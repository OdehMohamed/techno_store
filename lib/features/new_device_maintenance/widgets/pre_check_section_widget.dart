import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class PreCheckSectionWidget extends StatelessWidget {
  final List<bool> preCheckList;
  final ValueChanged<int> onCheckToggled;

  const PreCheckSectionWidget({
    Key? key,
    required this.preCheckList,
    required this.onCheckToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final checkList = [
      "Scratches",
      "Cracks",
      "Liquid Damage",
      "Missing Parts",
      "Others",
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
              const Icon(Icons.checklist_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "Device Status When Received".tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(checkList.length, (index) {
            return CheckboxListTile(
              title: Text(
                checkList[index].tr(),
                style: const TextStyle(fontSize: 14),
              ),
              value: preCheckList[index],
              onChanged: (value) => onCheckToggled(index),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      ),
    );
  }
}
