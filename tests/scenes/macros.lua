--@ title: Macros
--@ roots: PolestarUIMacros
--@ stubs: stub_macros.lua
-- /macro, the game menu and the chat menu all call ShowMacroFrame: ours
-- opens, the stock frame it showed is closed in the same call.
ShowMacroFrame()
local f = PolestarUIMacros
assert(f:IsShown() and not MacroFrame:IsShown(), "the stock window stayed open")
-- It shows, never toggles: a second /macro leaves it open.
ShowMacroFrame()
assert(f:IsShown(), "a second /macro closed it")
-- General first, the first macro selected, its body and the stock counter.
assert(tostring(f.Title:GetText()) == "General Macros", "not on General: " .. tostring(f.Title:GetText()))
assert(tostring(f.Subtitle:GetText()) == "12 of 120 macros.", "the count: " .. tostring(f.Subtitle:GetText()))
assert(f.psEdit:GetText() == "/assist [@focus]", "the first macro's body: " .. tostring(f.psEdit:GetText()))
assert(f.psCount:GetText() == "16/255 Characters Used", "the counter: " .. tostring(f.psCount:GetText()))
assert(not f.psSave:IsEnabled() and not f.psCancel:IsEnabled(), "Save or Cancel on with nothing typed")
local cells = {}
for _, c in ipairs({ f.psGrid.Child:GetChildren() }) do if c.psIndex and c:IsShown() then cells[c.psIndex] = c end end
assert(#cells == 12, "the grid: " .. #cells)

-- Typed, Save and Cancel come on; picking another macro saves it, as stock.
local e = f.psEdit
e:SetFocus()
e:SetText("/cast Charge\n/cast Rend")
stub.RunScript(e, "OnTextChanged", true)
assert(f.psSave:IsEnabled() and f.psCancel:IsEnabled(), "Save or Cancel off after typing")
assert(f.psCount:GetText() == "23/255 Characters Used", "the counter after typing")
cells[3]:Click()
assert(stub.macros.general[1][3] == "/cast Charge\n/cast Rend", "picking another did not save the body")
assert(e:GetText() == stub.macros.general[3][3] and not e:HasFocus(), "the third macro's body")
-- Cancel puts the saved body back; Save saves.
e:SetText("/oops")
stub.RunScript(e, "OnTextChanged", true)
f.psCancel:Click()
assert(e:GetText() == stub.macros.general[3][3], "Cancel did not undo")
e:SetText("/use Hearthstone\n/s Home!")
stub.RunScript(e, "OnTextChanged", true)
f.psSave:Click()
assert(stub.macros.general[3][3] == "/use Hearthstone\n/s Home!", "Save did not save")

-- A cell's drag and the selected icon's click pick it up for an action bar.
stub.RunScript(cells[2], "OnDragStart")
assert(stub.pickedMacro == 2, "no pickup from the grid")
f.psIcon:Click()
assert(stub.pickedMacro == 3, "no pickup from the selected icon")

-- A shift-clicked link goes into the body in focus, as the stock
-- InsertLink: at a line's start as /use (an item with a use), /equip or
-- /cast; within a line the name.
e:SetFocus()
e:SetText("")
ChatFrameUtil.InsertLink("|cffffffff|Hitem:6948::::::::|h[Hearthstone]|h|r")
ChatFrameUtil.InsertLink("|cffff8000|Hitem:19019::::::::|h[Thunderfury]|h|r")
ChatFrameUtil.InsertLink("|cff71d5ff|Hspell:100:0|h[Charge]|h|r")
e:Insert("/cast [@focus] ")
ChatFrameUtil.InsertLink("|cff71d5ff|Hspell:355:0|h[Taunt]|h|r")
assert(e:GetText() == "/use Hearthstone\n/equip Thunderfury, Blessed Blade of the Windseeker\n/cast Charge\n/cast [@focus] Taunt", "the links: " .. e:GetText())
assert(f.psSave:IsEnabled(), "a link did not count as a change")
-- With a chat line open the link is the chat's.
stub.chatWindow = true
ChatFrameUtil.InsertLink("|cff71d5ff|Hspell:355:0|h[Taunt]|h|r")
stub.chatWindow = nil
assert(e:GetText():sub(-6) == " Taunt", "the link went into the macro and the chat")
-- Closing saves, as the stock OnHide.
f.Close:Click()
assert(not f:IsShown() and stub.macros.general[3][3]:find("Thunderfury", 1, true), "closing did not save")

-- Delete asks first, in Polestar's dialog.
ShowMacroFrame()
assert(tostring(f.Title:GetText()) == "General Macros" and f.psName:GetText() == "Assist", "opens on the general macros' first")
f.footerButtons.left[1]:Click()
assert(PolestarModal:IsShown() and tostring(PolestarModal.Box.Title:GetText()) == "Delete Assist?", "no confirm")
PolestarModal.Box.Action:Click()
assert(#stub.macros.general == 11 and f.psName:GetText() == "Charge", "not deleted: " .. tostring(f.psName:GetText()))
assert(not stub.blocked, "a macro call refused: " .. tostring(stub.blocked))

-- Switched off, /macro opens the game's window; on again, ours.
SlashCmdList.POLESTARUI("macros off")
assert(not f:IsShown(), "ours stayed open")
ShowMacroFrame()
assert(MacroFrame:IsShown() and not f:IsShown(), "switched off, the game's window did not open")
MacroFrame.CloseButton:Click()
SlashCmdList.POLESTARUI("macros on")
ShowMacroFrame()
assert(f:IsShown() and not MacroFrame:IsShown(), "switched on again, ours did not open")
