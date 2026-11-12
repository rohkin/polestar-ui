--@ title: Social: Ignored
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- The stock ignore list in full: ignored players, then blocked Battle.net invites, each under
-- its heading; the ✕ stops ignoring or unblocks at once. "Ignore player" (the stock Block
-- button) ignores a friendly target at once, else asks for a name.
PolestarUI.Show("social", "ignored")
local f = PolestarUISocial
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(row("Ignored players (2)") and row("Spamalot") and row("Blocked Battle.net invites (1)") and row("Hexley"), "both lists")
local spam = row("Spamalot")
assert(spam.Remove:IsShown() and spam.Remove.psTip == "Stop ignoring" and row("Hexley").Remove.psTip == "Unblock invites", "row buttons")
assert(spam.Name:GetPoint(1) == "LEFT" and not spam.Sub:IsShown(), "one line, centred")
spam.Remove:Click()
assert(stub.unignored == "Spamalot" and not row("Spamalot") and row("Ignored players (1)"), "unignore")
row("Hexley").Remove:Click()
assert(stub.unblocked == 31 and not row("Hexley") and not row("Blocked Battle.net invites (1)"), "unblock")
-- Ignore player: no target asks for a name; a friendly target is ignored at once.
local b2 = f.footerButtons.right[2]
assert(f.footerButtons.right[1].Label:GetText() == "Ignore player" and not (b2 and b2:IsShown()), "footer")
f.footerButtons.right[1]:Click()
assert(PolestarModal:IsShown(), "no name dialog")
f.psIgnore.Box:SetText("Trollface")
PolestarModal.Box.Action:Click()
assert(stub.ignoredName == "Trollface" and row("Trollface"), "ignore by name")
stub.target = "Grimble"
f.footerButtons.right[1]:Click()
assert(stub.ignoredName == "Grimble" and not PolestarModal:IsShown() and row("Grimble") and row("Ignored players (3)"), "ignore the target")
assert(f.Subtitle:GetText() == "3 ignored", "status: " .. tostring(f.Subtitle:GetText()))
