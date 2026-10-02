import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contests/contest_catalog.dart';
import 'learning_controller.dart';
import 'learning_entry.dart';

final contestCatalogProvider = FutureProvider<ContestCatalog>(
  (ref) => loadContestCatalog(rootBundle),
  retry: (retryCount, error) => null,
);
final learningEntryProvider =
    Provider.family<AsyncValue<LearningEntry?>, String>((ref, id) {
      if (id.startsWith('bb2026-')) {
        return ref.watch(contestCatalogProvider).whenData((catalog) {
          final location = catalog.find(id);
          return location == null
              ? null
              : LearningEntry.fromContest(catalog, location);
        });
      }
      return ref.watch(catalogProvider).whenData((catalog) {
        final topic = catalog.find(id);
        return topic == null
            ? null
            : LearningEntry.fromFree(topic, catalog.catalogVersion);
      });
    });
