// Internal helpers shared across repositories and model factories.
//
// Centralised so that any future change (e.g. tightening the LIKE escape
// rules to also strip `*` for tsquery, or relaxing the string-list parser
// to coerce comma-separated text) is made in a single place.

/// Escape characters with special meaning inside Postgres `LIKE` / `ILIKE`
/// patterns.
///
/// Order matters: backslash MUST be replaced first so we don't double-
/// escape the escapes we add for `%` and `_`. Caller is expected to wrap
/// the result in `%...%` (or whichever wildcards they need) before
/// passing it to `client.from(...).ilike(...)`.
String escapeLike(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Parse a `dynamic` value from a Supabase JSON row into a non-null
/// `List<String>`. Postgres `text[]` columns come back as `List<dynamic>`
/// from PostgREST; null columns come back as `null`.
///
/// Returns an empty list for null / wrong-type inputs so callers can
/// always treat the result as non-nullable.
List<String> parseStringList(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) return value.map((e) => e.toString()).toList();
  return const <String>[];
}

/// Parse a `dynamic` value (typically from a JSON map) into a `double?`.
/// Accepts `int`, `double`, `num`, and numeric strings; returns `null`
/// for everything else so the caller can decide on a default.
double? numFromJson(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
