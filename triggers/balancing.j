library Balance requires Functions

globals
    private string nl = "\n"
    
    string array STOOLTIP
endglobals

private function HL takes string s returns string
    return ("|cffffcc00" + s + "|r")
endfunction

function AssaultHelicopterFormula takes integer pid returns real
    return 0.35 * (GetHeroAgi(Hero[pid], true) * 2 + UnitGetBonus(Hero[pid], BONUS_DAMAGE))
endfunction

function AssaultHelicopterTooltip takes integer pid, integer level returns string
    local string tt = ""

    set tt = "Call in an Assault Helicopter to provide air support. The Assault Helicopter may fire homing rockets with a " + HL(R2S(1.25 - 0.25 * level)) + " second cooldown to enemies you attack dealing " + HL(RealToString(AssaultHelicopterFormula(pid))) + " spell damage."
    set tt = tt + nl + "|cffffcc00Concentrated Fire:|r If |cffffcc00Sniper Stance|r is active it will instead only shoot one enemy dealing |cffffcc003x|r damage."
    set tt = tt + nl + "|cff0080C030 second duration.|r"
    set tt = tt + nl + "|cff0080C080 second cooldown.|r"
    
    return tt
endfunction

function ArcaneMightFormula takes integer pid returns real
    return (GetHeroStr(Hero[pid], true) + GetHeroInt(Hero[pid], true)) * ((22 + GetUnitAbilityLevel(Hero[pid], 'A07X')) * 0.01)
endfunction

function ArcaneMightTooltip takes integer pid, integer level returns string
    local string tt = ""

    set tt = "Increase an allies' |cffE15F08Attack Damage|r by " + HL(I2S(35 + 5 * level) + "%") + " and |cffFFCC00All Stats|r by " + HL(RealToString(ArcaneMightFormula(pid))) + "."
    set tt = tt + nl + "|cffff0000Target ally must be at least 70 levels within you and does not stack.|r"
    set tt = tt + nl + "|cff0080C015 second duration.|r"
    set tt = tt + nl + "|cff0080C045 second cooldown.|r"
    
    return tt
endfunction

function CounterStrikeFormula takes integer pid returns real
    return (GetHeroStr(Hero[pid],true) + UnitGetBonus(Hero[pid],BONUS_DAMAGE)) * (2 + GetUnitAbilityLevel(Hero[pid],'A0FL')) * 0.2
endfunction

function CounterStrikeTooltip takes integer pid, integer level returns string
    local string tt = ""

    set tt = "The Warrior has a |cffffcc0015%|r chance to counter attack upon being hit, damaging nearby enemies for " + HL(RealToString(CounterStrikeFormula(pid))) + " spell damage."
    set tt = tt + nl + "|c000080c01 second cooldown.|r"
    
    return tt
endfunction

function BladeSpinFormula takes integer pid returns integer
    return IMaxBJ(8 - R2I(GetHeroLevel(Hero[pid]) * 0.01), 5) 
endfunction

function BladeSpinTooltip takes integer pid returns string
    return "|cff999999Passive:|r Every " + HL(I2S(BladeSpinFormula(pid)) + "th") + " auto attack deals |cff00D23F8 x Agi|r spell damage in a |cffffcc00250|r AoE.
|cff999999Active:|r After casting a spell (excluding |cffffcc00Phantom Slash|r), |cffffcc00Blade Spin|r may be activated for the same effect at |cff00D23F4 x Agi|r.
|cff0080c07.5% max mana cost.
|cff0080c0Number of attacks required decreases by 1 every 100 levels (Down to 5 at level 300)"
endfunction

function InstantDeathFormula takes integer pid returns integer
    return (11 + R2I(GetHeroLevel(Hero[pid]) / 50.) * 3)
endfunction

function InstantDeathTooltip takes integer pid returns string
    return "The Master Rogue is an expert at assassinating targets, having a " + HL("5%") + " chance to deal " + HL(I2S(InstantDeathFormula(pid)) + "x") + " |c00e15f08Attack Damage|r additional damage on attack.
|cff0080c0Critical strike multiplier increases by +3 every 50 levels (Up to 35x total)"
endfunction

function NerveGasFormula takes integer pid returns real
    return GetUnitAbilityLevel(Hero[pid], 'A0F7') * GetHeroAgi(Hero[pid], true) * 0.15
endfunction

function NerveGasTooltip takes integer pid, integer level returns string
    return "Throw a vial of nerve gas reducing enemy |c009b9bedArmor|r by " + HL("20%") + ", movement and attack speed by " + HL("30%") + ", and deal " + HL(RealToString(NerveGasFormula(pid))) + " spell damage in an area " + HL("2") + " times a second for " + HL("10") + " seconds.
    |c000080c020 second cooldown.|r"
endfunction

function OmnislashFormula takes integer pid returns real
    return GetHeroAgi(Hero[pid], true) * 1.5
endfunction

function MonsoonFormula takes integer pid returns real
    return GetHeroAgi(Hero[pid],true) * 1.4 + 15 * GetHeroLevel(Hero[pid]) * Pow(1.3, GetHeroLevel(Hero[pid]) / 100.)
endfunction

function MonsoonTooltip takes integer pid, integer level returns string
    local string tt = ""
    
    set tt = "The Thunder-Blade calls forth " + HL(I2S(1 + level)) + " thunder waves from the skies that deal " + HL(RealToString(MonsoonFormula(pid))) + " spell damage to each target in the area."
    set tt = tt + nl + "|cff0080C014 second cooldown.|r"
    
    return tt
endfunction

function ReincarnationTooltip takes integer pid, integer level returns string
    local string tt = ""
    
    set tt = "Call forth a great blessing from the heavens above to revive an ally with " + HL(I2S(20 + 10 * level) + "%") + " Max Health / Mana by targeting their tombstone."
    set tt = tt + nl + "Cooldown is refunded if the target player revives by other means."
    set tt = tt + nl + "Casting any other spell will reduce the remaining cooldown of " + HL("Resurrection") + " by " + HL("2") + " seconds."
    set tt = tt + nl + "|c000080c0" + I2S(600 - 100 * level) + " second cooldown (" + I2S(ResurrectionCD[pid]) + ").|r"
    
    return tt
endfunction
    
endlibrary
