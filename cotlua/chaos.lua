if Debug then Debug.beginFile 'Chaos' end

OnInit.final("Chaos", function()

function OpenGodsPortal()
    local sfx        = AddSpecialEffect("war3mapImported\\Rune Blue Aura.mdl", -1420., -15270.) ---@type effect 
    BlzSetSpecialEffectScale(sfx, 2.45)
    BlzPlaySpecialEffect(sfx, ANIM_TYPE_BIRTH)

    god_portal = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n01O'), -1409, -15255, 270)
    SetUnitPathing(god_portal, false)
    SetUnitPosition(god_portal, -1445, -15260)
end

function GoddessOfLife()
    PauseUnit(Boss[BOSS_LIFE], false)
    UnitRemoveAbility(Boss[BOSS_LIFE], FourCC('Avul'))
end

function SpawnGods()
    PauseUnit(Boss[BOSS_HATE], false)
    UnitRemoveAbility(Boss[BOSS_HATE], FourCC('Avul'))
    PauseUnit(Boss[BOSS_LOVE], false)
    UnitRemoveAbility(Boss[BOSS_LOVE], FourCC('Avul'))
    PauseUnit(Boss[BOSS_KNOWLEDGE], false)
    UnitRemoveAbility(Boss[BOSS_KNOWLEDGE], FourCC('Avul'))
end

function ZeknenExpire()
    UnitRemoveAbility(gg_unit_O01A_0372, FourCC('Avul'))
    PauseUnit(gg_unit_O01A_0372, false)
    DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_O01A_0372), GetPlayerColor(pboss), GetUnitX(gg_unit_O01A_0372), GetUnitY(gg_unit_O01A_0372), nil, "Zeknen", "Very well.", 4)
end

function HideItems()
    local itm      = GetEnumItem() ---@type item 
    local itid         = GetItemTypeId(itm) ---@type integer 

    if itid ~= FourCC('I04I') and itid ~= FourCC('I031') and itid ~= FourCC('I030') and itid ~= FourCC('I02Z') and itid ~= FourCC('wolg') and itm ~= PathItem then
        Item[itm]:destroy()
    end
end

function SetupChaos()
    local i         = 0 ---@type integer 
    local i2         = 0 ---@type integer 
    local target      = nil ---@type unit 
    local ug       = CreateGroup()
    local g       = CreateGroup()
    local x      = 0. ---@type number 
    local y      = 0. ---@type number 
    local loc          = nil ---@type location 
    local myItem      = nil ---@type item 
    local r      = 0. ---@type number 
    local u      = User.first ---@type User 
    local itm ---@type Item 

    --crypt coffin
    RemoveDestructable(gg_dest_B003_1936)

    SoundHandler("Sound\\Interface\\BattleNetWooshStereo1.flac", false, nil, nil)

    DestroyQuest(Dark_Savior_Quest)
    DestroyQuest(Defeat_The_Horde_Quest)
    DestroyQuest(Evil_Shopkeeper_Quest_1)
    DestroyQuest(Evil_Shopkeeper_Quest_2)
    DestroyQuest(Icetroll_Quest)
    DestroyQuest(Iron_Golem_Fist_Quest)
    DestroyQuest(Key_Quest)
    DestroyQuest(Mink_Quest)
    DestroyQuest(Mist_Quest)
    DestroyQuest(Mountain_King_Quest)
    DestroyQuest(Paladin_Quest)
    DestroyQuest(Sasquatch_Quest)
    DestroyQuest(Tauren_Cheiftan_Quest)

    -- ------------------
    -- remove units
    -- ------------------

    SetDoodadAnimation(545, -663, 30.0, FourCC('D0CT'), true, "death", false)

    DestroyEffect(TalkToMe13)
    DestroyEffect(TalkToMe20)
    RemoveUnit(gg_unit_O01A_0372) --zeknen
    RemoveUnit(gg_unit_h03A_0005) --headhunter
    RemoveUnit(god_angel)
    RemoveUnit(gg_unit_n02Q_0382)
    RemoveUnit(gg_unit_N01N_0050)

    --huntsman
    r = GetUnitFacing(gg_unit_h036_0002)
    loc = Location(GetUnitX(gg_unit_h036_0002), GetUnitY(gg_unit_h036_0002))
    RemoveUnit(gg_unit_h036_0002) --huntsman
    CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h009'), loc, r)
    RemoveLocation(loc)

    --home salesmen
    r = GetUnitFacing(gg_unit_n01Q_0045)
    loc = Location(GetUnitX(gg_unit_n01Q_0045), GetUnitY(gg_unit_n01Q_0045))
    RemoveUnit(gg_unit_n01Q_0045)
    CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n03V'), loc, r)
    RemoveLocation(loc)
    r = GetUnitFacing(gg_unit_n00Z_0004)
    loc = Location(GetUnitX(gg_unit_n00Z_0004), GetUnitY(gg_unit_n00Z_0004))
    RemoveUnit(gg_unit_n00Z_0004)
    CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n03H'), loc, r)
    RemoveLocation(loc)

    --clean up bosses
    i = 0

    while i <= BOSS_TOTAL do
        RemoveUnit(Boss[i])
        RemoveLocation(BossLoc[i])
        Boss[i] = nil
        BossID[i] = 0
        i = i + 1
    end

    GroupEnumUnitsInRect(ug, bj_mapInitialPlayableArea, Condition(ChaosTransition)) --need exception for struggle / colo
    GroupEnumUnitsOfPlayer(g, Player(PLAYER_NEUTRAL_PASSIVE), Condition(isvillager))
    BlzGroupAddGroupFast(despawnGroup, ug)
    BlzGroupAddGroupFast(g, ug)

    while true do
        target = FirstOfGroup(ug)
        if target == nil then break end
        GroupRemoveUnit(ug, target)
        if target ~= gg_unit_H01Y_0099 then
            RemoveUnit(target)
        end
    end

    r = GetUnitFacing(PunchingBag[1])
    loc = Location(GetUnitX(PunchingBag[1]), GetUnitY(PunchingBag[1]))
    RemoveUnit(PunchingBag[1])
    PunchingBag[1] = CreateUnitAtLoc(pfoe, FourCC('h02F'), loc, r)
    RemoveLocation(loc)
    r = GetUnitFacing(PunchingBag[2])
    loc = Location(GetUnitX(PunchingBag[2]), GetUnitY(PunchingBag[2]))
    RemoveUnit(PunchingBag[2])
    PunchingBag[2] = CreateUnitAtLoc(pfoe, FourCC('h02G'), loc, r)
    RemoveLocation(loc)

    CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n0A2'), 1344., 1472., 270.) -- chaos merchant
    CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n01K'), -12363, -1185, 0) -- naga npc
    --call CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('ngol'), 15957, -15953, 175) // gold mine

    -- ------------------
    -- town
    -- ------------------

    while u do
            x = GetUnitX(Hero[u.id])
            y = GetUnitY(Hero[u.id])
            if not selectingHero[u.id] and RectContainsCoords(gg_rct_Colosseum, x, y) == false and RectContainsCoords(gg_rct_Infinite_Struggle, x, y) == false and RectContainsCoords(gg_rct_Church, x, y) == false then
                ForceRemovePlayer(AZAZOTH_GROUP, u.player)
                MoveHeroLoc(u.id, TownCenter)
                PanCameraToTimedForPlayer(u.player, GetUnitX(Hero[u.id]), GetUnitY(Hero[u.id]), 0.)
                SetCameraBoundsRectForPlayerEx(u.player, gg_rct_Main_Map_Vision)
            end

        u = u.next
    end

    i = 1

    while i <= 15 do
        loc = Location(GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 300.00, GetRectMaxX(gg_rct_Town_Boundry) - 300.00), GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 300.0, GetRectMaxY(gg_rct_Town_Boundry) - 300.0))

        if i < 6 then
            target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n036'), loc, GetRandomReal(0, 360.00))
        elseif i < 11 then
            target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n035'), loc, GetRandomReal(0, 360.00))
        elseif i < 16 then
            target = CreateUnitAtLoc(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n037'), loc, GetRandomReal(0, 360.00))
        end

        RemoveLocation(loc)
        i = i + 1
    end

    SetWaterBaseColorBJ(150.00, 0.00, 0.00, 0)

    HardMode = 0
    BANISH_FLAG = false

    -- ------------------
    -- bosses
    -- ------------------

    i = 0
    BossLoc[i] = GetRectCenter(gg_rct_Demon_Prince_Boss_Spawn) --demon prince
    SetDoodadAnimation(7810., 1203., 1000., FourCC('D05Q'), false, "death", false)
    BossFacing[i] = 315.00
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('N038'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('N038')
    BossName[i] = "Demon Prince"
    BossLevel[i] = 190
    BossItemType[i * 6] = FourCC('I03F')
    BossItemType[i * 6 + 1] = FourCC('I00X')
    BossItemType[i * 6 + 2] = 0
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 1
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRectCenter(gg_rct_Absolute_Horror_Spawn) --absolute horror
    BossFacing[i] = 270.00
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('N017'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('N017')
    BossName[i] = "Absolute Horror"
    BossLevel[i] = 230
    BossItemType[i * 6] = FourCC('I0ND')
    BossItemType[i * 6 + 1] = FourCC('I0NH')
    BossItemType[i * 6 + 2] = 0
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 2
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRectCenter(gg_rct_Orsted_Boss_Spawn) --orsted
    BossFacing[i] = 270.
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('N00F'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('N00F')
    BossName[i] = "Orsted"
    BossLevel[i] = 250
    BossItemType[i * 6] = 0
    BossItemType[i * 6 + 1] = 0
    BossItemType[i * 6 + 2] = 0
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 3
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = Location(-5400, -15470) --slaughter queen
    BossFacing[i] = 135.00
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('O02B'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('O02B')
    BossName[i] = "Slaughter Queen"
    BossLevel[i] = 270
    BossItemType[i * 6] = FourCC('I0AE')
    BossItemType[i * 6 + 1] = FourCC('I04F')
    BossItemType[i * 6 + 2] = 0
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 3
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRectCenter(gg_rct_Hell_Boss_Spawn) --satan
    BossFacing[i] = 315.00
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('O02I'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('O02I')
    BossName[i] = "Satan"
    BossLevel[i] = 310
    BossItemType[i * 6] = FourCC('I05J')
    BossItemType[i * 6 + 1] = FourCC('I0BX')
    BossItemType[i * 6 + 2] = 0
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 5
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn) --dark soul
    BossFacing[i] = bj_UNIT_FACING
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('O02H'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('O02H')
    BossName[i] = "Essence of Darkness"
    BossLevel[i] = 300
    BossItemType[i * 6] = FourCC('I05A')
    BossItemType[i * 6 + 1] = FourCC('I0AP')
    BossItemType[i * 6 + 2] = FourCC('I0AH')
    BossItemType[i * 6 + 3] = FourCC('I0AI')
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 3
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRectCenter(gg_rct_To_The_Forrest) --legion
    BossFacing[i] = bj_UNIT_FACING
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('H04R'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('H04R')
    BossName[i] = "Legion"
    BossLevel[i] = 340
    BossItemType[i * 6] = FourCC('I0AJ')
    BossItemType[i * 6 + 1] = FourCC('I0B1')
    BossItemType[i * 6 + 2] = FourCC('I0AU')
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 8
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRandomLocInRect(gg_rct_Thanatos_Boss_Spawn) --thanatos
    BossFacing[i] = bj_UNIT_FACING
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('O02K'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('O02K')
    BossName[i] = "Thanatos"
    BossLevel[i] = 320
    BossItemType[i * 6] = FourCC('I04E')
    BossItemType[i * 6 + 1] = FourCC('I0MR')
    BossItemType[i * 6 + 2] = 0
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 5
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRandomLocInRect(gg_rct_Existence_Boss_Spawn) --existence
    BossFacing[i] = bj_UNIT_FACING
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('O02M'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('O02M')
    BossName[i] = "Pure Existence"
    BossLevel[i] = 320
    BossItemType[i * 6] = FourCC('I09E')
    BossItemType[i * 6 + 1] = FourCC('I09O')
    BossItemType[i * 6 + 2] = FourCC('I018')
    BossItemType[i * 6 + 3] = FourCC('I0BY')
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 8
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRectCenter(gg_rct_Azazoth_Boss_Spawn) --azazoth
    BossFacing[i] = 270.00
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('O02T'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('O02T')
    BossName[i] = "Azazoth"
    BossLevel[i] = 380
    BossItemType[i * 6] = FourCC('I0BG')
    BossItemType[i * 6 + 1] = FourCC('I0BI')
    BossItemType[i * 6 + 2] = FourCC('I06M')
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 12
    BossLeash[i] = 2000.

    i = i + 1
    BossLoc[i] = GetRectCenter(gg_rct_Forgotten_Leader_Boss_Spawn) --xallarath
    BossFacing[i] = 135.00
    Boss[i] = CreateUnitAtLoc(pboss, FourCC('O03G'), BossLoc[i], BossFacing[i])
    BossID[i] = FourCC('O03G')
    BossName[i] = "Xallarath"
    BossLevel[i] = 360
    BossItemType[i * 6] = FourCC('I0O1')
    BossItemType[i * 6 + 1] = FourCC('I0OB')
    BossItemType[i * 6 + 2] = FourCC('I0CH')
    BossItemType[i * 6 + 3] = 0
    BossItemType[i * 6 + 4] = 0
    BossItemType[i * 6 + 5] = 0
    CrystalRewards[BossID[i]] = 12
    BossLeash[i] = 4000.

    BOSS_TOTAL = i
    FIRST_DROP = 0

    -- ------------------
    -- chaos boss items
    -- ------------------

    i = 0

    while i <= BOSS_TOTAL do
        i2 = 0

        SetHeroLevel(Boss[i], BossLevel[i], false)
        while not (BossItemType[i * 6 + i2] == 0 or i2 > 5) do
            BossNearbyPlayers[i] = 0
            itm = Item.create(CreateItem(BossItemType[i * 6 + i2], 30000., 30000.))
            UnitAddItem(Boss[i], itm.obj)
            itm:lvl(ItemData[itm.id][ITEM_UPGRADE_MAX])
            i2 = i2 + 1
        end
        SetUnitCreepGuard(Boss[i], true)

        i = i + 1
    end

    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h01M'), GetRectCenterX(gg_rct_ColoBanner1), GetRectCenterY(gg_rct_ColoBanner1), 180.00)
    SetUnitPathing(target, false)
    SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner1), GetRectCenterY(gg_rct_ColoBanner1))

    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h01M'), GetRectCenterX(gg_rct_ColoBanner2), GetRectCenterY(gg_rct_ColoBanner2), 0)
    SetUnitPathing(target, false)
    SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner2), GetRectCenterY(gg_rct_ColoBanner2))

    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h01M'), GetRectCenterX(gg_rct_ColoBanner3), GetRectCenterY(gg_rct_ColoBanner3), 180.00)
    SetUnitPathing(target, false)
    SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner3), GetRectCenterY(gg_rct_ColoBanner3))

    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h01M'), GetRectCenterX(gg_rct_ColoBanner4), GetRectCenterY(gg_rct_ColoBanner4), 0)
    SetUnitPathing(target, false)
    SetUnitPosition(target, GetRectCenterX(gg_rct_ColoBanner4), GetRectCenterY(gg_rct_ColoBanner4))

    -- ------------------
    -- chaotic enemies
    -- ------------------

    SpawnCreeps(1)

    forgotten_spawner = CreateUnit(pboss, FourCC('o02E'), 15100., -12650., bj_UNIT_FACING)
    SetUnitAnimation(forgotten_spawner, "Stand Work")
    SpawnForgotten()
    SpawnForgotten()
    SpawnForgotten()
    SpawnForgotten()
    SpawnForgotten()
    TimerQueue:callPeriodically(60., not UnitAlive(forgotten_spawner), SpawnForgotten)

    CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 2.5, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)

    CWLoading = false

    DestroyGroup(ug)
    DestroyGroup(g)
end

function BeginChaos()
    --stop prechaos boss respawns
    TimerList[BOSS_ID]:stopAllTimers(FourCC('boss'))

    --reset legion jump timer
    PauseTimer(wanderingTimer)
    TimerStart(wanderingTimer, 2040. - (User.AmountPlaying * 240), true, ShadowStepExpire)

    CWLoading = true
    ChaosMode = true

    RemoveUnit(power_crystal)
    power_crystal = nil

    RemoveUnit(god_portal)
    god_portal = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n00N'), -1409., -15255., 270)

    DisplayTimedTextToForce(FORCE_PLAYING, 100, "|cff800807Without the Goddess of Life, unspeakable chaos walks the land and wreaks havoc on all life. Chaos spreads across the land and thus the chaotic world is born.")
    SoundHandler("Sound\\Interface\\GlueScreenEarthquake1.flac", false, nil, nil)

    CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 3.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)

    TimerQueue:callDelayed(3., SetupChaos)
end

end)

if Debug then Debug.endFile() end
