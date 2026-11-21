--@ title: Auction addons: ours starts off
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_auction.lua, stub_auctionator.lua
-- With Auctionator (or AHledger, CraftProfit, TradeSkillMaster) loaded, our Auction starts off so AuctionHouseFrame loads for it; a saved choice wins.
assert(not PolestarUI.Enabled("auction"), "ours is on beside Auctionator")
assert(PolestarUI.Enabled("gossip"), "an unrelated window went off")
stub.assertNoErrors()
--@ panel
--@ title: Auction addons: a saved choice wins
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_auction.lua, stub_auctionator.lua
--@ saved: PolestarUIDB = { modules = { auction = true } }
assert(PolestarUI.Enabled("auction"), "the saved choice lost to Auctionator")
stub.assertNoErrors()
