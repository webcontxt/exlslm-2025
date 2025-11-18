import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/beforeLogin/splash/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/button/common_material_button.dart';

class NoConnectionScreen extends GetView<SplashController> {
  final String title;
  final String message;
  final IconData icon;

  const NoConnectionScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular icon container
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F3F7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/icons/no_internet.png",
                      height: 50,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title text
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Message text
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Try Again button
                Padding(
                  padding:
                      EdgeInsets.only(bottom: 32.v, left: 33.h, right: 33.h),
                  child: CommonMaterialButton(
                    text: "try_again".tr,
                    width: 145.adaptSize,
                    color: colorPrimary,
                    onPressed: () async {
                      if (await controller.isInternetWorking()) {
                        Get.back();
                        controller.initialCall();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Obx(() => controller.loading.value
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
