#### Chat (`ChatFrame1`..`ChatFrameN`, the whisper windows) — Risk: medium

The game's own chat windows, restyled in place and never replaced: addons
write into them (`AddMessage`, message event filters, chat mods), and the
edit box runs secure slash commands and macros, so frames, text, fonts,
positions and sizes all stay the game's (`Modules/Chat.lua`). Covered: every
window in `CHAT_FRAMES` (the whisper windows as they open), its button frame,
tab, edit box, scroll bar and buttons, minimised windows, the side buttons,
the dock's overflow list, the combat log's filter strip, the chat's own
menus and chat bubbles.
- **Ground:** one Polestar window per chat window: one ground (`bg` at the
  Background opacity setting) and one 1px `border` hairline round the
  message area, the button strip on its side (left or right, as the game
  puts it; re-placed when it moves) and a 22px tab header above both, which
  a `divider` rule closes as the guide window's tab strip; with the strip on
  the right, 6px of room left of the text. All of it our textures on the
  window, anchored to the stock grounds (window and button frame), whose
  pieces are hidden and grounds emptied: no stock frame is moved or sized. The game still writes the player's
  chat opacity and the mouse-over fade into its own ground's alpha; ours
  copies that alpha each frame, so the player's opacity scales Polestar's
  ground (0 is see-through, 1 is Polestar's ground). The player's window
  colour is kept for when it is switched off.
- **Tabs:** the guide window's tabs on that header: no box, the label in
  Polestar's face (`small`'s) at the game's size (the game sizes a tab to its
  text once), `textMuted`, the selected one `text` on the selected wash over
  a 2px accent bar; the hover wash. A tab the game colours (a whisper's)
  keeps its label colour. The new-message glow and the tab's fading stay the
  game's, the glow in the accent.
- **Edit box:** the window's footer, 24px under its ground, in Polestar's
  input: the window's ground (at the window's alpha) under the `inputBg`
  well, the window's hairline carried round it, the window's bottom edge
  its divider; while typing, that divider in the accent at 50%.
- **Combat log:** its filter strip's black band faded, a divider under it.
- **Buttons:** the side buttons (chat menu, channels, voice, speech) and each
  window's minimise, resize and scroll-to-bottom buttons as Polestar's icon
  buttons: the stock plate faded, the hover wash, a Polestar glyph where one
  matches (chat menu `icon-talk`, minimise `chevron-down`, restore
  `chevron-up`, grip `resize`, scroll to bottom `chevron-down`, dock overflow
  `chevron-right`), else the stock icon (channels, the voice states, speech)
  on our ground. Pressed, the glyph nudges 1px; disabled, it dims to 35%.
  The alerts (the channel button's flash, scroll to bottom's flash, the
  overflow pulse) stay the game's.
- **Scroll bar:** its track and thumb art faded; a 2px `textMuted` thumb,
  4px `iconHover` under the cursor; the steppers as chevrons.
- **Minimised windows:** as a tab (panel ground, hairline, hover wash); the
  new-message glow stays the game's.
- **Overflow list:** its tooltip border faded under Polestar's ground and
  hairline.
- **Menus:** the tab menu, a channel name's menu and the chat menu button's
  (submenus too), by their tags (`MENU_FCF_TAB`, `MENU_CHAT_FRAME_CHANNEL`,
  `MENU_CHAT_SHORTCUTS`): the style's ground faded, Polestar's ground and
  hairline attached through the menu's compositor (`AttachTexture`), which
  frees them as the menu closes. Rows, text and highlights stay the game's;
  every other menu (they share pooled frames) stays the game's.
- **Bubbles:** outside instances, chat bubbles in the tooltip look (the
  ground a touch more see-through, the hairline), border and tail faded. In
  instances the game forbids addons to touch them: they stay the game's.
- **Not changed:** the messages' fonts and colours (the chat font size is the
  player's); timestamps and channel names (the timestamp is the player's
  `showTimestamps` format, uncoloured, and the channel prefix is built inside
  the message handler: neither can change without rewriting every addon's
  messages or the player's setting); the social (Quick Join) button (plate
  and icon are one atlas the game cross-fades); the chat's popups
  (`StaticPopup`, shared with secure dialogs) and the chat settings window
  (`ChatConfigFrame`).
- **Switch:** `/pui chat on|off`, live: off gives back every stock piece at
  once.

