std = "lua51"
max_line_length = false
self = false

globals = {
    "EzOutfitterDB",
    "SLASH_EZOUTFITTER1",
    "SLASH_EZOUTFITTER2",
    "SlashCmdList",
    "BINDING_HEADER_EZOUTFITTER",
    "BINDING_NAME_EZOUTFITTER_PALETTE",
    "_G",
    "EzOutfitter_TogglePalette",
}

read_globals = {
    -- Lua / WoW utility
    "format", "strtrim", "tinsert",
    -- Frames & UI
    "CreateFrame", "UIParent", "UISpecialFrames", "UIErrorsFrame", "GameTooltip", "DEFAULT_CHAT_FRAME", "ChatFrame1", "CharacterFrame",
    -- Namespaced APIs
    "C_EquipmentSet", "C_TransmogOutfitInfo", "C_ChatInfo", "C_Spell", "C_Timer", "issecretvalue", "Constants",
    -- Global APIs
    "SendChatMessage", "UnitExists", "UnitName", "InCombatLockdown", "IsShiftKeyDown", "GetTime",
    "GetBindingKey", "GetBindingText",
    "INVSLOT_FIRST_EQUIPPED", "INVSLOT_LAST_EQUIPPED",
}
