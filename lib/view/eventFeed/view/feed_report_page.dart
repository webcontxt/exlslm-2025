import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/pref_utils.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:dreamcast/view/eventFeed/controller/eventFeedController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/ui_helper.dart';
import '../../../widgets/loading.dart';
import '../../../widgets/button/common_material_button.dart';
import '../../../widgets/toolbarTitle.dart';

class FeedReportPage extends GetView<EventFeedController> {
  String eventFeedId = "";
  String? feedCommentId = "";
  bool isReportPost;
  FeedReportPage(
      {Key? key,
        required this.eventFeedId,
        this.feedCommentId,
        required this.isReportPost})
      : super(key: key);
  static const routeName = "/FeedbackPage";
  final TextEditingController textAreaController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: ToolbarTitle(
          title: "report_on_Feed".tr,
          color: Colors.black,
        ),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
        backgroundColor: white,
        iconTheme: IconThemeData(color: colorSecondary),
      ),
      body: Container(
          padding: const EdgeInsets.all(10),
          child: GetX<EventFeedController>(builder: (controller) {
            return Stack(
              children: [
                Column(
                  children: [
                    buildSelectionWidget(),
                    controller.selectedReportOption.value ==
                        controller.commentResign.length - 1
                        ? textArea()
                        : const SizedBox(),
                    CommonMaterialButton(
                      text: 'Submit',
                      width: 160,
                      onPressed: () async {
                        String reason;
                        // Check if last option selected
                        bool isCustomReason =
                            controller.commentResign.length - 1 == controller.selectedReportOption.value;
                        // Validate custom text
                        if (isCustomReason) {
                          if (textAreaController.text.trim().isEmpty) {
                            UiHelper.showFailureMsg(null, "enter_description".tr);
                            return;
                          }
                          reason = textAreaController.text.trim();
                        } else {
                          reason = controller.commentResign[controller.selectedReportOption.value];
                        }
                        // Call correct API
                        if (isReportPost) {
                          controller.reportPostApi(
                            requestBody: {
                              "feed_id": eventFeedId,
                              "reason": reason,
                            },
                          );
                        } else {
                          controller.reportCommentApi(
                            requestBody: {
                              "feed_id": eventFeedId,
                              "feed_comment_id": feedCommentId,
                              "reason": reason,
                            },
                          );
                        }
                        Get.back();
                      },
                    )
                  ],
                ),
                controller.loading.value ? const Loading() : const SizedBox()
              ],
            );
          })),
    );
  }

  buildSelectionWidget() {
    return Expanded(
        child: ListView.builder(
            controller: _scrollController,
            itemCount: controller.commentResign.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  controller.selectedReportOption(index);
                  // Only scroll if last item is selected
                  if (index == controller.commentResign.length - 1) {
                    // Wait until frame is rebuilt
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      scrollToBottom();
                    });
                  }
                },
                child: ListTile(
                    title: CustomTextView(
                      fontWeight: FontWeight.normal,
                      text: controller.commentResign[index],
                      fontSize: 18,
                      maxLines: 2,
                      textAlign: TextAlign.start,
                    ),
                    trailing: Obx(() => Icon(
                      color: Colors.black,
                      controller.selectedReportOption.value != -1 &&
                          controller.selectedReportOption.value == index
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ))),
              );
            }));
  }

  textArea() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "enter_description_about_post".tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      subtitle: TextFormField(
        textInputAction: TextInputAction.done,
        controller: textAreaController,
        validator: (String? value) {
          if (value!.trim().isEmpty || value.trim() == null) {
            return "enter_description".tr;
          }
          return null;
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          //labelText: "${createFieldBody.label}",
          hintText: "",
          labelStyle: TextStyle(color: colorSecondary),
          fillColor: Colors.transparent,
          filled: true,
          prefixIconConstraints: const BoxConstraints(minWidth: 60),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorSecondary)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black)),
        ),
        minLines: 6,
        maxLines: 12,
      ),
    );
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }
}
