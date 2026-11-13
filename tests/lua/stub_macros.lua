-- The client's macros and MacroFrame as the Macros window sees them; the
-- values are the preview's sample warrior's macros.
-- stub.macros: { general = { {name, icon, body} }, character = {...} }, kept
-- sorted by name as the client keeps them. stub.blocked: a macro call our
-- code made in combat (the client refuses it). stub.pickedMacro: the last
-- PickupMacro. stub.cursorInfo: what GetCursorInfo answers.

Constants = Constants or {}
Constants.MacroConsts = { MAX_ACCOUNT_MACROS = 120, MAX_CHARACTER_MACROS = 30 }

-- The game's window: shown by the game's ShowMacroFrame (every door: /macro,
-- the game menu, the chat menu); its own close button hides it.
MacroFrame = CreateFrame("Frame", "MacroFrame", UIParent)
MacroFrame:Hide()
MacroFrame:SetSize(338, 424)
MacroFrame.x, MacroFrame.y = 16, 100
MacroFrame.CloseButton = CreateFrame("Button", nil, MacroFrame)
MacroFrame.CloseButton:SetScript("OnClick", function() MacroFrame:Hide() end)
function ShowMacroFrame() MacroFrame:Show() end

local QUESTION = 134400
stub.macros = {
	general = {
		{ "Assist", 132333, "/assist [@focus]" },
		{ "Charge", QUESTION, "#showtooltip\n/cast [@mouseover,harm][] Charge" },
		{ "Hearth", 134414, "/use Hearthstone" },
		{ "Mount", 132261, "/cast [nomounted] Summon Warhorse\n/dismount [mounted]" },
		{ "Pull", 132349, "/y Pulling %t!\n/cast Shoot" },
		{ "Shout", 132333, "/cast Battle Shout" },
		{ "Sunder", 132363, "#showtooltip\n/startattack\n/cast Sunder Armor" },
		{ "Taunt", 136080, "/cast Taunt\n/s Taunted %t" },
		{ "Trinket", 133434, "/use 13\n/use 14" },
		{ "Whisper", 133458, "/w %t Need a hand?" },
		{ "Zone", 134269, "/run print(GetZoneText())" },
		{ "Rend", 132155, "/cast Rend" },
	},
	character = {
		{ "Bandage", 133688, "/use [@player] Heavy Linen Bandage" },
		{ "Stance", 132349, "/cast [stance:1] Defensive Stance; Battle Stance" },
	},
}
local function sort(list) table.sort(list, function(a, b) return a[1] < b[1] end) end
sort(stub.macros.general)
sort(stub.macros.character)

local function where(i)
	if i > 120 then return stub.macros.character, i - 120, 120 end
	return stub.macros.general, i, 0
end
local function refused(what)
	if InCombatLockdown() then stub.blocked = what return true end
end
local function changed()
	stub.fire("UPDATE_MACROS")
end

function GetNumMacros() return #stub.macros.general, #stub.macros.character end
function GetMacroInfo(i)
	local list, k = where(i)
	local m = list[k]
	if not m then return end
	-- "?": the macro wears its spell's icon.
	return m[1], m[2] == QUESTION and 132337 or m[2], m[3]
end
C_Macro = C_Macro or {}
function C_Macro.GetSelectedMacroIcon(i)
	local list, k = where(i)
	return list[k] and list[k][2]
end
function C_Macro.GetMacroName(i) return (GetMacroInfo(i)) end
-- Returns the macro's index after it is sorted in.
local function placed(list, m, at)
	sort(list)
	for k, x in ipairs(list) do if x == m then return k + at end end
end
function CreateMacro(name, icon, body, perCharacter)
	if refused("CreateMacro") then return end
	local list = perCharacter and stub.macros.character or stub.macros.general
	assert(#list < (perCharacter and 30 or 120), "CreateMacro: no free slot")
	local m = { name, icon, body or "" }
	table.insert(list, m)
	local i = placed(list, m, perCharacter and 120 or 0)
	stub.created = { name, icon, body, perCharacter }
	changed()
	return i
end
function EditMacro(i, name, icon, body)
	if refused("EditMacro") then return end
	local list, k, at = where(i)
	local m = assert(list[k], "EditMacro: no macro " .. i)
	m[1], m[2], m[3] = name or m[1], icon or m[2], body or m[3]
	stub.edited = { i, name, icon, body }
	local n = placed(list, m, at)
	changed()
	return n
end
function DeleteMacro(i)
	if refused("DeleteMacro") then return end
	local list, k = where(i)
	table.remove(list, k)
	changed()
end
function PickupMacro(i) stub.pickedMacro = i end

-- The icon lists the picker reads: a few names, then file numbers.
function GetLooseMacroIcons(t) t[#t + 1] = "Ability_Warrior_Charge"; t[#t + 1] = "Ability_Warrior_Sunder" end
function GetMacroIcons(t) for k = 1, 60 do t[#t + 1] = 132000 + k end end
function GetLooseMacroItemIcons(t) t[#t + 1] = "INV_Misc_Bandage_15" end
function GetMacroItemIcons(t) for k = 1, 40 do t[#t + 1] = 133000 + k end end

-- The cursor: an item, spell, mount... held over the picker.
function GetCursorInfo() if stub.cursorInfo then return unpack(stub.cursorInfo) end end
local clear = ClearCursor
function ClearCursor()
	stub.cursorInfo = nil
	if clear then clear() end
end

-- Two items: Hearthstone has a use, Thunderfury is worn.
C_Item = C_Item or {}
local itemInfo = C_Item.GetItemInfo
local ITEMS = { [6948] = { "Hearthstone", 134414, true }, [19019] = { "Thunderfury, Blessed Blade of the Windseeker", 132403 } }
function C_Item.GetItemInfo(item)
	local id = tonumber(item) or tonumber(tostring(item):match("item:(%d+)"))
	local it = ITEMS[id]
	if not it then return itemInfo and itemInfo(item) end
	return it[1], nil, 1, nil, nil, nil, nil, nil, nil, it[2]
end
function C_Item.GetItemSpell(item)
	local id = tonumber(item) or tonumber(tostring(item):match("item:(%d+)"))
	return ITEMS[id] and ITEMS[id][3] and "Hearthstone" or nil
end

-- The game's link insert: with no chat line open it puts the link nowhere.
ChatFrameUtil = ChatFrameUtil or {}
function ChatFrameUtil.GetActiveWindow() return stub.chatWindow end
function ChatFrameUtil.InsertLink(link)
	if stub.chatWindow then stub.chatText = link return true end
	return false
end

-- An edit box's cursor and letters, as the client keeps them.
local B = stub.Methods
function B.GetCursorPosition(self) return self.cursorAt or #(self.text or "") end
function B.GetNumLetters(self) return #(self.text or "") end
