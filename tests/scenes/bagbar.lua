--@ title: Bag bar
--@ roots: BagsBar
--@ stubs: stub_npc.lua, stub_bags.lua, stub_bagbar.lua
-- The game's bag bar restyled in place, in the action buttons' look whatever the action bars' switch says: the frame art, the bar's art and its dividers faded, icons square (both stock masks off, the template's square and the item button's rounded one, cropped again after the game resets the coords with a new bag), our ground and 1px hairline round each, the free count in Polestar's number face, outlined; the fourth bag slot empty, a well. Our Bags window open lights every slot with the accent (the game's own open-bag highlight, which the parked stock bags never show, faded). The game re-sets the hover's alpha with each new icon: faded again.
PolestarUI.Switch("actionbars", false)
local Theme = Polestar.Theme
local function styled(b)
	return b:GetNormalTexture():GetAlpha() == 0 and b:GetHighlightTexture():GetAlpha() == 0 and b.icon.mask == nil
end
for _, b in ipairs(stub.bagButtons) do assert(styled(b), b:GetName() .. " is not restyled") end
assert(BagsBar.BorderArt:GetAlpha() == 0, "the bar's frame art shows")
for d in BagsBar.HorizontalDividersPool:EnumerateActive() do assert(d:GetAlpha() == 0, "a divider between the slots shows") end
assert(MainMenuBarBackpackButton.FreeSlots:GetFont() == (Theme.FontSpec("number")) and select(3, MainMenuBarBackpackButton.FreeSlots:GetFont()) == "OUTLINE", "the free count is not in Polestar's face")
local function lit(b)
	local r, g, bl = Theme.Accent()
	for _, t in ipairs({ b:GetRegions() }) do
		local l, s = t:GetDrawLayer()
		if t:IsShown() and l == "OVERLAY" and s == 6 and tostring(t:GetTexture()):find("white", 1, true) then return true end
	end
end
assert(not lit(CharacterBag0Slot), "lit with the bags closed")
-- The game's hover alpha after a new icon (UpdateTextures).
stub.bagUpdateTextures(CharacterBag1Slot)
stub.advance(0.05)
assert(CharacterBag1Slot:GetHighlightTexture():GetAlpha() == 0, "the hover shows again after a new icon")
-- A new bag in the slot: the game resets the icon's coords; cropped again.
stub.bagSetTexture(CharacterBag2Slot)
stub.advance(0.05)
assert(CharacterBag2Slot.icon:GetTexCoord() == 0.08, "a new bag's icon is not cropped again")
-- Our Bags window: the bar's click opens it, every slot lit.
stub.RunScript(MainMenuBarBackpackButton, "OnClick", "LeftButton")
stub.advance(0.1)
assert(PolestarUIBags:IsShown(), "the backpack's click does not open our bags")
stub.advance(0.05)
for _, b in ipairs(stub.bagButtons) do assert(lit(b), b:GetName() .. " is not lit with our bags open") end
