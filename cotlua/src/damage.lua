--[[
    damage.lua

    A library that handles the damage event (EVENT_PLAYER_UNIT_DAMAGING) and provides
    related functions.

    TODO: Migrate dps testing dummy to another file?
]]

OnInit.final("Damage", function(Require)
    Require('Variables')
    Require('UnitTable')

    THREAT_CAP  = 4000 ---@type integer 

    HeroInvul  = {} ---@type boolean[] 
    HeartBlood = __jarray(0) ---@type integer[] 
    BossDamage = __jarray(0) ---@type integer[] 
    ignoreflag = __jarray(0) ---@type integer[] 

    DUMMY_TIMER = CreateTimer() ---@type timer 

    DUMMY_TOTAL_PHYSICAL = 0. ---@type number 
    DUMMY_TOTAL_MAGIC    = 0. ---@type number 
    DUMMY_TOTAL          = 0. ---@type number 
    DUMMY_LAST           = 0. ---@type number 
    DUMMY_DPS            = 0. ---@type number 
    DUMMY_DPS_PEAK       = 0. ---@type number 
    DUMMY_STORAGE        = CircularArrayList.create() ---@type CircularArrayList 

    ATTACK_CHAOS     = 5 ---@type integer 
    ARMOR_CHAOS      = 6 ---@type integer 
    ARMOR_CHAOS_BOSS = 7 ---@type integer 

    PHYSICAL = DAMAGE_TYPE_NORMAL ---@type damagetype 
    MAGIC    = DAMAGE_TYPE_MAGIC ---@type damagetype 
    PURE     = DAMAGE_TYPE_DIVINE ---@type damagetype 

    local color_tag = {
        [MAGIC] = {100, 100, 255},
        [PURE] = {255, 255, 100},
        [PHYSICAL] = {200, 50, 50},
        crit = {255, 120, 20},
    }

---@return boolean
function OnAcquire()
    local target = GetEventTargetUnit() ---@type unit 
    local attacker = GetTriggerUnit() ---@type unit 
    local pid = GetPlayerId(GetOwningPlayer(attacker)) + 1

    if IsDummy(attacker) then
        BlzSetUnitWeaponBooleanField(attacker, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
    elseif GetPlayerController(Player(pid - 1)) ~= MAP_CONTROL_USER then
        Threat[attacker].target = AcquireProximity(attacker, target, 800.)
        TimerQueue:callDelayed(FPS_32, SwitchAggro, attacker, target)
    elseif Unit[attacker] then
        Unit[attacker].target = target
        
        if Unit[attacker].movespeed > MOVESPEED_MAX then
            BlzSetUnitFacingEx(attacker, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(attacker), GetUnitX(target) - GetUnitX(attacker)))
        end
    end

    return false
end

---@type fun(pt: PlayerTimer)
function DUMMY_HIDE_TEXT(pt)
    pt.dur = pt.dur - 1

    if pt.dur <= 0 then
        if GetLocalPlayer() == Player(pt.pid - 1) then
            BlzFrameSetVisible(dummyFrame, false)
        end

        pt:destroy()
    end

    pt.timer:callDelayed(1., DUMMY_HIDE_TEXT, pt)
end

function DUMMY_RESET()
    DUMMY_TOTAL_PHYSICAL = 0.
    DUMMY_TOTAL_MAGIC = 0.
    DUMMY_TOTAL = 0.
    DUMMY_LAST = 0.
    DUMMY_DPS = 0.
    DUMMY_DPS_PEAK = 0.
    DUMMY_STORAGE:wipe()
    BlzFrameSetText(dummyTextValue, "0\n0\n0\n0\n0\n0\n0s")
end

---@type fun(pt: PlayerTimer)
function DUMMY_DPS_UPDATE(pt)
    pt.time = pt.time + 0.1

    if DUMMY_TOTAL <= 0 or DUMMY_TOTAL > 2000000000 then
        DUMMY_RESET()
        pt:destroy()
    else
        DUMMY_STORAGE:add(DUMMY_TOTAL)
        if pt.time >= 1. then
            DUMMY_DPS_PEAK = math.max(math.max(DUMMY_STORAGE:calcPeakDps(10), DUMMY_DPS_PEAK), DUMMY_DPS)
            DUMMY_DPS = DUMMY_TOTAL / pt.time
        end

        BlzFrameSetText(dummyTextValue, RealToString(DUMMY_LAST) .. "\n" .. RealToString(DUMMY_TOTAL_PHYSICAL) .. "\n" .. RealToString(DUMMY_TOTAL_MAGIC) .. "\n" .. RealToString(DUMMY_TOTAL) .. "\n" .. RealToString(DUMMY_DPS) .. "\n" .. RealToString(DUMMY_DPS_PEAK) .. "\n" .. RealToString(pt.time) .. "s")
        pt.timer:callDelayed(0.1, DUMMY_DPS_UPDATE, pt)
    end
end

---@type fun(dmg: number, source: unit, target: unit):number
function ReduceArmorCalc(dmg, source, target)
    local armor    = BlzGetUnitArmor(target) ---@type number 
    local pid      = GetPlayerId(GetOwningPlayer(source)) + 1 ---@type integer 
    local newarmor = armor ---@type number 

    if RampageBuff:has(source, source) then --rampage
        newarmor = (math.max(0, armor - armor * (5 * GetUnitAbilityLevel(Hero[pid], RAMPAGE.id)) * 0.01))
    end

    if PiercingStrikeDebuff:has(source, target) then --piercing strikes
        newarmor = (math.max(0, armor - armor * (30 + GetUnitAbilityLevel(Hero[pid], FourCC('A0QU'))) * 0.01))
    end

    if GetUnitAbilityLevel(source, FourCC('A0F6')) > 0 then --flaming bow
        newarmor = (math.max(0, armor - armor * (10 + GetUnitAbilityLevel(Hero[pid], FourCC('A0F6')) * 1) * 0.01))
    end

    if newarmor >= 0 then
        dmg = dmg - (dmg * (0.05 * newarmor / (1 + 0.05 * newarmor)))
    else
        dmg = dmg * (2 - Pow(0.94, (-newarmor)))
    end

    if armor >= 0 then
        dmg = dmg / (1 - (0.05 * armor / (1 + 0.05 * armor)))
    end

    return dmg
end

---@type fun(dmg: number, source: unit, target: unit, TYPE: damagetype):number
function CalcAfterReductions(dmg, source, target, TYPE)
    local armor = BlzGetUnitArmor(target) ---@type number 
    local dtype = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE) ---@type integer 
    local atype = BlzGetUnitWeaponIntegerField(source, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0) ---@type integer 

    if TYPE ~= PURE then
        if (dtype == ARMOR_CHAOS or dtype == ARMOR_CHAOS_BOSS) then --chaos armor
            dmg = dmg * 0.03
        end

        if TYPE == PHYSICAL then
            if atype == ATTACK_CHAOS then
                dmg = dmg * 350.
            end

            if armor >= 0 then
                dmg = dmg - (dmg * (0.05 * armor / (1. + 0.05 * armor)))
            else
                dmg = dmg * (2. - Pow(0.94, (-armor)))
            end
        end
    end

    return dmg
end

--[[
damage flow chart:
handle dummy attacks first and return
handle specific physical/magic damage events
handle spell / buff procs
apply multipliers
apply mitigations
handle misc things
fatal damage
]]

---@return boolean
function OnDamage()
    local source      = GetEventDamageSource() ---@type unit 
    local target      = BlzGetEventDamageTarget() ---@type unit 
    local amount      = GetEventDamage() ---@type number 
    local damageType  = BlzGetEventDamageType() ---@type damagetype 
    local pid         = GetPlayerId(GetOwningPlayer(source)) + 1 ---@type integer 
    local tpid        = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 
    local uid         = GetUnitTypeId(source) ---@type integer 
    local tuid        = GetUnitTypeId(target) ---@type integer 
    local dmg         = 0. ---@type number 
    local crit        = 0. ---@type number 
    local pbagFlag    = target == PUNCHING_BAG
    local tag         = GetDamageTag()

    --prevents 0 damage events from applying debuffs
    if source == nil or target == nil then
        return false
    end

    --force unknown damage types to be magic
    if damageType ~= PHYSICAL and damageType ~= MAGIC and damageType ~= PURE then
        damageType = MAGIC
        BlzSetEventDamageType(MAGIC)
    end

    --[[
    dummy attack handling <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]]

    --TODO move these to a table or rework using missiles
    --arcanist arcane barrage
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A008')) > 0 then
        UnitRemoveAbility(source, FourCC('A008'))
        DamageTarget(Hero[pid], target, ARCANEBARRAGE.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, ARCANEBARRAGE.tag)
    end

    --phoenix ranger searing arrow
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A069')) > 0 then
        UnitRemoveAbility(source, FourCC('A069'))
        Dummy.create(GetUnitX(source), GetUnitY(source), FourCC('A092'), 1):cast(Player(pid - 1), "slow", target)
        DamageTarget(Hero[pid], target, (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroAgi(Hero[pid], true)) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, SEARINGARROWS.tag)
    end

    --electrocute lightning
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A09W')) > 0 then
        UnitRemoveAbility(source, FourCC('A09W'))
        DamageTarget(Hero[pid], target, GetWidgetLife(target) * 0.005, ATTACK_TYPE_NORMAL, PURE, ELEMENTLIGHTNING.tag)
    end

    --medean lightning trigger
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A01Y')) > 0 then
        UnitRemoveAbility(source, FourCC('A01Y'))
        DamageTarget(Hero[pid], target, MEDEANLIGHTNING.dmg(pid, GetUnitAbilityLevel(Hero[pid], MEDEANLIGHTNING.id)) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, MEDEANLIGHTNING.tag)
    end

    --frozen orb icicle
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A09F')) > 0 then
        DamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * GetUnitAbilityLevel(Hero[pid], FROZENORB.id)) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, FROZENORB.tag)
    end

    --satan flame strike
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A0DN')) > 0 and IsUnitEnemy(target, pboss) then
        DamageTarget(BossTable[BOSS_SATAN].unit, target, 10000., ATTACK_TYPE_NORMAL, MAGIC, "Flame Onslaught")
    end

    --instill fear trigger
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A0AE')) > 0 then
        UnitRemoveAbility(source, FourCC('A0AE'))
        InstillFear[pid] = target
        TimerQueue:callDelayed(7., InstillFearExpire, pid)
    end

    --single shot trigger
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A05J')) > 0 then
        UnitRemoveAbility(source, FourCC('A05J'))
    end

    --blizzard 
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A02O')) > 0 then
        amount = 0.00
        local pt = TimerList[pid]:get(BLIZZARD.id, source)
        if pt then
            dmg = pt.dmg
            if pt.infused then
                dmg = dmg * 1.3
            end
            DamageTarget(Hero[pid], target, dmg * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, BLIZZARD.tag)
        end
    end

    --dark summoner devour
    if IsDummy(source) and GetUnitAbilityLevel(source, FourCC('A00W')) > 0 then
        if tuid == SUMMON_GOLEM then --meat golem
            BorrowedLife[pid * 10] = 0
            UnitAddBonus(meatgolem[pid], BONUS_HERO_STR, - R2I(GetHeroStr(meatgolem[pid], false) * 0.1 * golemDevourStacks[pid]))
            golemDevourStacks[pid] = golemDevourStacks[pid] + 1
            BlzSetHeroProperName(meatgolem[pid], "Meat Golem (" .. (golemDevourStacks[pid]) .. ")")
            FloatingTextUnit(tostring(golemDevourStacks[pid]), meatgolem[pid], 1, 60, 50, 13.5, 255, 255, 255, 0, true)
            UnitAddBonus(meatgolem[pid], BONUS_HERO_STR, R2I(GetHeroStr(meatgolem[pid], false) * 0.1 * golemDevourStacks[pid]))
            SetUnitScale(meatgolem[pid], 1 + golemDevourStacks[pid] * 0.07, 1 + golemDevourStacks[pid] * 0.07, 1 + golemDevourStacks[pid] * 0.07)
            --magnetic
            if golemDevourStacks[pid] == 1 then
                UnitAddAbility(meatgolem[pid], FourCC('A071'))
            elseif golemDevourStacks[pid] == 2 then
                UnitAddAbility(meatgolem[pid], FourCC('A06O'))
            --thunder clap
            elseif golemDevourStacks[pid] == 3 then
                UnitAddAbility(meatgolem[pid], FourCC('A0B0'))
            elseif golemDevourStacks[pid] == 5 then
                UnitAddBonus(meatgolem[pid], BONUS_ARMOR, R2I(BlzGetUnitArmor(meatgolem[pid]) * 0.25 + 0.5))
            end
            if golemDevourStacks[pid] >= GetUnitAbilityLevel(Hero[pid], DEVOUR.id) + 1 then
                UnitDisableAbility(meatgolem[pid], FourCC('A06C'), true)
            end
            SetUnitAbilityLevel(meatgolem[pid], FourCC('A071'), golemDevourStacks[pid])
        elseif tuid == SUMMON_DESTROYER then --destroyer
            BorrowedLife[pid * 10 + 1] = 0
            UnitAddBonus(destroyer[pid], BONUS_HERO_INT, - R2I(GetHeroInt(destroyer[pid], false) * 0.15 * destroyerDevourStacks[pid]))
            destroyerDevourStacks[pid] = destroyerDevourStacks[pid] + 1
            UnitAddBonus(destroyer[pid], BONUS_HERO_INT, R2I(GetHeroInt(destroyer[pid], false) * 0.15 * destroyerDevourStacks[pid]))
            BlzSetHeroProperName(destroyer[pid], "Destroyer (" .. (destroyerDevourStacks[pid]) .. ")")
            FloatingTextUnit(tostring(destroyerDevourStacks[pid]), destroyer[pid], 1, 60, 50, 13.5, 255, 255, 255, 0, true)
            if destroyerDevourStacks[pid] == 1 then
                UnitAddAbility(destroyer[pid], FourCC('A071'))
                UnitAddAbility(destroyer[pid], FourCC('A061')) --blink
            elseif destroyerDevourStacks[pid] == 2 then
                UnitAddAbility(destroyer[pid], FourCC('A03B')) --crit
            elseif destroyerDevourStacks[pid] == 3 then
                SetHeroAgi(destroyer[pid], 200, true)
            elseif destroyerDevourStacks[pid] == 4 then
                SetUnitAbilityLevel(destroyer[pid], FourCC('A02D'), 2)
            elseif destroyerDevourStacks[pid] == 5 then
                SetHeroAgi(destroyer[pid], 400, true)
                UnitAddBonus(destroyer[pid], BONUS_HERO_INT, R2I(GetHeroInt(destroyer[pid], false) * 0.25))
            end
            if destroyerDevourStacks[pid] >= GetUnitAbilityLevel(Hero[pid], DEVOUR.id) + 1 then
                UnitDisableAbility(destroyer[pid], FourCC('A04Z'), true)
            end
            SetUnitAbilityLevel(destroyer[pid], FourCC('A071'), destroyerDevourStacks[pid])
        end
    end

    --clean up
    if IsDummy(source) then
        BlzSetEventDamage(0.00)
        BlzSetUnitWeaponBooleanField(source, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false) --prevent dummies from attacking twice

        return false
    end

    --[[
    end of dummy handling <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]]

    --[[
    physical damage events >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ]]

    if damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) then
        local evade = Unit[target].evasion

        --evasion
        if GetRandomInt(0, 99) < evade then
            FloatingTextUnit("Dodged!", target, 1, 90, 0, 9, 180, 180, 20, 0, true)
            amount = 0.00
        end

        --player hero is hit
        if target == Hero[tpid] and amount > 0.00 then
            --heart of demon prince damage taken
            if GetUnitLevel(source) >= 170 and IsUnitEnemy(source, GetOwningPlayer(target)) and UnitHasItemType(target, FourCC('I04Q')) then
                HeartBlood[tpid] = HeartBlood[tpid] + 1
                UpdateItemTooltips(tpid)
            end
        end

        --player hero attacks
        if IsUnitType(source, UNIT_TYPE_HERO) == true and ignoreflag[pid] ~= 1 then
            --item effects

            --onhit magic damage (king's clubba)
            if GetUnitAbilityLevel(source, FourCC('Abon')) > 0 then
                DamageTarget(source, target, GetAbilityField(source, FourCC('Abon'), 0), ATTACK_TYPE_NORMAL, MAGIC, "King's Clubba")
            end

            --assassin blade spin count
            if uid == HERO_ASSASSIN then
                BladeSpinCount[pid] = BladeSpinCount[pid] + 1
            end

            --vampire blood bank
            if uid == HERO_VAMPIRE then
                BLOODBANK.add(pid, BLOODBANK.gain(pid))

                --vampire blood lord
                if BloodLordBuff:has(source, source) then
                    DamageTarget(source, target, BLOODLORD.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, BLOODLORD.tag)
                    DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
                end
            end

            --master rogue piercing strike
            if GetRandomInt(0, 99) < 20 and GetUnitAbilityLevel(source, PIERCINGSTRIKE.id) > 0 then
                PiercingStrikeDebuff:add(source, target):duration(3.)
                SetUnitAnimation(source, "spell slam")
            end

            if PiercingStrikeDebuff:has(source, target) then
                amount = ReduceArmorCalc(amount, source, target)
            end

            --bloodzerker
            if uid == HERO_BLOODZERKER then
                --blood cleave
                if GetUnitAbilityLevel(source, BLOODCLEAVE.id) > 0 and ignoreflag[pid] ~= 2 then
                    local chance = BLOODCLEAVE.chance
                    local double = 1

                    if RampageBuff:has(source, source) then
                        chance = chance + 5
                    end

                    if UndyingRageBuff:has(source, source) then
                        chance = chance * 2
                        double = 2
                    end

                    if GetRandomReal(0, 99) < chance * LBOOST[pid] then
                        dmg = 0
                        ignoreflag[pid] = 2

                        local ug = CreateGroup()
                        MakeGroupInRange(pid, ug, GetUnitX(source), GetUnitY(source), BLOODCLEAVE.aoe(pid) * LBOOST[pid], Condition(FilterEnemy))
                        DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Reapers Claws Red.mdx", source, "chest"))

                        for u in each(ug) do
                            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", u, "chest"))
                            dmg = dmg + CalcAfterReductions(BLOODCLEAVE.dmg(pid) * BOOST[pid], source, target, PHYSICAL)
                            DamageTarget(source, u, BLOODCLEAVE.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, BLOODCLEAVE.tag)
                        end

                        DestroyGroup(ug)

                        ignoreflag[pid] = 0

                        --leech health
                        HP(source, source, dmg * double, BLOODCLEAVE.tag)
                    end
                end

                --rampage armor ignore
                if RampageBuff:has(source, source) then
                    amount = ReduceArmorCalc(amount, source, target)
                end
            end

            -- master rogue
            if uid == HERO_MASTER_ROGUE then
                local angle = 0

                --backstab
                if GetUnitAbilityLevel(source, BACKSTAB.id) > 0 then
                    angle = Atan2(GetUnitY(source) - GetUnitY(target), GetUnitX(source) - GetUnitX(target)) - (bj_DEGTORAD * (GetUnitFacing(target) - 180))

                    if angle > bj_PI then
                        angle = angle - 2 * bj_PI
                    elseif angle < -bj_PI then
                        angle = angle + 2 * bj_PI
                    end

                    if RAbsBJ(angle) <= (0.25 * bj_PI) and (IsUnitType(target,UNIT_TYPE_STRUCTURE) == false) then
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "chest"))
                        DamageTarget(source, target, BACKSTAB.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, BACKSTAB.tag)
                    end
                end

                --instant death
                if GetUnitAbilityLevel(source, INSTANTDEATH.id) > 0 then
                    HiddenGuise[pid] = false

                    crit = crit + INSTANTDEATH.crit(pid, angle, target)
                end
            end

            --phoenix ranger fiery arrows / flaming bow
            if uid == HERO_PHOENIX_RANGER then
                if GetUnitAbilityLevel(source,FourCC('A0IB')) > 0 then
                    local ablev = GetUnitAbilityLevel(source, FourCC('A0IB'))
                    if GetRandomInt(0,99) < ablev * 2 * LBOOST[pid] then
                        DamageTarget(source, target, (((UnitGetBonus(source, BONUS_DAMAGE) + GetHeroAgi(source, true)) * .3 + GetHeroAgi(source, true) * ablev)) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, FLAMINGBOW.tag)
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target),GetUnitY(target)))
                        if GetUnitAbilityLevel(target, FourCC('B02O')) > 0 then
                            UnitRemoveAbility(target, FourCC('B02O'))
                            SEARINGARROWS.ignite(source, target)
                        end
                    end
                end

                if GetUnitAbilityLevel(source, FourCC('A0F6')) > 0 then --armor pen
                    amount = ReduceArmorCalc(amount, source, target)
                end

                local buff = FlamingBowBuff:get(nil, source)

                if buff then
                    buff:onHit()
                end
            end

            --holy bash (savior)
            if GetUnitAbilityLevel(source, HOLYBASH.id) > 0 and uid == HERO_SAVIOR then
                saviorBashCount[pid] = saviorBashCount[pid] + 1
                if saviorBashCount[pid] > 10 then
                    DamageTarget(source, target, HOLYBASH.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, HOLYBASH.tag)
                    saviorBashCount[pid] = 0

                    local pt = TimerList[pid]:get(LIGHTSEAL.id, source)

                    --light seal augment
                    if pt then
                        MakeGroupInRange(pid, pt.ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

                        for u in each(pt.ug) do
                            if u ~= target then
                                StunUnit(pid, u, 2.)
                                DamageTarget(source, u, HOLYBASH.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, HOLYBASH.tag)
                            end
                        end
                    end

                    StunUnit(pid, target, 2.)

                    --aoe heal
                    local ug = CreateGroup()
                    MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), HOLYBASH.aoe * LBOOST[pid], Condition(FilterAlly))

                    for u in each(ug) do
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", u, "origin")) --change effect
                        HP(source, u, HOLYBASH.heal(pid) * BOOST[pid], HOLYBASH.tag)
                    end

                    DestroyGroup(ug)
                end
            end

            --bard encore (song of war)
            local buff = SongOfWarEncoreBuff:get(nil, source)

            if buff then
                DamageTarget(buff.source, target, buff.dmg * BOOST[GetPlayerId(GetOwningPlayer(buff.source)) + 1], ATTACK_TYPE_NORMAL, MAGIC, ENCORE.tag)

                buff:onHit()
            end

            --demon hound critical strike (dark summoner)
            if uid == SUMMON_HOUND then
                if GetRandomInt(0, 99) < 25 then
                    if destroyerSacrificeFlag[pid] then
                        --aoe attack
                        local ug = CreateGroup()
                        MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 400. * LBOOST[pid], Condition(FilterEnemy))

                        for u in each(ug) do
                            DamageTarget(source, u, GetHeroInt(source, true) * 1.25 * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, "Deadly Bite")
                        end

                        DestroyGroup(ug)
                    else
                        DamageTarget(source, target, GetHeroInt(source, true) * LBOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, "Deadly Bite")
                    end
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                end
            end

            --destroyer critical strike (dark summoner)
            if uid == SUMMON_DESTROYER then
                local ablev = 10

                if destroyerDevourStacks[pid] >= 2 then
                    if GetRandomInt(0, 99) < 25 then
                        crit = crit + 3
                    end

                    if destroyerDevourStacks[pid] >= 4 then
                        ablev = 15
                    end
                end

                if GetRandomInt(0, 99) < ablev then
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                    DamageTarget(source, target, GetHeroInt(source, true) * LBOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, "Annihilation Strike")
                end
            end

            --dark savior dark blade
            if GetUnitAbilityLevel(source, FourCC('B01A')) > 0 then
                DamageTarget(source, target, DARKBLADE.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, DARKBLADE.tag)
                DARKBLADE.cost(pid)
            end

            --oblivion guard infernal strike / magnetic strike
            if InfernalStrikeBuff:has(source, source) or MagneticStrikeBuff:has(source, source) then
                BodyOfFireCharges[pid] = BodyOfFireCharges[pid] - 1

                if GetLocalPlayer() == Player(pid - 1) then
                    BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\BTNBodyOfFire" .. (BodyOfFireCharges[pid]) .. ".blp")
                end

                --disable casting at 0 charges
                if BodyOfFireCharges[pid] <= 0 then
                    UnitDisableAbility(source, INFERNALSTRIKE.id, true)
                    BlzUnitHideAbility(source, INFERNALSTRIKE.id, false)
                    UnitDisableAbility(source, MAGNETICSTRIKE.id, true)
                    BlzUnitHideAbility(source, MAGNETICSTRIKE.id, false)
                end

                --refresh charge timer
                local pt = TimerList[pid]:get('bofi', source, nil)
                if not pt then
                    pt = TimerList[pid]:add()
                    pt.source = source
                    pt.tag = 'bofi'

                    BlzStartUnitAbilityCooldown(source, BODYOFFIRE.id, 5.)
                    TimerQueue:callDelayed(5., BODYOFFIRE.cooldown, pt)
                end

                if InfernalStrikeBuff:has(source, source) then
                    InfernalStrikeBuff:dispel(source, source)
                    amount = 0.00

                    ignoreflag[pid] = 1
                    local ablev = GetUnitAbilityLevel(source, INFERNALSTRIKE.id)

                    local ug = CreateGroup()
                    MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * LBOOST[pid], Condition(FilterEnemy))
                    local count = BlzGroupGetSize(ug)

                    for u in each(ug) do
                        if IsUnitType(u, UNIT_TYPE_HERO) then
                            count = count + 4
                        end
                        local dtype = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE)

                        if dtype == 7 then --chaos boss
                            DamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * 7.5 * LBOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, INFERNALSTRIKE.tag)
                        elseif dtype == 6 then
                            DamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * 15. * LBOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, INFERNALSTRIKE.tag)
                        elseif dtype == 1 then --prechaos boss
                            DamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * 0.5 * LBOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, INFERNALSTRIKE.tag)
                        elseif dtype == 0 then
                            DamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * LBOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, INFERNALSTRIKE.tag)
                        end
                    end

                    DestroyGroup(ug)

                    ignoreflag[pid] = 0

                    DestroyEffect(AddSpecialEffect("war3mapImported\\Lava_Slam.mdx", GetUnitX(target), GetUnitY(target)))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))

                    --6 percent max heal
                    HP(source, source, BlzGetUnitMaxHP(source) * 0.01 * IMinBJ(6, i), INFERNALSTRIKE.tag)
                elseif MagneticStrikeBuff:has(source, source) then
                    MagneticStrikeBuff:dispel(source, source)

                    local ug = CreateGroup()
                    MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * LBOOST[pid], Condition(FilterEnemy))

                    for u in each(ug) do
                        MagneticStrikeDebuff:add(source, u):duration(10.)
                    end

                    DestroyGroup(ug)

                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", GetUnitX(target), GetUnitY(target)))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
                end
            end

            --arcanist cds
            if TimerList[pid]:has(ARCANOSPHERE.id) then
                BlzStartUnitAbilityCooldown(Hero[pid], ARCANECOMETS.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANECOMETS.id) - 3.))
            else
                BlzStartUnitAbilityCooldown(Hero[pid], ARCANEBOLTS.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANEBOLTS.id) - 3.))
            end

            local pt = TimerList[pid]:get(ARCANESHIFT.id, Hero[pid])

            if pt then
                pt.cd = pt.cd - 3
            else
                BlzStartUnitAbilityCooldown(Hero[pid], ARCANESHIFT.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANESHIFT.id) - 3.))
            end
            BlzStartUnitAbilityCooldown(Hero[pid], ARCANEBARRAGE.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANEBARRAGE.id) - 3.))
            BlzStartUnitAbilityCooldown(Hero[pid], STASISFIELD.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], STASISFIELD.id) - 3.))
            BlzStartUnitAbilityCooldown(Hero[pid], ARCANOSPHERE.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANOSPHERE.id) - 3.))
            BlzStartUnitAbilityCooldown(Hero[pid], CONTROLTIME.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], CONTROLTIME.id) - 3.))

            --phoenix ranger multi shot
            if MultiShot[pid] then
                amount = amount * 0.6
            end

            --player hero item crit
            if source == Hero[pid] then
                for i = 0, 5 do
                    local itm = Item[UnitItemInSlot(Hero[pid], i)]

                    if itm then
                        if GetRandomInt(0, 99) < itm:getValue(ITEM_CRIT_CHANCE, 0) then
                            crit = crit + itm:getValue(ITEM_CRIT_DAMAGE, 0)
                        end
                    end
                end
            end

            --elite marksman sniper stance crit
            if uid == HERO_MARKSMAN_SNIPER then
                crit = SNIPERSTANCE.crit(pid, GetUnitAbilityLevel(source, SNIPERSTANCE.id))
            end

            --apply crit multiplier
            if crit > 0 then
                amount = amount * crit
            end
        end
    end

    --[[
    spell/buff effects on damage >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ]]

    --frost armor debuff
    if FrostArmorBuff:has(target, target) and damageType == PHYSICAL then
        FrostArmorDebuff:add(target, source):duration(3.)
    end

    --ursa elder frost nova
    if tuid == FourCC('nfpe') and BlzGetUnitAbilityCooldownRemaining(target, FourCC('ACfn')) <= 0 then
        IssueTargetOrder(target, "frostnova", source)
    end

    --forgotten one tentacle
    if tuid == FourCC('n08M') and GetRandomInt(1, 5) == 1 then
        IssueImmediateOrder(target, "waterelemental")
    end

    --legion reality rip
    if amount > 0.00 and GetUnitAbilityLevel(source, FourCC('A06M')) > 0 and damageType == PHYSICAL then
        if IsUnitIllusion(source) then
            DamageTarget(source, target, BlzGetUnitMaxHP(target) * 0.0025, ATTACK_TYPE_NORMAL, MAGIC, "Reality Rip")
        else
            DamageTarget(source, target, BlzGetUnitMaxHP(target) * 0.005, ATTACK_TYPE_NORMAL, MAGIC, "Reality Rip")
        end
    end

    --death knight decay
    if amount > 0.00 and GetUnitAbilityLevel(source, FourCC('A08N')) > 0 and damageType == PHYSICAL then
        if GetRandomInt(0, 99) < 20 then
            DamageTarget(source, target, 2500., ATTACK_TYPE_NORMAL, MAGIC, "Decay")
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", target, "origin"))
        end
    end

    --spell reflect (boss_hate) (before reductions)
    if damageType == MAGIC and GetUnitAbilityLevel(target, FourCC('A00S')) > 0 and UnitAlive(source) and BlzGetUnitAbilityCooldownRemaining(target, FourCC('A00S')) <= 0 and amount > 10000. then
        local angle = Atan2(GetUnitY(source) - GetUnitY(target), GetUnitX(source) - GetUnitX(target))
        local sfx = AddSpecialEffect("war3mapImported\\BoneArmorCasterTC.mdx", GetUnitX(target) + 75. * Cos(angle), GetUnitY(target) + 75. * Sin(angle))

        BlzSetSpecialEffectZ(sfx, BlzGetUnitZ(target) + 80.)
        BlzSetSpecialEffectColorByPlayer(sfx, Player(0))
        BlzSetSpecialEffectYaw(sfx, angle)
        BlzSetSpecialEffectScale(sfx, 0.9)
        BlzSetSpecialEffectTimeScale(sfx, 3.)

        DestroyEffect(sfx)

        BlzStartUnitAbilityCooldown(target, FourCC('A00S'), 5.)
        --call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl", target, "origin"))
        DamageTarget(target, source, math.min(amount, 2500), ATTACK_TYPE_NORMAL, MAGIC, "Spell Reflect")

        amount = math.max(0, amount - 20000)
    end

    --[[
    multipliers >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ]]

    --prevent self damage from being augmented
    if source ~= target then
        --magic damage events >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        if damageType == MAGIC then
            --creeps -30 percent
            if GetUnitAbilityLevel(target, FourCC('A04A')) > 0 then
                amount = amount * 0.7
            end

            --protected existence -33.33 percent
            if ProtectedExistenceBuff:has(nil, target) then
                amount = amount * 0.66
            end

            --astral shield -66.66 percent
            if AstralShieldBuff:has(nil, target) then
                amount = amount * 0.33
            end

            --hellfire shield (bosses) -50 percent
            if IsEnemy(tpid) and UnitHasItemType(target, FourCC('I03Y')) then
                amount = amount * 0.5
            end

            --meat golem magic resist -(25-30) percent
            if tuid == SUMMON_GOLEM and golemDevourStacks[tpid] > 0 then
                amount = amount * (0.75 - golemDevourStacks[tpid] * 0.1)
            end

            --hardmode multiplier +100 percent
            if IsEnemy(pid) and HARD_MODE > 0 then
                amount = amount * 2.
            end

            --thunderblade overload
            if OverloadBuff:has(source, source) then
                amount = amount * OVERLOAD.mult(pid)
            end

            --warrior intimidating shout limit break -40 percent
            local buff = IntimidatingShoutDebuff:get(nil, source)

            if buff then
                if limitBreak[buff.pid] & 0x4 > 0 then
                    amount = amount * 0.6
                end
            end

            --oblivion guard magnetic strike +25 percent
            if MagneticStrikeDebuff:has(nil, target) then
                amount = amount * 1.25
            end
        end

        --any damage type >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        --warrior parry
        if ParryBuff:has(target, target) and amount > 0. then
            amount = 0.00
            ParryBuff:get(target, target).playSound()

            if limitBreak[pid] & 0x1 > 0 then
                DamageTarget(target, source, PARRY.dmg(pid) * 2., ATTACK_TYPE_NORMAL, MAGIC, PARRY.tag)
            else
                DamageTarget(target, source, PARRY.dmg(pid), ATTACK_TYPE_NORMAL, MAGIC, PARRY.tag)
            end
        end

        --dark savior metamorphosis
        amount = amount * (1. + metamorphosis[pid])

        --intense focus azazoth bow
        amount = amount * (1. + IntenseFocus[pid] * 0.01)

        --magnetic stance -(50-30) percent
        if GetUnitAbilityLevel(source, FourCC('Bmag')) > 0 then
            amount = amount * (0.45 + 0.05 * GetUnitAbilityLevel(source, FourCC('Bmag')))
        end

        --tidal wave
        if TidalWaveDebuff:has(nil, target) then
            amount = amount * (1. + TidalWaveDebuff:get(nil, target).percent)
        end

        --earth elemental storm
        if GetUnitAbilityLevel(target, FourCC('B04P')) > 0 then
            amount = amount * (1 + 0.04 * GetUnitAbilityLevel(target, FourCC('A04P')))
        end

        --provoke 30 percent
        if GetUnitAbilityLevel(source, FourCC('B02B')) > 0 and IsUnitType(target, UNIT_TYPE_HERO) == true then
            amount = amount * 0.75
        end

        --sand storm +20 percent
        if GetUnitAbilityLevel(target, FourCC('Xsan')) > 0 then
            amount = amount * 1.2
        end

        --item shield damage reduction
        if damageType == PHYSICAL then
            local offset = FourCC('Zs00') --starting id

            for i = 1, 100 do --100 different shields ('Zs99')
                if GetUnitAbilityLevel(target, offset) > 0 and GetRandomInt(0, 99) < GetAbilityField(target, offset, 0) then
                    amount = amount * (1. - GetAbilityField(target, offset, 1) * 0.01)
                end

                offset = offset + 1

                if ModuloInteger(i, 10) == 0 then
                    offset = offset + 0xF6 --246
                end
            end
        end

        --dungeon handling
        amount = DungeonOnDamage(amount, source, target, damageType)

        --main hero damage dealt
        if source == Hero[pid] then
            if damageType == PHYSICAL then
                amount = amount * HeroStats[HeroID[pid]].phys_damage
            end

            --instill fear 15 percent
            if GetUnitAbilityLevel(target, FourCC('B02U')) > 0 and target == InstillFear[pid] then
                amount = amount * 1.15
            end
        end

        --main hero damage taken
        if target == Hero[tpid] then
            --triggered invulnerability
            if HeroInvul[tpid] then
                amount = 0.00
            end

            --cancel force save
            if forceSaving[tpid] then
                forceSaving[tpid] = false
            end
        end

        --unit resistances
        amount = amount * Unit[target].dr

        if damageType == PHYSICAL then
            amount = amount * Unit[target].pr
        elseif damageType == MAGIC then
            amount = amount * Unit[target].mr
        end
    end

    --[[
    end of multipliers <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]]

    local damageCalc = CalcAfterReductions(amount, source, target, damageType)
    local damageText = RealToString(damageCalc)

    --threat system and boss handling
    if IsEnemy(tpid) then
        --call for help
        local ug = CreateGroup()
        MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), CALL_FOR_HELP_RANGE, Condition(FilterEnemy))

        for enemy in each(ug) do
            if GetUnitCurrentOrder(enemy) == 0 and enemy ~= target then --current idle
                UnitWakeUp(enemy)
                IssueTargetOrder(enemy, "smart", AcquireProximity(enemy, source, 800.))
            end
        end

        DestroyGroup(ug)

        --stop the reset timer on damage
        TimerList[pid]:stopAllTimers('aggr')

        local index = IsBoss(tuid)

        if index ~= -1 and IsUnitIllusion(target) == false then
            --boss spell casting
            BossSpellCasting(source, target)

            --invulnerable units don't gain threat
            if damageType == PHYSICAL and GetUnitAbilityLevel(source, FourCC('Avul')) == 0 then --only physical because magic procs are too inconsistent 

                local threat = Threat[target][source]

                if threat < THREAT_CAP then --prevent multiple occurences
                    threat = threat + IMaxBJ(1, 100 - R2I(UnitDistance(target, source) * 0.12)) --~40 as melee, ~250 at 700 range
                    Threat[target][source] = threat

                    --switch target
                    if threat >= THREAT_CAP and Threat[target].target ~= source and Threat[target]["switching"] == 0 then
                        ChangeAggro(target, source)
                    end
                end
            end

            --keep track of player percentage damage
            BossDamage[#BossTable * index + pid] = BossDamage[#BossTable * index + pid] + R2I(damageCalc * 0.001)
        end
    end

    --mystic mana shield
    if GetUnitAbilityLevel(target, FourCC('A062')) > 0 then
        dmg = GetUnitState(target, UNIT_STATE_MANA) - damageCalc / 3.

        if dmg >= 0. then
            UnitAddAbility(target, FourCC('A058'))
            ArcingTextTag.create(RealToString(damageCalc / 3.), target, 1, 2, 170, 50, 220, 0)
        else
            UnitRemoveAbility(target, FourCC('A058'))
        end

        SetUnitState(target, UNIT_STATE_MANA, math.max(0., dmg))

        amount = math.max(0., 0. - dmg * 3.)
    end

    --law of resonance
    local buff = LawOfResonanceBuff:get(nil, source)

    if buff and damageType == PHYSICAL then
        DamageTarget(buff.source, target, damageCalc * buff.multiplier, ATTACK_TYPE_NORMAL, PURE, LAWOFRESONANCE.tag)
    end

    --body of fire
    local ablev = GetUnitAbilityLevel(target, BODYOFFIRE.id)
    if ablev > 0 and damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) then
        local returnDmg = (damageCalc * 0.05 * ablev) + BODYOFFIRE.dmg(tpid)
        DamageTarget(target, source, returnDmg * BOOST[tpid], ATTACK_TYPE_NORMAL, MAGIC, BODYOFFIRE.tag)
    end

    --zero damage flag
    local zeroDamage = (damageCalc <= 0. or amount <= 0.00)

    --damage numbers
    local size = (crit > 0 and 2.5) or 2
    local colors = (crit > 0 and color_tag.crit) or color_tag[damageType]

    --shield mitigation
    if shield[target] then
        colors = {shield[target].r, shield[target].g, shield[target].b}
        amount = shield[target]:damage(damageCalc, source)
    end

    --dont show zero damage text if 0
    if zeroDamage == false then
        if source ~= target then
            --prevent non-crit physical attacks from appearing if they do not reach a 0.05% max health damage threshold 
            if damageType ~= PHYSICAL or crit > 0 or (damageCalc >= (BlzGetUnitMaxHP(target) * 0.0005) or pbagFlag) then
                ArcingTextTag.create(damageText, target, 1, size, colors[1], colors[2], colors[3], 0)
            end

            local damageHex = string.format("|cff\x2502X\x2502X\x2502X", colors[1], colors[2], colors[3])
            LogDamage(source, target, damageHex .. damageText .. "|r", false, tag)
        end

    end

    --set final event damage
    BlzSetEventDamage(amount)

    --pure damage on chaos armor
    if damageType == PURE and (BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE) == ARMOR_CHAOS or BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE) == ARMOR_CHAOS_BOSS) then
        BlzSetEventAttackType(ATTACK_TYPE_CHAOS)
    end

    --[[
    end of mitigations <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]]

    --dps punching bags
    if pbagFlag then
        if GetLocalPlayer() == Player(pid - 1) then
            BlzFrameSetVisible(dummyFrame, true)
        end
        local pt = TimerList[pid]:get('pbag')

        if pt then
            pt.dur = 10.
        else
            pt = TimerList[pid]:add()
            pt.dur = 10.
            pt.tag = 'pbag'
            pt.timer:callDelayed(1., DUMMY_HIDE_TEXT, pt)
        end

        if not TimerList[0]:has('pdmg') then
            pt = TimerList[0]:add()
            pt.tag = 'pdmg'
            pt.time = 0

            pt.timer:callDelayed(0.1, DUMMY_DPS_UPDATE, pt)
        end

        DUMMY_LAST = damageCalc

        if damageType == PHYSICAL then
            DUMMY_TOTAL_PHYSICAL = DUMMY_TOTAL_PHYSICAL + damageCalc
        elseif damageType == MAGIC then
            DUMMY_TOTAL_MAGIC = DUMMY_TOTAL_MAGIC + damageCalc
        end
        DUMMY_TOTAL = DUMMY_TOTAL + damageCalc

        PauseTimer(DUMMY_TIMER)
        TimerStart(DUMMY_TIMER, 7.5, false, DUMMY_RESET)
        BlzSetEventDamage(0.00)
        SetWidgetLife(target, BlzGetUnitMaxHP(target))
    end

    --paladin (town)
    if target == townpaladin then
        if damageCalc >= 100. then
            if GetRandomInt(0, 1) == 0 then
                local pt = TimerList[0]:get('pala', source)

                if pt then
                    pt.dur = 30.
                else
                    if not TimerList[0]:has('pala') then
                        PaladinEnrage(true)
                    end

                    pt = TimerList[0]:add()
                    pt.dur = 30.
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

    --player hero + summons
    if source == Hero[pid] or TableHas(SummonGroup, source) then
        if GetUnitLevel(target) >= 170 and IsUnitEnemy(target, GetOwningPlayer(source)) and UnitHasItemType(Hero[pid], FourCC('I04Q')) then --demon heart
            HeartBlood[pid] = HeartBlood[pid] + 1
            UpdateItemTooltips(pid)
        end
        if VampiricPotion:has(nil, Hero[pid]) then
            HP(Hero[pid], Hero[pid], damageCalc * 0.05, "Vampiric Potion")
            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\VampiricAuraTarget.mdx", Hero[pid], "chest"))
        end
    end

    --undying rage delayed damage
    buff = UndyingRageBuff:get(nil, target)

    if buff then
        buff:addRegen(-amount)
        BlzSetEventDamage(0.00)
    end

    --fatal damage
    if damageCalc >= GetWidgetLife(target) then
        --buddha mode
        if DEV_ENABLED then
            if BUDDHA_MODE[tpid] and target == Hero[tpid] then
                BlzSetEventDamage(0.00)
            end
        end

        --summons
        if TableHas(SummonGroup, target) then
            amount = 0.00
            SummonExpire(target)
        end

        --soul link
        buff = SoulLinkBuff:get(nil, target)

        if buff then
            BlzSetEventDamage(0.00)
            buff:remove()
        end

        --gaia armor
        if GetUnitAbilityLevel(target, FourCC('B005')) > 0 and gaiaArmorCD[tpid] == 1 then
            gaiaArmorCD[tpid] = 2
            BlzSetEventDamage(0.00)
            HP(target, target, BlzGetUnitMaxHP(target) * 0.2 * GetUnitAbilityLevel(target, GAIAARMOR.id), GAIAARMOR.tag)
            MP(target, BlzGetUnitMaxMana(target) * 0.2 * GetUnitAbilityLevel(target, GAIAARMOR.id))
            UnitRemoveAbility(target, FourCC('A033'))
            UnitRemoveAbility(target, FourCC('B005'))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", target, "origin"))

            local ug = CreateGroup()
            MakeGroupInRange(tpid, ug, GetUnitX(target), GetUnitY(target), 400., Condition(FilterEnemy))

            local pt = TimerList[tpid]:add(tpid)
            pt.dur = 35.
            pt.speed = 20.
            pt.ug = CreateGroup()

            for u in each(ug) do
                GroupAddUnit(pt.ug, u)
                Stun:add(target, u):duration(4.)
            end

            DestroyGroup(ug)

            TimerQueue:callDelayed(120., GaiaArmorCD, tpid)
            pt.timer:callDelayed(FPS_32, GaiaArmorPush, pt)
        end
    end

    --attack count based health
    if Unit[target].attackCount > 0 then
        Unit[target].attackCount = Unit[target].attackCount - 1
        BlzSetEventDamage(0.00)
        SetWidgetLife(target, GetWidgetLife(target) - 1)
    end

    return false
end

    TriggerAddCondition(ACQUIRE_TRIGGER, Filter(OnAcquire))

    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DAMAGING, OnDamage)
end, Debug.getLine())
