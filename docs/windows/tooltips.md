#### Tooltips (`GameTooltip` and the stock tooltips) — Risk: low

Built first of the HUD. The game's own tooltips, restyled in place and never
replaced: other addons add their lines to them (`AddLine`,
`TooltipDataProcessor`), so their text, lines and layout stay the game's.
Covered: `GameTooltip`, `ItemRefTooltip`, `ShoppingTooltip1/2`,
`ItemRefShoppingTooltip1/2`, `EmbeddedItemTooltip`, `GameNoHeaderTooltip`
and `GameSmallHeaderTooltip` (`Modules/Tooltips.lua`).
- **Ground:** Polestar's tooltip ground, solid (`Theme.TIP_GROUND`, as 0.4.0's own tooltips), no longer scaled by Background opacity. A 1px border hairline, square, in
  place of the stock border (its NineSlice's pieces faded out). Ours lies on
  the NineSlice, so an embedded tooltip, whose art the game hides, shows
  none.
- **"Equipped" plate:** the comparison tooltips' header plate
  (`CompareHeader`, ShoppingTooltipTemplate) on the same ground and
  hairline, its stock atlas faded out, the label (the game's text, font
  object `GameTooltipText`) in `text` in place of gold.
- **Health bar:** the stock bar, flat (the white texture) on a shade track at
  60%; its colour stays the game's.
- **Type:** the tooltip font objects (`GameTooltipHeaderText`,
  `GameTooltipText`, `GameTooltipTextSmall`) in Polestar's face (heading, body
  and small weights) at the game's sizes. Line colours stay the game's
  (quality, red requirements).
- **Not changed:** the item tooltip's border (the stock one shows no quality
  colour), special styles' overlays (`TopOverlay`, `BottomOverlay`).
- **Switch:** `/pui tooltips on|off`, live: off gives back the stock pieces,
  bar texture and fonts at once. No window, so no "..." menu and no
  stock-side button.

