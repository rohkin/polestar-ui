# Settings

Polestar: UI's page in Polestar's settings window (Polestar 0.4.0's options
registry, `Polestar.RegisterOptions`), made by `Settings.lua` at login, after
the modules have enabled.

## Where the state lives

In our own saved data, never in PolestarDB: every control has `get`/`set` and
no `key`, so the page only reads and writes what `/pui` and the windows' menus
already do. A reset (the page's or a section's) calls `set(nil)`: our default.

| Control | Saved in | Through |
| --- | --- | --- |
| A toggle per module | `PolestarUIDB.modules[key]` (nil: on, unless the gamepad UI or `defaultOff`) | `ns.Enabled`, `ns.Switch` (refused in combat; a `reloadOff` module goes off after /reload, and its help says so) |
| Dock windows | `PolestarUIDB.free` | `ns.Docked`, `ns.SetDocked` |
| Unit frames: background opacity, 3D portraits, power text, sparkle, smooth bars, damage trail | `PolestarUIDB.unitframes` | the unit frames module's `Option(k)` / `SetOption(k, v)` when it exports them; until then the defaults are copied in `Settings.lua` and a change applies after /reload |
| Keep chat across sessions | `PolestarUICharDB.chatNoHistory` | read by Chat at logout and login |

## Layout

Page "Polestar: UI" (key `polestarui`, group `setup`, icon `window`):

- Windows tab: Windows (one toggle per window module, the Baganator skin
  included), Docking.
- HUD tab: HUD (one toggle per module with a `noun`: unit frames, chat,
  tooltips, minimap, bars...), Unit frames, Chat.

The unit frames' own small page (`/pui unitframes`) stays; both write the same
keys.

## Doors

- Each window's "..." menu has "Settings…" (`ns.ShowSettings(key)`) before the
  divider: our page, on the tab holding that module's toggle. Polestar's
  `JumpTo` finds rows by setting key, and ours have none, so it lands on the
  tab, not the row.
- The floating Bags register with Polestar's Move frames (`Polestar.Movers`)
  when first built (`ns.Float(f, label)`): get and set convert between
  UIParent's units and the window's, and write `PolestarUIDB.pos[name]`, the
  same place our own drag saves.

## Version

Polestar 0.4.0 is the minimum. `ns.PolestarTooOld(Polestar.version)` checks a
plain release number ("0.3.7"; a dev or test build passes): too old, no module
enables, the page is not registered, and login, `/pui <key> on|off` and
opening a window print "Polestar: UI needs Polestar 0.4.0 or newer; update
Polestar."

## Tests

`tests/scenes/settings.lua` (registration, every control's get/set round trip
and reset, the reload note, the menu item), `settings-mover.lua` (the Bags
mover's get/set/reset over `PolestarUIDB.pos`), `settings-old.lua` (the
version guard). The preview loads only Polestar's Core and Theme, so
`Polestar.UI` and `Polestar.Movers` are stand-ins there.
