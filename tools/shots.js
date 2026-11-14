'use strict';
// shots [--root <_forever_ folder>] [--dry-run] [--watch]: copies the screenshots /puishots took (Polestar_UI_Shots
// addon) into screenshots/game/<run>/<label>.<ext>, and the same into screenshots/game/latest/. The manifest is
// PolestarUIShotsDB in WTF/Account/*/SavedVariables/Polestar_UI_Shots.lua (the newest), written on /reload or logout:
// run = "<YYYYMMDD-HHMMSS>", shots = { "<time()>|<label>", ... }. Each entry takes the unused
// WoWScrnShot_MMDDYY_HHMMSS file nearest its time. --watch polls the manifest and does each new run once
// (done runs: screenshots/game/runs.json), printing one "SHOTS <n> files -> <folder>" line per run.

const fs = require('node:fs');
const path = require('node:path');
const { findAddons } = require('./link.js');

const OUT = path.resolve(__dirname, '..', 'screenshots', 'game');
const STATE = path.join(OUT, 'runs.json');
const SLACK = 10; // seconds between the shot's time() and the file's stamp
const IMG = /\.(png|jpe?g|tga)$/i;
const say = (s) => fs.writeSync(1, s + '\n'); // unbuffered: --watch is tailed

function manifestPath(root) {
	const accounts = path.join(root, 'WTF', 'Account');
	let svs = [];
	try {
		svs = fs.readdirSync(accounts).map((a) => path.join(accounts, a, 'SavedVariables', 'Polestar_UI_Shots.lua')).filter((p) => fs.existsSync(p));
	} catch {}
	return svs.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs)[0] || null;
}

function readState() { try { return JSON.parse(fs.readFileSync(STATE, 'utf8')); } catch { return { done: [] }; } }

// Copies one run; returns the files written (or that would be), or null when the manifest lists none.
function processRun(root, sv, dry) {
	const text = fs.readFileSync(sv, 'utf8');
	const str = (k) => (text.match(new RegExp(`\\["${k}"\\]\\s*=\\s*"([^"]*)"`)) || [])[1];
	const run = str('run') || 'run';
	const entries = [...text.matchAll(/"(\d+)\|([^"]+)"/g)].map((m) => ({ t: Number(m[1]), label: m[2] }));
	if (!entries.length) return null;

	const shotsDir = path.join(root, 'Screenshots');
	let files = [];
	try { files = fs.readdirSync(shotsDir); } catch {}
	files = files.map((name) => {
		const m = name.match(/^WoWScrnShot_(\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)\.(png|jpe?g|tga)$/i);
		return m && { name, ext: m[7].toLowerCase(), t: new Date(2000 + +m[3], m[1] - 1, +m[2], +m[4], +m[5], +m[6]).getTime() / 1000 };
	}).filter(Boolean);

	const dir = path.join(OUT, run), latest = path.join(OUT, 'latest');
	if (!dry) {
		for (const d of [dir, latest]) {
			fs.mkdirSync(d, { recursive: true });
			for (const f of fs.readdirSync(d)) if (IMG.test(f)) fs.unlinkSync(path.join(d, f));
		}
		fs.writeFileSync(path.join(latest, 'run.txt'), `${run}\n${str('info') || ''}\n`);
	}
	// The file is stamped at capture, the entry at SCREENSHOT_SUCCEEDED (a second or so later), shots ~1.5 s apart:
	// nearest-time can shift labels by one, so the run's files pair with the entries in order when the counts agree.
	const t0 = entries[0].t, t1 = entries[entries.length - 1].t;
	const span = files.filter((f) => f.t >= t0 - 5 && f.t <= t1 + 1).sort((a, b) => a.t - b.t || (a.name < b.name ? -1 : 1));
	const inOrder = span.length === entries.length;
	const used = new Set(), written = [];
	for (const [k, e] of entries.entries()) {
		let best = inOrder ? span[k] : null;
		if (!inOrder) for (const f of files) {
			const d = Math.abs(f.t - e.t);
			if (!used.has(f.name) && d <= SLACK && (!best || d < Math.abs(best.t - e.t))) best = f;
		}
		if (!best) { say(`  missing: ${e.label} (no screenshot within ${SLACK}s)`); continue; }
		used.add(best.name);
		const dest = path.join(dir, `${e.label}.${best.ext}`);
		if (!dry) {
			fs.copyFileSync(path.join(shotsDir, best.name), dest);
			fs.copyFileSync(dest, path.join(latest, path.basename(dest)));
		}
		written.push(dest);
	}
	const skipped = str('skipped');
	if (skipped) say(`  skipped in game: ${skipped}`);
	return { run, info: str('info'), dir, written, missing: entries.length - written.length };
}

function main(argv) {
	const dry = argv.includes('--dry-run'), watch = argv.includes('--watch');
	const ri = argv.indexOf('--root');
	let root = ri >= 0 ? argv[ri + 1] : null;
	if (!root) {
		const addons = findAddons(process.env);
		if (!addons) { console.error('No WoW Forever AddOns folder found (see npm run link).'); return 1; }
		root = path.resolve(addons, '..', '..');
	}

	if (!watch) {
		const sv = manifestPath(root);
		if (!sv) { console.error(`No Polestar_UI_Shots.lua under ${path.join(root, 'WTF', 'Account')}; run /puishots, then /reload.`); return 1; }
		const r = processRun(root, sv, dry);
		if (!r) { console.error(`${sv} lists no shots.`); return 1; }
		say(`Manifest: ${sv}${r.info ? `\n  ${r.info}` : ''}`);
		for (const f of r.written) say(`  ${dry ? 'would write' : 'wrote'} ${f}`);
		if (!dry) { const s = readState(); if (!s.done.includes(r.run)) s.done.push(r.run); fs.writeFileSync(STATE, JSON.stringify(s, null, 1)); }
		say(`SHOTS ${r.written.length} files -> ${path.relative(path.resolve(__dirname, '..'), r.dir).replace(/\\/g, '/')}/`);
		return r.missing ? 1 : 0;
	}

	say(`Watching ${path.join(root, 'WTF', 'Account', '*', 'SavedVariables', 'Polestar_UI_Shots.lua')} (Ctrl+C stops)`);
	let lastMtime = 0;
	const tick = () => {
		const sv = manifestPath(root);
		if (!sv) return;
		const m = fs.statSync(sv).mtimeMs;
		if (m === lastMtime) return;
		lastMtime = m;
		const run = (fs.readFileSync(sv, 'utf8').match(/\["run"\]\s*=\s*"([^"]*)"/) || [])[1];
		const s = readState();
		if (!run || s.done.includes(run)) return;
		const r = processRun(root, sv, dry);
		if (!r) return;
		if (!dry) { s.done.push(r.run); fs.mkdirSync(OUT, { recursive: true }); fs.writeFileSync(STATE, JSON.stringify(s, null, 1)); }
		say(`SHOTS ${r.written.length} files -> ${path.relative(path.resolve(__dirname, '..'), r.dir).replace(/\\/g, '/')}/`);
	};
	tick();
	setInterval(tick, 2000);
	return undefined;
}

const code = main(process.argv.slice(2));
if (code !== undefined) process.exitCode = code;
