import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/models/chat_message_model.dart';
import 'package:ocean_rent/pages/chat/chat_thread_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/providers/chat_providers.dart';
import 'package:ocean_rent/utils/chat_utils.dart';

class CustomerChatsPage extends ConsumerWidget {
  const CustomerChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser;

    if (user == null) {
      return Center(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Text(
            'Inicia sesión para usar el chat.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final bookingsAsync = ref.watch(userBookingsStreamProvider(user.uid));
    final boatsAsync = ref.watch(boatsStreamProvider);

    final boatNames = boatsAsync.maybeWhen(
      data: (boats) => {for (final boat in boats) boat.id: boat.name},
      orElse: () => <String, String>{},
    );

    return bookingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.oceanBlue),
      ),
      error: (_, _) => Center(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Text(
            'No se pudieron cargar tus chats.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.alertRed),
          ),
        ),
      ),
      data: (bookings) {
        final conversations = bookings
            .where(ChatAvailability.isConversationEnabled)
            .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacing20,
                  AppTheme.spacing18,
                  AppTheme.spacing20,
                  AppTheme.spacing8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis chats',
                      style: AppTheme.headlineSmall.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'Habla con el equipo sobre cada una de tus reservas.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (conversations.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _EmptyChats())
            else
              SliverPadding(
                padding: AppTheme.listPadding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index.isOdd) {
                      return const SizedBox(height: AppTheme.spacing12);
                    }
                    final booking = conversations[index ~/ 2];
                    final boatName =
                        boatNames[booking.boatId] ?? booking.boatId;
                    return _ChatConversationCard(
                      booking: booking,
                      currentUserId: user.uid,
                      isAdmin: false,
                      title: boatName,
                      subtitle:
                          '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                    );
                  }, childCount: conversations.length * 2 - 1),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyChats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_outlined,
              color: AppTheme.oceanBlue,
              size: AppTheme.emptyStateIconSize,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Aún no tienes chats',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'El chat se activa cuando solicitas una reserva.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatConversationCard extends ConsumerWidget {
  final BookingModel booking;
  final String currentUserId;
  final bool isAdmin;
  final String title;
  final String subtitle;

  const _ChatConversationCard({
    required this.booking,
    required this.currentUserId,
    required this.isAdmin,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessageAsync = ref.watch(lastChatMessageProvider(booking.id));
    final canSend = ChatAvailability.canSendMessages(booking);

    final preview = lastMessageAsync.maybeWhen(
      data: (message) => _previewText(message),
      orElse: () => null,
    );

    return InkWell(
      borderRadius: AppTheme.borderRadiusCard,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(
              booking: booking,
              title: title,
              subtitle: subtitle,
              currentUserId: currentUserId,
              isAdmin: isAdmin,
            ),
          ),
        );
      },
      child: Container(
        padding: AppTheme.compactCardPadding,
        decoration: AppTheme.cardDecoration(
          color: AppTheme.surface,
          border: Border.all(
            color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
          ),
          boxShadow: AppTheme.softShadow(alpha: AppTheme.alphaUltraSoft),
        ),
        child: Row(
          children: [
            Container(
              width: AppTheme.summaryIconBoxSize,
              height: AppTheme.summaryIconBoxSize,
              decoration: AppTheme.adminIconBoxDecoration(AppTheme.oceanBlue),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.oceanBlue,
                size: AppTheme.iconSize2xl,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleSmall.copyWith(
                            color: AppTheme.deepNavy,
                          ),
                        ),
                      ),
                      if (!canSend)
                        Container(
                          padding: AppTheme.licenseStatusBadgePadding,
                          decoration: AppTheme.badgeDecoration(
                            color: AppTheme.textMuted,
                          ),
                          child: Text(
                            'Cerrado',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    subtitle,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing6),
                  Text(
                    preview ?? 'Toca para abrir la conversación',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      color: preview == null
                          ? AppTheme.textSecondary
                          : AppTheme.textMuted,
                      fontStyle: preview == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: AppTheme.iconSizeLarge,
            ),
          ],
        ),
      ),
    );
  }

  String? _previewText(ChatMessageModel? message) {
    if (message == null) return null;

    final String senderPrefix;
    if (message.senderId == currentUserId) {
      senderPrefix = 'Tú: ';
    } else {
      senderPrefix = isAdmin ? 'Cliente: ' : 'Equipo: ';
    }

    return '$senderPrefix${message.text}';
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
