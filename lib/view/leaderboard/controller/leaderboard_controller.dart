import 'dart:convert';
import 'package:dreamcast/view/leaderboard/model/my_rank_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../model/criteriaModel.dart';
import '../model/leaderboard_team_model.dart';
import '../model/my_criteria_model.dart';

class LeaderboardController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// Controls loading UI visibility
  var loading = false.obs;

  /// Indicates if the first API call is in progress (used for pull-to-refresh or initial load)
  var isFirstLoadRunning = false.obs;

  /// Placeholder for dynamic action names (currently unused in logic)
  var actionName = [];

  /// Tab controller to manage tab selection in the UI
  late TabController _tabController;

  /// List of all criteria available for the leaderboard
  var criteria = <Criteria>[].obs;

  /// List of criteria specific to the current user
  var myCriteria = <Criteria>[].obs;

  /// List of all leaderboard users (except top 3)
  var team = <LeaderboardUsers>[].obs;

  /// List of top 3 users on the leaderboard
  var topThree = <LeaderboardUsers>[].obs;

  /// Total number of users in the team list
  int teamsLength = 0;

  /// Exposes the private tab controller
  TabController get tabController => _tabController;

  /// Keeps track of the currently selected tab index
  final selectedTabIndex = 0.obs;

  /// Fetches overall rank data including top 3 and rest of the team
  Future<void> getRankApi({required bool isRefresh}) async {
    try {
      isFirstLoadRunning(true);
      var response = await apiService.dynamicPostRequest(
          body: {"page_id": 1},
          url: "${AppUrl.baseURLV1}/leaderboard/getRanks");

      LeaderboardTeamModel? model =
          LeaderboardTeamModel.fromJson(json.decode(response));
      isFirstLoadRunning(false);
      if (model!.status! && model!.code == 200) {
        team.clear();
        topThree.clear();
        topThree.addAll(model.body?.top3 ?? []);
        team.addAll(model.body?.users ?? []);
        teamsLength = model.body?.users?.length ?? 0;

        // Fetch user's own rank data after team data
        await getMyRankApi(isRefresh: isRefresh, leaderboardModel: model);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  /// Fetches current user's ranking and inserts it at the top of the team list
  Future<void> getMyRankApi(
      {required bool isRefresh,
      required LeaderboardTeamModel leaderboardModel}) async {
    try {
      var response = await apiService.dynamicPostRequest(
          body: {"page_id": 1},
          url: "${AppUrl.baseURLV1}/leaderboard/getMyRank");

      MyRankModel? model = MyRankModel.fromJson(json.decode(response));
      isFirstLoadRunning(false);

      if (model!.status! && model!.code == 200) {
        if (model.body != null && model.body?.totalPoints != null) {
          print(model.body?.id);
          if (model.body?.id != null) {
            team.insert(0, model.body!); // Insert my rank at top
          }
        }
      }
    } catch (e) {
      isFirstLoadRunning(false);
      print(e.toString());
    } finally {
      isFirstLoadRunning(false); // Ensure loading state is reset
    }
  }

  /// Fetches all criteria used for the leaderboard system
  Future<void> getCriteriaApi({required bool isRefresh}) async {
    try {
      isFirstLoadRunning(true);
      var response = await apiService.dynamicPostRequest(
          body: {"page_id": 1},
          url: "${AppUrl.baseURLV1}/leaderboard/getCriteria");

      CriteriaModel? model = CriteriaModel.fromJson(json.decode(response));
      isFirstLoadRunning(false);

      if (model!.status! && model!.code == 200) {
        criteria.clear();
        criteria.addAll(model?.criteria ?? []);
        criteria.refresh();
      }
    } catch (e) {
      print(e.toString());
    }

    loading(false); // Reset general loading indicator
  }

  /// Fetches criteria data specific to the current user
  Future<void> getMyCriteriaApi({required bool isRefresh}) async {
    try {
      isFirstLoadRunning(true);
      var response = await apiService.dynamicPostRequest(
          body: {"page_id": 1},
          url: "${AppUrl.baseURLV1}/leaderboard/getMyCriteria");

      MyCriteriaModel? model = MyCriteriaModel.fromJson(json.decode(response));
      isFirstLoadRunning(false);

      if (model!.status! && model!.code == 200) {
        myCriteria.clear();
        myCriteria.addAll(model.body ?? []);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Start fetching initial data when controller initializes
    getRankApi(isRefresh: false);

    // Initialize tab controller for 3 tabs
    _tabController = TabController(vsync: this, length: 3);

    // If a tab index is passed via navigation arguments, set the current tab
    if (Get.arguments != null && Get.arguments["tab_index"] != null) {
      _tabController.index = Get.arguments["tab_index"];
      selectedTabIndex.value = Get.arguments["tab_index"];
      loading(true);
    }
  }
}
