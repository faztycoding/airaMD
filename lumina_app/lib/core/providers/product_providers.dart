import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'repository_providers.dart';
import 'auth_providers.dart';

/// All active products for current clinic.
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(productRepoProvider);
  return repo.list(clinicId: clinicId);
});

/// Products by category.
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, ProductCategory>((ref, cat) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(productRepoProvider);
  return repo.getByCategory(clinicId: clinicId, category: cat);
});

/// Low stock products.
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(productRepoProvider);
  return repo.getLowStock(clinicId);
});

/// All active services for current clinic.
final serviceListProvider = FutureProvider<List<Service>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(serviceRepoProvider);
  return repo.list(clinicId: clinicId);
});

/// Services by category.
final servicesByCategoryProvider =
    FutureProvider.family<List<Service>, ServiceCategory>((ref, cat) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(serviceRepoProvider);
  return repo.getByCategory(clinicId: clinicId, category: cat);
});
