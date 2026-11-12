#### Game menu (`GameMenuFrame`) — Risk: high
Not replaced. Escape runs `ToggleGameMenu`, which walks the game's Escape
handlers in `securecallfunction` (closing windows, stopping a cast, clearing
the target) before it shows the menu: taking the key would take all of that.
Other addons add buttons on `EventRegistry` "GameMenuFrame.Shown", and the
buttons are rebuilt from a pool on every show; Logout and Quit are
protected. If anything, it is restyled in place (rule 15: our ground and
hairlines, the pooled buttons repainted from "GameMenuFrame.Shown"), with
the HUD restyles, after the user decides.

