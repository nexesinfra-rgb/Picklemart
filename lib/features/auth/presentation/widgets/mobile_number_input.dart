import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MobileNumberInput extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final String? labelText;
  final String? hintText;

  const MobileNumberInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.labelText,
    this.hintText,
  });

  @override
  State<MobileNumberInput> createState() => _MobileNumberInputState();
}

class _MobileNumberInputState extends State<MobileNumberInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Mobile Number',
        hintText: widget.hintText ?? 'Enter 10-digit mobile number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.phone),
        counterText: '', // Hide character counter
      ),
      maxLength: 10,
      onChanged: (value) {
        widget.onChanged?.call(value);
      },
      validator: widget.validator,
    );
  }
}



