import 'dart:convert';

import 'package:dreamcast/view/beforeLogin/globalController/authentication_manager.dart';
import 'package:dreamcast/view/myFavourites/controller/favourite_controller.dart';
import 'package:dreamcast/view/schedule/controller/session_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../schedule/model/scheduleModel.dart';
import '../../schedule/model/speaker_webinar_model.dart';
import '../../schedule/request_model/session_request_model.dart';

class FavSessionController extends GetxController {
  var favouriteSessionList = <SessionsData>[].obs;

  var loading = false.obs;
  var isFirstLoading = false.obs;

  var userIdsList = <dynamic>[];
  FavouriteController favouriteController = Get.find();
  SessionController sessionController = Get.find();
  AuthenticationManager authenticationManager = Get.find();

  SessionRequestModel sessionRequestModel = SessionRequestModel();

  //pagination of session
  late bool hasNextPage;
  late int _pageNumber;
  var isLoadMoreRunning = false.obs;
  ScrollController scrollController = ScrollController();

  /// Called when the controller is initialized.
  ///
  /// Triggers the initial API data fetch for favourite sessions.
  @override
  void onInit() {
    super.onInit();
    getApiData();
  }

  /// Prepares the session request model and fetches the list of bookmarked sessions.
  getApiData() async {
    sessionRequestModel = SessionRequestModel(
        page: 1,
        favourite: 1,
        filters: RequestFilters(
            text:
                favouriteController.textController.value.text.trim().toString(),
            sort: "ASC",
            params: RequestParams(date: "")));
    getBookmarkSession(isRefresh: false);
  }

  /// Fetches the list of bookmarked sessions from the API and updates the observable list.
  Future<void> getBookmarkSession({required isRefresh}) async {
    sessionRequestModel.page = 1;
    _pageNumber = 1;
    if (!isRefresh ?? false) {
      isFirstLoading(true);
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
        favouriteSessionList.clear();
        favouriteSessionList.addAll(model.body?.sessions ?? []);
        favouriteSessionList.refresh();
        userIdsList.clear();
        if (favouriteSessionList.isNotEmpty) {
          userIdsList
              .addAll(favouriteSessionList!.map((obj) => obj.id).toList());
          sessionController.bookMarkIdsList.clear();
          sessionController.bookMarkIdsList
              .addAll(favouriteSessionList.map((obj) => obj.id).toList());

          if (authenticationManager.isLogin()) {
            getSpeakerWebinarList(requestBody: {"webinars": userIdsList});
          }
          hasNextPage = model.body?.hasNextPage ?? false;
          _pageNumber = _pageNumber + 1;
          if (hasNextPage) {
            _loadMore();
          }
        }
        update();
        isFirstLoading(false);
      }
    } catch (e, stack) {
      print("Error in user detail API: $e\n$stack");
    } finally {
      isFirstLoading(false);
    }
  }

  Future<void> _loadMore() async {
    scrollController.addListener(() async {
      if (hasNextPage == true &&
          isFirstLoading.value == false &&
          isLoadMoreRunning.value == false &&
          scrollController.position.maxScrollExtent ==
              scrollController.position.pixels) {
        isLoadMoreRunning(true);
        sessionRequestModel.page = _pageNumber;
        try {
          final model = ScheduleModel.fromJson(json.decode(
            await apiService.dynamicPostRequest(
              body: sessionRequestModel,
              url: AppUrl.getSession,
            ),
          ));
          if (model.status! && model.code == 200) {
            hasNextPage = model.body!.hasNextPage!;
            _pageNumber = _pageNumber + 1;
            favouriteSessionList.addAll(model.body?.sessions ?? []);
            userIdsList.clear();
            if (favouriteSessionList.isNotEmpty) {
              userIdsList
                  .addAll(favouriteSessionList!.map((obj) => obj.id).toList());
              sessionController.bookMarkIdsList
                  .addAll(favouriteSessionList.map((obj) => obj.id).toList());

              if (authenticationManager.isLogin()) {
                getSpeakerWebinarList(requestBody: {"webinars": userIdsList});
              }
            }
          }
        } catch (e) {
          print(e.toString());
        }
        isLoadMoreRunning(false);
      }
    });
  }

  ///Get the speaker list by webinar id
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
          /// Add the speakers to the session
          session.speakers?.addAll(matchingSpeakerData.sessionSpeaker ?? []);
          favouriteSessionList.refresh();
        }
      }
    } else {
      print(model.code.toString());
    }
  }
}
