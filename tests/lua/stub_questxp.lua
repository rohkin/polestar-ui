-- Polestar 0.4.2's "Completed quest XP" (Polestar/QoL/QuestXP.lua, not in
-- the 0.4.0 the tests run against), as it draws on the game's XP bar: on a
-- refresh (QuestXP.Refresh, which asks QoL.XPMark.Bar first) with quest XP,
-- a frame of Polestar's made under the shown XP bar the first time
-- (SetAllPoints on its StatusBar, MEDIUM, a level under OverlayFrame, alpha
-- 0.8): Tint (a sage gradient masked by the game's fill atlas, from the XP
-- fill to the quest XP's end, inset 2, BOTTOMLEFT at inset - 0.5, ended by
-- Tint:SetShown), Rested (a copy of the game's pip on the rest tick) and
-- LevelLabel ("+1 level", sage). Load after stub_statusbars.lua.
--
--   stub.questXP(total)   quests ready to hand in worth `total` XP (0: none), then Polestar's refresh

local SAGE = { 91 / 255, 149 / 255, 80 / 255 }
local QoL
local QuestXP = { total = 0, count = 0 }

local function xpBar()
	for _, c in ipairs({ MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer }) do
		local bar = c.bars[4]
		if bar:IsShown() then return bar end
	end
end
-- Polestar sets its global as it loads: QuestXP goes in once it has (before login, as in the client).
local function install()
	if QoL or not Polestar then return end
	Polestar.QoL = Polestar.QoL or {}
	QoL = Polestar.QoL
	QoL.XPMark = QoL.XPMark or {}
	-- Each refresh asks it first (Polestar: QoL.XPMark.Bar()).
	QoL.XPMark.Bar = function() return xpBar() end
	QoL.QuestXP = QuestXP
end
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", install)

local frame
local function draw()
	local xp, limit, total = QuestXP.xp, QuestXP.limit, QuestXP.total
	if not (xp and limit and limit > 0 and total > 0) then frame:Hide(); return end
	local w, h = frame.bar:GetWidth(), frame.bar:GetHeight()
	local inset = math.min(2, w / 4, h / 4)
	local left = math.max(math.min(1, xp / limit) * w, inset)
	local right = math.min(math.min(1, (xp + total) / limit) * w, w - inset)
	local tint = frame.Tint
	tint:SetShown(right - left > 0)
	-- Seen in game: after our fade (a post-hook on this SetShown) Tint read
	-- alpha 1 again, Rested 0 (probe: 6 regions, SetShown hooked, Tint shown
	-- at 1). Polestar's source sets no alpha on it; the stub brings it back
	-- here, after the hook, so a fade by SetAlpha alone fails.
	tint:SetAlpha(1)
	tint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", left, inset - 0.5)
	tint:SetSize(right - left - 1, h - 2 * inset)
	frame.Rested:SetShown(tint:IsShown() and frame.bar.ExhaustionTick:IsShown())
	frame.LevelLabel:SetShown(xp + total >= limit)
	frame:Show()
end

local function attach(bar)
	if not frame then
		frame = CreateFrame("Frame", nil, bar)
		frame.bar = bar
		frame:SetAllPoints(bar.StatusBar)
		frame:SetFrameStrata("MEDIUM")
		frame:SetFrameLevel(bar.OverlayFrame:GetFrameLevel() - 1)
		frame:SetAlpha(0.8)
		frame.Tint = frame:CreateTexture(nil, "OVERLAY")
		frame.Tint:SetTexture(Polestar.Theme.Media("white"))
		frame.Tint:SetVertexColor(SAGE[1] * 1.08, SAGE[2] * 1.08, SAGE[3] * 1.08, 0.5) -- Polestar: a vertical SetGradient
		local mask = frame:CreateMaskTexture()
		mask:SetAtlas("UI-HUD-ExperienceBar-Fill-Experience")
		mask:SetAllPoints(frame)
		frame.Tint:AddMaskTexture(mask)
		local rested = CreateFrame("Frame", nil, frame)
		local pip = rested:CreateTexture(nil, "OVERLAY")
		pip:SetAtlas("UI-HUD-ExperienceBar-Frame-Pip")
		pip:SetColorTexture(0.55, 0.85, 1, 1)
		pip:SetAllPoints(rested)
		rested:SetAllPoints(bar.ExhaustionTick)
		frame.Rested = rested
		frame.LevelLabel = frame:CreateFontString(nil, "OVERLAY")
		frame.LevelLabel:SetFont(STANDARD_TEXT_FONT, 10, "")
		frame.LevelLabel:SetText("+1 level")
		frame.LevelLabel:SetTextColor(SAGE[1], SAGE[2], SAGE[3], 1)
		frame.LevelLabel:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
		frame:SetScript("OnSizeChanged", draw)
		QuestXP.frame = frame
	end
	draw()
end

function QuestXP.Refresh()
	local bar = QoL.XPMark.Bar()
	if not bar then if frame then frame:Hide() end return end
	QuestXP.xp, QuestXP.limit = UnitXP("player"), UnitXPMax("player")
	if QuestXP.total > 0 then attach(bar) elseif frame then frame:Hide() end
end

function stub.questXP(total)
	QuestXP.total, QuestXP.count = total, total > 0 and 1 or 0
	QuestXP.Refresh()
end
