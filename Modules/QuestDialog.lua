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
local TILE, ROW_H = 32, 32

local f, page, choice, ended, cost
local M = { reloadOff = true }

-- Pooled pieces on the body, laid out top down from y (QuestLog.lua's details).
local texts, used, tiles, rows, nTile, y = {}, {}, {}, {}, 0, 0
local function text(role, color, s, gap)
	used[role] = (used[role] or 0) + 1
	texts[role] = texts[role] or {}
	local t = texts[role][used[role]]
	if not t then
		t = W.Text(f.Body, role, "text")
		t:SetWordWrap(true)
		t:SetSpacing(2)
		texts[role][used[role]] = t
	end
	W.Color(t, color)
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(y + gap))
	t:SetWidth(f.BodyWidth)
	t:SetJustifyH("LEFT")
	t:SetText(s or "")
	t:Show()
	y = y + gap + math.ceil(t:GetStringHeight())
	return t
end
local function head(s) if s then text("label", "textDim", s, 14) end end
-- A fact: its name, and its value at the right of the same line.
local function pair(label, value, color)
	local l = text("body", "textDim", label, 8)
	local v = text("number", color or "text", value, 0)
	v:ClearAllPoints()
	v:SetPoint("TOPRIGHT", l, "TOPRIGHT", 0, 0)
	v:SetJustifyH("RIGHT")
	y = y - math.ceil(v:GetStringHeight())
end
-- What reward XP is worth of the player's level, as "35% of level 12".
local function levelShare(xp)
	local max = UnitXPMax("player")
	if not (max and max > 0 and GameRulesUtil.CanShowExperienceBar()) then return end
	local pct = xp / max * 100
	return ("%s of level %d"):format(pct < 1 and "<1%" or math.floor(pct) .. "%", UnitLevel("player"))
end

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
local function newTile()
	local t = CreateFrame("Button", nil, f.Body)
	t:SetHeight(TILE)
	W.Hover(t)
	t.Sel = W.Painter(W.Tex(t, "BACKGROUND"), function(s) s:SetVertexColor(Theme.Wash("selected")) end)
	t.Sel:SetAllPoints(t)
	t.Well = CreateFrame("Frame", nil, t)
	t.Well:SetSize(TILE, TILE)
	t.Well:SetPoint("LEFT", t, "LEFT", 0, 0)
	Theme.Skin(t.Well, "inset")
	t.Icon = ns.GameIcon(t.Well)
	t.Icon:SetPoint("TOPLEFT", 1, -1)
	t.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	-- The marks: arrow and coin in the icon's top corners, the best in a 2px accent frame.
	t.Up = W.Tex(t.Well, "OVERLAY", "qol-upgrade", "success", 2)
	t.Up:SetSize(16, 16)
	t.Up:SetPoint("TOPLEFT", t.Well, "TOPLEFT", -2, 2)
	t.Coin = W.Tex(t.Well, "OVERLAY", "qol-coin", "accent", 2)
	t.Coin:SetSize(16, 16)
	t.Coin:SetPoint("TOPRIGHT", t.Well, "TOPRIGHT", 2, 2)
	t.Ring = {}
	for i, p in ipairs({ { "TOPLEFT", "TOPRIGHT", -2, 2, 2, 2 }, { "BOTTOMLEFT", "BOTTOMRIGHT", -2, -2, 2, -2 },
		{ "TOPLEFT", "BOTTOMLEFT", -2, 2, -2, -2 }, { "TOPRIGHT", "BOTTOMRIGHT", 2, 2, 2, -2 } }) do
		local e = W.Tex(t.Well, "OVERLAY", nil, "accent", 1)
		e:SetPoint(p[1], t.Well, p[1], p[3], p[4])
		e:SetPoint(p[2], t.Well, p[2], p[5], p[6])
		if i <= 2 then e:SetHeight(2) else e:SetWidth(2) end
		t.Ring[i] = e
	end
	t.Count = W.Text(t, "number", "text")
	t.Count:SetPoint("RIGHT", t, "RIGHT", -8, 0)
	t.Name = W.Text(t, "label", "text")
	t.Name:SetPoint("LEFT", t.Well, "RIGHT", 8, 0)
	t.Name:SetPoint("RIGHT", t.Count, "LEFT", -8, 0)
	t:SetScript("OnEnter", tileTip)
	t:SetScript("OnLeave", W.HideTooltip)
	t:SetScript("OnClick", function(self)
		if IsModifiedClick() then
			if self.psKind == "item" then HandleModifiedItemClick(GetQuestItemLink(self.psType, self.psIndex)) end
		elseif self.psType == "choice" and page == "reward" then
			choice = self.psIndex
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			paint()
		end
	end)
	return t
end
local function tile(kind, type, index, name, icon, count, q, usable, mark)
	nTile = nTile + 1
	local t = tiles[nTile] or newTile()
	tiles[nTile] = t
	t.psKind, t.psType, t.psIndex = kind, type, index
	t.Icon:SetTexture(icon)
	-- One the player cannot use, red as on the stock button.
	if usable == false then t.Icon:SetVertexColor(0.9, 0, 0) else t.Icon:SetVertexColor(1, 1, 1) end
	t.Name:SetText(name or RETRIEVING_ITEM_INFO or "")
	t.Count:SetText(type == "required" and count or (count and count > 1 and count or ""))
	-- The name in its quality colour, lifted; the border raw from uncommon up.
	local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	W.Uncolor(t.Name)
	if c then t.Name:SetTextColor(Theme.Legible(c.r, c.g, c.b)) else W.Color(t.Name, "text") end
	local br, bg, bb, ba = 0, 0, 0, 1
	if c and q >= 2 then br, bg, bb = c.r, c.g, c.b else br, bg, bb, ba = Theme.Wash("border") end
	Theme.Border(t.Well, br, bg, bb, ba, "OVERLAY")
	mark = mark or {}
	t.Up:SetShown(mark.up or false)
	t.Coin:SetShown(mark.coin or false)
	for _, e in ipairs(t.Ring) do e:SetShown(mark.best or false) end
	t.Sel:SetShown(page == "reward" and type == "choice" and index == choice)
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(y + 6))
	t:SetWidth(f.BodyWidth)
	t:Show()
	y = y + 6 + TILE
end

-- A spell reward's place and heading, by its kind (QuestInfo's
-- GetRewardSpellBucketType and its ordering), as QuestLog.lua.
local function spellKind(s)
	local T = Enum.QuestCompleteSpellType
	local k = (s.type and s.type ~= T.LegacyBehavior and s.type) or (s.isTradeskillSpell and T.Tradeskill)
		or (s.isBoostSpell and T.Ability) or (s.garrFollowerID and T.Follower) or (s.isSpellLearned and T.Spell)
		or (s.genericUnlock and T.Unlock) or T.Aura
	local order = { T.Follower, T.Companion, T.Tradeskill, T.Ability, T.Aura, T.Spell, T.Unlock, T.QuestlineUnlock,
		T.QuestlineReward, T.QuestlineUnlockPart, T.PossibleReward }
	local heads = { REWARD_FOLLOWER, REWARD_COMPANION, REWARD_TRADESKILL_SPELL, REWARD_ABILITY, REWARD_AURA, REWARD_SPELL,
		REWARD_UNLOCK, REWARD_QUESTLINE_UNLOCK, REWARD_QUESTLINE_REWARD, REWARD_QUESTLINE_UNLOCK_PART, REWARD_POSSIBLE_QUEST_REWARD }
	for i, v in ipairs(order) do if v == k then return i, heads[i] end end
	return #order + 1
end

-- The quest giver's rewards in QuestInfo_ShowRewards' order (its npc branch).
local function rewards()
	local id = GetQuestID()
	local items, choices, money, xp, honor, title, skillName, skillIcon, skillPoints = 0, 0, 0, 0, 0, nil, nil, nil, nil
	if page == "reward" or C_QuestLog.ShouldShowQuestRewards(id) then
		items, choices, money, xp, honor, title = GetNumQuestRewards(), GetNumQuestChoices(), GetRewardMoney(), GetRewardXP(), GetRewardHonor(), GetRewardTitle()
		skillName, skillIcon, skillPoints = GetRewardSkillPoints()
	end
	local currencies = C_QuestInfoSystem.GetQuestRewardCurrencies(id) or {}
	local spells = {}
	for i, spellID in ipairs(C_QuestInfoSystem.GetQuestRewardSpells(id) or {}) do
		local s = spellID and spellID > 0 and C_QuestInfoSystem.GetQuestRewardSpellInfo(id, spellID)
		if s and s.texture and not C_SpellBook.IsSpellInSpellBook(spellID, Enum.SpellBookSpellBank.Player, true)
			and (not s.isBoostSpell or IsCharacterNewlyBoosted())
			and (not s.garrFollowerID or not C_Garrison.IsFollowerCollected(s.garrFollowerID)) then
			local order, h = spellKind(s)
			s.spellID, s.head, s.order = spellID, h, order * 1000 + i
			spells[#spells + 1] = s
		end
	end
	if items + choices + #currencies + #spells == 0 and money == 0 and xp == 0 and honor == 0 and not title and not skillPoints then return end
	text("heading", "text", "Rewards", 24)
	if choices > 0 then
		head(choices == 1 and REWARD_ITEMS_ONLY or REWARD_CHOICES)
		local m = marks()
		for i = 1, choices do
			if GetQuestItemInfoLootType("choice", i) == 1 then
				local c = C_QuestOffer.GetQuestRewardCurrencyInfo("choice", i)
				if c then tile("currency", "choice", i, c.name, c.texture, c.totalRewardAmount, c.quality) end
			else
				local name, icon, n, q, usable = GetQuestItemInfo("choice", i)
				tile("item", "choice", i, name, icon, n, q, usable, m[i])
			end
		end
	end
	table.sort(spells, function(a, b) return a.order < b.order end)
	local lastHead
	for _, s in ipairs(spells) do
		if s.head ~= lastHead and not s.hideSpellLearnText then head(s.head) end
		lastHead = s.head
		tile("spell", nil, s.spellID, s.name, s.texture)
	end
	if title then
		head(REWARD_TITLE)
		text("body", "text", title, 6)
	end
	if items + #currencies > 0 or money > 0 or xp > 0 or honor > 0 or skillPoints then
		head((choices > 0 or #spells > 0 or title) and REWARD_ITEMS or REWARD_ITEMS_ONLY)
		if xp > 0 then
			pair("Experience", BreakUpLargeNumbers(xp) .. " XP")
			local share = levelShare(xp)
			if share then text("small", "textMuted", share, 2):SetJustifyH("RIGHT") end
		end
		if money > 0 then pair("Money", GetMoneyString(money)) end
		if skillPoints then tile(nil, nil, nil, skillName, skillIcon, skillPoints) end
		for i = 1, items do
			local name, icon, n, q, usable = GetQuestItemInfo("reward", i)
			tile("item", "reward", i, name, icon, n, q, usable)
		end
		for i, c in ipairs(currencies) do tile("currency", "reward", i, c.name, c.texture, c.totalRewardAmount, c.quality) end
		if honor > 0 then pair(HONOR or "Honor", BreakUpLargeNumbers(honor)) end
	end
end

-- What the quest takes, as QuestFrameProgressItems_Update: money, then items as "have/need".
local function required()
	local money = GetQuestMoneyToGet()
	local n = C_QuestOffer.GetHideRequiredItems() and 0 or GetNumQuestItems()
	local nc = GetNumQuestCurrencies()
	if money + n + nc == 0 then return end
	text("heading", "text", "Required", 24)
	if money > 0 then pair("Money", GetMoneyString(money), money > GetMoney() and "danger" or nil) end
	for i = 1, n do
		if IsQuestItemHidden(i) == 0 then
			local name, icon, need, q, usable, itemID = GetQuestItemInfo("required", i)
			tile("item", "required", i, name, icon, ("%d/%d"):format(math.min(C_Item.GetItemCount(itemID), need), need), q, usable)
		end
	end
	for i = 1, nc do
		local c = C_QuestOffer.GetQuestRequiredCurrencyInfo(i)
		if c then tile("currency", "required", i, c.name, c.texture, tostring(c.requiredAmount), c.quality) end
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
	f.psPanel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(y + 16))
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
	y = y + 16 + ph
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
	used, nTile, y = {}, 0, 0
	local left, right = {}, {}
	f.psPanel:Hide()
	-- The NPC heads the band; a quest's title, too long for a 560 band beside
	-- its tools, heads the body as on the World Map's details.
	W.ShellTitle(f, ns.Clean(UnitName("npc")) or "", page == "greeting" and "Click a quest." or nil)
	if page == "greeting" then
		text("body", "text", GetGreetingText(), 24)
		greeting()
	else
		text("title", "text", GetTitleText(), 24)
		if page == "detail" then
			-- The World Map's details: objectives, then the story, then the rewards.
			text("body", "text", GetObjectiveText(), 8)
			text("heading", "text", "Description", 24)
			text("body", "textDim", GetQuestText(), 8)
			rewards()
			local auto = QuestGetAutoAccept()
			if not auto then left[1] = { label = "Decline", onClick = function() f:Hide(); PlaySound(SOUNDKIT.IG_QUEST_CANCEL) end } end
			right[1] = { label = auto and "OK" or "Accept", onClick = accept, opts = { primary = true } }
		elseif page == "progress" then
			text("body", "text", GetProgressText(), 8)
			required()
			right[1] = { label = "Continue", onClick = function() CompleteQuest(); PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN) end, opts = { primary = true } }
		else
			text("body", "text", GetRewardText(), 8)
			rewards()
			right[1] = { label = "Complete quest", onClick = complete, opts = { primary = true } }
		end
	end
	for role, l in pairs(texts) do for i = (used[role] or 0) + 1, #l do l[i]:Hide() end end
	for i = nTile + 1, #tiles do tiles[i]:Hide() end
	W.ShellFooter(f, left, right)
	if page == "progress" then f.footerButtons.right[1]:SetEnabled(IsQuestCompletable() and true or false) end
	W.ShellBody(f, y + 24)
end

local function build()
	-- Plain: no sidebar; the main column hangs off the window itself, never
	-- off the 0-wide sidebar (docs/CLIENT.md, rule 12).
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 560, height = 600, sidebar = 0 })
	f.Sidebar:Hide()
	f.Main:ClearAllPoints()
	f.Main:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
	f.Main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
	ns.Dock(f)
	ns.WindowMenu(f, "questdialog")
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
