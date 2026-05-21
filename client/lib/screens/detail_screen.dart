import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/app_error_widget.dart';
import '../widgets/empty_widget.dart';
import 'results_screen/widgets/price_trend_chart.dart';
import 'results_screen/widgets/review_summary_card.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const DetailScreen({super.key, required this.productId});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
  }

  Future<_DetailData> _loadDetail() async {
    final api = ref.read(apiServiceProvider);
    final history = await api.fetchHistory(widget.productId);
    return _DetailData.fromJson(history);
  }

  void _retry() {
    setState(() {
      _future = _loadDetail();
    });
  }

  void _showPriceAlertDialog(BuildContext context) {
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置降价提醒'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '目标价格 (¥)',
            hintText: '当价格低于此值时通知我',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final price = double.tryParse(priceCtrl.text);
              if (price != null && price > 0) {
                try {
                  await ref.read(apiServiceProvider).createPriceAlert({
                    'productId': widget.productId,
                    'targetPrice': price,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已设置降价提醒: 低于 ¥${price.toStringAsFixed(0)} 时通知')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设置失败: $e')));
                  }
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: '加载商品详情...');
          }
          if (snapshot.hasError) {
            return AppErrorWidget(
              message: '加载失败: ${snapshot.error}',
              onRetry: _retry,
            );
          }
          final data = snapshot.data;
          if (data == null || data.platforms.isEmpty) {
            return const EmptyWidget(message: '暂无价格数据');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前各平台价格',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...data.platforms.entries.map((entry) {
                  final prices = entry.value;
                  final latest =
                      prices.isNotEmpty ? prices.last.price : 0.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            entry.key,
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          Text(
                            '¥${latest.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('设置降价提醒'),
                    onPressed: () => _showPriceAlertDialog(context),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '历史价格趋势',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                PriceTrendChart(
                  platformData: data.platforms,
                  lowestPrice: data.lowestPrice,
                ),
                const SizedBox(height: 24),
                // Reviews
                ReviewSummaryCard(productId: widget.productId),
                const SizedBox(height: 24),
                Text(
                  '价格明细',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...data.platforms.entries.map((entry) {
                  return _PlatformHistoryCard(
                    platform: entry.key,
                    points: entry.value,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlatformHistoryCard extends StatelessWidget {
  final String platform;
  final List<PricePoint> points;

  const _PlatformHistoryCard({
    required this.platform,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              platform,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...points.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      Text(
                        '¥${p.price.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DetailData {
  final String productId;
  final Map<String, List<PricePoint>> platforms;
  final Map<String, dynamic>? lowestPrice;

  const _DetailData({required this.productId, required this.platforms, this.lowestPrice});

  factory _DetailData.fromJson(Map<String, dynamic> json) {
    final platforms = <String, List<PricePoint>>{};
    final raw = json['platforms'] as Map<String, dynamic>? ?? {};
    for (final entry in raw.entries) {
      final list = (entry.value as List<dynamic>?)
              ?.map((e) => PricePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      platforms[entry.key] = list;
    }
    return _DetailData(
      productId: json['productId'] as String? ?? '',
      platforms: platforms,
      lowestPrice: json['lowestPrice'] as Map<String, dynamic>?,
    );
  }
}
