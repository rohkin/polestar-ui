--@ title: Social: EllesmereUI friend groups, edited
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua, stub_ellesmereui.lua
-- Every group change writes EllesmereUI's own data as its code does: a new
-- group from the friend menu, rename (and colour), delete, move, Favorites.
PolestarUI.Show("social", "friends")
local f = PolestarUISocial
local G = EllesmereUIDB.global
local function heads()
	local out = {}
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.psEntry and r.psEntry.head then out[#out + 1] = r.psEntry.name end
	end
	return table.concat(out, ", ")
end
local function head(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.psEntry and r.psEntry.head and r.psEntry.name:find(name, 1, true) == 1 then return r end
	end
end
local function tool(name, tip)
	for _, b in ipairs(head(name).psTools or {}) do
		if b:IsShown() and b.psTip == tip then return b end
	end
end
local function click(b) stub.RunScript(b, "OnClick", "LeftButton") end
local function field()
	for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do
		if c:IsShown() and type(c.Box) == "table" then return c.Box end
	end
end
local function sub(id, tag)
	local menu = stub.buildMenu("MENU_UNIT_BN_FRIEND", { bnetIDAccount = id, battleTag = tag, friendsList = 1 })
	local labels = {}
	for _, e in ipairs(menu[3].entries) do labels[#labels + 1] = e.text or "-" end
	return menu[3], table.concat(labels, ", ")
end
local function pick(s, text)
	for _, e in ipairs(s.entries) do if e.text == text then return e.fn() end end
	error("no entry " .. text)
end
f.IsMouseOver = function() return true end

-- Header tools: a group has move, edit and delete; Favorites and Friends move
-- and colour; the first can't move up, the last can't move down.
assert(tool("Raid team", "Delete group") and not tool("Favorites", "Delete group") and tool("Favorites", "Change colour"), "tools")
assert(not tool("Raid team", "Move up"):IsEnabled() and not tool("Friends", "Move down"):IsEnabled(), "ends")

-- New Group... from the menu of Sefa (a favorite: Favorites counts as grouped).
local s, labels = sub(101, "Sefa#4410")
assert(s.text == "Move to Group" and labels == "New Group..., -, Raid team, Guildies, Alts, -, Remove from Group", labels)
pick(s, "New Group...")
assert(PolestarModal:IsShown() and PolestarModal.Box.Action.Label:GetText() == "Create", "new group dialog")
field():SetText("  Healers  ")
PolestarModal.Box.Action:Click()
assert(G.friendGroups[4].name == "Healers" and G.friendGroups[4].collapsed == false, "group made")
assert(G.friendGroupsByTag["Sefa#4410"] == "Healers" and stub.favSet == nil, "Sefa moved, favorite untouched")
assert(heads() == "Raid team 1/1, Guildies 1/1, Healers 0/1, Friends 3/5", heads())

-- Rename: a taken name does nothing; a new one carries colour, order and members.
click(tool("Raid team", "Edit group"))
assert(field():GetText() == "Raid team", "rename field")
field():SetText("Guildies")
PolestarModal.Box.Action:Click()
assert(G.friendGroups[1].name == "Raid team", "taken name")
click(tool("Raid team", "Edit group"))
field():SetText("Core")
PolestarModal.Box.Action:Click()
assert(G.friendGroups[1].name == "Core" and G.friendGroupColors.Core and not G.friendGroupColors["Raid team"], "renamed, colour kept")
assert(G.friendGroupOrder[1] == "Core" and G.friendGroupsByTag["Mira#1123"] == "Core", "order and member renamed")

-- Colour: Favorites' through the game's picker; a cancel puts the old one back.
click(tool("Friends", "Change colour"))
ColorPickerFrame.info.swatchFunc()
assert(G.friendGroupColors._ungrouped and G.friendGroupColors._ungrouped.r == 1, "colour picked")
ColorPickerFrame.info.cancelFunc()
assert(G.friendGroupColors._ungrouped == nil, "colour cancelled")

-- Move: Guildies up swaps with Core in the saved order, written whole first.
click(tool("Guildies", "Move up"))
assert(table.concat(G.friendGroupOrder, ",") == "Guildies,_favorites,Core,Alts,Healers,_ungrouped", table.concat(G.friendGroupOrder, ","))

-- Delete, after Polestar's confirmation: members, colour gone; Sefa back in Favorites.
click(tool("Healers", "Delete group"))
assert(PolestarModal:IsShown() and PolestarModal.Box.Action.Label:GetText() == "Delete", "delete dialog")
PolestarModal.Box.Action:Click()
assert(not G.friendGroups[4] and G.friendGroupsByTag["Sefa#4410"] == nil, "deleted")
assert(heads() == "Guildies 1/1, Favorites 0/1, Core 1/1, Friends 3/5", heads())

-- Favorites: Jon leaves Guildies and Battle.net's favorite switch is set.
s, labels = sub(103, "Jon#2871")
assert(labels == "New Group..., -, Favorites, Core, Alts, -, Remove from Group", labels)
pick(s, "Favorites")
assert(G.friendGroupsByTag["Jon#2871"] == nil and stub.favSet[1] == 103 and stub.favSet[2] == true, "favorite set")
PolestarUI.Show("social", "friends")
assert(heads() == "Favorites 1/2, Core 1/1, Friends 3/5", heads())
-- Remove from Group out of Favorites turns it off again.
s = sub(103, "Jon#2871")
pick(s, "Remove from Group")
assert(stub.favSet[2] == false, "favorite cleared")
-- A group's member leaves it; not a favorite, so Battle.net isn't asked.
stub.favSet = nil
s = sub(102, "Mira#1123")
pick(s, "Remove from Group")
assert(G.friendGroupsByTag["Mira#1123"] == nil and stub.favSet == nil, "removed from group")
s, labels = sub(102, "Mira#1123")
assert(s.text == "Add to Group" and labels == "New Group..., -, Favorites, Core, Guildies, Alts", labels)
f.IsMouseOver = nil
PolestarUI.Show("social", "friends")
