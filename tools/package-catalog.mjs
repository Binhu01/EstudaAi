import { createRequire } from 'node:module';
import { readFile, mkdir, copyFile } from 'node:fs/promises';
const require = createRequire(import.meta.url);
const { StudyCatalog } = require('../apps/api/dist/src/catalog/study-catalog.js');
const { ContestCatalog } = require('../apps/api/dist/src/catalog/contest-catalog.js');
for (const [sourcePath, destinationPath, Catalog] of [
  ['../apps/client/assets/study/catalog.json', '../apps/api/dist/src/catalog/catalog.json', StudyCatalog],
  ['../apps/client/assets/contests/bb2026/catalog.json', '../apps/api/dist/src/catalog/contests/bb2026/catalog.json', ContestCatalog],
]) {
  const source = new URL(sourcePath, import.meta.url);
  Catalog.fromJson(JSON.parse(await readFile(source, 'utf8')));
  const destination = new URL(destinationPath, import.meta.url);
  await mkdir(new URL('.', destination), { recursive: true });
  await copyFile(source, destination);
}
