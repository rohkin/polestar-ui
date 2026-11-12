-- The client's gossip as the Gossip sees it: CustomGossipFrameManager with
-- the stock dispatch (CustomGossipFrameBase.lua), the stock GossipFrame
-- (never to be shown), the NPE guide's custom handler, C_GossipInfo, and the
-- quest dialog's events a choice hands on to (NPC windows via stub_npc.lua).

-- The game's windows: addon code must never show them.
GossipFrame = CreateFrame("Frame", "GossipFrame", UIParent)
GossipFrame:Hide()
function GossipFrame:HandleShow() self:Show() end
function GossipFrame:HandleHide() self:Hide() end
GuideFrame = CreateFrame("Frame", "GuideFrame", UIParent)
GuideFrame:Hide()
function ShowUIPanel(frame) frame:Show() end
function HideUIPanel(frame) frame:Hide() end

-- The manager, as the stock one dispatches: a custom handler by texture kit,
-- else the base handler, else the stock frame; GOSSIP_CLOSED hides the stock
-- frame or the frame the handler returned.
CustomGossipFrameManager = CreateFrame("Frame", "CustomGossipFrameManager", UIParent)
local m = CustomGossipFrameManager
m.handlers = { ["npe-guide"] = function() ShowUIPanel(GuideFrame); return GuideFrame end }
function m:SetBaseHandler(fn) self.baseHandler = fn end
m:RegisterEvent("GOSSIP_SHOW")
m:RegisterEvent("GOSSIP_CLOSED")
m:SetScript("OnEvent", function(self, event, arg)
	if event == "GOSSIP_SHOW" then
		local handler = arg and self.handlers[arg]
		if handler then self.customFrame = handler(arg)
		elseif self.baseHandler then self.customFrame = self.baseHandler(arg)
		else GossipFrame:HandleShow(arg) end
	elseif GossipFrame:IsShown() then
		GossipFrame:HandleHide(arg)
	elseif self.customFrame then
		HideUIPanel(self.customFrame)
		self.customFrame = nil
	end
end)

-- The NPC talked to: stub.talk({ name, text, active, available, options }, textureKit).
-- An option's `opens` is the interaction type it hands on to (a vendor).
local g = { active = {}, available = {}, options = {} }
stub.gossipClosed, stub.gossipPicked = 0, {}
local unitName = UnitName
function UnitName(unit, ...)
	if unit == "npc" then return g.name end
	return unitName(unit, ...)
end
function stub.talk(t, kit)
	g = t
	g.active, g.available, g.options = t.active or {}, t.available or {}, t.options or {}
	stub.fire("GOSSIP_SHOW", kit)
end

-- The game moving on: the gossip ends with the interaction continuing, and
-- a quest's dialog event follows (stub.handedOn), whichever window takes it.
local function handOn(event)
	stub.fire("GOSSIP_CLOSED", true)
	stub.handedOn = event
	if event then stub.fire(event) end
end

C_GossipInfo = {}
function C_GossipInfo.GetText() return g.text end
function C_GossipInfo.GetActiveQuests() return g.active end
function C_GossipInfo.GetAvailableQuests() return g.available end
function C_GossipInfo.GetNumActiveQuests() return #g.active end
function C_GossipInfo.GetNumAvailableQuests() return #g.available end
function C_GossipInfo.ForceGossip() return g.force end
-- The client hands the list over in its own order; the window sorts it.
function C_GossipInfo.GetOptions()
	local copy = {}
	for i, o in ipairs(g.options) do copy[i] = o end
	return copy
end
function C_GossipInfo.SelectOptionByIndex(i)
	table.insert(stub.gossipPicked, "option " .. i)
	for _, o in ipairs(g.options) do
		if o.orderIndex == i and o.opens then
			handOn()
			stub.interact(o.opens)
		end
	end
end
function C_GossipInfo.SelectActiveQuest(id) table.insert(stub.gossipPicked, "active " .. id); handOn("QUEST_PROGRESS") end
function C_GossipInfo.SelectAvailableQuest(id) table.insert(stub.gossipPicked, "available " .. id); handOn("QUEST_DETAIL") end
function C_GossipInfo.CloseGossip()
	stub.gossipClosed = stub.gossipClosed + 1
	stub.fire("GOSSIP_CLOSED", false)
end

-- The stock quest icons (QuestUtils.lua): file paths here, atlases for the newer kinds.
QuestUtil = QuestUtil or {}
function QuestUtil.GetQuestIconOffer(isLegendary, frequency, isRepeatable)
	if isRepeatable or (frequency or 0) > 0 then return "Interface\\GossipFrame\\DailyQuestIcon", false end
	return "Interface\\GossipFrame\\AvailableQuestIcon", false
end
function QuestUtil.GetQuestIconActive(isComplete)
	return isComplete and "Interface\\GossipFrame\\ActiveQuestIcon" or "Interface\\GossipFrame\\IncompleteQuestIcon", false
end

Enum.GossipOptionRecFlags = { QuestLabelPrepend = 1, PlayMovieLabelPrepend = 2 }
GOSSIP_OPTION_PREPEND = "%s %s"
QUEST_PREPEND = "(Quest)"
