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
	{ key = "StatisticsFrame", label = STATISTICS or "Statistics", icon = "icon-achieve" },
}
local TABS = { { key = "gear", label = "Gear" }, { key = "stats", label = "Stats" } }

local f, section, tab = nil, "PaperDollFrame", "gear"
local M = {}

-- The player's name (UnitName, UnitPVPName, GetGuildInfo) as last read out
-- of combat: in combat the client may hand our code a secret one, which
-- tooltips and our strings refuse (docs/CLIENT.md, rule 3). A nil (no guild)
-- is kept too.
local known = {}
local function playerText(fn)
	local v = fn("player")
	if not (issecretvalue and issecretvalue(v)) then known[fn] = v or false end
	return known[fn] or nil
end

---------------------------------------------------------------------------
-- Gear: the slot tiles (docs/DESIGN.md, "Slot Tile"), in the stock columns.

local SLOT, GAP, TEXT_W, PRIMARY_H = 36, 6, 220, 40
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

-- Short stat names, so an item's stats fit beside its slot (this screen only).
-- shortcut: English abbreviations; other locales and unlisted stats get the client's full name.
local SHORT = { STAMINA = "Sta", STRENGTH = "Str", AGILITY = "Agi", INTELLECT = "Int", SPIRIT = "Spi",
	ATTACK_POWER = "AP", RANGED_ATTACK_POWER = "RAP", SPELL_POWER = "SP", SPELL_DAMAGE_DONE = "SP",
	SPELL_HEALING_DONE = "Heal",
	CRIT_RATING = "Crit", HIT_RATING = "Hit", HASTE_RATING = "Haste", EXPERTISE_RATING = "Exp",
	DEFENSE_SKILL_RATING = "Def", DODGE_RATING = "Dodge", PARRY_RATING = "Parry", BLOCK_RATING = "Block",
	BLOCK_VALUE = "Block Value", RESILIENCE_RATING = "Resil", ARMOR_PENETRATION_RATING = "ArP",
	SPELL_PENETRATION = "Pen", MANA_REGENERATION = "MP5", DAMAGE_PER_SECOND = "DPS" }
-- By the client's name, for keys not above (Forever's newer items).
local SHORT_NAMED = { ["spell damage"] = "SP", ["bonus damage"] = "SP", ["spell power"] = "SP",
	["healing"] = "Heal", ["bonus healing"] = "Heal", ["spell healing"] = "Heal", ["healing power"] = "Heal" }

local function shortName(k)
	return SHORT[k:match("^ITEM_MOD_(.-)_SHORT$") or ""] or SHORT_NAMED[_G[k]:lower()] or _G[k]
end

-- An enchant's words in the same short names ("+15 Agility" to "+15 Agi"):
-- the client's names for the stats above, whole words, longest first.
local named
local function shortWords(text)
	if not named then
		named = {}
		for k, s in pairs(SHORT) do
			local n = _G["ITEM_MOD_" .. k .. "_SHORT"]
			if n then named[#named + 1] = { n:lower(), s } end
		end
		for n, s in pairs(SHORT_NAMED) do named[#named + 1] = { n, s } end
		table.sort(named, function(a, b) return #a[1] > #b[1] end)
	end
	for _, e in ipairs(named) do
		local i, j = text:lower():find("%f[%w]" .. e[1]:gsub("%p", "%%%0") .. "%f[%W]")
		if i then text = text:sub(1, i - 1) .. e[2] .. text:sub(j + 1) end
	end
	return text
end

-- The item's stats ("+12 Sta  +8 Str"), largest first; armor left out.
local function itemStats(link)
	local t = C_Item.GetItemStats(link)
	local list = {}
	for k, n in pairs(t or {}) do
		if k ~= "RESISTANCE0_NAME" and _G[k] and n ~= 0 then
			list[#list + 1] = { n, shortName(k) }
		end
	end
	table.sort(list, function(a, b) if a[1] ~= b[1] then return a[1] > b[1] end return a[2] < b[2] end)
	for i, e in ipairs(list) do list[i] = ("+%g %s"):format(e[1], e[2]) end
	return table.concat(list, "  ")
end

-- The worn item's permanent enchant, as its tooltip line reads, without the
-- "Enchanted: " the game puts before it.
local ENCHANT_LINE = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent or 15
local function enchantText(id)
	local data = C_TooltipInfo and C_TooltipInfo.GetInventoryItem("player", id)
	for _, line in ipairs(data and data.lines or {}) do
		local text = line.type == ENCHANT_LINE and line.leftText
		if text and not (issecretvalue and issecretvalue(text)) then
			local pre = ENCHANTED_TOOLTIP_LINE and ENCHANTED_TOOLTIP_LINE:match("^(.-)%%s")
			if pre and pre ~= "" and text:sub(1, #pre) == pre then text = text:sub(#pre + 1) end
			return shortWords(text)
		end
	end
end

-- The name and stats beside a column slot; the slot's name when empty. Out of
-- combat only: item stats may be secret in it (docs/CLIENT.md, rule 3).
local function paintSlotText(s, icon, q)
	if not s.psName or InCombatLockdown() then return end
	local link = icon and GetInventoryItemLink("player", s:GetID())
	local name = link and link:match("%[(.-)%]")
	s.psName:SetText(name or s.psLabel)
	local r, g, b = qualityRGB(q or 1)
	if name and r then s.psName:SetTextColor(r, g, b) else W.Color(s.psName, name and "text" or "textMuted") end
	s.psStats:SetText(link and itemStats(link) or "")
	-- The enchant as a third line, the three centred on the slot as the two are.
	local ench = link and enchantText(s:GetID())
	s.psEnchant:SetText(ench or "")
	local p, rel, x = unpack(s.psSide)
	s.psName:SetPoint(p, s, rel, x, ench and 12 or 8)
	s.psStats:SetPoint(p, s, rel, x, ench and 0 or -8)
end

-- The slots an item in the bags would upgrade, by Polestar's own bag verdict
-- (its settings, Pawn hand-off included) and the slot its advice compares
-- against. Read once per paint.
local function upgradeSlots()
	local up, Gear = {}, Polestar.Gear
	if not (Gear and Gear.Bags and Gear.Bags.IsOn() and C_Container) then return up end
	for bag = 0, NUM_BAG_SLOTS or 4 do
		for i = 1, C_Container.GetContainerNumSlots(bag) do
			local link = C_Container.GetContainerItemLink(bag, i)
			if link and Gear.Bags.IsUpgrade(link) then
				local r = Gear.CompareToEquipped(link)
				if r and r.slot then up[r.slot] = true end
			end
		end
	end
	return up
end

local function paintSlot(s, up)
	local id = s:GetID()
	s.psUp:SetShown(up and up[id] or false)
	local icon = GetInventoryItemTexture("player", id)
	s.Icon:SetTexture(icon or s.psEmpty)
	s.Icon:SetDesaturated(not icon)
	s.Icon:SetAlpha(icon and 1 or 0.6)
	if icon then s.Icon:SetVertexColor(1, 1, 1) else s.Icon:SetVertexColor(Polestar.Theme.Color("textMuted")) end
	paintSlotText(s, icon, icon and GetInventoryItemQuality("player", id))
	local cur, max = GetInventoryItemDurability(id)
	local broken = icon and GetInventoryItemBroken("player", id)
	local r, g, b, a
	-- The item on the cursor fits here: the accent, over every other state.
	if CursorHasItem() and C_PaperDollInfo.CursorCanGoInSlot(id) then
		r, g, b = Polestar.Theme.Color("accent"); a = 1
	elseif broken or (cur and max and max > 0 and cur == 0) then
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

-- Whether the worn item has a Use: effect (a trinket, an engineering belt).
local function canUse(id)
	local link = GetInventoryItemLink("player", id)
	local spell = C_Item and C_Item.GetItemSpell or GetItemSpell
	return link and spell and spell(link) ~= nil
end

local function slotEnter(s)
	GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
	if GameTooltip:SetInventoryItem("player", s:GetID()) then
		ns.TooltipHint((canUse(s:GetID()) and "Right-click to use it. " or "")
			.. "Drag to take it off. Shift-click to link it in chat.")
	else
		GameTooltip:SetText(s.psLabel)
		ns.TooltipHint("Drag an item here to equip it.")
	end
	GameTooltip:Show()
end

-- Left: pick up or put down (the stock slot's own call, unprotected); with a
-- modifier, the client's linking and try-on handling. While a spell targets
-- an item, picking up is applying it, forbidden to us: the secure overlay
-- (below) does that, and in combat it cannot.
local function slotClick(s, button)
	local link = GetInventoryItemLink("player", s:GetID())
	if link and IsModifiedClick() and HandleModifiedItemClick(link) then return end
	if button ~= "LeftButton" or SpellIsTargeting() then return end
	PickupInventoryItem(s:GetID())
end

-- Using a worn item (right-click) and applying an enchant, kit or stone to
-- one are protected. So out of combat one secure button takes the hovered
-- slot's place: right-click is the game's "item" action on the slot, and a
-- click while a spell targets an item lets the game's own code apply it
-- ("target-slot"). Everything else (pick up, drag, link) it hands back to the
-- slot. It hangs off UIParent, not the window: a window with secure children
-- could not close in combat (docs/CLIENT.md, rule 4); it hides as combat
-- starts, and the slots then only pick up and link.
local over
local function overSlot(s)
	if InCombatLockdown() then return end
	if not over then
		over = CreateFrame("Button", "PolestarUICharacterSlot", UIParent, "SecureActionButtonTemplate")
		over:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		over:RegisterForDrag("LeftButton")
		over:EnableMouse(true)
		over:SetAttribute("useOnKeyDown", false)
		over:SetScript("PreClick", function(self) self.psTargeting = SpellIsTargeting() end)
		over:SetScript("PostClick", function(self, button)
			if not self.psTargeting then slotClick(self.psSlot, button) end
			if not InCombatLockdown() then overSlot(self.psSlot) end -- the slot may have changed
		end)
		local function pickup(self) if not SpellIsTargeting() then PickupInventoryItem(self.psSlot:GetID()) end end
		over:SetScript("OnDragStart", pickup)
		over:SetScript("OnReceiveDrag", pickup)
		for _, e in ipairs({ "OnMouseDown", "OnMouseUp" }) do
			over:SetScript(e, function(self) self.psSlot:GetScript(e)(self.psSlot) end)
		end
		over:SetScript("OnEnter", function(self) slotEnter(self.psSlot) end)
		over:SetScript("OnLeave", function(self)
			W.HideTooltip()
			if not InCombatLockdown() then self:Hide() end
		end)
		over:SetScript("OnHide", function(self)
			self.psSlot:UnlockHighlight()
			self.psSlot:GetScript("OnMouseUp")(self.psSlot)
		end)
		-- The window closed (a key) or the tab changed under the cursor.
		over:SetScript("OnUpdate", function(self)
			if not self.psSlot:IsVisible() and not InCombatLockdown() then self:Hide() end
		end)
		Polestar.RegisterEvent("PLAYER_REGEN_DISABLED", function() over:Hide() end)
	end
	if over.psSlot and over.psSlot ~= s then over.psSlot:UnlockHighlight() end
	over.psSlot = s
	local k = s:GetEffectiveScale() / UIParent:GetEffectiveScale()
	over:ClearAllPoints()
	over:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", s:GetLeft() * k, s:GetTop() * k)
	over:SetSize(s:GetWidth() * k, s:GetHeight() * k)
	-- Above the window's strata: in it, the game still gave the slot the mouse
	-- although the button was shown over it, a level higher.
	over:SetFrameStrata("DIALOG")
	over:SetFrameLevel(s:GetFrameLevel() + 20)
	local id = s:GetID()
	over:SetAttribute("*target-slot*", id)
	-- An empty slot gets no action: the game's "item" action expects an item.
	over:SetAttribute("type2", GetInventoryItemID("player", id) and "item" or nil)
	over:SetAttribute("item", tostring(id))
	s:LockHighlight() -- the slot's hover wash, now under the overlay
	over:Show()
end

-- side: "left" or "right" for a column slot, its name and stats on the
-- inside (on `layer`, over the model); nil for a weapon.
local function newSlot(parent, name, layer, side)
	local id, empty = C_PaperDollInfo.GetInventorySlotInfo(name)
	local s = CreateFrame("Button", nil, parent)
	s:SetID(id)
	s:SetSize(SLOT, SLOT)
	s.psEmpty = empty
	s.psLabel = _G[name:upper()] or name
	W.Fill(s, "scrim", "BACKGROUND", 0)
	s.Icon = ns.GameIcon(s)
	s.Icon:SetPoint("TOPLEFT", 1, -1)
	s.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	-- Polestar's bag upgrade arrow, top-left as on every item it marks.
	s.psUp = W.Tex(s, "OVERLAY", "qol-upgrade", "success")
	s.psUp:SetSize(18, 18)
	s.psUp:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0)
	-- Pressed, the icon nudges 1px, as an icon button's glyph.
	s:SetScript("OnMouseDown", function(self)
		self.Icon:SetPoint("TOPLEFT", 2, -2)
		self.Icon:SetPoint("BOTTOMRIGHT", 0, 0)
	end)
	s:SetScript("OnMouseUp", function(self)
		self.Icon:SetPoint("TOPLEFT", 1, -1)
		self.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	end)
	W.Hover(s)
	s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	s:RegisterForDrag("LeftButton")
	s:SetScript("OnClick", slotClick)
	s:SetScript("OnDragStart", function(self) PickupInventoryItem(self:GetID()) end)
	s:SetScript("OnReceiveDrag", function(self) PickupInventoryItem(self:GetID()) end)
	s:SetScript("OnEnter", function(self)
		slotEnter(self)
		overSlot(self)
	end)
	s:SetScript("OnLeave", W.HideTooltip)
	if side then
		local p, rel, x = "LEFT", "RIGHT", 8
		if side == "right" then p, rel, x = "RIGHT", "LEFT", -8 end
		s.psSide = { p, rel, x }
		s.psName = W.Text(layer, "label", "text")
		s.psName:SetPoint(p, s, rel, x, 8)
		s.psStats = W.Text(layer, "small", "textDim")
		s.psStats:SetPoint(p, s, rel, x, -8)
		s.psEnchant = W.Text(layer, "small", "success")
		s.psEnchant:SetPoint(p, s, rel, x, -12)
		for _, t in ipairs({ s.psName, s.psStats, s.psEnchant }) do
			t:SetWidth(TEXT_W)
			t:SetJustifyH(p)
		end
	end
	slots[#slots + 1] = s
	return s
end

-- The two columns on the body's edges, the weapons centred under them, and
-- under those the primary stats' strip.
local function buildGear(body, width)
	local colH = #LEFT * (SLOT + GAP) - GAP
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", 32, -24)
	v:SetSize(width, colH + 16 + SLOT + 12 + PRIMARY_H)
	-- The item lines may run over the model, so they sit on a layer above it.
	local text = CreateFrame("Frame", nil, v)
	text:SetAllPoints(v)
	for i, name in ipairs(LEFT) do newSlot(v, name, text, "left"):SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(i - 1) * (SLOT + GAP)) end
	for i, name in ipairs(RIGHT) do newSlot(v, name, text, "right"):SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -(i - 1) * (SLOT + GAP)) end
	local row = #WEAPONS * (SLOT + GAP) - GAP
	for i, name in ipairs(WEAPONS) do
		newSlot(v, name):SetPoint("TOPLEFT", v, "TOP", -row / 2 + (i - 1) * (SLOT + GAP), -(colH + 16))
	end
	-- The primary stats' strip (paintPrimary): on the page, no panel.
	local primary = CreateFrame("Frame", nil, v)
	primary:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", 0, 0)
	primary:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", 0, 0)
	primary:SetHeight(PRIMARY_H)
	v.Primary = primary
	-- The model well between the columns (docs/DESIGN.md, "Model Well"): no
	-- border, a shade that fades out towards its edges.
	local well = CreateFrame("Frame", nil, v)
	well:SetPoint("TOPLEFT", v, "TOPLEFT", SLOT + 16, 0)
	well:SetPoint("BOTTOMRIGHT", v, "TOPRIGHT", -(SLOT + 16), -colH)
	local shade = W.Tex(well, "BACKGROUND", "glow")
	shade:SetAllPoints(well)
	W.Painter(shade, function(t) local r, g, b = Polestar.Theme.Color("shade"); t:SetVertexColor(r, g, b, 0.6) end)
	-- The game's own character-sheet scene: its camera frames every race and
	-- form, and the template turns, zooms and pans it. Our frame, their template.
	local m = CreateFrame("ModelScene", nil, well, "PanningModelSceneMixinTemplate")
	m:SetPoint("TOPLEFT", 1, -1)
	m:SetPoint("BOTTOMRIGHT", -1, 1)
	-- Hooked: the template has its own mouse scripts.
	m:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(playerText(UnitName) or "")
		ns.TooltipHint("Drag to turn, scroll to zoom, right-drag to move.")
		GameTooltip:Show()
	end)
	m:HookScript("OnLeave", W.HideTooltip)
	text:SetFrameLevel(m:GetFrameLevel() + 10)
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

local paintPrimary -- below, with the stats it reads

local function paintGear()
	local up = upgradeSlots()
	f.psUp = up -- for the cursor's repaint (CURSOR_CHANGED)
	for _, s in ipairs(slots) do paintSlot(s, up) end
	paintPrimary()
end

---------------------------------------------------------------------------
-- Stats: the stock categories (PAPERDOLL_STATCATEGORIES), each a heading over
-- a row panel (docs/DESIGN.md, "Stat Row"), flowed into two columns. The
-- numbers and tooltips are the stock sheet's own: each row is handed to
-- PAPERDOLL_STATINFO[stat].updateFunc, which fills Label, Value and tooltip.

local STAT_H, HEAD_H, SECTION_GAP, COL_GAP = 28, 44, 22, 24

-- Archetypes: the player's choice (per character, PolestarUICharDB.archetype),
-- one menu on both tabs. On the Stats tab the layout never moves: `key` stats
-- read in text, the rest in textMuted. Under the gear, `stats` are the strip.
-- The lists follow Forever's stats (Classic's, with one Hit and one Crit).
local ARCHETYPES = {
	{ id = "melee", label = "Melee", tip = "Stats for melee fighters.",
		key = { STRENGTH = true, AGILITY = true, MAINHAND_DAMAGE = true, OFFHAND_DAMAGE = true, ATTACK_AP = true,
			HITCHANCE = true, CRITCHANCE = true, HASTE = true, EXPERTISE = true, ARMORPEN = true },
		stats = { "STRENGTH", "AGILITY", "ATTACK_AP", "CRITCHANCE", "HITCHANCE" } },
	{ id = "ranged", label = "Ranged", tip = "Stats for hunters and other ranged fighters.",
		key = { AGILITY = true, RANGED_DAMAGE = true, RANGED_ATTACK_AP = true, HITCHANCE = true, CRITCHANCE = true,
			HASTE = true, ARMORPEN = true },
		stats = { "AGILITY", "RANGED_ATTACK_AP", "RANGED_DAMAGE", "CRITCHANCE", "HITCHANCE" } },
	{ id = "caster", label = "Caster", tip = "Stats for spellcasters who deal damage.",
		key = { INTELLECT = true, SPIRIT = true, POWER = true, MANAREGEN = true, SPELLPOWER = true,
			SPELLPENETRATION = true, HITCHANCE = true, CRITCHANCE = true, HASTE = true },
		stats = { "INTELLECT", "SPELLPOWER", "CRITCHANCE", "HITCHANCE", "SPELLPENETRATION" } },
	{ id = "healer", label = "Healer", tip = "Stats for healers.",
		key = { INTELLECT = true, SPIRIT = true, POWER = true, MANAREGEN = true, SPELLHEALING = true,
			CRITCHANCE = true, HASTE = true },
		stats = { "INTELLECT", "SPIRIT", "SPELLHEALING", "CRITCHANCE", "MANAREGEN" } },
	{ id = "tank", label = "Tank", tip = "Stats for tanks.",
		key = { STAMINA = true, HEALTH = true, DEFENSE = true, DODGE = true, PARRY = true, BLOCK = true, ARMOR = true },
		stats = { "HEALTH", "ARMOR", "DEFENSE", "DODGE", "PARRY", "BLOCK" } },
}
local BY_ID = {}
for _, a in ipairs(ARCHETYPES) do BY_ID[a.id] = a end
-- The starting choice by class, until the player picks one.
local CASTERS = { MAGE = true, WARLOCK = true, PRIEST = true, DRUID = true, SHAMAN = true }

local function archetype()
	local id = PolestarUICharDB and PolestarUICharDB.archetype
	if not BY_ID[id] then
		local _, class = UnitClass("player")
		id = class == "HUNTER" and "ranged" or CASTERS[class] and "caster" or "melee"
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

-- The stock functions write into this hidden row, never into ours: even out
-- of combat their text can be secret, and Polestar's font hook on our strings
-- cannot read a secret one (docs/CLIENT.md, rule 3). Its strings take the
-- game's font, so no hook. What it holds is copied over only when not secret.
local scratch
local OWN = {} -- the scratch row's own keys; any other is the stock function's

-- Runs fn on the scratch row: true, label, value, its fields (numericValue,
-- tooltip, onEnterFunc ...), shown; nil when it fails or reads secret.
local function runStock(fn)
	if not scratch then
		scratch = CreateFrame("Button", nil, UIParent)
		scratch:SetAlpha(0)
		for _, k in ipairs({ "Label", "Value" }) do
			scratch[k] = scratch:CreateFontString(nil, "OVERLAY")
			scratch[k]:SetFontObject(GameFontHighlightSmall)
		end
		for k in pairs(scratch) do OWN[k] = true end
	end
	for k in pairs(scratch) do if not OWN[k] then scratch[k] = nil end end
	scratch:Show()
	scratch.Label:SetText("")
	scratch.Value:SetText("")
	if not pcall(fn, scratch, "player") then return end
	local label, value = scratch.Label:GetText(), scratch.Value:GetText()
	if secret(label) or secret(value) or secret(scratch.numericValue) then return end
	local fields = {}
	for k, v in pairs(scratch) do if not OWN[k] then fields[k] = v end end
	-- The stock label ends in STAT_FORMAT's colon; a row label here has none.
	return true, (label or ""):gsub("%s*:%s*$", ""), value, fields, scratch:IsShown()
end

-- Fills row r from one stock stat function; true when the stat is to be shown.
-- In combat, or when the read fails, it shows what the stat last read.
local function fill(r, fn, hideAt)
	for k in pairs(r.psFields or {}) do r[k] = nil end
	r:Show()
	local ok, label, value, fields, shown
	if not InCombatLockdown() then ok, label, value, fields, shown = runStock(fn) end
	if ok then
		lastRead[fn] = { label, value, fields }
	else
		local last = lastRead[fn]
		if not last then return false end
		label, value, fields, shown = last[1], last[2], last[3], true
	end
	r.Label:SetText(label)
	r.Value:SetText(value or "")
	for k, v in pairs(fields) do r[k] = v end
	r.psFields = fields
	return shown and (hideAt == nil or hideAt ~= fields.numericValue)
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

---------------------------------------------------------------------------
-- Primary stats: the strip under the gear, the archetype's `stats`. Each cell
-- is a stat row as on the Stats tab (fill), so its combat rules hold.

-- A cell: the value in Number over its name in Small textDim, centred.
local function primaryCell(strip, i)
	local c = CreateFrame("Button", nil, strip)
	c:SetHeight(PRIMARY_H)
	c.Value = W.Text(c, "number", "text")
	c.Value:SetPoint("TOPLEFT", c, "TOPLEFT", 6, -5)
	c.Value:SetPoint("TOPRIGHT", c, "TOPRIGHT", -6, -5)
	c.Label = W.Text(c, "small", "textDim")
	c.Label:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 6, 5)
	c.Label:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -6, 5)
	for _, t in ipairs({ c.Value, c.Label }) do t:SetJustifyH("CENTER") end
	-- Between cells, the middle dot the page subtitle separates with.
	if i > 1 then
		c.Dot = W.Tex(c, "ARTWORK", "circle", "textMuted")
		c.Dot:SetSize(4, 4)
		c.Dot:SetPoint("CENTER", c, "LEFT", 0, 0)
	end
	c:SetScript("OnEnter", statEnter)
	c:SetScript("OnLeave", W.HideTooltip)
	return c
end

-- The picked list's stats that show (the stock functions hide some, as Block
-- without a shield), spread evenly across the strip.
function paintPrimary()
	local strip, list = f.psGear.Primary, archetype()
	strip.cells = strip.cells or {}
	local n = 0
	for _, key in ipairs(list.stats) do
		local info = PAPERDOLL_STATINFO[key]
		if info then
			local c = strip.cells[n + 1] or primaryCell(strip, n + 1)
			strip.cells[n + 1] = c
			if fill(c, info.updateFunc) then n = n + 1 else c:Hide() end
		end
	end
	for k = n + 1, #strip.cells do strip.cells[k]:Hide() end
	local w = f.BodyWidth / math.max(n, 1)
	for k = 1, n do
		local c = strip.cells[k]
		c:SetWidth(w)
		c:SetPoint("TOPLEFT", strip, "TOPLEFT", (k - 1) * w, 0)
	end
end

local function pickArchetype(self)
	if W.MenuShown(self) then return W.HideMenu() end
	local cur, items = archetype(), {}
	for i, a in ipairs(ARCHETYPES) do
		items[i] = { text = a.label, checked = a == cur, onClick = function()
			PolestarUICharDB.archetype = a.id
			M.Show()
		end }
	end
	W.ShowMenu(self, items, { minWidth = self:GetWidth() })
end

local function build()
	f = W.Shell(NAME, {})
	-- The subject block names the window, in place of Polestar's lockup.
	-- Reparented, not hidden: the shell re-shows its version line on every show.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Search, f.Status, f.Stage }) do r:SetParent(holder) end
	-- The class icon on an inset well with a hairline, centred on the title line.
	local well = CreateFrame("Frame", nil, f.Sidebar)
	well:SetSize(36, 36)
	well:SetPoint("LEFT", f.Sidebar, "TOPLEFT", 24, -47)
	Polestar.Theme.Skin(well, "inset")
	Polestar.Theme.Border(well, Polestar.Theme.Wash("border"))
	f.psClass = ns.GameIcon(well)
	f.psClass:SetPoint("TOPLEFT", 1, -1)
	f.psClass:SetPoint("BOTTOMRIGHT", -1, 1)
	f.psName = W.Text(f.Sidebar, "title", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", 24 + 36 + 12, -47)
	f.psLine = W.Text(f.Sidebar, "small", "textDim")
	f.psLine:SetPoint("TOPLEFT", f.psName, "BOTTOMLEFT", 0, -6)
	f.psGuild = W.Text(f.Sidebar, "small", "textMuted")
	f.psGuild:SetPoint("TOPLEFT", f.psLine, "BOTTOMLEFT", 0, -4)
	-- To the sidebar's 24 edge; a longer guild ends in an ellipsis
	-- (a fixed width on an unwrapped string: the client's own truncation).
	for _, t in ipairs({ f.psName, f.psLine, f.psGuild }) do t:SetWidth(f.Sidebar:GetWidth() - (24 + 36 + 12) - 24) end
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
	-- The archetype's menu at the right of the tab row, on both tabs.
	local pick = CreateFrame("Button", nil, f.TabRow)
	pick:SetHeight(24)
	pick:SetPoint("RIGHT", f.TabRow, "RIGHT", -20, 0)
	W.Hover(pick)
	pick.Label = W.Text(pick, "small", "text")
	pick.Label:SetPoint("LEFT", pick, "LEFT", 10, 0)
	pick.Arrow = W.Tex(pick, "ARTWORK", "chevron-down", "textDim")
	pick.Arrow:SetSize(12, 12)
	pick.Arrow:SetPoint("RIGHT", pick, "RIGHT", -10, 0)
	pick:SetScript("OnClick", pickArchetype)
	pick:SetScript("OnEnter", function(self)
		local a = archetype()
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(a.label)
		GameTooltip:AddLine(a.tip, 1, 1, 1, true)
		ns.TooltipHint("Picks the stats under your gear and the ones that stand out on the Stats tab. Kept for this character.")
		GameTooltip:Show()
	end)
	pick:SetScript("OnLeave", W.HideTooltip)
	f.psPick = pick
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
	f.psName:SetText(playerText(UnitName) or "")
	f.psLine:SetText(("Level %d %s"):format(level, UnitClass("player")))
	f.psGuild:SetText(playerText(GetGuildInfo) or "")
	f.psClass:SetTexture("Interface\\Icons\\ClassIcon_" .. select(2, UnitClass("player")))
	W.ShellNav(f, SECTIONS, section, function(k) M.Show(k) end)
	if section == "PaperDollFrame" then
		W.ShellTabs(f, TABS, tab, function(k) tab = k; refresh() end)
		local sub = ("Level %d %s %s"):format(level, race, UnitClass("player"))
		local ilvl = itemLevel()
		if ilvl then sub = sub .. " · Item level " .. ilvl end
		W.ShellTitle(f, playerText(UnitPVPName) or playerText(UnitName) or "", sub)
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
	f.psPick:SetShown(gear or stats)
	f.psPick.Label:SetText(archetype().label .. " stats")
	f.psPick:SetWidth(math.floor(f.psPick.Label:GetStringWidth() + 44 + 0.5))
	local h = 0
	if gear then
		paintGear()
		showModel()
		h = f.psGear:GetHeight() + 24
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
	-- When a spell waits for an item (an enchant), the game opens the sheet
	-- through ShowCharacterFrameIfMatchesContext: it means "show", but finding
	-- the stock frame hidden it toggles, which would close ours.
	hooksecurefunc("ToggleCharacter", function(key, onlyShow)
		if CharacterFrame and CharacterFrame:IsShown() then CharacterFrame:Hide() end
		local forContext = debugstack and debugstack():find("ShowCharacterFrameIfMatchesContext", 1, true)
		M.Toggle(key, onlyShow or forContext ~= nil)
	end)
	-- Out of combat, the stats are read even with the window closed (coalesced
	-- to one read per half second), so a window first opened mid-fight shows
	-- them from just before it (fill's lastRead).
	local warming = false
	local function warm()
		warming = false
		if InCombatLockdown() then return end
		if not f then build() end
		playerText(UnitName)
		playerText(UnitPVPName)
		playerText(GetGuildInfo)
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
	Polestar.RegisterEvent("CRITERIA_UPDATE", changed)
	-- Stats read in combat may be stand-ins (fill); read them again after it.
	Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", changed)
	Polestar.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", changed)
	-- Bags change what the upgrade arrows point at.
	Polestar.RegisterEvent("BAG_UPDATE_DELAYED", changed)
	-- An item picked up or put down: the borders of the slots it fits.
	Polestar.RegisterEvent("CURSOR_CHANGED", function()
		if f and f:IsShown() and f.psGear:IsShown() then
			for _, s in ipairs(slots) do paintSlot(s, f.psUp) end
		end
	end)
	Polestar.RegisterEvent("UNIT_INVENTORY_CHANGED", function(_, unit) if unit == "player" then changed() end end)
	-- A new look (gear, form) rebuilds the scene, as the stock sheet does.
	Polestar.RegisterEvent("UNIT_MODEL_CHANGED", function(_, unit)
		if unit == "player" and f and f:IsShown() and f.psGear:IsShown() then showModel() end
	end)
end

ns.Module("character", M)
