-- Group Finder: the Who page (docs/windows/groupfinder.md), the stock
-- LFGWhoListFrame (Blizzard_GroupFinder_VanillaStyle, Mainline/WhoList.lua)
-- rebuilt on our own tables: the query box on the tab row, the filter menu
-- (class, race, zone, sort), a card per player (name; level, race, class;
-- zone and guild) with an invite button, a click to whisper and the game's
-- player menu on a right-click.
-- C_FriendList.SendWho is restricted: only our Enter press or Search click
-- sends it. While the page shows, Who results come to the UI (SetWhoToUi,
-- as the stock page's OnShow/OnHide); left, they go back to chat, and the
-- ones the client still sends to the UI (a long /who) open this page.

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme
local G = ns.GroupFinder

local MAX_FROM_SERVER = 50 -- MAX_WHOS_FROM_SERVER
local ROW_H, ROW_GAP, TOP, NOTE_H = 44, 4, 12, 24

local bar, panel, empty, note
local rows = {}
local open, sent, searching = false, false, false

-- The stock filters (LFGWhoListFilterUtil), kept for the session as stock:
-- classes and races unticked are left out, zones ticked are the only ones.
local filters = { classes = {}, races = {}, maps = {}, sort = "name", ascending = true }

local function whoFilters()
	local w = { classIDs = {}, raceIDs = {}, uiMapIDs = {} }
	for id in pairs(filters.classes) do w.classIDs[#w.classIDs + 1] = id end
	for id in pairs(filters.races) do w.raceIDs[#w.raceIDs + 1] = id end
	for id in pairs(filters.maps) do w.uiMapIDs[#w.uiMapIDs + 1] = id end
	return w
end

local function filtered() return next(filters.classes) or next(filters.races) or next(filters.maps) end

-- Every C_FriendList call through here: missing on a client without it.
local function fl(name, ...)
	local fn = C_FriendList and C_FriendList[name]
	if fn then return fn(...) end
end

-- From our Enter press or Search click only (the call is restricted).
local function send()
	fl("SendWho", bar.Search:GetText() or "", Enum.SocialWhoOrigin and Enum.SocialWhoOrigin.Social, whoFilters())
	bar.Search:ClearFocus()
	searching = true
	G.Paint()
end

---------------------------------------------------------------------------
-- The filter menu: the stock dropdown's submenus as views of one menu (a
-- section opens in place, "Back" returns); a pick keeps it open.

local function classes()
	local out = {}
	for _, id in ipairs(C_SpecializationInfo and C_SpecializationInfo.GetAllClassIDs and C_SpecializationInfo.GetAllClassIDs() or {}) do
		local name = GetClassInfo(id)
		if name then out[#out + 1] = { id = id, name = name } end
	end
	table.sort(out, function(a, b) return a.name < b.name end)
	return out
end

local function races()
	local out = {}
	for _, r in ipairs(fl("GetWhoRaceFilters") or {}) do out[#out + 1] = { id = r.ID, name = r.name } end
	table.sort(out, function(a, b) return a.name < b.name end)
	return out
end

-- The zone tree from the player's world down (LFGWhoListFilterUtil's maps).
local function topMap()
	local id = C_Map.GetBestMapForUnit("player") or C_Map.GetFallbackWorldMapID()
	local top = id and MapUtil and MapUtil.GetMapParentInfo(id, Enum.UIMapType.World, true)
	return top and top.mapID
end

local function mapChildren(id)
	local out = {}
	for _, c in ipairs(C_Map.GetMapChildrenInfo(id) or {}) do
		if C_Map.IsMapValidForNavBarDropdown(c.mapID) then out[#out + 1] = c end
	end
	table.sort(out, function(a, b) return a.name < b.name end)
	return out
end

local function setMaps(id, on)
	local kids = mapChildren(id)
	if #kids == 0 then filters.maps[id] = on or nil end
	for _, c in ipairs(kids) do setMaps(c.mapID, on) end
end

local showFilter
local function view(key, arg)
	return function() showFilter(key, arg) end
end

local function menuItems(key, arg)
	local items = {}
	local function add(it) items[#items + 1] = it end
	local function toggle(set, id, k, a) return function() set[id] = not set[id] or nil; G.Paint(); showFilter(k, a) end end
	if key == "root" then
		add({ text = "Class", icon = "chevron-right", onClick = view("class") })
		add({ text = "Race", icon = "chevron-right", onClick = view("race") })
		add({ text = "Zone", icon = "chevron-right", onClick = view("zone", topMap()) })
		add({ text = "Sort", icon = "chevron-right", onClick = view("sort") })
		if filtered() then
			add({ separator = true })
			add({ text = "Reset filters", onClick = function()
				filters.classes, filters.races, filters.maps = {}, {}, {}
				G.Paint()
			end })
		end
		return items
	end
	add({ text = "Back", icon = "chevron-left", onClick = view(arg and arg.back or "root", arg and arg.backArg) })
	add({ separator = true })
	if key == "sort" then
		for _, s in ipairs({ { "name", "Name" }, { "class", "Class" }, { "level", "Level" } }) do
			add({ text = s[2], checked = filters.sort == s[1], onClick = function()
				filters.sort = s[1]
				fl("SortWho", s[1])
				G.Paint() -- at once (docs/CLIENT.md, rule 6)
				showFilter("sort")
			end })
		end
		add({ separator = true })
		for _, o in ipairs({ { true, "Ascending" }, { false, "Descending" } }) do
			add({ text = o[2], checked = filters.ascending == o[1], onClick = function()
				filters.ascending = o[1]
				fl("SortWho", filters.sort, o[1])
				G.Paint()
				showFilter("sort")
			end })
		end
		return items
	end
	local list, set, all
	if key == "class" then
		list, set = classes(), filters.classes
		all = function(on) for _, c in ipairs(list) do set[c.id] = (not on) or nil end end
	elseif key == "race" then
		list, set = races(), filters.races
		all = function(on) for _, r in ipairs(list) do set[r.id] = (not on) or nil end end
	else -- a zone of the tree (arg.id), its children drill in, its leaves tick
		list, set = {}, filters.maps
		for _, c in ipairs(arg and arg.id and mapChildren(arg.id) or {}) do
			list[#list + 1] = { id = c.mapID, name = c.name, tree = #mapChildren(c.mapID) > 0 }
		end
		all = function(on) if arg and arg.id then setMaps(arg.id, on) end end
	end
	add({ text = "Check all", onClick = function() all(true); G.Paint(); showFilter(key, arg) end })
	add({ text = "Uncheck all", onClick = function() all(false); G.Paint(); showFilter(key, arg) end })
	add({ separator = true })
	for _, e in ipairs(list) do
		if e.tree then
			add({ text = e.name, icon = "chevron-right", onClick = view("zone", { id = e.id, back = "zone", backArg = arg }) })
		elseif key == "zone" then
			add({ text = e.name, checked = set[e.id], onClick = toggle(set, e.id, key, arg) })
		else
			add({ text = e.name, checked = not set[e.id], onClick = toggle(set, e.id, key, arg) })
		end
	end
	return items
end

function showFilter(key, arg)
	if key == "zone" and type(arg) ~= "table" then arg = { id = arg } end
	W.ShowMenu(bar.Filter, menuItems(key, arg), { minWidth = 200 })
end

---------------------------------------------------------------------------
-- Player cards.

local function rowEnter(r)
	local e = r.psInfo
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(e.fullName or "")
	GameTooltip:AddLine(("Level %d %s %s"):format(e.level or 0, e.raceStr or "", e.classStr or ""), 1, 1, 1)
	if (e.area or "") ~= "" then GameTooltip:AddLine(e.area, 1, 1, 1) end
	if (e.fullGuildName or "") ~= "" then GameTooltip:AddLine(e.fullGuildName, 1, 1, 1) end
	ns.TooltipHint("Click to whisper. Right-click for more.")
	GameTooltip:Show()
end

local function newRow(i)
	local r = CreateFrame("Button", nil, panel)
	r:SetHeight(ROW_H)
	r:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
	r.Ground = W.Fill(r, "panel")
	W.Hover(r)
	r.Name = W.Text(r, "body", "text")
	r.Sub = W.Text(r, "small", "textDim")
	r.Area = W.Text(r, "small", "text")
	r.Guild = W.Text(r, "small", "textDim")
	for _, t in ipairs({ r.Name, r.Sub, r.Area, r.Guild }) do t:SetJustifyH("LEFT"); t:SetWordWrap(false) end
	-- The stock row's invite button (WhoInviteButtonMixin), at the right.
	r.Invite = W.IconButton(r, "plus", 24, "Invite to group", function(self)
		C_PartyInfo.InviteUnit(self:GetParent().psInfo.fullName)
	end)
	r.Invite:SetPoint("RIGHT", r, "RIGHT", -8, 0)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:SetScript("OnClick", function(self, button)
		local name = self.psInfo.fullName
		if button == "RightButton" then FriendsFrame_ShowDropdown(name, 1) else ChatFrameUtil.SendTell(name) end
	end)
	r:SetScript("OnEnter", rowEnter)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[i] = r
	return r
end

local function paintRows(n, width)
	local me = ns.Clean(UnitName("player"))
	local col = math.floor(width * 0.5)
	for i = 1, n do
		local e = fl("GetWhoInfo", i) or {}
		local r = rows[i] or newRow(i)
		r.psInfo = e
		r:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -(i - 1) * (ROW_H + ROW_GAP))
		ns.NameText(r.Name, "body", e.fullName)
		local class = ns.ClassText(e.filename, e.classStr or "")
		r.Sub:SetText(("Level %d %s %s"):format(e.level or 0, e.raceStr or "", class))
		r.Area:SetText(e.area or "")
		r.Guild:SetText(e.fullGuildName or "")
		local guild = (e.fullGuildName or "") ~= ""
		r.Name:ClearAllPoints()
		r.Name:SetPoint("BOTTOMLEFT", r, "LEFT", 12, 1)
		r.Name:SetPoint("RIGHT", r, "LEFT", col - 12, 0)
		r.Sub:ClearAllPoints()
		r.Sub:SetPoint("TOPLEFT", r, "LEFT", 12, -3)
		r.Sub:SetPoint("RIGHT", r, "LEFT", col - 12, 0)
		r.Area:ClearAllPoints()
		r.Area:SetPoint(guild and "BOTTOMLEFT" or "LEFT", r, "LEFT", col, guild and 1 or 0)
		r.Area:SetPoint("RIGHT", r, "RIGHT", -44, 0)
		r.Guild:ClearAllPoints()
		r.Guild:SetPoint("TOPLEFT", r, "LEFT", col, -3)
		r.Guild:SetPoint("RIGHT", r, "RIGHT", -44, 0)
		r.Guild:SetShown(guild)
		-- Not on your own card (stock: isOwnListing).
		r.Invite:SetShown(not (me and e.fullName == me))
		r:Show()
	end
	for i = n + 1, #rows do rows[i]:Hide() end
end

---------------------------------------------------------------------------
-- The page.

local function build(f)
	local pad = f.psPad
	-- The tab row: the query box (the stock edit box, its instructions as the
	-- placeholder) and the filter button at its right end, as Guild's.
	bar = CreateFrame("Frame", nil, f.TabRow)
	bar:SetAllPoints(f.TabRow)
	bar:Hide()
	bar.Filter = W.IconButton(bar, "sliders", 30, "Filter", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		showFilter("root")
	end, 14)
	bar.Filter:SetPoint("RIGHT", bar, "RIGHT", -pad, 0)
	Theme.Skin(bar.Filter, "editbox")
	bar.Search = W.SearchBox(bar, "Name, zone, guild, race, class or level (60, 10-20)")
	bar.Search:SetPoint("LEFT", bar, "LEFT", pad, 0)
	bar.Search:SetPoint("RIGHT", bar.Filter, "LEFT", -6, 0)
	bar.Search:SetScript("OnEnterPressed", send)
	Theme.Skin(bar.Search, "editbox")
	f.psWhoSearch, f.psWhoFilter, f.psWhoRows = bar.Search, bar.Filter, rows -- for the scenes
	panel = CreateFrame("Frame", nil, f.Body)
	panel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", pad, -TOP)
	panel:SetPoint("RIGHT", f.Body, "RIGHT", -pad, 0)
	panel:SetHeight(1)
	panel:Hide()
	empty = W.Text(f.Body, "default", "textDim")
	empty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", pad, -(TOP + 12))
	empty:SetPoint("RIGHT", f.Body, "RIGHT", -pad, 0)
	empty:SetJustifyH("LEFT")
	empty:SetWordWrap(true)
	empty:Hide()
	note = W.Text(f.Body, "small", "textMuted")
	note:SetPoint("TOPLEFT", f.Body, "TOPLEFT", pad, -TOP)
	note:SetPoint("RIGHT", f.Body, "RIGHT", -pad, 0)
	note:SetJustifyH("LEFT")
	note:SetWordWrap(false)
	note:Hide()
end

local function paint(f)
	if not open then
		open = true
		fl("SetWhoToUi", true)
	end
	f.psKeepTabRow = true
	bar:Show()
	local n, total = fl("GetNumWhoResults")
	n, total = n or 0, total or 0
	-- The stock totals line's note past the cap, above the cards so it is seen.
	local more = total > MAX_FROM_SERVER
	local top = TOP + (more and NOTE_H or 0)
	note:SetShown(more)
	note:SetText(("Too many results: showing the first %d of %d. Narrow the search."):format(MAX_FROM_SERVER, total))
	panel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -top)
	panel:SetShown(n > 0)
	paintRows(n, f.BodyWidth)
	local listH = n * (ROW_H + ROW_GAP)
	empty:SetShown(n == 0)
	empty:SetText(searching and "Searching..." or sent and "No one found. Try another search." or "Type a name, zone, guild, race, class or level range, then press Enter.")
	W.SetIconState(bar.Filter, filtered() and true or false)
	bar.Filter.psTip = filtered() and "Filter (on)" or "Filter"
	local fact
	if total > 0 then fact = ("%d found"):format(total) end -- short: the band's subtitle is narrow
	local right = { { label = "Search", onClick = send, opts = { primary = true } } }
	return fact, right, {}, top + listH + 20
end

local function leave(f)
	open = false
	fl("SetWhoToUi", false)
	f.psKeepTabRow = nil
	bar:Hide()
	panel:Hide()
	empty:Hide()
	note:Hide()
	if W.MenuShown(bar.Filter) then W.HideMenu() end
end

-- The stock Who list shows the game's window on every WHO_LIST_UPDATE
-- (LFGWhoListMixin:UpdateWhoList: ShowUIPanel(LFGParentFrame)), so while ours
-- is on, that one event is unregistered on that one frame (docs/CLIENT.md,
-- rule 15's exception) and ours opens on the Who page in its place; switched
-- off, it is registered again.
local taken = false
local function stopStock()
	if not LFGWhoListFrame then return end
	if taken then LFGWhoListFrame:UnregisterEvent("WHO_LIST_UPDATE") else LFGWhoListFrame:RegisterEvent("WHO_LIST_UPDATE") end
end

local function apply(on)
	if on == taken then return end -- off at login: the stock frame is never touched
	taken = on
	stopStock()
end

G.pages.who = { build = build, paint = paint, leave = leave, apply = apply }

Polestar.RegisterEvent("ADDON_LOADED", function(_, name)
	if name == "Blizzard_GroupFinder_VanillaStyle" and taken then stopStock() end
end)

-- Results sent to the UI (ours, or a /who typed in chat) open the Who page,
-- as the stock list opened the game's window.
Polestar.RegisterEvent("WHO_LIST_UPDATE", function()
	searching, sent = false, true
	if open then G.Paint() elseif taken then ns.Show("groupfinder", "who") end
end)
