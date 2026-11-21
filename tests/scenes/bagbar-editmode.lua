--@ title: Bag bar: Edit Mode
--@ roots: BagsBar
--@ stubs: stub_bagbar.lua
-- Edit Mode's bag bar settings stay the game's: Size 80%, vertical, slot padding 6. Our textures hang on the buttons, so they follow; leaving Edit Mode repaints the hairlines one pixel at the new scale. Nothing of ours moved, scaled, hid or wrote a key on the bar, a button or its art (the stub's guards).
stub.editBagsBar({ size = 80, vertical = true, padding = 6 })
stub.advance(0.1)
assert(BagsBar:GetScale() == 0.8 and stub.bagsVertical and stub.bagPadding == 6, "the bar's settings were undone")
local px = Polestar.Theme.Pixel(CharacterBag0Slot)
local n = 0
for _, r in ipairs({ CharacterBag0Slot:GetRegions() }) do
	local l, s = r:GetDrawLayer()
	if r:IsShown() and l == "OVERLAY" and s == 7 and tostring(r:GetTexture()):find("white", 1, true) then
		assert(r:GetHeight() == px or r:GetWidth() == px, "a hairline is not one pixel at the new scale")
		n = n + 1
	end
end
assert(n == 4, "not four hairlines")
-- The vertical layout's dividers, a new pool's frames: faded too.
local nd = 0
for d in BagsBar.VerticalDividersPool:EnumerateActive() do assert(d:GetAlpha() == 0, "a vertical divider shows"); nd = nd + 1 end
assert(nd > 0, "no vertical dividers")
