import 'dart:convert';

import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/view/support/model/faq_model.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../breifcase/model/BriefcaseModel.dart';
import '../../breifcase/model/common_document_request.dart';
import '../../exhibitors/model/bookmark_common_model.dart';
import '../model/sos_model.dart';

class SOSFaqController extends GetxController {
  var loading = false.obs;
  var isFirstLoading = false.obs;

  // Observable lists for guides, FAQs, and SOS items
  var guideList = <DocumentData>[].obs;
  var faqList = <dynamic>[].obs;
  var sosList = <SosData>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Load FAQ list initially when the controller is created
    getFaqList(isRefresh: false);
  }

  // Fetch the user guide documents
  Future<void> getUserGuide({required isRefresh}) async {
    if (!isRefresh) {
      isFirstLoading(true); // Show initial loading
    }

    final model = CommonDocumentModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
          body: CommonDocumentRequest(itemId: "", itemType: "guide"),
          url: AppUrl.getCommonDocument),
    ));

    isFirstLoading(false); // Stop loading after response

    if (model.status! && model.code == 200) {
      // Update the guide list
      guideList.clear();
      guideList.addAll(model.body ?? []);
    }
  }

  // Fetch the FAQ list from the API
  Future<void> getFaqList({isRefresh}) async {
    if (!isRefresh) {
      isFirstLoading(true); // Show loader during first load
    }

    final model = FaqModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(
        url: AppUrl.faqList,
      ),
    ));

    isFirstLoading(false); // Stop loading after response

    if (model.status! && model.code == 200) {
      // Update the FAQ list
      faqList.clear();
      faqList.addAll(model.body ?? []);
    }
  }

  // Fetch the SOS data list
  Future<void> getSOSList({isRefresh}) async {
    if (!isRefresh) {
      isFirstLoading(true); // Show loader if not a refresh
    }

    final model = SOSDataModel.fromJson(json.decode(
      await apiService.dynamicGetRequest(
        url: AppUrl.sos,
      ),
    ));

    isFirstLoading(false); // Hide loading indicator

    if (model.status! && model.code == 200) {
      // Update the SOS list
      sosList.clear();
      sosList.addAll(model.body ?? []);
      sosList.refresh(); // Notify listeners for UI update
    }
  }

  // Bookmark a document item by index
  Future<void> bookmarkToItem(int index) async {
    var jsonRequest = {"item_id": guideList[index].id, "item_type": "document"};

    loading(true); // Show loading while bookmarking

    final model = BookmarkCommonModel.fromJson(json.decode(
      await apiService.dynamicPostRequest(
          body: jsonRequest, url: AppUrl.commonBookmarkApi),
    ));

    loading(false); // Stop loading after response

    if (model.status! && model.code == 200) {
      // Update the favourite ID and refresh UI
      guideList[index].favourite = model.body?.id ?? "";
      guideList.refresh();

      // Show success message
      UiHelper.showSuccessMsg(null, model.body?.message ?? "");
    }
  }
}
