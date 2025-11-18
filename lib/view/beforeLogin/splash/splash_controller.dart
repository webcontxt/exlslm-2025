import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dreamcast/view/beforeLogin/globalController/authentication_manager.dart';
import 'package:dreamcast/view/dashboard/dashboard_page.dart';
import 'package:signin_with_linkedin/signin_with_linkedin.dart';
import '../../../network/view/noConnectionPage.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/pref_utils.dart';
import '../login/login_page_otp.dart';
import '../../../widgets/button/common_material_button.dart';
import '../../../widgets/textview/customTextView.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class SplashController extends GetxController {
  AuthenticationManager? authenticationManager;
  // Observable boolean to track loading state
  final loading = true.obs;

  /// Initializes the controller when it's created
  /// Called automatically by GetX
  @override
  void onInit() {
    super.onInit();
    initialCall();
  }

  /// Handles the initial application startup sequence
  /// - Checks internet connectivity
  /// - Loads configuration details
  /// - Verifies device security status
  Future<void> initialCall() async {
    authenticationManager = Get.find<AuthenticationManager>();

    // Wait for splash screen animation
    await Future.delayed(const Duration(seconds: 2));

    // Check internet connectivity first
    if (!await isInternetWorking()) {
      showNoInternetScreen();
      return;
    }

    // Load app configuration
    await authenticationManager?.getConfigDetail();
    update();

    // Check for rooted device on Android
    nextScreen();
    /*if (Platform.isAndroid && await isDeviceRooted()) {
      showRootedDialog();
    } else {
      nextScreen();
    }*/
  }

  /// Checks if the device has working internet connectivity
  /// Returns true if device can connect to the internet
  /// Uses both connectivity check and actual internet lookup
  Future<bool> isInternetWorking() async {
    loading(true);
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) return false;

      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      loading(false);
    }
  }

  /// Checks if the device is rooted/jailbroken
  /// Returns true if device is not trusted or is an emulator
  /// Uses JailbreakRootDetection plugin for detection
  /*Future<bool> isDeviceRooted() async {
    try {
      final detector = JailbreakRootDetection.instance;
      return await detector.isNotTrust && !(await detector.isRealDevice);
    } catch (_) {
      return false;
    }
  }*/

  /// Displays the no internet connection screen
  /// Shows when device can't connect to the internet
  void showNoInternetScreen() {
    Get.to(() => const NoConnectionScreen(
          icon: Icons.wifi_off,
          title: "No Internet!",
          message: "Please check your internet connection and try again",
        ));
  }

  /// Shows a non-dismissible dialog when device is rooted
  /// Forces app exit as rooted devices are not supported
  void showRootedDialog() {
    Get.defaultDialog(
      title: "",
      barrierDismissible: false,
      backgroundColor: Colors.white,
      radius: 10,
      onWillPop: () async => false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CustomTextView(
            fontSize: 22,
            text: "Rooted Device Detected",
            textAlign: TextAlign.center,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),
          const CustomTextView(
            fontSize: 16,
            text: "This app is not allowed to run on rooted devices.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CommonMaterialButton(
            height: 50,
            width: 160,
            text: "Exit",
            textSize: 16,
            color: colorPrimary,
            onPressed: () => SystemNavigator.pop(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Determines and navigates to the appropriate next screen
  /// - Dashboard if user is logged in or has valid guest access
  /// - Login page otherwise
  Future<void> nextScreen() async {
    final isLoggedIn = authenticationManager?.isLogin() ?? false;
    final isGuestLoginEnabled = PrefUtils.getGuestLogin();
    final hasGuestId = PrefUtils.getGuestLoginId().isNotEmpty;

    await Future.delayed(const Duration(milliseconds: 600));

    if (isLoggedIn || (hasGuestId && isGuestLoginEnabled)) {
      Get.offAllNamed(DashboardPage.routeName);
    } else {
      SignInWithLinkedIn.logout();
      Get.offAllNamed(LoginPageOTP.routeName);
    }
  }

  /// Utility function to generate a random color
  /// Returns a Color object with random RGB values
  Color getRandomColor() {
    final random = Random();
    return Color(0xFF000000 + random.nextInt(0x00FFFFFF));
  }
}
