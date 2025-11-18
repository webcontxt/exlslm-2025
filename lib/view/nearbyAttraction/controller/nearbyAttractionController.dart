import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import '../../../api_repository/api_service.dart';
import '../../../api_repository/app_url.dart';
import '../model/near_by_attrection_model.dart';

class NearbyAttractionController extends GetxController {
  var loading = false.obs;
  var isFirstLoading = false.obs;
  var itemList = <NearByData>[].obs;

  /// Called when the controller is initialized.
  ///
  /// Triggers the initial API data fetch for nearby attractions.
  @override
  void onInit() {
    super.onInit();
    getHubMenuAPi(isRefresh: false);
  }

  /// Fetches the list of nearby attractions from the API and updates the observable list.
  Future<void> getHubMenuAPi({required bool isRefresh}) async {
    try {
      isFirstLoading(!isRefresh);
      dynamic response =
          await apiService.dynamicGetRequest(url: AppUrl.nearByAttractions);
      NearByAttrectionModel model =
          NearByAttrectionModel.fromJson(json.decode(response));
      isFirstLoading(false);
      if (model.status! && model.code == 200) {
        itemList.clear();
        itemList.addAll(model.nearByData ?? []);
      }
    } catch (e) {
      print(e.toString());
      isFirstLoading(false);
    }
  }
}
