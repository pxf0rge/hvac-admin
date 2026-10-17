import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/data/pagination/list_paging.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';

void main() {
  test('pageSlice returns empty page when offset exceeds source', () {
    final page = pageSlice(['a', 'b', 'c'], offset: 10, limit: 5);
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
    expect(page.nextOffset, isNull);
  });

  test('pageSlice marks hasMore when more rows exist', () {
    final page = pageSlice(List.generate(12, (i) => i), offset: 0, limit: 5);
    expect(page.items, [0, 1, 2, 3, 4]);
    expect(page.hasMore, isTrue);
    expect(page.nextOffset, 5);
  });

  test('pageSlice last page has no next offset', () {
    final page = pageSlice(List.generate(7, (i) => i), offset: 5, limit: 5);
    expect(page.items, [5, 6]);
    expect(page.hasMore, isFalse);
    expect(page.nextOffset, isNull);
  });

  test('matchesSearch is case-insensitive substring', () {
    expect(matchesSearch('77 Oak Lane', 'oak'), isTrue);
    expect(matchesSearch('77 Oak Lane', 'Main'), isFalse);
  });
}
