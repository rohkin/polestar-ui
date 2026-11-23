#### Action bars (`MainActionBar`, `MultiBar*`, pet, stance, possess) — Risk: high

The game's own action buttons, restyled in place and never rebuilt
(`Modules/ActionBars.lua`): every bar is an Edit Mode system and every button
a secure action button, so the bars' places, sizes, rows, icon size, padding,
visibility, paging and Hide Bar Art stay the game's and the player's
(CLIENT.md, rule 17), and keybinds, macros, drag and drop and Quick Keybind
mode are untouched. Only each button's art changes; no key is written on a
stock frame and nothing is moved, sized, shown or hidden.
- **Covered:** the buttons by the names the game gives them
  (`ActionBarMixin:ActionBar_OnLoad`): `ActionButton1-12`, the
  `MultiBarBottomLeft`, `BottomRight`, `Left`, `Right`, `5`, `6`, `7` bars'
  `...Button1-12`, `PetActionButton1-10`, `StanceButton1-10`,
  `PossessButton1-2`, the totem bar's `MultiCastActionButton1-12` and its
  summon and recall buttons (Forever loads `MultiCastActionBarFrame`), the
  vehicle bar's `OverrideActionBarButton1-6` (Blizzard_OverrideActionBar,
  loaded on demand), the spell flyout's `SpellFlyoutPopupButton`s and the
  zone ability's buttons (both made when first needed).
- **Button:** ActionButtonTemplate's `SlotArt`, `SlotBackground`, frame
  (`NormalTexture`), `PushedTexture` and `HighlightTexture` faded with
  `SetAlpha` (the game swaps the frame's and pushed atlases with Hide Bar Art,
  which keeps the alpha); the `CheckedTexture` emptied (the game writes its
  alpha for auto-attack), given back with its atlas. The icon unmasked
  (`RemoveMaskTexture(IconMask)`) and cropped 8% each side, as `ns.GameIcon`
  crops the client's border. Ours: the HUD ground (`bg` at `H.GroundAlpha`)
  under the icon, so an empty slot shown in the grid is a well; Polestar's window border (`H.Edge`: its colour, `windowBorder`, or the accent; its size, the first pixel inside, the rest outward, as Theme.Border lays a window's,
  2 px at most; none with it off, a checked edge still shows) round the
  button; Polestar's window shadow outside it (`H.Shadow`, 6 units); the hover wash.
- **Empty slots:** the game hides an empty slot's icon (`ActionButton.lua`
  `Update`, `PetActionBar.lua`), so a slot whose icon is hidden shows Polestar's emblem (`Media/UI/emblem`,
  white, tinted) of ours centred at 60% of the button (its ink about 45%), in
  the lighter accent (the accent half way to white: Polestar 0.4.0 has no
  lighter accent token; its own bright star `emblem-hot` is a fixed gold) at
  5%. The per-frame driver compares the icon's shown state and repaints on a
  change (a drop, a page or form swap), in combat too: only our texture's
  shown state and colour. Hiding empty slots is the game's own Edit Mode
  setting, per bar, **Always Show Buttons** (unticked: `ActionBarMixin:
  UpdateShownButtons` hides a button with no action unless its `showgrid`
  attribute is set, which `ACTIONBAR_SHOWGRID` does while an action is
  dragged); ours hangs on the button, so it hides and shows with it. No
  option of ours duplicates it: faded art over a secure button left shown
  would still take clicks and keep its space.
- **States:** pressed (a click or its key: the button's state is `PUSHED`)
  the accent wash at 30%; checked (a stance, auto-attack, a spell waiting for
  its target) the accent wash at 15% and the hairline in the accent. No event
  says a key pressed a button, so a frame of ours reads `GetButtonState` and
  `GetChecked` of each shown button each frame and repaints on a change.
- **Type:** the key (`HotKey`) and count (`Count`) in Polestar's `number`
  face with `OUTLINE`, the macro name (`Name`) in `small`'s with the
  game's flags, at the game's sizes and colours (the key's grey, red out of
  range). The range dot the game writes in the key for an unbound action
  (`RANGE_INDICATOR`, "●", "•" in some locales) stays in the game's face:
  Fira Sans and Open Sans have no glyph for it (it drew as a box). A frame of
  ours compares the key's text with it each frame, as the game does, and
  swaps the face when it turns. The count is never read
  (secret in combat).
- **Not changed:** the equipped item's green `Border` (its alpha is the
  game's: it writes it with the colour), the attack `Flash`, spell alerts and
  the proc glow, `NewActionTexture`, cooldowns and loss of control, the
  autocast ring, the flyout arrow, and the bars' own art (the main bar's end
  caps and dividers: Edit Mode's Hide Bar Art). The vehicle leave button
  (its art is its icon), the extra action button and the zone ability's
  frame art.
- **Edit Mode:** ours hangs on the buttons, so moving, scaling (Icon Size)
  and re-rowing follow by themselves; on `EDIT_MODE_LAYOUTS_UPDATED` and
  `EditMode.Exit` the buttons are repainted so the hairlines are one pixel at
  the new scale.
- **Combat:** repainting the look (a theme change) writes only colours and
  alphas on textures; a button the game makes mid-fight (a flyout first
  opened in combat) keeps the game's look until `PLAYER_REGEN_ENABLED`.
- **Shared look:** `ns.ButtonLook` (`paint(b, shown, lit?, isEmpty?)`: `isEmpty(b)` replaces the hidden-icon test and fades the icon while empty, `tick(b)`)
  hands this look to the bag bar ([bagbar.md](bagbar.md)), which has its own
  switch and driver, so it works with this module off. The micro menu has its
  own look ([micromenu.md](micromenu.md)).
- **Switch:** `/pui actionbars on|off`, live (not in combat): off gives back
  every faded piece, the masks, the checked glow and the fonts at once. No
  window, so no "..." menu. Off by default with the gamepad UI.
- **Live checks (not in the preview):** that `RemoveMaskTexture` and the
  crop hold through the game's own icon updates (a spell swapped by a talent,
  a macro's icon), the checked glow emptied with auto-attack on, the pressed
  wash with "cast on key down", and the bars at every Edit Mode icon size.
