import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class ProblemsSectionWidget extends StatelessWidget {
  final List<bool> problems;
  final ValueChanged<int> onProblemToggled;

  const ProblemsSectionWidget({
    Key? key,
    required this.problems,
    required this.onProblemToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final problemList = [
      "Not Working",
      "Screen",
      "Battery",
      "Charging Base",
      "Service",
      "Check",
      "Selfie Camera",
      "Main Camera",
      "Internal Headset",
      "External Headset",
      "Microphone",
      "Touch Screen",
      "Fingerprint",
      "Device Back",
      "Software",
      "Open Gmail",
      "Open iCloud",
      "Volume Button",
      "Power Button",
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "The Problem *".tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(problemList.length, (index) {
              return FilterChip(
                label: Text(problemList[index].tr()),
                selected: problems[index],
                onSelected: (selected) => onProblemToggled(index),
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        problems[index] ? AppColors.primary : Colors.grey[300]!,
                  ),
                ),
                labelStyle: TextStyle(
                  color: problems[index] ? AppColors.primary : Colors.grey[700],
                  fontWeight:
                      problems[index] ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
