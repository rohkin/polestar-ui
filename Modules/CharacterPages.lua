-- The Character window's other sections (docs/DESIGN.md, "Character"):
-- Reputation, Currency, Honor, Skills and Statistics. Each page is
--   ns.CharacterPages[stock subframe] = { build = fn(body, width) -> frame, paint = fn(frame) -> height }
-- and is painted only out of combat (docs/CLIENT.md, rule 3): in combat a page
-- keeps what it last drew, and Character.lua reads it again once combat ends.

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local pages = {}
ns.CharacterPages = pages

local HEAD_H, GAP, ROW_H, BAR_ROW_H = 44, 22, 28, 40

local function hideTip() GameTooltip:Hide() end

-- Folds or unfolds a group through the client, then redraws at once: the
-- currency list sends no event when it folds.
local function fold(fn)
	fn()
	if ns.RefreshCharacter then ns.RefreshCharacter() end
end

-- A row chosen for the drawer's details: the drawer opens to show them, as
-- the stock right pane does (SetRightPaneCollapsed(false)).
local function choose(fn)
	fn()
	if PolestarUIDB then PolestarUIDB.hideStats = nil end
	if ns.RefreshCharacter then ns.RefreshCharacter() end
end
ns.CharacterChoose = choose

-- The selection wash behind a row (hidden until chosen).
local function selWash(r)
	r.Sel = W.Painter(W.Tex(r, "BACKGROUND"), function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	r.Sel:SetAllPoints(r)
	r.Sel:Hide()
end

---------------------------------------------------------------------------
-- A grouped list: a heading per group (its chevron in the gutter folds it),
-- over a row panel. groups = { { name, collapsed, toggle = fn, rows = { data, ... } } };
-- spec = { height, new = fn(row), draw = fn(row, data), plain }; plain: the
-- rows sit on the page, with no panel or hairlines around them.

local function listView(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", 32, 0)
	v:SetWidth(width)
	v.groups = {}
	return v
end

local function group(v, i, spec)
	local g = v.groups[i]
	if g then return g end
	g = { Head = W.SectionHeader(v), Panel = spec.plain and CreateFrame("Frame", nil, v) or W.RowPanel(v), rows = {} }
	g.Head:SetPoint("RIGHT", v, "RIGHT", 0, 0)
	g.Panel:SetPoint("RIGHT", v, "RIGHT", 0, 0)
	g.Chevron = W.Tex(g.Head, "ARTWORK", "chevron-down", "textDim")
	g.Chevron:SetSize(12, 12)
	g.Chevron:SetPoint("RIGHT", g.Head.Text, "LEFT", -6, 0)
	-- The click area spans the chevron in the gutter and the heading.
	g.Hit = CreateFrame("Button", nil, g.Head)
	g.Hit:SetPoint("TOPLEFT", g.Head, "TOPLEFT", -24, 0)
	g.Hit:SetPoint("BOTTOMRIGHT", g.Head, "BOTTOMRIGHT", 0, 0)
	g.Hit:SetScript("OnClick", function() if g.toggle then fold(g.toggle) end end)
	g.Hit:SetScript("OnEnter", function() W.Color(g.Chevron, "text") end)
	g.Hit:SetScript("OnLeave", function() W.Color(g.Chevron, "textDim") end)
	v.groups[i] = g
	return g
end

local function row(g, i, spec)
	local r = g.rows[i]
	if r then return r end
	r = CreateFrame("Button", nil, g.Panel)
	r:SetHeight(spec.height)
	r:SetPoint("TOPLEFT", g.Panel, "TOPLEFT", 0, -(i - 1) * spec.height)
	r:SetPoint("RIGHT", g.Panel, "RIGHT", 0, 0)
	if i > 1 and not spec.plain then
		local d = W.Divider(r)
		d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
		d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
	end
	W.Hover(r)
	r:SetScript("OnLeave", hideTip)
	spec.new(r)
	g.rows[i] = r
	return r
end

local function paintList(v, groups, spec)
	local y = 0
	for i, data in ipairs(groups) do
		local g = group(v, i, spec)
		g.toggle = data.toggle
		W.SetSection(g.Head, data.name)
		g.Chevron:SetTexture(Theme.Media(data.collapsed and "chevron-right" or "chevron-down"))
		g.Head:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -y)
		g.Head:Show()
		local n = data.collapsed and 0 or #data.rows
		for k = 1, n do
			local r = row(g, k, spec)
			r.psBarW = v:GetWidth() - 28 -- the bar spans the row inside its 16 and 12 insets
			spec.draw(r, data.rows[k])
			r:Show()
		end
		for k = n + 1, #g.rows do g.rows[k]:Hide() end
		g.Panel:SetShown(n > 0)
		g.Panel:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(y + HEAD_H))
		g.Panel:SetHeight(math.max(1, n * spec.height))
		y = y + HEAD_H + n * spec.height + (n > 0 and GAP or 0)
	end
	for i = #groups + 1, #v.groups do
		v.groups[i].Head:Hide()
		v.groups[i].Panel:Hide()
	end
	v:SetHeight(y)
	return y
end

-- A row with a name on the left, a value on the right and, for bar rows, a
-- 2px bar under them (docs/DESIGN.md, "Skill Bar").
local function newBarRow(r)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("TOPLEFT", r, "TOPLEFT", 16, -8)
	r.Value = W.Text(r, "small", "textDim")
	r.Value:SetPoint("TOPRIGHT", r, "TOPRIGHT", -12, -9)
	-- A long name ends in an ellipsis short of the value.
	r.Name:SetPoint("RIGHT", r.Value, "LEFT", -12, 0)
	r.Bar = W.ProgressLine(r, 2)
	r.Bar:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 16, 8)
	r.Bar:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -12, 8)
	r.Mark = W.Fill(r, "accent", "ARTWORK", 0)
	r.Mark:ClearAllPoints()
	r.Mark:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
	r.Mark:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
	r.Mark:SetWidth(2)
	selWash(r)
end

local function setBar(r, frac, red, green, blue)
	W.SetProgress(r.Bar, math.max(0, math.min(1, frac)), r.psBarW)
	W.Uncolor(r.Bar.Fill)
	if red then r.Bar.Fill:SetVertexColor(red, green, blue, 1) else W.Color(r.Bar.Fill, "accent") end
end

local function pageOf(paintFn)
	return { build = listView, paint = paintFn }
end

-- "1 skill", "3 skills".
local function count(n, one, many) return n == 1 and "1 " .. one or n .. " " .. many end

---------------------------------------------------------------------------
-- Reputation: groups are the top headers; a sub-header (isChild) is a row,
-- its factions indented under it. A click chooses a faction for the drawer's
-- details (CharacterDetails.lua: at war, inactive, watched), or folds a
-- sub-header; the watched one carries the accent bar.

local function standingColor(reaction)
	local c = FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
	if not c then return nil end
	return Theme.Legible(c.r, c.g, c.b)
end

local function repEnter(r)
	local d = r.psData
	if not d or d.isHeader and not d.isHeaderWithRep then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(d.name)
	if d.description and d.description ~= "" then GameTooltip:AddLine(d.description, 1, 1, 1, true) end
	local span = d.nextReactionThreshold - d.currentReactionThreshold
	if span > 0 then
		GameTooltip:AddLine(("%s / %s"):format(BreakUpLargeNumbers(d.currentStanding - d.currentReactionThreshold), BreakUpLargeNumbers(span)), 1, 1, 1)
	end
	if d.isWatched then GameTooltip:AddLine("Shown on your experience bar.", 1, 1, 1) end
	-- What a click does, for players new to it: a sub-header folds instead.
	if not d.isHeader then ns.TooltipHint("Click for its details: at war, inactive, experience bar.") end
	GameTooltip:Show()
end

local function repClick(r)
	local d = r.psData
	if not d then return end
	if d.isHeader then
		fold(function()
			if d.isCollapsed then C_Reputation.ExpandFactionHeader(d.index) else C_Reputation.CollapseFactionHeader(d.index) end
		end)
	else
		choose(function() C_Reputation.SetSelectedFaction(d.index) end)
	end
end

local repSpec = {
	height = BAR_ROW_H,
	new = function(r)
		newBarRow(r)
		r.Chevron = W.Tex(r, "ARTWORK", "chevron-down", "textDim")
		r.Chevron:SetSize(12, 12)
		r.Chevron:SetPoint("RIGHT", r.Name, "LEFT", -6, 0)
		r:SetScript("OnEnter", repEnter)
		r:SetScript("OnClick", repClick)
	end,
	draw = function(r, d)
		r.psData = d
		r.Name:SetPoint("TOPLEFT", r, "TOPLEFT", d.indent and 34 or 16, -8)
		r.Name:SetText(d.name)
		-- At war: the name in danger, as the stock row's red highlight.
		W.Color(r.Name, d.isHeader and "textDim" or d.atWarWith and "danger" or "text")
		r.Chevron:SetShown(d.isHeader)
		r.Chevron:SetTexture(Theme.Media(d.isCollapsed and "chevron-right" or "chevron-down"))
		r.Mark:SetShown(d.isWatched)
		r.Sel:SetShown(not d.isHeader and d.index == C_Reputation.GetSelectedFaction())
		local rep = not d.isHeader or d.isHeaderWithRep
		r.Value:SetShown(rep)
		r.Bar:SetShown(rep)
		if rep then
			local cr, cg, cb = standingColor(d.reaction)
			r.Value:SetText(GetText("FACTION_STANDING_LABEL" .. d.reaction, UnitSex("player")))
			W.Uncolor(r.Value)
			if cr then r.Value:SetTextColor(cr, cg, cb, 1) else W.Color(r.Value, "textDim") end
			local span = d.nextReactionThreshold - d.currentReactionThreshold
			setBar(r, span > 0 and (d.currentStanding - d.currentReactionThreshold) / span or 1, cr, cg, cb)
		end
	end,
}

-- The faction the details show: the client's choice, else the first that can
-- be chosen (the stock SelectFirstFactionIfNoneSelected).
local function selectFirstFaction()
	local sel = C_Reputation.GetSelectedFaction()
	local d = sel and sel > 0 and C_Reputation.GetFactionDataByIndex(sel)
	if d and not (d.isHeader and not d.isChild) then return end
	for i = 1, C_Reputation.GetNumFactions() do
		d = C_Reputation.GetFactionDataByIndex(i)
		if d and not d.isHeader then return C_Reputation.SetSelectedFaction(i) end
	end
end

pages.ReputationFrame = pageOf(function(v)
	selectFirstFaction()
	local groups, cur, n, watched = {}, nil, 0, nil
	for i = 1, C_Reputation.GetNumFactions() do
		local d = C_Reputation.GetFactionDataByIndex(i)
		if d then
			d.index = i
			if not d.isHeader or d.isHeaderWithRep then n = n + 1 end
			if d.isWatched then watched = d.name end
			if d.isHeader and not d.isChild then
				local idx = i
				cur = { name = d.name, collapsed = d.isCollapsed, rows = {}, toggle = function()
					if d.isCollapsed then C_Reputation.ExpandFactionHeader(idx) else C_Reputation.CollapseFactionHeader(idx) end
				end }
				groups[#groups + 1] = cur
			else
				if not cur then
					cur = { name = REPUTATION or "Reputation", rows = {} }
					groups[#groups + 1] = cur
				end
				d.indent = d.isChild and not d.isHeader
				cur.rows[#cur.rows + 1] = d
			end
		end
	end
	v.psSub = watched and "Watching " .. watched or count(n, "faction", "factions")
	return paintList(v, groups, repSpec)
end)

---------------------------------------------------------------------------
-- Currency: the client's currency list, its headers as groups (the client
-- keeps the unused ones in its Unused group). A click chooses one for the
-- drawer's details; shift-click links it while typing in chat, else shows it
-- on the backpack (or stops), as the stock list does.

local currencySel -- the chosen currency's name (its index moves as groups fold)
function ns.CharacterCurrency()
	for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
		local d = C_CurrencyInfo.GetCurrencyListInfo(i)
		if d and not d.isHeader and d.name == currencySel then return i, d end
	end
end

local function currencyClick(self)
	local i, d = self.psIndex, self.psData
	if IsModifiedClick("CHATLINK") and HandleModifiedItemClick(C_CurrencyInfo.GetCurrencyListLink(i)) then return end
	if IsModifiedClick("TOKENWATCHTOGGLE") then
		-- shortcut: no cap on watched currencies (the stock one reads the backpack's width); add one if the backpack overflows.
		C_CurrencyInfo.SetCurrencyBackpack(i, not d.isShowInBackpack)
		return fold(function() end)
	end
	choose(function() currencySel = d.name end)
end

local currencySpec = {
	height = ROW_H,
	new = function(r)
		-- The icon inset 1px in a hairline well, as a gear slot tile.
		r.IconFrame, r.Icon = ns.ItemWell(r, 18)
		r.IconFrame:SetPoint("LEFT", r, "LEFT", 15, 0)
		r.Name = W.Text(r, "label", "text")
		r.Name:SetPoint("LEFT", r.IconFrame, "RIGHT", 7, 0)
		r.Value = W.Text(r, "number", "text")
		r.Value:SetPoint("RIGHT", r, "RIGHT", -12, 0)
		r.Name:SetPoint("RIGHT", r.Value, "LEFT", -12, 0)
		selWash(r)
		r:SetScript("OnClick", currencyClick)
		r:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetCurrencyToken(self.psIndex)
			ns.TooltipHint("Click for its details. Shift-click to show it on your backpack, or to link it while you type in chat.")
			GameTooltip:Show()
		end)
	end,
	draw = function(r, d)
		r.psIndex, r.psData = d.index, d
		r.Sel:SetShown(d.name == currencySel)
		r.Icon:SetTexture(d.iconFileID)
		r.Name:SetText(d.name)
		local q = BreakUpLargeNumbers(d.quantity)
		if d.maxQuantity and d.maxQuantity > 0 then q = q .. " / " .. BreakUpLargeNumbers(d.maxQuantity) end
		r.Value:SetText(q)
	end,
}

pages.TokenFrame = pageOf(function(v)
	-- The first currency is chosen when none is (SelectFirstCurrencyIfNoneSelected).
	if not ns.CharacterCurrency() then
		currencySel = nil
		for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
			local d = C_CurrencyInfo.GetCurrencyListInfo(i)
			if d and not d.isHeader then currencySel = d.name break end
		end
	end
	local groups, cur, n = {}, nil, 0
	for i = 1, C_CurrencyInfo.GetCurrencyListSize() do
		local d = C_CurrencyInfo.GetCurrencyListInfo(i)
		if d then
			d.index = i
			if not d.isHeader then n = n + 1 end
			if d.isHeader then
				local idx, expanded = i, d.isHeaderExpanded
				cur = { name = d.name, collapsed = not expanded, rows = {}, toggle = function()
					C_CurrencyInfo.ExpandCurrencyList(idx, not expanded)
				end }
				groups[#groups + 1] = cur
			elseif cur then
				cur.rows[#cur.rows + 1] = d
			end
		end
	end
	v.psSub = count(n, "currency", "currencies")
	return paintList(v, groups, currencySpec)
end)

---------------------------------------------------------------------------
-- Skills: the client's skill lines (as the stock page filters them: no class
-- skills, no sub-lines), headers as groups, each skill with its bar.

local CLASS_SKILLS = 7 -- the stock page's HIDDEN_SKILL_LINE_CATEGORIES

local DEFENSE_SKILL = 95

local skillSpec = {
	height = BAR_ROW_H,
	new = function(r)
		newBarRow(r)
		r.Mark:Hide()
		-- A click chooses it for the drawer's details (its weapon odds too).
		r:SetScript("OnClick", function(self) choose(function() C_SkillInfo.SetSelectedSkill(self.psData.index) end) end)
		r:SetScript("OnEnter", function(self)
			local d = self.psData
			if not d then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(d.name)
			if d.description and d.description ~= "" then GameTooltip:AddLine(d.description, 1, 1, 1, true) end
			ns.TooltipHint("Click for its details.")
			GameTooltip:Show()
		end)
	end,
	draw = function(r, d)
		r.psData = d
		r.Sel:SetShown(d.index == C_SkillInfo.GetSelectedSkill())
		r.Name:SetText(d.name)
		local text = ("%d/%d"):format(d.rank, d.maxRank)
		if d.modifier and d.modifier ~= 0 then text = ("%s (%+d)"):format(text, d.modifier) end
		r.Value:SetText(text)
		setBar(r, d.maxRank > 0 and d.rank / d.maxRank or 0)
	end,
}

pages.SkillsFrame = pageOf(function(v)
	local groups, cur, n, first = {}, nil, 0, nil
	for i = 1, C_SkillInfo.GetNumSkillLines() do
		local d = C_SkillInfo.GetSkillLineInfo(i)
		if d then
			d.index = i
			-- Defense counts its gear bonus, as the stock page reads it.
			if d.skillID == DEFENSE_SKILL and UnitDefenseSkill then d.modifier = select(2, UnitDefenseSkill("player")) end
		end
		if d and d.parentSkillLineID == 0 then
			if d.isHeader then
				if d.skillID == CLASS_SKILLS then
					cur = nil
				else
					local idx = i
					cur = { name = d.name, collapsed = d.isCollapsed, rows = {}, toggle = function()
						if d.isCollapsed then C_SkillInfo.ExpandSkillHeader(idx) else C_SkillInfo.CollapseSkillHeader(idx) end
					end }
					groups[#groups + 1] = cur
				end
			elseif cur and d.skillLineCategoryID ~= CLASS_SKILLS then
				cur.rows[#cur.rows + 1] = d
				n = n + 1
				first = first or i
			end
		end
	end
	-- The first skill is chosen when none is (SelectFirstSkillIfNoneSelected).
	local sel = C_SkillInfo.GetSelectedSkill()
	local sd = sel and sel > 0 and C_SkillInfo.GetSkillLineInfo(sel)
	if (not sd or sd.isHeader) and first then C_SkillInfo.SetSelectedSkill(first) end
	v.psSub = count(n, "skill", "skills")
	return paintList(v, groups, skillSpec)
end)

---------------------------------------------------------------------------
-- Statistics: the client's statistic categories (as the stock StatisticsFrame
-- reads them), a group per top category; a sub-category is a row with its own
-- chevron, its statistics indented under it. The client keeps no fold state
-- for these, so the folds are ours, and every category starts folded: there
-- are hundreds of statistics.
-- shortcut: folds last the session; keep them in PolestarUICharDB if players ask.

local statOpen = {}

-- As the stock page: "--" for none; a number with its thousands marks; any
-- other text (money) as the client gives it.
local function statValue(quantity)
	local n = tonumber(quantity)
	if n then return n > 0 and BreakUpLargeNumbers(n) or "--" end
	return (quantity and quantity ~= "") and quantity or "--"
end

local statSpec = {
	height = ROW_H,
	plain = true,
	new = function(r)
		r.Value = W.Text(r, "number", "text")
		r.Value:SetPoint("RIGHT", r, "RIGHT", -12, 0)
		r.Name = W.Text(r, "label", "text")
		r.Name:SetPoint("RIGHT", r.Value, "LEFT", -12, 0)
		r.Chevron = W.Tex(r, "ARTWORK", "chevron-down", "textDim")
		r.Chevron:SetSize(12, 12)
		r.Chevron:SetPoint("RIGHT", r.Name, "LEFT", -6, 0)
		r:SetScript("OnClick", function(self)
			local d = self.psData
			if d and d.toggle then fold(d.toggle) end
		end)
		-- The whole name when the row cuts it, as the stock page does.
		r:SetScript("OnEnter", function(self)
			if not (self.Name.IsTruncated and self.Name:IsTruncated()) then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.Name:GetText())
			GameTooltip:Show()
		end)
	end,
	draw = function(r, d)
		r.psData = d
		r.Name:SetPoint("LEFT", r, "LEFT", d.indent and 34 or 16, 0)
		r.Name:SetText(d.name)
		W.Color(r.Name, d.toggle and "textDim" or "text")
		r.Chevron:SetShown(d.toggle ~= nil)
		r.Chevron:SetTexture(Theme.Media(d.collapsed and "chevron-right" or "chevron-down"))
		r.Value:SetText(d.value or "")
	end,
}

local function statToggle(id) return function() statOpen[id] = not statOpen[id] end end

-- A category's statistics, as rows.
local function statRows(id, rows, indent)
	for i = 1, GetCategoryNumAchievements(id) do
		local quantity, skip, statID = GetStatistic(id, i)
		if not skip and statID then
			rows[#rows + 1] = { name = select(2, GetAchievementInfo(statID)) or UNKNOWN, value = statValue(quantity), indent = indent }
		end
	end
end

pages.StatisticsFrame = pageOf(function(v)
	-- The list's numeric keys in order, as the stock page walks it.
	local list, keys = GetStatisticsCategoryList() or {}, {}
	for k, id in pairs(list) do if type(k) == "number" and id then keys[#keys + 1] = k end end
	table.sort(keys)
	local roots, kids = {}, {}
	for _, k in ipairs(keys) do
		local id = list[k]
		local _, parent = GetCategoryInfo(id)
		if parent == -1 then
			roots[#roots + 1] = id
		else
			kids[parent] = kids[parent] or {}
			table.insert(kids[parent], id)
		end
	end
	local groups = {}
	for _, root in ipairs(roots) do
		local g = { name = GetCategoryInfo(root), collapsed = not statOpen[root], toggle = statToggle(root), rows = {} }
		if statOpen[root] then
			statRows(root, g.rows, false)
			-- Deeper categories join their top one's group as sub-categories.
			local function sub(parent)
				for _, id in ipairs(kids[parent] or {}) do
					g.rows[#g.rows + 1] = { name = GetCategoryInfo(id), collapsed = not statOpen[id], toggle = statToggle(id) }
					if statOpen[id] then
						statRows(id, g.rows, true)
						sub(id)
					end
				end
			end
			sub(root)
		end
		groups[#groups + 1] = g
	end
	v.psSub = count(#roots, "category", "categories")
	return paintList(v, groups, statSpec)
end)

---------------------------------------------------------------------------
-- Honor: Forever's PvP rank, kept as the major faction 2800 (as the stock
-- PVPRankFrame reads it): the rank and its title, the points to the next.

local PVP_RANK_FACTION = 2800
ns.PVP_RANK_FACTION = PVP_RANK_FACTION

local function rankTitle(rank)
	if not rank or rank <= 0 then return PVP_RANK_0_NAME or "Unranked" end
	local alliance = UnitFactionGroup("player") == "Alliance" and 1 or 0
	return GetText("PVP_RANK_" .. (Enum.PvPRanks.Rank_1 + rank - 1) .. "_" .. alliance, UnitSex("player"))
end
ns.PvPRankTitle = rankTitle

-- "Season ends in 12 days" (SEASON_ENDS_IN_TIME), the two largest units as
-- the stock countdown; nil when the client knows no end.
local function seasonEnds()
	local left = C_SeasonInfo and C_SeasonInfo.GetTimeUntilCurrentPVPSeasonEnd and C_SeasonInfo.GetTimeUntilCurrentPVPSeasonEnd() or 0
	if left <= 0 then return end
	local d, h, m = math.floor(left / 86400), math.floor(left / 3600) % 24, math.floor(left / 60) % 60
	local parts = {}
	local function add(n, one, many) if n > 0 and #parts < 2 then parts[#parts + 1] = n .. " " .. (n == 1 and one or many) end end
	add(d, "day", "days")
	add(h, "hour", "hours")
	if d == 0 then add(m, "minute", "minutes") end
	if d == 0 and h == 0 and m == 0 then parts[1] = math.floor(left) .. " seconds" end
	return (SEASON_ENDS_IN_TIME or "Season ends in %s"):format(table.concat(parts, " "))
end

pages.PVPRankFrame = {
	build = function(body, width)
		local v = CreateFrame("Frame", nil, body)
		v:SetPoint("TOPLEFT", body, "TOPLEFT", 32, -24)
		v:SetWidth(width)
		v.Rank = W.Text(v, "display", "text")
		v.Rank:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
		-- The season's countdown, kept to the second while shown.
		v.Season = W.Text(v, "small", "textDim")
		v.Season:SetPoint("TOPLEFT", v.Rank, "BOTTOMLEFT", 0, -6)
		local wait = 0
		v:SetScript("OnUpdate", function(self, dt)
			wait = wait - dt
			if wait > 0 then return end
			wait = 1
			self.Season:SetText(seasonEnds() or "")
		end)
		v.Points = W.Text(v, "number", "textDim")
		v.Points:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -50)
		v.Bar = W.ProgressLine(v, 3)
		v.Bar:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -68)
		v.Bar:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -68)
		v.Empty = W.Text(v, "note", "textDim")
		v.Empty:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
		return v
	end,
	paint = function(v)
		local info = C_MajorFactions and C_MajorFactions.GetMajorFactionProgressionInfo(PVP_RANK_FACTION)
		for _, r in ipairs({ v.Rank, v.Season, v.Points, v.Bar }) do r:SetShown(info ~= nil) end
		v.Empty:SetShown(not info)
		if not info then
			v.Empty:SetText(PVP_RANK_DETAIL_UNAVAILABLE or "No PvP rank this season.")
			v.psSub = nil
			v:SetHeight(40)
			return 64
		end
		local rank = info.renownLevel or 0
		v.Rank:SetText(rank > 0 and ("%s · %s"):format(rankTitle(rank), (PVP_RANK_NUMBER or "Rank %d"):format(rank)) or rankTitle(rank))
		local season = GetCurrentArenaSeason and GetCurrentArenaSeason() or 0
		v.psSub = season > 0 and (EXPANSION_SEASON_NAME or "%sSeason %d"):format("", season) or nil
		v.Season:SetText(seasonEnds() or "")
		local earned, need = info.renownReputationEarned or 0, info.renownLevelThreshold or 0
		local points = PVP_RANK_CURRENT_PROGRESS and PVP_RANK_CURRENT_PROGRESS:format(earned, need)
			or ("%s / %s"):format(BreakUpLargeNumbers(earned), BreakUpLargeNumbers(need))
		v.Points:SetText(need > 0 and points or "")
		W.SetProgress(v.Bar, need > 0 and math.min(1, earned / need) or 1, v:GetWidth())
		v:SetHeight(72)
		return 96
	end,
}
