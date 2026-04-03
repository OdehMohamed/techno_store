import 'package:flutter/material.dart';
import 'package:techno_store/core/utils/app_colors.dart';

class GridCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  const GridCard(
      {super.key,
      required this.label,
      required this.onTap,
      this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : AppColors.white,
          border: Border.all(
            color: AppColors.secondary,
            width: 2,
          ),
          boxShadow: List.filled(
            2,
            const BoxShadow(
              color: AppColors.grey,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              textAlign: TextAlign.center,
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
