--@ title: Cast bars: player, target (cannot be interrupted), focus (interrupted)
--@ roots: PlayerCastingBarFrame, PolestarUITargetFrame, TargetFrameSpellBar, PolestarUIFocusFrame, FocusFrameSpellBar
--@ stubs: stub_castbars.lua
-- The game's own cast bars restyled in place: the game's art, name, time and icon faded where they are, and a frame of ours under each bar, 20 high from the bar's top: a track, a flat fill whose edge hangs on the game's fill (so it follows the cast with nothing read), a hairline, the spell's icon at its left, its name inside on the left and the time left inside on the right (the player's too, with Edit Mode's Show Cast Time off). The player casts (accent); the target's cast cannot be interrupted, which the client hands over secret (textMuted); the focus's channel is interrupted (danger, "Interrupted").
local T = Polestar.Theme
-- Ours under a stock bar: the frame, its fill (hung on the game's fill), its icon, time and name.
local function ours(bar)
	local box = bar:GetChildren()
	local o = { box = box, texts = {} }
	for _, r in ipairs({ box:GetRegions() }) do
		if r.kind == "FontString" then
			o.texts[#o.texts + 1] = r
		elseif r.points[1] and r.points[1].rel == bar:GetStatusBarTexture() then
			o.fill = r
		elseif r.texCoord then
			o.icon = r
		end
	end
	o.time, o.name = o.texts[1], o.texts[2]
	return o
end
local function is(tex, r, g, b) local x, y, z = tex:GetVertexColor() return x == r and y == g and z == b end
stub.units.target = { name = "Kurzen", level = 25, health = 12400, max = 20000, power = 900, powerMax = 1200, reaction = 2 }
stub.units.focus = { name = "Paxton", level = 26, class = "PRIEST", player = true, health = 2000, max = 2000, power = 3000, powerMax = 4000, reaction = 5 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.cast("player", { name = "Fireball", time = 2.5, elapsed = 1.5 })
stub.cast("target", { name = "Shadow Bolt", time = 3, elapsed = 1.8, locked = true })
stub.cast("focus", { name = "Mind Flay", time = 3, elapsed = 2, channel = true })
stub.advance(0.1)
local P, TB, FB = PlayerCastingBarFrame, TargetFrameSpellBar, FocusFrameSpellBar
local p, t, f = ours(P), ours(TB), ours(FB)
local ar, ag, ab = T.Color("sky")
-- Ours: 20 high from the bar's top, as wide as the bar; the stock bar itself untouched.
assert(p.box:GetHeight() == 20 and p.box:GetPoint(1) == "TOPLEFT" and select(2, p.box:GetPoint(1)) == P, "our frame is not hung on the bar's top")
assert(P:IsShown() and P:GetWidth() == 208 and P:GetHeight() == 11 and P:GetAlpha() == 1, "the bar itself was touched")
assert(p.fill:IsShown() and is(p.fill, ar, ag, ab) and p.fill:GetHeight() == 20 and p.fill.points[2].rel == P:GetStatusBarTexture(), "the player's fill is not ours in the header band blue (sky) at our height")
for _, k in ipairs({ "Border", "Background", "TextBorder", "Spark", "Text", "Icon" }) do
	assert(P[k]:GetAlpha() == 0, "the game's " .. k .. " is not faded")
end
assert(P.Spark:IsShown() and P.Text:GetText() == "Fireball", "the game's regions were hidden or written")
-- The name inside on the left, the icon at the bar's height, the time left on the right.
assert(p.name:GetText() == "Fireball" and p.name:GetFont() == (T.FontSpec("label")), "the player's name: " .. tostring(p.name:GetText()))
assert(p.icon:IsShown() and p.icon:GetHeight() == 20 and p.icon:GetTexture() == 136116, "the player's icon")
assert(p.time:GetText() == "1.0", "the player's time (shown whatever Edit Mode's Show Cast Time says): " .. tostring(p.time:GetText()))
-- The target's cast cannot be interrupted: secret, so the texture picks the colour; its name and icon are secret too, handed over unread.
local mr, mg, mb = T.Color("textMuted")
assert(is(t.fill, mr, mg, mb), "a cast that cannot be interrupted is not in textMuted")
assert(TB.BorderShield:IsShown() and TB.BorderShield:GetAlpha() == 0, "the game's shield shows")
assert(t.name:GetText() == "Shadow Bolt" and t.time:GetText() == "1.2" and t.icon:GetTexture() == 136116, "the target's name, time and icon: " .. tostring(t.time:GetText()))
-- Another spell failing mid-cast (a key pressed) leaves the cast as it is.
stub.failCast("player", true)
stub.advance(0.1)
assert(P.casting and is(p.fill, ar, ag, ab) and p.name:GetText() == "Fireball", "another spell's failure ended the cast in danger")
-- An interrupt: danger, the game's word for it, no time; the spark (set to 1 by the game's animation) faded again.
assert(is(f.fill, ar, ag, ab) and f.time:GetText() == "2.0", "a channel is not in the header band blue (sky) with its time left")
stub.interruptCast("focus")
stub.advance(0.1)
local dr, dg, db = T.Color("danger")
assert(is(f.fill, dr, dg, db) and f.name:GetText() == "Interrupted" and f.time:GetText() == "", "an interrupted cast is not in danger")
assert(FB.Spark:GetAlpha() == 0, "the spark shows after an interrupt")
-- In combat the target's and focus's bars answer their size with secrets (seen in the client): nothing of a stock bar's geometry is read, so a cast paints without an error.
stub.inCombat = true
assert(issecretvalue(TB:GetHeight()) and issecretvalue(TB:GetWidth()), "the stub's bar is not secret in combat")
stub.cast("target", { name = "Shadow Bolt", time = 3, elapsed = 0.6, locked = true })
stub.advance(0.2)
assert(#stub.errors == 0 and t.name:GetText() == "Shadow Bolt" and t.time:GetText() == "2.4" and t.fill:GetHeight() == 20, "a cast in combat: " .. tostring(stub.errors[1]))
stub.inCombat = false
local function polls(file)
	local n = 0
	for _, f in ipairs(stub.frames) do
		local fn = f:GetScript("OnUpdate")
		if fn and f:IsVisible() and debug.getinfo(fn, "S").source:find(file, 1, true) then n = n + 1 end
	end
	return n
end
-- No driver polls: only the box of a shown bar paints each frame (it runs only while its bar shows).
local shown = 0
for _, b in ipairs({ PlayerCastingBarFrame, TargetFrameSpellBar, FocusFrameSpellBar }) do if b:IsVisible() then shown = shown + 1 end end
assert(polls("CastBars.lua") == shown, "cast bar OnUpdates: " .. polls("CastBars.lua") .. " for " .. shown .. " shown bars")
