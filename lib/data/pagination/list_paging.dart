import 'package:hvac_admin/data/pagination/paged_result.dart';

PagedResult<T> pageSlice<T>(
  List<T> source, {
  required int offset,
  required int limit,
}) {
  if (offset < 0) offset = 0;
  if (limit < 1) limit = ListQuery.defaultLimit;
  if (offset >= source.length) {
    return const PagedResult(items: [], hasMore: false);
  }
  final end = (offset + limit + 1).clamp(0, source.length);
  final slice = source.sublist(offset, end);
  final hasMore = slice.length > limit;
  final items = hasMore ? slice.sublist(0, limit) : slice;
  return PagedResult(
    items: items,
    nextOffset: hasMore ? offset + limit : null,
    hasMore: hasMore,
  );
}

bool matchesSearch(String haystack, String? needle) {
  final q = needle?.trim().toLowerCase();
  if (q == null || q.isEmpty) return true;
  return haystack.toLowerCase().contains(q);
}
