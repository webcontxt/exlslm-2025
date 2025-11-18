
import 'dart:io';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/photobooth/controller/multiImageUploadController.dart';
import 'package:dreamcast/widgets/app_bar/appbar_leading_image.dart';
import 'package:dreamcast/widgets/app_bar/custom_app_bar.dart';
import 'package:dreamcast/widgets/dialog/custom_animated_dialog_widget.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:dreamcast/widgets/toolbarTitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';

class MultiImageUploader extends StatelessWidget {

  MultiImageUploader({super.key});


  MultiImageUploadController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async{
        // If the user tries to pop while uploading, show a dialog
        if (controller.isUploading.value && controller.imagesToUpload.isNotEmpty) {
          await Get.dialog(
            barrierDismissible: false,
            CustomAnimatedDialogWidget(
              title: "uploading_progress".tr,
              logo: "",
              description: "wait_upload_image".tr,
              buttonAction: "okay".tr,
              buttonCancel: "",
              isHideCancelBtn: true,
              onCancelTap: () {},
              onActionTap: () {
              },
            ),
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          height: 72.v,
          leadingWidth: 45.h,
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeft,
            margin: EdgeInsets.only(
              left: 7.h,
              top: 3,
              // bottom: 12.v,
            ),
            onTap: () async{
              if (controller.isUploading.value && controller.imagesToUpload.isNotEmpty) {
                await Get.dialog(
                  barrierDismissible: false,
                  CustomAnimatedDialogWidget(
                    title: "uploading_progress".tr,
                    logo: "",
                    description: "wait_upload_image".tr,
                    buttonAction: "okay".tr,
                    buttonCancel: "",
                    isHideCancelBtn: true,
                    onCancelTap: () {},
                    onActionTap: () {
                    },
                  ),
                );
                return;
              }else{
                Get.back();
              }

            },
          ),
          title: const ToolbarTitle(
              title: "Uploads"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Obx(() => controller.startUploading.value
            ? const SizedBox()
            : controller.imagesToUpload.isNotEmpty
            ? ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          ),
          onPressed: controller.uploadImages,
          icon: Icon(Icons.upload, color: white),
          label: CustomTextView(
            text: "Upload",
            color: white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        )
            :  const SizedBox()),
        body: GetBuilder<MultiImageUploadController>(
          builder: (_) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: CustomTextView(
                    text: "Total Photos (${controller.imagesToUpload.length})",
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.imagesToUpload.length,
                    itemBuilder: (context, index) {
                      final file = controller.imagesToUpload[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: lightGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ListTile(
                              title: CustomTextView(
                                text: file.path.length > 20
                                    ? file.path.substring(file.path.length - 20)
                                    : file.path,
                                fontSize: 16,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 7),
                                  CustomTextView(
                                    text: "Size : ${controller.imageSizesMB[index].toStringAsFixed(2)} MB",
                                    fontSize: 12,
                                    color: gray,
                                  ),
                                    const SizedBox(height: 7),
                                  if (controller.startUploading.value)
                                    LinearProgressIndicator(
                                      value: controller.uploadProgress[index].value,
                                      color: colorEndCompleted,
                                      backgroundColor: borderColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      controller.uploadProgress[index].value == 1.0
                                          ? Row(
                                        children: [
                                          Image.asset(
                                            ImageConstant.check,
                                            width: 14.h,
                                            height: 14.v,
                                          ),
                                          const SizedBox(width: 5),
                                          CustomTextView(text: "Uploaded", color: gray, fontSize: 14),
                                        ],
                                      )
                                          : controller.startUploading.value
                                          ?  CustomTextView(text: "Uploading...", color: gray, fontSize: 14)
                                          : const SizedBox(),
                                      if (controller.startUploading.value)
                                      CustomTextView(
                                        text: "${(controller.uploadProgress[index].value * 100).toStringAsFixed(0)}%",
                                        color: gray,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(file.path),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (!controller.startUploading.value)
                              Padding(
                                padding: EdgeInsets.only(right: 9.0.h, top: 5.v),
                                child: InkWell(
                                  onTap: () => controller.removeImage(index),
                                  child: Icon(Icons.clear, color: darkGray, size: 20.h),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
