enum GlobalSearchKind { customer, property, job, equipment, invoice }

extension GlobalSearchKindX on GlobalSearchKind {
  String get sectionTitle => switch (this) {
        GlobalSearchKind.customer => 'Customers',
        GlobalSearchKind.property => 'Properties',
        GlobalSearchKind.job => 'Jobs',
        GlobalSearchKind.equipment => 'Equipment',
        GlobalSearchKind.invoice => 'Invoices',
      };

  String get tileMeta => switch (this) {
        GlobalSearchKind.customer => 'Customer',
        GlobalSearchKind.property => 'Property',
        GlobalSearchKind.job => 'Job',
        GlobalSearchKind.equipment => 'Equipment',
        GlobalSearchKind.invoice => 'Invoice',
      };
}

class GlobalSearchHit {
  const GlobalSearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final GlobalSearchKind kind;
  final String id;
  final String title;
  final String subtitle;
  final String route;
}
