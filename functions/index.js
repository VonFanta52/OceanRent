const { setGlobalOptions } = require("firebase-functions");
const {
  onDocumentUpdated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

const BOOKING_STATUS_CONFIRMED = "confirmada";

exports.sendBookingConfirmedNotification = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    const previousStatus = beforeData.status;
    const currentStatus = afterData.status;

    if (
      previousStatus === BOOKING_STATUS_CONFIRMED ||
      currentStatus !== BOOKING_STATUS_CONFIRMED
    ) {
      logger.info("La reserva no acaba de pasar a confirmada.", {
        bookingId: event.params.bookingId,
        previousStatus,
        currentStatus,
      });
      return;
    }

    const bookingId = event.params.bookingId;
    const notificationSent = await sendBookingNotification({
      bookingId,
      bookingData: afterData,
      type: "booking_confirmed",
      title: "Reserva confirmada",
      bodyBuilder: (boatName) =>
        `Tu reserva${boatName ? ` de ${boatName}` : ""} ha sido confirmada.`,
    });

    if (notificationSent) {
      await event.data.after.ref.set(
        {
          confirmation_notification_sent: true,
          confirmation_notification_sent_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  },
);

exports.sendBookingReminderNotification = onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: "Europe/Madrid",
  },
  async () => {
    const now = new Date();

    const startWindow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const endWindow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    logger.info("Buscando reservas para recordatorio 24h.", {
      startWindow: startWindow.toISOString(),
      endWindow: endWindow.toISOString(),
    });

    const bookingsSnapshot = await admin
      .firestore()
      .collection("bookings")
      .where("start_date", ">=", admin.firestore.Timestamp.fromDate(startWindow))
      .where("start_date", "<", admin.firestore.Timestamp.fromDate(endWindow))
      .get();

    if (bookingsSnapshot.empty) {
      logger.info("No hay reservas para enviar recordatorio 24h.");
      return;
    }

    const tasks = bookingsSnapshot.docs.map(async (bookingDocument) => {
      const bookingData = bookingDocument.data();
      const bookingId = bookingDocument.id;

      if (bookingData.status !== BOOKING_STATUS_CONFIRMED) {
        logger.info("Reserva ignorada porque no está confirmada.", {
          bookingId,
          status: bookingData.status,
        });
        return;
      }

      if (bookingData.reminder_24h_sent === true) {
        logger.info("Reserva ignorada porque el recordatorio ya fue enviado.", {
          bookingId,
        });
        return;
      }

      const notificationSent = await sendBookingNotification({
        bookingId,
        bookingData,
        type: "booking_reminder_24h",
        title: "Recordatorio de reserva",
        bodyBuilder: (boatName) =>
          `Tu reserva${boatName ? ` de ${boatName}` : ""} empieza en 24 horas.`,
      });

      if (notificationSent) {
        await bookingDocument.ref.set(
          {
            reminder_24h_sent: true,
            reminder_24h_sent_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    });

    await Promise.all(tasks);

    logger.info("Proceso de recordatorios 24h finalizado.", {
      totalBookingsChecked: bookingsSnapshot.size,
    });
  },
);

exports.syncBoatRatingOnReviewWrite = onDocumentWritten(
  "reviews/{reviewId}",
  async (event) => {
    const beforeData = event.data.before.exists
      ? event.data.before.data()
      : null;
    const afterData = event.data.after.exists ? event.data.after.data() : null;

    const boatIds = new Set();
    if (beforeData?.boat_id) boatIds.add(beforeData.boat_id);
    if (afterData?.boat_id) boatIds.add(afterData.boat_id);

    await Promise.all([...boatIds].map(syncBoatRating));
  },
);

async function sendBookingNotification({
  bookingId,
  bookingData,
  type,
  title,
  bodyBuilder,
}) {
  const userId = bookingData.user_id;

  if (!userId) {
    logger.warn("La reserva no tiene user_id.", { bookingId });
    return false;
  }

  const userSnapshot = await admin
    .firestore()
    .collection("users")
    .doc(userId)
    .get();

  if (!userSnapshot.exists) {
    logger.warn("No existe el usuario asociado a la reserva.", {
      bookingId,
      userId,
    });
    return false;
  }

  const userData = userSnapshot.data();
  const fcmToken = userData.fcm_token;

  if (!fcmToken) {
    logger.warn("El usuario no tiene token FCM guardado.", {
      bookingId,
      userId,
    });
    return false;
  }

  const boatName = await getBoatName(bookingData.boat_id);

  const message = {
    token: fcmToken,
    notification: {
      title,
      body: bodyBuilder(boatName),
    },
    data: {
      type,
      bookingId,
      boatId: bookingData.boat_id || "",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "booking_notifications",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);

    logger.info("Notificación FCM enviada.", {
      bookingId,
      userId,
      type,
      response,
    });

    return true;
  } catch (error) {
    logger.error("Error al enviar la notificación FCM.", {
      bookingId,
      userId,
      type,
      error,
    });

    return false;
  }
}

async function getBoatName(boatId) {
  if (!boatId) {
    return "";
  }

  const boatSnapshot = await admin
    .firestore()
    .collection("boats")
    .doc(boatId)
    .get();

  if (!boatSnapshot.exists) {
    return "";
  }

  const boatData = boatSnapshot.data();

  return boatData.name || "";
}

async function syncBoatRating(boatId) {
  if (!boatId) {
    return;
  }

  const boatRef = admin.firestore().collection("boats").doc(boatId);
  const boatSnapshot = await boatRef.get();

  if (!boatSnapshot.exists) {
    logger.warn("No se puede sincronizar rating: el barco no existe.", {
      boatId,
    });
    return;
  }

  const reviewsSnapshot = await admin
    .firestore()
    .collection("reviews")
    .where("boat_id", "==", boatId)
    .get();

  let ratingCount = 0;
  let ratingTotal = 0;

  reviewsSnapshot.forEach((reviewDocument) => {
    const rating = Number(reviewDocument.data().rating || 0);
    if (Number.isFinite(rating) && rating >= 1 && rating <= 5) {
      ratingCount += 1;
      ratingTotal += rating;
    }
  });

  const ratingAvg = ratingCount === 0 ? 0 : ratingTotal / ratingCount;

  await boatRef.update({
    rating_avg: ratingAvg,
    rating_count: ratingCount,
  });

  logger.info("Rating de barco sincronizado.", {
    boatId,
    ratingAvg,
    ratingCount,
  });
}
