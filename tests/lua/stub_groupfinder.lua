-- The client's Vanilla-style Group Finder (LFGParentFrame) as the Group Finder
-- window sees it: the stock frame, its micro button and keys, and the guard
-- on the calls the client restricts to a hardware event. Page data (listings,
-- results, Who) comes from the pages' own stubs. Records:
--   stub.searched   the C_LFGList.Search arguments { category, activityIDs }
--   stub.listing    the CreateListing / UpdateListing table (.update = true)
--   stub.who        the SendWho query { text, origin, filters }
--   stub.roleSet    the role UnitSetRole set
-- stub.hardware: true only inside a click, an Enter press or a key.

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
LFGParentFrame = CreateFrame("Frame", "LFGParentFrame", UIParent)
LFGParentFrame:Hide()
LFGParentFrame:SetSize(458, 535)
function LFGParentFrame.Hide() error("addon code hid LFGParentFrame", 2) end
function LFGParentFrame.Show() error("addon code showed LFGParentFrame", 2) end
LFGParentFrame.CloseButton = CreateFrame("Button", nil, LFGParentFrame)
LFGParentFrame.CloseButton:SetScript("OnClick", function() UIParent.Hide(LFGParentFrame) end)
LFDMicroButton = CreateFrame("Button", "LFDMicroButton", UIParent)
LFDMicroButton.tooltipText = "Group Finder (I)"
LFDMicroButton:SetScript("OnClick", function()
	if LFGParentFrame:IsShown() then UIParent.Hide(LFGParentFrame) else UIParent.Show(LFGParentFrame) end
end)
LFDMicroButton:SetFrameStrata("HIGH")
LFDMicroButton:SetFrameLevel(40)
-- Forever's keys: the Group Finder key bound, the Who key bound here too (unbound
-- live) so the scenes cover it; the game's own runs open the stock window.
for action, key in pairs({ TOGGLEGROUPFINDER = "I", TOGGLEWHOTAB = "SHIFT-I" }) do
	stub.bindings[action] = { key }
	stub.bindingRun[action] = function() UIParent.Show(LFGParentFrame) end
end

GROUP_FINDER, LFG_LIST_TAB_1, LFG_LIST_TAB_2, LFG_LIST_TAB_3, LFG_LIST_EDIT = "Group Finder", "Create a Listing", "Browse Groups", "Who", "Edit Listing"

---------------------------------------------------------------------------
-- The hardware guard: the client runs these only from a hardware event; from
-- anywhere else (OnShow, an event, a timer), or a second time in one, the call is refused.

stub.hardware = false
local function withHardware(fn, ...)
	local was = stub.hardware
	stub.hardware = true
	local r = { pcall(fn, ...) }
	stub.hardware = was
	if not r[1] then error(r[2], 0) end
	return unpack(r, 2)
end
local runScript = stub.RunScript
function stub.RunScript(frame, script, ...)
	if script == "OnClick" or script == "OnEnterPressed" then return withHardware(runScript, frame, script, ...) end
	return runScript(frame, script, ...)
end
local click = stub.Methods.Click
function stub.Methods.Click(...) return withHardware(click, ...) end
local pressKey = stub.pressKey
function stub.pressKey(...) return withHardware(pressKey, ...) end

local function guard(name)
	if not stub.hardware then error(name .. " needs a hardware event (a click or a key)", 3) end
	stub.hardware = false -- one restricted call per hardware event (live: Search after CreateListing was blocked)
end

C_LFGList = C_LFGList or {}
stub.activeEntry = nil -- the listing up, { activityIDs, ... }
function C_LFGList.HasActiveEntryInfo() return stub.activeEntry ~= nil end
function C_LFGList.GetActiveEntryInfo() return stub.activeEntry end
function C_LFGList.Search(category, _, _, _, _, _, activityIDs)
	guard("C_LFGList.Search")
	stub.searched = { category = category, activityIDs = activityIDs }
end
function C_LFGList.CreateListing(t)
	guard("C_LFGList.CreateListing")
	stub.listing = t
	stub.activeEntry = t
	return true
end
function C_LFGList.UpdateListing(t)
	guard("C_LFGList.UpdateListing")
	t.update = true
	stub.listing = t
	stub.activeEntry = t
	return true
end
-- Protected (ADDON_ACTION_BLOCKED live, from any addon click): the game's window unlists.
function C_LFGList.RemoveListing() error("C_LFGList.RemoveListing is protected: the game's window unlists", 2) end
function UnitSetRole(unit, role)
	guard("UnitSetRole")
	stub.roleSet = role
end
C_FriendList = C_FriendList or {}
function C_FriendList.SendWho(text, origin, filters)
	guard("C_FriendList.SendWho")
	stub.who = { text = text, origin = origin, filters = filters }
end
