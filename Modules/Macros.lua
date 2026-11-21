-- Macros (docs/windows/macros.md): the stock MacroFrame (Blizzard_MacroUI)
-- in a Polestar shell: the general and character macros, the body editor
-- and the icon picker (the stock MacroPopupFrame) as a flyout.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUIMacros"
local ICON, CELL, CELL_H, GAP = 40, 56, 58, 8 -- the macro grid: a well, its name under it
local GRID_ROWS, EDIT_H, LETTERS = 2, 132, 255
local PICK_W, PICK_ICON, PICK_GAP = 336, 36, 6 -- the icon picker
local QUESTION = 134400 -- the "?" icon: the macro shows its spell's icon
local LOCKED = "Macros cannot change in combat."

local f, p -- the window, the icon picker
local tab, selected = "general", nil -- selected: the index in the tab
local changed, pending -- the body typed and not saved; { index, text } saved when the fight ends
local M = {}

local function maxes()
	local c = Constants and Constants.MacroConsts
	return c and c.MAX_ACCOUNT_MACROS or 120, c and c.MAX_CHARACTER_MACROS or 30
end
local function base() return tab == "character" and (maxes()) or 0 end
local function cap() local a, c = maxes(); return tab == "character" and c or a end
local function count() local a, c = GetNumMacros(); return tab == "character" and c or a end
local function actual(i) return base() + i end

-- The player's name, kept from out of combat (secret in it: docs/CLIENT.md, rule 3).
local who
local function player()
	who = ns.Clean(UnitName("player")) or who
	return who or "Character"
end

local function label(key)
	if key == "character" then return (CHARACTER_SPECIFIC_MACROS or "%s Specific Macros"):format(player()) end
	return GENERAL_MACROS or "General Macros"
end

-- The body as saved, or as typed before a fight and not yet saved.
local function savedBody(i)
	if pending and pending[1] == i then return pending[2] end
	return select(3, GetMacroInfo(i)) or ""
end

-- Saves the body typed into the selected macro, as the stock SaveMacro; in
-- combat, when the fight ends (EditMacro is refused in it).
local function save()
	if not (changed and selected) then return end
	local i, text = actual(selected), f.psEdit:GetText() or ""
	changed = nil
	if InCombatLockdown() then pending = { i, text } return end
	EditMacro(i, nil, nil, text)
end

-- A pickup for an action bar; none in combat, when no bar takes it.
local function pickup(i)
	if i and not InCombatLockdown() then ns.Pickup(PickupMacro, actual(i)) end
end

---------------------------------------------------------------------------
-- The icon picker (the stock MacroPopupFrame)
---------------------------------------------------------------------------

-- The stock list (IconDataProviderMixin, IconDataProviderOverrides), in a
-- table of our own: "?", the spellbook's icons, then the spell icons and the
-- item icons. The stock provider's table is file-local to its code; filling
-- it from ours would leave our values in it.
local function iconList(filter)
	local out, seen = { QUESTION }, {}
	local function add(t) if t and not seen[t] then seen[t] = true; out[#out + 1] = t end end
	if filter ~= "item" and C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
		local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
		local T = Enum.SpellBookItemType or {}
		for l = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local info = C_SpellBook.GetSpellBookSkillLineInfo(l)
			for k = 1, info and info.numSpellBookItems or 0 do
				local slot = info.itemIndexOffset + k
				local kind, id = C_SpellBook.GetSpellBookItemType(slot, bank)
				if kind ~= "FUTURESPELL" and kind ~= T.FutureSpell then add(C_SpellBook.GetSpellBookItemTexture(slot, bank)) end
				if (kind == "FLYOUT" or kind == T.Flyout) and GetFlyoutInfo then
					local _, _, n, known = GetFlyoutInfo(id)
					for s = 1, known and n or 0 do
						local spell, _, slotKnown = GetFlyoutSlotInfo(id, s)
						if slotKnown then add(C_Spell.GetSpellTexture(spell)) end
					end
				end
			end
		end
	end
	local lists = {}
	if filter ~= "item" then lists[#lists + 1] = { GetLooseMacroIcons, GetMacroIcons } end
	if filter ~= "spell" then lists[#lists + 1] = { GetLooseMacroItemIcons, GetMacroItemIcons } end
	for _, fns in ipairs(lists) do
		local t = {}
		for _, fn in ipairs(fns) do if fn then fn(t) end end
		-- A name is an icon under Interface\Icons; a number is its file.
		for _, v in ipairs(t) do out[#out + 1] = tonumber(v) or ("INTERFACE\\ICONS\\" .. v) end
	end
	return out
end

local function pickIndex(icon)
	if icon == QUESTION then return 1 end
	for i, v in ipairs(p.psIcons) do if v == icon then return i end end
end

local function paintChosen()
	p.Chosen.Icon:SetTexture(p.psIcon)
	local listed = pickIndex(p.psIcon) ~= nil
	p.ChosenText:SetText(listed and (ICON_SELECTION_CLICK or "Click on an icon to set it as the macro's icon.")
		or (ICON_SELECTION_NOTINLIST or "The current icon is not in the list."))
	W.Color(p.ChosenText, listed and "textDim" or "textMuted")
end

-- The picker's grid, only the rows in sight (a few thousand icons).
local function paintIcons()
	local sf, cols = p.Scroll, p.psCols
	local step = PICK_ICON + PICK_GAP
	local rows = math.ceil(#p.psIcons / cols)
	W.SetScrollContent(sf, rows * step - PICK_GAP, sf:GetHeight())
	local first = math.floor(sf:GetVerticalScroll() / step)
	p.psDrawn = sf:GetVerticalScroll()
	local seen = math.ceil(sf:GetHeight() / step) + 1
	for k, w in ipairs(p.Wells) do
		local i = first * cols + k
		local icon = k <= seen * cols and p.psIcons[i]
		w:SetShown(icon ~= nil and icon ~= false)
		if icon then
			w.psIcon = icon
			w:ClearAllPoints()
			w:SetPoint("TOPLEFT", sf.Child, "TOPLEFT", ((i - 1) % cols) * step, -math.floor((i - 1) / cols) * step)
			w.Icon:SetTexture(icon)
			if icon == p.psIcon then Theme.Border(w, Theme.Color("accent")) else Theme.Border(w, Theme.Wash("border")) end
		end
	end
end

-- Okay: on with a name, out of combat (CreateMacro, EditMacro).
local function canOkay()
	local name = (p.Name:GetText() or ""):gsub("\"", "")
	ns.SetEnabled(p.Okay, name ~= "" and not InCombatLockdown(), InCombatLockdown() and LOCKED or "Enter a name.")
	return name ~= "" and not InCombatLockdown() and name
end

local function closePicker() if p and p:IsShown() then p:Hide() end end

local function choose(icon)
	p.psIcon = icon
	paintChosen()
	paintIcons()
end

-- An item, spell, mount, battle pet or macro dropped on the picker gives
-- its icon, as the stock drag area (IconSelectorPopupFrameTemplateMixin:SetIconFromMouse).
local function fromCursor()
	local kind, id, _, spellID = GetCursorInfo()
	local icon
	if kind == "item" then icon = select(10, C_Item.GetItemInfo(id))
	elseif kind == "spell" then icon = C_Spell.GetSpellTexture(spellID)
	elseif kind == "mount" then icon = select(3, C_MountJournal.GetMountInfoByID(id))
	elseif kind == "battlepet" then icon = select(9, C_PetJournal.GetPetInfoByPetID(id))
	elseif kind == "macro" then icon = select(2, GetMacroInfo(id))
	elseif kind == "outfit" and C_TransmogOutfitInfo then
		local o = C_TransmogOutfitInfo.GetOutfitInfo(id)
		icon = o and o.icon
	else return false end
	ClearCursor()
	if icon then choose(icon) end
	return true
end

local function okay()
	local name = canOkay()
	if not name then return end
	-- A name the client keeps: Interface\Icons names without the folder.
	local icon = type(p.psIcon) == "string" and p.psIcon:gsub("^INTERFACE\\ICONS\\", "") or p.psIcon
	local i
	if p.psMode == "new" then
		i = CreateMacro(name, icon, nil, tab == "character")
	else
		i = EditMacro(actual(selected), name, icon)
	end
	local new = p.psMode == "new"
	closePicker()
	if i then selected = i - base() end
	M.Refresh(true)
	-- A new macro's body takes the keys, as stock.
	if new and i then f.psEdit:SetFocus() end
end

local function buildPicker()
	p = ns.Flyout(f, NAME .. "Icons", PICK_W)
	p:Hide()
	local w = PICK_W - 48
	p.Title = W.Text(p, "heading", "text")
	p.Title:SetPoint("TOPLEFT", p, "TOPLEFT", 24, -24)
	local nameLabel = W.Text(p, "small", "textDim")
	nameLabel:SetPoint("TOPLEFT", p, "TOPLEFT", 24, -62)
	nameLabel:SetText(MACRO_POPUP_TEXT or "Enter macro name (16 characters max):")
	p.Name = ns.TextField(p, w, 16)
	p.Name:SetPoint("TOPLEFT", p, "TOPLEFT", 24, -80)
	p.Name:SetScript("OnTextChanged", function() canOkay() end)
	p.Name:SetScript("OnEnterPressed", okay)
	p.Name:SetScript("OnEscapePressed", closePicker)
	p.Chosen = ns.ItemWell(p, 44)
	p.Chosen:SetPoint("TOPLEFT", p, "TOPLEFT", 24, -126)
	local head = W.Text(p, "label", "text")
	head:SetPoint("TOPLEFT", p.Chosen, "TOPRIGHT", 12, -2)
	head:SetText(ICON_SELECTION_TITLE_CURRENT or "Current Selection:")
	p.ChosenText = W.Text(p, "small", "textDim")
	p.ChosenText:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -4)
	p.ChosenText:SetWidth(w - 44 - 12 - 36)
	p.ChosenText:SetJustifyH("LEFT")
	p.ChosenText:SetWordWrap(true)
	p.ChosenText:SetHeight(28)
	p.ChosenText:SetJustifyV("TOP")
	-- The stock icon filter (All, Spells, Items).
	local filters = { { "all", ICON_FILTER_ALL or "All" }, { "spell", ICON_FILTER_SPELL or "Spells" }, { "item", ICON_FILTER_ITEM or "Items" } }
	p.Filter = W.IconButton(p, "sliders", 30, "Filter", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		local items = {}
		for _, fl in ipairs(filters) do
			items[#items + 1] = { text = fl[2], checked = p.psFilter == fl[1], onClick = function()
				p.psFilter = fl[1]
				p.psIcons = iconList(fl[1])
				W.SetIconState(p.Filter, fl[1] ~= "all")
				W.ScrollTo(p.Scroll, 0)
				choose(p.psIcon)
			end }
		end
		W.ShowMenu(self, items)
	end, 14)
	Theme.Skin(p.Filter, "editbox")
	p.Filter:SetPoint("RIGHT", p, "RIGHT", -24, 0)
	p.Filter:SetPoint("TOP", p.Chosen, "TOP", 0, -7)
	p.Okay = W.Button(p, OKAY or "Okay", okay, { primary = true })
	p.Okay:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -24, 16)
	local cancel = W.Button(p, CANCEL or "Cancel", closePicker)
	cancel:SetPoint("RIGHT", p.Okay, "LEFT", -8, 0)
	p.Scroll = W.Scroll(p)
	-- Sized, not anchored at both ends: its rows are counted from its height.
	p.Scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 24, -186)
	p.Scroll:SetSize(w + 10, f:GetHeight() - 186 - (16 + 30 + 16))
	p.psCols = math.floor((w + PICK_GAP) / (PICK_ICON + PICK_GAP))
	-- Enough wells for the rows in sight, moved as it scrolls.
	p.Wells = {}
	for k = 1, p.psCols * (math.ceil(p.Scroll:GetHeight() / (PICK_ICON + PICK_GAP)) + 1) do
		local well = ns.ItemWell(p.Scroll.Child, PICK_ICON, "Button")
		W.Hover(well)
		well:SetScript("OnClick", function(self) if not fromCursor() then choose(self.psIcon) end end)
		well:SetScript("OnReceiveDrag", fromCursor)
		p.Wells[k] = well
	end
	p:SetScript("OnReceiveDrag", fromCursor)
	p:SetScript("OnMouseUp", fromCursor)
	p:SetScript("OnUpdate", function() if p.Scroll:GetVerticalScroll() ~= p.psDrawn then paintIcons() end end)
	-- The icon list is let go with the picker, as the stock provider's.
	p:SetScript("OnHide", function() p.psIcons = nil; if f:IsShown() then M.Refresh() end end)
	ns.DockFlyout(f, p)
end

-- The picker for a new macro ("?", no name) or the selected one's name and icon.
local function openPicker(mode)
	save()
	if not p then buildPicker() end
	p.psMode = mode
	p.psFilter = "all"
	p.psIcons = iconList("all")
	W.SetIconState(p.Filter, false)
	p.Title:SetText(mode == "new" and "New macro" or "Change name and icon")
	if mode == "new" then
		p.Name:SetText("")
		p.psIcon = QUESTION
	else
		local i = actual(selected)
		p.Name:SetText(GetMacroInfo(i) or "")
		p.Name:HighlightText()
		p.psIcon = C_Macro.GetSelectedMacroIcon(i)
	end
	p:Show()
	-- Its width past the dock's room closes the oldest docked window: this
	-- one, when another opened after it (Core.lua layout), the picker with it.
	if not p:IsShown() then return end
	W.ScrollTo(p.Scroll, 0)
	choose(p.psIcon) -- sizes the grid first: a scroll is kept within it
	local at = pickIndex(p.psIcon)
	if at then
		W.ScrollTo(p.Scroll, math.floor((at - 1) / p.psCols) * (PICK_ICON + PICK_GAP))
		paintIcons()
	end
	canOkay()
	p.Name:SetFocus()
	M.Refresh()
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------

local function select_(i)
	save()
	closePicker()
	selected = i
	changed = nil
	f.psEdit:ClearFocus()
	M.Refresh(true)
end

local function cellEnter(c)
	GameTooltip:SetOwner(c, "ANCHOR_RIGHT")
	GameTooltip:SetText(GetMacroInfo(actual(c.psIndex)) or "", 1, 1, 1)
	ns.TooltipHint(InCombatLockdown() and "Click to read it. Drag it to an action bar after the fight."
		or "Click to edit it. Drag it to an action bar.")
	GameTooltip:Show()
end

local function newCell(parent)
	local c = CreateFrame("Button", nil, parent)
	c:SetSize(CELL, CELL_H)
	c.Well = ns.ItemWell(c, ICON)
	c.Well:SetPoint("TOP", c, "TOP", 0, 0)
	W.Hover(c.Well)
	c.Name = W.Text(c, "small", "textDim")
	c.Name:SetPoint("TOP", c.Well, "BOTTOM", 0, -4)
	c.Name:SetWidth(CELL)
	c.Name:SetWordWrap(false)
	c.Name:SetJustifyH("CENTER")
	c:RegisterForDrag("LeftButton")
	c:SetScript("OnClick", function(self) select_(self.psIndex) end)
	c:SetScript("OnDragStart", function(self) pickup(self.psIndex) end)
	c:SetScript("OnEnter", cellEnter)
	c:SetScript("OnLeave", W.HideTooltip)
	return c
end

local function paintGrid(n)
	local sf, cells = f.psGrid, f.psCells
	local cols = f.psCols
	for i = 1, n do
		local c = cells[i] or newCell(sf.Child)
		cells[i] = c
		c.psIndex = i
		local name, icon = GetMacroInfo(actual(i))
		c.Well.Icon:SetTexture(icon)
		c.Name:SetText(name or "")
		W.Color(c.Name, i == selected and "text" or "textDim")
		if i == selected then Theme.Border(c.Well, Theme.Color("accent")) else Theme.Border(c.Well, Theme.Wash("border")) end
		c:ClearAllPoints()
		c:SetPoint("TOPLEFT", sf.Child, "TOPLEFT", ((i - 1) % cols) * (CELL + GAP), -math.floor((i - 1) / cols) * (CELL_H + GAP))
		c:Show()
	end
	for i = n + 1, #cells do cells[i]:Hide() end
	local view = GRID_ROWS * (CELL_H + GAP) - GAP
	W.SetScrollContent(sf, math.ceil(n / cols) * (CELL_H + GAP) - GAP, view)
	f.psEmpty:SetShown(n == 0)
end

-- The selected one in sight in the grid.
local function scrollToSelected()
	if not selected then return W.ScrollTo(f.psGrid, 0) end
	local top = math.floor((selected - 1) / f.psCols) * (CELL_H + GAP)
	local view = GRID_ROWS * (CELL_H + GAP) - GAP
	local at = f.psGrid:GetVerticalScroll()
	if top < at then W.ScrollTo(f.psGrid, top) elseif top + CELL_H > at + view then W.ScrollTo(f.psGrid, top + CELL_H - view) end
end

-- The counter and Save/Cancel follow the body.
local function paintBody()
	local e = f.psEdit
	local n = e:GetNumLetters() or #(e:GetText() or "")
	f.psCount:SetText((MACROFRAME_CHAR_LIMIT or "%d/255 Characters Used"):format(n))
	local fight = InCombatLockdown()
	ns.SetEnabled(f.psSave, changed and not fight, fight and LOCKED or "No changes to save.")
	ns.SetEnabled(f.psCancel, changed and not fight, fight and LOCKED or "No changes to undo.")
end

local function paintDetail(load)
	local d = f.psDetail
	d:SetShown(selected ~= nil)
	if not selected then return end
	local i = actual(selected)
	local name, icon = GetMacroInfo(i)
	f.psIcon.Icon:SetTexture(icon)
	f.psName:SetText(name or "")
	f.psKind:SetText(tab == "character" and "Character macro" or "General macro")
	-- A body typed and not saved stays; otherwise the saved one, as the
	-- stock SelectMacro.
	if load or not changed then
		f.psEdit:SetText(savedBody(i))
		changed = nil
	end
	-- New: the body waits for the macro's name and icon, as stock.
	f.psEditWell:SetShown(not (p and p:IsShown() and p.psMode == "new"))
	local fight = InCombatLockdown()
	if fight then f.psEdit:ClearFocus() end
	f.psEdit:SetEnabled(not fight)
	f.psEditWell:SetAlpha(fight and 0.45 or 1)
	ns.SetEnabled(f.psChange, not fight, LOCKED)
	paintBody()
end

-- Redraws the window; `load` reloads the body (a macro or tab picked).
function M.Refresh(load)
	local nA, nC = GetNumMacros()
	local maxA, maxC = maxes()
	local n, top = count(), cap()
	if selected and selected > n then selected = n > 0 and n or nil; load = true end
	if not selected and n > 0 then selected = 1; load = true end
	-- The stock tabs on top, each with its macros used of its slots.
	ns.TopNav(f, {
		{ key = "general", label = label("general"), count = ("%d/%d"):format(nA, maxA) },
		{ key = "character", label = label("character"), count = ("%d/%d"):format(nC, maxC) },
	}, tab, function(k) M.SetTab(k) end)
	W.ShellTitle(f, label(tab), (n >= top and "Full: %d of %d macros." or "%d of %d macros."):format(n, top))
	ns.Footer(f, { { label = DELETE or "Delete", onClick = M.Delete } },
		{ { label = NEW or "New", onClick = function() openPicker("new") end, opts = { primary = true } } })
	local fight = InCombatLockdown()
	local del, new = f.footerButtons.left[1], f.footerButtons.right[1]
	ns.SetEnabled(del, selected and not fight, fight and LOCKED or "No macro selected.")
	ns.SetEnabled(new, n < top and not fight, fight and LOCKED
		or ("All %d %s macro slots are used."):format(top, tab == "character" and "character" or "general"))
	paintGrid(n)
	paintDetail(load)
	if p and p:IsShown() then canOkay() end
	if load then scrollToSelected() end
	W.ShellBody(f, 0)
end

function M.SetTab(k)
	save()
	closePicker()
	tab, selected, changed = k, nil, nil
	f.psEdit:ClearFocus()
	M.Refresh(true)
end

-- The stock CONFIRM_DELETE_SELECTED_MACRO, in Polestar's dialog.
function M.Delete()
	if not selected or InCombatLockdown() then return end
	local name = GetMacroInfo(actual(selected)) or ""
	W.Modal({ title = ("Delete %s?"):format(name), text = CONFIRM_DELETE_MACRO or "Do you want to delete this macro?",
		action = DELETE or "Delete", danger = true, onAccept = function()
			if not selected or InCombatLockdown() then return end
			closePicker()
			DeleteMacro(actual(selected))
			changed = nil
			M.Refresh(true)
		end })
end

-- The body: a multi-line box of 255 letters scrolled in its well, following
-- the cursor (as Mail's message box).
local function editor(parent, w)
	local well = CreateFrame("Frame", nil, parent)
	well:SetSize(w, EDIT_H)
	Theme.Skin(well, "editbox")
	local sf = W.Scroll(well)
	sf:SetAllPoints(well)
	local e = W.ScrollChild(sf, CreateFrame("EditBox", nil, sf))
	well:EnableMouse(true)
	well:SetScript("OnMouseUp", function() if e:IsEnabled() then e:SetFocus() end end)
	e:SetAutoFocus(false)
	e:SetMultiLine(true)
	e:SetMaxLetters(LETTERS)
	if e.SetCountInvisibleLetters then e:SetCountInvisibleLetters(true) end
	e:SetSize(w, EDIT_H)
	e:SetTextInsets(10, 10, 8, 8)
	Theme.Font(e, "label")
	W.Color(e, "text")
	e:SetScript("OnEditFocusGained", function() Theme.SetFocused(well, true) end)
	e:SetScript("OnEditFocusLost", function() Theme.SetFocused(well, false) end)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnCursorChanged", function(_, _, y, _, h)
		local at, top = sf:GetVerticalScroll(), -(y or 0)
		local bottom = top + (h or 16) + 8
		if top < at then W.ScrollTo(sf, top) elseif bottom > at + EDIT_H then W.ScrollTo(sf, bottom - EDIT_H) end
	end)
	e:SetScript("OnTextChanged", function(_, userInput)
		if userInput then changed = true end
		paintBody()
	end)
	return e, well
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 640, height = 560 })
	ns.Dock(f)
	ns.WindowMenu(f, "macros")
	f.Search:Hide() -- the stock window has none
	ns.Plain(f) -- before the grid: BodyWidth is the compact one
	ns.Compact(f)
	local w = f.BodyWidth
	local pad = f.psPad
	-- The grid, in its own scroll: the body under it stays in place.
	f.psCols = math.floor((w + GAP) / (CELL + GAP))
	f.psGrid = W.Scroll(f.Content)
	f.psGrid:SetPoint("TOPLEFT", f.Content, "TOPLEFT", pad, -20)
	f.psGrid:SetSize(w + 12, GRID_ROWS * (CELL_H + GAP) - GAP)
	f.psCells = {}
	f.psEmpty = W.Text(f.Content, "default", "textDim")
	f.psEmpty:SetPoint("TOPLEFT", f.psGrid, "TOPLEFT", 0, -4)
	f.psEmpty:SetText("No macros here yet.")
	local rule = W.Divider(f.Content)
	rule:SetPoint("TOPLEFT", f.psGrid, "BOTTOMLEFT", 0, -12)
	rule:SetPoint("RIGHT", f.Content, "RIGHT", -pad, 0)
	-- The selected macro, as the stock window's lower half.
	local d = CreateFrame("Frame", nil, f.Content)
	d:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", 0, -12)
	d:SetSize(w, 44 + 12 + 14 + 6 + EDIT_H + 8 + 30)
	f.psDetail = d
	f.psIcon = ns.ItemWell(d, 44, "Button")
	f.psIcon:SetPoint("TOPLEFT", d, "TOPLEFT", 0, 0)
	W.Hover(f.psIcon)
	f.psIcon:RegisterForDrag("LeftButton")
	-- Click or drag picks it up, as the stock SelectedMacroButton.
	f.psIcon:SetScript("OnClick", function() pickup(selected) end)
	f.psIcon:SetScript("OnDragStart", function() pickup(selected) end)
	f.psIcon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(f.psName:GetText() or "", 1, 1, 1)
		ns.TooltipHint(InCombatLockdown() and "Drag it to an action bar after the fight." or "Drag it to an action bar.")
		GameTooltip:Show()
	end)
	f.psIcon:SetScript("OnLeave", W.HideTooltip)
	f.psName = W.Text(d, "heading", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.psIcon, "RIGHT", 12, 1)
	f.psKind = W.Text(d, "small", "textDim")
	f.psKind:SetPoint("TOPLEFT", f.psIcon, "RIGHT", 12, -3)
	f.psChange = W.Button(d, CHANGE_MACRO_NAME_ICON or "Change Name/Icon", function() openPicker("edit") end)
	f.psChange:SetPoint("RIGHT", f.psIcon, "RIGHT", w - 44, 0)
	local enter = W.Text(d, "small", "textDim")
	enter:SetPoint("TOPLEFT", f.psIcon, "BOTTOMLEFT", 0, -12)
	enter:SetText(ENTER_MACRO_LABEL or "Enter Macro Commands:")
	f.psEdit, f.psEditWell = editor(d, w)
	f.psEditWell:SetPoint("TOPLEFT", enter, "BOTTOMLEFT", 0, -6)
	f.psCount = W.Text(d, "small", "textDim")
	f.psCount:SetPoint("TOPLEFT", f.psEditWell, "BOTTOMLEFT", 0, -14)
	f.psSave = W.Button(d, SAVE or "Save", function()
		save()
		f.psEdit:ClearFocus()
		M.Refresh(true)
	end)
	f.psSave:SetPoint("TOPRIGHT", f.psEditWell, "BOTTOMRIGHT", 0, -8)
	f.psCancel = W.Button(d, CANCEL or "Cancel", function()
		changed = nil
		f.psEdit:ClearFocus()
		M.Refresh(true)
	end)
	f.psCancel:SetPoint("RIGHT", f.psSave, "LEFT", -8, 0)
	-- Closing saves, as the stock OnHide; the stock window's sounds.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	f:HookScript("OnHide", function()
		save()
		closePicker()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	end)
	Polestar.CloseOnEscape(NAME)
end

-- Opens on the general macros, as the stock OnShow.
function M.Show(key)
	if not f then build() end
	if f:IsShown() and not key then return end
	save()
	tab, selected, changed = key or "general", nil, nil
	M.Refresh(true)
	f:Show()
end

function M.Toggle()
	if f and f:IsShown() then f:Hide() else M.Show() end
end

function M.Enable()
	-- Every door (/macro, the game menu, the chat menu) calls ShowMacroFrame,
	-- which shows the stock frame; we close it again, as Character's toggle
	-- hook (docs/DESIGN.md, The Replacement Contract). Its hide touches no
	-- action bar. The click binding window shows it itself: that stays the
	-- game's. Switched off, the hook does nothing.
	hooksecurefunc("ShowMacroFrame", function()
		if not ns.Enabled("macros") then return end
		if MacroFrame and MacroFrame:IsShown() then MacroFrame:Hide() end
		M.Show()
	end)
	player()
	local function changedEv() if f and f:IsShown() then M.Refresh() end end
	Polestar.RegisterEvent("UPDATE_MACROS", changedEv)
	Polestar.RegisterEvent("PLAYER_REGEN_DISABLED", changedEv)
	-- A body typed before the fight is saved after it.
	Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", function()
		player()
		if pending then
			local i, text = pending[1], pending[2]
			pending = nil
			EditMacro(i, nil, nil, text)
		end
		changedEv()
	end)
	-- A link shift-clicked with the body in focus goes into it, as the stock
	-- ChatFrameUtil.InsertLink puts it into MacroFrameText: at a line's start
	-- as /use, /equip or /cast and the name. A spell or mount link is its name.
	if ChatFrameUtil and ChatFrameUtil.InsertLink then hooksecurefunc(ChatFrameUtil, "InsertLink", function(text)
		local e = f and f.psEdit
		if not (e and e:IsVisible() and e:HasFocus()) or type(text) ~= "string" or ChatFrameUtil.GetActiveWindow() then return end
		local item = text:find("item:", 1, true) and C_Item.GetItemInfo(text)
		local name = item or text:match("|h%[(.-)%]|h") or text
		local at, body = e:GetCursorPosition() or 0, e:GetText() or ""
		if at == 0 or body:sub(at, at) == "\n" then
			if item then
				name = (C_Item.GetItemSpell(text) and (SLASH_USE1 or "/use") or (SLASH_EQUIP1 or "/equip")) .. " " .. item .. "\n"
			else
				name = (SLASH_CAST1 or "/cast") .. " " .. name .. "\n"
			end
		end
		e:Insert(name)
		changed = true
		paintBody()
	end) end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return MacroFrame and MacroFrame:IsShown() and MacroFrame end

ns.Module("macros", M)
