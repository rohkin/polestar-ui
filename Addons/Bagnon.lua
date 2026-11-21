-- Bagnon (docs/addons.md): its own bag and bank windows take the bag and
-- bank keys, so our Bags and Bank stay off beside it (ns.Enabled, blockedBy):
-- two bag windows would fight over the same keys. A no-op without it.

local ADDON, ns = ...

ns.AfterLogin(function()
	if not C_AddOns.IsAddOnLoaded("Bagnon") then return end
	for _, k in ipairs({ "bags", "bank" }) do
		if ns.modules[k] then ns.modules[k].blockedBy = "Bagnon" end
	end
end)
