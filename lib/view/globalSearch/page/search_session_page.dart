import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/globalSearch/controller/globalSearchTabController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../theme/app_decoration.dart';
import '../../../widgets/loadMoreItem.dart';
import '../../../widgets/loading.dart';
import '../../../widgets/toolbarTitle.dart';
import '../../dashboard/showLoadingPage.dart';
import '../../schedule/controller/session_controller.dart';
import '../../schedule/view/session_list_body.dart';
import '../../skeletonView/agendaSkeletonList.dart';
import '../../skeletonView/sessionSkeletonList.dart';

class SearchSessionPage extends GetView<GlobalSearchTabController> {
  SearchSessionPage({super.key});

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final SessionController sessionController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 0,
        title: ToolbarTitle(
          title: "myBookmark".tr,
        ),
        backgroundColor: white,
        shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
        elevation: 0,
        iconTheme: IconThemeData(color: colorSecondary),
      ),
      body: GetX<GlobalSearchTabController>(
        builder: (controller) {
          return Container(
            padding: EdgeInsets.symmetric(
                vertical: 14.adaptSize, horizontal: 15.adaptSize),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        key: _refreshIndicatorKey,
                        color: colorLightGray,
                        backgroundColor: colorPrimary,
                        strokeWidth: 1.0,
                        triggerMode: RefreshIndicatorTriggerMode.anywhere,
                        onRefresh: () async {
                          return Future.delayed(
                            const Duration(seconds: 1),
                            () {
                              controller.getDataByIndexPage(
                                  controller.tabController.index);
                            },
                          );
                        },
                        child: buildListView(context),
                      ),
                    ),
                    controller.isLoadMoreRunning.value
                        ? const LoadMoreLoading()
                        : const SizedBox()
                  ],
                ),
                _progressEmptyWidget(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildListView(BuildContext context) {
    return Skeletonizer(
      enabled: controller.isFirstLoading.value,
      child: controller.isFirstLoading.value
          ? const SessionListSkeleton()
          : ListView.separated(
              controller: controller.sessionScrollController,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(
                  height: 0,
                );
              },
              itemCount: controller.aiSessionList.length,
              itemBuilder: (context, index) {
                return SessionListBody(
                  isFromBookmark: false,
                  session: controller.aiSessionList[index],
                  index: index,
                  size: controller.aiSessionList.length,
                );
              },
            ),
    );
  }

  Widget _progressEmptyWidget() {
    return Center(
      child: controller.isLoading.value || sessionController.loading.value
          ? const Loading()
          : controller.aiSessionList.isEmpty && !controller.isFirstLoading.value
              ? ShowLoadingPage(refreshIndicatorKey: _refreshIndicatorKey)
              : const SizedBox(),
    );
  }
}

/*
class SearchSessionPage extends GetView<GlobalSearchTabController> {
  SearchSessionPage({super.key});

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GetX<GlobalSearchTabController>(
        builder: (controller) {
          return Container(
              padding: AppDecoration.userParentPadding(),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          key: _refreshIndicatorKey,
                          color: colorLightGray,
                          backgroundColor: colorPrimary,
                          strokeWidth: 1.0,
                          triggerMode: RefreshIndicatorTriggerMode.anywhere,
                          onRefresh: () async {
                            return Future.delayed(
                              const Duration(seconds: 1),
                              () {
                                controller.getSessionList(isRefresh: true);
                              },
                            );
                          },
                          child: buildListView(context),
                        ),
                      ),
                      controller.isLoadMoreRunning.value
                          ? const LoadMoreLoading()
                          : const SizedBox()
                      // when the _loadMore function is running
                    ],
                  ),
                  _progressEmptyWidget(),
                ],
              ));
        },
      ),
    );
  }

  Widget buildListView(BuildContext context) {
    return Skeletonizer(
      enabled: controller.isFirstLoading.value,
      child: controller.isFirstLoading.value
          ? const ListAgendaSkeleton()
          : ListView.separated(
              controller: controller.scrollController,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(
                  height: 0,
                );
              },
              itemCount: controller.sessionList.length,
              itemBuilder: (context, index) {
                return SessionListBody(
                  isFromBookmark: false,
                  apiLoading: controller.isFirstLoading.value,
                  session: controller.sessionList[index],
                  index: index,
                  size: controller.sessionList.length,
                );
              },
            ),
    );
  }

  Widget _progressEmptyWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: controller.loading.value
          ? const Loading()
          : !controller.isFirstLoading.value && controller.sessionList.isEmpty
              ? ShowLoadingPage(
                  refreshIndicatorKey: controller.refreshIndicatorKey,
                  message: "no_data_found_description".tr,
                )
              : const SizedBox(),
    );
  }
}
*/
