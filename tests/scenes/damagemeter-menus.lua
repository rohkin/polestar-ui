--@ title: Damage meter: the type menu (MenuStyle1), its categories open submenus
--@ roots: DamageMeter, StubMenu
--@ stubs: stub_damagemeter.lua
-- The meter's menus, by their tags (Menu.ModifyMenu): on the pooled menu frame the style's ground is faded and our ground and hairline attached through the menu's own AttachTexture; each item, after the game's initializers built it (AddInitializer on these menus' descriptions only), gets our submenu chevron, radio, tick and divider over the game's faded pieces, and our hover wash in the game's highlight. Everything is attached through the item's compositor and freed when the menu closes: the next menu without our tag is the game's.
-- Our textures on the menu's frames (ns.MenuLook: a frame of ours on the menu), shown; "white": ground and hairlines.
local function ours(m, find) local n, hit = 0 for _, c in ipairs({ m:GetChildren() }) do if c:IsShown() then for _, r in ipairs({ c:GetRegions() }) do local tex = tostring(r.GetTexture and r:GetTexture()) if r:IsShown() and tex:find("Polestar") then if not find or tex:find(find) then n, hit = n + 1, hit or r end end end end end return n, hit end
stub.damage({ { name = "Garrosh", class = "WARRIOR", amount = 412000 }, { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local TYPE = { { text = "Damage", submenu = true, hover = true }, { text = "Healing", submenu = true }, { text = "Actions", submenu = true } }
local menu, bg, items = stub.openMenu(w.DamageMeterTypeDropdown, "MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE", TYPE)
assert(bg:GetAlpha() == 0, "the menu's own ground shows")
assert(ours(menu, "white") == 5, "our ground and four hairlines: " .. ours(menu, "white"))
local first = items[1]
assert(first.arrow:GetAlpha() == 0, "the game's submenu arrow shows")
local _, chevron = ours(menu, "chevron%-right")
assert(chevron and select(2, chevron:GetPoint(1)) == first.arrow, "no chevron of ours on a submenu item")
local hr, hg, hb, ha = Polestar.Theme.Wash("hover")
assert(first.highlight.color[1] == hr and first.highlight.color[4] == ha, "the highlight is not our hover wash")
-- Another menu on the same pooled frame: the game's, its items too.
local _, other, oitems = stub.openMenu(w, "MENU_SOMETHING_ELSE", { { text = "Other", radio = true, selected = true } })
assert(other:GetAlpha() == 0.925 and oitems[1].leftTexture1:GetAlpha() == 1 and oitems[1].leftTexture2:GetAlpha() == 1, "another menu inherited our look")
assert(ours(menu) == 0, "ours stayed on the pooled menu")
-- The type menu again, then the session menu (opening one closes the other): our code attaches nothing through the game's compositor (the stub reports it: it taints the menu code walking it, s526).
stub.openMenu(w.DamageMeterTypeDropdown, "MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE", TYPE)
assert(ours(menu, "chevron%-right") == 3, "the type menu again: not restyled")
stub.openMenu(w.SessionDropdown, "MENU_DAMAGE_METER_SESSIONS", { { text = "Overall", radio = true } }, true)
assert(ours(menu, "chevron%-right") == 0 and ours(menu, "white") == 5, "the type menu's pieces stayed on the session menu")
stub.openMenu(w.DamageMeterTypeDropdown, "MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE", TYPE)
--@ panel
--@ title: Damage meter: the session menu (MenuStyle2), radios and a divider
--@ roots: DamageMeter, StubMenu
--@ stubs: stub_damagemeter.lua
-- The session menu's style is MenuStyle2 (its own ground, even padding): faded alike, ours to its edges. Its radios: our ring, the accent dot on the selected one; its divider a hairline.
-- Our textures on the menu's frames (ns.MenuLook: a frame of ours on the menu), shown; "white": ground and hairlines.
local function ours(m, find) local n, hit = 0 for _, c in ipairs({ m:GetChildren() }) do if c:IsShown() then for _, r in ipairs({ c:GetRegions() }) do local tex = tostring(r.GetTexture and r:GetTexture()) if r:IsShown() and tex:find("Polestar") then if not find or tex:find(find) then n, hit = n + 1, hit or r end end end end end return n, hit end
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
local _, dot = ours(StubMenu, "circle")
assert(dot, "no dot of ours on the selected radio")
local divider = items[2]:GetRegions()
assert(divider:GetAlpha() == 0, "the game's divider shows")
--@ panel
--@ title: Damage meter: the settings menu, buttons and ticks
--@ roots: DamageMeter, StubMenu
--@ stubs: stub_damagemeter.lua
-- The settings menu (MenuStyle1): its checkboxes a muted box of ours, the accent tick when checked.
-- Our textures on the menu's frames (ns.MenuLook: a frame of ours on the menu), shown; "white": ground and hairlines.
local function ours(m, find) local n, hit = 0 for _, c in ipairs({ m:GetChildren() }) do if c:IsShown() then for _, r in ipairs({ c:GetRegions() }) do local tex = tostring(r.GetTexture and r:GetTexture()) if r:IsShown() and tex:find("Polestar") then if not find or tex:find(find) then n, hit = n + 1, hit or r end end end end end return n, hit end
stub.damage({ { name = "Garrosh", class = "WARRIOR", amount = 412000 }, { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local _, _, items = stub.openMenu(w.SettingsDropdown, "MENU_DAMAGE_METER_WINDOW_SETTINGS", {
	{ text = "Open Settings" }, { text = "Lock Window", check = true, selected = true }, { text = "Non-Interactive", check = true },
	{ text = "Reset All Data" },
})
local _, tick = ours(StubMenu, "check")
assert(tick and items[2].leftTexture2:GetAlpha() == 0, "the checked box: no tick of ours, or the game's shows")
