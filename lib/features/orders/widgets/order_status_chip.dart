import 'package:flutter/material.dart';

import '../data/order_models.dart';

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blueAccent;
      case OrderStatus.processing:
        return Colors.deepPurple;
      case OrderStatus.outForDelivery:
        return Colors.teal;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withOpacity(.15), borderRadius: BorderRadius.circular(18)),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
