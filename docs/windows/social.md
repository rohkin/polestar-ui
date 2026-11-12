#### Social (`FriendsFrame`) — Risk: medium
In game the stock window is the Social UI (`SocialUIFrame`,
`Blizzard_SocialUI`), which `ToggleFriendsFrame` opens in place of the
Camelot `FriendsFrame`: a Battle.net bar (status, BattleTag, its menu's
Ignore List) and side tabs Friends, Recent Allies, Friend Requests and Raid
(the user's screenshots), plus Quick Join and Recruit a Friend only where
`C_SocialQueue.IsSystemEnabled` / `C_RecruitAFriend.IsSystemEnabled` (not
seen on Forever). No Who tab (Who is `LFGVanilla`'s, `TOGGLEWHOTAB`) and no
guild tab (`TOGGLEGUILDTAB` opens Communities): both stay the game's.
`FriendsFrame`'s show and hide run `UpdateMicroButtons`, so it is never
touched (CLIENT.md, rule 8): `TOGGLESOCIAL`, `TOGGLEFRIENDSTAB` and
`TOGGLERAIDTAB` open ours through `ns.Doors` (keys only: Forever has no
social micro button). The chat's friends button (`QuickJoinToastButton`),
Battle.net toasts, `/friends` and the gamepad radial call
`ToggleFriendsFrame` and stay the game's: they are the way to the stock
window (its Quick Join and Recruit a Friend where the game has them: the
Nothing Lost Rule, said in the "..." menu). `M.stock()` answers
`SocialUIFrame` or `FriendsFrame`, whichever is shown.
- **Shell:** 760×600 with sidebar (240). Subject block: the class icon with
  the player's Battle.net presence as a dot, the player's name, and the
  BattleTag in Small textDim ("Battle.net offline" when disconnected). The
  whole block is a button (the stock BattleNetBar): its menu sets Online,
  Away, Busy or Appear offline (`C_BattleNet.SetAFK`/`SetDND`/
  `SetAppearOffline`) copies the BattleTag (a modal with it selected), sets the
  broadcast (the stock broadcast box: the current message to edit, 127
  letters, `C_BattleNet.SetCustomMessage` on a change) and opens the ignore
  list (the stock Battle.net bar menu's Ignore List).
- **Band:** the page title and its status: "5 of 8 friends online", "1 of 2
  online" (Recent allies; "Not loaded yet" before the data), "3 requests",
  "3 ignored · 1 blocked", "12 of 40 players" or "Not in a raid", "2
  lockouts" (Raid info). The "..." menu's options
  (the Nothing Lost Rule: Quick Join and Recruit a Friend, where the game
  has them, stay on the game's window) come before "Use game window".
- **Sidebar:** the shell's search ("Search for keywords"; names and
  Battle.net character names) and, on Friends, a Filter icon button ending
  the search row as in Crafting (accent while a filter is on). Its menu is
  the stock list's: Status (Online, Away, Busy, Offline, In Queue, Available
  For Queue), then the Interests and Roles tags this game type supports (no
  Delves on Forever), and Clear filters; a pick keeps it open; the tooltip
  counts the picks ("Filter (2 on)"). Presence and tags filter from the
  friends' own data, as the stock search reads them (any checked status, then
  any checked tag); WoW friends stay only for the presence filters. In Queue
  and Available For Queue are on no friend's data: the restricted
  `C_BattleNet.SearchFriends` answers them, called only from the pick's
  click, and that answer holds until the next pick. Then Friends, Recent allies, Friend requests, Ignored, Raid as
  nav rows, each with its count.
- **Friends:** the stock list's folding groups "Favorites 2/5" and "Friends 9/54" (online of
  shown), Battle.net favorites, then online Battle.net and WoW friends, then
  offline ones. Rows as Polestar's Characters page (`Alts/View.lua`) lays
  its characters: each a card of its own (`W.Fill` "panel", `W.Hover`) 44
  tall with a 4 gap, text inset 14, group headings plain on the ground with
  their chevron. Each row: the presence pip before the name (success,
  warning, danger, textMuted), the name in Body (a WoW friend in class
  colour, legible; offline in textMuted), a favorite's star after it (the
  stock atlases `friends-icon-favorites`, `-dis` offline). Under it, Small
  textDim: "Thessaly · Lvl 26 Druid" with the class in class colour; one
  line sits centred. A second column from the middle, Small: where they
  are ("Darkshore"), the rich presence out of WoW, "Last online 3 days
  ago" offline (textMuted). Fixed slots at the right: the
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
  are set), double-click invites. Footer: "Add friend" (primary), the stock
  Add Friend button (`AddFriendFrame_Show`): a friendly player targeted who
  is not yet a friend is added at once; else a `W.Modal` with one field and
  "Send request", as `AddFriendFrame_Accept` decides: a BattleTag (or an
  email, with Real ID) to Battle.net, else a WoW friend request by name
  (`C_BattleNet.SendTitleFriendInviteByName`) where the game has them, else
  the old list (`C_FriendList.AddFriend`); a Real ID request while those
  are off is refused with the stock error. The stock dialog has no note
  field (notes are set afterwards from the menu). Greyed with its reason
  while `C_SocialRestrictions.IsFriendsDisabled()`. Then "Send message".
- **Friend requests:** the stock Friend Requests tab: a folding "Received
  (3)" group of cards, each the requester, the kind (Battle.net, Real ID or
  WoW friend) and "Sent 2 days ago"; Accept, and Decline's menu as the
  stock card's: Decline, Report player (`ReportFrame:InitiateReport`, a
  Friend report) and, for a Battle.net request, Block invites behind a
  confirm (`C_BattleNet.SetBlocked`, then decline). A Real ID request shows
  the stock tab's one-time notice (CVar `pendingInviteInfoShown`).
- **Recent allies:** `C_RecentAllies` in the client's order, in the
  Friends rows: level and class under the name, where they are and how you
  met in the second column. `TryRequestRecentAlliesData` is restricted
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
- **Raid:** the stock Raid tab (`RaidFrameSocialView.lua`). Out of a raid:
  what a raid is and "Convert to raid" (`C_PartyInfo.ConvertToRaid`, on
  when `AllowedToDoPartyConversion(true)`); in a story raid the stock tab's
  "unavailable" line. In one: a bar with the stock All assist box (the
  leader's; `SetEveryoneIsAssistant`) and the role counts ("2 Tanks · 4
  Healers · 6 Damage"); the eight groups two to a row, as the stock grid
  lays them, each a row panel of five: name in class colour (danger when
  dead, textMuted offline), "25 Mage", the leader / assistant atlas before
  the name and the main tank / main assist atlas at the right, where the
  ready check's answer shows while one runs (`GetReadyCheckStatus`,
  `READY_CHECK_*_TEXTURE`). A hovered player gets a secure button of ours
  (`ns.Overlay`, `type1 = target`): a click targets as the stock
  `SecureUnitButton` does, a right-click opens the game's `RAID` menu
  (promote, main tank, remove...), and the leader or an assistant drags a
  player onto another (`SwapRaidSubgroup`) or into a group with room
  (`SetRaidSubgroup`), redrawn at once; out of combat only (the button
  hides in combat) and never while a spell is targeting. All assist, greyed
  for anyone but the leader, says so in its tooltip. Footer: "Raid info" (the stock side window, on while
  saved: `GetSavedInstanceInfo`, world bosses, "Resets in 3 days" or
  "Expired", Extend / Unextend / Reactivate where
  `C_RaidLocks.IsRaidLockExtendFeatureSupported`, greyed with its reason
  where the lock cannot be extended; "Groups" goes back),
  then "Ready check" (`DoReadyCheck`, leader or assistant; the stock raid
  manager's) and "Convert to party" (`AllowedToDoPartyConversion(false)`).
- **Taint:** never `C_RecentAllies.TryRequestRecentAlliesData` (forbidden
  to addons: ADDON_ACTION_FORBIDDEN in game). The calls the API docs mark
  `HasRestrictions` (`C_FriendList.AddFriend`, `C_BattleNet.SearchFriends`
  (the queue filters), `C_BattleNet.SetAFK`/`SetDND`/
  `SetAppearOffline`/`SetBlocked`/`SetCustomMessage`/
  `SendTitleFriendInviteByName`, `C_PartyInfo.ConvertToRaid`/
  `ConvertToParty`/`SetEveryoneIsAssistant`, `DoReadyCheck`,
  `C_ReportSystem.SendReport` behind the report frame) run only from a
  click of the player's, out of combat where they touch the group;
  unproven in game: a BugGrabber entry for one moves it to the stock
  window ("..." menu) and to the deferred list. `SetRaidSubgroup` /
  `SwapRaidSubgroup` are not in the API docs (old globals); called out of
  combat only.
- **Deferred:** Copy BattleTag stays a selected field (`CopyToClipboard`
  is `HasRestrictions`); Quick Join and Recruit a Friend (and the friend
  card's RAF summon) stay the game's, off on Forever as far as seen. Battle.net names and notes
  are secret in combat on some clients: read out of combat, `issecretvalue`
  guard (rule 3).
- **Tests:** `stub_social.lua` (a `FriendsFrame` whose `Hide`/`Show` error
  from addon code, `C_FriendList`, `C_BattleNet`, `C_RecentAllies`, title
  icons); scenes `social` (keys through override bindings, refused in
  combat; order, client icons, row slots), `social-battlenet`,
  `social-filter` (filter menu, groups, pips, invite, presence; the
  restricted search only from a queue pick's click),
  `social-add` (add friend paths, broadcast), `social-requests`, `social-ignored`, `social-allies` (each with its band
  status), `social-raid` (no drag in combat or while targeting, All assist's
  reason), `social-secret` (names secret in combat keep the last read).
