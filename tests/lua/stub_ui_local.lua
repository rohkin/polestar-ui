-- Polestar: UI's addition to Polestar's stub_ui.lua, loaded right after it: the
-- preview loads only Polestar's Core and Theme, so Polestar.UI (its windows) is
-- not there when install() reads Polestar.UI.WhatsNew.
local install = uistub.install
function uistub.install(...)
	local had = Polestar.UI
	Polestar.UI = had or {}
	local r = install(...)
	Polestar.UI = had
	return r
end
