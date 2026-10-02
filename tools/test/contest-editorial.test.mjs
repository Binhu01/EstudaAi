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
test('ingles_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'ingles'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,8);assert.equal(report.questions,48);assert.equal(report.writingTasks,0);});
test('vendas_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'vendas'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,20);assert.equal(report.questions,120);assert.equal(report.writingTasks,0);});
test('financeira_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'financeira'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,7);assert.equal(report.questions,42);assert.equal(report.writingTasks,0);});
test('informatica_ready',()=>{const report=verifyContestContent(loadEditorialRoot(),{disciplineId:'informatica'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,21);assert.equal(report.questions,126);assert.equal(report.writingTasks,0);});
test('redacao_ready',()=>{const root=loadEditorialRoot();const report=verifyContestContent(root,{disciplineId:'redacao'});assert.deepEqual(report.errors,[]);assert.equal(report.modules,5);assert.equal(report.questions,30);assert.equal(report.writingTasks,6);assert.deepEqual(root.disciplines.find(d=>d.id==='redacao').modules.map(m=>m.writingTasks.length),[1,1,1,1,2]);});
