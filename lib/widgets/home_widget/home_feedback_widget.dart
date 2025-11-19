import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/beforeLogin/globalController/authentication_manager.dart';
import 'package:dreamcast/view/dashboard/dashboard_controller.dart';
import 'package:dreamcast/view/home/controller/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../routes/my_constant.dart';
import '../../theme/app_colors.dart';
import '../../utils/dialog_constant.dart';
import '../../view/quiz/view/feedback_page.dart';
import '../../view/support/view/helpdeskDashboard.dart';
import '../button/custom_outlined_button.dart';
import 'package:flutter/material.dart';

class HomeFeedbackWidget extends GetView<HomeController> {
  HomeFeedbackWidget({super.key});
  final AuthenticationManager _manager = Get.find();
  final DashboardController _dashboardController = Get.find();
  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
      padding: const EdgeInsets.only(top: 35),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: controller.menuFooterHome.length > 1
              ? 2
              : 1, // Two buttons per row
          crossAxisSpacing: 10,
          mainAxisSpacing: 0,
          childAspectRatio: controller.menuFooterHome.length > 1
              ? 4
              : 7, // Adjust height/width ratio as needed
        ),
        shrinkWrap: true,
        itemCount: controller.menuFooterHome.length,
        itemBuilder: (context, index) {
          final menuItem = controller.menuFooterHome[index];
          return CustomOutlinedButton(
            buttonStyle: OutlinedButton.styleFrom(
              side: BorderSide(color: colorPrimary, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            buttonTextStyle: TextStyle(
              color: colorPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 16.fSize,
            ),
            onPressed: () {
              print("Button pressed: ${menuItem.slug}");
              // Handle button press based on menuItem
              if (menuItem.slug == 'event_feedback') {
                if (!_manager.isLogin()) {
                  DialogConstantHelper.showLoginDialog(
                      Get.context!, _manager);
                  return;
                }

                Get.toNamed(FeedbackPage.routeName,
                    arguments: {MyConstant.titleKey: "feedback".tr});
              } else if (menuItem.slug == 'helpdesk') {
                _dashboardController.changeTabIndex(3);
              }
              // Add more conditions as needed for other menu items
            },
            text: menuItem.label ??
                "", // Assuming menuItem is a String key in your localization
          );
        },
      ),
    ));
  }
}
