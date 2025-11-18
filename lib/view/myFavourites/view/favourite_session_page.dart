import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/myFavourites/controller/favourite_session_controller.dart';
import 'package:dreamcast/view/skeletonView/sessionSkeletonList.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../widgets/loadMoreItem.dart';
import '../../../widgets/loading.dart';
import '../../../widgets/toolbarTitle.dart';
import '../../dashboard/showLoadingPage.dart';
import '../../schedule/controller/session_controller.dart';
import '../../schedule/view/session_list_body.dart';
import '../../skeletonView/agendaSkeletonList.dart';

class FavouriteSessionPage extends StatelessWidget {
  final String controllerTag;
  FavouriteSessionPage({super.key, required this.controllerTag});

  static const routeName = "/MySessionList";
  final SessionController sessionController = Get.find();

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    final favController = Get.find<FavSessionController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 0,
        title: ToolbarTitle(title: "myBookmark".tr),
        backgroundColor: white,
        shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
        elevation: 0,
        iconTheme: IconThemeData(color: colorSecondary),
      ),
      body: GetX<FavSessionController>(
        //tag: controllerTag, // 👈 IMPORTANT
        builder: (controller) {
          return Container(
            padding:
                EdgeInsets.symmetric(vertical: 10, horizontal: 18.adaptSize),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        key: refreshIndicatorKey,
                        color: colorLightGray,
                        backgroundColor: colorPrimary,
                        strokeWidth: 1.0,
                        triggerMode: RefreshIndicatorTriggerMode.anywhere,
                        onRefresh: () async {
                          return Future.delayed(
                            const Duration(seconds: 1),
                            () {
                              controller.getBookmarkSession(isRefresh: true);
                            },
                          );
                        },
                        child: buildListView(
                            context, favController, controllerTag),
                      ),
                    ),
                    controller.isLoadMoreRunning.value
                        ? const LoadMoreLoading()
                        : const SizedBox()
                  ],
                ),
                _progressEmptyWidget(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildListView(
      BuildContext context, FavSessionController favController, String tag) {
    return Skeletonizer(
      enabled: favController.isFirstLoading.value,
      child: favController.isFirstLoading.value
          ? const SessionListSkeleton()
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              key: PageStorageKey(tag), // keeps independent scroll position
              controller: favController.scrollController,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemCount: favController.favouriteSessionList.length,
              itemBuilder: (context, index) {
                return SessionListBody(
                  isFromBookmark: false,
                  session: favController.favouriteSessionList[index],
                  index: index,
                  size: favController.favouriteSessionList.length,
                );
              },
            ),
    );
  }

  Widget _progressEmptyWidget(FavSessionController controller) {
    return Center(
      child: controller.loading.value || sessionController.loading.value
          ? const Loading()
          : controller.favouriteSessionList.isEmpty &&
                  !controller.isFirstLoading.value
              ? ShowLoadingPage(refreshIndicatorKey: refreshIndicatorKey)
              : const SizedBox(),
    );
  }
}
