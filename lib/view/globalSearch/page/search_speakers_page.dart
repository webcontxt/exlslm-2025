import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/view/skeletonView/userBodySkeleton.dart';
import 'package:dreamcast/view/speakers/controller/speakerNetworkController.dart';
import 'package:dreamcast/view/speakers/controller/speakersController.dart';
import 'package:dreamcast/widgets/loading.dart';
import 'package:dreamcast/view/representatives/controller/user_detail_controller.dart';
import 'package:dreamcast/widgets/userListBody.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../theme/app_decoration.dart';
import '../../../widgets/loadMoreItem.dart';
import '../../dashboard/showLoadingPage.dart';
import '../../skeletonView/speakerBodySkeleton.dart';
import '../../speakers/view/speakerListBody.dart';
import '../controller/globalSearchTabController.dart';

class SearchSpeakerPage extends GetView<GlobalSearchTabController> {
  static const routeName = "/AiMatchesListPage";
  SearchSpeakerPage({Key? key}) : super(key: key);

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  final SpeakersDetailController userController =
  Get.put(SpeakersDetailController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GetX<GlobalSearchTabController>(builder: (controller) {
        return Container(
          color: Colors.transparent,
          width: context.width,
          padding: AppDecoration.commonVerticalPadding(),
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
                      child: buildListview(context),
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
          : controller.aiSpeakerList.isEmpty && !controller.isFirstLoading.value
          ? ShowLoadingPage(refreshIndicatorKey: _refreshIndicatorKey)
          : const SizedBox(),
    );
  }

  Widget buildListview(BuildContext context) {
    return Skeletonizer(
        enabled: controller.isFirstLoading.value,
        child: controller.isFirstLoading.value
            ? const SpeakerListSkeleton()
            : ListView.builder(
          controller: controller.speakerScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: controller.aiSpeakerList.length,
          itemBuilder: (context, index) => controller.isFirstLoading.value
              ? const SpeakerListSkeleton()
              : buildListBody(controller.aiSpeakerList[index]),
        ));
  }

  Widget buildListBody(dynamic representatives) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14),
      child: InkWell(
        onTap: () async {
          controller.isLoading(true);
          await userController.getSpeakerDetail(
              speakerId: representatives.id,
              role: representatives.role,
              isSessionSpeaker: false);
          controller.isLoading(false);
        },
        child: SpeakerViewWidget(
            isApiLoading: controller.isFirstLoading.value,
            speakerData: representatives,
            isSpeakerType: false),
      ),
    );
  }
}
