--@ title: Inspect
--@ roots: PolestarUIInspect
--@ stubs: stub_inspect.lua
-- The unit menu's Inspect (InspectUnit) asks the server; ours opens on its
-- answer (INSPECT_READY), never the stock window: its own open event is
-- unregistered once Blizzard_InspectUI loads. Closing ours forgets the
-- inspected player (ClearInspectPlayer), but not when another unit is
-- inspected while it is open; a new target closes a target's inspect.
assert(PolestarUI.modules.inspect.reloadOff, "switching off does not wait for /reload")
InspectUnit("target")
assert(not InspectFrame.events.INSPECT_READY, "the stock open event is still registered")
assert(stub.notified[1] == "target" and not PolestarUIInspect, "opened before the data came")
stub.inspectReady("target")
local f = PolestarUIInspect
assert(f:IsShown() and not InspectFrame:IsShown(), "ours not shown, or the stock one opened")
assert(f.Title:GetText() == "Aldric-Silvermoon", "title: " .. tostring(f.Title:GetText()))
assert(f.psSubtitle == "Level 60 |cfff48cbaPaladin|r", "level line: " .. f.psSubtitle)
assert(f.psPages.gear.Model.modelUnit == "target" and not f.psPages.gear.Logo:IsShown(), "model")
-- The top tabs: the stock mode tabs, each with its own icon; no sidebar, no rail.
local tabs = f.tabButtons
assert(tabs[1].psNavIcon:GetTexture() == 132355, "Character: not the unit's portrait")
assert(tabs[2].psNavIcon:GetTexture() == "Interface/ICONS/INV_SideTab_Honor_Alliance_c60", "PvP icon")
assert(tabs[3]:IsShown() and tabs[3].psNavIcon:GetTexture() == "Interface/ICONS/INV_Shirt_GuildTabard_01", "Guild icon")
assert(f.psCompact and not f.Sidebar:IsShown() and (f.psRail or 0) == 0, "not the compact grid")

-- Another unit while open: ours closes without forgetting the new request.
InspectUnit("party1")
assert(not f:IsShown() and stub.inspectCleared == 0, "the new request was cleared")
stub.inspectReady("party1")
assert(f:IsShown() and f.Title:GetText() == "Brenna", "the next unit")
stub.fire("PLAYER_TARGET_CHANGED")
assert(f:IsShown(), "a party member's inspect closed on a new target")
stub.fire("GROUP_ROSTER_UPDATE")
assert(not f:IsShown() and stub.inspectCleared == 1, "a roster change did not close it, or forgot nothing")

-- In combat the name comes secret: no title, never the last unit's.
InspectUnit("target")
stub.inCombat = true
stub.inspectReady("target")
assert(f:IsShown() and f.Title:GetText() == "", "secret title: " .. tostring(f.Title:GetText()))
stub.inCombat = false
f:Hide()

-- A unit that cannot be inspected: nothing opens.
stub.canInspect = false
InspectUnit("target")
stub.inspectReady("target")
assert(not f:IsShown(), "opened for a unit that cannot be inspected")
stub.canInspect = nil

InspectUnit("target")
stub.inspectReady("target")
assert(f:IsShown() and f.Title:GetText() == "Aldric-Silvermoon", "reopen")
-- A slot: the game's tooltip with the hint; a click is the client's modified click.
local slot
for _, c in ipairs({ f.psPages.gear:GetChildren() }) do if c.psLabel and c:GetID() == 1 then slot = c end end
assert(slot.psName:GetText() == "Helm of the Fallen Champion", "slot name")
stub.RunScript(slot, "OnEnter")
assert(GameTooltip:IsShown() and GameTooltip:GetOwner() == slot, "slot tooltip")
local clicked
local handle = HandleModifiedItemClick
HandleModifiedItemClick = function(link) clicked = link end
stub.RunScript(slot, "OnClick", "LeftButton")
HandleModifiedItemClick = handle
assert(clicked and clicked:find("Helm of the Fallen Champion", 1, true), "click not handed to HandleModifiedItemClick")
stub.RunScript(slot, "OnLeave")
