#### Micro menu (`MicroMenuContainer`, `MicroMenu`, the micro buttons) — Risk: high

The game's micro buttons, restyled in place and never rebuilt
(`Modules/MicroMenu.lua`): `MicroMenuContainer` is an Edit Mode system, so
its place, orientation, order and size, the vehicle bar's move of the menu,
and which buttons show (Forever's game rules: Housing, Adventure Guide, Help,
Shop) stay the game's (CLIENT.md, rule 17). Nothing is written on a stock
frame, no method is hooked, nothing is moved, sized, shown or hidden.
- **Covered:** Forever's buttons (`GenerateButtonInfos`, Camelot
  `MicroMenuContainerOverrides.lua`): Character, Professions, Spellbook,
  Talents, Legacy, Quest log, Housing, Guild, Group finder, Collections,
  Adventure Guide, Help, Shop, Game menu.
- **Button:** `Background` and `PushedBackground` faded with `SetAlpha` (the
  game only shows and hides them). Ours: the HUD ground (`bg` at
  `H.GroundAlpha`), Polestar's window border (`H.Edge`: its colour, `windowBorder`, or the accent; its size, the first pixel inside, the rest outward, as Theme.Border lays a window's, 2 px at most, the plate a pixel smaller per extra pixel so the gap to the next button stays; with it off only the active
  and pulsing edges show) and its window shadow (`H.Shadow`, 4 units) round the stock plate, not
  the button: the layout overlaps the 32x40 buttons (`childXPadding`/
  `childYPadding` -5, a 27 stride), so ours is inset 4 (3 at the bottom) to
  the ~24x33 plate, a 3px gap across, 2 down, in the button's units (Edit
  Mode's Size scales it). The icons
  stay the game's (decided): the game writes the normal texture's alpha on
  every hover and resets the highlight atlas in `SetPushed`/`SetNormal`, and
  the game menu button sets all four atlases each second, so a glyph would
  fight it. The Character button's round portrait and the Guild button's
  tabard stay the game's.
- **States:** hover, the `hover` wash, read from `IsMouseOver` each frame
  (the `ns.Doors` secure buttons lie over the doors' micro buttons and take
  their mouse, so the button never sees its own `OnEnter`). Its window open,
  the accent wash at 15% and an accent hairline: the game's pushed state (a
  stock window), or our window behind that door (`m.micro` and `m.psFrame`
  of a switched-on module), which the game never pushes. Disabled: the
  game's half alpha on the whole button dims ours too.
- **Alerts:** the pulse's `FlashBorder` (its alpha `UIFrameFlash`'s) emptied
  with `SetTexture(nil)`, given back with its atlas; its alpha blends our
  hairline to the accent. The notification (`NotificationOverlay`: talent
  points, new settings, community invites): its mark faded, an accent dot of
  ours made on that overlay, so it shows and hides with the game's. Every
  dot is 6px, its top right 2px inside the plate's top right corner.
- **Latency:** the game menu's `MainMenuBarPerformanceBar` faded; a dot of
  ours at the top right as the alert dot (stepping left of it while the
  game menu button has a notification too), coloured each second from `GetNetStats` in the game's own
  thresholds (over 600 ms `danger`, over 300 `warning`, else `success`). The
  latency and frame rate tooltip stays the game's.
- **Bar:** `MicroMenu.BorderArt` and `BackgroundArt` faded.
- **Doors:** untouched. The overlays (`ns.Doors`, Core.lua) are frames of
  ours on UIParent above the button; our textures are the button's own
  regions, under them. A shift-click still clicks the micro button from
  secure code for the game's window.
- **Edit Mode:** ours hangs on the buttons; on `EDIT_MODE_LAYOUTS_UPDATED`
  and `EditMode.Exit` the hairlines are one pixel again at the new size.
- **Switch:** `/pui micromenu on|off`, live (not in combat): off gives back
  every faded piece, the pulse's atlas and the latency strip at once. Off by
  default with the gamepad UI.
- **Scenes:** `micromenu`, `micromenu-doors`, `micromenu-editmode`,
  `micromenu-off`.
- **Live checks (not in the preview):** the game's "-Up" icon atlases on our
  ground (their baked shadow; the button's rect against the art), the pulse
  and notification in game, the plate inset against the real atlas size.
