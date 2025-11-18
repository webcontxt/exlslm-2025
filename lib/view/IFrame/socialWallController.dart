import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../api_repository/api_service.dart';
import '../../../model/guide_model.dart';
import '../../api_repository/app_url.dart';
import '../../routes/my_constant.dart';
import '../../theme/ui_helper.dart';

class SocialWallController extends GetxController {
  /// Observable string to hold the Social Wall URL
  var socialWallUrl = "".obs;

  /// Observable to manage loading state for the parent WebView
  var loading = false.obs;

  /// Observable to manage loading state for the child WebView
  var loadingChild = false.obs;

  /// To store API message from the response
  late var apiMessage;

  /// WebView controller for the child WebView
  late final WebViewController childWebViewController;

  /// WebView controller for the parent WebView
  late final WebViewController parentWebViewController;

  @override
  void onInit() {
    super.onInit();

    // Initialize child WebView controller with JS enabled, no zoom, and loading behavior
    childWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          loadingChild(true); // Show loading when child WebView starts
        },
        onPageFinished: (String url) {
          Future.delayed(const Duration(seconds: 1), () {
            loadingChild(false); // Hide loading after delay when finished
          });
        },
        onNavigationRequest: (NavigationRequest request) {
          return _navigationDelegate(request); // Handle custom URL routing
        },
      ));

    // Initialize parent WebView controller similarly
    parentWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          loading(true); // Show loading when parent WebView starts
        },
        onPageFinished: (String url) {
          Future.delayed(const Duration(seconds: 1), () {
            loading(false); // Hide loading after delay when finished
          });
        },
        onNavigationRequest: (NavigationRequest request) {
          return _navigationDelegate(request); // Handle custom URL routing
        },
      ));
  }

  /// Navigation handler to intercept and manage special URLs
  NavigationDecision _navigationDelegate(NavigationRequest request) {
    if (request.url.isNotEmpty &&
        !request.url.contains("https://widget.socialwalls.com") &&
        request.isMainFrame) {
      // Open all external non-widget URLs in in-app browser
      UiHelper.inAppWebView(Uri.parse(request.url));
      return NavigationDecision.prevent;
    } else if ((request.url.toString().startsWith('tel') ||
        request.url.toString().startsWith('whatsapp') ||
        request.url.toString().startsWith('mailto') && request.isMainFrame)) {
      // Handle telephone, WhatsApp, and email links
      UiHelper.inAppWebView(Uri.parse(request.url));
      return NavigationDecision.prevent;
    } else {
      // Allow all other URLs to load in WebView
      return NavigationDecision.navigate;
    }
  }

  /// Fetches Social Wall URL from API and sets it in both WebView controllers
  Future<dynamic> getSocialWallUrl() async {
    var result;
    loading(true); // Show loading
    final model = IFrameModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(
        url: "${AppUrl.iframe}/${MyConstant.slugSocialWall}",
      ),
    ));

    if (model.status ?? false) {
      // Update observables and WebViews if data fetch is successful
      result = {"status": model.body?.status ?? false};
      apiMessage = model.body?.messageData?.body ?? "";
      socialWallUrl(
          model.body?.status ?? false ? model.body?.webview ?? "" : "");
      parentSocialUpdateUrl(socialWallUrl.value);
      childSocialUpdateUrl(socialWallUrl.value);
      refresh(); // Trigger UI update
      loading(false);
    } else {
      // Handle failure case
      loading(false);
      result = {"status": false};
      apiMessage = model.body?.messageData?.body ?? "";
    }
    return result;
  }

  /// Loads the Social Wall URL into the parent WebView
  void parentSocialUpdateUrl(String url) {
    if (url?.isEmpty ?? false) {
      return;
    }
    parentWebViewController.loadRequest(Uri.parse(url));
  }

  /// Loads the Social Wall URL into the child WebView
  void childSocialUpdateUrl(String url) {
    if (url?.isEmpty ?? false) {
      return;
    }
    childWebViewController.loadRequest(Uri.parse(url));
  }
}
