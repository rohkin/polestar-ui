--@ title: Damage meter: the type menu (MenuStyle1), its categories open submenus
--@ roots: DamageMeter, StubMenu
--@ stubs: stub_damagemeter.lua
-- The meter's menus, by their tags (Menu.ModifyMenu): on the pooled menu frame the style's ground is faded and our ground and hairline attached through the menu's own AttachTexture; each item, after the game's initializers built it (AddInitializer on these menus' descriptions only), gets our submenu chevron, radio, tick and divider over the game's faded pieces, and our hover wash in the game's highlight. Everything is attached through the item's compositor and freed when the menu closes: the next menu without our tag is the game's.
stub.damage({ { name = "Garrosh", class = "WARRIOR", amount = 412000 }, { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local TYPE = { { text = "Damage", submenu = true, hover = true }, { text = "Healing", submenu = true }, { text = "Actions", submenu = true } }
local menu, bg, items = stub.openMenu(w.DamageMeterTypeDropdown, "MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE", TYPE)
assert(bg:GetAlpha() == 0, "the menu's own ground shows")
local ours = 0
for _, r in ipairs({ menu:GetRegions() }) do if r ~= bg and r.kind == "Texture" and r:IsShown() then ours = ours + 1 end end
assert(ours == 5, "our ground and four hairlines: " .. ours)
local first = items[1]
assert(first.arrow:GetAlpha() == 0, "the game's submenu arrow shows")
local chevron
for _, r in ipairs({ first:GetRegions() }) do if r:IsShown() and tostring(r:GetTexture()):find("chevron%-right") then chevron = r end end
assert(chevron, "no chevron of ours on a submenu item")
local hr, hg, hb, ha = Polestar.Theme.Wash("hover")
assert(first.highlight.color[1] == hr and first.highlight.color[4] == ha, "the highlight is not our hover wash")
-- Another menu on the same pooled frame: the game's, its items too.
local _, other, oitems = stub.openMenu(w, "MENU_SOMETHING_ELSE", { { text = "Other", radio = true, selected = true } })
assert(other:GetAlpha() == 0.925 and oitems[1].leftTexture1:GetAlpha() == 1 and oitems[1].leftTexture2:GetAlpha() == 1, "another menu inherited our look")
for _, r in ipairs({ menu:GetRegions() }) do assert(r == other or r.kind ~= "Texture" or not r:IsShown(), "ours stayed on the pooled menu") end
stub.openMenu(w.DamageMeterTypeDropdown, "MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE", TYPE)
--@ panel
--@ title: Damage meter: the session menu (MenuStyle2), radios and a divider
--@ roots: DamageMeter, StubMenu
--@ stubs: stub_damagemeter.lua
-- The session menu's style is MenuStyle2 (its own ground, even padding): faded alike, ours to its edges. Its radios: our ring, the accent dot on the selected one; its divider a hairline.
stub.damage({ { name = "Garrosh", class = "WARRIOR", amount = 412000 }, { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local _, bg, items = stub.openMenu(w.SessionDropdown, "MENU_DAMAGE_METER_SESSIONS", {
	{ text = "Hogger [00:42]", radio = true }, { divider = true },
	{ text = "Current Segment", radio = true, selected = true }, { text = "Overall", radio = true },
}, true)
assert(bg:GetAlpha() == 0, "the session menu's own ground shows")
local sel = items[3]
assert(sel.leftTexture1:GetAlpha() == 0 and sel.leftTexture2:GetAlpha() == 0, "the game's radio shows")
local dot
for _, r in ipairs({ sel:GetRegions() }) do if r:IsShown() and tostring(r:GetTexture()):find("circle") then dot = r end end
assert(dot, "no dot of ours on the selected radio")
local divider = items[2]:GetRegions()
assert(divider:GetAlpha() == 0, "the game's divider shows")
--@ panel
--@ title: Damage meter: the settings menu, buttons and ticks
--@ roots: DamageMeter, StubMenu
--@ stubs: stub_damagemeter.lua
-- The settings menu (MenuStyle1): its checkboxes a muted box of ours, the accent tick when checked.
stub.damage({ { name = "Garrosh", class = "WARRIOR", amount = 412000 }, { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local _, _, items = stub.openMenu(w.SettingsDropdown, "MENU_DAMAGE_METER_WINDOW_SETTINGS", {
	{ text = "Open Settings" }, { text = "Lock Window", check = true, selected = true }, { text = "Non-Interactive", check = true },
	{ text = "Reset All Data" },
})
local tick
for _, r in ipairs({ items[2]:GetRegions() }) do if r:IsShown() and tostring(r:GetTexture()):find("check") then tick = r end end
assert(tick and items[2].leftTexture2:GetAlpha() == 0, "the checked box: no tick of ours, or the game's shows")
