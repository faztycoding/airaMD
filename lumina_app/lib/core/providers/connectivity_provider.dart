import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams the current connectivity status (online / offline).
/// Returns `true` when device has any network connection.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  // Map connectivity results to a simple boolean
  bool isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  // Controller that emits online/offline booleans
  final controller = StreamController<bool>();

  // Check immediately on subscribe
  connectivity.checkConnectivity().then((results) {
    if (!controller.isClosed) controller.add(isOnline(results));
  });

  // Listen to changes
  final sub = connectivity.onConnectivityChanged.listen((results) {
    if (!controller.isClosed) controller.add(isOnline(results));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});
