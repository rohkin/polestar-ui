--@ title: Unit frames: their settings (/pui unitframes), and their look with no portrait on a faint ground
--@ roots: PolestarUIUnitFramesOptions
PolestarUI.Show("unitframes")
assert(PolestarUIUnitFramesOptions:IsShown(), "settings open")
assert(PolestarUIUnitFramesOptions.sparkle and PolestarUIUnitFramesOptions.smooth, "sparkle and smooth bars toggles")
--@ panel
--@ roots: PolestarUIPlayerFrame
--@ saved: PolestarUIDB = { modules = {}, unitframes = { ground = 0.2, portrait = false, sparkle = false, smooth = false } }
stub.cvars.statusText = "1"
stub.fire("CVAR_UPDATE", "statusText")
assert(not PolestarUIPlayerFrame.portrait:IsShown(), "no portrait")
assert(not PolestarUIPlayerFrame.Health.Sparkle:IsShown(), "sparkle off")
stub.fire("UNIT_HEALTH", "player")
assert(PolestarUIPlayerFrame.Health.interpolation == Enum.StatusBarInterpolation.Immediate, "smooth bars off")
