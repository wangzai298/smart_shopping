import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';

class ReviewSummaryCard extends ConsumerStatefulWidget {
  final String productId;
  const ReviewSummaryCard({super.key, required this.productId});

  @override
  ConsumerState<ReviewSummaryCard> createState() => _ReviewSummaryCardState();
}

class _ReviewSummaryCardState extends ConsumerState<ReviewSummaryCard> {
  Map<String, dynamic>? _reviews;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _reviews = await ref.read(apiServiceProvider).getReviews(widget.productId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
    if (_reviews == null) return const SizedBox.shrink();
    final pos = (_reviews!['positiveKeywords'] as List?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? [];
    final neg = (_reviews!['negativeKeywords'] as List?)?.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() ?? [];
    final summary = (_reviews!['summary'] as String?) ?? '';

    if (pos.isEmpty && neg.isEmpty && summary.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.reviews_outlined, size: 18),
              SizedBox(width: 8),
              Text('暂无评价', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('用户评价', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (pos.isNotEmpty) Wrap(spacing: 6, children: pos.map((k) => Chip(label: Text(k), backgroundColor: Colors.green.shade50)).toList()),
            if (neg.isNotEmpty) const SizedBox(height: 4),
            if (neg.isNotEmpty) Wrap(spacing: 6, children: neg.map((k) => Chip(label: Text(k), backgroundColor: Colors.red.shade50)).toList()),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(summary, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
