--@ title: Social: EllesmereUI friend groups
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua, stub_ellesmereui.lua
-- With EllesmereUI loaded, the Friends page shows its friend groups from its own data: its
-- order, colours and folded state; Favorites and the ungrouped friends as its sections.
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
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.psEntry and not r.psEntry.head and r.psEntry.name == name then return r end
	end
end
local function head(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.psEntry and r.psEntry.head and r.psEntry.name:find(name, 1, true) == 1 then return r end
	end
end
assert(heads() == "Raid team 1/1, Favorites 0/1, Guildies 1/1, Friends 3/5", "sections: " .. heads())
assert(row("Mira") and not row("Jon") and row("Sefa") and row("Aelric"), "folded Guildies")
assert(#G.friendGroupOrder == 4, "its saved order is not rewritten")
-- Folding writes its state, both ways.
stub.RunScript(head("Guildies"), "OnClick", "LeftButton")
assert(G.friendGroups[2].collapsed == false and row("Jon"), "unfold Guildies")
stub.RunScript(head("Favorites"), "OnClick", "LeftButton")
assert(G.friendFavCollapsed == true and not row("Sefa"), "fold Favorites")
-- The friend menu, opened from our row, moves a friend to another group.
f.IsMouseOver = function() return true end
local menu = stub.buildMenu("MENU_UNIT_BN_FRIEND", { bnetIDAccount = 102, battleTag = "Mira#1123", friendsList = 1 })
assert(menu[2].title == "EllesmereUI", "its section title")
local sub = menu[3]
assert(sub and sub.text == "Move to Group", "menu entry")
local labels = {}
for _, e in ipairs(sub.entries) do labels[#labels + 1] = e.text or "-" end
assert(table.concat(labels, ", ") == "New Group..., -, Favorites, Guildies, Alts, -, Remove from Group", "menu: " .. table.concat(labels, ", "))
sub.entries[5].fn()
assert(G.friendGroupsByTag["Mira#1123"] == "Alts" and heads():find("Alts 1/1", 1, true), "moved: " .. heads())
f.IsMouseOver = nil
assert(#stub.buildMenu("MENU_UNIT_BN_FRIEND", { bnetIDAccount = 102, battleTag = "Mira#1123" }) == 0, "no entries off our window")
-- Custom Friends List Tiles off in EllesmereUI: the stock groups.
EllesmereUIDB.friendsListCard.customTiles = false
PolestarUI.Show("social", "friends")
assert(heads() == "Favorites 0/1, Friends 5/7", "off: " .. heads())
EllesmereUIDB.friendsListCard.customTiles = nil
G.friendFavCollapsed = nil
G.friendGroupsByTag["Mira#1123"] = "Raid team"
PolestarUI.Show("social", "friends")
