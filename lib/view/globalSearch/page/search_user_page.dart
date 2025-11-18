import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/view/representatives/controller/networkingController.dart';
import 'package:dreamcast/view/skeletonView/userBodySkeleton.dart';
import 'package:dreamcast/widgets/loading.dart';
import 'package:dreamcast/view/representatives/controller/user_detail_controller.dart';
import 'package:dreamcast/widgets/userListBody.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../theme/app_decoration.dart';
import '../../../widgets/loadMoreItem.dart';
import '../../../widgets/toolbarTitle.dart';
import '../../dashboard/showLoadingPage.dart';
import '../controller/globalSearchTabController.dart';

class SearchUserPage extends GetView<GlobalSearchTabController> {
  SearchUserPage({super.key});

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GetX<GlobalSearchTabController>(builder: (controller) {
        return Container(
          width: context.width,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: colorLightGray,
                      backgroundColor: colorPrimary,
                      strokeWidth: 1.0,
                      key: _refreshIndicatorKey,
                      onRefresh: () {
                        return Future.delayed(
                          const Duration(seconds: 1),
                          () {
                            refreshListApi(search: "");
                          },
                        );
                      },
                      child: buildChildList(context),
                    ),
                  ),
                  controller.isLoadMoreRunning.value
                      ? const LoadMoreLoading()
                      : const SizedBox()
                ],
              ),
              _progressEmptyWidget()
            ],
          ),
        );
      }),
    );
  }

  refreshListApi({required String search}) {
    controller.getDataByIndexPage(controller.tabController.index);
  }

  Widget _progressEmptyWidget() {
    return Center(
      child: controller.isLoading.value
          ? const Loading()
          : controller.aiUserList.isEmpty && !controller.isFirstLoading.value
              ? ShowLoadingPage(refreshIndicatorKey: _refreshIndicatorKey)
              : const SizedBox(),
    );
  }

  Widget buildChildList(BuildContext context) {
    return Skeletonizer(
        enabled: controller.isFirstLoading.value,
        child: controller.isFirstLoading.value
            ? const UserListSkeleton()
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: controller.userScrollController,
                itemCount: controller.aiUserList.length,
                itemBuilder: (context, index) =>
                    buildChildMenuBody(controller.aiUserList[index]),
              ));
  }

  Widget buildChildMenuBody(dynamic representatives) {
    return UserListWidget(
      isFromBookmark: false,
      isApiLoading: controller.isFirstLoading.value,
      representatives: representatives,
      press: () async {
        controller.isLoading(true);
        await controller.userDetailController
            .getUserDetailApi(representatives.id, representatives.role);
        controller.isLoading(false);
      },
    );
  }
}
