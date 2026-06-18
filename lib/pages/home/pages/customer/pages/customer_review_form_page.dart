import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/models/review_model.dart';
import 'package:ocean_rent/providers/review_providers.dart';

class CustomerReviewFormPage extends ConsumerStatefulWidget {
  final BookingModel booking;
  final String userId;

  const CustomerReviewFormPage({
    super.key,
    required this.booking,
    required this.userId,
  });

  @override
  ConsumerState<CustomerReviewFormPage> createState() =>
      _CustomerReviewFormPageState();
}

class _CustomerReviewFormPageState
    extends ConsumerState<CustomerReviewFormPage> {
  final TextEditingController _commentController = TextEditingController();

  int _selectedRating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _publishReview() async {
    final comment = _commentController.text.trim();

    if (comment.length > 300) {
      _showSnackBar('El comentario no puede superar los 300 caracteres.');
      return;
    }

    final success = await ref
        .read(reviewNotifierProvider)
        .createReview(
          ReviewModel(
            id: '',
            boatId: widget.booking.boatId,
            bookingId: widget.booking.id,
            userId: widget.userId,
            rating: _selectedRating,
            comment: comment,
          ),
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    _showSnackBar(
      ref.read(reviewNotifierProvider).errorMessage ??
          'No se pudo publicar la reseña.',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final reviewNotifier = ref.watch(reviewNotifierProvider);
    final isSaving = reviewNotifier.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Valorar experiencia')),
      body: ListView(
        padding: AppTheme.cardPadding,
        children: [
          Container(
            padding: AppTheme.compactCardPadding,
            decoration: AppTheme.simpleCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puntua tu experiencia',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Tu valoracion ayudara a otros clientes a conocer mejor este barco. El comentario es opcional.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                    height: AppTheme.lineHeightRegular,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;

                    return IconButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              setState(() {
                                _selectedRating = starValue;
                              });
                            },
                      icon: Icon(
                        starValue <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppTheme.sunsetGold,
                        size: AppTheme.iconSize2xl,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextField(
                  controller: _commentController,
                  enabled: !isSaving,
                  maxLength: 300,
                  maxLines: 5,
                  decoration:
                      AppTheme.inputDecoration(
                        labelText: 'Comentario',
                        icon: Icons.rate_review_outlined,
                      ).copyWith(
                        hintText: 'Cuenta como fue tu experiencia',
                        alignLabelWithHint: true,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          SizedBox(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : _publishReview,
              style: AppTheme.fullWidthPrimaryButtonStyle,
              icon: isSaving
                  ? const SizedBox(
                      width: AppTheme.loadingSize,
                      height: AppTheme.loadingSize,
                      child: CircularProgressIndicator(
                        strokeWidth: AppTheme.progressStrokeWidth,
                        color: AppTheme.pearlWhite,
                      ),
                    )
                  : const Icon(Icons.publish_outlined),
              label: Text(
                isSaving ? 'Publicando...' : 'Publicar reseña',
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
