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

  static Future<dynamic>? navigateAndPopUntilFirstPage(Widget page) =>
      navigatorKey.currentState?.pushAndRemoveUntil(
        _materialPageRoute(page),
        (route) => route.isFirst,
      );

  static void pop() => navigatorKey.currentState?.pop();
  // ignore: strict_top_level_inference, type_annotate_public_apis
  static void popWithResult<T>(T? result) => navigatorKey.currentState?.pop<T>(result);

  static Route<dynamic> _materialPageRoute(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
