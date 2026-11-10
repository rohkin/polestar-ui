-- The Spellbook (docs/DESIGN.md, "Spellbook"): the stock spellbook tab of
-- PlayerSpellsFrame in a Polestar shell. Talents are Talents.lua's.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUISpellbook"
local ROW_H, ICON, COL_GAP = 44, 36, 24

local f, section, query = nil, nil, ""
local M = {}
local rows = {}

-- Spell text the client may hand over secret in combat (docs/CLIENT.md, rule 3).
local function clean(v)
	if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
	return v
end

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

-- A category's spells as the stock book shows them: its passives and lower
-- ranks per the stock settings (the same CVars), flyouts as their loose spells.
local function spells(cat, out, match)
	local hidePassive, allRanks = GetCVarBool("spellBookHidePassives"), GetCVarBool("ShowAllSpellRanks")
	for slot = cat.offset + 1, cat.offset + cat.n do
		local info = C_SpellBook.GetSpellBookItemInfo(slot, cat.bank)
		local t = info and info.itemType
		local name = info and clean(info.name)
		if name and t ~= Enum.SpellBookItemType.None and t ~= Enum.SpellBookItemType.Flyout
			and not (hidePassive and info.isPassive)
			and (allRanks or not (C_SpellBook.IsSpellBookItemLowRank and C_SpellBook.IsSpellBookItemLowRank(slot, cat.bank)))
			and (not match or name:lower():find(match, 1, true)) then
			out[#out + 1] = { slot = slot, bank = cat.bank, info = info }
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
	if r.psSpell.info.itemType ~= Enum.SpellBookItemType.FutureSpell then
		local hint = castable(r.psSpell) and "Click to cast it. " or ""
		if autocast(r.psSpell) then hint = hint .. "Right-click to turn its autocast on or off. " end
		ns.TooltipHint(hint .. "Drag it to an action bar. Shift-click to link it in chat.")
	end
	GameTooltip:Show()
end

-- Shift-click links it (into the macro text when that is open), as the stock book.
local function rowClick(r)
	local s = r.psSpell
	if not (s and IsModifiedClick("CHATLINK")) then return end
	if MacroFrameText and MacroFrameText:HasFocus() then
		ChatFrameUtil.InsertLink(s.info.name)
	else
		ChatFrameUtil.InsertLink(C_SpellBook.GetSpellBookItemLink(s.slot, s.bank))
	end
end

local function pickup(r)
	local s = r.psSpell
	if s and s.info.itemType ~= Enum.SpellBookItemType.FutureSpell then C_SpellBook.PickupSpellBookItem(s.slot, s.bank) end
end

-- Casting is protected. So out of combat one secure button takes the hovered
-- row's place (ns.Overlay), its left click the game's "spell" action;
-- everything else (drag, link) it hands back to the row. In combat the rows
-- still drag and link.
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
	local well = CreateFrame("Frame", nil, r)
	well:SetSize(ICON, ICON)
	well:SetPoint("LEFT", r, "LEFT", 0, 0)
	Polestar.Theme.Skin(well, "inset")
	Polestar.Theme.Border(well, Polestar.Theme.Wash("border"))
	r.Icon = ns.GameIcon(well)
	r.Icon:SetPoint("TOPLEFT", 1, -1)
	r.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	r.Well = well
	r.Cooldown = CreateFrame("Cooldown", nil, well, "CooldownFrameTemplate")
	r.Cooldown:SetAllPoints(r.Icon)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("BOTTOMLEFT", well, "RIGHT", 12, 1)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -8, 0)
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
	r.Sub:SetText(detail(s))
	W.Color(r.Sub, future and "textMuted" or "textDim")
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
		r:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad + c * (col + COL_GAP), -(24 + (k - 1) * ROW_H))
		r:SetWidth(col)
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

local function optionsMenu(self)
	if W.MenuShown(self) then return W.HideMenu() end
	local function flip(cvar) return function() SetCVar(cvar, GetCVarBool(cvar) and "0" or "1"); M.Show() end end
	local items = {
		{ text = "Show passive spells", checked = not GetCVarBool("spellBookHidePassives"), onClick = flip("spellBookHidePassives") },
		{ text = "Show all ranks", checked = GetCVarBool("ShowAllSpellRanks"), onClick = flip("ShowAllSpellRanks") },
		{ separator = true },
		{ text = "Game's spellbook: shift-click its micro button", disabled = true },
	}
	local wt = whatsTraining()
	if wt and wt.OnClick then
		items[#items + 1] = { text = "What's Training?", onClick = function() wt.OnClick(self, "LeftButton") end }
	end
	W.ShowMenu(self, items, { minWidth = 200 })
end

local function build()
	f = W.Shell(NAME, { searchPlaceholder = "Search spells", onSearch = function(text)
		query = (text or ""):lower()
		if f:IsShown() then M.Show() end
	end })
	ns.Dock(f)
	-- The subject block names the window, in place of Polestar's lockup.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Status, f.Stage }) do r:SetParent(holder) end
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
	for _, t in ipairs({ f.psName, f.psLine }) do t:SetWidth(f.Sidebar:GetWidth() - (24 + 36 + 12) - 24) end
	-- The stock book's settings and the ways to its own view, on the band.
	local opt = CreateFrame("Button", nil, f.Header)
	opt:SetSize(96, 24)
	opt:SetPoint("BOTTOMRIGHT", f.Header, "BOTTOMRIGHT", -20, 12)
	W.Hover(opt)
	opt.Label = W.Text(opt, "small", "text")
	opt.Label:SetPoint("LEFT", opt, "LEFT", 10, 0)
	opt.Label:SetText("Options")
	opt.Arrow = W.Tex(opt, "ARTWORK", "chevron-down", "textDim")
	opt.Arrow:SetSize(12, 12)
	opt.Arrow:SetPoint("RIGHT", opt, "RIGHT", -10, 0)
	opt:SetScript("OnClick", optionsMenu)
	f.psOptions = opt
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
	f.psClass:SetTexture("Interface\\Icons\\ClassIcon_" .. select(2, UnitClass("player")))
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
		W.ShellTitle(f, cur and cur.label or "", section == "pet" and "Your pet's abilities. Click one to use it, or drag it to the pet bar."
			or "Click a spell to cast it, or drag it to your action bars.")
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
	ns.Doors("Spellbook", { TOGGLESPELLBOOK = function() M.Toggle() end, TOGGLEPETBOOK = function() M.Toggle("pet") end },
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

ns.Module("spellbook", M)
