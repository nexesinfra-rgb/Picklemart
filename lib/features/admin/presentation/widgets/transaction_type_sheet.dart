import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

class TransactionTypeSheet extends StatelessWidget {
  const TransactionTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                title: 'Add Purchase',
                icon: Ionicons.cart_outline,
                color: Colors.blue,
                onTap: () {
                  context.pop(); // Close sheet
                  context.pushNamed('admin-purchase-order-form');
                },
              ),
              _buildOption(
                context,
                title: 'Add Sale',
                icon: Ionicons.receipt_outline,
                color: Colors.green,
                onTap: () {
                  context.pop(); // Close sheet
                  context.pushNamed('admin-create-order');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                title: 'Payment In',
                icon: Ionicons.arrow_down_circle_outline,
                color: Colors.orange,
                onTap: () {
                  context.pop(); // Close sheet
                  context.pushNamed('admin-payment-receipt');
                },
              ),
              _buildOption(
                context,
                title: 'Payment Out',
                icon: Ionicons.arrow_up_circle_outline,
                color: Colors.red,
                onTap: () {
                  context.pop(); // Close sheet
                  context.pushNamed('admin-payment-out');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCloseButton(context),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return InkWell(
      onTap: () => context.pop(),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: const Icon(Ionicons.close, color: Colors.grey),
      ),
    );
  }
}
