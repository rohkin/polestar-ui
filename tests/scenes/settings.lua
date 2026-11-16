--@ title: Settings: our page in Polestar's settings, and Settings... in a window's menu
--@ roots: PolestarUISpellbook, PolestarMenu
--@ stubs: stub_spellbook.lua
-- Settings.lua registers one page (key polestarui) whose controls keep their state in PolestarUIDB through get/set.
local ns = PolestarUI
local controls, sections = {}, {}
Polestar.Widgets.OnOptionsRegistered(function(spec)
	if spec.key ~= "polestarui" then return end
	assert(spec.page == "Polestar: UI" and spec.group == "setup", "page or group")
	sections[spec.tab .. "/" .. spec.section] = true
	for _, c in ipairs(spec.controls) do
		assert(c.key == nil and c.get and c.set, "a control with a PolestarDB key: " .. tostring(c.label))
		controls[c.label] = c
	end
end)
for _, s in ipairs({ "Windows/Windows", "Windows/Docking", "HUD/HUD", "HUD/Unit frames", "HUD/Chat" }) do
	assert(sections[s], "no section " .. s)
end

-- A window toggle: off and on as /pui does, saved in PolestarUIDB.modules.
local sb = controls["Spellbook"]
assert(sb.get() == true, "spellbook not on")
sb.set(false)
assert(PolestarUIDB.modules.spellbook == false and sb.get() == false, "off not saved")
sb.set(true)
assert(PolestarUIDB.modules.spellbook == true, "on not saved")
-- Refused in combat, as /pui is.
stub.inCombat = true
sb.set(false)
stub.inCombat = false
assert(PolestarUIDB.modules.spellbook == true, "switched in combat")
-- Reset: no saved choice again.
sb.set(nil)
assert(PolestarUIDB.modules.spellbook == nil and sb.get() == true, "reset kept a choice")

-- An NPC window waits for /reload to switch off, and says so.
assert(controls["Gossip"].help:find("after /reload"), "no reload note: " .. controls["Gossip"].help)
assert(not sb.help:find("after /reload"), "reload note on a live window")
-- A HUD module sits on the HUD tab.
assert(controls["Unit frames"] and controls["Chat"], "no HUD toggles")

-- Docking.
local dock = controls["Dock windows"]
dock.set(false)
assert(PolestarUIDB.free == true and not ns.Docked(), "undock not saved")
dock.set(nil)
assert(PolestarUIDB.free == nil and dock.get() == true, "dock reset")

-- Unit frames' options, in PolestarUIDB.unitframes.
local ground = controls["Background opacity"]
assert(ground.get() == 60, "ground default " .. tostring(ground.get()))
ground.set(25)
assert(PolestarUIDB.unitframes.ground == 0.25, "ground not saved")
ground.set(nil)
assert(ground.get() == 60, "ground reset")
local portrait = controls["3D portraits"]
portrait.set(false)
assert(PolestarUIDB.unitframes.portrait == false and portrait.get() == false, "portrait not saved")
portrait.set(nil)
assert(portrait.get() == true, "portrait reset")
-- Applied live through the module, and round-trips with it.
local uf = ns.modules.unitframes
portrait.set(false)
assert(uf.Option("portrait") == false, "module did not see the page's change")
uf.SetOption("portrait", true)
assert(portrait.get() == true, "page did not see the module's change")

-- Chat history, per character.
local keep = controls["Keep chat across sessions"]
assert(keep.get() == true, "history off by default")
keep.set(false)
assert(PolestarUICharDB.chatNoHistory == true, "history off not saved")
keep.set(nil)
assert(PolestarUICharDB.chatNoHistory == nil and keep.get(), "history reset")

-- Settings... in the window's menu (Polestar's UI is absent in the preview: a stand-in) opens our page on the window's tab.
local opened
Polestar.UI = { ShowOptions = function(k) opened = { k } end, Options = { Select = function(k, tab) opened[2], opened[3] = k, tab end } }
ns.Show("spellbook")
PolestarUISpellbook.psMenu:Click()
local row
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.psItem and r.psItem.icon == "gear" then row = r end end
assert(row, "no Settings... row")
row.psItem.onClick()
assert(opened and opened[1] == "polestarui" and opened[3] == "Windows", "page not opened on its tab")
PolestarUISpellbook.psMenu:Click()
