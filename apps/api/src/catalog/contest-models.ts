import type {StudyLesson, StudyQuestion, StudySource} from './study-catalog';
export type MaterialBlock =
  | Readonly<{type:'text';title:string;text:string}>
  | Readonly<{type:'list';title:string;items:readonly string[]}>
  | Readonly<{type:'example';title:string;problem:string;steps:readonly string[];answer:string;check:string}>
  | Readonly<{type:'formula';title:string;expression:string;variables:readonly Readonly<{name:string;meaning:string;unit:string}>[];conditions:readonly string[]}>
  | Readonly<{type:'table';title:string;columns:readonly string[];rows:readonly (readonly string[])[];caption:string}>;
export interface WritingTask {readonly id:string;readonly title:string;readonly prompt:string;readonly motivatingText:string;readonly planning:readonly string[];readonly selfReview:readonly string[]}
export interface CoverageRow {readonly referenceItem:string;readonly objectiveIndex:number;readonly blockIndexes:readonly number[];readonly exampleBlockIndex:number;readonly questionIds:readonly string[];readonly sourceUrls:readonly string[]}
export interface ContestModule {
  readonly id:string;readonly researchId:string;readonly title:string;readonly level:string;readonly summary:string;
  readonly objectives:readonly string[];readonly prerequisites:readonly string[];readonly blocks:readonly MaterialBlock[];
  readonly pitfalls:readonly string[];readonly recap:readonly string[];readonly retrieval:readonly string[];
  readonly notes:string;readonly suggestions:readonly string[];readonly sources:readonly StudySource[];readonly updatedAt:string;
  readonly lessonIds:readonly string[];readonly questions:readonly StudyQuestion[];readonly writingTasks:readonly WritingTask[];readonly coverage:readonly CoverageRow[];
}
export interface ContestDiscipline {readonly id:string;readonly title:string;readonly summary:string;readonly lessons:readonly StudyLesson[];readonly modules:readonly ContestModule[]}
export interface ContestCourse {readonly id:string;readonly title:string;readonly track:string;readonly status:'preparation';readonly referenceDate:string;readonly statusSources:readonly StudySource[];readonly syllabusSource:StudySource}
export interface ContestLocation {readonly discipline:ContestDiscipline;readonly module:ContestModule}
