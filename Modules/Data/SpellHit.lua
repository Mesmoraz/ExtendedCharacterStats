---@type Data
local Data = ECSLoader:ImportModule("Data")
---@type DataUtils
local DataUtils = ECSLoader:ImportModule("DataUtils")

local _SpellHit = {}

function Data:SpellMissChanceSameLevel()
    local missChance = ECS.IsWotlk and 3 or 4

    missChance = missChance - _SpellHit:GetTalentSpellHitBonus()
    local mod = _SpellHit:GetSpellHitBonus()
    if mod then
        missChance = missChance - mod
    end

    if ECS.IsWotlk and missChance < 0 then
        missChance = 0
    elseif (not ECS.IsWotlk) and missChance < 1 then
        missChance = 1
    elseif missChance > 100 then
        missChance = 100
    end

    return DataUtils:Round(missChance, 2) .. "%"
end

function Data:SpellMissChanceBossLevel()
    local missChance = 17

    missChance = missChance - _SpellHit:GetTalentSpellHitBonus()
    local mod = _SpellHit:GetSpellHitBonus()
    if mod then
        missChance = missChance - mod
    end

    if ECS.IsWotlk and missChance < 0 then
        missChance = 0
    elseif (not ECS.IsWotlk) and missChance < 1 then
        missChance = 1
    elseif missChance > 100 then
        missChance = 100
    end

    return DataUtils:Round(missChance, 2) .. "%"
end

function _SpellHit:GetTalentSpellHitBonus()
    local _, _, classId = UnitClass("player")
    local bonus = 0

    if classId == Data.PRIEST then
        if ECS.IsWotlk then
            local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 3)
            bonus = points -- 0-3% from Shadow Focus
        else
            local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 3)
            bonus = points * 2 -- 0-10% from Shadow Focus
        end
    end

    if classId == Data.PALADIN and (not ECS.IsWotlk) then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(2, 3)
        bonus = points * 1 -- 0-3% Precision
    end

    if classId == Data.MAGE then
        if ECS.IsWotlk then
            local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 17)
            bonus = points * 1 -- 0-3% from Elemental Precision
        else
            local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 17)
            bonus = points * 2 -- 0-6% from Elemental Precision
        end
    end

    if classId == Data.SHAMAN then
        if ECS.IsWotlk then
            local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 16)
            bonus = points -- 0-3% from Elemental Precision
        else
            local _, _, _, _, points, _, _, _ = GetTalentInfo(3, 3)
            bonus = points * 1 -- 0-3% Nature's Guidance
        end
    end

    if ECS.IsWotlk and classId == Data.DRUID then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 13)
        bonus = points * 2 -- 0-4% from Balance of Power
    end

    if ECS.IsWotlk and classId == Data.WARLOCK then
        local _, _, _, _, points, _, _, _ = GetTalentInfo(1, 5)
        bonus = points -- 0-3% from Suppression
    end

    return bonus
end

---@return number
function _SpellHit:GetSpellHitBonus()
    local mod = 0
    if CR_HIT_SPELL then
        mod = GetCombatRatingBonus(CR_HIT_SPELL)
    else
        mod = GetSpellHitModifier()
    end

    mod = mod + _SpellHit:GetSpellHitFromBuffs()
    mod = mod + _SpellHit:GetSpellHitFromRunes()  -- Add rune hit bonus

    return mod
end

function _SpellHit:GetSpellHitFromBuffs()
    local mod = 0
    local otherDraeneiInGroup = false

    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId, _ = UnitAura("player", i, "HELPFUL")
        if spellId == nil then
            break
        end

        if spellId == 28878 then
            mod = mod + 1 -- 1% from Inspiring Presence
            otherDraeneiInGroup = true
        end

        if spellId == 30708 then
            mod = mod + 3 -- 3% from Totem of Wrath
        end
    end

    if (not otherDraeneiInGroup) and (IsSpellKnown(28878) or IsSpellKnown(6562)) then
        mod = mod + 1
    end

    return mod
end

---@return string
function Data:SpellHitBonus()
    local hit = _SpellHit:GetTalentSpellHitBonus()
    local mod = _SpellHit:GetSpellHitBonus()
    if mod then
        hit = hit + mod
    end

    return DataUtils:Round(hit, 2) .. "%"
end

---@return number
function Data:SpellHitRating()
    return GetCombatRating(CR_HIT_SPELL)
end

---@return number
function _SpellHit:GetSpellHitFromRunes()
    local mod = 0
    local runeSpellIds = {
        [226413] = 6,  -- Rune of Arcane Specialization: +6% hit chance with Arcane spells
        [226414] = 6,  -- Rune of Fire Specialization: +6% hit chance with Fire spells
        [226415] = 6,  -- Rune of Frost Specialization: +6% hit chance with Frost spells
        [226416] = 6,  -- Rune of Nature Specialization: +6% hit chance with Nature spells
        [226417] = 6,  -- Rune of Shadow Specialization: +6% hit chance with Shadow spells
        [226418] = 6,  -- Rune of Holy Specialization: +6% hit chance with Holy spells
    }

    for i = 1, 40 do
        local _, _, _, _, _, _, _, _, _, spellId, _ = UnitAura("player", i, "HELPFUL")
        if spellId == nil then
            break
        end

        if runeSpellIds[spellId] then
            mod = runeSpellIds[spellId]
            break  -- Stop checking after the first valid rune to avoid stacking
        end
    end

    return mod
end