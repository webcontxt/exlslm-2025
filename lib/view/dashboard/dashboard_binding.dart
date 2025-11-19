import 'package:dreamcast/view/eventFeed/controller/eventFeedController.dart';
import 'package:dreamcast/view/menu/controller/menuController.dart';
import 'package:dreamcast/view/photobooth/controller/photobooth_controller.dart';
import 'package:get/get.dart';
import 'package:dreamcast/view/home/controller/home_controller.dart';
import '../account/controller/account_controller.dart';
import '../alert/controller/alert_controller.dart';
import '../breifcase/controller/common_document_controller.dart';
import '../support/controller/faq_controller.dart';
import '../support/controller/helpdesk_dashboard_controller.dart';
import 'dashboard_controller.dart';
import 'deep_linking_controller.dart';

class RootBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DashboardController>(DashboardController());
    Get.lazyPut<HelpdeskDashboardController>(() => HelpdeskDashboardController());
    Get.lazyPut<SOSFaqController>(() => SOSFaqController());
    Get.put<HomeController>(HomeController());
    Get.put<DeepLinkingController>(DeepLinkingController());
    Get.lazyPut<HubController>(() => HubController());
    Get.put<CommonDocumentController>(CommonDocumentController());
    Get.put<EventFeedController>(EventFeedController());
    Get.put<AccountController>(AccountController());
    Get.put<PhotoBoothController>(PhotoBoothController());
    Get.put<AlertController>(AlertController());


    //Get.lazyPut<LoginController>(() => LoginController());
  }
}
