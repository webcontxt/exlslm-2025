import 'dart:convert';

import 'package:dreamcast/view/myFavourites/controller/favourite_controller.dart';
import 'package:dreamcast/view/myFavourites/model/bookmark_speaker_model.dart';
import 'package:dreamcast/view/representatives/request/network_request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../../routes/my_constant.dart';
import '../../representatives/controller/user_detail_controller.dart';
import '../../representatives/model/user_model.dart';

class FavUserController extends GetxController {
  var favouriteAttendeeList = <Representatives>[].obs;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  NetworkRequestModel networkRequestModel = NetworkRequestModel();
  var loading = false.obs;
  var isFirstLoading = false.obs;

  FavouriteController favouriteController = Get.find();
  late UserDetailController userController;

  //pagination of session
  late bool hasNextPage;
  late int _pageNumber;
  var isLoadMoreRunning = false.obs;
  ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();

    /// Initialize the UserDetailController if not already registered
    if (Get.isRegistered<UserDetailController>()) {
      userController = Get.find();
    } else {
      userController = Get.put(UserDetailController());
    }
    getApiData();
  }

  getApiData() async {
    ///its a initial request for the get the data
    networkRequestModel = NetworkRequestModel(
        role: MyConstant.networking,
        page: 1,
        favorite: 1,
        filters: RequestFilters(
            text: favouriteController.textController.value.text.trim(),
            isBlocked: false,
            sort: "ASC",
            notes: false,
            params: {}));
    getBookmarkUser();
  }

  /// Fetches the list of bookmarked users from the API and updates the observable list.
  Future<void> getBookmarkUser() async {
    userController.isBookmarkLoaded(true);
    isFirstLoading(true);
    networkRequestModel.page = 1;
    _pageNumber = 1;
    final model = RepresentativeModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: networkRequestModel,
        url: "${AppUrl.usersListApi}/search",
      ),
    ));
    userController.isBookmarkLoaded(false);
    if (model.status! && model.code == 200) {
      /// Clear the existing list and add the new favourites
      favouriteAttendeeList.clear();
      favouriteAttendeeList.addAll(model.body!.representatives ?? []);
      userController.bookMarkIdsList.clear();
      userController.bookMarkIdsList
          .addAll(favouriteAttendeeList.map((obj) => obj.id).toList());
      hasNextPage = model.body?.hasNextPage ?? false;
      _pageNumber = _pageNumber + 1;
      userController.getRecommendedIds();
      if (hasNextPage) {
        _loadMore();
      }
    } else {
      print(model.code.toString());
    }
    isFirstLoading(false);
  }

  Future<void> _loadMore() async {
    scrollController.addListener(() async {
      if (hasNextPage == true &&
          isFirstLoading.value == false &&
          isLoadMoreRunning.value == false &&
          scrollController.position.maxScrollExtent ==
              scrollController.position.pixels) {
        isLoadMoreRunning(true);
        networkRequestModel.page = _pageNumber;
        try {
          final model = RepresentativeModel.fromJson(json.decode(
            await apiService.dynamicPostRequest(
              body: networkRequestModel,
              url: "${AppUrl.usersListApi}/search",
            ),
          ));
          if (model.status! && model.code == 200) {
            hasNextPage = model.body!.hasNextPage!;
            _pageNumber = _pageNumber + 1;
            favouriteAttendeeList.addAll(model.body!.representatives ?? []);
            userController.bookMarkIdsList.addAll(
                model.body!.representatives!.map((obj) => obj.id).toList());
            userController.getRecommendedIds();
          }
        } catch (e) {
          print(e.toString());
        }
        isLoadMoreRunning(false);
      }
    });
  }
}
