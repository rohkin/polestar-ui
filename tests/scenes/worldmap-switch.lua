--@ title: World Map: switched back
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
--@ saved: PolestarUIDB = { modules = { map = false } }
-- Both directions of the switch on the map, whose close button is on its border (BorderFrame), not WorldMapFrame.CloseButton: saved off, the quest log key opens the stock map and the Polestar button above it closes it (a secure click on its border's close button) and opens ours; ours' "Use game window" closes ours and opens the stock map (a secure click on the quest log micro button).
stub.pressKey("L")
assert(WorldMapFrame:IsShown() and not PolestarUIWorldMap, "saved off: the key did not open the stock map")
stub.advance(0.1)
local o = PolestarUISwitchmap
assert(o and o:IsShown() and o:GetAttribute("type1") == "click" and o:GetAttribute("clickbutton") == WorldMapFrame.BorderFrame.CloseButton, "the map's Polestar button does not close the stock map")
-- The client's secure click: the action (the close button's own click), then our PostClick.
o:GetAttribute("clickbutton"):Click()
stub.RunScript(o, "PostClick", "LeftButton", false)
local f = PolestarUIWorldMap
assert(not WorldMapFrame:IsShown() and f and f:IsShown() and PolestarUIDB.modules.map == true, "the stock map did not close for ours")
stub.advance(0.1)
assert(not o:IsShown(), "the Polestar button stayed")
f.psMenu:Click()
stub.advance(0.1)
local g = PolestarUIGameWindow
assert(g and g:IsShown() and g:GetAttribute("macrotext") == "/click [nocombat] QuestLogMicroButton", "no secure button over Use game window")
stub.RunScript(g, "PreClick", "LeftButton", false)
QuestLogMicroButton:Click()
assert(not f:IsShown() and WorldMapFrame:IsShown() and PolestarUIDB.modules.map == false, "Use game window did not swap ours for the stock map")
-- Ours again, for the picture.
stub.advance(0.1)
o:GetAttribute("clickbutton"):Click()
stub.RunScript(o, "PostClick", "LeftButton", false)
assert(f:IsShown() and not WorldMapFrame:IsShown(), "back to ours")
