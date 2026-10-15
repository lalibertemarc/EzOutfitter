-- EzOutfitter: your gear set and your transmog outfit, changed together with one click.
local _, ns = ...

BINDING_HEADER_EZOUTFITTER = "EzOutfitter"
BINDING_NAME_EZOUTFITTER_PALETTE = "Open the looks palette"

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc69b6dEzOutfitter|r: " .. msg)
end
ns.Print = Print

local issecret = issecretvalue or function() return false end
local Outfits = C_TransmogOutfitInfo

---------------------------------------------------------------------------
-- Game data: equipment sets and transmog outfits
---------------------------------------------------------------------------
-- Name, icon and whether it's worn, for an equipment set that still exists.
function ns.GearSet(id)
    if not id then return end
    local name, icon, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(id)
    if name then return name, icon, isEquipped end
end

-- Your equipment sets, by name: { { id, name, icon, equipped }, ... }.
function ns.GearSets()
    local out = {}
    for _, id in ipairs(C_EquipmentSet.GetEquipmentSetIDs() or {}) do
        local name, icon, equipped = ns.GearSet(id)
        if name then out[#out + 1] = { id = id, name = name, icon = icon, equipped = equipped } end
    end
    table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    return out
end

-- Your transmog outfits in the game's order (TransmogOutfitEntryInfo), without the Trial of Style one.
function ns.Outfits()
    local out = {}
    if not Outfits then return out end
    for _, info in ipairs(Outfits.GetOutfitsInfo() or {}) do
        if not info.isEventOutfit then out[#out + 1] = info end
    end
    return out
end

function ns.Outfit(id)
    if not id or id == ns.CLEAR_OUTFIT then return end
    for _, info in ipairs(ns.Outfits()) do
        if info.outfitID == id then return info end
    end
end

local function ActiveOutfitID()
    local id = Outfits and Outfits.GetActiveOutfitID()
    if not issecret(id) then return id end
end

local function PlainGearShown()
    local shown = Outfits and Outfits.IsEquippedGearOutfitDisplayed()
    return not issecret(shown) and shown
end

-- What's worn right now, to start a new Look from: equipped set ID and active outfit ID (or nil).
function ns.Current()
    local setID
    for _, set in ipairs(ns.GearSets()) do
        if set.equipped then setID = set.id break end
    end
    local outfit = ActiveOutfitID()
    return setID, ns.Outfit(outfit) and outfit or nil
end

---------------------------------------------------------------------------
-- Looks: EzOutfitterDB.looks[i] = { id, name, set = setID?, setName, setItems, outfit = outfitID | CLEAR_OUTFIT | nil, emote }
-- setName and setItems remember what the set was, to find it again after it's renamed.
---------------------------------------------------------------------------
function ns.Look(id)
    for i, look in ipairs(EzOutfitterDB.looks) do
        if look.id == id then return look, i end
    end
end

local FIRST_SLOT, LAST_SLOT = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19

-- An equipment set's items as one string ("0" for empty or ignored slots), or nil.
local function SetItems(id)
    local ids = id and C_EquipmentSet.GetItemIDs(id)
    if not ids then return end
    local parts = {}
    for slot = FIRST_SLOT, LAST_SLOT do
        local item = ids[slot]
        if issecret(item) then return end
        parts[#parts + 1] = item or 0
    end
    return table.concat(parts, ",")
end

-- The equipment set a Look means now. Its ID while that set keeps its name or its items (a
-- rename); else the set with its old name; else the only set with its items; else the ID.
local function FindSet(look)
    local name = ns.GearSet(look.set)
    if name and (not look.setName or name == look.setName) then return look.set end
    if name and look.setItems and SetItems(look.set) == look.setItems then return look.set end
    local byName = look.setName and C_EquipmentSet.GetEquipmentSetID(look.setName)
    if byName and ns.GearSet(byName) then return byName end
    if look.setItems then
        local found, count = nil, 0
        for _, set in ipairs(ns.GearSets()) do
            if SetItems(set.id) == look.setItems then found, count = set.id, count + 1 end
        end
        if count == 1 then return found end
    end
    if name then return look.set end
end

-- Follows a renamed equipment set; a set that's gone keeps what's saved, in case it comes back.
local function RefreshSet(look)
    local id = look.set and FindSet(look)
    if not id then return end
    look.set, look.setName = id, ns.GearSet(id)
    look.setItems = SetItems(id) or look.setItems
end

-- Saves a Look; a new one when id is nil.
function ns.SaveLook(id, name, set, outfit, emote)
    local look = id and ns.Look(id)
    if not look then
        look = { id = EzOutfitterDB.nextId }
        EzOutfitterDB.nextId = EzOutfitterDB.nextId + 1
        table.insert(EzOutfitterDB.looks, look)
    end
    look.name, look.set, look.outfit, look.emote = name, set, outfit, emote
    look.setName, look.setItems = ns.GearSet(set), SetItems(set)
    ns.Update()
end

function ns.DeleteLook(id)
    local _, i = ns.Look(id)
    if i then table.remove(EzOutfitterDB.looks, i) end
    ns.Update()
end

-- Moves a Look one place earlier (it takes the key binding of the one before it).
function ns.MoveLookUp(id)
    local looks, _, i = EzOutfitterDB.looks, ns.Look(id)
    if i and i > 1 then
        looks[i], looks[i - 1] = looks[i - 1], looks[i]
        ns.Update()
    end
end

-- Gear and outfit as text, and whether each is gone from the game: gear, gearMissing, outfit, outfitMissing.
function ns.Describe(look)
    local gear, gearMissing, outfit, outfitMissing
    if look.set then
        gear = ns.GearSet(look.set)
        gearMissing = gear == nil
    end
    if look.outfit == ns.CLEAR_OUTFIT then
        outfit = "no outfit"
    elseif look.outfit then
        local info = ns.Outfit(look.outfit)
        outfit = info and info.name
        outfitMissing = info == nil or info.isDisabled
    end
    return gear, gearMissing, outfit, outfitMissing
end

function ns.LookIcon(look)
    local info = ns.Outfit(look.outfit)
    if info then return info.icon end
    local _, icon = ns.GearSet(look.set)
    return icon or ns.ICON
end

-- True when you're wearing the Look's set and showing its outfit.
function ns.IsActive(look)
    if look.set and not select(3, ns.GearSet(look.set)) then return false end
    if look.outfit == ns.CLEAR_OUTFIT then
        if not PlainGearShown() then return false end
    elseif look.outfit and ActiveOutfitID() ~= look.outfit then
        return false
    end
    return look.set ~= nil or look.outfit ~= nil
end

-- Forever has no /outfit chat command, but its secure buttons know an "outfit" action. This
-- hidden button holds one per outfit slot, picked by a made-up mouse button: /click
-- EzOutfitterOutfit #3 reads "type-#3", "outfit-index-#3" and "action-#3". "change" keeps the
-- outfit on if it's already shown ("toggle" would take it off); "clear" shows your real gear.
-- Slot numbers don't move when outfits are renamed, so these are set once and never in combat.
-- Here and on the Look buttons, "*" makes an attribute count with Shift/Ctrl/Alt held too: a
-- plain "type1" is only read for an unmodified click.
local outfitButton = CreateFrame("Button", "EzOutfitterOutfit", UIParent, "SecureActionButtonTemplate")
outfitButton:SetAttribute("useOnKeyDown", false)
outfitButton:RegisterForClicks("AnyUp", "AnyDown")

-- Points key at outfit slot index, or at "no outfit" when index is nil.
local function SetOutfitKey(key, index)
    outfitButton:SetAttribute("*type-" .. key, "outfit")
    outfitButton:SetAttribute("*outfit-index-" .. key, index)
    outfitButton:SetAttribute("*action-" .. key, index and "change" or "clear")
end

SetOutfitKey("#clear")
for i = 0, ns.MAX_OUTFIT_INDEX do SetOutfitKey("#" .. i, i) end

-- Slot number of a Look's usable outfit, or nil.
local function OutfitIndex(look)
    local info = ns.Outfit(look.outfit)
    if info and not info.isDisabled and info.playerFacingOutfitIndex <= ns.MAX_OUTFIT_INDEX then
        return info.playerFacingOutfitIndex
    end
end

-- The secure macro that puts a Look on: the game's own /equipset, then the outfit button.
function ns.Macro(look)
    local lines = {}
    local setName = ns.GearSet(look.set)
    if setName then lines[#lines + 1] = "/equipset " .. setName end
    local index = OutfitIndex(look)
    if look.outfit == ns.CLEAR_OUTFIT then
        lines[#lines + 1] = "/click EzOutfitterOutfit #clear"
    elseif index then
        lines[#lines + 1] = "/click EzOutfitterOutfit #" .. index
    end
    if #lines > 0 then return table.concat(lines, "\n") end
end

---------------------------------------------------------------------------
-- Outfit cooldown: putting an outfit on (or taking it off) casts a spell with a cooldown
---------------------------------------------------------------------------
local OUTFIT_CONSTS = Constants and Constants.TransmogOutfitDataConsts or {}
local OUTFIT_SPELLS = {
    OUTFIT_CONSTS.EQUIP_TRANSMOG_OUTFIT_MANUAL_SPELL_ID or 1247613,
    OUTFIT_CONSTS.CLEAR_TRANSMOG_OUTFIT_MANUAL_SPELL_ID or 1247917,
}
local GCD = 1.5 -- cooldowns this short are the global cooldown, not the outfit's own

-- Seconds before look can be worn (0 when ready, or when it leaves your outfit alone), and the
-- cooldown's start and duration for a swipe. 0 too when the game hides the numbers (cooldowns
-- are secret in combat).
function ns.OutfitWait(look)
    if look.outfit == nil then return 0 end
    local endsAt, start, duration = 0
    for _, id in ipairs(OUTFIT_SPELLS) do
        local cd = C_Spell.GetSpellCooldown(id)
        if cd and cd.isActive and not issecret(cd.startTime) and not issecret(cd.duration)
            and cd.duration > GCD and cd.startTime + cd.duration > endsAt then
            endsAt, start, duration = cd.startTime + cd.duration, cd.startTime, cd.duration
        end
    end
    return math.max(0, endsAt - GetTime()), start, duration
end

---------------------------------------------------------------------------
-- The /e line
---------------------------------------------------------------------------
local function TargetName()
    local name = UnitExists("target") and UnitName("target")
    if name and not issecret(name) then return name end
end

-- Encounters and similar lock addon chat; sending then would be blocked.
local function ChatLocked()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

-- Sent from the click or key press itself: the game only lets addons send chat text then.
local EMOTE_COMMANDS = { e = true, me = true, emote = true }

local function Announce(look)
    local text = strtrim(look.emote or "")
    local cmd, rest = text:match("^/(%a+)%s+(.*)$")
    if cmd and EMOTE_COMMANDS[cmd:lower()] then text = rest end
    if text == "" or ChatLocked() then return end
    text = text:gsub("%%t", function() return TargetName() or "someone" end)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(text, "EMOTE")
    else
        SendChatMessage(text, "EMOTE")
    end
end

local function WarnMissing(look)
    local _, gearMissing, _, outfitMissing = ns.Describe(look)
    if gearMissing then Print(format("%s: its equipment set is gone. Pick another one.", look.name)) end
    if outfitMissing then Print(format("%s: its outfit is gone or locked. Pick another one.", look.name)) end
end

-- Runs after a Look's secure macro: the /e line, warnings, and the palette closes.
function ns.AfterSwap(look, keepOpen)
    WarnMissing(look)
    Announce(look)
    if ns.OnSwapped then ns.OnSwapped(keepOpen) end
end

-- PreClick of every Look button: while the outfit is on cooldown, hold the whole Look rather
-- than change only the gear. Out of combat the macro can be emptied for this one click (the
-- secure click reads it after PreClick); in combat it can't, so only the message stays.
local function OnLookPreClick(self, button, down)
    local look = self.look
    self.wait = nil
    if not look or down or button == "RightButton" then return end
    local wait = ns.OutfitWait(look)
    if wait <= 0 then return end
    self.wait = wait
    if not InCombatLockdown() then self:SetAttribute("*macrotext1", nil) end
end

-- PostClick of every Look button (keys, palette rows, strip): the macro has just run. Key
-- bindings click on press and on release; the macro runs on the release (useOnKeyDown is off).
function ns.OnLookClick(self, button, down)
    local look = self.look
    if not look or down then return end
    if button == "RightButton" then
        if ns.OnLookRightClick then ns.OnLookRightClick(look) end
        return
    end
    if self.wait then
        UIErrorsFrame:AddMessage(format("%s: your outfit can change again in %d s.", look.name, math.ceil(self.wait)),
            1, 0.1, 0.1)
        self.wait = nil
        if not InCombatLockdown() then ns.ArmButton(self, look) end
        return
    end
    ns.AfterSwap(look, IsShiftKeyDown())
end

---------------------------------------------------------------------------
-- Secure Look buttons. A Look needs a secure click: changing outfit casts a spell. Attributes
-- can't change in combat, so updates made then wait for it to end.
---------------------------------------------------------------------------
function ns.NewLookButton(name, parent, extraTemplate)
    local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate" .. (extraTemplate and "," .. extraTemplate or ""))
    -- Act on release for keys too, like a mouse click: the PostClick below ignores the press.
    b:SetAttribute("useOnKeyDown", false)
    b:SetAttribute("*type1", "macro")
    b:SetScript("PreClick", OnLookPreClick)
    b:SetScript("PostClick", ns.OnLookClick)
    return b
end

-- Points button at look (or nothing). Out of combat only.
function ns.ArmButton(b, look)
    b.look = look
    b:SetAttribute("*macrotext1", look and ns.Macro(look) or nil)
end

-- Hidden buttons behind the Look 1..N key bindings. They don't work from your own macros:
-- they run macrotext, and a macro can't start another macro.
local keyButtons = {}
for i = 1, ns.BINDING_COUNT do
    local b = ns.NewLookButton("EzOutfitterLook" .. i, UIParent)
    b:RegisterForClicks("AnyUp", "AnyDown")
    keyButtons[i] = b
end

function ns.BindingAction(i)
    return "CLICK EzOutfitterLook" .. i .. ":LeftButton"
end

-- Names the Look bindings after your Looks, so Options > Keybindings shows "Look 2: Travelling".
local function UpdateBindingNames()
    for i = 1, ns.BINDING_COUNT do
        local look = EzOutfitterDB and EzOutfitterDB.looks[i]
        _G["BINDING_NAME_" .. ns.BindingAction(i)] = look and format("Look %d: %s", i, look.name) or format("Look %d", i)
    end
end
UpdateBindingNames()

local pending -- an update waiting for combat to end

-- Rebuilds every secure Look button from EzOutfitterDB and tells the UI.
function ns.Update()
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = false
    for _, look in ipairs(EzOutfitterDB.looks) do RefreshSet(look) end
    for i, b in ipairs(keyButtons) do ns.ArmButton(b, EzOutfitterDB.looks[i]) end
    UpdateBindingNames()
    if ns.OnLooksChanged then ns.OnLooksChanged() end
end

---------------------------------------------------------------------------
-- Saved variables (per character: equipment sets and outfits are)
---------------------------------------------------------------------------
local function InitDB()
    EzOutfitterDB = EzOutfitterDB or {}
    local db = EzOutfitterDB
    for k, v in pairs(ns.DEFAULTS) do
        if db[k] == nil then db[k] = v end
    end
    db.looks = db.looks or {}
    db.nextId = db.nextId or #db.looks + 1
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local HELP = {
    "/eo - open or close your looks",
    "/eo new - make a look from what you're wearing",
    "/eo icon - show or hide the launcher icon",
    "/eo reset - reset the icon and palette positions",
    "Key bindings: Options > Keybindings > EzOutfitter",
}

local COMMANDS = {
    [""]  = function() ns.TogglePalette() end,
    new   = function() ns.OpenEditor() end,
    icon  = function()
        EzOutfitterDB.hideIcon = not EzOutfitterDB.hideIcon
        ns.UpdateIcon()
        Print(EzOutfitterDB.hideIcon and "Icon hidden. Use the key binding or /eo." or "Icon shown.")
    end,
    reset = function()
        EzOutfitterDB.iconPos, EzOutfitterDB.palettePos = nil, nil
        ns.ApplyPositions()
        Print("Positions reset.")
    end,
    help  = function()
        for _, line in ipairs(HELP) do Print(line) end
    end,
    -- What each Look's buttons will run, and what the game says about outfits.
    debug = function()
        local function Flat(text) return text and text:gsub("\n", " ; ") or "|cffff5555none|r" end
        Print(format("Outfit API: %s, transmog enabled: %s, outfits: %d, active: %s",
            tostring(Outfits ~= nil),
            tostring(Outfits and Outfits.IsTransmogEnabled and Outfits.IsTransmogEnabled()), #ns.Outfits(),
            tostring(ActiveOutfitID())))
        Print(format("%d looks, %d gear sets, combat update pending: %s",
            #EzOutfitterDB.looks, #ns.GearSets(), tostring(pending)))
        for i, look in ipairs(EzOutfitterDB.looks) do
            local info = ns.Outfit(look.outfit)
            Print(format("%d. %s | set %s = %s (saved as %s) | outfit %s = %s (index %s, disabled %s)",
                i, look.name, tostring(look.set), tostring(ns.GearSet(look.set)), tostring(look.setName),
                tostring(look.outfit),
                tostring(info and info.name), tostring(info and info.playerFacingOutfitIndex),
                tostring(info and info.isDisabled)))
            Print(format("   palette macro: %s | key: %s", Flat(ns.Macro(look)),
                Flat(keyButtons[i] and keyButtons[i]:GetAttribute("*macrotext1"))))
        end
    end,
}

SLASH_EZOUTFITTER1 = "/eo"
SLASH_EZOUTFITTER2 = "/ezoutfitter"
SlashCmdList.EZOUTFITTER = function(msg)
    msg = strtrim(msg or "")
    local fn = COMMANDS[msg:lower()]
    if fn then return fn() end
    COMMANDS.help()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ready -- set at login; equipment and combat events can come earlier

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        ready = true
        InitDB()
        ns.InitUI()
        ns.Update()
    elseif not ready then
        return
    elseif event == "EQUIPMENT_SETS_CHANGED" or event == "TRANSMOG_OUTFITS_CHANGED" then
        -- A rename changes the macros. Again a moment later, in case the new name lands after the event.
        ns.Update()
        C_Timer.After(1, ns.Update)
    elseif event == "PLAYER_REGEN_DISABLED" then
        if ns.OnCombat then ns.OnCombat(true) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pending then ns.Update() end
        if ns.OnCombat then ns.OnCombat(false) end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if ns.OnCooldownChanged then ns.OnCooldownChanged() end
    elseif ns.OnWornChanged then
        ns.OnWornChanged()
    end
end)
for _, event in ipairs({
    "PLAYER_LOGIN", "EQUIPMENT_SETS_CHANGED", "TRANSMOG_OUTFITS_CHANGED", "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED", "EQUIPMENT_SWAP_FINISHED", "PLAYER_EQUIPMENT_CHANGED", "TRANSMOG_DISPLAYED_OUTFIT_CHANGED",
    "SPELL_UPDATE_COOLDOWN",
}) do
    ev:RegisterEvent(event)
end
