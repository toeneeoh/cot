//////////////////////////////////////////////////////////////////////////////////////////
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@     Bonus Mod
//@=======================================================================================
//@ Credits:
//@---------------------------------------------------------------------------------------
//@     Written by:
//@         Earth-Fury
//@     Based on the work of:
//@         weaaddar
//@
//@ If you use this system, please credit all of the people mentioned above in your map.
//@=======================================================================================
//@ Bonus Mod Readme
//@---------------------------------------------------------------------------------------
//@ 
//@ BonusMod is a system for adding bonuses to a single unit. For example, you may wish
//@ to add a +40 damage bonus, or a -3 armor 'bonus'. Bonus mod works by adding abilitys
//@ to a unit which effect the particular stat by a power of two. By combining diffrent
//@ powers of two, you can reach any number between 0 and 2^(n+1) - 1, where n is the
//@ largest power of 2 used. Bonus mod can also apply negative bonuses, by adding an
//@ ability which has a 'bonus' of -2^(n+1), where again, n is the maximum power of 2.
//@ With the negative bonus, you can add anywhere between 1 and 2^(n+1)-1 of a bonus. This
//@ gives bonus mod a range of bonuses between -2^(n+1) and 2^(n+1)-1. By default, n is
//@ set at 11, giving us a range of bonuses between -4096 and +4095.
//@
//@---------------------------------------------------------------------------------------
//@ Adding Bonus Mod to your map:
//@
//@ Copy this library in to a trigger named "BonusMod" in your map.
//@
//@ After the script is copied, the hard part begins. You will have to transfer all of the
//@ bonus abilitys found in this map to yours. However, this is really easy to do if you
//@ are using the JASS NewGen editor. (Which you will have to be anyway, considering this
//@ system is written in vJASS.) Included with this library are macros for the Object 
//@ Merger included in NewGen. Simply copy the Object Merger script included with this 
//@ system in to your map in its own trigger. Save your map. (Saving will take a while. 
//@ Up to 5 min if you have a slow computer.) Close your map, and reopen it. Disable the 
//@ trigger you copied the ObjectMerger script in to.
//@ Your map now has all the abilitys it needs!
//@
//@---------------------------------------------------------------------------------------
//@ Functions:
//@
//@ boolean UnitSetBonus(unit <target unit>, integer <bonus type>, integer <bonus ammount>)
//@ 
//@     This function clears any previously applied bonus on <target unit>, setting the 
//@ unit's bonus for <bonus type> to <bonus ammount>. <bonus type> should be one of the
//@ integer type constants below. This function will return false if the desired bonus is
//@ not a valid bonus type, or out of the range of bonuses that can be applied.
//@
//@ integer UnitGetBonus(unit <target unit>, integer <bonus type>)
//@ 
//@     Returns the bonus ammount of <bonus type> currently applied to <target unit>.
//@
//@ boolean UnitAddBonus(unit <target unit>, integer <bonus type>, integer <bonus ammount>)
//@
//@     This function will add <bonus ammount> to the bonus of type <bonus type> on the
//@ unit <target unit>. <bonus ammount> can be a negative value. This function will return
//@ false if the new bonus will be out of the range which bonus mod can apply.
//@
//@ nothing UnitClearBonus(unit <target unit>, integer <bonus type>)
//@
//@     This function will effectively set the bonus of type <bonus type> for the unit
//@ <target unit> to 0. It is advised you use this function over UnitSetBonus(..., ..., 0)
//@
//@---------------------------------------------------------------------------------------
//@ Variables:
//@ 
//@ BonusMod_MaxBonus
//@     The maximum bonus that Bonus Mod can apply
//@ BonusMod_MinBonus
//@     The minimum bonus that Bonus Mod can apply
//@---------------------------------------------------------------------------------------
//@ Increasing the Range of Bonuses:
//@
//@ By default, bonus mod uses 13 abilitys per bonus type. This gives each bonus type a
//@ range of -4096 to +4095. To increase this range, you will have to create one new
//@ ability for each ability, for each power of two you increase bonus mod by. You will
//@ also have to edit the negative bonus ability to apply a bonus of -2^(n+1), where n is
//@ the largest power of two you will be using for positive bonuses. You will need to edit
//@ the ABILITY_COUNT constant found below to reflect the new total number of abilitys
//@ each individual bonus will use. You will also have to add the abilitys to the function
//@ InitializeAbilitys. Note that the number in the array index indicates which power of
//@ 2 is held there. So, for instance, set BonusAbilitys[i + 15] would hold an ability
//@ which changes the relivent stat by 32768. (2^15 = 32768) The last ability in the array
//@ must apply a negative bonus.
//@
//@ Here is an example of the bonus BONUS_ARMOR using 15 abilitys instead of 12:
//@
//@    set i = BONUS_ARMOR * ABILITY_COUNT
//@    set BonusAbilitys[i + 0]  = 'ZxA0' // +1
//@    set BonusAbilitys[i + 1]  = 'ZxA1' // +2
//@    set BonusAbilitys[i + 2]  = 'ZxA2' // +4
//@    set BonusAbilitys[i + 3]  = 'ZxA3' // +8
//@    set BonusAbilitys[i + 4]  = 'ZxA4' // +16
//@    set BonusAbilitys[i + 5]  = 'ZxA5' // +32
//@    set BonusAbilitys[i + 6]  = 'ZxA6' // +64
//@    set BonusAbilitys[i + 7]  = 'ZxA7' // +128
//@    set BonusAbilitys[i + 8]  = 'ZxA8' // +256
//@    set BonusAbilitys[i + 9]  = 'ZxA9' // +512
//@    set BonusAbilitys[i + 10] = 'ZxAa' // +1024
//@    set BonusAbilitys[i + 11] = 'ZxAb' // +2048
//@    set BonusAbilitys[i + 12] = 'ZxAc' // +4096
//@    set BonusAbilitys[i + 13] = 'ZxAd' // +8192
//@    set BonusAbilitys[i + 14] = 'ZxAe' // +16384
//@    set BonusAbilitys[i + 15] = 'ZxAf' // -32768
//@
//@---------------------------------------------------------------------------------------
//@ Adding and Removing Bonus Types:
//@
//@ Removing a bonus type is simple. First, delete it from the list of constants found
//@ below. Make sure the constants are numberd 0, 1, 2, 3, etc. without any gaps. Change
//@ the BONUS_TYPES constant to reflect the new number of bonuses. You must then remove
//@ the lines of array initialization for the bonus you removed from the
//@ InitializeAbilitys function. You can then delete the abilitys for that bonus type, and
//@ you are then done removing a bonus type.
//@
//@ Adding a bonus type is done in much the same way. Add a constant for it to the list of
//@ constants below, ensuring they are numberd 0, 1, 2, 3 etc. withour any gaps. Change
//@ the BONUS_TYPES constant to reflect the new number of bonuses. You must then create
//@ all the needed abilitys for the new bonus type. Ensure the bonus they each apply is a
//@ power of 2, as with the already included bonuses. See the section Increasing the Range
//@ of Bonuses for more information. After all the abilitys are added, you must add the
//@ needed lines to the InitializeAbilitys function. The existing lines should be a clear
//@ enogh example.
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//////////////////////////////////////////////////////////////////////////////////////////
library BonusMod initializer Initialize

globals
//========================================================================================
// Bonus Type Constants
//========================================================================================

    constant integer BONUS_ARMOR            = 0 // Armor Bonus
    constant integer BONUS_DAMAGE           = 1 // Damage Bonus
    constant integer BONUS_HERO_STR         = 2 // Strength Bonus
    constant integer BONUS_HERO_AGI         = 3 // Agility Bonus
    constant integer BONUS_HERO_INT         = 4 // Intelligence Bonus
    constant integer BONUS_LIFE_REGEN       = 5 // Life Regeneration Bonus (An absolute value)
    constant integer BONUS_ATTACK_SPEED     = 6 // Movespeed Bonus (A % value)
    
    //constant integer BONUS_MANA_REGEN       = 6 // Mana Regeneration Bonus (A % value)
    //constant integer BONUS_SIGHT_RANGE      = 7 // Sight Range Bonus

    // The number of bonus type constants above:
    constant integer BONUS_TYPES = 7

//========================================================================================
// Other Configuration
//========================================================================================

    // The number of abilitys used per bonus type:
    private constant integer ABILITY_COUNT = 30
    
    // Note: Setting the following to false will decrease loading time, but will cause a
    // small ammount of lag when a bonus is first applied. (Especially a negative bonus)
    // If set to true, all BonusMod abilitys will be preloaded:
    private constant boolean PRELOAD_ABILITYS = true
    
    // Only applies if PRELOAD_ABILITYS is set to true.
    // The unit type used to preload abilitys on:
    private constant integer PRELOAD_DUMMY_UNIT = 'E00W' // HERO_ELEMENTALIST
endglobals

//========================================================================================
// Ability Initialization
//----------------------------------------------------------------------------------------
// The following function is used to define the rawcodes for all the abilitys bonus mod
// uses. If you use the text macros included with BonusMod, and if you do not wish to add,
// remove, or change the range of bonuses, you will not have to edit the following.
// 
// Note that if your map already has abilitys with rawcodes that begin with Zx followed by
// an upper-case letter, the ObjectMerger macros included with this library will not work
// and you will have to edit the lines below. However, you could use the find and replace
// feature in JASS NewGen's Trigger Editor Syntax Highlighter to replace all occurances of
// Zx both here and in the ObjectMerger macros to ease configuration.
//========================================================================================
private keyword BonusAbilitys
private function InitializeAbilitys takes nothing returns nothing
    local integer i
    // Bonus Mod - Armor abilitys
    set i = BONUS_ARMOR * ABILITY_COUNT
    set BonusAbilitys[i + 0]  = 'ZxA0' // +1
    set BonusAbilitys[i + 1]  = 'ZxA1' // +2
    set BonusAbilitys[i + 2]  = 'ZxA2' // +4
    set BonusAbilitys[i + 3]  = 'ZxA3' // +8
    set BonusAbilitys[i + 4]  = 'ZxA4' // +16
    set BonusAbilitys[i + 5]  = 'ZxA5' // +32
    set BonusAbilitys[i + 6]  = 'ZxA6' // +64
    set BonusAbilitys[i + 7]  = 'ZxA7' // +128
    set BonusAbilitys[i + 8]  = 'ZxA8' // +256
    set BonusAbilitys[i + 9]  = 'ZxA9' // +512
    set BonusAbilitys[i + 10] = 'ZxAa' // +1024
    set BonusAbilitys[i + 11] = 'ZxAb' // +2048
    set BonusAbilitys[i + 12] = 'ZxAc' // +4096
    set BonusAbilitys[i + 13] = 'ZxAd' // +8192
    set BonusAbilitys[i + 14] = 'ZxAe' // +16384
    set BonusAbilitys[i + 15] = 'ZxAf' // +32768
    set BonusAbilitys[i + 16] = 'ZxAg' // +65536
    set BonusAbilitys[i + 17] = 'ZxAh' // +131072
    set BonusAbilitys[i + 18] = 'ZxAi' // +262144
    set BonusAbilitys[i + 19] = 'ZxAj' // +524288
    set BonusAbilitys[i + 20] = 'ZxAk' // +1048576
    set BonusAbilitys[i + 21] = 'ZxAl' // 2097152
    set BonusAbilitys[i + 22] = 'ZxAm' // 4194304
    set BonusAbilitys[i + 23] = 'ZxAn' // 8388608
    set BonusAbilitys[i + 24] = 'ZxAo' // 16777216
    set BonusAbilitys[i + 25] = 'ZxAp' // 2^25
    set BonusAbilitys[i + 26] = 'ZxAq' // 2^26
    set BonusAbilitys[i + 27] = 'ZxAr' // 2^27
    set BonusAbilitys[i + 28] = 'ZxAs' // 2^28
    set BonusAbilitys[i + 29] = 'ZxAt' // -2^29
    
    // Bonus Mod - Damage abilitys
    set i = BONUS_DAMAGE * ABILITY_COUNT
    set BonusAbilitys[i + 0]  = 'ZxD0' // +1
    set BonusAbilitys[i + 1]  = 'ZxD1' // +2
    set BonusAbilitys[i + 2]  = 'ZxD2' // +4
    set BonusAbilitys[i + 3]  = 'ZxD3' // +8
    set BonusAbilitys[i + 4]  = 'ZxD4' // +16
    set BonusAbilitys[i + 5]  = 'ZxD5' // +32
    set BonusAbilitys[i + 6]  = 'ZxD6' // +64
    set BonusAbilitys[i + 7]  = 'ZxD7' // +128
    set BonusAbilitys[i + 8]  = 'ZxD8' // +256
    set BonusAbilitys[i + 9]  = 'ZxD9' // +512
    set BonusAbilitys[i + 10] = 'ZxDa' // +1024
    set BonusAbilitys[i + 11] = 'ZxDb' // +2048
    set BonusAbilitys[i + 12] = 'ZxDc' // +4096
    set BonusAbilitys[i + 13] = 'ZxDd' // +8192
    set BonusAbilitys[i + 14] = 'ZxDe' // +16384
    set BonusAbilitys[i + 15] = 'ZxDf' // +32768
    set BonusAbilitys[i + 16] = 'ZxDg' // +65536
    set BonusAbilitys[i + 17] = 'ZxDh' // +131072
    set BonusAbilitys[i + 18] = 'ZxDi' // +262144
    set BonusAbilitys[i + 19] = 'ZxDj' // +524288
    set BonusAbilitys[i + 20] = 'ZxDk' // +1048576
    set BonusAbilitys[i + 21] = 'ZxDl' // 2097152
    set BonusAbilitys[i + 22] = 'ZxDm' // 4194304
    set BonusAbilitys[i + 23] = 'ZxDn' // 8388608
    set BonusAbilitys[i + 24] = 'ZxDo' // 16777216
    set BonusAbilitys[i + 25] = 'ZxDp' // 33554432
    set BonusAbilitys[i + 26] = 'ZxDq' // 2^26
    set BonusAbilitys[i + 27] = 'ZxDr' // 2^27
    set BonusAbilitys[i + 28] = 'ZxDs' // 2^28
    set BonusAbilitys[i + 29] = 'ZxDt' // -2^29
    
    // Bonus Mod - Life Regen abilitys
    set i = BONUS_LIFE_REGEN * ABILITY_COUNT
    set BonusAbilitys[i + 0]  = 'ZxR0' // +1
    set BonusAbilitys[i + 1]  = 'ZxR1' // +2
    set BonusAbilitys[i + 2]  = 'ZxR2' // +4
    set BonusAbilitys[i + 3]  = 'ZxR3' // +8
    set BonusAbilitys[i + 4]  = 'ZxR4' // +16
    set BonusAbilitys[i + 5]  = 'ZxR5' // +32
    set BonusAbilitys[i + 6]  = 'ZxR6' // +64
    set BonusAbilitys[i + 7]  = 'ZxR7' // +128
    set BonusAbilitys[i + 8]  = 'ZxR8' // +256
    set BonusAbilitys[i + 9]  = 'ZxR9' // +512
    set BonusAbilitys[i + 10] = 'ZxRa' // +1024
    set BonusAbilitys[i + 11] = 'ZxRb' // +2048
    set BonusAbilitys[i + 12] = 'ZxRc' // +4096
    set BonusAbilitys[i + 13] = 'ZxRd' // +8192
    set BonusAbilitys[i + 14] = 'ZxRe' // +16384
    set BonusAbilitys[i + 15] = 'ZxRf' // +32768
    set BonusAbilitys[i + 16] = 'ZxRg' // +65536
    set BonusAbilitys[i + 17] = 'ZxRh' // +131072
    set BonusAbilitys[i + 18] = 'ZxRi' // +262144
    set BonusAbilitys[i + 19] = 'ZxRj' // +524288
    set BonusAbilitys[i + 20] = 'ZxRk' // +1048576
    set BonusAbilitys[i + 21] = 'ZxRl' // +2097152
    set BonusAbilitys[i + 22] = 'ZxRm' // +4194304
    set BonusAbilitys[i + 23] = 'ZxRn' // +8388608
    set BonusAbilitys[i + 24] = 'ZxRo' // +16777216
    set BonusAbilitys[i + 25] = 'ZxRp' // 33554432
    set BonusAbilitys[i + 26] = 'ZxRq' // 2^26
    set BonusAbilitys[i + 27] = 'ZxRr' // 2^27
    set BonusAbilitys[i + 28] = 'ZxRs' // 2^28
    set BonusAbilitys[i + 29] = 'ZxRt' // -2^29
    
    // Bonus Mod - Hero STR abilitys
    set i = BONUS_HERO_STR * ABILITY_COUNT
    set BonusAbilitys[i + 0]  = 'ZxS0' // +1
    set BonusAbilitys[i + 1]  = 'ZxS1' // +2
    set BonusAbilitys[i + 2]  = 'ZxS2' // +4
    set BonusAbilitys[i + 3]  = 'ZxS3' // +8
    set BonusAbilitys[i + 4]  = 'ZxS4' // +16
    set BonusAbilitys[i + 5]  = 'ZxS5' // +32
    set BonusAbilitys[i + 6]  = 'ZxS6' // +64
    set BonusAbilitys[i + 7]  = 'ZxS7' // +128
    set BonusAbilitys[i + 8]  = 'ZxS8' // +256
    set BonusAbilitys[i + 9]  = 'ZxS9' // +512
    set BonusAbilitys[i + 10] = 'ZxSa' // +1024
    set BonusAbilitys[i + 11] = 'ZxSb' // +2048
    set BonusAbilitys[i + 12] = 'ZxSc' // +4096
    set BonusAbilitys[i + 13] = 'ZxSd' // +8192
    set BonusAbilitys[i + 14] = 'ZxSe' // +16384
    set BonusAbilitys[i + 15] = 'ZxSf' // +32768
    set BonusAbilitys[i + 16] = 'ZxSg' // +65536
    set BonusAbilitys[i + 17] = 'ZxSh' // +131072
    set BonusAbilitys[i + 18] = 'ZxSi' // +262144
    set BonusAbilitys[i + 19] = 'ZxSj' // +524288
    set BonusAbilitys[i + 20] = 'ZxSk' // +1048576
    set BonusAbilitys[i + 21] = 'ZxSl' // +2097152
    set BonusAbilitys[i + 22] = 'ZxSm' // +4194304
    set BonusAbilitys[i + 23] = 'ZxSn' // +8388608
    set BonusAbilitys[i + 24] = 'ZxSo' // +16777216
    set BonusAbilitys[i + 25] = 'ZxSp' // 33554432
    set BonusAbilitys[i + 26] = 'ZxSq' // 2^26
    set BonusAbilitys[i + 27] = 'ZxSr' // 2^27
    set BonusAbilitys[i + 28] = 'ZxSs' // 2^28
    set BonusAbilitys[i + 29] = 'ZxSt' // -2^29

    // Bonus Mod - Hero AGI abilitys
    set i = BONUS_HERO_AGI * ABILITY_COUNT
    set BonusAbilitys[i + 0]  = 'ZxB0' // +1
    set BonusAbilitys[i + 1]  = 'ZxB1' // +2
    set BonusAbilitys[i + 2]  = 'ZxB2' // +4
    set BonusAbilitys[i + 3]  = 'ZxB3' // +8
    set BonusAbilitys[i + 4]  = 'ZxB4' // +16
    set BonusAbilitys[i + 5]  = 'ZxB5' // +32
    set BonusAbilitys[i + 6]  = 'ZxB6' // +64
    set BonusAbilitys[i + 7]  = 'ZxB7' // +128
    set BonusAbilitys[i + 8]  = 'ZxB8' // +256
    set BonusAbilitys[i + 9]  = 'ZxB9' // +512
    set BonusAbilitys[i + 10] = 'ZxBa' // +1024
    set BonusAbilitys[i + 11] = 'ZxBb' // +2048
    set BonusAbilitys[i + 12] = 'ZxBc' // -4096
    set BonusAbilitys[i + 13] = 'ZxBd' // +8192
    set BonusAbilitys[i + 14] = 'ZxBe' // +16384
    set BonusAbilitys[i + 15] = 'ZxBf' // +32768
    set BonusAbilitys[i + 16] = 'ZxBg' // +65536
    set BonusAbilitys[i + 17] = 'ZxBh' // +131072
    set BonusAbilitys[i + 18] = 'ZxBi' // +262144
    set BonusAbilitys[i + 19] = 'ZxBj' // +524288
    set BonusAbilitys[i + 20] = 'ZxBk' // +1048576
    set BonusAbilitys[i + 21] = 'ZxBl' // +2097152
    set BonusAbilitys[i + 22] = 'ZxBm' // +4194304
    set BonusAbilitys[i + 23] = 'ZxBn' // +8388608
    set BonusAbilitys[i + 24] = 'ZxBo' // +16777216
    set BonusAbilitys[i + 25] = 'ZxBp' // 33554432
    set BonusAbilitys[i + 26] = 'ZxBq' // 2^26
    set BonusAbilitys[i + 27] = 'ZxBr' // 2^27
    set BonusAbilitys[i + 28] = 'ZxBs' // 2^28
    set BonusAbilitys[i + 29] = 'ZxBt' // -2^29
    
    // Bonus Mod - Hero INT abilitys
    set i = BONUS_HERO_INT * ABILITY_COUNT
    set BonusAbilitys[i + 0]  = 'ZxI0' // +1
    set BonusAbilitys[i + 1]  = 'ZxI1' // +2
    set BonusAbilitys[i + 2]  = 'ZxI2' // +4
    set BonusAbilitys[i + 3]  = 'ZxI3' // +8
    set BonusAbilitys[i + 4]  = 'ZxI4' // +16
    set BonusAbilitys[i + 5]  = 'ZxI5' // +32
    set BonusAbilitys[i + 6]  = 'ZxI6' // +64
    set BonusAbilitys[i + 7]  = 'ZxI7' // +128
    set BonusAbilitys[i + 8]  = 'ZxI8' // +256
    set BonusAbilitys[i + 9]  = 'ZxI9' // +512
    set BonusAbilitys[i + 10] = 'ZxIa' // +1024
    set BonusAbilitys[i + 11] = 'ZxIb' // +2048
    set BonusAbilitys[i + 12] = 'ZxIc' // -4096
    set BonusAbilitys[i + 13] = 'ZxId' // +8192
    set BonusAbilitys[i + 14] = 'ZxIe' // +16384
    set BonusAbilitys[i + 15] = 'ZxIf' // +32768
    set BonusAbilitys[i + 16] = 'ZxIg' // +65536
    set BonusAbilitys[i + 17] = 'ZxIh' // +131072
    set BonusAbilitys[i + 18] = 'ZxIi' // +262144
    set BonusAbilitys[i + 19] = 'ZxIj' // +524288
    set BonusAbilitys[i + 20] = 'ZxIk' // +1048576
    set BonusAbilitys[i + 21] = 'ZxIl' // +2097152
    set BonusAbilitys[i + 22] = 'ZxIm' // +4194304
    set BonusAbilitys[i + 23] = 'ZxIn' // +8388608
    set BonusAbilitys[i + 24] = 'ZxIo' // +16777216
    set BonusAbilitys[i + 25] = 'ZxIp' // 33554432
    set BonusAbilitys[i + 26] = 'ZxIq' // 2^26
    set BonusAbilitys[i + 27] = 'ZxIr' // 2^27
    set BonusAbilitys[i + 28] = 'ZxIs' // 2^28
    set BonusAbilitys[i + 29] = 'ZxIt' // -2^29
    
    // Bonus Mod - Attack Speed Abilities
    set i = BONUS_ATTACK_SPEED * ABILITY_COUNT
    set BonusAbilitys[i + 0] = 'ZxJ0' // +0.01
    set BonusAbilitys[i + 1] = 'ZxJ1' // +0.02
    set BonusAbilitys[i + 2] = 'ZxJ2' // +0.04
    set BonusAbilitys[i + 3] = 'ZxJ3' // +0.08
    set BonusAbilitys[i + 4] = 'ZxJ4' // +0.16
    set BonusAbilitys[i + 5] = 'ZxJ5' // +0.32
    set BonusAbilitys[i + 6] = 'ZxJ6' // +0.64
    set BonusAbilitys[i + 7] = 'ZxJ7' // +1.28
    set BonusAbilitys[i + 8] = 'ZxJ8' // +2.56
    set BonusAbilitys[i + 9] = 'ZxJ9' // +5.12
    set BonusAbilitys[i + 10] = 'ZxJa' // +10.24
    set BonusAbilitys[i + 11] = 'ZxJb' // +20.48
    set BonusAbilitys[i + 12] = 'ZxJc' // +40.96
    set BonusAbilitys[i + 13] = 'ZxJd' // +81.92
    set BonusAbilitys[i + 14] = 'ZxJe' // +163.84
    set BonusAbilitys[i + 15] = 'ZxJf' // +327.68
    set BonusAbilitys[i + 16] = 'ZxJg' // +655.36
    set BonusAbilitys[i + 17] = 'ZxJh' // +1310.72
    set BonusAbilitys[i + 18] = 'ZxJi' // +2621.44
    set BonusAbilitys[i + 19] = 'ZxJj' // +5242.88
    set BonusAbilitys[i + 20] = 'ZxJk' // +10485.67
    set BonusAbilitys[i + 21] = 'ZxJl' // +20971.52
    set BonusAbilitys[i + 22] = 'ZxJm' // +41943.04
    set BonusAbilitys[i + 23] = 'ZxJn' // +83886.08
    set BonusAbilitys[i + 24] = 'ZxJo' // +167772.16
    set BonusAbilitys[i + 25] = 'ZxJp' // +335544.32
    set BonusAbilitys[i + 26] = 'ZxJq' // +2^26
    set BonusAbilitys[i + 27] = 'ZxJr' // +2^27
    set BonusAbilitys[i + 28] = 'ZxJs' // +2^28
    set BonusAbilitys[i + 29] = 'ZxJt' // -2^29
    
    // Bonus Mod - Move Speed Abilities
    /*set i = BONUS_MOVE_SPEED * ABILITY_COUNT
    set BonusAbilitys[i + 0] = 'ZxK0' // +1
    set BonusAbilitys[i + 1] = 'ZxK1' // +2
    set BonusAbilitys[i + 2] = 'ZxK2' // +4
    set BonusAbilitys[i + 3] = 'ZxK3' // +8
    set BonusAbilitys[i + 4] = 'ZxK4' // +16
    set BonusAbilitys[i + 5] = 'ZxK5' // +32
    set BonusAbilitys[i + 6] = 'ZxK6' // +64
    set BonusAbilitys[i + 7] = 'ZxK7' // +128
    set BonusAbilitys[i + 8] = 'ZxK8' // +256
    set BonusAbilitys[i + 9] = 'ZxK9' // +512
    set BonusAbilitys[i + 10] = 'ZxKa' // +1024
    set BonusAbilitys[i + 11] = 'ZxKb' // +2048
    set BonusAbilitys[i + 12] = 'ZxKc' // +4096
    set BonusAbilitys[i + 13] = 'ZxKd' // +8192
    set BonusAbilitys[i + 14] = 'ZxKe' // +16384
    set BonusAbilitys[i + 15] = 'ZxKf' // +32768
    set BonusAbilitys[i + 16] = 'ZxKg' // +65536
    set BonusAbilitys[i + 17] = 'ZxKh' // +131072
    set BonusAbilitys[i + 18] = 'ZxKi' // +262144
    set BonusAbilitys[i + 19] = 'ZxKj' // +524288
    set BonusAbilitys[i + 20] = 'ZxKk' // +1048567
    set BonusAbilitys[i + 21] = 'ZxKl' // +2097152
    set BonusAbilitys[i + 22] = 'ZxKm' // +4194304
    set BonusAbilitys[i + 23] = 'ZxKn' // +8388608
    set BonusAbilitys[i + 24] = 'ZxKo' // +16777216
    set BonusAbilitys[i + 25] = 'ZxKp' // +33554432
    set BonusAbilitys[i + 26] = 'ZxKq' // +2^26
    set BonusAbilitys[i + 27] = 'ZxKr' // +2^27
    set BonusAbilitys[i + 28] = 'ZxKs' // +2^28
    set BonusAbilitys[i + 29] = 'ZxKt' // -2^29*/
endfunction

//========================================================================================
// System Code
//----------------------------------------------------------------------------------------
// Do not edit below this line unless you wish to change the way the system works.
//========================================================================================

globals
    // Contains all abilitys in a two-dimensional structure:
    private integer array BonusAbilitys
    
    // Precomputed powers of two to avoid speed and rounding issues with Pow():
    private integer array PowersOf2

    // Range constants (Read only please):
    public integer MaxBonus
    public integer MinBonus
endglobals

function UnitClearBonus takes unit u, integer bonusType returns nothing
    local integer i = 0
    
    loop
        call UnitRemoveAbility(u, BonusAbilitys[bonusType * ABILITY_COUNT + i])
        
        set i = i + 1
        exitwhen i == ABILITY_COUNT - 2
    endloop
endfunction

function UnitSetBonus takes unit u, integer bonusType, integer ammount returns boolean
    local integer i = ABILITY_COUNT - 2
    
    if ammount < MinBonus or ammount > MaxBonus then
        debug call BJDebugMsg("BonusSystem Error: Bonus too high or low (" + I2S(ammount) + ")")
        return false
    elseif bonusType < 0 or bonusType >= BONUS_TYPES then
        debug call BJDebugMsg("BonusSystem Error: Invalid bonus type (" + I2S(bonusType) + ")")
        return false
    endif
    
    if ammount < 0 then
        set ammount = MaxBonus + ammount + 1
        call UnitAddAbility(u, BonusAbilitys[bonusType * ABILITY_COUNT + ABILITY_COUNT - 1])
        call UnitMakeAbilityPermanent(u, true, BonusAbilitys[bonusType * ABILITY_COUNT + ABILITY_COUNT - 1])
    else
        call UnitRemoveAbility(u, BonusAbilitys[bonusType * ABILITY_COUNT + ABILITY_COUNT - 1])
    endif

    loop
        if ammount >= PowersOf2[i] then
            call UnitAddAbility(u, BonusAbilitys[bonusType * ABILITY_COUNT + i])
            call UnitMakeAbilityPermanent(u, true, BonusAbilitys[bonusType * ABILITY_COUNT + i])
            set ammount = ammount - PowersOf2[i]
        else
            call UnitRemoveAbility(u, BonusAbilitys[bonusType * ABILITY_COUNT + i])
        endif
        
        set i = i - 1
        exitwhen i < 0
    endloop
    
    return true
endfunction

function UnitGetBonus takes unit u, integer bonusType returns integer
    local integer i = 0
    local integer ammount = 0
    
    if GetUnitAbilityLevel(u, BonusAbilitys[bonusType * ABILITY_COUNT + ABILITY_COUNT - 1]) > 0 then
        set ammount = MinBonus
    endif
    
    loop
        if GetUnitAbilityLevel(u, BonusAbilitys[bonusType * ABILITY_COUNT + i]) > 0 then
            set ammount = ammount + PowersOf2[i]
        endif
        
        set i = i + 1
        exitwhen i == ABILITY_COUNT - 1
    endloop
    
    return ammount
endfunction

function UnitAddBonus takes unit u, integer bonusType, integer ammount returns boolean
    return UnitSetBonus(u, bonusType, UnitGetBonus(u, bonusType) + ammount)
endfunction

private function Initialize takes nothing returns nothing
    local integer i = 1
    local unit u
    
    set PowersOf2[0] = 1
    loop
        set PowersOf2[i] = PowersOf2[i - 1] * 2
        set i = i + 1
        exitwhen i == ABILITY_COUNT
    endloop
    
    set MaxBonus = PowersOf2[ABILITY_COUNT - 1] - 1
    set MinBonus = -PowersOf2[ABILITY_COUNT - 1]
    
    call InitializeAbilitys()
    
    if PRELOAD_ABILITYS then
        set u = CreateUnit(Player(15), PRELOAD_DUMMY_UNIT, 0, 0, 0)
        set i = 0
        loop
            exitwhen i == BONUS_TYPES * ABILITY_COUNT
            call UnitAddAbility(u, BonusAbilitys[i])
            set i = i + 1
        endloop
        call RemoveUnit(u)
    endif

endfunction
endlibrary