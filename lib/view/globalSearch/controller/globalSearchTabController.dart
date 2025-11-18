import 'dart:convert';
import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/view/exhibitors/controller/exhibitorsController.dart';
import 'package:dreamcast/view/schedule/controller/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../api_repository/api_service.dart';
import '../../../../api_repository/app_url.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../beforeLogin/splash/model/config_model.dart';
import '../../exhibitors/model/exibitorsModel.dart';
import '../../representatives/controller/user_detail_controller.dart';
import '../../representatives/model/user_model.dart';
import '../../schedule/model/scheduleModel.dart';
import '../../schedule/model/speaker_webinar_model.dart';
import '../../speakers/controller/speakersController.dart';

class GlobalSearchTabController extends GetxController
    with GetTickerProviderStateMixin {
  final AuthenticationManager authManager = Get.find();
  final SessionController sessionController = Get.find();
  final textController = TextEditingController().obs;

  // Data lists
  var aiUserList = <dynamic>[].obs;
  var aiSpeakerList = <dynamic>[].obs;
  var aiExhibitorsList = <Exhibitors>[].obs;
  var aiSessionList = <dynamic>[].obs;

  // Scroll controllers
  final userScrollController = ScrollController();
  final speakerScrollController = ScrollController();
  final bootScrollController = ScrollController();
  final sessionScrollController = ScrollController();
  final tabScrollController = ScrollController();

  final selectedDayIndex = 0.obs;
  // Loading states
  var isFirstLoading = false.obs;
  var isLoading = false.obs;
  var isLoadMoreRunning = false.obs;

  // Pagination
  late bool hasNextPage;
  int _pageNumber = 1;

  // Dynamic tabs from API
  var tabList = <Tabs>[].obs;
  late TabController _tabController;
  TabController get tabController => _tabController;

  var selectedTabIndex = 0.obs;

  // Other controllers
  final UserDetailController userDetailController = Get.find();
  final SpeakersDetailController speakersController =
      Get.put(SpeakersDetailController());
  final BoothController bootController = Get.put(BoothController());

  final String title = 'Home Title';

  @override
  void onInit() {
    super.onInit();
    loadTabsFromApi();
  }

  void loadTabsFromApi() {
    tabList.value = [
      Tabs(label: "exhibitors".tr, value: "exhibitors"),
      Tabs(label: "Networking", value: "networking"),
      Tabs(label: "Speakers".tr, value: "speakers"),
      Tabs(label: "Sessions".tr, value: "sessions"),
    ];

    _tabController = TabController(length: tabList.length, vsync: this)
      ..addListener(_handleTabChange)
      ..index = selectedTabIndex.value;

    getDataByIndexPage(selectedTabIndex.value);
  }

  int getCurrentIndex() => _tabController.index;

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      selectedTabIndex(newIndex);
      getDataByIndexPage(newIndex);
    }
  }

  /// Calls API based on selected tab
  void getDataByIndexPage(int index) {
    final slug = tabList[index].value ?? "";
    final text = textController.value.text.trim();

    final body = {
      "page": "1",
      "filters": {"text": text}
    };
    switch (slug) {
      case "networking":
        getAiMatchesUser({
          ...body,
          "role": MyConstant.networking,
          "favourite": 0,
        });
        break;
      case "exhibitors":
        getAiExhibitorsList({
          ...body,
          "favourite": 0,
          "featured": 0,
          "filters": {
            "sort": "",
            "text": text,
            "notes": false,
            "params": {
              "exhibitor_type": [""]
            }
          },
        });
        break;

      case "speakers":
        getAiMatchesSpeaker({
          ...body,
          "role": "speaker",
          "favourite": 0,
          "filters": {
            "text": text,
            "sort": "",
            "is_blocked": false,
            "notes": false,
            "params": {}
          }
        });
        break;
      case "sessions":
        getAiSessionList({
          "page": "1",
          "favourite": 0,
          "filters": {
            "params": {"date": "all"},
            "text": text,
          }
        });
        break;
    }
  }

  // ------------------ COMMON PAGINATION HANDLER ------------------

  Future<void> _paginate<T>({
    required ScrollController controller,
    required Future<T> Function(dynamic body) apiCall,
    required dynamic body,
    required void Function(T model) onSuccess,
  }) async {
    controller.addListener(() async {
      if (hasNextPage &&
          !isFirstLoading.value &&
          !isLoadMoreRunning.value &&
          controller.position.pixels == controller.position.maxScrollExtent) {
        isLoadMoreRunning(true);
        body["page"] = _pageNumber;

        try {
          final model = await apiCall(body);
          onSuccess(model);
        } catch (e) {
          debugPrint("Pagination error: $e");
        } finally {
          isLoadMoreRunning(false);
        }
      }
    });
  }

  // ------------------ USERS ------------------

  Future<void> getAiMatchesUser(dynamic body) async {
    if (!authManager.isLogin()) return;

    isFirstLoading(true);
    _pageNumber = 1;

    try {
      final response = await apiService.dynamicPostRequest(
        body: body,
        url: "${AppUrl.usersListApi}/search",
      );
      final model = RepresentativeModel.fromJson(json.decode(response));

      if (model.status == true && model.code == 200) {
        aiUserList.assignAll(model.body?.representatives ?? []);
        userDetailController
          ..clearDefaultList()
          ..userIdsList.assignAll(aiUserList.map((e) => e.id));

        hasNextPage = model.body?.hasNextPage ?? false;
        _pageNumber++;
        userDetailController.getBookmarkAndRecommendedByIds();
        if (hasNextPage) {
          _paginate<RepresentativeModel>(
            controller: userScrollController,
            apiCall: (req) async {
              final res = await apiService.dynamicPostRequest(
                body: req,
                url: "${AppUrl.usersListApi}/search",
              );
              return RepresentativeModel.fromJson(json.decode(res));
            },
            body: body,
            onSuccess: (model) {
              hasNextPage = model.body?.hasNextPage ?? false;
              _pageNumber++;
              aiUserList.addAll(model.body?.representatives ?? []);
              userDetailController.userIdsList
                  .addAll(model.body?.representatives?.map((e) => e.id) ?? []);
              userDetailController.getBookmarkAndRecommendedByIds();
            },
          );
        }
      }
    } finally {
      isFirstLoading(false);
    }
  }

  // ------------------ SPEAKERS ------------------

  Future<void> getAiMatchesSpeaker(dynamic body) async {
    if (!authManager.isLogin()) return;

    isFirstLoading(true);
    _pageNumber = 1;

    try {
      final response = await apiService.dynamicPostRequest(
        body: body,
        url: "${AppUrl.usersListApi}/search",
      );
      final model = RepresentativeModel.fromJson(json.decode(response));

      if (model.status == true && model.code == 200) {
        aiSpeakerList.assignAll(model.body?.representatives ?? []);
        speakersController
          ..clearDefaultList()
          ..userIdsList.assignAll(aiSpeakerList.map((e) => e.id));

        hasNextPage = model.body?.hasNextPage ?? false;
        _pageNumber++;
        //speakersController.getBookmarkAndRecommendedByIds();

        if (hasNextPage) {
          _paginate<RepresentativeModel>(
            controller: speakerScrollController,
            apiCall: (req) async {
              final res = await apiService.dynamicPostRequest(
                body: req,
                url: "${AppUrl.usersListApi}/aiSearch",
              );
              return RepresentativeModel.fromJson(json.decode(res));
            },
            body: body,
            onSuccess: (model) {
              hasNextPage = model.body?.hasNextPage ?? false;
              _pageNumber++;
              aiSpeakerList.addAll(model.body?.representatives ?? []);
              speakersController.userIdsList
                  .addAll(model.body?.representatives?.map((e) => e.id) ?? []);
              speakersController.getBookmarkAndRecommendedByIds();
            },
          );
        }
      }
    } finally {
      isFirstLoading(false);
    }
  }

  // ------------------ EXHIBITORS ------------------

  Future<void> getAiExhibitorsList(dynamic body) async {
    if (!authManager.isLogin()) return;

    isFirstLoading(true);
    _pageNumber = 1;

    try {
      final response = await apiService.dynamicPostRequest(
        url: "${AppUrl.exhibitorsListApi}/search",
        body: body,
      );
      final model = ExhibitorsModel.fromJson(json.decode(response));

      if (model.status == true && model.code == 200) {
        aiExhibitorsList.assignAll(model.body?.exhibitors ?? []);
        bootController.userIdsList.assignAll(aiExhibitorsList.map((e) => e.id));

        hasNextPage = model.body?.hasNextPage ?? false;
        _pageNumber++;
        bootController.getBookmarkAndRecommendedByIds();

        if (hasNextPage) {
          _paginate<ExhibitorsModel>(
            controller: bootScrollController,
            apiCall: (req) async {
              final res = await apiService.dynamicPostRequest(
                url: "${AppUrl.exhibitorsListApi}/search",
                body: req,
              );
              return ExhibitorsModel.fromJson(json.decode(res));
            },
            body: body,
            onSuccess: (model) {
              hasNextPage = model.body?.hasNextPage ?? false;
              _pageNumber++;
              aiExhibitorsList.addAll(model.body?.exhibitors ?? []);
              bootController.userIdsList
                  .addAll(model.body?.exhibitors?.map((e) => e.id) ?? []);
              bootController.getBookmarkAndRecommendedByIds();
            },
          );
        }
      }
    } finally {
      isFirstLoading(false);
    }
  }

  // ------------------ SESSIONS ------------------

  Future<void> getAiSessionList(dynamic body) async {
    if (!authManager.isLogin()) return;

    isFirstLoading(true);
    _pageNumber = 1;

    try {
      final response = await apiService.dynamicPostRequest(
        body: body,
        url: AppUrl.getSession,
      );
      final model = ScheduleModel.fromJson(json.decode(response));

      if (model.status == true && model.code == 200) {
        aiSessionList.assignAll(model.body?.sessions ?? []);
        sessionController.userIdsList.assignAll(aiSessionList.map((e) => e.id));

        hasNextPage = model.body?.hasNextPage ?? false;
        _pageNumber++;
        sessionController.getBookmarkIds();

        if (authManager.isLogin()) {
          getSpeakerWebinarList();
        }

        if (hasNextPage) {
          _paginate<ScheduleModel>(
            controller: sessionScrollController,
            apiCall: (req) async {
              final res = await apiService.dynamicPostRequest(
                body: req,
                url: AppUrl.getSession,
              );
              return ScheduleModel.fromJson(json.decode(res));
            },
            body: body,
            onSuccess: (model) {
              hasNextPage = model.body?.hasNextPage ?? false;
              _pageNumber++;
              aiSessionList.addAll(model.body?.sessions ?? []);
              sessionController.userIdsList
                  .addAll(model.body?.sessions?.map((e) => e.id) ?? []);
              sessionController.getBookmarkIds();
            },
          );
        }
      }
    } finally {
      isFirstLoading(false);
    }
  }

  // ------------------ SPEAKER-WEBINAR ------------------

  Future<void> getSpeakerWebinarList() async {
    if (sessionController.userIdsList.isEmpty) return;

    final response = await apiService.dynamicPostRequest(
      body: {"webinars": sessionController.userIdsList},
      url: AppUrl.getSpeakerByWebinarId,
    );
    final model = SpeakerModelWebinarModel.fromJson(json.decode(response));

    if (model.status == true && model.code == 200) {
      for (var session in aiSessionList) {
        final matching =
            model.body?.firstWhereOrNull((s) => s.id == session.id);
        if (matching != null) {
          session.speakers?.clear();
          session.speakers?.addAll(matching.sessionSpeaker ?? []);
        }
      }
      aiSessionList.refresh();
    }
  }
}
