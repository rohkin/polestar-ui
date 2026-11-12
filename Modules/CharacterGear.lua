-- The Character page's other panes (docs/windows/character.md): Titles, as
-- the stock PaperDollFrame's sidebar tabs have them. Each registers in
-- ns.CharacterPanes (Character.lua), which lays them out in the drawer.

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local PANE_W, ROW_H = 280, 28

local function refresh() if ns.RefreshCharacter then ns.RefreshCharacter() end end

-- A pane's list: rows in a row panel 24 in, scrolling. rows(sf, n, new)
-- shows n rows (made with new(row) as needed) and returns them.
local function listPane(parent)
	local sf = W.Scroll(parent)
	sf:SetAllPoints(parent)
	sf.Child:SetWidth(PANE_W - 4)
	sf.Panel = W.RowPanel(sf.Child)
	sf.Panel:SetPoint("TOPLEFT", sf.Child, "TOPLEFT", 24, 0)
	sf.Panel:SetWidth(PANE_W - 48)
	sf.rows = {}
	return sf
end

local function rows(sf, n, new, top)
	for i = 1, n do
		local r = sf.rows[i]
		if not r then
			r = CreateFrame("Button", nil, sf.Panel)
			r:SetHeight(ROW_H)
			r:SetPoint("TOPLEFT", sf.Panel, "TOPLEFT", 0, -(i - 1) * ROW_H)
			r:SetPoint("RIGHT", sf.Panel, "RIGHT", 0, 0)
			if i > 1 then
				local d = W.Divider(r)
				d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
				d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
			end
			W.Hover(r)
			r:SetScript("OnLeave", W.HideTooltip)
			new(r)
			sf.rows[i] = r
		end
		r:Show()
	end
	for i = n + 1, #sf.rows do sf.rows[i]:Hide() end
	sf.Panel:SetPoint("TOPLEFT", sf.Child, "TOPLEFT", 24, -(top or 0))
	sf.Panel:SetHeight(math.max(1, n * ROW_H))
	sf.Panel:SetShown(n > 0)
	W.SetScrollContent(sf, (top or 0) + n * ROW_H + 24, sf:GetParent():GetHeight())
	return sf.rows
end

---------------------------------------------------------------------------
-- Titles: the known titles by name, "None" first; the one worn is checked.
-- A click wears it (SetCurrentTitle), as the stock list does.

local function newTitleRow(r)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("LEFT", r, "LEFT", 16, 0)
	r.Check = W.Tex(r, "ARTWORK", "check", "accent")
	r.Check:SetSize(12, 12)
	r.Check:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.Name:SetPoint("RIGHT", r.Check, "LEFT", -8, 0)
	r:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		SetCurrentTitle(self.psID)
		refresh()
	end)
end

-- { { name, id }, ... }: "None" (-1), then the known titles by name (GetKnownTitles).
local function knownTitles()
	local list = {}
	for i = 1, GetNumTitles() do
		if IsTitleKnown(i) then
			local name, playerTitle = GetTitleName(i)
			if name and playerTitle then list[#list + 1] = { strtrim(name), i } end
		end
	end
	table.sort(list, function(a, b) return a[1] < b[1] end)
	table.insert(list, 1, { PLAYER_TITLE_NONE or "None", -1 })
	return list
end

ns.CharacterPanes.titles = { page = "PaperDollFrame", label = "Titles", order = 3, build = listPane,
	paint = function(sf)
		local list, cur = knownTitles(), GetCurrentTitle()
		if not (cur > 0 and cur <= GetNumTitles() and IsTitleKnown(cur)) then cur = -1 end
		for i, r in ipairs(rows(sf, #list, newTitleRow)) do
			r.psID = list[i][2]
			r.Name:SetText(list[i][1])
			r.Check:SetShown(r.psID == cur)
		end
	end }

Polestar.RegisterEvent("KNOWN_TITLES_UPDATE", refresh)
Polestar.RegisterEvent("UNIT_NAME_UPDATE", function(_, unit) if unit == "player" then refresh() end end)

---------------------------------------------------------------------------
-- Gear sets: the stock Equipment Manager (C_EquipmentSet). A click selects a
-- set, a double-click or Equip wears it, Save puts the gear worn now in it,
-- New set names a new one; right-click renames, changes its icon or deletes
-- it, and a set drags to the action bars. The client refuses equipping in
-- combat: a set asked for then goes on when the fight ends.

local SET_H, QUESTION = 36, 134400 -- INV_Misc_QuestionMark
local selectedSet, pendingSet

local function setInfo(id) return C_EquipmentSet.GetEquipmentSetInfo(id) end

local function equipSet(id)
	if not id then return end
	local name = setInfo(id)
	if InCombatLockdown() then
		pendingSet = id
		DEFAULT_CHAT_FRAME:AddMessage(("Polestar: UI: %s goes on when the fight ends."):format(name or ""))
		return
	end
	if C_EquipmentSet.EquipmentSetContainsLockedItems(id) or UnitCastingInfo("player") then
		UIErrorsFrame:AddExternalErrorMessage(ERR_CLIENT_LOCKED_OUT or "You can't do that right now.")
		return
	end
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
	C_EquipmentSet.UseEquipmentSet(id)
end

-- The worn items' icons, then the question mark (the stock picker's start).
local function setIcons(first)
	local list, seen = {}, {}
	local function add(icon) if icon and not seen[icon] then seen[icon] = true; list[#list + 1] = icon end end
	add(first)
	for slot = 1, 19 do add(GetInventoryItemTexture("player", slot)) end
	add(QUESTION)
	return list
end

-- The name and icon dialog, for a new set (id nil) or one renamed.
local editor
local function editSet(id)
	if not editor then
		editor = CreateFrame("Frame", nil, UIParent)
		editor.Field = ns.TextField(editor, 352, 16)
		editor.Field:SetPoint("TOPLEFT", editor, "TOPLEFT", 0, 0)
		editor.Field:SetScript("OnEnterPressed", function() PolestarModal.Box.Action:Click() end)
		editor.Grid = ns.ItemGrid(editor, 9, 32, 8)
		editor.Grid:SetPoint("TOPLEFT", editor.Field, "BOTTOMLEFT", 0, -12)
	end
	local name, icon = "", nil
	if id then name, icon = setInfo(id) end
	local icons = setIcons(icon)
	editor.icon = icon or icons[1]
	local function paint()
		for i, w in ipairs(editor.Grid.Layout(#icons)) do
			w.Icon:SetTexture(icons[i])
			if icons[i] == editor.icon then Theme.Border(w, Theme.Color("accent")) else Theme.Border(w, Theme.Wash("border")) end
			w:SetScript("OnClick", function() editor.icon = icons[i]; paint() end)
		end
	end
	paint()
	editor:SetSize(352, 30 + 12 + editor.Grid:GetHeight())
	editor.Field:SetText(name or "")
	ns.ModalWith({ title = id and "Edit gear set" or "New gear set", text = "Name the set and pick its icon.", action = "Save",
		onAccept = function()
			local text = strtrim(editor.Field:GetText() or "")
			if text == "" then return end
			local other = C_EquipmentSet.GetEquipmentSetID(text)
			if id then
				-- As the stock dialog: a rename may not take another set's name.
				if other and other ~= id then
					return UIErrorsFrame:AddExternalErrorMessage(EQUIPMENT_SETS_CANT_RENAME or "A set with that name already exists.")
				end
				C_EquipmentSet.ModifyEquipmentSet(id, text, editor.icon)
				selectedSet = id
			elseif other then
				local chosen = editor.icon
				W.Modal({ title = "Replace " .. text .. "?", text = "The set takes the gear you wear now.", action = "Replace",
					onAccept = function() C_EquipmentSet.SaveEquipmentSet(other, chosen); selectedSet = other; refresh() end })
				return
			elseif C_EquipmentSet.GetNumEquipmentSets() >= (MAX_EQUIPMENT_SETS_PER_PLAYER or 10) then
				return UIErrorsFrame:AddExternalErrorMessage(EQUIPMENT_SETS_TOO_MANY or "You have too many gear sets.")
			else
				-- A new set leaves the shirt and tabard out, as the stock one does.
				C_EquipmentSet.ClearIgnoredSlotsForSave()
				C_EquipmentSet.IgnoreSlotForSave(INVSLOT_BODY or 4)
				C_EquipmentSet.IgnoreSlotForSave(INVSLOT_TABARD or 19)
				C_EquipmentSet.CreateEquipmentSet(text, editor.icon)
				selectedSet = C_EquipmentSet.GetEquipmentSetID(text)
			end
			refresh()
		end }, editor)
	editor.Field:SetFocus()
end
ns.CharacterEditSet = editSet

-- Saves the gear worn now into the set, keeping the slots it leaves out.
local function saveSet(id)
	local name = setInfo(id)
	W.Modal({ title = "Save " .. (name or "") .. "?", text = "The set takes the gear you wear now.", action = "Save",
		onAccept = function()
			C_EquipmentSet.ClearIgnoredSlotsForSave()
			for slot, ignored in pairs(C_EquipmentSet.GetIgnoredSlots(id) or {}) do
				if ignored then C_EquipmentSet.IgnoreSlotForSave(slot) end
			end
			C_EquipmentSet.SaveEquipmentSet(id)
			refresh()
		end })
end

local function setMenu(r)
	local id = r.psID
	W.ShowMenu(r, {
		{ text = "Rename or change icon", onClick = function() editSet(id) end },
		{ text = "Save the gear worn now", onClick = function() saveSet(id) end },
		{ separator = true },
		{ text = "Delete", color = "danger", confirm = true, onClick = function()
			C_EquipmentSet.DeleteEquipmentSet(id)
			if selectedSet == id then selectedSet = nil end
			refresh()
		end },
	}, { point = "TOPLEFT", relPoint = "BOTTOMLEFT", minWidth = 200 })
end

local function newSetRow(r)
	r.Well = ns.ItemWell(r, 24)
	r.Well:SetPoint("LEFT", r, "LEFT", 12, 0)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("LEFT", r.Well, "RIGHT", 10, 0)
	r.Check = W.Tex(r, "ARTWORK", "check", "success")
	r.Check:SetSize(12, 12)
	r.Check:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.Name:SetPoint("RIGHT", r.Check, "LEFT", -8, 0)
	r.Mark = W.Fill(r, "accent", "ARTWORK", 0)
	r.Mark:ClearAllPoints()
	r.Mark:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
	r.Mark:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
	r.Mark:SetWidth(2)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:RegisterForDrag("LeftButton")
	r:SetScript("OnClick", function(self, button)
		if button == "RightButton" then return setMenu(self) end
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		selectedSet = self.psID
		refresh()
	end)
	r:SetScript("OnDoubleClick", function(self) equipSet(self.psID) end)
	r:SetScript("OnDragStart", function(self) if not InCombatLockdown() then C_EquipmentSet.PickupEquipmentSet(self.psID) end end)
	r:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetEquipmentSet(self.psID)
		ns.TooltipHint("Double-click to wear it, or drag it to your action bars. Right-click to rename or delete it.")
		GameTooltip:Show()
	end)
end

ns.CharacterPanes.sets = { page = "PaperDollFrame", label = "Gear sets", order = 2,
	build = function(holder)
		local sf = listPane(holder)
		sf:ClearAllPoints()
		sf:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
		sf:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 64)
		sf.Empty = W.Text(sf.Child, "note", "textDim")
		sf.Empty:SetPoint("TOPLEFT", sf.Child, "TOPLEFT", 24, 0)
		sf.Empty:SetWidth(PANE_W - 48)
		sf.Empty:SetJustifyH("LEFT")
		sf.Empty:SetWordWrap(true)
		sf.Empty:SetText("No gear sets yet: wear what the set should hold, then New set.")
		local w = math.floor((PANE_W - 48 - 16) / 3)
		sf.New = W.Button(holder, "New set", function() editSet(nil) end, { width = w })
		sf.Save = W.Button(holder, "Save", function() saveSet(selectedSet) end, { width = w })
		sf.Equip = W.Button(holder, "Equip", function() equipSet(selectedSet) end, { width = w, primary = true })
		sf.New:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 24, 24)
		sf.Save:SetPoint("LEFT", sf.New, "RIGHT", 8, 0)
		sf.Equip:SetPoint("LEFT", sf.Save, "RIGHT", 8, 0)
		return sf
	end,
	paint = function(sf)
		local ids = C_EquipmentSet.GetEquipmentSetIDs()
		local found = false
		for i, r in ipairs(rows(sf, #ids, newSetRow)) do
			local id = ids[i]
			local name, icon, _, equipped, _, _, _, lost = setInfo(id)
			r.psID = id
			r:SetHeight(SET_H)
			r:SetPoint("TOPLEFT", sf.Panel, "TOPLEFT", 0, -(i - 1) * SET_H)
			r.Well.Icon:SetTexture(icon or QUESTION)
			r.Name:SetText(name)
			W.Color(r.Name, (lost or 0) > 0 and "danger" or "text")
			r.Check:SetShown(equipped and true or false)
			r.Mark:SetShown(id == selectedSet)
			if id == selectedSet then found = true end
		end
		if not found then selectedSet = nil end
		sf.Panel:SetHeight(math.max(1, #ids * SET_H))
		W.SetScrollContent(sf, #ids * SET_H + 24, sf:GetHeight())
		sf.Empty:SetShown(#ids == 0)
		local equipped = selectedSet and select(4, setInfo(selectedSet))
		ns.SetEnabled(sf.Equip, selectedSet ~= nil and not equipped)
		ns.SetEnabled(sf.Save, selectedSet ~= nil)
	end }
function ns.CharacterSelectedSet() return selectedSet end

Polestar.RegisterEvent("EQUIPMENT_SETS_CHANGED", refresh)
Polestar.RegisterEvent("EQUIPMENT_SWAP_FINISHED", function(_, completed, id)
	if completed then
		PlaySound(SOUNDKIT.PUT_DOWN_SMALL_CHAIN)
		selectedSet = id
	end
	refresh()
end)
Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", function()
	local id = pendingSet
	pendingSet = nil
	if id then equipSet(id) end
end)
