import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isHeader;

  const AppLogo({super.key, this.size = 100, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Choose color based on theme (Black for light, White for dark)
    final Color iconColor = isDark ? Colors.white : Colors.black;

    return FaIcon(FontAwesomeIcons.appleWhole, size: size, color: iconColor);
  }
}
