-- The Group Finder (docs/windows/groupfinder.md): Forever's Vanilla-style
-- premade finder (LFGParentFrame, the load-on-demand
-- Blizzard_GroupFinder_VanillaStyle) in a Polestar shell: Listing, Browse
-- and Who on a slim rail. This file is the shell, the doors and the page
-- registry; each page lives in its own file (GroupFinderListing.lua,
-- GroupFinderBrowse.lua, GroupFinderWho.lua) and fills ns.GroupFinder.pages.
-- Ours never loads, shows or hides the stock window: its OnShow and OnHide
-- run UpdateMicroButtons (docs/CLIENT.md, rule 8).

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIGroupFinder"
local COMBAT = "You can't do that while in combat."

-- The page registry. A page file sets G.pages[key] = {
--   build(f): makes its frames on f.Body (once);
--   paint(f): shows them and returns fact, right, left, height:
--     fact, the band's subtitle after the subject ("18 groups");
--     right/left, footer specs { label, onClick, opts, on, why, tip, game };
--       game = true: the click opens the game's Group Finder instead (a secure
--       button of ours over it), for what addon code may not do
--       (C_LFGList.RemoveListing is protected: Unlist is the game's);
--     height, the body's scroll height (default: the view);
--   leave(f): the page is left or the window closes (optional);
--   menu(f): its items for the window's "..." menu (optional);
--   apply(on): the window is switched on (at login too) or off (optional) }.
-- G.Paint() redraws the window when it shows (after every change of ours:
-- docs/CLIENT.md, rule 6). G.frame is the window once built.
local G = { pages = {} }
ns.GroupFinder = G

-- The stock side tabs (LFGParentFrameMixin:UpdateTabs, the modern style:
-- ListingTab, BrowsingTab, WhoListingTab) with their icons, on a slim rail.
local PAGES = {
	{ key = "listing", icon = "Interface/ICONS/INV_SideTab_GroupFinder_c60" },
	{ key = "browse", icon = "Interface/ICONS/INV_SideTab_GroupBrowsing_c60" },
	{ key = "who", icon = "Interface/ICONS/INV_SideTab_WhoList_c60" },
}
local BY_KEY = {}
for _, p in ipairs(PAGES) do BY_KEY[p.key] = p end

local function listed() return C_LFGList and C_LFGList.HasActiveEntryInfo and C_LFGList.HasActiveEntryInfo() or false end

local function label(key)
	if key == "listing" then
		return listed() and (LFG_LIST_EDIT or "Edit Listing") or (LFG_LIST_TAB_1 or "Create a Listing")
	end
	if key == "browse" then return LFG_LIST_TAB_2 or "Browse Groups" end
	return LFG_LIST_TAB_3 or "Who"
end

local f, page
local M = {}

local function redraw() if f and f:IsShown() then G.Paint() end end

-- The subject leads the subtitle: "Level 42 Mage".
local function subject()
	local class, token = UnitClass("player")
	local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
	local name = c and c.colorStr and ("|c%s%s|r"):format(c.colorStr, class) or class or ""
	return ("Level %d %s"):format(UnitLevel("player") or 0, name)
end

-- A footer button marked `game` opens the game's Group Finder: a secure button
-- of ours on UIParent over it while hovered (ns.Overlay: placed out of combat,
-- hidden as combat starts), whose PreClick closes ours and whose macro clicks
-- the micro button from secure code, as its shift-click does (ns.Doors).
local placeDoor = ns.Overlay("PolestarUIGroupFinderGame", {
	enter = function(t) local s = t:GetScript("OnEnter"); if s then s(t) end end,
	pickup = function() end,
	attrs = function(over)
		over:SetAttribute("type1", "macro")
		over:SetAttribute("macrotext", "/click [nocombat] LFDMicroButton")
	end,
	stale = function(t) return not t.psGame or not t:IsEnabled() end,
	setup = function(over) over:HookScript("PreClick", function() if f then f:Hide() end end) end,
})

local function paintFooter(right, left)
	ns.Footer(f, left, right)
	for side, specs in pairs({ left = left, right = right }) do
		for i, d in ipairs(specs) do
			local b = f.footerButtons[side][i]
			local on, why = d.on ~= false, d.why
			if d.game and InCombatLockdown() then on, why = false, COMBAT end
			ns.SetEnabled(b, on, why)
			b.psTip = on and d.tip or nil
			b.psGame = d.game and LFDMicroButton and true or nil
			if not b.psDoorHook then
				b.psDoorHook = true
				b:HookScript("OnEnter", function(self) if self.psGame and self:IsEnabled() then placeDoor(self) end end)
			end
		end
	end
end

local function options(button)
	local items = {}
	local p = G.pages[page]
	if p and p.menu then for _, it in ipairs(p.menu(f)) do items[#items + 1] = it end end
	items[#items + 1] = { text = "The game's window: shift-click the Group Finder button.", disabled = true }
	return items
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 620, height = 560, sidebar = 0, rail = true })
	ns.Dock(f)
	ns.WindowMenu(f, "groupfinder", options)
	ns.Plain(f, f.psRail)
	ns.Compact(f)
	G.frame = f
	for _, p in pairs(G.pages) do if p.build then p.build(f) end end
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	f:HookScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
		local p = G.pages[page]
		if p and p.leave then p.leave(f) end
	end)
	Polestar.CloseOnEscape(NAME)
end

function G.Paint()
	local items = {}
	for i, p in ipairs(PAGES) do items[i] = { key = p.key, label = label(p.key), icon = p.icon } end
	ns.GameRail(f, items, page, function(key) M.Show(key) end, { slim = true })
	for i, it in ipairs(items) do f.railButtons[i].psTip = it.label end
	local p = G.pages[page]
	local fact, right, left, height = p.paint(f)
	W.ShellTabs(f, nil)
	W.ShellTitle(f, LFG_TITLE or "Group Finder", fact and (subject() .. " · " .. fact) or subject())
	paintFooter(right or {}, left or {})
	W.ShellBody(f, height or f.psViewH)
end

-- The page shown: the one asked for, else the last one (kept in PolestarUIDB).
function M.Show(key)
	if not f then build() end
	key = key or page or (PolestarUIDB and PolestarUIDB.groupFinderPage) or "listing"
	if not BY_KEY[key] then key = "listing" end
	local was = G.pages[page]
	if key ~= page and was and was.leave and f:IsShown() then was.leave(f) end
	page = key
	if PolestarUIDB then PolestarUIDB.groupFinderPage = page end
	G.Paint()
	f:Show()
end

-- As LFGVanilla_ToggleFrame(tab): open on that page, close if already on it.
function M.Toggle(key)
	if f and f:IsShown() and (key == nil or key == page) then f:Hide() else M.Show(key) end
end

function M.Enable()
	-- The Group Finder key (Listing), the Who key (unbound on Forever, taken
	-- when bound) and the micro button open ours; the stock window is never
	-- touched (docs/CLIENT.md, rule 8). The game's other doors (the queue
	-- eye, LFG_LIST_SHOW_SEARCH, /who, FriendsFrame's Who) stay the game's.
	ns.Doors("groupfinder", "GroupFinder", {
		TOGGLEGROUPFINDER = function() M.Toggle("listing") end,
		TOGGLEWHOTAB = function() M.Toggle("who") end,
	}, LFDMicroButton, function() M.Toggle() end)
	for _, e in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "LFG_LIST_ACTIVE_ENTRY_UPDATE" }) do
		Polestar.RegisterEvent(e, redraw)
	end
	M.Apply()
end

-- The switch, live (ns.Switch): each page follows it.
function M.Apply()
	local on = ns.Enabled("groupfinder")
	for _, p in pairs(G.pages) do if p.apply then p.apply(on) end end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return LFGParentFrame and LFGParentFrame:IsShown() and LFGParentFrame end

ns.Module("groupfinder", M)
