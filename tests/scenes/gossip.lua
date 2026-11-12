--@ title: Gossip
--@ roots: PolestarUIGossip
--@ stubs: stub_npc.lua, stub_gossip.lua
-- Ours is the manager's base handler: a gossip opens ours, never the stock window; the NPE guide's kit still goes to its own handler. The NPC's name heads the band, the greeting under it, then the options in the game's order (orderIndex) with their icons and key numbers; a quest option is marked. Closing ours ends the gossip once; GOSSIP_CLOSED closes ours without ending it again. A vendor option hands on to the merchant's interaction; a lone option the NPC skips to is taken at once. Keys 1-9 pick a row, other keys go on to the game. Off waits for /reload.
local f
-- The vendor's window: an interaction of its own, so whichever window takes the merchant's does not matter here.
local VENDOR = 999
local vendor = CreateFrame("Frame", "TestVendorFrame", UIParent)
vendor:Hide()
RegisterPlayerInteraction(VENDOR, { frame = "TestVendorFrame" })
local opts = {
	{ name = "Train me.", icon = 132058, orderIndex = 2, gossipOptionID = 12 },
	{ name = "Let me browse your goods.", icon = 132060, orderIndex = 1, gossipOptionID = 11, opens = VENDOR },
	{ name = "What happened to the mine?", icon = 132053, orderIndex = 3, gossipOptionID = 13, flags = 1 },
}
local function talk(kit)
	stub.talk({ name = "Innkeeper Farley", text = "Welcome to the Lion's Pride Inn. Rest your bones by the fire, and mind the gnoll stories; half of them are true.", options = opts }, kit)
end

assert(PolestarUI.modules.gossip.reloadOff, "switching off does not wait for /reload")
assert(CustomGossipFrameManager.baseHandler, "ours is not the base handler")

-- The NPE guide's kit keeps its own handler.
talk("npe-guide")
assert(GuideFrame:IsShown() and not (PolestarUIGossip and PolestarUIGossip:IsShown()), "the guide's gossip did not go to its handler")
stub.fire("GOSSIP_CLOSED", false)
assert(not GuideFrame:IsShown(), "the guide stayed open")

-- A plain gossip opens ours.
talk()
f = PolestarUIGossip
assert(f:IsShown() and not GossipFrame:IsShown(), "ours closed or the stock window open")
assert(f.Title:GetText() == "Innkeeper Farley", "the NPC's name is not the title")
local r = f.psRows
assert(r[1].Text:GetText() == "Let me browse your goods." and r[2].Text:GetText() == "Train me.", "options not in orderIndex order")
assert(r[3].Text:GetText() == "(Quest) What happened to the mine?", "the quest option is not marked")
assert(r[1].Icon.texture == 132060 and tostring(r[1].Key:GetText()) == "1", "icon or key number")

-- The player closing ours ends the gossip once.
f:Hide()
assert(stub.gossipClosed == 1, "closing ours did not end the gossip once")

-- The game ending it closes ours without ending it again.
talk()
stub.fire("GOSSIP_CLOSED", false)
assert(not f:IsShown() and stub.gossipClosed == 1, "the game's end did not close ours, or was ended again")

-- A vendor option hands on to the merchant's interaction.
talk()
stub.RunScript(r[1], "OnClick")
assert(stub.gossipPicked[1] == "option 1", "the option was not picked by its orderIndex")
assert(not f:IsShown() and stub.gossipClosed == 1, "ours stayed open or ended the gossip the vendor continues")
assert(vendor:IsShown(), "the merchant's interaction did not open")
vendor:Hide()

-- Keys: 2 picks the second row and is kept; other keys go on to the game.
talk()
function f:SetPropagateKeyboardInput(on) self.psPropagate = on end
stub.RunScript(f, "OnKeyDown", "W")
assert(f.psPropagate == true, "W was kept")
stub.RunScript(f, "OnKeyDown", "2")
assert(stub.gossipPicked[2] == "option 2" and f.psPropagate == false, "key 2 did not pick the second row, or went on to the game")
stub.RunScript(f, "OnKeyDown", "9")
assert(#stub.gossipPicked == 2, "key 9 picked a row that is not there")
stub.inCombat = true
stub.RunScript(f, "OnKeyDown", "1")
assert(#stub.gossipPicked == 2, "a key was taken in combat")
stub.inCombat = false

-- A lone option the NPC skips to is taken without a window.
f:Hide()
stub.talk({ name = "Vendor", text = "", options = { { name = "Let me browse your goods.", icon = 132060, orderIndex = 1, opens = VENDOR, selectOptionWhenOnlyOption = true } } })
assert(not f:IsShown() and vendor:IsShown(), "the lone option was not taken")
vendor:Hide()

talk()
