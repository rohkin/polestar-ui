-- Talents Forever (TalentsForeverBook) in our Talents (docs/addons.md): a
-- footer button to its planner, and its next planned point ringed, as it rings
-- it on the stock window (its UI.RefreshOverlay, its "Show plan on the game's
-- talents" setting). Its code runs in pcall. Never its Apply.
-- A no-op without the addon.

local ADDON, ns = ...
local W = Polestar.Widgets

ns.AfterLogin(function()
local TF = TalentsForeverBook
local talents = ns.modules.talents
if not (type(TF) == "table" and TF.Toggle and talents) then return end

-- -> the node ID of the plan's next point not yet learnt, or nil.
local function nextNode()
	local s = TF.db and TF.db.settings
	local p = TF.plan
	if not (s and s.overlay and p and TF.NextUp) or p.cls ~= select(2, UnitClass("player")) then return end
	for _, e in ipairs(TF.NextUp(p)) do
		if not e.done then
			-- The game's node first (it follows hotfixed nodes), the addon's data only while the game has not answered.
			local G = TF.Game
			local n = G and G.Node and G.Node(e.ti, e.i)
			if n then return n.id end
			if G and G.live then return end
			local D = TalentsForeverBookData
			local t = D and D.classes[p.cls].trees[e.ti].talents[e.i]
			return t and t.node
		end
	end
end

local function paintNext(f, nodes)
	local ring = f.psNext
	if not ring then
		-- A pulsing edge in Polestar's gold just outside the node.
		ring = CreateFrame("Frame", nil, f.Body)
		W.Painter(ring, function(e) local r, g, b = Polestar.Theme.Color("todo"); Polestar.Theme.Border(e, r, g, b, 1, "OVERLAY", 2) end)
		local pulse = ring:CreateAnimationGroup()
		pulse:SetLooping("BOUNCE")
		local a = pulse:CreateAnimation("Alpha")
		a:SetFromAlpha(1)
		a:SetToAlpha(0.3)
		a:SetDuration(0.6)
		ring:SetScript("OnShow", function() pulse:Play() end)
		ring:SetScript("OnHide", function() pulse:Stop() end)
		f.psNext = ring
	end
	local ok, id = pcall(nextNode)
	local on
	for _, b in ipairs(id and ok and nodes or {}) do
		if b:IsShown() and b.psNode == id then on = b end
	end
	ring:SetShown(on ~= nil)
	ring.psNode = on and id
	if not on then return end
	ring:ClearAllPoints()
	ring:SetPoint("TOPLEFT", on, "TOPLEFT", -4, 4)
	ring:SetPoint("BOTTOMRIGHT", on, "BOTTOMRIGHT", 4, -4)
	ring:SetFrameLevel(on:GetFrameLevel() + 4)
end

table.insert(talents.extras, {
	button = { label = "Talents Forever", onClick = function() pcall(TF.Toggle) end,
		tip = "Talents Forever", tipLines = { "Open its talent planner: your plan, path and builds." } },
	paint = paintNext,
})

if TF.On then
	local function redraw()
		local f = PolestarUITalents
		if f and f:IsShown() and not InCombatLockdown() then talents.Show() end
	end
	pcall(TF.On, "PLAN_CHANGED", redraw)
	pcall(TF.On, "GAME_CHANGED", redraw)
end
end)
