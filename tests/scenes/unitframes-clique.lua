--@ title: Unit frames: every button of ours is registered with click-casting addons (Clique)
--@ roots: PolestarUIPlayerFrame
--@ stubs: stub_clique.lua
local names = { "PolestarUIPlayerFrame", "PolestarUITargetFrame", "PolestarUIFocusFrame", "PolestarUITargetToT", "PolestarUIFocusToT", "PolestarUIPetFrame" }
for i = 1, 4 do names[#names + 1] = "PolestarUIPartyFrame" .. i end
for i = 1, 5 do names[#names + 1] = "PolestarUIBossFrame" .. i end
for _, name in ipairs(names) do
	assert(_G[name], name .. " not built")
	assert(stub.clickCast[_G[name]] == true, name .. " not in ClickCastFrames")
end
stub.assertNoErrors()
