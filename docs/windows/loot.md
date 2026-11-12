#### Loot (`LootFrame`) — Risk: high
`LootFrame` registers its own `LOOT_OPENED`/`LOOT_CLOSED` and ends the loot
as it hides (`CloseLoot`); the gamepad smart navigation focuses it. As the
quest dialog, ours needs the stock frame's open event unregistered (the
user's leave), off after `/reload`. `LootSlot` is not protected (the stock
click is plain Lua), but loot under the mouse and autoloot are the game's:
with autoloot the window flashes, as the stock one.
- **Shell:** none: a small panel (`Theme.Skin(f, "window")`, 240 wide), at
  the cursor when `lootUnderMouse` is on, else the stock place. A row per
  slot: Item Well (32px), name in quality colour (legible), count; coin
  slots as a Money line. Click loots (`LootSlot`); the bind and
  distribution confirms stay the game's StaticPopups (`LOOT_BIND`, shown by
  `GameEvent`); master loot's candidate menu as the stock one.
- **Group loot rolls** (`GroupLootFrame`, `START_LOOT_ROLL`) are not part of
  it.
- **Tests:** `stub_loot.lua` (`LootFrame` with its events, `GetLootSlotInfo`, a coin slot); scenes `loot` (`LootSlot` on click, `LootFrame` never shows), `loot-cursor` (`lootUnderMouse`).

