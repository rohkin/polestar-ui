-- EllesmereUI's friend groups in our Social (docs/addons.md): the Friends
-- page in its sections, from its own saved data (EllesmereUIDB.global, as
-- EllesmereUI_FriendsList.lua keeps it): order, colours, folded state, each
-- Battle.net friend's group by BattleTag. Every change writes that data as
-- its own code does (CreateGroup, RenameGroup, DeleteGroup, PlaceFriend,
-- MoveGroup, ToggleCollapsed, the colour pick); its list reads it afresh
-- each time it shows. A no-op without the addon.

local ADDON, ns = ...

ns.AfterLogin(function()
local social = ns.modules.social
if not (social and type(EllesmereUI) == "table" and EllesmereUI.FriendsList) then return end

local W = Polestar.Widgets
local FAV, UNGROUPED = "_favorites", "_ungrouped"
local GROUP_NAME_MAX = 32

-- Its group store, or nil while its custom list is off (Friends List card,
-- Custom Friends List Tiles: unset follows the card's look). Missing tables
-- are made as its Store() makes them.
local function store()
	local db = EllesmereUIDB
	if type(db) ~= "table" then return end
	local card = type(db.friendsListCard) == "table" and db.friendsListCard or {}
	if card.enabled == false then return end
	local on = card.customTiles
	if on == nil then
		local ok, style = pcall(EllesmereUI.GetBlizzWindowStyle or error, "socialui")
		on = ok and style ~= "off"
	end
	if not on then return end
	if type(db.global) ~= "table" then db.global = {} end
	local g = db.global
	for _, k in ipairs({ "friendGroups", "friendGroupsByTag", "friendGroupColors", "friendGroupOrder" }) do
		if type(g[k]) ~= "table" then g[k] = {} end
	end
	return g
end

local function findGroup(g, name)
	for i, grp in ipairs(g.friendGroups) do if grp.name == name then return grp, i end end
end

-- Its CleanGroupName: trimmed, not a section key, at most 32 letters.
local function cleanName(text)
	if type(text) ~= "string" then return end
	local name = strtrim(text)
	if name == "" or name == FAV or name == UNGROUPED then return end
	return name:sub(1, GROUP_NAME_MAX)
end

-- A friend's key in its store: the BattleTag, else "title:" and the character
-- the client whispers (a friend added by character name).
local function friendKey(tag, account)
	if tag and tag ~= "" then return tag end
	local t = account and C_BattleNet.GetDefaultTitleWhisperTarget and ns.Clean(C_BattleNet.GetDefaultTitleWhisperTarget(account))
	return t and t ~= "" and "title:" .. t or nil
end

-- The section a friend sits in, as its BucketOf: its group, then Favorites,
-- else the ungrouped Friends.
local function bucket(g, key, fav)
	local name = key and g.friendGroupsByTag[key]
	if name and findGroup(g, name) then return name end
	return fav and FAV or UNGROUPED
end

-- Its section order, as its ValidOrder makes it: the saved order, Favorites
-- first if missing, new groups before the ungrouped, those last. Written back
-- (when it differs) only before a move, as its MoveGroup does.
local function order(g, write)
	local out, seen = {}, {}
	for _, k in ipairs(g.friendGroupOrder) do
		if not seen[k] and (k == FAV or k == UNGROUPED or findGroup(g, k)) then out[#out + 1] = k; seen[k] = true end
	end
	if not seen[FAV] then table.insert(out, 1, FAV); seen[FAV] = true end
	for _, grp in ipairs(g.friendGroups) do
		if not seen[grp.name] then
			local at = #out + 1
			for i, k in ipairs(out) do if k == UNGROUPED then at = i; break end end
			table.insert(out, at, grp.name)
			seen[grp.name] = true
		end
	end
	if not seen[UNGROUPED] then out[#out + 1] = UNGROUPED end
	if write and table.concat(out, "\0") ~= table.concat(g.friendGroupOrder, "\0") then
		local fresh = {}
		for i, k in ipairs(out) do fresh[i] = k end
		g.friendGroupOrder = fresh
	end
	return out
end

local function shut(g, k)
	if k == FAV then return g.friendFavCollapsed == true end
	if k == UNGROUPED then return g.friendUngroupedCollapsed == true end
	local grp = findGroup(g, k)
	return grp ~= nil and grp.collapsed == true
end

-- Its group changes, each followed by our redraw.
local function fold(g, k)
	if k == FAV then g.friendFavCollapsed = not g.friendFavCollapsed
	elseif k == UNGROUPED then g.friendUngroupedCollapsed = not g.friendUngroupedCollapsed
	else local grp = findGroup(g, k); if grp then grp.collapsed = not grp.collapsed end end
	social.Show()
end

local function createGroup(text, key)
	local g, name = store(), cleanName(text)
	if not (g and name) then return end
	if not findGroup(g, name) then g.friendGroups[#g.friendGroups + 1] = { name = name, collapsed = false } end
	if key then g.friendGroupsByTag[key] = name end
	social.Show()
end

local function renameGroup(old, text)
	local g, name = store(), cleanName(text)
	local grp = g and findGroup(g, old)
	if not (name and grp) or name == old or findGroup(g, name) then return end
	grp.name = name
	if g.friendGroupColors[old] then
		g.friendGroupColors[name], g.friendGroupColors[old] = g.friendGroupColors[old], nil
	end
	for i, k in ipairs(g.friendGroupOrder) do if k == old then g.friendGroupOrder[i] = name; break end end
	for key, n in pairs(g.friendGroupsByTag) do if n == old then g.friendGroupsByTag[key] = name end end
	social.Show()
end

-- Its DeleteGroup: the order keeps the name until its ValidOrder drops it.
local function deleteGroup(name)
	local g = store()
	if not g then return end
	local _, at = findGroup(g, name)
	if not at then return end
	table.remove(g.friendGroups, at)
	for key, n in pairs(g.friendGroupsByTag) do if n == name then g.friendGroupsByTag[key] = nil end end
	g.friendGroupColors[name] = nil
	social.Show()
end

local function isFavorite(id)
	local info = C_BattleNet.GetAccountInfoByID and C_BattleNet.GetAccountInfoByID(id)
	return info and ns.Clean(info.isFavorite) == true or false
end

-- Its PlaceFriend: a group is its data alone; Favorites or the ungrouped
-- friends clear the group and set Battle.net's favorite switch, sent only
-- when it differs (its AskFavorite). The list redraws on the client's event.
local function place(id, key, target)
	local g = store()
	if not g then return end
	if target == FAV or target == UNGROUPED then
		g.friendGroupsByTag[key] = nil
		local want = target == FAV
		if isFavorite(id) ~= want then BNSetFriendFavoriteFlag(id, want) end
	else
		g.friendGroupsByTag[key] = target
	end
	social.Show()
end

-- Its MoveGroup: swaps a section with the shown one above (-1) or below (1).
local rendered = {}
local function moveGroup(key, dir)
	local at
	for i, k in ipairs(rendered) do if k == key then at = i end end
	local other = at and rendered[at + dir]
	local g = store()
	if not (other and g) then return end
	order(g, true)
	local o, a, b = g.friendGroupOrder
	for i, k in ipairs(o) do if k == key then a = i elseif k == other then b = i end end
	if a and b then o[a], o[b] = o[b], o[a]; social.Show() end
end

-- A section's colour, as its PickSectionColor: the game's colour picker,
-- each pick kept, a cancel puts the old one back.
local function pickColor(key)
	if not (ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow) or InCombatLockdown() then return end
	local colors = store().friendGroupColors
	local was = colors[key]
	local function set(c) colors[key] = c; social.Show() end
	local r, g, b = 1, 1, 1
	if was then r, g, b = was.r, was.g, was.b end
	ColorPickerFrame:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false,
		swatchFunc = function() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); set({ r = nr, g = ng, b = nb }) end,
		cancelFunc = function() set(was) end })
end

-- A name field for our dialog (Enter takes its action); `swatch` adds the
-- colour button its rename popup has beside the name.
local fields = {}
local function nameField(kind, swatch)
	local body = fields[kind]
	if not body then
		body = CreateFrame("Frame", nil, social.psFrame)
		body:SetSize(352, 30)
		body.Box = ns.TextField(body, swatch and 318 or 352, GROUP_NAME_MAX)
		body.Box:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
		body.Box:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", swatch and -34 or 0, 0)
		body.Box:SetScript("OnEnterPressed", function() PolestarModal.Box.Action:Click() end)
		if swatch then
			body.Swatch = W.IconButton(body, "palette", 30, "Colour", function() pickColor(body.psKey) end)
			body.Swatch:SetPoint("RIGHT", body, "RIGHT", 0, 0)
		end
		fields[kind] = body
	end
	return body
end

local function promptNew(key)
	local body = nameField("new")
	body.Box:SetText("")
	ns.ModalWith({ title = "New group", text = "Enter a name for the new group:", action = "Create",
		onAccept = function() createGroup(body.Box:GetText(), key) end }, body)
	body.Box:SetFocus()
end

local function promptRename(name)
	local body = nameField("rename", ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow)
	body.psKey = name
	body.Box:SetText(name)
	ns.ModalWith({ title = "Rename group", text = "Enter a new name for this group:", action = "Rename",
		onAccept = function() renameGroup(name, body.Box:GetText()) end }, body)
	body.Box:SetFocus()
end

local function promptDelete(name)
	W.Modal({ title = "Delete group", action = "Delete", danger = true,
		text = ("Delete the group %s? Its friends go back to Favorites or the Friends section."):format(name),
		onAccept = function() deleteGroup(name) end })
end

-- Its header icons, right to left: move down, move up, the pencil (a group's
-- name and colour; the colour alone for Favorites and Friends), delete (a
-- group's). `tools` runs once per shown head, in order: that is `rendered`.
local function tools(k)
	local custom = k ~= FAV and k ~= UNGROUPED
	return function(first, last)
		if first then rendered = {} end
		rendered[#rendered + 1] = k
		local t = {
			{ icon = "chevron-down", tip = "Move down", off = last, fn = function() moveGroup(k, 1) end },
			{ icon = "chevron-up", tip = "Move up", off = first, fn = function() moveGroup(k, -1) end },
		}
		if custom then
			t[3] = { icon = "icon-note", tip = "Edit group", fn = function() promptRename(k) end }
			t[4] = { icon = "close", tip = "Delete group", fn = function() promptDelete(k) end }
		elseif ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
			t[3] = { icon = "palette", tip = "Change colour", fn = function() pickColor(k) end }
		end
		return t
	end
end

function social.friendHeads()
	local g = store()
	if not g then return end
	local heads = {}
	for _, k in ipairs(order(g)) do
		local title = k == FAV and "Favorites" or k == UNGROUPED and "Friends" or k
		local c = g.friendGroupColors[k]
		heads[#heads + 1] = { key = "eui:" .. k, shut = shut(g, k), fold = function() fold(g, k) end,
			color = type(c) == "table" and tonumber(c.r) and c or nil, tools = tools(k),
			test = function(e) return bucket(g, e.bnet and friendKey(e.tag, e.account), e.favorite) == k end,
			label = function(on, n) return ("%s %d/%d"):format(title, on, n) end }
	end
	return heads
end

-- Its "EllesmereUI" section in the game's Battle.net friend menu, opened from
-- our rows: a menu entry added by tag, as EllesmereUI adds its own (only on a
-- client that isolates added entries, Menu.IsMenuProxy).
local function addEntries(_, root, ctx)
	local w = social.psFrame
	local g = store()
	if not (g and w and w:IsShown() and w:IsMouseOver() and type(ctx) == "table") then return end
	local id = tonumber(ctx.bnetIDAccount)
	local key = id and friendKey(ns.Clean(ctx.battleTag), id)
	if not key then return end
	local current = bucket(g, key, isFavorite(id))
	root:CreateDivider()
	if root.CreateTitle then root:CreateTitle("EllesmereUI") end
	local grouped = current ~= UNGROUPED
	local sub = root:CreateButton(grouped and "Move to Group" or "Add to Group")
	sub:CreateButton("New Group...", function() promptNew(key) end)
	if current ~= FAV or #g.friendGroups > 0 then sub:CreateDivider() end
	if current ~= FAV then sub:CreateButton(FAVORITES or "Favorites", function() place(id, key, FAV) end) end
	for _, grp in ipairs(g.friendGroups) do
		local name = grp.name
		if name ~= current then sub:CreateButton(name, function() place(id, key, name) end) end
	end
	if grouped then
		sub:CreateDivider()
		sub:CreateButton("Remove from Group", function() place(id, key, UNGROUPED) end)
	end
end

if Menu and Menu.ModifyMenu and Menu.IsMenuProxy then
	for _, tag in ipairs({ "MENU_UNIT_BN_FRIEND", "MENU_UNIT_BN_FRIEND_OFFLINE" }) do
		pcall(Menu.ModifyMenu, tag, addEntries)
	end
end
end)
