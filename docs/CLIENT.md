# Client rules

What Forever's client does that the preview stub did not, each learnt from a
bug that reached the game. Read this before building a new surface; when a new
rule is learnt, add it here and, where it can be, to the preview
(`tests/lua/stub_client.lua` or a scene in `tools/preview.js`) so the tests
catch it next time.

The design side of replacing stock frames is in [DESIGN.md](DESIGN.md), "The
Replacement Contract".

## 1. Never `HideUIPanel` from addon code

**What happened:** the Character window opened beside the stock one.
`HideUIPanel` hands managed panels to `FramePositionDelegate`, a forbidden
frame; from addon code the call silently does nothing.

**Rule:** close a stock panel with its own `Hide()`. The panel manager repairs a
panel hidden that way before it places the next one (`RepairUIPanelState` in
`UIParentPanelManager.lua`).

**Caught by:** nothing automatic (the stub has no panel manager); the live check
for every replaced window is "the stock one does not show, and other panels do
not move aside".

## 2. A font string needs a font before it takes text

**What happened:** the Character window stopped opening. A font string made
with a bare `CreateFontString()` was handed to a stock function that called
`SetText` on it; the client errors "Font not set".

**Rule:** make every font string with `W.Text` (it sets the font). Do not pass
our frames into stock functions to borrow a value when the stock code's own
inputs give it (`itemLevel()` reads `GetAverageItemLevel` itself).

**Caught by:** `stub_client.lua` errors on `SetText` without a font, and its
`GetFont` returns nil when none is set, as the client does.

## 3. Secret values in combat

**What happened:** errors opening the Stats tab in combat, in three places:
stock stat maths on a secret number (`MovementSpeed_OnUpdate`), our compare of
a secret `numericValue`, and Polestar's text hook reading secret text a stock
function wrote into our string.

**Rule:** in combat many game values are secret, and any code our addon calls
(stock functions included) may not do maths, compare or read them. So in
combat:
- do not run stock computation from our code; show values read out of combat;
- read those values in the background while out of combat, so a window first
  opened mid-fight still has them, and read again on `PLAYER_REGEN_ENABLED`;
- guard anything that may still be secret with `issecretvalue` before
  comparing it;
- never let stock code write into our `W.Text` strings in combat: Polestar's
  font hook reads the text.

`pcall` is not enough: a stock function can succeed and leave secret values
behind, and an error inside a secure hook escapes it.

**Caught by:** the `character-stats-combat` scene (a stub stat that errors in
combat; the tab is first opened mid-fight and must show every stat).

## 4. Protected calls in combat are blocked, and `pcall` does not stop that

**What happened:** `ADDON_ACTION_BLOCKED` from Polestar_Mob_Markers:
`SetPassThroughButtons` on a map marker made mid-fight.

**Rule:** before any call the client protects in combat (frame mouse and
passthrough setup on frames near secure ones, `SetAttribute`, showing or moving
secure frames), check `InCombatLockdown()` and queue it for
`PLAYER_REGEN_ENABLED`. The block is an event, not a Lua error.

**Caught by:** nothing automatic yet; BugGrabber in game.

## 5. Stock scenes are tuned for stock frames

**What happened:** the character model clipped (a troll) and could not zoom out.

**Rule:** reuse the stock setup (`ModelSceneUtil.SetUpCharacterSheetScene` on
our own `PanningModelSceneMixinTemplate` frame) so every race and form is
framed by the game, then adjust only what our frame's shape changes (the zoom
distances in `showModel`).

**Caught by:** nothing automatic (the preview draws no 3D models); check a tall
race in game.

## Reading errors from the game

With !BugGrabber installed, every Lua error and blocked action is saved, with
its stack, on `/reload` or logout to:

`D:\Battle.net\World of Warcraft\_forever_\WTF\Account\JAMESWHAT1\SavedVariables\!BugGrabber.lua`

Each entry carries a `session` number; only the newest session's entries are
new.
