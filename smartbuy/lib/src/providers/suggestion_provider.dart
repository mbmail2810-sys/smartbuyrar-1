import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_item.dart';
import '../services/suggestion_engine.dart';
import 'item_providers.dart';

final suggestionsProvider =
    Provider.family<List<GroceryItem>, String>((ref, listId) {
  final items = ref.watch(listItemsProvider(listId)).maybeWhen(
        data: (data) => data,
        orElse: () => <GroceryItem>[],
      );

  final ranked = [...items];
  ranked.sort((a, b) =>
      SuggestionEngine.score(b).compareTo(SuggestionEngine.score(a)));

  return ranked.take(5).toList();
});
