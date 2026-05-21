import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          Text(user?.nickname ?? '未登录', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text(user?.phone ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('我的收藏'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/favorites'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('搜索历史'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/search-history'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('降价提醒'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/price-alerts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
