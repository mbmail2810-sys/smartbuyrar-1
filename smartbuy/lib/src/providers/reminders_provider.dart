import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder_model.dart';
import 'list_providers.dart';

final remindersProvider =
    StreamProvider.family<List<Reminder>, String>((ref, listId) {
  final repo = ref.watch(listRepositoryProvider);
  return repo.watchReminders(listId);
});
