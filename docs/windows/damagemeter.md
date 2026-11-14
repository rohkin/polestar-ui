#### Damage meter (`DamageMeter`, `DamageMeterSessionWindow1`..`3`) — Risk: medium

The game's own damage meter (Blizzard_DamageMeter, loaded on Forever),
restyled in place and never rebuilt (`Modules/DamageMeter.lua`), in the
HUD's look: our HUD ground and hairline, no header band, flat bars in the
theme's colours, Polestar's faces, outlined.

**Why restyled, not replaced.** `DamageMeter` is an Edit Mode system
(`EditModeDamageMeterSystemTemplate`) and window 1 is anchored to it
(`SetupSessionWindow`: `TOPLEFT`, `BOTTOMRIGHT`), so Edit Mode places and
sizes it (rule 17). The session data (`C_DamageMeter.GetCombatSession*`) is
`SecretWhenInCombat` with `SecretArguments = "AllowedWhenUntainted"`: only the
game's untainted code can read, sort and sum it in combat (rule 3). A meter of
ours would get secrets it could not order, and the stock one would have to be
hidden. So every row, number, menu, the breakdown, the saved windows and every
setting stay the game's.

**How.** Nothing of the meter is moved, sized, shown, hidden or hooked, and no
key is written on it; no ScrollBox, Menu or EventRegistry callback is
registered on its objects (its menus are reached by tag, `Menu.ModifyMenu`, as
the chat's; `ScrollUtil.AddAcquiredFrameCallback` would run our
code inside the stock code that handles the secret data). A driver of ours
(`OnUpdate`, doing nothing while `DamageMeter` is hidden) finds the windows by
name each frame and dresses what it meets: windows 2+ appear when the player
opens them and rows as sources appear (pooled: a row is dressed once, its art
faded again each frame). Our art is textures made on the stock frames
(widget calls), kept in weak tables.

**Parts:**
| Stock part | Ours | How | Gotcha |
|---|---|---|---|
| `Header` (atlas) | faded; a hairline under the header strip | `SetAlpha(0)` (the game never writes its alpha) | HUD rule: no band |
| `MinimizeContainer.Background` (alpha written by the game: Background Transparency) | emptied; our HUD ground (`H.Ground`) on the container at that alpha times the HUD's Background opacity (`H.GroundAlpha`) | `SetTexture(nil)` (given back with `SetAtlas("damagemeters-background")`); its `GetAlpha()` read each frame | rule 15's chat lesson: never faded, so its alpha stays live. On the container, as the game's: minimized, it hides with it and only the header's texts stay |
| `SessionTimer`, `SessionName` (the session letter: "C", "O", a number), `TypeName`, `NotActive` | Polestar's faces (`number`, `label`), outlined, at the game's size, in the `text` colour as the rows' (the game's colour kept and put back when off) | `H.Face`, `SetTextColor`; each frame the font is checked against ours and set again if anything changed it | never read (the timer is secret-derived). Nothing in the source sets their font again (the session dropdown's template restyles its own `Text`, not `SessionName`); the check is a guard |
| `MinimizeButton` (normal, pushed, highlight atlases; `SetMinimized` swaps them) | faded; our `chevron-up` glyph (`chevron-down` while minimized, read from the container's `IsShown`), a hover wash | `SetAlpha(0)` on the three textures; ours on the button: a glyph (`ARTWORK` 7, `icon` token) and a `HIGHLIGHT`-layer wash, which the client shows on mouse-over (no script) | `SetAtlas` keeps the alpha, so faded once |
| `SettingsDropdown` (its `Icon` atlas per state) | faded; our `gear` glyph, a hover wash | as above | |
| `SessionDropdown` (`WowStyle2DropdownTemplate`: `Background` per state, the hover `Arrow`) | faded (its template has no other texture: `Text`, unused here, and a hidden `ResetButton`); only the letter, in our face and colour, and a hover wash: no box (the user's call; the box seen in game was our earlier plate) | as above | |
| `DamageMeterTypeDropdown` (`WowStyle1ArrowDropdownTemplate`: `Arrow` per state) | faded; our `chevron-down` glyph on the arrow's centre, a hover wash | as above | |
| Their menus (Blizzard_Menu, tags `MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE` with its category submenus, `MENU_DAMAGE_METER_SESSIONS`, `MENU_DAMAGE_METER_WINDOW_SETTINGS`) | the style's ground faded; Polestar's window ground (`Theme.GroundAlpha`) and a hairline | `Menu.ModifyMenu(tag)`, then the root's `AddMenuAcquiredCallback`; ours through the menu's own `AttachTexture`, freed (and the fade reset) when it closes (rule 15, as Chat.lua's menus) | the type and settings menus are MenuStyle1 (items 8 from the top, 15 from the foot: ours ends 7 above it); the session menu MenuStyle2 (even). A callback cannot be removed: switched off, it does nothing |
| Their items: radios and checkboxes (`leftTexture1`, `leftTexture2` when selected), submenu arrows (`arrow`), the hover (`highlight`), dividers | radio: our `skin-ring` in `textMuted`, the `accent` `circle` dot when selected; checkbox: a muted box, the `accent` `check` when ticked; submenu: our `chevron-right` in `icon`; hover: our wash; divider: a `border` hairline | in the same `ModifyMenu` callback, `AddInitializer(itemLook)` on every element description (submenus too): it runs after the game's initializers built the item; the game's pieces faded (`SetAlpha(0)`), ours attached through the item's compositor (`item:AttachTexture()`); the highlight, whose alpha the game writes on enter (1, or 0.4 disabled), recoloured in place (`SetColorTexture` with the wash, `BLEND`) | on close the compositor sets every attachment to its defaults (`SetToDefaults`) and frees it, so a pooled item another menu gets is the game's. Only pieces the item's description says were made are touched (`IsRadio`, `IsCheckbox`, `CanOpenSubmenu`; a non-button item's one texture is its divider): a key left from an earlier use could name a texture now in another menu. The items' text stays the game's font |
| `ScrollBar` | the game's | untouched | optional, left: its thumb and arrows swap many atlases by state and the game animates its alpha |
| `ResizeButton` (alpha 0 till the game fades it in on mouse-over) | its three textures faded; our `resize` grip in the container's corner, no wash | as the buttons | |
| Entry `StatusBar` fill (tinted by the game each update) | a flat fill (`H.FillTexture`) over it, edge to edge | a texture on the `StatusBar` (`ARTWORK` 7, under the game's `OVERLAY` texts) anchored to the game's fill texture's corners | no value or geometry read (rule 3) |
| Entry `Background`, `BackgroundEdge` (atlas set again by `UpdateStyle`, alpha 1 by `UpdateBackground` on every acquire) | faded each frame; a track of ours (`bg` at `H.GroundAlpha`) | `SetAlpha(0)` | a newly acquired row may show the game's art for one frame |
| `Name`, `Value` | `label`, `number` faces, outlined; Text Size (`SetTextScale`) still applies | `H.Face` | never read (secret in combat) |
| `Icon.Icon` (spec icon, secret; or a class atlas) | the game's, with a 1px `border` hairline | four textures on the `Icon` frame | the icon is 24 high in a row of Bar Height: below 24 the row clips it, hairline too (as stock) |
| `LocalPlayerEntry` (the pinned player row) | dressed as any row | | decision 2: no mark of its own |
| `SourceWindow` (the breakdown, HIGH strata) | its `Background` (a plain atlas) faded; our ground at 0.94; its spell rows dressed | `SetAlpha(0)` | |

**Colours.** The fill is the header band's blue (`sky`); with the meter's
own Show Class Color (each row's `isClassColorDesired`, written by the game),
a player's class colour from the row's `classFilename` (NeverSecret in
`DamageMeterDocumentation.lua`; guarded with `ns.Clean` all the same). A
creature has no class: sky. The game's ally and enemy tints are not kept.

**Edit Mode.** Window 1 hangs on the system: position, Frame Width and
Height, Bar Height, Padding, Style (every style gets our flat bars on the
game's geometry: Thin, Bordered), Numbers, Show Spec Icon, Text Size,
Visibility and Transparency (the windows' alpha, inherited) are the game's,
and ours follows by anchors and the per-frame driver. Background Transparency
is copied (times the HUD's Background opacity). Windows 2+ are the player's:
the game's drag, resize, lock and minimize; ours never moves them.

**Combat.** Nothing is protected; rows acquired mid-fight are dressed (plain
frames). Never called: `C_DamageMeter.*`. Never read: a row's `value`,
`sourceName`, `specIconID` or any text.

**Switch:** `/pui damagemeter on|off`, live (not in combat): off gives back
the header art, the ground's atlas (at the alpha the game wrote), the rows'
art and the game's faces and buttons' art, and hides ours; menus opened after are the game's. No window, so no "..." menu. Off by
default with the gamepad UI.

**Not covered yet:** the scroll bar; the menu items' text (the game's font).

**One centre line.** The game's header pieces are not centred alike
(`DamageMeterSessionWindow.xml`, under the 32-high header's top): the type
label 14.5, the minimize button 14.5, the settings button 16.5, the session
button 13.5, the type arrow 17.5, the timer from 9 down (its centre follows
the font). They stay where the game puts them (rule 17); our glyphs
are offset onto the texts' visual centre by constants (`dy`) measured in game (the client draws the type arrow, settings and minimize buttons 2 to 2.6 units lower than the template maths and the preview): the gear +4.4, the type chevron +5.6, the minimize chevron +1.4. The preview therefore shows them about 2 units high. The session
letter sits 1 above it; the timer about 1 below.

**An empty list (seen in the client).** One player's meter showed its header
and a live timer but no rows, while `GetCombatSessionFromType(1, 0)` held a
source. From the stock source: the timer is on the window itself, while the
rows, ground and `NotActive` live in `MinimizeContainer`, which
`SetMinimized` hides; the rows' ScrollBox runs from 34 under the window's top
to 6 above its foot, so a window under about 60 high has no room for one; a
row is Bar Height high (`SetElementExtent`, `SetHeight`), and Edit Mode's
`GetSettingValue` answers 0 before the system is initialized and the raw
stored value when a setting has no display value (the preset stores Bar
Height 1, Frame Height 20, Text Size 5, each meaning 16, 140 and 100%). Ours
cannot cause it (nothing of ours sizes, shows or feeds the list) and cannot
mend it without moving the game's rows; the in-game check is in the
module's report.

**Tests:** `tests/lua/stub_damagemeter.lua` (the system, window 1 on it and
player windows on UIParent, the header, dropdowns, container, ScrollBox of
pooled rows, the pinned row, the breakdown; rows laid out per Style with the
game's atlases and alphas set again on each acquire; Edit Mode's settings and
sample session; secret data in combat), every frame and region guarded.
Scenes: `damagemeter`, `damagemeter-classcolour`, `damagemeter-combat`,
`damagemeter-editmode`, `damagemeter-styles` (Thin, Bordered),
`damagemeter-window2` (a player's window, a breakdown, window 1 minimized:
the expand glyph), `damagemeter-menus` (the type menu, MenuStyle1, then
another menu on the pooled frame is the game's; the session menu,
MenuStyle2), `damagemeter-off` (buttons and menus back).

**Live checks (not in the preview):** that a dropdown's faded art stays faded
through hover, press and an open menu (the game only calls `SetAtlas`); the
hover wash on each button; the type menu's category submenus restyled too;
that our ground on the container draws
under the header's texts and buttons (the container is `useParentLevel`);
the one-frame flash of a newly acquired row's art; the icon hairline at Bar
Height under 24; the breakdown's ground; that a Bordered row's art (a frame
round the bar, offset 6 and 7) is fully covered by fading it.
