# Addons: other addons with Polestar: UI

`Addons/<Addon>.lua` holds every line of code that knows a third-party addon:
a skin of its frames (Baganator), or its data in one of our windows (What's
Training?, Talents Forever). Every such file:

- loads after every module (the end of `PolestarUI.toc`) and never names its
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
openers, so with Baganator loaded our Bags and Bank are blocked (`blockedBy = "Baganator"`,
as beside Bagnon): off whatever was saved and they cannot switch on.

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
transparency slider, then reopen; `/pui help` shows bags off.

## ForeverQuestTint (`Addons/ForeverQuestTint.lua`, addon `ForeverQuestTint`)

ForeverQuestTint (xanastar, GPL-3) marks the quests Forever added (any ID outside the original Classic list) in the stock quest log, giver and map. Our quest log (`Modules/QuestLog.lua`) draws its own rows and details, so it gets the same marks from the addon's saved settings (`ForeverQuestTintDB`, its defaults where a key is unset: `marker*`, `tint`, `objectiveTint`/`objectiveUseTint`/`objectiveColor`, `showTint`, `alpha`, `topAlpha`, `height`). The addon has no public API and its check is private, so this is the one place we **copy its logic**, by the user's decision (both GPL-3): `Addons/ForeverQuestTintData.lua` is its original-Classic quest ranges plus its version, generated by `npm run sync:fqt` (`tools/sync-fqt.js`, reads the installed addon's `.toc` and `VanillaQuests.lua`, fails loudly if the format changed, prints `unchanged` or `old -> new`; run it before a release), and `ns.FQTMarked(id)` is its `IsMarked` (a valid ID above 0 that is in no range; its "preview" testing aid is not copied). The data file keeps a credit and licence header.

Extension point: `ns.QuestLogTint(questID)` (Modules/QuestLog.lua heads it), returning `{ glyph, atStart, objective = {r,g,b}, gradient = {r,g,b,alpha,topAlpha,height} }` for a marked quest, read at each paint: the marker (its `Infinity.tga` icon, or its text symbol) after the title in the list (before it with `markerAtStart`); unfinished objectives in the tint when `objectiveTint`; a vertical wash on the details at a third of its stock alpha (ours is a plain colour on a dark ground, not a tinted parchment). Its settings have no change signal, so a change shows at our next repaint (reopen the log or any list change). Not done yet: the quest-giver dialog, the map's ! and ? pins, Questie's icons.

**Tests:** `tests/lua/stub_foreverquesttint.lua`, the `questlog-fqt` scene (marker only on the marked row, objectives tinted, wash only on the marked quest's details, marker at the start).

**In game:** open the quest log (L, the flyout) with a Forever-added quest and a classic one: the marker beside the first title only; its details with the teal wash at the foot; with ForeverQuestTint's "tint objectives" on, its objectives teal. Change its marker settings, then reopen the log.

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

## Bagnon (`Addons/Bagnon.lua`, addon `Bagnon`)

Bagnon has its own bag and bank windows and takes the bag keys, so with it loaded our Bags and Bank are blocked (`blockedBy = "Bagnon"`): off whatever was saved and cannot switch on. Nothing of Bagnon is read but its presence (`C_AddOns.IsAddOnLoaded("Bagnon")`). Not installed here when written: the bank takeover is from Bagnon's own description, unverified in game.

**Tests:** `tests/lua/stub_bagnon.lua`, the `bags-bagnon` scene (both blocked, a saved choice too; the switch refused with its line; the settings toggle greyed).

## Immersion (`Addons/Immersion.lua`, addon `Immersion`)

Immersion shows gossip and quest dialogs itself, so with it loaded our Gossip and Quest dialog start off (`defaultOff`; two dialogs would open together). A saved choice wins: `/pui gossip off` and `/pui questdialog off`, then /reload, for anyone who switched them on.

**Tests:** `tests/lua/stub_immersion.lua`, the `immersion` scene.

## Auction house addons (`Addons/AuctionHouse.lua`)

Our Auction window takes the Auctioneer interaction, so the game's `AuctionHouseFrame` never loads, and addons built on it find nothing to attach to. With one loaded, our Auction starts off (`defaultOff`; a saved choice wins: `/pui auction off`, then /reload, to use the game's window): Auctionator, AHledger, CraftProfit, TradeSkillMaster, Undying (not its Undying_Data or Undying_World) and NaowhForever (the last two add their scan button on AuctionHouseFrame).

**Tests:** `tests/lua/stub_auctionator.lua`, the `auction-addons` scene.

## Questie (`Addons/Questie.lua`, addon `Questie`)

Questie draws its map icons on `WorldMapFrame` alone: each icon is one frame, handed to its own HereBeDragons-Pins copy (a `QuestieLoader` module, not the LibStub library, so a standalone or another addon's HereBeDragons never replaces it), which parents it to a pin of the stock map. Our map is another canvas, so ours mirrors them: for the shown map, a frame of our own per icon (its art, colour, overlay and objective glow, at its spot and at the frame level Questie gives it, so a turn-in stays in front) under one frame of ours (`PolestarUIQuestiePins`) on our canvas. An icon is sized as Questie sizes it (16 x its icon scale x Questie's map icon scale, 0.9 on a continent and 0.85 on the world map; `icon.data.IconScale`, `globalScale`/`globalTownsfolkScale`), for our map's kind, not the stock map's. The glow follows Questie's rule (`alwaysGlowMap`, an objective with a colour, not a giver or a turn-in), since Questie shows it only as the icon shows on the stock map. Nothing of Questie's is moved, shown, hidden or replaced, the stock map is not touched and no pin is acquired (CLIENT.md, rules 4, 14), so it draws in combat too.

Questie's public API (`Questie.API`) has nothing for the map, so this reads private state, the one exception to "public API only": `QuestieLoader:ImportModule("HBDPins").worldmapPins` (icon -> `instanceID`, `x`, `y`, `uiMapID`, `worldMapShowFlag`), `ImportModule("HBD"):GetZoneCoordinatesFromWorldInstance`, and each icon's `texture` and `hidden` (Questie's own hide). Without them the file returns; a failure while drawing hides the mirror (`pcall`).

Extension points: `ns.modules.map.overlays`, a list of `fn(canvas)` run when the shown map, the canvas's size or its zoom changes; `ns.modules.map.PinMirror(o)` (its contract heads the function in Modules/WorldMap.lua).

Which icons show on a map follows Questie's `worldmapProvider:HandlePin`: an icon on every map its spot lies on (zone, neighbour, continent, Azeroth) by HBD's `worldMapShowFlag` (`hbd.mapData`, `GetAzerothWorldMapCoordinatesFromWorld`), none on a continent or Azeroth with Questie's "hide icons on continents" (`Questie.db.profile.hideIconsOnContinents`). Questie adds, removes, hides and fades icons at any time and tells no one, so the mirror follows by post-hooks (`hooksecurefunc`; Questie's tables and frames are an addon's, not stock, so no taint rule of CLIENT.md applies; nothing of it is replaced, moved, shown or hidden): on its HBDPins module `AddWorldMapIconMap`, `AddWorldMapIconWorld`, `RemoveWorldMapIcon`, `RemoveAllWorldMapIcons`, and once per icon its `FakeHide`, `FakeShow` (filters), `SetSize` (Questie sizes an icon after adding it), `SetFrameLevel` (its draw order) and its texture's `SetTexture` and `SetVertexColor` (a fade, a new state). Each change updates that icon alone, and only while our map shows; changes while it is closed are drawn at the next open. No timer. The icons are indexed by continent, so a map change walks its continent's icons, not the registry (Azeroth, which shows them all, walks it). The "hide icons on continents" setting resets Questie's icons (`QuestieQuest:SmoothReset`), which the hooks follow. The glow setting's handler (`QuestieFramePool:UpdateGlowConfig`) is post-hooked too: the drawn icons are painted again. A failure anywhere takes the mirror off for the session.

**Hover.** Our frame shows Questie's own tooltip: `MapIconTooltip.ShowOnTooltip(icon, tooltip, owner, icons)` into a tooltip frame of ours (`PolestarUIQuestieTooltip`, GameTooltipTemplate; never `GameTooltip`, on which Questie's call would write its keys from our code, CLIENT.md rule 15), anchored to our frame, as Questie's own gamepad hover does (`GamepadMapHover.lua`). It gets the hovered icon and the drawn icons round it by Questie's rule (the same zone, within 1, 4 on a continent, 6 on the world map, for our map's kind). On leave, or when the icon goes, the tooltip hides and `QuestieFrame.ResetHoverHighlights` gives the hovered quest's tinted icons back. Shift redraws the long form on `MODIFIER_STATE_CHANGED` (the tooltip's `_Rebuild`, as Questie's handler does for the stock map). The tooltip takes Polestar's look through `ns.modules.tooltips.Add(tip)` (Tooltips.lua: a tooltip of our own painted as the named ones). Accepted limits: Questie also lists the stock map's pins of the same zone within the stock map's radius (a few extra entries when the stock map was last on a continent), and tints the hovered quest's icons only among those it walks, not across our map.

**Clicks** (as on the stock map; our frames take the mouse, so a click on an icon does not reach the map under it): a plain left click opens the icon's own map on ours when another is shown (`canvas:SetMapID`, where Questie opens the stock map); with a modifier, the icon's own `OnClick` runs (a chat link, hide the quest, remove a manual icon, TomTom), which with a modifier down never takes its stock-map branch; a right-click goes out a map (`canvas:NavigateToParentMap`, plain code: `SetPassThroughButtons` is blocked in combat, rule 4).

**Patrol paths** (Questie's waypoint lines; it draws them on the stock map's canvas alone, `WaypointMap.lua`). Ours draws the shown map's with Questie's own renderer on our canvas (`WaypointRenderer.New(canvas)`, then `Draw`, `Restyle`, `Release`: Questie's frames, look and settings), by `WaypointMap`'s rules: a path on its own map only (`QuestieWaypoints.paths`, `path.uiMapId`), at its icon's visibility and fade (`WorldMapAlpha`), each route once (its highlighted copy, else the most visible; `IsHighlighted`), in `Color(path)` at `waypointWidth` held on screen, under the icons (level 2015). Questie says a path, its visibility or its highlight changed by calling `WaypointMap.Invalidate()`, which is post-hooked: one redraw on the next frame however many changed (a one-shot `C_Timer.After(0)`, as Questie's own draw waits for its next frame), none while our map is closed (drawn at the next open), and a route already drawn keeps its line, only its style set again. Hovering an icon highlights its paths through that same call. A failure takes the lines off for the session. Not done: a hovered path's tooltip (Questie finds the path under the cursor by reading the cursor every frame).

The mirror's machinery (the holder, the index by continent, one frame of ours per icon, the stale flag, the failure switch) is the map's `M.PinMirror` (Modules/WorldMap.lua), shared with the HereBeDragons mirror below; Questie's file keeps what is Questie's: its rules, its look, its hooks, hover, clicks and paths.

**Tests:** `tests/lua/stub_questie.lua` (errors on any write to an icon's registry row, and on a move, show, hide or script of an icon), the `worldmap-questie` scene (the tooltip in ours with its neighbours, Shift, leave, an icon removed under the mouse, each click; a path drawn once per route by Questie's renderer on our canvas, one redraw a frame, restyled on a highlight and a zoom, none while closed).

## HereBeDragons-Pins addons (`Addons/HereBeDragons.lua`; HandyNotes, TomTom, ...) — untested in game

Generic: no addon is named in the code. An addon that puts world map icons through the LibStub library "HereBeDragons-Pins-2.0" hands it frames of its own, which the library parents to pins of the stock map. Ours mirrors the library's registry (`lib.worldmapPins`, with "HereBeDragons-2.0" for the maps and coordinates) through the map's `M.PinMirror`: a frame of our own per icon of the shown map, at the icon's size and scale as a stock pin holds it, at the frame level the library asks of the map (`frameLevelType`, area POIs by default), with a copy of each texture the icon shows (file or atlas, crop, colour, alpha, layer, blend, and its anchors on the icon). Which maps an icon shows on is the library's `worldmapProvider:HandlePin` (`worldMapShowFlag`: its own map, parent zones, the continent, the world map). Nothing of the library's, the addons' or the stock map's is touched (CLIENT.md, rules 4, 14).

Change-driven: post-hooks on the library's `AddWorldMapIconMap`, `AddWorldMapIconWorld`, `RemoveWorldMapIcon` and `RemoveAllWorldMapIcons` update that icon alone (the last one the registry), only while our map shows. LibStub hands every copy of a library the same table, and a newer copy loaded later (an addon loaded on demand) writes its functions afresh, without our hooks: the file checks at login and each time our map shows or changes (never on a timer) whether its hook is still the library's function, hooks again and reads the registry again; the same check finds a library that was not there at login.

Not done, by design until an addon with such icons is at hand to check: tooltips and clicks (an icon's own `OnEnter` anchors `GameTooltip` to the icon, which is hidden off our map; ours take no mouse, so the map under them works), an icon's font strings and child frames, and art an addon changes after adding the icon (no signal: read again when the icon is added again or our map shown again).

Not installed here when written (no installed addon uses the library's world map registry), so this is covered by its stub and scene only.

**Tests:** `tests/lua/stub_hbd.lua` (the two libraries, an icon with a file texture, an atlas badge and a hidden highlight; errors on a move, show, hide or script of an icon and on a write to its registry row; `stub.hbdUpgrade()` a newer copy), the `worldmap-hbd` scene.

## Addons with their own map provider (GatherMate2, GatherPathForever, ForeverFishing)

These do not use HereBeDragons-Pins for the world map (GatherMate2 uses HereBeDragons only for coordinates): each adds a data provider of its own to `WorldMapFrame` and acquires its own pin template there (`GatherMate2/Display.lua`, `GatherPathForever/Core.lua`, `ForeverFishing/GuideMap.lua`). Our map is another canvas, so their nodes, routes and guide pins do not show on it; they show on the game's map (shift-click the quest micro button, or "Use game window"). Showing them on ours would be code per addon (a mirror of its data, or a second instance of its provider on our canvas, which shares that addon's state with the stock map and acquires its pins from our code); not done.
