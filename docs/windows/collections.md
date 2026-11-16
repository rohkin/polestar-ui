#### Collections (`CollectionsJournal`, Blizzard_Collections) — Risk: high

**Built** (stage 1: shell, doors, switch, Mounts, Toys; stage 2: Pets; stage 3:
Appearances, Items and Sets): `Modules/Collections.lua`, `tests/lua/stub_collections.lua`,
scenes `collections*`. The plan below was produced with the
`stock-to-polestar` skill; where the live client contradicts it, the "Live
facts" section wins. Items still marked **LIVE** need a check in game.

## Live facts (the user's checks in the Forever client; they override the plan and .ref)
- The stock tabs are **icon side-tabs**: a slim 48px rail (`ns.GameRail(..., { slim = true })`), labels in tooltips.
- **No heirlooms** (`C_HeirloomInfo.HeirloomsAvailable()` false, 0 displayed), **no warband scenes**, **no mount equipment**:
  those pages are dropped entirely (not even locked). The rail is Mounts, Pets, Toys, Appearances.
- From insecure `/run` code, out of combat: `C_MountJournal.SummonByID` summons, `C_PetJournal.SummonPetByGUID`
  summons, `UseToy(id)` uses the toy (no block), `C_MountJournal.Pickup` puts the mount on the cursor.
- The pet journal is the Classic one: no loadout, abilities, rename, release or cage.
- The client's `onlyShowCollectedItemsInJournal` is on (only collected mounts and toys are listed): the filter button is hidden, as stock hides its filter dropdown then.
- Appearances (A1-A3): 262 head appearances (`GetFilteredCategoryTotal(1)` and `#GetCategoryAppearances(1, ...)`);
  `C_TransmogSets.HasAnyValidSets()` **false** (no Sets view: Items alone, no Items | Sets switch);
  `GetCategoryInfo(13)` (one-handed axes) **nil** (a category without info is skipped: no picker entry,
  no category for the slot); no illusions (0: enchant tiles stay out); `C_TransmogOutfitInfo.GetAllSlotLocationInfo`
  exists; the player model is ready; `CollectionWardrobeUtil.SetAppearanceTooltip`, `Model_ApplyUICamera`,
  `C_TransmogSets.GetCameraIDs` exist. Scene `collections-nosets`.

## Built (stage 1)
- **Shell:** `W.Shell` 780×540 (600 covered the chat tabs), `sidebar = 0, rail = true`, `ns.Plain`, `ns.Compact`, "..." menu
  (`ns.WindowMenu`; Mounts adds "Show character on mount", the stock `mountJournalShowPlayer` toggle).
  A sliders filter ends the tab row (`ns.TopNav(f, {})` places it), the search at the top of its
  dropdown (`ns.SearchInFilter`; a submenu hides the box); each page keeps its own
  query, set on the client (`C_MountJournal.SetSearch`, `C_ToyBox.SetFilterString`). With the CVar
  `onlyShowCollectedItemsInJournal` the dropdown holds the search alone and a page with nothing collected leaves
  the rail, as stock. Last page in `PolestarUIDB.collectionsPage`.
- **Rail:** Mounts, Pets, Toys, Appearances with the `TABS_DATA` icons (stage 1 had Pets and
  Appearances locked; no page is locked now). A page the client would not show (the CVar
  rule) asked for opens the first one it does.
- **Doors:** `ns.Doors` with `TOGGLECOLLECTIONS` (last page), `TOGGLECOLLECTIONSMOUNTJOURNAL`,
  `TOGGLECOLLECTIONSPETJOURNAL`, `TOGGLECOLLECTIONSTOYBOX`, `TOGGLECOLLECTIONSWARDROBE` (open on that
  page, close when already on it, as `ToggleCollectionsJournal`), and `CollectionsMicroButton`
  (shift-click = the stock journal). Switch live (no `reloadOff`);
  off by default under the gamepad UI (`ns.Enabled`). `m.stock` reads `CollectionsJournal` only.
- **Mounts:** list column (260, own `W.Scroll`) of 36px rows: 28px icon well, name (two lines at most),
  favorite star, faction mark (`MountJournalIcons-Horde/Alliance`), "New" chip while it needs fanfare,
  the summoned mount's well in the accent; collected but unusable in danger with a red icon, uncollected
  desaturated and textMuted. Click selects; right-click (collected) the stock menu (Mount/Dismount/Unwrap,
  Set/Remove Favorite, redrawn at once); drag `C_MountJournal.Pickup(index)` out of combat for a collected
  one; shift-click links (spell name into an open macro). Detail: name, "New" chip, source (colour codes
  stripped; read again a few times while the client answers empty), lore over the top left of the model, as stock: the scene (our own `WrappedAndUnwrappedModelScene`) fills the whole inset detail pane, hairline and text on a frame above it; set up only while shown and again on a size change, as
  `MountJournal_UpdateMountDisplay` (stock scene ID, actor "unwrapped", `AttachPlayerToMount`). Footer:
  Mount / Dismount / Unwrap (primary), greyed by the client's `isUsable` with
  `GetMountUsabilityByID`'s reason. The band is "Collections" over the page's name; the page's fact sits on the tab row's left (`f.psStatus`, as Guild's): "7 mounts collected", "· n shown" while a search or filter
  narrows the list. Filter (flat): Collected, Not Collected, Unusable, Type (each valid type), "Sources…"
  (a menu of its own: Back, Check All, Uncheck All, each valid source), "Reset filters" off default.
  `C_MountJournal.ClearRecentFanfares` when leaving the page or closing, as `MountJournal_OnHide`.
- **Toys:** 18 a page in 3 columns of tiles (36px well, name), favorites first (the client's order),
  uncollected desaturated and textMuted, star on a favorite, "New" chip (fanfare, or learnt this session
  until hovered), stock cooldown sweep (`C_Spell.GetItemCooldown`; left as drawn while the times are
  secret). Click: a new toy unwraps (`C_ToyBoxInfo.ClearFanfare`), else `UseToy(id)` out of combat;
  right-click Set/Remove Favorite (redrawn at once); drag `C_ToyBox.PickupToyBoxItem` out of combat;
  shift-click links. Footer Previous / Next, the wheel turns pages, a toy just learnt opens its page
  (`TOYS_UPDATED` new). Tab-row fact "16 of 24 toys collected · Page 1 of 2". Filter (flat): Collected,
  Not Collected, Usable Only, "Sources…", "Expansions…", "Reset filters".
- **Decision, toys:** no secure overlay. `UseToy` works from addon code out of combat (live fact), and
  the plan's overlay could not be placed in combat either, so both ways a toy cannot be used from ours
  mid-fight. Ours does not call `UseToy` in combat; the tile's tooltip says "Toys can't be used from
  this window in combat." (the action bar or the stock window still can).
- **Decision, pickups:** mount and toy drags are refused in combat (not checked live in combat).

## Built (stage 2: Pets)
- **List** (the mounts' column and rows): icon well, name (the custom name when set), favorite star,
  "New" chip while it needs fanfare, the summoned pet's well in the accent, the stock cooldown sweep
  (`GetPetCooldownByGUID`; the times go through `ns.Clean` and the sweep stays as drawn while they are
  secret, rule 3). A pet never summonable here (`GetPetSummonInfo` error `InvalidFaction`) red,
  revoked desaturated, not collected desaturated and textMuted. Favorites first (the client's order).
  No level or quality: the Classic journal shows neither.
- **Card** (the mounts' detail pane and `WrappedAndUnwrappedModelScene`): name (custom name, the species
  under it), source (colour codes stripped), description in quotes, the model from
  `GetPetModelSceneInfoBySpeciesID`'s card scene, actor "unwrapped" (`PetJournal_UpdatePetCard`); one
  not collected shows by species.
- **Footer:** Summon / Dismiss / Unwrap (primary), enabled by `PetIsSummonable` or fanfare, greyed with
  `GetPetSummonInfo`'s error text (or "You don't have this pet."). Unwrap plays the scene's unwrap,
  then `ClearFanfare`.
- **Row:** click selects (clears a battle pet off the cursor, as stock); right-click (collected) the
  stock menu: Unwrap, or Summon/Dismiss (greyed when not summonable; none for a revoked pet) and Set /
  Remove Favorite (`IsJournalUnlocked`), redrawn at once; drag `PickupPet` out of combat (not revoked);
  shift-click links (`GetBattlePetLink` when `BATTLEPETS_SUPPORTED`, else `GetNonBattlePetLinkByIndex`;
  nothing into a macro, as stock).
- **Tab row:** "6 pets collected" (`GetNumPets` owned), "· n shown" while searched or filtered; search
  `SetSearchFilter`; filter Collected / Not Collected (`PetJournal_InitFilterDropdown`), hidden with the
  CVar as Mounts'. Leaving the page `ClearRecentFanfares`. Events: `PET_JOURNAL_LIST_UPDATE`,
  `PET_JOURNAL_PET_DELETED`, `COMPANION_UPDATE` ("CRITTER"), `SPELL_UPDATE_COOLDOWN`.
- **Left out:** `SpellTargetBattlePet` on a click while a spell targets (battle pet treats; Classic
  journal on Forever has no battle pets).

## Built (stage 3: Appearances)
- **Copied, not loaded:** `TransmogUtil`, its slot locations and the model setup tables live in the
  load-on-demand `Blizzard_TransmogShared`; loading it from our code would make its globals ours. Ours
  builds its own locations (`{slotID, type, modification}` with `GetData`, as `TransmogLocationMixin`)
  and copies `WARDROBE_MODEL_SETUP`/`_GEAR` and `GetUseTransmogSkin`. `CollectionWardrobeUtil`
  (`Blizzard_FrameXMLUtil`, always loaded) is called: sorted sources, the appearance tooltip, links.
- **Views:** Items | Sets as tabs on the tab row, the page's fact after them; only while
  `C_TransmogSets.HasAnyValidSets()` (false on Forever, live): else no switch at all, the fact at the
  row's left, and Sets falls back to Items, as `UpdateTabButtons`. The Sets code stays for clients with sets. Each view keeps its
  own search text. The class (`C_TransmogCollection` / `C_TransmogSets` class filter) is the first row
  of the filter menu ("Class: Warrior…", a menu of its own; a class change on a weapon category goes
  back to the head, as `SetClassFilter`): the tab row had no room for a class picker beside the views,
  the fact and the search, nor the slot row beside the weapon picker.
- **Items:** Forever's 14 slots (head to ranged; ranged only while `IsRangedSlotShown`) as 32px wells
  with the paper doll's empty-slot icons, the stock section gaps, the one shown in the accent; armor
  shows its category, a weapon slot the last weapon type picked if it fits, else the first
  (`SetActiveSlot`), with the weapon type picker (`UpdateWeaponDropdown`) at the row's end.
  `SetSearchAndFilterCategory` on each category change. Entering Items sets collected shown, uncollected
  not (Forever's `InitItemsFilterButtonSetupMenu`). 18 `DressUpModel` tiles a page (6 by 3, 100 high),
  lit as `ItemModelBaseMixin`, kept on hide; per slot the player is dressed as `Reload` (transmog skin,
  choices, hide flag, setup gear) or, for a weapon, the model is cleared; per tile the stock camera
  (`GetAppearanceCameraID`, applied again `OnModelLoaded`), armor tried on (the source picked, else the
  first), a weapon by `SetItemAppearance`; not displayable desaturated (and undressed / cleared);
  border textMuted not collected, danger unusable; star on a favorite, "New" until hovered
  (`ClearNewAppearance`). Tooltip: `CollectionWardrobeUtil.SetAppearanceTooltip` with the class's
  sources; Tab (`WARDROBE_CYCLE_KEY`) cycles them, shift-Tab back. A modified click hands the shown
  source's link to `HandleModifiedItemClick` (shift: chat, ctrl: dressing room). Right-click (collected):
  Set / Remove favorite (a favorite whose every source is refundable or tradable asks first in our modal,
  as `TRANSMOG_FAVORITE_WARNING`), then "Transmogrify as:" with the collected usable sources (the one
  picked is what the tile tries on). Footer Previous / Next and the wheel; fact "18 of 20 collected · Page
  1 of 2" (`GetFilteredCategoryCollectedCount` / `Total`), "Searching…" while the search runs. Filter:
  the class, Check All, Uncheck All, the valid source types (flat, as Forever's); shown even with the CVar
  (the wardrobe's filter does not hide).
- **Sets:** the base sets in the list column (the data provider's order: favorite groups, favorites,
  expansion, patch, `uiOrder`), each with its label under the name, icon from its first piece, colour by
  its best variant's progress (text done, success in progress, textMuted none; icon desaturated with
  none, red not valid for the character), star when it or a variant is a favorite, "New" with new pieces.
  Click shows its default variant (`GetDefaultSetIDForBaseSet`: new pieces, the one picked before, the
  favorite, the most collected). Detail: the player in the set (`DressUpModel`, `GetCameraIDs`' details
  camera, undressed then each piece tried on), drag turns it; name and label over its top left, the
  variant picker at its top right when more than one shows ("Heroic", menu "Normal (2/4)"…); the pieces
  in a row along its foot (collected in their quality, the rest faded and desaturated; star on a favorite
  appearance; "New" until hovered, `ClearSetNewSourcesForSlot`), tooltip their sources (Tab cycles),
  shift-click links, ctrl-click `DressUpVisual`, right-click favorite the appearance. Right-click a set:
  Set / Remove favorite on the variant shown (with its description when it has variants). Fact "1 of 3
  sets collected" (`GetFilteredBaseSetsCounts`). Filter: the class, Collected, Not Collected, PvE, PvP.
  No footer.
- **Search:** async, as stock: `SetSearch(type, text)` / `ClearSearch(type)` for the view shown (the
  other view's cleared on a switch), the lists again on `TRANSMOG_SEARCH_UPDATED`, the search again on
  `SEARCH_DB_LOADED`; leaving the page or closing `EndSearch` and clears both (the text stays ours and is
  set again on return). Other events: `TRANSMOG_COLLECTION_UPDATED`, `TRANSMOG_SETS_UPDATE_FAVORITE`,
  `TRANSMOG_COLLECTION_ITEM_UPDATE` (lists and the open tooltip), the camera ones and
  `UNIT_FORM_CHANGED` (models again), `UpdateUsableAppearances` on level, skill, faction and spell changes.
- **Decision, Tab:** the cycle key goes through a frame of ours whose keyboard is on only while an
  appearance tooltip with more than one source shows, out of combat (`SetPropagateKeyboardInput` is
  protected then; the keyboard goes off on `PLAYER_REGEN_DISABLED`). In combat the tooltip shows the
  first source and no Tab hint.
- **Left out** (not on Forever, of no use in our window, or not verified): illusions (the weapon slots'
  small enchant buttons) and the secondary shoulder button (both hang on `TRANSMOG_SLOTS` from
  `Blizzard_TransmogShared`; none on Forever: live check A2 gave 0); content tracking
  (`ContentTrackingUtil`, mainline; Forever lists collected appearances only, so no tracking line); the
  progress bar (hidden on Forever); help tips; the jump to the latest appearance on open; the equipped
  item's category as a weapon slot's first pick; the sets model's pan and zoom (per-race limits; ours
  turns only); the tooltip's visibility warning.

### Appearances live checks (/run, each under 255 characters)
- A1, transmog data on this character (expect numbers, true, a name):
  `/run local C=C_TransmogCollection print(C.GetFilteredCategoryTotal(1), C_TransmogSets.HasAnyValidSets(), (C.GetCategoryInfo(13)), #C.GetCategoryAppearances(1,{slotID=1,type=0,modification=0}))`
- A2, illusions and the outfit slot API (decides whether enchant tiles join):
  `/run print(#(C_TransmogCollection.GetIllusions() or {}), C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetAllSlotLocationInfo and "slots" or "none", IsUnitModelReadyForUI("player"))`
- A3, the shared helpers ours calls (expect three "function"):
  `/run print(type(CollectionWardrobeUtil.SetAppearanceTooltip), type(Model_ApplyUICamera), type(C_TransmogSets.GetCameraIDs))`

### Needs an in-game check
- Model frames at the stock aspect (rule 5): the mount and pet scene is sized to the stock MountDisplay /
  PetCard (407 by 514) and centred in our pane; each appearance tile's DressUpModel to the stock tile's
  78 by 104, centred (its mouse over the whole tile). Shots 20261115-115840 showed the mount left and low,
  the pet high, the back slot's camera cropped. Live: mounts and appearance tiles match stock. Pets now have
  their own scene (`d.Pet`, as stock's PetCard.modelScene apart from MountDisplay's): the shared scene
  handed the pet card the mount's "unwrapped" actor and camera (MAINTAIN), framing pets high. Still high
  (same camera and aspect as stock): stock's modelScene fills the card but sets `<ViewInsets top="300"
  bottom="-50"/>`, moving the view below the card's info and past its foot; `d.Pet` now sets the same,
  scaled to its height. Recheck pets.
- Appearance tiles (back slot): the body drew as a black silhouette although the tile light is stock's
  exactly (`ItemModelBaseMixin:OnLoad`: ambient 1.05, diffuse 0). Open: the /run checks in the report.
- The mount model: framing and zoom in our well (rule 5; a tall mount, "Show character on mount" on,
  a self-mount), drag-to-turn, the Unwrap animation then `ClearFanfare`.
- `UseToy` and `C_MountJournal.SummonByID` from our clicks (expected as the `/run` checks), and whether
  either is blocked in combat (ours does not try toys there; Mount follows `isUsable`).
- `C_MountJournal.Pickup` / `C_ToyBox.PickupToyBoxItem` in combat (ours refuses them there).
- Toy cooldown sweep in combat (secret times: the sweep should stay, no error).
- Shift-click on the micro button opens the stock journal; the switch-back button above it.
- Faction marks' atlases and the "New" chip placement on long mount names.
- Pets: the card model's framing; a summon, dismiss and unwrap from ours; `PickupPet` to a bar; the
  cooldown sweep after a summon, then in combat (no error); the pet link in chat.
- Appearances: the 18 tiles' framing per slot (a tall race; head, shoulders, feet, a weapon, a shield,
  a bow); the first open (the models are set up as the page paints, just before the window shows); the
  tiles after a shapeshift; Tab cycling, and other keys still reaching the game while hovering; the
  async search; ctrl-click opens the dressing room from our click; the sets model and its turn; the
  refund warning on a favorite.

S/ = `.ref/wow-ui-source-forever/Interface/AddOns`. Forever (game type
`camelot`) loads, per `Blizzard_Collections.toc`: `Shared/Blizzard_Collections.lua`,
`Camelot/Blizzard_CollectionsTabs.xml` + `Camelot/Blizzard_CollectionsOverrides.lua`
(side tabs), `Mainline/` mounts, toys, heirlooms and wardrobe, `Camelot/Blizzard_Wardrobe.lua`
(overrides), and the **Classic** pet journal (`Classic/Blizzard_PetCollection.lua`),
not the mainline battle pet journal. Warband scenes load only for `mainline`
(**LIVE**: whether `camelot` counts).

## What the stock window has (Forever)

| Page | Stock (S/ pointer) | Contents |
|---|---|---|
| Frame | `CollectionsJournal` (`Shared/Blizzard_Collections.xml`), `CollectionsJournalMixin.TABS_DATA`, `CollectionsJournal_CheckAndDisplayTabs` | **Icon side-tabs** on Forever (`CollectionsJournalTab` inherits `LargeSideTabButtonTemplate`, `BLIZZARD_COLLECTIONS_TAB_STYLE_SIDE` in `Camelot/Blizzard_CollectionsConstants.lua`), tooltip = page name; a tab shows only when `CollectionsJournal_ValidateTab` allows it (heirlooms: `C_HeirloomInfo.HeirloomsAvailable() and not PlayerIsTimerunning()`; warband scenes: `C_WarbandScene.WarbandScenesAvailable()`; with CVar `onlyShowCollectedItemsInJournal`, a page with nothing collected hides). Last tab kept in CVar `petJournalTab`. |
| Mounts | `MountJournal` (`Mainline/Blizzard_MountCollection.lua`) | List (icon, name, favorite star, usable/unusable red, "New"), count "n mounts", search (`C_MountJournal.SetSearch`), filter menu (collected, not collected, unusable, sources, types, reset: `MountJournal_InitFilterButton`). Detail: 3D `WrappedAndUnwrappedModelScene` (+ rotate/zoom control frame, "show player" toggle, CVar `mountJournalShowPlayer`), name, source, lore. Mount / Dismount / Unwrap button (`MountJournalMountButton_UseMount`). Right-click menu: Mount/Dismount, Favorite/Unfavorite. Drag (icon) to an action bar (`C_MountJournal.Pickup(index)`). Shift-click links (spell name into an open macro). Hidden on Forever per source: summon random favorite (`BLIZZARD_COLLECTIONS_MOUNT_JOURNAL_SHOW_FAVORITES = false`); mount equipment only if `C_MountJournal.MountEquipmentAvailable()`; skyriding flyout only if `DragonridingUtil.IsDragonridingUnlocked()` (**LIVE** all three). |
| Pets | `PetJournal` (`Classic/Blizzard_PetCollection.lua`) | Companion list (icon, name or custom name + species, favorite, cooldown, "New"), count, search (`C_PetJournal.SetSearchFilter`), filter menu: Collected / Not collected only (`PetJournal_InitFilterDropdown`; families, sources and sort helpers exist but are not in the menu). Card: icon, name, 3D model (`GetPetModelSceneInfoBySpeciesID`, actor "unwrapped", rotate buttons), favorite, source/description in its tooltip. Summon / Dismiss / Unwrap (`PetJournal_UpdateSummonButtonState`). Right-click menu: Unwrap, Summon/Dismiss, Favorite (`CreateContextMenu`). Drag to bars (`C_PetJournal.PickupPet`). Shift-click links. **No** loadout slots, abilities, rename, release or cage on Forever's journal (the brief asked for them: **LIVE** to confirm; if the live journal has them, they join stage 2). Random-pet button hidden (`BLIZZARD_COLLECTIONS_PETS_SHOW_SUMMON_RANDOM = false`). |
| Toys | `ToyBox` (`Mainline/Blizzard_ToyBox.lua`) | 18 per page (`TOYS_PER_PAGE`), pages + mouse wheel, progress "n/m", search (`C_ToyBox.SetFilterString`), filter (collected, uncollected, unusable, sources, expansions, reset), favorites first. Click uses (`UseToy`, from the stock button: secure path), right-click Favorite menu (`MENU_TOYBOX_FAVORITE`), drag (`C_ToyBox.PickupToyBoxItem`), shift-click links, "New"/fanfare unwrap, cooldown. `ToggleToyCollection(id)` pages to a toy. |
| Heirlooms | `HeirloomsJournal` (`Mainline/Blizzard_HeirloomCollection.lua`) | Paged grid grouped by slot heading, upgrade level pips (`C_Heirloom.GetHeirloomInfo`, `GetHeirloomMaxUpgradeLevel`), class/spec dropdown (`C_Heirloom.SetClassAndSpecFilters`, defaulting to the player's class below max level), collected/uncollected/sources filter. Click creates (`C_Heirloom.CreateHeirloom`); while an upgrade token targets (`SpellCanTargetItemID`, `C_Heirloom.IsPendingHeirloomUpgrade`) click upgrades (`C_Heirloom.UpgradeHeirloom`). Modified click: `HandleModifiedItemClick` (link, dress up). No Forever key binding (`Bindings_Camelot.xml` has none). **Dropped:** not on Forever (live: `HeirloomsAvailable()` false). |
| Appearances | `WardrobeCollectionFrame` (`Mainline/Blizzard_Wardrobe.lua`, `Shared/Blizzard_Wardrobe_Sets.lua`, overrides `Camelot/Blizzard_Wardrobe.lua`) | Two views, Items and Sets. **Items:** slot buttons (Forever's list: head, shoulder, back, chest, shirt, tabard, wrist, hands, waist, legs, feet, main hand, off hand, ranged), weapon-type dropdown, 18 `DressUpModel` tiles per page (camera via `C_TransmogCollection.GetAppearanceCameraID`), search (async: `TRANSMOG_SEARCH_UPDATED`, `SEARCH_DB_LOADED`, progress bar), filter = source types only (Forever forces collected only, no race/faction submenu), class dropdown, right-click Favorite, tooltip lists sources (cycle with Tab), shift-click link, ctrl-click dress up, "New". Progress bar hidden on Forever. **Sets:** base-set list (favorites, collected count), detail model (`C_TransmogSets.GetCameraIDs`), piece icons with sources, variants dropdown, set filter. |
| Warband scenes | `WarbandSceneJournal` (`Mainline/Blizzard_WarbandSceneCollection.lua`) | **Dropped:** not on Forever (live). If present: paged picture grid, favorite, search. |

Window show/hide: `CollectionsJournal_OnShow` / `_OnHide` run
`UpdateMicroButtons`, `MainMenuMicroButton_HideAlert`, `MicroButtonPulseStop`
and `CollectionsMicroButton:EvaluateAlertVisibility` — secure-adjacent micro
button code. Opened with `ShowUIPanel`/`HideUIPanel` from
`SetCollectionsJournalShown` (`Blizzard_Collections_Bootstrap.lua`).

## Plan: CollectionsJournal -> Polestar

### Strategy
**Replace, never show or hide the stock one** (skill checklist: "Do its
OnShow/OnHide touch secure frames (`UpdateMicroButtons`)? -> replace, doors via
`ns.Doors` only; shift-click on the micro button opens the stock window";
CLIENT.md rule 8, as Spellbook, Talents, Legacy, Professions book). No routing
is stopped, so the switch is live (no `reloadOff`). Blizzard_Collections is
LoadOnDemand and ours never loads it: every API below is a `C_*` namespace or a
shared template (`WrappedAndUnwrappedModelScene` is in
`Blizzard_SharedXML/ModelSceneTemplates.xml`, `Model_ApplyUICamera` in
`Blizzard_SharedXML/Mainline/ModelFrames.lua`).

Module key `collections`, window `PolestarUICollections`, file
`Modules/Collections.lua` (before Tooltips in the .toc). Gamepad UI on: off
by default (the gamepad radial drives `CollectionsMicroButton`,
`GamepadRadial.lua`).

### Shell and page structure
- `W.Shell("PolestarUICollections", { scalePath = "ui.menuScale", width = 780, height = 600, rail = true })`,
  `ns.Dock`, `ns.WindowMenu(f, "collections", options)`, `ns.Compact`,
  `Polestar.CloseOnEscape`.
- **Page nav: a slim icon rail**, not top tabs. Forever's stock tabs are icon
  side-tabs (`LargeSideTabButtonTemplate`), and the house rule (CLAUDE.md
  "Page nav", DESIGN.md "Page nav (no sidebar)") makes those a 48px rail:
  `ns.GameRail(f, items, active, onSelect, { slim = true })` with
  `TABS_DATA`'s icons (Mounts `INV_Horse3Saddle008_Chestnut`, Pets
  `INV_ArfusPet_Classic`, Toys `INV_SideTab_ToyBox_c60`, Heirlooms
  `INV_Misc_Bag_EnchantedRunecloth`, Appearances `UI_Transmog_ShowEquippedGear`,
  Warband scenes `UI_CampCollection`), each label in its tooltip. The brief
  said "text tabs → top tabs"; the source says icon tabs. **LIVE**: the user
  confirms which the client shows; if text tabs, swap `ns.GameRail` for
  `ns.TopNav` (same items; one call in `refresh`). A page shows only when the
  stock `CollectionsJournal_ValidateTab` rules allow it (copied, not called).
  Last page in `PolestarUIDB` (not the stock CVar `petJournalTab`).
- **Tab row** (free, since the rail carries the pages): each page's own
  views, then search + filter at its right end (`f.Search`, `f.psFilter` made on
  `f.TabRow`, as `ns.TopNav` places them). Mounts, Pets, Toys, Heirlooms: no
  views, search + filter only. Appearances: Items | Sets as `W.ShellTabs`.
- **Subtitle** (status, subject first): "312 of 540 mounts collected" ·
  "Showing 24 matches"; Pets "48 companions"; Toys "112 of 830 toys · Page 3 of
  12"; Heirlooms "14 of 120 heirlooms"; Appearances "Head · 210 appearances".
- **Footer** (`ns.Footer`): Mounts: Mount / Dismount / Unwrap (primary);
  Pets: Summon / Dismiss / Unwrap; Toys and Heirlooms: page `<` `>` and the
  page count; Appearances Items: page `<` `>`. Greyed with `ns.SetEnabled(b, on, why)`.
- **"..." menu options**: Mounts "Show character on mount" (CVar
  `mountJournalShowPlayer`, checked item); "Only show collected" mirrors the
  stock CVar `onlyShowCollectedItemsInJournal` only if the user wants it (open
  question).

### Parts
| Stock part (S/ pointer) | Polestar element | API + example call site | Risk / gotcha |
|---|---|---|---|
| `CollectionsJournal` frame, portrait, title | `W.Shell` compact, `W.ShellTitle` | `build` in `Spellbook.lua`; `ns.Compact` | Size 780×600 (Legacy is 760×600 with the same rail) |
| Side tabs `CollectionsJournalTab` (`Camelot/Blizzard_CollectionsTabs.xml`) | slim rail | `ns.GameRail(..., { slim = true })`; `refresh` in `Legacy.lua` | Rail items never cast here, so no `ns.Overlay` on the rail |
| Search boxes (`SearchBoxTemplate` on each page) | `f.Search` on the tab row | `ns.TopNav` search placement; `onSearch` → `C_MountJournal.SetSearch`, `C_PetJournal.SetSearchFilter`, `C_ToyBox.SetFilterString`, `C_Heirloom.SetSearch`, `C_TransmogCollection.SetSearch(Enum.TransmogSearchType.Items, text)` | Client search state is shared with the stock journal (fine). Appearances search is async: show "Searching…" in the subtitle until `TRANSMOG_SEARCH_UPDATED`/`SEARCH_DB_LOADED` |
| Filter dropdowns `WowStyle1FilterDropdownTemplate` (`MountJournal_InitFilterButton`, `ToyBox_InitFilterDropdown`, heirloom, wardrobe) | sliders `W.IconButton` + `W.ShowMenu` | `filterMenu` in `Crafting.lua` / `Legacy.lua`; glyph lit while not default (`C_MountJournal.IsUsingDefaultFilters`, `C_ToyBoxInfo.IsUsingDefaultFilters`, `C_HeirloomInfo.IsUsingDefaultFilters`, `C_TransmogCollection.IsUsingDefaultFilters`) | `W.ShowMenu` has no submenus: stock Sources/Types/Expansions submenus become flat sections with a heading row and "All / None" items, or a second menu opened from a row. Redraw at once after each set (rule 6) |
| Mount list rows (`MountJournal_InitMountButton`) | pooled list rows in `W.Scroll` (Recipe Row shape: 16px game icon, name, star) | `newRow` in `Spellbook.lua`, `W.SetScrollContent` | Unusable: name in danger (legible); uncollected: desaturated, receding. Favorite = a star glyph. "New": `W.Chip` |
| Mount detail `MountDisplay` + `WrappedAndUnwrappedModelScene` | Model Well (DESIGN.md "Model Well") holding our own `CreateFrame("ModelScene", nil, well, "WrappedAndUnwrappedModelScene")` | as `MountJournal_UpdateMountDisplay`: `TransitionToModelSceneID(modelSceneID, …)`, `GetActorByTag("unwrapped")`, `SetModelByCreatureDisplayID`, `AttachPlayerToMount(actor, animID, isSelfMount, disablePlayerMountPreview, spellVisualKitID, PlayerUtil.ShouldUseNativeFormInModelScene())`; fallback display `C_MountJournal.GetMountAllCreatureDisplayInfoByID` | Rule 5: reuse the stock scene IDs; tune only zoom. Drag to turn via the template's own mouse handling; no stock `ControlFrame` (our two `W.IconButton` rotate glyphs, or none). Feature-detect (`if scene.TransitionToModelSceneID`), as `Character.lua`; preview draws no model |
| Mount name / source / lore | `W.Text` Title, Body textDim | `C_MountJournal.GetMountInfoExtraByID` | `sourceText` carries colour codes: `W.Uncolor` before `Theme` colour |
| `MountButton` (Mount/Dismount/Unwrap) | footer primary | `C_MountJournal.SummonByID(id)` / `C_MountJournal.Dismiss()` from our click; Unwrap: `scene:StartUnwrapAnimation(cb)` then `C_MountJournal.ClearFanfare` | **LIVE** insecure summon. Enabled by `isUsable` (`GetMountInfoByID`), redrawn on `MOUNT_JOURNAL_USABILITY_CHANGED`, `COMPANION_UPDATE`, `PLAYER_MOUNT_DISPLAY_CHANGED` |
| Mount right-click menu | `W.ShowMenu` (Mount/Dismount, Favorite/Unfavorite) | `C_MountJournal.SetIsFavorite(index, on)` (displayed index), `GetIsFavorite` | Favorite reorders the list: re-find the selection by mountID |
| Mount drag to bars | row `OnDragStart` → `C_MountJournal.Pickup(displayIndex)` | as `MountListDragButton_OnClick` | Out of combat only (rule 4, like the spellbook pickup); **LIVE** whether blocked in combat |
| Mount count `CollectionsCountTemplate` | subtitle | `C_MountJournal.GetNumMounts`, `GetNumDisplayedMounts` | — |
| Pet list rows (`PetJournal_InitPetButton`) | list rows as mounts, plus a cooldown on the icon | `C_PetJournal.GetPetInfoByIndex`, `GetPetCooldownByGUID` | Cooldown: stock `CooldownFrameTemplate` on our well (`paintCooldown` in `Spellbook.lua`); **LIVE** whether the pet cooldown is secret in combat |
| Pet card + model | Model Well + `WrappedAndUnwrappedModelScene` | `C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID)` → `TransitionToModelSceneID(cardSceneID, …, CAMERA_MODIFICATION_TYPE_MAINTAIN)`, actor "unwrapped" `SetModelByCreatureDisplayID(displayID)` | Same as mounts |
| Pet Summon/Dismiss/Unwrap | footer primary | `C_PetJournal.SummonPetByGUID(petID)` (also dismisses the summoned one), unwrap as mounts then `C_PetJournal.ClearFanfare` | **LIVE** insecure summon; redraw on `COMPANION_UPDATE` ("CRITTER") |
| Pet right-click menu, drag | `W.ShowMenu`; `C_PetJournal.PickupPet(petID)` | `C_PetJournal.SetFavorite(petID, 0/1)`, `PetIsFavorite` | Skip revoked (`PetIsRevoked`) and locked pets |
| Toy grid `ToySpellButtonTemplate` ×18 + `PagingFrame` | `ns.ItemGrid(parent, 3, 36, gap)` of tiles with the name beside (Reward Tile shape), 18 per page, wheel pages | `ns.ItemWell` + `ns.PaintItem`; `C_ToyBox.GetToyFromIndex((page-1)*18+i)`, `GetToyInfo`, `PlayerHasToy` | Uncollected: desaturated, name textMuted |
| Toy use (`ToySpellButton_OnClick` → `UseToy`) | **Superseded (built): a plain click, `UseToy(id)` out of combat** (live: not blocked from addon code); was: secure hover button `ns.Overlay("PolestarUICollectionsToy", { attrs = type1 "toy", toy = itemID; type2 nil })` | `overRow` in `Spellbook.lua`, `overSlot` in `Character.lua` | Rules 4, 9, 10: placed out of combat, hides on `PLAYER_REGEN_DISABLED`; right-click passes to our tile (favorite menu); `pickup` = `C_ToyBox.PickupToyBoxItem`. **LIVE** `UseToy` blocked from addon code (expected) and `type=toy` working |
| Toy cooldown | stock `CooldownFrameTemplate` on our well | `C_Container.GetItemCooldown(itemID)` as the stock button does (grep `ToySpellButton_UpdateButton`'s cooldown) | Secret in combat: duration object if one exists, else hide in combat |
| Toy favorite menu | `W.ShowMenu` | `C_ToyBox.SetIsFavorite(itemID, on)` | Redraw at once (`TOYS_UPDATED` may lag) |
| Toy progress `ToyProgressTracker` | subtitle "n of m toys" | `C_ToyBox.GetNumLearnedDisplayedToys`, `GetNumTotalDisplayedToys` | — |
| Heirloom grid + level pips | `ns.ItemGrid` tiles under `W.SectionHeader` per slot group; upgrade level as "2/6" on a `W.Chip` | `C_Heirloom.GetHeirloomItemIDFromDisplayedIndex`, `GetHeirloomInfo`, `GetHeirloomMaxUpgradeLevel`, `PlayerHasHeirloom`; tooltip `GameTooltip:SetHeirloomByItemID` | Grouping copies `HeirloomsMixin` layout rules (grep `RefreshView`) |
| Heirloom click (create / upgrade) | tile `OnClick` | `C_Heirloom.CreateHeirloom(itemID)`; while `SpellCanTargetItemID()` and `C_Heirloom.IsPendingHeirloomUpgrade()`: `C_Heirloom.UpgradeHeirloom(itemID)`; modified click `HandleModifiedItemClick(C_Heirloom.GetHeirloomLink(itemID))` | **LIVE** both from addon code. If upgrade is refused (rule 4's targeting family), the tile shows "Use the game's window to upgrade" in its tooltip while targeting and the player shift-clicks the micro button |
| Heirloom class/spec dropdown | menu on a tab-row button (class icon) | `C_Heirloom.GetClassAndSpecFilters` / `SetClassAndSpecFilters`; default as `HeirloomsJournal_OnShow` | — |
| Appearance slot buttons | a row of 14 slot game icons (Slot Tile at 28) under the tab row on Items | slot list from `Camelot/Blizzard_Wardrobe.lua` `OverrideDefaults`; `C_TransmogCollection.GetCategoryAppearances(categoryID, transmogLocation)` | Weapon slots need `C_TransmogCollection.GetCategoryInfo` for the weapon-type menu |
| Appearance model tiles (`WardrobeItemsModelTemplate`, `DressUpModel` ×18) | our own `CreateFrame("DressUpModel")` ×18 in inset wells, 6×3 per page | camera `Model_ApplyUICamera(m, C_TransmogCollection.GetAppearanceCameraID(visualID))`; `m:SetUnit("player")`, `m:Undress()`, `m:TryOn(sourceID)`; illusions `C_TransmogCollection.GetIllusions` | Heavy: 18 models; rebuild only the page shown. Rule 5: stock camera IDs; check a tall race. Tooltip lists sources (`GetAppearanceSources` / `GetSourceInfo`), Tab cycles the shown source as stock |
| Appearance favorite / link / dress up | `W.ShowMenu`; modified click | `C_TransmogCollection.SetIsAppearanceFavorite`; link from the source's `itemLink`; ctrl-click `DressUpVisual(link)` | `DressUpVisual` opens the stock dressing room — a game window from our click; **LIVE** it opens untainted (it is not micro-button code; expected fine) |
| Sets list + detail (`WardrobeSetsCollectionMixin`) | `W.Scroll` rows (left 260) + one `DressUpModel` well + piece wells | `C_TransmogSets.GetBaseSets`, `GetVariantSets`, `GetSetPrimaryAppearances`, `GetCameraIDs`; `C_TransmogSets.SetIsFavorite` | Variants: a `W.ShowMenu` on the set title |
| Class dropdown, sources filter | tab-row menus | `C_TransmogCollection.GetClassFilter`/`SetClassFilter`; `SetSourceTypeFilter`, `SetAllSourceTypeFilters` | Forever forces collected only (`InitItemsFilterButtonSetupMenu` override): copy that, show no collected/uncollected items |
| "New" markers, fanfare | `W.Chip(…, "New")` | `C_MountJournal.NeedsFanfare`, `C_PetJournal.PetNeedsFanfare`, `C_ToyBox.GetToyInfo` (hasFanfare), `C_TransmogCollection.IsNewAppearance` | Clearing "new" (`ClearRecentFanfares`, `ClearNewAppearance`) on page hide, as stock |

### Doors
| Stock door | Ours | Rule |
|---|---|---|
| `TOGGLECOLLECTIONS` | `ns.Doors` → `M.Toggle()` (last page) | 8 |
| `TOGGLECOLLECTIONSMOUNTJOURNAL`, `TOGGLECOLLECTIONSPETJOURNAL`, `TOGGLECOLLECTIONSTOYBOX`, `TOGGLECOLLECTIONSWARDROBE` (Forever's names in `Bindings_Camelot.xml`; the brief's `TOGGLEMOUNTJOURNAL` etc. do not exist) | `ns.Doors` → `M.Toggle("mounts" | "pets" | "toys" | "appearances")`, same toggle semantics as `ToggleCollectionsJournal(tab)` (open on that page, close if already on it) | 8. A page not built yet keeps its binding the game's (left out of `actions`) |
| (`TOGGLECOLLECTIONSHEIRLOOM`) | none on Forever | — |
| `CollectionsMicroButton` | `ns.Doors(..., CollectionsMicroButton, M.Toggle)`; shift-click = stock window | 8, 10 |
| New mount/pet/toy/appearance/warband alerts (`AlertFrameSystems.lua`), mount item links (`ItemRefHandlers.lua`), heirloom upgrade (`EventImplementation.lua` → `ShowHeirloomsJournalToClosestUpgradeablePage`), pet battle tooltip (`FloatingPetBattleTooltip.lua`), transmog links (`Blizzard_TransmogShared.lua`), Encounter Journal, the wardrobe's own `ToggleCollectionsJournal(5)`, NPE tutorial Dispatcher | **stay the game's**: they call `ToggleCollectionsJournal`/`SetCollectionsJournalShown` inside stock code; hiding the stock window after them would run its OnHide (`UpdateMicroButtons`) as ours | 8, 14 |
| Stock window in use | the "Polestar" switch button above it (`m.stock` returns `CollectionsJournal` when loaded and shown) | Contract 3 |

### Protected actions: per-action decision
| Action | Stock path | Ours | Why / check |
|---|---|---|---|
| Summon / dismiss mount | `C_MountJournal.SummonByID`, `Dismiss` from the stock button | **insecure click** | Not marked protected in `MountJournalDocumentation.lua` (only `SecretArguments = "AllowedWhenUntainted"`: pass clean IDs). **LIVE 1** |
| Summon / dismiss pet | `C_PetJournal.SummonPetByGUID`, `DismissSummonedPet` | **insecure click** | **LIVE 2** |
| Use toy | `UseToy` from `CollectionsSpellButtonTemplate` (inherits `SecureFrameTemplate`) | **Built: insecure click out of combat, none in combat** (live: `UseToy` works from addon code); was: secure overlay (`ns.Overlay`, `type = "toy"`, `toy = itemID`; `SECURE_ACTIONS.toy` in `Blizzard_FrameXML/SecureTemplates.lua`) | `UseToy` is protected from addon code on mainline. Out of combat only: the overlay cannot be placed in combat, so a toy cannot be used from ours mid-fight (stock can). Tooltip hint says so; Nothing Lost via shift-click micro. **LIVE 3** |
| Create heirloom | `C_Heirloom.CreateHeirloom` | **insecure click** | **LIVE 4**. Fallback: secure overlay impossible (no secure type); point to the stock window |
| Upgrade heirloom | `C_Heirloom.UpgradeHeirloom` while a token targets | **insecure click**, unverified | Rule 4: item targeting from addon code was forbidden for `PickupInventoryItem`. **LIVE 5**; fallback as above |
| Drag to action bars | `C_MountJournal.Pickup(index)`, `C_PetJournal.PickupPet(guid)`, `C_ToyBox.PickupToyBoxItem(id)` | plain `OnDragStart`, refused in combat; toys through the overlay's `pickup` | Rule 4 (spell pickup is blocked in combat), rule 9 (drag source stays shown until `OnDragStop`). **LIVE 6** |
| Models | `WrappedAndUnwrappedModelScene`, `DressUpModel` | our own frames on the same templates / types | Not protected. Rule 5 |
| Favorites, filters, search | `C_*` setters | insecure | No Lua value on stock frames |

### Taint and combat
- Nothing of ours touches `CollectionsJournal`, `MountJournal`, `PetJournal`,
  `ToyBox`, `HeirloomsJournal` or `WardrobeCollectionFrame`; we never call
  `CollectionsJournal_LoadUI` (loading it from our code would run its OnLoad
  as ours; our pages need nothing from it). `m.stock` reads `CollectionsJournal`
  only if the global exists.
- Override bindings and the micro overlay: set out of combat (`ns.Doors`).
  Switch refused in combat.
- The toy overlay: out of combat only, hidden on `PLAYER_REGEN_DISABLED`,
  strata above the window (rule 4's note), never anchored to a stock frame.
- Secret values (rule 3): collection data is not expected secret; guard
  cooldown times (pet and toy cooldowns) — draw from duration objects if the
  client has them, else hide the sweep in combat. Read nothing from stock
  frames. **LIVE 7** for one cooldown read in combat.
- Every FontString via `W.Text` (rule 2); colour-coded source text through
  `W.Uncolor`/`Theme.Legible`.
- Lists redraw at once after our own favorite/filter changes (rule 6).
- No zero-width anchors (rule 12): `ns.GameRail` + `ns.Plain` handle the main
  column.

### Tests
- `tests/lua/stub_collections.lua`: `CollectionsMicroButton`; `C_MountJournal`
  (extend, do not replace, the `C_MountJournal` table Polestar's
  `stub_lookup_runtime.lua` makes), `C_PetJournal`, `C_ToyBox`, `C_ToyBoxInfo`,
  `C_Heirloom`, `C_HeirloomInfo`, `C_TransmogCollection`, `C_TransmogSets`,
  `PlayerHasToy`, `UseToy` (errors when called from addon code: protected),
  `C_MountJournal.Pickup`/`PickupPet`/`PickupToyBoxItem` refused in combat;
  records `stub.summoned`, `stub.dismissed`, `stub.favorites`, `stub.picked`.
  A stub `CollectionsJournal` whose `Show`/`Hide` error from addon code (as
  `PlayerSpellsFrame` in the talents stub).
- Scenes (stage 1): `collections` (Mounts page, a selected mount, filter
  default), `collections-mounts-filter` (filter menu, a source off, glyph lit),
  `collections-toys` (page 2, an uncollected toy, a favorite),
  `collections-doors` (each bound key opens the right page, again closes; micro
  overlay not anchored and covering; shift-click hands to the micro button;
  stock frame never shown/hidden by us), `collections-combat` (summon refused
  greyed with reason, drag picks nothing, toy overlay hidden),
  `collections-off` (switch off: doors are the game's; on again).
  Stage 2 (built): `collections-pets` (list states, card, summon/dismiss/unwrap, menu, drag,
  link, search, filter, the last page kept); `collections-combat` gained the pets' secret
  cooldown, a refused drag, Summon greyed, and no Tab keyboard in combat. Stage 3 (built):
  `collections-appearances` (slots, 18 tiles, tooltip and Tab, link, favorite and its refund
  warning, "Transmogrify as", pages, weapon type, class, async search, filter, end of search on
  close), `collections-sets` (order, colours, default variant, variants, pieces, link, favorite,
  async search, the views' own search, filter). `collections-locked` went with the locks.
- Asserts: `stub.pressKey`, `stub.inCombat`, `stub.assertNoErrors`; the
  toy overlay's attributes (`type = "toy"`, `toy = id`) on the hovered tile.
- Bless with `node tools/preview.js <scene>`; DESIGN.md index row (Risk high,
  status "planned"); CHANGELOG per stage.

### Build split
1. **Shell, doors, Mounts, Toys** (built) (the protected decisions all land here:
   insecure summon, a plain toy click (no overlay: see Live facts), pickups, the mount model). Rail shows
   all valid pages; unbuilt ones are locked items whose tooltip says
   "Shift-click the Collections button for the game's window" (rule 8: we may
   not open it from our code). Bindings for unbuilt pages stay the game's.
2. **Pets** (built) (heirlooms dropped: not on Forever) (pets reuse the mount list + model).
   Summon checked live; Classic journal only (no loadout, abilities, rename, release, cage).
3. **Appearances** (built) (Items + Sets): the largest page (DressUpModel tiles,
   async search, class and weapon menus, sources tooltip).
4. ~~Warband scenes~~: dropped (not on Forever).

Size estimate (by comparable modules): stage 1 about 900–1,100 lines of Lua
plus a 300-line stub; stage 2 about 600; stage 3 about 1,000; total near
Character's scale (Character + CharacterPages + CharacterGear).

### Live checks
Run each in game, out of combat unless noted; report what printed or happened.

1. Mount summon from addon code (summons your first usable mount):
   `/run for i=1,C_MountJournal.GetNumDisplayedMounts() do local _,_,_,_,u,_,_,_,_,_,c,id=C_MountJournal.GetDisplayedMountInfo(i) if u and c then C_MountJournal.SummonByID(id) return end end`
   (then `/run C_MountJournal.Dismiss()`; expect no "blocked" message)
2. Pet summon: `/run local id=C_PetJournal.GetPetInfoByIndex(1) print(id) if id then C_PetJournal.SummonPetByGUID(id) end`
3. Toy from addon code (expect "blocked"/protected):
   `/run for i=1,C_ToyBox.GetNumFilteredToys() do local id=C_ToyBox.GetToyFromIndex(i) if PlayerHasToy(id) then print(id) UseToy(id) return end end`
4. Heirloom tab and create: `/run print(C_HeirloomInfo.HeirloomsAvailable(), PlayerIsTimerunning and PlayerIsTimerunning(), C_Heirloom.GetNumDisplayedHeirlooms())`
   then, if available: `/run local id=C_Heirloom.GetHeirloomItemIDFromDisplayedIndex(1) print(id, C_Heirloom.PlayerHasHeirloom(id)) C_Heirloom.CreateHeirloom(id)`
5. Heirloom upgrade (start using an upgrade token, then type):
   `/run print(SpellCanTargetItemID(), C_Heirloom.IsPendingHeirloomUpgrade()) C_Heirloom.UpgradeHeirloom(C_Heirloom.GetHeirloomItemIDFromDisplayedIndex(1))`
6. Pickups (out of combat, then again in combat):
   `/run C_MountJournal.Pickup(1) print(GetCursorInfo())` and `/run C_ToyBox.PickupToyBoxItem(C_ToyBox.GetToyFromIndex(1)) print(GetCursorInfo())`
7. Secret cooldowns (in combat): `/run local s,d=C_PetJournal.GetPetCooldownByGUID(C_PetJournal.GetPetInfoByIndex(1)) print(issecretvalue and issecretvalue(d), s, d)`
8. Optional pages and flags: `/run print(C_WarbandScene and C_WarbandScene.WarbandScenesAvailable(), C_MountJournal.MountEquipmentAvailable(), DragonridingUtil and DragonridingUtil.IsDragonridingUnlocked())`
9. Pet journal shape and tab style: `/run print(GetClassicExpansionLevel and GetClassicExpansionLevel(), C_PetJournal.GetPetLoadOutInfo and "loadout API" or "none")`
   — and look at the stock window (shift-click the micro button once ours
   exists, or `/click CollectionsMicroButton` now): are the page tabs icons
   on the right edge or text tabs; does the pet page show loadout, abilities,
   rename/release/cage?

### Open questions
- **Tabs:** icon rail (source) or top tabs (brief)? Settled by LIVE 9.
- **Pets parity:** the brief lists loadout, rename, release, cage and
  abilities; Forever's source journal has none of them. Build only what the
  live journal shows.
- **Toys in combat:** ours cannot use a toy mid-fight (secure overlay is out
  of combat only); stock can. Accept, with the tooltip hint, or keep the toy
  page's click on the stock window in combat?
- **Heirloom upgrade fallback** if LIVE 5 is blocked.
- **"Only show collected"** (`onlyShowCollectedItemsInJournal`): mirror it in
  the "..." menu, or read it only?
- Stock mount journal's player-on-mount preview and pet rotate buttons:
  keep as "..." option and drag-to-turn only, or add our rotate glyphs?
