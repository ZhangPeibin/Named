import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

const audioPlaybackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5];

String audioRateLabel(double rate) {
  return rate == rate.roundToDouble()
      ? '${rate.toInt()}×'
      : '${rate.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}×';
}

class AudioSpeedControl extends StatelessWidget {
  const AudioSpeedControl({
    super.key,
    required this.playKey,
    required this.speedKey,
    required this.isPlaying,
    required this.isLoading,
    required this.speed,
    required this.onToggle,
    required this.onSpeedChanged,
    required this.speedTooltip,
    required this.playTooltip,
    required this.pauseTooltip,
    this.dimension = 34,
  });

  final Key playKey;
  final Key speedKey;
  final bool isPlaying;
  final bool isLoading;
  final double speed;
  final VoidCallback onToggle;
  final ValueChanged<double> onSpeedChanged;
  final String speedTooltip;
  final String playTooltip;
  final String pauseTooltip;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: palette.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: isPlaying ? pauseTooltip : playTooltip,
            child: InkWell(
              key: playKey,
              onTap: isLoading ? null : onToggle,
              child: SizedBox.square(
                dimension: dimension,
                child: isLoading
                    ? Center(
                        child: SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.primary,
                          ),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.volume_up_outlined,
                        size: 16,
                        color: palette.primary,
                      ),
              ),
            ),
          ),
          Container(width: 1, height: 18, color: palette.line),
          PopupMenuButton<double>(
            key: speedKey,
            tooltip: speedTooltip,
            initialValue: speed,
            onSelected: onSpeedChanged,
            itemBuilder: (context) => [
              for (final rate in audioPlaybackSpeeds)
                CheckedPopupMenuItem<double>(
                  value: rate,
                  checked: rate == speed,
                  child: Text(audioRateLabel(rate)),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    audioRateLabel(speed),
                    style: AppTextStyles.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 14, color: palette.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
