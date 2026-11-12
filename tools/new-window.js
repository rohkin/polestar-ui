#!/usr/bin/env node
// Scaffolds a new window: node tools/new-window.js <key> <StockFrameName>
// Writes Modules/<Name>.lua, tests/lua/stub_<key>.lua, tests/scenes/<key>.lua,
// the .toc line and, when missing, docs/windows/<key>.md. Never overwrites.
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const [key, stock] = process.argv.slice(2);
if (!/^[a-z][a-z0-9]*$/.test(key || '') || !/^[A-Za-z_]\w*$/.test(stock || '')) {
	console.error('usage: node tools/new-window.js <key> <StockFrameName>   (key: lowercase letters and digits)');
	process.exit(1);
}
const Name = key[0].toUpperCase() + key.slice(1);
const NAME = 'PolestarUI' + Name;
const ACTION = 'TOGGLE' + key.toUpperCase();
const MICRO = Name + 'MicroButton';

const files = {
	[`Modules/${Name}.lua`]: `-- The ${Name} (docs/windows/${key}.md): the stock ${stock} in a Polestar shell.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "${NAME}"

local f
local M = {}

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale" })
	ns.Dock(f)
	ns.WindowMenu(f, "${key}")
	Polestar.CloseOnEscape(NAME)
end

local function refresh()
	W.ShellNav(f, { { key = "main", label = "${Name}", icon = "bolt" } }, "main", function() M.Show() end)
	W.ShellTitle(f, "${Name}", "")
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, {})
	W.ShellBody(f, 0)
end

function M.Show()
	if not f then build() end
	refresh()
	f:Show()
end

function M.Toggle()
	if f and f:IsShown() then f:Hide() else M.Show() end
end

function M.Enable()
	-- The key and micro button open ours; the stock window is never touched
	-- (docs/CLIENT.md, rule 8).
	ns.Doors("${key}", "${Name}", { ${ACTION} = M.Toggle }, ${MICRO}, M.Toggle)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return ${stock} and ${stock}:IsShown() and ${stock} end

ns.Module("${key}", M)
`,
	[`tests/lua/stub_${key}.lua`]: `-- The client's ${stock} as the ${Name} sees it; fill in the real shape of its
-- XML (region names, children, the stock functions our hooks follow).

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
${stock} = CreateFrame("Frame", "${stock}", UIParent)
${stock}:Hide()
${MICRO} = CreateFrame("Button", "${MICRO}", UIParent)
${MICRO}.tooltipText = "${Name}"
stub.bindings.${ACTION} = { "F9" }
function stub.bindingRun.${ACTION}() ${stock}:Show() end
`,
	[`tests/scenes/${key}.lua`]: `--@ title: ${Name}
--@ roots: ${NAME}
--@ stubs: stub_${key}.lua
-- The key opens ours and closes it again, never the stock window (docs/CLIENT.md, rule 8).
stub.pressKey("F9")
assert(${NAME}:IsShown(), "ours closed")
assert(not ${stock}:IsShown(), "stock window open")
stub.pressKey("F9")
assert(not ${NAME}:IsShown(), "no toggle")
PolestarUI.Show("${key}")
assert(${NAME}:IsShown() and not ${stock}:IsShown(), "show")
`,
};

const exists = Object.keys(files).filter((p) => fs.existsSync(path.join(ROOT, p)));
if (exists.length) {
	console.error('refusing to overwrite: ' + exists.join(', '));
	process.exit(1);
}
const doc = `docs/windows/${key}.md`;
if (!fs.existsSync(path.join(ROOT, doc))) files[doc] = `#### ${Name} (\`${stock}\`) — Risk: ?\nTODO: the catalogue entry, written before building (add its row to docs/DESIGN.md).\n`;
for (const [p, text] of Object.entries(files)) fs.writeFileSync(path.join(ROOT, p), text);

// The module line goes before Tooltips (the HUD restyles load last), else at the end.
const toc = path.join(ROOT, 'Polestar_UI.toc');
const eol = fs.readFileSync(toc, 'utf8').includes('\r\n') ? '\r\n' : '\n';
const lines = fs.readFileSync(toc, 'utf8').split(/\r?\n/);
const entry = "Modules\\" + Name + ".lua";
if (!lines.includes(entry)) {
	let at = lines.findIndex((l) => /^Modules[\\/]Tooltips\./.test(l));
	if (at < 0) { at = lines.length; while (at > 0 && lines[at - 1] === '') at--; }
	lines.splice(at, 0, entry);
	fs.writeFileSync(toc, lines.join(eol));
}
console.log('wrote ' + Object.keys(files).join(', ') + ' and the .toc line');
