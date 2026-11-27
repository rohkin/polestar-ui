-- Polestar: UI's page in Polestar's settings (Polestar.RegisterOptions;
-- docs/settings.md). Every control keeps its state in our own saved data
-- (PolestarUIDB, PolestarUICharDB) through get/set, never in PolestarDB:
-- the page only reads and writes it, as /pui and the windows' menus do.
-- A reset (the page's or a section's) calls set(nil): our default again.

local ADDON, ns = ...
if ns.tooOld then return end

local PAGE, KEY = "Polestar: UI", "polestarui"
local WINDOWS, HUD, ICONS = "Windows", "HUD", "Icons"
-- The elements with a tab of their own (their options and their own look,
-- ns.HUD's CHAT, METER and UNITS): module key (its hudLook group too), tab,
-- what the look's help calls them, what its band and rim are.
local ELEMENTS = {
	{ "unitframes", "Unit frames", "unit frames", "The header band's stars over the player's health bar (with Sparkle on).", "The accent line along the top of the player's frame, with its light." },
	{ "chat", "Chat", "chat windows", "The starlit band behind the chat tabs.", "The accent line along the top of the chat's tab header, with its light." },
	{ "damagemeter", "Damage meter", "damage meter's windows", "The starlit band behind each window's header.", "The accent line along the top of each window, with its light." },
}
local OWN_TAB = {}
for _, e in ipairs(ELEMENTS) do OWN_TAB[e[1]] = e[2] end

-- Each module's name on the page; one missing here shows its /pui key.
local LABELS = {
	character = "Character", spellbook = "Spellbook", talents = "Talents", professions = "Professions",
	crafting = "Crafting", legacy = "Legacy", map = "World map and quest log", bank = "Bank", mail = "Mail",
	gossip = "Gossip", merchant = "Merchant", trainer = "Trainer", questdialog = "Quest dialog", loot = "Loot",
	social = "Social", auction = "Auction house", guild = "Guild", macros = "Macros", inspect = "Inspect",
	collections = "Collections", groupfinder = "Group finder", bags = "Bags", baganator = "Baganator skin",
	unitframes = "Unit frames", minimap = "Minimap", actionbars = "Action bars", bagbar = "Bag bar", micromenu = "Micro menu", auras = "Buffs and debuffs",
	castbars = "Cast bars", statusbars = "Experience and reputation bars", cooldownviewer = "Cooldown viewer", resourcedisplay = "Personal resource display",
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

local function blockedNote(by) return "Off while " .. by .. " is loaded: its own bags and bank take its place." end

local function moduleToggle(key)
	local m = ns.modules[key]
	local what = m.noun and ("the game's " .. m.noun) or "the game's own window"
	local help = "On: Polestar's. Off: " .. what .. (m.reloadOff and ", after /reload." or ".") .. " Not in combat."
	-- ns.Enabled: blocked beside another addon (Addons/Bagnon.lua), off and greyed.
	if m.blockedBy then help = blockedNote(m.blockedBy) end
	return { kind = "toggle", label = LABELS[key] or key, search = "/pui " .. key, help = help,
		disabled = m.blockedBy and function() return true end or nil,
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

-- The nameplates' cast bar: PolestarUIDB.nameplates through the module's Option/SetOption (live).
local function plateCast()
	local function get(k) return function() return ns.modules.nameplates.Option(k) end end
	local function set(k) return function(v) ns.modules.nameplates.SetOption(k, v) end end
	return {
		{ kind = "toggle", label = "Cast bar icon", search = "nameplate cast bar icon, spell icon",
			help = "The spell's icon at the left end of a nameplate's cast bar (with the game's own Spell Icon option on).",
			get = get("castIcon"), set = set("castIcon") },
		{ kind = "slider", label = "Cast bar height", min = 6, max = 16, step = 1, format = "%d", search = "nameplate cast bar height, thin cast bar",
			help = "In the plate's units (the game's Thin bar is 6, its cast area 16). Under 9, the spell's name and time go under the bar. Block and Cast Focus keep at least 16.",
			get = get("castHeight"), set = set("castHeight") },
	}
end

-- Polestar's page re-checks a row's `disabled` (and redraws its value) only on
-- a SETTING_CHANGED, and the look rows are no settings: each look change
-- refreshes the look rows itself (the rows Options made, W.SetDisabledWhen
-- then w.psControl).
local W = Polestar.Widgets
local optionRows, lookControl = setmetatable({}, { __mode = "k" }), {}
hooksecurefunc(W, "SetDisabledWhen", function(w) optionRows[w] = true end)
local function refreshLookRows()
	local set = {}
	for w in pairs(optionRows) do if lookControl[w.psControl] then set[w] = true end end
	W.RefreshShownAll(set)
end

-- One HUD look group's controls (PolestarUIDB.hudLook[group]), as Polestar's
-- Frames tab offers them for its windows. Shown as followed while off.
-- `el` (an ELEMENTS row): one element's own look over the Frames look, with
-- the window head's band and rim.
local function lookControls(group, what, el)
	local H = ns.HUD
	local function db() PolestarUIDB.hudLook = PolestarUIDB.hudLook or {}; return PolestarUIDB.hudLook end
	local function own() local o = db()[group]; return o and o.override and o or nil end
	local function following() return own() == nil end
	local function repaint() Polestar.Theme.Refresh(); refreshLookRows() end
	-- A value control: the override's own, else what Polestar's gives now; reset: Polestar's now.
	local function field(k, get, scale)
		return function() local o = own(); if o then return get(o[k], o) end return get(H.Seed(group)[k], H.Seed(group)) end,
			function(v) local o = own(); if not o then return end
				if v == nil then v = H.Seed(group)[k] elseif scale then v = v / scale end
				o[k] = v
				repaint()
			end
	end
	local function pct(v) return math.floor((tonumber(v) or 0) * 100 + 0.5) end
	local controls = {
		{ kind = "toggle", label = "Override Polestar's look", search = "hud border, shadow, background, " .. what,
			help = el and "Off: the " .. what .. " wear the Frames look (the HUD tab): Polestar's own settings, or that look's override. On: the settings below, for these alone."
				or "Off: the " .. what .. " wear Polestar's own Frames settings (border, shadow, background opacity). On: the settings below, for these alone.",
			get = function() return not following() end,
			set = function(v)
				local d = db()
				if v then
					local o = d[group]
					if not (o and o.borderSize) then o = H.Seed(group) end
					o.override = true
					d[group] = o
				elseif d[group] then
					d[group].override = nil
				end
				repaint()
			end },
	}
	local function add(c)
		c.search = c.search .. ", " .. what
		local was = c.disabled
		c.disabled = function() return following() or (was and was() or false) end
		controls[#controls + 1] = c
	end
	local borderOff = function() local o = own(); return o and o.border == false end
	local get, set
	if el then
		get, set = field("band", function(v) return v ~= false end)
		add({ kind = "toggle", label = "Starlit band", search = "band, header band, stars, sky", help = el[4], get = get, set = set })
		get, set = field("rim", function(v) return v ~= false end)
		add({ kind = "toggle", label = "Accent rim", search = "rim, gold line, accent line", help = el[5] .. " Polestar's own skin only.",
			disabled = function() return Polestar.Theme.SkinKey() ~= "polestar" end, get = get, set = set })
	end
	get, set = field("border", function(v) return v ~= false end)
	add({ kind = "toggle", label = "Window border", search = "border, edge, outline", help = "The line round each of them.", get = get, set = set })
	get, set = field("borderSize", function(v) return tonumber(v) or 1 end)
	add({ kind = "slider", label = "Border", min = 1, max = 4, step = 1, format = "%d px", search = "border thickness, border size",
		help = "In screen pixels; a thicker border grows outward, as a window's.", disabled = borderOff, get = get, set = set })
	get, set = field("borderColor", function(v) return v or "scheme" end)
	local colorSet = set
	add({ kind = "dropdown", label = "Border colour", search = "border colour, edge colour", disabled = borderOff,
		help = "The scheme's hairline (the accent with Accent border on), or a colour of its own (which turns Accent border off).",
		choices = function()
			local list = { { value = "scheme", label = "The scheme's" }, { value = "class", label = "Class colour" }, { value = "white", label = "White" },
				{ value = "black", label = "Black" }, { value = "gold", label = "Gold" }, { value = "silver", label = "Silver" } }
			local o = own()
			if o and o.ownColor then list[#list + 1] = { value = "own", label = "Polestar's border colour" } end
			return list
		end,
		-- A colour and the accent are rivals, as Polestar's ui.borderColor and ui.borderAccent.
		get = get, set = function(v) if v == "scheme" then v = false end local o = own(); if o and v then o.borderAccent = false end colorSet(v) end })
	get, set = field("borderAccent", function(v) return v and true or false end)
	local accentSet = set
	add({ kind = "toggle", label = "Accent border", search = "accent border, gold border", disabled = borderOff,
		help = "The border takes your accent colour. Picking a border colour turns this off.", get = get,
		set = function(v) local o = own(); if o and v then o.borderColor = false end accentSet(v) end })
	get, set = field("hairline", pct, 100)
	add({ kind = "slider", label = "Hairlines", min = 0, max = 300, step = 10, format = "%d%%", search = "hairline, border opacity, stronger lines",
		help = "How strongly the border shows, against its colour's own.", get = get, set = set })
	local shadowOff = function() local o = own(); return o and o.shadow == false end
	get, set = field("shadow", function(v) return v ~= false end)
	add({ kind = "toggle", label = "Window shadow", search = "shadow, drop shadow, depth", help = "The soft shadow round each of them.", get = get, set = set })
	get, set = field("shadowStrength", pct, 100)
	add({ kind = "slider", label = "Shadow strength", min = 0, max = 200, step = 5, format = "%d%%", search = "shadow strength, darker shadow",
		help = "How dark the shadow falls, against the skin's.", disabled = shadowOff, get = get, set = set })
	get, set = field("ground", pct, 100)
	add({ kind = "slider", label = "Background opacity", min = 0, max = 100, step = 5, format = "%d%%", search = "background opacity, ground, transparency",
		help = "The ground behind them.", get = get, set = set })
	for _, c in ipairs(controls) do lookControl[c] = true end
	return controls
end

-- The Icons tab's preview: two buttons of ours (plain Buttons: no action, no
-- events), a filled one and an empty one (its icon hidden, as the game hides
-- an empty slot's: Polestar's emblem), in the action bars' own paint
-- (ns.ButtonLook.paint), so it cannot drift from the bars. Polestar's band
-- (UI.Preview.Band, there once Polestar_Options draws the page) lays it out
-- again on every Theme.Refresh, which each look change runs: its ground is a
-- Polestar painter.
local SIZE, GAP = 45, 8 -- ActionButtonTemplate's size; the gap between the two
local function previewButton(parent, empty)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(SIZE, SIZE)
	b.icon = b:CreateTexture(nil, "BACKGROUND")
	b.icon:SetAllPoints(b)
	b.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
	b.icon:SetShown(not empty)
	b.HotKey = b:CreateFontString(nil, "OVERLAY")
	b.HotKey:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	b.HotKey:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -3)
	b.HotKey:SetText(empty and "2" or "1")
	return b
end

local function iconsPreview(host)
	local P, paint = Polestar.UI and Polestar.UI.Preview, ns.ButtonLook.paint
	if not (P and P.Band) then
		local f = CreateFrame("Frame", nil, host)
		local b, e = previewButton(f), previewButton(f, true)
		b:SetPoint("RIGHT", f, "CENTER", -GAP / 2, 0)
		e:SetPoint("LEFT", f, "CENTER", GAP / 2, 0)
		W.Painter(b, function() paint(b, true); paint(e, true) end)
		function f:Layout() return SIZE + 32 end
		return f
	end
	local f = P.Band(host)
	local b, e = previewButton(f), previewButton(f, true)
	f.Button, f.Empty = b, e
	function f:Content()
		paint(b, true)
		paint(e, true)
		local t = self:TrueScale()
		return (2 * SIZE + GAP) * t, SIZE * t, function(left, top, k)
			local g = t * k
			for i, x in ipairs({ b, e }) do
				x:SetScale(g)
				x:ClearAllPoints()
				x:SetPoint("TOPLEFT", self, "TOPLEFT", P.Snap(x, left / g + (i - 1) * (SIZE + GAP)), P.Snap(x, -top / g))
			end
		end
	end
	return f
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
	local windows, hud, blocked, names = {}, {}, {}, {}
	for _, key in ipairs(ns.order) do
		local by = ns.modules[key].blockedBy
		local list = by and blocked or tabOf(key) == HUD and hud or windows
		list[#list + 1] = moduleToggle(key)
		if by then names[#names + 1] = key end
	end
	-- Blocked toggles go first, side by side from the left column, under one wide note (Polestar's options API has no text row: a dimmed row with a disabled button says why). One shared reason: one note; else a note after each.
	local function note(key, text)
		return { kind = "button", wide = true, label = text, button = "Blocked", onClick = function() end,
			disabled = function() return true end, search = "/pui " .. key }
	end
	local head, same = {}, true
	for _, k in ipairs(names) do same = same and ns.modules[k].blockedBy == ns.modules[names[1]].blockedBy end
	if same and #names > 0 then
		for _, c in ipairs(blocked) do head[#head + 1] = c end
		local by = ns.modules[names[1]].blockedBy
		head[#head + 1] = note(names[1], #names > 1 and "Bags and Bank are off while " .. by .. " is loaded: its own bags and bank take their place." or blockedNote(by))
	else
		for i, c in ipairs(blocked) do head[#head + 1] = c; head[#head + 1] = note(names[i], blockedNote(ns.modules[names[i]].blockedBy)) end
	end
	for _, c in ipairs(windows) do head[#head + 1] = c end
	windows = head
	-- The page's subtitle (Polestar's registry keeps the first one given).
	local v = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version")
	register({ tab = WINDOWS, section = "Windows", controls = windows, subtitle = v and ("Version " .. v) or nil })
	register({ tab = WINDOWS, section = "Docking", controls = {
		{ kind = "toggle", label = "Dock windows", search = "dock, move, /pui dock",
			help = "On: the windows line up from the top left as the game's do. Off: drag each where you like.",
			get = function() return ns.Docked() end, set = function(v) ns.SetDocked(v ~= false) end },
	} })
	register({ tab = HUD, section = "HUD", controls = hud })
	-- The HUD's look, per group (ns.HUD: Edge, ShadowColor, GroundAlpha): Polestar's
	-- Frames settings, or with "Override" on the group's own, which start as
	-- Polestar's (H.Seed). Every change repaints (Theme.Refresh).
	for _, g in ipairs({ { "frames", "Frames look", "cast bars, the minimap, tooltips and (unless overridden on their own tabs) the unit frames, chat and the damage meter" },
		{ "plates", "Plates look", "nameplates and their cast bars" } }) do
		register({ tab = HUD, section = g[2], controls = lookControls(g[1], g[3]) })
		if g[1] == "plates" then register({ tab = HUD, section = "Nameplate cast bars", controls = plateCast() }) end
	end
	register({ tab = OWN_TAB.unitframes, section = "Unit frames", controls = {
		ufToggle("portrait", "3D portraits", "The unit's model in a square beside the bars."),
		ufToggle("powerText", "Power text", "The unit's power as a number, shown as the game's Status Text options show the health."),
		ufToggle("sparkle", "Sparkle", "Polestar's stars over the health bars, as over its windows' header band."),
		ufToggle("smooth", "Smooth bars", "Health and power glide to a new value instead of jumping."),
		ufToggle("trail", "Damage trail", "Health just lost stays red for a moment, then drains away."),
	} })
	register({ tab = OWN_TAB.chat, section = "Chat", controls = {
		{ kind = "toggle", label = "Fade chat when idle", search = "chat fade, chat background, tabs",
			help = "On: the chat's background, outline, tabs and side buttons fade back when the mouse leaves it. Off: they stay fully shown. Old messages still fade out as the game does them.",
			get = function() return PolestarUIDB.chatFade and true or false end,
			set = function(v) PolestarUIDB.chatFade = v or nil end },
		{ kind = "toggle", label = "Keep chat across sessions", search = "chat history",
			help = ns.CHAT_HISTORY_HELP,
			get = function() return not PolestarUICharDB.chatNoHistory end,
			set = function(v) PolestarUICharDB.chatNoHistory = v == false or nil end },
	} })
	-- Each element's own look, on its tab: off (the default), the Frames look.
	for _, e in ipairs(ELEMENTS) do
		register({ tab = e[2], section = e[2] .. " look", controls = lookControls(e[1], e[3], e) })
	end
	register({ tab = ICONS, section = "Icons look", preview = iconsPreview,
		controls = lookControls("icons", "action and bag buttons, the micro menu, buffs and the cooldown viewer's icons") })
end)

-- Opens our page on `key`'s own tab (chat, damagemeter, unitframes), else on
-- the tab holding its toggle (a window's "..." menu).
-- Polestar.UI is absent only where Polestar's UI is not loaded (the preview).
function ns.ShowSettings(key)
	local UI = Polestar.UI
	if not UI then return end
	-- The settings window sits on Polestar's layer: hidden with Polestar, it would open unseen (Polestar's own commands unhide first).
	if Polestar.Hidden() then Polestar.SetHidden(false) end
	UI.ShowOptions(KEY)
	local O = UI.Options
	if O and O.Select then O.Select(KEY, key and (OWN_TAB[key] or tabOf(key)) or nil) end
end
