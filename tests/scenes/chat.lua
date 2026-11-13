--@ title: Chat
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrameToggleVoiceDeafenButton, ChatFrameToggleVoiceMuteButton, ChatFrame1EditBox, ChatFrame1Tab, ChatFrame2Tab, ChatFrame11Tab, QuickJoinToastButton, PolestarUIChatSocialIcon
--@ stubs: stub_chat.lua
-- At rest (as the client shows it at login, the IM style's edit box at 0.35): a soft ground, no outline, no footer, the side icons gone, the tabs the game's faded labels. A message through a filter and another addon's AddMessage line show; a whisper window (alerting, its conversation icon flat) is restyled; the ground is Polestar's, not the player's chat opacity, and warms on the game's fade-in; the combat log strip when it loads; switched off and on live; the side buttons, scroll bar, grip and scroll-to-bottom button (a press nudges the glyph). Then warm (mouse over) and typing. Beside them: a minimised window, the dock's overflow list, the tab menu (no other menu on the pooled frame), a bubble (never a forbidden one), switched off and on live.
local W = "Polestar" local function ours(f, layer) local n = 0
for _, r in ipairs({ f:GetRegions() }) do local t = r.GetTexture and r:GetTexture()
if t and tostring(t):find(W) and r:IsShown() and (not layer or r:GetDrawLayer() == layer) then n = n + 1 end end
return n end local function fill(f) for _, r in ipairs({ f:GetRegions() }) do local t = r.GetTexture and r:GetTexture()
if t and tostring(t):find(W) and r:GetDrawLayer() == "BACKGROUND" then return r end end end local function styled(id) local n = "ChatFrame" .. id
local f, t = _G[n], _G[n .. "Tab"]
return not _G[n .. "TopLeftTexture"]:IsShown() and not _G[n .. "ButtonFrameTopTexture"]:IsShown() and f.Background:GetTexture() == nil and f.buttonFrame.Background:GetTexture() == nil and ours(f) == 5 and ours(f.buttonFrame) == 0 and t.Left:GetAlpha() == 0 and t.ActiveMiddle:GetAlpha() == 0 and ours(t, "HIGHLIGHT") == 0 and ours(t, "BACKGROUND") == 0 and _G[n .. "EditBoxMid"]:GetAlpha() == 0 end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", function(_, _, msg) return false, (msg:gsub("lfg", "looking for group")) end) stub.chatSample() assert(stub.messages[#stub.messages - 1]:find("looking for group"), "the filter did not run") assert(styled(1), "not restyled") assert(ours(ChatFrame1Tab, "ARTWORK") == 1 and ours(ChatFrame2Tab, "ARTWORK") == 0, "the selected bar") FCFTab_UpdateColors(ChatFrame2Tab, true)
assert(ours(ChatFrame2Tab, "ARTWORK") == 1, "selected: no bar")
FCFTab_UpdateColors(ChatFrame2Tab, false)
assert(ours(ChatFrame2Tab, "ARTWORK") == 0, "unselected: a bar")
-- The ground: Polestar's at REST (0.35) at rest, whatever the player's chat opacity; all of it warm.
local GA = Polestar.Theme.GroundAlpha() local function near(a, b) return math.abs(a - b) < 1e-6 end
stub.advance(0.1) assert(near(fill(ChatFrame1):GetAlpha(), GA * 0.35), "the ground not soft at rest")
FCF_SetWindowAlpha(ChatFrame1, 0) stub.advance(0.1) assert(near(fill(ChatFrame1):GetAlpha(), GA * 0.35), "the ground follows the chat opacity")
assert(ChatFrameChannelButton.Icon:GetAlpha() == 0, "the side icons shown at rest")
assert(ours(ChatFrame1EditBox) == 0 and ChatFrame1EditBox:IsShown(), "a footer at rest (IM style)")
FCF_FadeInChatFrame(ChatFrame1) stub.advance(0.2) assert(near(fill(ChatFrame1):GetAlpha(), GA), "the ground not full warm") assert(ChatFrameChannelButton.Icon:GetAlpha() == 1, "the side icons hidden warm")
FCF_FadeOutChatFrame(ChatFrame1) stub.advance(1.1) assert(near(fill(ChatFrame1):GetAlpha(), GA * 0.35), "the ground not back at rest")
-- The mouse on a tab, the game's fade-in not yet run (it waits for a still mouse): warm all the same; the label lit, out of the tab's fade, the wash under it (not over it).
stub.mouseOver = ChatFrame2Tab stub.advance(0.2)
assert(near(fill(ChatFrame1):GetAlpha(), GA), "the chat cools with the mouse on a tab")
assert(ChatFrame2Tab.Text:IsIgnoringParentAlpha() and select(1, ChatFrame2Tab.Text:GetTextColor()) == Polestar.Theme.Color("text") and ours(ChatFrame2Tab, "BACKGROUND") == 1 and ours(ChatFrame2Tab, "HIGHLIGHT") == 0, "a hovered tab not lit, or washed over")
stub.mouseOver = nil stub.advance(1.1)
assert(not ChatFrame2Tab.Text:IsIgnoringParentAlpha() and ours(ChatFrame2Tab, "BACKGROUND") == 0, "the tab still lit")
-- The social button: ours in the strip (the stock one's clicks, through a secure click), the stock icon and count faded.
assert(QuickJoinToastButton.FriendsButton:GetAlpha() == 0 and QuickJoinToastButton.FriendCount:GetAlpha() == 0 and PolestarUIChatSocial:GetAttribute("shift-type1") == "click" and PolestarUIChatSocial:GetAttribute("clickbutton") == QuickJoinToastButton and PolestarUIChatSocialIcon:GetAlpha() == 0, "the social button not in the strip")
-- At the strip's foot, on the chat menu button (which the game keeps at the bottom), inside the strip's span whatever the voice buttons do.
local sp, srel, srp = PolestarUIChatSocialIcon:GetPoint()
assert(sp == "BOTTOM" and srel == ChatFrameMenuButton and srp == "TOP" and select(1, ChatFrameMenuButton:GetPoint()) == "BOTTOM" and select(2, ChatFrameMenuButton:GetPoint()) == ChatFrame1ButtonFrame, "the social button not at the strip's foot")
-- The strip spans the window's height (FCF_SetButtonSide: 3 in from the ground's top, 6 from its foot; the ground 3 and 6 out of the window).
assert(ChatFrameMenuButton:GetHeight() + 2 + PolestarUIChatSocialIcon:GetHeight() + 2 + ChatFrameChannelButton:GetHeight() <= ChatFrame1:GetHeight(), "the social button pokes out of the strip")
-- Its click: our Social window while it is on (shift-click the game's), else the stock button's own; a Quick Join toast's click stays the stock button's.
local opened = 0 local toggle = PolestarUI.modules.social.Toggle PolestarUI.modules.social.Toggle = function() opened = opened + 1 end
assert(PolestarUIChatSocial:GetAttribute("type1") == nil, "ours not the social button's route")
stub.RunScript(PolestarUIChatSocial, "PostClick") assert(opened == 1, "the social button does not open ours")
stub.keys.shift = true stub.RunScript(PolestarUIChatSocial, "PostClick") stub.keys.shift = false assert(opened == 1, "shift-click opened ours")
QuickJoinToastButton.displayedToast = { guid = "g" } stub.advance(0.1) assert(PolestarUIChatSocial:GetAttribute("type1") == "click", "a toast's click not the stock button's")
QuickJoinToastButton.displayedToast = nil stub.advance(0.1) assert(PolestarUIChatSocial:GetAttribute("type1") == nil, "ours not back after the toast")
PolestarUI.Switch("social", false) stub.advance(0.1) assert(PolestarUIChatSocial:GetAttribute("type1") == "click", "the stock route not back with our Social window off")
stub.RunScript(PolestarUIChatSocial, "PostClick") assert(opened == 1, "ours opened while off")
PolestarUI.Switch("social", true) stub.advance(0.1) PolestarUI.modules.social.Toggle = toggle
-- Nothing of ours on a window reaches above its ground (the window, level 5, draws over the docked tabs, the LOW dock's children); the header's ground is the dock's, under the tabs; the social icon takes no mouse.
assert(ChatFrame1:GetFrameLevel() > ChatFrame1Tab:GetFrameLevel() and ChatFrame1Tab:GetParent() == GeneralDockManager, "the stub lost the client's stacking")
for _, r in ipairs({ ChatFrame1:GetRegions() }) do if tostring(r.GetTexture and r:GetTexture()):find(W) then for i = 1, r:GetNumPoints() do local pt, rel, _, _, y = r:GetPoint(i) if pt:find("TOP") and (rel == ChatFrame1Background or rel == ChatFrame1ButtonFrameBackground) then assert(y <= 0, "ours on the window reaches over the tabs") end end end end
assert(ours(GeneralDockManager, "BACKGROUND") == 1 and ours(GeneralDockManager) == 5, "no header ground under the tabs")
assert(not PolestarUIChatSocialIcon:IsMouseEnabled(), "the social icon takes the mouse")
assert(select(1, PolestarUIChatSocialIcon:GetSize()) == ChatFrameChannelButton:GetWidth() and PolestarUIChatSocialIcon:GetHeight() == ChatFrameChannelButton:GetHeight() and select(5, PolestarUIChatSocialIcon:GetPoint()) == 2, "the social button not the strip's size and spacing")
FCF_SetWindowAlpha(ChatFrame1, 0.25)
FCF_StartAlertFlash(ChatFrame11) assert(styled(11), "the whisper window is not restyled")
assert(ChatFrame11Tab.glow:IsShown(), "no alert") assert(ChatFrame11Tab.conversationIcon.desaturated and ChatFrame11Tab.conversationIcon:GetVertexColor() == Polestar.Theme.Color("icon"), "the conversation icon not flat in the icon colour") stub.loadCombatLog()
assert(CombatLogQuickButtonFrame_CustomTexture:GetAlpha() == 0 and ours(CombatLogQuickButtonFrame_Custom) == 1, "the combat log strip") PolestarUI.Switch("chat", false) assert(ChatFrame1TopLeftTexture:IsShown() and ChatFrame1Background:GetTexture():find("ChatFrameBackground") and ChatFrame1Tab.Left:GetAlpha() == 1 and ChatFrame1EditBoxMid:GetAlpha() == 1 and ours(ChatFrame1) == 0 and ours(ChatFrame1Tab) == 0 and ours(ChatFrame1EditBox) == 0 and ours(ChatFrame11) == 0 and CombatLogQuickButtonFrame_CustomTexture:GetAlpha() == 1, "not the stock look when off") assert(ChatFrameMenuButton:GetNormalTexture():GetAlpha() == 1 and ChatFrame1.ScrollBar.Track.Thumb.Middle:GetAlpha() == 1 and ChatFrame1.ScrollToBottomButton:GetHighlightTexture():GetAlpha() == 1, "the side buttons not stock when off")
assert(ChatFrameChannelButton.Icon:GetAlpha() == 1 and not ChatFrameChannelButton.Icon.desaturated and not ChatFrame11Tab.conversationIcon.desaturated, "the stock icons not given back when off")
assert(QuickJoinToastButton.FriendsButton:GetAlpha() == 1 and QuickJoinToastButton.FriendCount:GetAlpha() == 1 and not PolestarUIChatSocialIcon:IsShown() and not PolestarUIChatSocial:IsShown(), "the social button not the game's when off") -- At login the dock has not yet coloured the combat log's tab: its stock
-- Active art still shows. Ours follows the dock's selection, not that art.
ChatFrame2Tab.ActiveMiddle:Show()
PolestarUI.Switch("chat", true)
assert(ours(ChatFrame1Tab, "ARTWORK") == 1 and ours(ChatFrame2Tab, "ARTWORK") == 0, "the combat log tab marked selected beside General")
assert(styled(1) and styled(11), "not restyled when on again")
local mut = { Polestar.Theme.Color("textMuted") }
assert(select(1, ChatFrame2Tab.Text:GetTextColor()) == mut[1] and ChatFrame2Tab.Text:GetFont() == Polestar.Theme.FontSpec("small"), "the tab label not in Polestar") local function glyph(b, name) for _, x in ipairs({ b:GetRegions() }) do if tostring(x:GetTexture()):find(name) then return x end end end local function faded(b) return b:GetNormalTexture():GetAlpha() == 0 and b:GetPushedTexture():GetAlpha() == 0 and b:GetHighlightTexture():GetAlpha() == 0 end local bar = ChatFrame1.ScrollBar
assert(faded(ChatFrameMenuButton) and faded(ChatFrameChannelButton) and faded(ChatFrameToggleVoiceMuteButton) and faded(ChatFrame1.ScrollToBottomButton) and faded(ChatFrame1ResizeButton) and bar.Track.Middle:GetAlpha() == 0 and bar.Track.Thumb.Middle:GetAlpha() == 0 and bar.Back.Texture:GetAlpha() == 0, "the side buttons and scroll bar not restyled")
assert(glyph(ChatFrameMenuButton, "icon%-talk") and glyph(ChatFrame1ResizeButton, "resize") and not glyph(ChatFrameChannelButton, "icon") and ChatFrameChannelButton.Icon.desaturated, "the icons")
ChatFrameMenuButton:SetButtonState("PUSHED") ChatFrameChannelButton:Disable() stub.advance(0.1)
assert(select(5, glyph(ChatFrameMenuButton, "icon%-talk"):GetPoint()) == -1, "no press")
ChatFrameMenuButton:SetButtonState("NORMAL") stub.advance(0.1)
assert(select(5, glyph(ChatFrameMenuButton, "icon%-talk"):GetPoint()) == 0, "still pressed")
ChatFrameChannelButton:Enable()
--@ panel
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrameToggleVoiceDeafenButton, ChatFrameToggleVoiceMuteButton, ChatFrame1EditBox, ChatFrame1Tab, ChatFrame2Tab, ChatFrame11Tab, QuickJoinToastButton, PolestarUIChatSocialIcon
--@ stubs: stub_chat.lua
-- Warm: the mouse over the chat (the game's fade-in): the full ground and its hairline, the tabs' labels lit, the side icons back; still no footer.
stub.chatSample()
FCF_FadeInChatFrame(ChatFrame1)
stub.advance(0.3)
assert(ChatFrameChannelButton.Icon:GetAlpha() == 1 and ChatFrame1Tab:GetAlpha() == 1 and PolestarUIChatSocialIcon:GetAlpha() == 1, "not warm")
stub.mouseOver = ChatFrame2Tab
for _, x in ipairs({ ChatFrame1EditBox:GetRegions() }) do assert(not (tostring(x:GetTexture()):find("Polestar") and x:IsShown()), "a footer while not typing") end
preview.hover = ChatFrame2Tab
--@ panel
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrameToggleVoiceDeafenButton, ChatFrameToggleVoiceMuteButton, ChatFrame1EditBox, ChatFrame1Tab, ChatFrame2Tab, ChatFrame11Tab, QuickJoinToastButton, PolestarUIChatSocialIcon
--@ stubs: stub_chat.lua
-- Typing: the window warm, the footer below it (ground, input well, hairline, its top edge a faint accent).
stub.chatSample()
stub.activateChat(ChatFrame1EditBox)
ChatFrame1EditBox.header:SetText("Say:")
stub.advance(0.3)
local W = "Polestar" local r = { Polestar.Theme.Accent() } local lit, n = nil, 0
for _, x in ipairs({ ChatFrame1EditBox:GetRegions() }) do local vc = { x:GetVertexColor() }
if tostring(x:GetTexture()):find(W) and x:IsShown() then n = n + 1 if x:GetDrawLayer() == "BORDER" and vc[1] == r[1] and vc[2] == r[2] and vc[3] == r[3] then lit = x end end end
assert(lit and n == 6, "no footer while typing")
assert(ChatFrameChannelButton.Icon:GetAlpha() == 1, "not warm while typing")
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
