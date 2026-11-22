--@ title: World Map: Questie's icons
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua, stub_questie.lua
-- With Questie loaded, its world map icons for the shown map are mirrored on our canvas (frames of ours, at each icon's spot, size, art and frame level, with its objective glow and overlay; sized as Questie sizes them for the shown kind of map); one Questie hides and another zone's are left out; a new map and a zoom draw them afresh; the continent and Azeroth show every zone's by HBD's show flag, none with Questie's "hide icons on continents"; an icon Questie adds, sizes, hides, fades or removes while the map is open follows at once through post-hooks, that icon alone, with no timer; hovered, an icon shows Questie's tooltip in a tooltip of ours in Polestar's look (never GameTooltip), with the icons round it, its long form on Shift; a click opens the icon's zone on our map, a modified click is the icon's own, a right-click goes out a map; nothing of Questie's is written (the stub errors) and the stock map never opens.
stub.pressKey("M")
local c = PolestarUIWorldMapCanvas
local holder = PolestarUIQuestiePins
assert(holder and holder:GetParent() == c:GetCanvas() and not WorldMapFrame:IsShown(), "no mirror on our canvas")
local function at(r) local _, rel, point, x, y = r:GetPoint(1) return rel == c:GetCanvas() and point == "TOPLEFT" and math.floor(x + 0.5) .. "," .. math.floor(y + 0.5) end
-- The shown textures, as "art@x,y" in order.
local function shown()
	local t, by = {}, {}
	for _, r in ipairs({ holder:GetChildren() }) do
		if r:IsShown() then
			local key = r.tex:GetTexture():match("([%a]+)%.blp$") .. "@" .. tostring(at(r))
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
assert(near(select(4, by["loot@902,-601"].tex:GetVertexColor()), 0.3), "a fade")
new.texture:SetTexture("Interface/AddOns/Questie/Icons/slay.blp")
expect("available@251,-334 complete@501,-167 slay@902,-601", "new art")
stub.questieRemove(new)
expect("available@251,-334 complete@501,-167", "removed")
-- An objective: Questie's glow behind it in the objective's colour (its rule: the setting, an objective, not a giver or a turn-in), 1.13 its size; a turn-in in front of the rest; the size Questie's settings give (16 x icon scale x map icon scale), smaller on a continent as on the stock map.
local slay = stub.questieIcon(37, 0.6, 0.6, "Interface/AddOns/Questie/Icons/slay.blp", 12, false, 3, { Type = "monster", IconScale = 1, ObjectiveData = { Color = { 0.2, 0.8, 0.4 } } })
local done = stub.questieIcon(37, 0.6, 0.62, "Interface/AddOns/Questie/Icons/complete.blp", 12, false, 3, { Type = "complete", IconScale = 1.2, ObjectiveData = { Color = { 1, 1, 1 } } })
_, by = shown()
local s1, d1 = by["slay@601,-401"], by["complete@601,-414"]
assert(s1 and d1, "the objective and the turn-in: " .. shown())
assert(near(s1:GetWidth(), 16 * 0.75 / 0.9) and near(d1:GetWidth(), 16 * 1.2 * 0.75 / 0.9), "Questie's size: " .. s1:GetWidth())
local gr, gg, gb = s1.glow:GetVertexColor()
assert(s1.glow:IsShown() and near(gr, 0.2) and near(gg, 0.8) and near(gb, 0.4) and near(s1.glow:GetWidth(), s1:GetWidth() * 1.13), "the objective's glow")
assert(not d1.glow:IsShown() and not kept.glow:IsShown(), "a glow on a turn-in or a plain icon")
assert(d1:GetFrameLevel() > s1:GetFrameLevel() and s1:GetFrameLevel() >= holder:GetFrameLevel(), "the turn-in in front")
assert(not s1.over:IsShown(), "an overlay with none set")
slay.overlayTexture:SetTexture("Interface/AddOns/Questie/Icons/loot_overlay.png")
slay.overlayTexture:Show()
slay.texture:SetVertexColor(1, 1, 1, 1) -- UpdateTexture ends on the colour
assert(s1.over:IsShown() and s1.over:GetTexture():find("loot_overlay", 1, true), "the overlay")
-- The glow setting off (Questie's handler walks its icons): no glow, and on again.
local pool = QuestieLoader:ImportModule("QuestieFramePool")
Questie.db.profile.alwaysGlowMap = false
pool:UpdateGlowConfig(false, false)
assert(not s1.glow:IsShown(), "the glow with the setting off")
Questie.db.profile.alwaysGlowMap = true
pool:UpdateGlowConfig(false, true)
assert(s1.glow:IsShown(), "the glow back")
c:SetMapID(13)
_, by = shown()
assert(near(by["slay@651,-434"]:GetWidth(), 16 * 0.75 * 0.9 / 0.9), "smaller on the continent: " .. shown())
c:SetMapID(37)
stub.questieRemove(slay)
stub.questieRemove(done)
-- Hover: Questie's own tooltip, in a tooltip of ours anchored to our frame, listing the hovered icon and the drawn ones round it (within 1 in zone coordinates on a zone), not a far one; GameTooltip is left alone.
local I = "Interface/AddOns/Questie/Icons/"
local kobold = stub.questieIcon(37, 0.30, 0.30, I .. "slay.blp", 12, false, 3, { Type = "monster", Name = "Kobold", IconScale = 1 })
local candle = stub.questieIcon(37, 0.305, 0.30, I .. "loot.blp", 12, false, 3, { Type = "item", Name = "Candle", IconScale = 1 })
local far = stub.questieIcon(37, 0.5, 0.6, I .. "event.blp", 12, false, 3, { Type = "event", Name = "Far", IconScale = 1 })
_, by = shown()
local fk, fc = by["slay@301,-200"], by["loot@306,-200"]
assert(fk and fc and fk:IsMouseEnabled(), "the hover icons: " .. shown())
stub.RunScript(fk, "OnEnter")
local tip = PolestarUIQuestieTooltip
assert(tip and tip:IsShown() and tip.owner == fk and tip.anchor == "ANCHOR_CURSOR" and GameTooltip.owner ~= fk, "our tooltip on our frame")
assert(stub.questieTip.icon == kobold and stub.questieTip.tooltip == tip and stub.questieTip.owner == fk, "Questie's tooltip call")
assert(table.concat(tip.lines, ",") == "Kobold,Candle", "the hovered icon and its neighbour: " .. table.concat(tip.lines, ","))
assert(tip.NineSlice.Center:GetAlpha() == 0, "our tooltip in Polestar's look")
-- Questie tints the hovered quest's icon: ours follows it, and back on leave.
assert(near((fk.tex:GetVertexColor()), 0.6), "the hover tint")
-- Shift: Questie's long form, drawn again on the modifier event.
stub.keys.shift = true
stub.fire("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
assert(tip:IsShown() and tip.owner == fk and tip.lines[1] == "Kobold (long)" and #tip.lines == 2, "the long form: " .. table.concat(tip.lines, ","))
stub.keys.shift = nil
stub.RunScript(fk, "OnLeave")
assert(not tip:IsShown() and stub.questieUnhovered == kobold.data and near((fk.tex:GetVertexColor()), 1), "leave: hidden, Questie's highlights given back")
-- An icon Questie removes under the mouse takes its tooltip with it.
stub.RunScript(fc, "OnEnter")
assert(tip:IsShown() and tip.lines[1] == "Candle", "the neighbour's tooltip")
stub.questieUnhovered = nil
stub.questieRemove(candle)
assert(not tip:IsShown() and stub.questieUnhovered, "the tooltip of a removed icon")
-- Clicks. A plain left click on the icon's own map does nothing; with a modifier it is the icon's own click; a right-click goes out a map, as on the map under it; on the continent a plain click opens the icon's zone on our map, never the stock map.
stub.RunScript(fk, "OnMouseUp", "LeftButton")
assert(c.mapID == 37 and not stub.questieClicked, "a plain click on its own map")
stub.keys.shift = true
stub.RunScript(fk, "OnMouseUp", "LeftButton")
assert(stub.questieClicked and stub.questieClicked[1] == kobold and stub.questieClicked[2] == "LeftButton", "the icon's own click")
stub.keys.shift = nil
stub.RunScript(fk, "OnMouseUp", "RightButton")
assert(c.mapID == 13, "right-click out a map")
_, by = shown()
stub.RunScript(by["slay@576,-384"], "OnMouseUp", "LeftButton")
assert(c.mapID == 37 and not WorldMapFrame:IsShown(), "a click opens the icon's zone on our map: " .. shown())
stub.questieRemove(kobold)
stub.questieRemove(far)
-- Nothing of ours runs on a timer.
assert(not holder:GetScript("OnUpdate"), "a polling OnUpdate")
-- Closed, Questie's changes are not drawn; reopened on the same map, drawn afresh.
PolestarUIWorldMap:Hide()
stub.questieIcon(37, 0.1, 0.1, "Interface/AddOns/Questie/Icons/loot.blp")
stub.pressKey("M")
expect("available@251,-334 complete@501,-167 loot@100,-67", "reopened")
