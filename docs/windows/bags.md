#### Bags (`ContainerFrameCombinedBags`, `ContainerFrame1`..`N`) — Risk: high
**Stage 1 built** (`Modules/Bags.lua`); stages 2-4 below are still the plan.
Made with the `stock-to-polestar` skill.

## As built (stage 1)
- **Window:** `PolestarUIBags`, `W.Shell` 484 wide, `ns.Float` (never
  docked; first at the stock bags' place, bottom right clear of the right
  bars; dragged, kept in `PolestarUIDB.pos`), `ns.WindowMenu`, `ns.Plain`,
  `ns.Compact`, `ns.TopNav(f, {})` for the search ("Search the bags",
  `C_Container.SetItemSearch`; closing ours clears it only if ours set it).
  Height fits the bags, 600 at most, then the body scrolls.
- **Band:** "Bags", subtitle "Name · n of m free." (`ns.PlayerText`, free
  and total over the backpack and bags 1-4, counted from empty slots, so no
  secret free count is read).
- **First row:** the equipped bags (backpack, bags 1-4, reagent bag; 28px
  wells, icon and `SetInventoryItem` tooltip only) and the money (`ns.Money`).
- **Grid:** one grid whatever `combinedBags` says: backpack and bags 1-4,
  then the reagent bag on a new row, then the keyring (while
  `C_ActionBar.ShouldShowKeyring()` and `showKeyring`) on a new row, so every
  bag is reachable before stage 2's sections. Each slot is the stock
  `ContainerFrameItemButtonTemplate`, named `PolestarUIBagsItem<n>`, on a
  holder frame per bag (`holder:SetID(bag)`), `SetID(slot)`,
  `RegisterForClicks("AnyUp")` (live check 5: the template's own does not
  take; docs/CLIENT.md rule 18), `ClearAllPoints` before placing (the
  template's BOTTOMRIGHT anchor). Template art emptied (normal, pushed,
  highlight, `IconBorder` alpha 0, `BattlepayItemTexture` hidden); our well
  skin and icon (`ns.ItemWell` with the template), `W.Hover`, `ns.PaintItem`
  (quality, count, locked desaturated), search miss at alpha 0.25, the
  template's own `UpdateQuestItem`, `CooldownFrame_Set` on its `Cooldown`
  with clean values only (dimmed while `enable` is 0). New items: a 2px
  accent edge on a child frame, pulsing, from `C_NewItems` (kept past a
  stock close, which clears the flags); hover clears it (hooked `OnEnter`), closing ours
  clears every flag (`RemoveNewItem`, as `UpdateNewItemList`).
- **Footer:** "Clean up" (`UI_BAG_SORTING_01`, `C_Container.SortBags`).
- **"..." menu:** "Combine bags" / "Separate bags" (`combinedBags`), then
  "Use game window" (live: ours closes, the game's keys and bag bar show
  the stock bags at once). Until stage 2 the separate look still
  draws one grid in ours; the CVar is what the game's own bags follow.
- **Doors:** `ns.Doors` keys `OPENALLBAGS`, `TOGGLEBACKPACK`,
  `TOGGLEBAG1`..`4`, `TOGGLEREAGENTBAG1`: each toggles the whole window
  (until stage 2's sections), checked against `ContainerFrame_AllowedToOpenBags`.
  Post-hooks (only while on): toggles `ToggleAllBags`, `ToggleBackpack`,
  `ToggleBag`; opens `OpenBag`, `OpenBackpack`, `OpenAllBags(frame)`,
  `OpenAllBagsMatchingContext(frame)`; close `CloseAllBags(frame)`. The
  stock frames (`ContainerFrameCombinedBags`,
  `ContainerFrame1`..`NUM_CONTAINER_FRAMES`) are parked under a hidden frame
  of ours while on (docs/CLIENT.md rule 19): the game's calls open and close
  them there, unseen, no stock `OnShow`/`OnHide` running; each hook parks any
  that closed since (one shown at switch-on), and the intent is settled at the
  frame's end from ours' state at its first hook. `CloseBag`/`CloseBackpack` are not hooked (deviation):
  `CloseAllBags` calls them past the stock opener check, which can differ
  from ours. Ours plays the open and close sounds (the parked frames play
  none: that is their `OnShow`/`OnHide`).
- **Opener:** `ns.OpenBags(f)` / `ns.CloseBags(f)` (Core): `ns.Interaction`'s
  `o.bags` (Merchant, Bank, Mail, Auction) opens ours with `f` as opener, and
  closes it only if `f` opened it; a hook's `OpenAllBags(frame)` and
  `OpenAllBagsMatchingContext(frame)` record the opener only when ours was
  closed.
- **Enchants:** Forever opens the bags for an enchant through
  `GameEvent.HandleEnchantSpellSelected` ->
  `OpenAllBagsMatchingContext(dispatcher)` (the `CURRENT_SPELL_CAST_CHANGED`
  route is the gamepad combined frame's only): `bags-targeting` follows that.
- **Off:** live both ways (`M.Apply`; refused in combat by `ns.Switch`, as
  every window). Off: ours closes, each parked frame is hidden while still
  parked, then given back to its own parent closed; the hooks and keys do
  nothing. On: the hidden stock frames are parked; one shown stays until the
  game closes it (the bag bar's next click closes it and opens ours; the
  "Polestar" button over it clicks its close button). Other code calling
  `IsBagOpen`/`IsAnyBagOpen` gets the parked frames' state, which can differ
  from ours (ours also opens and closes on its own: keys, close, NPC
  windows). The bank's stock bag frames are parked too (as before, they
  never showed while Bags is on). The bag bar's open-bag highlight no longer
  lights (it was the stock `OnShow`'s).
- **Not in stage 1** (stage 2/3 below): sections (separate look, reagent bag,
  keyring), the strip's equip/pick-up/hover light/filter menu, the backpack's
  locked extra slots, currencies, junk coin, crafting quality and warbound
  overlays, Polestar's upgrade arrow, step glow and quest mark. The split is
  the template's stock `StackSplitFrame` (decided); no search sync with the
  Bank (decided).
- **Scenes:** `bags`, `bags-barclick`, `bags-combat`, `bags-npc`,
  `bags-targeting`, `bags-off`, and the second `auction-bags` panel.

## Plan: the player's bags -> Polestar

Stock: Forever loads mainline's `Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua`
and `.xml` (Camelot's `ContainerFrame.lua` only stubs
`ContainerFrame_UpdatePortraitPosition` and `ShouldUseBagIconForEmptySlot`).
Two looks, picked by the `combinedBags` CVar
(`ContainerFrameSettingsManager:IsUsingCombinedBags`): one
`ContainerFrameCombinedBags` for the backpack and bags 1-4, or one
`ContainerFrameN` per bag. The reagent bag (bag 5,
`NUM_REAGENTBAG_FRAMES`) and the keyring (`KEYRING_CONTAINER`, only while
`C_ActionBar.ShouldShowKeyring()` and the `showKeyring` CVar) are always
frames of their own. The bag bar (`BagsBar`, `MainMenuBarBackpackButton`,
`CharacterBag0Slot`..`3`, `CharacterReagentBag0Slot`, `KeyRingButton`;
`Blizzard_MainMenuBarBagButtons`) is an Edit Mode system and stays the
game's (CLIENT.md rule 17).

### Strategy
**Replace.** Checklist: nothing secure or other addons write lines into the
bag frames (Polestar decorates their item buttons, see Parts); they are not
pooled UI-wide; not a protected dialog; their OnShow/OnHide touch no secure
frame (sounds, their own events, `C_NewItems`, `UpdateContainerFrameAnchors`
on themselves, the bag bar's `SlotHighlightTexture` through the
`ContainerFrame.OpenBag`/`CloseBag` callbacks, `HelpTip`); hiding them ends
nothing. So "otherwise": ours replaces them, and the stock frame a game door
shows is closed with its own `Hide()` in a post-hook (Contract step 2). Not
an NPC window: no interaction. `reloadOff = true` (see Taint).

Ours is one window, `PolestarUIBags`, whatever `combinedBags` says: in the
combined look one grid; in the separate look a section per bag. It holds
"open sections" as the stock UI holds open frames: backpack+bags (one key
when combined, one per bag when not), reagent bag, keyring. It hides when
none is open.

### Layout
- **Shell:** `W.Shell(NAME, { scalePath = "ui.menuScale", width = 484, searchPlaceholder = "Search the bags", onSearch })`,
  `ns.WindowMenu(f, "bags", options)`, `ns.Plain(f)`, `ns.Compact(f)`,
  `Polestar.CloseOnEscape(NAME)`. The grid is Bank's (11 columns, 36px wells,
  4 apart), so as wide as the grid needs: 484 = 436 + 2 × 24 pad + 2 edge (computed from COLS, SIZE, GAP; no scrollbar gutter, it sits in the pad). Height fits the rows, at most 600; past that
  the body scrolls (`W.ShellBody`).
- **Not docked.** The stock bags are no UI panel (no `UIPanelLayout`); ours
  opened beside Merchant or Bank must not push them or be closed by the dock
  as "oldest". New Core helper `ns.Float(f)`: the dock's `offLayer` (parent
  UIParent, keep strata) and the stock bags' first place
  (`UpdateContainerFrameAnchors`: BOTTOMRIGHT of UIParent, x
  `-(EditModeUtil:GetRightActionBarWidth() + 10)`, y `85`), draggable, kept in
  `PolestarUIDB.pos[NAME]` as a free window.
- **Band:** title "Bags"; subtitle the subject first: "Thrall · 23 of 98
  free." (`C_Container.GetContainerNumFreeSlots` over the open bags). The
  name is secret in combat (rule 3): lift Character's `playerText` into Core
  (`ns.PlayerText(fn)`), Character then uses it.
- **Tab row:** no tabs (`ns.TopNav(f, {}, nil, ...)`): only the search at its
  right end.
- **Body, first row:** a strip of the equipped bags (28px wells: backpack,
  bags 1-4, reagent bag, keyring when shown) at the left, the player's money
  (`ns.Money`) at the right end, as Bank's first row.
- **Body:** the grid (combined), or a `W.SectionHeader` per open bag (bag
  name `bagNames`/`C_Container.GetBagName`, "7 free") over its grid
  (separate; reagent bag and keyring always so). The not-secured backpack's
  four extra slots (`ContainerFrame_GetContainerNumSlots`: max = current + 4
  while `not IsAccountSecured()`) are faded plain wells
  (`ns.ItemWell`), tooltip `BACKPACK_AUTHENTICATOR_INCREASE_SIZE`.
- **Body, last row:** the watched currencies (`C_CurrencyInfo.GetBackpackCurrencyInfo(i)`,
  as `BackpackTokenFrameMixin:Update`): icon and count, tooltip
  `GameTooltip:SetCurrencyByID`, a click opens the Currency page
  (`ns.Show("character", ...)`, as `TokenFrame` is where you watch them).
- **Footer:** "Clean up" (`PlaySound(SOUNDKIT.UI_BAG_SORTING_01)`,
  `C_Container.SortBags()`, as `BagItemAutoSortButton`; no confirm, stock asks
  none for bags).
- **"..." menu:** "Combine bags" / "Separate bags" (`SetCVar("combinedBags")`,
  `AddButtons_BagModeToggle`), divider, "Use game window" (after /reload).

### Parts
| Stock part (template / S/ pointer) | Polestar element | API + example call site | Risk / gotcha |
|---|---|---|---|
| Frame `PortraitFrameFlatTemplate` (`ContainerFrame.xml`, `ContainerFrameCombinedBags`) | `W.Shell` + `ns.Compact`, floating | `ns.Float` (new, Core.lua); `build` in `Bank.lua` | Never `ns.Dock` (above) |
| Portrait, title, free count `CountContainer` | band: `W.ShellTitle(f, "Bags", sub)` | `paint` in `Bank.lua` | name via `ns.PlayerText` |
| Close `UIPanelCloseButton`, `CloseAllWindows` | shell close, `Polestar.CloseOnEscape` | every module | `CloseAllWindows` also calls `CloseAllBags()`: hooked, closes ours |
| `BagItemSearchBox` (`BagSearchBoxTemplate`) | shell search on the tab row, `C_Container.SetItemSearch` | `build` in `Bank.lua` | One client search shared with the bank; ours clears it on hide as Bank does |
| Item slots `ContainerFrameItemButtonTemplate` (`ContainerFrame.xml`, `ContainerFrameItemButtonMixin`) | **the stock template itself**, made by us, restyled (Taint, below) | new local `bagGrid` in `Bags.lua` (per-bag holder frames, not `ns.ItemGrid`: the template's `GetBagID` is the parent's `GetID`) | Never write a key the mixin reads (`bagID`, `OnClick`, `SplitStack`, ...). Name each button (`PolestarUIBagsItem<n>`): the template's `$parentCooldown` child |
| Slot art (NormalTexture, IconBorder, PushedTexture, Highlight, the icon) | inset well look: `Theme.Skin(w, "inset")`, `Theme.Border`, our `ns.GameIcon` icon, `W.Hover`, count; template art emptied (`ClearNormalTexture`, `SetPushedTexture(nil)`, `IconBorder:SetAlpha(0)`) | `ns.ItemWell` + `ns.PaintItem` (copy their skin calls; or give `ns.ItemWell` an optional template arg) | `ns.PaintItem` writes `w.Icon`/`w.psCount` (keys the mixin never reads: fine; the template's own icon is `w.icon`) |
| Quest border/bang `IconQuestTexture` | the template's, via its own `w:UpdateQuestItem(isQuestItem, questID, isActive)` | `C_Container.GetContainerItemQuestInfo` (as `paintSlot` in `Bank.lua`) | — |
| Cooldown `Cooldown` child | the template's, `CooldownFrame_Set` only with clean values | `paintSlot` in `Bank.lua` (`ns.Clean`) | Rule 3. `ContainerFrameItemButtonMixin:UpdateCooldown` is not called (it would feed secret times). Dim when `enable == 0` |
| New-item glow `NewItemTexture`, `flash`, `BattlepayItemTexture` | ours: an accent edge, pulsing (`W.Painter`, an AnimationGroup) | `C_NewItems.IsNewItem` | Kept in our own set (Doors: the stock hide clears the flags); hover clears it (the template's `OnUpdate` calls `RemoveNewItem`), and closing ours clears all as `UpdateNewItemList` |
| Junk coin `JunkIcon` | the template's texture, shown by us | quality Poor, `not info.hasNoValue`, and our Merchant (`PolestarUIMerchant`) or the stock one shown | Stock shows it only with `MerchantFrame` (merchant.md's gap): ours fixes it for our Merchant |
| Locked, search miss | desaturated (`ns.PaintItem` desat), alpha 0.25 on `isFiltered` | `paintSlot` in `Bank.lua` | — |
| Item context dim `ItemContextOverlay` (socketing, scrapper) | the template's own (ItemButton updates it on its context events) | — | Check it shows in the stub; restyle not needed |
| Crafting quality pips, warbound overlay `IconOverlay` | the template's, through `SetItemButtonQuality(w, quality, link)` | ItemButton mixin | Then fade `IconBorder` again (that call shows it) |
| Upgrade arrow `UpgradeIcon` | Polestar's verdict on the template's arrow | `Polestar.Gear.Bags.IsOn()` / `.IsUpgrade(link)`, feature-detected | Polestar draws its arrow, step glow and quest mark only on the stock bags, Baganator and EllesmereUI (`Gear/Bags.lua`, `QoL/BagGlow.lua`, `Quests/BagMarks.lua`): ours is a fourth view, painted from `Polestar.QoL.BagGlow.Items(...)` and `Polestar.QuestDB.IsItemNeeded(id)` (with `qol.questBagMarks`), repainted on the events those files listen to. Never edit Polestar |
| Split `StackSplitFrame` (opened by the template's `OnModifiedClick`) | **left stock** (a shared dialog, as StaticPopup) | — | Bank uses a Polestar stepper; ours cannot without taking the template's click (Taint) |
| Bag bar slots (`BaseBagSlotButtonMixin`: click puts the cursor item in, else toggles; drag picks the bag up; tooltip with filters) | the first-row strip: wells with the bag's icon | `C_Container.ContainerIDToInventoryID`, `GameTooltip:SetInventoryItem`; `PutItemInBag(inv)`/`PutItemInBackpack()`, `PickupBagFromSlot(inv)` through `ns.Pickup`; `wireBag` in `Bank.lua` | Hover lights that bag's wells (the stock `BagSlot.OnEnter` highlight, Bank's `glow`). Click in the separate look toggles the bag's section. Check 6 (not protected) |
| Bag menu (`PortraitButton` dropdown: Assign to, Ignore clean up, Exclude from junk sell) | right-click a strip well: `W.ShowMenu` with `checked` items | `C_Container.Get/SetBagSlotFlag`, `Get/SetBackpackAutosortDisabled`, `Get/SetBackpackSellJunkDisabled` (`ContainerFrame_AddButtons_BagFilters`, `_BagCleanup`) | Flat, no submenus: one menu per bag fits. Backpack, profession and reagent bags take no filter (`ContainerFrame_CanContainerUseFilterMenu`). Redraw after (rule 6) |
| `MoneyFrame` (`ContainerMoneyFrameTemplate`) | `ns.Money` on the first row | `ns.SetMoney(money, GetMoney())` | Coin pickup (classic money frames) only if live shows the stock one does it |
| `BackpackTokenFrame` | last body row | `C_CurrencyInfo.GetBackpackCurrencyInfo` | Max watched: check 9 |
| Sort `BagItemAutoSortButton` | footer "Clean up" | `cleanUp` shape in `Bank.lua` | — |

### Item use: the stock template, no secure overlay
Use, sell, attach, socket and enchant-apply from the bags are protected
(`C_Container.UseContainerItem`; applying a waiting spell). Bank answers that
with an `ns.Overlay` secure button over the hovered slot, which is out of
combat only and hides on `PLAYER_REGEN_DISABLED`. For the bags that would
mean no potion, food or quest item from our bags in combat: not acceptable.
And secure buttons in the window would stop it opening and closing in combat
(rule 4).

So every well **is** a `ContainerFrameItemButtonTemplate` button we create.
The template is not secure (stock bags open, close and use items in
combat); its scripts (`OnClick`, `OnEnter`, `OnDragStart`,
`OnReceiveDrag`, ...) are Blizzard's. A hardware click therefore starts in
Blizzard's code, and `ContainerFrameItemButton_OnClick` calls
`UseContainerItem` untainted, as long as nothing it reads was written by us:
- **Bag ID from the parent:** the mixin's `GetBagID` is
  `self.bagID or self:GetParent():GetID()`. Never call `SetBagID` (it goes
  through `SetAttribute("bagid")` and `OnAttributeChanged` writes
  `self.bagID` from our code). Each bag's wells hang off a holder frame of
  ours with `holder:SetID(bag)`; the button's `SetID(slot)`. `GetID` comes
  from the client, carrying no taint.
- **No key the mixin reads:** we write only `ps*` keys, `w.Icon` and the
  skin's keys. The stub guards the rest (Tests).
- **No script replaced:** extra behaviour by `HookScript` only (the hover
  edge, our tooltip hint if any). `W.Hover` adds a texture, no script.
- What the template does on its own, for free and untainted: right-click use
  (food, potions, quest starters, open containers, equip), selling at a
  merchant (the client sells while the interaction is open), attaching at the
  mailbox (Mail sets `SetSendMailShowing`), the stock Trade window,
  shift-click link and the rest of `HandleModifiedItemClick` (ctrl-click
  dress-up), alt-click autoloot of lootable items, `EXPANDITEM` socketing
  (`SocketContainerItem`), split (`StackSplitFrame`), left-click and drag
  pick up and place, and a left-click applying a waiting enchant or stone
  (`SpellCanTargetItem`) securely. Its `OnEnter` fires
  `ContainerFrameItemButton.EnterButton`, so Auction's sell overlay
  (`bagDoor` in `Auction.lua`) lands on our wells unchanged, and Polestar's
  `HandleModifiedItemClick` post-hook still sees bag clicks.
- What reads stock frames and so stays wrong (gaps the doc and the UI say
  nothing new about; they exist today with our Merchant and Bank): the
  buyback-tab guard and the refund prompt on a right-click sell
  (`MerchantFrame.selectedTab`, `ContainerFrame_GetExtendedPriceString`:
  merchant.md), the sell cursor (`CanSellItems`), the bank deposit type
  (`BankFrame:GetActiveBankType()`: bank.md).
- `ns.Pickup` is still the rule for our own pickups (the strip); the wells'
  pickups are the template's, which already apply a waiting spell instead.

**If check 5 fails** (a right-click from a button made by addon code is
blocked), fall back to Bank's shape: plain wells plus an `ns.Overlay` secure
`item` button over the hovered well, out of combat only. Then in combat ours
shows the bags but cannot use from them; the plan goes back to the user
before building, since that loses combat use.

### Doors
| Stock door | Ours | Rule |
|---|---|---|
| Keys `OPENALLBAGS` (B; `ToggleAllBags`), `TOGGLEBACKPACK` (`ToggleBackpack`), `TOGGLEBAG1`..`4` (`ToggleBag(n)`), `TOGGLEREAGENTBAG1` (`ToggleBag(5)`) (`Bindings_Camelot.xml`) | `ns.Doors("bags", "Bags", { OPENALLBAGS = ..., TOGGLEBACKPACK = ..., TOGGLEBAG1 = ..., ... })`: override bindings to our buttons, no stock code runs, ours plays `IG_BACKPACK_OPEN`/`CLOSE` | rule 8 (no stock execution); bindings set out of combat, our show/hide works in combat (no secure child) |
| Bag bar clicks: backpack and bag slots (`BagSlotOnClick` -> `ToggleBag`, shift `OPENALLBAGS` modified click -> `ToggleAllBags`, `BackpackButton_OnModifiedClick`), keyring (`KeyRingMixin:BagSlotOnClick` -> `ToggleBag(KEYRING_CONTAINER)`) | post-hooks (below) | Contract step 2. No overlay on the bag bar: it would have to take the drag and drop of bags too (rule 17's system). Check: one open sound, no close sound; if the close sound plays, stage 4 puts `ns.Doors`-style secure overlays on these buttons |
| Game and other windows: `OpenAllBags(frame)`, `CloseAllBags(frame)`, `OpenBag(id)` (also on `BAG_OPEN`), `OpenBackpack`, `CloseBag`, `CloseBackpack`, `OpenAllBagsMatchingContext(frame)`: stock `TradeFrame`, scrapper, item interaction, `ContainerFrame_OnEvent`'s `CURRENT_SPELL_CAST_CHANGED` (an enchant waiting for its item opens all bags with `ContainerFrame1` as opener), alerts, tutorials, `CloseAllWindows` | post-hooks (below) | Contract step 2 |
| Our NPC windows (`ns.Interaction(..., { bags = true })`: Merchant, Bank, Mail, Auction, Trainer) | Core routes `o.bags` to ours when the module is on (`ns.OpenBags(f)` / `ns.CloseBags(f)`, else the stock calls): no stock frame shown and hidden at every NPC | — |
| Micro button, slash | none exist | — |

**The post-hooks** (`hooksecurefunc` on each global above, only while
`ns.Enabled("bags")`):
1. Every stock bag frame shown is closed at once with its own `Hide()`
   (`ContainerFrameCombinedBags`, `ContainerFrameContainer.ContainerFrames`,
   `ContainerFrame1`..`N`; never `HideUIPanel`, rule 1). Before that, ours
   copies `C_NewItems.IsNewItem` for those bags into its new-item set: the
   stock `OnHide` (`UpdateNewItemList`) clears the flags.
2. The intent is recorded, and decided once at the end of the frame
   (`C_Timer.After(0)`), from ours' state at the first hook of that frame:
   the stock toggles open everything from the inside (`ToggleAllBags` ->
   `OpenAllBagsInternal` -> `OpenBackpack` -> `OpenBag`), and since the stock
   frames are always closed, a toggle always "opens" there. Any toggle with
   ours shown at the start closes ours (that section, for `ToggleBag`);
   otherwise the sections asked for open. Opens are idempotent.
3. Opener as the stock `FRAME_THAT_OPENED_BAGS`: `OpenAllBags(frame)` /
   `OpenAllBagsMatchingContext(frame)` record `frame:GetName()` only when ours
   was closed; `CloseAllBags(frame)` closes ours only when it names the
   opener (or no frame is given); a close clears it.
4. Nothing opens unless `ContainerFrame_AllowedToOpenBags()` (the
   `BagsUIDisabled` game rule, `CanOpenPanels`); the keys check it too.

Other code calling `IsBagOpen`/`IsAnyBagOpen` now gets false (the stock frames
are shut): say so in the entry.

### Taint and combat
- No protected call from our code: item use is the template's own click
  (above). Our calls: `C_Container.PickupContainerItem` is not ours to make
  (the template does), `PickupBagFromSlot`/`PutItemInBag`/`PutItemInBackpack`
  (check 6), `C_Container.SortBags`, `SetBagSlotFlag`, `SetCVar`: none
  protected.
- The window has no secure child, so B opens and closes it in combat. Layout
  in combat (a bag changes size) is plain `SetPoint` on non-secure buttons.
- As built, the stock frames are never hidden or shown from our code: they
  are parked under a hidden frame (docs/CLIENT.md rule 19), so off is live.
  (Stage 1 first hid them from the post-hooks: their `OnHide` ran as ours,
  `ContainerFrameSettingsManager:MarkBagsShownDirty` wrote a key, the next
  stock open read it and the stock item buttons' `SetBagID` ran tainted, so
  off waited for `/reload`.) The hooks do nothing while off.
- Rule 17: no call on `BagsBar` or its buttons, no overlay anchored to them.
  The parked frames' `OnShow`/`OnHide` never run, so their
  `UpdateBagButtonHighlight` on the bag bar does not either.
- Secret values (rule 3): free counts, `GetContainerItemInfo` and
  `GetContainerItemCooldown` are read through `ns.Clean`/`ns.Num` (checks 7,
  8); a secret cooldown keeps the sweep set before combat. The player's name
  via `ns.PlayerText`. Stock code never writes into our `W.Text`.
- Fonts via `W.Text` (rule 2). Redraw at once after our own client changes:
  bag flags, `combinedBags` (rule 6). No frame 0 wide as an anchor: holder
  frames and the grid are sized from layout numbers, never 0 (rule 12).
- Gamepad UI on: off by default (Contract step 4; the stock bags are the
  smart navigation's).

### Tests
- `tests/lua/stub_bags.lua`: `C_Container` bags 0-5 and the keyring (slots,
  items, quest info, cooldowns, free slots, bag flags, search), `C_NewItems`,
  `GetCVar("combinedBags")`, `Constants.InventoryConstants`,
  `C_ActionBar.ShouldShowKeyring`, `GetKeyRingSize`, `IsAccountSecured`,
  `C_CurrencyInfo.GetBackpackCurrencyInfo`, `PickupBagFromSlot`/`PutItemInBag`;
  the stock toggles in their real shape (show `ContainerFrameCombinedBags` /
  `ContainerFrameN`, the stock `OnHide` clearing `C_NewItems`, the internal
  `OpenBackpack`/`OpenBag` calls of `ToggleAllBags`, `FRAME_THAT_OPENED_BAGS`);
  a `ContainerFrameItemButtonTemplate` for `CreateFrame("ItemButton", ...)`:
  the mixin's `GetBagID` (`bagID or parent:GetID()`), an `OnClick` that calls
  a stub `UseContainerItem` (recorded in `stub.used`), picks up, applies
  while targeting, links on shift, and fires `ContainerFrameItemButton.EnterButton`
  on enter; it errors when addon code writes a key the mixin reads (`bagID`,
  `OnClick`, `GetBagID`, `SplitStack`, `hasStackSplit`) or replaces one of its
  scripts with `SetScript` (a new CLIENT.md check if a live bug teaches it).
  Coordinate with `stub_npc.lua`'s `OpenAllBags`/`CloseAllBags` and Polestar's
  `stub_gear.lua` (its own `ContainerFrameCombinedBags`): one shape, loaded once.
- Scenes:
  - `bags`: combined; the strip, money, currencies, subtitle "Name · n of m
    free."; wells are the template, `GetParent():GetID()` is their bag, no
    `bagID` key; B (`stub.pressKey`) opens and closes ours with no stock
    toggle run; a right-click calls `UseContainerItem(bag, slot)`; a new item
    glows, hover clears it, closing clears all.
  - `bags-barclick`: the backpack button's stock `ToggleBackpack` and the
    shift `ToggleAllBags`: ours opens, the stock frame is hidden the same
    frame, its new items still glow in ours; a second click closes ours.
  - `bags-separate`: `combinedBags` 0; `TOGGLEBAG2` opens that section only,
    a second closes it and, last, the window; reagent bag and keyring
    sections.
  - `bags-combat`: `stub.inCombat`: B opens and closes ours; a right-click
    still uses; no secure frame shown or moved; a secret cooldown and count
    leave no error.
  - `bags-npc`: our Merchant opens ours through `ns.OpenBags` (no stock
    frame shown); the junk coin shows; `CloseAllBags(otherFrame)` leaves ours,
    closing the Merchant closes it.
  - `bags-targeting`: `CURRENT_SPELL_CAST_CHANGED` opens with
    `ContainerFrame1` as opener; a left-click applies; the end closes ours only
    if that opened it.
  - `bags-strip`: a strip right-click menu sets a bag flag (redrawn), hover
    lights the bag's wells, a click with a bag on the cursor puts it in.
  - `bags-off`: off at login, the game's toggles show the stock frame;
    switching says "after /reload".
  - `auction-bags` gains a panel: the overlay lands on our well.
- Bless each (`node tools/preview.js <scene>`), `npm test`.

### Live checks (in game, before building)
Each is one line to paste; note what it prints.
1. Combined or separate bags:
   `/run print(GetCVar("combinedBags"), ContainerFrameSettingsManager:IsUsingCombinedBags())`
2. Bag slots and the reagent bag:
   `/run local c=Constants.InventoryConstants print(c.NumBagSlots, c.NumReagentBagSlots, C_Container.GetContainerNumSlots(5))`
3. Keyring:
   `/run print(C_ActionBar.ShouldShowKeyring(), GetCVar("showKeyring"), KEYRING_CONTAINER, GetKeyRingSize and GetKeyRingSize())`
4. Slots per bag, account secured:
   `/run local t={} for b=0,5 do t[#t+1]=C_Container.GetContainerNumSlots(b) end print(table.concat(t," "), IsAccountSecured())`
5. **The item-use strategy.** Put a food or potion in the backpack's first
   slot, then make a template button from addon-like code:
   `/run local p=CreateFrame("Frame",nil,UIParent)p:SetID(0)p:SetAllPoints()local b=CreateFrame("ItemButton","PUIT",p,"ContainerFrameItemButtonTemplate")b:SetID(1)b:SetPoint("CENTER")b:Show()`
   Right-click the square at screen centre out of combat, then again in
   combat (a target dummy); shift-click and a left-click too. Pass: the item
   is used both times, and BugGrabber has no ADDON_ACTION_BLOCKED/FORBIDDEN.
   `/reload` after.
6. Bag pickup is not protected (then `/run ClearCursor()`):
   `/run PickupBagFromSlot(C_Container.ContainerIDToInventoryID(1)) print(CursorHasItem())`
7. Item cooldowns secret in combat (enter combat within 5 s, an item on
   cooldown in backpack slot 1):
   `/run C_Timer.After(5,function() local s=C_Container.GetContainerItemCooldown(0,1) print(issecretvalue and issecretvalue(s)) end)`
8. Bag contents secret in combat (same way):
   `/run C_Timer.After(5,function() local i=C_Container.GetContainerItemInfo(0,1) print(i and issecretvalue and issecretvalue(i.stackCount)) end)`
9. Watched currencies:
   `/run print(BackpackTokenFrame and BackpackTokenFrame:GetMaxTokensWatched(), C_CurrencyInfo.GetBackpackCurrencyInfo(1) ~= nil)`

**Results so far (live):**
- 1: `combinedBags` "1", `IsUsingCombinedBags()` true.
- 4: slots for bags 0-5: 20 12 12 14 12 6 (reagent bag 6). `IsAccountSecured()`
  true, so the backpack has no locked extra slots on this account.
- 3: keyring shown, true.
- 5 (first try): `CreateFrame("ItemButton", ..., "ContainerFrameItemButtonTemplate")`
  from /run returns a button. With its icon set and moved to screen centre,
  a right-click did not use the item, out of combat or in combat, and nothing
  was blocked. So this is no taint block: the click never reached the
  template's use path. The template's own BOTTOMRIGHT anchor put it under the
  micro menu first. Source read (grep only): nothing in Forever overrides
  `ContainerFrameItemButtonMixin:OnClick`, `GetBagID` is
  `self.bagID or self:GetParent():GetID()` (0 here), and the right-click path
  ends in `UseContainerItem` with no attribute or `type` involved (the
  template is not secure). Suspect: `OnLoad` failed before its
  `RegisterForClicks("LeftButtonUp", "RightButtonUp")` (a button then takes
  left-ups only, and a right-click does nothing, silently), or the click
  never landed on the button. Retest with explicit `RegisterForClicks` and a
  click print (coordinator's lines). Ask too: did a left-click pick the item
  up, and did the tooltip show?
- 5 (retest): **passed.** Holder `SetID(0)`, button `SetID(1)`: right-click
  used the item out of combat and in combat, no ADDON_ACTION_BLOCKED, the
  tooltip showed on hover, left-click picked up. Right-click worked only
  after `b:RegisterForClicks("AnyUp")` from our code (the template's own
  registration does not take on an addon's button), and the template's
  default BOTTOMRIGHT anchor must be cleared (docs/CLIENT.md rule 18).
- Open questions settled: the look follows `combinedBags`; the stock
  `StackSplitFrame` stays; no search sync between Bags and Bank for now.
- 2, 6-9: pending.

After stage 1, in game: the backpack button plays one sound and no stock
frame flickers; nothing on the bag bar in BugGrabber.

### Build split
Stage 0 is the user's live checks. Each stage is atomic commits, goldens with
their change.
1. **Shell, wells and doors** (Opus: secure item use, doors, taint). Core:
   `ns.Float`, `ns.OpenBags`/`ns.CloseBags` and their use in
   `ns.Interaction`, `ns.PlayerText` (Character switched to it). `node tools/new-window.js bags ContainerFrameCombinedBags`,
   then `Modules/Bags.lua`: combined grid of template wells (skin, count,
   quality, locked, quest, cooldown, new glow, search), money, subtitle,
   Clean up, `ns.Doors` keys, the post-hooks, `reloadOff`. `stub_bags.lua`;
   scenes `bags`, `bags-barclick`, `bags-combat`, `bags-npc`,
   `bags-targeting`, `bags-off`, the `auction-bags` panel. Row in
   `docs/DESIGN.md` (index and the size list), `.toc` line before Tooltips,
   CHANGELOG, this entry rewritten as built.
2. **Sections and the strip** (Sonnet): the separate look and its keys,
   reagent bag and keyring sections, the bag strip (equip, pick up, hover
   light, filter menu), the backpack's locked extra slots, currencies, the
   "..." menu's combine switch. Scenes `bags-separate`, `bags-strip`.
3. **Marks** (Sonnet): junk coin with our Merchant, crafting quality and
   warbound overlays, and Polestar's upgrade arrow, step glow and quest mark
   (feature-detected). Goldens.
4. **Only if the live pass needs it** (Opus): secure overlays on the bag bar
   buttons (a close sound or flicker on a bar click).

### Open questions
- Check 5 decides the item-use strategy; a failure goes back to the user
  (combat use is lost on the fallback).
- Split: the stock `StackSplitFrame` (ours keeps the template's click intact)
  differs from Bank's Polestar stepper. Accept, or move Bank to the template
  too for one look (not in this plan)?
- The bank, opened beside ours, still deposits a right-clicked item into the
  stock bank's active type (bank.md); it stays a gap.
- A separate-look section per bag inside one window, not a window per bag:
  confirm that look.
- Bags and Bank share one client search: should either window's box show the
  other's text while both are open?
