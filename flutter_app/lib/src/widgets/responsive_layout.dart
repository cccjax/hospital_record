import 'package:flutter/material.dart';

class ResponsiveLayout {
  const ResponsiveLayout._({
    required this.screenWidth,
    required this.isTablet,
    required this.useTwoPane,
    required this.listColumns,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.sectionGap,
    required this.blockGap,
  });

  final double screenWidth;
  final bool isTablet;
  final bool useTwoPane;
  final int listColumns;
  final double maxContentWidth;
  final double horizontalPadding;
  final double sectionGap;
  final double blockGap;

  static ResponsiveLayout fromWidth(double width) {
    final isTablet = width >= 700;
    final useTwoPane = width >= 1080;
    final listColumns = width >= 760 ? 2 : 1;
    final maxContentWidth = switch (width) {
      >= 1500 => 1260.0,
      >= 1180 => 1080.0,
      >= 700 => 940.0,
      _ => double.infinity,
    };
    final horizontalPadding = isTablet ? 18.0 : 12.0;
    final sectionGap = isTablet ? 16.0 : 12.0;
    final blockGap = isTablet ? 13.0 : 9.0;
    return ResponsiveLayout._(
      screenWidth: width,
      isTablet: isTablet,
      useTwoPane: useTwoPane,
      listColumns: listColumns,
      maxContentWidth: maxContentWidth,
      horizontalPadding: horizontalPadding,
      sectionGap: sectionGap,
      blockGap: blockGap,
    );
  }

  EdgeInsets listPadding({double top = 12, double bottom = 24}) {
    return EdgeInsets.fromLTRB(
        horizontalPadding, top, horizontalPadding, bottom);
  }

  double wrapItemWidth(double totalWidth, {double gap = 10}) {
    if (listColumns <= 1) return totalWidth;
    return (totalWidth - gap * (listColumns - 1)) / listColumns;
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
