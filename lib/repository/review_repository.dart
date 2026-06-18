import 'package:ocean_rent/models/review_model.dart';
import 'package:ocean_rent/services/review/review_service.dart';

class ReviewRepository {
  ReviewRepository(this._reviewService);

  final ReviewService _reviewService;

  Stream<List<ReviewModel>> watchReviewsByBoat(String boatId) {
    return _reviewService.getReviewsByBoat(boatId);
  }

  Stream<ReviewModel?> watchReviewByBooking(String bookingId) {
    return _reviewService.watchReviewByBooking(bookingId);
  }

  Future<void> createReview(ReviewModel review) {
    return _reviewService.createReview(review);
  }

  // Solo para admin: ver todas las reseñas sin filtrar por barco.
  Stream<List<ReviewModel>> watchAllReviews() {
    return _reviewService.watchAllReviews();
  }

  Future<void> updateAdminReply({
    required String reviewId,
    required String adminReply,
  }) {
    return _reviewService.updateAdminReply(
      reviewId: reviewId,
      adminReply: adminReply,
    );
  }
}
