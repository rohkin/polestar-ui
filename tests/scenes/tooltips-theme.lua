--@ title: Tooltips: theme change
--@ roots: GameTooltip
-- Changing the scheme repaints the shown tooltip's ground and hairline, and the next tooltip uses them too.
PolestarUI.Switch("tooltips", true)
preview.enableTooltips()
local t = GameTooltip
local o = CreateFrame("Frame", nil, UIParent)
o:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -60)
o:SetSize(1, 1)
t:SetOwner(o, "ANCHOR_RIGHT")
t:SetHyperlink("|cffa335ee|Hitem:19019|h[Thunderfury]|h|r")
t:Show()
local T = Polestar.Theme
local function ours() -- our ground and first hairline
	local f, e
	for _, r in ipairs({ t.NineSlice:GetRegions() }) do
		if r.GetTexture and tostring(r:GetTexture()):find("Polestar") then if not f then f = r else e = e or r end end
	end
	return f, e
end
local function near(a, b) return math.abs(a - b) < 0.002 end
local function check(tag)
	local f, e = ours()
	local br, bg, bb = T.Color("bg")
	local gr, gg, gb = f:GetVertexColor()
	local want = { T.Contrast({ 1, 1, 1 }, { br, bg, bb }) >= 7 and br or T.TIP_GROUND[1], 0, 0 }
	assert(near(gr, want[1]), tag .. ": ground not the scheme's")
	local r, g, b = T.Color("border")
	local er, eg, eb = e:GetVertexColor()
	assert(near(er, r) and near(eg, g) and near(eb, b), tag .. ": hairline not the border")
end
check("first")
local f1 = ours()
local before = { f1:GetVertexColor() }
Polestar.Set("ui.scheme", "graphite")
local after = { f1:GetVertexColor() }
assert(before[1] ~= after[1] or before[2] ~= after[2] or before[3] ~= after[3], "ground did not follow the scheme live")
check("live")
t:Hide() t:SetOwner(o, "ANCHOR_RIGHT") t:SetHyperlink("|cffa335ee|Hitem:19019|h[Thunderfury]|h|r") t:Show()
check("next tooltip")
