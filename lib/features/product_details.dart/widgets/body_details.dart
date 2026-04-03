import 'package:flutter/material.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/widgets/main_button.dart';

class BodyDetails extends StatelessWidget {
  const BodyDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Product Name",
              softWrap: true,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.normal,
                  ),
            ),
          ],
        ),
        const Divider(
          color: AppColors.primary,
        ),
        SizedBox(
          height: size.width < 500 ? 16 : 32,
        ),
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(
                      "Category Name",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary,
                  )),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      "Price: ",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    Text(
                      '\$100',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        SizedBox(
          height: size.width < 500 ? 24 : 48,
        ),
        Text(
          "Overview",
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: AppColors.primary,
              ),
        ),
        SizedBox(
          height: size.width < 500 ? 8 : 16,
        ),
        Text(
          "Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview Overview text goes here. Overview text goes here. Overview text goes here. Overview text goes here. Overview",
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.normal,
              ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}
