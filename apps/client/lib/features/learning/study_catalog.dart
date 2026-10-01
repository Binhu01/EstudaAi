import 'dart:convert';

import 'package:flutter/services.dart';

Map<String, dynamic> _object(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Objeto inválido');
  }
  return value;
}

String _text(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Texto inválido');
  }
  return value;
}

String _id(dynamic value) {
  final id = _text(value);
  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
    throw const FormatException('ID inválido');
  }
  return id;
}

List<T> _list<T>(dynamic value, T Function(dynamic) parse) {
  if (value is! List || value.isEmpty) {
    throw const FormatException('Lista inválida');
  }
  return List<T>.unmodifiable(value.map(parse));
}

void _unique(Iterable<String> values) {
  final list = values.toList();
  if (list.toSet().length != list.length) {
    throw const FormatException('Valor duplicado');
  }
}

class StudySource {
  const StudySource(this.title, this.url);
  final String title, url;
  factory StudySource.parse(dynamic value) {
    final s = _object(value);
    final url = _text(s['url']);
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Fonte insegura');
    }
    return StudySource(_text(s['title']), url);
  }
}

class StudyLesson {
  const StudyLesson(
    this.id,
    this.title,
    this.channel,
    this.description,
    this.level,
    this.videoId,
  );
  final String id, title, channel, description, level, videoId;
  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
  factory StudyLesson.parse(dynamic value) {
    final l = _object(value);
    final video = _text(l['videoId']);
    if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(video)) {
      throw const FormatException('Vídeo inválido');
    }
    return StudyLesson(
      _id(l['id']),
      _text(l['title']),
      _text(l['channel']),
      _text(l['description']),
      _text(l['level']),
      video,
    );
  }
}

class StudyQuestion {
  const StudyQuestion(
    this.id,
    this.prompt,
    this.options,
    this.correctIndex,
    this.explanation,
  );
  final String id, prompt, explanation;
  final List<String> options;
  final int correctIndex;
  factory StudyQuestion.parse(dynamic value) {
    final q = _object(value);
    final options = _list(q['options'], _text);
    _unique(options.map((s) => s.trim().toLowerCase()));
    final correct = q['correctIndex'];
    if (options.length != 4 || correct is! int || correct < 0 || correct > 3) {
      throw const FormatException('Questão inválida');
    }
    return StudyQuestion(
      _id(q['id']),
      _text(q['prompt']),
      options,
      correct,
      _text(q['explanation']),
    );
  }
}

class StudyTopic {
  const StudyTopic(
    this.id,
    this.title,
    this.subject,
    this.level,
    this.summary,
    this.notes,
    this.sources,
    this.lessons,
    this.questions,
  );
  final String id, title, subject, level, summary, notes;
  final List<StudySource> sources;
  final List<StudyLesson> lessons;
  final List<StudyQuestion> questions;
  factory StudyTopic.parse(dynamic value) {
    final t = _object(value);
    final lessons = _list(t['lessons'], StudyLesson.parse);
    final questions = _list(t['questions'], StudyQuestion.parse);
    if (lessons.length != 2 || questions.length != 10) {
      throw const FormatException('Tamanho inválido');
    }
    _unique(lessons.map((l) => l.id));
    _unique(questions.map((q) => q.id));
    return StudyTopic(
      _id(t['id']),
      _text(t['title']),
      _text(t['subject']),
      _text(t['level']),
      _text(t['summary']),
      _text(t['notes']),
      _list(t['sources'], StudySource.parse),
      lessons,
      questions,
    );
  }
}

class LearningCatalog {
  const LearningCatalog(this.catalogVersion, this.topics);
  final int catalogVersion;
  final List<StudyTopic> topics;
  factory LearningCatalog.fromJson(Map<String, dynamic> root) {
    final version = root['catalogVersion'];
    if (root['schemaVersion'] != 1 || version is! int || version < 1) {
      throw const FormatException('Versão inválida');
    }
    final topics = _list(root['topics'], StudyTopic.parse);
    _unique(topics.map((t) => t.id));
    return LearningCatalog(version, topics);
  }
  StudyTopic? find(String id) {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}

Future<LearningCatalog> loadCatalog(AssetBundle bundle) async =>
    LearningCatalog.fromJson(
      _object(jsonDecode(await bundle.loadString('assets/study/catalog.json'))),
    );
