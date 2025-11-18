import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;

class InternetController extends GetxController {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final isDeviceConnected = false.obs;
  final isSlowConnection = false.obs;
  bool _isScreenShown = false;

  @override
  void onInit() {
    _startMonitoring();
    super.onInit();
  }

  void _startMonitoring() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      await _checkConnection();
    });

    // Initial check
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    bool hasInternet = await InternetConnectionChecker().hasConnection;
    isDeviceConnected.value = hasInternet;
    checkConnection();
  }

  checkConnection() async {
    if (!isDeviceConnected.value) {
      isSlowConnection.value = false;
      _navigateToErrorScreen(
          "No Internet", "Please check your connection.", Icons.wifi_off);
    } else {
      bool slow = await _isConnectionSlow();
      isSlowConnection.value = slow;

      if (slow) {
        _navigateToErrorScreen(
            "Slow Connection",
            "Your internet is running slow.",
            Icons.signal_cellular_connected_no_internet_4_bar);
      } else {
        _navigateToErrorScreen(
          "Back Online",
          "You are now connected to the internet.",
          Icons.wifi_outlined,
        );
      }
    }
  }

  Future<bool> _isConnectionSlow() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;

      // Consider slow if request took more than 1500ms
      return response.statusCode != 200 || elapsed > 1500;
    } catch (_) {
      // On timeout or error, treat as slow or unreachable
      return true;
    }
  }

  static bool showingInternet = false;
  void _navigateToErrorScreen(String title, String message, IconData icon) {
    if (isDeviceConnected.value && showingInternet) {
      showingInternet = false;
      noInternetMessage(title, message, icon);
      Get.closeCurrentSnackbar();
      return;
    }

    if (!isDeviceConnected.value && !showingInternet) {
      showingInternet = true;
      noInternetMessage(title, message, icon);
    }
  }

  noInternetMessage(String title, String message, IconData icon) {
    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      isDismissible: false,
      duration: isDeviceConnected.value
          ? const Duration(seconds: 5)
          : const Duration(days: 1),
      backgroundColor:
          isDeviceConnected.value ? Colors.green : Colors.red.shade700,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 12,
      messageText: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}

class ThrottledClient extends http.BaseClient {
  final http.Client _inner;
  final int bytesPerSecond;

  ThrottledClient({required this.bytesPerSecond}) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final streamedResponse = await _inner.send(request);

    final throttledStream = streamedResponse.stream.transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) async {
          sink.add(data);
          final delay = data.length / bytesPerSecond;
          await Future.delayed(Duration(milliseconds: (delay * 1000).round()));
        },
      ),
    );

    return http.StreamedResponse(
      throttledStream,
      streamedResponse.statusCode,
      contentLength: streamedResponse.contentLength,
      request: streamedResponse.request,
      headers: streamedResponse.headers,
      isRedirect: streamedResponse.isRedirect,
      reasonPhrase: streamedResponse.reasonPhrase,
      persistentConnection: streamedResponse.persistentConnection,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
