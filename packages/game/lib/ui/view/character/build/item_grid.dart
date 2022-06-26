import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';

const kItemGridDefaultSize = 48.0;

class ItemGrid extends StatelessWidget {
  const ItemGrid({
    super.key,
    this.size = kItemGridDefaultSize,
    this.verticalMargin = 5.0,
    this.horizontalMargin = 5.0,
    this.data,
    required this.onSelect,
  });

  final double size;
  final double verticalMargin;
  final double horizontalMargin;
  final HTStruct? data;
  final void Function(HTStruct item, Offset screenPosition) onSelect;

  @override
  Widget build(BuildContext context) {
    final iconAssetKey = data?['icon'];

    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        if (data != null) {
          onSelect(data!, details.globalPosition);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: data?['name'] ?? '',
          child: Container(
            width: size,
            height: size,
            margin: EdgeInsets.symmetric(
                vertical: verticalMargin, horizontal: horizontalMargin),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              // border: Border.all(
              //   color: Colors.white54,
              //   width: 2,
              // ),
              image: const DecorationImage(
                fit: BoxFit.contain,
                image: AssetImage('assets/images/icon/item/grid.png'),
              ),
              borderRadius: kBorderRadius,
            ),
            child: iconAssetKey != null
                ? Image(
                    fit: BoxFit.contain,
                    image: AssetImage('assets/images/$iconAssetKey'),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
