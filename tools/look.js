'use strict';
// look.js <look|crop|rec|sheet|stop> [options]: the screen as small images, through ffmpeg (dev tool; docs/see.md).
// It only records the picture (as any screen recorder) and asks Windows which window has focus: nothing is read
// from or put into the game. Options are key=value or --key value; flags bare or with --.
//   look [region=x,y,w,h | region=mouse | region=mark] [size=WxH] [game] [scale=s] [fit=px] [monitor=n] [gdi]
//       the monitor now, mouse pointer drawn, fitted to 960 px wide; `region` (screen pixels) comes at full size:
//       four numbers, or `size` (640x400) round the mouse, or round the last /puisee mark's cursor. `game`: the
//       game window's own picture, whatever covers it. -> screenshots/game/look/look-<HHMMSS>.jpg (newest 20 kept)
//   crop <image> [out] [region=x,y,w,h | at=fx,fy] [size=WxH] [scale=s] [fit=px]
//       the same cut from a file (a recording's frame, a game screenshot); `at`: `size` (640x400) round that point,
//       given as 0..1 fractions, with a magenta box on it.
//   rec [seconds=60] [every=1 | fps=n] [threshold=0.02] [max=12] [region=...] [size=WxH] [text] [screen] [exe=re]
//       records the game window (the process matching `exe`, ^wow), starting when it takes focus and dropping
//       what comes while it has none; `screen`, or no game: the monitor, whatever has focus. Samples every `every`
//       s and keeps a frame only when the picture changed (ffmpeg's scene score over `threshold`), one line per
//       kept frame; ends with a contact sheet of up to `max` of them, numbered and timed. `region`: only that
//       part of the screen, at full size, tiled at native size. `text`: lines only, no image.
//   rec strip | diff [fps=10] [seconds=5] [threshold=0.1] [from=n] ...
//       a burst: every frame kept, each measured against the one before (mean difference, 0-255). `strip`: the
//       sheet is `max` frames in a row from `from`; `diff`: only the frames that differ from both neighbours (a
//       flicker), in red, each with its neighbours. -> screenshots/game/rec/<run>/
//   sheet <run> [from=n] [max=n]  a strip again from a finished run's frames.
//   stop  ends a running rec (it then writes its sheet).
// Every image line ends with its rough cost for Claude: width x height / 750 tokens.

const fs = require('node:fs');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');

const ROOT = path.resolve(__dirname, '..');
const OUT = path.join(ROOT, 'screenshots', 'game');
const STOP = path.join(OUT, 'rec', 'stop');
const VALUED = ['region', 'at', 'size', 'scale', 'fit', 'monitor', 'seconds', 'every', 'threshold', 'max', 'fps', 'from', 'exe', 'src'];
const rel = (p) => path.relative(ROOT, p).replace(/\\/g, '/');
const tokens = (w, h) => Math.ceil((w * h) / 750);
const clock = (d) => d.toTimeString().slice(0, 8);
const nums = (s, n, what) => {
	const v = String(s).split(/[,x]/).map(Number);
	if (v.length !== n || v.some((k) => !Number.isFinite(k) || k < 0)) throw new Error(`${what}: expected ${n} numbers, got "${s}"`);
	return v;
};

function parse(argv) {
	const o = {}, pos = [];
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i], k = a.replace(/^--/, '');
		const m = k.match(/^([a-z]+)=(.*)$/);
		if (m) o[m[1]] = m[2];
		else if (a.startsWith('--') && VALUED.includes(k)) o[k] = argv[++i];
		else if (a.startsWith('--') || ['text', 'gdi', 'strip', 'diff', 'screen', 'game'].includes(k)) o[k] = true;
		else pos.push(a);
	}
	return { o, pos };
}

function ffmpeg(args) {
	const r = spawnSync('ffmpeg', ['-hide_banner', '-y', ...args], { encoding: 'utf8' });
	if (r.error) throw new Error('ffmpeg is not on PATH (winget install Gyan.FFmpeg).');
	if (r.status !== 0) throw new Error('ffmpeg failed:\n' + r.stderr.split('\n').slice(-6).join('\n'));
	return r.stderr;
}

// The picture as an ffmpeg input at `fps`, and the filters that bring its frames to memory: the game window alone
// (`hwnd`: Windows.Graphics.Capture, the window's own picture even when covered), else the monitor (Desktop
// Duplication, or GDI), all of it or only `box` {x, y, w, h}.
function source(o, fps, box, hwnd) {
	if (o.src) return { input: ['-f', 'lavfi', '-i', o.src], pre: [] }; // tests: a made-up picture
	if (o.gdi) {
		const area = box ? ['-video_size', `${box.w}x${box.h}`, '-offset_x', String(box.x), '-offset_y', String(box.y)] : [];
		return { input: ['-f', 'gdigrab', '-framerate', String(fps), '-draw_mouse', '1', ...area, '-i', 'desktop'], pre: [] };
	}
	const grab = hwnd && !box ? `gfxcapture=hwnd=${hwnd}:max_framerate=${fps}`
		: `ddagrab=output_idx=${nums(o.monitor || 0, 1, 'monitor')[0]}:framerate=${fps}:draw_mouse=1${box ? `:video_size=${box.w}x${box.h}:offset_x=${box.x}:offset_y=${box.y}` : ''}`;
	return { input: ['-f', 'lavfi', '-i', grab], pre: ['hwdownload', 'format=bgra'] };
}

// The window helper (PowerShell, user32): one line "INFO <game hwnd or 0> <its client area x y w h> <screen w h>",
// then "F <1 while the game has focus> <mouse x y>", again on each change while LOOK_WATCH is set. All in physical
// pixels of the primary monitor.
const EXE = '^wow';
const PS = ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(`
$ProgressPreference = 'SilentlyContinue'
Add-Type @"
using System; using System.Runtime.InteropServices;
public class LookW {
	public struct P { public int x, y; } public struct R { public int l, t, r, b; }
	[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
	[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
	[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
	[DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out R r);
	[DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref P p);
	[DllImport("user32.dll")] public static extern bool GetCursorPos(out P p);
	[DllImport("user32.dll")] public static extern int GetSystemMetrics(int i);
}
"@
[void][LookW]::SetProcessDPIAware()
$g = Get-Process | Where-Object { $_.ProcessName -match $env:LOOK_EXE -and $_.MainWindowHandle -ne 0 } | Select-Object -First 1
$r = New-Object LookW+R; $p = New-Object LookW+P; $h = 0
if ($g) { $h = [int64]$g.MainWindowHandle; [void][LookW]::GetClientRect($g.MainWindowHandle, [ref]$r); [void][LookW]::ClientToScreen($g.MainWindowHandle, [ref]$p) }
[Console]::Out.WriteLine("INFO $h $($p.x) $($p.y) $($r.r) $($r.b) $([LookW]::GetSystemMetrics(0)) $([LookW]::GetSystemMetrics(1))")
$last = -1
do {
	[uint32]$fp = 0; [void][LookW]::GetWindowThreadProcessId([LookW]::GetForegroundWindow(), [ref]$fp)
	$f = [int]($g -and $fp -eq $g.Id)
	if ($f -ne $last) { $m = New-Object LookW+P; [void][LookW]::GetCursorPos([ref]$m); [Console]::Out.WriteLine("F $f $($m.x) $($m.y)"); $last = $f }
	if ($env:LOOK_WATCH) { Start-Sleep -Milliseconds 100 }
} while ($env:LOOK_WATCH)
`, 'utf16le').toString('base64')];
const helperEnv = (o, watch) => ({ ...process.env, LOOK_EXE: o.exe || EXE, LOOK_WATCH: watch ? '1' : '' });
function helper(o) {
	const r = spawnSync('powershell', PS, { env: helperEnv(o), encoding: 'utf8' });
	if (r.status !== 0) throw new Error('the window helper (powershell) failed:\n' + String(r.stderr).split('\n').slice(0, 6).join('\n'));
	return r.stdout;
}
// The helper's lines as { hwnd, game: {x, y, w, h}, sw, sh } and/or { focus, mouse: [x, y] }.
function parseInfo(text) {
	const p = {};
	for (const line of String(text).split(/\r?\n/)) {
		const [tag, ...v] = line.trim().split(' '), n = v.map(Number);
		if (tag === 'INFO') Object.assign(p, { hwnd: n[0], game: n[0] ? { x: n[1], y: n[2], w: n[3], h: n[4] } : null, sw: n[5], sh: n[6] });
		if (tag === 'F') Object.assign(p, { focus: n[0] === 1, mouse: [n[1], n[2]] });
	}
	return p;
}

// The last /puisee mark's cursor as 0..1 fractions of the game's picture (tools/see.js keeps it), or null.
function lastMark() {
	try { return JSON.parse(fs.readFileSync(path.join(OUT, 'see.json'), 'utf8')).at || null; } catch { return null; }
}

// `region` as { x, y, w, h } in screen pixels, or null: four numbers, or `size` (640x400) round the mouse (`mouse`)
// or round the last mark's cursor (`mark`, `at` = its fractions of the game window, else of the screen), kept on
// the screen. shortcut: the primary monitor only, add the monitor's origin when a second one matters.
function box(o, info, mouse, at) {
	if (!o.region) return null;
	if (!/^(mouse|mark)$/.test(o.region)) { const [x, y, w, h] = nums(o.region, 4, 'region'); return { x, y, w, h }; }
	if (o.region === 'mark' && !at) throw new Error('region=mark: no /puisee mark digested yet (npm run see)');
	const g = info.game || { x: 0, y: 0, w: info.sw, h: info.sh };
	const c = o.region === 'mark' ? [g.x + at[0] * g.w, g.y + at[1] * g.h] : mouse;
	const [w, h] = nums(o.size || '640x400', 2, 'size').map((v, i) => Math.min(v, i ? info.sh : info.sw));
	const keep = (v, max) => Math.max(0, Math.min(Math.round(v), max));
	return { x: keep(c[0] - w / 2, info.sw - w), y: keep(c[1] - h / 2, info.sh - h), w, h };
}

// Filters cutting `region`, or `size` round `at`, or nothing; then `scale`, else a fit into `fit` px wide (960)
// for a whole picture and full size for a cut.
function cutFilters(o) {
	const f = [];
	if (o.region) {
		const [x, y, w, h] = nums(o.region, 4, 'region');
		f.push(`crop=${w}:${h}:${x}:${y}`);
	} else if (o.at) {
		const [fx, fy] = nums(o.at, 2, 'at'), [w, h] = nums(o.size || '640x400', 2, 'size');
		f.push(`drawbox=x=${fx}*iw-12:y=${fy}*ih-12:w=24:h=24:color=magenta:t=2`,
			`crop=w='min(${w},iw)':h='min(${h},ih)':x='clip(${fx}*iw-ow/2,0,iw-ow)':y='clip(${fy}*ih-oh/2,0,ih-oh)'`);
	}
	if (o.scale) f.push(`scale=iw*${nums(o.scale, 1, 'scale')[0]}:-2`);
	else if (o.fit || !(o.region || o.at)) f.push(`scale='min(${nums(o.fit || 960, 1, 'fit')[0]},iw)':-2`);
	return f;
}

// One JPEG out of `input` through `filters`; returns its line: "<tag> <path> WxH ~N tokens".
function still(tag, input, filters, dest) {
	fs.mkdirSync(path.dirname(dest), { recursive: true });
	const log = ffmpeg([...input, '-frames:v', '1', ...(filters.length ? ['-vf', filters.join(',')] : []), '-q:v', '3', '-update', '1', dest]);
	const m = [...log.matchAll(/Video: mjpeg.*?, (\d+)x(\d+)/g)].pop();
	return `${tag} ${rel(dest)} ${m ? `${m[1]}x${m[2]} ~${tokens(+m[1], +m[2])} tokens` : ''}`;
}

// Cuts an image file (see cutFilters); used by tools/see.js for a mark's crop.
const cut = (src, dest, o = {}) => still('CROP', ['-i', src], cutFilters(o), dest);

function look(o) {
	const point = /^(mouse|mark)$/.test(o.region || '');
	const info = point || o.game ? parseInfo(helper(o)) : null;
	if (o.game && !info.hwnd) throw new Error(`game: no window of a process matching /${o.exe || EXE}/i`);
	if (point) { const b = box(o, info, info.mouse, lastMark()); o = { ...o, region: `${b.x},${b.y},${b.w},${b.h}` }; }
	const dir = path.join(OUT, 'look'), s = source(o, 5, null, o.game && info.hwnd);
	const line = still('LOOK', s.input, [...s.pre, ...cutFilters(o)], path.join(dir, `look-${clock(new Date()).replace(/:/g, '')}.jpg`));
	const old = fs.readdirSync(dir).filter((f) => /^look-d+.jpg$/.test(f)).sort().reverse().slice(20);
	for (const f of old) fs.unlinkSync(path.join(dir, f));
	return line;
}

// The contact sheet of `show` (frames {n, time, file, mark}), each with its number and time (red: a flicker).
// Frames of a region `size` up to 640 px wide are tiled at native size under a label strip, as many a row as fit
// 1280 px; anything else as 320 px thumbnails, 4 a row.
function layout(count, size) {
	const native = !!size && size.w <= 640, tw = native ? size.w : 320;
	const cols = Math.max(1, Math.min(count, 8, Math.floor(1280 / tw)));
	return { native, tw, cols, rows: Math.ceil(count / cols) };
}
// How many tiles a sheet of about 900 tokens holds (4 to 48); 12 thumbnails for a whole picture.
const tiles = (size) => (size && size.w <= 640 ? Math.max(4, Math.min(48, Math.floor((900 * 750) / (size.w * (size.h + 16))))) : 12);

function sheet(dir, show, total, size) {
	const { native, tw, cols, rows } = layout(show.length, size);
	const font = path.join(process.env.WINDIR || 'C:\\Windows', 'Fonts', 'consola.ttf').replace(/\\/g, '/').replace(':', '\\:');
	const label = (k) => (fs.existsSync(font.replace('\\:', ':'))
		? `,drawtext=fontfile='${font}':text='${k.mark ? '*' : '#'}${k.n} ${k.time.replace(/:/g, '\\:')}':x=${native ? 1 : 4}:y=${native ? 2 : 4}:fontsize=${native ? 12 : 14}:fontcolor=${k.mark ? 'red' : 'white'}${native ? '' : ':box=1:boxcolor=black@0.7'}`
		: '');
	const fit = native ? 'pad=iw:ih+16:0:16' : `scale=${tw}:-2`;
	const graph = show.map((k, i) => `[${i}:v]${fit}${label(k)}[t${i}]`).join(';')
		+ `;${show.map((_, i) => `[t${i}]`).join('')}concat=n=${show.length}:v=1:a=0,tile=${cols}x${rows}${native ? ':padding=2:color=gray' : ''}`;
	const dest = path.join(dir, 'sheet.jpg');
	const log = ffmpeg([...show.flatMap((k) => ['-i', k.file]), '-filter_complex', graph, '-frames:v', '1', '-q:v', native ? '2' : '4', '-update', '1', dest]);
	const m = [...log.matchAll(/Video: mjpeg.*?, (\d+)x(\d+)/g)].pop();
	return `SHEET ${rel(dest)} ${m[1]}x${m[2]} ~${tokens(+m[1], +m[2])} tokens (${show.length} of ${total} frames${native ? ', native size' : ''}; one at full size: npm run crop ${rel(dir)}/f-<nnn>.jpg region=x,y,w,h)`;
}

// Frames that differ from both neighbours: `d[n]` is frame n's difference from the one before it.
const flickers = (d, thr) => d.map((v, n) => (v > thr && d[n + 1] > thr ? n : 0)).filter(Boolean);

// The frames a burst's sheet shows: the flickers with both neighbours (`diff`), else `max` in a row from `from`.
function pick(frames, flick, o, max) {
	if (!o.diff) return frames.filter((k) => k.n >= nums(o.from || 1, 1, 'from')[0]).slice(0, max);
	const want = new Set(flick.flatMap((n) => [n - 1, n, n + 1]));
	return frames.filter((k) => want.has(k.n)).slice(0, max);
}

function rec(o) {
	const burst = !!(o.strip || o.diff), one = (v, what) => nums(v, 1, what)[0];
	const fps = o.fps ? one(o.fps, 'fps') : burst ? 10 : 1 / one(o.every || 1, 'every');
	const secs = one(o.seconds || (burst ? 5 : 60), 'seconds'), thr = one(o.threshold || (burst ? 0.1 : 0.02), 'threshold');
	if (!(fps > 0 && fps <= 30)) throw new Error('fps: 30 at most');
	fs.mkdirSync(path.dirname(STOP), { recursive: true });
	fs.rmSync(STOP, { force: true });
	let focused = true, child = null, watch = null, info = null, buf = '';
	const waited = Date.now();
	const end = (msg) => { if (watch) watch.kill(); clearInterval(poll); fs.rmSync(STOP, { force: true }); if (msg) console.log(msg); };
	const poll = setInterval(() => {
		if (child) { if (fs.existsSync(STOP)) { clearInterval(poll); child.stdin.write('q'); } return; }
		if (fs.existsSync(STOP)) end('REC stopped before the game took focus');
		else if (Date.now() - waited > 60000) { end('REC gave up: the game window did not take focus in 60 s (`screen` records the monitor whatever has focus)'); process.exitCode = 1; }
	}, 250);

	const start = (mouse) => {
		const size = box(o, info, mouse, lastMark());
		const began = new Date();
		const stamp = `${began.getFullYear()}${String(began.getMonth() + 1).padStart(2, '0')}${String(began.getDate()).padStart(2, '0')}-${clock(began).replace(/:/g, '')}`;
		const dir = path.join(OUT, 'rec', stamp);
		fs.mkdirSync(dir, { recursive: true });
		const s = source(o, fps, size, info && info.hwnd);
		const file = (n) => path.join(dir, `f-${String(n).padStart(3, '0')}.jpg`);
		const jpg = ['-q:v', size ? '2' : '4', path.join(dir, 'f-%03d.jpg')];
		// metadata=print writes "frame:N pts:.. pts_time:T" then "<key>=V" to stdout for each frame it sees: the kept
		// ones' scene score, or in a burst every frame's mean difference (0-255) from the one before it.
		const args = burst
			? ['-filter_complex', `[0:v]${[...s.pre, o.text ? 'null' : 'split[o][d];[d]null'].join(',')},tblend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-:direct=1[n]`,
				...(o.text ? [] : ['-map', '[o]', ...jpg]), '-map', '[n]', '-f', 'null', '-']
			: ['-vf', [...s.pre, `select='eq(n,0)+gt(scene,${thr})'`, 'metadata=print:file=-:direct=1'].join(','), '-fps_mode', 'vfr', ...(o.text ? ['-f', 'null', '-'] : jpg)];
		// Self-check: the same region the way `look` cuts it (the whole monitor, then a crop), against frame 1 at the end.
		const check = size && !o.src && !o.text ? path.join(dir, 'look.jpg') : null;
		if (check) { const w = source(o, 5); still('LOOK', w.input, [...w.pre, `crop=${size.w}:${size.h}:${size.x}:${size.y}`], check); }
		child = spawn('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', '-t', String(secs), ...s.input, ...args], { stdio: ['pipe', 'pipe', 'inherit'] });
		const max = o.max ? one(o.max, 'max') : tiles(size);
		const what = size ? `region ${size.x},${size.y},${size.w},${size.h}` : info && info.hwnd ? 'the game window' : 'the monitor';
		const L = layout(max, size), th = size && L.native ? size.h + 16 : 180;
		console.log(`REC ${rel(dir)}/ ${what}${info && info.hwnd ? ', only while the game has focus' : ''}, ${burst ? `${fps} fps (${o.diff ? 'diff' : 'strip'})` : `every ${1 / fps}s`} for up to ${secs}s`
			+ `${o.text ? ', text only' : `; sheet up to ${max} tiles, ~${tokens(L.cols * L.tw, L.rows * th)} tokens`} (npm run rec:stop ends it)`);
		const keys = [], d = [, 0], away = new Set();
		let at = 0, n = 0, frame = 0;
		const say = (text) => { console.log(text); fs.appendFileSync(path.join(dir, 'frames.txt'), text + '\n'); };
		child.stdout.on('data', (chunk) => {
			buf += chunk;
			let nl;
			while ((nl = buf.indexOf('\n')) >= 0) {
				const line = buf.slice(0, nl); buf = buf.slice(nl + 1);
				const t = line.match(/frame:(\d+).*pts_time:([\d.]+)/), v = line.match(/(?:scene_score|YAVG)=([\d.]+)/);
				if (t) { frame = Number(t[1]); at = Number(t[2]); }
				if (!v) continue;
				n = burst ? frame + 2 : n + 1; // tblend has no first frame: its frame 0 is file 2
				if (!focused) { away.add(n); continue; }
				if (burst) { d[n] = Number(v[1]); continue; }
				const k = { n, time: clock(new Date(began.getTime() + at * 1000)) };
				if (!o.text) k.file = file(n);
				keys.push(k);
				say(`#${k.n} ${k.time} ${keys.length === 1 ? 'first frame' : `changed (score ${v[1]})`}${k.file ? ' ' + rel(k.file) : ''}`);
			}
		});
		child.on('error', () => { end(); console.error('ffmpeg is not on PATH (winget install Gyan.FFmpeg).'); process.exitCode = 1; });
		child.on('exit', () => {
			end();
			for (const a of away) fs.rmSync(file(a), { force: true });
			if (check && fs.existsSync(file(1))) {
				const v = Number((ffmpeg(['-i', check, '-i', file(1), '-filter_complex', '[0][1]blend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG', '-f', 'null', '-']).match(/YAVG=([0-9.]+)/) || [])[1]);
				console.log(`CHECK frame 1 against a look of the same region (${rel(check)}): mean difference ${v.toFixed(1)} of 255${v > 50 ? ' - WARNING: they differ wildly, the region may be off (or the picture changed within the first half second)' : ', the same place'}`);
			}
			let show = keys, total = keys.length;
			if (burst) {
				const flick = flickers(d, thr), is = new Set(flick);
				const frames = d.map((v, i) => ({ n: i, time: `+${((i - 1) / fps).toFixed(1)}s`, file: file(i), mark: is.has(i), v })).filter(Boolean);
				for (const k of frames) fs.appendFileSync(path.join(dir, 'frames.txt'), `#${k.n} ${k.time} diff ${k.v.toFixed(3)}${k.mark ? ' flicker' : ''}\n`);
				console.log(`${frames.length} frames, ${frames.filter((k) => k.v > thr).length} changed (mean difference over ${thr} of 255), ${flick.length} differ from both neighbours`
					+ (flick.length > frames.length / 2 ? ' (the picture moves all the time: read the strip, a flicker cannot be told apart)' : '')
					+ (flick.length ? ': ' + frames.filter((k) => k.mark).slice(0, 8).map((k) => `#${k.n} ${k.time} (${k.v.toFixed(2)})`).join(', ') + (flick.length > 8 ? ', ...' : '') : '')
					+ `; all in ${rel(dir)}/frames.txt`);
				show = pick(frames, flick, o, max); total = frames.length;
				if (!show.length && !o.text) console.log(`no sheet: nothing flickered (lower threshold=, or see them in a row: npm run rec:sheet ${rel(dir)} from=1)`);
			} else if (show.length > max) show = Array.from({ length: max }, (_, i) => keys[Math.floor((i * (keys.length - 1)) / Math.max(1, max - 1))]);
			show = show.filter((k) => k.file && fs.existsSync(k.file));
			if (show.length) console.log(sheet(dir, show, total, size));
			console.log(`REC done: ${total} frames${away.size ? `, ${away.size} dropped while the game had no focus` : ''}`);
		});
	};

	const point = /^(mouse|mark)$/.test(o.region || '');
	if (o.src || (o.screen && !point)) return start();
	if (o.screen) { info = { ...parseInfo(helper(o)), hwnd: 0 }; return start(info.mouse); }
	console.log('REC looking for the game window');
	watch = spawn('powershell', PS, { env: helperEnv(o, true), stdio: ['ignore', 'pipe', 'inherit'] });
	let wbuf = '';
	watch.stdout.on('data', (chunk) => {
		wbuf += chunk;
		let nl;
		while ((nl = wbuf.indexOf('\n')) >= 0) {
			const p = parseInfo(wbuf.slice(0, nl)); wbuf = wbuf.slice(nl + 1);
			if (p.sw) {
				info = p;
				if (!info.hwnd) console.log(`REC no game window (a process matching /${o.exe || EXE}/i): recording the monitor, whatever has focus`);
			}
			if (p.focus === undefined || !info) continue;
			focused = !info.hwnd || p.focus;
			if (!child && focused) start(p.mouse);
			else if (!child) console.log('REC waiting for the game window to take focus (60 s at most)');
		}
	});
	watch.on('exit', () => { if (!child && !info) { end('REC: the window helper (powershell) failed'); process.exitCode = 1; } });
}

// A sheet again from a finished run's frames: `max` in a row from frame `from`.
function resheet(dir, o) {
	const all = fs.readdirSync(dir).filter((f) => /^f-\d+\.jpg$/.test(f)).sort().map((f) => ({ n: Number(f.slice(2, -4)), time: '', file: path.join(dir, f) }));
	if (!all.length) throw new Error(`no frames in ${dir}`);
	const m = ffmpeg(['-i', all[0].file, '-f', 'null', '-']).match(/Video: mjpeg.*?, (\d+)x(\d+)/);
	const size = { w: Number(m[1]), h: Number(m[2]) };
	return sheet(dir, pick(all, [], { from: o.from }, o.max ? nums(o.max, 1, 'max')[0] : tiles(size)), all.length, size);
}

function main(argv) {
	const { o, pos } = parse(argv.slice(1));
	switch (argv[0]) {
		case 'look': console.log(look(o)); break;
		case 'crop': {
			if (!pos[0]) throw new Error('crop <image> [out] [region=x,y,w,h | at=fx,fy] [size=WxH] [scale=s] [fit=px]');
			console.log(cut(path.resolve(pos[0]), pos[1] ? path.resolve(pos[1]) : path.join(OUT, 'look', `crop-${clock(new Date()).replace(/:/g, '')}.jpg`), o));
			break;
		}
		case 'rec': rec(o); break;
		case 'sheet': {
			if (!pos[0]) throw new Error('sheet <run folder> [from=n] [max=n]');
			console.log(resheet(path.resolve(pos[0]), o));
			break;
		}
		case 'stop': fs.mkdirSync(path.dirname(STOP), { recursive: true }); fs.writeFileSync(STOP, ''); console.log('REC stop asked'); break;
		default: throw new Error('usage: node tools/look.js <look|crop|rec|sheet|stop> [options] (see the file header)');
	}
}

if (require.main === module) {
	try { main(process.argv.slice(2)); } catch (e) { console.error(e.message); process.exitCode = 1; }
}
module.exports = { cut, parse, cutFilters, box, parseInfo, layout, tiles, flickers, pick };
