// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final bool enabled;

  const OtpInputField({
    super.key,
    required this.length,
    required this.value,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();

    // Auto-focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange(String text) {
    widget.onChanged(text);
    if (text.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Hidden master text field handling keyboard, paste, and SMS autofill
        Opacity(
          opacity: 0.0,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofillHints: const [AutofillHints.oneTimeCode],
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.length),
            ],
            onChanged: _handleTextChange,
          ),
        ),

        // Beautiful visible OTP digit cells
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.enabled) {
              _focusNode.requestFocus();
            }
          },
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (index) {
                final isCurrent = index == widget.value.length && _focusNode.hasFocus;
                final isFilled = index < widget.value.length;
                final digit = isFilled ? widget.value[index] : '';

                Color borderColor;
                if (widget.hasError) {
                  borderColor = AppTheme.errorRed;
                } else if (isCurrent) {
                  borderColor = AppTheme.deepOrange;
                } else if (isFilled) {
                  borderColor = AppTheme.deepOrange.withOpacity(0.6);
                } else {
                  borderColor = AppTheme.borderWarm;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: widget.length <= 4 ? 64 : 48,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppTheme.creamSurface
                        : (widget.hasError
                            ? AppTheme.errorBackground.withOpacity(0.5)
                            : AppTheme.creamInputFill),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: isCurrent || widget.hasError ? 2 : 1.5,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppTheme.deepOrange.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: widget.hasError
                            ? AppTheme.errorRed
                            : AppTheme.textDarkBrown,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
