#### Inspect (`InspectFrame`, Blizzard_InspectUI) — Risk: medium
Forever loads the Camelot files (`Camelot/Blizzard_InspectUI.lua`,
`InspectPVPFrame`, `InspectGuildFrame`, `InspectPaperDollFrame.xml`, with
Mainline's `InspectPaperDollFrame.lua` and bootstrap). Every door calls
`InspectUnit(unit)` (the bootstrap): the unit menu's Inspect
(`UnitPopupInspectButtonMixin`), `/inspect` (the target) and other addons.
It loads the addon on demand, and `InspectFrame_Show` asks the server
(`NotifyInspect`) when `CanInspect`; the stock frame then shows itself on
`INSPECT_READY` for its unit (`ShowUIPanel` in its `OnEvent`). There is no
key binding and no micro button. Its `OnHide` forgets the inspected player
(`ClearInspectPlayer`), so it cannot be closed under ours as Character's is:
the data ours shows would go with it. The gamepad smart navigation focuses it
(medium).
- **Doors:** a post-hook on `InspectUnit` notes the unit (when `CanInspect`);
  ours opens on that unit's `INSPECT_READY`. The stock frame's own open is
  stopped as the quest dialog's and loot's: `InspectFrame:UnregisterEvent("INSPECT_READY")`,
  once `Blizzard_InspectUI` has loaded (CLIENT.md, rule 15's exception, here
  extended to this frame and event). Off after `/reload` (`reloadOff`).
  The unit menu's Inspect Talents opens the game's talents window
  (`PlayerSpellsFrame`): it stays the game's (rule 8).
- **Shell:** as Character's: 808×680, no sidebar, the stock mode tabs on
  the icon rail (`ns.GameRail`) with each tab's own icon: Character (the
  unit's portrait, `UNIT_PORTRAIT_UPDATE`/`PORTRAITS_UPDATED`), PvP
  (`INV_SideTab_Honor_Alliance_c60` or `_Horde_c60` by the unit's faction),
  Guild (`INV_Shirt_GuildTabard_01`, only for a unit in a guild, as the
  stock `UpdateTabs`; without one, back to Character). A new inspect opens
  on Character, as `InspectFrame_Show`.
- **Band:** the stock title, `GetUnitName(unit, true)` (with the realm), on
  every tab; the subtitle the stock level line (`SetLevel`): "Level 60
  Paladin", "??" for a hidden level, the effective level beside a scaled
  one, the specialization (`GetInspectSpecialization`) when it differs from
  the class, class in its `RAID_CLASS_COLORS` colour. In combat a secret name
  shows no title, never the last unit's (CLIENT.md, rule 3).
- **Character:** Character's gear layout: two slot columns, the weapons
  under the model, each slot's item name in quality colour, its permanent
  enchant and its sockets beside it; empty, the slot's name in textMuted. No
  ammo slot (the Camelot inspect sheet has none). Slots only show, as the
  stock one: the game's tooltip (`SetInventoryItem(unit, slot)`, redrawn while
  hovered so a modifier compares), the dress-up cursor, and a click is
  `HandleModifiedItemClick` (shift links, ctrl tries it on). The model well
  holds a `PlayerModel` (`ModelWithZoomTemplate`, our frame) set to the unit
  as the stock one (`SetUnit`; drag turns, wheel zooms, no control buttons);
  when it cannot draw, the unit's faction logo, as stock. Values read
  through `ns.Clean` (secret in combat: painted empty).
- **PvP:** the inspected rank (`GetInspectHonorData`): rank title and number
  in Display (title by the unit's faction and sex), the season in Small
  textDim, the points to the next rank over a 3px progress line, then
  Honorable Kills (Lifetime, Today) as 28px stat rows. Redrawn on
  `INSPECT_HONOR_UPDATE`.
- **Guild:** the tabard emblem in a 72px well (`SetLargeGuildTabardTextures`
  on our texture, out of combat), the guild's name in Display, "<faction>
  Guild" and "N Members" (`INSPECT_GUILD_FACTION`, `INSPECT_GUILD_NUM_MEMBERS`).
- **Closes** as the stock frame: a new target closes a target's inspect, a
  roster change any other. Closed, it calls `ClearInspectPlayer` unless the
  talents window is inspecting too; closed for the next unit's inspect, it
  does not (that would drop the request just sent).
- **Left out:** the stock sheet's race background art (ours is the Model
  Well's shade, as Character), the open/close sounds (Character plays none),
  the hidden "View in Dressing Room" button (hidden in Camelot) and the
  gamepad footer (the module is off under the gamepad UI).
