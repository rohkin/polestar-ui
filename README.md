# Polestar: UI

A companion to [Polestar](https://github.com/fitzforge/polestar): the game's own windows remade in Polestar's look, drawn with Polestar's own widgets so they follow its scheme, accent and font live.

## Requirements

- Polestar.

## Use

- `/pui` lists the modules; `/pui character` opens the Character window.
- `/pui <module> off` (then `/reload`) gives the game's own window back.
- With Forever's gamepad UI on, every module starts off and `/pui` is not registered.

## Development

The design system is [docs/DESIGN.md](docs/DESIGN.md), on top of Polestar's own. Before building a surface, read [docs/CLIENT.md](docs/CLIENT.md): the client rules learnt from bugs in game, and how to read errors from it.

Needs Node 24+, a Lua 5.1 (`luajit` works; or set `LUA`), and a Polestar checkout at `../polestar` (or `$POLESTAR_DIR`).

```sh
npm test            # every scene must render as its golden in tests/golden, with no text overflowing
npm run preview     # re-render (re-bless) the goldens after a meant change
```

The renderer runs the real addon Lua on a stub of the client and draws every frame as SVG (`tools/preview.js`, scenes in `SCENES`). A failing scene writes `tests/golden/<scene>.actual.svg` next to its golden to compare.

The renderer and client stubs in `tools/preview`, `tools/lib`, `tests/lua` and `tests/helpers` come from Polestar, under the GPL-3.0.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
