import {readFileSync} from 'node:fs';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {verifyContestContent,verifyContestMetadata} from '../verify-contest-content.mjs';
export function loadEditorialRoot(){return JSON.parse(readFileSync(new URL('../../apps/client/assets/contests/bb2026/catalog.json',import.meta.url),'utf8'));}
test('metadata_and_videos_ready',()=>{const report=verifyContestMetadata(loadEditorialRoot());assert.equal(report.lessons,18);assert.deepEqual(report.errors,[]);});
