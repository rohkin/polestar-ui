#### Gossip (`GossipFrame`) — Risk: medium
Opened by `CustomGossipFrameManager` on `GOSSIP_SHOW`. The stock window ends
the gossip as it hides (`C_GossipInfo.CloseGossip` in its `OnHide`). The
manager offers a default handler (`CustomGossipFrameManager:SetBaseHandler`):
ours takes it, so the game calls ours for every gossip its custom handlers
(the NPE guide) do not take; ours closes itself on `GOSSIP_CLOSED` (the
manager's `HideUIPanel` of ours does nothing from our code, CLIENT.md rule
1). Off waits for `/reload`. Polestar's gossip automation runs on the
events and is unaffected.
- **Shell:** plain, 560×560, no tabs, no sidebar. Band: the NPC's portrait
  (`SetPortraitTexture`, the quest book when there is no NPC, as the stock
  `SetPortraitToUnit`) in a 48px well, the NPC's name beside it.
- **Body:** a friendship NPC's standing first (`NPCFriendshipStatusBarMixin`:
  `C_GossipInfo.GetFriendshipReputation(0)`; its icon or the heart, the rank,
  a Skill Bar to the next rank, the stock tooltip's lines), then the greeting.
  `ns.NpcPortrait` and `ns.FriendshipBar` live here and serve the Quest dialog
  too (Core helpers in all but name).
- **List:** in `GossipFrameSharedMixin:Update`'s order: quests to take, quests
  to hand in (the stock icons by quest ID, `QuestUtil.Get*ForQuestID`;
  trivial and ignored ones in textMuted with the icon greyed), then the
  options (`C_GossipInfo.GetOptions`, `orderIndex` order) with their game
  icons (`overrideIconID` first), the Quest and Play Movie prefixes, and the
  option's spell tooltip. Click: `SelectAvailableQuest`, `SelectActiveQuest`,
  `C_GossipInfo.SelectOptionByIndex`. Keys 1-9 pick (ours; the stock frame has
  none).
- **No Goodbye button:** the stock one only closes; ✕ and Escape do
  (DESIGN.md: never a footer Close).
- **Left out (client):** the stock `OnShow` hides the spirit healer's `XP_LOSS`
  popup (`StaticPopup_Hide`); from addon code that would taint the shared
  StaticPopup frames, so that popup stays until answered. Quest text contrast
  and the NPC's background art (texture kits) are the stock parchment's.
- **Taint:** none protected; a gossip that opens another window (vendor,
  trainer) flows into that window's interaction.
- **Tests:** `stub_gossip.lua` (`CustomGossipFrameManager` with the stock dispatch, `C_GossipInfo` with friendship); scenes `gossip` (the base handler is ours, the NPE guide kit still goes to its handler, `GOSSIP_CLOSED` closes ours, prefixes, portrait), `gossip-quests` (the stock order), `gossip-friend` (the friendship bar).
