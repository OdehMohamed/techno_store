import 'package:flutter/material.dart';
import 'package:techno_store/features/store_page/widgets/filter_buttons.dart';
import 'package:techno_store/features/store_page/widgets/product_item.dart';

class InnerStorePage extends StatefulWidget {
  const InnerStorePage({Key? key}) : super(key: key);

  @override
  State<InnerStorePage> createState() => _InnerStorePageState();
}

class _InnerStorePageState extends State<InnerStorePage> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        const FilterButtons(),
        const SizedBox(
          height: 10,
        ),
        const Divider(),
        Expanded(
          child: GridView.builder(
            itemCount: 100,
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width < 500
                  ? 2
                  : width < 1025
                      ? 4
                      : 6,
              mainAxisSpacing: 10,
              // crossAxisSpacing: 0,
            ),
            itemBuilder: (context, index) {
              return const ProductItem();
            },
          ),
        ),
      ],
    );
  }
}
