import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/beforeLogin/globalController/authentication_manager.dart';
import 'package:dreamcast/view/commonController/controller/common_chat_meeting_controller.dart';
import 'package:dreamcast/view/meeting/model/timeslot_model.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../theme/app_decoration.dart';
import '../../../utils/image_constant.dart';
import '../../../utils/pref_utils.dart';
import '../../../widgets/app_bar/appbar_leading_image.dart';
import '../../../widgets/app_bar/custom_app_bar.dart';
import '../../../widgets/customImageWidget.dart';
import '../../../widgets/button/custom_icon_button.dart';
import '../../../widgets/toolbarTitle.dart';

class CommonScheduleMeetingDialog extends GetView<CommonChatMeetingController> {
  String personName, profileImg, shortName, duration;
  CommonScheduleMeetingDialog(
      {super.key,
      required this.personName,
      required this.profileImg,
      required this.shortName,
      required this.duration});
  static const routeName = "/BookAppointmentPage";

  final textFieldController = TextEditingController(text: "select_date".tr);
  final notesFieldController = TextEditingController(text: "");

  final AuthenticationManager _authController = Get.find();
  final _selectedDate = 0.obs;
  final _selectedSlot = (-1).obs;
  var showPopup = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: CustomAppBar(
        height: 72.v,
        leadingWidth: 45.h,
        leading: AppbarLeadingImage(
          imagePath: ImageConstant.imgArrowLeft,
          margin: EdgeInsets.only(
            left: 7.h,
            top: 3,
            // bottom: 12.v,
          ),
          onTap: () {
            Get.back();
          },
        ),
        title: ToolbarTitle(title: "schedule_one_two_one".tr),
        backgroundColor: colorLightGray,
        dividerHeight: 0,
      ),
      body: Container(
          height: context.height,
          width: context.width,
          margin: EdgeInsets.zero,
          decoration: AppDecoration.roundedBoxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          child: GetX<CommonChatMeetingController>(builder: (controller) {
            return SingleChildScrollView(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildUserInfo(context),
                      Divider(
                        height: 6.v,
                        color: borderColor,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      CustomTextView(
                        text: "want_to_book_meeting".tr,
                        fontSize: 18,
                        color: colorSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      buildDateView(context),
                      Divider(
                        height: 24,
                        color: borderColor,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      CustomTextView(
                        text: "select_time_for_day".tr,
                        fontSize: 18,
                        color: colorSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      controller.slots.isNotEmpty
                          ? buildSlotsListView(context)
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CustomTextView(
                                text: "no_clot_available_this_time".tr,
                                textAlign: TextAlign.start,
                              ),
                            ),
                      Divider(
                        height: 24,
                        color: borderColor,
                      ),
                      buildNotesWidget(),
                      const SizedBox(
                        height: 24,
                      ),
                      controller.slots.isNotEmpty
                          ? CustomIconButton(
                              height: 55,
                              width: context.width,
                              decoration: BoxDecoration(
                                color: _selectedSlot.value == -1
                                    ? colorPrimary.withOpacity(0.5)
                                    : colorPrimary, // Background color
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                              ),
                              onTap: () async {
                                FocusScope.of(context).unfocus();
                                if (_selectedSlot.value == -1) {
                                  UiHelper.showFailureMsg(
                                      context, "Please select time slot");
                                  return;
                                }
                                var body = {
                                  "date_time": controller
                                      .slots[_selectedSlot.value].dateTime,
                                  "duration": controller
                                      .timeslotsList[_selectedDate.value]
                                      .duration!,
                                  "message":
                                      notesFieldController.text.toString() ?? ""
                                };
                                Get.back(result: body);
                              },
                              child: Center(
                                child: CustomTextView(
                                  text: "confirm_meeting".tr,
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : const SizedBox(),
                      const SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                  showPopup.value
                      ? Positioned(
                          top: context.height * 0.22,
                          right: 0,
                          left: 0,
                          child: buildDatePopup(
                            context,
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            );
          })),
    );
  }

  Widget buildDateView(BuildContext context) {
    if (controller.timeslotsList.isNotEmpty) {
      controller.slots.clear();
      // Populate the slots based on the selected date
      controller.slots.addAll(UiHelper.createTimeslotMeeting(
          startDate:
              controller.timeslotsList[_selectedDate.value].startDatetime,
          endDate: controller.timeslotsList[_selectedDate.value].endDatetime,
          duration: controller.timeslotsList[_selectedDate.value].duration,
          gap: controller.timeslotsList[_selectedDate.value].gap,
          timezone: PrefUtils.getTimezone()));

      textFieldController.text = UiHelper.getSlotsDate(
          date:
              controller.timeslotsList[_selectedDate.value].startDatetime ?? "",
          timezone: PrefUtils.getTimezone());
    }
    return GestureDetector(
      onTap: () {
        if (controller.timeslotsList.isEmpty) {
          return;
        }
        showPopup(!showPopup.value);
      },
      child: TextFormField(
        textInputAction: TextInputAction.done,
        controller: textFieldController,
        maxLength: 100,
        keyboardType: TextInputType.text,
        validator: (String? value) {},
        onChanged: (value) {},
        decoration: InputDecoration(
            counter: const Offstage(),
            contentPadding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            labelText: "Select Date",
            enabled: false,
            hintText: "Select Date",
            labelStyle: TextStyle(color: colorSecondary, fontSize: 13),
            filled: true,
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: colorSecondary,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 60),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor))),
      ),
    );
  }

  Widget buildDatePopup(BuildContext? context) {
    return SizedBox(
      width: context?.width,
      child: Card(
        color: white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: borderColor, width: 1)),
        elevation: 6,
        child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            scrollDirection: Axis.vertical,
            itemCount: controller.timeslotsList.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              MeetingSlots meetingsSlot = controller.timeslotsList[index];
              return InkWell(
                onTap: () {
                  controller.slots.clear();
                  controller.slots.addAll(UiHelper.createTimeslotMeeting(
                      startDate: meetingsSlot.startDatetime,
                      endDate: meetingsSlot.endDatetime,
                      duration: meetingsSlot.duration,
                      gap: meetingsSlot.gap,
                      timezone: PrefUtils.getTimezone()));
                  _selectedDate.value = index;
                  textFieldController.text = UiHelper.getSlotsDate(
                      date: meetingsSlot.startDatetime ?? "",
                      timezone: PrefUtils.getTimezone());

                  duration = meetingsSlot.duration.toString();
                  controller.update();
                  showPopup(false);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  child: CustomTextView(
                    text: UiHelper.getSlotsDate(
                        date: meetingsSlot.startDatetime ?? "",
                        timezone: PrefUtils.getTimezone()),
                    maxLines: 2,
                    softWrap: true,
                    textAlign: TextAlign.start,
                    fontSize: 16,
                    color: index == _selectedDate.value
                        ? colorPrimary
                        : colorSecondary,
                    fontWeight: index == _selectedDate.value
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget buildSlotsListView(BuildContext context) {
    return SizedBox(
      height: 300.v,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: controller.slots.length,
        itemBuilder: (context, index) {
          var slotData = controller.slots[index];
          return GestureDetector(
            onTap: () {
              if (controller.bookingAppointmentList
                  .contains(slotData.dateTime?.replaceAll("00+00:00", "00Z"))) {
                //UiHelper.showSuccessMsg(context, "slot_booked".tr);
                return;
              }
              _selectedSlot.value = index;
            },
            child: Obx(() => Container(
                  decoration: BoxDecoration(
                      color: controller.bookingAppointmentList.contains(
                              slotData.dateTime?.replaceAll("00+00:00", "00Z"))
                          ? colorLightGray
                          : white,
                      shape: BoxShape.rectangle,
                      border: Border.all(
                          width: 1,
                          color: index == _selectedSlot.value
                              ? colorPrimary
                              : borderColor),
                      borderRadius: const BorderRadius.all(Radius.circular(6))),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextView(
                          color: index == _selectedSlot.value
                              ? colorPrimary
                              : colorSecondary,
                          text: controller.slots[index].time ?? "",
                          fontSize: 16,
                          fontWeight: index == _selectedSlot.value
                              ? FontWeight.bold
                              : FontWeight.normal,
                          textAlign: TextAlign.center,
                        ),
                        controller.bookingAppointmentList.contains(slotData
                                .dateTime
                                ?.replaceAll("00+00:00", "00Z"))
                            ? CustomTextView(
                                text: "not_available".tr,
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                textAlign: TextAlign.center,
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                )),
          );
        },
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5 / 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 20),
      ),
    );
  }

  Widget buildNotesWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: colorLightGray,
          borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: CustomTextView(
              text: "write_a_message".tr,
              fontSize: 18,
              color: colorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
              margin: const EdgeInsets.only(top: 16),
              padding: EdgeInsets.zero,
              child: TextFormField(
                textInputAction: TextInputAction.newline,
                controller: notesFieldController,
                maxLength: 100,
                maxLines: 6,
                minLines: 1,
                focusNode: FocusNode(),
                keyboardType: TextInputType.multiline,
                validator: (String? value) {},
                onChanged: (value) {},
                decoration: InputDecoration(
                    counter: const Offstage(),
                    contentPadding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                    labelText: "write_a_message".tr,
                    hintText: "type_here".tr,
                    hintStyle: TextStyle(
                        color: colorGray,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                    labelStyle: TextStyle(color: colorGray, fontSize: 14),
                    filled: true,
                    fillColor: white,
                    prefixIconConstraints: const BoxConstraints(minWidth: 60),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colorSecondary)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.red)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black)),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey))),
              ))
        ],
      ),
    );
  }

  Widget buildUserInfo(BuildContext context) {
    String firstName = personName.toString().split(" ").first;
    String lastName = "\n${personName?.split(" ").skip(1).join(" ") ?? ""}";
    return Container(
      padding: const EdgeInsets.only(top: 15, bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // First Row for profile and name
          Expanded(
            flex: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomImageWidget(
                    size: 41, imageUrl: profileImg, shortName: shortName),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: firstName, // First word
                          style: TextStyle(
                            color: colorSecondary,
                            fontSize: 16,
                            fontFamily: MyConstant.currentFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (lastName.toString().trim()?.isNotEmpty ?? false)
                          TextSpan(
                            text: lastName, // Remaining words on new line
                            style: TextStyle(
                              color: colorSecondary,
                              fontSize: 16,
                              fontFamily: MyConstant.currentFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    softWrap: true,
                    maxLines: 2, // ensures only 2 lines total
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            height: 46,
            width: 1,
            color: borderColor,
          ),
          // Space between divider and the next row
          const SizedBox(width: 16),
          // Second Row for duration info
          Expanded(
            flex: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(ImageConstant.calendar_icon,
                    width: 18,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurface,
                        BlendMode.srcIn)),
                const SizedBox(width: 10),
                CustomTextView(
                  text: "$duration Mins Meeting",
                  color: colorSecondary,
                  maxLines: 3,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMeetingRoom() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              controller.selectedLocation("networking_lounge".tr);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radio_button_checked,
                    color: controller.selectedLocation.value ==
                            "networking_lounge".tr
                        ? colorSecondary
                        : colorLightGray),
                const SizedBox(
                  width: 12,
                ),
                CustomTextView(
                  text: "networking_lounge_cap".tr,
                  fontSize: 12,
                )
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              controller.selectedLocation("booth".tr);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio_button_checked,
                  color: controller.selectedLocation.value == "booth".tr
                      ? colorSecondary
                      : colorLightGray,
                ),
                const SizedBox(
                  width: 12,
                ),
                CustomTextView(text: "exhibitor_booth".tr, fontSize: 12)
              ],
            ),
          ),
        )
      ],
    );
  }
}
