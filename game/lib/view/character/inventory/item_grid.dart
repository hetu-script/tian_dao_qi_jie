import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';
import 'package:samsara/ui/rrect_icon.dart';
import 'package:samsara/pointer_detector.dart';

import '../../../ui.dart';
// import '../../../common.dart';
import '../../../state/hover_info.dart';

const kDefaultItemGridSize = Size(48.0, 48.0);

class ItemGrid extends StatelessWidget {
  const ItemGrid({
    super.key,
    this.size = kDefaultItemGridSize,
    this.itemData,
    this.onTapped,
    this.onSecondaryTapped,
    this.hasBorder = true,
    this.isSelected = false,
    this.isEquipped = false,
    this.child,
    this.backgroundImage,
    this.showEquippedIcon = true,
  });

  final Size size;
  final dynamic itemData;
  final void Function(dynamic itemData, Offset screenPosition)? onTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onSecondaryTapped;
  final bool hasBorder;
  final bool isSelected, isEquipped;
  final Widget? child;
  final ImageProvider<Object>? backgroundImage;
  final bool showEquippedIcon;

  @override
  Widget build(BuildContext context) {
    final String? iconAssetKey = itemData?['icon'];
    final int stackSize = itemData?['stackSize'] ?? 1;
    // final entityType = entityData?['entityType'];

    final isEquipped = itemData?['category'] == 'equipment' &&
        itemData?['equippedPosition'] != null;

    return Material(
      type: MaterialType.transparency,
      child: PointerDetector(
        cursor: itemData != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onMouseEnter: (event) {
          if (itemData == null) {
            return;
          }
          final Rect rect = getRenderRect(context);
          context.read<HoverInfoContentState>().set(itemData, rect);
        },
        onMouseExit: (event) {
          context.read<HoverInfoContentState>().hide();
        },
        onTapUp: (pointer, buttons, details) {
          if (itemData == null) return;
          if (buttons == kPrimaryButton) {
            onTapped?.call(itemData, details.globalPosition);
          } else if (buttons == kSecondaryButton) {
            onSecondaryTapped?.call(itemData, details.globalPosition);
          }
        },
        child: Container(
          width: size.width,
          height: size.height,
          decoration: hasBorder
              ? BoxDecoration(
                  color: GameUI.backgroundColor,
                  border: Border.all(
                    color: isSelected
                        ? Colors.yellow
                        : GameUI.foregroundColor.withAlpha(64),
                  ),
                  image: backgroundImage != null
                      ? DecorationImage(
                          fit: BoxFit.contain,
                          image: backgroundImage!,
                          opacity: 0.2,
                        )
                      : null,
                  borderRadius: GameUI.borderRadius,
                )
              : null,
          child: Stack(
            children: [
              if (iconAssetKey != null)
                RRectIcon(
                  image: AssetImage('assets/images/$iconAssetKey'),
                  size: size,
                  borderRadius: GameUI.borderRadius,
                  borderColor: Colors.transparent,
                  borderWidth: 0.0,
                ),
              if (child != null) child!,
              if (stackSize > 1)
                Align(
                  alignment: AlignmentDirectional.bottomEnd,
                  child: Text(stackSize.toString()),
                ),
              if (showEquippedIcon && isEquipped)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: Image(
                      width: size.width / 3,
                      height: size.height / 3,
                      fit: BoxFit.contain,
                      image:
                          const AssetImage('assets/images/item/equipped.png'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
