library Level requires Functions, Table

function LevelUp takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local player p = GetOwningPlayer(u)
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local item itm
    
    if GetUnitTypeId(u) == HERO_DARK_SUMMONER then //summoning improvement level
        call SetUnitAbilityLevel(u, 'A022', R2I(GetHeroLevel(u) / 10.) + 1)
    endif
    
    if GetUnitTypeId(u) == HERO_DARK_SAVIOR then //dark seal level
        call SetUnitAbilityLevel(u, 'A0GO', R2I(GetHeroLevel(u) / 100.) + 1)
    endif

    if u == Hero[pid] then
        call SuspendHeroXP(Backpack[pid], false)
        call SetHeroLevel(Backpack[pid],GetHeroLevel(Hero[pid]),false)
        call SuspendHeroXP(Backpack[pid], true)
    endif

    //handle duds
    loop
        exitwhen i > 5
        set itm = UnitItemInSlot(Backpack[pid], i) 
        if IsItemDud(itm) and (GetHeroLevel(Hero[pid])) >= ItemData[GetItemTypeId(itm)][StringHash("level")] then
            call DudToItem(itm, Backpack[pid], 0, 0)
        endif

        set i = i + 1
    endloop
    
    call MultiboardSetItemValueBJ(MULTI_BOARD, 5, udg_MultiBoardsSpot[pid], I2S(GetHeroLevel(Hero[pid])))
    
    call ExperienceControl(pid)

    set u = null
    set p = null
    set itm = null
endfunction

//===========================================================================
function LevelInit takes nothing returns nothing
    local trigger level = CreateTrigger()
    local User u = User.first
    
    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerUnitEvent(level, u.toPlayer(), EVENT_PLAYER_HERO_LEVEL, function boolexp)
        set u = u.next
    endloop
    
	call TriggerAddAction(level, function LevelUp)

    set level = null
endfunction

endlibrary
