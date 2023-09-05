library Bonus initializer init

    globals
        constant integer BONUS_ARMOR            = 0 
        constant integer BONUS_DAMAGE           = 1 
        constant integer BONUS_HERO_STR         = 2 
        constant integer BONUS_HERO_AGI         = 3 
        constant integer BONUS_HERO_INT         = 4 
        constant integer BONUS_LIFE_REGEN       = 5 
        constant integer BONUS_ATTACK_SPEED     = 6 

        constant integer BONUS_COUNT = 6

        integer array BONUS_ABIL
        abilityintegerlevelfield array BONUS_IFIELD
        abilityreallevelfield array BONUS_RFIELD
    endglobals

    function BonusIsReal takes integer bonus returns boolean
        return (bonus == BONUS_ATTACK_SPEED) 
    endfunction

    function UnitGetBonus takes unit u, integer bonus returns real
        if bonus == BONUS_LIFE_REGEN then
            return BlzGetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE)
        elseif BonusIsReal(bonus) then
            return BlzGetAbilityRealLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_RFIELD[bonus], 0)
        else
            return BlzGetAbilityIntegerLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_IFIELD[bonus], 0) * 1.
        endif
    endfunction

    function UnitSetBonus takes unit u, integer bonus, real amount returns nothing
        if GetUnitAbilityLevel(u, BONUS_ABIL[bonus]) == 0 then
            call UnitAddAbility(u, BONUS_ABIL[bonus])
            call UnitMakeAbilityPermanent(u, true, BONUS_ABIL[bonus])
        endif

        if bonus == BONUS_LIFE_REGEN then
            call BlzSetUnitRealField(u, UNIT_RF_HIT_POINTS_REGENERATION_RATE, amount)
        elseif BonusIsReal(bonus) then
            call BlzSetAbilityRealLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_RFIELD[bonus], 0, amount)
        else
            call BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(u, BONUS_ABIL[bonus]), BONUS_IFIELD[bonus], 0, R2I(amount))
        endif
        
        call IncUnitAbilityLevel(u, BONUS_ABIL[bonus])
        call DecUnitAbilityLevel(u, BONUS_ABIL[bonus])
    endfunction

    function UnitAddBonus takes unit u, integer bonus, real amount returns nothing
        if amount != 0 then
            call UnitSetBonus(u, bonus, UnitGetBonus(u, bonus) + amount)
        endif
    endfunction

    private function init takes nothing returns nothing
        set BONUS_ABIL[0] = 'Z000'
        set BONUS_ABIL[1] = 'Z001'
        set BONUS_ABIL[2] = 'Z002'
        set BONUS_ABIL[3] = 'Z002'
        set BONUS_ABIL[4] = 'Z002'
        set BONUS_ABIL[5] = 'Z005'
        set BONUS_ABIL[6] = 'Z006'
        set BONUS_IFIELD[0] = ABILITY_ILF_DEFENSE_BONUS_IDEF 
        set BONUS_IFIELD[1] = ABILITY_ILF_ATTACK_BONUS 
        set BONUS_IFIELD[2] = ABILITY_ILF_STRENGTH_BONUS_ISTR 
        set BONUS_IFIELD[3] = ABILITY_ILF_AGILITY_BONUS
        set BONUS_IFIELD[4] = ABILITY_ILF_INTELLIGENCE_BONUS 
        set BONUS_IFIELD[5] = ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND
        set BONUS_RFIELD[6] = ABILITY_RLF_ATTACK_SPEED_INCREASE_ISX1
    endfunction

endlibrary