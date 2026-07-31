#!/usr/bin/env node
// Splice the Haskell-emitted DAYS/NIGHTS blocks (hs/.build/*.js) into
// index.html. With --check, compare instead of writing and exit 1 on
// drift — i.e. someone edited the page's data blocks by hand instead of
// hs/Schedule.hs.
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const page = join(root, 'index.html');
const checkOnly = process.argv.includes('--check');

let src = readFileSync(page, 'utf8');

function currentBlock(marker, close) {
  const start = src.indexOf(marker);
  if (start < 0) throw new Error('marker not found: ' + marker);
  const end = src.indexOf('\n' + close, start);
  if (end < 0) throw new Error('terminator not found for: ' + marker);
  return { start, end: end + 1 + close.length };
}

let drift = false;
for (const [file, marker, close] of [
  ['days.js', 'const DAYS = {', '};'],
  ['nights.js', 'const NIGHTS = [', '];'],
]) {
  const generated = readFileSync(join(root, 'hs', '.build', file), 'utf8').trimEnd();
  const { start, end } = currentBlock(marker, close);
  const existing = src.slice(start, end);
  if (existing === generated) continue;
  if (checkOnly) {
    console.error(`DRIFT: index.html ${marker.split(' ')[1]} block differs from hs/Schedule.hs output`);
    drift = true;
  } else {
    src = src.slice(0, start) + generated + src.slice(end);
    console.log(`spliced ${file} into index.html`);
  }
}

if (checkOnly) {
  if (drift) process.exit(1);
  console.log('index.html data blocks match hs/Schedule.hs ✓');
} else {
  writeFileSync(page, src, 'utf8');
}
