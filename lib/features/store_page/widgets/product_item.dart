import 'package:flutter/material.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core/route/app_routes.dart';
import 'package:techno_store/core/utils/app_colors.dart';

class ProductItem extends StatelessWidget {
  const ProductItem({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.02),
      child: InkWell(
        onTap: () {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.productDetailsPage,
            // arguments: product,
          );
        },
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    color: AppColors.white,
                  ),
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/defaultProductImage2.png',
                          fit: BoxFit.cover,
                        ),
                      )
                      // CachedNetworkImage(
                      //   imageUrl: widget.productItem.imgUrl,
                      //   fit: BoxFit.contain,
                      //   placeholder: (context, url) => const Center(
                      //     child: CircularProgressIndicator.adaptive(),
                      //   ),
                      //   errorWidget: (context, url, error) => const Icon(
                      //     Icons.error,
                      //     color: Colors.red,
                      //   ),
                      // ),
                      ),
                ),
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.favorite_border,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            WidgetUtilities.autoSizeText("Product Name",
                textStyle: const TextStyle(
                  color: AppColors.primary,
                )),
            WidgetUtilities.autoSizeText("Product Category",
                textStyle: const TextStyle(
                  color: AppColors.grey,
                )),
            WidgetUtilities.autoSizeText("\$Product Price",
                textStyle: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
