import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_widget.dart';

class SearchHistoryScreen extends ConsumerStatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  ConsumerState<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends ConsumerState<SearchHistoryScreen> {
  List<dynamic>? _items;
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
      _items = await ref.read(apiServiceProvider).getSearchHistory();
    } catch (e) {
      if (_isAuthError(e) && mounted) {
        context.go('/login');
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _clearAll() async {
    await ref.read(apiServiceProvider).clearSearchHistory();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索历史'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearAll)],
      ),
      body: _loading ? const LoadingWidget() :
        _items == null || _items!.isEmpty ? const EmptyWidget(message: '还没有搜索记录') :
        ListView.builder(
          itemCount: _items!.length,
          itemBuilder: (_, i) {
            final item = _items![i] as Map<String, dynamic>;
            final date = item['createdAt']?.toString().substring(0, 10) ?? '';
            return ListTile(
              leading: const Icon(Icons.search),
              title: Text('搜索记录 ${item['id']}'),
              subtitle: Text(date),
            );
          },
        ),
    );
  }
}
