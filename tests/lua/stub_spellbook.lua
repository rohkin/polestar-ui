-- The client calls the Spellbook reads; the values are the preview's sample
-- mage: General, Arcane and Fire, a few ranks, a passive, a future spell.
function UnitLevel(unit) return 24 end
function UnitClass(unit) return "Mage", "MAGE", 8 end
function GetClassAtlas(className) return ("classicon-%s"):format(className) end

Enum.SpellBookSpellBank = { Player = 0, Pet = 1 }
Enum.SpellBookItemType = { None = 0, Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 }

-- { name, rank, cost, cast ms, passive, type, low rank, -, loose flyout member: its flyout's slot, flyout ID }
local BOOK = {
	{ "Attack", "", 0, 0 },
	{ "Shoot", "", 0, 1500 },
	{ "Hearthstone", "", 0, 10000 },
	{ "Arcane Intellect", "Rank 2", 180, 0 },
	{ "Arcane Missiles", "Rank 3", 195, 0 },
	{ "Arcane Missiles", "Rank 2", 140, 0, false, 1, true },
	{ "Blink", "", 105, 0 },
	{ "Arcane Mind", "Rank 1", 0, 0, true },
	{ "Evocation", "", 0, 0, false, 2 },
	{ "Fireball", "Rank 5", 150, 3500 },
	{ "Fire Blast", "Rank 3", 115, 0 },
	{ "Scorch", "Rank 2", 75, 1500 },
	{ "Flamestrike", "Rank 2", 260, 3000 },
	{ "Improved Fireball", "Rank 3", 0, 0, true },
	{ "Pyroblast", "Rank 1", 125, 6000 },
	-- A flyout (its two portals, each a loose spell of the book too).
	{ "Portals", "", 0, 0, false, 4, false, nil, nil, 1 },
	{ "Portal: Stormwind", "", 850, 10000, false, 1, false, nil, 16 },
	{ "Portal: Ironforge", "", 850, 10000, false, 1, false, nil, 16 },
	-- stub.warlock: Summon Demon, a flyout whose spells are hidden from the
	-- book (found only with includeHidden); Succubus not learnt, not in the book.
	{ "Summon Demon", "", 0, 0, false, 4, false, nil, nil, 2 },
	{ "Summon Imp", "", 64, 10000, false, 1, false, nil, 19 },
	{ "Summon Voidwalker", "", 120, 10000, false, 1, false, nil, 19 },
}
local FLYOUTS = { [1] = { "Portals", { 117, 118 } }, [2] = { "Summon Demon", { 120, 121, 199 } } }
local LINES = { { "General", 0, 3 }, { "Arcane", 3, 6 }, { "Fire", 9, 9 } }
local function lines() return stub.warlock and { LINES[1], LINES[2], LINES[3], { "Demonology", 18, 3 } } or LINES end
C_SpellBook = {}
function C_SpellBook.GetNumSpellBookSkillLines() return #lines() end
function C_SpellBook.GetSpellBookSkillLineInfo(i)
	local l = lines()[i]
	return l and { name = l[1], iconID = 135900 + i, itemIndexOffset = l[2], numSpellBookItems = l[3], shouldHide = false }
end
-- The stock tabs' icons: the class's skill line for General, the pet's.
function C_SpellBook.GetClassSkillLineInfo() return { name = "Mage", iconID = 626001 } end
function GetPetIcon() return 132270 end
-- stub.pet: a pet with a spellbook; Growl autocasts, Claw may, Attack is a command.
local PET_BOOK = { { "Growl", "Rank 2", 0, 0, false, 1, false, true }, { "Claw", "Rank 1", 0, 0, false, 1, false, false },
	{ "Attack", "", 0, 0, false, 3 } }
function PetHasSpellbook() return stub.pet or false end
function C_SpellBook.HasPetSpells() return stub.pet and #PET_BOOK or nil end
function C_SpellBook.GetSpellBookItemAutoCast(slot, bank)
	local s = bank == 1 and PET_BOOK[slot]
	if not s or s[8] == nil then return false, false end
	return true, s[8]
end
-- Fire Blast is cooling down.
function C_SpellBook.GetSpellBookItemCooldown(slot, bank)
	if bank == 0 and slot == 11 then return { startTime = 1, duration = 8, isEnabled = true, modRate = 1 } end
	return { startTime = 0, duration = 0, isEnabled = false, modRate = 1 }
end
function C_SpellBook.GetSpellBookItemInfo(slot, bank)
	local s = (bank == 1 and PET_BOOK or BOOK)[slot]
	if not s then return end
	local flyout = s[6] == 4
	return { actionID = flyout and s[10] or 100 + slot, spellID = not flyout and 100 + slot or nil, itemType = s[6] or 1, name = s[1], subName = s[2], iconID = 1,
		isPassive = s[5] or false, isOffSpec = false }
end
function C_SpellBook.IsSpellBookItemLowRank(slot) return BOOK[slot] and BOOK[slot][7] or false end
function C_SpellBook.IsSpellBookItemLooseFlyoutMember(slot, bank) return bank == 0 and BOOK[slot] and BOOK[slot][9] or false end
-- Flyout 1, the portals (the book's slots 17 and 18); 2, Summon Demon.
function GetFlyoutInfo(id) local f = FLYOUTS[id]; if f then return f[1], "", #f[2], true end end
function GetFlyoutSlotInfo(id, i)
	local spell = FLYOUTS[id][2][i]
	local s = BOOK[spell - 100]
	return spell, spell, s ~= nil, s and s[1] or "Summon Succubus", 0
end
function C_SpellBook.GetSpellBookItemLevelLearned(slot) return 26 end
-- As the client: a flyout's spell is hidden from the book, so without
-- includeHidden the search finds the flyout holding it (includeFlyouts, on
-- by default), not the spell.
function C_SpellBook.FindSpellBookSlotForSpell(id, includeHidden, includeFlyouts)
	local slot = id - 100
	local s = BOOK[slot]
	if not s then return end
	if s[9] and not includeHidden then
		if includeFlyouts == false then return end
		return s[9], 0
	end
	return slot, 0
end
function C_SpellBook.GetSpellBookItemLink(slot) return "|Hspell:" .. (100 + slot) .. "|h[" .. BOOK[slot][1] .. "]|h" end
-- The client blocks a spell pickup from addon code in combat (ADDON_ACTION_BLOCKED).
function C_SpellBook.PickupSpellBookItem(slot, bank)
	if stub.inCombat then
		stub.blocked = stub.blocked or {}
		return table.insert(stub.blocked, "PickupSpellBookItem")
	end
	stub.pickedSpell = slot
end
C_Spell = C_Spell or {}
-- A spell by ID; the warlock's slots (19 on) only for stub.warlock: the professions stub uses those IDs.
local function spell(id) local slot = id - 100; if slot > 18 and not stub.warlock then return nil end return BOOK[slot] end
function C_Spell.GetSpellPowerCost(id)
	local s = spell(id)
	return s and s[3] > 0 and { { name = "MANA", cost = s[3] } } or {}
end
function C_Spell.GetSpellInfo(id) local s = spell(id); return s and { castTime = s[4] } end
MANA, PET = "Mana", "Pet"
ChatFrameUtil = { InsertLink = function(link) stub.linked = link end }

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
PlayerSpellsFrame = CreateFrame("Frame", "PlayerSpellsFrame", UIParent)
PlayerSpellsFrame:Hide()
function PlayerSpellsFrame.Hide() error("addon code hid PlayerSpellsFrame", 2) end
function stub.bindingRun.TOGGLESPELLBOOK() PlayerSpellsFrame:Show() end
SpellbookMicroButton = CreateFrame("Button", "SpellbookMicroButton", UIParent)
SpellbookMicroButton.tooltipText = "Spellbook & Abilities (P)"
-- The action bars, as ActionButtonUtil reads them: Blink is on none.
ActionButtonUtil = { ActionBarActionStatus = { NotMissing = 1, MissingFromAllBars = 2, OnInactiveBonusBar = 3, OnDisabledActionBar = 4 } }
function ActionButtonUtil.GetActionBarStatusForSpell(id) return id == 107 and 2 or 1 end
function ActionButtonUtil.GetActionBarStatusForPetAction() return 1 end
function ActionButtonUtil.GetActionBarStatusForFlyout() return 1 end
TALENT_BUTTON_TOOLTIP_NOT_ON_ACTION_BAR = "Not on your action bars"
