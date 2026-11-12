# Parts catalog

S/ = `.ref/wow-ui-source-forever/Interface/AddOns`, W = `P/Theme/Widgets.lua`,
T = `P/Theme/Theme.lua` (P/ = `D:\Projects\polestar\addon\Polestar`). Find
things by name (grep it). Design rules per part are in `docs/DESIGN.md`
("The Game Window Shell", "Components"); each window's own entry is
`docs/windows/<key>.md`.

## A. Stock part -> Polestar element (replace strategy)

| Stock part (where) | Polestar element | API, example | Gotchas |
|---|---|---|---|
| Window frame: `PortraitFrameTemplate` (S/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml), `ButtonFrameTemplate`, `DefaultPanelTemplate`, NineSlice border (S/Blizzard_SharedXML/NineSlice.lua) | `W.Shell` (window skin, band, sidebar, main column, footer) | `W.Shell(name, { scalePath="ui.menuScale", width, height, sidebar, rail, plain, searchPlaceholder, onSearch })`; then `ns.Dock(f)`, `ns.WindowMenu(f, key)`, `Polestar.CloseOnEscape(name)`. `build` in `Spellbook.lua` | Fields: `f.Header Sidebar Main Body Content Footer Search Close HeaderTools NavScroll Rail Title Subtitle`. 960x680 with sidebar; plain/tabs-only smaller, height <= 600. `sidebar = 0` needs `f.Main` re-anchored (rule 12, `build` in `Professions.lua`) |
| Separate panel/drawer skin (stats drawer) | `Theme.Skin(frame, "window")` | `buildStats` in `Character.lua` | Ground alpha = `Theme.GroundAlpha()` (player's Background opacity) |
| Portrait (round icon top-left) | Subject Block: 36px game icon on an inset well + name (Title) + one Small textDim line, Polestar emblem/wordmark/search reparented to a hidden holder | `build` in `Character.lua` (copied in the `build` of Spellbook, Talents, Crafting, Legacy and WorldMap) | Never Polestar's emblem in a game window's sidebar. Icons: `ns.GameIcon` (`Core.lua`) crops the baked border |
| Close button `UIPanelCloseButton` (SharedUIPanelTemplates.xml) | the shell's `f.Close` (house `close` paint) | built by `W.Shell` | Escape via `Polestar.CloseOnEscape` (P/Core/Init.lua) |
| Title bar / title text | band: `W.ShellTitle(f, title, subtitle)` | `Spellbook.lua`, every module | Subtitle: a fact or a one-line "what you can do here" |
| Window "..." / options | `ns.WindowMenu(f, key)` (`Core.lua`), page options on `f.Header` via `W.IconButton` + `W.ShowMenu` | `optionsMenu` in `Spellbook.lua` and `Talents.lua` | "Use game window" entry is automatic |
| Bottom tabs `PanelTabButtonTemplate` (SharedUIPanelTemplates.xml, `PanelTemplates_SetTab` Mainline/SharedUIPanelTemplates.lua), top tabs `PanelTopTabButtonTemplate`, `TabSystemButtonTemplate` (Shared/TabSystem/TabSystemTemplates.xml), `MinimalTabTemplate` (Shared/Tabs/MinimalTab.xml) | views of one page: `W.ShellTabs(f, {{key,label},...}, active, onSelect)` (house `tab` paint, accent bar; `Theme.SetTabSelected`) | No module ships real tabs yet; all call `W.ShellTabs(f, nil)` to drop the row | One tab = no row. Tabs that are really sections of a window -> sidebar nav or rail instead |
| Side tabs `LargeSideTabButtonTemplate` (SharedUIPanelTemplates.xml), section switchers | `W.ShellRail(f, items, bottom, active, onSelect)` (`rail = true` on the shell) | `paintRail` in `Legacy.lua`; shared rail `ns.ProfessionTabs` (`Professions.lua`) | Rail icons are game icons, untinted. A rail item that casts is protected -> `ns.Overlay` |
| Category lists / sidebar nav | `W.ShellNav(f, items, active, onSelect)`; item `{ key, label, icon, count, dot, heading, separator }` | `refresh` in `Character.lua`, `Spellbook.lua` and `Talents.lua`, `M.Refresh` in `WorldMap.lua` | Locked item: count 0 + lock icon (Talents Secondary) |
| Scroll lists `WowScrollBoxList` (Shared/Scroll/ScrollTemplates.xml), `ScrollUtil.InitScrollBoxListWithScrollBar` (Shared/Scroll/ScrollUtil.lua), `UIPanelScrollFrameTemplate` (SecureScrollTemplates.xml) | `W.Scroll(parent)` + rows we pool ourselves; `W.SetScrollContent(sf, contentH, viewH)`, `W.ScrollTo`; shell body: `W.ShellBody(f, height)` | `buildStats` in `Character.lua`, `ns.QuestLog` and `paintDetails` in `QuestLog.lua` | No ScrollBox/DataProvider: rows are plain frames we lay out. Redraw at once after a client change (rule 6) |
| Scroll bars `MinimalScrollBar` (Shared/Scroll/MinimalScrollBar.xml), `WowTrimScrollBar` (TrimScrollBar.xml) | comes with `W.Scroll` (house `scrollbar` paint: 2px thumb) | — | On a stock frame (restyle): `scrollbar()` in `Chat.lua` |
| Section header + grouped rows (stock headers with +/-) | `W.SectionHeader(parent, {plain})`, `W.SetSection(h, text, count)`, `W.RowPanel(parent)`; fold chevron in the gutter | `group` in `CharacterPages.lua`, `statSection` in `Character.lua` | Fold state: the client's when it has one, else ours in `PolestarUIDB` |
| Search box `SearchBoxTemplate` (Shared/InputBox/InputBoxTemplates.xml) | shell search (`searchPlaceholder`, `onSearch` opts) or `W.SearchBox(parent, placeholder, onChange)` | `build` in `Spellbook.lua`, `ns.QuestLog` in `QuestLog.lua` | Others recede/dim, subtitle counts matches (Talents) |
| Edit box `InputBoxTemplate` (InputBoxTemplates.xml) | `CreateFrame("EditBox")` + `Theme.Skin(e, "editbox")`, focus via `Theme.SetFocused` | `build` in `Crafting.lua` (quantity field) | Fonts via `Theme.Font`/`W.Text` roles |
| Filter dropdown `WowStyle1FilterDropdownTemplate`, `WowStyle1DropdownTemplate` (S/Blizzard_Menu/Mainline/MenuTemplates.xml, :3) | 30px `W.IconButton(.., "sliders", 30, ...)` skinned `"editbox"`, at the end of the search row | `build` in `Crafting.lua` and `Legacy.lua`, `ns.QuestLog` in `QuestLog.lua` | Glyph in the accent while a filter hides something |
| Menu contents (Menu API: `MenuUtil.CreateContextMenu` S/Blizzard_Menu/MenuUtil.lua) | **flat, ours:** `W.ShowMenu(anchor, items, opts)`; items `{ text, icon, checked, disabled, onClick, tip, color, confirm }`, `{ separator = true }` | `targetMenu` and `filterMenu` in `Crafting.lua`, `filterMenu` in `Legacy.lua`, `optionsMenu` in `Spellbook.lua` | `W.ShowMenu` has **no submenus**. Keep the stock Menu (`MenuUtil.CreateContextMenu` + `root:SetTag("MENU_...")`) when it needs submenus, radio/title elements, or **other addons add to it by tag** (`Menu.ModifyMenu`, S/Blizzard_Menu/Menu.lua): `ns.QuestLog` in `QuestLog.lua` (`MENU_WORLD_MAP_TRACKING`). Restyle such menus per tag (section B) |
| Text buttons `UIPanelButtonTemplate` (SharedUIPanelTemplates.xml), `UIPanelDynamicResizeButtonTemplate` | `W.Button(parent, text, onClick, { primary, ghost, danger, width, height, icon })`; footer actions via `W.ShellFooter` | `build` in `Crafting.lua`, `abandon` in `QuestLog.lua` | Disabled = Polestar's 45% fade. Two-click confirm: `W.Confirm` or footer `opts.confirm` |
| Icon buttons `UIPanelSquareButton` (S/Blizzard_UIPanelTemplates/Mainline/UIPanelTemplates.xml), small arrow/gear buttons | `W.IconButton(parent, glyph, size, tip, onClick, glyphSize)`; `W.SetIcon`, `W.SetIconState` | `newCard` in `Professions.lua`, `build` in `WorldMap.lua` | Glyphs are Polestar's (`Theme.Media(Theme.Icon(name))`); game things keep game icons (Two Families Rule) |
| Footer button bar (`ButtonFrameTemplate` bottom, Apply/Reset) | `W.ShellFooter(f, left, right)`; `{ label, onClick, opts = { primary, ghost, confirm } }` | `refresh` in `Talents.lua`, `paintFooter` in `Crafting.lua` | No buttons = no footer bar. Never a "Close" button |
| Checkboxes `UICheckButtonTemplate` (Shared/Button/CheckButtonTemplates.xml), `MinimalCheckboxTemplate` | `W.Checkbox(parent, onClick)`; `W.Switch(parent, get, set, tip)`; settings rows `W.Toggle` | none in Modules yet | In a menu: `checked` on a `W.ShowMenu` item (Spellbook Options) |
| Sliders `MinimalSliderWithSteppersTemplate` (Shared/Slider/MinimalSlider.xml) | `W.Slider(parent, label, path, lo, hi, step, fmt, desc, depends, { get, set })` | none in Modules yet | Without a settings path use `opts.get/set`. Quantity steppers: `build` in `Crafting.lua` (-, field, +, Max) |
| Settings-style dropdown (a choice) | `W.Dropdown(parent, label, path, choices, ...)` | none yet | Bound to a settings path |
| Item / spell slots `ItemButton` (S/Blizzard_ItemButton/Shared/ItemButtonTemplate.xml), `SetItemButtonQuality` (Mainline/ItemButtonTemplate.lua), `SpellBookItemTemplate` (S/Blizzard_PlayerSpells/SpellBook/Blizzard_SpellBookItem.xml) | **well/tile pattern**: Frame sized to the icon, `Theme.Skin(well, "inset")` + `Theme.Border(well, Theme.Wash("border"))`, `ns.GameIcon` inset 1px; quality: border raw from uncommon up, name via `Theme.Legible` | `iconWell` + `paintQuality` in `Crafting.lua`; slot tile `newSlot` in `Character.lua`; spell row `ns.SpellRow` (`newRow` in `Spellbook.lua`); reward/reagent tile `tile` in `Crafting.lua` and `QuestLog.lua`; `iconWell` in `Legacy.lua`; talent node `newNode` in `Talents.lua` | Press nudges icon 1px; desaturate for unknown/locked; `W.ItemTip`/`W.SpellTip` for tooltips, `W.ItemClick` for modified clicks. Cast/use/target = `ns.Overlay` |
| Cooldown sweep `CooldownFrameTemplate` (S/Blizzard_FrameXMLUtil/Mainline/Cooldown.xml) | the stock template on our well, fed by a duration object | `paintCooldown` in `Spellbook.lua` | Rule 3: `SetCooldown` refuses secret times |
| Status / progress bars (rep, skill, XP) | Skill Bar: `W.ProgressLine(parent, 2)` + `W.SetProgress(f, frac, width)`; rank "145/150" in Number textDim above its right end | `setBar` in `CharacterPages.lua`, `newCard` in `Professions.lua`, `buildTrack` in `Legacy.lua` | Never thicker than 2-3px; standing colour for reputation |
| Small labelled badge | `W.Chip(parent)` + `W.SetChip(c, text, kind)` | (talent rank chips are hand-built in `Talents.lua`) | — |
| Tooltips on our things | `W.Tooltip(owner, anchor, title, lines)` / game tooltips `W.ItemTip`, `W.SpellTip`, `GameTooltip:Set*`; `W.HideTooltip` on leave; hint line `ns.TooltipHint(text)` (`Core.lua`) | `newSlot` in `Character.lua`, `refresh` in `Talents.lua` | Hint = textMuted after a blank line, says what a click does now |
| Modals / confirms (`StaticPopupTemplate` S/Blizzard_StaticPopup_Game/GameDialog.xml, `StaticPopup_Show` S/Blizzard_StaticPopup/StaticPopup.lua) | `W.Modal({ title, text, icon, action, danger, onAccept, cancel, onCancel })` | `unlearn` in `Professions.lua`, `abandon` in `QuestLog.lua` | Never replace or restyle StaticPopup (shared with secure dialogs); only our own flows call W.Modal |
| Flyouts / drawers | outside the window's edge: `ns.DockFlyout(f, fly, overlap)` (`Core.lua`); inside: grow the window | `build` in `Character.lua`; map quest log `ns.QuestLog` (`QuestLog.lua`) | Docking width counts shown flyouts |
| Inset wells `InsetFrameTemplate` (SharedUIPanelTemplates.xml) | `Theme.Skin(frame, "inset")` (shade at 25%) | every `iconWell` | — |
| Cards / raised panels | `Theme.Skin(c, "panel")` | `newCard` in `Professions.lua` | — |
| Sidebar-ground sub panel | `Theme.Skin(p, "sidebar")` | `ns.QuestLog` in `QuestLog.lua` | — |
| Hairlines / fills / hover | `W.Divider(parent, vertical)`, `W.Fill(parent, token)`, `W.Hover(frame)`, `W.Tex`, `W.Text(parent, role, color)` | everywhere | Every FontString via `W.Text` (rule 2) |
| Hover buttons for protected clicks (spell cast, item use, profession) | `ns.Overlay(name, { enter, pickup, attrs, stale, setup })` (`Core.lua`) | `overSlot` in `Character.lua`, `overRow` in `Spellbook.lua`, `overTab` in `Professions.lua` | Rules 4, 9, 10 |
| Two windows sharing one place | `ns.LinkPlace(win)` (`Professions.lua`) | Crafting/Professions | — |

### Colour and alpha rules
- Colours only through tokens: `Theme.Color(name)`, `Theme.Wash(name)` (hover, border, thumb...), `Theme.Accent()`, `W.Color`/`W.Painter` (repaint on theme change). Game colours (quality, difficulty, standing) through `Theme.Legible(r,g,b)` before they carry text; raw only on a 1px border.
- Window grounds: `bg` at `Theme.GroundAlpha()` (`ui.bgOpacity`, default 0.94). `Theme.Skin(f,"window")` does it for our frames.
- Menus and inputs: near-solid. Polestar's own menu is `Theme.Skin(menu, "panel")` (`panel` token, alpha ~0.98); inputs `"editbox"` (shade at 35%, accent border focused). Note: `Chat.lua`'s `menuLook` currently paints `bg` x `GroundAlpha()`; check against this rule when touching it.
- Tooltip look (tooltips, chat bubbles): `bg` at `GroundAlpha() * 0.85`, 1px `border` hairline (`paintGround` in `Tooltips.lua`).
- Hairline width: `Theme.Pixel(frame)` (one physical pixel).

## B. In-place restyle kit (Tooltips.lua, Chat.lua)

| Pattern | Where | Notes |
|---|---|---|
| Weak table keyed by stock frame, holding our textures | `looks` in `Tooltips.lua`, `Chat.lua` (`looks`, `look(f, make)`) | Never a key on the stock frame |
| Fade art with `SetAlpha` (art the game never re-alphas) | `fade` in `Tooltips.lua` (NineSlice pieces), `fadeArt` in Chat (tabs, buttons, scroll bar, strip) | `SetAtlas` keeps alpha, so state swaps stay faded |
| Hide / empty art the game re-alphas | Chat `panel`/`bare`: border pieces `SetShown(false)`, ground `SetTexture(nil)` | Game writes window alpha/fades into it (`FCF_SetWindowAlpha` S/Blizzard_ChatFrameBase/Mainline/FloatingChatFrame.lua) |
| Copy a live alpha onto ours | Chat `M.Enable` driver `OnUpdate` | Driver also follows edit-box focus, button state |
| Our ground + 4 hairlines on the stock frame | `ground` in `Tooltips.lua`; Chat `tex` + `hairline` + `paintLine` | Created with `CreateTexture` on the stock frame (widget call, no Lua key) |
| Re-apply after the game resets style | `hooksecurefunc("SharedTooltip_SetBackdropStyle", ...)` `M.Enable` in `Tooltips.lua` (S/Blizzard_SharedXML/SharedTooltipTemplates.lua); Chat hooks `FCF_OpenTemporaryWindow`, `FCF_MinimizeFrame`, `FCFTab_UpdateColors`, `FCF_SetButtonSide` | Post-hooks only |
| Theme repaint | `Theme.OnChanged(function() if ns.Enabled(key) then M.Apply() end end)` | both modules |
| Live on/off | `M.Apply()` paints on and off from `ns.Enabled(key)`; `ns.Switch` calls `Apply` (`Core.lua`) | Off restores stock textures, alphas, fonts (`stockFonts` in Tooltips) |
| Fonts | `Theme.SetFace(fontObject, Theme.FontSpec(role), size, flags)` on the font object, sizes kept | `M.Apply` in `Tooltips.lua` |
| Status bar | `SetStatusBarTexture` + a track texture of ours; colour stays the game's | `paint` in `Tooltips.lua` |
| Pooled Blizzard menus | `Menu.ModifyMenu(tag, function(_, root) root:AddMenuAcquiredCallback(menuLook) end)`, art via `menu:AttachTexture()` (S/Blizzard_Menu/Compositor.lua) | Chat `MENUS`/`menuLook`. Menu frames refuse `CreateTexture`; the pool frees attached art and resets fades |
| Chat bubbles | `C_ChatBubbles.GetAllChatBubbles()`, child frame, skip `IsForbidden()`; scan from the driver ~0.1s | Chat `bubble`/`bubbles` |
| Stock buttons as icon buttons | Chat `iconButton(b, glyph, size, keepLit)` + `paintState` | Fade normal/pushed/disabled/highlight; our hover + glyph |

### Duplicated helpers (candidates for one shared helper; not extracted)
- **Edge table + four hairlines**: `EDGES` + `ground` (`Tooltips.lua`), `EDGES` + `hairline`/`paintLine` (Chat), and a third inline copy in Chat `menuLook` (AttachTexture variant).
- **NineSlice piece list + fade loop**: `PIECES` + `fade` (`Tooltips.lua`) vs `NINE` + the loops in Chat `overflow` and `bubble`; Chat `fadeArt` is the general form.
- **Tooltip-look ground** (`bg` x `GroundAlpha()*0.85` + border hairline): `paintGround` (`Tooltips.lua`) vs Chat `bubble`.
- **Window-look ground** (`bg` x `GroundAlpha()` + hairline): Chat `panel`, `overflow`, `menuLook`.
- **Weak `looks` table + `look(f, make)`** and the `Theme.OnChanged -> M.Apply` line: both modules.

Beyond the two restyle modules (same shape, copied):
- **Icon well** (inset skin + border wash + `ns.GameIcon` inset 1px): `iconWell` in `Crafting.lua` and `Legacy.lua`, inline in `newRow` (`Spellbook.lua`), `tile` (`QuestLog.lua`), `newNode` and `paintTrees` (`Talents.lua`), `newCard` (`Professions.lua`), `build` (`WorldMap.lua`).
- **Subject block** (hide Polestar's lockup into a holder, 36px well, name, line): `build` in `Character.lua`, `Spellbook.lua`, `Talents.lua`, `Crafting.lua`, `Legacy.lua`, `WorldMap.lua`.
- **Secret-safe reads**: `clean` (`Spellbook.lua`, `Professions.lua`), `num` (`Talents.lua`, `Legacy.lua`).
- **Item quality colour**: `qualityRGB` (`Character.lua`) vs `quality` (`Crafting.lua`).
