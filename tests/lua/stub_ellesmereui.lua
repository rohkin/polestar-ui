-- EllesmereUI loaded (after stub_social.lua): its friends list and the group
-- store it keeps in EllesmereUIDB.global (EllesmereUI_FriendsList.lua). Mira
-- is in Raid team (gold), Jon in Guildies (folded); Alts is empty and missing
-- from the saved order; a tag points at a group since deleted.
EllesmereUI = { FriendsList = {}, GetBlizzWindowStyle = function() return "eui" end }
EllesmereUIDB = {
	friendsListCard = {},
	global = {
		friendGroups = { { name = "Raid team", collapsed = false }, { name = "Guildies", collapsed = true }, { name = "Alts", collapsed = false } },
		friendGroupsByTag = { ["Mira#1123"] = "Raid team", ["Jon#2871"] = "Guildies", ["Gone#1"] = "Old" },
		friendGroupColors = { ["Raid team"] = { r = 1, g = 0.82, b = 0 } },
		friendGroupOrder = { "Raid team", "_favorites", "Guildies", "_ungrouped" },
	},
}
-- Blizzard_Menu: a tag's ModifyMenu callbacks, run by stub.buildMenu(tag, context)
-- on a root that records its entries ({ text, fn, entries }, { divider }, { title }).
local modifiers = {}
Menu = { IsMenuProxy = function() return true end,
	ModifyMenu = function(tag, fn) modifiers[tag] = modifiers[tag] or {}; table.insert(modifiers[tag], fn) end }
local function node()
	local n = { entries = {} }
	function n:CreateButton(text, fn) local c = node(); c.text, c.fn = text, fn; table.insert(self.entries, c); return c end
	function n:CreateDivider() table.insert(self.entries, { divider = true }) end
	function n:CreateTitle(text) table.insert(self.entries, { title = text }) end
	return n
end
function stub.buildMenu(tag, ctx)
	local root = node()
	for _, fn in ipairs(modifiers[tag] or {}) do fn(nil, root, ctx) end
	return root.entries
end
-- Battle.net's favorite switch: BNSetFriendFavoriteFlag records stub.favSet
-- = { id, on } and the friend's isFavorite follows it (stub.favorites[id]).
stub.favorites = {}
local accountInfo = C_BattleNet.GetFriendAccountInfo
function C_BattleNet.GetFriendAccountInfo(i)
	local a = accountInfo(i)
	if a and stub.favorites[a.bnetAccountID] ~= nil then a.isFavorite = stub.favorites[a.bnetAccountID] end
	return a
end
function C_BattleNet.GetAccountInfoByID(id)
	for i = 1, BNGetNumFriends() do
		local a = C_BattleNet.GetFriendAccountInfo(i)
		if a.bnetAccountID == id then return a end
	end
end
function BNSetFriendFavoriteFlag(id, on) stub.favSet = { id, on }; stub.favorites[id] = on end
