-- Group Finder: the Listing page (docs/windows/groupfinder.md): post and edit a
-- listing as the stock LFGListingFrame does (Blizzard_LFGVanilla_Listing.lua),
-- its logic reimplemented on our own state: the stock mixins are never called.
-- Category cards, then the activity tree; roles, new player friendly,
-- playstyle and voice chat; Post / Update; the read-only view for a member
-- who is not the leader. CreateListing and UpdateListing run only from our own
-- clicks (the client wants a hardware event). RemoveListing is protected and
-- the comment box is the game's secure box, so Unlist and a listing with a
-- comment go through the game's window (the registry's `game` footer buttons).

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme
local G = ns.GroupFinder

local ROW_H, CARD_H, GAP, TOP = 28, 56, 8, 16
local LEVEL_CVAR, NPF_CVAR = "disableSuggestedLevelActivityFilter", "lfgNewPlayerFriendly"
local DASH, ELLIPSIS = "\226\128\147", "\226\128\166"
-- LFGLISTING_CATEGORY_TEXTURES (LFGVanilla_Constants.lua), by category id.
local ATLAS = { [2] = "groupfinder-button-dungeons", [114] = "groupfinder-button-raids-warlords",
	[116] = "groupfinder-button-questing", [118] = "groupfinder-button-battlegrounds", [120] = "groupfinder-button-custom-pve" }
local ROLES = {
	{ key = "tank", atlas = "UI-LFG-RoleIcon-Tank", label = function() return TANK or "Tank" end, role = "TANK" },
	{ key = "healer", atlas = "UI-LFG-RoleIcon-Healer", label = function() return HEALER or "Healer" end, role = "HEALER" },
	{ key = "dps", atlas = "UI-LFG-RoleIcon-DPS", label = function() return DAMAGER or "Damage" end, role = "DAMAGER" },
}
local COMMENT_TIP = "Closes this one and opens the game's Group Finder: only its comment box can take a comment."

local function lfg(name, ...)
	local fn = C_LFGList and C_LFGList[name]
	if fn then return fn(...) end
end
local function info(id) return id and lfg("GetActivityInfoTable", id) end
local function catInfo(id) return lfg("GetLfgCategoryInfo", id) or {} end
local function listed() return lfg("HasActiveEntryInfo") and true or false end
local function entry() return lfg("GetActiveEntryInfo") end
local function home() return LE_PARTY_CATEGORY_HOME end
local function inGroup() return IsInGroup and IsInGroup(home()) or false end
local function leader() return UnitIsGroupLeader and UnitIsGroupLeader("player", home()) or false end
-- LFGListingUtil_CanEditListing.
local function canEdit() return not inGroup() or leader() end
local function level() return ns.Num(UnitLevel("player")) end
local function nameOf(a) return a.shortName ~= nil and a.shortName ~= "" and a.shortName or a.fullName or "" end
local function playstyles() return Enum and Enum.LFGEntryGeneralPlaystyle end
local function voiceModes() return Enum and Enum.LFGEntryVoiceMode end

-- The page's state, as the stock frame keeps it: the category chosen, the
-- activities offered (id -> chosen), whether anything changed since the
-- listing was posted or loaded, and the fields that go with a post.
local s = { acts = {}, collapsed = {}, dirty = false }
local f, ui

local function redraw() if f and f:IsShown() then G.Paint() end end

-- As LFGUtil_GetFilteredActivities: activities outside the player's level
-- range go, unless the player ignores level ranges; the listing's own stay.
local function filtered(cat, group)
	local list = lfg("GetAvailableActivities", cat, group) or {}
	if GetCVarBool(LEVEL_CVAR) then return list end
	local mine, e, lv, out = {}, entry(), level(), {}
	for _, id in ipairs(e and e.activityIDs or {}) do mine[id] = true end
	for _, id in ipairs(list) do
		local a = info(id)
		local out1 = a and ((a.minLevelSuggestion > 0 and a.minLevelSuggestion > lv) or (a.maxLevelSuggestion > 0 and a.maxLevelSuggestion < lv))
		if mine[id] or not out1 then out[#out + 1] = id end
	end
	return out
end

-- LFGListingMixin:UpdateActivities: every activity offered, the listing's chosen
-- (or all of an auto-choose category).
local function loadActivities()
	s.acts = {}
	if not s.cat then return end
	for _, id in ipairs(filtered(s.cat)) do s.acts[id] = false end
	local e = entry()
	if e then
		for _, id in ipairs(e.activityIDs or {}) do if s.acts[id] ~= nil then s.acts[id] = true end end
	elseif catInfo(s.cat).autoChooseActivity then
		for id in pairs(s.acts) do s.acts[id] = true end
	end
end

local function chosen()
	local n = 0
	for _, on in pairs(s.acts) do if on then n = n + 1 end end
	return n
end

local function choose(cat)
	s.cat, s.collapsed = cat, {}
	loadActivities()
	if RequestRaidInfo then RequestRaidInfo() end
end

-- Back to the categories (LFGListingMixin:ClearUI, never while listed).
local function back()
	s.cat, s.collapsed, s.dirty = nil, {}, false
	s.voice = voiceModes() and voiceModes().None
	loadActivities()
	redraw()
end

-- LoadActiveEntry: the listing up is what the page shows until changed.
local function loadEntry()
	local e = entry()
	local a = e and e.activityIDs and info(e.activityIDs[1])
	if not a then return end
	if s.cat ~= a.categoryID then s.cat, s.collapsed = a.categoryID, {} end
	loadActivities()
	s.npf = e.newPlayerFriendly and true or false
	s.voice = e.voiceMode or (voiceModes() and voiceModes().None)
	if e.generalPlaystyle and e.generalPlaystyle ~= 0 then s.playstyle = e.generalPlaystyle end
	s.dirty = false
end

local function npf()
	if listed() then return s.npf and true or false end
	return GetCVarBool(NPF_CVAR)
end

-- A change of ours (a tick, a field): what it does to the Post button.
local function changed()
	if listed() then s.dirty = true else s.dirty = chosen() > 0 end
	G.Paint()
end

local function filtersChanged()
	s.collapsed = {}
	loadActivities()
	redraw()
end

local function playstyleText(v)
	if GetGeneralPlaystyleString then return GetGeneralPlaystyleString(v) end
	return _G["GROUP_FINDER_GENERAL_PLAYSTYLE" .. v] or ({ "Learning", "Relaxed", "Competitive", "Carry Offered" })[v] or ""
end

local function voiceText(v)
	local m = voiceModes()
	if v == m.Discord then return VOICE_CHAT_MODE_DISCORD or "Discord" end
	if v == m.Legacy then return VOICE_CHAT_MODE_LEGACY or "In-game voice" end
	if v == m.Custom then return VOICE_CHAT_MODE_CUSTOM or "Custom" end
	return VOICE_CHAT_MODE_NONE or "None"
end

-- The saved lockouts (LFGListingMixin:FetchSavedInstances).
local function lockouts()
	local out = {}
	for i = 1, (GetNumSavedInstances and GetNumSavedInstances() or 0) do
		local _, _, _, difficultyID, _, _, _, _, _, _, total, done, _, mapID = GetSavedInstanceInfo(i)
		out[#out + 1] = { mapID = mapID, difficultyID = difficultyID, total = total or 0, done = done or 0,
			redirected = C_RaidLocks and C_RaidLocks.GetRedirectedDifficultyID and C_RaidLocks.GetRedirectedDifficultyID(mapID, difficultyID) or difficultyID }
	end
	return out
end

-- LFGListingActivityView_InitActivityButton's lock warning: done, total.
local function lockOf(a, saved)
	if not (a.mapID and a.difficultyID) then return end
	for _, l in ipairs(saved) do
		if l.mapID == a.mapID and l.done > 0 and l.total > 0
			and (l.difficultyID == a.difficultyID or l.redirected == (a.redirectedDifficultyID or a.difficultyID)) then
			return l.done, l.total
		end
	end
end

-- LFGListingActivityView_UpdateActivities' sorts.
local function byActivity(x, y)
	if x.order ~= y.order then return x.order > y.order end
	if x.max ~= y.max then
		if x.max == 0 or y.max == 0 then return x.max == 0 end
		return x.max > y.max
	end
	if x.min ~= y.min then return x.min > y.min end
	return x.name < y.name
end

local function activityRow(id, saved)
	local a = info(id)
	if not a then return end
	local done, total = lockOf(a, saved)
	return { id = id, name = nameOf(a), min = a.minLevelSuggestion or 0, max = a.maxLevelSuggestion or 0, order = a.orderIndex or 0, done = done, total = total }
end

-- The tree: free activities first, then the activity groups by order and
-- name; a group with nothing at the player's level starts folded when there
-- is more than one.
local function tree()
	local saved, out = lockouts(), {}
	local free = {}
	for _, id in ipairs(filtered(s.cat, 0)) do free[#free + 1] = activityRow(id, saved) end
	table.sort(free, byActivity)
	for _, r in ipairs(free) do out[#out + 1] = r end
	local groups, ids = {}, lfg("GetAvailableActivityGroups", s.cat) or {}
	local lv = level()
	for _, gid in ipairs(ids) do
		local rows, suggested = {}, false
		for _, id in ipairs(filtered(s.cat, gid)) do
			local r = activityRow(id, saved)
			if r then
				rows[#rows + 1] = r
				suggested = suggested or (r.min <= lv and lv <= r.max)
			end
		end
		if #rows > 0 then
			local name, order = lfg("GetActivityGroupInfo", gid)
			table.sort(rows, byActivity)
			groups[#groups + 1] = { gid = gid, name = name or "", order = order or 0, rows = rows, suggested = suggested }
		end
	end
	table.sort(groups, function(x, y) if x.order ~= y.order then return x.order < y.order end return x.name < y.name end)
	local multi = #ids > 1
	for _, g in ipairs(groups) do
		if s.collapsed[g.gid] == nil then s.collapsed[g.gid] = multi and not g.suggested end
		g.multi = multi
		out[#out + 1] = g
	end
	return out
end

local function groupState(g)
	local all, any = true, false
	for _, r in ipairs(g.rows) do
		if s.acts[r.id] then any = true else all = false end
	end
	return all, any
end

---------------------------------------------------------------------------
-- Post and Update

local function cap()
	return Constants and Constants.LFGConstsExposed and Constants.LFGConstsExposed.GROUP_FINDER_MAX_ACTIVITY_CAPACITY or math.huge
end

-- LFGListingMixin:UpdatePostButtonEnableState: on, or the reason it is not.
local function postState()
	local up = listed()
	if not canEdit() then
		return false, up and (LFG_LIST_ONLY_LEADER_UPDATE or "Only your group leader can update the listing.")
			or (LFG_LIST_ONLY_LEADER_CREATE or "Only your group leader can create a listing.")
	end
	local n = chosen()
	if n > cap() then return false, LFG_LIST_TOO_MANY_ACTIVITIES_SELECTED or "Too many activities selected." end
	if playstyles() and not s.playstyle then return false, GROUP_FINDER_PLAYSTYLE_REQUIRED or "Choose a playstyle." end
	if n == 0 then
		return false, up and "Nothing chosen: Unlist takes the listing down." or "Choose an activity."
	end
	if not s.dirty then return false, up and "Change something to update the listing." or "Choose an activity." end
	if inGroup() then
		local size, least, full = GetNumGroupMembers(home()), 0, false
		for id, on in pairs(s.acts) do
			local a = on and info(id)
			local most = a and a.maxNumPlayers or 0
			if most ~= 0 then
				if most <= size then full = true end
				if least == 0 or most < least then least = most end
			end
		end
		if full then return false, (LFG_LIST_TOO_MANY_FOR_ACTIVITY or "Your group has too many players for this activity (max %d).") :format(least) end
	end
	return true
end

-- LFGListingMixin:CreateOrUpdateListing, from the Post button's click only.
-- An update copies the listing up into the client's creation fields first, so
-- the comment the game's window gave it is kept.
local function post()
	if not postState() then return end
	local ids = {}
	for id, on in pairs(s.acts) do if on then ids[#ids + 1] = id end end
	table.sort(ids)
	local m, p = voiceModes(), Enum and Enum.VoiceProviderID
	if m and p and s.voice and (not inGroup() or leader()) then
		local provider = s.voice == m.Discord and p.Discord or s.voice == m.Legacy and p.Legacy or nil
		if provider and tonumber(GetCVar("voiceProvider")) ~= provider then SetCVar("voiceProvider", provider) end
	end
	local ok
	if listed() then
		lfg("CopyActiveEntryInfoToCreationFields")
		ok = lfg("UpdateListing", { activityIDs = ids, newPlayerFriendly = npf(), voiceMode = s.voice })
	else
		ok = lfg("CreateListing", { activityIDs = ids, newPlayerFriendly = npf(), generalPlaystyle = s.playstyle, voiceMode = s.voice })
	end
	s.dirty = false
	-- Posted: to Browse on what was posted (LFGParentFrame_SearchActiveEntry), not
	-- searched: the listing call spent this click's hardware event (Search would be
	-- blocked), and stock's search from the entry event is no hardware event either.
	if ok ~= false and G.SearchFor then
		if SOUNDKIT and SOUNDKIT.PVP_ENTER_QUEUE then PlaySound(SOUNDKIT.PVP_ENTER_QUEUE) end
		G.SearchFor(ids, true)
		ns.Show("groupfinder", "browse")
	else
		G.Paint()
	end
end

---------------------------------------------------------------------------
-- Frames

local function newRow()
	local r = CreateFrame("Button", nil, ui.root)
	r:SetHeight(ROW_H)
	W.Hover(r)
	r.Chevron = W.Tex(r, "ARTWORK", "chevron-down", "textDim")
	r.Chevron:SetSize(12, 12)
	r.Check = W.Checkbox(r)
	-- Some of a group chosen: a dash in the empty box (stock's multi-check).
	r.Dash = W.Tex(r.Check, "OVERLAY", nil, "accent")
	r.Dash:SetSize(8, 2)
	r.Dash:SetPoint("CENTER", r.Check, "CENTER", 0, 0)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("LEFT", r.Check, "RIGHT", 8, 0)
	r.Level = W.Text(r, "number", "textMuted")
	r.Level:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.Level:SetJustifyH("RIGHT")
	r.Lock = CreateFrame("Frame", nil, r)
	r.Lock:SetSize(16, 16)
	r.Lock:SetPoint("RIGHT", r, "RIGHT", -72, 0)
	r.Lock.Art = W.Tex(r.Lock, "ARTWORK", "lock", "warning")
	r.Lock.Art:SetAllPoints(r.Lock)
	r.Lock:EnableMouse(true)
	r.Lock:SetScript("OnEnter", function(self)
		local dr, dg, db = Theme.Color("danger")
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText((BOSSES_KILLED or "%d/%d Bosses Defeated"):format(self.psDone, self.psTotal), dr, dg, db)
		GameTooltip:Show()
	end)
	r.Lock:SetScript("OnLeave", W.HideTip)
	r.Name:SetPoint("RIGHT", r.Lock, "LEFT", -8, 0)
	local function toggle()
		if r.psGroup then
			local _, any = groupState(r.psGroup)
			for _, a in ipairs(r.psGroup.rows) do s.acts[a.id] = not any end
		else
			s.acts[r.psID] = not s.acts[r.psID]
		end
		changed()
	end
	r.Check:SetScript("OnClick", toggle)
	r:SetScript("OnClick", function()
		-- A group's own click folds it (the chevron's); with one group, ticks it.
		if r.psGroup and r.psGroup.multi then
			s.collapsed[r.psGroup.gid] = not s.collapsed[r.psGroup.gid]
			G.Paint()
		else
			toggle()
		end
	end)
	return r
end

local function paintGroupRow(r, g)
	r.psGroup, r.psID = g, nil
	local all, any = groupState(g)
	r.Chevron:SetShown(g.multi)
	r.Chevron:SetTexture(Theme.Media(s.collapsed[g.gid] and "chevron-right" or "chevron-down"))
	r.Chevron:ClearAllPoints()
	r.Chevron:SetPoint("LEFT", r, "LEFT", 8, 0)
	r.Check:ClearAllPoints()
	r.Check:SetPoint("LEFT", r, "LEFT", g.multi and 28 or 8, 0)
	r.Check:SetChecked(all)
	r.Dash:SetShown(any and not all)
	Theme.Font(r.Name, "label")
	W.Color(r.Name, "text")
	r.Name:SetText(g.name)
	r.Level:SetText("")
	r.Lock:Hide()
end

-- LFGActivityEntryTrivial / Difficult: below the player's level recedes, above it warns.
local function paintActivityRow(r, a, indent)
	r.psGroup, r.psID = nil, a.id
	r.Chevron:Hide()
	r.Check:ClearAllPoints()
	r.Check:SetPoint("LEFT", r, "LEFT", indent, 0)
	r.Check:SetChecked(s.acts[a.id] and true or false)
	r.Dash:Hide()
	Theme.Font(r.Name, "body")
	local lv = level()
	local color = "text"
	if a.max ~= 0 and a.max < lv then color = "textMuted" elseif a.min ~= 0 and a.min > lv then color = "danger" end
	W.Color(r.Name, color)
	r.Name:SetText(a.name)
	if a.min == a.max or a.max == 0 then
		r.Level:SetText(a.min == 0 and "" or tostring(a.min))
	else
		r.Level:SetText(a.min .. DASH .. a.max)
	end
	r.Lock.psDone, r.Lock.psTotal = a.done, a.total
	r.Lock:SetShown(a.done ~= nil)
end

local function newCard()
	local c = CreateFrame("Button", nil, ui.root)
	c:SetHeight(CARD_H)
	Theme.Skin(c, "panel")
	c.Art = c:CreateTexture(nil, "ARTWORK")
	c.Art:SetPoint("TOPLEFT", c, "TOPLEFT", 1, -1)
	c.Art:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -1, 1)
	c.Art:SetAlpha(0.7)
	W.Hover(c)
	c.Name = W.Text(c, "title", "text")
	c.Name:SetPoint("LEFT", c, "LEFT", 16, 0)
	c.Name:SetPoint("RIGHT", c, "RIGHT", -36, 0)
	Theme.SetShadow(c.Name, true)
	c.Chevron = W.Tex(c, "OVERLAY", "chevron-right", "text")
	c.Chevron:SetSize(12, 12)
	c.Chevron:SetPoint("RIGHT", c, "RIGHT", -16, 0)
	c:SetScript("OnClick", function(self)
		choose(self.psCat)
		G.Paint()
	end)
	return c
end

local function newLine()
	local l = CreateFrame("Button", nil, ui.root)
	l:SetHeight(20)
	l.Text = W.Text(l, "body", "text")
	l.Text:SetPoint("LEFT", l, "LEFT", 0, 0)
	l.Text:SetPoint("RIGHT", l, "RIGHT", 0, 0)
	l:SetScript("OnEnter", function(self) if self.psTip then W.Tooltip(self, "ANCHOR_RIGHT", self.psTip, self.psTipLines) end end)
	l:SetScript("OnLeave", W.HideTip)
	return l
end

local function pooled(list, i, make)
	local x = list[i] or make()
	list[i] = x
	x:Show()
	return x
end

local function hideFrom(list, i) for k = i, #list do list[k]:Hide() end end

-- A check with its label, for the roles and new player friendly: one click area.
local function newToggle(parent, atlas, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(24)
	b.Check = W.Checkbox(b, function() onClick(b) end)
	b.Check:SetPoint("LEFT", b, "LEFT", 0, 0)
	local x = 24
	if atlas then
		b.Icon = b:CreateTexture(nil, "ARTWORK")
		b.Icon:SetAtlas(atlas)
		b.Icon:SetSize(20, 20)
		b.Icon:SetPoint("LEFT", b, "LEFT", x, 0)
		x = x + 24
	end
	b.Label = W.Text(b, "label", "text")
	b.Label:SetPoint("LEFT", b, "LEFT", x, 0)
	b.psX = x
	b:SetScript("OnClick", function() if b.Check:IsEnabled() then onClick(b) end end)
	return b
end

local function sizeToggle(b, text)
	b.Label:SetText(text)
	b:SetWidth(b.psX + math.ceil(b.Label:GetStringWidth()))
end

local function roleMenu(self)
	local items, mine = {}, UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
	for _, r in ipairs(ROLES) do
		items[#items + 1] = { text = r.label(), checked = mine == r.role, onClick = function()
			UnitSetRole("player", r.role)
			redraw()
		end }
	end
	W.ShowMenu(self, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT" })
end

local function playstyleMenu(self)
	local items = {}
	for v = 1, 4 do
		items[v] = { text = playstyleText(v), checked = s.playstyle == v, onClick = function()
			s.playstyle = v
			redraw()
		end }
	end
	W.ShowMenu(self, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT" })
end

local function voiceMenu(self)
	local m, items = voiceModes(), {}
	local discord = C_Discord and C_Discord.IsVoiceEnabled and C_Discord.IsVoiceEnabled()
	for _, v in ipairs({ m.None, m.Discord, m.Legacy, m.Custom }) do
		if v ~= m.Discord or discord then
			items[#items + 1] = { text = voiceText(v), checked = s.voice == v, onClick = function()
				s.voice = v
				s.dirty = true
				redraw()
			end }
		end
	end
	W.ShowMenu(self, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT" })
end

-- The voice mode a new listing starts with: the voice channel the player is in.
local function defaultVoice()
	local m = voiceModes()
	if not m then return nil end
	if C_VoiceChat and C_VoiceChat.GetActiveChannelID and C_VoiceChat.GetActiveChannelID() then
		local discord = Enum.VoiceProviderID and C_VoiceChat.GetActiveVoiceProviderID and C_VoiceChat.GetActiveVoiceProviderID() == Enum.VoiceProviderID.Discord
		return discord and m.Discord or m.Legacy
	end
	return m.None
end

local function build(frame)
	f = frame
	ui = { rows = {}, cards = {}, lines = {}, roles = {} }
	local root = CreateFrame("Frame", nil, f.Body)
	root:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, 0)
	root:SetHeight(1)
	root:Hide()
	ui.root = root
	-- Solo roles (C_LFGListRoles: the client saves them on each click).
	for i, r in ipairs(ROLES) do
		ui.roles[i] = newToggle(root, r.atlas, function()
			local cur = C_LFGListRoles.GetRoles() or {}
			local t = { tank = cur.tank, healer = cur.healer, dps = cur.dps }
			t[r.key] = not t[r.key]
			C_LFGListRoles.SetRoles(t)
			redraw()
		end)
	end
	-- Group role (any member) and the leader's role check.
	ui.role = W.Button(root, "", roleMenu)
	ui.poll = W.Button(root, ROLE_POLL or "Role Check", function() InitiateRolePoll() end)
	ui.npf = newToggle(root, "newplayerchat-chaticon-newcomer", function()
		local on = not npf()
		SetCVar(NPF_CVAR, on and "1" or "0")
		s.npf = on
		changed()
	end)
	ui.playstyle = W.Button(root, "", playstyleMenu)
	ui.voice = W.Button(root, "", voiceMenu)
	ui.rule = W.Divider(root)
	ui.notice = W.Text(root, "default", "textDim")
	ui.notice:SetWordWrap(true)
	ui.notice:SetJustifyH("LEFT")
	-- The stock Back, on the tab row: back to the categories.
	local b = CreateFrame("Button", nil, f.TabRow)
	b:SetHeight(30)
	b:SetPoint("LEFT", f.TabRow, "LEFT", f.psPad - 8, 0)
	W.Hover(b)
	b.Chevron = W.Tex(b, "ARTWORK", "chevron-left", "textDim")
	b.Chevron:SetSize(12, 12)
	b.Chevron:SetPoint("LEFT", b, "LEFT", 8, 0)
	b.Label = W.Text(b, "label", "textDim")
	b.Label:SetPoint("LEFT", b.Chevron, "RIGHT", 6, 0)
	b.Label:SetText("Categories")
	b:SetWidth(8 + 12 + 6 + math.ceil(b.Label:GetStringWidth()) + 10)
	b:SetScript("OnClick", back)
	b:Hide()
	ui.back = b
	-- The category being chosen from, beside "Categories" (the band's subtitle stays short).
	ui.cat = W.Text(f.TabRow, "default", "textMuted")
	ui.cat:SetPoint("LEFT", b, "RIGHT", 8, 0)
	ui.cat:Hide()
	f.psListingCat = ui.cat -- for the scenes
	-- Stock's "Ignore level ranges" (its options menu and the activity view's
	-- check), on the tab row's right end: the client's CVar.
	ui.levels = newToggle(f.TabRow, nil, function()
		SetCVar(LEVEL_CVAR, GetCVarBool(LEVEL_CVAR) and "0" or "1")
		filtersChanged()
	end)
	ui.levels:SetPoint("RIGHT", f.TabRow, "RIGHT", -f.psPad, 0)
	ui.levels:Hide()
	-- As the stock frame's OnShow: lockouts asked for, a new listing's voice mode.
	f:HookScript("OnShow", function()
		if not listed() and not s.dirty then s.voice = defaultVoice() end
		if RequestRaidInfo then RequestRaidInfo() end
	end)
	s.voice = defaultVoice()
	-- LoadSoloRolesOnStartup: the saved roles are the ones a listing carries.
	if C_LFGListRoles and C_LFGListRoles.GetSavedRoles then C_LFGListRoles.SetRoles(C_LFGListRoles.GetSavedRoles() or {}) end
end

-- The roles and new player friendly row, on every view. -> its height
local function paintPrefs(width, y)
	local x = 0
	local solo = not inGroup() and C_LFGListRoles ~= nil
	local roles = solo and C_LFGListRoles.GetRoles() or {}
	for i, r in ipairs(ROLES) do
		local t = ui.roles[i]
		t:SetShown(solo)
		if solo then
			sizeToggle(t, r.label())
			t.Check:SetChecked(roles[r.key] and true or false)
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", ui.root, "TOPLEFT", x, -(y + 2))
			x = x + t:GetWidth() + 20
		end
	end
	local group = inGroup()
	ui.role:SetShown(group)
	ui.poll:SetShown(group)
	if group then
		local mine = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
		local text = SELECT_YOUR_ROLE or "Choose a role"
		for _, r in ipairs(ROLES) do if r.role == mine then text = "Role: " .. r.label() end end
		W.SetButtonText(ui.role, text)
		ui.role:ClearAllPoints()
		ui.role:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
		ui.poll:ClearAllPoints()
		ui.poll:SetPoint("LEFT", ui.role, "RIGHT", 8, 0)
		W.SetButtonText(ui.poll, ROLE_POLL or "Role Check")
		ns.SetEnabled(ui.poll, leader() or (UnitIsGroupAssistant and UnitIsGroupAssistant("player")) or false,
			"Only the leader or an assistant can start a role check.")
	end
	sizeToggle(ui.npf, LFG_LIST_NEW_PLAYER_FRIENDLY or "New Player Friendly")
	ui.npf.Check:SetChecked(npf())
	ns.SetEnabled(ui.npf.Check, canEdit(), "Only the leader can change this.")
	ui.npf:ClearAllPoints()
	-- At the row's right end, or on a line of its own when the roles reach it.
	local used = group and (ui.role:GetWidth() + 8 + ui.poll:GetWidth() + 20) or x
	local wrap = used + ui.npf:GetWidth() > width
	ui.npf:SetPoint("TOPRIGHT", ui.root, "TOPLEFT", width, -(y + 2 + (wrap and 28 or 0)))
	return wrap and 56 or 28
end

local function paintCategories(width, y)
	local i = 0
	for _, cat in ipairs(lfg("GetAvailableCategories") or {}) do
		if #filtered(cat) > 0 then
			i = i + 1
			local c = pooled(ui.cards, i, newCard)
			c.psCat = cat
			c.Art:SetAtlas(ATLAS[cat] or ATLAS[116])
			c.Name:SetText(catInfo(cat).name or "")
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
			c:SetWidth(width)
			y = y + CARD_H + GAP
		end
	end
	hideFrom(ui.cards, i + 1)
	if i == 0 then
		ui.notice:SetText("Nothing to list at your level. To see every activity, turn on \"Ignore level ranges\" above.")
		ui.notice:ClearAllPoints()
		ui.notice:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
		ui.notice:SetWidth(width)
		ui.notice:Show()
		y = y + ui.notice:GetStringHeight() + GAP
	end
	return y
end

local function paintActivities(width, y)
	local auto = catInfo(s.cat).autoChooseActivity
	-- Playstyle and voice chat, as the stock activity view's bar.
	local style = playstyles()
	ui.playstyle:SetShown(style ~= nil and not auto)
	ui.voice:SetShown(voiceModes() ~= nil and not auto)
	local x = 0
	if ui.playstyle:IsShown() then
		W.SetButtonText(ui.playstyle, s.playstyle and ("Playstyle: " .. playstyleText(s.playstyle)) or (GROUP_FINDER_PLAYSTYLE_REQUIRED or "Choose a playstyle"))
		ns.SetEnabled(ui.playstyle, canEdit(), "Only the leader can change this.")
		ui.playstyle:ClearAllPoints()
		ui.playstyle:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
		x = 1
	end
	if ui.voice:IsShown() then
		W.SetButtonText(ui.voice, (VOICE_CHAT or "Voice Chat") .. ": " .. voiceText(s.voice))
		ns.SetEnabled(ui.voice, canEdit(), "Only the leader can change this.")
		ui.voice:ClearAllPoints()
		if x == 1 then ui.voice:SetPoint("LEFT", ui.playstyle, "RIGHT", 8, 0) else ui.voice:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y) end
		x = 1
	end
	if x == 1 then y = y + 28 + GAP * 2 end
	if auto then
		-- Stock shows only its comment box here (the comment is mandatory): that is the game's.
		ui.notice:SetText("A listing in this category needs a comment, and only the game's window can take one. Post it from there.")
		ui.notice:ClearAllPoints()
		ui.notice:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
		ui.notice:SetWidth(width)
		ui.notice:Show()
		hideFrom(ui.rows, 1)
		return y + ui.notice:GetStringHeight() + GAP
	end
	local i = 0
	for _, node in ipairs(tree()) do
		i = i + 1
		local r = pooled(ui.rows, i, newRow)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
		r:SetWidth(width)
		y = y + ROW_H
		if node.rows then
			paintGroupRow(r, node)
			if not s.collapsed[node.gid] then
				for _, a in ipairs(node.rows) do
					i = i + 1
					local ar = pooled(ui.rows, i, newRow)
					ar:ClearAllPoints()
					ar:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
					ar:SetWidth(width)
					paintActivityRow(ar, a, node.multi and 48 or 28)
					y = y + ROW_H
				end
			end
		else
			paintActivityRow(r, node, 8)
		end
	end
	hideFrom(ui.rows, i + 1)
	return y
end

-- LFGListingLockedView_RefreshContent: the leader's listing, read only; past
-- 13 lines a group is one line, its activities in the tooltip.
local function paintLocked(width, y)
	local up = listed()
	ui.notice:SetText(up and (LFG_LIST_ONLY_LEADER_UPDATE or "Only your group leader can update the listing.")
		or (LFG_LIST_ONLY_LEADER_CREATE or "Only your group leader can create a listing."))
	ui.notice:ClearAllPoints()
	ui.notice:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
	ui.notice:SetWidth(width)
	ui.notice:Show()
	y = y + ui.notice:GetStringHeight() + GAP * 2
	local lines = {}
	local e = up and entry()
	if e then
		local byGroup, gids = {}, {}
		for _, id in ipairs(e.activityIDs or {}) do
			local a = info(id)
			if a then
				local gid = a.groupFinderActivityGroupID or 0
				if not byGroup[gid] then byGroup[gid] = {}; gids[#gids + 1] = gid end
				table.insert(byGroup[gid], nameOf(a))
			end
		end
		table.sort(gids, function(p, q)
			local _, po = lfg("GetActivityGroupInfo", p)
			local _, qo = lfg("GetActivityGroupInfo", q)
			if (po or 0) ~= (qo or 0) then return (po or 0) < (qo or 0) end
			return p < q
		end)
		local verbose = 0
		for _, gid in ipairs(gids) do verbose = verbose + #byGroup[gid] + (gid ~= 0 and 1 or 0) end
		verbose = verbose <= 13
		lines[1] = { text = LFG_LIST_MY_ACTIVITY_LIST_HEADER or "Your listing:", head = true }
		for _, gid in ipairs(gids) do
			local names = byGroup[gid]
			table.sort(names)
			if gid == 0 then
				for _, n in ipairs(names) do lines[#lines + 1] = { text = n } end
			else
				local gname = lfg("GetActivityGroupInfo", gid) or ""
				local head = ("%s (%d)"):format(gname, #names)
				if verbose then
					lines[#lines + 1] = { text = head }
					for _, n in ipairs(names) do lines[#lines + 1] = { text = n, indent = true } end
				else
					lines[#lines + 1] = { text = head, tip = gname, tipLines = names }
				end
			end
		end
	end
	for i, d in ipairs(lines) do
		local l = pooled(ui.lines, i, newLine)
		l.Text:SetText(d.text)
		W.Color(l.Text, d.head and "textDim" or "text")
		l.psTip, l.psTipLines = d.tip, d.tipLines
		l:ClearAllPoints()
		l:SetPoint("TOPLEFT", ui.root, "TOPLEFT", d.indent and 16 or 0, -y)
		l:SetWidth(width - (d.indent and 16 or 0))
		y = y + 22
	end
	hideFrom(ui.lines, #lines + 1)
	return y
end

local function postLabel()
	if listed() then return LFG_POST_GROUP_UPDATE or "Update" end
	if inGroup() then return LFG_POST_GROUP_PARTY or "List Group" end
	return LFG_POST_GROUP_SOLO or "List Self"
end

local function unlist()
	return { label = LFG_LIST_UNLIST or "Unlist", game = true, on = LFDMicroButton ~= nil,
		tip = "Closes this one and opens the game's Group Finder: only it can take a listing down." }
end

local function paint(frame)
	local width = f.BodyWidth
	local up = listed()
	if up and not s.dirty then loadEntry() end
	-- Taken down elsewhere (the game's window): what is chosen can be posted again.
	if s.wasListed and not up then s.dirty = chosen() > 0 end
	s.wasListed = up
	ui.root:SetWidth(width)
	ui.root:Show()
	ui.notice:Hide()
	local y = TOP
	y = y + paintPrefs(width, y) + GAP
	ui.rule:ClearAllPoints()
	ui.rule:SetPoint("TOPLEFT", ui.root, "TOPLEFT", 0, -y)
	ui.rule:SetPoint("TOPRIGHT", ui.root, "TOPLEFT", width, -y)
	y = y + GAP * 2
	local view = not canEdit() and "locked" or s.cat and "activities" or "categories"
	if view ~= "categories" then hideFrom(ui.cards, 1) end
	if view ~= "activities" then
		hideFrom(ui.rows, 1)
		ui.playstyle:Hide()
		ui.voice:Hide()
	end
	if view ~= "locked" then hideFrom(ui.lines, 1) end
	local fact, right, left = nil, {}, {}
	local comment = { label = "With a comment" .. ELLIPSIS, game = true, on = LFDMicroButton ~= nil, tip = COMMENT_TIP }
	local n = chosen()
	if view == "locked" then
		y = paintLocked(width, y)
		fact = up and "Leader's listing" or "Not listed"
		local on, why = postState()
		right = { { label = postLabel(), opts = { primary = true }, on = on, why = why } }
	elseif view == "categories" then
		y = paintCategories(width, y)
		comment.label = "Post with a comment" .. ELLIPSIS
		right = { comment }
	else
		y = paintActivities(width, y)
		fact = up and ("Listed: %d"):format(n) or ("%d chosen"):format(n)
		if catInfo(s.cat).autoChooseActivity then
			right = { { label = up and "Edit in game's window" or "Post in game's window", opts = { primary = true }, game = true,
				on = LFDMicroButton ~= nil, tip = COMMENT_TIP } }
		else
			local on, why = postState()
			right = { { label = postLabel(), onClick = post, opts = { primary = true }, on = on, why = why }, comment }
		end
		if up then left = { unlist() } end
	end
	ui.back:SetShown(view == "activities" and not up)
	ui.cat:SetText(s.cat and catInfo(s.cat).name or "")
	ui.cat:ClearAllPoints()
	if up then ui.cat:SetPoint("LEFT", f.TabRow, "LEFT", f.psPad, 0) else ui.cat:SetPoint("LEFT", ui.back, "RIGHT", 4, 0) end
	ui.cat:SetShown(view == "activities")
	ui.levels:SetShown(view ~= "locked")
	sizeToggle(ui.levels, LFG_LIST_IGNORE_SUGGESTED_LEVEL or "Ignore level ranges")
	ui.levels.Check:SetChecked(GetCVarBool(LEVEL_CVAR))
	f.psKeepTabRow = view ~= "locked" or nil
	ui.root:SetHeight(math.max(1, y))
	return fact, right, left, y + TOP
end

local function leave(frame)
	if not ui then return end
	ui.root:Hide()
	ui.back:Hide()
	ui.cat:Hide()
	ui.levels:Hide()
	f.psKeepTabRow = nil
end

G.pages.listing = { build = build, paint = paint, leave = leave }

-- The client's changes the stock frame follows (LFGListingMixin:OnEvent).
local function on(event, fn) Polestar.RegisterEvent(event, fn) end
on("CVAR_UPDATE", function(_, name) if name == LEVEL_CVAR then filtersChanged() end end)
-- A listing changed (ours, the leader's, the game's window): it is what shows (GroupFinder.lua redraws).
on("LFG_LIST_ACTIVE_ENTRY_UPDATE", function() if listed() then s.dirty = false end end)
on("GROUP_LEFT", function(_, category)
	if category == home() and not listed() then
		s.cat, s.collapsed = nil, {}
		loadActivities()
	end
	redraw()
end)
on("LFG_LIST_AVAILABILITY_UPDATE", function()
	s.cat, s.collapsed, s.dirty = nil, {}, false
	loadActivities()
	redraw()
end)
for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "PLAYER_ROLES_ASSIGNED", "LFG_LIST_ROLE_UPDATE", "UPDATE_INSTANCE_INFO" }) do
	on(e, redraw)
end
