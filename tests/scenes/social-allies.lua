--@ title: Social: Recent allies
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- Recent allies (C_RecentAllies) in the client's order: the page never asks the client for them
-- (restricted), says how to load them until they come (RECENT_ALLIES_DATA_READY), then lists each with
-- level, class, where they are and how you met. Click whispers, double-click invites,
-- right-click opens the game's recent ally menu. As the stock tab: Pinned and Recent allies
-- groups, the pin mark (a click pins or unpins), the card's tooltip with the note, and the
-- Status and Categories filter through C_RecentAllies.SearchRecentAllies.
stub.alliesReady = false
PolestarUI.Show("social", "allies")
local f = PolestarUISocial
assert(not stub.forbidden, "called restricted " .. tostring(stub.forbidden))
assert(f.psEmpty:IsShown() and f.psEmpty:GetText() == "Recent allies load in the game's Social window: type /friends and open its Recent Allies tab.", "not ready: " .. tostring(f.psEmpty:GetText()))
stub.alliesReady = true
stub.fire("RECENT_ALLIES_DATA_READY")
local function plain(t) return (t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(f.Title:GetText() == "Recent allies" and not f.psEmpty:IsShown() and row("Vessa") and row("Orrin"), "rows after data ready")
assert(plain(row("Vessa").Sub:GetText()) == "Lvl 23 Rogue" and row("Vessa").Where:GetText() == "The Deadmines", "online: " .. tostring(row("Vessa").Where:GetText()))
assert(row("Orrin").Sub:GetText() == "Lvl 21 Mage" and row("Orrin").Where:GetText() == "Grouped in Westfall", "offline: " .. tostring(row("Orrin").Where:GetText()))
stub.RunScript(row("Vessa"), "OnClick", "LeftButton")
stub.RunScript(row("Vessa"), "OnDoubleClick", "LeftButton")
stub.advance(0.5)
assert(stub.invited == "Vessa-Realm" and stub.told == nil, "double-click")
stub.RunScript(row("Orrin"), "OnClick", "RightButton")
assert(stub.popup[1] == "RECENT_ALLY_OFFLINE" and stub.popup[2] == "Orrin-Realm", "menu")
-- The stock tab's groups: Pinned, then the rest, online/total; Vessa wears the pin mark.
assert(row("Pinned 1/1") and row("Recent allies 0/1"), "groups")
assert(row("Vessa").Pin:IsShown() and row("Vessa").Pin.Icon.atlas == "friendslist-recentallies-pin-yellow" and not row("Vessa").Pin.Icon.desaturated, "pin mark")
assert(row("Orrin").Pin.Icon.desaturated and row("Orrin").Pin:GetAlpha() < 1, "unpinned mark")
assert(row("Vessa").Invite:IsShown() and row("Vessa").Pip:IsShown(), "invite and presence")
-- The tooltip: the stock card's lines, the note among them.
stub.RunScript(row("Vessa"), "OnEnter")
local tip = table.concat(GameTooltip.lines or {}, "|")
assert(tip:find("Vessa-Realm", 1, true) and tip:find("Level 23 Rogue", 1, true) and tip:find("Note: Great tank", 1, true) and tip:find("Recent activity", 1, true), "tooltip: " .. tip)
stub.RunScript(row("Vessa"), "OnLeave")
-- A click on the pin pins or unpins at once; a pin near its end turns red.
row("Orrin").Pin:Click()
assert(stub.pinned[1] == "Player-MAGE-21" and stub.pinned[2] == true and row("Pinned 1/2"), "pin")
assert(row("Orrin").Pin.Icon.atlas == "friendslist-recentallies-pin", "pin ending")
-- The filter: Status and Categories (no Delves here), through the client's search.
assert(f.psFilter:IsShown(), "no filter on recent allies")
local items
local show = Polestar.Widgets.ShowMenu
Polestar.Widgets.ShowMenu = function(a, its, o) items = its; return show(a, its, o) end
f.psFilter:Click()
local t = {}
for _, it in ipairs(items) do if it.text then t[#t + 1] = it.text end end
assert(table.concat(t, ",") == "Status,Online,Away,Busy,Offline,Categories,Professions,PvP,Raiding,Dungeons,Questing", "menu: " .. table.concat(t, ","))
local function pick(text) for _, it in ipairs(items) do if it.text == text then return it.onClick() end end end
pick("PvP")
assert(#stub.allySearch.interactionCategoryFilters == 1 and stub.allySearch.interactionCategoryFilters[1] == Enum.RecentAlliesInteractionCategoryFilter.PvP, "category search")
assert(f.psEmpty:IsShown() and f.psEmpty:GetText() == "No one matches.", "filtered out")
pick("Online")
pick("PvP")
assert(stub.allySearch.isOnline and row("Vessa") and not row("Orrin"), "online filter")
pick("Clear filters")
Polestar.Widgets.HideMenu()
assert(row("Vessa") and row("Orrin") and not f.psFilter.psActive, "cleared")
Polestar.Widgets.ShowMenu = show
assert(f.Subtitle:GetText() == "1 of 2 online", "status: " .. tostring(f.Subtitle:GetText()))
