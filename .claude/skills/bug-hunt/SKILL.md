---
name: bug-hunt
description: Triage the in-game Lua error log (BugGrabber/BugSack) and fix the errors that belong to Polestar: UI. Use when the user says "bug hunt", "buggrabber", "bugsack", "check the errors" or "scan for errors" (the in-game error log, not a code audit).
---

# Bug hunt

Report first, fix only after the user picks.

1. **Find the log.** `WTF/Account/*/SavedVariables/!BugGrabber.lua`; the path is in `docs/CLIENT.md` ("Reading errors from the game"). If it is not there, go up from the AddOns folder `npm run link` autodetects to the install root. It is large: never dump it. Run `node .claude/skills/bug-hunt/bugs.js <file> [filter=PolestarUI] [localsMatch]`: it prints the entry count, the latest session number and each match (session, count, time, message, stack; locals for messages containing `localsMatch`). Entries are `BugGrabberDB.errors` (message, stack, locals, counter, time, session). Only the newest session's entries are new; note it and the newest entry time. The file is written on `/reload` or logout.
2. **Keep ours.** Keep entries whose message or stack touch PolestarUI. Group duplicates: one row per message with total count and newest session and time.
3. **Map to current code.** The game runs the working copy through a junction, so line numbers may come from uncommitted or since-changed code. Match by function and stack, then `git log --since=<error time> -- <file>`. Classify: still present, or already fixed (name the commit or the CLIENT.md rule).
4. **Scope rule.** Fix only errors whose root cause is in this repo.
   - Errors in Polestar (`../polestar`), Polestar_Mob_Markers, Polestar_Guides or third-party addons (Questie, ...): report only, one line each with the suggested fix and the repo it belongs to. Never edit them from here.
   - If the error surfaces in Polestar's code but our call causes it (e.g. we pass secret text to a Polestar widget), it is ours: fix our call site.
5. **Flag client rules.** Taint, `ADDON_ACTION_BLOCKED`, `ADDON_ACTION_FORBIDDEN` and secret-value errors: tie each to its `docs/CLIENT.md` rule (read it first). A new kind of client rule learnt goes into CLIENT.md.
6. **Report**, ranked: still present (with the cause), fixed since, other repos (one line each), other addons (a count only). Then ask which to fix.
7. **Fix** each chosen one: root cause once in shared code, a regression scene or assert, `npm test`, a `CHANGELOG.md` line, one commit per fix (subject line only).
