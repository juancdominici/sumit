import 'package:flutter/material.dart';

class KeypadButton extends StatefulWidget {
  final Widget content;
  final bool primary;
  final VoidCallback onPressed;
  const KeypadButton({
    super.key,
    this.primary = false,
    required this.content,
    required this.onPressed,
  });

  @override
  State<KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<KeypadButton> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return TextButton(
      style: ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
        ),
        backgroundColor:
            widget.primary
                ? WidgetStateProperty.all<Color>(
                  primaryColor.withValues(alpha: .4),
                )
                : WidgetStateProperty.all<Color>(
                  primaryColor.withValues(alpha: .1),
                ),
      ),
      onPressed: widget.onPressed,
      child: widget.content,
    );
  }
}
