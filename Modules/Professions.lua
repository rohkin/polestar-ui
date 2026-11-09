-- Professions (docs/DESIGN.md, "Professions"): the stock professions overview
-- (ProfessionsFrame's book page on Forever) in a Polestar shell: a card per
-- profession slot with its rank and spells. The crafting window stays the game's.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIProfessions"
local PAD, ICON, ROW_H, GAP = 16, 40, 44, 24
-- As the stock page lays them out: a primary is a wide, short card, its two
-- spells side by side; a secondary a narrow, tall one, its spells stacked.
local GROUPS = {
	{ slots = { 1, 2 }, perRow = 1, spellCols = 2, height = PAD + ICON + 12 + ROW_H - 8 + PAD },
	{ slots = { 3, 4, 5 }, perRow = 3, spellCols = 1, height = PAD + ICON + 12 + 2 * ROW_H - 8 + PAD },
}

local f
local M = {}
local cards = {}

local function clean(v)
	if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
	return v
end

-- The stock page's slots, in its order: two primaries, then Cooking, Fishing
-- and First Aid, each with what the stock page says while it is empty.
local function slots()
	local p1, p2, faid, fish, cook = GetProfessions()
	local missing = PROFESSIONS_MISSING_PROFESSION or "Learn it from a profession trainer."
	return {
		{ index = p1, primary = true, label = PROFESSIONS_FIRST_PROFESSION or "First Profession", text = missing },
		{ index = p2, primary = true, label = PROFESSIONS_SECOND_PROFESSION or "Second Profession", text = missing },
		{ index = cook, label = PROFESSIONS_COOKING or "Cooking", text = PROFESSIONS_COOKING_MISSING or "Learn it from a cooking trainer." },
		{ index = fish, label = PROFESSIONS_FISHING or "Fishing", text = PROFESSIONS_FISHING_MISSING or "Learn it from a fishing trainer." },
		{ index = faid, label = PROFESSIONS_FIRST_AID or "First Aid", text = PROFESSIONS_FIRST_AID_MISSING or "Learn it from a first aid trainer." },
	}
end

-- Unlearning, confirmed first, as the stock page's button.
local function unlearn(c)
	W.Modal({
		title = ("Unlearn %s?"):format(c.psName),
		text = "Your skill and every recipe you know in it are lost. A trainer can teach it again, from the start.",
		action = "Unlearn",
		danger = true,
		onAccept = function() C_SkillInfo.AbandonSkill(c.psSkillLine) end,
	})
end

local function newCard()
	local c = CreateFrame("Frame", nil, f.Body)
	Polestar.Theme.Skin(c, "panel")
	local well = CreateFrame("Frame", nil, c)
	well:SetSize(ICON, ICON)
	well:SetPoint("TOPLEFT", c, "TOPLEFT", PAD, -PAD)
	Polestar.Theme.Skin(well, "inset")
	Polestar.Theme.Border(well, Polestar.Theme.Wash("border"))
	c.Icon = ns.GameIcon(well)
	c.Icon:SetPoint("TOPLEFT", 1, -1)
	c.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	c.Unlearn = W.IconButton(c, "cross", 24, "Unlearn", function() unlearn(c) end, 12)
	c.Unlearn:SetPoint("TOPRIGHT", c, "TOPRIGHT", -10, -10)
	c.Name = W.Text(c, "title", "text")
	c.Name:SetPoint("TOPLEFT", well, "TOPRIGHT", 12, 0)
	c.Name:SetPoint("RIGHT", c, "RIGHT", -(PAD + 24), 0)
	c.Name:SetJustifyH("LEFT")
	-- The skill bar: the rank above its right end (docs/DESIGN.md, "Skill Bar").
	c.Bar = W.ProgressLine(c, 2)
	c.Bar:SetPoint("BOTTOMLEFT", well, "BOTTOMRIGHT", 12, 0)
	c.Bar:SetPoint("RIGHT", c, "RIGHT", -PAD, 0)
	c.Rank = W.Text(c, "number", "textDim")
	c.Rank:SetPoint("BOTTOMRIGHT", c.Bar, "TOPRIGHT", 0, 6)
	c.Missing = W.Text(c, "small", "textMuted")
	c.Missing:SetPoint("TOPLEFT", well, "BOTTOMLEFT", 0, -12)
	c.Missing:SetPoint("RIGHT", c, "RIGHT", -PAD, 0)
	c.Missing:SetJustifyH("LEFT")
	c.Missing:SetWordWrap(true)
	c.rows = {}
	return c
end

local function paintCard(c, slot, width, group)
	c:SetSize(width, group.height)
	local known = slot.index ~= nil
	for _, r in ipairs(c.rows) do r:Hide() end
	c.Unlearn:SetShown(known and slot.primary)
	c.Bar:SetShown(known)
	c.Rank:SetShown(known)
	c.Missing:SetShown(not known)
	W.Color(c.Name, known and "text" or "textMuted")
	if not known then
		c.Icon:SetTexture("Interface\\Icons\\INV_Scroll_04")
		c.Icon:SetDesaturated(true)
		c.Name:SetText(slot.label)
		c.Missing:SetText(slot.text)
		return
	end
	local name, texture, rank, maxRank, numSpells, offset, skillLine, modifier = GetProfessionInfo(slot.index)
	c.psName, c.psSkillLine = name, skillLine
	c.Icon:SetTexture(texture)
	c.Icon:SetDesaturated(false)
	c.Name:SetText(name)
	rank, maxRank, modifier = clean(rank), clean(maxRank), clean(modifier)
	if rank and maxRank then
		c.Rank:SetText(modifier and modifier > 0 and ("%d/%d (+%d)"):format(rank, maxRank, modifier) or ("%d/%d"):format(rank, maxRank))
		W.SetProgress(c.Bar, maxRank > 0 and rank / maxRank or 0, width - PAD * 2 - ICON - 12)
	end
	local bank = Enum.SpellBookSpellBank.Player
	local colW = (width - PAD * 2 - GAP * (group.spellCols - 1)) / group.spellCols
	for i = 1, math.min(numSpells or 0, 2) do
		local info = C_SpellBook.GetSpellBookItemInfo(offset + i, bank)
		if info then
			local r = c.rows[i] or ns.SpellRow.New(c)
			c.rows[i] = r
			r:ClearAllPoints()
			local col, line = (i - 1) % group.spellCols, math.floor((i - 1) / group.spellCols)
			r:SetPoint("TOPLEFT", c, "TOPLEFT", PAD + col * (colW + GAP), -(PAD + ICON + 12 + line * ROW_H))
			r:SetWidth(colW)
			ns.SpellRow.Paint(r, { slot = offset + i, bank = bank, info = info })
			r:Show()
		end
	end
end

local function build()
	f = W.Shell(NAME)
	f.Search:Hide()
	-- The subject block names the window, in place of Polestar's lockup.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Status, f.Stage }) do r:SetParent(holder) end
	local well = CreateFrame("Frame", nil, f.Sidebar)
	well:SetSize(36, 36)
	well:SetPoint("LEFT", f.Sidebar, "TOPLEFT", 24, -47)
	Polestar.Theme.Skin(well, "inset")
	Polestar.Theme.Border(well, Polestar.Theme.Wash("border"))
	local icon = ns.GameIcon(well)
	icon:SetPoint("TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", -1, 1)
	icon:SetTexture("Interface\\Icons\\INV_SideTab_Professions_c60")
	f.psName = W.Text(f.Sidebar, "title", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", 24 + 36 + 12, -47)
	f.psName:SetText("Professions")
	f.psLine = W.Text(f.Sidebar, "small", "textDim")
	f.psLine:SetPoint("TOPLEFT", f.psName, "BOTTOMLEFT", 0, -6)
	for _, t in ipairs({ f.psName, f.psLine }) do t:SetWidth(f.Sidebar:GetWidth() - (24 + 36 + 12) - 24) end
	f.psHeads = { W.SectionHeader(f.Body), W.SectionHeader(f.Body) }
	f.psHeads[1].Text:SetText("Primary")
	f.psHeads[2].Text:SetText("Secondary")
	-- The stock window's sounds: it never opens now to play them.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE) end)
	Polestar.CloseOnEscape(NAME)
end

-- Primaries one to a row, secondaries three, under their headings.
local function refresh()
	local list = slots()
	local learnt = (list[1].index and 1 or 0) + (list[2].index and 1 or 0)
	f.psLine:SetText(("%d of 2 professions learnt"):format(learnt))
	W.ShellTitle(f, "Professions", "Click a profession's spell to open it, or drag it to your action bars.")
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, {})
	local y = 0
	for g, group in ipairs(GROUPS) do
		local head = f.psHeads[g]
		head:ClearAllPoints()
		head:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -y)
		head:SetWidth(f.BodyWidth)
		y = y + head:GetHeight() + 4
		local w = (f.BodyWidth - GAP * (group.perRow - 1)) / group.perRow
		for k, i in ipairs(group.slots) do
			local c = cards[i] or newCard()
			cards[i] = c
			local col, line = (k - 1) % group.perRow, math.floor((k - 1) / group.perRow)
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad + col * (w + GAP), -(y + line * (group.height + 8)))
			paintCard(c, list[i], w, group)
		end
		y = y + math.ceil(#group.slots / group.perRow) * (group.height + 8)
	end
	W.ShellBody(f, y)
end

function M.Show()
	if not f then build() end
	refresh()
	f:Show()
end

function M.Toggle()
	if f and f:IsShown() then f:Hide() else M.Show() end
end

function M.Enable()
	-- The professions key and micro button open ours; the stock window, whose
	-- show touches the micro buttons, is never touched (docs/CLIENT.md, rule 8).
	ns.Doors("Professions", { TOGGLEPROFESSIONBOOK = M.Toggle }, ProfessionMicroButton, M.Toggle)
	local function changed() if f and f:IsShown() then refresh() end end
	Polestar.RegisterEvent("SKILL_LINES_CHANGED", changed)
	Polestar.RegisterEvent("SPELLS_CHANGED", changed)
	Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", changed)
	Polestar.RegisterEvent("SPELL_UPDATE_COOLDOWN", function()
		if not (f and f:IsShown()) then return end
		for _, c in ipairs(cards) do
			for _, r in ipairs(c.rows) do if r:IsShown() then ns.SpellRow.PaintCooldown(r) end end
		end
	end)
	-- A profession opened: the game's crafting window takes the left slot.
	Polestar.RegisterEvent("TRADE_SKILL_SHOW", function() if f then f:Hide() end end)
end

ns.Module("professions", M)
