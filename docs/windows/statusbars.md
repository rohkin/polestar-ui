#### Experience and reputation bars (`MainStatusTrackingBarContainer`, `SecondaryStatusTrackingBarContainer`) — Risk: medium

The game's status tracking bars (`Blizzard_StatusTrackingBar`), restyled in
place and never rebuilt (`Modules/StatusBars.lua`). Both containers are Edit
Mode systems (CLIENT.md, rule 17) under `StatusTrackingBarManager`, in the
bottom action-bar stack: their place, Size, the account option "Show status
bar 2", which bar each shows (`StatusTrackingManagerMixin:UpdateBarsShown`,
by priority), the fades between bars and at max level, the text, the
tooltips and the gain and level-up effects all stay the game's.

- **Stock shape:** each container holds one bar of every kind in
  `container.bars[StatusTrackingBarInfo.BarsEnum]` (1 reputation, 2 honor,
  3 artifact, 4 experience, 5 azerite, 6 house favour; all six exist on
  Forever, seen in game, though .ref loads 2, 3, 5, 6 for mainline only) and
  shows one. A bar: `StatusBar` (GradualAnimatedStatusBar: `Background`,
  `Underlay`, `Overlay`, `GainFlareAnimationTexture`, `LevelUpTexture`, its
  fill), `OverlayFrame.Text` (shown with the `xpBarText` CVar or on hover),
  the experience bar's `ExhaustionLevelFillBar` and `ExhaustionTick`. The
  container: `BarFrameTexture` and 19 dividers (`HorizontalDividersPool`,
  each a `BarDividerTexture`). No bar takes a click.
- **Ours:** under every bar of both containers, a frame of ours
  (`Polestar.CreateFrameUnder`, `SetAllPoints` on the bar, a level over its
  StatusBar; the text, `OverlayFrame`, is MEDIUM strata, over ours). It was
  under the StatusBar at first: the game sets the fill's texture again from
  the bar's own OnUpdate (`ApplyPendingTextures`: the reputation bar's
  colour waits for its first update after it shows), with no event, and after
  login the reputation bar showed the game's look until the next
  `UPDATE_FACTION`. Over it, ours covers the fill whatever the game does to it;
  the game's gain flare and level-up flash now go under ours. Each bar is
  also painted again in the frame the game shows it (`HookScript("OnShow")` on
  the bar: a widget script hook, no Lua key written): a track (`bg` at the Frames group's
  ground alpha), a fill hung on the game's fill texture's corners (it follows
  the value as the game eases it, with no value or size read: rule 3), a 1px
  hairline and the window shadow (`H.PaintEdge`, `H.PaintShadow`, the Frames
  look group), and a hairline tick (the edge's colour at half its alpha,
  `TICK_ALPHA` 0.5) hung on each live divider (Edit Mode's Size moves them;
  ours follow).
- **Stars (experience bar):** the track wears Polestar's header band,
  `Theme.Band` (the sky, tinted `sky`, and its stars, `star`; the skin's own
  `band`/`bandStars` art; painted clear with the band off; Polestar repaints
  it on every theme change), over the track and under the fill, at 70%
  (`STARS_ALPHA`). Cropped 1:1 as `ns.Compact` crops a window's band:
  `Theme.BandCoords(w, h, 23)` (rows 23 to 23 + h, the middle of a compact
  header), from the bar's own size (set by Edit Mode), read out of combat
  and never while secret, again on our frame's `OnSizeChanged` (a resize in
  Edit Mode) and each repaint. Wider than the band's 1,024 (the default
  1,189): `BandCoords` clamps at its edge, so the band stretches about 16% across, as a
  wide window's band does.
- **Faded (SetAlpha):** the StatusBar's fill, `Background`, `Underlay`,
  `Overlay`; `BarFrameTexture`; each divider's `BarDividerTexture`. The fill
  is asked again on each repaint (`GetStatusBarTexture`): a new texture
  object would be followed and faded.
- **Text:** `OverlayFrame.Text` in Polestar's `number` face, outlined, at the
  game's size (`H.Face`); when it shows stays the game's.
- **Colours:** experience: the scheme's violet (`dungeon`; the game's
  purple), the mana blue (`npc`) while rested (`GetRestState()` 1, the game's
  blue fill). Reputation: the watched faction's standing
  (`C_Reputation.GetWatchedFactionData().reaction`, as
  `ReputationStatusBarMixin:Update` reads it): 1-3 (hated, hostile,
  unfriendly) `danger`, 4 (neutral) `warning`, 5 and up `success`; a secret
  or missing standing keeps the last colour. The reputation track is tinted in that
  colour at 30% (`TINT_ALPHA`) over the dark track, as the game draws its
  green bar on a green ground; the experience track keeps its stars. Renown, paragon and friendship
  go by that same field for now (the game draws renown and a major faction's
  paragon blue and a friendship green). The other kinds: the HUD's default
  fill (`H.FillColor`).
- **Repaint:** events only: `PLAYER_ENTERING_WORLD`, `PLAYER_XP_UPDATE`,
  `PLAYER_LEVEL_UP`, `UPDATE_EXHAUSTION`, `PLAYER_UPDATE_RESTING`,
  `UPDATE_FACTION`, `MAJOR_FACTION_RENOWN_LEVEL_CHANGED`, `EDIT_MODE_LAYOUTS_UPDATED`, `EditMode.Exit`,
  `Theme.OnChanged`. Which bar shows needs none: ours are its children.
- **Not yet (later steps):** the rested segment and tick (the game's
  `ExhaustionLevelFillBar` is now under ours, so unseen; its pip, MEDIUM strata, still shows), reputation colours for friendship, renown and paragon, the other kinds' colours, combat
  checks. Click to open Reputation: an extra after parity.
- **The fade-in after login:** a container starts at alpha 0 and the game
  fades it in (`FadeInAnimation`: alpha 0 to 1 in 0.5 s on the container,
  from `StatusTrackingBarContainerMixin:FadeIn`, from `SetShownBar`, from the
  manager's `UpdateBarsShown`). After a /reload that fade took 5 to 8 s in
  game (traced: `FadeInAnimation:IsPlaying()` true from 0.5 to 5 s after
  Enable, done by 8 s; `GetAlpha` reads 0 throughout, the animated alpha is
  not the frame's own), so ours, a child, came in late and half see-through.
  Ours is dressed at PLAYER_LOGIN (Enable runs inside it; no gate) with the
  game's art faded from the start; nothing else draws over the bar
  (`UIWidgetTopCenterContainerFrame` only overlaps its rect). Now, while a
  container's `FadeInAnimation` plays, ours ignores the container's alpha
  (`SetIgnoreParentAlpha` on our own frame: shown at once, at full); it
  follows it again when the fade-in ends or stops, and through the game's
  fade-outs (`FadeOutAnimation`: a bar switch; `MaxLevelFadeOutAnimation`) and
  what follows them. Read from the animations' own scripts (`HookScript`
  OnPlay, OnFinished, OnStop on the container's animation groups: no key
  written), never polled. While it ignores the container's alpha it ignores
  UIParent's too (an addon fading the whole UI), only for that fade.
- **The game's art comes back:** in game (a /run listing every visible
  texture under the container, and a screenshot while the bar loaded in)
  `BarFrameTexture`, all 19 dividers, the shown bar's `Background` and its
  fill were at full alpha again under ours after we faded them, until the
  next `UPDATE_FACTION` repaint. No code in .ref writes their alpha: the live
  client's `StatusTrackingManagerMixin:UpdateBarVisuals` does (Edit Mode
  calls it with an argument the .ref one does not take; .ref's is empty), at
  the end of every `UpdateBarsShown`: on the manager's events, and when a
  container's fade ends (`UpdateBarsShown` waits for it, through the fade's
  OnFinished). It is a method copied into the manager, so a hook would write
  a key on it (rule 15) and one on the mixin would never run. Faded again
  instead (`refade`: only SetAlpha on what we fade): on each of the manager's
  events (`MANAGER_EVENTS`, the list `StatusTrackingManagerMixin:RegisterEvents`
  registers; the client calls handlers in the order frames registered, the
  manager's first), once more the frame after (one deferred `C_Timer.After(0)`
  however many events came, should one reach us first), and from the fades'
  own OnFinished (a hook, run after the game's script). Not covered: Edit
  Mode's live drag and Size slider (`OnSystemPositionChange`, no event) show
  the game's art until `EditMode.Exit`.
- **Switch:** `/pui statusbars on|off`, live; Settings, HUD. Off by default
  with the gamepad UI.
- **Scenes:** `statusbars`, `statusbars-editmode`, `statusbars-off`
  (`tests/lua/stub_statusbars.lua`, every stock frame and region guarded).
