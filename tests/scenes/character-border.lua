--@ title: Character: the stats drawer on a 4 px accent border
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- Window and drawer read as one window at every border size, live: one outer border (the top and bottom run on from the window's into the drawer's, no overlap), none at the seam but a 1 px divider, one shadow round both; the dock counts the drawer. Put away, the window's right border is back.
Polestar.Set("ui.borderAccent", true)
Polestar.Set("ui.borderSize", 4)
PolestarUI.Show("character")
local f, d = PolestarUICharacter, PolestarUICharacterStats
local probe = CreateFrame("Frame", nil, UIParent)
probe:SetSize(100, 100)
probe:Hide()
PolestarUI.Dock(probe)
-- The stub lays nothing out: x of region `t`'s `side` (LEFT or RIGHT) off `frame`'s, along its anchors.
local function sideX(t, frame, side)
	local x = 0
	while t ~= frame do
		local nxt
		for i = 1, t:GetNumPoints() do
			local p, rel, _, ox = t:GetPoint(i)
			if not nxt and p:find(side) then x, nxt = x + ox, rel end
		end
		assert(nxt, "no " .. side .. " anchor")
		t = nxt
	end
	return x
end
local function point(r, name)
	for i = 1, r:GetNumPoints() do
		local p, rel, rp, x, y = r:GetPoint(i)
		if p == name then return rel, rp, x, y end
	end
end
local function shown(t) return t:IsShown() end
local function check(n)
	local rel, rp, dx, top = point(d, "TOPLEFT")
	assert(rel == f and rp == "TOPRIGHT" and dx == 0 and top == 0 and select(4, point(d, "BOTTOMLEFT")) == 0, "drawer not flush and level")
	local wb, rb = f.psBorder, d.psRim.psBorder
	assert(f.psBorderSize == n and d.psRim.psBorderSize == n, "border not " .. n .. " px")
	-- No border at the seam: the window's right one, the drawer's own and its rim's left one gone.
	assert(not shown(wb[4]) and not shown(rb[3]), "a border at the seam at " .. n .. " px")
	assert(not (d.psBorder and shown(d.psBorder[1])), "the drawer draws its own border")
	assert(shown(d.psDivider) and d.psDivider:GetWidth() == 1, "no 1 px divider at the seam")
	-- The top and bottom go on where the window's end, at its height, the right one round the drawer.
	for i = 1, 2 do
		local wEnd = sideX(wb[i], f, "RIGHT")
		local rStart = dx + sideX(rb[i], d, "LEFT")
		assert(shown(wb[i]) and shown(rb[i]) and wEnd == rStart and wb[i]:GetHeight() == rb[i]:GetHeight(),
			"outer edge " .. i .. " broken at " .. n .. " px: the window's ends at " .. wEnd .. ", the drawer's starts at " .. rStart)
	end
	assert(shown(rb[4]), "no right border round the drawer")
	-- One shadow round both.
	assert(point(f.psShadow, "BOTTOMRIGHT") == d and not (d.psShadow and shown(d.psShadow)), "two shadows")
	local fe = f.psSkin.edge
	assert(not fe or not fe[5]:IsShown(), "the window's contact line at the seam")
	probe:Show()
	local fx, px = select(3, point(f, "TOPLEFT")), select(3, point(probe, "TOPLEFT"))
	-- Offsets in each frame's own units (the windows draw at the Menu scale's base).
	local s = f:GetScale()
	assert(math.abs(px * probe:GetScale() - ((fx + f:GetWidth() + d:GetWidth()) * s + 32)) < 1e-6, "the dock counts the drawer wrong at " .. n .. " px")
	probe:Hide()
end
check(4)
Polestar.Set("ui.borderSize", 1)
check(1)
Polestar.Set("ui.borderSize", 4)
check(4)
-- Put away: the window's own right border and shadow are back.
d:Hide()
assert(shown(f.psBorder[4]) and point(f.psShadow, "BOTTOMRIGHT") == f, "the window's right border or shadow not back")
d:Show()
check(4)
-- The border off: none round either, the divider stays.
Polestar.Set("ui.border", false)
assert(not shown(f.psBorder[1]) and not shown(d.psRim.psBorder[1]) and not shown(d.psRim.psBorder[4]) and shown(d.psDivider), "border off: a border left")
Polestar.Set("ui.border", true)
check(4)
