import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dreamcast/api_repository/api_service.dart';
import 'package:dreamcast/api_repository/app_url.dart';
import 'package:dreamcast/model/erro_code_model.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/widgets/dialog/custom_animated_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';

class MultiImageUploadController extends GetxController {

  // Variables to hold the state of the image upload process
  late List<RxDouble> uploadProgress;
  // List to track whether each image has been uploaded
  late List<RxBool> isUploaded;
  // List to hold the sizes of the images in MB
  late List<double> imageSizesMB;
  // List to hold the images to be uploaded
  late RxList<XFile> imagesToUpload;
  // Variables to track the upload status
  RxBool startUploading = false.obs;
  // Variable to indicate if the upload is in progress
  RxBool isUploading = false.obs;

  MultiImageUploadController();


  void init(List<XFile> imageFiles) {
    imagesToUpload = RxList<XFile>.from(imageFiles);
    uploadProgress = List.generate(imagesToUpload.length, (_) => 0.0.obs);
    isUploaded = List.generate(imagesToUpload.length, (_) => false.obs);
    imageSizesMB = imagesToUpload.map(_getFileSizeInMB).toList();
  }

  /// Calculates the size of the file in MB.
  double _getFileSizeInMB(XFile file) {
    final bytes = File(file.path).lengthSync();
    return bytes / (1024 * 1024);
  }

  ///Removes an image from the list of images to upload.
  void removeImage(int index) {
    imagesToUpload.removeAt(index);
    uploadProgress = List.generate(imagesToUpload.length, (_) => 0.0.obs);
    isUploaded = List.generate(imagesToUpload.length, (_) => false.obs);
    imageSizesMB = imagesToUpload.map(_getFileSizeInMB).toList();
    update();
  }

  /// Handles the upload of multiple images to the server.
  ///
  /// Iterates through the list of images, prepares the form data, tracks upload progress, and handles the server response for each image.
  /// Updates the upload progress and image size for each image, and processes error codes if returned by the server.
  Future<void> uploadImages() async {
    isUploading.value = true;
    startUploading.value = true;
    int uploadedCount = 1;
    Dio dio = Dio();

    for (int i = 0; i < imagesToUpload.length; i++) {
      final file = imagesToUpload[i];

      if (!imagesToUpload.contains(file)) continue;

      final fileSize = await File(file.path).length();
      final sizeInMB = fileSize / (1024 * 1024);
      imageSizesMB[i] = sizeInMB;

      FormData formData = FormData.fromMap({
        "image":
            await MultipartFile.fromFile(file.path, filename: "image_$i.jpg"),
        "type": "file",
      });

      try {
        final response = await dio.post(
          AppUrl.uploadAiPhoto,
          data: formData,
          onSendProgress: (sent, total) {
            if (total != -1) {
              uploadProgress[i].value = sent / total;
              update();
            }
          },
          options: Options(
            headers: ApiService().getHeaders(isMultipart: true),
          ),
        );

        final responseData = response.data is String
            ? json.decode(response.data)
            : response.data;

        if (ErrorCodeModel.fromJson(responseData).code == 440) {
          ApiService().tokenExpire(AppUrl.uploadAiPhoto);
        }

        if (imagesToUpload.length == uploadedCount) {
          if (Get.isDialogOpen == true) {
            Get.back(); // Dismiss the existing dialog
          }
          await Get.dialog(
            barrierDismissible: false,
            CustomAnimatedDialogWidget(
              title: "",
              logo: ImageConstant.icSuccessAnimated,
              description: responseData['message'] ?? "upload_success".tr,
              buttonAction: "okay".tr,
              buttonCancel: "cancel".tr,
              isHideCancelBtn: true,
              onCancelTap: () {},
              onActionTap: () {},
            ),
          );
          isUploading.value = false; // uploading finished
          break;
        }
        isUploaded[i].value = true;
        uploadedCount++;
      } catch (e) {
        debugPrint("Upload failed for image $i: $e");
        isUploaded[i].value = false;
      }
      update();
    }
  }
}
