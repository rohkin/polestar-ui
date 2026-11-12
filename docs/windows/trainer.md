#### Trainer (`ClassTrainerFrame`) — Risk: medium
Demand-loaded; opened by the interaction manager (Trainer) and by Forever's
`GameEvent` (`TRAINER_SHOW`): both are taken (`ns.Interaction`,
`CloseTrainer`). Its show and hide also run `UpdateMicroButtons`: one more
reason it is never opened. There is no Train All: Polestar removed its bulk
spell purchase (`QoL.Trainer.Start`) on purpose.
- **Shell:** 760×600 with sidebar. Subject block: the trainer's portrait
  (`SetPortraitTexture` on a well; the pet's at a pet trainer), the name,
  "Warrior trainer" ("Profession trainer", "Pet trainer"). Band subtitle: what can be learnt, and at a profession
  trainer the rank (`GetTrainerTradeskillRankValues`, the stock status bar's
  "Skill 75 (+5)/150").
- **Sidebar:** the stock categories (`Blizzard_TrainerUI_Camelot`: by skill
  line, sorted by name as the stock list) as nav rows with counts of what can
  be learnt, when categorized; the sidebar search keeps to the services
  whose name has it; the stock filter menu (`MENU_TRAINER_FILTER`) on the
  sliders button at the end of the search row: available, unavailable, used,
  Clear filters while one is off, and Categorize
  (`C_Trainer.Get/SetCategorizeTrainerUI`; none at a pet trainer, which never
  categorizes). The glyph is lit and its tooltip counts the types hidden
  ("Filter (2 on)").
- **Main column:** a row per service (service-type headers skipped; the
  rows span the body, a one-line row's name in its middle), as
  `ClassTrainerFrame_InitServiceButton`: icon (desaturated when unavailable),
  name and rank (greyed when unavailable), under it "Requires Level 26,
  Tailoring (75), Defensive Stance" with each unmet part in danger, or
  "Already known"; the cost as a Money line (danger when too dear), at a pet
  trainer the training points ("10 TP"). A profession's next rank
  (`GetTrainerServiceStepIndex`, the stock skill step button) heads the list
  in every view. Hover: the game's tooltip (`SetTrainerService`). Click
  selects, and selects it for the client too (`SelectTrainerService`); the
  first learnable is selected on open. The stock window has no details pane:
  the needs are in the row, the rest in the tooltip.
- **Footer:** the player's money, or a pet's training points left (the stock
  tooltip, `TRAINING_POINTS_TUTORIAL`), at the left; Train (primary,
  `BuyTrainerService`; the stock `CONFIRM_PROFESSION` becomes `W.Modal`), off
  when nothing is selected, known, unavailable, too dear, or a profession
  with no free slot; its tooltip says why (`ns.SetEnabled`), as the stock
  button's for the slot. Redraws on `TRAINER_UPDATE`,
  `TRAINER_DESCRIPTION_UPDATE`, `TRAINER_SERVICE_INFO_NAME_UPDATE`, money and
  training points.
- **Tests:** `stub_trainer.lua` (services with a header, categories and Categorize, the step and rank, training points, both open routes); scenes `trainer` (`TRAINER_SHOW` unregistered, the interaction taken, `ClassTrainerFrame` never shown, needs, header skipped), `trainer-filter` (filter, its count and Clear filters, Categorize, the search), `trainer-pet` (training points), `trainer-profession` (rank, next rank, no slot and the reason in Train's tooltip, a one-line row centred).
