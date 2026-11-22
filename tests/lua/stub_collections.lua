-- The client's Collections journal as the Collections window sees it: the
-- mount journal and toy box APIs (C_MountJournal, C_ToyBox, C_ToyBoxInfo),
-- with a sample of 10 mounts (7 collected) and 24 toys (15 collected), the
-- filters and search filtering for real. Records:
--   stub.summoned, stub.dismissed   mount summoned (its ID) / dismissed
--   stub.usedToy                    the toy used (UseToy; errors from our code)
--   stub.picked                     what a drag picked up ("mount:3", "toy:1001")
--   stub.blocked                    protected calls made in combat
-- stub.mountSearch, stub.toySearch: the search set on the client.

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
CollectionsJournal = CreateFrame("Frame", "CollectionsJournal", UIParent)
CollectionsJournal:Hide()
CollectionsJournal:SetSize(700, 600)
CollectionsJournal.x, CollectionsJournal.y = 16, 100
function CollectionsJournal.Hide() error("addon code hid CollectionsJournal", 2) end
function CollectionsJournal.Show() error("addon code showed CollectionsJournal", 2) end
CollectionsJournal.CloseButton = CreateFrame("Button", nil, CollectionsJournal)
CollectionsJournal.CloseButton:SetScript("OnClick", function() UIParent.Hide(CollectionsJournal) end)
CollectionsMicroButton = CreateFrame("Button", "CollectionsMicroButton", UIParent)
CollectionsMicroButton.tooltipText = "Collections (Shift-J)"
CollectionsMicroButton:SetScript("OnClick", function() UIParent.Show(CollectionsJournal) end)
CollectionsMicroButton:SetFrameStrata("HIGH")
CollectionsMicroButton:SetFrameLevel(40)
-- Forever's bindings (Bindings_Camelot.xml); the game's own runs open the stock journal.
for action, key in pairs({ TOGGLECOLLECTIONS = "SHIFT-J", TOGGLECOLLECTIONSMOUNTJOURNAL = "CTRL-M", TOGGLECOLLECTIONSPETJOURNAL = "CTRL-P",
	TOGGLECOLLECTIONSTOYBOX = "CTRL-T", TOGGLECOLLECTIONSWARDROBE = "CTRL-W" }) do
	stub.bindings[action] = { key }
	stub.bindingRun[action] = function() UIParent.Show(CollectionsJournal) end
end

MOUNTS, PET_JOURNAL, TOY_BOX, WARDROBE = "Mounts", "Pet Journal", "Toy Box", "Appearances"
COLLECTED, NOT_COLLECTED, SOURCES, CHECK_ALL, UNCHECK_ALL = "Collected", "Not Collected", "Sources", "Check All", "Uncheck All"
MOUNT_JOURNAL_FILTER_UNUSABLE, MOUNT_JOURNAL_FILTER_TYPE = "Unusable", "Type"
MOUNT_JOURNAL_FILTER_GROUND, MOUNT_JOURNAL_FILTER_FLYING, MOUNT_JOURNAL_FILTER_AQUATIC = "Ground", "Flying", "Aquatic"
MOUNT, BINDING_NAME_DISMOUNT, UNWRAP = "Mount", "Dismount", "Unwrap"
MOUNT_SUMMON_TOOLTIP, MOUNT_UNWRAP_TOOLTIP = "Summon or dismiss this mount.", "Unwrap your new mount."
BATTLE_PET_FAVORITE, BATTLE_PET_UNFAVORITE = "Set Favorite", "Remove Favorite"
PET_JOURNAL_FILTER_USABLE_ONLY, EXPANSION_FILTER_TEXT = "Usable Only", "Expansions"
EXPANSION_NAME0, EXPANSION_NAME1 = "Classic", "The Burning Crusade"
for i, s in ipairs({ "Drop", "Quest", "Vendor", "Profession", "Pet Battle", "Achievement", "World Event", "Promotion" }) do _G["BATTLE_PET_SOURCE_" .. i] = s end
LE_MOUNT_JOURNAL_FILTER_COLLECTED, LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, LE_MOUNT_JOURNAL_FILTER_UNUSABLE = 1, 2, 3
Enum.MountType = { Ground = 0, Flying = 1, Aquatic = 2, Dragonriding = 3, RideAlong = 4 }
Enum.MountTypeMeta = { NumValues = 5 }
function GetNumExpansions() return 2 end
C_PetJournal = C_PetJournal or {}
function C_PetJournal.GetNumPetSources() return 8 end

---------------------------------------------------------------------------
-- Mounts: { name, spellID, collected, usable, favorite, faction (0/1), source, type, fanfare }

local MOUNTS_DATA = {
	{ "Brown Horse", 458, true, true, true, nil, 3, 0 },
	{ "Swift Palomino", 23227, true, true, false, 1, 3, 0 },
	{ "Black Stallion", 470, true, true, false, nil, 3, 0 },
	{ "Reins of the Spectral Bear", 90001, true, true, false, nil, 6, 0, true },
	{ "Riding Turtle", 30174, true, true, false, nil, 2, 2 },
	{ "Swift Razzashi Raptor", 24242, true, false, false, nil, 1, 0 }, -- collected, unusable here
	{ "Black War Kodo", 22718, true, false, false, 0, 3, 0 },
	{ "Ashes of Al'ar", 40192, false, false, false, nil, 1, 1 },
	{ "Deathcharger's Reins", 17481, false, false, false, nil, 1, 0 },
	{ "Mimiron's Head", 63796, false, false, false, nil, 1, 1 },
}
local mounts = {}
for i, m in ipairs(MOUNTS_DATA) do
	mounts[i] = { id = i, name = m[1], spell = m[2], collected = m[3], usable = m[4], favorite = m[5], faction = m[6], source = m[7], type = m[8], fanfare = m[9] }
end
stub.mounts = mounts
local mountFilter = { [1] = true, [2] = true, [3] = true }
local mountTypes, mountSources = {}, {}
local function defaultMountFilters()
	mountFilter = { [1] = true, [2] = true, [3] = true }
	for i = 1, 5 do mountTypes[i] = true end
	for i = 1, 8 do mountSources[i] = true end
end
defaultMountFilters()
stub.mountSearch = ""
stub.activeMount = nil

-- The displayed list, as the client orders it: favorites first, then collected, then the rest.
local function displayed()
	local out = {}
	for _, m in ipairs(mounts) do
		local ok = (m.collected and mountFilter[1] or not m.collected and mountFilter[2])
			and (m.usable or not m.collected or mountFilter[3])
			and mountTypes[m.type + 1] and mountSources[m.source]
			and (stub.mountSearch == "" or m.name:lower():find(stub.mountSearch:lower(), 1, true))
		if ok then out[#out + 1] = m end
	end
	table.sort(out, function(a, b)
		if a.favorite ~= b.favorite then return a.favorite end
		if a.collected ~= b.collected then return a.collected end
		return a.id < b.id
	end)
	return out
end

C_MountJournal = C_MountJournal or {} -- Polestar's lookup stub may have made it: extended
local lookupInfo = C_MountJournal.GetMountInfoByID
local function info(m)
	return m.name, m.spell, 132261 + m.id, stub.activeMount == m.id, m.usable and not InCombatLockdown(), m.source, m.favorite,
		m.faction ~= nil, m.faction, false, m.collected, m.id, false
end
function C_MountJournal.GetMountInfoByID(id)
	if mounts[id] then return info(mounts[id]) end
	if lookupInfo then return lookupInfo(id) end
end
function C_MountJournal.GetNumMounts() return #mounts end
function C_MountJournal.GetMountIDs()
	local t = {}
	for i in ipairs(mounts) do t[i] = i end
	return t
end
function C_MountJournal.GetNumDisplayedMounts() return #displayed() end
function C_MountJournal.GetDisplayedMountInfo(i)
	local m = displayed()[i]
	if m then return info(m) end
end
function C_MountJournal.GetDisplayedMountID(i) local m = displayed()[i]; return m and m.id end
function C_MountJournal.GetMountInfoExtraByID(id)
	local m = mounts[id]
	return 1000 + id, "A loyal companion of " .. m.name .. ".", "|cFFFFD200Vendor: |rKatie Hunter|n|cFFFFD200Zone: |rElwynn Forest", false, 0, 4, 0, 0, false
end
function C_MountJournal.GetMountAllCreatureDisplayInfoByID(id) return { { creatureDisplayID = 1000 + id } } end
function C_MountJournal.NeedsFanfare(id) return mounts[id] and mounts[id].fanfare or false end
function C_MountJournal.ClearFanfare(id) mounts[id].fanfare = nil end
function C_MountJournal.ClearRecentFanfares() stub.fanfaresCleared = true end
function C_MountJournal.SetSearch(s) stub.mountSearch = s or "" end
function C_MountJournal.GetIsFavorite(i)
	local m = displayed()[i]
	return m.favorite, m.collected
end
function C_MountJournal.SetIsFavorite(i, on) displayed()[i].favorite = on end
function C_MountJournal.SummonByID(id) stub.summoned = id; stub.activeMount = id end
function C_MountJournal.Dismiss() stub.dismissed = true; stub.activeMount = nil end
function C_MountJournal.Pickup(i)
	-- Not tested in game in combat: kept refused there (docs/CLIENT.md, rule 4).
	if InCombatLockdown() then
		stub.blocked = stub.blocked or {}
		return table.insert(stub.blocked, "C_MountJournal.Pickup")
	end
	stub.picked = "mount:" .. displayed()[i].id
end
function C_MountJournal.GetMountLink(spell) return "[mount:" .. spell .. "]" end
function C_MountJournal.GetMountUsabilityByID(id, indoors)
	local m = mounts[id]
	if m.usable and not InCombatLockdown() then return true end
	return false, InCombatLockdown() and "You can't do that while in combat." or "You can't use that mount here."
end
function C_MountJournal.GetCollectedFilterSetting(k) return mountFilter[k] end
function C_MountJournal.SetCollectedFilterSetting(k, v) mountFilter[k] = v end
function C_MountJournal.IsValidTypeFilter(i) return i <= 3 end
function C_MountJournal.IsTypeChecked(i) return mountTypes[i] end
function C_MountJournal.SetTypeFilter(i, v) mountTypes[i] = v end
function C_MountJournal.IsValidSourceFilter(i) return i ~= 5 end
function C_MountJournal.IsSourceChecked(i) return mountSources[i] end
function C_MountJournal.SetSourceFilter(i, v) mountSources[i] = v end
function C_MountJournal.SetAllSourceFilters(v) for i = 1, 8 do mountSources[i] = v end end
function C_MountJournal.IsUsingDefaultFilters()
	if not (mountFilter[1] and mountFilter[2] and mountFilter[3]) then return false end
	for i = 1, 5 do if not mountTypes[i] then return false end end
	for i = 1, 8 do if not mountSources[i] then return false end end
	return true
end
C_MountJournal.SetDefaultFilters = defaultMountFilters
function C_MountJournal.HasDisplayableMount() return true end

---------------------------------------------------------------------------
-- Toys: 24, item IDs 1001.., every third uncollected; 1004 a favorite (listed first),
-- 1007 just learnt (fanfare), 1002 cooling down.

local toys = {}
for i = 1, 24 do
	toys[i] = { id = 1000 + i, name = "Toy " .. i, has = i % 3 ~= 0, favorite = i == 4, fanfare = i == 7, source = i % 4 + 1, exp = i % 2 + 1 }
end
toys[1].name, toys[2].name, toys[4].name = "Hearthstone Board", "Orb of Deception", "Toy Train Set"
stub.toys = toys
local toyFilter = {}
local function defaultToyFilters()
	toyFilter = { collected = true, uncollected = true, unusable = true, sources = {}, exps = {} }
	for i = 1, 8 do toyFilter.sources[i] = true end
	for i = 1, 2 do toyFilter.exps[i] = true end
end
defaultToyFilters()
stub.toySearch = ""
local function filtered()
	local out = {}
	for _, t in ipairs(toys) do
		if (t.has and toyFilter.collected or not t.has and toyFilter.uncollected) and toyFilter.sources[t.source] and toyFilter.exps[t.exp]
			and (stub.toySearch == "" or t.name:lower():find(stub.toySearch:lower(), 1, true)) then
			out[#out + 1] = t
		end
	end
	table.sort(out, function(a, b)
		if a.favorite ~= b.favorite then return a.favorite end
		return a.id < b.id
	end)
	return out
end
local function toy(id) return toys[id - 1000] end

C_ToyBox, C_ToyBoxInfo = {}, {}
function C_ToyBox.ForceToyRefilter() end
function C_ToyBox.GetNumFilteredToys() return #filtered() end
function C_ToyBox.GetToyFromIndex(i) local t = filtered()[i]; return t and t.id or -1 end
function C_ToyBox.GetToyInfo(id)
	local t = toy(id)
	if t then return t.id, t.name, 133000 + (id - 1000), t.favorite, t.fanfare end
end
function C_ToyBox.GetIsFavorite(id) return toy(id).favorite end
function C_ToyBox.SetIsFavorite(id, on) toy(id).favorite = on end
function C_ToyBox.SetFilterString(s) stub.toySearch = s or "" end
function C_ToyBox.GetNumLearnedDisplayedToys()
	local n = 0
	for _, t in ipairs(toys) do if t.has then n = n + 1 end end
	return n
end
function C_ToyBox.GetNumTotalDisplayedToys() return #toys end
function C_ToyBox.GetToyLink(id) return "[" .. toy(id).name .. "]" end
function C_ToyBox.PickupToyBoxItem(id)
	if InCombatLockdown() then
		stub.blocked = stub.blocked or {}
		return table.insert(stub.blocked, "C_ToyBox.PickupToyBoxItem")
	end
	stub.picked = "toy:" .. id
end
function C_ToyBox.GetCollectedShown() return toyFilter.collected end
function C_ToyBox.SetCollectedShown(v) toyFilter.collected = v end
function C_ToyBox.GetUncollectedShown() return toyFilter.uncollected end
function C_ToyBox.SetUncollectedShown(v) toyFilter.uncollected = v end
function C_ToyBox.GetUnusableShown() return toyFilter.unusable end
function C_ToyBox.SetUnusableShown(v) toyFilter.unusable = v end
function C_ToyBox.SetAllSourceTypeFilters(v) for i = 1, 8 do toyFilter.sources[i] = v end end
function C_ToyBox.IsSourceTypeFilterChecked(i) return toyFilter.sources[i] end
function C_ToyBox.SetSourceTypeFilter(i, v) toyFilter.sources[i] = v end
function C_ToyBox.SetAllExpansionTypeFilters(v) for i = 1, 2 do toyFilter.exps[i] = v end end
function C_ToyBox.IsExpansionTypeFilterChecked(i) return toyFilter.exps[i] end
function C_ToyBox.SetExpansionTypeFilter(i, v) toyFilter.exps[i] = v end
function C_ToyBoxInfo.IsToySourceValid(i) return i <= 4 end
function C_ToyBoxInfo.IsUsingDefaultFilters()
	if not (toyFilter.collected and toyFilter.uncollected and toyFilter.unusable) then return false end
	for i = 1, 8 do if not toyFilter.sources[i] then return false end end
	for i = 1, 2 do if not toyFilter.exps[i] then return false end end
	return true
end
C_ToyBoxInfo.SetDefaultFilters = defaultToyFilters
function C_ToyBoxInfo.ClearFanfare(id) toy(id).fanfare = nil end
function C_ToyBoxInfo.HasAnyToy() return true end
function PlayerHasToy(id) return toy(id) and toy(id).has or false end
-- UseToy is forbidden from addon code, in or out of combat (docs/CLIENT.md,
-- rule 4): it errors with our code on the stack; only the secure "toy" action may use one.
function UseToy(id)
	for level = 2, 40 do
		local info = debug.getinfo(level, "S")
		if not info then break end
		if stub.addonSources[info.source] == "PolestarUI" then error("ADDON_ACTION_FORBIDDEN: UseToy from PolestarUI", 2) end
	end
	stub.usedToy = id
end
C_Spell = C_Spell or {}
local itemCooldown = C_Spell.GetItemCooldown
function C_Spell.GetItemCooldown(id)
	if id == 1002 then return { startTime = GetTime() - 10, duration = 60, isEnabled = true, modRate = 1 } end
	if toy(id) then return { startTime = 0, duration = 0, isEnabled = true, modRate = 1 } end
	if itemCooldown then return itemCooldown(id) end
end

ChatFrameUtil = ChatFrameUtil or {}
function ChatFrameUtil.InsertLink(link) stub.linked = link; return true end

---------------------------------------------------------------------------
-- Pets (the Classic pet journal): 8 species, 6 collected. Pet 1 a favorite
-- (listed first), pet 2 summoned, pet 3 new (fanfare), pet 4 cooling down
-- (secret times in combat), pet 5 the other faction's (never summonable),
-- pet 6 revoked; species 9007 and 9008 not collected. Records:
--   stub.petSummoned, stub.petDismissed   the GUID summoned / dismissed
-- stub.petSearch: the search set on the client.

PET_DISMISS, BATTLE_PET_SUMMON = "Dismiss", "Summon"
BATTLE_PETS_SUMMON_TOOLTIP, BATTLE_PETS_UNWRAP_TOOLTIP = "Summon or dismiss this pet.", "Unwrap your new pet."
LE_PET_JOURNAL_FILTER_COLLECTED, LE_PET_JOURNAL_FILTER_NOT_COLLECTED = 1, 2
Enum.PetJournalError = { None = 0, PetIsDead = 1, JournalIsLocked = 2, InvalidFaction = 3, NoFavoritesToSummon = 4 }
local PETS_DATA = { -- name, owned, favorite, custom name
	{ "Mechanical Squirrel", true, true }, { "Black Tabby Cat", true, false, "Mister Whiskers" }, { "Hyacinth Macaw", true, false },
	{ "Prairie Dog", true, false }, { "Lil' K.T.", true, false }, { "Ancona Chicken", true, false },
	{ "Mini Diablo", false, false }, { "Panda Cub", false, false },
}
local pets = {}
for i, p in ipairs(PETS_DATA) do
	pets[i] = { guid = p[2] and ("BattlePet-0-%06d"):format(i) or nil, species = 9000 + i, name = p[1], owned = p[2], favorite = p[3], custom = p[4],
		fanfare = i == 3, never = i == 5, revoked = i == 6 }
end
stub.pets = pets
stub.activePet = pets[2].guid
local petFilter = { true, true }
stub.petSearch = ""
local function petList()
	local out = {}
	for _, p in ipairs(pets) do
		if (p.owned and petFilter[1] or not p.owned and petFilter[2]) and (stub.petSearch == "" or p.name:lower():find(stub.petSearch:lower(), 1, true)) then out[#out + 1] = p end
	end
	table.sort(out, function(a, b)
		if a.favorite ~= b.favorite then return a.favorite end
		if a.owned ~= b.owned then return a.owned end
		return a.species < b.species
	end)
	return out
end
local function petByGUID(id) for _, p in ipairs(pets) do if p.guid == id then return p end end end
local function petBySpecies(s) for _, p in ipairs(pets) do if p.species == s then return p end end end
function C_PetJournal.GetNumPets()
	local owned = 0
	for _, p in ipairs(pets) do if p.owned then owned = owned + 1 end end
	return #petList(), owned
end
function C_PetJournal.GetPetInfoByIndex(i)
	local p = petList()[i]
	if p then return p.guid, p.species, p.owned, p.custom, 1, p.favorite, p.revoked, p.name, 134000 + p.species - 9000, 1 end
end
function C_PetJournal.GetPetInfoByPetID(id)
	local p = petByGUID(id)
	if p then return p.species, p.custom, 1, 0, 100, 2000 + p.species, p.favorite, p.name, 134000 + p.species - 9000, 1, 0,
		"|cFFFFD200Vendor: |rDonni Anthania", "A loyal friend.", false, false, true, false end
end
function C_PetJournal.GetPetInfoBySpeciesID(s)
	local p = petBySpecies(s)
	if p then return p.name, 134000 + s - 9000, 1, 0, "|cFFFFD200Drop: |rSomewhere", "Not yours yet.", false, false, true, false, nil, 2000 + s end
end
function C_PetJournal.GetPetModelSceneInfoBySpeciesID() return 7, 8 end
function C_PetJournal.PetNeedsFanfare(id) local p = petByGUID(id); return p and p.fanfare or false end
function C_PetJournal.ClearFanfare(id) petByGUID(id).fanfare = nil end
function C_PetJournal.ClearRecentFanfares() stub.petFanfaresCleared = true end
function C_PetJournal.PetIsRevoked(id) local p = petByGUID(id); return p and p.revoked or false end
function C_PetJournal.PetIsLockedForConvert() return false end
function C_PetJournal.PetIsFavorite(id) return petByGUID(id).favorite end
function C_PetJournal.SetFavorite(id, v) petByGUID(id).favorite = v == 1 end
function C_PetJournal.IsJournalUnlocked() return true end
function C_PetJournal.GetSummonedPetGUID() return stub.activePet end
function C_PetJournal.IsCurrentlySummoned(id) return id ~= nil and id == stub.activePet end
function C_PetJournal.PetIsSummonable(id) local p = petByGUID(id); return p and not p.never and not p.revoked and not InCombatLockdown() or false end
function C_PetJournal.GetPetSummonInfo(id)
	local p = petByGUID(id)
	if p.never then return false, Enum.PetJournalError.InvalidFaction, "This pet can't be summoned by your faction." end
	if InCombatLockdown() then return false, 5, "You can't do that while in combat." end
	return true, Enum.PetJournalError.None, nil
end
-- Summoning from addon code works (checked in game); it toggles, as the client's.
function C_PetJournal.SummonPetByGUID(id)
	if stub.activePet == id then stub.activePet = nil; stub.petDismissed = id else stub.activePet = id; stub.petSummoned = id end
end
function C_PetJournal.DismissSummonedPet(id) stub.activePet = nil; stub.petDismissed = id end
function C_PetJournal.PickupPet(id)
	if InCombatLockdown() then
		stub.blocked = stub.blocked or {}
		return table.insert(stub.blocked, "C_PetJournal.PickupPet")
	end
	stub.picked = "pet:" .. id
end
function C_PetJournal.GetPetCooldownByGUID(id)
	if id ~= pets[4].guid then return 0, 0, 1 end
	if InCombatLockdown() then return stub.SECRET, stub.SECRET, stub.SECRET end
	return GetTime() - 5, 30, 1
end
function C_PetJournal.GetBattlePetLink(id) return "[battlepet:" .. id .. "]" end
function C_PetJournal.GetNonBattlePetLinkByIndex(i) return "[" .. petList()[i].name .. "]" end
function C_PetJournal.SetSearchFilter(s) stub.petSearch = s or "" end
function C_PetJournal.IsFilterChecked(k) return petFilter[k] end
function C_PetJournal.SetFilterChecked(k, v) petFilter[k] = v end
GetCursorInfo = GetCursorInfo or function() return nil end
ClearCursor = ClearCursor or function() end

---------------------------------------------------------------------------
-- Appearances: categories 1-11 armor, 13 one-handed axes (main hand), 18
-- shields (off hand), 25 bows (ranged). Head has 20 appearances (2 pages),
-- others 4; each appearance has 2 sources (Tab cycles them). On the head:
-- 101 a favorite, 102 new, 103 not displayable on the player, 104 unusable,
-- 105 only refundable sources (a favorite asks first).
-- The search is async: in progress until stub.finishSearch(type).
-- Sets: three base sets; 501 has two variants (502 with a new piece, 503),
-- 511 a favorite, 521 nothing collected. Records:
--   stub.transmogSearch[type]   the search set on the client
--   stub.searchCategory         SetSearchAndFilterCategory's last category
--   stub.collectedShown, stub.uncollectedShown
--   stub.dressedUp              DressUpVisual's source

HEADSLOT, SHOULDERSLOT, BACKSLOT, CHESTSLOT, SHIRTSLOT, TABARDSLOT, WRISTSLOT = "Head", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist"
HANDSSLOT, WAISTSLOT, LEGSSLOT, FEETSLOT, MAINHANDSLOT, SECONDARYHANDSLOT, RANGEDSLOT = "Hands", "Waist", "Legs", "Feet", "Main Hand", "Off Hand", "Ranged"
TRANSMOG_ITEM_SET_FAVORITE, TRANSMOG_ITEM_UNSET_FAVORITE, WARDROBE_TRANSMOGRIFY_AS = "Set favorite", "Remove favorite", "Transmogrify as:"
TRANSMOG_SET_PVE, TRANSMOG_SET_PVP, ITEMS, WARDROBE_SETS = "PvE", "PvP", "Items", "Sets"
for i, s in ipairs({ "Boss Drop", "Quest", "Vendor", "World Drop" }) do _G["TRANSMOG_SOURCE_" .. i] = s end
LE_TRANSMOG_SET_FILTER_COLLECTED, LE_TRANSMOG_SET_FILTER_UNCOLLECTED, LE_TRANSMOG_SET_FILTER_PVE, LE_TRANSMOG_SET_FILTER_PVP = 1, 2, 3, 4
Enum.TransmogType = { Appearance = 0, Illusion = 1 }
Enum.TransmogModification = { Main = 0, Secondary = 1 }
Enum.TransmogSearchType = { Items = 1, BaseSets = 2, UsableSets = 3 }
Enum.TransmogCollectionType.Paired = 29
local SLOT_IDS = { HEADSLOT = 1, SHOULDERSLOT = 3, SHIRTSLOT = 4, CHESTSLOT = 5, WAISTSLOT = 6, LEGSSLOT = 7, FEETSLOT = 8, WRISTSLOT = 9,
	HANDSSLOT = 10, BACKSLOT = 15, MAINHANDSLOT = 16, SECONDARYHANDSLOT = 17, RANGEDSLOT = 18, TABARDSLOT = 19 }
GetInventorySlotInfo = GetInventorySlotInfo or function(slot)
	return SLOT_IDS[slot], "Interface\\Paperdoll\\UI-PaperDoll-Slot-" .. slot:gsub("SLOT$", ""):lower()
end
C_PaperDollInfo = C_PaperDollInfo or {}
function C_PaperDollInfo.IsRangedSlotShown() return true end
local CLASSES = { { 1, "Warrior", "WARRIOR" }, { 2, "Paladin", "PALADIN" }, { 3, "Hunter", "HUNTER" } }
GetNumClasses = GetNumClasses or function() return #CLASSES end
C_CreatureInfo = C_CreatureInfo or {}
C_CreatureInfo.GetClassInfo = C_CreatureInfo.GetClassInfo or function(i)
	local c = CLASSES[i]
	if c then return { classID = c[1], className = c[2], classFile = c[3] } end
end
function Model_ApplyUICamera(m, id) m.psAppliedCamera = id end
function IsUnitModelReadyForUI() return true end
C_Item = C_Item or {}
local instant = C_Item.GetItemInfoInstant -- the character stub's takes links: ours, item IDs (as the client's does too)
function C_Item.GetItemInfoInstant(id)
	if type(id) == "number" or not instant then return id, "Armor", "Plate", "INVTYPE_HEAD", 135000 + (tonumber(id) or 0) % 1000 end
	return instant(id)
end
function HandleModifiedItemClick(l) stub.linked = l; return true end
function DressUpVisual(src) stub.dressedUp = src end
C_Transmog = C_Transmog or {}
function C_Transmog.GetSlotForInventoryType(t) return t end

local CATS = { [13] = { "One-Handed Axes", true, false, false }, [18] = { "Shields", false, true, false }, [25] = { "Bows", false, false, true } }
local looks = {}
local function looksFor(cat)
	if not looks[cat] then
		local list = {}
		for i = 1, cat == 1 and 20 or 4 do
			local id = cat * 100 + i
			list[i] = { visualID = id, name = (cat == 1 and "Helm " or "Look ") .. id, isCollected = true, isUsable = id ~= 104, isFavorite = id == 101,
				canDisplayOnPlayer = id ~= 103, isHideVisual = false, uiOrder = id }
		end
		looks[cat] = list
	end
	return looks[cat]
end
stub.looksFor = looksFor
stub.newLook = { [102] = true }
stub.transmogSearch = {}
local searching = {}
local itemSources = { true, true, true, true }
local classFilter, setClassFilter = 1, 1
local function lookByID(id) for _, v in ipairs(looksFor(math.floor(id / 100))) do if v.visualID == id then return v end end end
local function sources(visualID)
	local v = lookByID(visualID)
	return { { sourceID = visualID * 10 + 1, visualID = visualID, name = v.name, isCollected = true, quality = 3, itemID = visualID * 10 + 1 },
		{ sourceID = visualID * 10 + 2, visualID = visualID, name = v.name .. " (alt)", isCollected = true, quality = 2, itemID = visualID * 10 + 2 } }
end
local T = {}
C_TransmogCollection = T
function T.GetCategoryInfo(cat)
	if stub.noCategory and stub.noCategory[cat] then return nil end -- live: GetCategoryInfo(13) is nil on Forever
	if cat >= 1 and cat <= 11 then return "Armor " .. cat, false end
	local c = CATS[cat]
	if c then return c[1], true, false, c[2], c[3], c[4] end
end
function T.GetCategoryAppearances(cat)
	local out, q = {}, stub.transmogSearch[1] or ""
	for _, v in ipairs(looksFor(cat)) do
		if not searching[1] and (q == "" or v.name:lower():find(q:lower(), 1, true)) then out[#out + 1] = v end
	end
	return out
end
function T.GetAppearanceSources(visualID) return sources(visualID) end
function T.GetValidAppearanceSourcesForClass(visualID) return sources(visualID) end
function T.GetAppearanceInfoBySource(id) return { sourceIsCollectedPermanent = math.floor(id / 10) ~= 105 } end
function T.GetAppearanceSourceInfo(id) return { itemLink = "[item:" .. id .. "]", category = 1 } end
function T.GetSourceInfo(id) return { sourceID = id, visualID = math.floor(id / 10), itemID = id, invType = id % 100, quality = 4, isCollected = true, name = "Piece " .. id } end
function T.GetSourceIcon(id) return 136000 + id % 1000 end
function T.GetAppearanceCameraID(visualID) return 200 + math.floor(visualID / 100) end
function T.IsNewAppearance(id) return stub.newLook[id] or false end
function T.ClearNewAppearance(id) stub.newLook[id] = nil end
function T.GetIsAppearanceFavorite(id) local v = lookByID(id); return v and v.isFavorite or false end
function T.SetIsAppearanceFavorite(id, on) local v = lookByID(id); if v then v.isFavorite = on end; stub.favoriteLook = { id, on } end
function T.SetSearchAndFilterCategory(cat) stub.searchCategory = cat end
function T.SetSearch(kind, text) stub.transmogSearch[kind] = text; searching[kind] = true; return false end
function T.ClearSearch(kind) stub.transmogSearch[kind] = nil; searching[kind] = nil end
function T.EndSearch() stub.searchEnded = true end
function T.IsSearchInProgress(kind) return searching[kind] or false end
function stub.finishSearch(kind)
	searching[kind] = nil
	stub.fire("TRANSMOG_SEARCH_UPDATED", kind, stub.searchCategory)
end
function T.GetNumTransmogSources() return 6 end
function T.IsValidTransmogSource(i) return i <= 4 end
function T.IsSourceTypeFilterChecked(i) return itemSources[i] end
function T.SetSourceTypeFilter(i, v) itemSources[i] = v end
function T.SetAllSourceTypeFilters(v) for i = 1, 4 do itemSources[i] = v end end
function T.IsUsingDefaultFilters() for i = 1, 4 do if not itemSources[i] then return false end end return true end
function T.SetDefaultFilters() T.SetAllSourceTypeFilters(true) end
function T.SetCollectedShown(v) stub.collectedShown = v end
function T.SetUncollectedShown(v) stub.uncollectedShown = v end
function T.GetClassFilter() return classFilter end
function T.SetClassFilter(c) classFilter = c end
function T.GetFilteredCategoryCollectedCount(cat) return #looksFor(cat) - (cat == 1 and 2 or 0) end
function T.GetFilteredCategoryTotal(cat) return #looksFor(cat) end
function T.HasAnyAppearance() return true end
function T.UpdateUsableAppearances() end

-- Sets: { setID, name, label, collected, favorite, base (variants), description, pieces collected of 4 }
local SETS_DATA = {
	{ 501, "Battlegear of Might", "Raid", false, false, nil, "Normal", 2 },
	{ 502, "Battlegear of Might", "Raid", false, false, 501, "Heroic", 3 },
	{ 503, "Battlegear of Might", "Raid", false, false, 501, "Mythic", 0 },
	{ 511, "Lightforge Armor", "Dungeon", true, true, nil, nil, 4 },
	{ 521, "Gladiator's Plate", "PvP", false, false, nil, nil, 0 },
}
local setsByID, setOrder = {}, {}
for i, s in ipairs(SETS_DATA) do
	local set = { setID = s[1], name = s[2], label = s[3], collected = s[4], favorite = s[5], baseSetID = s[6], description = s[7], got = s[8],
		expansionID = 0, patchID = 0, uiOrder = i, validForCharacter = true }
	setsByID[s[1]] = set
	setOrder[i] = set
end
stub.sets = setsByID
local setFilter = { true, true, true, true }
local S = {}
C_TransmogSets = S
local function copy(t) local o = {}; for k, v in pairs(t) do o[k] = v end; return o end
function S.GetBaseSets()
	local out, q = {}, stub.transmogSearch[2] or ""
	for _, s in ipairs(setOrder) do
		if not s.baseSetID and not searching[2] and (q == "" or s.name:lower():find(q:lower(), 1, true))
			and (s.got == 4 and setFilter[1] or s.got < 4 and setFilter[2]) then out[#out + 1] = copy(s) end
	end
	return out
end
function S.GetVariantSets(base)
	local out = {}
	for _, s in ipairs(setOrder) do if s.baseSetID == base then out[#out + 1] = copy(s) end end
	return out
end
function S.GetSetInfo(id) return setsByID[id] and copy(setsByID[id]) end
function S.GetBaseSetID(id) return setsByID[id] and setsByID[id].baseSetID or id end
function S.IsSetVisible(id) return setsByID[id] ~= nil end
function S.GetSetPrimaryAppearances(id)
	local s, out = setsByID[id], {}
	for i = 1, 4 do out[i] = { appearanceID = id * 100 + i, collected = i <= s.got } end
	return out
end
function S.GetSourcesForSlot(id, slot) return { T.GetSourceInfo(id * 100 + slot) } end
function S.GetFilteredBaseSetsCounts() return 1, 3 end
function S.GetBaseSetsFilter(k) return setFilter[k] end
function S.SetBaseSetsFilter(k, v) setFilter[k] = v end
function S.IsUsingDefaultBaseSetsFilters() for i = 1, 4 do if not setFilter[i] then return false end end return true end
function S.SetDefaultBaseSetsFilters() for i = 1, 4 do setFilter[i] = true end end
function S.GetTransmogSetsClassFilter() return setClassFilter end
function S.SetTransmogSetsClassFilter(c) setClassFilter = c end
function S.SetIsFavorite(id, on) setsByID[id].favorite = on end
function S.HasAnyValidSets() return not stub.noSets end
function S.SetHasNewSources(id) return id == 502 and not stub.setNewCleared end
function S.SetHasNewSourcesForSlot(id, slot) return id == 502 and slot == 1 and not stub.setNewCleared end
function S.ClearSetNewSourcesForSlot() stub.setNewCleared = true end
function S.GetCameraIDs() return 300, 301 end

-- CollectionWardrobeUtil (Blizzard_FrameXMLUtil): the parts ours calls.
CollectionWardrobeUtil = {}
function CollectionWardrobeUtil.SortSources(s) return s end
function CollectionWardrobeUtil.GetSortedAppearanceSources(v, cat, loc) assert(loc:GetData().slotID, "location"); return T.GetAppearanceSources(v, cat, loc:GetData()) end
function CollectionWardrobeUtil.GetSortedAppearanceSourcesForClass(v, class, cat, loc) assert(loc:GetData().slotID, "location"); return T.GetValidAppearanceSourcesForClass(v, class, cat, loc:GetData()) end
function CollectionWardrobeUtil.GetValidIndexForNumSources(index, n)
	index = index - 1
	if index < 0 then index = n + index end
	return math.fmod(index, n) + 1
end
function CollectionWardrobeUtil.SetAppearanceTooltip(tt, d)
	local i = d.selectedIndex and CollectionWardrobeUtil.GetValidIndexForNumSources(d.selectedIndex, #d.sources) or 1
	tt:SetText(d.sources[i].name)
	return i, #d.sources > 1
end
function CollectionWardrobeUtil.GetAppearanceItemHyperlink(s) return "[item:" .. s.sourceID .. "]" end
function CollectionWardrobeUtil.CompareAppearance(a, b)
	if a.isFavorite ~= b.isFavorite then return a.isFavorite end
	return a.uiOrder < b.uiOrder
end
function CollectionWardrobeUtil.IsAppearanceUsable(s) return s.isCollected end
function CollectionWardrobeUtil.GetAppearanceNameTextAndColor(s) return s.name end

-- Keyboard on a frame: propagation is protected in combat (the client refuses it from addon code then).
function stub.Methods.EnableKeyboard(self, on) self.keyboardEnabled = on and true or false end
function stub.Methods.SetPropagateKeyboardInput(self, on)
	if InCombatLockdown() then error("SetPropagateKeyboardInput in combat", 2) end
	self.propagate = on and true or false
end
