-- The Character window (docs/DESIGN.md, "Character"): the stock CharacterFrame's
-- sections in a Polestar shell. 4a: the shell, its sections and the doors in.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUICharacter"
-- The stock subframes, in stock order; their keys are what ToggleCharacter takes.
local SECTIONS = {
	{ key = "PaperDollFrame", label = CHARACTER or "Character", icon = "icon-level" },
	{ key = "ReputationFrame", label = REPUTATION or "Reputation", icon = "icon-rep" },
	{ key = "TokenFrame", label = CURRENCY or "Currency", icon = "qol-coin" },
	{ key = "PVPRankFrame", label = PVP or "Honor", icon = "flag" },
	{ key = "SkillsFrame", label = SKILLS or "Skills", icon = "icon-skill" },
}
local TABS = { { key = "gear", label = "Gear" }, { key = "stats", label = "Stats" } }

local f, section, tab = nil, "PaperDollFrame", "gear"
local M = {}

---------------------------------------------------------------------------
-- Gear: the slot tiles (docs/DESIGN.md, "Slot Tile"), in the stock columns.

local SLOT, GAP = 40, 6
local LEFT = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
local RIGHT = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" }
local WEAPONS = { "MainHandSlot", "SecondaryHandSlot", "RangedSlot", "AmmoSlot" }
local slots = {}

local function qualityRGB(q)
	if C_Item and C_Item.GetItemQualityColor then
		local ok, r, g, b = pcall(C_Item.GetItemQualityColor, q)
		if ok and type(r) == "number" then return r, g, b end
	end
	local t = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	if t then return t.r, t.g, t.b end
end

local function paintSlot(s)
	local id = s:GetID()
	local icon = GetInventoryItemTexture("player", id)
	s.Icon:SetTexture(icon or s.psEmpty)
	s.Icon:SetDesaturated(not icon)
	s.Icon:SetAlpha(icon and 1 or 0.6)
	local cur, max = GetInventoryItemDurability(id)
	local broken = icon and GetInventoryItemBroken("player", id)
	local r, g, b, a
	if broken or (cur and max and max > 0 and cur == 0) then
		r, g, b = Polestar.Theme.Color("danger"); a = 1
	elseif cur and max and max > 0 and cur / max < 0.25 then
		r, g, b = Polestar.Theme.Color("warning"); a = 1
	else
		local q = icon and GetInventoryItemQuality("player", id)
		-- Common and poor items wear the hairline, as an empty slot does.
		if q and q >= 2 then r, g, b = qualityRGB(q); a = 0.9 end
	end
	if not r then r, g, b, a = Polestar.Theme.Wash("border") end
	Polestar.Theme.Border(s, r, g, b, a)
end

local function slotEnter(s)
	GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
	if GameTooltip:SetInventoryItem("player", s:GetID()) then
		ns.TooltipHint("Drag to take it off. Shift-click to link it in chat.")
	else
		GameTooltip:SetText(s.psLabel)
		ns.TooltipHint("Drag an item here to equip it.")
	end
	GameTooltip:Show()
end

-- Left: pick up or put down (the stock slot's own call, unprotected); with a
-- modifier, the client's linking and try-on handling.
-- shortcut: right-click "use" is left out (UseInventoryItem is protected); add a secure item button when needed.
local function slotClick(s, button)
	local link = GetInventoryItemLink("player", s:GetID())
	if link and IsModifiedClick() and HandleModifiedItemClick(link) then return end
	if button == "LeftButton" then PickupInventoryItem(s:GetID()) end
end

local function newSlot(parent, name)
	local id, empty = C_PaperDollInfo.GetInventorySlotInfo(name)
	local s = CreateFrame("Button", nil, parent)
	s:SetID(id)
	s:SetSize(SLOT, SLOT)
	s.psEmpty = empty
	s.psLabel = _G[name:upper()] or name
	W.Fill(s, "scrim", "BACKGROUND", 0)
	s.Icon = s:CreateTexture(nil, "ARTWORK")
	s.Icon:SetPoint("TOPLEFT", 1, -1)
	s.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	W.Hover(s)
	s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	s:RegisterForDrag("LeftButton")
	s:SetScript("OnClick", slotClick)
	s:SetScript("OnDragStart", function(self) PickupInventoryItem(self:GetID()) end)
	s:SetScript("OnReceiveDrag", function(self) PickupInventoryItem(self:GetID()) end)
	s:SetScript("OnEnter", slotEnter)
	s:SetScript("OnLeave", W.HideTooltip)
	slots[#slots + 1] = s
	return s
end

-- The two columns on the body's edges, the weapons centred under them.
local function buildGear(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", 32, -24)
	v:SetSize(width, #LEFT * (SLOT + GAP) - GAP + 16 + SLOT)
	for i, name in ipairs(LEFT) do newSlot(v, name):SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(i - 1) * (SLOT + GAP)) end
	for i, name in ipairs(RIGHT) do newSlot(v, name):SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -(i - 1) * (SLOT + GAP)) end
	local row = #WEAPONS * (SLOT + GAP) - GAP
	for i, name in ipairs(WEAPONS) do
		newSlot(v, name):SetPoint("BOTTOMLEFT", v, "BOTTOM", -row / 2 + (i - 1) * (SLOT + GAP), 0)
	end
	-- The model well between the columns (docs/DESIGN.md, "Model Well").
	local well = CreateFrame("Frame", nil, v)
	well:SetPoint("TOPLEFT", v, "TOPLEFT", SLOT + 16, 0)
	well:SetPoint("BOTTOMRIGHT", v, "TOPRIGHT", -(SLOT + 16), -(#LEFT * (SLOT + GAP) - GAP))
	Polestar.Theme.Skin(well, "inset")
	Polestar.Theme.Border(well, Polestar.Theme.Wash("border"))
	-- The game's own character-sheet scene: its camera frames every race and
	-- form, and the template turns, zooms and pans it. Our frame, their template.
	local m = CreateFrame("ModelScene", nil, well, "PanningModelSceneMixinTemplate")
	m:SetPoint("TOPLEFT", 1, -1)
	m:SetPoint("BOTTOMRIGHT", -1, 1)
	-- Hooked: the template has its own mouse scripts.
	m:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(UnitName("player"))
		ns.TooltipHint("Drag to turn, scroll to zoom, right-drag to move.")
		GameTooltip:Show()
	end)
	m:HookScript("OnLeave", W.HideTooltip)
	v.Model = m
	return v
end

-- The scene's camera is tuned for the stock sheet's tall, narrow well; ours is
-- wider and shorter, so the camera starts further back and may zoom out further.
-- shortcut: one factor for every race (a troll fits at 1.35); derive it from the well's aspect if a race still clips.
local BACK_OFF, ZOOM_OUT = 1.35, 2

local function showModel()
	local scene = f.psGear.Model
	ModelSceneUtil.SetUpCharacterSheetScene(scene)
	local cam = scene.GetActiveCamera and scene:GetActiveCamera()
	if cam and cam.GetMaxZoomDistance and cam:GetMaxZoomDistance() then
		local d = cam:GetZoomDistance()
		cam:SetMaxZoomDistance(cam:GetMaxZoomDistance() * ZOOM_OUT)
		cam:SetZoomDistance(d * BACK_OFF)
	end
end

local function paintGear()
	for _, s in ipairs(slots) do paintSlot(s) end
end

---------------------------------------------------------------------------
-- Stats: the stock categories (PAPERDOLL_STATCATEGORIES), each a heading over
-- a row panel (docs/DESIGN.md, "Stat Row"), flowed into two columns. The
-- numbers and tooltips are the stock sheet's own: each row is handed to
-- PAPERDOLL_STATINFO[stat].updateFunc, which fills Label, Value and tooltip.

local STAT_H, HEAD_H, SECTION_GAP, COL_GAP = 28, 44, 22, 24

-- Archetypes: the player's choice (per character) of which stats matter. The
-- layout never moves: `key` stats read in text, the rest in textMuted.
local ARCHETYPES = {
	{ id = "melee", label = "Melee",
		key = { STRENGTH = true, AGILITY = true, MAINHAND_DAMAGE = true, OFFHAND_DAMAGE = true, RANGED_DAMAGE = true,
			ATTACK_AP = true, RANGED_ATTACK_AP = true, HITCHANCE = true, CRITCHANCE = true, HASTE = true, EXPERTISE = true, ARMORPEN = true } },
	{ id = "caster", label = "Caster",
		key = { INTELLECT = true, SPIRIT = true, POWER = true, MANAREGEN = true, SPELLPOWER = true, SPELLHEALING = true,
			SPELLPENETRATION = true, HITCHANCE = true, CRITCHANCE = true, HASTE = true } },
	{ id = "tank", label = "Tank",
		key = { STAMINA = true, HEALTH = true, DEFENSE = true, DODGE = true, PARRY = true, BLOCK = true, ARMOR = true } },
}
local BY_ID = {}
for _, a in ipairs(ARCHETYPES) do BY_ID[a.id] = a end
-- The starting choice by class, until the player picks one.
local CASTERS = { MAGE = true, WARLOCK = true, PRIEST = true, DRUID = true, SHAMAN = true }

local function archetype()
	local id = PolestarUICharDB and PolestarUICharDB.archetype
	if not BY_ID[id] then
		local _, class = UnitClass("player")
		id = CASTERS[class] and "caster" or "melee"
	end
	return BY_ID[id]
end

local function statEnter(r)
	if r.onEnterFunc then r.onEnterFunc(r) else PaperDollStatTooltip(r) end
end

local function statRow(s, i)
	local r = s.rows[i]
	if r then return r end
	r = CreateFrame("Button", nil, s.Panel)
	r:SetHeight(STAT_H)
	r:SetPoint("TOPLEFT", s.Panel, "TOPLEFT", 0, -(i - 1) * STAT_H)
	r:SetPoint("RIGHT", s.Panel, "RIGHT", 0, 0)
	r.Label = W.Text(r, "label", "textDim")
	r.Label:SetPoint("LEFT", r, "LEFT", 16, 0)
	r.Value = W.Text(r, "number", "text")
	r.Value:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	if i > 1 then
		local d = W.Divider(r)
		d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
		d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
	end
	W.Hover(r)
	r:SetScript("OnEnter", statEnter)
	r:SetScript("OnLeave", W.HideTooltip)
	s.rows[i] = r
	return r
end

-- The last values each stock stat function gave, by function. In combat the
-- client makes many stats secret: the stock functions, called from our
-- (tainted) code, error on them or write secret text into our strings. So in
-- combat they are not run at all; each stat shows what it last read, and the
-- page reads them again when combat ends (PLAYER_REGEN_ENABLED).
local lastRead = {}
local secret = issecretvalue or function() return false end

-- Runs one stock stat function on row r; true when the stat is to be shown.
local function fill(r, fn, hideAt)
	r.onEnterFunc, r.UpdateTooltip, r.tooltip, r.tooltip2, r.tooltip3, r.numericValue = nil
	r:Show()
	if InCombatLockdown() or not pcall(fn, r, "player") or secret(r.numericValue) then
		local last = lastRead[fn]
		if not last then return false end
		r.Label:SetText(last[1])
		r.Value:SetText(last[2])
		r.numericValue, r.tooltip, r.tooltip2 = last[3], last[4], last[5]
		return true
	end
	-- The stock label ends in STAT_FORMAT's colon; a row label here has none.
	r.Label:SetText((r.Label:GetText() or ""):gsub("%s*:%s*$", ""))
	lastRead[fn] = { r.Label:GetText(), r.Value:GetText(), r.numericValue, r.tooltip, r.tooltip2 }
	return r:IsShown() and (hideAt == nil or hideAt ~= r.numericValue)
end

-- { name, { { fn, hideAt, key }, ... } } for the player's categories, in the
-- stock order.
local function statCategories(arch)
	local cats = {}
	for _, c in ipairs(PAPERDOLL_STATCATEGORIES or {}) do
		if (c.unit or "player") == "player" then
			local list = {}
			for _, st in ipairs(c.stats) do
				local info = PAPERDOLL_STATINFO[st.stat]
				if info and (not st.showFunc or st.showFunc()) then
					list[#list + 1] = { info.updateFunc, st.hideAt, arch.key[st.stat] or false }
				end
			end
			cats[#cats + 1] = { c.categoryName, list }
		end
	end
	return cats
end

-- The item level the stock sheet shows (PaperDollFrame_SetItemLevel's own
-- sum), from its level on; nil below it.
local function itemLevel()
	if UnitLevel("player") < (MIN_PLAYER_LEVEL_FOR_ITEM_LEVEL_DISPLAY or 10) then return nil end
	local _, equipped = GetAverageItemLevel()
	return math.floor(math.max(C_PaperDollInfo.GetMinItemLevel() or 0, equipped or 0))
end

local function buildStats(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", 32, 0)
	v:SetWidth(width)
	v.colW = (width - COL_GAP) / 2
	v.sections = {}
	return v
end

-- Lays the categories out, each in the shorter column; returns the height.
local function paintStats()
	local v = f.psStats
	local colH = { 0, 0 }
	local arch = archetype()
	for _, b in ipairs(v.segments) do
		local on = b.psKey == arch.id
		b.Selected:SetShown(on)
		W.Color(b.Label, on and "text" or "textMuted")
	end
	local cats = statCategories(arch)
	for i, cat in ipairs(cats) do
		local s = v.sections[i]
		if not s then
			s = { Head = W.SectionHeader(v), Panel = W.RowPanel(v), rows = {} }
			s.Head:SetWidth(v.colW)
			s.Panel:SetWidth(v.colW)
			v.sections[i] = s
		end
		local n = 0
		for _, e in ipairs(cat[2]) do
			local r = statRow(s, n + 1)
			if fill(r, e[1], e[2]) then
				n = n + 1
				W.Color(r.Label, e[3] and "text" or "textMuted")
				W.Color(r.Value, e[3] and "text" or "textMuted")
			else
				r:Hide()
			end
		end
		for k = n + 1, #s.rows do s.rows[k]:Hide() end
		local shown = n > 0
		s.Head:SetShown(shown)
		s.Panel:SetShown(shown)
		if shown then
			local col = colH[1] <= colH[2] and 1 or 2
			local x, y = (col - 1) * (v.colW + COL_GAP), colH[col]
			W.SetSection(s.Head, cat[1])
			s.Head:SetPoint("TOPLEFT", v, "TOPLEFT", x, -y)
			s.Panel:SetPoint("TOPLEFT", v, "TOPLEFT", x, -(y + HEAD_H))
			s.Panel:SetHeight(n * STAT_H)
			colH[col] = y + HEAD_H + n * STAT_H + SECTION_GAP
		end
	end
	for i = #cats + 1, #v.sections do
		v.sections[i].Head:Hide()
		v.sections[i].Panel:Hide()
	end
	local h = math.max(colH[1], colH[2])
	v:SetHeight(h)
	return h
end

local function build()
	f = W.Shell(NAME, {})
	-- The subject block names the window, in place of Polestar's lockup.
	-- Reparented, not hidden: the shell re-shows its version line on every show.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Search, f.Status, f.Stage }) do r:SetParent(holder) end
	f.psName = W.Text(f.Sidebar, "title", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", 24, -47)
	f.psLine = W.Text(f.Sidebar, "small", "textDim")
	f.psLine:SetPoint("TOPLEFT", f.psName, "BOTTOMLEFT", 0, -6)
	f.psGear = buildGear(f.Body, f.BodyWidth)
	f.psStats = buildStats(f.Body, f.BodyWidth)
	-- The other sections' pages (CharacterPages.lua), each with the height it last drew.
	f.psPages = {}
	for key, page in pairs(ns.CharacterPages) do
		local v = page.build(f.Body, f.BodyWidth)
		v:Hide()
		v.psPaint, v.psH = page.paint, 0
		f.psPages[key] = v
	end
	-- The archetype as filter segments at the right of the tab row (as the
	-- guide picker's faction filter): its right edge mirrors the first tab.
	local segs, x = {}, -20
	for i = #ARCHETYPES, 1, -1 do
		local a = ARCHETYPES[i]
		local b = CreateFrame("Button", nil, f.TabRow)
		b:SetHeight(24)
		b.psKey = a.id
		W.Hover(b)
		b.Selected = W.Fill(b, "panelAlt", "BACKGROUND", 0)
		b.Label = W.Text(b, "small", "textMuted")
		b.Label:SetPoint("CENTER", b, "CENTER", 0, 0)
		b.Label:SetText(a.label)
		b:SetWidth(math.floor(b.Label:GetStringWidth() + 20 + 0.5))
		b:SetPoint("RIGHT", f.TabRow, "RIGHT", x, 0)
		b:SetScript("OnClick", function(self)
			PolestarUICharDB.archetype = self.psKey
			M.Show()
		end)
		x = x - b:GetWidth() - 2
		segs[i] = b
	end
	f.psStats.segments = segs
	Polestar.CloseOnEscape(NAME)
end

-- A section page, painted out of combat only (docs/CLIENT.md, rule 3); in
-- combat it keeps what it last drew. Returns the body height.
local function paintPage(v)
	if not InCombatLockdown() then
		-- A page that fails keeps what it drew; the error still reaches the
		-- error handler (BugGrabber in game, a failed test in the preview).
		local ok, h = pcall(v.psPaint, v)
		if ok then v.psH = h else geterrorhandler()(h) end
	end
	return v.psH + 8
end

local function refresh()
	local level, race = UnitLevel("player"), UnitRace("player")
	f.psName:SetText(UnitName("player"))
	f.psLine:SetText(("Level %d %s"):format(level, UnitClass("player")))
	W.ShellNav(f, SECTIONS, section, function(k) M.Show(k) end)
	if section == "PaperDollFrame" then
		W.ShellTabs(f, TABS, tab, function(k) tab = k; refresh() end)
		local sub = ("Level %d %s %s"):format(level, race, UnitClass("player"))
		local ilvl = itemLevel()
		if ilvl then sub = sub .. " · Item level " .. ilvl end
		W.ShellTitle(f, UnitPVPName("player") or UnitName("player"), sub)
	else
		W.ShellTabs(f, nil)
		for _, s in ipairs(SECTIONS) do
			if s.key == section then W.ShellTitle(f, s.label, ns.CharacterPages[s.key] and ns.CharacterPages[s.key].subtitle) end
		end
	end
	W.ShellFooter(f, {}, {})
	local gear = section == "PaperDollFrame" and tab == "gear"
	local stats = section == "PaperDollFrame" and tab == "stats"
	f.psGear:SetShown(gear)
	f.psStats:SetShown(stats)
	for _, b in ipairs(f.psStats.segments) do b:SetShown(stats) end
	local h = 0
	if gear then
		paintGear()
		showModel()
		h = f.psGear:GetHeight() + 48
	elseif stats then
		h = paintStats() + 8
	end
	for key, v in pairs(f.psPages) do
		local on = key == section
		v:SetShown(on)
		if on then h = paintPage(v) end
	end
	W.ShellBody(f, h)
end

-- Redraws the window where it stands (CharacterPages.lua's folds).
function ns.RefreshCharacter()
	if f and f:IsShown() then refresh() end
end

function M.Show(key, view)
	if not f then build() end
	section = key or section
	tab = view or tab
	refresh()
	f:Show()
end

function M.Toggle(key, onlyShow)
	if f and f:IsShown() and (key == nil or key == section) and not onlyShow then
		f:Hide()
	else
		M.Show(key)
	end
end

function M.Enable()
	-- Every stock door (TOGGLECHARACTER0/2/4, the micro button) calls
	-- ToggleCharacter; it has just shown CharacterFrame, which we close again.
	-- Hide(), not HideUIPanel: that dispatches to a forbidden frame, which does
	-- nothing from addon code; the panel manager repairs a frame hidden this
	-- way before it places the next panel (FramePositionDelegate:ShowUIPanel).
	hooksecurefunc("ToggleCharacter", function(key, onlyShow)
		if CharacterFrame and CharacterFrame:IsShown() then CharacterFrame:Hide() end
		M.Toggle(key, onlyShow)
	end)
	-- Out of combat, the stats are read even with the window closed (coalesced
	-- to one read per half second), so a window first opened mid-fight shows
	-- them from just before it (fill's lastRead).
	local warming = false
	local function warm()
		warming = false
		if InCombatLockdown() then return end
		if not f then build() end
		paintStats()
		for _, v in pairs(f.psPages) do paintPage(v) end
	end
	local function changed()
		if not (f and f:IsShown()) then
			if not warming and not InCombatLockdown() then
				warming = true
				Polestar.After(0.5, warm)
			end
			return
		end
		if f.psGear:IsShown() then paintGear() end
		if f.psStats:IsShown() then W.ShellBody(f, paintStats() + 8) end
		for _, v in pairs(f.psPages) do
			if v:IsShown() then W.ShellBody(f, paintPage(v)) end
		end
	end
	Polestar.RegisterEvent("PLAYER_ENTERING_WORLD", changed)
	-- The stock sheet's stat events (PaperDollFrame_OnLoad).
	for _, e in ipairs({ "UNIT_STATS", "UNIT_RANGEDDAMAGE", "UNIT_RANGED_ATTACK_POWER", "UNIT_ATTACK", "UNIT_SPELL_HASTE",
		"UNIT_RESISTANCES", "UNIT_DAMAGE", "UNIT_ATTACK_SPEED", "UNIT_MAXHEALTH", "UNIT_AURA", "UNIT_LEVEL" }) do
		Polestar.RegisterEvent(e, function(_, unit) if unit == "player" then changed() end end)
	end
	Polestar.RegisterEvent("COMBAT_RATING_UPDATE", changed)
	Polestar.RegisterEvent("PLAYER_DAMAGE_DONE_MODS", changed)
	Polestar.RegisterEvent("SKILL_LINES_CHANGED", changed)
	-- The section pages' events.
	Polestar.RegisterEvent("UPDATE_FACTION", changed)
	Polestar.RegisterEvent("CURRENCY_DISPLAY_UPDATE", changed)
	Polestar.RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", changed)
	-- Stats read in combat may be stand-ins (fill); read them again after it.
	Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", changed)
	Polestar.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", changed)
	Polestar.RegisterEvent("UNIT_INVENTORY_CHANGED", function(_, unit) if unit == "player" then changed() end end)
	-- A new look (gear, form) rebuilds the scene, as the stock sheet does.
	Polestar.RegisterEvent("UNIT_MODEL_CHANGED", function(_, unit)
		if unit == "player" and f and f:IsShown() and f.psGear:IsShown() then showModel() end
	end)
end

ns.Module("character", M)
