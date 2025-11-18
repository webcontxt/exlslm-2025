import 'package:crop_image/crop_image.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/profileSetup/controller/draftProfileController.dart';
import 'package:dreamcast/view/profileSetup/controller/profileSetupController.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CropImagePage extends GetView<EditProfileController> {
  static const routeName = "/CropImagePage";

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black,
          leading: const SizedBox(),
          centerTitle: true,
          title: CustomTextView(
            text: "Crop Image",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 28.fSize,
          ),
        ),
        body: Column(
          children: [
            // Cropping area
            Expanded(
              child: controller.originalBytes != null
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CropImage(
                        controller: controller.cropController,
                        gridThickWidth: 5,
                        paddingSize: 8,
                        image: Image.memory(controller.originalBytes!),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: white,
                      side: BorderSide(color: white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Get.back(),
                    child: CustomTextView(text: "Cancel", color: white),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                    ),
                    onPressed: controller.cropNow,
                    child: CustomTextView(text: "Apply", color: white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CropImagePageDraft extends GetView<DraftProfileController> {
  static const routeName = "/CropImagePageDraft";

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black,
          leading: const SizedBox(),
          centerTitle: true,
          title: CustomTextView(
            text: "Crop Image",
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 28.fSize,
          ),
        ),
        body: Column(
          children: [
            // Cropping area
            Expanded(
              child: controller.originalBytes != null
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CropImage(
                        controller: controller.cropController,
                        gridThickWidth: 5,
                        paddingSize: 8,
                        image: Image.memory(controller.originalBytes!),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: white,
                      side: BorderSide(color: white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Get.back(),
                    child: CustomTextView(text: "Cancel", color: white),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                    ),
                    onPressed: controller.cropNow,
                    child: CustomTextView(text: "Apply", color: white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
