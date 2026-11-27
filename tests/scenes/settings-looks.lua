--@ title: Settings: the Chat, Damage meter and Unit frames tabs, each with a look of its own
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrame1Tab, ChatFrame2Tab, DamageMeter, PolestarUIPlayerFrame
--@ stubs: stub_chat.lua, stub_damagemeter.lua
-- Chat, the damage meter and the unit frames each have a tab on our page: their options, and "<Element> look", an override of the Frames look for that element alone (band, rim, border, shadow, ground). Off (the default) they follow the Frames look; on, they start from what they wear and change alone, live. Shown: the chat without its band, the meter without its shadow and edged white, the player's frame without its rim at 30% ground.
local ns, T, H = PolestarUI, Polestar.Theme, PolestarUI.HUD
local function near(a, b) return math.abs(a - b) < 1e-6 end
local in_ = {}
Polestar.Widgets.OnOptionsRegistered(function(spec)
	if spec.key ~= "polestarui" then return end
	local t = {}
	in_[spec.tab .. "/" .. spec.section] = t
	for _, c in ipairs(spec.controls) do
		assert(c.key == nil and c.get and c.set, "a control with a PolestarDB key: " .. tostring(c.label))
		assert(c.kind == "toggle" or c.kind == "slider" or c.kind == "dropdown", "a control Polestar 0.4.0 does not know: " .. tostring(c.kind))
		t[c.label] = c
	end
end)
local chat, meter, units = in_["Chat/Chat look"], in_["Damage meter/Damage meter look"], in_["Unit frames/Unit frames look"]
assert(chat and meter and units, "no look section on each element's tab")
assert(in_["Chat/Chat"]["Fade chat when idle"] and in_["Unit frames/Unit frames"]["3D portraits"], "the elements' options are not on their tabs")
assert(in_["HUD/HUD"]["Chat"] and in_["HUD/HUD"]["Damage meter"] and in_["HUD/Frames look"], "the HUD tab lost its toggles or the Frames look")
local ROWS = { "Starlit band", "Accent rim", "Window border", "Border", "Border colour", "Accent border", "Hairlines", "Window shadow", "Shadow strength", "Background opacity" }
for _, s in ipairs({ chat, meter, units }) do
	assert(s["Override Polestar's look"].get() == false, "an element overrides by default")
	for _, k in ipairs(ROWS) do assert(s[k] and s[k].disabled(), k .. ": missing, or not greyed while following") end
	assert(s["Starlit band"].get() == true and s["Background opacity"].get() == math.floor(T.GroundAlpha() * 100 + 0.5), "following does not show Polestar's values")
end
assert(not in_["HUD/Frames look"]["Starlit band"] and not in_["Icons/Icons look"]["Accent rim"], "a group's look has a band or rim row")

stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1830, max = 2400, power = 45, powerMax = 100, powerType = 1, reaction = 5 }
stub.unitWatch()
stub.chatSample()
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.3)
local dock, box, P = GeneralDockManager, DamageMeterSessionWindow1.MinimizeContainer, PolestarUIPlayerFrame
-- Our shown textures on f whose file is `file` (in `layer`).
local function art(f, file, layer)
	local n = 0
	for _, r in ipairs({ f:GetRegions() }) do
		local t = r.GetTexture and tostring(r:GetTexture())
		if t and t:find("Polestar") and t:sub(-#file - 1) == "\\" .. file and r:IsShown() and (not layer or r:GetDrawLayer() == layer) then n = n + 1 end
	end
	return n
end
local function band(f) return art(f, "band") end
local function rim(f) return art(f, "white", "OVERLAY") end
local function shadow(f) return art(f, "shadow") end
local function playerRim() local n = 0 for _, t in ipairs(P.head.rim) do if t:IsVisible() then n = n + 1 end end return n end
local function alpha(t) return select(4, t:GetVertexColor()) end
local function all() return band(dock) == 1 and rim(dock) == 4 and shadow(dock) == 16 and band(box) == 1 and rim(box) == 4 and shadow(box) == 16 and playerRim() == 4 and shadow(P) == 16 and P.Health.Sparkle:IsShown() end
assert(all(), "not Polestar's head and shadow on all three to start with")
local ground = T.GroundAlpha()
assert(near(alpha(P.Ground.fill), ground), "the player's ground is not Polestar's")

-- Chat: the override starts from what the chat wears (nothing changes), then its band goes alone.
chat["Override Polestar's look"].set(true)
stub.advance(0.3)
local o = PolestarUIDB.hudLook.chat
assert(o.override and o.band == true and o.rim == true and o.shadow == true and o.ground == ground and o.borderSize == 1, "the chat's override did not start from Polestar's look")
assert(all() and not chat["Starlit band"].disabled(), "turning the override on changed the chat, or left its rows greyed")
chat["Starlit band"].set(false)
stub.advance(0.3)
assert(band(dock) == 0 and rim(dock) == 4 and shadow(dock) == 16, "the chat's band stays (or its rim or shadow went with it)")
assert(band(box) == 1 and P.Health.Sparkle:IsShown(), "the chat's band took the meter's, or the player's stars")
assert(T.ShowsBand() and H.Band(H.FRAMES) and not PolestarUIDB.hudLook.frames, "the chat's band wrote Polestar's setting or the Frames look")

-- The damage meter: its shadow off and a white border, alone.
meter["Override Polestar's look"].set(true)
meter["Window shadow"].set(false)
meter["Border colour"].set("white")
stub.advance(0.3)
assert(shadow(box) == 0 and band(box) == 1 and rim(box) == 4, "the meter's shadow stays (or its head went with it)")
assert(shadow(dock) == 16 and shadow(P) == 16, "the meter's shadow took the chat's or the player's")
assert(meter["Shadow strength"].disabled() and not chat["Shadow strength"].disabled(), "Shadow strength greyed on the wrong tab")
local _, mr, mg, mb = H.Edge(H.METER)
local _, cr = H.Edge(H.CHAT)
assert(mr == 1 and mg == 1 and mb == 1 and near(cr, (T.Color("windowBorder"))), "the meter's border colour is not its own, or the chat took it")

-- The unit frames: the rim off, the stars off, the ground at 30%, alone.
units["Override Polestar's look"].set(true)
units["Accent rim"].set(false)
units["Background opacity"].set(30)
stub.advance(0.3)
assert(playerRim() == 0 and rim(dock) == 4 and rim(box) == 4, "the player's rim stays, or took the chat's or the meter's")
assert(near(alpha(P.Ground.fill), 0.3) and near(H.GroundAlpha(H.CHAT), ground) and near(H.GroundAlpha(H.FRAMES), ground), "the unit frames' ground is not their own, or the others took it")
units["Starlit band"].set(false)
stub.advance(0.3)
assert(not P.Health.Sparkle:IsShown() and band(box) == 1, "the player's stars stay with the unit frames' band off")
units["Starlit band"].set(nil) -- a row's reset: Polestar's value now
stub.advance(0.3)
assert(P.Health.Sparkle:IsShown() and PolestarUIDB.hudLook.unitframes.band == true, "a row's reset is not Polestar's value")
-- Polestar's own settings still rule what an override leaves alone... and no longer what it holds.
Polestar.Set("ui.rim", false)
stub.advance(0.3)
assert(rim(dock) == 4 and rim(box) == 4 and playerRim() == 0, "an override's rim follows Polestar's")
Polestar.Set("ui.rim", nil)
stub.advance(0.3)

-- Reset (the toggle's): each follows Polestar again, its own values kept for the next time.
for _, s in ipairs({ chat, meter, units }) do s["Override Polestar's look"].set(nil) end
stub.advance(0.3)
assert(all() and near(alpha(P.Ground.fill), ground) and chat["Starlit band"].disabled() and chat["Starlit band"].get() == true, "reset does not follow Polestar again")
assert(PolestarUIDB.hudLook.chat.band == false and not PolestarUIDB.hudLook.chat.override, "the chat's own values were lost while following")

-- ns.ShowSettings(key) lands on the element's own tab (Polestar's UI is absent in the preview: a stand-in).
local opened
local hadUI = Polestar.UI
Polestar.UI = { ShowOptions = function(k) opened = { k } end, Options = { Select = function(k, tab) opened[2], opened[3] = k, tab end } }
for key, tab in pairs({ chat = "Chat", damagemeter = "Damage meter", unitframes = "Unit frames", tooltips = "HUD" }) do
	ns.ShowSettings(key)
	assert(opened[1] == "polestarui" and opened[3] == tab, key .. " opened on " .. tostring(opened[3]))
end
Polestar.UI = hadUI

-- Shown: each override on again, with its own values.
for _, s in ipairs({ chat, meter, units }) do s["Override Polestar's look"].set(true) end
stub.advance(0.3)
assert(band(dock) == 0 and shadow(box) == 0 and playerRim() == 0 and near(alpha(P.Ground.fill), 0.3), "the overrides' own values did not come back")
stub.assertNoErrors()

--@ panel
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrame1Tab, ChatFrame2Tab, DamageMeter, PolestarUIPlayerFrame
--@ stubs: stub_chat.lua, stub_damagemeter.lua
--@ saved: PolestarUIDB = { modules = {}, hudLook = { frames = { override = true, border = true, borderSize = 2, borderColor = "white", hairline = 1, shadow = false, shadowStrength = 1, ground = 0.5 } } }
-- An old save with only the Frames override: chat, the meter and the unit frames wear it as before (white 2 px, no shadow, 50% ground; Polestar's band and rim). An element's own override starts from it, then leaves it.
local ns, T, H = PolestarUI, Polestar.Theme, PolestarUI.HUD
local function near(a, b) return math.abs(a - b) < 1e-6 end
local in_ = {}
Polestar.Widgets.OnOptionsRegistered(function(spec)
	if spec.key == "polestarui" then
		local t = {}
		in_[spec.section] = t
		for _, c in ipairs(spec.controls) do t[c.label] = c end
	end
end)
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1830, max = 2400, power = 45, powerMax = 100, powerType = 1, reaction = 5 }
stub.unitWatch()
stub.chatSample()
stub.damage({ { name = "Garrosh", class = "WARRIOR", amount = 412000 }, { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
stub.advance(0.3)
local dock, box, P = GeneralDockManager, DamageMeterSessionWindow1.MinimizeContainer, PolestarUIPlayerFrame
local function art(f, file)
	local n = 0
	for _, r in ipairs({ f:GetRegions() }) do
		local t = r.GetTexture and tostring(r:GetTexture())
		if t and t:find("Polestar") and t:sub(-#file - 1) == "\\" .. file and r:IsShown() then n = n + 1 end
	end
	return n
end
local function alpha(t) return select(4, t:GetVertexColor()) end
local d = PolestarUIDB.hudLook
assert(d.frames.override and not d.chat and not d.damagemeter and not d.unitframes, "the old save was rewritten")
for name, look in pairs({ chat = H.CHAT, meter = H.METER, units = H.UNITS, frames = H.FRAMES }) do
	local shown, r, g, b, _, n = H.Edge(look)
	assert(shown and r == 1 and g == 1 and b == 1 and n == 2 and H.ShadowColor(look) == nil and H.GroundAlpha(look) == 0.5, name .. ": not the Frames override")
	assert(H.Band(look) and H.Rim(look), name .. ": the band or rim left Polestar's")
end
assert(art(dock, "shadow") == 0 and art(box, "shadow") == 0 and art(P, "shadow") == 0, "a shadow shows under the Frames override's none")
assert(art(dock, "band") == 1 and art(box, "band") == 1 and near(alpha(P.Ground.fill), 0.5), "the band went, or the player's ground is not the Frames override's")
local er, eg, eb = P.Ground.edges[1]:GetVertexColor()
assert(er == 1 and eg == 1 and eb == 1 and P.Ground.edges[1]:IsShown(), "the player's edge is not the Frames override's white")
-- The element tabs show the Frames override while following, and start from it.
local chat = in_["Chat look"]
assert(chat["Override Polestar's look"].get() == false and chat["Border colour"].get() == "white" and chat["Window shadow"].get() == false and chat["Background opacity"].get() == 50, "the chat tab does not show the Frames override it follows")
chat["Override Polestar's look"].set(true)
stub.advance(0.3)
local o = d.chat
assert(o ~= d.frames and o.borderColor == "white" and o.borderSize == 2 and o.shadow == false and o.ground == 0.5 and o.band == true and o.rim == true, "the chat's override did not start from the Frames override")
assert(art(dock, "shadow") == 0 and art(dock, "band") == 1, "turning the chat's override on changed it")
-- The Frames override changes: the meter and the unit frames follow, the chat keeps its own.
in_["Frames look"]["Background opacity"].set(80)
in_["Frames look"]["Window shadow"].set(true)
stub.advance(0.3)
assert(near(alpha(P.Ground.fill), 0.8) and art(P, "shadow") == 16 and art(box, "shadow") == 16, "the unit frames or the meter left the Frames override")
assert(H.GroundAlpha(H.CHAT) == 0.5 and art(dock, "shadow") == 0, "the chat's own look followed the Frames override")
stub.assertNoErrors()
