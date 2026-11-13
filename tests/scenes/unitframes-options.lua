--@ title: Unit frames: their settings (/pui unitframes), and their look with no portrait on a faint ground
--@ roots: PolestarUIUnitFramesOptions
PolestarUI.Show("unitframes")
assert(PolestarUIUnitFramesOptions:IsShown(), "settings open")
--@ panel
--@ roots: PolestarUIPlayerFrame
--@ saved: PolestarUIDB = { modules = {}, unitframes = { ground = 0.2, portrait = false } }
stub.cvars.statusText = "1"
stub.fire("CVAR_UPDATE", "statusText")
assert(not PolestarUIPlayerFrame.portrait:IsShown(), "no portrait")
