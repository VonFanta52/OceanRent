import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/models/chat_message_model.dart';
import 'package:ocean_rent/pages/bookings/booking_detail_page.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/providers/chat_providers.dart';
import 'package:ocean_rent/utils/chat_utils.dart';

class ChatThreadPage extends ConsumerStatefulWidget {
  final BookingModel booking;
  final String title;
  final String subtitle;
  final String currentUserId;
  final bool isAdmin;

  const ChatThreadPage({
    super.key,
    required this.booking,
    required this.title,
    required this.subtitle,
    required this.currentUserId,
    required this.isAdmin,
  });

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BookingModel booking) async {
    if (booking.isChatClosed) {
      _showSnackBar(
        'No se pueden enviar mensajes porque esta conversación está cerrada.',
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('El mensaje no puede estar vacío.');
      return;
    }

    if (text.length > 500) {
      _showSnackBar('El mensaje no puede superar los 500 caracteres.');
      return;
    }

    final success = await ref
        .read(chatNotifierProvider)
        .sendMessage(
          bookingId: booking.id,
          senderId: widget.currentUserId,
          senderRole: widget.isAdmin
              ? ChatMessageModel.senderRoleAdmin
              : ChatMessageModel.senderRoleCustomer,
          text: text,
        );

    if (!mounted) return;

    if (success) {
      _messageController.clear();
      _scrollToBottom();
      return;
    }

    _showSnackBar(
      ref.read(chatNotifierProvider).errorMessage ??
          'No se pudo enviar el mensaje.',
    );
  }

  Future<void> _closeChat(BookingModel booking) async {
    if (booking.isChatClosed) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusCard,
        ),
        title: Text('Finalizar chat', style: AppTheme.titleMedium),
        content: Text(
          '¿Seguro que quieres finalizar esta conversación?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: AppTheme.destructiveButtonStyle,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Finalizar chat'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await ref
        .read(chatNotifierProvider)
        .closeChat(bookingId: booking.id, closedBy: widget.currentUserId);

    if (!mounted) return;

    _showSnackBar(
      success
          ? 'Chat finalizado.'
          : ref.read(chatNotifierProvider).errorMessage ??
                'No se pudo finalizar el chat.',
    );
  }

  void _openBookingDetail(BookingModel booking, String boatName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingDetailPage(
          booking: booking,
          boatName: boatName,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
  }

  void _showBookingSelector({
    required List<BookingModel> bookings,
    required Map<String, String> boatNames,
  }) {
    final availableBookings = bookings
        .where(ChatAvailability.isConversationEnabled)
        .toList();

    if (availableBookings.isEmpty) {
      _showSnackBar('No hay reservas disponibles para seleccionar.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacing16),
            padding: AppTheme.compactCardPadding,
            decoration: AppTheme.cardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar reserva',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing6),
                Text(
                  'Elige la reserva sobre la que quieres hablar.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(height: AppTheme.spacing14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableBookings.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: AppTheme.divider),
                    itemBuilder: (context, index) {
                      final booking = availableBookings[index];
                      final boatName =
                          boatNames[booking.boatId] ?? booking.boatId;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.event_available_outlined,
                          color: AppTheme.oceanBlue,
                        ),
                        title: Text(
                          boatName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleSmall.copyWith(
                            color: AppTheme.deepNavy,
                          ),
                        ),
                        subtitle: Text(
                          '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => ChatThreadPage(
                                booking: booking,
                                title: widget.isAdmin ? 'Reserva' : boatName,
                                subtitle:
                                    '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                                currentUserId: widget.currentUserId,
                                isAdmin: widget.isAdmin,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppTheme.animationFast,
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.booking.id));
    final bookingsAsync = widget.isAdmin
        ? ref.watch(bookingsStreamProvider)
        : ref.watch(userBookingsStreamProvider(widget.currentUserId));
    final boatsAsync = ref.watch(boatsStreamProvider);
    final chatState = ref.watch(chatNotifierProvider);

    final bookings = bookingsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => <BookingModel>[widget.booking],
    );
    final booking = bookings.firstWhere(
      (item) => item.id == widget.booking.id,
      orElse: () => widget.booking,
    );
    final boatNames = boatsAsync.maybeWhen(
      data: (boats) => {for (final boat in boats) boat.id: boat.name},
      orElse: () => <String, String>{},
    );
    final boatName = boatNames[booking.boatId] ?? booking.boatId;
    final canSend = ChatAvailability.canSendMessages(booking);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.appBarTitleStyle,
            ),
            if (widget.subtitle.trim().isNotEmpty)
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.white.withValues(
                    alpha: AppTheme.alphaTextOnDark,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Seleccionar reserva',
            onPressed: () =>
                _showBookingSelector(bookings: bookings, boatNames: boatNames),
            icon: const Icon(Icons.event_available_outlined),
          ),
          if (!booking.isChatClosed)
            IconButton(
              tooltip: 'Finalizar chat',
              onPressed: chatState.isClosing ? null : () => _closeChat(booking),
              icon: const Icon(Icons.lock_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          _BookingReferenceCard(
            booking: booking,
            boatName: boatName,
            onSelectBooking: () =>
                _showBookingSelector(bookings: bookings, boatNames: boatNames),
            onViewBooking: () => _openBookingDetail(booking, boatName),
          ),
          if (booking.isChatClosed) const _ChatClosedTopBanner(),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.oceanBlue),
              ),
              error: (_, _) => Center(
                child: Padding(
                  padding: AppTheme.screenPadding,
                  child: Text(
                    'No se pudo cargar la conversación.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.alertRed,
                    ),
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _EmptyConversation(isAdmin: widget.isAdmin);
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: AppTheme.listPadding,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == widget.currentUserId;

                    return _MessageBubble(message: message, isMine: isMine);
                  },
                );
              },
            ),
          ),
          if (canSend)
            _MessageComposer(
              controller: _messageController,
              isSending: chatState.isSending,
              onSend: () => _sendMessage(booking),
            )
          else
            const _ClosedConversationBanner(),
        ],
      ),
    );
  }
}

class _BookingReferenceCard extends StatelessWidget {
  final BookingModel booking;
  final String boatName;
  final VoidCallback onSelectBooking;
  final VoidCallback onViewBooking;

  const _BookingReferenceCard({
    required this.booking,
    required this.boatName,
    required this.onSelectBooking,
    required this.onViewBooking,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _bookingStatusColor(booking.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacing12,
        AppTheme.spacing12,
        AppTheme.spacing12,
        AppTheme.spacing6,
      ),
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
              Container(
                width: AppTheme.summaryIconBoxSize,
                height: AppTheme.summaryIconBoxSize,
                decoration: AppTheme.adminIconBoxDecoration(AppTheme.oceanBlue),
                child: const Icon(
                  Icons.directions_boat_outlined,
                  color: AppTheme.oceanBlue,
                  size: AppTheme.iconSize2xl,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserva vinculada',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.oceanBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing3),
                    Text(
                      boatName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.deepNavy,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: AppTheme.licenseStatusBadgePadding,
                decoration: AppTheme.badgeDecoration(color: statusColor),
                child: Text(
                  _bookingStatusLabel(booking.status),
                  style: AppTheme.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing10),
          _ReferenceRow(
            label: 'Fechas',
            value:
                '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
          ),
          _ReferenceRow(
            label: 'Fianza',
            value: '${booking.depositAmount.toStringAsFixed(2)} EUR',
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppTheme.spacing4,
            children: [
              TextButton.icon(
                onPressed: onSelectBooking,
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Seleccionar reserva'),
              ),
              TextButton.icon(
                onPressed: onViewBooking,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Ver reserva'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReferenceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.deepNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatClosedTopBanner extends StatelessWidget {
  const _ChatClosedTopBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing12,
        0,
        AppTheme.spacing12,
        AppTheme.spacing6,
      ),
      child: Container(
        width: double.infinity,
        padding: AppTheme.infoBannerPadding,
        decoration: AppTheme.infoBannerDecoration(AppTheme.textMuted),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline,
              color: AppTheme.textMuted,
              size: AppTheme.iconSizeMedium,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                'Chat finalizado',
                style: AppTheme.infoBannerTextStyle(AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final bool isAdmin;

  const _EmptyConversation({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
                      'Todavía no hay mensajes',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.deepNavy,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      isAdmin
                          ? 'Escribe para iniciar la conversación con el cliente.'
                          : 'Escribe para resolver cualquier duda sobre tu reserva.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppTheme.oceanBlue : AppTheme.surface;
    final textColor = isMine ? AppTheme.white : AppTheme.deepNavy;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppTheme.radiusLg),
      topRight: const Radius.circular(AppTheme.radiusLg),
      bottomLeft: Radius.circular(
        isMine ? AppTheme.radiusLg : AppTheme.radiusXs,
      ),
      bottomRight: Radius.circular(
        isMine ? AppTheme.radiusXs : AppTheme.radiusLg,
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing10),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing14,
          vertical: AppTheme.spacing10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
          border: isMine
              ? null
              : Border.all(
                  color: AppTheme.deepNavy.withValues(
                    alpha: AppTheme.alphaSoft,
                  ),
                ),
          boxShadow: AppTheme.softShadow(alpha: AppTheme.alphaUltraSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTheme.bodyMedium.copyWith(
                color: textColor,
                height: AppTheme.lineHeightSmall,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              _formatTime(message.createdAt),
              style: AppTheme.labelSmall.copyWith(
                color: isMine
                    ? AppTheme.white.withValues(alpha: AppTheme.alphaTextOnDark)
                    : AppTheme.textSecondary,
                fontSize: AppTheme.fontSize11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusBadge,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusBadge,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusBadge,
                    borderSide: const BorderSide(
                      color: AppTheme.oceanBlue,
                      width: AppTheme.borderWidthMedium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
              child: Material(
                color: AppTheme.deepNavy,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isSending ? null : onSend,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    child: isSending
                        ? const SizedBox(
                            width: AppTheme.iconSizeLarge,
                            height: AppTheme.iconSizeLarge,
                            child: CircularProgressIndicator(
                              strokeWidth: AppTheme.progressStrokeWidth,
                              color: AppTheme.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppTheme.white,
                            size: AppTheme.iconSizeLarge,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedConversationBanner extends StatelessWidget {
  const _ClosedConversationBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline,
              color: AppTheme.textMuted,
              size: AppTheme.iconSizeLarge,
            ),
            const SizedBox(width: AppTheme.spacing10),
            Expanded(
              child: Text(
                'No se pueden enviar mensajes porque esta conversación está cerrada.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime? date) {
  if (date == null) return '';

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month - $hour:$minute';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _bookingStatusLabel(String status) {
  return switch (status) {
    BookingModel.statusConfirmed => 'confirmada',
    BookingModel.statusCancelled => 'cancelada',
    BookingModel.statusPending => 'pendiente',
    _ => status,
  };
}

Color _bookingStatusColor(String status) {
  return switch (status) {
    BookingModel.statusConfirmed => AppTheme.oceanBlue,
    BookingModel.statusCancelled => AppTheme.alertRed,
    BookingModel.statusPending => AppTheme.sunsetGold,
    _ => AppTheme.textMuted,
  };
}
