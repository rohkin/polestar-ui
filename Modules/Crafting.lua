-- Crafting (docs/DESIGN.md, "Professions (ProfessionsFrame)"): the game's
-- crafting window in a Polestar shell. It opens when a profession is cast
-- (TRADE_SKILL_SHOW) and holds the trade skill until it closes.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUICrafting"
local HEAD_H, ROW_H, TILE_H, PRODUCT, RECENT = 32, 28, 32, 40, 8
-- The client's recipe difficulty colours: optimal, medium, easy, trivial.
local DIFFICULTY = { [0] = { 1, 0.5, 0.25 }, [1] = { 1, 1, 0 }, [2] = { 0.25, 0.75, 0.25 }, [3] = { 0.5, 0.5, 0.5 } }

local f, query, sel, selKey, qty = nil, "", nil, nil, 1
-- An enchant's item (its GUID), chosen in the item slot; nil: Craft lets the
-- game ask for it, as a cast does.
local target
local folded, lastSel = {}, {}
local closing -- the game closed the trade skill itself
-- A trade skill was opened: TRADE_SKILL_SHOW can come before its data, as
-- the stock window allows for; ours then opens on the list's first update.
local wanted
local M = {}
local heads, rows, tiles = {}, {}, {}
local refresh

-- The open trade skill's profession, or nil when none is open.
local function profession()
	local p = C_TradeSkillUI.GetChildProfessionInfo()
	if not (p and p.professionID ~= 0) then p = C_TradeSkillUI.GetBaseProfessionInfo() end
	if p and p.professionID ~= 0 then return p end
end

-- Another player's or the guild's recipes: shown, never crafted.
local function viewing()
	return C_TradeSkillUI.IsTradeSkillLinked() or C_TradeSkillUI.IsTradeSkillGuild()
end

-- A game filter hides recipes (its Filter menu: filterMenu).
local function filtering()
	local T = C_TradeSkillUI
	return T.GetOnlyShowSkillUpRecipes() or T.GetOnlyShowMakeableRecipes()
		or (T.AreAnyInventorySlotsFiltered and T.AreAnyInventorySlotsFiltered()) or false
end

-- Recipes crafted lately, newest first, for every profession (kept per character).
local function recent()
	PolestarUICharDB.recentRecipes = PolestarUICharDB.recentRecipes or {}
	return PolestarUICharDB.recentRecipes
end

local function remember(id)
	local list = recent()
	for i = #list, 1, -1 do if list[i] == id then table.remove(list, i) end end
	table.insert(list, 1, id)
	list[RECENT * 4 + 1] = nil
end

-- What a recipe needs besides reagents: its tools and places, its cooldown,
-- the game's own reason. -> { { text, colour } }, whether that blocks it now
local function notes(info)
	local out, names, missing = {}, {}, false
	for _, r in ipairs(C_TradeSkillUI.GetRecipeRequirements(info.recipeID) or {}) do
		names[#names + 1] = r.name
		missing = missing or not r.met
	end
	if #names > 0 then out[#out + 1] = { "Requires " .. table.concat(names, ", "), missing and "warning" or "textDim" } end
	local cd = C_TradeSkillUI.GetRecipeCooldown(info.recipeID)
	if cd and cd > 0 then out[#out + 1] = { "Ready again in " .. SecondsToTime(cd), "warning" } end
	if info.disabled and info.disabledReason then out[#out + 1] = { info.disabledReason, "warning" } end
	return out, missing or (cd and cd > 0) or info.disabled or not info.craftable
end

-- The learnt recipes by category in the client's order, "Can make now" and
-- "Recent" first; while searching, only the categories with a match.
-- -> sections, recipe info by ID.
local function sections()
	local byID, cats, list = {}, {}, {}
	local match = query ~= "" and query
	for _, id in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs() or {}) do
		local info = C_TradeSkillUI.GetRecipeInfo(id)
		if info and info.learned and not info.isDummyRecipe and (not match or info.name:lower():find(match, 1, true)) then
			info.count = C_TradeSkillUI.GetCraftableCount(id) or 0
			local c = cats[info.categoryID]
			if not c then
				local ci = C_TradeSkillUI.GetCategoryInfo(info.categoryID)
				c = { key = "c" .. info.categoryID, label = ci and ci.name or "", order = ci and ci.uiOrder or 0, n = #list, recipes = {} }
				cats[info.categoryID] = c
				list[#list + 1] = c
			end
			info.psCategory = c.label
			byID[id] = info
			table.insert(c.recipes, info)
		end
	end
	table.sort(list, function(a, b) if a.order ~= b.order then return a.order < b.order end return a.n < b.n end)
	if match then return list, byID end
	local make, last = { key = "make", label = "Can make now", recipes = {} }, { key = "recent", label = "Recent", recipes = {} }
	for _, c in ipairs(list) do
		for _, r in ipairs(c.recipes) do
			if r.count > 0 and not select(2, notes(r)) then table.insert(make.recipes, r) end
		end
	end
	for _, id in ipairs(recent()) do
		if byID[id] and #last.recipes < RECENT then table.insert(last.recipes, byID[id]) end
	end
	table.insert(list, 1, last)
	table.insert(list, 1, make)
	return list, byID
end

local function insertLink(link)
	local insert = (ChatFrameUtil and ChatFrameUtil.InsertLink) or ChatEdit_InsertLink
	if link and insert then insert(link) end
end

-- What a recipe makes, as the game's tooltip shows it.
local function productTip(owner, id)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	if GameTooltip.SetRecipeResultItem then GameTooltip:SetRecipeResultItem(id) else GameTooltip:SetSpellByID(id) end
	ns.TooltipHint("Shift-click to link it in chat.")
	GameTooltip:Show()
end

local function quality(q)
	local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	if c then return c.r, c.g, c.b end
end

-- An item's name in its quality colour, lifted to read; the border raw,
-- from uncommon up (docs/DESIGN.md, "Slot Tile").
local function paintQuality(text, well, q)
	local r, g, b = quality(q)
	W.Uncolor(text)
	if r then text:SetTextColor(Theme.Legible(r, g, b)) else W.Color(text, "text") end
	if r and q >= 2 then Theme.Border(well, r, g, b, 1) else Theme.Border(well, Theme.Wash("border")) end
end

local function iconWell(parent, size)
	local well = CreateFrame("Frame", nil, parent)
	well:SetSize(size, size)
	Theme.Skin(well, "inset")
	Theme.Border(well, Theme.Wash("border"))
	local icon = ns.GameIcon(well)
	icon:SetPoint("TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", -1, 1)
	return well, icon
end

local function place(b, y)
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT", f.NavScroll.Child, "TOPLEFT", 0, -y)
	b:SetPoint("TOPRIGHT", f.NavScroll.Child, "TOPRIGHT", 0, -y)
	b:Show()
end

-- A category's heading in the sidebar: a click folds its recipes away.
local function headRow(i)
	if heads[i] then return heads[i] end
	local h = CreateFrame("Button", nil, f.NavScroll.Child)
	h:SetHeight(HEAD_H)
	W.Hover(h)
	h.Chevron = W.Tex(h, "ARTWORK", "chevron-down", "textMuted")
	h.Chevron:SetSize(12, 12)
	h.Chevron:SetPoint("LEFT", h, "LEFT", W.SHELL.side, 0)
	h.Count = W.Text(h, "number", "textMuted")
	h.Count:SetPoint("RIGHT", h, "RIGHT", -W.SHELL.side, 0)
	h.Label = W.Text(h, "label", "textDim")
	h.Label:SetPoint("LEFT", h.Chevron, "RIGHT", 8, 0)
	h.Label:SetPoint("RIGHT", h.Count, "LEFT", -8, 0)
	h.Label:SetJustifyH("LEFT")
	h.Label:SetWordWrap(false)
	h:SetScript("OnClick", function(self)
		folded[self.psKey] = not folded[self.psKey]
		refresh()
	end)
	heads[i] = h
	return h
end

-- A recipe row (docs/DESIGN.md, "Recipe Row").
local function recipeRow(i)
	if rows[i] then return rows[i] end
	local r = CreateFrame("Button", nil, f.NavScroll.Child)
	r:SetHeight(ROW_H)
	W.Hover(r)
	r.Sel = r:CreateTexture(nil, "BACKGROUND")
	r.Sel:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.Sel:SetAllPoints(r)
	W.Painter(r.Sel, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	r.Bar = r:CreateTexture(nil, "ARTWORK")
	r.Bar:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.Bar:SetWidth(2)
	r.Bar:SetPoint("TOPLEFT")
	r.Bar:SetPoint("BOTTOMLEFT")
	W.Color(r.Bar, "accent")
	r.Icon = ns.GameIcon(r)
	r.Icon:SetSize(16, 16)
	r.Icon:SetPoint("LEFT", r, "LEFT", W.SHELL.side, 0)
	r.Count = W.Text(r, "number", "textMuted")
	r.Count:SetPoint("RIGHT", r, "RIGHT", -W.SHELL.side, 0)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetPoint("LEFT", r.Icon, "RIGHT", 8, 0)
	r.Name:SetJustifyH("LEFT")
	-- A long name (an enchant's) takes a second line, as the shell's nav rows.
	r.Name:SetWordWrap(true)
	r.Name:SetMaxLines(2)
	r:SetScript("OnClick", function(self)
		local id = self.psRecipe.recipeID
		if IsModifiedClick("CHATLINK") then return insertLink(C_TradeSkillUI.GetRecipeLink(id)) end
		if id ~= sel then qty, target = 1, nil end
		sel, selKey = id, self.psKey
		refresh()
	end)
	r:SetScript("OnEnter", function(self) productTip(self, self.psRecipe.recipeID) end)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[i] = r
	return r
end

local function paintRow(r, info, key)
	r.psRecipe, r.psKey = info, key
	r.Icon:SetTexture(info.icon)
	r.Name:SetText(info.name)
	local c = DIFFICULTY[info.relativeDifficulty]
	W.Uncolor(r.Name)
	if c then r.Name:SetTextColor(Theme.Legible(c[1], c[2], c[3])) else W.Color(r.Name, "text") end
	r.Count:SetText(info.count > 0 and info.count or "")
	-- The name runs from the icon to the count; the row grows for a second line.
	local side = W.SHELL.side
	r.Name:SetWidth((f.psSidebar or W.SHELL.sidebar) - 1 - (side + 16 + 8) - side - (info.count > 0 and r.Count:GetStringWidth() + 8 or 0))
	r:SetHeight(math.max(ROW_H, math.ceil(r.Name:GetStringHeight()) + 12))
	local on = info.recipeID == sel and key == selKey
	r.Sel:SetShown(on)
	r.Bar:SetShown(on)
end

-- The sidebar under the search: each section's heading, then its recipes
-- unless folded (a search shows every match).
local function paintNav(list)
	local y, hi, ri = 0, 0, 0
	for _, s in ipairs(list) do
		if #s.recipes > 0 then
			hi = hi + 1
			local h = headRow(hi)
			local open = query ~= "" or not folded[s.key]
			h.psKey = s.key
			h.Label:SetText(s.label)
			h.Count:SetText(#s.recipes)
			h.Chevron:SetTexture(Theme.Media(open and "chevron-down" or "chevron-right"))
			place(h, y)
			y = y + HEAD_H
			if open then
				for _, info in ipairs(s.recipes) do
					ri = ri + 1
					local r = recipeRow(ri)
					paintRow(r, info, s.key)
					place(r, y)
					y = y + r:GetHeight()
				end
			end
		end
	end
	for i = hi + 1, #heads do heads[i]:Hide() end
	for i = ri + 1, #rows do rows[i]:Hide() end
	f.NavScroll.Child:SetWidth((f.psSidebar or W.SHELL.sidebar) - 1)
	W.SetScrollContent(f.NavScroll, y, W.ShellNavHeight(f))
end

-- What the player holds of a reagent (an item, or a currency).
local function held(reagent)
	if reagent.itemID then
		local count = ItemUtil and ItemUtil.GetCraftingReagentCount and ItemUtil.GetCraftingReagentCount(reagent.itemID)
		return count or C_Item.GetItemCount(reagent.itemID) or 0
	end
	local c = reagent.currencyID and C_CurrencyInfo.GetCurrencyInfo(reagent.currencyID)
	return c and c.quantity or 0
end

-- A reagent tile (docs/DESIGN.md, "Reagent Tile"): the game's tooltip, and
-- its modified clicks (link, dressing room).
local function tile(i)
	if tiles[i] then return tiles[i] end
	local t = CreateFrame("Button", nil, f.Body)
	t:SetHeight(TILE_H)
	W.Hover(t)
	t.Well, t.Icon = iconWell(t, TILE_H)
	t.Well:SetPoint("LEFT", t, "LEFT", 0, 0)
	t.Count = W.Text(t, "number", "text")
	t.Count:SetPoint("RIGHT", t, "RIGHT", -8, 0)
	t.Name = W.Text(t, "label", "text")
	t.Name:SetPoint("LEFT", t.Well, "RIGHT", 8, 0)
	t.Name:SetPoint("RIGHT", t.Count, "LEFT", -8, 0)
	t.Name:SetJustifyH("LEFT")
	t.Name:SetWordWrap(false)
	t:SetScript("OnEnter", function(self) if self.psItem then W.ItemTip(self, self.psItem) end end)
	t:SetScript("OnLeave", W.HideTooltip)
	t:SetScript("OnClick", function(self) if self.psItem then W.ItemClick(self.psItem) end end)
	tiles[i] = t
	return t
end

local function paintTile(t, slot)
	local reagent = slot.reagents[1]
	local have = 0
	for _, r in ipairs(slot.reagents) do have = have + held(r) end
	local name, icon, q
	if reagent.itemID then
		W.PrefetchItem(reagent.itemID)
		name, icon, q = C_Item.GetItemNameByID(reagent.itemID), C_Item.GetItemIconByID(reagent.itemID), C_Item.GetItemQualityByID(reagent.itemID)
	else
		local c = C_CurrencyInfo.GetCurrencyInfo(reagent.currencyID)
		name, icon = c and c.name, c and c.iconFileID
	end
	t.psItem = reagent.itemID
	t.Icon:SetTexture(icon)
	t.Name:SetText(name or RETRIEVING_ITEM_INFO or "Loading")
	paintQuality(t.Name, t.Well, q)
	t.Count:SetText(("%d/%d"):format(have, slot.quantityRequired))
	W.Color(t.Count, have >= slot.quantityRequired and "text" or "danger")
end

-- An item by its GUID (a bag or worn item): name, icon, quality, worn.
local function itemByGUID(guid)
	local id = C_Item.GetItemIDByGUID(guid)
	if not id then return end
	W.PrefetchItem(id)
	local loc = C_Item.GetItemLocation(guid)
	return C_Item.GetItemNameByID(id), C_Item.GetItemIconByID(id), C_Item.GetItemQualityByID(id), loc and loc:IsEquipmentSlot()
end

-- The items an enchant can go on, as the game's item slot lists them.
local function targetMenu(slot)
	if W.MenuShown(slot) then return W.HideMenu() end
	local items = {}
	for _, guid in ipairs(C_TradeSkillUI.GetEnchantItems(sel) or {}) do
		local name, _, _, worn = itemByGUID(guid)
		if name then
			items[#items + 1] = { text = worn and (name .. " (equipped)") or name, checked = guid == target,
				onClick = function() target = guid; refresh() end }
		end
	end
	if #items == 0 then items[1] = { text = "Nothing in your bags or gear takes it.", disabled = true } end
	W.ShowMenu(slot, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT", minWidth = 200 })
end

-- The recipe page: the product, what it says, its reagents in two columns,
-- then the notes. -> the body height.
local function paintPage(info)
	local id = info.recipeID
	local s = C_TradeSkillUI.GetRecipeSchematic(id, false)
	local x, w, y = W.SHELL.pad, f.BodyWidth, 24
	local p = f.psProduct
	local name, icon, q = s.name, s.icon, nil
	if s.outputItemID then
		W.PrefetchItem(s.outputItemID)
		name = C_Item.GetItemNameByID(s.outputItemID) or name
		icon = C_Item.GetItemIconByID(s.outputItemID) or icon
		q = C_Item.GetItemQualityByID(s.outputItemID)
	end
	p.psRecipe, p.psItem = id, s.outputItemID
	p.Icon:SetTexture(icon)
	p.Name:SetText(name)
	paintQuality(p.Name, p.Well, q)
	local made = s.quantityMax > s.quantityMin and ("Makes %d\226\128\147%d"):format(s.quantityMin, s.quantityMax)
		or s.quantityMin > 1 and ("Makes %d"):format(s.quantityMin) or nil
	p.Sub:SetText(made or "")
	p.Sub:SetShown(made ~= nil)
	-- With a "Makes" line the name sits above the well's middle.
	p.Name:ClearAllPoints()
	p.Name:SetPoint(made and "BOTTOMLEFT" or "LEFT", p.Well, "RIGHT", 12, made and 1 or 0)
	p.Name:SetPoint("RIGHT", p, "RIGHT", 0, 0)
	p:ClearAllPoints()
	p:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y)
	p:SetWidth(w)
	p:Show()
	y = y + PRODUCT + 16
	local desc = C_TradeSkillUI.GetRecipeDescription(id, {}) or ""
	f.psDesc:SetWidth(w)
	f.psDesc:SetText(desc)
	f.psDesc:ClearAllPoints()
	f.psDesc:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y)
	f.psDesc:SetShown(desc ~= "")
	if desc ~= "" then y = y + f.psDesc:GetStringHeight() + 16 end
	local slots = {}
	for _, slot in ipairs(s.reagentSlotSchematics) do
		if slot.reagentType == Enum.CraftingReagentType.Basic and not slot.hiddenInCraftingForm and slot.reagents[1] then
			slots[#slots + 1] = slot
		end
	end
	local head = f.psHead
	head:SetShown(#slots > 0)
	head:ClearAllPoints()
	head:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y)
	head:SetWidth(w)
	if #slots > 0 then y = y + head:GetHeight() + 12 end
	local cw = (w - 8) / 2
	for i, slot in ipairs(slots) do
		local t = tile(i)
		local col, line = (i - 1) % 2, math.floor((i - 1) / 2)
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x + col * (cw + 8), -(y + line * (TILE_H + 8)))
		t:SetWidth(cw)
		paintTile(t, slot)
		t:Show()
	end
	for i = #slots + 1, #tiles do tiles[i]:Hide() end
	y = y + math.ceil(#slots / 2) * (TILE_H + 8)
	-- An enchant: the item it goes on, as the game's item slot. A chosen item
	-- no longer in the bags or worn is let go.
	f.psEnchant = s.recipeType == Enum.TradeskillRecipeType.Enchant
	local t = f.psTarget
	f.psHead2:SetShown(f.psEnchant)
	t:SetShown(f.psEnchant)
	if f.psEnchant then
		if target and not tContains(C_TradeSkillUI.GetEnchantItems(id) or {}, target) then target = nil end
		y = y + 8
		f.psHead2:ClearAllPoints()
		f.psHead2:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y)
		f.psHead2:SetWidth(w)
		y = y + f.psHead2:GetHeight() + 12
		local name, icon, q = nil, nil, nil
		if target then name, icon, q = itemByGUID(target) end
		t.Icon:SetTexture(icon)
		t.Icon:SetShown(icon ~= nil)
		t.Name:SetText(name or PROFESSIONS_ADD_ENCHANT or "Add an item")
		if name then paintQuality(t.Name, t.Well, q) else
			W.Color(t.Name, "textMuted")
			Theme.Border(t.Well, Theme.Wash("border"))
		end
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y)
		t:SetWidth((w - 8) / 2)
		y = y + TILE_H
	end
	local list = notes(info)
	for i, fs in ipairs(f.psNotes) do
		local n = list[i]
		fs:SetShown(n ~= nil)
		if n then
			y = y + 8
			fs:SetWidth(w)
			fs:SetText(n[1])
			W.Color(fs, n[2])
			fs:ClearAllPoints()
			fs:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y)
			y = y + fs:GetStringHeight()
		end
	end
	return y + 24
end

local function hidePage()
	f.psProduct:Hide()
	f.psDesc:Hide()
	f.psHead:Hide()
	f.psHead2:Hide()
	f.psTarget:Hide()
	f.psEnchant = false
	for _, t in ipairs(tiles) do t:Hide() end
	for _, fs in ipairs(f.psNotes) do fs:Hide() end
end

-- The footer: the quantity stepper on the left, Craft all and Craft on the
-- right, each enabled only when the game would take it.
local function paintFooter(info)
	local blocked = not info or viewing() or select(2, notes(info))
	local can = not blocked and info.count > 0
	local most = can and info.count or 1
	-- An enchant goes on one item; more only into one that stores them (a
	-- vellum), as the game's window allows.
	if f.psEnchant and not (target and C_TradeSkillUI.CanStoreEnchantInItem(target)) then most = 1 end
	qty = math.max(1, math.min(qty, most))
	if not f.psQty:HasFocus() then f.psQty:SetText(qty) end
	local function craft(n)
		if f.psEnchant and target then
			C_TradeSkillUI.CraftEnchant(info.recipeID, n, nil, C_Item.GetItemLocation(target))
		else
			C_TradeSkillUI.CraftRecipe(info.recipeID, n)
		end
		remember(info.recipeID)
		refresh()
	end
	W.ShellFooter(f, {}, {
		{ label = info and info.alternateVerb or "Craft", onClick = function() craft(qty) end, opts = { primary = true } },
		{ label = "Craft all", onClick = function() craft(most) end },
	})
	-- Disabled as Polestar disables: faded to 45%.
	local function enable(b, on)
		b:SetEnabled(on and true or false)
		b:SetAlpha(on and 1 or 0.45)
	end
	enable(f.psLess, can and qty > 1)
	enable(f.psMore, can and qty < most)
	enable(f.psMax, can and qty < most)
	for _, b in ipairs(f.footerButtons.right) do enable(b, can) end
end

-- The first section holding the recipe, `key`'s if it is one of them.
local function sectionOf(list, id, key)
	local first
	for _, s in ipairs(list) do
		for _, r in ipairs(s.recipes) do
			if r.recipeID == id then
				if s.key == key then return key end
				first = first or s.key
			end
		end
	end
	return first
end

function refresh()
	local p = profession()
	if not p then return end
	f.psTabs(p.parentProfessionID or p.professionID)
	f.psIcon:SetTexture(C_TradeSkillUI.GetTradeSkillTexture(p.professionID))
	f.psName:SetText(p.parentProfessionName or p.professionName)
	local rank, most, mod = p.skillLevel or 0, p.maxSkillLevel or 0, p.skillModifier or 0
	f.psRank:SetText(mod > 0 and ("%d/%d (+%d)"):format(rank, most, mod) or ("%d/%d"):format(rank, most))
	W.SetProgress(f.psBar, most > 0 and rank / most or 0, f.psBarW)
	local list, byID = sections()
	if not byID[sel] then
		sel, selKey, qty = nil, nil, 1
		for _, s in ipairs(list) do
			if s.recipes[1] then sel = s.recipes[1].recipeID break end
		end
	end
	selKey = sel and sectionOf(list, sel, selKey)
	if query == "" then lastSel[p.professionID] = sel end
	paintNav(list)
	local info = sel and byID[sel]
	local linked, who = C_TradeSkillUI.IsTradeSkillLinked()
	if info then
		W.ShellTitle(f, info.name, linked and who and ("%s's recipe: you cannot craft it."):format(who) or info.psCategory)
		W.ShellBody(f, paintPage(info))
	else
		hidePage()
		W.ShellTitle(f, query ~= "" and "Search" or p.professionName,
			(query ~= "" or filtering()) and "No recipe you know matches." or "You know no recipes yet: a trainer teaches them.")
		W.ShellBody(f, 0)
	end
	W.ShellWatermark(f, info == nil)
	W.SetIconState(f.psFilter, filtering())
	paintFooter(info)
end

-- The game's own recipe filters, as its Filter menu: skill-ups, materials,
-- item slots. They act on GetFilteredRecipeIDs. The list redraws at once and
-- again on the client's TRADE_SKILL_LIST_UPDATE (docs/CLIENT.md, rule 6); the
-- menu opens again after each pick, so several can be set in a row.
local function filterMenu(anchor)
	if W.MenuShown(anchor) then return W.HideMenu() end
	local T = C_TradeSkillUI
	local function pick(fn)
		return function()
			fn()
			refresh()
			filterMenu(anchor)
		end
	end
	local items = {}
	if not T.IsTradeSkillGuild() then
		items[#items + 1] = { text = TRADESKILL_FILTER_HAS_SKILL_UP or "Has skill up", checked = T.GetOnlyShowSkillUpRecipes(),
			onClick = pick(function() T.SetOnlyShowSkillUpRecipes(not T.GetOnlyShowSkillUpRecipes()) end) }
	end
	items[#items + 1] = { text = CRAFT_IS_MAKEABLE or "Have materials", checked = T.GetOnlyShowMakeableRecipes(),
		onClick = pick(function() T.SetOnlyShowMakeableRecipes(not T.GetOnlyShowMakeableRecipes()) end) }
	-- Slots: a slot shown is "checked"; the client calls showing it
	-- SetInventorySlotFilter(i, true), as the stock menu's Check All does.
	local n = T.GetAllFilterableInventorySlotsCount and T.GetAllFilterableInventorySlotsCount() or 0
	if n > 0 then
		local function all(on) return pick(function() for i = 1, n do T.SetInventorySlotFilter(i, on) end end) end
		items[#items + 1] = { separator = true }
		items[#items + 1] = { text = CHECK_ALL or "Check all", onClick = all(true) }
		items[#items + 1] = { text = UNCHECK_ALL or "Uncheck all", onClick = all(false) }
		for i = 1, n do
			items[#items + 1] = { text = T.GetFilterableInventorySlotName(i), checked = not T.IsInventorySlotFiltered(i),
				onClick = pick(function() T.SetInventorySlotFilter(i, T.IsInventorySlotFiltered(i)) end) }
		end
	end
	W.ShowMenu(anchor, items, { minWidth = 180 })
end

local function build()
	f = W.Shell(NAME, { width = 760 + W.SHELL.rail, rail = true, searchPlaceholder = "Search recipes", onSearch = function(text)
		query = (text or ""):lower()
		if f and f:IsShown() then refresh() end
	end })
	ns.Dock(f)
	-- The subject block names the profession, in place of Polestar's lockup:
	-- its name with the rank at the right end of its skill bar.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Status, f.Stage }) do r:SetParent(holder) end
	local SB, X = f.psSidebar or W.SHELL.sidebar, 24 + 36 + 12
	local well
	well, f.psIcon = iconWell(f.Sidebar, 36)
	well:SetPoint("LEFT", f.Sidebar, "TOPLEFT", 24, -47)
	f.psRank = W.Text(f.Sidebar, "number", "textDim")
	f.psRank:SetPoint("BOTTOMRIGHT", f.Sidebar, "TOPLEFT", SB - 24, -47)
	f.psName = W.Text(f.Sidebar, "title", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", X, -47)
	f.psName:SetPoint("RIGHT", f.psRank, "LEFT", -8, 0)
	f.psName:SetJustifyH("LEFT")
	f.psName:SetWordWrap(false)
	f.psBarW = SB - X - 24
	f.psBar = W.ProgressLine(f.Sidebar, 2)
	f.psBar:SetPoint("TOPLEFT", f.Sidebar, "TOPLEFT", X, -(47 + 8))
	f.psBar:SetWidth(f.psBarW)

	-- The recipe page's parts; the reagent tiles are made as needed.
	local p = CreateFrame("Button", nil, f.Body)
	p:SetHeight(PRODUCT)
	p.Well, p.Icon = iconWell(p, PRODUCT)
	p.Well:SetPoint("LEFT", p, "LEFT", 0, 0)
	p.Name = W.Text(p, "title", "text")
	p.Name:SetJustifyH("LEFT")
	p.Sub = W.Text(p, "small", "textDim")
	p.Sub:SetPoint("TOPLEFT", p.Well, "RIGHT", 12, -3)
	p:SetScript("OnEnter", function(self) productTip(self.Well, self.psRecipe) end)
	p:SetScript("OnLeave", W.HideTooltip)
	p:SetScript("OnClick", function(self)
		if not (self.psItem and W.ItemClick(self.psItem)) and IsModifiedClick("CHATLINK") then
			insertLink(C_TradeSkillUI.GetRecipeLink(self.psRecipe))
		end
	end)
	f.psProduct = p
	f.psDesc = W.Text(f.Body, "default", "textDim")
	f.psDesc:SetJustifyH("LEFT")
	f.psDesc:SetWordWrap(true)
	f.psHead = W.SectionHeader(f.Body)
	W.SetSection(f.psHead, "Reagents")
	f.psHead2 = W.SectionHeader(f.Body)
	W.SetSection(f.psHead2, "Item to enchant")
	-- The enchant's item slot: a click lists the items it can go on, a
	-- right-click clears it.
	local t = CreateFrame("Button", nil, f.Body)
	t:SetHeight(TILE_H)
	W.Hover(t)
	t.Well, t.Icon = iconWell(t, TILE_H)
	t.Well:SetPoint("LEFT", t, "LEFT", 0, 0)
	t.Name = W.Text(t, "label", "textMuted")
	t.Name:SetPoint("LEFT", t.Well, "RIGHT", 8, 0)
	t.Name:SetPoint("RIGHT", t, "RIGHT", -8, 0)
	t.Name:SetJustifyH("LEFT")
	t.Name:SetWordWrap(false)
	t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	t:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			target = nil
			W.HideMenu()
			return refresh()
		end
		targetMenu(self)
	end)
	t:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if target then
			GameTooltip:SetItemByGUID(target)
			ns.TooltipHint("Click to choose another item. Right-click to clear it.")
		else
			GameTooltip:SetText(PROFESSIONS_ADD_ENCHANT or "Add an item")
			ns.TooltipHint("Click to choose the item to enchant. Without one, Craft asks for it, as casting the enchant does.")
		end
		GameTooltip:Show()
	end)
	t:SetScript("OnLeave", W.HideTooltip)
	f.psTarget = t
	f.psNotes = {}
	for i = 1, 3 do
		f.psNotes[i] = W.Text(f.Body, "note", "textDim")
		f.psNotes[i]:SetJustifyH("LEFT")
		f.psNotes[i]:SetWordWrap(true)
	end

	-- The quantity stepper: -, the count, +, Max.
	local function setQty(n)
		qty = n
		refresh()
	end
	local step = CreateFrame("Frame", nil, f.Footer)
	step:SetSize(200, 28)
	step:SetPoint("LEFT", f.Footer, "LEFT", W.SHELL.pad, 0)
	f.psLess = W.Button(step, "\226\128\147", function() setQty(qty - 1) end, { width = 28 })
	f.psLess:SetPoint("LEFT", step, "LEFT", 0, 0)
	local e = CreateFrame("EditBox", nil, step)
	e:SetSize(48, 28)
	e:SetPoint("LEFT", f.psLess, "RIGHT", 4, 0)
	e:SetAutoFocus(false)
	e:SetNumeric(true)
	e:SetMaxLetters(3)
	e:SetJustifyH("CENTER")
	Theme.Font(e, "number")
	W.Color(e, "text")
	Theme.Skin(e, "editbox")
	e:SetScript("OnEditFocusGained", function(self)
		Theme.SetFocused(self, true)
		self:HighlightText()
	end)
	e:SetScript("OnEditFocusLost", function(self)
		Theme.SetFocused(self, false)
		setQty(tonumber(self:GetText()) or 1)
	end)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	f.psQty = e
	f.psMore = W.Button(step, "+", function() setQty(qty + 1) end, { width = 28 })
	f.psMore:SetPoint("LEFT", e, "RIGHT", 4, 0)
	f.psMax = W.Button(step, "Max", function() setQty(math.huge) end, { ghost = true })
	f.psMax:SetPoint("LEFT", f.psMore, "RIGHT", 8, 0)

	-- The filter acts on the list: it sits at the end of the search row, its
	-- glyph in the accent while a filter hides recipes.
	local top = W.SHELL.header - 30
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + 30 + 6), -top)
	f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", filterMenu, 14)
	f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -top)
	Theme.Skin(f.psFilter, "editbox")

	W.ShellTabs(f, nil)
	ns.LinkPlace(f)
	f.psTabs = ns.ProfessionTabs(f, function()
		f:Hide()
		ns.Show("professions")
	end)
	-- The stock window's sounds: it never opens now to play them. Closing
	-- ours ends the trade skill, as closing the stock window does.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN) end)
	f:HookScript("OnHide", function()
		PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE)
		if not closing then C_TradeSkillUI.CloseTradeSkill() end
		closing, wanted = nil, nil
	end)
	Polestar.CloseOnEscape(NAME)
end

function M.Show()
	local p = profession()
	if not p then return end
	if not f then build() end
	if f.psProf ~= p.professionID then
		f.psProf = p.professionID
		sel, selKey, qty, query, target = lastSel[p.professionID], nil, 1, "", nil
		f.Search:SetText("")
	end
	closing = nil
	refresh()
	f:Show()
end

function M.Enable()
	-- The game's crafting window ends the trade skill as it hides, so it
	-- cannot be closed under ours: the game's open is stopped instead, and
	-- ours opens on the same event (docs/CLIENT.md, rule 11).
	if GameEvent and GameEvent.UnregisterInternalEvent then GameEvent.UnregisterInternalEvent("TRADE_SKILL_SHOW") end
	Polestar.RegisterEvent("TRADE_SKILL_SHOW", function()
		wanted = true
		M.Show()
	end)
	Polestar.RegisterEvent("TRADE_SKILL_CLOSE", function()
		wanted = nil
		if f and f:IsShown() then
			closing = true
			f:Hide()
		end
	end)
	-- Bags, ranks and item names change in bursts: one redraw a frame.
	local pending
	local function changed()
		if wanted and not (f and f:IsShown()) then return M.Show() end
		if pending or not (f and f:IsShown()) then return end
		pending = true
		C_Timer.After(0, function()
			pending = nil
			if f:IsShown() and not (C_TradeSkillUI.IsDataSourceChanging and C_TradeSkillUI.IsDataSourceChanging()) then refresh() end
		end)
	end
	for _, e in ipairs({ "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_NAME_UPDATE", "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED",
		"GET_ITEM_INFO_RECEIVED", "SPELL_UPDATE_COOLDOWN" }) do
		Polestar.RegisterEvent(e, changed)
	end
	Theme.OnChanged(changed)
end

ns.Module("crafting", M)
