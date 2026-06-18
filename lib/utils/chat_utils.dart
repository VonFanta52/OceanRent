import 'package:ocean_rent/models/booking_model.dart';

class ChatAvailability {
  const ChatAvailability._();
  static bool isConversationEnabled(BookingModel booking) {
    return booking.status != BookingModel.statusCancelled;
  }

  static bool canSendMessages(BookingModel booking, {DateTime? now}) {
    if (booking.status == BookingModel.statusCancelled ||
        booking.isChatClosed) {
      return false;
    }

    final today = _startOfDay(now ?? DateTime.now());
    final endDay = _startOfDay(booking.endDate);

    return !endDay.isBefore(today);
  }

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
