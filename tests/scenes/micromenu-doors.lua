--@ title: Micro menu: our doors
--@ roots: MicroMenuContainer
--@ stubs: stub_talents.lua, stub_micromenu.lua
-- The talents door (Core.lua ns.Doors) over a restyled micro button: our secure button still lies above it, placed by position (not anchored: docs/CLIENT.md, rule 10), and opens ours on a click. While ours shows, the talents button wears the accent (its door's window), though the game never pushes it. The game's own window (a shift-click clicks the micro button from secure code; the game then pushes it) lights it too. The overlay holds the mouse, so the hover wash reads IsMouseOver.
local Theme = Polestar.Theme
stub.advance(0.1)
local b, o = TalentMicroButton, PolestarUITalentsMicro
local function accent()
	for _, r in ipairs({ b:GetRegions() }) do
		local l, s = r:GetDrawLayer()
		if r:IsShown() and l == "OVERLAY" and s == 6 and tostring(r:GetTexture()):find("white", 1, true) then return true end
	end
end
assert(b.Background:GetAlpha() == 0, "the micro button is not restyled")
assert(o:IsShown() and o:GetFrameStrata() == b:GetFrameStrata() and o:GetFrameLevel() > b:GetFrameLevel(), "the overlay is not above the micro button")
assert(select(2, o:GetPoint(1)) ~= b and math.abs(o:GetLeft() - b:GetLeft()) < 1e-6 and o:GetWidth() == b:GetWidth(), "the overlay is anchored to the micro button, or not over it")
assert(not accent(), "an accent before any window opened")
stub.RunScript(o, "PostClick", "LeftButton")
stub.advance(0.05)
assert(PolestarUITalents:IsShown() and not PlayerSpellsFrame:IsShown(), "the door does not open ours")
assert(accent(), "no accent while our window shows")
PolestarUITalents:Hide()
stub.advance(0.05)
assert(not accent(), "the accent stays after ours closed")
-- Shift-click: the game's window, the game pushes its button.
stub.bindingRun.TOGGLETALENTS()
stub.microSetPushed(b, true)
stub.advance(0.05)
assert(accent(), "no accent while the game's window shows")
stub.microSetPushed(b, false)
stub.mouseOver = b
stub.advance(0.05)
local hover
for _, r in ipairs({ b:GetRegions() }) do local l, s = r:GetDrawLayer(); if r:IsShown() and l == "OVERLAY" and s == 5 then hover = r end end
assert(hover, "no hover wash under the overlay")
stub.mouseOver = nil
-- Off: the door still works and the game's art is back.
PolestarUI.Switch("micromenu", false)
stub.advance(0.1)
assert(o:IsShown() and b.Background:GetAlpha() == 1, "switched off, the door or the art")
stub.RunScript(o, "PostClick", "LeftButton")
assert(PolestarUITalents:IsShown(), "the door does not open ours with the micro menu off")
PolestarUITalents:Hide()
PolestarUI.Switch("micromenu", true)
stub.advance(0.1)
