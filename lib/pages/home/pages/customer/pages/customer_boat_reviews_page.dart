import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/models/review_model.dart';
import 'package:ocean_rent/providers/review_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';

class CustomerBoatReviewsPage extends ConsumerWidget {
  final BoatModel boat;

  const CustomerBoatReviewsPage({super.key, required this.boat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsByBoatProvider(boat.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(boat.name.isEmpty ? 'Reseñas' : 'Reseñas de ${boat.name}'),
      ),
      body: reviewsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.oceanBlue,
            strokeWidth: AppTheme.progressStrokeWidth,
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Text(
              'No se pudieron cargar las reseñas.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        data: (reviews) {
          final realRatingCount = reviews.length;
          final realRatingAvg = realRatingCount == 0
              ? 0.0
              : reviews.fold<int>(0, (total, review) => total + review.rating) /
                    realRatingCount;

          return ListView(
            padding: AppTheme.cardPadding,
            children: [
              _ReviewSummaryCard(
                ratingAvg: realRatingAvg,
                ratingCount: realRatingCount,
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Todas las reseñas',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              if (reviews.isEmpty)
                const _EmptyReviewsCard()
              else
                ...reviews.map((review) => _ReviewCard(review: review)),
            ],
          );
        },
      ),
    );
  }
}

// Tarjeta que muestra el resumen de las reseñas del barco, incluyendo la valoración promedio y el número de reseñas.
class _ReviewSummaryCard extends StatelessWidget {
  final double ratingAvg;
  final int ratingCount;

  const _ReviewSummaryCard({
    required this.ratingAvg,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasReviews = ratingCount > 0;
    final count = ratingCount;
    final ratingText = hasReviews
        ? '${ratingAvg.toStringAsFixed(1)} · $count reseña${count == 1 ? '' : 's'}'
        : 'Sin reseñas todavía';

    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.simpleCardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppTheme.sunsetGold,
            size: AppTheme.iconSizeLarge,
          ),
          const SizedBox(width: AppTheme.spacing10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ratingText,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  hasReviews
                      ? 'Valoraciones reales de clientes.'
                      : 'Este barco todavía no tiene valoraciones.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReviewsCard extends StatelessWidget {
  const _EmptyReviewsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.infoBannerDecoration(AppTheme.oceanBlue),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.rate_review_outlined,
            color: AppTheme.oceanBlue,
            size: AppTheme.iconSizeLarge,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              'Todavía no hay reseñas para este barco. Cuando los clientes completen una reserva, podrán valorar su experiencia.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.deepNavy,
                height: AppTheme.lineHeightRegular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no disponible';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAdminReply = review.adminReply.trim().isNotEmpty;
    final userAsync = ref.watch(userByIdProvider(review.userId));
    final reviewerName = userAsync.maybeWhen(
      data: (user) {
        final fullName = '${user?.name ?? ''} ${user?.surname ?? ''}'.trim();
        return fullName.isEmpty ? 'Cliente' : fullName;
      },
      orElse: () => 'Cliente',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.simpleCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.oceanBlue,
                child: Icon(Icons.person_outline, color: AppTheme.pearlWhite),
              ),
              const SizedBox(width: AppTheme.spacing10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing10),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: AppTheme.sunsetGold,
                size: AppTheme.iconSizeSmall,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            review.comment.trim().isEmpty
                ? 'Sin comentario.'
                : review.comment.trim(),
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textMuted,
              height: AppTheme.lineHeightInfo,
            ),
          ),
          if (hasAdminReply) ...[
            const SizedBox(height: AppTheme.spacing14),
            Container(
              width: double.infinity,
              padding: AppTheme.infoBannerPadding,
              decoration: AppTheme.infoBannerDecoration(AppTheme.oceanBlue),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.reply_outlined,
                    color: AppTheme.oceanBlue,
                    size: AppTheme.iconSizeMedium,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Respuesta del administrador',
                          style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.deepNavy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          review.adminReply.trim(),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                            height: AppTheme.lineHeightRegular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
