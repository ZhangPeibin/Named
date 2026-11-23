import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import 'app_line_icon.dart';

class AppComposer extends StatefulWidget {
  const AppComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.sendTooltip,
    required this.onSend,
    this.isSending = false,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 4,
    this.leading,
    this.onChanged,
    this.focusNode,
    this.inputKey,
    this.sendKey,
  });

  final TextEditingController controller;
  final String hintText;
  final String sendTooltip;
  final VoidCallback onSend;
  final bool isSending;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final Widget? leading;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final Key? inputKey;
  final Key? sendKey;

  @override
  State<AppComposer> createState() => _AppComposerState();
}

class _AppComposerState extends State<AppComposer> {
  FocusNode? _internalFocus;
  var _focused = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocus)?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _internalFocus?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focused == _focusNode.hasFocus) {
      return;
    }
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final textTheme = Theme.of(context).textTheme;
    final multiline = widget.maxLines > 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(
          color: _focused ? palette.primary : palette.line,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: AppSpacing.s4),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s6,
              ),
              child: TextField(
                key: widget.inputKey,
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                textInputAction: multiline
                    ? TextInputAction.newline
                    : TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onChanged: widget.onChanged,
                onSubmitted: multiline ? null : (_) => widget.onSend(),
                style: textTheme.bodyLarge,
                cursorColor: palette.primary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                  ),
                  filled: false,
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, child) {
              final enabled =
                  widget.enabled &&
                  value.text.trim().isNotEmpty &&
                  !widget.isSending;
              return SizedBox.square(
                dimension: 40,
                child: IconButton.filled(
                  key: widget.sendKey,
                  onPressed: enabled ? widget.onSend : null,
                  tooltip: widget.sendTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    disabledBackgroundColor: palette.surfaceMuted,
                    disabledForegroundColor: palette.muted,
                    minimumSize: const Size.square(40),
                    maximumSize: const Size.square(40),
                    padding: EdgeInsets.zero,
                  ),
                  icon: widget.isSending
                      ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.onPrimary,
                          ),
                        )
                      : AppLineIcon(
                          AppLineGlyph.arrowUp,
                          size: 18,
                          color: enabled ? palette.onPrimary : palette.muted,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
