-- The client calls the Character window reads (tests/lua/wow_stub.lua has
-- UnitName only); the values are the preview's sample character.
function UnitLevel(unit) return 24 end
function UnitRace(unit) return "Human", "Human" end
function UnitClass(unit) return "Warrior", "WARRIOR", 1 end
function UnitPVPName(unit) return "Testchar" end
function ToggleCharacter(tab, onlyShow) end

-- Gear: the client's slot ids; a few items of each quality, one worn down,
-- one broken, the rest empty. Icons are client art, which the preview does
-- not draw: the wells and their borders show.
local SLOT_IDS = { AmmoSlot = 0, HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4, ChestSlot = 5, WaistSlot = 6,
	LegsSlot = 7, FeetSlot = 8, WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12, Trinket0Slot = 13,
	Trinket1Slot = 14, BackSlot = 15, MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18, TabardSlot = 19 }
C_PaperDollInfo = C_PaperDollInfo or {}
function C_PaperDollInfo.GetInventorySlotInfo(name)
	return SLOT_IDS[name], "Interface/PaperDoll/UI-PaperDoll-Slot-" .. name, false
end
ITEM_QUALITY_COLORS = { [1] = { r = 1, g = 1, b = 1 }, [2] = { r = 0.12, g = 1, b = 0 }, [3] = { r = 0, g = 0.44, b = 0.87 }, [4] = { r = 0.64, g = 0.21, b = 0.93 } }
-- slot id = { quality, durability left (fraction), broken }
local GEAR = { [1] = { 3, 1 }, [3] = { 2, 1 }, [5] = { 4, 1 }, [7] = { 2, 0.2 }, [8] = { 1, 1 }, [10] = { 2, 0, true }, [15] = { 1, 1 }, [16] = { 3, 1 }, [18] = { 2, 1 } }
function GetInventoryItemTexture(unit, id) return GEAR[id] and 134400 or nil end
function GetInventoryItemQuality(unit, id) return GEAR[id] and GEAR[id][1] end
function GetInventoryItemBroken(unit, id) return GEAR[id] and GEAR[id][3] or false end
function GetInventoryItemDurability(id) if GEAR[id] then return GEAR[id][2] * 100, 100 end end
function GetInventoryItemLink(unit, id) return nil end
