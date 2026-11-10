-- Legacy (docs/DESIGN.md, "Legacy"): Forever's Legacy System window
-- (LegacySystemFrame, Blizzard_LegacySystem) in a Polestar shell: the reward
-- track, the challenges and the legacy tree as sections.

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local LC = Constants and Constants.LegacyConsts or {}
local NAME = "PolestarUILegacy"
local FACTION = LC.LEGACY_REWARD_TRACK_FACTION_ID or 2802
local POINTS = LC.LEGACY_POINTS_TRAIT_CURRENCY_ID or 4225
local ROW_H, ICON, BAR_H, CRIT_H = 56, 36, 64, 24
-- The sections, on a section rail as the professions are, with the stock
-- window's tab icons (the Two Families Rule: they are the game's).
local SECTIONS = {
	{ key = "track", label = "Rewards", tip = "Reward Track", icon = "Interface/Icons/UI_Chat" },
	{ key = "challenges", label = "Challenges", icon = "Interface/Icons/achievement_guildperk_honorablemention" },
	{ key = "tree", label = "Tree", tip = "Legacy Tree", icon = "Interface/Icons/achievement_guildperk_everybodysfriend" },
}
local f, section = nil, "track"
local M = {}
-- The Challenges page: the open category, the stock filters (completed and
-- incomplete challenges shown), the search, and the challenge unfolded to
-- its objectives.
local chal = { cat = nil, showDone = true, showTodo = true, query = "", open = nil, stale = true }

-- Legacy points are the track's renown level.
local function points() return C_MajorFactions.GetCurrentRenownLevel(FACTION) or 0 end

local refresh -- below
local function redraw() if f and f:IsShown() then refresh() end end

local function hairline(r)
	r.Line = W.Divider(r)
	r.Line:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
	r.Line:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
end

local function iconWell(r, size)
	local well = CreateFrame("Frame", nil, r)
	well:SetSize(size, size)
	Theme.Skin(well, "inset")
	Theme.Border(well, Theme.Wash("border"))
	r.Icon = ns.GameIcon(well)
	r.Icon:SetPoint("TOPLEFT", 1, -1)
	r.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	return well
end

---------------------------------------------------------------------------
-- Reward Track

-- The stock card's tooltip (RenownLevelMixin:RefreshTooltip): one reward
-- names itself; a level of several lists them.
local function rewardTip(r)
	local d = r.psLevel
	if not d then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	local again = function() if GameTooltip:GetOwner() == r then rewardTip(r) end end
	if d.isCapstone and RENOWN_REWARD_CAPSTONE_TOOLTIP_TITLE then
		GameTooltip:SetText(RENOWN_REWARD_CAPSTONE_TOOLTIP_TITLE, 1, 1, 1)
		GameTooltip:AddLine(RENOWN_REWARD_CAPSTONE_TOOLTIP_DESC, nil, nil, nil, true)
	elseif #d.rewards == 1 then
		local _, name, desc = RenownRewardUtil.GetRenownRewardInfo(d.rewards[1], again)
		GameTooltip:SetText(name or "", 1, 1, 1)
		if desc then GameTooltip:AddLine(desc, nil, nil, nil, true) end
	else
		GameTooltip:SetText(("Rewards at %d points"):format(d.level), 1, 1, 1)
		for _, reward in ipairs(d.rewards) do
			local _, name = RenownRewardUtil.GetRenownRewardInfo(reward, again)
			if name then GameTooltip:AddLine("- " .. name) end
		end
	end
	GameTooltip:Show()
end

local function newRewardRow(parent, i)
	local r = CreateFrame("Button", nil, parent)
	r:SetHeight(ROW_H)
	r:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(i - 1) * ROW_H)
	r:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
	if i > 1 then hairline(r) end
	W.Hover(r)
	r:SetScript("OnEnter", rewardTip)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	-- The reward the player is working toward, marked as a selected row is.
	r.Mark = W.Fill(r, "accent", "ARTWORK", 0)
	r.Mark:ClearAllPoints()
	r.Mark:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
	r.Mark:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
	r.Mark:SetWidth(2)
	r.Level = W.Text(r, "number", "textDim")
	r.Level:SetPoint("CENTER", r, "LEFT", 32, 0)
	local well = iconWell(r, ICON)
	well:SetPoint("LEFT", r, "LEFT", 64, 0)
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

local function rewardName(d)
	local icon, name, desc = RenownRewardUtil.GetRenownRewardInfo(d.rewards[1], redraw)
	if #d.rewards > 1 then name = ("%s and %d more"):format(name or "", #d.rewards - 1) end
	return icon, name or "", desc or ""
end

local function paintRewardRow(r, d, current, nextLevel)
	r.psLevel = d
	local earned = d.level <= current
	local icon, name, desc = rewardName(d)
	r.Level:SetText(d.level)
	r.Icon:SetTexture(icon)
	r.Icon:SetDesaturated(not earned)
	r.Name:SetText(name)
	r.Desc:SetText(desc)
	W.Color(r.Name, earned and "text" or "textMuted")
	W.Color(r.Level, d.level == nextLevel and "accent" or (earned and "textDim" or "textMuted"))
	r.Mark:SetShown(d.level == nextLevel)
	r.State:SetTexture(Theme.Media(earned and "check" or "lock"))
	W.Color(r.State, earned and "accent" or "textMuted")
end

-- The track: progress toward the next reward, then a row per reward, each at
-- the legacy points it needs.
local function buildTrack(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", W.SHELL.pad, 0)
	v:SetWidth(width)
	v.Next = W.Text(v, "body", "text")
	v.Next:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -8)
	v.Value = W.Text(v, "number", "textDim")
	v.Value:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -8)
	v.Next:SetPoint("RIGHT", v.Value, "LEFT", -16, 0)
	v.Next:SetJustifyH("LEFT")
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
	local current = points()
	local levels = {}
	for _, info in ipairs(C_MajorFactions.GetRenownLevels(FACTION) or {}) do
		local rewards = C_MajorFactions.GetRenownRewardsForLevel(FACTION, info.level)
		if rewards and #rewards > 0 then levels[#levels + 1] = { level = info.level, isCapstone = info.isCapstone, rewards = rewards } end
	end
	local nextReward
	for _, d in ipairs(levels) do
		if d.level > current then nextReward = d; break end
	end
	if nextReward then
		local _, name = rewardName(nextReward)
		v.Next:SetText(("Next: %s"):format(name))
		v.Value:SetText(("%d / %d"):format(current, nextReward.level))
		W.SetProgress(v.Bar, current / nextReward.level, v:GetWidth())
	else
		v.Next:SetText("Every reward earned")
		v.Value:SetText(current)
		W.SetProgress(v.Bar, 1, v:GetWidth())
	end
	for i, d in ipairs(levels) do
		local r = v.rows[i] or newRewardRow(v.Panel, i)
		v.rows[i] = r
		paintRewardRow(r, d, current, nextReward and nextReward.level)
		r:Show()
	end
	for i = #levels + 1, #v.rows do v.rows[i]:Hide() end
	v.Panel:SetHeight(math.max(1, #levels * ROW_H))
	v.Panel:SetShown(#levels > 0)
	return BAR_H + #levels * ROW_H + 24
end

---------------------------------------------------------------------------
-- Challenges: achievements under the client's legacy categories.

-- Done as the stock page counts it: earned by this character (one earned by
-- another counts as not done; AchievementFrame_ShowAsComplete).
local function challenges(cat, matches)
	local list, n = {}, GetCategoryNumAchievements(cat) or 0
	for i = 1, n do
		local id, name, _, completed, month, day, year, desc, _, icon, _, _, mine = GetAchievementInfo(cat, i)
		if id then
			local done = completed and mine
			local shown = (done and chal.showDone or not done and chal.showTodo) and (not matches or matches[id])
			if shown then
				list[#list + 1] = { id = id, name = name, desc = desc, icon = icon, done = done,
					date = done and FormatShortDate and FormatShortDate(day, month, year) or nil,
					points = C_Traits.GetTraitCurrencyForAchievement(POINTS, id) or 0 }
			end
		end
	end
	return list
end

-- The challenges the client's search lets through (LegacySystem.GetFilteredChallenges).
-- The stock page filters through it even with no search: the client's list
-- holds only the challenges it shows (no hidden ones). Before the client has
-- answered (an empty list with no search), nothing is filtered out.
local function matches()
	local n = GetNumFilteredAchievements()
	if n == 0 and chal.query == "" then return nil end
	local set = {}
	for i = 1, n do set[GetFilteredAchievementID(i)] = true end
	return set
end

-- The categories as the stock list builds them (LegacyChallengesPageMixin:
-- GenerateDataProvider): only those with a challenge shown, and their
-- ancestors; a parent placed where its first shown descendant comes in the
-- client's list, which can name a child before its parent; any depth.
-- Each: { id, name, kids, own (challenges shown in it), count (in it and below) }.
local function categoryTree(found)
	local unviewed = LegacyChallengeViewedUtil and LegacyChallengeViewedUtil.CategoryHasUnviewedChallenges
	local list, info, visible = GetCategoryList() or {}, {}, {}
	for _, id in ipairs(list) do
		local name, parent = GetCategoryInfo(id)
		info[id] = { name = name, parent = parent, own = #challenges(id, found) }
	end
	for _, id in ipairs(list) do
		if info[id].own > 0 then
			local c = id
			while c and info[c] and not visible[c] do
				visible[c] = true
				c = info[c].parent
			end
		end
	end
	local tops, byId = {}, {}
	local function node(id)
		if not visible[id] then return nil end
		if byId[id] then return byId[id] end
		local i = info[id]
		local c = { id = id, name = i.name, kids = {}, own = i.own, count = 0, dot = unviewed and unviewed(id) or false }
		local p = i.parent and i.parent ~= -1 and node(i.parent)
		if p then
			c.parent = p
			table.insert(p.kids, c)
		else
			tops[#tops + 1] = c
		end
		byId[id] = c
		-- Each shown challenge counts in its category and every one above it.
		local up = c
		while up do
			up.count = up.count + i.own
			up.dot = up.dot or c.dot
			up = up.parent
		end
		return c
	end
	for _, id in ipairs(list) do node(id) end
	return tops, byId
end

-- The sidebar's category list under the search, folding as the stock one
-- does: a top category with sub-categories is a group row whose chevron
-- folds them (all open while searching); one without is a row of its own.
-- Text only: no icon on any row.
local HEAD_H, CAT_H = 36, 30
local unfolded, heads, cats = {}, {}, {}

local function catRow(list, i, group)
	if list[i] then return list[i] end
	local r = CreateFrame("Button", nil, f.NavScroll.Child)
	W.Hover(r)
	r.Sel = r:CreateTexture(nil, "BACKGROUND")
	r.Sel:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.Sel:SetAllPoints(r)
	W.Painter(r.Sel, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	r.Bar = W.Fill(r, "accent", "ARTWORK", 0)
	r.Bar:ClearAllPoints()
	r.Bar:SetPoint("TOPLEFT")
	r.Bar:SetPoint("BOTTOMLEFT")
	r.Bar:SetWidth(2)
	r.Count = W.Text(r, "number", "textMuted")
	r.Count:SetPoint("RIGHT", r, "RIGHT", -W.SHELL.side, 0)
	-- The stock list's "new" mark: a challenge earned here not yet seen.
	r.Dot = W.Fill(r, "accent", "ARTWORK", 0)
	r.Dot:ClearAllPoints()
	r.Dot:SetSize(6, 6)
	r.Dot:SetPoint("RIGHT", r.Count, "LEFT", -8, 0)
	r.Chevron = W.Tex(r, "ARTWORK", "chevron-right", "textMuted")
	r.Chevron:SetSize(12, 12)
	r.Chevron:SetPoint("LEFT", r, "LEFT", W.SHELL.side, 0)
	-- Group rows in the label face, their categories in body text under them.
	r.Label = W.Text(r, group and "label" or "body", group and "textDim" or "text")
	r.Label:SetPoint("LEFT", r, "LEFT", W.SHELL.side + 20, 0)
	r.Label:SetPoint("RIGHT", r.Dot, "LEFT", -8, 0)
	r.Label:SetJustifyH("LEFT")
	r.Label:SetWordWrap(false)
	r:SetScript("OnClick", function(self)
		local c = self.psCat
		if self.psGroup then
			unfolded[c.id] = not unfolded[c.id] or nil
			-- A group holding challenges of its own opens them too.
			if c.own > 0 then chal.cat, chal.open = c.id, nil end
		else
			chal.cat, chal.open = c.id, nil
		end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		M.Show("challenges")
	end)
	list[i] = r
	return r
end

local function paintCat(r, c, y, h, group)
	r.psCat, r.psGroup = c, group
	local on = c.id == chal.cat
	r:ClearAllPoints()
	r:SetPoint("TOPLEFT", f.NavScroll.Child, "TOPLEFT", 0, -y)
	r:SetPoint("TOPRIGHT", f.NavScroll.Child, "TOPRIGHT", 0, -y)
	r:SetHeight(h)
	r.Chevron:SetShown(group)
	r.Label:SetText(c.name or "")
	r.Count:SetText(c.count > 0 and c.count or "")
	r.Dot:SetShown(c.dot and true or false)
	r.Sel:SetShown(on)
	r.Bar:SetShown(on)
	-- A category the search or the tab leaves empty is dimmed.
	W.Color(r.Label, on and "text" or (c.count == 0 and "textMuted" or (group ~= nil and "textDim" or "navRest")))
	r:Show()
end

local function paintCategories(tops)
	local y, hi, ci = 0, 0, 0
	-- Top categories on group rows; those below on category rows, a level
	-- deeper indented further. Any category with sub-categories folds.
	local function walk(list, depth)
		for _, c in ipairs(list) do
			local group = #c.kids > 0
			local r
			if depth == 0 then
				hi = hi + 1
				r = catRow(heads, hi, true)
			else
				ci = ci + 1
				r = catRow(cats, ci)
			end
			local h = depth == 0 and HEAD_H or CAT_H
			-- true: folds; false: a top category of its own; nil: a leaf below.
			local kind = group or nil
			if depth == 0 then kind = group end
			paintCat(r, c, y, h, kind)
			-- Each level starts at its parent's label; a chevron goes before its label.
			local x = W.SHELL.side + 20 * depth
			r.Chevron:SetPoint("LEFT", r, "LEFT", x, 0)
			r.Label:SetPoint("LEFT", r, "LEFT", (group or depth == 0) and x + 20 or x, 0)
			y = y + h
			if group then
				local open = chal.query ~= "" or unfolded[c.id]
				r.Chevron:SetTexture(Theme.Media(open and "chevron-down" or "chevron-right"))
				if open then walk(c.kids, depth + 1) end
			end
		end
	end
	walk(tops, 0)
	for i = hi + 1, #heads do heads[i]:Hide() end
	for i = ci + 1, #cats do cats[i]:Hide() end
	f.NavScroll.Child:SetWidth((f.psSidebar or W.SHELL.sidebar) - 1)
	W.SetScrollContent(f.NavScroll, y, W.ShellNavHeight(f))
end

-- The stock card's clicks (AchievementTemplateMixin:ProcessClick):
-- shift-click links it in chat, or tracks it with no chat box open.
local function track(id)
	local T = Enum.ContentTrackingType.Achievement
	if C_ContentTracking.IsTracking(T, id) then
		C_ContentTracking.StopTracking(T, id, Enum.ContentTrackingStopType.Manual)
		return
	end
	local err = C_ContentTracking.StartTracking(T, id)
	if err and ContentTrackingUtil then ContentTrackingUtil.DisplayTrackingError(err) end
end

local function challengeClick(r)
	local id = r.psData.id
	if IsModifiedClick("CHATLINK") and ChatFrameUtil and ChatFrameUtil.InsertLink(GetAchievementLink(id)) then return end
	if IsModifiedClick("QUESTWATCHTOGGLE") then
		if not r.psData.done then track(id) end
		return
	end
	chal.open = chal.open ~= id and id or nil
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	refresh()
end

local function challengeTip(r)
	local d = r.psData
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(d.name, 1, 1, 1)
	if d.points > 0 then GameTooltip:AddLine(("Earns %d legacy %s."):format(d.points, d.points == 1 and "point" or "points")) end
	ns.TooltipHint(d.done and "Shift-click to link it in chat."
		or "Click to see its objectives. Shift-click to link it in chat, or to track it.")
	GameTooltip:Show()
end

local function newChallengeRow(parent)
	local r = CreateFrame("Button", nil, parent)
	r:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
	hairline(r)
	W.Hover(r)
	r:SetScript("OnClick", challengeClick)
	r:SetScript("OnEnter", challengeTip)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	local well = iconWell(r, ICON)
	well:SetPoint("TOPLEFT", r, "TOPLEFT", 16, -12)
	-- Its legacy points on a chip, the date it was earned under them.
	r.Points = W.Text(r, "number", "accent")
	r.Points:SetPoint("TOPRIGHT", r, "TOPRIGHT", -16, -14)
	r.Date = W.Text(r, "small", "textMuted")
	r.Date:SetPoint("TOPRIGHT", r.Points, "BOTTOMRIGHT", 0, -6)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("TOPLEFT", well, "TOPRIGHT", 12, -1)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -96, 0)
	r.Name:SetJustifyH("LEFT")
	r.Desc = W.Text(r, "small", "textDim")
	r.Desc:SetPoint("TOPLEFT", r.Name, "BOTTOMLEFT", 0, -6)
	r.Desc:SetPoint("RIGHT", r, "RIGHT", -96, 0)
	r.Desc:SetJustifyH("LEFT")
	r.Desc:SetWordWrap(true)
	r.crits = {}
	return r
end

-- One objective: a check or a dot and its text, or, for a counted one, a
-- skill bar with its count (LegacyChallengeCriteriaMixin).
local function crit(r, i)
	local c = r.crits[i]
	if c then return c end
	c = CreateFrame("Frame", nil, r)
	c:SetHeight(CRIT_H)
	c.Mark = W.Tex(c, "ARTWORK", "check", "accent")
	c.Mark:SetSize(12, 12)
	c.Mark:SetPoint("LEFT", c, "LEFT", 0, 0)
	c.Text = W.Text(c, "small", "text")
	c.Text:SetPoint("LEFT", c, "LEFT", 20, 0)
	c.Text:SetPoint("RIGHT", c, "RIGHT", 0, 0)
	c.Text:SetJustifyH("LEFT")
	c.Text:SetWordWrap(false)
	c.Bar = W.ProgressLine(c, 2)
	c.Bar:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 4)
	c.Bar:SetPoint("RIGHT", c, "RIGHT", 0, 0)
	c.Count = W.Text(c, "small", "textDim")
	c.Count:SetPoint("BOTTOMRIGHT", c.Bar, "TOPRIGHT", 0, 4)
	r.crits[i] = c
	return c
end

local function paintCrits(r, id, top, width)
	local n = GetAchievementNumCriteria(id) or 0
	local colW = (width - 24) / 2
	for i = 1, n do
		local text, _, done, q, req, _, flags = GetAchievementCriteriaInfo(id, i)
		local c = crit(r, i)
		local counted = flags and req and req > 0 and EVALUATION_TREE_FLAG_PROGRESS_BAR
			and bit.band(flags, EVALUATION_TREE_FLAG_PROGRESS_BAR) == EVALUATION_TREE_FLAG_PROGRESS_BAR
		local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
		c:ClearAllPoints()
		c:SetPoint("TOPLEFT", r, "TOPLEFT", 64 + col * (colW + 24), -(top + line * CRIT_H))
		-- A lone count spans the row.
		c:SetWidth((n == 1 and counted) and width or colW)
		c.Mark:SetShown(not counted)
		c.Mark:SetTexture(Theme.Media(done and "check" or "circle"))
		W.Color(c.Mark, done and "accent" or "textMuted")
		c.Text:ClearAllPoints()
		if counted then
			c.Text:SetPoint("BOTTOMLEFT", c.Bar, "TOPLEFT", 0, 4)
			c.Text:SetPoint("RIGHT", c.Count, "LEFT", -8, 0)
		else
			c.Text:SetPoint("LEFT", c, "LEFT", 20, 0)
			c.Text:SetPoint("RIGHT", c, "RIGHT", 0, 0)
		end
		c.Text:SetText(text or "")
		W.Color(c.Text, done and "text" or "textDim")
		c.Bar:SetShown(counted)
		c.Count:SetShown(counted)
		if counted then
			c.Count:SetText(("%d / %d"):format(q, req))
			W.SetProgress(c.Bar, math.min(q / req, 1), c:GetWidth())
		end
		c:Show()
	end
	for i = n + 1, #r.crits do r.crits[i]:Hide() end
	return math.ceil(n / 2) * CRIT_H
end

local function paintChallengeRow(r, d, y, first)
	r.psData = d
	r:ClearAllPoints()
	r:SetPoint("TOPLEFT", r:GetParent(), "TOPLEFT", 0, -y)
	r:SetPoint("RIGHT", r:GetParent(), "RIGHT", 0, 0)
	r.Line:SetShown(not first)
	r.Icon:SetTexture(d.icon)
	r.Icon:SetDesaturated(not d.done)
	r.Name:SetText(d.name or "")
	-- A set width: the client measures a wrapped string only once it has one.
	r.Desc:SetWidth(f.BodyWidth - 64 - 96)
	r.Desc:SetText(d.desc or "")
	W.Color(r.Name, d.done and "text" or "textDim")
	r.Points:SetText(d.points > 0 and ("+%d"):format(d.points) or "")
	W.Color(r.Points, d.done and "accent" or "textMuted")
	r.Date:SetText(d.date or "")
	local h = math.max(ROW_H + 4, 12 + 20 + 6 + r.Desc:GetStringHeight() + 12)
	if chal.open == d.id then
		h = h + paintCrits(r, d.id, h, f.BodyWidth - 64 - 16) + 8
	else
		for _, c in ipairs(r.crits) do c:Hide() end
	end
	r:SetHeight(h)
	return h
end

local function buildChallenges(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", W.SHELL.pad, 0)
	v:SetWidth(width)
	v.Panel = W.RowPanel(v)
	v.Panel:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -16)
	v.Panel:SetPoint("RIGHT", v, "RIGHT", 0, 0)
	v.Empty = W.Text(v, "body", "textDim")
	v.Empty:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -16)
	v.rows = {}
	return v
end

local function paintChallenges(v, list)
	local y = 0
	for i, d in ipairs(list) do
		local r = v.rows[i] or newChallengeRow(v.Panel)
		v.rows[i] = r
		y = y + paintChallengeRow(r, d, y, i == 1)
		r:Show()
	end
	for i = #list + 1, #v.rows do v.rows[i]:Hide() end
	v.Panel:SetHeight(math.max(1, y))
	v.Panel:SetShown(#list > 0)
	v.Empty:SetShown(#list == 0)
	v.Empty:SetText(chal.query ~= "" and "No challenge here matches your search." or "No challenges here.")
	return #list > 0 and 16 + y + 24 or 56
end

-- The stock filter menu (LegacyChallengeFilters): completed and incomplete
-- challenges, each shown or hidden; it opens again after each pick.
local function filterMenu(anchor)
	if W.MenuShown(anchor) then return W.HideMenu() end
	local function pick(key)
		return function()
			chal[key], chal.open = not chal[key], nil
			refresh()
			filterMenu(anchor)
		end
	end
	W.ShowMenu(anchor, {
		{ text = ACHIEVEMENTFRAME_FILTER_COMPLETED or "Completed", checked = chal.showDone, onClick = pick("showDone") },
		{ text = ACHIEVEMENTFRAME_FILTER_INCOMPLETE or "Incomplete", checked = chal.showTodo, onClick = pick("showTodo") },
	}, { minWidth = 160 })
end

---------------------------------------------------------------------------

-- The tree is not built yet: it points to the game's window (the Nothing
-- Lost Rule); opened from our code it would taint the micro buttons
-- (docs/CLIENT.md, rule 8).
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
	f = W.Shell(NAME, { rail = true, searchPlaceholder = "Search challenges", onSearch = function(text)
		chal.query = text or ""
		-- The client searches every category and answers with ACHIEVEMENT_SEARCH_UPDATED.
		SetAchievementSearchString(chal.query)
		redraw()
	end })
	-- The subject block names the window, in place of Polestar's lockup.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Status, f.Stage }) do r:SetParent(holder) end
	-- The Legacy emblem heads the rail, where Polestar's stands in its own,
	-- centred on the title's line.
	f.psEmblem = f.Rail:CreateTexture(nil, "ARTWORK")
	f.psEmblem:SetSize(40, 40)
	f.psEmblem:SetPoint("CENTER", f.Rail, "TOP", 0, -47)
	f.psEmblem:SetAtlas("Legacy-up-c60")
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
	-- The filter acts on the list: at the end of the search row, as the
	-- crafting window's.
	local top = W.SHELL.header - 30
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + 30 + 6), -top)
	f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", filterMenu, 14)
	f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -top)
	Theme.Skin(f.psFilter, "editbox")
	f.psPages = { track = buildTrack(f.Body, f.BodyWidth), challenges = buildChallenges(f.Body, f.BodyWidth), tree = buildSoon(f.Body, f.BodyWidth) }
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
	Polestar.CloseOnEscape(NAME)
end

-- The sidebar (the categories and their search) on Challenges only; the
-- other pages take its width. The main column hangs off the rail's edge
-- then, never off the hidden sidebar (docs/CLIENT.md, rule 12).
local function sidebar(on)
	f.Sidebar:SetShown(on)
	f.Main:ClearAllPoints()
	if on then
		f.Main:SetPoint("TOPLEFT", f.Sidebar, "TOPRIGHT", 0, 0)
	else
		f.Main:SetPoint("TOPLEFT", f, "TOPLEFT", 1 + f.psRail, -1)
	end
	f.Main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
	f.BodyWidth = f:GetWidth() - f.psRail - (on and f.psSidebar or 0) - 2 - W.SHELL.pad * 2
	f.psPages[section]:SetWidth(f.BodyWidth)
end

local function paintRail()
	W.ShellRail(f, SECTIONS, nil, section, function(key) M.Show(key) end)
	for i, d in ipairs(SECTIONS) do
		local b = f.railButtons[i]
		b.psTip = d.tip or d.label
		-- A game icon, not a glyph: the rail's tint taken off, its border cropped.
		W.Uncolor(b.Icon)
		b.Icon:SetVertexColor(1, 1, 1, 1)
		b.Icon:SetTexture(d.icon)
		b.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		b.Icon:SetSize(24, 24)
	end
end

function refresh()
	local pts = points()
	f.psLine:SetText(("%d Legacy %s"):format(pts, pts == 1 and "Point" or "Points"))
	local onChallenges = section == "challenges"
	paintRail()
	sidebar(onChallenges)
	local h = 40
	for key, v in pairs(f.psPages) do v:SetShown(key == section) end
	if onChallenges then
		-- The client drops its search data on every loading screen and builds
		-- it again only when a search is set (LegacyChallengesPageMixin:OnShow);
		-- ACHIEVEMENT_SEARCH_UPDATED redraws with it.
		if chal.stale then
			chal.stale = false
			SetAchievementSearchString(chal.query)
		end
		local found = matches()
		local tops, byId = categoryTree(found)
		-- The class's own category first, its group unfolded, as the stock page opens.
		if not chal.cat then
			local default = LC["LEGACY_DEFAULT_CATEGORY_" .. select(2, UnitClass("player"))]
			local first = tops[1] and (tops[1].kids[1] or tops[1])
			chal.cat = default and byId[default] and default or (first and first.id)
			local c = byId[chal.cat]
			c = c and c.parent
			while c do
				unfolded[c.id] = true
				c = c.parent
			end
		end
		if chal.cat and LegacyChallengeViewedUtil then LegacyChallengeViewedUtil.MarkCategoryViewed(chal.cat) end
		paintCategories(tops)
		local total = C_Traits.GetMaxAvailableTraitCurrency(POINTS, false) or 0
		W.ShellTitle(f, chal.cat and GetCategoryInfo(chal.cat) or "Challenges",
			("%d of %d legacy points earned. Challenges are shared by all your characters."):format(pts, total))
		W.ShellTabs(f, nil)
		-- The glyph in the accent while a filter hides challenges.
		W.SetIconState(f.psFilter, not (chal.showDone and chal.showTodo))
		h = paintChallenges(f.psPages.challenges, chal.cat and challenges(chal.cat, found) or {})
	else
		W.ShellTabs(f, nil)
		if section == "track" then
			W.ShellTitle(f, "Reward Track", ("%d legacy points. Earn more from challenges; each reward unlocks at the points shown."):format(pts))
			h = paintTrack(f.psPages.track)
		else
			W.ShellTitle(f, "Legacy Tree", "Spend legacy points on lasting bonuses.")
		end
	end
	W.ShellFooter(f, {}, {})
	W.ShellBody(f, h)
end

function M.Show(key)
	if not f then build() end
	section = key or section
	refresh()
	f:Show()
end

-- As the stock toggle: nothing before the first legacy point.
function M.Toggle(key)
	if f and f:IsShown() and (key == nil or key == section) then
		f:Hide()
	elseif points() > 0 then
		M.Show(key)
	end
end

function M.Enable()
	-- The legacy and achievements keys and the micro button open ours; the
	-- stock window, whose show touches the micro buttons, is never touched
	-- (docs/CLIENT.md, rule 8). Challenge links stay the game's.
	ns.Doors("Legacy", {
		TOGGLELEGACYSYSTEM = function() M.Toggle() end,
		TOGGLEACHIEVEMENT = function() M.Toggle("challenges") end,
	}, LegacyMicroButton, function() M.Toggle() end)
	Polestar.RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", redraw)
	Polestar.RegisterEvent("UPDATE_FACTION", redraw)
	Polestar.RegisterEvent("PLAYER_ENTERING_WORLD", function() chal.stale = true; redraw() end)
	for _, e in ipairs({ "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "ACHIEVEMENT_SEARCH_UPDATED", "CONTENT_TRACKING_UPDATE" }) do
		Polestar.RegisterEvent(e, redraw)
	end
end

ns.Module("legacy", M)
