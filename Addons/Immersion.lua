-- Immersion shows gossip and quest dialogs itself: ours start off beside it (a saved choice wins).
local ADDON, ns = ...

ns.AfterLogin(function()
	if not C_AddOns.IsAddOnLoaded("Immersion") then return end
	for _, key in ipairs({ "gossip", "questdialog" }) do
		if ns.modules[key] then ns.modules[key].defaultOff = true end
	end
end)
