--@ title: Trainer: filtered
--@ roots: PolestarUITrainer, PolestarMenu
--@ stubs: stub_npc.lua, stub_trainer.lua
-- A category in the sidebar shows only its services. The stock filter on the sliders button: Used and Unavailable off leave what can be learnt (the client's list, redrawn at once); the menu opens again after each pick; the button is lit while a filter hides some.
stub.interact(Enum.PlayerInteractionType.Trainer)
local f = PolestarUITrainer
local function shown() local n = 0; for _, r in ipairs(f.psRows) do if r:IsShown() then n = n + 1 end end; return n end
f.navButtons[3]:Click()
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
