/// Formats display text only; IDs, stored values and gameplay stay unchanged.
String persianDigits(Object value) {
  const digits = '۰۱۲۳۴۵۶۷۸۹';
  return value.toString().replaceAllMapped(
    RegExp('[0-9]'),
    (match) => digits[int.parse(match[0]!)],
  );
}
