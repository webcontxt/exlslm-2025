import 'package:dreamcast/core/extension/content_extension.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:flutter_svg/svg.dart';

import '../../theme/app_decoration.dart';

class CommonGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color, textColor, borderColor;
  final double textSize;
  final double height;
  final double? width;
  final double radius;
  final double borderWidth;
  final FontWeight weight;
  final String? svgIcon;
  final Color? svgIconColor;
  final double? iconHeight;
  final bool isLoading;
  final bool isWrap;

  const CommonGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.textSize = 20,
    this.height = 55,
    this.width,
    this.radius = 10,
    this.svgIcon,
    this.svgIconColor,
    this.borderWidth = 0,
    this.borderColor,
    this.iconHeight,
    this.isLoading = false,
    this.isWrap = false,
    this.weight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    final themeTextColor = textColor ?? Theme.of(context).highlightColor;
    final themeBorderColor = borderColor ?? Colors.transparent;
    final size = MediaQuery.of(context).size;

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Container(
          margin: isWrap
              ? null
              : EdgeInsets.fromLTRB(0, 10, 0, svgIcon != null ? 0 : 10),
          width: isWrap ? null : width ?? size.width,
          height: height,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.1,
              colors: [
                buttonGradientColor1,
                buttonGradientColor2,
              ],
              focalRadius: 0.0,
              stops: const [0.1, 1.0],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MaterialButton(
            elevation: 0,
            animationDuration: const Duration(milliseconds: 300),
            disabledColor: themeColor,
            hoverColor: themeColor.withOpacity(0.85),
            splashColor: themeColor.withOpacity(0.65),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: BorderSide(
                color: themeBorderColor,
                width: borderWidth,
              ),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: isLoading
                ? () {
              print("Button is disabled due to loading state.");
            }
                : () {
              print("Button Pressed: $text");
              onPressed(); // Invoke the actual onPressed callback here
            },
            child: isLoading
                ? SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                color: themeTextColor,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (svgIcon != null) ...[
                  SvgPicture.asset(svgIcon!,
                      height: iconHeight ?? 12,
                      colorFilter: ColorFilter.mode(
                          svgIconColor ??
                              Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn)),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: CustomTextView(
                    text: text,
                    color: colorSecondary,
                    fontSize: textSize,
                    fontWeight: weight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
