library PlayerManager requires Functions

    globals
        integer array HERO_PROF
    endglobals

    function TomeCap takes integer heroLevel returns integer
        return R2I(Pow(heroLevel, 3) * 0.002 + 10 * heroLevel)
    endfunction
    
    function CharacterSetup takes integer pid, boolean load returns nothing
        local HeroData myHero = Profile[pid].hero
        local player p = Player(pid - 1)
        local integer i = 0
        local integer i2 = 1
        local integer sid
        local ability abil = null

		set ItemMagicRes[pid] = 1
		set ItemDamageRes[pid] = 1

        if load then
            set Hero[pid] = CreateUnit(p, SAVE_UNIT_TYPE[myHero.id], GetRectCenterX(gg_rct_ChurchSpawn), GetRectCenterY(gg_rct_ChurchSpawn), 270.)
            set HeroID[pid] = GetUnitTypeId(Hero[pid])
            set urhome[pid] = 0 
            set hselection[pid] = false
            set udg_Hardcore[pid] = (myHero.hardcore > 0)

            call SetCurrency(pid, GOLD, myHero.gold)
            call SetCurrency(pid, LUMBER, myHero.lumber)
            call SetCurrency(pid, PLATINUM, myHero.platinum)
            call SetCurrency(pid, ARCADITE, myHero.arcadite)
            call SetCurrency(pid, CRYSTAL, myHero.crystal)

            call SetHeroLevelBJ(Hero[pid], myHero.level, false) 
            set udg_TimePlayed[pid] = myHero.time
            call ModifyHeroStat(bj_HEROSTAT_STR, Hero[pid], bj_MODIFYMETHOD_SET, myHero.str)
            call ModifyHeroStat(bj_HEROSTAT_AGI, Hero[pid], bj_MODIFYMETHOD_SET, myHero.agi)
            call ModifyHeroStat(bj_HEROSTAT_INT, Hero[pid], bj_MODIFYMETHOD_SET, myHero.int)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", Hero[pid], "origin"))
            if GetLocalPlayer() == p then
                call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
            endif
            call SetCameraBoundsRectForPlayerEx(p, gg_rct_Church)
        else
            //new characters can save immediately
            set LEFT_CHURCH[pid] = true
            //set hero values here?
        endif

        call GroupAddUnit(HeroGroup, Hero[pid])
        call SetPrestigeEffects(pid)
        set udg_Colloseum_XP[pid] = 1.00

        //grave
        set HeroGrave[pid] = CreateUnit(p, GRAVE, 30000, 30000, 270)
        call SuspendHeroXP(HeroGrave[pid], true)
        call ShowUnit(HeroGrave[pid], false)
        
        //backpack
        set Backpack[pid] = CreateUnit(p, BACKPACK, 30000, 30000, 0)

        //show backpack hero panel only for player
        if GetLocalPlayer() == p then
            call ClearSelection()
            call SelectUnit(Hero[pid], true)
            call ResetToGameCamera(0)
            call PanCameraToTimed(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
            call BlzSetUnitBooleanField(Backpack[pid], UNIT_BF_HERO_HIDE_HERO_INTERFACE_ICON, false)
        endif

        call SetUnitOwner(Backpack[pid], Player(PLAYER_NEUTRAL_PASSIVE), false)
        call SetUnitOwner(Backpack[pid], p, false)
        call SetUnitAnimation(Backpack[pid], "stand")
        if GetHeroLevel(Hero[pid]) > 1 then
            call SetHeroLevel(Backpack[pid], GetHeroLevel(Hero[pid]), false)
        endif
        call SuspendHeroXP(Backpack[pid], true)
        call UnitAddAbility(Backpack[pid], 'A00R')
        call UnitAddAbility(Backpack[pid], 'A09C')
        call UnitAddAbility(Backpack[pid], 'A0FS')
        call UnitAddAbility(Backpack[pid], 'A02J')
        call UnitAddAbility(Backpack[pid], 'A0FK')
        call UnitAddAbility(Backpack[pid], 'A0FV')
        call UnitAddAbility(Backpack[pid], 'A04M')
        call UnitAddAbility(Backpack[pid], 'A0DT')
        call UnitAddAbility(Backpack[pid], 'A05N')

        call UnitMakeAbilityPermanent(Hero[pid], true, 'A03C') //prevent actions disappearing on meta
		call UnitMakeAbilityPermanent(Hero[pid], true, 'A03V')
		call UnitMakeAbilityPermanent(Hero[pid], true, 'A0L0')
		call UnitMakeAbilityPermanent(Hero[pid], true, 'A0GD')
		call UnitMakeAbilityPermanent(Hero[pid], true, 'A06X')
		call UnitMakeAbilityPermanent(Hero[pid], true, 'A00F')
		call UnitMakeAbilityPermanent(Hero[pid], true, 'A08Y')

        call UpdatePrestigeTooltips()

        call SetUnitAbilityLevel(Backpack[pid], 'A0FV', IMaxBJ(1, myHero.teleport))
        call SetUnitAbilityLevel(Backpack[pid], 'A02J', IMaxBJ(1, myHero.teleport))
        call SetUnitAbilityLevel(Backpack[pid], 'A0FK', IMaxBJ(1, myHero.reveal))

        //hero proficiencies / inner resistances
            
        if HeroID[pid] == HERO_PHOENIX_RANGER then
            set HERO_PROF[pid]      = PROF_BOW + PROF_LEATHER
            set DmgBase[pid]        = 2.0
            set DealtDmgBase[pid]   = 1.3
            set SpellTakenBase[pid] = 1.8
        elseif HeroID[pid] == HERO_DARK_SUMMONER then
            set HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.8
            set DealtDmgBase[pid]   = 1.0
            set SpellTakenBase[pid] = 1.6
        elseif HeroID[pid] == HERO_BARD then
            set HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.8
            set DealtDmgBase[pid]   = 1.0
            set SpellTakenBase[pid] = 1.6
        elseif HeroID[pid] == HERO_ARCANIST then
            set HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.8
            set DealtDmgBase[pid]   = 1.0
            set SpellTakenBase[pid] = 1.6
        elseif HeroID[pid] == HERO_MASTER_ROGUE then
            set HERO_PROF[pid]      = PROF_DAGGER + PROF_LEATHER
            set DmgBase[pid]        = 1.6
            set DealtDmgBase[pid]   = 1.25
            set SpellTakenBase[pid] = 1.8
        elseif HeroID[pid] == HERO_THUNDERBLADE then
            set HERO_PROF[pid]      = PROF_DAGGER + PROF_LEATHER
            set DmgBase[pid]        = 1.6
            set DealtDmgBase[pid]   = 1.25
            set SpellTakenBase[pid] = 1.8
        elseif HeroID[pid] == HERO_HYDROMANCER then
            set HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.8
            set DealtDmgBase[pid]   = 1.0
            set SpellTakenBase[pid] = 1.6
        elseif HeroID[pid] == HERO_HIGH_PRIEST then
            set HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.8
            set DealtDmgBase[pid]   = 1.0
            set SpellTakenBase[pid] = 1.6
        elseif HeroID[pid] == HERO_ELEMENTALIST then
            set HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.8
            set DealtDmgBase[pid]   = 1.0
            set SpellTakenBase[pid] = 1.6
        elseif HeroID[pid] == HERO_BLOODZERKER then
            set HERO_PROF[pid]      = PROF_HEAVY + PROF_SWORD + PROF_PLATE
            set DmgBase[pid]        = 1.6
            set DealtDmgBase[pid]   = 1.2
            set SpellTakenBase[pid] = 1.8
        elseif HeroID[pid] == HERO_WARRIOR then
            set HERO_PROF[pid]      = PROF_HEAVY + PROF_SWORD + PROF_PLATE + PROF_FULLPLATE
            set DmgBase[pid]        = 1.1
            set DealtDmgBase[pid]   = 1.2
            set SpellTakenBase[pid] = 1.5
        elseif HeroID[pid] == HERO_ROYAL_GUARDIAN then
            set HERO_PROF[pid]      = PROF_HEAVY + PROF_SWORD + PROF_PLATE + PROF_FULLPLATE
            set DmgBase[pid]        = 0.9
            set DealtDmgBase[pid]   = 1.2
            set SpellTakenBase[pid] = 1.5
            call BlzUnitHideAbility(Hero[pid], 'A06K', true)
        elseif HeroID[pid] == HERO_OBLIVION_GUARD then
            set HERO_PROF[pid]      = PROF_HEAVY + PROF_PLATE + PROF_FULLPLATE
            set DmgBase[pid]        = 1.0
            set DealtDmgBase[pid]   = 1.2
            set SpellTakenBase[pid] = 1.3
            set BodyOfFireCharges[pid] = 5 //default

            if GetLocalPlayer() == Player(pid - 1) then
                call BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\PASBodyOfFire" + I2S(BodyOfFireCharges[pid]) + ".blp")
            endif
        elseif HeroID[pid] == HERO_VAMPIRE then
            set HERO_PROF[pid]      = PROF_HEAVY + PROF_PLATE + PROF_DAGGER + PROF_LEATHER
            set DmgBase[pid]        = 1.5
            set DealtDmgBase[pid]   = 1.25
            set SpellTakenBase[pid] = 1.5
        elseif HeroID[pid] == HERO_ARCANE_WARRIOR then
            set HERO_PROF[pid]      = PROF_HEAVY + PROF_FULLPLATE + PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.1
            set DealtDmgBase[pid]   = 1.2
            set SpellTakenBase[pid] = 1.1
        elseif HeroID[pid] == HERO_DARK_SAVIOR or HeroID[pid] == HERO_DARK_SAVIOR_DEMON then
            set HERO_PROF[pid]      = PROF_SWORD + PROF_PLATE + PROF_STAFF + PROF_CLOTH
            set DmgBase[pid]        = 1.6
            set DealtDmgBase[pid]   = 1.2
            set SpellTakenBase[pid] = 1.0
        elseif HeroID[pid] == HERO_SAVIOR then
            set HERO_PROF[pid]      = PROF_HEAVY + PROF_FULLPLATE + PROF_PLATE + PROF_SWORD
            set DmgBase[pid]        = 1.2
            set DealtDmgBase[pid]   = 1.2
            set SpellTakenBase[pid] = 1.3
        elseif HeroID[pid] == HERO_ASSASSIN then
            set HERO_PROF[pid]      = PROF_DAGGER + PROF_LEATHER
            set DmgBase[pid]        = 1.6
            set DealtDmgBase[pid]   = 1.25
            set SpellTakenBase[pid] = 1.8
        elseif HeroID[pid] == HERO_MARKSMAN or HeroID[pid] == HERO_MARKSMAN_SNIPER then
            set HERO_PROF[pid]      = PROF_BOW + PROF_LEATHER
            set DmgBase[pid]        = 2.0
            set DealtDmgBase[pid]   = 1.3
            set SpellTakenBase[pid] = 1.8
        endif
        
        //load items
        if load then
            //load saved bp skin
            if CosmeticTable[StringHash(User[p].name)][myHero.skin] > 0 then
                set Profile[pid].skin = myHero.skin
            endif

            set i = 0

            loop
                exitwhen i > 5
                if myHero.items[i] != 0 then
                    call UnitAddItem(Hero[pid], myHero.items[i].obj)
                    call UnitDropItemSlot(Hero[pid], myHero.items[i].obj, i)
                endif

                if myHero.items[i + 6] != 0 then
                    call UnitAddItem(Backpack[pid], myHero.items[i + 6].obj)
                    call UnitDropItemSlot(Backpack[pid], myHero.items[i + 6].obj, i)
                endif

                set i = i + 1
            endloop
        endif

        set p = null
    endfunction

endlibrary
