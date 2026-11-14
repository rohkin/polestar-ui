# Changelog

## Unreleased

- Social: the Social window moves to the compact grid (580×560, no sidebar): its pages are top tabs, the search sits on the tab row and the Battle.net status in the footer; a new scene shows the game's looks.
- Trainer: the trainer window moves to the compact grid (560×560, no sidebar): its categories are top tabs, with the search and filter at the tab row's right end; a new scene shows the game's looks.
- Merchant: the vendor window moves to the compact grid (640×560, no sidebar): Merchant, Buyback and the other pages as top tabs, with the money, search and filter on the same row; a new scene shows the game's looks.
- Chat: calmer look: a soft ground and no outline at rest; the full ground, hairline and side buttons fade in on mouse-over (tabs, edit box and side strip included); the edit box's footer only while typing; tabs as plain labels with an accent underline, lit when hovered; the social button sits in the side strip and opens Polestar's Social window; voice, social and whisper icons in Polestar's icon colour.
- Chat: copy your chat as plain text (side strip button or a tab's menu); chat windows keep their last lines across /reload and logout.
- Fix the Talents window saying talents open at level 10 on a second spec just bought: it waits for the game to make the spec's talents, then shows its tree with every point to spend.
- Unit frames: Polestar's own player, target, focus, target of target, pet, party and boss frames (slim bars, level chip, square 3D portraits), placed and sized with Edit Mode.
- Unit frames: hovering a frame shows its health (and power) value with the game's default Status Text setting (None), as the stock frames do.
- Unit frames: a soft threat glow round frames that hold threat.
- Unit frames: the pet frame has the player's slim look at a smaller size and no longer jumps to the screen's top left.
- Unit frames: incoming heals and shields show clearly; heal absorbs darken the bar; health and power glide to new values ("Smooth bars"); the player's power bar shows what the spell being cast will cost; Polestar's star constellation on the player bar ("Sparkle").
- Unit frames: health fills in the header band's blue by default (class colour with Class colour on); the level chip takes the game's difficulty colour; the power strip wears Polestar's colours.
- Party frames: role icons, class colours and a thicker power strip.
- Buffs and debuffs: square icons with a thin border in the debuff type's colour, time and stacks in Polestar's numbers; right-click, tooltips and Edit Mode work as before (/pui auras off).
- Target and focus auras: a row of square icons under Polestar's target and focus frames, your own first and larger; the game's are hidden.
- Cast bars: your, your target's and your focus's cast bars as thick flat bars with the icon, name and time inside, in the header band's blue (class colour with Class colour on); grey when it can't be interrupted, red when interrupted or failed (/pui castbars off).
- Action bars: square buttons with a thin border, the key and count in Polestar's type, and an accent wash while pressed or on; every bar, the pet and stance bars and spell flyouts, with Edit Mode's bar settings untouched (/pui actionbars off gives the game's back).
- Action bars: hotkeys and counts outlined; the range dot keeps the game's font.
- Minimap: square, with a thin border in your accent and an N while it turns, in Polestar's look; Edit Mode's minimap settings still apply (/pui minimap off gives the game's back).
- Minimap: the zone name and clock sit inside the map; the mail, calendar and tracking icons sit in its top-left, top-right and bottom-left corners; addon buttons sit in a flyout opened from an addons icon in the bottom-right corner (a second click, Escape or a click elsewhere closes it).
- Minimap: in Edit Mode the minimap can be dragged until the map itself meets any screen edge.
- Minimap: the addons flyout no longer has an addon compartment cell (the "7" count that opened a second list of addons); the game's compartment stays hidden.
- Guild: the guild window in Polestar's look (the guild key and button; shift-click for the game's window with communities, Guild Finder and recruitment): the roster with sortable columns, Show offline, professions and member details (rank, notes, remove, invite), the message of the day and guild information, challenges, news with its filters, perks and rewards, the guild log, and Invite member, Guild control, Guild chat and Leave guild.
- Macros: /macro and the game menu open Polestar's window: general and character macros with their counts, the body with its character count, Save and Cancel, a name and icon picker with the game's icon filter, drag to an action bar, and shift-clicked links written as /cast, /use or /equip lines. Editing waits out combat, and a change typed before a fight is saved after it.
- Inspect: inspecting a player opens Polestar's window: their gear with names, enchants and sockets, their model, PvP rank and honorable kills, and their guild, on an icon rail as the Character window.
- Character: the sections move to an icon rail on the left, as Professions, in the game's order with its own tab icons (your portrait, Reputation, Skills, your faction's Honor, Currency, Statistics); the Character page's title is your name with your chosen title, and its subtitle your level and class, the class in its colour.
- Switching windows swaps them in place: the Polestar button above a game window closes it and opens Polestar's, and "Use game window" closes Polestar's and opens the game's (an NPC or crafting window: Polestar's from its next opening, the game's after /reload; Social has no micro button, so its keys open the game's).
- Fixed: Mail no longer errors after taking an attachment or opening a letter with fewer attachments, nor the Character flyout on a slot with fewer choices than the last one.
- Fixed: the Character flyout's Put in bags and wearing an item do nothing while a spell waits for its item, instead of a blocked-action error.
- Fixed: the Polestar button above the game's World Map now closes it and opens Polestar's map, instead of leaving the game's open until next time.
- Fixed: hiding Polestar no longer hides Polestar: UI's windows and their dialogs; they replace the game's, so they stay.
- Fixed: a flood of secret-value errors from the unit frames' segments and from the target and focus cast bars in combat.
- Talents and Spellbook are smaller (780×650 and 720×600): a slim header, the specs and spell categories as tabs along the top, and the search on the tab row.
- Opening a flyout in the Spellbook (a warlock's Summon Demon) lists its spells, not the flyout again.

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
