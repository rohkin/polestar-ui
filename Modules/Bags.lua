-- The Bags (docs/windows/bags.md): the player's bags in a Polestar shell, in
-- place of the stock ContainerFrameCombinedBags and ContainerFrame1..N.
-- Every slot is the stock ContainerFrameItemButtonTemplate, made by us and
-- restyled: a click starts in Blizzard's own scripts, so right-click use,
-- selling, splitting and applying a waiting spell are the game's, in combat
-- too. Nothing the template reads is written by us: its bag is its parent's
-- GetID (a holder frame per bag), its slot its own GetID, and we add only
-- ps* keys, our icon (w.Icon) and hooks (HookScript).

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUIBags"
local COLS, SIZE, GAP = 11, 36, 4 -- Bank's grid
local GRID_W = COLS * (SIZE + GAP) - GAP
local STRIP = 28 -- the equipped bags' wells on the first row
local TOP = 16 + STRIP + 16 -- the grid starts under the first row
local MAX_H = 600 -- past this the body scrolls

local f, money, strip, grid
local holders, wells = {}, {} -- per bag: the holder frame (its ID the bag), its wells by slot
local newItems = {} -- "bag:slot" of new items, kept past a stock close (it clears the flags)
local opener -- the frame that opened ours (the stock FRAME_THAT_OPENED_BAGS), by name
local made = 0
local M = {}
local paint

local function combined() return GetCVar("combinedBags") ~= "0" end

-- The bags shown, in groups each starting a new row: the backpack and the
-- equipped bags; the reagent bag; the keyring when the game shows it.
-- shortcut: one grid for every bag; stage 2 of bags.md gives the reagent bag,
-- the keyring and the separate look sections of their own.
local function groups()
	local held = {}
	for bag = 0, Constants.InventoryConstants.NumBagSlots do held[#held + 1] = bag end
	local out = { held, { Constants.InventoryConstants.NumBagSlots + 1 } }
	if C_ActionBar.ShouldShowKeyring() and GetCVarBool("showKeyring") then out[#out + 1] = { KEYRING_CONTAINER } end
	return out
end

local function numSlots(bag)
	if bag == KEYRING_CONTAINER then return GetKeyRingSize() end
	return C_Container.GetContainerNumSlots(bag)
end

local function key(bag, slot) return bag .. ":" .. slot end

---------------------------------------------------------------------------
-- The wells
---------------------------------------------------------------------------

local function holder(bag)
	local h = holders[bag]
	if not h then
		h = CreateFrame("Frame", nil, grid)
		h:SetAllPoints(grid)
		h:SetID(bag) -- the template's GetBagID reads it (never SetBagID: bags.md)
		holders[bag], wells[bag] = h, {}
	end
	return h
end

local function makeWell(bag, slot)
	made = made + 1
	-- Named: the template names its cooldown $parentCooldown.
	local w = ns.ItemWell(holder(bag), SIZE, "ItemButton", "ContainerFrameItemButtonTemplate", NAME .. "Item" .. made)
	w:SetID(slot)
	-- The template's own registration does not take on a button addon code
	-- makes: without this, a right-click does nothing (docs/CLIENT.md, rule 18).
	w:RegisterForClicks("AnyUp")
	w:SetFrameLevel(holders[bag]:GetFrameLevel() + 2)
	w.psBag, w.psSlot = bag, slot
	-- The template's art out; ours is the well's (ns.ItemWell) and W.Hover.
	w:ClearNormalTexture()
	w:ClearPushedTexture()
	w:ClearHighlightTexture()
	w.IconBorder:SetAlpha(0)
	w.BattlepayItemTexture:Hide()
	W.Hover(w)
	-- New items: an accent edge, pulsing, until hovered or ours closes.
	local edge = CreateFrame("Frame", nil, w)
	edge:SetAllPoints(w)
	edge:SetFrameLevel(w:GetFrameLevel() + 3)
	W.Painter(edge, function(e) local r, g, b = Theme.Accent(); Theme.Border(e, r, g, b, 1, "OVERLAY", 2) end)
	local pulse = edge:CreateAnimationGroup()
	pulse:SetLooping("BOUNCE")
	local a = pulse:CreateAnimation("Alpha")
	a:SetFromAlpha(1)
	a:SetToAlpha(0.3)
	a:SetDuration(0.6)
	edge:SetScript("OnShow", function() pulse:Play() end)
	edge:SetScript("OnHide", function() pulse:Stop() end)
	edge:Hide()
	w.psNew = edge
	-- The template's hover clears the game's flag (RemoveNewItem); ours follows.
	w:HookScript("OnEnter", function(self)
		newItems[key(self.psBag, self.psSlot)] = nil
		self.psNew:Hide()
	end)
	wells[bag][slot] = w
	return w
end

-- One slot as the stock bags show it: icon, quality, count, locked, search
-- miss, quest mark, cooldown, new. Values the client may hand over secret in
-- combat are read clean (docs/CLIENT.md, rule 3). Returns the item, if any.
local function paintSlot(w)
	local bag, slot = w.psBag, w.psSlot
	local it = C_Container.GetContainerItemInfo(bag, slot)
	ns.PaintItem(w, it and { icon = it.iconFileID, quality = ns.Clean(it.quality), count = ns.Num(it.stackCount), desat = ns.Clean(it.isLocked) })
	-- The frame's own SetAlpha: the template's (ItemButtonMixin) fades only its parts, none of them ours.
	UIParent.SetAlpha(w, it and ns.Clean(it.isFiltered) and 0.25 or 1)
	local q = it and C_Container.GetContainerItemQuestInfo(bag, slot)
	w:UpdateQuestItem(q and q.isQuestItem, q and q.questID, q and q.isActive)
	local start, duration, enable = C_Container.GetContainerItemCooldown(bag, slot)
	if it and ns.Clean(start) and ns.Clean(duration) then CooldownFrame_Set(w.Cooldown, start, duration, ns.Clean(enable)) end
	if it and ns.Clean(enable) == 0 then w.Icon:SetVertexColor(0.4, 0.4, 0.4) end
	local k = key(bag, slot)
	if it and C_NewItems.IsNewItem(bag, slot) then newItems[k] = true end
	if not it then newItems[k] = nil end
	w.psNew:SetShown(newItems[k] or false)
	return it
end

-- Lays every shown bag's wells out in the grid; returns the free and total
-- slots of the backpack and equipped bags (the stock count's).
local function layout()
	local i, free, total = 0, 0, 0
	for g, bags in ipairs(groups()) do
		if g > 1 and i % COLS > 0 then i = i + COLS - i % COLS end
		for _, bag in ipairs(bags) do
			holder(bag)
			local n = numSlots(bag)
			for slot = 1, n do
				local w = wells[bag][slot] or makeWell(bag, slot)
				w:ClearAllPoints() -- the template anchors itself BOTTOMRIGHT of its parent
				w:SetPoint("TOPLEFT", grid, "TOPLEFT", (i % COLS) * (SIZE + GAP), -math.floor(i / COLS) * (SIZE + GAP))
				w:Show()
				i = i + 1
				local it = paintSlot(w)
				if g == 1 then
					total = total + 1
					if not it then free = free + 1 end
				end
			end
			for slot = n + 1, #wells[bag] do wells[bag][slot]:Hide() end
		end
	end
	-- Never 0 high (docs/CLIENT.md, rule 12).
	grid:SetHeight(math.max(1, math.ceil(i / COLS) * (SIZE + GAP) - GAP))
	return free, total
end

---------------------------------------------------------------------------
-- The equipped bags (first row)
---------------------------------------------------------------------------

local function paintStrip()
	local bags = {}
	for bag = 0, Constants.InventoryConstants.NumBagSlots + 1 do bags[#bags + 1] = bag end
	for k, b in ipairs(strip.Layout(#bags)) do
		local bag = bags[k]
		b.psInv = bag > 0 and C_Container.ContainerIDToInventoryID(bag) or nil
		local icon = bag == 0 and "Interface\\Buttons\\Button-Backpack-Up" or GetInventoryItemTexture("player", b.psInv)
		ns.PaintItem(b, { icon = icon or "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag", quality = b.psInv and GetInventoryItemQuality("player", b.psInv) })
		b:SetAlpha(icon and 1 or 0.45)
		if not b.psStrip then
			b.psStrip = true
			b:HookScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				if not (self.psInv and GameTooltip:SetInventoryItem("player", self.psInv)) then
					GameTooltip:SetText(self.psInv and "Bag slot" or BACKPACK_TOOLTIP or "Backpack")
				end
				GameTooltip:Show()
			end)
			b:HookScript("OnLeave", W.HideTooltip)
		end
	end
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------

local function cleanUp()
	PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
	C_Container.SortBags()
end

local function menu()
	local on = combined()
	return { { text = on and "Separate bags" or "Combine bags", onClick = function()
		SetCVar("combinedBags", on and "0" or "1")
		paint()
	end } }
end

local function build()
	-- As wide as the grid needs: its columns, the compact pad (ns.Compact's) each side, the frame's 2px edge.
	local width = GRID_W + 2 * (W.SHELL.pad - 8) + 2
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = width, height = 400, searchPlaceholder = "Search the bags",
		onSearch = function(text) C_Container.SetItemSearch(text or "") end })
	ns.Float(f)
	ns.WindowMenu(f, "bags", menu)
	ns.Plain(f)
	ns.Compact(f)
	ns.TopNav(f, {}, nil, function() end) -- the search onto the tab row
	strip = ns.ItemGrid(f.Body, 6, STRIP, 4)
	strip:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -16)
	f.psStrip = strip
	money = ns.Money(f.Body)
	money:SetPoint("RIGHT", f.Body, "TOPRIGHT", -f.psPad, -16 - STRIP / 2)
	grid = CreateFrame("Frame", nil, f.Body)
	grid:SetSize(GRID_W, 1)
	grid:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -TOP)
	f.psGrid = grid
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_BACKPACK_OPEN) end)
	f:HookScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
		opener = nil
		-- As the stock frame's hide (UpdateNewItemList): seen now, no longer new.
		for bag, row in pairs(wells) do
			for slot, w in pairs(row) do
				if w:IsShown() then C_NewItems.RemoveNewItem(bag, slot) end
			end
		end
		newItems = {}
		-- The client's one search is the bank's too: ours ends only what it set.
		if f.Search:GetText() ~= "" then
			f.Search:SetText("")
			C_Container.SetItemSearch("")
		end
	end)
	Polestar.CloseOnEscape(NAME)
end

function paint()
	local free, total = layout()
	paintStrip()
	ns.SetMoney(money, GetMoney())
	local who = ns.PlayerText(UnitName)
	local sub = ("%d of %d free."):format(free, total)
	W.ShellTitle(f, "Bags", who and (who .. " · " .. sub) or sub)
	local h = TOP + grid:GetHeight() + 24
	f:SetHeight(math.min(MAX_H, f.psHead + f.psTabsH + f.psFootH + h + 2))
	ns.Footer(f, { { label = "Clean up", onClick = cleanUp } }, {}) -- after the height: it lays the view out
	W.ShellBody(f, h)
end

local function open()
	if (f and f:IsShown()) or not ContainerFrame_AllowedToOpenBags() then return end
	if not f then build() end
	paint()
	f:Show()
end

local function close()
	if f then f:Hide() end
end

local function toggle()
	if f and f:IsShown() then close() else open() end
end

M.Show = open

-- ns.OpenBags / ns.CloseBags (Core.lua): an NPC window of ours opens ours and
-- closes it only if it opened it, as the stock FRAME_THAT_OPENED_BAGS.
function M.Open(frame)
	if f and f:IsShown() then return end
	open()
	if f and f:IsShown() then opener = frame and frame:GetName() end
end
function M.Close(frame)
	if frame and frame:GetName() ~= opener then return end
	close()
end

---------------------------------------------------------------------------
-- The game's doors
---------------------------------------------------------------------------

-- While ours is on, the stock bag frames live under a hidden frame of ours
-- (docs/CLIENT.md, rule 19): the game's toggles still open and close them,
-- their state stays the game's, but they never show, so their OnShow/OnHide
-- never run, from our code or any, and nothing of theirs is tainted. Moved
-- only while hidden (a shown one moved would run its OnShow/OnHide as ours);
-- one shown when ours switched on is parked once it closes.
local parked = {} -- stock frame -> its own parent
local hider
local function reparent(fr, p)
	local strata, level = fr:GetFrameStrata(), fr:GetFrameLevel()
	fr:SetParent(p)
	fr:SetFrameStrata(strata)
	fr:SetFrameLevel(level)
end
local function park()
	if not hider then
		hider = CreateFrame("Frame", nil, UIParent)
		hider:SetAllPoints(UIParent) -- the stock frames anchor to their parent's corner
		hider:Hide()
	end
	local frames = { ContainerFrameCombinedBags }
	for i = 1, NUM_CONTAINER_FRAMES do frames[#frames + 1] = _G["ContainerFrame" .. i] end
	for _, fr in ipairs(frames) do
		if not parked[fr] and not fr:IsShown() then
			parked[fr] = fr:GetParent()
			reparent(fr, hider)
		end
	end
end
-- Switched off: each given back closed. Hide() first, while invisible (no
-- script runs): given back shown, it would show and run its OnShow as ours.
local function unpark()
	for fr, p in pairs(parked) do
		fr:Hide()
		reparent(fr, p)
	end
	parked = {}
end

-- The stock toggles open from the inside (ToggleAllBags -> OpenBackpack ->
-- OpenBag), and the parked frames' state need not be ours (ours also opens
-- and closes on its own): so what the game asked is decided once, at the end
-- of the frame, from ours as it was at the first call of that frame. Any toggle flips it;
-- else an open opens it and a close closes it.
local pending
local function settle()
	local p = pending
	pending = nil
	if p.toggle then
		if p.was then close() else open() end
	elseif p.open then
		open()
		if p.opener and f and f:IsShown() then opener = p.opener end
	elseif p.close then
		close()
	end
end

local function asked(kind, frame)
	if not ns.Enabled("bags") then return end
	park()
	if not pending then
		pending = { was = f and f:IsShown() or false }
		C_Timer.After(0, settle)
	end
	if kind == "close" then
		-- Only the frame that opened ours (or none named) closes it.
		if frame and frame:GetName() ~= opener then return end
	elseif kind == "open" and frame and not pending.was and not pending.opener then
		pending.opener = frame:GetName()
	end
	pending[kind] = true
end

function M.Enable()
	-- The preview loads the stock bags only in bag scenes (stub_bags.lua).
	if not ToggleAllBags then return end
	-- The keys open ours and run no stock code (docs/CLIENT.md, rule 8); the bag
	-- bar stays the game's (rule 17): its clicks run the stock toggles on the
	-- parked frames, and the hooks below follow them.
	-- shortcut: every key toggles the whole window until stage 2's sections.
	local keys = {}
	for _, k in ipairs({ "OPENALLBAGS", "TOGGLEBACKPACK", "TOGGLEBAG1", "TOGGLEBAG2", "TOGGLEBAG3", "TOGGLEBAG4", "TOGGLEREAGENTBAG1" }) do keys[k] = toggle end
	ns.Doors("bags", "Bags", keys)
	for _, fn in ipairs({ "ToggleAllBags", "ToggleBackpack", "ToggleBag" }) do hooksecurefunc(fn, function() asked("toggle") end) end
	for _, fn in ipairs({ "OpenBag", "OpenBackpack" }) do hooksecurefunc(fn, function() asked("open") end) end
	for _, fn in ipairs({ "OpenAllBags", "OpenAllBagsMatchingContext" }) do hooksecurefunc(fn, function(frame) asked("open", frame) end) end
	-- Not CloseBag/CloseBackpack: CloseAllBags calls them past its own opener
	-- check (the stock one's), which need not be ours.
	hooksecurefunc("CloseAllBags", function(frame) asked("close", frame) end)
	for _, e in ipairs({ "BAG_UPDATE_DELAYED", "BAG_CONTAINER_UPDATE", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN", "INVENTORY_SEARCH_UPDATE",
		"BAG_NEW_ITEMS_UPDATED", "QUEST_ACCEPTED", "UNIT_QUEST_LOG_CHANGED", "PLAYER_MONEY", "PLAYER_REGEN_ENABLED" }) do
		Polestar.RegisterEvent(e, function() if f and f:IsShown() then paint() end end)
	end
	M.ready = true
	park()
end

-- ns.Switch: on parks the stock frames, off gives them back, live.
function M.Apply()
	if not M.ready then return end
	if ns.Enabled("bags") then park() else unpark() end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() and ContainerFrameCombinedBags end

ns.Module("bags", M)
