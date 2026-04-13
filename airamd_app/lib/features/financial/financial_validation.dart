enum FinancialAmountValidationIssue {
  empty,
  invalid,
  nonPositive,
  exceedsLimit,
}

FinancialAmountValidationIssue? validateFinancialAmount(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return FinancialAmountValidationIssue.empty;

  final amount = double.tryParse(trimmed);
  if (amount == null) return FinancialAmountValidationIssue.invalid;
  if (amount <= 0) return FinancialAmountValidationIssue.nonPositive;
  if (amount > 10000000) return FinancialAmountValidationIssue.exceedsLimit;

  return null;
}

double parseFinancialAmount(String raw) {
  return double.parse(raw.trim());
}
