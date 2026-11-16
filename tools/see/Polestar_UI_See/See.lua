-- Polestar: UI See (dev tool, not shipped): /puisee [note] (or its key binding)
-- marks a bug: the UI's state as text (frame under the mouse and its parents,
-- every mouse-enabled frame under the cursor, tooltips, our windows, stock
-- windows showing) plus a Screenshot(). Marks and a one-line event log are kept
-- in PolestarUISeeDB as plain strings (written on /reload or logout);
-- `npm run see` turns them into screenshots/game/digest.md (docs/see.md).
-- Reads only: no frame is written, hooked, shown or hidden; nothing protected.

local ADDON = ...
local ns = PolestarUI
local MAX_EVENTS, MAX_MARKS = 200, 10
local NAMEPLATE = { "nameplateShowAll", "nameplateShowEnemies", "nameplateShowFriends", "nameplateShowFriendlyNPCs",
	"nameplateMotion", "nameplateOverlapV", "nameplateOverlapH", "nameplateMaxDistance", "nameplateGlobalScale",
	"nameplateSelectedScale", "nameplateMinScale", "NamePlateHorizontalScale", "NamePlateVerticalScale" }
local STRATA = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4, DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }
local db, lastText, lastMark = nil, nil, 0
local ev = CreateFrame("Frame")

local function say(msg) print("|cff88ccffPUI see|r: " .. msg) end
local function secret(v) return issecretvalue and issecretvalue(v) end
local function s(v) if secret(v) then return "<secret>" end return tostring(v) end
local function n(v, fmt) if v == nil then return "-" end if secret(v) then return "?" end return (fmt or "%.0f"):format(v) end

-- One line per notable event: "<time()> text" (a repeat of the last line is dropped).
local function log(text)
	if not db or text == lastText then return end
	lastText = text
	local e = db.events
	e[#e + 1] = time() .. " " .. (text:gsub("[\r\n]+", " "))
	if #e > MAX_EVENTS then table.remove(e, 1) end
end

local function name(f)
	local ok, v = pcall(f.GetDebugName, f)
	v = ok and type(v) == "string" and not secret(v) and v or "?"
	return #v > 90 and "..." .. v:sub(-87) or v
end

local function describe(f)
	local w, h = f:GetSize()
	return ("%s [%s] %s/%s%s%s a=%s %sx%s @%s,%s"):format(name(f), s(f:GetObjectType()), s(f:GetFrameStrata()), n(f:GetFrameLevel()),
		f:IsMouseEnabled() and " mouse" or "", f:IsShown() and "" or " HIDDEN", n(f:GetAlpha(), "%.2f"), n(w), n(h), n(f:GetLeft()), n(f:GetBottom()))
end
-- A secret rect or flag (combat) fails the line, never the mark.
local function desc(f)
	local ok, d = pcall(describe, f)
	return ok and d or name(f) .. " (unreadable)"
end

local function snapshot()
	local out = {}
	local function L(text) out[#out + 1] = text end
	local function section(fn)
		local ok, err = pcall(fn)
		if not ok then L("(section failed: " .. s(err) .. ")") end
	end

	L(("combat=%s effScale=%.3f"):format(tostring(InCombatLockdown() and true or false), UIParent:GetEffectiveScale()))

	section(function() -- the frame under the mouse, then its parents
		local f = GetMouseFoci and GetMouseFoci()[1]
		if not f and GetMouseFocus then f = GetMouseFocus() end
		if not f then return L("focus: none") end
		local depth = 0
		while f and depth < 8 do
			local lead = depth == 0 and "focus: " or "  < "
			if f:IsForbidden() then L(lead .. "(forbidden)"); break end
			if f == UIParent or f == WorldFrame then L(lead .. name(f)); break end
			L(lead .. desc(f))
			f, depth = f:GetParent(), depth + 1
		end
	end)

	section(function() -- every visible mouse-enabled frame under the cursor, top first (what can eat the click)
		if not EnumerateFrames then return end
		local hits = {}
		local function check(f)
			if f ~= UIParent and f ~= WorldFrame and not f:IsForbidden() and f:IsVisible() and f:IsMouseEnabled() and f:IsMouseOver() then
				hits[#hits + 1] = { (STRATA[f:GetFrameStrata()] or 0) * 100000 + f:GetFrameLevel(), f }
			end
		end
		local f = EnumerateFrames()
		while f do
			pcall(check, f)
			f = EnumerateFrames(f)
		end
		table.sort(hits, function(a, b) return a[1] > b[1] end)
		L("mouse-enabled under cursor (top first): " .. #hits)
		for i = 1, math.min(#hits, 15) do
			local h = hits[i][2]
			L(("  %s/%s %s"):format(s(h:GetFrameStrata()), n(h:GetFrameLevel()), name(h)))
		end
	end)

	section(function()
		for _, nm in ipairs({ "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "EmbeddedItemTooltip" }) do
			local tt = _G[nm]
			if tt and tt:IsVisible() then
				local owner = tt.GetOwner and tt:GetOwner()
				local fs = _G[nm .. "TextLeft1"]
				L(("tooltip: owner=%s text=\"%s\" %s"):format(owner and name(owner) or "none", s(fs and fs:GetText()), desc(tt)))
			end
		end
	end)

	section(function() -- our windows showing, modules off, stock windows on screen (!! = while ours is on)
		local off, ours, stock = {}, {}, {}
		for _, key in ipairs(ns.order) do
			local m = ns.modules[key]
			local on = ns.Enabled(key)
			if not on then off[#off + 1] = key elseif not m.psStarted then off[#off + 1] = key .. "(not started)" end
			if m.psFrame and m.psFrame:IsShown() then ours[#ours + 1] = key end
			local ok, fr = pcall(function() return m.stock and m.stock() end)
			if ok and type(fr) == "table" and fr.IsVisible and fr:IsVisible() then
				stock[#stock + 1] = key .. "=" .. name(fr) .. (fr:IsMouseEnabled() and "(mouse)" or "") .. (on and " !!" or "")
			end
		end
		L("ours shown: " .. (#ours > 0 and table.concat(ours, ", ") or "none"))
		L("stock shown: " .. (#stock > 0 and table.concat(stock, ", ") or "none"))
		L("modules off: " .. (#off > 0 and table.concat(off, ", ") or "none"))
	end)
	return table.concat(out, "\n")
end

local function info()
	local w, h = GetPhysicalScreenSize()
	local T = Polestar.Theme
	local meta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
	local v, np = {}, {}
	for _, a in ipairs({ "Polestar_UI", "Polestar", "!BugGrabber", "BugSack", "Baganator" }) do
		if loaded(a) then v[#v + 1] = a .. "=" .. s(meta(a, "Version")) end
	end
	for _, c in ipairs(NAMEPLATE) do
		local ok, val = pcall(GetCVar, c)
		if ok and val ~= nil then np[#np + 1] = c .. "=" .. s(val) end
	end
	local version, build = GetBuildInfo()
	return ("build=%s.%s res=%dx%d uiScale=%s useUiScale=%s effScale=%.3f scheme=%s skin=%s\naddons: %s\nnameplates: %s"):format(
		s(version), s(build), w, h, s(GetCVar("uiScale")), s(GetCVar("useUiScale")), UIParent:GetEffectiveScale(),
		s(T.SchemeKey and T.SchemeKey()), s(T.SkinKey and T.SkinKey()), table.concat(v, " "), table.concat(np, " "))
end

-- A mark: "<time()>|<cursor x 0..1>|<cursor y 0..1 from the top>|<note>\n<state>". At most one per 2 s, so each
-- screenshot's file stamp matches one mark.
function PolestarUISee_Mark(note)
	if not db then return end
	local now = time()
	if now < lastMark + 2 then return say("one mark per 2 s.") end
	lastMark = now
	note = type(note) == "string" and (note:gsub("[|%s]+", " ")):match("^%s*(.-)%s*$") or ""
	local ok, body = pcall(snapshot)
	local fx, fy = 0.5, 0.5
	pcall(function()
		local x, y = GetCursorPosition()
		local k = UIParent:GetEffectiveScale()
		fx, fy = x / k / UIParent:GetWidth(), 1 - y / k / UIParent:GetHeight()
	end)
	local marks = db.marks
	marks[#marks + 1] = ("%d|%.4f|%.4f|%s\n%s"):format(now, fx, fy, note, ok and body or "snapshot failed: " .. s(body))
	while #marks > MAX_MARKS do table.remove(marks, 1) end
	log("mark " .. note)
	Screenshot()
	say("marked" .. (note ~= "" and " \"" .. note .. "\"" or "") .. ". Type /reload to hand it over (npm run see:watch writes the digest).")
end

SLASH_POLESTARUISEE1 = "/puisee"
SlashCmdList.POLESTARUISEE = PolestarUISee_Mark
BINDING_NAME_POLESTARUISEE_MARK = "Polestar: UI See: mark a bug"

ev:SetScript("OnEvent", function(_, event, a, b)
	if event == "ADDON_LOADED" then
		if a ~= ADDON then return end
		PolestarUISeeDB = type(PolestarUISeeDB) == "table" and PolestarUISeeDB or {}
		db = PolestarUISeeDB
		db.events, db.marks = db.events or {}, db.marks or {}
		-- BugGrabber's session: tools/see.js lists !BugGrabber.lua's errors of this session.
		db.session = BugGrabber and BugGrabber.GetSessionId and BugGrabber:GetSessionId() or 0
		log("load")
	elseif not db then return
	elseif event == "PLAYER_ENTERING_WORLD" then
		local ok, text = pcall(info)
		db.info = ok and text or "info failed: " .. s(text)
		log("enter world")
	elseif event == "PLAYER_REGEN_DISABLED" then log("combat on")
	elseif event == "PLAYER_REGEN_ENABLED" then log("combat off")
	elseif event == "LUA_WARNING" then log("warning " .. s(b):sub(1, 160))
	else log(event .. " " .. s(a) .. " " .. s(b)) -- ADDON_ACTION_BLOCKED / _FORBIDDEN: addon, function
	end
end)
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "ADDON_ACTION_BLOCKED",
	"ADDON_ACTION_FORBIDDEN", "LUA_WARNING" }) do
	pcall(ev.RegisterEvent, ev, e)
end

-- Errors as BugGrabber takes them (the stacks stay in its own saved file).
if EventRegistry and BugGrabber and BugGrabber.GetErrorByID then
	EventRegistry:RegisterCallback("BugGrabber.BugGrabbed", function(_, id)
		local ok, e = pcall(BugGrabber.GetErrorByID, BugGrabber, id)
		log("error " .. (ok and type(e) == "table" and s(e.message) or "?"):sub(1, 160))
	end, ev)
end
-- Post-hooks on our own namespace: which window was asked for, which module switched.
hooksecurefunc(ns, "Show", function(key) log("show " .. s(key)) end)
hooksecurefunc(ns, "Switch", function(key, on) log("switch " .. s(key) .. " " .. s(on)) end)
