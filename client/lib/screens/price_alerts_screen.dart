import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_widget.dart';

class PriceAlertsScreen extends ConsumerStatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  ConsumerState<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends ConsumerState<PriceAlertsScreen> {
  List<dynamic>? _alerts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isAuthError(Object e) => e is DioException && (e.response?.statusCode == 401);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _alerts = await ref.read(apiServiceProvider).getPriceAlerts();
    } catch (e) {
      if (_isAuthError(e) && mounted) {
        context.go('/login');
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(int id) async {
    await ref.read(apiServiceProvider).deletePriceAlert(id);
    _load();
  }

  Future<void> _edit(Map<String, dynamic> alert) async {
    final ctrl = TextEditingController(text: alert['targetPrice']?.toString() ?? '');
    final newPrice = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改目标价格'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '目标价格 (¥)', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (newPrice != null) {
      await ref.read(apiServiceProvider).updatePriceAlert(alert['id'] as int, {'targetPrice': newPrice});
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('降价提醒'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: _loading ? const LoadingWidget() :
        _alerts == null || _alerts!.isEmpty ? const EmptyWidget(message: '还没有降价提醒') :
        ListView.builder(
          itemCount: _alerts!.length,
          itemBuilder: (_, i) {
            final a = _alerts![i] as Map<String, dynamic>;
            return ListTile(
              leading: Icon(a['isActive'] == true ? Icons.notifications_active : Icons.notifications_off),
              title: Text('目标价 ¥${a['targetPrice']}'),
              subtitle: Text('商品: ${a['productId']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _edit(a)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _delete(a['id'] as int)),
                ],
              ),
            );
          },
        ),
    );
  }
}
