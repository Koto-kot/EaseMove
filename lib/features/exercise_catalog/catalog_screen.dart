/// Exercise list for one collection. Filtering is by explicit collection
/// membership — tags are for future recommendations only
/// (docs/TECHNICAL_SPEC.md 7).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
import '../../data/exercise_repository.dart';
import '../../domain/exercise/exercise.dart';
import '../../shared/widgets/exercise_card.dart';
import '../exercise_player/player_screen.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({required this.collectionId, super.key});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final AsyncValue<ExerciseRepository> repository = ref.watch(
      exerciseRepositoryProvider,
    );
    final bool showIds = ref.watch(settingsProvider).devShowIds;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          repository.maybeWhen(
            data: (ExerciseRepository repo) =>
                repo.bundle.collectionById(collectionId)?.title ?? collectionId,
            orElse: () => '',
          ),
        ),
      ),
      body: repository.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text(t('app.common.error'))),
        data: (ExerciseRepository repo) {
          final List<ExerciseSummary> exercises = repo.byCollection(
            collectionId,
          );
          if (exercises.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  t('app.catalog.empty'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 16),
            itemBuilder: (BuildContext context, int index) => ExerciseCard(
              summary: exercises[index],
              showId: showIds,
              onStart: () => _open(context, exercises[index]),
            ),
          );
        },
      ),
    );
  }

  /// Opens the player in SELECTED: the exercise waits for an explicit Start
  /// (docs/APP_STATE_MACHINE.md, invariant 3).
  void _open(BuildContext context, ExerciseSummary summary) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            PlayerScreen(exerciseId: summary.id, collectionId: collectionId),
      ),
    );
  }
}
