#### Social (`FriendsFrame`) — Risk: medium
Forever loads `Blizzard_FriendsFrame`'s Camelot files: three bottom tabs,
Contacts (`FriendsListFrame`, its header's Battle.net status and the ignore
list as a toggle inside it; `RecentAlliesFrame`), Raid (`RaidFrame`) and
Quick Join. No Who tab (Who is `LFGVanilla`'s, `TOGGLEWHOTAB`) and no guild
tab (`TOGGLEGUILDTAB` opens Communities): both stay the game's.
`FriendsFrame`'s show and hide run `UpdateMicroButtons`, so it is never
touched (CLIENT.md, rule 8): `TOGGLESOCIAL`, `TOGGLEFRIENDSTAB` and
`TOGGLERAIDTAB` open ours through `ns.Doors` (keys only: Forever has no
social micro button). The chat's friends button (`QuickJoinToastButton`),
Battle.net toasts, `/friends` and the gamepad radial call
`ToggleFriendsFrame` and stay the game's: they are the way to the stock
window (its Quick Join and Recruit a Friend, until ours has them: the
Nothing Lost Rule, said in the Options menu).
- **Shell:** 760×600 with sidebar (240). Subject block: the class icon with
  the player's Battle.net presence as a dot, the player's name, and the
  BattleTag in Small textDim ("Battle.net offline" when disconnected). The
  whole block is a button (the stock BattleNetBar): its menu sets Online,
  Away, Busy or Appear offline (`C_BattleNet.SetAFK`/`SetDND`/
  `SetAppearOffline`) and copies the BattleTag (a modal with it selected).
- **Band:** the page title; on Friends the subtitle is "5 of 8 friends
  online", on the other pages one line saying what the page is. Options
  (the Nothing Lost Rule: Quick Join, Recruit a Friend and the raid's
  groups stay on the game's window) is the band's only button.
- **Sidebar:** the shell's search ("Search for keywords"; names and
  Battle.net character names) and, on Friends, a Filter icon button ending
  the search row as in Crafting (accent while a filter is on). Its menu is
  the stock list's: Status (Online, Away, Busy, Offline, In Queue, Available
  For Queue), then the Interests and Roles tags this game type supports (no
  Delves on Forever), and Clear filters; a pick keeps it open. Battle.net
  friends filter through `C_BattleNet.SearchFriends`; WoW friends stay only
  for the presence filters. Then Friends, Recent allies, Friend requests, Ignored, Raid as
  nav rows, each with its count.
- **Friends:** the stock list's folding groups "Favorites 2/5" and "Friends 9/54" (online of
  shown), Battle.net favorites, then online Battle.net and WoW friends, then
  offline ones. Each row: the presence pip in its top-left corner (success,
  warning, danger, textMuted), the name in Body (a WoW friend in class
  colour, legible; offline in textMuted), a favorite's star after it (the
  stock atlases `friends-icon-favorites`, `-dis` offline). The second line,
  Small textDim: "Thessaly · Lvl 26 Druid · Darkshore" with the class in
  class colour, the friend's rich presence out of WoW, "Last online 3 days
  ago" offline; one line sits centred. Fixed slots at the right: the
  friend's client icon as the stock card sets it
  (`C_Texture.SetTitleIconTexture`, `Enum.TitleIconVersion.Small`; faded
  for another WoW project, none offline), then the invite "+", faint when
  disabled with a tooltip saying why. The row's tooltip is the stock
  card's: the character (level, class, race, zone, faction, "In a group")
  or the rich presence, the note ("Note: ..."), the tags, the broadcast and
  when it was sent, "Last online" offline, and the other game accounts; a
  WoW friend's level, zone and note. Notes are set from the right-click
  menu (Set Note), as in the stock list. Click whispers, right-click opens the
  game's menu (`FriendsFrame_ShowDropdown`/`ShowBNDropdown`, where favorites
  are set), double-click invites. Footer: "Add friend" (primary; `W.Modal`
  with a name field, a BattleTag sends a Battle.net invite), "Send message".
- **Friend requests:** the stock Friend Requests tab: a folding "Received
  (3)" group of cards, each the requester, the kind (Battle.net, Real ID or
  WoW friend) and "Sent 2 days ago"; Accept, and Decline's menu as the
  stock card's: Decline, Report player (`ReportFrame:InitiateReport`, a
  Friend report) and, for a Battle.net request, Block invites behind a
  confirm (`C_BattleNet.SetBlocked`, then decline). A Real ID request shows
  the stock tab's one-time notice (CVar `pendingInviteInfoShown`).
- **Recent allies:** `C_RecentAllies` in the client's order: level, class,
  where they are and how you met. `TryRequestRecentAlliesData` is restricted
  (addon code may not call it): until the data is ready the page says to
  load it in the game's window (/friends, its Recent Allies tab), and
  `RECENT_ALLIES_DATA_READY` fills it. As the stock tab: the folding groups
  "Legacy friends", "Pinned" and "Recent allies" (online/total), a presence
  pip and the invite "+", the pin mark in the client icon's slot (the stock
  atlases; red when the pin nears its end, faint when unpinned), whose click
  pins or unpins (`C_RecentAllies.SetRecentAllyPinned`); "Friend request
  sent" when one went this session. The tooltip is the stock card's: level
  and class, race, faction, where, the note ("Note: ..."; set from the
  right-click menu, as stock), the latest activity and when. The Filter
  button shows here too, with the stock tab's own menu: Status (Online,
  Away, Busy, Offline) and Categories this game type supports, through
  `C_RecentAllies.SearchRecentAllies`; each list keeps its own picks.
- **Ignored:** the stock ignore list (its Battle.net bar menu's Ignore List)
  in full: "Ignored players (2)", then "Blocked Battle.net invites (1)"
  (`BNGetBlockedInfo`), each row with an ✕ (`C_FriendList.DelIgnore`,
  `C_BattleNet.SetBlocked(id, false)`). Footer: "Ignore player", the stock
  Block button: a friendly player targeted is ignored at once, else a name
  dialog (`ADD_IGNORE`'s).
- **Raid:** the eight groups as two columns of row panels (name, class
  colour, role), read only; the stock drag between groups and the raid
  ready check stay on the stock tab (pointed to in Options).
- **Taint:** no protected or restricted calls (`C_FriendList`,
  `BNSendWhisper`, `C_PartyInfo.InviteUnit` are not; never
  `C_RecentAllies.TryRequestRecentAlliesData`). Battle.net names and notes
  are secret in combat on some clients: read out of combat, `issecretvalue`
  guard (rule 3).
- **Tests:** `stub_social.lua` (a `FriendsFrame` whose `Hide`/`Show` error
  from addon code, `C_FriendList`, `C_BattleNet`, `C_RecentAllies`, title
  icons); scenes `social` (keys through override bindings, refused in
  combat; order, client icons, row slots), `social-battlenet`,
  `social-filter` (filter menu, groups, pips, invite, presence),
  `social-requests`, `social-ignored`, `social-allies`, `social-raid`, `social-secret` (names secret in combat
  keep the last read).
