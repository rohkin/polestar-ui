'use strict';
// The addon folder was Polestar_UI; an old copy left installed beside PolestarUI starts none of
// our modules, is disabled and gets one chat line asking to delete it.

const test = require('node:test');
const { dumpPanel, metricsLua, loadFonts } = require('../tools/preview');

const run = (old) => dumpPanel({
	roots: [], stubs: [],
	saved: `${old ? 'table.insert(stub.addons, { name = "Polestar_UI", loaded = true })' : ''}
C_AddOns.DisableAddOn = function(n) stub.disabledAddOn = n end
stub.printed = {}
local print0 = print
print = function(m, ...) table.insert(stub.printed, tostring(m)); return print0(m, ...) end`,
	script: `local started = 0
for _, key in ipairs(PolestarUI.order) do if PolestarUI.modules[key].psStarted then started = started + 1 end end
local said = 0
for _, m in ipairs(stub.printed) do if m:find("old Polestar_UI folder", 1, true) then said = said + 1 end end
if ${old} then
	assert(started == 0, started .. " modules started beside the old folder")
	assert(said == 1, "the delete line printed " .. said .. " times")
	assert(stub.disabledAddOn == "Polestar_UI", "the old addon was not disabled")
	PolestarUI.Show("spellbook")
	assert(not (PolestarUISpellbook and PolestarUISpellbook:IsShown()), "a window opened beside the old folder")
else
	assert(started > 0 and said == 0 and stub.disabledAddOn == nil, "the guard fired without the old folder")
end`,
}, metricsLua(loadFonts()));

test('an old Polestar_UI folder: no module starts, it is disabled, one line says so', () => { run(true); });
test('without it, modules start as before', () => { run(false); });
