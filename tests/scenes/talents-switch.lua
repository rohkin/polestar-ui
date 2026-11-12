--@ title: Talents: switched back
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
--@ saved: PolestarUIDB = { modules = { talents = false } }
-- The switch: saved off, the talents key is the game's and a Polestar button sits above the stock window (ours on UIParent, not anchored to it); it switches on live (keys, overlay). The window's menu switches it off live; not in combat; /pui switches and lists each window (the Character toggle hook stands aside while off; crafting off waits for /reload).
local said = {}
print = function(m) said[#said + 1] = m end
local function lastSaid() return said[#said] or "" end
stub.pressKey("N")
assert(not PolestarUITalents and PlayerSpellsFrame:IsShown() and not PolestarUITalentsMicro, "saved off: the key did not open the stock window")
stub.advance(0.1)
local sb
for _, c in ipairs({ UIParent:GetChildren() }) do if c:IsShown() and type(c.Label) == "table" and c.Label.GetText and c.Label:GetText() == "Polestar" then sb = c end end
local p, rel, rp, x, y = sb:GetPoint(1)
assert(sb and rel == UIParent and p == "BOTTOMRIGHT" and rp == "BOTTOMLEFT" and x == PlayerSpellsFrame:GetRight() and y == PlayerSpellsFrame:GetTop() + 4, "no switch-back button above the stock window, or anchored to it")
sb:Click()
assert(PolestarUIDB.modules.talents == true and stub.overrides["N"] == "PolestarUITalentsTOGGLETALENTS", "the stock button did not switch on live")
stub.advance(0.1)
assert(not sb:IsShown() and PolestarUITalentsMicro:IsShown(), "on: the overlay, no stock button")
stub.pressKey("N")
local f = PolestarUITalents
assert(f:IsShown(), "on: the key opens ours")
f.psMenu:Click()
-- The window's options first, a divider, then "Use game window".
assert(PolestarMenu.rows[1].psItem.text == "Game's talents: shift-click their micro button" and PolestarMenu.seps[1]:IsShown(), "options not first in the menu")
local row = PolestarMenu.rows[2]
assert(PolestarMenu:IsShown() and row:IsShown() and row.psItem.text == "Use game window" and row.psItem.tip:find("/pui talents on", 1, true), "menu entry")
assert(select(2, f.psMenu:GetPoint(1)) == f.Close and select(2, f.HeaderTools:GetPoint(1)) == f.psMenu, "menu button between the scale and the close button")
row:Click()
assert(not f:IsShown() and PolestarUIDB.modules.talents == false and not stub.overrides["N"], "off: ours closed, the key unbound")
stub.advance(0.1)
assert(not PolestarUITalentsMicro:IsShown(), "off: overlay still over the micro button")
stub.pressKey("N")
assert(not f:IsShown(), "off: the key opened ours")
stub.inCombat = true
SlashCmdList.POLESTARUI("talents on")
stub.inCombat = false
assert(PolestarUIDB.modules.talents == false and lastSaid():find("combat"), "switched in combat")
SlashCmdList.POLESTARUI("talents on")
assert(PolestarUIDB.modules.talents == true and stub.overrides["N"], "/pui talents on")
SlashCmdList.POLESTARUI("character off")
ToggleCharacter()
assert(not (PolestarUICharacter and PolestarUICharacter:IsShown()), "character off: the toggle opened ours")
SlashCmdList.POLESTARUI("character on")
ToggleCharacter()
assert(PolestarUICharacter:IsShown(), "character on: the toggle did not open ours")
PolestarUICharacter:Hide()
SlashCmdList.POLESTARUI("crafting off")
assert(PolestarUIDB.modules.crafting == false and lastSaid():find("/reload", 1, true), "crafting off waits for /reload")
said = {}
SlashCmdList.POLESTARUI("")
local list = table.concat(said, "/")
assert(#said == 1 + #PolestarUI.order and list:find("talents: on", 1, true) and list:find("crafting: off after /reload", 1, true) and list:find("map: on", 1, true), "listing: " .. list)
SlashCmdList.POLESTARUI("crafting on")
stub.pressKey("N")
assert(f:IsShown(), "on again: the key opens ours")
