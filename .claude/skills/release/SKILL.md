---
name: release
description: Cut a Polestar: UI release. Use when the user says "release", "new version" or "publish".
---

# Release

`tools/release.js` does the mechanics (guards, npm test, toc version, changelog heading, "Release <version>" commit, tag `v<version>`, optional push). Your part is small.

1. Tidy `## Unreleased` in `CHANGELOG.md`: merge duplicates, one line per window or feature area, user-facing wording, no internal names or hashes (match the 0.0.5 section). Commit it as its own commit (the script needs a clean tree).
2. Ask the user for the version (default: patch; or minor, or x.y.z) and whether to push.
3. Run `node tools/release.js <version> --dry-run` and show the plan. After the user confirms, run `node tools/release.js <version>` (add `--push` if approved; a push triggers the CurseForge workflow).
4. Report the tag, and after a push the workflow run: `gh run list --limit 1`.

Never edit settings files, and never tag or push by hand.
