---
name: stock-to-polestar
description: Plan how to replace or restyle a stock WoW (Forever) window, frame or widget in Polestar: UI. Use before building any new surface or reskin (a Blizzard window, panel, tab strip, list, dropdown, popup, HUD piece): it maps each stock part to the Polestar element already in use, picks replace-vs-restyle, and lists doors, taint and test work. Produces a plan, not code.
---

# Stock to Polestar

Turns "make <stock thing> look like Polestar" into a plan built from parts this
repo already has. Read this file, then `catalog.md` (same folder) for the
part-by-part mapping and the in-place restyle kit.

Paths: **S/** = `.ref/wow-ui-source-forever/Interface/AddOns` (Forever = mainline
family, game type `camelot`; prefer `Mainline/` or `Camelot/` files over
`Classic/`). **P/** = `D:\Projects\polestar\addon\Polestar` (read only):
`P/Theme/Widgets.lua` (W), `P/Theme/Theme.lua` (Theme). **Ours**: `Core.lua`,
`Modules/*.lua`. Cite code by file plus function or frame name, never by line number: grep the
name. `docs/windows/<key>.md` holds each window's catalogue entry.

## Steps

1. **Find the stock source.** Locate the frame's XML/Lua in S/ (grep the
   global name, its template, its toggle). Note: its templates and mixins,
   who shows it (keybinding action, micro button, toggle function, events,
   links, other windows), what its OnShow/OnHide run, and whether other
   code (secure code, other addons) writes into it.
2. **Pick the strategy** (below). Read `docs/DESIGN.md` "The Replacement
   Contract" and the window's entry in `docs/windows/<key>.md` (or its sibling
   windows', when it is new), and `docs/CLIENT.md` (all 15 rules; rules 8, 11, 14,
   15 most often decide it).
3. **Break it into parts** and map each with `catalog.md` section A. Prefer,
   in order: a W/Theme widget, an `ns.*` helper in Core.lua, a pattern
   already in a Module (copy its shape), a new local helper. Never repaint a
   colour by hand: tokens via `Theme.Color`/`W.Color`/`W.Painter`.
4. **Plan doors, taint and tests** with the checklists below.
5. **Write the plan** in the output format. Stop there unless asked to build.

## Strategy: replace or restyle

**Replace with our own window** (default; Character, Spellbook, Talents,
Professions, Crafting, Legacy, World Map): `W.Shell` named `PolestarUI<Name>`,
`ns.Dock`, `ns.WindowMenu`, `Polestar.CloseOnEscape`, `ns.Module(key, M)`
with `Enable`/`Show`/`stock`, opened by `ns.Doors` or a toggle post-hook.
Nothing is added to, hooked on or anchored to the stock frame.

**Restyle the stock frame in place** (Tooltips, Chat): only when other code
writes into the frame, so a replacement would lose their output or taint
secure readers (CLIENT.md rule 15). `ns.Module(key, { noun=..., Enable, Apply })`,
no window, no doors.

Checklist, first "yes" wins:
- Do secure code or other addons write lines/messages/entries into it
  (`AddLine`, `AddMessage`, `TooltipDataProcessor`, `Menu.ModifyMenu`,
  map canvas pins)? -> **restyle in place**.
- Is it pooled/shared by the whole UI (Blizzard_Menu frames, chat bubbles)?
  -> **restyle in place, per tag / per instance** (catalog B).
- Is it `StaticPopup` or a protected dialog (logout, loot)? -> **leave it**;
  only our own windows call `W.Modal`.
- Do its OnShow/OnHide touch secure frames (action bars, micro buttons,
  `UpdateMicroButtons`)? -> **replace, never show/hide the stock one**: doors
  via `ns.Doors` only; shift-click on the micro button opens the stock window
  (rule 8; Spellbook, Talents, Legacy, Professions book).
- Does hiding it end what it shows (trade skill)? -> **replace, stop its
  open at `GameEvent.UnregisterInternalEvent`**, `reloadOff = true` (rule 11,
  `M.Enable` in `Crafting.lua`).
- Does the game open it through doors only its code knows (links, tracker,
  NPC interactions)? -> those doors **stay the game's** (rule 14, World Map).
- Otherwise -> **replace**, closing the stock one with its own `Hide()` in a
  `hooksecurefunc` on its toggle (Contract step 2; `M.Enable` in `Character.lua`,
  including rule 7's "show, not toggle" caller check). Never `HideUIPanel`.

## Doors and taint checklist

Replace:
- [ ] Every stock door listed (Same Doors Rule): binding actions, micro
      button, slash, toggle functions, other windows, links, events.
- [ ] Keys + micro: `ns.Doors(module, name, { ACTION = fn }, MicroButton, onMicro)`
      (`ns.Doors`, `Core.lua`). Override bindings set out of combat; overlay placed by
      position, never anchored (rules 8, 10).
- [ ] Doors only stock code knows: stay the game's; say so in the window's entry.
- [ ] Off is off and live: `ns.Switch` (`Core.lua`), `m.stock` for the
      "Polestar" button above the stock frame, `reloadOff` if routing was
      stopped. Switching refused in combat.
- [ ] Protected actions (cast, use, target slot): `ns.Overlay`
      (`ns.Overlay`, `Core.lua`) secure button, out of combat (rules 4, 9).
- [ ] Combat: values may be secret (rule 3): read out of combat, guard with
      `issecretvalue`, no stock code writing into `W.Text` strings
      (`runStock` in `Character.lua`). Cooldowns via duration objects.
- [ ] Fonts: every FontString via `W.Text` (rule 2).
- [ ] Lists that change with no event: redraw after our own change (rule 6).
- [ ] No frame 0 wide used as an anchor (rule 12): drop a sidebar by
      anchoring `f.Main` to the window (`ns.ProfessionTabs`).
- [ ] Gamepad UI on: module off by default (`ns.Enabled`, Contract step 4).
- [ ] Trait trees: `canPurchaseRank` ignores cost (rule 13).

Restyle in place (rule 15):
- [ ] No Lua key written on the stock frame or its children; no method or
      function replaced; nothing moved, sized, reparented. So **no
      `Theme.Skin`/`Theme.Border`/`W.Hover`-with-state on stock frames**
      (Theme.Skin writes `psSkin`, Theme.Border writes `psBorder`).
- [ ] Our textures in a weak table keyed by frame.
- [ ] Art the game re-alphas (fades) is hidden or emptied, not `SetAlpha`'d;
      copy its alpha onto ours from a driver of our own.
- [ ] Re-apply in `hooksecurefunc` on what resets the style; never replace it.
- [ ] Read no text/value of the frame (secret in combat). Frames others type
      into: no script hooks, read state (`HasFocus`) from our driver.
- [ ] Pooled menus: `Menu.ModifyMenu(tag)` + `AddMenuAcquiredCallback` +
      `menu:AttachTexture()`. Bubbles: `C_ChatBubbles.GetAllChatBubbles()`,
      skip `IsForbidden()`.
- [ ] `M.Apply()` handles on and off (gives back every stock piece), wired to
      `Theme.OnChanged`; `ns.Switch` calls it live.

## Tests checklist

- [ ] Stub what the stock frame/API looks like in `tests/lua/stub_<module>.lua`
      (shape of the real XML: region names, children, the stock functions our
      hooks follow). Client rules shared by all scenes: `tests/lua/stub_client.lua`;
      generic frames: `tests/lua/wow_stub.lua`.
- [ ] Scene(s) as `tests/scenes/<name>.lua`: `--@ title`, `--@ roots`, `--@ stubs`
      and `--@ saved` header lines, then Lua asserts; `--@ panel` starts a further
      panel with its own header. Asserts cover doors (`stub.pressKey`), combat
      (`stub.inCombat`), secrets, the switch off/on, and for restyles that other
      code's lines still show and the stock art comes back off. A new window
      starts from `node tools/new-window.js <key> <StockFrameName>` (module,
      stub, scene and `.toc` line; refuses to overwrite).
- [ ] A new CLIENT.md rule gets a stub check where it can.
- [ ] Bless and compare: `node tools/preview.js <scene>` writes
      `tests/golden/<scene>.svg`; `node tools/preview.js --check <scene>`
      compares one scene without writing; `npm run preview` re-blesses all;
      `npm test` compares everything (a mismatch writes `<scene>.actual.svg`)
      and audits text overflow. SVG ids are stable per file, so a golden diff
      holds only real changes.
- [ ] Look at it: `"/c/Program Files/Google/Chrome/Application/chrome.exe" --headless --disable-gpu --screenshot=<scratch>/x.png --window-size=1400,1000 "file:///D:/Projects/Polestar_UI/tests/golden/X.svg"`
      then Read the PNG.
- [ ] Catalogue entry (with Risk) written before building, in its own file
      `docs/windows/<key>.md` (key = the module key), plus a row (window, risk,
      status, link) in the index table of `docs/DESIGN.md`.

## Output format

```
## Plan: <stock frame> -> Polestar

### Parts
| Stock part (template / S/ pointer) | Polestar element | API + example call site | Risk / gotcha |
|---|---|---|---|

### Strategy
Replace | Restyle in place | Leave stock — and the checklist line that decided it.

### Doors
Each stock door -> ours (ns.Doors / toggle hook / event) or "stays the game's", with the rule.

### Taint and combat
Protected calls, secret values, secure readers, what runs out of combat only.

### Tests
Stubs to add, scenes and their asserts, goldens to bless.

### Open questions
What the source did not settle; what the user must decide (look, Nothing Lost gaps).
```
