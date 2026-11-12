#### Gossip (`GossipFrame`) — Risk: medium
Opened by `CustomGossipFrameManager` on `GOSSIP_SHOW`. The stock window ends
the gossip as it hides (`C_GossipInfo.CloseGossip` in its `OnHide`). The
manager offers a default handler (`CustomGossipFrameManager:SetBaseHandler`):
ours takes it, so the game calls ours for every gossip its custom handlers
(the NPE guide) do not take; ours closes itself on `GOSSIP_CLOSED` (the
manager's `HideUIPanel` of ours does nothing from our code, CLIENT.md rule
1). Off waits for `/reload`. Polestar's gossip automation runs on the
events and is unaffected.
- **Shell:** plain, 520×560, no tabs, no sidebar. Band: the NPC's name, the
  greeting under it in Body.
- **List:** quests to hand in, quests to take (the stock icons:
  available, repeatable, complete; trivial in textMuted), then the options
  (`C_GossipInfo.GetOptions`, `orderIndex` order) with their game icons.
  Click: `SelectActiveQuest`, `SelectAvailableQuest`,
  `C_GossipInfo.SelectOption`. Keys 1-9 pick, as the stock frame's.
- **Taint:** none protected; a gossip that opens another window (vendor,
  trainer) flows into that window's interaction.
- **Tests:** `stub_gossip.lua` (`CustomGossipFrameManager` with the stock dispatch, `C_GossipInfo`); scenes `gossip` (the base handler is ours, the NPE guide kit still goes to its handler, `GOSSIP_CLOSED` closes ours), `gossip-quests`.

