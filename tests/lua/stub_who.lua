-- The Who list as the Group Finder's Who page reads it (load after
-- stub_groupfinder.lua, whose guarded C_FriendList.SendWho it keeps): the
-- results (stub.whoResults, stub.whoTotal: the server's count, past the 50 it
-- sends), race filters, the class list and a zone tree. Records:
--   stub.whoToUi   the last C_FriendList.SetWhoToUi value
--   stub.whoSort   the last SortWho { sorting, ascending }
--   stub.invited, stub.told, stub.popup   invite, whisper, the player menu
-- A scene delivers results with stub.fire("WHO_LIST_UPDATE").

Enum.SocialWhoOrigin = { Unknown = 0, Social = 1, Chat = 2, Item = 3 }
Enum.UIMapType = Enum.UIMapType or {}
Enum.UIMapType.World = 1

stub.whoResults = {}
stub.whoTotal = nil
function C_FriendList.GetNumWhoResults() return #stub.whoResults, stub.whoTotal or #stub.whoResults end
function C_FriendList.GetWhoInfo(i) return stub.whoResults[i] end
function C_FriendList.SetWhoToUi(on) stub.whoToUi = on end
function C_FriendList.SortWho(sorting, ascending)
	stub.whoSort = { sorting = sorting, ascending = ascending }
	local key = ({ name = "fullName", class = "classStr", level = "level" })[sorting]
	table.sort(stub.whoResults, function(a, b)
		if ascending == false then return a[key] > b[key] end
		return a[key] < b[key]
	end)
end
function C_FriendList.GetWhoRaceFilters()
	return { { ID = 1, name = "Human" }, { ID = 2, name = "Orc" }, { ID = 4, name = "Night Elf" }, { ID = 5, name = "Undead" } }
end

local CLASSES = { [1] = { "Warrior", "WARRIOR" }, [2] = { "Paladin", "PALADIN" }, [4] = { "Rogue", "ROGUE" }, [8] = { "Mage", "MAGE" }, [11] = { "Druid", "DRUID" } }
C_SpecializationInfo = C_SpecializationInfo or {}
function C_SpecializationInfo.GetAllClassIDs() return { 1, 2, 4, 8, 11 } end
function GetClassInfo(id) local c = CLASSES[id]; if c then return c[1], c[2], id end end

-- Azeroth (947) holds two continents; each holds zones (leaves).
local MAPS = {
	[947] = { { mapID = 13, name = "Eastern Kingdoms" }, { mapID = 12, name = "Kalimdor" } },
	[13] = { { mapID = 1429, name = "Elwynn Forest" }, { mapID = 1453, name = "Stormwind City" } },
	[12] = { { mapID = 1411, name = "Durotar" }, { mapID = 1454, name = "Orgrimmar" } },
}
C_Map = C_Map or {}
function C_Map.GetBestMapForUnit() return 1429 end
function C_Map.GetFallbackWorldMapID() return 947 end
function C_Map.GetMapChildrenInfo(id) return MAPS[id] end
function C_Map.IsMapValidForNavBarDropdown() return true end
MapUtil = MapUtil or {}
function MapUtil.GetMapParentInfo() return { mapID = 947, name = "Azeroth" } end

C_PartyInfo = C_PartyInfo or {}
function C_PartyInfo.InviteUnit(name) stub.invited = name end
ChatFrameUtil = ChatFrameUtil or {}
function ChatFrameUtil.SendTell(name) stub.told = name end
function FriendsFrame_ShowDropdown(name, connected) stub.popup = { name, connected } end

-- The sample: a few players, the player herself among them.
local function who(name, level, race, class, file, area, guild)
	return { fullName = name, level = level, raceStr = race, classStr = class, filename = file, area = area, fullGuildName = guild or "", gender = 2 }
end
stub.whoSample = {
	who("Aldwyn", 60, "Human", "Paladin", "PALADIN", "Stormwind City", "Knights of the Silver Hand"),
	who("Brakka", 42, "Orc", "Warrior", "WARRIOR", "Durotar"),
	who("Testchar", 42, "Human", "Mage", "MAGE", "Elwynn Forest", "Polestar"),
	who("Thessaly", 58, "Night Elf", "Druid", "DRUID", "Elwynn Forest", "Moonglade Wardens"),
	who("Vex", 19, "Undead", "Rogue", "ROGUE", "Orgrimmar"),
}

-- The stock Who list (Blizzard_GroupFinder_VanillaStyle, loaded at login on
-- Forever): on every WHO_LIST_UPDATE it shows the game's window
-- (LFGWhoListMixin:UpdateWhoList). stub.loadWhoList() makes it again and fires
-- ADDON_LOADED, as a late load.
function stub.loadWhoList()
	LFGWhoListFrame = CreateFrame("Frame", "LFGWhoListFrame", LFGParentFrame)
	LFGWhoListFrame:RegisterEvent("WHO_LIST_UPDATE")
	LFGWhoListFrame:SetScript("OnEvent", function() UIParent.Show(LFGParentFrame) end)
end
stub.loadWhoList()
