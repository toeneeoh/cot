--[[
    dungeons.lua

    This module contains dungeon related globals and functions.
]]

OnInit.final("Dungeons", function(Require)
    Require('Variables')

    DungeonTable  = {} ---@type table 

    QUEUE_DUNGEON = 0 ---@type integer 
    QUEUE_GROUP   = {} ---@type player[]
    QUEUE_X       = 0. ---@type number 
    QUEUE_Y       = 0. ---@type number 
    QUEUE_LEVEL   = 0 ---@type integer 
    QUEUE_READY   = {} ---@type boolean[] 

    NAGA_FLOOR         = 0 ---@type integer 
    NAGA_TIMER         = nil ---@type TimerFrame 
    NAGA_ENEMIES       = {}
    nagatp             = nil ---@type unit 
    nagachest          = nil ---@type unit 
    nagaboss           = nil ---@type unit 
    nagawaterstrikecd  = false ---@type boolean 

    NAGA_GROUP      = {} ---@type integer[]
    AZAZOTH_GROUP   = {} ---@type player[]

    DUNGEON_AZAZOTH = FourCC('I08T') ---@type integer 
    DUNGEON_NAGA    = FourCC('I0JU') ---@type integer 

    DUNGEONS = {
        DUNGEON_AZAZOTH,
        DUNGEON_NAGA,
    }

    DungeonTable[DUNGEON_AZAZOTH] = {}
    DungeonTable[DUNGEON_AZAZOTH].level = 360
    DungeonTable[DUNGEON_AZAZOTH].queue = 0
    DungeonTable[DUNGEON_AZAZOTH].playercount = 0
    DungeonTable[DUNGEON_AZAZOTH].group = AZAZOTH_GROUP
    DungeonTable[DUNGEON_AZAZOTH].name = "Azazoth's Lair"
    DungeonTable[DUNGEON_AZAZOTH].queueloc = Location(-1408., -15246.)
    DungeonTable[DUNGEON_AZAZOTH].entrance = Location(-2036., -28236.)

    DungeonTable[DUNGEON_NAGA] = {}
    DungeonTable[DUNGEON_NAGA].level = 400
    DungeonTable[DUNGEON_NAGA].queue = 0
    DungeonTable[DUNGEON_NAGA].playercount = 0
    DungeonTable[DUNGEON_NAGA].group = NAGA_GROUP
    DungeonTable[DUNGEON_NAGA].name = "Naga Dungeon"
    DungeonTable[DUNGEON_NAGA].queueloc = Location(-12363., -1185.)
    DungeonTable[DUNGEON_NAGA].entrance = Location(-20000., -4600.)

    --if a dungeon is failed
    function DungeonFail(pid)
        local p = Player(pid - 1)

        --azazoth reset
        if TableHas(AZAZOTH_GROUP, p) then
            TableRemove(AZAZOTH_GROUP, p)

            DisplayTimedTextToPlayer(p, 0, 0, 20.00, "|c00ff3333Azazoth: Mortal weakling, begone! Your flesh is not even worth annihilation.")

            if #AZAZOTH_GROUP == 0 then
                Buff.dispelAll(BossTable[BOSS_AZAZOTH].unit)
                SetUnitLifePercentBJ(BossTable[BOSS_AZAZOTH].unit, 100)
                SetUnitManaPercentBJ(BossTable[BOSS_AZAZOTH].unit, 100)
                SetUnitPosition(BossTable[BOSS_AZAZOTH].unit, GetRectCenterX(gg_rct_Azazoth_Boss_Spawn), GetRectCenterY(gg_rct_Azazoth_Boss_Spawn))
                BlzSetUnitFacingEx(BossTable[BOSS_AZAZOTH].unit, 90.00)
            end

        --naga dungeon
        elseif TableHas(NAGA_GROUP, pid) then
            TableRemove(NAGA_GROUP, pid)

            if #NAGA_GROUP <= 0 then
                NAGA_TIMER:destroy()
                NAGA_ENEMIES = {}
            end
        end
    end

    --actions after a dungeon is finished
    function DungeonComplete(id)
        StartSound(bj_questCompletedSound)

        --clear dungeon group
        DungeonTable[id].group = {}

        if id == DUNGEON_AZAZOTH then

        elseif id == DUNGEON_NAGA then
            nagachest = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h002'), -22141, -10500, 0)
            DisplayTextToTable(NAGA_GROUP, "You have vanquished the Ancient Nagas!")
            if NAGA_TIMER then --time restriction
                NAGA_TIMER:destroy()
                Item.create(CreateItem(FourCC('I0NN'), x, y)) --token
                if DungeonTable[DUNGEON_NAGA].playercount > 3 and GetRandomInt(0, 99) < 50 then
                    Item.create(CreateItem(FourCC('I0NN'), x, y))
                end
            end
            for _, pid in ipairs(NAGA_GROUP) do
                local XP = R2I(Experience_Table[500] / 700. * XP_Rate[pid])
                AwardXP(pid, XP)
                EnableItems(pid)
            end
        end

        --display end UI
    end

    function NagaWaygate()
        local ug = CreateGroup()

        GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Reward, Condition(ischar))

        if BlzGroupGetSize(ug) == 0 then
            TimerQueue:callDelayed(2.5, RemoveUnit, nagachest)
            if NAGA_FLOOR == 1 then
                BlackMask(NAGA_GROUP, 2, 2)
                DungeonMove(NAGA_GROUP, -20000, -4600, 2)
                TimerQueue:callDelayed(2., RemoveUnit, nagatp)
                NagaSpawnFloor(NAGA_FLOOR + 1)
            elseif NAGA_FLOOR == 2 then
                BlackMask(NAGA_GROUP, 2, 2)
                DungeonMove(NAGA_GROUP, -24192, -10500, 2)
                TimerQueue:callDelayed(2., RemoveUnit, nagatp)
                NagaSpawnFloor(NAGA_FLOOR + 1)
            end
        end

        DestroyGroup(ug)
    end

    ---@type fun(id: integer, x: number, y: number, facing: number, dmgr: integer, g: table):unit
    function DungeonCreateUnit(id, x, y, facing, dmgr, g)
        local u = CreateUnit(pfoe, id, x, y, facing)
        g[#g + 1] = u
        Unit[u].dr = (1 - dmgr * 0.1)
        return u
    end

    ---@type fun(tbl: table, x: number, y: number)
    local function DungeonMoveExpire(tbl, x, y)
        for _, pid in ipairs(tbl) do
            pid = (type(pid) == "userdata" and GetPlayerId(pid) + 1) or pid
            MoveHero(pid, x, y)
        end
    end

    ---@type fun(tbl: table, x: number, y:number, delay: number)
    function DungeonMove(tbl, x, y, delay)
        TimerQueue:callDelayed(delay, DungeonMoveExpire, tbl, x, y)
    end

    --naga dungeon

    ---@type fun(killed: unit)
    function AdvanceNagaDungeon(killed)
        TableRemove(NAGA_ENEMIES, killed)

        if #NAGA_ENEMIES <= 0 then
            if NAGA_FLOOR < 3 then
                nagachest = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h002'), -23000, -3750, 270)
                nagatp = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n00O'), -21894, -4667, 270)
                MovePlayers(NAGA_GROUP, -24000, -4700)
                WaygateSetDestination(nagatp, -27637, -7440)
                WaygateActivate(nagatp, true)
            end
        end
    end

    function NagaReward()
        local pcount  = DungeonTable[DUNGEON_NAGA].playercount ---@type integer 
        local plat    = GetRandomInt(12, 15) + pcount * 3 ---@type integer 
        local arc     = GetRandomInt(12, 15) + pcount * 3 ---@type integer 
        local crystal = GetRandomInt(12, 15) + pcount * 3 ---@type integer 

        DisplayTimedTextToTable(NAGA_GROUP, 7.5, "|cffffcc00You have been rewarded:|r \n|cffe3e2e2" .. (plat) .. " Platinum|r \n|cff66FF66" .. (arc) .. " Arcadite|r \n|cff6969FF" .. (crystal) .. " Crystals|r")

        for _, p in ipairs(NAGA_GROUP) do
            local pid = GetPlayerId(p) + 1
            AddCurrency(pid, PLATINUM, plat)
            AddCurrency(pid, ARCADITE, arc)
            AddCurrency(pid, CRYSTAL, crystal)
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))
        end
    end

    ---@param floor integer
    function NagaSpawnFloor(floor)
        local pcount = DungeonTable[DUNGEON_NAGA].playercount ---@type integer 

        NAGA_FLOOR = floor

        if NAGA_FLOOR == 1 then
            DungeonCreateUnit(FourCC('n01L'), -20607, -3733, 335, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -22973, -2513, 0, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -25340, -4218, 45, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -24980, -6070, 335, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -23087, -6656, 0, pcount, NAGA_ENEMIES)
            DungeonCreateUnit(FourCC('n01L'), -20567, -5402, 45, pcount, NAGA_ENEMIES)
        elseif NAGA_FLOOR == 2 then
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -20607, -3733, 335, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -22973, -2513, 0, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -25340, -4218, 45, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -24980, -6070, 335, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -23087, -6656, 0, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
            UnitAddBonus(DungeonCreateUnit(FourCC('n005'), -20567, -5402, 45, pcount, NAGA_ENEMIES), BONUS_DAMAGE, 200000 * pcount)
        elseif NAGA_FLOOR == 3 then
            nagaboss = DungeonCreateUnit(FourCC('O006'), -20828, -10500, 180, pcount, NAGA_ENEMIES)
            AddSpecialEffectTarget("LightYellow30.mdl", nagaboss, "origin")
            SetHeroLevel(nagaboss, 500, false)
        end
    end

    ---@type fun(source: unit, dmg: number, x: number, y: number, aoe: number, filter: boolexpr)
    function NagaTridentStrike(source, dmg, x, y, aoe, filter)
        local ug = CreateGroup()

        GroupEnumUnitsInRange(ug, x, y, aoe, filter)

        for target in each(ug) do
            DamageTarget(source, target, dmg, ATTACK_TYPE_NORMAL, MAGIC, "Trident Strike")
        end

        DestroyGroup(ug)
    end

    ---@type fun(amount: number, source: unit, target: unit, damageType: damagetype): number
    function DungeonOnDamage(amount, source, target, damageType)
        local uid = GetUnitTypeId(source) ---@type integer 
        local tuid = GetUnitTypeId(target) ---@type integer 

        --target
        if tuid == FourCC('n01L') then --naga defender
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04K')) == 0 and GetUnitLifePercent(target) < 90. then
                IssueImmediateOrder(target, "berserk")
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04R')) == 0 and GetUnitLifePercent(target) < 80. then
                IssueImmediateOrder(target, "battleroar")
            end

            if damageType == PHYSICAL and GetUnitAbilityLevel(target, FourCC('B04S')) > 0 then
                DamageTarget(target, source, BlzGetUnitMaxHP(source) * 0.4, ATTACK_TYPE_NORMAL, MAGIC)
            end
        elseif tuid == FourCC('n005') then --naga elite
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04V')) == 0 and GetUnitLifePercent(target) < 90. then
                IssueImmediateOrder(target, "battleroar")
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04W')) == 0 and GetUnitLifePercent(target) < 80. then
                IssueImmediateOrder(target, "berserk")
            end
        elseif tuid == FourCC('O006') then --naga boss
            if nagawaterstrikecd == false then
                nagawaterstrikecd = true
                TimerQueue:callDelayed(5., NagaWaterStrike)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05C')) == 0 and GetUnitLifePercent(target) < 90. then
                IssueImmediateOrder(target, "berserk")
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05K')) == 0 and GetUnitLifePercent(target) < 80. then
                IssueImmediateOrder(target, "battleroar")
            end
        elseif tuid == FourCC('u002') then --beetle
            if damageType == MAGIC then
                amount = 0.00
            end
        end

        --source
        if uid == FourCC('n01L') then --naga defender
            if damageType == PHYSICAL then
                amount = 0.00

                if not Unit[source].hits then
                    Unit[source].hits = 0
                end

                Unit[source].hits = Unit[source].hits + 1
                FloatingTextUnit(tostring(Unit[source].hits), target, 1.5, 50, 150., 14.5, 255, 255, 255, 0, true)

                if Unit[source].target ~= target then
                    Unit[source].hits = 1
                elseif Unit[source].hits > 2 then
                    NagaTridentStrike(source, BlzGetUnitMaxHP(target) * 0.7, GetUnitX(target), GetUnitY(target), 120., Condition(isplayerunit))
                    DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", target, "origin"))
                    Unit[source].hits = 0
                end

                Unit[source].target = target
            end
        elseif uid == FourCC('n005') then --naga elite

        elseif uid == FourCC('u002') then --beetle
            Stun:add(source, target):duration(8.)
            KillUnit(source)
        elseif uid == FourCC('h003') then --naga water strike
            amount = 0.00
            if UnitAlive(nagaboss) then
                DamageTarget(nagaboss, target, BlzGetUnitMaxHP(target) * 0.075, ATTACK_TYPE_NORMAL, MAGIC, "Water Strike")
            end
            RemoveUnit(source)
        end

        return amount
    end

    ---@type fun(time: integer)
    function SpiritCallPeriodic(time)
        local ug  = CreateGroup()
        local ug2 = CreateGroup()

        time = time - 1

        GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Boss, Condition(isspirit))

        if time >= 0 then
            for target in each(ug) do
                if GetRandomInt(0, 99) < 25 then
                    GroupEnumUnitsInRect(ug2, gg_rct_Naga_Dungeon_Boss, Condition(isplayerunit))
                    local u = BlzGroupUnitAt(ug2, GetRandomInt(0, BlzGroupGetSize(ug2) - 1))
                    IssuePointOrder(target, "move", GetUnitX(u) + GetRandomInt(-150, 150), GetUnitY(u) + GetRandomInt(-150, 150))
                end
                GroupEnumUnitsInRange(ug2, GetUnitX(target), GetUnitY(target), 300., Condition(isplayerunit))
                for enemy in each(ug2) do
                    local dummy = Dummy.create(GetUnitX(target), GetUnitY(target), FourCC('A09R'), 1).unit
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(enemy) - GetUnitY(target), GetUnitX(enemy) - GetUnitX(target)))
                    InstantAttack(dummy, enemy)
                    SpiritCallSlow:add(target, enemy):duration(5.)
                    DamageTarget(target, enemy, BlzGetUnitMaxHP(enemy) * 0.1, ATTACK_TYPE_NORMAL, MAGIC, "Spirit Call")
                end
            end
            TimerQueue:callDelayed(1., SpiritCallPeriodic, time)
        else
            for target in each(ug) do
                SetUnitVertexColor(target, 100, 255, 100, 255)
                SetUnitScale(target, 1, 1, 1)
                IssuePointOrder(target, "move", GetRandomReal(GetRectMinX(gg_rct_Naga_Dungeon_Boss_Vision), GetRectMaxX(gg_rct_Naga_Dungeon_Boss_Vision)), GetRandomReal(GetRectMinY(gg_rct_Naga_Dungeon_Boss_Vision), GetRectMaxY(gg_rct_Naga_Dungeon_Boss_Vision)))
            end
        end

        DestroyGroup(ug)
        DestroyGroup(ug2)
    end

    function SpiritCall()
        local ug = CreateGroup()

        GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Boss, Condition(isspirit))

        for target in each(ug) do
            SetUnitVertexColor(target, 255, 25, 25, 255)
            SetUnitScale(target, 1.25, 1.25, 1.25)
        end

        TimerQueue:callDelayed(1., SpiritCallPeriodic, 15)

        DestroyGroup(ug)
    end

    ---@type fun(x: number, y: number)
    function CollapseExpire(x, y)
        local ug = CreateGroup()

        GroupEnumUnitsInRange(ug, x, y, 500., Condition(isplayerunit))
        DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x + 150, y + 150))
        DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x - 150, y - 150))
        DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x + 150, y - 150))
        DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", x - 150, y + 150))

        for target in each(ug) do
            DamageTarget(nagaboss, target, BlzGetUnitMaxHP(target) * GetRandomReal(0.75, 1), ATTACK_TYPE_NORMAL, MAGIC, "Collapse")
        end

        DestroyGroup(ug)
    end

    function NagaCollapse()
        local dummy ---@type unit 

        for _ = 0, 9 do
            dummy = Dummy.create(GetRandomReal(GetRectMinX(gg_rct_Naga_Dungeon_Boss), GetRectMaxX(gg_rct_Naga_Dungeon_Boss)), GetRandomReal(GetRectMinY(gg_rct_Naga_Dungeon_Boss), GetRectMaxY(gg_rct_Naga_Dungeon_Boss)), 0, 0, 4.).unit
            BlzSetUnitFacingEx(dummy, 270.)
            BlzSetUnitSkin(dummy, FourCC('e01F'))
            SetUnitScale(dummy, 10., 10., 10.)
            SetUnitVertexColor(dummy, 0, 255, 255, 255)
            TimerQueue:callDelayed(3., CollapseExpire, GetUnitX(dummy), GetUnitY(dummy))
        end
    end

    function NagaWaterStrike()
        if UnitAlive(nagaboss) then
            local ug = CreateGroup()

            MakeGroupInRect(FOE_ID, ug, gg_rct_Naga_Dungeon_Boss, Condition(FilterEnemy))

            for target in each(ug) do
                local dummy = CreateUnit(pfoe, FourCC('h003'), GetUnitX(nagaboss), GetUnitY(nagaboss), 0)
                IssueTargetOrder(dummy, "smart", target)
            end

            DestroyGroup(ug)
        else
            nagawaterstrikecd = false
        end
    end

    ---@type fun(caster: unit, time: integer)
    function NagaMiasmaDamage(caster, time)
        time = time - 1

        if time > 0 then
            local ug = CreateGroup()

            GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon, Condition(isplayerunit))

            for target in each(ug) do
                if ModuloInteger(time, 2) == 0 then
                    TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Units\\Undead\\PlagueCloud\\PlagueCloudtarget.mdl", target, "overhead"))
                end
                DamageTarget(caster, target, 25000 + BlzGetUnitMaxHP(target) * 0.03, ATTACK_TYPE_NORMAL, MAGIC, "Miasma")
            end
            TimerQueue:callDelayed(0.5, NagaMiasmaDamage, caster, time)

            DestroyGroup(ug)
        end
    end

    ---@type fun(source: unit, target: unit)
    function SwarmBeetle(source, target)
    PauseUnit(source, false)
    UnitRemoveAbility(source, FourCC('Avul'))
    IssueTargetOrder(source, "attack", target)
    UnitApplyTimedLife(source, FourCC('BTLF'), 6.5)
    TimerQueue:callDelayed(5., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Other\\Parasite\\ParasiteTarget.mdl", source, "overhead"))
    end

    ---@type fun(source: unit)
    function ApplyNagaAtkSpeed(source)
        if UnitAlive(source) then
            NagaEliteAtkSpeed:add(source, source):duration(4.)
        end
    end

    ---@type fun(source: unit)
    function ApplyNagaThorns(source)
        if UnitAlive(source) then
            NagaThorns:add(source, source):duration(6.5)
        end
    end

    local function NAGA_TIMER_END()
        DisplayTextToTable(NAGA_GROUP, "Prestige token will no longer drop.")
    end

    --end naga dungeon

    function DungeonStarter()
        local U = User.first ---@type User 
        local dungeon = DungeonTable[QUEUE_DUNGEON]

        while U do
            if TableHas(QUEUE_GROUP, U.player) and QUEUE_READY[U.id] then
                MoveHeroLoc(U.id, dungeon.entrance)
                dungeon.group[#dungeon.group + 1] = U.player
                dungeon.playercount = dungeon.playercount + 1

                --TODO should dungeon disable item dropping?
                DisableItems(U.id)

                TableRemove(QUEUE_GROUP, U.player)

                --minimize queue multiboard if currently viewing
                if MULTIBOARD.bodies[MULTIBOARD.lookingAt[U.id]] == MULTIBOARD.QUEUE then
                    MULTIBOARD.minimize(U.id)
                end
            end

            QUEUE_READY[U.id] = false
            U = U.next
        end

        if QUEUE_DUNGEON == DUNGEON_NAGA then
            NagaSpawnFloor(1)

            NAGA_TIMER = TimerFrame.create("Prestige Token available:", 1800, NAGA_TIMER_END, NAGA_GROUP)
        end

        QUEUE_DUNGEON = 0
        QUEUE_LEVEL = 0
    end

    ---@param id integer
    function ReadyCheck(id)
        local U      = User.first ---@type User 
        local allReady         = true ---@type boolean 

        while U do
            if not QUEUE_READY[U.id] and TableHas(QUEUE_GROUP, U.player) then
                allReady = false
            end
            U = U.next
        end

        if allReady then
            BlackMask(QUEUE_GROUP, 2, 2)

            DungeonTable[id].playercount = 0

            TimerQueue:callDelayed(2., DungeonStarter)
        else
            DisplayTextToTable(QUEUE_GROUP, "Not all players are ready to start the dungeon!")
        end
    end

    ---@param pid integer
    ---@param id integer
    function QueueDungeon(pid, id)
        if #DungeonTable[id].group > 0 then
            DisplayTextToPlayer(Player(pid - 1), 0, 0, "This dungeon is already in progress!")
        else
            if QUEUE_DUNGEON == 0 then
                QUEUE_X = GetLocationX(DungeonTable[id].queueloc)
                QUEUE_Y = GetLocationY(DungeonTable[id].queueloc)
                QUEUE_LEVEL = DungeonTable[id].level
                QUEUE_DUNGEON = id

                QUEUE_GROUP = {}
                MULTIBOARD.QUEUE.title = DungeonTable[id].name
            elseif QUEUE_DUNGEON == id then
                ReadyCheck(id)
            else
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Please wait while another dungeon is queueing!")
            end
        end
    end
end, Debug.getLine())
