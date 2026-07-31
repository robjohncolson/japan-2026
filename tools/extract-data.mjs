#!/usr/bin/env node
// Extract the DAYS and NIGHTS literals from index.html into JSON for the
// Haskell schedule kernel (hs/). Evaluating the literals also proves the
// blocks are syntactically valid JS — the apostrophe trap fails right here,
// before anything is committed.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = readFileSync(join(root, 'index.html'), 'utf8');

function slice(marker, close) {
  const start = src.indexOf(marker);
  if (start < 0) throw new Error('marker not found: ' + marker);
  const open = src.indexOf('=', start) + 1;
  const end = src.indexOf('\n' + close, open);
  if (end < 0) throw new Error('terminator not found for: ' + marker);
  return src.slice(open, end + 1 + close.length - 1);
}

const days = new Function('return (' + slice('const DAYS = {', '};') + ')')();
const nights = new Function('return (' + slice('const NIGHTS = [', '];') + ')')();

const out = join(root, 'hs', '.build');
mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'days.json'), JSON.stringify(days), 'utf8');
writeFileSync(join(out, 'nights.json'), JSON.stringify(nights), 'utf8');
console.log(`extracted ${Object.keys(days).length} day cards, ${nights.length} lodging rows`);
