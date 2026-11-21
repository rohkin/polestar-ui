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
  and the day/night ring's pieces faded with `SetAlpha`. Polestar's window border
  round the map (`H.PaintEdge`: its colour, `windowBorder`, or the accent;
  its size, the first pixel inside, the rest outward, as Theme.Border lays a window's; none with it off) and its window shadow outside it
  (`H.Shadow`, while Polestar draws one), on a frame of ours.
- **North:** while the map turns with the player, an "N" (caption, accent)
  rides the square's edge where north is, from `GetPlayerFacing` (radians,
  counter-clockwise from north), on a square 26 units inside the map's
  edge, so it never crosses a corner icon, the clock or the zone name; none
  while the game withholds the facing (instances). With the map fixed, north is up and no N is drawn.
- **Zone and clock:** on our frame on the map, in outlined HUD text
  (`H.Text`): the zone name inside the map at its foot, centred (`small`,
  `text`, between the bottom corners' icons: a long name is cut, never run
  under them), from `GetMinimapZoneText` through `ns.Clean` (secret in
  combat: the last clean name stays; re-read on the zone events and
  `PLAYER_REGEN_ENABLED`); the clock inside at its top (`number`), from
  `GameTime_GetTime(false)` each second, so the TimeManager's CVars (local or
  realm time, 24-hour) apply, shown while the game shows its clock button.
- **Screen edge:** Edit Mode clamps `MinimapCluster` to the screen by its
  box (`EditModeSystemMixin:UpdateClampOffsets`: `SetClampRectInsets` from
  the Selection's edges), which keeps the stock header strip and the ring's
  margin (empty with our square) on screen. Ours sets the insets to the
  visible map's edges inside the box instead (each edge's offset, in the
  cluster's units: left and bottom positive, right and top negative, as the
  game's), so the box may leave the screen until the map meets its edge, on
  every side. Re-set by `hooksecurefunc` on the cluster's own
  `UpdateClampOffsets` and `UpdateSystemSetting` (Size, Header Underneath
  and Rotate move the map inside the box after the game's clamp), the
  rotation CVar (next frame) and each Apply. After the game's
  `UpdateClampOffsets` its own insets are live: a rect read then would lay
  the cluster out clamped by them and pull a box placed off screen back on,
  so there the last measured insets are set again without reading (the
  stub errors on such a read). At 100% with the header above:
  39 left, 19 right, 44 top, 14 bottom. Switched off, the Selection's edges
  again (the game's formula); with another addon's shape never touched. The
  user's leave: rule 17's exception (CLIENT.md).
- **Corners:** the mail indicator top-left, the calendar top-right and the
  tracking button bottom-left as bare icons of ours, 4 units in from the
  map's corners (on our frame on the map, so they scale with Edit Mode's
  Size), each shown while the game shows its own; the addons icon takes the
  bottom-right. The clock sits between the top two and the zone name
  between the bottom two, so none overlap at any map size. The tracking
  button's `search` glyph opens the game's tracking menu (its own
  generator, `menuGenerator`, read off the stock button and opened with
  `MenuUtil.CreateContextMenu`); the calendar shows today's day (`number`,
  outlined), clicks as `GameTimeFrameMixin:OnClick` (`ToggleCalendar`, or
  `Calendar_Show` with invites waiting), counts pending invites as
  `GameTimeFrame_Refresh` does (`CALENDAR_UPDATE_PENDING_INVITES`) with an
  accent glow pulsing, and carries the stock tooltip; the mail icon (the
  game's `ui-hud-minimap-mail-icon` atlas: Polestar has no envelope glyph)
  shows with the stock `MailFrame` and its tooltip is the game's
  (`MinimapMailFrameUpdate`: the latest three senders). The stock buttons
  are not moved: they are `MinimapCluster`'s children, which
  `MinimapClusterMixin:SetHeaderUnderneath` re-anchors (rule 17), so they
  stay where the game puts them, faded, and still take clicks and show
  their tooltips there.
- **Addons flyout:** one click target for every addon: the addons icon
  (`plug` glyph, `ADDONS` tooltip) in the map's bottom-right corner, shown
  while there is anything to hold, toggles a flyout of ours
  (`PolestarUIMinimapDock`, the HUD's ground, `H.GroundAlpha`, and its edge) on the
  map, up from the icon. It is shut by default, by a second click, by
  Escape (`UISpecialFrames`) and by a click anywhere else
  (`GLOBAL_MOUSE_DOWN` off the flyout and icon). It holds the addon
  buttons only, 18-unit cells (each button scaled to fit, raised over the
  ground; scale and level given back), a column further left when the map's
  height is full; laid again on `EDIT_MODE_LAYOUTS_UPDATED` and
  `EditMode.Exit`. The addon compartment has no stand-in in it (the user
  asked: a count opening a second list of addons is one flyout too many);
  addons listed only in the compartment (`AddonCompartmentFunc`) are
  reached through the game's faded button where it sits, or their own
  commands. A collected button is parented to the
  flyout, so while it is shut the button stays out of sight even when its
  addon shows it again (LibDBIcon does on updates). Collected: LibDBIcon's
  buttons (`LibStub("LibDBIcon-1.0", true)`, `GetButtonList`, and
  `LibDBIcon_IconCreated` for the ones made later), Polestar's
  `PolestarMinimapButton`, and other addons' named buttons on `Minimap` or
  `MinimapBackdrop`: never a stock one (its global is secure:
  `issecurevariable`), nor a protected one, a map pin (a name with "Pin") or
  anything not button-sized (14 to 40). With more frames on a parent than
  `GetChildren` can return (thousands of map pins: "stack overflow"), that
  parent's scan is skipped (`minimap-pins`). A collected button cannot be dragged
  round the edge; its clicks are its addon's. The flyout follows buttons
  their addons show or hide (checked twice a second). Switched off, each one goes
  back to its parent and anchors, dragging again.
- **Header:** no ground: the calendar (`GameTimeFrame`), the addon
  compartment (`AddonCompartmentFrame`) and the tracking button keep their
  place; their state art faded (`StateTexture`, its atlas set again on each
  state change) and their additive hover emptied (`AddTexture`, whose alpha
  the game writes; given back with its atlas); the compartment's count
  (`Text`) and the mail icon (`MiniMapMailIcon`) faded, the invite flash
  (`GameTimeCalendarInvitesTexture`, `...Glow`, whose alpha the game
  writes) emptied: the corners stand in for the rest. The game's update
  path (`UpdateDisplay` writing the count and showing it,
  `OnButtonStateChanged` the state atlas and the hover's alpha) keeps
  them unseen: it never writes the faded alphas, and the hover has no
  texture. A faded button still takes the mouse where the game puts it
  (rule 17: no `Hide`, `EnableMouse` or move on a cluster child). With another
  addon owning the shape they are bare icons in place with the hover wash:
  the tracking button wears the `search` glyph, the calendar today's day,
  the compartment its count. The
  zone text button stays where it is (its click opens the map), its art and
  text (`MinimapZoneText`) faded, as is the clock's ticker
  (`TimeManagerClockTicker`): ours are on the map. With another addon owning
  the shape (no text of ours on the map) they show, in Polestar's faces at
  the game's sizes and colours. No stock header button is moved. The
  coordinate text is never read (secret in combat).
- **Menus:** the tracking and addon compartment menus (`MENU_MINIMAP_TRACKING`,
  `MENU_ADDON_COMPARTMENT`) in the chat's menu look, by tag, through the
  menu's own compositor (rule 15).
- **Not changed:** the instance difficulty banner, the
  queue status eye and the zoom buttons (icons and states, no frame art to
  fade); the stock buttons on the backdrop (`ExpansionLandingPageMinimapButton`,
  the event button).
- **Another minimap addon:** when `GetMinimapShape` was defined before our
  login (a minimap addon that shapes the map itself), that addon owns the shape:
  the mask, ring, border, N and flyout are left alone, a chat line says so, and
  only the header is restyled.
- **Switch:** `/pui minimap on|off`, live: off gives back the round mask, the
  ring, every addon button (its scale too), the header's art, zone text,
  clock and fonts at once;
  `GetMinimapShape` answers "ROUND". No window, so no "..." menu. Off by
  default with the gamepad UI.
- **Live checks (not in the preview):** the square mask on the real map
  (`WHITE8X8` as a minimap mask), the rotation callback's order, the N's side
  when turning, LibDBIcon buttons re-placing or re-scaling themselves on a
  profile change (and their MEDIUM strata over the flyout's ground), a
  click in an addon's own dropdown shutting the flyout, `GetMinimapZoneText`
  turning secret in combat, a long zone name wider than the map (
  cut between the bottom icons), the faded zone text button and clock still
  taking clicks, the corner icons at Size 50%, the map meeting each screen edge in Edit Mode at Sizes 50 to 200% with the header on either side and rotating, a saved layout partly off screen coming back where it was after /reload, the tracking and
  compartment menus opened at the cursor from ours (theirs anchor to the
  stock button), and the mail atlas's size in the corner.
