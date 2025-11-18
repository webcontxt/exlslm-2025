import 'package:dreamcast/view/myFavourites/controller/favourite_controller.dart';
import 'package:get/get.dart';

import '../../exhibitors/controller/exhibitorsController.dart';
import '../../home/controller/for_you_controller.dart';

class FavouriteDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ForYouController>(ForYouController());
    Get.put<FavouriteController>(FavouriteController());
    Get.lazyPut(() => BoothController(), fenix: true);
  }
}
