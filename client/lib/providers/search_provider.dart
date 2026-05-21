import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

final searchProvider =
    AsyncNotifierProvider<SearchNotifier, List<Product>>(SearchNotifier.new);

class SearchNotifier extends AsyncNotifier<List<Product>> {
  List<String>? _lastImages;

  @override
  Future<List<Product>> build() async => [];

  Future<void> search(List<String> images) async {
    _lastImages = images;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.uploadImage(images);
    });
  }

  Future<void> refresh() async {
    if (_lastImages == null || _lastImages!.isEmpty) return;
    state = await AsyncValue.guard(() async {
      final apiService = ref.read(apiServiceProvider);
      return await apiService.uploadImage(_lastImages!);
    });
  }

  void clear() {
    _lastImages = null;
    state = const AsyncValue.data([]);
  }
}
