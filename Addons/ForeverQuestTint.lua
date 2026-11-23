-- ForeverQuestTint's marks on our quest log (docs/addons.md): the addon marks
-- the quests Forever added (any ID not in the original Classic list) in the
-- stock log; our log draws its own rows, so ours marks them the same way from
-- the addon's saved settings (ForeverQuestTintDB, its defaults where unset):
-- the glyph by the title, the objective colour, the teal wash on the details.
-- The list is our copy (Addons/ForeverQuestTintData.lua, npm run sync:fqt).
-- The map: its teal gradient on the yellow ! and ? of a marked quest, on the game's quest pins of our canvas and on
-- our mirror of Questie's icons (its questieTint).
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
	questieTint = true,
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

-- The map icons' gradient (its ApplyIconGradient): over `tex`, a desaturated copy of its art (`file`, coordinates
-- l, r, t, b) in the vivid tint, solid over the bottom 45% at `alpha`, fading out by 75% of the way up; two textures
-- of ours on `owner` (kept in a table of ours, not on a stock pin) in `layer`/`sub`; `show` false hides them.
local SOLID, FADE, LIFT, VIVID = 0.45, 0.75, 1.15, 2
local grads = setmetatable({}, { __mode = "k" })
local function gradient(owner, tex, show, file, l, r, t, b, height, alpha, layer, sub)
	local g = grads[owner]
	if not (show and file and height and height > 0) then
		if g then g[1]:Hide(); g[2]:Hide() end
		return
	end
	if not g then
		g = { owner:CreateTexture(nil, layer, nil, sub), owner:CreateTexture(nil, layer, nil, sub) }
		grads[owner] = g
	end
	local c = cfg("tint")
	local avg = ((c[1] or 0) + (c[2] or 0) + (c[3] or 0)) / 3
	local function vivid(x) return math.min(1, math.max(0, math.min(1, avg + ((x or 0) - avg) * VIVID)) * LIFT) end
	local cr, cg, cb = vivid(c[1]), vivid(c[2]), vivid(c[3])
	local low, clear = CreateColor(cr, cg, cb, alpha), CreateColor(cr, cg, cb, 0)
	local function slice(piece, from, to, lo, hi)
		piece:SetDrawLayer(layer, sub)
		piece:ClearAllPoints()
		piece:SetPoint("BOTTOMLEFT", tex, "BOTTOMLEFT", 0, height * from)
		piece:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", 0, height * from)
		piece:SetHeight(height * (to - from))
		piece:SetTexture(file)
		piece:SetTexCoord(l, r, b + (t - b) * to, b + (t - b) * from)
		piece:SetDesaturated(true)
		piece:SetGradient("VERTICAL", lo, hi)
		piece:Show()
	end
	slice(g[1], 0, SOLID, low, low)
	slice(g[2], SOLID, FADE, low, clear)
end

-- Questie's icons on our map (Addons/Questie.lua's dress calls it on each repaint of our frame `f` for `icon`): the
-- addon's rule for Questie's own frame (questieTint, plain white, a marked data.Id, the yellow ! or ? art, by the
-- path it recorded from Questie's UpdateTexture, else the texture's), drawn on our frame over its copy of the art.
local QUESTIE_KINDS = { "ICON_TYPE_AVAILABLE", "ICON_TYPE_COMPLETE" }
local function questieYellow(path)
	if not path or type(Questie) ~= "table" or type(Questie.usedIcons) ~= "table" then return false end
	for _, key in ipairs(QUESTIE_KINDS) do
		if Questie[key] and Questie.usedIcons[Questie[key]] == path then return true end
	end
	return false
end
ns.FQTQuestieTint = function(f, icon)
	local tex, data = icon.texture, type(icon.data) == "table" and icon.data
	local r, g, b, a = tex:GetVertexColor()
	local show = cfg("questieTint") and data and r > 0.99 and g > 0.99 and b > 0.99 and ns.FQTMarked(data.Id)
		and questieYellow(icon.fqtIcon or tex:GetTexture())
	local l, t, _, _, _, _, rr, bb = tex:GetTexCoord()
	gradient(f, f.tex, show, f.tex:GetTexture(), l, rr, t, bb, f:GetHeight(), a or 1, "OVERLAY", 1)
end

-- The game's quest pins on our canvas (its MapPins, which hooks WorldMapFrame's alone): a giver's plain yellow !
-- (QuestOfferPinTemplate, pin.Texture, atlas QuestNormal, pin.questID; a trivial one at half alpha left alone) and a
-- plain turn-in ? (QuestPinTemplate, pin.Display.Icon, UI-QuestIcon-TurnIn-Normal, pin:GetQuestID()). Post-hooks
-- on our canvas instance only: RegisterPin (end of AcquirePin, after the pin's OnAcquired) and UnregisterPin (its
-- release); a quest pin gets its quest and art after AcquirePin returns (QuestDataProvider:AddQuest), so each of
-- ours is also post-hooked once on UpdateButtonStyle, which the provider calls then and on every restyle.
local map = ns.modules.map
if not (map and map.overlays) then return end
local PINS = {
	QuestOfferPinTemplate = { atlas = "QuestNormal", tex = function(p) return p.Texture end,
		id = function(p) return (p.pinAlpha or 1) >= 1 and p.questID end },
	QuestPinTemplate = { atlas = "UI-QuestIcon-TurnIn-Normal", tex = function(p) return p.Display and p.Display.Icon end,
		id = function(p) return p.GetQuestID and p:GetQuestID() end },
}
local function paint(pin, on)
	local kind = PINS[pin.pinTemplate]
	local tex = kind and kind.tex(pin)
	if not (tex and tex.GetAtlas) then return end
	local atlas = tex:GetAtlas()
	local info = on and cfg("questieTint") and atlas == kind.atlas and ns.FQTMarked(kind.id(pin))
		and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
	local owner = tex:GetParent()
	if not info then return gradient(owner, tex, false) end
	local layer, sub = tex:GetDrawLayer()
	local h = tex:GetHeight()
	if not h or h <= 0 then h = owner:GetHeight() end
	gradient(owner, tex, true, info.file or info.filename, info.leftTexCoord, info.rightTexCoord, info.topTexCoord,
		info.bottomTexCoord, h, 1, layer, math.min((sub or 0) + 1, 7))
end
local styled = setmetatable({}, { __mode = "k" })
local function acquired(_, pin)
	if pin.pinTemplate == "QuestPinTemplate" and not styled[pin] and type(pin.UpdateButtonStyle) == "function" then
		styled[pin] = true
		hooksecurefunc(pin, "UpdateButtonStyle", function(self) paint(self, true) end)
	end
	paint(pin, true)
end
local hooked
map.overlays[#map.overlays + 1] = function(canvas)
	if hooked then return end
	hooked = true
	hooksecurefunc(canvas, "RegisterPin", acquired)
	hooksecurefunc(canvas, "UnregisterPin", function(_, pin) paint(pin, false) end)
	for template in pairs(PINS) do
		for pin in canvas:EnumeratePinsByTemplate(template) do acquired(canvas, pin) end
	end
end
end)
