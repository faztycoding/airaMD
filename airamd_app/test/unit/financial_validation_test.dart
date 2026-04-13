import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/features/financial/financial_validation.dart';

void main() {
  group('Financial amount validation', () {
    test('returns empty issue for blank amount', () {
      expect(
        validateFinancialAmount('   '),
        FinancialAmountValidationIssue.empty,
      );
    });

    test('returns invalid issue for non numeric amount', () {
      expect(
        validateFinancialAmount('abc'),
        FinancialAmountValidationIssue.invalid,
      );
    });

    test('returns non positive issue for zero or negative amount', () {
      expect(
        validateFinancialAmount('0'),
        FinancialAmountValidationIssue.nonPositive,
      );
      expect(
        validateFinancialAmount('-50'),
        FinancialAmountValidationIssue.nonPositive,
      );
    });

    test('returns exceeds limit issue for amounts over 10 million', () {
      expect(
        validateFinancialAmount('10000001'),
        FinancialAmountValidationIssue.exceedsLimit,
      );
    });

    test('accepts valid positive amount within limit', () {
      expect(validateFinancialAmount('1250.50'), isNull);
      expect(validateFinancialAmount('10000000'), isNull);
    });

    test('parses valid positive amount', () {
      expect(parseFinancialAmount('1250.50'), 1250.5);
    });
  });
}
