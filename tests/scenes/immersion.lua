--@ title: Immersion: ours start off
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_gossip.lua, stub_immersion.lua
-- With Immersion loaded, our Gossip and Quest dialog start off (it shows both itself); a saved choice wins.
assert(not PolestarUI.Enabled("gossip") and not PolestarUI.Enabled("questdialog"), "ours are on beside Immersion")
assert(PolestarUI.Enabled("auction"), "an unrelated window went off")
stub.assertNoErrors()
--@ panel
--@ title: Immersion: a saved choice wins
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_gossip.lua, stub_immersion.lua
--@ saved: PolestarUIDB = { modules = { gossip = true, questdialog = true } }
assert(PolestarUI.Enabled("gossip") and PolestarUI.Enabled("questdialog"), "the saved choice lost to Immersion")
stub.assertNoErrors()
