import 'package:dreamcast/widgets/textview/customTextView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_colors.dart';
class LoadMoreLoading extends StatelessWidget {
  const LoadMoreLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeIn,
      child: _animatedCard(context),
    );
  }

  Widget _animatedCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorPrimary.withOpacity(0.2),
                          blurRadius: 10, // reduced blur for smaller glow
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 15, // reduced size
                      width: 15, // reduced size
                      child: CircularProgressIndicator(
                        strokeWidth: 1, // thinner stroke
                        valueColor: AlwaysStoppedAnimation<Color>(colorPrimary),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // reduced spacing
                  CustomTextView(
                    text: "Loading..",
                    fontSize: 13, // smaller font
                    fontWeight: FontWeight.normal,
                    color: colorPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
