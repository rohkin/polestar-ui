--@ title: Unit frames: player, target and its target, focus and its target
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUITargetToT, PolestarUIFocusFrame, PolestarUIFocusToT
stub.cvars.statusText = "1"
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1830, max = 2400, heals = 300, power = 45, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.target = { name = "Defias Thug", level = 25, health = 12400, max = 20000, power = 900, powerMax = 1200, powerType = 0, reaction = 2, classification = "elite", threat = 3 }
stub.units.targettarget = stub.units.player
stub.units.focus = { name = "Brother Paxton", level = 26, class = "PRIEST", player = true, health = 2000, max = 2000, absorbs = 400, power = 3000, powerMax = 4000, powerType = 0, reaction = 5 }
stub.units.focustarget = { name = "Kobold Miner", level = 23, health = 0, max = 800, dead = true, reaction = 4 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.advance(0.3)
local P, T = PolestarUIPlayerFrame, PolestarUITargetFrame
assert(P:IsShown() and T:IsShown() and PolestarUITargetToT:IsShown() and PolestarUIFocusFrame:IsShown(), "frames shown")
-- Ours sit on the stock frames' Edit Mode boxes, at their scale.
assert(P:GetPoint(1) == "TOPLEFT" and select(4, P:GetPoint(1)) == PlayerFrame.Selection:GetLeft(), "player on its box")
assert(select(5, T:GetPoint(1)) == TargetFrame.Selection:GetTop() and T:GetWidth() == TargetFrame.Selection:GetWidth(), "target on its box")
-- The stock frames stay (Edit Mode's proxies), their art and bars hidden, their mouse off.
assert(PlayerFrame:IsShown() and not PlayerFrame:IsMouseEnabled(), "stock player kept, mouse off")
assert(not PlayerFrame.PlayerFrameContainer:IsShown() and not PlayerFrame.PlayerFrameContent.PlayerFrameContentMain:IsShown(), "stock art hidden")
assert(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual:IsShown(), "stock icons and auras kept")
assert(TargetFrameToT:GetAlpha() == 0, "stock target of target faded")
-- Secure: targets on left click, the game's unit menu on right click.
assert(T:GetAttribute("*type1") == "target" and T:GetAttribute("*type2") == "togglemenu" and T:GetAttribute("unit") == "target", "secure clicks")
assert(P:GetAttribute("toggleForVehicle"), "player follows the vehicle")
-- Values are the client's secrets, handed over unread.
assert(issecretvalue(T.Health:GetValue()), "health handed over as the secret it is")
assert(T.healthText:GetText() == "12.4K / 20.0K", "health text: " .. tostring(T.healthText:GetText()))
assert(T.levelText:GetText() == "25 Elite", "level and rank: " .. tostring(T.levelText:GetText()))
assert(PolestarUIFocusToT:IsShown(), "a dead target of target still shows (only a dead target hides it)")
