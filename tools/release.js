#!/usr/bin/env node
// Release: node tools/release.js [version|patch|minor] [--push] [--dry-run]
// Does what the "Release 0.0.5" commit did: toc Version, "## Unreleased" -> "## <version>", commit, lightweight tag v<version>.
const { execSync, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.join(__dirname, "..");
const args = process.argv.slice(2);
const push = args.includes("--push");
const dry = args.includes("--dry-run");
const want = args.find((a) => !a.startsWith("--")) || "patch";
const git = (c) => execSync("git " + c, { cwd: root, encoding: "utf8" }).trim();
const fail = (m) => { console.error("release: " + m); process.exit(1); };

const tocFile = path.join(root, "Polestar_UI.toc");
const logFile = path.join(root, "CHANGELOG.md");
const toc = fs.readFileSync(tocFile, "utf8");
const cur = (toc.match(/^## Version: (\d+)\.(\d+)\.(\d+)\s*$/m) || fail("no ## Version in the .toc")).slice(1).map(Number);
let next;
if (want === "patch") next = [cur[0], cur[1], cur[2] + 1];
else if (want === "minor") next = [cur[0], cur[1] + 1, 0];
else if (/^\d+\.\d+\.\d+$/.test(want)) next = want.split(".").map(Number);
else fail(`bad version "${want}" (use x.y.z, patch or minor)`);
const version = next.join(".");
const tag = "v" + version;

if (git("status --porcelain")) fail("the working tree is not clean");
if (git("branch --show-current") !== "main") fail("not on main");
if (git(`tag -l ${tag}`)) fail(`tag ${tag} already exists`);

const log = fs.readFileSync(logFile, "utf8");
const m = log.match(/^## Unreleased[ \t]*\r?\n([\s\S]*?)(?=^## |(?![\s\S]))/m);
if (!m) fail('CHANGELOG.md has no "## Unreleased" section');
if (!/^\s*[-*] /m.test(m[1])) fail('"## Unreleased" has no entries');

console.log(`Release ${version} (from ${cur.join(".")}), tag ${tag}`);
console.log("Touches: Polestar_UI.toc, CHANGELOG.md\n## " + version + "\n" + m[1].trimEnd() + "\n");
const pushCmd = `git push origin main ${tag}`;
if (dry) { console.log("Dry run: nothing changed. Real run pushes with:\n  " + pushCmd); process.exit(0); }

if (spawnSync("npm", ["test"], { cwd: root, stdio: "inherit", shell: true }).status !== 0) fail("npm test failed");

fs.writeFileSync(tocFile, toc.replace(/^## Version: .*$/m, "## Version: " + version));
fs.writeFileSync(logFile, log.replace(/^## Unreleased/m, "## " + version));
git("add -- Polestar_UI.toc CHANGELOG.md");
git(`commit -m "Release ${version}"`);
git(`tag ${tag}`);
console.log(`Committed "Release ${version}" and tagged ${tag}.`);
if (push) { execSync(pushCmd, { cwd: root, stdio: "inherit" }); }
else console.log("Push with:\n  " + pushCmd);
