-- Edit Mode's hold on the HUD (docs/CLIENT.md, rule 17), shared by
-- stub_minimap.lua and stub_actionbars.lua (each loads it with require).
-- EditModeSystemMixin:OnSystemLoad writes SetPoint, SetScale,
-- ClearAllPoints, Hide and SetShown as Lua keys on every system frame, and
-- a secure button's place and attributes are the game's: stub.guard(frame,
-- calls) gives a stock frame those keys, each one erroring when called from
-- Polestar: UI's own files, and errors on any Lua key our files write on it.
-- The stub's own code (standing in for the game's) may still call them.
-- hooksecurefunc on a guarded frame errors too (it writes the method's key).
-- MinimapCluster's clamp insets are rule 17's minimap exception (hookAllowed).
-- The stock unit frames are not guarded here: rule 16's veil (EnableMouse,
-- SetAlpha, its children's Hide) is rule 17's one exception, and
-- stub_unitframes.lua guards them, allowing exactly those calls.

local function ours(level)
	local info = debug.getinfo(level + 1, "S")
	return info and stub.addonSources[info.source] == "Polestar_UI"
end

-- A breach errors where it happens, and is kept: Polestar's login and event
-- handlers catch errors, so the next stub.advance (every scene ends with one)
-- raises it again.
stub.breaches = {}
local function breach(msg)
	table.insert(stub.breaches, msg)
	io.stderr:write(msg .. "\n")
	error(msg, 3)
end
local advance = stub.advance
function stub.advance(...)
	advance(...)
	if stub.breaches[1] then error(stub.breaches[1], 2) end
end

-- What Polestar: UI must never call on an Edit Mode system frame or a secure button.
stub.SYSTEM_CALLS = { "SetPoint", "ClearAllPoints", "SetAllPoints", "SetScale", "Hide", "Show", "SetShown", "SetParent",
	"SetAttribute", "EnableMouse", "SetSize", "SetWidth", "SetHeight", "SetFrameStrata", "SetFrameLevel", "SetAlpha",
	"SetClampRectInsets" }

stub.guarded = setmetatable({}, { __mode = "k" })
function stub.guard(f, calls, label)
	label = label or f:GetName() or "a stock frame"
	local mt = getmetatable(f)
	setmetatable(f, {
		__index = mt.__index,
		__newindex = function(t, k, v)
			if ours(2) then breach("Polestar: UI wrote the key " .. tostring(k) .. " on " .. label) end
			rawset(t, k, v)
		end,
	})
	for _, name in ipairs(calls or {}) do
		local base = f[name]
		rawset(f, name, function(self, ...)
			if ours(2) then breach("Polestar: UI called " .. name .. " on " .. label) end
			return base(self, ...)
		end)
	end
	stub.guarded[f] = label
	return f
end

-- Rule 17's one minimap exception (the user's leave): Polestar: UI may
-- hook MinimapCluster's UpdateClampOffsets and UpdateSystemSetting (to
-- re-set the clamp insets after Edit Mode's); every other hook on a
-- guarded frame errors. SetClampRectInsets is a call on the cluster alone.
stub.hookAllowed = setmetatable({}, { __mode = "k" })

local hook = hooksecurefunc
function hooksecurefunc(a, b, c)
	if type(a) == "table" and stub.guarded[a] and ours(2) and not (stub.hookAllowed[a] and stub.hookAllowed[a][b]) then breach("Polestar: UI hooked " .. tostring(b) .. " on " .. stub.guarded[a]) end
	return hook(a, b, c)
end

-- A Blizzard frame's global is secure; an addon's is not.
stub.secureNames = {}
function issecurevariable(t, name)
	if name == nil then name = t end
	return stub.secureNames[name] == true
end

-- CVarCallbackRegistry (CvarUtil.lua): a CVar's callbacks, run when the
-- stub sets it, ours (registered after the game's) first: the client keeps
-- them in no set order.
CVarCallbackRegistry = { callbacks = {} }
function CVarCallbackRegistry:RegisterCallback(cvar, fn, owner)
	self.callbacks[cvar] = self.callbacks[cvar] or {}
	table.insert(self.callbacks[cvar], 1, { fn = fn, owner = owner })
end
function CVarCallbackRegistry:GetCVarValueBool(cvar) return GetCVarBool(cvar) end
function stub.setCVar(cvar, value)
	stub.cvars[cvar] = value
	for _, c in ipairs(CVarCallbackRegistry.callbacks[cvar] or {}) do c.fn(c.owner, value) end
	stub.fire("CVAR_UPDATE", cvar, value)
end

-- Leaving Edit Mode after a change: the layout event, then stub_unitframes.lua's
-- exit (loaded first for every scene: its Selection boxes hidden, the pet,
-- party and boss frames back, then EditMode.Exit), so the unit frames' Edit
-- Mode handling runs in the minimap and action bar scenes too.
local unitExit = stub.exitEditMode
function stub.exitEditMode()
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
	if unitExit then return unitExit() end
	EventRegistry:TriggerEvent("EditMode.Exit")
end
