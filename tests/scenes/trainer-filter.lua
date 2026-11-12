--@ title: Trainer: filtered
--@ roots: PolestarUITrainer, PolestarMenu
--@ stubs: stub_npc.lua, stub_trainer.lua
-- The categories by name, as the stock list sorts them; one in the sidebar shows only its services. The stock filter on the sliders button: Used and Unavailable off leave what can be learnt (the client's list, redrawn at once); the menu opens again after each pick; the button is lit while a filter hides some. Categorize (the stock menu's) off lists no categories.
stub.interact(Enum.PlayerInteractionType.Trainer)
local f = PolestarUITrainer
local function shown() local n = 0; for _, r in ipairs(f.psRows) do if r:IsShown() then n = n + 1 end end; return n end
f.navButtons[4]:Click()
assert(f.Title:GetText() == "Protection" and shown() == 3, "category not shown")
f.navButtons[1]:Click()
assert(shown() == 8, "All not back")

stub.RunScript(f.psFilter, "OnClick")
local function item(t) for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == t then return r end end end
item("Used"):Click()
assert(PolestarMenu:IsShown(), "menu closed")
item("Unavailable"):Click()
assert(not stub.typeFilter.used and not stub.typeFilter.unavailable and stub.typeFilter.available, "filter not set")
assert(shown() == 4, "filtered rows: " .. shown())
assert(item("Available").Check:IsShown() and not item("Used").Check:IsShown(), "checks wrong")

-- Categorize off: no categories in the sidebar, the rows all under All.
item("Categorize"):Click()
assert(not stub.categorize and not f.navButtons[2]:IsShown() and shown() == 4, "categories still shown")
item("Categorize"):Click()
assert(stub.categorize and f.navButtons[2]:IsShown(), "categories not back")

-- The sliders button counts the types it hides in its tooltip; Clear filters shows them all again.
assert(f.psFilter.psTip == "Filter (2 on)", "filter tip: " .. tostring(f.psFilter.psTip))
item("Clear filters"):Click()
assert(stub.typeFilter.used and stub.typeFilter.unavailable and shown() == 8 and f.psFilter.psTip == "Filter", "Clear filters did not show all")
-- The sidebar search keeps to the services whose name has it.
f.Search:SetText("shield"); stub.RunScript(f.Search, "OnTextChanged")
assert(shown() == 2, "search rows: " .. shown())
f.Search:SetText(""); stub.RunScript(f.Search, "OnTextChanged")
assert(shown() == 8, "search not cleared")
