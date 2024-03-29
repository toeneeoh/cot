library Level requires Functions

function LevelUp takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local player p = GetOwningPlayer(u)
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local Item itm
    local integer level = GetHeroLevel(u)
    local integer uid = GetUnitTypeId(u)
    
    if u == Hero[pid] then
        if uid == HERO_DARK_SUMMONER then //summoning improvement level
            call SetUnitAbilityLevel(u, 'A022', R2I(GetHeroLevel(u) / 10.) + 1)
        endif
        
        if uid == HERO_DARK_SAVIOR then //dark seal level
            call SetUnitAbilityLevel(u, 'A0GO', R2I(GetHeroLevel(u) / 100.) + 1)
        endif

        if uid == HERO_SAVIOR then //light seal level
            call SetUnitAbilityLevel(u, LIGHTSEAL.id, R2I(GetHeroLevel(u) / 100.) + 1)
        endif

        if uid == HERO_OBLIVION_GUARD then //body of fire level
            call SetUnitAbilityLevel(u, BODYOFFIRE.id, R2I(GetHeroLevel(u) / 100.) + 1)
        endif

        if uid == HERO_MARKSMAN or uid == HERO_MARKSMAN_SNIPER then //sniper stance level
            call SetUnitAbilityLevel(u, SNIPERSTANCE.id, R2I(GetHeroLevel(u) / 50.) + 1)
        endif
        
        if level >= 180 and urhome[pid] <= 4 then
            call SoundHandler("Sound\\Interface\\SecretFound.wav", false, p, null)
            call DisplayTimedTextToPlayer(p, 0, 0, 60., "|cffff0000You have reached level 180 and no longer earn experience with regular homes, you must purchase a chaotic home!")
        elseif level <= 15 and urhome[pid] == 0 then
            call SoundHandler("Sound\\Interface\\SecretFound.wav", false, p, null)
            call DisplayTimedTextToPlayer(p, 0, 0, 60., "You will stop gaining experience after level 15 without a home, purchase one from the vendors in town and build it near a gold mine.")
        endif

        call SuspendHeroXP(Backpack[pid], false)
        call SetHeroLevel(Backpack[pid],GetHeroLevel(Hero[pid]),false)
        call SuspendHeroXP(Backpack[pid], true)

        //handle duds
        loop
            exitwhen i > 5
            set itm = Item[UnitItemInSlot(Backpack[pid], i)]
            if IsItemDud(itm) and (GetHeroLevel(Hero[pid])) >= ItemData[itm.id][ITEM_LEVEL_REQUIREMENT] then
                call itm.toItem()
            endif

            set i = i + 1
        endloop
        
        call MultiboardSetItemValueBJ(MULTI_BOARD, 5, udg_MultiBoardsSpot[pid], I2S(GetHeroLevel(Hero[pid])))
        
        call ExperienceControl(pid)
    endif

    set u = null
    set p = null
endfunction

//===========================================================================
function LevelInit takes nothing returns nothing
    local trigger level = CreateTrigger()
    local User u = User.first
    
    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerUnitEvent(level, u.toPlayer(), EVENT_PLAYER_HERO_LEVEL, null)
        set u = u.next
    endloop
    
	call TriggerAddAction(level, function LevelUp)

    set level = null
endfunction

endlibrary
