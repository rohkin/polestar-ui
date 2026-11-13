#### Macros (`MacroFrame`, Blizzard_MacroUI) — Risk: medium
Demand-loaded (`MacroFrame_LoadUI`). Every door is the global
`ShowMacroFrame` (its bootstrap file loads at login): `/macro`, the game
menu's Macros button and the chat menu's Macros entry; Forever has no key
binding and no micro button for it. `ShowMacroFrame` is "show", never a
toggle, so ours follows it with `hooksecurefunc` and closes the stock frame
with its own `Hide()` in the same call, as Character's `ToggleCharacter`
hook (Contract step 2). Its `OnHide` runs `MacroPopupFrame:Hide`, an empty
`SaveMacro` and `UpdateMicroButtons` (as `CharacterFrame`'s does), and
touches no action bar. The click binding window (`ClickBindingFrame`) shows
`MacroFrame` itself from its portrait (`ShowUIPanel`): that door stays the
game's, as click binding needs the stock frame's own buttons. `M.stock()`
answers `MacroFrame` (its `CloseButton` serves the switch-back button).

- **Data:** `GetNumMacros()` (general, character), `GetMacroInfo(i)` (name,
  icon, body), `C_Macro.GetSelectedMacroIcon(i)` (the chosen icon, not the
  dynamic one), `Constants.MacroConsts.MAX_ACCOUNT_MACROS` (120) and
  `MAX_CHARACTER_MACROS` (30): character macros are indices 121 to 150.
  `CreateMacro(name, icon, body, perCharacter)`, `EditMacro(i, name, icon,
  body)` and `DeleteMacro(i)` as the stock buttons call them; `CreateMacro`
  and `EditMacro` answer the macro's new index (macros sort by name).
  Redraw on `UPDATE_MACROS`.
- **Shell:** 960×680 with sidebar. Subject block: the stock portrait
  (`Interface\MacroFrame\MacroFrame-Icon`), "Macros", "12 of 150 used".
- **Nav:** the stock tabs as two nav rows: General Macros (count) and
  "<name> Specific Macros" (count), the stock labels (`GENERAL_MACROS`,
  `CHARACTER_SPECIFIC_MACROS`). Band: the page's label; subtitle "12 of 120
  macros." or "Full: 120 of 120 macros."
- **Main column:** the stock icon grid (`MacroSelector`) at the top, in its
  own scroll (each macro a well with its name under it, the selected one
  in the accent); only the macros themselves, not the stock window's empty
  disabled slots (the count says how many are left). Under it the selected
  macro: its icon well (click or drag picks it up, `PickupMacro`, as the
  stock `SelectedMacroButton`), its name, "General macro" or "Character
  macro", and Change name/icon (`CHANGE_MACRO_NAME_ICON`). Then "Enter macro
  commands:" (`ENTER_MACRO_LABEL`), the body: a multi-line box of 255
  letters (`MacroFrameText`), and the stock counter "88/255 Characters Used"
  (`MACROFRAME_CHAR_LIMIT`), with Save and Cancel beside it (off while
  nothing changed). A tab with no macro: "No macros here yet."
- **Saving, as stock:** the body is saved (`EditMacro(i, nil, nil, body)`)
  when another macro or tab is picked, on Save, New and Change name/icon,
  and when the window hides; Cancel puts the saved text back.
- **Icon picker:** the stock `MacroPopupFrame` as a flyout on the window's
  right edge (`ns.Flyout`, `ns.DockFlyout`): "New macro" or "Change name and
  icon", the name (16 letters, `"` dropped, as stock), the chosen icon and
  the stock line under it ("Click an icon..." / "not in the list"), the
  stock icon filter (All, Spells, Items) on a sliders button, and the icon
  grid, drawn only where seen. The list is the stock one built as
  `IconDataProviderMixin` builds it, but in our own table: "?" first, the
  spellbook's icons (`IconDataProviderOverrides`: skill lines and known
  flyout spells), then `GetLooseMacroIcons`/`GetMacroIcons` and
  `GetLooseMacroItemIcons`/`GetMacroItemIcons`. Calling the stock mixin would
  write its file-local icon table from our code. An item, spell, mount,
  battle pet or macro dropped on the picker sets its icon, as the stock
  drag area. Okay (off with no name; Enter) creates the macro in the shown
  tab or edits the selected one; Cancel (Escape) closes it. New starts with
  no name and the "?" icon (the macro then takes its spell's icon), and the
  body appears and takes the focus once it is made, as stock. Picking a
  macro, a tab or New again closes the picker (the stock window greys its
  tabs and buttons instead).
- **Footer:** Delete at the left (danger; Polestar's dialog in place of
  `CONFIRM_DELETE_SELECTED_MACRO`), New (primary; off when the tab is full,
  "All 120 general macro slots are used.") at the right. No Exit button:
  the shell's Close is it.
- **Links:** with the body in focus, a shift-clicked link goes into it as
  `ChatFrameUtil.InsertLink` puts it into `MacroFrameText`: at a line's
  start "/use" (an item with a use), "/equip" (another item) or "/cast"
  and the name, else the item's name or the text. A post-hook on
  `ChatFrameUtil.InsertLink` (as Auction's), only while no chat line is
  open; a spell or mount link becomes its name, as the stock spellbook and
  mount journal send names while `MacroFrameText` has the focus.
- **Combat:** creating, editing and deleting macros is refused in combat,
  so New, Delete, Change name/icon, Save and Cancel are greyed with "Macros
  cannot change in combat." and the body is locked; a change typed before
  the fight is kept and saved when it ends (the stock window loses it).
  Picking a macro up waits for the fight to end too (it could go on no
  action bar then).
- **Not as stock:** the secure action buttons save the open macro before
  running it (`MacroFrame_SaveMacro`, `SecureTemplates.lua`); ours cannot be
  called from there without tainting them, so a macro run from a bar while
  its edit is unsaved runs the saved text. Right-click on a macro does what
  the stock button does: nothing. The gamepad's "bind to action bar" prompt
  is the stock window's.
- **Tests:** `stub_macros.lua` (`ShowMacroFrame` showing a stock
  `MacroFrame`, the macro API keeping a list sorted by name, combat
  refusing `CreateMacro`/`EditMacro`/`DeleteMacro`, the icon lists);
  scenes `macros` (`/macro` opens ours and never leaves the stock one
  shown, the grid, body and counter, saving on select, pickup, a link into
  the body, delete, switched off the stock one opens), `macros-character`
  (the character tab and a full tab's New), `macros-icons` (the picker:
  new and edit, filter, a dropped item's icon), `macros-combat` (greyed with
  the reason, the body locked, the change saved after the fight).
