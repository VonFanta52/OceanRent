import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_rent/models/booking_model.dart';

void main() {
  group('BookingModel', () {
    test('serializes customer-created booking fields used by rules', () {
      final startDate = DateTime(2026, 7, 1);
      final endDate = DateTime(2026, 7, 3);
      final booking = BookingModel(
        id: 'booking-1',
        boatId: 'boat-1',
        userId: 'user-1',
        startDate: startDate,
        endDate: endDate,
        crewCount: 4,
        status: BookingModel.statusPending,
        depositAmount: 100,
        depositPaymentIntentId: '',
        depositStatus: BookingModel.depositStatusHeld,
        rentalPaymentIntentId: '',
      );

      final map = {...booking.toMap(), 'id': booking.id};

      expect(map['id'], 'booking-1');
      expect(map['boat_id'], 'boat-1');
      expect(map['user_id'], 'user-1');
      expect(map['start_date'], isA<Timestamp>());
      expect(map['end_date'], isA<Timestamp>());
      expect(map['crew_count'], 4);
      expect(map['status'], BookingModel.statusPending);
      expect(map['deposit_amount'], 100);
      expect(map['deposit_payment_intent_id'], '');
      expect(map['deposit_status'], BookingModel.depositStatusHeld);
      expect(map['rental_payment_intent_id'], '');
    });
  });
}
