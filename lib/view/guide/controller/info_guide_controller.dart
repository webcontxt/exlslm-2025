import 'dart:convert';

import 'package:dreamcast/theme/ui_helper.dart';
import 'package:dreamcast/view/support/model/faq_model.dart';
import 'package:get/get.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../../breifcase/model/BriefcaseModel.dart';
import '../../breifcase/model/common_document_request.dart';
import '../../exhibitors/model/bookmark_common_model.dart';
import '../../home/model/config_detail_model.dart';
import '../model/dodont_model.dart';

class InfoFaqController extends GetxController {
  var loading = false.obs;
  var isFirstLoading = false.obs;
  var guideList = <DocumentData>[].obs;
  var tipsList = TipsBody().obs;
  var configDetailBody = HomeConfigBody().obs;

  @override
  void onInit() {
    super.onInit();
    getHomeApi(isRefresh: false);
  }

  /// Fetches the home API to get configuration details and updates the UI accordingly.
  Future<void> getHomeApi({required bool isRefresh}) async {
    // Show loading only if it's not a refresh call
    if (!isRefresh) {
      isFirstLoading(true);
    }

    try {
      // Perform the API request and parse the response
      final response =
          await apiService.dynamicGetRequest(url: AppUrl.getConfigDetail);
      final model = HomePageModel.fromJson(json.decode(response));

      // Update the config detail if response is successful
      if (model.status == true && model.code == 200) {
        configDetailBody(model.homeConfigBody);
        configDetailBody.refresh(); // Notify observers
      }
    } catch (e, stack) {
      // Log any errors
      print("Error in getHomeApi: $e\n$stack");
    } finally {
      // Always hide the loading indicator
      isFirstLoading(false);
    }
  }

  /// Fetches the FAQ data from the API and updates the guide list.
  Future<void> getUserGuide({required isRefresh}) async {
    if (!isRefresh) {
      isFirstLoading(true);
    }

    try {
      final model = CommonDocumentModel.fromJson(json.decode(
        await apiService.dynamicPostRequest(
            body: CommonDocumentRequest(itemId: "", itemType: "guide"),
            url: AppUrl.getCommonDocument),
      ));
      isFirstLoading(false);
      if (model.status! && model.code == 200) {
        guideList.clear();
        guideList.addAll(model.body ?? []);
      }
    } catch (e, stack) {
      // Log any errors
      print("Error in guide api: $e\n$stack");
    } finally {
      // Always hide the loading indicator
      isFirstLoading(false);
    }
  }

  /// Fetches the Do's and Don'ts data from the API and updates the guide list.
  Future<void> getTips({isRefresh}) async {
    if (!isRefresh) {
      isFirstLoading(true);
    }

    try {
      final model = TipsDataModel.fromJson(json.decode(
        await apiService.dynamicGetRequest(
          url: AppUrl.tips,
        ),
      ));
      isFirstLoading(false);
      if (model.status! && model.code == 200) {
        tipsList(model.body);
        tipsList.refresh();
      }
    } catch (e, stack) {
      // Log any errors
      print("Error in getTips api: $e\n$stack");
    } finally {
      // Always hide the loading indicator
      isFirstLoading(false);
    }
  }

  /// bookmarks an item in the guide list by its index.
  Future<void> bookmarkToItem(int index) async {
    var jsonRequest = {"item_id": guideList[index].id, "item_type": "document"};
    loading(true);
    try {
      final model = BookmarkCommonModel.fromJson(json.decode(
        await apiService.dynamicPostRequest(
            body: jsonRequest, url: AppUrl.commonBookmarkApi),
      ));
      loading(false);
      if (model.status! && model.code == 200) {
        guideList[index].favourite = model.body?.id ?? "";
        guideList.refresh();
        UiHelper.showSuccessMsg(null, model.body?.message ?? "");
      }
    } catch (e, stack) {
      // Log any errors
      print("Error in getTips api: $e\n$stack");
    } finally {
      // Always hide the loading indicator
      loading(false);
    }
  }
}
