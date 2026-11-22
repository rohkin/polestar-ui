# Changelog

## Unreleased

- **The addon folder is now `PolestarUI` (was `Polestar_UI`). Please read before updating.** Polestar treats every `Polestar_*` folder as part of its own suite, and community addons must not use that name; this rename also ends Polestar's "Your install is mixed or incomplete" warning about Polestar: UI. After updating:
  1. Delete the old `Polestar_UI` folder from `World of Warcraft/_forever_/Interface/AddOns/` if it is still there (CurseForge may leave it). While it is installed, Polestar: UI starts nothing, switches the old copy off and asks you in chat to delete it and /reload.
  2. To keep your settings, with the game closed, rename `Polestar_UI.lua` to `PolestarUI.lua` in `WTF/Account/<account>/SavedVariables/`, and the same file in `WTF/Account/<account>/<realm>/<character>/SavedVariables/` for each character. Without this, Polestar: UI starts with its default settings.
- World Map: with Questie, its map icons (quest givers, turn-ins, objectives with their glow) now show on our map too, on zones, continents and Azeroth as on the game's map, and follow Questie's settings and changes at once. Hovering one shows Questie's tooltip (Shift for its long form) in Polestar's look; a click opens the icon's zone on our map, a modified click does what it does on the game's map (chat link, hide the quest, TomTom), a right-click goes out a map. Questie's patrol paths (the lines an NPC walks) are drawn too.
- Fixed a dark band inside the edges of the damage meter, the minimap and other HUD frames: the window shadow no longer reaches inside the frame.
- Removed the EllesmereUI integration: the Social friends list no longer shows EllesmereUI's friend groups (sections, colours, folding, moving, renaming, deleting, "Add to Group" in a friend's menu), our nameplates no longer start off beside EllesmereUI's nameplates, and Bags and Bank no longer stand down beside EllesmereUI's bags.
- `/pui` opens the settings page, which shows the version; `/pui help` lists the windows and commands.
- Character, Guild, Macros, Mail and Quest dialog: a side panel (the Stats drawer, member details, icon picker, open letter, quest portrait) and its window now read as one window at every border size: one outer border and one shadow round both, a thin divider between them instead of two borders at the seam; changing the border follows live.
- Micro menu and bag bar: the game's micro buttons and bag bar now wear Polestar's look in place (the game's icons kept, the open window and alerts in the accent, a latency dot in the game's latency colours; bag slots as the action buttons, lit while the bags are open), still placed by Edit Mode, with our window doors untouched; `/pui micromenu` and `/pui bagbar` switch them off live.
- HUD: unit frames, cast bars, buffs, cooldowns, the resource display, nameplates, the damage meter, action and bag buttons, the micro menu and the minimap now follow Polestar's Frames settings: their edges take the window border's colour (or the accent) and size, laid as on Polestar's windows (the first pixel on the element, a thicker border growing outward; 2 px at most on buttons, icons and nameplates), vanish with the border off (threat, focus and active edges stay), and Polestar's window shadow falls round them as round its windows; their ground follows Polestar's background opacity. Settings, HUD: Frames, Plates and Icons each can override Polestar's look (border, its size and colour, accent, hairlines, shadow and its strength, background opacity), so windows can keep a thick border while icons stay thin; an earlier HUD opacity of your own carries over.
- Nameplates: the cast bar is thinner (10 instead of the whole 16-high cast area) with no spell icon, as most plate addons draw it; Settings, HUD, Nameplate cast bars: "Cast bar icon" brings the icon back at the bar's left, "Cast bar height" sets 6 to 16. The game's red "targets you" and important-cast outlines no longer show round and through the bar: our border takes their colour instead.
- World Map: the map's filters (and what other addons add to them, such as Polestar's Nearby services and NPC services) are now part of the filter dropdown under the search, not a second game menu; a check keeps the dropdown open, a submenu opens in its place with Back.
- Immersion: with Immersion loaded, our Gossip and Quest dialog start off, so its dialogs no longer open beside ours. A saved choice wins (`/pui gossip off` and `/pui questdialog off`, then /reload, if you switched them on).
- Auction house addons: with Auctionator, AHledger, CraftProfit, TradeSkillMaster, Undying or Naowh Forever loaded, our Auction House starts off, so the game's window they build on still opens. A saved choice wins (`/pui auction off`, then /reload, if you switched it on).
- Bags and Bank stay off while Baganator or Bagnon is loaded (their own bags and bank take over); switching Bags off no longer brings back the stock bags beside them.
- Clique: our unit frames register with click-casting addons such as Clique, so their bindings work on them.
- Tooltips: the ground takes the colour scheme's background (a dark fallback where white text would not read on it) and follows a scheme change live.
- Fixed: a "stack overflow" error in the minimap with map pin addons that add thousands of pins.
- Fixed: clicking New or Change Name/Icon in Macros, with another window docked after it and no room left for the icon picker, no longer raises a Lua error.
- Opening a docked window's side panel (the Macros icon picker, the Character stats drawer, Guild member details, a Mail letter) no longer closes that window when room runs out: the dock closes the other window instead.
- Fixed: the trainer window no longer errors when the game hands over the trainer's name as a secret value; the subtitle then shows only what can be learnt.
- Fixed: more values the game can hand over as secret no longer raise errors: an inspected player's faction (Inspect), a target's name for Add friend and Block (they open the name dialog instead), the pet's family and level (Character, Pet tab), your GUID in the Auction House bid status, and the level in the Trainer's requirement check.
- Fixed: the Macros icon picker's "Click on an icon to set it as the macro's icon." hint wraps instead of being cut off.
- Guild: a member note's Edit icon opens the game's guild window, where you pick the member and edit the note (the game forbids addons to save notes, even through its own note popup; this ends the ADDON_ACTION_FORBIDDEN on saving one). Greyed in combat.
- Fixed: using a toy from the Collections window's Toy Box no longer raises ADDON_ACTION_FORBIDDEN; a secure button over the hovered toy uses it.

## 0.2.0

- Settings: a Polestar: UI page in Polestar's settings (each window and HUD part on or off, docking, the unit frame options, chat history; reset restores our defaults), "Settings…" in every window's menu, the Bags in Polestar's Move frames, coins in Polestar's localized symbols with gold in thousands; Polestar 0.4.0 or newer is now required.
- Polestar 0.4.0: live slider and colour ticks repaint only cheap parts (unit frames, auras, tooltip hairline); handlers that lay out take full changes alone; HUD bars and the damage trail snap under Reduce motion; tooltips use Polestar's solid tooltip ground.
- Nameplates: the game's enemy and friendly nameplates in Polestar's look: flat health bars in the theme's colours (hostile, neutral, friendly, threat, tapped), an accent outline round your target, the cast bar as Polestar's cast bars draw it, square aura icons and Polestar's face; every nameplate option stays the game's, and friendly plates in dungeons and raids keep the game's look. Off by default beside Plater, Platynator, KuiNameplates, Threat Plates or EllesmereUI's or ElvUI's nameplates (`/pui nameplates on|off`).
- Spellbook: with What's Training? loaded, a Training tab lists what your class trainer teaches now and later (available, missing requirements, coming soon, not yet available, pet abilities, missing talents) with level and cost, from its public API.
- Spellbook, Talents, Auction House, Collections, Legacy, Merchant, Social, Trainer and World Map: the search moves into the filter dropdown at the tab row's end (click the box to type, so movement keys never land in it; Enter keeps the search and closes it), leaving the tab row to the tabs; the filter button stays lit while a search runs. Merchant's filter is now Polestar's dropdown; the World Map's game filter menu opens from a row under the search.
- Unit frames, auras and minimap: hovering an aura under the target or focus frame, the party, pet or target of target frames, or the minimap's edges no longer shows the game's hidden parts' tooltips beside ours; the minimap's zone name shows the zone tooltip.
- Talents: with Talents Forever loaded, a footer button opens its planner and a pulsing gold edge marks your next planned talent point (following its "Show plan on the game's talents" setting).
- Fixed: Bags search dims the items that don't match again.
- Fixed: a dragged Bags window keeps its place, and docked windows stay docked when their header is dragged, with Polestar 0.4.0.
- Fixed: posting or updating a Group Finder listing no longer triggers a blocked-action error; Browse picks your listing's activities and waits for Refresh.

## 0.1.0

- Group Finder: a new Polestar window for the game's premade Group Finder, opened by its key, the Who key, the Group Finder button (shift-click: the game's window) and Who results. Listing (categories, activities with level ranges and lockouts, playstyle, voice chat, roles, Post and Update), Browse (sorted results with every member, whisper, invite, report) and Who (query, filters, invite, whisper). Unlisting and posting with a comment open the game's window. `/pui groupfinder on|off`.
- Collections: a new Polestar window for the game's Collections: Mounts (favorites, faction marks, model, source and lore, Mount/Dismount, filters, search, drag to bars), Toy Box (favorites, cooldowns, use on click out of combat, filters), Pet Journal (favorites, cooldowns, model, Summon/Dismiss, drag to bars) and Appearances (items by slot and weapon type, sets with variants, favorites, source tooltips, class filter, search). `/pui collections on|off`.
- Bags: a new Polestar window for your bags: every bag in one grid with the game's own slots (use, sell, split and enchant as in the game, in combat too), the equipped bags and money on the first row, free slots in the subtitle, search, Clean up and new items glowing until hovered. The bag keys, the bag bar and the game's own openers (vendors, trade, enchants) open it. `/pui bags on|off`.
- Baganator: a Polestar skin for Baganator's bags, bank and guild bank (Polestar's ground, hairlines and fonts, slots edged by quality, following Polestar's scheme and skin); its categories and settings stay Baganator's. With Baganator loaded our Bags window starts off. `/pui baganator on|off`.
- Unit frames: Polestar's own player, target, focus, target of target, pet, party and boss frames (slim bars, level chip in the game's difficulty colour, square 3D portraits), placed and sized with Edit Mode. Health fills in the header band's blue (class colour with Class colour on), party frames show role icons, and hovering shows health and power with the game's Status Text setting.
- Unit frames: a damage trail (the health just lost held red, then drained), clear incoming heals and shields, darkened heal absorbs, end glows past the bar for shields and heal absorbs, a soft threat glow, smooth bars, the cost of the spell being cast on the power bar, and Polestar's star constellation on the player bar. Power text follows the game's Status Text display.
- Unit frames hide with the game's own in cutscenes and spectator views, and names in Cyrillic, Korean or Chinese draw in the game's face for that script.
- Player names and notes in Group Finder, Social and Guild draw Cyrillic, Korean and Chinese in the client's own face, with no boxes and safe in combat.
- Buffs, debuffs, target and focus auras: square icons with a thin border in the debuff type's colour, in Polestar's numbers; a row under the target and focus frames, your own first and larger. Right-click, tooltips and Edit Mode work as before (`/pui auras off`).
- Cast bars: your, your target's and your focus's cast bars as thick flat bars with icon, name and time inside; grey when it can't be interrupted, red when interrupted or failed (`/pui castbars off`).
- Action bars: square buttons with a thin border, outlined keys and counts, and an accent wash while pressed or on, for every bar, the pet and stance bars and flyouts; Edit Mode settings untouched (`/pui actionbars off`).
- Minimap: square with a thin accent border and an N while it turns; the zone name and clock sit inside, the mail, calendar and tracking icons in the corners, addon buttons in a flyout from an addons icon; draggable to any screen edge in Edit Mode (`/pui minimap off`).
- Cooldown Viewer: essential, utility and tracked buff icons and bars in the HUD's look, with square icons, a hairline and a square sweep; Edit Mode settings stay the game's (`/pui cooldowns`).
- Personal Resource Display: the game's own bars in Polestar's look (flat fills, track, hairline, heal, absorb and cost segments); every Edit Mode setting stays the game's (`/pui resource`).
- Damage meter: the game's own meter in the HUD's look (ground at its Background Transparency, flat bars or class colours, Polestar's faces and glyphs, restyled menus), with the session letter on an accent chip; Edit Mode, extra windows and the breakdown stay the game's (`/pui damagemeter on|off`).
- Chat: a calmer look with a soft ground and no outline at rest, the full ground and side buttons fading in on mouse-over, tabs as plain labels with an accent underline, and the edit box ringed like Polestar's inputs; the social button opens Polestar's Social window.
- Chat: copy your chat as plain text (side strip button or a tab's menu); chat windows keep their last lines across /reload and logout.
- Windows are smaller on a compact grid with a slimmer header, and page navigation moves to top tabs or a slim icon rail: Character (700x540), Talents and Spellbook (780x650, 720x600), Professions and crafting (792x600), Legacy (760x600), Guild (740x520), Inspect (640x540), World Map (a bigger 900x600 map), Auction House (880x600), Gossip (520x400), Quest dialog (520x540), Mail, Bank, Social, Trainer, Merchant and Macros (560 to 640 wide).
- Guild: the guild window in Polestar's look (shift-click the guild button for the game's window): the roster with sortable columns, member details, message of the day, guild information, challenges, news, perks, rewards, the log, Invite member, Guild control, Guild chat and Leave guild. Every page keeps its tab row with status text.
- Macros: /macro and the game menu open Polestar's window: general and character macros with counts, Save and Cancel, a name and icon picker with the game's icon filter, drag to a bar, and shift-clicked links written as /cast, /use or /equip lines. Editing waits out combat.
- Inspect: inspecting a player opens Polestar's window with their gear, enchants and sockets, model, PvP rank and honorable kills, and guild.
- Character: the sections are top tabs with the game's own tab icons; the page's title is your name with your chosen title, and the subtitle your level and class in its colour.
- Switching windows swaps them in place: the Polestar button above a game window closes it and opens Polestar's, and "Use game window" does the reverse (an NPC or crafting window: Polestar's from its next opening, the game's after /reload).
- Spellbook: the search placeholder reads "Search", and opening a flyout (a warlock's Summon Demon) lists its spells.
- Talents: no more "talents open at level 10" on a second spec just bought; it waits for the game, then shows the tree.
- Fixed: Legacy reward text no longer shows a stray "|"; the unlearned profession card text matches the other cards; no trailing period in the Professions subtitle.
- Fixed: the Character Skills page no longer errors when a skill's bonus is secret; it shows the last bonus read.
- Fixed: Mail no longer errors after taking an attachment or opening a letter with fewer attachments, nor the Character flyout on a slot with fewer choices than the last one.
- Fixed: the Character flyout's Put in bags and wearing an item do nothing while a spell waits for its item, instead of a blocked-action error.
- Fixed: the Polestar button above the game's World Map now closes it and opens Polestar's map.
- Fixed: hiding Polestar no longer hides Polestar: UI's windows and their dialogs.
- Fixed: a hatched circle inside the square minimap near area quests.
- Fixed: floods of secret-value errors from unit frame segments, target and focus cast bars, and target and focus aura rows in combat and PvP.
- Fixed: the stock pet frame's red attack pulse and threat flash no longer show round the pet portrait, and the pet frame no longer jumps to the screen's top left.

## 0.0.6

- Character: pick your title; save, wear, rename and delete gear sets; gear slots show sockets, gems, counts, cooldowns and broken items, with Alt-hover choices for another item; reputation, currency and skill details; Honor's weekly cap, season progress and rewards; your pet's loyalty, happiness and stats.
- Social: friends, friend requests, recent allies, the ignore list and the raid in Polestar's look, with the game's tooltips and menus; drag players between raid groups, ready check, role counts, Raid info and party conversion.
- Bank: the Bank and Warband bank in one grid with bag slots, search, Clean up, Deposit all, money and a warning before a refundable item goes into the Warband bank.
- Mail: the mailbox and a send page in Polestar's look, with Open all, shift-click to take a letter whole, attachments, money and COD, and warnings before costly or refundable sends.
- Gossip: NPC conversations open Polestar's window, with the NPC's portrait, quests, options with their icons, and keys 1-9 to pick.
- Merchant: Buy and Buyback with every price and currency, the game's purchase warnings, Repair all, Sell junk, refunds and Restock.
- Trainer: categories, each spell's cost and needs, Train, and your money or pet training points.
- Quest dialog: quest givers open Polestar's window with the offer, progress and reward choice, and the best pick marked.
- Loot: the loot window in Polestar's look, with quest items marked and the master loot menu.
- Auction House: the auctioneer in Polestar's look, with the full stock feature set: search and filters, commodity and item buying, posting, your auctions and bids, and the WoW Token.
- World Map: filter and map pin buttons, and your coordinates and the cursor's at the bottom left.
- Quest log: right-click a quest to track, focus, share or abandon it; party members and money needed on quests, and a red count when the log is full.
- Spellbook: a Filter button, portals and other flyouts as one entry, the game's skill-line icons, and marks for spells on no action bar.
- Talents: Activate and Reset, the game's search options, drag learnt talents to your bars, and disabled buttons say why.
- Professions: favorite recipes, Track recipe, Link profession, item-level search, skill-up chance in the tooltip, View crafters, tool and gear slots, and Craft says why it is disabled.
- Legacy: status lines in place of instructions, and filters that show how many are on, with Clear filters.
- Chat: the selected tab is the only one that looks selected.
- Windows: each window's options are in its "..." menu.
- NPC windows stay open when a bag addon such as Baganator opens its bags.
- Quest dialog: closes itself when another addon accepts or turns in the quest.

## 0.0.5

- Chat: each chat window is one Polestar window, its tabs as the header and the input line as the footer. The side buttons, scroll bar, resize grip, minimised windows, the dock's overflow list, the chat's right-click menus and chat bubbles (outside instances) take Polestar's look too.
- Tooltips: the comparison tooltips' "Equipped" plate in Polestar's look; tooltips a little more see-through than the windows, following the Background opacity.
- World Map: Polestar draws its map features on our map, when the Polestar version installed supports it.
- Releases upload to CurseForge.

## 0.0.4

- World Map: the game's map in Polestar's look, opened from the map key. The sidebar lists the maps above, the zones, a zone's dungeons and caves, and a map's floors; zoom steps and full screen.
- Quest log: a flyout beside the map, from the quest log key and micro button (shift-click for the game's map). Headers that fold, search, each quest's level (elite marked +), difficulty colour and objectives, and the map's filter menu, kept in step with the game's map.
- Quest details: click a quest for its objectives, text and rewards (experience with its share of your level), with Track, Share and Abandon.
- Tooltips: the game's own tooltips in Polestar's look, with every line other addons add to them.
- Chat: the game's own chat windows, tabs and input line in Polestar's look, at your chat opacity.
- Switch a window between Polestar's and the game's at once: "Use game window" in its "..." menu, the Polestar button above the game's window, or `/pui <window> on|off` (crafting after `/reload`). `/pui tooltips` and `/pui chat` switch the same way.
- The windows dock from the top left as the game's own do (`/pui dock off` frees them) and follow Polestar's Menu scale, its slider in each header.
- Crafting: the window is titled by its profession.
- Known: map and quest links, the quest tracker and the game's other ways to the map still open the game's map.

## 0.0.3

- Legacy: Forever's Legacy System window in Polestar's look, opened from its key, the achievements key and the Legacy micro button (shift-click for the game's own). Rewards, Challenges and the Tree on a rail on the left.
- Reward Track: each reward at the legacy points it needs, the next one marked, with progress toward it.
- Challenges: categories that fold as the game's do, search, and the game's Completed/Incomplete filters; each challenge's legacy points and the date earned; click for its objectives, shift-click to link it in chat or track it.
- Legacy Tree: the Professions, Adventure and Progression trees; click to learn a rank, right-click to take one back, then Apply, Undo or Reset.
- Crafting: an enchant gets an item slot, listing what it can go on (worn items marked); long recipe names take a second line.
- Known: challenge links in chat still open the game's window.

## 0.0.2

- Professions: a card per profession with its rank, its spells (click to open, drag to your bars) and the game's card art; unlearn a primary profession from its card.
- Crafting: the game's crafting window in Polestar's look. Recipes by category, "Can make now" and "Recent" first, search and the game's own filters; the product, its reagents and what else it needs; Craft and Craft all with a quantity.
- Switch between professions from the rail on the left; both windows open in one shared place.
- A spell or item dragged from our windows now drops where you release it, and a fast drag takes the one you pressed.
- Spellbook cooldowns show in combat, and the micro buttons no longer cause blocked-action errors in combat.
- Known: casting by click from our windows (spells, professions) works out of combat; dragging works in combat. Other addons' panels in the game's crafting window (Auctionator, CraftProfit, CraftShuffle) do not show in ours yet: `/pui crafting off` and `/reload` give the game's window back.

## 0.0.1

- First version: the Character window (gear, stats, Reputation, Currency, Player vs. Player, Skills, Statistics), the Spellbook and Talents, in Polestar's look.
- `/pui` lists the modules; `/pui <module> off` and `/reload` gives back the game's own window.
