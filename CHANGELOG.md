# Changelog

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
