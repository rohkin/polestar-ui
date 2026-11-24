--@ title: Action bars: combat
--@ roots: MainActionBar, MultiBarBottomLeft, SpellFlyout
--@ stubs: stub_actionbars.lua
-- In combat: a theme change repaints the buttons already restyled (colours only: no protected call, no key, nothing moved). A flyout opened for the first time mid-fight keeps the game's look (its buttons are new, restyled only out of combat), and is restyled as combat ends. The first stance button stays checked; its accent follows the theme.
stub.inCombat = true
Polestar.Theme.Refresh()
assert(ActionButton1.NormalTexture:GetAlpha() == 0, "a theme change in combat lost the look")
stub.cascadeVisibility = true
stub.openFlyout(ActionButton6, 2)
stub.cascadeVisibility = false
stub.advance(0.5)
assert(SpellFlyoutPopupButton1.NormalTexture:GetAlpha() == 1 and SpellFlyoutPopupButton1.icon.mask ~= nil, "a new button was restyled in combat")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
assert(SpellFlyoutPopupButton1.NormalTexture:GetAlpha() == 0 and SpellFlyoutPopupButton1.icon.mask == nil, "the flyout is not restyled after combat")
stub.inCombat = true
-- Empty slots in combat: a drag shows the grid (the game's ACTIONBAR_SHOWGRID), a spell dropped on an empty
-- slot (the game shows its icon) loses the emblem, a slot emptied (its icon hidden) gains it; colours and
-- shown states of our own textures only, so no protected call errors. Put back as it was for the picture.
local function logo(b)
	for _, r in ipairs({ b:GetRegions() }) do
		if r:IsShown() and tostring(r:GetTexture()):find("emblem", 1, true) then return r end
	end
end
stub.fire("ACTIONBAR_SHOWGRID")
assert(logo(ActionButton12) and not logo(ActionButton1), "the emblem is not on the empty slot alone while dragging")
ActionButton12.icon:Show()
ActionButton1.icon:Hide()
stub.advance(0.05)
assert(not logo(ActionButton12), "the emblem stayed on a slot given an action in combat")
assert(logo(ActionButton1), "no emblem on a slot emptied in combat")
stub.fire("ACTIONBAR_HIDEGRID")
ActionButton12.icon:Hide()
ActionButton1.icon:Show()
stub.advance(0.05)
assert(logo(ActionButton12) and not logo(ActionButton1), "the emblem did not follow the slots back")
