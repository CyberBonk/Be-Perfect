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
        statusText = context.tr('Cooldown Period', 'فترة راحة');
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

        final double verticalPadding = isSmallScreen ? 16.0 : 28.0;
        final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;
        final double timerFontSize = (parentWidth * 0.22).clamp(44.0, 96.0);
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
                  : statusColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.1),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      derivedState.state == DerivedPhaseState.paused
                          ? Icons.pause_circle_outline
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
              SizedBox(height: isSmallScreen ? 10 : 16),
              // Dynamic scaling countdown timer with tabular figures
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  derivedState.isStartingCountdown
                      ? '${derivedState.startingCountdownSeconds}'
                      : derivedState.formattedTime,
                  style: TextStyle(
                    fontSize: timerFontSize,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: derivedState.state == DerivedPhaseState.paused
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                context.tr(
                  'Round ${derivedState.currentRoundIndex} of ${derivedState.totalRounds}',
                  'الجولة ${derivedState.currentRoundIndex} من ${derivedState.totalRounds}',
                ),
                style: (isSmallScreen
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.titleSmall)
                    ?.copyWith(
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
