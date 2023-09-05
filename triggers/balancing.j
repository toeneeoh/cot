library Balance requires Functions

globals
    private string nl = "\n"
    
    string array STOOLTIP
endglobals

interface Spell
    integer pid
    integer ablev
    ability abil
    real array values[10]

    method setValues takes integer pid returns nothing

    method f0 takes integer pid, integer ablev returns real defaults 0.
    method f1 takes integer pid, integer ablev returns real defaults 0.
    method f2 takes integer pid, integer ablev returns real defaults 0.
    method f3 takes integer pid, integer ablev returns real defaults 0.
    method f4 takes integer pid, integer ablev returns real defaults 0.
    method f5 takes integer pid, integer ablev returns real defaults 0.
    method f6 takes integer pid, integer ablev returns real defaults 0.
    method f7 takes integer pid, integer ablev returns real defaults 0.
    method f8 takes integer pid, integer ablev returns real defaults 0.
    method f9 takes integer pid, integer ablev returns real defaults 0.
    //expansion probably not necessary (more than 10 formulas in one spell?)
endinterface

module spellSetup
    static method get takes integer pid returns thistype
        local thistype this = thistype.allocate()

        call setValues(pid)

        return this
    endmethod

    method setValues takes integer pid returns nothing
        set this.pid = pid
        set this.abil = BlzGetUnitAbility(Hero[pid], id)
        set this.ablev = GetUnitAbilityLevel(Hero[pid], id)
        set this.values[0] = f0(this.pid, this.ablev)
        set this.values[1] = f1(this.pid, this.ablev)
        set this.values[2] = f2(this.pid, this.ablev)
        set this.values[3] = f3(this.pid, this.ablev)
        set this.values[4] = f4(this.pid, this.ablev)
        set this.values[5] = f5(this.pid, this.ablev)
        set this.values[6] = f6(this.pid, this.ablev)
        set this.values[7] = f7(this.pid, this.ablev)
        set this.values[8] = f8(this.pid, this.ablev)
        set this.values[9] = f9(this.pid, this.ablev)
    endmethod
endmodule

//text macro for simple equation formulas
//! textmacro FORMULAS takes NAME,FORMULA
    method f$NAME$ takes integer pid, integer ablev returns real
        return $FORMULA$
    endmethod
//! endtextmacro

//formulas in order of when they appear in tooltips
//savior

struct LIGHTSEAL extends Spell 
    static constant integer id = 'A07C'

    //! runtextmacro FORMULAS("0", "12.")

    implement spellSetup
endstruct

struct DIVINEJUDGEMENT extends Spell 
    static constant integer id = 'A038'

    //! runtextmacro FORMULAS("0", "(0.2 + 0.3 * ablev) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) + BlzGetUnitBaseDamage(Hero[pid], 0))")

    implement spellSetup
endstruct

struct SAVIORSGUIDANCE extends Spell 
    static constant integer id = 'A0KU'

    //! runtextmacro FORMULAS("0", "GetHeroStr(Hero[pid], true) * (2.25 + .25 * ablev)")

    implement spellSetup
endstruct

struct HOLYBASH extends Spell 
    static constant integer id = 'A0GG'

    //! runtextmacro FORMULAS("0", "ablev * (GetHeroStr(Hero[pid], true) + (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * .4)")
    //! runtextmacro FORMULAS("1", "600.")
    //! runtextmacro FORMULAS("2", "25 + 0.5 * GetHeroStr(Hero[pid], true)")

    implement spellSetup
endstruct

struct THUNDERCLAP extends Spell 
    static constant integer id = 'A0AT'

    //! runtextmacro FORMULAS("0", "0.25 * (ablev + 1) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) + BlzGetUnitBaseDamage(Hero[pid], 0))")
    //! runtextmacro FORMULAS("1", "(200. + 50 * ablev)")

    implement spellSetup
endstruct

struct RIGHTEOUSMIGHT extends Spell 
    static constant integer id = 'A08R'

    //! runtextmacro FORMULAS("0", "(UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (.2 + .2 * ablev)")
    //! runtextmacro FORMULAS("1", "BlzGetUnitArmor(Hero[pid]) * (.4 + (.2 * ablev)) + 0.5")
    //! runtextmacro FORMULAS("2", "BlzGetUnitMaxHP(Hero[pid]) * (0.10 + 0.05 * ablev)")
    //! runtextmacro FORMULAS("3", "(ablev + 1) * 2. * GetHeroStr(Hero[pid],true)")
    //! runtextmacro FORMULAS("4", "(ablev + 1) * 5.")

    implement spellSetup
endstruct

//elite marksman

struct SNIPERSTANCE extends Spell 
    static constant integer id = 'A049'

    method f0 takes integer pid, integer ablev returns real
        local integer i = 0
        local integer id = 0
        local real crit = 2. + GetHeroLevel(Hero[pid]) / 50

        loop
            exitwhen i > 5
            set id = GetItemTypeId(UnitItemInSlot(Hero[pid], i))

            if id != 0 then
                set crit = crit + (ItemData[id][ITEM_CRIT_DAMAGE]) * (ItemData[id][ITEM_CRIT_CHANCE]) * 0.02
            endif

            set i = i + 1
        endloop

        return crit
    endmethod

    implement spellSetup
endstruct

struct TRIROCKET extends Spell 
    static constant integer id = 'A06I'

    //! runtextmacro FORMULAS("0", "(ablev * GetHeroAgi(Hero[pid], true) + (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * ablev * .1)")

    method f1 takes integer pid, integer ablev returns real
        if sniperstance[pid] then
            return 3.
        else
            return 6.
        endif
    endmethod

    implement spellSetup
endstruct

struct ASSAULTHELICOPTER extends Spell 
    static constant integer id = 'A06U'

    //! runtextmacro FORMULAS("0", "0.35 * (BlzGetUnitBaseDamage(Hero[pid], 0) + GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")
    //! runtextmacro FORMULAS("1", "30.")

    implement spellSetup
endstruct

struct SINGLESHOT extends Spell 
    static constant integer id = 'A05D'

    //! runtextmacro FORMULAS("0", "GetHeroAgi(Hero[pid], true) * 5.")

    implement spellSetup
endstruct

struct HANDGRENADE extends Spell 
    static constant integer id = 'A0J4'

    //! runtextmacro FORMULAS("0", "(UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (0.4 + 0.1 * ablev)")
    //! runtextmacro FORMULAS("1", "(BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * (0.9 + 0.1 * ablev)")

    implement spellSetup
endstruct

struct U235SHELL extends Spell 
    static constant integer id = 'A06V'

    //! runtextmacro FORMULAS("0", "(ablev + 2) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) + (GetHeroAgi(Hero[pid], true) * 5.)")

    implement spellSetup
endstruct

//thunder blade

struct THUNDERDASH extends Spell 
    static constant integer id = 'A095'

    //! runtextmacro FORMULAS("0", "(ablev + 3) * 150.")
    //! runtextmacro FORMULAS("1", "GetHeroAgi(Hero[pid], true) * 2. * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid], OVERLOAD.id) * GetUnitAbilityLevel(Hero[pid], 'B0ov'))")
    //! runtextmacro FORMULAS("2", "260.")

    implement spellSetup
endstruct

struct MONSOON extends Spell 
    static constant integer id = 'A0MN'

    //! runtextmacro FORMULAS("0", "ablev + 1.5")
    //! runtextmacro FORMULAS("1", "275 + 25. * ablev")
    //! runtextmacro FORMULAS("2", "GetHeroAgi(Hero[pid], true) * 1.4 + 15 * GetHeroLevel(Hero[pid]) * Pow(1.3, GetHeroLevel(Hero[pid]) * 0.01) * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid], OVERLOAD.id) * GetUnitAbilityLevel(Hero[pid], 'B0ov'))")

    implement spellSetup
endstruct

struct BLADESTORM extends Spell 
    static constant integer id = 'A03O'

    //! runtextmacro FORMULAS("0", "400.")
    //! runtextmacro FORMULAS("1", "GetHeroAgi(Hero[pid],true) * ablev * 0.2 * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid], OVERLOAD.id) * GetUnitAbilityLevel(Hero[pid], 'B0ov'))")
    //! runtextmacro FORMULAS("2", "15.")
    //! runtextmacro FORMULAS("3", "GetHeroAgi(Hero[pid],true) * (ablev + 2.) * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid], OVERLOAD.id) * GetUnitAbilityLevel(Hero[pid], 'B0ov'))")

    implement spellSetup
endstruct

struct OMNISLASH extends Spell 
    static constant integer id = 'A0os'

    //! runtextmacro FORMULAS("0", "ablev + 3.5")
    //! runtextmacro FORMULAS("1", "GetHeroAgi(Hero[pid], true) * 1.5 * (1 + 0.1 * GetUnitAbilityLevel(Hero[pid], OVERLOAD.id) * GetUnitAbilityLevel(Hero[pid], 'B0ov'))")

    implement spellSetup
endstruct

struct OVERLOAD extends Spell 
    static constant integer id = 'A096'

    //! runtextmacro FORMULAS("0", "9. + ablev")
    //! runtextmacro FORMULAS("1", "GetHeroAgi(Hero[pid], true) * 1. * ablev")

    implement spellSetup
endstruct

//master rogue

struct INSTANTDEATH extends Spell 
    static constant integer id = 'A0QQ'

    //! runtextmacro FORMULAS("0", "5.")
    //! runtextmacro FORMULAS("1", "12 + R2I(GetHeroLevel(Hero[pid]) / 50.) * 3.")

    implement spellSetup
endstruct

struct DEATHSTRIKE extends Spell 
    static constant integer id = 'A0QV'

    //! runtextmacro FORMULAS("0", "GetHeroAgi(Hero[pid], true) * (0.5 + 0.5 * ablev)")
    //! runtextmacro FORMULAS("1", "0.6 * ablev")

    implement spellSetup
endstruct

struct HIDDENGUISE extends Spell 
    static constant integer id = 'A0F5'

    implement spellSetup
endstruct

struct NERVEGAS extends Spell 
    static constant integer id = 'A0F7'

    //! runtextmacro FORMULAS("0", "190 + 10. * ablev")
    //! runtextmacro FORMULAS("1", "GetHeroAgi(Hero[pid], true) * 3. * ablev")
    //! runtextmacro FORMULAS("2", "10.")

    implement spellSetup
endstruct

struct BACKSTAB extends Spell 
    static constant integer id = 'A0QP'

    //! runtextmacro FORMULAS("0", "(GetHeroAgi(Hero[pid], true) * 0.16 + (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * .03) * ablev")

    implement spellSetup
endstruct

struct PIERCINGSTRIKE extends Spell 
    static constant integer id = 'A0QP'

    //! runtextmacro FORMULAS("0", "(GetHeroAgi(Hero[pid], true) * 0.16 + (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * .03) * ablev")

    implement spellSetup
endstruct

//oblivion guard

struct BODYOFFIRE extends Spell
    static constant integer id = 'A07R'

    //! runtextmacro FORMULAS("0", "GetHeroStr(Hero[pid], true) * (0.25 + 0.05 * ablev)")

    implement spellSetup
endstruct

struct METEOR extends Spell
    static constant integer id = 'A07O'

    //! runtextmacro FORMULAS("0", "GetHeroStr(Hero[pid], true) * ablev * 1.")
    //! runtextmacro FORMULAS("1", "300.")
    //! runtextmacro FORMULAS("2", "1.")

    implement spellSetup
endstruct

struct MAGNETICSTANCE extends Spell
    static constant integer id = 'A076'

    implement spellSetup
endstruct

struct INFERNALSTRIKE extends Spell
    static constant integer id = 'A05S'

    //! runtextmacro FORMULAS("0", "GetHeroStr(Hero[pid], true) * ablev * 1.")
    //! runtextmacro FORMULAS("1", "250.")

    implement spellSetup
endstruct

struct MAGNETICSTRIKE extends Spell
    static constant integer id = 'A047'

    //! runtextmacro FORMULAS("0", "250.")

    implement spellSetup
endstruct

struct GATEKEEPERSPACT extends Spell
    static constant integer id = 'A0GJ'

    //! runtextmacro FORMULAS("0", "GetHeroStr(Hero[pid], true) * 15.")
    //! runtextmacro FORMULAS("1", "550. + 50. * ablev")

    implement spellSetup
endstruct

//phoenix ranger

struct REINCARNATION extends Spell
    static constant integer id = 'A05T'

    implement spellSetup
endstruct

//bloodzerker

struct BLOODFRENZY extends Spell
    static constant integer id = 'A05Y'

    implement spellSetup
endstruct

struct BLOODLEAP extends Spell
    static constant integer id = 'A05Z'

    //! runtextmacro FORMULAS("0", "(0.4 + 0.4 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")
    //! runtextmacro FORMULAS("1", "300.")

    implement spellSetup
endstruct

struct BLOODCURDLINGSCREAM extends Spell
    static constant integer id = 'A06H'

    //! runtextmacro FORMULAS("0", "500.")

    implement spellSetup
endstruct

struct BLOODCLEAVE extends Spell
    static constant integer id = 'A05X'

    //! runtextmacro FORMULAS("0", "20.")
    //! runtextmacro FORMULAS("1", "195. + 5. * ablev")
    //! runtextmacro FORMULAS("2", "(0.45 + 0.05 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")

    implement spellSetup
endstruct

struct RAMPAGE extends Spell
    static constant integer id = 'A0GZ'

    implement spellSetup
endstruct

struct UNDYINGRAGE extends Spell
    static constant integer id = 'A0AD'

    //! runtextmacro FORMULAS("0", "0.1 * GetHeroStr(Hero[pid], true) * ((BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid]) - 1.) / BlzGetUnitMaxHP(Hero[pid]) * 10.)")
    //! runtextmacro FORMULAS("1", "0.1 * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE) - undyingRageAttackBonus[pid]) * ((BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid]) - 1.) / BlzGetUnitMaxHP(Hero[pid]) * 10.)")
    //! runtextmacro FORMULAS("2", "10.")

    implement spellSetup
endstruct

//warrior

struct PARRY extends Spell
    static constant integer id = 'A0AI'

    //! runtextmacro FORMULAS("0", "0.5 * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")

    implement spellSetup
endstruct

struct SPINDASH extends Spell
    static constant integer id = 'A0EE'
    static constant integer id2 = 'A00K'

    //! runtextmacro FORMULAS("0", "(0.2 + 0.1 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")

    implement spellSetup
endstruct

struct INTIMIDATINGSHOUT extends Spell
    static constant integer id = 'A00L'

    //! runtextmacro FORMULAS("0", "500.")
    //! runtextmacro FORMULAS("1", "3.")

    implement spellSetup
endstruct

struct WINDSCAR extends Spell
    static constant integer id = 'A0B7'

    //! runtextmacro FORMULAS("0", "(0.55 + 0.05 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")

    implement spellSetup
endstruct

struct ADAPTIVESTRIKE extends Spell
    static constant integer id = 'A0AH'
    static constant integer id2 = 'A0AM'

    //! runtextmacro FORMULAS("0", "(0.5 + 0.1 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")
    //! runtextmacro FORMULAS("1", "10. * TotalRegen[pid]")
    //! runtextmacro FORMULAS("2", "300.")
    //! runtextmacro FORMULAS("3", "300.")
    //! runtextmacro FORMULAS("4", "1.5")
    //! runtextmacro FORMULAS("5", "900.")
    //! runtextmacro FORMULAS("6", "4.")
    //! runtextmacro FORMULAS("7", "(0.2 + 0.05 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE))")
    //! runtextmacro FORMULAS("8", "3.")

    implement spellSetup
endstruct

struct LIMITBREAK extends Spell
    static constant integer id = 'A02R'

    //! runtextmacro FORMULAS("0", "4.")

    implement spellSetup
endstruct

//hydromancer

struct FROSTBLAST extends Spell
    static constant integer id = 'A0GI'

    //! runtextmacro FORMULAS("0", "1. * ablev * GetHeroInt(Hero[pid], true)")
    //! runtextmacro FORMULAS("1", "250.")
    //! runtextmacro FORMULAS("2", "4.")

    implement spellSetup
endstruct

struct WHIRLPOOL extends Spell
    static constant integer id = 'A03X'

    //! runtextmacro FORMULAS("0", "0.25 * ablev * GetHeroInt(Hero[pid], true)")
    //! runtextmacro FORMULAS("1", "330.")
    //! runtextmacro FORMULAS("2", "2. + 2. * ablev")

    implement spellSetup
endstruct

struct TIDALWAVE extends Spell
    static constant integer id = 'A077'

    //! runtextmacro FORMULAS("0", "500. + 100. * ablev")

    implement spellSetup
endstruct

struct ICEBARRAGE extends Spell
    static constant integer id = 'A098'

    implement spellSetup
endstruct

//

function ArcaneMightFormula takes integer pid returns real
    return (GetHeroStr(Hero[pid], true) + GetHeroInt(Hero[pid], true)) * ((22 + GetUnitAbilityLevel(Hero[pid], 'A07X')) * 0.01)
endfunction

function ArcaneMightTooltip takes integer pid, integer level returns string
    local string tt = ""

    set tt = "Increase an allies' |cffE15F08Attack Damage|r by " + HL(I2S(35 + 5 * level) + "%", false) + " and |cffFFCC00All Stats|r by " + HL(RealToString(ArcaneMightFormula(pid)), false) + "."
    set tt = tt + nl + "|cffff0000Target ally must be at least 70 levels within you and does not stack.|r"
    set tt = tt + nl + "|cff0080C015 second duration.|r"
    set tt = tt + nl + "|cff0080C045 second cooldown.|r"
    
    return tt
endfunction

function BladeSpinFormula takes integer pid returns integer
    return IMaxBJ(8 - R2I(GetHeroLevel(Hero[pid]) * 0.01), 5) 
endfunction

function BladeSpinTooltip takes integer pid returns string
    return "|cff999999Passive:|r Every " + HL(I2S(BladeSpinFormula(pid)) + "th", false) + " auto attack deals |cff00D23F8 x Agi|r spell damage in a |cffffcc00250|r AoE.
|cff999999Active:|r After casting a spell (excluding |cffffcc00Phantom Slash|r), |cffffcc00Blade Spin|r may be activated for the same effect at |cff00D23F4 x Agi|r.
|cff0080c07.5% max mana cost.
|cff0080c0Number of attacks required decreases by 1 every 100 levels (Down to 5 at level 300)"
endfunction

endlibrary
