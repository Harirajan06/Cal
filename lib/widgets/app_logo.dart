import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/app.svg',
      height: size,
      width: size,
      // The SVG already contains branding colors and a black background.
      // We avoid srcIn filter to preserve the complex neon gradients.
    );
  }
}
