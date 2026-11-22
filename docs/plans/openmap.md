# OpenMap on our World Map (parked, 2026-11-22)

Goal: OpenMap's map (stitched art, pins, notes, routes) inside our World Map window, so we don't depend on per-addon hooks.

## Where things stand
- OpenMap (v0.8.12, MIT, https://github.com/openmap-world/openmap) takes over `WorldMapFrame` itself. It hard-codes `_G.WorldMapFrame` (`Map\WorldMap.lua:1444`, `:1837`, `PadView.lua:1052`, `Nav.lua:441`, `Routes.lua:225`) and keeps it in file-local `map`/`sc`. No public API draws on another canvas.
- Our map (`Modules/WorldMap.lua`) is a second MapCanvas instance, so none of it shows in ours.
- Skinning the game's own map instead was tried and parked on branch `experiment/mapskin` (`a5d37da`): window look, quest panel and breadcrumb verified in game; buttons, overlays and the maximised layout not.

## Small local plan (no upstream needed)
0. Baseline in game, no code:
   - `/dump OpenMapAPI.version, OpenMapAPI.IsStitched()`
   - `/dump GetCVar("worldMapShowPlayerCoords"), GetCVar("worldMapShowCursorCoords"), OpenMapCharDB.worldmap.cvars`
   - `/dump issecurevariable(MapCanvasPinMixin, "CheckMouseButtonPassthrough")`
   - Is our coordinates box shown? What happens on `/openmap` while ours is open?
   - Our map in combat with quest pins, then a bug hunt.
1. Our coordinates survive OpenMap's CVar hold (`Extras.lua:36`, 65-72, 231-235). `shown(cvar)` (`Modules/WorldMap.lua:378`) asks `Addons/OpenMap.lua` for the player's own value from `OpenMapCharDB.worldmap.cvars`. Reads OpenMap's private saved variable; precedent `TalentsForeverBookData`.
2. The "..." item reads "Use OpenMap's map" while OpenMap is loaded (same secure click, `ns.WindowMenu`).
3. Decide: `map` defaultOff beside OpenMap (Immersion pattern). Cost: the quest log is the same module, so L goes to the stock log too.

## Upstream API (the real fix)
Research (2026-11-22): no existing issue or PR asks for a second canvas. Related:
- PR #207 (draft): `OM.Showing()` + callback accepted as API v5; the pins/lines `Layer` deferred ("a bigger promise to keep once it's public"; HereBeDragons covers pins). Soft pushback on API size, not on APIs.
- Issue #57: gamepad authors asked for the same second-surface hooks; the controller view shipped, the hooks didn't.
- Issue #405: zone mask API request, no reply yet.
- PR #303: ClassicUI taking over WorldMapFrame got a popup asking the user to turn its option off: mild sign of how they see UI addons competing for the map.

Maintainer `jigrobbulus` merges outside PRs often; releases every 1-4 days. CONTRIBUTING: MIT, the offline checks (`tools/offline-test/run.py plain`, `run.py secret`, `lint.py`), a `Credits.lua` line, before/after renders; AI-assisted code allowed (AGENTS.md).

Mechanism already there: private `S.Rehost(canvas)` (`Map\Stitch.lua:1955`) moves the stitched root, chart and pinRoot onto a canvas; `Map\OwnView.lua` uses it in combat with its own pan/zoom and moves HereBeDragons/Questie icons on.

Proposal: `OpenMapAPI.AttachCanvas(canvas, opts)` / `DetachCanvas()`, built on Rehost + OwnView without the combat gate; `Showing()` reports "attached". Needs `Setup`/`Start`/`SetupOwnView` to take a host `{map, sc}` instead of `_G.WorldMapFrame`, and the OnUpdate driver (`WorldMap.lua:1510-1511`, ticker `:739`) moved off the stock scroll container.

Blockers: a single stitched root (attach is exclusive: fine, ours and the stock map are never open together); `CreateZoomLevels`/`GetPinFrameLevelsManager` dependencies; frame-level resets on reparent; CoordsBar, brightness shade and quest/group dots tied to the stock canvas.

Next step: open an issue first (cite #57, #207, #405 as one need), propose the small versioned API, offer the PR with offline tests, `docs/api.md` and a credits line. Post nothing without the user's approval of the wording.
