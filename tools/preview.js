'use strict';
// Renders Polestar: UI's windows outside the game, the way Polestar's
// `tools/commands/preview.js` does (fonts, metrics and dumpPanel from there):
// Polestar and Polestar: UI run on the client stub (tests/lua), every frame is
// dumped and drawn as SVG by tools/preview/render.js. Output is byte-identical
// run to run, so tests/preview.test.js compares it with tests/golden.
//
//   node tools/preview.js            render every scene into tests/golden
//   node tools/preview.js character  only the scenes named

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

// Scenes: Lua run once the player has logged in. `roots` names the frames drawn.
const SCENES = [
	{ file: 'character.svg', title: 'Character', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character")' }] },
	{ file: 'character-primary-tank.svg', title: 'Character: Gear, Tank (the same choice as the Stats tab)', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUICharDB.archetype = "tank"; PolestarUI.Show("character")' }] },
	// An enchant waiting for its item: hovering a slot puts the secure overlay over it, targeting that slot (and using it on a right-click).
	{ file: 'character-enchant.svg', title: 'Character: an enchant over the head slot', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character"); stub.targeting = true; local s; for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 1 then s = c end end; stub.RunScript(s, "OnEnter"); local a = PolestarUICharacterSlot; assert(a and a:IsShown(), "no overlay"); assert(a:GetAttribute("*target-slot*") == 1, "wrong slot"); assert(a:GetAttribute("type2") == "item" and a:GetAttribute("item") == "1", "no use"); for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 2 then stub.RunScript(c, "OnEnter") end end; assert(a:GetAttribute("type2") == nil and a:GetAttribute("*target-slot*") == 2, "empty slot")' }] },
	// Stats read once, then secret out of combat: the rows keep what they read, and no secret reaches our strings.
	{ file: 'character-stats-secret.svg', title: 'Character: Stats gone secret', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "PaperDollFrame", "stats"); stub.secretStats = true; stub.fire("UNIT_STATS", "player")' }] },
	// An enchant started from the bags while the window is open: the game's "show it" must not close it.
	{ file: 'character-enchant-open.svg', title: 'Character: an enchant started while open', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character"); ShowCharacterFrameIfMatchesContext(); assert(PolestarUICharacter:IsShown(), "the window closed")' }] },
	// Polestar's gear advice finds upgrades in the bags for the shoulders and main hand; the cursor holds a ring.
	{ file: 'character-upgrades.svg', title: 'Character: upgrades in the bags, a ring held', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'Polestar.Gear = { Bags = { IsOn = function() return true end, IsUpgrade = function() return true end }, CompareToEquipped = function(link) return { slot = link:find("item:91") and 3 or 16 } end }; stub.cursorFits = { [11] = true, [12] = true }; PolestarUI.Show("character")' }] },
	{ file: 'character-stats.svg', title: 'Character: Stats', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "PaperDollFrame", "stats")' }] },
	{ file: 'character-stats-tank.svg', title: 'Character: Stats, Tank', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUICharDB.archetype = "tank"; PolestarUI.Show("character", "PaperDollFrame", "stats")' }] },
	{ file: 'character-reputation.svg', title: 'Character: Reputation', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "ReputationFrame")' }] },
	{ file: 'character-currency.svg', title: 'Character: Currency', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "TokenFrame")' }] },
	{ file: 'character-honor.svg', title: 'Character: Honor', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "PVPRankFrame")' }] },
	{ file: 'character-skills.svg', title: 'Character: Skills', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "SkillsFrame")' }] },
	{ file: 'character-statistics.svg', title: 'Character: Statistics, folded', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "StatisticsFrame")' }] },
	// A heading opens its category, and a sub-category row opens under it, each redrawn at once.
	{ file: 'character-statistics-open.svg', title: 'Character: Statistics, a category open', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "StatisticsFrame"); local v = PolestarUICharacter.psPages.StatisticsFrame; v.groups[1].Hit:Click(); v.groups[1].rows[3]:Click()' }] },
	// A click on a group's chevron folds it, and the page redraws without an event.
	{ file: 'character-currency-folded.svg', title: 'Character: Currency, a group folded', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "TokenFrame"); PolestarUICharacter.psPages.TokenFrame.groups[1].Hit:Click()' }] },
	// First opened mid-fight: the stats and name read in the background before it still show, and the model's tooltip takes no secret name.
	{ file: 'character-stats-combat.svg', title: 'Character: Stats in combat', panels: [{ roots: ['PolestarUICharacter'], stubs: ['stub_character.lua'], script: 'stub.fire("PLAYER_ENTERING_WORLD"); stub.advance(1); stub.inCombat = true; PolestarUI.Show("character", "PaperDollFrame", "stats"); stub.RunScript(PolestarUICharacter.psGear.Model, "OnEnter")' }] },
];

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
		stubs: ['stub_ui.lua', 'stub_client.lua', ...(panel.stubs || [])],
		before: `${prelude}\ndofile(${JSON.stringify(path.join(ROOT, 'tools', 'preview', 'stub.lua'))})`,
		addons: [{ name: 'Polestar', files: POLESTAR_FILES }, { name: 'Polestar_UI', dir: ROOT }],
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
	const only = process.argv.slice(2);
	const out = render(only);
	if (!Object.keys(out).length) {
		console.error(`no preview scene named ${only.join(', ')}`);
		process.exit(2);
	}
	fs.mkdirSync(GOLDEN, { recursive: true });
	for (const [file, r] of Object.entries(out)) {
		fs.writeFileSync(path.join(GOLDEN, file), r.svg);
		console.log(path.relative(ROOT, path.join(GOLDEN, file)));
	}
}
