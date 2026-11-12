--@ title: Chat
--@ roots: ChatFrame1, ChatFrame1ButtonFrame, ChatFrameToggleVoiceDeafenButton, ChatFrameToggleVoiceMuteButton, ChatFrame1EditBox, ChatFrame1Tab, ChatFrame2Tab, ChatFrame11Tab
--@ stubs: stub_chat.lua
-- The chat window restyled in place: a message through a filter and another addon's AddMessage line show; a new whisper window (alerting) is restyled; the ground follows the window alpha; the combat log strip when it loads; switched off and on live; the edit box in focus; the side buttons, scroll bar, grip and scroll-to-bottom button (a press nudges the glyph). Beside it: a minimised window, the dock's overflow list, the tab menu (no other menu on the pooled frame), a bubble (never a forbidden one), switched off and on live.
local W = "Polestar" local function ours(f, layer) local n = 0
for _, r in ipairs({ f:GetRegions() }) do local t = r.GetTexture and r:GetTexture()
if t and tostring(t):find(W) and r:IsShown() and (not layer or r:GetDrawLayer() == layer) then n = n + 1 end end
return n end local function fill(f) for _, r in ipairs({ f:GetRegions() }) do local t = r.GetTexture and r:GetTexture()
if t and tostring(t):find(W) and r:GetDrawLayer() == "BACKGROUND" then return r end end end local function styled(id) local n = "ChatFrame" .. id
local f, t, e = _G[n], _G[n .. "Tab"], _G[n .. "EditBox"]
return not _G[n .. "TopLeftTexture"]:IsShown() and not _G[n .. "ButtonFrameTopTexture"]:IsShown() and f.Background:GetTexture() == nil and f.buttonFrame.Background:GetTexture() == nil and ours(f) == 6 and ours(f.buttonFrame) == 0 and t.Left:GetAlpha() == 0 and t.ActiveMiddle:GetAlpha() == 0 and ours(t, "HIGHLIGHT") == 1 and _G[n .. "EditBoxMid"]:GetAlpha() == 0 and ours(e) == 5 end for _, l in ipairs(ChatFrame1.lines) do l:Hide() end
ChatFrame1.lines = {} ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", function(_, _, msg) return false, (msg:gsub("lfg", "looking for group")) end) DEFAULT_CHAT_FRAME:AddMessage("Welcome to World of Warcraft!", 1, 1, 0) stub.chatEvent(ChatFrame1, "CHAT_MSG_SAY", "anyone lfg for Deadmines?", "Thrall") ChatFrame1:AddMessage("|cff33ff99Another addon:|r its own line, through AddMessage", 0.8, 0.8, 1) assert(stub.messages[#stub.messages - 1]:find("looking for group"), "the filter did not run") assert(styled(1), "not restyled") assert(ours(ChatFrame1Tab, "ARTWORK") == 1 and ours(ChatFrame2Tab, "ARTWORK") == 0, "the selected bar") FCFTab_UpdateColors(ChatFrame2Tab, true)
assert(ours(ChatFrame2Tab, "ARTWORK") == 1, "selected: no bar")
FCFTab_UpdateColors(ChatFrame2Tab, false)
assert(ours(ChatFrame2Tab, "ARTWORK") == 0, "unselected: a bar") FCF_SetWindowAlpha(ChatFrame1, 0)
stub.advance(0.1)
assert(fill(ChatFrame1):GetAlpha() == 0, "the ground ignores the window alpha") FCF_SetWindowAlpha(ChatFrame1, 0.6)
stub.advance(0.1)
assert(fill(ChatFrame1):GetAlpha() == 0.6, "the ground ignores the window alpha") FCF_OpenTemporaryWindow("WHISPER", "Jaina", ChatFrame1)
FCF_StartAlertFlash(ChatFrame11) assert(styled(11), "the whisper window is not restyled")
assert(ChatFrame11Tab.glow:IsShown(), "no alert") stub.loadCombatLog()
assert(CombatLogQuickButtonFrame_CustomTexture:GetAlpha() == 0 and ours(CombatLogQuickButtonFrame_Custom) == 1, "the combat log strip") PolestarUI.Switch("chat", false) assert(ChatFrame1TopLeftTexture:IsShown() and ChatFrame1Background:GetTexture():find("ChatFrameBackground") and ChatFrame1Tab.Left:GetAlpha() == 1 and ChatFrame1EditBoxMid:GetAlpha() == 1 and ours(ChatFrame1) == 0 and ours(ChatFrame1Tab) == 0 and ours(ChatFrame1EditBox) == 0 and ours(ChatFrame11) == 0 and CombatLogQuickButtonFrame_CustomTexture:GetAlpha() == 1, "not the stock look when off") assert(ChatFrameMenuButton:GetNormalTexture():GetAlpha() == 1 and ChatFrame1.ScrollBar.Track.Thumb.Middle:GetAlpha() == 1 and ChatFrame1.ScrollToBottomButton:GetHighlightTexture():GetAlpha() == 1, "the side buttons not stock when off") -- At login the dock has not yet coloured the combat log's tab: its stock
-- Active art still shows. Ours follows the dock's selection, not that art.
ChatFrame2Tab.ActiveMiddle:Show()
PolestarUI.Switch("chat", true)
assert(ours(ChatFrame1Tab, "ARTWORK") == 1 and ours(ChatFrame2Tab, "ARTWORK") == 0, "the combat log tab marked selected beside General")
local function shownIn(t, layer) local n = 0 for _, r in ipairs({ t:GetRegions() }) do if r:IsShown() and r:GetAlpha() > 0 and r:GetDrawLayer() == layer then n = n + 1 end end return n end
assert(shownIn(ChatFrame1Tab, "BACKGROUND") == shownIn(ChatFrame2Tab, "BACKGROUND"), "the selected tab's ground is the hovered one's")
assert(styled(1) and styled(11), "not restyled when on again") stub.activateChat(ChatFrame1EditBox)
ChatFrame1EditBox.header:SetText("Say:")
stub.advance(0.1) local e = select(2, ChatFrame1EditBox:GetRegions())
local r = { Polestar.Theme.Accent() } local lit
for _, x in ipairs({ ChatFrame1EditBox:GetRegions() }) do local vc = { x:GetVertexColor() }
if x:GetDrawLayer() == "BORDER" and tostring(x:GetTexture()):find(W) and x:IsShown() and vc[1] == r[1] and vc[2] == r[2] and vc[3] == r[3] then lit = x end end
assert(lit, "no accent while typing")
local mut = { Polestar.Theme.Color("textMuted") }
assert(select(1, ChatFrame2Tab.Text:GetTextColor()) == mut[1] and ChatFrame2Tab.Text:GetFont() == Polestar.Theme.FontSpec("small"), "the tab label not in Polestar") local function glyph(b, name) for _, x in ipairs({ b:GetRegions() }) do if tostring(x:GetTexture()):find(name) then return x end end end local function faded(b) return b:GetNormalTexture():GetAlpha() == 0 and b:GetPushedTexture():GetAlpha() == 0 and b:GetHighlightTexture():GetAlpha() == 0 end local bar = ChatFrame1.ScrollBar
assert(faded(ChatFrameMenuButton) and faded(ChatFrameChannelButton) and faded(ChatFrameToggleVoiceMuteButton) and faded(ChatFrame1.ScrollToBottomButton) and faded(ChatFrame1ResizeButton) and bar.Track.Middle:GetAlpha() == 0 and bar.Track.Thumb.Middle:GetAlpha() == 0 and bar.Back.Texture:GetAlpha() == 0, "the side buttons and scroll bar not restyled")
assert(glyph(ChatFrameMenuButton, "icon%-talk") and glyph(ChatFrame1ResizeButton, "resize") and not glyph(ChatFrameChannelButton, "icon") and ChatFrameChannelButton.Icon:GetAlpha() == 1, "the icons")
ChatFrameMenuButton:SetButtonState("PUSHED") ChatFrameChannelButton:Disable() stub.advance(0.1)
assert(select(5, glyph(ChatFrameMenuButton, "icon%-talk"):GetPoint()) == -1, "no press")
ChatFrameMenuButton:SetButtonState("NORMAL") stub.advance(0.1)
assert(select(5, glyph(ChatFrameMenuButton, "icon%-talk"):GetPoint()) == 0, "still pressed")
ChatFrameChannelButton:Enable() preview.hover = ChatFrame2Tab
--@ panel
--@ roots: ChatFrame3Minimized, GeneralDockManager, GeneralDockManagerOverflowButtonList, StubMenu, StubBubble
--@ stubs: stub_chat.lua
local W = "Polestar" local function ours(f, layer) local n = 0
for _, r in ipairs({ f:GetRegions() }) do local t = r.GetTexture and r:GetTexture()
if t and tostring(t):find(W) and r:IsShown() and (not layer or r:GetDrawLayer() == layer) then n = n + 1 end end
return n end FCF_MinimizeFrame(stub.makeChat(3, "Trade"), "LEFT")
local mini = ChatFrame3Minimized
assert(mini.Left:GetAlpha() == 0 and mini.HighlightMiddle:GetAlpha() == 0 and ours(mini, "BACKGROUND") == 1 and ChatFrame3MinimizedMaximizeButton:GetNormalTexture():GetAlpha() == 0 and ours(ChatFrame3MinimizedMaximizeButton, "ARTWORK") == 1, "the minimised window not restyled")
stub.openOverflow()
local list = GeneralDockManagerOverflowButtonList
assert(list.NineSlice.TopEdge:GetAlpha() == 0 and list.NineSlice.Center:GetAlpha() == 0 and ours(list.NineSlice) == 5 and GeneralDockManagerOverflowButton:GetHighlightTexture():GetAlpha() == 1, "the overflow list not restyled, or its pulse faded")
local m, bg = stub.openMenu(ChatFrame1Tab, "MENU_UNIT_SELF", { "Set Focus" })
assert(bg:GetAlpha() > 0.9 and ours(m) == 0, "a menu not the chat's restyled")
m, bg = stub.openMenu(ChatFrame1Tab, "MENU_FCF_TAB", { "Rename Window" })
assert(bg:GetAlpha() == 0 and ours(m) == 5, "the tab menu not restyled")
m, bg = stub.openMenu(ChatFrame1Tab, "MENU_UNIT_SELF", { "Set Focus" })
assert(bg:GetAlpha() > 0.9 and ours(m) == 0, "ours left on the pooled menu frame")
local bub = stub.chatBubble("StubBubble", "Anyone selling Runecloth?", 330, 330)
local inst = stub.chatBubble("StubBubbleForbidden", "In a dungeon", 330, 400, true)
stub.advance(0.2)
assert(bub.TopEdge:GetAlpha() == 0 and bub.Center:GetAlpha() == 0 and bub.Tail:GetAlpha() == 0 and ours(bub) == 5, "the bubble not restyled")
assert(inst.TopEdge:GetAlpha() == 1 and ours(inst) == 0, "a forbidden bubble touched")
PolestarUI.Switch("chat", false)
m, bg = stub.openMenu(ChatFrame1Tab, "MENU_FCF_TAB", { "Rename Window" })
assert(bub.TopEdge:GetAlpha() == 1 and bub.Tail:GetAlpha() == 1 and ours(bub) == 0 and mini.Left:GetAlpha() == 1 and ours(mini) == 0 and list.NineSlice.TopEdge:GetAlpha() == 1 and ours(list.NineSlice) == 0 and bg:GetAlpha() > 0.9 and ours(m) == 0, "not the stock look when off")
PolestarUI.Switch("chat", true)
m = stub.openMenu(ChatFrame1Tab, "MENU_FCF_TAB", { "Rename Window", "Create New Window", "Settings" })
assert(bub.TopEdge:GetAlpha() == 0 and ours(bub) == 5 and mini.Left:GetAlpha() == 0 and ours(m) == 5, "not restyled when on again")
preview.hover = mini
