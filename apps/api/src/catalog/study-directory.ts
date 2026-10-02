import { StudyCatalog, StudyTopic, loadStudyCatalog } from './study-catalog';
import { ContestCatalog, loadContestCatalog } from './contest-catalog';
import { ContestLocation } from './contest-models';

export class LearningEntry {
  private constructor(
    readonly topic: StudyTopic,
    readonly area: 'freeStudy' | 'contest',
    readonly contentVersion: number,
    readonly suggestions: readonly string[],
    readonly courseId?: string,
    readonly courseTitle?: string,
    readonly disciplineId?: string,
    readonly contestLocation?: ContestLocation,
    readonly referenceDate?: string,
  ) { Object.freeze(this); }
  static fromFree(topic: StudyTopic, contentVersion: number): LearningEntry {
    return new LearningEntry(topic, 'freeStudy', contentVersion, Object.freeze([
      ({porcentagem:'Como calcular um desconto de 20%?', 'interpretacao-texto':'Como encontrar a ideia principal de um texto?',ecologia:'Qual é a diferença entre cadeia e teia alimentar?'} as Record<string,string>)[topic.id] ?? `Explique ${topic.title} com um exemplo.`,
      'Como usar as aulas e os desafios?',
    ]));
  }
  static fromContest(catalog: ContestCatalog, location: ContestLocation): LearningEntry {
    const { module: m, discipline: d } = location;
    const topic: StudyTopic = Object.freeze({
      id: m.id, title: m.title, subject: d.title, level: m.level,
      summary: m.summary, notes: m.notes, sources: m.sources,
      questions: m.questions,
      lessons: Object.freeze(m.lessonIds.map(id => d.lessons.find(l => l.id === id)!)),
    });
    return new LearningEntry(topic, 'contest', catalog.catalogVersion, m.suggestions,
      catalog.course.id, catalog.course.title, d.id, location, catalog.course.referenceDate);
  }
}
export class StudyDirectory {
  readonly topicIds: readonly string[];
  private readonly entries: ReadonlyMap<string, LearningEntry>;
  constructor(readonly free: StudyCatalog, readonly contests: ContestCatalog) {
    const all = [
      ...free.topics.map(t => LearningEntry.fromFree(t, free.catalogVersion)),
      ...contests.disciplines.flatMap(d => d.modules.map(m => LearningEntry.fromContest(contests, {discipline: d, module: m}))),
    ];
    if (free.topics.some(t => t.id.startsWith('bb2026-')) || new Set(all.map(e => e.topic.id)).size !== all.length) throw new Error('Catalog identity collision');
    this.entries = new Map(all.map(e => [e.topic.id, e]));
    this.topicIds = Object.freeze(all.map(e => e.topic.id));
    Object.freeze(this);
  }
  find(id: string): LearningEntry | undefined { return this.entries.get(id); }
}
export function loadStudyDirectory(): StudyDirectory { return new StudyDirectory(loadStudyCatalog(), loadContestCatalog()); }
