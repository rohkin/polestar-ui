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

**Layout.** Each frame takes the size and scale of the stock frame's Edit
Mode box (`Selection`): the player's, target's and focus's 192 x 66 at Frame
Size 100%, a target of target the stock one's 120 x 49, the pet's box 112 x
40, a party member its stock frame's 120 x 53, a boss its stock frame's body
(192 x 66 at the bosses' small scale, 0.75). Inside, 2 in from the
edge: the portrait square (the frame's height) on the outer side (left for
the player, right for target and focus, mirroring the stock), then a 16 line
with the level (Small, textDim), rank ("Elite", "Rare Elite", "Rare", "Boss")
and name (Label, text), the health bar with its text at the far end
(Number), and a power bar (22% of the height) with its value centred
(Small, textDim). A target of target: its name on the health bar over the
power bar, no portrait or text. The pet and party members are compact: a 13
line with the name (Small), the health text in Small. Bosses have no
portrait, as the stock ones have none. All text is outlined with a hard shadow, as
on the transparent guide window (HUD rule).

**Colours** (from the player's Polestar theme, never fixed):
- Ground: the scheme's `bg` at the player's "Background opacity" (60%), a 1px
  `border` hairline. The hairline turns `danger` round the player's frame in
  combat, and takes the game's threat colours (`GetThreatStatusColor`) round
  a unit the player has threat on.
- Health: the accent; with Polestar's "Class colour" on (`ui.classAccent`,
  Theme.FollowsClassAccent), a player in their class colour. An enemy in
  `danger`, a neutral creature in `warning`, a dead, offline or tapped unit
  in `textMuted`. Incoming heals continue the fill in `success` at 45%,
  absorbs after them in `text` at 35%.
- Power: the game's power colours (`PowerBarColor`), as quality keeps the
  game's meaning.
- Skins: the game skins (Hearth, WoW Forever, Blizzard, Classic) wear the
  game's bar fill (`UI-StatusBar`), the house skins a flat one; grounds,
  hairlines, wells and text follow each skin's palette.

**Edit Mode** (the only way to move them; the settings page says so). Ours
sit on the stock frame's `Selection` box: read (GetLeft, GetTop, size,
effective scale), never anchored (rule 10). Placed on login, on
`EDIT_MODE_LAYOUTS_UPDATED` (a layout switched or reset, next frame), every
frame while Edit Mode is open (the player drags the stock box; ours move with
it, the box drawn over ours), and as Edit Mode closes. Frame Size is the stock
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
| Status text: `statusText` (always or on mouse-over), `statusTextDisplay` (NUMERIC, PERCENT, BOTH, NONE) | the same CVars |
| Dead, Ghost, Offline | the health text says so; bar in textMuted |
| Name, level, `??`, elite/rare/boss dragon | name, level, rank word; the stock skull also shows (Contextual layer) |
| Portrait | square 3D model (2D game portrait while the unit is out of sight); the setting turns it off |
| Heal prediction, absorbs, heal absorbs | incoming heals and total absorbs continue the fill; heal absorbs (`UnitGetTotalHealAbsorbs`) eat into it from its end in `danger` at 50% |
| Threat (glow), combat flash | the hairline's colour |
| Numeric threat, leader, guide, PvP/prestige, raid target, quest, pet battle, role, ready check, rest, group, play time, ping icons; target and focus auras | the game's own, still drawn by the stock frame's Contextual layer where the stock puts them |
| Cast bars (target, focus, player) | the game's own (children of the stock frames, or their own Edit Mode system) |
| Combo points, totems, pet frame, alternate power | the game's own (they hang off the stock frames, which stay) |
| Left click targets, right click opens the unit menu, click casting, pings | secure attributes (`target`, `togglemenu`), SecureUnitButtonTemplate, PingableUnitFrameTemplate |
| Tooltip on hover | GameTooltip:SetUnit |
| Vehicle swap | the player frame shows the vehicle; clicks follow `toggleForVehicle` |
| Target of target: the `showTargetOfTarget` option; hidden with no unit or a dead target | the same CVar; a state driver `[@targettarget,noexists][@target,dead] hide; show` |
| Pet: shown with a pet, the player in a vehicle; happiness; attack mode; pet cast bar | unit watch on `pet`, `toggleForVehicle` (shows the player); the game's happiness icon and pet cast bar (`PetCastingBarFrame`, its own frame) stay; attack mode's red pulse is veiled (our edge does not show it) |
| Party: shown in a group, not in a raid, not with Raid-Style Party Frames; offline, dead; out of phase or in another group (faded to 0.6); leader, guide, role, PvP, ready check, summon, phasing icons; auras; party pets | a state driver `[group:raid] hide; [@partyN,exists] show; hide`, standing down with Raid-Style Party Frames; the texts; the stock member's alpha copied; the game's icons, auras and party pets stay |
| Boss: shown while the boss exists; level `??`, Boss rank; threat; cast bars | unit watch on `bossN`; the level line; the edge; the game's boss cast bars stay |
| Edit Mode: position, layouts, Frame Size, Opacity | followed (above) |

**Gaps (to verify or build):** the stock target of target's debuff icons
are faded with it (ours shows none); the target of target still shows when
the target is the player (no macro condition says so); the pet's attack-mode
pulse; the party pets keep the stock look; a boss with no power shows "0"
under an empty power bar; range fading is none on the stock ones either.

**Settings** (`/pui unitframes`, a small page of ours,
`PolestarUIUnitFramesOptions`): Background opacity, 3D portraits, saved in
`PolestarUIDB.unitframes`. Its "..." menu has "Use game window".

**Switch:** `/pui unitframes on|off`, live (refused in combat): off hides ours,
gives the stock frames their mouse, art and bars back at once.

**HUD kit** (`Modules/HUD.lua`, `ns.HUD`): `H.Bar` (secret-safe StatusBar on
a progress-wash track, skin-aware fill), `H.Segment` (a bar continuing
another's fill, or eating into it from its end), `H.Text` (outlined HUD text, SetFormattedText only),
`H.Ground`/`H.PaintGround`, `H.Portrait`/`H.SetPortrait` (square 3D well),
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

**Unverified in the client:** model framing per race in the square well
(rule 5); `UnitHealthPercent` with `CurveConstants.ScaleTo100` formatting
through `%.0f`; that hiding the two child frames leaves nothing of the stock
art drawn (the threat glow and the frame flash are in the hidden pieces); that
stock code never shows them again (none in the source); and that Edit Mode
draws its box at the same rect our frame reads; that the party and boss
stacking fallback matches where the game first shows a member or boss (its
`spacing`, the boss scale); the pet frame's unit watch and vehicle swap
(whether `pet` exists while the vehicle hides it); and that the faded pet and
party pieces stay faded (the source never sets their alpha; the party
portrait's is, so it is hidden instead).

**Tests:** `tests/lua/stub_unitframes.lua` (loaded for every scene): the unit
API with secret values (`stub.secret`, `stub.units`), the unit watch, the
stock frames as Edit Mode systems with their Selection boxes and rule 16's
checks, Edit Mode (`stub.enterEditMode`, `stub.exitEditMode`,
`stub.moveSystem`, `stub.applyLayout`, `stub.showPartyInEditMode`), the pet,
party (`stub.updateParty`, `stub.inRaid`, `stub.raidStyleParty`) and boss
frames (`stub.updateBosses`), and state drivers. Scenes: `unitframes`,
`unitframes-editmode`, `unitframes-combat`, `unitframes-off`,
`unitframes-options`, `unitframes-tot`, `unitframes-group`,
`unitframes-group-editmode`.
