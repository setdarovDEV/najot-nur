import 'package:flutter/material.dart';

/// Watermark o'chirilgan — child ni o'zgarishsiz o'tkazadi.
class SecurityWatermark extends StatelessWidget {
  const SecurityWatermark({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
