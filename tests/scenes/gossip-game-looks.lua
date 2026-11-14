--@ title: Gossip: the game's looks
--@ roots: PolestarUIGossip
--@ stubs: stub_npc.lua, stub_gossip.lua
-- In the game's looks (Forever's), the compact grid takes the skin's pad (20); the NPC's portrait well stays in the 60 band, the name beside it.
Polestar.Set("ui.skin", "forever")
stub.talk({ name = "Innkeeper Farley", text = "Welcome to the Lion's Pride Inn. Rest your bones by the fire.", options = {
	{ name = "Let me browse your goods.", icon = 132060, orderIndex = 1 },
	{ name = "Make this inn your home.", icon = 132052, orderIndex = 2 },
} })
local f = PolestarUIGossip
assert(f.psPad == 20 and f.Header:GetHeight() == 60 and f.psPortraitIcon.texture == 132355, "not the game's looks")
