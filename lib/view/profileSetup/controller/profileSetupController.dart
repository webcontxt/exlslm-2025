import 'dart:convert';
import 'dart:io';

import 'package:crop_image/crop_image.dart';
import 'package:dreamcast/utils/dialog_constant.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/account/controller/account_controller.dart';
import 'package:dreamcast/view/account/view/account_page.dart';
import 'package:dreamcast/view/profileSetup/view/draft_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signin_with_linkedin/signin_with_linkedin.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../../model/common_model.dart';
import '../../../model/erro_code_model.dart';
import '../../../routes/my_constant.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/ui_helper.dart';
import '../../../utils/image_constant.dart';
import '../../../utils/pref_utils.dart';
import '../../../widgets/ImagePickerBottomSheet.dart';
import '../../../widgets/button/common_material_button.dart';
import '../../../widgets/dialog/custom_animated_dialog_widget.dart';
import '../../account/model/createProfileModel.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../beforeLogin/signup/model/city_res_model.dart';
import '../../beforeLogin/signup/model/state_res_model.dart';
import '../../../widgets/textview/customTextView.dart';
import '../../dashboard/dashboard_page.dart';
import '../model/ai_profile_data_model.dart';
import '../model/profile_update_model.dart';
import '../view/crop_image_page.dart';
import 'linkedInSetupController.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class EditProfileController extends GetxController {
  late final AuthenticationManager _authManager;

  final ImagePicker _picker = ImagePicker();

  //used for change the profile tab
  final selectedTabIndex = 0.obs;
  var selectedCountryCode = "+91".obs;
  var selectedCountry = "IN".obs;
  final textController = TextEditingController().obs;
  var tempOptionList = <Options>[].obs;

  //parent list of profile
  final profileFieldList = <ProfileFieldData>[].obs;
  final selectedAiMatch = <dynamic>[].obs;
  final profileImage = CroppedFile("").obs;

  final cityList = <Options>[].obs;
  final stateList = <Options>[].obs;

  var selectedCountryId = "";
  var selectedStateId = "";
  var countryCode = "";

  //parent list of profile
  //its used for profile steps
  final profileFieldStep1 = <ProfileFieldData>[].obs;
  final profileFieldStep2 = <ProfileFieldData>[].obs;
  final profileFieldStep3 = <ProfileFieldData>[].obs;
  final profileFieldStep4 = <ProfileFieldData>[].obs;

  //show loading
  var isLoading = false.obs;
  var isFirstLoading = false.obs;

  //for the name field
  var userName = "";
  var isUserEditEnable = false.obs;

  //var linkedProfileUrl = "".obs;

  CropController cropController = CropController(aspectRatio: 1.0);
  Uint8List? originalBytes;
  Uint8List? croppedBytes;

  LinkedInSetupController linkedInSetupController =
      Get.put(LinkedInSetupController());

  ///Generate,Regenerate,Ready,Progress,Connect
  @override
  void onInit() {
    _authManager = Get.find();
    super.onInit();
    userName = PrefUtils.getName() ?? "";
    _authManager.linkedinSetupDynamic();
    getProfileFields();
  }

  ///create profile field dynamic
  Future<void> getProfileFields() async {
    if (!_authManager.isLogin()) {
      return;
    }
    isFirstLoading(true);

    final createProfileModel = CreateProfileModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(url: AppUrl.getProfileFields),
    ));
    isFirstLoading(false);
    if (createProfileModel!.status! && createProfileModel.code == 200) {
      linkedInSetupController.aiButtonText.value =
          createProfileModel.body?.user?.aiButton?.status ?? "";
      linkedInSetupController
          .aiButtonAction(createProfileModel.body?.user?.aiButton?.value ?? "");
      profileFieldList.clear();
      profileFieldList.addAll(createProfileModel.body?.fields ?? []);
      profileFieldStep1.clear();
      profileFieldStep2.clear();
      profileFieldStep3.clear();
      profileFieldStep4.clear();
      profileFieldList.forEach((element){
        if(element.name == "country_code"){
          selectedCountryCode.value = element.value !=null && element.value !=""
              ? "+${element.value}"
              : "";
        }
      });
      profileFieldStep1
          .addAll(profileFieldList.where((u) => u.step == 0).toList());
      profileFieldStep2
          .addAll(profileFieldList.where((u) => u.step == 1).toList());
      profileFieldStep3
          .addAll(profileFieldList.where((u) => u.step == 2).toList());
      profileFieldStep4
          .addAll(profileFieldList.where((u) => u.step == 3).toList());
      update();
    } else {
      print(createProfileModel!.code.toString());
    }
    isFirstLoading(false);
  }

  ///used profile field
  Future<void> updateProfile(BuildContext context,
      {required bool isPublish, required isLater}) async {
    var formData = <String, dynamic>{};
    profileFieldList.clear();
    profileFieldList.addAll(profileFieldStep1);
    profileFieldList.addAll(profileFieldStep2);
    profileFieldList.addAll(profileFieldStep3);
    profileFieldList.addAll(profileFieldStep4);
    var aiFormKey = [];
    profileFieldList.forEach((element){
      if(element.name == "country_code"){
        element.value = selectedCountryCode.value ;
      }
    });
    for (int index = 0; index < profileFieldList.length; index++) {
      var mapList = [];
      var data = profileFieldList[index];
      if (data.value != null) {
        if (data.value is List) {
          for (int cIndex = 0; cIndex < data.value!.length; cIndex++) {
            mapList.add(data.value[cIndex]);
          }
          formData["${data.name}"] = mapList;
        } else {
          formData["${data.name}"] = data.value.toString();
          if (data.isAiFormField != null && data.isAiFormField == true) {
            aiFormKey.add(data.name);
          }
        }
      }
      if (isPublish == true) {
        formData["aiUpdatedFiled"] = aiFormKey;
      }
    }
    isLoading(true);

    final responseModel = ProfileUpdateModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
          body: formData,
          url: isLater ? AppUrl.onepageSaveDraft : AppUrl.updateProfile),
    ));

    isLoading(false);
    if (responseModel!.status!) {
      if (isLater == true || isPublish == true) {
        await Get.dialog(
            barrierDismissible: false,
            CustomAnimatedDialogWidget(
              title: "",
              logo: ImageConstant.icSuccessAnimated,
              description: responseModel.message ?? "",
              buttonAction: "profile".tr,
              buttonCancel: "cancel".tr,
              isHideCancelBtn: true,
              onCancelTap: () async {
                Get.back(result: "update");
              },
              onActionTap: () async {
                if (Get.isRegistered<AccountController>()) {
                  AccountController accountController = Get.find();
                  accountController.callDefaultApi();
                }
                Get.toNamed(AccountPage.routeName);
              },
            ));
        update();
      } else {
        await PrefUtils.setProfileUpdate(1);
        Get.back(result: "update");
        UiHelper.showSuccessMsg(context, responseModel.message ?? "");
        update();
      }
    } else {
      Map<String, dynamic> decoded = responseModel.body!.toJson();
      String message = "";
      for (var colour in decoded.keys) {
        message = "$message${decoded[colour] ?? ""}";
      }
      update();
      UiHelper.showFailureMsg(context, message ?? "");
    }
  }

  /// update the profile image
  Future<void> updatePicture() async {
    final File imageFile = File(profileImage.value.path);
    final int sizeInBytes = await imageFile.length();
    final double sizeInMb = sizeInBytes / (1024 * 1024);
    print('Image size: ${sizeInMb} MB');

    isLoading(true);
    ProfileUpdateModel? responseModel =
        await apiService.uploadMultipartRequest<ProfileUpdateModel>(
      url: AppUrl.updatePicture,
      fields: {},
      files: {"avatar": profileImage.value.path},
      fromJson: (json) => ProfileUpdateModel.fromJson(json),
    );
    isLoading(false);
    if (responseModel!.status!) {
      ///used for the save the image form the  local storage
      profileFieldList.firstWhere((data) => data.name == "avatar").value =
          responseModel.body?.avatar ?? "";

      if (Get.isRegistered<AccountController>()) {
        AccountController accountController = Get.find();
        accountController.callDefaultApi();
      }
      UiHelper.showSuccessMsg(null, responseModel.message ?? "");
    } else {
      UiHelper.showFailureMsg(null, responseModel.message ?? "");
    }
  }

  ///remove the profile picture
  Future<void> removePicture() async {
    isLoading(true);

    final responseModel = ProfileUpdateModel.fromJson(json.decode(
      await apiService
          .dynamicPostRequest(body: {"avatar": ""}, url: AppUrl.updatePicture),
    ));
    isLoading(false);
    if (responseModel!.status!) {
      ///used for the remove the image form the  local storage
      profileImage(CroppedFile(""));
      PrefUtils.saveProfileImage("");
      profileFieldList.firstWhere((data) => data.name == "avatar").value = "";
      if (Get.isRegistered<AccountController>()) {
        AccountController accountController = Get.find();
        accountController.callDefaultApi();
      }
      update();
      UiHelper.showSuccessMsg(null, responseModel.message ?? "");
    } else {
      UiHelper.showFailureMsg(null, responseModel.message ?? "");
    }
  }

  ///show the picker for the profile image
  void showPicker(BuildContext context, index, int step, String imgUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ImagePickerBottomSheet(
        imgUrl: imgUrl,
        onCameraTap: () => imgFromCamera(index),
        onGalleryTap: () => imgFromGallery(index),
        onRemoveTap: () => removePicture(),
      ),
    );
  }

  ///image from the camera ask the permission and crop the image
  imgFromCamera(int index) async {
    // Check current camera permission status
    PermissionStatus status = await Permission.camera.status;
    debugPrint("@@ camera status ${status.isDenied}");
    if (status.isPermanentlyDenied /*|| status.isDenied*/) {
      // If permission is denied or permanently denied
      DialogConstantHelper.showPermissionDialog();
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      final bytes = await pickedFile!.readAsBytes();
      originalBytes = bytes;
      croppedBytes = null;
      cropController = CropController(aspectRatio: 1.0);
      update();
      Get.toNamed(CropImagePage.routeName);
      // await _cropImage(pickedFile, index);
    }
  }

  ///image from the gallery ask the permission and crop the image
  imgFromGallery(int index) async {
    // Check current camera permission status
    PermissionStatus status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      // If permission is denied or permanently denied
      DialogConstantHelper.showPermissionDialog();
    }
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    final bytes = await pickedFile!.readAsBytes();
    originalBytes = bytes;
    croppedBytes = null;
    cropController = CropController(aspectRatio: 1.0);
    update();
    Get.toNamed(CropImagePage.routeName);
    // await _cropImage(pickedFile, index);
  }

  /// currently not used
  Future<void> _cropImage(_pickedFile, index) async {
    final File imageFile = File(_pickedFile.path);
    final int sizeInBytes = await imageFile.length();
    final double sizeInMb = sizeInBytes / (1024 * 1024);
    print('Image size upload beofre crop: ${sizeInMb} MB');

    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 80,
        // Adjust quality as needed
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: "cropper".tr,
              toolbarColor: colorSecondary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: true),
          IOSUiSettings(
              title: 'Cropper',
              aspectRatioLockEnabled: true, // Lock aspect ratio
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio4x3,
              ],
              hidesNavigationBar: true),
        ],
      );
      if (croppedFile != null) {
        final File imageFile = File(croppedFile.path);
        final int sizeInBytes = await imageFile.length();
        final double sizeInMb = sizeInBytes / (1024 * 1024);
        print('Image size upload cropped: $sizeInMb MB');
        File compressedFile =
            await UiHelper.compressImage(originalFile: File(croppedFile.path));

        final File imageFile1 = File(compressedFile.path);
        final int sizeInBytes1 = await imageFile1.length();
        final double sizeInMb1 = sizeInBytes1 / (1024 * 1024);
        print('Image size upload after compress: $sizeInMb1 MB');
        profileImage(CroppedFile(compressedFile.path));
        refresh();
      }
    }
  }

  //get the state by country id.
  Future<void> getState(String countryId) async {
    isLoading(true);

    final model = StateResponseModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
          body: {"country": countryId}, url: AppUrl.getStatesByCountry),
    ));

    if (model!.status! && model!.code == 200) {
      isLoading(false);
      stateList.clear();
      stateList.addAll(model.body ?? []);
    } else {
      isLoading(false);
    }
  }

  //get the cities by country id and state id
  Future<void> getCities(String countryId, String stateId) async {
    isLoading(true);

    final model = CityResponseModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
          body: {"country": countryId, "state": stateId},
          url: AppUrl.getCityByState),
    ));

    if (model!.status! && model!.code == 200) {
      isLoading(false);
      cityList.clear();
      cityList.addAll(model.body ?? []);
    } else {
      isLoading(false);
    }
  }

  /// Crop image and always return square Uint8List
  Future<Uint8List?> cropNow() async {
    Get.back();
    if (originalBytes == null) return null;

    // 1. Get crop area (Rect)
    final rect = cropController.crop; // returns Rect

    // 2. Decode image
    final originalImage = img.decodeImage(originalBytes!);
    if (originalImage == null) return null;

    // Convert rect values to pixel values
    final cropX = (rect.left * originalImage.width).toInt();
    final cropY = (rect.top * originalImage.height).toInt();
    final cropWidth = (rect.width * originalImage.width).toInt();
    final cropHeight = (rect.height * originalImage.height).toInt();

    // Force square
    final side = cropWidth < cropHeight ? cropWidth : cropHeight;

    // 3. Crop square using image package
    final croppedImage = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: side,
      height: side,
    );

    // 4. Encode cropped image
    var croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage));
    croppedBytes = croppedBytes;
    uint8ListToFile(croppedBytes);
  }

  Future uint8ListToFile(Uint8List data, {String? extension}) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}${extension ?? '.png'}');
    await file.writeAsBytes(data);

    /// Compress Image
    final File imageFile = File(file.path);
    final int sizeInBytes = await imageFile.length();
    final double sizeInMb = sizeInBytes / (1024 * 1024);
    print('Image size upload cropped: $sizeInMb MB');
    File compressedFile =
        await UiHelper.compressImage(originalFile: File(file.path));
    final File imageFile1 = File(compressedFile.path);
    final int sizeInBytes1 = await imageFile1.length();
    final double sizeInMb1 = sizeInBytes1 / (1024 * 1024);
    print('Image size upload after compress: $sizeInMb1 MB');
    profileImage(CroppedFile(compressedFile.path));
    update();
    if (profileImage.value.path.isNotEmpty) {
      updatePicture();
    }
  }
}
