-- Talents (docs/DESIGN.md, "Talents"): the stock talents tab of
-- PlayerSpellsFrame in a Polestar shell. Forever's three classic trees live on
-- the client's trait engine: one C_Traits tree, a node group per talent tree.
-- This first step shows them; spending comes next.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUITalents"
local NODE, PITCH, HEAD_H = 40, 52, 48

local f, group = nil, nil -- group: the spec group shown (1 Primary, 2 Secondary)
local query, found = "", 0 -- the sidebar search, and the talents it matched
local M = {}
local nodes, lines = {}, {}

-- Numbers the client may hand over secret in combat (docs/CLIENT.md, rule 3).
local function num(v)
	if v == nil or (issecretvalue and issecretvalue(v)) then return 0 end
	return v
end

local function activeGroup() return C_SpecializationInfo.GetActiveSpecGroup() or 1 end
local function numGroups() return GetNumSpecGroups and GetNumSpecGroups() or 1 end
local function configOf(g) return C_SpecializationInfo.GetCombatConfigIDForSpecGroup(g) end

local function treeOf(config)
	local info = config and C_Traits.GetConfigInfo(config)
	return info and info.treeIDs and info.treeIDs[1]
end

local function spentIn(config)
	local tree = treeOf(config)
	local c = tree and C_Traits.GetTreeCurrencyInfo(config, tree, false)
	return c and c[1] and num(c[1].spent) or 0, c and c[1] and num(c[1].quantity) or 0
end

-- The node's entry and its icon: the client's override icon, else the spell's.
local function entryOf(config, info)
	local entryID = info.activeEntry and info.activeEntry.entryID or info.entryIDs[1]
	local entry = entryID and C_Traits.GetEntryInfo(config, entryID)
	local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
	local icon = def and (def.overrideIcon or (def.spellID and C_Spell.GetSpellTexture(def.spellID)))
	return entryID, icon, def and def.spellID, def
end

-- One cell of the client's grid: the smallest step between positions,
-- ignoring the few units the client nudges a node off it (steps under a
-- quarter of the largest).
local function cell(v)
	table.sort(v)
	local big, s = 0, nil
	for i = 2, #v do big = math.max(big, v[i] - v[i - 1]) end
	for i = 2, #v do
		local d = v[i] - v[i - 1]
		if d >= big / 4 and d > 0 and (not s or d < s) then s = d end
	end
	return s or 1
end

-- The trees: the client's groups in order, each with its nodes on a grid read
-- off the client's positions (rounded to the nearest cell).
local function readTrees(config)
	local tree = treeOf(config)
	if not tree then return {} end
	local trees, byGroup = {}, {}
	local displays = C_Traits.GetGroupDisplayInfoByTreeID(tree) or {}
	table.sort(displays, function(a, b) return a.orderIndex < b.orderIndex end)
	local ids = {}
	for i, d in ipairs(displays) do
		trees[i] = { name = d.displayName, icon = d.icon, groupID = d.groupID, nodes = {} }
		byGroup[d.groupID] = trees[i]
		ids[i] = d.groupID
	end
	for _, gc in ipairs(C_Traits.GetGroupCurrencyInfo(config, ids) or {}) do
		local t = byGroup[gc.traitNodeGroupID]
		if t and gc.currencyInfos[1] then t.spent = num(gc.currencyInfos[1].spent) end
	end
	local ys, top = {}, nil
	for _, id in ipairs(C_Traits.GetTreeNodes(tree) or {}) do
		local info = C_Traits.GetNodeInfo(config, id)
		local t
		for _, g in ipairs(info and info.isVisible and info.groupIDs or {}) do t = t or byGroup[g] end
		if t then
			t.nodes[#t.nodes + 1] = info
			ys[#ys + 1] = info.posY
			top = math.min(top or info.posY, info.posY)
		end
	end
	local sy, sx = cell(ys), nil
	for _, t in ipairs(trees) do
		local xs = {}
		for i, n in ipairs(t.nodes) do xs[i] = n.posX end
		if #xs > 1 then sx = math.min(sx or math.huge, cell(xs)) end
	end
	for _, t in ipairs(trees) do
		local left
		for _, n in ipairs(t.nodes) do left = math.min(left or n.posX, n.posX) end
		-- shortcut: a tree with no talent in its first column is drawn one column left; classic trees all use it.
		for _, n in ipairs(t.nodes) do
			n.col = math.floor((n.posX - left) / (sx or 1) + 0.5)
			n.row = math.floor((n.posY - top) / sy + 0.5)
		end
	end
	return trees
end

local function nodeEnter(b)
	-- The stock talent tooltip's lines (TalentDisplayMixin:SetTooltipInternal,
	-- Camelot's overrides): name, rank, subtext, this rank's and the next
	-- rank's text, then the tier and prerequisite it still waits on.
	local n, tip = b.psInfo, GameTooltip
	tip:SetOwner(b, "ANCHOR_RIGHT")
	local def = b.psDef or {}
	GameTooltip_SetTitle(tip, def.overrideName or (b.psSpell and C_Spell.GetSpellName(b.psSpell)) or "")
	GameTooltip_AddHighlightLine(tip, TALENT_BUTTON_TOOLTIP_RANK_FORMAT:format(b.psRank, num(n.maxRanks)))
	local sub = def.overrideSubtext or (b.psSpell and C_Spell.GetSpellSubtext(b.psSpell))
	if sub and sub ~= "" then
		GameTooltip_AddBlankLineToTooltip(tip)
		GameTooltip_AddColoredLine(tip, sub, DISABLED_FONT_COLOR)
	end
	local cur = n.activeEntry or n.nextEntry
	if cur then
		if not (sub and sub ~= "") then GameTooltip_AddBlankLineToTooltip(tip) end
		tip:AppendInfo("GetTraitEntry", cur.entryID, cur.rank)
	end
	if n.nextEntry and num(n.ranksPurchased) > 0 then
		GameTooltip_AddBlankLineToTooltip(tip)
		GameTooltip_AddHighlightLine(tip, TALENT_BUTTON_TOOLTIP_NEXT_RANK)
		tip:AppendInfo("GetTraitEntry", n.nextEntry.entryID, n.nextEntry.rank)
	end
	-- The highest tier gate and every other condition with text, as the stock
	-- frame filters them (AddConditionsToTooltip), then an unmet prerequisite.
	local conds, gate, met = {}, nil, {}
	for _, id in ipairs(n.conditionIDs or {}) do
		local c = C_Traits.GetConditionInfo(b.psConfig, id, false, b.psTree)
		if c then
			conds[#conds + 1] = c
			if c.isSufficient and c.isMet then met[c.type] = true end
			if c.isGate and (not gate or c.spentAmountRequired > gate.spentAmountRequired) then gate = c end
		end
	end
	local spaced = false
	local function line(add, text)
		if not spaced then GameTooltip_AddBlankLineToTooltip(tip); spaced = true end
		add(tip, text)
	end
	for _, c in ipairs(conds) do
		if c.tooltipText and (c.isMet or not met[c.type]) and (not c.isGate or c == gate) then
			line(GameTooltip_AddHighlightLine, c.tooltipText)
		end
	end
	if not n.meetsEdgeRequirements then line(GameTooltip_AddErrorLine, GENERIC_TRAIT_FRAME_EDGE_REQUIREMENTS_BUTTON_TOOLTIP) end
	if b.psSpell then ns.TooltipHint("Shift-click to link it in chat.") end
	tip:Show()
end

-- Shift-click links the talent's spell, as the stock frame.
local function nodeClick(b)
	if b.psSpell and IsModifiedClick("CHATLINK") then ChatFrameUtil.InsertLink(C_Spell.GetSpellLink(b.psSpell)) end
end

local function newNode(parent)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(NODE, NODE)
	Polestar.Theme.Skin(b, "inset")
	Polestar.Theme.Border(b, Polestar.Theme.Wash("border"))
	b.Icon = ns.GameIcon(b)
	b.Icon:SetPoint("TOPLEFT", 1, -1)
	b.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	W.Hover(b)
	-- The rank, once learnt, on a solid chip over the bottom-right corner,
	-- its hairline in the node's state colour: legible on any icon.
	b.Chip = CreateFrame("Frame", nil, b)
	b.Chip:SetSize(18, 18)
	b.Chip:SetPoint("CENTER", b, "BOTTOMRIGHT", -2, 2)
	b.Chip:SetFrameLevel(b:GetFrameLevel() + 3)
	local bg = b.Chip:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	W.Painter(bg, function(t) t:SetColorTexture(Polestar.Theme.Color("bg")) end)
	b.Rank = W.Text(b.Chip, "number", "text")
	b.Rank:SetPoint("CENTER", 0, 0)
	b:SetScript("OnEnter", nodeEnter)
	b:SetScript("OnLeave", W.HideTooltip)
	b:SetScript("OnClick", nodeClick)
	return b
end

-- A node, as the stock frame reads: maxed with its border and rank in the
-- accent, partly learnt in success, open to a point on the hairline, locked
-- (tier or prerequisite) desaturated and dim. The rank shows once learnt.
-- The search, as the stock frame's: a talent's name or its description.
local function matches(spell, def)
	if query == "" then return true end
	local function has(text)
		return type(text) == "string" and not (issecretvalue and issecretvalue(text)) and text:lower():find(query, 1, true)
	end
	return has(def and def.overrideName) or (spell and (has(C_Spell.GetSpellName(spell)) or has(C_Spell.GetSpellDescription(spell)))) or false
end

local function paintNode(b, config, n)
	local entryID, icon, spell, def = entryOf(config, n)
	-- Searching, a talent that does not match recedes.
	local match = matches(spell, def)
	if query ~= "" and match then found = found + 1 end
	b:SetAlpha(match and 1 or 0.25)
	b.psEntry, b.psSpell, b.psNode, b.psInfo, b.psDef, b.psConfig = entryID, spell, n.ID, n, def, config
	local rank, max = num(n.currentRank), num(n.maxRanks)
	b.psRank = rank
	local locked = not (n.isAvailable and n.meetsEdgeRequirements) and rank == 0
	b.Icon:SetTexture(icon)
	b.Icon:SetDesaturated(locked)
	b.Icon:SetAlpha(locked and 0.35 or 1)
	local state = rank >= max and "accent" or rank > 0 and "success" or nil
	b.Rank:SetText(rank)
	W.Color(b.Rank, state or "text")
	b.Chip:SetShown(rank > 0)
	if state then
		local r, g, bl = Polestar.Theme.Color(state)
		Polestar.Theme.Border(b, r, g, bl, 1)
		Polestar.Theme.Border(b.Chip, r, g, bl, 1)
	else
		Polestar.Theme.Border(b, Polestar.Theme.Wash("border"))
	end
end

-- The three trees side by side, each centred in a third of the main column
-- (the art's panels, between its seams); returns the height.
local function paintTrees(config)
	local trees = readTrees(config)
	local colW = (f.BodyWidth + 2 * W.SHELL.pad) / math.max(#trees, 1)
	local at, ni, li, bottom = {}, 0, 0, 0
	for i, t in ipairs(trees) do
		local h = f.psHeads[i]
		if not h then
			h = CreateFrame("Frame", nil, f.Body)
			h:SetSize(1, 24)
			h.Well = CreateFrame("Frame", nil, h)
			h.Well:SetSize(24, 24)
			h.Well:SetPoint("LEFT", 0, 0)
			Polestar.Theme.Skin(h.Well, "inset")
			Polestar.Theme.Border(h.Well, Polestar.Theme.Wash("border"))
			h.Icon = ns.GameIcon(h.Well)
			h.Icon:SetPoint("TOPLEFT", 1, -1)
			h.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
			h.Name = W.Text(h, "heading", "text")
			h.Name:SetPoint("LEFT", h.Well, "RIGHT", 8, 0)
			h.Spent = W.Text(h, "number", "textDim")
			h.Spent:SetPoint("LEFT", h.Name, "RIGHT", 8, 0)
			f.psHeads[i] = h
		end
		-- The grid (four columns at least) and its heading (icon, name, points)
		-- each centred in the column.
		local mid = (i - 0.5) * colW
		local cols = 3
		for _, n in ipairs(t.nodes) do cols = math.max(cols, n.col) end
		local gw = NODE + cols * PITCH
		local gx = mid - gw / 2
		h.Icon:SetTexture(t.icon)
		h.Name:SetText(t.name)
		h.Spent:SetText(t.spent or 0)
		h:SetWidth(24 + 8 + h.Name:GetStringWidth() + 8 + h.Spent:GetStringWidth())
		h:ClearAllPoints()
		h:SetPoint("TOP", f.Body, "TOPLEFT", mid, -24)
		h:Show()
		for _, n in ipairs(t.nodes) do
			ni = ni + 1
			local b = nodes[ni] or newNode(f.Body)
			nodes[ni] = b
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", f.Body, "TOPLEFT", gx + n.col * PITCH, -(24 + HEAD_H + n.row * PITCH))
			b:SetFrameLevel(f.Body:GetFrameLevel() + 2)
			paintNode(b, config, n)
			b.psTree = t.name -- the conditions name it ("Requires 10 points in Fire")
			b:Show()
			at[n.ID] = b
			bottom = math.max(bottom, 24 + HEAD_H + n.row * PITCH + NODE)
		end
	end
	for i = #trees + 1, #f.psHeads do f.psHeads[i]:Hide() end
	for i = ni + 1, #nodes do nodes[i]:Hide() end
	-- Prerequisites: the client's edges, 2px, in the accent once met.
	for _, t in ipairs(trees) do
		for _, n in ipairs(t.nodes) do
			for _, e in ipairs(n.visibleEdges or {}) do
				local a, b = at[n.ID], at[e.targetNode]
				if a and b then
					li = li + 1
					local l = lines[li] or f.Body:CreateLine(nil, "BORDER")
					lines[li] = l
					l:SetThickness(2)
					l:SetStartPoint("CENTER", a)
					l:SetEndPoint("CENTER", b)
					if e.isActive then
						l:SetColorTexture(Polestar.Theme.Color("accent"))
					else
						l:SetColorTexture(Polestar.Theme.Wash("border"))
					end
					l:Show()
				end
			end
		end
	end
	for i = li + 1, #lines do lines[i]:Hide() end
	f.psEmpty:SetShown(#trees == 0)
	return bottom + 24
end

local function optionsMenu(self)
	if W.MenuShown(self) then return W.HideMenu() end
	W.ShowMenu(self, { { text = "Game's talents: shift-click their micro button", disabled = true } }, { minWidth = 200 })
end

-- The class's talent art (the stock frame's talent-background-<class>) behind
-- the trees, under a wash of Polestar's sky blue, both feathered out at the
-- sides: full width, the middle band of its height (its aspect kept), so its
-- three panels sit behind the three trees.
local ART_ALPHA, TINT_ALPHA, FEATHER, SEAM = 0.85, 0.55, 160, 80
local ART_PIECES = 9
local function paintArt()
	local _, cls = UnitClass("player")
	local info = C_Texture and C_Texture.GetAtlasInfo("talent-background-" .. cls:lower())
	-- The main column under the band, from the shell's own sizes.
	local w = f.BodyWidth + 2 * W.SHELL.pad
	local h = f:GetHeight() - W.SHELL.header - (f.Footer:IsShown() and W.SHELL.footer or 0)
	local on = info ~= nil and w > 2 * FEATHER + 4 * SEAM and h > 0
	for i = 1, ART_PIECES do
		f.psArt[i]:SetShown(on)
		f.psTint[i]:SetShown(on)
	end
	-- The hairline where the art meets the band: 1px of the border wash,
	-- fading out from the middle to the column's edges.
	local ar, ag, ab, aa = Polestar.Theme.Wash("border")
	for i, s in ipairs(f.psStripe) do
		s:SetShown(on)
		s:ClearAllPoints()
		s:SetPoint("TOPLEFT", f.Content, "TOPLEFT", (i - 1) * w / 2, 0)
		s:SetSize(w / 2, 1)
		local a0, a1 = i == 1 and 0 or aa or 1, i == 1 and (aa or 1) or 0
		s:SetGradient("HORIZONTAL", CreateColor(ar, ag, ab, a0), CreateColor(ar, ag, ab, a1))
	end
	if not on then return end
	local l, r, t, b = info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord
	local keep = math.min(1, (h / w) / (info.height / info.width))
	local mid, half = (t + b) / 2, (b - t) * keep / 2
	t, b = mid - half, mid + half
	-- Alpha stops across the column: in from the left edge, out to nothing at
	-- each seam between the art's panels and in again, out at the right edge.
	-- shortcut: the seams are taken at a third and two thirds of the atlas, as its three panels sit; measure them if a class's art differs.
	local s1, s2 = w / 3, 2 * w / 3
	local stops = { { 0, 0 }, { FEATHER, 1 }, { s1 - SEAM, 1 }, { s1, 0 }, { s1 + SEAM, 1 }, { s2 - SEAM, 1 },
		{ s2, 0 }, { s2 + SEAM, 1 }, { w - FEATHER, 1 }, { w, 0 } }
	local sr, sg, sb = Polestar.Theme.Color("sky")
	for i = 1, ART_PIECES do
		local x0, a0, x1, a1 = stops[i][1], stops[i][2], stops[i + 1][1], stops[i + 1][2]
		local art, tint = f.psArt[i], f.psTint[i]
		for _, p in ipairs({ art, tint }) do
			p:ClearAllPoints()
			p:SetPoint("TOPLEFT", f.Content, "TOPLEFT", x0, 0)
			p:SetPoint("BOTTOMRIGHT", f.Content, "BOTTOMLEFT", x1, 0)
		end
		art:SetTexture(info.file)
		art:SetTexCoord(l + (r - l) * x0 / w, l + (r - l) * x1 / w, t, b)
		art:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, a0 * ART_ALPHA), CreateColor(1, 1, 1, a1 * ART_ALPHA))
		tint:SetGradient("HORIZONTAL", CreateColor(sr, sg, sb, a0 * TINT_ALPHA), CreateColor(sr, sg, sb, a1 * TINT_ALPHA))
	end
end

local function build()
	-- Wider than the shell's 960: three four-column trees side by side.
	f = W.Shell(NAME, { width = 1100, searchPlaceholder = "Search talents", onSearch = function(text)
		query = (text or ""):lower()
		if f:IsShown() then M.Show() end
	end })
	-- The subject block names the window, in place of Polestar's lockup.
	-- Reparented, not hidden: the shell re-shows its version line on every show.
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
	-- The way to the stock frame (its search, inspect), on the band.
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
	f.psArt, f.psTint, f.psStripe = {}, {}, {}
	for i = 1, 2 do
		f.psStripe[i] = f.Content:CreateTexture(nil, "BORDER")
		f.psStripe[i]:SetTexture("Interface\\Buttons\\WHITE8X8")
	end
	for i = 1, ART_PIECES do
		f.psArt[i] = f.Content:CreateTexture(nil, "BACKGROUND", nil, 2)
		f.psTint[i] = f.Content:CreateTexture(nil, "BACKGROUND", nil, 3)
		f.psTint[i]:SetTexture("Interface\\Buttons\\WHITE8X8")
	end
	-- Repainted with the theme: the wash is Polestar's sky.
	W.Painter(f.psTint[1], function() paintArt() end)
	f.psHeads = {}
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psEmpty:SetText("No talents yet: they open at level 10.")
	-- The stock window's sounds: it never opens now to play them.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.UI_CLASS_TALENT_OPEN_WINDOW) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.UI_CLASS_TALENT_CLOSE_WINDOW) end)
	Polestar.CloseOnEscape(NAME)
end

local function refresh()
	if group > numGroups() then group = activeGroup() end
	local _, cls = UnitClass("player")
	f.psName:SetText((UnitClass("player")))
	f.psLine:SetText(("Level %d"):format(UnitLevel("player")))
	f.psClass:SetTexture("Interface\\Icons\\ClassIcon_" .. cls)
	-- The stock tabs as nav rows: the active spec with the dot, the other its points spent.
	-- Secondary stays listed before dual spec is learnt: locked, receding
	-- (count 0), its tooltip saying how to learn it, as the stock tab.
	local nav = {}
	for g = 1, 2 do
		local active, locked = g == activeGroup(), g > numGroups()
		nav[g] = { key = g, label = g == 1 and (DUAL_SPEC_PRIMARY or "Primary") or (DUAL_SPEC_SECONDARY or "Secondary"),
			icon = locked and "lock" or "star", dot = active or nil,
			count = locked and 0 or (not active and spentIn(configOf(g))) or nil }
	end
	W.ShellNav(f, nav, group, function(k)
		if k > numGroups() then return end
		group = k
		M.Show()
	end)
	for _, b in ipairs(f.navButtons) do
		if not b.psTalentTip then
			b.psTalentTip = true
			b:HookScript("OnEnter", function(self)
				if self.psKey ~= 2 or numGroups() > 1 then return end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(DUAL_SPEC_SECONDARY or "Secondary")
				GameTooltip:AddLine(TALENT_SPEC_LOCKED or "Learn Dual Talent Specialization from a class trainer.", 1, 0.2, 0.2, true)
				GameTooltip:Show()
			end)
			b:HookScript("OnLeave", W.HideTooltip)
		end
	end
	local config = configOf(group)
	local _, left = spentIn(config)
	found = 0
	local height = paintTrees(config)
	local sub
	if query ~= "" then
		sub = found == 1 and "1 talent matches." or ("%d talents match."):format(found)
	elseif group ~= activeGroup() then
		sub = "Not your active spec."
	elseif left > 0 then
		sub = left == 1 and "1 point to spend." or ("%d points to spend."):format(left)
	else
		sub = "Every point is spent."
	end
	W.ShellTitle(f, "Talents", sub)
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, {})
	paintArt() -- the footer sets the content's height
	W.ShellBody(f, height)
end

function M.Show(g)
	if not f then build() end
	group = g or group or activeGroup()
	refresh()
	f:Show()
end

function M.Toggle()
	if f and f:IsShown() then f:Hide() else M.Show() end
end

function M.Enable()
	-- The talents key and micro button open ours; the stock window is never
	-- touched (docs/CLIENT.md, rule 8). A talent link and inspecting another
	-- player stay the game's.
	ns.Doors("Talents", { TOGGLETALENTS = M.Toggle }, TalentMicroButton, M.Toggle)
	local function changed() if f and f:IsShown() and not InCombatLockdown() then refresh() end end
	for _, e in ipairs({ "TRAIT_CONFIG_UPDATED", "TRAIT_NODE_CHANGED", "TRAIT_TREE_CURRENCY_INFO_UPDATED",
		"ACTIVE_COMBAT_CONFIG_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_REGEN_ENABLED" }) do
		Polestar.RegisterEvent(e, changed)
	end
end

ns.Module("talents", M)
