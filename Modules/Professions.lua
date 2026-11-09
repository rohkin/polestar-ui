-- Professions (docs/DESIGN.md, "Professions"): the stock professions overview
-- (ProfessionsFrame's book page on Forever) in a Polestar shell: a card per
-- profession slot with its rank and spells. The crafting window is Crafting.lua's.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIProfessions"
local PAD, ICON, ROW_H, GAP = 16, 40, 44, 24
-- As the stock page lays them out: a primary is a wide, short card, its two
-- spells side by side; a secondary a narrow, tall one, its spells stacked.
-- Their art is drawn for those shapes.
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
		{ index = cook, label = PROFESSIONS_COOKING or "Cooking", text = PROFESSIONS_COOKING_MISSING or "Learn it from a cooking trainer.", art = "cooking" },
		{ index = fish, label = PROFESSIONS_FISHING or "Fishing", text = PROFESSIONS_FISHING_MISSING or "Learn it from a fishing trainer.", art = "fishing" },
		{ index = faid, label = PROFESSIONS_FIRST_AID or "First Aid", text = PROFESSIONS_FIRST_AID_MISSING or "Learn it from a first aid trainer.", art = "firstaid" },
	}
end

-- The stock page's card art behind each card, as the Talents window's class
-- art: under a wash of Polestar's sky, both feathered out at the card's sides,
-- the art cropped to the card's shape low in its height. Primaries wear their
-- profession's card (named by its client name, as the stock page names it),
-- secondaries their generic one; an empty slot its art greyed.
local ART_ALPHA, TINT_ALPHA, FEATHER = 1, 0.55, 64
local function cardAtlas(c)
	local get = C_Texture and C_Texture.GetAtlasInfo
	if not get then return end
	local slot = c.psSlot
	local name = slot.art and ("Profession-overview-card-generic-" .. slot.art)
		or (slot.index and ("Profession-overview-Card-" .. (c.psName or "")))
	return (name and get(name)) or get("Profession-overview-Card")
end

local function paintArt(c)
	local info = c.psSlot and cardAtlas(c)
	local w, h = c:GetWidth() - 2, c:GetHeight() - 2
	local on = info ~= nil and w > 2 * FEATHER
	for i = 1, 3 do
		c.psArt[i]:SetShown(on)
		c.psTint[i]:SetShown(on)
	end
	if not on then return end
	local l, r, t, b = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
	-- The stock card's own rounded frame is trimmed off every edge (the same
	-- share of each side, so the aspect holds). Tunable live:
	-- /run PolestarUI.ProfessionArtInset = 0.08
	local inset = ns.ProfessionArtInset or 0.06
	l, r, t, b = l + (r - l) * inset, r - (r - l) * inset, t + (b - t) * inset, b - (b - t) * inset
	-- Cover: keep the art's aspect, cropping whichever side is too long.
	local aspect = (h / w) / (info.height / info.width)
	if aspect < 1 then
		-- Which band of the art's height shows: 0 its top, 1 its bottom (the
		-- cards' scenes sit low). Tunable live: /run PolestarUI.ProfessionArtFocus = 0.9
		local span = (b - t) * aspect
		t = t + (b - t - span) * (ns.ProfessionArtFocus or 0.85)
		b = t + span
	else
		local mid, half = (l + r) / 2, (r - l) / aspect / 2
		l, r = mid - half, mid + half
	end
	local stops = { { 0, 0 }, { FEATHER, 1 }, { w - FEATHER, 1 }, { w, 0 } }
	local sr, sg, sb = Polestar.Theme.Color("sky")
	for i = 1, 3 do
		local x0, a0, x1, a1 = stops[i][1], stops[i][2], stops[i + 1][1], stops[i + 1][2]
		local art, tint = c.psArt[i], c.psTint[i]
		for _, p in ipairs({ art, tint }) do
			p:ClearAllPoints()
			p:SetPoint("TOPLEFT", c, "TOPLEFT", 1 + x0, -1)
			p:SetPoint("BOTTOMRIGHT", c, "BOTTOMLEFT", 1 + x1, 1)
		end
		art:SetTexture(info.file)
		art:SetTexCoord(l + (r - l) * x0 / w, l + (r - l) * x1 / w, t, b)
		art:SetDesaturated(c.psSlot.index == nil)
		art:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, a0 * ART_ALPHA), CreateColor(1, 1, 1, a1 * ART_ALPHA))
		tint:SetGradient("HORIZONTAL", CreateColor(sr, sg, sb, a0 * TINT_ALPHA), CreateColor(sr, sg, sb, a1 * TINT_ALPHA))
	end
end

-- The profession tabs down a window's right side, as on the stock window:
-- the overview (this window), then each profession with a crafting window,
-- the open one marked. Shared with Crafting.lua. Casting a profession is
-- protected: out of combat a secure button of ours takes the hovered tab's
-- place (ns.Overlay). ns.ProfessionTabs(window, onOverview) -> paint(skill
-- line of the open profession, or nil for the overview).
local TAB = 40
local function tabEnter(t)
	GameTooltip:SetOwner(t, "ANCHOR_RIGHT")
	GameTooltip:SetText(t.psName)
	if not t.psActive then
		ns.TooltipHint(t.psSpell and "Click to open its recipes." or "Click to see all your professions.")
	end
	GameTooltip:Show()
end

local overTab = ns.Overlay("PolestarUIProfessionTab", {
	enter = tabEnter,
	pickup = function() end,
	attrs = function(over, t)
		over:SetAttribute("type1", not t.psActive and "spell" or nil)
		over:SetAttribute("spell", t.psSpell)
	end,
})

function ns.ProfessionTabs(win, onOverview)
	local tabs = {}
	local function tab(i)
		if tabs[i] then return tabs[i] end
		local t = CreateFrame("Button", nil, win)
		t:SetSize(TAB, TAB)
		t:SetPoint("TOPLEFT", win, "TOPRIGHT", 2, -(24 + (i - 1) * (TAB + 6)))
		Polestar.Theme.Skin(t, "inset")
		W.Hover(t)
		t.Icon = ns.GameIcon(t)
		t.Icon:SetPoint("TOPLEFT", 1, -1)
		t.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
		t:SetScript("OnEnter", function(self)
			tabEnter(self)
			if self.psSpell then overTab(self) end
		end)
		t:SetScript("OnLeave", W.HideTooltip)
		-- The overview's click; a profession's is the secure button's.
		t:SetScript("OnClick", function(self)
			if not self.psSpell and not self.psActive and onOverview then onOverview() end
		end)
		tabs[i] = t
		return t
	end
	return function(current)
		local list = { { name = "Professions", icon = "Interface\\Icons\\INV_SideTab_Professions_c60", active = current == nil } }
		local slots = { GetProfessions() }
		for k = 1, 5 do
			local i = slots[k]
			if i then
				local name, icon, _, _, _, offset, skillLine = GetProfessionInfo(i)
				local info = C_SpellBook.GetSpellBookItemInfo(offset + 1, Enum.SpellBookSpellBank.Player)
				if info and info.spellID and C_TradeSkillUI.CanTradeSkillShowCraftingUI(info.spellID) then
					list[#list + 1] = { name = name, icon = icon, spell = info.spellID, active = current ~= nil and skillLine == current }
				end
			end
		end
		for i, d in ipairs(list) do
			local t = tab(i)
			t.psName, t.psSpell, t.psActive = d.name, d.spell, d.active
			t.Icon:SetTexture(d.icon)
			if d.active then
				Polestar.Theme.Border(t, Polestar.Theme.Color("accent"))
			else
				Polestar.Theme.Border(t, Polestar.Theme.Wash("border"))
			end
			t:Show()
		end
		for i = #list + 1, #tabs do tabs[i]:Hide() end
	end
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
	c.psArt, c.psTint = {}, {}
	for i = 1, 3 do
		c.psArt[i] = c:CreateTexture(nil, "BACKGROUND", nil, 2)
		c.psTint[i] = c:CreateTexture(nil, "BACKGROUND", nil, 3)
		c.psTint[i]:SetTexture("Interface\\Buttons\\WHITE8X8")
	end
	-- Repainted with the theme: the wash is Polestar's sky.
	W.Painter(c.psTint[1], function() paintArt(c) end)
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
	c.psSlot = slot
	local known = slot.index ~= nil
	c.psName = known and GetProfessionInfo(slot.index) or nil
	paintArt(c)
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
	-- A profession opened: the crafting window (Crafting.lua) takes over.
	Polestar.RegisterEvent("TRADE_SKILL_SHOW", function() if f then f:Hide() end end)
end

ns.Module("professions", M)
