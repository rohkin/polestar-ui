#### Professions (`ProfessionsFrame`) — Risk: medium
Opened by the game when a profession is cast (`TRADE_SKILL_SHOW`). The stock
window ends the trade skill as it hides (`CloseTradeSkill` in its `OnHide`), so
it cannot be closed under ours: the game's own open is stopped instead
(`GameEvent.UnregisterInternalEvent("TRADE_SKILL_SHOW")`, CLIENT.md rule 11)
and ours opens on the same event. Ours holds the trade skill: closing it calls
`CloseTradeSkill`, and the game's `TRADE_SKILL_CLOSE` closes it. `TRADE_SKILL_SHOW` can come before the
trade skill's data (the stock window opens empty and fills on
`TRADE_SKILL_LIST_UPDATE`): ours then opens on that update. Doors only
the stock code knows (a recipe link) still open the stock window. Switching
ours off (the window's menu, `/pui crafting off`) takes effect after /reload:
routing `TRADE_SKILL_SHOW` back to the stock window from our code would open
it from tainted code.
- **Shell:** 760×680 with sidebar, near the stock window's width, plus the
  section rail: the Professions window's size, and its place (`ns.LinkPlace`:
  each opens where the other is or was last, kept in `PolestarUIDB.pos`), so
  switching between them never moves the window.
- **Professions rail** (`ns.ProfessionTabs`, shared with the Professions
  window): the shell's section rail (`rail = true`, `W.ShellRail`), Polestar's
  own way to switch sections. "Overview" first (the Professions window,
  closing this one), then one section per profession with a crafting window,
  in the stock order; the open one marked as the rail marks it. The icons are
  the game's (24px, untinted), not glyphs; Polestar's emblem stays off the
  rail. Casting a profession is protected: out of combat a secure button of
  ours takes the hovered section's place (`ns.Overlay`), its click the
  profession's spell; the open one casts nothing. In combat the sections only
  show their tooltips.
- **Subject block:** the profession's icon, name in Title, and its 2px skill
  bar under it with the rank ("112/150") above the bar's right end.
- **Sidebar:** the search (shell's own) and the filter, then the learnt recipes under their
  categories in the client's order, "Favorites" (the client's,
  `PROFESSIONS_CATEGORY_FAVORITE`, as the stock list groups them), "Can make
  now" (nothing missing, no cooldown) and "Recent" (the last 8 crafted here,
  kept per character) first. A recipe row's right-click is the stock list's
  menu: "Set favorite" or "Remove favorite" (`SetRecipeFavorite`; a learnt
  recipe of the player's own).
  A category is a heading row with its count; a click folds it. Under it, one
  recipe row per recipe, its name in the client's difficulty colour
  (`DIFFICULT_`, `FAIR_`, `EASY_`, `TRIVIAL_DIFFICULTY_COLOR`, lifted to read).
  A search shows every match, unfolded.
- **Filter:** it acts on the list, so it sits in the sidebar at the end of
  the search row: a 30px square on the search field's well, the `sliders`
  glyph, in the accent while a filter hides recipes (on the band it read as
  filtering the selected recipe). Its menu drops under it, over the list.
  Its menu is the game's own filter menu, flat (Polestar's menu has no
  submenus): "Has skill up" (not for a guild's recipes), "Have materials",
  then after a hairline "Check all", "Uncheck all" and each item slot. The
  client keeps them (`C_TradeSkillUI.SetOnlyShow*`, `SetInventorySlotFilter`)
  and they act on its filtered recipe list, as in the stock window; the menu
  opens again after each pick.
- **Main column:** title the profession, subtitle the selected recipe's
  category ("<name>'s recipe: you cannot craft it." for another player's).
  One view, so no tab row (Orders later). An Options menu at the band's bottom
  right, the stock link button's: "Link profession" puts the profession's
  link (`GetTradeSkillListLink`) in the chat line, or the macro being
  written; then, under "Post in", Guild, Party, Raid and each chat channel
  post it there, each disabled where the player is not. All disabled for
  another player's recipes or when the client cannot link it
  (`CanTradeSkillListLink`).
  - *Recipe page:* the product as a 40px tile with its name in its quality
    colour (legible) and "Makes 2" when it makes more than one, the stock
    page's favorite star at the row's right end (a 24px `star` icon button,
    in the accent while the recipe is a favorite; not for another player's
    recipes), the recipe's
    description in textDim, the reagents under a "Reagents" heading as reagent
    tiles (two columns, 8px apart), then the tools and places line ("Requires
    Moonwell"), the cooldown and the game's own reason in Note (warning while
    they stop the craft), then "Track recipe", the stock page's checkbox
    (`SetRecipeTracked`: its reagents on the objective tracker), for the
    player's own recipes with reagents; the box and its label toggle it. A
    shift-click on a recipe row tracks it too while the chat line is closed
    (`RECIPEWATCHTOGGLE`), and links it while it is open, as the stock list.
- **Footer:** quantity stepper (−, a 48px field, +, "Max") on the left,
  "Craft all" (default) and "Craft" (primary, the recipe's own verb when it has
  one) on the right; all faded to 45% while the game would refuse the craft or
  the recipes are another player's, the reason in their tooltip, in the stock
  window's order: the game's own reason, "On cooldown", "Missing a
  requirement", "Missing reagents". `C_TradeSkillUI.CraftRecipe` is not
  protected on Forever (`SecretArguments = "AllowedWhenUntainted"`, no
  restriction): our button's click calls it.
  - *Enchants* (`recipeType == Enchant`): after the reagents, "Item to
    enchant" and one item slot, as the game's (`PROFESSIONS_ADD_ENCHANT`,
    "Add an item", in textMuted on an empty well). A click lists the items it
    can go on (`GetEnchantItems`, worn ones marked "(equipped)") in Polestar's
    menu; a right-click clears it; the tooltip is the item's
    (`SetItemByGUID`). With an item, Craft is `CraftEnchant` on its location
    (not protected either), one at a time unless the item stores enchants
    (`CanStoreEnchantInItem`, a vellum); without one, Craft casts the enchant
    and the game asks for the item, as it would from the spellbook (a trade
    window's item). An item no longer in the bags or worn is let go.

