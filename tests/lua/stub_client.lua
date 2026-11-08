-- Client rules the generic stub (wow_stub.lua) lets slide, each one a bug
-- that reached the game: loaded for every Polestar: UI preview scene.

local M = stub.Methods

-- A FontString with no font (none set, no font object, no template) cannot
-- take text: the client errors "Font not set".
local create, setText = M.CreateFontString, M.SetText
function M.CreateFontString(self, name, layer, inherits)
	local fs = create(self, name, layer, inherits)
	fs.psInherits = inherits
	return fs
end
function M.SetText(self, t)
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
