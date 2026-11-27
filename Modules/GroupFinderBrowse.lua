-- Group Finder: the Browse page (docs/windows/groupfinder.md): the stock
-- LFGBrowseFrame (Blizzard_LFGVanilla_Browse.lua) on our own tables. The tab
-- row holds the category and activity pickers, the options menu and Refresh;
-- the list is the search results with every member display, a tooltip, a
-- selection for Send Message and Group Invite, and the right-click menu.
-- C_LFGList.Search is restricted to a hardware event: it runs only from our
-- clicks (Refresh, a category, an activity group, Reset), never on show or an
-- event. Unlist is the game's window (RemoveListing is protected live).
-- Names go to font strings as given (ns.Clean), comments (kstrings) only to
-- SetText or a tooltip line: never compared, measured or joined.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme
local G = ns.GroupFinder

local ROW_H, HEAD_H, GAP, TOP = 44, 30, 2, 8
local IGNORE_LEVELS = "disableSuggestedLevelActivityFilter"
local DT = Enum.LFGListDisplayType or {}
-- If a listing has activities of several display types, the most telling one (LFGBROWSE_DISPLAYTYPE_PRIORITY).
local PRIORITY = { [5] = 6, [0] = 5, [4] = 4, [1] = 3, [2] = 2, [3] = 1 }
local ROLES = { "TANK", "HEALER", "DAMAGER" }
local ROLE_ATLAS = { TANK = "groupfinder-icon-role-large-tank", HEALER = "groupfinder-icon-role-large-heal", DAMAGER = "groupfinder-icon-role-large-dps" }
local SOLO_ATLAS = { "groupfinder-icon-role-micro-tank", "groupfinder-icon-role-micro-heal", "groupfinder-icon-role-micro-dps" }
local ROLE_NAME = { TANK = TANK or "Tank", HEALER = HEALER or "Healer", DAMAGER = DAMAGER or "Damage" }
local VOICE = { [0] = VOICE_CHAT_MODE_NONE or "None", VOICE_CHAT_MODE_LEGACY or "Legacy", VOICE_CHAT_MODE_DISCORD or "Discord", VOICE_CHAT_MODE_CUSTOM or "Custom" }
local SOLO, GROUP = 1, 2

local L = C_LFGList or {}
local f, panel, empty, catButton, actButton, optButton, refresh
local rows, heads = {}, {}
local category, chosen = 0, {} -- the category picked (0: none) and the activities ticked
local searching, failed, selected, shown = false, false, nil, false
local waiting = false -- picked for Refresh to search (after a Post: its click is spent)
local collapsed = {}

local function call(name, ...) if L[name] then return L[name](...) end end
local function info(id) return call("GetActivityInfoTable", id) end
local function activityName(a) return a and (a.shortName ~= "" and a.shortName or a.fullName) or "" end
local function less(a, b) if strcmputf8i then return strcmputf8i(a, b) < 0 end return a < b end
local function entry() return call("GetActiveEntryInfo") end
local function inGroup() return IsInGroup and IsInGroup() or false end
local function leads() return not inGroup() or (UnitIsGroupLeader and UnitIsGroupLeader("player")) end

-- The activities of a category the player is in level for, unless the
-- options say to ignore level ranges; the listing's own always stay
-- (LFGUtil_GetFilteredActivities).
local function activities(cat)
	local all, out = call("GetAvailableActivities", cat) or {}, {}
	local mine = entry()
	local level, ignore = ns.Num(UnitLevel("player")), GetCVarBool(IGNORE_LEVELS)
	for _, id in ipairs(all) do
		local a = info(id)
		local off = a and ((a.minLevelSuggestion > 0 and a.minLevelSuggestion > level) or (a.maxLevelSuggestion > 0 and a.maxLevelSuggestion < level))
		if ignore or not off or (mine and tContains(mine.activityIDs, id)) then out[#out + 1] = id end
	end
	return out
end

-- Activities by activity group (0: none), each sorted, and the groups in
-- order (LFGUtil_OrganizeActivitiesByActivityGroup, LFGUtil_Sort*).
local function byGroup(ids)
	local groups, order = {}, {}
	for _, id in ipairs(ids) do
		local a = info(id)
		if a then
			local g = a.groupFinderActivityGroupID or 0
			if not groups[g] then groups[g] = {}; order[#order + 1] = g end
			table.insert(groups[g], id)
		end
	end
	for _, list in pairs(groups) do
		table.sort(list, function(x, y)
			local a, b = info(x), info(y)
			if a.orderIndex ~= b.orderIndex then return a.orderIndex < b.orderIndex end
			local n1, n2 = activityName(a), activityName(b)
			if n1 ~= n2 then return less(n1, n2) end
			return x < y
		end)
	end
	table.sort(order, function(x, y)
		local n1, o1 = call("GetActivityGroupInfo", x)
		local n2, o2 = call("GetActivityGroupInfo", y)
		if o1 and o2 and o1 ~= o2 then return o1 < o2 end
		if n1 and n2 and n1 ~= n2 then return less(n1, n2) end
		return x < y
	end)
	return groups, order
end

---------------------------------------------------------------------------
-- Searching: only from a click of ours (the client refuses it elsewhere).

-- A search the client never answers (no results, no failure event: live, the
-- page stayed on "Searching" with Refresh greyed) ends after TIMEOUT as a
-- failed one; Refresh always searches again, even while one runs.
local TIMEOUT, token = 10, 0
local function doSearch()
	if category == 0 or not L.Search then return end
	local ids = #chosen > 0 and chosen or activities(category)
	L.Search(category, 0, 0, nil, false, nil, ids)
	searching, failed, selected, waiting = true, false, nil, false
	token = token + 1
	local mine = token
	if C_Timer and C_Timer.After then
		C_Timer.After(TIMEOUT, function()
			if searching and mine == token then
				searching, failed = false, true
				if shown and f:IsShown() then G.Paint() end
			end
		end)
	end
	G.Paint()
end

local function setCategory(id)
	category, chosen = id, {}
	doSearch()
	G.Paint()
end

-- These activities picked, in the first one's category, and searched
-- (LFGBrowseMixin:SetSelectedSearchActivities, then the search). `wait`: picked
-- only, for Refresh: a hardware event allows one restricted call, so after
-- Post's CreateListing/UpdateListing a Search in the same click is blocked.
local function searchFor(ids, wait)
	chosen = {}
	for _, id in ipairs(ids or {}) do
		local a = info(id)
		if a then
			if #chosen == 0 then category = a.categoryID end
			if a.categoryID == category then chosen[#chosen + 1] = id end
		end
	end
	if wait then waiting, selected = true, nil else doSearch() end
	G.Paint()
end
G.SearchFor = searchFor -- the Listing page's Post (as LFGParentFrame_SearchActiveEntry)

-- "Your listing" (SearchActiveEntry).
local function searchMine() local e = entry(); searchFor(e and e.activityIDs) end

local function categoryMenu(anchor)
	if W.MenuShown(anchor) then return W.HideMenu() end
	local items, cats = {}, call("GetAvailableCategories") or {}
	if entry() then items[1] = { text = LFG_SELF_LISTING or "Your listing", onClick = searchMine } end
	for _, id in ipairs(cats) do
		local c = call("GetLfgCategoryInfo", id)
		if c and #activities(id) > 0 then
			items[#items + 1] = { text = c.name, checked = category == id, onClick = function() setCategory(id) end }
		end
	end
	if #items == 0 then items[1] = { text = LFG_TYPE_NONE or "None", disabled = true } end
	W.ShowMenu(anchor, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT", minWidth = 180, current = true })
end

local function isChosen(id) return tContains(chosen, id) end
local function setChosen(id, on)
	if on and not isChosen(id) then chosen[#chosen + 1] = id elseif not on then tDeleteItem(chosen, id) end
end

-- The activity filter: a group's tick sets all of it and searches, an
-- activity's toggles it alone; the menu opens again after each pick (flat:
-- each group, then its activities indented, as the stock submenus).
local function activityMenu(anchor, again)
	if not again and W.MenuShown(anchor) then return W.HideMenu() end
	local groups, order = byGroup(activities(category))
	local items = {}
	local function pick(fn) return function() fn(); G.Paint(); activityMenu(anchor, true) end end
	if #chosen > 0 then
		items[1] = { text = RESET or "Reset", onClick = function() chosen = {}; doSearch(); G.Paint() end }
		items[2] = { separator = true }
	end
	for _, g in ipairs(order) do
		local ids = groups[g]
		if g ~= 0 then
			local any = false
			for _, id in ipairs(ids) do if isChosen(id) then any = true end end
			items[#items + 1] = { text = (call("GetActivityGroupInfo", g)) or "", checked = any, onClick = pick(function()
				for _, id in ipairs(ids) do setChosen(id, not any) end
				doSearch()
			end) }
		end
		for _, id in ipairs(ids) do
			items[#items + 1] = { text = (g ~= 0 and "    " or "") .. activityName(info(id)), checked = isChosen(id),
				onClick = pick(function() setChosen(id, not isChosen(id)) end) }
		end
	end
	W.ShowMenu(anchor, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT", minWidth = 200 })
end

-- The stock options button: ignore level ranges (a CVar; CVAR_UPDATE resets the pickers as stock).
local function optionsMenu(anchor)
	if W.MenuShown(anchor) then return W.HideMenu() end
	W.ShowMenu(anchor, { { text = LFG_LIST_IGNORE_SUGGESTED_LEVEL or "Ignore level ranges", checked = GetCVarBool(IGNORE_LEVELS),
		onClick = function() SetCVar(IGNORE_LEVELS, GetCVarBool(IGNORE_LEVELS) and "0" or "1") end } }, { minWidth = 200 })
end

---------------------------------------------------------------------------
-- Results.

local function result(id) return call("GetSearchResultInfo", id) end

local function matches(r)
	local e, hit = entry(), {}
	if e then for _, id in ipairs(e.activityIDs) do if tContains(r.activityIDs, id) then hit[#hit + 1] = id end end end
	return hit
end

local function filtered(r)
	if #chosen == 0 then return true end
	for _, id in ipairs(r.activityIDs) do if isChosen(id) then return true end end
	return false
end

local function displayType(ids)
	local best, bp, most = nil, 0, 0
	for _, id in ipairs(ids) do
		local a = info(id)
		if a then
			local p = PRIORITY[a.displayType]
			if p and p > bp then best, bp = a.displayType, p end
			if a.maxNumPlayers > most then most = a.maxNumPlayers end
		end
	end
	return best, most
end

-- LFGBrowseUtil_SortSearchResults: own listing, matches to it, groups or solo
-- players first (by whether the player is in a group), then roles, size, age.
local function sortResults(list)
	local e = entry()
	local dungeonRoles = false
	for _, id in ipairs(e and e.activityIDs or {}) do local a = info(id); if a and a.useDungeonRoleExpectations then dungeonRoles = true end end
	local have = GetGroupMemberCounts and GetGroupMemberCounts()
	local mine = C_LFGListRoles and C_LFGListRoles.GetRoles and C_LFGListRoles.GetRoles() or {}
	local function slots(id)
		local c = call("GetSearchResultMemberCounts", id) or {}
		local t = (c.TANK_REMAINING or 0) > 0 and mine.tank or false
		local h = (c.HEALER_REMAINING or 0) > 0 and mine.healer or false
		local d = (c.DAMAGER_REMAINING or 0) > 0 and mine.dps or false
		return (t or h or d) and true or false, t, h
	end
	local hit = {}
	for _, id in ipairs(list) do hit[id] = #matches(result(id)) > 0 end
	table.sort(list, function(id1, id2)
		local a, b = result(id1), result(id2)
		if a.hasSelf ~= b.hasSelf then return a.hasSelf end
		if e and hit[id1] ~= hit[id2] then return hit[id1] end
		local s1, s2 = a.numMembers == 1, b.numMembers == 1
		if s1 ~= s2 then if inGroup() then return s1 end return s2 end
		if s1 then
			local order = { "TANK", "HEALER", "DAMAGER" }
			if dungeonRoles and have then
				for role, need in pairs({ TANK = 1, HEALER = 1, DAMAGER = 3 }) do
					if (have[role] or 0) >= need then tDeleteItem(order, role); order[#order + 1] = role end
				end
			end
			local c1, c2 = call("GetSearchResultMemberCounts", id1) or {}, call("GetSearchResultMemberCounts", id2) or {}
			for _, role in ipairs(order) do
				local p1, p2 = c1["LEADER_ROLE_" .. role] and true or false, c2["LEADER_ROLE_" .. role] and true or false
				if p1 ~= p2 then return p1 end
				if p1 then break end
			end
		else
			local h1, t1, he1 = slots(id1)
			local h2, t2, he2 = slots(id2)
			if h1 ~= h2 then return h1 end
			if a.numMembers ~= b.numMembers then return a.numMembers > b.numMembers end
			if (t1 and true or false) ~= (t2 and true or false) then return t1 and true or false end
			if (he1 and true or false) ~= (he2 and true or false) then return he1 and true or false end
		end
		if a.age ~= b.age then return a.age > b.age end
		return id1 < id2
	end)
end

-- The stock invite: only a solo listing, and only while the player may invite.
local function canInvite(r)
	return r and r.numMembers == 1 and r.leaderName and (not inGroup() or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and true or false
end

local function whisper(r) if r and r.leaderName then ChatFrameUtil.SendTell(r.leaderName) end end
local function invite(r) if canInvite(r) then C_PartyInfo.InviteUnit(r.leaderName) end end

-- Reports go through the game's report dialog (ReportFrame:InitiateReport,
-- as Social.lua). The stock "advertisement" shortcut sets the dialog's
-- category first; ours writes nothing into ReportFrame and opens the same dialog.
local function report(id, r)
	local ri = ReportInfo:CreateReportInfoFromType(Enum.ReportType.GroupFinderPosting)
	ri:SetGroupFinderSearchResultID(id)
	ReportFrame:InitiateReport(ri, r.leaderName)
end

local function rowMenu(row)
	local id = row.psID
	local r = result(id)
	if not r then return end
	W.ShowMenu(row, {
		{ text = ns.Clean(r.leaderName) or "", disabled = true },
		{ text = SEND_MESSAGE or "Send Message", disabled = not r.leaderName, onClick = function() whisper(r) end },
		{ text = GROUP_INVITE or "Group Invite", disabled = not canInvite(r), onClick = function() invite(r) end },
		{ text = LFG_LIST_REPORT_GROUP_FOR or "Report Group", onClick = function() report(id, r) end },
		{ text = REPORT_GROUP_FINDER_ADVERTISEMENT or "Report Advertisement", onClick = function() report(id, r) end },
	}, { point = "TOPLEFT", relPoint = "TOPRIGHT", x = -40, y = 0, minWidth = 180 })
end

---------------------------------------------------------------------------
-- The tooltip (LFGBrowseSearchEntryTooltip_UpdateAndShow), as game tooltip lines.

local function classRGB(file)
	local c = file and RAID_CLASS_COLORS[file]
	if c then return Theme.Legible(c.r, c.g, c.b) end
	return Theme.Color("text")
end

-- A member's level and roles: their LFG roles for a solo player, else the role assigned.
local function memberFacts(m, solo)
	local roles = {}
	if solo then
		local lr = m.lfgRoles or {}
		for i, on in ipairs({ lr.tank, lr.healer, lr.dps }) do if on then roles[#roles + 1] = ROLE_NAME[ROLES[i]] end end
	elseif ROLE_NAME[m.assignedRole] then
		roles[1] = ROLE_NAME[m.assignedRole]
	end
	local text = ("%s %d"):format(LEVEL_ABBR or "Lvl", ns.Num(m.level))
	if #roles > 0 then text = text .. " · " .. table.concat(roles, ", ") end
	return text
end

local function tooltip(row)
	local id = row.psID
	local r = result(id)
	if not r then return end
	local solo = r.numMembers == 1
	local counts = call("GetSearchResultMemberCounts", id) or {}
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	-- The leader heads it, in their class colour; then the group's members.
	local leader = call("GetSearchResultLeaderInfo", id)
	local tr, tg, tb = Theme.Color("text")
	GameTooltip:SetText(leader and ns.Clean(leader.name) or ns.Clean(r.leaderName) or "", classRGB(leader and leader.classFilename))
	if r.isDelisted then GameTooltip:AddLine(LFG_LIST_ENTRY_DELISTED or "This group is no longer listed.", Theme.Color("danger")) end
	if r.newPlayerFriendly and not r.isDelisted then GameTooltip:AddLine(LFG_LIST_NEW_PLAYER_FRIENDLY_HEADER or "New Player Friendly", Theme.Color("success")) end
	if leader and leader.name then
		local facts = memberFacts(leader, solo)
		GameTooltip:AddLine(solo and facts or ((LEADER or "Leader") .. " · " .. facts), Theme.Color("textDim"))
	end
	if not solo and r.numMembers <= 10 then
		local dr, dg, db = Theme.Color("textDim")
		for i = 1, r.numMembers do
			local m = call("GetSearchResultPlayerInfo", id, i)
			if m and m.name and not m.isLeader then
				local cr, cg, cb = classRGB(m.classFilename)
				GameTooltip:AddDoubleLine(ns.Clean(m.name) or "", memberFacts(m, false), cr, cg, cb, dr, dg, db)
			end
		end
	end
	local comment = ns.Clean(r.comment) -- a kstring: shown as given, never compared
	if comment then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(comment, Theme.Color("textDim"))
	end
	GameTooltip:AddLine(" ")
	if solo then
		GameTooltip:AddLine((LFG_LIST_TOOLTIP_MEMBERS_SIMPLE or "%d member"):format(r.numMembers), tr, tg, tb)
	else
		GameTooltip:AddLine((LFG_LIST_TOOLTIP_MEMBERS or "%d members (%d/%d/%d)"):format(r.numMembers, counts.TANK or 0, counts.HEALER or 0, counts.DAMAGER or 0), tr, tg, tb)
	end
	local voice = VOICE[r.voiceMode or 0]
	if voice then GameTooltip:AddLine((VOICE_CHAT_MODE_FORMAT or "Voice Chat: %s"):format(voice), Theme.Color("textDim")) end
	-- Activities by group; the ones the player's own listing has in the accent.
	local mine = entry()
	local groups, order = byGroup(r.activityIDs)
	GameTooltip:AddLine(" ")
	for _, g in ipairs(order) do
		local any, lines = false, {}
		for _, aid in ipairs(groups[g]) do
			local on = mine and tContains(mine.activityIDs, aid)
			any = any or on
			lines[#lines + 1] = { (g ~= 0 and "    " or "") .. activityName(info(aid)), on }
		end
		if g ~= 0 then GameTooltip:AddLine((call("GetActivityGroupInfo", g)) or "", Theme.Color(any and "accent" or "textDim")) end
		for _, l in ipairs(lines) do GameTooltip:AddLine(l[1], Theme.Color(l[2] and "accent" or "textDim")) end
	end
	local done = #r.activityIDs == 1 and call("GetSearchResultEncounterInfo", id)
	if done and #done > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LFG_LIST_BOSSES_DEFEATED or "Bosses Defeated:", tr, tg, tb)
		for _, name in ipairs(done) do GameTooltip:AddLine(name, Theme.Color("danger")) end
	end
	if not r.isDelisted and not filtered(r) then GameTooltip:AddLine(" "); GameTooltip:AddLine("Not in your activity filter.", Theme.Color("textMuted")) end
	if not r.isDelisted and not r.hasSelf then ns.TooltipHint("Click to select. Right-click for more.") end
	GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Rows.

local function newRow(i)
	local r = CreateFrame("Button", nil, panel)
	r:SetHeight(ROW_H)
	r.Ground = W.Fill(r, "panel")
	W.Hover(r)
	r.Sel = W.Painter(W.Tex(r, "BACKGROUND", nil, nil, -5), function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	r.Sel:SetAllPoints(r)
	r.Icon = r:CreateTexture(nil, "ARTWORK")
	r.Icon:SetSize(24, 24)
	r.Icon:SetPoint("LEFT", r, "LEFT", 10, 0)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("TOPLEFT", r, "TOPLEFT", 44, -7)
	r.Level = W.Text(r, "small", "textMuted")
	r.Level:SetPoint("LEFT", r.Name, "RIGHT", 6, 0)
	r.Voice = r:CreateTexture(nil, "ARTWORK")
	r.Voice:SetSize(14, 14)
	r.Voice:SetAtlas("UI-ChatIcon-Discord")
	r.Fresh = r:CreateTexture(nil, "ARTWORK")
	r.Fresh:SetSize(14, 14)
	r.Fresh:SetAtlas("newplayerchat-chaticon-newcomer")
	r.Sub = W.Text(r, "small", "textDim")
	r.Sub:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 44, 7)
	r.Comment = W.Text(r, "small", "textDim")
	r.Comment:SetPoint("RIGHT", r, "RIGHT", -10, 0)
	r.Comment:SetWidth(200)
	r.Comment:SetJustifyH("RIGHT")
	r.Icons, r.Counts = {}, {}
	for k = 1, 5 do
		r.Icons[k] = r:CreateTexture(nil, "ARTWORK")
		r.Icons[k]:SetSize(20, 20)
	end
	for k = 1, 3 do r.Counts[k] = W.Text(r, "number", "text") end
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:SetScript("OnClick", function(self, button)
		local res = result(self.psID)
		if not res or res.isDelisted or res.hasSelf then return end
		if button == "RightButton" then return rowMenu(self) end
		selected = selected ~= self.psID and self.psID or nil
		G.Paint() -- at once (docs/CLIENT.md, rule 6)
	end)
	r:SetScript("OnEnter", tooltip)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[i] = r
	return r
end

local function newHead(i)
	local h = CreateFrame("Button", nil, panel)
	h:SetHeight(HEAD_H)
	h.Chevron = W.Tex(h, "ARTWORK", "chevron-down", "textDim")
	h.Chevron:SetSize(12, 12)
	h.Chevron:SetPoint("LEFT", h, "LEFT", 2, 0)
	h.Text = W.Text(h, "label", "textDim")
	h.Text:SetPoint("LEFT", h, "LEFT", 20, 0)
	h:SetScript("OnClick", function(self)
		collapsed[self.psKind] = not collapsed[self.psKind] or nil
		G.Paint()
	end)
	heads[i] = h
	return h
end

local function tint(t, off)
	t:SetDesaturated(off)
	t:SetAlpha(off and 0.5 or 1)
end

-- The member display (LFGBrowseGroupDataDisplay_Update), at the row's right.
local function paintDisplay(r, res, id, solo, off)
	for _, t in ipairs(r.Icons) do t:Hide(); t:ClearAllPoints() end
	for _, t in ipairs(r.Counts) do t:Hide(); t:ClearAllPoints() end
	r.Comment:Hide()
	local kind, most = displayType(res.activityIDs)
	local counts = call("GetSearchResultMemberCounts", id)
	local color = off and "textMuted" or "text"
	if kind == DT.Comment then
		r.Comment:SetText(res.comment) -- a kstring: shown as given
		W.Color(r.Comment, off and "textMuted" or "textDim")
		r.Comment:Show()
		return 220
	end
	if not counts then return 20 end
	local right = r
	local function place(t, w)
		t:SetPoint("RIGHT", right, right == r and "RIGHT" or "LEFT", right == r and -10 or -(w or 2), 0)
		right = t
		t:Show()
	end
	if solo then
		local m = call("GetSearchResultPlayerInfo", id, 1)
		local lr = m and m.lfgRoles or {}
		local on = {}
		for k, v in ipairs({ lr.tank, lr.healer, lr.dps }) do if v then on[#on + 1] = k end end
		for k = #on, 1, -1 do
			local t = r.Icons[k]
			t:SetAtlas(SOLO_ATLAS[on[k]])
			tint(t, off)
			place(t)
		end
	elseif kind == DT.RoleCount then
		for k = 3, 1, -1 do
			local n, t = r.Counts[k], r.Icons[k]
			n:SetText(counts[ROLES[k]] or 0)
			W.Color(n, color)
			place(n, 10)
			t:SetAtlas(ROLE_ATLAS[ROLES[k]])
			tint(t, off)
			t:SetAlpha(off and 0.5 or 0.7)
			place(t, 3)
		end
	elseif kind == DT.RoleEnumerate or kind == DT.ClassEnumerate then
		-- Icons right to left: empty slots at the right, the members by role (or class) order to their left.
		local order = kind == DT.RoleEnumerate and ROLES or CLASS_SORT_ORDER or {}
		local n = math.min(most, 5)
		local atlases = {}
		for _, key in ipairs(order) do
			for _ = 1, counts[key] or 0 do atlases[#atlases + 1] = ROLE_ATLAS[key] or ("groupfinder-icon-class-" .. key:lower()) end
		end
		for k = 1, n do
			local t = r.Icons[k]
			t:SetAtlas(atlases[n - k + 1] or "groupfinder-icon-emptyslot")
			tint(t, off)
			place(t)
		end
	elseif kind == DT.PlayerCount then
		local t, c = r.Icons[1], r.Counts[1]
		t:SetAtlas("groupfinder-waitdot")
		tint(t, off)
		place(t)
		c:SetText((counts.TANK or 0) + (counts.HEALER or 0) + (counts.DAMAGER or 0) + (counts.NOROLE or 0))
		W.Color(c, color)
		place(c, 3)
	end
	return 130
end

local function paintRow(r, id, res)
	local solo = res.numMembers == 1
	local off = res.isDelisted or not filtered(res)
	local hit = matches(res)
	r.psID = id
	r.Sel:SetShown(selected == id)
	-- The leader: their class icon and level for a solo player, the leader mark for a group.
	local m = solo and call("GetSearchResultPlayerInfo", id, 1)
	local leader = call("GetSearchResultLeaderInfo", id)
	if solo and m and m.classFilename and m.level then
		r.Icon:SetAtlas("groupfinder-icon-class-" .. m.classFilename:lower())
		r.Level:SetText(("%s %d"):format(LEVEL_ABBR or "Lvl", ns.Num(m.level)))
	else
		r.Icon:SetAtlas("groupfinder-icon-leader")
		r.Level:SetText("")
	end
	r.Icon:SetShown(not solo or (m and m.classFilename) and true or false)
	tint(r.Icon, res.isDelisted)
	r.Level:SetShown(solo and m and m.level and true or false)
	ns.NameText(r.Name, "body", ns.Clean(res.leaderName))
	W.Uncolor(r.Name)
	if off then W.Color(r.Name, "textMuted")
	elseif leader and leader.classFilename then r.Name:SetTextColor(classRGB(leader.classFilename))
	else W.Color(r.Name, "text") end
	local last = r.Level:IsShown() and r.Level or r.Name
	r.Voice:SetShown(res.voiceMode == (Enum.LFGEntryVoiceMode and Enum.LFGEntryVoiceMode.Discord or 2))
	if r.Voice:IsShown() then r.Voice:SetPoint("LEFT", last, "RIGHT", 4, 0); tint(r.Voice, res.isDelisted); last = r.Voice end
	r.Fresh:SetShown(res.newPlayerFriendly and true or false)
	if r.Fresh:IsShown() then r.Fresh:SetPoint("LEFT", last, "RIGHT", 4, 0); tint(r.Fresh, res.isDelisted) end
	-- The activities: the own listing's, one by name, or a count.
	local shownIDs = #hit > 0 and hit or res.activityIDs
	local text
	if res.isDelisted then text = LFG_LIST_DELISTED or "Delisted"
	elseif res.hasSelf then text = LFG_SELF_LISTING or "Your listing"
	elseif #shownIDs == 1 then text = activityName(info(shownIDs[1]))
	elseif #hit > 0 then text = (LFGBROWSE_ACTIVITY_MATCHING_COUNT or "%d matching activities"):format(#shownIDs)
	else text = (LFGBROWSE_ACTIVITY_COUNT or "%d activities"):format(#shownIDs) end
	if res.generalPlaystyle and GetGeneralPlaystyleString then
		local p = GetGeneralPlaystyleString(res.generalPlaystyle)
		if p and p ~= "" then text = text .. " · " .. p end
	end
	r.Sub:SetText(text)
	W.Color(r.Sub, off and "textMuted" or res.hasSelf and "success" or #hit > 0 and "accent" or "textDim")
	r.Sub:SetPoint("RIGHT", r, "RIGHT", -paintDisplay(r, res, id, solo, off), 0)
	r.Name:SetWidth(0)
	r.Name:SetWidth(math.min(r.Name:GetStringWidth() + 1, 220))
	r:SetAlpha(res.isDelisted and 0.8 or 1)
end

local function paintList(list)
	local y, nr, nh, kind = 0, 0, 0, nil
	for _, t in ipairs(rows) do t:Hide() end
	for _, t in ipairs(heads) do t:Hide() end
	for _, id in ipairs(list) do
		local res = result(id)
		if res then
			-- A heading where solo players give way to groups or back (the stock collapsible dividers).
			local k = not res.hasSelf and (res.numMembers <= 1 and SOLO or GROUP) or nil
			if k and k ~= kind then
				kind = k
				nh = nh + 1
				local h = heads[nh] or newHead(nh)
				h.psKind = k
				h.Text:SetText(k == SOLO and (LFG_LIST_CATEGORY_SOLO_PLAYERS or "Solo Players") or (LFG_LIST_CATEGORY_GROUPS or "Groups"))
				h.Chevron:SetTexture(Theme.Media(collapsed[k] and "chevron-right" or "chevron-down"))
				h:ClearAllPoints()
				h:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -y)
				h:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
				h:Show()
				y = y + HEAD_H
			end
			if not (k and collapsed[k]) then
				nr = nr + 1
				local r = rows[nr] or newRow(nr)
				r:ClearAllPoints()
				r:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -y)
				r:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
				paintRow(r, id, res)
				r:Show()
				y = y + ROW_H + GAP
			end
		end
	end
	return y
end

---------------------------------------------------------------------------
-- The page.

local function redraw() if shown and f:IsShown() then G.Paint() end end

local function build(frame)
	f = frame
	local row = f.TabRow
	catButton = W.Button(row, CATEGORY or "Category", function(self) categoryMenu(self) end, { icon = "chevron-down", height = 28 })
	catButton:SetPoint("LEFT", row, "LEFT", f.psPad, 0)
	actButton = W.Button(row, "", function(self) activityMenu(self) end, { icon = "chevron-down", height = 28 })
	actButton:SetPoint("LEFT", catButton, "RIGHT", 6, 0)
	refresh = W.IconButton(row, "reload", 30, "Refresh", function() doSearch() end, 14)
	refresh:SetPoint("RIGHT", row, "RIGHT", -f.psPad, 0)
	if refresh.SetMotionScriptsWhileDisabled then refresh:SetMotionScriptsWhileDisabled(true) end
	Theme.Skin(refresh, "editbox")
	optButton = W.IconButton(row, "sliders", 30, "Options", function(self) optionsMenu(self) end, 14)
	optButton:SetPoint("RIGHT", refresh, "LEFT", -6, 0)
	Theme.Skin(optButton, "editbox")
	panel = CreateFrame("Frame", nil, f.Body)
	panel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -TOP)
	panel:SetPoint("RIGHT", f.Body, "RIGHT", -f.psPad, 0)
	panel:SetHeight(1)
	empty = W.Text(f.Body, "default", "textDim")
	empty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -24)
	empty:SetPoint("RIGHT", f.Body, "RIGHT", -f.psPad, 0)
	empty:SetJustifyH("LEFT")
	empty:SetWordWrap(true)
	for _, t in ipairs({ catButton, actButton, refresh, optButton, panel, empty }) do t:Hide() end
	Polestar.RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED", function() searching, failed, selected = false, false, nil; redraw() end)
	Polestar.RegisterEvent("LFG_LIST_SEARCH_FAILED", function() searching, failed, selected = false, true, nil; redraw() end)
	for _, e in ipairs({ "LFG_LIST_SEARCH_RESULT_UPDATED", "LFG_LIST_AVAILABILITY_UPDATE", "REPORT_PLAYER_RESULT" }) do Polestar.RegisterEvent(e, redraw) end
	Polestar.RegisterEvent("CVAR_UPDATE", function(_, name)
		if name == IGNORE_LEVELS then category, chosen = 0, {}; redraw() end
	end)
end

local function paint()
	shown = true
	f.psKeepTabRow = true
	for _, t in ipairs({ catButton, actButton, refresh, optButton, panel }) do t:Show() end
	-- The pickers: the category, then the activities (greyed until a category is picked).
	local c = category > 0 and call("GetLfgCategoryInfo", category)
	W.SetButtonText(catButton, c and c.name or CATEGORY or "Category")
	local act = #chosen == 0 and (LFGBROWSE_ACTIVITY_HEADER_DEFAULT or "All Activities")
		or #chosen == 1 and activityName(info(chosen[1]))
		or (LFGBROWSE_ACTIVITY_HEADER or "%d Activities"):format(#chosen)
	W.SetButtonText(actButton, act)
	ns.SetEnabled(actButton, category > 0, "Pick a category first.")
	W.SetIconState(refresh, false, category > 0)
	refresh.psTip = category == 0 and "Pick a category first." or searching and "Searching… Click to search again." or "Refresh"
	W.SetIconState(optButton, GetCVarBool(IGNORE_LEVELS))
	-- The list: the client keeps the last results (ours or the game's window's).
	local total, list = 0, {}
	if L.GetFilteredSearchResults then total, list = L.GetFilteredSearchResults() end
	list = list or {}
	if selected then
		local s = result(selected)
		if not s or s.isDelisted then selected = nil end
	end
	local height
	if waiting or searching or failed or (total or 0) == 0 then
		panel:Hide()
		empty:SetText(waiting and "Listed. Click Refresh to see the groups for your listing." or searching and (SEARCHING or "Searching…") or failed and (LFG_LIST_SEARCH_FAILED or "The search failed. Try again.")
			or category == 0 and "Pick a category to see its groups." or (LFG_LIST_NO_RESULTS_FOUND or "No groups found."))
		empty:Show()
	else
		empty:Hide()
		sortResults(list)
		height = TOP + paintList(list) + 16
	end
	-- The footer: Send Message and Group Invite on the selection; Unlist is the game's window.
	local sel = selected and result(selected)
	local right = {
		{ label = GROUP_INVITE or "Group Invite", onClick = function() invite(result(selected)) end, on = canInvite(sel),
			why = not sel and "Select a listing first." or sel.numMembers ~= 1 and "Only a solo player can be invited: whisper a group's leader." or "Only the leader or an assistant can invite." },
		{ label = SEND_MESSAGE or "Send Message", onClick = function() whisper(result(selected)) end, opts = { primary = true }, on = sel ~= nil, why = "Select a listing first." },
	}
	local left = {}
	if entry() and leads() then
		left[1] = { label = LFG_LIST_UNLIST or "Unlist", game = true, on = LFDMicroButton ~= nil, why = "No Group Finder button.",
			tip = "Addons can't unlist a group: this opens the game's Group Finder, where its Unlist button is." }
	end
	local fact = waiting and "Listed" or searching and "Searching…" or failed and "Search failed" or (total or 0) > 0 and ("%d %s"):format(total, total == 1 and "listing" or "listings") or nil
	return fact, right, left, height
end

local function leave()
	shown = false
	f.psKeepTabRow = nil
	for _, t in ipairs({ catButton, actButton, refresh, optButton, panel, empty }) do t:Hide() end
	W.HideMenu()
end

if G then G.pages.browse = { build = build, paint = paint, leave = leave } end
