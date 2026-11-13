--@ title: Unit frames: Edit Mode open, ours follow the game's boxes
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUITargetToT, PolestarUIFocusFrame, PlayerFrameSelection, TargetFrameSelection, FocusFrameSelection
stub.cvars.statusText = "1"
stub.units.target = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1000, max = 1000, power = 40, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.focus = stub.units.target
stub.units.targettarget = stub.units.target
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
local P, T, F = PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUIFocusFrame
local function on(f, stock)
	local _, _, _, x, y = f:GetPoint(1)
	return x == stock.Selection:GetLeft() and y == stock.Selection:GetTop() and f:GetWidth() == stock.Selection:GetWidth()
		and f:GetHeight() == stock.Selection:GetHeight() and f:GetScale() == stock:GetEffectiveScale() / UIParent:GetEffectiveScale()
end
-- Edit Mode opens: the game's boxes show on the stock frames, which still stand where ours are.
stub.enterEditMode()
assert(PlayerFrame.Selection:IsShown() and on(P, PlayerFrame) and on(T, TargetFrame) and on(F, FocusFrame), "ours under the boxes")
-- The player drags the player box and resizes the target (Frame Size): ours follow as it moves.
stub.moveSystem(PlayerFrame, 300, 700)
stub.moveSystem(TargetFrame, 600, 700, 1.2)
stub.advance(0.1)
assert(on(P, PlayerFrame), "player follows the drag")
assert(on(T, TargetFrame) and T:GetScale() == 1.2, "target follows its new size")
-- Ours never move the stock frame (rule 16): that would error in the stub.
assert(not PlayerFrame:IsMouseEnabled() and PlayerFrame:IsShown(), "stock frame left in place")
-- Closing Edit Mode keeps them where they were left.
stub.exitEditMode()
assert(not PlayerFrame.Selection:IsShown() and on(P, PlayerFrame), "placed on close")
-- Another layout (switched in Edit Mode's dropdown): ours take its places.
stub.applyLayout({ [PlayerFrame] = { 260, 760, 1 }, [FocusFrame] = { 900, 400, 0.8 } })
stub.advance(0.1)
assert(on(P, PlayerFrame) and on(F, FocusFrame) and F:GetScale() == 0.8, "layout switch followed")
-- The targets of target follow their stock frames, which hang off the target and focus.
assert(select(4, PolestarUITargetToT:GetPoint(1)) == TargetFrameToT:GetLeft(), "target of target follows")
-- Edit Mode open again for the picture: the boxes over ours.
stub.applyLayout({ [TargetFrame] = { 560, 760, 1 } })
stub.advance(0.1)
stub.enterEditMode()
