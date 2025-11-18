import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dreamcast/theme/controller/theme_controller.dart';
import 'package:dreamcast/utils/initial_bindings.dart';
import 'package:dreamcast/utils/logger.dart';
import 'package:dreamcast/utils/pref_utils.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/beforeLogin/splash/splash_page.dart';
import 'package:dreamcast/view/representatives/controller/networkingController.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dreamcast/routes/app_pages.dart';
import 'package:toastification/toastification.dart';
import 'fcm/firebase_options.dart';
import 'localization/app_localization.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Global navigator key for showing dialogs, snackbars etc. from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Enable insecure SSL renegotiation (for legacy compatibility if needed)
  final context = SecurityContext.defaultContext;
  context.allowLegacyUnsafeRenegotiation = true;

  // ✅ Ensure Flutter bindings are initialized before any plugin or Firebase use
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI preferences
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: SystemUiOverlay.values);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    statusBarColor: Colors.transparent,
  ));

  // Reset GetX to clear previously registered dependencies (optional safety)
  Get.reset();

  // Initialize local storage using GetStorage
  await GetStorage.init();

  // Set device orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize FlutterDownloader for file downloads (with SSL ignore)
  await FlutterDownloader.initialize(ignoreSsl: true);

  // Initialize Firebase with custom name and platform-specific options
  await Firebase.initializeApp(
    name: "Dreamcast-2024",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup Awesome Notifications with a high-importance notification channel
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'high_importance_channel',
        channelName: 'High Importance Notifications',
        channelDescription:
            'Notification channel for Dreamcast 2024 notifications',
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
        playSound: true,
        onlyAlertOnce: true,
        importance: NotificationImportance.High,
      ),
    ],
  );

  // 🔁 Register background FCM message handler
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  // Initialize custom logger
  Logger.init(LogMode.live);

  // Initialize shared preference utility
  await PrefUtils.init();

  // Register ThemeController with GetX (used for theme switching)
  Get.put(ThemeController());
  // Launch the main app
  runApp(MyApp());
}

/// ✅ Background FCM message handler runs in a separate isolate,
/// so we must manually initialize Flutter bindings and Firebase again here.
@pragma('vm:entry-point')
Future<void> backgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Required to use plugins in background isolate
  await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions.currentPlatform); // Re-initialize Firebase

  // Show notification using AwesomeNotifications if payload exists
  if (message.notification != null) {
    await AwesomeNotifications().createNotificationFromJsonData(message.data);
  }
}

/// Optional Crashlytics setup for error logging
initCrashlytics() {
  const fatalError = true;

  // Capture Flutter framework errors
  FlutterError.onError = (errorDetails) {
    if (fatalError) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } else {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };

  // Capture platform-level (async) errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (fatalError) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };
}

/// Main Application Widget
class MyApp extends StatelessWidget {
  final themeController = Get.find<ThemeController>(); // Access ThemeController

  MyApp({Key? key}) : super(key: key);

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return ToastificationWrapper(
          child: Obx(
            () => GetMaterialApp(
              theme: themeController.lightTheme, // Light theme config
              darkTheme: themeController.darkTheme, // Dark theme config
              themeMode: ThemeMode.light, // Mode (light/dark/system)
              navigatorKey: navigatorKey, // Global nav key
              defaultTransition: Transition.fade,
              transitionDuration: const Duration(milliseconds: 300),
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  child: GestureDetector(
                    onTap: () {
                      FocusManager.instance.primaryFocus
                          ?.unfocus(); // Dismiss keyboard
                    },
                    child: child!,
                  ),
                );
              },
              title: '',
              debugShowCheckedModeBanner: false,
              initialBinding: InitialBindings(), // Bind dependencies on startup
              getPages: AppPages.pages, // Route definitions
              initialRoute: SplashScreen.routeName, // Launch route
              translations: AppLocalization(), // Localization translations
              locale: Get.deviceLocale, // Default locale based on device
              fallbackLocale:
                  const Locale('en', 'US'), // Fallback if locale not found
            ),
          ),
        );
      },
    );
  }
}

///
// 1. uncomment  app version check codee in auth manager