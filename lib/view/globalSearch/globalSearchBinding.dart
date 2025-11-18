import 'package:dreamcast/view/Notes/controller/my_notes_controller.dart';
import 'package:dreamcast/view/exhibitors/controller/exhibitorsController.dart';
import 'package:dreamcast/view/globalSearch/controller/globalSearchTabController.dart';
import 'package:dreamcast/view/representatives/controller/networkingController.dart';
import 'package:get/get.dart';
import '../representatives/controller/user_detail_controller.dart';
import '../schedule/controller/session_controller.dart';
import '../speakers/controller/speakerNetworkController.dart';
import '../speakers/controller/speakersController.dart';

class GlobalSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GlobalSearchTabController());
    Get.lazyPut(() => UserDetailController(), fenix: true);
    Get.lazyPut(() => SessionController(), fenix: true);
    Get.lazyPut(() => BoothController(), fenix: true);
    Get.lazyPut(() => SpeakersDetailController(), fenix: true);
  }
}
