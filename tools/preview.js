'use strict';
// Renders Polestar: UI's windows outside the game, the way Polestar's
// `tools/commands/preview.js` does (fonts, metrics and dumpPanel from there):
// Polestar and Polestar: UI run on the client stub (tests/lua), every frame is
// dumped and drawn as SVG by tools/preview/render.js. Output is byte-identical
// run to run, so tests/preview.test.js compares it with tests/golden.
//
//   node tools/preview.js            render every scene into tests/golden
//   node tools/preview.js character  only the scenes named
//   node tools/preview.js --check character  compare only (blesses nothing), exit 1 on a mismatch

const fs = require('node:fs');
const path = require('node:path');
const { runAddon, ROOT, POLESTAR_DIR } = require('../tests/helpers/lua');
const { Font } = require('./preview/font');
const { svg, compose, TextureCache } = require('./preview/render');

const POLESTAR = path.join(POLESTAR_DIR, 'addon', 'Polestar');
const GOLDEN = path.join(ROOT, 'tests', 'golden');
const POLESTAR_FILES = ['Core/Core.xml', 'Theme/Theme.xml'];
const FONT_FILES = ['OpenSans-Regular.ttf', 'OpenSans-Bold.ttf', 'Inter-Regular.ttf', 'Inter-Medium.ttf', 'Inter-SemiBold.ttf', 'FiraSans-Regular.ttf', 'FiraSans-Medium.ttf', 'FiraSans-SemiBold.ttf'];
// The client's own font cannot ship: it is drawn in the nearest Inter weight.
const FALLBACK = 'Inter-Medium.ttf';

// Scenes: one file each in tests/scenes/<name>.lua, Lua run once the player has
// logged in. Leading `--@ key: value` lines give the title, the `roots` (frames
// drawn), extra `stubs` (tests/lua; stub_character.lua is always loaded) and
// `saved` variables; a `--@ panel` line starts a further panel (its own header).
const SCENE_DIR = path.join(ROOT, 'tests', 'scenes');

function parseScene(name, text) {
	const scene = { file: name + '.svg', title: name, panels: [] };
	for (const block of text.split(/^--@ panel\r?\n/m)) {
		const panel = { roots: [], stubs: [], script: '' };
		const body = [];
		for (const line of block.split(/\r?\n/)) {
			const m = /^--@ (\w+): (.*)$/.exec(line);
			if (!m) body.push(line);
			else if (m[1] === 'title') scene.title = m[2];
			else if (m[1] === 'roots' || m[1] === 'stubs') panel[m[1]] = m[2].split(/,\s*/);
			else if (m[1] === 'saved') panel.saved = m[2];
			else throw new Error(name + '.lua: unknown header ' + m[1]);
		}
		panel.script = body.join('\n');
		scene.panels.push(panel);
	}
	return scene;
}

const SCENES = fs.readdirSync(SCENE_DIR).filter((f) => f.endsWith('.lua')).sort().map((f) => parseScene(f.slice(0, -4), fs.readFileSync(path.join(SCENE_DIR, f), 'utf8')));


function loadFonts() {
	const fonts = {};
	for (const f of FONT_FILES) fonts[f] = new Font(path.join(POLESTAR, 'Media', 'Fonts', f));
	return new Proxy(fonts, { get: (t, k) => t[k] || t[FALLBACK] });
}

// Advance widths (em) for every code point the UI can plausibly show.
function metricsLua(fonts) {
	const cps = [];
	for (let c = 32; c < 127; c++) cps.push(c);
	for (let c = 0xa0; c < 0x180; c++) cps.push(c);
	cps.push(0x2013, 0x2014, 0x2018, 0x2019, 0x201c, 0x201d, 0x2026, 0x2022, 0x00b7, 0x00d7, 0x2192);
	const parts = FONT_FILES.map((file) => {
		const f = fonts[file];
		const adv = cps.map((c) => `[${c}]=${f.advanceEm(c).toFixed(5)}`).join(',');
		return `[${JSON.stringify(file)}]={upm=${f.upm},fallback=${f.advanceEm(0x6e).toFixed(5)},adv={${adv}}}`;
	});
	return `preview = { metrics = { ${parts.join(',')} }, fallbackFont = ${JSON.stringify(FALLBACK)} }`;
}

function dumpPanel(panel, prelude) {
	const { emitted } = runAddon({
		stubs: ['stub_ui.lua', 'stub_ui_local.lua', 'stub_client.lua', 'stub_character.lua', ...panel.stubs],
		before: `${prelude}\ndofile(${JSON.stringify(path.join(ROOT, 'tools', 'preview', 'stub.lua'))})`,
		addons: [{ name: 'Polestar', files: POLESTAR_FILES }, { name: 'Polestar_UI', dir: ROOT }],
		saved: panel.saved && { Polestar_UI: panel.saved },
		script: `uistub.install()\nstub.login()\n${panel.script}\nstub.advance(1)\npreview.emit()`,
	});
	const dump = emitted[emitted.length - 1];
	if (!dump || !dump.objects) throw new Error('preview: the scene emitted no frames');
	return dump;
}

// { file: { svg, dumps } } for the scenes named (all when none).
function render(only = []) {
	const fonts = loadFonts();
	const textures = new TextureCache(path.join(POLESTAR, 'Media', 'UI'));
	const prelude = metricsLua(fonts);
	const out = {};
	for (const scene of SCENES) {
		if (only.length && !only.includes(scene.file.replace(/\.svg$/, ''))) continue;
		const shared = { glyphs: new Set(), defs: [] };
		const dumps = scene.panels.map((p) => dumpPanel(p, prelude));
		const panels = dumps.map((d, i) => svg(d, { fonts, textures, roots: scene.panels[i].roots, prefix: `p${i}`, shared }));
		out[scene.file] = { svg: compose(panels, { title: scene.title, shared }), dumps };
	}
	return out;
}

module.exports = { SCENES, GOLDEN, render, loadFonts };

if (require.main === module) {
	const args = process.argv.slice(2);
	const check = args.includes('--check');
	const only = args.filter((a) => a !== '--check');
	const out = render(only);
	if (!Object.keys(out).length) {
		console.error('no preview scene named ' + only.join(', '));
		process.exit(2);
	}
	fs.mkdirSync(GOLDEN, { recursive: true });
	let bad = 0;
	for (const [file, r] of Object.entries(out)) {
		const golden = path.join(GOLDEN, file);
		if (check) {
			const same = fs.existsSync(golden) && fs.readFileSync(golden, 'utf8') === r.svg;
			if (!same) bad++;
			console.log((same ? 'ok       ' : 'MISMATCH ') + path.relative(ROOT, golden));
		} else {
			fs.writeFileSync(golden, r.svg);
			console.log(path.relative(ROOT, golden));
		}
	}
	if (bad) process.exit(1);
}
