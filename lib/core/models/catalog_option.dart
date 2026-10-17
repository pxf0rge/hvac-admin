class CatalogOption {
  const CatalogOption({
    required this.key,
    required this.label,
    this.isSystem = false,
  });

  final String key;
  final String label;
  final bool isSystem;
}
