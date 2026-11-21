--@ title: Micro menu
--@ roots: MicroMenuContainer
--@ stubs: stub_micromenu.lua
-- The game's micro buttons restyled in place: the stock button background and the bar's frame art faded, our ground and 1px hairline round each, the game's icons kept. The quest log's window shows (the game pushed it): the accent wash and hairline. The collections button pulses (its alert): the stock glow emptied, its alpha lighting our hairline. The talents button has a notification: the stock mark faded under our accent dot. The spellbook button is hovered: our hover wash (read from IsMouseOver: a door's secure button may hold the mouse). The guild button is disabled: the game's half alpha dims ours with it. The game menu's latency strip faded under our dot, in the game's latency colours.
local Theme = Polestar.Theme
stub.microSetPushed(QuestLogMicroButton, true)
stub.microPulse(CollectionsMicroButton, 0.8)
stub.microNotify(TalentMicroButton, true)
stub.microHover(SpellbookMicroButton, true)
stub.microDisable(GuildMicroButton)
stub.advance(0.1)

local function ours(b, layer, sub)
	for _, r in ipairs({ b:GetRegions() }) do
		local l, s = r:GetDrawLayer()
		if r:IsShown() and l == layer and s == sub and tostring(r:GetTexture()):find("white", 1, true) then return r end
	end
end
for _, b in ipairs(stub.microButtons) do
	assert(b.Background:GetAlpha() == 0 and b.PushedBackground:GetAlpha() == 0, b:GetName() .. ": the stock background shows")
	assert(ours(b, "BACKGROUND", -8), b:GetName() .. ": no ground of ours")
	assert(b:GetNormalTexture():GetAtlas() == "UI-HUD-MicroMenu-" .. b.textureName .. "-Up", b:GetName() .. ": the game's icon changed")
end
assert(MicroMenu.BorderArt:GetAlpha() == 0 and MicroMenu.BackgroundArt:GetAlpha() == 0, "the bar's frame art shows")
local ar, ag, ab = Theme.Accent()
local wash = ours(QuestLogMicroButton, "OVERLAY", 6)
assert(wash, "no accent on the pushed button")
assert(not ours(CharacterMicroButton, "OVERLAY", 6), "an accent on a button whose window is closed")
-- The pulse: the stock border emptied, our hairline towards the accent.
assert(CollectionsMicroButton.FlashBorder:GetTexture() == nil and CollectionsMicroButton.FlashBorder.color == nil, "the stock pulse glow shows")
local edge = ours(CollectionsMicroButton, "OVERLAY", 7)
local er, eg, eb = edge:GetVertexColor()
local br, bg, bb = Theme.Color("border")
assert(math.abs(er - (br + (ar - br) * 0.8)) < 1e-6 and math.abs(eb - (bb + (ab - bb) * 0.8)) < 1e-6, "the pulse does not light our hairline")
stub.microPulse(CollectionsMicroButton, nil)
stub.advance(0.05)
er, eg, eb = ours(CollectionsMicroButton, "OVERLAY", 7):GetVertexColor()
assert(er == br and eb == bb, "the hairline stays lit after the pulse")
stub.microPulse(CollectionsMicroButton, 0.8)
stub.advance(0.05)
-- The notification: the stock mark faded, our dot on the game's overlay.
local mark = TalentMicroButton.NotificationOverlay:GetRegions()
assert(mark:GetAlpha() == 0, "the stock notification mark shows")
local dot = select(2, TalentMicroButton.NotificationOverlay:GetRegions())
assert(dot and dot:IsShown() and dot:IsVisible(), "no notification dot")
assert(not select(2, CharacterMicroButton.NotificationOverlay:GetRegions()):IsVisible(), "a dot without a notification")
-- Hover, from IsMouseOver.
assert(ours(SpellbookMicroButton, "OVERLAY", 5) and not ours(CharacterMicroButton, "OVERLAY", 5), "the hover wash")
-- Latency: 120 ms is the game's green; 400 its yellow, 700 its red.
local bar = MainMenuMicroButton.MainMenuBarPerformanceBar
assert(bar:GetAlpha() == 0, "the stock latency strip shows")
local ping = ours(MainMenuMicroButton, "OVERLAY", 7)
for _, r in ipairs({ MainMenuMicroButton:GetRegions() }) do if tostring(r:GetTexture()):find("disc", 1, true) then ping = r end end
local function is(token) local r, g, b = ping:GetVertexColor(); local tr, tg, tb = Theme.Color(token); return r == tr and g == tg and b == tb end
assert(is("success"), "120 ms is not green")
stub.netStats = { 0, 0, 90, 400 }
stub.advance(1.1)
assert(is("warning"), "400 ms is not yellow")
stub.netStats = { 0, 0, 700, 80 }
stub.advance(1.1)
assert(is("danger"), "700 ms is not red")
stub.netStats = { 0, 0, 120, 80 }
stub.advance(1.1)
-- Where a region of ours lies in the menu's space (the stub keeps anchors, not geometry): its button
-- sits by its TOPLEFT on the menu; ours hang on the button's corners (two, or one and a size).
local function rect(r, b)
	local _, _, _, bx, by = b:GetPoint(1)
	local w, h = b:GetWidth(), b:GetHeight()
	local c = { TOPLEFT = { bx, by }, TOPRIGHT = { bx + w, by }, BOTTOMLEFT = { bx, by - h }, BOTTOMRIGHT = { bx + w, by - h } }
	local e = {}
	for i = 1, r:GetNumPoints() do
		local p, _, rp, x, y = r:GetPoint(i)
		local px, py = c[rp][1] + x, c[rp][2] + y
		if p:find("LEFT") then e.l = px else e.r = px end
		if p:find("TOP") then e.t = py else e.b = py end
	end
	e.l, e.r = e.l or e.r - r:GetWidth(), e.r or e.l + r:GetWidth()
	e.t, e.b = e.t or e.b + r:GetHeight(), e.b or e.t - r:GetHeight()
	return e
end
-- Each ground on the stock plate, apart from its neighbours (the layout overlaps the buttons by 5).
for i = 2, #stub.microButtons do
	local p, n = stub.microButtons[i - 1], stub.microButtons[i]
	local a, b = rect(ours(p, "BACKGROUND", -8), p), rect(ours(n, "BACKGROUND", -8), n)
	assert(b.l - a.r >= 2, n:GetName() .. ": its ground runs into its neighbour's")
end
-- Every dot the same size, as far inside its plate's top right corner.
local function corner(d, b)
	local g, e = rect(ours(b, "BACKGROUND", -8), b), rect(d, b)
	return g.r - e.r, g.t - e.t, e.r - e.l, e
end
local dx, dy, dw = corner(dot, TalentMicroButton)
assert(dx == 2 and dy == 2, "the notification dot is not at the top right")
local px, py, pw = corner(ping, MainMenuMicroButton)
assert(px == dx and py == dy and pw == dw, "the latency dot is not placed as the notification dot")
-- Both on one button: the latency dot steps left of the alert dot.
stub.microNotify(MainMenuMicroButton, true)
stub.advance(0.05)
local alert = select(2, MainMenuMicroButton.NotificationOverlay:GetRegions())
local ax, _, _, ae = corner(alert, MainMenuMicroButton)
local _, _, _, pe = corner(ping, MainMenuMicroButton)
assert(ax == 2 and pe.r <= ae.l - 2, "the latency dot sits under the alert dot")
stub.microNotify(MainMenuMicroButton, false)
stub.advance(0.05)
assert(corner(ping, MainMenuMicroButton) == 2, "the latency dot does not come back to the corner")
