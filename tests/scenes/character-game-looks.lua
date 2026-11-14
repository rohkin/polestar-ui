--@ title: Character: the game's looks
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20; the six sections stay top tabs on the row and the gear keeps its columns.
Polestar.Set("ui.skin", "forever")
PolestarUI.Show("character")
local f = PolestarUICharacter
assert(f:IsShown() and f.TabRow:GetHeight() == 32 and f.psPad == 20, "not the game's looks")
assert(f.tabButtons[6]:IsShown() and f.psTabsRight <= f:GetWidth() - f.psPad, "tabs overflow the row: " .. f.psTabsRight)
