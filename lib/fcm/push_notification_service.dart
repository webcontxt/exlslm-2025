import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../view/beforeLogin/globalController/authentication_manager.dart';
import '../view/dashboard/deep_linking_controller.dart'
    show DeepLinkingController;

class PushNotificationService {
  final FirebaseMessaging _fcm;
  PushNotificationService(this._fcm);

  // Initializes notification permissions, listeners, and handlers for different app states
  Future<void> initialise() async {
    // Request notification permission for iOS or Android 13+
    if (Platform.isIOS) {
      _fcm.requestPermission();
    } else {
      await Permission.notification.isDenied.then((value) {
        if (value) {
          Permission.notification.request();
        }
      });
    }

    // Start listening to notification actions (Awesome Notifications)
    startListeningNotificationEvents();

    // Handle notification when app is terminated and opened via a notification
    _fcm.getInitialMessage().then((message) {
      print("@@ message terminated-: ${message?.data}");

      if (message != null) {
        handleMessage(
          data: message.data,
          page: message.data["page"] ?? "",
          title: message.notification?.title ?? "",
          notificationId: message.data["id"] ?? "",
          appStatus: "terminate",
        );
      }
    });

    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen((message) {
      print(" @@ message foreground-: ${message.data}");
      if (message.notification != null && Platform.isAndroid) {
        createNotification(message, "foreground");
      }
    });

    // Handle notification when app is in background and user taps on it
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("@@ message background-: ${message.data}");

      if (message.notification != null) {
        handleMessage(
          data: message.data,
          page: message.data["page"] ?? "",
          title: message.notification?.title ?? "",
          notificationId: message.data["id"] ?? "",
          appStatus: "background",
        );
      }
    });
  }

  // Setup listener for actions triggered from Awesome Notifications
  Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: PushNotificationService.onActionReceivedMethod,
    );
  }

  // Callback when a notification action is received
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.actionType == ActionType.Default ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      handleMessage(
        data: receivedAction.payload?["data"] ?? "",
        page: receivedAction.payload?["page"] ?? "",
        title: receivedAction.payload?["title"] ?? "",
        notificationId: receivedAction.payload?["id"] ?? "",
        appStatus: "background",
      );
      print(
          ' @@ Message sent via notification input: "${receivedAction.buttonKeyInput}"');
    }
  }

  // Creates a local notification using Awesome Notifications (for foreground messages)
  Future<void> createNotification(RemoteMessage message, String key) async {
    AuthenticationManager manager = Get.find();
    manager.pageRouteName = message.data["page"] ?? "";
    manager.pageRouteTitle = message.notification?.title ?? "";
    manager.pageRouteId = message.data["id"] ?? "";

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(2147483647), // Generate a random notification ID
        channelKey: "high_importance_channel", // Channel must be pre-configured
        payload: {
          "page": message.data["page"] ?? "",
          "id": message.data["id"] ?? "",
          "title": message.notification?.title ?? ""
        },
        title: message.notification?.title.toString(),
        body: message.notification?.body.toString(),
        displayOnBackground: true,
        displayOnForeground: true,
        criticalAlert: true,
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: message.data?["page"] ?? "",
          label: 'Open Notification',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  // Handles redirection logic based on notification content and app state
  static Future<void> handleMessage({
    required dynamic data,
    required String page,
    required String notificationId,
    required String appStatus,
    required String title,
  }) async {
    print("@@ handleMessage call ${appStatus})");
    if (appStatus == "background" && page.isNotEmpty) {
      AuthenticationManager manager = Get.find();
      if (manager.isLogin()) {
        // this is common controller to manage the page on click on third party link and notification
        if (Get.isRegistered<DeepLinkingController>()) {
          DeepLinkingController controller = Get.find();
          manager.pageRouteId = notificationId;
          manager.pageRouteName = page;
          manager.pageRouteTitle = title;
          controller.navigatePageAsPerNotification();
        }
      }
    } else if (appStatus == "terminate") {
      //this is manage when the app is terminated and user clicks on notification at that time the payload set the auth manager to open the page detail.
      AuthenticationManager manager = Get.find();
      if (page.isNotEmpty) {
        if (notificationId.isNotEmpty) {
          manager.pageRouteId = notificationId ?? "";
        }
        manager.pageRouteName = page;
        manager.pageRouteTitle = title;
      } else {
        manager.pageRouteName = "alert";
      }
    }
  }
}
