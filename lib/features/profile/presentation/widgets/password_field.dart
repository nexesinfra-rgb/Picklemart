import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

/// Password field with show/hide toggle
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showStrengthIndicator;
  final bool showMatchIndicator;
  final bool? matchesPassword;

  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.showStrengthIndicator = false,
    this.showMatchIndicator = false,
    this.matchesPassword,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          validator: widget.validator,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon)
                : const Icon(Ionicons.lock_closed_outline),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showMatchIndicator && widget.matchesPassword != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      widget.matchesPassword == true
                          ? Ionicons.checkmark_circle
                          : Ionicons.close_circle,
                      color: widget.matchesPassword == true
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _obscureText
                        ? Ionicons.eye_outline
                        : Ionicons.eye_off_outline,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}






