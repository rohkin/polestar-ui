--@ title: Macros: icon picker with no room left
--@ roots: PolestarUIMacros
--@ stubs: stub_macros.lua
-- Macros opened first, another docked window after it, the two just fitting:
-- New's picker widens Macros past the room, and the dock closes the oldest,
-- Macros itself (its picker with it). Nothing is painted into the picker
-- let go (its icon list gone).
ShowMacroFrame()
local f = PolestarUIMacros
-- The room ends just past the second window, as the dock adds them up.
local L = GetUIPanelLayoutAttribute
local room = L("LEFT_OFFSET") + f:GetWidth() * f:GetScale() + L("PANEl_SPACING_X") + 300 * f:GetScale() + 20
function GetMaxUIPanelsWidth() return room end
local other = CreateFrame("Frame", "PolestarUITestOther", UIParent)
other:SetSize(300, 400)
other:SetScale(f:GetScale())
other:Hide()
PolestarUI.Dock(other)
other:Show()
assert(f:IsShown() and other:IsShown(), "the two windows do not fit")
f.footerButtons.right[1]:Click()
assert(not f:IsShown() and other:IsShown(), "the dock did not close the oldest")
assert(not (PolestarUIMacrosIcons and PolestarUIMacrosIcons:IsShown()), "the picker stayed open")
-- Opened again, New opens the picker (it fits alone).
other:Hide()
ShowMacroFrame()
f.footerButtons.right[1]:Click()
assert(PolestarUIMacrosIcons:IsShown() and #PolestarUIMacrosIcons.psIcons > 0, "no picker after reopening")
stub.assertNoErrors()
