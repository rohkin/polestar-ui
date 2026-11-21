#### Cooldown Viewer (`EssentialCooldownViewer`, `UtilityCooldownViewer`, `BuffIconCooldownViewer`, `BuffBarCooldownViewer`) — Risk: high

The game's own Cooldown Manager viewers, restyled in place and never rebuilt
(`Modules/CooldownViewer.lua`, key `cooldowns`), in the HUD's look: the
cooldown and tracked buff icons as the action buttons (square, our ground
and Polestar's window border as the edge, 2 px at most, a square sweep), the tracked buff bars as the cast bars
(a track, a flat fill, a hairline), every number and name in Polestar's
faces, outlined.

**Turning the viewers on** is the game's own option: the
`cooldownViewerEnabled` CVar, a checkbox in Options' Advanced Options
(`ENABLE_COOLDOWN_VIEWER`, `AdvancedOptions.lua`), also turned on by ticking
the Cooldown Viewer systems in Edit Mode's list (`allowAutoEnableCVar`).
What each viewer tracks is set in the game's Cooldown Settings window
(`/cdm`), which stays stock.

**Why restyled, not replaced.** Each viewer is an Edit Mode system
(`CooldownViewerTemplate` inherits `EditModeCooldownViewerSystemTemplate`;
three are also stacked by the bottom manager), and secure code writes into
the items (the aura map in `CooldownViewerSecure.lua`, keyed by secret aura
instance ids; the spell alert and glow managers): CLIENT.md rules 15 and 17
decide it. A replacement would need the stock viewers silenced (a hide or
events dropped on a system frame) and would have to rebuild cooldown and
aura tracking from secret data.

**How.** Items are pooled (`CreateFramePool` on the viewer; `RefreshLayout`
releases and acquires them on every layout, spec, settings and Edit Mode
change). A driver of ours looks each frame at every shown viewer's children
and dresses each item with a `Cooldown` or a `Bar` it has not seen (the
pandemic effects and Edit Mode's `Selection` have neither). A pooled frame
keeps what we added across release and acquire, so each is dressed once; one
acquired for the first time shows the stock look for at most a frame. No pool
callback, no hook on the mixins, no key on any frame: ours lives in a weak
table keyed by the item.

**Parts** (`CooldownViewer.xml`):
| Stock part | Ours | How | Gotcha |
|---|---|---|---|
| `Icon` under the unnamed `UI-HUD-CoolDownManager-Mask` | square, cropped 8%, 3 units inside the item | the game's mask swapped for a square `MaskTexture` of ours (white, `CLAMPTOBLACKADDITIVE`, inset 3): `RemoveMaskTexture(icon:GetMaskTexture(1))`, `AddMaskTexture(ours)`, `SetTexCoord`; given back the other way round with `SetTexCoord(0, 1, 0, 1)` | the game's desaturation and vertex colours (range, no mana, unusable) stay its own; with no `GetMaskTexture`, the icon stays the game's |
| The unnamed overlay (`UI-HUD-CoolDownManager-IconOverlay`) | faded | found once by its atlas; `SetAlpha(0)` | the game never touches it again |
| Ground and border | a tile 2 units inside the item: `bg` at `H.GroundAlpha()` and a `border` hairline on its edges, the icon a unit further in so the line lies on our ground, not on the art | textures of ours on the item (on the bar item's `Icon` frame, so Bar Content "Name only" hides them with it) | |
| `Cooldown` sweep (rounded file, XML only) | square, over our tile | `SetSwipeTexture("Interface\AddOns\Polestar_UI\Media\cooldown-swipe-<size>")` (white with a 2-texel clear margin, one per item size, from the viewer's name): CLIENT.md rule 17's sweep exception, the user's leave | its colour and whether it draws stay the game's (`SetSwipeColor`, `SetDrawSwipe`) |
| Countdown, `ChargeCount.Current`, `Applications.Applications`, the bar's `Icon.Applications` | `number` face, outlined, at the game's size | `H.Face` | never read: secret in combat (rule 3); Show Timer stays the game's |
| `OutOfRange`, `CooldownFlash`, the spell alert, the pandemic effect | the game's | untouched | drawn for a rounded icon: live check how they sit on a square one |
| `DebuffBorder` (buff icons and bars) | the game's | untouched | its atlas comes from the dispel type, which can be secret |
| Bar fill (the orange `UI-HUD-CoolDownManager-Bar`) | a flat fill in the header band's `sky`, or the class colour with Polestar's "Class colour" (`H.FillColor("player")`) | a texture of ours on `Bar` (ARTWORK 7, over the game's fill, under its name, time and pip) anchored to the game's fill texture's corners | no value or size read: the edge is the game's (rule 3) |
| `Bar.BarBG`, `Bar.Pip` | faded; a track (`bg` at `H.GroundAlpha()`) and a hairline round the bar | `SetAlpha(0)`: the game only shows and hides the pip | |
| `Bar.Name`, `Bar.Duration` | `label` and `number` faces, outlined | `H.Face` | Bar Content and Show Timer still show or hide them |

**Room between the icons.** The game lays items out at Edit Mode's
Padding less 4 (`GetAdditionalPaddingOffset`; bars less 2), and the preset
Padding is 2 for the essential and utility viewers, 5 for the buff ones: at
the default the item frames overlap by 2, and the game's rounded mask, inset
inside each frame, makes the gap. Our tile sits 2 units inside each item
(never moving it, rule 17), so the gap equals the Padding setting, as the
game intends: 2 by default, more with a higher Padding.

**Deviation from the plan.** The bar's track and fill are textures on the
game's `Bar`, not a frame under it: a child frame draws above the bar's own
regions and would cover the game's name and time, which stay the game's.

**Edit Mode.** Nothing of the viewers or items is moved, sized, scaled,
shown or hidden; position, snapping, the bottom manager's stacking,
Orientation, Icon Limit, Icon Direction, Icon Size (the item's scale),
Padding, Opacity, Visibility, Hide When Inactive, Show Timer, Show Tooltips,
Bar Content and Bar Width stay the game's and ours follows. Edit Mode's
sample items are the same pooled frames, dressed like the real ones. On
`EDIT_MODE_LAYOUTS_UPDATED` and `EditMode.Exit` the hairlines are repainted
one pixel at the new scale.

**Combat.** Nothing here is protected. Items acquired mid-fight (a new aura,
a spec swap) are dressed at once: textures and faces on plain frames.

**Switch:** `/pui cooldowns on|off`, live (not in combat): off gives back the
mask, crop, overlay, sweep, faces, BarBG and pip and hides ours. No window,
so no "..." menu. Off by default with the gamepad UI.

**Not covered:** the Cooldown Settings window (`CooldownViewerSettings`,
stock by the user's choice).

**Tests:** `tests/lua/stub_cooldowns.lua` (the four viewers, a frame pool
per viewer, the templates' regions with the unnamed mask and overlay, a
`Cooldown` whose sweep is drawn, Edit Mode's settings and sample items, a
non-item child beside the items), every viewer, item and region guarded, the
counts' `GetText` too. Scenes: `cooldowns`, `cooldowns-classcolour`,
`cooldowns-editmode`, `cooldowns-combat`, `cooldowns-off`.

**Live checks (not in the preview):** that the four viewers show on Forever
with the option on; that `GetMaskTexture(1)` returns the unnamed mask; that
the white sweep draws square in the game's colour; the flash flipbook, spell
alert, range shadow and pandemic effect round a square icon; that our bar
fill follows the game's fill as it drains and draws under the name and time;
no stock-look flash after a relayout or spec swap; no error in combat.
