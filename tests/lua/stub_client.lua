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
