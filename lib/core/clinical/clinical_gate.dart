/// One place that decides whether an exercise may be shown.
///
/// docs/SAFETY_AND_CLINICAL_REVIEW.md + TECHNICAL_SPEC 6: production shows only
/// `clinical.status: approved`. This must stay a single function — scattered
/// conditions are how unapproved content leaks into a release.
library;

import '../../domain/exercise/exercise.dart';
import '../config/feature_flags.dart';

class ClinicalGate {
  const ClinicalGate(this.flags);

  final FeatureFlags flags;

  bool canRender(ClinicalStatus status) {
    if (status == ClinicalStatus.retired) return false;
    if (status == ClinicalStatus.approved) return true;
    if (flags.approvedContentOnly) return false;
    return flags.showPendingReviewContent &&
        status == ClinicalStatus.pendingReview;
  }

  bool canRenderExercise(Exercise exercise) =>
      canRender(exercise.clinicalStatus);

  bool canRenderSummary(ExerciseSummary summary) =>
      canRender(summary.clinicalStatus);
}
