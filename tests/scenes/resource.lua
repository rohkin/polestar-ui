--@ title: Personal Resource Display: heals, an absorb and a cast's cost
--@ roots: PersonalResourceDisplayFrame
--@ stubs: stub_resource.lua
-- The game's own Personal Resource Display restyled in place: on each bar a track, a flat fill pinned to the game's fill (the header band's sky for health, the power's token for mana), a hairline, and our segments pinned to the game's prediction textures: my heal and another's (the fill lightened), an absorb (text at 0.55), the cast's cost past the game's fill (the power darkened). The game's bar art and prediction textures faded; the bars themselves untouched.
local T = Polestar.Theme
stub.units.player = { name = "Jaina", level = 60, class = "MAGE", player = true, health = 1500, max = 2400, power = 3200, powerMax = 4000, powerType = 0, reaction = 5 }
stub.prd({ heal = 250, otherHeal = 150, absorb = 300, cost = 600 })
stub.advance(0.1)
local P = PersonalResourceDisplayFrame
local hb, pb = P.HealthBarsContainer.healthBar, P.PowerBar
-- Ours on a stock bar: our textures (white), keyed by what they hang on.
local function ours(bar)
	local o = { pinned = {} }
	for _, r in ipairs({ bar:GetRegions() }) do
		if r.kind == "Texture" and r ~= bar:GetStatusBarTexture() and tostring(r:GetTexture()):find("white", 1, true) then
			local p = r.points[1]
			if p and p.rel == bar:GetStatusBarTexture() and r.points[1].relPoint == "TOPLEFT" then o.fill = r
			elseif p and p.rel == bar and r:GetDrawLayer() == "BACKGROUND" then o.track = r
			elseif p and p.rel ~= bar then o.pinned[p.rel] = r end
		end
	end
	return o
end
local function is(tex, r, g, b) local x, y, z = tex:GetVertexColor() return x == r and y == g and z == b end
local h, p = ours(hb), ours(pb)
local sr, sg, sb = T.Color("sky")
assert(h.fill and h.fill:IsShown() and is(h.fill, sr, sg, sb), "the health fill is not ours in sky")
assert(h.track and h.track:IsShown(), "no track")
assert(p.fill and is(p.fill, T.Color("npc")), "the mana fill is not in the npc token")
-- Every prediction the game shows has ours pinned on it and shown; the game's faded.
for _, k in ipairs({ "myHealPrediction", "otherHealPrediction", "totalAbsorb" }) do
	assert(hb[k]:IsShown() and hb[k]:GetAlpha() == 0, "the game's " .. k .. " is not faded")
	assert(h.pinned[hb[k]] and h.pinned[hb[k]]:IsShown(), "no segment of ours on " .. k)
end
assert(not hb.myHealAbsorb:IsShown() and not h.pinned[hb.myHealAbsorb]:IsShown(), "a heal absorb shows with none")
assert(pb.ManaCostPredictionBar:IsShown() and pb.ManaCostPredictionBar:GetAlpha() == 0 and p.pinned[pb.ManaCostPredictionBar]:IsShown(), "the cost")
assert(select(4, h.pinned[hb.totalAbsorb]:GetVertexColor()) == 0.55, "the absorb is not at 0.55")
-- The game's bar art faded, its text in our face.
for _, r in ipairs({ hb:GetRegions() }) do
	if r.GetAtlas and r:GetAtlas() == "UI-HUD-CoolDownManager-Bar-BG" then assert(r:GetAlpha() == 0, "the game's bar art shows") end
end
assert(hb.TextString:GetFont() == (T.FontSpec("number")), "the bar text is not in Polestar's face")
-- A prediction gone: ours hides with the game's.
stub.prd({ heal = 250, cost = 0 })
stub.advance(0.1)
assert(not h.pinned[hb.totalAbsorb]:IsShown() and not p.pinned[pb.ManaCostPredictionBar]:IsShown(), "a segment stayed after the game's hid")
stub.prd({ heal = 250, otherHeal = 150, absorb = 300, cost = 600 })
stub.advance(0.1)
local function polls(file)
	local n = 0
	for _, f in ipairs(stub.frames) do
		local fn = f:GetScript("OnUpdate")
		if fn and f:IsVisible() and debug.getinfo(fn, "S").source:find(file, 1, true) then n = n + 1 end
	end
	return n
end
-- The repaint runs only while the display shows (its driver is under it).
assert(polls("ResourceDisplay.lua") == 1, "no repaint while shown")
PersonalResourceDisplayFrame:Hide()
assert(polls("ResourceDisplay.lua") == 0, "a repaint runs while the display is hidden")
PersonalResourceDisplayFrame:Show()
