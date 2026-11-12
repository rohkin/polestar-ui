--@ title: Social: filter, groups and presence
--@ roots: PolestarUISocial, PolestarMenu
--@ stubs: stub_social.lua
-- As the stock friends list: search "for keywords"; a Filter menu (Status, then the tags this
-- game type has as Interests and Roles, no Delves) that filters through C_BattleNet.SearchFriends
-- and keeps WoW friends only for presence filters; Favorites and Friends groups that fold; a
-- presence pip and an invite button on each friend; the player's presence and BattleTag in the band.
PolestarUI.Show("social", "friends")
local f = PolestarUISocial
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
local function menuRow(text)
	for _, r in ipairs(PolestarMenu.rows) do
		if r:IsShown() and r.Text:GetText() == text then return r end
	end
end
local function menuTexts()
	local t = {}
	for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then t[#t + 1] = r.Text:GetText() end end
	return table.concat(t, ",")
end
assert(f.Search.Placeholder:GetText() == "Search for keywords", "placeholder")
-- Presence pips: online, away (WoW and Battle.net), busy, offline.
local Theme = Polestar.Theme
local function pip(name) return { row(name).Pip:GetVertexColor() } end
local function is(name, token)
	local c, w = pip(name), { Theme.Color(token) }
	return row(name).Pip:IsShown() and math.abs(c[1] - w[1]) < 0.01 and math.abs(c[2] - w[2]) < 0.01
end
assert(is("Aelric", "success") and is("Brannoc", "warning") and is("Mira", "warning") and is("Jon", "danger") and is("Eldric", "textMuted"), "pips")
assert(not row("Rook").Pip:IsShown() and not row("Favorites 0/1").Pip:IsShown(), "pip on a request or heading")
-- Invite: a friend in WoW only; the app and offline ones show it disabled.
assert(row("Mira").Invite:IsShown() and row("Mira").Invite:IsEnabled(), "invite in WoW")
assert(not row("Jon").Invite:IsEnabled() and not row("Eldric").Invite:IsEnabled(), "invite out of WoW")
row("Aelric").Invite:Click()
assert(stub.invited == "Aelric", "invite button")
row("Mira").Invite:Click()
assert(stub.invited == 2, "Battle.net invite")
-- Groups fold from their heading, at once.
stub.RunScript(row("Friends 5/7"), "OnClick", "LeftButton")
assert(row("Friends 5/7") and not row("Mira") and not row("Aelric") and row("Sefa"), "fold")
stub.RunScript(row("Friends 5/7"), "OnClick", "LeftButton")
assert(row("Mira"), "unfold")
-- The Filter menu: Status, Interests and Roles; no Delves on this game type.
f.psFilter:Click()
assert(PolestarMenu:IsShown(), "no filter menu")
assert(menuTexts() == "Status,Online,Away,Busy,Offline,In Queue,Available For Queue,Interests,Professions,PvP,Raiding,Dungeons,Questing,Roleplaying,Roles,DPS,Healer,Tank", "menu: " .. menuTexts())
-- Away: Mira through the client's search, Brannoc as a WoW friend; the menu stays open.
menuRow("Away"):Click()
assert(stub.searchInfo.isAFK and not stub.searchInfo.isOnline and #stub.searchInfo.tags == 0, "search info")
assert(PolestarMenu:IsShown() and menuRow("Away").psItem.checked, "menu closed on a pick")
assert(row("Mira") and row("Brannoc") and not row("Jon") and not row("Aelric") and not row("Sefa"), "away filter")
assert(row("Friends 2/2") and not row("Favorites 0/1"), "group counts follow the filter")
assert(f.psFilter.Label:GetText() == "Filter (1)", "filter count")
-- A tag keeps Battle.net friends only.
menuRow("Away"):Click()
menuRow("Raiding"):Click()
assert(stub.searchInfo.tags[1] == Enum.BattleNetFriendTag.Raiding, "tag search")
assert(row("Sefa") and row("Mira") and not row("Jon") and not row("Brannoc"), "tag filter")
PolestarUI.Show("social", "friends")
-- The player's presence in the band: the BattleTag with a dot; a pick sets it through C_BattleNet.
local st = f.psStatus
assert(st.Label:GetText() == "Testchar#1000" and st:IsEnabled(), "BattleTag")
st:Click()
menuRow("Busy"):Click()
assert(stub.bnDND == true and not PolestarMenu:IsShown(), "set busy")
local c, w = { st.Dot:GetVertexColor() }, { Theme.Color("danger") }
assert(math.abs(c[1] - w[1]) < 0.01, "dot not busy")
st:Click()
assert(menuRow("Busy").psItem.checked, "busy not checked")
menuRow("Online"):Click()
assert(stub.bnDND == false and stub.bnAFK == false and stub.bnHidden == false, "set online")
-- Copy BattleTag: a modal with the tag selected.
st:Click()
menuRow("Copy BattleTag"):Click()
assert(PolestarModal:IsShown() and f.psCopy.Box:GetText() == "Testchar#1000", "copy BattleTag")
PolestarModal.Box.Action:Click()
-- Clear filters; the Filter button leaves with the friends page.
f.psFilter:Click()
menuRow("Clear filters"):Click()
assert(row("Jon") and row("Aelric") and f.psFilter.Label:GetText() == "Filter", "clear")
PolestarUI.Show("social", "ignored")
assert(not f.psFilter:IsShown() and st:IsShown(), "filter off the friends page")
PolestarUI.Show("social", "friends")
-- Leave the filter menu open on the picture.
f.psFilter:Click()
menuRow("Online"):Click()
