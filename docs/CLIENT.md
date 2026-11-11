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

## 11. Hiding the stock crafting window ends the trade skill

**What the source says:** `ProfessionsFrame`'s `OnHide` calls
`C_TradeSkillUI.CloseTradeSkill()` (`Blizzard_ProfessionsFrame.lua`). Closed
under ours the way the other windows are, it would end the trade skill ours
shows, and every recipe read after would come back empty.

**Rule:** a stock window whose hiding ends what it shows is never opened at
all: stop its open where the game routes it
(`GameEvent.UnregisterInternalEvent("TRADE_SKILL_SHOW")` in Crafting.lua) and
open ours on the same event. Ours then closes what the stock window would
(`CloseTradeSkill` as it hides), and closes itself on the game's
`TRADE_SKILL_CLOSE` without closing it again.

**Caught by:** the `crafting` scene (the routing stub records the unregister)
and the `crafting-cooldown` scene (closing ours closes the trade skill once;
the game's close does not close it twice).

## 12. A frame 0 wide has no rect

**What happened:** the Professions window showed its ground and the profession
tabs, nothing else. Its sidebar was set 0 wide (`W.Shell` with `sidebar = 0`)
and hidden; the shell hangs the main column (band, body, footer) off the
sidebar's right edge, and the client gives a frame of no width no rect, so
nothing anchored to it was placed or drawn. The stub placed it anyway.

**Rule:** never anchor anything to a frame of size 0. To drop a shell's
sidebar, anchor `f.Main` to the window itself, past the rail when there is
one (`ns.ProfessionTabs` in Professions.lua).

**Caught by:** the `professions` scene checks the main column is anchored to
the window.

## 13. A trait node's `canPurchaseRank` ignores its cost

**What happened:** twice (Talents, then the Legacy tree), every open talent
showed in full colour with no point to spend. The client's
`canPurchaseRank` says whether a rank could go in, not whether the player
can pay for it; the stock button also checks the cost against the points on
hand (`TalentButtonSpendMixin:CanPurchaseRank`).

**Rule:** a talent can take a point now only when `canPurchaseRank`, its
prerequisites (`meetsEdgeRequirements`) and its cost
(`C_Traits.GetNodeCost` against `GetTreeCurrencyInfo`'s quantities) all
allow it. Colour, the click and the tooltip hint all follow that
(`lit` in Talents.lua, `canTake` in Legacy.lua).

**Caught by:** the stubs' `canPurchaseRank` ignores points as the client's
does; the `talents-spend` and `legacy-tree` scenes check that with no point
left an unlearnt talent is greyed and a click spends nothing.

## 14. Never hide the stock world map after the game opened it

**What the source says:** the game opens `WorldMapFrame` through doors only
its own code knows: quest tracker clicks and "Show on map", world quest and
bonus objective clicks, map, event and world quest links, `/mappin`, the
minimap's zone text, NPC map interactions (`WORLD_MAP_OPEN`, registered on
`WorldMapFrame` itself) and the spirit healer. None goes through `GameEvent`,
and a link handler cannot be registered twice (`LinkUtil`'s `assertsafe`).
The only way to take them is a post-hook that hides the stock map, which runs
`WorldMapMixin:OnHide` as our code: `MapCanvasMixin.OnHide` and every data
provider's `OnHide`, `QuestMapFrame_OnHide`, `OnUIClose`,
`C_Map.CloseWorldMapInteraction` and `UpdateMicroButtons`
(`Blizzard_WorldMap.lua`). That leaves tainted canvas, provider and quest log
state behind, which the stock map's own `OnShow` and pin setup
(`SetPassThroughButtons`) read when the game opens it in combat;
`MaximizeUIPanel` and `RestoreUIPanelArea` do nothing from tainted code; and
the open and close sounds play and the read emote flickers.

**Rule:** take only the doors that run no stock code (keys and the micro
button, `ns.Doors`). Every door only the game's code knows stays the game's,
and opens the stock map; never hide it after the game opened it.

**Caught by:** the map scenes' stub `WorldMapFrame` is only ever shown by the
game's own bindings; no scene hides it.

## 15. A stock frame other code writes into is restyled, never replaced

**What the source says:** `GameTooltip` is filled by secure code (action
buttons, spell flyouts, the world map) and by every addon that adds a line.
A tooltip of ours in its place loses their lines; a stock function or method
replaced, or a key written on the tooltip or its NineSlice, taints what the
secure code reads next.

**Rule:** restyle such a frame only through widget calls that write no Lua
value on it: fade its art's pieces (`SetAlpha` on the NineSlice's pieces),
add textures of our own to it (kept in a weak table keyed by the frame, never
as a key on it), set a status bar's texture or a font object's face. Re-apply
in a post-hook on what resets the style (`hooksecurefunc`
on `SharedTooltip_SetBackdropStyle`, which every hide runs), never by
replacing it. Read no line or value of the tooltip: in combat they can be
secret (rule 3).

Art the game itself fades (the chat windows' ground and border, whose
alpha `FCF_SetWindowAlpha` and the mouse-over fades write) cannot be faded
with `SetAlpha`: the next fade writes over it. Hide the pieces the game only
fades while shown, empty a piece whose alpha must stay live
(`SetTexture(nil)` on the chat ground), and copy its alpha onto ours from a
frame of our own (`Modules/Chat.lua`). A frame other code types into (the
chat edit box: slash commands, macros) gets no script hook; read its state
(`HasFocus`) from our own frame.

**Caught by:** the `tooltips` scene: another addon's hook adds its line, the
look holds through a style reset (embedded and back), and switched off, the
stock art and fonts are back. The `chat` scene: a filtered message and
another addon's `AddMessage` line show, a new whisper window is restyled,
our ground follows the window alpha, and switched off, the stock art is back.

## Reading errors from the game

With !BugGrabber installed, every Lua error and blocked action is saved, with
its stack, on `/reload` or logout to:

`D:\Battle.net\World of Warcraft\_forever_\WTF\Account\JAMESWHAT1\SavedVariables\!BugGrabber.lua`

Each entry carries a `session` number; only the newest session's entries are
new.
