import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'textview/customTextView.dart';

class CompanyPositionWidget extends StatelessWidget {
  String company;
  String position;
  CompanyPositionWidget(
      {super.key, required this.company, required this.position});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        company.isNotEmpty
            ? CustomTextView(
            maxLines: 4,
            fontSize: 16,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.normal,
            color: colorGray,
            text: company)
            : const SizedBox(),
        position.isNotEmpty
            ? CustomTextView(
                maxLines: 4,
                fontSize: 16,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.w600,
                color: colorGray,
                text: position)
            : const SizedBox(),
      ],
    );
  }
}
