import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/exhibitors/controller/exhibitorsController.dart';
import 'package:dreamcast/view/globalSearch/controller/globalSearchTabController.dart';
import 'package:dreamcast/view/skeletonView/gridViewSkeleton.dart';
import 'package:dreamcast/widgets/loadMoreItem.dart';
import 'package:dreamcast/widgets/loading.dart';
import 'package:dreamcast/view/exhibitors/model/exibitorsModel.dart';
import 'package:dreamcast/view/exhibitors/view/bootListBody.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../theme/app_decoration.dart';
import '../../../widgets/toolbarTitle.dart';
import '../../dashboard/showLoadingPage.dart';

class SearchExhibitorPage extends GetView<GlobalSearchTabController> {
  static const routeName = "/AiMatchesBootList";
  SearchExhibitorPage({super.key});

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final textController = TextEditingController().obs;
  final BoothController exhibitorsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: context.width,
        padding: EdgeInsets.symmetric(
            vertical: 14.adaptSize, horizontal: 15.adaptSize),
        child: GetX<GlobalSearchTabController>(builder: (controller) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                        color: colorLightGray,
                        backgroundColor: colorPrimary,
                        strokeWidth: 1.0,
                        key: _refreshIndicatorKey,
                        child: buildChildList(context),
                        onRefresh: () {
                          return Future.delayed(
                            const Duration(seconds: 1),
                            () {
                              refreshListAPi(search: "");
                            },
                          );
                        }),
                  ),
                  controller.isLoadMoreRunning.value
                      ? const LoadMoreLoading()
                      : const SizedBox()
                ],
              ),
              // when the first load function is running
              _progressEmptyWidget()
            ],
          );
        }),
      ),
    );
  }

  refreshListAPi({required String search}) {
    controller.getDataByIndexPage(controller.tabController.index);
  }

  Widget _progressEmptyWidget() {
    return Center(
      child: controller.isLoading.value || exhibitorsController.isLoading.value
          ? const Loading()
          : controller.aiExhibitorsList.isEmpty &&
                  !controller.isFirstLoading.value
              ? ShowLoadingPage(
                  refreshIndicatorKey: _refreshIndicatorKey,
                )
              : const SizedBox(),
    );
  }

  Widget buildChildList(BuildContext context) {
    return Skeletonizer(
        enabled: controller.isFirstLoading.value,
        child: controller.isFirstLoading.value
            ? const BootViewSkeleton()
            : GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: controller.bootScrollController,
                itemCount: controller.aiExhibitorsList.length,
                itemBuilder: (context, index) =>
                    buildChildMenuBody(controller.aiExhibitorsList[index]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 9 / 10,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15)));
  }

  Widget buildChildMenuBody(Exhibitors exhibitors) {
    return GestureDetector(
      onTap: () {
        exhibitorsController.getExhibitorsDetail(exhibitors.id);
      },
      child: BootListBody(
        exhibitor: exhibitors,
        isApiLoading: controller.isFirstLoading.value,
      ),
    );
  }
}

/*
class SearchExhibitorPage extends GetView<BoothController> {
  SearchExhibitorPage({super.key});

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  final controller = Get.put(BoothController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: Colors.transparent,
        width: context.width,
        padding: AppDecoration.userParentPadding(),
        child: GetX<BoothController>(builder: (controller) {
          return Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: RefreshIndicator(
                          color: colorLightGray,
                          backgroundColor: colorPrimary,
                          strokeWidth: 1.0,
                          key: _refreshIndicatorKey,
                          child: buildChildList(context),
                          onRefresh: () {
                            return Future.delayed(
                              const Duration(seconds: 1),
                              () {
                                refreshListAPi(search: "");
                              },
                            );
                          })),
                  controller.isLoadMoreRunning.value
                      ? const LoadMoreLoading()
                      : const SizedBox()
                  // when the _loadMore function is running
                ],
              ),
              // when the first load function is running
              _progressEmptyWidget()
            ],
          );
        }),
      ),
    );
  }

  refreshListAPi({required String search}) {
    controller.getExhibitorsList(isRefresh: true);
  }

  Widget _progressEmptyWidget() {
    return Center(
      child: controller.isLoading.value || controller.isLoading.value
          ? const Loading()
          : controller.exhibitorsList.isEmpty &&
                  !controller.isFirstLoadRunning.value
              ? ShowLoadingPage(
                  refreshIndicatorKey: _refreshIndicatorKey,
                )
              : const SizedBox(),
    );
  }

  Widget buildChildList(BuildContext context) {
    return Skeletonizer(
        enabled: controller.isFirstLoadRunning.value,
        child: controller.isFirstLoadRunning.value
            ? const BootViewSkeleton()
            : GridView.builder(
                controller: controller.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: controller.exhibitorsList.length,
                itemBuilder: (context, index) =>
                    buildChildMenuBody(controller.exhibitorsList[index]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 9 / 10,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15)));
  }

  Widget buildChildMenuBody(Exhibitors exhibitors) {
    return GestureDetector(
      onTap: () async {
        controller.isLoading(true);
        await controller.getExhibitorsDetail(exhibitors.id);
        controller.isLoading(false);
      },
      child: BootListBody(
        isApiLoading: controller.isFirstLoadRunning.value,
        exhibitor: exhibitors,
      ),
    );
  }
}
*/
