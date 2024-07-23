--[[
    units.lua

    A library that spawns units and does any necessary setup related to units.
    Sets up creeps, bosses, NPCs, etc.
]]

OnInit.final("Units", function(Require)
    Require('Shop')
    Require('Items')
    Require('Damage')

    BossTable         = {} ---@type table[]
    BossNearbyPlayers = __jarray(0) ---@type integer[] 
    --ice troll trapper
    local id = FourCC('nitt')
    UnitData[id].count = 18
    UnitData[id].spawn = 1
    UnitData[0][0] = id
    --ice troll berserker
    id = FourCC('nits')
    UnitData[id].count = 10
    UnitData[id].spawn = 1
    UnitData[0][1] = id
    --tuskarr sorc
    id = FourCC('ntks')
    UnitData[id].count = 10
    UnitData[id].spawn = 2
    UnitData[0][2] = id
    --tuskarr warrior
    id = FourCC('ntkw')
    UnitData[id].count = 11
    UnitData[id].spawn = 2
    UnitData[0][3] = id
    --tuskarr chieftain
    id = FourCC('ntkc')
    UnitData[id].count = 9
    UnitData[id].spawn = 2
    UnitData[0][4] = id
    --nerubian Seer
    id = FourCC('nnwr')
    UnitData[id].count = 18
    UnitData[id].spawn = 3
    UnitData[0][5] = id
    --nerubian spider lord
    id = FourCC('nnws')
    UnitData[id].count = 18
    UnitData[id].spawn = 3
    UnitData[0][6] = id
    --polar furbolg warrior 
    id = FourCC('nfpu')
    UnitData[id].count = 38
    UnitData[id].spawn = 4
    UnitData[0][7] = id
    --polar furbolg elder shaman
    id = FourCC('nfpe')
    UnitData[id].count = 22
    UnitData[id].spawn = 4
    UnitData[0][8] = id
    --giant polar bear
    id = FourCC('nplg')
    UnitData[id].count = 20
    UnitData[id].spawn = 5
    UnitData[0][9] = id
    --dire mammoth
    id = FourCC('nmdr')
    UnitData[id].count = 16
    UnitData[id].spawn = 5
    UnitData[0][10] = id
    --ogre overlord
    id = FourCC('n01G')
    UnitData[id].count = 55
    UnitData[id].spawn = 6
    UnitData[0][11] = id
    --tauren
    id = FourCC('o01G')
    UnitData[id].count = 40
    UnitData[id].spawn = 6
    UnitData[0][12] = id
    --unbroken deathbringer
    id = FourCC('nfod')
    UnitData[id].count = 18
    UnitData[id].spawn = 7
    UnitData[0][13] = id
    --unbroken trickster
    id = FourCC('nfor')
    UnitData[id].count = 15
    UnitData[id].spawn = 7
    UnitData[0][14] = id
    --unbroken darkweaver
    id = FourCC('nubw')
    UnitData[id].count = 12
    UnitData[id].spawn = 7
    UnitData[0][15] = id
    --lesser hellfire
    id = FourCC('nvdl')
    UnitData[id].count = 25
    UnitData[id].spawn = 8
    UnitData[0][16] = id
    --lesser hellhound
    id = FourCC('nvdw')
    UnitData[id].count = 30
    UnitData[id].spawn = 8
    UnitData[0][17] = id
    --centaur lancer
    id = FourCC('n027')
    UnitData[id].count = 25
    UnitData[id].spawn = 9
    UnitData[0][18] = id
    --centaur ranger
    id = FourCC('n024')
    UnitData[id].count = 20
    UnitData[id].spawn = 9
    UnitData[0][19] = id
    --centaur mage
    id = FourCC('n028')
    UnitData[id].count = 15
    UnitData[id].spawn = 9
    UnitData[0][20] = id
    --magnataur destroyer
    id = FourCC('n01M')
    UnitData[id].count = 45
    UnitData[id].spawn = 10
    UnitData[0][21] = id
    --forgotten one
    id = FourCC('n08M')
    UnitData[id].count = 20
    UnitData[id].spawn = 10
    UnitData[0][22] = id
    --ancient hydra
    id = FourCC('n01H')
    UnitData[id].count = 4
    UnitData[id].spawn = 11
    UnitData[0][23] = id
    --frost dragon
    id = FourCC('n02P')
    UnitData[id].count = 18
    UnitData[id].spawn = 12
    UnitData[0][24] = id
    --frost drake
    id = FourCC('n01R')
    UnitData[id].count = 18
    UnitData[id].spawn = 12
    UnitData[0][25] = id
    --frost elder
    id = FourCC('n099')
    UnitData[id].count = 1
    UnitData[id].spawn = 14
    UnitData[0][26] = id
    --medean berserker
    id = FourCC('n00C')
    UnitData[id].count = 7
    UnitData[id].spawn = 13
    UnitData[0][27] = id
    --medean devourer
    id = FourCC('n02L')
    UnitData[id].count = 15
    UnitData[id].spawn = 13
    UnitData[0][28] = id

    --demon
    id = FourCC('n033')
    UnitData[id].count = 20
    UnitData[id].spawn = 1
    UnitData[1][0] = id
    --demon wizard
    id = FourCC('n034')
    UnitData[id].count = 11
    UnitData[id].spawn = 1
    UnitData[1][1] = id
    --horror young
    id = FourCC('n03C')
    UnitData[id].count = 24
    UnitData[id].spawn = 15
    UnitData[1][2] = id
    --horror mindless
    id = FourCC('n03A')
    UnitData[id].count = 46
    UnitData[id].spawn = 15
    UnitData[1][3] = id
    --horror leader
    id = FourCC('n03B')
    UnitData[id].count = 11
    UnitData[id].spawn = 15
    UnitData[1][4] = id
    --despair
    id = FourCC('n03F')
    UnitData[id].count = 62
    UnitData[id].spawn = 18
    UnitData[1][5] = id
    --despair wizard
    id = FourCC('n01W')
    UnitData[id].count = 30
    UnitData[id].spawn = 18
    UnitData[1][6] = id
    --abyssal beast
    id = FourCC('n00X')
    UnitData[id].count = 19
    UnitData[id].spawn = 16
    UnitData[1][7] = id
    --abyssal guardian
    id = FourCC('n08N')
    UnitData[id].count = 34
    UnitData[id].spawn = 16
    UnitData[1][8] = id
    --abyssal spirit
    id = FourCC('n00W')
    UnitData[id].count = 34
    UnitData[id].spawn = 16
    UnitData[1][9] = id
    --void seeker
    id = FourCC('n030')
    UnitData[id].count = 30
    UnitData[id].spawn = 17
    UnitData[1][10] = id
    --void keeper
    id = FourCC('n031')
    UnitData[id].count = 40
    UnitData[id].spawn = 17
    UnitData[1][11] = id
    --void mother
    id = FourCC('n02Z')
    UnitData[id].count = 40
    UnitData[id].spawn = 17
    UnitData[1][12] = id
    --nightmare creature
    id = FourCC('n020')
    UnitData[id].count = 22
    UnitData[id].spawn = 9
    UnitData[1][13] = id
    --nightmare spirit
    id = FourCC('n02J')
    UnitData[id].count = 18
    UnitData[id].spawn = 9
    UnitData[1][14] = id
    --spawn of hell
    id = FourCC('n03E')
    UnitData[id].count = 18
    UnitData[id].spawn = 8
    UnitData[1][15] = id
    --death dealer
    id = FourCC('n03D')
    UnitData[id].count = 16
    UnitData[id].spawn = 8
    UnitData[1][16] = id
    --lord of plague
    id = FourCC('n03G')
    UnitData[id].count = 6
    UnitData[id].spawn = 8
    UnitData[1][17] = id
    --denied existence
    id = FourCC('n03J')
    UnitData[id].count = 24
    UnitData[id].spawn = 13
    UnitData[1][18] = id
    --deprived existence
    id = FourCC('n01X')
    UnitData[id].count = 13
    UnitData[id].spawn = 13
    UnitData[1][19] = id
    --astral being
    id = FourCC('n03M')
    UnitData[id].count = 24
    UnitData[id].spawn = 12
    UnitData[1][20] = id
    --astral entity
    id = FourCC('n01V')
    UnitData[id].count = 13
    UnitData[id].spawn = 12
    UnitData[1][21] = id
    --dimensional planewalker
    id = FourCC('n026')
    UnitData[id].count = 22
    UnitData[id].spawn = 7
    UnitData[1][22] = id
    --dimensional planeshifter
    id = FourCC('n03T')
    UnitData[id].count = 18
    UnitData[id].spawn = 7
    UnitData[1][23] = id

    --forgotten units
    forgottenTypes[0] = FourCC('o030') --corpse basher
    forgottenTypes[1] = FourCC('o033') --destroyer
    forgottenTypes[2] = FourCC('o036') --spirit
    forgottenTypes[3] = FourCC('o02W') --warrior
    forgottenTypes[4] = FourCC('o02Y') --monster

    local x = 0. ---@type number 
    local y = 0. ---@type number 

    --velreon guard
    velreon_guard = CreateUnit(Player(PLAYER_TOWN), FourCC('h04A'), 29919., -2419., 225.)
    PauseUnit(velreon_guard, true)

    --angel
    god_angel = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n0A1'), -1841., -14858., 325.)
    ShowUnit(god_angel, false)

    --zeknen
    zeknen = CreateUnit(pboss, FourCC('O01A'), -1886., -27549., 225.)
    SetHeroLevel(zeknen, 150, false)
    PauseUnit(zeknen, true)
    UnitAddAbility(zeknen, FourCC('Avul'))

    --sponsor
    BlzSetUnitMaxHP(udg_SPONSOR, 1)
    BlzSetUnitMaxMana(udg_SPONSOR, 0)
    UnitAddItemById(udg_SPONSOR, FourCC('I0ML'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MH'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MI'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MJ'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MK'))
    UnitAddItemById(udg_SPONSOR, FourCC('I0MG'))
    --town paladin
    townpaladin = CreateUnit(Player(PLAYER_TOWN), FourCC('H01T'), -176.3, 666, 90.)
    BlzSetUnitMaxMana(townpaladin, 0)

    local function paladin_on_hit(target, source, amount, amount_after_red, damage_type)
        if amount_after_red >= 100. then
            if GetRandomInt(0, 1) == 0 then
                local pt = TimerList[0]:get('pala', source)
                local pid = GetPlayerId(GetOwningPlayer(source)) + 1

                if pt then
                    pt.dur = 25.
                else
                    PaladinEnrage(true)

                    pt = TimerList[0]:add()
                    pt.dur = 25.
                    pt.source = source
                    pt.tag = 'pala'
                    pt.pid = pid

                    SetPlayerAllianceStateBJ(Player(pid - 1), Player(PLAYER_TOWN), bj_ALLIANCE_UNALLIED)
                    SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), Player(pid - 1), bj_ALLIANCE_UNALLIED)

                    if GetUnitCurrentOrder(target) ~= OrderId("attack") or GetUnitCurrentOrder(target) ~= OrderId("smart") then
                        IssueTargetOrder(target, "attack", source)
                    end

                    pt.timer:callDelayed(0.5, PaladinAggroExpire, pt)
                end
            end
        end
    end
    EVENT_ON_STRUCK_FINAL:register_unit_action(townpaladin, paladin_on_hit)

    --prechaos trainer
    prechaosTrainer = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h001'), 26205., 252., 270.)
    local itm = UnitAddItemById(prechaosTrainer, FourCC('I0MY'))
    BlzSetItemName(itm.obj, "|cffffcc00" .. GetObjectName(UnitData[0][0]) .. "|r")
    BlzSetItemIconPath(itm.obj, BlzGetAbilityIcon(UnitData[0][0]))
    itm.spawn = 0
    --chaos trainer
    chaosTrainer = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h001'), 29415., 252., 270.)
    itm = UnitAddItemById(chaosTrainer, FourCC('I0MY'))
    BlzSetItemName(itm.obj, "|cffffcc00" .. GetObjectName(UnitData[1][0]) .. "|r")
    BlzSetItemIconPath(itm.obj, BlzGetAbilityIcon(UnitData[1][0]))
    itm.spawn = 0

    --colo banners
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

    --special prechaos "bosses"

    --pinky
    pinky = CreateUnit(pboss, FourCC('O019'), 11528., 8168., 180.)
    SetHeroLevel(pinky, 100, false)
    UnitAddItemById(pinky, FourCC('I02Y'))
    --bryan
    bryan = CreateUnit(pboss, FourCC('H043'), 11528., 7880., 180.)
    SetHeroLevel(bryan, 100, false)
    UnitAddItemById(bryan, FourCC('I02X'))
    --ice troll
    ice_troll = CreateUnit(pboss, FourCC('O00T'), 15833., 4382., 254.)
    SetHeroLevel(ice_troll, 100, false)
    UnitAddItemById(ice_troll, FourCC('I03Z'))
    --kroresh
    kroresh = CreateUnit(pboss, FourCC('N01N'), 17000., -19000., 0.)
    SetHeroLevel(kroresh, 120, false)
    UnitAddItemById(kroresh, FourCC('I0BZ'))
    UnitAddItemById(kroresh, FourCC('I064'))
    UnitAddItemById(kroresh, FourCC('I04B'))
    --forest corruption
    forest_corruption = CreateUnit(pboss, FourCC('N00M'), 5777., -15523., 90.)
    SetHeroLevel(forest_corruption, 100, false)
    UnitAddItemById(forest_corruption, FourCC('I03X'))
    UnitAddItemById(forest_corruption, FourCC('I03Y'))
    Unit[forest_corruption].mr = Unit[forest_corruption].mr * 0.5
    --zeknen
    UnitAddItemById(zeknen, FourCC('I03Y'))
    Unit[zeknen].mr = Unit[zeknen].mr * 0.5

    --prechaos bosses

    -- Minotaur
    local boss = CreateBossEntry(BOSS_TAUREN, Location(-11692., -12774.), 45., FourCC('O002'), "Minotaur", 75,
    {FourCC('I03T'), FourCC('I0FW'), FourCC('I078'), FourCC('I076'), FourCC('I07U'), 0}, 0, 2000)
    -- Forgotten Mystic
    boss = CreateBossEntry(BOSS_MYSTIC, Location(-15435., -14354.), 270., FourCC('H045'), "Forgotten Mystic", 100,
    {FourCC('I03U'), FourCC('I07F'), FourCC('I0F3'), FourCC('I03Y'), 0, 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Hellfire Magi
    boss = CreateBossEntry(BOSS_HELLFIRE, GetRectCenter(gg_rct_Hell_Boss_Spawn), 315., FourCC('U00G'), "Hellfire Magi", 100,
    {FourCC('I03Y'), FourCC('I0FA'), FourCC('I0FU'), FourCC('I00V'), 0, 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Last Dwarf
    boss = CreateBossEntry(BOSS_DWARF, Location(11520., 15466.), 225., FourCC('H01V'), "Last Dwarf", 100,
    {FourCC('I0FC'), FourCC('I079'), FourCC('I03Y'), FourCC('I07B'), 0, 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Vengeful Test Paladin
    boss = CreateBossEntry(BOSS_PALADIN, GetRectCenter(gg_rct_Dark_Soul_Boss_Spawn), 270., FourCC('H02H'), "Vengeful Test Paladin", 140,
    {FourCC('I03P'), FourCC('I0FX'), FourCC('I0F9'), FourCC('I0C0'), FourCC('I03Y'), 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Dragoon
    boss = CreateBossEntry(BOSS_DRAGOON, GetRectCenter(gg_rct_Thanatos_Boss_Spawn), 320., FourCC('O01B'), "Dragoon", 100,
    {FourCC('I0EY'), FourCC('I074'), FourCC('I04N'), FourCC('I0EX'), FourCC('I046'), FourCC('I03Y')}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    Unit[boss].evasion = 50
    -- Death Knight
    boss = CreateBossEntry(BOSS_DEATH_KNIGHT, Location(6932., -14177.), 0., FourCC('H040'), "Death Knight", 120,
    {FourCC('I02B'), FourCC('I029'), FourCC('I02C'), FourCC('I02O'), 0, 0}, 0, 2000)
    -- Siren of the Tides
    boss = CreateBossEntry(BOSS_VASHJ, Location(-12375., -1181.), 0., FourCC('H020'), "Siren of the Tides", 75,
    {FourCC('I09L'), FourCC('I09F'), FourCC('I03Y'), 0, 0, 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Super Fun Happy Yeti
    boss = CreateBossEntry(BOSS_YETI, Location(15816., 6250.), 180., FourCC('n02H'), "Super Fun Happy Yeti", 0,
    {0, 0, 0, 0, 0, 0}, 0, 2000)
    -- King of Ogres
    boss = CreateBossEntry(BOSS_OGRE, Location(-5242., -15630.), 135., FourCC('n03L'), "King of Ogres", 0,
    {0, 0, 0, 0, 0, 0}, 0, 2000)
    -- Nerubian Empress
    boss = CreateBossEntry(BOSS_NERUBIAN, GetRectCenter(gg_rct_Demon_Prince_Boss_Spawn), 315., FourCC('n02U'), "Nerubian Empress", 0,
    {0, 0, 0, 0, 0, 0}, 0, 2000)
    -- Giant Polar Bear
    boss = CreateBossEntry(BOSS_POLAR_BEAR, Location(-16040., 6579.), 45., FourCC('nplb'), "Giant Polar Bear", 0,
    {0, 0, 0, 0, 0, 0}, 0, 2000)
    -- The Goddesses
    boss = CreateBossEntry(BOSS_LIFE, Location(-1840., -27400.), 230., FourCC('H04Q'), "The Goddesses", 180,
    {FourCC('I04I'), FourCC('I030'), FourCC('I031'), FourCC('I02Z'), FourCC('I03Y'), 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Hate
    boss = CreateBossEntry(BOSS_HATE, Location(-1977., -27116.), 230., FourCC('E00B'), "Hate", 180,
    {FourCC('I02Z'), FourCC('I03Y'), FourCC('I02B'), 0, 0, 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Love
    boss = CreateBossEntry(BOSS_LOVE, Location(-1560., -27486.), 230., FourCC('E00D'), "Love", 180,
    {FourCC('I030'), FourCC('I03Y'), FourCC('I0EY'), 0, 0, 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Knowledge
    boss = CreateBossEntry(BOSS_KNOWLEDGE, Location(-1689., -27210.), 230., FourCC('E00C'), "Knowledge", 180,
    {FourCC('I031'), FourCC('I03Y'), FourCC('I03U'), 0, 0, 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5
    -- Arkaden
    boss = CreateBossEntry(BOSS_ARKADEN, Location(-1413., -15846.), 90., FourCC('H00O'), "Arkaden", 140,
    {FourCC('I02B'), FourCC('I02C'), FourCC('I02O'), FourCC('I03Y'), FourCC('I036'), 0}, 0, 2000)
    Unit[boss].mr = Unit[boss].mr * 0.5

    for i = BOSS_OFFSET, #BossTable do
        SetHeroLevel(BossTable[i].unit, BossTable[i].level, false)
        for j = 1, 6 do
            if BossTable[i].item[j] ~= 0 then
                UnitAddItemById(BossTable[i].unit, BossTable[i].item[j])
            end
        end
    end

    --start death march cooldown
    BlzStartUnitAbilityCooldown(BossTable[BOSS_DEATH_KNIGHT].unit, FourCC('A0AU'), 2040. - (User.AmountPlaying * 240))

    ShowUnit(BossTable[BOSS_LIFE].unit, false) --gods
    ShowUnit(BossTable[BOSS_LOVE].unit, false)
    ShowUnit(BossTable[BOSS_HATE].unit, false)
    ShowUnit(BossTable[BOSS_KNOWLEDGE].unit, false)

    --evil shopkeepers
    do
        local onClick = CreateTrigger()
        evilshopkeeperbrother = gg_unit_n02S_0098
        evilshopkeeper = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n01F'), 7284., -13177., 270.)

        --UnitAddAbility(evilshopkeeperbrother, FourCC('Aloc'))

        --[[local track = CreateTrackable("units\\undead\\Acolyte\\Acolyte.mdl", GetUnitX(evilshopkeeperbrother), GetUnitY(evilshopkeeperbrother), 3 * bj_PI / 4.)
        TriggerRegisterTrackableHitEvent(onClick, track)

        ---@return boolean
        local function trackableClick()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            if not SELECTING_HERO[pid] then
                if GetLocalPlayer() == Player(pid - 1) then
                    ClearSelection()
                    SelectUnit(evilshopkeeperbrother, true)
                end
            end

            return false
        end

        TriggerAddCondition(onClick, Condition(trackableClick))
        ]]
    end

    --hero circle
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
