--@ title: Inspect: Guild
--@ roots: PolestarUIInspect
--@ stubs: stub_inspect.lua
-- The Guild tab (only for a unit in a guild, as the stock UpdateTabs): the tabard's emblem, the guild's name, faction and members. A unit out of range draws its faction's logo in place of the model; inspecting a unit with no guild drops the tab and goes back to Character.
InspectUnit("target")
stub.inspectReady("target")
local f = PolestarUIInspect
stub.RunScript(f.tabButtons[3], "OnClick")
local v = f.psPages.guild
assert(v:IsShown() and v.Name:GetText() == "Silver Hand", "guild page")
assert(v.Faction:GetText() == "Alliance Guild" and v.Members:GetText() == "42 Members", "faction or members")
local faction = UnitFactionGroup -- a secret faction (CLIENT.md, rule 3) leaves the line out
UnitFactionGroup = function() return stub.SECRET, stub.SECRET end
stub.RunScript(f.tabButtons[3], "OnClick")
assert(v.Faction:GetText() == "", "secret faction shown")
UnitFactionGroup = faction
stub.RunScript(f.tabButtons[3], "OnClick")
assert(v.Emblem:GetTexture() == "Interface/GuildFrame/GuildEmblemsLG_01", "emblem")
-- No guild: no Guild tab, back on Character.
stub.inspectGuild = { 0, 0, "", "" }
stub.noModel = true
InspectUnit("party1")
stub.inspectReady("party1")
assert(f.psPages.gear:IsShown() and not f.tabButtons[3]:IsShown(), "guild tab kept for a unit without a guild")
assert(f.psPages.gear.Logo:IsShown() and not f.psPages.gear.Model:IsShown(), "no faction logo for a model out of range")
stub.inspectGuild = { 0, 42, "Silver Hand", "" }
stub.noModel = nil
InspectUnit("target")
stub.inspectReady("target")
stub.RunScript(f.tabButtons[3], "OnClick")
