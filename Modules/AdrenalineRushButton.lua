-- SavedVariables for position, size, and lock status
ROBIconSettings = ROBIconSettings or { size = 64, point = "CENTER", x = 0, y = 0, locked = false }

-- Create the Adrenaline Rush icon frame as a button
local adrenalineRushFrame = CreateFrame("Button", "AdrenalineRushIconFrame", UIParent)
adrenalineRushFrame:SetWidth(ROBIconSettings.size)
adrenalineRushFrame:SetHeight(ROBIconSettings.size)
adrenalineRushFrame:SetPoint(ROBIconSettings.point, UIParent, ROBIconSettings.point, ROBIconSettings.x, ROBIconSettings.y)
adrenalineRushFrame:SetMovable(true)
adrenalineRushFrame:EnableMouse(true)

-- Right-click to drag and move the icon if not locked
adrenalineRushFrame:RegisterForDrag("RightButton")
adrenalineRushFrame:SetScript("OnDragStart", function()
    if not ROBIconSettings.locked then
        adrenalineRushFrame:StartMoving()
    end
end)
adrenalineRushFrame:SetScript("OnDragStop", function()
    adrenalineRushFrame:StopMovingOrSizing()
    local point, _, _, xOfs, yOfs = adrenalineRushFrame:GetPoint()
    ROBIconSettings.point = point
    ROBIconSettings.x = xOfs
    ROBIconSettings.y = yOfs
end)

-- Create the texture for the Adrenaline Rush icon
local adrenalineRushTexture = adrenalineRushFrame:CreateTexture(nil, "BACKGROUND")
adrenalineRushTexture:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordDominate") -- Replace with Adrenaline Rush texture
adrenalineRushTexture:SetAllPoints(adrenalineRushFrame)

-- Function to update the visibility of the Adrenaline Rush icon based on toggle state
function ROB.UpdateAdrenalineRushIcon()
    if ROB.adrenalineRushToggled then
        adrenalineRushFrame:SetAlpha(1.0) -- Full opacity when toggled ON
    else
        adrenalineRushFrame:SetAlpha(0.3) -- Faded opacity when toggled OFF
    end
end

-- Button click functionality to toggle Adrenaline Rush
local function ToggleAdrenalineRushFromButton()
    ROB.Adrenalinerush()
    ROB.UpdateAdrenalineRushIcon()
end

-- Set the left-click functionality to toggle Adrenaline Rush
adrenalineRushFrame:RegisterForClicks("LeftButtonUp")
adrenalineRushFrame:SetScript("OnClick", ToggleAdrenalineRushFromButton)

-- Initialize the Adrenaline Rush button icon on load
ROB.UpdateAdrenalineRushIcon()

-- Create the Blade Flurry icon frame as a button
local bladeFlurryFrame = CreateFrame("Button", "BladeFlurryIconFrame", UIParent)
bladeFlurryFrame:SetWidth(ROBIconSettings.size)
bladeFlurryFrame:SetHeight(ROBIconSettings.size)
bladeFlurryFrame:SetPoint("LEFT", adrenalineRushFrame, "RIGHT", 0, 0) -- Position it to the right of Adrenaline Rush
bladeFlurryFrame:SetMovable(true)
bladeFlurryFrame:EnableMouse(true)

-- Right-click to drag and move the icon if not locked
bladeFlurryFrame:RegisterForDrag("RightButton")
bladeFlurryFrame:SetScript("OnDragStart", function()
    if not ROBIconSettings.locked then
        bladeFlurryFrame:StartMoving()
    end
end)
bladeFlurryFrame:SetScript("OnDragStop", function()
    bladeFlurryFrame:StopMovingOrSizing()
    local point, _, _, xOfs, yOfs = bladeFlurryFrame:GetPoint()
    ROBIconSettings.point = point
    ROBIconSettings.x = xOfs
    ROBIconSettings.y = yOfs
end)

-- Create the texture for the Blade Flurry icon
local bladeFlurryTexture = bladeFlurryFrame:CreateTexture(nil, "BACKGROUND")
bladeFlurryTexture:SetTexture("Interface\\Icons\\Ability_Warrior_PunishingBlow") -- Replace with Blade Flurry texture
bladeFlurryTexture:SetAllPoints(bladeFlurryFrame)

-- Function to update the visibility of the Blade Flurry icon based on toggle state
function ROB.UpdateBladeFlurryIcon()
    if ROB.bladeFlurryToggled then
        bladeFlurryFrame:SetAlpha(1.0) -- Full opacity when toggled ON
    else
        bladeFlurryFrame:SetAlpha(0.3) -- Faded opacity when toggled OFF
    end
end

-- Button click functionality to toggle Blade Flurry
local function ToggleBladeFlurryFromButton()
    ROB.BladeFlurry()
    ROB.UpdateBladeFlurryIcon()
end

-- Set the left-click functionality to toggle Blade Flurry
bladeFlurryFrame:RegisterForClicks("LeftButtonUp")
bladeFlurryFrame:SetScript("OnClick", ToggleBladeFlurryFromButton)

-- Initialize the Blade Flurry button icon on load
ROB.UpdateBladeFlurryIcon()

-- Function to scale all icons and save the size
function ROB.ScaleIcons(scale)
    if scale < 1 then scale = 1 end
    if scale > 100 then scale = 100 end
    local size = 64 * (scale / 100)
    adrenalineRushFrame:SetWidth(size)
    adrenalineRushFrame:SetHeight(size)
    bladeFlurryFrame:SetWidth(size)
    bladeFlurryFrame:SetHeight(size)
    ROBIconSettings.size = size -- Save the size for future use
end

-- Function to hide all icons
function ROB.HideIcons()
    adrenalineRushFrame:Hide()
    bladeFlurryFrame:Hide()
    print("Icons are now hidden.")
end

-- Function to show all icons
function ROB.ShowIcons()
    adrenalineRushFrame:Show()
    bladeFlurryFrame:Show()
    print("Icons are now visible.")
end

-- Slash command to scale, lock/unlock, hide/show icons
SLASH_ROBICON1 = "/robicon"
SlashCmdList["ROBICON"] = function(input)
    local scale = tonumber(input)
    if input == "lock" then
        ROBIconSettings.locked = true
        print("Icons are now locked.")
    elseif input == "unlock" then
        ROBIconSettings.locked = false
        print("Icons are now unlocked.")
    elseif input == "hide" then
        ROB.HideIcons()
    elseif input == "show" then
        ROB.ShowIcons()
    elseif scale then
        ROB.ScaleIcons(scale)
        print("Icons scaled to " .. scale .. "% of default size.")
    else
        print("Please enter a valid command: lock, unlock, hide, show, or a number between 1 and 100 to scale the icons.")
    end
end

-- Create the Expose Armor icon frame as a button
local exposeArmorFrame = CreateFrame("Button", "ExposeArmorIconFrame", UIParent)
exposeArmorFrame:SetWidth(ROBIconSettings.size)
exposeArmorFrame:SetHeight(ROBIconSettings.size)
exposeArmorFrame:SetPoint("LEFT", bladeFlurryFrame, "RIGHT", 0, 0) -- Position it to the right of Blade Flurry
exposeArmorFrame:SetMovable(true)
exposeArmorFrame:EnableMouse(true)

-- Right-click to drag and move the icon if not locked
exposeArmorFrame:RegisterForDrag("RightButton")
exposeArmorFrame:SetScript("OnDragStart", function()
    if not ROBIconSettings.locked then
        exposeArmorFrame:StartMoving()
    end
end)
exposeArmorFrame:SetScript("OnDragStop", function()
    exposeArmorFrame:StopMovingOrSizing()
    local point, _, _, xOfs, yOfs = exposeArmorFrame:GetPoint()
    ROBIconSettings.point = point
    ROBIconSettings.x = xOfs
    ROBIconSettings.y = yOfs
end)

-- Create the texture for the Expose Armor icon
local exposeArmorTexture = exposeArmorFrame:CreateTexture(nil, "BACKGROUND")
exposeArmorTexture:SetTexture("Interface\\Icons\\Ability_Warrior_Riposte") -- Replace with Expose Armor texture
exposeArmorTexture:SetAllPoints(exposeArmorFrame)

-- Function to update the visibility of the Expose Armor icon based on toggle state
function ROB.UpdateExposeArmorIcon()
    if ROB.exposeArmorToggled then
        exposeArmorFrame:SetAlpha(1.0) -- Full opacity when toggled ON
    else
        exposeArmorFrame:SetAlpha(0.3) -- Faded opacity when toggled OFF
    end
end

-- Button click functionality to toggle Expose Armor
local function ToggleExposeArmorFromButton()
    ROB.ToggleExposeArmor()
    ROB.UpdateExposeArmorIcon()
end

-- Set the left-click functionality to toggle Expose Armor
exposeArmorFrame:RegisterForClicks("LeftButtonUp")
exposeArmorFrame:SetScript("OnClick", ToggleExposeArmorFromButton)

-- Initialize the Expose Armor button icon on load
ROB.UpdateExposeArmorIcon()

