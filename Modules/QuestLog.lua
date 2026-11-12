-- The quest log (docs/DESIGN.md, "World Map and Quest Log"): the flyout on
-- the right of our World Map, listing the log as the stock panel
-- (QuestMapFrame's QuestLogQuests_Update) lists it: foldable headers, each
-- quest with its level, its title in its difficulty colour and what is left
-- of it (each as the map's filters say); a click opens its details in the
-- list's place.
-- ns.QuestLog(window, canvas, width) -> the panel; panel.Paint().

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local HEAD_H, HEAD, TOP, SLOT = 28, 44, 44 + 30 + 12, 14

function ns.QuestLog(win, canvas, width)
	local p = CreateFrame("Frame", nil, win.Main)
	p:SetWidth(width)
	Theme.Skin(p, "sidebar")
	local rule = W.Divider(p, true)
	rule:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
	rule:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 0)
	p.Title = W.Text(p, "label", "textDim")
	p.Title:SetPoint("LEFT", p, "TOPLEFT", W.SHELL.side, -HEAD / 2)
	p.Title:SetText("Quests")
	p.Count = W.Text(p, "number", "textMuted")
	p.Count:SetPoint("RIGHT", p, "TOPRIGHT", -W.SHELL.side, -HEAD / 2)
	-- The search, as the stock log's: a quest's title or what is left of it.
	local query = ""
	p.Search = W.SearchBox(p, "Search quests", function(text)
		query = (text or ""):lower()
		p.Paint()
	end)
	p.Search:SetPoint("TOPLEFT", p, "TOPLEFT", W.SHELL.side, -HEAD)
	p.Search:SetPoint("TOPRIGHT", p, "TOPRIGHT", -(W.SHELL.side + 30 + 6), -HEAD)
	-- The stock map's filter menu (WorldMapTrackingOptionsButtonMixin:SetupMenu,
	-- the filters Forever's table holds), then the log's own as the stock menu
	-- adds it when the two are one. The same CVars and tracking filter, so a
	-- change shows in both maps; under the stock tag, so other addons' entries
	-- (Menu.ModifyMenu) join ours. Each change redraws at once (rule 6). The
	-- log's button and the map's open the same menu (p.FilterMenu).
	local TRIVIAL = Enum.MinimapTrackingFilter and Enum.MinimapTrackingFilter.TrivialQuests
	local function cvar(text, name, tip)
		return { text = text, tip = tip, get = function() return GetCVarBool(name) end,
			set = function(on) SetCVar(name, on and "1" or "0") end,
			default = function() return GetCVarDefault(name) == "1" end }
	end
	local WQ = cvar(SHOW_WORLD_QUESTS_ON_MAP_TEXT, "questPOIWQ", WORLD_QUESTS_FILTER_DESCRIPTION)
	local WQ_KINDS = { cvar(SHOW_PRIMARY_PROFESSION_ON_MAP_TEXT, "primaryProfessionsFilter"), cvar(SHOW_SECONDARY_PROFESSION_ON_MAP_TEXT, "secondaryProfessionsFilter") }
	local FILTERS = {
		cvar(SHOW_QUEST_OBJECTIVES_ON_MAP_TEXT, "questPOI", QUEST_OBJECTIVES_FILTER_DESCRIPTION),
		cvar(SHOW_QUEST_LEVELS, "showQuestLevel", QUEST_LEVEL_FILTER_DESCRIPTION),
		cvar(MAP_QUEST_DIFFICULTY_TEXT, "showQuestDifficultyColor", QUEST_DIFFICULTY_FILTER_DESCRIPTION),
		-- Straight to the tracking filter: the Settings proxy the stock menu
		-- writes through only reads it back, and stays untouched by our code.
		{ text = MINIMAP_TRACKING_TRIVIAL_QUESTS, tip = TRIVIAL_QUESTS_FILTER_DESCRIPTION,
			get = function() return not C_Minimap.IsFilteredOut(TRIVIAL) end,
			set = function(on)
				local i = MinimapUtil.GetFilterIndexForFilterID(TRIVIAL)
				if i then C_Minimap.SetTracking(i, on) end
			end,
			default = function() return C_Minimap.GetDefaultTrackingValue(TRIVIAL) and true or false end },
		cvar(CONTENT_TRACKING_MAP_TOGGLE, "contentTrackingFilter", TRACKED_ITEMS_FILTER_DESCRIPTION),
	}
	local LOG_OBJECTIVES = cvar(QUEST_LOG_SHOW_OBJECTIVES, "showQuestObjectivesInLog")
	local ALL = { WQ, WQ_KINDS[1], WQ_KINDS[2], LOG_OBJECTIVES }
	for _, x in ipairs(FILTERS) do ALL[#ALL + 1] = x end
	-- How many filters are off their default (the stock filter counter's count).
	function p.FiltersOn()
		local n = 0
		for _, x in ipairs(ALL) do if x.get() ~= x.default() then n = n + 1 end end
		return n
	end
	local function changed()
		canvas:RefreshAllDataProviders()
		p.Paint()
		if p.OnFilters then p.OnFilters() end
	end
	local function checkbox(root, x)
		local box = root:CreateCheckbox(x.text, x.get, function()
			x.set(not x.get())
			changed()
		end)
		if x.tip then
			box:SetOnEnter(function(button)
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
				GameTooltip_SetTitle(GameTooltip, x.text)
				GameTooltip_AddNormalLine(GameTooltip, x.tip)
				GameTooltip:Show()
			end)
			box:SetOnLeave(GameTooltip_Hide)
		end
		return box
	end
	function p.FilterMenu(owner)
		MenuUtil.CreateContextMenu(owner, function(_, root)
			root:SetTag("MENU_WORLD_MAP_TRACKING")
			root:CreateTitle(WORLD_MAP_FILTER_TITLE_SHOW_MAP)
			local mapID = canvas:GetMapID()
			if mapID and MapUtil.MapShouldShowWorldQuestFilters and MapUtil.MapShouldShowWorldQuestFilters(mapID) then
				local sub = checkbox(root, WQ)
				sub:CreateTitle(WORLD_MAP_FILTER_LABEL_WORLD_QUESTS_SUBMENU_TYPE)
				local prof1, prof2, _, fish, cook, firstAid = GetProfessions()
				if prof1 or prof2 then checkbox(sub, WQ_KINDS[1]) end
				if fish or cook or firstAid then checkbox(sub, WQ_KINDS[2]) end
			end
			for _, x in ipairs(FILTERS) do checkbox(root, x) end
			root:QueueSpacer()
			root:QueueDivider()
			root:QueueSpacer()
			root:CreateTitle(WORLD_MAP_FILTER_TITLE_SHOW_QUEST_LOG)
			checkbox(root, LOG_OBJECTIVES)
			-- As the stock filter's reset: every filter back to its default.
			if p.FiltersOn() > 0 then
				root:CreateDivider()
				root:CreateButton("Clear filters", function()
					for _, x in ipairs(ALL) do if x.get() ~= x.default() then x.set(x.default()) end end
					changed()
				end)
			end
		end)
	end
	-- At the end of the search row, as Social's: lit while a filter is off its default.
	p.Filter = W.IconButton(p, "sliders", 30, "Filter", function(self) p.FilterMenu(self) end, 14)
	p.Filter:SetPoint("TOPRIGHT", p, "TOPRIGHT", -W.SHELL.side, -HEAD)
	Theme.Skin(p.Filter, "editbox")
	function p.PaintFilter(b)
		local n = p.FiltersOn()
		W.SetIconState(b, n > 0)
		b.psTip = n > 0 and ("Filter (%d on)"):format(n) or "Filter"
	end
	local line = W.Divider(p)
	line:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -TOP)
	line:SetPoint("TOPRIGHT", p, "TOPRIGHT", 0, -TOP)
	p.Scroll = W.Scroll(p)
	p.Scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -(TOP + 1))
	p.Scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
	p.Empty = W.Text(p.Scroll.Child, "default", "textDim")
	p.Empty:SetPoint("TOPLEFT", p.Scroll.Child, "TOPLEFT", W.SHELL.side, -16)
	p.Empty:SetText("Your quest log is empty.")

	local heads, rows, sel = {}, {}, nil
	local textW = width - 1 - W.SHELL.side * 2

	local function place(b, y)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", p.Scroll.Child, "TOPLEFT", 0, -y)
		b:SetPoint("TOPRIGHT", p.Scroll.Child, "TOPRIGHT", 0, -y)
		b:Show()
	end

	-- A header: a click folds it, through the client, which sends no redraw
	-- of its own we can count on (docs/CLIENT.md, rule 6).
	local function headRow(i)
		if heads[i] then return heads[i] end
		local h = CreateFrame("Button", nil, p.Scroll.Child)
		h:SetHeight(HEAD_H)
		W.Hover(h)
		h.Chevron = W.Tex(h, "ARTWORK", "chevron-down", "textMuted")
		h.Chevron:SetSize(12, 12)
		h.Chevron:SetPoint("LEFT", h, "LEFT", W.SHELL.side, 0)
		h.Count = W.Text(h, "number", "textMuted")
		h.Count:SetPoint("RIGHT", h, "RIGHT", -W.SHELL.side, 0)
		h.Label = W.Text(h, "label", "textDim")
		h.Label:SetPoint("LEFT", h.Chevron, "RIGHT", 8, 0)
		h.Label:SetPoint("RIGHT", h.Count, "LEFT", -8, 0)
		h.Label:SetJustifyH("LEFT")
		h.Label:SetWordWrap(false)
		h:SetScript("OnClick", function(self)
			if self.psCollapsed then ExpandQuestHeader(self.psIndex) else CollapseQuestHeader(self.psIndex) end
			p.Paint()
		end)
		heads[i] = h
		return h
	end

	local function questTip(r)
		GameTooltip:SetOwner(r, "ANCHOR_LEFT")
		GameTooltip:SetText(r.psTitle, 1, 1, 1, 1, true)
		ns.TooltipHint("Click to open it and show it on the map. Shift-click to " .. (QuestUtils_IsQuestWatched(r.psQuest) and "stop tracking it." or "track it."))
		GameTooltip:Show()
	end

	-- As the stock title button: a link into an open chat box, shift-click
	-- tracks; a click opens its details and shows the quest's map with its
	-- area in focus.
	local function questClick(r)
		local id = r.psQuest
		if ChatFrameUtil.TryInsertQuestLinkForQuestID(id) then return end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if IsShiftKeyDown() then
			-- The stock toggle: it says so when too many are tracked.
			if not C_QuestLog.IsQuestDisabledForSession(id) then QuestMapQuestOptions_TrackQuest(id) end
		else
			sel = id
			local mapID = GetQuestUiMapID(id)
			if mapID and mapID ~= 0 then canvas:SetMapID(mapID) end
			canvas:TriggerEvent("SetFocusedQuestID", id)
			return p.Open(id)
		end
		p.Paint()
		if GameTooltip:GetOwner() == r then questTip(r) end
	end

	local function questRow(i)
		if rows[i] then return rows[i] end
		local r = CreateFrame("Button", nil, p.Scroll.Child)
		W.Hover(r)
		r.Sel = r:CreateTexture(nil, "BACKGROUND")
		r.Sel:SetTexture("Interface\\Buttons\\WHITE8X8")
		r.Sel:SetAllPoints(r)
		W.Painter(r.Sel, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
		r.Bar = r:CreateTexture(nil, "ARTWORK")
		r.Bar:SetTexture("Interface\\Buttons\\WHITE8X8")
		r.Bar:SetWidth(2)
		r.Bar:SetPoint("TOPLEFT")
		r.Bar:SetPoint("BOTTOMLEFT")
		W.Color(r.Bar, "accent")
		-- Two fixed slots at the right of the title line: tracked at the end
		-- (the stock checkbox's mark), and left of it done, failed or the
		-- quest's stock tag, so one never hides the other.
		r.Tracked = r:CreateTexture(nil, "ARTWORK")
		r.Tracked:SetAtlas("questlog-icon-checkmark-yellow")
		r.Tracked:SetSize(SLOT, SLOT)
		r.Tracked:SetPoint("TOPRIGHT", r, "TOPRIGHT", -W.SHELL.side, -8)
		r.Mark = W.Tex(r, "ARTWORK", "check", "success")
		r.Mark:SetSize(SLOT, SLOT)
		r.Mark:SetPoint("TOPRIGHT", r, "TOPRIGHT", -(W.SHELL.side + SLOT + 6), -8)
		r.Tag = r:CreateTexture(nil, "ARTWORK")
		r.Tag:SetSize(SLOT, SLOT)
		r.Tag:SetPoint("CENTER", r.Mark, "CENTER", 0, 0)
		r.Name = W.Text(r, "body", "text")
		r.Name:SetPoint("TOPLEFT", r, "TOPLEFT", W.SHELL.side, -8)
		r.Name:SetJustifyH("LEFT")
		r.Name:SetWordWrap(true)
		r.Goals = W.Text(r, "small", "textDim")
		r.Goals:SetPoint("TOPLEFT", r.Name, "BOTTOMLEFT", 0, -4)
		r.Goals:SetJustifyH("LEFT")
		r.Goals:SetWordWrap(true)
		r.Goals:SetSpacing(2)
		r.Goals:SetWidth(textW)
		r:RegisterForClicks("LeftButtonUp")
		r:SetScript("OnClick", questClick)
		-- Its area on the map lights up, as from the stock log.
		r:SetScript("OnEnter", function(self)
			canvas:TriggerEvent("SetHighlightedQuestID", self.psQuest)
			questTip(self)
		end)
		r:SetScript("OnLeave", function()
			canvas:TriggerEvent("ClearHighlightedQuestID")
			W.HideTooltip()
		end)
		rows[i] = r
		return r
	end

	-- What is left: the unfinished objectives, or the hand-in line once done.
	local function goals(info)
		if C_QuestLog.IsComplete(info.questID) then
			return GetQuestLogCompletionText and GetQuestLogCompletionText(info.questLogIndex) or QUEST_WATCH_QUEST_READY or "Ready to turn in."
		end
		local t = {}
		for i = 1, GetNumQuestLeaderBoards(info.questLogIndex) or 0 do
			local text, _, finished = GetQuestLogLeaderBoard(i, info.questLogIndex)
			if text and text ~= "" and not finished then t[#t + 1] = text end
		end
		return table.concat(t, "\n")
	end

	-- "[level] title" in its difficulty colour, lifted to read; the level and
	-- the colour as the map's filters say.
	local function questName(fs, info)
		fs:SetText(GetCVarBool("showQuestLevel") and ("[%d%s] %s"):format(info.level or 0, C_QuestLog.IsEliteQuest(info.questID) and "+" or "", info.title or "") or info.title or "")
		local diff = GetCVarBool("showQuestDifficultyColor") and C_PlayerInfo.GetContentDifficultyQuestForPlayer and C_PlayerInfo.GetContentDifficultyQuestForPlayer(info.questID)
		local c = diff and GetDifficultyColor(diff)
		W.Uncolor(fs)
		if c then fs:SetTextColor(Theme.Legible(c.r, c.g, c.b)) else W.Color(fs, "text") end
	end

	local function paintQuest(r, info)
		r.psQuest, r.psTitle = info.questID, info.title
		questName(r.Name, info)
		local id = info.questID
		local done, failed = C_QuestLog.IsComplete(id), C_QuestLog.IsFailed(id)
		r.Tracked:SetShown(QuestUtils_IsQuestWatched(id))
		r.Mark:SetShown(done or failed)
		r.Mark:SetTexture(Theme.Media(done and "check" or "close"))
		W.Color(r.Mark, done and "success" or "danger")
		-- The stock tag (QuestLogQuests_AddQuestButton): account-wide first, else the quest's own.
		local tag
		if not (done or failed) and not QuestUtil.IsQuestTagIconHidden() then
			local t = C_QuestLog.GetQuestTagInfo(id)
			tag = C_QuestLog.IsAccountQuest(id) and "questlog-questtypeicon-account" or (t and QuestUtils_GetQuestTagAtlas(t.tagID))
		end
		r.Tag:SetShown(tag ~= nil)
		if tag then
			r.Tag:SetAtlas(tag)
			r.Tag:SetDesaturated(C_QuestLog.IsQuestDisabledForSession(id))
		end
		r.Name:SetWidth(textW - 2 * (SLOT + 6))
		local g = GetCVarBool("showQuestObjectivesInLog") and goals(info) or ""
		r.Goals:SetText(g)
		r.Goals:SetShown(g ~= "")
		local h = 8 + math.ceil(r.Name:GetStringHeight()) + (g ~= "" and 4 + math.ceil(r.Goals:GetStringHeight()) or 0) + 10
		r:SetHeight(h)
		r.Sel:SetShown(info.questID == sel)
		r.Bar:SetShown(info.questID == sel)
	end

	-- The log in its order: a header, then its quests unless folded. Hidden
	-- quests, tasks and unfinished bounties stay out, as in the stock list;
	-- a header shows when folded or when it holds a quest that shows.
	local function shown(info)
		if info.isTask or info.isHidden or (info.isBounty and not C_QuestLog.IsComplete(info.questID)) then return false end
		return query == "" or (info.title or ""):lower():find(query, 1, true) or goals(info):lower():find(query, 1, true)
	end

	local detail, paintDetails -- the quest whose details show, if any
	function p.Paint()
		if not p:IsVisible() then return end
		if detail then
			-- Turned in or abandoned: back to the list.
			if C_QuestLog.GetLogIndexForQuestID(detail) then return paintDetails(detail) end
			return p.Close()
		end
		local groups, cur = {}, nil
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i)
			if info and info.isHeader then
				cur = { info = info, quests = {} }
				groups[#groups + 1] = cur
			elseif info and shown(info) then
				if not cur then
					cur = { quests = {} }
					groups[#groups + 1] = cur
				end
				cur.quests[#cur.quests + 1] = info
			end
		end
		local y, hi, ri, total = 0, 0, 0, 0
		for _, g in ipairs(groups) do
			local h = g.info
			total = total + #g.quests
			-- Searching, every match shows, its header open.
			local folded = h and h.isCollapsed and query == ""
			if h and (folded or #g.quests > 0) then
				hi = hi + 1
				local b = headRow(hi)
				b.psIndex, b.psCollapsed = h.questLogIndex, h.isCollapsed
				b.Label:SetText(h.title)
				b.Count:SetText(#g.quests > 0 and #g.quests or "")
				b.Chevron:SetTexture(Theme.Media(folded and "chevron-right" or "chevron-down"))
				place(b, y)
				y = y + HEAD_H
			end
			if not folded then
				for _, info in ipairs(g.quests) do
					ri = ri + 1
					local r = questRow(ri)
					paintQuest(r, info)
					place(r, y)
					y = y + r:GetHeight()
				end
			end
		end
		for i = hi + 1, #heads do heads[i]:Hide() end
		for i = ri + 1, #rows do rows[i]:Hide() end
		p.PaintFilter(p.Filter)
		local _, quests = C_QuestLog.GetNumQuestLogEntries()
		local max = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()
		p.Count:SetText(max and ("%d/%d"):format(quests or total, max) or (quests or total))
		p.Empty:SetText(query ~= "" and "No quests match." or "Your quest log is empty.")
		p.Empty:SetShown(hi == 0 and ri == 0)
		p.Scroll.Child:SetWidth(width - 1)
		W.SetScrollContent(p.Scroll, y + 8, p:GetHeight() - TOP - 1)
	end

	-- The details (QuestMapFrame_ShowQuestDetails and QuestInfo's map
	-- templates), in the list's place: back returns to the list as it was.
	local FOOT, X = W.SHELL.footer, W.SHELL.side
	local d = CreateFrame("Frame", nil, p)
	d:SetAllPoints(p)
	d:Hide()
	p.Details = d
	d.Back = CreateFrame("Button", nil, d)
	d.Back:SetPoint("TOPLEFT", d, "TOPLEFT", 1, 0)
	d.Back:SetPoint("TOPRIGHT", d, "TOPRIGHT", 0, 0)
	d.Back:SetHeight(HEAD)
	W.Hover(d.Back)
	local chev = W.Tex(d.Back, "ARTWORK", "chevron-left", "textDim")
	chev:SetSize(12, 12)
	chev:SetPoint("LEFT", d.Back, "LEFT", X - 1, 0)
	d.Back.Label = W.Text(d.Back, "label", "textDim")
	d.Back.Label:SetPoint("LEFT", chev, "RIGHT", 8, 0)
	d.Back.Label:SetText("All quests")
	d.Back:SetScript("OnClick", function() p.Close() end)
	local dline = W.Divider(d)
	dline:SetPoint("TOPLEFT", d, "TOPLEFT", 1, -HEAD)
	dline:SetPoint("TOPRIGHT", d, "TOPRIGHT", 0, -HEAD)
	d.Foot = CreateFrame("Frame", nil, d)
	d.Foot:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 1, 0)
	d.Foot:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", 0, 0)
	d.Foot:SetHeight(FOOT)
	W.Fill(d.Foot, "footer")
	local fline = W.Divider(d.Foot)
	fline:SetPoint("TOPLEFT", d.Foot, "TOPLEFT", 0, 0)
	fline:SetPoint("TOPRIGHT", d.Foot, "TOPRIGHT", 0, 0)
	d.Scroll = W.Scroll(d)
	d.Scroll:SetPoint("TOPLEFT", d, "TOPLEFT", 1, -(HEAD + 1))
	d.Scroll:SetPoint("BOTTOMRIGHT", d.Foot, "TOPRIGHT", 0, 0)
	local child = d.Scroll.Child
	d.Title = W.Text(child, "heading", "text")
	d.Title:SetPoint("TOPLEFT", child, "TOPLEFT", X, -16)
	d.Title:SetWidth(textW)
	d.Title:SetWordWrap(true)

	-- Pooled pieces, laid out top down from c.y; what a paint does not use hides.
	local checks, nCheck = {}, 0
	local tileTip, rewards
	local c = ns.QuestRewards(child, { x = X, width = textW,
		tip = function(t) tileTip(t) end,
		click = function(self)
			if self.psKind == "item" and IsModifiedClick() then HandleModifiedItemClick(GetQuestLogItemLink(self.psType, self.psIndex)) end
		end })
	local function check(t)
		nCheck = nCheck + 1
		local c = checks[nCheck] or W.Tex(child, "ARTWORK", "check", "success")
		checks[nCheck] = c
		c:SetSize(12, 12)
		c:ClearAllPoints()
		c:SetPoint("TOPRIGHT", t, "TOPLEFT", -6, -1)
		c:Show()
	end

	-- A reward (docs/DESIGN.md, "Reagent Tile", the flyout's full width): the
	-- game's tooltip, as the stock reward button's, and its modified click.
	function tileTip(t)
		if not t.psKind then return end
		C_QuestLog.SetSelectedQuest(detail) -- the tooltip reads the selected quest
		GameTooltip:SetOwner(t, "ANCHOR_RIGHT")
		if t.psKind == "item" then
			GameTooltip:SetQuestLogItem(t.psType, t.psIndex, nil, false)
			GameTooltip_ShowCompareItem(GameTooltip)
		elseif t.psKind == "currency" then
			GameTooltip:SetQuestLogCurrency(t.psType, t.psIndex)
		else
			GameTooltip:SetSpellByID(t.psIndex, nil, true)
		end
		GameTooltip:Show()
	end
	-- The rewards in QuestInfo_ShowRewards' order, read from the quest log.
	function rewards(id)
		local d = { items = 0, choices = 0, money = 0, xp = 0, honor = 0 }
		if C_QuestLog.ShouldShowQuestRewards(id) then
			d.items, d.choices = GetNumQuestLogRewards(), GetNumQuestLogChoices(id, true)
			d.money, d.xp, d.honor, d.title = GetQuestLogRewardMoney(), GetQuestLogRewardXP(), GetQuestLogRewardHonor(), GetQuestLogRewardTitle()
			d.skillName, d.skillIcon, d.skillPoints = GetQuestLogRewardSkillPoints()
		end
		-- Items and currencies are counted apart, as the tooltips index them.
		local ni, nc = 0, 0
		function d.choice(i)
			if GetQuestLogChoiceInfoLootType(i) == 1 then
				local cur = C_QuestLog.GetQuestRewardCurrencyInfo(id, i, true)
				nc = nc + 1
				if cur then c.tile("currency", "choice", nc, cur.name, cur.texture, cur.totalRewardAmount, cur.quality) end
			else
				local name, icon, n, q, usable = GetQuestLogChoiceInfo(i)
				ni = ni + 1
				c.tile("item", "choice", ni, name, icon, n, q, usable)
			end
		end
		d.reward = GetQuestLogRewardInfo
		c.Rewards(id, d)
	end

	-- Abandon, as QuestMapQuestOptions_AbandonQuest and its popup's accept,
	-- confirmed by our own dialog: StaticPopup is never driven from our code.
	local function abandon(id)
		local old = C_QuestLog.GetSelectedQuest()
		C_QuestLog.SetSelectedQuest(id)
		C_QuestLog.SetAbandonQuest()
		local names = {}
		for _, itemID in ipairs(C_QuestLog.GetAbandonQuestItems() or {}) do names[#names + 1] = C_Item.GetItemNameByID(itemID) end
		local title = QuestUtils_GetQuestName(C_QuestLog.GetAbandonQuest())
		C_QuestLog.SetSelectedQuest(old)
		W.Modal({
			title = ("Abandon %s?"):format(title),
			text = #names > 0 and ("Its progress is lost, and these items with it: %s."):format(table.concat(names, ", ")) or "Its progress is lost.",
			action = "Abandon",
			danger = true,
			onAccept = function()
				C_QuestLog.AbandonQuest()
				PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST)
			end,
		})
	end
	d.Abandon = W.Button(d.Foot, "Abandon", function() abandon(detail) end, { danger = true })
	d.Abandon:SetPoint("LEFT", d.Foot, "LEFT", X, 0)
	-- Track and Share: the stock toggles (the client says when too many are tracked).
	d.Track = W.Button(d.Foot, "Track", function()
		QuestMapQuestOptions_TrackQuest(detail)
		p.Paint()
	end)
	d.Track:SetPoint("RIGHT", d.Foot, "RIGHT", -X, 0)
	d.Share = W.Button(d.Foot, "Share", function() QuestMapQuestOptions_ShareQuest(detail) end)
	d.Share:SetPoint("RIGHT", d.Track, "LEFT", -8, 0)

	function paintDetails(id)
		-- The stock details read the selected quest.
		C_QuestLog.SetSelectedQuest(id)
		local index = C_QuestLog.GetLogIndexForQuestID(id)
		local info = C_QuestLog.GetInfo(index) or { questID = id }
		nCheck = 0
		questName(d.Title, info)
		c.Begin(16 + math.ceil(d.Title:GetStringHeight()))
		local description, summary = GetQuestLogQuestText()
		if summary and summary ~= "" then c.text("body", "text", summary, 8) end
		-- Every objective, a finished one checked and muted (QuestInfo_ShowObjectives).
		local gap = 10
		local waypoint = C_QuestLog.GetNextWaypointText(id)
		if waypoint then
			c.text("body", "textDim", WAYPOINT_OBJECTIVE_FORMAT_OPTIONAL:format(waypoint), gap, 18)
			gap = 4
		end
		for i = 1, GetNumQuestLeaderBoards(index) or 0 do
			local s, kind, finished = GetQuestLogLeaderBoard(i, index)
			if kind ~= "spell" and kind ~= "log" then
				local t = c.text("body", finished and "textMuted" or "textDim", (s and s ~= "") and s or kind, gap, 18)
				if finished then check(t) end
				gap = 4
			end
		end
		local need = C_QuestLog.GetRequiredMoney()
		if need > 0 then c.money("Required money", need, need > GetMoney() and "danger" or nil) end
		local group = C_QuestLog.GetSuggestedGroupSize(id)
		if group > 0 then c.text("small", "textDim", QUEST_SUGGESTED_GROUP_NUM:format(group), 8) end
		if description and description ~= "" then
			c.text("heading", "text", "Description", 24)
			c.text("body", "textDim", description, 8)
		end
		rewards(id)
		c.End()
		for i = nCheck + 1, #checks do checks[i]:Hide() end
		child:SetWidth(width - 1)
		W.SetScrollContent(d.Scroll, c.y + 16, p:GetHeight() - HEAD - 1 - FOOT)
		-- The actions, as QuestMapFrame_UpdateQuestDetailsButtons allows them.
		-- Disabled ones fade (ns.SetEnabled) and say why in their tooltip.
		local disabled, watched = C_QuestLog.IsQuestDisabledForSession(id), QuestUtils_IsQuestWatched(id)
		W.SetButtonText(d.Track, watched and "Untrack" or "Track")
		local hold = disabled and "This quest is on hold for now." or nil
		local why
		if watched then
			why = not QuestUtil.CanRemoveQuestWatch() and "This quest can't be untracked now." or nil
		else
			local max = Constants.QuestWatchConsts and Constants.QuestWatchConsts.MAX_QUEST_WATCHES
			why = hold or (max and C_QuestLog.GetNumQuestWatches() >= max and ("You're tracking too many quests (%d at most). Untrack one first."):format(max)) or nil
		end
		ns.SetEnabled(d.Track, not why)
		d.Track.psTip = why
		d.Share:SetShown(not disabled and C_QuestLog.IsPushableQuest(id) and IsInGroup())
		why = hold or (not C_QuestLog.CanAbandonQuest(id) and "You can't abandon this quest.") or nil
		ns.SetEnabled(d.Abandon, not why)
		d.Abandon.psTip = why
	end

	local listParts = { p.Title, p.Count, p.Filter, p.Search, line, p.Scroll }
	function p.Open(id)
		detail = id
		for _, r in ipairs(listParts) do r:Hide() end
		d:Show()
		W.ScrollTo(d.Scroll, 0)
		p.Paint()
	end
	function p.Close()
		detail = nil
		d:Hide()
		for _, r in ipairs(listParts) do r:Show() end
		p.Paint()
	end

	p:SetScript("OnShow", p.Paint)
	return p
end
