#### Group Finder (`LFGParentFrame`, Blizzard_GroupFinder_VanillaStyle) — Risk: high — Built

**Built**: shell, doors and all three stock pages (Listing, Browse, Who). The
plan below is kept as the reference it was built from; where the build
differs, "Built" wins. The live check results end the file.

## Built
- `Modules/GroupFinder.lua`: `W.Shell` 620×560 (`sidebar = 0`, `rail = true`),
  `ns.Dock`, `ns.WindowMenu` (page items, then "The game's window:
  shift-click the Group Finder button."), `ns.Plain`, `ns.Compact`; the slim
  `ns.GameRail` (Listing: "Create a Listing" / "Edit Listing" while
  listed, redrawn on `LFG_LIST_ACTIVE_ENTRY_UPDATE`; Browse; Who); band
  title `LFG_TITLE` as stock's modern style (`GROUP_FINDER` is "Dungeons &
  Raids" live), subtitle "Level 42 Mage · <page fact>" with short facts only
  ("3 chosen", "Listed: 3", "7 listings", "50 found": the band is narrow and
  cut longer ones in game); opens on the last page
  (`PolestarUIDB.groupFinderPage`).
- Doors: `TOGGLEGROUPFINDER` -> Listing, `TOGGLEWHOTAB` -> Who (unbound live;
  taken when bound), `LFDMicroButton` overlay -> last page, shift-click the
  stock window. Live switch (not `reloadOff`); `M.stock()` = `LFGParentFrame`.
  Who results sent to the UI open our Who page (the Who list exception,
  below).
- **Page registry** `ns.GroupFinder = { pages, Paint, frame, SearchFor }`: a
  page file sets `pages[key] = { build(f), paint(f) -> fact, right, left,
  height, leave(f)?, menu(f)?, apply(on)? }`; footer specs are `ns.Footer`'s
  plus `on`, `why`, `tip` and **`game = true`**: a secure button of ours
  (`PolestarUIGroupFinderGame`, `ns.Overlay`: on UIParent, placed on hover out
  of combat, hidden as combat starts) over that footer button, whose PreClick
  closes ours and whose macro is `/click [nocombat] LFDMicroButton`. That is
  the door for **Unlist** and **posting with a comment**. A `game` button is
  greyed in combat ("You can't do that while in combat."). A page that uses
  the tab row sets `f.psKeepTabRow` in `paint` and clears it (and hides its
  tab-row controls) in `leave`.
- **Listing** (`GroupFinderListing.lua`): category cards (stock atlases), the
  activity tree (fold, tri-state group box, level colours, lock warning),
  playstyle and voice chat, solo roles (`C_LFGListRoles`) or the group role
  (`UnitSetRole` from the menu click) and Role Check, new player friendly;
  "‹ Categories", the category's name and **"Ignore level ranges"** (the
  CVar) on the tab row; new player friendly drops to its own line when the
  role toggles reach it; Post
  / Update from the click only (`CopyActiveEntryInfoToCreationFields` first
  on Update); after a post, Browse searching what was posted, from the same
  click (stock's `LFGParentFrame_SearchActiveEntry`); the locked view for a
  member. Unlist, "Post with a comment…" and a mandatory-comment category go
  to the game's window.
- **Browse** (`GroupFinderBrowse.lua`): category and activity pickers, the
  options menu (ignore level ranges) and Refresh on the tab row; search only
  from those clicks (never on show or an event; a menu item's `onClick` runs
  inside the menu row's click, so a pick counts); a search with no answer
  ends as failed after 10 s and Refresh always searches again (live, the
  page stuck on "Searching" with Refresh greyed); results sorted as stock under
  Groups / Solo Players headings, every member display type, tooltip,
  selection for Send Message / Group Invite, right-click menu (whisper,
  invite, report); a dimmed row says why ("Delisted" on the row, "Not in
  your activity filter." in its tooltip); Unlist is the game's window.
- **Who** (`GroupFinderWho.lua`): the query box and filter menu (class, race,
  zone, sort) on the tab row; `SendWho` from Enter or Search only; a card per
  player (name, level, race, class; zone, guild) with an invite button, click
  to whisper, right-click the player menu; the "first 50 of n" note. No
  column switch (the stock column is fixed to zone on this client).
  `SetWhoToUi(true)` while the page shows.
- Player names (Who cards, Browse leaders) go through `ns.NameText`: on a
  font family (`ns.NameFont`: Polestar's face for Latin, the client's for
  Cyrillic, Hangul and Chinese) the engine picks the face per glyph and
  nothing reads the name (a name drew as boxes in Polestar's face live).
  Without font families, the old scan: past Latin-1 and not CJK,
  `GameFontHighlight`.
- Every client API a page calls is feature-detected (the `groupfinder` scene
  loads no page stub).
- Tests: `stub_groupfinder.lua` (frame, keys, the hardware guard),
  `stub_lfglisting.lua`, `stub_lfgbrowse.lua`, `stub_who.lua`; scenes
  `groupfinder`, `-switch`, `-combat`, `groupfinder-listing`,
  `-listing-activities`, `-listing-listed`, `-listing-locked`,
  `-listing-comment`, `groupfinder-browse`, `-browse-actions`, `-browse-timeout`,
  `groupfinder-who`, `-who-more`, `-who-door`.

## Reference plan: LFGParentFrame -> Polestar

### What the client has (settled in game)
- `C_LFGList.GetPremadeGroupFinderStyle()` is `2` (Vanilla). `PVEFrame` is nil,
  and `Blizzard_GroupFinder` and `Blizzard_PVPUI` are not loaded (the user's
  check 1).
- The Group Finder is therefore `LFGParentFrame`, from the load-on-demand
  addon `Blizzard_GroupFinder_VanillaStyle`. `SetLookingForGroupUIAvailable`
  (`Blizzard_LFGUtil/Camelot/LFGUtil.lua`) loads it through
  `GroupFinderVanillaStyle_LoadUI`.
- It is **premade groups only**: post a listing, browse listings, and a Who
  list. There is no Dungeon Finder queue, no Raid Finder, no applications:
  you join a group by whispering or inviting its leader. There is no Mythic+.
- **PvP is not in this window.** The client has no `PVEFrame`/`PVPUIFrame`.
  `.ref` has no Camelot battleground queue frame either: the only one,
  `Blizzard_UIPanels_Game/Cata/PVPFrame.lua`, is Cata-only. What Camelot does have:
  - the Character window's PvP rank page (`PVPRankFrame`, `TOGGLECHARACTER4`),
    which our Character window already covers;
  - the premade "Battlegrounds" category (id 118) in this finder;
  - battlemasters (minimap tracking).
  Check 3 shows whether the live client has a battleground queue frame
  (for example one a battlemaster opens). If it does, that is a **separate
  window to plan later**, likely an NPC window (`ns.Interaction`). Nothing PvP
  is planned here beyond the Battlegrounds premade category.

### Size and shell
**620×560**: a 48px slim rail plus 572 of content, on the compact grid
(`ns.Compact`). The stock window is 458×535 plus its side tabs. Ours needs the
width for the browse row (leader, activities, member display, level,
comment) and the Who columns. The shell is `W.Shell("PolestarUIGroupFinder",
{ scalePath = "ui.menuScale", width = 620, height = 560, rail = true })`, with
`ns.GameRail`, `ns.Dock`, `ns.WindowMenu` and `Polestar.CloseOnEscape`.

- **Page nav: a slim icon rail.** With `LFGVANILLA_SETTING_MODERN_STYLE = true`,
  the stock window hides its text tabs (`Tab1..3`). It shows the three
  `LargeSideTabButtonTemplate` side tabs instead (`ListingTab`, `BrowsingTab`,
  `WhoListingTab`, `LFGParentFrameMixin:UpdateTabs`). Icon side-tabs become
  `ns.GameRail(f, items, active, onSelect, { slim = true })`, with labels in
  tooltips:
  - Listing (`INV_SideTab_GroupFinder_c60`): "Create a Listing", or "Edit
    Listing" while listed (`LFG_LIST_TAB_1` / `LFG_LIST_EDIT`).
  - Browse (`INV_SideTab_GroupBrowsing_c60`, `LFG_LIST_TAB_2`).
  - Who (`INV_SideTab_WhoList_c60`, `LFG_LIST_TAB_3`).
- **Band:** title "Group Finder". The subtitle starts with the subject,
  then the page's fact: "Level 42 Mage · Listed for 3 activities", "Level 42
  Mage · 18 groups", "Level 42 Mage · 27 players found". The stock eye
  portrait animates while listed (`UpdateEyePortrait`). Ours leaves it out:
  the subtitle carries "Listed".
- **Tab row** (the page's own views and controls, as Guild's):
  - Listing: no tabs; "‹ Categories" (the stock Back) while choosing
    activities.
  - Browse: category and activity pickers, the options button (sliders),
    and Refresh.
  - Who: the shell's search (the Who query) and a filter button.
- **Opens** on the last page used. The stock binding opens Listing (tab 1).

### Parts
| Stock part (S/ = `Blizzard_GroupFinder_VanillaStyle`) | Polestar element | API + example call site | Risk / gotcha |
|---|---|---|---|
| `LFGParentFrame` (458×535, `UIPanelWindows` area left) | `W.Shell` + `ns.GameRail` slim | `build` in `Guild.lua` / `Professions.lua` | its OnShow/OnHide run `UpdateMicroButtons`: never touched (rule 8) |
| Side tabs `ListingTab/BrowsingTab/WhoListingTab` | rail items with the stock icons | `ns.GameRail` (`Core.lua`) | text tabs `Tab1..3` are hidden in the modern style: not built |
| **Listing: category view** (`LFGListingCategorySelection_*`, `LFGLISTING_CATEGORY_TEXTURES` atlases) | category cards: the stock `groupfinder-button-*` atlas cropped as art, name, click to choose (`C_LFGList.GetAvailableCategories`, `GetLfgCategoryInfo`) | `newCard` in `Professions.lua` | the art is a game texture (the Two Families Rule) |
| **Listing: activity view** (`LFGListingActivityView_*`: tree of activity groups and activities with checkboxes, level range, trivial/difficult colour, instance-lock warning) | `W.Scroll` rows: `W.SectionHeader` + fold chevron per activity group with a tri-state group checkbox, `W.Checkbox` per activity, level "40–45" in Number textMuted, name in the difficulty colour via `Theme.Legible`, a lock glyph with "n/m bosses" tooltip from `GetSavedInstanceInfo` | `group` in `CharacterPages.lua` | `GetAvailableActivities(categoryID)` filtered by level unless the CVar is set (`LFGUtil_GetFilteredActivities` logic, reimplemented); cap `Constants.LFGConstsExposed.GROUP_FINDER_MAX_ACTIVITY_CAPACITY`; `RequestRaidInfo()` on show |
| Playstyle dropdown (required) | `W.Button` + `W.ShowMenu` (Learning, Fun Relaxed, Fun Serious, Expert: `GetGeneralPlaystyleString`) | `filterMenu` in `Crafting.lua` | Post greyed "Playstyle required" until set |
| "Ignore level ranges" checkbox + options menu (`disableSuggestedLevelActivityFilter`) | Listing: a check on the tab row's right end; Browse: the sliders menu | — | a CVar: `SetCVar` from ours is fine; redraw on `CVAR_UPDATE` |
| Voice chat dropdown (`VoiceChatDropdown`: None/Discord/Legacy/Custom) | `W.ShowMenu` radio-style items | — | sets the `voiceProvider` CVar as stock does when leader |
| Comment box (`StoreSecureReference("LFGListingComment")`, `SetSecurityDisableSetText`) | **not ours**: a secure stock box. Ours posts with no comment. A category with `autoChooseActivity` (comment mandatory) is **posted from the game's window** | — | the client reads the stock box; addons cannot set it |
| Solo roles (`SoloRoleButtons`: `C_LFGListRoles.GetSavedRoles/GetRoles/SetRoles`) | three role toggles (stock atlases `groupfinder-icon-role-large-*`) | `ns.ItemWell` | saved on post (`SaveSoloRoles`) |
| Group role (`GroupRoleButtons`: role dropdown `UnitSetRole`, role icon, **Role Poll** `InitiateRolePoll`) | role menu + "Role check" button (leader/assistant only) | — | `UnitSetRole` is HasRestrictions: click only |
| New player friendly (`lfgNewPlayerFriendly` CVar) | `W.Checkbox` / `W.Switch` | — | leader only (`LFGListingUtil_CanEditListing`) |
| Post / Update button (`LFGListingPostButton_*`) | footer primary: "List Group" solo, "List Party" in a group, "Update" while listed (stock strings) | `paintFooter` in `Crafting.lua` | enable logic as `UpdatePostButtonEnableState` (leader, cap, playstyle, dirty, group size vs `maxNumPlayers`), reason in tooltip via `ns.SetEnabled(b, on, why)` |
| Back / Unlist button | "‹ Categories" on the tab row (clears) / footer left "Unlist" (a `game = true` footer spec: the game's window unlists) | the registry's game door | `RemoveListing` is protected (live check 6) |
| Locked view (not leader: `LFGListingLockedView_RefreshContent`) | body text "Only the leader can…" + the active entry's activities by group | — | |
| Listing expired popups (`LFG_LIST_ENTRY_EXPIRED_*` StaticPopups) | **left stock** (the stock frame shows them from its own events) | — | StaticPopup is never replaced |
| **Browse: category dropdown, activity multi-select dropdown, reset** (`LFGBrowseCategoryDropdownMixin`, `LFGBrowseActivityDropdownMixin`) | tab row: category `W.ShowMenu`; activity picker as a `W.ShowMenu` of checked items by activity group (flat: group names as disabled headers) + "Reset" | `targetMenu` in `Crafting.lua` | `W.ShowMenu` has no submenus: flat with headers |
| Refresh / search (`LFGBrowse_DoSearch`) | Refresh icon button (`W.IconButton(.., "refresh")`), greyed while searching | — | `C_LFGList.Search(cat, 0, 0, nil, false, nil, activityIDs)`: click only |
| Results list (`LFGBrowseSearchEntry_Update`: leader name, class colour, level, activity names matched in blue / others grey, own listing green, delisted grey, member display by `Enum.LFGListDisplayType`: role counts, role or class enumerate, player count, comment, solo roles) | `W.Scroll` rows: name (leader for a solo listing), activities line, member display as role or class atlases (`groupfinder-icon-role-large-*`, `groupfinder-icon-class-*`), comment in textDim (kstring: `SetText` only) | `ns.SpellRow` shape | names and comments are kstrings: never read, compare or concatenate; sort as stock (`LFGBrowseUtil_SortSearchResults` logic on the non-kstring fields) |
| Result tooltip (`LFGBrowseSearchEntryTooltip_UpdateAndShow`: members, classes, roles, encounters `GetSearchResultEncounterInfo`, matching activities) | our tooltip from the same APIs (`W.Tooltip` / `GameTooltip` lines) | `newSlot` in `Character.lua` | |
| Selection + Send Message / Group Invite buttons | row selection; footer "Whisper" and "Invite" (Invite only for a solo listing, and when the player can invite: `LFGBrowseUtil_GetInviteActionForResult`) | `Social.lua` (`ChatFrameUtil.SendTell`, `C_PartyInfo.InviteUnit`) | |
| Row right-click menu (whisper, invite, Report group, Report advertisement) | `W.ShowMenu`: Whisper, Invite, Report…, Report advertisement (`ReportFrame:InitiateReport`, as `Social.lua` does) | `Social.lua` | |
| Delist button (Browse, while listed) | footer left "Unlist" (`game = true`) | the registry's game door | as above |
| `LFG_LIST_SHOW_SEARCH` (game asks to browse activities) | **stays the game's** (the stock frame opens itself) | — | rule 8 |
| **Who: edit box + Search, results (name, level, race, class colour, zone, guild), invite button per row, right-click player menu, totals, filters (class, race, zone, sort and order)** | search box on the tab row (`OnEnterPressed` -> `C_FriendList.SendWho(text, Enum.SocialWhoOrigin.Social, filters)`), player cards (no column picker: on this client the stock variable column is fixed to zone, `whoSortValue = 1`, and there are no sort headers; sorting is in the filter menu), an invite icon button per row, right-click `FriendsFrame_ShowDropdown(name, 1)`, totals in the subtitle, filter menu (flat: class, race, zone, sort) with `C_FriendList.GetWhoRaceFilters`, `SortWho` | `Social.lua` (rows, menu) | `SetWhoToUi(true)` while the page shows, `false` on hide (as stock); `SendWho` is HasRestrictions: Enter/click only; invite via `C_PartyInfo.InviteUnit` (stock `UnitPopupSharedUtil.TryInvite`'s confirmation is for cross-faction/realm: reuse the same `UnitPopup` path if a check shows it matters) |

### Strategy
**Replace.** The deciding line: "Do its OnShow/OnHide touch secure frames
(`UpdateMicroButtons`)? -> replace, never show/hide the stock one".
`LFGParentFrameMixin:OnShow`/`OnHide` call `UpdateMicroButtons`. So it gets
`ns.Doors` only, and a shift-click on the micro button opens the stock window.
No other code writes into `LFGParentFrame`. Nothing is rerouted, so the
switch is live (not `reloadOff`). The addon is load-on-demand: ours never
loads it. It reads only C APIs (`C_LFGList`, `C_LFGListRoles`,
`C_FriendList`) and works whether or not the stock addon is loaded.

### Doors
- `TOGGLEGROUPFINDER` (key; `Bindings.xml` of the addon: `LFGVanilla_ToggleFrame(1)`)
  -> ours, Listing page: `ns.Doors`.
- `TOGGLEWHOTAB` (key; `Bindings_Camelot.xml`: `LFGVanilla_ToggleFrame(LFG_TAB_WHO)`)
  -> ours, Who page: `ns.Doors`. **`docs/windows/social.md` says this key stays
  the game's; it changes to ours when this is built (update that line then).**
- `TOGGLELFGTAB` / `TOGGLELFMTAB` appear in the tab tooltips. If check 2 shows
  them bound, they map to Listing and Browse.
- `LFDMicroButton` (`GetToggledFrame` -> `LFGParentFrame` for style 2) ->
  ours: the `ns.Doors` overlay. Shift-click opens the stock window from secure
  code.
- **Stay the game's** (rule 8: taking them means hiding `LFGParentFrame` after
  the game showed it):
  - the queue eye's click and menu (Camelot `QueueStatusButtonMixin:ShowLFGFrame`
    -> `LFGVanilla_ToggleFrame/ShowFrame`; its menu "View group" / "Unlist my
    group");
  - `ShowWhoPanel` (FriendsFrame, Camelot);
  - `LFG_LIST_SHOW_SEARCH`;
  - `LFGParentFrame_SearchActiveEntry` after a post in the game's window
    (after a post in ours, ours goes to Browse and searches it);
  - the minimap entry (off: `LFGVANILLA_SETTING_SHOW_ON_MINIMAP = false`).
- **`/who` results** the client sends to the UI (`WHO_LIST_UPDATE`: a long
  `/who` from chat, or any while our Who page shows) open **ours** on the Who
  page. The stock `LFGWhoListFrame` would show the game's window on that event
  (`UpdateWhoList`), so while ours is on that one event is unregistered on it
  (the user's leave: `docs/CLIENT.md`, rule 15's Who list exception) and
  registered again when switched off. Short `/who` results still go to chat.

  The "..." menu says: "The game's window: shift-click the Group Finder
  button."
- `M.stock()` returns `LFGParentFrame` when it is shown (the stock-side
  "Polestar" switch button).
- **Posting with a comment** (a mandatory-comment category, or a player who
  wants one) is the game's window. The footer shows "Post with a comment…"
  with a secure overlay on UIParent, placed out of combat (rules 4, 10), as
  `gameWindowDoor` in `Core.lua`: PreClick hides ours, then `/click
  [nocombat] LFDMicroButton`. If the Core door is generalised (a door without
  the switch-off), that is a stage 1 change in `Core.lua`.

### Taint and combat
**Rule: every call marked `HasRestrictions` runs only from our own `OnClick` /
`OnEnterPressed`. Never from OnShow, an event, a timer or a hook.** No
auto-search on show: the stock window searches on its own events, and ours
waits for Refresh. A change of category or activity filter calls `Search`
only when the player clicked that change.

| Action | API | Docs | Decision | Check |
|---|---|---|---|---|
| Browse search | `C_LFGList.Search` | HasRestrictions | ours, click only; no text (the Vanilla finder has none) | 4 |
| Read results | `GetFilteredSearchResults`, `GetSearchResultInfo`, `...MemberCounts`, `...LeaderInfo`, `...PlayerInfo`, `...EncounterInfo` | SecretArguments only | ours; kstrings shown via `SetText` only | — |
| Post a listing | `C_LFGList.CreateListing({activityIDs, newPlayerFriendly, generalPlaystyle, voiceMode})` | HasRestrictions | ours, no comment; mandatory-comment categories -> game window | 5 |
| Update a listing | `C_LFGList.UpdateListing` | HasRestrictions | ours, after `C_LFGList.CopyActiveEntryInfoToCreationFields()` (as `LoadActiveEntry`) so the existing comment is kept; if 6 shows the comment lost or the call refused -> game window | 6 |
| Unlist | `C_LFGList.RemoveListing` | protected (BLOCKED live) | **the game's window** (the `game` door) | 6: blocked |
| Roles | `C_LFGListRoles.SetRoles` | SecretArguments | ours | — |
| Group role | `UnitSetRole` | HasRestrictions | ours, click only (needs a group: first live test) | open |
| Role poll | `InitiateRolePoll` | — | ours (leader/assistant) | open |
| Invite / whisper | `C_PartyInfo.InviteUnit`, `ChatFrameUtil.SendTell` | SecretArguments | ours (as `Social.lua`) | — |
| Report | `ReportFrame:InitiateReport` | (C_ReportSystem.SendReport is restricted) | ours as `Social.lua` (already in use); the report is sent from the game's dialog | — |
| Who search | `C_FriendList.SendWho` | HasRestrictions | ours, Enter/click only | 4 (same class) |
| Who to UI | `C_FriendList.SetWhoToUi` | — | true while our Who page shows, false on hide | — |

- **A FORBIDDEN or BLOCKED result** moves that action to the game's window,
  through the "Post with a comment…" style secure door. A macro `/run` is
  insecure too, so no secure button can call these for us.
- **Stock Lua state is never written or called.** The stock mixins
  (`LFGListingFrame`, `LFGBrowseFrame`, `LFGUtil_*`, `LFGBrowseUtil_*`,
  `LFGWhoListFilterUtil`) are left alone. Their logic is reimplemented on
  our own tables.
  - `C_LFGList.ClearCreationTextFields` and `CopyActiveEntryInfoToCreationFields`
    change the client's creation fields, which the stock box shows. This is
    client-side and harmless. Ours never calls `ClearCreationTextFields`
    while listed, or the player's comment would be wiped before an update.
  - `SetWhoToUi` is a client flag the stock Who page also sets. If both are
    shown and one hides, Who results go to chat. Accepted (rare).
- **kstrings:** `name`, `comment` and `voiceChat` of results go only to
  `W.Text:SetText`.
- **Combat:** none of these calls is blocked in combat. Our window has no
  secure children: the comment door sits on UIParent and hides on
  `PLAYER_REGEN_DISABLED`. Unit names may be secret: use `ns.Clean`. The
  switch is refused in combat.
- **Fonts** via `W.Text` (rule 2). **Lists** redraw after each of our changes
  (rule 6). **Gamepad UI:** module off by default.

### Tests
- `node tools/new-window.js groupfinder LFGParentFrame` (its stock-icon
  `ns.GameRail` scaffold is close to what this needs; make it slim). This file
  already exists and is kept. The .toc line goes before Tooltips.
- `tests/lua/stub_groupfinder.lua`:
  - `LFGParentFrame`, whose `Show`/`Hide` error from addon code; `LFDMicroButton`;
    the bindings `TOGGLEGROUPFINDER` and `TOGGLEWHOTAB`.
  - `C_LFGList`: categories with atlases, one `autoChooseActivity`; activity
    groups and activities with levels; search results of every
    `LFGListDisplayType`; the active entry. `C_LFGListRoles`; `C_FriendList`
    Who results and filters; `GetSavedInstanceInfo`.
  - kstring stand-ins that error on `..`, `==` and `#`.
  - **A hardware guard:** `stub.hardware` is true only inside
    `stub.RunScript(.., "OnClick" | "OnEnterPressed")` and `stub.pressKey`.
    `Search`, `CreateListing`, `UpdateListing`, `UnitSetRole` and `SendWho`
    error outside it.
  - Records go to `stub.searched`, `stub.listing`, `stub.who`,
    `stub.invited` and `stub.whisper`.
- Scenes, one per state; every scene ends with `stub.assertNoErrors()`:
  - `groupfinder`: keys and micro overlay, rail labels, the game door, the
    guard; `groupfinder-listing`: the category cards.
  - `groupfinder-listing-activities`: fold, group tri-state, level colours, lock
    warning, playstyle required, Post enabled, Post records the listing.
  - `groupfinder-listing-listed`: "Edit Listing" tooltip, Update keeps the comment
    (the copy call recorded before the update), Unlist.
  - `groupfinder-listing-locked`: not leader.
  - `groupfinder-listing-comment`: an `autoChooseActivity` category points to the
    game's window.
  - `groupfinder-browse`: Refresh records the search with the activity
    filter; every display type; delisted; own listing; tooltip.
  - `groupfinder-browse-actions`: whisper, invite only for a solo listing,
    menu.
  - `groupfinder-who`: Enter sends the query with filters; cards;
    invite; `SetWhoToUi` on and off. `-who-more`: past 50 results;
    `-who-door`: the Who list exception, switch off and on.
  - `groupfinder-combat`.
  - `groupfinder-switch`: off makes the keys and micro button the game's;
    then on again.
- Bless `node tools/preview.js groupfinder*`, `git diff --stat tests/golden`,
  look at the PNG, `npm test`. DESIGN.md index row (Group Finder,
  `LFGParentFrame`; high; planned; this file), CHANGELOG line at build.

### In-game checks still needed
Run them out of combat, solo, in order. Line 1 prints any block the later
lines cause; BugGrabber also keeps them. No line touches a stranger's group.
Line 5 lists you publicly for a moment, and line 6 removes the listing.

1. `/run F=CreateFrame("Frame")F:SetScript("OnEvent",print)for _,e in ipairs{"ADDON_ACTION_FORBIDDEN","ADDON_ACTION_BLOCKED","MACRO_ACTION_FORBIDDEN","MACRO_ACTION_BLOCKED"}do F:RegisterEvent(e)end`
2. `/run print(GetBindingKey("TOGGLEGROUPFINDER"), GetBindingKey("TOGGLEWHOTAB"), GetBindingKey("TOGGLELFGTAB"), GetBindingKey("TOGGLELFMTAB"), LFDMicroButton:IsShown())`
3. `/run print(PVPFrame, BattlefieldFrame, PVPBattlegroundFrame, HonorFrame, GetNumBattlegroundTypes(), C_PvP.GetRandomBGInfo().name)`
4. `/run C_LFGList.Search(2,0,0,nil,false,nil,C_LFGList.GetAvailableActivities(2)) C_Timer.After(2,function() print(C_LFGList.GetFilteredSearchResults()) end)`
5. `/run local a=C_LFGList.GetAvailableActivities(2) print(C_LFGList.CreateListing({activityIDs={a[1]},generalPlaystyle=1}))`
6. `/run C_LFGList.CopyActiveEntryInfoToCreationFields() C_LFGList.UpdateListing({activityIDs=C_LFGList.GetActiveEntryInfo().activityIDs}) C_LFGList.RemoveListing()`

How to read them:
- 2: which keys to take.
- 3: any table or a battleground count means a battleground queue window
  exists, to plan separately; all nil means there is none.
- 4–6: nothing printed by line 1, plus the game's answer (a result count,
  `true`, the listing gone), means ours can call them. A FORBIDDEN or
  BLOCKED line means that action goes to the game's window.
- Not covered solo: `UnitSetRole`, `InitiateRolePoll` (they need a group).
  The first live test covers them.

### Build split (after the checks)
Each agent owns its files. Stage 1 lays down the shared files and the .toc
lines.

- **Stage 1: shell and doors (Opus, 1 agent).**
  - The scaffold.
  - `Modules/GroupFinder.lua`: shell, slim rail, band, footer plumbing, a
    page registry `ns.GroupFinder = { pages = {}, Paint, Footer }`,
    `ns.Doors` for both keys and the micro button, `M.stock`, `ns.Module`.
  - Empty `Modules/GroupFinderListing.lua`, `GroupFinderBrowse.lua` and
    `GroupFinderWho.lua`, with their .toc lines after `GroupFinder.lua`.
  - `tests/lua/stub_groupfinder.lua` (base frame, bindings, hardware
    guard); scenes `groupfinder-switch` and `groupfinder-combat`.
  - The Core door if generalised; the DESIGN.md row.
- **Stage 2: pages, in parallel.**
  - A (Opus: restricted posting and update): `GroupFinderListing.lua` +
    `tests/lua/stub_lfglisting.lua` + scenes `groupfinder`, `-activities`,
    `-listed`, `-locked`, `-comment`.
  - B (Opus: restricted search, kstrings): `GroupFinderBrowse.lua` +
    `tests/lua/stub_lfgbrowse.lua` + scenes `groupfinder-browse`,
    `-browse-actions`.
  - C (Sonnet: one restricted call on a known pattern): `GroupFinderWho.lua`
    + `tests/lua/stub_who.lua` + scene `groupfinder-who`.
- **Stage 3.**
  - Haiku: bless goldens, `npm test`.
  - Opus: review against CLIENT.md, finish this doc as the catalogue entry,
    update `social.md`'s Who line.
  - The lead: the CHANGELOG line.
  - The user: in game, post, update, unlist, browse, whisper and invite,
    Who; BugGrabber clean.

### Open questions
- A battleground queue window on Forever (check 3): if there is one, it gets
  its own plan.
- The posting comment: ours posts without one. Is a game-window link for
  posting with a comment enough? Or should mandatory-comment categories hide
  from ours?
- Stock's tree of activities vs flat menus in Browse (no submenus in
  `W.ShowMenu`): flat with group headers is planned.

## Live check results (2026-11-15)
- Group Finder key is bound ("I"); TOGGLEWHOTAB, TOGGLELFGTAB, TOGGLELFMTAB unbound; LFDMicroButton shown.
- No PvP frames (PVPFrame, BattlefieldFrame, PVPBattlegroundFrame, HonorFrame all nil); GetNumBattlegroundTypes() = 3. PvP queue window: not on this client's finder; a battlemaster window may exist, plan later.
- C_LFGList.Search from insecure code: works (100 results).
- C_LFGList.CreateListing from insecure code: works (true).
- CopyActiveEntryInfoToCreationFields + UpdateListing: no block reported.
- C_LFGList.RemoveListing: ADDON_ACTION_BLOCKED (protected). Unlist must go through the game's window (secure button that opens it, or tell the player), never our insecure click.
