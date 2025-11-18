import 'dart:io';

import 'package:dreamcast/routes/my_constant.dart';
import 'package:dreamcast/utils/Validations.dart';
import 'package:dreamcast/utils/size_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dreamcast/theme/app_colors.dart';

import 'package:auto_size_text_field/auto_size_text_field.dart';

class InputFormField extends StatelessWidget {
  final String hintText;
  final bool isMobile;
  final int maxLength;
  final IconData icon;
  final String inputExperssion;
  final TextInputType inputType;
  final Color? enableFocusBorderColor;
  final TextEditingController controller;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction inputAction;
  final FormFieldValidator<String> validator;
  final int minLines;
  final int? maxLines;

  const InputFormField({
    Key? key,
    this.inputExperssion = "",
    this.isMobile = false,
    this.inputFormatters,
    this.enableFocusBorderColor,
    required this.controller,
    required this.inputAction,
    required this.inputType,
    required this.hintText,
    this.maxLength = 50,
    this.icon = Icons.person,
    required this.validator,
    this.minLines = 1,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutoSizeTextField(
      controller: controller,
      minFontSize: 12,
      maxLines: 1,
      fullwidth: true,
      textAlign: TextAlign.center,
      textInputAction: inputAction,
      keyboardType: inputType,
      inputFormatters: inputFormatters == null
          ? []
          : [
              ...?inputFormatters,
              FilteringTextInputFormatter.deny(
                  RegExp(Validations.regexToRemoveEmoji))
            ],
      style: TextStyle(
        fontSize: 34.fSize,
        color: colorSecondary,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: defaultCheckboxColor,
      decoration: InputDecoration(
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        filled: true,
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: defaultCheckboxColor.withOpacity(0.39),
            width: 4.0,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: defaultCheckboxColor.withOpacity(0.39),
            width: 4.0,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: defaultCheckboxColor.withOpacity(0.39),
            width: 4.0,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: defaultCheckboxColor.withOpacity(0.39),
            width: 4.0,
          ),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: defaultCheckboxColor.withOpacity(0.39),
            width: 4.0,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: defaultCheckboxColor.withOpacity(0.39),
            width: 4.0,
          ),
        ),
        hintStyle: TextStyle(
          color: defaultCheckboxColor,
          fontWeight: FontWeight.w700,
          fontSize: 34.fSize,
        ),
        hintText: hintText,
        fillColor: Colors.transparent,
      ),
    );
  }
}

class InputFormFieldMobile extends StatelessWidget {
  final String hintText;
  final bool isMobile;
  final int maxLength;
  final IconData icon;
  final String inputExperssion;
  final TextInputType inputType;
  final TextEditingController controller;
  final TextInputAction inputAction;
  final FormFieldValidator<String> validator;

  const InputFormFieldMobile({
    Key? key,
    this.inputExperssion = "",
    this.isMobile = false,
    required this.controller,
    required this.inputAction,
    required this.inputType,
    required this.hintText,
    this.maxLength = 50,
    this.icon = Icons.person,
    required this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enableSuggestions: false, autocorrect: false, autofocus: false,
      controller: controller,
      textInputAction: inputAction,
      //keyboardType: inputType,
      maxLength: maxLength,
      validator: validator, textAlign: TextAlign.start,
      keyboardType:
          const TextInputType.numberWithOptions(signed: true, decimal: true),
      //maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
          fontSize: 30,
          fontFamily: MyConstant.currentFont,
          fontWeight: FontWeight.bold),
      cursorColor: colorSecondary,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.fromLTRB(isMobile ? 15 : 15, 15, 15, 15),
        filled: true,
        hintStyle: TextStyle(
            color: colorLightGray, fontFamily: MyConstant.currentFont),
        hintText: hintText, /*fillColor: Colors.white70*/
      ),
    );
  }
}
