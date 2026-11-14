--@ title: Chat: history and copy
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrame1Tab, ChatFrame2Tab, QuickJoinToastButton, PolestarUIChatSocialIcon, PolestarUIChatCopyButton, PolestarUIChatCopy
--@ stubs: stub_chat.lua
--@ saved: PolestarUICharDB = { chat = { at = 1700000000, [1] = { { "|cff40ff40[Guild] [Jegba]: see you tomorrow|r", 1, 1, 1 }, { "You receive loot: |cffffffff|Hitem:2589::::::::|h[Linen Cloth]|h|rx2.", 0, 0.667, 0 } }, [2] = { { "a combat log line", 1, 1, 1 } } } }
-- Logged in again: the last session's lines put back above this one's, dimmed, under a divider; the combat log never. This session's lines, a secret one among them; the strip's copy button (warm) opens the copy window on the selected window: plain text, an item as [Name], the secret line a placeholder, all of it selected. At logout the history is saved again: once each, at its own colour, no divider, no secret line, at most 500 lines a window.
local f = ChatFrame1
f:RemoveMessagesByPredicate(function(...) return select(8, ...) == nil end) -- the stub's login lines (Polestar's install warning)
assert(f:GetNumMessages() == 3, "the history not put back")
local t, r, _, _, _, _, _, m = f:GetMessageInfo(1)
assert(t:find("see you tomorrow") and m == "PolestarUIHistory" and math.abs(r - 0.8) < 1e-9, "an old line not put back dimmed")
t, _, _, _, _, _, _, m = f:GetMessageInfo(3)
assert(m == "PolestarUIHistoryDivider" and t == "- previous session, 14 Nov 22:13 -", "no divider")
assert(ChatFrame2:GetNumMessages() == 0, "the combat log put back")
f:AddMessage("Welcome to World of Warcraft!", 1, 1, 0)
f:AddMessage("|cffff80ff|Hplayer:Thrall|h[Thrall]|h whispers: meet at the bank|r", 1, 0.5, 1)
f:AddMessage(stub.secret("[Ragnaros] yells: BY FIRE BE PURGED!"), 1, 0.2, 0.2)
FCF_FadeInChatFrame(f)
stub.advance(0.3)
assert(PolestarUIChatCopyButton:IsShown() and PolestarUIChatCopyButton:GetAlpha() == 1, "no copy button in the warm strip")
assert(select(2, PolestarUIChatCopyButton:GetPoint()) == PolestarUIChatSocialIcon, "the copy button not above the social button")
stub.RunScript(PolestarUIChatCopyButton.Button, "OnClick")
local want = table.concat({ "[Guild] [Jegba]: see you tomorrow", "You receive loot: [Linen Cloth]x2.", "- previous session, 14 Nov 22:13 -",
	"Welcome to World of Warcraft!", "[Thrall] whispers: meet at the bank", "(hidden: the game keeps this line secret)" }, "\n")
assert(PolestarUIChatCopy:IsShown() and PolestarUIChatCopy.Box:GetText() == want, "the copy text: " .. tostring(PolestarUIChatCopy.Box:GetText()))
assert(PolestarUIChatCopy.Hint:GetText():find("^1 line"), "the secret line not said")
assert(PolestarUIChatCopy.Box:HasFocus(), "the copy box not focused")
-- At logout: saved once each, at its own colour, without the divider and the secret line.
stub.fire("PLAYER_LOGOUT")
local h = PolestarUICharDB.chat
assert(h and h.at and #h[1] == 4 and h[1][1][2] == 1 and h[1][2][3] == 0.667 and h[1][4][1]:find("meet at the bank") and not h[2], "the history not saved as it was")
--@ panel
--@ roots: GeneralDockManager, ChatFrame1, ChatFrame1ButtonFrame, ChatFrame1Tab, ChatFrame2Tab
--@ stubs: stub_chat.lua
--@ saved: PolestarUICharDB = { chat = { at = 1700000000, [1] = { { "an old line", 1, 1, 1 } } } }
-- The tab menu's "Copy chat text" opens the copy window on that tab's window; "Clear history" takes the last session's lines out of the windows and the saved history; switched off, nothing is kept at logout. A window of more than 500 lines keeps its newest 500.
local f = ChatFrame1
f:RemoveMessagesByPredicate(function(...) return select(8, ...) == nil end)
f:AddMessage("a new line", 1, 1, 1)
local _, _, root = stub.openMenu(ChatFrame1Tab, "MENU_FCF_TAB", { "Rename Window" })
local item for _, it in ipairs(root.items) do if type(it) == "table" and it[1] == "Copy chat text" then item = it end end
assert(item, "no copy item in the tab menu")
stub.closeMenu()
item[2]()
assert(PolestarUIChatCopy:IsShown() and PolestarUIChatCopy.Box:GetText():find("an old line"), "the tab menu's copy")
stub.RunScript(PolestarUIChatCopy.Clear, "OnClick")
assert(f:GetNumMessages() == 1 and f:GetMessageInfo(1) == "a new line" and PolestarUICharDB.chat == nil, "the history not cleared")
assert(PolestarUICharDB.chat == nil and PolestarUIChatCopy.Box:GetText() == "a new line", "the copy not refreshed")
local big = stub.makeChat(3, "Trade")
function big.GetNumMessages() return 600 end
function big.GetMessageInfo(_, i) return "line " .. i, 1, 1, 1 end
stub.fire("PLAYER_LOGOUT")
assert(#PolestarUICharDB.chat[3] == 500 and PolestarUICharDB.chat[3][1][1] == "line 101", "not cut to the newest 500")
stub.RunScript(PolestarUIChatCopy.Keep, "OnClick")
assert(PolestarUICharDB.chatNoHistory, "the switch")
stub.fire("PLAYER_LOGOUT")
assert(PolestarUICharDB.chat == nil, "kept while switched off")
PolestarUIChatCopy:Hide()
