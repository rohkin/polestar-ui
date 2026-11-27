-- Client rules the generic stub (wow_stub.lua) lets slide, each one a bug
-- that reached the game: loaded for every Polestar: UI preview scene.

local M = stub.Methods

-- The call stack as text, as the client's debugstack gives it.
function debugstack() return debug.traceback("", 2) end

-- Secret values: in combat the player's name reaches addon code secret, and
-- neither a tooltip nor our strings (Polestar's font hook reads them) take one.
-- A string on a game font object has no hook: it holds the secret as is.
-- (stub_character.lua's UnitPVPName answers stub.SECRET the same way.)
local SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
stub.SECRET = SECRET
function issecretvalue(v) return v == SECRET end
local unitName = UnitName
function UnitName(unit, ...)
	if unit == "player" and InCombatLockdown() then return SECRET end
	return unitName(unit, ...)
end
local tipText = GameTooltip.SetText
function GameTooltip.SetText(self, t, ...)
	if t == SECRET then error("bad argument #2 to 'SetText' (a secret value)", 2) end
	return tipText(self, t, ...)
end

-- A FontString with no font (none set, no font object, no template) cannot
-- take text: the client errors "Font not set".
local create, setText = M.CreateFontString, M.SetText
function M.CreateFontString(self, name, layer, inherits)
	local fs = create(self, name, layer, inherits)
	fs.psInherits = inherits
	return fs
end
function M.SetText(self, t)
	if t == SECRET then
		if self.kind == "FontString" and self.fontObject then self.text = SECRET return end
		error("bad argument #2 to 'SetText' (a secret value)", 2)
	end
	if self.kind == "FontString" and not (self.font or self.fontObject or self.psInherits) then
		error("FontString:SetText(): Font not set", 2)
	end
	return setText(self, t)
end

-- With no font, GetFont answers nil (the stub's default would make code that
-- skips SetFont when "already set" leave the string fontless).
local getFont = M.GetFont
function M.GetFont(self)
	if self.kind == "FontString" and not (self.font or self.fontObject or self.psInherits) then return nil end
	return getFont(self)
end

-- Key bindings: the keys bound to each action, and the override bindings set
-- over them (refused in combat). stub.pressKey(key) runs what the key does:
-- the override's button, else the game's own binding (stub.bindingRun[action]).
stub.bindings = { TOGGLETALENTS = { "N" }, TOGGLESPELLBOOK = { "P" }, TOGGLEPETBOOK = { "SHIFT-P" }, TOGGLEPROFESSIONBOOK = { "K" } }
stub.overrides, stub.bindingRun = {}, {}
function GetBindingKey(action) return unpack(stub.bindings[action] or {}) end
function SetOverrideBindingClick(owner, priority, key, button)
	if InCombatLockdown() then error("SetOverrideBindingClick is protected in combat", 2) end
	stub.overrides[key] = button
end
function ClearOverrideBindings(owner)
	if InCombatLockdown() then error("ClearOverrideBindings is protected in combat", 2) end
	stub.overrides = {}
end
function stub.pressKey(key)
	if stub.overrides[key] then return _G[stub.overrides[key]]:Click() end
	for action, keys in pairs(stub.bindings) do
		for _, k in ipairs(keys) do if k == key and stub.bindingRun[action] then stub.bindingRun[action]() end end
	end
end

-- stub.dragHeader(f, dx, dy): the left button held on a shell's header, the
-- pointer moved (dx, dy physical px), let go: Polestar's ns.DragWindow path.
function stub.dragHeader(f, dx, dy)
	local x, y = stub.cursor[1], stub.cursor[2]
	stub.RunScript(f.Header, "OnMouseDown", "LeftButton")
	stub.cursor = { x + dx, y + dy }
	stub.RunScript(f.Header, "OnMouseUp", "LeftButton")
	stub.cursor = { x, y }
end

-- EditBox:SetText runs OnTextChanged (userInput false), as the client does.
local setTextChanged = M.SetText
function M.SetText(self, t)
	local was = self.text
	setTextChanged(self, t)
	if self.kind == "EditBox" and self.text ~= was then stub.RunScript(self, "OnTextChanged", false) end
end

-- The mouse's motion half (OnEnter/OnLeave) apart from its clicks: a stock
-- TextStatusBar (enableMouseMotion) or a header button. EnableMouse sets both.
function M.SetMouseMotionEnabled(self, v) self.mouseMotion = v and true or false end
function M.IsMouseMotionEnabled(self)
	if self.mouseMotion == nil then return self.mouse == true end
	return self.mouseMotion
end
local enableMouse = M.EnableMouse
function M.EnableMouse(self, v) self.mouseMotion = nil return enableMouse(self, v) end

-- Frame:SetRolesets (the UI modes' visibility tags, C_Roleset) is protected:
-- a protected frame (stub_unitframes.lua's psProtected) refuses it in combat.
-- GetRolesetNames answers the tags, "roleless" while none are set.
function M.SetRolesets(self, s)
	if self.psProtected and InCombatLockdown() then
		error("SetRolesets on protected " .. tostring(self.name) .. " in combat (ADDON_ACTION_BLOCKED, rule 4)", 2)
	end
	self.rolesets = s
end
function M.GetRolesetNames(self)
	local t = {}
	for r in tostring(self.rolesets or "roleless"):gmatch("[^,%s]+") do t[#t + 1] = r end
	return t
end

-- Font families: each alphabet's own face, picked by the engine per glyph.
-- stub.fontFamilies[name] = the family (fam.members as given); a name used
-- twice errors. The game fonts answer the client's faces per alphabet.
stub.fontFamilies = {}
local ALPHABET_FACES = { roman = STANDARD_TEXT_FONT, russian = "Fonts\\FRIZQT___CYR.TTF", korean = "Fonts\\2002.TTF",
	simplifiedchinese = "Fonts\\ARKai_T.ttf", traditionalchinese = "Fonts\\bLEI00D.ttf" }
function M.GetFontObjectForAlphabet(self, alphabet)
	local _, size, flags = self:GetFont()
	local o = CreateFont(nil)
	o:SetFont(ALPHABET_FACES[alphabet] or STANDARD_TEXT_FONT, size, flags)
	return o
end
function CreateFontFamily(name, members)
	if stub.fontFamilies[name] then error("CreateFontFamily: font family '" .. name .. "' already exists", 2) end
	local fam = CreateFont(name)
	fam.members = members
	for _, m in ipairs(members) do if m.alphabet == "roman" then fam:SetFont(m.file, m.height, m.flags) end end
	stub.fontFamilies[name] = fam
	return fam
end

-- A Button's state, as the client answers it (stub_actionbars.lua tracks it).
M.GetButtonState = M.GetButtonState or function(self) return self.buttonState or "NORMAL" end

-- Polestar_Options' preview band (UI.Preview.Band), not loaded in the
-- preview: a stand-in laying f:Content out at k = 1 as the band does, again
-- on every Theme.Refresh (a painter on it, as the band's ground). A scene
-- puts it in place: Polestar.UI = { Preview = stub.preview }. f.laidOut counts.
stub.preview = { Snap = function(_, v) return v end }
function stub.preview.Band(parent)
	local f = CreateFrame("Frame", nil, parent)
	function f:TrueScale() return 1 end
	function f:Layout(width)
		self.psWidth = width
		local _, h, place = self:Content(width)
		place(0, 16, 1)
		self.laidOut = (self.laidOut or 0) + 1
		return h + 32
	end
	Polestar.Widgets.Painter(f, function() if f.psWidth then f:Layout(f.psWidth) end end)
	return f
end

-- A frame's size set to a new one runs its OnSizeChanged (its script, then
-- its hooks) with the new width and height, as the client does: what refits
-- on it (W.SearchBox's placeholder, hidden below 64 wide) renders at the size
-- it is drawn at. Not again from inside its own handler. (Polestar's own
-- preview stub does the same, #3427.) The stub lays nothing out, so an edit
-- box held by a left and a right anchor on one frame (a search moved into a
-- dropdown, ns.FilterMenu) takes its width from them, again whenever that
-- frame is resized.
do
	local setSize, setWidth, setHeight, setPoint = M.SetSize, M.SetWidth, M.SetHeight, M.SetPoint
	local REGION = { FontString = true, Texture = true, Line = true, MaskTexture = true }
	local edits = setmetatable({}, { __mode = "k" }) -- frame -> { edit box anchored on it }
	local function side(p) return p:find("LEFT") and 0 or p:find("RIGHT") and 1 or 0.5 end
	-- A frame's left and right x along its anchors, up to one with no anchor
	-- (at 0, its own width); nil where they do not say. Scale is ignored.
	local function edges(f, depth)
		if depth > 12 then return end
		local fixed, w = {}, M.GetWidth(f)
		for _, p in ipairs(f.points or {}) do
			local rel = p.rel or f.parent
			local rl, rr
			if rel then rl, rr = edges(rel, depth + 1) end
			if rl then fixed[#fixed + 1] = { side(p.point), rl + (rr - rl) * side(p.relPoint) + p.x } end
		end
		if #(f.points or {}) == 0 then return 0, w end
		local a, b = fixed[1], nil
		for i = 2, #fixed do if fixed[i][1] ~= a[1] then b = fixed[i] end end
		if a and b then
			local span = (b[2] - a[2]) / (b[1] - a[1])
			local l = a[2] - a[1] * span
			return l, l + span
		elseif a and w > 0 then
			return a[2] - a[1] * w, a[2] + (1 - a[1]) * w
		end
	end
	-- An edit box held by a left and a right anchor takes its width from them.
	local function fit(e)
		local l, r
		for _, p in ipairs(e.points) do
			if p.point:find("LEFT") then l = p elseif p.point:find("RIGHT") then r = p end
		end
		if not (l and r) then return end
		local x0, x1 = edges(e, 0)
		if x0 and x1 > x0 then M.SetWidth(e, x1 - x0) end
	end
	local function resize(set)
		return function(self, ...)
			local w0, h0 = M.GetWidth(self), M.GetHeight(self)
			set(self, ...)
			local w, h = M.GetWidth(self), M.GetHeight(self)
			if w == w0 and h == h0 then return end
			if self.scripts ~= nil and not REGION[self.kind] and not self.psSizing then
				self.psSizing = true
				local ok, err = pcall(stub.RunScript, self, "OnSizeChanged", w, h)
				self.psSizing = nil
				if not ok then error(err, 0) end
			end
			for e in pairs(edits[self] or {}) do fit(e) end
		end
	end
	M.SetSize, M.SetWidth, M.SetHeight = resize(setSize), resize(setWidth), resize(setHeight)
	-- tools/preview/stub.lua sets its own SetPoint after this file and calls this.
	function stub.fitEdit(self)
		if self.kind ~= "EditBox" then return end
		local rel = self.points[#self.points].rel or self.parent
		if rel then
			edits[rel] = edits[rel] or setmetatable({}, { __mode = "k" })
			edits[rel][self] = true
		end
		fit(self)
	end
	function M.SetPoint(self, ...) setPoint(self, ...) stub.fitEdit(self) end
end
