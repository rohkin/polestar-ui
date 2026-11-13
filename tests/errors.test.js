'use strict';
// A Lua error that Polestar catches and hands to the client's error handler
// (a module's Enable at login, any event handler) fails the scene.

const test = require('node:test');
const assert = require('node:assert');
const { dumpPanel, metricsLua, loadFonts } = require('../tools/preview');

test('an error in a module Enable fails the scene', () => {
	const panel = { roots: [], stubs: [], script: '', saved: 'PolestarUI.Module("planted", { Enable = function() error("planted in Enable") end })' };
	assert.throws(() => dumpPanel(panel, metricsLua(loadFonts())), /planted in Enable/);
});
