import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

// ponytail: lightweight logger to output to both console (for profile mode) and developer timeline
void logOcr(String message, {required String name}) {
  if (!kReleaseMode) {
    debugPrint('[$name] $message');
    developer.log(message, name: name);
  }
}
