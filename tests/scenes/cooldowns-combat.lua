--@ title: Cooldown Viewer: in combat, a buff appears
--@ roots: EssentialCooldownViewer, BuffIconCooldownViewer, BuffBarCooldownViewer
--@ stubs: stub_cooldowns.lua
-- In combat the game acquires items when an aura appears: they are dressed the next frame (textures and faces on plain frames, nothing protected), and their counts, secret in combat, are never read (GetText is guarded). No error.
stub.cdm({ essential = { { icon = { 0.75, 0.3, 0.2 }, cd = 0.6, time = "12" } }, buffs = {}, bars = {} })
stub.advance(0.05)
stub.inCombat = true
stub.cdm({
	essential = { { icon = { 0.75, 0.3, 0.2 }, cd = 0.5, time = "10" }, { icon = { 0.3, 0.5, 0.85 }, charges = "1" } },
	buffs = { { icon = { 0.3, 0.65, 0.7 }, cd = 0.2, time = "14", stacks = "5" } },
	bars = { { icon = { 0.85, 0.7, 0.25 }, name = "Ice Barrier", left = 9, duration = 30 } },
})
stub.advance(0.05)
assert(#stub.errors == 0, "an error in combat: " .. tostring(stub.errors[1]))
assert(not EssentialCooldownViewer.active[2].Icon.mask.psStock and not BuffIconCooldownViewer.active[1].Icon.mask.psStock, "an item acquired in combat is not dressed")
assert(BuffBarCooldownViewer.active[1].Bar.BarBG:GetAlpha() == 0, "a bar acquired in combat is not dressed")
stub.inCombat = false
