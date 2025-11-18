import 'dart:convert';
import 'dart:io';
import 'package:dreamcast/network/controller/internet_controller.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/api_repository/app_url.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../model/erro_code_model.dart';
import '../theme/app_colors.dart';
import '../utils/image_constant.dart';
import '../utils/pref_utils.dart';
import '../view/beforeLogin/globalController/authentication_manager.dart';
import '../view/beforeLogin/login/login_page_otp.dart';
import '../widgets/dialog/custom_animated_dialog_widget.dart';
import '../widgets/textview/customTextView.dart';
import '../view/eventFeed/model/createPostModel.dart';
import '../widgets/button/common_material_button.dart';
import 'digestauthclient.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:http_parser/http_parser.dart';
import 'exceptions.dart';

ApiService apiService = Get.find<ApiService>();

class ApiService extends GetxService {
  // API headers and credentials
  var authHeader;
  var DIGEST_AUTH_USERNAME = "";
  var DIGEST_AUTH_PASSWORD = "";
  var isDialogShow = false;

  // Initialize headers and auth info
  Future<ApiService> init() async {
    DIGEST_AUTH_USERNAME = "41ab073b088c9b12b231643ff6f437d9";
    DIGEST_AUTH_PASSWORD = "9381edb30e889126282379eae2bf2aee";
    AuthenticationManager authManager = Get.find();
    return this;
  }

  // Return dynamic headers based on request type
  dynamic getHeaders({bool? isMultipart}) {
    AuthenticationManager authManager = Get.find();
    authHeader = {
      "Content-Type": isMultipart == true
          ? "multipart/form-data"
          : "application/json; charset=utf-8",
      "X-Api-Key": '%2BiR%2Ftt9g8E1tk1%2BDCJgiO7i5XrI%3D',
      "X-Requested-With": "XMLHttpRequest",
      "dc-timezone": "-330",
      "Cookie": PrefUtils.getToken() ?? "",
      "User-Agent": authManager.osName.toUpperCase(),
      "Dc-OS": authManager.osName,
      "Dc-Device": authManager.dc_device,
      "Dc-Platform": "flutter",
      "Dc-OS-Version": authManager.platformVersion,
      "DC-UUID": "",
      "Dc-App-Version": authManager.currAppVersion.toString(),
      "dc-guest-id": PrefUtils.getGuestLoginId(),
    };
    return authHeader!;
  }

  // Perform POST request with digest authentication
  Future<dynamic> dynamicPostRequest(
      {dynamic body, url, dynamic defaultHeader, dynamic isLoginApi}) async {
    try {
      debugPrint("api body ${url + " \n" + jsonEncode(body)}");
      final response = await DigestAuthClient(
              DIGEST_AUTH_USERNAME, DIGEST_AUTH_PASSWORD)
          .post(Uri.parse(url), headers: getHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      debugPrint("api get response: ${url + " \n" + response.body}");
      if (isLoginApi == true) {
        if (json.decode(response.body)["status"]) {
          PrefUtils.setToken(response.headers['set-cookie'].toString());
        } else {
          PrefUtils.setToken("");
        }
      }
      if (ErrorCodeModel.fromJson(json.decode(response.body)).code == 440) {
        tokenExpire(url);
      }

      return response.body;
    } catch (e) {

      print("api error $e");
      return checkException(e); // Your custom exception handler
    }
  }

  // Perform GET request with digest authentication
  Future<dynamic> dynamicGetRequest({url, dynamic defaultHeader}) async {
    try {
      final response =
          await DigestAuthClient(DIGEST_AUTH_USERNAME, DIGEST_AUTH_PASSWORD)
              .get(Uri.parse(url), headers: getHeaders())
              .timeout(const Duration(seconds: 30));
      debugPrint("api get response: ${url + " \n" + response.body}");
      if (ErrorCodeModel.fromJson(json.decode(response.body)).code == 440) {
        tokenExpire(url);
      }
      return response.body;
    } catch (e) {
      return checkException(e); // Your custom exception handler
    }
  }

  /// Multipart request for travel desk with dynamic file upload
  Future<dynamic> commonMultipartAPi({
    required Map<String, dynamic> requestBody, // Allow dynamic values
    required String url,
    required dynamic formFieldData,
  }) async {
    final uri = Uri.parse(url);
    final req = http.MultipartRequest("POST", uri);

    // Attach all valid file fields
    for (int index = 0; index < formFieldData.length; index++) {
      var data = formFieldData[index];

      // Attach image if provided
      if (data.type == "file") {
        var imageFile = data.value ?? "";
        if (imageFile != null &&
            imageFile.isNotEmpty &&
            imageFile.toString().contains("https") == false) {
          final mimeType = lookupMimeType(imageFile, headerBytes: [0xFF, 0xD8]);
          if (mimeType != null) {
            final mimeTypeData = mimeType.split('/');
            req.files.add(await http.MultipartFile.fromPath(
              data.name,
              imageFile,
              contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
            ));
          } else {
            debugPrint("Error: Unsupported file type.");
            return {"error": "Unsupported file type."};
          }
        }
      }
    }

    // Add form fields to request
    req.fields.addAll(
        requestBody.map((key, value) => MapEntry(key, value.toString())));
    req.headers.addAll(authHeader);

    try {
      final response = await http.Response.fromStream(
        await DigestAuthClient(DIGEST_AUTH_USERNAME, DIGEST_AUTH_PASSWORD)
            .send(req)
            .timeout(const Duration(seconds: 50)),
      );

      debugPrint("Response: ${response.body}");

      final responseData = json.decode(response.body);

      if (responseData["code"] == 440) {
        tokenExpire(url);
      }

      return responseData;
    } on TimeoutException {
      debugPrint("Error: Request Timed Out.");
      return {"error": "Request Timed Out."};
    } on SocketException {
      debugPrint("Error: No Internet Connection.");
      return {"error": "No Internet Connection."};
    } on FormatException {
      debugPrint("Error: Invalid Response Format.");
      return {"error": "Invalid Response Format."};
    } catch (e) {
      debugPrint("Unexpected Error: $e");
      return {"error": e.toString()};
    }
  }

  // Multipart API for event feed (images, videos, or documents)
  Future<CreatePostModel?> createEventFeed(
      dynamic body, XFile? file, File? thumbnailFile, String? type) async {
    print("event feed body $body");
    final uri = Uri.parse(AppUrl.feedCreate);
    final req = http.MultipartRequest("POST", uri);

    // Attach media files
    if (file != null && file.path.isNotEmpty) {
      final mimeTypeData =
          lookupMimeType(file.path, headerBytes: [0xFF, 0xD8])!.split('/');
      if (type == "image" || type == "document") {
        req.files.add(await http.MultipartFile.fromPath("media", file.path,
            contentType: MediaType(mimeTypeData[0], mimeTypeData[1])));
      } else {
        if (thumbnailFile != null) {
          final mimeTypeData =
              lookupMimeType(thumbnailFile.path, headerBytes: [0xFF, 0xD8])!
                  .split('/');
          req.files.add(await http.MultipartFile.fromPath(
              "media", thumbnailFile.path,
              contentType: MediaType(mimeTypeData[0], mimeTypeData[1])));
          req.files.add(await http.MultipartFile.fromPath("video", file.path,
              contentType: MediaType(mimeTypeData[0], mimeTypeData[1])));
        }
      }
    }
    req.fields.addAll(body);
    req.headers.addAll(getHeaders());
    try {
      http.Response response1 = await http.Response.fromStream(
          await DigestAuthClient(DIGEST_AUTH_USERNAME, DIGEST_AUTH_PASSWORD)
              .send(req)
              .timeout(const Duration(seconds: 120)));
      if (CreatePostModel.fromJson(json.decode(response1.body)).code == 440) {
        tokenExpire(uri.toString());
      }
      return CreatePostModel.fromJson(json.decode(response1.body.toString()));
    } catch (e) {
      checkException(e);
    }
    return null;
  }

  /// Generic multipart upload handler with typed response
  Future<T?> uploadMultipartRequest<T>({
    required String url,
    required Map<String, String> fields,
    required Map<String, dynamic> files, // key: fieldName, value: file path
    Duration timeout = const Duration(seconds: 60),
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final uri = Uri.parse(url);
    final req = http.MultipartRequest("POST", uri);

    // Add form fields
    req.fields.addAll(fields);

    // Attach file paths
    for (var entry in files.entries) {
      final filePath = entry.value;
      if (filePath != null && filePath.toString().isNotEmpty) {
        final mimeTypeData =
            lookupMimeType(filePath, headerBytes: [0xFF, 0xD8])!.split('/');
        req.files.add(await http.MultipartFile.fromPath(
          entry.key,
          filePath,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
        ));
      }
    }

    // Add headers
    req.headers.addAll(getHeaders(isMultipart: true));

    try {
      final response = await http.Response.fromStream(
        await DigestAuthClient(DIGEST_AUTH_USERNAME, DIGEST_AUTH_PASSWORD)
            .send(req)
            .timeout(timeout),
      );

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return fromJson(decoded);
      }
    } catch (e) {
      checkException(e);
      debugPrint(e.toString());
      UiHelper.showFailureMsg(null, e.toString());
    }

    return null;
  }

  // Prevents repeated token-expired dialogs
  bool _isButtonDisabled = false;

  // Shows login expired dialog and resets app state
  tokenExpire(String? url) async {
    if (_isButtonDisabled) return; // Prevent further clicks
    _isButtonDisabled = true;
    Future.delayed(const Duration(seconds: 2), () {
      _isButtonDisabled =
          false; // Re-enable the button after the screen is closed
    });
    if (Get.isDialogOpen != true) {
      await Get.dialog(
          barrierDismissible: false,
          CustomAnimatedDialogWidget(
            title: "Login Expired",
            logo: "",
            description:
                "You have either logged out or you were automatically logged out for security purposes",
            buttonAction: "Login Again".tr,
            buttonCancel: "cancel".tr,
            isHideCancelBtn: true,
            onCancelTap: () {},
            onActionTap: () async {
              isDialogShow = false;
              PrefUtils.clearPreferencesData();
              if (Get.currentRoute != LoginPageOTP.routeName) {
                Get.offNamedUntil(LoginPageOTP.routeName, (route) => false);
              } else {
                Get.back();
              }
            },
          ));
    }
  }

  // Checks and shows error UI based on the type of exception
  dynamic checkException(Object exception) {
    String errorTitle = "";
    String errorMessage = "";

    if (exception is ServerException) {
      errorTitle = "Server Error [500]";
      errorMessage = exception.message.toString();
    } else if (exception is ClientException) {
      errorTitle = "Client Error";
      errorMessage = "Request failed from the client side.";
    } else if (exception is HttpException) {
      errorTitle = "Server Error";
      errorMessage = "Server is not responding. Please try again later.";
    } else {
      // Network issue (no internet)
      if (Get.isRegistered<InternetController>()) {
        Get.find<InternetController>().checkConnection();
      }
      if (errorTitle.isNotEmpty && errorMessage.isNotEmpty) {
        UiHelper.showFailureMsg(null, "${errorTitle} - ${errorMessage}");
      }
    }
    return {"status": false, "code": 500, "message": errorMessage, "body": {}};
  }
}
