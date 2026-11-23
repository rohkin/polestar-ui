--@ title: World Map: ForeverQuestTint
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua, stub_questie.lua, stub_foreverquesttint.lua
-- With ForeverQuestTint, a quest Forever added gets its teal gradient (a desaturated copy of the icon's art, solid below, fading out above) on the yellow ! and ? of our map: the game's quest pins on our canvas (a giver's plain !, a plain turn-in ?; not a trivial giver's, another icon, or a classic quest's), drawn as a pin is acquired or restyled and taken off on its release, so a pin reused for a classic quest has none; and our mirror of Questie's icons (its available and complete art, plain white; not an objective's, a hovered tint, or a classic quest's), following an art swap, a frame of ours reused for another icon, and its questieTint setting at the next repaint. Nothing runs on a timer.
local I = "Interface\\AddOns\\Questie\\Icons\\"
Questie.ICON_TYPE_AVAILABLE, Questie.ICON_TYPE_COMPLETE, Questie.ICON_TYPE_SLAY = 1, 2, 3
Questie.usedIcons = { I .. "available.blp", I .. "complete.blp", I .. "slay.blp" }
local ATLAS = {
	QuestNormal = { file = "Interface/QuestFrame/QuestMapIcons", leftTexCoord = 0.25, rightTexCoord = 0.5, topTexCoord = 0, bottomTexCoord = 0.5 },
	["UI-QuestIcon-TurnIn-Normal"] = { file = "Interface/QuestFrame/QuestPOI", leftTexCoord = 0, rightTexCoord = 0.25, topTexCoord = 0.5, bottomTexCoord = 1 },
}
C_Texture = C_Texture or {}
local atlasInfo = C_Texture.GetAtlasInfo
function C_Texture.GetAtlasInfo(a) return ATLAS[a] or (atlasInfo and atlasInfo(a)) end
local MARKED, CLASSIC = 9999, 33
assert(PolestarUI.FQTMarked(MARKED) and not PolestarUI.FQTMarked(CLASSIC), "lookup")

stub.pressKey("M")
local c = PolestarUIWorldMapCanvas
local function near(a, b) return math.abs(a - b) < 0.01 end
-- The gradient's two textures on `owner`, when shown: { solid, fade }.
local function tint(owner)
	local t = {}
	for _, r in ipairs({ owner:GetRegions() }) do
		if r:IsShown() and r.desaturated and r.gradient then t[#t + 1] = r end
	end
	table.sort(t, function(a, b) return a:GetHeight() > b:GetHeight() end)
	return #t > 0 and t or nil
end

-- The game's pins, as MapCanvasMixin:AcquirePin and the providers set them up (pooled per template).
local pools = { QuestOfferPinTemplate = {}, QuestPinTemplate = {} }
local function acquire(template, id, atlas, alpha)
	local pin = table.remove(pools[template])
	if not pin then
		pin = CreateFrame("Button", nil, c:GetCanvas())
		pin:SetSize(24, 24)
		if template == "QuestOfferPinTemplate" then
			pin.Texture = pin:CreateTexture(nil, "ARTWORK")
			pin.Texture:SetAllPoints(pin)
			pin.Texture:SetSize(24, 24)
		else
			pin.Display = CreateFrame("Frame", nil, pin)
			pin.Display:SetAllPoints(pin)
			pin.Display.Icon = pin.Display:CreateTexture(nil, "ARTWORK")
			pin.Display.Icon:SetSize(24, 24)
			function pin:GetQuestID() return self.questID end
			function pin:UpdateButtonStyle() self.Display.Icon:SetAtlas(self.style) end
		end
	end
	pin.pinTemplate = template
	pin:SetPoint("CENTER", c:GetCanvas(), "TOPLEFT", 300, -300)
	pin:Show()
	if template == "QuestOfferPinTemplate" then -- its OnAcquired
		pin.questID, pin.pinAlpha = id, alpha or 1
		pin.Texture:SetAtlas(atlas)
	end
	c:RegisterPin(pin)
	if template == "QuestPinTemplate" then -- QuestDataProvider:AddQuest, after AcquirePin
		pin.questID, pin.style = id, atlas
		pin:UpdateButtonStyle()
	end
	return pin
end
local function release(pin)
	c:UnregisterPin(pin)
	pin:Hide()
	table.insert(pools[pin.pinTemplate], pin)
end

local giver = acquire("QuestOfferPinTemplate", MARKED, "QuestNormal")
local g = tint(giver)
assert(g and #g == 2, "a marked giver's !")
local solid, fade = g[1], g[2]
assert(solid.texture == ATLAS.QuestNormal.file and solid.layer == "ARTWORK" and solid.sublayer == 1, "the copy over the art: " .. tostring(solid.texture))
assert(near(solid:GetHeight(), 24 * 0.45) and near(fade:GetHeight(), 24 * 0.30), "solid below, fading above")
-- The vivid tint: { 0.6, 0.9, 0.95 } pushed away from grey (x2), lifted by 1.15.
local lo = solid.gradient.min
assert(near(lo[1], (2.45 / 3 - (2.45 / 3 - 0.6) * 2) * 1.15) and near(lo[2], 1) and near(lo[3], 1) and near(lo[4], 1), "the colour: " .. table.concat(lo, ","))
assert(near(fade.gradient.max[4], 0) and near(fade.gradient.min[4], 1), "the fade")
assert(not tint(acquire("QuestOfferPinTemplate", CLASSIC, "QuestNormal")), "a classic giver's !")
assert(not tint(acquire("QuestOfferPinTemplate", MARKED, "QuestNormal", 0.5)), "a trivial giver's !")
assert(not tint(acquire("QuestOfferPinTemplate", MARKED, "QuestDaily")), "another icon")
-- Released, then reused for a classic quest: none; for a marked one: back.
release(giver)
assert(not tint(giver), "a released pin")
assert(acquire("QuestOfferPinTemplate", CLASSIC, "QuestNormal") == giver and not tint(giver), "reused for a classic quest")
release(giver)
assert(acquire("QuestOfferPinTemplate", MARKED, "QuestNormal") == giver and tint(giver), "reused for a marked one")
-- A turn-in: its quest and art come after AcquirePin; a restyle to another icon takes it off.
local done = acquire("QuestPinTemplate", MARKED, "UI-QuestIcon-TurnIn-Normal")
assert(tint(done.Display) and tint(done.Display)[1].texture == ATLAS["UI-QuestIcon-TurnIn-Normal"].file, "a marked turn-in's ?")
done.style = "UI-QuestIcon-InProgress"
done:UpdateButtonStyle()
assert(not tint(done.Display), "restyled")
release(done)
assert(acquire("QuestPinTemplate", CLASSIC, "UI-QuestIcon-TurnIn-Normal") == done and not tint(done.Display), "a classic turn-in's ?")

-- Questie's icons on our mirror.
local holder = PolestarUIQuestiePins
local function ours(icon) for _, f in ipairs({ holder:GetChildren() }) do if f.psIcon == icon and f:IsShown() then return f end end end
local function data(id, kind) return { Id = id, Type = kind, IconScale = 1 } end
local avail = stub.questieIcon(37, 0.3, 0.3, I .. "available.blp", 16, false, 3, data(MARKED, "available"))
local turnIn = stub.questieIcon(37, 0.4, 0.4, I .. "complete.blp", 16, false, 3, data(MARKED, "complete"))
local classic = stub.questieIcon(37, 0.5, 0.5, I .. "available.blp", 16, false, 3, data(CLASSIC, "available"))
local slay = stub.questieIcon(37, 0.6, 0.6, I .. "slay.blp", 16, false, 3, data(MARKED, "monster"))
local fa = ours(avail)
local q = tint(fa)
assert(q and #q == 2 and q[1].texture == I .. "available.blp" and q[1].layer == "OVERLAY" and q[1].sublayer == 1, "a marked quest's !")
assert(near(q[1]:GetHeight(), fa:GetHeight() * 0.45), "over our frame")
assert(tint(ours(turnIn)), "a marked quest's ?")
assert(not tint(ours(classic)) and not tint(ours(slay)), "a classic quest's ! or an objective")
-- Questie's hover tint: none while not plain white, back after.
avail.texture:SetVertexColor(0.6, 0.6, 0.6, 1)
assert(not tint(fa), "a hovered tint")
avail.texture:SetVertexColor(1, 1, 1, 1)
assert(tint(fa), "back to white")
-- Its art swapped (a level up, a new state): Questie's UpdateTexture.
avail:UpdateTexture(I .. "slay.blp")
assert(not tint(fa), "another art")
avail:UpdateTexture(I .. "available.blp")
assert(tint(fa), "the ! again")
-- Our frame reused for a classic quest's icon: none.
stub.questieRemove(avail)
local again = stub.questieIcon(37, 0.35, 0.35, I .. "available.blp", 16, false, 3, data(CLASSIC, "available"))
assert(ours(again) == fa and not tint(fa), "a reused frame")
-- questieTint off: at the next repaint, none on either; on again.
ForeverQuestTintDB.questieTint = false
c:OnCanvasScaleChanged()
release(giver)
acquire("QuestOfferPinTemplate", MARKED, "QuestNormal")
assert(not tint(ours(turnIn)) and not tint(giver), "questieTint off")
ForeverQuestTintDB.questieTint = nil
c:OnCanvasScaleChanged()
assert(tint(ours(turnIn)), "on again")
assert(not holder:GetScript("OnUpdate") and not c:GetScript("OnUpdate"), "a polling OnUpdate")
