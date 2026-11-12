#### Character (`CharacterFrame`) — Risk: medium
Opened by `TOGGLECHARACTER0/2/4`, `TOGGLECURRENCY` and the micro button; all
call `ToggleCharacter(subFrame)` or `CharacterFrame:ToggleTokenFrame()`.
- **Shell:** 960×680 with sidebar (240).
- **Subject block:** the class icon (36px, the game's class atlas,
  `GetClassAtlas`, on an inset well, hairline), the first name in Title (no surname: the sidebar has no room), "Level 24 Warrior" in Small textDim; the
  guild under it in Small textMuted (none without one); each to the 24 edge,
  ending in an ellipsis past it. Name and guild are read
  out of combat (CLIENT.md, rule 3).
- **Sidebar sections** (stock subframes, in stock order): Character
  (`PaperDollFrame`), Reputation, Currency (always: the stock `ShouldShowCurrencyTab` returns true; only
  the `TOGGLECURRENCY` key does nothing with an empty list, as
  `ToggleTokenFrame` does), Honor (`PVPRankFrame`), Skills, Statistics.
- **Band:** the section's name as title; a status subtitle (Character: "2
  items need repair" or "Gear in good repair"; Reputation: "Watching
  Stormwind" or the faction count; Currency, Skills, Statistics: their
  counts; Honor: the season); Options on the Character page ("Show stats",
  checked while the drawer shows).
- **Character page** — no tabs: the gear, with the stats in a drawer at the window's right.
  Item level is not shown anywhere: it means nothing in Forever.
  - *Gear*: two slot columns on the 32 and right edges (Head, Neck, Shoulder,
    Back, Chest, Shirt, Tabard, Wrist; Hands, Waist, Legs, Feet, Finger ×2,
    Trinket ×2), then, 16px down, the weapons in a row centred under the model
    well (Main Hand, Off Hand, Ranged), as the stock sheet and the armory lay
    them out. Ammo is a 16px tile in the Ranged slot's bottom-right corner,
    shown only when the ranged weapon is a bow, gun or crossbow. Slot tiles
    36px item wells (`ns.ItemWell`), 6px apart. Beside each column's slot, on the inside (over the model
    well): the item's name in Label in its quality colour, 220px wide, and
    under it a permanent enchant (its tooltip line, "Enchanted: " dropped) in
    Small success; the lines centred on the slot (no item stats: those are the
    drawer's). The weapons' text sits on the row's outer sides, Main Hand's
    left and Ranged's right, and Off Hand's centred under its slot; empty, the
    slot's name in textMuted. Painted out of combat only.
  - *Stats drawer*: 280px wide, its own window skin, docked flush to the
    window's right edge and as tall (the shell stays 960 wide; open, the two
    read as one 1240px window, as in the armory). Options' "Show stats" puts
    it away and back, for every character (`PolestarUIDB.hideStats`). In it:
    "Stats" in Heading, centred 36px down, then one scrolling column from
    72px: a Heading per stock category (`PAPERDOLL_STATCATEGORIES`) over a
    panel of 28px stat rows, 24px in, every row alike (no highlights). A
    chevron in the gutter beside each heading folds it; the folds are kept for
    every character (`PolestarUIDB.statsFolded`, by category name). Numbers,
    the stats a character shows and their tooltips are the stock sheet's own:
    each row is filled by `PAPERDOLL_STATINFO[stat].updateFunc`, so the
    client's colours for buffed and debuffed values stay.
The other sections share one grouped list: the client's top headers as
Headings with their hairline, a chevron in the gutter that folds them (the
client's own collapse state), over a row panel. They are painted out of combat
only and read in the background like the stats (CLIENT.md, rule 3).
- **Reputation:** faction rows 40px: the name in Body text, the standing in
  Small in its standing colour (legible form) at the right, a 2px standing bar
  (track wash, fill in the standing colour) under them. A sub-header is a row
  in textDim with its own chevron, its factions indented 18px. A click watches
  a faction (or stops watching it); the watched one carries the 2px accent bar.
  The tooltip is the faction's description and its points in this standing.
- **Currency:** 28px rows: the icon in an 18px item well at 15, the name in Label, the amount
  (and its cap) in Number at the right; the game's currency tooltip.
- **Honor:** Forever's PvP rank (the major faction 2800, as the stock page
  reads it): the title and rank in Display, the season in Small textDim, the
  points to the next rank in Number over a 3px accent progress line.
- **Skills:** the stock page's lines (no class skills, no sub-lines): 40px
  rows, the name in Body, "rank/max" (and the modifier, "(+5)") in Small textDim
  at the right, the 2px accent skill bar under them.
- **Statistics:** the client's statistic categories as the stock page reads
  them, a group per top category; a sub-category is a row in textDim with its
  own chevron, its statistics indented 18px. 28px rows: the name in Label (cut
  with an ellipsis, the whole name in the tooltip), the value in Number at the
  right ("--" for none); no row panel or hairlines, the rows on the page. The client keeps no fold state here: the folds are
  ours, and every category starts folded.

