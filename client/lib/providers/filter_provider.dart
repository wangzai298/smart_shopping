import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/filter.dart';
import '../services/api_service.dart';

final filterProvider =
    StateNotifierProvider<FilterNotifier, Filter>((ref) => FilterNotifier());

class FilterNotifier extends StateNotifier<Filter> {
  FilterNotifier() : super(Filter.defaultFilter());

  void applyFilter(Filter filter) {
    state = filter;
  }

  void resetFilter() {
    state = Filter.defaultFilter();
  }
}

final filterQueryProvider = StateProvider<String>((ref) => '');

final conversationIdProvider = StateProvider<String?>((ref) => null);

final nlpFilterProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return {'conversationId': null, 'filter': Filter.defaultFilter().toJson()};
  }
  final apiService = ref.read(apiServiceProvider);
  final conversationId = ref.read(conversationIdProvider);
  final result = await apiService.sendFilter(query, conversationId: conversationId);
  if (result['conversationId'] != null) {
    ref.read(conversationIdProvider.notifier).state = result['conversationId'] as String;
  }
  return result;
});
