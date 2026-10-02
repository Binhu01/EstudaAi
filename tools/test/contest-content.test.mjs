import {test} from 'node:test';
import assert from 'node:assert/strict';
import {makeContestFixture} from './contest-fixture.mjs';
import {verifyContestContent,verifyContestMetadata} from '../verify-contest-content.mjs';
test('metadata_draft_does_not_publish_partial_catalog',()=>{
  const draft=makeContestFixture({empty:true});
  assert.deepEqual(verifyContestMetadata(draft),{lessons:18,errors:[]});
  assert.ok(verifyContestContent(draft,{}).errors.length);
});
test('isolated_discipline_validation_keeps_global_gate',()=>{
  const root=makeContestFixture();root.disciplines[1].modules=[];
  assert.deepEqual(verifyContestContent(root,{disciplineId:'bancarios'}),{modules:22,questions:132,writingTasks:0,errors:[]});
  assert.ok(verifyContestContent(root,{}).errors.length);
  assert.ok(verifyContestContent(root,{disciplineId:'unknown'}).errors.length);
});
