#### Professions book (`ProfessionsFrame`, its book page) — Risk: high
Forever has no `ProfessionsBookFrame`: `ToggleProfessionsBook` shows
`ProfessionsFrame` on its book page (`SelectBookPage`), whose show touches the
micro buttons. So, as the Spellbook, ours opens from `TOGGLEPROFESSIONBOOK` and
`ProfessionMicroButton` through `ns.Doors`, never touching the stock window;
shift-click on the micro button opens the stock one. It closes when a
profession opens (`TRADE_SKILL_SHOW`), as ours takes the crafting window.
- **Shell:** 760×680 plus the section rail, no sidebar (`sidebar = 0`,
  hidden): one page, nothing to navigate, so no subject block either; the band
  names the window.
- **Professions rail:** the crafting window's (`ns.ProfessionTabs`, below),
  "Overview" marked; a profession's section opens its crafting window.
- **Main column:** title "Professions", subtitle "2 of 2 professions learnt."
  only (what a spell does is in its tooltip). The
  stock page's five slots as cards on the panel ground under two headings:
  Primary (one to a row: wide, short cards, the spells side by side, as the
  stock page and its art), then Secondary (Cooking, Fishing, First Aid, three
  to a row). A card: the profession's icon (40px on an inset well, `ns.ItemWell`), its name in
  Title, its skill bar with the rank ("145/150 (+5)") above its right end, then
  its spells as the Spellbook's rows (`ns.SpellRow`: click casts through the
  secure button, drag, shift-click links, cooldown). An empty slot: the stock
  scroll icon desaturated, the slot's name and the stock "learn it" line in
  textMuted. Behind each card, the stock page's card art, as the Talents
  window's class art: at full strength under a wash of Polestar's sky at 55%,
  cropped to the card's shape (the band 85% of the way down its height: the
  scenes sit low) and 6% trimmed off each edge so the stock card's rounded
  frame never shows, both fading to nothing over 64px at its sides. A primary
  wears its profession's card (`Profession-overview-Card-<name>`, the client
  name, as the stock page names it; the generic `Profession-overview-Card`
  when there is none), a secondary its generic one
  (`Profession-overview-card-generic-cooking`, `-fishing`, `-firstaid`); an
  empty slot's art is greyed. A primary's ✕ unlearns it (`C_SkillInfo.AbandonSkill`, not
  protected), confirmed by `W.Modal` in danger.

