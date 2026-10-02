import 'dart:convert';

import 'package:flutter/services.dart';

import '../learning/study_catalog.dart';
import 'contest_models.dart';
export 'contest_models.dart';

const _layout = <String, (String, int, int)>{
  'bancarios': ('b', 22, 23),
  'atualidades': ('a', 12, 15),
  'portugues': ('p', 13, 9),
  'matematica': ('m', 18, 11),
  'ingles': ('e', 8, 1),
  'vendas': ('v', 20, 17),
  'financeira': ('f', 7, 4),
  'informatica': ('i', 21, 14),
  'redacao': ('r', 5, 0),
};
Never _fail(String message) =>
    throw FormatException('Catálogo de concursos: $message');
Map<String, dynamic> _object(dynamic v) {
  if (v is! Map<String, dynamic>) _fail('objeto inválido');
  return v;
}

String _text(dynamic v) {
  if (v is! String || v.trim().isEmpty) _fail('texto vazio');
  return v;
}

List<T> _list<T>(dynamic v, T Function(dynamic) parse, {bool empty = false}) {
  if (v is! List || (!empty && v.isEmpty)) _fail('lista inválida');
  return List<T>.unmodifiable(v.map(parse));
}

void _unique(Iterable<Object> values) {
  final v = values.toList();
  if (v.toSet().length != v.length) _fail('valor duplicado');
}

int _int(dynamic v, {int min = 0, int max = 9007199254740991}) {
  if (v is! int || v < min || v > max) _fail('inteiro inválido');
  return v;
}

String _id(dynamic v) {
  final s = _text(v);
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(s)) _fail('ID inválido');
  return s;
}

String _date(dynamic v) {
  final s = _text(v);
  final d = DateTime.tryParse(s);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ||
      d == null ||
      d.toIso8601String().substring(0, 10) != s)
    _fail('data inválida');
  return s;
}

MaterialBlock _block(dynamic v) {
  final b = _object(v), title = _text(b['title']);
  switch (b['type']) {
    case 'text':
      return TextBlock(title, _text(b['text']));
    case 'list':
      return ListBlock(title, _list(b['items'], _text));
    case 'example':
      return ExampleBlock(
        title,
        _text(b['problem']),
        _list(b['steps'], _text),
        _text(b['answer']),
        _text(b['check']),
      );
    case 'formula':
      return FormulaBlock(
        title,
        _text(b['expression']),
        _list(b['variables'], (v) {
          final x = _object(v);
          return FormulaVariable(
            _text(x['name']),
            _text(x['meaning']),
            _text(x['unit']),
          );
        }),
        _list(b['conditions'], _text),
      );
    case 'table':
      final columns = _list(b['columns'], _text),
          rows = _list(b['rows'], (v) => _list(v, _text));
      if (rows.any((r) => r.length != columns.length))
        _fail('tabela irregular');
      return TableBlock(title, columns, rows, _text(b['caption']));
    default:
      return _fail('tipo de bloco desconhecido');
  }
}

WritingTask _writing(dynamic v) {
  final w = _object(v);
  return WritingTask(
    _id(w['id']),
    _text(w['title']),
    _text(w['prompt']),
    _text(w['motivatingText']),
    _list(w['planning'], _text),
    _list(w['selfReview'], _text),
  );
}

CoverageRow _coverage(dynamic v) {
  final c = _object(v);
  return CoverageRow(
    _text(c['referenceItem']),
    _int(c['objectiveIndex']),
    _list(c['blockIndexes'], _int),
    _int(c['exampleBlockIndex']),
    _list(c['questionIds'], _id),
    _list(c['sourceUrls'], _text),
  );
}

ContestCourse _course(dynamic v) {
  final c = _object(v);
  if (c['id'] != 'bb2026' || c['status'] != 'preparation')
    _fail('curso/status inválido');
  return ContestCourse(
    c['id'],
    _text(c['title']),
    _text(c['track']),
    c['status'],
    _date(c['referenceDate']),
    _list(c['statusSources'], StudySource.parse),
    StudySource.parse(c['syllabusSource']),
  );
}

List<String> _references(String id) {
  final n = _layout[id]!.$3;
  return id == 'redacao'
      ? [
          '7.3.3a',
          '7.3.3b',
          '7.3.3c',
          '7.3.3d',
          '7.3.3e',
          '7.3.4',
          '7.3.5',
          '7.3.6',
        ]
      : List.generate(n, (i) => '${i + 1}');
}

ContestDiscipline _discipline(dynamic v) {
  final d = _object(v),
      disciplineId = _id(d['id']),
      layout = _layout[disciplineId];
  if (layout == null) _fail('disciplina desconhecida');
  final lessons = _list(d['lessons'], StudyLesson.parse);
  if (lessons.length != 2 ||
      lessons.any((l) => !l.id.startsWith('bb2026-$disciplineId-')))
    _fail('aulas inválidas');
  _unique(lessons.map((l) => l.id));
  _unique(lessons.map((l) => l.videoId));
  final refs = _references(disciplineId), prefix = layout.$1, count = layout.$2;
  final modules = _list(d['modules'], (v) {
    final m = _object(v),
        moduleId = _id(m['id']),
        researchId = _text(m['researchId']);
    if (!RegExp('^bb2026-$prefix\\d{2}\$').hasMatch(moduleId) ||
        researchId != moduleId.substring(7).toUpperCase())
      _fail('módulo fora da disciplina');
    final objectives = _list(m['objectives'], _text),
        blocks = _list(m['blocks'], _block),
        questions = _list(m['questions'], StudyQuestion.parse),
        sources = _list(m['sources'], StudySource.parse),
        rows = _list(m['coverage'], _coverage),
        lessonIds = _list(m['lessonIds'], _id),
        writingTasks = _list(m['writingTasks'], _writing, empty: true),
        suggestions = _list(m['suggestions'], _text),
        notes = _text(m['notes']);
    if (questions.length != 6 ||
        suggestions.length != 3 ||
        notes.length > 4000 ||
        !blocks.any((b) => b is ExampleBlock))
      _fail('módulo incompleto');
    _unique(questions.map((q) => q.id));
    _unique(lessonIds);
    _unique(sources.map((s) => s.url));
    _unique(writingTasks.map((w) => w.id));
    if (questions.indexed.any(
          (q) =>
              q.$2.id != '$moduleId-q${(q.$1 + 1).toString().padLeft(2, '0')}',
        ) ||
        lessonIds.length > 2 ||
        lessonIds.any((l) => !lessons.any((x) => x.id == l)))
      _fail('vínculo de questão/aula inválido');
    final number = int.parse(moduleId.substring(moduleId.length - 2)),
        expectedWriting = disciplineId == 'redacao' ? (number == 5 ? 2 : 1) : 0;
    if (writingTasks.length != expectedWriting ||
        writingTasks.any((w) => !w.id.startsWith('$moduleId-')))
      _fail('tarefas de escrita inválidas');
    for (final c in rows) {
      _unique(c.blockIndexes);
      _unique(c.questionIds);
      _unique(c.sourceUrls);
      if (!refs.contains(c.referenceItem) ||
          c.objectiveIndex >= objectives.length ||
          c.blockIndexes.any(
            (i) => i >= blocks.length || blocks[i] is ExampleBlock,
          ) ||
          c.exampleBlockIndex >= blocks.length ||
          blocks[c.exampleBlockIndex] is! ExampleBlock ||
          c.questionIds.any((q) => !questions.any((x) => x.id == q)) ||
          c.sourceUrls.any((u) => !sources.any((s) => s.url == u)))
        _fail('cobertura com vínculo inválido');
    }
    if (objectives.indexed.any(
          (o) => !rows.any((c) => c.objectiveIndex == o.$1),
        ) ||
        questions.any((q) => !rows.any((c) => c.questionIds.contains(q.id))))
      _fail('objetivo/prática sem cobertura');
    return ContestModule(
      id: moduleId,
      researchId: researchId,
      title: _text(m['title']),
      level: _text(m['level']),
      summary: _text(m['summary']),
      objectives: objectives,
      prerequisites: _list(m['prerequisites'], _text, empty: true),
      blocks: blocks,
      pitfalls: _list(m['pitfalls'], _text),
      recap: _list(m['recap'], _text),
      retrieval: _list(m['retrieval'], _text),
      notes: notes,
      suggestions: suggestions,
      sources: sources,
      updatedAt: _date(m['updatedAt']),
      lessonIds: lessonIds,
      questions: questions,
      writingTasks: writingTasks,
      coverage: rows,
    );
  });
  if (modules.length != count ||
      modules.indexed.any(
        (m) =>
            m.$2.id != 'bb2026-$prefix${(m.$1 + 1).toString().padLeft(2, '0')}',
      ))
    _fail('sequência de módulos incompleta');
  if (refs.any(
    (item) =>
        !modules.any((m) => m.coverage.any((c) => c.referenceItem == item)),
  ))
    _fail('item histórico ausente');
  return ContestDiscipline(
    disciplineId,
    _text(d['title']),
    _text(d['summary']),
    lessons,
    modules,
  );
}

class ContestCatalog {
  const ContestCatalog(this.catalogVersion, this.course, this.disciplines);
  final int catalogVersion;
  final ContestCourse course;
  final List<ContestDiscipline> disciplines;
  factory ContestCatalog.fromJson(Map<String, dynamic> root) {
    if (root['schemaVersion'] != 1) _fail('schema inválido');
    final version = _int(root['catalogVersion'], min: 1),
        course = _course(root['course']),
        disciplines = _list(root['disciplines'], _discipline);
    if (disciplines.length != 9) _fail('nove disciplinas exigidas');
    _unique(disciplines.map((d) => d.id));
    _unique(disciplines.expand((d) => d.lessons).map((l) => l.id));
    _unique(disciplines.expand((d) => d.lessons).map((l) => l.videoId));
    return ContestCatalog(version, course, disciplines);
  }
  ContestDiscipline? findDiscipline(String id) {
    for (final d in disciplines) {
      if (d.id == id) return d;
    }
    return null;
  }

  ContestLocation? find(String topicId) {
    for (final d in disciplines) {
      for (final m in d.modules) {
        if (m.id == topicId) return ContestLocation(d, m);
      }
    }
    return null;
  }
}

Future<ContestCatalog> loadContestCatalog(AssetBundle bundle) async =>
    ContestCatalog.fromJson(
      _object(
        jsonDecode(
          await bundle.loadString('assets/contests/bb2026/catalog.json'),
        ),
      ),
    );
