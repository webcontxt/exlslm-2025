import 'dart:convert';
import 'package:dreamcast/api_repository/api_service.dart';
import 'package:dreamcast/api_repository/app_url.dart';
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/view/home/controller/home_controller.dart';
import 'package:dreamcast/view/myCalender/model/myCalenderModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

//enum calander  { webinarBookmark,webinar,meeting}
class MyCalenderController extends GetxController {
  var loader = false.obs;

  HomeController homeController = Get.find<HomeController>();

  var callDetailsLoader = false.obs;

  var selectedDate = DateTime.now().obs;
  var allDates = <DateTime>[].obs;
  final ScrollController dateScrollController = ScrollController();
  final ScrollController timelineScrollController = ScrollController();

  final eventsList = <Appointment>[].obs;
  final eventTheme = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initial API call to fetch calendar events
    getEventsListApi(requestBody: {"date": ""});
  }

  // Scroll the timeline to a specific hour
  void scrollToHour(int hour) {
    const double minuteHeight = 1.5;
    final double offset = hour * 60 * minuteHeight;
    timelineScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Scrolls the horizontal date list to center the selected date
  void scrollToSelectedDate() {
    int index = allDates.indexWhere((date) =>
    date.day == selectedDate.value.day &&
        date.month == selectedDate.value.month &&
        date.year == selectedDate.value.year);
    if (index != -1 && dateScrollController.hasClients) {
      double itemWidth = 150.0;
      double screenWidth = Get.width;
      double offset =
          index * itemWidth - (screenWidth / 2) + (itemWidth / 2) - 8.0;
      if (offset < 0) offset = 0;
      dateScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Handles scroll event to update the selected date based on scroll position
  void _onDateScroll() {
    double itemWidth = 60.0; // Your actual item width
    double scrollOffset = dateScrollController.offset;
    double screenCenter = Get.width / 2;

    // Index of the centered item
    int index =
    ((scrollOffset + screenCenter - itemWidth / 2) / itemWidth).round();

    if (index >= 0 && index < allDates.length) {
      final newDate = allDates[index];
      if (selectedDate.value != newDate) {
        selectedDate.value = newDate;
      }
    }
  }

  // Returns list of events for a particular date
  List<Appointment> getAppointmentsForDate(DateTime date) {
    return eventsList.where((appointment) {
      return appointment.startTime.year == date.year &&
          appointment.startTime.month == date.month &&
          appointment.startTime.day == date.day;
    }).toList();
  }

  // Generates the list of all dates between event start and end dates
  void generateAllDates() {
    var startDateTime = homeController.configDetailBody.value.datetime?.start;
    var endDateTime = homeController.configDetailBody.value.datetime?.end;
    allDates = <DateTime>[].obs;
    if (startDateTime != null && endDateTime != null) {
      DateTime startDate = DateTime.parse(startDateTime);
      DateTime endDate = DateTime.parse(endDateTime);
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        allDates.add(startDate.add(Duration(days: i)));
      }
    }
    DateTime today = DateTime.now();
    DateTime? match = allDates.firstWhereOrNull(
          (date) =>
      date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );
    if (match != null) {
      selectedDate.value = match;
    } else if (allDates.isNotEmpty) {
      selectedDate.value = allDates.first;
    }
  }

  // API call to fetch events and prepare event list and themes
  Future<void> getEventsListApi(
      {required Map<String, dynamic> requestBody}) async {
    try {
      loader(true);
      final model = MyEventCalenderModel.fromJson(json.decode(
        await apiService.dynamicPostRequest(
          body: requestBody,
          url: AppUrl.myCalenderGet,
        ),
      ));

      if (model.status == true && model.body?.isNotEmpty == true) {
        eventsList.clear();
        allDates.clear();
        Set<DateTime> dateSet = {};

        for (var element in model.body!) {
          final start = DateTime.parse(element.startDatetime.toString() ?? "");
          final end = DateTime.parse(element.endDatetime.toString() ?? "");

          // Add each unique day between start and end (inclusive)
          DateTime current = DateTime(start.year, start.month, start.day);
          DateTime last = DateTime(end.year, end.month, end.day);

          while (!current.isAfter(last)) {
            dateSet.add(current);
            current = current.add(const Duration(days: 1));
          }

          // Convert hex color string to Color
          final eventColor = UiHelper.getColorByHexCode(element.color);

          // Avoid duplicate events based on ID
          if (eventsList.isEmpty || !eventsList.any((event) => event.id.toString() == element.id.toString())) {
            eventsList.add(
              Appointment(
                startTime: start,
                endTime: end,
                subject: element.title ?? '',
                color: eventColor ?? colorPrimary,
                id: element.id.toString(),
                notes: element.description ?? '',
                recurrenceRule: element.type,
              ),
            );

            // Add additional theme data for UI styling
            eventTheme.add({
              'textColor': element.textColor ?? colorSecondary,
              'borderColor': element.borderColor ?? colorPrimary,
              'opacity': element.opacity ?? 1.0,
              'type': element.type ?? 1.0,
            });
          }

          print(eventTheme);
        }
      }
      // Create date list and scroll UI elements
      generateAllDates();
      loader(false);
      // Scroll UI after slight delay to show selected date and time
      Future.delayed(const Duration(milliseconds: 80), () {
        scrollToSelectedDate();
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        scrollToHour(8); // Scroll to 8:00 AM
      });
    } catch (e) {
      rethrow;
    }
  }

  // Format hour as 12-hour format with AM/PM (e.g., 08:00 AM)
  String formatHourWithAmPm(int hour) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final formattedHour = hour12.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$formattedHour:00\n$period';
  }

  // Display date as "16th Jan", using day suffix and month abbreviation
  String showDateMyCalender(DateTime date) {
    final day = date.day;
    final suffix = UiHelper.getDaySuffix(day);
    final month = DateFormat('MMM').format(date); // Jan, Feb, etc.
    return '$day$suffix $month'; // e.g., 16th Jan
  }
  String getTheColorByType(type){
    String? textColor = eventTheme.firstWhere(
          (item) => item['type'] == type,
      orElse: () => {},
    )['textColor'];
    return textColor??"";
  }

}
