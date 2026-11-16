#### World Map and Quest Log (`WorldMapFrame`, `QuestMapFrame`) — Risk: medium
Forever loads the mainline map: the quest log is a panel inside
`WorldMapFrame`, and other addons (Polestar's own map features, Mob Markers,
OpenMap) draw on that frame's canvas by its global name. Pointing the global
at ours would taint every Blizzard reader of it (`UpdateMicroButtons`, the
action bars' spell flyout), so the stock map is never touched: it stays the
map those addons draw on, and its hide runs `UpdateMicroButtons` (CLIENT.md,
rule 8). Ours is a second map, built as the game builds its zone map
(`BattlefieldMapFrame`): the game's `MapCanvasFrameTemplate` with the stock
map's data providers and pin layers, so its art, fog, pins, player arrow,
zoom and click-to-open are the game's.
- **Shell:** the compact grid (`ns.Compact`, no sidebar): a 60 band, the
  36 tab row (the skin's when smaller), no footer, and a canvas of 900×600
  (the map art's shape) under the tab row: 902×698 windowed, 1222 wide with
  the side column (was 1094×682 with a 240 sidebar and an 852×568 map).
- **Band:** "World Map"; the one-line subtitle names the shown map and the
  map it lies in ("Elwynn Forest · Eastern Kingdoms"; a map with no parent,
  its name alone).
- **Tab row:** the side column's pages as top tabs (`ns.TopNav`; the stock
  quest panel's Quests and Map Legend tabs): Quests with the log's count
  over the most it holds ("5/25", danger past it), Map Legend where the
  client has its data (`MapLegendData`). A tab opens the column on its page;
  the shown page's tab shuts it (its tooltip says so), and no tab is lit while
  it is shut. After the tabs, the map's nav (the old sidebar, as the stock
  nav bar): a flag button, "Where you are" (its tooltip names the player's
  zone), back to the player's map; then the shown map's name with a chevron,
  opening the game's menu (scrolling where the client can): the maps above
  it (to go back out), its zones (continents and zones only, by name), the
  dungeons and caves in it that the stock nav bar's dropdown lists
  (`IsMapValidForNavBarDropdown`; a map of floors once, by its first) and,
  on a map of several floors (a map group), its floors in the client's
  order, the shown one checked; dividers between them. How to move around
  the map (click a zone, right-click out, scroll to zoom) is its tooltip
  hint. At the row's right end the filter (always, so the filters work with
  the log shut); while the quest list shows, it opens our dropdown
  (`ns.SearchInFilter`): the quest search on top, then "Map filters…", which
  opens the game's menu; else the game's menu at once.
- **Map controls:** as the stock map's overlay frames, at the canvas's top
  right (above the pins): the full-screen toggle (the stock maximise,
  remembered; out of the dock while full), and under it, unless a game rule
  turns it off, the map pin
  (`qol-target`; the stock pin button: while on, a click on the map sets the
  player's waypoint through the stock waypoint provider,
  `WaypointLocationToggleUpdate`; off again once a waypoint is set, on a new
  map, or as the window hides; disabled where the map takes no waypoint,
  its tooltip the stock lines).
- **Coordinates:** at the canvas's bottom left, on an editbox ground, as
  the stock coordinates panel: the player's ("Player: 41, 65"; off this map,
  their own map's, named after them) and the cursor's while over the map,
  each as its CVar says (`worldMapShowPlayerCoords`,
  `worldMapShowCursorCoords`; shown where the client lacks it), in tenths
  with `coordsByTenths`; read ten times a second while the map shows.
- **Zoom:** the canvas takes its zoom steps from the map art; where the art
  gives one (Forever's), ours adds 1.5×, 2.25× and 3×. Drag pans once zoomed.
- **Side column:** 320 wide right of the canvas, under the tab row, on the
  sidebar ground, its page remembered (Quests, Map Legend or shut).
  Windowed, the window grows by its width; full screen, the map gives it room.
- **Quest Log:** the column's Quests page, the list from its top (its count
  and filter are on the tab row, the search in the filter's dropdown). The log as the stock panel lists it: header rows (label
  face, chevron, count) fold through the client and redraw at once
  (CLIENT.md, rule 6); hidden quests, tasks and unfinished bounties stay
  out; a campaign's header always shows (unless searching). A quest row: "[level]
  title" (with "[n]" before the title for party members on it, as the
  stock title) in Body in its difficulty colour
  (legible), what is left under it in Small textDim (the unfinished
  objectives and the money it takes the player lacks, "have / need", or the
  hand-in line once done), and two fixed slots at the
  right of the title: tracked at the end (the stock checkbox's
  `questlog-icon-checkmark-yellow`), and left of it a check (success) when
  done, a cross (danger) when failed, else the quest's stock tag
  (`QuestUtils_GetQuestTagAtlas`, account-wide first). Hover lights its area on the map (the
  canvas's `SetHighlightedQuestID`); a click shows its map with its area in
  focus, selects it and opens its details; shift-click tracks it (the stock
  toggle); with a chat box open, a click links it. Right-click opens the
  stock title menu (the game's Menu, `MENU_QUEST_MAP_LOG_TITLE`, so other
  addons' entries join it): Track/Untrack, Focus (the client's super-track,
  `C_SuperTrack`), Share (greyed unless pushable in a group) and Abandon
  (our confirm). A header's right-click: Track all and Untrack all
  (`MENU_QUEST_MAP_FRAME`). The focused quest carries the accent bar, the
  clicked one the selected wash. The row's tooltip is the stock one: the
  title, on hold or failed, the hand-in line or the objectives summary and
  every objective (finished ones grey), then the hint. The search
  ("Search quests", in the filter's dropdown) matches a quest's title or what is left of it;
  searching, every match shows with its header open. The filter, as
  Social's (`sliders`, editbox ground; its glyph in the accent while a
  filter is off its default or a search runs, its tooltip "Search and filter
  (n on)" with the list shown)
  opens the stock map's filter menu as Forever builds it (the game's Menu,
  its `MENU_WORLD_MAP_TRACKING` tag, so other addons' entries join it, each
  filter with the stock tooltip): the world quest submenu where the map has
  world quests, quest objectives on the map (`questPOI`), quest levels
  (`showQuestLevel`), difficulty colour (`showQuestDifficultyColor`),
  low-level quests (the trivial quests tracking filter) and tracked items
  (`contentTrackingFilter`), then the log's objectives
  (`showQuestObjectivesInLog`), and "Clear filters" (every one back to its
  default, as the stock reset) while any is off. The row's level, colour and
  "what is left" line follow them; each change redraws the map and the list
  at once, and a change from the stock menus on `CVAR_UPDATE`.
- **Map Legend:** the column's other page, as the stock `MapLegendFrame`:
  each `MapLegendData` category (label, textDim) and its pin kinds from
  `MapLegendPinDefinitions` two to a row (the stock atlas, on its background
  atlas where it has one, and the name in Small); a kind the client lacks is
  left out. Hover: the stock tooltip (name, then its line) and its pins on
  our map glow (`EnumeratePinsByTemplate`, matched by the stock
  `MapLegendButtonMixin.MetaDataMatches`, `ShowMapLegendGlow`), off on leave.
  A pin hovered on the map does not light its legend row (the stock
  `MapLegendPinOnEnter` callback is not taken: our code would run inside the
  pin's own OnEnter).
- **Quest details:** in the list's place (the search hidden while they show), as the stock details page
  (`QuestMapFrame_ShowQuestDetails`, QuestInfo's map templates; the quest
  selected through `C_QuestLog.SetSelectedQuest`, as the stock reads it).
  Its head: a chevron and "All quests" (label textDim), back to the list
  with its scroll and search. Scrolling: the title as on the row, in Heading;
  the objectives summary in Body; every objective in Body, textDim, a
  finished one textMuted with a check (success) before it; required money
  and group size when there are any; "Description" (Heading) and the quest
  text; "Rewards" (Heading) in the stock order and with the stock lines
  (label textDim): the choices, the spells (by kind), a title, then
  experience and money as facts (the value in Number at the right;
  experience reads "450 XP" and adds its share of the player's level under it,
  right-aligned in small textMuted, "35% of level 24", unless the game shows no XP bar), a
  skill, items, currencies and honor. A reward is a Reagent Tile at the
  column's width, with the stock reward's tooltip
  (`GameTooltip:SetQuestLogItem`, `SetQuestLogCurrency`, `SetSpellByID`)
  and its modified click; one the player cannot use has a red icon. A
  footer at the bottom: Abandon (danger) at the left, Share (only when the
  stock button is enabled: pushable, in a group) and Track/Untrack at the
  right. Track (greyed when the most quests are tracked, or the quest is on
  hold) and Abandon (greyed when the client refuses it) fade as Polestar
  disables (`ns.SetEnabled`), their tooltip saying why. Track and Share are
  the stock helpers; Abandon runs the stock
  steps (`SetSelectedQuest`, `SetAbandonQuest`, then `AbandonQuest` on
  accept), confirmed by `W.Modal` in danger naming any items lost with it,
  never the stock popup. Redrawn on `QUEST_LOG_UPDATE` (and as a reward's
  item loads); back to the list when the quest leaves the log.
- **Doors:** `TOGGLEWORLDMAP` toggles ours; `TOGGLEQUESTLOG` and
  `QuestLogMicroButton` open it with the quest log, or close it when the
  log shows, as the stock toggle (`ns.Doors`; shift-click on the micro
  button: the stock map). Every other door stays the game's and opens the
  stock map (CLIENT.md, rule 14): the objective tracker's quest clicks and
  "Show on map", world quest and bonus objective clicks, map, event and
  world quest links, `/mappin`, the minimap's zone text, NPC map
  interactions (`WORLD_MAP_OPEN`) and the spirit healer.

