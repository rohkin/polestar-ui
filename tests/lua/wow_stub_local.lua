-- Polestar: UI's additions to Polestar's tests/lua/wow_stub.lua, loaded right
-- after it: the stock tooltip art and comparison tooltip, the chat window calls
-- Modules/Chat.lua hooks, the tooltip fonts and the panel manager's layout.

-- Its art (SharedTooltipArtTemplate): the NineSlice on the tooltip's level,
-- its nine pieces (a dark centre, grey edges), and GameTooltipTemplate's
-- health bar. SharedTooltip_SetBackdropStyle lays the layout again, as the
-- client's (SharedTooltipTemplates.lua): an embedded tooltip hides it.
local function tooltipArt(tip)
	local n = CreateFrame("Frame", nil, tip)
	n:SetAllPoints(tip)
	-- useParentLevel puts its art under the tooltip's text; the preview orders
	-- whole frames, so a level under the tooltip's draws it so.
	n.level = 0
	tip.NineSlice = n
	local edges = { TopEdge = { "TOPLEFT", "TOPRIGHT", "height" }, BottomEdge = { "BOTTOMLEFT", "BOTTOMRIGHT", "height" },
		LeftEdge = { "TOPLEFT", "BOTTOMLEFT", "width" }, RightEdge = { "TOPRIGHT", "BOTTOMRIGHT", "width" } }
	for _, k in ipairs({ "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }) do
		local t = n:CreateTexture(nil, k == "Center" and "BACKGROUND" or "BORDER")
		n[k] = t
		local e = edges[k]
		if e then
			t:SetPoint(e[1], n, e[1], 0, 0)
			t:SetPoint(e[2], n, e[2], 0, 0)
			t[e[3]] = 1
			t:SetColorTexture(0.45, 0.46, 0.52, 1)
		end
	end
	n.Center:SetAllPoints(n)
	n.Center:SetColorTexture(0.02, 0.02, 0.05, 0.92)
end
tooltipArt(GameTooltip)
GameTooltip.StatusBar = CreateFrame("StatusBar", "GameTooltipStatusBar", GameTooltip)
GameTooltip.StatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
GameTooltip.StatusBar:Hide()
-- A comparison tooltip (ShoppingTooltipTemplate, GameTooltip.xml), made by a
-- test (a frame made here would renumber the preview's objects): the stock
-- art and the "Equipped" plate above it, its atlas then the gold label.
function stub.withShoppingTooltip()
	local tip = CreateFrame("GameTooltip", "ShoppingTooltip1", UIParent)
	tip.lines = {}
	tooltipArt(tip)
	tip.StatusBar = false -- none on this template (a stub frame answers any key)
	local h = CreateFrame("Frame", nil, tip)
	h:SetSize(100, 22)
	h:SetPoint("BOTTOMLEFT", tip, "TOPLEFT", 0, -1)
	h:Hide()
	local art = h:CreateTexture(nil, "BACKGROUND")
	art:SetAllPoints(h)
	art:SetColorTexture(0.1, 0.08, 0.04, 0.95)
	h.Label = h:CreateFontString(nil, "ARTWORK")
	h.Label:SetFontObject(GameTooltipText)
	h.Label:SetPoint("CENTER", h, "CENTER", 0, 0)
	h.Label:SetTextColor(1, 0.82, 0)
	tip.CompareHeader = h
	return tip
end
function SharedTooltip_SetBackdropStyle(self, style, embedded)
	if embedded or rawget(self, "IsEmbedded") then self.NineSlice:Hide() else self.NineSlice:Show() end
end

-- FloatingChatFrame.lua's list and the calls Modules/Chat.lua hooks; the
-- chat windows themselves are stub_chat.lua's.
CHAT_FRAMES = {}
function FCF_OpenTemporaryWindow() end
function FCFTab_UpdateColors() end
function FCF_MinimizeFrame() end
function FCF_SetButtonSide() end
Menu = { ModifyMenu = function() end }
C_ChatBubbles = { GetAllChatBubbles = function() return {} end }
for name, size in pairs({ GameTooltipHeaderText = 14, GameTooltipText = 12, GameTooltipTextSmall = 10 }) do
	_G[name] = CreateFont(name)
	_G[name].font = { STANDARD_TEXT_FONT, size, "" }
end
-- The panel manager as addon code sees it: its layout constants, the room it
-- leaves (GetMaxUIPanelsWidth), and its show broadcasts.
local panelLayout = { TOP_OFFSET = -116, LEFT_OFFSET = 16, PANEl_SPACING_X = 32 }
function GetUIPanelLayoutAttribute(name) return panelLayout[name] end
function GetMaxUIPanelsWidth() return UIParent:GetRight() - 80 end
EventRegistry = { callbacks = {} }
function EventRegistry:RegisterCallback(event, fn) self.callbacks[event] = self.callbacks[event] or {}; table.insert(self.callbacks[event], fn) end
function EventRegistry:TriggerEvent(event, ...) for _, fn in ipairs(self.callbacks[event] or {}) do fn(self, ...) end end
