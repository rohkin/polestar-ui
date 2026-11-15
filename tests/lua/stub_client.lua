-- Client rules the generic stub (wow_stub.lua) lets slide, each one a bug
-- that reached the game: loaded for every Polestar: UI preview scene.

local M = stub.Methods

-- The call stack as text, as the client's debugstack gives it.
function debugstack() return debug.traceback("", 2) end

-- Secret values: in combat the player's name reaches addon code secret, and
-- neither a tooltip nor our strings (Polestar's font hook reads them) take one.
-- A string on a game font object has no hook: it holds the secret as is.
-- (stub_character.lua's UnitPVPName answers stub.SECRET the same way.)
local SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
stub.SECRET = SECRET
function issecretvalue(v) return v == SECRET end
local unitName = UnitName
function UnitName(unit, ...)
	if unit == "player" and InCombatLockdown() then return SECRET end
	return unitName(unit, ...)
end
local tipText = GameTooltip.SetText
function GameTooltip.SetText(self, t, ...)
	if t == SECRET then error("bad argument #2 to 'SetText' (a secret value)", 2) end
	return tipText(self, t, ...)
end

-- A FontString with no font (none set, no font object, no template) cannot
-- take text: the client errors "Font not set".
local create, setText = M.CreateFontString, M.SetText
function M.CreateFontString(self, name, layer, inherits)
	local fs = create(self, name, layer, inherits)
	fs.psInherits = inherits
	return fs
end
function M.SetText(self, t)
	if t == SECRET then
		if self.kind == "FontString" and self.fontObject then self.text = SECRET return end
		error("bad argument #2 to 'SetText' (a secret value)", 2)
	end
	if self.kind == "FontString" and not (self.font or self.fontObject or self.psInherits) then
		error("FontString:SetText(): Font not set", 2)
	end
	return setText(self, t)
end

-- With no font, GetFont answers nil (the stub's default would make code that
-- skips SetFont when "already set" leave the string fontless).
local getFont = M.GetFont
function M.GetFont(self)
	if self.kind == "FontString" and not (self.font or self.fontObject or self.psInherits) then return nil end
	return getFont(self)
end

-- Key bindings: the keys bound to each action, and the override bindings set
-- over them (refused in combat). stub.pressKey(key) runs what the key does:
-- the override's button, else the game's own binding (stub.bindingRun[action]).
stub.bindings = { TOGGLETALENTS = { "N" }, TOGGLESPELLBOOK = { "P" }, TOGGLEPETBOOK = { "SHIFT-P" }, TOGGLEPROFESSIONBOOK = { "K" } }
stub.overrides, stub.bindingRun = {}, {}
function GetBindingKey(action) return unpack(stub.bindings[action] or {}) end
function SetOverrideBindingClick(owner, priority, key, button)
	if InCombatLockdown() then error("SetOverrideBindingClick is protected in combat", 2) end
	stub.overrides[key] = button
end
function ClearOverrideBindings(owner)
	if InCombatLockdown() then error("ClearOverrideBindings is protected in combat", 2) end
	stub.overrides = {}
end
function stub.pressKey(key)
	if stub.overrides[key] then return _G[stub.overrides[key]]:Click() end
	for action, keys in pairs(stub.bindings) do
		for _, k in ipairs(keys) do if k == key and stub.bindingRun[action] then stub.bindingRun[action]() end end
	end
end

-- EditBox:SetText runs OnTextChanged (userInput false), as the client does.
local setTextChanged = M.SetText
function M.SetText(self, t)
	local was = self.text
	setTextChanged(self, t)
	if self.kind == "EditBox" and self.text ~= was then stub.RunScript(self, "OnTextChanged", false) end
end

-- Frame:SetRolesets (the UI modes' visibility tags, C_Roleset) is protected:
-- a protected frame (stub_unitframes.lua's psProtected) refuses it in combat.
-- GetRolesetNames answers the tags, "roleless" while none are set.
function M.SetRolesets(self, s)
	if self.psProtected and InCombatLockdown() then
		error("SetRolesets on protected " .. tostring(self.name) .. " in combat (ADDON_ACTION_BLOCKED, rule 4)", 2)
	end
	self.rolesets = s
end
function M.GetRolesetNames(self)
	local t = {}
	for r in tostring(self.rolesets or "roleless"):gmatch("[^,%s]+") do t[#t + 1] = r end
	return t
end

-- Font families: each alphabet's own face, picked by the engine per glyph.
-- stub.fontFamilies[name] = the family (fam.members as given); a name used
-- twice errors. The game fonts answer the client's faces per alphabet.
stub.fontFamilies = {}
local ALPHABET_FACES = { roman = STANDARD_TEXT_FONT, russian = "Fonts\\FRIZQT___CYR.TTF", korean = "Fonts\\2002.TTF",
	simplifiedchinese = "Fonts\\ARKai_T.ttf", traditionalchinese = "Fonts\\bLEI00D.ttf" }
function M.GetFontObjectForAlphabet(self, alphabet)
	local _, size, flags = self:GetFont()
	local o = CreateFont(nil)
	o:SetFont(ALPHABET_FACES[alphabet] or STANDARD_TEXT_FONT, size, flags)
	return o
end
function CreateFontFamily(name, members)
	if stub.fontFamilies[name] then error("CreateFontFamily: font family '" .. name .. "' already exists", 2) end
	local fam = CreateFont(name)
	fam.members = members
	for _, m in ipairs(members) do if m.alphabet == "roman" then fam:SetFont(m.file, m.height, m.flags) end end
	stub.fontFamilies[name] = fam
	return fam
end
