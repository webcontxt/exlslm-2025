import 'package:cached_network_image/cached_network_image.dart';
import 'package:dreamcast/api_repository/app_url.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/beforeLogin/splash/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({Key? key}) : super(key: key);
  static const routeName = "/";

  // Generate the image URL once per app session
  static final String _cachedImageUrl =
      "${AppUrl.splashDynamicImage}?t=${DateTime.now().millisecondsSinceEpoch}";

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: SplashController(),
        builder: (controller) {
          return SafeArea(
            child: Scaffold(
              body: Container(
                color: colorPrimary,
                width: context.width,
                height: context.height,
                child: Stack(
                  children: [
                    ///cached image it load the image one time till not changed if the url is the different.
                    ///its used to load the image first time.
                    CachedNetworkImage(
                        imageUrl: _cachedImageUrl,
                        imageBuilder: (context, imageProvider) => Container(
                              height: context.height,
                              width: context.width,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: imageProvider, fit: BoxFit.cover),
                              ),
                            ),
                        placeholder: (context, url) => Center(
                              child: Container(
                                height: context.height,
                                width: context.width,
                                color: Colors.black,
                              ),
                            ),
                        errorWidget: (context, url, error) => Container(
                              height: context.height,
                              width: context.width,
                              color: Colors.black,
                            )),
                  ],
                ),
              ),
            ),
          );
        });
  }

  ///This widget is used to show the bottom image and text in the splash screen.
  Widget buildBottomImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "powered_by".tr,
              style: TextStyle(
                  color: white, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ),
          SizedBox(
              height: 20.adaptSize,
              child: SvgPicture.asset(ImageConstant.dreamcast_logo)),
        ],
      ),
    );
  }
}
