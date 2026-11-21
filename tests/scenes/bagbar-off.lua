--@ title: Bag bar: off
--@ roots: BagsBar
--@ stubs: stub_bagbar.lua
-- Without our Bags window (no bags stub here), a bag slot is lit by the game's own open-bag highlight, faded under our accent. Switched off, live: the frame and hover art, the round masks, the open-bag highlight, the free count's font and the bar's art are the game's again, ours hidden; on and off again, the same. The action bars' switch changes nothing of it.
local function lit(b)
	for _, t in ipairs({ b:GetRegions() }) do
		local l, s = t:GetDrawLayer()
		if t:IsShown() and l == "OVERLAY" and s == 6 and tostring(t:GetTexture()):find("white", 1, true) then return true end
	end
end
stub.bagHighlight(CharacterBag1Slot, true)
stub.advance(0.05)
assert(lit(CharacterBag1Slot) and not lit(CharacterBag2Slot), "the game's open-bag highlight does not light our accent")
assert(CharacterBag1Slot.SlotHighlightTexture:GetAlpha() == 0, "the stock open-bag highlight shows")
PolestarUI.Switch("actionbars", false)
assert(CharacterBag1Slot:GetNormalTexture():GetAlpha() == 0, "the action bars' switch turned the bag bar off")
local font = CharacterBag0Slot.Count:GetFont()
PolestarUI.Switch("bagbar", false)
PolestarUI.Switch("bagbar", true)
assert(CharacterBag0Slot:GetNormalTexture():GetAlpha() == 0, "not restyled when on again")
PolestarUI.Switch("bagbar", false)
stub.advance(0.1)
for _, b in ipairs(stub.bagButtons) do
	assert(b:GetNormalTexture():GetAlpha() == 1 and b:GetPushedTexture():GetAlpha() == 1, b:GetName() .. ": the frame art is not back")
	assert(b:GetHighlightTexture():GetAlpha() == 0.4, b:GetName() .. ": the hover is not the game's")
	assert(b.SlotHighlightTexture:GetAlpha() == 1, b:GetName() .. ": the open-bag highlight is not back")
	assert(b.icon.masks[b.SquareMask] and b.icon.masks[b.Mask], b:GetName() .. ": the icon is not masked again")
	assert(b.Count:GetFont() == font, b:GetName() .. ": the count's font is not the game's")
	for _, r in ipairs({ b:GetRegions() }) do
		assert(not (r:IsShown() and tostring(r:GetTexture()):find("white", 1, true)), b:GetName() .. ": our textures still show")
	end
end
assert(MainMenuBarBackpackButton.FreeSlots:GetFont() == font, "the free count's font is not the game's")
assert(BagsBar.BorderArt:GetAlpha() == 1, "the bar's art is not back")
for d in BagsBar.HorizontalDividersPool:EnumerateActive() do assert(d:GetAlpha() == 1, "a divider is not back") end
