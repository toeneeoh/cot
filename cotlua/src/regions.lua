if Debug then Debug.beginFile 'Regions' end

--[[
    regions.lua

    This library handles region events (when a unit enters a predefined rectangle region on the map)
    and defines enemy spawn, teleport, and quest trigger regions.
]]

OnInit.final("Regions", function(require)
    require 'Helper'
    require 'WorldBounds'

    GUARD_CAPTURED = false ---@type boolean 
    AREAS          = { ---@type rect[]
        MAIN_MAP.rect,
        gg_rct_Tavern,
        gg_rct_Infinite_Struggle,
        gg_rct_Colosseum,
        gg_rct_Cave,
        gg_rct_Gods_Arena,
        gg_rct_Training_Prechaos,
        gg_rct_Training_Chaos,
        gg_rct_Church,
        gg_rct_Naga_Dungeon_Boss,
        gg_rct_Naga_Dungeon_Reward,
        gg_rct_Naga_Dungeon,
        gg_rct_Crypt,
        gg_rct_Arena1,
        gg_rct_Arena2,
        gg_rct_Arena3,
        gg_rct_Tomb,
    }

    REGION_DATA = {}

    for i = 1, 10 do
        REGION_DATA[i] = CreateRegion()
    end

    RegionAddRect(REGION_DATA[1], gg_rct_ChurchO)
    RegionAddRect(REGION_DATA[2], gg_rct_ChurchIn)
    RegionAddRect(REGION_DATA[3], gg_rct_Tavern_Out)
    RegionAddRect(REGION_DATA[4], gg_rct_Tavern_In)
    RegionAddRect(REGION_DATA[5], gg_rct_Devourer_entry)
    RegionAddRect(REGION_DATA[6], gg_rct_Flee_Devourers)
    RegionAddRect(REGION_DATA[7], gg_rct_Enter_Tomb)
    RegionAddRect(REGION_DATA[8], gg_rct_Exit_Tomb)
    RegionAddRect(REGION_DATA[9], gg_rct_CryptO)
    RegionAddRect(REGION_DATA[10], gg_rct_CryptIn)

    REGION_DATA[REGION_DATA[1]]  = { x = 20943., y = 772., facing = 0., vision = gg_rct_ChurchRegion_Vision }
    REGION_DATA[REGION_DATA[2]]  = { x = 448.7, y = 1600., facing = 270., vision = MAIN_MAP.vision, extra = function(pid, p) if not CANNOT_LOAD[pid] then
            CANNOT_LOAD[pid] = true
            DisplayTimedTextToPlayer(p, 0, 0, 30., "You may now save.")
        end
    end}
    REGION_DATA[REGION_DATA[3]]  = { x = 22191., y = 3441., facing = 180., extra = function(pid, p) ShowHeroCircle(p, false) end }
    REGION_DATA[REGION_DATA[4]]  = { x = -690., y = -238., facing = 0., extra = function(pid, p) ShowHeroCircle(p, true) end }
    REGION_DATA[REGION_DATA[5]]  = { x = 27145., y = -5489., facing = 0.}
    REGION_DATA[REGION_DATA[6]]  = { x = -15245., y = -14100., facing = 0., exception = function(u, x, y) if u == velreon_guard then SetUnitPosition(u, x, y) end end }
    REGION_DATA[REGION_DATA[7]]  = { x = 19709., y = -20237., facing = 0.}
    REGION_DATA[REGION_DATA[8]]  = { x = -15426., y = 9535., facing = 225.}
    REGION_DATA[REGION_DATA[9]]  = { x = 20353., y = 11426., facing = 270.}
    REGION_DATA[REGION_DATA[10]] = { x = 11793., y = 8501., facing = 180.}
    REGION_DATA[MAIN_MAP.rect] = { vision = MAIN_MAP.vision, minimap = "war3mapImported\\minimap_main.dds" }
    REGION_DATA[gg_rct_Tavern] = { vision = gg_rct_Tavern_Vision, minimap = "war3mapImported\\minimap_tavern.dds" }
    REGION_DATA[gg_rct_Church] = { vision = gg_rct_ChurchRegion_Vision, minimap = "war3mapImported\\minimap_church.dds" }
    REGION_DATA[gg_rct_Gods_Arena] = { vision = gg_rct_GodsCameraBounds }
    REGION_DATA[gg_rct_Cave] = { vision = gg_rct_Devourer_Camera_Bounds, minimap = "war3mapImported\\minimap_cave.dds" }
    REGION_DATA[gg_rct_Crypt] = { vision = gg_rct_Crypt_Vision }
    REGION_DATA[gg_rct_Tomb] = { vision = gg_rct_TombCameraBounds }
    REGION_DATA[gg_rct_Colosseum] = { vision = gg_rct_Colosseum_Camera_Bounds, minimap = "war3mapImported\\minimap_colosseum.dds" }
    REGION_DATA[gg_rct_Infinite_Struggle] = { vision = gg_rct_InfiniteStruggleCameraBounds }
    REGION_DATA[gg_rct_Training_Prechaos] = { vision = gg_rct_PrechaosTraining_Vision }
    REGION_DATA[gg_rct_Training_Chaos] = { vision = gg_rct_ChaosTraining_Vision }
    REGION_DATA[gg_rct_Arena1] = { vision = gg_rct_Arena1Vision }
    REGION_DATA[gg_rct_Arena2] = { vision = gg_rct_Arena2Vision }
    REGION_DATA[gg_rct_Arena3] = { vision = gg_rct_Arena3Vision }
    REGION_DATA[gg_rct_Naga_Dungeon_Boss] = { vision = gg_rct_Naga_Dungeon_Boss_Vision, minimap = "war3mapImported\\minimap_nagadungeon_boss.dds" }
    REGION_DATA[gg_rct_Naga_Dungeon_Reward] = { vision = gg_rct_Naga_Dungeon_Reward_Vision, minimap = "war3mapImported\\minimap_nagadungeon.dds" }
    REGION_DATA[gg_rct_Naga_Dungeon] = { vision = gg_rct_Naga_Dungeon_Vision, minimap = "war3mapImported\\minimap_nagadungeon.dds" }

    colospot[1] = GetRectCenter(gg_rct_Colosseum_Monster_Spawn)
    colospot[2] = GetRectCenter(gg_rct_Colosseum_Monster_Spawn_2)
    colospot[3] = GetRectCenter(gg_rct_Colosseum_Monster_Spawn_3)

    RegionCount      = {} ---@type rect[] 
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

    ---@type fun(x: number, y: number): rect?
    function GetRectFromCoords(x, y)
        for i = 1, #AREAS do
            if GetRectMinX(AREAS[i]) <= x and x <= GetRectMaxX(AREAS[i]) and GetRectMinY(AREAS[i]) <= y and y <= GetRectMaxY(AREAS[i]) then
                return AREAS[i]
            end
        end

        return nil
    end

    function LavaRegion()
        local u = GetFilterUnit()

        Lava:add(u, u)
        return false
    end

    function LeaveRegions()
        local u = GetFilterUnit() ---@type unit 

        if u == udg_SPONSOR or u == townpaladin then --prevent paladin and sponsor from leaving
            IssuePointOrderLoc(u, "move", TownCenter)
        end
    end

    ---@return boolean
    function SafeRegions()
        local u    = GetFilterUnit()
        local uid  = GetUnitTypeId(u)
        local pid  = GetPlayerId(GetOwningPlayer(u)) + 1
        local x    = GetUnitX(u)
        local y    = GetUnitY(u)
        local r    = nil
        local U    = User.first
        local boss = IsBoss(uid)

        if IsUnitIllusion(u) then
            return false
        end

        if IsEnemy(pid) and (IsUnitInRangeXY(u,GetRectCenterX(gg_rct_Town_Boundry),GetRectCenterY(gg_rct_Town_Boundry),4000.) or IsUnitInRangeXY(u,GetRectCenterX(gg_rct_Top_of_Town),GetRectCenterY(gg_rct_Top_of_Town),4000.)) then
            if boss ~= -1 then
                SetUnitXBounded(BossTable[boss].unit, GetLocationX(BossTable[boss].loc))
                SetUnitYBounded(BossTable[boss].unit, GetLocationY(BossTable[boss].loc))
            elseif UnitData[uid][UNITDATA_COUNT] > 0 then
                r = SelectGroupedRegion(UnitData[uid][UNITDATA_SPAWN])
                SetUnitPosition(u, GetRandomReal(GetRectMinX(r), GetRectMaxX(r)), GetRandomReal(GetRectMinY(r), GetRectMaxY(r)))
            end
        elseif NearbyRect(gg_rct_Town_Boundry, x, y) and u == velreon_guard then --rescue guard
            DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Velreon Scholar:|r Excellent work, traveler. Perhaps you would be interested in the ancient tales of the |cffffcc00Medean Empire|r...")
            while U do
                SetPlayerTechResearched(U.player, FourCC('R018'), 1)
                U = U.next
            end
            RemoveUnit(velreon_guard)
        end

        return false
    end

    function SpecialRegions()
        local u   = GetFilterUnit() ---@type unit 
        local x   = GetUnitX(u) ---@type number 
        local y   = GetUnitY(u) ---@type number 
        local p   = GetOwningPlayer(u) ---@type player 
        local pid = GetPlayerId(p) + 1 ---@type integer 

        if u == Hero[pid] then
            if NearbyRect(gg_rct_Naga_Waygate, x, y) then --naga dungeon
                NagaWaygate()
            elseif NearbyRect(gg_rct_Key_Quest, x, y) and not CHAOS_MODE and not IsUnitHidden(god_angel) then
                if (PlayerHasItemType(pid, FourCC('I04J')) or PlayerHasItemType(pid, FourCC('I0NJ')) or GetHeroLevel(Hero[pid]) > 239) and IsQuestCompleted(Key_Quest) == false then
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
                    QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1REQUIRED QUEST|r|nThe Goddesses' Keys\n   - Retrieve the Key of the Gods")
                elseif IsQuestCompleted(Key_Quest) == false then
                    local itm = GetItemFromPlayer(pid, FourCC('I0M7'))
                    if itm then
                        QuestSetCompleted(Key_Quest, true)
                        QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_UPDATED, "|cffffcc00QUEST COMPLETED:|r\nThe Goddesses' Keys")
                        TimerQueue:callDelayed(1., OpenGodsPortal)
                        itm:destroy()
                    end
                end
            elseif NearbyRect(gg_rct_Rescueable_Worker, x, y) and GUARD_CAPTURED == false then --guard
                if UnitAlive(velreon_guard) then
                    GUARD_CAPTURED = true
                    DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Velreon Scholar:|r Thank the lords! If you could escort me back to town I will be able to share the wealth of knowledge I have obtained.")
                    SetUnitOwner(velreon_guard, p, true)
                    PauseUnit(velreon_guard, false)
                end
            end
        end
    end

    function EnterArea()
        local u = GetEnteringUnit()
        local r = GetTriggeringRegion()
        local p = GetOwningPlayer(u)
        local pid = GetPlayerId(p) + 1
        local data = REGION_DATA[r]

        if UnitAlive(u) and u == Hero[pid] then
            MoveHero(pid, data.x, data.y)
            BlzSetUnitFacingEx(u, data.facing)
            if data.extra then
                data.extra(pid, p)
            end
        end

        if data.exception then
            data.exception(u, data.x, data.y)
        end

        return false
    end

    local enterTrigger   = CreateTrigger()

    local specialTrigger = CreateTrigger()
    local specialRegion  = CreateRegion()

    local safeTrigger    = CreateTrigger()
    local safeRegion     = CreateRegion()

    local leaveTrigger   = CreateTrigger()
    local leaveRegion    = CreateRegion()

    --Enter church
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[1], nil)

    --Leave church
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[2], nil)

    --Enter tavern
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[3], nil)

    --Leave tavern
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[4], nil)

    --Enter devourer cave
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[5], nil)

    --Leave devourer cave
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[6], nil)

    --Enter wizard tower
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[7], nil)

    --Leave wizard tower
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[8], nil)

    --Enter crypt
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[9], nil)

    --Leave crypt
    TriggerRegisterEnterRegion(enterTrigger, REGION_DATA[10], nil)

    TriggerAddCondition(enterTrigger, Condition(EnterArea))

    RegionAddRect(specialRegion, gg_rct_Rescueable_Worker)
    RegionAddRect(specialRegion, gg_rct_Key_Quest)
    RegionAddRect(specialRegion, gg_rct_Naga_Waygate)

    RegionAddRect(safeRegion, gg_rct_Town_Boundry)
    RegionAddRect(safeRegion, gg_rct_Top_of_Town)

    RegionAddRect(leaveRegion, gg_rct_Town_Boundry_2)
    RegionAddRect(leaveRegion, gg_rct_Town_boundry_4)

    TriggerRegisterEnterRegion(specialTrigger, specialRegion, Filter(SpecialRegions))
    TriggerRegisterEnterRegion(safeTrigger, safeRegion, Filter(SafeRegions))
    TriggerRegisterEnterRegion(leaveTrigger, leaveRegion, Filter(LeaveRegions))

    local lavaTrigger = CreateTrigger()
    LAVA_REGION = CreateRegion()

    RegionAddRect(LAVA_REGION, gg_rct_Lava1)
    RegionAddRect(LAVA_REGION, gg_rct_Lava2)

    TriggerRegisterEnterRegion(lavaTrigger, LAVA_REGION, Filter(LavaRegion))
end)

if Debug then Debug.endFile() end
