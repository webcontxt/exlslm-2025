import 'package:dreamcast/theme/controller/theme_controller.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/widgets/toolbarTitle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../utils/image_constant.dart';
import 'app_bar/appbar_leading_image.dart';
import 'app_bar/custom_app_bar.dart';

class ThemeSettingsPage extends GetView<ThemeController> {
  ThemeSettingsPage({super.key});

  final List<String> fonts = ['FigTree', 'FigTree'];

  final String sampleText =
      'This is a preview of the font size.\nयह फ़ॉन्ट साइज का पूर्वावलोकन है।';

  final Map<int, String> fontSizeLabels = {
    0: 'Small',
    1: 'Normal',
    2: 'Large',
    3: 'Extra Large',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        height: 72.v,
        leadingWidth: 45.h,
        leading: AppbarLeadingImage(
          imagePath: ImageConstant.imgArrowLeft,
          margin: EdgeInsets.only(left: 7.h, top: 3),
          onTap: () => Get.back(),
        ),
        title: const ToolbarTitle(title: "Font Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 32),
          // Sample Preview Text
          Center(
            child: Obx(() => Text(
                  sampleText,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: controller.getFontSize(16),
                  ),
                )),
          ),
          const SizedBox(height: 24),
          Text('Font Size',
              style: TextStyle(fontSize: controller.getFontSize(16))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.text_fields, size: 18), // Small icon
              Expanded(
                child: Obx(() => SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        valueIndicatorTextStyle:
                            const TextStyle(color: Colors.white),
                      ),
                      child: Slider(
                        value: controller.sliderValue.value,
                        min: 0,
                        max: 3,
                        divisions: 3,
                        inactiveColor: Colors.grey,
                        thumbColor: Colors.black,
                        label: fontSizeLabels[controller.sliderValue.toInt()],
                        onChanged: (value) {
                          controller.sliderValue.value = value;
                          print("Slider Value: ${value.toInt()}");
                          controller.changeFontSize(
                            AppFontSizeOption
                                .values[controller.sliderValue.toInt()],
                          );
                        },
                      ),
                    )),
              ),
              const Icon(Icons.text_fields, size: 28), // Large icon
            ],
          ),
        ],
      ),
    );
  }
}
