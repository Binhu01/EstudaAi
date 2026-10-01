import { createRequire } from 'node:module';
import { readFile, mkdir, copyFile } from 'node:fs/promises';
const require = createRequire(import.meta.url);
const { StudyCatalog } = require('../apps/api/dist/src/catalog/study-catalog.js');
const source = new URL('../apps/client/assets/study/catalog.json', import.meta.url);
StudyCatalog.fromJson(JSON.parse(await readFile(source, 'utf8')));
const destination = new URL('../apps/api/dist/src/catalog/catalog.json', import.meta.url);
await mkdir(new URL('.', destination), { recursive: true });
await copyFile(source, destination);
