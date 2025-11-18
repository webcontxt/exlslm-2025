import 'package:dreamcast/view/photobooth/controller/photobooth_controller.dart';
import 'package:get/get.dart';

class PhotoBoothBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<PhotoBoothController>(PhotoBoothController());

  }
}
