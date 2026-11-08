-- The Character window (docs/DESIGN.md, "Character"): the stock CharacterFrame's
-- sections in a Polestar shell. 4a: the shell, its sections and the doors in.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUICharacter"
-- The stock subframes, in stock order; their keys are what ToggleCharacter takes.
-- shortcut: Currency is always listed; hide it via ShouldShowCurrencyTab when its page is built (4e).
local SECTIONS = {
	{ key = "PaperDollFrame", label = CHARACTER or "Character", icon = "icon-level" },
	{ key = "ReputationFrame", label = REPUTATION or "Reputation", icon = "icon-rep" },
	{ key = "TokenFrame", label = CURRENCY or "Currency", icon = "qol-coin" },
	{ key = "PVPRankFrame", label = PVP or "Honor", icon = "flag" },
	{ key = "SkillsFrame", label = SKILLS or "Skills", icon = "icon-skill" },
}
local TABS = { { key = "gear", label = "Gear" }, { key = "stats", label = "Stats" } }

local f, section, tab = nil, "PaperDollFrame", "gear"
local M = {}

local function build()
	f = W.Shell(NAME, {})
	-- The subject block names the window, in place of Polestar's lockup.
	-- Reparented, not hidden: the shell re-shows its version line on every show.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Search, f.Status, f.Stage }) do r:SetParent(holder) end
	f.psName = W.Text(f.Sidebar, "title", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", 24, -47)
	f.psLine = W.Text(f.Sidebar, "small", "textDim")
	f.psLine:SetPoint("TOPLEFT", f.psName, "BOTTOMLEFT", 0, -6)
	Polestar.CloseOnEscape(NAME)
end

local function refresh()
	local level, race = UnitLevel("player"), UnitRace("player")
	f.psName:SetText(UnitName("player"))
	f.psLine:SetText(("Level %d %s"):format(level, UnitClass("player")))
	W.ShellNav(f, SECTIONS, section, function(k) M.Show(k) end)
	if section == "PaperDollFrame" then
		W.ShellTabs(f, TABS, tab, function(k) tab = k; refresh() end)
		W.ShellTitle(f, UnitPVPName("player") or UnitName("player"), ("Level %d %s %s"):format(level, race, UnitClass("player")))
	else
		W.ShellTabs(f, nil)
		for _, s in ipairs(SECTIONS) do
			if s.key == section then W.ShellTitle(f, s.label) end
		end
	end
	W.ShellFooter(f, {}, {})
end

function M.Show(key)
	if not f then build() end
	section = key or section
	refresh()
	f:Show()
end

function M.Toggle(key, onlyShow)
	if f and f:IsShown() and (key == nil or key == section) and not onlyShow then
		f:Hide()
	else
		M.Show(key)
	end
end

function M.Enable()
	-- Every stock door (TOGGLECHARACTER0/2/4, the micro button) calls
	-- ToggleCharacter; it has just shown CharacterFrame, which we close again.
	-- Hide(), not HideUIPanel: that dispatches to a forbidden frame, which does
	-- nothing from addon code; the panel manager repairs a frame hidden this
	-- way before it places the next panel (FramePositionDelegate:ShowUIPanel).
	hooksecurefunc("ToggleCharacter", function(key, onlyShow)
		if CharacterFrame and CharacterFrame:IsShown() then CharacterFrame:Hide() end
		M.Toggle(key, onlyShow)
	end)
end

ns.Module("character", M)
