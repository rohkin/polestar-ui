--@ title: Spellbook: a flyout opened
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- As the stock book with "Use flyouts" (spellBookHideFlyouts off): a flyout is one entry, its loose spells left out; a click lists its spells after it, indented, and hides them again. With the setting off, its loose spells instead; a search looks at the loose spells.
PolestarUI.Show("spellbook", "line3")
local f = PolestarUISpellbook
local function rows()
	local n = {}
	for _, c in ipairs({ f.Body:GetChildren() }) do if c.psSpell and c:IsShown() then n[c.psSpell.info.name] = c end end
	return n
end
local r = rows()
assert(r.Portals and not r["Portal: Stormwind"] and r.Portals.Sub:GetText() == "2 spells", "flyout not one entry")
stub.RunScript(r.Portals, "OnEnter")
assert(GameTooltip.lines[#GameTooltip.lines]:find("Click to show its spells"), "no flyout hint")
stub.RunScript(r.Portals, "OnClick", "LeftButton")
r = rows()
assert(r["Portal: Stormwind"] and r["Portal: Ironforge"], "flyout did not open")
assert(select(4, r["Portal: Stormwind"]:GetPoint(1)) == select(4, r.Portals:GetPoint(1)) + 24, "flyout spell not indented")
stub.RunScript(r.Portals, "OnClick", "LeftButton")
assert(not rows()["Portal: Stormwind"], "flyout did not close")
stub.cvars.spellBookHideFlyouts = "1"
PolestarUI.Show("spellbook", "line3")
r = rows()
assert(not r.Portals and r["Portal: Stormwind"] and f.psFilter.psActive, "flyouts off: " .. tostring(r.Portals))
stub.cvars.spellBookHideFlyouts = "0"
f.Search:SetText("portal")
stub.RunScript(f.Search, "OnTextChanged")
r = rows()
assert(not r.Portals and r["Portal: Ironforge"], "search")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
PolestarUI.Show("spellbook", "line3")
stub.RunScript(rows().Portals, "OnClick", "LeftButton")
assert(f.Subtitle:GetText() == "7 spells.", "count: " .. f.Subtitle:GetText())
