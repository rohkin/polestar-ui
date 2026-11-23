-- ForeverQuestTint's marks on our quest log (docs/addons.md): the addon marks
-- the quests Forever added (any ID not in the original Classic list) in the
-- stock log; our log draws its own rows, so ours marks them the same way from
-- the addon's saved settings (ForeverQuestTintDB, its defaults where unset):
-- the glyph by the title, the objective colour, the teal wash on the details.
-- The list is our copy (Addons/ForeverQuestTintData.lua, npm run sync:fqt).
-- Its settings have no change signal: a change shows at our next repaint.
-- Settings, glyph and rules after ForeverQuestTint (xanastar, GPL-3).

local ADDON, ns = ...

ns.AfterLogin(function()
if not (C_AddOns.IsAddOnLoaded("ForeverQuestTint") and type(ForeverQuestTintDB) == "table" and ns.FQTData) then return end

local DEF = {
	showTint = true, tint = { 0.60, 0.90, 0.95 }, alpha = 1.0, topAlpha = 0, height = 0.6,
	marker = true, markerSymbol = "\226\136\158", markerAtStart = false, markerIcon = true,
	markerHeight = 8, markerOffset = 0, markerGap = 0, markerUseTint = true, markerColor = { 0.60, 0.90, 0.95 },
	objectiveTint = false, objectiveUseTint = true, objectiveColor = { 0.60, 0.90, 0.95 },
}
local function cfg(k)
	local v = ForeverQuestTintDB[k]
	if v == nil then return DEF[k] end
	return v
end
local function rgb(c) return c[1] or 0, c[2] or 0, c[3] or 0 end

-- As the addon's IsMarked: a valid ID not in the sorted original-Classic ranges.
function ns.FQTMarked(id)
	if type(id) ~= "number" or id <= 0 then return false end
	local R, lo, hi = ns.FQTData.ranges, 1, #ns.FQTData.ranges
	while lo <= hi do
		local mid = math.floor((lo + hi) / 2)
		local r = R[mid]
		if id < r[1] then hi = mid - 1 elseif id > r[2] then lo = mid + 1 else return false end
	end
	return true
end

local ICON = "Interface/AddOns/ForeverQuestTint/Media/Infinity.tga" -- its 64x64 art; the sign spans 1..63 x 12..51
local function glyph(size)
	if not cfg("marker") then return end
	local r, g, b = rgb(cfg("markerUseTint") and cfg("tint") or cfg("markerColor"))
	r, g, b = math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
	if cfg("markerIcon") then
		local h = cfg("markerHeight")
		local y = cfg("markerOffset") - 2
		if size then -- their height is for a 13 px title; scale it, and centre the sign on the text's middle (~0.3 em over the baseline)
			h = math.max(1, math.floor(h * size / 13 + 0.5))
			y = cfg("markerOffset") + math.floor(0.3 * size - h / 2 + 0.5)
		end
		local gap = cfg("markerAtStart") and -cfg("markerGap") or cfg("markerGap")
		return ("|T%s:%d:%d:%d:%d:64:64:1:63:12:51:%d:%d:%d|t"):format(ICON, h, math.floor(h * 62 / 39 + 0.5), gap, y, r, g, b)
	end
	local s = cfg("markerSymbol")
	if s ~= "" then return ("|cff%02x%02x%02x%s|r"):format(r, g, b, s) end
end

ns.QuestLogTint = function(id, size)
	if not ns.FQTMarked(id) then return end
	local t = { glyph = glyph(size), atStart = cfg("markerAtStart") and true or false }
	if cfg("objectiveTint") then t.objective = { rgb(cfg("objectiveUseTint") and cfg("tint") or cfg("objectiveColor")) } end
	if cfg("showLogo") then t.logo = "Interface/AddOns/ForeverQuestTint/Media/ForeverLogo.tga" end
	if cfg("showTint") then t.gradient = { rgb(cfg("tint")) } ; t.gradient[4], t.gradient[5], t.gradient[6] = cfg("alpha"), cfg("topAlpha"), cfg("height") end
	return t
end

-- The wash on a holder frame with .Fade and .Flat textures (quest log details, quest dialog body): `wash` is
-- tint.gradient, `h` the holder's height; a third of the stock alpha (ours is a plain colour on a dark ground).
ns.QuestWash = function(holder, wash, h)
	holder:SetShown(wash ~= nil)
	if not wash then return end
	local r, g, b, a, top, hh = unpack(wash)
	local fade, flat = holder.Fade, holder.Flat
	fade:ClearAllPoints()
	fade:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
	fade:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
	fade:SetHeight(math.max(1, h * hh))
	flat:ClearAllPoints()
	flat:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
	flat:SetPoint("BOTTOMRIGHT", fade, "TOPRIGHT", 0, 0)
	fade:SetColorTexture(1, 1, 1, 1)
	fade:SetGradient("VERTICAL", CreateColor(r, g, b, a * 0.16), CreateColor(r, g, b, top * 0.16))
	flat:SetColorTexture(r, g, b, top * 0.16)
end
end)
