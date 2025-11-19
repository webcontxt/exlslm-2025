import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/widgets/loadMoreItem.dart';
import 'package:dreamcast/widgets/loading.dart';
import 'package:dreamcast/view/eventFeed/controller/eventFeedController.dart';
import 'package:dreamcast/view/eventFeed/view/upload_post_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../routes/my_constant.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/image_constant.dart';
import '../../../utils/pref_utils.dart';
import '../../../widgets/app_bar/appbar_leading_image.dart';
import '../../../widgets/app_bar/custom_app_bar.dart';
import '../../../widgets/event_feed_widget.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../../widgets/textview/customTextView.dart';
import '../../../widgets/toolbarTitle.dart';
import '../../dashboard/showLoadingPage.dart';

class SocialFeedListPage extends GetView<EventFeedController> {
  static const routeName = "/SocialFeedListPage";

  SocialFeedListPage({Key? key, required this.isFromLaunchpad})
      : super(key: key);
  final AuthenticationManager authenticationManager = Get.find();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  int currentSec = 5;
  var isFromLaunchpad = false;

  var showPopup = false.obs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            height: 72.v,
            leadingWidth: 45.h,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.v),
                child: GestureDetector(
                  onTap: () {
                    showPopup(!showPopup.value);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorGray, width: 1),
                      color: showPopup.value ? white : Colors.transparent,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/svg/ic_sort.svg",
                          width: 11,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Obx(() {
                          return CustomTextView(
                            text: controller.sortList[controller.sortValue.value].text ?? "",
                            color: colorSecondary,
                            fontWeight: FontWeight.normal,
                            fontSize: 14.fSize,
                          );
                        })
                      ],
                    ),
                  ),
                ),
              )
            ],
            title: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ToolbarTitle(
                  title: Get.arguments?[MyConstant.titleKey] ?? "Image wall"),
            ),
            backgroundColor: white,
            // dividerHeight: 0,
          ),
          body: SizedBox(
            height: context.height,
            width: context.width,
            child: GetX<EventFeedController>(
              builder: (controller) {
                return Column(
                  children: [
                    buildHeader(),
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  triggerMode:
                                      RefreshIndicatorTriggerMode.anywhere,
                                  color: colorLightGray,
                                  backgroundColor: colorPrimary,
                                  strokeWidth: 1.0,
                                  key: _refreshIndicatorKey,
                                  onRefresh: () {
                                    return Future.delayed(
                                      const Duration(seconds: 1),
                                      () async {
                                        controller.getEventFeed(
                                            isLimited: false);
                                      },
                                    );
                                  },
                                  child: EventFeedWidgetDynamic(
                                    isFromLaunchpad: isFromLaunchpad,
                                  ),
                                ),
                              ),
                              // when the _loadMore function is running
                              controller.isLoadMoreRunning.value
                                  ? const LoadMoreLoading()
                                  : const SizedBox()
                            ],
                          ),
                          _progressEmptyWidget()
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          resizeToAvoidBottomInset: true,
        ),
        Obx(() {
          return showPopup.value
              ? Positioned(
                  width: 172.adaptSize,
                  top: 55.adaptSize,
                  right: 10,
                  child: buildAlertPopup(context),
                )
              : const SizedBox();
        }),
      ],
    );
  }

  Widget buildAlertPopup(BuildContext context) {
    return SizedBox(
      width: 132.adaptSize,
      child: Card(
          color: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: colorGray, width: 1),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                controller.sortList.length,
                (index) {
                  return InkWell(
                    onTap: () {
                      controller.sortValue.value = index;
                      showPopup(false);
                      controller.getEventFeed(isLimited: false);
                    },
                    child: Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: CustomTextView(
                        text: controller.sortList[index].text ?? "",
                        fontWeight: FontWeight.w600,
                        color: controller.sortValue.value == index
                            ? colorSecondary
                            : colorGray,
                        fontSize: 14,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  );
                },
              ),
            ),
          )),
    );
  }

  Widget _progressEmptyWidget() {
    return Center(
      child: controller.loading.value
          ? const Loading()
          : !controller.isFirstLoadRunning.value &&
                  controller.feedDataList.isEmpty
              ? ShowLoadingPage(refreshIndicatorKey: _refreshIndicatorKey)
              : const SizedBox(),
    );
  }

  buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// old codition
          // authenticationManager.getUserId() !=
          //     authenticationManager.getFeedEmail()
          true
              ? InkWell(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: circularImage(
                            shortName: PrefUtils.getUsername(),
                            url: PrefUtils.getImage()),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                          width: 1, height: 30, color: const Color(0xffDCDCDD)),
                      const SizedBox(
                        width: 8,
                      ),
                      Flexible(
                          child: CustomTextView(
                        text: "want_to_talk_about".tr,
                        fontSize: 16,
                        maxLines: 2,
                        fontWeight: FontWeight.normal,
                        color: colorGray,
                        textAlign: TextAlign.start,
                      ))
                    ],
                  ),
                  onTap: () async {
                    controller.isFilePicked(false);
                    controller.mediaPath("");
                    controller.mediaType("");
                    controller.recordAudio(false);

                    if (controller.feedDataList.isNotEmpty) {
                      controller.feedDataList[controller.lastIndexPlay]
                          .isPlayVideo = false;
                      controller.feedDataList.refresh();
                    }
                    var result = await Get.bottomSheet(
                      UploadPostPage(),
                      enableDrag: true,
                      barrierColor: widgetBackgroundColor.withOpacity(0.90),
                      isDismissible: false,
                      isScrollControlled: true,
                    );
                    if (result == true) {
                      controller.getEventFeed(isLimited: false);
                    }
                  },
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  circularImage({url, shortName, color}) {
    return url.toString().isNotEmpty && url != null
        ? SizedBox(
            height: 45,
            width: 45,
            child: CircleAvatar(backgroundImage: NetworkImage(url)))
        : Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorSecondary,
            ),
            child: Center(
                child: CustomTextView(
              text: shortName ?? "",
              color: Colors.white,
              textAlign: TextAlign.center,
            )),
          );
  }
}
