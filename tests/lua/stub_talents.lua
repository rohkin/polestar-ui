-- The client calls the Talents window reads, on Polestar's own snapshot of
-- Forever's mage tree (Talents/Builds.lua: nodes, ranks, rows, columns,
-- prerequisites), laid out as the client's trait tree: one tree, a node group
-- per talent tree, positions in the client's units.
--   stub.dual        a second spec learnt (Secondary in the sidebar)
--   stub.specGroup   the active spec group (1)
function UnitLevel(unit) return 24 end
function UnitClass(unit) return "Mage", "MAGE", 8 end

local data
do
	local dir = os.getenv("POLESTAR_DIR") or "../polestar"
	local ns = { L = setmetatable({}, { __index = function(_, k) return k end }), Talents = {} }
	function ns.Talents.Register(d) if d.class == "MAGE" then data = d end end
	assert(loadfile(dir .. "/addon/Polestar/Talents/Builds.lua"))("Polestar", ns)
end

local TREE = data.tree
-- node = { entry, max ranks, spell, spec column, row, column, name }
local byEntry, sources = {}, {}
for id, n in pairs(data.nodes) do byEntry[n[1]] = id end
for _, e in ipairs(data.edges) do
	sources[e[2]] = sources[e[2]] or {}
	table.insert(sources[e[2]], e[1])
end

-- Each config's learnt ranks: points poured into its trees in order, row by
-- row, as far as tier gates (5 points a row) and prerequisites let them;
-- Primary is Frost with one point staged in Arcane, Secondary Fire.
local function sorted(spec)
	local ids = {}
	for id, n in pairs(data.nodes) do if n[4] == spec then ids[#ids + 1] = id end end
	table.sort(ids, function(a, b)
		local x, y = data.nodes[a], data.nodes[b]
		if x[5] ~= y[5] then return x[5] < y[5] end
		return x[6] < y[6]
	end)
	return ids
end
local function fill(ranks, spec, points)
	local spent = 0
	for _, id in ipairs(sorted(spec)) do
		local n = data.nodes[id]
		local ok = spent >= (n[5] - 1) * 5
		for _, s in ipairs(sources[id] or {}) do ok = ok and (ranks[s] or 0) == data.nodes[s][2] end
		if ok then
			local r = math.min(n[2], points)
			if r > 0 then ranks[id] = r end
			spent, points = spent + r, points - r
		end
	end
	return points
end
local CONFIGS = {}
CONFIGS[11] = { ranks = {} }
fill(CONFIGS[11].ranks, 3, 14)
CONFIGS[11].staged = {}
for k, v in pairs(CONFIGS[11].ranks) do CONFIGS[11].staged[k] = v end
fill(CONFIGS[11].staged, 1, 1)
CONFIGS[12] = { ranks = {} }
fill(CONFIGS[12].ranks, 2, 15)
CONFIGS[12].staged = CONFIGS[12].ranks
local POINTS = 15

local function spentBy(c, spec)
	local s = 0
	for id, r in pairs(c.staged) do if not spec or data.nodes[id][4] == spec then s = s + r end end
	return s
end

C_SpecializationInfo = {}
function C_SpecializationInfo.GetActiveSpecGroup() return stub.specGroup or 1 end
function C_SpecializationInfo.GetCombatConfigIDForSpecGroup(g) return 10 + g end
function GetNumSpecGroups() return stub.dual and 2 or 1 end

C_Traits = {}
function C_Traits.GetConfigInfo(config) return CONFIGS[config] and { ID = config, treeIDs = { TREE } } end
function C_Traits.GetTreeNodes(tree)
	local ids = {}
	for id in pairs(data.nodes) do ids[#ids + 1] = id end
	table.sort(ids)
	return ids
end
function C_Traits.GetGroupDisplayInfoByTreeID(tree)
	local out = {}
	for i, name in ipairs(data.specs) do out[i] = { groupID = 1000 + i, treeID = tree, orderIndex = i, displayName = name, icon = 1 } end
	return out
end
function C_Traits.GetGroupCurrencyInfo(config, ids)
	local out = {}
	for i, g in ipairs(ids) do
		out[i] = { traitNodeGroupID = g, currencyInfos = { { traitCurrencyID = 1, quantity = 0, spent = spentBy(CONFIGS[config], g - 1000) } } }
	end
	return out
end
function C_Traits.GetTreeCurrencyInfo(config)
	local s = spentBy(CONFIGS[config])
	return { { traitCurrencyID = 1, quantity = POINTS - s, spent = s } }
end
function C_Traits.GetNodeInfo(config, id)
	local c, n = CONFIGS[config], data.nodes[id]
	local learnt, cur = c.ranks[id] or 0, c.staged[id] or 0
	local meets = true
	for _, s in ipairs(sources[id] or {}) do meets = meets and (c.staged[s] or 0) == data.nodes[s][2] end
	local edges = {}
	for _, e in ipairs(data.edges) do
		if e[1] == id then edges[#edges + 1] = { targetNode = e[2], type = 1, visualStyle = 1, isActive = cur == n[2] } end
	end
	-- Off the grid by a few units, as the client's positions are.
	return { ID = id, posX = (n[4] - 1) * 4000 + (n[6] - 1) * 600 + id % 7 * 9 - 27, posY = 1500 + (n[5] - 1) * 600 + id % 5 * 11 - 22,
		entryIDs = { n[1] }, isVisible = true, isAvailable = spentBy(c, n[4]) >= (n[5] - 1) * 5,
		meetsEdgeRequirements = meets, activeRank = learnt, currentRank = cur, ranksPurchased = cur, maxRanks = n[2],
		visibleEdges = edges, groupIDs = { 1000 + n[4] }, activeEntry = cur > 0 and { entryID = n[1], rank = cur } or nil }
end
function C_Traits.GetEntryInfo(config, entry) return { definitionID = entry, maxRanks = 1, conditionIDs = {} } end
function C_Traits.GetDefinitionInfo(def) local n = data.nodes[byEntry[def]]; return n and { spellID = n[3] } end
C_Spell = C_Spell or {}
function C_Spell.GetSpellTexture(id) return 134400 end
function C_Spell.GetSpellLink(id) return "|Hspell:" .. id .. "|h[" .. id .. "]|h" end
function GameTooltip:SetTraitEntry(entry, rank) stub.tooltipEntry = entry end
DUAL_SPEC_PRIMARY, DUAL_SPEC_SECONDARY = "Primary", "Secondary"

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
PlayerSpellsFrame = CreateFrame("Frame", "PlayerSpellsFrame", UIParent)
PlayerSpellsFrame:Hide()
function PlayerSpellsFrame.Hide() error("addon code hid PlayerSpellsFrame", 2) end
function stub.bindingRun.TOGGLETALENTS() PlayerSpellsFrame:Show() end
TalentMicroButton = CreateFrame("Button", "TalentMicroButton", UIParent)
TalentMicroButton.tooltipText = "Talents (N)"
-- High in its bar, as the micro menu sits: the overlay must land above it.
TalentMicroButton:SetFrameStrata("HIGH")
TalentMicroButton:SetFrameLevel(40)
