# Addons: other addons with Polestar: UI

`Addons/<Addon>.lua` holds every line of code that knows a third-party addon:
a skin of its frames (Baganator), or its data in one of our windows (What's
Training?, Talents Forever). Every such file:

- loads after every module (the end of `Polestar_UI.toc`) and never names its
  addon in `## OptionalDeps`: we do not suggest installing those addons
  alongside ours. It wraps its whole body in `ns.AfterLogin(function() ... end)`
  (Core.lua; runs at PLAYER_LOGIN before the modules are enabled), so its
  addon's globals and saved variables are there whatever the load order;
- returns at once when the addon (or the API it uses) is not there: no
  module, no `/pui` entry, no tab or button; every scene without the addon's
  stub runs that path;
- reads the addon's public API only (its documented globals and callbacks),
  never its private state or namespace, and calls it in `pcall` where a
  failure would break our window;
- plugs into one of our windows only through the small extension point that
  window exposes (below), never by reaching into its locals;
- has a stub of the API it uses (`tests/lua/stub_<addon>.lua`) and a scene.

## Skins

A skin repaints another addon's frames in Polestar's look; the addon keeps
its own layout, features and settings. A skin:

- uses the addon's own skin API where it has one, never hooks its code;
- restyles as the tooltips do (docs/CLIENT.md, rule 15): the addon's art
  faded with `SetAlpha`, a ground and hairlines of ours added
  (`ns.PaintGround`, `ns.Hairlines`, `ns.PaintHairlines`, `ns.FadeNine`),
  kept in weak tables, never a key of ours on its frames; template keys read
  with `rawget`;
- is a module with `Apply` (`ns.Module(key, { noun = "<Addon> skin" })`), so
  `/pui <key> off` gives the addon's own look back at once, and repaints on
  `Theme.OnChanged` (scheme, skin, accent, background opacity).

## Baganator (`Addons/Baganator.lua`, `/pui baganator`)

Baganator 857's public skin API is `Baganator.API.Skins`: `RegisterListener(fn)`
(each frame Baganator makes, as `{ regionType, region, tags }`),
`GetAllFrames()` and `GetCurrentSkin()`. It cannot add an entry to
Baganator's own skin list (that is `addonTable.Skins.RegisterSkin`, private),
so ours paints over Baganator's default skin, **Blizzard**: the player
chooses Blizzard in Baganator's settings (Customise, Skin) and gets
Polestar's look; any other Baganator skin (Dark, ElvUI, ...) is left as
Baganator draws it. Each frame remembers the skin it was made under
(Baganator makes a new set of frames per skin).

| Region type | Ours |
|---|---|
| `ButtonFrame` (views, ButtonFrameTemplate) | NineSlice pieces, `Bg`, `TopTileStreaks` and the Inset's art faded; `Theme.Skin(f, "window")`, the very paint of our own windows (ground at Polestar's Window opacity, border, shadow, in every Polestar skin; `psBare` hides it when off: these keys go on Baganator's own view frame, which no secure code reads); title in the `title` face and `text` colour; the red close button's art faded under our close glyph (`icon`, `iconHover` on hover) and hover wash. `Bg` faded again on each show. Baganator's transparency slider only fades its own art, hidden while ours is on: Polestar's Window opacity sets the ground |
| `IconButton` (title-bar toggles, gear, sort, transfer, search row) | as our header buttons (`W.IconButton`): no frame, the icon desaturated in `icon` (`iconHover` on hover), the hover wash |
| `Button`, `TabButton`, `TopTabButton`, `SideTabButton` | the template's thirds / `Background` and highlight faded; `control` fill, `border` hairlines, the hover wash. Labels in our font objects per state (`SetNormal/Highlight/DisabledFontObject`: `label` face in `buttonText`/`text`/`textMuted`; tabs `textDim`/`text`/`text`), which the client applies on hover and enable. A selected tab (`PanelTemplates_SelectTab` disables it) on the `selected` wash with an accent line at its foot; `PanelTemplates_SelectTab`/`DeselectTab` post-hooked to follow it and set our disabled font again |
| `SearchBox`, `EditBox` | thirds faded; `inputBg` fill, `border` hairlines |
| `InsetFrame` | NineSlice and `Bg` faded; Polestar's inset well |
| `ItemButton` | `SlotBackground`, normal texture and the quality ring (`IconBorder`) faded; an `inputBg` well with hairlines round the icon, in the item's quality colour from uncommon up (`border` wash for poor and common), as `ns.PaintItem`. The ring's `SetVertexColor`/`Show`/`Hide`/`SetShown` are post-hooked to follow quality changes; nothing else on the secure item button is touched. Left alone when Masque is loaded |
| `CategorySectionHeader` | the label in the `heading` face, `textDim`; the arrow desaturated in `textMuted` |
| `Divider` | the texture faded; a `divider` hairline along its frame's top |
| `CornerWidget` | untouched: Polestar's own upgrade arrow, step glow, lock and quest mark are Baganator corner widgets (`Gear/Bags.lua`, `QoL/BagGlow.lua`, `Quests/BagMarks.lua` in Polestar), drawn once |
| `TrimScrollBar`, `CheckBox`, `Slider`, `Dropdown`, `Dialog` | Baganator's (its Customise dialog) |

**Beside our Bags window:** two bag windows would fight over B and the bag
openers, so with Baganator loaded our Bags module starts off: the skin sets
`defaultOff` on it, which `ns.Enabled` reads when there is no saved choice.
`/pui bags on` (a saved choice) still wins.

**Tests:** `tests/lua/stub_baganator.lua` (the API and a backpack view in
Baganator's shapes, stock art as colour textures); the `baganator` scene
(painted, header buttons and close glyph, the selected tab followed, our label fonts, a quality change followed, our Bags off, off and on again, a view
on another Baganator skin left alone). Every other scene loads without
Baganator, so the skin's no-op path runs in all of them.

**In game:** with Baganator on its Blizzard skin, open the bags, the bank
and the guild bank: Polestar's ground, hairlines and fonts; slots edged by
quality; Polestar's upgrade arrows and quest marks still shown once; use,
split and sell items, in combat too (no `ADDON_ACTION_BLOCKED`); change
Polestar's scheme and skin (the bags follow); `/pui baganator off` and on;
pick Dark in Baganator (ours stands aside), then Blizzard again; Baganator's
transparency slider, then reopen; `/pui` shows bags off.

## What's Training? (`Addons/WhatsTraining.lua`, addon `WhatsTraining`)

Reads its public `WT_API` (`GetSpells`, `Status`, `RegisterCallback`): a
"Training" top tab in our Spellbook (docs/windows/spellbook.md, "Training")
and "What's Training?" in its "..." menu (its LibDataBroker launcher
`WhatsTrainingMinimap`, `OnClick`). Without `WT_API.GetSpells` and `Status`
the file returns. `GetSpells` runs in `pcall`.

Extension point: `ns.modules.spellbook.pages`, a list of extra top-tab pages
after the book's: `{ key, label, icon, subtitle(), paint(f) -> body height,
hide(), option(button) -> a "..." item or nil }`; the title is `label`, the
subtitle the character then `subtitle()`; a search shows the book's results
over it. `ns.modules.spellbook.Refresh()` redraws the open book (registered
on its Ready, SpellsChanged, LevelChanged and IgnoredChanged callbacks).

**Tests:** `tests/lua/stub_whatstraining.lua`, the `spellbook-training` scene.

## Talents Forever (`Addons/TalentsForever.lua`, addon `TalentsForeverBook`)

Reads `TalentsForeverBook` (`Toggle`, `db.settings.overlay`, `plan`,
`NextUp`, `Game.Node`, `On`) and `TalentsForeverBookData`: a footer button to
its planner and its next planned point ringed in our Talents
(docs/windows/talents.md, "Talents Forever"). Without `Toggle` the file
returns. Every call into it runs in `pcall`; its Apply is never called.

Extension point: `ns.modules.talents.extras`, a list of `{ button = { label,
onClick, tip, tipLines } (a footer button after Reset), paint(f, nodes)
(after the trees are drawn; `nodes` are our node buttons, `psNode` their node
ID) }`. Its `PLAN_CHANGED`/`GAME_CHANGED` redraw the shown window out of
combat (`ns.modules.talents.Show()`).

**Tests:** `tests/lua/stub_talentsforever.lua`, the `talents-forever` scene.

## EllesmereUI (`Addons/EllesmereUI.lua`, addon `EllesmereUI`)

EllesmereUI's friends list (`EllesmereUI_FriendsList.lua`, in the core
addon; on Forever started by EllesmereUIBlizzardSkin's Friends List card)
groups Battle.net friends in sections of its own. Our Social's Friends page
shows those sections from **its** saved data, `EllesmereUIDB.global`, never a
copy (an exception to "public API only": the user's groups live nowhere
else):

- read: `friendGroups` (`{ name, collapsed }`), `friendGroupsByTag` (key:
  BattleTag, or `"title:"` and `C_BattleNet.GetDefaultTitleWhisperTarget`
  for a friend added by character), `friendGroupColors` (`{ r, g, b }`, the
  head's name tint; ours `textDim` without), `friendGroupOrder` (its
  `ValidOrder` rebuilt: Favorites first if missing, new groups before the
  ungrouped, those last), `friendFavCollapsed`, `friendUngroupedCollapsed`.
  Missing tables are made as its `Store()` makes them. A friend's section is
  its `BucketOf`: its group, then Favorites (Battle.net's own flag), else
  "Friends" (WoW friends too: it groups Battle.net friends only). Empty
  sections have no head.
- written, each as its own function writes it (`EllesmereUI_FriendsList.lua`,
  verified against the Forever build 9.8.8), then our redraw (its list reads
  the store afresh each time it shows: no refresh call):
  - folding a head: its folded state (`ToggleCollapsed`);
  - head tools, right to left: Move down / Move up (`MoveGroup`: swaps with
    the next shown section in `friendGroupOrder`, the validated order written
    first; off at the ends), the pencil (a group: Polestar's dialog to rename,
    `RenameGroup`: name, colour key, order entry and members; a taken or
    empty name does nothing; its palette button and the palette on Favorites
    and Friends set `friendGroupColors[key]` through the game's colour
    picker, a cancel restoring it), delete (a group, after Polestar's
    confirmation; `DeleteGroup`: the group, its members' tags and colour; the
    order keeps the name until its `ValidOrder` drops it);
  - the game's Battle.net friend menu, opened from our row, gets its
    "EllesmereUI" section: "Add to Group" ("Move to Group" once grouped or a
    favorite) with "New Group..." (Polestar's dialog; `CreateGroup`: trimmed,
    32 letters, then the friend in it), Favorites, its other groups and
    "Remove from Group" (`PlaceFriend`: a group sets
    `friendGroupsByTag[key]`; Favorites and Remove clear it and call
    `BNSetFriendFavoriteFlag(id, on)` only when the flag differs, as its
    `AskFavorite`; the friend moves when the client's
    `BN_FRIEND_INFO_CHANGED` redraws us, as it keeps no pending state).
- not taken: its own menu entries off its list (Set Note, favorite, Tags,
  Remove Friend: the game's menu has them from our row, `friendsList` set),
  the search-only folding, the note-tag migration (it runs on its own list).
- gate: `EllesmereUI.FriendsList` at load; per redraw, the card on
  (`friendsListCard.enabled ~= false`) and `customTiles` (Custom Friends
  List Tiles; unset follows `GetBlizzWindowStyle("socialui") ~= "off"`, in
  `pcall`) on. Off: the stock Favorites/Friends heads.
- the menu entries go in by tag (`Menu.ModifyMenu`, `MENU_UNIT_BN_FRIEND`
  and `_OFFLINE`), only on a client with `Menu.IsMenuProxy` (added entries
  isolated, as EllesmereUI requires for its own) and only while our window
  is shown under the mouse. Taint: they write its saved table and call
  `BNSetFriendFavoriteFlag`, the plain friend function its own added entries
  call from the same isolated menu (its file header: field-checked secure);
  nothing touches Blizzard's friends data. Its own entries need its list on
  screen, so they never show in ours.

Extension point: `ns.modules.spellbook.pages`, a list of extra top-tab pages
after the book's: `{ key, label, icon, subtitle(), paint(f) -> body height,
hide(), option(button) -> a "..." item or nil }`; the title is `label`, the
subtitle the character then `subtitle()`; a search shows the book's results
over it. `ns.modules.spellbook.Refresh()` redraws the open book (registered
on its Ready, SpellsChanged, LevelChanged and IgnoredChanged callbacks).

**Tests:** `tests/lua/stub_whatstraining.lua`, the `spellbook-training` scene.

## Talents Forever (`Addons/TalentsForever.lua`, addon `TalentsForeverBook`)

Reads `TalentsForeverBook` (`Toggle`, `db.settings.overlay`, `plan`,
`NextUp`, `Game.Node`, `On`) and `TalentsForeverBookData`: a footer button to
its planner and its next planned point ringed in our Talents
(docs/windows/talents.md, "Talents Forever"). Without `Toggle` the file
returns. Every call into it runs in `pcall`; its Apply is never called.

Extension point: `ns.modules.talents.extras`, a list of `{ button = { label,
onClick, tip, tipLines } (a footer button after Reset), paint(f, nodes)
(after the trees are drawn; `nodes` are our node buttons, `psNode` their node
ID) }`. Its `PLAN_CHANGED`/`GAME_CHANGED` redraw the shown window out of
combat (`ns.modules.talents.Show()`).

**Tests:** `tests/lua/stub_talentsforever.lua`, the `talents-forever` scene.

## EllesmereUI (`Addons/EllesmereUI.lua`, addon `EllesmereUI`)

EllesmereUI's friends list (`EllesmereUI_FriendsList.lua`, in the core
addon; on Forever started by EllesmereUIBlizzardSkin's Friends List card)
groups Battle.net friends in sections of its own. Our Social's Friends page
shows those sections from **its** saved data, `EllesmereUIDB.global`, never a
copy (an exception to "public API only": the user's groups live nowhere
else):

- read: `friendGroups` (`{ name, collapsed }`), `friendGroupsByTag` (key:
  BattleTag, or `"title:"` and `C_BattleNet.GetDefaultTitleWhisperTarget`
  for a friend added by character), `friendGroupColors` (`{ r, g, b }`, the
  head's name tint; ours `textDim` without), `friendGroupOrder` (its
  `ValidOrder` rebuilt, not written back: Favorites first if missing, new
  groups before the ungrouped, those last), `friendFavCollapsed`,
  `friendUngroupedCollapsed`. A friend's section is its `BucketOf`: its
  group, then Favorites (Battle.net's own flag), else "Friends" (WoW
  friends too: it groups Battle.net friends only). Empty sections have no head.
- written: folding a head flips its folded state (the same keys); the game's
  Battle.net friend menu, opened from our row, gets "Add to group"/"Move to
  group" (its groups, "Remove from group"), which sets or clears
  `friendGroupsByTag[key]` as its `PlaceFriend`. Groups are made, renamed,
  coloured and removed in EllesmereUI only; Favorites stays the menu's own
  favorite switch.
- gate: `EllesmereUI.FriendsList` at load; per redraw, its store present, the
  card on (`friendsListCard.enabled ~= false`) and `customTiles` (Custom
  Friends List Tiles; unset follows `GetBlizzWindowStyle("socialui") ~=
  "off"`, in `pcall`) on. Off: the stock Favorites/Friends heads.
- the menu entries go in by tag (`Menu.ModifyMenu`, `MENU_UNIT_BN_FRIEND`
  and `_OFFLINE`), only on a client with `Menu.IsMenuProxy` (added entries
  isolated, as EllesmereUI requires for its own) and only while our window
  is shown under the mouse; they write saved data and redraw, nothing else.
  Its own entries need its list on screen, so they never show in ours.

Extension point: `ns.modules.social.friendHeads()`, heads for the Friends
page or nil for the stock ones: `{ key, test(e), label(online, total),
shut, fold(), color, tools(first, last) }` (tools: icon buttons `{ icon, tip, fn, off }`, right to left) (`fold` set: the folded state is the caller's);
Battle.net entries carry `account` (the account ID) and `tag` (BattleTag).

**Tests:** `tests/lua/stub_ellesmereui.lua` (its store, `Menu`, the
favorite flag), the `social-ellesmere` and `social-ellesmere-edit` scenes.

**In game (data keys checked against the installed 9.8.8; behaviour
unverified):** with EllesmereUI's groups, open the Social: its sections,
order, colours and folds; fold, move, recolour, rename and delete a group,
then open EllesmereUI's list (same state); right-click a Battle.net friend:
New Group..., Favorites, Remove from Group. After each kind of change,
whisper a Battle.net friend from that menu and from a row click (no taint
error).
