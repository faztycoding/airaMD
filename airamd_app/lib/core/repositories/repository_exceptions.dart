// Typed exceptions raised by repositories.
//
// Using sealed classes lets the UI / service layer differentiate failure
// modes without parsing string error messages, and keeps localisation /
// retry decisions pure.

sealed class RepositoryException implements Exception {
  final String message;
  final Object? cause;
  const RepositoryException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Stock deduction failed because requested quantity exceeds available stock.
class InsufficientStockException extends RepositoryException {
  /// Optional product name for nicer user-facing messages.
  final String? productName;
  const InsufficientStockException({this.productName, Object? cause})
      : super('insufficient_stock', cause);
}

/// Quantity / amount input was non-positive when it had to be > 0.
class InvalidQuantityException extends RepositoryException {
  const InvalidQuantityException([Object? cause])
      : super('quantity_must_be_positive', cause);
}

/// The referenced row could not be found (e.g. product, patient, treatment).
class NotFoundException extends RepositoryException {
  final String resource;
  const NotFoundException(this.resource, [Object? cause])
      : super('not_found:$resource', cause);
}

/// Optimistic-concurrency mismatch — caller's `version` did not match the
/// current row in the database. Refetch and retry.
class VersionConflictException extends RepositoryException {
  const VersionConflictException([Object? cause])
      : super('version_conflict', cause);
}

/// Unknown / unmapped backend error. Wraps the original error so callers can
/// still inspect / log it but cannot match on string content.
class UnknownRepositoryException extends RepositoryException {
  const UnknownRepositoryException(super.message, [super.cause]);
}

/// A required runtime context (clinic id, current user, current clinic role)
/// is missing — usually means the auth/session bootstrap hasn't finished or
/// has been invalidated. Callers should redirect to login or surface a
/// "no clinic selected" UI rather than crashing.
class MissingContextException extends RepositoryException {
  /// Logical name of the missing piece, e.g. `clinic_id`, `staff`.
  final String resource;
  const MissingContextException(this.resource, [Object? cause])
      : super('missing_context:$resource', cause);
}

/// An on-device image / canvas → bytes conversion failed (PNG render,
/// `toByteData`, etc.). Distinct from network/storage errors so the UI can
/// retry locally instead of falling through to the offline queue.
class RenderFailureException extends RepositoryException {
  const RenderFailureException([Object? cause])
      : super('render_failure', cause);
}

/// User input failed a domain-level validation rule that cannot be expressed
/// purely as a form-validator (e.g. "draw at least one diagram view"). The
/// `message` carries a human-readable, optionally localised reason that the
/// UI can surface verbatim.
class DomainValidationException extends RepositoryException {
  const DomainValidationException(super.message, [super.cause]);
}
