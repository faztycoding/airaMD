import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/repository_providers.dart';

/// The clinic's default laser/device list, seeded on first use. These are the
/// machines the client confirmed live under the Laser category.
const kDefaultLaserDevices = <String>[
  'Ulthera Prime',
  'Ultraformer III',
  'Oligio',
];

/// Active devices for the current clinic (used as quick-pick chips in the
/// treatment form).
final activeDevicesProvider = FutureProvider<List<ClinicDevice>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return const [];
  return ref.read(deviceRepoProvider).list(clinicId: clinicId);
});

/// Managed device list for Settings (includes inactive so OWNER can restore).
final clinicDevicesProvider =
    AsyncNotifierProvider<ClinicDevicesNotifier, List<ClinicDevice>>(
        ClinicDevicesNotifier.new);

class ClinicDevicesNotifier extends AsyncNotifier<List<ClinicDevice>> {
  @override
  Future<List<ClinicDevice>> build() async {
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) return const [];
    return ref.read(deviceRepoProvider).list(clinicId: clinicId, activeOnly: false);
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
    ref.invalidate(activeDevicesProvider);
  }

  Future<void> add({required String name, String category = 'LASER'}) async {
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) return;
    await ref.read(deviceRepoProvider).create(
          ClinicDevice(
            id: '',
            clinicId: clinicId,
            name: name,
            category: category,
          ),
        );
    await _reload();
  }

  Future<void> edit(ClinicDevice device) async {
    await ref.read(deviceRepoProvider).updateDevice(device);
    await _reload();
  }

  Future<void> remove(String id) async {
    await ref.read(deviceRepoProvider).deleteDevice(id);
    await _reload();
  }

  Future<void> seedDefaults() async {
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) return;
    final repo = ref.read(deviceRepoProvider);
    for (final name in kDefaultLaserDevices) {
      await repo.create(
        ClinicDevice(id: '', clinicId: clinicId, name: name, category: 'LASER'),
      );
    }
    await _reload();
  }
}
