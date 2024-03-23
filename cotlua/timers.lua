--[[
    timers.lua

    A library that initializes game timers and functions that should run periodically.
    Notable functions:
    Tick() - executes roughly 64 times per second
    Periodic() - executes roughly 3 times per second

    Ideally we try to avoid as too much in periodic functions because performance
    is easily affected in wc3 as a single-threaded game.

    Makes use of the timerqueue library for more fluid callback functionality.
]]

if Debug then Debug.beginFile 'Timers' end

OnInit.final("Timers", function(require)
    require 'Units'
    require 'BossAI'
    require 'MapSetup'
    require 'Buffs'
    require 'BuffSystem'
    require 'Multiboard'

    SaveTimer      = {} ---@type timer[] 
    LAST_HERO_X    = __jarray(0) ---@type number[] 
    LAST_HERO_Y    = __jarray(0) ---@type number[] 
    HeroGroup      = CreateGroup()
    wanderingTimer = CreateTimer() ---@type timer 

function DisplayHint()
    local rand = GetRandomInt(2, #HINT_TOOLTIP) ---@type integer 

    if LAST_HINT < 2 then
        LAST_HINT = LAST_HINT + 1
    else
        LAST_HINT = rand
    end

    DisplayTimedTextToForce(FORCE_HINT, 15, HINT_TOOLTIP[LAST_HINT])
    if rand ~= LAST_HINT then
        LAST_HINT = rand
    else
        LAST_HINT = LAST_HINT + 1
    end
    if LAST_HINT > #HINT_TOOLTIP then
        LAST_HINT = 1
    end
end

---@type fun(i: integer)
function BossBonusLinger(i)
    if CHAOS_LOADING == false and UnitAlive(BossTable[i].unit) then
        local numplayers = 0

        for hero in each(HeroGroup) do
            if IsUnitInRange(hero, BossTable[i].unit, NEARBY_BOSS_RANGE) then
                numplayers = numplayers + 1
            end
        end

        BossNearbyPlayers[i] = numplayers
    end
end

---@type fun(pt: PlayerTimer)
function ReturnBoss(pt)
    if UnitAlive(BossTable[pt.id].unit) and not CHAOS_LOADING then
        local angle = Atan2(GetLocationY(BossTable[pt.id].loc) - GetUnitY(BossTable[pt.id].unit), GetLocationX(BossTable[pt.id].loc) - GetUnitX(BossTable[pt.id].unit))
        if IsUnitInRangeLoc(BossTable[pt.id].unit, BossTable[pt.id].loc, 100.) then
            pt:destroy()
            SetUnitMoveSpeed(BossTable[pt.id].unit, GetUnitDefaultMoveSpeed(BossTable[pt.id].unit))
            SetUnitPathing(BossTable[pt.id].unit, true)
            UnitRemoveAbility(BossTable[pt.id].unit, FourCC('Amrf'))
            SetUnitTurnSpeed(BossTable[pt.id].unit, GetUnitDefaultTurnSpeed(BossTable[pt.id].unit))
        else
            SetUnitXBounded(BossTable[pt.id].unit, GetUnitX(BossTable[pt.id].unit) + 20. * Cos(angle))
            SetUnitYBounded(BossTable[pt.id].unit, GetUnitY(BossTable[pt.id].unit) + 20. * Sin(angle))
            IssuePointOrder(BossTable[pt.id].unit, "move", GetUnitX(BossTable[pt.id].unit) + 70. * Cos(angle), GetUnitY(BossTable[pt.id].unit) + 70. * Sin(angle))
            UnitRemoveBuffs(BossTable[pt.id].unit, false, true)
        end

        pt.timer:callDelayed(0.06, ReturnBoss, pt)
    else
        pt:destroy()
    end
end

---@type fun(pid: integer)
function DelayedSave(pid)
    if not ActionSave(Player(pid - 1)) and HeroID[pid] > 0 then
        TimerQueue:callDelayed(30., DelayedSave, pid)
    end
end

function Periodic()
    local x = 0 ---@type number 
    local y = 0 ---@type number 

    --player loop
    local u = User.first ---@type User 

    while u do
        local pid = u.id

        --camera lock
        if CameraLock[pid] and not selectingHero[pid] then
            if (GetLocalPlayer() == u.player) then
                SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, Zoom[pid], 0)
            end
        end

        if HeroID[pid] > 0 then

            --backpack move
            if IS_TELEPORTING[pid] == false then
                x = GetUnitX(Hero[pid]) + 50 * Cos((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                y = GetUnitY(Hero[pid]) + 50 * Sin((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
                if IsUnitInRange(Hero[pid], Backpack[pid], 1000.) == false then
                    SetUnitXBounded(Backpack[pid], x)
                    SetUnitYBounded(Backpack[pid], y)
                elseif bpmoving[pid] == false or IsUnitInRange(Hero[pid], Backpack[pid], 800.) == false then
                    if IsUnitInRange(Hero[pid], Backpack[pid], 50.) == false then
                        DisableTrigger(pointOrder)
                        IssuePointOrder(Backpack[pid], "move", x, y)
                        EnableTrigger(pointOrder)
                    end
                end
            end

            --spellboost
            BoostValue[pid] = ItemSpellboost[pid]

            --bard inspire
            local b = InspireBuff:get(nil, Hero[pid])

            if b then
               BoostValue[pid] = BoostValue[pid] + (0.08 + 0.02 * b.ablev)
            end

            --master of elements fire
            if masterElement[pid] == ELEMENTFIRE.value then
                BoostValue[pid] = BoostValue[pid] + 0.15
            end

            --demonic sacrifice
            if DemonicSacrificeBuff:has(Hero[pid], Hero[pid]) then
                BoostValue[pid] = BoostValue[pid] + 0.15
            end

            --dark seal spellboost
            local pt = TimerList[pid]:get(DARKSEAL.id, Hero[pid])

            if pt then
                BoostValue[pid] = BoostValue[pid] + pt.dmg * 0.01
            end

            --metamorphosis duration update
            local ablev = GetUnitAbilityLevel(Hero[pid], METAMORPHOSIS.id)
            if ablev > 0 then
                BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], METAMORPHOSIS.id), ABILITY_RLF_DURATION_HERO, ablev - 1, METAMORPHOSIS.dur(pid) * LBOOST[pid])
            end

            --steed charge meta duration update
            ablev = GetUnitAbilityLevel(Hero[pid], FourCC('A06K'))
            if ablev > 0 then
                BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], FourCC('A06K')), ABILITY_RLF_DURATION_HERO, ablev - 1, 10. * LBOOST[pid])
            end

            --damage taken
            PhysicalTaken[pid] = math.max(0, HeroStats[HeroID[pid]].phys_resist * ItemDamageRes[pid])
            MagicTaken[pid] = math.max(0, HeroStats[HeroID[pid]].magic_resist * ItemDamageRes[pid] * ItemMagicRes[pid])

            --master of elements (earth)
            if masterElement[pid] == ELEMENTEARTH.value then
                PhysicalTaken[pid] = PhysicalTaken[pid] * 0.75
                MagicTaken[pid] = MagicTaken[pid] * 0.75
            end

            --vampire str resist
            if HeroID[pid] == HERO_VAMPIRE and GetUnitAbilityLevel(Hero[pid], BLOODLORD.id) > 0 and GetHeroStr(Hero[pid], true) > GetHeroAgi(Hero[pid], true) then
                PhysicalTaken[pid] = PhysicalTaken[pid] * (1 - 0.01 * (BloodBank[pid] / (GetHeroInt(Hero[pid], true) * 10)))
                MagicTaken[pid] = MagicTaken[pid] * (1 - 0.01 * (BloodBank[pid] / (GetHeroInt(Hero[pid], true) * 10)))
            end

            --aura of justice
            b = JusticeAuraBuff:get(nil, Hero[pid])

            if b then
                PhysicalTaken[pid] = PhysicalTaken[pid] * math.max(0.91 - 0.01 * b.ablev, 0.85)
            end

            --song of peace
            b = SongOfPeaceEncoreBuff:get(nil, Hero[pid])

            if b then
                PhysicalTaken[pid] = PhysicalTaken[pid] * 0.8
                MagicTaken[pid] = MagicTaken[pid] * 0.8
            end

            --darkest of darkness
            if DarkestOfDarknessBuff:has(Hero[pid], Hero[pid]) then
                PhysicalTaken[pid] = PhysicalTaken[pid] * 0.7
                MagicTaken[pid] = MagicTaken[pid] * 0.7
            end

            --magnetic stance
            if MagneticStanceBuff:has(Hero[pid], Hero[pid]) then
                PhysicalTaken[pid] = PhysicalTaken[pid] * (0.95 - 0.05 * GetUnitAbilityLevel(Hero[pid], MAGNETICSTANCE.id))
                MagicTaken[pid] = MagicTaken[pid] * (0.95 - 0.05 * GetUnitAbilityLevel(Hero[pid], MAGNETICSTANCE.id))
            end

            --protected
            b = ProtectedBuff:get(nil, Hero[pid])

            if b then
                PhysicalTaken[pid] = PhysicalTaken[pid] * (0.93 - 0.02 * GetUnitAbilityLevel(b.source, PROTECTOR.id))
                MagicTaken[pid] = MagicTaken[pid] * (0.93 - 0.02 * GetUnitAbilityLevel(b.source, PROTECTOR.id))
            end

            --omnislash 80 percent reduction 
            if TimerList[pid]:has(OMNISLASH.id) then
                PhysicalTaken[pid] = PhysicalTaken[pid] * 0.2
                MagicTaken[pid] = MagicTaken[pid] * 0.2
            end

            --righteous might 80 percent reduction
            if RighteousMightBuff:has(nil, Hero[pid]) then
                MagicTaken[pid] = MagicTaken[pid] * 0.2
            end

            --weather
            if WeatherBuff:has(Hero[pid], Hero[pid]) then
                BoostValue[pid] = BoostValue[pid] + WeatherTable[CURRENT_WEATHER].boost * 0.01
                PhysicalTaken[pid] = PhysicalTaken[pid] * (1. - WeatherTable[CURRENT_WEATHER].dr * 0.01)
                MagicTaken[pid] = MagicTaken[pid] * (1. - WeatherTable[CURRENT_WEATHER].dr * 0.01)
            end

            --regeneration
            TotalRegen[pid] = ItemRegen[pid] + BuffRegen[pid]

            --undying rage bonus attack / regen
            if GetUnitAbilityLevel(Hero[pid], UNDYINGRAGE.id) > 0 then
                UnitAddBonus(Hero[pid], BONUS_DAMAGE, -undyingRageAttackBonus[pid])
                undyingRageAttackBonus[pid] = 0
                undyingRageAttackBonus[pid] = R2I(UNDYINGRAGE.attack(pid))
                UnitAddBonus(Hero[pid], BONUS_DAMAGE, undyingRageAttackBonus[pid])

                TotalRegen[pid] = TotalRegen[pid] + UNDYINGRAGE.regen(pid)
            end

            --chaos shield 
            local hp = IMinBJ(5, R2I((BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid])) / BlzGetUnitMaxHP(Hero[pid]) * 100 / 15))

            local itm = GetItemFromPlayer(pid, FourCC('I01J'))

            if itm then
                TotalRegen[pid] = TotalRegen[pid] + BlzGetUnitMaxHP(Hero[pid]) * (0.0001 * itm:getValue(ITEM_ABILITY, 0)) * hp
            end
            TotalRegen[pid] = TotalRegen[pid] * (1. + PercentHealBonus[pid] * 0.01)

            --prevent healing visual
            if UndyingRageBuff:has(Hero[pid], Hero[pid]) then
                UnitSetBonus(Hero[pid], BONUS_LIFE_REGEN, 0)
            else
                UnitSetBonus(Hero[pid], BONUS_LIFE_REGEN, TotalRegen[pid])
            end

            --movement speed

            --flat bonuses
            Movespeed[pid] = R2I(GetUnitDefaultMoveSpeed(Hero[pid])) + ItemMovespeed[pid]

            if GetUnitAbilityLevel(Hero[pid], FourCC('B02A')) > 0 then --barrage
                Movespeed[pid] = Movespeed[pid] + 150
            end
            if GetUnitAbilityLevel(Hero[pid], FourCC('B01I')) > 0 then --infused water
                Movespeed[pid] = Movespeed[pid] + 150
            end
            if GetUnitAbilityLevel(Hero[pid], FourCC('B02F')) > 0 then --drum of war
                Movespeed[pid] = Movespeed[pid] + 150
            end
            if GetUnitAbilityLevel(Hero[pid], FourCC('BUau')) > 0 then --blood horn
                Movespeed[pid] = Movespeed[pid] + 75
            end

            --multipliers
            if masterElement[pid] == ELEMENTLIGHTNING.value then --master of elements (lightning)
                Movespeed[pid] = R2I(Movespeed[pid] * 1.4)
            end

            --weather
            if WeatherBuff:has(Hero[pid], Hero[pid]) then
                Movespeed[pid] = R2I(Movespeed[pid] * (1. - WeatherTable[CURRENT_WEATHER].ms * 0.01))
            end

            Movespeed[pid] = Movespeed[pid] + BuffMovespeed[pid]
            SetUnitMoveSpeed(Hero[pid], IMinBJ(500, Movespeed[pid]))

            if Movespeed[pid] > 500 then
                Movespeed[pid] = 500
            end

            --arcanosphere
            pt = TimerList[pid]:get(ARCANOSPHERE.id)

            if pt then
                if IsUnitInRangeXY(Hero[pid], pt.x, pt.y, 800.) then
                    Movespeed[pid] = 1000
                    SetUnitMoveSpeed(Hero[pid], 522)
                end
            end

            --Adjust Backpack MS
            SetUnitMoveSpeed(Backpack[pid], Movespeed[pid])

            if sniperstance[pid] then
                Movespeed[pid] = 100
                SetUnitMoveSpeed(Hero[pid], 100)
            end
        end

        u = u.next
    end
end

function CreateWell()
    local heal = 50 ---@type integer 
    local x    = 0 ---@type number 
    local y    = 0 ---@type number 
    local r ---@type rect 
    local rand = GetRandomInt(1, 14) ---@type integer 

    if rand == 14 then
        rand = 15 --exclude elder dragon
    end

    if wellcount < 7 then
        r = SelectGroupedRegion(rand)

        wellcount = wellcount + 1
        repeat
            x = GetRandomReal(GetRectMinX(r), GetRectMaxX(r))
            y = GetRandomReal(GetRectMinY(r), GetRectMaxY(r))
        until IsTerrainWalkable(x, y)
        --TODO rework into sfx? use ui for tooltip?
        well[wellcount] = Dummy.create(x, y, 0, 0, 0).unit
        BlzSetUnitFacingEx(well[wellcount], 270)
        UnitRemoveAbility(well[wellcount], FourCC('Aloc'))
        ShowUnit(well[wellcount], false)
        ShowUnit(well[wellcount], true)
        if GetRandomInt(0, 2) < 2 then
            BlzSetUnitSkin(well[wellcount], FourCC('h04W'))
            BlzSetUnitName(well[wellcount], "Health Well")
        else
            BlzSetUnitSkin(well[wellcount], FourCC('h05H'))
            BlzSetUnitName(well[wellcount], "Mana Well")
            heal = heal + 100 --mana
        end
        SetUnitScale(well[wellcount], 0.5, 0.5, 0.5)
        wellheal[wellcount] = heal
    end
end

function SpawnStruggleUnits()
    local end_ = R2I(Struggle_Wave_SR[Struggle_WaveN]) ---@type integer 
    local rand = GetRandomInt(1,4) ---@type integer 
    local u ---@type unit 

    if Struggle_Pcount > 0 and Struggle_WaveU[Struggle_WaveN] > 0 then
        for i = 0, end_ do
            if Struggle_WaveUCN > 0 then
                if BlzGroupGetSize(StruggleWaveGroup) < 70 then
                    Struggle_WaveUCN = Struggle_WaveUCN - 1
                    u = CreateUnit(pboss, Struggle_WaveU[Struggle_WaveN], GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), bj_UNIT_FACING)
                    SetUnitXBounded(u, GetRandomReal(GetRectMinX(Struggle_SpawnR[rand]), GetRectMaxX(Struggle_SpawnR[rand])))
                    SetUnitYBounded(u, GetRandomReal(GetRectMinY(Struggle_SpawnR[rand]), GetRectMaxY(Struggle_SpawnR[rand])))
                    GroupAddUnit(StruggleWaveGroup, u)
                    SetUnitCreepGuard(u, false)
                    SetUnitAcquireRange(u, 3000.)
                end
            end
        end
        TimerQueue:callDelayed(3., SpawnStruggleUnits)
    end
end

function LavaBurn()
    local ug = CreateGroup()
    local ug2 = CreateGroup()

    GroupEnumUnitsInRect(ug, gg_rct_Lava1, Condition(isplayerunit))
    GroupEnumUnitsInRect(ug2, gg_rct_Lava2, Condition(isplayerunit))
    BlzGroupAddGroupFast(ug2, ug)

    for target in each(ug) do
        local dmg = BlzGetUnitMaxHP(target) / 40. + 1000.

        if GetUnitFlyHeight(u) < 75.00 then
            DamageTarget(DummyUnit, target, dmg, ATTACK_TYPE_NORMAL, PURE, "Lava")
        end
    end

    DestroyGroup(ug)
    DestroyGroup(ug2)
end

function ColosseumXPDecrease()
    local u = User.first ---@type User 
    local i ---@type integer 

    while u do
        i = GetPlayerId(u.player) + 1
        if HeroID[i] > 0 and InColo[i] and Colosseum_XP[i] > 0.05 then
            Colosseum_XP[i]= Colosseum_XP[i] - 0.005
        end
        if Colosseum_XP[i] < 0.05 then
            Colosseum_XP[i] = 0.05
        end
        ExperienceControl(i)
        u = u.next
    end
end

function WanderingGuys()
    local x ---@type number 
    local y ---@type number 
    local x2 ---@type number 
    local y2 ---@type number 
    local count = 0 ---@type integer 
    local id    = (CHAOS_MODE and BOSS_LEGION) or BOSS_DEATH_KNIGHT

    if CHAOS_LOADING then
        return
    end

    --dk / legion
    if GetUnitTypeId(BossTable[id].unit) ~= 0 and UnitAlive(BossTable[id].unit) then
        repeat
            x = GetRandomReal(MAIN_MAP.minX, MAIN_MAP.maxX)
            y = GetRandomReal(MAIN_MAP.minY, MAIN_MAP.maxY)
            x2 = GetUnitX(BossTable[id].unit)
            y2 = GetUnitY(BossTable[id].unit)
            count = count + 1

        until LineContainsRect(x2, y2, x, y, -4000, -3000, 4000, 5000) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 2500.

        IssuePointOrder(BossTable[id].unit, "patrol", x, y)
    end

    if UnitAlive(townpaladin) then
        if not TimerList[0]:has('pala') or (DistanceCoords(GetUnitX(townpaladin), GetUnitY(townpaladin), GetRectCenterX(gg_rct_Town_Boundry), GetRectCenterY(gg_rct_Town_Boundry)) > 3000.) then
            x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
            y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)

            IssuePointOrder(townpaladin, "move", x, y)
        end
    end

    if UnitAlive(gg_unit_H01Y_0099) then
        x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
        y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)

        IssuePointOrder(gg_unit_H01Y_0099, "move", x, y)
    end
end

function SaveTimerExpire()
    local u = User.first ---@type User 
    local pid ---@type integer 

    while u do
        pid = u.id
        if GetExpiredTimer() == SaveTimer[pid] then
            if autosave[pid] and not ActionSave(u.player) then
                TimerQueue:callDelayed(30., DelayedSave, pid)
            end
        end
        u = u.next
    end
end

function OneMinute()
    local u = User.first ---@type User 

    while u do
        --time played
        TimePlayed[u.id] = TimePlayed[u.id] + 1

        --colosseum xp decrease
        if HeroID[u.id] > 0 and InColo[u.id] == false and Colosseum_XP[u.id] < 1.30 then
            if Colosseum_XP[u.id] < 0.75 then
                Colosseum_XP[u.id] = Colosseum_XP[u.id] + 0.02
            else
                Colosseum_XP[u.id] = Colosseum_XP[u.id] + 0.01
            end
            if Colosseum_XP[u.id] > 1.30 then
                Colosseum_XP[u.id] = 1.30
            end
            ExperienceControl(u.id)
        end

        u = u.next
    end
end

---@type fun(): string
function GenerateAFKString()
    local alphanumeric = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""

    for _ = 1, 4 do
        local index = GetRandomInt(1, #alphanumeric)
        str = str .. alphanumeric:sub(index, index)
    end

    return str
end

function AFKClock()
    local u = User.first ---@type User 

    AFK_TEXT = GenerateAFKString()
    BlzFrameSetText(AFK_FRAME, "Type -" .. AFK_TEXT)

    while u do
        local pid = u.id

        if HeroID[pid] > 0 then
            if afkTextVisible[pid] then
                afkTextVisible[pid] = false
                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(AFK_FRAME_BG, false)
                end
                PanCameraToTimedLocForPlayer(u.player, TownCenter, 0)
                DisplayTextToForce(FORCE_PLAYING, u.nameColored .. " was removed for being AFK.")
                DisplayTextToPlayer(u.player, 0, 0, "You have lost the game. All of your structures and units will be removed from the game, however you may stay and watch or leave as you choose.")
                PlayerCleanup(pid)
            elseif panCounter[pid] < 50 or moveCounter[pid] < 5000 or clickCounter[pid] < 200 then
                afkTextVisible[pid] = true
                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(AFK_FRAME_BG, true)
                end
                SoundHandler("Sound\\Interface\\SecretFound.wav", false, Player(pid - 1), nil)
            end
        end

        moveCounter[pid] = 0
        panCounter[pid] = 0
        clickCounter[pid] = 0

        u = u.next
    end
end

function ShopkeeperMove()
    if UnitAlive(evilshopkeeper) then
        local x = 0. ---@type number 
        local y = 0. ---@type number 

        repeat
            x = GetRandomReal(MAIN_MAP.minX, MAIN_MAP.maxX)
            y = GetRandomReal(MAIN_MAP.minY, MAIN_MAP.maxY)

            if GetRandomInt(0, 99) < 5 then
                x = GetRandomReal(GetRectMinX(gg_rct_Tavern), GetRectMaxX(gg_rct_Tavern))
                y = GetRandomReal(GetRectMinY(gg_rct_Tavern), GetRectMaxY(gg_rct_Tavern))
            end

        until IsTerrainWalkable(x, y)

        evilshop:visible(false)
        ShowUnit(evilshopkeeper, false)
        ShowUnit(evilshopkeeper, true)
        SetUnitPosition(evilshopkeeper, x, y) --random starting spot
        BlzStartUnitAbilityCooldown(evilshopkeeper, FourCC('A017'), 300.)

        ShopSetStock(FourCC('n01F'), FourCC('I02B'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I02C'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I0EY'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I074'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I03U'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I07F'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I03P'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I0F9'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I079'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I0FC'), 1)
        ShopSetStock(FourCC('n01F'), FourCC('I00A'), 1)

        TimerQueue:callDelayed(300., ShopkeeperMove)
    end
end

function OneSecond()
    local ug = CreateGroup()
    local hp = 0.
    local mp = 0.

    TIME = TIME + 1

    --clock frame
    BlzFrameSetText(clockText, IntegerToTime(TIME))

    --set space bar camera to town
    SetCameraQuickPositionLoc(TownCenter)

    --fountain regeneration
    MakeGroupInRange(TOWN_ID, ug, -260., 350., 600., Condition(FilterAlly))

    for target in each(ug) do
        hp = GetWidgetLife(target)
        mp = GetUnitState(target, UNIT_STATE_MANA)

        if hp < BlzGetUnitMaxHP(target) * 0.99 then
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", target, "origin"))
            SetWidgetLife(target, hp + BlzGetUnitMaxHP(target))
        end

        if mp < BlzGetUnitMaxMana(target) * 0.99 and GetUnitTypeId(target) ~= HERO_VAMPIRE then
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl", target, "origin"))
            SetUnitState(target, UNIT_STATE_MANA, GetUnitState(target, UNIT_STATE_MANA) + BlzGetUnitMaxMana(target))
        end
    end

    --boss regeneration / player scaling / reset
    for i = BOSS_OFFSET, #BossTable do
        if CHAOS_LOADING == false and UnitAlive(BossTable[i].unit) then

            --death knight / legion exception
            if BossTable[i].id ~= FourCC('H04R') and BossTable[i].id ~= FourCC('H040') then
                if IsUnitInRangeLoc(BossTable[i].unit, BossTable[i].loc, BossTable[i].leash) == false and GetUnitAbilityLevel(BossTable[i].unit, FourCC('Amrf')) == 0 then
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.16
                    if GetUnitAbilityLevel(BossTable[i].unit, FourCC('Asan')) > 0 then
                        hp = hp * 0.5
                    end
                    UnitSetBonus(BossTable[i].unit, BONUS_LIFE_REGEN, hp)
                    UnitAddAbility(BossTable[i].unit, FourCC('Amrf'))
                    SetUnitMoveSpeed(BossTable[i].unit, 522)
                    SetUnitPathing(BossTable[i].unit, false)
                    SetUnitTurnSpeed(BossTable[i].unit, 1.)
                    local pt = TimerList[BOSS_ID]:add()
                    pt.id = i
                    pt.timer:callDelayed(0.06, ReturnBoss, pt)
                end
            end

            --determine number of nearby heroes
            local numplayers = 0
            for hero in each(HeroGroup) do
                if IsUnitInRange(hero, BossTable[i].unit, NEARBY_BOSS_RANGE) then
                    numplayers = numplayers + 1
                end
            end

            BossNearbyPlayers[i] = IMaxBJ(BossNearbyPlayers[i], numplayers)

            if numplayers < BossNearbyPlayers[i] then
                TimerQueue:callDelayed(5., BossBonusLinger, i)
            end

            --calculate hp regeneration
            if GetWidgetLife(BossTable[i].unit) > GetHeroStr(BossTable[i].unit, false) * 25 * 0.15 then -- > 15 percent
                if CHAOS_MODE then
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * (0.0001 + 0.0004 * BossNearbyPlayers[i]) --0.04 percent per player
                else
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.002 * BossNearbyPlayers[i] --0.2 percent
                end
            else
                if CHAOS_MODE then
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * (0.0002 + 0.0008 * BossNearbyPlayers[i]) --0.08 percent
                else
                    hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.004 * BossNearbyPlayers[i] --0.4 percent
                end
            end

            if numplayers == 0 then --out of combat?
                hp = GetHeroStr(BossTable[i].unit, false) * 25 * 0.02 --2 percent
            else --bonus damage and health
                if CHAOS_MODE then
                    UnitSetBonus(BossTable[i].unit, BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(BossTable[i].unit, 0) * 0.2 * (BossNearbyPlayers[i] - 1)))
                    UnitSetBonus(BossTable[i].unit, BONUS_HERO_STR, R2I(GetHeroStr(BossTable[i].unit, false) * 0.2 * (BossNearbyPlayers[i] - 1)))
                end
            end

            --sanctified ground debuff
            if SanctifiedGroundDebuff:has(nil, BossTable[i].unit) then
                hp = hp * 0.5
            end

            --non-returning hp regeneration
            if GetUnitAbilityLevel(BossTable[i].unit, FourCC('Amrf')) == 0 then
                UnitSetBonus(BossTable[i].unit, BONUS_LIFE_REGEN, hp)
            end
        end
    end

    --summon regeneration
    for _, target in ipairs(SummonGroup) do
        if UnitAlive(target) and GetUnitAbilityLevel(target, FourCC('A06Q')) > 0 then
            if GetUnitTypeId(target) == SUMMON_DESTROYER then
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            elseif GetUnitTypeId(target) == SUMMON_HOUND and GetUnitAbilityLevel(target, FourCC('A06Q')) > 9 then
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            else
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.00025 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            end
        end
    end

    --zeppelin kill
    if CHAOS_MODE then
        ZeppelinKill()
    end

    --Undespawn Units
    for i = 1, #despawnGroup do
        local creep = despawnGroup[i]

        if creep ~= nil then
            GroupEnumUnitsInRange(ug, GetUnitX(creep), GetUnitY(creep), 800., Condition(FilterDespawn))
            if BlzGroupGetSize(ug) == 0 then
                TimerQueue:callDelayed(0.9, Undespawn, creep)
                despawnGroup[i] = despawnGroup[#despawnGroup]
                despawnGroup[#despawnGroup] = nil
                i = i - 1
            end
        end
    end

    --add & remove players in dungeon queue
    if QUEUE_DUNGEON > 0 then
        local p = User.first
        local mb = MULTIBOARD.QUEUE

        while p do
            if IsUnitInRangeXY(Hero[p.id], QUEUE_X, QUEUE_Y, 750.) and UnitAlive(Hero[p.id]) and IS_TELEPORTING[p.id] == false then
                if TableHas(QUEUE_GROUP, p.player) == false and GetHeroLevel(Hero[p.id]) >= QUEUE_LEVEL then
                    QUEUE_GROUP[#QUEUE_GROUP + 1] = p.player
                    mb:addRows(1)
                    mb:get(mb.rowCount, 1).text = {0.02, 0, 0.09, 0.011}
                    mb:get(mb.rowCount, 2).icon = {0.26, 0, 0.011, 0.011}
                    mb.available[p.id] = true
                    mb:display(p.id)
                end
            elseif TableHas(QUEUE_GROUP, p.player) then
                TableRemove(QUEUE_GROUP, p.player)
                QUEUE_READY[p.id] = false
                mb:delRows(1)
                mb.available[p.id] = false
                MULTIBOARD.MAIN:display(p.id)

                if #QUEUE_GROUP <= 0 then
                    QUEUE_DUNGEON = 0
                end
            end

            p = p.next
        end

        --Refresh dungeon queue multiboard
        if #QUEUE_GROUP == 0 then
            QUEUE_DUNGEON = 0
        end
    end

    --refresh multiboard bodies
    RefreshMB()

    --player loop
    local p = User.first

    while p do
        --update boost variance every second
        BOOST[p.id] = 1. + BoostValue[p.id] + GetRandomReal(-0.2, 0.2)
        LBOOST[p.id] = 1. + 0.5 * BoostValue[p.id]

        if DEV_ENABLED then
            if BOOST_OFF then
                BOOST[p.id] = (1. + BoostValue[p.id])
            end
        end

        --Cooldowns

        if HeroID[p.id] > 0 then
            UpdateManaCosts(p.id)

            --intense focus
            if (HasProficiency(p.id, PROF_BOW) and
                GetUnitAbilityLevel(Hero[p.id], FourCC('A0B9')) > 0 and
                UnitAlive(Hero[p.id]) and
                LAST_HERO_X[p.id] == GetUnitX(Hero[p.id]) and
                LAST_HERO_Y[p.id] == GetUnitY(Hero[p.id]))
            then
                IntenseFocus[p.id] = IMinBJ(10, IntenseFocus[p.id] + 1)
            else
                IntenseFocus[p.id] = 0
            end

            --keep track of hero positions
            LAST_HERO_X[p.id] = GetUnitX(Hero[p.id])
            LAST_HERO_Y[p.id] = GetUnitY(Hero[p.id])

            --PVP leave range
            if ArenaQueue[p.id] > 0 and IsUnitInRangeXY(Hero[p.id], -1311., 2905., 1000.) == false then
                ArenaQueue[p.id] = 0
                DisplayTimedTextToPlayer(p.player, 0, 0, 5.0, "You have been removed from the PvP queue.")
            end

            hp = GetWidgetLife(Hero[p.id]) / BlzGetUnitMaxHP(Hero[p.id]) * 100

            --backpack hp/mp percentage
            if hp >= 1 then
                hp = GetWidgetLife(Hero[p.id]) / BlzGetUnitMaxHP(Hero[p.id])
                SetUnitState(Backpack[p.id], UNIT_STATE_LIFE, BlzGetUnitMaxHP(Backpack[p.id]) * hp)
                mp = GetUnitState(Hero[p.id], UNIT_STATE_MANA) / GetUnitState(Hero[p.id], UNIT_STATE_MAX_MANA)
                SetUnitState(Backpack[p.id], UNIT_STATE_MANA, GetUnitState(Backpack[p.id], UNIT_STATE_MAX_MANA) * mp)
            end

            --blood bank
            if HeroID[p.id] == HERO_VAMPIRE then
                BloodBank[p.id] = math.min(BLOODBANK.curr(p.id), BLOODBANK.max(p.id))
                BlzSetUnitMaxMana(Hero[p.id], R2I(BLOODBANK.max(p.id)))
                SetUnitState(Hero[p.id], UNIT_STATE_MANA, BLOODBANK.curr(p.id))
                BlzSetUnitRealField(Hero[p.id], UNIT_RF_MANA_REGENERATION, - GetHeroInt(Hero[p.id], true) * 0.05)

                hp = (BloodBank[p.id] / BLOODBANK.max(p.id)) * 5
                if GetLocalPlayer() == Player(p.id - 1) then
                    BlzSetAbilityIcon(BLOODBANK.id, "ReplaceableTextures\\CommandButtons\\BTNSimpleHugePotion" .. (R2I(hp)) .. "_5.blp")
                end

                --vampire cooldowns
                if GetUnitAbilityLevel(Hero[p.id], BLOODLORD.id) > 0 and GetHeroAgi(Hero[p.id], true) > GetHeroStr(Hero[p.id], true) then
                    BlzSetUnitAbilityCooldown(Hero[p.id], BLOODLEECH.id, GetUnitAbilityLevel(Hero[p.id], BLOODLEECH.id) - 1, 3.)
                    BlzSetUnitAbilityCooldown(Hero[p.id], BLOODNOVA.id, GetUnitAbilityLevel(Hero[p.id], BLOODNOVA.id) - 1, 2.5)
                    BlzSetUnitAbilityCooldown(Hero[p.id], BLOODDOMAIN.id, GetUnitAbilityLevel(Hero[p.id], BLOODDOMAIN.id) - 1, 5.)
                else
                    BlzSetUnitAbilityCooldown(Hero[p.id], BLOODLEECH.id, GetUnitAbilityLevel(Hero[p.id], BLOODLEECH.id) - 1, 6.)
                    BlzSetUnitAbilityCooldown(Hero[p.id], BLOODNOVA.id, GetUnitAbilityLevel(Hero[p.id], BLOODNOVA.id) - 1, 5.)
                    BlzSetUnitAbilityCooldown(Hero[p.id], BLOODDOMAIN.id, GetUnitAbilityLevel(Hero[p.id], BLOODDOMAIN.id) - 1, 10.)
                end

                --vampire blood mist
                local b = BloodMistBuff:get(Hero[p.id], Hero[p.id])
                if b then
                    if BloodBank[p.id] >= BLOODMIST.cost(p.id) then
                        BloodBank[p.id] = BloodBank[p.id] - BLOODMIST.cost(p.id)
                        SetUnitState(Hero[p.id], UNIT_STATE_MANA, BloodBank[p.id])

                        HP(Hero[p.id], Hero[p.id], BLOODMIST.heal(p.id) * BOOST[p.id], BLOODMIST.tag)
                        if GetUnitAbilityLevel(Hero[p.id], FourCC('B02Q')) == 0 then
                            PlayerAddItemById(p.id, FourCC('I0OE'))
                        end
                        BlzSetSpecialEffectAlpha(b.sfx, 255)
                    else
                        UnitRemoveAbility(Hero[p.id], FourCC('B02Q'))
                        BlzSetSpecialEffectAlpha(b.sfx, 0)
                    end
                end
            end

            --tooltips
            UpdateSpellTooltips(p.id)

            --TODO for now use 900 as default aura range
            MakeGroupInRange(p.id, ug, GetUnitX(Hero[p.id]), GetUnitY(Hero[p.id]), 900. * LBOOST[p.id], Condition(isalive))

            for target in each(ug) do
                if IsUnitAlly(target, Player(p.id - 1)) then
                    if InspireBuff:has(Hero[p.id], Hero[p.id]) then
                        local b = InspireBuff:get(nil, target)

                        --choose strongest one
                        if b then
                            b.ablev = IMaxBJ(b.ablev, GetUnitAbilityLevel(Hero[p.id], INSPIRE.id))
                        else
                            InspireBuff:add(Hero[p.id], target):duration(1.)
                        end
                    end
                    if BardSong[p.id] == SONG_WAR then
                        local b = SongOfWarBuff:get(nil, target)

                        --allow for damage bonus refresh
                        if b then
                            b:remove()
                        end

                        SongOfWarBuff:add(Hero[p.id], target):duration(2.)
                    end
                    if GetUnitAbilityLevel(Hero[p.id], PROTECTOR.id) > 0 then
                        ProtectedBuff:add(Hero[p.id], target):duration(2.)
                    end
                    if FightMeCasterBuff:has(Hero[p.id], Hero[p.id]) and target ~= Hero[p.id] then
                        FightMeBuff:add(Hero[p.id], target):duration(2.)
                    end
                    if GetUnitAbilityLevel(Hero[p.id], AURAOFJUSTICE.id) > 0 then
                        JusticeAuraBuff:add(Hero[p.id], target):duration(2.)
                        local b = JusticeAuraBuff:get(nil, target)
                        b.ablev = IMaxBJ(b.ablev, GetUnitAbilityLevel(Hero[p.id], AURAOFJUSTICE.id))
                    end
                elseif IsUnitAlly(target, Player(p.id - 1)) == false and UnitIsSleeping(target) == false then
                    if BardSong[p.id] == SONG_FATIGUE then
                        SongOfFatigueSlow:add(Hero[p.id], target):duration(2.)
                    elseif masterElement[p.id] == ELEMENTICE.value then
                        IceElementSlow:add(Hero[p.id], target):duration(2.)
                    end
                end
            end
        end

        p = p.next
    end

    DestroyGroup(ug)
end

function CustomMovement()
    local angle = 0. ---@type number 
    local dist = 0. ---@type number 
    local x = 0. ---@type number 
    local y = 0. ---@type number 
    local p = User.first ---@type User 

    while p do
        local order = GetUnitCurrentOrder(Hero[p.id])

        if Moving[p.id] and not IsUnitStunned(Hero[p.id]) and GetUnitAbilityLevel(Hero[p.id], FourCC('BEer')) == 0 then
            --stop, holdposition, or null
            if order == 851972 or order == 851993 or order == 0 then
                Moving[p.id] = false
            else
                --attack or smart
                if (order == 851983 or order == 851971) and
                    UnitAlive(LAST_TARGET[p.id]) and
                    UnitDistance(Hero[p.id], LAST_TARGET[p.id]) <= BlzGetUnitWeaponRealField(Hero[p.id], UNIT_WEAPON_RF_ATTACK_RANGE, 0)
                then
                    Moving[p.id] = false
                else
                    dist = DistanceCoords(GetUnitX(Hero[p.id]), GetUnitY(Hero[p.id]), clickedPoint[p.id][1], clickedPoint[p.id][2])
                    if dist < 55. then
                        Moving[p.id] = false
                    elseif Movespeed[p.id] - 522 > 0 then
                        angle = Atan2(clickedPoint[p.id][2] - GetUnitY(Hero[p.id]), clickedPoint[p.id][1] - GetUnitX(Hero[p.id]))
                        if RAbsBJ(angle * bj_RADTODEG - GetUnitFacing(Hero[p.id])) < 30. or RAbsBJ(angle * bj_RADTODEG - GetUnitFacing(Hero[p.id])) > 330. then
                            x = GetUnitX(Hero[p.id]) + (((Movespeed[p.id] - 522) * 0.01) + 1) * Cos(bj_DEGTORAD * GetUnitFacing(Hero[p.id]))
                            y = GetUnitY(Hero[p.id]) + (((Movespeed[p.id] - 522) * 0.01) + 1) * Sin(bj_DEGTORAD * GetUnitFacing(Hero[p.id]))
                            if dist > (Movespeed[p.id] - 522) * 0.01 and IsTerrainWalkable(x, y) then
                                SetUnitXBounded(Hero[p.id], x)
                                SetUnitYBounded(Hero[p.id], y)
                            end
                        end
                    end
                end
            end
        end

        p = p.next
    end
end

function Tick()
    local u = GetMainSelectedUnitEx() ---@type unit 

    --rarity item borders
    for i = 0, 5 do
        local itm = Item[UnitItemInSlot(u, i)]

        if itm then
            BlzFrameSetTexture(INVENTORYBACKDROP[i], SPRITE_RARITY[itm.level], 0, true)
            BlzFrameSetVisible(INVENTORYBACKDROP[i], true)
        else
            BlzFrameSetVisible(INVENTORYBACKDROP[i], false)
        end
    end

    if u == PUNCHING_BAG then
        BlzFrameSetVisible(PUNCHING_BAG_UI, true)
    else
        BlzFrameSetVisible(PUNCHING_BAG_UI, false)
    end

    --hide health ui
    BlzFrameSetVisible(hideHealth, UndyingRageBuff:has(u, u))
end

    local savetimer = CreateTrigger()
    local wandering = CreateTrigger()
    local u         = User.first ---@type User 

    TimerQueue:callPeriodically(FPS_64, nil, Tick)
    TimerQueue:callPeriodically(FPS_64, nil, CustomMovement)
    TimerQueue:callPeriodically(0.35, nil, Periodic)
    TimerQueue:callPeriodically(1.0, nil, OneSecond)
    TimerQueue:callPeriodically(1.5, nil, LavaBurn)
    TimerQueue:callPeriodically(15., nil, WanderingGuys)
    TimerQueue:callPeriodically(15., nil, ColosseumXPDecrease)

    TimerQueue:callPeriodically(60., nil, OneMinute)

    TimerQueue:callPeriodically(240., nil, DisplayHint)

    TimerQueue:callDelayed(0., ShopkeeperMove)
    TimerQueue:callPeriodically(300., nil, CreateWell)

    TimerQueue:callPeriodically(1800., nil, AFKClock)

    TriggerRegisterTimerExpireEvent(wandering, wanderingTimer)
    TimerStart(wanderingTimer, 2040. - (User.AmountPlaying * 240), true, ShadowStepExpire)

    while u do
        SaveTimer[u.id] = CreateTimer()
        TriggerRegisterTimerExpireEvent(savetimer, SaveTimer[u.id])
        u = u.next
    end

    TriggerAddAction(savetimer, SaveTimerExpire)
end)

if Debug then Debug.endFile() end
