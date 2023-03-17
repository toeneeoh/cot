library Regions requires Functions, Chaos

globals
    rect array RegionCount
    rect array AREAS
    boolean GUARD_CAPTURED = false
endglobals

function NagaWaygate takes integer pid returns nothing
    local group ug = CreateGroup()
    local unit target

    call GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Reward, Condition(function ischar))

    if BlzGroupGetSize(ug) == 0 then
        call RemoveUnitTimed(nagachest, 2.5)
        if NAGA_FLOOR == 1 then
            call BlackMask(NAGA_GROUP, 2, 2)
            call DungeonMove(NAGA_GROUP, -20000, -4600, 2, gg_rct_Naga_Dungeon_Vision)
            call RemoveUnitTimed(nagatp, 2.)
            call NagaSpawnFloor(NAGA_FLOOR + 1)
        elseif NAGA_FLOOR == 2 then
            call BlackMask(NAGA_GROUP, 2, 2)
            call DungeonMove(NAGA_GROUP, -24192, -10500, 2, gg_rct_Naga_Dungeon_Boss_Vision)
            call RemoveUnitTimed(nagatp, 2.)
            call NagaSpawnFloor(NAGA_FLOOR + 1)
        elseif NAGA_FLOOR == 3 then //exit
            if IsPlayerInForce(Player(pid - 1), NAGA_GROUP) then
                call ForceRemovePlayer(NAGA_GROUP, Player(pid - 1))
                call ShowUnit(HeroGrave[pid], true)
                call SetUnitPosition(HeroGrave[pid], -260, 100)
                call ShowUnit(HeroGrave[pid], false)
                call SetUnitXBounded(Hero[pid], -260)
                call SetUnitYBounded(Hero[pid], 100)
                call SetCameraBoundsRectForPlayerEx(Player(pid - 1), gg_rct_Main_Map_Vision)
                call PanCameraToTimedForPlayer(Player(pid - 1), -260, 100, 0)
                //bind token on leave
                call StoreItems(pid)
            endif

            if CountPlayersInForceBJ(NAGA_GROUP) <= 0 then
                call RemoveUnitTimed(nagatp, 2.)

                loop
                    set target = FirstOfGroup(NAGA_ENEMIES)
                    exitwhen target == null
                    call GroupRemoveUnit(NAGA_ENEMIES, target)
                    call RemoveUnit(target)
                endloop
            endif
        endif
    endif

    call DestroyGroup(ug)
    
    set ug = null
endfunction

function BossEject takes unit u returns boolean
    local integer i = 0

    loop
        exitwhen i > BOSS_TOTAL
        if u == Boss[i] then
            call SetUnitPositionLoc(u, BossLoc[i])
            return true
        endif

        set i = i + 1
    endloop
    
    return false
endfunction

function LeaveZone takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local real x = GetUnitX(u)
    local real y = GetUnitY(u)
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local User U = User.first

    if u == gg_unit_H01Y_0099 or u == gg_unit_H01T_0259 then //prevent paladin, sponsor, villagers from leaving
        if pallyENRAGE and u == gg_unit_H01T_0259 then
            call PaladinEnrage(false)
        endif
        
        call IssuePointOrderLoc(u, "move", TownCenter)

    elseif IsUnitInRangeXY(u, GetRectCenterX(gg_rct_Town_Boundry), GetRectCenterY(gg_rct_Town_Boundry), 4000.) and pid == PLAYER_NEUTRAL_PASSIVE + 1 then
        call IssuePointOrderLoc(u, "move", TownCenter)
    endif
    
    set u = null
endfunction

function SafeZones takes nothing returns boolean
    local unit u = GetFilterUnit()
    local integer uid = GetUnitTypeId(u)
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local real x = GetUnitX(u)
    local real y = GetUnitY(u)
    local rect r
    local User U = User.first
    
    if IsEnemy(pid) and (IsUnitInRangeXY(u,GetRectCenterX(gg_rct_Town_Boundry),GetRectCenterY(gg_rct_Town_Boundry),4000.) or IsUnitInRangeXY(u,GetRectCenterX(gg_rct_Top_of_Town),GetRectCenterY(gg_rct_Top_of_Town),4000.)) then
        if BossEject(u) then
        elseif UnitData[uid][StringHash("count")] > 0 then
            set r = SelectGroupedRegion(UnitData[uid][StringHash("spawn")])
            call SetUnitPosition(u, GetRandomReal(GetRectMinX(r), GetRectMaxX(r)), GetRandomReal(GetRectMinY(r), GetRectMaxY(r)))
        endif
    elseif NearbyRect(gg_rct_Town_Boundry, x, y) and uid == 'h04A' then //rescue guard
        call DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Velreon Scholar:|r Excellent work, traveler. Perhaps you would be interested in the ancient tales of the |cffffcc00Medean Empire|r...")
        call RemoveUnit(u)
        loop
            exitwhen U == User.NULL
            call SetPlayerTechResearched(U.toPlayer(), 'R018', 1)
            set U = U.next
        endloop
    endif
    
    set u = null
    set r = null

    return false
endfunction

function EnterArea takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local real x = GetUnitX(u)
    local real y = GetUnitY(u)
    local integer id = GetUnitTypeId(u)
    local player p = GetOwningPlayer(u)
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local real angle
    local item itm
    local group ug = CreateGroup()
    local User U = User.first
    
    if NearbyRect(gg_rct_ChurchO, x, y) and u == Hero[pid] then
        call SetUnitPosition(u, 20943, 772)
        call BlzSetUnitFacingEx(u, 0.)
        call SetCameraBoundsRectForPlayerEx(p, gg_rct_ChurchRegion_Vision)
        call PanCameraToTimedForPlayer(p, 20943, 772, 0)
        call EnterWeather(u)
    elseif NearbyRect(gg_rct_ChurchIn, x, y) and u == Hero[pid] then
        call SetUnitPosition( u, 448.7, 1600.0 )
        call BlzSetUnitFacingEx(u, 270.)
        call SetCameraBoundsRectForPlayerEx( p, gg_rct_Main_Map_Vision )
        call PanCameraToTimedForPlayer( p, 448.7, 1600.0, 0 )
        call EnterWeather(u)
        if LEFT_CHURCH[pid] == false then
            set LEFT_CHURCH[pid] = true
            call DisplayTimedTextToPlayer(p, 0, 0, 30., "You may now save.")
        endif
    elseif NearbyRect(gg_rct_Tavern_Out, x, y) and u == Hero[pid] then
        call SetUnitPosition(u, 22191., 3441.)
        call BlzSetUnitFacingEx(u, 180.)
        call SetCameraBoundsRectForPlayerEx( p, gg_rct_Tavern_Vision)
        call PanCameraToTimedForPlayer( p, GetUnitX(u), GetUnitY(u), 0.)
        call EnterWeather(u)
        call ShowHeroCircle(p, false)
    elseif NearbyRect(gg_rct_Tavern_In, x, y) and u == Hero[pid] then
        call SetUnitPosition(u, -690., -238.)
        call BlzSetUnitFacingEx(u, 0.)
        call SetCameraBoundsRectForPlayerEx( p, gg_rct_Main_Map_Vision)
        call PanCameraToTimedForPlayer( p, GetUnitX(u), GetUnitY(u), 0.)
        call EnterWeather(u)
        call ShowHeroCircle(p, true)
    elseif NearbyRect(gg_rct_Devourer_entry, x, y) and u == Hero[pid] then
        call SetUnitPosition( u, 27145, -5489 )
        call SetCameraBoundsRectForPlayerEx( p, gg_rct_Devourer_Camera_Bounds )
        call PanCameraToTimedForPlayer( p, 27145, -5489, 0 )
        call EnterWeather(u)
    elseif NearbyRect(gg_rct_Naga_Waygate, x, y) and u == Hero[pid] then //naga dungeon
        call NagaWaygate(pid)
    elseif NearbyRect(gg_rct_Flee_Devourers, x, y) then
        if u == Hero[pid] then
            call SetUnitPosition( u, -15245, -14100 )
            call SetCameraBoundsRectForPlayerEx( p, gg_rct_Main_Map_Vision )
            call PanCameraToTimedForPlayer( p, -15245, -14100, 0 )
            call EnterWeather(u)
        elseif id == 'h04A' then
            call SetUnitPosition( u, -15245, -14100)
        endif
    elseif NearbyRect(gg_rct_Enter_Tomb, x, y) and u == Hero[pid] then
        call SetUnitPosition( u, 19709, -20237 )
        call SetCameraBoundsRectForPlayerEx( p, gg_rct_TombCameraBounds )
        call PanCameraToTimedForPlayer( p, 19709, -20237, 0 )
        call EnterWeather(u)
    elseif NearbyRect(gg_rct_Exit_Tomb, x, y) and u == Hero[pid] then
        call SetUnitPosition( u, -15426, 9535 )
        call SetCameraBoundsRectForPlayerEx( p, gg_rct_Main_Map_Vision )
        call PanCameraToTimedForPlayer( p, -15426, 9535, 0 )
        call EnterWeather(u)
    elseif NearbyRect(gg_rct_Key_Quest, x, y) and not udg_Chaos_World_On and not IsUnitHidden(gg_unit_n0A1_0164) then
        if (HasItemType(Hero[pid], 'I04J') or HasItemType(Hero[pid], 'I0NJ') or HasItemType(Backpack[pid], 'I04J') or HasItemType(Backpack[pid], 'I0NJ') or GetHeroLevel(Hero[pid]) > 239) and IsQuestCompleted(udg_Key_Quest) == false then
            call DisplayTextToForce(FORCE_PLAYING, "|cffffcc00The portal to the gods has opened.|r")
            call QuestSetDiscovered(udg_Key_Quest, true)
            call QuestSetCompleted(udg_Key_Quest, true)
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_UPDATED, "|cffffcc00QUEST COMPLETED:|r\nThe Goddesses' Keys")
            call DestroyEffect(udg_TalkToMe13)
            call TriggerSleepAction(1.00)
            call OpenGodsPortal()
        endif
        if IsQuestDiscovered(udg_Key_Quest) == false then
            call DestroyEffect(udg_TalkToMe13)
            call QuestSetDiscovered(udg_Key_Quest, true)
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1REQUIRED QUEST|r
The Goddesses' Keys
   - Retrieve the Key of the Gods")
        elseif IsQuestCompleted(udg_Key_Quest) == false then
            if HasItemType(Hero[pid], 'I0M7') then
                set itm = GetItemFromUnit(Hero[pid], 'I0M7')
            elseif HasItemType(Backpack[pid], 'I0M7') then
                set itm = GetItemFromUnit(Backpack[pid], 'I0M7')
            endif
            if GetItemTypeId(itm) == 'I0M7' then
                call UnitRemoveItem(Hero[pid], itm)
                call RemoveItem(itm)
                call QuestSetCompleted(udg_Key_Quest, true)
                call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_UPDATED, "|cffffcc00QUEST COMPLETED:|r\nThe Goddesses' Keys")
                call TriggerSleepAction(1.00)
                call OpenGodsPortal()
            endif
        endif
    elseif NearbyRect(gg_rct_Rescueable_Worker, x, y) and u == Hero[pid] and GUARD_CAPTURED == false then //guard
        set GUARD_CAPTURED = true
        call DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Velreon Scholar:|r Thank the lords! If you could escort me back to town I will be able to share the wealth of knowledge I have obtained.")
        call SetUnitOwner(gg_unit_h04A_0438, p, true)
    endif

    call DestroyGroup(ug)
    
    set ug = null
    set u = null
    set itm = null
    set p = null
endfunction

//===========================================================================
function RegionsInit takes nothing returns nothing
    local region enterRegion = CreateRegion()
    local region leaveRegion = CreateRegion()
    local region map = CreateRegion()
    local region safeRegion = CreateRegion()
    local trigger safezone = CreateTrigger()
    local trigger enterzone = CreateTrigger() 
    local trigger villagerleave = CreateTrigger()
    
    set AREAS[0] = gg_rct_Main_Map
    set AREAS[1] = gg_rct_Tavern
    set AREAS[2] = gg_rct_Infinite_Struggle
    set AREAS[3] = gg_rct_Colosseum
    set AREAS[4] = gg_rct_Cave
    set AREAS[5] = gg_rct_Gods_Vision
    set AREAS[6] = gg_rct_Training_Prechaos
    set AREAS[7] = gg_rct_Training_Chaos
    set AREAS[8] = gg_rct_Church
    set AREAS[9] = gg_rct_Naga_Dungeon_Boss
    set AREAS[10] = gg_rct_Naga_Dungeon_Reward
    set AREAS[11] = gg_rct_Naga_Dungeon

    call RegionAddRect(enterRegion, gg_rct_ChurchO)
    call RegionAddRect(enterRegion, gg_rct_ChurchIn)
    call RegionAddRect(enterRegion, gg_rct_Tavern_Out)
    call RegionAddRect(enterRegion, gg_rct_Tavern_In)
    call RegionAddRect(enterRegion, gg_rct_Devourer_entry)
    call RegionAddRect(enterRegion, gg_rct_Flee_Devourers)
    call RegionAddRect(enterRegion, gg_rct_Colloseum_Monster_Spawn)
    call RegionAddRect(enterRegion, gg_rct_Colloseum_Monster_Spawn_2)
    call RegionAddRect(enterRegion, gg_rct_Colloseum_Monster_Spawn_3)
    call RegionAddRect(enterRegion, gg_rct_Rescueable_Worker)
    call RegionAddRect(enterRegion, gg_rct_Key_Quest)
    call RegionAddRect(enterRegion, gg_rct_Enter_Tomb)
    call RegionAddRect(enterRegion, gg_rct_Exit_Tomb)
    call RegionAddRect(enterRegion, gg_rct_Naga_Waygate)

    call RegionAddRect(safeRegion, gg_rct_Town_Boundry)
    call RegionAddRect(safeRegion, gg_rct_Top_of_Town)
    
    call RegionAddRect(leaveRegion, gg_rct_Town_Boundry_2)
    call RegionAddRect(leaveRegion, gg_rct_Town_boundry_4)
    
    call RegionAddRect(map, bj_mapInitialPlayableArea) 
    
    call TriggerRegisterEnterRegion(enterzone, enterRegion, Condition(function isplayerunitRegion))
    call TriggerAddAction(enterzone, function EnterArea)
    
    call TriggerRegisterEnterRegion(safezone, safeRegion, Filter(function SafeZones))
    
    call TriggerRegisterEnterRegion(villagerleave, leaveRegion, Condition(function isvillager))
    call TriggerAddAction(villagerleave, function LeaveZone)
    
    set safezone = null
    set enterzone = null
    set villagerleave = null
endfunction

endlibrary
