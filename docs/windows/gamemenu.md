#### Game menu (`GameMenuFrame`) — Risk: high — dropped
Dropped: not built. Escape runs the game's own handlers first, other addons
add buttons to it, and Logout and Quit are protected. A restyle may come later
with the HUD.

Not replaced. Escape runs `ToggleGameMenu`, which walks the game's Escape
handlers in `securecallfunction` (closing windows, stopping a cast, clearing
the target) before it shows the menu: taking the key would take all of that.
Other addons add buttons on `EventRegistry` "GameMenuFrame.Shown", and the
buttons are rebuilt from a pool on every show; Logout and Quit are
protected. If anything, it is restyled in place (rule 15: our ground and
hairlines, the pooled buttons repainted from "GameMenuFrame.Shown"), with
the HUD restyles, after the user decides.

