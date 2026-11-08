'use strict';
// findLua, from Polestar's tools/lib/lua.js (GPL-3.0): the first Lua 5.1 on PATH.

const { spawnSync } = require('node:child_process');

let cached;

function findLua() {
	if (cached) return cached;
	const candidates = [process.env.LUA, 'lua5.1', 'luajit', 'lua'].filter(Boolean);
	for (const bin of candidates) {
		const r = spawnSync(bin, ['-e', 'io.write(_VERSION)'], { encoding: 'utf8' });
		if (r.status === 0 && /5\.1/.test(r.stdout)) return (cached = bin);
	}
	throw new Error(`No Lua 5.1 interpreter found (tried ${candidates.join(', ')}). Install lua5.1 or luajit, or set LUA=/path/to/lua5.1.`);
}

module.exports = { findLua };
