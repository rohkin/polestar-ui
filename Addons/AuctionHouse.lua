-- These addons build on the game's AuctionHouseFrame, which never loads while our Auction takes the
-- Auctioneer interaction: ours starts off beside them (a saved choice wins).
local ADDON, ns = ...

local NAMES = { "Auctionator", "AHledger", "CraftProfit", "TradeSkillMaster", "Undying", "NaowhForever" }

ns.AfterLogin(function()
	for _, name in ipairs(NAMES) do
		if C_AddOns.IsAddOnLoaded(name) then
			if ns.modules.auction then ns.modules.auction.defaultOff = true end
			return
		end
	end
end)
