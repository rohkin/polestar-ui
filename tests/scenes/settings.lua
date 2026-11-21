--@ title: Settings: our page in Polestar's settings, and Settings... in a window's menu
--@ roots: PolestarUISpellbook, PolestarMenu
--@ stubs: stub_spellbook.lua
-- Settings.lua registers one page (key polestarui) whose controls keep their state in PolestarUIDB through get/set.
local ns = PolestarUI
local controls, sections, in_, subtitle = {}, {}, {}, nil
Polestar.Widgets.OnOptionsRegistered(function(spec)
	if spec.key ~= "polestarui" then return end
	assert(spec.page == "Polestar: UI" and spec.group == "setup", "page or group")
	subtitle = subtitle or spec.subtitle
	sections[spec.tab .. "/" .. spec.section] = true
	for _, c in ipairs(spec.controls) do
		assert(c.key == nil and ((c.get and c.set) or c.kind == "button"), "a control with a PolestarDB key: " .. tostring(c.label))
		controls[c.label] = c
		in_[spec.section] = in_[spec.section] or {}
		in_[spec.section][c.label] = c
	end
end)
for _, s in ipairs({ "Windows/Windows", "Windows/Docking", "HUD/HUD", "HUD/Frames look", "HUD/Plates look", "HUD/Icons look", "HUD/Unit frames", "HUD/Chat" }) do
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

-- The HUD's look, per group: Polestar's by default (each value row greyed, showing Polestar's); "Override" seeds the group's own from Polestar's, which then rule it alone; reset follows again.
local H, T, icons, frames = ns.HUD, Polestar.Theme, in_["Icons look"], in_["Frames look"]
local override = icons["Override Polestar's look"]
assert(override.get() == false and icons["Border"].disabled() and icons["Background opacity"].disabled() and icons["Window shadow"].disabled(), "the Icons rows are not greyed while following")
assert(icons["Background opacity"].get() == math.floor(T.GroundAlpha() * 100 + 0.5) and H.GroundAlpha(H.ICONS) == T.GroundAlpha(), "following does not show Polestar's opacity")
for _, k in ipairs({ "Window border", "Border", "Border colour", "Accent border", "Hairlines", "Window shadow", "Shadow strength", "Background opacity" }) do
	assert(icons[k] and frames[k] and in_["Plates look"][k], "no " .. k .. " row in every group")
end
override.set(true)
local o = PolestarUIDB.hudLook.icons
assert(o.override and o.borderSize == 1 and o.border == true and o.shadow == true and o.ground == T.GroundAlpha() and not icons["Border"].disabled(), "the override did not start from Polestar's look")
icons["Border"].set(3)
icons["Background opacity"].set(25)
icons["Border colour"].set("white")
icons["Window shadow"].set(false)
assert(o.borderSize == 3 and o.ground == 0.25 and o.borderColor == "white" and o.shadow == false and icons["Shadow strength"].disabled(), "the Icons rows did not save")
assert(H.GroundAlpha(H.ICONS) == 0.25 and select(6, H.Edge(H.ICONS)) == 3 and H.ShadowColor(H.ICONS) == nil, "the Icons look does not take its own")
assert(H.GroundAlpha(H.FRAMES) == T.GroundAlpha() and select(6, H.Edge(H.FRAMES)) == 1 and frames["Border"].disabled(), "the Frames look changed with the Icons'")
icons["Border colour"].set("scheme")
assert(o.borderColor == false and icons["Border colour"].get() == "scheme", "the scheme's colour not picked again")
icons["Border"].set(nil)
assert(o.borderSize == 1, "a row's reset is not Polestar's value")
override.set(nil)
assert(not PolestarUIDB.hudLook.icons.override and H.GroundAlpha(H.ICONS) == T.GroundAlpha() and icons["Border"].disabled(), "reset does not follow Polestar again")
override.set(true)
assert(PolestarUIDB.hudLook.icons.ground == 0.25, "the override's own values were lost while following")
override.set(nil)
-- The Frames look's rows as Polestar's page makes them (W.SetDisabledWhen, then psControl): turning the
-- override on enables every row at once (the page re-checks `disabled` on a setting change only), and each
-- row writes the frames group's own value, which the painted edge follows.
local W, rowOf = Polestar.Widgets, {}
local host = CreateFrame("Frame", nil, UIParent)
for label, c in pairs(frames) do
	local w = W.Toggle(host, label, nil, nil, nil, { get = function() return c.get() end, set = c.set })
	W.SetDisabledWhen(w, c.disabled)
	w.psControl = c
	rowOf[label] = w
end
assert(not rowOf["Accent border"]:IsEnabled(), "the Accent border row is not greyed while following")
frames["Override Polestar's look"].set(true)
for label, w in pairs(rowOf) do assert(w:IsEnabled() and not (frames[label].disabled and frames[label].disabled()), label .. " stays greyed with the override on") end
local fo = PolestarUIDB.hudLook.frames
local function edge() local _, r, g, b, a = H.Edge(H.FRAMES); return r, g, b, a end
frames["Border colour"].set("white")
assert(edge() == 1 and select(2, edge()) == 1, "the edge does not take its own colour")
frames["Accent border"].set(true)
local ar, ag, ab = T.Accent()
local er, eg, eb, ea = edge()
assert(fo.borderAccent == true and fo.borderColor == false and frames["Border colour"].get() == "scheme" and er == ar and eg == ag and eb == ab and ea == 0.8, "Accent border did not take the edge over its own colour")
frames["Border colour"].set("gold")
assert(fo.borderAccent == false and not frames["Accent border"].get() and select(2, edge()) == 0.82, "a colour did not turn Accent border off")
frames["Accent border"].set(false)
assert(fo.borderAccent == false, "Accent border off not saved")
frames["Window border"].set(false)
assert(not rowOf["Accent border"]:IsEnabled() and not rowOf["Border"]:IsEnabled() and rowOf["Hairlines"]:IsEnabled(), "the border rows are not greyed with the border off")
assert(not H.Edge(H.FRAMES), "the edge still shows with the border off")
frames["Window border"].set(true)
-- Each slider writes its own key (they once all wrote the last row's, ground).
local ground = fo.ground
frames["Hairlines"].set(50)
assert(fo.hairline == 0.5 and fo.ground == ground and select(5, H.Edge(H.FRAMES)) == 0.5, "Hairlines not painted, or written to another key")
local _, _, _, sa = H.ShadowColor(H.FRAMES)
frames["Shadow strength"].set(50)
assert(fo.shadowStrength == 0.5 and fo.ground == ground and select(4, H.ShadowColor(H.FRAMES)) < sa, "Shadow strength not painted, or written to another key")
frames["Background opacity"].set(40)
assert(fo.ground == 0.4 and fo.hairline == 0.5 and fo.shadowStrength == 0.5 and H.GroundAlpha(H.FRAMES) == 0.4, "the ground not saved")
assert(not PolestarUIDB.hudLook.plates or not PolestarUIDB.hudLook.plates.override, "the Plates look took the Frames override")
frames["Override Polestar's look"].set(nil)
assert(not rowOf["Accent border"]:IsEnabled(), "the rows are not greyed again when following")
host:Hide()
-- Unit frames' options, in PolestarUIDB.unitframes.
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
-- Bare /pui opens the page, with Polestar hidden too (the window is on its layer); its subtitle carries the version.
opened = nil
-- A stand-in hidden state (the real one would redraw Polestar's frames in this scene).
local hidden, realHidden, realSet = true, Polestar.Hidden, Polestar.SetHidden
Polestar.Hidden, Polestar.SetHidden = function() return hidden end, function(on) hidden = on end
SlashCmdList.POLESTARUI("")
Polestar.Hidden, Polestar.SetHidden = realHidden, realSet
assert(opened and opened[1] == "polestarui", "bare /pui did not open the settings")
assert(not hidden, "settings opened under Polestar's hidden layer")
assert((subtitle or ""):find("^Version %S"), "no version subtitle: " .. tostring(subtitle))
PolestarUISpellbook.psMenu:Click()
