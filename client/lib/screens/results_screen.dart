import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import '../models/filter.dart';
import '../providers/search_provider.dart';
import '../providers/filter_provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/app_error_widget.dart';
import '../widgets/empty_widget.dart';
import 'results_screen/widgets/product_card.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final _filterController = TextEditingController();
  String _activeQuery = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<Product> _applyFilter(List<Product> products, Filter filter) {
    var list = products.toList();

    // Filter by shopType: keep products that have at least one matching platform
    if (filter.shopType != null) {
      list = list
          .where((p) => p.platformPrices.any(
                (pp) => pp.shopType == filter.shopType,
              ))
          .toList();
    }

    // Filter by price range on lowestPrice
    if (filter.priceRange != null) {
      final range = filter.priceRange!;
      list = list
          .where((p) =>
              p.lowestPrice >= range.min && p.lowestPrice <= range.max)
          .toList();
    }

    // Sort
    switch (filter.sort) {
      case 'price_asc':
        list.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
      case 'price_desc':
        list.sort((a, b) => b.lowestPrice.compareTo(a.lowestPrice));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchProvider);
    final currentFilter = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('比价结果'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (searchAsync is AsyncData && searchAsync.value?.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: '重置筛选',
              onPressed: () {
                ref.read(filterProvider.notifier).resetFilter();
                _filterController.clear();
                setState(() => _activeQuery = '');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // NLP filter input
          _buildFilterBar(context),
          const Divider(height: 1),
          // Results
          Expanded(child: _buildBody(searchAsync, currentFilter)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: '输入筛选条件，如"要便宜点的"',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _activeQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _filterController.clear();
                          setState(() => _activeQuery = '');
                          ref.read(filterProvider.notifier).resetFilter();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() => _activeQuery = value.trim());
                  _applyNlpFilter(value.trim());
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _activeQuery.isEmpty
                ? null
                : () {
                    final value = _filterController.text.trim();
                    if (value.isNotEmpty) {
                      setState(() => _activeQuery = value);
                      _applyNlpFilter(value);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SizedBox(
            height: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 140, color: Colors.white),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 200, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 100, color: Colors.white),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(height: 12, width: 60, color: Colors.white),
                          Container(height: 12, width: 50, color: Colors.white),
                          Container(height: 12, width: 40, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Product>> async, Filter filter) {
    return async.when(
      loading: () => _buildShimmerSkeleton(),
      error: (error, _) => RefreshIndicator(
        onRefresh: () async => ref.read(searchProvider.notifier).refresh(),
        child: ListView(
          children: [SizedBox(height: 200, child: AppErrorWidget(
            message: '加载失败: $error',
            onRetry: () => ref.read(searchProvider.notifier).refresh(),
          ))],
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const EmptyWidget(message: '未找到匹配的商品');
        }

        final filtered = _applyFilter(products, filter);

        if (filtered.isEmpty) {
          return EmptyWidget(
            icon: Icons.filter_list_off,
            message: '当前筛选条件下无匹配商品\n请尝试调整筛选条件',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.read(searchProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return ProductCard(
                product: product,
                onTap: () => context.push('/detail/${product.id}'),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _applyNlpFilter(String query) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final conversationId = ref.read(conversationIdProvider);
      final result = await apiService.sendFilter(query, conversationId: conversationId);
      final filterJson = result['filter'] as Map<String, dynamic>?;
      if (filterJson != null) {
        ref.read(filterProvider.notifier).applyFilter(Filter.fromJson(filterJson));
      }
      if (result['conversationId'] != null) {
        ref.read(conversationIdProvider.notifier).state = result['conversationId'] as String;
      }
    } catch (_) {
      // If NLP fails, keep current filter
    }
  }
}
