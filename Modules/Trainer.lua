-- The Trainer (docs/windows/trainer.md): the trainer's services in a Polestar
-- shell. The stock ClassTrainerFrame ends the trainer as it hides (CloseTrainer)
-- and runs UpdateMicroButtons as it shows and hides, so it is never opened:
-- ours takes the interaction and Forever's TRAINER_SHOW route (ns.Interaction).

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUITrainer"
local ROW_H, ICON = 48, 36
local ALL = "all"

local f, subject
local rows = {}
local cat, sel = ALL, nil -- the shown category; the selected service's index
local M = {}
local paint

-- A pet trainer's costs are the pet's training points, not money (Camelot).
local function petTrainer()
	return C_Trainer and C_Trainer.GetTrainerType and Enum.TrainerType and C_Trainer.GetTrainerType() == Enum.TrainerType.Pet
end

local function purse()
	if not petTrainer() then return GetMoney() end
	local total, used = C_PetInfo.GetPetTrainingPoints()
	return total - used
end

-- What the service needs, as the stock row lists it, and whether all of it is met.
local function needs(i)
	local parts, met = {}, true
	local function add(text, ok)
		parts[#parts + 1] = text
		met = met and ok
	end
	local _, _, _, reqLevel = GetTrainerServiceInfo(i)
	if reqLevel and reqLevel > 1 then add("level " .. reqLevel, UnitLevel(petTrainer() and "pet" or "player") >= reqLevel) end
	local skill, rank, has = GetTrainerServiceSkillReq(i)
	if skill then add(("%s (%d)"):format(skill, rank), has) end
	for a = 1, GetTrainerServiceNumAbilityReq(i) do
		local ability, ok = GetTrainerServiceAbilityReq(i, a)
		if ability then add(ability, ok) end
	end
	return #parts > 0 and "Requires " .. table.concat(parts, ", ") or "", met
end

-- Whether Train can buy service i now: available, affordable, and for a
-- profession a free slot (as the stock Train button).
local function canTrain(i)
	local _, kind = GetTrainerServiceInfo(i)
	local cost, isProfession = GetTrainerServiceCost(i)
	if kind ~= "available" or (cost or 0) > purse() then return false end
	return not (isProfession and select(2, GetProfessions()))
end

local function train()
	if not (sel and canTrain(sel)) then return end
	local i = sel
	if not (IsTradeskillTrainer() and select(2, GetTrainerServiceCost(i))) then return BuyTrainerService(i) end
	-- The stock CONFIRM_PROFESSION, as Polestar's dialog (StaticPopup is never ours).
	local text = GetProfessions() and PROFESSION_CONFIRMATION2 or PROFESSION_CONFIRMATION1
	W.Modal({ title = "Learn a profession", text = text:format(GetTrainerServiceSkillLine(i)), action = "Learn",
		onAccept = function() BuyTrainerService(i) end })
end

-- A trainer of the player's class, as Polestar knows them (Engine.IsClassTrainer).
local function classTrainer()
	local E = Polestar.Engine
	return not IsTradeskillTrainer() and not petTrainer() and E and E.IsClassTrainer and E.IsClassTrainer(Polestar.Compat.GetNpcID("npc"))
end

local function enter(r)
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetTrainerService(r.psIndex)
	GameTooltip:Show()
end

local function newRow(i)
	local r = CreateFrame("Button", nil, f.Body)
	r:SetHeight(ROW_H)
	W.Hover(r)
	r.Sel = r:CreateTexture(nil, "BACKGROUND")
	r.Sel:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.Sel:SetAllPoints(r)
	W.Painter(r.Sel, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	local well
	well, r.Icon = ns.ItemWell(r, ICON)
	well:SetPoint("LEFT", r, "LEFT", 6, 0)
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
	r:SetScript("OnClick", function(self)
		sel = self.psIndex
		paint()
	end)
	r:SetScript("OnEnter", enter)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[i] = r
	return r
end

local function paintRow(r, i)
	r.psIndex = i
	local name, kind, icon, _, subText = GetTrainerServiceInfo(i)
	local used = kind == "used"
	r.Icon:SetTexture(icon)
	r.Icon:SetDesaturated(kind == "unavailable")
	r.Name:SetText((name or UNKNOWN or "Unknown") .. ((subText or "") ~= "" and " (" .. subText .. ")" or ""))
	W.Color(r.Name, used and "textMuted" or "text")
	local req, met = needs(i)
	local cost = GetTrainerServiceCost(i) or 0
	if petTrainer() and cost > 0 and not used then
		req = (req ~= "" and req .. " · " or "") .. cost .. " training points"
	end
	r.Sub:SetText(used and "Known" or req)
	W.Color(r.Sub, used and "textMuted" or (met and "textDim" or "danger"))
	r.Money:SetShown(not used and not petTrainer() and cost > 0)
	ns.SetMoney(r.Money, cost, cost > purse() and "danger" or nil)
	r.Sel:SetShown(i == sel)
end

local function filterMenu(anchor)
	if W.MenuShown(anchor) then return W.HideMenu() end
	local items = {}
	for _, k in ipairs({ { "available", AVAILABLE or "Available" }, { "unavailable", UNAVAILABLE or "Unavailable" }, { "used", USED or "Used" } }) do
		items[#items + 1] = { text = k[2], checked = GetTrainerServiceTypeFilter(k[1]), onClick = function()
			SetTrainerServiceTypeFilter(k[1], not GetTrainerServiceTypeFilter(k[1]))
			-- The list comes back on TRAINER_UPDATE; redraw now too (docs/CLIENT.md, rule 6).
			paint()
			filterMenu(anchor)
		end }
	end
	W.ShowMenu(anchor, items, { minWidth = 160 })
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 760, height = 600 })
	ns.Dock(f)
	ns.WindowMenu(f, "trainer")
	subject = ns.SubjectBlock(f)
	local top = W.SHELL.header - 30
	f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", filterMenu, 14)
	f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -top)
	Theme.Skin(f.psFilter, "editbox")
	f.psEmpty = W.Text(f.Body, "body", "textMuted")
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psEmpty:SetText("Nothing to show. Check the filter.")
	f.psRows = rows
	Polestar.CloseOnEscape(NAME)
end

function paint()
	local pet = petTrainer()
	SetPortraitTexture(subject.icon, pet and "pet" or "npc")
	subject.name:SetText(UnitName(pet and "pet" or "npc") or "")
	subject.line:SetText(classTrainer() and (UnitClass("player") .. " trainer") or IsTradeskillTrainer() and "Profession trainer" or "Trainer")

	-- The services by category (Camelot's skill lines), counting what can be learnt.
	local list, cats, order, open = {}, {}, {}, 0
	for i = 1, GetNumTrainerServices() do
		local _, kind, _, _, _, category = GetTrainerServiceInfo(i)
		if kind ~= "header" then
			category = (category or "") ~= "" and category or nil
			local n = kind == "available" and 1 or 0
			open = open + n
			if category then
				if not cats[category] then order[#order + 1] = category end
				cats[category] = (cats[category] or 0) + n
			end
			if cat == ALL or cat == category then list[#list + 1] = i end
		end
	end
	if cat ~= ALL and not cats[cat] then
		cat = ALL
		return paint()
	end
	local nav = { { key = ALL, label = "All", icon = "compact", count = open } }
	for _, c in ipairs(order) do nav[#nav + 1] = { key = c, label = c, count = cats[c] } end
	W.ShellNav(f, nav, cat, function(k)
		cat = k
		paint()
	end)

	-- The selection stays while listed; else the first that can be learnt, as the stock window.
	local listed
	for _, i in ipairs(list) do listed = listed or i == sel end
	if not listed then
		sel = nil
		for _, i in ipairs(list) do
			if not sel and select(2, GetTrainerServiceInfo(i)) == "available" then sel = i end
		end
	end

	W.ShellTitle(f, cat == ALL and "Trainer" or cat, open > 0 and ("%d to learn"):format(open) or "Nothing to learn now.")
	W.ShellTabs(f, nil)
	for n, i in ipairs(list) do
		local r = rows[n] or newRow(n)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad - 6, -(24 + (n - 1) * ROW_H))
		r:SetWidth(f.BodyWidth - 2 * W.SHELL.pad + 12)
		paintRow(r, i)
		r:Show()
	end
	for n = #list + 1, #rows do rows[n]:Hide() end
	f.psEmpty:SetShown(#list == 0)
	W.SetIconState(f.psFilter, not (GetTrainerServiceTypeFilter("available") and GetTrainerServiceTypeFilter("unavailable") and GetTrainerServiceTypeFilter("used")))

	W.ShellFooter(f, {}, { { label = "Train", onClick = train, opts = { primary = true } } })
	ns.SetEnabled(f.footerButtons.right[1], sel and canTrain(sel) or false)
	W.ShellBody(f, 24 + math.max(#list, 1) * ROW_H + 24)
end

function M.Show()
	if not f then build() end
	cat, sel = ALL, nil
	paint()
	f:Show()
end

function M.Enable()
	ns.Interaction("trainer", { Enum.PlayerInteractionType.Trainer }, { frame = NAME, close = function() CloseTrainer() end, internal = { "TRAINER_SHOW" } })
	for _, e in ipairs({ "TRAINER_UPDATE", "PLAYER_MONEY", "UNIT_PET_TRAINING_POINTS" }) do
		Polestar.RegisterEvent(e, function() if f and f:IsShown() then paint() end end)
	end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return ClassTrainerFrame and ClassTrainerFrame:IsShown() and ClassTrainerFrame end

ns.Module("trainer", M)
