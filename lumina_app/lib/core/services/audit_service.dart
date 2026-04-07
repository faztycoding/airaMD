import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/repository_providers.dart';
import '../providers/auth_providers.dart';

/// Convenience wrapper around AuditRepository for logging actions.
class AuditService {
  final Ref _ref;
  AuditService(this._ref);

  Future<void> log({
    required String action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      final clinicId = _ref.read(currentClinicIdProvider);
      if (clinicId == null) return;

      final repo = _ref.read(auditRepoProvider);
      await repo.logAction(
        clinicId: clinicId,
        action: action,
        entityType: entityType,
        entityId: entityId,
        oldData: oldData,
        newData: newData,
      );
    } catch (e) {
      // Non-blocking — audit logging should never break the main flow
      debugPrint('[AuditService] Error: $e');
    }
  }
}

/// Provider for the audit service.
final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(ref);
});
