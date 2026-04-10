import 'package:flutter/material.dart';

class ResponsiveLayout {
  const ResponsiveLayout._({
    required this.screenWidth,
    required this.isTablet,
    required this.useTwoPane,
    required this.maxContentWidth,
    required this.horizontalPadding,
  });

  final double screenWidth;
  final bool isTablet;
  final bool useTwoPane;
  final double maxContentWidth;
  final double horizontalPadding;

  static ResponsiveLayout fromWidth(double width) {
    final isTablet = width >= 700;
    final useTwoPane = width >= 1024;
    final maxContentWidth = switch (width) {
      >= 1400 => 1180.0,
      >= 1100 => 1020.0,
      >= 700 => 860.0,
      _ => double.infinity,
    };
    final horizontalPadding = isTablet ? 20.0 : 12.0;
    return ResponsiveLayout._(
      screenWidth: width,
      isTablet: isTablet,
      useTwoPane: useTwoPane,
      maxContentWidth: maxContentWidth,
      horizontalPadding: horizontalPadding,
    );
  }

  EdgeInsets listPadding({double top = 12, double bottom = 24}) {
    return EdgeInsets.fromLTRB(
        horizontalPadding, top, horizontalPadding, bottom);
  }
}

class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.layout,
    required this.child,
  });

  final ResponsiveLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (layout.maxContentWidth == double.infinity) {
      return child;
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
        child: child,
      ),
    );
  }
}
