abstract final class InventoryValidators {
  static String? positiveQuantity(String? value, {required String label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final parsed = int.tryParse(text);
    if (parsed == null) return '$label must be a whole number';
    if (parsed <= 0) return '$label must be greater than zero';
    return null;
  }
}
