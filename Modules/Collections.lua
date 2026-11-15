-- Collections (docs/windows/collections.md): Forever's Collections journal
-- (CollectionsJournal, Blizzard_Collections) in a Polestar shell: Mounts,
-- Pets (the Classic pet journal), Toys and Appearances (Items and Sets).
-- Ours never loads, shows or hides the stock journal: its show and hide run
-- micro button code (UpdateMicroButtons; docs/CLIENT.md, rule 8).

local ADDON, ns = ...
local W, Theme = Polestar.Widgets, Polestar.Theme

local NAME = "PolestarUICollections"
local LISTW, ROW_H, ICON, SIDE = 260, 36, 28, 12 -- the list column (mounts, pets, sets), its rows
local TOYS_PER_PAGE, TOY_COLS, TOY_H, GAP = 18, 3, 44, 12 -- as the stock toy box: 18 a page
local LOOKS_PER_PAGE, LOOK_COLS, LOOK_H, SLOT = 18, 6, 100, 32 -- as the stock wardrobe: 6 by 3 models a page
-- The stock journal's side tabs (CollectionsJournalMixin.TABS_DATA) on Forever,
-- no heirlooms nor warband scenes (the client has neither), on a slim rail.
local PAGES = {
	{ key = "mounts", label = MOUNTS or "Mounts", icon = "Interface/ICONS/INV_Horse3Saddle008_Chestnut" },
	{ key = "pets", label = PET_JOURNAL or "Pet Journal", icon = "Interface/ICONS/INV_ArfusPet_Classic" },
	{ key = "toys", label = TOY_BOX or "Toy Box", icon = "Interface/ICONS/INV_SideTab_ToyBox_c60" },
	{ key = "appearances", label = WARDROBE or "Appearances", icon = "Interface/ICONS/UI_Transmog_ShowEquippedGear" },
}
local BY_KEY = {}
for _, p in ipairs(PAGES) do BY_KEY[p.key] = p end

local f, page, nav, detail, toyPage, looks
local view = "items" -- the Appearances view: items or sets
local M = {}
local query = { mounts = "", pets = "", toys = "", items = "", sets = "" }
local rows, tiles = {}, {}
local tries = {} -- mounts whose source and lore were read empty, how often
local selected, shown -- the mount selected (its ID); what the model shows
local petSel -- the pet on the card: its GUID, or the species ID of one not collected
local toyAt = 1 -- the toy page
local newToys = {} -- learnt while the game ran, until hovered (as the stock box's)

local refresh -- below
local function redraw() if f and f:IsShown() then refresh() end end

-- With the client's "only show collected" setting, a page with nothing
-- collected is not shown (CollectionsJournal_ValidateTab).
local function valid(key)
	if not GetCVarBool("onlyShowCollectedItemsInJournal") then return true end
	if key == "mounts" then return C_MountJournal.HasDisplayableMount() end
	if key == "pets" then return select(2, C_PetJournal.GetNumPets()) > 0 end
	if key == "toys" then return C_ToyBoxInfo.HasAnyToy() end
	return C_TransmogCollection.HasAnyAppearance()
end

-- The search box's key: the page, or the Appearances view.
local function qkey() return page == "appearances" and view or page end

local function strip(s) return ((s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "\n")) end

local function favText(fav) return fav and (BATTLE_PET_UNFAVORITE or "Remove Favorite") or (BATTLE_PET_FAVORITE or "Set Favorite") end

-- Shift-click links: into the macro text (the spell's name) while it is open, as stock.
local function link(spellID, l)
	if MacroFrame and MacroFrame:IsShown() then
		ChatFrameUtil.InsertLink(C_Spell.GetSpellName(spellID))
	elseif l then
		ChatFrameUtil.InsertLink(l)
	end
end

local function shiftClick() return IsModifiedClick("CHATLINK") end

---------------------------------------------------------------------------
-- Mounts: the list on the left, the selected mount's model and lore beside it.

local function mountAt(i)
	local name, spell, icon, active, usable, _, favorite, factionOnly, faction, _, collected, id = C_MountJournal.GetDisplayedMountInfo(i)
	return { index = i, name = name, spell = spell, icon = icon, active = active, usable = usable, favorite = favorite,
		faction = factionOnly and faction or nil, collected = collected, id = id, fanfare = C_MountJournal.NeedsFanfare(id) }
end

-- Mount, Dismount or Unwrap, as the stock button (MountJournalMountButton_UseMount).
-- Summoning is not protected (checked in game from addon code).
local function useMount(id)
	local active = select(4, C_MountJournal.GetMountInfoByID(id))
	if active then
		C_MountJournal.Dismiss()
	elseif C_MountJournal.NeedsFanfare(id) then
		local function done()
			C_MountJournal.ClearFanfare(id)
			shown = nil
			redraw()
		end
		local scene = detail.Model
		if scene.StartUnwrapAnimation and scene:IsVisible() then scene:StartUnwrapAnimation(done) else done() end
	else
		C_MountJournal.SummonByID(id)
	end
	redraw()
end

-- The stock row menu (MENU_MOUNT_COLLECTION_MOUNT): Mount/Dismount/Unwrap,
-- Favorite/Unfavorite; the list redraws at once (docs/CLIENT.md, rule 6).
local function mountMenu(r)
	local m = r.psMount
	local items = {}
	if m.fanfare then
		items[1] = { text = UNWRAP or "Unwrap", onClick = function() selected = m.id; refresh(); useMount(m.id) end }
	else
		items[1] = { text = m.active and (BINDING_NAME_DISMOUNT or "Dismount") or (MOUNT or "Mount"), disabled = not m.active and not m.usable,
			onClick = function() useMount(m.id) end }
		local fav, can = C_MountJournal.GetIsFavorite(m.index)
		items[2] = { text = favText(fav), disabled = not can,
			onClick = function()
				C_MountJournal.SetIsFavorite(m.index, not fav)
				redraw()
			end }
	end
	W.ShowMenu(r, items, { minWidth = 160 })
end

local function rowEnter(r)
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetMountBySpellID(r.psMount.spell)
	if r.psMount.collected then
		ns.TooltipHint("Click to see it. Right-click for its menu. Drag it to an action bar. Shift-click to link it in chat.")
	else
		ns.TooltipHint("Shift-click to link it in chat.")
	end
	GameTooltip:Show()
end

local function rowClick(r, button)
	local m = r.psMount
	if button == "RightButton" then
		if m.collected then mountMenu(r) end
	elseif shiftClick() then
		link(m.spell, C_MountJournal.GetMountLink(m.spell))
	elseif m.id ~= selected then
		selected = m.id
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		redraw()
	end
end

-- A collected mount drags to the bars; not in combat (docs/CLIENT.md, rule 4:
-- a pickup from addon code may be blocked there, not checked in game).
local function rowDrag(r)
	if InCombatLockdown() or not r.psMount.collected then return end
	C_MountJournal.Pickup(r.psMount.index)
end

-- A list row, shared by mounts, pets and sets: each paint sets its own scripts.
local function newRow()
	local r = CreateFrame("Button", nil, nav.Child)
	r:SetSize(LISTW - 8, ROW_H)
	W.Hover(r)
	r.Sel = r:CreateTexture(nil, "BACKGROUND")
	r.Sel:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.Sel:SetAllPoints(r)
	W.Painter(r.Sel, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	r.Bar = W.Fill(r, "accent", "ARTWORK", 0)
	r.Bar:ClearAllPoints()
	r.Bar:SetPoint("TOPLEFT")
	r.Bar:SetPoint("BOTTOMLEFT")
	r.Bar:SetWidth(2)
	r.Well = ns.ItemWell(r, ICON)
	r.Well:SetPoint("LEFT", r, "LEFT", SIDE, 0)
	r.Cooldown = CreateFrame("Cooldown", nil, r.Well, "CooldownFrameTemplate")
	r.Cooldown:SetAllPoints(r.Well.Icon)
	r.Star = W.Tex(r, "ARTWORK", "star", "accent")
	r.Star:SetSize(12, 12)
	r.Star:SetPoint("RIGHT", r, "RIGHT", -SIDE, 0)
	r.Faction = r:CreateTexture(nil, "ARTWORK")
	r.Faction:SetSize(16, 16)
	r.Faction:SetPoint("RIGHT", r.Star, "LEFT", -6, 0)
	r.New = W.Chip(r)
	r.Name = W.Text(r, "body", "text")
	r.Name:SetJustifyH("LEFT")
	r.Name:SetWordWrap(true)
	r.Sub = W.Text(r, "small", "textMuted")
	r.Sub:SetPoint("LEFT", r.Well, "RIGHT", 10, -8)
	r.Sub:SetJustifyH("LEFT")
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:RegisterForDrag("LeftButton")
	r:SetScript("OnLeave", W.HideTooltip)
	return r
end

-- The parts every list row shows alike: selection, star, "New", name (with a
-- second line under it, or two lines of name at most: the Recipe Row).
local function paintBase(r, o)
	r.Sel:SetShown(o.on)
	r.Bar:SetShown(o.on)
	r.Name:SetText(o.name)
	W.Color(r.Name, o.color)
	r.Name:SetMaxLines(o.sub and 1 or 2)
	r.Name:SetPoint("LEFT", r.Well, "RIGHT", 10, o.sub and 7 or 0)
	r.Sub:SetShown(o.sub and true or false)
	r.Sub:SetText(o.sub or "")
	r.Star:SetShown(o.favorite and true or false)
	local fac = o.faction
	r.Faction:SetShown(fac and true or false)
	if fac then r.Faction:SetAtlas(fac) end
	r.New:SetShown(o.new and true or false)
	if o.new then
		W.SetChip(r.New, "New", "accent")
		r.New:ClearAllPoints()
		r.New:SetPoint("RIGHT", r.Faction, "LEFT", -6, 0)
	end
	r.Name:SetPoint("RIGHT", o.new and r.New or r.Faction, "LEFT", -6, o.sub and 7 or 0)
	r.Sub:SetPoint("RIGHT", r.Faction, "LEFT", -6, -8)
	r.Well.Icon:SetAlpha(o.receding and 0.5 or 1)
	if o.active then local cr, cg, cb = Theme.Color("accent"); Theme.Border(r.Well, cr, cg, cb, 1) end
end

-- A row as the stock list shows it: usable in full, collected but unusable
-- red (the name in danger), not collected desaturated and receding; the star
-- of a favorite, the faction's mark, "New" until unwrapped, the summoned one's
-- well in the accent.
local function paintRow(r, m)
	r.psMount, r.psPet, r.psSet = m, nil, nil
	r:SetScript("OnClick", rowClick)
	r:SetScript("OnDragStart", rowDrag)
	r:SetScript("OnEnter", rowEnter)
	r.Cooldown:Clear()
	ns.PaintItem(r.Well, { icon = m.fanfare and COLLECTIONS_FANFARE_ICON or m.icon, desat = not m.collected,
		unusable = m.collected and not m.usable and not m.fanfare })
	paintBase(r, { on = m.id == selected, name = m.name, favorite = m.favorite, new = m.fanfare, receding = not m.collected, active = m.active,
		color = not m.collected and "textMuted" or (m.usable or m.fanfare) and "text" or "danger",
		faction = m.faction and (m.faction == 0 and "MountJournalIcons-Horde" or "MountJournalIcons-Alliance") })
end

-- The model: the game's mount scene on our own frame, as the stock journal
-- sets it up (MountJournal_UpdateMountDisplay; docs/CLIENT.md, rule 5).
local function showModel(id)
	local scene = detail.Model
	-- Set up only while shown: the camera frames the mount by the scene's
	-- size, and a hidden scene has none yet (the stock journal transitions
	-- only while visible, MountJournal_FullUpdate).
	if not scene:IsVisible() then shown = nil; return end
	shown = id
	if not (id and scene.TransitionToModelSceneID) then return end
	local display, _, _, isSelf, _, sceneID, animID, kit, noPlayer = C_MountJournal.GetMountInfoExtraByID(id)
	if not display then
		local all = C_MountJournal.GetMountAllCreatureDisplayInfoByID(id)
		display = all and all[1] and all[1].creatureDisplayID or 0
	end
	scene:TransitionToModelSceneID(sceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
	scene:PrepareForFanfare(C_MountJournal.NeedsFanfare(id))
	local actor = scene:GetActorByTag("unwrapped")
	if not actor then return end
	actor:SetModelByCreatureDisplayID(display, true)
	if isSelf then
		actor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
		actor:SetAnimation(618) -- MountSelfIdle
	else
		actor:SetAnimationBlendOperation(Enum.ModelBlendOperation.Anim)
		actor:SetAnimation(0)
	end
	noPlayer = noPlayer or not GetCVarBool("mountJournalShowPlayer")
	scene:AttachPlayerToMount(actor, animID, isSelf, noPlayer, kit, PlayerUtil and PlayerUtil.ShouldUseNativeFormInModelScene())
end

-- The pet card's model, as PetJournal_UpdatePetCard: the species' card scene.
local function showPet(key)
	local scene = detail.Pet
	if not scene:IsVisible() then shown = nil; return end
	shown = key
	if not (key and scene.TransitionToModelSceneID) then return end
	local species, display, fanfare, _
	if type(key) == "string" then
		species, _, _, _, _, display = C_PetJournal.GetPetInfoByPetID(key)
		fanfare = C_PetJournal.PetNeedsFanfare(key)
	else
		species, display = key, select(12, C_PetJournal.GetPetInfoBySpeciesID(key))
	end
	if not species then return end
	scene:TransitionToModelSceneID(C_PetJournal.GetPetModelSceneInfoBySpeciesID(species), CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, true)
	local actor = scene:GetActorByTag("unwrapped")
	if actor then
		actor:SetModelByCreatureDisplayID(display)
		actor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
		actor:SetAnimation(0, -1)
	end
	scene:PrepareForFanfare(fanfare and true or false)
end

local function showCurrent()
	if page == "pets" then showPet(petSel) elseif page == "mounts" then showModel(selected) end
end

local setModelTurn -- below (the sets' model turns by drag)

-- A model frame at the stock frame's aspect, centred in `parent` (inset 1px):
-- the game's cameras frame a model for the stock frame's shape (docs/CLIENT.md, rule 5).
local function fitAspect(m, parent, aw, ah)
	local w, h = parent:GetWidth() - 2, parent:GetHeight() - 2
	if w <= 0 or h <= 0 then return 0 end
	if w / h > aw / ah then w = h * aw / ah else h = w * ah / aw end
	m:ClearAllPoints()
	m:SetPoint("CENTER", parent, "CENTER")
	m:SetSize(w, h)
	return (parent:GetWidth() - 2 - w) / 2
end

local function buildDetail()
	-- As the stock MountDisplay: the scene fills the whole pane (its scene IDs
	-- frame the mount for that: low and centred, docs/CLIENT.md rule 5), with
	-- the name, source and lore over its top left. The pane is a model well
	-- (ns.ModelShade, no border); the text sits on a frame above the
	-- scene, which draws at its parent's level (useParentLevel in the template).
	-- The sets' DressUpModel and pieces share it (Appearances, Sets).
	local d = CreateFrame("Frame", nil, f.Body)
	ns.ModelShade(d, "BORDER")
	d.Model = CreateFrame("ModelScene", nil, d, "WrappedAndUnwrappedModelScene")
	-- Pets get their own scene, as stock (PetCard.modelScene): sharing one, the pet card
	-- took over the mount's "unwrapped" actor and its camera state (MAINTAIN), framing pets high.
	d.Pet = CreateFrame("ModelScene", nil, d, "WrappedAndUnwrappedModelScene")
	-- Sized in refresh to the stock MountDisplay / PetCard (407 by 514: RightInset less 3px each side).
	d.Dress = CreateFrame("DressUpModel", nil, d)
	d.Dress:SetPoint("TOPLEFT", 1, -1)
	d.Dress:SetPoint("BOTTOMRIGHT", -1, 1)
	setModelTurn(d.Dress)
	local top = CreateFrame("Frame", nil, d)
	top:SetAllPoints(d)
	top:SetFrameLevel(d.Model:GetFrameLevel() + 10)
	d.Top = top
	d.Name = W.Text(top, "title", "text")
	d.Name:SetPoint("TOPLEFT", top, "TOPLEFT", SIDE, -SIDE)
	d.Name:SetJustifyH("LEFT")
	d.New = W.Chip(top)
	d.New:SetPoint("LEFT", d.Name, "RIGHT", 8, 0)
	d.Source = W.Text(top, "body", "textDim")
	d.Source:SetPoint("TOPLEFT", d.Name, "BOTTOMLEFT", 0, -6)
	d.Source:SetPoint("RIGHT", top, "RIGHT", -SIDE, 0)
	d.Lore = W.Text(top, "small", "textDim")
	d.Lore:SetPoint("TOPLEFT", d.Source, "BOTTOMLEFT", 0, -6)
	d.Lore:SetPoint("RIGHT", top, "RIGHT", -SIDE, 0)
	for _, t in ipairs({ d.Source, d.Lore }) do
		t:SetJustifyH("LEFT")
		t:SetWordWrap(true)
		t:SetMaxLines(3)
	end
	for _, m in ipairs({ d.Model, d.Pet }) do
		m:HookScript("OnSizeChanged", function(self) if shown and self:IsVisible() then showCurrent() end end)
		m:HookScript("OnShow", showCurrent)
		-- Hooked: the template has its own mouse scripts (drag turns, the wheel zooms).
		m:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(d.Name:GetText() or "")
			ns.TooltipHint("Drag to turn it, scroll to zoom.")
			GameTooltip:Show()
		end)
		m:HookScript("OnLeave", W.HideTooltip)
	end
	d.Empty = W.Text(f.Body, "default", "textDim")
	d.Empty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", LISTW + f.psPad, -16)
	return d
end

-- Shows the list's rows (count n, painted by paint(row, i)), hides the rest.
local function paintList(n, paint)
	for i = 1, n do
		local r = rows[i] or newRow()
		rows[i] = r
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", nav.Child, "TOPLEFT", 0, -(8 + (i - 1) * ROW_H))
		paint(r, i)
		r:Show()
	end
	for i = n + 1, #rows do rows[i]:Hide() end
	nav.psH = 16 + n * ROW_H
end

-- The detail pane's head (name, "New", source, lore) and which model shows.
local function paintDetail(name, new, source, lore, dress)
	detail:SetShown(name ~= nil)
	detail.Empty:SetShown(name == nil)
	detail.Model:SetShown(not dress and page ~= "pets")
	detail.Pet:SetShown(not dress and page == "pets")
	detail.Dress:SetShown(dress and true or false)
	if not name then return end
	detail.Name:SetText(name)
	detail.New:SetShown(new and true or false)
	if new then W.SetChip(detail.New, "New", "accent") end
	detail.Source:SetText(source or "")
	detail.Lore:SetText(lore or "")
end

-- -> the footer, title and subtitle.
local function paintMounts()
	local n = C_MountJournal.GetNumDisplayedMounts()
	local list, cur = {}, nil
	for i = 1, n do
		list[i] = mountAt(i)
		if list[i].id == selected then cur = list[i] end
	end
	-- As the stock journal: the first one when none is selected (or it left the list).
	if not cur and list[1] and not (selected and C_MountJournal.GetMountInfoByID(selected)) then
		cur = list[1]
		selected = cur.id
	end
	paintList(n, function(r, i) paintRow(r, list[i]) end)
	-- The detail, from the selected mount (it may be filtered out of the list).
	local name, spell, icon, active, usable = nil, nil, nil, false, false
	if selected then name, spell, icon, active, usable = C_MountJournal.GetMountInfoByID(selected) end
	local fanfare = selected and C_MountJournal.NeedsFanfare(selected)
	detail.Empty:SetText(C_MountJournal.GetNumMounts() < 1 and "You have no mounts yet." or "No mount selected.")
	if name then
		local _, lore, source = C_MountJournal.GetMountInfoExtraByID(selected)
		paintDetail(name, fanfare, strip(source), lore)
		-- shortcut: the client may answer empty strings before the mount's data
		-- is loaded and no event says when it is; read again a few times.
		if (source or "") == "" and (lore or "") == "" and (tries[selected] or 0) < 4 then
			tries[selected] = (tries[selected] or 0) + 1
			C_Timer.After(0.5, redraw)
		end
		if shown ~= selected then showModel(selected) end
	else
		paintDetail(nil)
	end
	-- Owned, as the stock count: collected and not hidden on this character.
	local owned = 0
	for _, id in ipairs(C_MountJournal.GetMountIDs()) do
		local _, _, _, _, _, _, _, _, _, hide, collected = C_MountJournal.GetMountInfoByID(id)
		if collected and hide ~= true then owned = owned + 1 end
	end
	local sub = owned == 1 and "1 mount collected" or ("%d mounts collected"):format(owned)
	if query.mounts ~= "" or not C_MountJournal.IsUsingDefaultFilters() then
		sub = sub .. (n == 1 and " · 1 shown" or (" · %d shown"):format(n))
	end
	local label = fanfare and (UNWRAP or "Unwrap") or active and (BINDING_NAME_DISMOUNT or "Dismount") or (MOUNT or "Mount")
	local why
	if name and not fanfare and not usable then
		why = select(2, C_MountJournal.GetMountUsabilityByID(selected, true)) or "You can't use this mount now."
	end
	return { { label = label, onClick = function() if selected then useMount(selected) end end, opts = { primary = true },
		on = name ~= nil and (fanfare or usable), why = why or "No mount selected.",
		tip = fanfare and (MOUNT_UNWRAP_TOOLTIP or "Unwrap your new mount.") or (MOUNT_SUMMON_TOOLTIP or "Summon or dismiss this mount.") } },
		MOUNTS or "Mounts", sub
end

---------------------------------------------------------------------------
-- Pets: the Classic pet journal (Classic/Blizzard_PetCollection.lua), the
-- mounts' list and model pane. Forever's has no loadout, abilities, rename,
-- release or cage.

local function petAt(i)
	local id, species, owned, custom, _, favorite, revoked, name, icon = C_PetJournal.GetPetInfoByIndex(i)
	return { index = i, id = id, species = species, owned = owned, name = custom or name, favorite = favorite, revoked = revoked,
		icon = icon, key = id or species, fanfare = id and C_PetJournal.PetNeedsFanfare(id) }
end

local function unwrapPet(id)
	local scene = detail.Pet
	if (scene.IsUnwrapAnimating and scene:IsUnwrapAnimating()) or not C_PetJournal.PetNeedsFanfare(id) then return end
	petSel = id
	refresh()
	local function done()
		C_PetJournal.ClearFanfare(id)
		shown = nil
		redraw()
	end
	if scene.StartUnwrapAnimation and scene:IsVisible() then scene:StartUnwrapAnimation(done) else done() end
end

-- Summon, Dismiss or Unwrap, as PetJournalSummonButton_OnClick (summoning
-- from addon code works: checked in game).
local function usePet(id)
	if C_PetJournal.IsCurrentlySummoned(id) then
		C_PetJournal.DismissSummonedPet(id)
	elseif C_PetJournal.PetNeedsFanfare(id) then
		return unwrapPet(id)
	else
		C_PetJournal.SummonPetByGUID(id)
	end
	redraw()
end

-- The stock row menu (CreateContextMenu, MENU_PET_COLLECTION_PET).
local function petMenu(r)
	local p = r.psPet
	if p.fanfare then return W.ShowMenu(r, { { text = UNWRAP or "Unwrap", onClick = function() unwrapPet(p.id) end } }, { minWidth = 160 }) end
	local items = {}
	local locked = C_PetJournal.PetIsLockedForConvert and C_PetJournal.PetIsLockedForConvert(p.id)
	if not p.revoked and not locked then
		items[1] = { text = C_PetJournal.IsCurrentlySummoned(p.id) and (PET_DISMISS or "Dismiss") or (BATTLE_PET_SUMMON or "Summon"),
			disabled = not C_PetJournal.PetIsSummonable(p.id), onClick = function() C_PetJournal.SummonPetByGUID(p.id); redraw() end }
	end
	local fav = C_PetJournal.PetIsFavorite(p.id)
	if fav or (not p.revoked and not locked) then
		items[#items + 1] = { text = favText(fav), disabled = not C_PetJournal.IsJournalUnlocked(),
			onClick = function() C_PetJournal.SetFavorite(p.id, fav and 0 or 1); redraw() end }
	end
	if #items > 0 then W.ShowMenu(r, items, { minWidth = 160 }) end
end

local function petEnter(r)
	local p = r.psPet
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	if p.id then GameTooltip:SetCompanionPet(p.id) else GameTooltip:SetText(p.name or "") end
	ns.TooltipHint(p.owned and "Click to see it. Right-click for its menu. Drag it to an action bar. Shift-click to link it in chat."
		or "Click to see it. Shift-click to link it in chat.")
	GameTooltip:Show()
end

local function petLink(p)
	if MacroFrame and MacroFrame:IsShown() then return end -- as stock: no pet links in macros
	local l
	if p.id and BATTLEPETS_SUPPORTED then l = C_PetJournal.GetBattlePetLink(p.id) else l = C_PetJournal.GetNonBattlePetLinkByIndex(p.index) end
	if l then ChatFrameUtil.InsertLink(l) end
end

local function petClick(r, button)
	local p = r.psPet
	if shiftClick() then
		petLink(p)
	elseif button == "RightButton" then
		if p.owned then petMenu(r) end
	elseif GetCursorInfo() == "battlepet" then
		ClearCursor()
	elseif p.key ~= petSel then
		petSel = p.key
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		redraw()
	end
end

-- Out of combat only, as mounts (docs/CLIENT.md, rule 4).
local function petDrag(r)
	local p = r.psPet
	if InCombatLockdown() or not p.id or C_PetJournal.PetIsRevoked(p.id) then return end
	C_PetJournal.PickupPet(p.id)
end

-- The stock sweep (CooldownFrame_Set from GetPetCooldownByGUID). The times may
-- be secret in combat (docs/CLIENT.md, rule 3): the sweep drawn before stays.
local function paintPetCooldown(r)
	local id = r.psPet and r.psPet.id
	local s, d, e
	if id then s, d, e = C_PetJournal.GetPetCooldownByGUID(id) end
	if s == nil then return r.Cooldown:Clear() end
	s, d, e = ns.Clean(s), ns.Clean(d), ns.Clean(e)
	if s == nil or d == nil or e == nil then return end
	if (e == true or e == 1) and d > 0 then r.Cooldown:SetCooldown(s, d) else r.Cooldown:Clear() end
end

-- As PetJournal_InitPetButton: a pet never summonable here (the other
-- faction's) red, a revoked one desaturated, one not collected receding.
local function paintPetRow(r, p)
	r.psMount, r.psPet, r.psSet = nil, p, nil
	r:SetScript("OnClick", petClick)
	r:SetScript("OnDragStart", petDrag)
	r:SetScript("OnEnter", petEnter)
	local never = false
	if p.owned and not p.revoked then
		local _, err = C_PetJournal.GetPetSummonInfo(p.id)
		never = Enum.PetJournalError and err ~= nil and err == Enum.PetJournalError.InvalidFaction or false
	end
	ns.PaintItem(r.Well, { icon = p.fanfare and COLLECTIONS_FANFARE_ICON or p.icon, desat = not p.owned or p.revoked, unusable = never })
	paintBase(r, { on = p.key == petSel, name = p.name, favorite = p.favorite, new = p.fanfare, receding = not p.owned,
		active = p.id and p.id == C_PetJournal.GetSummonedPetGUID(), color = not p.owned and "textMuted" or never and "danger" or "text" })
	paintPetCooldown(r)
end

local function petsDefault()
	return C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED) and C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED)
end

local function paintPets()
	local n, owned = C_PetJournal.GetNumPets()
	local list, cur = {}, nil
	for i = 1, n do
		list[i] = petAt(i)
		if list[i].key == petSel then cur = list[i] end
	end
	if not cur and list[1] and not (type(petSel) == "string" and C_PetJournal.GetPetInfoByPetID(petSel)) then
		cur = list[1]
		petSel = cur.key
	end
	paintList(n, function(r, i) paintPetRow(r, list[i]) end)
	-- The card, as PetJournal_UpdatePetCard: by GUID, or by species for one not collected.
	local id = type(petSel) == "string" and petSel or nil
	local name, custom, source, lore, fanfare, _
	if id then
		_, custom, _, _, _, _, _, name, _, _, _, source, lore = C_PetJournal.GetPetInfoByPetID(id)
		fanfare = C_PetJournal.PetNeedsFanfare(id)
	elseif petSel then
		name, _, _, _, source, lore = C_PetJournal.GetPetInfoBySpeciesID(petSel)
	end
	detail.Empty:SetText(owned < 1 and n < 1 and "You have no pets yet." or "No pet selected.")
	if name then
		local text = strip(source)
		if custom then text = name .. "\n" .. text end
		paintDetail(custom or name, fanfare, text, (lore or "") ~= "" and ('"%s"'):format(lore) or "")
		if shown ~= petSel then showPet(petSel) end
	else
		paintDetail(nil)
	end
	local sub = owned == 1 and "1 pet collected" or ("%d pets collected"):format(owned or 0)
	if query.pets ~= "" or not petsDefault() then sub = sub .. (n == 1 and " · 1 shown" or (" · %d shown"):format(n)) end
	local summoned = id and C_PetJournal.IsCurrentlySummoned(id)
	local why = "You don't have this pet."
	if id then why = select(3, C_PetJournal.GetPetSummonInfo(id)) or "You can't summon this pet now." elseif not petSel then why = "No pet selected." end
	return { { label = summoned and (PET_DISMISS or "Dismiss") or fanfare and (UNWRAP or "Unwrap") or (BATTLE_PET_SUMMON or "Summon"),
		onClick = function() if type(petSel) == "string" then usePet(petSel) end end, opts = { primary = true },
		on = id ~= nil and (fanfare or C_PetJournal.PetIsSummonable(id)) and true or false, why = why,
		tip = fanfare and (BATTLE_PETS_UNWRAP_TOOLTIP or "Unwrap your new pet.") or (BATTLE_PETS_SUMMON_TOOLTIP or "Summon or dismiss this pet.") } },
		PET_JOURNAL or "Pet Journal", sub
end

---------------------------------------------------------------------------
-- Toys: 18 a page, three columns of tiles (the icon, the name beside it).

local function toyEnter(t)
	GameTooltip:SetOwner(t, "ANCHOR_RIGHT")
	GameTooltip:SetToyByItemID(t.psID)
	if PlayerHasToy(t.psID) then
		ns.TooltipHint(InCombatLockdown() and "Toys can't be used from this window in combat. Shift-click to link it in chat."
			or "Click to use it. Right-click for its menu. Drag it to an action bar. Shift-click to link it in chat.")
	else
		ns.TooltipHint("Shift-click to link it in chat.")
	end
	GameTooltip:Show()
	-- Seen: no longer new (a toy still to unwrap stays new).
	if newToys[t.psID] and not t.psFanfare then
		newToys[t.psID] = nil
		t.New:Hide()
	end
end

-- A click uses it (UseToy works from addon code out of combat, checked in game;
-- in combat ours does not try). A new toy's first click unwraps it, as stock.
local function toyClick(t, button)
	local id = t.psID
	if button == "RightButton" then
		if not PlayerHasToy(id) then return end
		local fav = C_ToyBox.GetIsFavorite(id)
		W.ShowMenu(t, { { text = favText(fav), onClick = function()
			C_ToyBox.SetIsFavorite(id, not fav)
			redraw() -- TOYS_UPDATED may lag (docs/CLIENT.md, rule 6)
		end } }, { minWidth = 160 })
	elseif shiftClick() then
		local l = C_ToyBox.GetToyLink(id)
		if l then ChatFrameUtil.InsertLink(l) end
	elseif t.psFanfare then
		C_ToyBoxInfo.ClearFanfare(id)
		newToys[id] = nil
		redraw()
	elseif PlayerHasToy(id) and not InCombatLockdown() then
		UseToy(id)
	end
end

local function toyDrag(t)
	if InCombatLockdown() or not PlayerHasToy(t.psID) then return end
	C_ToyBox.PickupToyBoxItem(t.psID)
end

local function newTile(parent)
	local t = CreateFrame("Button", nil, parent)
	t:SetHeight(TOY_H)
	W.Hover(t)
	t.Well = ns.ItemWell(t, 36)
	t.Well:SetPoint("LEFT", t, "LEFT", 4, 0)
	t.Well:EnableMouse(false)
	t.Cooldown = CreateFrame("Cooldown", nil, t.Well, "CooldownFrameTemplate")
	t.Cooldown:SetAllPoints(t.Well.Icon)
	t.Star = W.Tex(t.Well, "OVERLAY", "star", "accent")
	t.Star:SetSize(12, 12)
	t.Star:SetPoint("CENTER", t.Well, "TOPLEFT", 3, -3)
	t.Name = W.Text(t, "label", "text")
	t.Name:SetPoint("LEFT", t.Well, "RIGHT", 10, 0)
	t.Name:SetPoint("RIGHT", t, "RIGHT", -4, 0)
	t.Name:SetJustifyH("LEFT")
	t.Name:SetWordWrap(true)
	t.Name:SetMaxLines(2)
	t.New = W.Chip(t)
	t.New:SetPoint("BOTTOMRIGHT", t.Well, "BOTTOMRIGHT", 6, -4)
	t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	t:RegisterForDrag("LeftButton")
	t:SetScript("OnClick", toyClick)
	t:SetScript("OnDragStart", toyDrag)
	t:SetScript("OnEnter", toyEnter)
	t:SetScript("OnLeave", W.HideTooltip)
	return t
end

-- The stock sweep (CollectionsSpellButton_UpdateCooldown). Cooldown times may
-- be secret in combat, which SetCooldown refuses from addon code: the sweep
-- drawn before stays then (docs/CLIENT.md, rule 3).
local function paintCooldown(t)
	local cd = t.psID and C_Spell.GetItemCooldown and C_Spell.GetItemCooldown(t.psID)
	if not cd then return t.Cooldown:Clear() end
	if issecretvalue and (issecretvalue(cd.startTime) or issecretvalue(cd.duration) or issecretvalue(cd.isEnabled)) then return end
	if cd.isEnabled and cd.duration > 0 then t.Cooldown:SetCooldown(cd.startTime, cd.duration) else t.Cooldown:Clear() end
end

local function pages() return 1 + math.floor(math.max(C_ToyBox.GetNumFilteredToys() - 1, 0) / TOYS_PER_PAGE) end

local function turn(by)
	local to = math.max(1, math.min(pages(), toyAt + by))
	if to == toyAt then return end
	toyAt = to
	PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
	redraw()
end

local function buildToys()
	local v = CreateFrame("Frame", nil, f.Body)
	-- The wheel turns the page, as on the stock box.
	v:EnableMouseWheel(true)
	v:SetScript("OnMouseWheel", function(_, delta) turn(delta > 0 and -1 or 1) end)
	v.Empty = W.Text(v, "default", "textDim")
	v.Empty:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
	v.Empty:SetText("No toys match.")
	return v
end

local function pager(at, max, go)
	return { { label = "Next", onClick = function() go(1) end, on = at < max, why = "This is the last page." },
		{ label = "Previous", onClick = function() go(-1) end, on = at > 1, why = "This is the first page." } }
end

local function paintToys()
	-- A toy just learnt: its page (ToyBox_UpdatePages' autoPageToCollectedToyID).
	if toyPage.psGoto then
		for i = 1, C_ToyBox.GetNumFilteredToys() do
			if C_ToyBox.GetToyFromIndex(i) == toyPage.psGoto then toyAt = math.floor((i - 1) / TOYS_PER_PAGE) + 1 end
		end
		toyPage.psGoto = nil
	end
	local max = pages()
	toyAt = math.min(toyAt, max)
	local w = (f.BodyWidth - (TOY_COLS - 1) * GAP) / TOY_COLS
	toyPage:SetWidth(f.BodyWidth)
	local count = 0
	for i = 1, TOYS_PER_PAGE do
		local id = C_ToyBox.GetToyFromIndex((toyAt - 1) * TOYS_PER_PAGE + i)
		local t = tiles[i] or newTile(toyPage)
		tiles[i] = t
		local itemID, name, icon, favorite, fanfare
		if id and id ~= -1 then itemID, name, icon, favorite, fanfare = C_ToyBox.GetToyInfo(id) end
		if itemID and name then
			count = count + 1
			local k = i - 1
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", toyPage, "TOPLEFT", (k % TOY_COLS) * (w + GAP), -math.floor(k / TOY_COLS) * (TOY_H + 8))
			t:SetWidth(w)
			t.psID, t.psFanfare = itemID, fanfare
			if fanfare then newToys[itemID] = true end
			local has = PlayerHasToy(itemID)
			ns.PaintItem(t.Well, { icon = fanfare and COLLECTIONS_FANFARE_ICON or icon, desat = not has })
			t.Well.Icon:SetAlpha(has and 1 or 0.5)
			t.Name:SetText(name ~= "" and name or tostring(itemID))
			W.Color(t.Name, has and "text" or "textMuted")
			t.Star:SetShown(favorite and true or false)
			t.New:SetShown(newToys[itemID] and true or false)
			if newToys[itemID] then W.SetChip(t.New, "New", "accent") end
			paintCooldown(t)
			t:Show()
		else
			t.psID = nil
			t:Hide()
		end
	end
	toyPage.Empty:SetShown(count == 0)
	toyPage:SetHeight(6 * (TOY_H + 8))
	local learnt, total = C_ToyBox.GetNumLearnedDisplayedToys(), C_ToyBox.GetNumTotalDisplayedToys()
	return pager(toyAt, max, turn), TOY_BOX or "Toy Box", ("%d of %d toys collected · Page %d of %d"):format(learnt, total, toyAt, max)
end

---------------------------------------------------------------------------
-- Appearances (Mainline/Blizzard_Wardrobe.lua, Shared/Blizzard_Wardrobe_Sets.lua,
-- Camelot/Blizzard_Wardrobe.lua). The stock helpers that live in the
-- load-on-demand Blizzard_TransmogShared (TransmogUtil, its slot locations and
-- model setup) are copied: loading it from our code would make its globals
-- ours. CollectionWardrobeUtil (Blizzard_FrameXMLUtil, always loaded) is used.

local APPEARANCE = Enum.TransmogType and Enum.TransmogType.Appearance or 0
local MAIN = Enum.TransmogModification and Enum.TransmogModification.Main or 0
local NONE = 0 -- Constants.Transmog.NoTransmogID
local function searchType() return view == "items" and (Enum.TransmogSearchType and Enum.TransmogSearchType.Items or 1) or (Enum.TransmogSearchType and Enum.TransmogSearchType.BaseSets or 2) end
-- Forever's slot buttons (OverrideDefaults in Camelot/Blizzard_Wardrobe.lua).
local SLOTS = { "HEADSLOT", "SHOULDERSLOT", "BACKSLOT", "CHESTSLOT", "SHIRTSLOT", "TABARDSLOT", "WRISTSLOT",
	"HANDSSLOT", "WAISTSLOT", "LEGSSLOT", "FEETSLOT", "MAINHANDSLOT", "SECONDARYHANDSLOT", "RANGEDSLOT" }
local ARMOR = { HEADSLOT = 1, SHOULDERSLOT = 2, BACKSLOT = 3, CHESTSLOT = 4, SHIRTSLOT = 5, TABARDSLOT = 6, WRISTSLOT = 7,
	HANDSSLOT = 8, WAISTSLOT = 9, LEGSSLOT = 10, FEETSLOT = 11 } -- Enum.TransmogCollectionType
-- WARDROBE_MODEL_SETUP and WARDROBE_MODEL_SETUP_GEAR (Blizzard_TransmogShared.lua).
local function setup(skin, choices, obey, chest, hands, legs, feet, head)
	return { skin = skin, choices = choices, obey = obey, slots = { CHESTSLOT = chest, HANDSSLOT = hands, LEGSSLOT = legs, FEETSLOT = feet, HEADSLOT = head } }
end
local BODY = setup(true, true, true, false, false, false, false, true)
local SETUP = { HEADSLOT = setup(false, false, false, true, false, false, false, false), SHOULDERSLOT = BODY, BACKSLOT = BODY, CHESTSLOT = BODY,
	TABARDSLOT = BODY, SHIRTSLOT = BODY, WRISTSLOT = BODY, HANDSSLOT = setup(false, true, true, true, false, true, true, true), WAISTSLOT = BODY,
	LEGSSLOT = BODY, FEETSLOT = setup(false, true, true, true, true, true, false, true) }
local GEAR = { CHESTSLOT = 78420, LEGSSLOT = 78425, FEETSLOT = 78427, HANDSSLOT = 78426, HEADSLOT = 78416 }

local slots, slotSel -- the slot locations (built once), the one shown
local category, lastWeapon -- the category shown, the last weapon category picked
local lookAt = 1 -- the Items page
local chosen = {} -- visual ID -> the source picked for it ("Transmogrify as")
local setSel, setVariant = nil, {} -- the set shown; base set ID -> the variant picked
local setCache -- base sets, variants, source counts: dropped on every collection, favorite or search change
local tip -- the tooltip shown: { index, cycle, refresh }, for Tab (cycling the sources)

-- A transmog location as TransmogUtil makes one: what the C_ calls and
-- CollectionWardrobeUtil take (GetData).
local function location(slot)
	local id, icon = GetInventorySlotInfo(slot)
	return { slot = slot, slotID = id, icon = icon, type = APPEARANCE, modification = MAIN, armor = ARMOR[slot],
		GetData = function(self) return { slotID = self.slotID, type = self.type, modification = self.modification } end }
end

local function firstWeapon() return FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE or 12 end
local function lastWeaponType() return LAST_TRANSMOG_COLLECTION_WEAPON_TYPE or 29 end

local function fits(cat, loc)
	local name, isWeapon, _, mh, oh, ranged = C_TransmogCollection.GetCategoryInfo(cat)
	return (name and isWeapon and (loc.slot == "MAINHANDSLOT" and mh or loc.slot == "SECONDARYHANDSLOT" and oh or loc.slot == "RANGEDSLOT" and ranged)) and true or false
end

local function setCategory(cat)
	if cat == category then return end
	category, lookAt = cat, 1
	if not cat then return end
	C_TransmogCollection.SetSearchAndFilterCategory(cat)
	if select(2, C_TransmogCollection.GetCategoryInfo(cat)) then lastWeapon = cat end
	-- The search follows the category (SwitchSearchCategory).
	if query.items ~= "" then C_TransmogCollection.SetSearch(searchType(), query.items) end
end

-- As SetActiveSlot: armor shows its own category, a weapon slot the last
-- weapon type picked if it fits, else the first that does.
local function setSlot(loc)
	slotSel = loc
	local cat = loc.armor
	if not cat then
		if lastWeapon and fits(lastWeapon, loc) then cat = lastWeapon end
		for c = firstWeapon(), lastWeaponType() do
			if cat then break end
			if fits(c, loc) then cat = c end
		end
	end
	category = nil
	setCategory(cat)
end

-- GetUseTransmogSkin: the head and hands/feet slots show skin only while the slot is empty.
local function useSkin(slot)
	local s = SETUP[slot]
	if not s or s.skin then return true end
	if s.choices then
		local id = GetInventorySlotInfo(slot)
		if id and C_PlayerInfo.HasVisibleInvSlot and not C_PlayerInfo.HasVisibleInvSlot(id) then return true end
	end
	return false
end

-- As ItemModelBaseMixin:Reload: the player dressed for the slot (armor), or an
-- empty model for a weapon's appearance. False while the player's model is not ready.
local function dress(m, slot)
	local native = PlayerUtil and PlayerUtil.ShouldUseNativeFormInModelScene and PlayerUtil.ShouldUseNativeFormInModelScene()
	if m.psSlot == slot and m.psNative == native then return true end
	local s = SETUP[slot]
	if s and IsUnitModelReadyForUI and not IsUnitModelReadyForUI("player") then return false end
	m.psSlot, m.psNative, m.psVisual = slot, native, nil
	if not s then m:ClearModel(); return true end
	m:SetUseTransmogSkin(useSkin(slot))
	m:SetUseTransmogChoices(s.choices)
	m:SetObeyHideInTransmogFlag(s.obey)
	m:SetUnit("player", false, native)
	for k, on in pairs(s.slots) do if on then m:TryOn(GEAR[k]) end end
	return true
end

local function lightModel(m, ambient, diffuse, x, y)
	m:SetAutoDress(false)
	if CreateVector3D and CreateColor then
		m:SetLight(true, { omnidirectional = false, point = CreateVector3D(x, y, -1), ambientIntensity = ambient, ambientColor = CreateColor(1, 1, 1),
			diffuseIntensity = diffuse, diffuseColor = CreateColor(1, 1, 1) })
	end
	-- The camera again once the model has loaded (ItemModelBaseMixin:OnModelLoaded).
	m:SetScript("OnModelLoaded", function(self) if self.psCamera then Model_ApplyUICamera(self, self.psCamera) end end)
end

-- The appearances of the slot's category, as RefreshVisualsList: no hidden visual, the stock order.
local function visuals()
	if not category then return {} end
	local out = {}
	for _, v in ipairs(C_TransmogCollection.GetCategoryAppearances(category, slotSel:GetData()) or {}) do
		if not v.isHideVisual then out[#out + 1] = v end
	end
	table.sort(out, CollectionWardrobeUtil.CompareAppearance)
	return out
end

local function sourcesFor(visualID)
	return CollectionWardrobeUtil.GetSortedAppearanceSourcesForClass(visualID, C_TransmogCollection.GetClassFilter(), category, slotSel)
end

-- GetAnAppearanceSourceFromVisual: the source picked, else the first.
local function sourceOf(visualID)
	if (chosen[visualID] or NONE) ~= NONE then return chosen[visualID] end
	local s = CollectionWardrobeUtil.GetSortedAppearanceSources(visualID, category, slotSel)[1]
	return s and s.sourceID or NONE
end

-- The appearance tooltip, sources listed (CollectionWardrobeUtil.SetAppearanceTooltip);
-- Tab cycles which source it leads with, as stock (out of combat: the key
-- frame's propagation is protected then).
local function showSources(owner, sources, primary, hint)
	if #sources == 0 then return end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	local index, cycle = CollectionWardrobeUtil.SetAppearanceTooltip(GameTooltip, { sources = sources, primarySourceID = primary,
		selectedIndex = tip and tip.index, showUseError = true })
	tip = tip or {}
	tip.index, tip.cycle, tip.sources = index, cycle, sources
	ns.TooltipHint(hint .. (cycle and not InCombatLockdown() and " Tab shows its next source." or ""))
	GameTooltip:Show()
end

local function keysFor(on)
	if InCombatLockdown() then on = false end
	if on == f.psKeysOn then return end -- a Tab's redraw keeps the key it is handling
	f.psKeysOn = on
	if on then f.psKeys:SetPropagateKeyboardInput(true) end
	f.psKeys:EnableKeyboard(on)
end

local function tipLeave()
	tip = nil
	keysFor(false)
	GameTooltip:Hide()
end

-- The source the tooltip leads with, its item link.
local function tipLink()
	local s = tip and tip.sources
	if not s or #s == 0 then return end
	local i = CollectionWardrobeUtil.GetValidIndexForNumSources(tip.index or 1, #s)
	return CollectionWardrobeUtil.GetAppearanceItemHyperlink(s[i], category == (Enum.TransmogCollectionType and Enum.TransmogCollectionType.Paired))
end

-- A favorite on an appearance whose every source is still refundable or
-- tradable asks first, as TransmogUtil.ToggleFavorite.
local function setFavorite(visualID, on)
	local function apply() C_TransmogCollection.SetIsAppearanceFavorite(visualID, on); redraw() end
	if on then
		for _, s in ipairs(C_TransmogCollection.GetAppearanceSources(visualID, category, slotSel:GetData()) or {}) do
			local info = C_TransmogCollection.GetAppearanceInfoBySource(s.sourceID)
			if info and info.sourceIsCollectedPermanent then return apply() end
		end
		return W.Modal({ title = TRANSMOG_ITEM_SET_FAVORITE or "Set Favorite", text = TRANSMOG_FAVORITE_LOSE_REFUND_AND_TRADE
			or "Setting this appearance as a favorite will make it non-refundable and non-tradable.", action = OKAY or "Okay", onAccept = apply })
	end
	apply()
end

local function lookEnter(t)
	local v = t.psLook
	if not v then return end
	if C_TransmogCollection.IsNewAppearance(v.visualID) then
		C_TransmogCollection.ClearNewAppearance(v.visualID)
		t.New:Hide()
	end
	tip = { refresh = function() lookEnter(t) end, index = tip and tip.index }
	showSources(t, sourcesFor(v.visualID), chosen[v.visualID] or NONE,
		v.isCollected and "Right-click for its menu. Shift-click to link it, ctrl-click to try it on." or "Shift-click to link it, ctrl-click to try it on.")
	keysFor(tip.cycle and true or false)
end

-- ItemModelBaseMixin:OnMouseDown: a modified click links or tries it on.
local function lookDown(t)
	if t.psLook and IsModifiedClick() then
		local l = tipLink()
		if l then HandleModifiedItemClick(l) end
	end
end

-- ItemModelBaseMixin:OnMouseUp: right-click on a collected one, its favorite
-- and "Transmogrify as" (the source the model wears).
local function lookUp(t, button)
	local v = t.psLook
	if button ~= "RightButton" or not v or not v.isCollected or v.isHideVisual then return end
	local fav = C_TransmogCollection.GetIsAppearanceFavorite(v.visualID)
	local items = { { text = fav and (TRANSMOG_ITEM_UNSET_FAVORITE or "Remove Favorite") or (TRANSMOG_ITEM_SET_FAVORITE or "Set Favorite"),
		onClick = function() setFavorite(v.visualID, not fav) end } }
	local cur = chosen[v.visualID] or NONE
	local list = {}
	for _, s in ipairs(CollectionWardrobeUtil.GetSortedAppearanceSources(v.visualID, category, slotSel)) do
		if s.isCollected and CollectionWardrobeUtil.IsAppearanceUsable(s, false) then
			if cur == NONE then cur = s.sourceID end
			list[#list + 1] = { text = CollectionWardrobeUtil.GetAppearanceNameTextAndColor(s, false) or "", checked = s.sourceID == cur,
				onClick = function() chosen[v.visualID] = s.sourceID; t.psModel.psVisual = nil; redraw() end }
		end
	end
	if #list > 0 then
		items[#items + 1] = { separator = true }
		items[#items + 1] = { text = WARDROBE_TRANSMOGRIFY_AS or "Transmogrify as:", disabled = true }
		for _, it in ipairs(list) do items[#items + 1] = it end
	end
	W.ShowMenu(t, items, { minWidth = 180 })
end

local function newLook(parent)
	local t = CreateFrame("Frame", nil, parent)
	t:SetHeight(LOOK_H)
	Theme.Skin(t, "inset")
	local m = CreateFrame("DressUpModel", nil, t)
	lightModel(m, 1.05, 0, -1, 1)
	m:SetKeepModelOnHide(true)
	m:EnableMouse(true)
	m:SetScript("OnEnter", function() lookEnter(t) end)
	m:SetScript("OnLeave", tipLeave)
	m:SetScript("OnMouseDown", function() lookDown(t) end)
	m:SetScript("OnMouseUp", function(_, button) lookUp(t, button) end)
	t.psModel = m
	local top = CreateFrame("Frame", nil, t)
	top:SetAllPoints(t)
	top:SetFrameLevel(m:GetFrameLevel() + 5)
	t.Star = W.Tex(top, "OVERLAY", "star", "accent")
	t.Star:SetSize(12, 12)
	t.Star:SetPoint("TOPLEFT", top, "TOPLEFT", 4, -4)
	t.New = W.Chip(top)
	t.New:SetPoint("BOTTOM", top, "BOTTOM", 0, 4)
	return t
end

local function lookPages(n) return 1 + math.floor(math.max(n - 1, 0) / LOOKS_PER_PAGE) end

local function turnLooks(by)
	local to = math.max(1, math.min(looks.psPages or 1, lookAt + by))
	if to == lookAt then return end
	lookAt = to
	PlaySound(SOUNDKIT.UI_TRANSMOG_PAGE_TURN or SOUNDKIT.IG_ABILITY_PAGE_TURN)
	redraw()
end

-- The class the lists are filtered for (WardrobeCollectionClassDropdownMixin).
local function classFilter()
	if view == "items" then return C_TransmogCollection.GetClassFilter() end
	return C_TransmogSets.GetTransmogSetsClassFilter()
end

-- The weapon type picker (UpdateWeaponDropdown): the weapon categories the slot takes.
local function weaponMenu(anchor)
	if W.MenuShown(anchor) then return W.HideMenu() end
	local items = {}
	for c = firstWeapon(), lastWeaponType() do
		if fits(c, slotSel) then
			items[#items + 1] = { text = (C_TransmogCollection.GetCategoryInfo(c)), checked = c == category, onClick = function() setCategory(c); redraw() end }
		end
	end
	W.ShowMenu(anchor, items, { minWidth = 160 })
end

local function slotEnter(b)
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G[b.psLoc.slot] or b.psLoc.slot)
	GameTooltip:Show()
end

-- A picker: a text button with a chevron, opening a menu.
local function picker(parent, onClick)
	local b = W.Button(parent, "", onClick, { height = 26 })
	b.Chevron = W.Tex(b, "ARTWORK", "chevron-down", "textDim")
	b.Chevron:SetSize(10, 10)
	b.Chevron:SetPoint("RIGHT", b, "RIGHT", -8, 0)
	return b
end

local function setPicker(b, text)
	W.SetButtonText(b, text)
	b:SetWidth(math.max(120, b.Label:GetStringWidth() + 40))
end

local function buildLooks()
	local v = CreateFrame("Frame", nil, f.Body)
	v:EnableMouseWheel(true)
	v:SetScript("OnMouseWheel", function(_, delta) turnLooks(delta > 0 and -1 or 1) end)
	v.Slots = {}
	v.Weapon = picker(v, function(self) weaponMenu(self) end)
	v.Grid = CreateFrame("Frame", nil, v)
	v.Grid:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(SLOT + 12))
	v.Grid:SetPoint("RIGHT", v, "RIGHT")
	v.Grid:SetHeight(3 * (LOOK_H + 8))
	v.Empty = W.Text(v.Grid, "default", "textDim")
	v.Empty:SetPoint("TOPLEFT")
	v.Empty:SetText("No appearances match.")
	v.Looks = {}
	return v
end

-- The slot row: the paper doll's empty-slot icons, the one shown in the accent.
local function paintSlots()
	local x = 0
	for i, loc in ipairs(slots) do
		local b = looks.Slots[i]
		if not b then
			b = ns.ItemWell(looks, SLOT, "Button")
			b:SetScript("OnClick", function(self)
				PlaySound(SOUNDKIT.UI_TRANSMOG_GEAR_SLOT_CLICK or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				setSlot(self.psLoc)
				redraw()
			end)
			b:SetScript("OnEnter", slotEnter)
			b:SetScript("OnLeave", W.HideTooltip)
			looks.Slots[i] = b
		end
		b.psLoc = loc
		-- The stock gaps after the wrist and the feet (defaultSectionSpacing).
		if loc.slot == "HANDSSLOT" or loc.slot == "MAINHANDSLOT" then x = x + 12 end
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", looks, "TOPLEFT", x, 0)
		x = x + SLOT + 4
		ns.PaintItem(b, { icon = loc.icon })
		if loc == slotSel then local r, g, bl = Theme.Color("accent"); Theme.Border(b, r, g, bl, 1) end
	end
	local weapon = category and select(2, C_TransmogCollection.GetCategoryInfo(category))
	looks.Weapon:SetShown(weapon and true or false)
	if weapon then
		setPicker(looks.Weapon, (C_TransmogCollection.GetCategoryInfo(category)))
		looks.Weapon:ClearAllPoints()
		looks.Weapon:SetPoint("LEFT", looks, "TOPLEFT", x + 8, -SLOT / 2)
	end
end

-- A model tile as UpdateItems draws it: the camera for the visual, the
-- player trying on armor, the item alone for a weapon; border by state.
local function paintLook(t, v)
	local m = t.psModel
	t.psLook = v
	local armor = slotSel.armor
	if not dress(m, slotSel.slot) then
		-- shortcut: no event here says the player's model is ready; ask again (once a paint)
		if not looks.psWait then looks.psWait = true; C_Timer.After(0.5, function() looks.psWait = nil; redraw() end) end
	else
		local cam = C_TransmogCollection.GetAppearanceCameraID(v.visualID)
		if m.psCamera ~= cam then Model_ApplyUICamera(m, cam); m.psCamera = cam end
		if m.psVisual ~= v.visualID then
			m.psVisual = v.visualID
			if not v.canDisplayOnPlayer then
				if armor then m:UndressSlot(slotSel.slotID) else m:ClearModel() end
			elseif armor then
				m:TryOn(sourceOf(v.visualID))
			else
				m:SetItemAppearance(v.visualID)
			end
		end
	end
	m:SetDesaturation(v.canDisplayOnPlayer and 0 or 1)
	if not v.isCollected then
		Theme.Border(t, Theme.Color("textMuted"))
	elseif not v.isUsable then
		local r, g, b = Theme.Color("danger"); Theme.Border(t, r, g, b, 1)
	else
		Theme.Border(t, Theme.Wash("border"))
	end
	t.Star:SetShown(v.isFavorite and true or false)
	local new = C_TransmogCollection.IsNewAppearance(v.visualID)
	t.New:SetShown(new and true or false)
	if new then W.SetChip(t.New, "New", "accent") end
end

local function paintItems()
	if not slotSel then setSlot(slots[1]) end
	paintSlots()
	local list = visuals()
	local max = lookPages(#list)
	looks.psPages = max
	lookAt = math.min(lookAt, max)
	looks:SetWidth(f.BodyWidth)
	local w = (f.BodyWidth - (LOOK_COLS - 1) * 8) / LOOK_COLS
	for i = 1, LOOKS_PER_PAGE do
		local v = list[(lookAt - 1) * LOOKS_PER_PAGE + i]
		local t = looks.Looks[i] or newLook(looks.Grid)
		looks.Looks[i] = t
		if v then
			local k = i - 1
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", looks.Grid, "TOPLEFT", (k % LOOK_COLS) * (w + 8), -math.floor(k / LOOK_COLS) * (LOOK_H + 8))
			t:SetWidth(w)
			-- The stock tile's 78 by 104 (WardrobeItemsModelTemplate); the mouse takes the whole tile.
			local pad = fitAspect(t.psModel, t, 78, 104)
			t.psModel:SetHitRectInsets(-pad, -pad, 0, 0)
			t:Show()
			paintLook(t, v)
		else
			t.psLook = nil
			t:Hide()
		end
	end
	looks.Empty:SetShown(#list == 0)
	looks:SetHeight(SLOT + 12 + 3 * (LOOK_H + 8))
	local sub
	if C_TransmogCollection.IsSearchInProgress(searchType()) then
		sub = "Searching…"
	else
		sub = ("%d of %d collected · Page %d of %d"):format(C_TransmogCollection.GetFilteredCategoryCollectedCount(category or 0),
			C_TransmogCollection.GetFilteredCategoryTotal(category or 0), lookAt, max)
	end
	return pager(lookAt, max, turnLooks), WARDROBE or "Appearances", sub
end

-- Sets: the base sets (favorites first: WardrobeSetsDataProviderMixin), each
-- with its variants; the selected one on the player in the detail pane.

-- SortSets, as the data provider orders them.
local function sortSets(list, reverse, ignorePatch, ignoreCollected)
	table.sort(list, function(a, b)
		local fa, fb = a.favoriteSetID and true or false, b.favoriteSetID and true or false
		if fa ~= fb then return fa end
		if (a.favorite or false) ~= (b.favorite or false) then return a.favorite and true or false end
		if not ignoreCollected and (a.collected or false) ~= (b.collected or false) then return a.collected and true or false end
		if a.expansionID ~= b.expansionID then return (a.expansionID or 0) > (b.expansionID or 0) end
		if not ignorePatch and a.patchID ~= b.patchID then return (a.patchID or 0) > (b.patchID or 0) end
		if a.uiOrder ~= b.uiOrder then if reverse then return (a.uiOrder or 0) < (b.uiOrder or 0) end return (a.uiOrder or 0) > (b.uiOrder or 0) end
		if reverse then return a.setID < b.setID end
		return a.setID > b.setID
	end)
end

local function cache()
	if not setCache then setCache = { variants = {}, counts = {}, byID = {} } end
	return setCache
end

local function variants(base)
	local c = cache()
	if not c.variants[base] then
		local list = C_TransmogSets.GetVariantSets(base) or {}
		if #list > 0 then
			list[#list + 1] = c.byID[base] or C_TransmogSets.GetSetInfo(base)
			sortSets(list, true, true, true)
		end
		c.variants[base] = list
	end
	return c.variants[base]
end

local function baseSets()
	local c = cache()
	if not c.base then
		c.base = C_TransmogSets.GetBaseSets() or {}
		for _, s in ipairs(c.base) do c.byID[s.setID] = s end
		-- DetermineFavorites: a base set is a favorite when one of its variants is.
		for _, s in ipairs(c.base) do
			s.favoriteSetID = s.favorite and s.setID or nil
			if not s.favoriteSetID then
				for _, vs in ipairs(variants(s.setID)) do if vs.favorite then s.favoriteSetID = vs.setID; break end end
			end
		end
		sortSets(c.base, false, false, true)
	end
	return c.base
end

local function counts(setID)
	local c = cache()
	if not c.counts[setID] then
		local got, all, list = 0, 0, C_TransmogSets.GetSetPrimaryAppearances(setID) or {}
		for _, a in ipairs(list) do
			all = all + 1
			if a.collected then got = got + 1 end
		end
		c.counts[setID] = { got, all, list }
	end
	return c.counts[setID][1], c.counts[setID][2], c.counts[setID][3]
end

-- GetSetSourceTopCounts: the base set's best variant.
local function topCounts(base)
	local got, all = counts(base)
	for _, vs in ipairs(variants(base)) do
		local g, a = counts(vs.setID)
		if g > got then got, all = g, a end
	end
	return got, all
end

local function isNew(base)
	if C_TransmogSets.SetHasNewSources(base) then return true end
	for _, vs in ipairs(variants(base)) do if C_TransmogSets.SetHasNewSources(vs.setID) then return true end end
	return false
end

-- GetSortedSetSources: the set's pieces in the slots' order.
local function pieces(setID)
	local out = {}
	for _, a in ipairs(select(3, counts(setID))) do
		local s = C_TransmogCollection.GetSourceInfo(a.appearanceID)
		if s then
			out[#out + 1] = { sourceID = a.appearanceID, collected = a.collected, itemID = s.itemID, invType = s.invType, visualID = s.visualID,
				order = EJ_GetInvTypeSortOrder and EJ_GetInvTypeSortOrder(s.invType) or 0 }
		end
	end
	table.sort(out, function(a, b) if a.order == b.order then return a.itemID < b.itemID end return a.order < b.order end)
	return out
end

-- GetDefaultSetIDForBaseSet: a variant with new pieces, the one picked
-- before, the favorite, else the most collected (higher difficulty on ties).
local function defaultSet(base)
	local b = cache().byID[base]
	if isNew(base) then
		if C_TransmogSets.SetHasNewSources(base) then return base end
		for _, vs in ipairs(variants(base)) do if C_TransmogSets.SetHasNewSources(vs.setID) then return vs.setID end end
	end
	if setVariant[base] then return setVariant[base] end
	if b and b.favoriteSetID then return b.favoriteSetID end
	local best, bestID = 0, nil
	for _, vs in ipairs(variants(base)) do
		local got = counts(vs.setID)
		if got > 0 and got >= best then best, bestID = got, vs.setID end
	end
	return bestID or base
end

local function selectSet(setID)
	setSel = setID
	local base = C_TransmogSets.GetBaseSetID(setID)
	if #variants(base) > 0 then setVariant[base] = setID end
end

local function setEnter(r)
	local s = r.psSet
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(s.name or "")
	if (s.label or "") ~= "" then GameTooltip:AddLine(s.label, 1, 1, 1, true) end
	ns.TooltipHint("Click to see it. Right-click for its menu.")
	GameTooltip:Show()
end

-- The stock row menu (MENU_WARDROBE_SETS_SET): the favorite, on the variant shown.
local function setMenu(r)
	local base = r.psSet.setID
	local b = cache().byID[base]
	local fav = b and b.favoriteSetID ~= nil
	local target = fav and b.favoriteSetID or defaultSet(base)
	local text = fav and (TRANSMOG_ITEM_UNSET_FAVORITE or "Remove Favorite") or (TRANSMOG_ITEM_SET_FAVORITE or "Set Favorite")
	if #variants(base) > 0 then
		local info = C_TransmogSets.GetSetInfo(target)
		local fmt = fav and TRANSMOG_SETS_UNFAVORITE_WITH_DESCRIPTION or TRANSMOG_SETS_FAVORITE_WITH_DESCRIPTION
		if fmt and info and info.description then text = fmt:format(info.description) end
	end
	W.ShowMenu(r, { { text = text, onClick = function()
		C_TransmogSets.SetIsFavorite(target, not fav)
		setCache = nil
		redraw()
	end } }, { minWidth = 180 })
end

local function setClick(r, button)
	if button == "RightButton" then return setMenu(r) end
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	selectSet(defaultSet(r.psSet.setID))
	redraw()
end

-- WardrobeSetsScrollFrameButtonMixin:Init: a base set hidden until collected
-- shows through a collected variant; colour by its best variant's progress.
local function paintSetRow(r, base)
	r.psMount, r.psPet, r.psSet = nil, nil, base
	r:SetScript("OnClick", setClick)
	r:SetScript("OnDragStart", nil)
	r:SetScript("OnEnter", setEnter)
	r.Cooldown:Clear()
	local shownSet = base
	if base.hiddenUntilCollected and not base.collected then shownSet = (C_TransmogSets.GetVariantSets(base.setID) or {})[1] or base end
	local got, all = topCounts(base.setID)
	local done = shownSet.collected or got == all
	local p = pieces(shownSet.setID)[1]
	local icon = p and select(5, C_Item.GetItemInfoInstant(p.itemID)) or QUESTION_MARK_ICON
	ns.PaintItem(r.Well, { icon = icon, desat = got == 0, unusable = shownSet.validForCharacter == false })
	paintBase(r, { on = setSel and C_TransmogSets.GetBaseSetID(setSel) == base.setID, name = shownSet.name, sub = shownSet.label ~= "" and shownSet.label or nil,
		favorite = base.favoriteSetID, new = isNew(base.setID), receding = got == 0, color = done and "text" or got == 0 and "textMuted" or "success" })
end

-- The variant picker (MENU_WARDROBE_VARIANT_SETS): "description (n/m)".
local function variantMenu(anchor)
	if W.MenuShown(anchor) then return W.HideMenu() end
	local items = {}
	for _, vs in ipairs(variants(C_TransmogSets.GetBaseSetID(setSel))) do
		if not vs.hiddenUntilCollected or vs.collected then
			local got, all = counts(vs.setID)
			items[#items + 1] = { text = ("%s (%d/%d)"):format(vs.description or vs.name or "", got, all), checked = vs.setID == setSel,
				onClick = function() selectSet(vs.setID); redraw() end }
		end
	end
	W.ShowMenu(anchor, items, { minWidth = 180 })
end

-- A piece's sources, as WardrobeSetsCollectionMixin:RefreshAppearanceTooltip.
local function pieceSources(w)
	local slot = C_Transmog.GetSlotForInventoryType(w.psPiece.invType)
	local s = C_TransmogSets.GetSourcesForSlot(setSel, slot) or {}
	if #s == 0 then s[1] = C_TransmogCollection.GetSourceInfo(w.psPiece.sourceID) end
	CollectionWardrobeUtil.SortSources(s, s[1].visualID, w.psPiece.sourceID)
	return s, slot
end

local function pieceEnter(w)
	local s, slot = pieceSources(w)
	if w.New:IsShown() then
		w.New:Hide()
		C_TransmogSets.ClearSetNewSourcesForSlot(setSel, slot)
		setCache = nil
	end
	tip = { refresh = function() pieceEnter(w) end, index = tip and tip.index }
	showSources(w, s, w.psPiece.sourceID, w.psPiece.collected and "Right-click for its menu. Shift-click to link it, ctrl-click to try it on."
		or "Shift-click to link it, ctrl-click to try it on.")
	keysFor(tip.cycle and true or false)
end

local function pieceClick(w, button)
	local p = w.psPiece
	if shiftClick() then
		local s = tip and tip.sources or pieceSources(w)
		local info = C_TransmogCollection.GetAppearanceSourceInfo(s[CollectionWardrobeUtil.GetValidIndexForNumSources(tip and tip.index or 1, #s)].sourceID)
		if info and info.itemLink then HandleModifiedItemClick(info.itemLink) end
	elseif IsModifiedClick("DRESSUP") then
		DressUpVisual(p.sourceID)
	elseif button == "RightButton" and p.collected then
		local fav = C_TransmogCollection.GetIsAppearanceFavorite(p.visualID)
		W.ShowMenu(w, { { text = fav and (TRANSMOG_ITEM_UNSET_FAVORITE or "Remove Favorite") or (TRANSMOG_ITEM_SET_FAVORITE or "Set Favorite"),
			onClick = function() C_TransmogCollection.SetIsAppearanceFavorite(p.visualID, not fav); redraw() end } }, { minWidth = 160 })
	end
end

-- The sets' model turns by drag (the stock details model's rotation; no pan or zoom).
function setModelTurn(m)
	lightModel(m, 0.7, 0.6, -1, 0)
	m:SetKeepModelOnHide(true)
	m:EnableMouse(true)
	m:SetScript("OnMouseDown", function(self, button) if button == "LeftButton" then self.psTurn = GetCursorPosition() end end)
	m:SetScript("OnMouseUp", function(self) self.psTurn = nil end)
	m:SetScript("OnHide", function(self) self.psTurn = nil end)
	m:SetScript("OnUpdate", function(self)
		if not self.psTurn then return end
		local x = GetCursorPosition()
		self:SetFacing((self:GetFacing() or 0) + (x - self.psTurn) * 0.02)
		self.psTurn = x
	end)
end

-- DisplaySet: the player in the set's pieces, its pieces in a row along the pane's foot.
local function paintSetDetail()
	local info = setSel and C_TransmogSets.GetSetInfo(setSel)
	detail.Empty:SetText("No sets match.")
	paintDetail(info and info.name, false, info and info.label, nil, true)
	detail.psPieces = detail.psPieces or {}
	local list = info and pieces(setSel) or {}
	local m = detail.Dress
	if info and m.psSet ~= setSel then
		m.psSet = setSel
		local cam = C_TransmogSets.GetCameraIDs()
		m.psCamera = cam
		m:SetUnit("player", false, PlayerUtil and PlayerUtil.ShouldUseNativeFormInModelScene and PlayerUtil.ShouldUseNativeFormInModelScene())
		Model_ApplyUICamera(m, cam)
		m:Undress()
		for _, p in ipairs(list) do m:TryOn(p.sourceID) end
	end
	local x0 = -math.floor((#list - 1) * 37 / 2)
	for i, p in ipairs(list) do
		local w = detail.psPieces[i]
		if not w then
			w = ns.ItemWell(detail.Top, 32, "Button")
			w:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			w:SetScript("OnClick", pieceClick)
			w:SetScript("OnEnter", pieceEnter)
			w:SetScript("OnLeave", tipLeave)
			w.Star = W.Tex(w, "OVERLAY", "star", "accent")
			w.Star:SetSize(10, 10)
			w.Star:SetPoint("CENTER", w, "TOPLEFT", 3, -3)
			w.New = W.Chip(w)
			w.New:SetPoint("TOP", w, "BOTTOM", 0, -2)
			detail.psPieces[i] = w
		end
		w.psPiece = p
		w:ClearAllPoints()
		w:SetPoint("BOTTOM", detail.Top, "BOTTOM", x0 + (i - 1) * 37, 28)
		local s = C_TransmogCollection.GetSourceInfo(p.sourceID)
		ns.PaintItem(w, { icon = C_TransmogCollection.GetSourceIcon(p.sourceID), quality = p.collected and s and s.quality or nil, desat = not p.collected })
		w.Icon:SetAlpha(p.collected and 1 or 0.3)
		w.Star:SetShown(C_TransmogCollection.GetIsAppearanceFavorite(p.visualID) and true or false)
		local new = p.collected and C_TransmogSets.SetHasNewSourcesForSlot(setSel, C_Transmog.GetSlotForInventoryType(p.invType))
		w.New:SetShown(new and true or false)
		if new then W.SetChip(w.New, "New", "accent") end
		w:Show()
	end
	for i = #list + 1, #detail.psPieces do detail.psPieces[i]:Hide() end
	-- The variants, when more than one shows.
	local n = 0
	if info then for _, vs in ipairs(variants(C_TransmogSets.GetBaseSetID(setSel))) do if not vs.hiddenUntilCollected or vs.collected then n = n + 1 end end end
	detail.Variant:SetShown(n > 1)
	if n > 1 then setPicker(detail.Variant, info.description or "") end
end

local function paintSets()
	local list = baseSets()
	if not (setSel and C_TransmogSets.IsSetVisible(setSel)) then setSel = list[1] and defaultSet(list[1].setID) or nil end
	paintList(#list, function(r, i) paintSetRow(r, list[i]) end)
	paintSetDetail()
	local sub
	if C_TransmogCollection.IsSearchInProgress(searchType()) then
		sub = "Searching…"
	else
		sub = ("%d of %d sets collected"):format(C_TransmogSets.GetFilteredBaseSetsCounts())
	end
	return {}, WARDROBE or "Appearances", sub
end

-- The search for the view shown (stock clears the other view's as it hides).
local function lookSearch()
	local text = query[view]
	if text == "" then C_TransmogCollection.ClearSearch(searchType()) else C_TransmogCollection.SetSearch(searchType(), text) end
	lookAt, setCache = 1, nil
end

local function leaveLooks()
	C_TransmogCollection.EndSearch()
	C_TransmogCollection.ClearSearch(Enum.TransmogSearchType and Enum.TransmogSearchType.Items or 1)
	C_TransmogCollection.ClearSearch(Enum.TransmogSearchType and Enum.TransmogSearchType.BaseSets or 2)
	if tip then tipLeave() else keysFor(false) end
end

-- Entering Items: Forever shows collected appearances only (InitItemsFilterButtonSetupMenu).
local function enterView()
	if view == "sets" and not C_TransmogSets.HasAnyValidSets() then view = "items" end -- no sets: no Sets tab (UpdateTabButtons)
	if view == "items" then
		C_TransmogCollection.SetUncollectedShown(false)
		C_TransmogCollection.SetCollectedShown(true)
	end
	lookSearch()
end

local VIEWS = { { key = "items", label = ITEMS or "Items" }, { key = "sets", label = WARDROBE_SETS or "Sets" } }

local function setView(key)
	if key == view then return end
	C_TransmogCollection.ClearSearch(searchType())
	view = key
	enterView()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	refresh()
end

---------------------------------------------------------------------------
-- Filters: the stock filter menus, flat (Polestar's menu has no submenus):
-- the source, type and expansion lists each open as a menu of their own from
-- a row. The menu opens again after each pick; the page redraws at once.

local filterMenu -- below

local function refilter()
	if page == "toys" then toyAt = 1 elseif page == "appearances" then lookAt, setCache = 1, nil end
end

-- A checked item over a client getter and setter.
local function check(text, get, set, sub)
	return { text = text, checked = get() and true or false, onClick = function()
		set(not get())
		refilter()
		refresh()
		filterMenu(f.psFilter, sub)
	end }
end

local function all(set, sub)
	return { text = CHECK_ALL or "Check All", onClick = function() set(true); refilter(); refresh(); filterMenu(f.psFilter, sub) end },
		{ text = UNCHECK_ALL or "Uncheck All", onClick = function() set(false); refilter(); refresh(); filterMenu(f.psFilter, sub) end }
end

local function open(text, sub) return { text = text .. "…", onClick = function() filterMenu(f.psFilter, sub) end } end
local function back() return { text = "Back", onClick = function() filterMenu(f.psFilter) end } end

local MOUNT_TYPES -- the stock mountFilterTypeStrings, by Enum.MountType
local function mountItems(sub)
	local J = C_MountJournal
	local items = {}
	if sub == "sources" then
		items = { back(), { separator = true }, all(J.SetAllSourceFilters, sub) } -- both of all()'s items: the last expression
		for i = 1, C_PetJournal.GetNumPetSources() do
			if J.IsValidSourceFilter(i) then
				items[#items + 1] = check(_G["BATTLE_PET_SOURCE_" .. i] or tostring(i), function() return J.IsSourceChecked(i) end, function(v) J.SetSourceFilter(i, v) end, sub)
			end
		end
		return items
	end
	local function setting(k) return function() return J.GetCollectedFilterSetting(k) end, function(v) J.SetCollectedFilterSetting(k, v) end end
	items[1] = check(COLLECTED or "Collected", setting(LE_MOUNT_JOURNAL_FILTER_COLLECTED))
	items[2] = check(NOT_COLLECTED or "Not Collected", setting(LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED))
	items[3] = check(MOUNT_JOURNAL_FILTER_UNUSABLE or "Unusable", setting(LE_MOUNT_JOURNAL_FILTER_UNUSABLE))
	items[4] = { separator = true }
	items[5] = { text = MOUNT_JOURNAL_FILTER_TYPE or "Type", disabled = true }
	local T = Enum.MountType
	MOUNT_TYPES = MOUNT_TYPES or { [T.Ground or 0] = MOUNT_JOURNAL_FILTER_GROUND, [T.Flying or 1] = MOUNT_JOURNAL_FILTER_FLYING,
		[T.Aquatic or 2] = MOUNT_JOURNAL_FILTER_AQUATIC, [T.Dragonriding or 3] = MOUNT_JOURNAL_FILTER_DRAGONRIDING,
		[T.RideAlong or 4] = MOUNT_JOURNAL_FILTER_RIDEALONG }
	for i = 1, Enum.MountTypeMeta and Enum.MountTypeMeta.NumValues or 0 do
		if J.IsValidTypeFilter(i) then
			items[#items + 1] = check(MOUNT_TYPES[i - 1] or tostring(i), function() return J.IsTypeChecked(i) end, function(v) J.SetTypeFilter(i, v) end)
		end
	end
	items[#items + 1] = { separator = true }
	items[#items + 1] = open(SOURCES or "Sources", "sources")
	return items
end

local function toyItems(sub)
	local B, I = C_ToyBox, C_ToyBoxInfo
	if sub == "sources" then
		local a, b = all(B.SetAllSourceTypeFilters, sub)
		local items = { back(), { separator = true }, a, b }
		for i = 1, C_PetJournal.GetNumPetSources() do
			if I.IsToySourceValid(i) then
				items[#items + 1] = check(_G["BATTLE_PET_SOURCE_" .. i] or tostring(i), function() return B.IsSourceTypeFilterChecked(i) end, function(v) B.SetSourceTypeFilter(i, v) end, sub)
			end
		end
		return items
	elseif sub == "expansions" then
		local a, b = all(B.SetAllExpansionTypeFilters, sub)
		local items = { back(), { separator = true }, a, b }
		for i = 1, GetNumExpansions() do
			items[#items + 1] = check(_G["EXPANSION_NAME" .. (i - 1)] or tostring(i), function() return B.IsExpansionTypeFilterChecked(i) end, function(v) B.SetExpansionTypeFilter(i, v) end, sub)
		end
		return items
	end
	-- "Usable only" is the client's unusable setting, inverted (as stock).
	return {
		check(COLLECTED or "Collected", B.GetCollectedShown, B.SetCollectedShown),
		check(NOT_COLLECTED or "Not Collected", B.GetUncollectedShown, B.SetUncollectedShown),
		check(PET_JOURNAL_FILTER_USABLE_ONLY or "Usable Only", function() return not B.GetUnusableShown() end, function(v) B.SetUnusableShown(not v) end),
		{ separator = true },
		open(SOURCES or "Sources", "sources"),
		open(EXPANSION_FILTER_TEXT or "Expansions", "expansions"),
	}
end

-- PetJournal_InitFilterDropdown: Collected and Not Collected only.
local function petItems()
	local P = C_PetJournal
	local function setting(k) return function() return P.IsFilterChecked(k) end, function(v) P.SetFilterChecked(k, v) end end
	return { check(COLLECTED or "Collected", setting(LE_PET_JOURNAL_FILTER_COLLECTED)), check(NOT_COLLECTED or "Not Collected", setting(LE_PET_JOURNAL_FILTER_NOT_COLLECTED)) }
end

-- The class the lists are for (WardrobeCollectionClassDropdownMixin), a menu of its own.
local function classItems()
	local items = { back(), { separator = true } }
	for id = 1, GetNumClasses() do
		local info = C_CreatureInfo.GetClassInfo(id)
		if info then
			items[#items + 1] = { text = info.className, checked = classFilter() == info.classID, onClick = function()
				if view == "items" then
					-- Not every class can use the same weapons: back to the head (SetClassFilter).
					if not category or select(2, C_TransmogCollection.GetCategoryInfo(category)) then setSlot(slots[1]) end
					C_TransmogCollection.SetClassFilter(info.classID)
				else
					C_TransmogSets.SetTransmogSetsClassFilter(info.classID)
				end
				refilter()
				refresh()
				filterMenu(f.psFilter)
			end }
		end
	end
	return items
end

local function classRow()
	local info = C_CreatureInfo.GetClassInfo(classFilter())
	return open((CLASS or "Class") .. ": " .. (info and info.className or ""), "class")
end

-- Forever's items filter: the source types, flat (Camelot/Blizzard_Wardrobe.lua);
-- the class first.
local function itemItems(sub)
	if sub == "class" then return classItems() end
	local T = C_TransmogCollection
	local a, b = all(T.SetAllSourceTypeFilters)
	local items = { classRow(), { separator = true }, a, b }
	for i = 1, T.GetNumTransmogSources() do
		if T.IsValidTransmogSource(i) then
			items[#items + 1] = check(_G["TRANSMOG_SOURCE_" .. i] or tostring(i), function() return T.IsSourceTypeFilterChecked(i) end, function(v) T.SetSourceTypeFilter(i, v) end)
		end
	end
	return items
end

-- InitBaseSetsFilterButton; the class first.
local function setItems(sub)
	if sub == "class" then return classItems() end
	local S = C_TransmogSets
	local function setting(k) return function() return S.GetBaseSetsFilter(k) end, function(v) S.SetBaseSetsFilter(k, v) end end
	return { classRow(), { separator = true }, check(COLLECTED or "Collected", setting(LE_TRANSMOG_SET_FILTER_COLLECTED)), check(NOT_COLLECTED or "Not Collected", setting(LE_TRANSMOG_SET_FILTER_UNCOLLECTED)),
		{ separator = true }, check(TRANSMOG_SET_PVE or "PvE", setting(LE_TRANSMOG_SET_FILTER_PVE)), check(TRANSMOG_SET_PVP or "PvP", setting(LE_TRANSMOG_SET_FILTER_PVP)) }
end

local FILTERS = {
	mounts = { mountItems, function() return C_MountJournal.IsUsingDefaultFilters() end, function() C_MountJournal.SetDefaultFilters() end },
	pets = { petItems, petsDefault, function() C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED, true); C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED, true) end },
	toys = { toyItems, function() return C_ToyBoxInfo.IsUsingDefaultFilters() end, function() C_ToyBoxInfo.SetDefaultFilters() end },
	items = { itemItems, function() return C_TransmogCollection.IsUsingDefaultFilters() end, function() C_TransmogCollection.SetDefaultFilters() end },
	sets = { setItems, function() return C_TransmogSets.IsUsingDefaultBaseSetsFilters() end, function() C_TransmogSets.SetDefaultBaseSetsFilters() end },
}

local function isDefault() return FILTERS[qkey()][2]() end

function filterMenu(anchor, sub)
	if not sub and W.MenuShown(anchor) then return W.HideMenu() end
	local fl = FILTERS[qkey()]
	local items = fl[1](sub)
	if not sub and not isDefault() then
		items[#items + 1] = { separator = true }
		items[#items + 1] = { text = "Reset filters", onClick = function()
			fl[3]()
			refilter()
			refresh()
		end }
	end
	W.ShowMenu(anchor, items, { minWidth = 180 })
end

---------------------------------------------------------------------------
-- The window.

-- The "..." menu: the stock journal's "show player" toggle on Mounts.
local function options()
	if page ~= "mounts" then return {} end
	return { { text = "Show character on mount", checked = GetCVarBool("mountJournalShowPlayer"), onClick = function()
		SetCVar("mountJournalShowPlayer", GetCVarBool("mountJournalShowPlayer") and "0" or "1")
		shown = nil
		redraw()
	end } }
end

-- Leaving a page clears what its stock hide does: the mounts' and pets' "new"
-- marks (MountJournal_OnHide, PetJournal_OnHide), the wardrobe's search.
local function leave()
	if page == "mounts" then C_MountJournal.ClearRecentFanfares()
	elseif page == "pets" then C_PetJournal.ClearRecentFanfares()
	elseif page == "appearances" then leaveLooks() end
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 780, height = 540, sidebar = 0, rail = true, searchPlaceholder = "Search", onSearch = function(text)
		text = text or ""
		local k = page and qkey()
		if not k or query[k] == text then return end
		query[k] = text
		if page == "mounts" then C_MountJournal.SetSearch(text)
		elseif page == "pets" then C_PetJournal.SetSearchFilter(text)
		elseif page == "toys" then C_ToyBox.SetFilterString(text); toyAt = 1
		else lookSearch() end
		redraw()
	end })
	ns.Dock(f)
	ns.WindowMenu(f, "collections", options)
	ns.Plain(f, f.psRail)
	ns.Compact(f)
	f.psFilter = W.IconButton(f.TabRow, "sliders", 30, "Filter", function(self) filterMenu(self) end, 14)
	Theme.Skin(f.psFilter, "editbox")
	ns.TopNav(f, {}, nil, function() end) -- the search and filter onto the tab row
	f.psKeepTabRow = true
	f.psStatus = W.Text(f.TabRow, "default", "textMuted")
	nav = W.Scroll(f.Main)
	f.psNav = nav
	nav:SetPoint("TOPLEFT", f.Scroll, "TOPLEFT", 0, 0)
	nav:SetPoint("BOTTOMLEFT", f.Scroll, "BOTTOMLEFT", 0, 0)
	nav:SetWidth(LISTW)
	nav:SetFrameLevel(f.Scroll:GetFrameLevel() + 5)
	nav.Rule = W.Fill(nav, "border", "OVERLAY", 0)
	nav.Rule:ClearAllPoints()
	nav.Rule:SetPoint("TOPRIGHT")
	nav.Rule:SetPoint("BOTTOMRIGHT")
	nav.Rule:SetWidth(1)
	detail = buildDetail()
	detail.Variant = picker(detail.Top, function(self) variantMenu(self) end)
	detail.Variant:SetPoint("TOPRIGHT", detail.Top, "TOPRIGHT", -SIDE, -SIDE)
	toyPage = buildToys()
	looks = buildLooks()
	f.psDetail, f.psToys, f.psLooks = detail, toyPage, looks
	slots = {}
	for _, s in ipairs(SLOTS) do
		if s ~= "RANGEDSLOT" or not C_PaperDollInfo.IsRangedSlotShown or C_PaperDollInfo.IsRangedSlotShown() then slots[#slots + 1] = location(s) end
	end
	-- Tab cycles the sources in an appearance tooltip (WardrobeCollectionFrameMixin:OnKeyDown);
	-- every other key passes on. Keyboard on only while such a tooltip shows, out of combat.
	f.psKeys = CreateFrame("Frame", nil, f)
	f.psKeys:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown() then return end
		local cycle = tip and tip.cycle and key == (WARDROBE_CYCLE_KEY or "TAB")
		self:SetPropagateKeyboardInput(not cycle)
		if cycle then
			tip.index = (tip.index or 1) + (IsShiftKeyDown() and -1 or 1)
			tip.refresh()
		end
	end)
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end)
	f:HookScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
		leave()
	end)
	Polestar.CloseOnEscape(NAME)
end

local function paintRail()
	local items = {}
	for _, p in ipairs(PAGES) do if valid(p.key) then items[#items + 1] = p end end
	ns.GameRail(f, items, page, function(key) M.Show(key) end, { slim = true })
	for i, p in ipairs(items) do f.railButtons[i].psTip = p.label end
end

local PAINT = { mounts = paintMounts, pets = paintPets, toys = paintToys, items = paintItems, sets = paintSets }

function refresh()
	paintRail()
	local k = qkey()
	local list = k == "mounts" or k == "pets" or k == "sets"
	nav:SetShown(list)
	detail:SetShown(list)
	detail.Empty:SetShown(false)
	detail.Variant:SetShown(false)
	toyPage:SetShown(k == "toys")
	looks:SetShown(k == "items")
	if k ~= "sets" and detail.psPieces then for _, w in ipairs(detail.psPieces) do w:Hide() end end
	if (f.Search:GetText() or "") ~= query[k] then f.Search:SetText(query[k]) end
	-- With the client's "only show collected" there is one filter setting: none,
	-- as stock (the wardrobe keeps its own filter).
	local filters = page == "appearances" or not GetCVarBool("onlyShowCollectedItemsInJournal")
	f.psFilter:SetShown(filters)
	f.Search:ClearAllPoints()
	f.Search:SetPoint("RIGHT", filters and f.psFilter or f.TabRow, filters and "LEFT" or "RIGHT", filters and -6 or -f.psPad, 0)
	local lit = not isDefault()
	W.SetIconState(f.psFilter, lit)
	f.psFilter.psTip = lit and "Filter (on)" or "Filter"
	local foot, title, sub = PAINT[k]()
	-- The Appearances views on the tab row; the page's fact after them, else on its left (as Guild's).
	local views
	-- No valid sets (Forever, live): no Items | Sets switch at all, as stock hides its Sets tab (UpdateTabButtons).
	if page == "appearances" and C_TransmogSets.HasAnyValidSets() then views = VIEWS end
	W.ShellTabs(f, views, view, setView)
	f.psStatus:ClearAllPoints()
	local last = views and #views > 1 and f.tabButtons[#views]
	if last then f.psStatus:SetPoint("LEFT", last, "RIGHT", 16, 0) else f.psStatus:SetPoint("LEFT", f.TabRow, "LEFT", f.psPad, 0) end
	W.ShellTitle(f, "Collections", title)
	f.psStatus:SetText(sub)
	ns.Footer(f, {}, foot)
	for i, d in ipairs(foot) do
		local b = f.footerButtons.right[i]
		ns.SetEnabled(b, d.on, d.why)
		b.psTip = d.on and d.tip or nil
	end
	-- Laid out after the footer (Sets has none): the list column and the detail pane fill the view.
	if list then
		W.SetScrollContent(nav, nav.psH, f.psViewH)
		detail:ClearAllPoints()
		detail:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad + LISTW, -16)
		detail:SetSize(f.BodyWidth - LISTW, f.psViewH - 32)
		fitAspect(detail.Model, detail, 407, 514)
		fitAspect(detail.Pet, detail, 407, 514)
		-- Stock PetCard.modelScene's ViewInsets (top 300, bottom -50 on its 514): the view starts
		-- below the card's info and runs past its foot, so the pet lands mid-card, not at the top.
		local s = detail.Pet:GetHeight() / 514
		if detail.Pet.SetViewInsets then detail.Pet:SetViewInsets(0, 0, 300 * s, -50 * s) end
	end
	local grid = k == "toys" and toyPage or k == "items" and looks
	if grid then
		grid:ClearAllPoints()
		grid:SetPoint("TOPLEFT", f.Body, "TOPLEFT", f.psPad, -16)
	end
	W.ShellBody(f, grid and grid:GetHeight() + 32 or f.psViewH)
end

-- The page shown: the one asked for, else the last one (kept in PolestarUIDB),
-- else the first the client lets show.
local function pick(key)
	key = key or page or (PolestarUIDB and PolestarUIDB.collectionsPage) or "mounts"
	if BY_KEY[key] and valid(key) then return key end
	for _, p in ipairs(PAGES) do if valid(p.key) then return p.key end end
	return "mounts"
end

function M.Show(key)
	if not f then build() end
	key = pick(key)
	if key ~= page then
		leave()
		shown = nil
		if key == "toys" then C_ToyBox.ForceToyRefilter() end -- as ToyBox_OnShow
		page = key
		if key == "appearances" then enterView() end
	elseif not f:IsShown() and key == "appearances" then
		enterView()
	end
	if PolestarUIDB then PolestarUIDB.collectionsPage = page end
	refresh()
	f:Show()
end

-- As ToggleCollectionsJournal(tab): open on that page, close if already on it.
function M.Toggle(key)
	if f and f:IsShown() and (key == nil or key == page) then
		f:Hide()
	else
		M.Show(key)
	end
end

function M.Enable()
	-- Every Collections key and the micro button open ours; the stock journal,
	-- whose show touches the micro buttons, is never touched (docs/CLIENT.md,
	-- rule 8). The game's other doors (new-collectible toasts, mount, pet and
	-- transmog links) stay the game's.
	ns.Doors("collections", "Collections", {
		TOGGLECOLLECTIONS = function() M.Toggle() end,
		TOGGLECOLLECTIONSMOUNTJOURNAL = function() M.Toggle("mounts") end,
		TOGGLECOLLECTIONSPETJOURNAL = function() M.Toggle("pets") end,
		TOGGLECOLLECTIONSTOYBOX = function() M.Toggle("toys") end,
		TOGGLECOLLECTIONSWARDROBE = function() M.Toggle("appearances") end,
	}, CollectionsMicroButton, function() M.Toggle() end)
	for _, e in ipairs({ "COMPANION_LEARNED", "COMPANION_UNLEARNED", "MOUNT_JOURNAL_USABILITY_CHANGED", "MOUNT_JOURNAL_SEARCH_UPDATED",
		"PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PET_JOURNAL_LIST_UPDATE", "PET_JOURNAL_PET_DELETED" }) do
		Polestar.RegisterEvent(e, redraw)
	end
	Polestar.RegisterEvent("COMPANION_UPDATE", function(_, kind) if not kind or kind == "MOUNT" or kind == "CRITTER" then redraw() end end)
	-- The model again when the client's scene data arrives, or the player's form changes under it.
	local function remodel() shown = nil; redraw() end
	Polestar.RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED", remodel)
	Polestar.RegisterEvent("UNIT_FORM_CHANGED", function(_, unit)
		if unit ~= "player" then return end
		if looks then for _, t in ipairs(looks.Looks) do t.psModel.psSlot = nil end end
		if detail then detail.Dress.psSet = nil end
		if GetCVarBool("mountJournalShowPlayer") or page == "appearances" then remodel() end
	end)
	Polestar.RegisterEvent("TOYS_UPDATED", function(_, itemID, new)
		if new and itemID then
			newToys[itemID] = true
			if toyPage then toyPage.psGoto = itemID end
		end
		redraw()
	end)
	Polestar.RegisterEvent("SPELL_UPDATE_COOLDOWN", function()
		if not (f and f:IsShown()) then return end
		if page == "toys" then for _, t in ipairs(tiles) do if t:IsShown() then paintCooldown(t) end end end
		if page == "pets" then for _, r in ipairs(rows) do if r:IsShown() and r.psPet then paintPetCooldown(r) end end end
	end)
	-- The wardrobe: its lists change with the collection, favorites and the
	-- async search (TRANSMOG_SEARCH_UPDATED), the search runs again once its
	-- data has loaded (SEARCH_DB_LOADED), cameras with the screen.
	local function looksChanged() setCache = nil; if page == "appearances" then redraw() end end
	for _, e in ipairs({ "TRANSMOG_COLLECTION_UPDATED", "TRANSMOG_SETS_UPDATE_FAVORITE", "TRANSMOG_COLLECTION_ITEM_UPDATE", "TRANSMOG_SEARCH_UPDATED" }) do
		Polestar.RegisterEvent(e, function()
			looksChanged()
			if tip and tip.refresh and GameTooltip:IsShown() then tip.refresh() end
		end)
	end
	-- No Tab cycling in combat (the propagation call is protected then): the keyboard goes before the lockdown.
	Polestar.RegisterEvent("PLAYER_REGEN_DISABLED", function() if f then keysFor(false) end end)
	Polestar.RegisterEvent("SEARCH_DB_LOADED", function() if page == "appearances" and f:IsShown() and query[view] ~= "" then lookSearch(); redraw() end end)
	for _, e in ipairs({ "TRANSMOG_COLLECTION_CAMERA_UPDATE", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
		Polestar.RegisterEvent(e, function()
			if looks then for _, t in ipairs(looks.Looks) do t.psModel.psCamera = nil end end
			if detail then detail.Dress.psSet = nil end
			looksChanged()
		end)
	end
	-- What the player can wear changes with level, skills and spells (UpdateUsableAppearances).
	for _, e in ipairs({ "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED", "UPDATE_FACTION", "SPELLS_CHANGED" }) do
		Polestar.RegisterEvent(e, function()
			if f and f:IsShown() and page == "appearances" and C_TransmogCollection.UpdateUsableAppearances then C_TransmogCollection.UpdateUsableAppearances() end
		end)
	end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return CollectionsJournal and CollectionsJournal:IsShown() and CollectionsJournal end

ns.Module("collections", M)
