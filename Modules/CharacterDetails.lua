-- The drawer's details for the Character window's other sections
-- (docs/windows/character.md), as the stock right pane has them
-- (CharacterFrameSidePaneMixin): the chosen faction, currency or skill, and
-- the PvP rank. Each is a pane in ns.CharacterPanes (Character.lua).

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local PANE_W, CHECK_H = 280, 28

local function refresh() if ns.RefreshCharacter then ns.RefreshCharacter() end end

-- A details view: a scrolling column of texts (ns.QuestRewards' pooled
-- lines, pairs and tiles) with a bar, over a footer of checkboxes.
--   v.c: the column; v.Bar: a 2px bar placed by v.bar(frac, r, g, b);
--   v.checks[i]: v.check(i, label, checked, enabled, onClick, tip, color).
local function detailView(holder, nChecks)
	local sf = W.Scroll(holder)
	sf:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
	sf:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, (nChecks or 0) * CHECK_H + (nChecks and nChecks > 0 and 24 or 0))
	sf.Child:SetWidth(PANE_W - 4)
	sf.c = ns.QuestRewards(sf.Child, { x = 24, width = PANE_W - 48,
		tip = function(t)
			if not t.psTip then return end
			GameTooltip:SetOwner(t, "ANCHOR_RIGHT")
			GameTooltip:SetText(t.psTip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end })
	sf.Prog = W.ProgressLine(sf.Child, 2)
	sf.Prog:SetWidth(PANE_W - 48)
	sf.checks = {}
	for i = 1, nChecks or 0 do
		local r = CreateFrame("Button", nil, holder)
		r:SetHeight(CHECK_H)
		r:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 20, 20 + (nChecks - i) * CHECK_H)
		r:SetPoint("RIGHT", holder, "RIGHT", -20, 0)
		W.Hover(r)
		r.Box = W.Checkbox(r)
		r.Box:SetPoint("LEFT", r, "LEFT", 4, 0)
		r.Box:EnableMouse(false)
		r.Label = W.Text(r, "label", "text")
		r.Label:SetPoint("LEFT", r.Box, "RIGHT", 10, 0)
		r:SetScript("OnClick", function(self)
			if not self.psOn then return end
			PlaySound(self.Box:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			self.psClick(not self.Box:GetChecked())
			refresh()
		end)
		r:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.psTip, 1, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		r:SetScript("OnLeave", W.HideTooltip)
		sf.checks[i] = r
	end
	function sf.bar(frac, r, g, b)
		local c = sf.c
		sf.Prog:ClearAllPoints()
		sf.Prog:SetPoint("TOPLEFT", sf.Child, "TOPLEFT", 24, -(c.y + 8))
		W.SetProgress(sf.Prog, math.max(0, math.min(1, frac)), PANE_W - 48)
		W.Uncolor(sf.Prog.Fill)
		if r then sf.Prog.Fill:SetVertexColor(r, g, b, 1) else W.Color(sf.Prog.Fill, "accent") end
		sf.Prog:Show()
		c.y = c.y + 10
	end
	function sf.check(i, label, checked, enabled, onClick, tip, color)
		local r = sf.checks[i]
		r.psOn, r.psClick, r.psTip = enabled, onClick, tip
		r.Label:SetText(label)
		W.Color(r.Label, enabled and (color or "text") or "textMuted")
		r.Box:SetChecked(checked and true or false)
		r.Box:SetAlpha(enabled and 1 or 0.45)
		r:Show()
	end
	-- Starts a paint: the column empty, the bar and checkboxes hidden.
	function sf.Begin()
		sf.c.Begin(0)
		sf.Prog:Hide()
		for _, r in ipairs(sf.checks) do r:Hide() end
	end
	function sf.Finish(empty)
		local c = sf.c
		if empty then c.text("note", "textDim", empty, 0) end
		c.End()
		W.SetScrollContent(sf, c.y + 24, sf:GetHeight())
	end
	return sf
end
ns.CharacterDetailView = detailView

---------------------------------------------------------------------------
-- Reputation: the chosen faction's standing, its bar and description, and
-- the stock checkboxes: At war, Inactive, Show as experience bar.

local function standingColor(reaction)
	local c = FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
	if c then return Theme.Legible(c.r, c.g, c.b) end
end

ns.CharacterPanes.reputation = { page = "ReputationFrame", label = REPUTATION or "Reputation", order = 1,
	build = function(holder) return detailView(holder, 3) end,
	paint = function(sf)
		sf.Begin()
		local i = C_Reputation.GetSelectedFaction()
		local d = i and i > 0 and C_Reputation.GetFactionDataByIndex(i)
		if not d or d.factionID and d.factionID <= 0 then
			sf.psTitle = REPUTATION or "Reputation"
			return sf.Finish("Choose a faction to see its details.")
		end
		local c = sf.c
		sf.psTitle = d.name
		local cr, cg, cb = standingColor(d.reaction)
		local standing = GetText("FACTION_STANDING_LABEL" .. d.reaction, UnitSex("player"))
		local span = d.nextReactionThreshold - d.currentReactionThreshold
		local line = c.text("label", "text", standing, 0)
		if cr then W.Uncolor(line); line:SetTextColor(cr, cg, cb, 1) end
		if span > 0 and d.reaction < (MAX_REPUTATION_REACTION or 8) then
			local pts = c.text("number", "textDim", ("%s / %s"):format(BreakUpLargeNumbers(d.currentStanding - d.currentReactionThreshold), BreakUpLargeNumbers(span)), 0)
			pts:ClearAllPoints()
			pts:SetPoint("TOPRIGHT", line, "TOPRIGHT", 0, 0)
			pts:SetJustifyH("RIGHT")
			c.y = c.y - math.ceil(pts:GetStringHeight())
		end
		sf.bar(span > 0 and (d.currentStanding - d.currentReactionThreshold) / span or 1, cr, cg, cb)
		if d.description and d.description ~= "" then c.text("body", "textDim", d.description, 14) end
		if C_Reputation.IsAccountWideReputation and d.factionID and C_Reputation.IsAccountWideReputation(d.factionID) then
			c.text("small", "success", REPUTATION_TOOLTIP_ACCOUNT_WIDE_LABEL or "Account-wide", 10)
		end
		local warOK = d.canToggleAtWar and not d.isHeader
		sf.check(1, AT_WAR or "At War", d.atWarWith, warOK, function() C_Reputation.ToggleFactionAtWar(i) end,
			REPUTATION_AT_WAR_DESCRIPTION or "At war: you attack its members on sight.", warOK and "danger")
		sf.check(2, MOVE_TO_INACTIVE or "Inactive", not C_Reputation.IsFactionActive(i), d.canSetInactive, function(on)
			local id = d.factionID
			C_Reputation.SetFactionActive(i, not on)
			-- The list moves it: keep it chosen where it went (ReselectFactionByID).
			for k = 1, C_Reputation.GetNumFactions() do
				local e = C_Reputation.GetFactionDataByIndex(k)
				if e and e.factionID == id then return C_Reputation.SetSelectedFaction(k) end
			end
		end, REPUTATION_MOVE_TO_INACTIVE or "Moves it to the Inactive group.")
		sf.check(3, SHOW_FACTION_ON_MAINSCREEN or "Show as Experience Bar", d.isWatched, true, function(on)
			C_Reputation.SetWatchedFactionByIndex(on and i or 0)
		end, REPUTATION_SHOW_AS_XP or "Shows it on your experience bar.")
		sf.Finish()
	end }

---------------------------------------------------------------------------
-- Currency: the chosen currency's amount, description and caps, and the
-- stock checkboxes: Unused (to the client's Unused group) and Show on
-- backpack. Moving a currency to another character of the account stays in
-- the game's window.

ns.CharacterPanes.currency = { page = "TokenFrame", label = CURRENCY or "Currency", order = 1,
	build = function(holder) return detailView(holder, 2) end,
	paint = function(sf)
		sf.Begin()
		local i, d = ns.CharacterCurrency()
		if not d then
			sf.psTitle = CURRENCY or "Currency"
			return sf.Finish("Choose a currency to see its details.")
		end
		local c = sf.c
		sf.psTitle = d.name
		local desc = d.currencyID and C_CurrencyInfo.GetCurrencyDescription and C_CurrencyInfo.GetCurrencyDescription(d.currencyID)
		if desc and desc ~= "" then c.text("body", "textDim", desc, 0) end
		c.pair("You have", BreakUpLargeNumbers(d.quantity))
		if (d.maxQuantity or 0) > 0 then c.pair(CURRENCY_DETAIL_TOTAL_CAP_LABEL or "Total maximum", BreakUpLargeNumbers(d.maxQuantity)) end
		if d.canEarnPerWeek and (d.maxWeeklyQuantity or 0) > 0 then
			c.pair(CURRENCY_DETAIL_WEEKLY_CAP_LABEL or "Weekly maximum",
				BreakUpLargeNumbers(d.quantityEarnedThisWeek or 0) .. " / " .. BreakUpLargeNumbers(d.maxWeeklyQuantity))
		end
		if d.isAccountTransferable then
			local lost = d.transferPercentage and (100 - d.transferPercentage) or 0
			if lost > 0 and CURRENCY_TRANSFER_LOSS then c.text("small", "textDim", CURRENCY_TRANSFER_LOSS:format(math.ceil(lost)), 10) end
			c.text("small", "textMuted", "Transfers between characters are in the game's Currency window.", 10)
		elseif d.isAccountWide then
			c.text("small", "success", ACCOUNT_LEVEL_CURRENCY or "Account-wide", 10)
		end
		if d.discovered ~= false then
			sf.check(1, UNUSED or "Unused", d.isTypeUnused, true, function(on) C_CurrencyInfo.SetCurrencyUnused(i, on) end,
				TOKEN_MOVE_TO_UNUSED or "Moves it to the Unused group.")
			sf.check(2, SHOW_ON_BACKPACK or "Show on Backpack", d.isShowInBackpack, true, function(on) C_CurrencyInfo.SetCurrencyBackpack(i, on) end,
				TOKEN_SHOW_ON_BACKPACK or "Shows it on your backpack.")
		end
		sf.Finish()
	end }

---------------------------------------------------------------------------
-- Honor: the stock PvP rank details (PVPRankDetailFrameMixin): what the
-- season's top rank takes, the season's progress against this week's cap,
-- how much the cap rose this week, and the next rank's rewards.

ns.CharacterPanes.honor = { page = "PVPRankFrame", label = PVP or "Honor", order = 1,
	build = function(holder) return detailView(holder, 0) end,
	paint = function(sf)
		sf.Begin()
		local F = ns.PVP_RANK_FACTION
		local info = C_MajorFactions and C_MajorFactions.GetMajorFactionProgressionInfo(F)
		if not info then
			sf.psTitle = PVP or "Honor"
			return sf.Finish(PVP_RANK_DETAIL_UNAVAILABLE or "No PvP rank this season.")
		end
		local c, total = sf.c, function(level) return C_MajorFactions.GetTotalReputationForRenownLevel(F, level or 0) or 0 end
		local rank, top = info.renownLevel or 0, info.maxLevel or 0
		local cap = total(info.currentWeekProgressiveMaxLevel)
		local rise = cap - total(info.previousWeekProgressiveMaxLevel)
		local mine = total(rank) + (info.renownReputationEarned or 0)
		sf.psTitle = ns.PvPRankTitle(rank)
		if rank > 0 then c.text("label", "textDim", (PVP_RANK_NUMBER or "Rank %d"):format(rank), 0) end
		if PVP_RANK_SEASON_RANKUP_DESCRIPTION then
			c.text("body", "textDim", PVP_RANK_SEASON_RANKUP_DESCRIPTION:format(total(top), top), 10)
		end
		if mine > 0 and cap == 0 then
			c.text("body", "text", (PVP_RANK_SEASON_PROGRESS_NO_MAX or "Season progress: %d"):format(mine), 14)
		elseif mine > 0 then
			c.text("body", "text", (PVP_RANK_SEASON_PROGRESS or "Season progress: %d / %d"):format(mine, cap), 14)
		end
		if rise > 0 then c.text("body", "textDim", (PVP_RANK_WEEKLY_CAP_INCREASE or "This week's cap rose by %d."):format(rise), 6) end
		-- The next rank with rewards, and what it gives.
		for level = rank + 1, top do
			local rewards = C_MajorFactions.GetRenownRewardsForLevel(F, level)
			if rewards and #rewards > 0 then
				c.head((PVP_RANK_NEXT_REWARD or "Rank %d rewards"):format(level))
				for _, r in ipairs(rewards) do
					if r.description then c.tile(nil, nil, nil, r.description, r.icon) end
				end
				local horde = UnitFactionGroup("player") == "Horde"
				c.text("small", "textDim", horde and PVP_RANK_REWARDS_VENDOR_HORDE or PVP_RANK_REWARDS_VENDOR_ALLIANCE or "", 10)
				break
			end
		end
		sf.Finish()
	end }
