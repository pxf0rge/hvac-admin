import 'package:flutter/material.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';

enum ScreenSize { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static ScreenSize screenSizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.tablet) return ScreenSize.desktop;
    if (width >= AppBreakpoints.mobile) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    return switch (size) {
      ScreenSize.desktop => desktop ?? tablet ?? mobile,
      ScreenSize.tablet => tablet ?? mobile,
      ScreenSize.mobile => mobile,
    };
  }
}
