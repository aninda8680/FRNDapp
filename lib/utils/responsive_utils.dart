import 'package:flutter/widgets.dart';

extension ResponsiveContext on BuildContext {
  /// Returns a responsive height based on a base design height of 852 (e.g. iPhone 14 Pro)
  double responsiveHeight(double value) {
    final height = MediaQuery.of(this).size.height;
    return value * (height / 852.0);
  }

  /// Returns a responsive width based on a base design width of 393 (e.g. iPhone 14 Pro)
  double responsiveWidth(double value) {
    final width = MediaQuery.of(this).size.width;
    return value * (width / 393.0);
  }

  /// Bottom safe area padding
  double get bottomSafeArea => MediaQuery.of(this).padding.bottom;
  
  /// Top safe area padding
  double get topSafeArea => MediaQuery.of(this).padding.top;
}
