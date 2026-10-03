import 'package:flutter/material.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // ওভারস্ক্রল ইন্ডিকেটর (গ্লো/শ্যাডো) সম্পূর্ণ বন্ধ
    return child;
  }
}