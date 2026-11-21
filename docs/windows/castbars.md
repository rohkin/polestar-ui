#### Cast bars (`PlayerCastingBarFrame`, `TargetFrameSpellBar`, `FocusFrameSpellBar`) — Risk: high

The game's own cast bars, restyled in place and never rebuilt
(`Modules/CastBars.lua`), in the HUD's look: a flat bar 20 units high in the
theme's colours, a thin border, the spell's icon at its left, its name
inside on the left and the time left inside on the right, outlined.

**Why restyled, not replaced.** `PlayerCastingBarFrame` is an Edit Mode
system (`EditModeCastBarSystemTemplate`, `CastingBarFrame.xml`) and the
target's and focus's bars are children of the stock unit frames
(`TargetFrameMixin:CreateSpellbar`): CLIENT.md rules 16 and 17 decide it. A
bar of our own would need the stock one gone, and the game offers no way that
keeps the rules: `SetAndUpdateShowCastbar(false)` writes a key on a system
frame, and unregistering its events or hiding it is forbidden. So the game's
bar stays the cast bar: its place, Bar Size, Lock to Player Frame, the
target bar's place under the auras or the target of target, the
cast itself (progress, the fade out, the hold on an interrupt, trade skills)
and what shows it are all the game's. It is never moved, sized, shown or
hidden, and none of its children is re-anchored.

**How.** Everything of the game's bar that draws is faded where it is, and a
frame of ours under the bar (a child made with `Polestar.CreateFrameUnder`,
rule 17: it follows the bar's place, scale, alpha and visibility by itself)
draws ours over it: as wide as the bar, 20 units high from the bar's top.
That is where the game's bar and its text box were (11 + 12 units on the
player's, 10 + 12 on the others), and exactly the height of the game's own
icon on the target's and focus's bars.

**Parts** (`CastingBarFrameBaseTemplate`, `SmallCastingBarFrameTemplate`):
| Stock part | Ours | How | Gotcha |
|---|---|---|---|
| The fill (its atlas and colour set again for each cast, `UpdateBarFillTexture`) | a flat fill of ours, 20 high | a texture on our frame anchored to the game's fill texture's `TOPLEFT` and `TOPRIGHT`, 20 high (`SetHeight`). Its right edge is the game's, so the cast's progress is never read (cast times are secret, rule 3) | nothing of the stock bar's geometry is read either: `TargetFrameSpellBar:GetHeight()` is secret in combat (900 errors in the client from one compare); the game's fill cannot be faded (`SetStatusBarColor(1, 1, 1)` writes its alpha on every cast): it is under ours |
| `Background` | a track: `bg` at the unit frames' Background opacity (`H.GroundAlpha`) | a texture filling our frame | |
| `Border`, `TextBorder`, `DropShadow`, `BorderShield`, the spark's glows (`StandardGlow`, `CraftGlow`, `ChannelShadow`) | faded; Polestar's window border round our frame (`H.PaintEdge`; `o.look` for another module's bar: a nameplate's `H.PLATES`) and its window shadow outside it (`H.Shadow`) | `SetAlpha(0)`: the game only shows, hides and swaps atlases on them | |
| `Spark` | faded, again on every frame a bar shows | `SetAlpha(0)` | the interrupt animation (`InterruptSparkAnim`, `setToFinalAlpha`) sets it to 1 |
| `Text` (the name, Interrupted, Failed) | faded; ours inside the bar on the left (`label`, outlined), cut where the time starts | `SetAlpha(0)`; ours from `UnitCastingInfo`/`UnitChannelInfo`'s display name into `SetFormattedText` (secret for another unit: never read; the never-secret `isTradeskill` says there is a cast) | an interrupt shows the game's `INTERRUPTED` or `FAILED`; the game's "interrupted by <name>" is not shown (its text is never read) |
| `CastTimeText` (the player's) | faded; ours inside the bar on the right (`number`, outlined, "1.3") | `UnitCastingDuration(unit):GetRemainingDuration()` (or `UnitChannelDuration`) into `SetFormattedText("%.1f")`, each frame | always shown on all three, whatever Edit Mode's Show Cast Time says (the user's choice; that setting now only shows the game's own cast time, which is faded); a sample "10.0" in Edit Mode |
| `Icon` | faded; ours left of the bar, 20 x 20 (the bar's full height), cropped 8%, in a hairline | `SetAlpha(0)`; ours `SetTexture(select(3, UnitCastingInfo(unit)))` (a secret file is taken) | on the target's and focus's bars ours sits exactly where the game's was |
| `Flash`, the finish effects, the interrupt's outer glow | the game's, untouched: the game animates their alpha | | they are under our frame: covered by the fill, seen faintly through the track |
| The empowered stages | the game's | while `reverseChanneling`, our track and fill hide, so the stage art shows through our frame; our hairline, icon and name stay over it (outlined, so readable) | no time on an empowered cast |

**Colours** (the player's theme): the fill in the header band's blue (`sky`, as the unit frames' health, `H.FillColor`; the caster's class colour
when Polestar's "Class colour" is on), a channel too; a cast that cannot be interrupted
in `textMuted` (the game's grey shield bar; target and focus only, as the
game marks none on the player's own); an interrupted or failed cast in
`danger`. Whether a cast can be interrupted is secret for another unit: the
boolean goes straight into `SetVertexColorFromBoolean`, which picks the
colour.

**State.** What the bar is doing is read off the game's own flags
(`casting`, `channeling`, `reverseChanneling`, `isInEditMode`: plain booleans the game writes, never secret), each
frame a bar shows, after the game's handlers ran. An interrupt or failure:
the game tells its own cast's from another spell's (a key pressed mid-cast)
by the cast id, secret for another unit; ours by the bar: it was casting at
our last look and, after `UNIT_SPELLCAST_INTERRUPTED` or
`UNIT_SPELLCAST_FAILED`, no longer is.

**Edit Mode.** Ours is a child of the bar, so position, Bar Size (the bar's
scale: ours is 20 of its units) and Lock to Player Frame follow by
themselves; Edit Mode's sample bar is covered in the default fill and named
"Cast Bar".
- **The player's box.** Edit Mode's selection box is the bar plus the text
  box under it: 208 x 23 from the bar's top. Ours is 208 x 20 from the same
  top: inside the box on every side, 3 units short at its foot. Snapping and
  neighbours see what the player sees. Only the icon lies outside: 22 units
  left of the box (the game shows no icon there), so a frame snapped to the
  cast bar's left edge would sit under the icon.
- **Locked to the player frame**, the game makes the bar 150 x 10 with no
  text box and hangs it under the stock player frame's place: ours hangs 10
  units below that bar's foot, and our slim player frame is centred in the
  stock box, so a gap shows between them.
- **Target and focus** have no box of their own: the bars stay where the
  game hangs them off the stock frames, under the game's auras, and are not
  moved onto ours (rule 17). Ours covers the game's bar and text box
  (150 x 22) but for 2 units at the foot.

**Combat.** None of the bars is protected; every call is on a region of the
game's (its alpha) or on our own frame. A bar the game has not made yet is
restyled when it appears.

**Switch:** `/pui castbars on|off`, live (not in combat): off gives back the
art, the spark, the name, the time and the icon and hides ours, mid-cast too.
No window, so no "..." menu. Off by default with the gamepad UI.

**Not covered yet:** the pet's cast bar (`PetCastingBarFrame`), the bosses'
(`Boss1TargetFrameSpellBar`..), the professions' overlay bar
(`OverlayPlayerCastingBarFrame`); the target's name on
a cast (`CastTargetNameText`, where the game shows one).

**Shared:** the nameplates' cast bars wear this look through `ns.CastLook`
(`dress(bar, o?)`, `paint`, `fail`, `undress`; `o` a smaller fit: height,
icon size, texts under the bar, text size), see
[nameplates.md](nameplates.md).

**An own bar instead (not built; needs a leave).** Bars of ours on our
target and focus frames (attached, sized to them) would need the stock ones
silenced: `bar:SetAndUpdateShowCastbar(false)` or `UnregisterAllEvents()` on
`TargetFrameSpellBar`, `FocusFrameSpellBar` and `PlayerCastingBarFrame`, a
key written or events dropped on a stock frame (rules 16, 17), and for the
player's a mover-free way to follow Edit Mode (reading the hidden system
frame's rect, as the unit frames do).

**Tests:** `tests/lua/stub_castbars.lua` (the three bars with the templates'
regions and `CastingBarMixin`'s handling: the fill set again per cast, the
flags, the spark's alpha after an interrupt, `SetLook`, Edit Mode's Lock to
Player Frame and Show Cast Time; another unit's cast secret, duration
objects, `SetVertexColorFromBoolean`), every bar and region guarded. Scenes:
`castbars` (player, a target's cast that cannot be interrupted, a focus's
interrupted channel, another spell's failure), `castbars-editmode`,
`castbars-off`.

**Live checks (not in the preview):** that our frame draws over the game's
fill, flash and effects at every moment (a child frame over its parent's
regions) and fades out with the bar; that the faded name, time and icon stay
faded (the game sets the name's font object and shows or hides them, never
their alpha, in the source); that `TargetFrameSpellBar` takes a child frame
of ours while it hangs off the aura container (it inherits that container's
forbidden aspects); a secret name through `SetFormattedText("%s")`, a
secret `notInterruptible` through `SetVertexColorFromBoolean`, the timer's
`%.1f` of a secret duration; the interrupt's outer glow round the flat bar;
an empowered cast, if the game has one here.
