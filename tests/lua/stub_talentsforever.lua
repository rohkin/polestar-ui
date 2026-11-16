-- Talents Forever (TalentsForeverBook) loaded, after stub_talents.lua: a Mage
-- plan whose first point is learnt; the next goes into the tree's second node.
-- Toggle counts its calls in stub.tfToggled.
local tree = C_Traits.GetConfigInfo(11).treeIDs[1]
local ids = C_Traits.GetTreeNodes(tree)
table.sort(ids)
stub.tfNext = ids[2]
stub.tfToggled = 0

local callbacks = {}
TalentsForeverBookData = { classes = { MAGE = { trees = { { talents = { { node = ids[1] }, { node = ids[2] } } } } } } }
TalentsForeverBook = {
	db = { settings = { overlay = true } },
	plan = { cls = "MAGE", level = 24, ranks = { { 1, 1 } }, order = { { 1, 1 }, { 1, 2 } } },
	NextUp = function(p) return { { ti = 1, i = 1, rank = 1, level = 10, done = true }, { ti = 1, i = 2, rank = 1, level = 11, done = false } } end,
	Toggle = function() stub.tfToggled = stub.tfToggled + 1 end,
	Game = { live = { cls = "MAGE" }, Node = function(ti, i) return { id = ids[i] } end },
	On = function(ev, fn) callbacks[ev] = callbacks[ev] or {}; table.insert(callbacks[ev], fn) end,
}
function stub.tfFire(ev) for _, fn in ipairs(callbacks[ev] or {}) do fn() end end
