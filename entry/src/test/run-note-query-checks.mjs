import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const root = new URL('../../../', import.meta.url);
function read(relative) {
  return readFileSync(new URL(relative, root), 'utf8');
}

function strip(source) {
  let text = source
    .replace(/import\s+\{[^}]+\}\s+from\s+'[^']+';\n/g, '')
    .replace(/\s+as\s+[A-Za-z0-9_\[\]]+/g, '')
    .replace(/\bprivate\s+/g, '')
    .replace(/\bexport\s+/g, '')
    .replace(/:\s*Promise<[^>]+>/g, '')
    .replace(/:\s*Note\[\]/g, '')
    .replace(/:\s*string\[\]/g, '')
    .replace(/:\s*number\[\]/g, '')
    .replace(/:\s*Note\b/g, '')
    .replace(/:\s*string\b/g, '')
    .replace(/:\s*boolean\b/g, '')
    .replace(/:\s*number\b/g, '')
    .replace(/:\s*void\b/g, '')
    .replace(/\s*\|\s*undefined/g, '');
  return text;
}

const bundled = [
  strip(read('entry/src/main/ets/model/NoteTypes.ets')),
  strip(read('entry/src/main/ets/model/NoteQuery.ets')),
  strip(read('entry/src/test/NoteQueryCheck.ets')),
  'const failures = checkNoteQuery();\nif (failures.length > 0) {\n  console.error(failures.join(\'\\n\'));\n  process.exit(1);\n}\nconsole.log(\'note-query checks passed\');\n'
].join('\n');

const out = join(tmpdir(), 'lakeside-note-query-checks.mjs');
writeFileSync(out, bundled);
await import(pathToFileURL(out).href);
