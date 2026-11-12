-- The Gossip (docs/windows/gossip.md): the NPC's greeting, quests and options
-- in a plain Polestar shell. Ours is CustomGossipFrameManager's base handler,
-- so the stock GossipFrame never opens; custom handlers (the NPE guide) stay
-- the game's. Off waits for /reload.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIGossip"
local ROW_H = 32

local f, ended, continuing
local M = { reloadOff = true }
local rows = {}

-- The NPC's portrait at the band's left, the title beside it, as the stock
-- windows' (SetPortraitToUnit; the quest book when there is no unit). Shared
-- with the Quest dialog. Returns paint(unit).
function ns.NpcPortrait(f)
	local well, icon = ns.ItemWell(f.Header, 48)
	well:SetPoint("TOPLEFT", f.Header, "TOPLEFT", W.SHELL.pad, -28)
	f.Title:SetPoint("TOPLEFT", f.Header, "TOPLEFT", W.SHELL.pad + 48 + 16, -32)
	f.psPortraitIcon = icon
	return function(unit)
		if UnitExists(unit) then SetPortraitTexture(icon, unit) else icon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon") end
		f.Subtitle:SetWidth(f.BodyWidth - 48 - 16)
	end
end

-- A friendship NPC's standing (NPCFriendshipStatusBarMixin:Update): its icon,
-- the rank, a Skill Bar, and the stock tooltip's lines. Shared with the Quest
-- dialog. Returns the frame; frame.Paint() shows it for the NPC, or hides it.
function ns.FriendshipBar(parent)
	local b = CreateFrame("Frame", nil, parent)
	b:SetHeight(32)
	b:EnableMouse(true)
	b.Icon = ns.GameIcon(b)
	b.Icon:SetSize(24, 24)
	b.Icon:SetPoint("LEFT", b, "LEFT", 0, 0)
	b.Label = W.Text(b, "label", "text")
	b.Label:SetPoint("TOPLEFT", b.Icon, "TOPRIGHT", 10, 0)
	b.Value = W.Text(b, "small", "textDim")
	b.Value:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, -1)
	b.Bar = W.ProgressLine(b, 2)
	b.Bar:SetPoint("BOTTOMLEFT", b.Icon, "BOTTOMRIGHT", 10, 2)
	b.Bar:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 2)
	function b.Paint()
		local r = C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(0)
		b.info = r and (r.friendshipFactionID or 0) > 0 and r or nil
		b:SetShown(b.info ~= nil)
		if not b.info then return end
		local ranks = C_GossipInfo.GetFriendshipReputationRanks(r.friendshipFactionID)
		b.ranks = ranks
		b.Icon:SetTexture(r.texture and r.texture ~= 0 and r.texture or "Interface\\Common\\friendship-heart")
		b.Label:SetText(r.reaction or "")
		local lo, hi = r.reactionThreshold or 0, r.nextThreshold
		b.Value:SetText(hi and ("%s / %s"):format(BreakUpLargeNumbers(r.standing - lo), BreakUpLargeNumbers(hi - lo)) or "")
		W.SetProgress(b.Bar, hi and (r.standing - lo) / math.max(1, hi - lo) or 1, b:GetWidth() - 34)
	end
	b:SetScript("OnEnter", function(self)
		local r, ranks = self.info, self.ranks
		if not r then return end
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		local title = r.name or ""
		if ranks and ranks.maxLevel > 0 then title = ("%s (%d / %d)"):format(title, ranks.currentLevel, ranks.maxLevel) end
		GameTooltip:SetText(title, 1, 1, 1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(r.text, nil, nil, nil, true)
		local lo = r.reactionThreshold or 0
		GameTooltip:AddLine(r.nextThreshold and ("%s (%d / %d)"):format(r.reaction, r.standing - lo, r.nextThreshold - lo) or r.reaction, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", W.HideTooltip)
	return b
end

-- The rows, in the order keys 1-9 pick them: as GossipFrameSharedMixin:Update
-- lists them, quests to take, quests to hand in, then the options in the
-- game's order.
local function entries()
	local list = {}
	for _, q in ipairs(C_GossipInfo.GetAvailableQuests()) do
		local icon, atlas = QuestUtil.GetQuestIconOfferForQuestID(q.questID, q.isLegendary, q.frequency, q.repeatable, q.isImportant, q.isMeta, q.questInfoID)
		list[#list + 1] = { text = q.title, icon = icon, atlas = atlas, dim = q.isTrivial or q.isIgnored,
			pick = function() C_GossipInfo.SelectAvailableQuest(q.questID) end }
	end
	for _, q in ipairs(C_GossipInfo.GetActiveQuests()) do
		local icon, atlas = QuestUtil.GetQuestIconActiveForQuestID(q.questID, q.isComplete, q.isLegendary, q.frequency, q.repeatable, q.isImportant, q.isMeta, q.questInfoID)
		list[#list + 1] = { text = q.title, icon = icon, atlas = atlas, dim = q.isTrivial or q.isIgnored,
			pick = function() C_GossipInfo.SelectActiveQuest(q.questID) end }
	end
	local options = C_GossipInfo.GetOptions()
	table.sort(options, function(a, b) return a.orderIndex < b.orderIndex end)
	local F = Enum.GossipOptionRecFlags
	for _, o in ipairs(options) do
		local text, pre = o.name, {}
		if bit.band(o.flags or 0, F.QuestLabelPrepend or 0) ~= 0 then pre[#pre + 1] = QUEST_PREPEND end
		if bit.band(o.flags or 0, F.PlayMovieLabelPrepend or 0) ~= 0 then pre[#pre + 1] = PLAY_MOVIE_PREPEND end
		if #pre > 0 then text = GOSSIP_OPTION_PREPEND:format(table.concat(pre, " "), o.name) end
		list[#list + 1] = { text = text, icon = o.overrideIconID or o.icon, spellID = o.spellID,
			pick = function() C_GossipInfo.SelectOptionByIndex(o.orderIndex) end }
	end
	return list
end

local function newRow(i)
	local r = CreateFrame("Button", nil, f.psPanel)
	r:SetPoint("RIGHT", f.psPanel, "RIGHT", 0, 0)
	if i > 1 then
		local d = W.Divider(r)
		d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
		d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
	end
	W.Hover(r)
	r.Icon = r:CreateTexture(nil, "ARTWORK")
	r.Icon:SetSize(16, 16)
	r.Icon:SetPoint("LEFT", r, "LEFT", W.SHELL.side, 0)
	r.Key = W.Text(r, "number", "textMuted")
	r.Key:SetPoint("RIGHT", r, "RIGHT", -W.SHELL.side, 0)
	r.Text = W.Text(r, "body", "text")
	r.Text:SetPoint("LEFT", r.Icon, "RIGHT", 8, 0)
	r.Text:SetWordWrap(true)
	r:SetScript("OnClick", function(self) self.psEntry.pick() end)
	r:SetScript("OnEnter", function(self)
		local id = self.psEntry.spellID
		if not id then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(id)
		GameTooltip:Show()
	end)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[i] = r
	return r
end

local function refresh()
	local list, w = entries(), f.BodyWidth
	W.ShellTitle(f, ns.Clean(UnitName("npc")) or "", #list > 0 and "Click a choice, or press its number." or nil)
	f.psPortrait("npc")
	-- A friendship NPC's standing heads the body, the greeting under it.
	f.psFriend.Paint()
	local y = 24 + (f.psFriend:IsShown() and 32 + 16 or 0)
	f.psGreeting:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -y)
	f.psGreeting:SetWidth(w)
	f.psGreeting:SetText(C_GossipInfo.GetText() or "")
	y = y + math.ceil(f.psGreeting:GetStringHeight()) + 16
	f.psPanel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -y)
	local ph = 0
	for i, e in ipairs(list) do
		local r = rows[i] or newRow(i)
		r.psEntry = e
		if e.atlas then r.Icon:SetAtlas(e.icon) else r.Icon:SetTexture(e.icon) end
		r.Icon:SetDesaturated(e.dim or false)
		r.Key:SetText(i <= 9 and i or "")
		r.Text:SetWidth(w - (W.SHELL.side + 16 + 8) - W.SHELL.side - 24)
		r.Text:SetText(e.text)
		W.Color(r.Text, e.dim and "textMuted" or "text")
		r:SetHeight(math.max(ROW_H, math.ceil(r.Text:GetStringHeight()) + 12))
		r:SetPoint("TOPLEFT", f.psPanel, "TOPLEFT", 0, -ph)
		ph = ph + r:GetHeight()
		r:Show()
	end
	for i = #list + 1, #rows do rows[i]:Hide() end
	f.psPanel:SetHeight(math.max(1, ph))
	f.psPanel:SetShown(#list > 0)
	f.psList = list
	W.ShellBody(f, y + ph + 24)
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 640, height = 560, sidebar = 0 })
	ns.Plain(f)
	ns.Dock(f)
	ns.WindowMenu(f, "gossip")
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, {})
	f.psPortrait = ns.NpcPortrait(f)
	f.psFriend = ns.FriendshipBar(f.Body)
	f.psFriend:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psFriend:SetWidth(f.BodyWidth)
	f.psGreeting = W.Text(f.Body, "body", "text")
	f.psGreeting:SetWordWrap(true)
	f.psRows = rows
	f.psPanel = W.RowPanel(f.Body)
	f.psPanel:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	-- Keys 1-9 pick a row; every other key goes on to the game. Propagation
	-- cannot change in combat, so keys are ours only when it can.
	f:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown() then return end
		local e = key:match("^%d$") and f.psList[tonumber(key)]
		self:SetPropagateKeyboardInput(not e)
		if e then e.pick() end
	end)
	f:SetScript("OnKeyUp", function(self) if not InCombatLockdown() then self:SetPropagateKeyboardInput(true) end end)
	f:HookScript("OnShow", function(self)
		PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN)
		if not InCombatLockdown() then
			self:EnableKeyboard(true)
			self:SetPropagateKeyboardInput(true)
		end
	end)
	-- As the stock OnHide: closed by the player, ours ends the gossip; closed
	-- by the game, never again, and silent when the NPC's next window opens.
	f:HookScript("OnHide", function(self)
		-- A digit picked, then the gossip closed before its key came up.
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(true) end
		if not continuing then PlaySound(SOUNDKIT.IG_QUEST_LIST_CLOSE) end
		if not ended then C_GossipInfo.CloseGossip() end
		ended, continuing = nil, nil
	end)
	Polestar.CloseOnEscape(NAME)
end

function M.Show()
	if not f then build() end
	refresh()
	f:Show()
end

local function close(_, cont)
	if not (f and f:IsShown()) then return end
	ended, continuing = true, cont
	f:Hide()
end

function M.Enable()
	-- The game calls ours for every gossip no custom handler takes. It gets
	-- nil back, so the manager's HideUIPanel never reaches ours (docs/CLIENT.md,
	-- rule 1): ours closes on GOSSIP_CLOSED itself. (No manager: other scenes' stubs.)
	if not CustomGossipFrameManager then return end
	CustomGossipFrameManager:SetBaseHandler(function()
		-- As the stock HandleShow: a lone option the NPC skips to (a vendor) is taken at once.
		local options = C_GossipInfo.GetOptions()
		if C_GossipInfo.GetNumAvailableQuests() == 0 and C_GossipInfo.GetNumActiveQuests() == 0 and #options == 1
			and not C_GossipInfo.ForceGossip() and options[1].selectOptionWhenOnlyOption then
			C_GossipInfo.SelectOptionByIndex(options[1].orderIndex)
			return
		end
		M.Show()
	end)
	Polestar.RegisterEvent("GOSSIP_CLOSED", close)
	-- The stock window closes for a trainer's talent wipe dialog (EventImplementation.lua).
	Polestar.RegisterEvent("CONFIRM_TALENT_WIPE", function() if f and f:IsShown() then f:Hide() end end)
	Polestar.RegisterEvent("QUEST_LOG_UPDATE", function() if f and f:IsShown() then refresh() end end)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return GossipFrame and GossipFrame:IsShown() and GossipFrame end

ns.Module("gossip", M)
