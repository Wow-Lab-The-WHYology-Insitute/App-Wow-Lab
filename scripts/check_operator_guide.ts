/**
 * Run by hand — not wired into CI (none exists in this repo).
 *
 * Parses the manifest table at the top of
 * docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md and diffs each row's
 * claimed Romanian text against the live i18n dictionary it names. Only
 * covers claims that are literal i18n-dictionary strings (button labels,
 * option text, defaults) — behavioral claims in the guide (e.g. "lists
 * start empty", "date defaults to today") aren't in the manifest and
 * aren't checked here.
 *
 * Run:
 *   npx tsx scripts/check_operator_guide.ts
 */

import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..");
const GUIDE_PATH = path.join(REPO_ROOT, "docs/WOWLAB_GHID_Operare_Clienti_Contracte_Grupe.md");

type ManifestRow = { key: string; exportName: string; file: string; expectedRo: string };

function stripBackticks(cell: string): string {
  const trimmed = cell.trim();
  return trimmed.startsWith("`") && trimmed.endsWith("`") ? trimmed.slice(1, -1) : trimmed;
}

// The manifest is the first (and only) markdown table in the guide: a
// header row, a `---`-style separator row, then data rows. Parsing is by
// column position (4 columns: key, export, file, expected RO text), not by
// header text, so re-wording the column headers doesn't break this.
function parseManifest(markdown: string): ManifestRow[] {
  const lines = markdown.split("\n");
  const rows: ManifestRow[] = [];
  let inTable = false;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("|")) {
      if (inTable) break; // table block ended
      continue;
    }
    const body = trimmed.slice(1, trimmed.endsWith("|") ? -1 : undefined);
    const cells = body.split("|").map((c) => c.trim());

    const isSeparatorRow = cells.every((c) => /^:?-+:?$/.test(c));
    if (isSeparatorRow) {
      inTable = true;
      continue;
    }
    if (!inTable) continue; // this is the header row, above the separator
    if (cells.length < 4) continue;

    const [keyCell, exportCell, fileCell, expectedCell] = cells;
    rows.push({
      key: stripBackticks(keyCell),
      exportName: stripBackticks(exportCell),
      file: stripBackticks(fileCell),
      expectedRo: expectedCell.trim(),
    });
  }
  return rows;
}

async function main() {
  const markdown = readFileSync(GUIDE_PATH, "utf8");
  const rows = parseManifest(markdown);
  if (rows.length === 0) {
    console.error(`No manifest rows found in ${GUIDE_PATH}`);
    process.exit(1);
  }

  const moduleCache = new Map<string, Record<string, unknown>>();
  let failures = 0;

  for (const row of rows) {
    let mod = moduleCache.get(row.file);
    if (!mod) {
      const absPath = path.join(REPO_ROOT, row.file);
      mod = (await import(pathToFileURL(absPath).href)) as Record<string, unknown>;
      moduleCache.set(row.file, mod);
    }

    const dict = mod[row.exportName] as Record<string, { ro?: string }> | undefined;
    if (!dict) {
      console.error(`FAIL  ${row.file} has no export \`${row.exportName}\``);
      failures++;
      continue;
    }

    const entry = dict[row.key];
    if (!entry || typeof entry.ro !== "string") {
      console.error(`FAIL  ${row.exportName}.${row.key} (${row.file}) does not exist or has no \`ro\` value`);
      failures++;
      continue;
    }

    if (entry.ro !== row.expectedRo) {
      console.error(
        `FAIL  ${row.exportName}.${row.key} (${row.file})\n` +
          `      guide claims: "${row.expectedRo}"\n` +
          `      live value:   "${entry.ro}"`,
      );
      failures++;
      continue;
    }

    console.log(`ok    ${row.exportName}.${row.key}`);
  }

  console.log(`\n${rows.length - failures}/${rows.length} manifest claims match the live dictionaries.`);
  if (failures > 0) {
    console.error(`${failures} mismatch(es) found — the guide is out of date.`);
    process.exit(1);
  }
}

main();
