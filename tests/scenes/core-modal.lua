--@ title: Core: dialogs with a stepper and a money input
--@ roots: PolestarModal
-- ns.ModalWith puts a body of ours under Polestar's dialog text. ns.Stepper: - and + step within 1 and the most, Max takes the most, a typed count is kept within them, each button fades when it cannot act; the dialog's action reads the count; the body hides with the dialog, and when the next dialog takes its place.
local ns, W = PolestarUI, Polestar.Widgets
local n, bought = 1, nil
local s = ns.Stepper(UIParent, { get = function() return n end, set = function(v) n = v end, max = function() return 20 end })
local spec = { title = "Buy how many?", text = "Linen Cloth, 10 copper each.", action = "Buy", onAccept = function() bought = n end }
ns.ModalWith(spec, s)
s.Paint()
assert(s:IsShown() and s:GetParent() == PolestarModal.Box, "no body in the dialog")
assert(not s.Less:IsEnabled() and s.More:IsEnabled() and s.Max:IsEnabled(), "buttons at 1")
s.More:Click()
s.More:Click()
assert(n == 3 and tostring(s.Box:GetText()) == "3", "+ did not step")
s.Max:Click()
assert(n == 20 and not s.More:IsEnabled() and not s.Max:IsEnabled() and s.Less:IsEnabled(), "Max")
s.Box:SetText("99")
stub.RunScript(s.Box, "OnEditFocusLost")
assert(n == 20, "a typed count past the most kept")
s.Box:SetText("0")
stub.RunScript(s.Box, "OnEditFocusLost")
assert(n == 1, "a typed count under 1 kept")
s.More:Click()
PolestarModal.Box.Action:Click()
assert(bought == 2 and not PolestarModal:IsShown() and not s:IsShown(), "the action did not read the count, or the body stayed")
ns.ModalWith(spec, s)
W.Modal({ title = "Another dialog" })
assert(not s:IsShown(), "the body stayed under the next dialog")
n = 3
ns.ModalWith(spec, s)
s.Paint()
--@ panel
--@ roots: PolestarModal
-- ns.MoneyInput: gold, silver and copper fields, filled by Set and read back as copper as the player types.
local ns = PolestarUI
local got
local m = ns.MoneyInput(UIParent, function(c) got = c end)
ns.ModalWith({ title = "Deposit money", text = "Into your Warband bank.", action = "Deposit" }, m)
m.Set(1234567)
local g, sv, c = m:GetChildren()
assert(tostring(g:GetText()) == "123" and tostring(sv:GetText()) == "45" and tostring(c:GetText()) == "67", "Set")
sv:SetText("5")
stub.RunScript(sv, "OnTextChanged", true)
assert(got == 1230567, "typed money not read as copper")
