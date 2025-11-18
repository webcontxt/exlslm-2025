import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_decoration.dart';
class GradientBorderCircle extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double borderWidth;

  const GradientBorderCircle({
    Key? key,
    required this.imageUrl,
    this.size = 100.0,
    this.borderWidth = 5.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppDecoration.aiRoundedBoxDecoration,
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: white, // Background color inside the gradient border
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 50);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}
