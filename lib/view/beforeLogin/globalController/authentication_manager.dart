import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dreamcast/model/common_model.dart';
import 'package:dreamcast/theme/controller/theme_controller.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/widgets/dialog/custom_dialog_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signin_with_linkedin/signin_with_linkedin.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../api_repository/app_url.dart';
import '../../../fcm/push_notification_service.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/pref_utils.dart';
import '../../dashboard/dashboard_page.dart';
import '../login/login_page_otp.dart';
import '../splash/model/config_model.dart';
import '../../../api_repository/api_service.dart';
import 'package:path_provider/path_provider.dart';

class AuthenticationManager extends GetxController {
  var iosAppVersion = 1; // Current iOS app version, can be updated dynamically.
  var _currAppVersion = ""; // Current app version, can be updated dynamically.
  get currAppVersion => _currAppVersion;
  var isAiFeature =
      false.obs; // Whether AI feature is enabled, can be updated dynamically.
  var isGuestLogin =
      false; // Whether guest login is enabled, can be updated dynamically.

  final isLogged =
      false.obs; // Whether the user is logged in, can be updated dynamically.
  final loading = false.obs;
  final isRemember = false
      .obs; // Whether the user wants to be remembered, can be updated dynamically.
  ConfigModel _configModel = ConfigModel();
  late String _osName;
  late FirebaseMessaging _firebaseMessaging;
  var tokenExpired = false;
  FirebaseMessaging get firebaseMessaging => _firebaseMessaging;
  late final FirebaseDatabase _firebaseDatabase;
  FirebaseDatabase get firebaseDatabase => _firebaseDatabase;

  // Firebase Realtime Database subscription for token changes.
  StreamSubscription<DatabaseEvent>? _tokenSubscription;

  var showBadge = false.obs;
  var isMuteNotification = false.obs;
  late final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  String _platformVersion = "";
  late String _dc_device = "tablet";
  String get dc_device => _dc_device;
  String get platformVersion => _platformVersion;
  String get osName => _osName;
  ConfigModel get configModel => _configModel;
  String pageRouteName = "";
  String pageRouteId = "";
  String? pageRouteTitle;
  String role = "";
  String type = "";

  var notificationNode = {}; // Notification node to store notification data.
  var showWelcomeDialog = false; // Whether to show the welcome dialog.
  var showForceUpdateDialog =
      false.obs; // Whether to show the force update dialog.

  // LinkedIn configuration for authentication.
  LinkedInConfig? _linkedInConfig;
  LinkedInConfig? get linkedInConfig => _linkedInConfig;

  var localBadgePath = "";

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // The URL for the deep link to the event.
  String deeplinkUrl = "https://applinks.evnts.info/3b9aca01";

  //Sets the configuration model for the authentication manager.
  set configModel(ConfigModel value) {
    _configModel = value;
    update();
  }

  ThemeController themeController =
      Get.find<ThemeController>(); // Theme controller for managing app themes.
  @override
  onInit() async {
    super.onInit();
    _firebaseMessaging =
        FirebaseMessaging.instance; // Initialize Firebase Messaging
    _firebaseDatabase =
        FirebaseDatabase.instance; // Initialize Firebase Database
    fcmSubscribe(); // Subscribe to Firebase Cloud Messaging
    getInitialInfo(); // Get initial device information
    final pushNotificationService = PushNotificationService(_firebaseMessaging);
    pushNotificationService
        .initialise(); // Initialize push notification service
  }

  @override
  void onReady() {
    super.onReady();
    getFcmTokenFrom();
    initSharedPref();
    checkTheInternet();
    getTheBuildVersion();
  }

  // Get the current app version
  getTheBuildVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    _currAppVersion = info.version.toString();
  }

  /// Clears the app's storage by deleting the application documents directory.
  ///
  /// Catches and prints any errors that occur during the process.
  Future<void> clearAppStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (e) {
      print("Error clearing app storage: $e");
    }
  }

  /// Sets up the LinkedIn configuration for authentication.
  ///
  /// Retrieves LinkedIn credentials from the config model and initializes the LinkedInConfig object.
  linkedinSetupDynamic() {
    _linkedInConfig = LinkedInConfig(
        clientId: configModel.body?.linkedInDetail?.clientId ?? "",
        clientSecret: configModel.body?.linkedInDetail?.clientSecret ?? "",
        redirectUrl: configModel.body?.linkedInDetail?.redirectUrl ?? "",
        scope: ['openid', 'profile', 'email', 'r_basicprofile']);
  }

  /// Checks for app updates by comparing the current app version with the latest version available.
  ///
  /// If an update is available, shows a dialog to the user with the option to update now or later.
  void checkUpdate() {
    Future.delayed(const Duration(seconds: 2), () {
      if (Platform.isAndroid) {
        versionCheck();
      } else {
        versionCheckIos();
      }
    });
  }

  /// Retrieves the app configuration details from the server.
  ///
  /// Updates the config model, saves relevant data to preferences, and sets up the app's theme and LinkedIn configuration.
  Future<void> getConfigDetail() async {
    print("time zone  login ${isLogin()}");
    final model = ConfigModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(
          url: AppUrl.getConfig,
          defaultHeader: isLogin() == true ? null : true),
    ));
    try {
      if (model?.status == true && model?.code == 200) {
        configModel = model;
        PrefUtils.setGuestLoginId(model?.body?.guestId ?? "");
        final firebase = model?.body?.config?.firebase;
        final meta = model?.body?.meta;
        print("time zone default: ${model.body?.defaultTimezone}");
        print("time zone im: ${model.body?.iam?.timezone ?? ""}");
        final timezone =
            isLogin() ? model.body?.iam?.timezone : model.body?.defaultTimezone;
        PrefUtils.saveTimezone(timezone ?? "");
        AppUrl.setDefaultFirebaseNode = firebase?.name?.toLowerCase() ?? "";
        AppUrl.setTopicName = firebase?.topics?.all?.toString() ?? "";
        AppUrl.setDataBaseUrl = firebase?.configs?.databaseURL ?? "";
        AppUrl.appName = meta?.title ?? "";
        PrefUtils.setAiFeature(model.body?.themeSetting?.aiFeature ?? false);
        PrefUtils.setGuestLogin(
            model.body?.themeSetting?.isGuestLogin ?? false);
        PrefUtils.setDeleteAccountFeature(
            model.body?.pages?.isProfileAccountDelete ?? false);
        if (model.body?.themeSetting?.primaryColor != null &&
            model.body?.themeSetting?.secondaryColor != null) {
          themeController.updateColor(
            primaryColor: UiHelper.getColorByHexCode(
                model.body?.themeSetting?.primaryColor ?? ""),
            secondaryColor: UiHelper.getColorByHexCode(
              model.body?.themeSetting?.secondaryColor ?? "",
            ),
            primaryColorDark: UiHelper.getColorByHexCode(
                model.body?.themeSetting?.primaryColorDark ?? ""),
          );
        }
        linkedinSetupDynamic();
        print("===>${AppUrl.defaultFirebaseNode}");
        print(AppUrl.topicName);
        print(AppUrl.dataBaseUrl);
      }
    } catch (e) {
      print(e.toString());
    } finally {
      loading(false);
      update();
    }
  }

  /// Deletes the user's account from the server and clears preferences.
  ///
  /// Shows a success message and redirects the user to the login page.
  Future<void> deleteYourAccount() async {
    loading(true);
    final model = CommonModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(url: AppUrl.deleteAccount),
    ));
    loading(false);
    if (model.status! && model.code == 200) {
      UiHelper.showSuccessMsg(null, model?.message ?? "");
      PrefUtils.clearPreferencesData();
      PrefUtils.saveTimezone(configModel.body?.defaultTimezone ?? "");
      Get.offNamedUntil(LoginPageOTP.routeName, (route) => false);
    }
  }

  //used for the logout the session from the server
  /// Logs out the user by calling the logout API and redirects to the appropriate page based on guest login status.
  ///
  /// Clears preferences and shows a success message.
  Future<void> logoutTheUserAPi() async {
    loading(true);
    final model = CommonModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(url: AppUrl.logoutApi),
    ));
    loading(false);
    if (model.status! && model.code == 200) {
      await FirebaseAuth.instance.signOut();
      if (PrefUtils.getGuestLogin()) {
        PrefUtils.clearPreferencesData();
        PrefUtils.setGuestLogin(true);
        PrefUtils.saveTimezone(configModel.body?.defaultTimezone ?? "");
        Get.offNamedUntil(DashboardPage.routeName, (route) => false);
      } else {
        PrefUtils.clearPreferencesData();
        PrefUtils.setGuestLogin(false);
        PrefUtils.saveTimezone(configModel.body?.defaultTimezone ?? "");
        cancelAllNotifications();
        Get.offNamedUntil(LoginPageOTP.routeName, (route) => false);
      }
      Future.delayed(const Duration(seconds: 1), () async {
        getConfigDetail();
      });
    } else {
      Get.offNamedUntil(LoginPageOTP.routeName, (route) => false);
      Future.delayed(const Duration(seconds: 1), () async {
        getConfigDetail();
      });
    }
  }

  /// Subscribes to Firebase Cloud Messaging and retrieves the device token.
  ///
  /// Sets the database URL and listens for changes in the Firebase Realtime Database.
  void fcmSubscribe() {
    _firebaseDatabase.databaseURL = AppUrl.dataBaseUrl;
    firebaseDatabase
        .ref("${AppUrl.eventAppNode}/${AppUrl.defaultNodeName}")
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final json = event.snapshot.value as Map<dynamic, dynamic>;
        if (json["endPoint"] != null &&
            json["endPoint"].toString().isNotEmpty) {
          // AppUrl.baseURLV1 = json["endPoint"];
          print("AppUrl.baseURLV1 ${AppUrl.baseURLV1}");
        }
      }
    });
    if (PrefUtils.getAuthToken() != null &&
        PrefUtils.getAuthToken()!.isNotEmpty) {
      signInFirebaseByCustomToken(PrefUtils.getAuthToken() ?? "");
    }
  }

  /// Initializes the shared preferences instance for persistent storage.
  initSharedPref() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Retrieves the device token from Firebase Cloud Messaging and saves it in preferences.
  ///
  /// Prints the token for debugging and handles errors if token retrieval fails.
  void getFcmTokenFrom() async {
    _firebaseMessaging.getToken().then((token) {
      PrefUtils.saveFcmToken(token);
      print('token: $token');
    }).catchError((err) {
      print("This is bug from FCM${err.message.toString()}");
    });
  }

  /// Checks if the user is currently logged in by verifying the presence of a token in preferences.
  ///
  /// Returns true if a token exists and is not empty, otherwise false.
  bool isLogin() {
    if (PrefUtils.getToken() != null && PrefUtils.getToken().isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  /// Retrieves initial device information such as device type (mobile or tablet).
  getInitialInfo() {
    final data = MediaQueryData.fromView(WidgetsBinding.instance.window);
    _dc_device = data.size.shortestSide < 600 ? 'mobile' : 'tablet';
    print("_dc_device$_dc_device");

    _osName = Platform.isAndroid ? "android" : "ios";
  }

  /// Adds or updates the Firebase Cloud Messaging device token on the server.
  ///
  /// If the token is null or empty, retrieves a new token from Firebase.
  /// Sends a request to update the token on the server.
  Future<void> adFcmDeviceToken(String token) async {
    if (!isLogin()) {
      return;
    }
    if (token == null || token.isEmpty) {
      _firebaseMessaging.getToken().then((newToken) {
        PrefUtils.saveFcmToken(newToken);
        token = newToken ?? "";
        print('token: $token');
      }).catchError((err) {
        print("This is bug from FCM${err.message.toString()}");
      });
    }
    var loginRequest = {
      //"device_id": Platform.isAndroid ? "android" : "ios",
      "registration_token": token ?? ""
    };
    print("token added: $token");
    CommonModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
          url: AppUrl.updateFcm, body: loginRequest),
    ));
  }

  /// Signs in to Firebase using a custom token.
  ///
  /// Retrieves the custom token from preferences and signs in the user.
  /// Refreshes the Firebase token after successful sign-in.
  signInFirebaseByCustomToken(customToken) async {
    print('customToken :$customToken');
    try {
      UserCredential user =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
      refreshTheFirebaseToken();
      print("Sign-in successful.");
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      switch (e.code) {
        case "invalid-custom-token":
          print("501 The supplied token is not a Firebase custom auth token.");
          break;
        case "custom-token-mismatch":
          print("501  The supplied token is for a different Firebase project.");
          break;
        default:
          print("501  Unkown error.");
      }
    }
  }

  /// Checks for updates to the app's version and prompts the user to update if a new version is available.
  ///
  /// Compares the current app version with the latest version from the config model.
  /// Shows a dialog with the option to update now or cancel.
  versionCheck() async {
    //Get Current installed version of app
    final PackageInfo info = await PackageInfo.fromPlatform();
    double currentVersion =
        double.parse(info.buildNumber.trim().replaceAll(".", ""));
    _currAppVersion = info.version.toString();
    try {
      if (double.parse(configModel.body?.flutter?.version ?? "0") >
          currentVersion) {
        await Get.dialog(
            barrierDismissible: false,
            WillPopScope(
              onWillPop: () async => false,
              child: CustomDialogWidget(
                title: "force_update_title".tr,
                logo: "",
                description: configModel.body?.flutter?.updateMessage ??
                    "force_update_msg".tr,
                buttonAction: "update_now".tr,
                buttonCancel: "cancel".tr,
                isShowBtnCancel:
                    configModel.body!.flutter!.forceDownload == false
                        ? true
                        : false,
                onCancelTap: () {},
                onActionTap: () async {
                  _launchURL(configModel.body?.flutter?.playStoreUrl ??
                      "PLAY_STORE_URL".tr);
                },
              ),
            ));
        showForceUpdateDialog(true);
      } else {
        showForceUpdateDialog(false);
      }
    } catch (exception) {
      print(exception.toString());
    }
  }

  /// Checks for updates to the iOS app's version and prompts the user to update if a new version is available.
  ///
  /// Compares the current app version with the latest version from the config model.
  /// Shows a dialog with the option to update now or cancel.
  versionCheckIos() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _currAppVersion = info.version.toString();
      // _currAppVersion = iosAppVersion.toString();
      print("version ${configModel.body?.flutter?.version}");
      if (double.parse(configModel.body?.flutter?.version ?? "0") >
          iosAppVersion) {
        showForceUpdateDialog(true);
        await Get.dialog(
            barrierDismissible: false,
            WillPopScope(
              onWillPop: () async => false,
              child: CustomDialogWidget(
                title: "force_update_title".tr,
                logo: "",
                description: configModel.body?.flutter?.updateMessage ??
                    "force_update_msg".tr,
                buttonAction: "update_now".tr,
                buttonCancel: "cancel".tr,
                isShowBtnCancel:
                    configModel.body!.flutter!.forceDownload == false
                        ? true
                        : false,
                onCancelTap: () {},
                onActionTap: () async {
                  _launchURL(configModel.body?.flutter?.appStoreUrl ??
                      "APP_STORE_URL".tr);
                },
              ),
            ));
      } else {
        showForceUpdateDialog(false);
      }
    } catch (exception) {
      print(exception.toString());
    }
  }

  /// Launches the given URL in the device's default browser.
  ///
  /// [url] - The URL to be launched.
  /// Throws an exception if the URL could not be launched.
  _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (Platform.isAndroid) {
        versionCheck();
      } else {
        versionCheckIos();
      }
    } else {
      throw 'Could not launch $url';
    }
  }

  /// Refreshes the Firebase token periodically to keep the user signed in.
  ///
  /// Sends a request to Firebase to refresh the token every 55 minutes.
  refreshTheFirebaseToken() {
    Timer.periodic(const Duration(minutes: 55), (Timer t) {
      FirebaseAuth.instance.currentUser?.getIdToken(true);
      String msg =
          "${DateTime.now().hour} : ${DateTime.now().minute} ${DateTime.now().second}"; //'notification ' + counter.toString();
      print('SEND: $msg');
    });
  }

  /// Monitors the internet connection status and performs actions based on the connection state.
  ///
  /// Currently, it does not perform any specific actions on connection or disconnection.
  checkTheInternet() {
    InternetConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case InternetConnectionStatus.disconnected:
          break;
        case InternetConnectionStatus.connected:
          break;
      }
    });
  }

  /// Checks for an existing token in the database and compares it with the token in preferences.
  ///
  /// If the tokens do not match, marks the token as expired.
  void checkExistingToken() {
    final userId = PrefUtils.getUserId();
    if (userId == null || userId.isEmpty) {
      debugPrint("user id is empty");
      return;
    }

    // Cancel previous listener if already running
    _tokenSubscription?.cancel();

    _tokenSubscription = firebaseDatabase
        .ref("${AppUrl.defaultFirebaseNode}/auth/$userId")
        .onValue
        .listen((event) async {
      if (event.snapshot.value != null) {
        final firebaseToken = event.snapshot.value;
        final localToken = PrefUtils.getFAuthToken();
        print("snapshot $firebaseToken \n $localToken");

        await Future.delayed(const Duration(seconds: 3), () {
          if (PrefUtils.getFAuthToken() != firebaseToken) {
            ApiService().tokenExpire("");
          }
        });
      }
    });
  }

  // Function to cancel all pending notifications
  void cancelAllNotifications() {
    AwesomeNotifications().cancelAll();
    cancelTokenListener();
  }

  void cancelTokenListener() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }

  void clearPageRoute() {
    pageRouteName = "";
    pageRouteId = "";
    pageRouteTitle = null;
    role = "";
  }
}
