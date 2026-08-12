import 'package:flutter/material.dart';
import '../../core/timer/schedule_engine.dart';
import '../../core/localization/app_locale.dart';

class TimerDisplayWidget extends StatelessWidget {
  final TimerDerivedState derivedState;
  final bool isOffline;

  const TimerDisplayWidget({
    super.key,
    required this.derivedState,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String statusText;
    Color statusColor;

    switch (derivedState.state) {
      case DerivedPhaseState.starting:
        statusText = context.tr(
          'Starting in ${derivedState.startingCountdownSeconds}s...',
          'يبدأ خلال ${derivedState.startingCountdownSeconds} ث...',
        );
        statusColor = theme.colorScheme.tertiary;
        break;
      case DerivedPhaseState.runningRound:
        statusText = context.tr(
          'Round ${derivedState.currentRoundIndex} Running',
          'الجولة ${derivedState.currentRoundIndex} جارية',
        );
        statusColor = theme.colorScheme.primary;
        break;
      case DerivedPhaseState.cooldown:
        statusText = context.tr('Next Round', 'الجولة التالية');
        statusColor = theme.colorScheme.secondary;
        break;
      case DerivedPhaseState.paused:
        statusText = context.tr('Paused', 'متوقف مؤقتًا');
        statusColor = theme.colorScheme.error;
        break;
      case DerivedPhaseState.completed:
        statusText = context.tr('Event Completed', 'اكتملت الفعالية');
        statusColor = theme.colorScheme.primary;
        break;
      case DerivedPhaseState.ended:
        statusText = context.tr('Event Ended', 'انتهت الفعالية');
        statusColor = theme.colorScheme.outline;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double parentWidth = constraints.maxWidth;
        final bool isSmallScreen = parentWidth < 360;

        final double verticalPadding = isSmallScreen ? 16.0 : 22.0;
        final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
        final double timerFontSize = (parentWidth * 0.20).clamp(44.0, 92.0);
        final double iconSize = isSmallScreen ? 16.0 : 20.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
            border: Border.all(
              color: isOffline
                  ? theme.colorScheme.error
                  : statusColor.withValues(alpha: 0.28),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      alignment: AlignmentDirectional.centerStart,
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            derivedState.state == DerivedPhaseState.paused
                                ? Icons.pause_circle_outline
                                : derivedState.state ==
                                        DerivedPhaseState.cooldown
                                    ? Icons.skip_next_rounded
                                    : Icons.timer_outlined,
                            color: statusColor,
                            size: iconSize,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: (isSmallScreen
                                    ? theme.textTheme.titleSmall
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${derivedState.currentRoundIndex}/${derivedState.totalRounds}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr('TIME LEFT', 'الوقت المتبقي'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        derivedState.isStartingCountdown
                            ? '${derivedState.startingCountdownSeconds}'
                            : derivedState.formattedTime,
                        style: TextStyle(
                          fontSize: timerFontSize,
                          height: 1.05,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: derivedState.state == DerivedPhaseState.paused
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                derivedState.state == DerivedPhaseState.cooldown
                    ? context.tr(
                        'The next round starts soon',
                        'تبدأ الجولة التالية قريبًا',
                      )
                    : context.tr(
                        'Round ${derivedState.currentRoundIndex} of ${derivedState.totalRounds}',
                        'الجولة ${derivedState.currentRoundIndex} من ${derivedState.totalRounds}',
                      ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
