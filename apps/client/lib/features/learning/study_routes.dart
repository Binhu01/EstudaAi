import 'learning_entry.dart';

enum StudyAction { material, lessons, quiz, steve }

class StudyRoutes {
  static String path(LearningEntry entry, StudyAction action) {
    if (entry.area == LearningArea.contest) {
      final suffix = switch (action) {
        StudyAction.material => 'material',
        StudyAction.lessons => 'aulas',
        StudyAction.quiz => 'desafio',
        StudyAction.steve => 'steve',
      };
      return '/concursos/${entry.courseId}/${entry.disciplineId}/${entry.topic.id}/$suffix';
    }
    final prefix = switch (action) {
      StudyAction.material || StudyAction.lessons => 'aprender',
      StudyAction.quiz => 'desafios',
      StudyAction.steve => 'steve',
    };
    return '/$prefix/${entry.topic.id}';
  }
}
