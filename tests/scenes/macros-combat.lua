--@ title: Macros: in combat
--@ roots: PolestarUIMacros
--@ stubs: stub_macros.lua
-- The client refuses CreateMacro, EditMacro and DeleteMacro in combat: New,
-- Delete, Change name/icon, Save and Cancel grey with the reason, and the
-- body locks. A change typed before the fight is kept and saved after it.
ShowMacroFrame()
local f = PolestarUIMacros
local e = f.psEdit
e:SetFocus()
e:SetText("/cast Heroic Strike")
stub.RunScript(e, "OnTextChanged", true)
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
local why = "Macros cannot change in combat."
local del, new = f.footerButtons.left[1], f.footerButtons.right[1]
for _, b in ipairs({ del, new, f.psChange, f.psSave, f.psCancel }) do
	assert(not b:IsEnabled() and b.psReason == why, "on in combat, or not saying why: " .. tostring(b.psReason))
end
assert(not e:IsEnabled() and not e:HasFocus(), "the body takes keys in combat")
assert(e:GetText() == "/cast Heroic Strike", "the typed body lost")
-- No pickup in combat: no action bar takes it then.
f.psIcon:Click()
assert(not stub.pickedMacro, "picked up in combat")
-- Picking another macro reads it; the typed one waits for the fight's end.
local cells = {}
for _, c in ipairs({ f.psGrid.Child:GetChildren() }) do if c.psIndex and c:IsShown() then cells[c.psIndex] = c end end
cells[2]:Click()
assert(not stub.blocked, "a macro call refused in combat: " .. tostring(stub.blocked))
assert(stub.macros.general[1][3] == "/assist [@focus]", "saved in combat")
cells[1]:Click()
assert(e:GetText() == "/cast Heroic Strike", "the waiting body not shown")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
assert(stub.macros.general[1][3] == "/cast Heroic Strike", "not saved after the fight")
assert(e:IsEnabled() and new:IsEnabled() and not f.psSave:IsEnabled(), "still locked after the fight")
-- The picture: in combat again.
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
