import {readFileSync} from 'node:fs';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {verifyContestContent,verifyContestMetadata} from '../verify-contest-content.mjs';
export function loadEditorialRoot(){return JSON.parse(readFileSync(new URL('../../apps/client/assets/contests/bb2026/catalog.json',import.meta.url),'utf8'));}
test('metadata_and_videos_ready',()=>{const report=verifyContestMetadata(loadEditorialRoot());assert.equal(report.lessons,18);assert.deepEqual(report.errors,[]);});
test('bancarios_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'bancarios'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,22);assert.equal(report.questions,132);assert.equal(report.writingTasks,0);});
test('atualidades_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'atualidades'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,12);assert.equal(report.questions,72);assert.equal(report.writingTasks,0);});
test('portugues_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'portugues'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,13);assert.equal(report.questions,78);assert.equal(report.writingTasks,0);});
test('matematica_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'matematica'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,18);assert.equal(report.questions,108);assert.equal(report.writingTasks,0);});
