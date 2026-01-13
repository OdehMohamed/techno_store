import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/product_details.dart/widgets/body_details.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    bool engLang = !Utilities.isEnglish(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: Padding(
              padding: EdgeInsets.only(
                left:
                    width < 500 ? (Utilities.isEnglish(context) ? 16 : 0) : 16,
                top: width < 500 ? 0 : 25,
                right: width < 500
                    ? Utilities.isEnglish(context)
                        ? 0
                        : 16
                    : 100,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  // borderRadius: BorderRadius.circular(16),
                  color: AppColors.secondary,
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primary,
                    size: width < 500 ? 24 : 32,
                  ),
                ),
              ),
            ),
            leadingWidth: width < 500 ? 60 : 210,
            toolbarHeight: width < 500 ? 70 : 70,
            expandedHeight: height * 0.45,
            pinned: true,
            floating: true,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(
                    !engLang
                        ? 0
                        : width <= 500
                            ? width * 0.4
                            : width < 1025
                                ? width * 0.2
                                : width * 0.15,
                  ),
                  bottomRight: Radius.circular(
                    engLang
                        ? 0
                        : width <= 500
                            ? width * 0.4
                            : width < 1025
                                ? width * 0.2
                                : width * 0.15,
                  ),
                ),
                child: Image.asset(
                  'assets/images/defaultProductImage2.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
                // child: CachedNetworkImage(
                //   imageUrl: ApiPaths.imagePath + movie.posterPath,
                //   fit: BoxFit.cover,
                //   filterQuality: FilterQuality.high,
                // ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.10,
                vertical: height * 0.02,
              ),
              child: const BodyDetails(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: kIsWeb ? height * 0.02 : 0,
          ),
          child: MainButton(
            label: 'Added to Cart (Coming soon)',
            onPressed: () {},
            width: width < 500 ? width * 0.9 : width * 0.5,
          ),
        ),
      ),
    );
  }
}
