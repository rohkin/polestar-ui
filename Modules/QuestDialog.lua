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
local rows, rows2 = {}, {} -- the greeting's lists: current quests, available quests

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
	local d = { items = 0, choices = 0, money = 0, xp = 0, honor = 0, chooseItems = page == "reward" }
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

-- One list of the greeting: its heading, then a row per quest in its panel.
local function list(panel, pool, head, entries)
	if #entries == 0 then return panel:Hide() end
	c.text("heading", "text", head, 24)
	panel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(c.y + 12))
	local ph = 0
	for i, e in ipairs(entries) do
		local r = pool[i]
		if not r then
			r = CreateFrame("Button", nil, panel)
			r:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
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
			r.Text:SetWordWrap(true)
			r:SetScript("OnClick", function(self)
				PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
				self.psPick()
			end)
			pool[i] = r
		end
		r.psPick = e[5]
		if e[3] then r.Icon:SetAtlas(e[2]) else r.Icon:SetTexture(e[2]) end
		r.Icon:SetSize(16, 16)
		r.Icon:SetDesaturated(e[4] or false)
		r.Text:SetText(e[1])
		W.Color(r.Text, e[4] and "textMuted" or "text")
		-- A long title wraps and the row grows; one line stays centred.
		r.Text:SetWidth(f.BodyWidth - W.SHELL.side * 2 - 24)
		r:SetHeight(math.max(ROW_H, math.ceil(r.Text:GetStringHeight()) + 12))
		r:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -ph)
		ph = ph + r:GetHeight()
		r:Show()
	end
	for i = #entries + 1, #pool do pool[i]:Hide() end
	panel:SetHeight(ph)
	panel:Show()
	c.y = c.y + 12 + ph
end

-- The NPC's quests (QuestFrameGreetingPanel_OnShow): Current Quests (to
-- hand in), then Available Quests (to take), each under its heading.
local function greeting()
	local active, available = {}, {}
	for i = 1, GetNumActiveQuests() do
		local title, done = GetActiveTitle(i)
		local icon, atlas = QuestUtil.GetQuestIconActiveForQuestID(GetActiveQuestID(i), done)
		active[#active + 1] = { title, icon, atlas, IsActiveQuestTrivial(i), function() SelectActiveQuest(i) end }
	end
	for i = 1, GetNumAvailableQuests() do
		local trivial, frequency, repeatable, legendary, id, important, meta, infoID = GetAvailableQuestInfo(i)
		local icon, atlas = QuestUtil.GetQuestIconOfferForQuestID(id, legendary, frequency, repeatable, important, meta, infoID)
		available[#available + 1] = { GetAvailableTitle(i), icon, atlas, trivial, function() SelectAvailableQuest(i) end }
	end
	list(f.psPanel, rows, CURRENT_QUESTS or "Current Quests", active)
	list(f.psPanel2, rows2, AVAILABLE_QUESTS or "Available Quests", available)
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

-- The quest giver's portrait (QuestFrame_ShowQuestPortrait) in a flyout off
-- the window's right edge: the model in our own scene, set up as the stock
-- QuestModelScene (scene 309, the mount and rider actors; -1 is the player),
-- the name under it, then the text.
local PORTRAIT_SCENE = 309
local function portrait(display, text, name, mount, sceneID)
	local p = f.psPortrait
	if not display or display == 0 then return p:Hide() end
	p.Name:SetText(name or "")
	p.Text:SetText(text or "")
	p:Show()
	local m = p.Model
	if not m.TransitionToModelSceneID then return end
	m:ClearScene()
	m:TransitionToModelSceneID(sceneID or PORTRAIT_SCENE, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
	if display == -1 then
		local actor = m:GetPlayerActor("player")
		if actor then actor:SetModelByUnit("player", false) end
		return
	end
	local riderTag, mountActor = "rider", nil
	if (mount or 0) > 0 then
		mountActor = m:GetActorByTag("mount")
		if mountActor then mountActor:SetModelByCreatureDisplayID(mount) end
	else
		riderTag = "mount" -- no mount: the mount actor carries the rider, as the stock scene
	end
	local rider = m:GetActorByTag(riderTag)
	if rider then rider:SetModelByCreatureDisplayID(display) end
	if mountActor and rider then mountActor:AttachToMount(rider, 91, 0) end
end

-- The stock detail text writes itself in (instantQuestText off): the
-- description's alpha gradient at QUEST_DESCRIPTION_GRADIENT_CPS, Accept
-- off until it is done.
local CPS, GRADIENT = 70, 30
local fading

-- What the offer asks besides its objectives (QUEST_TEMPLATE_DETAIL): a spell
-- to learn, the group it suggests, the giver's signature.
local function extras(id)
	local spellID, spellName, spellIcon = GetCriteriaSpell()
	if spellID then
		c.head(LEARN_SPELL_OBJECTIVE or "Learn Spell:")
		c.tile("spell", nil, spellID, spellName, spellIcon)
	end
	local group = GetSuggestedGroupSize() or 0
	if group > 0 then c.text("body", "textDim", (QUEST_SUGGESTED_GROUP_NUM or "Suggested Players: [%d]"):format(group), 14) end
	local theme = C_QuestLog.GetQuestDetailsTheme and C_QuestLog.GetQuestDetailsTheme(id)
	if theme and (theme.signature or "") ~= "" then c.text("body", "textDim", theme.signature, 14):SetJustifyH("RIGHT") end
end

-- Rewards the shared reward column (ns.QuestRewards, Core.lua) does not draw
-- yet: a major faction's reputation and the War Mode bonus, after the rest.
local function moreRewards(id)
	if page ~= "reward" and not C_QuestLog.ShouldShowQuestRewards(id) then return end
	local reps = C_QuestOffer.GetQuestOfferMajorFactionReputationRewards and C_QuestOffer.GetQuestOfferMajorFactionReputationRewards() or {}
	for _, r in ipairs(reps) do
		local data = C_MajorFactions and C_MajorFactions.GetMajorFactionData(r.factionID)
		c.pair(data and data.name or REPUTATION or "Reputation", "+" .. BreakUpLargeNumbers(r.rewardAmount))
	end
	if C_QuestLog.QuestCanHaveWarModeBonus and C_QuestLog.QuestCanHaveWarModeBonus(id) and C_PvP and C_PvP.IsWarModeDesired() then
		c.pair(PVP_LABEL_WAR_MODE or "War Mode", (PLUS_PERCENT_FORMAT or "+%d%%"):format(C_PvP.GetWarModeRewardBonus()))
	end
end

function paint()
	c.Begin(0)
	local left, right = {}, {}
	f.psPanel:Hide()
	f.psPanel2:Hide()
	f.psDesc = nil
	-- The NPC heads the band, its portrait beside it (QuestFrame_SetPortrait:
	-- the quest's NPC, the quest book with none); a quest's title, too long for
	-- a 640 band beside its tools, heads the body as on the World Map's details.
	W.ShellTitle(f, ns.Clean(UnitName("questnpc")) or "")
	f.psPortraitPaint("questnpc")
	-- A friendship NPC's standing heads the body (QuestFrame_OnShow).
	f.psFriend.Paint()
	if f.psFriend:IsShown() then c.y = 24 + 32 end
	if page == "greeting" then
		c.text("body", "text", GetGreetingText(), 24)
		greeting()
	else
		local id = GetQuestID()
		c.text("title", "text", GetTitleText(), 24)
		if page == "detail" then
			-- The World Map's details: objectives, then the story, then the rewards.
			c.text("body", "text", GetObjectiveText(), 8)
			extras(id)
			c.text("heading", "text", "Description", 24)
			f.psDesc = c.text("body", "textDim", GetQuestText(), 8)
			rewards()
			moreRewards(id)
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
			moreRewards(id)
			right[1] = { label = "Complete quest", onClick = complete, opts = { primary = true } }
		end
	end
	c.End()
	ns.Footer(f, left, right)
	-- Each page greys its own, with the reason a greyed one gives.
	local go = f.footerButtons.right[1]
	if page == "progress" then
		ns.SetEnabled(go, IsQuestCompletable(), "You don't have everything this quest asks for yet.")
	elseif page == "detail" then
		if fading and f.psDesc.SetAlphaGradient then f.psDesc:SetAlphaGradient(fading, GRADIENT) end
		ns.SetEnabled(go, not fading, "The quest text is still writing in.")
	end
	-- An auto-accepted quest is taken, not closed (QuestFrameDetailPanel_OnShow).
	ns.SetEnabled(f.Close, not (page == "detail" and QuestGetAutoAccept()), "This quest is already yours: press OK.")
	W.ShellBody(f, c.y + 24)
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 640, height = 600, sidebar = 0 })
	ns.Plain(f)
	ns.Dock(f)
	ns.WindowMenu(f, "questdialog")
	c = ns.QuestRewards(f.Body, { x = W.SHELL.pad, width = f.BodyWidth, tip = tileTip, click = tileClick,
		selected = function(type, index) return page == "reward" and type == "choice" and index == choice end })
	W.ShellTabs(f, nil)
	f.psPortraitPaint = ns.NpcPortrait(f)
	f.psFriend = ns.FriendshipBar(f.Body)
	f.psFriend:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psFriend:SetWidth(f.BodyWidth)
	f.psPanel = W.RowPanel(f.Body)
	f.psPanel:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	f.psPanel2 = W.RowPanel(f.Body)
	f.psPanel2:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	local p = ns.Flyout(f, NAME .. "Portrait", 232)
	p.Model = CreateFrame("ModelScene", nil, p, "PanningModelSceneMixinTemplate")
	p.Model:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -16)
	p.Model:SetSize(200, 240)
	p.Name = W.Text(p, "heading", "text")
	p.Name:SetPoint("TOPLEFT", p.Model, "BOTTOMLEFT", 0, -12)
	p.Name:SetWidth(200)
	p.Text = W.Text(p, "body", "textDim")
	p.Text:SetPoint("TOPLEFT", p.Name, "BOTTOMLEFT", 0, -8)
	p.Text:SetWidth(200)
	p.Text:SetWordWrap(true)
	p.Text:SetSpacing(2)
	p:Hide()
	f.psPortrait = p
	ns.DockFlyout(f, p, 1)
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN) end)
	f:SetScript("OnUpdate", function(_, elapsed)
		if not (fading and f.psDesc) then return end
		fading = fading + elapsed * CPS
		PlaySound(SOUNDKIT.IG_WRITE_QUEST)
		if not (f.psDesc.SetAlphaGradient and f.psDesc:SetAlphaGradient(fading, GRADIENT)) then
			fading = nil
			ns.SetEnabled(f.footerButtons.right[1], true)
		end
	end)
	-- As the stock OnHide: closed by the player, ours ends the quest dialog;
	-- closed by the game (QUEST_FINISHED), never again. An auto-accepted
	-- quest's tracker pop-up goes with it.
	f:HookScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_QUEST_LIST_CLOSE)
		if page == "detail" and QuestGetAutoAccept() then
			RemoveAutoQuestPopUp(GetQuestID())
			PlaySound(SOUNDKIT.UI_AUTO_QUEST_COMPLETE)
		end
		if not ended then CloseQuest() end
		ended, page, fading = nil, nil, nil
		f.psPortrait:Hide()
	end)
	Polestar.CloseOnEscape(NAME)
end

-- Shown only on the game's open events: away from a quest giver there is nothing to show.
function M.Show()
	if not page then return end
	if not f then build() end
	fading = page == "detail" and GetCVar("instantQuestText") == "0" and 0 or nil
	paint()
	-- The giver on an offer, the one who takes it on the reward page; none on the others.
	if page == "detail" then
		portrait(GetQuestPortraitGiver())
	elseif page == "reward" then
		local display, text, name = GetQuestPortraitTurnIn()
		portrait(display, text, name, 0)
	else
		f.psPortrait:Hide()
	end
	W.ScrollTo(f.Scroll, 0)
	f:Show()
end

-- An offer the stock frame does not show (QuestFrame_OnEvent): one an item
-- starts, or an auto-accepted one from an area trigger, goes to the objective
-- tracker as a pop-up (the client's AddAutoQuestPopUp; the tracker draws it
-- on its next update) and the dialog ends; one from the adventure map stays
-- the map's.
local function offerElsewhere(itemID)
	if QuestIsFromAdventureMap and QuestIsFromAdventureMap() then return true end
	if (itemID and itemID ~= 0) or (QuestGetAutoAccept() and QuestIsFromAreaTrigger()) then
		if AddAutoQuestPopUp(GetQuestID(), "OFFER") then PlaySound(SOUNDKIT.UI_AUTO_QUEST_COMPLETE) end
		CloseQuest()
		return true
	end
end

function M.Enable()
	for event, p in pairs(OPEN) do
		-- The stock window's own open, stopped (docs/CLIENT.md, rule 15's exception).
		if QuestFrame then QuestFrame:UnregisterEvent(event) end
		Polestar.RegisterEvent(event, function(_, itemID)
			if p == "detail" and offerElsewhere(itemID) then return end
			page, choice = p, nil
			M.Show()
		end)
	end
	Polestar.RegisterEvent("QUEST_FINISHED", function()
		if not (f and f:IsShown()) then return end
		ended = true
		f:Hide()
	end)
	-- Late item data, the quest log and the NPC's portrait redraw the open page.
	for _, e in ipairs({ "QUEST_ITEM_UPDATE", "QUEST_LOG_UPDATE", "GET_ITEM_INFO_RECEIVED", "LEARNED_SPELL_IN_SKILL_LINE", "UNIT_PORTRAIT_UPDATE", "PORTRAITS_UPDATED" }) do
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
