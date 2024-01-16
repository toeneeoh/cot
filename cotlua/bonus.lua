if Debug then Debug.beginFile 'Bonus' end

OnInit.global("Bonus", function()
    BONUS_ARMOR                    = 0  ---@type integer 
    BONUS_DAMAGE                   = 1  ---@type integer 
    BONUS_HERO_STR                 = 2  ---@type integer 
    BONUS_HERO_AGI                 = 3  ---@type integer 
    BONUS_HERO_INT                 = 4  ---@type integer 
    BONUS_LIFE_REGEN               = 5  ---@type integer 
    BONUS_ATTACK_SPEED             = 6  ---@type integer 
    BONUS_COUNT                    = 6 ---@type integer 

    BONUS_ABIL = { ---@type integer
        [0] = FourCC('Z000'),
        [1] = FourCC('Z001'),
        [2] = FourCC('Z002'),
        [3] = FourCC('Z002'),
        [4] = FourCC('Z002'),
        [5] = FourCC('Z005'),
        [6] = FourCC('Z006')
    }
    BONUS_IFIELD={ ---@type abilityintegerlevelfield[] 
        [0] = ABILITY_ILF_DEFENSE_BONUS_IDEF,
        [1] = ABILITY_ILF_ATTACK_BONUS,
        [2] = ABILITY_ILF_STRENGTH_BONUS_ISTR,
        [3] = ABILITY_ILF_AGILITY_BONUS,
        [4] = ABILITY_ILF_INTELLIGENCE_BONUS,
        [5] = ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND
    }
    BONUS_RFIELD = { ---@type abilityreallevelfield[] 
        [6] = ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1
    }

    ---@type fun(u: unit, bonus: integer): number
    function UnitGetBonus(u, bonus)
        if bonus == BONUS_LIFE_REGEN then
            return BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE)
        elseif bonus == BONUS_ATTACK_SPEED then
            return BlzGetAbilityRealLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_RFIELD[bonus], 0)
        else
            return BlzGetAbilityIntegerLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_IFIELD[bonus], 0) * 1.
        end
    end

    ---@type fun(u: unit, bonus: integer, amount: number)
    function UnitSetBonus(u, bonus, amount)
        if GetUnitAbilityLevel(u, BONUS_ABIL[bonus]) == 0 then
            UnitAddAbility(u, BONUS_ABIL[bonus])
            UnitMakeAbilityPermanent(u, true, BONUS_ABIL[bonus])
        end

        if bonus == BONUS_LIFE_REGEN then
            BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE, amount)
        elseif bonus == BONUS_ATTACK_SPEED then
            BlzSetAbilityRealLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_RFIELD[bonus], 0, amount)
        else
            BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_IFIELD[bonus], 0, R2I(amount))
        end

        IncUnitAbilityLevel(u, BONUS_ABIL[bonus])
        DecUnitAbilityLevel(u, BONUS_ABIL[bonus])
    end

    ---@type fun(u: unit, bonus: integer, amount: number)
    function UnitAddBonus(u, bonus, amount)
        if amount ~= 0 then
            UnitSetBonus(u, bonus, UnitGetBonus(u, bonus) + amount)
        end
    end
end)

if Debug then Debug.endFile() end
