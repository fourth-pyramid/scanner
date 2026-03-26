// import 'package:qrscanner/core/utils/app_logger.dart';

// /// Performance monitoring utility for tracking operation timings and metrics.
// ///
// /// Usage:
// /// ```dart
// /// // Simple timing
// /// final timer = PerformanceMonitor.start('OperationName');
// /// await doSomething();
// /// timer.stop();
// ///
// /// // With context
// /// final timer = PerformanceMonitor.start('APICall', context: {'endpoint': '/scan'});
// /// final result = await apiCall();
// /// timer.stop(metrics: {'responseSize': result.length});
// ///
// /// // Async wrapper
// /// final result = await PerformanceMonitor.measureAsync(
// ///   'DatabaseQuery',
// ///   () => database.query(),
// /// );
// /// ```
// class PerformanceMonitor {
//   final String operationName;
//   final DateTime _startTime;
//   final Map<String, dynamic>? _context;
//   bool _stopped = false;

//   PerformanceMonitor._(this.operationName, this._startTime, this._context);

//   /// Start timing an operation
//   ///
//   /// [operationName] - Descriptive name of the operation being timed
//   /// [context] - Optional context data to log with the operation
//   ///
//   /// Returns a PerformanceMonitor instance. Call `.stop()` when done.
//   static PerformanceMonitor start(
//     String operationName, {
//     Map<String, dynamic>? context,
//   }) {
//     final timer = PerformanceMonitor._(operationName, DateTime.now(), context);

//     AppLogger.debug(
//       'PerformanceMonitor',
//       'start',
//       'Started timing: $operationName',
//       data: context,
//     );

//     return timer;
//   }

//   /// Stop timing and log the duration
//   ///
//   /// [metrics] - Optional additional metrics to log with the result
//   ///
//   /// Returns the duration of the operation
//   Duration stop({Map<String, dynamic>? metrics}) {
//     if (_stopped) {
//       AppLogger.warning(
//         'PerformanceMonitor',
//         'stop',
//         'Timer already stopped for: $operationName',
//       );
//       return Duration.zero;
//     }

//     _stopped = true;
//     final duration = DateTime.now().difference(_startTime);

//     final allMetrics = <String, dynamic>{
//       if (_context != null) ..._context,
//       if (metrics != null) ...metrics,
//     };

//     AppLogger.performance(
//       operationName,
//       duration,
//       metrics: allMetrics.isNotEmpty ? allMetrics : null,
//     );

//     return duration;
//   }

//   /// Measure an async operation and automatically log timing
//   ///
//   /// [operationName] - Descriptive name of the operation
//   /// [operation] - The async function to measure
//   /// [context] - Optional context data
//   ///
//   /// Returns the result of the operation
//   static Future<T> measureAsync<T>(
//     String operationName,
//     Future<T> Function() operation, {
//     Map<String, dynamic>? context,
//   }) async {
//     final timer = start(operationName, context: context);

//     try {
//       final result = await operation();
//       timer.stop();
//       return result;
//     } catch (e) {
//       timer.stop(metrics: {'error': e.toString()});
//       rethrow;
//     }
//   }

//   /// Measure a synchronous operation and automatically log timing
//   ///
//   /// [operationName] - Descriptive name of the operation
//   /// [operation] - The function to measure
//   /// [context] - Optional context data
//   ///
//   /// Returns the result of the operation
//   static T measureSync<T>(
//     String operationName,
//     T Function() operation, {
//     Map<String, dynamic>? context,
//   }) {
//     final timer = start(operationName, context: context);

//     try {
//       final result = operation();
//       timer.stop();
//       return result;
//     } catch (e) {
//       timer.stop(metrics: {'error': e.toString()});
//       rethrow;
//     }
//   }

//   /// Performance threshold constants for common operations
//   static const Duration networkRequestThreshold = Duration(seconds: 3);
//   static const Duration databaseQueryThreshold = Duration(milliseconds: 500);
//   static const Duration imageProcessingThreshold = Duration(seconds: 5);
//   static const Duration uiRenderThreshold = Duration(milliseconds: 16); // 60fps

//   /// Check if duration exceeds threshold and log warning if so
//   ///
//   /// [operationName] - Name of the operation
//   /// [duration] - Duration to check
//   /// [threshold] - Threshold to compare against
//   static void checkThreshold(
//     String operationName,
//     Duration duration,
//     Duration threshold,
//   ) {
//     if (duration > threshold) {
//       AppLogger.warning(
//         'PerformanceMonitor',
//         'checkThreshold',
//         '$operationName exceeded threshold: ${duration.inMilliseconds}ms > ${threshold.inMilliseconds}ms',
//         data: {
//           'operation': operationName,
//           'duration_ms': duration.inMilliseconds,
//           'threshold_ms': threshold.inMilliseconds,
//           'exceeded_by_ms': (duration - threshold).inMilliseconds,
//         },
//       );
//     }
//   }
// }
