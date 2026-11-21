--@ title: Macros: icon picker with no room left
--@ roots: PolestarUIMacros, PolestarUIMacrosIcons
--@ stubs: stub_macros.lua
-- Macros opened first, another docked window after it, the two just fitting:
-- New's picker widens Macros past the room, and the dock closes the other
-- window: Macros, whose flyout just opened, counts as the newest.
ShowMacroFrame()
local f = PolestarUIMacros
-- The room ends just past the second window, as the dock adds them up.
local L = GetUIPanelLayoutAttribute
local room = L("LEFT_OFFSET") + f:GetWidth() * f:GetScale() + L("PANEl_SPACING_X") + 300 * f:GetScale() + 20
local wide = GetMaxUIPanelsWidth
function GetMaxUIPanelsWidth() return room end
local other = CreateFrame("Frame", "PolestarUITestOther", UIParent)
other:SetSize(300, 400)
other:SetScale(f:GetScale())
other:Hide()
PolestarUI.Dock(other)
other:Show()
assert(f:IsShown() and other:IsShown(), "the two windows do not fit")
f.footerButtons.right[1]:Click()
assert(f:IsShown() and not other:IsShown(), "the dock did not close the other window")
assert(PolestarUIMacrosIcons:IsShown() and #PolestarUIMacrosIcons.psIcons > 0, "the picker is not painted")
GetMaxUIPanelsWidth = wide
stub.assertNoErrors()
