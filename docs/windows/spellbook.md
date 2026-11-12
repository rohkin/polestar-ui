#### Spellbook (`PlayerSpellsFrame`, its spellbook tab) — Risk: high
Opened by its keys (`TOGGLESPELLBOOK`; `TOGGLEPETBOOK` at Pet) and
`SpellbookMicroButton` through `ns.Doors`, never touching the stock window
(CLIENT.md, rule 8); shift-click on the micro button opens the stock one.
Spell links and new-spell toasts stay the game's. Its talents tab is the
Talents window's.
- **Shell:** 960×680 with sidebar.
- **Subject block:** the class icon (the class atlas, `GetClassAtlas`), the
  class in Title, "Level 24" in Small textDim.
- **Sidebar:** the shell's search ("Search spells", every category at once,
  titled "Search" with the count) and, at the end of its row, the filter;
  then the stock categories as nav rows: each shown skill line (General, the
  class's), then Pet when the pet has a spellbook.
- **Filter:** a 30px square on the search field's well, the `sliders` glyph,
  as Crafting's; in the accent while a setting is off its default. Its menu
  is the stock book's settings menu, on the same CVars: "Hide passives"
  (`spellBookHidePassives`) and "Show all ranks" (`ShowAllSpellRanks`; not
  for a Rogue or Warrior, as stock), then "Clear filters" (back to the
  defaults) while one is off. A search ignores them, as the stock book's
  does, so they are disabled while one runs. The menu opens again after each
  pick.
- **Main column:** title the category, subtitle the count ("12 spells.").
  What a click does is in each row's tooltip. An Options menu at the band's
  bottom right: a disabled line saying the micro button's shift-click opens
  the game's spellbook (for what other addons add to it, as What's
  Training?'s tab) and, when that addon is loaded, "What's Training?" (its
  own window).
- **Rows:** two columns, book order down the left, then the right; a 36px
  game icon on an inset well (`ns.ItemWell`), the name in Label, under it in
  Small textDim: rank, cost, cast time ("Rank 3 · 195 Mana · Instant"),
  "Passive", or for a spell not learned yet "Learn at level 26" with the name
  in textMuted and the icon desaturated. With no second line the name sits on
  the well's middle. Lower ranks and flyouts follow the stock settings
  (flyouts as their loose spells).
- **Click** casts (out of combat: a secure button over the hovered row, as the
  gear slots'); **drag** puts it on a bar; **shift-click** links it. In combat
  the rows still link, but do not drag: the client blocks a spell pickup from
  addon code then (CLIENT.md, rule 4).
- **Cooldown:** the game's sweep over the icon (`CooldownFrameTemplate`), as
  the stock book.
- **Pet autocast:** "Autocast on" or "off" first on the line, the well's
  hairline in the accent while on; right-click toggles it (the secure button
  runs the game's `/petautocasttoggle`). Pet commands (Attack, Follow) only
  drag: cast by name they would be the player's own.

