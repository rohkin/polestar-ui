#### Guild (`CommunitiesFrame`) — Risk: medium
The stock window is the Guild & Communities window (`Blizzard_Communities`):
a list of the guild, communities, invitations and the finders down its left,
and on the selected guild the side tabs Chat, Roster, Guild Benefits (only
while `GetNumGuildPerks() > 0` or `C_GuildInfo.IsGuildReputationEnabled()`)
and Guild Info, plus Guild preferred play settings where
`C_GuildInfo.GetPreferredPlaySettingsFeatures` allows them. Camelot overrides
only `CommunitiesFrame_ShouldDisplayPersonalAchievements` (false: no
Achievement points column). Its `OnShow` and `OnHide` run `UpdateMicroButtons`
and `OnHide` flushes the club state (`C_Club.ClearClubPresenceSubscription`,
`C_Club.Flush`), so it is never touched (CLIENT.md, rule 8): `TOGGLEGUILDTAB`
opens ours through `ns.Doors`, and `GuildMicroButton` carries our secure
overlay, whose shift-click opens the game's window. As `ToggleGuildFrame`:
nothing for a Neutral character. Doors only the game's code knows stay the
game's: the guild news toast (`AlertFrameSystems`), club finder and community
links, `/guildfinder`, the gamepad radial. `M.stock()` answers
`CommunitiesFrame`.

Ours is the guild only. **Communities** (Battle.net and character
communities), **community and guild chat streams** (the stock Chat tab, voice),
**Guild Finder / Community Finder**, **recruitment settings and applicants**
(the stock Guild Recruitment button, the Applicants and Pending columns),
invitations and tickets stay on the game's window (shift-click the micro
button; said in the "..." menu): each is a window of its own, and their
messages need the club stream API ours does not draw. The guild's chat is in
the chat frame: "Guild chat" opens its edit box on `/g`.

- **Data:** the stock roster's own: `C_Club.GetGuildClubId()`,
  `C_Club.GetClubMembers` and `C_Club.GetMemberInfo` (presence, level,
  class, zone, `guildRank`/`guildRankOrder`, notes, last online, professions,
  dungeon score), `C_GuildInfo.GuildRoster()` asked on show as the stock Info
  tab does. These read `SecretInChatMessagingLockdown`: a read that comes back
  secret keeps the last clean roster (rule 3).
- **Shell:** the compact grid (`ns.Compact`), no sidebar: the stock side tabs
  are a slim 48 icon-only rail (`ns.GameRail`, `slim`; labels in tooltips),
  740 wide and 520 tall (was 808 x 600), content laid out by `f.psPad`. The rail wears the stock tabs' own icons in their order:
  Roster (`achievement_guildperk_everybodysfriend`), Benefits
  (`achievement_guildperk_honorablemention`; only as the stock tab shows),
  Info (`inv_misc_scrollunrolled01`), then News and Log, which sit on the
  stock Guild Info tab and have no tab icon of their own: note icons
  (`INV_Misc_Note_02`, `inv_misc_note_06`). Not in a guild: one Guild tab and
  a page saying so, and that Guild Finder is on the game's window.
- **Band:** the guild's name (Display); under it, one line, "Officer · 9 members".
- **Tab row:** it holds no tabs; it shows on every page (`psKeepTabRow`) so content starts at one y. At its left,
  the page's fact (`f.psOnline`): "6 online" (Roster), "3 news items", "2 perks · 3 rewards", "4 events", the
  week's challenges. On the Roster and News, at its right end,
  a search ("Search": name, zone,
  rank, note) and a Filter icon at its right end: Show offline members (the stock check box;
  CVar `communitiesShowOffline`) and the stock column dropdown's choices that
  can show here (Professions where `C_TradeSkillUI.IsGuildTradeSkillsEnabled`,
  Dungeon score where `C_MythicPlus.IsMythicPlusActive`; Achievement points is
  off on Camelot). On News, the Filter icon alone (the news filters).
- **Roster:** the stock columns, each header a sort button as stock
  (`SortByColumnIndex`: a second click reverses; ours sorts A to Z and low to
  high first, ties in the stock order; zone puts online members by zone, then
  offline ones by last online): Level, class icon, Name (class colour; textMuted offline),
  Zone ("Last online 3 days ago" / "Mobile" as the stock column), Rank, Note,
  then the chosen extra column. The default order is the stock one
  (`CommunitiesUtil.SortMemberInfo`: presence, level, rank, name). Professions
  groups the roster under each profession as stock (folding heads, skill in
  the column, a click asks the member's recipes:
  `C_GuildInfo.QueryGuildMemberRecipes`). Rows are 26 tall in one row panel,
  drawn only where seen (a guild has up to 1000 members). Tooltip: the stock
  entry's (name, rank, level race class, zone or Mobile, note). Click opens the
  member's details; right-click the game's `COMMUNITIES_GUILD_MEMBER` menu
  (`UnitPopup_OpenMenu`, as stock: whisper, invite, promote to leader, leave,
  report, copy name).
- **Member details:** a flyout on the right edge (the stock
  `GuildMemberDetailFrame` beside the window): name, "Level 60 Mage", zone,
  Online or last online; Rank: a button with the stock rank menu where the
  player may promote or demote (`CanGuildPromote`/`CanGuildDemote` and rank
  orders as stock; a rank `C_GuildInfo.IsGuildRankAssignmentAllowed` refuses is
  greyed with the stock authenticator reason; `C_GuildInfo.SetGuildRankOrder`);
  Note and Officer note (only with `CanViewOfficerNote`), read-only: an Edit
  icon where allowed (`CanEditPublicNote` or self; `CanEditOfficerNote`),
  greyed, its tooltip pointing to the game's guild window (shift-click the
  Guild micro button); see Taint;
  Remove (danger, confirm; `CanGuildRemove` and a lower rank;
  `C_GuildInfo.RemoveFromGuild`) and Group invite (online on WoW only;
  `C_PartyInfo.InviteUnit`).
- **Info:** the stock Guild Info tab: Message of the day and Guild
  information, each with Edit for those allowed (`CanEditMOTD`,
  `CanEditGuildInfo`; 255 and 499 letters; `C_GuildInfo.SetMOTD`/`SetInfoText`),
  and the guild challenges with progress or a check where
  `GetNumGuildChallenges() > 0` (`RequestGuildChallengeInfo`).
- **News:** the stock news list: the message of the day, up to 7 guild
  calendar events, then `GetGuildNewsInfo` under their date headings, sticky
  ones marked. Tooltip as stock (the item, the achievement and its
  description, the boss and zone). Shift-click links the item; right-click:
  View achievement / Link item and, for those who may edit the MOTD, Make
  sticky / Remove sticky (`GuildNewsSetSticky`). The Filter icon is the stock
  filter popup (`GetGuildNewsFilters`, `SetGuildNewsFilter`, the stock hidden
  filters). The guild master impeachment banner where `CanReplaceGuildMaster`
  (`ReplaceGuildMaster` behind a confirm). Opens with `QueryGuildNews`,
  `GuildNewsSort(0)` and `C_Calendar.OpenCalendar`, as stock.
- **Benefits:** guild reputation as a Skill Bar where enabled
  (`C_Reputation.GetGuildFactionData`), the perks (`GetGuildPerkInfo`; spell
  tooltip, shift-click links) and the rewards (`RequestGuildRewards`,
  `GetGuildRewardInfo`: icon, name, the achievement or standing it needs, its
  cost in coins red when short; item tooltip, shift-click links).
- **Log:** the stock guild log (`QueryGuildEventLog`, `GetGuildEventInfo`),
  newest first: invites, joins, promotions, demotions, removals, leaves, each
  with how long ago.
- **Footer** (every page): "Leave guild" (danger, confirm; greyed for the
  guild master, who must pass leadership first, as the stock menu hides it),
  then "Guild chat" (`/g`; greyed without `C_GuildInfo.CanSpeakInGuildChat`),
  "Guild control" for the guild master and officers (the stock button:
  `GuildControlUI_Show`, the game's rank window), "Invite member" (primary;
  `CanGuildInvite`; a name field, `C_GuildInfo.Invite`, as `ADD_GUILDMEMBER`).
- **Names:** roster cells, the member flyout's name and notes, and the log and news lines sit on a font family (`ns.NameFont`): Polestar's face for Latin, the client's for Cyrillic, Hangul and Chinese, picked per glyph without reading the text.
- **Taint:** the calls the API docs mark `HasRestrictions`
  (`RemoveFromGuild`, `SetGuildRankOrder`, `SetMOTD`, `SetInfoText`) run only
  from the player's click. `C_GuildInfo.SetNote` is forbidden to addon code even
  from a click, and so is the stock `SET_GUILD_COMMUNITIY_NOTE` popup shown by
  our code: its `which`/`data` are ours, its OnAccept runs tainted and SetNote is
  refused (BugGrabber, both in game). Nothing of ours can open it untainted
  (`/run` macrotext is insecure; the stock note frames take `OnMouseUp`, out of a
  secure click's reach; opening the stock roster from our code taints its member
  info), so notes are edited in the stock window, opened by the player. `GuildControlUI` is the
  game's own dialog (no secure frame in its show or hide), opened by its own
  `GuildControlUI_Show`. Unproven in game: a BugGrabber entry for one moves it
  to the stock window ("..." menu).
- **Deferred:** the stock news boss model on hover (a tooltip instead);
  clicking a calendar event (opening the calendar from our code runs the panel
  manager; the calendar has its own button); the guild rename banner; the
  column headers scroll with the roster.
- **Tests:** `stub_guild.lua` (a `CommunitiesFrame` whose `Hide`/`Show` error
  from addon code, `C_Club`, `C_GuildInfo`, the guild news, perks, rewards,
  log); scenes `guild` (key and micro overlay, sort, offline toggle, combat
  secret keeps the roster), `guild-member` (details, rank menu, notes read-only: Edit greyed with its
  reason, no popup, the stub's `SetNote` erroring,
  remove), `guild-info`, `guild-news`, `guild-benefits`, `guild-log`,
  `guild-none` (not in a guild), `guild-game-looks` (the skin's sizes; search and filter on the tab row).
