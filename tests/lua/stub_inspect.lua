-- The client's inspect as the Inspect window sees it (Camelot
-- Blizzard_InspectUI): InspectUnit (the bootstrap) loads the addon on demand,
-- which makes InspectFrame; InspectFrame_Show asks the server (NotifyInspect)
-- and the stock frame shows itself on INSPECT_READY for its unit. The gear
-- is stub_character.lua's (it ignores the unit).

local GUIDS = { player = "Player-1-0000", target = "Player-1-0001", party1 = "Player-1-0002" }
local NAMES = { target = "Aldric-Silvermoon", party1 = "Brenna" }
function UnitGUID(u) return GUIDS[u] end
function GetUnitName(u, realm) return InCombatLockdown() and stub.SECRET or NAMES[u] or "Testchar" end
function CanInspect(u) return stub.canInspect ~= false and GUIDS[u] ~= nil end
stub.notified, stub.inspectCleared = {}, 0
function NotifyInspect(u) table.insert(stub.notified, u) end
function ClearInspectPlayer() stub.inspectCleared = stub.inspectCleared + 1 end

-- The inspected unit: a level 60 paladin of the guild "Silver Hand".
local unitClass, unitLevel = UnitClass, UnitLevel
function UnitClass(u) if u == "player" then return unitClass(u) end return "Paladin", "PALADIN", 2 end
function UnitLevel(u) if u == "player" then return unitLevel(u) end return 60 end
RAID_CLASS_COLORS.PALADIN = RAID_CLASS_COLORS.PALADIN or { r = 0.96, g = 0.55, b = 0.73 }
RAID_CLASS_COLORS.PALADIN.colorStr = "fff48cba"
PLAYER_LEVEL_NO_SPEC = "Level %s |c%s%s|r"
stub.inspectGuild = { 0, 42, "Silver Hand", "" }
C_PaperDollInfo.GetInspectGuildInfo = function(u) return unpack(stub.inspectGuild) end
INSPECT_GUILD_FACTION, INSPECT_GUILD_NUM_MEMBERS = "%s Guild", "%d Members"
function SetLargeGuildTabardTextures(u, emblem) emblem:SetTexture("Interface/GuildFrame/GuildEmblemsLG_01") end
-- todayHK, todayHonor, yesterdayHK, yesterdayHonor, lifetimeHK, lifetimeRank, rank, points, next rank's points
function GetInspectHonorData() return 3, 0, 0, 0, 1287, 0, 5, 3400, 5000 end
HONORABLE_KILLS, HONOR_LIFETIME, HONOR_TODAY = "Honorable Kills", "Lifetime", "Today"
PVP_RANK_CURRENT_PROGRESS = "%d / %d"
EXPANSION_SEASON_NAME = "%sSeason %d"

-- A PlayerModel: SetUnit draws unless stub.noModel (out of range).
function stub.Methods.SetUnit(self, u) self.modelUnit = u; return not stub.noModel end
function stub.Methods.RefreshUnit(self) self.refreshed = true end

-- The load-on-demand addon and its open, as the stock code runs them.
function InspectUnit(u)
	if not InspectFrame then
		InspectFrame = CreateFrame("Frame", "InspectFrame", UIParent)
		InspectFrame:Hide()
		InspectFrame:RegisterEvent("INSPECT_READY")
		InspectFrame:SetScript("OnEvent", function(self, ev, guid)
			if ev == "INSPECT_READY" and self.unit and UnitGUID(self.unit) == guid then self:Show() end
		end)
		stub.addonLoaded("Blizzard_InspectUI")
	end
	InspectFrame:Hide()
	if CanInspect(u, true) then
		NotifyInspect(u)
		InspectFrame.unit = u
	else
		InspectFrame.unit = nil
	end
end
-- The server's answer.
function stub.inspectReady(u) stub.fire("INSPECT_READY", UnitGUID(u)) end
