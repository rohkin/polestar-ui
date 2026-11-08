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
  class. Tabs: Gear, Stats.
  - *Gear*: two slot columns on the 32 and right edges (Head, Neck, Shoulder,
    Back, Chest, Shirt, Tabard, Wrist; Hands, Waist, Legs, Feet, Finger ×2,
    Trinket ×2), weapons in a row under the model, the model well between the
    columns. Slot tiles 36px, 6px apart. Beside each column's
    slot, on the inside (over the model well): the item's name in Label in its
    quality colour, its stats ("+12 Sta  +8 Str": short names on this screen only, armor left out) in
    Small textDim under it, 220px wide; empty, the slot's name in textMuted.
    Painted out of combat only. Under the weapons, a 40px panel of primary stats:
    cells spread evenly, the value in Number over its name in Small textDim,
    hairlines between, filled and guarded as the Stats tab's rows.
  - *Stats*: stat panels in Polestar's settings layout, flowed into two
    columns 24px apart (each section into the shorter one, so the page rarely
    scrolls): a Heading per stock category (`PAPERDOLL_STATCATEGORIES`) over a
    panel of 28px stat rows. Numbers, the stats a character shows and their
    tooltips are the stock sheet's own: each row is filled by
    `PAPERDOLL_STATINFO[stat].updateFunc`, so the client's colours for buffed
    and debuffed values stay. The item level (from level 10) joins the page
    subtitle ("Level 31 Troll Warlock · Item level 42"), not a section of one row.
  - *Archetype*: one menu (Polestar's) at the right of the tab row, the same
    on Gear and Stats, per character (`PolestarUICharDB.archetype`; until
    chosen, hunters Ranged, casters by class Caster, the rest Melee). On
    Stats it highlights in place: the archetype's key stats read in text,
    every other row in textMuted, and the sections and rows keep the stock
    order, so switching never moves anything. Never the accent: these are
    numbers, and the archetype is a view, not an action. Under the gear it
    picks the primary stats. From Forever's stats (Classic's, with one Hit and
    one Crit; Defense 440 makes a tank uncrittable):
    Melee: Strength, Agility, Attack Power, Crit, Hit. Ranged: Agility, Ranged
    AP, Ranged damage, Crit, Hit. Caster: Intellect, Spell Power, Crit, Hit,
    Spell Penetration. Healer: Intellect, Spirit, Healing, Crit, Mana regen.
    Tank: Health, Armor, Defense, Dodge, Parry, Block (where the stock sheet
    shows it).
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

#### Professions book (`ProfessionsBookFrame`) — Risk: medium
`TOGGLEPROFESSIONBOOK` → `ToggleProfessionsBook()`.
- **Shell:** plain, 560×520. One card per known profession (primary first, then
  secondary): the profession's icon (40px), name in Title, rank in Number with
  its skill bar, and its spells as Default buttons ("Open Blacksmithing",
  "Smelting"). These are spell casts, so the buttons are
  `SecureActionButtonTemplate` with `type=spell` (protected: set out of combat).
  The unlearn action is an action tile in danger, confirmed by `W.Modal`.

#### Professions (`ProfessionsFrame`) — Risk: medium
Opened by the game when a profession is cast (`TRADE_SKILL_SHOW`).
- **Shell:** 960×680 with sidebar.
- **Subject block:** the profession's icon, name in Title, rank in Number with
  its 2px skill bar.
- **Sidebar:** the search (shell's own), then the recipe categories as nav rows
  with counts; "Can make now" and "Recent" first.
- **Main column:** title the selected recipe, subtitle its category. Tabs:
  Recipe, (later) Orders.
  - *Recipe page:* the product as a 40px tile with its name in its quality colour
    (legible), the reagents as reagent tiles (two columns, 8px apart), the
    tools/requirements line in Note (warning while missing).
  - *Recipe list* lives in the sidebar under its category, one recipe row each.
- **Footer:** quantity stepper (−, a 48px copy-box field, +, "Max") on the left,
  "Craft all" (default) and "Craft" (primary) on the right.
  `C_TradeSkillUI.CraftRecipe` is called from our button's click; verify in
  `.ref` that it is not protected on Forever before relying on it.

#### Later windows
Each gets its entry before it is built. Planned order and Risk:
Spellbook and Talents (`PlayerSpellsFrame`, high: spell buttons are secure),
Quest log (medium), Social (low), Merchant (medium), Bank (medium), Mail (low),
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
- **Upgrade:** Polestar's bag upgrade arrow (`qol-upgrade`) when Polestar's gear
  advice says so, top-left as everywhere else.
- **Durability:** under 25%, the border turns warning; broken, danger.
- **Press:** the icon nudges 1px, as an icon button's glyph.

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
craftable now in Number textMuted at the right. Selected: the selection wash and
the 2px accent bar.

### Reagent Tile
Polestar's reward tile (200×32): the icon 32px, the name in Label (quality
colour, legible), "3/4" in Number at the right: text when enough, danger when not.

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
