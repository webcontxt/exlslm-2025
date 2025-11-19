
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/utils/file_manager.dart';
import 'package:dreamcast/utils/pref_utils.dart';
import 'package:dreamcast/view/home/screen/pdfViewer.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:saver_gallery/saver_gallery.dart';

class TravelDeskController extends GetxController {

  // Variable to hold the current tab index
  final tabIndex = 0.obs;
  // List to hold the names of the tabs
  var tabList = <String>[].obs;
  // Pdf download
  var showFileLoader = "".obs;

  // Loader variable to show loading state
  var loader = true.obs;
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  // Variable to hold the download progress
  var downloadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    createTab();
    callApi(0, false);
    /// pdf download initialization
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(requestAlertPermission: true);

    const initSettings = InitializationSettings(android: android, iOS: ios);
    flutterLocalNotificationsPlugin!.initialize(initSettings);
  }

  // Method to create the tabs
  Future<void> createTab() async {
    tabList.clear();
    tabList.add("Flight Details");
    // tabList.add("Cab Details");
    // tabList.add("Hotel Details");
    // tabList.add("Visa Details");
    // tabList.add("Passport");
  }

  // Common method for all tabs
  viewPdf({required String fileName, required String networkPath}) async {
    // Get the file path
    final directory = await FileManager.instance.getDocumentsDirectoryPath;
    final filePath = '$directory/$fileName.pdf';
    final pdfFile = File(filePath);

    if (PrefUtils.getDocumentPath(fileName) != networkPath &&
        networkPath.isNotEmpty) {
      final response = await http.get(Uri.parse(networkPath));
      if (response.statusCode == 200) {
        PrefUtils.saveDocumentPath(fileName, networkPath);
        FileManager.instance
            .saveFile("$fileName.pdf", response.bodyBytes)
            .then((filePath) async {
          Get.to(PdfViewPage(
              htmlPath: filePath, title: fileName, isLocalDataShow: true));
        });
      }
    } else {
      print("else ");
      final directory = await FileManager.instance.getDocumentsDirectoryPath;
      final filePath = '$directory/$fileName.pdf';
      if (await pdfFile.exists()) {
        Get.to(PdfViewPage(
          htmlPath: filePath,
          title: fileName,
          isLocalDataShow: true,
        ));
      } else {
        UiHelper.showFailureMsg(null, "Please check your internet connection.");
      }
    }
  }


  Future<String?> pdfDownload({String? networkPath, String? fileName, bool? showNotification}) async {
    showFileLoader(networkPath);
    if (!networkPath!.startsWith("https://")) {
      print("Error: The URL must start with 'https://'");
      return null;
    }

    try {
      if(networkPath.contains(".png") || networkPath.contains(".jpg") || networkPath.contains(".jpeg") || networkPath.contains(".webp") || networkPath.contains(".gif")) {
        var response = await Dio()
            .get(networkPath, options: Options(responseType: ResponseType.bytes));
        String name = networkPath.split('/').last;
        String picturesPath = name;
        final result = await SaverGallery.saveImage(
            Uint8List.fromList(response.data),
            quality: 60,
            fileName: picturesPath,
            androidRelativePath: "picture_imc_ai_gallery".tr,
            skipIfExists: true);
        if (result != null && result.isSuccess) {
          UiHelper.showSuccessMsg(null, "image_saved_in_gallery".tr);
          var res = {"isSuccess": result.isSuccess, "filePath": picturesPath};
          if (showNotification == true) {
            await _showNotification(res);
          }
        }
      }else{
        downloadPDF(networkPath: networkPath, fileName: fileName, showNotification: showNotification);
      }
    } catch (e) {
      print("Download error: $e");
      return null;
    }
  }



  Future<void> downloadPDF({String? networkPath, String? fileName, bool? showNotification}) async {
    try {
      // Get app-safe directory (no permissions needed)
      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/$fileName.pdf";

      Dio dio = Dio();

      await dio.download(
        networkPath!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint("Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );
      print("File downloaded to: $savePath");
     if(showNotification == true){
       print("File downloaded to: $savePath");
       var res = {"isSuccess": true, "filePath": savePath};
       _showNotification(res);
     }

    } catch (e) {
      debugPrint("Download failed: $e");
    }
  }


  /// local notification
  Future<void> _showNotification(Map<String, dynamic> downloadStatus) async {
    const android = AndroidNotificationDetails('1', 'channel name',
        // 'channel description',
        priority: Priority.high,
        importance: Importance.max);

    const platform = NotificationDetails(android: android);
    final json = jsonEncode(downloadStatus);
    final isSuccess = downloadStatus['isSuccess'];
    // print("${platform.iOS!.subtitle}" + "platform information");

    await flutterLocalNotificationsPlugin!.show(
        0, // notification id
        isSuccess ? 'success'.tr : 'failure'.tr,
        isSuccess ? 'file_uploaded_success'.tr : 'file_upload_error'.tr,
        platform,
        payload: json);
    // print("Notification Shown ===================================");
    await _onSelectNotification(json);
  }

  ///when user tap on notification

  Future<void> _onSelectNotification(String json) async {
    print(json);
    final obj = jsonDecode(json);
    if (obj['isSuccess']) {
      OpenFile.open(obj['filePath']);
    } else {
      UiHelper.showSuccessMsg(null, "${obj['error']}");
    }
  }


  ///****** call Apis ********///
  Future<void> callApi(int index, bool isRefresh) async {
    tabIndex(index);
  }


}
