import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import 'app_line_icon.dart';

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
    this.dimension = 28,
    this.label,
    this.color,
    this.iconSize = 12,
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
  final String? label;
  final Color? color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = color ?? palette.muted;

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
              child: _PlayIcon(
                dimension: dimension,
                label: label,
                isLoading: isLoading,
                isPlaying: isPlaying,
                color: accent,
                iconSize: iconSize,
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
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppLineIcon(
                    AppLineGlyph.chevronDown,
                    size: 14,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayIcon extends StatelessWidget {
  const _PlayIcon({
    required this.dimension,
    required this.label,
    required this.isLoading,
    required this.isPlaying,
    required this.color,
    required this.iconSize,
  });

  final double dimension;
  final String? label;
  final bool isLoading;
  final bool isPlaying;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final glyph = isLoading
        ? Center(
            child: SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
          )
        : AppLineIcon(
            isPlaying ? AppLineGlyph.pause : AppLineGlyph.play,
            size: iconSize,
            color: color,
          );

    if (label == null) {
      return SizedBox.square(
        dimension: dimension,
        child: Center(child: glyph),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          glyph,
          const SizedBox(width: AppSpacing.s6),
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
