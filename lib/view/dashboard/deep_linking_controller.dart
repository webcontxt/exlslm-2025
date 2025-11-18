import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:dreamcast/view/breifcase/controller/common_document_controller.dart';
import 'package:dreamcast/view/dashboard/dashboard_controller.dart';
import 'package:dreamcast/view/menu/controller/menuController.dart';
import 'package:get/get.dart';
import '../beforeLogin/globalController/authentication_manager.dart';
import '../menu/model/menu_data_model.dart';
import 'package:flutter/widgets.dart';

/// Controller for handling deep linking in the app using GetX.

class DeepLinkingController extends GetxController with WidgetsBindingObserver {
  final AuthenticationManager _authManager = Get.find();
  final DashboardController dashboardController = Get.find();

  final RxBool loading = false.obs;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Initialize deep links after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForDeepLinks();
      navigatePageAsPerNotification();
    });
  }

  /// no need Handles the deep link if app was opened from terminated state
  Future<void> _handleInitialDeepLink() async {
    try {
      final initialUri = await AppLinks().getInitialLink();
      if (initialUri != null) {
        debugPrint("Initial URI: $initialUri");
        _openDeeplinkPage(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial URI: $e');
    }
  }

  /// Listens for deep links while app is running (foreground/background)
  void _listenForDeepLinks() {
    _linkSubscription = AppLinks().uriLinkStream.listen((uri) {
      debugPrint("Initial Stream: $uri");
      _openDeeplinkPage(uri);
    });
  }

  /// Opens the deep link page
  void _openDeeplinkPage(Uri uri) {
    debugPrint("Initial i am calling: $uri");
    final queryParams = uri.queryParameters;
    final pageRouteName = queryParams['page'] ?? "";
    final pageRouteId = queryParams['id'] ?? "";
    final type = queryParams['type'] ?? "";
    final role = queryParams['role'] ?? "";

    // Ensure required controllers are registered
    if (!Get.isRegistered<HubController>()) {
      Get.lazyPut(() => HubController());
    }
    if (!Get.isRegistered<CommonDocumentController>()) {
      Get.lazyPut(() => CommonDocumentController());
    }

    // Navigate via HubController
    final hubController = Get.find<HubController>();
    hubController.commonMenuRouting(
      menuData: MenuData(
        pageId: pageRouteId,
        icon: "",
        role: role,
        slug: pageRouteName,
        type: type,
      ),
    );
  }

  /// Navigate as per notification payload
  Future<void> navigatePageAsPerNotification() async {
    if (_authManager.pageRouteName.isEmpty ||
        _authManager.pageRouteName == "null") {
      return;
    }

    // Ensure required controllers are registered
    if (!Get.isRegistered<HubController>()) {
      Get.lazyPut(() => HubController());
    }
    if (!Get.isRegistered<CommonDocumentController>()) {
      Get.lazyPut(() => CommonDocumentController());
    }

    final hubController = Get.find<HubController>();
    hubController.commonMenuRouting(
      menuData: MenuData(
        pageId: _authManager.pageRouteId,
        icon: "",
        id: _authManager.pageRouteId,
        role: _authManager.role,
        slug: _authManager.pageRouteName,
        type: _authManager.type,
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    _authManager.clearPageRoute();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
