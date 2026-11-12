--@ title: Talents: reset
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- Reset, on the footer's left in danger, as the stock ResetButton's "all talents": confirmed first, it stages every point back out (C_Traits.ResetTreeByCurrency); Undo drops it, Apply would keep it. With no point spent it is disabled and says why.
PolestarUI.Show("talents")
local f = PolestarUITalents
local r = f.footerButtons.left[1]
local function sub() return f.Subtitle:GetText() end
assert(r:IsShown() and r.Label:GetText() == "Reset" and r.psDanger and r:IsEnabled(), "no Reset")
r:Click()
assert(PolestarModal:IsShown() and sub():find("Every point is spent"), "reset without asking")
PolestarModal.Box.Action:Click()
assert(sub() == "15 points to spend. Your changes are not applied yet.", "not reset: " .. sub())
assert(f.footerButtons.right[1]:IsEnabled() and f.footerButtons.right[2]:IsEnabled(), "Apply or Undo off after a reset")
assert(not r:IsEnabled(), "Reset on with no point spent")
stub.RunScript(r, "OnEnter")
assert(GameTooltip.lines[1] == "No points spent", "no reason on Reset")
f.footerButtons.right[2]:Click()
assert(sub():find("1 point to spend") and r:IsEnabled(), "undo did not bring the points back: " .. sub())
r:Click()
PolestarModal.Box.Action:Click()
