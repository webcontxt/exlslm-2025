import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/beforeLogin/globalController/authentication_manager.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:dreamcast/view/meeting/model/timeslot_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../view/meeting/model/create_time_slot.dart';
import 'app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class UiHelper {
  AuthenticationManager controller = Get.find();

  static openRouteIfExistsOrPush(String routeName,
      {Map<String, dynamic>? arguments}) {
    bool isInStack = false;

    Get.until((route) {
      if (route.settings.name == routeName) {
        isInStack = true;
      }
      return true; // allow full traversal
    });

    if (isInStack) {
      // Pop to the existing route
      Get.until((route) => route.settings.name == routeName);
    } else {
      // Route not found, push it
      Get.toNamed(routeName);
    }
  }

  // Compresses an image file if it exceeds the specified max size.
  static Future<File> compressImage({
    required File originalFile,
    int imageQuality = 90,
    int maxSizeInMB = 1,
  }) async {
    final int maxSizeInBytes = maxSizeInMB * 1024 * 1024;

    int originalSize = originalFile.lengthSync();
    // If original image is already within size limit, return it
    if (originalSize <= maxSizeInBytes) {
      return originalFile;
    }

    int quality = imageQuality;
    // Create target path for compressed image
    String targetPath =
        '${originalFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    File? compressedResult;

    // Try compressing in a loop by reducing quality gradually
    while (quality >= 10) {
      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        originalFile.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true, // Ensures orientation is baked in
        keepExif: false, //used for the show the image in correct orientation
      );

      if (compressedFile == null) break;

      final File resultFile = File(compressedFile.path);
      final int compressedSize = resultFile.lengthSync();
      print('Tried with quality $quality => ${compressedSize / 1024} KB');

      if (compressedSize <= maxSizeInBytes) {
        return resultFile;
      }

      compressedResult = resultFile;
      quality -= 5;
    }

    // Return last compressed version or original if compression failed
    return compressedResult ?? originalFile;
  }

// Reopens the meeting page if already in stack, otherwise pushes it fresh
  static reopenMeetingPageIfExists(String routeName) {
    if (Get.previousRoute == routeName || Get.currentRoute == routeName) {
      // Remove the existing page from the stack
      Get.offNamedUntil(
          Get.currentRoute, (route) => route.settings.name != routeName,
          arguments: {"tab_index": 1});
    }
    // Open the page again as a new instance
    Get.toNamed(routeName, arguments: {"tab_index": 1});
  }

// Formats a string date into "1st Jan, 2025" format
  static String formatDate({required String? date}) {
    if (date == null || date.trim().isEmpty) {
      return "";
    }
    return date;
    // DateTime parsedDate = DateTime.parse(date);
    // int dayInt = parsedDate.day;
    // String dayWithSuffix = "$dayInt${getDaySuffix(dayInt)}";
    // return "$dayWithSuffix ${DateFormat('MMM, yyyy').format(parsedDate)}";
  }

// Formats a string date into time format like "03:45 PM"
  static String formatTime({required String? date}) {
    if (date == null || date.trim().isEmpty) {
      return "";
    }
    return date;
    //DateTime parsedDate = DateTime.parse(date);
    //return DateFormat('hh:mm a').format(parsedDate);
  }

  ///date format is manage form backend  please don't change it
  String formatDateTime(String input) {
    if (input.isEmpty || input == "null") {
      return "";
    }
    return input;
    /*try {
      DateTime dateTime;
      String formattedTime = "";
      if (input.contains("|")) {
        List<String> parts = input.split('|');
        dateTime = DateFormat("yyyy-MM-dd").parse(parts[0].trim());
        formattedTime = parts.length > 1 ? parts[1].trim() : "";
      } else {
        dateTime = DateTime.parse(input);
        formattedTime = DateFormat('h:mm a').format(dateTime);
      }

      String dayWithSuffix = UiHelper.getDaySuffix(dateTime.day);
      String month = DateFormat('MMM').format(dateTime);
      String year = DateFormat('yyyy').format(dateTime);

      return "${dateTime.day}$dayWithSuffix $month, $year | $formattedTime";
    } catch (e) {
      return "";
    }*/
  }

// Formats a date string based on given timezone, adds day suffix
  static String formatDateWithTimezone({required String? date, timeZone}) {
    // Check if date is null or empty
    if (date == null || date.trim().isEmpty) {
      return "";
    }

    // Parse UTC Date (Ensure TimeZone conversion is correct)
    DateTime utcDate = DateTime.parse(date).toUtc();

    // Get the specified timezone
    final tz.Location location = tz.getLocation(timeZone ?? "Asia/Kolkata");

    // Convert UTC to Local Timezone
    final tz.TZDateTime localDate = tz.TZDateTime.from(utcDate, location);

    // Extract day and add ordinal suffix
    int dayInt = localDate.day;
    String dayWithSuffix = "$dayInt${getDaySuffix(dayInt)}";

    // Format final output
    return "$dayWithSuffix ${DateFormat('MMM, yyyy').format(localDate)}";
  }

// Formats time with timezone conversion
  static String formatTimeWithTimezone({required String? date, timeZone}) {
    // Check if date is null or empty
    if (date == null || date.trim().isEmpty) {
      return "";
    }

    // Parse UTC Date (Ensure TimeZone conversion is correct)
    DateTime utcDate = DateTime.parse(date).toUtc();

    // Get the specified timezone
    final tz.Location location = tz.getLocation(timeZone ?? "Asia/Kolkata");

    // Convert UTC to Local Timezone
    final tz.TZDateTime localDate = tz.TZDateTime.from(utcDate, location);
    // Format final output
    return DateFormat('hh:mm a').format(localDate);
  }

// Detects if given URL points to a PDF or image type
  static String checkUrlTypeImageOrPDf({String? url}) {
    if (url!.toLowerCase().endsWith('.pdf')) {
      return MyConstant.pdf;
    } else if (url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.gif') ||
        url.toLowerCase().endsWith('.webp')) {
      return MyConstant.image;
    } else {
      return "";
    }
  }

// Converts UTC date string to specified timezone and formats as "dd MMM, yyyy | hh:mm a"
  static String convertToTimeZone(String dateTimeString, String timeZone) {
    // Parse UTC datetime
    DateTime utcDateTime = DateTime.parse(dateTimeString).toUtc();

    // Convert to specified time zone
    final tz.Location location = tz.getLocation(timeZone);
    tz.TZDateTime localTime = tz.TZDateTime.from(utcDateTime, location);

    // Format final date & time
    return DateFormat("dd MMM, yyyy | hh:mm a").format(localTime);
  }

// Formats UTC timestamp into date-time string with suffix and timezone
  static String formatDateAndTime({String? timestamp, String? timeZone}) {
    if (timestamp == null || timestamp.isEmpty) {
      return "";
    }
    // Parse UTC timestamp
    DateTime utcDateTime = DateTime.parse(timestamp ?? "").toUtc();

    // Get dynamic timezone location
    final location = tz.getLocation(timeZone ?? "Asia/Kolkata");

    // Convert to the provided timezone
    tz.TZDateTime localDateTime = tz.TZDateTime.from(utcDateTime, location);

    // Get day with suffix
    String dayWithSuffix = getDaySuffix(localDateTime.day);

    // Format the final date
    String formattedDate =
        DateFormat("MMM, yyyy | hh:mm a").format(localDateTime);

    return "${localDateTime.day}$dayWithSuffix $formattedDate"; // Show city name (e.g., IST)
  }

  // Returns the ordinal suffix (st, nd, rd, th) based on the day number
  static String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return "th";
    }
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

// Returns a common divider widget with optional thickness and color
  static commonDivider({double? thickness, Color? dividerColor}) {
    return Divider(
      thickness: thickness ?? 1.0,
      color: borderColor,
    );
  }

// Downloads a PDF file from a given HTTPS URL and saves it to local storage
  static Future<String?> downloadPDF(String url, String fileName) async {
    try {
      // Ensure the URL uses HTTPS
      if (!url.startsWith("https://")) {
        print("Invalid URL: Only HTTPS is allowed.");
        return null;
      }

      // Request storage permission (Android only)
      if (Platform.isAndroid) {
        var status = await Permission.manageExternalStorage.request().isGranted;
        if (!status) {
          print("Storage permission denied");
          return null;
        }
      }

      // Get the correct directory to save the file
      Directory? directory;
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getExternalStorageDirectory();
      }

      if (directory == null) return null;

      String filePath = '${directory.path}/$fileName';

      // Start downloading the file
      Dio dio = Dio();
      await dio.download(url, filePath);

      print("PDF downloaded successfully at: $filePath");
      return filePath;
    } catch (e) {
      print("Download error: $e");
      return null;
    }
  }

// Checks for active internet connection
  static Future<bool> isInternetConnect() async {
    bool isConnected = await InternetConnectionChecker().hasConnection;
    return isConnected;
  }

  static String getShortName(String fullName) {
    // Split the full name into parts by space
    List<String> nameParts = fullName.trim().split(' ');

    // Extract the first letter of the first two parts
    String initials = nameParts
        .where((part) => part.isNotEmpty) // Filter out empty parts
        .take(2) // Take the first two non-empty parts
        .map((part) =>
            part[0].toUpperCase()) // Get the first letter and make it uppercase
        .join(); // Combine them into a string

    return initials;
  }

// Removes all HTML tags from a given string
  static String removeHtmlTags(String htmlText) {
    final document = htmlParser.parse(htmlText);
    return document.body?.text ?? "";
  }

// Formats a UTC datetime string into local timezone for chat display
  static String getChatDateTime({date, timezone}) {
    if (date.toString().isEmpty && date == null) {
      return "";
    }
    tz.initializeTimeZones();
    DateTime parseDate =
        DateFormat("yyyy-MM-dd HH:mm:ssZ").parse(date.toString(), true);
    final pacificTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    var inputDate = tz.TZDateTime.from(parseDate, pacificTimeZone);
    var outputFormat = DateFormat('MMM dd, HH:mm aa');
    var outputDate = outputFormat.format(inputDate);
    return outputDate;
  }

// Formats a UTC datetime string into "yyyy-MM-dd" in the given timezone
  static String getAllowDateFormat({date, timezone}) {
    if (date.isEmpty) {
      return "";
    }
    tz.initializeTimeZones();
    DateTime parseDate = DateFormat("yyyy-MM-dd'T'HH:mm:ssZ").parse(date, true);
    final pacificTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    var inputDate = tz.TZDateTime.from(parseDate, pacificTimeZone);
    var outputFormat = DateFormat('yyyy-MM-dd');
    var outputDate = outputFormat.format(inputDate);
    return outputDate;
  }

// Formats a UTC datetime string into "dd MMM" format in the given timezone
  static String getSlotsDate({date, timezone}) {
    if (date.isEmpty) {
      return "";
    }
    tz.initializeTimeZones();
    DateTime parseDate = DateFormat("yyyy-MM-dd'T'HH:mm:ssZ").parse(date, true);
    final pacificTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    var inputDate = tz.TZDateTime.from(parseDate, pacificTimeZone);
    var outputFormat = DateFormat('dd MMM');
    var outputDate = outputFormat.format(inputDate);
    return outputDate;
  }

// Generates a list of available time slots between two dates
  static List<CreatedSlots> createTimeslotMeeting({
    required startDate,
    required endDate,
    required duration,
    required gap,
    required timezone,
  }) {
    tz.initializeTimeZones();
    List<CreatedSlots> timeSlots = [];
    final location =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);

    DateTime startDateTime = DateTime.parse(startDate.toString()).toUtc();
    DateTime endDateTime = DateTime.parse(endDate.toString()).toUtc();

    DateTime convertedStartDate = tz.TZDateTime.from(startDateTime, location);
    DateTime convertedEndDate = tz.TZDateTime.from(endDateTime, location);

    Duration slotDuration = Duration(minutes: duration);
    Duration slotGap = Duration(minutes: gap);

    // Get the current time in the target timezone
    DateTime currentTime = tz.TZDateTime.now(location);

    while (convertedStartDate.isBefore(convertedEndDate)) {
      // Skip past time slots
      if (convertedStartDate.isBefore(currentTime)) {
        convertedStartDate = convertedStartDate.add(slotDuration + slotGap);
        continue;
      }

      var utcDateTimeFormat =
          "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(convertedStartDate.toUtc())}+00:00";

      timeSlots.add(CreatedSlots(
        time: DateFormat('hh:mm a').format(convertedStartDate),
        dateTime: utcDateTimeFormat,
        status: false,
      ));

      convertedStartDate = convertedStartDate.add(slotDuration + slotGap);
    }

    return timeSlots;
  }

// Filters out meeting slots that are in the past based on current date
  static List<MeetingSlots> filterMeetingSlotDate(
      String timezone, List<MeetingSlots> slotDateList) {
    List<MeetingSlots> newSlotDate = [];

    var mCurrentDate = UiHelper.getCurrentDate(timezone: timezone);
    for (var slotData in slotDateList) {
      DateTime startDate = DateTime.parse(UiHelper.getFormattedDateForCompare(
          date: slotData.endDatetime, timezone: timezone));

      DateTime dt1 = DateTime.parse(mCurrentDate);
      if (dt1.isBefore(startDate)) {
        newSlotDate.add(slotData);
        print("DT1 is before DT2");
      } else {
        print("DT1 is After DT2");
      }
    }
    return newSlotDate;
  }

  /// Parses the given date and formats it as '27 Sep, 2024 | 12:30 PM' format.
  /// Handles various date string formats and applies the specified or default timezone.
  static String displayCommonDateTime({date, timezone, String? dateFormat}) {
    if (date.toString().isEmpty && date == null) {
      return "";
    }
    // Initialize time zones
    tz.initializeTimeZones();
    DateTime parseDate;
    try {
      // Handle ISO 8601 format
      if (date.toString().contains('T') && date.toString().contains('Z')) {
        parseDate = DateTime.parse(date);
      } else if (date.toString().contains('.') &&
          date.toString().contains('Z')) {
        // Handle date string with milliseconds
        parseDate =
            DateFormat("yyyy-MM-dd HH:mm:ssZ'").parseUtc(date.toString());
      } else {
        // Fallback custom format
        parseDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date, true);
      }
    } catch (e) {
      print(e.toString());
      return "";
    }

    // Convert to the desired timezone (default to Asia/Kolkata)
    final targetTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    var inputDate = tz.TZDateTime.from(parseDate, targetTimeZone);

    // Format the output using provided or default format
    var outputFormat = DateFormat(dateFormat ?? 'dd MMM, yyyy | hh:mm aa');
    String outputDate = outputFormat.format(inputDate);

    return outputDate;
  }

  static String displayCommonDateTimeTh({date, timezone, String? dateFormat}) {
    if (date.toString().isEmpty || date == null) {
      return "";
    }

    // Initialize time zones
    tz.initializeTimeZones();
    DateTime parseDate;

    try {
      if (date.toString().contains('T') && date.toString().contains('Z')) {
        // ISO 8601 format (e.g., 2024-09-27T07:00:00Z)
        parseDate = DateTime.parse(date);
      } else if (date.toString().contains('.') &&
          date.toString().contains('Z')) {
        // Format with milliseconds (e.g., 2024-10-04 08:58:58.000Z)
        parseDate =
            DateFormat("yyyy-MM-dd HH:mm:ssZ'").parseUtc(date.toString());
      } else {
        // Default fallback format
        parseDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date, true);
      }
    } catch (e) {
      print(e.toString());
      // Return empty string if parsing fails
      return "";
    }

    // Get the specified time zone or default to "Asia/Kolkata"
    final targetTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    // Convert to the specified time zone
    var inputDate = tz.TZDateTime.from(parseDate, targetTimeZone);

    // Add suffix to the day
    String addDaySuffix(int day) {
      if (day >= 11 && day <= 13) return "${day}th";
      switch (day % 10) {
        case 1:
          return "${day}st";
        case 2:
          return "${day}nd";
        case 3:
          return "${day}rd";
        default:
          return "${day}th";
      }
    }

    // Extract day with suffix
    String dayWithSuffix = addDaySuffix(inputDate.day);

    // Define the date format
    var outputFormat = DateFormat(dateFormat ?? 'dd MMM, yyyy | hh:mm a');
    String formattedDate = outputFormat.format(inputDate);

    // Replace the day in the formatted date with the day and suffix
    return formattedDate.replaceFirst(
      RegExp(r'^\d{2}'),
      dayWithSuffix,
    );
  }

  /// Combines startDate and endDate with date suffix for meeting or session duration display
  static String displayDatetimeSuffix({startDate, endDate, timezone}) {
    String datetime =
        '${UiHelper.displayCommonDateTimeTh(date: startDate, dateFormat: 'dd MMM, yyyy', timezone: timezone)} | '
        '${UiHelper.displayCommonDateTime(date: startDate, dateFormat: 'hh:mm a', timezone: timezone)} - '
        '${UiHelper.displayCommonDateTime(date: endDate, dateFormat: 'hh:mm a', timezone: timezone)}';
    return datetime;
  }

  /// Displays date and time for event feed using date suffix
  static String displayDatetimeSuffixEventFeed({startDate, timezone}) {
    String datetime =
        '${UiHelper.displayCommonDateTimeTh(date: startDate, dateFormat: 'dd MMM, yyyy', timezone: timezone)} | '
        '${UiHelper.displayCommonDateTime(date: startDate, dateFormat: 'hh:mm a', timezone: timezone)}';
    return datetime;
  }

  /// Formats the date into '27 Sep' format
  static String displayDateFormat({date, timezone}) {
    if (date.toString().isEmpty && date == null) {
      return "";
    }
    // Initialize time zones
    tz.initializeTimeZones();
    DateTime parseDate;
    try {
      if (date.toString().contains('T') && date.toString().contains('Z')) {
        // ISO 8601 format (e.g., 2024-09-27T07:00:00Z)
        parseDate = DateTime.parse(date);
      } else if (date.toString().contains('.') &&
          date.toString().contains('Z')) {
        // Format with milliseconds (e.g., 2024-10-04 08:58:58.000Z)
        parseDate =
            DateFormat("yyyy-MM-dd HH:mm:ssZ'").parseUtc(date.toString());
      } else {
        // Default fallback format
        parseDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date, true);
      }
    } catch (e) {
      // Return empty string if parsing fails
      print(e.toString());
      return "";
    }
    // Get the specified time zone or default to "Asia/Kolkata"
    final targetTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    // Convert to the specified time zone
    var inputDate = tz.TZDateTime.from(parseDate, targetTimeZone);
    // Define output format
    var outputFormat = DateFormat('dd MMM');
    var outputDate = outputFormat.format(inputDate);

    return outputDate;
  }

  static String displayDateFormat2({date, timezone}) {
    if (date.toString().isEmpty || date == null) {
      return "";
    }
    // Initialize time zones
    tz.initializeTimeZones();
    DateTime parseDate;
    try {
      if (date.toString().contains('T') && date.toString().contains('Z')) {
        // ISO 8601 format (e.g., 2024-09-27T07:00:00Z)
        parseDate = DateTime.parse(date);
      } else if (date.toString().contains('.') &&
          date.toString().contains('Z')) {
        // Format with milliseconds (e.g., 2024-10-04 08:58:58.000Z)
        parseDate =
            DateFormat("yyyy-MM-dd HH:mm:ssZ'").parseUtc(date.toString());
      } else {
        // Default fallback format
        parseDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date, true);
      }
    } catch (e) {
      // Return empty string if parsing fails
      print(e.toString());
      return "";
    }
    // Get the specified time zone or default to "Asia/Kolkata"
    final targetTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    // Convert to the specified time zone
    var inputDate = tz.TZDateTime.from(parseDate, targetTimeZone);

    // Define a function to get the ordinal suffix
    String getOrdinalSuffix(int day) {
      if (day >= 11 && day <= 13) {
        return "th";
      }
      switch (day % 10) {
        case 1:
          return "st";
        case 2:
          return "nd";
        case 3:
          return "rd";
        default:
          return "th";
      }
    }

    // Get the day with the suffix
    var day = inputDate.day;
    var suffix = getOrdinalSuffix(day);

    // Define output format for month
    var monthFormat = DateFormat('MMM');
    var formattedDate = "$day$suffix ${monthFormat.format(inputDate)}";

    return formattedDate;
  }

  /// Formats the time only (e.g., '12:30 PM')
  static String displayTimeFormat({date, timezone}) {
    if (date.toString().isEmpty && date == null) {
      return "";
    }
    // Initialize time zones
    tz.initializeTimeZones();
    DateTime parseDate;
    try {
      if (date.toString().contains('T') && date.toString().contains('Z')) {
        // ISO 8601 format (e.g., 2024-09-27T07:00:00Z)
        parseDate = DateTime.parse(date);
      } else if (date.toString().contains('.') &&
          date.toString().contains('Z')) {
        // Format with milliseconds (e.g., 2024-10-04 08:58:58.000Z)
        parseDate =
            DateFormat("yyyy-MM-dd HH:mm:ssZ'").parseUtc(date.toString());
      } else {
        // Default fallback format
        parseDate = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date, true);
      }
    } catch (e) {
      // Return empty string if parsing fails
      print(e.toString());
      return "";
    }
    // Get the specified time zone or default to "Asia/Kolkata"
    final targetTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    // Convert to the specified time zone
    var inputDate = tz.TZDateTime.from(parseDate, targetTimeZone);
    // Define output format
    var outputFormat = DateFormat('hh:mm aa');
    var outputDate = outputFormat.format(inputDate);

    return outputDate;
  }

  //* Limits given string, adds '..' if necessary
  static String shortenName(String nameRaw,
      {int nameLimit = 10, bool addDots = false}) {
    //* Limiting val should not be gt input length (.substring range issue)
    final max = nameLimit < nameRaw.length ? nameLimit : nameRaw.length;
    //* Get short name
    final name = nameRaw.substring(0, max);
    //* Return with '..' if input string was sliced
    if (addDots && nameRaw.length > max) return '$name..';
    return name;
  }

  ///used for the compare the date in meeting section
  static String getFormattedDateForCompare({date, timezone}) {
    if (date.isEmpty) {
      return "";
    }
    tz.initializeTimeZones();

    DateTime parseDate =
        DateFormat("yyyy-MM-dd'T'HH:mm:ssZ'").parse(date, true);
    final pacificTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    var inputDate = tz.TZDateTime.from(parseDate, pacificTimeZone);
    var outputFormat = DateFormat('yyyy-MM-dd HH:mm');
    var outputDate = outputFormat.format(inputDate);
    return outputDate;
  }

  ///get the current date to used in meeting and chat created time
  static String getCurrentDate({timezone}) {
    tz.initializeTimeZones();

    final pacificTimeZone =
        tz.getLocation(timezone?.isEmpty ?? true ? "Asia/Kolkata" : timezone);
    var inputDate = tz.TZDateTime.from(DateTime.now(), pacificTimeZone);
    var outputFormat = DateFormat('yyyy-MM-dd HH:mm');
    var outputDate = outputFormat.format(inputDate);
    return outputDate;
  }

  /// Returns the corresponding asset path for social icons
  static String getSocialIcon(type) {
    switch (type) {
      case "facebook":
        return "assets/svg/fb_icon.svg";
      case "twitter":
        return "assets/svg/twitter_icon.svg";
      case "instagram":
        return "assets/svg/insta_icon.svg";
      case "linkedin":
        return "assets/svg/linked_icon.svg";
      case "google":
        return "assets/svg/google_icon.svg";
      case "youtube":
        return "assets/svg/youtube_icon.svg";
      case "website":
        return "assets/svg/website_icon.svg";
    }
    return "assets/svg/website.svg";
  }

  /// Returns reaction emoji icons based on type
  static String getLikeIcon(type) {
    switch (type) {
      case "like":
        return "assets/icons/like_icons.png";
      case "love":
        return "assets/icons/heart_icon.png";
      case "care":
        return "assets/icons/emoji_like_1.png";
      case "haha":
        return "assets/icons/emoji_like_2.png";
      case "wow":
        return "assets/icons/emoji_like_3.png";
      case "sad":
        return "assets/icons/emoji_like_4.png";
      case "angry":
        return "assets/icons/emoji_like_5.png";
        break;
      case "":
        return "assets/icons/like_icon.png";
        break;
    }
    return "assets/icons/like_icon.png";
  }

  /// Extracts YouTube video ID and returns thumbnail URL
  static String? getYoutubeThumbnail(String videoUrl) {
    final Uri uri = Uri.parse(videoUrl);
    if (uri == null) {
      return null;
    }
    return 'https://img.youtube.com/vi/${uri.queryParameters['v']}/0.jpg';
  }

  /// Opens a URL in in-app webview mode
  static Future<void> inAppWebView(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppWebView,
      webViewConfiguration: const WebViewConfiguration(enableDomStorage: false),
    )) {
      throw 'Could not launch $url';
    }
  }

  /// Opens a URL in in-app browser view
  static Future<void> inAppBrowserView(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppBrowserView,
      webViewConfiguration: const WebViewConfiguration(enableDomStorage: false),
    )) {
      throw 'Could not launch $url';
    }
  }

  /// Opens a URL in external browser or application
  static Future<void> externalWebView(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
      webViewConfiguration: const WebViewConfiguration(enableDomStorage: false),
    )) {
      throw 'Could not launch $url';
    }
  }

  /// Opens a URL using platform's default behavior
  static Future<void> inPlatformDefault(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
      webViewConfiguration: const WebViewConfiguration(enableDomStorage: false),
    )) {
      throw 'Could not launch $url';
    }
  }

  /// Pads number with leading zero if < 10, used for countdown display
  static String formatCountdown(int time) {
    return time.toString().padLeft(2, '0');
  }

  /// Validates if a string is a numeric value
  static bool isNumber(String string) {
    final numericRegex = RegExp(r'^-?(([0-9]*)|(([0-9]*)\.([0-9]*)))$');
    return numericRegex.hasMatch(string);
  }

  static bool isEmail(String string) {
    // Return true if email string is empty
    if (string.isEmpty) {
      return true;
    }

    // Regular expression for validating an email address
    const pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    final regExp = RegExp(pattern);

    // Validate email using regex
    if (!regExp.hasMatch(string)) {
      return false;
    }
    return true;
  }

  static Widget getPhotoBoothImage({imageUrl}) {
    // Display network image with placeholder and error widget
    return CachedNetworkImage(
      maxHeightDiskCache: 500,
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      placeholder: (context, url) => Center(
        child: Image.asset(
          ImageConstant.imagePlaceholder,
        ),
      ),
      errorWidget: (context, url, error) => Image.asset(
        ImageConstant.imagePlaceholder,
        fit: BoxFit.contain,
      ),
    );
  }

  static Widget getProductImage({imageUrl}) {
    // Display product image with loading and fallback image
    return CachedNetworkImage(
      maxHeightDiskCache: 500,
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: imageProvider, fit: BoxFit.contain),
        ),
      ),
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Image.asset(
        "assets/icons/products.png",
        color: colorLightGray,
      ),
    );
  }

  static Widget getExhibitorDetailsImage({imageUrl}) {
    // Display exhibitor detail image or fallback if null/empty
    return imageUrl != null && imageUrl.toString().isNotEmpty
        ? CachedNetworkImage(
            maxHeightDiskCache: 500,
            imageUrl: imageUrl,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image:
                    DecorationImage(image: imageProvider, fit: BoxFit.contain),
              ),
            ),
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => Image.asset(
              "assets/icons/exhibitors_home.png",
              color: colorGray,
            ),
          )
        : Image.asset(
            "assets/icons/exhibitors_home.png",
            color: colorGray,
          );
  }

  static Widget getExhibitorImage({imageUrl}) {
    // Display exhibitor image or fallback if null/empty
    return imageUrl != null && imageUrl.toString().isNotEmpty
        ? CachedNetworkImage(
            maxHeightDiskCache: 500,
            imageUrl: imageUrl,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image:
                    DecorationImage(image: imageProvider, fit: BoxFit.contain),
              ),
            ),
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => Image.asset(
              "assets/icons/exhibitors_home.png",
              color: colorGray,
            ),
          )
        : Image.asset(
            "assets/icons/exhibitors_home.png",
            color: colorGray,
          );
  }
  static Future<bool> isInternetWorking(BuildContext context) async {
    try {
      // Check if any connectivity is available
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        showFailureMsg(context,
            "Internet not working. Please check your network connection and try again");
        return false;
      }

      // Try a DNS lookup to confirm internet access
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      // Fallback error message if any step fails
      showFailureMsg(context,
          "Internet not working. Please check your network connection and try again");
      return false;
    }
    return false;
  }

  static void showFailureMsgTop(BuildContext? context, String message) {
    // Show toast with failure message (top center)
    toastification.dismissAll();
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
      description: RichText(
        text: TextSpan(
          text: message ?? "",
          style: TextStyle(color: white, fontSize: 14.fSize),
        ),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 350),
      icon: Icon(Icons.error_outline, color: white, size: 30),
      showIcon: true,
      backgroundColor: colorSecondary,
      primaryColor: colorSecondary,
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(100),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => print('Toast ${toastItem.id} tapped'),
        onCloseButtonTap: (toastItem) =>
            print('Toast ${toastItem.id} close button tapped'),
        onAutoCompleteCompleted: (toastItem) =>
            print('Toast ${toastItem.id} auto complete completed'),
        onDismissed: (toastItem) {
          print("'wehfbwuefbwuefb");
        },
      ),
    );
  }

  static void showFailureMsg(BuildContext? context, String message) {
    // Show toast with failure message (bottom center)
    toastification.dismissAll();
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
      description: RichText(
        text: TextSpan(
          text: message ?? "",
          style: TextStyle(color: white, fontSize: 14.fSize),
        ),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 350),
      icon: Icon(Icons.error_outline, color: white, size: 30),
      showIcon: true,
      backgroundColor: colorSecondary,
      primaryColor: colorSecondary,
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(100),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => print('Toast ${toastItem.id} tapped'),
        onCloseButtonTap: (toastItem) =>
            print('Toast ${toastItem.id} close button tapped'),
        onAutoCompleteCompleted: (toastItem) =>
            print('Toast ${toastItem.id} auto complete completed'),
        onDismissed: (toastItem) {
          print("'wehfbwuefbwuefb");
        },
      ),
    );
  }

  static void showSuccessMsg(BuildContext? context, String message) {
    // Show toast with success message
    toastification.dismissAll();
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
      description: RichText(
        text: TextSpan(
          text: message ?? "",
          style: TextStyle(color: white, fontSize: 14.fSize),
        ),
      ),
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomCenter,
      animationDuration: const Duration(milliseconds: 350),
      icon: Icon(Icons.check_circle_outline, color: white, size: 30),
      showIcon: true,
      backgroundColor: colorSecondary,
      primaryColor: colorSecondary,
      borderSide: const BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(100),
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.onHover,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => print('Toast ${toastItem.id} tapped'),
        onCloseButtonTap: (toastItem) =>
            print('Toast ${toastItem.id} close button tapped'),
        onAutoCompleteCompleted: (toastItem) =>
            print('Toast ${toastItem.id} auto complete completed'),
        onDismissed: (toastItem) {
          print("'wehfbwuefbwuefb");
        },
      ),
    );
  }

  static String durationToString(int minutes) {
    // Convert integer minutes to HH:mm format string
    var d = Duration(minutes: minutes);
    List<String> parts = d.toString().split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')} minutes';
  }

  static bool isValidPhoneNumber(String string) {
    // Check phone number format and length using regex
    if (string == null || string.isEmpty || string.length < 7) {
      return false;
    }
    const pattern = r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$';
    final regExp = RegExp(pattern);

    if (!regExp.hasMatch(string)) {
      return false;
    }
    return true;
  }

  static Color getColorByHexCode(String code) {
    // Convert hex string to Color
    if (code.isNotEmpty) {
      return Color(int.parse("0xFF${code.replaceAll("#", "")}"));
    }
    return colorPrimary;
  }

  ///********** Checking Camera Permission ***********///
  static Future<bool?> checkAndRequestCameraPermissions() async {
    PermissionStatus permissionStatus;
    late Permission permission;
    permission = Permission.camera;
    permissionStatus = await permission.request();

    if (permissionStatus == PermissionStatus.denied) {
      PermissionStatus newPermissionStatus = await permission.request();
      if (newPermissionStatus == PermissionStatus.denied) {
        /// Permission denied
        return false;
      }
      if (newPermissionStatus == PermissionStatus.permanentlyDenied) {
        /// Permission denied
        return false;
      } else {
        /// Permission accepted
        return true;
      }
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      /// Permission denied
      return false;
    } else {
      /// Permission accepted
      return true;
    }
  }

  ///********** Checking Contact Permission ***********///
  static Future<bool?> checkAndRequestContactPermissions() async {
    PermissionStatus permissionStatus;
    late Permission permission;
    permission = Permission.contacts;
    permissionStatus = await permission.request();
    if (permissionStatus == PermissionStatus.denied) {
      PermissionStatus newPermissionStatus = await permission.request();
      if (newPermissionStatus == PermissionStatus.denied) {
        /// Permission denied
        return false;
      }
      if (newPermissionStatus == PermissionStatus.permanentlyDenied) {
        /// Permission denied
        return false;
      } else {
        /// Permission accepted
        return true;
      }
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      /// Permission denied
      return false;
    } else {
      /// Permission accepted
      return true;
    }
  }

  ///social media validation
  static bool isValidLinkedInUrl(String url) {
    final RegExp regex = RegExp(
      r'^(https?:\/\/)(www\.)?linkedin\.com\/',
    );
    return regex.hasMatch(url);
  }

  static bool isValidLinkedInUrlNew(String url) {
    // Validate non-empty LinkedIn URL using regex
    if (url.isEmpty) {
      return false;
    }
    final regex = RegExp(
      r'^https:\/\/(www\.)?linkedin\.com\/',
    );
    return regex.hasMatch(url);
  }

  static bool isValidTwitterUrl(String url) {
    // Validate X (Twitter) URL
    final RegExp regex = RegExp(
      r'^https?:\/\/(www\.)?x\.com\/',
    );
    return regex.hasMatch(url);
  }

  static bool isValidFacebookUrl(String url) {
    // Validate Facebook URL
    final RegExp regex = RegExp(
      r'^https?:\/\/(www\.)?facebook\.com\/',
    );
    return regex.hasMatch(url);
  }

  static bool isValidWebsiteUrl(String url) {
    // Validate basic website URL structure
    if (url == null || url.isEmpty) {
      return true;
    }
    final RegExp regex = RegExp(
      r'^(https?:\/\/)' // http or https
      r'([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}' // domain
      r'(:\d{2,5})?' // optional port
      r'(\/[a-zA-Z0-9@:%_+.~#?&//=]*)?$', // optional path
    );
    return regex.hasMatch(url);
  }

  static bool webSiteValidator(String url) {
    // Alternate basic website URL validation using regex
    String pattern = r'^(https?|ftp):\/\/[^\s/$.?#].[^\s]*$';
    RegExp regExp = RegExp(pattern);
    if (!regExp.hasMatch(url)) {
      return false;
    } else {
      return true;
    }
  }
}
