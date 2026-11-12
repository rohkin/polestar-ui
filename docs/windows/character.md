#### Character (`CharacterFrame`) — Risk: medium
Opened by `TOGGLECHARACTER0/2/4`, `TOGGLECURRENCY` and the micro button; all
call `ToggleCharacter(subFrame)` or `CharacterFrame:ToggleTokenFrame()`.
Code: `Character.lua` (shell, gear, stats, the drawer and its Pet pane),
`CharacterPages.lua` (the other sections' lists), `CharacterGear.lua` (Gear
sets, Titles, the slot flyout), `CharacterDetails.lua` (the other sections'
details).
- **Shell:** 960×680 with sidebar (240).
- **Subject block:** the class icon (36px, the game's class atlas,
  `GetClassAtlas`, on an inset well, hairline), the first name in Title (no
  surname: the sidebar has no room), the level line as the stock sheet writes
  it ("Level 24 Warrior"; "Level 20 (24)" when scaled; the specialization
  when the class picks one) in Small textDim; the guild under it in Small
  textMuted (none without one); each to the 24 edge, ending in an ellipsis
  past it. Name and guild are read out of combat (CLIENT.md, rule 3).
- **Sidebar sections** (stock subframes, in stock order): Character
  (`PaperDollFrame`), Reputation, Currency (always: the stock
  `ShouldShowCurrencyTab` returns true; only the `TOGGLECURRENCY` key does
  nothing with an empty list, as `ToggleTokenFrame` does), Honor
  (`PVPRankFrame`), Skills, Statistics.
- **Band:** the section's name as title; a status subtitle (Character: "2
  items need repair" or "Gear in good repair"; Reputation: "Watching
  Stormwind" or the faction count; Currency, Skills, Statistics: their
  counts; Honor: the season); Options on every section with a drawer: "Show
  stats" (Character) or "Show details", checked while the drawer shows.
- **The drawer** (the stock right pane): 280px wide, its own window skin,
  docked flush to the window's right edge and as tall (the shell stays 960
  wide; open, the two read as one 1240px window, as in the armory). Options
  puts it away and back, for every character (`PolestarUIDB.hideStats`), on
  every section at once, as the stock pane's collapse. Its top band (72px)
  holds the Character page's pane tabs (Stats, Gear sets, Titles, Pet with a
  pet; Label, the chosen one text with a 2px accent line under it, the rest
  textDim), or another section's details heading in Heading (the chosen
  faction, currency, skill, the PvP rank). Panes are painted out of combat
  only (`ns.CharacterPanes`). Statistics has no drawer.
  - *Stats*: one scrolling column: a Heading per stock category
    (`PAPERDOLL_STATCATEGORIES`) and Resistance (the stock pane's five
    schools, `UnitResistance`) over a panel of 28px stat rows, 24px in, every
    row alike (no highlights). A chevron in the gutter beside each heading
    folds it; the folds are kept for every character
    (`PolestarUIDB.statsFolded`, by category name). Numbers, the stats shown
    and their tooltips are the stock sheet's own: each row is filled by
    `PAPERDOLL_STATINFO[stat].updateFunc`, so the client's colours for buffed
    and debuffed values stay.
  - *Gear sets* (the Equipment Manager, `C_EquipmentSet`): 36px rows, the
    set's icon in a 24px well, its name (danger when an item is missing), a
    success check on the worn one, the 2px accent bar on the chosen one. Click
    chooses, double-click or Equip wears it, drag puts it on the action bars,
    right-click: Rename or change icon, Save the gear worn now, Delete (a
    second click confirms). New set, Save and Equip buttons at the foot. New
    set and rename are a dialog: the name and an icon grid (the worn items'
    icons, then the question mark). A new set leaves shirt and tabard out, as
    the stock one; a name in use asks to replace that set. In combat Equip
    waits: the set goes on at `PLAYER_REGEN_ENABLED`, with a chat line.
  - *Titles*: "None" then the known titles by name, 28px rows, the worn one
    checked; a click wears one (`SetCurrentTitle`).
  - *Pet* (only with `HasPetUI`): the pet's level, family and loyalty, its
    happiness (a hunter's pet; the stock tooltip with damage, loyalty and
    diet), its experience over a 2px bar, then its stats as the Stats pane
    (the stock "pet" categories). While it shows, the model well holds the
    pet (`C_PetInfo.GetPetUIModelSceneID`) and the gear slots step aside.
- **Character page** — no tabs: the gear, the model between its columns.
  Item level is not shown anywhere: it means nothing in Forever.
  - *Gear*: two slot columns on the 32 and right edges (Head, Neck, Shoulder,
    Back, Chest, Shirt, Tabard, Wrist; Hands, Waist, Legs, Feet, Finger ×2,
    Trinket ×2), then, 16px down, the weapons in a row centred under the model
    well (Main Hand, Off Hand, Ranged), as the stock sheet and the armory lay
    them out. Ammo is a 16px tile in the Ranged slot's bottom-right corner,
    shown only when the ranged weapon is a bow, gun or crossbow, its count
    above it. Slot tiles 36px item wells (`ns.ItemWell`), 6px apart; a stack's
    count at the bottom right; the Use: cooldown's sweep; locked items grey,
    broken ones red, as the stock slot; the item's sockets as 12px wells
    along its bottom edge (each gem's icon, or the empty socket). Beside each
    column's slot, on the inside (over the model well): the item's name in
    Label in its quality colour, 220px wide, and under it a permanent enchant
    (its tooltip line, "Enchanted: " dropped) in Small success; the lines
    centred on the slot (no item stats: those are the drawer's). The weapons'
    text sits on the row's outer sides, Main Hand's left and Ranged's right,
    and Off Hand's centred under its slot; empty, the slot's name in
    textMuted. Painted out of combat only.
  - *Slot actions*: click picks up or puts down, drag takes it off,
    shift-click links, shift-right-click sockets (`SocketInventoryItem`),
    right-click uses a Use: item and a click applies a waiting enchant (both
    through the secure overlay, out of combat; in combat the tooltip says
    they wait for the fight to end). An item dropped on the model goes on
    (`AutoEquipCursorItem`).
  - *Slot flyout* (the stock `EquipmentFlyout`): Alt over a slot shows a
    panel of 36px wells beside it (over the item text; under a weapon): Put in
    bags, then, while a gear set is chosen, Leave out of the set (or Put back
    in the set: the slot then carries a danger ✕), then the items in the bags
    and worn elsewhere that fit (`GetInventoryItemsForSlot`). A click wears
    one; in combat only the weapons change, as the client allows.
The other sections share one grouped list: the client's top headers as
Headings with their hairline, a chevron in the gutter that folds them (the
client's own collapse state), over a row panel. They are painted out of combat
only and read in the background like the stats (CLIENT.md, rule 3). A click
on a row chooses it for the drawer's details (the selection wash), and opens
the drawer if it was put away, as the stock right pane.
- **Reputation:** faction rows 40px: the name in Body text (danger when at
  war), the standing in Small in its standing colour (legible form) at the
  right, a 2px standing bar (track wash, fill in the standing colour) under
  them. A sub-header is a row in textDim with its own chevron, its factions
  indented 18px. The watched one carries the 2px accent bar. Details: the
  standing and its points, the bar, the description, "Account-wide" when it
  is, and the stock checkboxes At War (danger; only where the faction allows
  it), Inactive (the client's Inactive group) and Show as Experience Bar.
- **Currency:** 28px rows: the icon in an 18px item well at 15, the name in
  Label, the amount (and its cap) in Number at the right; the game's currency
  tooltip. Shift-click links it while typing in chat, else shows it on the
  backpack (or stops). Details: the description, the amount, total and
  weekly maximum, and the stock checkboxes Unused (the client's Unused group)
  and Show on Backpack.
- **Honor:** Forever's PvP rank (the major faction 2800, as the stock page
  reads it): the title and rank in Display, the season's countdown in Small
  textDim ("Season ends in 12 days 5 hours", kept to the second), the points
  to the next rank in Number over a 3px accent progress line. Details: the
  points the season's top rank takes, the season's progress against this
  week's cap, how much the cap rose this week, the next rank with rewards as
  tiles, and where to buy them.
- **Skills:** the stock page's lines (no class skills, no sub-lines): 40px
  rows, the name in Body, "rank/max" (and the modifier, "(+5)"; Defense's gear
  bonus too) in Small textDim at the right, the 2px accent skill bar under
  them. Details: rank, bar, description and, for a weapon skill, the stock
  hit and crit odds against your level and a raid boss (glancing blows for
  melee).
- **Statistics:** the client's statistic categories as the stock page reads
  them, a group per top category; a sub-category is a row in textDim with its
  own chevron, its statistics indented 18px. 28px rows: the name in Label (cut
  with an ellipsis, the whole name in the tooltip), the value in Number at the
  right ("--" for none); no row panel or hairlines, the rows on the page. The
  client keeps no fold state here: the folds are ours, and every category
  starts folded.
- **Left to the game's window** (the client forbids them to addon code):
  moving a currency to another character of the account
  (`C_CurrencyInfo.RequestCurrencyFromAccountCharacter` has restrictions) and
  the reputation's View Renown button (it opens the Encounter Journal with
  `ShowUIPanel`, which does nothing from addon code: CLIENT.md, rule 1).
