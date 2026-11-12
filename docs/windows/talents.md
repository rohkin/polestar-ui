#### Talents (`PlayerSpellsFrame`, its talents tab) — Risk: high
Opened by `TOGGLETALENTS` and `TalentMicroButton` through `ns.Doors`, as the
Spellbook (in combat too); shift-click on the micro button opens the stock
window. Not before the first talent point
(`C_SpecializationInfo.HasPlayerEarnedATalentPoint`): the stock micro button
is disabled until then and its overlay steps aside, and the key does nothing.
Talent links and inspecting another player stay the game's.
Forever's talents are the classic three trees on the client's trait engine
(`C_Traits`, one tree, a node group per talent tree): changes are staged, then
applied. Not protected, but refused in combat and while
`C_ClassTalents.CanChangeTalents` says no; switching spec is a cast.
- **Shell:** 1100×680 with sidebar: wider than the shell's 960, so three
  four-column trees stand apart.
- **Subject block:** the class icon (the class atlas, `GetClassAtlas`), the class in Title, "Level 60" in Small
  textDim.
- **Sidebar:** the shell's search ("Search talents"), then the stock tabs as
  nav rows, Primary and Secondary (`DUAL_SPEC_PRIMARY`/`SECONDARY`): the
  active spec's row with the dot, the other with its points spent as the
  count. Until dual spec is learnt (`GetNumSpecGroups() > 1`) Secondary is
  locked, as the stock tab: the lock glyph, receding (a count of 0), a click
  does nothing, and its tooltip is the stock `TALENT_SPEC_LOCKED`.
- **Search:** as the stock frame's, a talent matches on its name or its
  description; the others recede to 25%, and the subtitle counts the matches
  ("7 talents match."). The stock search options on a filter at the end of
  the search row (a 30px `sliders` square on the search field's well, as the
  Spellbook's), lit while one is on, kept for the session as stock: "Hide
  passives" (`C_Spell.IsSpellPassive` talents never match) and "Show ranks"
  (each match's chip shows its ranks of the most, "2/3", widening to fit),
  then "Clear filters" while one is on.
- **Main column:** title "Talents", subtitle the points left ("12 points to
  spend.", "Every point is spent."), then "Your changes are not applied
  yet." while something is staged, and "Applying your talents…" while Apply
  runs. Viewing the spec that is not active, the
  subtitle says so ("Not your active spec.") and the footer's primary action
  is "Activate" (the stock `SetActiveSpecGroup`), the trees read-only.
- **Art:** the class's talent art, as the stock frame shows it
  (`talent-background-<class>`, one atlas, a panel per tree), fills the main
  column under the band at 85%, under a wash of Polestar's sky at 55%: full
  width, the middle band of its height (its aspect kept), so each panel sits
  behind its tree. Both fade to nothing over 160px at the column's left and
  right edges, and over 80px either side of each seam between the art's
  panels (at a third and two thirds), so no hard line shows between trees. A game texture, so a game thing (the Two Families Rule); the
  wash keeps it in Polestar's grounds and follows the theme.
  Where it meets the band, a hairline (the border wash), full at the middle,
  fading to nothing at the column's edges.
- **Trees:** the three trees side by side, each a column a third of the main
  column (the art's panels, between its seams): the tree's nodes on a 52px
  grid of at least four columns, centred in the column, under its heading,
  centred too: its icon (24px), its name in Heading and the points spent in
  Number textDim 8px after it, kept two digits wide so the heading does not
  move as points go in. The grid is read off the client's positions
  (`posX`, `posY`), which sit a few units off it: one cell is the smallest
  step between positions that is at least a quarter of the largest, and each
  node rounds to the nearest cell. A node reads as the stock one: a 40px game
  icon on an inset well (`ns.ItemWell`, a button); partly learnt, its 1px border and rank in success;
  maxed, in the accent; open to a point, the hairline and no rank. Greyed as
  the stock button greys (`CalculateVisualState`): a talent keeps its colour
  while it has points or can take one now (`canPurchaseRank`, prerequisites
  met, the active spec, its cost, `C_Traits.GetNodeCost`, on hand); else its
  icon is desaturated, at 30% while its tier is closed (`isAvailable`), at
  75% otherwise (a prerequisite missing, no point to spend, the inactive
  spec). The rank (the
  points in it, "3") is in Number text on a solid 18px chip (the bg ground,
  its 1px border in the node's state colour) centred on the well's
  bottom-right corner, shown once learnt: legible over any icon. Prerequisites are the client's
  edges, drawn as 2px lines in the border wash under the nodes, in the accent
  once met.
- **Node:** on the active spec, click puts a point in and right-click takes
  one back, as the stock buttons allow (`canPurchaseRank`, `canRefundRank`):
  `C_Traits.PurchaseRank`/`RefundRank` stage it on the config, with the stock
  spend and refund sounds, and the window and tooltip redraw at once. While
  Apply runs, clicks change nothing. The tooltip is the stock talent
  tooltip's lines, built as the
  stock frame builds them: the name, "Rank 3/5", the subtext ("Passive"), this
  rank's text and, once learnt, "Next Rank:" with the next one's
  (`AppendInfo("GetTraitEntry")`), then the tier gate it waits on ("Requires
  10 points in Affliction", `C_Traits.GetConditionInfo`) and an unmet
  prerequisite; after a blank line, the hint for what a click does now ("Click
  to learn a rank. Right-click to take one back. Drag it to an action bar.
  Shift-click to link it in chat."). Shift-click links the spell. A learnt
  talent that is not passive drags its spell to a bar (`C_Spell.PickupSpell`,
  as the stock `TalentButtonBaseMixin:OnDragStart`); not in combat, where the
  client blocks the pickup from addon code (CLIENT.md, rule 4). Such a
  talent on no action bar says so in its tooltip, as stock (the light blue
  `TALENT_BUTTON_TOOLTIP_NOT_ON_ACTION_BAR`; read out of combat).
- **Footer:** "Reset" (danger) on the left, as the stock ResetButton's "all
  talents": confirmed by `W.Modal`, it stages every point of the spec back
  out (`C_Traits.ResetTreeByCurrency` for each of the tree's currencies);
  Apply keeps it, Undo drops it. "Undo" (default, drops what is staged:
  `RollbackConfig`) and "Apply" (primary, `C_ClassTalents.CommitConfig`, the
  stock apply sound) on the right. All three always there so the layout never
  moves, disabled as Polestar disables (faded to 45%) with the reason in
  their tooltip: "Not your active spec", "Applying your talents…", "Nothing
  to apply", "Nothing to undo", "No points spent", or Apply's
  `CanChangeTalents` error, as the stock Apply. The commit is a cast, ended
  by `TRAIT_CONFIG_UPDATED` or `CONFIG_COMMIT_FAILED`, or after the stock
  frame's 6 seconds. On the spec that is not active, "Activate" takes
  Apply's place, as the stock ActivateButton
  (`C_SpecializationInfo.SetActiveSpecGroup`, not protected): a cast, the
  subtitle "Switching to this spec…" until `ACTIVE_TALENT_GROUP_CHANGED`
  (then that spec shows, now the active one) or 10 seconds; disabled in
  combat ("Not in combat").
- **Options:** first in the "..." menu, a disabled line saying the micro button's
  shift-click opens the game's talents (its search and inspect, until ours has
  them: the Nothing Lost Rule).

