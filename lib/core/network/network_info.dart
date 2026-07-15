import 'dart:io';

// ponytail: check internet access using standard DNS lookup to avoid unneeded external dependencies
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('8.8.8.8').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on Object catch (_) {
      return false;
    }
  }
}
