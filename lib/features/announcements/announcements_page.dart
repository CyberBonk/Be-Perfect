import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../core/localization/app_locale.dart';
import '../../core/models/feed_event_model.dart';

// Events that should display as expanded cards (important ones)
const _importantTitles = {
  'Event Ended',
  'Event Started',
};

bool _isImportant(FeedEvent event) {
  if (event.type == FeedEventType.announcement) return true;
  // Round ended is important
  if (event.title.contains('Round') && event.title.contains('Ended')) {
    return true;
  }
  // Check if title matches known important system events
  return _importantTitles.any((t) => event.title.contains(t));
}

class AnnouncementsPage extends ConsumerStatefulWidget {
  final bool isController;
  const AnnouncementsPage({super.key, this.isController = false});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  final _messageController = TextEditingController();
  bool _notifyDevices = true;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || text.length > 500) return;

    final roomId = ref.read(activeRoomIdProvider);
    if (roomId == null) return;
    final sectorName = ref.read(userSectorNameProvider);

    setState(() => _isSending = true);

    try {
      final repo = ref.read(roomRepositoryProvider);
      await repo.sendAnnouncement(
        roomId: roomId,
        body: text,
        title: widget.isController
            ? context.tr('Announcement', 'تنويه')
            : context.tr(
                'Message from ${sectorName ?? 'Participant'}',
                'رسالة من ${sectorName ?? 'مشارك'}',
              ),
        notifyDevices: _notifyDevices,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedAsync = ref.watch(feedStreamProvider);

    return Column(
      children: [
        Expanded(
          child: feedAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    context.tr(
                      'No announcements yet.',
                      'لا توجد تنويهات حتى الآن.',
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final timeStr = DateFormat('hh:mm a').format(
                    DateTime.fromMillisecondsSinceEpoch(event.timestamp),
                  );
                  final isAnnouncement =
                      event.type == FeedEventType.announcement;
                  final important = _isImportant(event);

                  if (important) {
                    // Full expanded card for important events
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: isAnnouncement
                          ? theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.5)
                          : theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isAnnouncement
                                      ? Icons.campaign
                                      : Icons.notifications_active,
                                  size: 18,
                                  color: isAnnouncement
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isAnnouncement
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.secondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (event.body.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                event.body,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Compact one-liner for minor system events (pause, resume, adjust, skip)
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        leading: Icon(
                          Icons.settings,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          '${event.title}  ·  ${event.body}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          timeStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                '${context.tr('Error loading announcements', 'تعذر تحميل التنويهات')}: $err',
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isController)
                Row(
                  children: [
                    Checkbox(
                      value: _notifyDevices,
                      onChanged: (v) =>
                          setState(() => _notifyDevices = v ?? true),
                    ),
                    Text(context.tr('Notify Devices', 'إشعار الأجهزة')),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: widget.isController
                            ? context.tr(
                                'Type announcement...',
                                'اكتب تنويهًا...',
                              )
                            : context.tr(
                                'Send a message to the room...',
                                'أرسل رسالة إلى الغرفة...',
                              ),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendAnnouncement,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
