scope Buffs

struct BlinkStrike extends Buff
    private static constant integer RAWCODE = 'A03Y'
    private static constant integer DISPEL_TYPE = BUFF_POSITIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL

    method onRemove takes nothing returns nothing
        call DestroyEffect(LoadEffectHandle(MiscHash, 'bstr', GetHandleId(this.target)))
        call RemoveSavedHandle(MiscHash, 'bstr', GetHandleId(this.target))
    endmethod
        
    method onApply takes nothing returns nothing
        call SaveEffectHandle(MiscHash, 'bstr', GetHandleId(this.target), AddSpecialEffectTarget("war3mapImported\\Windwalk.mdx", this.target, "origin"))
    endmethod

    implement BuffApply
endstruct

struct NagaThorns extends Buff

    private static constant integer RAWCODE = 'A04S'
    private static constant integer DISPEL_TYPE = BUFF_POSITIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        
    method onRemove takes nothing returns nothing
        //
    endmethod
        
    method onApply takes nothing returns nothing
        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\ThornyShield\\ThornyShieldTargetChestLeft.mdl", this.target, "chest"), 6.5)
        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\ThornsAura\\ThornsAura.mdl", this.target, "origin"), 2.5)
    endmethod
        
    implement BuffApply
endstruct

struct NagaEliteAtkSpeed extends Buff

    private static constant integer RAWCODE = 'A04L'
    private static constant integer DISPEL_TYPE = BUFF_POSITIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        
    method onRemove takes nothing returns nothing
        call UnitClearBonus(this.target, BONUS_ATTACK_SPEED)
    endmethod
        
    method onApply takes nothing returns nothing
        call UnitAddBonus(this.target, BONUS_ATTACK_SPEED, 800)
        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\BattleRoar\\RoarCaster.mdl", this.target, "chest"))
    endmethod
        
    implement BuffApply
endstruct

struct SpiritCallSlow extends Buff
    private static constant integer RAWCODE = 'A05M'
    private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        
    method onRemove takes nothing returns nothing

    endmethod
        
    method onApply takes nothing returns nothing
        
    endmethod
        
    implement BuffApply
endstruct

struct DarkSealSlow extends Buff
    private static constant integer RAWCODE = 'A06W'
    private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        
    method onRemove takes nothing returns nothing

    endmethod
        
    method onApply takes nothing returns nothing

    endmethod
        
    implement BuffApply
endstruct

struct Stun extends Buff
    private static constant integer RAWCODE = 'A08J'
    private static constant integer DISPEL_TYPE = BUFF_NEGATIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_PARTIAL
        
    method onRemove takes nothing returns nothing
        call BlzPauseUnitEx(this.target, false)
        call DestroyEffect(LoadEffectHandle(MiscHash, 'stun', GetHandleId(this.target)))
        call RemoveSavedHandle(MiscHash, 'stun', GetHandleId(this.target))
    endmethod
        
    method onApply takes nothing returns nothing
        call BlzPauseUnitEx(this.target, true)
        call SaveEffectHandle(MiscHash, 'stun', GetHandleId(this.target), AddSpecialEffectTarget("Abilities\\Spells\\Human\\Thunderclap\\ThunderclapTarget.mdl", this.target, "overhead"))
    endmethod
        
    implement BuffApply
endstruct

struct DarkestOfDarkness extends Buff

    private static constant integer RAWCODE = 'A056'
    private static constant integer DISPEL_TYPE = BUFF_POSITIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        
    method onRemove takes nothing returns nothing
        
    endmethod
        
    method onApply takes nothing returns nothing
        call DestroyEffectTimed(AddSpecialEffectTarget("war3mapImported\\SoulArmor.mdx", this.target, "chest"), 6.)
    endmethod
        
    implement BuffApply
endstruct

struct HolyBlessing extends Buff

    private static constant integer RAWCODE = 'A08K'
    private static constant integer DISPEL_TYPE = BUFF_POSITIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        
    method onRemove takes nothing returns nothing
        call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) * 2, 0)
    endmethod
        
    method onApply takes nothing returns nothing
        call BlzSetUnitAttackCooldown(this.target, BlzGetUnitAttackCooldown(this.target, 0) / 2, 0)
    endmethod
        
    implement BuffApply
endstruct

struct VampiricPotion extends Buff

    private static constant integer RAWCODE = 'A05O'
    private static constant integer DISPEL_TYPE = BUFF_POSITIVE
    private static constant integer STACK_TYPE =  BUFF_STACK_NONE
        
    method onRemove takes nothing returns nothing
        
    endmethod
        
    method onApply takes nothing returns nothing
        call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Items\\VampiricPotion\\VampPotionCaster.mdl", this.target, "origin"), 9)
    endmethod
        
    implement BuffApply
endstruct

endscope
