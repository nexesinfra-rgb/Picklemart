import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryScroller extends StatefulWidget {
  const CategoryScroller({super.key});

  @override
  State<CategoryScroller> createState() => _CategoryScrollerState();
}

class _CategoryScrollerState extends State<CategoryScroller> {
  int selected = 0;
  final categories = const [
    _Category('Pickles', Ionicons.restaurant_outline, Color(0xFFEFF6FF)),
    _Category('Karam\nPodis', Ionicons.flame_outline, Color(0xFFFFF7ED)),
    _Category('Spice\nPowders', Ionicons.cafe_outline, Color(0xFFFEFCE8)),
    _Category('Masalas', Ionicons.sparkles_outline, Color(0xFFF0FDF4)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSel = i == selected;
          return GestureDetector(
            onTap: () => setState(() => selected = i),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSel ? AppColors.primary : AppColors.outlineSoft),
                  ),
                  child: Icon(c.icon, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 72,
                  child: Text(
                    c.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSel ? Colors.black : AppColors.textSecondary,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Category {
  final String label;
  final IconData icon;
  final Color bg;
  const _Category(this.label, this.icon, this.bg);
}

