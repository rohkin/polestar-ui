#### Legacy (`LegacySystemFrame`, Blizzard_LegacySystem) — Risk: high
Forever's account-wide progression: a renown track (faction 2802), the
challenges (achievements) and a legacy talent tree (`C_Traits`). The stock
window's show and hide run `UpdateMicroButtons`, so it is never touched
(CLIENT.md, rule 8): `TOGGLELEGACYSYSTEM` and `LegacyMicroButton` open ours
through `ns.Doors`, and like the stock toggle only from the first legacy
point. `TOGGLEACHIEVEMENT` (which Forever routes to the challenges) opens ours
on Challenges; challenge links (`ShowLegacyChallenge`) stay the game's.
- **Shell:** 960×680 with a section rail (as the Professions windows), headed
  by the Legacy emblem: Rewards, Challenges and Tree, with the stock tabs'
  game icons. The sidebar shows on Challenges only (subject block: the Legacy
  emblem, "Legacy", the player's legacy points, the track's renown level; the
  search; the categories); the other pages take its width, the main column
  hung off the rail (CLIENT.md, rule 12).
- **Reward Track:** progress toward the next reward (a skill bar, points over
  the reward's points), then a row panel, one row per reward level: the points
  it needs, the reward's game icon, its name and description
  (`RenownRewardUtil`), a check when earned or a lock. The next reward carries
  the accent mark. Tooltips are the stock card's.
- **Challenges:** the client's achievement categories in the sidebar, folding
  as the stock list does: a top category with sub-categories is a group row
  (label face) whose chevron folds them, opened for the class's own category
  and while searching; one without is a row of its own. Built as the stock
  list builds it: any depth, each level starting at its parent's label; the
  client's list can name a child before its parent; only categories with a
  challenge in the client's search list (set, even empty, after every
  loading screen) and their parents show. Text only, no icon on
  any row. Each row counts the challenges shown and carries the stock
  "unviewed" dot (`LegacyChallengeViewedUtil`, marked viewed on opening). The sidebar search is the client's (`SetAchievementSearchString`,
  answered by `ACHIEVEMENT_SEARCH_UPDATED`); a category with no match dims.
  No tabs: the stock filter (Completed, Incomplete, both shown at first; one
  earned by another character is incomplete) is a menu on a filter button at
  the end of the search row, as the crafting window's, its glyph in the accent
  while a filter hides challenges. A row per challenge: game icon, name, description,
  its legacy points (`GetTraitCurrencyForAchievement`) and the date earned. A
  click unfolds its objectives in two columns (a counted one as a skill bar);
  shift-click links it in chat, or tracks it with no chat box open.
- **Legacy Tree:** three `C_Traits` trees (Professions, Adventure,
  Progression; `C_Traits.GetConfigIDByTreeID`), one shown at a time. The
  sidebar holds the search (the tree's talents: a talent that does not match
  recedes) and the trees, each with its art and the points spent in it. The
  page: the tree's heading (art, name, points in it), then its talents on the
  client's grid (read off its positions, as Talents) centred in the page, each
  with its ranks as the stock button shows them ("0/5") on a chip, and the
  client's edges edge to edge, in the accent once met. Click spends a rank,
  right-click takes one back, staged until Apply (`C_Traits.CommitConfig`,
  changes held until `TRAIT_CONFIG_UPDATED` or `CONFIG_COMMIT_FAILED`). Footer:
  Apply, then Undo while something is staged, else Reset (`C_Traits.ResetTree`,
  on a second click). The subtitle says the points left to spend.
- **Subtitles** are status lines only: "3 of 65 legacy points earned" on
  Rewards and Challenges, the points left to spend (or the search's matches,
  or "Applying your changes…") on the Tree. What each page is for is its
  rail button's tooltip.

