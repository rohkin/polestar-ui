# Polestar: UI

WoW (Forever client) addon: replaces stock Blizzard windows with Polestar's kit (`Polestar.Widgets`, `Polestar.Theme`). Lua 5.1, tested in Node under a client stub. Depends on the Polestar addon.

## Layout
- `Polestar_UI.toc`: load order is `Core.lua`, then `Modules/*` (CharacterPages, Character, Spellbook, Talents, Professions, Crafting, Legacy, WorldMap.xml, Tooltips, Chat). A new window goes before Tooltips. `Modules/QuestLog.lua` is not in the .toc (loaded by `WorldMap.xml`).
- `docs/CLIENT.md`: client rules learnt from bugs (taint, secret values, secure buttons, doors). MANDATORY reading before any surface work; this file does not repeat them.
- `docs/DESIGN.md`: shared sections (Replacement Contract, Shell, Components) plus the window index. Each window's entry: `docs/windows/<key>.md`.
- `.claude/skills/stock-to-polestar`: the process for a new window or reskin (produces a plan).
- `.ref/wow-ui-source-forever`: stock Blizzard sources. Grep only.
- Polestar itself: `../polestar` or `$POLESTAR_DIR` (`addon/`, shared stubs in `tests/lua/`).
- `tests/scenes/*.lua` + `tests/golden/*.svg`: one scene per rendered state. `tests/lua/stub_<key>.lua`: the client's stock frame for a window. `tools/preview/stub.lua`: the preview's extra stub.

## Commands
- `npm test`: every scene must render byte-identical to its golden, no text overflow.
- `npm run preview`: render all scenes into `tests/golden` (blesses them; run only for an intended change).
- `node tools/preview.js <scene>...`: render only those scenes (blesses them).
- `node tools/preview.js --check <scene>`: compare only, exit 1 on a mismatch; a failure writes `<scene>.actual.svg` (gitignored).
- `node tools/new-window.js <key> <StockFrame>`: writes `Modules/<Key>.lua`, `tests/lua/stub_<key>.lua`, `tests/scenes/<key>.lua`, the .toc line, and `docs/windows/<key>.md` (a TODO stub, if missing). Never overwrites.
- `npm run link` / `npm run unlink`: junction the repo into the WoW Forever AddOns folder (`$WOW_FOREVER_ADDONS` or autodetected); unlink removes only a junction.
- Needs Node 24+, a Lua 5.1 (luajit works; `LUA=` overrides), and Polestar at `../polestar`.
- Worktree gotcha: `tests/helpers/lua.js` finds the TOC by folder name, so the checkout folder must be named `Polestar_UI`.

## Never read
- `tests/golden/*.svg` (up to 210 KB, huge lines). Use `--check` and `git diff --stat`.
- `LICENSE`; `.ref` except by grep; the Polestar stubs whole (`wow_stub.lua` is 1,300+ lines: grep for the function).

## Core API (`ns` = `PolestarUI`; all in `Core.lua`)
Modules and state
- `ns.Module(key, m)`: registers `{Enable, Show, stock, reloadOff, Apply, noun}`; key is its `/pui` name.
- `ns.Enabled(key)`: module on (saved choice, else on unless gamepad UI). `ns.Show(key, ...)`: calls `m.Show`.
- `ns.Switch(key, on)`: window Polestar's or the game's, live (not in combat); `reloadOff` modules wait for /reload.
- `ns.WindowMenu(f, key)`: the "..." menu ("Use game window") left of Close; sets `m.psFrame`.
Docking
- `ns.Dock(f)`: lays the window out as the stock panel manager does (the default); `ns.Docked()`, `ns.SetDocked(on)`, `ns.Relayout()`.
- `ns.DockFlyout(f, fly, overlap)`: a flyout outside a docked window's right edge counts in its width.
- `ns.LinkPlace(win)` (Professions.lua): windows sharing a `psDockGroup` swap in place.
Doors and secure parts
- `ns.Doors(module, Name, {BINDING = fn}, microButton, onMicro)`: override-binding clicks plus a secure button over the micro button (shift-click = stock window).
- `ns.Interaction(key, types, o)`: NPC window takes the interaction; `o = {frame, close, internal = {events}, bags}`; call from Enable; does nothing without the interaction manager (preview scenes without NPC stubs).
- `ns.Overlay(name, o)`: one secure button over a hovered target; `o = {enter, pickup, attrs, stale?, setup?}`; returns `place(t)`.
Shell pieces
- `ns.Plain(f)`: a shell made with `sidebar = 0` loses its sidebar; `f.Main` hangs off the window.
- `ns.OptionsButton(f, items)`: the band's Options button; `items` = menu items, or `function(button)` returning them.
- `ns.Flyout(f, name, width)`: window-skinned panel on `f`'s right edge; caller hides it and calls `ns.DockFlyout`.
Widgets
- `ns.GameIcon(parent, layer)`: texture cropped of the client's icon border.
- `ns.ItemWell(parent, size, kind?)`: inset icon well; returns `well, icon` (`well.Icon`).
- `ns.PaintItem(w, it)`: `it = {icon, quality, count, desat, unusable}` (nil empties); quality border from uncommon up.
- `ns.ItemGrid(parent, cols, size, gap)`: frame; `grid.Layout(n)` shows n wells, returns them, fits height.
- `ns.QualityRGB(q)`: item quality as r,g,b or nil.
- `ns.SubjectBlock(f)`: sidebar head replacing Polestar's lockup; returns `{icon, name, line}`.
- `ns.Coins(copper)`: coins as plain text ("1g 2s 3c") for labels and dialogs.
- `ns.Money(parent)` / `ns.SetMoney(m, copper, colorToken?)`: coin line as `GetMoneyString` writes it.
- `ns.TextField(parent, w, letters?)`: one-line edit box (Enter and Escape leave it).
- `ns.SetEnabled(button, on)`: enable and fade to 45% as Polestar does.
- `ns.QuestRewards(parent, {x, width, tip, click, selected?})`: pooled text and reward tiles shared by Quest dialog and quest log; `c.Begin(y)`, `c.text/head/pair/tile`, `c.Rewards(id, d)`, `c.End()`, `c.y`.
- `ns.MoneyInput(parent, onChange(copper))`: g/s/c fields; `m.Set(copper)`.
- `ns.Stepper(parent, {get, set, max})`: -, count, +, Max; caller calls `s.Paint()` after its own changes.
- `ns.ModalWith(spec, body)`: `W.Modal(spec)` with our frame (stepper, input) under its text.
- `ns.TooltipHint(text)`: textMuted hint line ending the shown tooltip.
Values
- `ns.Clean(v)`: nil if secret (combat). `ns.Num(v)`: 0 if secret. `ns.GridCell(list)`: smallest grid step of positions (sorts the list).
Slash: `/pui` lists windows, `/pui <key> [on|off]`, `/pui dock on|off`.

## Test API (scene globals: `stub`, `PolestarUI`, `Polestar`, `assert`)
Generic (Polestar `wow_stub.lua`, `stub_ui.lua`; `stub_client.lua`)
- `stub.pressKey("F9")`: override binding's button click, else the game's binding (`stub.bindings[action]`, `stub.bindingRun[action]`).
- `stub.fire(event, ...)`: fire an event on every frame registered for it.
- `stub.advance(sec)`: step time (0.05 s) running timers and OnUpdates.
- `stub.RunScript(frame, "OnTextChanged", ...)`: run a frame's script and hooks (type text, click: `stub.RunScript(btn, "OnClick")`).
- `stub.inCombat = true`: `InCombatLockdown()` answers it. `stub.keys.shift = true`: `IsShiftKeyDown()`.
- `stub.cvars.<name> = "1"`; `stub.messages`: chat lines printed; `stub.frame(name)`; `stub.SECRET`: a secret value.
- `stub.openMenu(owner, tag, labels)` / `stub.closeMenu()`, `stub.chatEvent`, `stub.activateChat`, `stub.makeChat`, `stub.chatBubble(name, text, x, y, forbidden)`, `stub.openOverflow()`, `stub.loadCombatLog()`, `stub.withShoppingTooltip()`: chat/tooltip scenes (`stub_chat.lua`, `wow_stub_local.lua`).
Per window (set before `Show`, read after)
- Crafting: `stub.openTradeSkill()` (TRADE_SKILL_SHOW then list update), `stub.enchanting = true`, results in `stub.crafted = {id, n}`, `stub.enchanted = {id, n, guid}`, `stub.closed`, `stub.unrouted[event]`.
- NPC (`stub_npc.lua`): `stub.interact(type)`, `stub.endInteraction(type)`, `stub.npcClosed[CloseFn]` counts (`CloseMerchant`, `CloseTrainer`, `CloseMail`, `C_Bank.CloseBankFrame`), `stub.bagsOpen`/`stub.bagsOpener`, `stub.money`, `stub.bag`, `stub.unrouted[event]`.
- Character: `stub.secretStats`, `stub.targeting`, `stub.cursorFits[slot]`. Spellbook: `stub.pet`, `stub.linked`. Talents: `stub.dual`, `stub.noPoints`, `stub.finishCommit()`.
- Legacy: `stub.treePoints`, `stub.searched`, `stub.tracked`, `stub.modified`, `stub.finishLegacyCommit()`. World Map: `stub.watched`, `stub.abandoned`, `stub.shared`, `stub.inGroup`, `stub.xpMax`, `stub.maxLevel`, `stub.trivialOut`, `stub.caveListed`, `stub.chatOpen`. Professions: `stub.abandoned`.
Scene file: leading `--@ key: value` lines (`title`, `roots` = frames drawn, `stubs` = files in `tests/lua`, `saved` = saved-variable Lua); the rest is Lua run after login. `--@ panel` starts another panel (own roots/stubs/saved header). Asserts fail the scene.
```lua
--@ title: Spellbook: search
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
PolestarUI.Show("spellbook")
PolestarUISpellbook.Search:SetText("fire"); stub.RunScript(PolestarUISpellbook.Search, "OnTextChanged")
assert(PolestarUISpellbook:IsShown(), "closed")
```

## A new window touches
Module (`Modules/<Key>.lua`), `tests/lua/stub_<key>.lua`, `tests/scenes/<key>*.lua` (+ blessed goldens), a `.toc` line, `docs/windows/<key>.md` with its row in the DESIGN.md index, and `CHANGELOG.md`. The scaffold does the first four (and a stub doc); the real doc and CHANGELOG are yours.

## Conventions
- Commits: one imperative sentence, subject line only, one logical change each (e.g. "Add a window scaffold script ..."). No body, no attribution trailer.
- Module skeleton (copy `Modules/Spellbook.lua`): `local ADDON, ns = ...; local W = Polestar.Widgets`; `build()` = `W.Shell(NAME, {scalePath = "ui.menuScale"})`, `ns.Dock(f)`, `ns.WindowMenu(f, key)`, `Polestar.CloseOnEscape(NAME)`; `refresh()` = `W.ShellNav/Title/Tabs/Footer/Body`; `M.Show/Toggle`; `M.Enable()` calls `ns.Doors` and registers events; `M.stock()` returns the stock frame when shown; `ns.Module(key, M)`.
- Never touch the stock window (no show/hide/hook/anchor): the stock one is closed or never opened (CLIENT.md rules 1, 8, 10).
- Switching a module off that stopped stock routing (`reloadOff`) takes effect "after /reload"; say so in text and tests.
- Feature-detect Polestar exports and ship without them until they exist, e.g. `if Polestar.MapCanvas and Polestar.MapCanvas.Add then ...` (WorldMap).
- Intended visual change: run `npm run preview`, check `git diff --stat tests/golden`, commit goldens with the change.
