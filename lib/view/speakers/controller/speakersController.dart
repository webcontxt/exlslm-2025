import 'dart:convert';

import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/view/Notes/controller/my_notes_controller.dart';
import 'package:dreamcast/view/breifcase/controller/common_document_controller.dart';
import 'package:dreamcast/view/commonController/bookmark_request_model.dart';
import 'package:dreamcast/view/schedule/controller/session_controller.dart';
import 'package:dreamcast/view/speakers/controller/speakerNetworkController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../../model/common_model.dart';
import '../../../theme/ui_helper.dart';
import '../../../utils/dialog_constant.dart';
import '../../../utils/image_constant.dart';
import '../../../widgets/dialog/custom_animated_dialog_widget.dart';
import '../../../widgets/dialog/custom_dialog_widget.dart';
import '../../Notes/model/common_notes_model.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../commonController/controller/common_chat_meeting_controller.dart';
import '../../myFavourites/controller/favourite_speaker_controller.dart';
import '../../myFavourites/model/BookmarkIdsModel.dart';
import '../../schedule/model/scheduleModel.dart';
import '../../schedule/model/speaker_webinar_model.dart';
import '../model/speaker_session_model.dart';
import '../model/speakersDetailModel.dart';
import '../view/speakers_details_page.dart';

class SpeakersDetailController extends GetxController {
  @override
  final notesController = Get.put(MyNotesController());

  late final AuthenticationManager _authenticationManager;
  AuthenticationManager get authenticationManager => _authenticationManager;

  final CommonDocumentController _documentController = Get.find();

  final commonChatMeetingController = Get.put(CommonChatMeetingController());

  final TextEditingController notesEdtController = TextEditingController();
  var isLoading = false.obs;
  var isNotesLoading = false.obs;
  var isBookmarkLoading = false.obs;
  var selectedIndex = 0.obs;

  var isBlocked = false.obs;

  //var iMReceiver = false.obs;
  final textController = TextEditingController().obs;

  ScrollController scrollController = ScrollController();
  //used for match the ids to user ids
  var bookMarkIdsList = <dynamic>[].obs;
  var recommendedIdsList = <dynamic>[].obs;

  var userIdsList = <dynamic>[];

  var userDetailBody = UserDetailBody().obs;

  var role = MyConstant.speakers;

  var selectedSort = "ASC".obs;

  var notesData = NotesDataModel().obs;
  var isEditNotes = false.obs;
  var pageTitle = "".obs;

  var speakerSessionList = [].obs;

  final SessionController _sessionController = Get.find();

  SessionController get sessionController => _sessionController;

  @override
  void onInit() {
    // Initializes the authentication manager and calls the parent onInit.
    _authenticationManager = Get.find();
    super.onInit();
  }

  /// Fetches bookmark and recommended IDs for the current user list.
  Future<void> getBookmarkAndRecommendedByIds() async {
    getBookmarkIds();
    getRecommendedIds();
  }

  /// Retrieves bookmark IDs for the current user list and updates loading state.
  Future<void> getBookmarkIds() async {
    isBookmarkLoading(true);
    bookMarkIdsList.value = await _documentController.getCommonBookmarkIds(
        items: userIdsList, itemType: role);
    isBookmarkLoading(false);
  }

  ///get the re-commanded ids from the list of user ids
  Future<void> getRecommendedIds() async {
    try {
      if (userIdsList.isEmpty) {
        return;
      }
      final model = BookmarkIdsModel.fromJson(json.decode(
        await apiService.dynamicPostRequest(
            body: {"users": userIdsList},
            url: "${AppUrl.usersListApi}/getAiRecommended"),
      ));
      if (model.status! && model.code == 200) {
        // Extract the list from the body and filter items with recommended == true
        if (model.body != null) {
          recommendedIdsList.addAll(model.body!
              .where((item) => item.isRecommended == true)
              .map((item) => item.id)
              .toList());
        }
      } else {
        print(model.code.toString());
        return;
      }
    } catch (exception) {
      debugPrint(exception.toString());
    } finally {
      // Code here will run whether or not an exception was thrown
      debugPrint("Completed the process of fetching recommended IDs");
    }
  }


  /// Clears the bookmark and recommended lists.
  void clearDefaultList() {
    bookMarkIdsList.clear();
    recommendedIdsList.clear();
  }

  /// Fetches speaker details, notes, and sessions for a given speaker.
  Future<void> getSpeakerDetail({speakerId, role, isSessionSpeaker}) async {
    if (!authenticationManager.isLogin()) {
      DialogConstantHelper.showLoginDialog(Get.context!, authenticationManager);
      return;
    }
    notesData.value.text = "";
    notesEdtController.text = "";
    isEditNotes(true);
    this.role = role;
    var body = {"id": speakerId, "role": role};
    isLoading(true);

    final model = SpeakersDetailModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: body,
        url: "${AppUrl.usersListApi}/get",
      ),
    ));

    isLoading(false);
    try {
      if (model.status! && model.code == 200) {
        userDetailBody.value = model.body!;
        isBlocked(
            userDetailBody.value.isBlocked.toString() == "1" ? true : false);

        pageTitle("${role.toString().capitalize} Profile");
        Get.toNamed(SpeakersDetailPage.routeName);
        commonChatMeetingController.getChatRequestStatus(
            isShow: false, receiverId: userDetailBody.value.id ?? "");
        getUserNotes(requestBody: {
          "item_type": role,
          "item_id": userDetailBody.value.id ?? "",
        });
        getSessionBySpeakerId(
            requestBody: {"speaker_id": userDetailBody.value.id ?? ""});
      } else {
        print(model.code.toString());
      }
    } catch (exception) {
      UiHelper.showFailureMsg(
          null, "User may be currently unavailable or Inactive.");
    }
  }

  ///refresh the session list from the book seat button
  void refreshTheSessionList(){
    getSessionBySpeakerId(
        requestBody: {"speaker_id": userDetailBody.value.id ?? ""});
  }

  /// Fetches notes for the current user and updates the notes state.
  Future<void> getUserNotes({required requestBody}) async {
    if (!authenticationManager.isLogin()) {
      return;
    }
    isNotesLoading(true);
    final model = CommonNotesModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: requestBody,
        url: AppUrl.getNotes,
      ),
    ));
    isNotesLoading(false);
    if (model.status! && model.code == 200) {
      if (model.body != null && model.body!.isNotEmpty) {
        notesEdtController.text = model.body?[0].text ?? "";
        notesData(model.body?[0]);
        isEditNotes(notesData.value.text.toString().isNotEmpty ? false : true);
      } else {
        notesData(NotesDataModel());
      }
    }
  }

  /// Saves or edits notes for the current user and updates the UI.
  Future<void> saveEditNotesApi(BuildContext context) async {
    var postRequest = {
      "id": notesData.value.id ?? "",
      "item_id": userDetailBody.value.id ?? "",
      "item_type": userDetailBody.value.role,
      "text": notesEdtController.text.trim().toString()
    };
    isLoading(true);
    var result = await notesController.addNotesToUser(postRequest);
    isLoading(false);
    if (result['status'] == true) {
      isEditNotes(!isEditNotes.value);
      notesData(NotesDataModel(text: result["text"], id: result["id"]));
      refresh();
      print(notesData);
    } else {
      notesData.value.text = "";
    }
  }

  /// Fetches sessions for a speaker and updates the session list.
  Future<void> getSessionBySpeakerId({required requestBody}) async {
    isNotesLoading(true);
    speakerSessionList.clear();
    speakerSessionList.refresh();
    final model = SpeakerSessionModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: requestBody,
        url: AppUrl.sessionBySpeakerId,
      ),
    ));
    isNotesLoading(false);
    if (model.status! && model.code == 200) {
      if (model.body != null && model.body!.isNotEmpty) {
        speakerSessionList.addAll(model.body ?? []);
        speakerSessionList.refresh();
        _sessionController.userIdsList =
            speakerSessionList.map((obj) => obj.id).toList();
        _sessionController.getBookmarkIds();
        if (speakerSessionList != null) {
          var userIdsList = speakerSessionList.map((obj) => obj.id).toList();
          _sessionController.getSpeakerWebinarList(
              sessionList: speakerSessionList, userIdsList: userIdsList);
        }
      }
    }
  }

  /*used for attendee*/
  /// Adds or removes a user from bookmarks and updates the backend.
  Future<dynamic> bookmarkToUser(dynamic id, dynamic role) async {
    if (bookMarkIdsList.contains(id)) {
      bookMarkIdsList.remove(id);
      removeItemFromBookmark(id);
    } else {
      bookMarkIdsList.add(id);
    }
    var model = await _documentController.bookmarkToItem(
        requestBody:
            BookmarkRequestModel(itemType: MyConstant.speakers, itemId: id));
    return model;
  }

  /// Removes an item from the bookmark list and updates the favorite speaker list.
  void removeItemFromBookmark(String id) {
    Future.delayed(Duration(seconds: 1), () {
      if (Get.isRegistered<FavSpeakerController>()) {
        FavSpeakerController favouriteController = Get.find();
        // Remove item where 'id' matches 'idToDelete'
        favouriteController.favouriteSpeakerList
            .removeWhere((item) => item.id == id);
        favouriteController.favouriteSpeakerList.refresh();
      }
    });
  }

  /// Shows a dialog to confirm block or unblock action for a user.
  /// Handles the API call and UI update for blocking/unblocking.
  void saveBlockUnblockDialog(
      {required context, required content, required body}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogWidget(
          title: isBlocked.value ? "Unblock?" : "Block?",
          logo: ImageConstant.block,
          description:
              "Are you sure you want to ${isBlocked.value ? "unblock" : "block"} this user.",
          buttonAction: isBlocked.value ? "Yes, Unblock" : "Yes, Block",
          buttonCancel: "Cancel",
          onCancelTap: () {},
          onActionTap: () async {
            isLoading(true);
            final model = CommonModel.fromJson(json.decode(
              await apiService.dynamicPostRequest(
                body: body,
                url: "${AppUrl.blockUnblockUser}/save",
              ),
            ));

            isLoading(false);
            if (model.status! && model.code == 200) {
              isBlocked(!isBlocked.value);
              if (isBlocked.value) {
                removeTheBlockedUser(userId: body["block_user_id"]);
              }
              await Get.dialog(
                  barrierDismissible: false,
                  CustomAnimatedDialogWidget(
                    title: "",
                    logo: ImageConstant.icSuccessAnimated,
                    description: model.body!.message ?? "",
                    buttonAction: "close".tr,
                    buttonCancel: "cancel".tr,
                    isHideCancelBtn: true,
                    onCancelTap: () {},
                    onActionTap: () async {},
                  ));
            } else {
              UiHelper.showFailureMsg(null, model.body?.message ?? "");
            }

            //Get.back();
            //;
          },
        );
      },
    );
  }

  /// Removes a blocked user from the networking attendee list and updates the count.
  void removeTheBlockedUser({userId}) {
    final SpeakerNetworkController networkingController = Get.find();
    networkingController.attendeeList.removeWhere((user) => user.id == userId);
    networkingController.getUserCount(isRefresh: false);
    networkingController.attendeeList.refresh();
  }

  /// Shares the speaker's profile using a deep link and the share package.
  void shareEvent(
    BuildContext context,
  ) {
    // Deep link to the event, replace with your actual deep link logic

    String deepLink =
        "${authenticationManager.deeplinkUrl}?page=speakers&role=$role&id=${userDetailBody.value.id}";

    // Format the content to be shared
    String shareText =
        'Meet ${userDetailBody.value.name} at Dreamcast Event app!\n'
        'Check out the speaker profile here: $deepLink';

    // Share the content using the share package
    Share.share(shareText);
  }
}
