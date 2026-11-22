--@ title: Damage meter: six sources, the player's row pinned
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- The game's own damage meter restyled in place: the header art faded, the window ground emptied and our HUD ground in its place (the meter's Background Transparency times the HUD's Background opacity), a hairline under the header strip, the texts in Polestar's faces (the type label as a title, the timer dim), the session letter on an accent pill (a Polestar chip); on each row a track and a flat fill in the accent (mixed 0.55 into the ground colour) whose edge hangs on the game's fill, the row's own background art faded, a hairline round the spec icon. Below the visible rows the game pins the player's row; it is dressed the same (no mark of its own, as stock).
local T = Polestar.Theme
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Water Elemental", amount = 254000 },
	{ name = "Alleria", class = "HUNTER", amount = 201000 },
	{ name = "Thrall", class = "SHAMAN", amount = 150000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local c = w.MinimizeContainer
-- The window: nothing moved; the header faded; the ground emptied, its alpha still the game's.
assert(w:GetPoint(1) == "TOPLEFT" and select(2, w:GetPoint(1)) == DamageMeter, "window 1 is no longer on the system")
assert(w.Header:GetAlpha() == 0, "the header art shows")
assert(c.Background:GetTexture() == nil and c.Background:GetAtlas() == nil and c.Background:GetAlpha() == 0.6, "the game's ground is not emptied, or its alpha was touched")
-- Ours: the ground on the container at 0.6 x the HUD's Background opacity.
local ground
for _, r in ipairs({ c:GetRegions() }) do
	if r ~= c.Background and r.layer == "BACKGROUND" and r.sublayer == -8 and r.points[1] and r.points[1].rel == c and #r.points == 2 then ground = r break end
end
local _, _, _, ga = ground:GetVertexColor()
assert(ground and ground:IsShown() and math.abs(ga - 0.6 * Polestar.Theme.GroundAlpha()) < 1e-6, "our ground's alpha: " .. tostring(ga))
-- A row: our fill (hung on the game's fill) in the accent mixed 0.55 into the ground colour, the row's art faded, the texts in Polestar's faces.
local e = c.ScrollBox.ScrollTarget:GetChildren()
local sb = e.StatusBar
local fill
for _, r in ipairs({ sb:GetRegions() }) do if r.points[1] and r.points[1].rel == sb:GetStatusBarTexture() then fill = r end end
local x, y, z, fa = fill:GetVertexColor()
local ar, ag, ab = T.Accent()
local br, bg, bb = T.Color("bg")
local function near(u, v) return math.abs(u - v) < 1e-6 end
assert(fill:IsShown() and near(x, ar * 0.55 + br * 0.45) and near(y, ag * 0.55 + bg * 0.45) and near(z, ab * 0.55 + bb * 0.45) and fa == 1, "the row's fill is not ours in the accent")
assert(sb.Background:GetAlpha() == 0 and sb.BackgroundEdge:GetAlpha() == 0, "the row's art shows")
assert(sb.Name:GetFont() == (T.FontSpec("label")) and sb.Value:GetFont() == (T.FontSpec("number")), "the row's texts are not in Polestar's faces")
-- The player's row, pinned below the visible ones, dressed alike.
assert(c.LocalPlayerEntry:IsShown() and c.LocalPlayerEntry.StatusBar.Background:GetAlpha() == 0, "the pinned player's row is not dressed")
-- The game sets the art again (a style update on acquire): faded again next frame.
stub.damage({ { name = "Garrosh", class = "WARRIOR", amount = 500000 }, { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
assert(sb.Background:GetAlpha() == 1, "the stub did not set the art again")
stub.advance(0.1)
assert(sb.Background:GetAlpha() == 0 and sb.Background:GetAtlas() ~= nil, "the art is not faded again")
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Water Elemental", amount = 254000 },
	{ name = "Alleria", class = "HUNTER", amount = 201000 },
	{ name = "Thrall", class = "SHAMAN", amount = 150000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
-- The header's buttons: the game's art faded (it swaps atlases, never alphas), our glyphs in the icon token, the session button a flat plate.
local min, set, ses, kind = w.MinimizeButton, w.SettingsDropdown, w.SessionDropdown, w.DamageMeterTypeDropdown
assert(min:GetNormalTexture():GetAlpha() == 0 and min:GetPushedTexture():GetAlpha() == 0 and min:GetHighlightTexture():GetAlpha() == 0, "the minimize button's art shows")
assert(set.Icon:GetAlpha() == 0 and ses.Background:GetAlpha() == 0 and ses.Arrow:GetAlpha() == 0 and kind.Arrow:GetAlpha() == 0, "a dropdown's art shows")
local function glyph(b)
	for _, r in ipairs({ b:GetRegions() }) do if r.layer == "ARTWORK" and r.sublayer == 7 then return r end end
end
assert(glyph(min):IsShown() and tostring(glyph(min):GetTexture()):find("chevron%-up"), "the minimize glyph: " .. tostring(glyph(min):GetTexture()))
assert(tostring(glyph(set):GetTexture()):find("gear") and tostring(glyph(kind):GetTexture()):find("chevron%-down"), "the settings or type glyph")
-- The type label a title (heading face, text colour), the session letter ("C") a chip's caption in the accent, the timer dim.
for _, t in ipairs({ { kind.TypeName, "heading", "text" }, { ses.SessionName, "caption", "accent" }, { w.SessionTimer, "number", "textDim" } }) do
	local r, g, b = t[1]:GetTextColor()
	local tr, tg, tb = T.Color(t[3])
	assert(t[1]:GetFont() == (T.FontSpec(t[2])) and r == tr and g == tg and b == tb, "a header text is not in our face and colour: " .. t[2])
end
-- The type label one size up (with the game's face, one weight, it reads as a title only by size).
assert(select(2, kind.TypeName:GetFont()) == select(2, GameFontNormalMed1:GetFont()) + 1, "the type label is not one size up")
-- The game setting the letter's colour again: ours again next frame.
ses.SessionName:SetTextColor(1, 1, 1)
stub.advance(0.1)
assert(select(1, ses.SessionName:GetTextColor()) == (T.Color("accent")), "the session letter's colour was not put back")
-- Something setting the letter's font again (a font object): ours again next frame.
ses.SessionName:SetFontObject(GameFontNormalMed1)
stub.advance(0.1)
assert(ses.SessionName:GetFont() == (T.FontSpec("caption")), "the session letter's face was not put back")
-- The session button: every texture of the template (Background, Arrow) faded; ours an accent pill (accent at 0.35) under the letter, the hover wash a pill too.
local aa = 0.35
local pills = 0
for _, r in ipairs({ ses:GetRegions() }) do
	if r.kind ~= "FontString" and r.layer == "ARTWORK" and r:IsShown() then
		local x2, y2, z2, a2 = r:GetVertexColor()
		assert(x2 == ar and y2 == ag and z2 == ab and a2 == aa, "a piece round the session letter is not the accent pill")
		pills = pills + 1
	else
		assert(r.kind == "FontString" or r.layer == "HIGHLIGHT" or r:GetAlpha() == 0 or not r:IsShown(), "the game's box shows round the session letter")
	end
end
assert(pills == 3, "the session pill: " .. pills .. " pieces")
-- The ground's shadow lies outside the container only: its pieces are cut at the edge (under a translucent ground the part inside showed as a darker frame within the frame).
local shadows = 0
for _, r in ipairs({ c:GetRegions() }) do
	if r.kind ~= "FontString" and r:GetTexture() == T.Media("shadow") then
		local p, q = r.points[1], r.points[2]
		local function side(s, sign, axis)
			return p.relPoint:find(s) and q.relPoint:find(s) and p[axis] * sign >= 0 and q[axis] * sign >= 0
		end
		assert(p.rel == c and q.rel == c and (side("TOP", 1, "y") or side("BOTTOM", -1, "y") or side("LEFT", -1, "x") or side("RIGHT", 1, "x")), "a shadow piece reaches inside the window")
		shadows = shadows + 1
	end
end
assert(shadows == 16, "the ground's shadow: " .. shadows .. " pieces")
