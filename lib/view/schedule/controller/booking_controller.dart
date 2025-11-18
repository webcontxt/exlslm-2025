import 'package:get/get.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../schedule/controller/session_controller.dart';
import 'dart:convert';
import 'package:dreamcast/view/myFavourites/controller/favourite_controller.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../schedule/model/scheduleModel.dart';
import '../../schedule/model/speaker_webinar_model.dart';
import '../../schedule/request_model/session_request_model.dart';

class SessionBookingController extends GetxController {
  var favouriteSessionList = <SessionsData>[].obs;

  var loading = false.obs;
  var isFirstLoading = false.obs;

  // Getting instances of other controllers via GetX
  FavouriteController favouriteController = Get.find();
  SessionController sessionController = Get.find();
  AuthenticationManager authenticationManager = Get.find();

  // Model to hold request parameters
  SessionRequestModel sessionRequestModel = SessionRequestModel();

  @override
  void onInit() {
    super.onInit();
    // Fetch initial API data on controller initialization
    getApiData();
  }

  // Prepare and set request model data then call API
  getApiData() async {
    sessionRequestModel = SessionRequestModel(
        page: 1,
        favourite: 0,
        booking: 1,
        filters: RequestFilters(
            text:
                favouriteController.textController.value.text.trim().toString(),
            sort: "ASC",
            params: RequestParams(date: "")));
    getBookmarkSession(isRefresh: false);
  }

  // Fetch session list based on bookmark/booking
  Future<void> getBookmarkSession({required isRefresh}) async {
    if (!isRefresh ?? false) {
      isFirstLoading(true); // Show loading for first time
    }

    try {
      final model = ScheduleModel.fromJson(json.decode(
        await apiService.dynamicPostRequest(
          body: sessionRequestModel,
          url: AppUrl.getSession,
        ),
      ));
      isFirstLoading(false);
      sessionController.isBookmarkLoaded(true);
      if (model.status! && model.code == 200) {
        // Clear existing data and update with new session list
        favouriteSessionList.clear();
        favouriteSessionList.addAll(model.body?.sessions ?? []);
        favouriteSessionList.refresh();

        // Update user session ID list
        sessionController.userIdsList.clear();
        if (favouriteSessionList.isNotEmpty) {
          sessionController.userIdsList
              .addAll(favouriteSessionList.map((obj) => obj.id).toList());

          // Fetch bookmarked session IDs
          //sessionController.getBookmarkIds();

          // If user is logged in, fetch speaker details
          if (authenticationManager.isLogin()) {
            getSpeakerWebinarList(
                requestBody: {"webinars": sessionController.userIdsList});
          }
        }

        update(); // Notify UI
      }
    } catch (e, stack) {
      print("Error found API: $e\n$stack");
    } finally {
      isFirstLoading(false);
    }
  }

  // Fetch speaker data for webinars and attach to corresponding sessions
  Future<void> getSpeakerWebinarList({required requestBody}) async {
    final model = SpeakerModelWebinarModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: requestBody,
        url: AppUrl.getSpeakerByWebinarId,
      ),
    ));

    if (model.status! && model.code == 200 && model.body != null) {
      for (var session in favouriteSessionList) {
        var matchingSpeakerData = model.body!
            .firstWhere((speakerData) => speakerData.id == session.id);

        if (matchingSpeakerData != null) {
          session.speakers?.addAll(matchingSpeakerData.sessionSpeaker ?? []);
          favouriteSessionList.refresh(); // Refresh UI with speaker updates
        }
      }
    } else {
      print(model.code.toString()); // Print error code if request fails
    }
  }
}
