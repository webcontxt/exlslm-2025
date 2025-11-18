import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/utils/event_timer_constant.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/view/breifcase/controller/common_document_controller.dart';
import 'package:dreamcast/view/eventFeed/controller/eventFeedController.dart';
import 'package:dreamcast/view/home/controller/for_you_controller.dart';
import 'package:dreamcast/view/home/model/config_detail_model.dart';
import 'package:dreamcast/view/menu/controller/menuController.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dreamcast/api_repository/api_service.dart';
import 'package:dreamcast/view/beforeLogin/globalController/authentication_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../api_repository/app_url.dart';
import '../../../model/guide_model.dart';
import '../../../utils/pref_utils.dart';
import '../../../widgets/dialog/custom_animated_dialog_widget.dart';
import '../../../widgets/home_menu_item.dart';
import '../../IFrame/socialWallController.dart';
import '../../IFrame/socialWallpage.dart';
import '../../eventFeed/model/feedDataModel.dart';
import '../../menu/model/menu_data_model.dart';
import '../../partners/controller/partnersController.dart';
import '../../schedule/model/scheduleModel.dart';
import '../../schedule/model/speaker_webinar_model.dart';
import '../screen/inAppWebview.dart';
import '../screen/pdfViewer.dart';

class HomeController extends GetxController {
  var isFirstLoading = false.obs;
  var isLiveSessionLoading = false.obs;

  ///used for the social wall
  var socialWallUrl = "".obs;
  var loading = false.obs;

  var configDetailBody = HomeConfigBody().obs;
  final AuthenticationManager _authManager = Get.find();

  int index = 0;

  /// List of today's live sessions.
  var todaySessionList = <dynamic>[].obs;
  var eventRemainingTime = "".obs;

  /// Status of the event, 0: Upcoming, 1: Live, 2: Ended
  var eventStatus = 0.obs;

  var menuFeatureHome = <MenuData>[].obs;
  var menuHorizontalHome = <MenuData>[].obs;
  var menuFooterHome = <MenuData>[].obs;

  var feedDataList = <Posts>[].obs;

  Set<String> existingAuditoriumKeys = {};

  var recommendedForYouList = [].obs;
  var userIdsList = [];

  /// Called when the controller is initialized.
  ///
  /// Sets up initial API calls, starts the timer widget, and initializes dependencies after the widget tree is built.
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initApiCall();
    });
    startTheTimerWidget();
    dependencies();
  }

  initApiCall() {
    _authManager.checkExistingToken();
    getHomeApi(isRefresh: false);
  }

  @override
  void onReady() {
    super.onReady();
    _loadInitialData();
  }

  void dependencies() {
    Get.put(SocialWallController());
  }

  ///default init api to get the default data about the app
  Future<void> getHomeApi({required bool isRefresh}) async {
    getTodaySession(isRefresh: true);
    await fetchHomeApiData(isRefresh: isRefresh);
    refreshResourceCenter();
    refreshAndGetEventFeed();
    refreshHubMenu();
  }

  ///this is first api of home page.
  Future<void> fetchHomeApiData({required bool isRefresh}) async {
    if (configDetailBody.value.datetime == null) {
      isFirstLoading(true);
    }
    final model = HomePageModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(url: AppUrl.getConfigDetail),
    ));
    isFirstLoading(false);
    if (model.status! && model.code == 200) {
      configDetailBody(model.homeConfigBody);
      _authManager.deeplinkUrl = model.homeConfigBody?.deepLink ?? "";
      configDetailBody.refresh();
      PrefUtils.saveFeedEmail(
          configDetailBody.value.organizers?.eventFeed?.id ?? "");
      socialWallUrl(configDetailBody.value.socialWall?.url ?? "");
      refreshOpenSocialWall(isGotoSocialWall: false);
      showWelcomeDialog();
    }
    //update();
  }

  ///update the url of social wall and open the page of social page.
  Future<void> refreshOpenSocialWall({required bool isGotoSocialWall}) async {
    if (Get.isRegistered<SocialWallController>()) {
      SocialWallController controller = Get.find();
      if (isGotoSocialWall) {
        controller.getSocialWallUrl();
        Get.to(() => SocialWallPage(
              title: "social_wall".tr,
              showToolbar: true,
            ));
      } else {
        controller.childSocialUpdateUrl(socialWallUrl.value);
      }
    }
  }

  ///refresh the resource center item.
  refreshResourceCenter() {
    if (Get.isRegistered<CommonDocumentController>()) {
      CommonDocumentController resourceCenterController = Get.find();
      resourceCenterController.getDocumentList(
          isRefresh: true, limitedMode: true);
      resourceCenterController.getBannerList(
          itemId: "", itemType: "home_banner");
    }

    if (Get.isRegistered<SponsorPartnersController>()) {
      SponsorPartnersController resourceCenterController = Get.find();
      resourceCenterController.homeSponsorsPartnersListApi(
          requestBody: {"limited_mode": true}, isRefresh: false);
    }
  }

  ///refresh the event feed.
  refreshAndGetEventFeed() {
    if (Get.isRegistered<EventFeedController>()) {
      EventFeedController eventFeedController = Get.find();
      eventFeedController.getEventFeed(isLimited: true);
    }
  }

  ///refresh the hub menu.
  refreshHubMenu() {
    if (Get.isRegistered<HubController>()) {
      HubController hubController = Get.find();
      hubController.getHubMenuAPi(isRefresh: true);
    }
  }

  ///its  used for to get live session data
  Future<void> getTodaySession({required bool isRefresh}) async {
    isLiveSessionLoading(true);
    final model = ScheduleModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: {
          "page": 1,
          "favourite": 0,
          "filters": {
            "params": {"status": 1}
          }
        },
        url: AppUrl.getSession,
      ),
    ));
    isLiveSessionLoading(false);
    if (model.status == true && model.code == 200) {
      todaySessionList.clear();
      todaySessionList.addAll(model.body?.sessions ?? []);
      userIdsList.clear();
      if (todaySessionList.isNotEmpty) {
        userIdsList.addAll(model.body!.sessions!.map((obj) => obj.id).toList());
        if (_authManager.isLogin()) {
          getSpeakerWebinarList(requestBody: {"webinars": userIdsList});
        }
      }
    } else {
      print(model.code.toString());
    }
  }

  ///the the speaker by session ids
  Future<void> getSpeakerWebinarList({required requestBody}) async {
    final model = SpeakerModelWebinarModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: requestBody,
        url: AppUrl.getSpeakerByWebinarId,
      ),
    ));

    if (model.status! && model.code == 200) {
      for (SessionsData session in todaySessionList) {
        var matchingSpeakerData = model.body!
            .firstWhere((speakerData) => speakerData.id == session.id);
        if (matchingSpeakerData.sessionSpeaker != null &&
            matchingSpeakerData.sessionSpeaker!.isNotEmpty) {
          session.speakers?.addAll(matchingSpeakerData.sessionSpeaker ?? []);
          todaySessionList.refresh();
        }
      }
    } else {
      print(model.code.toString());
    }
  }

  ///update the session data by the firebase database
  Future<void> _loadInitialData() async {
    DataSnapshot snapshot = await _authManager.firebaseDatabase
        .ref("${AppUrl.defaultFirebaseNode}/auditoriums")
        .get();

    if (snapshot.exists) {
      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      // Store existing keys in the Set
      data.forEach((key, value) {
        existingAuditoriumKeys.add(key);
      });
      initAudiRefUpdate();
    } else {
      initAudiRefUpdate();
    }
  }

  ///initialize the firebase database reference update
  initAudiRefUpdate() {
    _authManager.firebaseDatabase
        .ref("${AppUrl.defaultFirebaseNode}/auditoriums")
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        String childKey = event.snapshot.key!;
        if (!existingAuditoriumKeys.contains(childKey)) {
          getTodaySession(isRefresh: true);
        }
      }
    });

    _authManager.firebaseDatabase
        .ref("${AppUrl.defaultFirebaseNode}/auditoriums")
        .onChildChanged
        .listen((event) {
      if (event.snapshot.value != null) {
        String childKey = event.snapshot.key!;
        // Only trigger API for new additions
        try {
          if (todaySessionList.value.isNotEmpty) {
            Iterable<int>.generate(todaySessionList.value.length)
                .forEach((index) {
              if (todaySessionList.value[index].id == childKey) {
                todaySessionList.value.removeAt(index);
                todaySessionList.refresh();
              }
            });
          }
        } catch (e) {
          print(e.toString());
        }
      }
    });
  }

  ///builds an event object with the given parameters.
  Event buildEvent(
    String eventName,
    location, {
    Recurrence? recurrence,
  }) {
    debugPrint(
        DateTime.parse(configDetailBody.value.datetime?.end ?? "").toString());
    return Event(
      title: eventName,
      description: configDetailBody.value.description ?? "",
      location: location,
      startDate: DateTime.parse(configDetailBody.value.datetime?.start ?? ""),
      endDate: DateTime.parse(configDetailBody.value.datetime?.end ?? ""),
      allDay: false,
      iosParams: const IOSParams(reminder: Duration(minutes: 40)),
      recurrence: recurrence,
    );
  }

  /// Starts the event timer and continuously updates the timer and status every second.
  startTheTimerWidget() {
    // Calculate and set the remaining months until the event using provided start and end dates, and timezone.
    EventTimerConstant.getRemainingTImeCounter(
      eventDate: configDetailBody.value.datetime?.start?.toString() ?? "",
      eventEndDate: configDetailBody.value.datetime?.end?.toString() ?? "",
      timezone: PrefUtils.getTimezone() ?? "",
    );

    // Start a periodic timer that runs every 1 second to update the event timer and status.
    Timer.periodic(const Duration(seconds: 1), (timer) {
      getEventTimer(); // Update the countdown timer or time display.
      getEventStatus(); // Update the event status (e.g., upcoming, live, ended).
    });
  }

  /// Gets the remaining time until the event starts or ends, and updates the event status.
  getEventTimer() {
    eventRemainingTime.value = EventTimerConstant.getRemainingTImeCounter(
        eventDate: configDetailBody.value.datetime?.start?.toString() ?? "",
        eventEndDate: configDetailBody.value.datetime?.end?.toString() ?? "",
        timezone: PrefUtils.getTimezone() ?? "");
  }

  /// Checks the current date against the event's start and end dates to determine the event status.
  getEventStatus() {
    eventStatus.value = EventTimerConstant.isCurrentDateInRangeOrCrossed(
          startDateTime:
              configDetailBody.value.datetime?.start?.toString() ?? "",
          endDateTime: configDetailBody.value.datetime?.end?.toString() ?? "",
          currentDateTime: UiHelper.getCurrentDate(
              timezone: PrefUtils.getTimezone() ?? "Asia/Kolkata"),
        ) ??
        0;
  }

  /// Fetches and displays an HTML page or PDF based on the provided slug.
  ///
  /// [title] – Optional title for the page.
  /// [slug] – The unique identifier used to fetch the content.
  /// [isExternal] – If true, opens the link in an external web view; otherwise, opens in an in-app screen.
  Future<void> getHtmlPage(String? title, String slug, bool isExternal) async {
    try {
      loading(true); // Show loading indicator.

      // Make API request to fetch iframe content based on slug.
      final model = IFrameModel.fromJson(json.decode(
        await apiService.dynamicGetRequest(
          url: "${AppUrl.iframe}/$slug",
        ),
      ));

      loading(false); // Hide loading indicator.

      if (model.status == true) {
        final body = model.body;

        // Check if the response body indicates a failure.
        if (body?.status == false) {
          UiHelper.showFailureMsg(
            null,
            body?.messageData?.body ?? "Something went wrong",
          );
          return;
        }

        final webview = body?.webview;

        if (webview != null) {
          if (webview.contains("pdf")) {
            // If the URL contains 'pdf', open it in the PDF viewer page.
            Get.to(PdfViewPage(htmlPath: webview, title: title));
          } else if (isExternal) {
            // If it's marked as external, open in external browser or in-app external webview.
            UiHelper.inAppWebView(Uri.parse(webview));
          } else {
            // Open in the custom in-app webview route with provided arguments.
            Get.toNamed(CustomWebViewPage.routeName, arguments: {
              "page_url": webview,
              "title": title,
            });
          }
        } else {
          // If webview data is missing from the response.
          UiHelper.showFailureMsg(null, "Webview data is missing");
        }
      } else {
        // If model status is false, show general failure message.
        UiHelper.showFailureMsg(null, model.message ?? "Failed to load data");
      }
    } catch (e) {
      loading(false); // Hide loading if an error occurs.
      UiHelper.showFailureMsg(
          null, "An error occurred: $e"); // Show error message.
    }
  }

  showWelcomeDialog() {
    if (_authManager.showWelcomeDialog) {
      if (configDetailBody.value.welcomeContent?.status ?? false) {
        Future.delayed(const Duration(seconds: 1), () async {
          await Get.dialog(
              barrierDismissible: false,
              PopScope(
                canPop: false,
                child: WelcomeAnimatedDialogWidget(
                  welcomeContent: configDetailBody.value.welcomeContent,
                  title: configDetailBody.value.welcomeContent?.title ?? "",
                  logo: configDetailBody.value.welcomeContent?.media ?? "",
                  description:
                      configDetailBody.value.welcomeContent?.text ?? "",
                  buttonAction: "start_exploring!".tr,
                  buttonCancel: "cancel".tr,
                  isHideCancelBtn: true,
                  onCancelTap: () {},
                  onActionTap: () async {},
                ),
              ));
          _authManager.showWelcomeDialog = false;
        });
      }
    }
  }

  bool isHubLoading() {
    if (Get.isRegistered<HubController>()) {
      HubController hubController = Get.find();
      return hubController.contentLoading.value;
    } else {
      return false;
    }
  }
}
