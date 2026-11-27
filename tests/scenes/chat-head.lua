--@ title: Chat: the window head (band, rim) and shadow, docked and floating
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrame1Tab, ChatFrame2Tab, ChatFrame3, ChatFrame3ButtonFrame, ChatFrame3Tab
--@ stubs: stub_chat.lua
-- The chat as a Polestar window: over the docked tabs the header band (sky, stars, haze) and the accent rim with its light, round header and window the window shadow; each follows Polestar's own setting live (Header band, Rim, Shadow). A window pulled off the dock gets a header of its own under its tab, with the same head and shadow; docked again, it is gone. With "Fade chat when idle" the head and shadow rest with the ground. Switched off, nothing of ours is left.
local T = Polestar.Theme
local function near(a, b) return math.abs(a - b) < 1e-6 end
-- Our shown textures on f whose file is `file`.
local function art(f, file)
	local out = {}
	for _, r in ipairs({ f:GetRegions() }) do
		local t = r.GetTexture and tostring(r:GetTexture())
		if t and t:find("Polestar") and t:sub(-#file - 1) == "\\" .. file and r:IsShown() then out[#out + 1] = r end
	end
	return out
end
local function ours(f) local n = 0 for _, r in ipairs({ f:GetRegions() }) do if r.GetTexture and tostring(r:GetTexture()):find("Polestar") and r:IsShown() then n = n + 1 end end return n end
local function rim(f) local n = 0 for _, r in ipairs(art(f, "white")) do if r:GetDrawLayer() == "OVERLAY" then n = n + 1 end end return n end
-- sky, stars, glows (the haze and the rim's light), the rim's lines, the shadow's parts.
local function is(f, sky, stars, glow, lines, shadow)
	return #art(f, "band") == sky and #art(f, "band-stars") == stars and #art(f, "glow") == glow and rim(f) == lines and #art(f, "shadow") == shadow
end
local dock = GeneralDockManager
stub.chatSample()
stub.advance(0.3)
-- Docked (fade off: warm): the band, the rim and the shadow on the dock, under the tabs; none on the window.
assert(is(dock, 1, 1, 2, 4, 16), "the docked header has no band, rim or shadow")
assert(is(ChatFrame1, 0, 0, 0, 0, 0), "a docked window carries a head of its own")
local sky = art(dock, "band")[1]
local layer, sub = sky:GetDrawLayer()
assert(near(select(4, sky:GetVertexColor()), 1) and layer == "BACKGROUND" and sub == -7, "the band not full, or not just above the header's ground")
-- Cropped 1:1 from the band's top left (Theme.BandCoords), never stretched.
local _, x1, _, y1 = T.BandCoords(ChatFrame1:GetWidth() + ChatFrame1ButtonFrame:GetWidth(), 32)
assert(near(sky.texCoord[2], x1) and near(sky.texCoord[4], y1) and x1 < 1 and y1 < 1, "the band stretched over the header")
-- Polestar's Header band off, live: the band and its haze go, the rim stays; on again.
Polestar.Set("ui.band", false)
stub.advance(0.3)
assert(is(dock, 0, 0, 1, 4, 16), "the band shows with Polestar's header band off (or the rim went with it)")
Polestar.Set("ui.band", nil)
stub.advance(0.3)
assert(is(dock, 1, 1, 2, 4, 16), "the band not back")
-- The rim off, live; the shadow off, live.
Polestar.Set("ui.rim", false)
stub.advance(0.3)
assert(is(dock, 1, 1, 1, 0, 16), "the rim shows with Polestar's rim off")
Polestar.Set("ui.rim", nil)
Polestar.Set("ui.shadow", false)
stub.advance(0.3)
assert(is(dock, 1, 1, 2, 4, 0), "the shadow shows with Polestar's shadow off")
Polestar.Set("ui.shadow", nil)
stub.advance(0.3)
-- A second window, docked: no header of its own. Pulled off the dock: its own, 32 tall on its ground, under its tab (which sits on the ground's top), with the head and the shadow round both.
local loot = stub.makeChat(3, "Loot")
loot:Hide()
stub.dockDynamic(ChatFrame3Tab, ChatFrame2Tab)
PolestarUI.modules.chat.Apply()
stub.advance(0.1)
assert(is(loot, 0, 0, 0, 0, 0), "a docked second window has a header")
stub.undockChat(loot, 620, 120)
loot:AddMessage("You receive loot: [Runecloth]", 0.2, 0.9, 0.2)
stub.advance(0.3)
assert(is(loot, 1, 1, 2, 4, 16), "a floating window has no header band, rim or shadow")
assert(is(dock, 1, 1, 2, 4, 16), "the dock lost its head to the floating window")
local ground, strip
for _, r in ipairs(art(loot, "white")) do
	local l, s = r:GetDrawLayer()
	if l == "BACKGROUND" and s == -8 then if r:GetHeight() == 32 then strip = r else ground = r end end
end
local p, rel, rp, _, y = strip:GetPoint(1)
assert(p == "BOTTOMLEFT" and rel == ground and rp == "TOPLEFT" and y == 0, "the floating header not on the window's ground")
local tp, trel, trp, _, ty = ChatFrame3Tab:GetPoint(1)
assert(tp == "BOTTOMLEFT" and trel == loot.Background and trp == "TOPLEFT" and ty == 0 and ChatFrame3Tab:GetHeight() == 32, "the floating tab not in its header")
assert(near(select(4, strip:GetVertexColor()), T.GroundAlpha()), "the floating header's ground not the window's")
-- In game the floating tab sat 2px above the window's ground: its label, wash and underline are moved down onto the header, as a dynamic docked tab's are.
ChatFrame3Tab.y = 2
stub.advance(0.1)
assert(select(5, ChatFrame3Tab.Text:GetPoint()) == select(5, ChatFrame1Tab.Text:GetPoint()) - 2, "a floating tab's label not moved onto its header")
-- Docked again: its header, head and shadow gone (the dock's is over it); pulled off again, back.
local docked = ours(ChatFrame1)
stub.dockChat(loot, ChatFrame2Tab)
loot:Show()
stub.advance(0.1)
assert(is(loot, 0, 0, 0, 0, 0) and ours(loot) == docked, "the header stays on a window docked again")
stub.undockChat(loot, 620, 120)
stub.advance(0.3)
assert(is(loot, 1, 1, 2, 4, 16), "the header not back on a window pulled off again")
-- "Fade chat when idle": at rest the head and the shadow rest with the ground (0.35 of them).
PolestarUIDB.chatFade = true
stub.advance(1.2)
local _, _, _, sa = PolestarUI.HUD.ShadowColor()
assert(near(select(4, sky:GetVertexColor()), 0.35) and near(select(4, art(loot, "band")[1]:GetVertexColor()), 0.35), "the band does not rest with the ground")
assert(near(select(4, art(dock, "shadow")[1]:GetVertexColor()), sa * (T.GroundAlpha() * 0.35 + 0.1)), "the shadow does not rest with the ground")
PolestarUIDB.chatFade = nil
stub.advance(0.3)
assert(near(select(4, sky:GetVertexColor()), 1), "the band not warm again")
-- Switched off: nothing of ours on the dock, the docked window or the floating one; on again, all back at once.
PolestarUI.Switch("chat", false)
assert(ours(dock) == 0 and ours(ChatFrame1) == 0 and ours(loot) == 0, "ours still shows with the chat off")
stub.advance(0.3)
assert(ours(dock) == 0 and ours(loot) == 0, "ours came back while off")
PolestarUI.Switch("chat", true)
assert(is(dock, 1, 1, 2, 4, 16) and is(loot, 1, 1, 2, 4, 16), "not back when on again")
stub.advance(0.3)
stub.assertNoErrors()
