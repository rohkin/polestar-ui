#### Nameplates (`NamePlateDriverFrame`, each plate's `UnitFrame`) — Risk: high

The game's own nameplates, restyled in place and never rebuilt
(`Modules/Nameplates.lua`, key `nameplates`), in the unit frames' look: a
health bar of our own over the game's (as wide as the plate's content, a
little taller than the game's bar) on the unit frames' ground (`H.Ground`:
track at the HUD's Background opacity, 1px hairline, glow), a flat fill in the
target frame's colour for the same unit (`H.UnitColor`), the level (in its
difficulty colour) and the name in the row above the bar, the health text
inside at the right; the target has no glow, the focus a flat
`warning` hairline, the other plates dimmed while there is a target; and the
cast bar as `Modules/CastBars.lua` draws the target's (`ns.CastLook`) over the
plate's cast area. Enemy and friendly plates both; forbidden ones never.

**Design.** The first pass kept the game's bar and put the level, the name
and the health text inside its 13 units, short of the level badge's gap: the
name was cut after a few letters. What the admired plate addons share (their
defaults, read from their sources) is a wide thin bar with the name outside
it:
- *Plater* (`Plater_DefaultSettings.lua`): a 112x12 bar (120x16 in combat),
  the name at 11 centred above it, the health % at 9 inside at the right, the
  level small and secondary, a 10-high cast bar right under at the bar's
  width, auras above the name, the target lit and the rest at 65% alpha.
  Taken: the name centred above the bar, a small % inside at the right, the
  others dimmed.
- *KuiNameplates* (`Kui_Nameplates_Core/config.lua`): 100x14, the target's
  128x16, names at 11, a soft glow as the frame's edge (8 round the target,
  in its colour), non-targets faded to 50%. Taken: the glow as the target's
  mark, in the unit's colour (it is the unit frames' edge already), a bar of
  16.
- *ElvUI* (`Defaults/Profile.lua`): 150x10, the name above at the left and
  the level above at the right in its difficulty colour, outlined 11, the
  cast bar 150x8 under it. Taken: the level in its difficulty colour beside
  the name, outside the bar; the bar as wide as the plate.
- *Threat Plates* (`Constants.lua`): 120x10 bar and cast bar, threat as a
  colour system of its own. Not taken: threat stays on the edge, as on our
  target frame (the fill is the unit's colour, the user's choice).
- *Platynator*: its source could not be fetched, so nothing is credited to
  it; from memory its default also has the name above and the % at the
  bar's right end (not checked).

Ours (Thin, the default style, at the Medium size; all of it times the
game's size scale):
- **Bar:** 166 x 16: the plate's content width (the game's bar stops 33
  short for its level badge; that room is the bar's now) and 3 taller than
  the game's 13 (2 up into the name's row, 1 down into the gap over the cast
  area). The unit frames' ground, hairline and flat fill; heals and absorbs
  as the unit frames' segments. The fill is inset by the hairline's own
  thickness (one physical pixel, read with it on each repaint), not by 1
  unit: the game scales plates with distance and selection, and a fixed
  1-unit inset beside a 1-pixel hairline left a strip of ground that
  flickered as a dark line under the fill.
- **Name row:** the level in its difficulty colour, then the name, one
  string at 11 in Polestar's face, outlined, centred, as wide as the whole
  plate (190): "54 Deadwood Shaman" fits; only a name past the plate's width
  is cut.
- **Health text:** the game's own option (percent, value, both, none) at 9
  inside the bar's right end. Nothing else is inside the bar.
- **Target:** no glow (the plain border; the dim of the others is the mark); focus a
  flat `warning` hairline; threat the threat glow. While there is a target,
  every other plate's bar is dimmed (35% of the ground colour over it), so
  the target reads first. No scaling: the plates' size is the game's.
- **Cast bar:** unchanged, the cast bars' look over the game's cast area (16
  high in Thin), 1 unit under the health bar, at the same width.
- **Auras:** the game's row above the name, square in a hairline, timers in
  the number face; their size stays the game's (Options > Nameplates, the
  aura size), see Sizing.
- **Styles with the name inside the bar** (Modern, Block: 20 high, no row
  above): the bar at the game's height and full width, the level and name
  inside at the left, cut at the health text, as on the unit frames.

**Sizing, within the rules.** Rule 20 forbids sizing or placing the game's
pooled frames, and nothing here does. What is sized is ours: one frame per
pooled `UnitFrame`, made with `Polestar.CreateFrameUnder` under the game's
`healthBar` (so it shows and hides with the game's bar: a name-only or
widget plate has none), anchored `TOPLEFT` to `HealthBarsContainer` and
`BOTTOMRIGHT` to `CastBarsContainer`'s top right (the plate's content
edge), with offsets of our own. It holds a StatusBar of ours fed with
`UnitHealth`/`UnitHealthMax` (secret, unread), so its size is free of the
game's bar. The game's bar stays where and as large as the game lays it
out, under ours, with every region of it faded by `SetAlpha` (rule 15); its
fill's alpha, which `SetStatusBarColor` writes again, is set to 0 again in
the post-hook on `CompactUnitFrame_UpdateHealthColor`, the only place the
game colours it (and the game's fill is never wider than ours, so even a
frame of it at alpha 1 is under our fill). Not done, and why: FlareUI
re-anchors `HealthBarsContainer` in a per-frame `UpdateAnchors` hook, which
moves a pooled stock frame and writes a hook key on it (rule 20); the
game's size and style options are the player's (no CVar is written); the
aura items are the game's pooled frames, filled by the game from auras
addon code cannot read in combat, so they can be neither sized nor redrawn
by us: their size is the game's aura size option.

**What Forever has** (`Blizzard_NamePlates`, Camelot overrides; options in
`Blizzard_SettingsDefinitions_Frame/Nameplates.lua`). The client makes a base
plate per unit in sight (`NamePlate1`..`n`, reused) and fires
`NAME_PLATE_UNIT_ADDED`; `NamePlateDriverFrame` gives it a `UnitFrame` from a
pool (`NamePlateUnitFrameTemplate`, built on CompactUnitFrame) and releases it
on `NAME_PLATE_UNIT_REMOVED`, so one `UnitFrame` serves many units in turn.
Friendly plates in instances are forbidden plates (`FORBIDDEN_NAME_PLATE_*`,
a pool of their own) that addon code never gets. A `UnitFrame` holds
`HealthBarsContainer.healthBar` (`barTexture`, `bgTexture`, `selectedBorder`,
`deselectedOverlay`, the health texts), `name`, `CastBarsContainer.castBar`
(important-cast and cast-target indicators, target name, shield), `AurasFrame`
(debuffs, buffs, crowd control, loss of control), `ClassificationFrame` (elite,
rare, PvP), `RaidTargetFrame`, `LevelFrame` (Camelot shows the level), the
aggro flare, `WidgetContainer` (widget-only plates), `SoftTargetFrame` and
private auras. Every option is a CVar the game itself follows:
`nameplateStyle` (Thin, the default; Modern, Block, Cast Focus),
`nameplateSize`, `nameplateInfoDisplay` (health %, value, rarity icon),
`nameplateCastBarDisplay` (name, icon, target, important casts, "targets
me"), `nameplateThreatDisplay` (progressive, flash, health colour), the three
aura bitfields and `nameplateDebuffPadding`/`nameplateAuraScale`, the show
CVars (`nameplateShowAll`, `nameplateShowEnemies`, minions,
`nameplateShowFriendlyPlayers`, `nameplateShowFriendlyNpcs`, name-only
friendly players, class colours, realm), simplified types and stacking
types. No quest marker on plates in stock: Polestar's own
`qol.nameplateIcons` (`Quests/Tooltips.lua`) finds the health bar and keeps
working. The Personal Resource Display is a frame of its own
([resource.md](resource.md)).

**Why restyled, not replaced** (CLIENT.md rules 3, 15, 20). The plate frames
are pooled, and the game's code (CompactUnitFrame, the driver) and other
addons write into them. A plate of our own would lose stock parity where the
client gives addons no way: auras are not handed to tainted code while they
are secret (rule 3: every fight), private auras and widget-only plates are
drawn only by the game, and the threat, tapped, class and selection logic,
important casts and the "targets me" flag would all be copies. ElvUI, Plater
and Platynator build their own plates on this client and still keep the
stock `AurasFrame` and `WidgetContainer` for that reason. Restyled, every
option above keeps working, because the game still drives it.

**How.** Ours is made once per pooled `UnitFrame` and kept in a weak table
keyed by it (no key on any stock frame), so a frame the pool hands to another
unit already wears it.
- *When:* our `NAME_PLATE_UNIT_ADDED` handler (the driver's runs first: its
  frame registered before any addon's) with `C_NamePlate.GetNamePlateForUnit`
  and the plate's `UnitFrame`; `NAME_PLATE_UNIT_REMOVED` drops the unit from
  our map (the frame is already released then: look it up by our own unit
  map, not the plate). Theme changes repaint every live plate
  (`C_NamePlate.GetNamePlates()`).
- *Health:* `UNIT_HEALTH`, `UNIT_MAXHEALTH`, `UNIT_HEAL_PREDICTION` and the two
  absorb events on our driver frame (filtered to `nameplate*` units) feed
  our bar and its segments; the text follows `nameplateInfoDisplay`.
- *No hook on a plate frame* (rule 20): not on the instance, not on the
  driver. The game's re-layout (`UpdateAnchors`: style, size, padding
  changes) sets atlases and font objects again; `SetAtlas` keeps a region's
  alpha, and ours hang on the game's regions by anchors, so they follow with
  no hook. The re-colour hangs on the global
  `hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ...)`, filtered to
  frames in our table (it runs for raid frames too).
- *Fallback, only if a live check finds a reset no event covers:* a post-hook
  on the mixin table (`NamePlateUnitFrameMixin`) set at load, which reaches
  every frame the pool makes after it (the mixin is copied in when a frame is
  made; plates are made after login).

**Parts:**
| Stock part | Ours | How | Gotcha |
|---|---|---|---|
| `healthBar` fill (`barTexture`), heal prediction and absorb regions | a StatusBar of ours (`H.Bar`) in our frame, in our colour, with the unit frames' segments (`H.Segment`: incoming heals, absorbs, heal absorbs, from the client's calculator, unread) | the game's regions faded with `SetAlpha`; ours fed with `UnitHealth`/`UnitHealthMax` on the health events | `SetStatusBarColor` writes the game's fill's alpha again: faded again in the colour hook. The segments need the bar's width as a number: read off our own bar out of combat only (the game's layout numbers until then) |
| `bgTexture` | the unit frames' ground on our frame: `H.Ground` (track `bg` at `H.GroundAlpha()`, hairline, glow), our bar 1 unit inside it | `SetAlpha(0)` on the game's (an atlas the game only swaps) | our frame is 2 units taller than the game's bar upward (the name row keeps 14 for our 11-high name) and reaches down to 1 unit over the cast area; in Modern and Block, the game's height |
| `selectedBorder`, `selectionHighlight`, `deselectedOverlay` | faded; the edge as the target frame paints its own (`H.PaintGround`): the target glows in its fill colour, the focus a flat `warning` hairline, a plate whose `displayThreatHealthBarColor` flag is set (the game's threat option) glows in `GetThreatStatusColor` at `H.THREAT_ALPHA` like the target frame's threat edge; else the border. A dim of ours (the ground colour at 35%) over the bar of every plate that is neither target nor focus, while there is a target (the game dims them always) | from `PLAYER_TARGET_CHANGED`/`PLAYER_FOCUS_CHANGED`, `UNIT_THREAT_*` and the colour hook, with `UnitIsUnit(unit, "target" / "focus")` (`ns.Clean`) and `UnitExists("target")` | |
| `PlayerLevelDiffFrame` (Camelot's level badge right of the bar: `playerLevelDiffIcon`, `playerLevelDiffText`, `selectedBorder`, `highLevelTexture`), `LevelFrame` (`LevelText`, `HighLevelTexture`) | faded; the level leads our name string, coloured as the target frame's (`levelColor`, a copy of UnitFrames.lua's: difficulty colour, gold friendly, "??" in the skull's red; `textDim` when it has none), left out while secret | `SetAlpha` on the regions (the game shows, hides and fills them); repainted after the global `CompactUnitFrame_UpdatePlayerLevelDiff` | the game still narrows its own bar by the badge's width; ours spans the plate's content, over the gap |
| `name` | faded while our bar shows; ours (11 times the size scale, `ns.NameFont`) in the row above the bar, centred, as wide as the plate (the bar plus the 12-unit insets); inside the bar at the left in Modern and Block | `UnitName(unit)` into ours unread (`SetFormattedText("%s%s", level prefix, name)`); after the global `CompactUnitFrame_UpdateName`; ours shows only where the game shows a name and a bar (a name-only or widget plate keeps the game's name) | the game still anchors its aura row on its own faded name: the row above the bar is 14 high plus the 2-unit gap |
| health texts | faded with the bar; ours (`H.Text` "number", 9 times the size scale) inside the bar's right end, as `nameplateInfoDisplay` asks: the percent (`UnitHealthPercent`), the value (`AbbreviateNumbers(UnitHealth)`), both, or none | on the health events and `CVAR_UPDATE` | the game also shows its text on mouse-over (`forceShow`): ours follows the option only |
| cast texts, the game's name where it shows (a name-only plate) | Polestar's face, the game's sizes and outline | `Theme.SetFace` on the roman member (`GetFontObjectForAlphabet("roman")`) of the game's font families `SystemFont_NamePlate`, `SystemFont_NamePlate_Outlined` (names: `label`), `SystemFont_NamePlateLevel`, `SystemFont_NamePlateCastBar`, given back off. The families' Cyrillic, Korean and Chinese members keep the client's faces, so names in any script draw (the font family path, as `ns.FontFamily`; `ns.NameFont` itself would hook the game's string, rule 15) | forbidden plates share these families and take the face too; that the client's roman member is live (a face set on it reaches the strings on the family): live check |
| `castBar` | as the target's cast bar, compact over the plate's whole cast area: art faded, our fill on the game's fill, the icon inside at the left, the name after it, the time at the right | `ns.CastLook.dress(bar, { height, inside = true, text })`, `paint`, `fail`, `undress` (`CastBars.lua`; `inside` is the plate's option): the height from the game's layout numbers, never read off the bar (Thin, Modern, Health Focus: the 6-high bar plus the 10-high icon row under it; Block, Cast Focus: 16; times `nameplateSize`'s vertical scale); the name and icon follow `nameplateCastBarDisplay` | our box covers the game's icon row: `CastTargetNameText` is faded and, while the game shows it, the caster's target (`UnitSpellTargetName`, unread) takes the time's place; a shield texture of ours (`nameplates-InterruptShield`) on our icon while `BorderShield:IsShown()` (through `ns.Clean`: secret, ours stays off and the `textMuted` fill marks it); `ImportantCastIndicator`, `CastTargetIndicator` stay the game's |
| `AurasFrame` items | square: the game's rounded mask swapped for ours, the icon cropped 8%, the unnamed overlay ring faded, a hairline, the stack count in Polestar's face (`H.Face`, the game's corner), the countdown (the Cooldown's own string, `GetCountdownFontString`, centred) in the number face at 11 on the 25-unit item (the target frame's 9 on 20) | widget calls on the game's items (no aura read), each item once (pooled) | the items' size is the game's (`AURA_ITEM_HEIGHT` 25 x Aura scale x `nameplateSize`): a pooled stock frame is never sized (rule 20) | `UNIT_AURA` reaches ours before the game's handler (its frames are made after ours): the plate is dressed on the next frame |
| `ClassificationFrame`, `RaidTargetFrame`, aggro flare, `WidgetContainer`, `SoftTargetFrame`, private auras | the game's | | game icons stay game icons (Two Families Rule); the aggro flare's alpha is animated by the game |

**Colours:** exactly the target frame's (`H.UnitColor(unit)`, read in the
re-colour hook, on target/focus/threat changes): dead, offline or tapped by
another `textMuted`; hostile (`UnitReaction` 1-3) `danger`; a neutral NPC
`warning`; anyone else `sky`, or the class colour with Polestar's "Class
colour". Threat never colours the fill (it was the cause of orange plates
beside a red target frame: the plate's own threat branch painted `warning`);
it shows on the edge, as on the target frame, while the game's own threat
option is on for the plate. Secret inputs fall through `ns.Clean` as on the
target frame (a secret reaction: `sky`); the game's bar colour is never read.

**Forbidden plates** (friendly plates in dungeons and raids): the client
never hands them to addon code (`GetNamePlateForUnit` and `GetNamePlates`
leave them out); they keep the game's look, but for the font face, which
comes from the shared font objects. A hard client limit.

**CVars.** Never written, by this module or any other of ours; the
nameplate options stay the game's (Options > Nameplates, and the V keys).
With the show CVars off the client makes no plates and ours draws nothing,
exactly as stock. No login hint (the user's choice). Polestar's own core
was said to toggle `nameplateShowEnemies` and restore it; a grep of
`../polestar` (`nameplateShow`, `SetCVar`) finds no such write at the
current checkout. Either way ours reads no CVar to decide what shows, so it
cannot interfere.

**Other plate addons.** FlareUI (installed on Forever, `Modules/Tweaks.lua`)
restyles `plate.UnitFrame` on this client too: per-instance
`hooksecurefunc(unitFrame, "UpdateAnchors")`, `pcall`-wrapped writes,
`canaccessvalue(unit)` checks, and it backs off when its
`GetNameplateAddon()` reports another plate addon. Two restylers on one frame
fight over the same regions, so ours starts off (the module's `defaultOff`,
as Bags beside Baganator; the player can still switch it on) while a known
plate addon is loaded: Plater, Platynator, KuiNameplates, Threat Plates,
EllesmereUI Nameplates, ElvUI with its nameplates on. FlareUI is not
detected: how to read its plate tweak's switch is still an open question
(a live check), so beside it both restyle the same plates.

**Combat and performance.** Nothing here is protected: widget calls on
regions of the game's and on frames and textures of ours, made in or out of
combat. Work happens only on `NAME_PLATE_UNIT_ADDED`, the colour hook, target
and focus changes, the plates' health and cast events (filtered to
`nameplate*` units) and theme changes; no `OnUpdate` per plate: one driver
frame paints only the cast bars that show (their time counts down) and the
plates whose auras changed. Ours is made once per pooled frame. No geometry
is read in combat (the segments' width is read off our own bar out of combat).

**Switch:** `/pui nameplates on|off`, live (not in combat): off gives back
every region's alpha, hides our frame and gives back the font objects' faces, on
every live plate. Nothing persists (no CVar, no key), so off is stock exactly.
No window, so no "..." menu. Off by default with the gamepad UI.

**Tests** (`tests/lua/stub_nameplates.lua`): the driver, the pool (frames
reused across units; the mixin copied in when a frame is made), base plates
`NamePlate1..n`, forbidden plates, the template's parts, the game's
`UpdateAnchors` (atlases and font objects set again; `stub.anchorRuns`) and
the global `CompactUnitFrame_UpdateHealthColor` (the game's colours, its
skip of an unchanged colour, the fill's alpha written back), bitfield CVars,
the show CVars, secret identities (the unit API and the bar's colour answer
secret), casts. Guards: a key written, a hook, a move, size, show, hide,
reparent or script on any stock plate frame or region errors from our code;
textures take only `SetAlpha` (and mask calls on an aura icon); strings only `SetAlpha` (an aura's count its face); a forbidden plate errors
on any use; aura reads of a plate while secret, `SetNamePlateSize` and every
`SetCVar` of ours are caught. Scenes (with the module): `nameplates` (an
elite enemy, a rare, a neutral, a friendly NPC, the target and focus, health %:
our bar on the game's containers over the level badge's gap, 2 units over
the game's bar; fill equals `H.UnitColor` for the unit and takes the secret
health; level and name in the row above, the plate's width; the game's fill,
texts, badge and name faded, the fill still faded after the game colours it
again; the target plain, the others dimmed, none without a target; Modern:
the name inside),
`nameplates-cast` (Thin's and Cast Focus's bars, shielded, important, the caster's target, an interrupt),
`nameplates-auras` (countdown face and size, in combat too: drawn, nothing read), `nameplates-pool`
(a frame reused for another unit, no second set of ours, the new unit's health),
`nameplates-colours` (threat on the edge not the fill, tapped, a secret
identity: the target frame's fallback, no level read), `nameplates-forbidden` (never touched),
`nameplates-combat` (a plate added and hurt mid-fight), `nameplates-cvars-off` (no
plates, no CVar written), `nameplates-off` (everything back, live: its golden is the stock plate).
The preview resolves sizes from anchors only when it draws, so the scenes
check ours by its anchors and offsets; the picture itself is the golden.

**Live checks (not in the preview):** that `NamePlateN.UnitFrame` is set when
our `NAME_PLATE_UNIT_ADDED` handler runs; that the game's fill never shows
under or beside ours (its alpha after `SetStatusBarColor`, a smoothed bar);
that faded regions stay faded through a style and size change; that our bar
ends at the plate's right edge, level with the cast bar, and 1 unit over it;
that the name row clears the aura row above it at every size (the game's row
is 14 high, ours 11) and the game's Debuff padding; that the dim reads right
on the other plates with a target; that heals and absorbs on a friendly
plate end at the right place (the segments' width); the Classic and Legacy
styles (their bar is inset in the container: ours spans the container); that
the roman member of `SystemFont_NamePlate_Outlined` takes Polestar's face and
that Cyrillic and Chinese names still draw in the client's faces (our name:
`ns.NameFont`); the cast bar over Thin's cast area (bar and icon row) and
inside Cast Focus's; how FlareUI's plate tweak is switched (with its Hide
Level Box on, it moves the game's bar; ours follows the containers either
way); a plate whose identity is secret (a PvP match, an encounter) in the
target frame's fallback colour; that the game's name and level badge stay
faded through name, faction and level updates (the two global hooks) and
that a name-only plate keeps the game's name; whether `BorderShield:IsShown()`
and `UnitSpellTargetName` come back secret for an enemy cast (then our shield
and target name stay off); the aura countdown's size after the client sets
it (`SetCountdownFont`).
