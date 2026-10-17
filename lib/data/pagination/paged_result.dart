/// Shared list query for repository pagination.
class ListQuery {
  const ListQuery({
    this.offset = 0,
    this.limit = 50,
    this.search,
  });

  final int offset;
  final int limit;
  final String? search;

  static const defaultLimit = 50;
}

/// Page of domain rows plus cursor for the next request.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    this.nextOffset,
    required this.hasMore,
  });

  final List<T> items;
  final int? nextOffset;
  final bool hasMore;

  int get count => items.length;
}
