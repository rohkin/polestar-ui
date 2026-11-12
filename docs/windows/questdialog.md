#### Quest dialog (`QuestFrame`) — Risk: medium
`QuestFrame` registers its own events (`QUEST_GREETING`, `QUEST_DETAIL`,
`QUEST_PROGRESS`, `QUEST_COMPLETE`, `QUEST_FINISHED`, `QuestFrame_OnLoad`) and
ends the quest dialog as it hides (`CloseQuest`). No manager, no `GameEvent`
route: to replace it, ours would unregister those five events on
`QuestFrame` (a widget call, no Lua value written; the contract allows it only
with the user's leave). Without that, it is not built. Polestar's reward
marks hang on `QuestInfoFrame`'s reward buttons; ours shows them through
Polestar's ranking (`QoL.Rewards`, exported for it).
- **Shell:** plain, 560×600. Band: the quest's title, the NPC's name.
- **Pages:** greeting (as Gossip's list), detail (description, objectives,
  rewards: the World Map's quest details layout), progress (required items as
  Reagent Tiles, "3/4"), reward (choices as Reagent Tiles with Polestar's
  marks, a click selects). Footer: Accept / Decline, Continue, Complete
  (`AcceptQuest`, `CompleteQuest`, `GetQuestReward(choice)`); the stock
  expensive and PvP confirms become `W.Modal`.
- **Tests:** `stub_questdialog.lua` (`QuestFrame` with its registered events); scenes `quest-detail`, `quest-progress`, `quest-reward` (Polestar's marks), each asserting `QuestFrame` never shows.

