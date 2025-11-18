import 'dart:convert';
import 'dart:io';
import 'package:dreamcast/utils/pref_utils.dart';
import 'package:dreamcast/view/account/model/createProfileModel.dart';
import 'package:dreamcast/view/account/model/notes_model.dart';
import 'package:dreamcast/view/dashboard/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dreamcast/api_repository/api_service.dart';
import 'package:dreamcast/api_repository/app_url.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/view/beforeLogin/globalController/authentication_manager.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../widgets/home_menu_item.dart';
import '../../home/controller/home_controller.dart';
import '../../menu/controller/menuController.dart';
import '../../menu/model/menu_data_model.dart';
import '../../profileSetup/controller/linkedInSetupController.dart';
import '../model/profileModel.dart';

class AccountController extends GetxController {
  var isLoading = false.obs;
  var selectedIndex = 0.obs;
  final ImagePicker _picker = ImagePicker();
  ProfileBody? _profileBody;
  ProfileBody? get profileBody => _profileBody;
  XFile _xFile = XFile("");
  XFile get profileFile => _xFile;

  var profileMenu = <MenuData>[].obs;

  Rx<bool> isSelectedSwitch = false.obs;
  var notesData = NotesData().obs;

  ProfileFieldData countryCodeData = ProfileFieldData();

  var profilePicUrl = "".obs;

  set profileFile(XFile xFile) {
    _xFile = xFile;
    update();
  }

  LinkedInSetupController linkedInSetupController =
      Get.put(LinkedInSetupController());

  final AuthenticationManager _authManager = Get.find();

  /*used for the ai profile*/

  /// Called when the controller is initialized.
  ///
  /// If the user is logged in, it calls the default API to fetch profile data.
  @override
  void onInit() {
    super.onInit();
    if (_authManager.isLogin()) {
      callDefaultApi();
    }
  }

  /// Calls the default API to fetch the user's profile data.
  void callDefaultApi() {
    getProfileData(isFromDashboard: false);
  }

  /// Called when the controller is ready.
  ///
  /// Fetches the country list for the profile setup.
  @override
  void onReady() {
    super.onReady();
    getCountryList();
  }

  /// Fetches the user's profile data from the server.
  ///
  /// Updates the profile body, LinkedIn setup, and local preferences.
  Future<void> getProfileData({required isFromDashboard}) async {
    if(_profileBody==null){
      isLoading(true);
    }

    final model = ProfileModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
          body: {"id": "", "role": "", "mine": true},
          url: AppUrl.getProfileData),
    ));
    isLoading(false);
    if (model.status! && model.code == 200) {
      _profileBody = model.profileBody;
      linkedInSetupController.aiButtonText.value =
          model.profileBody?.aiButton?.status ?? "";
      linkedInSetupController
          .aiButtonAction(model.profileBody?.aiButton?.value ?? "");
      linkedInSetupController
          .linkedProfileUrl(model.profileBody?.linkedin ?? "");
      PrefUtils.saveProfileData(
        fullName: model.profileBody?.name ?? "",
        username: model.profileBody?.shortName ?? "",
        profile: model.profileBody?.avatar ?? "",
        userId: PrefUtils.getUserId() ?? "",
        role: model.profileBody?.role ?? "",
        email: PrefUtils.getEmail() ?? "",
        chatId: /*PrefUtils.getDreamcastId() ?? ""*/ "",
        category: PrefUtils.getCategory() ?? "",
      );
      profilePicUrl(model.profileBody?.avatar ?? "");
      PrefUtils.savePrivacyData(
          isChat: model.profileBody?.isChat == 1 ? true : false,
          isMeeting: model.profileBody?.isMeeting == 1 ? true : false,
          isProfile: false);

      _authManager.isMuteNotification(
          model.profileBody?.muteNotification == 1 ? true : false);
      if (model.profileBody?.isChat == 1 || model.profileBody?.isMeeting == 1) {
        isSelectedSwitch(true);
      } else {
        isSelectedSwitch(false);
      }
      update();
    } else {
      print(model.status!);
    }
  }

  //create profile dynamic
  /// Fetches the list of countries for the profile setup.
  ///
  /// Updates the countryCodeData with the country code field data.
  Future<void> getCountryList() async {
    if (!_authManager.isLogin()) {
      return;
    }

    final createProfileModel = CreateProfileModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(url: AppUrl.getProfileFields),
    ));

    if (createProfileModel!.status! && createProfileModel!.code == 200) {
      for (ProfileFieldData data in createProfileModel.body?.fields ?? []) {
        if (data.name == "country_code") {
          countryCodeData = data;
        }
      }
      update();
    } else {
      print(createProfileModel!.code.toString());
    }
  }

  /// Returns the display text for a given country code value.
  String getTextFromValue(String countryCode) {
    var value = "";
    for (var data in countryCodeData.options ?? []) {
      if (data.value == countryCode) {
        value = data.text ?? "";
      }
    }
    return value;
  }

  /// Shows a modal bottom sheet to pick an image from gallery or camera.
  void showPicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: Icon(
                      Icons.photo_library,
                      color: colorSecondary,
                    ),
                    title: const CustomTextView(
                      text: "Photo",
                      textAlign: TextAlign.start,
                    ),
                    onTap: () {
                      imgFromGallery();
                      Navigator.of(bc).pop();
                    }),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: colorSecondary),
                  title: const CustomTextView(
                      text: "Camera", textAlign: TextAlign.start),
                  onTap: () {
                    imgFromCamera();
                    Navigator.of(bc).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  /// Picks an image from the camera and updates the profile file.
  imgFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    profileFile = pickedFile!;
  }

  /// Picks an image from the gallery and updates the profile file.
  imgFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    profileFile = pickedFile!;
  }

  /// Checks if the HubController is loading content.
  ///
  /// Returns true if the HubController is registered and loading, otherwise false.
  bool isHubLoading() {
    if (Get.isRegistered<HubController>()) {
      HubController hubController = Get.find();
      return hubController.contentLoading.value;
    } else {
      return false;
    }
  }
}
