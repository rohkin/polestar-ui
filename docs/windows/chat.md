#### Chat (`ChatFrame1`..`ChatFrameN`, the whisper windows) — Risk: medium

The game's own chat windows, restyled in place and never replaced: addons
write into them (`AddMessage`, message event filters, chat mods), and the
edit box runs secure slash commands and macros, so frames, text, fonts,
positions and sizes all stay the game's (`Modules/Chat.lua`). Covered: every
window in `CHAT_FRAMES` (the whisper windows as they open), its button frame,
tab, edit box, scroll bar and buttons, minimised windows, the side buttons,
the dock's overflow list, the combat log's filter strip, the chat's own
menus and chat bubbles.
- **Calm and warm:** at rest the chat is quiet: a soft ground, a faint
  outline, no footer, the side strip's icons gone, the tabs' labels dimmed
  but legible.
  It turns warm while the game fades it in (the mouse over it, read from
  the window's `hasBeenFaded`), while the mouse is on a tab (any docked tab
  warms the docked windows), on its shown edit box or on the social button,
  or while its edit box is typed in: the full ground and its hairline, the
  side icons back. Ours eases in over 0.15 s
  (the game's fade-in) and out over 1 s.
- **Ground:** one flat Polestar surface per chat window: one ground (`bg` at
  the Background opacity setting) round the message area, the button strip
  on its side (left or right, as the game puts it; re-placed when it moves)
  and a 22px tab header above both, no divider. The header's ground and
  hairline are on `GeneralDockManager`, under the docked tabs (its
  children, LOW strata): the chat window (frame level 5) draws above the
  docked tabs, so nothing of ours on the window may reach above its ground,
  or it covers them. Undocked windows have no header (their tab, MEDIUM
  strata, sits above them); with the strip on the right,
  6px of room left of the text. At rest the ground is 35% of Polestar's
  (`REST`), warm all of it; its 1px `border` hairline likewise (35% at rest,
  so the panel keeps its outline over the world, as the damage meter). The
  player's chat opacity no longer scales it. All of it our textures on the
  window, anchored to the stock grounds (window and button frame), whose
  pieces are hidden and grounds emptied: no stock frame is moved or sized.
  The game still writes the player's opacity and fades into its own
  (emptied) ground; the player's window colour is kept for when it is
  switched off.
- **Tabs:** plain text on that header: no box, no ground, the label in
  Polestar's face (`small`'s) at the game's size (the game sizes a tab to its
  text once), `textMuted`, the selected one `text` over a 2px accent
  underline as wide as its label's text. A docked tab that is not static (a
  window the player made, a whisper's) lies in the dock's scroll frame
  (`FCFDock_UpdateTabs`), a few px above the dock's foot, stretched to 90
  (`FCFDock_CalculateTabSize`) with its label centred: so every label is
  left-justified in its text box (which starts at the tab's side padding on
  every tab) and the label, wash and underline are moved by the tab's foot
  to the dock's (measured by our driver; the tab itself is the dock's and
  never moved). Switched off, the label's own anchor and justification are
  back. Label and underline are out of the tab's
  fade (`SetIgnoreParentAlpha`; the game's 0.2 left a label unreadable over
  the world): ours fades them, 0.85 selected and 0.7 the others at rest
  (`TAB_REST`), full with the window's warmth (the header's, docked) or
  hovered, times the alpha above the tab (its parent's). A hovered tab: its
  label `text` on the hover wash, which lies under the label (BACKGROUND, shown by our driver); in the
  HIGHLIGHT layer it drew over the label and washed it out. Which
  tab is selected is the dock's answer (undocked, or
  `FCFDock_GetSelectedWindow`), never the stock Active art, which shows on
  the combat log's tab until the dock first colours it. A tab the game
  colours (a whisper's) keeps its label colour; its conversation icon is
  desaturated and drawn in Polestar's `icon` colour. The tabs' own fade (0.4
  selected, 0.2 others at rest; 1 and 0.6 on mouse-over; it still fades the
  icon, hover wash and the alerting tab) and the new-message glow stay the
  game's, the glow in the accent.
- **Edit box:** only while typing, the window's footer, 24px under its
  ground, in Polestar's input as a focused `ns.TextField`: the window's
  ground under the `inputBg` well, a 1px accent ring at 0.8. Not typing
  there is no footer, whether the game hides the box (classic chat style) or
  leaves it shown at 0.35 (IM style, the default). Its letter limit stays
  the game's (`visibleBytes` 255); nothing of ours sets one.
- **Combat log:** its filter strip's black band faded, a divider under it.
- **Buttons:** the side buttons (chat menu, channels, voice, speech) and each
  window's minimise, resize and scroll-to-bottom buttons as Polestar's icon
  buttons: the stock plate faded, the hover wash, a Polestar glyph where one
  matches (chat menu `icon-talk`, minimise `chevron-down`, restore
  `chevron-up`, grip `resize`, scroll to bottom `chevron-down`, dock overflow
  `chevron-right`), else the stock icon (channels, the voice states, speech)
  desaturated and drawn in Polestar's `icon` colour. The side strip's icons
  show only while a shown window is warm. Pressed, the glyph nudges 1px;
  disabled, it dims to 35%. The alerts (the channel button's flash, scroll
  to bottom's flash, the overflow pulse) stay the game's.
- **Social button:** the Quick Join button (`QuickJoinToastButton`) shown at
  the foot of the side strip, just above the chat menu button (2px apart, a
  voice button's 27x26, a 15px friend icon `groupfinder-icon-friend` flat in
  `icon`, the online count copied from the stock count in `textMuted`,
  none at 0), with the strip. Anchored on the menu button, which the game
  keeps at the strip's bottom, it stays inside the strip whether the voice
  buttons show or not; in a voice channel on a window at its minimum height
  (120) the strip is too short for all five and it meets the mute button.
  The stock button cannot move (ChatAlertFrame places it as an alert
  subsystem), so ours is a copy: an icon frame on the strip and a secure
  button of ours over it, placed out of combat by position (rule 10). A
  click opens Polestar's Social window while that module is on (PostClick,
  as our doors), shift-click the stock button; with the module off, or while
  a Quick Join toast shows (its click opens that group), a click is the stock
  button's own (`type1` `click`, its OnClick untainted). The route is set
  out of combat. Its tooltip is the stock one's (Social and its key, the
  shift-click hint on ours, or the disabled reason). The stock button's
  icon, count and highlight are faded; its toasts and queue icon (alpha the
  game animates) and its click area at its old place stay.
- **Copy:** a copy button (Polestar's `compact` glyph, a voice button's
  size, 2px apart) in the side strip just above the social button, faded
  with the strip, and "Copy chat text" at the foot of a tab's right-click
  menu (`MENU_FCF_TAB`, `Menu.ModifyMenu`), open Polestar's copy window
  (`PolestarUIChatCopy`, 560x440, the window skin, movable, Escape closes):
  the strip's button copies the selected docked window, the tab menu that
  tab's window. Every line the window holds (the game keeps 128), oldest
  first, as plain text: colour codes, textures and Battle.net tokens
  stripped, a link its visible text (an item stays `[Name]`). A read-only
  copy box (Polestar's `W.CopyBox`) in a scrolled well, scrolled to the
  newest, all of it selected and focused as it opens, so Ctrl+C copies it;
  a click or drag selects a part (one line). A line the game keeps secret
  (in combat, in instances; rule 3) cannot be read: it shows as "(hidden:
  the game keeps this line secret)" and the hint above says how many.
- **History:** at logout and `/reload` (`PLAYER_LOGOUT`) each permanent
  window's lines (`ChatFrame1`..`NUM_CHAT_WINDOWS`, by index; not the
  combat log, `ChatFrame2`; not the whisper windows, whose index changes)
  are saved per character in `PolestarUICharDB.chat` (`{ at = time,
  [index] = { { text, r, g, b }, ... } }`), at most 500 a window (the game
  keeps 128; a mod that raises it is cut to the newest 500, some 75 KB a
  window). At login they are put back above the new session's lines, their
  colour faded toward grey (`c * 0.6 + 0.2`), under a divider "- previous
  session, 14 Nov 22:13 -" in `textMuted`. Saved again at the next logout,
  a put-back line is stored once at its own colour and the divider is left
  out, so the history rolls on without doubles. Secret lines are never
  stored. A Battle.net name is a token good for one session: its link is
  made plain text and the name "Battle.net friend". The switch "Keep chat
  across sessions" in the copy window turns it off
  (`PolestarUICharDB.chatNoHistory`: nothing is saved, the history is
  forgotten at logout); "Clear history" forgets it now and takes the put-back
  lines out of the windows. Whispers are kept too, only on this computer, in
  the addon's saved variables beside the game's own (`WTF`).
- **How (rules 15 and 17):** neither writes into a chat window's code: no
  hook on `AddMessage` (`ChatFrame1` is an Edit Mode system, rule 17, and a
  `hooksecurefunc` on a frame's method writes a key on it, rule 15), no
  message filter. Lines are read from the window's own buffer
  (`GetNumMessages`, `GetMessageInfo`), so every addon's filters and hooks
  have had their say and there is nothing to keep in step; they are put back
  with the window's own `BackFillMessage` (the call addons write chat with,
  as `AddMessage`) with a mark of ours in the line's extra data (after the
  game's id, access id and line id, which stay nil), and cleared with its
  `RemoveMessagesByPredicate`. Lines lost to a crash or disconnect (no
  logout) are not saved: the game writes saved variables only then.
- **Clipping:** the message frame clips a line that sticks out at its top or
  bottom (a large chat font): half a line under the tabs, a cut descender at
  the foot. That is the game's frame, not ours, and stays: the lines are laid
  from the bottom and clipped by the frame's own `FontStringContainer`
  (`ScrollingMessageFrame.lua`), and the header's ground lies under the
  window, so nothing of ours can cover the cut line without moving or
  sizing the window (an Edit Mode system, rule 17), and a cover of ours
  over the text would darken a band of the translucent ground.
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
- **Not changed:** the messages' font, size and colours (the chat font size is
  the player's; Polestar's face on the lines read poorly in game); timestamps and channel names (the timestamp is the player's
  `showTimestamps` format, uncoloured, and the channel prefix is built inside
  the message handler: neither can change without rewriting every addon's
  messages or the player's setting); the social (Quick Join) button (plate
  and icon are one atlas the game cross-fades); the chat's popups
  (`StaticPopup`, shared with secure dialogs) and the chat settings window
  (`ChatConfigFrame`).
- **Switch:** `/pui chat on|off`, live: off gives back every stock piece at
  once (the tabs' own fade too),
  hides the copy button and its menu item, and leaves the saved history
  as it is (neither saved nor put back while off).

