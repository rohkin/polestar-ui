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
- Every stock window becomes a compact `W.Shell`: the starlit band carries
  the page's title and its subject, the stock window's tabs are its tabs (or a
  slim rail of their icons), no sidebar.
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
   **Except** the tooltips and the chat: other addons write into the stock
   ones, so they are restyled in place (Tooltips and Chat, below; CLIENT.md,
   rule 15).
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
3. **Off is off, and live.** Each window is Polestar's or the game's, saved per
   window (`PolestarUIDB.modules`, on by default) and switched by
   `/pui <window> on|off` (bare `/pui` lists them), the "Use game window" entry
   of the window's own menu (the "..." left of ✕, Polestar's `W.ShowMenu`), or a
   small "Polestar" button of ours above the stock window's top right corner
   while that one is in use (`ns.Switch` in Core.lua). The switch is live: off,
   ours closes and its doors step aside (`ns.Doors` binds and overlays only a
   module that is on; Character's toggle hook stays and does nothing); on, they
   come back. Never in combat (override bindings and secure buttons cannot
   change then): it is refused with a message. Crafting alone goes off only
   after `/reload`: its stock routing, routed again from our code, would open
   the stock window tainted. The stock-side button reads the stock frame
   (shown, rect, strata) and nothing else: it hangs on UIParent, placed by
   position, never anchored to it (CLIENT.md, rule 10).
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

Every stock window becomes one `W.Shell(name, opts)` on the **compact grid**
(`ns.Compact`, Core.lua): the band 0–60 (the title in Display, its subtitle
one line under it), the tab row 60–96 (36; the skin's when smaller), the
hairline under it, the 44px footer, a 24 pad (the skin's less 8; content is
laid out by `f.psPad`). Polestar's own grid (112 band, 40 tabs, 56 footer,
32 pad) is for Polestar's windows; ours were too big on it. The band's art is
cropped to 60, never stretched; the close button, "..." menu and scale sit on
the band's middle (the game's looks put the close button on the frame's
corner).

- **Size.** The smallest that fits the content at the compact grid: no
  sidebar, a width that fits (Talents 780×650, Spellbook 720×600, Merchant 640×560, Trainer 560×560, Social 580×560, Bank 560×560, Macros 640×560, Mail 560×560), height
  600 or so at most so it never covers the guide window at default scale.
- **Page nav (no sidebar).** Where the stock window has **text tabs** (top or
  bottom: Talents, Spellbook, Character, Inspect, Social, Bank, Macros, Mail,
  Merchant, Trainer), its pages are top tabs (`ns.TopNav`): `W.ShellTabs`
  keeping each page's state (active, a count, a warning dot, locked with its
  tooltip), with the stock tab's icon before the label where it has one; the
  search (and its filter) moves to the tab row's right end. Where the stock
  window has **icon side-tabs** (Guild, Professions and Crafting, Legacy), a
  slim 48px rail of those icons only (`ns.GameRail(..., { slim = true })`),
  each label in its tooltip, from the band's line down. A page's own views
  are the tab row then.
- **Header.** The band holds the page title, a short status subtitle in Note
  textDim; nothing else. The subject (the character's level and class, the
  NPC, the profession) leads the subtitle ("Level 24 Mage · 7 spells."),
  never a sidebar block. The window's settings live in its "..."
  menu (`ns.WindowMenu(f, key, options)`), first, then a divider and "Use
  game window". The subtitle is a fact about the page now ("2 items need
  repair", "Watching Stormwind", "3 currencies", "4 of 9 friends online"),
  never an instruction. Hints go in tooltips: anything that can be clicked or
  dragged in a way a newer player would not guess ends its tooltip with a
  hint in textMuted after a blank line (`ns.TooltipHint`), saying what it
  does now ("Shown on your experience bar. Click to stop.", "Drag an item
  here to equip it."). Filters are a sliders icon button after the search
  (`W.IconButton(..., "sliders")` on the editbox skin), its glyph lit while
  a filter is on.
- **Older windows** still on the sidebar shell (a subject block, nav rows,
  Polestar's grid) move to the compact grid and the rule above one by one.
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

**The Stock First Rule.** A replacement implements everything the stock window
has before any improvement; a missing stock feature is a bug. Only what the
client forbids addon code is left to the stock window, and the window's doc
says why.

## Element Catalogue

Ordered by build increment. Each entry: what it becomes, its layout, and its
Risk. Sizes are UI units at scale 1, on the shell grid.

### 1. Windows

| Window | Risk | Status | Entry |
|---|---|---|---|
| Character (`CharacterFrame`) | medium | built | [windows/character.md](windows/character.md) |
| Spellbook (`PlayerSpellsFrame`, its spellbook tab) | high | built | [windows/spellbook.md](windows/spellbook.md) |
| Talents (`PlayerSpellsFrame`, its talents tab) | high | built | [windows/talents.md](windows/talents.md) |
| Professions book (`ProfessionsFrame`, its book page) | high | built | [windows/professions.md](windows/professions.md) |
| Professions (`ProfessionsFrame`) | medium | built | [windows/crafting.md](windows/crafting.md) |
| Legacy (`LegacySystemFrame`, Blizzard_LegacySystem) | high | built | [windows/legacy.md](windows/legacy.md) |
| World Map and Quest Log (`WorldMapFrame`, `QuestMapFrame`) | medium | built | [windows/worldmap.md](windows/worldmap.md) |
| Social (`FriendsFrame`) | medium | built | [windows/social.md](windows/social.md) |
| Guild (`CommunitiesFrame`) | medium | built | [windows/guild.md](windows/guild.md) |
| Merchant (`MerchantFrame`) | medium | built | [windows/merchant.md](windows/merchant.md) |
| Bank (`BankFrame`) | medium | built | [windows/bank.md](windows/bank.md) |
| Mail (`MailFrame`, `OpenMailFrame`) | low | built | [windows/mail.md](windows/mail.md) |
| Auction House (`AuctionHouseFrame`) | medium | built | [windows/auction.md](windows/auction.md) |
| Trainer (`ClassTrainerFrame`) | medium | built | [windows/trainer.md](windows/trainer.md) |
| Gossip (`GossipFrame`) | medium | built | [windows/gossip.md](windows/gossip.md) |
| Quest dialog (`QuestFrame`) | medium | built | [windows/questdialog.md](windows/questdialog.md) |
| Loot (`LootFrame`) | high | built | [windows/loot.md](windows/loot.md) |
| Macros (`MacroFrame`, Blizzard_MacroUI) | medium | built | [windows/macros.md](windows/macros.md) |
| Inspect (`InspectFrame`) | medium | built | [windows/inspect.md](windows/inspect.md) |
| Game menu (`GameMenuFrame`) | high | dropped | [windows/gamemenu.md](windows/gamemenu.md) |
| Tooltips (`GameTooltip` and the stock tooltips) | low | built | [windows/tooltips.md](windows/tooltips.md) |
| Chat (`ChatFrame1`..`ChatFrameN`, the whisper windows) | medium | built | [windows/chat.md](windows/chat.md) |

The World Map and Quest Log share one entry (`worldmap.md`, also the quest log's). Each
new window gets its own file in `docs/windows/` and a row here.


#### NPC windows: how they open
Merchant, Bank, Mail, Auction and Trainer are NPC interactions. The game
opens each through the interaction manager
(`PLAYER_INTERACTION_MANAGER_FRAME_SHOW`, `RegisterPlayerInteraction` in
`PlayerInteractionFrameManager.lua`), and the stock window ends the
interaction as it hides (`CloseMerchant`, `C_Bank.CloseBankFrame`,
`CloseMail`, `C_AuctionHouse.CloseAuctionHouse`, `CloseTrainer` in its
`OnHide`). So, as the crafting window (CLIENT.md, rule 11), the stock window
is never opened: ours registers itself for the interaction type
(`RegisterPlayerInteraction(type, { frame = "PolestarUI<Name>", showFunc,
hideFunc })`, the manager's own API, which replaces the stock entry), and
where Forever also routes the open through `GameEvent` (`TRAINER_SHOW`,
`AUCTION_HOUSE_SHOW`/`CLOSED`) that route is stopped
(`GameEvent.UnregisterInternalEvent`). Ours opens the bags as the stock
`OnShow` did (`OpenAllBags`), closes them as it hides, and ends the
interaction when the player closes it (`C_PlayerInteractionManager.ClearInteraction`
or the stock close call), never twice when the game ended it. Off waits for
`/reload` (`reloadOff`): routed back from our code, the stock window would open
tainted. One helper does this for all five (`ns.Interaction`, Core.lua).
Doors only the stock code knows: none; the NPC is the only door. Gossip,
the quest dialog and loot open on events their own frames register
(below): each says how.

#### Later windows
StaticPopup is never replaced or restyled: it is shared with the secure
dialogs; only our own windows call `W.Modal`.

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

Unit frames replace the stock ones, which stay as Edit Mode's proxies, only
veiled (CLIENT.md, rule 16). The other built HUD pieces are restyled in place
(rule 17: Edit Mode places them, so nothing of theirs is moved, scaled or
hidden):

| HUD element | Risk | Status | Entry |
|---|---|---|---|
| Unit frames: player, target, target of target, focus, focus's target, pet, party, bosses (`PlayerFrame`, `TargetFrame`, `FocusFrame`, their `ToT`, `PetFrame`, `PartyFrame`, `BossTargetFrameContainer`) | high | building (phases 1-3; compact raid next) | [windows/unitframes.md](windows/unitframes.md) |
| Minimap (`MinimapCluster`, `Minimap`) | high | built | [windows/minimap.md](windows/minimap.md) |
| Action bars (`MainActionBar`, `MultiBar*`, pet, stance, possess) | high | built | [windows/actionbars.md](windows/actionbars.md) |
| Player buffs and debuffs (`BuffFrame`, `DebuffFrame`) | medium | built, with the target's and focus's rows under our unit frames | [windows/auras.md](windows/auras.md) |
| Cast bars: player, target, focus (`PlayerCastingBarFrame`, `TargetFrameSpellBar`, `FocusFrameSpellBar`) | high | built | [windows/castbars.md](windows/castbars.md) |

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
