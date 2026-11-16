'use strict';
// link / unlink [shots]: a directory junction <AddOns>\Polestar_UI -> this repo, so the game loads the working copy;
// with `shots`, <AddOns>\Polestar_UI_Shots -> tools/shots/Polestar_UI_Shots (the dev screenshot addon); with `see`,
// <AddOns>\Polestar_UI_See -> tools/see/Polestar_UI_See (the dev bug-mark addon, docs/see.md).
// AddOns: $WOW_FOREVER_ADDONS (as Polestar's tools), else the first _forever_ client found on a local drive.
// Never deletes or overwrites a real folder; unlink removes only a junction or symlink.

const fs = require('node:fs');
const path = require('node:path');

const TARGETS = {
	main: ['Polestar_UI', path.resolve(__dirname, '..')],
	shots: ['Polestar_UI_Shots', path.resolve(__dirname, 'shots', 'Polestar_UI_Shots')],
	see: ['Polestar_UI_See', path.resolve(__dirname, 'see', 'Polestar_UI_See')],
};
const isDir = (p) => { try { return fs.statSync(p).isDirectory(); } catch { return false; } };

// shortcut: fixed install roots per drive, add a root here when a client lives elsewhere.
function findAddons(env) {
	if (env.WOW_FOREVER_ADDONS) return isDir(env.WOW_FOREVER_ADDONS) ? path.resolve(env.WOW_FOREVER_ADDONS) : null;
	for (const d of 'CDEFGH') {
		for (const root of ['Program Files (x86)', 'Program Files', 'Games', 'Battle.net', '']) {
			const p = path.join(d + ':\\', root, 'World of Warcraft', '_forever_', 'Interface', 'AddOns');
			if (isDir(p)) return p;
		}
	}
	return null;
}

function run(cmd, which = 'main', env = process.env) {
	if ((cmd !== 'link' && cmd !== 'unlink') || !TARGETS[which]) { console.error('usage: node tools/link.js link|unlink [shots|see]'); return 2; }
	const [NAME, REPO] = TARGETS[which];
	const addons = findAddons(env);
	if (!addons) {
		console.error('No WoW Forever AddOns folder found. Set it, then open a new terminal:\n  setx WOW_FOREVER_ADDONS "<WoW>\_forever_\Interface\AddOns"');
		return 1;
	}
	const dest = path.join(addons, NAME);
	let st = null;
	try { st = fs.lstatSync(dest); } catch {}
	if (cmd === 'link') {
		if (st) {
			if (!st.isSymbolicLink()) { console.error(`${dest} is a real folder (a release install?); remove it yourself first. Nothing changed.`); return 1; }
			let same = false;
			try { same = fs.realpathSync(dest) === fs.realpathSync(REPO); } catch {}
			if (!same) { console.error(`${dest} is a link to somewhere else (${fs.readlinkSync(dest)}); unlink it first. Nothing changed.`); return 1; }
			console.log(`Already linked: ${dest} -> ${REPO}`);
			return 0;
		}
		fs.symlinkSync(REPO, dest, 'junction');
		console.log(`Linked: ${dest} -> ${REPO}`);
		return 0;
	}
	if (!st) { console.log(`Not linked: ${dest} does not exist.`); return 0; }
	if (!st.isSymbolicLink()) { console.error(`${dest} is a real folder, not a link; not removing it.`); return 1; }
	fs.unlinkSync(dest); // removes the junction itself, never its contents
	console.log(`Unlinked: ${dest}`);
	return 0;
}

if (require.main === module) process.exitCode = run(process.argv[2], process.argv[3]);
module.exports = { findAddons };
