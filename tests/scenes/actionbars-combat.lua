--@ title: Action bars: combat
--@ roots: MainActionBar, MultiBarBottomLeft, SpellFlyout
--@ stubs: stub_actionbars.lua
-- In combat: a theme change repaints the buttons already restyled (colours only: no protected call, no key, nothing moved). A flyout opened for the first time mid-fight keeps the game's look (its buttons are new, restyled only out of combat), and is restyled as combat ends. The first stance button stays checked; its accent follows the theme.
stub.inCombat = true
Polestar.Theme.Refresh()
assert(ActionButton1.NormalTexture:GetAlpha() == 0, "a theme change in combat lost the look")
stub.openFlyout(ActionButton6, 2)
stub.advance(0.5)
assert(SpellFlyoutPopupButton1.NormalTexture:GetAlpha() == 1 and SpellFlyoutPopupButton1.icon.mask ~= nil, "a new button was restyled in combat")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
assert(SpellFlyoutPopupButton1.NormalTexture:GetAlpha() == 0 and SpellFlyoutPopupButton1.icon.mask == nil, "the flyout is not restyled after combat")
stub.inCombat = true
