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
- **Shell:** 760×600 with sidebar (240). Subject block: the player's
  Battle.net status as a dot on the class icon, the player's name, "12 of 40
  friends online" in Small textDim.
- **Sidebar:** the shell's search ("Search friends"), then Friends,
  Battle.net, Ignored, Raid as nav rows, each with its count.
- **Friends / Battle.net:** a row panel, online first, as the stock list
  sorts: name in Body (class colour, legible), level, class and zone in Small
  textDim; offline rows in textMuted with "last online". Click whispers,
  right-click opens the game's unit popup menu (`FriendsFrame_ShowDropdown`'s
  contexts, so other addons' entries join it), double-click invites. Footer:
  "Add friend" (primary, the stock `AddFriendFrame` flow is a StaticPopup:
  ours is `W.Modal` with a name field), "Send message".
- **Ignored:** rows with an ✕ (`C_FriendList.DelIgnore`).
- **Raid:** the eight groups as two columns of row panels (name, class
  colour, role), read only; the stock drag between groups and the raid
  ready check stay on the stock tab (pointed to in Options).
- **Taint:** no protected calls (`C_FriendList`, `BNSendWhisper`,
  `C_PartyInfo.InviteUnit` are not). Battle.net names and notes are secret
  in combat on some clients: read out of combat, `issecretvalue` guard (rule 3).
- **Tests:** `stub_social.lua` (a `FriendsFrame` whose `Hide`/`Show` error from addon code, `C_FriendList`, `C_BattleNet`); scenes `social` (keys through override bindings, refused in combat), `social-battlenet`, `social-raid`, `social-secret` (names secret in combat keep the last read).

