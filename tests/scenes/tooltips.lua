--@ title: Tooltips
--@ roots: GameTooltip, ShoppingTooltip1
-- The game's tooltip restyled in place: its NineSlice's pieces faded under our ground and hairline, the health bar flat, the fonts Polestar's; another addon's hook still adds its line. A style reset (an embedded tooltip hides the art, the next shows it) keeps the look; switched off, the stock art and fonts are back at once, and on again. Beside it a comparison tooltip: its "Equipped" plate on our ground and hairline, the label in text; hidden and shown again (each comparison) it keeps the look, and switched off its atlas and gold label are back.
local s = stub.withShoppingTooltip()
PolestarUI.Switch("tooltips", true)
preview.enableTooltips()
local h = s.CompareHeader
local art = h:GetRegions()
local function plated() local ours = 0
for _, r in ipairs({ h:GetRegions() }) do if r ~= art and r:IsShown() and r.GetTexture and tostring(r:GetTexture()):find("Polestar") then ours = ours + 1 end end
local r, g, b = h.Label:GetTextColor()
local tr, tg, tb = Polestar.Theme.Color("text")
return art:GetAlpha() == 0 and ours == 5 and s.NineSlice.Center:GetAlpha() == 0 and r == tr and g == tg and b == tb end
local function compare() s:SetOwner(GameTooltip, "ANCHOR_NONE")
s:ClearAllPoints()
s:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 4, -24)
s:SetHyperlink("|cff0070dd|Hitem:2244|h[Krol Blade]|h|r")
h:Show()
h.Label:SetText("Equipped")
h:SetWidth(h.Label:GetStringWidth() + 30)
s:Show() end
local t, n = GameTooltip, GameTooltip.NineSlice
local stockFont = GameTooltipText:GetFont()
hooksecurefunc(t, "SetHyperlink", function(tip) tip:AddLine("Another addon's line", 0.5, 0.8, 1) end)
local o = CreateFrame("Frame", nil, UIParent)
o:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -60)
o:SetSize(1, 1)
local function show() t:SetOwner(o, "ANCHOR_RIGHT")
t:SetHyperlink("|cffa335ee|Hitem:19019|h[Thunderfury, Blessed Blade of the Windseeker]|h|r")
t:Show() end
local function styled() for _, k in ipairs({ "TopLeftCorner", "TopEdge", "RightEdge", "Center" }) do if n[k]:GetAlpha() ~= 0 then return false end end
local ours = 0
for _, r in ipairs({ n:GetRegions() }) do if r:IsShown() and r:GetAlpha() ~= 0 then ours = ours + 1 end end
return ours == 5 and t.StatusBar:GetStatusBarTexture():GetTexture():find("Polestar") and GameTooltipText:GetFont() == Polestar.Theme.FontSpec("body") end
show()
local found
for _, l in ipairs(t.lines) do if l == "Another addon's line" then found = true end end
assert(found, "the other addon's line is missing")
assert(styled(), "not restyled")
SharedTooltip_SetBackdropStyle(t, nil, true)
assert(not n:IsShown(), "embedded: the art shows")
SharedTooltip_SetBackdropStyle(t, nil)
assert(n:IsShown() and styled(), "not restyled after a reset")
PolestarUI.Switch("tooltips", false)
assert(n.Center:GetAlpha() == 1 and not styled() and GameTooltipText:GetFont() == stockFont and t.StatusBar:GetStatusBarTexture():GetTexture():find("BarFill"), "not the stock look when off")
PolestarUI.Switch("tooltips", true)
assert(styled(), "not restyled when on again")
show()
compare()
assert(plated(), "the plate is not restyled")
h:Hide()
SharedTooltip_SetBackdropStyle(s, nil)
compare()
assert(plated(), "the plate is not restyled on a re-show")
PolestarUI.Switch("tooltips", false)
local r, g, b = h.Label:GetTextColor()
assert(art:GetAlpha() == 1 and not plated() and r == 1 and g == 0.82 and b == 0, "not the stock plate when off")
PolestarUI.Switch("tooltips", true)
assert(plated(), "the plate not restyled when on again")
