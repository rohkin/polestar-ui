-- The Spellbook (docs/DESIGN.md, "Spellbook"): the stock spellbook tab of
-- PlayerSpellsFrame in a Polestar shell. Talents are Talents.lua's.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUISpellbook"
local ROW_H, ICON, COL_GAP = 44, 36, 24

local f, section, query = nil, nil, ""
local M = {}
local rows = {}

local clean = ns.Clean

local function bank(name) return Enum.SpellBookSpellBank[name] end

-- A pet spell's autocast: allowed, then on.
local function autocast(s)
	if s.bank ~= bank("Pet") then return false, false end
	local allowed, on = C_SpellBook.GetSpellBookItemAutoCast(s.slot, s.bank)
	return clean(allowed) or false, clean(on) or false
end

-- The categories: every shown skill line (General, the class's), then the pet's.
local function categories()
	local list = {}
	for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local info = C_SpellBook.GetSpellBookSkillLineInfo(i)
		if info and not info.shouldHide then
			list[#list + 1] = { key = "line" .. i, label = info.name, icon = i == 1 and "compact" or "bolt",
				offset = info.itemIndexOffset, n = info.numSpellBookItems, bank = bank("Player") }
		end
	end
	local pet = C_SpellBook.HasPetSpells()
	if pet and pet > 0 and (not PetHasSpellbook or PetHasSpellbook()) then
		list[#list + 1] = { key = "pet", label = PET or "Pet", icon = "star", offset = 0, n = pet, bank = bank("Pet") }
	end
	return list
end

local FLYOUT = Enum.SpellBookItemType.Flyout
local open = {} -- the flyouts opened, by flyout ID

-- A flyout's spells the player knows, as entries of the book (each is a
-- loose spell of the book too): GetFlyoutSlotInfo, as the stock flyout.
local function flyoutSpells(id)
	local out = {}
	local _, _, n = GetFlyoutInfo(id)
	for i = 1, n or 0 do
		local spellID, _, known = GetFlyoutSlotInfo(id, i)
		local slot, bank = C_SpellBook.FindSpellBookSlotForSpell(spellID)
		local info = known and slot and C_SpellBook.GetSpellBookItemInfo(slot, bank)
		if info then out[#out + 1] = { slot = slot, bank = bank, info = info, member = true } end
	end
	return out
end

-- A category's spells as the stock book shows them: its passives and lower
-- ranks per the stock settings (the same CVars), which a search ignores, as
-- the stock book's does. Flyouts per its "Use flyouts" (spellBookHideFlyouts):
-- on, a flyout is one entry and its loose spells are left out, an opened one
-- listing its spells after it; off, its loose spells instead. A search looks
-- at the loose spells.
local function spells(cat, out, match)
	local hidePassive = not match and GetCVarBool("spellBookHidePassives")
	local allRanks = match or GetCVarBool("ShowAllSpellRanks")
	local flyouts = not match and not GetCVarBool("spellBookHideFlyouts")
	local loose = C_SpellBook.IsSpellBookItemLooseFlyoutMember
	for slot = cat.offset + 1, cat.offset + cat.n do
		local info = C_SpellBook.GetSpellBookItemInfo(slot, cat.bank)
		local t = info and info.itemType
		local name = info and clean(info.name)
		if name and t ~= Enum.SpellBookItemType.None
			and (flyouts or t ~= FLYOUT)
			and not (flyouts and loose and loose(slot, cat.bank))
			and not (hidePassive and info.isPassive)
			and (allRanks or not (C_SpellBook.IsSpellBookItemLowRank and C_SpellBook.IsSpellBookItemLowRank(slot, cat.bank)))
			and (not match or name:lower():find(match, 1, true)) then
			out[#out + 1] = { slot = slot, bank = cat.bank, info = info }
			if t == FLYOUT and open[info.actionID] then
				for _, s in ipairs(flyoutSpells(info.actionID)) do out[#out + 1] = s end
			end
		end
	end
	return out
end

-- The line under a spell's name: "Rank 4 · 95 Mana · 3 sec", "Passive",
-- "Learn at level 20".
local function detail(s)
	local info = s.info
	if info.itemType == Enum.SpellBookItemType.FutureSpell then
		local lvl = C_SpellBook.GetSpellBookItemLevelLearned(s.slot, s.bank)
		return lvl and lvl > 0 and ("Learn at level %d"):format(lvl) or "Not learned yet"
	end
	if info.isPassive then return "Passive" end
	if info.itemType == FLYOUT then
		local _, _, n = GetFlyoutInfo(info.actionID)
		return n == 1 and "1 spell" or ("%d spells"):format(n or 0)
	end
	local parts = {}
	local allowed, on = autocast(s)
	if allowed then parts[1] = on and "Autocast on" or "Autocast off" end
	local rank = clean(info.subName)
	if rank and rank ~= "" then parts[#parts + 1] = rank end
	local id = info.spellID
	if id then
		for _, c in ipairs(C_Spell.GetSpellPowerCost(id) or {}) do
			local cost = clean(c.cost)
			if cost and cost > 0 then
				parts[#parts + 1] = ("%d %s"):format(cost, _G[c.name] or c.name)
				break
			end
		end
		local sp = C_Spell.GetSpellInfo(id)
		local ms = sp and clean(sp.castTime)
		if ms then parts[#parts + 1] = ms > 0 and ("%g sec"):format(math.floor(ms / 100 + 0.5) / 10) or "Instant" end
	end
	return table.concat(parts, " · ")
end

local function castable(s)
	local t = s.info.itemType
	-- Pet commands (Attack, Follow) are pet actions, not spells: cast by name
	-- they would be the player's own. They drag to the pet bar instead.
	return not s.info.isPassive and t == Enum.SpellBookItemType.Spell and not s.info.isOffSpec
end

local function rowEnter(r)
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetSpellBookItem(r.psSpell.slot, r.psSpell.bank)
	if r.psSpell.info.itemType == FLYOUT then
		ns.TooltipHint((open[r.psSpell.info.actionID] and "Click to hide its spells. " or "Click to show its spells. ")
			.. "Drag it to an action bar. Shift-click to link it in chat.")
	elseif r.psSpell.info.itemType ~= Enum.SpellBookItemType.FutureSpell then
		local hint = castable(r.psSpell) and "Click to cast it. " or ""
		if autocast(r.psSpell) then hint = hint .. "Right-click to turn its autocast on or off. " end
		ns.TooltipHint(hint .. "Drag it to an action bar. Shift-click to link it in chat.")
	end
	GameTooltip:Show()
end

-- Shift-click links it (into the macro text when that is open), as the stock
-- book. A click on a flyout shows its spells after it, or hides them.
local function rowClick(r)
	local s = r.psSpell
	if s and s.info.itemType == FLYOUT and not IsModifiedClick() then
		open[s.info.actionID] = not open[s.info.actionID] or nil
		M.Show()
		if GameTooltip:GetOwner() == r or GameTooltip:GetOwner() == PolestarUISpellbookCast then rowEnter(r) end
		return
	end
	if not (s and IsModifiedClick("CHATLINK")) then return end
	if MacroFrameText and MacroFrameText:HasFocus() then
		ChatFrameUtil.InsertLink(s.info.name)
	else
		ChatFrameUtil.InsertLink(C_SpellBook.GetSpellBookItemLink(s.slot, s.bank))
	end
end

-- The client blocks a spell pickup from addon code in combat (docs/CLIENT.md, rule 4).
local function pickup(r)
	local s = r.psSpell
	if InCombatLockdown() then return end
	if s and s.info.itemType ~= Enum.SpellBookItemType.FutureSpell then C_SpellBook.PickupSpellBookItem(s.slot, s.bank) end
end

-- Casting is protected. So out of combat one secure button takes the hovered
-- row's place (ns.Overlay), its left click the game's "spell" action;
-- everything else (drag, link) it hands back to the row. In combat the rows
-- still link; dragging waits for the fight to end.
local overRow = ns.Overlay("PolestarUISpellbookCast", {
	enter = rowEnter,
	pickup = pickup,
	setup = function(over)
		over:HookScript("PostClick", function(self) rowClick(self.psTarget) end)
	end,
	attrs = function(over, r)
		local s = r.psSpell
		-- The player's spells by ID (that rank exactly); the pet's by name, as a macro casts them.
		over:SetAttribute("type1", castable(s) and "spell" or nil)
		over:SetAttribute("spell", s.bank == bank("Pet") and s.info.name or s.info.spellID)
		-- Autocast is protected too: the game's own slash command, as a macro runs it.
		local auto = autocast(s)
		over:SetAttribute("type2", auto and "macro" or nil)
		over:SetAttribute("macrotext", auto and ((SLASH_PET_AUTOCASTTOGGLE1 or "/petautocasttoggle") .. " " .. s.info.name) or nil)
	end,
})

local function newRow(parent)
	local r = CreateFrame("Button", nil, parent)
	r:SetHeight(ICON)
	W.Hover(r)
	local well
	well, r.Icon = ns.ItemWell(r, ICON)
	well:SetPoint("LEFT", r, "LEFT", 0, 0)
	r.Well = well
	r.Cooldown = CreateFrame("Cooldown", nil, well, "CooldownFrameTemplate")
	r.Cooldown:SetAllPoints(r.Icon)
	r.Name = W.Text(r, "label", "text")
	r.Sub = W.Text(r, "small", "textDim")
	r.Sub:SetPoint("TOPLEFT", well, "RIGHT", 12, -3)
	r.Sub:SetPoint("RIGHT", r, "RIGHT", -8, 0)
	for _, t in ipairs({ r.Name, r.Sub }) do t:SetJustifyH("LEFT") end
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:RegisterForDrag("LeftButton")
	r:SetScript("OnClick", rowClick)
	r:SetScript("OnDragStart", pickup)
	r:SetScript("OnEnter", function(self)
		rowEnter(self)
		overRow(self)
	end)
	r:SetScript("OnLeave", W.HideTooltip)
	return r
end

-- The stock book's sweep; the client may hand the times over secret in
-- combat, which the sweep takes but our code cannot test (docs/CLIENT.md, rule 3).
local function paintCooldown(r)
	local s = r.psSpell
	if not (s and s.info.itemType ~= Enum.SpellBookItemType.FutureSpell) then return r.Cooldown:Clear() end
	-- A duration object: the client's way to hand a cooldown that may be secret
	-- (in combat) to addon code; SetCooldown refuses secret times from us.
	local getDuration = C_SpellBook.GetSpellBookItemCooldownDuration
	if getDuration and r.Cooldown.SetCooldownFromDurationObject then
		local d = getDuration(s.slot, s.bank)
		if d then r.Cooldown:SetCooldownFromDurationObject(d) else r.Cooldown:Clear() end
		return
	end
	local cd = C_SpellBook.GetSpellBookItemCooldown(s.slot, s.bank)
	if cd and ((issecretvalue and issecretvalue(cd.isEnabled)) or cd.isEnabled) then
		r.Cooldown:SetCooldown(cd.startTime, cd.duration, cd.modRate)
	else
		r.Cooldown:Clear()
	end
end

local function paintRow(r, s)
	r.psSpell = s
	local future = s.info.itemType == Enum.SpellBookItemType.FutureSpell
	r.Icon:SetTexture(s.info.iconID)
	r.Icon:SetDesaturated(future)
	r.Name:SetText(s.info.name)
	W.Color(r.Name, future and "textMuted" or "text")
	local sub = detail(s)
	r.Sub:SetText(sub)
	W.Color(r.Sub, future and "textMuted" or "textDim")
	-- With no second line the name sits on the well's middle.
	r.Name:ClearAllPoints()
	r.Name:SetPoint(sub ~= "" and "BOTTOMLEFT" or "LEFT", r.Well, "RIGHT", 12, sub ~= "" and 1 or 0)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -8, 0)
	-- Autocast on: the well's hairline in the accent.
	local _, on = autocast(s)
	if on then
		local cr, cg, cb = Polestar.Theme.Color("accent")
		Polestar.Theme.Border(r.Well, cr, cg, cb, 1)
	else
		Polestar.Theme.Border(r.Well, Polestar.Theme.Wash("border"))
	end
	paintCooldown(r)
end

-- A spellbook row for other windows' spells (the Professions window's).
ns.SpellRow = { New = newRow, Paint = paintRow, PaintCooldown = paintCooldown }

-- Two columns of rows, in book order down the left column, then the right.
-- Returns the body height.
local function paintList(list)
	local col = (f.BodyWidth - COL_GAP) / 2
	local half = math.ceil(#list / 2)
	for i, s in ipairs(list) do
		local r = rows[i] or newRow(f.Body)
		rows[i] = r
		local c, k = i <= half and 0 or 1, i <= half and i or i - half
		r:ClearAllPoints()
		-- A flyout's spells sit indented under it.
		local indent = s.member and 24 or 0
		r:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad + c * (col + COL_GAP) + indent, -(24 + (k - 1) * ROW_H))
		r:SetWidth(col - indent)
		paintRow(r, s)
		r:Show()
	end
	for i = #list + 1, #rows do rows[i]:Hide() end
	f.psEmpty:SetShown(#list == 0)
	return 24 + half * ROW_H
end

-- WhatsTraining shows its own window from the launcher it registers.
local function whatsTraining()
	local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
	return ldb and ldb:GetDataObjectByName("WhatsTrainingMinimap")
end

-- The stock book's settings (its CVars), as its settings menu: no ranks for
-- Rogue and Warrior.
local function settings()
	local list = { { "spellBookHidePassives", SPELLBOOK_FILTER_PASSIVES or "Hide passives" },
		{ "spellBookHideFlyouts", SPELLBOOK_USE_FLYOUTS or "Use flyouts", true } }
	local _, cls = UnitClass("player")
	if cls ~= "ROGUE" and cls ~= "WARRIOR" then list[#list + 1] = { "ShowAllSpellRanks", SHOW_ALL_SPELL_RANKS or "Show all ranks" } end
	return list
end

local function default(cvar) return C_CVar and C_CVar.GetCVarDefault and C_CVar.GetCVarDefault(cvar) or "0" end

-- The filter menu: each setting, then "Clear filters" while one is off its
-- default. A search ignores them, so they wait while one runs, as stock.
-- -> items, whether one is off its default.
local function filterItems()
	local items, any = {}, false
	for _, s in ipairs(settings()) do
		local cvar = s[1]
		any = any or (GetCVar(cvar) or "0") ~= default(cvar)
		-- "Use flyouts" is checked while the CVar (hide them) is off.
		items[#items + 1] = { text = s[2], checked = GetCVarBool(cvar) ~= (s[3] or false), disabled = query ~= "", onClick = function()
			SetCVar(cvar, GetCVarBool(cvar) and "0" or "1")
			M.Show()
			W.ShowMenu(f.psFilter, (filterItems()), { minWidth = 200 })
		end }
	end
	if any then
		items[#items + 1] = { separator = true }
		items[#items + 1] = { text = "Clear filters", onClick = function()
			for _, s in ipairs(settings()) do SetCVar(s[1], default(s[1])) end
			M.Show()
		end }
	end
	return items, any
end

local function optionsItems(self)
	local items = {
		{ text = "Game's spellbook: shift-click its micro button", disabled = true },
	}
	local wt = whatsTraining()
	if wt and wt.OnClick then
		items[#items + 1] = { text = "What's Training?", onClick = function() wt.OnClick(self, "LeftButton") end }
	end
	return items
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", searchPlaceholder = "Search spells", onSearch = function(text)
		query = (text or ""):lower()
		if f:IsShown() then M.Show() end
	end })
	ns.Dock(f)
	ns.WindowMenu(f, "spellbook")
	-- The subject block names the window, in place of Polestar's lockup.
	local b = ns.SubjectBlock(f)
	f.psClass, f.psName, f.psLine = b.icon, b.name, b.line
	-- The ways to the stock book's own view, on the band.
	f.psOptions = ns.OptionsButton(f, optionsItems)
	-- The stock book's settings act on the list: a filter at the end of the
	-- search row, as Crafting's, its glyph in the accent while one is off its default.
	local top = W.SHELL.header - 30
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + 30 + 6), -top)
	f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		W.ShowMenu(self, (filterItems()), { minWidth = 200 })
	end, 14)
	f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -top)
	Polestar.Theme.Skin(f.psFilter, "editbox")
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psEmpty:SetText("No spells here.")
	-- The stock window's sounds: it never opens now to play them.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.UI_CLASS_TALENT_OPEN_WINDOW) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.UI_CLASS_TALENT_CLOSE_WINDOW) end)
	Polestar.CloseOnEscape(NAME)
end

local function refresh()
	local cats = categories()
	local found = false
	for _, c in ipairs(cats) do if c.key == section then found = true end end
	if not found then section = cats[1] and cats[1].key end
	f.psName:SetText(UnitClass("player"))
	f.psLine:SetText(("Level %d"):format(UnitLevel("player")))
	f.psClass:SetAtlas(GetClassAtlas(strlower(select(2, UnitClass("player")))))
	W.SetIconState(f.psFilter, select(2, filterItems()))
	local list = {}
	if query ~= "" then
		for _, c in ipairs(cats) do spells(c, list, query) end
		W.ShellNav(f, cats, nil, function(k) section = k; f.Search:SetText(""); M.Show() end)
		W.ShellTitle(f, "Search", (#list == 1 and "1 spell" or #list .. " spells") .. " match.")
	else
		local cur
		for _, c in ipairs(cats) do if c.key == section then cur = c end end
		W.ShellNav(f, cats, section, function(k) section = k; M.Show() end)
		if cur then spells(cur, list) end
		-- An opened flyout's spells are not counted again.
		local n = 0
		for _, s in ipairs(list) do if not s.member then n = n + 1 end end
		W.ShellTitle(f, cur and cur.label or "", n == 1 and "1 spell." or n .. " spells.")
	end
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, {})
	W.ShellBody(f, paintList(list))
end

function M.Show(key)
	if not f then build() end
	section = key or section
	refresh()
	f:Show()
end

function M.Toggle(key)
	if f and f:IsShown() and (key == nil or key == section) then f:Hide() else M.Show(key) end
end

function M.Enable()
	-- The spellbook keys and micro button open ours; the stock window is never
	-- touched (docs/CLIENT.md, rule 8). A spell link and a new-spell toast stay
	-- the game's.
	ns.Doors("spellbook", "Spellbook", { TOGGLESPELLBOOK = function() M.Toggle() end, TOGGLEPETBOOK = function() M.Toggle("pet") end },
		SpellbookMicroButton, function() M.Toggle() end)
	local function changed() if f and f:IsShown() then refresh() end end
	Polestar.RegisterEvent("SPELLS_CHANGED", changed)
	Polestar.RegisterEvent("PET_BAR_UPDATE", changed) -- autocast turned on or off
	Polestar.RegisterEvent("SPELL_UPDATE_COOLDOWN", function()
		if not (f and f:IsShown()) then return end
		for _, row in ipairs(rows) do if row:IsShown() then paintCooldown(row) end end
	end)
	Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", changed)
	Polestar.RegisterEvent("UNIT_PET", function(_, unit) if unit == "player" then changed() end end)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame:IsShown() and PlayerSpellsFrame end

ns.Module("spellbook", M)
