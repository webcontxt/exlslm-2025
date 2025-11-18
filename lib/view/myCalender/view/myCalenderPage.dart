import 'dart:io';

import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/meeting/controller/meetingController.dart';
import 'package:dreamcast/view/meeting/view/meeting_details_page.dart';
import 'package:dreamcast/view/myCalender/controller/myCalender_controller.dart';
import 'package:dreamcast/view/schedule/controller/session_controller.dart';
import 'package:dreamcast/view/schedule/view/watch_session_page.dart';
import 'package:dreamcast/widgets/app_bar/appbar_leading_image.dart';
import 'package:dreamcast/widgets/app_bar/custom_app_bar.dart';
import 'package:dreamcast/widgets/loading.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:dreamcast/widgets/toolbarTitle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MyEventCalenderPage extends GetView<MyCalenderController> {
  MyEventCalenderPage({super.key});
  static const routeName = "/MyEventCalenderPage";

  final MyCalenderController controller = Get.put(MyCalenderController());

  @override
  Widget build(BuildContext context) {
    const double minuteHeight = 1.5;
    const double timelineHeight = 24 * 60 * minuteHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        height: 72.v,
        leadingWidth: 45.h,
        leading: AppbarLeadingImage(
          imagePath: ImageConstant.imgArrowLeft,
          margin: EdgeInsets.only(
            left: 7.h,
            top: 3,
          ),
          onTap: () {
            Get.back();
          },
        ),
        title: ToolbarTitle(
            title:
            "${Get.arguments?[MyConstant.titleKey] ?? "my_calendar".tr}"),
      ),
      body: GetBuilder<MyCalenderController>(
        builder: (controller) {
          return Obx(() {
            final selectedDate = controller.selectedDate.value;
            return Stack(
              children: [
                Skeletonizer(
                    enabled: controller.loader.value,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                              controller: controller.dateScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: controller.loader.value
                                  ? 5
                                  : controller.allDates.length,
                              itemBuilder: (context, index) {
                                if (controller.loader.value) {
                                  return Container(
                                    width: 120,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 22, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: colorLightGray,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                  );
                                } else {
                                  final date = controller.allDates[index];
                                  final isSelected =
                                      date.day == selectedDate.day &&
                                          date.month == selectedDate.month &&
                                          date.year == selectedDate.year;

                                  return GestureDetector(
                                    onTap: () {
                                      controller.selectedDate.value = date;
                                    },
                                    child: Container(
                                      width: 120,
                                      padding: const EdgeInsets.only(left: 10),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 22, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color:
                                        isSelected ? colorPrimary : white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: isSelected
                                                ? colorPrimary
                                                : border,
                                            width: 1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          CustomTextView(
                                            text: controller
                                                .showDateMyCalender(date),
                                            color: isSelected
                                                ? white
                                                : colorSecondary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          CustomTextView(
                                            text:
                                            DateFormat('EEEE').format(date),
                                            fontSize: 14,
                                            color: isSelected
                                                ? white
                                                : colorSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }),
                        ),
                        Expanded(
                          child: Obx(() {
                            final selectedAppointments =
                            controller.getAppointmentsForDate(
                                controller.selectedDate.value);
                            List<_PositionedAppointment>
                            positionedAppointments = [];

                            selectedAppointments.sort(
                                    (a, b) => a.startTime.compareTo(b.startTime));

                            for (var appt in selectedAppointments) {
                              int column = 0;
                              for (var placed in positionedAppointments) {
                                bool overlaps = appt.startTime
                                    .isBefore(placed.appointment.endTime) &&
                                    appt.endTime
                                        .isAfter(placed.appointment.startTime);
                                if (overlaps && placed.column == column) {
                                  column++;
                                }
                              }
                              positionedAppointments
                                  .add(_PositionedAppointment(appt, column));
                            }

                            int maxColumns = positionedAppointments.fold(
                                1,
                                    (prev, pos) => pos.column + 1 > prev
                                    ? pos.column + 1
                                    : prev);

                            double eventWidth = 160;
                            double horizontalPadding = 16;
                            double timeLabelWidth = 70;
                            double stackWidth = maxColumns * eventWidth +
                                timeLabelWidth +
                                horizontalPadding;
                            List<Widget> stackChildren = [];
                            int index = 0;
                            for (var pos in positionedAppointments) {
                              var appt = pos.appointment;
                              int apptStartMinute = appt.startTime.hour * 60 +
                                  appt.startTime.minute;
                              int apptEndMinute =
                                  appt.endTime.hour * 60 + appt.endTime.minute;
                              double apptHeight =
                              ((apptEndMinute - apptStartMinute) *
                                  minuteHeight)
                                  .clamp(22.0, double.infinity);
                              stackChildren.add(Positioned(
                                top: apptStartMinute * minuteHeight + 12,
                                left: pos.column * eventWidth,
                                width: eventWidth - 2,
                                height: apptHeight-2,
                                child: Container(
                                  color: white,
                                  child: InkWell(
                                    onTap: () {
                                      onEventTap(appt);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 1),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: appt.color.withOpacity(
                                            controller.eventTheme[index]
                                            ['opacity']) ??
                                            colorPrimary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CustomTextView(
                                        text:
                                        '${DateFormat.jm().format(appt.startTime)} - ${DateFormat.jm().format(appt.endTime)}\n${appt.subject}',
                                        fontSize: 12,
                                        color: UiHelper.getColorByHexCode(
                                            controller.getTheColorByType(
                                                appt.recurrenceRule)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ));
                              index++;
                            }

                            return SingleChildScrollView(
                              controller: controller.timelineScrollController,
                              child: SizedBox(
                                height: timelineHeight + 100,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: timeLabelWidth,
                                      child: Stack(
                                        children: List.generate(24, (hour) {
                                          return Positioned(
                                            top: hour * 60 * minuteHeight,
                                            left: 0,
                                            right: 0,
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      left: 0),
                                                  child: CustomTextView(
                                                    text: controller
                                                        .formatHourWithAmPm(
                                                        hour),
                                                    textAlign: TextAlign.center,
                                                    fontSize: 14,
                                                    color: gray,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: stackWidth + 120,
                                          height: timelineHeight,
                                          child: Stack(
                                            children: [
                                              for (int hour = 0;
                                              hour < 24;
                                              hour++)
                                                Positioned(
                                                  top:
                                                  hour * 60 * minuteHeight +
                                                      10,
                                                  left: -100,
                                                  right: 0,
                                                  child: Row(
                                                    children: [
                                                      const SizedBox(
                                                          width: 70),
                                                      Expanded(
                                                        child: Container(
                                                          height: 1,
                                                          // margin: EdgeInsets.only(bottom: 10),
                                                          color: border,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ...stackChildren,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    )),
                controller.callDetailsLoader.value
                    ? const Loading()
                    : const SizedBox()
              ],
            );
          });
        },
      ),
    );
  }

  onEventTap(Appointment eventData) async {
    if (eventData.recurrenceRule == MyConstant.webinarBookmark ||
        eventData.recurrenceRule == MyConstant.webinar) {
      openSessionDetail(eventData.id);
    } else if (eventData.recurrenceRule == MyConstant.meeting) {
      openMeetingDetail(eventData.id);
    }
  }

  openSessionDetail(dynamic id) async {
    final sessionController =
    Get.put(SessionController(), permanent: false);
    controller.callDetailsLoader(true);
    var apiResult =
    await sessionController.getSessionDetail(requestBody: {"id": id});
    controller.callDetailsLoader(false);
    if (apiResult["status"] == true) {
      await Get.to(() => WatchDetailPage(
        sessions: sessionController.sessionDetailBody,
      ));
      controller.update();
    }
  }

  openMeetingDetail(dynamic id) async {
    final meetingController =
    Get.put(MeetingController(), permanent: false);
    controller.callDetailsLoader(true);
    var result =
    await meetingController.getMeetingDetail(requestBody: {"id": id});
    controller.callDetailsLoader(false);
    if (result["status"] == true) {
      Get.toNamed(MeetingDetailPage.routeName);
    }
  }
}

class _PositionedAppointment {
  final Appointment appointment;
  final int column;
  _PositionedAppointment(this.appointment, this.column);
}
