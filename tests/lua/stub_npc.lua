-- The client the NPC windows open from (docs/DESIGN.md, "NPC windows: how
-- they open"): the interaction manager (PlayerInteractionFrameManager.lua),
-- GameEvent's routing, the bags, money and C_Container. Shared by every NPC
-- window's stub.

Enum.PlayerInteractionType = { Merchant = 5, Trainer = 7, Banker = 8, MailInfo = 17, Auctioneer = 21, CharacterBanker = 67, AccountBanker = 68 }

-- The stock windows: they record being shown; none may be.
for _, name in ipairs({ "MerchantFrame", "ClassTrainerFrame", "BankFrame", "MailFrame", "AuctionHouseFrame" }) do
	local f = CreateFrame("Frame", name, UIParent)
	f:Hide()
end

-- The game's event routing (Blizzard_Game's EventRouting.lua): a handler per
-- event on one frame; Forever routes TRAINER_SHOW to the stock trainer.
GameEvent = GameEvent or {}
stub.unrouted = {}
local routing, handlers = CreateFrame("Frame"), {}
routing:SetScript("OnEvent", function(_, event, ...) if handlers[event] then handlers[event](...) end end)
handlers.TRAINER_SHOW = function() ClassTrainerFrame:Show() end
routing:RegisterEvent("TRAINER_SHOW")
function GameEvent.UnregisterInternalEvent(event)
	stub.unrouted[event] = true
	if handlers[event] then
		routing:UnregisterEvent(event)
		handlers[event] = nil
	end
end

-- The interaction manager: one entry per type (the last registered wins),
-- shown and hidden on the manager's events; the stock entries are registered
-- before any addon loads. A frame not made yet is not hidden.
local entries = {}
function RegisterPlayerInteraction(t, info)
	assert(type(info.frame) == "string", "RegisterPlayerInteraction expected frameInfo.frame to be a string.")
	entries[t] = info
end
local manager = CreateFrame("Frame")
manager:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
manager:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
manager:SetScript("OnEvent", function(_, event, t)
	local info = entries[t]
	if not info then return end
	if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
		if info.showFunc then info.showFunc() else _G[info.frame]:Show() end
	elseif _G[info.frame] then
		if info.hideFunc then info.hideFunc() else _G[info.frame]:Hide() end
	end
end)
local T = Enum.PlayerInteractionType
for t, frame in pairs({ [T.Merchant] = "MerchantFrame", [T.Trainer] = "ClassTrainerFrame", [T.Banker] = "BankFrame",
	[T.CharacterBanker] = "BankFrame", [T.AccountBanker] = "BankFrame", [T.MailInfo] = "MailFrame", [T.Auctioneer] = "AuctionHouseFrame" }) do
	RegisterPlayerInteraction(t, { frame = frame, showFunc = function() _G[frame]:Show() end })
end

-- The player at an NPC (the interaction opens) and walking away (the game ends it).
function stub.interact(t) stub.fire("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", t) end
function stub.endInteraction(t) stub.fire("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", t) end

-- The stock close calls: each counted, and each ends the interaction as the
-- client does (the manager's hide follows).
stub.npcClosed = {}
for name, t in pairs({ CloseMerchant = T.Merchant, CloseTrainer = T.Trainer, CloseMail = T.MailInfo }) do
	_G[name] = function()
		stub.npcClosed[name] = (stub.npcClosed[name] or 0) + 1
		stub.endInteraction(t)
	end
end

-- The bags (ContainerFrame.lua): opened by a frame, closed only by the frame
-- that opened them (FRAME_THAT_OPENED_BAGS).
stub.bagsOpen, stub.bagsOpener = false, nil
function OpenAllBags(frame)
	if stub.bagsOpen then return end
	stub.bagsOpen, stub.bagsOpener = true, frame and frame:GetName()
end
function CloseAllBags(frame)
	if frame and frame:GetName() ~= stub.bagsOpener then return false end
	stub.bagsOpen, stub.bagsOpener = false, nil
	return true
end

-- Money: 123g 45s 67c.
stub.money = 1234567
function GetMoney() return stub.money end

-- The backpack (bag 0), 16 slots: a few items, the rest empty.
-- slot = { icon, quality, count, locked }
stub.bag = {
	[1] = { 134400, 1, 20 }, [2] = { 135274, 2, 1 }, [3] = { 133784, 3, 1 }, [4] = { 132940, 4, 1 },
	[5] = { 134939, 0, 5 }, [6] = { 133970, 1, 200, true },
}
C_Container = C_Container or {}
function C_Container.GetContainerNumSlots(bag) return bag == 0 and 16 or 0 end
function C_Container.GetContainerItemInfo(bag, slot)
	local s = bag == 0 and stub.bag[slot]
	if not s then return nil end
	return { iconFileID = s[1], quality = s[2], stackCount = s[3], isLocked = s[4] or false, itemID = 1000 + slot }
end
