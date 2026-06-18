import 'package:flutter_test/flutter_test.dart';
import 'package:ocean_rent/models/review_model.dart';

void main() {
  group('ReviewModel', () {
    test('serializes using Firestore field names expected by rules', () {
      const review = ReviewModel(
        id: 'booking-1',
        boatId: 'boat-1',
        bookingId: 'booking-1',
        userId: 'user-1',
        rating: 5,
        comment: 'Muy buena experiencia.',
      );

      final map = review.toMap();

      expect(map['id'], 'booking-1');
      expect(map['boat_id'], 'boat-1');
      expect(map['booking_id'], 'booking-1');
      expect(map['user_id'], 'user-1');
      expect(map['rating'], 5);
      expect(map['comment'], 'Muy buena experiencia.');
      expect(map['admin_reply'], '');
      expect(map.containsKey('userId'), isFalse);
      expect(map.containsKey('bookingId'), isFalse);
      expect(map.containsKey('boatId'), isFalse);
    });
  });
}
