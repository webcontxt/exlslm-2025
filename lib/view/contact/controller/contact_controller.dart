import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:dreamcast/view/contact/model/contact_export_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../../theme/ui_helper.dart';
import '../../../utils/dialog_constant.dart';
import '../../beforeLogin/globalController/authentication_manager.dart';
import '../../representatives/controller/user_detail_controller.dart';
import '../model/contact_list_model.dart';
import '../model/model_contact_filter.dart';
import 'dart:io' show Directory, File, Platform;
import 'package:path_provider/path_provider.dart';

class ContactController extends GetxController {
  late final AuthenticationManager _authenticationManager;
  AuthenticationManager get authenticationManager => _authenticationManager;

  late bool hasNextPage;
  late int _pageNumber;
  var isFirstLoadRunning = false.obs;
  var isLoadMoreRunning = false.obs;
  var isLoading = false.obs;
  var isFavLoading = false.obs;

  final textController = TextEditingController().obs;
  ScrollController scrollController = ScrollController();
  var contactList = <Contacts>[].obs;

  var newRequestBody = {};
  var userIdsList = <dynamic>[];
  var exportContactList = <ExportModel>[];
  var filterContactBody = ContactFilterData().obs;
  var selectedFilterIndex = 0.obs;

  @override
  void onInit() {
    _authenticationManager = Get.find();
    _pageNumber = 1;
    hasNextPage = false;
    super.onInit();
    getFilter();
    getContactList(requestBody: {
      "page": "1",
      "filters": {
        "search": "",
        "sort": "ASC",
        "type": filterContactBody.value.selectedItem ?? ""
      }
    });
    dependencies();
  }

  void dependencies() {
    Get.lazyPut(() => UserDetailController(), fenix: true);
  }

  /// Searches for contacts based on the provided query.
  Future<void> getContactList({required requestBody}) async {
    _pageNumber = 1;
    newRequestBody = requestBody;
    isFirstLoadRunning(true);
    try {
      final model = ContactListModel.fromJson(json.decode(
        await apiService.dynamicPostRequest(
          body: requestBody,
          url: AppUrl.contactListApi,
        ),
      ));
      isFirstLoadRunning(false);
      if (model.status! && model.code == 200) {
        contactList.clear();
        contactList.addAll(model.body!.contacts!);
        hasNextPage = model.body?.hasNextPage ?? false;
        _pageNumber = _pageNumber + 1;
        _loadMoreContact();
      }
    } catch (e, stack) {
      print("Error in  API: $e\n$stack");
    } finally {
      isFirstLoadRunning(false);
    }
  }

  ///loads more contacts when the user scrolls to the bottom of the list.
  Future<void> _loadMoreContact() async {
    scrollController.addListener(() async {
      if (hasNextPage == true &&
          isFirstLoadRunning.value == false &&
          isLoadMoreRunning.value == false &&
          scrollController.position.maxScrollExtent ==
              scrollController.position.pixels) {
        isLoadMoreRunning(true);
        newRequestBody["page"] = _pageNumber.toString();
        try {
          final model = ContactListModel.fromJson(json.decode(
            await apiService.dynamicPostRequest(
              body: newRequestBody,
              url: AppUrl.contactListApi,
            ),
          ));
          if (model.status! && model.code == 200) {
            hasNextPage = model.body!.hasNextPage!;
            _pageNumber = _pageNumber + 1;
            contactList.addAll(model.body!.contacts!);
            update();
          }
        } catch (e) {
          print(e.toString());
        }
        isLoadMoreRunning(false);
      }
    });
  }

  /// Searches for contacts based on the provided query.
  Future<bool?> exportContact({required BuildContext context}) async {
    isLoading(true);
    final model = ExportModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
        body: {
          "page": 1,
          "filters": {"type": "all", "search": ""},
          "export": 1
        },
        url: AppUrl.exportContact,
      ),
    ));
    isLoading(false);
    if (model.status! && model.code == 200) {
      exportContactList.clear();
      exportContactList.add(model);
      return true;
    } else {
      return false;
    }
  }

  /// Filters the contact list based on the selected filter index.
  Future<void> getFilter() async {
    final model = FilterContactModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(
        url: AppUrl.contactListFiltersApi,
      ),
    ));
    try {
      if (model.status ?? false && model.code == 200) {
        if (model.body != null &&
            model.body?.params != null &&
            model.body!.params!.isNotEmpty) {
          filterContactBody(model.body!.params![0]);
          if (filterContactBody.value.options != null &&
              filterContactBody.value.options!.isNotEmpty) {
            selectedFilterIndex.value = 0;
            filterContactBody.value.selectedItem =
                filterContactBody.value.options![0].value;
          }
          filterContactBody.refresh();
        }
      }
    } catch (e) {
      e.toString();
    }
  }

  /// Saves a contact to the phone's contact list.
  Future<void> requestPermissionAndSaveContact(
      BuildContext context, Contacts representatives) async {
    /// Request permission to access contacts
    bool permissionGranted = await FlutterContacts.requestPermission();

    if (permissionGranted!) {
      // Create a new contact object
      Contact newContact = Contact()
        ..name.first = representatives.name ?? ""
        ..emails = [Email(representatives.email ?? "")]
        ..organizations = [
          Organization(
              company: representatives.company ?? "",
              department: representatives.position ?? "")
        ]
        ..phones = [Phone(representatives.mobile ?? "")];
      try {
        // Save the contact to the phone's contact list
        await newContact.insert();
        UiHelper.showSuccessMsg(context, "Contact saved successfully!");
      } catch (e) {
        UiHelper.showFailureMsg(context, "Failed to save contact!");
      }
    } else {
      PermissionStatus status = await Permission.contacts.status;
      if (Platform.isIOS && status.isDenied) {
        DialogConstantHelper.showPermissionDialog(
            message: "contact_permission".tr);
      } else if (Platform.isAndroid && status.isPermanentlyDenied) {
        DialogConstantHelper.showPermissionDialog(
            message: "contact_permission".tr);
      }
      print(status.isDenied);
      print(status.isPermanentlyDenied);
    }
  }

  /// Generates a CSV file from the exported contact list and shares it.
  Future<void> generateCsvFile() async {
    try {
      // Extract headers and contacts from the body response
      List<String>? headers = exportContactList[0].body?.headers ?? [];
      List<ExportContacts>? contacts =
          exportContactList[0].body?.contacts ?? [];
      if (headers == null || contacts == null) {
        print('No data available');
        return;
      }
      List<List<dynamic>> rows = [headers];
      // Populate each row based on the headers dynamically
      for (var contact in contacts) {
        List<dynamic> row = [];
        for (var header in headers) {
          // Convert header to lowercase and replace spaces with underscores for consistency
          String key = header.toLowerCase().replaceAll(' ', '_');
          // Dynamically access the properties of ExportContacts based on the header
          switch (key) {
            case 'name':
              row.add(contact.name ?? '');
              break;
            case 'id':
              row.add(contact.id ?? '');
              break;
            case 'email':
              row.add(contact.email ?? '');
              break;
            case 'country_code':
              row.add(contact.country ?? '');
              break;
            case 'mobile':
              row.add(contact.mobile ?? '');
              break;
            case 'note':
              row.add(contact.note ?? '');
              break;
            case 'company':
              row.add(contact.company ?? '');
              break;
            case 'avatar':
              row.add(contact.avatar ?? '');
              break;
            case 'role':
              row.add(contact.role ?? '');
              break;
            case 'position':
              row.add(contact.position ?? '');
              break;
            case 'short_name':
              row.add(contact.shortName ?? '');
              break;
            case 'type':
              row.add(contact.type ?? '');
              break;
            default:
              row.add('');
          }
        }
        rows.add(row);
      }
      // Convert rows to CSV
      String csvData = const ListToCsvConverter().convert(rows);
      Directory? directory = await getApplicationDocumentsDirectory();
      String filePath = "${directory.path}/Contacts.csv";
      // Write CSV data to the file
      File file = File(filePath);
      await file.writeAsString(csvData);
      XFile xFile = XFile(file.path);
      // Share the file
      await Share.shareXFiles([xFile], text: "Here is your CSV file");
      // return;
      print('CSV file saved at: $filePath');
    } catch (e) {
      print('Error generating CSV: $e');
    }
  }
}
