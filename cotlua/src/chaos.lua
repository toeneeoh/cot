--[[
    chaos.lua

    A module that contains functions for transitioning to chaos mode.
]]

OnInit.final("Chaos", function()

function OpenGodsPortal()
    local sfx = AddSpecialEffect("war3mapImported\\Rune Blue Aura.mdl", -1420., -15270.) ---@type effect 
    BlzSetSpecialEffectScale(sfx, 2.45)
    BlzPlaySpecialEffect(sfx, ANIM_TYPE_BIRTH)

    god_portal = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n01O'), -1409, -15255, 270)
    SetUnitPathing(god_portal, false)
    SetUnitPosition(god_portal, -1445, -15260)
end

function GoddessOfLife()
    PauseUnit(BossTable[BOSS_LIFE].unit, false)
    UnitRemoveAbility(BossTable[BOSS_LIFE].unit, FourCC('Avul'))
end

function SpawnGods()
    PauseUnit(BossTable[BOSS_HATE].unit, false)
    UnitRemoveAbility(BossTable[BOSS_HATE].unit, FourCC('Avul'))
    PauseUnit(BossTable[BOSS_LOVE].unit, false)
    UnitRemoveAbility(BossTable[BOSS_LOVE].unit, FourCC('Avul'))
    PauseUnit(BossTable[BOSS_KNOWLEDGE].unit, false)
    UnitRemoveAbility(BossTable[BOSS_KNOWLEDGE].unit, FourCC('Avul'))
end

function ZeknenExpire()
    UnitRemoveAbility(zeknen, FourCC('Avul'))
    PauseUnit(zeknen, false)
	SetCinematicScene(GetUnitTypeId(zeknen), GetPlayerColor(pboss), "Zeknen", "Very well.", 5, 4)
end

function SetupChaos()
    FIRST_DROP = 0
    HARD_MODE = 0
    BANISH_FLAG = false

    --change water color
    SetWaterBaseColorBJ(150.00, 0.00, 0.00, 0)

    --crypt coffin
    RemoveDestructable(gg_dest_B003_1936)

    SoundHandler("Sound\\Interface\\BattleNetWooshStereo1.flac", false)

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
    RemoveUnit(zeknen) --zeknen
    RemoveUnit(gg_unit_h03A_0005) --headhunter
    RemoveUnit(god_angel)
    RemoveUnit(gg_unit_n02Q_0382)
    RemoveUnit(kroresh)

    --huntsman
    local facing = GetUnitFacing(gg_unit_h036_0002)
    local loc = {GetUnitX(gg_unit_h036_0002), GetUnitY(gg_unit_h036_0002)}
    RemoveUnit(gg_unit_h036_0002) --huntsman
    CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h009'), loc[1], loc[2], facing)

    --home salesmen
    facing = GetUnitFacing(gg_unit_n01Q_0045)
    loc = {GetUnitX(gg_unit_n01Q_0045), GetUnitY(gg_unit_n01Q_0045)}
    RemoveUnit(gg_unit_n01Q_0045)
    CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n03V'), loc[1], loc[2], facing)

    facing = GetUnitFacing(gg_unit_n00Z_0004)
    loc = {GetUnitX(gg_unit_n00Z_0004), GetUnitY(gg_unit_n00Z_0004)}
    RemoveUnit(gg_unit_n00Z_0004)
    CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n03H'), loc[1], loc[2], facing)

    --removes creeps and villagers
    local ug = CreateGroup()
    local g  = CreateGroup()

    GroupEnumUnitsInRect(ug, bj_mapInitialPlayableArea, Condition(ChaosTransition)) --need exception for struggle / colo
    GroupEnumUnitsOfPlayer(g, Player(PLAYER_NEUTRAL_PASSIVE), Condition(isvillager))
    BlzGroupAddGroupFast(g, ug)

    for i = 1, #despawnGroup do
        RemoveUnit(despawnGroup[i])
    end

    for target in each(ug) do
        if target ~= udg_SPONSOR then
            RemoveUnit(target)
        end
    end

    DestroyGroup(ug)
    DestroyGroup(g)

    --------------------
    --town
    --------------------

    --chaos merchant
    CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n0A2'), 1344., 1472., 270.)
    --naga dungeon npc
    CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n01K'), -12363, -1185, 0)

    local u = User.first
    local x = 0. ---@type number 
    local y = 0. ---@type number 

    --move players to fountain (unless in struggle or colosseum)
    while u do
        x = GetUnitX(Hero[u.id])
        y = GetUnitY(Hero[u.id])
        if not selectingHero[u.id] and RectContainsCoords(gg_rct_Colosseum, x, y) == false and RectContainsCoords(gg_rct_Infinite_Struggle, x, y) == false and RectContainsCoords(gg_rct_Church, x, y) == false then
            TableRemove(GODS_GROUP, u.player)
            MoveHeroLoc(u.id, TownCenter)
        end

        u = u.next
    end

    --spawn new villagers
    for _ = 1, 15 do
        loc = {GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 300.00, GetRectMaxX(gg_rct_Town_Boundry) - 300.00),
                GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 300.0, GetRectMaxY(gg_rct_Town_Boundry) - 300.0)}

        CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n03' .. GetRandomInt(5, 7)), loc[1], loc[2], GetRandomReal(0, 360.00))
    end

    -- ------------------
    -- bosses
    -- ------------------

    --clear spider webs in demon prince pit
    SetDoodadAnimation(7810., 1203., 1000., FourCC('D05Q'), false, "death", false)

    --clean up bosses
    for i = BOSS_OFFSET, #BossTable do
        RemoveUnit(BossTable[i].unit)
        RemoveLocation(BossTable[i].loc)
    end

    -- Demon Prince
    CreateBossEntry(BOSS_DEMON_PRINCE, GetRectCenter(gg_rct_Demon_Prince_Boss_Spawn), 315.00, FourCC('N038'), "Demon Prince", 190,
    {FourCC('I03F'), FourCC('I00X'), 0, 0, 0, 0}, 1, 2000)
    -- Absolute Horror
    CreateBossEntry(BOSS_ABSOLUTE_HORROR, GetRectCenter(gg_rct_Absolute_Horror_Spawn), 270.00, FourCC('N017'), "Absolute Horror", 230,
    {FourCC('I0ND'), FourCC('I0NH'), 0, 0, 0, 0}, 2, 2000)
    -- Orsted
    CreateBossEntry(BOSS_ORSTED, GetRectCenter(gg_rct_Orsted_Boss_Spawn), 270.00, FourCC('N00F'), "Orsted", 250,
    {0, 0, 0, 0, 0, 0}, 3, 2000)
    -- Slaughter Queen
    CreateBossEntry(BOSS_SLAUGHTER_QUEEN, Location(-5400, -15470), 135.00, FourCC('O02B'), "Slaughter Queen", 270,
    {FourCC('I0AE'), FourCC('I04F'), 0, 0, 0, 0}, 3, 2000)
    -- Satan
    CreateBossEntry(BOSS_SATAN, GetRectCenter(gg_rct_Hell_Boss_Spawn), 315.00, FourCC('O02I'), "Satan", 310,
    {FourCC('I05J'), FourCC('I0BX'), 0, 0, 0, 0}, 5, 2000)
    -- Dark Soul
    CreateBossEntry(BOSS_DARK_SOUL, GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn), bj_UNIT_FACING, FourCC('O02H'), "Essence of Darkness", 300,
    {FourCC('I05A'), FourCC('I0AP'), FourCC('I0AH'), FourCC('I0AI'), 0, 0}, 3, 2000)
    -- Legion
    CreateBossEntry(BOSS_LEGION, GetRectCenter(gg_rct_To_The_Forrest), bj_UNIT_FACING, FourCC('H04R'), "Legion", 340,
    {FourCC('I0AJ'), FourCC('I0B1'), FourCC('I0AU'), 0, 0, 0}, 8, 2000)
    -- Thanatos
    CreateBossEntry(BOSS_THANATOS, GetRandomLocInRect(gg_rct_Thanatos_Boss_Spawn), bj_UNIT_FACING, FourCC('O02K'), "Thanatos", 320,
    {FourCC('I04E'), FourCC('I0MR'), 0, 0, 0, 0}, 5, 2000)
    -- Existence
    CreateBossEntry(BOSS_EXISTENCE, GetRandomLocInRect(gg_rct_Existence_Boss_Spawn), bj_UNIT_FACING, FourCC('O02M'), "Pure Existence", 320,
    {FourCC('I09E'), FourCC('I09O'), FourCC('I018'), FourCC('I0BY'), 0, 0}, 8, 2000)
    -- Azazoth
    CreateBossEntry(BOSS_AZAZOTH, GetRectCenter(gg_rct_Azazoth_Boss_Spawn), 270.00, FourCC('O02T'), "Azazoth", 380,
    {FourCC('I0BG'), FourCC('I0BI'), FourCC('I06M'), 0, 0, 0}, 12, 2000)
    -- Xallarath
    CreateBossEntry(BOSS_XALLARATH, GetRectCenter(gg_rct_Forgotten_Leader_Boss_Spawn), 135.00, FourCC('O03G'), "Xallarath", 360,
    {FourCC('I0O1'), FourCC('I0OB'), FourCC('I0CH'), 0, 0, 0}, 12, 4000)

    BOSS_OFFSET = BOSS_DEMON_PRINCE

    -- ------------------
    -- chaos boss items
    -- ------------------

    for i = BOSS_OFFSET, #BossTable do
        BossNearbyPlayers[i] = 0
        SetHeroLevel(BossTable[i].unit, BossTable[i].level, false)

        for j = 1, 6 do
            if BossTable[i].item[j] ~= 0 then
                local itm = UnitAddItemById(BossTable[i].unit, BossTable[i].item[j])
                itm:lvl(ItemData[itm.id][ITEM_UPGRADE_MAX])
            end
        end
        SetUnitCreepGuard(BossTable[i].unit, true)
    end

    local target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h01M'), GetRectCenterX(gg_rct_ColoBanner1), GetRectCenterY(gg_rct_ColoBanner1), 180.00)
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
    SpawnForgotten(5)
    TimerQueue:callDelayed(60., SpawnForgotten, 1)

	SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\Black_mask.blp")
	SetCineFilterBlendMode(BLEND_MODE_BLEND)
	SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
	SetCineFilterStartUV(0, 0, 1, 1)
	SetCineFilterEndUV(0, 0, 1, 1)
	SetCineFilterStartColor(0, 0, 0, 255)
	SetCineFilterEndColor(0, 0, 0, 0)
	SetCineFilterDuration(2.5)
	TimerQueue:callDelayed(2.5, DisplayCineFilter, false)

    CHAOS_LOADING = false
end

function BeginChaos()
    --stop prechaos boss respawns
    TimerList[BOSS_ID]:stopAllTimers('boss')

    --reset legion jump timer
    WANDER_TIMER:reset()
    WANDER_TIMER:callDelayed(2040. - (User.AmountPlaying * 240), ShadowStepExpire)

    CHAOS_LOADING = true
    CHAOS_MODE = true

    RemoveUnit(power_crystal)

    RemoveUnit(god_portal)
    god_portal = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n00N'), -1409., -15255., 270)

    DisplayTimedTextToForce(FORCE_PLAYING, 100, "|cff800807Without the Goddess of Life, unspeakable chaos walks the land and wreaks havoc on all life. Chaos spreads across the land and thus the chaotic world is born.")
    SoundHandler("Sound\\Interface\\GlueScreenEarthquake1.flac", false, nil, nil)

	SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\Black_mask.blp")
	SetCineFilterBlendMode(BLEND_MODE_BLEND)
	SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
	SetCineFilterStartUV(0, 0, 1, 1)
	SetCineFilterEndUV(0, 0, 1, 1)
	SetCineFilterStartColor(0, 0, 0, 0)
	SetCineFilterEndColor(0, 0, 0, 255)
	SetCineFilterDuration(3.0)
	DisplayCineFilter(true)

    TimerQueue:callDelayed(3., SetupChaos)
end

end, Debug.getLine())
