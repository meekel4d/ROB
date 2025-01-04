-- ROB namespace setup
ROB = ROB or {}

-- Debug mode toggle
ROB.debugMode = false

-- Function for debug prints
local function debug_print(msg)
    if ROB.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("[DEBUG] " .. msg, 1, 1, 0)
    end
end

-- Buffs and abilities
ROB.SLICE_AND_DICE_TEXTURE = "Interface\\Icons\\Ability_Rogue_SliceDice"
ROB.SURPRISE_ATTACK_TEXTURE = "Interface\\Icons\\Ability_Rogue_SurpriseAttack"
ROB.ADRENALINE_RUSH_SPELL_ID = 13750
ROB.BLADE_FLURRY_SPELL_ID = 13877
ROB.adrenalineRushToggled = false -- Default state for Adrenaline Rush toggle
ROB.bladeFlurryToggled = false -- Default state for Blade Flurry toggle

-- Function to toggle debug mode
SLASH_ROBDEBUG1 = "/robdebug"
SlashCmdList["ROBDEBUG"] = function()
    ROB.debugMode = not ROB.debugMode
    if ROB.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("[ROB] Debug mode enabled.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("[ROB] Debug mode disabled.")
    end
end

-- Function to toggle Adrenaline Rush usage
function ROB.Adrenalinerush()
    ROB.adrenalineRushToggled = not ROB.adrenalineRushToggled
    if ROB.adrenalineRushToggled then
        debug_print("Adrenaline Rush toggled ON.")
    else
        debug_print("Adrenaline Rush toggled OFF.")
    end
end

-- Slash command to toggle Adrenaline Rush
SLASH_ROBARUSH1 = "/robarush"
SlashCmdList["ROBARUSH"] = ROB.Adrenalinerush

-- Function to toggle Blade Flurry usage
function ROB.BladeFlurry()
    ROB.bladeFlurryToggled = not ROB.bladeFlurryToggled
    if ROB.bladeFlurryToggled then
        debug_print("Blade Flurry toggled ON.")
    else
        debug_print("Blade Flurry toggled OFF.")
    end
end

-- Slash command to toggle Blade Flurry
SLASH_ROBBF1 = "/robbf"
SlashCmdList["ROBBF"] = ROB.BladeFlurry

-- Function to check if Slice and Dice is active and get its remaining time
function ROB.GetSliceAndDiceTimeLeft()
    for i = 0, 31 do
        local id, cancel = GetPlayerBuff(i, "HELPFUL|HARMFUL|PASSIVE")
        if id > -1 then
            local texture = GetPlayerBuffTexture(id)
            if texture == ROB.SLICE_AND_DICE_TEXTURE then
                local timeLeft = GetPlayerBuffTimeLeft(id)
                return timeLeft
            end
        end
    end
    return nil
end

-- Function to check if Surprise Attack is queued
function ROB.IsSurpriseAttackQueued()
    local slot = ROB.FindActionSlotByTexture(ROB.SURPRISE_ATTACK_TEXTURE)
    if slot then
        local isQueued = IsCurrentAction(slot) == 1
        debug_print("Is Surprise Attack queued: " .. tostring(isQueued))
        return isQueued
    else
        debug_print("Surprise Attack not found on action bar.")
        return false
    end
end

-- Function to check if a spell is off cooldown
function ROB.IsSpellOffCooldown(spellID)
    local start, duration, _ = ROB.GetSpellCooldownById(spellID)
    local cooldown = (start + duration) - GetTime()
    return cooldown <= 0
end

-- Function to handle Blade Flurry in the rotation
function ROB.HandleBladeFlurry()
    if not ROB.bladeFlurryToggled then
        debug_print("Blade Flurry is toggled OFF, skipping.")
        return
    end

    local timeLeft = ROB.GetSliceAndDiceTimeLeft()
    if not timeLeft then
        debug_print("Slice and Dice is not active, skipping Blade Flurry.")
        return
    end

    if ROB.IsSpellOffCooldown(ROB.BLADE_FLURRY_SPELL_ID) then
        local energy = UnitMana("player")
        if energy >= 25 then
            if ROB.adrenalineRushToggled and ROB.IsSpellOffCooldown(ROB.ADRENALINE_RUSH_SPELL_ID) then
                debug_print("Waiting for Adrenaline Rush before using Blade Flurry.")
                return
            end
            CastSpellByName("Blade Flurry")
            debug_print("Casting Blade Flurry.")
        else
            debug_print("Not enough energy to cast Blade Flurry.")
        end
    else
        debug_print("Blade Flurry is on cooldown.")
    end
end

-- Function to handle Adrenaline Rush
function ROB.HandleAdrenalineRush()
    if not ROB.adrenalineRushToggled then
        debug_print("Adrenaline Rush is toggled OFF, skipping.")
        return
    end

    -- Check if Slice and Dice is active
    local timeLeft = ROB.GetSliceAndDiceTimeLeft()
    if not timeLeft then
        debug_print("Slice and Dice is not active, skipping Adrenaline Rush.")
        return
    end

    -- Get Adrenaline Rush cooldown
    local arStart, arDuration, _ = ROB.GetSpellCooldownById(ROB.ADRENALINE_RUSH_SPELL_ID)
    local arCooldown = (arStart + arDuration) - GetTime()

    -- Sanity check for cooldown values
    if arCooldown < 0 then arCooldown = 0 end

    if arCooldown == 0 then
        CastSpellByName("Adrenaline Rush")
        debug_print("Casting Adrenaline Rush.")
    else
        debug_print("Adrenaline Rush is on cooldown for " .. string.format("%.1f", arCooldown) .. " seconds.")
    end
end

function ROB.HandleRotation()
    local comboPoints = GetComboPoints("player", "target")
    local timeLeft = ROB.GetSliceAndDiceTimeLeft()
    local energy = UnitMana("player")
    local targetHealth = UnitHealth("target")
    local targetHealthMax = UnitHealthMax("target")
    local targetHealthPercent = (targetHealth / targetHealthMax) * 100
    local isBoss = UnitClassification("target") == "worldboss" -- Check if the target is a boss

    -- Prioritize Adrenaline Rush
    ROB.HandleAdrenalineRush()

    -- Prioritize Blade Flurry
    ROB.HandleBladeFlurry()

    -- Prioritize Surprise Attack
    if ROB.IsDodgeActive() and comboPoints < 5 and energy >= 10 then
        if not ROB.IsSurpriseAttackQueued() then
            if timeLeft and timeLeft <= 3 and energy < 35 then
                debug_print("Not queuing Surprise Attack due to Slice and Dice refresh priority.")
            else
                CastSpellByName("Surprise Attack")
                debug_print("Queuing Surprise Attack.")
                return
            end
        else
            debug_print("Surprise Attack already queued.")
        end
    end

    -- Handle Slice and Dice and Eviscerate
    if comboPoints == 5 and energy >= 35 then
        CastSpellByName("Eviscerate")
        debug_print("Casting Eviscerate (5 combo points).")
        return
    end

    -- Adjust Slice and Dice logic based on health thresholds
    local canCastSliceAndDice = true
    if isBoss and targetHealthPercent <= 10 then
        canCastSliceAndDice = false
        debug_print("Skipping Slice and Dice (target is a boss and health is <= 10%).")
    elseif not isBoss and targetHealthPercent <= 20 then
        canCastSliceAndDice = false
        debug_print("Skipping Slice and Dice (non-boss target and health is <= 20%).")
    end

    -- Handle Slice and Dice
    if not timeLeft and canCastSliceAndDice then
        if comboPoints >= 3 then
            if ROB.IsSurpriseAttackQueued() then
                -- Require 35 energy if Surprise Attack is queued
                if energy >= 35 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Casting Slice and Dice (not active, Surprise Attack queued).")
                else
                    debug_print("Not enough energy to cast Slice and Dice (Surprise Attack queued).")
                end
            else
                -- Require 25 energy if Surprise Attack is not queued
                if energy >= 25 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Casting Slice and Dice (not active, Surprise Attack not queued).")
                else
                    debug_print("Not enough energy to cast Slice and Dice.")
                end
            end
        end
    elseif timeLeft and timeLeft <= 2 and canCastSliceAndDice then
        if energy >= 65 then
            CastSpellByName("Sinister Strike")
            debug_print("Casting Sinister Strike before refreshing Slice and Dice.")
            if comboPoints >= 3 then
                if ROB.IsSurpriseAttackQueued() then
                    if energy >= 35 then
                        CastSpellByName("Slice and Dice")
                        debug_print("Refreshing Slice and Dice (Surprise Attack queued).")
                    else
                        debug_print("Not enough energy to refresh Slice and Dice (Surprise Attack queued).")
                    end
                else
                    CastSpellByName("Slice and Dice")
                    debug_print("Refreshing Slice and Dice (Surprise Attack not queued).")
                end
            end
        elseif energy >= 25 and comboPoints >= 3 then
            if ROB.IsSurpriseAttackQueued() then
                if energy >= 35 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Refreshing Slice and Dice (Surprise Attack queued).")
                else
                    debug_print("Not enough energy to refresh Slice and Dice (Surprise Attack queued).")
                end
            else
                CastSpellByName("Slice and Dice")
                debug_print("Refreshing Slice and Dice (Surprise Attack not queued).")
            end
        end
    end

    -- Handle Sinister Strike if Slice and Dice is skipped or not needed
    if not canCastSliceAndDice or (not timeLeft and comboPoints < 2) then
        if energy >= 40 then
            -- Continue building combo points with Sinister Strike
            if ROB.IsSurpriseAttackQueued() then
                if comboPoints == 4 then
                    debug_print("Not using Sinister Strike to avoid wasting combo points (Surprise Attack queued).")
                elseif energy < 50 then
                    debug_print("Not using Sinister Strike to preserve energy for Surprise Attack.")
                else
                    CastSpellByName("Sinister Strike")
                    debug_print("Casting Sinister Strike (Slice and Dice skipped).")
                end
            else
                CastSpellByName("Sinister Strike")
                debug_print("Casting Sinister Strike (Slice and Dice skipped).")
            end
        else
            debug_print("Not enough energy to cast Sinister Strike.")
        end
        return
    end

    -- Fallback: Build combo points with Sinister Strike if nothing else applies
    if energy >= 40 and comboPoints < 5 then
        CastSpellByName("Sinister Strike")
        debug_print("Fallback: Casting Sinister Strike to build combo points.")
    else
        debug_print("Fallback: Not enough energy to cast Sinister Strike.")
    end
end


function ROB.HandleRotationRupture()
    local comboPoints = GetComboPoints("player", "target")
    local timeLeft = ROB.GetSliceAndDiceTimeLeft()
    local energy = UnitMana("player")
    local targetHealth = UnitHealth("target")
    local targetHealthMax = UnitHealthMax("target")
    local targetHealthPercent = (targetHealth / targetHealthMax) * 100
    local isBoss = UnitClassification("target") == "worldboss" -- Check if the target is a boss

    -- Prioritize Adrenaline Rush
    ROB.HandleAdrenalineRush()

    -- Prioritize Blade Flurry
    ROB.HandleBladeFlurry()

    -- Prioritize Surprise Attack
    if ROB.IsDodgeActive() and comboPoints < 5 and energy >= 10 then
        if not ROB.IsSurpriseAttackQueued() then
            if timeLeft and timeLeft <= 3 and energy < 35 then
                debug_print("Not queuing Surprise Attack due to Slice and Dice refresh priority.")
            else
                CastSpellByName("Surprise Attack")
                debug_print("Queuing Surprise Attack.")
                return
            end
        else
            debug_print("Surprise Attack already queued.")
        end
    end

    -- Handle Slice and Dice and Rupture/Eviscerate logic
    if comboPoints == 5 then
        if targetHealthPercent <= 10 and isBoss and energy >= 35 then
            -- Use Eviscerate if the mob's HP is ≤ 10% and it's a boss
            CastSpellByName("Eviscerate")
            debug_print("Casting Eviscerate (target HP ≤ 10%, boss).")
        elseif targetHealthPercent <= 20 and not isBoss and energy >= 35 then
            -- Use Eviscerate if the mob's HP is ≤ 20% and it's not a boss
            CastSpellByName("Eviscerate")
            debug_print("Casting Eviscerate (target HP ≤ 20%, non-boss).")
        elseif energy >= 25 then
            -- Use Rupture otherwise
            CastSpellByName("Rupture")
            debug_print("Casting Rupture (5 combo points).")
        else
            debug_print("Not enough energy to cast Rupture or Eviscerate.")
        end
        return
    end

    -- Slice and Dice logic
    if not timeLeft then
        -- Check target health conditions
        if isBoss and targetHealthPercent <= 10 then
            debug_print("Skipping Slice and Dice (target is a boss and health is ≤ 10%).")
            return
        elseif not isBoss and targetHealthPercent <= 20 then
            debug_print("Skipping Slice and Dice (non-boss target and health is ≤ 20%).")
            return
        end

        -- Slice and Dice is not active
        if comboPoints >= 2 then
            if ROB.IsSurpriseAttackQueued() then
                -- Require 35 energy if Surprise Attack is queued
                if energy >= 35 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Casting Slice and Dice (not active, Surprise Attack queued).")
                else
                    debug_print("Not enough energy to cast Slice and Dice (Surprise Attack queued).")
                end
            else
                -- Require 25 energy if Surprise Attack is not queued
                if energy >= 25 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Casting Slice and Dice (not active, Surprise Attack not queued).")
                else
                    debug_print("Not enough energy to cast Slice and Dice.")
                end
            end
        elseif energy >= 40 then
            -- Build combo points with Sinister Strike
            if ROB.IsSurpriseAttackQueued() then
                if comboPoints == 4 then
                    debug_print("Not using Sinister Strike to avoid wasting combo points (Surprise Attack queued).")
                elseif energy < 50 then
                    debug_print("Not using Sinister Strike to preserve energy for Surprise Attack.")
                else
                    CastSpellByName("Sinister Strike")
                    debug_print("Casting Sinister Strike to build combo points.")
                end
            else
                CastSpellByName("Sinister Strike")
                debug_print("Casting Sinister Strike to build combo points.")
            end
        else
            debug_print("Not enough energy to cast Sinister Strike.")
        end
    else
        -- Slice and Dice is active
        if timeLeft <= 2 then
            if energy >= 65 then
                CastSpellByName("Sinister Strike")
                debug_print("Casting Sinister Strike before refreshing Slice and Dice.")
                if comboPoints >= 3 then
                    if ROB.IsSurpriseAttackQueued() then
                        -- Require 35 energy if Surprise Attack is queued
                        if energy >= 35 then
                            CastSpellByName("Slice and Dice")
                            debug_print("Refreshing Slice and Dice (Surprise Attack queued).")
                        else
                            debug_print("Not enough energy to refresh Slice and Dice (Surprise Attack queued).")
                        end
                    else
                        -- Require 25 energy if Surprise Attack is not queued
                        CastSpellByName("Slice and Dice")
                        debug_print("Refreshing Slice and Dice (Surprise Attack not queued).")
                    end
                end
            elseif energy >= 25 then
                if comboPoints >= 3 then
                    if ROB.IsSurpriseAttackQueued() then
                        -- Require 35 energy if Surprise Attack is queued
                        if energy >= 35 then
                            CastSpellByName("Slice and Dice")
                            debug_print("Refreshing Slice and Dice (Surprise Attack queued).")
                        else
                            debug_print("Not enough energy to refresh Slice and Dice (Surprise Attack queued).")
                        end
                    else
                        -- Require 25 energy if Surprise Attack is not queued
                        CastSpellByName("Slice and Dice")
                        debug_print("Refreshing Slice and Dice (Surprise Attack not queued).")
                    end
                else
                    debug_print("Not enough combo points to refresh Slice and Dice.")
                end
            else
                debug_print("Waiting for energy to refresh Slice and Dice.")
            end
        elseif energy >= 40 then
            -- Build combo points with Sinister Strike
            if ROB.IsSurpriseAttackQueued() then
                if comboPoints == 4 then
                    debug_print("Not using Sinister Strike to avoid wasting combo points (Surprise Attack queued).")
                elseif energy < 50 then
                    debug_print("Not using Sinister Strike to preserve energy for Surprise Attack.")
                else
                    CastSpellByName("Sinister Strike")
                    debug_print("Casting Sinister Strike (Slice and Dice active).")
                end
            else
                CastSpellByName("Sinister Strike")
                debug_print("Casting Sinister Strike (Slice and Dice active).")
            end
        else
            debug_print("Not enough energy to cast Sinister Strike.")
        end
    end
end

function ROB.RotationExpose()
    local comboPoints = GetComboPoints("player", "target")
    local timeLeft = ROB.GetSliceAndDiceTimeLeft()
    local energy = UnitMana("player")
    local targetHealth = UnitHealth("target")
    local targetHealthMax = UnitHealthMax("target")
    local targetHealthPercent = (targetHealth / targetHealthMax) * 100
    local isBoss = UnitClassification("target") == "worldboss" -- Check if the target is a boss

    -- Prioritize Adrenaline Rush
    ROB.HandleAdrenalineRush()

    -- Prioritize Blade Flurry
    ROB.HandleBladeFlurry()

    -- Prioritize Surprise Attack
    if ROB.IsDodgeActive() and comboPoints < 5 and energy >= 10 then
        if not ROB.IsSurpriseAttackQueued() then
            if timeLeft and timeLeft <= 3 and energy < 35 then
                debug_print("Not queuing Surprise Attack due to Slice and Dice refresh priority.")
            else
                CastSpellByName("Surprise Attack")
                debug_print("Queuing Surprise Attack.")
                return
            end
        else
            debug_print("Surprise Attack already queued.")
        end
    end

    -- Handle Slice and Dice logic
    local canCastSliceAndDice = true
    if isBoss and targetHealthPercent <= 10 then
        canCastSliceAndDice = false
        debug_print("Skipping Slice and Dice (target is a boss and health is <= 10%).")
    elseif not isBoss and targetHealthPercent <= 20 then
        canCastSliceAndDice = false
        debug_print("Skipping Slice and Dice (non-boss target and health is <= 20%).")
    end

    if not timeLeft and canCastSliceAndDice then
        if comboPoints >= 2 then
            if ROB.IsSurpriseAttackQueued() then
                if energy >= 35 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Casting Slice and Dice (not active, Surprise Attack queued).")
                else
                    debug_print("Not enough energy to cast Slice and Dice (Surprise Attack queued).")
                end
            else
                if energy >= 25 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Casting Slice and Dice (not active, Surprise Attack not queued).")
                else
                    debug_print("Not enough energy to cast Slice and Dice.")
                end
            end
        end
    elseif timeLeft and timeLeft <= 2 and canCastSliceAndDice then
        if energy >= 65 then
            CastSpellByName("Sinister Strike")
            debug_print("Casting Sinister Strike before refreshing Slice and Dice.")
            if comboPoints >= 3 then
                if ROB.IsSurpriseAttackQueued() then
                    if energy >= 35 then
                        CastSpellByName("Slice and Dice")
                        debug_print("Refreshing Slice and Dice (Surprise Attack queued).")
                    else
                        debug_print("Not enough energy to refresh Slice and Dice (Surprise Attack queued).")
                    end
                else
                    CastSpellByName("Slice and Dice")
                    debug_print("Refreshing Slice and Dice (Surprise Attack not queued).")
                end
            end
        elseif energy >= 25 and comboPoints >= 3 then
            if ROB.IsSurpriseAttackQueued() then
                if energy >= 35 then
                    CastSpellByName("Slice and Dice")
                    debug_print("Refreshing Slice and Dice (Surprise Attack queued).")
                else
                    debug_print("Not enough energy to refresh Slice and Dice (Surprise Attack queued).")
                end
            else
                CastSpellByName("Slice and Dice")
                debug_print("Refreshing Slice and Dice (Surprise Attack not queued).")
            end
        end
    end

    -- Handle Expose Armor at 5 combo points
    if comboPoints == 5 and energy >= 25 then
        CastSpellByName("Expose Armor")
        debug_print("Casting Expose Armor (5 combo points).")
        return
    end

    -- Handle Sinister Strike if Slice and Dice is skipped or not needed
    if not canCastSliceAndDice or (not timeLeft and comboPoints < 2) then
        if energy >= 40 then
            if ROB.IsSurpriseAttackQueued() then
                if comboPoints == 4 then
                    debug_print("Not using Sinister Strike to avoid wasting combo points (Surprise Attack queued).")
                elseif energy < 50 then
                    debug_print("Not using Sinister Strike to preserve energy for Surprise Attack.")
                else
                    CastSpellByName("Sinister Strike")
                    debug_print("Casting Sinister Strike (Slice and Dice skipped).")
                end
            else
                CastSpellByName("Sinister Strike")
                debug_print("Casting Sinister Strike (Slice and Dice skipped).")
            end
        else
            debug_print("Not enough energy to cast Sinister Strike.")
        end
        return
    end

    -- Fallback: Build combo points with Sinister Strike if nothing else applies
    if energy >= 40 and comboPoints < 5 then
        CastSpellByName("Sinister Strike")
        debug_print("Fallback: Casting Sinister Strike to build combo points.")
    else
        debug_print("Fallback: Not enough energy to cast Sinister Strike.")
    end
end


-- Updated /robattack command to choose rotation based on talents and Expose Armor toggle
SLASH_ROBATTACK1 = "/robattack"
SlashCmdList["ROBATTACK"] = function()
    if ROB.exposeArmorToggled then
        -- Use the Expose Armor rotation if toggled ON
        debug_print("Using Expose Armor rotation (Expose Armor toggled ON).")
        ROB.RotationExpose()
    elseif ROB.HasTalent("Lethality") then
        -- Use the original rotation if the player has the Lethality talent
        debug_print("Using original rotation (Lethality detected).")
        ROB.HandleRotation()
    elseif ROB.HasTalent("Serrated Blades") then
        -- Use the rupture-focused rotation if the player has the Serrated Blades talent
        debug_print("Using rupture-focused rotation (Serrated Blades detected).")
        ROB.HandleRotationRupture()
    else
        -- Default fallback if no relevant talents are detected
        DEFAULT_CHAT_FRAME:AddMessage("[ROB] No relevant talent detected. Using default rotation.")
        ROB.HandleRotation()
    end
end

