import 'dart:async';
import 'dart:convert';
import 'package:dreamcast/api_repository/app_url.dart';
import 'package:dreamcast/view/chat/model/create_room_model.dart';
import 'package:dreamcast/view/dashboard/dashboard_controller.dart';
import 'package:dreamcast/view/home/model/config_detail_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../utils/pref_utils.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../home/controller/home_controller.dart';
import '../../representatives/model/chat_request_status_model.dart';
import '../../chat/model/message_model.dart';
import '../../chat/model/user_model.dart';

class SupportController extends GetxController {
  final DashboardController dashboardController = Get.find();
  final HomeController homeController = Get.find();

  final _scrollController = ScrollController();
  get scrollController => _scrollController;

  final AuthenticationManager _authManager = Get.find();
  AuthenticationManager get authManager => _authManager;

  // Firebase reference for chat messages
  late DatabaseReference _messagesRef;
  DatabaseReference get messagesRef => _messagesRef;

  final String title = 'Home Title';
  var loading = false.obs;

  // Room ID for current chat session
  String _mRoomId = "";
  String get getRoomId => _mRoomId;
  set setRoomId(String value) {
    _mRoomId = value;
  }

  // List of chat messages
  var newChatDetailList = <ChatModel>[].obs;

  // Firebase event subscription for real-time messages
  late StreamSubscription<DatabaseEvent> _eventsSubscription;

  // Holds chat user details
  var userModel = UserModel();

  // Observable label for chat loading status
  var loadingLabel = "Chat Loading...".obs;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(seconds: 0), () {
      if (!authManager.isLogin()) {
        return;
      }
      getChatRequestStatus(); // Fetch room ID or user info
    });
  }

  // Get current chat room info or request status
  Future<void> getChatRequestStatus() async {
    HelpDeskChat? helpDeskChat =
        homeController.configDetailBody.value.organizers?.helpDeskChat;
    var body = {"receiver_id": helpDeskChat?.id ?? ""};

    final model = ChatRequestStatusModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: body,
        url: AppUrl.getChatRequestStatus,
      ),
    ));

    loading(false);

    if (model.status! && model!.code == 200) {
      // Initialize userModel with existing room ID or default info
      userModel = UserModel(
          userId: helpDeskChat?.id ?? "",
          fullName: helpDeskChat?.name ?? "",
          shortName: helpDeskChat?.shortName ?? "",
          avtar: helpDeskChat?.avatar ?? "",
          roomId: model.body?.id ?? "");
      loadingLabel("");

      if (userModel!.roomId != null && userModel!.roomId!.isNotEmpty) {
        setRoomId = userModel!.roomId ?? "";
        initMessageRef(receiverId: userModel.userId ?? "");
      } else {
        setRoomId = "";
      }
    }
  }

  // Scroll chat to the bottom (after new messages)
  void scrollToBottom() {
    if (newChatDetailList.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 1),
          curve: Curves.fastOutSlowIn,
        );
      });
    }
  }

  // Firebase message reference and listener
  initMessageRef({receiverId}) async {
    if (getRoomId.toString().isNotEmpty) {
      newChatDetailList.clear();
      _messagesRef = authManager.firebaseDatabase
          .ref(AppUrl.defaultFirebaseNode)
          .child(AppUrl.chatConversation)
          .child(getRoomId);

      // Listen for new child (message) added
      _eventsSubscription = _messagesRef.onChildAdded.listen((snapshot) {
        onEventsSnapshot(snapshot);
      });

      // Reset unread count
      clearReadCount(receiverId);
    }
  }

  // Called when a new message is added to Firebase
  void onEventsSnapshot(DatabaseEvent event) {
    if (event.snapshot.value != null) {
      final json = event.snapshot.value as Map<dynamic, dynamic>;
      final message = ChatModel.fromJson(json);
      newChatDetailList.add(message);
      scrollToBottom();
    } else {
      print("data is load");
    }
  }

  // Alternative scroll with try-catch
  void scrollToBottom1() {
    if (newChatDetailList.isNotEmpty) {
      try {
        _scrollController.position.maxScrollExtent;
        Future.delayed(const Duration(seconds: 1), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 1),
            curve: Curves.fastOutSlowIn,
          );
        });
      } catch (exception) {
        print("exception:$exception");
      }
    }
  }

  // Send a message to Firebase
  void sendMessage(ChatModel message, String receiverId) {
    messagesRef.push().set(message.toJson()).then((_) {
      manageReadCount(receiverId, message);
      print(message.dateTime);
    }).catchError((onError) {
      print("onError-:$onError");
    });
  }

  // Increment unread count on receiver’s end
  void manageReadCount(String receiverId, ChatModel message) async {
    return await authManager.firebaseDatabase
        .ref("${AppUrl.defaultFirebaseNode}/${AppUrl.chatUsers}/")
        .child(receiverId)
        .child(PrefUtils.getUserId() ?? "")
        .once()
        .then((result) async {
      if (result.snapshot.value != null) {
        final json = result.snapshot!.value! as Map<dynamic, dynamic>;
        int count = json['count'];
        var body = <String, dynamic>{};
        body["count"] = count + 1;
        body["datetime"] = json['datetime'];
        body["room"] = json['room'];
        body["text"] = message.message;

        await authManager.firebaseDatabase
            .ref(AppUrl.defaultFirebaseNode)
            .child(AppUrl.chatUsers)
            .child(receiverId)
            .child(PrefUtils.getUserId() ?? "")
            .update(body);
      } else {
        print("result is empty");
      }
    });
  }

  // Clear unread count for the current user
  void clearReadCount(String receiverId) async {
    return await authManager.firebaseDatabase
        .ref(AppUrl.defaultFirebaseNode)
        .child(AppUrl.chatUsers)
        .child(PrefUtils.getUserId() ?? "")
        .child(receiverId)
        .update({"count": 0});
  }

  // Create room and send the first message if room ID doesn't exist
  Future<void> sendFirstMessage(dynamic requestBody, receiverId) async {
    loading(true);
    final model = CreateRoomModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: requestBody,
        url: AppUrl.createRoomSupport,
      ),
    ));
    loading(false);

    if (model!.status! && model!.code == 200) {
      setRoomId = model.body?.room?.id ?? "";
      loadingLabel("");
      initMessageRef(receiverId: receiverId);
    }
    loading(false);
  }

  @override
  void onClose() {
    try {
      // Clean up Firebase listeners and controller instance
      messagesRef.onDisconnect();
      _eventsSubscription.cancel();
      Get.delete<SupportController>();
    } catch (exception) {
      print(exception.toString());
    }

    super.onClose();
  }
}
