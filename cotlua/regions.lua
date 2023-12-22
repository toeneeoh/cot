if Debug then Debug.beginFile 'Regions' end

OnInit.final("Regions", function(require)
    require 'Variables'
    require 'Helper'

    RegionCount={} ---@type rect[] 
    AREAS={} ---@type rect[] 
    GUARD_CAPTURED         = false ---@type boolean 

---@param pid integer
function NagaWaygate(pid)
    local ug       = CreateGroup()
    local target ---@type unit 

    GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Reward, Condition(ischar))

    if BlzGroupGetSize(ug) == 0 then
        TimerQueue:callDelayed(2.5, RemoveUnit, nagachest)
        if NAGA_FLOOR == 1 then
            BlackMask(NAGA_GROUP, 2, 2)
            DungeonMove(NAGA_GROUP, -20000, -4600, 2, gg_rct_Naga_Dungeon_Vision)
            TimerQueue:callDelayed(2., RemoveUnit, nagatp)
            NagaSpawnFloor(NAGA_FLOOR + 1)
        elseif NAGA_FLOOR == 2 then
            BlackMask(NAGA_GROUP, 2, 2)
            DungeonMove(NAGA_GROUP, -24192, -10500, 2, gg_rct_Naga_Dungeon_Boss_Vision)
            TimerQueue:callDelayed(2., RemoveUnit, nagatp)
            NagaSpawnFloor(NAGA_FLOOR + 1)
        elseif NAGA_FLOOR == 3 then --exit
            if IsPlayerInForce(Player(pid - 1), NAGA_GROUP) then
                ForceRemovePlayer(NAGA_GROUP, Player(pid - 1))
                ShowUnit(HeroGrave[pid], true)
                SetUnitPosition(HeroGrave[pid], -260, 100)
                ShowUnit(HeroGrave[pid], false)
                SetUnitXBounded(Hero[pid], -260)
                SetUnitYBounded(Hero[pid], 100)
                SetCameraBoundsRectForPlayerEx(Player(pid - 1), gg_rct_Main_Map_Vision)
                PanCameraToTimedForPlayer(Player(pid - 1), -260, 100, 0)

                --bind token on leave
                GetItemFromPlayer(pid, FourCC('I0NN')).owner = Player(pid - 1)
            end

            if CountPlayersInForceBJ(NAGA_GROUP) <= 0 then
                TimerQueue:callDelayed(2., RemoveUnit, nagatp)

                target = FirstOfGroup(NAGA_ENEMIES)
                while target do
                    GroupRemoveUnit(NAGA_ENEMIES, target)
                    RemoveUnit(target)
                    target = FirstOfGroup(NAGA_ENEMIES)
                end
            end
        end
    end

    DestroyGroup(ug)
end

function LeaveZone()
    local u      = GetTriggerUnit() ---@type unit 
    local x      = GetUnitX(u) ---@type number 
    local y      = GetUnitY(u) ---@type number 
    local pid         = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local U      = User.first ---@type User 

    if u == gg_unit_H01Y_0099 or u == gg_unit_H01T_0259 then --prevent paladin, sponsor, villagers from leaving
        IssuePointOrderLoc(u, "move", TownCenter)

    elseif IsUnitInRangeXY(u, GetRectCenterX(gg_rct_Town_Boundry), GetRectCenterY(gg_rct_Town_Boundry), 4000.) and pid == PLAYER_NEUTRAL_PASSIVE + 1 then
        IssuePointOrderLoc(u, "move", TownCenter)
    end
end

---@return boolean
function SafeZones()
    local u      = GetFilterUnit() ---@type unit 
    local uid         = GetUnitTypeId(u) ---@type integer 
    local pid         = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local x      = GetUnitX(u) ---@type number 
    local y      = GetUnitY(u) ---@type number 
    local r ---@type rect 
    local U      = User.first ---@type User 
    local boss         = IsBoss(uid) ---@type integer 

    if IsUnitIllusion(u) then
    elseif IsEnemy(pid) and (IsUnitInRangeXY(u,GetRectCenterX(gg_rct_Town_Boundry),GetRectCenterY(gg_rct_Town_Boundry),4000.) or IsUnitInRangeXY(u,GetRectCenterX(gg_rct_Top_of_Town),GetRectCenterY(gg_rct_Top_of_Town),4000.)) then
        if boss ~= -1 then
            SetUnitXBounded(Boss[boss], GetLocationX(BossLoc[boss]))
            SetUnitYBounded(Boss[boss], GetLocationY(BossLoc[boss]))
        elseif UnitData[uid][UNITDATA_COUNT] > 0 then
            r = SelectGroupedRegion(UnitData[uid][UNITDATA_SPAWN])
            SetUnitPosition(u, GetRandomReal(GetRectMinX(r), GetRectMaxX(r)), GetRandomReal(GetRectMinY(r), GetRectMaxY(r)))
        end
    elseif NearbyRect(gg_rct_Town_Boundry, x, y) and uid == FourCC('h04A') then --rescue guard
        DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Velreon Scholar:|r Excellent work, traveler. Perhaps you would be interested in the ancient tales of the |cffffcc00Medean Empire|r...")
        RemoveUnit(u)
        while U do
            SetPlayerTechResearched(U.player, FourCC('R018'), 1)
            U = U.next
        end
    end

    return false
end

function EnterArea()
    local u      = GetTriggerUnit() ---@type unit 
    local x      = GetUnitX(u) ---@type number 
    local y      = GetUnitY(u) ---@type number 
    local id         = GetUnitTypeId(u) ---@type integer 
    local p        = GetOwningPlayer(u) ---@type player 
    local pid         = GetPlayerId(p) + 1 ---@type integer 
    local i         = 0 ---@type integer 
    local angle ---@type number 
    local itm ---@type item?
    local ug       = CreateGroup()
    local U      = User.first ---@type User 

    if NearbyRect(gg_rct_ChurchO, x, y) and u == Hero[pid] then
        SetUnitPosition(u, 20943, 772)
        BlzSetUnitFacingEx(u, 0.)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_ChurchRegion_Vision)
        PanCameraToTimedForPlayer(p, 20943, 772, 0)
    elseif NearbyRect(gg_rct_ChurchIn, x, y) and u == Hero[pid] then
        SetUnitPosition(u, 448.7, 1600.0)
        BlzSetUnitFacingEx(u, 270.)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        PanCameraToTimedForPlayer(p, 448.7, 1600.0, 0)
        if CANNOT_LOAD[pid] == false then
            CANNOT_LOAD[pid] = true
            DisplayTimedTextToPlayer(p, 0, 0, 30., "You may now save.")
        end
    elseif NearbyRect(gg_rct_Tavern_Out, x, y) and u == Hero[pid] then
        SetUnitPosition(u, 22191., 3441.)
        BlzSetUnitFacingEx(u, 180.)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Tavern_Vision)
        PanCameraToTimedForPlayer(p, GetUnitX(u), GetUnitY(u), 0.)
        ShowHeroCircle(p, false)
    elseif NearbyRect(gg_rct_Tavern_In, x, y) and u == Hero[pid] then
        SetUnitPosition(u, -690., -238.)
        BlzSetUnitFacingEx(u, 0.)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        PanCameraToTimedForPlayer(p, GetUnitX(u), GetUnitY(u), 0.)
        ShowHeroCircle(p, true)
    elseif NearbyRect(gg_rct_Devourer_entry, x, y) and u == Hero[pid] then
        SetUnitPosition(u, 27145, -5489)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Devourer_Camera_Bounds)
        PanCameraToTimedForPlayer(p, 27145, -5489, 0)
    elseif NearbyRect(gg_rct_Naga_Waygate, x, y) and u == Hero[pid] then --naga dungeon
        NagaWaygate(pid)
    elseif NearbyRect(gg_rct_Flee_Devourers, x, y) then
        if u == Hero[pid] then
            SetUnitPosition(u, -15245, -14100)
            SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
            PanCameraToTimedForPlayer(p, -15245, -14100, 0)
        elseif id == FourCC('h04A') then
            SetUnitPosition(u, -15245, -14100)
        end
    elseif NearbyRect(gg_rct_Enter_Tomb, x, y) and u == Hero[pid] then
        SetUnitPosition(u, 19709, -20237)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_TombCameraBounds)
        PanCameraToTimedForPlayer(p, 19709, -20237, 0)
    elseif NearbyRect(gg_rct_Exit_Tomb, x, y) and u == Hero[pid] then
        SetUnitPosition(u, -15426, 9535)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        PanCameraToTimedForPlayer(p, -15426, 9535, 0)
    elseif NearbyRect(gg_rct_Key_Quest, x, y) and not ChaosMode and not IsUnitHidden(god_angel) then
        if (HasItemType(Hero[pid], FourCC('I04J')) or HasItemType(Hero[pid], FourCC('I0NJ')) or HasItemType(Backpack[pid], FourCC('I04J')) or HasItemType(Backpack[pid], FourCC('I0NJ')) or GetHeroLevel(Hero[pid]) > 239) and IsQuestCompleted(Key_Quest) == false then
            DisplayTextToForce(FORCE_PLAYING, "|cffffcc00The portal to the gods has opened.|r")
            QuestSetDiscovered(Key_Quest, true)
            QuestSetCompleted(Key_Quest, true)
            QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_UPDATED, "|cffffcc00QUEST COMPLETED:|r\nThe Goddesses' Keys")
            DestroyEffect(TalkToMe13)
            TimerQueue:callDelayed(1., OpenGodsPortal)
        end
        if IsQuestDiscovered(Key_Quest) == false then
            DestroyEffect(TalkToMe13)
            QuestSetDiscovered(Key_Quest, true)
            QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1REQUIRED QUEST|r|nThe Goddesses' Keys|n   - Retrieve the Key of the Gods")
        elseif IsQuestCompleted(Key_Quest) == false then
            if HasItemType(Hero[pid], 'I0M7') then
                itm = GetItemFromUnit(Hero[pid], 'I0M7')
            elseif HasItemType(Backpack[pid], 'I0M7') then
                itm = GetItemFromUnit(Backpack[pid], 'I0M7')
            end
            if GetItemTypeId(itm) == 'I0M7' then
                Item[itm].destroy()
                QuestSetCompleted(Key_Quest, true)
                QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_UPDATED, "|cffffcc00QUEST COMPLETED:|r\nThe Goddesses' Keys")
                TimerQueue:callDelayed(1., OpenGodsPortal)
            end
        end
    elseif NearbyRect(gg_rct_Rescueable_Worker, x, y) and u == Hero[pid] and GUARD_CAPTURED == false then --guard
        GUARD_CAPTURED = true
        DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Velreon Scholar:|r Thank the lords! If you could escort me back to town I will be able to share the wealth of knowledge I have obtained.")
        SetUnitOwner(gg_unit_h04A_0438, p, true)
    elseif NearbyRect(gg_rct_CryptO, x, y) and u == Hero[pid] then
        SetUnitPosition(u, 20353., 11426.)
        BlzSetUnitFacingEx(u, 270.)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Crypt_Vision)
        PanCameraToTimedForPlayer(p, 20353., 11426., 0)
    elseif NearbyRect(gg_rct_CryptIn, x, y) and u == Hero[pid] then
        SetUnitPosition(u, 11793., 8501.)
        BlzSetUnitFacingEx(u, 180.)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        PanCameraToTimedForPlayer(p, 11793., 8501., 0)
    end

    DestroyGroup(ug)
end

    local enterRegion        = CreateRegion() ---@type region 
    local leaveRegion        = CreateRegion() ---@type region 
    local map        = CreateRegion() ---@type region 
    local safeRegion        = CreateRegion() ---@type region 
    local safezone         = CreateTrigger() ---@type trigger 
    local enterzone         = CreateTrigger()  ---@type trigger 
    local villagerleave         = CreateTrigger() ---@type trigger 

    AREAS[0] = gg_rct_Main_Map
    AREAS[1] = gg_rct_Tavern
    AREAS[2] = gg_rct_Infinite_Struggle
    AREAS[3] = gg_rct_Colosseum
    AREAS[4] = gg_rct_Cave
    AREAS[5] = gg_rct_Gods_Vision
    AREAS[6] = gg_rct_Training_Prechaos
    AREAS[7] = gg_rct_Training_Chaos
    AREAS[8] = gg_rct_Church
    AREAS[9] = gg_rct_Naga_Dungeon_Boss
    AREAS[10] = gg_rct_Naga_Dungeon_Reward
    AREAS[11] = gg_rct_Naga_Dungeon
    AREAS[12] = gg_rct_Crypt

    colospot[1] = GetRectCenter(gg_rct_Colloseum_Monster_Spawn)
    colospot[2] = GetRectCenter(gg_rct_Colloseum_Monster_Spawn_2)
    colospot[3] = GetRectCenter(gg_rct_Colloseum_Monster_Spawn_3)

    RegionCount[25]  = gg_rct_Troll_Demon_1
    RegionCount[26]  = gg_rct_Troll_Demon_2
    RegionCount[27]  = gg_rct_Troll_Demon_3
    RegionCount[50]  = gg_rct_Tuskar_Horror_1
    RegionCount[51]  = gg_rct_Tuskar_Horror_2
    RegionCount[52]  = gg_rct_Tuskar_Horror_3
    RegionCount[75]  = gg_rct_Spider_Horror_1
    RegionCount[76]  = gg_rct_Spider_Horror_2
    RegionCount[77]  = gg_rct_Spider_Horror_3
    RegionCount[78]  = gg_rct_Spider_Horror_4
    RegionCount[100] = gg_rct_Ursa_Abyssal_1
    RegionCount[101] = gg_rct_Ursa_Abyssal_2
    RegionCount[102] = gg_rct_Ursa_Abyssal_3
    RegionCount[103] = gg_rct_Ursa_Abyssal_4
    RegionCount[104] = gg_rct_Ursa_Abyssal_5
    RegionCount[105] = gg_rct_Ursa_Abyssal_6
    RegionCount[125] = gg_rct_Bear_1
    RegionCount[126] = gg_rct_Bear_2
    RegionCount[127] = gg_rct_Bear_3
    RegionCount[128] = gg_rct_Bear_4
    RegionCount[129] = gg_rct_Bear_5
    RegionCount[150] = gg_rct_OgreTauren_Void_1
    RegionCount[151] = gg_rct_OgreTauren_Void_2
    RegionCount[152] = gg_rct_OgreTauren_Void_3
    RegionCount[153] = gg_rct_OgreTauren_Void_4
    RegionCount[154] = gg_rct_OgreTauren_Void_5
    RegionCount[155] = gg_rct_OgreTauren_Void_6
    RegionCount[156] = gg_rct_OgreTauren_Void_7
    RegionCount[175] = gg_rct_Unbroken_Dimensional_1
    RegionCount[176] = gg_rct_Unbroken_Dimensional_2
    RegionCount[200] = gg_rct_Hell_1
    RegionCount[201] = gg_rct_Hell_2
    RegionCount[202] = gg_rct_Hell_3
    RegionCount[203] = gg_rct_Hell_4
    RegionCount[204] = gg_rct_Hell_5
    RegionCount[225] = gg_rct_Centaur_Nightmare_1
    RegionCount[226] = gg_rct_Centaur_Nightmare_2
    RegionCount[227] = gg_rct_Centaur_Nightmare_3
    RegionCount[228] = gg_rct_Centaur_Nightmare_4
    RegionCount[229] = gg_rct_Centaur_Nightmare_5
    RegionCount[250] = gg_rct_Magnataur_Despair_1
    RegionCount[275] = gg_rct_Hydra_Spawn
    RegionCount[300] = gg_rct_Dragon_Astral_1
    RegionCount[301] = gg_rct_Dragon_Astral_2
    RegionCount[302] = gg_rct_Dragon_Astral_3
    RegionCount[303] = gg_rct_Dragon_Astral_4
    RegionCount[304] = gg_rct_Dragon_Astral_5
    RegionCount[305] = gg_rct_Dragon_Astral_6
    RegionCount[306] = gg_rct_Dragon_Astral_7
    RegionCount[307] = gg_rct_Dragon_Astral_8
    RegionCount[325] = gg_rct_Devourer_Existence_1
    RegionCount[326] = gg_rct_Devourer_Existence_2
    RegionCount[350] = gg_rct_Azazoth_Circle_Spawn
    RegionCount[375] = gg_rct_Tuskar_Horror_1
    RegionCount[376] = gg_rct_Tuskar_Horror_2
    RegionCount[377] = gg_rct_Tuskar_Horror_3
    RegionCount[378] = gg_rct_Spider_Horror_1
    RegionCount[379] = gg_rct_Spider_Horror_2
    RegionCount[380] = gg_rct_Spider_Horror_3
    RegionCount[381] = gg_rct_Spider_Horror_4
    RegionCount[400] = gg_rct_Ursa_Abyssal_1
    RegionCount[401] = gg_rct_Ursa_Abyssal_2
    RegionCount[402] = gg_rct_Ursa_Abyssal_3
    RegionCount[403] = gg_rct_Ursa_Abyssal_4
    RegionCount[404] = gg_rct_Ursa_Abyssal_5
    RegionCount[405] = gg_rct_Ursa_Abyssal_6
    RegionCount[406] = gg_rct_Abyssal_Only
    RegionCount[425] = gg_rct_OgreTauren_Void_1
    RegionCount[426] = gg_rct_OgreTauren_Void_2
    RegionCount[427] = gg_rct_OgreTauren_Void_3
    RegionCount[428] = gg_rct_OgreTauren_Void_4
    RegionCount[429] = gg_rct_OgreTauren_Void_5
    RegionCount[430] = gg_rct_OgreTauren_Void_6
    RegionCount[431] = gg_rct_OgreTauren_Void_7
    RegionCount[432] = gg_rct_Void_Only
    RegionCount[450] = gg_rct_Magnataur_Despair_1
    RegionCount[451] = gg_rct_Magnataur_Despair_2


    RegionAddRect(enterRegion, gg_rct_ChurchO)
    RegionAddRect(enterRegion, gg_rct_ChurchIn)
    RegionAddRect(enterRegion, gg_rct_Tavern_Out)
    RegionAddRect(enterRegion, gg_rct_Tavern_In)
    RegionAddRect(enterRegion, gg_rct_Devourer_entry)
    RegionAddRect(enterRegion, gg_rct_Flee_Devourers)
    RegionAddRect(enterRegion, gg_rct_Colloseum_Monster_Spawn)
    RegionAddRect(enterRegion, gg_rct_Colloseum_Monster_Spawn_2)
    RegionAddRect(enterRegion, gg_rct_Colloseum_Monster_Spawn_3)
    RegionAddRect(enterRegion, gg_rct_Rescueable_Worker)
    RegionAddRect(enterRegion, gg_rct_Key_Quest)
    RegionAddRect(enterRegion, gg_rct_Enter_Tomb)
    RegionAddRect(enterRegion, gg_rct_Exit_Tomb)
    RegionAddRect(enterRegion, gg_rct_Naga_Waygate)
    RegionAddRect(enterRegion, gg_rct_CryptO)
    RegionAddRect(enterRegion, gg_rct_CryptIn)

    RegionAddRect(safeRegion, gg_rct_Town_Boundry)
    RegionAddRect(safeRegion, gg_rct_Top_of_Town)

    RegionAddRect(leaveRegion, gg_rct_Town_Boundry_2)
    RegionAddRect(leaveRegion, gg_rct_Town_boundry_4)

    RegionAddRect(map, bj_mapInitialPlayableArea)

    TriggerRegisterEnterRegion(enterzone, enterRegion, Condition(isplayerunitRegion))
    TriggerAddAction(enterzone, EnterArea)

    TriggerRegisterEnterRegion(safezone, safeRegion, Filter(SafeZones))

    TriggerRegisterEnterRegion(villagerleave, leaveRegion, Condition(isvillager))
    TriggerAddAction(villagerleave, LeaveZone)

end)

if Debug then Debug.endFile() end
