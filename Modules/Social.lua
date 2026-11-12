-- The Social (docs/windows/social.md): the stock FriendsFrame's Contacts and
-- Raid tabs in a Polestar shell. Quick Join, Recruit a Friend and the raid's
-- drag and ready check stay on the stock window.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUISocial"
local ROW_H, RAID_H, COL_GAP = 44, 28, 24

local f, page, query = nil, "friends", ""
local M = {}
local rows, groups = {}, {}

-- A value the client may hand over secret (Battle.net names in combat, the
-- player's name): the last one read clean under `key` (docs/CLIENT.md, rule 3).
local known = {}
local function keep(key, v)
	if v ~= nil and not (issecretvalue and issecretvalue(v)) then known[key] = v end
	return known[key]
end

local function classFile(guid)
	return guid and select(2, GetPlayerInfoByGUID(guid))
end

local function lastOnline(t)
	return t and t > 0 and FriendsFrame_GetLastOnline and ("Last online %s"):format(FriendsFrame_GetLastOnline(t)) or "Offline"
end

local function detail(level, class, zone)
	local parts = {}
	if level and level > 0 then parts[1] = ("Level %d %s"):format(level, class or "") end
	if zone and zone ~= "" then parts[#parts + 1] = zone end
	return table.concat(parts, " · ")
end

-- The pages' entries, online first as the client already orders each list.
local function friends()
	local list = {}
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info then
			list[#list + 1] = { name = info.name, online = info.connected, class = classFile(info.guid),
				sub = info.connected and detail(info.level, info.className, info.area) or "Offline",
				whisper = function() ChatFrameUtil.SendTell(info.name) end,
				invite = function() C_PartyInfo.InviteUnit(info.name) end,
				menu = function() FriendsFrame_ShowDropdown(info.name, info.connected, nil, nil, nil, 1, nil, nil, nil, nil, info.guid) end }
		end
	end
	return list
end

local function battlenet()
	local list = {}
	for i = 1, (BNGetNumFriends()) do
		local a = C_BattleNet.GetFriendAccountInfo(i)
		if a then
			local g, id = a.gameAccountInfo or {}, a.bnetAccountID
			local name = keep("bn" .. id, a.accountName) or a.battleTag or ""
			local char = keep("bnc" .. id, g.characterName)
			local sub
			if not g.isOnline then
				sub = lastOnline(a.lastOnlineTime)
			elseif char then
				sub = char .. " · " .. detail(g.characterLevel, g.className, keep("bnz" .. id, g.areaName))
			else
				sub = keep("bnr" .. id, g.richPresence) or "Online"
			end
			list[#list + 1] = { name = name, char = char, online = g.isOnline, class = char and classFile(g.playerGuid), sub = sub,
				whisper = function() ChatFrameUtil.SendBNetTell(name) end,
				invite = function() FriendsFrame_BattlenetInviteByIndex(i) end,
				menu = function() FriendsFrame_ShowBNDropdown(name, g.isOnline, nil, nil, nil, 1, id, nil, nil, nil, nil, a.battleTag) end }
		end
	end
	return list
end

local function ignored()
	local list = {}
	for i = 1, C_FriendList.GetNumIgnores() do
		local name = C_FriendList.GetIgnoreName(i)
		if name then list[#list + 1] = { name = name, online = true, sub = "", unignore = name } end
	end
	return list
end

local function matches(e)
	return query == "" or e.name:lower():find(query, 1, true) or (e.char and e.char:lower():find(query, 1, true))
end

---------------------------------------------------------------------------
-- Friend rows: name over a detail line, in one row panel.

local function rowEnter(r)
	local e = r.psEntry
	if e.unignore then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(e.name)
	ns.TooltipHint("Click to whisper. Double-click to invite to your group. Right-click for more.")
	GameTooltip:Show()
end

local function newRow(panel, i)
	local r = CreateFrame("Button", nil, panel)
	r:SetHeight(ROW_H)
	r:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -(i - 1) * ROW_H)
	r:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
	if i > 1 then
		local d = W.Divider(r)
		d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
		d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
	end
	W.Hover(r)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("BOTTOMLEFT", r, "LEFT", 16, 1)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -48, 0)
	r.Sub = W.Text(r, "small", "textDim")
	r.Sub:SetPoint("TOPLEFT", r, "LEFT", 16, -3)
	r.Sub:SetPoint("RIGHT", r, "RIGHT", -48, 0)
	for _, t in ipairs({ r.Name, r.Sub }) do t:SetJustifyH("LEFT") end
	r.Remove = W.IconButton(r, "close", 24, "Stop ignoring", function(self)
		C_FriendList.DelIgnore(self:GetParent().psEntry.unignore)
		M.Show() -- at once, not on the client's event (docs/CLIENT.md, rule 6)
	end)
	r.Remove:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:SetScript("OnClick", function(self, button)
		local e = self.psEntry
		if not e.whisper then return end
		if button == "RightButton" then e.menu() else e.whisper() end
	end)
	r:SetScript("OnDoubleClick", function(self) if self.psEntry.invite then self.psEntry.invite() end end)
	r:SetScript("OnEnter", rowEnter)
	r:SetScript("OnLeave", W.HideTooltip)
	return r
end

local function paintName(t, class, dim)
	local c = class and RAID_CLASS_COLORS[class]
	W.Uncolor(t)
	if c and not dim then t:SetTextColor(Theme.Legible(c.r, c.g, c.b)) else W.Color(t, dim and "textMuted" or "text") end
end

local function paintRows(list)
	local p = f.psPanel
	for i, e in ipairs(list) do
		local r = rows[i] or newRow(p, i)
		rows[i] = r
		r.psEntry = e
		r.Name:SetText(e.name)
		paintName(r.Name, e.class, not e.online)
		r.Sub:SetText(e.sub)
		W.Color(r.Sub, e.online and "textDim" or "textMuted")
		r.Sub:SetShown(e.sub ~= "")
		r.Name:ClearAllPoints()
		r.Name:SetPoint(e.sub ~= "" and "BOTTOMLEFT" or "LEFT", r, "LEFT", 16, e.sub ~= "" and 1 or 0)
		r.Name:SetPoint("RIGHT", r, "RIGHT", -48, 0)
		r.Remove:SetShown(e.unignore ~= nil)
		r:Show()
	end
	for i = #list + 1, #rows do rows[i]:Hide() end
	p:SetHeight(math.max(1, #list * ROW_H))
	p:SetShown(#list > 0)
	f.psEmpty:SetShown(#list == 0)
	return 24 + #list * ROW_H + 24
end

---------------------------------------------------------------------------
-- Raid: the eight groups in two columns, read only.

local function raidGroup(i)
	local g = groups[i]
	if g then return g end
	g = { Head = W.SectionHeader(f.Body, { plain = true }), Panel = W.RowPanel(f.Body), rows = {} }
	for k = 1, 5 do
		local r = CreateFrame("Frame", nil, g.Panel)
		r:SetHeight(RAID_H)
		r:SetPoint("TOPLEFT", g.Panel, "TOPLEFT", 0, -(k - 1) * RAID_H)
		r:SetPoint("RIGHT", g.Panel, "RIGHT", 0, 0)
		if k > 1 then
			local d = W.Divider(r)
			d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
			d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
		end
		r.Role = W.Text(r, "small", "textDim")
		r.Role:SetPoint("RIGHT", r, "RIGHT", -12, 0)
		r.Name = W.Text(r, "label", "text")
		r.Name:SetPoint("LEFT", r, "LEFT", 12, 0)
		r.Name:SetPoint("RIGHT", r.Role, "LEFT", -8, 0)
		r.Name:SetJustifyH("LEFT")
		g.rows[k] = r
	end
	groups[i] = g
	return g
end

local function paintRaid()
	local members = {}
	for i = 1, 8 do members[i] = {} end
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, _, sub, _, _, class, _, online, _, _, _, role = GetRaidRosterInfo(i)
			if name and members[sub] then
				local m = members[sub]
				m[#m + 1] = { name = keep("raid" .. i, name) or "", class = class, online = online, role = role }
			end
		end
	end
	local col = (f.BodyWidth - COL_GAP) / 2
	local y = { 24, 24 }
	for i = 1, 8 do
		local g, c = raidGroup(i), i <= 4 and 1 or 2
		local x = W.SHELL.pad + (c - 1) * (col + COL_GAP)
		W.SetSection(g.Head, ("Group %d"):format(i))
		g.Head:SetWidth(col)
		g.Head:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y[c])
		g.Panel:SetWidth(col)
		g.Panel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -(y[c] + W.PLAIN_SECTION_H))
		g.Panel:SetHeight(5 * RAID_H)
		for k, r in ipairs(g.rows) do
			local m = members[i][k]
			r.Name:SetText(m and m.name or "")
			if m then paintName(r.Name, m.class, not m.online) end
			r.Role:SetText(m and m.role and m.role ~= "NONE" and _G[m.role] or "")
		end
		g.Head:Show()
		g.Panel:Show()
		y[c] = y[c] + W.PLAIN_SECTION_H + 5 * RAID_H + 16
	end
	return math.max(y[1], y[2]) + 8
end

---------------------------------------------------------------------------
-- The window.

-- The Nothing Lost Rule: what stays on the stock window, and the way to it.
local function optionsMenu(self)
	if W.MenuShown(self) then return W.HideMenu() end
	W.ShowMenu(self, {
		{ text = "Game's window: the friends button by the chat, or /friends", disabled = true },
		{ text = "There: Quick Join, Recruit a Friend, and the raid's groups and ready check", disabled = true },
	}, { minWidth = 200 })
end

local function addFriend()
	if not f.psAdd then
		local body = CreateFrame("Frame", nil, f)
		body:SetSize(352, 30)
		local e = CreateFrame("EditBox", nil, body)
		e:SetAllPoints(body)
		e:SetAutoFocus(false)
		e:SetTextInsets(10, 10, 0, 0)
		Theme.Font(e, "label")
		W.Color(e, "text")
		Theme.Skin(e, "editbox")
		e:SetScript("OnEditFocusGained", function(self) Theme.SetFocused(self, true) end)
		e:SetScript("OnEditFocusLost", function(self) Theme.SetFocused(self, false) end)
		e:SetScript("OnEscapePressed", e.ClearFocus)
		e:SetScript("OnEnterPressed", function() PolestarModal.Box.Action:Click() end)
		body.Box = e
		f.psAdd = body
	end
	local e = f.psAdd.Box
	e:SetText("")
	ns.ModalWith({ title = "Add friend", text = "A character's name, or a BattleTag (Name#1234) for Battle.net.", action = "Add",
		onAccept = function()
			local name = strtrim(e:GetText() or "")
			if name == "" then return end
			-- As the stock dialog decides (AddFriendTemplates.lua).
			if name:find("#", 1, true) then BNSendFriendInvite(name, "") else C_FriendList.AddFriend(name) end
		end }, f.psAdd)
	e:SetFocus()
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 760, height = 600, sidebar = 240, searchPlaceholder = "Search friends",
		onSearch = function(text)
			query = (text or ""):lower()
			if f:IsShown() then M.Show() end
		end })
	ns.Dock(f)
	ns.WindowMenu(f, "social")
	local b = ns.SubjectBlock(f)
	f.psClass, f.psName, f.psLine = b.icon, b.name, b.line
	-- The player's Battle.net status, as a dot on the class icon.
	f.psDot = W.Tex(f.psClass:GetParent(), "OVERLAY", "circle", "success")
	f.psDot:SetSize(10, 10)
	f.psDot:SetPoint("CENTER", f.psClass:GetParent(), "BOTTOMRIGHT", -2, 2)
	local opt = CreateFrame("Button", nil, f.Header)
	opt:SetSize(96, 24)
	opt:SetPoint("BOTTOMRIGHT", f.Header, "BOTTOMRIGHT", -20, 12)
	W.Hover(opt)
	opt.Label = W.Text(opt, "small", "text")
	opt.Label:SetPoint("LEFT", opt, "LEFT", 10, 0)
	opt.Label:SetText("Options")
	opt.Arrow = W.Tex(opt, "ARTWORK", "chevron-down", "textDim")
	opt.Arrow:SetSize(12, 12)
	opt.Arrow:SetPoint("RIGHT", opt, "RIGHT", -10, 0)
	opt:SetScript("OnClick", optionsMenu)
	f.psOptions = opt
	f.psPanel = W.RowPanel(f.Body)
	f.psPanel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psPanel:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	-- The stock window's sounds: it never opens now to play them.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE) end)
	Polestar.CloseOnEscape(NAME)
end

local function statusColor()
	if not BNConnected() then return "textMuted" end
	local afk, dnd = select(5, BNGetInfo())
	return dnd and "danger" or afk and "warning" or "success"
end

local PAGES = {
	friends = { "Friends", "Click a friend to whisper, double-click to invite.", "No friends yet. Add one below." },
	bnet = { "Battle.net", "Your Battle.net friends, in any game.", "No Battle.net friends here." },
	ignored = { "Ignored", "You see nothing these players say.", "You ignore no one." },
	raid = { "Raid", "Your raid by group. To move players, see Options.", nil },
}

local function refresh()
	local lists = { friends = friends(), bnet = battlenet(), ignored = ignored() }
	local bnTotal, bnOnline = BNGetNumFriends()
	local total, online = #lists.friends + bnTotal, C_FriendList.GetNumOnlineFriends() + bnOnline
	f.psName:SetText(keep("player", UnitName("player")) or "")
	f.psLine:SetText(("%d of %d friends online"):format(online, total))
	f.psClass:SetTexture("Interface\\Icons\\ClassIcon_" .. select(2, UnitClass("player")))
	W.Color(f.psDot, statusColor())
	local raidN = IsInRaid() and GetNumGroupMembers() or 0
	W.ShellNav(f, {
		{ key = "friends", label = "Friends", icon = "star", count = #lists.friends },
		{ key = "bnet", label = "Battle.net", icon = "compact", count = bnTotal },
		{ key = "ignored", label = "Ignored", icon = "close", count = #lists.ignored },
		{ key = "raid", label = "Raid", icon = "bolt", count = raidN },
	}, page, function(k) page = k; M.Show() end)
	local p = PAGES[page]
	W.ShellTitle(f, p[1], p[2])
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, page == "raid" and {} or {
		{ label = "Add friend", onClick = addFriend, opts = { primary = true } },
		{ label = "Send message", onClick = function() ChatFrameUtil.OpenChat(SLASH_WHISPER1 .. " ") end },
	})
	for _, g in ipairs(groups) do g.Head:Hide(); g.Panel:Hide() end
	local h
	if page == "raid" then
		f.psPanel:Hide()
		f.psEmpty:SetText("You are not in a raid.")
		f.psEmpty:SetShown(not IsInRaid())
		h = IsInRaid() and paintRaid() or 60
	else
		local list = {}
		for _, e in ipairs(lists[page]) do if matches(e) then list[#list + 1] = e end end
		f.psEmpty:SetText(query ~= "" and "No one matches." or p[3])
		h = paintRows(list)
	end
	W.ShellBody(f, h)
end

function M.Show(key)
	if not f then build() end
	page = key or page
	refresh()
	f:Show()
end

function M.Toggle(key)
	if f and f:IsShown() and (key == nil or key == page) then f:Hide() else M.Show(key) end
end

function M.Enable()
	-- The keys open ours; the stock window is never touched (docs/CLIENT.md,
	-- rule 8). Forever has no social micro button; the chat's friends button,
	-- /friends and toasts stay the game's: they are the way to the stock window.
	ns.Doors("social", "Social", {
		TOGGLESOCIAL = function() M.Toggle() end,
		TOGGLEFRIENDSTAB = function() M.Toggle("friends") end,
		TOGGLERAIDTAB = function() M.Toggle("raid") end,
	})
	local function changed() if f and f:IsShown() then refresh() end end
	for _, ev in ipairs({ "FRIENDLIST_UPDATE", "IGNORELIST_UPDATE", "BN_DISCONNECTED", "BN_INFO_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED" }) do
		Polestar.RegisterEvent(ev, changed)
	end
	-- Battle.net reads also run hidden, so a window first opened in combat
	-- has the names last read clean.
	local function bnet()
		if f and f:IsShown() then return refresh() end
		battlenet()
		keep("player", UnitName("player"))
	end
	for _, ev in ipairs({ "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_CONNECTED" }) do Polestar.RegisterEvent(ev, bnet) end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return FriendsFrame and FriendsFrame:IsShown() and FriendsFrame end

ns.Module("social", M)
