import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FloterOptionCard extends StatelessWidget {
  const FloterOptionCard({required this.label, required this.selected, required this.onTap, super.key});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: selected ? AppTheme.accent.withOpacity(0.18) : AppTheme.inputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppTheme.accent : Colors.transparent)),
        child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: selected ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))), Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? AppTheme.accent : AppTheme.textSecondary)]),
      ),
    );
  }
}
