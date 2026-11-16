--@ title: Spellbook: Training (What's Training?)
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua, stub_whatstraining.lua
-- With What's Training? loaded, a Training tab lists its spells (WT_API) in its groups; known and ignored ones are left out.
PolestarUI.Show("spellbook", "training")
local f = PolestarUISpellbook
local function shown()
	local n, names = 0, {}
	for _, c in ipairs({ f.Body:GetChildren() }) do
		if c.psTrain and c:IsShown() then n = n + 1; names[c.psTrain.name] = true end
	end
	return n, names
end
local n, names = shown()
assert(f.Title:GetText() == "Training", "not the Training page: " .. tostring(f.Title:GetText()))
assert(f.Subtitle:GetText() == "Level 24 Mage · 3 spells to train now.", "subtitle: " .. f.Subtitle:GetText())
assert(n == 8 and not names["Frost Armor"], "rows: " .. n)
-- Its SpellsChanged callback redraws the open page.
stub.wtSpells[1][6] = "known"
stub.wtFire("SpellsChanged", { 8413 })
assert(f.Subtitle:GetText() == "Level 24 Mage · 2 spells to train now.", "no redraw: " .. f.Subtitle:GetText())
stub.wtSpells[1][6] = "available"
stub.wtFire("SpellsChanged", { 8413 })
-- The book's tabs still work, and its rows are not left behind.
PolestarUI.Show("spellbook", "line3")
assert(select(1, shown()) == 0, "training rows left on the book page")
PolestarUI.Show("spellbook", "training")
-- The tab row holds only the filter at its end (the search is in its dropdown): the tabs clear it.
-- (the row is the body's width plus its pads; the filter is 30 wide inside the right pad)
assert(not f.Search:IsShown() and f.psTabsRight + 6 <= f.BodyWidth + f.psPad - f.psFilter:GetWidth(), "tabs run under the filter: " .. f.psTabsRight .. " of " .. f.BodyWidth)
