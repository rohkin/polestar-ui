# Design System: Polestar: UI

Polestar: UI inherits every token, rule and component from Polestar's own
[DESIGN.md](https://github.com/fitzforge/polestar/blob/main/docs/DESIGN.md)
(the Dusk grounds, the gold accent, the text ladder, the type ladder, the
hairline grid, the Square-and-Capsule Rule, the starlit band, motion). Nothing
here restates it. This file says only how the game's own interface is remade in
that language: which shell each stock element becomes, the few components the
game's windows need that Polestar has no use for, and how each one is replaced
without breaking the game's secure code.

Where this file and Polestar's disagree, Polestar's wins and this file is wrong.

## Overview

**Creative North Star: "One instrument, the whole cockpit."** Polestar already
looks like one crafted object in several sizes. Polestar: UI extends that object
to everything else on screen, so the guide window no longer sits beside a UI from
another era. The player should not be able to tell where Polestar ends and the
game begins.

**How it is built.** Every window is drawn by Polestar's own kit at runtime
(`Polestar.Widgets`, `Polestar.Theme`). Nothing paints its own colour: a token,
the player's accent, scheme or brightness change in Polestar's Options repaints
Polestar: UI live through `Theme.OnChanged`. When Polestar's look changes, ours
changes with it, and the preview goldens (`tests/golden`) show exactly how.

**Key Characteristics** (in addition to Polestar's):
- Every stock window becomes a `W.Shell`: the sidebar names the window and its
  sections, the starlit band carries the page's title, tabs split a page.
- Game data keeps the game's meaning: item quality, recipe difficulty and
  reputation standing keep their client colours, lifted through `Theme.Legible`
  before they carry text, and raw only on a 1px border.
- Game icons stay game icons (the Two Families Rule): an item, a spell or a
  profession wears its client icon; controls wear Polestar's glyphs.
- Every replacement is a module the player can switch off, which gives the stock
  frame back at once.

## Intent

**Who it is for.** The same Forever players as Polestar, who already chose its
look and want the rest of the game to match it, often in place of a full UI
suite (ElvUI, EllesmereUI).

**What success looks like.** Opening the Character window feels like opening
Polestar's Options: the same sidebar, band, tabs and rows, read at the same arm's
length. Everything the stock window could do still works: equipping, comparing,
the game's tooltips, the keybinding that opened it. Nothing is lost, nothing is
blocked in combat, and the gamepad still reaches it.

**Constraints.** Those of Polestar (Lua frames, textures and FontStrings only,
power-of-two textures, GPL-3.0, readable code), plus:
- **Forever's client is the mainline family** (game type `camelot`): Character is
  `CharacterFrame` with `PaperDollFrame`, `ReputationFrame`, `TokenFrame`,
  `PVPRankFrame`, `SkillsFrame` and `StatisticsFrame`; professions are
  `ProfessionsBookFrame` and `ProfessionsFrame` (`C_TradeSkillUI`). Verify every
  API against `.ref/wow-ui-source-forever` (Gethe/wow-ui-source, branch
  `forever`), never against Era or retail memory.
- **Secure code reads the game's frames.** Forever's gamepad UI
  (`Blizzard_GamepadSmartNavigation`) focuses, opens and closes the stock windows
  from secure code. See The Replacement Contract.

## The Replacement Contract

How a stock element is replaced, for every module.

1. **Our frames are our own.** We never add children, scripts or hooks to a
   Blizzard frame, and never call a Blizzard frame's methods except the ones in
   step 2. We build our own window, named `PolestarUI<Element>`.
2. **The stock way in opens ours, and the stock window closes.** Keybindings and
   micro buttons call stock toggles (`ToggleCharacter`, `ToggleProfessionsBook`,
   `ProfessionsFrame_LoadUI`). We follow them with `hooksecurefunc` (a post-hook
   never taints the caller): the stock window the toggle just showed is closed
   with its own `Hide()` in the same call, so it never draws, and ours opens.
   Never `HideUIPanel`: it dispatches to the forbidden `FramePositionDelegate`
   and does nothing from addon code; the panel manager repairs a panel hidden
   directly before it places the next one (`RepairUIPanelState`). We
   never replace the global, reparent the stock frame or unregister its events.
   **Except** a stock window whose show/hide scripts touch secure frames
   (`PlayerSpellsFrame`: the action bars): hiding it from our code taints them
   (CLIENT.md, rule 8). Such a window is never touched; its keys are override
   bindings to a button of ours and its micro button carries a secure overlay
   of ours (`ns.Doors`), whose shift-click opens the stock window.
   **And except** a stock window whose hiding ends what it shows
   (`ProfessionsFrame`: the trade skill). Its open is stopped at the game's
   event routing (`GameEvent.UnregisterInternalEvent`), the one stock event we
   unregister; `/reload` with the module off routes it again.
3. **Off is off.** `/pui <module> off` and a `/reload` give the stock window back
   untouched, since nothing was changed on it.
4. **With the gamepad UI on** (`Polestar.GamepadUI()`), a module whose stock
   frame the smart navigation focuses stays off by default, and no slash command
   is registered. (A setting to turn a module on anyway comes with Options.)
5. **Protected actions stay on secure templates.** Anything the game protects
   (casting, targeting, using an item in combat) is a `Secure*Template` button
   with attributes set out of combat. Item equipping out of combat
   (`PickupInventoryItem`, `EquipCursorItem`) is not protected.

6. **Follow the client rules.** [CLIENT.md](CLIENT.md) lists what the client
   does that the preview stub did not, each learnt from a bug in game: no
   `HideUIPanel`, fonts before text, secret values in combat, protected calls
   in combat, stock scenes tuned for stock frames, lists that change without
   an event. A new rule goes there, and
   into the preview where it can.

Each catalogue entry below names its **Risk**: *low* (no protected calls, stock
frame not read by secure code), *medium* (stock frame read by gamepad
navigation), *high* (protected actions or secure headers).

## The Game Window Shell

Every stock window becomes one `W.Shell(name, opts)`. The shell's grid is
Polestar's: the band 0–112, the tab band 112–152, the hairline at 152, the 24 and
32 edges, the 56px footer.

- **Size.** The stock windows are small (Character is 631×484); ours keep the
  shell's 960×680 only when a window has a sidebar of sections. A window with
  only tabs uses `opts.plain` and a width that fits its content (see each entry),
  height 600 at most so it never covers the guide window at default scale.
- **Sidebar.** The window's identity, not Polestar's: in place of the lockup, a
  **subject block** (the thing the window is about: the character, the
  profession) at the band's line, then the window's sections as `W.ShellNav`
  rows. The Polestar emblem stays in the rail of a hub only.
- **Header.** The page title in Hero on the band, its subtitle in Note textDim:
  a fact ("Level 24 Human Warrior", "Blacksmithing 145/150"), or one line for
  a newer player saying what the page is and what they can do on it ("Click a
  faction to follow it on your experience bar.", "Your skills rise as you use
  them; a trainer raises how high they can go."). Anything that can be
  clicked or dragged in a way a newer player would not guess ends its tooltip
  with a hint in textMuted after a blank line (`ns.TooltipHint`), saying what
  it does now ("Shown on your experience bar. Click to stop.", "Drag an item
  here to equip it."); where the title line holds facts, the hints live in the
  tooltips alone (Gear, Stats).
- **Tabs.** `W.ShellTabs` for the views of one page; one view is no tab row.
- **Footer.** Only when a page has actions (Reset, Craft, Learn). Never "Close":
  the ✕ and Escape already close it.
- **Opens where the stock window opened** (the stock UI panel's left slot), then
  remembers where the player dragged it (`PolestarUIDB.pos[name]`).
- **Flyouts** (a drawer, a side panel) are part of their window to the
  dock: one inside the window grows it (the map's quest log); one hung off
  its right edge (the Stats drawer) is given to `ns.DockFlyout`, so the
  dock makes room for it while it shows and the window keeps it on screen.
- **Escape** closes it through `Polestar.CloseOnEscape`, which already skips
  `UISpecialFrames` under the gamepad UI.

### Named Rules

**The Same Doors Rule.** A replaced window opens from every door the stock one
did: its keybinding, its micro button, its slash command and every other window
that opened it. A door we miss is a bug.

**The Nothing Lost Rule.** A replacement ships only when everything the stock
window did works: if a feature is not built yet, the window links to the stock
frame for it ("Open the game's view") rather than leave it out silently.

## Element Catalogue

Ordered by build increment. Each entry: what it becomes, its layout, and its
Risk. Sizes are UI units at scale 1, on the shell grid.

### 1. Windows

#### Character (`CharacterFrame`) — Risk: medium
Opened by `TOGGLECHARACTER0/2/4`, `TOGGLECURRENCY` and the micro button; all
call `ToggleCharacter(subFrame)` or `CharacterFrame:ToggleTokenFrame()`.
- **Shell:** 960×680 with sidebar (240).
- **Subject block:** the class icon (36px, `ClassIcon_<class>` on an inset
  well, hairline), the first name in Title (no surname: the sidebar has no room), "Level 24 Warrior" in Small textDim; the
  guild under it in Small textMuted (none without one); each to the 24 edge,
  ending in an ellipsis past it. Name and guild are read
  out of combat (CLIENT.md, rule 3).
- **Sidebar sections** (stock subframes, in stock order): Character
  (`PaperDollFrame`), Reputation, Currency (only while `ShouldShowCurrencyTab`),
  Honor (`PVPRankFrame`), Skills, Statistics.
- **Character page** — title the character's PvP name, subtitle level, race,
  class. No tabs: the gear, with the stats in a drawer at the window's right.
  Item level is not shown anywhere: it means nothing in Forever.
  - *Gear*: two slot columns on the 32 and right edges (Head, Neck, Shoulder,
    Back, Chest, Shirt, Tabard, Wrist; Hands, Waist, Legs, Feet, Finger ×2,
    Trinket ×2), then, 16px down, the weapons in a row centred under the model
    well (Main Hand, Off Hand, Ranged), as the stock sheet and the armory lay
    them out. Ammo is a 16px tile in the Ranged slot's bottom-right corner,
    shown only when the ranged weapon is a bow, gun or crossbow. Slot tiles
    36px, 6px apart. Beside each column's slot, on the inside (over the model
    well): the item's name in Label in its quality colour, 220px wide, and
    under it a permanent enchant (its tooltip line, "Enchanted: " dropped) in
    Small success; the lines centred on the slot (no item stats: those are the
    drawer's). The weapons' text sits on the row's outer sides, Main Hand's
    left and Ranged's right, and Off Hand's centred under its slot; empty, the
    slot's name in textMuted. Painted out of combat only.
  - *Stats drawer*: 280px wide, its own window skin, docked flush to the
    window's right edge and as tall (the shell stays 960 wide; open, the two
    read as one 1240px window, as in the armory). "Hide stats" / "Show
    stats" with a chevron at the right of the tab row (kept with no tabs) puts
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
- **Currency:** 28px rows: the icon 16px in a 1px hairline (18px at 15), the name in Label, the amount
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

#### Talents (`PlayerSpellsFrame`, its talents tab) — Risk: high
Opened by `TOGGLETALENTS` and `TalentMicroButton` through `ns.Doors`, as the
Spellbook (in combat too); shift-click on the micro button opens the stock
window. Not before the first talent point
(`C_SpecializationInfo.HasPlayerEarnedATalentPoint`): the stock micro button
is disabled until then and its overlay steps aside, and the key does nothing.
Talent links and inspecting another player stay the game's.
Forever's talents are the classic three trees on the client's trait engine
(`C_Traits`, one tree, a node group per talent tree): changes are staged, then
applied. Not protected, but refused in combat and while
`C_ClassTalents.CanChangeTalents` says no; switching spec is a cast.
- **Shell:** 1100×680 with sidebar: wider than the shell's 960, so three
  four-column trees stand apart.
- **Subject block:** the class icon, the class in Title, "Level 60" in Small
  textDim.
- **Sidebar:** the shell's search ("Search talents"), then the stock tabs as
  nav rows, Primary and Secondary (`DUAL_SPEC_PRIMARY`/`SECONDARY`): the
  active spec's row with the dot, the other with its points spent as the
  count. Until dual spec is learnt (`GetNumSpecGroups() > 1`) Secondary is
  locked, as the stock tab: the lock glyph, receding (a count of 0), a click
  does nothing, and its tooltip is the stock `TALENT_SPEC_LOCKED`.
- **Search:** as the stock frame's, a talent matches on its name or its
  description; the others recede to 25%, and the subtitle counts the matches
  ("7 talents match.").
- **Main column:** title "Talents", subtitle the points left ("12 points to
  spend.", "Every point is spent."), then "Your changes are not applied
  yet." while something is staged, and "Applying your talents…" while Apply
  runs. Viewing the spec that is not active, the
  subtitle says so ("Not your active spec.") and the footer's primary action
  is "Activate" (the stock `SetActiveSpecGroup`), the trees read-only.
- **Art:** the class's talent art, as the stock frame shows it
  (`talent-background-<class>`, one atlas, a panel per tree), fills the main
  column under the band at 85%, under a wash of Polestar's sky at 55%: full
  width, the middle band of its height (its aspect kept), so each panel sits
  behind its tree. Both fade to nothing over 160px at the column's left and
  right edges, and over 80px either side of each seam between the art's
  panels (at a third and two thirds), so no hard line shows between trees. A game texture, so a game thing (the Two Families Rule); the
  wash keeps it in Polestar's grounds and follows the theme.
  Where it meets the band, a hairline (the border wash), full at the middle,
  fading to nothing at the column's edges.
- **Trees:** the three trees side by side, each a column a third of the main
  column (the art's panels, between its seams): the tree's nodes on a 52px
  grid of at least four columns, centred in the column, under its heading,
  centred too: its icon (24px), its name in Heading and the points spent in
  Number textDim 8px after it, kept two digits wide so the heading does not
  move as points go in. The grid is read off the client's positions
  (`posX`, `posY`), which sit a few units off it: one cell is the smallest
  step between positions that is at least a quarter of the largest, and each
  node rounds to the nearest cell. A node reads as the stock one: a 40px game
  icon on an inset well; partly learnt, its 1px border and rank in success;
  maxed, in the accent; open to a point, the hairline and no rank. Greyed as
  the stock button greys (`CalculateVisualState`): a talent keeps its colour
  while it has points or can take one now (`canPurchaseRank`, prerequisites
  met, the active spec, its cost, `C_Traits.GetNodeCost`, on hand); else its
  icon is desaturated, at 30% while its tier is closed (`isAvailable`), at
  75% otherwise (a prerequisite missing, no point to spend, the inactive
  spec). The rank (the
  points in it, "3") is in Number text on a solid 18px chip (the bg ground,
  its 1px border in the node's state colour) centred on the well's
  bottom-right corner, shown once learnt: legible over any icon. Prerequisites are the client's
  edges, drawn as 2px lines in the border wash under the nodes, in the accent
  once met.
- **Node:** on the active spec, click puts a point in and right-click takes
  one back, as the stock buttons allow (`canPurchaseRank`, `canRefundRank`):
  `C_Traits.PurchaseRank`/`RefundRank` stage it on the config, with the stock
  spend and refund sounds, and the window and tooltip redraw at once. While
  Apply runs, clicks change nothing. The tooltip is the stock talent
  tooltip's lines, built as the
  stock frame builds them: the name, "Rank 3/5", the subtext ("Passive"), this
  rank's text and, once learnt, "Next Rank:" with the next one's
  (`AppendInfo("GetTraitEntry")`), then the tier gate it waits on ("Requires
  10 points in Affliction", `C_Traits.GetConditionInfo`) and an unmet
  prerequisite; after a blank line, the hint for what a click does now ("Click
  to learn a rank. Right-click to take one back. Shift-click to link it in
  chat."). Shift-click links the spell.
- **Footer:** "Reset" (danger, every staged and spent point back, confirmed by
  `W.Modal`) on the left; "Undo" (default, drops what is staged:
  `RollbackConfig`) and "Apply" (primary, `C_ClassTalents.CommitConfig`, the
  stock apply sound) on the right, always there so the layout never moves,
  disabled as Polestar disables (faded to 45%) unless something is staged
  (`ConfigHasStagedChanges`) and no commit is running. Apply first asks
  `CanChangeTalents` (its error on the game's error line when refused); the commit is a cast, ended by
  `TRAIT_CONFIG_UPDATED` or `CONFIG_COMMIT_FAILED`, or after the stock
  frame's 6 seconds.
- **Options:** on the band, a disabled line saying the micro button's
  shift-click opens the game's talents (its search and inspect, until ours has
  them: the Nothing Lost Rule).

#### Professions book (`ProfessionsFrame`, its book page) — Risk: high
Forever has no `ProfessionsBookFrame`: `ToggleProfessionsBook` shows
`ProfessionsFrame` on its book page (`SelectBookPage`), whose show touches the
micro buttons. So, as the Spellbook, ours opens from `TOGGLEPROFESSIONBOOK` and
`ProfessionMicroButton` through `ns.Doors`, never touching the stock window;
shift-click on the micro button opens the stock one. It closes when a
profession opens (`TRADE_SKILL_SHOW`), as ours takes the crafting window.
- **Shell:** 760×680 plus the section rail, no sidebar (`sidebar = 0`,
  hidden): one page, nothing to navigate, so no subject block either; the band
  names the window.
- **Professions rail:** the crafting window's (`ns.ProfessionTabs`, below),
  "Overview" marked; a profession's section opens its crafting window.
- **Main column:** title "Professions", subtitle "2 of 2 professions learnt."
  and what the player can do. The
  stock page's five slots as cards on the panel ground under two headings:
  Primary (one to a row: wide, short cards, the spells side by side, as the
  stock page and its art), then Secondary (Cooking, Fishing, First Aid, three
  to a row). A card: the profession's icon (40px on an inset well), its name in
  Title, its skill bar with the rank ("145/150 (+5)") above its right end, then
  its spells as the Spellbook's rows (`ns.SpellRow`: click casts through the
  secure button, drag, shift-click links, cooldown). An empty slot: the stock
  scroll icon desaturated, the slot's name and the stock "learn it" line in
  textMuted. Behind each card, the stock page's card art, as the Talents
  window's class art: at full strength under a wash of Polestar's sky at 55%,
  cropped to the card's shape (the band 85% of the way down its height: the
  scenes sit low) and 6% trimmed off each edge so the stock card's rounded
  frame never shows, both fading to nothing over 64px at its sides. A primary
  wears its profession's card (`Profession-overview-Card-<name>`, the client
  name, as the stock page names it; the generic `Profession-overview-Card`
  when there is none), a secondary its generic one
  (`Profession-overview-card-generic-cooking`, `-fishing`, `-firstaid`); an
  empty slot's art is greyed. A primary's ✕ unlearns it (`C_SkillInfo.AbandonSkill`, not
  protected), confirmed by `W.Modal` in danger.

#### Professions (`ProfessionsFrame`) — Risk: medium
Opened by the game when a profession is cast (`TRADE_SKILL_SHOW`). The stock
window ends the trade skill as it hides (`CloseTradeSkill` in its `OnHide`), so
it cannot be closed under ours: the game's own open is stopped instead
(`GameEvent.UnregisterInternalEvent("TRADE_SKILL_SHOW")`, CLIENT.md rule 11)
and ours opens on the same event. Ours holds the trade skill: closing it calls
`CloseTradeSkill`, and the game's `TRADE_SKILL_CLOSE` closes it. `TRADE_SKILL_SHOW` can come before the
trade skill's data (the stock window opens empty and fills on
`TRADE_SKILL_LIST_UPDATE`): ours then opens on that update. Doors only
the stock code knows (a recipe link) still open the stock window.
- **Shell:** 760×680 with sidebar, near the stock window's width, plus the
  section rail: the Professions window's size, and its place (`ns.LinkPlace`:
  each opens where the other is or was last, kept in `PolestarUIDB.pos`), so
  switching between them never moves the window.
- **Professions rail** (`ns.ProfessionTabs`, shared with the Professions
  window): the shell's section rail (`rail = true`, `W.ShellRail`), Polestar's
  own way to switch sections. "Overview" first (the Professions window,
  closing this one), then one section per profession with a crafting window,
  in the stock order; the open one marked as the rail marks it. The icons are
  the game's (24px, untinted), not glyphs; Polestar's emblem stays off the
  rail. Casting a profession is protected: out of combat a secure button of
  ours takes the hovered section's place (`ns.Overlay`), its click the
  profession's spell; the open one casts nothing. In combat the sections only
  show their tooltips.
- **Subject block:** the profession's icon, name in Title, and its 2px skill
  bar under it with the rank ("112/150") above the bar's right end.
- **Sidebar:** the search (shell's own) and the filter, then the learnt recipes under their
  categories in the client's order, "Can make now" (nothing missing, no
  cooldown) and "Recent" (the last 8 crafted here, kept per character) first.
  A category is a heading row with its count; a click folds it. Under it, one
  recipe row per recipe. A search shows every match, unfolded.
- **Filter:** it acts on the list, so it sits in the sidebar at the end of
  the search row: a 30px square on the search field's well, the `sliders`
  glyph, in the accent while a filter hides recipes (on the band it read as
  filtering the selected recipe). Its menu drops under it, over the list.
  Its menu is the game's own filter menu, flat (Polestar's menu has no
  submenus): "Has skill up" (not for a guild's recipes), "Have materials",
  then after a hairline "Check all", "Uncheck all" and each item slot. The
  client keeps them (`C_TradeSkillUI.SetOnlyShow*`, `SetInventorySlotFilter`)
  and they act on its filtered recipe list, as in the stock window; the menu
  opens again after each pick.
- **Main column:** title the selected recipe, subtitle its category. One view,
  so no tab row (Orders later).
  - *Recipe page:* the product as a 40px tile with its name in its quality
    colour (legible) and "Makes 2" when it makes more than one, the recipe's
    description in textDim, the reagents under a "Reagents" heading as reagent
    tiles (two columns, 8px apart), then the tools and places line ("Requires
    Moonwell"), the cooldown and the game's own reason in Note (warning while
    they stop the craft).
- **Footer:** quantity stepper (−, a 48px field, +, "Max") on the left,
  "Craft all" (default) and "Craft" (primary, the recipe's own verb when it has
  one) on the right; all faded to 45% while the game would refuse the craft or
  the recipes are another player's. `C_TradeSkillUI.CraftRecipe` is not
  protected on Forever (`SecretArguments = "AllowedWhenUntainted"`, no
  restriction): our button's click calls it.
  - *Enchants* (`recipeType == Enchant`): after the reagents, "Item to
    enchant" and one item slot, as the game's (`PROFESSIONS_ADD_ENCHANT`,
    "Add an item", in textMuted on an empty well). A click lists the items it
    can go on (`GetEnchantItems`, worn ones marked "(equipped)") in Polestar's
    menu; a right-click clears it; the tooltip is the item's
    (`SetItemByGUID`). With an item, Craft is `CraftEnchant` on its location
    (not protected either), one at a time unless the item stores enchants
    (`CanStoreEnchantInItem`, a vellum); without one, Craft casts the enchant
    and the game asks for the item, as it would from the spellbook (a trade
    window's item). An item no longer in the bags or worn is let go.

#### Legacy (`LegacySystemFrame`, Blizzard_LegacySystem) — Risk: high
Forever's account-wide progression: a renown track (faction 2802), the
challenges (achievements) and a legacy talent tree (`C_Traits`). The stock
window's show and hide run `UpdateMicroButtons`, so it is never touched
(CLIENT.md, rule 8): `TOGGLELEGACYSYSTEM` and `LegacyMicroButton` open ours
through `ns.Doors`, and like the stock toggle only from the first legacy
point. `TOGGLEACHIEVEMENT` (which Forever routes to the challenges) opens ours
on Challenges; challenge links (`ShowLegacyChallenge`) stay the game's.
- **Shell:** 960×680 with a section rail (as the Professions windows), headed
  by the Legacy emblem: Rewards, Challenges and Tree, with the stock tabs'
  game icons. The sidebar shows on Challenges only (subject block: the Legacy
  emblem, "Legacy", the player's legacy points, the track's renown level; the
  search; the categories); the other pages take its width, the main column
  hung off the rail (CLIENT.md, rule 12).
- **Reward Track:** progress toward the next reward (a skill bar, points over
  the reward's points), then a row panel, one row per reward level: the points
  it needs, the reward's game icon, its name and description
  (`RenownRewardUtil`), a check when earned or a lock. The next reward carries
  the accent mark. Tooltips are the stock card's.
- **Challenges:** the client's achievement categories in the sidebar, folding
  as the stock list does: a top category with sub-categories is a group row
  (label face) whose chevron folds them, opened for the class's own category
  and while searching; one without is a row of its own. Built as the stock
  list builds it: any depth, each level starting at its parent's label; the
  client's list can name a child before its parent; only categories with a
  challenge in the client's search list (set, even empty, after every
  loading screen) and their parents show. Text only, no icon on
  any row. Each row counts the challenges shown and carries the stock
  "unviewed" dot (`LegacyChallengeViewedUtil`, marked viewed on opening). The sidebar search is the client's (`SetAchievementSearchString`,
  answered by `ACHIEVEMENT_SEARCH_UPDATED`); a category with no match dims.
  No tabs: the stock filter (Completed, Incomplete, both shown at first; one
  earned by another character is incomplete) is a menu on a filter button at
  the end of the search row, as the crafting window's, its glyph in the accent
  while a filter hides challenges. A row per challenge: game icon, name, description,
  its legacy points (`GetTraitCurrencyForAchievement`) and the date earned. A
  click unfolds its objectives in two columns (a counted one as a skill bar);
  shift-click links it in chat, or tracks it with no chat box open.
- **Legacy Tree:** three `C_Traits` trees (Professions, Adventure,
  Progression; `C_Traits.GetConfigIDByTreeID`), one shown at a time. The
  sidebar holds the search (the tree's talents: a talent that does not match
  recedes) and the trees, each with its art and the points spent in it. The
  page: the tree's heading (art, name, points in it), then its talents on the
  client's grid (read off its positions, as Talents) centred in the page, each
  with its ranks as the stock button shows them ("0/5") on a chip, and the
  client's edges edge to edge, in the accent once met. Click spends a rank,
  right-click takes one back, staged until Apply (`C_Traits.CommitConfig`,
  changes held until `TRAIT_CONFIG_UPDATED` or `CONFIG_COMMIT_FAILED`). Footer:
  Apply, then Undo while something is staged, else Reset (`C_Traits.ResetTree`,
  on a second click). The subtitle says the points left to spend.

#### World Map and Quest Log (`WorldMapFrame`, `QuestMapFrame`) — Risk: medium
Forever loads the mainline map: the quest log is a panel inside
`WorldMapFrame`, and other addons (Polestar's own map features, Mob Markers,
OpenMap) draw on that frame's canvas by its global name. Pointing the global
at ours would taint every Blizzard reader of it (`UpdateMicroButtons`, the
action bars' spell flyout), so the stock map is never touched: it stays the
map those addons draw on, and its hide runs `UpdateMicroButtons` (CLIENT.md,
rule 8). Ours is a second map, built as the game builds its zone map
(`BattlefieldMapFrame`): the game's `MapCanvasFrameTemplate` with the stock
map's data providers and pin layers, so its art, fog, pins, player arrow,
zoom and click-to-open are the game's.
- **Shell:** the sidebar's width plus a canvas of 852×568 (the map art's
  shape) under the band; no tabs, no footer. Subject block: the map icon,
  "World Map", the player's zone.
- **Sidebar:** "Where you are", then the maps above the shown one (to go
  back out), then its zones (continents and zones only, by name).
- **Header:** the shown map's name; the subtitle says how to move around it.
  A full-screen toggle at the band's bottom right, as the stock maximise
  (remembered; out of the dock while full).
- **Zoom:** the canvas takes its zoom steps from the map art; where the art
  gives one (Forever's), ours adds 1.5×, 2.25× and 3×. Drag pans once zoomed.
- **Quest Log:** a 320 flyout right of the canvas, under the band, on the
  sidebar ground, opened by a "Quests" button left of the full-screen
  toggle (remembered). Windowed, the window grows by its width; full screen,
  the map gives it room. Its head: "Quests" and the log's count over the
  most it holds. The log as the stock panel lists it: header rows (label
  face, chevron, count) fold through the client and redraw at once
  (CLIENT.md, rule 6); hidden quests, tasks and unfinished bounties stay
  out. A quest row: "[level] title" in Body in its difficulty colour
  (legible), what is left under it in Small textDim (the unfinished
  objectives, or the hand-in line once done), a check (success) when done
  or a star (accent) when tracked. Hover lights its area on the map (the
  canvas's `SetHighlightedQuestID`); a click shows its map with its area in
  focus and selects it; shift-click tracks it (the stock toggle); with a
  chat box open, a click links it. A search under the head (the sidebar's
  search box) matches a quest's title or what is left of it; searching,
  every match shows with its header open.
- **Doors:** `TOGGLEWORLDMAP` toggles ours; `TOGGLEQUESTLOG` and
  `QuestLogMicroButton` open it with the quest log, or close it when the
  log shows, as the stock toggle (`ns.Doors`; shift-click on the micro
  button: the stock map, for the quest details we do not show yet). Map
  links and the quest tracker stay the game's.

#### Later windows
Each gets its entry before it is built. Planned order and Risk:
Social (low), Merchant (medium), Bank (medium), Mail (low),
Auction (medium), Trainer (low), Gossip and Quest dialog (medium), Loot (high:
`LootSlot`), Game menu (high: protected logout/exit), StaticPopup (high: never
replaced, only restyled windows of our own call `W.Modal`).

### 2. HUD (after the windows)

Listed so the shell rules are written for them later; each gets a full entry
before it is built. Unit frames (player, target, target of target, focus, pet,
party, raid, boss), cast bars, auras, action bars (main, multi, pet, stance,
possess/vehicle), micro menu, bag bar, XP and reputation bars, minimap, chat,
tooltip, nameplates, objective tracker, error and raid warning text, mirror
timers. All are high Risk (secure headers, protected positions in combat) except
the tooltip, XP bar and error text (low).

HUD elements cast no window shadow and carry no band: they sit on the world, so
they follow Polestar's Transparent guide-window rules (outlined text, faint
tracks), with a panel ground only where the player turns it on.

## Components

New components, built from Polestar's widgets. Each takes its colours through
`Theme.Color`/`W.Painter` only.

### Slot Tile
- **Size:** 36×36; the game icon inset 1px; a 1px border in the item's raw
  quality colour (common and poor items: the border hairline).
- **Empty:** the inset well with the stock empty-slot texture desaturated to
  textMuted at 60% (the client's own art, so a game icon, not a glyph).
- **Hover:** the hover wash, the game's tooltip (`GameTooltip:SetInventoryItem`),
  and a 1px accent border while the cursor holds an item that fits the slot.
- **Upgrade:** Polestar's bag upgrade arrow (`qol-upgrade`, success, 18px)
  top-left when an item in the bags is an upgrade for this slot (Polestar's
  bag verdict, `Gear.Bags.IsUpgrade`, and the slot `Gear.CompareToEquipped`
  weighs it against); off with Polestar's bag arrows.
- **Durability:** under 25%, the border turns warning; broken, danger.
- **Press:** the icon nudges 1px, as an icon button's glyph.
- **Use:** right-click uses a worn item with a Use: effect (the tooltip hint
  says so); a click while an enchant, kit or stone waits applies it. Out of
  combat only: both are protected.

### Stat Row
28px; the label in Label textDim at 16, the value in Number text at the right
edge minus 12, a hairline between rows (Polestar's row panel). A value above its
base takes success, below it danger; the tooltip is the game's stat tooltip.

### Model Well
No border: shade (Polestar's `glow` texture at 60%) that fades out towards
its edges, holding the player's model; drag to turn, wheel to zoom. No band.

### Recipe Row
28px list row (Polestar's list row): a 16px icon at 24, the name in Body in its
difficulty colour (legible form: optimal, medium, easy, trivial), the number
craftable now in Number textMuted at the right. A long name (an enchant's)
takes a second line, never more, and the row grows to hold it. Selected: the selection wash and
the 2px accent bar.

### Reagent Tile
Polestar's reward tile, 32 tall and half the page wide: the icon 32px, the name
in Label (quality colour, legible), "3/4" (held/needed) in Number at the
right: text when enough, danger when not.

### Skill Bar
A 2px track wash with a fill (the accent for professions and skills, the standing
colour for reputation), the rank "145/150" in Number textDim above its right
end. Never thicker: it is Polestar's progress line.

### Subject Block
The sidebar's head in a game window: a 36px game icon on an inset well with a
hairline at the 24 edge, centred on the band's title line (y 47); the name in
Title 12px right of it, one Small textDim line under it. Never the Polestar
emblem or wordmark.

## Do's and Don'ts

### Do:
- **Do** build every window on `W.Shell` and its helpers; extend Polestar's kit
  only when Polestar has no widget for it.
- **Do** lift game colours (quality, difficulty, standing) with `Theme.Legible`
  before they carry text.
- **Do** keep the game's own tooltips for game things.
- **Do** open a replaced window from every stock door (The Same Doors Rule).
- **Do** add a preview scene and golden with every new surface.

### Don't:
- **Don't** add children, scripts or hooks to a Blizzard frame; hide it, never
  restyle it.
- **Don't** call a protected API from an insecure button; use a secure template.
- **Don't** hide a stock frame in combat; queue it.
- **Don't** copy Polestar's colour values; read them through `Polestar.Theme`.
- **Don't** put Polestar's emblem in a game window's sidebar; the subject block
  names the window.
- **Don't** ship a window that drops a stock feature without a way to it.
