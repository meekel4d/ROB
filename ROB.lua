-- ROB namespace setup
ROB = ROB or {}

-- Debug mode toggle for tracking energy and combo points
ROB.debugCombo = false  -- Debug toggle for combo point tracking
ROB.currentEnergy = UnitMana("player") or 0  -- Tracks the current energy value
ROB.currentComboPoints = GetComboPoints("player", "target") or 0  -- Tracks the current combo points

-- Create a shared namespace frame
ROB.frame = CreateFrame("Frame")

local function debug_energy_print(msg)
    if ROB.debugEnergy then
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] " .. msg, 1, 1, 0)
    end
end

local function energy_print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 0.5, 0.8, 1)
end

-- Slash command to toggle debug mode for energy tracking
SLASH_ENERGYDEBUG1 = "/energydebug"
SlashCmdList["ENERGYDEBUG"] = function()
    ROB.debugEnergy = not ROB.debugEnergy
    if ROB.debugEnergy then
        energy_print("Energy debug mode enabled.")
    else
        energy_print("Energy debug mode disabled.")
    end
end

-- Slash command to check the current energy value
SLASH_CHECKENERGY1 = "/checkenergy"
SlashCmdList["CHECKENERGY"] = function()
    energy_print("Current energy: " .. ROB.currentEnergy)
end

-- Function to update energy and log debug info
function ROB.UpdateEnergy()
    local newEnergy = UnitMana("player")
    debug_energy_print("Energy updated from " .. ROB.currentEnergy .. " to " .. newEnergy)
    ROB.currentEnergy = newEnergy
end

-- Event handling to track energy changes
local energyFrame = CreateFrame("Frame")
energyFrame:RegisterEvent("UNIT_ENERGY")
energyFrame:SetScript("OnEvent", function()
    -- Assume the event pertains to the player
    ROB.UpdateEnergy()
end)

-- Initialize energy at the start
ROB.UpdateEnergy()
debug_energy_print("Initial energy set to: " .. ROB.currentEnergy)

local function debug_combo_print(msg)
    if ROB.debugCombo then
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] " .. msg, 1, 1, 0)
    end
end

local function combo_print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 0.5, 0.8, 1)
end

-- Slash command to toggle debug mode for combo points
SLASH_COMBODEBUG1 = "/combodebug"
SlashCmdList["COMBODEBUG"] = function()
    ROB.debugCombo = not ROB.debugCombo
    if ROB.debugCombo then
        combo_print("Combo point debug mode enabled.")
    else
        combo_print("Combo point debug mode disabled.")
    end
end

-- Slash command to check the current combo points
SLASH_CHECKCOMBO1 = "/checkcombo"
SlashCmdList["CHECKCOMBO"] = function()
    combo_print("Current combo points: " .. ROB.currentComboPoints)
end

-- Function to check if the player has Mortal Strike or Bloodthirst talents
function ROB.HasTalent(talentName)
    -- Talent names for Mortal Strike and Bloodthirst
    local talents = {
        ["Lethality"] = {tabIndex = 1, talentIndex = 9},  -- Verify if this is correct
        ["Serrated Blades"] = {tabIndex = 3, talentIndex = 5}     -- Verify if this is correct
    }

    -- Fetch talent data
    local talentData = talents[talentName]
    if not talentData then
        return false
    end

    -- Check if the talent is trained and debug the output
    local tabIndex, talentIndex = talentData.tabIndex, talentData.talentIndex
    local name, _, _, _, rank = GetTalentInfo(tabIndex, talentIndex)
    return rank > 0
end

-- Function to update combo points and log debug info
function ROB.UpdateComboPoints()
    local newComboPoints = GetComboPoints("player", "target")
    debug_combo_print("Combo points updated from " .. ROB.currentComboPoints .. " to " .. newComboPoints)
    ROB.currentComboPoints = newComboPoints
end

-- Event handling to track combo point changes and target changes
local comboFrame = CreateFrame("Frame")
comboFrame:RegisterEvent("PLAYER_COMBO_POINTS")  -- Tracks combo point changes
comboFrame:RegisterEvent("UNIT_COMBO_POINTS")    -- Tracks combo point changes for specific units
comboFrame:RegisterEvent("PLAYER_TARGET_CHANGED")  -- Tracks when the player changes targets
comboFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_TARGET_CHANGED" then
        debug_combo_print("Target changed, updating combo points.")
    end
    -- Update combo points whenever one of these events occurs
    ROB.UpdateComboPoints()
end)

-- Initialize combo points at the start
ROB.UpdateComboPoints()
debug_combo_print("Initial combo points set to: " .. ROB.currentComboPoints)

-- Toggle state for Expose Armor rotation
ROB.exposeArmorToggled = false

-- Function to toggle Expose Armor rotation
function ROB.ToggleExposeArmor()
    ROB.exposeArmorToggled = not ROB.exposeArmorToggled
    if ROB.exposeArmorToggled then
        DEFAULT_CHAT_FRAME:AddMessage("[ROB] Expose Armor rotation toggled ON.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("[ROB] Expose Armor rotation toggled OFF.")
    end
end

-- Slash command to toggle Expose Armor rotation
SLASH_ROBEXPOSE1 = "/robexpose"
SlashCmdList["ROBEXPOSE"] = ROB.ToggleExposeArmor
