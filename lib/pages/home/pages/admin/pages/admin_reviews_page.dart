import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/review_model.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/review_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';

class AdminReviewsPage extends ConsumerWidget {
  const AdminReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allReviewsProvider);
    final boatsAsync = ref.watch(boatsStreamProvider);

    final boatNames = boatsAsync.maybeWhen(
      data: (boats) => {for (final boat in boats) boat.id: boat.name},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Reseñas de clientes')),
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
          if (reviews.isEmpty) {
            return const _EmptyReviewsAdminState();
          }

          return ListView.separated(
            padding: AppTheme.listPadding,
            itemCount: reviews.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTheme.spacing12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final boatName = boatNames[review.boatId] ?? review.boatId;

              return _AdminReviewCard(review: review, boatName: boatName);
            },
          );
        },
      ),
    );
  }
}

class _EmptyReviewsAdminState extends StatelessWidget {
  const _EmptyReviewsAdminState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Container(
          padding: AppTheme.compactCardPadding,
          decoration: AppTheme.simpleCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.rate_review_outlined,
                color: AppTheme.oceanBlue,
                size: AppTheme.iconSize3xl,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'No hay reseñas todavía',
                textAlign: TextAlign.center,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Cuando los clientes completen reservas y valoren su experiencia, aparecerán aquí.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  height: AppTheme.lineHeightRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminReviewCard extends ConsumerStatefulWidget {
  final ReviewModel review;
  final String boatName;

  const _AdminReviewCard({required this.review, required this.boatName});

  @override
  ConsumerState<_AdminReviewCard> createState() => _AdminReviewCardState();
}

class _AdminReviewCardState extends ConsumerState<_AdminReviewCard> {
  late final TextEditingController _replyController;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController(text: widget.review.adminReply);
  }

  @override
  void didUpdateWidget(covariant _AdminReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.review.adminReply != widget.review.adminReply &&
        _replyController.text != widget.review.adminReply) {
      _replyController.text = widget.review.adminReply;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _saveReply() async {
    final reply = _replyController.text.trim();

    final success = await ref
        .read(reviewNotifierProvider)
        .updateAdminReply(reviewId: widget.review.id, adminReply: reply);

    if (!mounted) return;

    final message = success
        ? 'Respuesta guardada correctamente.'
        : ref.read(reviewNotifierProvider).errorMessage ??
              'No se pudo guardar la respuesta.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no disponible';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reviewNotifier = ref.watch(reviewNotifierProvider);
    final hasReply = widget.review.adminReply.trim().isNotEmpty;
    final userAsync = ref.watch(userByIdProvider(widget.review.userId));
    final reviewerName = userAsync.maybeWhen(
      data: (user) {
        final fullName = '${user?.name ?? ''} ${user?.surname ?? ''}'.trim();
        return fullName.isEmpty ? 'Cliente' : fullName;
      },
      orElse: () => 'Cliente',
    );

    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
        ),
        boxShadow: AppTheme.softShadow(alpha: AppTheme.alphaUltraSoft),
      ),
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
                      widget.boatName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      reviewerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      _formatDate(widget.review.createdAt),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _ReplyStatusBadge(hasReply: hasReply),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < widget.review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: AppTheme.sunsetGold,
                size: AppTheme.iconSizeMedium,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing10),
          Text(
            widget.review.comment.trim().isEmpty
                ? 'Sin comentario.'
                : widget.review.comment.trim(),
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textMuted,
              height: AppTheme.lineHeightRegular,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextField(
            controller: _replyController,
            enabled: !reviewNotifier.isLoading,
            maxLines: 3,
            decoration:
                AppTheme.inputDecoration(
                  labelText: 'Respuesta del admin',
                  icon: Icons.reply_outlined,
                ).copyWith(
                  hintText: 'Escribe una respuesta para el cliente',
                  alignLabelWithHint: true,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: reviewNotifier.isLoading ? null : _saveReply,
              style: AppTheme.fullWidthPrimaryButtonStyle,
              icon: reviewNotifier.isLoading
                  ? const SizedBox(
                      width: AppTheme.loadingSize,
                      height: AppTheme.loadingSize,
                      child: CircularProgressIndicator(
                        strokeWidth: AppTheme.progressStrokeWidth,
                        color: AppTheme.pearlWhite,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                hasReply ? 'Actualizar respuesta' : 'Responder reseña',
                style: AppTheme.buttonTextStyle.copyWith(
                  color: AppTheme.pearlWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyStatusBadge extends StatelessWidget {
  final bool hasReply;

  const _ReplyStatusBadge({required this.hasReply});

  @override
  Widget build(BuildContext context) {
    final color = hasReply ? AppTheme.oceanBlue : AppTheme.sunsetGold;
    final label = hasReply ? 'Respondida' : 'Pendiente';

    return Container(
      padding: AppTheme.licenseStatusBadgePadding,
      decoration: AppTheme.badgeDecoration(color: color),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
