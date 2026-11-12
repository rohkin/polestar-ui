--@ title: World Map: Quest Details
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- A click opens a quest's details in the flyout (its map and focus as before), and back returns to the list with its search; every objective (the finished one checked), the text and the rewards (choices, a spell, experience with its share of the level unless at the cap, money, an item) with the game's tooltips; Track, Share (only in a group) and Abandon (only on our dialog's confirm) call the stock steps, and the details close when the quest leaves the log.
stub.pressKey("L")
local f = PolestarUIWorldMap
local c = PolestarUIWorldMapCanvas
local q = f.psQuests
local d = q.Details
local function rows() local t = {} for _, r in ipairs({ q.Scroll.Child:GetChildren() }) do if r:IsShown() then t[#t + 1] = r end end return t end
local function row(n) for _, r in ipairs(rows()) do if (r.psTitle or (r.Label and r.Label:GetText())) == n then return r end end end
local function look(fr, s) for _, r in ipairs({ fr:GetRegions() }) do if r:IsShown() and r.GetText and r:GetText() and tostring(r:GetText()):find(s, 1, true) then return r end end for _, k in ipairs({ fr:GetChildren() }) do if k:IsShown() then local r = look(k, s) if r then return r end end end end
local function has(s) return look(d.Scroll.Child, s) end
q.Search:SetText("kobold")
stub.RunScript(q.Search, "OnTextChanged")
row("Kobold Camp Cleanup"):Click()
assert(d:IsShown() and not q.Scroll:IsShown() and not q.Search:IsShown(), "a click opens the details")
assert(c.mapID == 37 and c.events[#c.events][1] == "SetFocusedQuestID" and c.events[#c.events][2] == 7 and C_QuestLog.GetSelectedQuest() == 7, "map, focus, selected")
d.Back:Click()
assert(not d:IsShown() and q.Search:GetText() == "kobold" and #rows() == 2 and row("Kobold Camp Cleanup").Sel:IsShown(), "back to the list as it was")
row("Kobold Camp Cleanup"):Click()
assert(d.Title:GetText() == "[2] Kobold Camp Cleanup", "title")
assert(has("Marshal McBride") and has("cleansing"), "text")
assert(has("4/10") and has("Kobold camp found"), "every objective")
local checks = 0
for _, r in ipairs({ d.Scroll.Child:GetRegions() }) do if r:IsShown() and r.GetTexture and r:GetTexture() == Polestar.Theme.Media("check") then checks = checks + 1 end end
assert(checks == 1, "finished objective checked: " .. checks)
assert(has(REWARD_CHOICES) and has("Militia Dagger") and has("Kobold Ear Charm") and has(REWARD_SPELL) and has("Healing Touch") and has(REWARD_ITEMS) and has("450 XP") and has("12s 50c") and has("Militia Buckler"), "rewards")
assert(has("450 XP") and has("35% of level 24"), "XP share of the level")
stub.xpMax = 100000
q.Paint()
assert(has("<1% of level 24"), "XP share under 1%")
stub.xpMax = nil
stub.maxLevel = true
q.Paint()
assert(has("450 XP") and not has("of level"), "XP share at the level cap")
stub.maxLevel = false
q.Paint()
stub.RunScript(has("Kobold Ear Charm"):GetParent(), "OnEnter")
assert(GameTooltip.lines[1] == "quest log choice 2", "choice tooltip")
stub.RunScript(has("Militia Buckler"):GetParent(), "OnEnter")
assert(GameTooltip.lines[1] == "quest log reward 1", "reward tooltip")
GameTooltip:Hide()
assert(d.Track.Label:GetText() == "Untrack" and not d.Share:IsShown(), "untrack; no share alone")
d.Track:Click()
assert(not stub.watched[7] and d.Track.Label:GetText() == "Track", "untracked")
d.Track:Click()
assert(stub.watched[7], "tracked")
stub.inGroup = true
q.Paint()
assert(d.Share:IsShown(), "share in a group")
d.Share:Click()
assert(stub.shared == 7, "shared")
d.Abandon:Click()
assert(PolestarModal:IsShown() and not stub.abandoned and C_QuestLog.GetAbandonQuest() == 7, "abandon asks first")
PolestarModal.Box.Cancel:Click()
assert(not stub.abandoned and d:IsShown(), "cancel")
d.Back:Click()
q.Search:SetText("")
stub.RunScript(q.Search, "OnTextChanged")
row("A Threat Within"):Click()
d.Abandon:Click()
PolestarModal.Box.Action:Click()
assert(stub.abandoned == 783, "abandon on the confirm")
stub.fire("QUEST_LOG_UPDATE")
assert(not d:IsShown() and q.Scroll:IsShown() and not row("A Threat Within"), "the details close when the quest leaves the log")
row("Kobold Camp Cleanup"):Click()
