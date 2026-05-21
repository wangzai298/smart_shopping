import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../services/api_service.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isFavorited = false;
  bool _favoriteLoading = false;

  Future<void> _toggleFavorite() async {
    if (_favoriteLoading) return;

    final api = ref.read(apiServiceProvider);

    // Load existing lists and show bottom sheet
    setState(() => _favoriteLoading = true);
    List<dynamic> lists;
    try {
      lists = await api.getFavoriteLists();
    } catch (_) {
      lists = [];
    }
    if (mounted) setState(() => _favoriteLoading = false);
    if (!mounted) return;

    // Show bottom sheet
    final selectedId = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _FavoriteSheet(
        lists: lists.cast<Map<String, dynamic>>().toList(),
        productId: widget.product.id,
        api: api,
      ),
    );

    if (selectedId != null && mounted) {
      setState(() => _isFavorited = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已收藏', textAlign: TextAlign.center), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with favorite button
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _toggleFavorite,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _favoriteLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Icon(
                                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorited ? Colors.red : Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '最低 ¥${widget.product.lowestPrice.toStringAsFixed(0)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  ...widget.product.platformPrices.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Text(
                              p.platform,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '¥${p.price.toStringAsFixed(0)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: p.price == widget.product.lowestPrice
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          const Spacer(),
                          _ShopTypeChip(shopType: p.shopType),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorite selection bottom sheet ──

class _FavoriteSheet extends StatefulWidget {
  final List<Map<String, dynamic>> lists;
  final String productId;
  final ApiService api;

  const _FavoriteSheet({required this.lists, required this.productId, required this.api});

  @override
  State<_FavoriteSheet> createState() => _FavoriteSheetState();
}

class _FavoriteSheetState extends State<_FavoriteSheet> {
  bool _loading = false;
  String _newListName = '';

  Future<int> _addTo(int listId) async {
    setState(() => _loading = true);
    try {
      await widget.api.addFavoriteItem(listId, widget.productId);
      return listId;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('添加失败: $e')));
      }
      return -1;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int> _createAndAdd() async {
    final name = _newListName.trim();
    if (name.isEmpty) return -1;
    setState(() => _loading = true);
    try {
      final created = await widget.api.createFavoriteList(name);
      final listId = created['id'] as int;
      await widget.api.addFavoriteItem(listId, widget.productId);
      return listId;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
      return -1;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('添加到收藏夹', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // Existing lists
            if (widget.lists.isNotEmpty) ...[
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.lists.length,
                  itemBuilder: (_, i) {
                    final list = widget.lists[i];
                    return ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(list['name']?.toString() ?? ''),
                      subtitle: Text('${list['itemCount'] ?? 0} 件'),
                      trailing: const Icon(Icons.add_circle_outline),
                      enabled: !_loading,
                      onTap: () async {
                        final result = await _addTo(list['id'] as int);
                        if (result > 0 && context.mounted) Navigator.of(context).pop(result);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
            ],
            // New list
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '新建文件夹名称',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _newListName = v,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading || _newListName.trim().isEmpty ? null : () async {
                    final result = await _createAndAdd();
                    if (result > 0 && context.mounted) Navigator.of(context).pop(result);
                  },
                  child: const Text('新建并添加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ShopTypeChip extends StatelessWidget {
  final String shopType;
  const _ShopTypeChip({required this.shopType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;

    switch (shopType) {
      case '旗舰店':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
      case '自营':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
      default:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        shopType,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
