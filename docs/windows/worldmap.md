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
- **Shell:** the sidebar's width plus a canvas of 852×568 (the map art's
  shape) under the band; no tabs, no footer. Subject block: the map icon,
  "World Map", the player's zone.
- **Sidebar:** "Where you are", then the maps above the shown one (to go
  back out), then its zones (continents and zones only, by name). A map of several floors (a map group) ends with a
  section of them, in the client's order, the shown floor selected.
  Between the zones and the floors, the dungeons and caves in it that the
  stock nav bar's dropdown lists (`IsMapValidForNavBarDropdown`; a map of
  floors once, by its first), with `icon-dungeon`.
- **Header:** the shown map's name; the subtitle, a status line, names the
  map it lies in. How to move around the map (click a zone, right-click out,
  scroll to zoom) is the sidebar rows' tooltip hint.
  A full-screen toggle at the band's bottom right, as the stock maximise
  (remembered; out of the dock while full).
- **Map controls:** as the stock map's overlay frames, at the canvas's top
  right (above the pins, unless a game rule turns them off): the filter
  button (the quest log's menu and state, lit and counted as the log's, so
  the filters work with the log shut), and under it the map pin
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
- **Quest Log:** a 320 flyout right of the canvas, under the band, on the
  sidebar ground, opened by a "Quests" button left of the full-screen
  toggle (remembered). Windowed, the window grows by its width; full screen,
  the map gives it room. Its head: "Quests" and the log's count over the
  most it holds. The log as the stock panel lists it: header rows (label
  face, chevron, count) fold through the client and redraw at once
  (CLIENT.md, rule 6); hidden quests, tasks and unfinished bounties stay
  out. A quest row: "[level] title" in Body in its difficulty colour
  (legible), what is left under it in Small textDim (the unfinished
  objectives, or the hand-in line once done), and two fixed slots at the
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
  every objective (finished ones grey), then the hint. A search under the head
  (the sidebar's search box) matches a quest's title or what is left of it;
  searching, every match shows with its header open. At its right end, as
  Social's, a filter button (`sliders`, editbox ground; its glyph in the
  accent and its tooltip "Filter (n on)" while a filter is off its default)
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
- **Quest details:** in the flyout's place, as the stock details page
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
  flyout's width, with the stock reward's tooltip
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

