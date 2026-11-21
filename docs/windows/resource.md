#### Personal Resource Display (`PersonalResourceDisplayFrame`) — Risk: medium

The game's own Personal Resource Display, restyled in place and never
rebuilt (`Modules/ResourceDisplay.lua`, key `resource`), in the HUD's look:
flat bars on a track, Polestar's window border as the edge (`H.PaintEdge`), the heal, absorb and cost segments as
our unit frames draw them, the bar text in Polestar's face. On Forever it is
a standalone frame on `UIParent` (not a nameplate), an Edit Mode system
(`EditModePersonalResourceDisplaySystemTemplate`), shown when the game rule
and `nameplateShowSelf` allow it or while Edit Mode shows it.

**Why restyled, not replaced.** It is an Edit Mode system (CLIENT.md, rule
17), and every one of its settings works by the game resizing, moving,
showing and hiding its own bars: Size (the frame's scale), Bar Width, Health
and Power Bar Height, Padding, Hide Health, Hide Power, Hide Alt Power, Hide
Class Info, Opacity, Visibility (Always, In Combat, Hidden). A bar of ours
would need the stock one hidden and would lose all of that. It is a plain
frame, not a secure unit button, so rule 16's veil does not apply.

**How.** Nothing of the frame or its parts is moved, sized, shown, hidden,
hooked or written. On each stock bar (`HealthBarsContainer.healthBar`,
`PowerBar`, `AlternatePowerBar`) we add textures of our own (kept in a weak
table): they are the bar's regions, so they follow its place, scale, alpha
and visibility by themselves, and draw over the game's fill by draw layer
(our fill `ARTWORK` 3, segments 4 to 6, hairline 7; the game's text stays
`OVERLAY`, above). No child frame of ours: the game's child frames (the
power animations, `TempMaxHealthLoss` at level 100) stay above ours.

**Parts** (`Blizzard_PersonalResourceDisplay.xml`):
| Stock part | Ours | How | Gotcha |
|---|---|---|---|
| A bar's fill (`SetStatusBarColor` on every update) | a flat fill (`H.FillTexture`) | `SetAllPoints` on the game's fill texture: it follows the value with nothing read (rule 3) | the game writes the fill's colour, alpha included, so it cannot be faded: ours covers it |
| The bar's unnamed BACKGROUND atlas (`UI-HUD-CoolDownManager-Bar-BG`) | faded; a track of ours, `bg` at `H.GroundAlpha()` | found once by `GetAtlas()`; `SetAlpha(0)` | |
| `myHealPrediction`, `otherHealPrediction` | the fill lightened 45%, at 0.7 (the unit frames' heal) | one texture of ours `SetAllPoints` on each; shown as the game's `IsShown()` says, each frame | the game places and sizes them (`CompactUnitFrameUtil_UpdateFillBar`); ours copies only the shown flag (`ns.Clean`: hidden if ever secret) |
| `totalAbsorb` (+ `totalAbsorbOverlay`) | `text` at 0.55 | pinned the same way | |
| `myHealAbsorb` (+ its two shadows) | `shade` at 0.55, over the fill's end | pinned the same way | |
| `overAbsorbGlow`, `overHealAbsorbGlow` | dropped (as our unit frames) | `SetAlpha(0)` | they reach past the bar's edges |
| `PowerBar.ManaCostPredictionBar` | the power colour mixed 55% toward `shade` (our player frame's cost look) | pinned; the game's fill there is power less cost, so ours sits where our player frame darkens | the game writes its vertex colour, alpha included, on a power change: every faded region is faded again each frame |
| `TextString`, `LeftText`, `RightText` (Show Bar Text) | the game's text in Polestar's `number` face, outlined | `H.Face` | never read (secret) |
| `PowerBar.FeedbackFrame`, `FullPowerFrame` | the game's | untouched | the user's choice: the builder and spender flash and the full-power pulse stay |
| `ClassFrameContainer` (Rogue and Druid combo points) | the game's | untouched | as on the player frame |
| `TempMaxHealthLoss` | the game's | untouched | |

**Colours.** Health: the header band's `sky`, or the class colour when Edit
Mode's Show Class Color is on (the game's own `showClassColor` flag on the
frame, read with `rawget`, never written) or Polestar's "Class colour" is on
(`H.FillColor`). Power: `H.PowerColor("player")`. The alt bar (always mana on
Forever: the Druid in forms): `npc`, as `H.PowerColor` paints mana. No combat
edge (the user's choice: the player frame shows it).

**Edit Mode.** Every setting is the game's; ours hangs on the bars and
follows: Size, Bar Width, the heights and padding, the Hide toggles (a hidden
bar hides ours), Opacity, Visibility, the preview Edit Mode shows. The
frame is turned on with Edit Mode's own "Personal Resource Display" checkbox.

**Combat.** Nothing is protected; no secure frame of ours. Each frame while
the display shows, our driver (`OnUpdate` on a frame of ours on `UIParent`)
repaints colours (`H.FillColor`, `H.PowerColor`: both guarded), copies the
prediction textures' shown flags and re-fades. No value, width, height or
min/max of a stock bar is read, in or out of combat.

**Switch:** `/pui resource on|off`, live: off gives back the bar art, the
prediction textures, the glows and the fonts and hides ours. No window, so
no "..." menu. Off by default with the gamepad UI.

**Tests:** `tests/lua/stub_resource.lua` (the frame, its three bars and their
regions as the XML builds them, the mixin's update and layout, the Edit Mode
setters; secret values; secret bar sizes in combat; the frame, its parts and
every region guarded). Scenes: `resource` (heals, an absorb, a cost),
`resource-editmode`, `resource-combat`, `resource-classcolour` (Edit Mode's
Show Class Color with a Druid's alt bar; Polestar's Class colour),
`resource-off`.

**Live checks (not in the preview):** that the frame shows on Forever (Edit
Mode's "Personal Resource Display" checkbox, `nameplateShowSelf`); that our
`ARTWORK` fill draws over the game's fill and under its builder/spender flash
(`FeedbackFrame` uses its parent's level: if its regions sort with the bar's
by layer, the flash is under our fill) and the full-power pulse; that a
hidden prediction texture leaves no stale segment; that the faded regions
stay faded (`ManaCostPredictionBar`'s colour is written on a power change);
`IsShown()` on the prediction textures in combat is a plain boolean;
`TempMaxHealthLoss` over ours; the combo points' place under our bars.
