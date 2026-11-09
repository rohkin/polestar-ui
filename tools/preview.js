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
	{ file: 'character.svg', title: 'Character', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character")' }] },
	// An enchant waiting for its item: hovering a slot puts the secure overlay over it, targeting that slot (and using it on a right-click).
	{ file: 'character-enchant.svg', title: 'Character: an enchant over the head slot', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character"); stub.targeting = true; local s; for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 1 then s = c end end; stub.RunScript(s, "OnEnter"); local a = PolestarUICharacterSlot; assert(a and a:IsShown(), "no overlay"); assert(a:GetAttribute("*target-slot*") == 1, "wrong slot"); assert(a:GetAttribute("type2") == "item" and a:GetAttribute("item") == "1", "no use"); for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 2 then stub.RunScript(c, "OnEnter") end end; assert(a:GetAttribute("type2") == nil and a:GetAttribute("*target-slot*") == 2, "empty slot")' }] },
	// Stats read once, then secret out of combat: the rows keep what they read, and no secret reaches our strings.
	{ file: 'character-stats-secret.svg', title: 'Character: Stats gone secret', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character"); stub.secretStats = true; stub.fire("UNIT_STATS", "player")' }] },
	// An enchant started from the bags while the window is open: the game's "show it" must not close it.
	{ file: 'character-enchant-open.svg', title: 'Character: an enchant started while open', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character"); ShowCharacterFrameIfMatchesContext(); assert(PolestarUICharacter:IsShown(), "the window closed")' }] },
	// Polestar's gear advice finds upgrades in the bags for the shoulders and main hand; the cursor holds a ring.
	{ file: 'character-upgrades.svg', title: 'Character: upgrades in the bags, a ring held', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'Polestar.Gear = { Bags = { IsOn = function() return true end, IsUpgrade = function() return true end }, CompareToEquipped = function(link) return { slot = link:find("item:91") and 3 or 16 } end }; stub.cursorFits = { [11] = true, [12] = true }; PolestarUI.Show("character")' }] },
	{ file: 'character-stats.svg', title: 'Character: stats put away', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character"); PolestarUICharacter.psToggle:Click(); assert(not PolestarUICharacterStats:IsShown(), "still shown"); assert(PolestarUIDB.hideStats, "not kept")' }] },
	{ file: 'character-stats-folded.svg', title: 'Character: a stats category folded', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character"); local v = PolestarUICharacterStats.Body; v.sections[2].Hit:Click(); assert(not v.sections[2].Panel:IsShown(), "not folded"); assert(PolestarUIDB.statsFolded[v.sections[2].name], "not kept")' }] },
	{ file: 'character-reputation.svg', title: 'Character: Reputation', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "ReputationFrame")' }] },
	{ file: 'character-currency.svg', title: 'Character: Currency', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "TokenFrame")' }] },
	{ file: 'character-honor.svg', title: 'Character: Honor', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "PVPRankFrame")' }] },
	{ file: 'character-skills.svg', title: 'Character: Skills', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "SkillsFrame")' }] },
	{ file: 'character-statistics.svg', title: 'Character: Statistics, folded', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "StatisticsFrame")' }] },
	// A heading opens its category, and a sub-category row opens under it, each redrawn at once.
	{ file: 'character-statistics-open.svg', title: 'Character: Statistics, a category open', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "StatisticsFrame"); local v = PolestarUICharacter.psPages.StatisticsFrame; v.groups[1].Hit:Click(); v.groups[1].rows[3]:Click()' }] },
	// A click on a group's chevron folds it, and the page redraws without an event.
	{ file: 'character-currency-folded.svg', title: 'Character: Currency, a group folded', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'PolestarUI.Show("character", "TokenFrame"); PolestarUICharacter.psPages.TokenFrame.groups[1].Hit:Click()' }] },
	// First opened mid-fight: the stats and name read in the background before it still show, and the model's tooltip takes no secret name.
	{ file: 'character-stats-combat.svg', title: 'Character: Stats in combat', panels: [{ roots: ['PolestarUICharacter', 'PolestarUICharacterStats'], stubs: ['stub_character.lua'], script: 'stub.fire("PLAYER_ENTERING_WORLD"); stub.advance(1); stub.inCombat = true; PolestarUI.Show("character"); stub.RunScript(PolestarUICharacter.psGear.Model, "OnEnter")' }] },
	// The spellbook key opens ours without the stock book, and closes it again (docs/CLIENT.md, rule 8).
	{ file: 'spellbook.svg', title: 'Spellbook: Fire', panels: [{ roots: ['PolestarUISpellbook'], stubs: ['stub_character.lua', 'stub_spellbook.lua'], script: 'stub.pressKey("P"); assert(not PlayerSpellsFrame:IsShown(), "stock book open"); assert(PolestarUISpellbook:IsShown(), "ours closed"); stub.pressKey("P"); assert(not PolestarUISpellbook:IsShown(), "no toggle"); PolestarUI.Show("spellbook", "line3")' }] },
	// Lower ranks hidden (the stock setting), a passive and a spell not learned yet; hovering a spell puts the secure cast button over it, a passive gets none.
	{ file: 'spellbook-arcane.svg', title: 'Spellbook: Arcane', panels: [{ roots: ['PolestarUISpellbook'], stubs: ['stub_character.lua', 'stub_spellbook.lua'], script: 'PolestarUI.Show("spellbook", "line2"); local f = PolestarUISpellbook; local byName = {}; for _, c in ipairs({ f.Body:GetChildren() }) do if c.psSpell and c:IsShown() then byName[c.psSpell.info.name] = c end end; assert(not byName["Arcane Missiles"] or byName["Arcane Missiles"].psSpell.info.subName == "Rank 3", "low rank shown"); stub.RunScript(byName["Blink"], "OnEnter"); local o = PolestarUISpellbookCast; assert(o and o:IsShown() and o:GetAttribute("type1") == "spell" and o:GetAttribute("spell") == 107, "no cast"); stub.RunScript(byName["Arcane Mind"], "OnEnter"); assert(o:GetAttribute("type1") == nil, "passive casts")' }] },
	// A pet's book: right-click toggles autocast (the game's slash command on the secure button); a pet command does not cast.
	{ file: 'spellbook-pet.svg', title: 'Spellbook: Pet', panels: [{ roots: ['PolestarUISpellbook'], stubs: ['stub_character.lua', 'stub_spellbook.lua'], script: 'stub.pet = true; PolestarUI.Show("spellbook", "pet"); local byName = {}; for _, c in ipairs({ PolestarUISpellbook.Body:GetChildren() }) do if c.psSpell and c:IsShown() then byName[c.psSpell.info.name] = c end end; stub.RunScript(byName["Growl"], "OnEnter"); local o = PolestarUISpellbookCast; assert(o:GetAttribute("type2") == "macro" and o:GetAttribute("macrotext") == "/petautocasttoggle Growl", "no autocast"); assert(o:GetAttribute("type1") == "spell" and o:GetAttribute("spell") == "Growl", "no cast"); stub.RunScript(byName["Attack"], "OnEnter"); assert(o:GetAttribute("type1") == nil and o:GetAttribute("type2") == nil, "command casts")' }] },
	// The sidebar search looks through every category.
	{ file: 'spellbook-search.svg', title: 'Spellbook: search', panels: [{ roots: ['PolestarUISpellbook'], stubs: ['stub_character.lua', 'stub_spellbook.lua'], script: 'PolestarUI.Show("spellbook"); local s = PolestarUISpellbook.Search; s:SetText("fire"); stub.RunScript(s, "OnTextChanged")' }] },
	// The talents key opens ours and closes it, in combat too, never touching the stock window; the micro button's overlay opens ours on a click and hands a shift-click to the micro button from secure code (docs/CLIENT.md, rule 8). Frost learnt, a point staged in Arcane.
	{ file: 'talents.svg', title: 'Talents', panels: [{ roots: ['PolestarUITalents'], stubs: ['stub_character.lua', 'stub_talents.lua'], script: 'stub.noPoints = true; stub.pressKey("N"); assert(not PolestarUITalents or not PolestarUITalents:IsShown(), "opened before the first talent point"); stub.noPoints = false; stub.pressKey("N"); assert(PolestarUITalents:IsShown() and not PlayerSpellsFrame:IsShown(), "key"); stub.pressKey("N"); assert(not PolestarUITalents:IsShown(), "no toggle"); stub.inCombat = true; stub.pressKey("N"); assert(PolestarUITalents:IsShown(), "not in combat"); stub.pressKey("N"); stub.inCombat = false; stub.advance(0.1); local o = PolestarUITalentsMicro; assert(o:IsShown() and o:GetAttribute("shift-type1") == "click" and o:GetAttribute("clickbutton") == TalentMicroButton, "no overlay"); assert(o:GetFrameStrata() == "HIGH" and o:GetFrameLevel() > 40, "overlay under the micro button"); stub.RunScript(o, "PostClick", "LeftButton"); assert(PolestarUITalents:IsShown() and not PlayerSpellsFrame:IsShown(), "micro")' }] },
	// Before dual spec, Secondary is listed locked: a click does nothing, its tooltip says how to learn it. The search marks the talents whose name or description matches.
	{ file: 'talents-search.svg', title: 'Talents: search, Secondary locked', panels: [{ roots: ['PolestarUITalents'], stubs: ['stub_character.lua', 'stub_talents.lua'], script: 'PolestarUI.Show("talents"); local f = PolestarUITalents; local sec; for _, b in ipairs(f.navButtons) do if b.psKey == 2 and b:IsShown() then sec = b end end; assert(sec, "no Secondary"); sec:Click(); assert(f.Title:GetText() == "Talents" and not f.Subtitle:GetText():find("active spec"), "locked spec opened"); stub.RunScript(sec, "OnEnter"); assert(table.concat(GameTooltip.lines, "/"):find("trainer"), "no unlock hint"); local s = f.Search; s:SetText("frost"); stub.RunScript(s, "OnTextChanged"); assert(f.Subtitle:GetText():find("talents? match"), "no count: " .. f.Subtitle:GetText())' }] },
	// Spending: right-click takes the staged Arcane point back, a click puts it into Frost; Apply and Undo show while something is staged; Apply commits as a cast, the window waiting until it ends; Undo drops what is staged.
	{ file: 'talents-spend.svg', title: 'Talents: a point staged', panels: [{ roots: ['PolestarUITalents'], stubs: ['stub_character.lua', 'stub_talents.lua'], script: 'PolestarUI.Show("talents"); local f = PolestarUITalents; local function find(test) for _, c in ipairs({ f.Body:GetChildren() }) do if c.psInfo and c:IsShown() and test(c.psInfo) then return c end end end; local function footer() local k = 0; for _, b in ipairs(f.footerButtons.right) do assert(b:IsShown(), "a footer button hidden: the layout would move"); if b:IsEnabled() then k = k + 1 end end; return k end; local function sub() return f.Subtitle:GetText() end; assert(footer() == 2 and sub():find("not applied"), "a staged point: " .. sub()); local function frost() return find(function(n) return n.currentRank == 0 and n.isAvailable and n.meetsEdgeRequirements and n.groupIDs[1] == 1003 end) end; assert(frost().Icon.desaturated, "an open talent with no point to spend is not greyed, as the stock button greys it"); f.footerButtons.right[2]:Click(); assert(footer() == 0 and sub():find("1 point to spend"), "undo: " .. sub()); assert(not frost().Icon.desaturated, "an open talent with a point to spend is greyed"); local open = find(function(n) return n.canPurchaseRank and n.groupIDs[1] == 1003 end); local id, rank = open.psInfo.ID, open.psInfo.currentRank; local headW = f.psHeads[3]:GetWidth(); open:Click("LeftButton"); assert(f.psHeads[3]:GetWidth() == headW, "the Frost heading moved as its count changed"); assert(find(function(n) return n.ID == id end).psInfo.currentRank == rank + 1 and footer() == 2, "purchase"); find(function(n) return n.ID == id end):Click("RightButton"); assert(footer() == 0 and find(function(n) return n.ID == id end).psInfo.currentRank == rank, "refund"); find(function(n) return n.ID == id end):Click("LeftButton"); f.footerButtons.right[1]:Click(); assert(stub.committing and sub():find("Applying") and footer() == 0, "apply"); find(function(n) return n.canRefundRank end):Click("RightButton"); assert(find(function(n) return n.ID == id end).psInfo.currentRank == rank + 1, "changed while applying"); stub.finishCommit(); assert(sub():find("Every point is spent") and footer() == 0, "commit did not end: " .. sub()); find(function(n) return n.canPurchaseRank or true end); PolestarUI.Show("talents"); stub.RunScript(find(function(n) return n.ID == id end), "OnEnter")' }] },
	// Dual spec learnt: Secondary (Fire) in the sidebar with its points; viewing it says it is not the active spec.
	{ file: 'talents-secondary.svg', title: 'Talents: Secondary', panels: [{ roots: ['PolestarUITalents'], stubs: ['stub_character.lua', 'stub_talents.lua'], script: 'stub.dual = true; PolestarUI.Show("talents", 2); local f = PolestarUITalents; assert(f.psArt[2]:IsShown() and f.psTint[2]:IsShown() and f.psArt[1].gradient.min[4] == 0 and f.psArt[3].gradient.max[4] == 0 and f.psArt[6].gradient.max[4] == 0 and f.psArt[9].gradient.max[4] == 0, "no class art, or not feathered at its sides and seams")' }] },
	// The stock talent tooltip's lines: rank, subtext, this and the next rank's text; a locked talent names its tier gate.
	{ file: 'talents-tooltip.svg', title: 'Talents: tooltips', panels: [{ roots: ['PolestarUITalents'], stubs: ['stub_character.lua', 'stub_talents.lua'], script: 'PolestarUI.Show("talents"); local part, locked; for _, c in ipairs({ PolestarUITalents.Body:GetChildren() }) do if c.psInfo and c:IsShown() then local n = c.psInfo; if n.currentRank > 0 and n.currentRank < n.maxRanks then part = c elseif not n.isAvailable then locked = locked or c end end end; local function has(t) for _, l in ipairs(GameTooltip.lines) do if l:find(t, 1, true) then return true end end end; stub.RunScript(part, "OnEnter"); assert(has("Rank 2/") and has("Passive") and has("rank 2]") and has("Next Rank:") and has("rank 3]"), "partial: " .. table.concat(GameTooltip.lines, "/")); stub.RunScript(locked, "OnEnter"); assert(has("Rank 0/") and has("rank 1]") and not has("Next Rank:") and has(" points in "), "locked: " .. table.concat(GameTooltip.lines, "/"))' }] },
	// The professions key opens ours and closes it, never the stock window; hovering a profession's spell puts the secure cast button over it; unlearning asks first.
	{ file: 'professions.svg', title: 'Professions', panels: [{ roots: ['PolestarUIProfessions'], stubs: ['stub_character.lua', 'stub_spellbook.lua', 'stub_professions.lua'], script: 'stub.pressKey("K"); assert(PolestarUIProfessions:IsShown() and not ProfessionsFrame:IsShown(), "key"); stub.pressKey("K"); assert(not PolestarUIProfessions:IsShown(), "no toggle"); PolestarUI.Show("professions"); local byName = {}; for _, c in ipairs({ PolestarUIProfessions.Body:GetChildren() }) do for _, r in ipairs(c.rows or {}) do if r:IsShown() then byName[r.psSpell.info.name] = r end end end; stub.RunScript(byName["Smelting"], "OnEnter"); local o = PolestarUISpellbookCast; assert(o and o:IsShown() and o:GetAttribute("type1") == "spell" and o:GetAttribute("spell") == byName["Smelting"].psSpell.info.spellID, "no cast"); o:Hide(); local tail = byName["Tailoring"]:GetParent(); tail.Unlearn:Click(); assert(not stub.abandoned, "unlearnt without asking"); PolestarModal.Box.Action:Click(); assert(stub.abandoned == 197, "not unlearnt")' }] },
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
