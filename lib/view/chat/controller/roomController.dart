import 'dart:async';
import 'package:dreamcast/api_repository/app_url.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/view/breifcase/controller/common_document_controller.dart';
import 'package:dreamcast/view/chat/model/parent_room_model.dart';
import 'package:dreamcast/view/dashboard/dashboard_controller.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/pref_utils.dart';
import '../../../widgets/dialog/custom_animated_dialog_widget.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../model/profile_model.dart';
import '../model/room_model.dart';
import '../model/user_model.dart';
import '../view/chat_detail.dart';

class RoomController extends GetxController {
  final DashboardController dashboardController = Get.find();
  final AuthenticationManager _authManager = Get.find();
  final CommonDocumentController documentController = Get.find();

  AuthenticationManager get authManager => _authManager;

  final String title = 'Home Title';
  var loading = false.obs;
  String mRoomId = "";
  var tabList = ["Active Chats", "Request Received", "Request Sent"];

  var chatList = <ParentRoomModel>[].obs;
  var filterChatList = [].obs;

  late StreamSubscription<DatabaseEvent> _onChildChangeListener;
  late StreamSubscription<DatabaseEvent> _onChildAddedListener;
  var isFromNotification = false;
  var activeChatItemCount = 0.obs;
  var requestedChatItemCount = 0.obs;
  var sentChatItemCount = 0.obs;

  var activeChatItem = [].obs;
  var receivedChatItem = [].obs;
  var sendChatItem = [].obs;

  @override
  void onInit() {
    super.onInit();
    initRoomRef();
    if (Get.arguments != null && Get.arguments["chat_data"] != null) {
      ///open the chat detail page after click on notification.
      /*try {
        var data = Get.arguments["chat_data"];
        Future.delayed(const Duration(milliseconds: 10), () {
          openChatPageFromAlert(UserModel(
              iam: data["iam"],
              chatRequestStatus: int.parse(data["chat_req_status"] ?? "0"),
              userId: data["user_id"],
              fullName: data["full_name"],
              shortName: data["short_name"],
              avtar: data["avtar"],
              roomId: data["room_id"]));
        });
      } catch (exception) {
        debugPrint(exception.toString());
      }*/
    }
  }

  ///no room id need here
  initRoomRef() async {
    chatList.clear();
    filterChatList.clear();

    final initialDataSnapshot = await authManager.firebaseDatabase
        .ref(AppUrl.defaultFirebaseNode)
        .child(AppUrl.chatUsers)
        .child(PrefUtils.getUserId() ?? "")
        .once();

    int totalChildren = initialDataSnapshot.snapshot.children.length;
    int processedChildren = 0;
    loading(true);
    //used for get all room details here.
    _onChildAddedListener = authManager.firebaseDatabase
        .ref(AppUrl.defaultFirebaseNode)
        .child(AppUrl.chatUsers)
        .child(PrefUtils.getUserId() ?? "")
        .orderByChild('datetime')
        .onChildAdded
        .listen((snapshot) async {
      final profileModel = await getUserData(snapshot.snapshot.key ?? "");
      await onChildAddedListenerSnapshot(snapshot, profileModel);
      processedChildren++;
      // Check if all initial children are processed
      if (processedChildren == totalChildren) {
        updateTheChatList();
      }
    });

    ///used for on child change
    _onChildChangeListener = authManager.firebaseDatabase
        .ref(AppUrl.defaultFirebaseNode)
        .child(AppUrl.chatUsers)
        .child(PrefUtils.getUserId() ?? "")
        .onChildChanged
        .listen((snapshot) {
      print("onChildChanged");
      onChildChangeEventsSnapshot(snapshot);
    });
    Future.delayed(const Duration(seconds: 4), () {
      loading(false);
    });
  }

  /// Fetches the user data for a given user ID from Firebase.
  ///
  /// Returns a [ChatProfileModel] with the user's profile information if found, otherwise returns an empty model.
  Future<ChatProfileModel> getUserData(String userId) async {
    final snapshot = await authManager.firebaseDatabase
        .ref(AppUrl.defaultFirebaseNode)
        .child("users")
        .child(userId)
        .get();
    if (snapshot.value != null) {
      final json = snapshot.value! as Map<dynamic, dynamic>;
      print(json);
      return ChatProfileModel.fromJson(json);
    } else {
      return ChatProfileModel("", "", "", "", "", "");
    }
  }

  /// Handles the event when a child is added to the chat users node in Firebase.
  ///
  /// Processes the event and updates the chat list with the new profile model if provided.
  Future<void> onChildAddedListenerSnapshot(
      DatabaseEvent event, ChatProfileModel? profileModel) async {
    if (event.snapshot.value != null) {
      final json = event.snapshot.value as Map<dynamic, dynamic>;
      final message = RoomModel.fromJson(json);
      print(json);
      var parentRoomModel = ParentRoomModel(
          receiverId: event.snapshot.key,
          roomModel: message,
          chatProfileModel: profileModel);
      chatList.add(parentRoomModel);
      filterChatList.add(parentRoomModel);
    } else {
      loading(false);
    }
  }

  /// Handles the event when a child is changed in the chat users node in Firebase.
  void onChildChangeEventsSnapshot(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final jsonData = event.snapshot.value as Map<dynamic, dynamic>;
      for (int i = 0; i < chatList.length; i++) {
        ParentRoomModel temp = chatList[i];
        if (temp.receiverId == event.snapshot.key) {
          final roomModel = RoomModel.fromJson(jsonData);
          filterChatList[i].roomModel = roomModel;
          chatList[i].roomModel = roomModel;
        }
      }
      chatList.refresh();
      filterChatList.refresh();
      updateTheChatList();
      update();
    }
  }

  /// Filters the chat list based on the search query.
  filterSearchResults(String query) {
    if (query.isNotEmpty) {
      List<ParentRoomModel> dummyListData = [];
      for (var item in chatList) {
        if ((item.chatProfileModel?.name?.toLowerCase())!
            .contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      }
      activeChatItem.clear();
      activeChatItem.addAll(dummyListData);
      print("activeChatItem.length");
      return;
    } else {
      activeChatItem.clear();
      activeChatItem.addAll(chatList);
    }
  }

  /// Updates the chat list by fetching active, received, and sent chat items.
  updateTheChatList() {
    loading(false);
    getActiveChatList();
    getReceivedChatList();
    getSentChatList();
  }

  /// Gets the list of active chat items where the room status is 1 (active).
  getActiveChatList() {
    List outputList = chatList
        .where((parentRoomModel) => parentRoomModel.roomModel?.status == 1)
        .toList();
    outputList.sort((a, b) {
      var date1 = b.roomModel?.dateTime.toString();
      var date2 = a.roomModel?.dateTime.toString();
      return date1!.compareTo(date2!);
    });
    activeChatItemCount(outputList.length);
    activeChatItem.clear();
    activeChatItem.addAll(outputList);
    refresh();
  }

  /// Gets the list of received chat items where the user is not the initiator.
  getReceivedChatList() {
    List outputList = chatList
        .where((parentRoomModel) =>
            parentRoomModel.roomModel?.status == 0 &&
            parentRoomModel.roomModel?.iam != PrefUtils.getUserId())
        .toList();

    outputList.sort((a, b) {
      var date1 = b.roomModel?.dateTime.toString();
      var date2 = a.roomModel?.dateTime.toString();
      return date1!.compareTo(date2!);
    });

    requestedChatItemCount(outputList.length);
    receivedChatItem.clear();
    receivedChatItem.addAll(outputList);
    refresh();
  }

  /// Gets the list of sent chat messages.
  getSentChatList() {
    List outputList = chatList
        .where((parentRoomModel) =>
            parentRoomModel.roomModel?.status == 0 &&
            parentRoomModel.roomModel?.iam == PrefUtils.getUserId())
        .toList();

    outputList.sort((a, b) {
      var date1 = b.roomModel?.dateTime.toString();
      var date2 = a.roomModel?.dateTime.toString();
      return date1!.compareTo(date2!);
    });

    sentChatItemCount(outputList.length);
    sendChatItem.clear();
    sendChatItem.addAll(outputList);
    refresh();
  }

  /// Checks if the user is blocked and opens the chat detail page if not blocked.
  checkIsUserBlocked(ParentRoomModel parentRoomModel) async {
    loading(true);
    var isBlocked = await documentController
        .getBlockListByIds(items: [parentRoomModel.receiverId]);
    loading(false);
    if (isBlocked) {
      await Get.dialog(
          barrierDismissible: false,
          CustomAnimatedDialogWidget(
            title: "",
            logo: ImageConstant.block,
            description: "Chat is not available for this user",
            buttonAction: "okay".tr,
            buttonCancel: "cancel".tr,
            isHideCancelBtn: true,
            onCancelTap: () {},
            onActionTap: () async {
              Get.back();
            },
          ));
    } else {
      openChatDetailPage(parentRoomModel);
    }
  }

  /// Opens the chat detail page for the given [ParentRoomModel].
  openChatDetailPage(ParentRoomModel parentRoomModel) {
    Get.to(() => ChatDetailPage(
        userModel: UserModel(
            chatRequestStatus: parentRoomModel.roomModel?.status,
            iam: parentRoomModel.roomModel?.iam,
            userId: parentRoomModel.receiverId,
            fullName: parentRoomModel.chatProfileModel?.name ?? "",
            shortName: parentRoomModel.chatProfileModel?.shortName ?? "",
            avtar: parentRoomModel.chatProfileModel?.avtar ?? "",
            roomId: parentRoomModel.roomModel?.roomId)));
  }

  /// Opens the chat detail page from an alert with the provided [UserModel].
  openChatPageFromAlert(UserModel userModel) {
    Get.to(() => ChatDetailPage(userModel: userModel));
  }

  @override
  void onClose() {
    _onChildChangeListener.cancel();
    _onChildAddedListener.cancel();
    super.onClose();
  }
}
