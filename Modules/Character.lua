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
local f, section = nil, "PaperDollFrame"
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

local SLOT, GAP, TEXT_W = 36, 6, 220
local LEFT = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
local RIGHT = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" }
-- The weapons in a row under the model, as the stock sheet and the armory lay
-- them out: each one's text on its outer side, the off hand's below it.
local WEAPONS = { { "MainHandSlot", "right" }, { "SecondaryHandSlot", "below" }, { "RangedSlot", "left" } }
local slots = {}

local qualityRGB = ns.QualityRGB

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
			return text
		end
	end
end

-- The name and enchant beside a slot; the slot's name when empty. Out of
-- combat only: item data may be secret in it (docs/CLIENT.md, rule 3).
local function paintSlotText(s, icon, q)
	if not s.psName or InCombatLockdown() then return end
	local link = icon and GetInventoryItemLink("player", s:GetID())
	local name = link and link:match("%[(.-)%]")
	s.psName:SetText(name or s.psLabel)
	local r, g, b = qualityRGB(q or 1)
	if name and r then s.psName:SetTextColor(r, g, b) else W.Color(s.psName, name and "text" or "textMuted") end
	local ench = link and enchantText(s:GetID())
	s.psEnchant:SetText(ench or "")
	-- Beside the slot, the one or two lines centred on it; below, they hang down.
	local p, rel, x = unpack(s.psSide)
	if p ~= "TOP" then s.psName:SetPoint(p, s, rel, x, ench and 8 or 0) end
end

-- Whether the worn ranged weapon shoots ammo (a bow, gun or crossbow).
local AMMO_WEAPONS = { [2] = true, [3] = true, [18] = true }
local function needsAmmo(ranged)
	local link = GetInventoryItemLink("player", ranged:GetID())
	if not link then return false end
	local _, _, _, _, _, class, sub = C_Item.GetItemInfoInstant(link)
	return class == 2 and AMMO_WEAPONS[sub] or false
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
	if s.psAmmo then s.psAmmo:SetShown(needsAmmo(s)) end
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
-- slot's place (ns.Overlay): right-click is the game's "item" action on the
-- slot, and a click while a spell targets an item lets the game's own code
-- apply it ("target-slot"). Everything else (pick up, drag, link) it hands
-- back to the slot. In combat the slots only pick up and link.
local overSlot
local function pickupWorn(s) if not SpellIsTargeting() then PickupInventoryItem(s:GetID()) end end
overSlot = ns.Overlay("PolestarUICharacterSlot", {
	enter = slotEnter,
	pickup = pickupWorn,
	-- Over the ranged slot's ammo tile, the ammo tile takes the mouse.
	stale = function(s) return s.psAmmo and s.psAmmo:IsShown() and s.psAmmo:IsMouseOver() end,
	setup = function(over)
		over:HookScript("PreClick", function(self) self.psTargeting = SpellIsTargeting() end)
		over:HookScript("PostClick", function(self, button)
			if not self.psTargeting then slotClick(self.psTarget, button) end
			if not InCombatLockdown() then overSlot(self.psTarget) end -- the slot may have changed
		end)
		over:HookScript("OnReceiveDrag", function(self) pickupWorn(self.psTarget) end)
		for _, e in ipairs({ "OnMouseDown", "OnMouseUp" }) do
			over:HookScript(e, function(self) self.psTarget:GetScript(e)(self.psTarget) end)
		end
		over:HookScript("OnHide", function(self) self.psTarget:GetScript("OnMouseUp")(self.psTarget) end)
	end,
	attrs = function(over, s)
		local id = s:GetID()
		over:SetAttribute("*target-slot*", id)
		-- An empty slot gets no action: the game's "item" action expects an item.
		over:SetAttribute("type2", GetInventoryItemID("player", id) and "item" or nil)
		over:SetAttribute("item", tostring(id))
	end,
})

-- side: where its name and enchant go (on `layer`, over the model): "left"
-- for text on its right, "right" for text on its left, "below"; nil for none.
local function newSlot(parent, name, layer, side, size)
	local id, empty = C_PaperDollInfo.GetInventorySlotInfo(name)
	local s = CreateFrame("Button", nil, parent)
	s:SetID(id)
	s:SetSize(size or SLOT, size or SLOT)
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
	end
	slots[#slots + 1] = s
	return s
end

-- The two columns on the body's edges, the weapons centred under them.
local function buildGear(body, width)
	local colH = #LEFT * (SLOT + GAP) - GAP
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", 32, -24)
	-- The weapon row and, under the off hand, its two lines.
	local weapH = SLOT + 36
	v:SetSize(width, colH + 16 + weapH)
	-- The item lines may run over the model, so they sit on a layer above it.
	local text = CreateFrame("Frame", nil, v)
	text:SetAllPoints(v)
	for i, name in ipairs(LEFT) do newSlot(v, name, text, "left"):SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(i - 1) * (SLOT + GAP)) end
	for i, name in ipairs(RIGHT) do newSlot(v, name, text, "right"):SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -(i - 1) * (SLOT + GAP)) end
	local row = #WEAPONS * (SLOT + GAP) - GAP
	for i, w in ipairs(WEAPONS) do
		local s = newSlot(v, w[1], text, w[2])
		s:SetPoint("TOPLEFT", v, "TOP", -row / 2 + (i - 1) * (SLOT + GAP), -(colH + 16))
		-- Ammo: a small tile in the ranged slot's corner, shown when it shoots.
		if w[1] == "RangedSlot" then
			s.psAmmo = newSlot(s, "AmmoSlot", nil, nil, 16)
			s.psAmmo:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, 0)
			s.psAmmo.psUp:SetSize(10, 10)
		end
	end
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

local function paintGear()
	local up = upgradeSlots()
	f.psUp = up -- for the cursor's repaint (CURSOR_CHANGED)
	for _, s in ipairs(slots) do paintSlot(s, up) end
end

---------------------------------------------------------------------------
-- Stats: a drawer docked to the window's right edge, the stock categories
-- (PAPERDOLL_STATCATEGORIES) in one column, each a heading over a row panel
-- (docs/DESIGN.md, "Stat Row"); the player can put it away. The
-- numbers and tooltips are the stock sheet's own: each row is handed to
-- PAPERDOLL_STATINFO[stat].updateFunc, which fills Label, Value and tooltip.

local STAT_H, HEAD_H, SECTION_GAP, STATS_W, STATS_TOP = 28, 44, 22, 280, 72

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

-- { name, { { fn, hideAt }, ... } } for the player's categories, in the
-- stock order.
local function statCategories()
	local cats = {}
	for _, c in ipairs(PAPERDOLL_STATCATEGORIES or {}) do
		if (c.unit or "player") == "player" then
			local list = {}
			for _, st in ipairs(c.stats) do
				local info = PAPERDOLL_STATINFO[st.stat]
				if info and (not st.showFunc or st.showFunc()) then
					list[#list + 1] = { info.updateFunc, st.hideAt }
				end
			end
			cats[#cats + 1] = { c.categoryName, list }
		end
	end
	return cats
end

-- The drawer: its own window skin, flush with the window's right edge, its
-- heading over a scrolling column.
local function buildStats()
	local d = ns.Flyout(f, NAME .. "Stats", STATS_W)
	local title = W.Text(d, "heading", "text")
	title:SetPoint("LEFT", d, "TOPLEFT", 24, -STATS_TOP / 2)
	title:SetText("Stats")
	d.Scroll = W.Scroll(d)
	d.Scroll:SetPoint("TOPLEFT", d, "TOPLEFT", 0, -STATS_TOP)
	d.Scroll:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -4, 4)
	local v = d.Scroll.Child
	v:SetWidth(STATS_W - 4)
	v.colW = STATS_W - 48
	v.sections = {}
	d.Body = v
	return d
end

-- The folded categories, by name, for every character (PolestarUIDB.statsFolded).
local function folded()
	PolestarUIDB.statsFolded = PolestarUIDB.statsFolded or {}
	return PolestarUIDB.statsFolded
end

local paintStats

-- A category: its heading (the chevron in the gutter and the heading fold it)
-- over its row panel.
local function statSection(v)
	local s = { Head = W.SectionHeader(v), Panel = W.RowPanel(v), rows = {} }
	s.Head:SetWidth(v.colW)
	s.Panel:SetWidth(v.colW)
	s.Chevron = W.Tex(s.Head, "ARTWORK", "chevron-down", "textDim")
	s.Chevron:SetSize(12, 12)
	s.Chevron:SetPoint("RIGHT", s.Head.Text, "LEFT", -6, 0)
	s.Hit = CreateFrame("Button", nil, s.Head)
	s.Hit:SetPoint("TOPLEFT", s.Head, "TOPLEFT", -24, 0)
	s.Hit:SetPoint("BOTTOMRIGHT", s.Head, "BOTTOMRIGHT", 0, 0)
	s.Hit:SetScript("OnClick", function()
		folded()[s.name] = not folded()[s.name] or nil
		paintStats()
	end)
	s.Hit:SetScript("OnEnter", function() W.Color(s.Chevron, "text") end)
	s.Hit:SetScript("OnLeave", function() W.Color(s.Chevron, "textDim") end)
	return s
end

-- Lays the categories out down the drawer and sets its scroll.
function paintStats()
	local d = f.psStats
	local v, y = d.Body, 0
	local cats = statCategories()
	for i, cat in ipairs(cats) do
		local s = v.sections[i] or statSection(v)
		v.sections[i] = s
		s.name = cat[1]
		local n = 0
		for _, e in ipairs(cat[2]) do
			local r = statRow(s, n + 1)
			if fill(r, e[1], e[2]) then
				n = n + 1
			else
				r:Hide()
			end
		end
		for k = n + 1, #s.rows do s.rows[k]:Hide() end
		local shown, open = n > 0, not folded()[cat[1]]
		s.Head:SetShown(shown)
		s.Panel:SetShown(shown and open)
		if shown then
			W.SetSection(s.Head, cat[1])
			s.Chevron:SetTexture(Polestar.Theme.Media(open and "chevron-down" or "chevron-right"))
			s.Head:SetPoint("TOPLEFT", v, "TOPLEFT", 24, -y)
			s.Panel:SetPoint("TOPLEFT", v, "TOPLEFT", 24, -(y + HEAD_H))
			s.Panel:SetHeight(n * STAT_H)
			y = y + HEAD_H + (open and n * STAT_H + SECTION_GAP or 0)
		end
	end
	for i = #cats + 1, #v.sections do
		v.sections[i].Head:Hide()
		v.sections[i].Panel:Hide()
	end
	W.SetScrollContent(d.Scroll, y, f:GetHeight() - STATS_TOP - 4)
end

local refresh, statsShown, repairLine -- below

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale" })
	ns.Dock(f)
	ns.WindowMenu(f, "character")
	-- The subject block names the window, in place of Polestar's lockup:
	-- the class icon, the name, the level and class, and the guild under them.
	f.Search:Hide()
	local b = ns.SubjectBlock(f)
	f.psClass, f.psName, f.psLine = b.icon, b.name, b.line
	f.psGuild = W.Text(f.Sidebar, "small", "textMuted")
	f.psGuild:SetPoint("TOPLEFT", f.psLine, "BOTTOMLEFT", 0, -4)
	-- A longer guild ends in an ellipsis (a fixed width on an unwrapped
	-- string: the client's own truncation).
	f.psGuild:SetWidth(f.psLine:GetWidth())
	f.psGear = buildGear(f.Body, f.BodyWidth)
	f.psStats = buildStats()
	-- The dock makes room for the drawer, and the window keeps it on screen.
	ns.DockFlyout(f, f.psStats, 1)
	-- The other sections' pages (CharacterPages.lua), each with the height it last drew.
	f.psPages = {}
	for key, page in pairs(ns.CharacterPages) do
		local v = page.build(f.Body, f.BodyWidth)
		v:Hide()
		v.psPaint, v.psH = page.paint, 0
		f.psPages[key] = v
	end
	-- The band's Options: the drawer put away and back, for every character.
	f.psOptions = ns.OptionsButton(f, function()
		return { { text = "Show stats", checked = statsShown(), onClick = function()
			PolestarUIDB.hideStats = statsShown() or nil
			refresh()
		end } }
	end)
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

-- The band's status: how many worn items have lost durability.
function repairLine()
	local n = 0
	for _, s in ipairs(slots) do
		local cur, max = GetInventoryItemDurability(s:GetID())
		if cur and max and max > 0 and cur < max then n = n + 1 end
	end
	if n == 0 then return "Gear in good repair" end
	return n == 1 and "1 item needs repair" or n .. " items need repair"
end

-- The drawer is shown unless the player put it away (for every character).
function statsShown() return not (PolestarUIDB and PolestarUIDB.hideStats) end

function refresh()
	local level = UnitLevel("player")
	f.psName:SetText(playerText(UnitName) or "")
	f.psLine:SetText(("Level %d %s"):format(level, UnitClass("player")))
	f.psGuild:SetText(playerText(GetGuildInfo) or "")
	f.psClass:SetTexture("Interface\\Icons\\ClassIcon_" .. select(2, UnitClass("player")))
	W.ShellNav(f, SECTIONS, section, function(k) M.Show(k) end)
	local gear = section == "PaperDollFrame"
	if gear then
		W.ShellTabs(f, nil)
		W.ShellTitle(f, CHARACTER or "Character", repairLine())
	else
		W.ShellTabs(f, nil)
	end
	W.ShellFooter(f, {}, {})
	local stats = gear and statsShown()
	f.psGear:SetShown(gear)
	f.psStats:SetShown(stats)
	f.psOptions:SetShown(gear)
	local h = 0
	if gear then
		paintGear()
		showModel()
		h = f.psGear:GetHeight() + 24
	end
	if stats then paintStats() end
	for key, v in pairs(f.psPages) do
		local on = key == section
		v:SetShown(on)
		if on then
			h = paintPage(v)
			for _, s in ipairs(SECTIONS) do
				if s.key == key then W.ShellTitle(f, s.label, v.psSub) end
			end
		end
	end
	W.ShellBody(f, h)
end

-- Redraws the window where it stands (CharacterPages.lua's folds).
function ns.RefreshCharacter()
	if f and f:IsShown() then refresh() end
end

function M.Show(key)
	if not f then build() end
	section = key or section
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
	-- Switched off (Core.lua, ns.Switch), the hook stays and does nothing.
	hooksecurefunc("ToggleCharacter", function(key, onlyShow)
		if not ns.Enabled("character") then return end
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
		if f.psStats:IsShown() then paintStats() end
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

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return CharacterFrame end

ns.Module("character", M)
