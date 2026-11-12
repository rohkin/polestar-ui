#### Trainer (`ClassTrainerFrame`) — Risk: medium
Polestar export: Train All (`QoL.Trainer.Start`) needs a new export from Polestar, which needs a Polestar PR
approved first. The window feature-detects it and ships without Train All until
Polestar has it, as the World Map does with `Polestar.MapCanvas.Add`.
Demand-loaded; opened by the interaction manager (Trainer) and by Forever's
`GameEvent` (`TRAINER_SHOW`): both are taken (`ns.Interaction`,
`CloseTrainer`). Its show and hide also run `UpdateMicroButtons`: one more
reason it is never opened. Polestar's "Train All" button hangs on the stock
frame (`QoL/Trainer.lua`); ours carries it in the footer (Polestar's
`QoL.Trainer.Start`).
- **Shell:** 760×600 with sidebar. Subject block: the trainer's portrait
  (`SetPortraitTexture` on a well), the NPC's name, "Warrior trainer".
- **Sidebar:** the stock categories (`Blizzard_TrainerUI_Camelot`: by skill
  line) as nav rows with counts of what can be learnt; the stock filter
  (available, unavailable, used; `MENU_TRAINER_FILTER`) on the sliders button.
- **Main column:** a row per service as Spellbook rows (`ns.SpellRow`'s
  shape): icon, name and rank, under it the cost as a Money line and what it
  needs ("Requires level 26") in danger when unmet; learnt ones in textMuted.
  Click selects and shows its description in a panel under the list.
- **Footer:** Train (primary, `BuyTrainerService`; the stock
  `CONFIRM_PROFESSION` becomes `W.Modal`), Train All (Polestar's).
- **Tests:** `stub_trainer.lua` (services, categories, both open routes); scenes `trainer` (`TRAINER_SHOW` unregistered, the interaction taken, `ClassTrainerFrame` never shown), `trainer-filter`.

