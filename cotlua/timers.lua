if Debug then Debug.beginFile 'Timers' end

OnInit.final("Timers", function(require)
    require 'Units'
    require 'BossAI'
    require 'MapSetup'
    require 'Buffs'
    require 'BuffSystem'

    MISSILE_EXPIRE_AOE=__jarray(false) ---@type boolean[] 
    SaveTimer={} ---@type timer[] 
    LAST_HERO_X=__jarray(0) ---@type number[] 
    LAST_HERO_Y=__jarray(0) ---@type number[] 
    HeroGroup       = CreateGroup()
    wanderingTimer       = CreateTimer() ---@type timer 

function DisplayHint()
    local rand = GetRandomInt(2, NUM_HINTS) ---@type integer 

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
    if LAST_HINT > NUM_HINTS then
        LAST_HINT = 1
    end
end

---@type fun(i: integer)
function BossBonusLinger(i)
    local index         = 0 ---@type integer 
    local count         = BlzGroupGetSize(HeroGroup) ---@type integer 
    local numplayers         = 0 ---@type integer 

    if CWLoading == false and UnitAlive(Boss[i]) then
        repeat
            if IsUnitInRange(BlzGroupUnitAt(HeroGroup, index), Boss[i], NEARBY_BOSS_RANGE) then
                numplayers = numplayers + 1
            end
            index = index + 1
        until index >= count

        BossNearbyPlayers[i] = numplayers
    end
end

---@type fun(pt: PlayerTimer)
function ReturnBoss(pt)
    if UnitAlive(Boss[pt.i]) and not CWLoading then
        local angle = Atan2(GetLocationY(BossLoc[pt.i]) - GetUnitY(Boss[pt.i]), GetLocationX(BossLoc[pt.i]) - GetUnitX(Boss[pt.i]))
        if IsUnitInRangeLoc(Boss[pt.i], BossLoc[pt.i], 100.) then
            pt:destroy()
            SetUnitMoveSpeed(Boss[pt.i], GetUnitDefaultMoveSpeed(Boss[pt.i]))
            SetUnitPathing(Boss[pt.i], true)
            UnitRemoveAbility(Boss[pt.i], FourCC('Amrf'))
            SetUnitTurnSpeed(Boss[pt.i], GetUnitDefaultTurnSpeed(Boss[pt.i]))
        else
            SetUnitXBounded(Boss[pt.i], GetUnitX(Boss[pt.i]) + 20. * Cos(angle))
            SetUnitYBounded(Boss[pt.i], GetUnitY(Boss[pt.i]) + 20. * Sin(angle))
            IssuePointOrder(Boss[pt.i], "move", GetUnitX(Boss[pt.i]) + 70. * Cos(angle), GetUnitY(Boss[pt.i]) + 70. * Sin(angle))
            UnitRemoveBuffs(Boss[pt.i], false, true)
        end
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
    local pid         = 0 ---@type integer 
    local x      = 0 ---@type number 
    local y      = 0 ---@type number 
    local u      = User.first ---@type User 
    local pt ---@class PlayerTimer 
    local ablev         = 0 ---@type integer 
    local itm ---@type Item 
    local b ---@type Buff 

    --player loop

    while u do
        pid = GetPlayerId(u.player) + 1

        if HeroID[pid] > 0 then

            --backpack move
            if isteleporting[pid] == false then
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
            b = InspireBuff:get(nil, Hero[pid])

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
            pt = TimerList[pid]:get(DARKSEAL.id, Hero[pid])

            if pt then
                BoostValue[pid] = BoostValue[pid] + pt.dmg * 0.01
            end

            --metamorphosis duration update
            ablev = GetUnitAbilityLevel(Hero[pid], METAMORPHOSIS.id)
            if ablev > 0 then
                BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], METAMORPHOSIS.id), ABILITY_RLF_DURATION_HERO, ablev - 1, METAMORPHOSIS.dur(pid) * LBOOST[pid])
            end

            --steed charge meta duration update
            ablev = GetUnitAbilityLevel(Hero[pid], FourCC('A06K'))
            if ablev > 0 then
                BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], FourCC('A06K')), ABILITY_RLF_DURATION_HERO, ablev - 1, 10. * LBOOST[pid])
            end

            --damage taken
            PhysicalTaken[pid] = math.max(0, PhysicalTakenBase[pid] * ItemDamageRes[pid])
            MagicTaken[pid] = math.max(0, MagicTakenBase[pid] * ItemDamageRes[pid] * ItemMagicRes[pid])

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
            if GetUnitAbilityLevel(Hero[pid], FourCC('B056')) > 0 then
                PhysicalTaken[pid] = PhysicalTaken[pid] * 0.7
                MagicTaken[pid] = MagicTaken[pid] * 0.7
            end

            --magnetic stance
            if GetUnitAbilityLevel(Hero[pid], FourCC('Bmag')) > 0 then
                PhysicalTaken[pid] = PhysicalTaken[pid] * (0.95 - 0.05 * GetUnitAbilityLevel(Hero[pid], MAGNETICSTANCE.id))
                MagicTaken[pid] = MagicTaken[pid] * (0.95 - 0.05 * GetUnitAbilityLevel(Hero[pid], MAGNETICSTANCE.id))
            end

            --protected
            if GetUnitAbilityLevel(Hero[pid], FourCC('A09I')) > 0 then
                PhysicalTaken[pid] = PhysicalTaken[pid] * (0.93 - 0.02 * GetUnitAbilityLevel(ProtectedBuff:get(nil, Hero[pid]).source, PROTECTOR.id))
                MagicTaken[pid] = MagicTaken[pid] * (0.93 - 0.02 * GetUnitAbilityLevel(ProtectedBuff:get(nil, Hero[pid]).source, PROTECTOR.id))
            end

            --omnislash 80% reduction 
            if TimerList[pid]:has(OMNISLASH.id) then
                PhysicalTaken[pid] = PhysicalTaken[pid] * 0.2
                MagicTaken[pid] = MagicTaken[pid] * 0.2
            end

            --righteous might 80% reduction
            if RighteousMightBuff:has(nil, Hero[pid]) then
                MagicTaken[pid] = MagicTaken[pid] * 0.2
            end

            --weather
            if WeatherBuff:has(Hero[pid], Hero[pid]) then
                BoostValue[pid] = BoostValue[pid] + WeatherTable[CURRENT_WEATHER][WEATHER_BOOST] * 0.01
                PhysicalTaken[pid] = PhysicalTaken[pid] * (1. - WeatherTable[CURRENT_WEATHER][WEATHER_DR] * 0.01)
                MagicTaken[pid] = MagicTaken[pid] * (1. - WeatherTable[CURRENT_WEATHER][WEATHER_DR] * 0.01)
            end

            --evasion
            TotalEvasion[pid] = 0

            --assassin smokebomb
            b = SmokebombBuff:get(nil, Hero[pid])

            if b then
                if b.source == Hero[pid] then
                    TotalEvasion[pid] = TotalEvasion[pid] + (9 + GetUnitAbilityLevel(Hero[pid], SMOKEBOMB.id)) * 2
                else
                    TotalEvasion[pid] = TotalEvasion[pid] + 9 + GetUnitAbilityLevel(b.source, SMOKEBOMB.id)
                end
            end

            TotalEvasion[pid] = TotalEvasion[pid] + ItemEvasion[pid]

            if TotalEvasion[pid] > 100 or PhantomSlashing[pid] then
                TotalEvasion[pid] = 100
            end

            --regeneration
            TotalRegen[pid] = ItemRegen[pid] + BuffRegen[pid]

            --undying rage bonus attack / regen
            if GetUnitAbilityLevel(Hero[pid], UNDYINGRAGE.id) > 0 then
                UnitAddBonus(Hero[pid], BONUS_DAMAGE, -undyingRageAttackBonus[pid])
                undyingRageAttackBonus[pid] = R2I(UNDYINGRAGE.attack(pid))
                UnitAddBonus(Hero[pid], BONUS_DAMAGE, undyingRageAttackBonus[pid])

                TotalRegen[pid] = TotalRegen[pid] + UNDYINGRAGE.regen(pid)
            end

            --chaos shield 
            x = IMinBJ(5, R2I((BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid])) / BlzGetUnitMaxHP(Hero[pid]) * 100 / 15))

            itm = GetItemFromPlayer(pid, FourCC('I01J'))

            if itm then
                TotalRegen[pid] = TotalRegen[pid] + BlzGetUnitMaxHP(Hero[pid]) * (0.0001 * itm:calcStat(ITEM_ABILITY, 0)) * x
            end
            TotalRegen[pid] = TotalRegen[pid] * (1. + PercentHealBonus[pid] * 0.01)

            --prevent healing visual
            if UndyingRageBuff:has(Hero[pid], Hero[pid]) then
                UnitSetBonus(Hero[pid], BONUS_LIFE_REGEN, 0)
            else
                UnitSetBonus(Hero[pid], BONUS_LIFE_REGEN, TotalRegen[pid])
            end

            --movement speed
            pt = TimerList[pid]:get(ARCANOSPHERE.id)

            if pt and IsUnitInRangeXY(Hero[pid], pt.x, pt.y, 800.) then
                Movespeed[pid] = 1000
                SetUnitMoveSpeed(Hero[pid], 522)
            else
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
                    Movespeed[pid] = R2I(Movespeed[pid] * (1. - WeatherTable[CURRENT_WEATHER][WEATHER_MS_SLOW] * 0.01))
                end

                Movespeed[pid] = Movespeed[pid] + BuffMovespeed[pid]
                SetUnitMoveSpeed(Hero[pid], IMinBJ(500, Movespeed[pid]))

                if Movespeed[pid] > 500 then
                    Movespeed[pid] = 500
                end

                --Adjust Backpack MS
                SetUnitMoveSpeed(Backpack[pid], Movespeed[pid])

                if sniperstance[pid] then
                    Movespeed[pid] = 100
                    SetUnitMoveSpeed(Hero[pid], 100)
                end
            end
        end

        u = u.next
    end
end

function CreateWell()
    local heal         = 50 ---@type integer 
    local x      = 0 ---@type number 
    local y      = 0 ---@type number 
    local r ---@type rect 
    local rand         = GetRandomInt(1, 14) ---@type integer 

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
        well[wellcount] = GetDummy(x, y, 0, 0, 0)
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
    local end_         = R2I(Struggle_Wave_SR[Struggle_WaveN]) ---@type integer 
    local rand         = GetRandomInt(1,4) ---@type integer 
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

    local target = FirstOfGroup(ug)
    while target do
        GroupRemoveUnit(ug, target)
        local dmg = BlzGetUnitMaxHP(target) / 40. + 1000.

        if GetUnitFlyHeight(u) < 75.00 then
            UnitDamageTarget(WeatherUnit, target, dmg, true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
        end
        target = FirstOfGroup(ug)
    end

    DestroyGroup(ug)
    DestroyGroup(ug2)
end

function ColosseumXPDecrease()
    local u      = User.first ---@type User 
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
    local count         = 0 ---@type integer 
    local id         = BOSS_DEATH_KNIGHT ---@type integer 

    if ChaosMode then
        id = BOSS_LEGION
    end

    --dk / legion
    if GetUnitTypeId(Boss[id]) ~= 0 and UnitAlive(Boss[id]) then
        repeat
            x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
            y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))
            x2 = GetUnitX(Boss[id])
            y2 = GetUnitY(Boss[id])
            count = count + 1

        until LineContainsRect(x2, y2, x, y, -4000, -3000, 4000, 5000) == false and IsTerrainWalkable(x, y) and DistanceCoords(x, y, x2, y2) > 2000.

        --call DEBUGMSG("Iterations: " .. count)
        IssuePointOrder(Boss[id], "patrol", x, y)
    end

    if UnitAlive(gg_unit_H01T_0259) and not TimerList[0]:has('pala') then
        x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
        y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)

        IssuePointOrder(gg_unit_H01T_0259, "move", x, y)
    end

    if UnitAlive(gg_unit_H01Y_0099) then
        x = GetRandomReal(GetRectMinX(gg_rct_Town_Boundry) + 500, GetRectMaxX(gg_rct_Town_Boundry) - 500)
        y = GetRandomReal(GetRectMinY(gg_rct_Town_Boundry) + 500, GetRectMaxY(gg_rct_Town_Boundry) - 500)

        IssuePointOrder(gg_unit_H01Y_0099, "move", x, y)
    end
end

function SaveTimerExpire()
    local u      = User.first ---@type User 
    local pid ---@type integer 

    while u do
        pid = GetPlayerId(u.player) + 1
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

function AFKClock()
    local pid ---@type integer 
    local u      = User.first ---@type User 

    afkInt = GetRandomInt(1000, 9999)
    BlzFrameSetText(afkText, "TYPE -" .. afkInt)

    while u do
        pid = GetPlayerId(u.player) + 1

        if HeroID[pid] > 0 then
            if afkTextVisible[pid] then
                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(afkTextBG, false)
                end
                PanCameraToTimedLocForPlayer(u.player, TownCenter, 0)
                DisplayTextToForce(FORCE_PLAYING, u.nameColored .. " was removed for being AFK.")
                DisplayTextToPlayer(u.player,0,0, "You have lost the game. All of your structures and units will be removed from the game, however you may stay and watch or leave as you choose.")
                PlayerCleanup(u.player)
                --call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_FOOD_USED, 0)
            elseif panCounter[pid] < 75 or moveCounter[pid] < 1000 or selectCounter[pid] < 20 then
                afkTextVisible[pid] = true
                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(afkTextBG, true)
                end
                SoundHandler("Sound\\Interface\\SecretFound.wav", false, Player(pid - 1), nil)
            end
        end

        moveCounter[pid] = 0
        panCounter[pid] = 0
        selectCounter[pid] = 0

        u = u.next
    end
end

function ShopkeeperMove()
    if UnitAlive(gg_unit_n01F_0576) then
        local x      = 0. ---@type number 
        local y      = 0. ---@type number 

        repeat
            x = GetRandomReal(GetRectMinX(gg_rct_Main_Map), GetRectMaxX(gg_rct_Main_Map))
            y = GetRandomReal(GetRectMinY(gg_rct_Main_Map), GetRectMaxY(gg_rct_Main_Map))

            if GetRandomInt(0, 99) < 5 then
                x = GetRandomReal(GetRectMinX(gg_rct_Tavern), GetRectMaxX(gg_rct_Tavern))
                y = GetRandomReal(GetRectMinY(gg_rct_Tavern), GetRectMaxY(gg_rct_Tavern))
            end

        until IsTerrainWalkable(x, y)

        evilshop:visible(false)
        ShowUnit(gg_unit_n01F_0576, false)
        ShowUnit(gg_unit_n01F_0576, true)
        SetUnitPosition(gg_unit_n01F_0576, x, y) --random starting spot
        BlzStartUnitAbilityCooldown(gg_unit_n01F_0576, FourCC('A017'), 300.)

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
    local pid         = 0 ---@type integer 
    local hp      = 0. ---@type number 
    local mp      = 0. ---@type number 
    local i         = 0 ---@type integer 
    local boardpos         = 0 ---@type integer 
    local g       = CreateGroup()
    local ug       = CreateGroup()
    local index         = 0 ---@type integer 
    local count         = 0 ---@type integer 
    local numplayers         = 0 ---@type integer 
    local p      = User.first ---@class User 
    local b ---@type Buff 
    local mbitem                = nil ---@type multiboarditem 

    TIME = TIME + 1

    --fountain regeneration
    MakeGroupInRange(TOWN_ID, ug, -260., 350., 600., Condition(FilterAlly))

    local target = FirstOfGroup(ug)
    while target do
        GroupRemoveUnit(ug, target)

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
        target = FirstOfGroup(ug)
    end

    --boss regeneration / player scaling / reset
    while i <= BOSS_TOTAL do
        index = 0
        count = BlzGroupGetSize(HeroGroup)
        numplayers = 0

        if CWLoading == false and UnitAlive(Boss[i]) then
            --death knight / legion exception
            if BossID[i] ~= FourCC('H04R') and BossID[i] ~= FourCC('H040') then
                if IsUnitInRangeLoc(Boss[i], BossLoc[i], BossLeash[i]) == false and GetUnitAbilityLevel(Boss[i], FourCC('Amrf')) == 0 then
                    hp = GetHeroStr(Boss[i], false) * 25 * 0.16
                    if GetUnitAbilityLevel(Boss[i], FourCC('Asan')) > 0 then
                        hp = hp * 0.5
                    end
                    UnitSetBonus(Boss[i], BONUS_LIFE_REGEN, hp)
                    UnitAddAbility(Boss[i], FourCC('Amrf'))
                    SetUnitMoveSpeed(Boss[i], 522)
                    SetUnitPathing(Boss[i], false)
                    SetUnitTurnSpeed(Boss[i], 1.)
                    pt = TimerList[BOSS_ID]:add()
                    pt.id = i
                    TimerQueue:callPeriodically(0.06, ReturnBoss, pt)
                end
            end

            --determine number of nearby heroes
            if count > 0 then
                repeat
                    if IsUnitInRange(BlzGroupUnitAt(HeroGroup, index), Boss[i], NEARBY_BOSS_RANGE) then
                        numplayers = numplayers + 1
                    end
                    index = index + 1
                until index >= count
            end

            BossNearbyPlayers[i] = IMaxBJ(BossNearbyPlayers[i], numplayers)

            if numplayers < BossNearbyPlayers[i] then
                TimerQueue:callDelayed(5., BossBonusLinger, i)
            end

            --calculate hp regeneration
            if GetWidgetLife(Boss[i]) > GetHeroStr(Boss[i], false) * 25 * 0.15 then -- > 15%
                if ChaosMode then
                    hp = GetHeroStr(Boss[i], false) * 25 * (0.0001 + 0.0004 * BossNearbyPlayers[i]) --0.04% per player
                else
                    hp = GetHeroStr(Boss[i], false) * 25 * 0.002 * BossNearbyPlayers[i] --0.2%
                end
            else
                if ChaosMode then
                    hp = GetHeroStr(Boss[i], false) * 25 * (0.0002 + 0.0008 * BossNearbyPlayers[i]) --0.08%
                else
                    hp = GetHeroStr(Boss[i], false) * 25 * 0.004 * BossNearbyPlayers[i] --0.4%
                end
            end

            if numplayers == 0 then --out of combat?
                hp = GetHeroStr(Boss[i], false) * 25 * 0.02 --2%
            else --bonus damage and health
                if ChaosMode then
                    UnitSetBonus(Boss[i], BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(Boss[i], 0) * 0.2 * (BossNearbyPlayers[i] - 1)))
                    UnitSetBonus(Boss[i], BONUS_HERO_STR, R2I(GetHeroStr(Boss[i], false) * 0.2 * (BossNearbyPlayers[i] - 1)))
                end
            end

            --sanctified ground debuff
            if SanctifiedGroundDebuff:has(nil, Boss[i]) then
                hp = hp * 0.5
            end

            --non-returning hp regeneration
            if GetUnitAbilityLevel(Boss[i], FourCC('Amrf')) == 0 then
                UnitSetBonus(Boss[i], BONUS_LIFE_REGEN, hp)
            end
        end

        i = i + 1
    end

    --summon regeneration
    BlzGroupAddGroupFast(SummonGroup, ug)

    target = FirstOfGroup(ug)
    while target do
        GroupRemoveUnit(ug, target)
        if UnitAlive(target) and GetUnitAbilityLevel(target, FourCC('A06Q')) > 0 then
            if GetUnitTypeId(target) == SUMMON_DESTROYER then
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            elseif GetUnitTypeId(target) == SUMMON_HOUND and GetUnitAbilityLevel(target, FourCC('A06Q')) > 9 then
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.0005 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            else
                UnitSetBonus(target, BONUS_LIFE_REGEN, BlzGetUnitMaxHP(target) * (0.02 + 0.00025 * GetUnitAbilityLevel(target, FourCC('A06Q'))))
            end
        end
        target = FirstOfGroup(ug)
    end

    --zeppelin kill
    if ChaosMode then
        ZeppelinKill()
    end

    --Undespawn Units
    BlzGroupAddGroupFast(despawnGroup, ug)

    target = FirstOfGroup(ug)
    while target do
        GroupRemoveUnit(ug, target)
        GroupEnumUnitsInRange(g, GetUnitX(target), GetUnitY(target), 800., Condition(Trig_Enemy_Of_Hostile))
        if BlzGroupGetSize(g) == 0 then
            GroupRemoveUnit(despawnGroup, target)
            TimerQueue:callDelayed(1., Undespawn, target, UnitData[target]["ghost"])
        end
        target = FirstOfGroup(ug)
    end

    --add & remove players in dungeon queue
    if QUEUE_DUNGEON > 0 then
        while p do

            if IsUnitInRangeXY(Hero[p.id], QUEUE_X, QUEUE_Y, 750.) and UnitAlive(Hero[p.id]) and isteleporting[p.id] == false then
                if IsPlayerInForce(p.player, QUEUE_GROUP) == false and GetHeroLevel(Hero[p.id]) >= QUEUE_LEVEL then
                    ForceAddPlayer(QUEUE_GROUP, p.player)
                end
            elseif IsPlayerInForce(p.player, QUEUE_GROUP) then
                ForceRemovePlayer(QUEUE_GROUP, p.player)
                QUEUE_READY[p.id] = false
                if GetLocalPlayer() == p.player then
                    MultiboardDisplay(QUEUE_BOARD, false)
                    MultiboardDisplay(MULTI_BOARD, true)
                end

                if CountPlayersInForceBJ(QUEUE_GROUP) <= 0 then
                    QUEUE_DUNGEON = 0
                end
            end

            p = p.next
        end
    end

    --clock frame
    BlzFrameSetText(clockText, IntegerToTime(TIME))

    --refresh multiboard
    pid = 1

    while pid <= PLAYER_CAP do

        if MB_SPOT[pid] > 0 then
            if HeroID[pid] > 0 then
                hp = GetUnitState(Hero[pid], UNIT_STATE_LIFE) / BlzGetUnitMaxHP(Hero[pid])

                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 0)
                if isdonator[pid] then
                    MultiboardSetItemValue(mbitem, User[pid - 1].nameColored .. "|r|cffffcc00*|r")
                else
                    MultiboardSetItemValue(mbitem, User[pid - 1].nameColored)
                end
                MultiboardReleaseItem(mbitem)

                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 3)
                MultiboardSetItemValue(mbitem, GetUnitName(Hero[pid]))
                MultiboardReleaseItem(mbitem)

                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 4)
                MultiboardSetItemValue(mbitem, (GetHeroLevel(Hero[pid])))
                MultiboardSetItemValueColor(mbitem, 158, 196, 250, 255)
                MultiboardReleaseItem(mbitem)

                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 5)
                MultiboardSetItemValue(mbitem, (R2I(hp * 100.)) .. "%")
                MultiboardSetItemValueColor(mbitem, R2I(MathClamp(CubicInterpolation(hp, 295., 275., 140., 0.), 0, 255)), R2I(MathClamp(CubicInterpolation(hp, 0, 20., 255., 255.), 0, 255)), 0, 255)
                MultiboardReleaseItem(mbitem)

                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 1)
                if Hardcore[pid] then
                    MultiboardSetItemStyle(mbitem, false, true)
                    MultiboardSetItemIcon(mbitem, "ReplaceableTextures\\CommandButtons\\BTNBirial.blp")
                else
                    MultiboardSetItemStyle(mbitem, false, false)
                end
                MultiboardReleaseItem(mbitem)
                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 2)
                MultiboardSetItemStyle(mbitem, false, true)
                MultiboardSetItemIcon(mbitem, BlzGetAbilityIcon(GetUnitTypeId(Hero[pid])))
                MultiboardReleaseItem(mbitem)
            else
                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 1)
                MultiboardSetItemStyle(mbitem, false, false)
                MultiboardReleaseItem(mbitem)
                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 2)
                MultiboardSetItemStyle(mbitem, false, false)
                MultiboardReleaseItem(mbitem)
                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 3)
                MultiboardSetItemValue(mbitem, "")
                MultiboardReleaseItem(mbitem)
                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 4)
                MultiboardSetItemValue(mbitem, "")
                MultiboardReleaseItem(mbitem)
                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 5)
                MultiboardSetItemValue(mbitem, "")
                MultiboardReleaseItem(mbitem)
            end
        end

        pid = pid + 1
    end

    --unit id loop
    for _, v in ipairs(Unit.list) do
        --refresh weather
        if TimerGetRemaining(WeatherTimer) > 0 then
            --weather that only affects players
            if GetPlayerId(GetOwningPlayer(v.unit)) < PLAYER_CAP or WeatherTable[CURRENT_WEATHER][WEATHER_ALL] == 1 then
                if UnitAlive(v.unit) and RectContainsCoords(gg_rct_Main_Map, GetUnitX(v.unit), GetUnitY(v.unit)) then
                    WeatherBuff:add(v.unit, v.unit).duration = TimerGetRemaining(WeatherTimer)
                    if WeatherBuff:get(v.unit, v.unit).weather ~= CURRENT_WEATHER then
                        WeatherBuff:get(v.unit, v.unit):dispel()
                    end
                else
                    WeatherBuff:get(v.unit, v.unit):dispel()
                end
            end
        end
    end

    --player loop
    p = User.first

    while p do

        --set space bar camera to town
        if GetLocalPlayer() == p.player then
            SetCameraQuickPositionLoc(TownCenter)
        end

        --update boost variance every second
        BOOST[p.id] = 1. + BoostValue[p.id] + GetRandomReal(-0.2, 0.2)
        LBOOST[p.id] = 1. + 0.5 * BoostValue[p.id]

        if LIBRARY_dev then
            if BOOST_OFF then
                BOOST[p.id] = (1. + BoostValue[p.id])
            end
        end

        --Heli leash
        if helicopter[p.id] ~= nil and UnitDistance(Hero[p.id], helicopter[p.id]) > 700. then
            SetUnitPosition(helicopter[p.id], GetUnitX(Hero[p.id]), GetUnitY(Hero[p.id]))
        end

        --Refresh dungeon queue multiboard
        if CountPlayersInForceBJ(QUEUE_GROUP) > 0 then
            MultiboardSetRowCount(QUEUE_BOARD, CountPlayersInForceBJ(QUEUE_GROUP))
            MultiboardSetColumnCount(QUEUE_BOARD, 2)

            if IsPlayerInForce(p.player, QUEUE_GROUP) then
                mbitem = MultiboardGetItem(QUEUE_BOARD, boardpos, 0)
                MultiboardSetItemValue(mbitem, p.nameColored)
                MultiboardSetItemStyle(mbitem, true, false)
                MultiboardSetItemWidth(mbitem, 0.1)
                MultiboardReleaseItem(mbitem)
                mbitem = MultiboardGetItem(QUEUE_BOARD, boardpos, 1)
                MultiboardSetItemStyle(mbitem, false, true)
                MultiboardSetItemWidth(mbitem, 0.01)

                if QUEUE_READY[p.id] then
                    MultiboardSetItemIcon(mbitem, "ReplaceableTextures\\CommandButtons\\BTNcheck.blp")
                else
                    MultiboardSetItemIcon(mbitem, "ReplaceableTextures\\CommandButtons\\BTNCancel.blp")
                end

                MultiboardReleaseItem(mbitem)

                boardpos = boardpos + 1
            end

            MultiboardDisplay(MULTI_BOARD, false)
            MultiboardDisplay(QUEUE_BOARD, true)
        else
            QUEUE_DUNGEON = 0
            MultiboardDisplay(QUEUE_BOARD, false)
            MultiboardDisplay(MULTI_BOARD, true)
        end

        --Cooldowns

        if HeroID[p.id] > 0 then
            UpdateManaCosts(p.id)

            --intense focus
            if GetUnitAbilityLevel(Hero[p.id], FourCC('A0B9')) > 0 and UnitAlive(Hero[p.id]) and LAST_HERO_X[p.id] == GetUnitX(Hero[p.id]) and LAST_HERO_Y[p.id] == GetUnitY(Hero[p.id]) and BlzBitAnd(HERO_PROF[p.id], PROF_BOW) ~= 0 then
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

            hp = GetUnitState(Hero[p.id], UNIT_STATE_LIFE) / BlzGetUnitMaxHP(Hero[p.id]) * 100

            --backpack hp/mp percentage
            if hp >= 1 then
                hp = GetUnitState(Hero[p.id], UNIT_STATE_LIFE) / BlzGetUnitMaxHP(Hero[p.id])
                SetUnitState(Backpack[p.id], UNIT_STATE_LIFE, BlzGetUnitMaxHP(Backpack[p.id]) * hp)
                mp = GetUnitState(Hero[p.id], UNIT_STATE_MANA) / GetUnitState(Hero[p.id], UNIT_STATE_MAX_MANA)
                SetUnitState(Backpack[p.id], UNIT_STATE_MANA, GetUnitState(Backpack[p.id], UNIT_STATE_MAX_MANA) * mp)
            end

            --blood bank
            if HeroID[p.id] == HERO_VAMPIRE then
                BloodBank[p.id] = math.min(BLOODBANK.curr(pid), BLOODBANK.max(pid))
                BlzSetUnitMaxMana(Hero[p.id], R2I(BLOODBANK.max(pid)))
                SetUnitState(Hero[p.id], UNIT_STATE_MANA, BLOODBANK.curr(pid))

                hp = (BloodBank[p.id] / BLOODBANK.max(pid)) * 5
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
                if BloodMistBuff:has(Hero[p.id], Hero[p.id]) and BloodBank[p.id] >= BLOODMIST.cost(pid) then
                    BloodBank[p.id] = BloodBank[p.id] - BLOODMIST.cost(pid)
                    SetUnitState(Hero[p.id], UNIT_STATE_MANA, BloodBank[p.id])

                    HP(Hero[p.id], BLOODMIST.heal(pid) * BOOST[p.id])
                    if GetUnitAbilityLevel(Hero[p.id], FourCC('B02Q')) == 0 then
                        Item.create(UnitAddItemById(Hero[p.id], FourCC('I0OE')))
                    end
                    BlzSetSpecialEffectAlpha(BloodMistBuff:get(Hero[p.id], Hero[p.id]).sfx, 255)
                else
                    UnitRemoveAbility(Hero[p.id], FourCC('B02Q'))
                    BlzSetSpecialEffectAlpha(BloodMistBuff:get(Hero[p.id], Hero[p.id]).sfx, 0)
                end
            end

            --tooltips
            UpdateSpellTooltips(p.id)

            --TODO for now use 900 as default aura range
            MakeGroupInRange(p.id, ug, GetUnitX(Hero[p.id]), GetUnitY(Hero[p.id]), 900. * LBOOST[p.id], Condition(isalive))

            target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                if IsUnitAlly(target, Player(p.id - 1)) then
                    if InspireActive[p.id] then
                        b = InspireBuff:get(nil, target)

                        --choose strongest one
                        if b then
                            b.ablev = IMaxBJ(b.ablev, GetUnitAbilityLevel(Hero[p.id], INSPIRE.id))
                        else
                            InspireBuff:add(Hero[p.id], target):duration(1.)
                        end

                        --mana cost
                        hp = GetUnitState(Hero[p.id], UNIT_STATE_MANA)
                        mp = BlzGetUnitMaxMana(Hero[p.id]) * 0.02
                        SetUnitState(Hero[p.id], UNIT_STATE_MANA, math.max(hp - mp, 0))
                        if hp - mp <= 0 then
                            IssueImmediateOrderById(Hero[p.id], 852178)
                        end
                    end
                    if BardSong[p.id] == SONG_WAR then
                        b = SongOfWarBuff:get(nil, target)

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
                        b = JusticeAuraBuff:get(nil, target)
                        b.ablev = IMaxBJ(b.ablev, GetUnitAbilityLevel(Hero[p.id], AURAOFJUSTICE.id))
                    end
                elseif IsUnitAlly(target, Player(p.id - 1)) == false and UnitIsSleeping(target) == false then
                    if BardSong[p.id] == SONG_FATIGUE then
                        SongOfFatigueSlow:add(Hero[p.id], target):duration(2.)
                    elseif masterElement[p.id] == ELEMENTICE.value then
                        IceElementSlow:add(Hero[p.id], target):duration(2.)
                    end
                end
                target = FirstOfGroup(ug)
            end
        end

        p = p.next
    end

    --move multiboard
    BlzFrameClearAllPoints(MultiBoard)
    BlzFrameSetAbsPoint(MultiBoard, FRAMEPOINT_TOPRIGHT, 0.8, 0.6)

    DestroyGroup(g)
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
            if order == 851972 or order == 851993 or order == 0 then --stop, holdposition, or null
                Moving[p.id] = false
            else
                dist = DistanceCoords(GetUnitX(Hero[p.id]), GetUnitY(Hero[p.id]), clickedpointX[p.id], clickedpointY[p.id])
                if dist < 55. then
                    Moving[p.id] = false
                elseif Movespeed[p.id] - 522 > 0 then
                    angle = Atan2(clickedpointY[p.id] - GetUnitY(Hero[p.id]), clickedpointX[p.id] - GetUnitX(Hero[p.id]))
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

        p = p.next
    end
end

function PeriodicFPS()
    local U = User.first ---@type User 
    local itm ---@type Item 
    local u = GetMainSelectedUnitEx() ---@type unit 

    --rarity item borders
    BlzFrameSetVisible(INVENTORYBACKDROP[0], false)
    BlzFrameSetVisible(INVENTORYBACKDROP[1], false)
    BlzFrameSetVisible(INVENTORYBACKDROP[2], false)
    BlzFrameSetVisible(INVENTORYBACKDROP[3], false)
    BlzFrameSetVisible(INVENTORYBACKDROP[4], false)
    BlzFrameSetVisible(INVENTORYBACKDROP[5], false)

    for i = 0, 5 do
        itm = Item[UnitItemInSlot(u, i)]

        if itm then
            BlzFrameSetTexture(INVENTORYBACKDROP[i], SPRITE_RARITY[itm.level], 0, true)
            BlzFrameSetVisible(INVENTORYBACKDROP[i], true)
        end
    end

    --hide health ui
    if UndyingRageBuff:has(u, u) then
        BlzFrameSetVisible(hideHealth, true)
    else
        BlzFrameSetVisible(hideHealth, false)
    end

    while U do
        --heli text follow
        if helitag[U.id] ~= nil and UnitAlive(helicopter[U.id]) then
            SetTextTagPosUnit(helitag[U.id], helicopter[U.id], -200.)
        end

        --camera lock
        if selectingHero[U.id] then
            if (GetLocalPlayer() == U.player) then
                SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 500, 0)
                SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 340, 0)
                SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, 60, 0)
                SetCameraField(CAMERA_FIELD_ZOFFSET, 200, 0)
                SetCameraField(CAMERA_FIELD_ROTATION, GetUnitFacing(HeroCircle[hslook[U.id]].unit) + 180, 0)
                SetCameraTargetController(gg_unit_h00T_0511, 0, 0, false)
            end
        elseif CameraLock[U.id] then
            if (GetLocalPlayer() == U.player) then
                SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, Zoom[U.id], 0)
            end
        end

        U = U.next
    end
end

    local savetimer         = CreateTrigger() ---@type trigger 
    local wandering         = CreateTrigger() ---@type trigger 
    local u      = User.first ---@type User 

    TimerQueue:callPeriodically(FPS_64, nil, PeriodicFPS)
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
