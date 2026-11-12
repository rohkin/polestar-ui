#### Quest dialog (`QuestFrame`) — Risk: medium
`QuestFrame` registers its own events (`QUEST_GREETING`, `QUEST_DETAIL`,
`QUEST_PROGRESS`, `QUEST_COMPLETE`, `QUEST_FINISHED`, `QuestFrame_OnLoad`) and
ends the quest dialog as it hides (`CloseQuest`). No manager, no `GameEvent`
route: ours unregisters the four open events on `QuestFrame` (a widget call,
no Lua value written; client rule 15's exception allows it, for these open
events only) and answers them. Off waits for `/reload`. Polestar's reward
marks (`QoL.Rewards`, feature-detected) sit on our choices.
- **Ended by another addon:** Polestar's automation and Questie answer the
  open events in handlers that run before ours. `QuestFrame` registers before
  any addon, so it always shows first and its `QUEST_FINISHED` hides it; ours
  can get `QUEST_FINISHED` before it shows. So ours never shows, and closes on
  any repaint and one frame after it opens, once `GetTitleText()` is empty.
- **Shell:** plain, 640×600. Band: the quest NPC's portrait and name
  (`questnpc`, the quest book with none, as `QuestFrame_SetPortrait`). A
  friendship NPC's standing heads the body (`ns.FriendshipBar`, Core.lua).
- **3D portrait:** the giver's on an offer (`GetQuestPortraitGiver`), the
  turn-in's on the reward page (`GetQuestPortraitTurnIn`), in a flyout off
  the right edge (`ns.Flyout`, `ns.DockFlyout`): our own
  `PanningModelSceneMixinTemplate` scene set up as the stock `QuestModelScene`
  (scene 309, mount and rider actors, -1 the player), the name, the text.
- **Pages:** greeting (Current Quests, then Available Quests, under their
  headings, as `QuestFrameGreetingPanel_OnShow`; a long title wraps and its
  row grows; no band subtitle), detail (title, objectives,
  a spell to learn `GetCriteriaSpell`, the suggested group, the giver's
  signature, the description, rewards: the World Map's details layout),
  progress (required items as Reagent Tiles, "3/4"), reward (choices with
  Polestar's marks, a click selects). Rewards: the shared column
  (`ns.QuestRewards`: choices, spells and followers, title, XP, money, skill
  points, items, currencies, honor), then here a major faction's reputation
  and the War Mode bonus where the client has them. Footer: Accept / Decline
  (OK alone, and no close, for an auto-accepted quest; closing one removes its
  tracker pop-up), Continue, Complete; the PvP and expensive confirms are
  `W.Modal`. With `instantQuestText` off the description writes itself in
  (`SetAlphaGradient`, 70 a second, the write sound) and Accept waits.
  A greyed button says why in its tooltip (`ns.SetEnabled`): Continue until
  the quest's needs are met, Accept while the text writes in, ✕ on an
  auto-accepted quest (OK takes it).
- **Offers elsewhere** (`QuestFrame_OnEvent`): one an item starts
  (`QUEST_DETAIL`'s item ID) or an auto-accepted area trigger goes to the
  objective tracker as a pop-up (the client's `AddAutoQuestPopUp`) and the
  dialog ends; one from the adventure map stays the map's.
- **Left out (client):** the stock pop-up goes through the tracker's Lua
  (`QuestObjectiveTracker:AddAutoQuestPopUp`), which also expands the tracker
  and shows the item's icon; from our code that would taint the tracker, so
  ours calls the client's function and the tracker draws it on its next
  update, without the item icon. The stock detail also hides the objectives
  and rewards until the text is in; ours shows them (World Map layout).
  Quest text contrast and the parchment
  materials are the stock art's.
- **Polestar's chat line:** Polestar prints "Best reward: ..." when it could
  not mark the stock buttons (`Rewards.Mark` finds no `QuestInfoFrame`); with
  ours showing the marks the line is redundant, and is Polestar's to drop.
- **Tests:** `stub_questdialog.lua` (`QuestFrame` with its registered events, portraits, the offer's origin, the tracker's pop-ups); scenes `questdialog`, `questdialog-greeting` (a long title wraps), `questdialog-progress`, `questdialog-reward` (Polestar's marks), `questdialog-portrait` (portraits, extras, write-in, offers elsewhere, auto-accept), each asserting `QuestFrame` never shows.
