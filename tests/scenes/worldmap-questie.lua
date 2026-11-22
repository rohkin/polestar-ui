--@ title: World Map: Questie's icons
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua, stub_questie.lua
-- With Questie loaded, its world map icons for the shown map are mirrored on our canvas (textures of ours, at each icon's spot, size and art); one Questie hides and another zone's are left out; a new map and a zoom draw them afresh; the continent and Azeroth show every zone's by HBD's show flag, none with Questie's "hide icons on continents"; an icon Questie adds, sizes, hides, fades or removes while the map is open follows at once through post-hooks, that icon alone, with no timer; nothing of Questie's is written (the stub errors) and the stock map never opens.
stub.pressKey("M")
local c = PolestarUIWorldMapCanvas
local holder = PolestarUIQuestiePins
assert(holder and holder:GetParent() == c:GetCanvas() and not WorldMapFrame:IsShown(), "no mirror on our canvas")
local function at(r) local _, rel, point, x, y = r:GetPoint(1) return rel == c:GetCanvas() and point == "TOPLEFT" and math.floor(x + 0.5) .. "," .. math.floor(y + 0.5) end
-- The shown textures, as "art@x,y" in order.
local function shown()
	local t, by = {}, {}
	for _, r in ipairs({ holder:GetRegions() }) do
		if r:IsShown() then
			local key = r:GetTexture():match("([%a]+)%.blp$") .. "@" .. tostring(at(r))
			t[#t + 1] = key
			by[key] = r
		end
	end
	table.sort(t)
	return table.concat(t, " "), by
end
local function expect(want, why) local got = shown() assert(got == want, why .. ": " .. got) end
expect("available@251,-334 complete@501,-167", "Elwynn's two icons, not the hidden one or another zone's")
-- Sized as a stock pin holds its icon on screen: the icon's size over the canvas scale.
local function near(a, b) return math.abs(a - b) < 0.01 end
local _, by = shown()
assert(near(by["available@251,-334"]:GetWidth(), 16 / 0.9) and near(by["complete@501,-167"]:GetWidth(), 20 / 0.9), "size")
-- Zoomed in: the same size on screen (a little larger, as HBD's pins), the same spot on the art.
stub.mapScale, stub.mapZoom = 2.7, 1
c:OnCanvasScaleChanged()
_, by = shown()
assert(by["available@251,-334"] and near(by["available@251,-334"]:GetWidth(), 16 * 1.2 / 2.7), "zoom")
stub.mapScale, stub.mapZoom = nil, nil
-- Another zone: its own icons.
c:SetMapID(52)
expect("available@401,-267", "Westfall's icon")
-- The continent: every zone's icon whose flag reaches it (Questie's do), each at its spot there; Duskwood's own-map-only one is left out.
c:SetMapID(13)
expect("available@351,-401 available@564,-417 complete@626,-376", "the continent's icons")
c:SetMapID(47)
expect("event@501,-334", "Duskwood's own icon")
-- Azeroth: the same three, through HBD's world map translation.
c:SetMapID(947)
expect("available@426,-367 available@532,-376 complete@564,-355", "Azeroth's icons")
-- Questie's "hide icons on continents" (its setting resets its icons): none on a continent or Azeroth, zones as before.
Questie.db.profile.hideIconsOnContinents = true
stub.questieReset()
expect("", "hidden on Azeroth")
c:SetMapID(13)
expect("", "hidden on the continent")
c:SetMapID(37)
expect("available@251,-334 complete@501,-167", "back in Elwynn")
Questie.db.profile.hideIconsOnContinents = false
stub.questieReset()
expect("available@251,-334 complete@501,-167", "after Questie's reset")
-- Questie adds, sizes, hides, fades, repaints and removes an icon while the map is open: ours follows at once, that icon alone, with no timer.
_, by = shown()
local kept = by["complete@501,-167"]
local new = stub.questieIcon(37, 0.9, 0.9, "Interface/AddOns/Questie/Icons/loot.blp", 24)
expect("available@251,-334 complete@501,-167 loot@902,-601", "the new icon")
_, by = shown()
assert(near(by["loot@902,-601"]:GetWidth(), 24 / 0.9), "the size Questie set after adding it: " .. by["loot@902,-601"]:GetWidth())
assert(by["complete@501,-167"] == kept, "another icon's texture was redrawn")
new:FakeHide()
expect("available@251,-334 complete@501,-167", "an icon Questie hid")
new:FakeShow()
expect("available@251,-334 complete@501,-167 loot@902,-601", "shown again")
new.texture:SetVertexColor(1, 1, 1, 0.3)
_, by = shown()
assert(near(select(4, by["loot@902,-601"]:GetVertexColor()), 0.3), "a fade")
new.texture:SetTexture("Interface/AddOns/Questie/Icons/slay.blp")
expect("available@251,-334 complete@501,-167 slay@902,-601", "new art")
stub.questieRemove(new)
expect("available@251,-334 complete@501,-167", "removed")
-- Nothing of ours runs on a timer.
assert(not holder:GetScript("OnUpdate"), "a polling OnUpdate")
-- Closed, Questie's changes are not drawn; reopened on the same map, drawn afresh.
PolestarUIWorldMap:Hide()
stub.questieIcon(37, 0.1, 0.1, "Interface/AddOns/Questie/Icons/loot.blp")
stub.pressKey("M")
expect("available@251,-334 complete@501,-167 loot@100,-67", "reopened")
