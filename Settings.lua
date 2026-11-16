-- Polestar: UI's page in Polestar's settings (Polestar.RegisterOptions;
-- docs/settings.md). Every control keeps its state in our own saved data
-- (PolestarUIDB, PolestarUICharDB) through get/set, never in PolestarDB:
-- the page only reads and writes it, as /pui and the windows' menus do.
-- A reset (the page's or a section's) calls set(nil): our default again.

local ADDON, ns = ...
if ns.tooOld then return end

local PAGE, KEY = "Polestar: UI", "polestarui"
local WINDOWS, HUD = "Windows", "HUD"

-- Each module's name on the page; one missing here shows its /pui key.
local LABELS = {
	character = "Character", spellbook = "Spellbook", talents = "Talents", professions = "Professions",
	crafting = "Crafting", legacy = "Legacy", map = "World map and quest log", bank = "Bank", mail = "Mail",
	gossip = "Gossip", merchant = "Merchant", trainer = "Trainer", questdialog = "Quest dialog", loot = "Loot",
	social = "Social", auction = "Auction house", guild = "Guild", macros = "Macros", inspect = "Inspect",
	collections = "Collections", groupfinder = "Group finder", bags = "Bags", baganator = "Baganator skin",
	unitframes = "Unit frames", minimap = "Minimap", actionbars = "Action bars", auras = "Buffs and debuffs",
	castbars = "Cast bars", cooldownviewer = "Cooldown viewer", resourcedisplay = "Personal resource display",
	nameplates = "Nameplates", damagemeter = "Damage meter", tooltips = "Tooltips", chat = "Chat",
}

-- A module with no window of its own (a noun of its own, as "unit frames")
-- is the HUD's; the Baganator skin dresses a window.
local function tabOf(key)
	local m = ns.modules[key]
	return m and m.noun and key ~= "baganator" and HUD or WINDOWS
end

-- The default with no saved choice (ns.Enabled's), read without changing it.
local function default(key)
	local was = PolestarUIDB.modules[key]
	PolestarUIDB.modules[key] = nil
	local on = ns.Enabled(key)
	PolestarUIDB.modules[key] = was
	return on
end

-- As /pui <key> on|off (ns.Switch: refused in combat); nil: back to no saved choice.
local function setModule(key, v)
	if v == nil then
		local on = default(key)
		if ns.Enabled(key) ~= on then ns.Switch(key, on) end
		if ns.Enabled(key) == on then PolestarUIDB.modules[key] = nil end
	elseif v ~= ns.Enabled(key) then
		ns.Switch(key, v)
	end
end

local function moduleToggle(key)
	local m = ns.modules[key]
	local what = m.noun and ("the game's " .. m.noun) or "the game's own window"
	return { kind = "toggle", label = LABELS[key] or key, search = "/pui " .. key,
		help = "On: Polestar's. Off: " .. what .. (m.reloadOff and ", after /reload." or ".") .. " Not in combat.",
		get = function() return ns.Enabled(key) end, set = function(v) setModule(key, v) end }
end

-- Unit frames: their options in PolestarUIDB.unitframes, read and applied live by the module.
local function uf() return ns.modules.unitframes end
local function ufGet(k) return uf().Option(k) end
local function ufSet(k, v) return uf().SetOption(k, v) end
local function ufToggle(k, label, help)
	return { kind = "toggle", label = label, help = help, search = "unit frames",
		get = function() return ufGet(k) end, set = function(v) ufSet(k, v) end }
end

local function register(spec)
	spec.page, spec.key, spec.icon, spec.order, spec.group = PAGE, KEY, "window", 66, "setup"
	local ok, err = Polestar.RegisterOptions(spec)
	if not ok then geterrorhandler()(err) end
end

-- At login, after the modules have enabled: an NPC window says it waits for
-- /reload (reloadOff) only once ns.Interaction has run.
Polestar.OnLogin(function()
	if ns.tooOld then return end
	local windows, hud = {}, {}
	for _, key in ipairs(ns.order) do
		local list = tabOf(key) == HUD and hud or windows
		list[#list + 1] = moduleToggle(key)
	end
	register({ tab = WINDOWS, section = "Windows", controls = windows })
	register({ tab = WINDOWS, section = "Docking", controls = {
		{ kind = "toggle", label = "Dock windows", search = "dock, move, /pui dock",
			help = "On: the windows line up from the top left as the game's do. Off: drag each where you like.",
			get = function() return ns.Docked() end, set = function(v) ns.SetDocked(v ~= false) end },
	} })
	register({ tab = HUD, section = "HUD", controls = hud })
	register({ tab = HUD, section = "Unit frames", controls = {
		{ kind = "slider", label = "Background opacity", min = 0, max = 100, step = 5, format = "%d%%", search = "unit frames",
			help = "The ground behind the bars. Their colours follow your Polestar theme; with its \"Class colour\" on, players wear their class colour.",
			get = function() return math.floor(ufGet("ground") * 100 + 0.5) end, set = function(v) ufSet("ground", v and v / 100) end },
		ufToggle("portrait", "3D portraits", "The unit's model in a square beside the bars."),
		ufToggle("powerText", "Power text", "The unit's power as a number, shown as the game's Status Text options show the health."),
		ufToggle("sparkle", "Sparkle", "Polestar's stars over the health bars, as over its windows' header band."),
		ufToggle("smooth", "Smooth bars", "Health and power glide to a new value instead of jumping."),
		ufToggle("trail", "Damage trail", "Health just lost stays red for a moment, then drains away."),
	} })
	register({ tab = HUD, section = "Chat", controls = {
		{ kind = "toggle", label = "Keep chat across sessions", search = "chat history",
			help = "Keep each chat window's last lines across /reload and logout, on this computer only (whispers too). Off, they are forgotten at logout.",
			get = function() return not PolestarUICharDB.chatNoHistory end,
			set = function(v) PolestarUICharDB.chatNoHistory = v == false or nil end },
	} })
end)

-- Opens our page on the tab holding `key`'s toggle (a window's "..." menu).
-- Polestar.UI is absent only where Polestar's UI is not loaded (the preview).
function ns.ShowSettings(key)
	local UI = Polestar.UI
	if not UI then return end
	UI.ShowOptions(KEY)
	local O = UI.Options
	if O and O.Select then O.Select(KEY, key and tabOf(key) or nil) end
end
