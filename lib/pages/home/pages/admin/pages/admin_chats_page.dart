import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/pages/chat/chat_thread_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/providers/chat_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';
import 'package:ocean_rent/utils/chat_utils.dart';

class AdminChatsPage extends ConsumerWidget {
  const AdminChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(authNotifierProvider).currentUser;
    final bookingsAsync = ref.watch(bookingsStreamProvider);
    final boatsAsync = ref.watch(boatsStreamProvider);

    final boatNames = boatsAsync.maybeWhen(
      data: (boats) => {for (final boat in boats) boat.id: boat.name},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Mensajes')),
      body: admin == null
          ? const SizedBox.shrink()
          : bookingsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.oceanBlue),
              ),
              error: (_, _) => Center(
                child: Padding(
                  padding: AppTheme.screenPadding,
                  child: Text(
                    'No se pudieron cargar los chats.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.alertRed,
                    ),
                  ),
                ),
              ),
              data: (bookings) {
                final conversations = bookings
                    .where(ChatAvailability.isConversationEnabled)
                    .toList();

                if (conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: AppTheme.screenPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.forum_outlined,
                            color: AppTheme.oceanBlue,
                            size: AppTheme.emptyStateIconSize,
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            'No hay chats activos',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.deepNavy,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            'Cuando un cliente solicite una reserva, su chat aparecerá aquí.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: AppTheme.listPadding,
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spacing12),
                  itemBuilder: (context, index) {
                    final booking = conversations[index];

                    return _AdminChatCard(
                      booking: booking,
                      boatName: boatNames[booking.boatId] ?? booking.boatId,
                      adminId: admin.uid,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _AdminChatCard extends ConsumerWidget {
  final BookingModel booking;
  final String boatName;
  final String adminId;

  const _AdminChatCard({
    required this.booking,
    required this.boatName,
    required this.adminId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(booking.userId));
    final lastMessageAsync = ref.watch(lastChatMessageProvider(booking.id));
    final canSend = ChatAvailability.canSendMessages(booking);

    final customerName = userAsync.maybeWhen(
      data: (user) =>
          user == null ? 'Cliente' : '${user.name} ${user.surname}'.trim(),
      orElse: () => 'Cliente',
    );

    final preview = lastMessageAsync.maybeWhen(
      data: (message) {
        if (message == null) return null;
        final prefix = message.senderId == adminId ? 'Tú: ' : 'Cliente: ';
        return '$prefix${message.text}';
      },
      orElse: () => null,
    );

    return InkWell(
      borderRadius: AppTheme.borderRadiusCard,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadPage(
              booking: booking,
              title: customerName.isEmpty ? 'Cliente' : customerName,
              subtitle: '$boatName · ${_formatDate(booking.startDate)}',
              currentUserId: adminId,
              isAdmin: true,
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
                Icons.person_outline,
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
                          customerName.isEmpty ? 'Cliente' : customerName,
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
                    '$boatName · ${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing6),
                  Text(
                    preview ?? 'Sin mensajes todavía',
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
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
