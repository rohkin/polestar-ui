-- ForeverQuestTint loaded (Addons/ForeverQuestTint.lua): the addon and its saved settings, as the
-- addon leaves them (only what the player changed).
stub.addonsLoaded.ForeverQuestTint = true
ForeverQuestTintDB = { objectiveTint = true }
-- A texture's coordinates as the client gives them: eight values, its corners UL, LL, UR, LR.
stub.Methods.GetTexCoord = stub.Methods.GetTexCoord or function(self)
	local c = self.texCoord or { 0, 1, 0, 1 }
	if #c == 8 then return unpack(c) end
	return c[1], c[3], c[1], c[4], c[2], c[3], c[2], c[4]
end
