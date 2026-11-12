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
