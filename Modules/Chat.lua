-- Chat (docs/DESIGN.md, "Chat"): the game's own chat windows in Polestar's
-- look, restyled in place, never replaced: every addon that writes into them
-- (AddMessage, message filters, chat mods) still does, and the edit box,
-- which runs secure slash commands, is only drawn over. Only the art changes
-- (docs/CLIENT.md, rule 15): the stock border pieces hidden, the stock ground
-- emptied (SetTexture(nil)) but left to the game, which keeps writing the
-- player's opacity and the mouse-over fade into its alpha; our ground and
-- hairline copy that alpha each frame. The tabs' and edit box's art faded
-- with SetAlpha; textures of ours added, kept in a weak table by frame. No
-- key is written on a stock frame, nothing is moved, sized or reparented,
-- and fonts stay the player's. Switched off, all of it is the game's again
-- at once.

local ADDON, ns = ...
local Theme = Polestar.Theme

-- FloatingBorderedFrame's border pieces (FloatingChatFrame.xml), on a chat
-- window and on its button frame; its Background is the ground.
local PIECES = { "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture", "LeftTexture", "RightTexture", "BottomTexture", "TopTexture" }
local GROUND = "Interface\\ChatFrame\\ChatFrameBackground"
-- ChatTabArtTemplate's art (its glow, the new-message flash, stays the game's).
local TAB = { "Left", "Middle", "Right", "ActiveLeft", "ActiveMiddle", "ActiveRight", "HighlightLeft", "HighlightMiddle", "HighlightRight" }
-- ChatFrameEditBoxTemplate's art, by global name after the edit box's.
local INPUT = { "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }
local EDGES = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }

local looks = setmetatable({}, { __mode = "k" }) -- stock frame -> its textures of ours
local M = { noun = "chat" }
local driver

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

-- Four hairlines round region `r`, on frame `f`.
local function hairline(f, r)
	local e = {}
	for i, p in ipairs(EDGES) do
		local t = tex(f, "BORDER", 7)
		t:SetPoint(p[1], r, p[1], 0, 0)
		t:SetPoint(p[2], r, p[2], 0, 0)
		e[i] = t
	end
	return e
end

local function paintLine(e, on, r, g, b, a)
	local px = Theme.Pixel(e[1]:GetParent())
	for i, t in ipairs(e) do
		t:SetShown(on)
		t:SetVertexColor(r, g, b, a)
		if i <= 2 then t:SetHeight(px) else t:SetWidth(px) end
	end
end

-- A frame never restyled has nothing to give back.
local function look(f, make)
	if not f then return end
	if not looks[f] and ns.Enabled("chat") then looks[f] = make(f) end
	return looks[f]
end

-- The ground and hairline round a chat window or its button frame: Polestar's
-- window ground (bg at the Background opacity setting) times the alpha the
-- game gives its own ground (the player's chat opacity, the mouse-over fade).
local function panel(f)
	local l = look(f, function()
		local l = { bg = f.Background, fill = tex(f, "BACKGROUND", -8) }
		l.fill:SetAllPoints(l.bg)
		l.edges = hairline(f, l.bg)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	l.bg:SetTexture(not on and GROUND or nil)
	local name = f:GetName()
	for _, k in ipairs(PIECES) do
		local p = name and _G[name .. k]
		if p then p:SetShown(not on) end
	end
	local r, g, b = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, b, Theme.GroundAlpha())
	l.fill:SetShown(on)
	paintLine(l.edges, on, Theme.Color("border"))
end

-- A tab as Polestar's panel (ground and hairline) under its label, the
-- accent bar when selected, the hover wash. Its alpha stays the game's.
local function tab(t)
	local l = look(t, function()
		local l = { fill = tex(t, "BACKGROUND", -8), bar = tex(t, "ARTWORK"), hover = tex(t, "HIGHLIGHT") }
		-- The stock art's visible part: the bottom 22 of the tab, the label centred in it.
		l.fill:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 0, 0)
		l.fill:SetPoint("TOPRIGHT", t, "TOPRIGHT", 0, -10)
		l.edges = hairline(t, l.fill)
		l.bar:SetPoint("BOTTOMLEFT", l.fill, "BOTTOMLEFT", 0, 0)
		l.bar:SetPoint("BOTTOMRIGHT", l.fill, "BOTTOMRIGHT", 0, 0)
		l.bar:SetHeight(2)
		l.hover:SetAllPoints(l.fill)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	for _, k in ipairs(TAB) do t[k]:SetAlpha(on and 0 or 1) end
	l.fill:SetVertexColor(Theme.Color("panel"))
	l.fill:SetShown(on)
	paintLine(l.edges, on, Theme.Color("border"))
	l.bar:SetVertexColor(Theme.Accent())
	l.bar:SetShown(on and t.ActiveMiddle:IsShown())
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.hover:SetShown(on)
end

-- The edit box as Polestar's input: the shade ground, the hairline, the
-- accent while typing (the driver follows the focus).
local function paintFocus(e, l)
	if e:HasFocus() then
		local r, g, b = Theme.Accent()
		paintLine(l.edges, true, r, g, b, 0.8)
	else
		paintLine(l.edges, true, Theme.Color("border"))
	end
	l.focus = e:HasFocus()
end

local function input(e)
	local l = look(e, function()
		local l = { fill = tex(e, "BACKGROUND", -8) }
		-- The stock art's visible box, inside the 32 high edit box.
		l.fill:SetPoint("TOPLEFT", e, "TOPLEFT", 3, -4)
		l.fill:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -1, 4)
		l.edges = hairline(e, l.fill)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	local name = e:GetName()
	for _, k in ipairs(INPUT) do
		local p = name and _G[name .. k]
		if p then p:SetAlpha(on and 0 or 1) end
	end
	local r, g, b = Theme.Color("shade")
	l.fill:SetVertexColor(r, g, b, 0.35)
	l.fill:SetShown(on)
	if on then paintFocus(e, l) else paintLine(l.edges, false, 0, 0, 0, 0) end
end

-- The combat log's filter strip (Blizzard_CombatLog, loaded on demand): its
-- black band faded, a divider under it; the window's ground shows through.
local function strip()
	local f = _G.CombatLogQuickButtonFrame_Custom
	local l = look(f, function()
		local l = { line = tex(f, "BORDER", 7) }
		l.line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		l.line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	local band = _G.CombatLogQuickButtonFrame_CustomTexture
	if band then band:SetAlpha(on and 0 or 1) end
	l.line:SetVertexColor(Theme.Color("divider"))
	l.line:SetHeight(Theme.Pixel(f))
	l.line:SetShown(on)
end

function M.Apply()
	for _, name in ipairs(CHAT_FRAMES) do
		local f = _G[name]
		if f then
			panel(f)
			panel(f.buttonFrame)
			tab(_G[name .. "Tab"])
			input(f.editBox)
		end
	end
	strip()
	driver:SetShown(ns.Enabled("chat"))
end

function M.Enable()
	-- Ours copies the alpha the game writes into its ground (FCF_SetWindowAlpha,
	-- FCF_FadeInChatFrame's fades), and follows the edit box's focus.
	driver = CreateFrame("Frame", nil, UIParent)
	driver:SetScript("OnUpdate", function()
		for f, l in pairs(looks) do
			if l.bg then
				local a = l.bg:GetAlpha()
				if a ~= l.alpha then
					l.alpha = a
					l.fill:SetAlpha(a)
					for _, t in ipairs(l.edges) do t:SetAlpha(a) end
				end
			elseif l.focus ~= nil and l.focus ~= f:HasFocus() and f:IsVisible() then
				paintFocus(f, l)
			end
		end
	end)
	-- A new whisper window (a new frame the first time), a tab selected.
	hooksecurefunc("FCF_OpenTemporaryWindow", function() if ns.Enabled("chat") then M.Apply() end end)
	hooksecurefunc("FCFTab_UpdateColors", function(t, selected)
		local l = looks[t]
		if l and ns.Enabled("chat") then l.bar:SetShown(selected and true or false) end
	end)
	Polestar.RegisterEvent("ADDON_LOADED", function(_, name)
		if name == "Blizzard_CombatLog" and ns.Enabled("chat") then strip() end
	end)
	Theme.OnChanged(function() if ns.Enabled("chat") then M.Apply() end end)
	M.Apply()
end

ns.Module("chat", M)
