import 'dart:convert';

import 'package:dreamcast/api_repository/app_url.dart';
import 'package:dreamcast/view/exhibitors/model/exibitorsModel.dart';
import 'package:dreamcast/view/exhibitors/request_model/request_model.dart';
import 'package:dreamcast/view/myFavourites/controller/favourite_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../routes/my_constant.dart';
import '../../exhibitors/controller/exhibitorsController.dart';

class FavBootController extends GetxController {
  var favouriteBootList = <Exhibitors>[].obs;

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  var loading = false.obs;
  var isFirstLoading = false.obs;
  FavouriteController favouriteController = Get.find();
  BootRequestModel bootRequestModel = BootRequestModel();
  final BoothController exhibitorsController = Get.find();

  //pagination of session
  late bool hasNextPage;
  late int _pageNumber;
  var isLoadMoreRunning = false.obs;
  ScrollController scrollController = ScrollController();

  /// Called when the controller is initialized.
  ///
  /// Triggers the initial API data fetch for favourite exhibitors.
  @override
  void onInit() {
    super.onInit();
    getApiData();
  }

  /// Prepares the boot request model and fetches the list of bookmarked exhibitors.
  getApiData() async {
    bootRequestModel = BootRequestModel(
        favourite: 1,
        filters: RequestFilters(
            text: favouriteController.textController.value.text.trim() ?? "",
            sort: "ASC",
            notes: false),
        page: 1);
    getBookmarkExhibitor();
  }

  /// Fetches the list of bookmarked exhibitors from the API and updates the observable list.
  Future<void> getBookmarkExhibitor() async {
    _pageNumber = 1;
    bootRequestModel.page = 1;
    exhibitorsController.isBookmarkLoaded(true);
    isFirstLoading(true);

    final model = ExhibitorsModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: bootRequestModel,
        url: "${AppUrl.exhibitorsListApi}/search",
      ),
    ));

    exhibitorsController.isBookmarkLoaded(false);
    if (model.status! && model.code == 200) {
      favouriteBootList.clear();
      favouriteBootList.value = model.body!.exhibitors ?? [];
      exhibitorsController.bookMarkIdsList.clear();
      exhibitorsController.bookMarkIdsList
          .addAll(favouriteBootList.map((obj) => obj.id).toList());

      hasNextPage = model.body?.hasNextPage ?? false;
      _pageNumber = _pageNumber + 1;
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
        bootRequestModel.page = _pageNumber;
        try {
          final model = ExhibitorsModel.fromJson(json.decode(
            await apiService.dynamicPostRequest(
              body: bootRequestModel,
              url: "${AppUrl.exhibitorsListApi}/search",
            ),
          ));
          if (model.status! && model.code == 200) {
            hasNextPage = model.body!.hasNextPage!;
            _pageNumber = _pageNumber + 1;
            if (model.body!.exhibitors != null &&
                model.body!.exhibitors!.isNotEmpty) {
              favouriteBootList.addAll(model.body!.exhibitors ?? []);
              exhibitorsController.bookMarkIdsList
                  .addAll(favouriteBootList.map((obj) => obj.id).toList());
            }
          }
        } catch (e) {
          print(e.toString());
        }
        isLoadMoreRunning(false);
      }
    });
  }
}
