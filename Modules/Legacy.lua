-- Legacy (docs/DESIGN.md, "Legacy"): Forever's Legacy System window
-- (LegacySystemFrame, Blizzard_LegacySystem) in a Polestar shell: the reward
-- track, the challenges and the legacy tree as sections.

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local NAME = "PolestarUILegacy"
local FACTION = Constants and Constants.LegacyConsts and Constants.LegacyConsts.LEGACY_REWARD_TRACK_FACTION_ID or 2802
local ROW_H, ICON, BAR_H = 56, 36, 64
local SECTIONS = {
	{ key = "track", label = "Reward Track", icon = "icon-treasure" },
	{ key = "challenges", label = "Challenges", icon = "icon-achieve" },
	{ key = "tree", label = "Legacy Tree", icon = "icon-skill" },
}
local f, section = nil, "track"
local M = {}

local function level() return C_MajorFactions.GetCurrentRenownLevel(FACTION) or 0 end

local refresh -- below

-- The stock card's tooltip (RenownLevelMixin:RefreshTooltip): one reward
-- names itself; a level of several lists them.
local function rowTip(r)
	local d = r.psLevel
	if not d then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	local again = function() if GameTooltip:GetOwner() == r then rowTip(r) end end
	if d.isCapstone and RENOWN_REWARD_CAPSTONE_TOOLTIP_TITLE then
		GameTooltip:SetText(RENOWN_REWARD_CAPSTONE_TOOLTIP_TITLE, 1, 1, 1)
		GameTooltip:AddLine(RENOWN_REWARD_CAPSTONE_TOOLTIP_DESC, nil, nil, nil, true)
	elseif #d.rewards == 1 then
		local _, name, desc = RenownRewardUtil.GetRenownRewardInfo(d.rewards[1], again)
		GameTooltip:SetText(name or "", 1, 1, 1)
		if desc then GameTooltip:AddLine(desc, nil, nil, nil, true) end
	else
		GameTooltip:SetText(("Level %d rewards"):format(d.level), 1, 1, 1)
		for _, reward in ipairs(d.rewards) do
			local _, name = RenownRewardUtil.GetRenownRewardInfo(reward, again)
			if name then GameTooltip:AddLine("- " .. name) end
		end
	end
	GameTooltip:Show()
end

local function newRow(parent, i)
	local r = CreateFrame("Button", nil, parent)
	r:SetHeight(ROW_H)
	r:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * ROW_H)
	r:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
	if i > 1 then
		local d = W.Divider(r)
		d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
		d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
	end
	W.Hover(r)
	r:SetScript("OnEnter", rowTip)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	-- The level the player stands at, marked as a selected row is.
	r.Mark = W.Fill(r, "accent", "ARTWORK", 0)
	r.Mark:ClearAllPoints()
	r.Mark:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
	r.Mark:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
	r.Mark:SetWidth(2)
	r.Level = W.Text(r, "number", "textDim")
	r.Level:SetPoint("CENTER", r, "LEFT", 32, 0)
	local well = CreateFrame("Frame", nil, r)
	well:SetSize(ICON, ICON)
	well:SetPoint("LEFT", r, "LEFT", 64, 0)
	Theme.Skin(well, "inset")
	Theme.Border(well, Theme.Wash("border"))
	r.Icon = ns.GameIcon(well)
	r.Icon:SetPoint("TOPLEFT", 1, -1)
	r.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	r.State = W.Tex(r, "ARTWORK", "check", "accent")
	r.State:SetSize(14, 14)
	r.State:SetPoint("RIGHT", r, "RIGHT", -16, 0)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("BOTTOMLEFT", well, "RIGHT", 12, 2)
	r.Name:SetPoint("RIGHT", r.State, "LEFT", -16, 0)
	r.Name:SetJustifyH("LEFT")
	r.Desc = W.Text(r, "small", "textDim")
	r.Desc:SetPoint("TOPLEFT", well, "RIGHT", 12, -3)
	r.Desc:SetPoint("RIGHT", r.State, "LEFT", -16, 0)
	r.Desc:SetJustifyH("LEFT")
	r.Desc:SetWordWrap(false)
	return r
end

local function paintRow(r, d, current)
	r.psLevel = d
	local earned = d.level <= current
	local again = function() if f:IsShown() then refresh() end end
	local icon, name, desc = RenownRewardUtil.GetRenownRewardInfo(d.rewards[1], again)
	if #d.rewards > 1 then name, desc = ("%s and %d more"):format(name or "", #d.rewards - 1), desc end
	r.Level:SetText(d.level)
	r.Icon:SetTexture(icon)
	r.Icon:SetDesaturated(not earned)
	r.Name:SetText(name or "")
	r.Desc:SetText(desc or "")
	W.Color(r.Name, earned and "text" or "textMuted")
	W.Color(r.Level, d.level == current and "accent" or (earned and "textDim" or "textMuted"))
	r.Mark:SetShown(d.level == current)
	r.State:SetTexture(Theme.Media(earned and "check" or "lock"))
	W.Color(r.State, earned and "accent" or "textMuted")
end

-- The track: progress toward the next level, then a row per level with a reward.
local function buildTrack(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", W.SHELL.pad, 0)
	v:SetWidth(width)
	v.Next = W.Text(v, "body", "text")
	v.Next:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -8)
	v.Value = W.Text(v, "number", "textDim")
	v.Value:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -8)
	v.Bar = W.ProgressLine(v, 2)
	v.Bar:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -36)
	v.Bar:SetPoint("RIGHT", v, "RIGHT", 0, 0)
	v.Panel = W.RowPanel(v)
	v.Panel:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -BAR_H)
	v.Panel:SetPoint("RIGHT", v, "RIGHT", 0, 0)
	v.rows = {}
	return v
end

local function paintTrack(v)
	local data = C_MajorFactions.GetMajorFactionData(FACTION)
	if not data then return 0 end
	local current = data.renownLevel
	local maxed = C_MajorFactions.HasMaximumRenown(FACTION)
	if maxed then
		v.Next:SetText(("Level %d: every reward earned"):format(current))
		v.Value:SetText("")
		W.SetProgress(v.Bar, 1, v:GetWidth())
	else
		v.Next:SetText(("Toward level %d"):format(current + 1))
		v.Value:SetText(("%d / %d"):format(data.renownReputationEarned, data.renownLevelThreshold))
		local t = data.renownLevelThreshold
		W.SetProgress(v.Bar, t > 0 and data.renownReputationEarned / t or 0, v:GetWidth())
	end
	local n = 0
	for _, info in ipairs(C_MajorFactions.GetRenownLevels(FACTION)) do
		local rewards = C_MajorFactions.GetRenownRewardsForLevel(FACTION, info.level)
		if #rewards > 0 then
			n = n + 1
			local r = v.rows[n] or newRow(v.Panel, n)
			v.rows[n] = r
			paintRow(r, { level = info.level, isCapstone = info.isCapstone, rewards = rewards }, current)
			r:Show()
		end
	end
	for i = n + 1, #v.rows do v.rows[i]:Hide() end
	v.Panel:SetHeight(math.max(1, n * ROW_H))
	v.Panel:SetShown(n > 0)
	return BAR_H + n * ROW_H + 24
end

-- Sections not built yet point to the game's window (the Nothing Lost Rule):
-- opened from our code it would taint the micro buttons (docs/CLIENT.md, rule 8).
local function buildSoon(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", W.SHELL.pad, 0)
	v:SetWidth(width)
	v.Text = W.Text(v, "body", "textDim")
	v.Text:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -8)
	v.Text:SetWidth(width)
	v.Text:SetJustifyH("LEFT")
	v.Text:SetWordWrap(true)
	v.Text:SetText("Not in this window yet. Shift-click the Legacy button on your micro menu for the game's own.")
	return v
end

local function build()
	f = W.Shell(NAME, {})
	-- The subject block names the window, in place of Polestar's lockup.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Search, f.Status, f.Stage }) do r:SetParent(holder) end
	local well = CreateFrame("Frame", nil, f.Sidebar)
	well:SetSize(36, 36)
	well:SetPoint("LEFT", f.Sidebar, "TOPLEFT", 24, -47)
	Theme.Skin(well, "inset")
	Theme.Border(well, Theme.Wash("border"))
	f.psIcon = well:CreateTexture(nil, "ARTWORK")
	f.psIcon:SetPoint("TOPLEFT", 1, -1)
	f.psIcon:SetPoint("BOTTOMRIGHT", -1, 1)
	f.psIcon:SetAtlas("Legacy-up-c60")
	f.psName = W.Text(f.Sidebar, "title", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", 24 + 36 + 12, -47)
	f.psName:SetText(LEGACY_BUTTON or "Legacy")
	f.psLine = W.Text(f.Sidebar, "small", "textDim")
	f.psLine:SetPoint("TOPLEFT", f.psName, "BOTTOMLEFT", 0, -6)
	f.psPages = { track = buildTrack(f.Body, f.BodyWidth), challenges = buildSoon(f.Body, f.BodyWidth), tree = buildSoon(f.Body, f.BodyWidth) }
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
	Polestar.CloseOnEscape(NAME)
end

local SUBTITLES = {
	track = "Earn legacy across your characters; each level brings a reward.",
	challenges = "Feats across your characters that earn legacy.",
	tree = "Spend legacy points on lasting bonuses.",
}

function refresh()
	f.psLine:SetText(("Level %d"):format(level()))
	W.ShellNav(f, SECTIONS, section, function(k) M.Show(k) end)
	for _, s in ipairs(SECTIONS) do
		if s.key == section then W.ShellTitle(f, s.label, SUBTITLES[s.key]) end
	end
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, {})
	local h = 40
	for key, v in pairs(f.psPages) do
		v:SetShown(key == section)
	end
	if section == "track" then h = paintTrack(f.psPages.track) end
	W.ShellBody(f, h)
end

function M.Show(key)
	if not f then build() end
	section = key or section
	refresh()
	f:Show()
end

-- As the stock toggle: nothing until the first legacy level.
function M.Toggle()
	if f and f:IsShown() then f:Hide() elseif level() > 0 then M.Show() end
end

function M.Enable()
	-- The legacy key and micro button open ours; the stock window, whose show
	-- touches the micro buttons, is never touched (docs/CLIENT.md, rule 8).
	ns.Doors("Legacy", { TOGGLELEGACYSYSTEM = M.Toggle }, LegacyMicroButton, M.Toggle)
	local function changed() if f and f:IsShown() then refresh() end end
	Polestar.RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", changed)
	Polestar.RegisterEvent("UPDATE_FACTION", changed)
end

ns.Module("legacy", M)
