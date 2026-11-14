--@ title: Action bars
--@ roots: MainActionBar, MultiBarBottomLeft, MultiBarRight, PetActionBar, StanceBar, SpellFlyout
--@ stubs: stub_actionbars.lua
-- The game's action buttons restyled in place, on every bar (main, bottom left, right, pet, stance): the slot and frame art faded, the icons square (unmasked, cropped), our ground and 1px hairline, the key, count and macro name in Polestar's faces at the game's sizes and colours, the key and count outlined; empty slots as wells. The first stance is on (checked): the accent wash and hairline. The fourth button held down (its key pressed): the accent wash. The equipped item's green border stays the game's. A flyout opened over the sixth button: its buttons, made now, restyled.
local function styled(b)
	return b.NormalTexture:GetAlpha() == 0 and b.SlotArt:GetAlpha() == 0 and b.icon.mask == nil and b.HotKey:GetFont() == (Polestar.Theme.FontSpec("number"))
end
for _, b in ipairs({ ActionButton1, ActionButton12, MultiBarBottomLeftButton3, MultiBarRightButton1, PetActionButton2, StanceButton1 }) do
	assert(styled(b), b:GetName() .. " is not restyled")
end
local r, g, b = ActionButton1.HotKey:GetTextColor()
assert(r == 0.6 and g == 0.6 and b == 0.6, "the key's colour is not the game's")
-- The range dot keeps the game's face (Fira Sans and Open Sans have no glyph for it); a key again, Polestar's.
assert(ActionButton11.HotKey:GetFont() == STANDARD_TEXT_FONT, "the range dot is not in the game's face")
ActionButton11.HotKey:SetText("Q")
stub.advance(0.05)
assert(ActionButton11.HotKey:GetFont() == (Polestar.Theme.FontSpec("number")), "a key is not in Polestar's face")
ActionButton11.HotKey:SetText(RANGE_INDICATOR)
stub.advance(0.05)
assert(ActionButton11.HotKey:GetFont() == STANDARD_TEXT_FONT, "the dot written later is not in the game's face")
assert(select(3, ActionButton1.HotKey:GetFont()) == "OUTLINE" and select(3, ActionButton10.Count:GetFont()) == "OUTLINE", "the key and count are not outlined")
assert(ActionButton8.Border:IsShown() and select(4, ActionButton8.Border:GetVertexColor()) == 0.5 and ActionButton8.Border:GetAlpha() == 1, "the equipped border is not the game's")
ActionButton4:SetButtonState("PUSHED")
stub.advance(0.1)
stub.openFlyout(ActionButton6, 3)
stub.advance(0.5)
assert(styled(SpellFlyoutPopupButton1) and styled(SpellFlyoutPopupButton3), "the flyout's buttons are not restyled")
