-- What's Training? (WhatsTraining) in our Spellbook (docs/addons.md): its
-- public WT_API read into a "Training" tab of ours (its own tab hangs on the
-- stock book, which never opens), and its window in the book's "..." menu.
-- A no-op without the addon.

local ADDON, ns = ...
local W = Polestar.Widgets

ns.AfterLogin(function()
local api = WT_API
local book = ns.modules.spellbook
if not (type(api) == "table" and api.GetSpells and api.Status and book) then return end

local ROW_H, ICON, TOP = 44, 36, 16 -- the book's rows

-- The addon's own groups and order (its Categories.lua), weapon skills folded
-- into their level's group; known and ignored ones left out (the book has the known).
local GROUPS = {
	{ "Available now", "AVAILABLE", "WEAPON_AVAILABLE" },
	{ "Missing requirements", "MISSINGREQS" },
	{ "Coming soon", "NEXTLEVEL", "WEAPON_NEXTLEVEL" },
	{ "Not yet available", "NOTLEVEL", "WEAPON_NOTLEVEL" },
	{ "Pet abilities", "PET" },
	{ "Missing talents", "MISSINGTALENT" },
}

-- -> the groups with their spells (level, then name), the count to train now.
local function trainingGroups()
	local of = {}
	for g, def in ipairs(GROUPS) do
		for k = 2, #def do if api.Status[def[k]] then of[api.Status[def[k]]] = g end end
	end
	local out = {}
	for g, def in ipairs(GROUPS) do out[g] = { label = def[1], spells = {} } end
	local ok, list = pcall(api.GetSpells)
	for _, s in ipairs(ok and type(list) == "table" and list or {}) do
		local g = of[s.status]
		if g then table.insert(out[g].spells, s) end
	end
	for _, g in ipairs(out) do
		table.sort(g.spells, function(a, b)
			if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
			return (a.name or "") < (b.name or "")
		end)
	end
	return out, #out[1].spells
end

local trows, theads = {}, {}

local function trainingRow(f)
	local r = CreateFrame("Button", nil, f.Body)
	r:SetHeight(ICON)
	W.Hover(r)
	local well
	well, r.Icon = ns.ItemWell(r, ICON)
	well:SetPoint("LEFT", r, "LEFT", 0, 0)
	r.Money = ns.Money(r)
	r.Money:SetPoint("RIGHT", r, "RIGHT", -8, 0)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("BOTTOMLEFT", well, "RIGHT", 12, 1)
	r.Sub = W.Text(r, "small", "textDim")
	r.Sub:SetPoint("TOPLEFT", well, "RIGHT", 12, -3)
	for _, t in ipairs({ r.Name, r.Sub }) do
		t:SetPoint("RIGHT", r, "RIGHT", -120, 0)
		t:SetJustifyH("LEFT")
		t:SetWordWrap(false)
	end
	r:SetScript("OnEnter", function(self)
		local s = self.psTrain
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if s.link then GameTooltip:SetHyperlink(s.link) else GameTooltip:SetText(s.name or "") end
		GameTooltip:Show()
	end)
	r:SetScript("OnLeave", W.HideTooltip)
	return r
end

-- "Rank 3 · Level 20 · Quest"
local function trainingSub(s)
	local parts = {}
	if s.subText and s.subText ~= "" then parts[1] = s.subText end
	if s.level and s.level > 0 then parts[#parts + 1] = ("Level %d"):format(s.level) end
	if s.quest then parts[#parts + 1] = "Quest" end
	return table.concat(parts, " · ")
end

-- One column under the groups' headings. Returns the body height.
local function paintTraining(f)
	local y, n, h = 0, 0, 0
	local purse = GetMoney()
	for _, g in ipairs((trainingGroups())) do
		if #g.spells > 0 then
			h = h + 1
			local head = theads[h] or W.SectionHeader(f.Body)
			theads[h] = head
			head:ClearAllPoints()
			head:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -y)
			head:SetWidth(f.BodyWidth)
			W.SetSection(head, g.label, #g.spells)
			head:Show()
			y = y + head:GetHeight() + 4
			for _, s in ipairs(g.spells) do
				n = n + 1
				local r = trows[n] or trainingRow(f)
				trows[n] = r
				r.psTrain = s
				r:ClearAllPoints()
				r:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -y)
				r:SetWidth(f.BodyWidth)
				r.Icon:SetTexture(s.icon or 134400)
				r.Name:SetText(s.name or UNKNOWN or "Unknown")
				r.Sub:SetText(trainingSub(s))
				local cost = s.cost or 0
				r.Money:SetShown(cost > 0)
				ns.SetMoney(r.Money, cost, cost > purse and "danger" or nil)
				r:Show()
				y = y + ROW_H
			end
		end
	end
	for i = n + 1, #trows do trows[i]:Hide() end
	for i = h + 1, #theads do theads[i]:Hide() end
	f.psEmpty:SetShown(n == 0)
	return y + TOP
end

-- Its own window, from the launcher it registers.
local function launcher()
	local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
	return ldb and ldb:GetDataObjectByName("WhatsTrainingMinimap")
end

table.insert(book.pages, {
	key = "training", label = "Training", icon = "Interface\\Icons\\INV_Misc_Book_09",
	subtitle = function()
		local _, now = trainingGroups()
		return (now == 1 and "1 spell" or now .. " spells") .. " to train now."
	end,
	paint = paintTraining,
	hide = function()
		for _, r in ipairs(trows) do r:Hide() end
		for _, h in ipairs(theads) do h:Hide() end
	end,
	option = function(button)
		local wt = launcher()
		return wt and wt.OnClick and { text = "What's Training?", onClick = function() wt.OnClick(button, "LeftButton") end }
	end,
})

if api.RegisterCallback then
	for _, e in ipairs({ "Ready", "SpellsChanged", "LevelChanged", "IgnoredChanged" }) do
		api.RegisterCallback("PolestarUISpellbook", e, book.Refresh)
	end
end
end)
