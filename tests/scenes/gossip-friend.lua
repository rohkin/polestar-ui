--@ title: Gossip: a friendship NPC
--@ roots: PolestarUIGossip
--@ stubs: stub_npc.lua, stub_gossip.lua
-- A friendship NPC's standing heads the body, as the stock NPCFriendshipStatusBar: its icon, the rank, the progress to the next, and the stock tooltip's lines (the name with the rank count, the text, the rank's progress). An NPC with none shows no bar.
stub.talk({
	name = "Ella",
	text = "The farm won't tend itself, but a good neighbour makes the work lighter.",
	friend = { friendshipFactionID = 1273, standing = 6100, maxRep = 42000, reactionThreshold = 4200, nextThreshold = 8400, name = "Ella", reaction = "Acquaintance", text = "Ella appreciates your help around the farm.", texture = 0, reversedColor = false },
	ranks = { currentLevel = 2, maxLevel = 6 },
	options = { { name = "What do you need?", icon = 132053, orderIndex = 1 } },
})
local f = PolestarUIGossip
local b = f.psFriend
assert(b:IsShown() and b.Label:GetText() == "Acquaintance" and b.Value:GetText() == "1,900 / 4,200", "rank: " .. tostring(b.Value:GetText()))
assert(math.abs(b.Bar.psFrac - 1900 / 4200) < 0.001, "bar")
stub.RunScript(b, "OnEnter")
assert(GameTooltip:IsShown(), "no tooltip")
stub.RunScript(b, "OnLeave")
local _, _, _, _, y = f.psGreeting:GetPoint(1)
assert(y < -24 - 32, "the greeting is not under the bar")
f:Hide()
stub.talk({ name = "Innkeeper Farley", text = "Welcome.", options = {} })
assert(not b:IsShown(), "a bar for an NPC with no friendship")
f:Hide()
stub.talk({
	name = "Ella",
	text = "The farm won't tend itself, but a good neighbour makes the work lighter.",
	friend = { friendshipFactionID = 1273, standing = 6100, maxRep = 42000, reactionThreshold = 4200, nextThreshold = 8400, name = "Ella", reaction = "Acquaintance", text = "Ella appreciates your help around the farm.", texture = 0, reversedColor = false },
	ranks = { currentLevel = 2, maxLevel = 6 },
	options = { { name = "What do you need?", icon = 132053, orderIndex = 1 } },
})
