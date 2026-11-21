--@ title: Micro menu: Edit Mode
--@ roots: MicroMenuContainer
--@ stubs: stub_micromenu.lua
-- Edit Mode's micro menu settings stay the game's: Size 80% and the vertical orientation. Our textures hang on the buttons, so they follow; leaving Edit Mode repaints the hairlines one pixel at the new scale. Nothing of ours moved, scaled, hid or wrote a key on the container, the menu, a button or its art (the stub's guards).
stub.editMicroMenu({ size = 80, vertical = true })
stub.advance(0.1)
assert(MicroMenu:GetScale() == 0.8 and stub.microVertical, "the menu's settings were undone")
assert(CharacterMicroButton:GetLeft() == QuestLogMicroButton:GetLeft(), "the buttons are not in a column")
local px = Polestar.Theme.Pixel(CharacterMicroButton)
local n = 0
for _, r in ipairs({ CharacterMicroButton:GetRegions() }) do
	local l, s = r:GetDrawLayer()
	if r:IsShown() and l == "OVERLAY" and s == 7 and tostring(r:GetTexture()):find("white", 1, true) then
		assert(r:GetHeight() == px or r:GetWidth() == px, "a hairline is not one pixel at the new scale")
		n = n + 1
	end
end
assert(n == 4, "not four hairlines")
-- In a column too, each ground apart from its neighbours (the stub keeps anchors: a button's TOPLEFT
-- on the menu, the ground's top and bottom on the button's).
local function span(b)
	local _, _, _, _, by = b:GetPoint(1)
	for _, r in ipairs({ b:GetRegions() }) do
		local l, s = r:GetDrawLayer()
		if r:IsShown() and l == "BACKGROUND" and s == -8 then
			local _, _, _, _, ty = r:GetPoint(1)
			local _, _, _, _, uy = r:GetPoint(2)
			return by + ty, by - b:GetHeight() + uy
		end
	end
end
for i = 2, #stub.microButtons do
	local _, abot = span(stub.microButtons[i - 1])
	local btop = span(stub.microButtons[i])
	assert(abot - btop >= 1, stub.microButtons[i]:GetName() .. ": its ground runs into its neighbour's")
end
