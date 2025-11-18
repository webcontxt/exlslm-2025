import 'dart:convert';

import 'package:dreamcast/network/controller/internet_controller.dart';
import 'package:dreamcast/view/representatives/model/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../../routes/my_constant.dart';
import '../../account/controller/account_controller.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import 'user_detail_controller.dart';
import '../model/user_filter_model.dart';
import '../model/user_count_model.dart';
import '../request/network_request_model.dart';

class NetworkingController extends GetxController with WidgetsBindingObserver {
  final AuthenticationManager _authenticationManager = Get.find();
  AuthenticationManager get authenticationManager => _authenticationManager;
  final InternetController internetController = Get.find();

  late bool hasNextPage;
  late int _pageNumber;
  var isFirstLoading = false.obs;
  var isLoading = false.obs;
  var isFavLoading = false.obs;
  var isLoadMoreRunning = false.obs;

  final textController = TextEditingController().obs;

  ScrollController scrollControllerAttendee = ScrollController();

  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  ItemScrollController itemScrollController = ItemScrollController();

  ScrollController nestedScrollController = ScrollController();

  var attendeeList = <Representatives>[].obs;

  var userFilterBody = UserBodyFilter().obs;
  var tempFilterBody = UserBodyFilter().obs;
  var isFilterApply = false.obs;
  var role = MyConstant.networking;
  //extra field.
  var selectedSort = "ASC".obs;
  TextEditingController searchController = TextEditingController();
  Rx<bool> isSelectedSwitch = false.obs;

  late UserDetailController userDetailController;
  var totalUserCount = "".obs;

  ///used for the filter data
  NetworkRequestModel networkRequestModel = NetworkRequestModel();
  var isReset = false.obs;

  ///refresh the page.
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  GlobalKey<RefreshIndicatorState> get refreshIndicatorKey =>
      _refreshIndicatorKey;

  var appState = AppLifecycleState.resumed.obs;

  @override
  void onInit() {
    // Add the controller as a WidgetsBinding observer
    bindingController();
    WidgetsBinding.instance.addObserver(this);
    super.onInit();
    userDetailController = Get.isRegistered<UserDetailController>()
        ? Get.find()
        : Get.put(UserDetailController());
    _pageNumber = 1;

    ///its a initial request for the get the data
    networkRequestModel = NetworkRequestModel(
        role: role,
        favorite: 0,
        filters: RequestFilters(
            text: textController.value.text.trim() ?? "",
            isBlocked: false,
            sort: "",
            notes: false,
            params: {}));
    hasNextPage = false;
  }

  @override
  void onClose() {
    // Remove the controller from observers
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  ///call the api from  the dashbaord controller
  initApiCall() {
    textController.value.clear();
    networkRequestModel.filters?.text = "";
    attendeeAPiCall(isRefresh: false);
  }

  //its used for the binding the other controller.
  Future<void> bindingController() async {
    Get.lazyPut(() => AccountController());
  }

  ///main entry points to call the api first.
  Future<void> attendeeAPiCall({required isRefresh}) async {
    await getAttendeeList(isRefresh: isRefresh);
  }

  ///get the total user count
  Future<void> getUserCount({required isRefresh}) async {
    final userCountModel = UserCountModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: networkRequestModel,
        url: "${AppUrl.usersListApi}/getTotalCount",
      ),
    ));
    if (userCountModel.status! &&
        userCountModel.code == 200 &&
        userCountModel.body != null) {
      totalUserCount(userCountModel.body?.total.toString());
    }
  }

  ///get the user list and no of user count.
  Future<void> getAttendeeList({required isRefresh}) async {
    _pageNumber = 1;
    networkRequestModel.page = 1;

    if (attendeeList.isEmpty) {
      isFirstLoading(!isRefresh);
    }

    try {
      final model = RepresentativeModel.fromJson(json.decode(
        await apiService.dynamicPostRequest(
          body: networkRequestModel,
          url: "${AppUrl.usersListApi}/search",
        ),
      ));
      isFirstLoading(false);
      if (model.status! && model.code == 200) {
        attendeeList.clear();
        userDetailController.clearDefaultList();
        userDetailController.userIdsList.clear();
        if (model.body!.representatives != null &&
            model.body!.representatives!.isNotEmpty) {
          attendeeList.assignAll(model.body!.representatives ?? []);
          userDetailController.userIdsList
              .addAll(attendeeList.map((obj) => obj.id).toList());
        }

        hasNextPage = model.body?.hasNextPage ?? false;
        attendeeList.refresh();
        isFirstLoading(false);
        userDetailController.getBookmarkAndRecommendedByIds();
        _pageNumber = _pageNumber + 1;
        getUserCount(isRefresh: true);
        azLoadMore();
      }
    } catch (e, stack) {
      print("Error in API: $e\n$stack");
    } finally {
      isFirstLoading(false);
    }
  }

  ///load the more data when user scrolls to the bottom of the list.
  Future<void> azLoadMore() async {
    itemPositionsListener.itemPositions.addListener(() async {
      final positions = itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty) {
        final lastVisibleIndex = positions
            .where((element) => element.itemTrailingEdge <= 1)
            .reduce((max, element) =>
                max.itemTrailingEdge > element.itemTrailingEdge ? max : element)
            .index;

        if (hasNextPage == true &&
            isFirstLoading.value == false &&
            isLoadMoreRunning.value == false &&
            lastVisibleIndex >= attendeeList.length - 5 &&
            internetController.isDeviceConnected.value) {
          // Load more when close to the end
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

              attendeeList.addAll(model.body!.representatives!);
              attendeeList.value = attendeeList.toSet().toList();

              attendeeList.refresh();

              if (model.body!.representatives != null &&
                  model.body!.representatives!.isNotEmpty) {
                userDetailController.userIdsList.addAll(
                    model.body!.representatives!.map((obj) => obj.id).toList());
              }
              await userDetailController.getBookmarkAndRecommendedByIds();
              update();
            }
          } catch (e) {
            print(e.toString());
            isLoadMoreRunning(false);
          }
          isLoadMoreRunning(false);
        }
      }
    });
  }

  ///reset the filter on button
  Future<bool> getAndResetFilter({
    required bool isRefresh,
    bool? isFromReset,
  }) async {
    final requestBody = {"role": role};
    isLoading(isRefresh);

    try {
      final response = await apiService.dynamicPostRequest(
        body: requestBody,
        url: "${AppUrl.usersListApi}/getFilters",
      );

      final model = RepresentativeFilterModel.fromJson(json.decode(response));

      if (model.status == true && model.code == 200 && model.body != null) {
        selectedSort = "ASC".obs;
        userFilterBody.value = model.body!;
        if (isFromReset != true) {
          tempFilterBody.value = model.body!;
        }
        return true;
      }

      return false;
    } catch (e, stack) {
      print("Error in getAndResetFilter: $e\n$stack");
      return false;
    } finally {
      isLoading(false);
    }
  }

  ///this is used for the remove the filter is its not applied.
  clearFilterIfNotApply() {
    try {
      if (isReset.value) {
        userFilterBody(tempFilterBody.value);
        isReset(false);
      }
      userFilterBody.value.filters?.forEach((data) {
        if (data.value is List) {
          data.value = data.options
                  ?.where((opt) => opt.apply)
                  .map((opt) => opt.id)
                  .toList() ??
              [];
        } else {
          data.value = data.options
              ?.firstWhere((opt) => opt.apply, orElse: () => Options(id: ""))
              .id;
        }
      });

      ///this is used to reset the default value after filter is not apply
      final filter = userFilterBody.value;
      filter.notes?.value = filter.notes?.apply;
      filter.isBlocked?.value = filter.isBlocked?.apply;
    } catch (e) {
      print(e.toString());
    }
  }

  clearFilterOnTab() {
    try {
      if (userFilterBody.value.filters?.isNotEmpty ?? false) {
        if (isFilterApply.value) {
          networkRequestModel = NetworkRequestModel(
              role: role,
              favorite: 0,
              filters: RequestFilters(
                  text: textController.value.text.trim() ?? "",
                  isBlocked: false,
                  sort: "",
                  notes: false,
                  params: {}));
          hasNextPage = false;
          getAndResetFilter(isRefresh: false, isFromReset: true);
          tempFilterBody(userFilterBody.value);
          isFilterApply(false);
          isReset(true);
          clearFilterIfNotApply();
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}
}
