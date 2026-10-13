-- EzOutfitter static data: limits, defaults and colors.
local _, ns = ...

ns.ICON = "Interface\\Icons\\INV_Chest_Cloth_17"

-- Looks you can save, how many get a key binding (Bindings.xml lists that many), and how many
-- sit in the strip beside the character window.
ns.MAX_LOOKS = 20
ns.BINDING_COUNT = 10
ns.STRIP_COUNT = 10

-- A Look's outfit field: nil leaves your outfit alone, CLEAR_OUTFIT takes it off (shows your
-- real gear), any other number is a transmog outfitID.
ns.CLEAR_OUTFIT = 0

-- Highest outfit slot number (playerFacingOutfitIndex) the outfit button is set up for.
ns.MAX_OUTFIT_INDEX = 50

ns.DEFAULTS = {
    hideIcon = false,
    showStrip = true,
    keepOpen = false,
}

ns.COLORS = {
    gold   = { 1, 0.82, 0.3 },
    active = { 0.35, 0.85, 0.45 },
    muted  = { 0.55, 0.55, 0.55 },
    warn   = { 1, 0.45, 0.35 },
}
