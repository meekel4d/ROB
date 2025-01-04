-- Debug mode toggle for tracking dodges
ROB.debugDodge = false  -- Set to false by default to disable debug messages
local dodgeFlag = false  -- This flag will be set to true only when a dodge occurs
ROB.dodgeProcEndTime = 0  -- Tracks the end time of the dodge proc

-- Debug print function
local function debug_dodge_print(msg)
    if ROB.debugDodge then
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] " .. msg, 1, 1, 0)
    end
end

-- General print function
local function dodge_print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 0.7, 0.9)
end

-- Function to check if a dodge proc is active
function ROB.IsDodgeActive()
    if dodgeFlag then
        local timeLeft = ROB.dodgeProcEndTime - GetTime()
        if timeLeft > 0 then
            debug_dodge_print("Dodge is active for " .. string.format("%.1f", timeLeft) .. " seconds.")
            return true
        else
            debug_dodge_print("Dodge proc expired.")
            dodgeFlag = false  -- Reset dodge flag after timer expires
            return false
        end
    else
        debug_dodge_print("No dodge proc active.")
    end
    return false
end

-- Slash command to check dodge status
SLASH_CHECKDODGE1 = "/checkdodge"
SlashCmdList["CHECKDODGE"] = function()
    if ROB.IsDodgeActive() then
        local timeLeft = ROB.dodgeProcEndTime - GetTime()
        dodge_print("Dodge is active for " .. string.format("%.1f", timeLeft) .. " seconds.")
    else
        dodge_print("No dodge proc active.")
    end
end

-- Slash command to toggle debug mode for dodges
SLASH_DODGEDEBUG1 = "/dodgedebug"
SlashCmdList["DODGEDEBUG"] = function()
    ROB.debugDodge = not ROB.debugDodge
    if ROB.debugDodge then
        dodge_print("Dodge debug mode enabled.")
    else
        dodge_print("Dodge debug mode disabled.")
    end
end

-- Event handling to detect when a dodge occurs
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
f:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
f:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")

f:SetScript("OnEvent", function()
    local message = arg1  -- Capture the message in case it's not explicitly passed

    if not message then
        debug_dodge_print("Error: arg1 (message) is nil for the current event.")
        return
    end

    local event = event -- Capture the event name explicitly for clarity
    debug_dodge_print("Event triggered: " .. event .. " with message: " .. message)

    if event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        local a, b, str = string.find(message, "You attack. (.+) dodges.")
        if a then
            dodgeFlag = true  -- Set the dodge flag to true when a dodge is detected
            ROB.dodgeProcEndTime = GetTime() + 4  -- Set proc end time to 4 seconds from now
            debug_dodge_print("Detected dodge in CHAT_MSG_COMBAT_SELF_MISSES for target: " .. str)
        else
            debug_dodge_print("No dodge found in CHAT_MSG_COMBAT_SELF_MISSES.")
        end

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" or event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
        local a, b, _, str = string.find(message, "Your (.+) was dodged by (.+).")
        if a then
            dodgeFlag = true  -- Set the dodge flag to true when a dodge is detected
            ROB.dodgeProcEndTime = GetTime() + 4  -- Set proc end time to 4 seconds from now
            debug_dodge_print("Detected dodge in " .. event .. " for spell: " .. str)
        else
            debug_dodge_print("No dodge found in " .. event .. ".")
        end
    end
end)

-- Initialize with no dodge proc
dodgeFlag = false
debug_dodge_print("Dodge tracking initialized.")
