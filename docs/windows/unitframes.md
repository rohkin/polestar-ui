#### Unit frames (`PlayerFrame`, `TargetFrame`, `FocusFrame`, their `ToT`, `PetFrame`, `PartyFrame`, `Boss1TargetFrame`..`Boss5TargetFrame`) — Risk: high

The first HUD element. Phase 1: the player, target, target of target, focus
and focus's target; phases 2 and 3: the pet, the party (four members) and the
bosses (five), in Polestar's look, after EllesmereUI's (flat bars, a
square portrait, the name over the bars). Ours are secure unit buttons of our
own (`Modules/UnitFrames.lua`), built from the HUD kit (`Modules/HUD.lua`);
the stock frames stay, as the game's Edit Mode proxies (docs/CLIENT.md,
rule 16). Compact party and raid frames are restyled in place (a later
phase); the party members' pets stay the game's until then.

**Why replaced, not restyled.** Restyling in place (rule 15) cannot move or
resize anything, so the stock layout (round portraits, bars where the
stock art puts them) would stay. The user chose our own frames and gave
leave for rule 16: the stock frame is kept and only veiled.

**Layout.** Each frame takes the width and scale of the stock frame's Edit
Mode box (`Selection`); a slimmer one is centred in it:
- **Player, target, focus (slim):** 192 x 40 centred in the 192 x 66 box
  (Frame Size 100%). 1 in (inside the hairline): the portrait square (the
  frame's height less the hairlines, no hairline of its own) on the outer
  side (left for the player, right for target and focus, mirroring the
  stock), 1 apart from the health bar, which fills the rest over a 4-unit
  power strip under a 1px `border` hairline. On the health bar: the name
  (Label, text) 4 in from its left, for target and focus after a level chip
  (Small, textDim; the player shows none): the level with the rank as a
  suffix, "25", "25+" elite, "25R" rare, "25R+" rare elite, "??" for an
  unknown level (a world boss shows only "??", the stock skull's
  convention, no letter), and the value at the far end (Number, text). The name ends
  where the value starts.
- **Target of target:** one 20-unit bar centred in the stock one's 120 x 49,
  its name on it (Label); no portrait, power or value.
- **Party member (block):** its stock frame's 120 x 53, no portrait: the
  health fill full height over a 6-unit power strip (the hairline between;
  thicker than the slim frames' 4, to read at a glance; every member's, as
  the stock party frame shows every member's mana bar),
  the name top left (Small, text, 3 in), the percent bottom right (Small,
  textDim). The group role top right, in the game's own icon
  (`roleicon-tiny-tank`, `-healer`, `-dps`, 12 units, 5 in: exactly where
  the stock member frame has its `RoleIcon`, so the game's, under ours, never
  shows beside it), from `UnitGroupRolesAssigned` through `ns.Clean` (none
  with no role or while secret), on `GROUP_ROSTER_UPDATE` and
  `PLAYER_ROLES_ASSIGNED`; the name ends before it. The fill is the member's
  class colour whatever Polestar's "Class colour" says
  (`H.UnitColor(unit, true)`; the default fill while the class is secret).
  The game's other icons stay. The player's own role icon stays the game's
  (the stock player frame shows it only inside instances).
- **Pet (slim, smaller):** the player's slim look (bare portrait 1 in, the
  name and value on the health bar, a 4-unit power strip under a hairline,
  the same ground, edge and threat glow) at 24 units, centred in the pet's
  box (112 x 40): its portrait 22, about 0.6 of the player's, as the stock
  pet portrait (37) is of the player's. Name and value Small; the value is
  the percent whatever `statusTextDisplay` asks, so the name keeps its room
  on the narrow bar.
- **Bosses (unchanged):** a boss its stock
  frame's body (192 x 66 at the bosses' small scale, 0.75): 2 in, a line with
  level, rank and name, the health bar with its
  text, a power bar with its value centred. Bosses have no portrait, as the
  stock ones have none.

All text is outlined with a hard shadow, as on the transparent guide window
(HUD rule). At 192 wide, with the value showing (Status Text always on,
"Both": "12.4K | 62%") and a level chip, a target's name has about 45
units (Label): "Hogger" or "Kurzen" fit, "Defias Thug" does not and ends in
an ellipsis in the client. With the value on mouse-over (the game's
default) the name has the bar. The bosses' line keeps the rank
words.

**Colours** (from the player's Polestar theme, never fixed):
- Ground: the scheme's `bg` at the player's "Background opacity" (60%), a 1px
  `border` hairline. The bars' tracks are `bg` at the same opacity over it,
  so missing health reads dark. The hairline turns `danger` round the player's frame in
  combat, and takes the game's threat colours (`GetThreatStatusColor`) round
  a unit the player has threat on, with a glow: four gradient strips and four rounded corners (`H.GLOW` = 8 px, 0.455 alpha at the
  frame, the hairline 0.65 (`H.GLOW_PEAK` 0.7 x `H.THREAT_ALPHA` 0.65), clear at the far edge) drawn outside the frame as textures, so the frame's size and Edit Mode
  rect do not change; each corner is a quarter disc of 8 one-pixel rows (horizontal gradients, no overlap). The player's own combat edge has no glow.
- Level chip colour as stock's `TargetFrameMixin:CheckLevel` (TargetFrame.lua:283): on an attackable unit the difficulty colour
  (`C_PlayerInfo.GetContentDifficultyCreatureForPlayer` through `GetDifficultyColor`: grey, green, yellow, orange, red), gold
  (1, 0.82, 0) on a friendly one, `QuestDifficultyColors.impossible` red on "??" (stock shows an untinted skull); a secret level
  keeps `textDim`. Stock's colours are fixed, so they do not follow the scheme.
- Health: the `sky` token (the header band's blue, under its stars; follows every scheme); with Polestar's "Class colour" on (`ui.classAccent`,
  Theme.FollowsClassAccent), a player in their class colour. An enemy in
  `danger`, a neutral creature in `warning`, a dead, offline or tapped unit
  in `textMuted`. Incoming heals continue the fill in its own colour, 45%
  toward white at 70%; shields (absorbs) after them in `text` at 55%; heal
  absorbs eat into the fill from its end in `shade` at 55% (the fill
  darkened). End glows, as stock's (`OverAbsorbGlow`,
  `OverHealAbsorbGlow`): shields past the missing health light a 2-unit
  strip inside the health bar's right end in `text`, heal absorbs past the
  health one inside its left end in `danger` (stock's 16-unit additive glow
  overhangs the bar's end; ours stay inside it). The client's secret
  "clamped" flags go straight into `SetAlphaFromBoolean`; a client without it
  shows none.
- Sparkle (the "Sparkle" setting, on): Polestar's night-sky stars
  (`Theme.Media("band-stars")`) on the player frame only: the whole constellation (band x 655-945, y 12-76) at the bar's right end, filling its full height, unstretched (cropped from its left if the bar is narrower), its left quarter a second texture fading to clear (`SetGradient`), static, in the `star` token with its alpha (Halo and Hearth have none on their band, so
  none here).
- Smooth bars (the "Smooth bars" setting, on): health and power glide to a
  new value (`SetValue(v, Enum.StatusBarInterpolation.ExponentialEaseOut)`,
  the client's own easing, which takes secrets); a new unit in a frame
  (target, focus, roster, pet, vehicle changes) and the targets of target
  snap. Everything hanging off a fill rides along.
- Damage trail (the "Damage trail" setting, on): health just lost stays in
  `danger` for a moment, then drains to the new value. A second StatusBar
  (`bar.trail`, under the health bar) is given the same secret health 0.4 s
  later and eased (`ExponentialEaseOut`; no interpolation: it jumps). It is
  drawn only past the new health: a clip frame anchored to the fill edge of an
  unseen bar (`trail.psAim`, holding the track) that takes the health at once,
  one maximum for all three (`H.SetTrail(..., max)`). On a loss the fill drops
  and the trail shows the lost chunk; on a gain its end is below the new
  health, so no red shows ahead of a fill easing up (Smooth bars: before the
  clip, a heal right after a hit showed a red sliver at the bar's right end
  until the fill caught up). No value is compared or subtracted, so it
  works in combat the same as out. A new unit in a frame snaps it. Stock's
  `AnimatedHealthLossMixin` (player frame) does the maths on health, which
  addon code cannot in combat.
- Power cost (the player's frame): while the player casts, the spell's cost
  in the bar's power (`C_Spell.GetSpellPowerCost` on `UNIT_SPELLCAST_START`)
  eats into the power fill from its end in `shade` at 55% (darkened: the
  power colours are light), cleared when the
  cast stops, fails, is interrupted or succeeds unless another cast still
  runs (`UnitCastingInfo`), as stock's `UnitFrameManaCostPredictionBars_Update`.
- Power (`H.PowerColor`): a Polestar token per power type, near the game's
  hue, so the strip follows every scheme and sits calmly by the health fill:
  mana `npc` (a soft blue, clear of the health's `sky`), rage `danger`,
  energy `warning`, focus `place` (warm), runic power and maelstrom `spell`
  (ice), insanity and fury `dungeon` (violet), lunar power `item`, pain
  `achievement`. Any other type (or a token the scheme lacks) wears the
  game's own colour (`PowerBarColor`) mixed halfway to `textMuted`.
- Skins: the game skins (Hearth, WoW Forever, Blizzard, Classic) wear the
  game's bar fill (`UI-StatusBar`), the house skins a flat one; grounds,
  hairlines, wells and text follow each skin's palette.

**Edit Mode** (the only way to move them; the settings page says so). Ours
sit on the stock frame's `Selection` box: read (GetLeft, GetTop, size,
effective scale), never anchored (rule 10). Placed on login, on
`EDIT_MODE_LAYOUTS_UPDATED` (a layout switched or reset, next frame), every
frame while Edit Mode is open (the player drags the stock box; ours move with
it, the box drawn over ours), as Edit Mode closes, and the next frame after
the player's `UNIT_PET` or vehicle swap (the game lays the pet frame out in
its managed container). A stock frame with no points (the pet frame before
its first pet, or between that container's `ClearAllPoints` and `Layout`)
is never read: it would read as its parent's corner, the screen's top left,
so ours stay where they were. Frame Size is the stock
frame's scale and Opacity its alpha: ours copy both. Per-layout positions are
Edit Mode's own. While open, Edit Mode's "Target and Focus" option targets
and focuses the player, so ours show there too. In combat a move waits for
`PLAYER_REGEN_ENABLED` (protected). The targets of target follow the stock
ones, which hang off the target and focus frames. A party member or boss sits
on its own stock frame, which the game lays out in its system (`PartyFrame`,
a VerticalLayoutFrame, `spacing` 10 or 26 with party pets;
`BossTargetFrameContainer`, 10 apart); one the game has not shown yet stands
where the system will stack it (its top left, index by index), and keeps the
last rect it was shown at. While Edit Mode is open with no unit there, the
game shows the pet frame, the bosses (`isInEditMode`) and the party (its
"Party Frames" option, `ArePartyFramesForcedShown`) with stand-ins: ours
stand in with the player too, and go back to their units as it closes.

**Stock parity.**
| Stock | Ours |
|---|---|
| Health and power bars, values | ours, from the client's secret values (StatusBar, SetFormattedText, AbbreviateNumbers, UnitHealthPercent) |
| Status text: `statusText` (always or on mouse-over), `statusTextDisplay` (NUMERIC, PERCENT, BOTH, NONE) | the same CVars: NUMERIC "12.4K / 20.0K", PERCENT "62%", BOTH "12.4K \| 62%" (SetFormattedText, the pipe escaped); NONE (the game's default, with `statusText` 0) is NUMERIC on mouse-over, as stock; a party block always shows its percent. Power text follows them too, off by default (the "Power text" setting): PERCENT "65%", BOTH "2600 | 65%"\| 65%" (`UnitPowerPercent` on `CurveConstants.ScaleTo100`, secret-safe), else the value |
| Dead, Ghost, Offline | the health text says so; bar in textMuted |
| Name, level, `??`, elite/rare/boss dragon | name, level, rank word; the stock skull also shows (Contextual layer) |
| Portrait | square 3D model (2D game portrait while the unit is out of sight); the setting turns it off. The model loads only for another unit (its GUID; while that is secret, on the events that change the unit), its portrait camera set before `SetUnit` and again on `OnModelLoaded`, kept at alpha 0 until then (a quarter second at most), so the unframed model never shows |
| Heal prediction, absorbs, heal absorbs | the client's calculator (`CreateUnitHealPredictionCalculator`, `UnitGetDetailedHealPrediction`): incoming heals up to the missing health, shields up to what is still missing after them, heal absorbs up to the health, netted against the heals (stock's maths, done by the client on secrets); the over-absorb and over-heal-absorb end glows from its clamped flags. Without the calculator: the plain totals |
| Mana cost prediction (player) | the cast's cost eating into the power fill (above) |
| Threat (glow), combat flash | the hairline's colour; the threat glow is gradient strips outside the frame |
| Numeric threat, leader, guide, PvP/prestige, raid target, quest, pet battle, role, ready check, rest, group, play time, ping icons; the bosses' auras | the game's own, still drawn by the stock frame's Contextual layer where the stock puts them |
| Target and focus auras | a row of ours under our target and focus frames, the game's container veiled ([auras.md](auras.md); rule 16's exception) |
| Cast bars (target, focus, player) | the game's own, restyled in place where the game puts them ([castbars.md](castbars.md)) |
| Combo points, totems, pet frame, alternate power | the game's own (they hang off the stock frames, which stay) |
| Left click targets, right click opens the unit menu, click casting, pings | secure attributes (`target`, `togglemenu`), SecureUnitButtonTemplate, PingableUnitFrameTemplate |
| Tooltip on hover | GameTooltip:SetUnit |
| Vehicle swap | the player frame shows the vehicle; clicks follow `toggleForVehicle` |
| Target of target: the `showTargetOfTarget` option; hidden with no unit or a dead target | the same CVar; a state driver `[@targettarget,noexists][@target,dead] hide; show` |
| Pet: shown with a pet, the player in a vehicle; happiness; attack mode; pet cast bar | unit watch on `pet`, `toggleForVehicle` (shows the player); the game's happiness icon and pet cast bar (`PetCastingBarFrame`, its own frame) stay; attack mode's red pulse is veiled (our edge does not show it) |
| Party: shown in a group, not in a raid, not with Raid-Style Party Frames; offline, dead; out of phase or in another group (faded to 0.6); leader, guide, role, PvP, ready check, summon, phasing icons; auras; party pets | a state driver `[group:raid] hide; [@partyN,exists] show; hide`, standing down with Raid-Style Party Frames; the texts; the stock member's alpha copied; the game's icons, auras and party pets stay |
| Boss: shown while the boss exists; level `??`, Boss rank; threat; cast bars | unit watch on `bossN`; the level line; the edge; the game's boss cast bars stay |
| Edit Mode: position, layouts, Frame Size, Opacity | followed (above) |
| UI modes (cutscene, pet battle, spectator: `C_Roleset`, Blizzard_UIModes) hide the `unitFrames` roleset | every frame of ours is tagged `unitFrames` (`SetRolesets`, as `PlayerFrame.xml`, `TargetFrame.xml`, `PartyFrame.xml` tag the stock ones; boss frames too, as oUF does): protected, so set once out of combat (`M.Apply`), never in combat. What hangs off ours (the aura rows) goes with them |

**Gaps (to verify or build):** the stock target of target's debuff icons
are faded with it (ours shows none); the target of target still shows when
the target is the player (no macro condition says so); the pet's attack-mode
pulse; the party pets keep the stock look; a boss with no power shows "0"
under an empty power bar; range fading is none on the stock ones either.

**Settings** (`/pui unitframes`, a small page of ours,
`PolestarUIUnitFramesOptions`): Background opacity, 3D portraits, Power text (off), Sparkle, Smooth bars, Damage trail, saved in
`PolestarUIDB.unitframes`. Its "..." menu has "Use game window".

**Switch:** `/pui unitframes on|off`, live (refused in combat): off hides ours,
gives the stock frames their mouse, art and bars back at once.

**HUD kit** (`Modules/HUD.lua`, `ns.HUD`): `H.Bar(parent, trail?)` (secret-safe StatusBar on
a progress-wash track, with `trail` a damage trail under its fill fed by `H.SetTrail(b, v, snap, on, max)`, or `bg` at an alpha with `H.SetTrack`; skin-aware fill), `H.Segment` (a bar continuing
another's fill, or eating into it from its end; without a token the caller colours it), `H.SetValue(b, v, smooth)`
(the client's eased fill), `H.Sparkle`/`H.SizeSparkle`/`H.PaintSparkle`
(Polestar's band stars over a bar), `H.Text` (outlined HUD text, SetFormattedText only),
`H.Ground`/`H.PaintGround`, `H.Portrait(parent, bare)`/`H.SetPortrait` (square 3D well, framed before it shows: `H.Framed`),
`H.ClassColor` (secret-safe), `H.UnitColor`, `H.PowerColor`.

**Polestar asks** (built here for now; for Polestar when it takes them):
- `Theme.ClassColor(file)` errors on a secret `file` (it indexes
  `RAID_CLASS_COLORS`): return nil for a secret, as `H.ClassColor` does.
- `W.Text`'s font hook (`Theme.Font`) reads the string's text, so a string
  that takes secret values cannot use it: a HUD text widget that sets the face
  without the hook (`H.Text`).
- `W.ProgressLine`/`W.SetProgress` do maths on the value: a StatusBar-based
  bar for secret values (`H.Bar`), and a `hud` skin kind for the ground.
- A square portrait well with a 3D model (`H.Portrait`).

**Unverified in the client:** the calculator's
clamp modes and that its "clamped" flags are taken by `SetAlphaFromBoolean`
in combat; the feel of `ExponentialEaseOut` (its time is the client's);
the damage trail's hold (0.4 s) and drain feel, and that a StatusBar a level
under another draws under its fill; whether the player's `spellID` on `UNIT_SPELLCAST_START` and the cost
table's `type` are clean in combat (a secret type is taken as the bar's);
model framing per race in the square well
(rule 5); that the model no longer rises into the well on a target change
(the camera set before `SetUnit`, alpha 0 until `OnModelLoaded` or a
quarter second), and that `OnModelLoaded` fires for `SetUnit`;
`"||"` drawn as one pipe by `SetFormattedText`; `UnitHealthPercent` with `CurveConstants.ScaleTo100` formatting
through `%.0f`; that hiding the two child frames leaves nothing of the stock
art drawn (the threat glow and the frame flash are in the hidden pieces); that
stock code never shows them again (none in the source); and that Edit Mode
draws its box at the same rect our frame reads; that the party and boss
stacking fallback matches where the game first shows a member or boss (its
`spacing`, the boss scale); the pet frame's unit watch and vehicle swap
(whether `pet` exists while the vehicle hides it); that an unanchored
`PetFrame` (no pet since login, or between its managed container's
`ClearAllPoints` and `Layout`) is what read as the screen's top left; and that the faded pet and
party pieces stay faded (the source never sets their alpha; the party
portrait's is, so it is hidden instead).

**Tests:** `tests/lua/stub_unitframes.lua` (loaded for every scene): the unit
API with secret values (`stub.secret`, `stub.units`), the unit watch, the
stock frames as Edit Mode systems with their Selection boxes and rule 16's
checks, Edit Mode (`stub.enterEditMode`, `stub.exitEditMode`,
`stub.moveSystem`, `stub.applyLayout`, `stub.showPartyInEditMode`), the pet,
party (`stub.updateParty`, `stub.inRaid`, `stub.raidStyleParty`) and boss
frames (`stub.updateBosses`), and state drivers. `stub_editmode.lua` (minimap and action bar scenes) chains its `stub.exitEditMode` onto this one, so leaving Edit Mode there runs the unit frames' handling too. Scenes: `unitframes`,
`unitframes-editmode`, `unitframes-combat`, `unitframes-off`,
`unitframes-options`, `unitframes-tot`, `unitframes-group`,
`unitframes-group-editmode`, `unitframes-pet` (the pet stays on its box
while the game unanchors its frame: dismissed, summoned, a vehicle),
`unitframes-predict` (heals, a shield past the missing health, a heal
absorb, smooth bars, the sparkle, a cast's power cost), `unitframes-trail`
(the damage trail: a loss held then drained, a heal snapping past it, no red
past the new health on a heal with and without Smooth bars, a maximum change in
step, a new target snapping, the setting off), `unitframes-glows` (the end glows, the
power percent, every frame's roleset, none set again in combat).
The stub's heal calculator (`CreateUnitHealPredictionCalculator`), the
eased `SetValue` (`bar.interpolation`), `SetAlphaFromBoolean`, `UnitPowerPercent`, `SetRolesets`/`GetRolesetNames`
(`stub_client.lua`: refused in combat on a protected frame), and a cast
(`stub.casting`, `stub.spellCosts`).
