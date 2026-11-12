#### Spellbook (`PlayerSpellsFrame`, its spellbook tab) — Risk: high
Opened by its keys (`TOGGLESPELLBOOK`; `TOGGLEPETBOOK` at Pet) and
`SpellbookMicroButton` through `ns.Doors`, never touching the stock window
(CLIENT.md, rule 8); shift-click on the micro button opens the stock one.
Spell links and new-spell toasts stay the game's. Its talents tab is the
Talents window's.
- **Shell:** 960×680 with sidebar.
- **Subject block:** the class icon, the class in Title, "Level 24" in Small
  textDim.
- **Sidebar:** the shell's search ("Search spells", every category at once,
  titled "Search" with the count), then the stock categories as nav rows:
  each shown skill line (General, the class's), then Pet when the pet has a
  spellbook.
- **Main column:** title the category, subtitle what the player can do ("Click
  a spell to cast it, or drag it to your action bars."). An Options menu at the
  band's bottom right: the stock book's settings (Show passive spells, Show all
  ranks; the same CVars), a disabled line saying the micro button's
  shift-click opens the game's spellbook (for what other addons add to it, as
  What's Training?'s tab) and, when that addon
  is loaded, "What's Training?" (its own window).
- **Rows:** two columns, book order down the left, then the right; a 36px
  game icon on an inset well with a hairline, the name in Label, under it in
  Small textDim: rank, cost, cast time ("Rank 3 · 195 Mana · Instant"),
  "Passive", or for a spell not learned yet "Learn at level 26" with the name
  in textMuted and the icon desaturated. Lower ranks and flyouts follow the
  stock settings (flyouts as their loose spells).
- **Click** casts (out of combat: a secure button over the hovered row, as the
  gear slots'); **drag** puts it on a bar; **shift-click** links it. In combat
  the rows still drag and link.
- **Cooldown:** the game's sweep over the icon (`CooldownFrameTemplate`), as
  the stock book.
- **Pet autocast:** "Autocast on" or "off" first on the line, the well's
  hairline in the accent while on; right-click toggles it (the secure button
  runs the game's `/petautocasttoggle`). Pet commands (Attack, Follow) only
  drag: cast by name they would be the player's own.

