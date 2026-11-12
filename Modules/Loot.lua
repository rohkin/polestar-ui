-- The Loot (docs/windows/loot.md): a small Polestar panel for the open loot.
-- The stock LootFrame ends the loot as it hides (CloseLoot), so it is never
-- opened: its own LOOT_OPENED is unregistered (docs/CLIENT.md, rule 15's
-- exception) and ours opens on it. LootSlot is plain Lua, not protected.
-- Auto-loot (the CVar and its modifier) is the game's: it loots the slots
-- itself and ours shows them clearing, as the stock window. Group rolls
-- (GroupLootFrame), the bind and roll confirms (StaticPopups shown by
-- GameEvent) and master loot's menu stay the game's.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUILoot"
local WIDTH, ROW_H, ICON, TOP, PAD = 240, 40, 32, 52, 12

local f
local rows, cleared = {}, {}
local ended -- the game closed the loot: hiding ours must not close it again
local M = { reloadOff = true }

local function enter(r)
	local t = GetLootSlotType(r.psSlot)
	if t ~= Enum.LootSlotType.Item and t ~= Enum.LootSlotType.Currency then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	if t == Enum.LootSlotType.Currency then GameTooltip:SetLootCurrency(r.psSlot) else GameTooltip:SetLootItem(r.psSlot) end
	GameTooltip:Show()
end

-- As the stock row: a modified click links (Polestar's HandleModifiedItemClick hook sees it), else loots.
local function click(r)
	if IsModifiedClick() then return HandleModifiedItemClick(GetLootSlotLink(r.psSlot)) end
	LootSlot(r.psSlot)
end

local function newRow(n)
	local r = CreateFrame("Button", nil, f)
	r:SetSize(WIDTH - 2 * PAD + 8, ROW_H)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	W.Hover(r)
	r.Well = ns.ItemWell(r, ICON)
	r.Well:SetPoint("LEFT", r, "LEFT", 4, 0)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("LEFT", r.Well, "RIGHT", 10, 0)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -4, 0)
	r.Name:SetJustifyH("LEFT")
	r.Name:SetWordWrap(false)
	r:SetScript("OnClick", click)
	r:SetScript("OnEnter", enter)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[n] = r
	return r
end

local function paint()
	f.Title:SetText(IsFishingLoot() and "Fishing" or "Loot")
	local n = 0
	for slot = 1, GetNumLootItems() do
		local icon, name, count, _, quality, locked, _, _, _, isCoin = GetLootSlotInfo(slot)
		if icon and not cleared[slot] then
			n = n + 1
			local r = rows[n] or newRow(n)
			r.psSlot = slot
			r:SetPoint("TOPLEFT", f, "TOPLEFT", PAD - 4, -(TOP + (n - 1) * ROW_H))
			quality = not isCoin and ns.Clean(quality) or nil
			ns.PaintItem(r.Well, { icon = icon, quality = quality, count = ns.Num(count), unusable = locked })
			-- A coin slot's name is the game's money text ("1 Silver\n50 Copper"); no copper amount is given.
			r.Name:SetText((name or ""):gsub("\n", " "))
			W.Uncolor(r.Name)
			local qr, qg, qb = ns.QualityRGB(quality)
			if qr then r.Name:SetTextColor(Theme.Legible(qr, qg, qb)) else W.Color(r.Name, "text") end
			r:Show()
		end
	end
	for i = n + 1, #rows do rows[i]:Hide() end
	f:SetHeight(TOP + math.max(n, 1) * ROW_H + PAD)
end

local function build()
	f = CreateFrame("Frame", NAME, UIParent)
	f:SetWidth(WIDTH)
	f:SetFrameStrata("HIGH")
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	Theme.Skin(f, "window")
	f.Title = W.Text(f, "heading", "text")
	f.Title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 4, -18)
	f.Close = W.IconButton(f, "close", 28, "Close", function() f:Hide() end, 14)
	f.Close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
	f.psRows = rows
	f:Hide()
	f:SetScript("OnHide", function()
		if not ended then CloseLoot() end
		ended = nil
	end)
	Polestar.CloseOnEscape(NAME)
end

-- At the cursor with lootUnderMouse, as LootFrameMixin:Open places it.
local function place()
	f:ClearAllPoints()
	if GetCVarBool("lootUnderMouse") then
		local x, y = GetCursorPosition()
		local s = f:GetEffectiveScale()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s - 30, math.max(y / s + 50, 350))
	else
		-- shortcut: the stock Edit Mode default, not a moved LootFrame's place; read the layout if players ask.
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
	end
end

-- Shown only on the game's LOOT_OPENED: with no loot open there is nothing to show.
function M.Show()
	if not f then build() end
	place()
	paint()
	f:Show()
	f:Raise()
end

function M.Enable()
	if not f then build() end
	-- The stock window's own open, stopped (docs/CLIENT.md, rule 15's exception).
	if LootFrame then LootFrame:UnregisterEvent("LOOT_OPENED") end
	Polestar.RegisterEvent("LOOT_OPENED", function(_, _, fromItem)
		cleared, ended = {}, nil
		M.Show()
		if fromItem then PlaySound(SOUNDKIT.UI_CONTAINER_ITEM_OPEN) elseif IsFishingLoot() then PlaySound(SOUNDKIT.FISHING_REEL_IN) end
	end)
	Polestar.RegisterEvent("LOOT_SLOT_CLEARED", function(_, slot)
		cleared[slot] = true
		if f:IsShown() then paint() end
	end)
	Polestar.RegisterEvent("LOOT_SLOT_CHANGED", function() if f:IsShown() then paint() end end)
	Polestar.RegisterEvent("LOOT_CLOSED", function()
		if not f:IsShown() then return end
		ended = true
		f:Hide()
	end)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return LootFrame and LootFrame:IsShown() and LootFrame end

ns.Module("loot", M)
