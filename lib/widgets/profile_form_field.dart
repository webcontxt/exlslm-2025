import 'package:country_code_picker/country_code_picker.dart';
import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_decoration.dart';
import '../theme/ui_helper.dart';
import '../view/account/model/createProfileModel.dart';
import '../view/profileSetup/controller/profileSetupController.dart';

class ProfileInputFormField extends GetView<EditProfileController> {
  ProfileFieldData profileFieldData;
  String? mobileCode;
  ProfileInputFormField({super.key, required this.profileFieldData,this.mobileCode});

  @override
  Widget build(BuildContext context) {
    return buildEditText(profileFieldData);
  }

  Widget buildEditText(ProfileFieldData createFieldBody) {
    final TextEditingController textAreaController = TextEditingController(
      text: createFieldBody.value ?? '',
    );

    // Helper method to determine maxLength based on validationAs
    int getMaxLength() {
      if (createFieldBody.name.toString().contains('email')) return 50;
      if (createFieldBody.name.toString().contains('Mobile') ||
          createFieldBody.name.toString().contains('alternative_mobile'))
        return 12;
      if (createFieldBody.name.toString().contains('website')) return 200;
      return 50;
    }

    // Helper method to determine keyboardType based on validationAs
    TextInputType getKeyboardType() {
      if (createFieldBody.name.toString().contains('email')) {
        return TextInputType.emailAddress;
      }
      if (createFieldBody.name.toString().contains('Mobile landline')) {
        return TextInputType.phone;
      }
      return TextInputType.text;
    }

    // Helper method to get the label text
    String getLabelText() {
      return '${createFieldBody.label} ${createFieldBody.rules.toString().contains("required") ? "*" : ""}';
    }

    // Simplified validation logic
    String? validator(String? value) {
      final rules = createFieldBody.rules?.toString() ?? '';
      final name = createFieldBody.name?.capitalize ?? '';

      if (rules.contains('required') && (value == null || value.isEmpty)) {
        return '$name required';
      }

      if ((value != null && value!.isNotEmpty) && value.length < 2) {
        return 'Please enter valid ${createFieldBody.name}';
      }

      if (createFieldBody.name?.contains('email') == true &&
          !UiHelper.isEmail(value ?? '')) {
        return 'enter_valid_email_address'.tr;
      }

      if (createFieldBody.name?.contains('Mobile') == true &&
          !UiHelper.isValidPhoneNumber(value ?? '')) {
        return 'enter_valid_mobile'.tr;
      }

      if (createFieldBody.name?.contains('website') == true &&
          !UiHelper.isValidWebsiteUrl(value ?? '')) {
        return 'enter_valid_website_url'.tr;
      }

      return null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.start,
        textAlignVertical: TextAlignVertical.top,
        controller: textAreaController,
        enabled: !(createFieldBody.readonly ?? false),
        maxLength: getMaxLength(),
        keyboardType: getKeyboardType(),
        style: AppDecoration.setTextStyle(
            fontSize: 15.fSize,
            color: colorSecondary,
            fontWeight: FontWeight.normal),
        validator: validator,
        onChanged: (value) {
          createFieldBody.value = value.isNotEmpty ? value : '';
        },
        decoration: InputDecoration(
          counter: const Offstage(),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
          labelText: getLabelText(),
          hintText: createFieldBody.placeholder ?? "",
          hintStyle: AppDecoration.setTextStyle(
              fontSize: 15.fSize,
              color: colorGray,
              fontWeight: FontWeight.normal),
          labelStyle: AppDecoration.setTextStyle(
              fontSize: 15.fSize,
              color: colorGray,
              fontWeight: FontWeight.normal),
          fillColor:
          createFieldBody.readonly == true ? colorLightGray : white,
          filled: true,
          prefix: createFieldBody.name == "mobile"
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  selectedCountryCode(),
                ],
              ),
            ],
          )
              : const SizedBox(),
          prefixIconConstraints: const BoxConstraints(minWidth: 60),
          enabledBorder: createFieldBody.isAiFormField == true
              ? AppDecoration.editBoxGradientBorder()
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:BorderSide(color: borderColor),
                ),
          focusedBorder: createFieldBody.isAiFormField == true
              ? AppDecoration.editBoxGradientBorder()
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:BorderSide(color: borderColor),
                ),
          errorBorder: createFieldBody.isAiFormField == true
              ? AppDecoration.editBoxGradientBorder()
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
          border: createFieldBody.isAiFormField == true
              ? AppDecoration.editBoxGradientBorder()
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black),
                ),
          disabledBorder: createFieldBody.isAiFormField == true
              ? AppDecoration.editBoxGradientBorder()
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:BorderSide(color: borderColor),
                ),
        ),
      ),
    );
  }




  selectedCountryCode() {
    String countryCode = getCountryIsoFromDialCode(controller.selectedCountryCode.value ?? '');
    if(countryCode != null && countryCode.isNotEmpty && countryCode !="null"){
      controller.selectedCountry.value = countryCode ?? '';
    }else{
      controller.selectedCountry.value = '';
      controller.selectedCountryCode.value = "";
    }
    return CountryCodePicker(
      barrierColor: widgetBackgroundColor.withOpacity(0.7),
      backgroundColor: white,
      dialogBackgroundColor: white,
      padding: const EdgeInsets.all(0),
      // flagWidth: 0.adaptSize,
      headerText: "Select Country",
      textStyle: TextStyle(
        fontSize: 15.fSize,
        fontFamily: MyConstant.currentFont,
        color: colorSecondary,
        fontWeight: FontWeight.w400,
      ),
      onChanged: (country) {
        // print(country.dialCode);
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
      // alignLeft: true,
    );

  }


  String getCountryIsoFromDialCode(String dialCode) {
    if(dialCode.isEmpty || dialCode == null){
      return "";
    }
    // This will return a single CountryCode object for the dial code
    final country = CountryCode.fromDialCode(dialCode);
    // Fallback to IN if null
    return country.code ?? 'IN';
  }


}
