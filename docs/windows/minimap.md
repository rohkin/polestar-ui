#### Minimap (`MinimapCluster`, `Minimap`) — Risk: high

The game's own minimap, restyled in place and never rebuilt
(`Modules/Minimap.lua`): `MinimapCluster` is an Edit Mode system, so its
place, size, header side and rotation stay the game's and the player's
(CLIENT.md, rule 17). Forever loads Camelot's `Minimap.lua` over the mainline
XML: the map's mask is the atlas `ui-hud-minimap-frame-generic-mask` in both
modes, set again by `MinimapClusterMixin:UpdateMinimapConfig` whenever the
`rotateMinimap` CVar changes, and `Diel.lua` adds a day/night ring
(`MinimapCluster.DielFrame`). Nothing is moved, sized, shown or hidden, and
no key is written on a stock frame; ours lives in weak tables and on frames
of ours under the `Minimap` (`Polestar.CreateFrameUnder`).
- **Square:** `Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")`, laid
  again the frame after the game's rotation callback (the CVar's callbacks run
  in no set order) and after `PLAYER_ENTERING_WORLD`; HybridMinimap's
  `CircleMask` (indoor maps, loaded on demand) gets the same texture as it
  loads. `GetMinimapShape()` answers "SQUARE", so addons that place buttons
  on the edge (LibDBIcon, Polestar's own) ride the square.
- **Ring:** the compass ring (`MinimapCompassTexture`, swapped between its
  fixed and pointer atlases by the game, which keeps the alpha), its underlay
  and the day/night ring's pieces faded with `SetAlpha`. A 1px border in the
  accent (the class colour when Polestar follows it) round the map, on a
  frame of ours.
- **North:** while the map turns with the player, an "N" (caption, accent)
  rides the square's edge where north is, from `GetPlayerFacing` (radians,
  counter-clockwise from north); none while the game withholds the facing
  (instances). With the map fixed, north is up and no N is drawn.
- **Addon dock:** the addon buttons on the minimap's edge in one row of
  ours, outside the map on the side away from the zone text (below it with
  the header on top, under the player's coordinates when the game shows them;
  above it with Edit Mode's Header Underneath, read with
  `MinimapCluster:GetSettingValueBool` and re-read on
  `EDIT_MODE_LAYOUTS_UPDATED` and `EditMode.Exit`). Collected: LibDBIcon's
  buttons (`LibStub("LibDBIcon-1.0", true)`, `GetButtonList`, and
  `LibDBIcon_IconCreated` for the ones made later), Polestar's
  `PolestarMinimapButton`, and other addons' named buttons on `Minimap` or
  `MinimapBackdrop`: never a stock one (its global is secure:
  `issecurevariable`), nor a protected one, a map pin (a name with "Pin") or
  anything not button-sized (14 to 40). A docked button cannot be dragged
  round the edge; its clicks are its addon's. The row follows buttons their
  addons show or hide (checked twice a second). Switched off, each one goes
  back to its parent and anchors, dragging again.
- **Header:** the zone text button, the calendar (`GameTimeFrame`), the addon
  compartment (`AddonCompartmentFrame`) and the tracking button on our ground
  (`bg` at the Background opacity) and 1px `border` hairline, the hover wash;
  their state art faded (`StateTexture`, its atlas set again on each state
  change) and their additive hover emptied (`AddTexture`, whose alpha the game
  writes; given back with its atlas). The tracking button wears the `search`
  glyph, the calendar today's day (`number`), the compartment its count. The
  zone text (`small`), the count and the clock's ticker
  (`TimeManagerClockTicker`, Blizzard_TimeManager loaded on demand:
  `number`) in Polestar's faces at the game's sizes; their colours (the zone's
  PvP colour) stay the game's. The zone and coordinate texts are never read
  (secret in combat).
- **Menus:** the tracking and addon compartment menus (`MENU_MINIMAP_TRACKING`,
  `MENU_ADDON_COMPARTMENT`) in the chat's menu look, by tag, through the
  menu's own compositor (rule 15).
- **Not changed:** the mail indicator, the instance difficulty banner, the
  queue status eye and the zoom buttons (icons and states, no frame art to
  fade); the stock buttons on the backdrop (`ExpansionLandingPageMinimapButton`,
  the event button).
- **Another minimap addon:** when `GetMinimapShape` was defined before our
  login (a minimap addon that shapes the map itself), that addon owns the shape:
  the mask, ring, border, N and dock are left alone, a chat line says so, and
  only the header is restyled.
- **Switch:** `/pui minimap on|off`, live: off gives back the round mask, the
  ring, every addon button and the header's art and fonts at once;
  `GetMinimapShape` answers "ROUND". No window, so no "..." menu. Off by
  default with the gamepad UI.
- **Live checks (not in the preview):** the square mask on the real map
  (`WHITE8X8` as a minimap mask), the rotation callback's order, the N's side
  when turning, LibDBIcon buttons re-placing themselves on a profile change,
  and how the dock sits under the coordinates.
