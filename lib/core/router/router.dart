// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Route<dynamic>? onGenerateRoute(RouteSettings settings) => null;

class MagicRouter {
  static BuildContext get currentContext => navigatorKey.currentContext!;

  static Future<dynamic>? navigateTo(Widget page) =>
      navigatorKey.currentState?.push(_materialPageRoute(page));

  static Future<dynamic>? navigateToReplacment(Widget page) =>
      navigatorKey.currentState?.pushReplacement(_materialPageRoute(page));

  static Future<dynamic>? navigateAndPopAll(Widget page) => navigatorKey
      .currentState
      ?.pushAndRemoveUntil(_materialPageRoute(page), (_) => false);

  // ponytail: removed unused navigateAndPopUntilFirstPage
  
  static void pop() => navigatorKey.currentState?.pop();
  
  // ponytail: removed unused popWithResult

  static Route<dynamic> _materialPageRoute(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
