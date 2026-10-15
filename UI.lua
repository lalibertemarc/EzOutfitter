-- EzOutfitter palette (your Looks, the Look editor, options), the strip beside the character
-- window and the launcher icon.
--
-- Look buttons are secure, so the palette and the strip that hold them can't be shown, hidden
-- or moved in combat. Both close when combat starts; the palette won't open until it ends.
local _, ns = ...

local PAD, GAP = 8, 6
local WIDTH = 270
local HEAD_H = 20
local BODY_TOP = -(PAD + HEAD_H + GAP)
local ROW_H, ICON_S = 34, 28
local FIELD_H, LABEL_H = 22, 16
local PICK_ROW_H = 20
local STRIP_S, STRIP_GAP = 30, 3
local EDITOR_H, OPTIONS_H = 268, 290

local WHITE = "Interface\\Buttons\\WHITE8x8"
local FLAT = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
local GOLD, ACTIVE, MUTED, WARN = ns.COLORS.gold, ns.COLORS.active, ns.COLORS.muted, ns.COLORS.warn
local LIGHT, WHITE_TEXT = { 0.9, 0.9, 0.9 }, { 1, 1, 1 }

local function Skin(f, alpha)
    f:SetBackdrop(FLAT)
    f:SetBackdropColor(0.05, 0.05, 0.06, alpha or 0.92)
    f:SetBackdropBorderColor(1, 1, 1, 0.08)
end

local function Text(parent, font)
    return parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
end

local function Hover(f, alpha)
    local hl = f:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, alpha or 0.08)
end

local function Colored(color, s)
    local function Hex(c) return math.floor(c * 255 + 0.5) end
    return format("|cff%02x%02x%02x%s|r", Hex(color[1]), Hex(color[2]), Hex(color[3]), s)
end

-- Flat button with a centered label.
local function TextButton(parent, label, width)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, 20)
    Skin(b, 0.6)
    Hover(b)
    b.text = Text(b)
    b.text:SetPoint("CENTER")
    b.text:SetText(label)
    return b
end

local function SingleLineBox(parent, placeholder)
    local e = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    e:SetHeight(FIELD_H)
    Skin(e, 0.5)
    e:SetFontObject("GameFontHighlightSmall")
    e:SetTextInsets(6, 6, 0, 0)
    e:SetAutoFocus(false)
    e.placeholder = Text(e, "GameFontDisableSmall")
    e.placeholder:SetPoint("LEFT", 7, 0)
    e.placeholder:SetPoint("RIGHT", -6, 0)
    e.placeholder:SetJustifyH("LEFT")
    e.placeholder:SetWordWrap(false)
    e.placeholder:SetText(placeholder)
    e:SetScript("OnTextChanged", function(self) self.placeholder:SetShown(self:GetText() == "") end)
    return e
end

-- Remembers where frame is in EzOutfitterDB[field], by its top left corner so it grows down.
local function Movable(frame, field)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        EzOutfitterDB[field] = { "TOPLEFT", "BOTTOMLEFT", self:GetLeft(), self:GetTop() }
    end)
end

-- Small button showing only a texture, which brightens under the mouse.
local function IconButton(parent, width, height, texture, texSize)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetTexture(texture)
    b.tex:SetSize(texSize, texSize)
    b.tex:SetPoint("CENTER")
    b.tex:SetAlpha(0.6)
    b:SetScript("OnEnter", function(self) self.tex:SetAlpha(1) end)
    b:SetScript("OnLeave", function(self) self.tex:SetAlpha(0.6) end)
    return b
end

local function Place(frame, field, ...)
    local p = EzOutfitterDB[field]
    frame:ClearAllPoints()
    if p then
        frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        frame:SetPoint(...)
    end
end

---------------------------------------------------------------------------
-- Look buttons (palette rows and strip icons): tooltip and look
---------------------------------------------------------------------------
-- "Tank set + Knight" for a row; parts gone from the game show in red.
local function Detail(look)
    local gear, gearMissing, outfit, outfitMissing = ns.Describe(look)
    if gearMissing then gear = Colored(WARN, "set gone") end
    if outfitMissing then outfit = Colored(WARN, "outfit gone") end
    return format("%s  +  %s", gear or "same gear", outfit or "same outfit")
end

local function ShowLookTooltip(b)
    local look = b.look
    if not look then return end
    local gear, gearMissing, outfit, outfitMissing = ns.Describe(look)
    GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
    GameTooltip:AddLine(look.name, 1, 1, 1)
    if ns.IsActive(look) then GameTooltip:AddLine("Wearing it", unpack(ACTIVE)) end
    local wait = ns.OutfitWait(look)
    if wait > 0 then GameTooltip:AddLine(format("Outfit ready in %d s", math.ceil(wait)), unpack(WARN)) end
    GameTooltip:AddDoubleLine("Gear set", gearMissing and "gone, pick another" or gear or "not changed",
        0.6, 0.6, 0.6, unpack(gearMissing and WARN or LIGHT))
    GameTooltip:AddDoubleLine("Outfit", outfitMissing and "gone, pick another" or outfit or "not changed",
        0.6, 0.6, 0.6, unpack(outfitMissing and WARN or LIGHT))
    if look.emote and look.emote ~= "" then GameTooltip:AddLine("/e " .. look.emote, 0.8, 0.8, 0.8, true) end
    local key = b.index <= ns.BINDING_COUNT and GetBindingKey(ns.BindingAction(b.index))
    if key then GameTooltip:AddDoubleLine("Key", GetBindingText(key), 0.6, 0.6, 0.6, unpack(GOLD)) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click: wear it   Shift-click: keep open", unpack(MUTED))
    GameTooltip:AddLine("Right-click: edit   Ctrl-right-click: copy", unpack(MUTED))
    GameTooltip:AddLine("Shift-right-click: move earlier", unpack(MUTED))
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

-- The outfit cooldown swipe, on Looks that change your outfit.
local function PaintCooldown(b)
    local wait, start, duration = 0
    if b.look then wait, start, duration = ns.OutfitWait(b.look) end
    if wait > 0 then
        b.cooldown:SetCooldown(start, duration)
    else
        b.cooldown:Clear()
    end
end

-- Icon, name, cooldown and the green border of the Look you're wearing. Visual only, so fine in combat.
local function Paint(b)
    local look = b.look
    if not look then return end
    PaintCooldown(b)
    local active = ns.IsActive(look)
    b.icon:SetTexture(ns.LookIcon(look))
    if active then
        b:SetBackdropBorderColor(ACTIVE[1], ACTIVE[2], ACTIVE[3], 0.9)
    else
        b:SetBackdropBorderColor(1, 1, 1, b.name and 0.08 or 0.25)
    end
    if not b.name then return end
    b.name:SetText(look.name)
    b.name:SetTextColor(unpack(active and ACTIVE or WHITE_TEXT))
    b.detail:SetText(Detail(look))
    local key = b.index <= ns.BINDING_COUNT and GetBindingKey(ns.BindingAction(b.index))
    b.key:SetText(key and GetBindingText(key) or "")
end

local function LookButton(parent, index)
    local b = ns.NewLookButton(nil, parent, "BackdropTemplate")
    b.index = index
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnEnter", ShowLookTooltip)
    b:SetScript("OnLeave", HideTooltip)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cooldown:SetAllPoints(b.icon)
    b.cooldown:SetDrawEdge(false)
    b:Hide()
    return b
end

-- Points buttons at your Looks in order, shows the ones that have one and paints them. Out of combat only.
local function ArmAll(buttons)
    local looks = EzOutfitterDB.looks
    for i, b in ipairs(buttons) do
        ns.ArmButton(b, looks[i])
        b:SetShown(looks[i] ~= nil)
        Paint(b)
    end
end

---------------------------------------------------------------------------
-- Palette
---------------------------------------------------------------------------
local palette = CreateFrame("Frame", "EzOutfitterPalette", UIParent, "BackdropTemplate")
palette:SetSize(WIDTH, 120)
Skin(palette)
palette:SetFrameStrata("DIALOG")
palette:EnableMouse(true)
Movable(palette, "palettePos")
palette:Hide()
tinsert(UISpecialFrames, "EzOutfitterPalette") -- Esc closes it

local mode = "list" -- "list" | "editor" | "options"
local SetMode, OpenEditor -- defined below

local title = Text(palette, "GameFontNormal")
title:SetPoint("TOPLEFT", PAD + 2, -PAD - 3)

local OPTIONS_ICON = "Interface\\Buttons\\UI-OptionsButton"

local gear = IconButton(palette, HEAD_H, HEAD_H, OPTIONS_ICON, 14)
gear:SetPoint("TOPRIGHT", -PAD, -PAD)
gear:SetScript("OnClick", function() SetMode(mode == "options" and "list" or "options") end)

---------------------------------------------------------------------------
-- List of Looks
---------------------------------------------------------------------------
local list = CreateFrame("Frame", nil, palette)
list:SetPoint("TOPLEFT", PAD, BODY_TOP)
list:SetPoint("BOTTOMRIGHT", -PAD, PAD)

local rows = {}
for i = 1, ns.MAX_LOOKS do
    local r = LookButton(list, i)
    r:SetSize(WIDTH - 2 * PAD, ROW_H - 2)
    r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    Skin(r, 0.4)
    Hover(r)
    r.icon:SetSize(ICON_S, ICON_S)
    r.icon:SetPoint("LEFT", 2, 0)
    r.key = Text(r, "GameFontDisableSmall")
    r.key:SetPoint("TOPRIGHT", -6, -5)
    r.name = Text(r, "GameFontHighlight")
    r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1)
    r.name:SetPoint("RIGHT", r.key, "LEFT", -4, 0)
    r.name:SetJustifyH("LEFT")
    r.name:SetWordWrap(false)
    r.detail = Text(r, "GameFontDisableSmall")
    r.detail:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 1)
    r.detail:SetPoint("RIGHT", -6, 0)
    r.detail:SetJustifyH("LEFT")
    r.detail:SetWordWrap(false)
    rows[i] = r
end

local empty = Text(list, "GameFontDisableSmall")
empty:SetPoint("TOPLEFT", 2, -2)
empty:SetPoint("RIGHT", -2, 0)
empty:SetJustifyH("LEFT")
empty:SetSpacing(3)
empty:SetText("A Look is an equipment set and a transmog outfit you put on together, "
    .. "with an optional /e line. Make one from what you're wearing:")

local newLook = TextButton(list, "+ New look", WIDTH - 2 * PAD)
newLook:SetScript("OnClick", function() OpenEditor() end)

-- Arms and places the rows for your Looks and sizes the palette to fit. Out of combat only.
local function LayoutList()
    local looks = EzOutfitterDB.looks
    ArmAll(rows)
    empty:SetShown(#looks == 0)
    local listH = #looks == 0 and (math.max(empty:GetStringHeight(), 36) + GAP) or #looks * ROW_H
    newLook:ClearAllPoints()
    newLook:SetPoint("TOPLEFT", 0, -listH)
    newLook:SetShown(#looks < ns.MAX_LOOKS)
    palette:SetHeight(-BODY_TOP + listH + (newLook:IsShown() and 20 or 0) + PAD)
end

---------------------------------------------------------------------------
-- Picker: the drop-down list for gear sets and outfits (own frame; Blizzard menus break in combat)
---------------------------------------------------------------------------
local popup = CreateFrame("Frame", nil, palette, "BackdropTemplate")
popup:SetFrameStrata("FULLSCREEN_DIALOG")
popup:SetClampedToScreen(true)
popup:EnableMouse(true)
Skin(popup, 0.97)
popup:Hide()

local popupRows = {}

local function PopupRow(i)
    local b = CreateFrame("Button", nil, popup)
    b:SetHeight(PICK_ROW_H)
    b:SetPoint("TOPLEFT", 4, -4 - (i - 1) * PICK_ROW_H)
    b:SetPoint("RIGHT", -4, 0)
    Hover(b)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16)
    b.icon:SetPoint("LEFT", 2, 0)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.text = Text(b)
    b.text:SetPoint("LEFT", 24, 0)
    b.text:SetPoint("RIGHT", -4, 0)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    popupRows[i] = b
    return b
end

-- options = { { value, label, icon }, ... }; onPick(value) runs when one is clicked.
local function OpenPopup(anchor, options, current, onPick)
    for i, opt in ipairs(options) do
        local b = popupRows[i] or PopupRow(i)
        b.text:SetText(opt.label)
        b.text:SetTextColor(unpack(opt.value == current and GOLD or LIGHT))
        b.icon:SetTexture(opt.icon)
        b.icon:SetShown(opt.icon ~= nil)
        b:SetScript("OnClick", function()
            popup:Hide()
            onPick(opt.value)
        end)
        b:Show()
    end
    for i = #options + 1, #popupRows do popupRows[i]:Hide() end
    popup.anchor = anchor
    popup:SetSize(anchor:GetWidth(), #options * PICK_ROW_H + 8)
    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    popup:Show()
end

popup:SetScript("OnShow", function(self) self:RegisterEvent("GLOBAL_MOUSE_DOWN") end)
popup:SetScript("OnHide", function(self) self:UnregisterEvent("GLOBAL_MOUSE_DOWN") end)
popup:SetScript("OnEvent", function(self)
    if not self:IsMouseOver() and not (self.anchor and self.anchor:IsMouseOver()) then self:Hide() end
end)

---------------------------------------------------------------------------
-- Look editor
---------------------------------------------------------------------------
local editor = CreateFrame("Frame", nil, palette)
editor:SetPoint("TOPLEFT", PAD, BODY_TOP)
editor:SetPoint("BOTTOMRIGHT", -PAD, PAD)
editor:Hide()

local editing = {} -- { id, set, outfit } of the Look being edited; id is nil for a new one
local ShowEditor -- defined below

local function Label(text, anchor)
    local l = Text(editor, "GameFontNormalSmall")
    l:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -GAP - 2)
    l:SetHeight(LABEL_H)
    l:SetText(text)
    return l
end

-- A field that opens the picker: label text on the left, a down arrow on the right.
local function PickField(anchor)
    local b = TextButton(editor, "", 10)
    b:SetHeight(FIELD_H)
    b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    b:SetPoint("RIGHT", editor, "RIGHT")
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", 7, 0)
    b.text:SetPoint("RIGHT", -20, 0)
    b.text:SetJustifyH("LEFT")
    b.text:SetWordWrap(false)
    local arrow = b:CreateTexture(nil, "ARTWORK")
    arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", -4, -3)
    arrow:SetAlpha(0.7)
    return b
end

local nameBox = SingleLineBox(editor, "Name, e.g. Travelling")
nameBox:SetPoint("TOPLEFT")
nameBox:SetPoint("TOPRIGHT")
nameBox:SetMaxLetters(32)

local gearField = PickField(Label("Gear set", nameBox))
local outfitField = PickField(Label("Outfit", gearField))
local emoteLabel = Label("Emote when you change (optional)", outfitField)

local emoteBox = SingleLineBox(editor, "changes into travelling clothes.")
emoteBox:SetPoint("TOPLEFT", emoteLabel, "BOTTOMLEFT", 0, -2)
emoteBox:SetPoint("RIGHT", editor, "RIGHT")
emoteBox:SetMaxLetters(255)

local hint = Text(editor, "GameFontDisableSmall")
hint:SetPoint("TOPLEFT", emoteBox, "BOTTOMLEFT", 0, -GAP)
hint:SetPoint("RIGHT", editor, "RIGHT")
hint:SetJustifyH("LEFT")
hint:SetSpacing(2)

local HINT = "Sent as /e when you change; %t is your target's name."

local function ShowHint(msg, color)
    hint:SetText(msg or HINT)
    hint:SetTextColor(unpack(color or MUTED))
end

local function GearText()
    if not editing.set then return Colored(MUTED, "Don't change gear") end
    return ns.GearSet(editing.set) or Colored(WARN, "That set is gone, pick another")
end

local function OutfitText()
    if editing.outfit == ns.CLEAR_OUTFIT then return "No outfit (your real gear)" end
    if not editing.outfit then return Colored(MUTED, "Don't change outfit") end
    local info = ns.Outfit(editing.outfit)
    return info and info.name or Colored(WARN, "That outfit is gone, pick another")
end

local function UpdateFields()
    gearField.text:SetText(GearText())
    outfitField.text:SetText(OutfitText())
end

-- Picker values: false for "don't change" (a table can't hold nil), else what the Look stores.
gearField:SetScript("OnClick", function(self)
    if popup:IsShown() and popup.anchor == self then return popup:Hide() end
    local options = { { value = false, label = "Don't change gear" } }
    for _, set in ipairs(ns.GearSets()) do
        options[#options + 1] = { value = set.id, label = set.name, icon = set.icon }
    end
    if #options == 1 then ShowHint("No equipment sets yet. Make them in the character window's equipment manager.", GOLD) end
    OpenPopup(self, options, editing.set or false, function(v)
        editing.set = v or nil
        UpdateFields()
    end)
end)

outfitField:SetScript("OnClick", function(self)
    if popup:IsShown() and popup.anchor == self then return popup:Hide() end
    local options = {
        { value = false, label = "Don't change outfit" },
        { value = ns.CLEAR_OUTFIT, label = "No outfit (your real gear)" },
    }
    for _, info in ipairs(ns.Outfits()) do
        if not info.isDisabled then
            options[#options + 1] = { value = info.outfitID, label = info.name, icon = info.icon }
        end
    end
    if #options == 2 then ShowHint("No outfits yet. Save them at a transmogrifier.", GOLD) end
    OpenPopup(self, options, editing.outfit or false, function(v)
        editing.outfit = v or nil
        UpdateFields()
    end)
end)

local save = TextButton(editor, "Save", 60)
save:SetPoint("BOTTOMRIGHT")
local cancel = TextButton(editor, "Cancel", 60)
cancel:SetPoint("RIGHT", save, "LEFT", -GAP, 0)
local delete = TextButton(editor, "Delete", 52)
delete:SetPoint("BOTTOMLEFT")
local copy = TextButton(editor, "Copy", 52)
copy:SetPoint("LEFT", delete, "RIGHT", GAP, 0)

save:SetScript("OnClick", function()
    local name = strtrim(nameBox:GetText())
    if name == "" then return ShowHint("Give it a name.", WARN) end
    if not (editing.set or editing.outfit) then return ShowHint("Pick a gear set, an outfit, or both.", WARN) end
    ns.SaveLook(editing.id, name, editing.set, editing.outfit, strtrim(emoteBox:GetText()))
    SetMode("list")
end)
cancel:SetScript("OnClick", function() SetMode("list") end)
-- Two clicks to delete, so a stray one can't lose a Look.
delete:SetScript("OnClick", function(self)
    if not self.armed then
        self.armed = true
        self.text:SetText("Sure?")
        self.text:SetTextColor(unpack(WARN))
        return
    end
    ns.DeleteLook(editing.id)
    SetMode("list")
end)
-- Starts a new Look from the one in the editor, unsaved changes included; it's only added on Save.
local function StartCopy()
    if #EzOutfitterDB.looks >= ns.MAX_LOOKS then return end
    local name = strtrim(nameBox:GetText())
    editing = { set = editing.set, outfit = editing.outfit }
    nameBox:SetText(name ~= "" and name .. " copy" or "")
    ShowEditor()
    ShowHint("A copy. Change what you want, then Save.", GOLD)
end
copy:SetScript("OnClick", StartCopy)

for _, box in ipairs({ nameBox, emoteBox }) do
    box:SetScript("OnEscapePressed", function() SetMode("list") end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
end
nameBox:SetScript("OnTabPressed", function() emoteBox:SetFocus() end)
emoteBox:SetScript("OnTabPressed", function() nameBox:SetFocus() end)

-- Opens the editor on Look id (on a copy of it with asCopy), or on a new one started from what you're wearing.
function OpenEditor(id, asCopy)
    local look = id and ns.Look(id)
    if look then
        editing = { id = look.id, set = look.set, outfit = look.outfit }
        nameBox:SetText(look.name)
        emoteBox:SetText(look.emote or "")
    else
        local set, outfit = ns.Current()
        local info = ns.Outfit(outfit)
        editing = { set = set, outfit = outfit }
        nameBox:SetText(info and info.name or ns.GearSet(set) or "")
        emoteBox:SetText("")
    end
    ShowEditor()
    if look and asCopy then StartCopy() end
end

-- Shows the editor on what's in editing and the boxes.
function ShowEditor()
    delete:SetShown(editing.id ~= nil)
    copy:SetShown(editing.id ~= nil and #EzOutfitterDB.looks < ns.MAX_LOOKS)
    delete.armed = nil
    delete.text:SetText("Delete")
    delete.text:SetTextColor(1, 1, 1)
    ShowHint()
    UpdateFields()
    SetMode("editor")
    nameBox:SetFocus()
    nameBox:HighlightText()
end

---------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------
local options = CreateFrame("Frame", nil, palette)
options:SetPoint("TOPLEFT", PAD + 4, BODY_TOP - 4)
options:SetPoint("BOTTOMRIGHT", -PAD, PAD)
options:Hide()

local checks = {}

local function Check(label, get, set)
    local b = CreateFrame("Button", nil, options)
    b:SetHeight(20)
    b:SetPoint("TOPLEFT", 0, -#checks * 22)
    b:SetPoint("RIGHT")
    b.box = CreateFrame("Frame", nil, b, "BackdropTemplate")
    b.box:SetSize(12, 12)
    b.box:SetPoint("LEFT")
    Skin(b.box, 0.5)
    b.fill = b.box:CreateTexture(nil, "ARTWORK")
    b.fill:SetPoint("TOPLEFT", 3, -3)
    b.fill:SetPoint("BOTTOMRIGHT", -3, 3)
    b.fill:SetColorTexture(unpack(GOLD))
    b.text = Text(b)
    b.text:SetPoint("LEFT", b.box, "RIGHT", 8, 0)
    b.text:SetText(label)
    b.Update = function() b.fill:SetShown(get()) end
    b:SetScript("OnClick", function()
        set(not get())
        b.Update()
    end)
    checks[#checks + 1] = b
end

local UpdateStrip -- defined with the strip below

Check("Show the launcher icon",
    function() return not EzOutfitterDB.hideIcon end,
    function(v) EzOutfitterDB.hideIcon = not v; ns.UpdateIcon() end)
Check("Show looks beside the character window",
    function() return EzOutfitterDB.showStrip end,
    function(v) EzOutfitterDB.showStrip = v; UpdateStrip() end)
Check("Keep this palette open after changing",
    function() return EzOutfitterDB.keepOpen end,
    function(v) EzOutfitterDB.keepOpen = v end)

local notes = Text(options, "GameFontDisableSmall")
notes:SetPoint("TOPLEFT", 0, -#checks * 22 - 8)
notes:SetPoint("RIGHT", -6, 0)
notes:SetJustifyH("LEFT")
notes:SetSpacing(3)
notes:SetText(format("Key bindings: Options > Keybindings > EzOutfitter. Look 1 to %d follow the order "
    .. "of this list (Shift-right-click moves a look up).\n"
    .. "Changing outfit has a short cooldown, and most gear can't be swapped in combat.\n"
    .. "If the game switches your outfit after a look, turn off that outfit's situations at a "
    .. "transmogrifier.", ns.BINDING_COUNT))

local back = TextButton(options, "Back", 60)
back:SetPoint("BOTTOMRIGHT")
back:SetScript("OnClick", function() SetMode("list") end)

---------------------------------------------------------------------------
-- Modes, open/close
---------------------------------------------------------------------------
function SetMode(m)
    mode = m
    popup:Hide()
    list:SetShown(m == "list")
    editor:SetShown(m == "editor")
    options:SetShown(m == "options")
    title:SetText(m == "editor" and (editing.id and "Edit look" or "New look") or m == "options" and "Options" or "Looks")
    if m == "options" then
        gear.tex:SetVertexColor(unpack(GOLD))
    else
        gear.tex:SetVertexColor(unpack(WHITE_TEXT))
    end
    if m ~= "editor" then
        nameBox:ClearFocus()
        emoteBox:ClearFocus()
    end
    if m == "list" then
        LayoutList()
    elseif m == "editor" then
        palette:SetHeight(EDITOR_H)
    else
        for _, b in ipairs(checks) do b.Update() end
        palette:SetHeight(OPTIONS_H)
    end
    GameTooltip:Hide()
end

palette:SetScript("OnShow", function() SetMode("list") end)
palette:SetScript("OnHide", function()
    palette:StopMovingOrSizing()
    popup:Hide()
    nameBox:ClearFocus()
    emoteBox:ClearFocus()
    GameTooltip:Hide()
end)

local function CombatBlocked()
    if InCombatLockdown() then
        ns.Print("Your looks open again after combat.")
        return true
    end
end

function ns.TogglePalette(startMode)
    if CombatBlocked() then return end
    if palette:IsShown() and (not startMode or mode == startMode) then return palette:Hide() end
    palette:Show()
    if startMode then SetMode(startMode) end
end

function EzOutfitter_TogglePalette()
    ns.TogglePalette()
end

function ns.OpenEditor(id, asCopy)
    if CombatBlocked() then return end
    palette:Show()
    OpenEditor(id, asCopy)
end

---------------------------------------------------------------------------
-- Strip beside the character window. Placed on UIParent at the window's edge rather than
-- anchored to it: anchoring secure buttons to the window would lock it in combat too.
---------------------------------------------------------------------------
local strip = CreateFrame("Frame", "EzOutfitterStrip", UIParent)
strip:SetSize(STRIP_S, STRIP_S)
strip:Hide()

local stripButtons = {}
for i = 1, ns.STRIP_COUNT do
    local b = LookButton(strip, i)
    b:SetSize(STRIP_S, STRIP_S)
    b:SetPoint("TOPLEFT", 0, -(i - 1) * (STRIP_S + STRIP_GAP))
    b:SetBackdrop(FLAT)
    b:SetBackdropColor(0, 0, 0, 0.6)
    b.icon:SetPoint("TOPLEFT", 1, -1)
    b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    Hover(b, 0.15)
    stripButtons[i] = b
end

local stripOpen = IconButton(strip, STRIP_S, 18, OPTIONS_ICON, 12)
stripOpen:SetScript("OnClick", function() ns.TogglePalette() end)
stripOpen:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("EzOutfitter")
    GameTooltip:AddLine("Click: your looks, to add or edit them", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
stripOpen:HookScript("OnLeave", HideTooltip)

-- Arms, places and shows the strip while the character window is open. Out of combat only.
function UpdateStrip()
    if InCombatLockdown() then return end
    local frame = CharacterFrame
    if not (EzOutfitterDB.showStrip and frame and frame:IsShown() and frame:GetRight()) then
        return strip:Hide()
    end
    ArmAll(stripButtons)
    local n = math.min(#EzOutfitterDB.looks, ns.STRIP_COUNT)
    stripOpen:ClearAllPoints()
    stripOpen:SetPoint("TOPLEFT", 0, -n * (STRIP_S + STRIP_GAP))
    local ratio = frame:GetEffectiveScale() / strip:GetEffectiveScale()
    strip:ClearAllPoints()
    strip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", frame:GetRight() * ratio + 2, frame:GetTop() * ratio - 30)
    strip:Show()
end

-- The window can still be moving into place when it shows, so place the strip a frame later.
local function UpdateStripSoon()
    C_Timer.After(0, UpdateStrip)
end

---------------------------------------------------------------------------
-- Launcher icon
---------------------------------------------------------------------------
local icon = CreateFrame("Button", "EzOutfitterIcon", UIParent, "BackdropTemplate")
icon:SetSize(24, 24)
icon:SetFrameStrata("MEDIUM")
Movable(icon, "iconPos")
icon:RegisterForClicks("LeftButtonUp", "RightButtonUp")
icon:SetBackdrop(FLAT)
icon:SetBackdropColor(0, 0, 0, 0.6)
icon:SetBackdropBorderColor(0, 0, 0, 1)
icon:SetAlpha(0.7)
icon:Hide()
icon.tex = icon:CreateTexture(nil, "ARTWORK")
icon.tex:SetPoint("TOPLEFT", 1, -1)
icon.tex:SetPoint("BOTTOMRIGHT", -1, 1)
icon.tex:SetTexture(ns.ICON)
icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

icon:SetScript("OnClick", function(_, button)
    ns.TogglePalette(button == "RightButton" and "options" or nil)
end)
icon:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("EzOutfitter")
    GameTooltip:AddLine("Click: your looks", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click: options", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Drag: move", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
icon:SetScript("OnLeave", function(self)
    self:SetAlpha(0.7)
    GameTooltip:Hide()
end)

function ns.UpdateIcon()
    icon:SetShown(not EzOutfitterDB.hideIcon)
end

function ns.ApplyPositions()
    Place(icon, "iconPos", "BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", -28, 28)
    Place(palette, "palettePos", "BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 40)
end

---------------------------------------------------------------------------
-- Hooks from Core
---------------------------------------------------------------------------
function ns.InitUI()
    ns.ApplyPositions()
    ns.UpdateIcon()
    if CharacterFrame then
        CharacterFrame:HookScript("OnShow", UpdateStripSoon)
        CharacterFrame:HookScript("OnHide", UpdateStripSoon)
        CharacterFrame:HookScript("OnSizeChanged", UpdateStripSoon)
    end
end

-- Your Looks changed (and it's not combat): re-arm the visible buttons.
function ns.OnLooksChanged()
    if palette:IsShown() and mode == "list" then LayoutList() end
    UpdateStrip()
end

-- Runs paint on every Look button on screen, palette and strip.
local function PaintShown(paint)
    for _, buttons in ipairs({ rows, stripButtons }) do
        for _, b in ipairs(buttons) do
            if b:IsShown() then paint(b) end
        end
    end
end

-- Gear or outfit changed: only the highlight moves.
function ns.OnWornChanged()
    PaintShown(Paint)
end

-- The outfit cooldown started or ended: update the swipes (visual only, fine in combat).
function ns.OnCooldownChanged()
    PaintShown(PaintCooldown)
end

-- After a Look's click: the palette closes unless kept open.
function ns.OnSwapped(keepOpen)
    if palette:IsShown() and mode == "list" and not (keepOpen or EzOutfitterDB.keepOpen) then palette:Hide() end
end

-- Right-click on a Look: edit it, with Ctrl edit a copy of it, or with Shift move it up.
function ns.OnLookRightClick(look)
    if IsShiftKeyDown() then return ns.MoveLookUp(look.id) end
    ns.OpenEditor(look.id, IsControlKeyDown())
end

-- Combat starting: close what holds secure buttons while that's still allowed. Ending: bring the strip back.
function ns.OnCombat(starting)
    if starting then
        palette:Hide()
        strip:Hide()
    else
        UpdateStrip()
    end
end
