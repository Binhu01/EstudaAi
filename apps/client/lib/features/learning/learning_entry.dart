import '../contests/contest_catalog.dart';
import '../contests/contest_models.dart';
import 'study_catalog.dart';

enum LearningArea { freeStudy, contest }

class LearningEntry {
  const LearningEntry._({
    required this.topic,
    required this.area,
    required this.contentVersion,
    required this.suggestions,
    this.courseId,
    this.courseTitle,
    this.disciplineId,
    this.contestLocation,
    this.referenceDate,
  });
  final StudyTopic topic;
  final LearningArea area;
  final int contentVersion;
  final List<String> suggestions;
  final String? courseId, courseTitle, disciplineId, referenceDate;
  final ContestLocation? contestLocation;
  factory LearningEntry.fromFree(StudyTopic topic, int contentVersion) =>
      LearningEntry._(
        topic: topic,
        area: LearningArea.freeStudy,
        contentVersion: contentVersion,
        suggestions: List.unmodifiable([
          'Explique ${topic.title} com um exemplo.',
          'Como posso resolver uma questão deste assunto?',
          'Como uso as aulas e os desafios da plataforma?',
        ]),
      );
  factory LearningEntry.fromContest(
    ContestCatalog catalog,
    ContestLocation location,
  ) {
    final m = location.module, d = location.discipline;
    return LearningEntry._(
      topic: StudyTopic(
        m.id,
        m.title,
        d.title,
        m.level,
        m.summary,
        m.notes,
        m.sources,
        List.unmodifiable(
          m.lessonIds.map((id) => d.lessons.firstWhere((l) => l.id == id)),
        ),
        m.questions,
      ),
      area: LearningArea.contest,
      contentVersion: catalog.catalogVersion,
      suggestions: m.suggestions,
      courseId: catalog.course.id,
      courseTitle: catalog.course.title,
      disciplineId: d.id,
      contestLocation: location,
      referenceDate: catalog.course.referenceDate,
    );
  }
}
