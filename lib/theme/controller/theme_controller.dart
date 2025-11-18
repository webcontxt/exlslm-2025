import 'package:dreamcast/utils/pref_utils.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../main.dart';
import '../app_colors.dart';

enum AppFontSizeOption { small, medium, large, extraLarge }

class ThemeController extends GetxController with WidgetsBindingObserver {
  // Observable theme mode and font
  Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  RxString fontFamily = "FigTree".obs;
  var selectedFontSize = AppFontSizeOption.medium.obs;
  final RxDouble sliderValue = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // Start listening
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up
    super.onClose();
  }

  // Called when app resumes from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final context = Get.context;
      if (context != null) {
        loadThemeBasedOnSystem(context);
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    // This waits until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = Get.context;
      if (context != null) {
        loadThemeBasedOnSystem(context);
      }
    });
  }

  void loadThemeBasedOnSystem(BuildContext context) {
    print("session theme mode: ${PrefUtils.getThemeMode()}");
    print("session theme mode: ${themeMode.value.name}");
    print(
        "session theme mode: ${PrefUtils.getThemeMode() == ThemeMode.system.name}");

    if (PrefUtils.getThemeMode() == ThemeMode.system.name) {
      final isSystemDarkMode =
          MediaQuery.of(context).platformBrightness == Brightness.dark;
      themeMode.value = isSystemDarkMode ? ThemeMode.dark : ThemeMode.light;
    } else if (PrefUtils.getThemeMode() == ThemeMode.dark.name) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
    // Optionally apply theme and update UI
    Get.changeThemeMode(themeMode.value);
    setColorAsPerTheme(themeMode.value == ThemeMode.dark ? true : false);
  }

  double getFontSize(double baseSize) {
    switch (selectedFontSize.value) {
      case AppFontSizeOption.small:
        return baseSize - 2;
      case AppFontSizeOption.large:
        return baseSize + 2;
      case AppFontSizeOption.extraLarge:
        return baseSize + 4;
      case AppFontSizeOption.medium:
      default:
        return baseSize;
    }
  }

  void changeFontSize(AppFontSizeOption option) {
    print("Font size changed to: $option");
    selectedFontSize.value = option;
    // Force UI to refresh
    Get.forceAppUpdate();
  }

  void setColorAsPerTheme(bool isDarkMode) {
    //primary = isDarkMode ? const Color(0xffF08E20) : const Color(0xff4658A7);
    secondary = isDarkMode ? const Color(0xffDCDCDD) : const Color(0xFF333333);
    lightGray = isDarkMode ? const Color(0xff343434) : const Color(0xffF4F3F7);
    border = isDarkMode ? const Color(0x8a8a8a8e) : const Color(0xffDCDCDD);
    backgroundColor =
        isDarkMode ? const Color(0xff000000) : const Color(0xffFFFFFF);
    Get.forceAppUpdate();
  }

  // Change the app font dynamically
  void changeFont(String font) {
    fontFamily.value = font;
    Get.forceAppUpdate(); // Force rebuild to apply new font
  }

  /// Update the primary and secondary colors by the admin theme settings
  Future<void> updateColor({
    required Color primaryColor,
    required Color secondaryColor,
    required Color primaryColorDark,
    Color? lightGrayColor,
    Color? backgroundColor,
  }) async {
    primary =
        themeMode.value == ThemeMode.dark ? primaryColorDark : primaryColor;
    secondary = themeMode.value == ThemeMode.dark
        ? const Color(0xffDCDCDD)
        : secondaryColor;

    // Optional colors
    if (lightGrayColor != null) {
      lightGray = lightGrayColor;
    }
    if (backgroundColor != null) {
      backgroundColor = backgroundColor;
    }

    Get.forceAppUpdate();
  }

  // Return ThemeData based on current settings
  ThemeData get lightTheme => ThemeData(
      brightness: Brightness.light,
      fontFamily: fontFamily.value,
      secondaryHeaderColor: Colors.white,
      shadowColor: Colors.black,
      cardColor: const Color(0xFF333333),
      highlightColor: Colors.white,
      dividerColor: const Color(0xffDCDCDD),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF4F3F7), // Light background for text fields
      ),
      tabBarTheme: TabBarThemeData(
        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
        labelStyle: TextStyle(
            fontFamily: fontFamily.value,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorPrimary), // for selected tabs
        unselectedLabelStyle: TextStyle(
            fontFamily: fontFamily.value,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorGray), // for unselected tabs
      ),
      dialogTheme: DialogThemeData(
        barrierColor: Colors.grey.withOpacity(0.5),
      ),
      scaffoldBackgroundColor: white,
      colorScheme: ColorScheme.light(
          onSurface: const Color(0xFF333333),
          onPrimary: Colors.black,
          primary: colorPrimary,
          secondary: colorSecondary));

  ThemeData get darkTheme => ThemeData(
      brightness: Brightness.dark,
      fontFamily: fontFamily.value,
      tabBarTheme: TabBarThemeData(
        overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
        labelStyle: TextStyle(
            fontFamily: fontFamily.value,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorPrimary), // for selected tabs
        unselectedLabelStyle: TextStyle(
            fontFamily: fontFamily.value,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colorGray), // for unselected tabs
      ),
      dialogTheme: DialogThemeData(
        barrierColor: Colors.grey.withOpacity(0.5),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF343434), // Dark background for text fields
      ),
      scaffoldBackgroundColor: const Color(0xff000000),
      secondaryHeaderColor: Colors.black,
      shadowColor: Colors.white,
      highlightColor: Colors.white,
      dividerColor: const Color(0xffDCDCDD),
      cardColor: const Color(0xFF343434),
      colorScheme: ColorScheme.dark(
        onSurface: const Color(0xffDCDCDD),
        onPrimary: Colors.white,
        primary: const Color(0xffF08E20),
        secondary: colorSecondary,
      ));
}
