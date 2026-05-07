import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/repositories/repository_exceptions.dart';

void main() {
  group('RepositoryException — typed hierarchy', () {
    test('InsufficientStockException carries optional product name', () {
      const ex = InsufficientStockException(productName: 'Botox 50U');
      expect(ex, isA<RepositoryException>());
      expect(ex.message, 'insufficient_stock');
      expect(ex.productName, 'Botox 50U');
    });

    test('InvalidQuantityException is distinct from insufficient stock', () {
      const ex = InvalidQuantityException();
      expect(ex, isA<RepositoryException>());
      expect(ex, isNot(isA<InsufficientStockException>()));
      expect(ex.message, 'quantity_must_be_positive');
    });

    test('NotFoundException carries the missing resource type', () {
      const ex = NotFoundException('product');
      expect(ex.resource, 'product');
      expect(ex.message, 'not_found:product');
    });

    test('VersionConflictException is its own subtype', () {
      const ex = VersionConflictException();
      expect(ex, isA<RepositoryException>());
      expect(ex, isNot(isA<InsufficientStockException>()));
      expect(ex.message, 'version_conflict');
    });

    test('MissingContextException encodes the missing resource', () {
      const ex = MissingContextException('clinic_id');
      expect(ex, isA<RepositoryException>());
      expect(ex.resource, 'clinic_id');
      expect(ex.message, 'missing_context:clinic_id');
    });

    test('RenderFailureException is distinguishable from network errors', () {
      const ex = RenderFailureException();
      expect(ex, isA<RepositoryException>());
      expect(ex, isNot(isA<UnknownRepositoryException>()));
      expect(ex.message, 'render_failure');
    });

    test('DomainValidationException carries a localised message verbatim', () {
      const ex = DomainValidationException('ยังไม่ได้วาด Diagram');
      expect(ex, isA<RepositoryException>());
      expect(ex.message, 'ยังไม่ได้วาด Diagram');
    });

    test('callers can switch on the sealed hierarchy', () {
      RepositoryException pickError(int code) {
        switch (code) {
          case 1:
            return const InsufficientStockException(productName: 'Filler');
          case 2:
            return const InvalidQuantityException();
          case 3:
            return const VersionConflictException();
          default:
            return const NotFoundException('patient');
        }
      }

      // Exhaustive switch over the sealed family — would fail to compile if
      // a new subtype were added without updating this matcher, which is the
      // entire point of using sealed classes.
      String tagFor(RepositoryException e) {
        return switch (e) {
          InsufficientStockException() => 'stock',
          InvalidQuantityException() => 'qty',
          VersionConflictException() => 'version',
          NotFoundException() => 'missing',
          UnknownRepositoryException() => 'unknown',
          MissingContextException() => 'context',
          RenderFailureException() => 'render',
          DomainValidationException() => 'validation',
        };
      }

      expect(tagFor(pickError(1)), 'stock');
      expect(tagFor(pickError(2)), 'qty');
      expect(tagFor(pickError(3)), 'version');
      expect(tagFor(pickError(99)), 'missing');
    });
  });
}
