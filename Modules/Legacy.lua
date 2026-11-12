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
-- What each page is for lives in its rail tooltip; the subtitle is a status line.
local SECTIONS = {
	{ key = "track", label = "Rewards", tip = "Reward Track", icon = "Interface/Icons/UI_Chat",
		about = "Earn legacy points from challenges; each reward unlocks at the points shown." },
	{ key = "challenges", label = "Challenges", icon = "Interface/Icons/achievement_guildperk_honorablemention",
		about = "Challenges are shared by all your characters, and each one earns legacy points." },
	{ key = "tree", label = "Tree", tip = "Legacy Tree", icon = "Interface/Icons/achievement_guildperk_everybodysfriend",
		about = "Spend legacy points on talents. Your changes wait until you apply them." },
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

local iconWell = ns.ItemWell

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
	r:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(i - 1) * ROW_H)
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
	local well
	well, r.Icon = iconWell(r, ICON)
	well:SetPoint("LEFT", r, "LEFT", 64, 0)
	r.State = W.Tex(r, "ARTWORK", "check", "accent")
	r.State:SetSize(14, 14)
	r.State:SetPoint("RIGHT", r, "RIGHT", -16, 0)
	r.Well = well
	-- One line each, cut short cleanly: never wrapping up over the row's top.
	r.Name = W.Text(r, "body", "text")
	r.Name:SetJustifyH("LEFT")
	r.Name:SetWordWrap(false)
	r.Desc = W.Text(r, "small", "textDim")
	r.Desc:SetPoint("TOPLEFT", well, "RIGHT", 12, -3)
	r.Desc:SetPoint("TOPRIGHT", r, "RIGHT", -46, -3)
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
	-- Over its description, or centred on the icon when there is none.
	local two = desc ~= ""
	r.Desc:SetShown(two)
	r.Name:ClearAllPoints()
	r.Name:SetPoint(two and "BOTTOMLEFT" or "LEFT", r.Well, "RIGHT", 12, two and 2 or 0)
	r.Name:SetPoint(two and "BOTTOMRIGHT" or "RIGHT", r, "RIGHT", -46, two and 2 or 0)
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
	v.Next:SetPoint("TOPRIGHT", v.Value, "TOPLEFT", -16, 0)
	v.Next:SetJustifyH("LEFT")
	v.Bar = W.ProgressLine(v, 2)
	v.Bar:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -36)
	v.Bar:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -36)
	v.Panel = W.RowPanel(v)
	v.Panel:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -BAR_H)
	v.Panel:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -BAR_H)
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
	v:SetHeight(BAR_H + #levels * ROW_H)
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
	-- The stock list's "new" mark: a challenge earned here not yet seen; a
	-- fixed slot left of the count's (three digits wide), never moving with it.
	r.Dot = W.Fill(r, "accent", "ARTWORK", 0)
	r.Dot:ClearAllPoints()
	r.Dot:SetSize(6, 6)
	r.Dot:SetPoint("RIGHT", r, "RIGHT", -(W.SHELL.side + 24 + 8), 0)
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
	hairline(r)
	W.Hover(r)
	r:SetScript("OnClick", challengeClick)
	r:SetScript("OnEnter", challengeTip)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	local well
	well, r.Icon = iconWell(r, ICON)
	well:SetPoint("TOPLEFT", r, "TOPLEFT", 16, -12)
	-- Its legacy points on a chip, the date it was earned under them.
	r.Points = W.Text(r, "number", "accent")
	r.Points:SetPoint("TOPRIGHT", r, "TOPRIGHT", -16, -14)
	r.Date = W.Text(r, "small", "textMuted")
	r.Date:SetPoint("TOPRIGHT", r.Points, "BOTTOMRIGHT", 0, -6)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("TOPLEFT", well, "TOPRIGHT", 12, -1)
	r.Name:SetPoint("TOPRIGHT", r, "TOPRIGHT", -96, -13)
	r.Name:SetJustifyH("LEFT")
	r.Name:SetWordWrap(false) -- one line, cut short: never over the next row
	r.Desc = W.Text(r, "small", "textDim")
	r.Desc:SetPoint("TOPLEFT", r.Name, "BOTTOMLEFT", 0, -6)
	r.Desc:SetPoint("TOPRIGHT", r.Name, "BOTTOMRIGHT", 0, -6)
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
	c.Bar:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 4)
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
			c.Text:SetPoint("BOTTOMRIGHT", c.Count, "BOTTOMLEFT", -8, 0)
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
	r:SetPoint("TOPRIGHT", r:GetParent(), "TOPRIGHT", 0, -y)
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
	v.Panel:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -16)
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
	v:SetHeight(#list > 0 and 16 + y or 40)
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

---------------------------------------------------------------------------
-- Legacy Tree: three trait trees (LegacyTreeData), one shown at a time, its
-- points staged until Apply, as the stock page (LegacyTreeTraitPanelMixin).

local TREES = {
	{ id = LC.LEGACY_TREE_PROFESSIONS_ID or 1187, atlas = "UI-Legacy-Tree-Professions", name = LEGACY_TREE_PROFESSIONS or "Professions" },
	{ id = LC.LEGACY_TREE_ADVENTURE_ID or 1188, atlas = "UI-Legacy-Tree-Adventure", name = LEGACY_TREE_ADVENTURE or "Adventure" },
	{ id = LC.LEGACY_TREE_PROGRESSION_ID or 1189, atlas = "UI-Legacy-Tree-Progression", name = LEGACY_TREE_PROGRESSION or "Progression" },
}
local NODE, PITCH, TREE_HEAD = 40, 64, 72
-- The tree shown, its search, and a commit under way (no changes until it ends).
local tree = { idx = 1, query = "", committing = false }
local treeNodes, treeLines, treeRows = {}, {}, {}

local num = ns.Num

local function configOf(t) return C_Traits.GetConfigIDByTreeID(t.id) end

-- The tree's points: { quantity (to spend), spent }.
local function currencyOf(config, t)
	local c = config and C_Traits.GetTreeCurrencyInfo(config, t.id, false)
	return c and c[1]
end

local cell = ns.GridCell

-- The tree's shown nodes, each with its column and row on that grid.
local function readTree(config, t)
	local list, xs, ys = {}, {}, {}
	for _, id in ipairs(config and C_Traits.GetTreeNodes(t.id) or {}) do
		local n = C_Traits.GetNodeInfo(config, id)
		if n and n.isVisible then
			list[#list + 1] = n
			xs[#xs + 1], ys[#ys + 1] = n.posX, n.posY
		end
	end
	local left, top = math.min(math.huge, unpack(xs)), math.min(math.huge, unpack(ys))
	local sx, sy = cell(xs), cell(ys)
	for _, n in ipairs(list) do
		n.col = math.floor((n.posX - left) / sx + 0.5)
		n.row = math.floor((n.posY - top) / sy + 0.5)
	end
	return list
end

-- The node's entry: the client's override name and icon, else its spell's.
local function entryOf(config, n)
	local entryID = n.activeEntry and n.activeEntry.entryID or (n.entryIDs and n.entryIDs[1])
	local entry = entryID and C_Traits.GetEntryInfo(config, entryID)
	local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID) or {}
	local icon = def.overrideIcon or (def.spellID and C_Spell.GetSpellTexture(def.spellID))
	local name = def.overrideName or (def.spellID and C_Spell.GetSpellName(def.spellID))
	return icon, name, def.spellID
end

-- The points on hand, by trait currency, for the tree being painted.
local treeOnHand = {}

-- Whether a talent can take a point now, as the stock button reckons it
-- (CanPurchaseRank): the client's canPurchaseRank says nothing of the cost,
-- so its prerequisites are met and its cost is on hand too (as Talents.lua's lit).
local function canTake(config, n)
	if not (n.canPurchaseRank and n.meetsEdgeRequirements) then return false end
	for _, c in ipairs(C_Traits.GetNodeCost(config, n.ID) or {}) do
		if (treeOnHand[c.ID] or 0) < num(c.amount) then return false end
	end
	return true
end

-- The stock talent tooltip's lines: name, rank, this and the next rank's text,
-- an unmet prerequisite; then what a click does now.
local function nodeTip(b)
	local n, tip = b.psInfo, GameTooltip
	tip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip_SetTitle(tip, b.psName or "")
	GameTooltip_AddHighlightLine(tip, TALENT_BUTTON_TOOLTIP_RANK_FORMAT:format(num(n.currentRank), num(n.maxRanks)))
	local cur = n.activeEntry or n.nextEntry
	if cur then
		GameTooltip_AddBlankLineToTooltip(tip)
		tip:AppendInfo("GetTraitEntry", cur.entryID, cur.rank)
	end
	if n.nextEntry and num(n.ranksPurchased) > 0 then
		GameTooltip_AddBlankLineToTooltip(tip)
		GameTooltip_AddHighlightLine(tip, TALENT_BUTTON_TOOLTIP_NEXT_RANK)
		tip:AppendInfo("GetTraitEntry", n.nextEntry.entryID, n.nextEntry.rank)
	end
	if not n.meetsEdgeRequirements then
		GameTooltip_AddBlankLineToTooltip(tip)
		GameTooltip_AddErrorLine(tip, GENERIC_TRAIT_FRAME_EDGE_REQUIREMENTS_BUTTON_TOOLTIP)
	end
	local hint = {}
	if not tree.committing then
		if canTake(b.psConfig, n) then hint[#hint + 1] = "Click to learn a rank." end
		if n.canRefundRank and num(n.ranksPurchased) > 0 then hint[#hint + 1] = "Right-click to take one back." end
	end
	if b.psSpell then hint[#hint + 1] = "Shift-click to link it in chat." end
	if #hint > 0 then ns.TooltipHint(table.concat(hint, " ")) end
	tip:Show()
end

-- Click spends a rank, right-click takes one back (TalentButtonSpendMixin),
-- staged on the config until Apply; redrawn at once (docs/CLIENT.md, rule 6).
local function nodeClick(b, button)
	if b.psSpell and IsModifiedClick("CHATLINK") then
		ChatFrameUtil.InsertLink(C_Spell.GetSpellLink(b.psSpell))
		return
	end
	local n = b.psInfo
	if not n or tree.committing then return end
	local op, sound
	if button == "RightButton" then
		if not (n.canRefundRank and num(n.ranksPurchased) > 0) then return end
		op, sound = C_Traits.RefundRank, SOUNDKIT.UI_CLASS_TALENT_NODE_REFUND
	else
		if not canTake(b.psConfig, n) then return end
		op, sound = C_Traits.PurchaseRank, SOUNDKIT.UI_CLASS_TALENT_NODE_SPEND
	end
	if not op(b.psConfig, n.ID) then
		UIErrorsFrame:AddExternalErrorMessage(GENERIC_TRAIT_FRAME_INTERNAL_ERROR or "That cannot be changed now.")
		return
	end
	PlaySound(sound)
	refresh()
	if GameTooltip:GetOwner() == b then nodeTip(b) end
end

local function newNode(parent)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(NODE, NODE)
	Theme.Skin(b, "inset")
	Theme.Border(b, Theme.Wash("border"))
	b.Icon = ns.GameIcon(b)
	b.Icon:SetPoint("TOPLEFT", 1, -1)
	b.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	W.Hover(b)
	-- Its ranks as the stock button shows them ("0/5"), on a solid chip over
	-- the bottom-right corner, its hairline in the node's state colour.
	b.Chip = CreateFrame("Frame", nil, b)
	b.Chip:SetSize(30, 16)
	b.Chip:SetPoint("CENTER", b, "BOTTOMRIGHT", -4, 2)
	b.Chip:SetFrameLevel(b:GetFrameLevel() + 3)
	local bg = b.Chip:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	W.Painter(bg, function(t) t:SetColorTexture(Theme.Color("bg")) end)
	b.Rank = W.Text(b.Chip, "number", "text")
	b.Rank:SetPoint("CENTER", 0, 0)
	b:SetScript("OnEnter", nodeTip)
	b:SetScript("OnLeave", W.HideTooltip)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:SetScript("OnClick", nodeClick)
	return b
end

-- A talent's look, as the stock button reckons it: maxed in the accent,
-- partly learnt in success, one that can take a point now in colour; the
-- rest greyed, dimmer while a prerequisite is missing. Searching, a talent
-- that does not match recedes. -> whether it matches.
local function paintNode(b, config, n)
	local icon, name, spell = entryOf(config, n)
	b.psInfo, b.psConfig, b.psName, b.psSpell = n, config, name, spell
	local rank, max = num(n.currentRank), num(n.maxRanks)
	local on = rank > 0 or canTake(config, n)
	b.Icon:SetTexture(icon or 134400)
	b.Icon:SetDesaturated(not on)
	b.Icon:SetAlpha(on and 1 or n.meetsEdgeRequirements and 0.75 or 0.4)
	local q = tree.query
	local function has(text)
		return type(text) == "string" and not (issecretvalue and issecretvalue(text)) and text:lower():find(q, 1, true)
	end
	local match = q == "" or has(name) or (spell and has(C_Spell.GetSpellDescription(spell))) or false
	b:SetAlpha(match and 1 or 0.25)
	b.Rank:SetText(("%d/%d"):format(rank, max))
	local state = rank >= max and "accent" or rank > 0 and "success" or nil
	W.Color(b.Rank, state or "text")
	if state then
		local r, g, bl = Theme.Color(state)
		Theme.Border(b, r, g, bl, 1)
		Theme.Border(b.Chip, r, g, bl, 1)
	else
		Theme.Border(b, Theme.Wash("border"))
		Theme.Border(b.Chip, Theme.Wash("border"))
	end
	return match
end

local function buildTreePage(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", W.SHELL.pad, 0)
	v:SetWidth(width)
	-- The tree's heading: its art in a well, its name, the points in it.
	v.Well = CreateFrame("Frame", nil, v)
	v.Well:SetSize(48, 48)
	v.Well:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -16)
	Theme.Skin(v.Well, "inset")
	Theme.Border(v.Well, Theme.Wash("border"))
	v.Art = v.Well:CreateTexture(nil, "ARTWORK")
	v.Art:SetPoint("TOPLEFT", 1, -1)
	v.Art:SetPoint("BOTTOMRIGHT", -1, 1)
	v.Name = W.Text(v, "heading", "text")
	v.Name:SetPoint("BOTTOMLEFT", v.Well, "RIGHT", 12, 2)
	v.Spent = W.Text(v, "small", "textDim")
	v.Spent:SetPoint("TOPLEFT", v.Well, "RIGHT", 12, -4)
	v.Grid = CreateFrame("Frame", nil, v)
	v.Grid:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(TREE_HEAD + 16))
	v.Grid:SetSize(1, 1)
	v.Empty = W.Text(v, "body", "textDim")
	v.Empty:SetPoint("TOPLEFT", v.Grid, "TOPLEFT", 0, 0)
	v.Empty:SetText("This tree is not open to you yet.")
	return v
end

-- The tree: its heading, then its talents on the client's grid, centred in
-- the page, with the client's edges between them (2px, the accent once met).
-- -> height, config, currency, talents matching the search.
local function paintTreePage(v)
	local t = TREES[tree.idx]
	local config = configOf(t)
	local c = currencyOf(config, t)
	treeOnHand = {}
	for _, cur in ipairs(config and C_Traits.GetTreeCurrencyInfo(config, t.id, false) or {}) do
		treeOnHand[cur.traitCurrencyID] = num(cur.quantity)
	end
	v.Art:SetAtlas(t.atlas)
	v.Name:SetText(t.name)
	local spent = c and num(c.spent) or 0
	v.Spent:SetText(spent == 1 and "1 point in this tree" or ("%d points in this tree"):format(spent))
	local list = readTree(config, t)
	local cols = 0
	for _, n in ipairs(list) do cols = math.max(cols, n.col) end
	local gx = math.max(0, (f.BodyWidth - (NODE + cols * PITCH)) / 2)
	local at, bottom, found = {}, 0, 0
	for i, n in ipairs(list) do
		local b = treeNodes[i] or newNode(v.Grid)
		treeNodes[i] = b
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", v.Grid, "TOPLEFT", gx + n.col * PITCH, -n.row * PITCH)
		b:SetFrameLevel(v.Grid:GetFrameLevel() + 2)
		if paintNode(b, config, n) and tree.query ~= "" then found = found + 1 end
		b:Show()
		at[n.ID] = b
		bottom = math.max(bottom, n.row * PITCH + NODE)
	end
	for i = #list + 1, #treeNodes do treeNodes[i]:Hide() end
	local li = 0
	for _, n in ipairs(list) do
		for _, e in ipairs(n.visibleEdges or {}) do
			local a, b = at[n.ID], at[e.targetNode]
			if a and b then
				li = li + 1
				local l = treeLines[li] or v.Grid:CreateLine(nil, "BORDER")
				treeLines[li] = l
				l:SetThickness(2)
				-- Edge to edge, so the line never crosses an icon: along a row
				-- from side to side, down a column from bottom to top.
				local from, to = "CENTER", "CENTER"
				local p, q = a.psInfo, b.psInfo
				if p.row == q.row then
					from, to = p.col < q.col and "RIGHT" or "LEFT", p.col < q.col and "LEFT" or "RIGHT"
				elseif p.col == q.col then
					from, to = p.row < q.row and "BOTTOM" or "TOP", p.row < q.row and "TOP" or "BOTTOM"
				end
				l:SetStartPoint(from, a)
				l:SetEndPoint(to, b)
				if e.isActive then l:SetColorTexture(Theme.Color("accent")) else l:SetColorTexture(Theme.Wash("border")) end
				l:Show()
			end
		end
	end
	for i = li + 1, #treeLines do treeLines[i]:Hide() end
	v.Empty:SetShown(#list == 0)
	local h = TREE_HEAD + 16 + math.max(bottom, 24)
	v:SetHeight(h)
	return h + 24, config, c, found
end

-- The trees in the sidebar under the search, each with its art and the
-- points spent in it; the open one marked.
local TREE_ROW = 44
local function treeRow(i)
	if treeRows[i] then return treeRows[i] end
	local r = CreateFrame("Button", nil, f.NavScroll.Child)
	r:SetHeight(TREE_ROW)
	W.Hover(r)
	r.Sel = r:CreateTexture(nil, "BACKGROUND")
	r.Sel:SetTexture("Interface/Buttons/WHITE8X8")
	r.Sel:SetAllPoints(r)
	W.Painter(r.Sel, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	r.Bar = W.Fill(r, "accent", "ARTWORK", 0)
	r.Bar:ClearAllPoints()
	r.Bar:SetPoint("TOPLEFT")
	r.Bar:SetPoint("BOTTOMLEFT")
	r.Bar:SetWidth(2)
	r.Art = r:CreateTexture(nil, "ARTWORK")
	r.Art:SetSize(28, 28)
	r.Art:SetPoint("LEFT", r, "LEFT", W.SHELL.side, 0)
	r.Count = W.Text(r, "number", "textMuted")
	r.Count:SetPoint("RIGHT", r, "RIGHT", -W.SHELL.side, 0)
	r.Label = W.Text(r, "body", "text")
	r.Label:SetPoint("LEFT", r.Art, "RIGHT", 12, 0)
	r.Label:SetJustifyH("LEFT")
	r:SetScript("OnClick", function(self)
		tree.idx = self.psIdx
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
		refresh()
	end)
	treeRows[i] = r
	return r
end

local function paintTreeNav()
	for i, t in ipairs(TREES) do
		local r = treeRow(i)
		r.psIdx = i
		local on = i == tree.idx
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", f.NavScroll.Child, "TOPLEFT", 0, -(i - 1) * TREE_ROW)
		r:SetPoint("TOPRIGHT", f.NavScroll.Child, "TOPRIGHT", 0, -(i - 1) * TREE_ROW)
		r.Art:SetAtlas(t.atlas)
		r.Label:SetText(t.name)
		W.Color(r.Label, on and "text" or "navRest")
		local c = currencyOf(configOf(t), t)
		r.Count:SetText(c and num(c.spent) > 0 and num(c.spent) or "")
		r.Sel:SetShown(on)
		r.Bar:SetShown(on)
		r:Show()
	end
	f.NavScroll.Child:SetWidth((f.psSidebar or W.SHELL.sidebar) - 1)
	W.SetScrollContent(f.NavScroll, #TREES * TREE_ROW, W.ShellNavHeight(f))
end

-- Apply commits the staged points (C_Traits.CommitConfig, as the stock
-- Apply): changes wait until TRAIT_CONFIG_UPDATED or CONFIG_COMMIT_FAILED, or
-- six seconds at most, as the stock frame's backup timer.
local function treeApply()
	local config = configOf(TREES[tree.idx])
	if not (config and C_Traits.ConfigHasStagedChanges(config)) or tree.committing then return end
	PlaySound(SOUNDKIT.UI_CLASS_TALENT_APPLY_CHANGES)
	if not C_Traits.CommitConfig(config) then
		UIErrorsFrame:AddExternalErrorMessage(GENERIC_TRAIT_FRAME_INTERNAL_ERROR or "That cannot be changed now.")
		return
	end
	tree.committing = true
	C_Timer.After(6, function()
		if tree.committing then
			tree.committing = false
			redraw()
		end
	end)
	refresh()
end

local function treeUndo()
	C_Traits.RollbackConfig(configOf(TREES[tree.idx]))
	refresh()
end

-- Reset takes every point out of the tree (C_Traits.ResetTree, staged like
-- the rest until Apply); its button asks for a second click first.
local function treeReset()
	local t = TREES[tree.idx]
	C_Traits.ResetTree(configOf(t), t.id)
	refresh()
end

local function build()
	-- One search box, for the page shown: the challenges, or the tree's talents.
	f = W.Shell(NAME, { scalePath = "ui.menuScale", rail = true, searchPlaceholder = "Search", onSearch = function(text)
		text = text or ""
		if section == "tree" then
			if tree.query == text:lower() then return end
			tree.query = text:lower()
		else
			if chal.query == text then return end
			chal.query = text
			-- The client searches every category and answers with ACHIEVEMENT_SEARCH_UPDATED.
			SetAchievementSearchString(chal.query)
		end
		redraw()
	end })
	ns.Dock(f)
	ns.WindowMenu(f, "legacy")
	-- The subject block names the window, in place of Polestar's lockup.
	local b = ns.SubjectBlock(f)
	-- The Legacy emblem heads the rail, where Polestar's stands in its own,
	-- centred on the title's line.
	f.psEmblem = f.Rail:CreateTexture(nil, "ARTWORK")
	f.psEmblem:SetSize(40, 40)
	f.psEmblem:SetPoint("CENTER", f.Rail, "TOP", 0, -47)
	f.psEmblem:SetAtlas("Legacy-up-c60")
	-- An atlas, not an icon: its own crop.
	f.psIcon = b.icon
	f.psIcon:SetTexCoord(0, 1, 0, 1)
	f.psIcon:SetAtlas("Legacy-up-c60")
	f.psName, f.psLine = b.name, b.line
	f.psName:SetText(LEGACY_BUTTON or "Legacy")
	-- The filter acts on the list: at the end of the search row, as the
	-- crafting window's.
	local top = W.SHELL.header - 30
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + 30 + 6), -top)
	f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", filterMenu, 14)
	f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -top)
	Theme.Skin(f.psFilter, "editbox")
	f.psPages = { track = buildTrack(f.Body, f.BodyWidth), challenges = buildChallenges(f.Body, f.BodyWidth), tree = buildTreePage(f.Body, f.BodyWidth) }
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
	Polestar.CloseOnEscape(NAME)
end

-- The sidebar (the search, and the categories or the trees) on Challenges
-- and the tree; the reward track takes its width. The main column hangs off the rail's edge
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
		b.psTip, b.psTipLines = d.tip or d.label, { d.about }
		-- A game icon, not a glyph: the rail's tint taken off, its border cropped.
		W.Uncolor(b.Icon)
		b.Icon:SetVertexColor(1, 1, 1, 1)
		b.Icon:SetTexture(d.icon)
		b.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		b.Icon:SetSize(24, 24)
	end
end

-- The status line of the track and the challenges: "3 of 65 legacy points earned".
local function earned(pts)
	return ("%d of %d legacy points earned"):format(pts, C_Traits.GetMaxAvailableTraitCurrency(POINTS, false) or 0)
end

function refresh()
	local pts = points()
	f.psLine:SetText(("%d Legacy %s"):format(pts, pts == 1 and "Point" or "Points"))
	local onChallenges, onTree = section == "challenges", section == "tree"
	paintRail()
	sidebar(onChallenges or onTree)
	-- The search row: the filter on Challenges only; each page keeps its own search.
	local top = W.SHELL.header - 30
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + (onChallenges and 30 + 6 or 0)), -top)
	f.psFilter:SetShown(onChallenges)
	local want = onTree and tree.query or chal.query
	if (f.Search:GetText() or ""):lower() ~= want:lower() then f.Search:SetText(want) end
	for _, r in ipairs(heads) do if not onChallenges then r:Hide() end end
	for _, r in ipairs(cats) do if not onChallenges then r:Hide() end end
	for _, r in ipairs(treeRows) do r:SetShown(onTree) end
	local foot = {}
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
		W.ShellTitle(f, chal.cat and GetCategoryInfo(chal.cat) or "Challenges", earned(pts))
		W.ShellTabs(f, nil)
		-- The glyph in the accent while a filter hides challenges.
		W.SetIconState(f.psFilter, not (chal.showDone and chal.showTodo))
		h = paintChallenges(f.psPages.challenges, chal.cat and challenges(chal.cat, found) or {})
	else
		W.ShellTabs(f, nil)
		if section == "track" then
			W.ShellTitle(f, "Reward Track", earned(pts))
			h = paintTrack(f.psPages.track)
		else
			paintTreeNav()
			local found, config, c
			h, config, c, found = paintTreePage(f.psPages.tree)
			local left = c and num(c.quantity) or 0
			local staged = config and not tree.committing and C_Traits.ConfigHasStagedChanges(config)
			local sub
			if tree.query ~= "" then
				sub = found == 1 and "1 talent matches." or ("%d talents match."):format(found)
			elseif tree.committing then
				sub = "Applying your changes…"
			else
				sub = left == 0 and "No legacy points to spend." or left == 1 and "1 legacy point to spend."
					or ("%d legacy points to spend."):format(left)
				if staged then sub = sub .. " Your changes are not applied yet." end
			end
			W.ShellTitle(f, "Legacy Tree", sub)
			-- Apply, then Undo while something is staged, else Reset (the stock pair).
			local any = false
			for _, b in ipairs(treeNodes) do if b:IsShown() and num(b.psInfo.ranksPurchased) > 0 then any = true end end
			foot = { { label = "Apply", onClick = treeApply, opts = { primary = true }, on = staged },
				staged and { label = "Undo", onClick = treeUndo, on = true }
				or { label = "Reset", onClick = treeReset, opts = { confirm = true }, on = any and not tree.committing } }
		end
	end
	W.ShellFooter(f, {}, foot)
	-- Disabled as Polestar disables (faded to 45%), so the layout never moves.
	for i, d in ipairs(foot) do
		local b = f.footerButtons.right[i]
		ns.SetEnabled(b, d.on)
	end
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
	ns.Doors("legacy", "Legacy", {
		TOGGLELEGACYSYSTEM = function() M.Toggle() end,
		TOGGLEACHIEVEMENT = function() M.Toggle("challenges") end,
	}, LegacyMicroButton, function() M.Toggle() end)
	Polestar.RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", redraw)
	Polestar.RegisterEvent("UPDATE_FACTION", redraw)
	Polestar.RegisterEvent("PLAYER_ENTERING_WORLD", function() chal.stale = true; redraw() end)
	for _, e in ipairs({ "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "ACHIEVEMENT_SEARCH_UPDATED", "CONTENT_TRACKING_UPDATE",
		"TRAIT_NODE_CHANGED", "TRAIT_TREE_CURRENCY_INFO_UPDATED" }) do
		Polestar.RegisterEvent(e, redraw)
	end
	-- A commit ends (applied or refused): the tree is open to changes again.
	local function committed()
		tree.committing = false
		redraw()
	end
	Polestar.RegisterEvent("TRAIT_CONFIG_UPDATED", committed)
	Polestar.RegisterEvent("CONFIG_COMMIT_FAILED", committed)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return LegacySystemFrame end

ns.Module("legacy", M)
