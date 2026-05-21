import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/camera_service.dart';
import '../providers/search_provider.dart';
import '../widgets/loading_widget.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickFromCamera() async {
    final result = await ref.read(cameraServiceProvider).pickFromCamera();
    switch (result.result) {
      case PickResult.success:
        setState(() => _selectedImage = result.file);
      case PickResult.cancelled:
        // User chose not to take a photo — do nothing.
        break;
      case PickResult.permissionDenied:
        _showPermissionDeniedDialog('相机');
      case PickResult.error:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('拍照失败: ${result.errorMessage}')),
          );
        }
    }
  }

  Future<void> _pickFromGallery() async {
    final result = await ref.read(cameraServiceProvider).pickFromGallery();
    switch (result.result) {
      case PickResult.success:
        setState(() => _selectedImage = result.file);
      case PickResult.cancelled:
        break;
      case PickResult.permissionDenied:
        _showPermissionDeniedDialog('相册');
      case PickResult.error:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('选图失败: ${result.errorMessage}')),
          );
        }
    }
  }

  void _showPermissionDeniedDialog(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
        title: const Text('权限未开启'),
        content: Text(
          '无法访问$feature。\n\n'
          '请在系统设置中为「识物比价」开启${feature}权限：\n\n'
          '设置 → 应用 → 识物比价 → 权限管理 → $feature\n\n'
          '开启后返回本页面重试。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndUpload() async {
    if (_selectedImage == null) return;
    setState(() => _isUploading = true);
    try {
      final base64 = await ref
          .read(cameraServiceProvider)
          .compressAndEncode(_selectedImage!);
      if (mounted) {
        await ref.read(searchProvider.notifier).search([base64]);
      }
      if (mounted) {
        context.push('/results');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('识别失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _retake() {
    setState(() => _selectedImage = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照识物'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isUploading
          ? const LoadingWidget(message: '正在识别...')
          : _selectedImage != null
              ? _buildPreview(theme)
              : _buildPicker(theme),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            child: Center(
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retake,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重拍'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _confirmAndUpload,
                    icon: const Icon(Icons.check),
                    label: const Text('确认上传'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPicker(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '拍照或选择商品图片',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PickerButton(
                icon: Icons.camera_alt,
                label: '拍照',
                onTap: _pickFromCamera,
              ),
              const SizedBox(width: 24),
              _PickerButton(
                icon: Icons.photo_library,
                label: '相册',
                onTap: _pickFromGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
