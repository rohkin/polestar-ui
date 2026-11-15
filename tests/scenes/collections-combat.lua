--@ title: Collections: in combat
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- In combat the keys still open and close ours (override bindings set before); a mount drag and a toy drag pick nothing (pickups from addon code are kept out of combat: docs/CLIENT.md, rule 4); a toy click uses nothing and its tooltip says why; the client's usability greys Mount with its reason; the switch is refused.
stub.inCombat = true
stub.pressKey("CTRL-M")
local f = PolestarUICollections
assert(f:IsShown(), "key in combat")
stub.fire("PLAYER_REGEN_DISABLED")
local row
for _, r in ipairs({ f.psNav.Child:GetChildren() }) do if r.psMount and r:IsShown() then row = r; break end end
stub.RunScript(row, "OnDragStart")
assert(not stub.picked and not stub.blocked, "mount picked up in combat")
assert(not f.footerButtons.right[1]:IsEnabled() and f.footerButtons.right[1].psReason == "You can't do that while in combat.", "mount button: " .. tostring(f.footerButtons.right[1].psReason))
PolestarUI.Switch("collections", false)
assert(PolestarUI.Enabled("collections"), "switched in combat")
stub.pressKey("CTRL-T")
local tile
for _, c in ipairs({ f.psToys:GetChildren() }) do if c.psID == 1001 then tile = c end end
stub.RunScript(tile, "OnClick", "LeftButton")
stub.RunScript(tile, "OnDragStart")
assert(not stub.usedToy and not stub.picked and not stub.blocked, "toy used or picked up in combat")
stub.RunScript(tile, "OnEnter")
assert(table.concat(GameTooltip.lines or {}, "/"):find("can't be used from this window in combat", 1, true), "no combat hint: " .. table.concat(GameTooltip.lines or {}, "/"))
stub.pressKey("CTRL-T")
assert(not f:IsShown(), "toy key closes in combat")
-- Pets: the cooldown times are secret in combat (docs/CLIENT.md, rule 3): the sweep stays as drawn, no error;
-- a drag picks nothing, Summon greys with the client's reason.
stub.pressKey("CTRL-P")
local cat
for _, r in ipairs({ f.psNav.Child:GetChildren() }) do if r.psPet and r.psPet.name == "Prairie Dog" then cat = r end end
stub.fire("SPELL_UPDATE_COOLDOWN")
stub.RunScript(cat, "OnDragStart")
assert(not stub.picked and not stub.blocked, "pet picked up in combat")
stub.RunScript(cat, "OnClick", "LeftButton")
assert(not f.footerButtons.right[1]:IsEnabled() and f.footerButtons.right[1].psReason == "You can't do that while in combat.", "summon: " .. tostring(f.footerButtons.right[1].psReason))
-- Appearances: no Tab cycling in combat (the key frame's propagation is protected then).
stub.pressKey("CTRL-W")
local look
for _, t in ipairs(f.psLooks.Looks) do if t:IsShown() then look = t; break end end
stub.RunScript(look.psModel, "OnEnter")
assert(GameTooltip:IsShown() and not f.psKeys.keyboardEnabled, "keyboard taken in combat")
stub.RunScript(look.psModel, "OnLeave")
stub.pressKey("CTRL-W")
-- Drawn on Mounts, still in combat: Mount greyed with the client's reason.
stub.pressKey("CTRL-M")
