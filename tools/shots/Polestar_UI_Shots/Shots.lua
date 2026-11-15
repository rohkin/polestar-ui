-- Polestar: UI Shots (dev tool, not shipped): /puishots opens every Polestar: UI
-- window and page in turn and takes a screenshot of each; /puishots <key> | hud.
-- Each shot is saved to PolestarUIShotsDB.shots as "time|label" (written on
-- /reload or logout); `npm run shots` copies the images into screenshots/game.
-- Only public module calls (m.Show, ns.Enabled, m.psFrame:Hide): no stock frame,
-- no protected call, nothing hidden.

local ns = PolestarUI
local DELAY, TIMEOUT = 0.6, 5

-- The pages each window opens on its own, as m.Show's argument (a function
-- returns the list, or steps {label, fn} where Show takes no page).
local PLAN = {
	{ "character", { "PaperDollFrame", "ReputationFrame", "SkillsFrame", "PVPRankFrame", "TokenFrame", "StatisticsFrame" } },
	{ "spellbook", function()
		local t = {}
		for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local info = C_SpellBook.GetSpellBookSkillLineInfo(i)
			if info and not info.shouldHide then t[#t + 1] = "line" .. i end
		end
		local pet = C_SpellBook.HasPetSpells()
		if pet and pet > 0 then t[#t + 1] = "pet" end
		return t
	end },
	{ "talents", function()
		local t = { 1 }
		if GetNumSpecGroups and GetNumSpecGroups() > 1 then t[2] = 2 end
		return t
	end },
	{ "professions", { false } },
	{ "legacy", { "track", "challenges", "tree" } },
	{ "map", { { "map", function(m) m.Show() end }, { "quests", function(m) m.ToggleQuests() end } } },
	{ "social", { "friends", "allies", "requests", "ignored", "raid" } },
	{ "guild", { "roster", "benefits", "info", "news", "log" } },
	{ "macros", { "general", "character" } },
	{ "collections", { "mounts", "pets", "toys", "appearances" } },
	{ "groupfinder", { "listing", "browse", "who" } },
	{ "bags", { false } },
}
local NEEDS = { -- open only from an NPC, a target or an open trade skill
	bank = "a banker", mail = "a mailbox", merchant = "a vendor", gossip = "an NPC", trainer = "a trainer",
	auction = "an auctioneer", questdialog = "a quest giver", loot = "loot", inspect = "a target to inspect",
	crafting = "an open trade skill",
}

local queue, i, waiting, oldFormat = {}, 0, nil, nil
local ev = CreateFrame("Frame")

local function say(msg) print("|cff88ccffPUI shots|r: " .. msg) end

local function closeAll()
	for _, p in ipairs(PLAN) do
		local m = ns.modules[p[1]]
		if m and m.psFrame and m.psFrame:IsShown() then m.psFrame:Hide() end
	end
end

-- The list reaches disk only on /reload. ReloadUI (C_UI.Reload) from addon code
-- does nothing in this client, even on a click, so the modal's Reload button is
-- covered by a secure button running the /reload macro (as the micro doors do).
local reload
local function offerReload(n)
	if InCombatLockdown() then return end -- a secure button can't be placed; the chat line says /reload
	local d = Polestar.Widgets.Modal({ title = "Shots done", text = n .. " screenshots taken. Reload to save the list?", action = "Reload" })
	if not reload then
		reload = CreateFrame("Button", "PolestarUIShotsReload", UIParent, "SecureActionButtonTemplate")
		reload:RegisterForClicks("LeftButtonUp")
		reload:SetAttribute("useOnKeyDown", false)
		reload:SetAttribute("type", "macro")
		reload:SetAttribute("macrotext", "/reload")
		reload:SetFrameStrata("TOOLTIP") -- above the modal: a level higher in its strata still lost the mouse
		reload:Hide()
		reload:RegisterEvent("PLAYER_REGEN_ENABLED")
		reload:SetScript("OnEvent", function(self) if not d:IsShown() then self:Hide() end end)
		d:HookScript("OnHide", function() if not InCombatLockdown() then reload:Hide() end end)
	end
	-- Absolute coordinates, not anchored to the modal (anchoring would make it restricted).
	C_Timer.After(0, function()
		local a = d.Box.Action
		if InCombatLockdown() or not d:IsShown() or not a:GetLeft() then return end
		local k = a:GetEffectiveScale() / UIParent:GetEffectiveScale()
		reload:ClearAllPoints()
		reload:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", a:GetLeft() * k, a:GetBottom() * k)
		reload:SetSize(a:GetWidth() * k, a:GetHeight() * k)
		reload:Show()
	end)
end

local function finish(msg)
	queue, waiting = {}, nil
	ev:UnregisterAllEvents()
	closeAll()
	if oldFormat then pcall(SetCVar, "screenshotFormat", oldFormat); oldFormat = nil end
	local n = #PolestarUIShotsDB.shots
	say(msg .. " " .. n .. " shots listed; click Reload or type /reload (or log out) to write the list, then run `npm run shots`.")
	if n > 0 then offerReload(n) end
end

local function step()
	i = i + 1
	local s = queue[i]
	if not s then return finish("Done.") end
	if InCombatLockdown() then return finish("Stopped: combat.") end
	closeAll()
	local ok, err = pcall(s.open)
	if not ok then say(s.label .. " failed to open: " .. tostring(err)); return step() end
	C_Timer.After(DELAY, function()
		if not queue[i] then return end
		waiting = s
		Screenshot()
		local mine = i
		C_Timer.After(TIMEOUT, function()
			if waiting == s and i == mine then waiting = nil; say(s.label .. ": no screenshot event, moving on."); step() end
		end)
	end)
end

ev:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_DISABLED" then return finish("Stopped: combat.") end
	local s = waiting
	if not s then return end
	waiting = nil
	if event == "SCREENSHOT_SUCCEEDED" then
		local t = PolestarUIShotsDB.shots
		t[#t + 1] = time() .. "|" .. s.label -- one string per shot: tools/shots.js reads it with a regex
	else
		say(s.label .. ": screenshot failed.")
	end
	step()
end)

local function add(label, open) queue[#queue + 1] = { label = label, open = open } end

local function addModule(key, pages)
	local m = ns.modules[key]
	if type(pages) == "function" then pages = pages() end
	for _, pg in ipairs(pages) do
		if type(pg) == "table" then
			add(key .. "-" .. pg[1], function() pg[2](m) end)
		elseif pg == false then
			add(key, function() m.Show() end)
		else
			add(key .. "-" .. tostring(pg), function() m.Show(pg) end)
		end
	end
end

local function usable(key)
	local m = ns.modules[key]
	if not m then return "not loaded" end
	if not ns.Enabled(key) or not m.psStarted then return "off (/pui " .. key .. " on)" end
end

local function run(arg)
	arg = (arg or ""):lower():match("^%s*(.-)%s*$")
	if InCombatLockdown() then return say("not in combat.") end
	if waiting or queue[i] then return say("a run is going.") end
	queue, i = {}, 0
	local planned, skipped = {}, {}
	local function skip(key, why) skipped[#skipped + 1] = key .. ": " .. why; say("skipped " .. key .. ": " .. why) end
	for _, p in ipairs(PLAN) do
		planned[p[1]] = true
		if arg == "" or arg == p[1] then
			local why = usable(p[1])
			if why then skip(p[1], why) else addModule(p[1], p[2]) end
		end
	end
	if arg ~= "" and arg ~= "hud" and not planned[arg] then
		return say(arg .. (NEEDS[arg] and " needs " .. NEEDS[arg] .. "; open it in game and press Print Screen." or " has no window of its own; see /puishots hud."))
	end
	if arg == "" then
		for _, key in ipairs(ns.order) do
			if not planned[key] then skip(key, NEEDS[key] and "needs " .. NEEDS[key] or "no window (in the HUD shot)") end
		end
	end
	if arg == "" or arg == "hud" then add("hud", function() end) end -- closeAll ran: the plain HUD
	if #queue == 0 then return say("nothing to shoot.") end

	local T = Polestar.Theme
	local w, h = GetPhysicalScreenSize()
	PolestarUIShotsDB = {
		run = date("%Y%m%d-%H%M%S"), -- the run's id: tools/shots.js --watch skips runs it has done
		info = ("res=%dx%d uiScale=%s useUiScale=%s effScale=%.3f scheme=%s skin=%s"):format(w, h, tostring(GetCVar("uiScale")),
			tostring(GetCVar("useUiScale")), UIParent:GetEffectiveScale(), tostring(T.SchemeKey and T.SchemeKey()), tostring(T.SkinKey and T.SkinKey())),
		skipped = table.concat(skipped, "; "),
		shots = {},
	}
	local ok, cur = pcall(GetCVar, "screenshotFormat")
	if ok and cur and cur ~= "png" and pcall(SetCVar, "screenshotFormat", "png") then oldFormat = cur end
	ev:RegisterEvent("SCREENSHOT_SUCCEEDED")
	ev:RegisterEvent("SCREENSHOT_FAILED")
	ev:RegisterEvent("PLAYER_REGEN_DISABLED")
	say(#queue .. " shots; don't touch the mouse or keyboard.")
	step()
end

SLASH_POLESTARUISHOTS1 = "/puishots"
SlashCmdList.POLESTARUISHOTS = run

-- A minimap button: left-click the full run, right-click the HUD alone. On the
-- map's bottom-left corner, outside the map and above its pins; its
-- PolestarUI name keeps the Minimap module from moving it into its addons flyout.
local b = CreateFrame("Button", "PolestarUIShotsButton", Minimap)
b:SetSize(18, 18)
b:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -4)
b:SetFrameStrata("HIGH")
b:SetFrameLevel(100)
b:SetNormalTexture("Interface/Icons/INV_Misc_Spyglass_02")
b:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")
b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
b:SetScript("OnClick", function(_, button) run(button == "RightButton" and "hud" or "") end)
b:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText("Polestar: UI shots")
	GameTooltip:AddLine("Left-click: open every Polestar: UI window and page in turn and screenshot each, then the plain HUD (/puishots).", 1, 1, 1, true)
	GameTooltip:AddLine("Right-click: screenshot just the HUD (/puishots hud).", 1, 1, 1, true)
	GameTooltip:Show()
end)
b:SetScript("OnLeave", function() GameTooltip:Hide() end)
