'use strict';
// Visual regression: every preview scene must render byte for byte as its
// golden in tests/golden. On a difference the new render is written next to
// it as <scene>.actual.svg (gitignored) to open side by side; if the change is
// meant, `npm run preview` re-blesses the goldens. Also: no visible text may
// overflow its box or window.

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { POLESTAR_DIR } = require('./helpers/lua');
const { SCENES, GOLDEN, render, loadFonts } = require('../tools/preview');
const { audit, describe } = require(path.join(POLESTAR_DIR, 'tools', 'preview', 'fit'));

const out = render();
const fonts = loadFonts();

for (const scene of SCENES) {
	const name = scene.file.replace(/\.svg$/, '');
	const r = out[scene.file];

	test(`${name}: matches its golden`, () => {
		const golden = path.join(GOLDEN, scene.file);
		const actual = golden.replace(/\.svg$/, '.actual.svg');
		assert.ok(fs.existsSync(golden), `no golden for ${name}: run npm run preview`);
		if (fs.readFileSync(golden, 'utf8') === r.svg) {
			fs.rmSync(actual, { force: true });
			return;
		}
		fs.writeFileSync(actual, r.svg);
		assert.fail(`${name} renders differently from its golden; compare ${path.relative(process.cwd(), actual)} with it`);
	});

	test(`${name}: no text overflows`, () => {
		const found = r.dumps.flatMap((d, i) => audit(d, scene.panels[i].roots, fonts));
		assert.deepStrictEqual(found.map(describe), []);
	});
}
