import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../utils/image_constant.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  final String imgUrl;
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onRemoveTap;

  const ImagePickerBottomSheet({
    Key? key,
    required this.imgUrl,
    this.onCameraTap,
    this.onGalleryTap,
    this.onRemoveTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Image URL: $imgUrl");
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 8),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomTextView(
                    text: "choose_photo".tr,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: colorSecondary,
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(color: Colors.grey.shade300),
              // Gallery
              ListTile(
                leading: SvgPicture.asset(
                  ImageConstant.noImage,
                  height: 22,
                  width: 22,
                ),
                title: CustomTextView(
                  text: "photo".tr,
                  color: colorSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (onGalleryTap != null) onGalleryTap!();
                },
              ),

              // Camera
              ListTile(
                leading: SvgPicture.asset(
                  ImageConstant.camera,
                  height: 22,
                  width: 22,
                ),
                title: CustomTextView(
                  text: "camera".tr,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (onCameraTap != null) onCameraTap!();
                },
              ),

              // Remove (only if image exists)
              if (imgUrl.isNotEmpty)
                ListTile(
                  leading: SvgPicture.asset(
                    ImageConstant.deletePost,
                    height: 22,
                    width: 22,
                  ),
                  title: CustomTextView(
                    text: "remove_image".tr,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onRemoveTap != null) onRemoveTap!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
