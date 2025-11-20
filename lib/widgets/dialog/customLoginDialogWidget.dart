
import 'package:dreamcast/theme/app_colors.dart';
import 'package:dreamcast/utils/image_constant.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../textview/customTextView.dart';


class CustomLoginDialogWidget extends StatelessWidget {
  final String title, buttonCancel, buttonAction;
  final String description;
  final VoidCallback? onCancelTap, onActionTap;
  final bool? isHideCancelBtn;

  const CustomLoginDialogWidget(
      {super.key,
        required this.title,
        required this.description,
        required this.buttonCancel,
        required this.buttonAction,
        this.isHideCancelBtn,
        this.onCancelTap,
        this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: white,
          border: Border.all(color: white),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             Align(
                 alignment: Alignment.topRight,
                 child: InkWell(
                     onTap: ()=> Navigator.pop(context),
                     child: SvgPicture.asset(ImageConstant.close_popup, height: 35))),
              SizedBox(height: 10.v,),
              title.isNotEmpty
                  ? Padding(
                padding: const EdgeInsets.only( left: 9, right: 9),
                child: CustomTextView(
                  text: title,
                  textAlign: TextAlign.center,
                  fontSize: 20,
                  color: colorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : const SizedBox(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 9, right: 9),
                child: Html(
                  data: description ?? "",
                  style: {
                    "body": Style(
                      fontSize: FontSize(16.fSize),
                      color: colorSecondary,
                      fontWeight: FontWeight.normal,
                      textAlign: TextAlign.start,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                  },
                )
              ),
            ],
          ),
        ),
      ),
    );
  }


}
