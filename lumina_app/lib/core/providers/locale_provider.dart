import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide locale provider for TH/EN switching.
final localeProvider = StateProvider<Locale>((ref) => const Locale('th', 'TH'));

/// Helper to check if current locale is Thai.
final isThaiProvider = Provider<bool>((ref) {
  return ref.watch(localeProvider).languageCode == 'th';
});
