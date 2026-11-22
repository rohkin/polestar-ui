'use strict';
// tools/see.js against a made-up game folder (saved variables, BugGrabber's log, a screenshot), and the
// PolestarUI_See addon under the client stub.

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { parseSaved, digest } = require('../tools/see');
const { dumpPanel, metricsLua, loadFonts } = require('../tools/preview');

const T = new Date(2026, 10, 15, 22, 29, 10).getTime() / 1000;
const SAVED = `
PolestarUISeeDB = {
["marks"] = {
"${T - 500}|0.1000|0.1000|\\n(an old one)", -- [1]
"${T}|0.7500|0.2500|the \\"Buy\\" tab eats clicks\\ncombat=false effScale=0.711\\nfocus: PolestarUIMerchant.Tabs.2 [Button] MEDIUM/12 mouse a=1.00 80x36 @812,300\\nstock shown: merchant=MerchantFrame(mouse) !!", -- [2]
},
["session"] = 343,
["events"] = {
"${T - 900} load", -- [1]
"${T - 800} show bags", -- [2]
"${T - 60} load", -- [3]
"${T - 5} show merchant", -- [4]
"${T} mark the \\"Buy\\" tab eats clicks", -- [5]
},
["info"] = "build=1.60.1.70338 res=1920x1080\\naddons: PolestarUI=0.1.0",
}
`;
const BUGS = `
BugGrabberDB = {
["session"] = 343,
["errors"] = {
{
["message"] = "Interface/AddOns/PolestarUI/Core.lua:10: old",
["time"] = ${T - 5000},
["stack"] = "[Interface/AddOns/PolestarUI/Core.lua]:10: in function 'x'\\n",
["session"] = 340,
["counter"] = 1,
},
{
["message"] = "Interface/AddOns/PolestarUI/Modules/Merchant.lua:42: attempt to index local 'row' (a nil value)",
["time"] = ${T - 3},
["stack"] = "[Interface/AddOns/PolestarUI/Modules/Merchant.lua]:42: in function 'paint'\\n[Interface/AddOns/!BugGrabber/BugGrabber.lua]:1: in function <x>\\n",
["session"] = 343,
["counter"] = 4,
},
{
["message"] = "Interface/AddOns/Questie/Q.lua:1: theirs",
["time"] = ${T - 2},
["stack"] = "[Interface/AddOns/Questie/Q.lua]:1: in function 'q'\\n",
["session"] = 343,
["counter"] = 1,
},
},
}
`;

test('the saved table parses into marks, events and info', () => {
	const db = parseSaved(SAVED);
	assert.strictEqual(db.session, 343);
	assert.deepStrictEqual([db.marks[1].t, db.marks[1].fx, db.marks[1].fy, db.marks[1].note], [T, 0.75, 0.25, 'the "Buy" tab eats clicks']);
	assert.match(db.marks[1].body, /^combat=false.*\nfocus: PolestarUIMerchant/);
	assert.strictEqual(db.events.length, 5);
	assert.strictEqual(db.info.split('\n')[1], 'addons: PolestarUI=0.1.0');
});

test('a digest lists the new marks, this session\'s errors and the events since the load, with small images', () => {
	const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pui-see-'));
	const sv = path.join(root, 'WTF', 'Account', 'X', 'SavedVariables'), shots = path.join(root, 'Screenshots'), out = path.join(root, 'out');
	for (const d of [sv, shots, out]) fs.mkdirSync(d, { recursive: true });
	fs.writeFileSync(path.join(sv, 'PolestarUI_See.lua'), SAVED);
	fs.writeFileSync(path.join(sv, '!BugGrabber.lua'), BUGS);
	fs.writeFileSync(path.join(out, 'see.json'), JSON.stringify({ marks: [T - 500], session: 342 }));
	// A fake screenshot stamped a second after the mark, when ffmpeg is here to make and cut it.
	const shot = path.join(shots, 'WoWScrnShot_111526_222911.jpg');
	const ff = spawnSync('ffmpeg', ['-hide_banner', '-y', '-f', 'lavfi', '-i', 'color=c=gray:s=1920x1080', '-frames:v', '1', '-update', '1', shot]).status === 0;
	try {
		const r = digest(root, ff ? { out } : { out, cut: false });
		assert.deepStrictEqual([r.marks, r.ours, r.errors], [1, 1, 2]);
		const text = fs.readFileSync(r.file, 'utf8');
		assert.match(text, /### 22:29:10 "the "Buy" tab eats clicks"/);
		assert.match(text, /stock shown: merchant=MerchantFrame\(mouse\) !!/);
		assert.doesNotMatch(text, /an old one/);
		assert.match(text, /22:29:07 x4 Interface\/AddOns\/PolestarUI\/Modules\/Merchant\.lua:42/);
		assert.match(text, / {4}\[PolestarUI\/Modules\/Merchant\.lua\]:42: in function 'paint'/);
		assert.doesNotMatch(text, /Core\.lua:10: old|BugGrabber\.lua\]/);
		assert.match(text, /- 22:29:08 x1 Interface\/AddOns\/Questie/);
		assert.match(text, /## Events \(3\)/);
		assert.doesNotMatch(text, /show bags/);
		assert.match(text, /WARNING: .* is not a link to this checkout/);
		if (ff) {
			assert.match(text, /mark-222910\.jpg 640x400 ~342 tokens/);
			assert.match(text, /mark-222910-full\.jpg 960x540 ~692 tokens/);
			assert.ok(fs.statSync(path.join(out, 'see', 'mark-222910.jpg')).size > 0);
		}
		assert.strictEqual(digest(root, { out, cut: false }), null, 'nothing new the second time');
	} finally {
		fs.rmSync(root, { recursive: true, force: true });
	}
});

test('the See addon marks under the client stub', () => {
	const file = path.join(__dirname, '..', 'tools', 'see', 'PolestarUI_See', 'See.lua').replace(/\\/g, '/');
	const script = `
Screenshot = function() stub.shot = (stub.shot or 0) + 1 end
assert(loadfile("${file}"))("PolestarUI_See", {})
stub.addonLoaded("PolestarUI_See")
stub.fire("PLAYER_ENTERING_WORLD", true, false)
PolestarUI.Show("spellbook")
SlashCmdList.POLESTARUISEE("  the tab | eats clicks ")
local db = PolestarUISeeDB
assert(#db.marks == 1 and stub.shot == 1, "no mark")
local head, body = db.marks[1]:match("^(.-)\\n(.*)$")
assert(head:match("^%d+|[%d.]+|[%d.]+|the tab eats clicks$"), head)
assert(not body:find("failed", 1, true), body)
assert(body:find("ours shown: spellbook", 1, true), body)
assert(db.info:find("res=1920x1080", 1, true), db.info)
local seen = {}
for _, e in ipairs(db.events) do seen[e:gsub("^%d+ ", "")] = true end
assert(seen["load"] and seen["show spellbook"] and seen["mark the tab eats clicks"], table.concat(db.events, "; "))
SlashCmdList.POLESTARUISEE("again")
assert(#db.marks == 1, "a second mark within 2 s")
`;
	dumpPanel({ roots: [], stubs: ['stub_spellbook.lua'], script, saved: '' }, metricsLua(loadFonts()));
});

test('look.js: regions, sheet layout and flicker frames', () => {
	const look = require('../tools/look');
	const info = look.parseInfo('INFO 67398 0 0 1920 1080 1920 1080\r\nF 1 630 389\r\n');
	assert.deepStrictEqual(info, { hwnd: 67398, game: { x: 0, y: 0, w: 1920, h: 1080 }, sw: 1920, sh: 1080, focus: true, mouse: [630, 389] });
	assert.strictEqual(look.parseInfo('INFO 0 0 0 0 0 1920 1080').game, null);
	assert.strictEqual(look.box({}, info, info.mouse), null);
	assert.deepStrictEqual(look.box({ region: '10,20,300,200' }, info), { x: 10, y: 20, w: 300, h: 200 });
	assert.deepStrictEqual(look.box({ region: 'mouse', size: '200x100' }, info, info.mouse), { x: 530, y: 339, w: 200, h: 100 });
	assert.deepStrictEqual(look.box({ region: 'mouse' }, info, [1900, 5]), { x: 1280, y: 0, w: 640, h: 400 }, 'kept on the screen');
	assert.deepStrictEqual(look.box({ region: 'mark', size: '200x100' }, info, null, [0.75, 0.25]), { x: 1340, y: 220, w: 200, h: 100 });
	assert.throws(() => look.box({ region: 'mark' }, info, null, null), /no \/puisee mark/);
	// d[n]: frame n's difference from the one before; 4 differs from 3 and 5 from 4, so 4 is the flicker.
	assert.deepStrictEqual(look.flickers([, 0, 0, 0, 3.5, 3.5, 0, 2, 0], 0.1), [4]);
	const frames = [1, 2, 3, 4, 5, 6, 7, 8].map((n) => ({ n }));
	assert.deepStrictEqual(look.pick(frames, [4], { diff: true }, 12).map((k) => k.n), [3, 4, 5]);
	assert.deepStrictEqual(look.pick(frames, [], { from: '6' }, 2).map((k) => k.n), [6, 7]);
	assert.deepStrictEqual(look.layout(12, null), { native: false, tw: 320, cols: 4, rows: 3 });
	assert.deepStrictEqual(look.layout(20, { w: 200, h: 60 }), { native: true, tw: 200, cols: 6, rows: 4 });
	assert.strictEqual(look.tiles(null), 12);
	assert.strictEqual(look.tiles({ w: 200, h: 60 }), 44);
	assert.strictEqual(look.tiles({ w: 640, h: 400 }), 4);
});

test('look.js: a burst over a made-up picture finds the one flicker frame', (t) => {
	if (spawnSync('ffmpeg', ['-version']).error) return t.skip('no ffmpeg');
	const src = "color=c=gray:s=200x60:r=10,drawbox=enable='eq(n,7)':color=black:t=fill:w=200:h=2:y=30";
	const r = spawnSync(process.execPath, [path.join(__dirname, '..', 'tools', 'look.js'), 'rec', 'diff', 'text', 'seconds=2', `src=${src}`], { encoding: 'utf8' });
	assert.match(r.stdout, /20 frames, 2 changed .*, 1 differ from both neighbours: #8 \+0\.7s/, r.stdout + r.stderr);
	fs.rmSync(path.join(__dirname, '..', r.stdout.match(/REC (\S+)\//)[1]), { recursive: true, force: true });
});
