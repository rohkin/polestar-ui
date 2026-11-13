-- The Guild (docs/windows/guild.md): the stock Guild & Communities window's
-- guild (roster, member details, info, news, benefits, log) in a Polestar
-- shell. Communities, chat streams, the finders and recruitment stay on the
-- game's window (shift-click the guild micro button).

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUIGuild"
local ROW_H, HEAD_H, GAP = 26, 28, 8
local DETAIL_W = 300

local f, page, query = nil, "roster", ""
local M = {}
local sortKey, sortRev, extra = nil, false, nil
local profOpen = {} -- profession heads unfolded (stock: folded)
local detailId -- the member whose details show

local function tipLine(text, token)
	local r, g, b = Theme.Color(token or "textDim")
	GameTooltip:AddLine(text, r, g, b, true)
end

-- Values the client hands over secret in combat or chat lockdown keep the
-- last clean read (docs/CLIENT.md, rule 3).
local known = {}
local function keep(key, v)
	if ns.Clean(v) ~= nil then known[key] = v end
	return known[key]
end

---------------------------------------------------------------------------
-- The roster, as the stock member list reads it (C_Club, the guild's club).

local P = Enum.ClubMemberPresence
local function online(m) return m.presence ~= P.Offline and m.presence ~= P.Unknown end
local function mobile(m) return m.presence == P.OnlineMobile end

local function clubId() return ns.Clean(C_Club.GetGuildClubId()) end

local roster = {}
local function readRoster()
	local id = clubId()
	if not id then return roster end
	local ids = ns.Clean(C_Club.GetClubMembers(id))
	if not ids then return roster end
	local list = {}
	for _, mid in ipairs(ids) do
		local m = C_Club.GetMemberInfo(id, mid)
		if m then
			if not ns.Clean(m.name) then return roster end -- a secret read: keep the last
			list[#list + 1] = m
		end
	end
	roster = list
	return list
end

local function me()
	local id = clubId()
	return id and C_Club.GetMemberInfoForSelf(id)
end

local function classFile(m)
	local c = m.classID and C_CreatureInfo.GetClassInfo(m.classID)
	return c and c.classFile, c and c.className
end

-- "3 days ago" from the client's year, month, day, hour counts (TimeUtil.GetRecentTimeDate).
local function ago(y, mo, d, h)
	y, mo, d, h = y or 0, mo or 0, d or 0, h or 0
	local n, u = y, "year"
	if y == 0 then n, u = mo, "month" end
	if y == 0 and mo == 0 then n, u = d, "day" end
	if y == 0 and mo == 0 and d == 0 then n, u = h, "hour" end
	if n == 0 then return "under an hour ago" end
	return ("%d %s%s ago"):format(n, u, n == 1 and "" or "s")
end
local function hoursAgo(m)
	return (m.lastOnlineYear or 0) * 8760 + (m.lastOnlineMonth or 0) * 730 + (m.lastOnlineDay or 0) * 24 + (m.lastOnlineHour or 0)
end

-- The stock Zone column: where they are, "Mobile", or when they were last on.
local function whereText(m)
	if mobile(m) then return "Mobile" end
	if not online(m) then return m.lastOnlineYear and "Last online " .. ago(m.lastOnlineYear, m.lastOnlineMonth, m.lastOnlineDay, m.lastOnlineHour) or "Offline" end
	return m.zone or ""
end

-- The stock order (CommunitiesUtil.SortMemberInfo): presence, level, rank, name.
local function presenceOrder(p)
	return p == P.Online and 1 or p == P.OnlineMobile and 2 or p == P.Away and 3 or p == P.Busy and 4 or p == P.Offline and 5 or 6
end
local function stockLess(a, b)
	if a.presence ~= b.presence then return presenceOrder(a.presence) < presenceOrder(b.presence) end
	if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) > (b.level or 0) end
	if (a.guildRankOrder or 0) ~= (b.guildRankOrder or 0) then return (a.guildRankOrder or 0) < (b.guildRankOrder or 0) end
	return (a.name or "") < (b.name or "")
end

-- The columns of the stock guild roster (GUILD_COLUMN_INFO), then the chosen
-- extra one (EXTRA_GUILD_COLUMNS): `value(m)` sorts, `w` 0 takes the rest.
local COLS = {
	{ key = "level", label = "Lvl", w = 36, value = function(m) return m.level or 0 end },
	{ key = "class", label = "Class", w = 32, value = function(m) return select(2, classFile(m)) or "" end },
	{ key = "name", label = "Name", w = 120, value = function(m) return (m.name or ""):lower() end },
	-- Online by zone, then offline by how recently they were on (the stock zone sort).
	{ key = "zone", label = "Zone", w = 140, value = function(m)
		return online(m) and "0" .. (m.zone or ""):lower() or ("1%09d"):format(hoursAgo(m))
	end },
	{ key = "rank", label = "Rank", w = 100, value = function(m) return m.guildRankOrder or 99 end },
	{ key = "note", label = "Note", w = 0, value = function(m) return (m.memberNote or ""):lower() end },
}
local EXTRA = {
	prof = { key = "prof", label = "Profession", w = 90, value = function(m) return m.psProfRank or 0 end,
		can = function() return C_TradeSkillUI and C_TradeSkillUI.IsGuildTradeSkillsEnabled and C_TradeSkillUI.IsGuildTradeSkillsEnabled() end },
	score = { key = "score", label = "Dungeon score", w = 90, value = function(m) return m.overallDungeonScore or 0 end,
		can = function() return C_MythicPlus and C_MythicPlus.IsMythicPlusActive and C_MythicPlus.IsMythicPlusActive() end },
}
local function columns()
	local list = {}
	for _, c in ipairs(COLS) do list[#list + 1] = c end
	if extra and EXTRA[extra].can() then list[#list + 1] = EXTRA[extra] end
	local fixed, x = 0, 0
	for _, c in ipairs(list) do fixed = fixed + c.w + GAP end
	for _, c in ipairs(list) do
		c.x = x
		c.cw = c.w > 0 and c.w or math.max(40, f.BodyWidth - fixed - 8)
		x = x + c.cw + GAP
	end
	return list
end

local function showOffline() return GetCVarBool("communitiesShowOffline") end

local function matches(m)
	if query == "" then return true end
	for _, s in ipairs({ m.name, m.zone, m.guildRank, m.memberNote }) do
		if s and s:lower():find(query, 1, true) then return true end
	end
end

-- The roster as shown: online (or all), matching the search, sorted by the
-- chosen column (a second click on it reverses) or in the stock order. With
-- the Profession column, grouped under each profession as stock.
local function shownRoster()
	local all, list = readRoster(), {}
	for _, m in ipairs(all) do
		if (showOffline() or online(m)) and matches(m) then list[#list + 1] = m end
	end
	local col
	for _, c in ipairs(columns()) do if c.key == sortKey then col = c end end
	table.sort(list, function(a, b)
		if col then
			local va, vb = col.value(a), col.value(b)
			if va ~= vb then if sortRev then return va > vb end return va < vb end
		end
		return stockLess(a, b)
	end)
	if extra ~= "prof" or not EXTRA.prof.can() then return list, all end
	local profs, order = {}, {}
	for _, m in ipairs(list) do
		for i = 1, 2 do
			local id = m["profession" .. i .. "ID"]
			if id then
				if not profs[id] then profs[id] = { name = m["profession" .. i .. "Name"] or "", list = {} }; order[#order + 1] = id end
				-- A copy carrying the skill in this profession for the column.
				local e = setmetatable({ psProf = id, psProfRank = m["profession" .. i .. "Rank"] or 0 }, { __index = m })
				table.insert(profs[id].list, e)
			end
		end
	end
	table.sort(order, function(a, b) return profs[a].name < profs[b].name end)
	local out = {}
	for _, id in ipairs(order) do
		local p = profs[id]
		if sortKey == "prof" then
			table.sort(p.list, function(a, b) if sortRev then return a.psProfRank > b.psProfRank end return a.psProfRank < b.psProfRank end)
		end
		out[#out + 1] = { head = true, prof = id, name = ("%s (%d)"):format(p.name, #p.list) }
		if profOpen[id] then for _, e in ipairs(p.list) do out[#out + 1] = e end end
	end
	return out, all
end

---------------------------------------------------------------------------
-- Roster rows: one row panel under the column headings, rows drawn only
-- where the scroll shows them (a guild holds up to 1000 members).

local shown = {}
local rows = {}

local function memberTip(r)
	local m = r.psMember
	if not m or m.head then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(m.name or "")
	tipLine(m.guildRank or "", "textDim")
	local race = m.race and C_CreatureInfo.GetRaceInfo and C_CreatureInfo.GetRaceInfo(m.race)
	local _, className = classFile(m)
	if m.level and race and className then tipLine(("Level %d %s %s"):format(m.level, race.raceName, className), "text") end
	if mobile(m) then tipLine("On the mobile app", "text") elseif online(m) and m.zone then tipLine(m.zone, "text") end
	if (m.memberNote or "") ~= "" then tipLine("Note: " .. m.memberNote, "textDim") end
	ns.TooltipHint(m.psProf and "Click to see their recipes. Right-click for more." or "Click for details. Right-click for more.")
	GameTooltip:Show()
end

-- The game's own guild member menu, as the stock roster opens it
-- (OnClubMemberButtonClicked): whisper, invite, promote to leader, leave...
local function memberMenu(r, m)
	local id = clubId()
	local club = id and C_Club.GetClubInfo(id)
	if not club then return end
	UnitPopup_OpenMenu("COMMUNITIES_GUILD_MEMBER", {
		name = m.name, clubMemberInfo = m, clubInfo = club, clubPrivileges = C_Club.GetClubPrivileges(id),
		clubAssignableRoles = C_Club.GetAssignableRoles(id, m.memberId), isSelf = m.isSelf, guid = m.guid,
		isMobile = mobile(m), isGuildMember = true, ownerFrame = r,
	})
end

local function newRow(panel)
	local r = CreateFrame("Button", nil, panel)
	r:SetHeight(ROW_H)
	r:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
	W.Hover(r)
	r.Cells = {}
	r.Class = r:CreateTexture(nil, "ARTWORK")
	r.Class:SetSize(16, 16)
	r.Chevron = W.Tex(r, "ARTWORK", "chevron-right", "textDim")
	r.Chevron:SetSize(12, 12)
	r.Chevron:SetPoint("LEFT", r, "LEFT", 8, 0)
	r.Head = W.Text(r, "default", "textDim")
	r.Head:SetPoint("LEFT", r, "LEFT", 26, 0)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:SetScript("OnClick", function(self, button)
		local m = self.psMember
		if m.head then
			profOpen[m.prof] = not profOpen[m.prof] or nil
			return M.Show() -- at once (docs/CLIENT.md, rule 6)
		end
		if button == "RightButton" then return memberMenu(self, m) end
		if m.psProf then return C_GuildInfo.QueryGuildMemberRecipes(m.guid, m.psProf) end
		detailId = detailId ~= m.memberId and m.memberId or nil
		M.Show()
	end)
	r:SetScript("OnEnter", memberTip)
	r:SetScript("OnLeave", W.HideTooltip)
	return r
end

local function cell(r, k)
	local t = r.Cells[k]
	if not t then
		t = W.Text(r, "small", "text")
		t:SetJustifyH("LEFT")
		t:SetWordWrap(false)
		r.Cells[k] = t
	end
	return t
end

local function paintRow(r, m, cols)
	r.psMember = m
	local head = m.head
	r.Chevron:SetShown(head ~= nil)
	r.Head:SetShown(head ~= nil)
	r.Class:SetShown(false)
	for _, t in pairs(r.Cells) do t:Hide() end
	if head then
		r.Chevron:SetTexture(Theme.Media(profOpen[m.prof] and "chevron-down" or "chevron-right"))
		r.Head:SetText(m.name)
		return
	end
	local file = classFile(m)
	local on = online(m)
	for _, c in ipairs(cols) do
		if c.key == "class" then
			if file then
				r.Class:SetAtlas(GetClassAtlas(file))
				r.Class:ClearAllPoints()
				r.Class:SetPoint("LEFT", r, "LEFT", c.x + 8, 0)
				r.Class:SetDesaturated(not on)
				r.Class:SetAlpha(on and 1 or 0.6)
				r.Class:Show()
			end
		else
			local t = cell(r, c.key)
			t:ClearAllPoints()
			t:SetPoint("LEFT", r, "LEFT", c.x + 8, 0)
			t:SetWidth(c.cw - 4)
			local text = c.key == "level" and tostring(m.level or "") or c.key == "name" and m.name or c.key == "zone" and whereText(m)
				or c.key == "rank" and m.guildRank or c.key == "note" and m.memberNote
				or c.key == "prof" and tostring(m.psProfRank or "")
				or c.key == "score" and (m.overallDungeonScore and tostring(m.overallDungeonScore) or "-")
			t:SetText(text or "")
			W.Uncolor(t)
			local cc = c.key == "name" and on and file and RAID_CLASS_COLORS[file]
			if cc then t:SetTextColor(Theme.Legible(cc.r, cc.g, cc.b)) else W.Color(t, on and (c.key == "name" and "text" or "textDim") or "textMuted") end
			t:Show()
		end
	end
end

-- Paint the rows the scroll shows now.
local function paintVisible()
	local p = f.psRoster.Rows
	if not p:IsShown() then return end
	local top = f.Scroll:GetVerticalScroll() - 8 - HEAD_H
	local first = math.max(1, math.floor(top / ROW_H) + 1)
	local n = math.ceil((f.psViewH or 600) / ROW_H) + 1
	local cols = columns()
	for k = 1, n do
		local i = first + k - 1
		local r = rows[k] or newRow(p)
		rows[k] = r
		local m = shown[i]
		if m then
			r:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -(i - 1) * ROW_H)
			r.psIndex = i
			paintRow(r, m, cols)
			r:Show()
		else
			r:Hide()
		end
	end
	for k = n + 1, #rows do rows[k]:Hide() end
end

local function paintHeads(cols)
	local R = f.psRoster
	R.psHeads = R.psHeads or {}
	for i, c in ipairs(cols) do
		local b = R.psHeads[i]
		if not b then
			b = CreateFrame("Button", nil, R)
			b:SetHeight(HEAD_H)
			W.Hover(b)
			b.Text = W.Text(b, "small", "textDim")
			b.Text:SetPoint("LEFT", b, "LEFT", 8, 0)
			b.Arrow = W.Tex(b, "ARTWORK", "chevron-down", "textDim")
			b.Arrow:SetSize(10, 10)
			b.Arrow:SetPoint("LEFT", b.Text, "RIGHT", 4, 0)
			-- The stock headers sort; a second click on the same one reverses.
			b:SetScript("OnClick", function(self)
				if sortKey == self.psKey then sortRev = not sortRev else sortKey, sortRev = self.psKey, false end
				M.Show()
			end)
			R.psHeads[i] = b
		end
		b.psKey = c.key
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", R, "TOPLEFT", c.x, 0)
		b:SetWidth(c.cw + GAP)
		b.Text:SetText(c.label)
		W.Color(b.Text, sortKey == c.key and "text" or "textDim")
		b.Arrow:SetShown(sortKey == c.key)
		b.Arrow:SetTexture(Theme.Media(sortRev and "chevron-up" or "chevron-down"))
		b:Show()
	end
	for i = #cols + 1, #R.psHeads do R.psHeads[i]:Hide() end
end

local function paintRoster()
	local list = shownRoster()
	shown = list
	local R = f.psRoster
	paintHeads(columns())
	R.Rows:SetHeight(math.max(1, #list * ROW_H))
	R.Rows:SetShown(#list > 0)
	f.psEmpty:SetText(query ~= "" and "No one matches." or "No one in your guild is online.")
	f.psEmpty:SetShown(#list == 0)
	f.psEmpty:ClearAllPoints()
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(8 + HEAD_H + 16))
	paintVisible()
	return 8 + HEAD_H + #list * ROW_H + 24
end

---------------------------------------------------------------------------
-- Member details: the stock GuildMemberDetailFrame, as a flyout.

local function fieldBody(letters, lines)
	local body = CreateFrame("Frame", nil, f)
	body:SetSize(352, lines and 120 or 30)
	local e = ns.TextField(body, 352, letters)
	e:SetAllPoints(body)
	if lines then
		e:SetMultiLine(true)
		e:SetTextInsets(10, 10, 8, 8)
		e:SetScript("OnEnterPressed", nil)
	else
		e:SetScript("OnEnterPressed", function() PolestarModal.Box.Action:Click() end)
	end
	body.Box = e
	return body
end

-- A modal with a text field: `apply(text)` on accept.
local bodies = {}
local function editText(title, text, value, letters, apply, lines)
	local key = (lines and "m" or "l") .. letters
	bodies[key] = bodies[key] or fieldBody(letters, lines)
	local e = bodies[key].Box
	e:SetText(value or "")
	ns.ModalWith({ title = title, text = text, action = "Save", onAccept = function() apply(e:GetText() or "") end }, bodies[key])
	e:SetFocus()
end

local function detailMember()
	for _, m in ipairs(roster) do if m.memberId == detailId then return m end end
end

-- The stock rank dropdown (SetupRankDropdown): the ranks this player may set.
local function rankItems(m)
	local mine = me()
	if not mine or not mine.guildRankOrder then return {} end
	local hi = CanGuildPromote() and mine.guildRankOrder + 1 or m.guildRankOrder
	local lo = CanGuildDemote() and GuildControlGetNumRanks() or m.guildRankOrder
	local items = {}
	for o = hi, lo do
		local allowed = C_GuildInfo.IsGuildRankAssignmentAllowed(m.guid, o)
		items[#items + 1] = { text = GuildControlGetRankName(o), checked = o == m.guildRankOrder, disabled = not allowed,
			tip = not allowed and "This rank needs an authenticator on the account." or nil,
			onClick = function() if o ~= m.guildRankOrder then C_GuildInfo.SetGuildRankOrder(m.guid, o) end end }
	end
	return items
end

local function buildDetail()
	local d = ns.Flyout(f, NAME .. "Member", DETAIL_W)
	d:Hide()
	local w = DETAIL_W - 48
	d.Close = W.IconButton(d, "close", 28, "Close", function() detailId = nil; M.Show() end, 14)
	d.Close:SetPoint("TOPRIGHT", d, "TOPRIGHT", -12, -12)
	d.Name = W.Text(d, "heading", "text")
	d.Name:SetPoint("TOPLEFT", d, "TOPLEFT", 24, -24)
	d.Name:SetWidth(w - 28)
	d.Name:SetWordWrap(false)
	d.Line = W.Text(d, "note", "textDim")
	d.Line:SetPoint("TOPLEFT", d.Name, "BOTTOMLEFT", 0, -6)
	d.Where = W.Text(d, "note", "textDim")
	d.Where:SetPoint("TOPLEFT", d.Line, "BOTTOMLEFT", 0, -4)
	d.Online = W.Text(d, "note", "textDim")
	d.Online:SetPoint("TOPLEFT", d.Where, "BOTTOMLEFT", 0, -4)
	for _, t in ipairs({ d.Line, d.Where, d.Online }) do t:SetWidth(w); t:SetWordWrap(false); t:SetJustifyH("LEFT") end
	d.RankLabel = W.Text(d, "small", "textDim")
	d.RankLabel:SetText("Rank")
	d.RankLabel:SetPoint("TOPLEFT", d.Online, "BOTTOMLEFT", 0, -20)
	d.Rank = W.Text(d, "default", "text")
	d.Rank:SetPoint("TOPLEFT", d.RankLabel, "BOTTOMLEFT", 0, -6)
	d.RankPick = W.Button(d, "", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		local m = detailMember()
		if m then W.ShowMenu(self, rankItems(m), { minWidth = w }) end
	end, { width = w })
	d.RankPick:SetPoint("TOPLEFT", d.RankLabel, "BOTTOMLEFT", 0, -6)
	local function note(label, anchor)
		local n = {}
		n.Label = W.Text(d, "small", "textDim")
		n.Label:SetText(label)
		n.Label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -20)
		n.Text = W.Text(d, "default", "text")
		n.Text:SetPoint("TOPLEFT", n.Label, "BOTTOMLEFT", 0, -6)
		n.Text:SetWidth(w)
		n.Text:SetJustifyH("LEFT")
		n.Edit = W.IconButton(d, "icon-note", 22, "Edit", nil, 12)
		n.Edit:SetPoint("LEFT", n.Label, "RIGHT", 6, 0)
		return n
	end
	d.Note = note("Note", d.RankPick)
	d.Officer = note("Officer note", d.Note.Text)
	d.Note.Edit:SetScript("OnClick", function()
		local m = detailMember()
		if m then editText("Note", ("The note on %s, seen by the guild."):format(m.name), m.memberNote, 31,
			function(t) C_GuildInfo.SetNote(m.guid, t, true) end) end
	end)
	d.Officer.Edit:SetScript("OnClick", function()
		local m = detailMember()
		if m then editText("Officer note", ("The note on %s, seen by officers."):format(m.name), m.officerNote, 31,
			function(t) C_GuildInfo.SetNote(m.guid, t, false) end) end
	end)
	d.Remove = W.Button(d, "Remove", function()
		local m = detailMember()
		if not m then return end
		W.Modal({ title = "Remove from guild", text = ("Remove %s from the guild?"):format(m.name), action = "Remove", danger = true,
			onAccept = function() C_GuildInfo.RemoveFromGuild(m.guid); detailId = nil; M.Show() end })
	end, { danger = true })
	d.Remove:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 24, 16)
	d.Invite = W.Button(d, "Group invite", function()
		local m = detailMember()
		if m then C_PartyInfo.InviteUnit(m.name) end
	end, { primary = true })
	d.Invite:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -24, 16)
	ns.DockFlyout(f, d, 1)
	f.psDetail = d
end

local function paintDetail()
	local d = f.psDetail
	local m = page == "roster" and detailMember()
	d:SetShown(m and true or false)
	if not m then return end
	local file, className = classFile(m)
	local c = file and RAID_CLASS_COLORS[file]
	d.Name:SetText(m.name or "")
	W.Uncolor(d.Name)
	if c then d.Name:SetTextColor(Theme.Legible(c.r, c.g, c.b)) else W.Color(d.Name, "text") end
	d.Line:SetText(m.level and ("Level %d %s"):format(m.level, className or "") or "")
	d.Where:SetText(online(m) and not mobile(m) and m.zone or "")
	d.Online:SetText(online(m) and (mobile(m) and "On the mobile app" or "Online") or whereText(m))
	-- Rank: a menu where the player may move it (the stock rule), else text.
	local mine = me()
	local mo, o, max = mine and mine.guildRankOrder or 99, m.guildRankOrder or 0, GuildControlGetNumRanks()
	local canMove = (CanGuildPromote() and o > mo + 1) or (CanGuildDemote() and o < max and o > mo)
	d.Rank:SetText(m.guildRank or "")
	d.Rank:SetShown(not canMove)
	W.SetButtonText(d.RankPick, m.guildRank or "")
	d.RankPick:SetShown(canMove)
	local canNote = m.isSelf or CanEditPublicNote()
	d.Note.Text:SetText((m.memberNote or "") ~= "" and m.memberNote or "No note")
	W.Color(d.Note.Text, (m.memberNote or "") ~= "" and "text" or "textMuted")
	d.Note.Edit:SetShown(canNote and true or false)
	local view = C_GuildInfo.CanViewOfficerNote()
	for _, k in ipairs({ "Label", "Text", "Edit" }) do d.Officer[k]:SetShown(view) end
	if view then
		d.Officer.Text:SetText((m.officerNote or "") ~= "" and m.officerNote or "No note")
		W.Color(d.Officer.Text, (m.officerNote or "") ~= "" and "text" or "textMuted")
		d.Officer.Edit:SetShown(C_GuildInfo.CanEditOfficerNote())
	end
	ns.SetEnabled(d.Remove, not m.isSelf and CanGuildRemove() and o > mo, m.isSelf and "Leave the guild from the footer instead."
		or "Only a higher rank with the right can remove members.")
	ns.SetEnabled(d.Invite, online(m) and not m.isRemoteChat and not mobile(m), "They are not in the game.")
end

---------------------------------------------------------------------------
-- The other pages: a list of sections, paragraphs and item rows.

local lines = {}

local function newLine(p)
	local r = CreateFrame("Button", nil, p)
	r:SetPoint("RIGHT", p, "RIGHT", 0, 0)
	W.Hover(r)
	r.Head = W.SectionHeader(r)
	r.Head:SetAllPoints(r)
	r.Edit = W.Button(r, "Edit", function(self) self:GetParent().psEntry.edit() end, { ghost = true })
	r.Edit:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", 0, 4)
	r.Icon = ns.GameIcon(r)
	r.Icon:SetSize(28, 28)
	r.Icon:SetPoint("LEFT", r, "LEFT", 8, 0)
	r.Glyph = W.Tex(r, "ARTWORK", "star", "accent")
	r.Glyph:SetSize(12, 12)
	r.Text = W.Text(r, "default", "text")
	r.Text:SetJustifyH("LEFT")
	r.Sub = W.Text(r, "small", "textDim")
	r.Sub:SetJustifyH("LEFT")
	r.Sub:SetWordWrap(false)
	r.Right = W.Text(r, "small", "textDim")
	r.Right:SetJustifyH("RIGHT")
	r.Bar = W.ProgressLine(r, 2)
	r.Bar:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 8)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:SetScript("OnClick", function(self, button)
		local e = self.psEntry
		if e.link and IsModifiedClick("CHATLINK") then return ChatFrameUtil.LinkItem(e.linkId, e.link) end
		if button == "RightButton" and e.menu then
			if W.MenuShown(self) then return W.HideMenu() end
			return W.ShowMenu(self, e.menu(), { minWidth = 200 })
		end
	end)
	r:SetScript("OnEnter", function(self)
		local e = self.psEntry
		if not e.tip then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		e.tip()
		if e.menu then ns.TooltipHint("Right-click for more.") end
		GameTooltip:Show()
	end)
	r:SetScript("OnLeave", W.HideTooltip)
	return r
end

-- Entries: { section = text, count?, edit? }, { para = text, dim? },
-- { text, sub?, right?, rightColor?, icon?, glyph?, color?, tip?, menu?, link?, linkId? },
-- { bar = frac, text, right }.
local function paintLines(list)
	local p, y = f.psLines, 0
	local w = f.BodyWidth
	for i, e in ipairs(list) do
		local r = lines[i] or newLine(p)
		lines[i] = r
		r.psEntry = e
		for _, k in ipairs({ "Head", "Edit", "Icon", "Glyph", "Text", "Sub", "Right", "Bar" }) do r[k]:Hide() end
		r:EnableMouse(e.tip ~= nil or e.menu ~= nil or e.link ~= nil)
		local h
		if e.section then
			W.SetSection(r.Head, e.section, e.count)
			r.Head:Show()
			r.Edit:SetShown(e.edit ~= nil)
			if e.edit then r.Head.Rule:SetPoint("RIGHT", r.Edit, "LEFT", -12, 0) end
			h = 44
		elseif e.para then
			r.Text:ClearAllPoints()
			r.Text:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -8)
			r.Text:SetWidth(w)
			r.Text:SetWordWrap(true)
			r.Text:SetText(e.para)
			W.Uncolor(r.Text)
			W.Color(r.Text, e.dim and "textMuted" or "text")
			r.Text:Show()
			h = math.ceil(r.Text:GetStringHeight()) + 16
		elseif e.bar then
			r.Text:ClearAllPoints()
			r.Text:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -10)
			r.Text:SetWidth(w - 120)
			r.Text:SetWordWrap(false)
			r.Text:SetText(e.text)
			W.Uncolor(r.Text)
			W.Color(r.Text, "text")
			r.Text:Show()
			r.Right:SetText(e.right or "")
			r.Right:ClearAllPoints()
			r.Right:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -12)
			W.Color(r.Right, "textDim")
			r.Right:Show()
			W.SetProgress(r.Bar, e.bar, w)
			r.Bar:Show()
			h = 44
		else
			local x = 12
			if e.icon then r.Icon:SetTexture(e.icon); r.Icon:SetDesaturated(e.desat or false); r.Icon:Show(); x = 48 end
			if e.glyph then
				r.Glyph:SetTexture(Theme.Media(e.glyph))
				r.Glyph:ClearAllPoints()
				r.Glyph:SetPoint("LEFT", r, "LEFT", x, 0)
				r.Glyph:Show()
				x = x + 18
			end
			local sub = e.sub and e.sub ~= ""
			local right = e.right and 140 or 12
			r.Text:ClearAllPoints()
			r.Text:SetPoint(sub and "BOTTOMLEFT" or "LEFT", r, "LEFT", x, sub and 1 or 0)
			r.Text:SetPoint("RIGHT", r, "RIGHT", -right, 0)
			r.Text:SetWordWrap(false)
			r.Text:SetText(e.text or "")
			W.Uncolor(r.Text)
			W.Color(r.Text, e.color or "text")
			r.Text:Show()
			if sub then
				r.Sub:ClearAllPoints()
				r.Sub:SetPoint("TOPLEFT", r, "LEFT", x, -3)
				r.Sub:SetPoint("RIGHT", r, "RIGHT", -right, 0)
				r.Sub:SetText(e.sub)
				r.Sub:Show()
			end
			if e.right then
				r.Right:ClearAllPoints()
				r.Right:SetPoint("RIGHT", r, "RIGHT", -12, 0)
				r.Right:SetWidth(right - 20)
				r.Right:SetText(e.right)
				W.Color(r.Right, e.rightColor or "textDim")
				r.Right:Show()
			end
			h = (e.icon or sub) and 40 or ROW_H + 4
		end
		r:SetHeight(h)
		r:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -y)
		y = y + h
		r:Show()
	end
	for i = #list + 1, #lines do lines[i]:Hide() end
	p:SetHeight(math.max(1, y))
	return 8 + y + 24
end

-- Info: the stock Guild Info tab.
local function infoLines()
	local out = {}
	local motd = C_GuildInfo.GetMOTD() or ""
	out[#out + 1] = { section = "Message of the day", edit = CanEditMOTD() and function()
		editText("Message of the day", "Every member sees it as they log in.", C_GuildInfo.GetMOTD(), 255,
			function(t) C_GuildInfo.SetMOTD(t) end)
	end or nil }
	out[#out + 1] = { para = motd ~= "" and motd or "No message of the day.", dim = motd == "" }
	local info = C_GuildInfo.GetInfoText() or ""
	out[#out + 1] = { section = "Guild information", edit = CanEditGuildInfo() and function()
		editText("Guild information", "What the guild is about, for every member.", C_GuildInfo.GetInfoText(), 499,
			function(t) C_GuildInfo.SetInfoText(t); M.Show() end, true)
	end or nil }
	out[#out + 1] = { para = info ~= "" and info or "No guild information.", dim = info == "" }
	local n, done = GetNumGuildChallenges(), 0
	if n > 0 then
		local list = {}
		for i = 1, n do
			local id, cur, max = GetGuildChallengeInfo(i)
			if id then
				if cur == max then done = done + 1 end
				list[#list + 1] = { text = _G["GUILD_CHALLENGE_TYPE" .. id] or ("Challenge " .. id), glyph = cur == max and "check" or nil,
					right = cur == max and "Done" or ("%d/%d"):format(cur, max), rightColor = cur == max and "success" or "textDim" }
			end
		end
		out[#out + 1] = { section = "Guild challenges", count = ("%d/%d"):format(done, #list) }
		for _, e in ipairs(list) do out[#out + 1] = e end
	end
	return out, n > 0 and ("%d of %d challenges done this week"):format(done, n) or nil
end

-- News: the stock news list (GuildNewsButton_SetNews), with the MOTD and
-- the guild's calendar events first.
local WEEKDAYS = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }
local NEWS_TEXT = {
	[0] = "The guild earned %s", [1] = "%s earned %s", [2] = "%s defeated %s", [3] = "%s got %s", [4] = "%s crafted %s",
	[5] = "%s bought %s", [6] = "The guild reached a new level%.0s%.0s", [7] = "%s founded the guild%.0s", [8] = "%s got %s",
}
local function isLoot(t) return t == 3 or t == 4 or t == 5 or t == 8 end

local function newsMenu(i, n)
	local items = {}
	if n.newsType == 0 or n.newsType == 1 then
		items[#items + 1] = { text = "View achievement", onClick = function() ShowAchievementFrameForAchievement(n.newsDataID) end }
	elseif isLoot(n.newsType) then
		items[#items + 1] = { text = "Link item", onClick = function() ChatFrameUtil.LinkItem(n.newsDataID, n.whatText) end }
	end
	if CanEditMOTD() then
		items[#items + 1] = { text = n.isSticky and "Remove sticky" or "Make sticky", onClick = function() GuildNewsSetSticky(i, n.isSticky and 0 or 1) end }
	end
	return #items > 0 and items or nil
end

local function newsLines()
	local out, count = {}, 0
	if CanReplaceGuildMaster() then
		out[#out + 1] = { text = "Your guild master has been away a long time.", sub = "Right-click to take the lead.", glyph = "flag", color = "warning",
			tip = function() GameTooltip:SetText("Impeach the guild master"); tipLine("You may become the guild master in their place.", "text") end,
			menu = function() return { { text = "Impeach the guild master", onClick = function()
				W.Modal({ title = "Impeach the guild master", text = "Become guild master in place of the inactive one?", action = "Impeach", danger = true,
					onAccept = function() ReplaceGuildMaster() end })
			end } } end }
	end
	local motd = C_GuildInfo.GetMOTD() or ""
	if motd ~= "" then
		out[#out + 1] = { text = "Message of the day: " .. motd, glyph = "info",
			tip = function() GameTooltip:SetText("Message of the day"); tipLine(motd, "text") end }
	end
	local today = date("*t")
	for i = 1, math.min(7, C_Calendar.GetNumGuildEvents()) do
		local ev = C_Calendar.GetGuildEventInfo(i)
		if ev then
			local day = (ev.monthDay == today.day and ev.month == today.month) and "Today" or WEEKDAYS[ev.weekday] or ""
			out[#out + 1] = { text = ev.title or "", glyph = "hourglass", right = ("%s %02d:%02d"):format(day, ev.hour or 0, ev.minute or 0) }
		end
	end
	for i = 1, GetNumGuildNews() do
		local n = C_GuildInfo.GetGuildNewsInfo(i)
		if n and n.isHeader then
			out[#out + 1] = { section = ("%s, %d/%d"):format(WEEKDAYS[(n.weekday or 0) + 1] or "", (n.month or 0) + 1, (n.day or 0) + 1) }
		elseif n then
			count = count + 1
			local who, what = n.whoText or "Unknown", n.whatText or "Unknown"
			if n.newsType == 0 then who = what end
			local e = { text = (NEWS_TEXT[n.newsType] or "%s: %s"):format(who, what), glyph = n.isSticky and "star" or nil }
			if isLoot(n.newsType) and n.whatText then
				e.link, e.linkId = n.whatText, n.newsDataID
				e.tip = function() GameTooltip:SetHyperlink(n.whatText) end
			elseif (n.newsType == 0 or n.newsType == 1) and n.newsDataID then
				e.tip = function()
					local _, name, _, _, _, _, _, desc = GetAchievementInfo(n.newsDataID)
					GameTooltip:SetText(name or what)
					if desc then tipLine(desc, "text") end
				end
			elseif n.newsType == 2 then
				e.tip = function() GameTooltip:SetText(what); tipLine(n.data and GetRealZoneText(n.data[1]) or "", "text") end
			end
			e.menu = newsMenu(i, n) and function() return newsMenu(i, n) end
			out[#out + 1] = e
		end
	end
	return out, count
end

-- The stock news filters (CommunitiesGuildNewsFiltersFrame), hidden as stock.
local NEWS_FILTERS = {
	{ 1, "Guild achievements", function() return C_AchievementInfo.AreGuildAchievementsEnabled() end },
	{ 2, "Achievements", function() return CanShowAchievementUI() end },
	{ 3, "Dungeon encounters", function() return C_GuildInfo.IsEncounterGuildNewsEnabled() end },
	{ 4, "Epic items looted" }, { 5, "Epic items purchased" }, { 6, "Epic items crafted" }, { 9, "Legendary items looted" },
}
local function newsFilterItems()
	local on, items = { GetGuildNewsFilters() }, {}
	for _, o in ipairs(NEWS_FILTERS) do
		local id = o[1]
		if not o[3] or o[3]() then
			items[#items + 1] = { text = o[2], checked = on[id] and true or false, onClick = function()
				SetGuildNewsFilter(id, on[id] and 0 or 1)
				M.Show()
				W.ShowMenu(f.psFilter, newsFilterItems(), { minWidth = 200 })
			end }
		end
	end
	return items
end

-- Benefits: the stock Guild Benefits tab.
local function benefitsOn()
	return GetNumGuildPerks() > 0 or C_GuildInfo.IsGuildReputationEnabled()
end

local function benefitLines()
	local out = {}
	local rep = C_GuildInfo.IsGuildReputationEnabled() and C_Reputation.GetGuildFactionData()
	if rep then
		local lo, hi = rep.currentReactionThreshold or 0, rep.nextReactionThreshold or 1
		local frac = hi > lo and (rep.currentStanding - lo) / (hi - lo) or 1
		out[#out + 1] = { bar = math.max(0, math.min(1, frac)),
			text = ("%s: %s"):format(rep.name or "Guild reputation", _G["FACTION_STANDING_LABEL" .. (rep.reaction or 4)] or ""),
			right = hi > lo and ("%d/%d"):format(rep.currentStanding - lo, hi - lo) or "" }
	end
	local np = GetNumGuildPerks()
	if np > 0 then
		out[#out + 1] = { section = "Perks", count = tostring(np) }
		for i = 1, np do
			local name, spellID, icon = GetGuildPerkInfo(i)
			local link = C_Spell.GetSpellLink(spellID)
			out[#out + 1] = { text = name, icon = icon, link = link, tip = function() GameTooltip:SetHyperlink(link) end }
		end
	end
	local list = {}
	for i = 1, GetNumGuildRewards() do
		local achievementID, itemID, itemName, icon, repLevel, cost = GetGuildRewardInfo(i)
		if achievementID ~= nil then
			local needs, desat
			if achievementID > 0 then
				needs, desat = "Requires " .. (select(2, GetAchievementInfo(achievementID)) or "an achievement"), true
			elseif rep and repLevel and repLevel > (rep.reaction or 0) then
				needs = "Requires " .. (_G["FACTION_STANDING_LABEL" .. repLevel] or "a higher standing")
			end
			local short = cost and cost > 0 and GetMoney() < cost
			list[#list + 1] = { text = itemName, icon = icon, desat = desat, color = desat and "textMuted" or "text", sub = needs,
				right = cost and cost > 0 and ns.Coins(cost) or nil, rightColor = short and "danger" or "textDim",
				link = "item:" .. itemID, linkId = itemID,
				tip = function()
					GameTooltip:SetHyperlink("item:" .. itemID)
					if needs then tipLine(needs, "danger") end
				end,
				menu = function()
					local items = { { text = "Link item", onClick = function() ChatFrameUtil.LinkItem(itemID) end } }
					if achievementID > 0 then items[2] = { text = "View achievement", onClick = function() ShowAchievementFrameForAchievement(achievementID) end } end
					return items
				end }
		end
	end
	if #list > 0 then
		out[#out + 1] = { section = "Rewards", count = tostring(#list) }
		for _, e in ipairs(list) do out[#out + 1] = e end
	end
	return out, ("%d perks · %d rewards"):format(np, #list)
end

-- Log: the stock guild log (CommunitiesGuildLogFrame_Update), newest first.
local LOG_TEXT = {
	invite = "%s invited %s", join = "%s joined the guild%.0s", promote = "%s promoted %s to %s", demote = "%s demoted %s to %s",
	remove = "%s removed %s", quit = "%s left the guild%.0s",
}
local function logLines()
	local out = {}
	for i = GetNumGuildEvents(), 1, -1 do
		local kind, p1, p2, rank, y, mo, d, h = GetGuildEventInfo(i)
		if LOG_TEXT[kind] then
			out[#out + 1] = { text = LOG_TEXT[kind]:format(p1 or "Unknown", p2 or "Unknown", rank or ""), right = ago(y, mo, d, h) }
		end
	end
	return out
end

---------------------------------------------------------------------------
-- Actions (footer) and the window.

local function invite()
	editText("Invite member", "The character to invite to your guild.", "", 48, function(t)
		t = strtrim(t)
		if t ~= "" then C_GuildInfo.Invite(t) end
	end)
end

local function leave()
	W.Modal({ title = "Leave guild", text = ("Leave %s?"):format(keep("guild", (GetGuildInfo("player"))) or "the guild"), action = "Leave", danger = true,
		onAccept = function() C_GuildInfo.Leave() end })
end

local optionsItems = {
	{ text = "Game's window: shift-click the guild button", disabled = true },
	{ text = "There: communities, chat, Guild Finder and recruitment", disabled = true },
}

local function count(n, one) return ("%d %s"):format(n, n == 1 and one or one .. "s") end

local function filterItems()
	if page == "news" then return newsFilterItems() end
	local items = { { text = "Show offline members", checked = showOffline(), onClick = function()
		SetCVar("communitiesShowOffline", showOffline() and "0" or "1")
		M.Show()
	end } }
	local any = false
	for _, k in ipairs({ "prof", "score" }) do
		local c = EXTRA[k]
		if c.can() then
			if not any then items[#items + 1] = { separator = true }; items[#items + 1] = { text = "Extra column", disabled = true }; any = true end
			items[#items + 1] = { text = c.label, checked = extra == k, onClick = function()
				extra = extra ~= k and k or nil
				if sortKey == k then sortKey = nil end
				M.Show()
			end }
		end
	end
	return items
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 960, height = 600, sidebar = 240, searchPlaceholder = "Search the roster",
		onSearch = function(text)
			query = (text or ""):lower()
			if query ~= "" then page = "roster" end
			if f:IsShown() then M.Show() end
		end })
	ns.Dock(f)
	ns.WindowMenu(f, "guild", optionsItems)
	local b = ns.SubjectBlock(f)
	f.psEmblem, f.psName, f.psLine = b.icon, b.name, b.line
	-- The roster's options and the news filters end the search row (as Social).
	f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		W.ShowMenu(self, filterItems(), { minWidth = 200 })
	end, 14)
	f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -(W.SHELL.header - 30))
	Theme.Skin(f.psFilter, "editbox")
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + 36), -(W.SHELL.header - 30))
	local R = CreateFrame("Frame", nil, f.Body)
	R:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -8)
	R:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	R:SetHeight(1)
	R.Rows = W.RowPanel(R)
	R.Rows:SetPoint("TOPLEFT", R, "TOPLEFT", 0, -HEAD_H)
	R.Rows:SetPoint("RIGHT", R, "RIGHT", 0, 0)
	f.psRoster = R
	f.psLines = CreateFrame("Frame", nil, f.Body)
	f.psLines:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -8)
	f.psLines:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	f.psEmpty:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	f.psEmpty:SetJustifyH("LEFT")
	f.psEmpty:SetWordWrap(true)
	-- Rows follow the scroll (only the seen ones are drawn).
	hooksecurefunc(f.Scroll, "SetVerticalScroll", function() if page == "roster" then paintVisible() end end)
	buildDetail()
	-- The stock window's sounds: it never opens now to play them.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end)
	Polestar.CloseOnEscape(NAME)
end

local function refresh()
	local inGuild = IsInGuild()
	if not inGuild then page = "none" elseif page == "none" or (page == "benefits" and not benefitsOn()) then page = "roster" end
	local guild, rank = GetGuildInfo("player")
	guild, rank = keep("guild", guild), keep("rank", rank)
	local all = readRoster()
	local on = 0
	for _, m in ipairs(all) do if online(m) then on = on + 1 end end
	local tabard = inGuild and C_GuildInfo.GetGuildTabardInfo("player")
	f.psEmblem:SetTexture(tabard and tabard.emblemFileID or 135026) -- else a guild banner icon
	f.psName:SetText(inGuild and (guild or "Guild") or "No guild")
	f.psLine:SetText(inGuild and ("%s · %s"):format(rank or "", count(#all, "member")) or "Not in a guild")
	local nav
	if inGuild then
		nav = { { key = "roster", label = "Roster", icon = "compact", count = on }, { key = "info", label = "Info", icon = "info" },
			{ key = "news", label = "News", icon = "flag" } }
		if benefitsOn() then nav[#nav + 1] = { key = "benefits", label = "Benefits", icon = "star" } end
		nav[#nav + 1] = { key = "log", label = "Log", icon = "icon-note" }
	else
		nav = { { key = "none", label = "Guild", icon = "flag" } }
	end
	W.ShellNav(f, nav, page, function(k) M.Show(k) end)
	W.ShellTabs(f, nil)
	f.psFilter:SetShown(page == "roster" or page == "news")
	local filtersOn = page == "roster" and (showOffline() or extra ~= nil)
	if page == "news" then for _, v in ipairs({ GetGuildNewsFilters() }) do if not v then filtersOn = true end end end
	W.SetIconState(f.psFilter, filtersOn)
	f.psFilter.psTip = page == "news" and "News filters" or "Roster options"
	if inGuild then
		local leader = IsGuildLeader()
		-- The first is the rightmost: Invite member, then Guild control (the
		-- stock button, the master's and officers'), then Guild chat.
		local right = { { label = "Invite member", onClick = invite, opts = { primary = true } } }
		if leader or C_GuildInfo.IsGuildOfficer() then
			right[#right + 1] = { label = "Guild control", onClick = function() GuildControlUI_Show() end }
		end
		right[#right + 1] = { label = "Guild chat", onClick = function() ChatFrameUtil.OpenChat(SLASH_GUILD1 .. " ") end }
		ns.Footer(f, { { label = "Leave guild", onClick = leave } }, right)
		local fb = f.footerButtons
		ns.SetEnabled(fb.left[1], not leader, "The guild master can't leave: make another member guild master first.")
		ns.SetEnabled(fb.right[1], CanGuildInvite(), "Your rank can't invite members.")
		ns.SetEnabled(fb.right[#right], C_GuildInfo.CanSpeakInGuildChat(), "Your rank can't speak in guild chat.")
	else
		ns.Footer(f, {}, {})
	end
	f.psRoster:SetShown(page == "roster")
	f.psLines:SetShown(page ~= "roster" and page ~= "none")
	f.psEmpty:Hide()
	local h
	if page == "roster" then
		W.ShellTitle(f, "Roster", ("%d of %d online"):format(on, #all))
		h = paintRoster()
	elseif page == "none" then
		W.ShellTitle(f, "Guild", "Not in a guild")
		f.psEmpty:SetText("You are not in a guild. Guild Finder and communities are on the game's window: shift-click the guild button on the bar.")
		f.psEmpty:ClearAllPoints()
		f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
		f.psEmpty:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
		f.psEmpty:Show()
		h = 80
	else
		local list, status
		if page == "info" then list, status = infoLines()
		elseif page == "news" then
			local n
			list, n = newsLines()
			status = count(n, "news item")
			if #list == 0 then list = { { para = "No guild news yet.", dim = true } } end
		elseif page == "benefits" then list, status = benefitLines()
		else
			list = logLines()
			status = count(#list, "event")
			if #list == 0 then list = { { para = "Nothing in the guild log yet.", dim = true } } end
		end
		W.ShellTitle(f, ({ info = "Info", news = "News", benefits = "Benefits", log = "Log" })[page], status)
		h = paintLines(list)
	end
	paintDetail()
	W.ShellBody(f, h)
end

-- What each page asks the client for as it opens, as the stock tabs do.
local ASK = {
	roster = function() C_GuildInfo.GuildRoster() end,
	info = function() C_GuildInfo.GuildRoster(); RequestGuildChallengeInfo() end,
	news = function() C_Calendar.OpenCalendar(); QueryGuildNews(); GuildNewsSort(0) end,
	benefits = function() RequestGuildRewards() end,
	log = function() QueryGuildEventLog() end,
}

function M.Show(key)
	if not f then build() end
	local was = page
	page = key or page
	if page ~= was or not f:IsShown() then
		if ASK[page] and IsInGuild() then ASK[page]() end
		if page ~= was then W.ScrollTo(f.Scroll, 0) end
	end
	refresh()
	f:Show()
end

function M.Toggle()
	-- As ToggleGuildFrame: nothing for a Neutral character.
	if UnitFactionGroup("player") == "Neutral" then return end
	if f and f:IsShown() then f:Hide() else M.Show() end
end

function M.Enable()
	-- The key and micro button open ours; the stock window is never touched
	-- (docs/CLIENT.md, rule 8).
	ns.Doors("guild", "Guild", { TOGGLEGUILDTAB = M.Toggle }, GuildMicroButton, M.Toggle)
	local function changed() if f and f:IsShown() then refresh() end end
	for _, ev in ipairs({ "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "GUILD_MOTD", "GUILD_RANKS_UPDATE", "GUILD_NEWS_UPDATE",
		"GUILD_REWARDS_LIST", "GUILD_REWARDS_LIST_UPDATE", "GUILD_EVENT_LOG_UPDATE", "GUILD_CHALLENGE_UPDATED", "CALENDAR_UPDATE_GUILD_EVENTS",
		"CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED", "CLUB_MEMBER_UPDATED", "CLUB_MEMBERS_UPDATED", "CLUB_MEMBER_PRESENCE_UPDATED",
		"INITIAL_CLUBS_LOADED", "PLAYER_REGEN_ENABLED", "PLAYER_MONEY" }) do
		Polestar.RegisterEvent(ev, changed)
	end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return CommunitiesFrame and CommunitiesFrame:IsShown() and CommunitiesFrame end

ns.Module("guild", M)
