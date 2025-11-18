import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/view/beforeLogin/login/login_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/my_constant.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/ui_helper.dart';
import '../../../utils/Validations.dart';
import '../../../widgets/input_form_field.dart';

class LoginEmailWidget extends GetView<LoginController> {
  bool? isEmailType;
  bool isGuestForm;

  LoginEmailWidget(
      {super.key, required this.isGuestForm, required this.isEmailType});

  @override
  Widget build(BuildContext context) {
    return isEmailType == true
        ? InputFormField(
            controller: controller.emailCtr,
            isMobile: false,
            inputAction: TextInputAction.done,
            inputType: TextInputType.emailAddress,
            inputFormatters: Validations.emailFormatters,
            hintText: "loginId".tr,
            maxLength: 50,
            enableFocusBorderColor: colorGray,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return "enter_email_address".tr;
              } else if (!UiHelper.isEmail(value.toString())) {
                return "enter_valid_email_address".tr;
              } else {
                return null;
              }
            },
          )
        : Transform.translate(
      offset: Offset(-17.adaptSize, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    selectedCountryCode(),
                    Flexible(
                      flex: 1,
                      child: InputFormField(
                        controller: controller.emailCtr,
                        isMobile: true,
                        enableFocusBorderColor: defaultCheckboxColor,
                        inputAction: TextInputAction.done,
                        inputType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: Validations.mobileFormatters,
                        hintText: "Mobile Number",
                        maxLength: 15,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return "empty_mobile".tr;
                          } else if (!UiHelper.isNumber(value.toString())) {
                            return "enter_valid_mobile".tr;
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              Container(
                height: 4,
                width: double.infinity,
                margin: EdgeInsets.only(left: 37.adaptSize, right: 3.adaptSize),
                color: bottomLineColor.withOpacity(0.20),
              ),
            ],
          ),
        );
  }

  selectedCountryCode() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.translate(
          offset: const Offset(25, 1), // try -4, -6, -8 as needed
          child: CountryCodePicker(
            barrierColor: widgetBackgroundColor.withOpacity(0.7),
            backgroundColor: white,
            dialogBackgroundColor: white,
            padding: const EdgeInsets.all(0),
            margin: EdgeInsets.zero,
            headerText: "Select Country",
            textStyle: TextStyle(
              fontSize: 28.fSize,
              fontFamily: MyConstant.currentFont,
              color:  colorSecondary,
              fontWeight: FontWeight.w700,
            ),
            onChanged: (country) {
              controller.selectedCountryCode.value = country.dialCode ?? '+91';
              controller.selectedCountry.value = country.code ?? 'IN';
              },
            showDropDownButton: true,
            showFlag: false,
            initialSelection: controller.selectedCountryCode.value ?? 'IN',
            favorite: [
              controller.selectedCountryCode.value.isNotEmpty
                  ? controller.selectedCountryCode.value
                  : '+91',
              controller.selectedCountry.value.isNotEmpty
                  ? controller.selectedCountry.value
                  : 'IN',
            ],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 10.h, left: 0.h),
          height: 45.v,
          width: 1.5,
          color: defaultCheckboxColor,
        ),
      ],
    );
  }
}
