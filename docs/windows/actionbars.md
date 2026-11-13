#### Action bars (`MainActionBar`, `MultiBar*`, pet, stance, possess) — Risk: high

The game's own action buttons, restyled in place and never rebuilt
(`Modules/ActionBars.lua`): every bar is an Edit Mode system and every button
a secure action button, so the bars' places, sizes, rows, icon size, padding,
visibility, paging and Hide Bar Art stay the game's and the player's
(CLIENT.md, rule 16), and keybinds, macros, drag and drop and Quick Keybind
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
  crops the client's border. Ours: the window ground (`bg` at the Background
  opacity) under the icon, so an empty slot shown in the grid is a well; a 1px
  `border` hairline round the button; the hover wash.
- **States:** pressed (a click or its key: the button's state is `PUSHED`)
  the accent wash at 30%; checked (a stance, auto-attack, a spell waiting for
  its target) the accent wash at 15% and the hairline in the accent. No event
  says a key pressed a button, so a frame of ours reads `GetButtonState` and
  `GetChecked` of each shown button each frame and repaints on a change.
- **Type:** the key (`HotKey`) and count (`Count`) in Polestar's `number`
  face, the macro name (`Name`) in `small`'s, at the game's sizes, outlines
  and colours (the key's grey, red out of range). The count is never read
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
- **Later:** the micro menu (`MicroMenuContainer`: its buttons' art is their
  icons, and our `ns.Doors` overlays sit over them) and the bag bar
  (`BagsBar`, item buttons) are not restyled yet.
- **Switch:** `/pui actionbars on|off`, live (not in combat): off gives back
  every faded piece, the masks, the checked glow and the fonts at once. No
  window, so no "..." menu. Off by default with the gamepad UI.
- **Live checks (not in the preview):** that `RemoveMaskTexture` and the
  crop hold through the game's own icon updates (a spell swapped by a talent,
  a macro's icon), the checked glow emptied with auto-attack on, the pressed
  wash with "cast on key down", and the bars at every Edit Mode icon size.
