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
  ground alpha; the experience bar's see-through black, `shade` at 40%, `XP_TRACK`), a fill hung on the game's fill texture's corners (it follows
  the value as the game eases it, with no value or size read: rule 3), a 1px
  outline and the window shadow (`H.Edge`'s colour and size, its alpha at
  least `EDGE_MIN` 0.5, hidden with Polestar's border off; `H.PaintShadow`,
  the Frames look group), and a 1px tick (the same colour, its alpha at least
  `TICK_MIN` 0.3: the house border's 0.1 vanished on the dark track) hung on
  each live divider (Edit Mode's Size moves them;
  ours follow).
- **Experience bar as the game's, in Polestar's look:** a see-through black
  track (`shade` at 40%, `XP_TRACK`: the world shows through a little, as on
  the game's bar) and a solid fill in Polestar's blue wearing the header
  band's stars (the band-stars art, the skin's `bandStars`, in the `star`
  token at 60%, `STAR_OVER`; hidden with Polestar's band off, as
  `Theme.Band` paints them; repainted with every theme change). The stars
  show over the fill only: they sit on a frame as wide as the whole bar,
  inside a frame clipped to the fill (its corners hung on the game's fill,
  as our fill), so the fill reveals them as it grows and nothing slides or
  stretches. Cropped 1:1 as `ns.Compact` crops a window's band:
  `Theme.BandCoords(w, h, 23)` (rows 23 to 23 + h, the middle of a compact
  header), from the bar's own size (set by Edit Mode), read out of combat
  and never while secret, again on our frame's `OnSizeChanged` (a resize in
  Edit Mode) and each repaint. Wider than the band's 1,024 (the default
  1,189): `BandCoords` clamps at its edge, so the stars stretch about 16%
  across, as a wide window's band does.
- **Inside the outline:** the outline's first pixel lies inside the bar
  (`ns.PaintHairlines`; a thicker border grows outward). The fill, its stars
  and the rested preview are on a frame clipped to the bar less that pixel
  on every side, so the outline shows whole at 0% and at 100%; the ticks and
  marks sit on a frame over them. Polestar's quest XP band (ours on its
  frame) is set one pixel in at the top and bottom; its right end is
  already 2 in.
- **Faded (SetAlpha):** the StatusBar's fill, `Background`, `Underlay`,
  `Overlay`; `BarFrameTexture`; each divider's `BarDividerTexture`. The fill
  is asked again on each repaint (`GetStatusBarTexture`): a new texture
  object would be followed and faded.
- **Text:** `OverlayFrame.Text` in Polestar's `number` face, outlined, at the
  game's size (`H.Face`); when it shows stays the game's.
- **Colours:** experience: Polestar's blue, the HUD's default fill as on
  the unit frames (`H.FillColor`: the header band's `sky`, or the class
  colour with Polestar's "Class colour"), the same while rested (the game
  turns its fill blue then; ours leaves that to the rested preview). Reputation: the watched faction's standing
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
- **Rested experience:** the game's prediction (`ExhaustionLevelFillBar`,
  from the bar's left to the experience plus the rest, sized, shown and
  hidden by `ExhaustionTickMixin:UpdateTickPosition`) and its pip
  (`ExhaustionTick`'s `Normal` and `Highlight`) are faded with SetAlpha; the
  pip keeps its mouse and the game's rest tooltip. Ours: from our fill's end
  (the game's fill's corners) to the prediction's right edge, the bar's full
  height, the portal violet (`dungeon`: apart from the blue fill and the
  green quest XP) at 40% (`REST_ALPHA`), a 1px line along its top and a hairline at its end
  in the full colour; shown while the game's prediction is (no rest, the
  maximum level, XP off: hidden), read on the rest events and with every
  refade. Seen in game before: the game's prediction (green-grey) showed
  through our track and its pip over our fill.
- **Reputation, every state** (`repColor`, as `ReputationStatusBarMixin:Update`
  picks its atlas): renown (`C_Reputation.IsMajorFaction`) and a major
  faction's paragon in the game's blue (`npc`: the game draws them with its
  rested blue), a friendship (`C_GossipInfo.GetFriendshipReputation`) in
  `success` whatever its reaction (the game draws every friendship at
  reaction 5), a normal faction's paragon by its reaction, the rest by
  reaction. The track's tint follows. A paragon reward pending overfills
  the game's bar; ours follows its fill. Watching none: the game hides the
  bar, ours with it; watching one again: dressed in the frame it shows
  (OnShow), recoloured on `UPDATE_FACTION`. "Show status bar 2" and the
  maximum level (the experience bar goes, reputation takes the main
  container) need nothing of their own: every bar of both containers is
  dressed.
- **The other kinds:** honor (the game's orange-red) in `place`; artifact,
  azerite and house favour (the game's one artifact-power gold) in `quest`;
  a token a scheme lacks: the game's hue calmed halfway to `textMuted`. The
  artifact bar's pip (`Tick`: the power for its next trait) faded as the
  rest's, marked by a 2 px accent line of ours while the game shows it; its
  mouse and tooltip the game's. All six exist on Forever (seen in game),
  though .ref loads four for mainline only.
- **Combat:** nothing here is protected (the bars are not secure; ours
  are plain frames and textures). Every value read (the standing, renown,
  friendship, the rest state) goes through `ns.Clean`: secret, the last
  colour stays; no geometry is read in combat (the stars' crop waits).
- **The click:** a left-click on the reputation bar opens our Character
  window on Reputation (`ns.modules.character.Toggle("ReputationFrame")`,
  its own toggle, as its key door calls it); with our Character window off
  it does nothing (the stock bar has no click, and showing the stock window
  from our code would taint it: CLIENT.md rule 8). `HookScript("OnMouseUp")`
  on the stock bar: a script hook, no key written.
- **Polestar's "Completed quest XP"** (Polestar 0.4.2's `QoL/QuestXP.lua`,
  option `qol.questXPOverlay`, on by default; not in 0.4.0, so
  feature-detected: `Polestar.QoL.QuestXP` and its `frame`): a frame of
  Polestar's under the game's XP bar, over its StatusBar, with a sage band
  from the XP fill to the XP the quests ready to hand in will give (masked by
  the game's fill atlas, inset 2), a copy of the game's pip on the rest tick,
  and "+1 level" above. Drawn for the game's bar, it showed over ours in the
  game's look (the "grey-green band" and "+1 level" in game). While ours is
  on: its band emptied (SetTexture(nil): a SetAlpha(0) did not hold in game, the probe read alpha 1 again; Polestar sets its texture only once) and ours drawn on the same span at the bar's full inner
  height, flat, in `success` at 40% (`QUEST_ALPHA`, with 1px lines along its bottom and at its end: the green Polestar's
  sage stands for, apart from our blue fill and violet rested preview); its pip copy
  faded; its label in Polestar's `label` face, outlined, in `success`. Off:
  all of it Polestar's again (its texture and the label's colour as read when first found).
  Hooks, on Polestar's own objects only: `hooksecurefunc(frame.Tint,
  "SetShown")` (its local draw ends every redraw with it) and
  `hooksecurefunc(Polestar.QoL.XPMark, "Bar")` (every refresh calls it
  first; the frame is made on the first refresh with quest XP, so the next
  frame looks for it, until found). Polestar's band inset (2) is undone by
  constant offsets (a `shortcut:` in the code). Its tooltip on the bar stays
  Polestar's.
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
- **Scenes:** `statusbars`, `statusbars-editmode`, `statusbars-off`, `statusbars-rep`, `statusbars-kinds`, `statusbars-questxp` (with `tests/lua/stub_questxp.lua`)
  (`tests/lua/stub_statusbars.lua`, every stock frame and region guarded).
