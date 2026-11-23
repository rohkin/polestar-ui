#### Bag bar (`BagsBar`: backpack, bag slots, reagent bag, keyring) — Risk: high

The game's bag bar buttons, restyled in place and never rebuilt
(`Modules/BagBar.lua`), in the action buttons' look (`ns.ButtonLook`,
[actionbars.md](actionbars.md)) whatever the action bars' switch says;
a bag slot with no bag (`GetInventoryItemTexture("player", id)` nil, as
`BaseBagSlotButtonMixin:HasBagEquipped`; a secret answer counts as a bag)
shows the action bars' empty-slot star, its icon (the game's empty-bag art)
faded with `SetAlpha`; read on `BAG_UPDATE_DELAYED` (the game's own update
for the slots) and every repaint, never per frame.
`BagsBar` is an Edit Mode system: its place, orientation, direction, size
and slot padding stay the game's (CLIENT.md, rule 17). Clicks (the game's
bag toggles, which our Bags window follows), drag and drop, equipping a bag
and the tooltips stay the buttons' own scripts.
- **Covered:** `MainMenuBarBackpackButton`, `CharacterBag0Slot`..`3`,
  `CharacterReagentBag0Slot`, `KeyRingButton` (shown by the game while
  `C_ActionBar.ShouldShowKeyring()`).
- **Button:** as an action button: frame (normal), pushed and hover art
  faded, the icon unmasked (the template's `SquareMask` and the item
  button's rounded `Mask`, which `ItemButtonMixin:PostOnLoad` puts on it:
  the dark rounded frame in game) and cropped square, cropped again by the
  driver after `SetItemButtonTexture` resets the coords with a new bag, our ground,
  edge (Polestar's window border, 2 px at most), shadow and hover wash; the count and the backpack's `FreeSlots` in
  Polestar's `number` face, outlined (the free count's visibility stays the
  `displayFreeBagSlots` setting's). `UpdateTextures` sets the hover's alpha
  to 0.4 with every icon: the driver fades it again.
- **Open bags:** `SlotHighlightTexture` faded. Lit (the accent wash and
  hairline): every slot while our Bags window shows (Bags on: the parked
  stock bags never light the game's highlight, bags.md), else the game's own
  highlight per bag.
- **Not changed:** item quality (the stock bar shows none on Forever).
- **Bar:** `BagsBar.BorderArt` faded; the dividers between slots
  (`useDividers`: frames of `HorizontalDividersPool`/`VerticalDividersPool`,
  acquired again with each Layout) faded by the driver each frame (in game
  they were the brown bars left between our squares).
- **Baganator:** nothing of it touches the bar; its own bag toggles still
  run from the bar's clicks.
- **Switch:** `/pui bagbar on|off`, live (not in combat). Off by default with
  the gamepad UI.
- **Scenes:** `bagbar`, `bagbar-editmode`, `bagbar-off`; `bags-barclick`
  keeps the clicks.
- **Live checks:** a bag swapped onto the bar (the icon's crop after
  `UpdateTextures`), the reagent bag and keyring, Edit Mode's vertical
  layout.
