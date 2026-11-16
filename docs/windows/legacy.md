#### Legacy (`LegacySystemFrame`, Blizzard_LegacySystem) — Risk: high
Forever's account-wide progression: a renown track (faction 2802), the
challenges (achievements) and a legacy talent tree (`C_Traits`). The stock
window's show and hide run `UpdateMicroButtons`, so it is never touched
(CLIENT.md, rule 8): `TOGGLELEGACYSYSTEM` and `LegacyMicroButton` open ours
through `ns.Doors`, and like the stock toggle only from the first legacy
point. `TOGGLEACHIEVEMENT` (which Forever routes to the challenges) opens ours
on Challenges; challenge links (`ShowLegacyChallenge`) stay the game's.
- **Shell:** the compact grid (`ns.Compact`), 760 wide (was 1088 with the
  rail and sidebar) and about 600 tall (was 720). No sidebar: the sections are
  a slim 48px icon rail (`ns.GameRail`, `slim`; Rewards, Challenges, Tree)
  with the stock tabs' game icons, the Legacy emblem on the rail's head, and
  each label and what the page is for in the rail tooltip. The tab row shows
  on Challenges (the filter at its right end, the search at the top of its
  dropdown, `ns.SearchInFilter`) and the Tree (the three trees as tabs, each
  with its points spent, the same button holding the search alone); the Reward Track has neither. The player's legacy points lead the
  subtitle's status line. Challenges keep their categories in a 184px column
  of the page, left of the list (own scroll, a hairline on its right edge).
- **Reward Track:** progress toward the next reward (a skill bar, points over
  the reward's points), then a row panel, one row per reward level: the points
  it needs, the reward's game icon, its name and description
  (`RenownRewardUtil`), a check when earned or a lock. The next reward carries
  the accent mark. Tooltips are the stock card's.
- **Challenges:** the client's achievement categories in their column, folding
  as the stock list does: a top category with sub-categories is a group row
  (label face) whose chevron folds them, opened for the class's own category
  and while searching; one without is a row of its own. Built as the stock
  list builds it: any depth, each level starting at its parent's label; the
  client's list can name a child before its parent; only categories with a
  challenge in the client's search list (set, even empty, after every
  loading screen) and their parents show. Text only, no icon on
  any row. Each row counts the challenges shown and carries the stock
  "unviewed" dot (`LegacyChallengeViewedUtil`, marked viewed on opening). The search is the client's (`SetAchievementSearchString`,
  answered by `ACHIEVEMENT_SEARCH_UPDATED`); a category with no match dims.
  No page tabs: the stock filter (Completed, Incomplete, both shown at first; one
  earned by another character is incomplete) is a menu on a filter button at
  the tab row's end, under the search, as Social's, its glyph in the accent
  while a search runs or a filter hides challenges (tooltip "Search and
  filter (n on)"), with "Clear
  filters" (both shown again, as the stock reset) in the menu then. A row per challenge: game icon, name, description,
  its legacy points (`GetTraitCurrencyForAchievement`) and the date earned,
  or "Tracking" in the accent while an unfinished one is tracked (the stock
  card's Track box), redrawn at once as it is tracked. A
  click unfolds its objectives in two columns (a counted one as a skill bar);
  shift-click links it in chat, or tracks it with no chat box open.
- **Legacy Tree:** three `C_Traits` trees (Professions, Adventure,
  Progression; `C_Traits.GetConfigIDByTreeID`), one shown at a time. The
  tab row holds the trees and the search (the tree's talents: a talent that does not match
  recedes); each tree tab counts the points spent in it. The
  page: the tree's heading (art, name, points in it), then its talents on the
  client's grid (read off its positions, as Talents) centred in the page, each
  with its ranks as the stock button shows them ("0/5") on a chip, and the
  client's edges edge to edge, in the accent once met. Click spends a rank,
  right-click takes one back, staged until Apply (`C_Traits.CommitConfig`,
  changes held until `TRAIT_CONFIG_UPDATED` or `CONFIG_COMMIT_FAILED`). Footer:
  Apply, then Undo while something is staged, else Reset (`C_Traits.ResetTree`,
  on a second click); a greyed Apply or Reset says why in its tooltip, and a
  greyed talent's tooltip says whether it is fully learnt or lacks points. The subtitle says the points left to spend.
- **Subtitles** are status lines only: "3 of 65 legacy points earned" on
  Rewards and Challenges, the points left to spend (or the search's matches,
  or "Applying your changes…") on the Tree. What each page is for is its
  rail button's tooltip.

