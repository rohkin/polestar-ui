-- The Quest dialog (docs/windows/questdialog.md): a quest giver's greeting,
-- offer, progress and reward pages in a plain Polestar shell. The stock
-- QuestFrame's open events are unregistered on it (docs/CLIENT.md, rule 15's
-- exception), so it never opens; ours answers them whoever led there (an NPC,
-- the Gossip window, an item). Off waits for /reload.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUIQuestDialog"
local OPEN = { QUEST_GREETING = "greeting", QUEST_DETAIL = "detail", QUEST_PROGRESS = "progress", QUEST_COMPLETE = "reward" }
local ROW_H = 32

local f, page, choice, ended, cost
local M = { reloadOff = true }

local c -- the page's text and tiles (ns.QuestRewards)
local rows = {}

-- Polestar's reward marks (QoL/Rewards.lua), drawn on our choices as Polestar
-- draws them on the stock buttons: the upgrade arrow, the coin on the highest
-- vendor value once every price is known, and the best of two or more once
-- every verdict is in. -> { [choice index] = { up, coin, best } }
local function marks()
	local Q = Polestar.QoL
	local R = Q and Q.Rewards
	if not (R and R.ReadChoices and R.Rank and Q.On and Q.On("rewardHighlight")) or (Polestar.Hidden and Polestar.Hidden()) then return {} end
	local list, complete, priced = R.ReadChoices(false)
	local best = #list >= 2 and complete and R.Rank(list)[1]
	local top = 0
	if #list >= 2 and priced then for _, c in ipairs(list) do top = math.max(top, c.value or 0) end end
	local m = {}
	for _, c in ipairs(list) do
		m[c.index] = { up = c.upgrade and (c.delta or 0) > 0, coin = top > 0 and c.value == top, best = c.index == best }
	end
	return m
end

-- A reward or a required item (docs/DESIGN.md, "Reagent Tile"): the game's
-- tooltip, as the stock button's; on the reward page a click picks a choice.
local function tileTip(t)
	if not t.psKind then return end
	GameTooltip:SetOwner(t, "ANCHOR_RIGHT")
	if t.psKind == "item" then
		GameTooltip:SetQuestItem(t.psType, t.psIndex, false)
		GameTooltip_ShowCompareItem(GameTooltip)
	elseif t.psKind == "currency" then
		GameTooltip:SetQuestCurrency(t.psType, t.psIndex)
	else
		GameTooltip:SetSpellByID(t.psIndex, nil, true)
	end
	if t.psType == "choice" and page == "reward" then ns.TooltipHint("Click to choose this reward.") end
	GameTooltip:Show()
end
local paint
local function tileClick(self)
	if IsModifiedClick() then
		if self.psKind == "item" then HandleModifiedItemClick(GetQuestItemLink(self.psType, self.psIndex)) end
	elseif self.psType == "choice" and page == "reward" then
		choice = self.psIndex
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		paint()
	end
end

-- The quest giver's rewards in QuestInfo_ShowRewards' order (its npc branch).
local function rewards()
	local id = GetQuestID()
	local d = { items = 0, choices = 0, money = 0, xp = 0, honor = 0 }
	if page == "reward" or C_QuestLog.ShouldShowQuestRewards(id) then
		d.items, d.choices, d.money, d.xp, d.honor, d.title = GetNumQuestRewards(), GetNumQuestChoices(), GetRewardMoney(), GetRewardXP(), GetRewardHonor(), GetRewardTitle()
		d.skillName, d.skillIcon, d.skillPoints = GetRewardSkillPoints()
	end
	local m
	function d.choice(i)
		m = m or marks()
		if GetQuestItemInfoLootType("choice", i) == 1 then
			local cur = C_QuestOffer.GetQuestRewardCurrencyInfo("choice", i)
			if cur then c.tile("currency", "choice", i, cur.name, cur.texture, cur.totalRewardAmount, cur.quality) end
		else
			local name, icon, n, q, usable = GetQuestItemInfo("choice", i)
			c.tile("item", "choice", i, name, icon, n, q, usable, m[i])
		end
	end
	function d.reward(i) return GetQuestItemInfo("reward", i) end
	c.Rewards(id, d)
end

-- What the quest takes, as QuestFrameProgressItems_Update: money, then items as "have/need".
local function required()
	local money = GetQuestMoneyToGet()
	local n = C_QuestOffer.GetHideRequiredItems() and 0 or GetNumQuestItems()
	local nc = GetNumQuestCurrencies()
	if money + n + nc == 0 then return end
	c.text("heading", "text", "Required", 24)
	if money > 0 then c.money("Money", money, money > GetMoney() and "danger" or nil) end
	for i = 1, n do
		if IsQuestItemHidden(i) == 0 then
			local name, icon, need, q, usable, itemID = GetQuestItemInfo("required", i)
			c.tile("item", "required", i, name, icon, ("%d/%d"):format(math.min(C_Item.GetItemCount(itemID), need), need), q, usable)
		end
	end
	for i = 1, nc do
		local cur = C_QuestOffer.GetQuestRequiredCurrencyInfo(i)
		if cur then c.tile("currency", "required", i, cur.name, cur.texture, tostring(cur.requiredAmount), cur.quality) end
	end
end

-- The NPC's quests (QuestFrameGreetingPanel_OnShow): to hand in, then to take.
local function greeting()
	local list = {}
	for i = 1, GetNumActiveQuests() do
		local title, done = GetActiveTitle(i)
		local icon, atlas = QuestUtil.GetQuestIconActiveForQuestID(GetActiveQuestID(i), done)
		list[#list + 1] = { title, icon, atlas, IsActiveQuestTrivial(i), function() SelectActiveQuest(i) end }
	end
	for i = 1, GetNumAvailableQuests() do
		local trivial, frequency, repeatable, legendary, id, important, meta, infoID = GetAvailableQuestInfo(i)
		local icon, atlas = QuestUtil.GetQuestIconOfferForQuestID(id, legendary, frequency, repeatable, important, meta, infoID)
		list[#list + 1] = { GetAvailableTitle(i), icon, atlas, trivial, function() SelectAvailableQuest(i) end }
	end
	f.psPanel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(c.y + 16))
	local ph = 0
	for i, e in ipairs(list) do
		local r = rows[i]
		if not r then
			r = CreateFrame("Button", nil, f.psPanel)
			r:SetPoint("RIGHT", f.psPanel, "RIGHT", 0, 0)
			if i > 1 then
				local d = W.Divider(r)
				d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
				d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
			end
			W.Hover(r)
			r.Icon = r:CreateTexture(nil, "ARTWORK")
			r.Icon:SetPoint("LEFT", r, "LEFT", W.SHELL.side, 0)
			r.Text = W.Text(r, "body", "text")
			r.Text:SetPoint("LEFT", r, "LEFT", W.SHELL.side + 24, 0)
			r.Text:SetPoint("RIGHT", r, "RIGHT", -W.SHELL.side, 0)
			r:SetScript("OnClick", function(self)
				PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
				self.psPick()
			end)
			rows[i] = r
		end
		r.psPick = e[5]
		if e[3] then r.Icon:SetAtlas(e[2]) else r.Icon:SetTexture(e[2]) end
		r.Icon:SetSize(16, 16)
		r.Icon:SetDesaturated(e[4] or false)
		r.Text:SetText(e[1])
		W.Color(r.Text, e[4] and "textMuted" or "text")
		r:SetHeight(ROW_H)
		r:SetPoint("TOPLEFT", f.psPanel, "TOPLEFT", 0, -ph)
		ph = ph + ROW_H
		r:Show()
	end
	for i = #list + 1, #rows do rows[i]:Hide() end
	f.psPanel:SetHeight(math.max(1, ph))
	f.psPanel:Show()
	c.y = c.y + 16 + ph
end

-- Accept (QuestDetailAcceptButton_OnClick): a PvP quest asks first, in our dialog.
local function accept()
	if QuestFlagsPVP() then
		W.Modal({ title = "Accept this quest?", text = CONFIRM_ACCEPT_PVP_QUEST, action = "Accept", onAccept = AcceptQuest,
			onCancel = function() DeclineQuest(); PlaySound(SOUNDKIT.IG_QUEST_CANCEL) end })
	elseif QuestGetAutoAccept() then
		AcknowledgeAutoAcceptQuest()
	else
		AcceptQuest()
	end
end

-- Complete (QuestRewardCompleteButton_OnClick): a choice first, and a quest
-- that takes money asks first, naming it.
local function complete()
	local n = GetNumQuestChoices()
	if n == 1 then choice = 1 end
	if n > 1 and not choice then return QuestChooseRewardError() end
	local money = GetQuestMoneyToGet()
	if not (money and money > 0) then return GetQuestReward(choice or 0) end
	cost = cost or ns.Money(UIParent)
	ns.SetMoney(cost, money, money > GetMoney() and "danger" or nil)
	ns.ModalWith({ title = "Complete this quest?", text = CONFIRM_COMPLETE_EXPENSIVE_QUEST, action = "Complete",
		onAccept = function() GetQuestReward(choice or 0); PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE) end,
		onCancel = function() DeclineQuest(); PlaySound(SOUNDKIT.IG_QUEST_CANCEL) end }, cost)
end

function paint()
	c.Begin(0)
	local left, right = {}, {}
	f.psPanel:Hide()
	-- The NPC heads the band; a quest's title, too long for a 560 band beside
	-- its tools, heads the body as on the World Map's details.
	W.ShellTitle(f, ns.Clean(UnitName("npc")) or "", page == "greeting" and "Click a quest." or nil)
	if page == "greeting" then
		c.text("body", "text", GetGreetingText(), 24)
		greeting()
	else
		c.text("title", "text", GetTitleText(), 24)
		if page == "detail" then
			-- The World Map's details: objectives, then the story, then the rewards.
			c.text("body", "text", GetObjectiveText(), 8)
			c.text("heading", "text", "Description", 24)
			c.text("body", "textDim", GetQuestText(), 8)
			rewards()
			local auto = QuestGetAutoAccept()
			if not auto then left[1] = { label = "Decline", onClick = function() f:Hide(); PlaySound(SOUNDKIT.IG_QUEST_CANCEL) end } end
			right[1] = { label = auto and "OK" or "Accept", onClick = accept, opts = { primary = true } }
		elseif page == "progress" then
			c.text("body", "text", GetProgressText(), 8)
			required()
			right[1] = { label = "Continue", onClick = function() CompleteQuest(); PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN) end, opts = { primary = true } }
		else
			c.text("body", "text", GetRewardText(), 8)
			rewards()
			right[1] = { label = "Complete quest", onClick = complete, opts = { primary = true } }
		end
	end
	c.End()
	W.ShellFooter(f, left, right)
	if page == "progress" then f.footerButtons.right[1]:SetEnabled(IsQuestCompletable() and true or false) end
	W.ShellBody(f, c.y + 24)
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 560, height = 600, sidebar = 0 })
	ns.Plain(f)
	ns.Dock(f)
	ns.WindowMenu(f, "questdialog")
	c = ns.QuestRewards(f.Body, { x = W.SHELL.pad, width = f.BodyWidth, tip = tileTip, click = tileClick,
		selected = function(type, index) return page == "reward" and type == "choice" and index == choice end })
	W.ShellTabs(f, nil)
	f.psPanel = W.RowPanel(f.Body)
	f.psPanel:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN) end)
	-- As the stock OnHide: closed by the player, ours ends the quest dialog;
	-- closed by the game (QUEST_FINISHED), never again.
	f:HookScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_QUEST_LIST_CLOSE)
		if not ended then CloseQuest() end
		ended, page = nil, nil
	end)
	Polestar.CloseOnEscape(NAME)
end

-- Shown only on the game's open events: away from a quest giver there is nothing to show.
function M.Show()
	if not page then return end
	if not f then build() end
	paint()
	W.ScrollTo(f.Scroll, 0)
	f:Show()
end

function M.Enable()
	for event, p in pairs(OPEN) do
		-- The stock window's own open, stopped (docs/CLIENT.md, rule 15's exception).
		if QuestFrame then QuestFrame:UnregisterEvent(event) end
		Polestar.RegisterEvent(event, function()
			-- An offer from the adventure map stays the map's (QuestFrame_OnEvent).
			if p == "detail" and QuestIsFromAdventureMap and QuestIsFromAdventureMap() then return end
			page, choice = p, nil
			M.Show()
		end)
	end
	Polestar.RegisterEvent("QUEST_FINISHED", function()
		if not (f and f:IsShown()) then return end
		ended = true
		f:Hide()
	end)
	-- Late item data and the quest log redraw the open page.
	for _, e in ipairs({ "QUEST_ITEM_UPDATE", "QUEST_LOG_UPDATE", "GET_ITEM_INFO_RECEIVED", "LEARNED_SPELL_IN_SKILL_LINE" }) do
		Polestar.RegisterEvent(e, function() if f and f:IsShown() then paint() end end)
	end
	-- Polestar's verdicts and its mark setting redraw the marks.
	if Polestar.On then
		for _, msg in ipairs({ "GEAR_UPDATED", "SETTING_CHANGED", "POLESTAR_HIDDEN" }) do
			Polestar.On(msg, function() if f and f:IsShown() then paint() end end)
		end
	end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return QuestFrame and QuestFrame:IsShown() and QuestFrame end

ns.Module("questdialog", M)
