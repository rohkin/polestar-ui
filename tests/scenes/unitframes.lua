--@ title: Unit frames: player, target and its target, focus and its target
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUITargetToT, PolestarUIFocusFrame, PolestarUIFocusToT
stub.cvars.statusText = "1"
stub.cvars.statusTextDisplay = "BOTH"
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1830, max = 2400, heals = 300, power = 45, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.target = { name = "Kurzen", level = 25, health = 12400, max = 20000, power = 900, powerMax = 1200, powerType = 0, reaction = 2, classification = "elite", threat = 3 }
stub.units.targettarget = stub.units.player
stub.units.focus = { name = "Paxton", level = 26, class = "PRIEST", player = true, health = 2000, max = 2000, absorbs = 400, power = 3000, powerMax = 4000, powerType = 0, reaction = 5 }
stub.units.focustarget = { name = "Kobold Miner", level = 23, health = 0, max = 800, dead = true, reaction = 4 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.advance(0.3)
local P, T = PolestarUIPlayerFrame, PolestarUITargetFrame
assert(P:IsShown() and T:IsShown() and PolestarUITargetToT:IsShown() and PolestarUIFocusFrame:IsShown(), "frames shown")
-- Ours sit on the stock frames' Edit Mode boxes, at their scale: 40 high, centred in the box.
assert(P:GetPoint(1) == "TOPLEFT" and select(4, P:GetPoint(1)) == PlayerFrame.Selection:GetLeft(), "player on its box")
assert(select(5, T:GetPoint(1)) == TargetFrame.Selection:GetTop() - (TargetFrame.Selection:GetHeight() - 40) / 2 and T:GetHeight() == 40
	and T:GetWidth() == TargetFrame.Selection:GetWidth(), "target centred in its box")
-- The stock frames stay (Edit Mode's proxies), their art and bars hidden, their mouse off.
assert(PlayerFrame:IsShown() and not PlayerFrame:IsMouseEnabled(), "stock player kept, mouse off")
assert(not PlayerFrame.PlayerFrameContainer:IsShown() and not PlayerFrame.PlayerFrameContent.PlayerFrameContentMain:IsShown(), "stock art hidden")
assert(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual:IsShown(), "stock icons and auras kept")
assert(TargetFrameToT:GetAlpha() == 0, "stock target of target faded")
-- Faded, its bars (TextStatusBar) would still show the game's unit tooltip over ours: their hover off.
assert(not TargetFrameToT.HealthBar:IsMouseMotionEnabled() and not TargetFrameToT.ManaBar:IsMouseMotionEnabled(), "the faded target of target's bars still take the mouse")
-- Secure: targets on left click, the game's unit menu on right click.
assert(T:GetAttribute("*type1") == "target" and T:GetAttribute("*type2") == "togglemenu" and T:GetAttribute("unit") == "target", "secure clicks")
assert(P:GetAttribute("toggleForVehicle"), "player follows the vehicle")
local glow = PolestarUITargetFrame.Ground.glow
assert(glow[1]:IsShown() and glow[4]:IsShown(), "threat glow shown on the target")
assert(not PolestarUIPlayerFrame.Ground.glow[1]:IsShown(), "no glow without threat")
-- Values are the client's secrets, handed over unread.
assert(issecretvalue(T.Health:GetValue()), "health handed over as the secret it is")
assert(T.healthText:GetText() == "12.4K || 62%", "health text: " .. tostring(T.healthText:GetText()))
assert(T.levelText:GetText() == "25+", "level and rank: " .. tostring(T.levelText:GetText()))
assert(not P.levelText, "no level on the player")
assert(T.powerText:GetText() ~= "", "power text on by default, with the health text")
assert(PolestarUIFocusToT:IsShown(), "a dead target of target still shows (only a dead target hides it)")
-- The portrait: the model loads again only for another unit, unseen until framed.
local m, loads = T.portrait.Model, 0
local setUnit = m.SetUnit
m.SetUnit = function(self, ...) loads = loads + 1 return setUnit(self, ...) end
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("UNIT_THREAT_SITUATION_UPDATE", "target")
stub.fire("UNIT_HEALTH", "target")
stub.fire("PLAYER_REGEN_DISABLED")
stub.fire("PLAYER_REGEN_ENABLED")
assert(loads == 0, "the model loaded again for the same unit: " .. loads)
assert(m:GetAlpha() == 1, "a framed model is hidden")
local thug = stub.units.target
stub.units.target = { name = "Defias Pillager", level = 25, health = 900, max = 1000, reaction = 2 }
stub.fire("PLAYER_TARGET_CHANGED")
assert(loads == 1 and m:GetAlpha() == 0, "a new unit's model shows before it is framed")
stub.RunScript(m, "OnModelLoaded")
assert(m:GetAlpha() == 1, "the model is not shown once framed")
stub.units.target = thug
stub.fire("PLAYER_TARGET_CHANGED")
stub.advance(0.3)
assert(loads == 2 and m:GetAlpha() == 1, "a model that never says it loaded is not shown")
-- The level takes stock's colour (CheckLevel): by the gap to the player's 24, gold on a friend, red on "??".
local function levelRGB(u) stub.units.target = u stub.fire("PLAYER_TARGET_CHANGED") return T.levelText:GetTextColor() end
local function same(u, c) local r, g, b = levelRGB(u) return math.abs(r - c.r) < 0.01 and math.abs(g - c.g) < 0.01 and math.abs(b - c.b) < 0.01 end
local C, kurzen = QuestDifficultyColors, stub.units.target
assert(same({ name = "A", level = 10, reaction = 2 }, C.trivial), "grey")
assert(same({ name = "A", level = 18, reaction = 2 }, C.standard), "green")
assert(same({ name = "A", level = 25, reaction = 2 }, C.difficult), "yellow")
assert(same({ name = "A", level = 27, reaction = 2 }, C.verydifficult), "orange")
assert(same({ name = "A", level = 29, reaction = 2 }, C.impossible), "red")
assert(same({ name = "A", level = -1, reaction = 2 }, C.impossible), "skull")
assert(same({ name = "A", level = 25, reaction = 5 }, { r = 1, g = 0.82, b = 0 }), "friendly gold")
local dr, dg, db = Polestar.Theme.Color("textDim")
assert(same({ name = "A", level = stub.SECRET, reaction = 2 }, { r = dr, g = dg, b = db }), "a secret level keeps the neutral colour")
stub.units.target = kurzen stub.fire("PLAYER_TARGET_CHANGED")
-- The client's default status text (Interface > Status Text: None) still shows the numbers on mouse-over, as stock does.
stub.cvars.statusText, stub.cvars.statusTextDisplay = "0", "NONE"
stub.fire("CVAR_UPDATE", "statusText")
assert(P.healthText:GetText() == "", "health text hidden off mouse-over: " .. tostring(P.healthText:GetText()))
stub.RunScript(P, "OnEnter")
assert(P.healthText:GetText() == "1830 / 2400", "health text on mouse-over: " .. tostring(P.healthText:GetText()))
stub.RunScript(P, "OnLeave")
assert(P.healthText:GetText() == "", "health text kept after mouse-over: " .. tostring(P.healthText:GetText()))
stub.cvars.statusText, stub.cvars.statusTextDisplay = "1", "BOTH"
stub.fire("CVAR_UPDATE", "statusText")
