library PlayerManager requires Functions
    function SetPlayerGold takes player whichPlayer, integer amount returns nothing
        call SetPlayerState( whichPlayer, PLAYER_STATE_RESOURCE_GOLD, amount)
    endfunction
    
    function AddPlayerGold takes player whichPlayer, integer amount returns integer
        local integer currentGold = GetPlayerGold( whichPlayer )
        
        if currentGold + amount >= MAX_GOLD_LUMB then
            call AddPlatinumCoin(GetPlayerId(whichPlayer) + 1, 1)
            call SetPlayerGold( whichPlayer, currentGold - 1000000 + amount  )
        else
            call SetPlayerGold( whichPlayer, currentGold + amount  )
        endif

        return GetPlayerGold( whichPlayer )
    endfunction
    
    function SetPlayerLumber takes player whichPlayer, integer amount returns nothing
        call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER, amount)
    endfunction
    
    function AddPlayerLumber takes player whichPlayer, integer amount returns integer
        local integer currentLumber = GetPlayerLumber( whichPlayer )

        if currentLumber + amount >= MAX_GOLD_LUMB then
            call AddArcaditeLumber(GetPlayerId(whichPlayer) + 1, 1)
            call SetPlayerLumber( whichPlayer, currentLumber - 1000000 + amount  )
        else
            call SetPlayerLumber( whichPlayer, currentLumber + amount  )
        endif

        return GetPlayerLumber( whichPlayer )
    endfunction
    
    function ItemToIndex takes integer itemType returns integer
        return LoadInteger(SAVE_TABLE, KEY_ITEMS, itemType)
    endfunction
    
    function ItemIndexer takes item itm returns integer
        if itm == null then
            return 0
        endif

        if IsItemDud(itm) then
            return ItemToIndex(ItemData[GetHandleId(itm)][0])
        else
            return ItemToIndex(GetItemTypeId(itm))
        endif
    endfunction

    function TomeCap takes integer heroLevel returns integer
        return R2I(Pow(heroLevel, 3) * 0.002 + 10 * heroLevel)
    endfunction
    
    function CharacterSetup takes integer pid, boolean load returns nothing
        local HeroData myHero = Profiles[pid].hd
        local player p = Player(pid - 1)
        local integer i = 0

		set ItemSpelldef[pid] = 1
		set ItemTotaldef[pid] = 1

        if load then
            set Hero[pid] = CreateUnit(p, udg_SaveUnitType[myHero.id], GetRectCenterX(gg_rct_ChurchSpawn), GetRectCenterY(gg_rct_ChurchSpawn), 270.)
            set HeroID[pid] = GetUnitTypeId(Hero[pid])
            set urhome[pid] = 0 
            set hselection[pid] = false
            set udg_Hardcore[pid] = (myHero.hardcore > 0)

            call SetPlayerGold(p, myHero.gold)
            call SetPlayerLumber(p, myHero.lumber)
            if myHero.arcadite + myHero.platinum + myHero.crystal > 20000 then
                call DisplayTextToPlayer(p, 0, 0, "You had too many crystals so you dropped everything on your way here.")
            else
                call AddArcaditeLumber(pid, myHero.arcadite)
                call AddPlatinumCoin(pid, myHero.platinum)
                call AddCrystals(pid, myHero.crystal)
            endif
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
            //set hd values here?
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
        call BlzSetUnitSkin(Backpack[pid], 'H011')
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

        call UpdateTooltips()

        set i = 0
        loop
            exitwhen i > 5

            if myHero.items[6 + i] != null then
                call UnitAddItem(Backpack[pid], myHero.items[6 + i])
                call UnitDropItemSlot(Backpack[pid], myHero.items[6 + i], i)
            endif

            set i = i + 1
        endloop

        call SetUnitAbilityLevel(Backpack[pid], 'A0FV', IMaxBJ(1, myHero.teleport))
        call SetUnitAbilityLevel(Backpack[pid], 'A02J', IMaxBJ(1, myHero.teleport))
        call SetUnitAbilityLevel(Backpack[pid], 'A0FK', IMaxBJ(1, myHero.reveal))
            
        if HeroID[pid] == HERO_PHOENIX_RANGER then
            set udg_HeroCanUseBow[pid] = true
            set udg_HeroCanUseLeather[pid] = true
            set DmgBase[pid]=2.0
            set DealtDmgBase[pid]=1.3
            set SpellTakenBase[pid]=1.8
            call UnitDisableAbility(Hero[pid], 'A047', true)
            call BlzUnitHideAbility(Hero[pid], 'A047', true)
        elseif HeroID[pid] == HERO_DARK_SUMMONER then
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.8
            set DealtDmgBase[pid]=1.0
            set SpellTakenBase[pid]=1.6
        elseif HeroID[pid] == HERO_BARD then
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.8
            set DealtDmgBase[pid]=1.0
            set SpellTakenBase[pid]=1.6
        elseif HeroID[pid] == HERO_ARCANIST then
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.8
            set DealtDmgBase[pid]=1.0
            set SpellTakenBase[pid]=1.6
        elseif HeroID[pid] == HERO_MASTER_ROGUE then
            set udg_HeroCanUseDagger[pid] = true
            set udg_HeroCanUseLeather[pid] = true
            set DmgBase[pid]=1.6
            set DealtDmgBase[pid]=1.25
            set SpellTakenBase[pid]=1.8
        elseif HeroID[pid] == HERO_THUNDERBLADE then
            set udg_HeroCanUseDagger[pid] = true
            set udg_HeroCanUseLeather[pid] = true
            set DmgBase[pid]=1.6
            set DealtDmgBase[pid]=1.25
            set SpellTakenBase[pid]=1.8
        elseif HeroID[pid] == HERO_HYDROMANCER then
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.8
            set DealtDmgBase[pid]=1.0
            set SpellTakenBase[pid]=1.6
        elseif HeroID[pid] == HERO_HIGH_PRIEST then
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.8
            set DealtDmgBase[pid]=1.0
            set SpellTakenBase[pid]=1.6
        elseif HeroID[pid] == HERO_ELEMENTALIST then
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.8
            set DealtDmgBase[pid]=1.0
            set SpellTakenBase[pid]=1.6
        elseif HeroID[pid] == HERO_BLOODZERKER then
            set udg_HeroCanUseHeavy[pid] = true
            set udg_HeroCanUseShortSword[pid] = true
            set udg_HeroCanUsePlate[pid] = true
            set DmgBase[pid]=1.6
            set DealtDmgBase[pid]=1.2
            set SpellTakenBase[pid]=1.8
        elseif HeroID[pid] == HERO_WARRIOR then
            set udg_HeroCanUseHeavy[pid]= true
            set udg_HeroCanUseShortSword[pid]= true
            set udg_HeroCanUsePlate[pid]= true
            set udg_HeroCanUseFullPlate[pid]= true
            set DmgBase[pid]=1.1
            set DealtDmgBase[pid]=1.2
            set SpellTakenBase[pid]=1.5
        elseif HeroID[pid] == HERO_ROYAL_GUARDIAN then
            set udg_HeroCanUseHeavy[pid] = true
            set udg_HeroCanUseShortSword[pid] = true
            set udg_HeroCanUseFullPlate[pid] = true
            set udg_HeroCanUsePlate[pid] = true
            set DmgBase[pid]=0.9
            set DealtDmgBase[pid]=1.2
            set SpellTakenBase[pid]=1.5
            call BlzUnitHideAbility(Hero[pid], 'A06K', true)
        elseif HeroID[pid] == HERO_INFERNAL then
            set udg_HeroCanUseHeavy[pid] = true
            set udg_HeroCanUseFullPlate[pid] = true
            set udg_HeroCanUsePlate[pid] = true
            set DmgBase[pid]=1.0
            set DealtDmgBase[pid]=1.2
            set SpellTakenBase[pid]=1.3
        elseif HeroID[pid] == HERO_VAMPIRE then
            set udg_HeroCanUseHeavy[pid] = true
            set udg_HeroCanUsePlate[pid] = true
            set udg_HeroCanUseDagger[pid] = true
            set udg_HeroCanUseLeather[pid] = true
            set DmgBase[pid]=1.5
            set DealtDmgBase[pid]=1.25
            set SpellTakenBase[pid]=1.5
        elseif HeroID[pid] == HERO_ARCANE_WARRIOR then
            set udg_HeroCanUseFullPlate[pid] = true
            set udg_HeroCanUseHeavy[pid] = true
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.1
            set DealtDmgBase[pid]=1.2
            set SpellTakenBase[pid]=1.1
        elseif HeroID[pid] == HERO_DARK_SAVIOR or HeroID[pid] == HERO_DARK_SAVIOR_DEMON then
            set udg_HeroCanUseShortSword[pid] = true
            set udg_HeroCanUseStaff[pid] = true
            set udg_HeroCanUsePlate[pid] = true
            set udg_HeroCanUseCloth[pid] = true
            set DmgBase[pid]=1.6
            set DealtDmgBase[pid]=1.2
            set SpellTakenBase[pid]=1.0
        elseif HeroID[pid] == HERO_SAVIOR then
            set udg_HeroCanUseShortSword[pid] = true
            set udg_HeroCanUseHeavy[pid] = true
            set udg_HeroCanUsePlate[pid] = true
            set udg_HeroCanUseFullPlate[pid] = true
            set DmgBase[pid]=1.2
            set DealtDmgBase[pid]=1.2
            set SpellTakenBase[pid]=1.3
        elseif HeroID[pid] == HERO_ASSASSIN then
            set udg_HeroCanUseDagger[pid] = true
            set udg_HeroCanUseLeather[pid] = true
            set DmgBase[pid]=1.6
            set DealtDmgBase[pid]=1.25
            set SpellTakenBase[pid]=1.8
        elseif HeroID[pid] == HERO_MARKSMAN or HeroID[pid] == HERO_MARKSMAN_SNIPER then
            set udg_HeroCanUseBow[pid] = true
            set udg_HeroCanUseLeather[pid] = true
            set DmgBase[pid]=2.0
            set DealtDmgBase[pid]=1.3
            set SpellTakenBase[pid]=1.8
        endif
        
        if udg_HeroCanUsePlate[pid] then
            call SaveBoolean(PlayerProf,pid,1,true)
        endif
        if udg_HeroCanUseFullPlate[pid] then
            call SaveBoolean(PlayerProf,pid,2,true)
        endif
        if udg_HeroCanUseLeather[pid] then
            call SaveBoolean(PlayerProf,pid,3,true)
        endif
        if udg_HeroCanUseCloth[pid] then
            call SaveBoolean(PlayerProf,pid,4,true)
        endif
        if udg_HeroCanUseHeavy[pid] then
            call SaveBoolean(PlayerProf,pid,6,true)
        endif
        if udg_HeroCanUseShortSword[pid] then
            call SaveBoolean(PlayerProf,pid,7,true)
        endif
        if udg_HeroCanUseDagger[pid] then
            call SaveBoolean(PlayerProf,pid,8,true)
        endif
        if udg_HeroCanUseBow[pid] then
            call SaveBoolean(PlayerProf,pid,9,true)
        endif
        if udg_HeroCanUseStaff[pid] then
            call SaveBoolean(PlayerProf,pid,10,true)
        endif
        
        if load then
            //give items
            set i = 0
            loop
                exitwhen i > 5
                if myHero.items[i] != null then
                    call UnitAddItem(Hero[pid], myHero.items[i])
                    call UnitDropItemSlot(Hero[pid], myHero.items[i], i)
                endif
                set i = i + 1
            endloop
        endif

        set p = null
    endfunction

endlibrary
