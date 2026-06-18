import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/models/review_model.dart';
import 'package:ocean_rent/repository/review_repository.dart';
import 'package:ocean_rent/services/review/review_service.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ReviewService.instance);
});

final reviewsByBoatProvider = StreamProvider.autoDispose
    .family<List<ReviewModel>, String>((ref, boatId) {
      final repository = ref.watch(reviewRepositoryProvider);

      if (boatId.trim().isEmpty) {
        return const Stream.empty();
      }

      return repository
          .watchReviewsByBoat(boatId)
          .handleError(
            (error, _) {},
            test: (e) => e.toString().contains('permission-denied'),
          );
    });
final reviewByBookingProvider = StreamProvider.autoDispose
    .family<ReviewModel?, String>((ref, bookingId) {
      final repository = ref.watch(reviewRepositoryProvider);

      if (bookingId.trim().isEmpty) {
        return const Stream.empty();
      }

      return repository
          .watchReviewByBooking(bookingId)
          .handleError(
            (error, _) {},
            test: (e) => e.toString().contains('permission-denied'),
          );
    });
// Solo para admin: ver todas las reseñas sin filtrar por barco.
final allReviewsProvider = StreamProvider.autoDispose<List<ReviewModel>>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);

  return repository.watchAllReviews().handleError(
    (error, _) {},
    test: (e) => e.toString().contains('permission-denied'),
  );
});

// Notifier para manejar la lógica de actualización de la respuesta del admin a una reseña.
final reviewNotifierProvider = ChangeNotifierProvider<ReviewNotifier>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);

  return ReviewNotifier(repository);
});

class ReviewNotifier extends ChangeNotifier {
  final ReviewRepository _reviewRepository;

  ReviewNotifier(this._reviewRepository);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> createReview(ReviewModel review) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _reviewRepository.createReview(review);
      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAdminReply({
    required String reviewId,
    required String adminReply,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _reviewRepository.updateAdminReply(
        reviewId: reviewId,
        adminReply: adminReply,
      );

      return true;
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('permission-denied')) {
      return 'No tienes permisos para realizar esta acción.';
    }

    return message.isEmpty ? 'No se pudo completar la operación.' : message;
  }
}
