# Settings

Polestar: UI's page in Polestar's settings window (Polestar 0.4.0's options
registry, `Polestar.RegisterOptions`), made by `Settings.lua` at login, after
the modules have enabled.

Opened by bare `/pui`. Its subtitle (the registry's `spec.subtitle`, set on the first
section) reads "Version x.y.z" from `C_AddOns.GetAddOnMetadata(ADDON, "Version")`;
`/pui help` prints the window listing.

## Where the state lives

In our own saved data, never in PolestarDB: every control has `get`/`set` and
no `key`, so the page only reads and writes what `/pui` and the windows' menus
already do. A reset (the page's or a section's) calls `set(nil)`: our default.

| Control | Saved in | Through |
| --- | --- | --- |
| A toggle per module | `PolestarUIDB.modules[key]` (nil: on, unless the gamepad UI or `defaultOff`; always off with `blockedBy`: the toggle greyed, its help the reason; blocked toggles lead the Windows list, side by side from the left column, under one dimmed wide row with a disabled "Blocked" button saying so, since the options API has no text row: "Bags and Bank are off while X is loaded: ...", or a row after each when their blockers differ) | `ns.Enabled`, `ns.Switch` (refused in combat; a `reloadOff` module goes off after /reload, and its help says so) |
| Dock windows | `PolestarUIDB.free` | `ns.Docked`, `ns.SetDocked` |
| Frames look, Plates look, Icons look: Override Polestar's look; Window border, Border (1-4 px), Border colour (the scheme's, class colour, white, black, gold, silver, Polestar's own colour when seeded with one), Accent border (a colour and the accent turn each other off, as in Polestar), Hairlines (0-300%), Window shadow, Shadow strength (0-200%), Background opacity (greyed while following, showing Polestar's) | `PolestarUIDB.hudLook[frames/plates/icons]` (`override`, `border`, `borderSize`, `borderColor`, `ownColor`, `borderAccent`, `hairline`, `shadow`, `shadowStrength`, `ground`); turning the override on first seeds them from Polestar's look (`ns.HUD.Seed`, the small pieces' size at their 2 px cap); a row's reset: Polestar's value now; the toggle's: follow (the values kept) | `ns.HUD.Edge`/`ShadowColor`/`GroundAlpha` read them; every change runs `Theme.Refresh` and refreshes the look rows (Polestar's page re-checks `disabled` only on a SETTING_CHANGED; Settings.lua hooks `W.SetDisabledWhen` to find them). A save with the old `hudOwnGround` becomes an override of every group at Polestar's look and `unitframes.ground`, once, at login |
| Unit frames: 3D portraits, power text, sparkle, smooth bars, damage trail | `PolestarUIDB.unitframes` | the unit frames module's `Option(k)` / `SetOption(k, v)` when it exports them; until then the defaults are copied in `Settings.lua` and a change applies after /reload |
| Nameplate cast bars: Cast bar icon (off), Cast bar height (6-16, 10) | `PolestarUIDB.nameplates` (`castIcon`, `castHeight`; nil: the default) | the nameplates module's `Option(k)` / `SetOption(k, v)`, applied live to every plate |
| Keep chat across sessions | `PolestarUICharDB.chatNoHistory` | read by Chat at logout and login |
| Fade chat when idle (off) | `PolestarUIDB.chatFade` (nil: no fade) | read by Chat's driver each frame (live) |
| Auction house list sorts | `PolestarUIDB.auctionSorts[context]` (two `{sortOrder, reverseSort}` at most, the last clicked first; nil: the stock defaults) | Auction.lua `sorts(ctx)`, written by the column clicks; no settings control |
| World map: side panel page, full screen | `PolestarUIDB.mapQuests` (`"quests"`, `"legend"`, or nil), `PolestarUIDB.mapFull` (true or nil) | WorldMap.lua `setPanel`/`setFull`, restored at login; no settings control |
| Recently crafted recipes (newest first, per character) | `PolestarUICharDB.recentRecipes` | Crafting.lua `recent()`/`remember(id)`; no settings control |

## Layout

Page "Polestar: UI" (key `polestarui`, group `setup`, icon `window`):

- Windows tab: Windows (one toggle per window module, the Baganator skin
  included), Docking.
- HUD tab: HUD (one toggle per module with a `noun`: unit frames, chat,
  tooltips, minimap, bars...), Frames look, Plates look, Nameplate cast bars (Frames: unit frames, cast bars, the damage meter, the minimap; Plates: nameplates and their cast bars), Unit frames, Chat.
- Icons tab: Icons look (action and bag buttons, the micro menu, buffs, the
  cooldown viewer), with a pinned live preview (`spec.preview`): Polestar's
  band (`Polestar.UI.Preview.Band`, there once Polestar_Options draws the
  page; without it a plain frame with `:Layout`) holding two plain Buttons of
  ours (no action, no events, never secure) at their real size, a filled one
  and an empty one (its icon hidden: the empty slot's emblem), painted by the
  action bars' own `ns.ButtonLook.paint` (Modules/ActionBars.lua), so it
  cannot drift from the bars. Every look change runs `Theme.Refresh`, and the
  band's ground is a Polestar painter: it lays the button out and paints it
  again then, and on Polestar's own theme and skin changes.
  Polestar 0.4.0's colour control is keyed to a PolestarDB setting only (no get/set), so the border colour is a dropdown.

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
and reset, each HUD look group following Polestar's or overriding it, the Icons tab's preview built on a stand-in band (`stub.preview`, tests/lua/stub_client.lua) and laid out again on a look change, the reload note, the menu item), `settings-mover.lua` (the Bags
mover's get/set/reset over `PolestarUIDB.pos`), `settings-old.lua` (the
version guard). The preview loads only Polestar's Core and Theme, so
`Polestar.UI` and `Polestar.Movers` are stand-ins there.
