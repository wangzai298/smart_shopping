import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_widget.dart';
import '../widgets/app_error_widget.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<dynamic>? _lists;
  List<dynamic>? _items;
  int? _expandedListId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isAuthError(Object e) => e is DioException && (e.response?.statusCode == 401);

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _lists = await ref.read(apiServiceProvider).getFavoriteLists();
    } catch (e) {
      if (_isAuthError(e) && mounted) { context.go('/login'); return; }
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadItems(int listId) async {
    try {
      _items = await ref.read(apiServiceProvider).getFavoriteItems(listId);
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _createList() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建清单'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '清单名称'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('创建')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(apiServiceProvider).createFavoriteList(name);
      _load();
    }
  }

  Future<void> _removeItem(int itemId) async {
    await ref.read(apiServiceProvider).deleteFavoriteItem(itemId);
    if (_expandedListId != null) {
      await _loadItems(_expandedListId!);
      setState(() {});
    }
    _load();
  }

  Future<void> _deleteList(int id) async {
    await ref.read(apiServiceProvider).deleteFavoriteList(id);
    if (_expandedListId == id) {
      _expandedListId = null;
      _items = null;
    }
    _load();
  }

  void _toggleExpand(int listId) async {
    if (_expandedListId == listId) {
      setState(() { _expandedListId = null; _items = null; });
    } else {
      setState(() => _expandedListId = listId);
      await _loadItems(listId);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏夹'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      floatingActionButton: FloatingActionButton(onPressed: _createList, child: const Icon(Icons.add)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingWidget(message: '加载收藏...');
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    if (_lists == null || _lists!.isEmpty) return const EmptyWidget(message: '还没有收藏清单\n点击右下角创建');

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.builder(
        itemCount: _lists!.length,
        itemBuilder: (_, i) {
        final list = _lists![i] as Map<String, dynamic>;
        final listId = list['id'] as int;
        final isExpanded = _expandedListId == listId;
        return Column(
          children: [
            ListTile(
              leading: Icon(isExpanded ? Icons.folder_open : Icons.folder_outlined),
              title: Text(list['name']?.toString() ?? ''),
              subtitle: Text('${list['itemCount'] ?? 0} 件商品'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _deleteList(listId)),
                ],
              ),
              onTap: () => _toggleExpand(listId),
            ),
            if (isExpanded) _buildItems(),
            const Divider(height: 1),
          ],
        );
      },
    ),
    );
  }

  Widget _buildItems() {
    if (_items == null) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
    if (_items!.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('该清单还没有商品', style: TextStyle(color: Colors.grey)));
    return Column(
      children: _items!.map((item) {
        final itemMap = item as Map<String, dynamic>;
        final itemId = itemMap['id'] as int;
        final productId = itemMap['productId'] as String? ?? '';
        return ListTile(
          leading: const Icon(Icons.shopping_bag_outlined, size: 20),
          title: Text(productId, style: const TextStyle(fontSize: 13)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: () => _removeItem(itemId)),
          onTap: () => context.push('/detail/$productId'),
        );
      }).toList(),
    );
  }
}
