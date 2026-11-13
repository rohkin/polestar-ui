--@ title: Action bars: Edit Mode
--@ roots: MainActionBar, MultiBarBottomLeft, MultiBarRight, PetActionBar, StanceBar
--@ stubs: stub_actionbars.lua
-- Edit Mode's bar settings stay the game's: the bottom left bar at Icon Size 80% in 2 rows, the main bar with Hide Bar Art (the game swaps its slot art for the slot background and the frame's atlas, which keeps our fades). Our textures hang on the buttons, so they follow; leaving Edit Mode repaints them. Nothing of ours moved, scaled, hid or wrote a key on a bar, a container or a button (the stub's guards).
stub.editBar("MultiBarBottomLeft", { iconSize = 80, rows = 2 })
stub.editBar("MainActionBar", { hideArt = true })
assert(MultiBarBottomLeftButtonContainer1:GetScale() == 0.8 and MultiBarBottomLeft.rows == 2, "the bar's settings were undone")
assert(ActionButton1.SlotBackground:IsShown() and ActionButton1.SlotBackground:GetAlpha() == 0, "the slot background shows with Hide Bar Art")
assert(ActionButton1.NormalTexture:GetAtlas() == "UI-HUD-ActionBar-IconFrame-AddRow" and ActionButton1.NormalTexture:GetAlpha() == 0, "the frame art shows after its atlas changed")
assert(ActionButton1.icon.mask == nil, "an icon is masked again")
