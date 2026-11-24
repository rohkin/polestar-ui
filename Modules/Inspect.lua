-- The Inspect window (docs/windows/inspect.md): the stock InspectFrame
-- (Camelot Blizzard_InspectUI) in a Polestar shell: another player's gear,
-- PvP rank and guild, shaped as the Character window.

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local NAME = "PolestarUIInspect"
local clean = ns.Clean
-- The stock mode tabs (INSPECTFRAME_SUBFRAMES), in stock order, as top tabs
-- (ns.TopNav) with each tab's own icon (Camelot Blizzard_InspectUI.lua): the
-- unit's portrait (painted over the stand-in), its faction's honor icon, the
-- guild tabard.
local SECTIONS = {
	{ key = "gear", label = CHARACTER or "Character", icon = "Interface/ICONS/INV_Misc_QuestionMark" },
	{ key = "pvp", label = PVP or "PvP" },
	{ key = "guild", label = GUILD or "Guild", icon = "Interface/ICONS/INV_Shirt_GuildTabard_01" },
}
local f, section = nil, "gear"
-- unit: the one shown; pending: asked for (NotifyInspect), shown on INSPECT_READY;
-- keep: ours closes for the next unit, whose request must not be cleared.
local unit, pending, keep
local M = { reloadOff = true }
local pages = {}

local function guildOf(u)
	local _, members, name = C_PaperDollInfo.GetInspectGuildInfo(u)
	name = clean(name)
	if name and name ~= "" then return name, clean(members) end
end

---------------------------------------------------------------------------
-- Gear: the Character window's slot columns and model well, read off the
-- inspected unit; a slot only shows (no pick up, use or flyout), as the stock one.

local SLOT, GAP, TEXT_W, TOP = 36, 6, 220, 20
local LEFT = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
local RIGHT = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" }
local WEAPONS = { { "MainHandSlot", "right" }, { "SecondaryHandSlot", "below" }, { "RangedSlot", "left" } }
local slots = {}

-- The worn item's permanent enchant, its tooltip line without "Enchanted: ".
local ENCHANT_LINE = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent or 15
local function enchantText(id)
	local data = C_TooltipInfo and C_TooltipInfo.GetInventoryItem(unit, id)
	for _, line in ipairs(data and data.lines or {}) do
		local text = line.type == ENCHANT_LINE and clean(line.leftText)
		if text then
			local pre = ENCHANTED_TOOLTIP_LINE and ENCHANTED_TOOLTIP_LINE:match("^(.-)%%s")
			if pre and pre ~= "" and text:sub(1, #pre) == pre then text = text:sub(#pre + 1) end
			return text
		end
	end
end

local EMPTY_SOCKET, GEM = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic", 12
local function paintGems(s, link)
	local n = link and C_Item.GetItemNumSockets and C_Item.GetItemNumSockets(link) or 0
	for i = 1, n do
		local g = s.psGems[i]
		if not g then
			g = ns.ItemWell(s, GEM)
			g:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 2 + (i - 1) * (GEM + 1), 2)
			s.psGems[i] = g
		end
		local gem = C_Item.GetItemGemID(link, i)
		g.Icon:SetTexture(gem and C_Item.GetItemIconByID(gem) or EMPTY_SOCKET)
		g:Show()
	end
	for i = n + 1, #s.psGems do s.psGems[i]:Hide() end
end

-- Every value read through ns.Clean: in combat the client may hand them over
-- secret (docs/CLIENT.md, rule 3); a secret one paints as empty.
local function paintSlot(s)
	local id = s:GetID()
	local icon = clean(GetInventoryItemTexture(unit, id))
	local q = icon and clean(GetInventoryItemQuality(unit, id))
	ns.PaintItem(s, icon and { icon = icon, quality = q, count = clean(GetInventoryItemCount(unit, id)) })
	if not icon then
		s.Icon:SetTexture(s.psEmpty)
		s.Icon:SetDesaturated(true)
		s.Icon:SetVertexColor(Theme.Color("textMuted"))
	end
	s.Icon:SetAlpha(icon and 1 or 0.6)
	local link = icon and clean(GetInventoryItemLink(unit, id))
	paintGems(s, link)
	local name = link and link:match("%[(.-)%]")
	s.psName:SetText(name or s.psLabel)
	local r, g, b = ns.QualityRGB(q or 1)
	if name and r then s.psName:SetTextColor(r, g, b) else W.Color(s.psName, name and "text" or "textMuted") end
	local ench = link and enchantText(id)
	s.psEnchant:SetText(ench or "")
	local p, rel, x = unpack(s.psSide)
	if p ~= "TOP" then s.psName:SetPoint(p, s, rel, x, ench and 8 or 0) end
end

local function slotEnter(s)
	GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
	if unit and GameTooltip:SetInventoryItem(unit, s:GetID()) then
		ns.TooltipHint("Shift-click to link it in chat. Ctrl-click to try it on.")
	else
		GameTooltip:SetText(s.psLabel)
	end
	GameTooltip:Show()
	if CursorUpdate then CursorUpdate(s) end
end

local function newSlot(parent, name, layer, side)
	local id, empty = C_PaperDollInfo.GetInventorySlotInfo(name)
	local s = ns.ItemWell(parent, SLOT, "Button")
	s:SetID(id)
	s.psEmpty, s.psLabel, s.psGems = empty, _G[name:upper()] or name, {}
	W.Hover(s)
	s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	-- As the stock slot: the client's linking and try-on.
	s:SetScript("OnClick", function(self)
		local link = unit and GetInventoryItemLink(unit, self:GetID())
		if link then HandleModifiedItemClick(link) end
	end)
	s:SetScript("OnEnter", slotEnter)
	s:SetScript("OnLeave", function()
		W.HideTooltip()
		if ResetCursor then ResetCursor() end
	end)
	-- As the stock slot's OnUpdate: a modifier pressed shows the comparison.
	s:SetScript("OnUpdate", function(self)
		if GameTooltip:GetOwner() ~= self then return end
		slotEnter(self)
		if CursorOnUpdate then CursorOnUpdate(self) end
	end)
	local p, rel, x = "LEFT", "RIGHT", 8
	if side == "right" then p, rel, x = "RIGHT", "LEFT", -8 end
	if side == "below" then p, rel, x = "TOP", "BOTTOM", 0 end
	s.psSide = { p, rel, x }
	s.psName = W.Text(layer, "label", "text")
	s.psName:SetPoint(p, s, rel, x, p == "TOP" and -4 or 0)
	s.psEnchant = W.Text(layer, "small", "success")
	s.psEnchant:SetPoint("TOP", s.psName, "BOTTOM", 0, -2)
	for _, t in ipairs({ s.psName, s.psEnchant }) do
		t:SetWidth(TEXT_W)
		t:SetJustifyH(p == "TOP" and "CENTER" or p)
	end
	slots[#slots + 1] = s
	return s
end

-- The stock frame's stand-in when the model cannot draw (out of range).
local FACTION_LOGO = { Alliance = "Interface\\Timer\\Alliance-Logo", Horde = "Interface\\Timer\\Horde-Logo", Neutral = "Interface\\Timer\\Panda-Logo" }

pages.gear = {
	build = function(body, width, pad)
		local colH = #LEFT * (SLOT + GAP) - GAP
		local v = CreateFrame("Frame", nil, body)
		v:SetPoint("TOPLEFT", body, "TOPLEFT", pad, -TOP)
		v:SetSize(width, colH + 16 + SLOT + 36)
		local text = CreateFrame("Frame", nil, v)
		text:SetAllPoints(v)
		for i, name in ipairs(LEFT) do newSlot(v, name, text, "left"):SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(i - 1) * (SLOT + GAP)) end
		for i, name in ipairs(RIGHT) do newSlot(v, name, text, "right"):SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -(i - 1) * (SLOT + GAP)) end
		local row = #WEAPONS * (SLOT + GAP) - GAP
		for i, w in ipairs(WEAPONS) do
			newSlot(v, w[1], text, w[2]):SetPoint("TOPLEFT", v, "TOP", -row / 2 + (i - 1) * (SLOT + GAP), -(colH + 16))
		end
		-- The model well (docs/DESIGN.md, "Model Well"), as the Character window's.
		local well = CreateFrame("Frame", nil, v)
		well:SetPoint("TOPLEFT", v, "TOPLEFT", SLOT + 16, 0)
		well:SetPoint("BOTTOMRIGHT", v, "TOPRIGHT", -(SLOT + 16), -colH)
		local shade = W.Tex(well, "BACKGROUND", "glow")
		shade:SetAllPoints(well)
		W.Painter(shade, function(t) local r, g, b = Theme.Color("shade"); t:SetVertexColor(r, g, b, 0.6) end)
		-- The stock inspect model is a PlayerModel set to the unit (SetUnit);
		-- ours, without the stock control buttons: drag turns, the wheel zooms.
		local m = CreateFrame("PlayerModel", nil, well, "ModelWithZoomTemplate")
		m:SetPoint("TOPLEFT", 1, -1)
		m:SetPoint("BOTTOMRIGHT", -1, 1)
		m:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(f.psName or "")
			ns.TooltipHint("Drag to turn, scroll to zoom.")
			GameTooltip:Show()
		end)
		m:HookScript("OnLeave", W.HideTooltip)
		v.Logo = well:CreateTexture(nil, "ARTWORK")
		v.Logo:SetSize(128, 128)
		v.Logo:SetPoint("CENTER")
		text:SetFrameLevel(m:GetFrameLevel() + 10)
		v.Model = m
		return v
	end,
	paint = function(v)
		for _, s in ipairs(slots) do paintSlot(s) end
		return TOP + v:GetHeight()
	end,
}

-- The unit in the well, or its faction's logo when the model cannot draw.
local function showModel()
	local v = f.psPages.gear
	local drawn = v.Model:SetUnit(unit)
	local logo = drawn ~= true and FACTION_LOGO[clean(UnitFactionGroup(unit)) or ""]
	v.Model:SetShown(not logo)
	v.Logo:SetShown(logo and true or false)
	if logo then v.Logo:SetTexture(logo) end
end

---------------------------------------------------------------------------
-- PvP: the inspected rank (GetInspectHonorData), as the stock InspectPVPFrame.

local function rankTitle(rank)
	if not rank or rank <= 0 then return PVP_RANK_0_NAME or "Unranked" end
	local alliance = clean(UnitFactionGroup(unit)) == "Alliance" and 1 or 0
	return GetText("PVP_RANK_" .. (Enum.PvPRanks.Rank_1 + rank - 1) .. "_" .. alliance, UnitSex(unit))
end

pages.pvp = {
	build = function(body, width, pad)
		local v = CreateFrame("Frame", nil, body)
		v:SetPoint("TOPLEFT", body, "TOPLEFT", pad, -TOP)
		v:SetSize(width, 1)
		v.Rank = W.Text(v, "display", "text")
		v.Rank:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
		v.Season = W.Text(v, "small", "textDim")
		v.Season:SetPoint("TOPLEFT", v.Rank, "BOTTOMLEFT", 0, -6)
		v.Points = W.Text(v, "number", "textDim")
		v.Points:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -50)
		v.Bar = W.ProgressLine(v, 3)
		v.Bar:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -68)
		v.Bar:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -68)
		v.Head = W.SectionHeader(v)
		v.Head:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -96)
		v.Head:SetPoint("RIGHT", v, "RIGHT", 0, 0)
		W.SetSection(v.Head, HONORABLE_KILLS or "Honorable Kills")
		v.Panel = W.RowPanel(v)
		v.Panel:SetPoint("TOPLEFT", v.Head, "BOTTOMLEFT", 0, 0)
		v.Panel:SetPoint("RIGHT", v, "RIGHT", 0, 0)
		v.Panel:SetHeight(56)
		v.Rows = {}
		for i, label in ipairs({ HONOR_LIFETIME or "Lifetime", HONOR_TODAY or "Today" }) do
			local r = CreateFrame("Frame", nil, v.Panel)
			r:SetHeight(28)
			r:SetPoint("TOPLEFT", v.Panel, "TOPLEFT", 0, -(i - 1) * 28)
			r:SetPoint("RIGHT", v.Panel, "RIGHT", 0, 0)
			if i > 1 then
				local d = W.Divider(r)
				d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
				d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
			end
			r.Label = W.Text(r, "label", "textDim")
			r.Label:SetPoint("LEFT", r, "LEFT", 16, 0)
			r.Label:SetText(label)
			r.Value = W.Text(r, "number", "text")
			r.Value:SetPoint("RIGHT", r, "RIGHT", -12, 0)
			v.Rows[i] = r
		end
		return v
	end,
	paint = function(v)
		local today, _, _, _, lifetime, _, rank, cur, nxt = GetInspectHonorData()
		today, lifetime, rank, cur, nxt = ns.Num(today), ns.Num(lifetime), ns.Num(rank), ns.Num(cur), ns.Num(nxt)
		v.Rank:SetText(rank > 0 and ("%s · %s"):format(rankTitle(rank), (PVP_RANK_NUMBER or "Rank %d"):format(rank)) or rankTitle(rank))
		local season = GetCurrentArenaSeason and GetCurrentArenaSeason() or 0
		v.Season:SetText(season > 0 and (EXPANSION_SEASON_NAME or "%sSeason %d"):format("", season) or "")
		v.Points:SetText(PVP_RANK_CURRENT_PROGRESS and PVP_RANK_CURRENT_PROGRESS:format(cur, nxt)
			or ("%s / %s"):format(BreakUpLargeNumbers(cur), BreakUpLargeNumbers(nxt)))
		W.SetProgress(v.Bar, nxt > 0 and math.min(1, cur / nxt) or 0, v:GetWidth())
		v.Rows[1].Value:SetText(BreakUpLargeNumbers(lifetime))
		v.Rows[2].Value:SetText(BreakUpLargeNumbers(today))
		return TOP + 96 + 44 + 56
	end,
}

---------------------------------------------------------------------------
-- Guild: the stock InspectGuildFrame: the guild's tabard emblem, name,
-- faction and member count.

pages.guild = {
	build = function(body, width, pad)
		local v = CreateFrame("Frame", nil, body)
		v:SetPoint("TOPLEFT", body, "TOPLEFT", pad, -TOP)
		v:SetSize(width, 72)
		v.Well = ns.ItemWell(v, 72)
		v.Well:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
		v.Emblem = v.Well:CreateTexture(nil, "ARTWORK")
		v.Emblem:SetSize(56, 56)
		v.Emblem:SetPoint("CENTER")
		v.Name = W.Text(v, "display", "text")
		v.Name:SetPoint("TOPLEFT", v.Well, "TOPRIGHT", 16, -4)
		v.Name:SetPoint("RIGHT", v, "RIGHT", 0, 0)
		v.Faction = W.Text(v, "body", "textDim")
		v.Faction:SetPoint("TOPLEFT", v.Name, "BOTTOMLEFT", 0, -6)
		v.Members = W.Text(v, "body", "textDim")
		v.Members:SetPoint("TOPLEFT", v.Faction, "BOTTOMLEFT", 0, -4)
		return v
	end,
	paint = function(v)
		local name, members = guildOf(unit)
		local _, faction = UnitFactionGroup(unit)
		faction = clean(faction)
		v.Name:SetText(name or "")
		v.Faction:SetText(faction and members and (INSPECT_GUILD_FACTION or "%s Guild"):format(faction) or "")
		v.Members:SetText(faction and members and (INSPECT_GUILD_NUM_MEMBERS or "%d Members"):format(members) or "")
		-- The stock emblem helper, on our texture; stock code runs only out of combat (rule 3).
		if not InCombatLockdown() and SetLargeGuildTabardTextures then
			v.Emblem:SetSize(56, 56)
			SetLargeGuildTabardTextures(unit, v.Emblem)
		end
		return TOP + 72
	end,
}

---------------------------------------------------------------------------
-- The window.

-- "Level 60 Warrior", as the stock sheet writes it (InspectPaperDollFrameMixin:SetLevel):
-- "??" for a level hidden, the effective level beside a scaled one, the
-- specialization when it differs from the class; in the class colour.
local function levelLine()
	local class, token = UnitClass(unit)
	class, token = clean(class), clean(token)
	if not (class and token) then return "" end
	local level, eff = clean(UnitLevel(unit)), clean(UnitEffectiveLevel and UnitEffectiveLevel(unit))
	local lv = level or "??"
	if level == -1 or eff == -1 then
		lv = "??"
	elseif level and eff and eff ~= level then
		lv = (EFFECTIVE_LEVEL_FORMAT or "%d (%d)"):format(eff, level)
	end
	local color = ns.ClassText(token, ""):match("|c(%x+)") or "ffffffff" -- the format globals take the colour code
	local spec = C_SpecializationInfo and C_SpecializationInfo.GetInspectSpecialization and clean(C_SpecializationInfo.GetInspectSpecialization(unit))
	local specName = spec and spec ~= 0 and GetSpecializationInfoByID and clean((select(2, GetSpecializationInfoByID(spec, UnitSex(unit)))))
	if specName and specName ~= "" and specName ~= class then
		return (PLAYER_LEVEL or "Level %s |c%s%s %s|r"):format(lv, color, specName, class)
	end
	return (PLAYER_LEVEL_NO_SPEC or "Level %s |c%s%s|r"):format(lv, color, class)
end

local function portrait()
	local t = f.tabButtons[1].psNavIcon
	SetPortraitTexture(t, unit)
	t:SetTexCoord(0.03125, 0.96875, 0.03125, 0.96875)
end

local function build()
	-- The compact grid, no sidebar: the stock tabs are top tabs, the window as
	-- wide as the gear's columns and weapon row need.
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 640, height = 540 })
	ns.Dock(f)
	ns.WindowMenu(f, "inspect")
	f.Search:Hide()
	ns.Plain(f) -- before the grid: BodyWidth is the compact one
	ns.Compact(f)
	f.psPages = {}
	for key, page in pairs(pages) do
		local v = page.build(f.Body, f.BodyWidth, f.psPad)
		v:Hide()
		f.psPages[key] = v
	end
	-- Closed, the client forgets the inspected player, as the stock OnHide,
	-- unless the talents window inspects them too.
	f:HookScript("OnHide", function()
		if not keep and not (PlayerSpellsFrame and PlayerSpellsFrame.IsInspecting and PlayerSpellsFrame:IsInspecting()) then
			ClearInspectPlayer()
		end
		unit = nil
	end)
	Polestar.CloseOnEscape(NAME)
end

local function refresh()
	-- The Guild tab only for a unit in a guild, as the stock UpdateTabs.
	local items = { SECTIONS[1], SECTIONS[2] }
	if guildOf(unit) then items[3] = SECTIONS[3] elseif section == "guild" then section = "gear" end
	SECTIONS[2].icon = clean(UnitFactionGroup(unit)) == "Alliance" and "Interface/ICONS/INV_SideTab_Honor_Alliance_c60"
		or "Interface/ICONS/INV_SideTab_Honor_Horde_c60"
	ns.TopNav(f, items, section, function(k)
		section = k
		refresh()
	end)
	portrait()
	-- The stock title (GetUnitName with the realm); a secret one keeps the last.
	f.psName = clean(GetUnitName(unit, true)) or f.psName
	W.ShellTitle(f, f.psName or "", levelLine())
	ns.Footer(f, {}, {})
	local h = 0
	for key, v in pairs(f.psPages) do
		v:SetShown(key == section)
		if key == section then h = pages[key].paint(v) end
	end
	W.ShellBody(f, h)
end

-- Opens ours on the inspected unit (its data in: INSPECT_READY).
function M.Show(u)
	unit = u or unit
	if not unit then return end
	if not f then build() end
	-- A new unit: no name kept from the last one.
	if u then f.psName = nil end
	refresh()
	showModel()
	f:Show()
end

local function shown() return f and f:IsShown() and unit end

function M.Enable()
	-- The stock InspectFrame shows itself on INSPECT_READY (ShowUIPanel in
	-- its OnEvent); hidden by us, its OnHide would clear the inspect data
	-- ours shows. So its open is stopped as the quest dialog's and loot's
	-- (docs/CLIENT.md, rule 15's exception): that one event unregistered on
	-- that one frame, once the load-on-demand Blizzard_InspectUI has made it.
	local function stopStock() if InspectFrame then InspectFrame:UnregisterEvent("INSPECT_READY") end end
	stopStock()
	Polestar.RegisterEvent("ADDON_LOADED", function(_, name) if name == "Blizzard_InspectUI" then stopStock() end end)
	-- Every door (the unit menu's Inspect, /inspect, other addons) calls
	-- InspectUnit, whose InspectFrame_Show has asked the server
	-- (NotifyInspect) when the unit can be inspected. Ours waits for the data.
	-- (Blizzard_InspectUI's bootstrap defines it; preview scenes without it: no door.)
	if not InspectUnit then return end
	hooksecurefunc("InspectUnit", function(u)
		local can = u and CanInspect(u) and true or nil
		if shown() then
			-- As the stock HideUIPanel first; the new request is not cleared.
			keep = can
			f:Hide()
			keep = nil
		end
		pending, section = can and u or nil, "gear"
	end)
	Polestar.RegisterEvent("INSPECT_READY", function(_, guid)
		guid = clean(guid)
		if pending and guid and clean(UnitGUID(pending)) == guid then
			local u = pending
			pending = nil
			M.Show(u)
		elseif shown() and guid and clean(UnitGUID(unit)) == guid then
			refresh()
		end
	end)
	-- As the stock frame: a new target closes a target's inspect, a roster
	-- change any other (the server drops data asked for too fast).
	Polestar.RegisterEvent("PLAYER_TARGET_CHANGED", function() if shown() and unit == "target" then f:Hide() end end)
	Polestar.RegisterEvent("GROUP_ROSTER_UPDATE", function() if shown() and unit ~= "target" then f:Hide() end end)
	local function ofUnit(fn) return function(_, u) if shown() and u == unit then fn() end end end
	for _, e in ipairs({ "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_INVENTORY_CHANGED" }) do Polestar.RegisterEvent(e, ofUnit(refresh)) end
	Polestar.RegisterEvent("UNIT_PORTRAIT_UPDATE", ofUnit(portrait))
	Polestar.RegisterEvent("PORTRAITS_UPDATED", function() if shown() then portrait() end end)
	Polestar.RegisterEvent("UNIT_MODEL_CHANGED", ofUnit(function() f.psPages.gear.Model:RefreshUnit() end))
	Polestar.RegisterEvent("INSPECT_HONOR_UPDATE", function() if shown() and section == "pvp" then refresh() end end)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return InspectFrame and InspectFrame:IsShown() and InspectFrame end

ns.Module("inspect", M)
