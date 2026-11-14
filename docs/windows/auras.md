#### Player buffs and debuffs (`BuffFrame`, `DebuffFrame`) — Risk: medium

The game's own aura buttons, restyled in place and never rebuilt
(`Modules/Auras.lua`), in the HUD's look (the unit frames': square, flat, a
thin border, outlined numbers).

**Why restyled, not replaced.** `BuffFrame` and `DebuffFrame` are Edit Mode
systems (`BaseAuraFrameTemplate` on `EditModeAuraFrameSystemTemplate`,
`Blizzard_BuffFrame/BuffFrame.xml`): CLIENT.md rule 17 decides it. Their
place, Icon Size, Icon Limit per row, Icon Padding, Icon Direction, Icon
Wrap, Orientation, Opacity and Visibility are the game's and the player's.
And cancelling a buff is the game's to do: `AuraButtonMixin:OnClick` calls
`CancelUnitBuff`, which addon code may not call in combat; a replacement
would need the secure aura header, which knows none of Edit Mode's settings.
Kept as they are, each button keeps its own handlers: right-click cancels,
hover shows the game's tooltip, a weapon enchant cancels through its own
closure, and the deadly-debuff warning and the private aura anchors (secure)
are untouched.

**Parts** (each aura button: `AuraButtonTemplate`, `BuffFrameTemplates.xml`;
the frames keep them in `auraFrames`):
| Stock part | Ours | How | Gotcha |
|---|---|---|---|
| `Icon` (30 x 30, the client's baked border) | square, cropped 8% | `SetTexCoord`, as `ns.GameIcon` | given back with `SetTexCoord(0, 1, 0, 1)` |
| `DebuffBorder` (an atlas per dispel type, `AuraUtil.SetAuraBorderAtlas`), `TempEnchantBorder` | faded | `SetAlpha(0)`: the game only swaps the atlas and shows or hides them, which keeps the alpha | Edit Mode's Show Dispel Type glyph sits on that border: faded with it (the colour says the type) |
| the border's meaning | a 1px hairline of ours round the icon | `ns.Hairlines(button, Icon)` + `ns.PaintHairlines`, kept in a weak table | a buff: the `border` token; a debuff: its dispel type's colour, the game's own (`AuraUtil.GetDebuffDisplayInfoTable()`, as item quality keeps the game's meaning); a weapon enchant: the epic colour (the game's border is purple) |
| `Duration` (`GameFontNormalSmall`), `Count` (`NumberFontNormal`) | Polestar's `number` face, outlined, at the game's sizes and colours (gold, white under 90 s) | `H.Face` (Modules/HUD.lua) | never read (rule 3). In zhTW the game swaps the duration's font each frame for long buffs: there it stays the game's |
| The low-time flash (the button's alpha), `Symbol`, the collapse arrow, Consolidated Buffs, the deadly debuff warning, private auras | the game's | untouched | |

**What is read.** Only what kind of aura a button holds (`auraType`,
`isExample`, its frame's `exampleAuraType`: plain strings the game writes)
and a debuff's `buttonInfo.debuffType` through `ns.Clean`: while the client
keeps it secret (combat) the hairline is the plain debuff red.

**No hooks.** The game deals the auras over its buttons again on every change
(an aura gained or lost, the collapse arrow, Edit Mode's examples, which
also set the duration's font again), and rule 17 allows no hook on a system's
buttons: a frame of ours paints the shown buttons again ten times a second
(a few widget calls each; nothing is created after the first pass).

**Edit Mode.** Ours hangs on the buttons, so every setting follows by
itself; the hairlines are sized to one pixel at the button's scale on each
pass.

**Combat.** The buttons are not protected: every call (a texture's alpha,
colour and crop, a font) is allowed mid-fight.

**Switch:** `/pui auras on|off`, live (not in combat): off gives back the
borders, the icon's crop and the fonts at once. No window, so no "..." menu.
Off by default with the gamepad UI.

**Tests:** `tests/lua/stub_auras.lua` (both frames as guarded systems, the
buttons dealt as `AuraFrameMixin:UpdateAuraButtons` deals them, Edit Mode's
settings and examples, a debuff's type secret in combat). Scenes: `auras`
(colours by kind, the secret type, the game's cancel and tooltip, re-dealt
auras), `auras-editmode`, `auras-off`.

**Live checks (not in the preview):** that the icon's crop holds through the
game's own `SetTexture`; that the faded borders stay faded through a
dispel-type change; the look at every Edit Mode icon size; the duration's
size in the vertical orientation; whether a debuff's type is secret in
combat (then every debuff is red there).

##### Target and focus auras: rows of ours (`Modules/Auras.lua`)

Under our target and focus frames (`PolestarUITargetFrame`,
`PolestarUIFocusFrame`), one row of square aura icons of ours; the game's
own aura container is veiled. Chosen by the user over keeping the game's
(which cannot be restyled: the stock auras are the client's secure
`Blizzard_AuraContainer`, its buttons intrinsic `AuraButton`s hidden from
addon code) and over showing both.

**The veil (CLIENT.md rule 16, the exception).** Out of combat, `SetAlpha(0)`
on `TargetFrame`'s and `FocusFrame`'s
`TargetFrameContent.TargetFrameContentContextual.Auras`, nothing else. It is
veiled while both `auras` and `unitframes` are on and our frame exists, and
given back (alpha 1) when either is switched off; a change waits out combat.
A container that is forbidden or refuses the call is left alone, and then
ours does not show (never both). The game's container still lays its rows
out, so the stock cast bar still hangs under them.

**The row.** A plain frame of ours, a child of our unit frame, 3 units under
it, as wide as the frame, 20 high: it shows, hides, scales and fades with
our frame. One row only: what does not fit the width is left out (8 to 11
icons at 192 wide). It sits in the gap above the game's cast bar, which the
game hangs 26 units under our frame with no auras and lower with them.

| Stock | Ours | How (secret-safe) |
|---|---|---|
| Which auras, in what order (the player's own first) | the same | `C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter, 32, Enum.UnitAuraSortRule.Default)`: the client sorts; the ids are plain numbers. The `"...|PLAYER"` filter says which are the player's, with nothing read |
| Debuffs first on anyone but a friend, buffs first on a friend (`RebuildLayoutGroups`) | the same | `UnitIsFriend` through `ns.Clean` |
| The player's own auras large (21), others small (17) | 20 and 16 | from the `PLAYER` filter |
| On a hostile creature, another player's debuffs left out; `noBuffDebuffFilterOnTarget` shows all (`ShouldShowAuraAsDebuff`) | the same | `isFromPlayerOrPlayerPet` through `ns.Clean`: while the client keeps it secret (combat) they show |
| Icon | square, cropped, on the HUD ground, a 1px hairline | `SetTexture(aura.icon)` takes a secret file |
| Debuff border by dispel type | the hairline in the type's colour (`AuraUtil.GetDebuffDisplayInfoTable()`); a buff's in `border` | `dispelName` through `ns.Clean`: plain debuff red while secret |
| The time's sweep | the game's own Cooldown (`CooldownFrameTemplate`), its countdown in the `number` face, outlined | `C_UnitAuras.GetAuraDuration` into `SetCooldownFromDurationObject`; the face on `GetCountdownFontString()` |
| Stacks | bottom right, `number`, outlined | `C_UnitAuras.GetAuraApplicationDisplayCount(unit, id, 2, 99)` into `SetFormattedText` |
| Tooltip | the game's | `GameTooltip:SetUnitAuraByAuraInstanceID(unit, id)` on hover |

Repainted on `UNIT_AURA` for the unit, a target or focus change, and as
combat starts and ends.

**Gaps:** one row (the game wraps to more); the stealable (purple) border on
an enemy's buff; Buffs On Top (Edit Mode's target setting: ours is always
under the frame); the game's "nameplate only" debuff flag and another
player's pet; private auras on the target; the bosses' auras stay the
game's. The countdown numbers follow the game's own cooldown-numbers option.

**Tests:** the unit aura API in `stub_auras.lua` (ids sorted as the client
sorts them, every field secret in combat), the stock container and its guard
in `stub_unitframes.lua`. Scene `auras-target`: the veil, both orders, the
filter and its CVar, sizes, colours, stacks, the tooltip, both switches, the
secret case.

**Live checks (not in the preview):** the `/run` in the report first (the
container takes `SetAlpha(0)`; whether its faded buttons still catch the
mouse: the game's tooltips over nothing, about 13 to 35 units under our
frame, partly under our row); that `GetUnitAuraInstanceIDs` and
`GetAuraDataByAuraInstanceID` answer for the target in combat; the
countdown's face and size; an aura's sweep direction; that our icons, being
mouse-enabled children of a secure frame, show and hide mid-fight without a
blocked action.
