import { readFileSync } from 'node:fs';
import { join } from 'node:path';

export interface StudySource { readonly title: string; readonly url: string }
export interface StudyLesson { readonly id: string; readonly title: string; readonly channel: string; readonly description: string; readonly level: string; readonly videoId: string }
export interface StudyQuestion { readonly id: string; readonly prompt: string; readonly options: readonly string[]; readonly correctIndex: number; readonly explanation: string }
export interface StudyTopic { readonly id: string; readonly title: string; readonly subject: string; readonly level: string; readonly summary: string; readonly notes: string; readonly sources: readonly StudySource[]; readonly lessons: readonly StudyLesson[]; readonly questions: readonly StudyQuestion[] }

function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid catalog object');
  return value as Record<string, unknown>;
}
function string(value: unknown): string {
  if (typeof value !== 'string' || !value.trim()) throw new Error('Invalid catalog text');
  return value;
}
function list<T>(value: unknown, parse: (item: unknown) => T): readonly T[] {
  if (!Array.isArray(value) || !value.length) throw new Error('Invalid catalog list');
  return Object.freeze(value.map(parse));
}
function unique(values: readonly string[]): void {
  if (new Set(values).size !== values.length) throw new Error('Duplicate catalog value');
}
function id(value: unknown): string {
  const text = string(value);
  if (!/^[a-z0-9-]+$/.test(text)) throw new Error('Invalid catalog id');
  return text;
}
export class StudyCatalog {
  private constructor(readonly catalogVersion: number, readonly topics: readonly StudyTopic[]) { Object.freeze(this); }
  static fromJson(value: unknown): StudyCatalog {
    const root = record(value);
    if (root.schemaVersion !== 1 || !Number.isInteger(root.catalogVersion) || Number(root.catalogVersion) < 1) throw new Error('Unsupported catalog version');
    const topics = list(root.topics, item => {
      const t = record(item);
      const sources = list(t.sources, item => {
        const s = record(item); const url = string(s.url); const parsed = new URL(url);
        if (parsed.protocol !== 'https:' || parsed.username || parsed.password) throw new Error('Unsafe source');
        return Object.freeze({title: string(s.title), url});
      });
      const lessons = list(t.lessons, item => {
        const l = record(item); const videoId = string(l.videoId);
        if (!/^[A-Za-z0-9_-]{11}$/.test(videoId)) throw new Error('Invalid video id');
        return Object.freeze({id:id(l.id), title:string(l.title), channel:string(l.channel), description:string(l.description), level:string(l.level), videoId});
      });
      const questions = list(t.questions, item => {
        const q = record(item); const options = list(q.options, string);
        unique(options.map(o => o.trim().toLocaleLowerCase('pt-BR')));
        if (options.length !== 4 || !Number.isInteger(q.correctIndex) || Number(q.correctIndex) < 0 || Number(q.correctIndex) > 3) throw new Error('Invalid question');
        return Object.freeze({id:id(q.id), prompt:string(q.prompt), options, correctIndex:Number(q.correctIndex), explanation:string(q.explanation)});
      });
      if (lessons.length !== 2 || questions.length !== 10) throw new Error('Invalid topic size');
      unique(lessons.map(l=>l.id)); unique(questions.map(q=>q.id));
      return Object.freeze({id:id(t.id), title:string(t.title), subject:string(t.subject), level:string(t.level), summary:string(t.summary), notes:string(t.notes), sources, lessons, questions});
    });
    unique(topics.map(t=>t.id));
    return new StudyCatalog(Number(root.catalogVersion), topics);
  }
  find(id: string): StudyTopic | undefined { return this.topics.find(t => t.id === id); }
}
export function loadStudyCatalog(): StudyCatalog {
  return StudyCatalog.fromJson(JSON.parse(readFileSync(join(__dirname, 'catalog.json'), 'utf8')));
}
