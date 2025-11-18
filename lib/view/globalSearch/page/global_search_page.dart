import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/globalSearch/controller/globalSearchTabController.dart';
import 'package:dreamcast/view/globalSearch/page/search_exhibitor_page.dart';
import 'package:dreamcast/view/globalSearch/page/search_session_page.dart';
import 'package:dreamcast/view/globalSearch/page/search_speakers_page.dart';
import 'package:dreamcast/view/globalSearch/page/search_user_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/image_constant.dart';
import '../../../widgets/app_bar/appbar_leading_image.dart';
import '../../../widgets/custom_search_view.dart';

class GlobalSearchPage extends GetView<GlobalSearchTabController> {
  GlobalSearchPage({super.key});
  static const routeName = "/globalSearchPage";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: GetX<GlobalSearchTabController>(
        builder: (controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, right: 15, top: 20),
                child: Row(
                  children: [
                    AppbarLeadingImage(
                      imagePath: ImageConstant.imgArrowLeft,
                      margin: EdgeInsets.only(
                        left: 0.h,
                        top: 3,
                        // bottom: 12.v,
                      ),
                      onTap: () {
                        Get.back();
                      },
                    ),
                    Expanded(
                      child: _buildSearchSection(),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Expanded(
                  child: DefaultTabController(
                initialIndex: controller.selectedTabIndex.value,
                length: controller.tabList.length,
                child: Scaffold(
                  appBar: TabBar(
                    controller: controller.tabController,
                    dividerColor: Colors.transparent,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: List.generate(
                      controller.tabList.length,
                      (index) => Tab(text: controller.tabList[index].label),
                    ),
                  ),
                  body: Obx(
                    () => TabBarView(
                      controller: controller.tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: controller.tabList.map((tab) {
                        switch (tab.value) {
                          case "networking":
                            return SearchUserPage();
                          case "exhibitors":
                            return SearchExhibitorPage();
                          case "speakers":
                            return SearchSpeakerPage();
                          case "sessions":
                            return SearchSessionPage();
                          default:
                            return Center(child: Text("Unknown tab"));
                        }
                      }).toList(),
                    ),
                  ),
                ),
              ))
            ],
          );
        },
      ),
    );
  }

  /// Section Widget
  Widget _buildSearchSection() {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(
        left: 0.h,
        right: 0.h,
      ),
      child: NewCustomSearchView(
        isShowFilter: false,
        hintText: "search_here".tr,
        controller: controller.textController.value,
        onSubmit: (result) {
          controller.textController.refresh();
          if (result.isNotEmpty) {
            FocusManager.instance.primaryFocus?.unfocus();
            controller.getDataByIndexPage(controller.selectedTabIndex.value);
          }
        },
        onClear: (result) {
          controller.textController.refresh();
          FocusManager.instance.primaryFocus?.unfocus();
          controller.getDataByIndexPage(controller.selectedTabIndex.value);
        },
        press: () async {
          controller.textController.refresh();
          FocusManager.instance.primaryFocus?.unfocus();
          controller.getDataByIndexPage(controller.selectedTabIndex.value);
        },
      ),
    );
  }
}
