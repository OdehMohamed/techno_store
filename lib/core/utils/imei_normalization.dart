/// IMEI/serial normalization for the ADR-007 Device Matching Policy's
/// exact-match pathway. Normalization (this file) is for comparison only
/// — it never changes what's stored as `imeiNumber` or shown to staff.
/// Deliberately no checksum or fixed-length validation: this shop
/// services devices beyond phones (see AppConstants' problem/accessory
/// lists), and imposing phone-specific rigor on evidence, not identity,
/// would incorrectly reject a legitimate non-phone serial number.
class ImeiNormalization {
  ImeiNormalization._();

  static final RegExp _separators = RegExp(r'[\s\-:]+');

  /// Trims, strips common separators (spaces, hyphens, colons — real IMEI
  /// display formats include grouped forms like `35-209900-176148-1`),
  /// and uppercases (a no-op for all-digit IMEIs, necessary for
  /// alphanumeric serials). Returns null for empty/whitespace-only input
  /// — absent evidence, never a matchable value: two devices both lacking
  /// a recorded IMEI must never be presented as matching each other.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final compact = raw.trim().replaceAll(_separators, '').toUpperCase();
    return compact.isEmpty ? null : compact;
  }
}
