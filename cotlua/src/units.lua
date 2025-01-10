--[[
    units.lua

    A library that spawns units and does any necessary setup related to units.
    Sets up creeps, bosses, NPCs, etc.
]]

OnInit.final("Units", function(Require)
    Require('Shop')
    Require('Boss')
    Require('Items')
    Require('Damage')

    UnitData = {}

    ---@return boolean
    local function respawn_filter()
        local u = GetFilterUnit()

        return IsUnitEnemy(u, PLAYER_CREEP) and
            UnitAlive(u) and
            GetUnitTypeId(u) ~= BACKPACK and
            not IsDummy(u) and
            GetUnitAbilityLevel(u, FourCC('Aloc')) == 0 and
            GetPlayerId(GetOwningPlayer(u)) <= PLAYER_CAP
    end

    ---@type fun(u: unit)
    local function revive_ghost(u)
        HideEffect(Unit[u].ghost)
        PauseUnit(u, false)
        UnitRemoveAbility(u, FourCC('Avul'))
        ShowUnit(u, true)
        Unit[u].original_x = GetUnitX(u)
        Unit[u].original_y = GetUnitY(u)
    end

    local function ghost_respawn(creep)
        local ug = CreateGroup()

        GroupEnumUnitsInRange(ug, GetUnitX(creep), GetUnitY(creep), 800., Condition(respawn_filter))
        if BlzGroupGetSize(ug) == 0 then
            TimerQueue:callDelayed(0.9, revive_ghost, creep)
            TableRemove(GHOST_UNITS, creep)
        else
            TimerQueue:callDelayed(1., ghost_respawn, creep)
        end

        DestroyGroup(ug)
    end

    ---@type fun(uid: integer, x: number, y: number, flag: integer, func: function)
    local function on_respawn(uid, x, y, flag, func)
        if CHAOS_MODE == flag then
            local ug = CreateGroup()

            GroupEnumUnitsInRange(ug, x, y, 800., Condition(respawn_filter))

            local creep = CreateUnit(PLAYER_CREEP, uid, x, y, math.random(0, 359))
            EVENT_ON_DEATH:register_unit_action(creep, func)

            if FirstOfGroup(ug) ~= nil then
                BlzSetItemSkin(PATH_ITEM, BlzGetUnitSkin(creep))
                local sfx = AddSpecialEffect(BlzGetItemStringField(PATH_ITEM, ITEM_SF_MODEL_USED), x, y)
                GHOST_UNITS[#GHOST_UNITS + 1] = creep
                PauseUnit(creep, true)
                UnitAddAbility(creep, FourCC('Avul'))
                ShowUnit(creep, false)
                BlzSetItemSkin(PATH_ITEM, BlzGetUnitSkin(DUMMY_UNIT))
                BlzSetSpecialEffectColorByPlayer(sfx, PLAYER_CREEP)
                BlzSetSpecialEffectColor(sfx, 175, 175, 175)
                BlzSetSpecialEffectAlpha(sfx, 127)
                BlzSetSpecialEffectScale(sfx, BlzGetUnitRealField(creep, UNIT_RF_SCALING_VALUE))
                BlzSetSpecialEffectYaw(sfx, bj_DEGTORAD * GetUnitFacing(creep))
                Unit[creep].ghost = sfx
                TimerQueue:callDelayed(1., ghost_respawn, creep)
            end

            DestroyGroup(ug)
        end
    end

    local function on_death(killed, killer)
        local uid = GetUnitTypeId(killed)
        local x, y = GetUnitX(killed), GetUnitY(killed)

        RewardItem(killed)
        RewardXPGold(killed, killer)
        TimerQueue:callDelayed(20.0, on_respawn, uid, x, y, CHAOS_MODE, on_death)
    end

    local function on_enter_safe_zone(u)
        local uid = GetUnitTypeId(u)
        local r = SelectGroupedRegion(UnitData[uid].spawn)
        SetUnitPosition(u, GetRandomReal(GetRectMinX(r), GetRectMaxX(r)), GetRandomReal(GetRectMinY(r), GetRectMaxY(r)))
    end

    local UNIT_COUNT = 0
    local function setup_unit(id, count, spawn, chaos)
        UnitData[id] = {
            count = count,
            spawn = spawn,
            mode = chaos,
        }
        UnitData[UNIT_COUNT] = id
        UNIT_COUNT = UNIT_COUNT + 1
    end

    setup_unit(FourCC('nitt'), 18, 1, 0) -- ice troll trapper
    setup_unit(FourCC('n0tb'), 10, 1, 0) -- ice troll berserker
    setup_unit(FourCC('n0ts'), 10, 2, 0) -- tuskarr sorc
    setup_unit(FourCC('n0tw'), 11, 2, 0) -- tuskarr warrior
    setup_unit(FourCC('n0tc'), 9, 2, 0)  -- tuskarr chieftain
    setup_unit(FourCC('n0ss'), 18, 3, 0) -- spider seer
    setup_unit(FourCC('n1sl'), 18, 3, 0) -- spider lord
    setup_unit(FourCC('n1uw'), 35, 4, 0) -- ursa warrior 
    setup_unit(FourCC('n0us'), 22, 4, 0) -- ursa shaman
    setup_unit(FourCC('n0po'), 20, 5, 0) -- polar bear
    setup_unit(FourCC('n0dm'), 16, 5, 0) -- dire mammoth
    setup_unit(FourCC('n01G'), 50, 6, 0) -- ogre overlord
    setup_unit(FourCC('o01G'), 40, 6, 0) -- tauren
    setup_unit(FourCC('n0ub'), 18, 7, 0) -- unbroken deathbringer
    setup_unit(FourCC('n0ut'), 15, 7, 0) -- unbroken trickster
    setup_unit(FourCC('n0ud'), 12, 7, 0) -- unbroken darkweaver
    setup_unit(FourCC('n0hs'), 25, 8, 0) -- lesser hellfire
    setup_unit(FourCC('n0hs'), 30, 8, 0) -- lesser hellhound
    setup_unit(FourCC('n027'), 25, 9, 0) -- centaur lancer
    setup_unit(FourCC('n024'), 20, 9, 0) -- centaur ranger
    setup_unit(FourCC('n028'), 15, 9, 0) -- centaur mage
    setup_unit(FourCC('n01M'), 45, 10, 0) -- magnataur destroyer
    setup_unit(FourCC('n08M'), 20, 10, 0) -- forgotten one
    setup_unit(FourCC('n01H'), 4, 11, 0) -- ancient hydra
    setup_unit(FourCC('n02P'), 18, 12, 0) -- frost dragon
    setup_unit(FourCC('n01R'), 18, 12, 0) -- frost drake
    setup_unit(FourCC('n099'), 1, 14, 0) -- frost elder
    setup_unit(FourCC('n00C'), 7, 13, 0) -- medean berserker
    setup_unit(FourCC('n02L'), 15, 13, 0) -- medean devourer
    -- CHAOS
    setup_unit(FourCC('n033'), 20, 1, 1) -- demon
    setup_unit(FourCC('n034'), 11, 1, 1) -- demon wizard
    setup_unit(FourCC('n03C'), 24, 15, 1) -- horror young
    setup_unit(FourCC('n03A'), 46, 15, 1) -- horror mindless
    setup_unit(FourCC('n03B'), 11, 15, 1) -- horror leader
    setup_unit(FourCC('n03F'), 62, 18, 1) -- despair
    setup_unit(FourCC('n01W'), 30, 18, 1) -- despair wizard
    setup_unit(FourCC('n00X'), 19, 16, 1) -- abyssal beast
    setup_unit(FourCC('n08N'), 34, 16, 1) -- abyssal guardian
    setup_unit(FourCC('n00W'), 34, 16, 1) -- abyssal spirit
    setup_unit(FourCC('n030'), 30, 17, 1) -- void seeker
    setup_unit(FourCC('n031'), 40, 17, 1) -- void keeper
    setup_unit(FourCC('n02Z'), 40, 17, 1) -- void mother
    setup_unit(FourCC('n020'), 22, 9, 1) -- nightmare creature
    setup_unit(FourCC('n02J'), 18, 9, 1) -- nightmare spirit
    setup_unit(FourCC('n03E'), 18, 8, 1) -- spawn of hell
    setup_unit(FourCC('n03D'), 16, 8, 1) -- death dealer
    setup_unit(FourCC('n03G'), 6, 8, 1) -- lord of plague
    setup_unit(FourCC('n03J'), 24, 13, 1) -- denied existence
    setup_unit(FourCC('n01X'), 13, 13, 1) -- deprived existence
    setup_unit(FourCC('n03M'), 24, 12, 1) -- astral being
    setup_unit(FourCC('n01V'), 13, 12, 1) -- astral entity
    setup_unit(FourCC('n026'), 22, 7, 1) -- dimensional planewalker
    setup_unit(FourCC('n03T'), 18, 7, 1) -- dimensional planeshifter

    -- forgotten units
    forgottenTypes[0] = FourCC('o030') -- corpse basher
    forgottenTypes[1] = FourCC('o033') -- destroyer
    forgottenTypes[2] = FourCC('o036') -- spirit
    forgottenTypes[3] = FourCC('o02W') -- warrior
    forgottenTypes[4] = FourCC('o02Y') -- monster

    ---@param flag integer
    function SpawnCreeps(flag)
        for i = 0, UNIT_COUNT - 1 do
            local id = UnitData[i]
            local index = UnitData[id]

            if index.mode == flag then
                for _ = 1, index.count do
                    local myregion = SelectGroupedRegion(index.spawn)
                    local x, y
                    repeat
                        x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
                        y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
                    until IsTerrainWalkable(x, y)
                    local u = CreateUnit(PLAYER_CREEP, id, x, y, GetRandomInt(0, 359))

                    AntiLagUnit(u)
                    -- on death logic
                    EVENT_ON_DEATH:register_unit_action(u, on_death)

                    -- safe zone logic
                    EVENT_ON_ENTER_SAFE_AREA:register_unit_action(u, on_enter_safe_zone)
                end
            end
        end
    end

    local x = 0. ---@type number 
    local y = 0. ---@type number 

    -- velreon guard
    velreon_guard = CreateUnit(Player(PLAYER_TOWN), FourCC('h04A'), 29919., -2419., 225.)
    PauseUnit(velreon_guard, true)

    -- angel
    god_angel = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n0A1'), -1841., -14858., 325.)
    ShowUnit(god_angel, false)

    -- zeknen
    zeknen = CreateUnit(PLAYER_BOSS, FourCC('O01A'), -1886., -27549., 225.)
    SetHeroLevel(zeknen, 150, false)
    PauseUnit(zeknen, true)
    UnitAddAbility(zeknen, FourCC('Avul'))
    EVENT_ON_DEATH:register_unit_action(zeknen, function()
        DeadGods = 0
        SetCinematicScene(Boss[BOSS_LIFE].id, GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), "Goddess of Life", "You are foolish to challenge us in our realm. Prepare yourself.", 9, 7)

        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_HATE].unit), GetUnitY(Boss[BOSS_HATE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_HATE].unit), GetUnitY(Boss[BOSS_HATE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_HATE].unit), GetUnitY(Boss[BOSS_HATE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_LOVE].unit), GetUnitY(Boss[BOSS_LOVE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_LOVE].unit), GetUnitY(Boss[BOSS_LOVE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_LOVE].unit), GetUnitY(Boss[BOSS_LOVE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_KNOWLEDGE].unit), GetUnitY(Boss[BOSS_KNOWLEDGE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_KNOWLEDGE].unit), GetUnitY(Boss[BOSS_KNOWLEDGE].unit)))
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_KNOWLEDGE].unit), GetUnitY(Boss[BOSS_KNOWLEDGE].unit)))
        ShowUnit(Boss[BOSS_HATE].unit, true)
        ShowUnit(Boss[BOSS_LOVE].unit, true)
        ShowUnit(Boss[BOSS_KNOWLEDGE].unit, true)
        PauseUnit(Boss[BOSS_HATE].unit, true)
        PauseUnit(Boss[BOSS_LOVE].unit, true)
        PauseUnit(Boss[BOSS_KNOWLEDGE].unit, true)
        UnitAddAbility(Boss[BOSS_HATE].unit, FourCC('Avul'))
        UnitAddAbility(Boss[BOSS_LOVE].unit, FourCC('Avul'))
        UnitAddAbility(Boss[BOSS_KNOWLEDGE].unit, FourCC('Avul'))
        TimerQueue:callDelayed(7., SpawnGods)
    end)

    -- sponsor
    BlzSetUnitMaxHP(udg_SPONSOR, 1)
    BlzSetUnitMaxMana(udg_SPONSOR, 0)
    UnitAddItemById(udg_SPONSOR, FourCC('I0ML'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MH'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MI'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MJ'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MK'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MG'))
    -- town paladin
    townpaladin = CreateUnit(Player(PLAYER_TOWN), FourCC('H01T'), -176.3, 666, 90.)
    SetHeroLevel(townpaladin, 100, false)
    BlzSetUnitMaxMana(townpaladin, 0)

    local function paladin_enrage(b)
        local ug = CreateGroup()

        if b then
            GroupEnumUnitsInRange(ug, GetUnitX(townpaladin), GetUnitY(townpaladin), 250., Condition(isplayerunit))

            for target in each(ug) do
                DamageTarget(townpaladin, target, 20000., ATTACK_TYPE_NORMAL, PHYSICAL, "Enrage")
            end

            if GetUnitAbilityLevel(townpaladin, FourCC('Bblo')) == 0 then
                Dummy.create(GetUnitX(townpaladin), GetUnitY(townpaladin), FourCC('A041'), 1):cast(GetOwningPlayer(townpaladin), "bloodlust", townpaladin)
            end

            BlzSetHeroProperName(townpaladin, "|cff990000BUZAN THE FEARLESS|r")
            UnitAddBonus(townpaladin, BONUS_DAMAGE, 5000)
        else
            UnitRemoveAbility(townpaladin, FourCC('Bblo'))
            BlzSetHeroProperName(townpaladin, "|c00F8A48BBuzan the Fearless|r")
            UnitAddBonus(townpaladin, BONUS_DAMAGE, -5000)
            IssueImmediateOrderById(townpaladin, ORDER_ID_STOP)
        end

        DestroyGroup(ug)
    end

    local function paladin_aggro_expire(pt)
        pt.dur = pt.dur - 0.5

        if pt.dur <= 0 then
            SetPlayerAllianceStateBJ(Player(pt.pid - 1), Player(PLAYER_TOWN), bj_ALLIANCE_ALLIED)
            SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), Player(pt.pid - 1), bj_ALLIANCE_ALLIED)

            paladin_enrage(false)

            pt:destroy()
        else
            pt.timer:callDelayed(0.5, paladin_aggro_expire, pt)
        end
    end

    local function paladin_on_struck(target, source, amount, amount_after_red, damage_type)
        if amount_after_red >= 100. and math.random(0, 1) == 0 then
            local pt = TimerList[0]:get('pala', source)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1

            if pt then
                pt.dur = 20.
            else
                paladin_enrage(true)

                pt = TimerList[0]:add()
                pt.dur = 20.
                pt.source = source
                pt.tag = 'pala'
                pt.pid = pid

                SetPlayerAllianceStateBJ(Player(pid - 1), Player(PLAYER_TOWN), bj_ALLIANCE_UNALLIED)
                SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), Player(pid - 1), bj_ALLIANCE_UNALLIED)

                if GetUnitCurrentOrder(target) ~= OrderId("attack") or GetUnitCurrentOrder(target) ~= OrderId("smart") then
                    IssueTargetOrder(target, "attack", source)
                end

                pt.timer:callDelayed(0.5, paladin_aggro_expire, pt)
            end
        end
    end
    local function paladin_on_kill(killer, killed)
        local pt = TimerList[0]:get('pala', killed)

        if pt then
            pt.dur = 0.
        end
    end

    EVENT_ON_STRUCK_FINAL:register_unit_action(townpaladin, paladin_on_struck)
    EVENT_ON_KILL:register_unit_action(townpaladin, paladin_on_kill)
    EVENT_ON_DEATH:register_unit_action(townpaladin, function(u)
        CreateItem(FourCC('I01Y'), GetUnitX(u), GetUnitY(u)) -- cheese
    end)

    -- minigame banners
    local target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 180.00)
    x = GetRectCenterX(gg_rct_ColoBanner1)
    y = GetRectCenterY(gg_rct_ColoBanner1)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)
    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 0)
    x = GetRectCenterX(gg_rct_ColoBanner2)
    y = GetRectCenterY(gg_rct_ColoBanner2)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)
    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 180.00)
    x = GetRectCenterX(gg_rct_ColoBanner3)
    y = GetRectCenterY(gg_rct_ColoBanner3)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)
    target = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h00G'), 0, 0, 0)
    x = GetRectCenterX(gg_rct_ColoBanner4)
    y = GetRectCenterY(gg_rct_ColoBanner4)
    SetUnitPathing(target, false)
    SetUnitPosition(target, x, y)

    -- special prechaos "bosses"

    -- pinky
    pinky = CreateUnit(PLAYER_BOSS, FourCC('O019'), 11528., 8168., 180.)
    SetHeroLevel(pinky, 100, false)
    UnitAddItemById(pinky, FourCC('I02Y'))
    EVENT_ON_DEATH:register_unit_action(pinky, function(u)
        CreateItem(FourCC('I02Y'), GetUnitX(u), GetUnitY(u)) -- pinky pick
    end)
    -- bryan
    bryan = CreateUnit(PLAYER_BOSS, FourCC('H043'), 11528., 7880., 180.)
    SetHeroLevel(bryan, 100, false)
    UnitAddItemById(bryan, FourCC('I02X'))
    EVENT_ON_DEATH:register_unit_action(bryan, function(u)
        CreateItem(FourCC('I02X'), GetUnitX(u), GetUnitY(u)) -- bryan pick
    end)
    -- ice troll
    ice_troll = CreateUnit(PLAYER_BOSS, FourCC('O00T'), 15833., 4382., 254.)
    SetHeroLevel(ice_troll, 100, false)
    UnitAddItemById(ice_troll, FourCC('I03Z'))
    EVENT_ON_DEATH:register_unit_action(ice_troll, function(u)
        CreateItem(FourCC('I040'), GetUnitX(u), GetUnitY(u)) -- key of redemption
        CreateItem(FourCC('I03Z'), GetUnitX(u), GetUnitY(u)) -- da's dingo
    end)

    -- kroresh
    kroresh = CreateUnit(PLAYER_BOSS, FourCC('N01N'), 17000., -19000., 0.)
    SetHeroLevel(kroresh, 120, false)
    UnitAddItemById(kroresh, FourCC('I0BZ'))
    UnitAddItemById(kroresh, FourCC('I064'))
    UnitAddItemById(kroresh, FourCC('I04B'))
    EVENT_ON_DEATH:register_unit_action(kroresh, function(u)
        CreateItem(FourCC('I04B'), GetUnitX(u), GetUnitY(u), 600.) -- jewel of the horde
    end)
    -- zeknen
    UnitAddItemById(zeknen, FourCC('I03Y'))
    Unit[zeknen].mr = Unit[zeknen].mr * 0.5

    -- prechaos bosses

    -- Minotaur
    local boss = Boss.create(BOSS_TAUREN, Location(-11692., -12774.), 45., FourCC('O002'), "Minotaur", 75,
    0, 2000)
    -- Forgotten Mystic
    boss = Boss.create(BOSS_MYSTIC, Location(-15435., -14354.), 270., FourCC('H045'), "Forgotten Mystic", 100,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Hellfire Magi
    boss = Boss.create(BOSS_HELLFIRE, GetRectCenter(gg_rct_Hell_Boss_Spawn), 315., FourCC('U00G'), "Hellfire Magi", 100,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Last Dwarf
    boss = Boss.create(BOSS_DWARF, Location(11520., 15466.), 225., FourCC('H01V'), "Last Dwarf", 100,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Vengeful Test Paladin
    boss = Boss.create(BOSS_PALADIN, GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn), 270., FourCC('H02H'), "Vengeful Test Paladin", 140,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Dragoon
    boss = Boss.create(BOSS_DRAGOON, GetRectCenter(gg_rct_Thanatos_Boss_Spawn), 320., FourCC('O01B'), "Dragoon", 100,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Death Knight
    boss = Boss.create(BOSS_DEATH_KNIGHT, Location(6932., -14177.), 0., FourCC('H040'), "Death Knight", 120,
    0, 2000)
    -- Siren of the Tides
    boss = Boss.create(BOSS_VASHJ, Location(-12375., -1181.), 0., FourCC('H020'), "Siren of the Tides", 75,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Super Fun Happy Yeti
    boss = Boss.create(BOSS_YETI, Location(15816., 6250.), 180., FourCC('n02H'), "Super Fun Happy Yeti", 0,
    0, 2000)
    -- King of Ogres
    boss = Boss.create(BOSS_OGRE, Location(-5242., -15630.), 135., FourCC('n03L'), "King of Ogres", 0,
    0, 2000)
    -- Nerubian Empress
    boss = Boss.create(BOSS_NERUBIAN, GetRectCenter(gg_rct_Demon_Prince_Boss_Spawn), 315., FourCC('n02U'), "Nerubian Empress", 0,
    0, 2000)
    -- Giant Polar Bear
    boss = Boss.create(BOSS_POLAR_BEAR, Location(-16040., 6579.), 45., FourCC('n0pb'), "Giant Polar Bear", 0,
    0, 2000)
    -- The Goddesses
    boss = Boss.create(BOSS_LIFE, Location(-1840., -27400.), 230., FourCC('H04Q'), "The Goddesses", 180,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Hate
    boss = Boss.create(BOSS_HATE, Location(-1977., -27116.), 230., FourCC('E00B'), "Hate", 180,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Love
    boss = Boss.create(BOSS_LOVE, Location(-1560., -27486.), 230., FourCC('E00D'), "Love", 180,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Knowledge
    boss = Boss.create(BOSS_KNOWLEDGE, Location(-1689., -27210.), 230., FourCC('E00C'), "Knowledge", 180,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Arkaden
    boss = Boss.create(BOSS_ARKADEN, Location(-1413., -15846.), 90., FourCC('H00O'), "Arkaden", 140,
    0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    local function arkaden_death()
        SetUnitAnimation(god_angel, "birth")
        ShowUnit(god_angel, true)
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(god_angel), GetUnitY(god_angel)))
        SetCinematicScene(GetUnitTypeId(god_angel), GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), "Angel", "Halt! Before proceeding you must bring me the 3 keys to unlock the seal and face the gods in their domain.", 8, 7)
    end
    EVENT_ON_DEATH:register_unit_action(boss, arkaden_death)

    -- start death march cooldown
    BlzStartUnitAbilityCooldown(Boss[BOSS_DEATH_KNIGHT].unit, FourCC('A0AU'), 2040. - (User.AmountPlaying * 240))

    ShowUnit(Boss[BOSS_LIFE].unit, false) --gods
    ShowUnit(Boss[BOSS_LOVE].unit, false)
    ShowUnit(Boss[BOSS_HATE].unit, false)
    ShowUnit(Boss[BOSS_KNOWLEDGE].unit, false)

    -- evil shopkeepers
    do
        evilshopkeeperbrother = gg_unit_n02S_0098
        evilshopkeeper = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n01F'), 7284., -13177., 270.)
        EVENT_ON_DEATH:register_unit_action(evilshopkeeper, function(u)
            CreateItem(FourCC('I045'), GetUnitX(u), GetUnitY(u)) -- bloodstained cloak
        end)
    end

    -- hero circle
    HeroCircle[0] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_OBLIVION_GUARD, 30000., 30000., 0.), --oblivion guard
        skin = HERO_OBLIVION_GUARD,
        select = FourCC('A07S'),
        passive = FourCC('A0HQ')
    }
    HeroCircle[1] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_BLOODZERKER, 30000., 30000., 0.), --bloodzerker
        skin = HERO_BLOODZERKER,
        select = FourCC('A07T'),
        passive = FourCC('A06N')
    }
    HeroCircle[2] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_ROYAL_GUARDIAN, 30000., 30000., 0.), --royal guardian
        skin = HERO_ROYAL_GUARDIAN,
        select = FourCC('A07U'),
        passive = FourCC('A0I5')
    }
    HeroCircle[3] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_WARRIOR, 30000., 30000., 0.), --warrior
        skin = HERO_WARRIOR,
        select = FourCC('A07V'),
        passive = FourCC('A0IE')
    }
    HeroCircle[4] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_VAMPIRE, 30000., 30000., 0.), --vampire
        skin = HERO_VAMPIRE,
        select = FourCC('A029'),
        passive = FourCC('A05E')
    }
    HeroCircle[5] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_SAVIOR, 30000., 30000., 0.), --savior
        skin = HERO_SAVIOR,
        select = FourCC('A07W'),
        passive = FourCC('A0HW')
    }
    HeroCircle[6] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_DARK_SAVIOR, 30000., 30000., 0.), --dark savior
        skin = HERO_DARK_SAVIOR,
        select = FourCC('A07Z'),
        passive = FourCC('A0DL')
    }
    HeroCircle[7] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_CRUSADER, 30000., 30000., 0.), --Crusader
        skin = HERO_CRUSADER,
        select = FourCC('A080'),
        passive = FourCC('A0I4')
    }
    HeroCircle[8] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_ARCANIST, 30000., 30000., 0.), --arcanist
        skin = HERO_ARCANIST,
        select = FourCC('A081'),
        passive = FourCC('A0EY')
    }
    HeroCircle[9] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_DARK_SUMMONER, 30000., 30000., 0.), --dark summoner
        skin = HERO_DARK_SUMMONER,
        select = FourCC('A082'),
        passive = FourCC('A0I0')
    }
    HeroCircle[10] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_BARD, 30000., 30000., 0.), --bard
        skin = HERO_BARD,
        select = FourCC('A084'),
        passive = FourCC('A0HV')
    }
    HeroCircle[11] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_HYDROMANCER, 30000., 30000., 0.), --hydromancer
        skin = HERO_HYDROMANCER,
        select = FourCC('A086'),
        passive = FourCC('A0EC')
    }
    HeroCircle[12] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_HIGH_PRIEST, 30000., 30000., 0.), --high priestess
        skin = HERO_HIGH_PRIEST,
        select = FourCC('A087'),
        passive = FourCC('A0I2')
    }
    HeroCircle[13] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_ELEMENTALIST, 30000., 30000., 0.), --elementalist
        skin = HERO_ELEMENTALIST,
        select = FourCC('A089'),
        passive = FourCC('A0I3')
    }
    HeroCircle[14] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_ASSASSIN, 30000., 30000., 0.), --assassin
        skin = HERO_ASSASSIN,
        select = FourCC('A07J'),
        passive = FourCC('A01N')
    }
    HeroCircle[15] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_THUNDERBLADE, 30000., 30000., 0.), --thunder blade
        skin = HERO_THUNDERBLADE,
        select = FourCC('A01P'),
        passive = FourCC('A039')
    }
    HeroCircle[16] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_MASTER_ROGUE, 30000., 30000., 0.), --master rogue
        skin = HERO_MASTER_ROGUE,
        select = FourCC('A07L'),
        passive = FourCC('A0I1')
    }
    HeroCircle[17] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_MARKSMAN, 30000., 30000., 0.), --elite marksman
        skin = HERO_MARKSMAN,
        select = FourCC('A07M'),
        passive = FourCC('A070')
    }
    HeroCircle[18] = {
        unit = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), HERO_PHOENIX_RANGER, 30000., 30000., 0.), --phoenix ranger
        skin = HERO_PHOENIX_RANGER,
        select = FourCC('A07N'),
        passive = FourCC('A0I6')
    }

    for i = 0, HERO_TOTAL do
        if HeroCircle[i] then
            local angle = bj_PI * (HERO_TOTAL - i) / (HERO_TOTAL * 0.5)

            SetUnitPosition(HeroCircle[i].unit, 21643. + 475. * Cos(angle), 3447. + 475. * Sin(angle))
            SetUnitFacingTimed(HeroCircle[i].unit, bj_RADTODEG * Atan2(3447. - GetUnitY(HeroCircle[i].unit), 21643. - GetUnitX(HeroCircle[i].unit)), 0)

            UnitAddAbility(HeroCircle[i].unit, FourCC('Aloc'))
        end
    end

    --spawn prechaos enemies
    SpawnCreeps(0)

    --ashen vat
    ASHEN_VAT = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h05J'), 20485., -20227., 270.)
end, Debug and Debug.getLine())
