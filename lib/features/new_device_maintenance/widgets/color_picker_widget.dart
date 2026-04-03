import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:techno_store/core/utils/app_colors.dart';

class ColorPickerWidget extends StatefulWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final List<Color> predefinedColors;

  const ColorPickerWidget({
    Key? key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.predefinedColors,
  }) : super(key: key);

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  bool colorPickerExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                  const Icon(Icons.palette_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    "Device Color".tr(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.selectedColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.predefinedColors.map((color) {
                  final isSelected = color.value == widget.selectedColor.value;
                  return InkWell(
                    onTap: () => widget.onColorChanged(color),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () =>
                    setState(() => colorPickerExpanded = !colorPickerExpanded),
                icon: Icon(
                  colorPickerExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
                label: Text(
                  colorPickerExpanded
                      ? "Hide Color Picker".tr()
                      : "More Colors".tr(),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
              if (colorPickerExpanded) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColorPicker(
                    pickerColor: widget.selectedColor,
                    onColorChanged: widget.onColorChanged,
                    pickerAreaHeightPercent: 0.5,
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: const [],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
