import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ShippingEta extends StatefulWidget {
  const ShippingEta({super.key});

  @override
  State<ShippingEta> createState() => _ShippingEtaState();
}

class _ShippingEtaState extends State<ShippingEta> {
  String? _pin;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now().add(const Duration(days: 3));
    final eta = '${_month(date.month)} ${date.day}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSoft),
        color: AppColors.thumbBg,
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Delivers by $eta ${_pin != null ? 'to $_pin' : ''}'),
          ),
          TextButton(
            onPressed: () async {
              final controller = TextEditingController(text: _pin);
              final newPin = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Enter pincode'),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 560001'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Apply')),
                  ],
                ),
              );
              if (newPin != null && newPin.isNotEmpty) {
                setState(() => _pin = newPin);
              }
            },
            child: const Text('Change'),
          )
        ],
      ),
    );
  }

  String _month(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}

