import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../core/localization/app_locale.dart';
import '../../core/models/feed_event_model.dart';

enum _SystemEventKind { roundStarted, timerAdjusted, other }

String _eventText(FeedEvent event) =>
    '${event.title} ${event.body}'.toLowerCase();

_SystemEventKind _systemEventKind(FeedEvent event) {
  final text = _eventText(event);
  if (text.contains('adjust') || text.contains('تعديل')) {
    return _SystemEventKind.timerAdjusted;
  }
  if (text.contains('round') &&
          (text.contains('started') || text.contains('start')) ||
      text.contains('بدأت الجولة') ||
      text.contains('الجولة التالية')) {
    return _SystemEventKind.roundStarted;
  }
  return _SystemEventKind.other;
}

int? _roundNumber(FeedEvent event) {
  final source = '${event.title} ${event.body}';
  final match = RegExp(
    r'(?:round|الجولة)\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(source);
  return match == null ? null : int.tryParse(match.group(1)!);
}

String? _adjustmentLabel(FeedEvent event) {
  final source = '${event.title} ${event.body}';
  final match = RegExp(r'([+-]\s?\d+)').firstMatch(source);
  return match?.group(1)?.replaceAll(' ', '');
}

String _systemSummary(BuildContext context, FeedEvent event) {
  final text = _eventText(event);
  final round = _roundNumber(event);

  if (_systemEventKind(event) == _SystemEventKind.timerAdjusted) {
    final delta = _adjustmentLabel(event);
    if (delta != null) {
      return context.tr(
        'Controller $delta min',
        'المتحكّم $delta دقيقة',
      );
    }
    return context.tr('Timer adjusted', 'تم تعديل المؤقت');
  }

  if (_systemEventKind(event) == _SystemEventKind.roundStarted) {
    return round == null
        ? context.tr('Next round started', 'بدأت الجولة التالية')
        : context.tr('Round $round started', 'بدأت الجولة $round');
  }

  if (text.contains('skip') || text.contains('تخط')) {
    return round == null
        ? context.tr('Round skipped', 'تم تخطّي الجولة')
        : context.tr('Round $round skipped', 'تم تخطّي الجولة $round');
  }
  if (text.contains('pause') || text.contains('إيقاف')) {
    return context.tr('Timer paused', 'تم إيقاف المؤقت');
  }
  if (text.contains('resume') || text.contains('استئناف')) {
    return context.tr('Timer resumed', 'تم استئناف المؤقت');
  }
  if (text.contains('end') ||
      text.contains('completed') ||
      text.contains('اكتملت')) {
    return round == null
        ? context.tr('Round completed', 'اكتملت الجولة')
        : context.tr('Round $round completed', 'اكتملت الجولة $round');
  }

  return event.title;
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
                  final systemKind = _systemEventKind(event);

                  if (isAnnouncement || event.title.contains('Event Ended')) {
                    // Human announcements and event closure deserve the full
                    // card treatment. Routine timer controls stay quiet.
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
                  }

                  if (systemKind == _SystemEventKind.roundStarted) {
                    final accent = theme.colorScheme.primary;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.72,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.skip_next_rounded,
                              size: 20,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    'Next round',
                                    'الجولة التالية',
                                  ),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _systemSummary(context, event),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 4,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 7,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _systemSummary(context, event),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
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
