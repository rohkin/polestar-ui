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
inputs give it.

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
- never let stock code write into our `W.Text` strings, in combat or out:
  Polestar's font hook reads the text, and values can be secret out of combat
  too (seen from a background stat read). Stock functions write into a hidden
  row on a game font (`runStock` in Character.lua); only what is not secret
  is copied over.

`pcall` is not enough: a stock function can succeed and leave secret values
behind, and an error inside a secure hook escapes it.

Cooldown times are secret in combat, and `Cooldown:SetCooldown` refuses them
from addon code. Draw a spell's sweep from its duration object
(`C_SpellBook.GetSpellBookItemCooldownDuration` into
`SetCooldownFromDurationObject`), which carries them without our code
reading them (`paintCooldown` in Spellbook.lua).

The player's own name (`UnitName("player")`, `UnitPVPName`) is secret in
combat too: `GameTooltip:SetText` refuses it. Read it through `playerText`,
which keeps the last name read out of combat.

**Caught by:** the `character-stats-secret` scene (stats turn secret out of
combat; the rows keep what they read) and the `character-stats-combat` scene (a stub stat that errors in
combat; the tab is first opened mid-fight and must show every stat).

## 4. Protected calls in combat are blocked, and `pcall` does not stop that

**What happened:** `ADDON_ACTION_BLOCKED` from Polestar_Mob_Markers:
`SetPassThroughButtons` on a map marker made mid-fight.

**Rule:** before any call the client protects in combat (frame mouse and
passthrough setup on frames near secure ones, `SetAttribute`, showing or moving
secure frames), check `InCombatLockdown()` and queue it for
`PLAYER_REGEN_ENABLED`. The block is an event, not a Lua error.

Some calls are not blocked but forbidden outright from addon code, in or out
of combat: `PickupInventoryItem` while a spell waits for its item (an enchant,
a sharpening stone, an armor kit) is applying that spell, and
`UseInventoryItem` (right-click use) is protected. Hand those to the client's
secure code (a `SecureActionButtonTemplate` button: `*target-slot*` for the
targeting, which the game gates on `SpellCanTargetItem`, and the `item` type for
use), on a button kept off our windows: a window with secure children cannot be
hidden in combat. Place it out of combat over the hovered slot, hand its other
clicks and drags back to the slot, and hide it on `PLAYER_REGEN_DISABLED`
(`overSlot` in Character.lua). Give it a strata above the window's: in the same
strata, a level higher, the game still handed the mouse to the slot under it.

**Caught by:** nothing automatic for blocked calls; BugGrabber in game. The
`character-enchant` scene checks the secure button lands on the hovered slot, with use only on
a filled one.

## 5. Stock scenes are tuned for stock frames

**What happened:** the character model clipped (a troll) and could not zoom out.

**Rule:** reuse the stock setup (`ModelSceneUtil.SetUpCharacterSheetScene` on
our own `PanningModelSceneMixinTemplate` frame) so every race and form is
framed by the game, then adjust only what our frame's shape changes (the zoom
distances in `showModel`).

**Caught by:** nothing automatic (the preview draws no 3D models); check a tall
race in game.

## 6. Not every client list says when it changes

**What happened:** folding a Currency group did nothing until something else
redrew the page. `C_CurrencyInfo.ExpandCurrencyList` sends no event, unlike
the reputation and skill lists (`UPDATE_FACTION`, `SKILL_LINES_CHANGED`).

**Rule:** after any change we make through the client (fold, watch, select),
redraw at once (`fold` in CharacterPages.lua); never rely on an event to
come back. And a click area covers everything that looks clickable: a glyph in
the gutter sits outside its heading's frame.

**Caught by:** the `character-currency-folded` scene (its stub folds without an
event; the scene clicks the chevron's click area).

## 7. The game opens stock frames for its own reasons, through toggles

**What happened:** starting an enchant from the bags closed the Character
window. The game opens the sheet for a spell waiting on an item
(`ShowCharacterFrameIfMatchesContext`); it checks the stock frame, finds it
hidden (ours replaced it), and calls `ToggleCharacter`, which our hook took as
"close".

**Rule:** a replacement's toggle hook must tell the player's toggle from the
game's "show it". Where the game calls the toggle to show, treat it as
`onlyShow` (the hook in Character.lua reads `debugstack` for that caller).

**Caught by:** the `character-enchant-open` scene.

## 8. Hiding a stock window runs its OnHide as ours

**What happened:** `ADDON_ACTION_BLOCKED` on `MultiBarBottomLeft:SetFrameStrata()`
opening talents in combat, blamed on Polestar_UI, and a talent window that
would not close. The Spellbook and Talents doors closed `PlayerSpellsFrame`
with `Hide()` out of combat; its `OnHide` then ran as our code and wrote the
action bars' grid state (`MultiActionBar_HideAllGrids`: `showAllButtons` on
every bar and button). In combat the stock window's own `OnShow` read those
values, its execution was tainted, and the action bar call was blocked.

**Rule:** never show or hide a stock window whose show/hide scripts touch
secure frames (`PlayerSpellsFrame` does: action bars, micro buttons). Open
ours from doors that run no stock code (`ns.Doors` in Core.lua): its keys as
override bindings to a button of ours (set out of combat), and a secure button
of ours over its micro button, whose shift-click clicks the micro button from
secure code for the stock window. Opening the stock window from our own code
(a menu entry calling `PlayerSpellsUtil`) taints it the same way: point the
player to the shift-click instead. Doors that only the stock code knows (a
spell or talent link, a new-spell toast) stay the game's.

**Caught by:** the `spellbook` and `talents` scenes: the stub's
`PlayerSpellsFrame:Hide()` errors when addon code calls it, the keys go
through override bindings (refused in combat), and the micro overlay is
checked.

## 9. Hiding a drag's source ends the drag

**What happened:** a spell dragged from our Spellbook stayed on the cursor
when released over an action bar; it took a click on the slot to place it.
The secure button over the hovered row hid itself on `OnLeave`, which fires as
soon as the drag leaves the row, and a hidden source ends the drag before the
release reaches the bar.

**Rule:** a frame a drag can start from stays shown until `OnDragStop`; hide
it then if the mouse has left.

A drag starts a few pixels after the press, often already over the next
row. A button that moves between rows on hover must stay on the pressed row
from `OnMouseDown` until release, and drag the pressed row's spell. Otherwise
a fast drag takes the next row's spell, or nothing.

Both live in `ns.Overlay` (Core.lua), which the Spellbook rows and the
Character gear slots share: build any new hover button with it.

**Caught by:** nothing automatic (the stub has no drag and drop); drag a spell
or a worn item and release it in game.

## 10. Anchoring a secure frame to a frame protects that frame

**What happened:** `ADDON_ACTION_BLOCKED` on `ProfessionMicroButton:Enable()`
in combat, blamed on another addon (OpenMap) whose map toggle ran the game's
`UpdateMicroButtons`. Our secure overlay was anchored to the micro button
(`SetAllPoints`), which made the micro button protected, so the game's own
`Enable()` of it was blocked whenever tainted code led there.

**Rule:** never anchor a secure frame of ours to a Blizzard frame. Place it
by position, relative to `UIParent`, out of combat (`ns.Doors` in Core.lua
copies the micro button's rect each frame it changes).

**Caught by:** the `talents` scene checks the overlay is not anchored to the
micro button and still covers it.

## Reading errors from the game

With !BugGrabber installed, every Lua error and blocked action is saved, with
its stack, on `/reload` or logout to:

`D:\Battle.net\World of Warcraft\_forever_\WTF\Account\JAMESWHAT1\SavedVariables\!BugGrabber.lua`

Each entry carries a `session` number; only the newest session's entries are
new.
