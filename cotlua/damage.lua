if Debug then Debug.beginFile 'Damage' end

OnInit.final("Damage", function(require)
    require 'Users'
    require 'Variables'
    require 'Helper'

    UNIT_TARGET         = 10000 ---@type integer 
    THREAT_CAP         = 4000 ---@type integer 
    BeforeArmor         = CreateTrigger() ---@type trigger 

    HeroInvul=__jarray(false) ---@type boolean[] 
    HeartBlood=__jarray(0) ---@type integer[] 
    BossDamage=__jarray(0) ---@type integer[] 
    ignoreflag=__jarray(0) ---@type integer[] 

    DUMMY_TIMER       = CreateTimer() ---@type timer 

    DUMMY_TOTAL_PHYSICAL      = 0. ---@type number 
    DUMMY_TOTAL_MAGIC      = 0. ---@type number 
    DUMMY_TOTAL      = 0. ---@type number 
    DUMMY_LAST      = 0. ---@type number 
    DUMMY_DPS      = 0. ---@type number 
    DUMMY_DPS_PEAK      = 0. ---@type number 
    DUMMY_STORAGE         = CircularArrayList.create() ---@type CircularArrayList 

    ATTACK_CHAOS         = 5 ---@type integer 
    ARMOR_CHAOS         = 6 ---@type integer 
    ARMOR_CHAOS_BOSS         = 7 ---@type integer 

    PHYSICAL            = DAMAGE_TYPE_NORMAL ---@type damagetype 
    MAGIC            = DAMAGE_TYPE_MAGIC ---@type damagetype 
    PURE            = DAMAGE_TYPE_DIVINE ---@type damagetype 

---@return boolean
function AcquireTarget()
    local target      = GetEventTargetUnit() ---@type unit 
    local source      = GetTriggerUnit() ---@type unit 

    if GetUnitTypeId(source) == DUMMY then
        BlzSetUnitWeaponBooleanField(source, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
    elseif GetPlayerController(GetOwningPlayer(source)) ~= MAP_CONTROL_USER then
        Threat[source][UNIT_TARGET] = AcquireProximity(source, target, 800.)
        TimerQueue:callDelayed(FPS_32, SwitchAggro, target)
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
    local armor      = BlzGetUnitArmor(target) ---@type number 
    local pid         = GetPlayerId(GetOwningPlayer(source)) + 1 ---@type integer 
    local newarmor      = armor ---@type number 

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
function CalcAfterReductions(dmg, source, target, TYPE) --after
    local armor      = BlzGetUnitArmor(target) ---@type number 
    local dtype         = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE) ---@type integer 
    local atype         = BlzGetUnitWeaponIntegerField(source, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0) ---@type integer 

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
    local u           = nil ---@type unit 
    local b           = nil ---@type Buff 

    --TODO force unknown damage to magic damage?
    if damageType ~= PHYSICAL and damageType ~= MAGIC and damageType ~= PURE then
        damageType = MAGIC
        BlzSetEventDamageType(MAGIC)
    end

    --[[
    dummy attack handling <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]]

    --arcanist arcane barrage
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A008')) > 0 then
        UnitRemoveAbility(source, FourCC('A008'))
        UnitDamageTarget(Hero[pid], target, ARCANEBARRAGE.dmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
    end

    --phoenix ranger searing arrow
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A069')) > 0 then
        UnitRemoveAbility(source, FourCC('A069'))
        DummyCastTarget(Player(pid - 1), target, FourCC('A092'), 1, GetUnitX(source), GetUnitY(source), "slow")
        UnitDamageTarget(Hero[pid], target, (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroAgi(Hero[pid], true)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
    end

    --electrocute lightning
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A09W')) > 0 then
        UnitRemoveAbility(source, FourCC('A09W'))
        UnitDamageTarget(Hero[pid], target, GetWidgetLife(target) * 0.005, true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
    end

    --medean lightning trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A01Y')) > 0 then
        UnitRemoveAbility(source, FourCC('A01Y'))
        UnitDamageTarget(Hero[pid], target, MEDEANLIGHTNING.dmg(pid, GetUnitAbilityLevel(Hero[pid], MEDEANLIGHTNING.id)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
    end

    --frozen orb icicle
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A09F')) > 0 then
        UnitDamageTarget(Hero[pid], target, GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * GetUnitAbilityLevel(Hero[pid], FROZENORB.id)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
    end

    --satan flame strike
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A0DN')) > 0 and IsUnitEnemy(target, pboss) then
        UnitDamageTarget(Boss[BOSS_SATAN], target, 10000., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
    end

    --instill fear trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A0AE')) > 0 then
        UnitRemoveAbility(source, FourCC('A0AE'))
        InstillFear[pid] = target
        TimerQueue:callDelayed(7., InstillFearExpire, pid)
    end

    --single shot trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A05J')) > 0 then
        UnitRemoveAbility(source, FourCC('A05J'))
    end

    --nerve gas trigger
    if tuid == DUMMY and GetUnitAbilityLevel(source, FourCC('A01X')) > 0 then
        UnitRemoveAbility(source, FourCC('A01X'))
        local ug = CreateGroup()

        MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), NERVEGAS.aoe(pid) * LBOOST[pid], Condition(FilterEnemy))
        local count = BlzGroupGetSize(ug)
        TimerQueue:callDelayed(5., RemoveUnit, source)
        TimerQueue:callDelayed(5., RemoveUnit, target)
        if count > 0 then
            local pt = TimerList[pid]:add()
            pt.dmg = NERVEGAS.dmg(pid) * BOOST[pid]
            pt.dur = NERVEGAS.dur * LBOOST[pid]
            pt.armor = pt.dur --keep track of initial duration
            pt.ug = CreateGroup()
            BlzGroupAddGroupFast(ug, pt.ug)
            for i = 0, count - 1 do
                NerveGasDebuff:add(Hero[pid], BlzGroupUnitAt(pt.ug, i)):duration(10.)
            end
            pt.timer:callDelayed(0.5, NerveGas, pt)
        end

        DestroyGroup(ug)
    end

    --frost blast trigger
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A04B')) > 0 then
        UnitRemoveAbility(source, FourCC('A04B'))
        amount = 0.00
        dmg = FROSTBLAST.dmg(pid) * BOOST[pid]

        local ug = CreateGroup()
        MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), FROSTBLAST.aoe * LBOOST[pid], Condition(FilterEnemy))

        if GetUnitAbilityLevel(Hero[pid], FourCC('B01I')) > 0 then
            UnitRemoveAbility(Hero[pid], FourCC('B01I'))
            dmg = dmg * 2
        end

        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX(target), GetUnitY(target)))

        u = FirstOfGroup(ug)
        while u do
            GroupRemoveUnit(ug, u)
            if u == target then
                Freeze:add(Hero[pid], target):duration(FROSTBLAST.dur * LBOOST[pid])
                UnitDamageTarget(Hero[pid], u, dmg * (GetUnitAbilityLevel(u, FourCC('B01G')) + 1.), true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                Freeze:add(Hero[pid], target):duration(FROSTBLAST.dur * 0.5 * LBOOST[pid])
                UnitDamageTarget(Hero[pid], u, dmg / (2. - GetUnitAbilityLevel(u, FourCC('B01G'))), true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end
            u = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    end

    --blizzard 
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A02O')) > 0 then
        amount = 0.00
        local pt = TimerList[pid]:get(BLIZZARD.id, source)
        dmg = pt.dmg
        if pt.infused then
            dmg = dmg * 1.3
        end
        UnitDamageTarget(Hero[pid], target, dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
    end

    --dark summoner devour
    if uid == DUMMY and GetUnitAbilityLevel(source, FourCC('A00W')) > 0 then
        if tuid == SUMMON_GOLEM then --meat golem
            BorrowedLife[pid * 10] = 0
            UnitAddBonus(meatgolem[pid], BONUS_HERO_STR, - R2I(GetHeroStr(meatgolem[pid], false) * 0.1 * golemDevourStacks[pid]))
            golemDevourStacks[pid] = golemDevourStacks[pid] + 1
            BlzSetHeroProperName(meatgolem[pid], "Meat Golem (" .. (golemDevourStacks[pid]) .. ")")
            FloatingTextUnit((golemDevourStacks[pid]), meatgolem[pid], 1, 60, 50, 13.5, 255, 255, 255, 0, true)
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
            FloatingTextUnit((destroyerDevourStacks[pid]), destroyer[pid], 1, 60, 50, 13.5, 255, 255, 255, 0, true)
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
    if uid == DUMMY or tuid == DUMMY then
        BlzSetEventDamage(0.00)
        BlzSetUnitWeaponBooleanField(source, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false) --so dummies are not hit twice

        return false
    end

    --[[
    end of dummy handling <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]]

    --[[
    physical damage events >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ]]

    if damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) then
        --player hero is hit
        if target == Hero[tpid] then --hitting a hero
            --evasion
            if TotalEvasion[tpid] > 0 and GetRandomInt(0, 99) < TotalEvasion[tpid] then
                FloatingTextUnit("Dodged!", target, 1, 90, 0, 9, 180, 180, 20, 0, true)
                amount = 0.00
            else
                --heart of demon prince damage taken
                if GetUnitLevel(source) >= 170 and IsUnitEnemy(source, GetOwningPlayer(target)) and HasItemType(target, FourCC('I04Q')) then
                    HeartBlood[tpid] = HeartBlood[tpid] + 1
                    UpdateItemTooltips(tpid)
                end
            end
        end

        --player hero attacks
        if IsUnitType(source, UNIT_TYPE_HERO) == true and ignoreflag[pid] ~= 1 then
            --item effects

            --onhit magic damage (king's clubba)
            if GetUnitAbilityLevel(source, FourCC('Abon')) > 0 then
                UnitDamageTarget(source, target, GetAbilityField(source, FourCC('Abon'), 0), true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end

            --assassin blade spin count
            if uid == HERO_ASSASSIN then
                BladeSpinCount[pid] = BladeSpinCount[pid] + 1
            end

            --vampire blood bank
            if uid == HERO_VAMPIRE then
                BloodBank[pid] = math.min(BloodBank[pid] + BLOODBANK.gain(pid), BLOODBANK.max(pid))

                --vampire blood lord
                if BloodLordBuff:has(source, source) then
                    UnitDamageTarget(source, target, BLOODLORD.dmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
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

                        u = FirstOfGroup(ug)
                        while u do
                            GroupRemoveUnit(ug, u)
                            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", u, "chest"))
                            dmg = dmg + CalcAfterReductions(BLOODCLEAVE.dmg(pid) * BOOST[pid], source, target, PHYSICAL)
                            UnitDamageTarget(source, u, BLOODCLEAVE.dmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                            u = FirstOfGroup(ug)
                        end

                        DestroyGroup(ug)

                        ignoreflag[pid] = 0

                        --leech health
                        HP(source, dmg * double)
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
                        UnitDamageTarget(source, target, BACKSTAB.dmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end
                end

                --instant death
                if GetUnitAbilityLevel(source, INSTANTDEATH.id) > 0 then
                    if HiddenGuise[pid] then
                        HiddenGuise[pid] = false
                    end

                    crit = crit + INSTANTDEATH.crit(pid, angle, target)
                end
            end

            --phoenix ranger fiery arrows / flaming bow
            if uid == HERO_PHOENIX_RANGER then
                if GetUnitAbilityLevel(source,FourCC('A0IB')) > 0 then
                    local ablev = GetUnitAbilityLevel(source, FourCC('A0IB'))
                    if GetRandomInt(0,99) < ablev * 2 * LBOOST[pid] then
                        UnitDamageTarget(source, target, (((UnitGetBonus(source, BONUS_DAMAGE) + GetHeroAgi(source, true)) * .3 + GetHeroAgi(source, true) * ablev)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
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

                b = FlamingBowBuff:get(nil, source)

                if b then
                    b:onHit()
                end
            end

            --holy bash (savior)
            if GetUnitAbilityLevel(source, HOLYBASH.id) > 0 and uid == HERO_SAVIOR then
                saviorBashCount[pid] = saviorBashCount[pid] + 1
                if saviorBashCount[pid] > 10 then
                    UnitDamageTarget(source, target, HOLYBASH.dmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    saviorBashCount[pid] = 0

                    local pt = TimerList[pid]:get(source, nil, LIGHTSEAL.id)

                    --light seal augment
                    if pt then
                        MakeGroupInRange(pid, pt.ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

                        u = FirstOfGroup(pt.ug)
                        while u do
                            GroupRemoveUnit(pt.ug, u)
                            if u ~= target then
                                StunUnit(pid, u, 2.)
                                UnitDamageTarget(source, u, HOLYBASH.dmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                            end
                            u = FirstOfGroup(pt.ug)
                        end
                    end

                    StunUnit(pid, target, 2.)

                    --aoe heal
                    local ug = CreateGroup()
                    MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), HOLYBASH.aoe * LBOOST[pid], Condition(FilterAlly))

                    u = FirstOfGroup(ug)
                    while u do
                        GroupRemoveUnit(ug, u)
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", u, "origin")) --change effect
                        HP(u, HOLYBASH.heal(pid) * BOOST[pid])
                        u = FirstOfGroup(ug)
                    end

                    DestroyGroup(ug)
                end
            end

            --bard encore (song of war)
            b = SongOfWarEncoreBuff:get(nil, source)

            if b then
                UnitDamageTarget(b.source, target, b.dmg * BOOST[GetPlayerId(GetOwningPlayer(b.source)) + 1], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

                b:onHit()
            end

            --demon hound critical strike (dark summoner)
            if uid == SUMMON_HOUND then
                if GetRandomInt(0, 99) < 25 then
                    if destroyerSacrificeFlag[pid] then
                        --aoe attack
                        local ug = CreateGroup()
                        MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 400. * LBOOST[pid], Condition(FilterEnemy))

                        u = FirstOfGroup(ug)
                        while u do
                            GroupRemoveUnit(ug, u)
                            UnitDamageTarget(source, u, GetHeroInt(source, true) * 1.25 * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                            u = FirstOfGroup(ug)
                        end

                        DestroyGroup(ug)
                    else
                        UnitDamageTarget(source, target, GetHeroInt(source, true) * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
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
                    UnitDamageTarget(source, target, GetHeroInt(source, true) * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                end
            end

            --dark savior dark blade
            if GetUnitAbilityLevel(source, FourCC('B01A')) > 0 then
                UnitDamageTarget(source, target, GetHeroInt(source, true) * (0.6 + GetUnitAbilityLevel(source, FourCC('AEim')) * 0.1) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                if GetUnitManaPercent(source) >= 0.5 then
                    if metamorphosis[pid] > 0 then
                        SetUnitManaPercentBJ(source, (GetUnitManaPercent(source) + 0.5))
                    else
                        SetUnitManaPercentBJ(source, (GetUnitManaPercent(source) - 1.00))
                    end
                else
                    IssueImmediateOrder(source, "unimmolation")
                end
            end

            --oblivion guard infernal strike / magnetic strike
            if InfernalStrikeBuff:has(source, source) or MagneticStrikeBuff:has(source, source) then
                BodyOfFireCharges[pid] = BodyOfFireCharges[pid] - 1

                if GetLocalPlayer() == Player(pid - 1) then
                    BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\PASBodyOfFire" .. (BodyOfFireCharges[pid]) .. ".blp")
                end

                InfernalStrikeBuff:get(source, source):dispel()
                MagneticStrikeBuff:get(source, source):dispel()

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
                    amount = 0.00

                    ignoreflag[pid] = 1
                    local ablev = GetUnitAbilityLevel(source, INFERNALSTRIKE.id)

                    local ug = CreateGroup()
                    MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * LBOOST[pid], Condition(FilterEnemy))
                    local count = BlzGroupGetSize(ug)

                    u = FirstOfGroup(ug)
                    while u do
                        GroupRemoveUnit(ug, u)
                        if IsUnitType(u, UNIT_TYPE_HERO) then
                            count = count + 4
                        end
                        local dtype = BlzGetUnitIntegerField(target, UNIT_IF_DEFENSE_TYPE)

                        if dtype == 7 then --chaos boss
                            UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * 7.5 * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        elseif dtype == 6 then
                            UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * 15. * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        elseif dtype == 1 then --prechaos boss
                            UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * 0.5 * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        elseif dtype == 0 then
                            UnitDamageTarget(source, u, ((GetHeroStr(source, true) * ablev) + GetWidgetLife(u) * (0.25 + 0.05 * ablev)) * LBOOST[pid], true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
                        end

                        u = FirstOfGroup(ug)
                    end

                    DestroyGroup(ug)

                    ignoreflag[pid] = 0

                    DestroyEffect(AddSpecialEffect("war3mapImported\\Lava_Slam.mdx", GetUnitX(target), GetUnitY(target)))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))

                    --6% max heal
                    HP(source, BlzGetUnitMaxHP(source) * 0.01 * IMinBJ(6, i))
                elseif MagneticStrikeBuff:has(source, source) then
                    local ug = CreateGroup()
                    MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), 250. * LBOOST[pid], Condition(FilterEnemy))

                    u = FirstOfGroup(ug)
                    while u do
                        GroupRemoveUnit(ug, u)
                        MagneticStrikeDebuff:add(source, target):duration(10.)
                        u = FirstOfGroup(ug)
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

            local pt = TimerList[pid]:get(Hero[pid], nil, ARCANESHIFT.id)

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
                        if GetRandomInt(0, 99) < itm:calcStat(ITEM_CRIT_CHANCE, 0) then
                            crit = crit + itm:calcStat(ITEM_CRIT_DAMAGE, 0)
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
            UnitDamageTarget(source, target, BlzGetUnitMaxHP(target) * 0.0025, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
        else
            UnitDamageTarget(source, target, BlzGetUnitMaxHP(target) * 0.005, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
        end
    end

    --death knight decay
    if amount > 0.00 and GetUnitAbilityLevel(source, FourCC('A08N')) > 0 and damageType == PHYSICAL then
        if GetRandomInt(0, 99) < 20 then
            UnitDamageTarget(source, target, 2500., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", target, "origin"))
        end
    end

    --spell reflect (hate) (before reductions)
    if damageType == MAGIC and GetUnitAbilityLevel(target, FourCC('A00S')) > 0 and UnitAlive(source) and BlzGetUnitAbilityCooldownRemaining(target, FourCC('A00S')) <= 0 and amount > 10000. then
        local angle = Atan2(GetUnitY(source) - GetUnitY(target), GetUnitX(source) - GetUnitX(target))
        bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\BoneArmorCasterTC.mdx", GetUnitX(target) + 75. * Cos(angle), GetUnitY(target) + 75. * Sin(angle))

        BlzSetSpecialEffectZ(bj_lastCreatedEffect, BlzGetUnitZ(target) + 80.)
        BlzSetSpecialEffectColorByPlayer(bj_lastCreatedEffect, Player(0))
        BlzSetSpecialEffectYaw(bj_lastCreatedEffect, angle)
        BlzSetSpecialEffectScale(bj_lastCreatedEffect, 0.9)
        BlzSetSpecialEffectTimeScale(bj_lastCreatedEffect, 3.)

        DestroyEffect(bj_lastCreatedEffect)

        BlzStartUnitAbilityCooldown(target, FourCC('A00S'), 5.)
        --call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl", target, "origin"))
        UnitDamageTarget(target, source, math.min(amount, 2500), true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

        amount = math.max(0, amount - 20000)
    end

    --[[
    multipliers >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ]]

    --prevent self damage from being augmented
    if source ~= target then
        --magic damage events >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        if damageType == MAGIC then
            --creeps -30%
            if GetUnitAbilityLevel(target, FourCC('A04A')) > 0 then
                amount = amount * 0.7
            end

            --protected existence -33.33%
            if ProtectedExistenceBuff:has(nil, target) then
                amount = amount * 0.66
            end

            --astral shield -66.66%
            if AstralShieldBuff:has(nil, target) then
                amount = amount * 0.33
            end

            --hellfire shield (bosses) -50%
            if IsEnemy(tpid) and HasItemType(target, FourCC('I03Y')) then
                amount = amount * 0.5
            end

            --meat golem magic resist -(25-30)%
            if tuid == SUMMON_GOLEM and golemDevourStacks[tpid] > 0 then
                amount = amount * (0.75 - golemDevourStacks[tpid] * 0.1)
            end

            --hardmode multiplier +100%
            if IsEnemy(pid) and HardMode > 0 then
                amount = amount * 2.
            end

            --thunderblade overload
            if OverloadBuff:has(source, source) then
                amount = amount * OVERLOAD.mult(pid)
            end

            --warrior intimidating shout limit break -40%
            if IntimidatingShoutDebuff:has(nil, source) then
                if BlzBitAnd(limitBreak[IntimidatingShoutDebuff(IntimidatingShoutDebuff:get(nil, source)).pid], 0x4) > 0 then
                    amount = amount * 0.6
                end
            end

            --oblivion guard magnetic strike +25%
            if MagneticStrikeDebuff:has(nil, target) then
                amount = amount * 1.25
            end
        end

        --any damage type >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

        --warrior parry
        if ParryBuff:has(target, target) and amount > 0. then
            amount = 0.00
            ParryBuff:get(target, target).playSound()

            if BlzBitAnd(limitBreak[pid], 0x1) > 0 then
                UnitDamageTarget(target, source, PARRY.dmg(pid) * 2., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            else
                UnitDamageTarget(target, source, PARRY.dmg(pid), true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end
        end

        --dark savior metamorphosis
        amount = amount * (1. + metamorphosis[pid])

        --intense focus azazoth bow
        amount = amount * (1. + IntenseFocus[pid] * 0.01)

        --magnetic stance -(50-30)%
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

        --provoke 30%
        if GetUnitAbilityLevel(source, FourCC('B02B')) > 0 and IsUnitType(target, UNIT_TYPE_HERO) == true then
            amount = amount * 0.75
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

        --threat system and boss handling
        if IsEnemy(tpid) then
            --call for help
            local ug = CreateGroup()
            MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), CALL_FOR_HELP_RANGE, Condition(FilterEnemy))

            u = FirstOfGroup(ug)
            while u do
                GroupRemoveUnit(ug, u)
                if GetUnitCurrentOrder(u) == 0 and u ~= target then --current idle
                    UnitWakeUp(u)
                    IssueTargetOrder(u, "smart", AcquireProximity(u, source, 800.))
                end
                u = FirstOfGroup(ug)
            end

            DestroyGroup(ug)

            --if you attack stop the reset timer
            TimerList[pid]:stopAllTimers('aggr')

            if IsBoss(DropTable:getType(tuid)) ~= -1 then
                --boss spell casting
                if (GetWidgetLife(target) - CalcAfterReductions(amount, source, target, damageType)) >= MIN_LIFE then
                    BossSpellCasting(source, target)
                end

                --invulnerable units don't gain threat
                if damageType == PHYSICAL and GetUnitAbilityLevel(source, FourCC('Avul')) == 0 then --only physical because magic procs are too inconsistent 

                    local threat = Threat[target][source]

                    if threat < THREAT_CAP then --prevent multiple occurences
                        threat = threat + IMaxBJ(1, 100 - R2I(UnitDistance(target, source) * 0.12)) --~40 as melee, ~250 at 700 range
                        Threat[target][source] = threat

                        if threat >= THREAT_CAP then
                            if Threat[target][UNIT_TARGET] == source then
                                Threat[target] = __jarray(0)
                            else --switch target
                                local dummy = GetDummy(GetUnitX(target), GetUnitY(target), 0, 0, 1.5)
                                BlzSetUnitSkin(dummy, FourCC('h00N'))
                                if GetLocalPlayer() == Player(pid - 1) then
                                    BlzSetUnitSkin(dummy, FourCC('h01O'))
                                end
                                SetUnitScale(dummy, 2.5, 2.5, 2.5)
                                SetUnitFlyHeight(dummy, 250.00, 0.)
                                SetUnitAnimation(dummy, "birth")
                                TimerQueue:callDelayed(1.5, SwitchAggro, target)
                            end
                            Threat[target][UNIT_TARGET] = source
                        end
                    end
                end

                local index = IsBoss(tuid)

                --keep track of player percentage damage
                BossDamage[BOSS_TOTAL * index + pid] = BossDamage[BOSS_TOTAL * index + pid] + R2I(CalcAfterReductions(amount, source, target, damageType) * 0.001)
            end
        end

        --main hero damage dealt
        if source == Hero[pid] then
            if DealtDmgBase[pid] > 0 and damageType == PHYSICAL then
                amount = amount * DealtDmgBase[pid]
            end

            --instill fear 15%
            if GetUnitAbilityLevel(target, FourCC('B02U')) > 0 and target == InstillFear[pid] then
                amount = amount * 1.15
            end
        end

        --main hero damage taken
        if target == Hero[tpid] then
            --triggered invulnerability
            if HeroInvul[tpid] then
                amount = 0.00
            elseif damageType == PHYSICAL then
                amount = amount * PhysicalTaken[tpid]
            elseif damageType == MAGIC then
                amount = amount * MagicTaken[tpid]
            end

            --cancel force save
            if forceSaving[tpid] then
                forceSaving[tpid] = false
            end
        --damage resist modifiers for non main heroes
        else
            --sand storm +20%
            if GetUnitAbilityLevel(target, FourCC('B002')) > 0 then
                amount = amount * 1.2
            end
        end
    end

    --[[
    end of multipliers <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]]

    --/mystic mana shield
    if GetUnitAbilityLevel(target, FourCC('A062')) > 0 then
        dmg = GetUnitState(target, UNIT_STATE_MANA) - CalcAfterReductions(amount, source, target, damageType) / 3.

        if dmg >= 0. then
            UnitAddAbility(target, FourCC('A058'))
            ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType) / 3.), target, 1, 2, 170, 50, 220, 0)
        else
            UnitRemoveAbility(target, FourCC('A058'))
        end

        SetUnitState(target, UNIT_STATE_MANA, math.max(0., dmg))

        amount = math.max(0., 0. - dmg * 3.)
    end

    --law of resonance
    b = LawOfResonanceBuff:get(nil, source)

    if b and damageType == PHYSICAL then
        UnitDamageTarget(b.source, target, CalcAfterReductions(amount, source, target, damageType) * b.multiplier, true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
    end

    --body of fire
    if target == Hero[tpid] and damageType == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) and GetUnitAbilityLevel(target, BODYOFFIRE.id) > 0 then
        dmg = (CalcAfterReductions(amount, target, source, damageType) * 0.05 * GetUnitAbilityLevel(target, BODYOFFIRE.id) + BODYOFFIRE.dmg(pid))
        UnitDamageTarget(target, source, dmg * BOOST[tpid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
    end

    --zero damage flag
    local zeroDamage = false

    if CalcAfterReductions(amount, source, target, damageType) <= 0. or amount <= 0.00 then
        zeroDamage = true
    end

    --damage numbers
    if not zeroDamage and source ~= target then
        if shield[target] then
            ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 170, 50, 220, 0)
        elseif damageType == MAGIC then
            ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 100, 100, 255, 0)
        elseif damageType == PURE then
            ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 255, 255, 100, 0)
        elseif damageType == PHYSICAL then
            if crit > 0 then
                ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2.5, 255, 120, 20, 0)
            else
                if CalcAfterReductions(amount, source, target, damageType) >= BlzGetUnitMaxHP(target) * 0.0005 or (target == PunchingBag[1] or target == PunchingBag[2]) then
                    ArcingTextTag.create(RealToString(CalcAfterReductions(amount, source, target, damageType)), target, 1, 2, 200, 50, 50, 0)
                end
            end
        end
    end

    --shield mitigation
    if shield[target] then
        amount = shield[target]:damage(CalcAfterReductions(amount, source, target, damageType), source)
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

    --dps dummy
    if target == PunchingBag[1] or target == PunchingBag[2] then
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

        DUMMY_LAST = CalcAfterReductions(amount, source, target, damageType)

        if damageType == PHYSICAL then
            DUMMY_TOTAL_PHYSICAL = DUMMY_TOTAL_PHYSICAL + CalcAfterReductions(amount, source, target, damageType)
        elseif damageType == MAGIC then
            DUMMY_TOTAL_MAGIC = DUMMY_TOTAL_MAGIC + CalcAfterReductions(amount, source, target, damageType)
        end
        DUMMY_TOTAL = DUMMY_TOTAL + CalcAfterReductions(amount, source, target, damageType)

        PauseTimer(DUMMY_TIMER)
        TimerStart(DUMMY_TIMER, 7.5, false, DUMMY_RESET)
        BlzSetEventDamage(0.00)
        SetWidgetLife(target, BlzGetUnitMaxHP(target))
    end

    --paladin (town)
    if target == gg_unit_H01T_0259 then
        if CalcAfterReductions(amount, source, target, damageType) >= 100. then
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
    if source == Hero[pid] or IsUnitInGroup(source, SummonGroup) then
        if GetUnitLevel(target) >= 170 and IsUnitEnemy(target, GetOwningPlayer(source)) and HasItemType(Hero[pid], FourCC('I04Q')) then --demon heart
            HeartBlood[pid] = HeartBlood[pid] + 1
            UpdateItemTooltips(pid)
        end
        if VampiricPotion:has(nil, Hero[pid]) then
            HP(Hero[pid], CalcAfterReductions(amount, source, target, damageType) * 0.05)
            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\VampiricAuraTarget.mdx", Hero[pid], "chest"))
        end
    end

    --undying rage delayed damage
    b = UndyingRageBuff:get(nil, target)

    if b then
        b:addRegen(-amount)
        BlzSetEventDamage(0.00)
    end

    --fatal damage
    if CalcAfterReductions(amount, source, target, damageType) >= GetWidgetLife(target) then
        --buddha mode
        if LIBRARY_dev then
            if BUDDHA_MODE[tpid] and target == Hero[tpid] then
                BlzSetEventDamage(0.00)
            end
        end

        --summons
        if IsUnitInGroup(target, SummonGroup) then
            amount = 0.00
            SummonExpire(target)
        end

        --soul link
        b = SoulLinkBuff:get(nil, target)

        if b then
            BlzSetEventDamage(0.00)
            b:dispel()
        end

        --gaia armor
        if GetUnitAbilityLevel(target, FourCC('B005')) > 0 and aoteCD[tpid] then
            aoteCD[tpid] = false
            BlzSetEventDamage(0.00)
            HP(target, BlzGetUnitMaxHP(target) * 0.2 * GetUnitAbilityLevel(target, GAIAARMOR.id))
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

            u = FirstOfGroup(ug)
            while u do
                GroupRemoveUnit(ug, u)
                GroupAddUnit(pt.ug, u)
                Stun:add(target, u):duration(4.)
                u = FirstOfGroup(ug)
            end

            DestroyGroup(ug)

            TimerQueue:callDelayed(120., GaiaArmorCD, tpid)
            TimerQueue:callDelayed(FPS_32, GaiaArmorPush, pt)
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

    local U = User.first ---@type User 

    TriggerAddCondition(ACQUIRE_TRIGGER, Filter(AcquireTarget))

    while U do
        TriggerRegisterPlayerUnitEvent(BeforeArmor, U.player, EVENT_PLAYER_UNIT_DAMAGING, nil)
        U = U.next
    end

    TriggerRegisterPlayerUnitEvent(BeforeArmor, Player(PLAYER_TOWN), EVENT_PLAYER_UNIT_DAMAGING, nil)
    TriggerRegisterPlayerUnitEvent(BeforeArmor, pboss, EVENT_PLAYER_UNIT_DAMAGING, nil)
    TriggerRegisterPlayerUnitEvent(BeforeArmor, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_DAMAGING, nil)
    TriggerRegisterPlayerUnitEvent(BeforeArmor, pfoe, EVENT_PLAYER_UNIT_DAMAGING, nil)

    --before reductions
    TriggerAddCondition(BeforeArmor, Filter(OnDamage))

end)

if Debug then Debug.endFile() end
