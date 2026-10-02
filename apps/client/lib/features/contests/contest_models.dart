import '../learning/study_catalog.dart';

sealed class MaterialBlock {
  const MaterialBlock(this.title);
  final String title;
}

class TextBlock extends MaterialBlock {
  const TextBlock(super.title, this.text);
  final String text;
}

class ListBlock extends MaterialBlock {
  const ListBlock(super.title, this.items);
  final List<String> items;
}

class ExampleBlock extends MaterialBlock {
  const ExampleBlock(
    super.title,
    this.problem,
    this.steps,
    this.answer,
    this.check,
  );
  final String problem, answer, check;
  final List<String> steps;
}

class FormulaVariable {
  const FormulaVariable(this.name, this.meaning, this.unit);
  final String name, meaning, unit;
}

class FormulaBlock extends MaterialBlock {
  const FormulaBlock(
    super.title,
    this.expression,
    this.variables,
    this.conditions,
  );
  final String expression;
  final List<FormulaVariable> variables;
  final List<String> conditions;
}

class TableBlock extends MaterialBlock {
  const TableBlock(super.title, this.columns, this.rows, this.caption);
  final List<String> columns;
  final List<List<String>> rows;
  final String caption;
}

class WritingTask {
  const WritingTask(
    this.id,
    this.title,
    this.prompt,
    this.motivatingText,
    this.planning,
    this.selfReview,
  );
  final String id, title, prompt, motivatingText;
  final List<String> planning, selfReview;
}

class CoverageRow {
  const CoverageRow(
    this.referenceItem,
    this.objectiveIndex,
    this.blockIndexes,
    this.exampleBlockIndex,
    this.questionIds,
    this.sourceUrls,
  );
  final String referenceItem;
  final int objectiveIndex, exampleBlockIndex;
  final List<int> blockIndexes;
  final List<String> questionIds, sourceUrls;
}

class ContestModule {
  const ContestModule({
    required this.id,
    required this.researchId,
    required this.title,
    required this.level,
    required this.summary,
    required this.objectives,
    required this.prerequisites,
    required this.blocks,
    required this.pitfalls,
    required this.recap,
    required this.retrieval,
    required this.notes,
    required this.suggestions,
    required this.sources,
    required this.updatedAt,
    required this.lessonIds,
    required this.questions,
    required this.writingTasks,
    required this.coverage,
  });
  final String id, researchId, title, level, summary, notes, updatedAt;
  final List<String> objectives,
      prerequisites,
      pitfalls,
      recap,
      retrieval,
      suggestions,
      lessonIds;
  final List<MaterialBlock> blocks;
  final List<StudySource> sources;
  final List<StudyQuestion> questions;
  final List<WritingTask> writingTasks;
  final List<CoverageRow> coverage;
}

class ContestDiscipline {
  const ContestDiscipline(
    this.id,
    this.title,
    this.summary,
    this.lessons,
    this.modules,
  );
  final String id, title, summary;
  final List<StudyLesson> lessons;
  final List<ContestModule> modules;
}

class ContestCourse {
  const ContestCourse(
    this.id,
    this.title,
    this.track,
    this.status,
    this.referenceDate,
    this.statusSources,
    this.syllabusSource,
  );
  final String id, title, track, status, referenceDate;
  final List<StudySource> statusSources;
  final StudySource syllabusSource;
}

class ContestLocation {
  const ContestLocation(this.discipline, this.module);
  final ContestDiscipline discipline;
  final ContestModule module;
}
