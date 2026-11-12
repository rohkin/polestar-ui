#### Loot (`LootFrame`) — Risk: high
`LootFrame` registers its own `LOOT_OPENED`/`LOOT_CLOSED` and ends the loot
as it hides (`CloseLoot`); the gamepad smart navigation focuses it. As the
quest dialog, ours needs the stock frame's open event unregistered (the
user's leave), off after `/reload`. `LootSlot` is not protected (the stock
click is plain Lua), but loot under the mouse and autoloot are the game's:
with autoloot the window flashes, as the stock one.
- **Shell:** none: a small panel (`Theme.Skin(f, "window")`, 240 wide), at
  the cursor when `lootUnderMouse` is on; else where Edit Mode put the stock
  frame when the player moved it (its anchor, read off `LootFrame`, never
  written), else the stock panel's left slot. A row per slot, as
  `LootFrameMixin:Open` lists them: Item Well (32px), the name in quality
  colour (legible) over the quality ("Uncommon", the stock tag), count; a
  quest item's mark over the icon (the stock border, the bang on one that
  starts a quest, the stock `TEXTURE_ITEM_QUEST_BANG`/`_BORDER`); a locked one red; a currency container as what it holds
  (`CurrencyContainerUtil`). A coin slot shows the game's money text, a line
  per coin, as the stock row (the client gives no copper amount). Click loots
  (`LootSlot`); a modified click links or dresses up. Hovered, the game's
  tooltip is drawn again each frame (a modifier shows the comparison) and the
  cursor follows the dress-up modifier (`CursorUpdate`, `CursorOnUpdate`),
  as the stock row's `OnUpdate`. Empty loot plays the stock empty sound.
- **Combat:** a name the client hands over secret shows through a string on
  a game font (ours take no secret, CLIENT.md rule 3); the other values are
  read through `ns.Clean`.
- **Master loot:** the game answers a click with `OPEN_MASTER_LOOT_LIST`. The
  stock menu (`GroupLootFrame_OnLoad`) acts on `LootFrame.selectedSlot`, which
  only the stock row writes and we may not (rule 15), so it opens at the
  cursor with no slot. Ours opens a frame later on the clicked row and takes
  its place (the menu manager closes the open menu): Master Looter, Assign
  Loot with the candidates (`GetMasterLootCandidate`, by class then name, in
  a raid under their class), Request Roll (`DoMasterLootRoll`). An item at
  `MasterLootQualityThreshold` or better asks first in `W.Modal` (the stock
  `CONFIRM_LOOT_DISTRIBUTION` text), then `GiveMasterLoot`.
- **The game's:** the bind and roll confirms (`LOOT_BIND`, shown by
  `GameEvent`); group loot rolls (`GroupLootFrame`, `START_LOOT_ROLL`).
- **Left out (client):** the stock frame hides `LOOT_BIND` and
  `CONFIRM_LOOT_DISTRIBUTION` as it closes (`StaticPopup_Hide`); from addon
  code that would write into the shared StaticPopup frames and taint the next
  popup's protected action, so a bind confirm left open stays until answered
  (it then binds nothing: the loot is closed). Gamepad smart navigation and
  "Loot All" (`C_LootFrame.TryAutoLoot`, the gamepad footer's) are the
  gamepad UI's, where this module is off by default.
- **Tests:** `stub_loot.lua` (`LootFrame` with its events and Edit Mode place, `GetLootSlotInfo` with quest items and a coin slot, master loot's candidates and the game's menu); scenes `loot` (`LootSlot` on click, `LootFrame` never shows, quest marks, quality tags, the hovered tooltip and cursor, empty sound), `loot-cursor` (`lootUnderMouse`), `loot-master` (the menu, the confirm, a raid's classes), `loot-moved` (the Edit Mode place, secret names in combat).
