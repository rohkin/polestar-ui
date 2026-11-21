--@ title: NPC windows: a secret name (Gossip)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_gossip.lua
-- An NPC's name can come secret (docs/CLIENT.md rule 3): every NPC window opens with UnitName("npc"/"questnpc"/"pet") secret, shows no secret text and raises no error.
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
stub.talk({ name = "Innkeeper Farley", text = "Welcome.", options = { { name = "Bye.", icon = 132053, orderIndex = 1 } } })
local f = PolestarUIGossip
assert(f and f:IsShown(), "gossip did not open with a secret NPC name")
assert(not leak(f), "gossip shows the secret name")
stub.assertNoErrors()
--@ panel
--@ title: NPC windows: a secret name (Merchant)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_merchant.lua
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
local T = Enum.PlayerInteractionType
stub.interact(T.Merchant)
local f = PolestarUIMerchant
assert(f and f:IsShown(), "merchant did not open with a secret NPC name")
assert(not leak(f), "merchant shows the secret name")
stub.assertNoErrors()
--@ panel
--@ title: NPC windows: a secret name (Bank)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_bank.lua
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
local T = Enum.PlayerInteractionType
stub.interact(T.Banker)
local f = PolestarUIBank
assert(f and f:IsShown(), "bank did not open with a secret NPC name")
assert(not leak(f), "bank shows the secret name")
stub.assertNoErrors()
--@ panel
--@ title: NPC windows: a secret name (Auction)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_auction.lua
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
assert(f and f:IsShown(), "auction did not open with a secret NPC name")
assert(not leak(f), "auction shows the secret name")
stub.assertNoErrors()
--@ panel
--@ title: NPC windows: a secret name (Quest dialog)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_questdialog.lua
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
stub.fire("QUEST_DETAIL", 0)
local f = PolestarUIQuestDialog
assert(f and f:IsShown(), "questdialog did not open with a secret NPC name")
assert(not leak(f), "questdialog shows the secret name")
stub.assertNoErrors()
--@ panel
--@ title: NPC windows: a secret name (Trainer)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_trainer.lua
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
local T = Enum.PlayerInteractionType
stub.interact(T.Trainer)
local f = PolestarUITrainer
assert(f and f:IsShown(), "trainer did not open with a secret NPC name")
assert(not leak(f), "trainer shows the secret name")
stub.assertNoErrors()
--@ panel
--@ title: NPC windows: a secret name (pet trainer)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_trainer.lua
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
local T = Enum.PlayerInteractionType
stub.trainerType = 1
stub.interact(T.Trainer)
local f = PolestarUITrainer
assert(f and f:IsShown(), "trainer-pet did not open with a secret NPC name")
assert(not leak(f), "trainer-pet shows the secret name")
stub.assertNoErrors()
--@ panel
--@ title: NPC windows: a secret name (Mail)
--@ roots: PolestarUI
--@ stubs: stub_npc.lua, stub_mail.lua
local function leak(fr) for _, r in ipairs({ fr:GetRegions() }) do if r.GetText and r:GetText() == stub.SECRET then return true end end for _, k in ipairs({ fr:GetChildren() }) do if leak(k) then return true end end end
stub.secretNpc = true
assert(UnitName("npc") == stub.SECRET and UnitName("questnpc") == stub.SECRET, "stub.secretNpc not applied")
local T = Enum.PlayerInteractionType
stub.interact(T.MailInfo)
local f = PolestarUIMail
assert(f and f:IsShown(), "mail did not open with a secret NPC name")
assert(not leak(f), "mail shows the secret name")
stub.assertNoErrors()
