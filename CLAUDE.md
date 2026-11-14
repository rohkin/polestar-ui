# Polestar: UI

WoW (Forever client) addon: replaces stock Blizzard windows with Polestar's kit (`Polestar.Widgets`, `Polestar.Theme`). Lua 5.1, tested in Node under a client stub. Depends on the Polestar addon.

## Layout
- `Polestar_UI.toc`: load order is `Core.lua`, then `Modules/*` (CharacterPages, Character, CharacterGear, CharacterDetails, Spellbook, Talents, Professions, Crafting, Legacy, WorldMap.xml, Bank, Mail, Gossip, Merchant, Trainer, QuestDialog, Loot, Social, Auction, Guild, Macros, Inspect, HUD, UnitFrames, Minimap, ActionBars, Auras, CastBars, CooldownViewer, ResourceDisplay, DamageMeter, Tooltips, Chat). A new window goes before Tooltips. `Modules/QuestLog.lua` is not in the .toc (loaded by `WorldMap.xml`).
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
- `node tools/release.js [version|patch|minor] [--push] [--dry-run]`: cut a release; see the release skill.
- `npm run link` / `npm run unlink`: junction the repo into the WoW Forever AddOns folder (`$WOW_FOREVER_ADDONS` or autodetected); unlink removes only a junction.
- In-game screenshots (dev addon `tools/shots/Polestar_UI_Shots`, never shipped: `.pkgmeta` ignores `tools`): `npm run link:shots` (junction, as `link`; `unlink:shots`). In game, `/puishots` or left-click its button on the minimap's left edge: every window and page Polestar: UI opens on its own, then the plain HUD (NPC windows skipped); `/puishots <key>`, `/puishots hud` (right-click). At the end a modal offers Reload, which writes the list. `npm run shots [-- --dry-run]` copies the last run into `screenshots/game/<run>/<key>-<page>.png` and `screenshots/game/latest/` (gitignored); `npm run shots:watch` does each new run once as its list lands and prints `SHOTS <n> files -> screenshots/game/<run>/` (tail it, then read `latest/`).
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
- `ns.WindowMenu(f, key, options?)`: the "..." menu left of Close: `options` (menu items, or `function(button)` returning them) first, a divider, then "Use game window"; sets `m.psFrame`, `f.psMenu`. A window has no other Options button.
Docking
- `ns.Dock(f)`: lays the window out as the stock panel manager does (the default); `ns.Docked()`, `ns.SetDocked(on)`, `ns.Relayout()`.
- `ns.DockFlyout(f, fly, overlap)`: a flyout outside a docked window's right edge counts in its width.
- `ns.LinkPlace(win)` (Professions.lua): windows sharing a `psDockGroup` swap in place.
Doors and secure parts
- `ns.Doors(module, Name, {BINDING = fn}, microButton, onMicro)`: override-binding clicks plus a secure button over the micro button (shift-click = stock window).
- `ns.Interaction(key, types, o)`: NPC window takes the interaction; `o = {frame, close, internal = {events}, bags, events = {show, hide}}` (events: fallback open/close on game events, once even if both fire); call from Enable; does nothing without the interaction manager (preview scenes without NPC stubs).
- `ns.Overlay(name, o)`: one secure button over a hovered target; `o = {enter, pickup, attrs, stale?, setup?}`; returns `place(t)`.
Shell pieces
- `ns.Plain(f, left?)`: a shell made with `sidebar = 0` loses its sidebar and Polestar's emblem; `f.Main` hangs off the window, `left` past its edge (a rail's width).
- `ns.Footer(f, left, right)`: `W.ShellFooter` with every reused footer button back on at full alpha; use it, never `W.ShellFooter`, then grey your own with `ns.SetEnabled`.
- `ns.Compact(f)` (after `ns.WindowMenu`): the compact grid: 60 band (Display title, one-line subtitle), 36 tabs (skin's if less), 44 footer, pad `f.psPad` (24; skin's pad less 8: lay content out by it, not `W.SHELL.pad`); band art re-cropped; post-hooks on `W.ShellTabs/ShellFooter/ShellBody` keep `f.BodyWidth`, `f.psViewH` and the tabs/footer on it.
- `ns.TopNav(f, items, active, onSelect)`: page nav as top tabs, no sidebar (`ns.Plain`); items `{key, label, icon (game texture), count, dot, locked, tip}` (locked: receding, click ignored, `tip` in its tooltip); `f.Search` and `f.psFilter` (make it on `f.TabRow` before) at the tab row's right end; `active` nil marks none.
- `ns.GameRail(win, items, active, onSelect, opts?)`: `W.ShellRail` with each item's game icon (`icon`, 24px, untinted, cropped), then `ns.Plain` off the rail when the sidebar is hidden (Professions, Character); `opts.slim`: a 48px icon-only rail, labels in tooltips.
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
- `ns.SetEnabled(button, on, why?)`: enable and fade to 45% as Polestar does; `why`, the reason a disabled one shows in its tooltip. A `W.Switch` too (through `W.SetDisabledWhen`; `why` is its tooltip while off).
- `ns.Pickup(fn, ...)`: `fn(...)` unless a spell waits for its item (`SpellIsTargeting`); every bag, bank or window-slot pickup goes through it. No combat block.
- `ns.QuestRewards(parent, {x, width, tip, click, selected?})`: pooled text and reward tiles shared by Quest dialog and quest log; `c.Begin(y)`, `c.text/head/pair/tile`, `c.money(label, copper, color?)` (coins, `ns.Money`), `c.Rewards(id, d)` (`d.chooseItems`: "Choose your reward:" on the complete step), `c.End()`, `c.y`.
- `ns.NpcPortrait(f)`: the NPC portrait well and title in a shell band; returns `paint(unit)`. Shared by Gossip and Quest dialog.
- `ns.FriendshipBar(parent)`: friendship NPC standing (icon, rank, Skill Bar, tooltip); `b.Paint()` shows or hides it. Shared by Gossip and Quest dialog.
- `ns.MoneyInput(parent, onChange(copper))`: g/s/c fields; `m.Set(copper)`.
- `ns.Stepper(parent, {get, set, max})`: -, count, +, Max; caller calls `s.Paint()` after its own changes.
- `ns.ModalWith(spec, body)`: `W.Modal(spec)` with our frame (stepper, input) under its text. `ns.CloseModal(spec)`: closes Polestar's dialog while it still shows `spec` (a window's own dialog, from its OnHide).
- `ns.TooltipHint(text)`: textMuted hint line ending the shown tooltip.
Restyle kit (art of ours on a stock frame, CLIENT.md rule 15; Tooltips, Chat)
- `ns.FadeNine(holder, a)`: the NineSlice pieces keyed on `holder` at alpha `a`.
- `ns.Hairlines(f, rel, make?)`: four hairline textures on `f` round `rel` (top, bottom, left, right; `make()` supplies them on a pooled menu); `ns.PaintHairlines(e, on, r, g, b, a)` shows, colours and sizes them to one pixel.
- `ns.PaintGround(fill, on, k?)`: `bg` at `Theme.GroundAlpha()` times `k` (0.85 = the tooltip look).
HUD kit (`ns.HUD`, `Modules/HUD.lua`; takes secret values, follows every scheme and skin)
- `H.Bar(parent)` (StatusBar on a progress track; `H.SetBarColor(b, r, g, b)`), `H.Segment(bar, token, alpha, back?)` (continues a fill, or eats into it from its end), `H.Text(parent, role, color)` (outlined; set values with SetFormattedText only), `H.Ground(f)`/`H.PaintGround(g, alpha, r?, g?, b?, a?)`, `H.Portrait(parent)`/`H.SetPortrait(p, unit)` (square 3D well).
- `H.Face(fontString, role, on)` (a stock font string in Polestar's face, outlined, at the game's size; off gives it back), `H.GroundAlpha()` (the unit frames' Background opacity), `H.FillTexture()`.
- `H.ClassColor(unit)` (nil while secret), `H.UnitColor(unit)` (theme accent, class colour with Polestar's "Class colour", danger/warning by reaction), `H.PowerColor(unit)`.
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
- `geterrorhandler()` records into `stub.errors` (it does not raise); every scene ends with `stub.assertNoErrors()`, so an error Polestar catches (a module's Enable, any event handler) fails it (`tests/errors.test.js`).
- `stub.cvars.<name> = "1"`; `stub.messages`: chat lines printed; `stub.frame(name)`; `stub.SECRET`: a secret value.
- `stub.openMenu(owner, tag, labels)` / `stub.closeMenu()`, `stub.chatEvent`, `stub.activateChat`, `stub.makeChat`, `stub.chatBubble(name, text, x, y, forbidden)`, `stub.openOverflow()`, `stub.loadCombatLog()`, `stub.withShoppingTooltip()`: chat/tooltip scenes (`stub_chat.lua`, `wow_stub_local.lua`).
Per window (set before `Show`, read after)
- Crafting: `stub.openTradeSkill()` (TRADE_SKILL_SHOW then list update), `stub.enchanting = true`, results in `stub.crafted = {id, n}`, `stub.enchanted = {id, n, guid}`, `stub.closed`, `stub.unrouted[event]`.
- NPC (`stub_npc.lua`): `stub.interact(type)`, `stub.endInteraction(type)`, `stub.npcClosed[CloseFn]` counts (`CloseMerchant`, `CloseTrainer`, `CloseMail`, `C_Bank.CloseBankFrame`), `stub.bagsOpen`/`stub.bagsOpener`, `stub.money`, `stub.bag`, `stub.unrouted[event]`.
- Character: `stub.secretStats`, `stub.targeting`, `stub.cursorFits[slot]`. Spellbook: `stub.pet`, `stub.linked`. Talents: `stub.dual`, `stub.noPoints`, `stub.finishCommit()`.
- Legacy: `stub.treePoints`, `stub.searched`, `stub.tracked`, `stub.modified`, `stub.finishLegacyCommit()`. World Map: `stub.watched`, `stub.abandoned`, `stub.shared`, `stub.inGroup`, `stub.xpMax`, `stub.maxLevel`, `stub.trivialOut`, `stub.caveListed`, `stub.chatOpen`. Professions: `stub.abandoned`.
- Unit frames (`stub_unitframes.lua`, loaded for every scene): `stub.units[unit] = {name, level, class, player, reaction, classification, health, max, power, powerMax, powerType, heals, absorbs, healAbsorbs, dead, ghost, offline, tapped, threat}` (values come back as `stub.secret(v)`; `stub.reveal(v)`), `stub.unitWatch()` (re-runs the unit watch and state drivers), `stub.vehicle`, `stub.inRaid`, `stub.raidStyleParty`, `stub.updateParty()`, `stub.updateBosses()`; Edit Mode: `stub.enterEditMode()`, `stub.exitEditMode()`, `stub.moveSystem(frame, x, y, scale?)`, `stub.applyLayout({[frame] = {x, y, scale}})`, `stub.showPartyInEditMode`. Rule 16 calls on a stock unit frame and protected calls in combat error.
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
- Module skeleton (copy `Modules/Spellbook.lua`): `local ADDON, ns = ...; local W = Polestar.Widgets`; `build()` = `W.Shell(NAME, {scalePath = "ui.menuScale", width, height})`, `ns.Dock(f)`, `ns.WindowMenu(f, key)`, `ns.Compact(f)`, `Polestar.CloseOnEscape(NAME)`; `refresh()` = `ns.TopNav` (or the slim `ns.GameRail`), `W.ShellTitle`, `ns.Footer`, `W.ShellBody`; `M.Show/Toggle`; `M.Enable()` calls `ns.Doors` and registers events; `M.stock()` returns the stock frame when shown; `ns.Module(key, M)`.
- Page nav = the stock window's tabs, on the compact grid (`ns.Compact`), no sidebar: stock text tabs (Talents, Spellbook, Character, Inspect, Social, Bank, Macros, Mail, Merchant, Trainer) are top tabs (`ns.TopNav`, the stock tab icon on a tab where it has one, search+filter on the tab row); stock icon side-tabs (Guild, Professions/Crafting, Legacy) are a slim rail (`ns.GameRail(..., { slim = true })`, labels in tooltips). The subject (name, class, level, NPC) leads the subtitle, never a sidebar block. No `W.ShellNav` sidebar in a new window.
- Never touch the stock window (no show/hide/hook/anchor): the stock one is closed or never opened (CLIENT.md rules 1, 8, 10). Unit frames: the stock ones stay as Edit Mode's proxies, only veiled (rule 16).
- Switching a module off that stopped stock routing (`reloadOff`) takes effect "after /reload"; say so in text and tests.
- Feature-detect Polestar exports and ship without them until they exist, e.g. `if Polestar.MapCanvas and Polestar.MapCanvas.Add then ...` (WorldMap).
- Intended visual change: run `npm run preview`, check `git diff --stat tests/golden`, commit goldens with the change.
