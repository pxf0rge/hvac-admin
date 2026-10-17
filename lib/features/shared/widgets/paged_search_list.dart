import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hvac_admin/core/errors/failure_mapper.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/design_system/design_system.dart';

typedef PagedFetch<T> = Future<PagedResult<T>> Function(int offset, String query);

class PagedSearchList<T> extends StatefulWidget {
  const PagedSearchList({
    super.key,
    required this.fetchPage,
    required this.itemBuilder,
    required this.searchHint,
    this.emptyTitle = 'No results',
    this.emptyMessage = 'Nothing matches this search.',
    this.showSearch = true,
    this.listKey,
    this.header,
    this.refreshToken = 0,
    this.padding = EdgeInsets.zero,
  });

  final PagedFetch<T> fetchPage;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String searchHint;
  final String emptyTitle;
  final String emptyMessage;
  final bool showSearch;
  final Key? listKey;
  final Widget? header;
  final int refreshToken;
  final EdgeInsets padding;

  @override
  State<PagedSearchList<T>> createState() => _PagedSearchListState<T>();
}

class _PagedSearchListState<T> extends State<PagedSearchList<T>> {
  final _scrollController = ScrollController();
  final _items = <T>[];
  String _query = '';
  int _offset = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void didUpdateWidget(covariant PagedSearchList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final page = await widget.fetchPage(0, _query);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _offset = page.nextOffset ?? _items.length;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = FailureMapper.messageFor(error);
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.fetchPage(_offset, _query);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _offset = page.nextOffset ?? _items.length;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_query == value) return;
      setState(() => _query = value);
      _loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSearch) ...[
          AppSearchField(hint: widget.searchHint, onChanged: _onQueryChanged),
          const SizedBox(height: AppSpacing.md),
        ],
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: AppSpacing.md),
        ],
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          TextButton(onPressed: _loadInitial, child: const Text('Retry')),
          const SizedBox(height: AppSpacing.sm),
        ],
        Expanded(
          child: _loading && _items.isEmpty
              ? const LoadingState()
              : _items.isEmpty
                  ? EmptyState(title: widget.emptyTitle, message: widget.emptyMessage)
                  : ListView.separated(
                      key: widget.listKey,
                      controller: _scrollController,
                      padding: widget.padding,
                      itemCount: _items.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        return widget.itemBuilder(context, _items[index]);
                      },
                    ),
        ),
      ],
    );
  }
}
