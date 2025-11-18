import 'dart:async';
import 'package:dreamcast/view/account/controller/account_controller.dart';
import 'package:dreamcast/view/dashboard/deep_linking_controller.dart';
import 'package:dreamcast/view/home/controller/for_you_controller.dart';
import 'package:dreamcast/view/home/controller/home_controller.dart';
import 'package:dreamcast/view/myFavourites/controller/favourite_controller.dart';
import 'package:dreamcast/view/myFavourites/controller/favourite_user_controller.dart';
import 'package:dreamcast/view/representatives/controller/networkingController.dart';
import 'package:dreamcast/widgets/dialog/custom_animated_dialog_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_repository/app_url.dart';
import '../../utils/dialog_constant.dart';
import '../../utils/pref_utils.dart';
import '../alert/controller/alert_controller.dart';
import '../alert/pages/alert_dashboard.dart';
import '../alert/model/notification_model.dart';
import '../beforeLogin/globalController/authentication_manager.dart';
import '../eventFeed/controller/eventFeedController.dart';
import '../menu/controller/menuController.dart';
import '../schedule/controller/session_controller.dart';
import '../support/controller/helpdesk_dashboard_controller.dart';

class DashboardController extends GetxController
    with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
  var dashboardTabIndex = 0; //manage the dashboard tab index
  var selectedAiMatchIndex = 0.obs; //manage the Ai match tab index
  var chatTabIndex = 0.obs; //manage the chat dashboard tab index

  var chatCount = 0.obs;
  var notificationCount = 0.obs;

  var personalCount = 0.obs;
  var broadcastCount = 0.obs;

  var showPopup = false.obs; // manage the popup welcome dialog.
  final AuthenticationManager _authManager = Get.find();
  var loading = false.obs;
  final _currAppVersion = "";

  late TabController _tabController;
  TabController get tabController => _tabController;

  get currAppVersion => _currAppVersion;

  late SharedPreferences preferences;

  /// Changes the currently selected tab index for the dashboard.
  /// If the index is 4, it checks if the user is logged in; if not, shows the login dialog.
  /// Updates the dashboardTabIndex and triggers the appropriate API calls based on the new index.
  /// Also checks for app updates and the current version.
  void changeTabIndex(int index) {
    // Prevent API call and update if the tab is already selected
    if (index == dashboardTabIndex) {
      return;
    }

    // If 4th tab requires login
    if (index == 4 && !_authManager.isLogin()) {
      DialogConstantHelper.showLoginDialog(Get.context!, _authManager);
      return;
    }

    dashboardTabIndex = index;
    showPopup(false);
    _authManager.checkUpdate();

    // Optional version check for specific tab
    if (index == 2) {
      checkCurrentVersion();
    }

    apiCallAccordingIndex(); // ✅ Called only when tab actually changes
    loading(false);
    update(); // Notifies GetBuilder listeners
  }

  ///fina code merge
  ///call the api on tab click
  apiCallAccordingIndex() {
    switch (dashboardTabIndex) {
      case 0:
        if (Get.isRegistered<HomeController>()) {
          HomeController homeController = Get.find();
          homeController.initApiCall();
        }
        break;
      case 1:
        if (Get.isRegistered<EventFeedController>()) {
          EventFeedController controller = Get.find();
          controller.loading(false);
          controller.getEventFeed(isLimited: false);
        }
        break;
      case 3:
        if (Get.isRegistered<HelpdeskDashboardController>()) {
          HelpdeskDashboardController controller = Get.find();
          controller.faqController.getSOSList();
        }
        break;
      case 4:
        if (Get.isRegistered<AccountController>()) {
          AccountController controller = Get.find();
          controller.getProfileData(isFromDashboard: true);
        }
        break;
    }
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // Start listening
    _tabController = TabController(vsync: this, length: 2);
    apiCallAccordingIndex();
    getNotificationCount();
    getChatCount();
    _authManager.checkUpdate();
    if (PrefUtils.getAuthToken() != null &&
        PrefUtils.getAuthToken()!.isNotEmpty) {
      _authManager.signInFirebaseByCustomToken(PrefUtils.getAuthToken() ?? "");
    }
  }

  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(seconds: 3), () async {
      _authManager.adFcmDeviceToken(PrefUtils.getFcmToken() ?? "");
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up
    super.onClose();
  }

  /// Checks the current app version against the version specified in the app configuration.
  ///
  /// If the current version is lower, it fetches the latest configuration details.
  checkCurrentVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    double currentVersion =
        double.parse(info.buildNumber.trim().replaceAll(".", ""));
    if (double.parse(_authManager.configModel.body?.flutter?.version ?? "0") <
        currentVersion) {
      _authManager.getConfigDetail();
    }
    return;
  }

  /// Fetches the notification counts for personal and broadcast notifications from Firebase.
  ///
  /// Listens for new personal notifications for the current user and increments the count if unread.
  /// Listens for new broadcast notifications and increments the count accordingly.
  /// Updates the alert badge based on the broadcast count.
  getNotificationCount() async {
    preferences = await SharedPreferences.getInstance();
    personalCount(0);
    broadcastCount(0);
    _authManager.firebaseDatabase
        .ref(
            "${AppUrl.defaultFirebaseNode}/notifications/personal/${PrefUtils.getUserId()}")
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        final json = event.snapshot.value as Map<dynamic, dynamic>;
        var message = json['read'];
        if (message == false) {
          personalCount((personalCount.value + 1));
        }
      }
    });

    _authManager.firebaseDatabase
        .ref("${AppUrl.defaultFirebaseNode}/notifications/broadcast")
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        broadcastCount((broadcastCount.value + 1));
        manageAlertBadge();
      }
    });
  }

  /// Manages the alert badge visibility based on the broadcast notification count
  /// If the current broadcast count is greater than the stored count in preferences,
  /// the badge is shown. Otherwise, it is hidden. This check is delayed by 5 seconds.
  manageAlertBadge() {
    Future.delayed(const Duration(seconds: 5), () async {
      if ((broadcastCount.value >
          (preferences.getInt("broadcast_count") ?? 0))) {
        _authManager.showBadge(true);
      } else {
        _authManager.showBadge(false);
      }
    });
  }

  ///get the chat count from the firebase
  getChatCount() {
    _authManager.firebaseDatabase
        .ref(
            "${AppUrl.defaultFirebaseNode}/${AppUrl.chatUsers}/${PrefUtils.getUserId()}")
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        final json = event.snapshot.value as Map<dynamic, dynamic>;
        int count = json['count'] ?? 0;
        if (count > 0) {
          chatCount((chatCount.value + count));
        } else {
          chatCount(0);
        }
      }
    });
    _authManager.firebaseDatabase
        .ref(
            "${AppUrl.defaultFirebaseNode}/${AppUrl.chatUsers}/${PrefUtils.getUserId()}")
        .onChildChanged
        .listen((event) {
      if (event.snapshot.value != null) {
        final json = event.snapshot.value as Map<dynamic, dynamic>;
        int count = json['count'];
        if (count > 0) {
          chatCount.value = 0;
          chatCount.value = count;
        } else {
          chatCount(0);
        }
      }
    });
  }

  ///open the alert page
  openAlertPage() async {
    if (!_authManager.isLogin()) {
      DialogConstantHelper.showLoginDialog(Get.context!, _authManager);
      return;
    }
    preferences?.setInt("broadcast_count", broadcastCount.value);
    _authManager.showBadge(false);
    showPopup(false);
    if (Get.isRegistered<AlertController>()) {
      Get.delete<AlertController>();
    }
    Get.toNamed(AlertDashboard.routeName);
  }

  ///refresh the session when live and update the session status
  refreshTheSession() {
    if (Get.isRegistered<HomeController>()) {
      HomeController controller = Get.find();
      controller.getTodaySession(isRefresh: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _authManager.checkExistingToken();
    }
  }
}
