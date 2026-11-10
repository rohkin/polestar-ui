-- The quest log (docs/DESIGN.md, "World Map and Quest Log"): the flyout on
-- the right of our World Map, listing the log as the stock panel
-- (QuestMapFrame's QuestLogQuests_Update) lists it: foldable headers, each
-- quest with its level, its title in its difficulty colour and what is left
-- of it. ns.QuestLog(window, canvas, width) -> the panel; panel.Paint().

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local HEAD_H, HEAD, TOP = 28, 44, 44 + 30 + 12

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
	p.Search:SetPoint("TOPRIGHT", p, "TOPRIGHT", -W.SHELL.side, -HEAD)
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
		ns.TooltipHint("Click to show it on the map. Shift-click to " .. (QuestUtils_IsQuestWatched(r.psQuest) and "stop tracking it." or "track it."))
		GameTooltip:Show()
	end

	-- As the stock title button: a link into an open chat box, shift-click
	-- tracks; a click shows the quest's map with its area in focus.
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
		-- Complete, or tracked: a glyph at the right of the title line.
		r.Mark = W.Tex(r, "ARTWORK", "check", "success")
		r.Mark:SetSize(14, 14)
		r.Mark:SetPoint("TOPRIGHT", r, "TOPRIGHT", -W.SHELL.side, -8)
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

	local function paintQuest(r, info)
		r.psQuest, r.psTitle = info.questID, info.title
		r.Name:SetText(("[%d] %s"):format(info.level or 0, info.title or ""))
		local diff = C_PlayerInfo.GetContentDifficultyQuestForPlayer and C_PlayerInfo.GetContentDifficultyQuestForPlayer(info.questID)
		local c = diff and GetDifficultyColor(diff)
		W.Uncolor(r.Name)
		if c then r.Name:SetTextColor(Theme.Legible(c.r, c.g, c.b)) else W.Color(r.Name, "text") end
		local done, watched = C_QuestLog.IsComplete(info.questID), QuestUtils_IsQuestWatched(info.questID)
		r.Mark:SetShown(done or watched)
		r.Mark:SetTexture(Theme.Media(done and "check" or "star"))
		W.Color(r.Mark, done and "success" or "accent")
		r.Name:SetWidth(textW - ((done or watched) and 14 + 8 or 0))
		local g = goals(info)
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

	function p.Paint()
		if not p:IsVisible() then return end
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
		local _, quests = C_QuestLog.GetNumQuestLogEntries()
		local max = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()
		p.Count:SetText(max and ("%d/%d"):format(quests or total, max) or (quests or total))
		p.Empty:SetText(query ~= "" and "No quests match." or "Your quest log is empty.")
		p.Empty:SetShown(hi == 0 and ri == 0)
		p.Scroll.Child:SetWidth(width - 1)
		W.SetScrollContent(p.Scroll, y + 8, p:GetHeight() - TOP - 1)
	end

	p:SetScript("OnShow", p.Paint)
	return p
end
