'use strict';
// Text that does not fit, trimmed from Polestar's tools/preview/fit.js (GPL-3.0):
// only audit() and describe(), for tests/preview.test.js. Kinds:
//   cut     a one-line string wider than its box
//   lines   a wrapping string with more lines than its box holds
//   word    a single word wider than its wrapping box
//   window  a string crossing its window's edge or a frame that clips it

const { resolve, wrap, measure } = require('./render');

const H = { LEFT: 0, CENTER: 0.5, RIGHT: 1, TOPLEFT: 0, TOP: 0.5, TOPRIGHT: 1, BOTTOMLEFT: 0, BOTTOM: 0.5, BOTTOMRIGHT: 1 };
const V = { TOP: 0, CENTER: 0.5, BOTTOM: 1, TOPLEFT: 0, LEFT: 0.5, TOPRIGHT: 0, RIGHT: 0.5, BOTTOMLEFT: 1, BOTTOMRIGHT: 1 };

const intersect = (a, r) => ({ x0: Math.max(a.x0, r.x), y0: Math.max(a.y0, r.y), x1: Math.min(a.x1, r.x + r.w), y1: Math.min(a.y1, r.y + r.h) });
const px = (v) => Math.round(v * 10) / 10;

// -> the strings of one dump that do not fit: { text, kind, over, box, what }.
// `kinds` limits the checks (the text-fit test checks only "window").
function audit(dump, roots, fonts, kinds = ['cut', 'lines', 'word', 'window']) {
	const want = new Set(kinds);
	const objects = dump.objects;
	const { byId, rects, scaleOf } = resolve(objects, fonts);
	const parentOf = (o) => (o.parent != null ? byId.get(o.parent) : null);
	const rootOf = (o) => {
		for (let cur = o; cur; cur = parentOf(cur)) if (roots.includes(cur.name)) return cur;
		return null;
	};
	const shown = (o) => {
		for (let cur = o; cur; cur = parentOf(cur)) if (!cur.shown || (cur.alpha ?? 1) <= 0.001) return false;
		return true;
	};
	const out = [];
	for (const o of objects) {
		if (o.kind !== 'FontString' || !o.plain || !o.plain.trim() || !shown(o)) continue;
		const root = rootOf(o);
		if (!root) continue;
		const r = rects.get(o.id);
		const s = scaleOf(o);
		const rr = rects.get(root.id);
		const text = o.plain.replace(/\s+/g, ' ').trim();
		const report = (kind, what, over, box) => {
			if (want.has(kind)) out.push({ text, kind, what, over: px(over), box: box == null ? null : px(box) });
		};
		const pts = o.points;
		const bound = o.anchoredW || (o.w != null && o.w > 0);
		const hasTop = pts.some((p) => V[p.point] === 0), hasBottom = pts.some((p) => V[p.point] === 1);
		const lineH = (n) => (n * o.font[1] + (n - 1) * (o.spacing || 0)) * s;
		// What the client cuts inside the string's own box.
		if (bound && r.w > 0) {
			if (!o.wrap) {
				for (const l of o.plain.split('\n')) {
					const w = measure(fonts, o.font, l) * s;
					if (w - r.w > 0.5) report('cut', 'its width', w - r.w, r.w / s);
				}
			} else {
				const lines = wrap(fonts, o.font, o.plain, r.w / s);
				for (const l of lines) {
					const w = measure(fonts, o.font, l) * s;
					if (w - r.w > 0.5) report('word', 'its width', w - r.w, r.w / s);
				}
				if (o.maxLines && lines.length > o.maxLines) report('lines', `${o.maxLines} lines`, lines.length - o.maxLines, null);
				else if ((o.h != null || (hasTop && hasBottom)) && lineH(lines.length) - r.h > 0.5) report('lines', `its height (${px(r.h / s)})`, lineH(lines.length) - r.h, null);
			}
		}
		// The window, cut down by every clipping frame above the string; the
		// same without the scroll areas, for height (a scroll area scrolls).
		let box = { x0: rr.x, y0: rr.y, x1: rr.x + rr.w, y1: rr.y + rr.h };
		let fixed = { ...box };
		let scrolls = false;
		for (let cur = parentOf(o); cur && cur !== root; cur = parentOf(cur)) {
			if (!cur.clips) continue;
			const cr = rects.get(cur.id);
			box = intersect(box, cr);
			if (cur.kind === 'ScrollFrame') scrolls = true;
			else fixed = intersect(fixed, cr);
		}
		if (!bound) {
			// Unbound: as wide as its text, grown from its anchor.
			const w = Math.max(...o.plain.split('\n').map((l) => measure(fonts, o.font, l))) * s;
			const hx = pts.length ? H[pts[0].point] ?? 0 : 0;
			const x0 = r.x + r.w * hx - w * hx, x1 = x0 + w;
			if (box.x0 - x0 > 0.5) report('window', `the left edge (${box.x0 === rr.x ? 'window' : 'clip'})`, box.x0 - x0);
			if (x1 - box.x1 > 0.5) report('window', `the right edge (${box.x1 === rr.x + rr.w ? 'window' : 'clip'})`, x1 - box.x1);
			continue;
		}
		if (box.x0 - r.x > 0.5) report('window', 'the left edge (its box)', box.x0 - r.x);
		if (r.x + r.w - box.x1 > 0.5) report('window', 'the right edge (its box)', r.x + r.w - box.x1);
		// Wrapping, its height free: the lines it takes.
		if (!o.wrap || scrolls || (hasTop && hasBottom) || o.h != null || r.w <= 0) continue;
		const h = lineH(wrap(fonts, o.font, o.plain, r.w / s).length);
		const vy = hasTop ? 0 : hasBottom ? 1 : 0.5;
		const y0 = r.y + r.h * vy - h * vy, y1 = y0 + h;
		if (fixed.y0 - y0 > 0.5) report('window', 'the top edge', fixed.y0 - y0);
		if (y1 - fixed.y1 > 0.5) report('window', 'the bottom edge', y1 - fixed.y1);
	}
	return out;
}

const describe = (f) => `"${f.text.length > 70 ? f.text.slice(0, 67) + '...' : f.text}" ${f.kind === 'window' ? 'crosses' : 'is cut at'} ${f.what} by ${f.over}${f.kind === 'lines' && f.what.includes('lines') ? ' line(s)' : 'px'}${f.box != null ? ` (box ${f.box})` : ''}`;


module.exports = { audit, describe };
