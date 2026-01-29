import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class PatternDialogWidget extends StatefulWidget {
  final List<int> initialPattern;
  final ValueChanged<List<int>> onPatternSaved;

  const PatternDialogWidget({
    Key? key,
    required this.initialPattern,
    required this.onPatternSaved,
  }) : super(key: key);

  @override
  State<PatternDialogWidget> createState() => _PatternDialogWidgetState();
}

class _PatternDialogWidgetState extends State<PatternDialogWidget> {
  late List<int> tempPatternValue;

  @override
  void initState() {
    super.initState();
    tempPatternValue = List.from(widget.initialPattern);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Calculate optimal sizes for web
    final dialogWidth = width > 800 ? 500.0 : width * 0.9;
    final patternSize = width > 800 ? 350.0 : width * 0.7;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pattern,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Draw Pattern".tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (tempPatternValue.isNotEmpty)
                            Text(
                              "Pattern: ${tempPatternValue.join('-')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (tempPatternValue.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.primary,
                        tooltip: "Reset".tr(),
                        onPressed: () {
                          setState(() {
                            tempPatternValue.clear();
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tempPatternValue.isEmpty
                        ? "Draw a pattern to unlock the device".tr()
                        : tempPatternValue.length < 4
                            ? "Connect at least 4 points (${tempPatternValue.length}/4)"
                                .tr()
                            : "Pattern is ready to save! ✓".tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: tempPatternValue.length >= 4
                          ? Colors.green[700]
                          : Colors.grey[700],
                      fontWeight: tempPatternValue.length >= 4
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    height: patternSize,
                    width: patternSize,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: PatternLock(
                        selectedColor: AppColors.primary,
                        pointRadius: 10,
                        showInput: true,
                        dimension: 3,
                        relativePadding: 0.7,
                        selectThreshold: 25,
                        fillPoints: true,
                        notSelectedColor: Colors.grey[300]!,
                        onInputComplete: (List<int> input) {
                          setState(() {
                            tempPatternValue = input;
                          });
                          debugPrint("Pattern: ${tempPatternValue.toString()}");
                        },
                        setUsed: tempPatternValue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        icon:
                            Icon(Icons.close_rounded, color: Colors.grey[700]),
                        label: Text(
                          "Cancel".tr(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: tempPatternValue.length >= 4
                            ? () {
                                widget.onPatternSaved(tempPatternValue);
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                        ),
                        icon:
                            const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          "Save".tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
