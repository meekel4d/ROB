-- Function to get spell book slot for a given spell name
function ROB.FindSpellBookSlotByName(spellName)
    for i = 1, 120 do
        local spellBookName, spellBookRank = GetSpellName(i, "spell")
        if spellBookName == spellName then
            return i
        end
    end
    return nil
end

-- Function to get spell cooldown by spell ID
function ROB.GetSpellCooldownById(spellID)
    local name, rank, texture, minRange, maxRange = SpellInfo(spellID)
    if name then
        local slot = ROB.FindSpellBookSlotByName(name)
        if slot then
            return GetSpellCooldown(slot, "spell")
        end
    end
    return nil, nil, nil
end

-- Function to find action slot by texture
function ROB.FindActionSlotByTexture(texture)
    for lActionSlot = 1, 120 do
        local lActionTexture = GetActionTexture(lActionSlot)
        if lActionTexture == texture then
            return lActionSlot
        end
    end
    return nil
end
