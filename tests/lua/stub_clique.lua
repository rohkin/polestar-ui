-- Clique's registry: a click-casting addon loaded first leaves ClickCastFrames as
-- a table whose writes register a frame; record them.
stub.clickCast = {}
ClickCastFrames = setmetatable({}, { __newindex = function(_, k, v) stub.clickCast[k] = v or nil end })
