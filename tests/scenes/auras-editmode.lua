--@ title: Buffs and debuffs: Edit Mode
--@ roots: BuffFrame, DebuffFrame
--@ stubs: stub_auras.lua
-- Edit Mode's settings stay the game's: the buffs at Icon Size 80%, 6 per row, padding 8, growing right; the debuffs vertical (the duration beside the icon). Edit Mode's examples (their duration's font set again by the game) are restyled too. Nothing of ours moved, scaled, hid or wrote a key on a frame, a container or a button (the stub's guards).
stub.auras.buffs = { { icon = { 0.3, 0.5, 0.85 }, time = 1800 } }
stub.updateAuras()
stub.enterEditMode()
stub.editAuras(BuffFrame, { size = 80, perRow = 6, padding = 8, toRight = true })
stub.editAuras(DebuffFrame, { vertical = true, perRow = 4 })
stub.advance(0.2)
local B, D = BuffFrame.auraFrames, DebuffFrame.auraFrames
local number = Polestar.Theme.FontSpec("number")
assert(B[1]:GetScale() == 0.8 and BuffFrame.AuraContainer.iconStride == 6 and B[2]:GetPoint(1) == "TOPLEFT", "the buffs' settings were undone")
assert(D[1]:GetWidth() == 60 and D[1].Duration:GetPoint(1) == "RIGHT", "the debuffs are not vertical")
assert(B[20]:IsShown() and B[20].isExample and B[20].Duration:GetFont() == number, "an example's duration is not in our face again")
assert(D[5].DebuffBorder:GetAlpha() == 0, "an example debuff's border shows")
