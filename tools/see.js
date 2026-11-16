'use strict';
// see [--root <_forever_ folder>] [--watch]: turns what the Polestar_UI_See addon recorded (/puisee [note], then
// /reload) into one small text file, screenshots/game/digest.md: each new mark's state and note, this session's Lua
// errors (!BugGrabber.lua, ours with their stack) and the event log; per mark two small images, cut by tools/look.js
// from the screenshot the mark took: a 640x400 crop round the cursor and the whole screen at 960 px (docs/see.md).
// PolestarUISeeDB (WTF/Account/*/SavedVariables/Polestar_UI_See.lua, the newest) holds only flat strings:
//   marks = { "<time()>|<cursor x 0..1>|<cursor y 0..1>|<note>\n<state>" }, events = { "<time()> text" },
//   info = "...", session = <BugGrabber's session>.
// --watch polls and writes the digest once per save that has a new mark or new errors of ours (done marks and the
// session: screenshots/game/see.json), printing one "SEE ..." line each time.

const fs = require('node:fs');
const path = require('node:path');
const { findAddons } = require('./link.js');
const look = require('./look.js');

const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'screenshots', 'game');
const rel = (p) => path.relative(ROOT, p).replace(/\\/g, '/');
const clock = (t) => new Date(t * 1000).toTimeString().slice(0, 8);

// A Lua string literal's value, as the client writes saved variables.
const unescape = (s) => s.replace(/\\(\d{1,3}|.)/g, (_, c) => (c === 'n' ? '\n' : c === 'r' ? '\r' : c === 't' ? '\t' : /^\d/.test(c) ? String.fromCharCode(+c) : c));
const STRING = /"((?:[^"\\]|\\.)*)"/;

// The saved table: its string arrays (one string a line, closed by a "}," line) and its scalar fields.
function parseSaved(text) {
	const lines = text.split(/\r?\n/);
	const list = (key) => {
		const out = [];
		let i = lines.findIndex((l) => l.trim().startsWith(`["${key}"] = {`));
		if (i < 0) return out;
		for (i++; i < lines.length && !/^\s*\},?\s*$/.test(lines[i]); i++) {
			const m = lines[i].match(STRING);
			if (m) out.push(unescape(m[1]));
		}
		return out;
	};
	const info = text.match(new RegExp(`\\["info"\\] = ${STRING.source}`));
	const marks = list('marks').map((s) => {
		const nl = s.indexOf('\n'), head = (nl < 0 ? s : s.slice(0, nl)).split('|');
		return { t: Number(head[0]), fx: Number(head[1]), fy: Number(head[2]), note: head.slice(3).join('|'), body: nl < 0 ? '' : s.slice(nl + 1) };
	}).filter((m) => m.t > 0);
	const events = list('events').map((s) => ({ t: Number(s.split(' ', 1)[0]), text: s.replace(/^\d+ /, '') }));
	return { marks, events, info: info ? unescape(info[1]) : '', session: Number((text.match(/\["session"\] = (-?\d+)/) || [])[1]) || 0 };
}

// BugGrabberDB.errors of one session (the newest when 0): { message, stack: [lines], count, t, ours }.
function parseBugs(text, session) {
	const get = (e, k) => { const m = e.match(new RegExp(`\\["${k}"\\] = (?:${STRING.source}|(-?\\d+))`)); return m ? (m[2] !== undefined ? m[2] : unescape(m[1])) : ''; };
	const all = text.split(/\r?\n\{\r?\n/).slice(1).map((e) => ({ session: Number(get(e, 'session')), message: get(e, 'message'), stack: get(e, 'stack'), count: Number(get(e, 'counter')) || 1, t: Number(get(e, 'time')) }));
	const want = session > 0 ? session : Math.max(0, ...all.map((e) => e.session));
	return all.filter((e) => e.session === want).sort((a, b) => a.t - b.t).map((e) => ({
		message: e.message, count: e.count, t: e.t, ours: /Polestar_UI/.test(e.message + e.stack),
		stack: e.stack.replace(/Interface\/AddOns\//g, '').split('\n').filter((l) => l && !/BugGrabber/.test(l)),
	}));
}

// The game's screenshot stamped at a mark's time(): WoWScrnShot_MMDDYY_HHMMSS, up to 2 s after it.
function shotFor(dir, t, used) {
	let files = [];
	try { files = fs.readdirSync(dir); } catch {}
	let best = null;
	for (const name of files) {
		const m = name.match(/^WoWScrnShot_(\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)\.(png|jpe?g)$/i);
		if (!m || used.has(name)) continue;
		const d = new Date(2000 + +m[3], m[1] - 1, +m[2], +m[4], +m[5], +m[6]).getTime() / 1000 - t;
		if (d >= -1 && d <= 2 && (!best || Math.abs(d) < Math.abs(best.d))) best = { name, d };
	}
	if (best) used.add(best.name);
	return best && path.join(dir, best.name);
}

function newest(root, file) {
	const accounts = path.join(root, 'WTF', 'Account');
	let svs = [];
	try { svs = fs.readdirSync(accounts).map((a) => path.join(accounts, a, 'SavedVariables', file)).filter((p) => fs.existsSync(p)); } catch {}
	return svs.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs)[0] || null;
}

// Writes <out>/digest.md from the newest save under `root`. o: { out, cut(src, dest, opts) (false: no images),
// always (write even with nothing new) }. Returns { marks, ours, errors, file } or null (nothing new, or no save).
function digest(root, o = {}) {
	const out = o.out || OUT, cut = o.cut === undefined ? look.cut : o.cut;
	const sv = newest(root, 'Polestar_UI_See.lua');
	if (!sv) return null;
	const db = parseSaved(fs.readFileSync(sv, 'utf8'));
	const statePath = path.join(out, 'see.json');
	let state = { marks: [], session: 0 };
	try { state = JSON.parse(fs.readFileSync(statePath, 'utf8')); } catch {}
	const bugsPath = path.join(path.dirname(sv), '!BugGrabber.lua');
	const bugs = fs.existsSync(bugsPath) ? parseBugs(fs.readFileSync(bugsPath, 'utf8'), db.session) : null;
	const ours = bugs ? bugs.filter((e) => e.ours) : [];
	const marks = db.marks.filter((m) => !state.marks.includes(m.t));
	if (!o.always && !marks.length && !(ours.length && db.session !== state.session)) return null;

	const L = [`# Game digest (${new Date(fs.statSync(sv).mtimeMs).toLocaleString('sv')}, BugGrabber session ${db.session || '?'})`, '', db.info || '(no info line: the addon saw no login)'];
	const addon = path.join(root, 'Interface', 'AddOns', 'Polestar_UI');
	let linked = false;
	try { linked = fs.realpathSync(addon) === fs.realpathSync(ROOT); } catch {}
	if (!linked) L.push(`WARNING: ${addon} is not a link to this checkout: the game ran another copy of Polestar: UI (npm run link).`);

	L.push('', `## Marks (${marks.length} new)`);
	const used = new Set();
	for (const m of marks) {
		L.push('', `### ${clock(m.t)}${m.note ? ` "${m.note}"` : ''}`);
		const shot = shotFor(path.join(root, 'Screenshots'), m.t, used);
		if (!shot) L.push('image: none (no game screenshot stamped at this mark)');
		else if (cut) {
			const base = path.join(out, 'see', `mark-${clock(m.t).replace(/:/g, '')}`);
			try {
				L.push('images, only if the text does not answer it (the magenta box is the cursor):',
					'- ' + cut(shot, `${base}.jpg`, { at: `${m.fx},${m.fy}` }).replace(/^CROP /, ''),
					'- ' + cut(shot, `${base}-full.jpg`, {}).replace(/^CROP /, ''));
			} catch (e) { L.push(`image: ${shot} (not cut: ${e.message.split('\n')[0]})`); }
		} else L.push(`image: ${shot}`);
		L.push('```', m.body, '```');
	}

	if (!bugs) L.push('', '## Errors', 'No !BugGrabber.lua next to the save.');
	else {
		L.push('', `## Errors this session (${bugs.length}; ${ours.length} touch Polestar_UI)`);
		for (const e of ours.slice(-8)) L.push('', `${clock(e.t)} x${e.count} ${e.message}`, ...e.stack.slice(0, 8).map((l) => '    ' + l));
		if (ours.length > 8) L.push('', `(${ours.length - 8} older ones of ours left out)`);
		const rest = bugs.filter((e) => !e.ours);
		if (rest.length) L.push('', 'Others:', ...rest.slice(-5).map((e) => `- ${clock(e.t)} x${e.count} ${e.message.slice(0, 200)}`));
		if (bugs.length) L.push('', `Locals: node .claude/skills/bug-hunt/bugs.js "${bugsPath}" Polestar_UI <text in the message>`);
	}

	// The events since the last load, the newest 40.
	const from = db.events.map((e) => e.text).lastIndexOf('load');
	const events = db.events.slice(Math.max(0, from)).slice(-40);
	L.push('', `## Events (${events.length})`, ...events.map((e) => `${clock(e.t)} ${e.text}`), '');

	fs.mkdirSync(out, { recursive: true });
	const file = path.join(out, 'digest.md');
	fs.writeFileSync(file, L.join('\n'));
	fs.writeFileSync(statePath, JSON.stringify({ marks: [...state.marks, ...marks.map((m) => m.t)].slice(-50), session: db.session,
		at: marks.length ? [marks[marks.length - 1].fx, marks[marks.length - 1].fy] : state.at })); // `at`: tools/look.js region=mark
	return { marks: marks.length, ours: ours.length, errors: bugs ? bugs.length : 0, file };
}

function main(argv) {
	const ri = argv.indexOf('--root');
	let root = ri >= 0 ? argv[ri + 1] : null;
	if (!root) {
		const addons = findAddons(process.env);
		if (!addons) { console.error('No WoW Forever AddOns folder found (see npm run link).'); return 1; }
		root = path.resolve(addons, '..', '..');
	}
	const line = (r) => console.log(`SEE ${r.marks} new marks, ${r.ours} errors of ours (${r.errors} in all) -> ${rel(r.file)}`);
	if (!argv.includes('--watch')) {
		const r = digest(root, { always: true });
		if (!r) { console.error(`No Polestar_UI_See.lua under ${path.join(root, 'WTF', 'Account')}: npm run link:see, enable the addon, /puisee, /reload.`); return 1; }
		line(r);
		return 0;
	}
	console.log(`Watching ${path.join(root, 'WTF', 'Account', '*', 'SavedVariables', 'Polestar_UI_See.lua')} (Ctrl+C stops)`);
	let seen = 0, last = 0;
	setInterval(() => {
		const sv = newest(root, 'Polestar_UI_See.lua');
		if (!sv) return;
		const m = fs.statSync(sv).mtimeMs;
		// A tick after the save settles: !BugGrabber.lua is written in the same reload.
		if (m !== seen && m === last) {
			seen = m;
			try { const r = digest(root); if (r) line(r); } catch (e) { console.error(`SEE failed: ${e.message}`); }
		}
		last = m;
	}, 2000);
	return undefined;
}

if (require.main === module) {
	const code = main(process.argv.slice(2));
	if (code !== undefined) process.exitCode = code;
}
module.exports = { parseSaved, parseBugs, digest };
