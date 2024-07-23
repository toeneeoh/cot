--[[
    herospells.lua

    Defines all spells used by player characters
]]

OnInit.final("HeroSpells", function(Require)
    Require("Spells")

    DMG_NUMBERS             = __jarray(0) ---@type integer[] 
    ResurrectionRevival     = __jarray(0) ---@type integer[] 
    IntenseFocus            = __jarray(0) ---@type integer[] 
    masterElement           = __jarray(0) ---@type integer[] 
    lastCast                = __jarray(0) ---@type integer[] 
    limitBreak              = __jarray(0) ---@type integer[] 
    limitBreakPoints        = __jarray(0) ---@type integer[] 

    destroyer   = {} ---@type unit[] 
    meatgolem   = {} ---@type unit[] 
    hounds      = {} ---@type unit[] 

    songeffect      = {} ---@type effect[] 
    InstillFear     = {} ---@type unit[] 

    --savior

    ---@class LIGHTSEAL : Spell
    ---@field dur number
    ---@field aoe number
    LIGHTSEAL = Spell.define('A07C')
    do
        local thistype = LIGHTSEAL
        thistype.aoe = 450.
        thistype.values = {
            dur = 12.,
        }

        ---@type fun(pt: PlayerTimer)
        function thistype.onExpire(pt)
            pt:destroy()
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            pt.dur = self.dur * LBOOST[self.pid]
            pt.x = self.targetX
            pt.y = self.targetY
            pt.source = self.caster
            pt.target = Dummy.create(pt.x, pt.y, 0, 0, pt.dur).unit
            pt.aoe = self.aoe
            pt.tag = self.id
            pt.ug = CreateGroup()

            BlzSetUnitSkin(pt.target, FourCC('h046'))
            UnitDisableAbility(pt.target, FourCC('Amov'), true)
            SetUnitScale(pt.target, 6.1, 6.1, 6.1)
            BlzSetUnitFacingEx(pt.target, 270)
            SetUnitVertexColor(pt.target, 255, 255, 200, 200)
            SetUnitAnimation(pt.target, "birth")
            SetUnitTimeScale(pt.target, 0.9)
            DelayAnimation(self.pid, pt.target, 1., 0, 1., false)

            pt.timer:callDelayed(pt.dur, thistype.onExpire, pt)
        end
    end

    ---@class DIVINEJUDGEMENT : Spell
    ---@field dmg function
    DIVINEJUDGEMENT = Spell.define('A038')
    do
        local thistype = DIVINEJUDGEMENT
        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.2 + 0.3 * ablev) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) + BlzGetUnitBaseDamage(Hero[pid], 0)) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 40.

            if pt.dur > 0. then
                local ug = CreateGroup()
                local x = GetUnitX(pt.target)
                local y = GetUnitY(pt.target)

                MakeGroupInRange(pt.pid, ug, x, y, 150., Condition(FilterEnemy))
                SetUnitXBounded(pt.target, x + 40. * Cos(pt.angle))
                SetUnitYBounded(pt.target, y + 40. * Sin(pt.angle))

                local pt2 = TimerList[pt.pid]:get(LIGHTSEAL.id, pt.source)

                if pt2 ~= 0 then
                    LightSealBuff:add(pt.source, pt.source):duration(20.)
                end

                for target in each(ug) do
                    if IsUnitInGroup(target, pt.ug) == false then
                        GroupAddUnit(pt.ug, target)
                        if pt2 and IsUnitInRangeXY(target, pt2.x, pt2.y, 450.) then
                            if IsUnitType(target, UNIT_TYPE_HERO) == true then
                                LightSealBuff:get(pt.source, pt.source):addStack(5)
                            else
                                LightSealBuff:get(pt.source, pt.source):addStack(1)
                            end
                        end
                        DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end
                end
                pt.timer:callDelayed(FPS_32, periodic, pt)

                DestroyGroup(ug)
            else
                SetUnitTimeScale(pt.target, 1.5)
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.angle = self.angle
            pt.target = Dummy.create(self.x, self.y, 0, 0).unit
            pt.source = self.caster
            pt.dur = 1000.
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.ug = CreateGroup()

            BlzSetUnitSkin(pt.target, FourCC('h00X'))
            BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)
            SetUnitScale(pt.target, 1.1, 1.1, 0.8)
            SetUnitFlyHeight(pt.target, 25.00, 0.)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class SAVIORSGUIDANCE : Spell
    ---@field shield function
    ---@field dur function
    SAVIORSGUIDANCE = Spell.define('A0KU')
    do
        local thistype = SAVIORSGUIDANCE
        thistype.values = {
            shield = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * (2.25 + .25 * ablev) end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 9. + ablev end,
        }

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(LIGHTSEAL.id, self.caster)

            --light seal augment
            if pt then
                MakeGroupInRange(self.pid, pt.ug, pt.x, pt.y, pt.aoe, Condition(FilterAllyHero))

                if self.caster ~= self.target and UnitAlive(self.target) then
                    GroupAddUnit(pt.ug, self.target)
                end

                GroupAddUnit(pt.ug, self.caster)

                for target in each(pt.ug) do
                    shield.add(target, self.shield * BOOST[self.pid], self.dur)
                end
            --normal cast
            else
                if self.caster ~= self.target and self.target ~= nil then
                    shield.add(self.target, self.shield * BOOST[self.pid], self.dur)
                end

                shield.add(self.caster, self.shield * BOOST[self.pid], self.dur)
            end


        end
    end

    ---@class HOLYBASH : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field heal function
    ---@field count number[]
    HOLYBASH = Spell.define('A0GG')
    do
        local thistype = HOLYBASH
        thistype.stundur = 2.
        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev * (GetHeroStr(Hero[pid], true) + (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * .4) end,
            aoe = 600.,
            heal = function(pid) return 25 + 0.5 * GetHeroStr(Hero[pid], true) end,
        }
        thistype.count = __jarray(0)

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1

            thistype.count[pid] = thistype.count[pid] + 1
            if thistype.count[pid] > 10 then
                local dmg = thistype.values.dmg(pid) * BOOST[pid]
                local heal = thistype.values.heal(pid) * BOOST[pid]
                DamageTarget(source, target, dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                thistype.count[pid] = 0

                local pt = TimerList[pid]:get(LIGHTSEAL.id, source)

                --light seal augment
                if pt then
                    MakeGroupInRange(pid, pt.ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

                    for u in each(pt.ug) do
                        if u ~= target then
                            StunUnit(pid, u, thistype.stundur)
                            DamageTarget(source, u, dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                        end
                    end
                end

                StunUnit(pid, target, thistype.stundur)

                --aoe heal
                local ug = CreateGroup()
                MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), thistype.aoe * LBOOST[pid], Condition(FilterAlly))

                for u in each(ug) do
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", u, "origin")) --change effect
                    HP(source, u, heal, thistype.tag)
                end

                DestroyGroup(ug)
            end
        end

        function thistype.onLearn(source, ablev, pid)
            EVENT_ON_HIT:register_unit_action(source, onHit)
        end

    end

    ---@class THUNDERCLAP : Spell
    ---@field dmg function
    ---@field aoe function
    THUNDERCLAP = Spell.define("A0AT")
    do
        local thistype = THUNDERCLAP

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.25 * (ablev + 1) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) + BlzGetUnitBaseDamage(Hero[pid], 0)) end,
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (200. + 50 * ablev) end,
        }

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(LIGHTSEAL.id, self.caster)
            local ug = CreateGroup()
            local aoe, x, y = 0., 0., 0.

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            if pt then
                LightSealBuff:add(self.caster, self.caster):duration(20.)
                x = pt.x
                y = pt.y
                aoe = pt.aoe
                GroupEnumUnitsInRangeEx(self.pid, ug, x, y, aoe, Condition(FilterEnemy))
            end

            for target in each(ug) do
                SaviorThunderClap:add(self.caster, target):duration(5.)
                if IsUnitInRangeXY(target, x, y, aoe) then
                    LightSealBuff:get(self.caster, self.caster):addStack((IsUnitType(target, UNIT_TYPE_HERO) == true and 5) or 1)
                end
                DamageTarget(self.caster, target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end

            Taunt(self.caster, self.pid, 800., true, 2000, 2000)

            DestroyGroup(ug)
        end
    end

    ---@class RIGHTEOUSMIGHT : Spell
    ---@field attack function
    ---@field armor function
    ---@field heal function
    ---@field dmg function
    ---@field dur function
    RIGHTEOUSMIGHT = Spell.define("A08R")
    do
        local thistype = RIGHTEOUSMIGHT

        thistype.values = {
            attack = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (.2 + .2 * ablev) end,
            armor = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return BlzGetUnitArmor(Hero[pid]) * (.4 + (.2 * ablev)) + 0.5 end,
            heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return BlzGetUnitMaxHP(Hero[pid]) * (0.10 + 0.05 * ablev) end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev + 1) * 2. * GetHeroStr(Hero[pid],true) end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev + 1) * 5. end,
        }

        function thistype:onCast()
            local b = RighteousMightBuff:create(self.caster, self.caster)
            local ug = CreateGroup()
            local angle = 0. ---@type number 

            b.dmg = self.attack
            b.armor = self.armor
            b = b:check(self.caster, self.caster)
            b:duration(self.dur * LBOOST[self.pid])

            HP(self.caster, self.caster, self.heal * LBOOST[self.pid], thistype.tag)

            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\HolyAwakening.mdx", self.caster, "origin"))

            for i = 1, 24 do
                angle = 2 * bj_PI * i / 24.
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", self.x + 500 * Cos(angle), self.y + 500 * Sin(angle)))
            end

            MakeGroupInRange(self.pid, ug, self.x, self.y, 500 * LBOOST[self.pid], Condition(FilterEnemy))

            for target in each(ug) do
                DamageTarget(self.caster, target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end

            DestroyGroup(ug)
        end
    end

    --elite marksman

    ---@class SNIPERSTANCE : Spell
    ---@field enabled boolean[]
    SNIPERSTANCE = Spell.define("A049")
    do
        local thistype = SNIPERSTANCE
        thistype.enabled = {}

        ---@type fun(self: SNIPERSTANCE)
        local function delay(self)
            UnitRemoveAbility(self.caster, FourCC('Avul'))
            UnitRemoveAbility(self.caster, FourCC('A03C'))
            UnitAddAbility(self.caster, FourCC('A03C'))

            local u = Unit[self.caster]
            u.movespeed = (thistype.enabled[self.pid] and 100) or u.ms_flat * u.ms_percent
            u.cc_percent = (thistype.enabled[self.pid] and u.cc_percent + 1.) or u.cc_percent - 1.
            u.cd_percent = (thistype.enabled[self.pid] and u.cd_percent + 1.) or u.cd_percent - 1.
        end

        function thistype:onCast()
            local cooldown = 3.
            local s = "Disable"

            if thistype.enabled[self.pid] then
                cooldown = 6.
                s = "Enable"
            end

            for i = 0, 9 do
                BlzSetUnitAbilityCooldown(self.caster, TRIROCKET.id, i, cooldown)
                BlzSetAbilityStringLevelField(BlzGetUnitAbility(self.caster, thistype.id), ABILITY_SLF_TOOLTIP_NORMAL, i, s .. " Sniper Stance - [|cffffcc00D|r]")
            end

            thistype.enabled[self.pid] = not thistype.enabled[self.pid]

            UnitAddAbility(self.caster, FourCC('Avul'))
            TimerQueue:callDelayed(FPS_32, delay, self)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Defend\\DefendCaster.mdl", self.caster, "origin"))
        end
    end

    ---@class TRIROCKET : Spell
    ---@field dmg function
    ---@field cooldown function
    TRIROCKET = Spell.define("A06I")
    do
        local thistype = TRIROCKET

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev * GetHeroAgi(Hero[pid], true) + (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * ablev * .1) end,
            cooldown = function(pid) return SNIPERSTANCE.enabled[pid] and 3. or 6. end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 50.

            if pt.dur > 0. then
                local x = GetUnitX(Hero[pt.pid]) + 50. * Cos(bj_DEGTORAD * pt.angle)
                local y = GetUnitY(Hero[pt.pid]) + 50. * Sin(bj_DEGTORAD * pt.angle)

                if IsTerrainWalkable(x, y) then
                    SetUnitXBounded(Hero[pt.pid], x)
                    SetUnitYBounded(Hero[pt.pid], y)
                    pt.timer:callDelayed(FPS_32, periodic, pt)
                else
                    pt:destroy()
                end
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            SoundHandler("Units\\Human\\SteamTank\\SteamTankAttack1.flac", true, Player(self.pid - 1), self.caster)

            for i = 0, 2 do
                local angle = self.angle + 0.175 * i - 0.175
                local missile = Missiles:create(self.x, self.y, 20., self.x + 700. * Cos(angle), self.y + 700. * Sin(angle), 0.) ---@type Missiles
                missile:model("Abilities\\Weapons\\GyroCopter\\GyroCopterMissile.mdl")
                missile:scale(1.1)
                missile:speed(1500)
                missile.source = self.caster
                missile.owner = Player(self.pid - 1)
                missile:vision(400)
                missile.collision = 90
                missile.damage = self.dmg * BOOST[self.pid]

                missile.onHit = function(enemy)
                    if IsHittable(enemy, missile.owner) then
                        local ug = CreateGroup()
                        local pid = GetPlayerId(missile.owner) + 1

                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\GyroCopter\\GyroCopterMissile.mdl", missile.x, missile.y))
                        MakeGroupInRange(pid, ug, missile.x, missile.y, 150. * LBOOST[pid], Condition(FilterEnemy))

                        for target in each(ug) do
                            DamageTarget(missile.source, target, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, TRIROCKET.tag)
                        end

                        DestroyGroup(ug)

                        return true
                    end

                    return false
                end

                missile:launch()
            end

            --movement
            local pt = TimerList[self.pid]:add()
            pt.dur = 250.
            pt.angle = (bj_RADTODEG * self.angle - 180)
            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class ASSAULTHELICOPTER : Spell
    ---@field cd function
    ---@field dmg function
    ---@field dur number
    ASSAULTHELICOPTER = Spell.define("A06U")
    do
        local thistype = ASSAULTHELICOPTER
        local type = {FourCC('h03W'), FourCC('h03V'), FourCC('h03H'),}

        thistype.values = {
            cd = function(pid) return (1.25 - (0.25 * GetUnitAbilityLevel(Hero[pid], thistype.id))) / (LBOOST[pid] ^ 2) end,
            dmg = function(pid) return 0.35 * (BlzGetUnitBaseDamage(Hero[pid], 0) + GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
            dur = 30.,
        }

        local function cluster_rocket(pt)
            local to_remove = {}

            for target in each(pt.ug) do
                if UnitAlive(target) == false or UnitDistance(target, pt.source) > 1500. or IsUnitAlly(target, Player(pt.pid - 1)) then
                    to_remove[#to_remove + 1] = target
                end
            end

            --clean helitargets
            for i = 1, #to_remove do
                GroupRemoveUnit(pt.ug, to_remove[i])
            end

            local x, y, z = GetUnitX(pt.source), GetUnitY(pt.source), GetUnitFlyHeight(pt.source)

            --single shot
            if SNIPERSTANCE.enabled[pt.pid] then
                local target = FirstOfGroup(pt.ug)

                if UnitAlive(Unit[Hero[pt.pid]].target) then
                    target = Unit[Hero[pt.pid]].target
                end

                local missile = Missiles:create(x, y, z, GetUnitX(target), GetUnitY(target), BlzGetUnitZ(target)) ---@type Missiles
                missile:model("war3mapImported\\HighSpeedProjectile_ByEpsilon.mdx")
                missile:scale(1.1)
                missile:speed(1800)
                missile:arc(math.random(5, 15))
                missile.source = Hero[pt.pid]
                missile.target = target
                missile.owner = Player(pt.pid - 1)
                missile:vision(400)
                missile.damage = pt.dmg * 2.5 * pt.boost

                missile.onFinish = function()
                    DamageTarget(missile.source, missile.target, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, "Cluster Rockets")

                    return true
                end

                missile:launch()
            --multi shot
            else
                for enemy in each(pt.ug) do
                    local missile = Missiles:create(x, y, z, GetUnitX(enemy), GetUnitY(enemy), BlzGetUnitZ(enemy)) ---@type Missiles
                    missile:model("Abilities\\Spells\\Other\\TinkerRocket\\TinkerRocketMissile.mdl")
                    missile:scale(1.1)
                    missile:speed(1400)
                    missile.source = Hero[pt.pid]
                    missile.target = enemy
                    missile.owner = Player(pt.pid - 1)
                    missile:vision(400)
                    missile.damage = pt.dmg * pt.boost

                    missile.onFinish = function()
                        DamageTarget(missile.source, missile.target, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, "Cluster Rockets")

                        return true
                    end

                    missile:launch()
                end
            end
        end

        local function cooldown(pt)
            pt.rocket_cd = false
        end

        local function attack(pt)
            local x = GetUnitX(Hero[pt.pid]) + 60. * Cos(bj_DEGTORAD * (pt.angle + GetUnitFacing(Hero[pt.pid])))
            local y = GetUnitY(Hero[pt.pid]) + 60. * Sin(bj_DEGTORAD * (pt.angle + GetUnitFacing(Hero[pt.pid])))

            --leash
            if UnitDistance(Hero[pt.pid], pt.source) > 700. then
                SetUnitPosition(pt.source, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]))
            end

            --follow
            if DistanceCoords(x, y, GetUnitX(pt.source), GetUnitY(pt.source)) > 75. then
                IssuePointOrder(pt.source, "move", x, y)
            end

            --prioritize facing target hero is attacking
            if UnitAlive(Unit[Hero[pt.pid]].target) then
                SetUnitFacing(pt.source, bj_RADTODEG * Atan2(GetUnitY(Unit[Hero[pt.pid]].target) - GetUnitY(pt.source), GetUnitX(Unit[Hero[pt.pid]].target) - GetUnitX(pt.source)))
            end

            --acquire helicopter targets near hero
            GroupEnumUnitsInRangeEx(pt.pid, pt.ug, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), 1200., Condition(FilterEnemyAwake))

            if BlzGroupGetSize(pt.ug) > 0 and not pt.rocket_cd then
                pt.rocket_cd = true
                TimerQueue:callDelayed(pt.cd, cooldown, pt)
                cluster_rocket(pt)
            end
        end

        local function periodic(pt, tag)
            SetTextTagPosUnit(tag, pt.source, -200.)
        end

        local function wander(pt)
            pt.angle = math.random(1, 3) * 120. - 60
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            local tag = CreateTextTag()
            pt.source = CreateUnit(Player(self.pid - 1), type[self.ablev], self.x + 75. * Cos(self.angle), self.y + 75. * Sin(self.angle), bj_RADTODEG * self.angle)
            SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterWhat" .. (GetRandomInt(1,5)) .. ".flac", true, nil, pt.source)
            SetUnitFlyHeight(pt.source, 1100., 0.)
            SetUnitFlyHeight(pt.source, 300., 500.)
            UnitAddIndicator(pt.source, 255, 255, 255, 255)

            pt.boost = BOOST[self.pid]
            pt.dmg = self.dmg
            SetTextTagText(tag, RealToString(pt.boost * 100) .. "\x25", 0.024)
            SetTextTagColor(tag, 255, R2I(270 - pt.boost * 150), R2I(270 - pt.boost * 150), 255)
            pt.cd = self.cd * LBOOST[self.pid]
            pt.ug = CreateGroup()
            wander(pt)
            pt.timer:callPeriodically(FPS_32, nil, periodic, pt, tag)
            pt.timer:callPeriodically(0.25, nil, attack, pt)
            pt.timer:callPeriodically(6., nil, wander, pt)
            pt.timer:callDelayed(self.dur * LBOOST[self.pid], PlayerTimer.destroy, pt)
            pt.onRemove = function()
                SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterPissed6.flac", true, nil, pt.source)
                IssuePointOrder(pt.source, "move", GetUnitX(Hero[pt.pid]) + 1000. * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pt.pid])), GetUnitY(Hero[pt.pid]) + 1000. * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pt.pid])))
                TimerQueue:callDelayed(2., RemoveUnit, pt.source)
                Fade(pt.source, 2., true)
                DestroyTextTag(tag)
            end
            pt.tag = thistype.id
        end

    end

    ---@class SINGLESHOT : Spell
    ---@field dmg function
    SINGLESHOT = Spell.define("A05D")
    do
        local thistype = SINGLESHOT
        thistype.values = {
            dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 5. end,
        }

        function thistype:onCast()
            self.x = self.x + 80. * Cos(GetUnitFacing(self.caster) * bj_DEGTORAD)
            self.y = self.y + 80. * Sin(GetUnitFacing(self.caster) * bj_DEGTORAD)
            self.angle = Atan2(MouseY[self.pid] - self.y, MouseX[self.pid] - self.x) * bj_RADTODEG
            local newangle = (180. - RAbsBJ(RAbsBJ(self.angle - GetUnitFacing(self.caster)) - 180.)) * 0.5
            self.angle = bj_DEGTORAD * (self.angle + GetRandomReal(-(newangle), newangle))

            local dummy = Dummy.create(self.x + 1500. * Cos(self.angle), self.y + 1500. * Sin(self.angle), 0, 0, 1.5).unit
            SetUnitOwner(dummy, Player(self.pid - 1), true)
            UnitRemoveAbility(dummy, FourCC('Avul'))
            UnitRemoveAbility(dummy, FourCC('Aloc'))
            local target = Dummy.create(self.x, self.y, FourCC('A05J'), 1, 1.5)
            target:attack(dummy)
            SoundHandler("war3mapImported\\xm1014-3.wav", false, Player(self.pid - 1))

            local ug = CreateGroup()

            for _ = 1, 30 do
                MakeGroupInRange(self.pid, ug, self.x, self.y, 150. * LBOOST[self.pid], Condition(FilterEnemy))

                for target in each(ug) do
                    if SingleShotDebuff:has(self.caster, target) == false then
                        DamageTarget(self.caster, target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end
                    SingleShotDebuff:add(self.caster, target):duration(3.)
                end

                self.x = self.x + 50 * Cos(self.angle)
                self.y = self.y + 50 * Sin(self.angle)
            end

            DestroyGroup(ug)
        end
    end

    ---@class HANDGRENADE : Spell
    ---@field dmg function
    ---@field aoe number
    ---@field dmg2 function
    ---@field aoe2 number
    HANDGRENADE = Spell.define("A0J4")
    do
        local thistype = HANDGRENADE

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (0.4 + 0.1 * ablev) end,
            aoe = 300,
            dmg2 = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * (0.9 + 0.1 * ablev) end,
            aoe2 = 400.,
        }

        local function rocket(pt, boost)
            local missile = Missiles:create(GetUnitX(pt.source), GetUnitY(pt.source), GetUnitFlyHeight(pt.source), pt.x, pt.y, 0) ---@type Missiles
            missile:model("war3mapImported\\Rocket.mdx")
            missile:scale(1.2)
            missile:speed(1500)
            missile:arc(math.random(1, 2))
            missile.source = Hero[pt.pid]
            missile.owner = Player(pt.pid - 1)
            missile:vision(400)

            missile.onFinish = function()
                local ug = CreateGroup()
                --explode
                DestroyEffect(AddSpecialEffect("war3mapImported\\NewMassiveEX.mdx", pt.x, pt.y))
                MakeGroupInRange(pt.pid, ug, missile.x, missile.y, thistype.aoe2 * boost, Condition(FilterEnemy))

                for target in each(ug) do
                    StunUnit(pt.pid, target, 4.)
                    DamageTarget(missile.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                DestroyGroup(ug)

                return false
            end

            missile:launch()

            SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterPissed1.flac", true, nil, pt.source)

            pt:destroy()
        end

        function thistype:onCast()
            local pt, heli = TimerList[self.pid]:add(), TimerList[self.pid]:get(ASSAULTHELICOPTER.id)

            if heli then
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareCaster.mdl", self.x, self.y))
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareTarget.mdl", self.targetX, self.targetY))
                pt.x = self.targetX
                pt.y = self.targetY
                pt.dur = 3.
                pt.dmg = self.dmg2 * heli.boost
                pt.source = heli.source

                pt.timer:callDelayed(2., rocket, pt, heli.boost)
            else
                SoundHandler("war3mapImported\\grenade pin.mp3", true, nil, self.caster)
                local missile = Missiles:create(self.x, self.y, 30., self.targetX, self.targetY, -10) ---@type Missiles
                missile:model("war3mapImported\\PotatoMasher.mdl")
                missile:scale(1.5)
                missile:speed(800)
                missile:arc(math.random(60, 65))
                missile.source = self.caster
                missile.owner = Player(self.pid - 1)
                missile:vision(400)
                missile.damage = self.dmg * BOOST[self.pid]

                missile.onFinish = function()
                    missile:pause(true)
                    TimerQueue:callDelayed(2., function() missile:pause(false) end)

                    return false
                end

                missile.onResume = function()
                    local ug = CreateGroup()

                    MakeGroupInRange(self.pid, ug, missile.x, missile.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

                    for target in each(ug) do
                        StunUnit(self.pid, target, 3.)
                        DamageTarget(missile.source, target, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end

                    DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", missile.x, missile.y))
                    DestroyGroup(ug)

                    return true
                end

                missile:launch()
            end
        end
    end

    ---@class FLAMINGBETTY : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field dur number
    ---@field cd function
    ---@field charges integer[]
    FLAMINGBETTY = Spell.define("A06V")
    do
        local thistype = FLAMINGBETTY

        thistype.charges = __jarray(0)
        thistype.values = {
            aoe = 300.,
            dmg = function(pid) return 0.2 * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
            dur = 15.,
            cd = function(pid) return 42. - 2 * GetUnitAbilityLevel(Hero[pid], thistype.id) end,
        }

        local function cooldown(pt)
            local MAX_CHARGES = 2

            thistype.charges[pt.pid] = IMinBJ(MAX_CHARGES, thistype.charges[pt.pid] + 1)

            if GetLocalPlayer() == Player(pt.pid - 1) then
                BlzSetAbilityIcon(thistype.id, "ReplaceableTextures\\CommandButtons\\BTNFlamingBetty" .. (thistype.charges[pt.pid]) .. ".blp")
            end

            if thistype.charges[pt.pid] >= MAX_CHARGES then
                pt:destroy()
            else
                BlzStartUnitAbilityCooldown(pt.source, thistype.id, 0.)
                pt.timer:callDelayed(thistype.cd(pt.pid), cooldown, pt)
            end
        end

        local function onHit(source, target, amount)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local ug = CreateGroup()

            amount.value = 0
            MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), thistype.aoe * LBOOST[pid], Condition(FilterEnemy))

            for enemy in each(ug) do
                DamageTarget(source, enemy, thistype.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local turret = CreateUnit(Player(self.pid - 1), FourCC("o003"), self.targetX, self.targetY, GetUnitFacing(self.caster))
            UnitApplyTimedLife(turret, FourCC('Bhwd'), self.dur * LBOOST[self.pid])
            EVENT_ON_HIT_MULTIPLIER:register_unit_action(turret, onHit)
            Unit[turret].attackCount = 8
            SoundHandler("Units\\Creeps\\HeroTinkerRobot\\ClockwerkGoblinReady1.flac", true, nil, turret)
            DestroyEffect(AddSpecialEffect("UI\\Feedback\\TargetPreSelected\\TargetPreSelected.mdl", self.targetX, self.targetY))

            thistype.charges[self.pid] = thistype.charges[self.pid] - 1

            if GetLocalPlayer() == Player(self.pid - 1) then
                BlzSetAbilityIcon(thistype.id, "ReplaceableTextures\\CommandButtons\\BTNFlamingBetty" .. (thistype.charges[self.pid]) .. ".blp")
            end

            --refresh charge timer
            local pt = TimerList[self.pid]:get(thistype.id, self.caster)
            if not pt then
                pt = TimerList[self.pid]:add()
                pt.source = self.caster
                pt.tag = thistype.id

                pt.timer:callDelayed(self.cd, cooldown, pt)
            end

            if thistype.charges[self.pid] <= 0 then
                BlzStartUnitAbilityCooldown(self.caster, thistype.id, TimerGetRemaining(pt.timer.timer))
            end
        end

        function thistype.onLearn(u)
            local pid = GetPlayerId(GetOwningPlayer(u)) + 1
            thistype.charges[pid] = 2
        end
    end

    --thunderblade

    ---@class OVERLOAD : Spell
    ---@field mult function
    OVERLOAD = Spell.define("A096")
    do
        local thistype = OVERLOAD

        thistype.values = {
            mult = function(pid) return 1. + (0.5 + 0.1 * R2I(GetHeroLevel(Hero[pid]) / 75.)) end,
        }

        function thistype:onCast()
            OverloadBuff:add(self.caster, self.caster)
        end

        function thistype.onLearn(source, ablev, pid)
            OverloadBuff:refresh(source, source)
        end
    end

    ---@class THUNDERDASH : Spell
    ---@field range function
    ---@field dmg function
    ---@field aoe number
    THUNDERDASH = Spell.define("A095")
    do
        local thistype = THUNDERDASH

        thistype.values = {
            range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev + 3) * 150. end,
            dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 2. end,
            aoe = 260.,
        }

        function thistype:onCast()
            TimerList[self.pid]:stopAllTimers(OMNISLASH.id)

            local range = self.range * LBOOST[self.pid]
            local angle = self.angle

            --reset omnislash visual
            SetUnitVertexColor(self.caster, 255, 255, 255, 255)
            SetUnitTimeScale(self.caster, 1.)

            ShowUnit(self.caster, false)
            UnitAddAbility(self.caster, FourCC('Avul'))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\FarseerMissile\\FarseerMissile.mdl", self.caster, "chest"))

            local missile = Missiles:create(self.x, self.y, 100., self.x + range * Cos(angle), self.y + range * Sin(angle), 100.) ---@type Missiles
            missile:model("war3mapImported\\LightningSphere_FX.mdl")
            missile:scale(1.5)
            missile:speed(1120)
            missile.source = self.caster
            missile.owner = Player(self.pid - 1)
            missile:vision(400)
            missile.collision = 80
            missile.damage = self.dmg * BOOST[self.pid]
            missile.aoe = self.aoe * LBOOST[self.pid]
            missile.pid = self.pid

            --unit impact
            missile.onHit = function(enemy)
                if IsHittable(enemy, missile.owner) and missile.travel >= 200 then
                    missile.impacted = true
                end

                return false
            end

            missile.onRemove = function()
                UnitRemoveAbility(missile.source, FourCC('Avul'))
                ShowUnit(missile.source, true)
                reselect(missile.source)
                SetUnitPathing(missile.source, true)
                BlzUnitClearOrders(missile.source, false)
            end

            missile.onPeriod = function()
                local stopped = false

                if not UnitAlive(missile.source) then
                    stopped = true
                else
                    SetUnitXBounded(missile.source, missile.x)
                    SetUnitYBounded(missile.source, missile.y)

                    --terrain impact
                    if not IsTerrainWalkable(missile.x, missile.y) then
                        missile.impacted = true
                    end

                    if missile.travel >= 200 and missile.impacted then
                        for i = -1, 1 do
                            for j = -1, 1 do
                                if (i == 0 and j == 0) or (i ~= 0 and j ~= 0) then
                                    DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", missile.x + 140 * i, missile.y + 140 * j))
                                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", missile.x + 100 * i, missile.y + 100 * j))
                                end
                            end
                        end
                        local ug = CreateGroup()
                        MakeGroupInRange(missile.pid, ug, missile.x, missile.y, missile.aoe, Condition(FilterEnemy))

                        for target in each(ug) do
                            DamageTarget(missile.source, target, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, THUNDERDASH.tag)
                        end

                        DestroyGroup(ug)

                        stopped = true
                    end
                end

                return stopped
            end

            missile:launch()
        end
    end

    ---@class MONSOON : Spell
    ---@field times function
    ---@field aoe function
    ---@field dmg function
    MONSOON = Spell.define("A0MN")
    do
        local thistype = MONSOON

        thistype.values = {
            times = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 1. end,
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 275 + 25. * ablev end,
            dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 1.8 end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 1

            if pt.dur >= -0.5 then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, thistype.aoe(pt.pid) * LBOOST[pt.pid], Condition(FilterEnemy))

                for target in each(ug) do
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", GetUnitX(target), GetUnitY(target)))
                    DamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(1., periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.x = self.targetX
            pt.y = self.targetY
            pt.dur = self.times * LBOOST[self.pid]

            local sfx = AddSpecialEffect("war3mapImported\\AnimatedEnviromentalEffectRainBv005", self.targetX, self.targetY)
            BlzSetSpecialEffectScale(sfx, 0.4)
            TimerQueue:callDelayed(pt.dur, DestroyEffect, sfx)
            pt.timer:callDelayed(1., periodic, pt)
        end
    end

    ---@class BLADESTORM : Spell
    ---@field aoe number
    ---@field dot function
    ---@field chance number
    ---@field dmg function
    BLADESTORM = Spell.define("A03O")
    do
        local thistype = BLADESTORM

        thistype.values = {
            aoe = 400.,
            dot = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid],true) * ablev * 0.2 end,
            chance = 15.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid],true) * (ablev + 2.) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 1

            if UnitAlive(Hero[pt.pid]) and pt.dur >= 0 then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), thistype.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

                if math.random() * 100 < thistype.chance * LBOOST[pt.pid] and BlzGroupGetSize(ug) > 0 then
                    local enemy = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))
                    Dummy.create(GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), FourCC('A09S'), 1):cast(Player(pt.pid - 1), "forkedlightning", enemy)
                    DamageTarget(Hero[pt.pid], enemy, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                for target in each(ug) do
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "origin"))
                    DamageTarget(Hero[pt.pid], target, pt.dot * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.33, periodic, pt)
            else
                AddUnitAnimationProperties(Hero[pt.pid], "spin", false)
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            pt.dur = 9.
            pt.dmg = self.dmg
            pt.dot = self.dot

            AddUnitAnimationProperties(Hero[self.pid], "spin", true)
            pt.timer:callDelayed(0.33, periodic, pt)
        end
    end

    ---@class OMNISLASH : Spell
    ---@field times function
    ---@field dmg function
    OMNISLASH = Spell.define("A0os")
    do
        local thistype = OMNISLASH

        thistype.values = {
            times = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 3. end,
            dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 1.5 end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local x = GetUnitX(pt.source)
            local y = GetUnitY(pt.source)

            pt.dur = pt.dur - 1

            if pt.dur >= -0.5 then
                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, x, y, 600., Condition(FilterEnemy))

                local target = FirstOfGroup(ug)

                if target then
                    SetUnitAnimation(pt.source, "Attack Slam")
                    SetUnitXBounded(pt.source, GetUnitX(target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
                    SetUnitYBounded(pt.source, GetUnitY(target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
                    BlzSetUnitFacingEx(pt.source, GetUnitFacing(target))
                    DamageTarget(pt.source, target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl", Hero[pt.pid], "chest"))
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "chest"))
                else
                    pt.dur = 0.
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.4, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dur = self.times * LBOOST[self.pid] - 1
            pt.source = self.caster
            pt.tag = OMNISLASH.id
            pt.dmg = self.dmg
            pt.onRemove = function(this)
                reselect(Hero[this.pid])
                SetUnitVertexColor(Hero[this.pid], 255, 255, 255, 255)
                SetUnitTimeScale(Hero[this.pid], 1.)
                OmnislashBuff:dispel(this.source, this.source)
            end

            SetUnitTimeScale(self.caster, 2.5)
            SetUnitVertexColorBJ(self.caster, 100, 100, 100, 50.00)
            SetUnitXBounded(self.caster, GetUnitX(self.target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(self.target) - 180.)))
            SetUnitYBounded(self.caster, GetUnitY(self.target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(self.target) - 180.)))
            BlzSetUnitFacingEx(self.caster, GetUnitFacing(self.target))
            DamageTarget(self.caster, self.target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl", self.caster, "chest"))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", self.target, "chest"))

            pt.timer:callDelayed(0.4, periodic, pt)

            OmnislashBuff:add(self.caster, self.caster)
        end
    end

    ---@class RAILGUN : Spell
    ---@field range number
    ---@field aoe number
    ---@field dmg function
    RAILGUN = Spell.define("A01L")
    do
        local thistype = RAILGUN

        thistype.values = {
            range = 3000.,
            aoe = 800.,
            dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 20. end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.time = pt.time + FPS_32

            if pt.time >= pt.dur then
                local x = GetUnitX(pt.target)
                local y = GetUnitY(pt.target)
                local dist = 0.
                local sfx

                local ug = CreateGroup()

                repeat
                    MakeGroupInRange(pt.pid, ug, x, y, 100., Condition(FilterEnemy))

                    x = x + 50. * Cos(pt.angle)
                    y = y + 50. * Sin(pt.angle)

                    dist = dist + 50.
                    if ModuloReal(dist, 750.) == 0. then
                        sfx = AddSpecialEffect("war3mapImported\\DustWindFaster3.mdx", x, y)
                        BlzSetSpecialEffectScale(sfx, 0.5)
                        BlzSetSpecialEffectYaw(sfx, pt.angle)
                        BlzSetSpecialEffectRoll(sfx, bj_PI)
                        BlzSetSpecialEffectZ(sfx, BlzGetLocalSpecialEffectZ(sfx) + 300.)
                        DestroyEffect(sfx)
                    end
                until BlzGroupGetSize(ug) > 0 or dist >= thistype.range

                --laser shot
                local dummy = Dummy.create(x, y, 0, 0).unit
                SetUnitFlyHeight(dummy, 135., 0.)
                UnitRemoveAbility(dummy, FourCC('Avul'))
                UnitRemoveAbility(dummy, FourCC('Aloc'))
                local dummy2 = Dummy.create(GetUnitX(pt.target), GetUnitY(pt.target), FourCC('A010'), 1)
                SetUnitFlyHeight(dummy2.unit, 135., 0.)
                dummy2:attack(dummy)

                SetUnitScale(pt.target, 1., 1., 1.)
                SetUnitAnimation(pt.target, "death")

                sfx = AddSpecialEffect("war3mapImported\\SuperLightningBall.mdl", x, y)
                BlzSetSpecialEffectScale(sfx, 3.0)
                BlzPlaySpecialEffect(sfx, ANIM_TYPE_DEATH)
                TimerQueue:callDelayed(0.5, DestroyEffect, sfx)
                sfx = AddSpecialEffect("war3mapImported\\EMPBubble.mdx", x, y)
                BlzSetSpecialEffectScale(sfx, thistype.aoe * 0.01)
                BlzPlaySpecialEffectWithTimeScale(sfx, ANIM_TYPE_DEATH, 1.5)
                TimerQueue:callDelayed(1.5, DestroyEffect, sfx)

                MakeGroupInRange(pt.pid, ug, x, y, thistype.aoe, Condition(FilterEnemy))

                for target in each(ug) do
                    DamageTarget(pt.source, target, thistype.dmg(pt.pid) * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                DestroyGroup(ug)

                pt:destroy()
            else
                SetUnitScale(pt.target, pt.time / 3., pt.time / 3., pt.time / 3.)
                BlzSetUnitFacingEx(pt.target, GetUnitFacing(pt.target) + 10 * pt.time)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.angle = self.angle
            pt.source = self.caster
            pt.target = Dummy.create(self.x + 65. * Cos(pt.angle), self.y + 65. * Sin(pt.angle), 0, 0).unit
            pt.dur = 4.

            BlzSetUnitSkin(pt.target, FourCC('h072'))
            SetUnitScale(pt.target, 0., 0., 0.)
            SoundHandler("war3mapImported\\railgun.mp3", true, nil, pt.target)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    --master rogue

    ---@class INSTANTDEATH : Spell
    ---@field mult function
    ---@field apply function
    INSTANTDEATH = Spell.define("A0QQ")
    do
        local thistype = INSTANTDEATH

        thistype.bonus = __jarray(0)
        thistype.values = {
            mult = function(pid) return 400. + GetHeroLevel(Hero[pid]) // 50 * 100. end,
        }

        function thistype.apply(u, pid)
            Unit[u].cd_flat = Unit[u].cd_flat - thistype.bonus[u]
            thistype.bonus[u] = thistype.mult(pid)
            Unit[u].cd_flat = Unit[u].cd_flat + thistype.bonus[u]
        end

        function thistype:setup(u)
            local pid = GetPlayerId(GetOwningPlayer(u)) + 1
            Unit[u].cc_percent = 1.2
            thistype.apply(u, pid)
        end
    end

    ---@class DEATHSTRIKE : Spell
    ---@field dmg function
    ---@field dur function
    DEATHSTRIKE = Spell.define("A0QV")
    do
        local thistype = DEATHSTRIKE

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid], true) * (0.5 + 0.5 * ablev) end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.6 * ablev end,
        }

        ---@type fun(pt: PlayerTimer)
        local function expire(pt)
            UnitRemoveAbility(pt.target, FourCC('S00I'))
            SetUnitTurnSpeed(pt.target, GetUnitDefaultTurnSpeed(pt.target))

            pt:destroy()
        end

        function thistype:onCast()
            local x = GetUnitX(self.target) - 60 * Cos(GetUnitFacing(self.target) * bj_DEGTORAD) ---@type number 
            local y = GetUnitY(self.target) - 60 * Sin(GetUnitFacing(self.target) * bj_DEGTORAD) ---@type number 

            AddUnitAnimationProperties(self.caster, "alternate", false)

            UnitAddAbility(self.target, FourCC('S00I'))
            SetUnitTurnSpeed(self.target, 0)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\BlinkCaster.mdl", self.caster, "chest"))

            if IsTerrainWalkable(x, y) then
                SetUnitPathing(self.caster, false)
                SetUnitXBounded(self.caster, x)
                SetUnitYBounded(self.caster, y)
                SetUnitPathing(self.caster, true)
                BlzSetUnitFacingEx(self.caster, Atan2(GetUnitY(self.target) - y, GetUnitX(self.target) - x))
            end

            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", self.target, "origin"))
            DamageTarget(self.caster, self.target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            TimerQueue:callDelayed(0., IssueTargetOrder, self.caster, "smart", self.target)

            local pt = TimerList[self.pid]:add()
            pt.target = self.target
            pt.timer:callDelayed(self.dur * LBOOST[self.pid], expire, pt)
        end
    end

    ---@class HIDDENGUISE : Spell
    ---@field expire function
    HIDDENGUISE = Spell.define("A0F5")
    do
        local thistype = HIDDENGUISE

        ---@type fun(pt: PlayerTimer)
        function thistype.expire(pt)
            PlayerAddItemById(pt.pid, FourCC('I0OW'))
            SetUnitVertexColor(pt.source, 255, 255, 255, 255)
            ToggleCommandCard(pt.source, true)
            UnitRemoveAbility(pt.source, FourCC('Avul'))
            Unit[pt.source].attack = true
            pt:destroy()
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dur = 2.
            pt.source = self.caster
            pt.tag = thistype.id

            local sfx = AddSpecialEffect("Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", self.x, self.y)
            BlzSetSpecialEffectYaw(sfx, GetUnitFacing(self.caster) * bj_DEGTORAD)
            TimerQueue:callDelayed(2., DestroyEffect, sfx)

            UnitRemoveAbility(self.caster, FourCC('BOwk'))
            UnitAddAbility(self.caster, FourCC('Avul'))
            ToggleCommandCard(self.caster, false)
            SetUnitVertexColor(self.caster, 50, 50, 50, 50)
            Unit[self.caster].attack = false
            pt.timer:callDelayed(pt.dur, thistype.expire, pt)
        end
    end

    ---@class NERVEGAS : Spell
    ---@field aoe function
    ---@field dmg function
    ---@field dur number
    NERVEGAS = Spell.define("A0F7")
    do
        local thistype = NERVEGAS

        thistype.values = {
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 190 + 10. * ablev end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid], true) * 3. * ablev end,
            dur = 10.,
        }

        function thistype:onCast()
            AddUnitAnimationProperties(self.caster, "alternate", false)

            local missile = Missiles:create(self.x, self.y, 60, self.targetX, self.targetY, 0) ---@type Missiles
            missile:model("Abilities\\Spells\\Other\\AcidBomb\\BottleMissile.mdl")
            missile:scale(1.1)
            missile:speed(900)
            missile:arc(40)
            missile:vision(400)
            missile.source = self.caster
            missile.owner = Player(self.pid - 1)

            missile.onFinish = function()
                local ug = CreateGroup()

                MakeGroupInRange(self.pid, ug, missile.x, missile.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

                for enemy in each(ug) do
                    NerveGasDebuff:add(missile.source, enemy):duration(self.dur * LBOOST[self.pid])
                end

                return true
            end

            missile:launch()
        end
    end

    ---@class BACKSTAB : Spell
    ---@field dmg function
    BACKSTAB = Spell.define("A0QP")
    do
        local thistype = BACKSTAB

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (GetHeroAgi(Hero[pid], true) * 0.16 + (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * .03) * ablev end,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local angle = Atan2(GetUnitY(source) - GetUnitY(target), GetUnitX(source) - GetUnitX(target)) - (bj_DEGTORAD * (GetUnitFacing(target) - 180))

            if angle > bj_PI then
                angle = angle - 2 * bj_PI
            elseif angle < -bj_PI then
                angle = angle + 2 * bj_PI
            end

            if RAbsBJ(angle) <= (0.25 * bj_PI) and (IsUnitType(target, UNIT_TYPE_STRUCTURE) == false) then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "chest"))
                DamageTarget(source, target, thistype.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end
        end

        function thistype.onLearn(source, ablev, pid)
            if ablev == 1 then
                EVENT_ON_HIT:register_unit_action(source, onHit)
            end
        end
    end

    ---@class PIERCINGSTRIKE : Spell
    ---@field pen function
    PIERCINGSTRIKE = Spell.define("A0QU")
    do
        local thistype = PIERCINGSTRIKE
        thistype.pen = function(pid) return (30 + GetUnitAbilityLevel(Hero[pid], PIERCINGSTRIKE.id)) end

        function thistype.onLearn(source, ablev, pid)
            EVENT_ON_HIT:register_unit_action(source, thistype.onHit)
        end

        function thistype.onHit(source)
            if GetRandomInt(0, 99) < 20 then
                PiercingStrikeBuff:add(source, source):duration(3.)
                SetUnitAnimation(source, "spell slam")
            end
        end
    end

    --oblivion guard

    ---@class BODYOFFIRE : Spell
    ---@field dmg function
    ---@field cooldown function
    ---@field charges integer[]
    BODYOFFIRE = Spell.define("A07R")
    do
        local thistype = BODYOFFIRE

        thistype.charges = __jarray(0)
        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * (0.25 + 0.05 * ablev) end,
        }

        ---@type fun(pt: PlayerTimer)
        function thistype.cooldown(pt)
            local MAX_CHARGES = 5

            BODYOFFIRE.charges[pt.pid] = IMinBJ(MAX_CHARGES, BODYOFFIRE.charges[pt.pid] + 1)
            UnitDisableAbility(pt.source, INFERNALSTRIKE.id, false)
            UnitDisableAbility(pt.source, MAGNETICSTRIKE.id, false)

            if GetLocalPlayer() == Player(pt.pid - 1) then
                BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\BTNBodyOfFire" .. (BODYOFFIRE.charges[pt.pid]) .. ".blp")
            end

            if BODYOFFIRE.charges[pt.pid] >= MAX_CHARGES then
                BlzStartUnitAbilityCooldown(pt.source, BODYOFFIRE.id, 0.)
                pt:destroy()
            else
                BlzStartUnitAbilityCooldown(pt.source, BODYOFFIRE.id, 5.)
                pt.timer:callDelayed(5., thistype.cooldown, pt)
            end
        end

        local function onHit(target, source, amount, amount_after_red, damage_type)
            local ablev = GetUnitAbilityLevel(target, BODYOFFIRE.id)
            if ablev > 0 and damage_type == PHYSICAL and IsUnitEnemy(target, GetOwningPlayer(source)) then
                local tpid = GetPlayerId(GetOwningPlayer(target)) + 1
                local returnDmg = (amount_after_red * 0.05 * ablev) + BODYOFFIRE.dmg(tpid)
                DamageTarget(target, source, returnDmg * BOOST[tpid], ATTACK_TYPE_NORMAL, MAGIC, BODYOFFIRE.tag)
            end
        end

        function thistype:setup(u)
            local pid = GetPlayerId(GetOwningPlayer(u)) + 1
            thistype.charges[pid] = 5 --default

            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetAbilityIcon(thistype.id, "ReplaceableTextures\\CommandButtons\\BTNBodyOfFire" .. (thistype.charges[pid]) .. ".blp")
            end

            EVENT_ON_STRUCK_AFTER_REDUCTIONS:register_unit_action(u, onHit)
        end
    end

    ---@class METEOR : Spell
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    METEOR = Spell.define("A07O")
    do
        local thistype = METEOR
        thistype.preCast = DASH_PRECAST

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * ablev * 1. end,
            aoe = 300.,
            dur = 1.,
        }

        ---@type fun(pt: PlayerTimer)
        local function expire(pt)
            local ug = CreateGroup()

            DestroyTreesInRange(pt.x, pt.y, 250)
            reselect(Hero[pt.pid])
            BlzPauseUnitEx(Hero[pt.pid], false)

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, thistype.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

            for target in each(ug) do
                Stun:add(Hero[pt.pid], target):duration(thistype.dur * LBOOST[pt.pid])
                DamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end

            if SquareRoot(Pow(GetUnitX(Hero[pt.pid]) - pt.x, 2) + Pow(GetUnitY(Hero[pt.pid]) - pt.y, 2)) < 1000. then
                SetUnitPosition(Hero[pt.pid], pt.x, pt.y)
            end

            SetUnitAnimation(Hero[pt.pid], "birth")
            SetUnitTimeScale(Hero[pt.pid], 1)
            Fade(Hero[pt.pid], 0.8, false)

            DestroyGroup(ug)

            pt:destroy()
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.x = self.targetX
            pt.y = self.targetY

            BlzPauseUnitEx(self.caster, true)
            SetUnitAnimation(self.caster, "death")
            SetUnitTimeScale(self.caster, 2)
            Fade(self.caster, 0.8, true)

            local sfx = AddSpecialEffect("Units\\Demon\\Infernal\\InfernalBirth.mdl", pt.x, pt.y)
            BlzSetSpecialEffectScale(sfx, 2.5)
            TimerQueue:callDelayed(2., DestroyEffect, sfx)
            BlzSetSpecialEffectYaw(sfx, self.angle)

            pt.timer:callDelayed(0.9, expire, pt)
        end
    end

    ---@class MAGNETICSTANCE : Spell
    MAGNETICSTANCE = Spell.define("A076")
    do
        local thistype = MAGNETICSTANCE

        function thistype:onCast()
            MagneticStanceBuff:add(self.caster, self.caster)
        end

        function thistype.onLearn(source, ablev, pid)
            MagneticStanceBuff:refresh(source, source)
        end
    end

    ---@class INFERNALSTRIKE : Spell
    ---@field dmg function
    ---@field aoe number
    INFERNALSTRIKE = Spell.define("A05S")
    do
        local thistype = INFERNALSTRIKE

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * ablev * 1. end,
            aoe = 250.,
        }

        function thistype:onCast()
            MagneticStrikeBuff:dispel(self.caster, self.caster)
            InfernalStrikeBuff:add(self.caster, self.caster)
        end
    end

    ---@class MAGNETICSTRIKE : Spell
    ---@field aoe function
    ---@field dur function
    MAGNETICSTRIKE = Spell.define("A047")
    do
        local thistype = MAGNETICSTRIKE

        thistype.values = {
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 25. * ablev + 200. end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 4 end,
        }

        function thistype:onCast()
            InfernalStrikeBuff:dispel(self.caster, self.caster)
            MagneticStrikeBuff:add(self.caster, self.caster)
        end
    end

    ---@class GATEKEEPERSPACT : Spell
    ---@field dmg function
    ---@field aoe function
    GATEKEEPERSPACT = Spell.define("A0GJ")
    do
        local thistype = GATEKEEPERSPACT

        thistype.values = {
            dmg = function(pid) return GetHeroStr(Hero[pid], true) * 15. end,
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 550. + 50. * ablev end,
        }

        ---@type fun(pt: PlayerTimer)
        local function expire(pt)
            local ug = CreateGroup()
            local sfx = AddSpecialEffect("war3mapImported\\AnnihilationBlast.mdx", GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]))

            BlzSetSpecialEffectColor(sfx, 25, 255, 0)
            DestroyEffect(sfx)

            SetUnitAnimationByIndex(Hero[pt.pid], 2)
            BlzPauseUnitEx(Hero[pt.pid], false)
            MakeGroupInRange(pt.pid, ug, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), thistype.aoe(pt.pid) * LBOOST[pt.pid], Condition(FilterEnemy))

            for target in each(ug) do
                StunUnit(pt.pid, target, 5.)
                DamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end

            pt:destroy()

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            BlzPauseUnitEx(self.caster, true)
            TimerQueue:callDelayed(2, DestroyEffect, AddSpecialEffect("war3mapImported\\AnnihilationTarget.mdx", self.x, self.y))
            pt.timer:callDelayed(2, expire, pt)
        end
    end

    --phoenix ranger

    ---@class REINCARNATION : Spell
    ---@field enabled boolean[]
    REINCARNATION = Spell.define("A05T")
    do
        local thistype = REINCARNATION
        thistype.enabled = __jarray(false)
    end

    ---@class PHOENIXFLIGHT : Spell
    ---@field range function
    ---@field aoe number
    ---@field dmg function
    PHOENIXFLIGHT = Spell.define("A0FT")
    do
        local thistype = PHOENIXFLIGHT
        thistype.preCast = DASH_PRECAST

        thistype.values = {
            range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 350. + ablev * 150. end,
            dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 1.5 end,
            aoe = 250.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - pt.speed

            if pt.dur > 0. and IsUnitInRangeXY(pt.source, pt.x, pt.y, pt.dur + 500.) then
                local x = GetUnitX(pt.source)
                local y = GetUnitY(pt.source)
                local ug = CreateGroup()
                --movement
                SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))
                SetUnitXBounded(pt.source, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.source, y + pt.speed * Sin(pt.angle))

                BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)

                MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

                for target in each(ug) do
                    if IsUnitInGroup(target, pt.ug) == false then
                        GroupAddUnit(pt.ug, target)
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target), GetUnitY(target)))
                        DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)

                        local b = IgniteDebuff:get(nil, target)
                        if b then
                            b:dispel()
                            SEARINGARROWS.ignite(pt.source, target)
                        end
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                UnitRemoveAbility(pt.source, FourCC('Avul'))
                ShowUnit(pt.source, true)
                reselect(pt.source)
                SetUnitPathing(pt.source, true)
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dur = math.min(self.range * LBOOST[self.pid], math.max(17., DistanceCoords(self.x, self.y, self.targetX, self.targetY)))
            pt.speed = 33.
            pt.angle = self.angle
            pt.x = self.x + pt.dur * Cos(self.angle)
            pt.y = self.y + pt.dur * Sin(self.angle)
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.source = self.caster
            pt.target = Dummy.create(self.x, self.y, 0, 0).unit
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.ug = CreateGroup()
            UnitAddAbility(self.caster, FourCC('Avul'))
            ShowUnit(self.caster, false)

            BlzSetUnitSkin(pt.target, FourCC('h01B'))
            BlzSetUnitFacingEx(pt.target, bj_RADTODEG * pt.angle)
            SetUnitFlyHeight(pt.target, 150., 0)
            SetUnitAnimation(pt.target, "birth")
            SetUnitTimeScale(pt.target, 2)
            SetUnitScale(pt.target, 1.5, 1.5, 1.5)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class FIERYARROWS : Spell
    FIERYARROWS = Spell.define("A0IB")
    do
        local thistype = FIERYARROWS
        thistype.values = {
            chance = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2 * ablev end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid], true) * ablev + BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE) end,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local ablev = GetUnitAbilityLevel(source, thistype.id)

            if math.random() * 100. < ablev * 2 * LBOOST[pid] then
                DamageTarget(source, target, (((UnitGetBonus(source, BONUS_DAMAGE) + GetHeroAgi(source, true)) * .3 + GetHeroAgi(source, true) * ablev)) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, FLAMINGBOW.tag)
                DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target),GetUnitY(target)))

                local b = IgniteDebuff:get(nil, target)
                if b then
                    b:dispel()
                    SEARINGARROWS.ignite(source, target)
                end
            end
        end

        function thistype.onLearn(source, ablev, pid)
            EVENT_ON_HIT:register_unit_action(source, onHit)
        end

    end

    ---@class SEARINGARROWS : Spell
    ---@field ignite function
    ---@field burn function
    ---@field aoe number
    ---@field dmg function
    ---@field dot function
    SEARINGARROWS = Spell.define("A090")
    do
        local thistype = SEARINGARROWS

        thistype.values = {
            aoe = 750.,
            dmg = function(pid) return UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0) end,
            dot = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.05 + ablev * 0.05) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function burn(pt)
            pt.dur = pt.dur - 1

            if pt.dur >= 0 then
                DamageTarget(pt.source, pt.target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                pt.timer:callDelayed(1., burn, pt)
            else
                pt:destroy()
            end
        end

        ---@type fun(source: unit, target: unit)
        function thistype.ignite(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local pt = TimerList[pid]:add()

            TimerQueue:callDelayed(5., HideEffect, AddSpecialEffectTarget("war3mapImported\\FireNormal1.mdl", target, "chest"))

            pt.dmg = thistype.dot(pid) * BOOST[pid]
            pt.dur = 5.
            pt.source = source
            pt.target = target

            pt.timer:callDelayed(1., burn, pt)
        end

        function thistype:onCast()
            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            for target in each(ug) do
                local missile = Missiles:create(self.x, self.y, 40., 0, 0, 0) ---@type Missiles
                missile:model("Abilities\\Weapons\\SearingArrow\\SearingArrowMissile.mdl")
                missile:scale(1.)
                missile:speed(1250)
                missile:arc(15)
                missile.source = self.caster
                missile.target = target
                missile.owner = Player(self.pid - 1)
                missile.collision = 50
                missile:vision(400)
                missile.damage = self.dmg * BOOST[self.pid]

                missile.onHit = function(enemy)
                    if IsHittable(enemy, missile.owner) then
                        --apply debuff
                        IgniteDebuff:add(missile.source, enemy):duration(5.)
                        DamageTarget(missile.source, enemy, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)

                        return true
                    end

                    return false
                end

                missile:launch()
            end

            DestroyGroup(ug)
        end
    end

    ---@class FLAMINGBOW : Spell
    ---@field pierce function
    ---@field bonus function
    ---@field total function
    ---@field dur number
    FLAMINGBOW = Spell.define("A0F6")
    do
        local thistype = FLAMINGBOW
        thistype.values = {
            pierce = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 10. + 1. * ablev end,
            bonus = function(pid)
                local b = FlamingBowBuff:get(Hero[pid], Hero[pid])
                local adjust = (b and b.attack) or 0
                return 0.5 * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE) - adjust) end,
            total = function(pid)
                local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id)
                local b = FlamingBowBuff:get(Hero[pid], Hero[pid])
                local adjust = (b and b.attack) or 0
                return (0.8 + 0.02 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE) - adjust) end,
            dur = 15.,
        }

        function thistype:onCast()
            FlamingBowBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    --bloodzerker

    ---@class BLOODFRENZY : Spell
    BLOODFRENZY = Spell.define("A05Y")
    do
        local thistype = BLOODFRENZY

        function thistype:onCast()
            BloodFrenzyBuff:add(self.caster, self.caster):duration(5.)
        end
    end

    ---@class BLOODLEAP : Spell
    ---@field dmg function
    ---@field aoe number
    BLOODLEAP = Spell.define("A05Z")
    do
        local thistype = BLOODLEAP
        thistype.preCast = DASH_PRECAST

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.4 + 0.4 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
            aoe = 300.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            if pt.dur > 0. and IsUnitInRangeXY(pt.target, pt.x, pt.y, pt.dur) then
                local x = GetUnitX(pt.target)
                local y = GetUnitY(pt.target)
                local accel = pt.dur / pt.dist
                --movement
                SetUnitXBounded(pt.target, x + (pt.speed / (1 + accel)) * Cos(pt.angle))
                SetUnitYBounded(pt.target, y + (pt.speed / (1 + accel)) * Sin(pt.angle))
                pt.dur = pt.dur - (pt.speed // (1 + accel))

                if pt.dur <= pt.dist - 120 and pt.dur >= pt.dist - 160 then --sick animation
                    SetUnitTimeScale(pt.target, 0)
                end

                accel = pt.dur / pt.dist

                SetUnitFlyHeight(pt.target, 20 + pt.dist * (1. - accel) * accel * 1.3, 0)

                if pt.dur <= 0 then
                    local ug = CreateGroup()
                    if DistanceCoords(x, y, pt.x, pt.y) < 25. then
                        SetUnitXBounded(pt.target, pt.x)
                        SetUnitYBounded(pt.target, pt.y)
                    end

                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y))
                    MakeGroupInRange(pt.pid, ug, pt.x, pt.y, thistype.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

                    for target in each(ug) do
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Devour\\DevourEffectArt.mdl", target, "chest"))
                        DamageTarget(pt.target, target, thistype.dmg(pt.pid) * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end

                    DestroyGroup(ug)
                end

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                SetUnitFlyHeight(pt.target, 0, 0)
                reselect(pt.target)
                SetUnitTimeScale(pt.target, 1.)
                SetUnitPropWindow(pt.target, bj_DEGTORAD * 60.)
                SetUnitPathing(pt.target, true)
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            --minimum distance
            local dur = math.max(DistanceCoords(self.x, self.y, self.targetX, self.targetY), 400.) ---@type number 

            self.x = self.x + dur * Cos(self.angle)
            self.y = self.y + dur * Sin(self.angle)

            DamageTarget(self.caster, self.caster, 0.1 * BlzGetUnitMaxHP(self.caster), ATTACK_TYPE_NORMAL, PURE, thistype.tag)

            pt.angle = self.angle
            pt.dur = dur
            pt.dist = dur
            pt.speed = 40.
            pt.target = self.caster
            pt.x = self.x
            pt.y = self.y

            if UnitAddAbility(self.caster, FourCC('Amrf')) then
                UnitRemoveAbility(self.caster, FourCC('Amrf'))
            end

            SetUnitTimeScale(self.caster, 0.75)
            SetUnitPathing(self.caster, false)
            SetUnitPropWindow(self.caster, 0)
            DelayAnimation(self.pid, self.caster, (pt.dur / 30. * FPS_32) + 0.5, 1, 0, false)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class BLOODCURDLINGSCREAM : Spell
    ---@field aoe number
    ---@field dur function
    BLOODCURDLINGSCREAM = Spell.define("A06H")
    do
        local thistype = BLOODCURDLINGSCREAM

        thistype.values = {
            aoe = 500.,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 6 end,
        }

        function thistype:onCast()
            local ug = CreateGroup()

            DamageTarget(self.caster, self.caster, 0.1 * BlzGetUnitMaxHP(self.caster), ATTACK_TYPE_NORMAL, PURE, thistype.tag)
            MakeGroupInRange(self.pid, ug, self.x, self.y, thistype.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            for target in each(ug) do
                BloodCurdlingScreamDebuff:add(self.caster, target):duration(self.dur * LBOOST[self.pid])
            end

            DestroyGroup(ug)
        end
    end

    ---@class BLOODCLEAVE : Spell
    ---@field chance number
    ---@field aoe function
    ---@field dmg function
    BLOODCLEAVE = Spell.define("A05X")
    do
        local thistype = BLOODCLEAVE

        thistype.values = {
            chance = 20.,
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 195. + 5. * ablev end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.45 + 0.05 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local chance = BLOODCLEAVE.chance
            local double = 1

            if RampageBuff:has(source, source) then
                chance = chance + 5
            end

            if UndyingRageBuff:has(source, source) then
                chance = chance * 2
                double = 2
            end

            if math.random() * 100. < chance * LBOOST[pid] then
                local heal = 0
                local ug = CreateGroup()
                MakeGroupInRange(pid, ug, GetUnitX(source), GetUnitY(source), BLOODCLEAVE.aoe(pid) * LBOOST[pid], Condition(FilterEnemy))
                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Reapers Claws Red.mdx", source, "chest"))

                for u in each(ug) do
                    local cd = (math.random() * 100. < Unit[source].cc and (1. + Unit[source].cd * 0.01)) or 1
                    DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", u, "chest"))
                    heal = heal + BLOODCLEAVE.dmg(pid) * BOOST[pid] * ApplyArmorMult(source, target, PHYSICAL) * cd * Unit[source].pm
                    DamageTarget(source, u, BLOODCLEAVE.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, PHYSICAL, BLOODCLEAVE.tag)
                end

                DestroyGroup(ug)

                --leech health
                HP(source, source, heal * double, BLOODCLEAVE.tag)
            end
        end

        function thistype.onLearn(source, ablev, pid)
            if ablev == 1 then
                EVENT_ON_HIT:register_unit_action(source, onHit)
            end
        end
    end

    ---@class RAMPAGE : Spell
    ---@field pen function
    RAMPAGE = Spell.define("A0GZ")
    do
        local thistype = RAMPAGE
        thistype.pen = function(pid) return (5 * GetUnitAbilityLevel(Hero[pid], RAMPAGE.id)) end

        function thistype:onCast()
            RampageBuff:add(self.caster, self.caster)
        end
    end

    ---@class UNDYINGRAGE : Spell
    ---@field dur number
    ---@field regen number[]
    ---@field attack number[]
    ---@field timer TimerQueue[]
    ---@field onHit function
    UNDYINGRAGE = Spell.define("A0AD")
    do
        local thistype = UNDYINGRAGE

        thistype.values = {
            dur = 10.,
            regen = __jarray(0),
            attack = __jarray(0),
        }
        thistype.timer = {}

        local function regen(pid)
            local hp = GetWidgetLife(Hero[pid])
            local maxhp = BlzGetUnitMaxHP(Hero[pid])
            thistype.regen[pid] = R2I(GetHeroStr(Hero[pid], true) - (hp / maxhp) * GetHeroStr(Hero[pid], true))
            return thistype.regen[pid]
        end

        local function attack(pid)
            local hp = GetWidgetLife(Hero[pid])
            local maxhp = BlzGetUnitMaxHP(Hero[pid])
            local base = BlzGetUnitBaseDamage(Hero[pid], 0)
            local bonus = UnitGetBonus(Hero[pid], BONUS_DAMAGE)
            thistype.attack[pid] = R2I((base + bonus) - (hp / maxhp) * (base + bonus))
            return thistype.attack[pid]
        end

        --updates bonus attack and regen periodically
        local function refresh(pid)
            local u = Hero[pid]

            if HeroID[pid] ~= 0 then
                UnitAddBonus(u, BONUS_DAMAGE, -thistype.attack[pid])
                Unit[u].regen = Unit[u].regen - thistype.regen[pid]
            else
                thistype.attack[pid] = 0
                thistype.regen[pid] = 0
                thistype.timer[pid]:destroy()
                thistype.timer[pid] = nil
                return
            end

            UnitAddBonus(u, BONUS_DAMAGE, attack(pid))
            Unit[u].regen = Unit[u].regen + regen(pid)

            thistype.timer[pid]:callDelayed(0.25, refresh, pid)
        end

        function thistype:onCast()
            UndyingRageBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end

        function thistype.onLearn(source, ablev, pid)
            if not thistype.timer[pid] then
                thistype.timer[pid] = TimerQueue.create()
                thistype.timer[pid]:callDelayed(0.01, refresh, pid)
            end
        end

        function thistype.onHit(target, source, amount, amount_after_red, damage_type)
            --undying rage delayed damage
            buff = UndyingRageBuff:get(nil, target)

            if buff then
                amount.value = 0.
                buff:addRegen(-amount_after_red)
            end
        end
    end

    --warrior

    ---@class PARRY : Spell
    ---@field dmg function
    PARRY = Spell.define("A0AI")
    do
        local thistype = PARRY

        thistype.values = {
            dmg = function(pid) return 1. * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
        }
    end

    ---@class SPINDASH : Spell
    ---@field dmg function
    SPINDASH = Spell.define("A0EE")
    do
        local thistype = SPINDASH
        thistype.preCast = DASH_PRECAST

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.7 + 0.2 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function recastExpire(pt)
            BlzStartUnitAbilityCooldown(pt.source, thistype.id, 3.)
            BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(pt.source, thistype.id), ABILITY_ILF_TARGET_TYPE, GetUnitAbilityLevel(pt.source, thistype.id) - 1, 2)

            pt:destroy()
        end

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - pt.speed

            if pt.dur > 0. and IsUnitInRangeXY(pt.source, pt.x, pt.y, pt.dur + 50.) then
                local x = GetUnitX(pt.source)
                local y = GetUnitY(pt.source)
                SetUnitXBounded(pt.source, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.source, y + pt.speed * Sin(pt.angle))

                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, x, y, 225. * LBOOST[pt.pid], Condition(FilterEnemy))

                for target in each(ug) do
                    if not IsUnitInGroup(target, pt.ug) then
                        GroupAddUnit(pt.ug, target)
                        if limitBreak[pt.pid] & 0x2 > 0 then
                            DamageTarget(pt.source, target, thistype.dmg(pt.pid) * 4. * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                            SpinDashDebuff:add(pt.source, target):duration(2.)
                        else
                            DamageTarget(pt.source, target, thistype.dmg(pt.pid) * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                        end
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                SetUnitPropWindow(pt.source, bj_DEGTORAD * 60.)
                SetUnitTimeScale(pt.source, 1.)
                AddUnitAnimationProperties(pt.source, "spin", false)
                SetUnitPathing(pt.source, true)
                IssueImmediateOrderById(pt.source, ORDER_ID_STOP)
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(ADAPTIVESTRIKE.id)
            UnitDisableAbility(self.caster, ADAPTIVESTRIKE.id, false)

            if limitBreak[self.pid] & 0x10 > 0 and not pt then
                ADAPTIVESTRIKE.effect(self.caster, self.x, self.y)
                UnitDisableAbility(self.caster, ADAPTIVESTRIKE.id, true)
                BlzUnitHideAbility(self.caster, ADAPTIVESTRIKE.id, false)
            elseif pt then
                BlzStartUnitAbilityCooldown(self.caster, ADAPTIVESTRIKE.id, TimerGetRemaining(pt.timer.timer))
            end

            pt = TimerList[self.pid]:get('recast', self.caster)

            --recast
            if pt then
                self.targetX = pt.x
                self.targetY = pt.y
                self.angle = Atan2(pt.y - self.y, pt.x - self.x)
                SetUnitPropWindow(pt.source, bj_DEGTORAD * 60.)
                SetUnitTimeScale(pt.source, 1.)
                AddUnitAnimationProperties(pt.source, "spin", false)
                SetUnitPathing(pt.source, true)
                IssueImmediateOrderById(pt.source, ORDER_ID_STOP)

                BlzStartUnitAbilityCooldown(pt.source, thistype.id, 3. + TimerGetRemaining(pt.timer.timer))
                BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(pt.source, thistype.id), ABILITY_ILF_TARGET_TYPE, GetUnitAbilityLevel(pt.source, thistype.id) - 1, 2)

                pt:destroy()

                --if still moving
                pt = TimerList[self.pid]:get(thistype.id, self.caster)
                if pt then
                    pt:destroy()
                end
            --first cast
            else
                pt = TimerList[self.pid]:add()
                pt.x = self.x
                pt.y = self.y
                pt.source = self.caster
                pt.tag = 'recast'

                BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(pt.source, thistype.id), ABILITY_ILF_TARGET_TYPE, GetUnitAbilityLevel(pt.source, thistype.id) - 1, 0)

                pt.timer:callDelayed(3., recastExpire, pt)
            end

            pt = TimerList[self.pid]:add()
            pt.x = self.targetX
            pt.y = self.targetY
            pt.angle = self.angle
            pt.dur = math.min(1000., DistanceCoords(self.x, self.y, pt.x, pt.y))
            pt.speed = 40.
            pt.source = self.caster
            pt.ug = CreateGroup()
            pt.tag = thistype.id

            SetUnitPropWindow(self.caster, 0)
            SetUnitTimeScale(self.caster, 2.)
            AddUnitAnimationProperties(self.caster, "spin", true)
            SetUnitPathing(self.caster, false)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class INTIMIDATINGSHOUT : Spell
    ---@field aoe number
    ---@field dur number
    INTIMIDATINGSHOUT = Spell.define("A00L")
    do
        local thistype = INTIMIDATINGSHOUT

        thistype.values = {
            aoe = 500.,
            dur = 3.,
        }

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(ADAPTIVESTRIKE.id)
            UnitDisableAbility(self.caster, ADAPTIVESTRIKE.id, false)

            if limitBreak[self.pid] & 0x10 > 0 and not pt then
                ADAPTIVESTRIKE.effect(self.caster, self.x, self.y)
                UnitDisableAbility(self.caster, ADAPTIVESTRIKE.id, true)
                BlzUnitHideAbility(self.caster, ADAPTIVESTRIKE.id, false)
            elseif pt then
                BlzStartUnitAbilityCooldown(self.caster, ADAPTIVESTRIKE.id, TimerGetRemaining(pt.timer.timer))
            end

            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            local effect

            if limitBreak[self.pid] & 0x4 > 0 then
                effect = AddSpecialEffectTarget("war3mapImported\\BattleCryCaster.mdx", self.caster, "origin")
                BlzSetSpecialEffectColor(effect, 255, 255, 0)
            else
                effect = AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", self.caster, "origin")
            end

            DestroyEffect(effect)

            for target in each(ug) do
                IntimidatingShoutDebuff:add(self.caster, target):duration(self.dur * LBOOST[self.pid])
            end

            DestroyGroup(ug)
        end
    end

    ---@class WINDSCAR : Spell
    ---@field dmg function
    WINDSCAR = Spell.define("A001")
    do
        local thistype = WINDSCAR

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.7 + 0.1 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local x = GetUnitX(pt.target) ---@type number 
            local y = GetUnitY(pt.target) ---@type number 

            pt.dur = pt.dur + 0.05

            if (pt.dur > 1. and not pt.limitbreak) or (pt.dur > 5. and pt.limitbreak) then
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            else
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

                for target in each(ug) do
                    if not IsUnitInGroup(target, pt.ug) then
                        GroupAddUnit(pt.ug, target)
                        TimerQueue:callDelayed(1., GroupRemoveUnit, pt.ug, target)
                        DamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end
                end

                if pt.limitbreak then
                    pt.angle = pt.angle + bj_PI * 0.045
                    SetUnitXBounded(pt.target, GetUnitX(pt.source) + 150. * Cos(pt.angle))
                    SetUnitYBounded(pt.target, GetUnitY(pt.source) + 150. * Sin(pt.angle))
                    BlzSetUnitFacingEx(pt.target, bj_RADTODEG * (pt.angle + bj_PI * 0.5))
                else
                    pt.curve:calcT(pt.dur)
                    SetUnitXBounded(pt.target, pt.curve.X)
                    SetUnitYBounded(pt.target, pt.curve.Y)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            end
        end

        ---@type fun(pt: PlayerTimer)
        local function delay(pt)
            local angle      = 0. ---@type number 
            local pt2

            if limitBreak[pt.pid] & 0x8 > 0 then
                for i = 0, 3 do
                    pt2 = TimerList[pt.pid]:add()
                    pt2.ug = CreateGroup()
                    pt2.aoe = 120.
                    pt2.angle = 2. * bj_PI / 3. * i
                    pt2.source = pt.source
                    pt2.target = Dummy.create(GetUnitX(pt.source) + 150. * Cos(pt2.angle), GetUnitY(pt.source) + 150. * Sin(pt2.angle), 0, 0).unit
                    pt2.dmg = thistype.dmg(pt.pid)
                    pt2.limitbreak = true

                    BlzSetUnitSkin(pt2.target, FourCC('h044'))
                    SetUnitScale(pt2.target, 0.6, 0.6, 0.6)
                    UnitAddAbility(pt2.target, FourCC('Amrf'))
                    SetUnitFlyHeight(pt2.target, 30.00, 0.00)
                    BlzSetUnitFacingEx(pt2.target, bj_RADTODEG * (pt2.angle + bj_PI * 0.5))
                    SetUnitVertexColor(pt2.target, 255, 255, 0, 255)

                    pt2.timer:callDelayed(FPS_32, periodic, pt2)
                end
            else
                SoundHandler("Abilities\\Spells\\Orc\\Shockwave\\Shockwave.flac", true, nil, pt.source)

                angle = pt.angle

                for i = -1, 1 do
                    pt2 = TimerList[pt.pid]:add()
                    pt2.ug = CreateGroup()
                    pt2.aoe = 150.
                    pt2.angle = angle + i / 4. * bj_PI
                    pt2.target = Dummy.create(GetUnitX(pt.source) + 100. * Cos(pt2.angle), GetUnitY(pt.source) + 100. * Sin(pt2.angle), 0, 0).unit
                    pt2.x = GetUnitX(pt2.target)
                    pt2.y = GetUnitY(pt2.target)
                    pt2.speed = 700.
                    pt2.dmg = thistype.dmg(pt.pid)
                    pt2.curve = BezierCurve.create()
                    pt2.limitbreak = false
                    --add bezier points
                    pt2.curve:addPoint(pt2.x, pt2.y)
                    pt2.curve:addPoint(pt2.x + pt2.speed * 0.6 * Cos(pt2.angle), pt2.y + pt2.speed * 0.6 * Sin(pt2.angle))
                    pt2.curve:addPoint(pt2.x + pt2.speed * Cos(angle), pt2.y + pt2.speed * Sin(angle))

                    BlzSetUnitSkin(pt2.target, FourCC('h044'))
                    SetUnitScale(pt2.target, 1., 1., 1.)
                    UnitAddAbility(pt2.target, FourCC('Amrf'))
                    SetUnitFlyHeight(pt2.target, 10.00, 0.00)
                    BlzSetUnitFacingEx(pt2.target, bj_RADTODEG * pt2.angle)

                    pt2.timer:callDelayed(FPS_32, periodic, pt2)
                end

                SetUnitTimeScale(pt.source, 1.)
            end

            pt:destroy()
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(ADAPTIVESTRIKE.id)  
            UnitDisableAbility(self.caster, ADAPTIVESTRIKE.id, false)

            if limitBreak[self.pid] & 0x10 > 0 and not pt then
                ADAPTIVESTRIKE.effect(self.caster, self.x, self.y)
                UnitDisableAbility(self.caster, ADAPTIVESTRIKE.id, true)
                BlzUnitHideAbility(self.caster, ADAPTIVESTRIKE.id, false)
            elseif pt then
                BlzStartUnitAbilityCooldown(self.caster, ADAPTIVESTRIKE.id, TimerGetRemaining(pt.timer.timer))
            end

            TimerQueue:callDelayed(1., DestroyEffect, AddSpecialEffectTarget("war3mapImported\\Sweep_Wind_Medium.mdx", self.caster, "Weapon"))

            pt = TimerList[self.pid]:add()
            pt.source = self.caster

            if limitBreak[self.pid] & 0x8 > 0 then
                BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(Hero[self.pid], WINDSCAR.id), ABILITY_ILF_TARGET_TYPE, self.ablev - 1, 0)

                pt.timer:callDelayed(0., delay, pt)
                SetUnitAnimation(self.caster, "stand")
            else
                SetUnitAnimation(self.caster, "attack slam")
                SetUnitTimeScale(self.caster, 1.5)
                pt.angle = self.angle
                pt.timer:callDelayed(0.4, delay, pt)
            end
        end

        function thistype.onLearn(source, ablev, pid)
            if limitBreak[pid] & 0x8 > 0 then
                BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(source, thistype.id), ABILITY_ILF_TARGET_TYPE, ablev - 1, 0)
            end
        end
    end

    ---@class ADAPTIVESTRIKE : Spell
    ---@field spindmg function
    ---@field spinaoe number
    ---@field spinheal function
    ---@field knockaoe number
    ---@field knockdur number
    ---@field shoutaoe number
    ---@field shoutdur number
    ---@field tornadodmg function
    ---@field tornadodur number
    ---@field effect function
    ADAPTIVESTRIKE = Spell.define("A0AH")
    do
        local thistype = ADAPTIVESTRIKE

        thistype.values = {
            spindmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (1. + 0.2 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
            spinaoe = 400.,
            spinheal = function(pid) return 10. * Unit[Hero[pid]].regen end,

            knockaoe = 300.,
            knockdur = 1.5,
            shoutaoe = 900.,
            shoutdur = 4.,

            tornadodmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.35 + 0.05 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end,
            tornadodur = 3.,
        }

        ---@type fun(pt: PlayerTimer)
        local function tornado(pt)
            pt.time = pt.time + 0.5

            if pt.time >= pt.dur then
                IssueImmediateOrderById(pt.target, ORDER_ID_STOP)
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            else
                local x = GetUnitX(pt.target)
                local y = GetUnitY(pt.target)

                IssuePointOrder(pt.target, "move", x + 75. * Cos(pt.angle), y + 75. * Sin(pt.angle))

                if ModuloReal(pt.time + 0.5, 1.) == 0. then
                    local ug = CreateGroup()
                    MakeGroupInRange(pt.pid, ug, x, y, 200., Condition(FilterEnemy))

                    for target in each(ug) do
                        DamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end

                    DestroyGroup(ug)
                end

                pt.timer:callDelayed(0.5, tornado, pt)
            end
        end

        ---@type fun(caster: unit, x: number, y: number)
        function thistype.effect(caster, x, y)
            local pid = GetPlayerId(GetOwningPlayer(caster)) + 1
            local pt
            local ug = CreateGroup()

            if lastCast[pid] == PARRY.id then --spin heal
                SetUnitAnimation(caster, "spell")
                MakeGroupInRange(pid, ug, x, y, thistype.spinaoe * LBOOST[pid], Condition(FilterEnemy))

                local dummy = Dummy.create(x, y, 0, 0, 1.).unit
                BlzSetUnitSkin(dummy, FourCC('h074'))
                SetUnitTimeScale(dummy, 1.)
                SetUnitScale(dummy, 1.25, 1.25, 1.25)
                SetUnitAnimationByIndex(dummy, 0)
                SetUnitFlyHeight(dummy, 100., 0)
                BlzSetUnitFacingEx(dummy, GetUnitFacing(caster))

                dummy = Dummy.create(x, y, 0, 0, 1.).unit
                BlzSetUnitSkin(dummy, FourCC('h074'))
                SetUnitTimeScale(dummy, 1.)
                SetUnitScale(dummy, 1.25, 1.25, 1.25)
                SetUnitAnimationByIndex(dummy, 0)
                SetUnitFlyHeight(dummy, 100., 0)
                BlzSetUnitFacingEx(dummy, GetUnitFacing(caster) + 180.)

                for target in each(ug) do
                    DamageTarget(caster, target, thistype.spindmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                HP(caster, caster, thistype.spinheal(pid) * BOOST[pid], thistype.tag)
            elseif lastCast[pid] == SPINDASH.id then --knock up
                SetUnitAnimationByIndex(caster, 4)
                DelayAnimation(pid, caster, 0.6, 0, 1., false)
                MakeGroupInRange(pid, ug, x, y, thistype.knockaoe * LBOOST[pid], Condition(FilterEnemy))

                for target in each(ug) do
                    KnockUp:add(caster, target):duration(thistype.knockdur * LBOOST[pid])
                end

                local sfx = AddSpecialEffect("war3mapImported\\DustWindFaster3.mdx", x - 110., y)
                BlzSetSpecialEffectPitch(sfx, bj_PI * 0.5)

                SoundHandler("Abilities\\Spells\\NightElf\\Cyclone\\CycloneBirth1.flac", true, nil, caster)

                DestroyEffect(sfx)
            elseif lastCast[pid] == INTIMIDATINGSHOUT.id then --ally attack damage buff
                MakeGroupInRange(pid, ug, x, y, thistype.shoutaoe * LBOOST[pid], Condition(FilterAlly))

                for target in each(ug) do
                    IntimidatingShoutBuff:add(caster, target):duration(thistype.shoutdur * LBOOST[pid])
                end

                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\BattleCryCaster.mdx", caster, "origin"))
            elseif lastCast[pid] == WINDSCAR.id then --5 tornadoes
                for i = 0, 4 do
                    pt = TimerList[pid]:add()
                    pt.angle = bj_PI * 0.4 * i
                    pt.target = Dummy.create(x + 75. * Cos(pt.angle), y + 75 * Sin(pt.angle), 0, 0).unit
                    pt.dmg = thistype.tornadodmg(pid)
                    pt.dur = thistype.tornadodur * LBOOST[pid]

                    SetUnitPathing(pt.target, false)
                    BlzSetUnitSkin(pt.target, FourCC('n001'))
                    SetUnitMoveSpeed(pt.target, 100.)
                    SetUnitScale(pt.target, 0.5, 0.5, 0.5)
                    UnitAddAbility(pt.target, FourCC('Amrf'))
                    IssuePointOrder(pt.target, "move", x + 225. * Cos(pt.angle), y + 225. * Sin(pt.angle))

                    pt.timer:callDelayed(0.5, tornado, pt)
                end
            end

            UnitDisableAbility(caster, thistype.id, true)
            BlzUnitHideAbility(caster, thistype.id, false)

            --adaptive strike cooldown reset
            local rand = math.random() ---@type number

            --empowered adaptive strike 50 percent
            if limitBreak[pid] & 0x10 > 0 then
                rand = rand * 1.5
            end

            if rand < 0.75 then
                pt = TimerList[pid]:add()
                pt.tag = thistype.id
                pt.timer:callDelayed(4., PlayerTimer.destroy, pt)
            end
            DestroyGroup(ug)
        end

        function thistype:onCast()
            thistype.effect(self.caster, self.x, self.y)
        end

        function thistype.onLearn(source, ablev, pid)
            if ablev == 1 then
                UnitDisableAbility(source, thistype.id, true)
                BlzUnitHideAbility(source, thistype.id, false)
            end
        end
    end

    ---@class LIMITBREAK : Spell
    LIMITBREAK = Spell.define("A02R")
    do
        local thistype = LIMITBREAK

        function thistype:onCast()
            if GetLocalPlayer() == Player(self.pid - 1) then
                if BlzFrameIsVisible(LimitBreakBackdrop) then
                    BlzFrameSetVisible(LimitBreakBackdrop, false)
                else
                    BlzFrameSetVisible(LimitBreakBackdrop, true)
                end
            end
        end

        function thistype.onLearn(source, ablev, pid)
            limitBreakPoints[pid] = math.min(2, limitBreakPoints[pid] + 1)
            if GetLocalPlayer() == GetOwningPlayer(source) then
                BlzFrameSetVisible(LimitBreakBackdrop, true)
            end
        end
    end

    --hydromancer

    ---@class INFUSEDWATER : Spell
    INFUSEDWATER = Spell.define("A0DY")
    do
        local thistype = INFUSEDWATER

        function thistype:onCast()
            InfusedWaterBuff:add(self.caster, self.caster):duration(5)
        end
    end

    ---@class FROSTBLAST : Spell
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    FROSTBLAST = Spell.define("A0GI")
    do
        local thistype = FROSTBLAST

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 1. * ablev * GetHeroInt(Hero[pid], true) end,
            aoe = 250.,
            dur = 4.,
        }

        function thistype:onCast()
            local missile = Missiles:create(self.x, self.y, 30., 0, 0, 0) ---@type Missiles
            missile:model("Abilities\\Spells\\Other\\FrostBolt\\FrostBoltMissile.mdl")
            missile:scale(1.1)
            missile:speed(1200)
            missile.source = self.caster
            missile.target = self.target
            missile.owner = Player(self.pid - 1)
            missile:vision(400)
            missile.collision = 50
            missile.damage = self.dmg * BOOST[self.pid]
            missile.collideZ = true

            missile.onHit = function(target)
                if target == missile.target then
                    local ug = CreateGroup()
                    local pid = GetPlayerId(missile.owner) + 1
                    MakeGroupInRange(pid, ug, GetUnitX(target), GetUnitY(target), FROSTBLAST.aoe * LBOOST[pid], Condition(FilterEnemy))

                    local b = InfusedWaterBuff:get(nil, missile.source)
                    if b then
                        b:dispel()
                        missile.damage = missile.damage * 2
                    end

                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", GetUnitX(target), GetUnitY(target)))

                    for enemy in each(ug) do
                        if enemy == target then
                            Freeze:add(missile.source, target):duration(FROSTBLAST.dur * LBOOST[pid])
                            DamageTarget(missile.source, enemy, missile.damage * (GetUnitAbilityLevel(enemy, FourCC('B01G')) + 1.), ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                        else
                            Freeze:add(missile.source, target):duration(FROSTBLAST.dur * 0.5 * LBOOST[pid])
                            DamageTarget(missile.source, enemy, missile.damage / (2. - (GetUnitAbilityLevel(enemy, FourCC('B01G')))), ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                        end
                    end

                    DestroyGroup(ug)

                    return true
                end

                return false
            end

            missile:launch()
        end
    end

    ---@class WHIRLPOOL : Spell
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    WHIRLPOOL = Spell.define("A03X")
    do
        local thistype = WHIRLPOOL
        thistype.preCast = TERRAIN_PRECAST

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.25 * ablev * GetHeroInt(Hero[pid], true) end,
            aoe = 330.,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2. + 2. * ablev end,
        }

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.count = pt.count + 1
            pt.dur = pt.dur - FPS_32

            if pt.dur > 0. then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

                pt.dur = pt.dur - 0.0015 * IMinBJ(BlzGroupGetSize(ug), 20)

                local angle

                for target in each(ug) do
                    --movement effects
                    angle = Atan2(pt.y - GetUnitY(target), pt.x - GetUnitX(target))

                    if IsUnitType(target, UNIT_TYPE_HERO) == false and GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Cos(angle), GetUnitY(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Sin(angle)) then
                        SetUnitPathing(target, false)
                        SetUnitXBounded(target, GetUnitX(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Cos(angle))
                        SetUnitYBounded(target, GetUnitY(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Sin(angle))
                    end
                    SetUnitPathing(target, true)

                    if ModuloInteger(pt.count, 32) == 0 then
                        DamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end

                    SoakedDebuff:add(Hero[pt.pid], target):duration(5.)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            elseif pt.dur <= 0 then
                SetUnitAnimation(pt.source, "death")
                SetUnitAnimation(pt.target, "death")
                TimerQueue:callDelayed(3., DestroyEffect, AddSpecialEffect("Objects\\Spawnmodels\\Naga\\NagaDeath\\NagaDeath.mdl", pt.x, pt.y))
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dmg = self.dmg
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dur = self.dur * LBOOST[self.pid]
            pt.x = self.targetX
            pt.y = self.targetY
            pt.count = 0

            local b = InfusedWaterBuff:get(nil, self.caster)

            if b then
                b:dispel()
                pt.dur = pt.dur + 3
            end

            pt.source = Dummy.create(pt.x, pt.y, 0, 0, pt.dur + 1.).unit
            BlzSetUnitSkin(pt.source, FourCC('h01I'))
            SetUnitTimeScale(pt.source, 1.3)
            SetUnitScale(pt.source, 0.6, 0.6, 0.6)
            SetUnitAnimation(pt.source, "birth")
            SetUnitFlyHeight(pt.source, 50., 0)
            PauseUnit(pt.source, true)
            pt.target = Dummy.create(pt.x, pt.y, 0, 0, pt.dur + 1.).unit
            BlzSetUnitSkin(pt.target, FourCC('h01I'))
            SetUnitTimeScale(pt.target, 1.1)
            SetUnitScale(pt.target, 0.35, 0.35, 0.35)
            SetUnitAnimation(pt.target, "birth")
            SetUnitFlyHeight(pt.target, 50., 0)
            SetUnitVertexColor(pt.target, 255, 255, 255, 100)
            PauseUnit(pt.target, true)

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class TIDALWAVE : Spell
    ---@field range function
    TIDALWAVE = Spell.define("A077")
    do
        local thistype = TIDALWAVE

        thistype.values = {
            range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 500. + 100. * ablev end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local Ax = pt.x + 250. * Cos(pt.angle + bj_PI * 5. / 8.)
            local Bx = pt.x + 250. * Cos(pt.angle + bj_PI * 3. / 8.)
            local Cx = pt.x + 250. * Cos(pt.angle - bj_PI * 3. / 8.)
            local Dx = pt.x + 250. * Cos(pt.angle - bj_PI * 5. / 8.)

            local Ay = pt.y + 250. * Sin(pt.angle + bj_PI * 5. / 8.)
            local By = pt.y + 250. * Sin(pt.angle + bj_PI * 3. / 8.)
            local Cy = pt.y + 250. * Sin(pt.angle - bj_PI * 3. / 8.)
            local Dy = pt.y + 250. * Sin(pt.angle - bj_PI * 5. / 8.)

            local AB = 0.
            local BC = 0.
            local CD = 0.
            local DA = 0.

            pt.dist = pt.dist - 20
            pt.time = pt.time + FPS_32

            if pt.time <= FPS_32 then
                SetUnitAnimation(pt.target, "stand")
            elseif pt.time >= 1. then
                SetUnitTimeScale(pt.target, 0.)
            end

            if pt.dist > 0. then
                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, 600., Condition(FilterEnemy))

                pt.x = pt.x + 20 * Cos(pt.angle)
                pt.y = pt.y + 20 * Sin(pt.angle)
                SetUnitXBounded(pt.target, pt.x)
                SetUnitYBounded(pt.target, pt.y)

                local x = 0.
                local y = 0.

                for target in each(ug) do
                    x = GetUnitX(target)
                    y = GetUnitY(target)

                    AB = (y - By) * (Ax - Bx) - (x - Bx) * (Ay - By)
                    BC = (y - Cy) * (Bx - Cx) - (x - Cx) * (By - Cy)
                    CD = (y - Dy) * (Cx - Dx) - (x - Dx) * (Cy - Dy)
                    DA = (y - Ay) * (Dx - Ax) - (x - Ax) * (Dy - Ay)

                    if (AB >= 0 and BC >= 0 and CD >= 0 and DA >= 0) or (AB <= 0 and BC <= 0 and CD <= 0 and DA <= 0) then
                        if IsUnitType(target, UNIT_TYPE_STRUCTURE) == false and GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(x, y) then
                            DestroyEffect(AddSpecialEffect("war3mapImported\\SlideWater.mdx", GetUnitX(target), GetUnitY(target)))
                            SetUnitXBounded(target, x + 17. * Cos(pt.angle))
                            SetUnitYBounded(target, y + 17. * Sin(pt.angle))
                        end

                        SoakedDebuff:add(Hero[pt.pid], target):duration(5.)
                        local b = TidalWaveDebuff:get(nil, target)

                        if not b then
                            b = TidalWaveDebuff:create(Hero[pt.pid], target)

                            if pt.infused then
                                b.percent = .20
                            end

                            b:check(Hero[pt.pid], target)

                            if IsUnitType(target, UNIT_TYPE_HERO) == true then
                                b:duration(5.)
                            else
                                b:duration(10.)
                            end
                        end
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                SetUnitTimeScale(pt.target, 2.)
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.angle = self.angle
            pt.dist = self.range * LBOOST[self.pid]
            pt.target = Dummy.create(self.x, self.y, 0, 0).unit
            pt.x = self.x
            pt.y = self.y
            pt.infused = false

            local b = InfusedWaterBuff:get(nil, self.caster)
            if b then
                b:dispel()
                pt.infused = true
            end

            BlzSetUnitSkin(pt.target, FourCC('h04X'))
            SetUnitAnimation(pt.target, "birth")
            SetUnitScale(pt.target, 0.8, 0.8, 0.8)
            BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class BLIZZARD : Spell
    ---@field aoe function
    ---@field dmg function
    ---@field dur function
    BLIZZARD = Spell.define("A08E")
    do
        local thistype = BLIZZARD

        thistype.values = {
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 175. + 25. * ablev end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.25 * ablev * GetHeroInt(Hero[pid], true) end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 3 end,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local pt = TimerList[pid]:get(BLIZZARD.id, source)

            if pt then
                local dmg = pt.dmg
                if pt.infused then
                    dmg = dmg * 1.3
                end
                DamageTarget(source, target, dmg * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, BLIZZARD.tag)
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            pt.dur = self.dur * LBOOST[self.pid]

            local dummy = Dummy.create(self.x, self.y, FourCC('A02O'), 1, pt.dur + 3.)
            dummy.source = self.caster
            pt.source = dummy.unit
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dmg = self.dmg
            pt.tag = thistype.id
            pt.infused = false

            BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(pt.source, FourCC('A02O')), ABILITY_ILF_NUMBER_OF_WAVES, 0, pt.dur // 0.6)
            BlzSetAbilityRealLevelField(BlzGetUnitAbility(pt.source, FourCC('A02O')), ABILITY_RLF_AREA_OF_EFFECT, 0, pt.aoe)
            IncUnitAbilityLevel(pt.source, FourCC('A02O'))
            DecUnitAbilityLevel(pt.source, FourCC('A02O'))
            SetUnitOwner(pt.source, Player(self.pid - 1), true)

            local b = InfusedWaterBuff:get(nil, self.caster)
            if b then
                b:dispel()
                pt.infused = true
            end

            IssuePointOrder(pt.source, "blizzard", self.targetX, self.targetY)
            EVENT_DUMMY_ON_HIT:register_unit_action(pt.source, onHit)

            pt.timer:callDelayed(pt.dur, PlayerTimer.destroy, pt)
        end
    end

    ---@class ICEBARRAGE : Spell
    ---@field times function
    ---@field dmg function
    ICEBARRAGE = Spell.define("A098")
    do
        local thistype = ICEBARRAGE

        thistype.values = {
            times = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 12. + 4. * ablev end,
            dmg = function(pid) return GetHeroInt(Hero[pid], true) * 0.5 end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.time = (pt.time + 0.01) * 1.1 --acceleration

            if pt.time < 1. then
                pt.curve:calcT(pt.time)
                SetUnitXBounded(pt.source, pt.curve.X)
                SetUnitYBounded(pt.source, pt.curve.Y)
                pt.curve:calcT(pt.time + 0.01)
                local angle = Atan2(pt.curve.Y - GetUnitY(pt.source), pt.curve.X - GetUnitX(pt.source))
                BlzSetUnitFacingEx(pt.source, bj_RADTODEG * angle)

                if pt.time < 0.28 then
                    SetUnitFlyHeight(pt.source, GetUnitFlyHeight(pt.source) + GetRandomReal(15., 20.), 0.)
                elseif pt.time > 0.35 then
                    SetUnitFlyHeight(pt.source, GetUnitFlyHeight(pt.source) - pt.time * 40, 0.)
                end

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                SetUnitXBounded(pt.source, GetUnitX(pt.target))
                SetUnitYBounded(pt.source, GetUnitY(pt.target))
                SetUnitAnimation(pt.source, "death")
                if pt.infused then
                    Stun:add(Hero[pt.pid], pt.target):duration(0.25)
                end

                if SoakedDebuff:has(nil, pt.target) then
                    DamageTarget(Hero[pt.pid], pt.target, pt.dmg * 2. * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                else
                    DamageTarget(Hero[pt.pid], pt.target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end
                pt:destroy()
            end
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.onSpawn(pt)
            pt.time = pt.time + 1

            if pt.time <= pt.dur then
                local x = GetUnitX(pt.source)
                local y = GetUnitY(pt.source)
                local angle = Atan2(GetUnitY(pt.target) - y, GetUnitX(pt.target) - x) + bj_DEGTORAD * (180 + GetRandomInt(-60, 60))

                local pt2 = TimerList[pt.pid]:add()
                pt2.source = Dummy.create(x + 100. * Cos(angle), y + 100. * Sin(angle), 0, 0).unit
                pt2.target = pt.target
                pt2.dmg = thistype.dmg(pt.pid)
                pt2.infused = pt.infused

                BlzSetUnitSkin(pt2.source, FourCC('h071'))
                SetUnitScale(pt2.source, 0.6, 0.6, 0.6)
                SetUnitFlyHeight(pt2.source, 150.00, 0.00)

                pt2.curve = BezierCurve.create()
                --add bezier points
                pt2.curve:addPoint(x + 100. * Cos(angle), y + 100. * Sin(angle))
                pt2.curve:addPoint(x + 600. * Cos(angle), y + 600. * Sin(angle))
                pt2.curve:addPoint(GetUnitX(pt.target), GetUnitY(pt.target))

                pt.timer:callDelayed(0.05, thistype.onSpawn, pt)
                pt2.timer:callDelayed(FPS_32, periodic, pt2)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.source = self.caster
            pt.target = self.target
            pt.dur = self.times * LBOOST[self.pid]
            pt.infused = false
            pt.time = 0

            local b = InfusedWaterBuff:get(nil, self.caster)
            if b then
                b:dispel()
                pt.infused = true
            end

            pt.timer:callDelayed(0.05, thistype.onSpawn, pt)
        end
    end

    --vampire

    ---@class BLOODBANK : Spell
    ---@field gain function
    ---@field max function
    ---@field set function
    ---@field get function
    ---@field add function
    ---@field onHit function
    ---@field bank integer[]
    ---@field refresh function
    BLOODBANK = Spell.define("A07K")
    do
        local thistype = BLOODBANK

        thistype.values = {
            gain = function(pid) return 0.75 * GetHeroStr(Hero[pid], true) end,
            max = function(pid) return 200. * GetHeroInt(Hero[pid], true) end,
            bank = __jarray(0),
        }

        function thistype.refresh(u)
            local pid = GetPlayerId(GetOwningPlayer(u)) + 1

            Unit[u].dr = Unit[u].dr / BLOODLORD.dr[pid]

            --blood bank visual
            local max = R2I(thistype.max(pid))
            local blood = math.min(thistype.get(pid), max)
            BlzSetUnitMaxMana(u, max)
            SetUnitState(u, UNIT_STATE_MANA, blood)
            BlzSetUnitRealField(u, UNIT_RF_MANA_REGENERATION, - GetHeroInt(u, true) * 0.05)

            local hp = blood / max * 5
            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetAbilityIcon(thistype.id, "ReplaceableTextures\\CommandButtons\\BTNSimpleHugePotion" .. (R2I(hp)) .. "_5.blp")
            end

            BLOODLORD.dr[pid] = 1
            BlzSetUnitAbilityCooldown(u, BLOODLEECH.id, GetUnitAbilityLevel(u, BLOODLEECH.id) - 1, 6.)
            BlzSetUnitAbilityCooldown(u, BLOODNOVA.id, GetUnitAbilityLevel(u, BLOODNOVA.id) - 1, 5.)
            BlzSetUnitAbilityCooldown(u, BLOODDOMAIN.id, GetUnitAbilityLevel(u, BLOODDOMAIN.id) - 1, 10.)

            if GetUnitAbilityLevel(u, BLOODLORD.id) > 0 then
                if GetHeroStr(u, true) >= GetHeroAgi(u, true) then
                    BLOODLORD.dr[pid] = (1 - 0.01 * (thistype.get(pid) / (GetHeroInt(u, true) * 10.)))

                    Unit[u].dr = Unit[u].dr * BLOODLORD.dr[pid]
                else
                    BlzSetUnitAbilityCooldown(u, BLOODLEECH.id, GetUnitAbilityLevel(u, BLOODLEECH.id) - 1, 3.)
                    BlzSetUnitAbilityCooldown(u, BLOODNOVA.id, GetUnitAbilityLevel(u, BLOODNOVA.id) - 1, 2.5)
                    BlzSetUnitAbilityCooldown(u, BLOODDOMAIN.id, GetUnitAbilityLevel(u, BLOODDOMAIN.id) - 1, 5.)
                end
            end
        end

        function thistype.set(pid, amount)
            thistype.values.bank[pid] = amount

            thistype.refresh(Hero[pid])

            return amount
        end

        function thistype.add(pid, amount)
            return thistype.set(pid, math.min(thistype.bank[pid] + amount, thistype.max(pid)))
        end

        function thistype.get(pid)
            return thistype.bank[pid]
        end

        function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            thistype.add(pid, thistype.gain(pid))
        end

        function thistype:setup(u)
            EVENT_ON_HIT:register_unit_action(u, onHit)
            EVENT_STAT_CHANGE:register_unit_action(u, thistype.refresh)
        end
    end

    ---@class BLOODLEECH : Spell
    ---@field gain function
    ---@field dmg function
    BLOODLEECH = Spell.define("A07A")
    do
        local thistype = BLOODLEECH

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (2.75 + 0.25 * ablev) * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end,
            gain = function(pid) return 10. * GetHeroAgi(Hero[pid], true) + 5. * GetHeroStr(Hero[pid], true) end,
        }

        function thistype:onCast()
            DamageTarget(self.caster, self.target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            BLOODBANK.add(self.pid, self.gain)
        end
    end

    ---@class BLOODDOMAIN : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field gain function
    BLOODDOMAIN = Spell.define("A09B")
    do
        local thistype = BLOODDOMAIN

        thistype.values = {
            aoe = 400.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.5 + 0.5 * ablev) * GetHeroAgi(Hero[pid], true) + (1.5 + 0.5 * ablev) * GetHeroStr(Hero[pid], true) end,
            gain = function(pid) return 1. * GetHeroAgi(Hero[pid], true) + 1. * GetHeroStr(Hero[pid], true) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local ablev = GetUnitAbilityLevel(pt.source, BLOODDOMAIN.id) ---@type integer 

            pt.dur = pt.dur - 1

            if pt.dur > 0. then
                local ug = CreateGroup()
                local ug2 = CreateGroup()
                MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), pt.aoe, Condition(FilterEnemyDead))
                MakeGroupInRange(pt.pid, ug2, GetUnitX(pt.source), GetUnitY(pt.source), pt.aoe, Condition(FilterEnemy))

                pt.dmg = math.max(thistype.dmg(pt.pid) * 0.2, thistype.dmg(pt.pid) * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug2) - 1)))
                pt.blood = math.max(thistype.gain(pt.pid) * 0.2, thistype.gain(pt.pid) * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug) - 1)))

                for target in each(ug) do
                    BLOODBANK.add(pt.pid, pt.blood)

                    if UnitAlive(target) then
                        DamageTarget(pt.source, target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end

                    local dummy = Dummy.create(GetUnitX(target), GetUnitY(target), FourCC('A09D'), 1)
                    dummy:attack(pt.source)
                end

                DestroyGroup(ug)
                DestroyGroup(ug2)

                pt.timer:callDelayed(1., periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            if GetHeroStr(self.caster, true) > GetHeroAgi(self.caster, true) and GetUnitAbilityLevel(self.caster, BLOODLORD.id) > 0 then
                pt.aoe = thistype.aoe * 2. * LBOOST[self.pid]
            else
                pt.aoe = thistype.aoe * LBOOST[self.pid]
            end

            local ug = CreateGroup()
            local ug2 = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, pt.aoe, Condition(FilterEnemyDead))
            MakeGroupInRange(self.pid, ug2, self.x, self.y, pt.aoe, Condition(FilterEnemy))

            pt.dur = 5.
            pt.dmg = math.max(self.dmg * 0.2, self.dmg * (1 - (0.17 - 0.02 * self.ablev) * (BlzGroupGetSize(ug2) - 1)))
            pt.blood = math.max(self.gain * 0.2, self.gain * (1 - (0.17 - 0.02 * self.ablev) * (BlzGroupGetSize(ug) - 1)))
            pt.source = self.caster

            for target in each(ug) do
                BLOODBANK.add(self.pid, pt.blood)

                if UnitAlive(target) then
                    DamageTarget(self.caster, target, pt.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    if GetHeroStr(self.caster, true) > GetHeroAgi(self.caster, true) and GetUnitAbilityLevel(self.caster, BLOODLORD.id) > 0 then
                        --TODO blood domain taunt?
                    end
                end

                local dummy = Dummy.create(GetUnitX(target), GetUnitY(target), FourCC('A09D'), 1)
                dummy:attack(self.caster)
            end

            pt.timer:callDelayed(1., periodic, pt)

            DestroyGroup(ug)
            DestroyGroup(ug2)
        end
    end

    ---@class BLOODMIST : Spell
    ---@field cost function
    ---@field heal function
    BLOODMIST = Spell.define("A093")
    do
        local thistype = BLOODMIST

        thistype.values = {
            cost = function(pid) return 16. * GetHeroInt(Hero[pid], true) end,
            heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.25 + 0.25 * ablev) * GetHeroStr(Hero[pid], true) + thistype.cost(pid) * 0.15 end,
        }
    end

    ---@class BLOODNOVA : Spell
    ---@field cost number
    ---@field dmg number
    ---@field aoe number
    BLOODNOVA = Spell.define("A09A")
    do
        local thistype = BLOODNOVA

        thistype.values = {
            cost = function(pid) return 40. * GetHeroInt(Hero[pid], true) end,
            dmg = function(pid) return 3. * GetHeroAgi(Hero[pid], true) + 2. * GetHeroStr(Hero[pid], true) + thistype.cost(pid) * 0.3 end,
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 225. + 25. * ablev end,
        }

        function thistype.preCast(pid, tpid, caster, target, x, y, targetX, targetY)
            if BLOODBANK.get(pid) < thistype.cost(pid) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "Not enough blood.")
            end
        end

        function thistype:onCast()
            if BLOODBANK.get(self.pid) >= self.cost then
                BLOODBANK.add(self.pid, -self.cost)

                local ug = CreateGroup()

                MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

                for target in each(ug) do
                    DamageTarget(self.caster, target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                local dummy = AddSpecialEffect("war3mapImported\\Death Nova.mdx", self.x, self.y)
                BlzSetSpecialEffectScale(dummy, 0.75 + 0.075 * self.ablev)
                DestroyEffect(dummy)

                DestroyGroup(ug)
            end
        end
    end

    ---@class BLOODLORD : Spell
    ---@field bonus function
    ---@field dmg function
    ---@field dur function
    ---@field dr number[]
    BLOODLORD = Spell.define("A097")
    do
        local thistype = BLOODLORD

        thistype.values = {
            bonus = function(pid) return BLOODBANK.get(pid) * 0.01 end,
            dmg = function(pid) return 0.75 * GetHeroAgi(Hero[pid], true) + 1. * GetHeroStr(Hero[pid], true) end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 9. + ablev end,
        }
        thistype.dr = __jarray(1) ---@type number[]

        function thistype:onCast()
            BloodLordBuff:add(self.caster, self.caster):duration(self.dur)
        end

        function thistype.onLearn(source)
            BLOODBANK.refresh(source)
        end
    end

    --high priestess

    ---@class INVIGORATION : Spell
    ---@field aoe number
    ---@field heal function
    ---@field mana function
    INVIGORATION = Spell.define("A0DU")
    do
        local thistype = INVIGORATION

        thistype.values = {
            aoe = 850.,
            heal = function(pid) return 0.15 * GetHeroInt(Hero[pid], true) end,
            mana = function(pid) return 0.02 * BlzGetUnitMaxMana(Hero[pid]) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local heal = thistype.heal(pt.pid) ---@type number 
            local mana = thistype.mana(pt.pid) ---@type number 
            local ug = CreateGroup()
            local ftarget = nil ---@type unit 
            local percent = 100. ---@type number 

            pt.dur = pt.dur + 1

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterAllyHero))

            for target in each(ug) do
                if percent > GetUnitLifePercent(target) then
                    percent = GetUnitLifePercent(target)
                    ftarget = target
                end
            end

            if pt.dur > 10. then
                mana = mana * 2.
            end

            if GetUnitCurrentOrder(Hero[pt.pid]) == OrderId("clusterrockets") and UnitAlive(Hero[pt.pid]) then
                if ModuloReal(pt.dur, 2.) == 0 then
                    MP(Hero[pt.pid], mana)
                end
                if ftarget then
                    heal = (heal + BlzGetUnitMaxHP(ftarget) * 0.01) * BOOST[pt.pid]
                    HP(Hero[pt.pid], ftarget, heal, thistype.tag)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", ftarget, "origin"))
                end

                pt.timer:callDelayed(0.5, periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.x = self.x
            pt.y = self.y
            pt.aoe = self.aoe * LBOOST[self.pid]

            pt.timer:callDelayed(0.5, periodic, pt)
        end
    end

    ---@class DIVINELIGHT : Spell
    ---@field heal function
    DIVINELIGHT = Spell.define("A0JE")
    do
        local thistype = DIVINELIGHT

        thistype.values = {
            heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.25 + 0.25 * ablev) * GetHeroInt(Hero[pid], true) end,
        }

        function thistype:onCast()
            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            --because backpack is a valid target
            if GetUnitTypeId(self.target) == BACKPACK then
                self.target = Hero[self.pid]
            end

            HP(self.caster, self.target, (self.heal + BlzGetUnitMaxHP(self.target) * 0.05) * BOOST[self.pid], thistype.tag)
            DivineLightBuff:add(self.caster, self.target):duration(3.)
        end
    end

    ---@class SANCTIFIEDGROUND : Spell
    ---@field ms number
    ---@field regen number
    ---@field aoe number
    ---@field dur function
    SANCTIFIEDGROUND = Spell.define("A0JG")
    do
        local thistype = SANCTIFIEDGROUND

        thistype.values = {
            ms = 20.,
            regen = 100.,
            aoe = 400.,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 11. + ablev end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 1

            if pt.dur > 0. then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

                for target in each(ug) do
                    SanctifiedGroundDebuff:add(Hero[pt.pid], target):duration(1.)
                end

                if pt.dur == 2 then
                    FadeSFX(pt.sfx, true)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.5, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            local pt = TimerList[self.pid]:add()
            pt.x = self.targetX
            pt.y = self.targetY
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dur = self.dur * 2. * LBOOST[self.pid]

            pt.sfx = AddSpecialEffect("war3mapImported\\Heaven's Gate Channel.mdl", pt.x, pt.y)
            BlzSetSpecialEffectScale(pt.sfx, LBOOST[self.pid])
            BlzPlaySpecialEffect(pt.sfx, ANIM_TYPE_BIRTH)
            local loc = Location(pt.x, pt.y)
            BlzSetSpecialEffectZ(pt.sfx, GetLocationZ(loc))
            RemoveLocation(loc)

            pt.timer:callDelayed(0.5, periodic, pt)
        end
    end

    ---@class HOLYRAYS : Spell
    ---@field aoe number
    ---@field heal function
    ---@field dmg function
    HOLYRAYS = Spell.define("A0JD")
    do
        local thistype = HOLYRAYS

        thistype.values = {
            aoe = 600.,
            heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.5 * ablev * GetHeroInt(Hero[pid], true) end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2. * ablev * GetHeroInt(Hero[pid], true) end,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1

            DamageTarget(source, target, thistype.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
        end
        function thistype:onCast()
            local ug = CreateGroup()

            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(isalive))

            for target in each(ug) do
                local dummy = Dummy.create(self.x, self.y, FourCC('A09Q'), 1)
                if IsUnitAlly(target, Player(self.pid - 1)) then
                    dummy:attack(target)
                    HP(self.caster, target, self.heal * BOOST[self.pid], thistype.tag)
                else
                    dummy:attack(target, self.caster, onHit)
                end
            end
        end
    end

    ---@class PROTECTION : Spell
    ---@field shield function
    ---@field aoe number
    PROTECTION = Spell.define("A0J3")
    do
        local thistype = PROTECTION

        thistype.values = {
            shield = function(pid) return 3. * GetHeroInt(Hero[pid], true) end,
            aoe = 650.,
        }

        function thistype:onCast()
            local ug = CreateGroup()

            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\RighteousGuard.mdx", self.caster, "chest"))
            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterAllyHero))

            for target in each(ug) do
                ProtectionBuff:add(self.caster, target)
                shield.add(target, self.shield * BOOST[self.pid], 20 + 10 * self.ablev):color(4)
            end
        end
    end

    ---@class RESURRECTION : Spell
    ---@field restore number
    ---@field spell integer
    RESURRECTION = Spell.define("A048")
    do
        local thistype = RESURRECTION
        thistype.spell = FourCC('A045')

        thistype.values = {
            restore = function(pid) return 40. + 20.* GetUnitAbilityLevel(Hero[pid], thistype.id) end,
        }

        function thistype.preCast(pid, tpid, caster, target, x, y, targetX, targetY)
            if target ~= HeroGrave[tpid] then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "You must target a tombstone!")
            elseif GetUnitAbilityLevel(HeroGrave[tpid], thistype.spell) > 0 then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "This player is already being revived!")
            end
        end

        function thistype:onCast()
            local size = 0.

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", self.targetX, self.targetY))
            ResurrectionRevival[self.tpid] = self.pid
            UnitAddAbility(HeroGrave[self.tpid], thistype.spell)

            BlzSetSpecialEffectScale(HeroReviveIndicator[self.tpid], size)
            DestroyEffect(HeroReviveIndicator[self.tpid])
            HeroReviveIndicator[self.tpid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", self.targetX, self.targetY)

            if GetLocalPlayer() == Player(self.tpid - 1) then
                size = 15.
            end

            BlzSetSpecialEffectTimeScale(HeroReviveIndicator[self.tpid], 0.)
            BlzSetSpecialEffectScale(HeroReviveIndicator[self.tpid], size)
            BlzSetSpecialEffectZ(HeroReviveIndicator[self.tpid], BlzGetLocalSpecialEffectZ(HeroReviveIndicator[self.tpid]) - 100)
            TimerQueue:callDelayed(12.8, DestroyEffect, HeroReviveIndicator[self.tpid])
        end
    end

    --crusader

    ---@class SOULLINK : Spell
    ---@field dur number
    ---@field onHit function
    SOULLINK = Spell.define("A06A")
    do
        local thistype = SOULLINK

        thistype.values = {
            dur = 5.,
        }

        function thistype:onCast()
            SoulLinkBuff:add(self.caster, self.target):duration(self.dur * LBOOST[self.pid])
        end

        function thistype.onHit(target, source, amount, damage_type)
            --soul link
            buff = SoulLinkBuff:get(nil, target)

            if buff then
                amount.value = 0.
                buff:remove()
            end
        end
    end

    ---@class LAWOFRESONANCE : Spell
    ---@field echo function
    ---@field dur number
    LAWOFRESONANCE = Spell.define("A0KD")
    do
        local thistype = LAWOFRESONANCE

        thistype.values = {
            echo = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 20. + 5. * ablev end,
            dur = 5.,
        }

        function thistype:onCast()
            LawOfResonanceBuff:add(self.caster, self.target):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class LAWOFVALOR : Spell
    ---@field regen function
    ---@field amp function
    ---@field dur number
    LAWOFVALOR = Spell.define("A06D")
    do
        local thistype = LAWOFVALOR
        thistype.values = {
            regen = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.08 + 0.02 * ablev) * GetHeroStr(Hero[pid], true) end,
            amp = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 8. + 2. * ablev end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 14. + ablev end,
        }

        function thistype:onCast()
            LawOfValorBuff:add(self.caster, self.target):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class LAWOFMIGHT : Spell
    ---@field pbonus function
    ---@field fbonus function
    ---@field dur number
    LAWOFMIGHT = Spell.define("A07D")
    do
        local thistype = LAWOFMIGHT

        thistype.values = {
            pbonus = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 10. + 5. * ablev end,
            fbonus = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.04 + 0.01 * ablev) * GetHeroInt(Hero[pid], true) end,
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 14. + ablev end,
        }

        function thistype:onCast()
            LawOfMightBuff:add(self.caster, self.target):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class AURAOFJUSTICE : Spell
    ---@field pshield function
    ---@field dur number
    AURAOFJUSTICE = Spell.define("A06E")
    do
        local thistype = AURAOFJUSTICE

        thistype.values = {
            pshield = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 20. + 5. * ablev end,
            dur = 5.,
        }

        function thistype:onCast()
            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, 900., Condition(FilterAlly))
            DestroyEffect(AddSpecialEffect("war3mapImported\\BlessedField.mdx", self.x, self.y))

            for target in each(ug) do
                shield.add(target, BlzGetUnitMaxHP(target) * self.pshield * 0.01 * LBOOST[self.pid], self.dur * LBOOST[self.pid])
            end

            DestroyGroup(ug)
        end

        function thistype.onLearn(source, ablev, pid)
            if JusticeAuraBuff:has(source, source) then
                JusticeAuraBuff:dispel(source, source)
            end
        end
    end

    ---@class DIVINERADIANCE : Spell
    ---@field heal function
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    DIVINERADIANCE = Spell.define("A07P")
    do
        local thistype = DIVINERADIANCE

        thistype.values = {
            heal = function(pid) return 2. * GetHeroStr(Hero[pid], true) end,
            dmg = function(pid) return 2. * GetHeroInt(Hero[pid], true) end,
            aoe = 750,
            dur = 10.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 2.

            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), thistype.aoe * LBOOST[pt.pid], Condition(FilterAlive))

            for target in each(ug) do
                if IsUnitEnemy(target, Player(pt.pid - 1)) then
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                    DamageTarget(pt.source, target, thistype.dmg(pt.pid) * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                elseif GetUnitTypeId(target) ~= BACKPACK and IsUnitAlly(target, Player(pt.pid - 1)) and GetUnitAbilityLevel(target, FourCC('Aloc')) == 0 then
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                    HP(pt.source, target, thistype.heal(pt.pid) * BOOST[pt.pid], thistype.tag)
                end
            end

            if pt.dur - 1 <= 0 then
                pt:destroy()
            else
                pt.timer:callDelayed(2., periodic, pt)
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dur = self.dur * LBOOST[self.pid]
            pt.source = self.caster

            TimerQueue:callDelayed(pt.dur, HideEffect, AddSpecialEffectTarget("war3mapImported\\HolyAurora.MDX", self.caster, "origin"))

            pt.timer:callDelayed(1., periodic, pt)
        end
    end

    --elementalist

    ---@class ELEMENTFIRE : Spell
    ---@field value integer
    ---@field reset function
    ELEMENTFIRE = Spell.define("A0J8")
    do
        local thistype = ELEMENTFIRE
        thistype.value = 1 ---@type integer 

        function thistype:onCast()
            IceElementBuff:dispel(self.caster, self.caster)
            LightningElementBuff:dispel(self.caster, self.caster)
            EarthElementBuff:dispel(self.caster, self.caster)
            FireElementBuff:add(self.caster, self.caster)
        end
    end

    ---@class ELEMENTICE : Spell
    ---@field value integer
    ELEMENTICE = Spell.define("A0J6")
    do
        local thistype = ELEMENTICE
        thistype.value = 2 ---@type integer 

        function thistype:onCast()
            FireElementBuff:dispel(self.caster, self.caster)
            LightningElementBuff:dispel(self.caster, self.caster)
            EarthElementBuff:dispel(self.caster, self.caster)
            IceElementBuff:add(self.caster, self.caster)
        end
    end

    ---@class ELEMENTLIGHTNING : Spell
    ---@field value integer
    ELEMENTLIGHTNING = Spell.define("A0J9")
    do
        local thistype = ELEMENTLIGHTNING
        thistype.value = 3 ---@type integer 

        function thistype:onCast()
            FireElementBuff:dispel(self.caster, self.caster)
            EarthElementBuff:dispel(self.caster, self.caster)
            IceElementBuff:dispel(self.caster, self.caster)
            LightningElementBuff:add(self.caster, self.caster)
        end
    end

    ---@class ELEMENTEARTH : Spell
    ---@field value integer
    ---@field reset function
    ELEMENTEARTH = Spell.define("A0JA")
    do
        local thistype = ELEMENTEARTH
        thistype.value = 4 ---@type integer 

        function thistype:onCast()
            FireElementBuff:dispel(self.caster, self.caster)
            IceElementBuff:dispel(self.caster, self.caster)
            LightningElementBuff:dispel(self.caster, self.caster)
            EarthElementBuff:add(self.caster, self.caster)
        end
    end

    ---@class BALLOFLIGHTNING : Spell
    ---@field range function
    ---@field dmg function
    BALLOFLIGHTNING = Spell.define("A0GV")
    do
        local thistype = BALLOFLIGHTNING

        thistype.values = {
            range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 650. + 200. * ablev end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (5. + ablev) * GetHeroInt(Hero[pid], true) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - pt.speed

            if pt.dur > 0. then
                local ug = CreateGroup()
                local x = GetUnitX(pt.target) ---@type number 
                local y = GetUnitY(pt.target) ---@type number 

                MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

                --ball movement
                SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))

                local target = FirstOfGroup(ug)

                if target then
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", target, "origin"))
                    DamageTarget(Hero[pt.pid], target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)

                    pt.dur = 0.
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.angle = self.angle
            pt.target = Dummy.create(self.x + 25. * Cos(pt.angle), self.y + 25. * Sin(pt.angle), 0, 0, 5.).unit
            pt.aoe = 150.
            pt.dur = self.range
            pt.speed = 25. + 2. * self.ablev
            pt.dmg = self.dmg * BOOST[self.pid]

            BlzSetUnitSkin(pt.target, FourCC('h070'))
            SetUnitFlyHeight(pt.target, 50., 0)
            SetUnitScale(pt.target, 1. + .2 * self.ablev, 1. + .2 * self.ablev, 1. + .2 * self.ablev)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class FROZENORB : Spell
    ---@field id2 integer
    ---@field iceaoe number
    ---@field icedmg function
    ---@field orbrange number
    ---@field orbdmg function
    ---@field orbaoe number
    ---@field freeze number
    ---@field missile Missiles[]
    ---@field icecd boolean[]
    FROZENORB = Spell.define("A011", "A01W")
    do
        local thistype = FROZENORB
        thistype.id2 = FourCC("A01W") ---@type integer 

        thistype.values = {
            iceaoe = 750.,
            icedmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * ablev) end,
            orbrange = 1000.,
            orbdmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * 3. * ablev end,
            orbaoe = 400.,
            freeze = 3.,
        }
        thistype.missile = {}
        thistype.icecd = {}

        ---@type fun(pid: number, missile: Missiles)
        local function spawn_icicle(pid, missile)
            thistype.icecd[pid] = true

            if missile.allocated then
                local ug = CreateGroup()

                MakeGroupInRange(pid, ug, missile.x, missile.y, thistype.iceaoe * LBOOST[pid], Condition(FilterEnemy))

                for target in each(ug) do
                    local icicle = Missiles:create(missile.x, missile.y, 70., 0, 0, 0) ---@type Missiles
                    icicle:model("war3mapImported\\BlizMissile.mdl")
                    icicle:scale(0.6)
                    icicle:speed(1000)
                    icicle.source = missile.source
                    icicle.owner = missile.owner
                    icicle.target = target
                    icicle:vision(400)

                    icicle.onFinish = function()
                        DamageTarget(icicle.source, icicle.target, thistype.icedmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)

                        return true
                    end

                    icicle:launch()
                end

                DestroyGroup(ug)

                TimerQueue:callDelayed(1., spawn_icicle, pid, missile)
            end
        end

        function thistype:onCast()
            local missile = thistype.missile[self.pid]

            --recast
            if missile then
                missile:onFinish()
                missile:terminate()
            else
                missile = Missiles:create(self.x + 75. * Cos(self.angle), self.y + 75. * Sin(self.angle), 70., ---@type Missiles
                self.x + self.orbrange * Cos(self.angle), self.y + self.orbrange * Sin(self.angle), 70.)
                missile:model("war3mapImported\\FrostOrb.mdl")
                missile:scale(1.3)
                missile:speed(200)
                missile.source = self.caster
                missile.owner = Player(self.pid - 1)
                missile:vision(self.iceaoe * LBOOST[self.pid])

                missile.onFinish = function()
                    -- show original cast
                    UnitRemoveAbility(missile.source, thistype.id2)
                    BlzUnitHideAbility(missile.source, thistype.id, false)

                    -- orb shatter
                    local ug = CreateGroup()
                    MakeGroupInRange(self.pid, ug, missile.x, missile.y, self.orbaoe * LBOOST[self.pid], Condition(FilterEnemy))

                    for target in each(ug) do
                        Freeze:add(missile.source, target):duration(self.freeze * LBOOST[self.pid])
                        DamageTarget(missile.source, target, self.orbdmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end

                    DestroyGroup(ug)

                    DestroyEffect(AddSpecialEffect("war3mapImported\\FrostNova.mdx", missile.x, missile.y))
                    thistype.missile[self.pid] = nil

                    return true
                end

                missile:launch()
                thistype.missile[self.pid] = missile
                TimerQueue:callDelayed(0.5, spawn_icicle, self.pid, missile)

                -- show second cast
                BlzUnitHideAbility(self.caster, FROZENORB.id, true)
                UnitAddAbility(self.caster, FROZENORB.id2)
                SetUnitAbilityLevel(self.caster, FROZENORB.id2, self.ablev)
            end
        end
    end

    ---@class GAIAARMOR : Spell
    ---@field shield function
    GAIAARMOR = Spell.define("A032")
    do
        local thistype = GAIAARMOR
        thistype.id2 = FourCC("A033") ---@type integer 

        thistype.values = {
            shield = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * ablev) end,
        }

        local onHit

        ---@type fun(pt: PlayerTimer)
        local function fatal_cooldown(pt)
            if GetUnitAbilityLevel(pt.source, thistype.id) >= 1 then
                EVENT_ON_FATAL_DAMAGE:register_unit_action(pt.source, onHit)

                UnitAddAbility(pt.source, thistype.id2)
                BlzUnitHideAbility(pt.source, thistype.id2, true)
            end
        end

        ---@type fun(pt: PlayerTimer)
        local function fatal_push(pt)
            local angle = 0. ---@type number 
            local x     = 0. ---@type number 
            local y     = 0. ---@type number 

            pt.dur = pt.dur - 1

            if pt.dur > 0. then
                for target in each(pt.ug) do
                    x = GetUnitX(target)
                    y = GetUnitY(target)
                    angle = Atan2(y - GetUnitY(Hero[pt.pid]), x - GetUnitX(Hero[pt.pid]))
                    if IsTerrainWalkable(x + pt.speed * Cos(angle), y + pt.speed * Sin(angle)) then
                        SetUnitXBounded(target, x + pt.speed * Cos(angle))
                        SetUnitYBounded(target, y + pt.speed * Sin(angle))
                    end
                end
                pt.timer:callDelayed(FPS_32, fatal_push, pt)
            else
                pt:destroy()
            end
        end


        onHit = function(target, source, amount, damage_type)
            local tpid = GetPlayerId(GetOwningPlayer(target)) + 1
            local pt = TimerList[tpid]:add()

            EVENT_ON_FATAL_DAMAGE:unregister_unit_action(target, onHit)
            amount.value = 0
            HP(target, target, BlzGetUnitMaxHP(target) * 0.2 * GetUnitAbilityLevel(target, GAIAARMOR.id), GAIAARMOR.tag)
            MP(target, BlzGetUnitMaxMana(target) * 0.2 * GetUnitAbilityLevel(target, GAIAARMOR.id))
            UnitRemoveAbility(target, thistype.id2)
            UnitRemoveAbility(target, FourCC('B005'))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Doom\\DoomDeath.mdl", target, "origin"))

            pt.dur = 35.
            pt.speed = 20.
            pt.ug = CreateGroup()
            MakeGroupInRange(tpid, pt.ug, GetUnitX(target), GetUnitY(target), 400., Condition(FilterEnemy))

            for u in each(pt.ug) do
                Stun:add(target, u):duration(4.)
            end

            pt.timer:callDelayed(FPS_32, fatal_push, pt)

            pt = TimerList[tpid]:add()
            pt.tag = thistype.id2
            pt.source = target
            pt.timer:callDelayed(120., fatal_cooldown, pt)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.sfx = AddSpecialEffectTarget("war3mapImported\\Archnathid Armor.mdx", self.caster, "chest")
            pt.tag = thistype.id
            BlzSetSpecialEffectColor(pt.sfx, 160, 255, 160)

            if masterElement[self.pid] == ELEMENTEARTH.value then --earth element bonus
                shield.add(self.caster, self.shield * 2.5 * BOOST[self.pid], 31.)
            else
                shield.add(self.caster, self.shield * BOOST[self.pid], 31.)
            end

            pt.timer:callDelayed(30., PlayerTimer.destroy, pt)
        end

        function thistype.onLearn(source, ablev, pid)
            if ablev == 1 and not TimerList[pid]:has(thistype.id2) then
                EVENT_ON_FATAL_DAMAGE:register_unit_action(source, onHit)
                UnitAddAbility(source, thistype.id2)
                BlzUnitHideAbility(source, thistype.id2, true)
            end
        end
    end

    ---@class FLAMEBREATH : Spell
    ---@field aoe number
    ---@field dmg function
    FLAMEBREATH = Spell.define("A01U")
    do
        local thistype = FLAMEBREATH

        thistype.values = {
            aoe = 750.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * ablev) end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur + 1

            local mp      = GetUnitState(Hero[pt.pid], UNIT_STATE_MANA) ---@type number 
            local x      = GetUnitX(Hero[pt.pid]) ---@type number 
            local y      = GetUnitY(Hero[pt.pid]) ---@type number 

            --trapezoid
            local Ax      = x + 50 * Cos(pt.angle + bj_PI * 0.5) ---@type number 
            local Ay      = y + 50 * Sin(pt.angle + bj_PI * 0.5) ---@type number 
            local Bx      = x + 50 * Cos(pt.angle - bj_PI * 0.5) ---@type number 
            local By      = y + 50 * Sin(pt.angle - bj_PI * 0.5) ---@type number 
            local Cx      = Bx + pt.aoe * Cos(pt.angle - bj_PI * 0.125) * LBOOST[pt.pid] ---@type number 
            local Cy      = By + pt.aoe * Sin(pt.angle - bj_PI * 0.125) * LBOOST[pt.pid] ---@type number 
            local Dx      = Ax + pt.aoe * Cos(pt.angle + bj_PI * 0.125) * LBOOST[pt.pid] ---@type number 
            local Dy      = Ay + pt.aoe * Sin(pt.angle + bj_PI * 0.125) * LBOOST[pt.pid] ---@type number 
            local AB ---@type number 
            local BC ---@type number 
            local CD ---@type number 
            local DA ---@type number 

            if GetUnitCurrentOrder(Hero[pt.pid]) == OrderId("clusterrockets") and UnitAlive(Hero[pt.pid]) and mp >= BlzGetUnitMaxMana(Hero[pt.pid]) * 0.03 then
                if ModuloReal(pt.dur, 2.) == 0 then
                    SetUnitState(Hero[pt.pid], UNIT_STATE_MANA, mp - BlzGetUnitMaxMana(Hero[pt.pid]) * 0.03)
                end
                if ModuloReal(pt.dur, 5.) == 0 then
                    SoundHandler("Abilities\\Spells\\Other\\BreathOfFire\\BreathOfFire1.flac", true, nil, Hero[pt.pid])
                end

                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, x, y, pt.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

                for target in each(ug) do
                    x = GetUnitX(target)
                    y = GetUnitY(target)

                    AB = (y - By) * (Ax - Bx) - (x - Bx) * (Ay - By)
                    BC = (y - Cy) * (Bx - Cx) - (x - Cx) * (By - Cy)
                    CD = (y - Dy) * (Cx - Dx) - (x - Dx) * (Cy - Dy)
                    DA = (y - Ay) * (Dx - Ax) - (x - Ax) * (Dy - Ay)

                    if (AB >= 0 and BC >= 0 and CD >= 0 and DA >= 0) or (AB <= 0 and BC <= 0 and CD <= 0 and DA <= 0) then
                        DamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.5, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            TimerList[self.pid]:stopAllTimers(thistype.id)

            local pt = TimerList[self.pid]:add()
            pt.angle = self.angle
            pt.sfx = AddSpecialEffect("war3mapImported\\flamebreath.mdx", self.x + 75 * Cos(pt.angle), self.y + 75 * Sin(pt.angle))
            pt.tag = thistype.id
            pt.aoe = self.aoe
            pt.dmg = self.dmg
            BlzSetSpecialEffectScale(pt.sfx, 1.3 * LBOOST[self.pid])
            BlzSetSpecialEffectTimeScale(pt.sfx, 1.5)
            BlzSetSpecialEffectYaw(pt.sfx, pt.angle)

            pt.timer:callDelayed(0.5, periodic, pt)
        end
    end

    ---@class ELEMENTALSTORM : Spell
    ---@field times number
    ---@field dmg function
    ---@field aoe number
    ELEMENTALSTORM = Spell.define("A04H")
    do
        local thistype = ELEMENTALSTORM

        thistype.values = {
            times = 12.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (1.5 + 0.5 * ablev) end,
            aoe = 400.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 1

            local rand = GetRandomInt(1, 4) ---@type integer 
            local angle = GetRandomInt(0, 359) * bj_DEGTORAD ---@type number 
            local dist = GetRandomInt(50, 200) ---@type integer 
            local x2 = pt.x + dist * Cos(angle) ---@type number 
            local y2 = pt.y + dist * Sin(angle) ---@type number 

            --guarantee the first 6 strikes are your chosen element
            if pt.dur >= 6 then
                rand = pt.element
            else
                while not ((rand ~= pt.element and rand ~= pt.str and rand ~= pt.int)) do
                    rand = GetRandomInt(1, 4)
                end
            end

            --alternate elements
            if pt.str == 0 then
                pt.str = rand
            elseif pt.int == 0 then
                pt.int = rand
            else
                pt.str = 0
                pt.int = 0
            end

            if pt.dur >= 0 then
                local ug = CreateGroup()

                TimerQueue:callDelayed(1., DestroyEffect, AddSpecialEffect("war3mapImported\\Lightnings Long.mdx", x2, y2))

                --fire aoe
                if rand == ELEMENTFIRE.value then
                    MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe * 1.5, Condition(FilterEnemy))
                    TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffect("war3mapImported\\Flame Burst.mdx", x2, y2))
                else
                    MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))
                end

                local target = FirstOfGroup(ug)

                --sfx
                if rand == ELEMENTICE.value then
                    TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", x2, y2))
                    MP(Hero[pt.pid], BlzGetUnitMaxMana(Hero[pt.pid]) * 0.15)
                elseif rand == ELEMENTLIGHTNING.value then
                    DamageTarget(Hero[pt.pid], target, GetWidgetLife(target) * 0.015, ATTACK_TYPE_NORMAL, PURE, thistype.tag)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "origin"))
                elseif rand == ELEMENTEARTH.value then
                    TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffect("war3mapImported\\Earth NovaTarget.mdx", x2, y2))
                end

                --unique effects
                for enemy in each(ug) do
                    if rand == ELEMENTFIRE.value then --fire
                        DamageTarget(Hero[pt.pid], enemy, pt.dmg * 1.5, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    else
                        DamageTarget(Hero[pt.pid], enemy, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                        if rand == ELEMENTICE.value then --ice
                            Freeze:add(Hero[pt.pid], enemy):duration(2.)
                        elseif rand == ELEMENTEARTH.value then --earth
                            local b = EarthDebuff:get(nil, enemy)
                            if b then
                                IncUnitAbilityLevel(enemy, b.RAWCODE)
                                b:refresh()
                            end
                            EarthDebuff:add(Hero[pt.pid], enemy):duration(10.)
                        end
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.4, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            pt.x = self.targetX
            pt.y = self.targetY
            pt.dur = self.times
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.aoe = self.aoe * LBOOST[self.pid]

            if masterElement[self.pid] == 0 then
                pt.element = GetRandomInt(1, 4)
            else
                pt.element = masterElement[self.pid]
            end

            pt.timer:callDelayed(0.4, periodic, pt)
        end
    end

    --dark summoner

    ---@class SUMMONINGIMPROVEMENT : Spell
    ---@field apply function
    SUMMONINGIMPROVEMENT = Spell.define("A022")
    do
        local thistype = SUMMONINGIMPROVEMENT

        ---@type fun(pid: integer, summon: unit, str: integer, agi: integer, int: integer)
        function thistype.apply(pid, summon, str, agi, int)
            local ablev = GetUnitAbilityLevel(Hero[pid], SUMMONINGIMPROVEMENT.id) - 1  ---@type integer --summoning improvement
            local uid = GetUnitTypeId(summon) ---@type integer 

            --stat ratios
            SetHeroStr(summon, str, true)
            if uid ~= SUMMON_DESTROYER then
                SetHeroAgi(summon, agi, true)
            else
                BlzSetUnitArmor(summon, agi)
            end
            SetHeroInt(summon, int, true)

            local armor = 0

            if ablev > 0 then
                SetUnitMoveSpeed(summon, GetUnitDefaultMoveSpeed(summon) + ablev * 10.)

                --armor bonus
                armor = armor + R2I((Pow(ablev, 1.2) + (Pow(ablev, 4.) - Pow(ablev, 3.9)) / 90.) / 2. + ablev + 6.5)

                --status bar buff
                UnitAddAbility(summon, FourCC('A06Q'))
                SetUnitAbilityLevel(summon, FourCC('A06Q'), ablev)
            end

            if uid == SUMMON_GOLEM then --golem
                if GetUnitAbilityLevel(Hero[pid], DEVOUR.id) > 0 then --golem devour ability
                    UnitAddAbility(summon, DEVOUR_GOLEM.id)
                    SetUnitAbilityLevel(summon, DEVOUR_GOLEM.id, GetUnitAbilityLevel(Hero[pid], DEVOUR.id))
                end
                if ablev >= 20 then
                    UnitAddAbility(summon, FourCC('A0IQ'))
                end
            elseif uid == SUMMON_DESTROYER then --destroyer
                if GetUnitAbilityLevel(Hero[pid], DEVOUR.id) > 0 then --destroyer devour ability
                    UnitAddAbility(summon, FourCC('A04Z'))
                    SetUnitAbilityLevel(summon, FourCC('A04Z'), GetUnitAbilityLevel(Hero[pid], DEVOUR.id))
                end
                if ablev >= 30 then
                    UnitAddAbility(summon, FourCC('A0IQ'))
                end
            elseif uid == SUMMON_HOUND then --demon hound
            end

            UnitSetBonus(summon, BONUS_ARMOR, armor)
        end

        function thistype:onCast()
            RecallSummons(self.pid)
        end
    end

    -- emulates timed life using hero XP (perhaps make general purpose custom frame for this later)
    ---@type fun(pt: PlayerTimer)
    local function summon_timed_life_bar(pt)
        local lev = GetHeroLevel(pt.target) ---@type integer 

        if Unit[pt.target].borrowed_life <= 0 then
            pt.dur = pt.dur - 0.5
        else
            Unit[pt.target].borrowed_life = math.max(0, Unit[pt.target].borrowed_life - 0.5)
        end

        if pt.dur <= 0 then
            SummonExpire(pt.target)
        else
            UnitStripHeroLevel(pt.target, 1)
            SetHeroXP(pt.target, R2I(RequiredXP(lev) + ((lev + 1) * pt.dur * 100. / pt.time) - 100), false)
        end
    end

    local is_destroyer_sacrificed = {} ---@type boolean[] 

    ---@class SUMMONDEMONHOUND : Spell
    ---@field hounds function
    ---@field str function
    ---@field agi function
    ---@field int function
    SUMMONDEMONHOUND = Spell.define("A0KF")
    do
        local thistype = SUMMONDEMONHOUND

        thistype.values = {
            hounds = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2 + ablev end,
            str = function(pid) return 0.2 * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end,
            agi = function(pid) return 0.075 * GetHeroInt(Hero[pid], true) end,
            int = function(pid) return 0.25 * GetHeroInt(Hero[pid], true) end,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1

            --deadly bite
            if GetRandomInt(0, 99) < 25 then
                if is_destroyer_sacrificed[pid] then
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

        function thistype:onCast()
            local pt
            local offset = self.pid * PLAYER_CAP ---@type integer 

            self.angle = GetUnitFacing(self.caster)
            self.x = self.x + 150 * Cos(bj_DEGTORAD * self.angle)
            self.y = self.y + 150 * Sin(bj_DEGTORAD * self.angle)

            for i = 0, self.hounds do
                if hounds[offset + i] == nil then
                    hounds[offset + i] = CreateUnit(Player(self.pid - 1), SUMMON_HOUND, self.x, self.y, self.angle)
                else
                    TimerList[self.pid]:stopAllTimers(hounds[offset + i])
                    ShowUnit(hounds[offset + i], true)
                    ReviveHero(hounds[offset + i], self.x, self.y, false)
                    SetWidgetLife(hounds[offset + i], BlzGetUnitMaxHP(hounds[offset + i]))
                    SetUnitState(hounds[offset + i], UNIT_STATE_MANA, BlzGetUnitMaxMana(hounds[offset + i]))
                    SetUnitScale(hounds[offset + i], 0.85, 0.85, 0.85)
                    SetUnitPosition(hounds[offset + i], self.x, self.y)
                    BlzSetUnitFacingEx(hounds[offset + i], self.angle)
                    SetUnitVertexColor(hounds[offset + i], 120, 60, 60, 255)
                    UnitSetBonus(hounds[offset + i], BONUS_ARMOR, 0)
                    SetUnitAbilityLevel(hounds[offset + i], FourCC('A06F'), 1)
                end

                pt = TimerList[self.pid]:add()
                pt.x = self.x
                pt.y = self.y
                pt.dur = 60.
                pt.time = 60.
                pt.tag = hounds[offset + i]
                pt.target = hounds[offset + i]

                TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", hounds[offset + i], "origin"))

                SUMMONINGIMPROVEMENT.apply(self.pid, hounds[offset + i], R2I(self.str * BOOST[self.pid]), R2I(self.agi * BOOST[self.pid]), R2I(self.int * BOOST[self.pid]))
                EVENT_ON_HIT:register_unit_action(hounds[offset + i], onHit)

                if is_destroyer_sacrificed[self.pid] then
                    SetUnitVertexColor(hounds[offset + i], 90, 90, 230, 255)
                    SetUnitScale(hounds[offset + i], 1.15, 1.15, 1.15)
                    SetUnitAbilityLevel(hounds[offset + i], FourCC('A06F'), 2)
                end


                Unit[hounds[offset + i]].borrowed_life = 0
                SummonGroup[#SummonGroup + 1] = hounds[offset + i]
                EVENT_ON_FATAL_DAMAGE:register_unit_action(hounds[offset + i], SummonExpire)

                SetHeroXP(hounds[offset + i], R2I(RequiredXP(GetHeroLevel(Hero[self.pid]) - 1) + ((GetHeroLevel(Hero[self.pid]) + 1) * pt.dur * 100 / pt.time) - 1), false)

                pt.timer:callPeriodically(0.5, nil, summon_timed_life_bar, pt)
            end
        end
    end

    ---@class SUMMONMEATGOLEM : Spell
    ---@field str function
    ---@field agi function
    SUMMONMEATGOLEM = Spell.define("A0KH")
    do
        local thistype = SUMMONMEATGOLEM

        thistype.values = {
            str = function(pid) return 0.4 * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end,
            agi = function(pid) return 0.6 * GetHeroInt(Hero[pid], true) end,
        }

        function thistype:onCast()
            local pt

            TimerList[self.pid]:stopAllTimers('dvou')
            self.angle = GetUnitFacing(self.caster)
            self.x = self.x + 150 * Cos(bj_DEGTORAD * self.angle)
            self.y = self.y + 150 * Sin(bj_DEGTORAD * self.angle)

            if meatgolem[self.pid] == nil then
                meatgolem[self.pid] = CreateUnit(Player(self.pid - 1), SUMMON_GOLEM, self.x, self.y, self.angle)
            else
                TimerList[self.pid]:stopAllTimers(meatgolem[self.pid])
                ShowUnit(meatgolem[self.pid], true)
                ReviveHero(meatgolem[self.pid], self.x, self.y, false)
                SetWidgetLife(meatgolem[self.pid], BlzGetUnitMaxHP(meatgolem[self.pid]))
                SetUnitState(meatgolem[self.pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(meatgolem[self.pid]))
                SetUnitScale(meatgolem[self.pid], 1., 1., 1.)
                SetUnitPosition(meatgolem[self.pid], self.x, self.y)
                BlzSetUnitFacingEx(meatgolem[self.pid], self.angle)
                UnitRemoveAbility(meatgolem[self.pid], BORROWED_LIFE.id) --borrowed life
                UnitRemoveAbility(meatgolem[self.pid], THUNDER_CLAP_GOLEM.id) --thunder clap
                UnitRemoveAbility(meatgolem[self.pid], MAGNETIC_FORCE.id) --magnetic force
                UnitRemoveAbility(meatgolem[self.pid], DEVOUR_GOLEM.id) --devour
                UnitSetBonus(meatgolem[self.pid], BONUS_ARMOR, 0)
                UnitSetBonus(meatgolem[self.pid], BONUS_HERO_STR, 0)
            end

            pt = TimerList[self.pid]:add()
            pt.x = self.x
            pt.y = self.y
            pt.dur = 180.
            pt.time = 180.
            pt.tag = meatgolem[self.pid]
            pt.target = meatgolem[self.pid]

            Unit[meatgolem[self.pid]].devour_stacks = 0
            Unit[meatgolem[self.pid]].borrowed_life = 0

            BlzSetHeroProperName(meatgolem[self.pid], "Meat Golem")
            TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", meatgolem[self.pid], "origin"))
            SUMMONINGIMPROVEMENT.apply(self.pid, meatgolem[self.pid], R2I(self.str * BOOST[self.pid]), R2I(self.agi * BOOST[self.pid]), 0)
            SummonGroup[#SummonGroup + 1] = meatgolem[self.pid]
            EVENT_ON_FATAL_DAMAGE:register_unit_action(meatgolem[self.pid], SummonExpire)

            SetHeroXP(meatgolem[self.pid], R2I(RequiredXP(GetHeroLevel(Hero[self.pid]) - 1) + ((GetHeroLevel(Hero[self.pid]) + 1) * pt.dur * 100 / pt.time) - 1), false)

            pt.timer:callPeriodically(0.5, nil, summon_timed_life_bar, pt)
        end
    end

    ---@class SUMMONDESTROYER : Spell
    ---@field periodic function
    ---@field str function
    ---@field agi function
    ---@field int function
    SUMMONDESTROYER = Spell.define("A0KG")
    do
        local thistype = SUMMONDESTROYER

        thistype.values = {
            str = function(pid) return 0.0666 * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end,
            agi = function(pid) return 0.005 * GetHeroInt(Hero[pid], true) end,
            int = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.5 * GetHeroInt(Hero[pid], true) * ablev end,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local chance = (15 and Unit[source].devour_stacks >= 4) or 10

            --annihilation strike
            if GetRandomInt(0, 99) < chance then
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                DamageTarget(source, target, GetHeroInt(source, true) * LBOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, "Annihilation Strike")
            end
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local base = 0 ---@type integer 

            if Unit[destroyer[pt.pid]].devour_stacks == 5 then
                base = 400
            elseif Unit[destroyer[pt.pid]].devour_stacks >= 3 then
                base = 200
            end

            SetHeroAgi(destroyer[pt.pid], IMinBJ(GetHeroAgi(destroyer[pt.pid], false) + 50, 400), true)

            if pt.x == GetUnitX(destroyer[pt.pid]) and pt.y == GetUnitY(destroyer[pt.pid]) then
                pt.timer:callDelayed(1., thistype.periodic, pt)
            else
                SetHeroAgi(destroyer[pt.pid], base, true)
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt

            TimerList[self.pid]:stopAllTimers('blif')
            self.angle = GetUnitFacing(self.caster) + 180
            self.x = self.x + 150 * Cos(bj_DEGTORAD * self.angle)
            self.y = self.y + 150 * Sin(bj_DEGTORAD * self.angle)

            if destroyer[self.pid] == nil then
                destroyer[self.pid] = CreateUnit(Player(self.pid - 1), SUMMON_DESTROYER, self.x, self.y, self.angle + 180)
            else
                TimerList[self.pid]:stopAllTimers(destroyer[self.pid])
                ShowUnit(destroyer[self.pid], true)
                ReviveHero(destroyer[self.pid], self.x, self.y, false)
                SetWidgetLife(destroyer[self.pid], BlzGetUnitMaxHP(destroyer[self.pid]))
                SetUnitState(destroyer[self.pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(destroyer[self.pid]))
                SetUnitPosition(destroyer[self.pid], self.x, self.y)
                BlzSetUnitFacingEx(destroyer[self.pid], self.angle + 180)
                SetUnitAbilityLevel(destroyer[self.pid], FourCC('A02D'), 1)
                SetUnitAbilityLevel(destroyer[self.pid], FourCC('A06J'), 1)
                UnitRemoveAbility(destroyer[self.pid], FourCC('A061')) --blink
                UnitRemoveAbility(destroyer[self.pid], FourCC('A03B')) --crit
                UnitRemoveAbility(destroyer[self.pid], BORROWED_LIFE.id) --borrowed life
                UnitRemoveAbility(destroyer[self.pid], FourCC('A04Z')) --devour
                UnitSetBonus(destroyer[self.pid], BONUS_ARMOR, 0)
                UnitSetBonus(destroyer[self.pid], BONUS_HERO_STR, 0)
                UnitSetBonus(destroyer[self.pid], BONUS_HERO_AGI, 0)
                UnitSetBonus(destroyer[self.pid], BONUS_HERO_INT, 0)
                SetHeroAgi(destroyer[self.pid], 0, true)
            end

            pt = TimerList[self.pid]:add()
            pt.x = self.x
            pt.y = self.y
            pt.dur = 180.
            pt.time = 180.
            pt.tag = destroyer[self.pid]
            pt.target = destroyer[self.pid]

            Unit[destroyer[self.pid]].borrowed_life = 0
            Unit[destroyer[self.pid]].devour_stacks = 0
            is_destroyer_sacrificed[self.pid] = false

            BlzSetHeroProperName(destroyer[self.pid], "Destroyer")
            TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", destroyer[self.pid], "origin"))
            SUMMONINGIMPROVEMENT.apply(self.pid, destroyer[self.pid], R2I(self.str * BOOST[self.pid]), R2I(self.agi * BOOST[self.pid]), R2I(self.int * BOOST[self.pid]))
            EVENT_ON_HIT:register_unit_action(destroyer[self.pid], onHit)

            --revert hounds to normal
            for i = 1, #SummonGroup do
                local target = SummonGroup[i]
                if GetOwningPlayer(target) == Player(self.pid - 1) and GetUnitTypeId(target) == SUMMON_HOUND then
                    SetUnitVertexColor(target, 120, 60, 60, 255)
                    SetUnitScale(target, 0.85, 0.85, 0.85)
                    SetUnitAbilityLevel(target, FourCC('A06F'), 1)
                end
            end

            SummonGroup[#SummonGroup + 1] = destroyer[self.pid]
            EVENT_ON_FATAL_DAMAGE:register_unit_action(destroyer[self.pid], SummonExpire)

            SetHeroXP(destroyer[self.pid], R2I(RequiredXP(GetHeroLevel(Hero[self.pid]) - 1) + ((GetHeroLevel(Hero[self.pid]) + 1) * pt.dur * 100 / pt.time) - 1), false)

            pt.timer:callPeriodically(0.5, nil, summon_timed_life_bar, pt)
        end
    end

    ---@class DEVOUR : Spell
    ---@field autocast function
    DEVOUR = Spell.define("A063")
    do
        local thistype = DEVOUR

        ---@type fun(pt: PlayerTimer, order: string)
        function thistype.autocast(pt, order)
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 1250., Condition(FilterHound))

            local target = FirstOfGroup(ug)

            if target then
                IssueTargetOrder(pt.target, order, target)
            end

            DestroyGroup(ug)

            pt.timer:callDelayed(1., thistype.autocast, pt, order)
        end
    end

    ---@class DEMONICSACRIFICE : Spell
    ---@field pheal number
    ---@field dur number
    DEMONICSACRIFICE = Spell.define("A0K1")
    do
        local thistype = DEMONICSACRIFICE

        thistype.values = {
            pheal = 30.,
            dur = 15.,
        }

        function thistype.preCast(pid, tpid, caster, target, x, y, targetX, targetY)
            if GetOwningPlayer(target) ~= Player(pid - 1) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(Player(pid - 1), 0, 0, "You must target your own summons!")
            end
        end

        function thistype:onCast()
            --demon hound
            if GetUnitTypeId(self.target) == SUMMON_HOUND then
                SummonExpire(self.target)

                for i = 1, #SummonGroup do
                    local target = SummonGroup[i]
                    if GetOwningPlayer(target) == Player(self.pid - 1) then
                        local heal = BlzGetUnitMaxHP(target) * self.pheal * 0.01 * BOOST[self.pid]
                        HP(self.caster, target, heal, thistype.tag)
                    end
                end
            --meat golem
            elseif GetUnitTypeId(self.target) == SUMMON_GOLEM then
                if Unit[self.target].devour_stacks < 4 then
                    SummonExpire(self.target)
                end

                DemonicSacrificeBuff:add(self.caster, self.caster):duration(thistype.dur * LBOOST[self.pid])

                TimerQueue:callDelayed(3., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Orc\\AncestralSpirit\\AncestralSpiritCaster.mdl", self.target, "origin"))
            --destroyer
            elseif GetUnitTypeId(self.target) == SUMMON_DESTROYER then
                SummonExpire(self.target)
                is_destroyer_sacrificed[self.pid] = true

                for i = 1, #SummonGroup do
                    local target = SummonGroup[i]
                    if GetOwningPlayer(target) == Player(self.pid - 1) and GetUnitTypeId(target) == SUMMON_HOUND then
                        SetUnitVertexColor(target, 90, 90, 230, 255)
                        SetUnitScale(target, 1.15, 1.15, 1.15)
                        DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Call of Dread Purple.mdx", target, "origin"))
                        SetUnitAbilityLevel(target, FourCC('A06F'), 2)
                    end
                end
            end
        end
    end

    --royal guardian

    ---@class STEEDCHARGE : Spell
    ---@field charge function
    ---@field dur number
    STEEDCHARGE = Spell.define("A06B")
    do
        local thistype = STEEDCHARGE
        thistype.preCast = DASH_PRECAST
        thistype.values = {
            dur = 10.,
        }

        ---@type fun(pid: integer, angle: number, x: number, y: number)
        local function charge(pid, angle, x, y)
            local speed = Unit[Hero[pid]].movespeed * 0.045

            SetUnitPathing(Hero[pid], false)
            SetUnitPropWindow(Hero[pid], 0)

            if not UnitAlive(Hero[pid]) or IsUnitLoaded(Hero[pid]) or IsUnitInRangeXY(Hero[pid], x, y, speed + 5.) or IsUnitInRangeXY(Hero[pid], x, y, 1000.) == false then
                SetUnitPropWindow(Hero[pid], bj_DEGTORAD * 60.)
                SetUnitPathing(Hero[pid], true)
                SetUnitAnimationByIndex(Hero[pid], 1)
            else
                local ug = CreateGroup()

                BlzSetUnitFacingEx(Hero[pid], bj_RADTODEG * angle)
                SetUnitXBounded(Hero[pid], GetUnitX(Hero[pid]) + speed * Cos(angle))
                SetUnitYBounded(Hero[pid], GetUnitY(Hero[pid]) + speed * Sin(angle))
                SetUnitAnimationByIndex(Hero[pid], 0)

                MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 150., Condition(FilterEnemy))

                for target in each(ug) do
                    if SteedChargeStun:has(Hero[pid], target) == false then
                        Stun:add(Hero[pid], target):duration(1.)
                        SteedChargeStun:add(Hero[pid], target):duration(2.)
                        DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", target, "origin"))
                    end
                end

                TimerQueue:callDelayed(FPS_32, charge, pid, angle, x, y)

                DestroyGroup(ug)
            end
        end

        function thistype:onCast()
            SoundHandler("Units\\Human\\Knight\\KnightYesAttack3.flac", true, nil, self.caster)
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Polymorph\\PolyMorphDoneGround.mdl", self.x, self.y))

            BlzUnitHideAbility(self.caster, FourCC('A06K'), false)
            IssueImmediateOrderById(self.caster, 852180) --avatar
            BlzUnitHideAbility(self.caster, FourCC('A06K'), true)
            BlzStartUnitAbilityCooldown(self.caster, thistype.id, 30.)
            SteedChargeBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])

            TimerQueue:callDelayed(0.05, charge, self.pid, self.angle, self.targetX, self.targetY)
        end

        function thistype:setup(u)
            BlzUnitHideAbility(u, FourCC('A06K'), true)
        end
    end

    ---@class SHIELDSLAM : Spell
    ---@field dmg function
    SHIELDSLAM = Spell.define("A0HT")
    do
        local thistype = SHIELDSLAM

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev * (GetHeroStr(Hero[pid], true) + 6. * BlzGetUnitArmor(Hero[pid])) end,
        }

        function thistype:onCast()
            local dmg = self.dmg * BOOST[self.pid] ---@type number 

            StunUnit(self.pid, self.target, 3.)
            DamageTarget(self.caster, self.target, dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)

            local sfx = AddSpecialEffect("war3mapImported\\DetroitSmash_Effect_CasterArt.mdx", self.x, self.y)
            BlzSetSpecialEffectYaw(sfx, bj_DEGTORAD * GetUnitFacing(self.caster))
            DestroyEffect(sfx)

            if ShieldCount[self.pid] > 0 then
                local ug = CreateGroup()
                MakeGroupInRange(self.pid, ug, GetUnitX(self.target), GetUnitY(self.target), 300 * LBOOST[self.pid], Condition(FilterEnemy))
                GroupRemoveUnit(ug, self.target)

                for target in each(ug) do
                    DamageTarget(self.caster, target, dmg * .5, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    StunUnit(self.pid, target, 1.5)
                end

                DestroyGroup(ug)
            end
        end
    end

    ---@class ROYALPLATE : Spell
    ---@field armor function
    ---@field dur number
    ROYALPLATE = Spell.define("A0EG")
    do
        local thistype = ROYALPLATE

        thistype.values = {
            armor = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.006 * Pow(ablev, 5.) + 10. * Pow(ablev, 2.) + 25. * ablev end,
            dur = 15.,
        }

        function thistype:onCast()
            RoyalPlateBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class PROVOKE : Spell
    ---@field heal function
    ---@field aoe function
    ---@field dur number
    PROVOKE = Spell.define("A04Y")
    do
        local thistype = PROVOKE

        thistype.values = {
            aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 450. + 50. * ablev end,
            heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid])) * (0.2 + 0.01 * ablev) end,
            dur = 10.,
        }

        function thistype:onCast()
            local ug = CreateGroup()

            HP(self.caster, self.caster, self.heal * BOOST[self.pid], thistype.tag)
            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", self.caster, "origin"))

            for target in each(ug) do
                ProvokeDebuff:add(self.caster, target):duration(self.dur * LBOOST[self.pid])
            end

            Taunt(self.caster, self.pid, 800., true, 2000, 2000)

            DestroyGroup(ug)
        end
    end

    ---@class FIGHTME : Spell
    ---@field dur function
    FIGHTME = Spell.define("A09E")
    do
        local thistype = FIGHTME

        thistype.values = {
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (4. + ablev) end,
        }

        function thistype:onCast()
            FightMeCasterBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class PROTECTOR : Spell
    PROTECTOR = Spell.define("A0HS")
    do
        local thistype = PROTECTOR
    end

    --assassin

    ---@class SHADOWSHURIKEN : Spell
    ---@field dmg function
    SHADOWSHURIKEN = Spell.define("A0BG")
    do
        local thistype = SHADOWSHURIKEN

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (ablev + 5.) * 0.25 end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            if pt.dur > 0. then
                SetUnitXBounded(pt.target, GetUnitX(pt.target) + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.target, GetUnitY(pt.target) + pt.speed * Sin(pt.angle))

                pt.dur = pt.dur - pt.speed

                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), pt.aoe, Condition(FilterEnemy))

                for target in each(ug) do
                    if IsUnitInGroup(target, pt.ug) == false then
                        GroupAddUnit(pt.ug, target)
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "chest"))
                        local debuff = MarkedForDeathDebuff:get(nil, target) ---@type Buff

                        if debuff and pt.mana < 50 then
                            local mana = 6  ---@type integer --percent mana restored per unit hit
                            local percentcap = 50 ---@type integer 

                            --mana restore from bosses
                            if IsUnitType(target, UNIT_TYPE_HERO) then
                                mana = 25
                            end

                            debuff:dispel()

                            pt.mana = pt.mana + mana

                            if pt.mana > percentcap then
                                mana = ModuloInteger(pt.mana,percentcap)
                            end

                            SetUnitState(Hero[pt.pid], UNIT_STATE_MANA, GetUnitState(Hero[pt.pid], UNIT_STATE_MANA) + BlzGetUnitMaxMana(Hero[pt.pid]) * mana * 0.01)
                            SetUnitPathing(target, true)
                            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl", Hero[pt.pid], "origin"))
                        end
                        DamageTarget(Hero[pt.pid], target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end
        end

        function thistype:onCast()
            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPIN.id2, true)
            UpdateManaCosts(self.pid)

            local pt = TimerList[self.pid]:add()
            pt.target = Dummy.create(self.x, self.y, 0, 0).unit
            pt.ug = CreateGroup()
            pt.dur = 750.
            pt.aoe = 200.
            pt.speed = 60.
            pt.mana = 0
            pt.angle = self.angle
            pt.dmg = self.dmg * BOOST[self.pid]

            BlzSetUnitSkin(pt.target, FourCC('h00F'))
            SetUnitScale(pt.target, 1.1, 1.1, 1.1)
            SetUnitVertexColor(pt.target, 50, 50, 50, 255)
            UnitAddAbility(pt.target, FourCC('Amrf'))
            SetUnitFlyHeight(pt.target, 75.00, 0.00)
            BlzSetUnitFacingEx(pt.target, bj_RADTODEG * pt.angle)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class BLINKSTRIKE : Spell
    ---@field dmg function
    ---@field aoe number
    BLINKSTRIKE = Spell.define("A00T")
    do
        local thistype = BLINKSTRIKE
        thistype.preCast = DASH_PRECAST

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev * (0.5 * GetHeroAgi(Hero[pid], true) + 0.25 * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0))) end,
            aoe = 200.,
        }

        function thistype:onCast()
            local ug = CreateGroup()

            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPIN.id2, true)
            UpdateManaCosts(self.pid)

            for i = 0, 11 do
                self.angle = 0.1666 * bj_PI * i
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", self.targetX + 190. * Cos(self.angle), self.targetY + 190. * Sin(self.angle)))
            end

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", self.targetX, self.targetY))
            MakeGroupInRange(self.pid, ug, self.targetX, self.targetY, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            for target in each(ug) do
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))

                local debuff = MarkedForDeathDebuff:get(nil, target)

                if debuff then
                    SetUnitPathing(target, true)
                    debuff:remove()
                    BlinkStrikeBuff:add(Hero[self.pid], Hero[self.pid]):duration(6.)
                end

                DamageTarget(self.caster, target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end

            SetUnitXBounded(self.caster, self.targetX)
            SetUnitYBounded(self.caster, self.targetY)

            DestroyGroup(ug)
        end
    end

    ---@class SMOKEBOMB : Spell
    ---@field aoe number
    ---@field dur number
    SMOKEBOMB = Spell.define("A01E")
    do
        local thistype = SMOKEBOMB

        thistype.values = {
            aoe = 300.,
            dur = 8.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 0.5

            if pt.dur > 0. then
                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(isalive))

                for target in each(ug) do
                    if IsUnitAlly(target, Player(pt.pid - 1)) then
                        SmokebombBuff:add(Hero[pt.pid], target):duration(1.)
                    else
                        SmokebombDebuff:add(Hero[pt.pid], target):duration(1.)
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.5, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPIN.id2, true)
            UpdateManaCosts(self.pid)

            local pt = TimerList[self.pid]:add()
            pt.x = self.targetX
            pt.y = self.targetY
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dur = self.dur * LBOOST[self.pid]

            pt.sfx = AddSpecialEffect("war3mapImported\\GreySmoke.mdx", self.targetX, self.targetY)
            BlzSetSpecialEffectScale(pt.sfx, LBOOST[self.pid])
            pt.timer:callDelayed(0.5, periodic, pt)
        end
    end

    ---@class DAGGERSTORM : Spell
    ---@field dmg function
    ---@field num number
    DAGGERSTORM = Spell.define("A00P")
    do
        local thistype = DAGGERSTORM

        thistype.values = {
            dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 2. end,
            num = 30.,
        }

        local function periodic(pt)
            local i = 1

            if pt.count > 0 then
                pt.count = pt.count - 3

                for _ = 0, 2 do
                    i = -i
                    local spawnangle = pt.angle + bj_PI + GetRandomReal(bj_PI * -0.15, bj_PI * 0.15) ---@type number
                    local x = pt.x + GetRandomReal(70., 200.) * Cos(spawnangle) ---@type number
                    local y = pt.y + GetRandomReal(70., 200.) * Sin(spawnangle) ---@type number
                    local moveangle = Atan2(pt.targetY - y, pt.targetX - x)
                    local missile = Missiles:create(x, y, 70, x + 1150. * Cos(moveangle), y + 1150. * Sin(moveangle), 0) ---@type Missiles
                    missile:model("Abilities\\Weapons\\WardenMissile\\WardenMissile.mdl")
                    missile:scale(1.1)
                    missile:speed(1400)
                    missile:arc(GetRandomReal(5, 15))
                    missile.source = pt.source
                    missile.owner = Player(pt.pid - 1)
                    missile:vision(400)
                    missile.collision = 50
                    missile.damage = pt.dmg * BOOST[pt.pid]

                    missile.onHit = function(enemy)
                        if IsHittable(enemy, missile.owner) then
                            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", enemy, "origin"))
                            DamageTarget(missile.source, enemy, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                            missile.damage = missile.damage - missile.damage * 0.05
                        end

                        return false
                    end

                    missile:launch()
                end

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPIN.id2, true)
            UpdateManaCosts(self.pid)

            local pt = TimerList[self.pid]:add()
            pt.count = self.num
            pt.dmg = self.dmg
            pt.source = self.caster
            pt.angle = self.angle
            pt.x = self.x
            pt.y = self.y
            pt.targetX = self.targetX
            pt.targetY = self.targetY

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

    ---@class BLADESPIN : Spell
    ---@field id2 integer
    ---@field spin function
    ---@field times function
    ---@field amdg function
    ---@field aoe number
    ---@field pdmg function
    ---@field count number[]
    ---@field onHit function
    ---@field admg function
    BLADESPIN = Spell.define("A0AS", "A0AQ")
    do
        local thistype = BLADESPIN
        thistype.id2 = FourCC("A0AQ")

        thistype.values = {
            times = function(pid) return math.max(8 - GetHeroLevel(Hero[pid]) // 100, 5) end,
            pdmg = function(pid) return 8. * GetHeroAgi(Hero[pid], true) end,
            aoe = 250.,
            admg = function(pid) return 4. * GetHeroAgi(Hero[pid], true) end,
        }
        thistype.count = __jarray(0)

        ---@type fun(caster: unit, active: boolean)
        function thistype.spin(caster, active)
            local ug = CreateGroup()
            local pid = GetPlayerId(GetOwningPlayer(caster)) + 1

            DelayAnimation(pid, caster, 0.5, 0, 1., true)
            SetUnitTimeScale(caster, 1.75)
            SetUnitAnimationByIndex(caster, 5)

            local dummy = Dummy.create(GetUnitX(caster), GetUnitY(caster), 0, 0).unit
            BlzSetUnitSkin(dummy, FourCC('h00C'))
            SetUnitTimeScale(dummy, 0.5)
            SetUnitScale(dummy, 1.35, 1.35, 1.35)
            SetUnitAnimationByIndex(dummy, 0)
            SetUnitFlyHeight(dummy, 75., 0)
            BlzSetUnitFacingEx(dummy, GetUnitFacing(caster))

            dummy = Dummy.create(GetUnitX(caster), GetUnitY(caster), 0, 0).unit
            BlzSetUnitSkin(dummy, FourCC('h00C'))
            SetUnitTimeScale(dummy, 0.5)
            SetUnitScale(dummy, 1.35, 1.35, 1.35)
            SetUnitAnimationByIndex(dummy, 0)
            SetUnitFlyHeight(dummy, 75., 0)
            BlzSetUnitFacingEx(dummy, GetUnitFacing(caster) + 180)

            MakeGroupInRange(pid, ug, GetUnitX(caster), GetUnitY(caster), thistype.aoe * LBOOST[pid], Condition(FilterEnemy))

            for target in each(ug) do
                DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", target, "chest"))
                if active then
                    DamageTarget(caster, target, thistype.admg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                else
                    DamageTarget(caster, target, thistype.pdmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end
            end

            DestroyGroup(ug)
        end

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            thistype.count[pid] = thistype.count[pid] + 1
        end

        function thistype:setup(u)
            EVENT_ON_HIT:register_unit_action(u, onHit)
            UnitRemoveAbility(u, thistype.id)
        end
    end

    ---@class PHANTOMSLASH : Spell
    ---@field dmg function
    ---@field slashing boolean[]
    PHANTOMSLASH = Spell.define("A07Y")
    do
        local thistype = PHANTOMSLASH
        thistype.slashing = {}

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid], true) * 1.5 * ablev end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local x = GetUnitX(pt.source) ---@type number 
            local y = GetUnitY(pt.source) ---@type number 

            pt.dur = pt.dur - pt.speed

            if pt.dur > 0. then
                --movement
                if IsTerrainWalkable(x + pt.speed * Cos(pt.angle), y + pt.speed * Sin(pt.angle)) then
                    SetUnitXBounded(pt.source, x + pt.speed * Cos(pt.angle))
                    SetUnitYBounded(pt.source, y + pt.speed * Sin(pt.angle))
                else
                    pt.dur = 0.
                end

                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, x, y, 200., Condition(FilterEnemy))

                for target in each(ug) do
                    if not IsUnitInGroup(target, pt.ug) then
                        GroupAddUnit(pt.ug, target)
                        MarkedForDeathDebuff:add(pt.source, target):duration(4.)
                        DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                pt:destroy()
            end
        end

        local function onRemove(self)
            BlzUnitClearOrders(self.source, true)
            BlzUnitDisableAbility(self.source, thistype.id, false, false)

            thistype.slashing[self.pid] = false
            Unit[self.source].evasion = Unit[self.source].evasion - 100
            SetUnitTimeScale(self.source, 1.)
            SetUnitAnimationByIndex(self.source, 4)
        end

        function thistype:onCast()
            thistype.slashing[self.pid] = true
            Unit[self.caster].evasion = Unit[self.caster].evasion + 100

            BlzUnitDisableAbility(self.caster, thistype.id, true, false)
            SetUnitState(self.caster, UNIT_STATE_MANA, GetUnitState(self.caster, UNIT_STATE_MANA) - BlzGetUnitMaxMana(self.caster) * (.1 - 0.025 * self.ablev))

            local pt = TimerList[self.pid]:add()
            pt.dur = math.min(750., SquareRoot(Pow(self.targetX - self.x, 2) + Pow(self.targetY - self.y, 2)))
            pt.speed = 60.
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.angle = Atan2(self.targetY - self.y, self.targetX - self.x)
            pt.source = self.caster
            pt.ug = CreateGroup()
            pt.onRemove = onRemove

            TimerQueue:callDelayed(FPS_32, IssueImmediateOrderById, pt.source, ORDER_ID_UNIMMOLATION)
            pt.timer:callDelayed(FPS_32, periodic, pt)

            SetUnitTimeScale(self.caster, 1.5)
            SetUnitAnimationByIndex(self.caster, 5)
            BlzSetUnitFacingEx(self.caster, pt.angle * bj_RADTODEG)

            local sfx = AddSpecialEffect("war3mapImported\\ShadowWarrior.mdl", self.x, self.y)
            BlzSetSpecialEffectColorByPlayer(sfx, Player(self.pid - 1))
            BlzSetSpecialEffectYaw(sfx, pt.angle)
            FadeSFX(sfx, true)
            TimerQueue:callDelayed(2., HideEffect, sfx)
            BlzPlaySpecialEffectWithTimeScale(sfx, ANIM_TYPE_ATTACK, 1.5)
        end
    end

    --arcanist

    ---@class CONTROLTIME : Spell
    ---@field dur number
    CONTROLTIME = Spell.define("A04C")
    do
        local thistype = CONTROLTIME
        thistype.values = {
            dur = 10.,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1

            if TimerList[pid]:has(ARCANOSPHERE.id) then
                BlzStartUnitAbilityCooldown(Hero[pid], ARCANECOMETS.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANECOMETS.id) - 3.))
            else
                BlzStartUnitAbilityCooldown(Hero[pid], ARCANEBOLTS.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANEBOLTS.id) - 3.))
            end

            local pt = TimerList[pid]:get(ARCANESHIFT.id, Hero[pid])

            if pt then
                pt.cooldown = pt.cooldown - 3
            else
                BlzStartUnitAbilityCooldown(Hero[pid], ARCANESHIFT.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANESHIFT.id) - 3.))
            end
            BlzStartUnitAbilityCooldown(Hero[pid], ARCANEBARRAGE.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANEBARRAGE.id) - 3.))
            BlzStartUnitAbilityCooldown(Hero[pid], STASISFIELD.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], STASISFIELD.id) - 3.))
            BlzStartUnitAbilityCooldown(Hero[pid], ARCANOSPHERE.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], ARCANOSPHERE.id) - 3.))
            BlzStartUnitAbilityCooldown(Hero[pid], CONTROLTIME.id, math.max(0.0001, BlzGetUnitAbilityCooldownRemaining(Hero[pid], CONTROLTIME.id) - 3.))
        end

        function thistype:onCast()
            ControlTimeBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end

        function thistype:setup(u)
            EVENT_ON_HIT:register_unit_action(u, onHit)
        end
    end

    ---@class ARCANECOMETS : Spell
    ---@field dmg function
    ---@field aoe number
    ARCANECOMETS = Spell.define("A00U")
    do
        local thistype = ARCANECOMETS

        thistype.values = {
            dmg = function(pid) return 2. * GetHeroInt(Hero[pid], true) end,
            aoe = 250.,
        }

        ---@type fun(pt: PlayerTimer)
        local function expire(pt)
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

            for target in each(ug) do
                DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
            end

            pt:destroy()

            DestroyGroup(ug)
        end

        ---@type fun(pt: PlayerTimer)
        local function spawn(pt)
            pt.count = pt.count - 1

            if pt.count >= 0 then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, 800., Condition(FilterEnemy))

                local count = BlzGroupGetSize(ug)

                if count > 0 then
                    local target = BlzGroupUnitAt(ug, GetRandomInt(0, count - 1))
                    local x = GetUnitX(target)
                    local y = GetUnitY(target)

                    local pt2 = TimerList[pt.pid]:add()
                    pt2.x = x
                    pt2.y = y
                    pt2.dmg = pt.dmg
                    pt2.aoe = pt.aoe
                    pt2.source = pt.source

                    local sfx = AddSpecialEffect("war3mapImported\\Voidfall Medium.mdx", x, y)
                    BlzPlaySpecialEffectWithTimeScale(sfx, ANIM_TYPE_STAND, 1.5)
                    TimerQueue:callDelayed(2., DestroyEffect, sfx)

                    pt2.timer:callDelayed(0.6, expire, pt2)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.2, spawn, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            pt.source = self.caster
            pt.count = self.ablev + 2
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.x = self.x
            pt.y = self.y

            pt.timer:callDelayed(0.2, spawn, pt)
        end
    end

    ---@class ARCANEBOLTS : Spell
    ---@field dmg function
    ---@field aoe number
    ARCANEBOLTS = Spell.define("A05Q")
    do
        local thistype = ARCANEBOLTS

        thistype.values = {
            dmg = function(pid) return 2. * GetHeroInt(Hero[pid], true) end,
            aoe = 250.,
        }

        ---@type fun(pt: PlayerTimer)
        local function spawn(pt)
            pt.dur = pt.dur - 1

            if pt.dur >= 0 then
                local x = GetUnitX(pt.source) ---@type number 
                local y = GetUnitY(pt.source) ---@type number 
                local missile = Missiles:create(x, y, 20., pt.x, pt.y, 20.) ---@type Missiles
                missile:model("ArcaneRocketProjectile.mdl")
                missile:scale(1.4)
                missile:speed(1400)
                missile.source = pt.source
                missile.owner = Player(pt.pid - 1)
                missile:vision(400)
                missile.collision = 100
                missile.damage = pt.dmg * BOOST[pt.pid]

                missile.onHit = function(target)
                    if IsHittable(target, missile.owner) then
                        local ug = CreateGroup()
                        MakeGroupInRange(GetPlayerId(missile.owner) + 1, ug, missile.x, missile.y, ARCANEBOLTS.aoe, Condition(FilterEnemy))

                        for enemy in each(ug) do
                            DamageTarget(missile.source, enemy, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                        end

                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", missile.x, missile.y))

                        return true
                    end

                    return false
                end

                missile:launch()

                pt.timer:callDelayed(0.2, spawn, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            pt.dur = self.ablev + 2
            pt.angle = self.angle
            pt.source = self.caster
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.x = self.x + 1000. * Cos(pt.angle)
            pt.y = self.y + 1000. * Sin(pt.angle)
            pt.timer:callDelayed(0., spawn, pt)
        end
    end

    ---@class ARCANEBARRAGE : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field cooldown function
    ARCANEBARRAGE = Spell.define("A02N")
    do
        local thistype = ARCANEBARRAGE

        thistype.values = {
            aoe = 750.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (ablev + 1.) end,
            cooldown = function(pid) return TimerList[pid]:has(ARCANOSPHERE.id) and 8. or 25. end,
        }

        function thistype:onCast()
            ArcaneBarrageBuff:add(self.caster, self.caster):duration(3)

            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            local size = BlzGroupGetSize(ug) ---@type integer
            local target = FirstOfGroup(ug)
            local singletarget = false

            if target then
                if size == 1 then
                    singletarget = true
                    size = 3
                end

                for i = 0, size - 1 do
                    if not singletarget then
                        target = BlzGroupUnitAt(ug, i)
                    end
                    self.targetX = self.x + 40. * Cos(bj_DEGTORAD * (GetUnitFacing(Hero[self.pid]) + i * (360. / size)))
                    self.targetY = self.y + 40. * Sin(bj_DEGTORAD * (GetUnitFacing(Hero[self.pid]) + i * (360. / size)))

                    local missile = Missiles:create(self.targetX, self.targetY, 50., 0, 0, 20.) ---@type Missiles
                    missile:model("war3mapImported\\TinkerRocketMissileModified2.mdl")
                    missile:scale(1.1)
                    missile:speed(750)
                    missile.source = self.caster
                    missile.owner = Player(self.pid - 1)
                    missile.target = target
                    missile:vision(400)
                    missile.collision = 10
                    missile.collideZ = true
                    missile.damage = self.dmg * BOOST[self.pid]

                    missile.onFinish = function()
                        DamageTarget(missile.source, missile.target, missile.damage, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)

                        return true
                    end

                    missile:launch()
                end
            end

            DestroyGroup(ug)
        end
    end

    ---@class ARCANOSPHERE : Spell
    ---@field dur function
    ARCANOSPHERE = Spell.define("A079")
    do
        local thistype = ARCANOSPHERE

        thistype.values = {
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 8. + 4. * ablev end,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

            pt.dur = pt.dur - 0.5

            if pt.dur > 0. then
                for target in each(ug) do
                    ArcanosphereDebuff:add(pt.source, target):duration(1.)
                end

                if IsUnitInRangeXY(pt.source, pt.x, pt.y, pt.aoe) then
                    ArcanosphereBuff:add(pt.source, pt.source):duration(1.)
                end

                pt.timer:callDelayed(0.5, periodic, pt)
            else
                SetUnitAnimation(pt.target, "death")

                UnitRemoveAbility(pt.source, ARCANECOMETS.id)
                BlzUnitHideAbility(pt.source, ARCANEBOLTS.id, false)
                BlzSetUnitAbilityCooldown(pt.source, ARCANEBARRAGE.id, GetUnitAbilityLevel(pt.source, ARCANEBARRAGE.id) - 1, 25.)
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dur = self.dur * LBOOST[self.pid]
            pt.aoe = 800.
            pt.x = self.targetX
            pt.y = self.targetY
            pt.source = self.caster
            pt.tag = thistype.id

            pt.target = Dummy.create(self.targetX, self.targetY, 0, 0, pt.dur + 1.5).unit
            BlzSetUnitSkin(pt.target, FourCC('e00M'))
            SetUnitScale(pt.target, 10., 10., 10.)
            SetUnitFlyHeight(pt.target, -50.00, 0.00)
            SetUnitAnimation(pt.target, "birth")
            SetUnitTimeScale(pt.target, 0.4)
            UnitDisableAbility(pt.target, FourCC('Amov'), true)

            --swap to comets
            UnitAddAbility(self.caster, ARCANECOMETS.id)
            SetUnitAbilityLevel(self.caster, ARCANECOMETS.id, GetUnitAbilityLevel(self.caster, ARCANEBOLTS.id))
            BlzUnitHideAbility(self.caster, ARCANEBOLTS.id, true)

            --barrage cooldown
            BlzEndUnitAbilityCooldown(self.caster, ARCANEBARRAGE.id)
            BlzSetUnitAbilityCooldown(self.caster, ARCANEBARRAGE.id, GetUnitAbilityLevel(self.caster, ARCANEBARRAGE.id) - 1, 8.)

            pt.timer:callDelayed(0.5, periodic, pt)
        end
    end

    ---@class STASISFIELD : Spell
    ---@field aoe number
    ---@field dur number
    STASISFIELD = Spell.define("A075")
    do
        local thistype = STASISFIELD

        thistype.values = {
            aoe = 250.,
            dur = 6.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.dur = pt.dur - 0.25

            if pt.dur > 0. then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

                for target in each(ug) do
                    StasisFieldDebuff:add(pt.source, target):duration(0.5)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.25, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.x = self.targetX
            pt.y = self.targetY
            pt.dur = self.dur * LBOOST[self.pid]
            pt.source = self.caster

            pt.target = Dummy.create(pt.x, pt.y, 0, 0, 6.).unit
            BlzSetUnitSkin(pt.target, FourCC('h02B'))
            SetUnitScale(pt.target, 1.05 * LBOOST[self.pid], 1.05 * LBOOST[self.pid], 1.05 * LBOOST[self.pid])
            UnitDisableAbility(pt.target, FourCC('Amov'), true)
            SetUnitFlyHeight(pt.target, 0., 0.)
            SetUnitAnimation(pt.target, "birth")

            pt.timer:callDelayed(0.25, periodic, pt)
        end
    end

    ---@class ARCANESHIFT : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field dur number
    ARCANESHIFT = Spell.define("A078")
    do
        local thistype = ARCANESHIFT

        thistype.values = {
            aoe = 350.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (5. + 3. * ablev) * GetHeroInt(Hero[pid], true) end,
            dur = 4.,
        }

        function thistype.preCast(pid, tpid, caster, target, x, y, targetX, targetY)
            local pt = TimerList[pid]:get(thistype.id, caster)

            if not IsTerrainWalkable(targetX, targetY) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(Player(pid - 1), 0, 0, INVALID_TARGET_MESSAGE)
            elseif pt then
                if DistanceCoords(targetX, targetY, pt.x, pt.y) > 1500. then
                    IssueImmediateOrderById(caster, ORDER_ID_STOP)
                    DisplayTextToPlayer(Player(pid - 1), 0, 0, "|cffff0000Target point is too far away!")
                end
            end
        end

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.time = pt.time + FPS_32

            if pt.time >= pt.dur then
                for target in each(pt.ug) do
                    SetUnitFlyHeight(target, 0.00, 0.00)
                    if GetUnitMoveSpeed(target) > 0 then
                        SetUnitPathing(target, false)
                        SetUnitXBounded(target, pt.x)
                        SetUnitYBounded(target, pt.y)
                        ResetPathingTimed(target, 2.)
                    end
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
                    DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end

                BlzStartUnitAbilityCooldown(pt.source, thistype.id, pt.cooldown - pt.time)

                pt:destroy()
            else
                pt.timer:callDelayed(FPS_32, periodic, pt)
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(thistype.id, self.caster)

            --second cast
            if pt then
                pt.x = self.targetX
                pt.y = self.targetY
                pt.dur = 0.
            else
                local ug = CreateGroup()

                MakeGroupInRange(self.pid, ug, self.targetX, self.targetY, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

                if FirstOfGroup(ug) then
                    pt = TimerList[self.pid]:add()
                    pt.ug = CreateGroup()
                    pt.dmg = self.dmg * BOOST[self.pid]
                    pt.dur = self.dur * LBOOST[self.pid]
                    pt.cooldown = 80 --original cooldown
                    pt.source = self.caster
                    pt.tag = thistype.id
                    pt.x = self.targetX
                    pt.y = self.targetY

                    for target in each(ug) do
                        GroupAddUnit(pt.ug, target)
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", GetUnitX(target), GetUnitY(target)))
                        if UnitAddAbility(target, FourCC('Amrf')) then
                            UnitRemoveAbility(target, FourCC('Amrf'))
                        end
                        Stun:add(self.caster, target):duration(pt.dur)
                        SetUnitFlyHeight(target, 500.00, 0.00)
                    end

                    TimerQueue:callDelayed(FPS_32, BlzEndUnitAbilityCooldown, pt.source, thistype.id)
                    pt.timer:callDelayed(FPS_32, periodic, pt)
                end

                DestroyGroup(ug)
            end
        end
    end

    --dark savior

    ---@class SOULSTEAL : Spell
    SOULSTEAL = Spell.define("A08Z")
    do
        local thistype = SOULSTEAL
    end

    ---@class DARKSEAL : Spell
    ---@field dur number
    DARKSEAL = Spell.define("A0GO")
    do
        local thistype = DARKSEAL

        thistype.values = {
            dur = 12.,
        }

        function thistype:onCast()
            local b = DarkSealBuff:add(self.caster, self.caster)

            b:duration(self.dur * LBOOST[self.pid])
            b.x = self.targetX
            b.y = self.targetY
            SetUnitXBounded(b.sfx, b.x)
            SetUnitYBounded(b.sfx, b.y)
        end
    end

    ---@class MEDEANLIGHTNING : Spell
    ---@field targets function
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    MEDEANLIGHTNING = Spell.define("A019")
    do
        local thistype = MEDEANLIGHTNING

        thistype.values = {
            targets = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 1.5 end,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (1.5 + 0.5 * ablev) * GetHeroInt(Hero[pid], true) end,
            aoe = 900.,
            dur = 3.,
        }

        local function onHit(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1

            DamageTarget(source, target, thistype.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
        end

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            local x = GetUnitX(pt.source) ---@type number 
            local y = GetUnitY(pt.source) ---@type number 

            pt.dur = pt.dur - 1
            DestroyEffect(pt.sfx)

            if pt.dur < 0 then
                pt:destroy()
            else
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

                local target
                for i = 0, pt.time - 1 do
                    target = BlzGroupUnitAt(ug, i)
                    if not target then break end
                    local dummy = Dummy.create(x, y, FourCC('A01Y'), 1, 2.)
                    dummy:attack(target, pt.source, onHit)
                end

                --dark seal augment
                local b = DarkSealBuff:get(pt.source, pt.source)

                if b then
                    BlzGroupAddGroupFast(ug, b.ug)
                    local count = BlzGroupGetSize(ug)

                    if count > 0 then
                        for index = 0, count - 1 do
                            target = BlzGroupUnitAt(ug, index)

                            if GetUnitAbilityLevel(target, FourCC('A06W')) > 0 then
                                local angle = 360. / count * (index + 1) * bj_DEGTORAD
                                x = b.x + 380 * Cos(angle)
                                y = b.y + 380 * Sin(angle)

                                local dummy = Dummy.create(x, y, FourCC('A01Y'), 1, 2.)
                                dummy:attack(target, pt.source, onHit)
                            end
                        end
                    end
                end

                if pt.dur > 0. then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\LightningShield" .. IMinBJ(3, R2I(pt.dur)) .. ".mdx", Hero[pt.pid], "origin")
                    BlzSetSpecialEffectTimeScale(pt.sfx, 1.5)
                    BlzPlaySpecialEffect(pt.sfx, ANIM_TYPE_STAND)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(1., periodic, pt)
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.time = R2I(self.targets * LBOOST[self.pid])
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dur = self.dur * LBOOST[self.pid]
            pt.sfx = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\LightningShield\\LightningShieldTarget.mdl", self.caster, "origin")
            pt.source = self.caster
            BlzSetSpecialEffectTimeScale(pt.sfx, 1.5)

            pt.timer:callDelayed(1., periodic, pt)
        end
    end

    ---@class FREEZINGBLAST : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field slow number
    ---@field freeze number
    FREEZINGBLAST = Spell.define("A074")
    do
        local thistype = FREEZINGBLAST

        thistype.values = {
            aoe = 250.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (ablev + 2.) end,
            slow = 3.,
            freeze = 1.5,
        }

        function thistype:onCast()
            local b = DarkSealBuff:get(self.caster, self.caster)
            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.targetX, self.targetY, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            --dark seal
            if b then
                BlzGroupAddGroupFast(ug, b.ug)

                local sfx = AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", b.x, b.y)
                BlzSetSpecialEffectScale(sfx, 5)
                TimerQueue:callDelayed(3, DestroyEffect, sfx)
            end

            DestroyEffect(AddSpecialEffect("war3mapImported\\AquaSpikeVersion2.mdx", self.targetX, self.targetY))

            for target in each(ug) do
                Freeze:add(self.caster, target):duration(self.freeze * LBOOST[self.pid])
                if IsUnitInRangeXY(target, self.targetX, self.targetY, self.aoe * LBOOST[self.pid]) == true and b then
                    DamageTarget(self.caster, target, self.dmg * 2 * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                else
                    DamageTarget(self.caster, target, self.dmg * BOOST[self.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                end
            end
        end
    end

    ---@class DARKBLADE : Spell
    ---@field dmg function
    ---@field cost function
    DARKBLADE = Spell.define("AEim")
    do
        local thistype = DARKBLADE

        thistype.values = {
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.6 + 0.1 * ablev) * GetHeroInt(Hero[pid], true) end,
        }

        local function onHit(source, target)
            if GetUnitAbilityLevel(source, FourCC('B01A')) > 0 then
                local pid = GetPlayerId(GetOwningPlayer(source)) + 1
                local maxmp = BlzGetUnitMaxMana(source)
                local pmana = GetUnitState(source, UNIT_STATE_MANA) / maxmp * 100.
                local pgain = (MetamorphosisBuff:has(source, source) and 0.5) or -1.0

                if pmana >= 0.5 or pgain > 0 then
                    SetUnitState(source, UNIT_STATE_MANA, (pmana + pgain) * maxmp * 0.01)
                    DamageTarget(source, target, thistype.dmg(pid) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                else
                    IssueImmediateOrder(source, "unimmolation")
                end
            end
        end

        function thistype.onLearn(source, ablev, pid)
            EVENT_ON_HIT:register_unit_action(source, onHit)
        end
    end

    ---@class METAMORPHOSIS : Spell
    ---@field dur function
    METAMORPHOSIS = Spell.define("A02S")
    do
        local thistype = METAMORPHOSIS

        thistype.values = {
            dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 5. + 5. * ablev end,
        }

        function thistype.preCast(pid, tpid, caster, target, x, y, targetX, targetY)
            local ablev = GetUnitAbilityLevel(caster, thistype.id)
            BlzSetAbilityRealLevelField(BlzGetUnitAbility(caster, METAMORPHOSIS.id), ABILITY_RLF_DURATION_HERO, ablev - 1, thistype.dur(pid) * LBOOST[pid])
        end

        function thistype:onCast()
            if GetUnitTypeId(self.caster) == HERO_DARK_SAVIOR then
                MetamorphosisBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
            end
        end
    end

    --bard

    BARD_SONG = __jarray(0)

    local song_color = {
        [SONG_FATIGUE] = 3,
        [SONG_HARMONY] = 6,
        [SONG_PEACE] = 4,
        [SONG_WAR] = 0
    }

    local function change_song(self, song)
        local p = Player(self.pid - 1)

        BARD_SONG[self.pid] = song
        SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
        SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
        SetPlayerAbilityAvailable(p, SONG_PEACE, false)
        SetPlayerAbilityAvailable(p, SONG_WAR, false)

        SetPlayerAbilityAvailable(p, song, true)
        if songeffect[self.pid] == nil then
            songeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", self.caster, "overhead")
        end
        BlzSetSpecialEffectColorByPlayer(songeffect[self.pid], Player(song_color[song]))
    end

    ---@class SONGOFFATIGUE : Spell
    local SONGOFFATIGUE = Spell.define("A025")
    do
        local thistype = SONGOFFATIGUE

        function thistype:onCast()
            change_song(self, SONG_FATIGUE)
        end
    end

    ---@class SONGOFHARMONY : Spell
    local SONGOFHARMONY = Spell.define("A026")
    do
        local thistype = SONGOFHARMONY

        function thistype:onCast()
            change_song(self, SONG_HARMONY)
        end
    end

    ---@class SONGOFPEACE : Spell
    local SONGOFPEACE = Spell.define("A027")
    do
        local thistype = SONGOFPEACE

        function thistype:onCast()
            change_song(self, SONG_PEACE)
        end
    end

    ---@class SONGOFWAR : Spell
    local SONGOFWAR = Spell.define("A02C")
    do
        local thistype = SONGOFWAR

        function thistype:onCast()
            change_song(self, SONG_WAR)
        end
    end

    ---@class ENCORE : Spell
    ---@field aoe number
    ---@field wardur number
    ---@field heal function
    ---@field peacedur number
    ---@field fatiguedur number
    ---@field onHit function
    ENCORE = Spell.define("A0AZ")
    do
        local thistype = ENCORE

        thistype.values = {
            aoe = 900.,
            wardur = 5.,
            heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (.75 + .25 * ablev) end,
            peacedur = 5.,
            fatiguedur = 3.,
        }

        function thistype:onCast()
            local ug = CreateGroup()
            local p = Player(self.pid - 1)

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(isalive))

            -- harmony all allied units
            -- war all allied heroes
            -- fatigue all enemies
            -- peace all heroes

            -- improv
            local pt = TimerList[self.pid]:get(IMPROV.id, nil, self.caster)
            local x2, y2, aoe, song = 0, 0, 0, 0

            if pt then
                GroupEnumUnitsInRangeEx(self.pid, ug, pt.x, pt.y, pt.aoe, Condition(isalive))
                x2 = pt.x
                y2 = pt.y
                aoe = pt.aoe
                song = pt.song ---@type integer 
            end

            for target in each(ug) do
                self.tpid = GetPlayerId(GetOwningPlayer(target)) + 1

                -- allied units
                if IsUnitAlly(target, p) == true then
                    -- song of harmony
                    if (BARD_SONG[self.pid] == SONG_HARMONY and IsUnitInRangeXY(target, self.x, self.y, aoe)) or (song == SONG_HARMONY and IsUnitInRangeXY(target, x2, y2, aoe)) then
                        HP(self.caster, target, self.heal * BOOST[self.pid], thistype.tag)
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", target, "origin"))
                    end
                    -- heroes
                    if target == Hero[self.tpid] then
                        -- song of war
                        if (BARD_SONG[self.pid] == SONG_WAR and IsUnitInRangeXY(target, self.x, self.y, aoe)) or (song == SONG_WAR and IsUnitInRangeXY(target, x2, y2, aoe)) then
                            SongOfWarEncoreBuff:add(self.caster, target):duration(thistype.wardur * LBOOST[self.pid])
                        end
                        -- song of peace
                        if (BARD_SONG[self.pid] == SONG_PEACE and IsUnitInRangeXY(target, self.x, self.y, aoe)) or (song == SONG_PEACE and IsUnitInRangeXY(target, x2, y2, aoe)) then
                            SongOfPeaceEncoreBuff:add(self.caster, target):duration(thistype.peacedur * LBOOST[self.pid])
                        end
                    end
                else
                -- enemies
                    -- song of fatigue
                    if (BARD_SONG[self.pid] == SONG_FATIGUE and IsUnitInRangeXY(target, self.x, self.y, aoe)) or (song == SONG_FATIGUE and IsUnitInRangeXY(target, x2, y2, aoe)) then
                        StunUnit(self.pid, target, thistype.fatiguedur * LBOOST[self.pid])
                    end
                end
            end
        end
    end

    ---@class MELODYOFLIFE : Spell
    ---@field cost function
    ---@field heal function
    MELODYOFLIFE = Spell.define("A02H")
    do
        local thistype = MELODYOFLIFE

        thistype.values = {
            cost = function(pid) return Roundmana(GetUnitState(Hero[pid], UNIT_STATE_MANA) * .1) end,
            heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return thistype.cost(pid) * (.25 + .25 * ablev) end,
        }

        function thistype:onCast()
            local p = Player(self.pid - 1)
            local heal = self.heal * BOOST[self.pid] ---@type number 

            if GetUnitTypeId(self.target) == BACKPACK then
                HP(self.caster, Hero[self.tpid], heal, thistype.tag)
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", GetUnitX(Hero[self.tpid]), GetUnitY(Hero[self.tpid])))
            elseif IsUnitAlly(self.target, p) then
                HP(self.caster, self.target, heal, thistype.tag)
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", self.targetX, self.targetY))
            end
        end
    end

    ---@class IMPROV : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field dur number
    IMPROV = Spell.define("A06Y")
    do
        local thistype = IMPROV

        thistype.values = {
            aoe = 750.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.25 + 0.25 * ablev) * GetHeroInt(Hero[pid], true) end,
            dur = 20.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)
            pt.time = pt.time + 1.

            if pt.time >= pt.dur then
                BlzSetSpecialEffectScale(pt.sfx, 1.)
                SetUnitScale(pt.source, 1., 1., 1.)
                pt:destroy()
            else
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(isalive))

                for target in each(ug) do
                    if IsUnitAlly(target, Player(pt.pid - 1)) == false then
                        if ModuloInteger(R2I(pt.time),2) == 0 then
                            DamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                        end
                        if pt.song == SONG_FATIGUE then
                            SongOfFatigueSlow:add(Hero[pt.pid], target):duration(2.)
                        end
                    else
                        if pt.song == SONG_WAR then
                            local buff = SongOfWarBuff:get(nil, target)

                            --allow for damage bonus refresh
                            if buff then
                                buff:remove()
                            end

                            SongOfWarBuff:add(Hero[pt.pid], target):duration(2.)
                        end
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(1., periodic, pt)
            end
        end

        function thistype:onCast()
            if BARD_SONG[self.pid] ~= 0 then
                local pt = TimerList[self.pid]:add()

                pt.x = self.targetX
                pt.y = self.targetY
                pt.song = BARD_SONG[self.pid]
                pt.tag = thistype.id --important for aura check
                pt.aoe = self.aoe * LBOOST[self.pid]
                pt.dmg = self.dmg
                pt.dur = self.dur * LBOOST[self.pid]
                pt.target = self.caster
                pt.source = Dummy.create(pt.x, pt.y, 0, 0, pt.dur).unit

                SetUnitScale(pt.source, 3., 3., 3.)
                SetUnitOwner(pt.source, Player(PLAYER_TOWN), true)

                --the order matters here
                UnitAddAbility(pt.source, BARD_SONG[self.pid])

                --auras for allies
                if BARD_SONG[self.pid] ~= SONG_FATIGUE then
                    BlzSetAbilityRealLevelField(BlzGetUnitAbility(pt.source, BARD_SONG[self.pid]), ABILITY_RLF_AREA_OF_EFFECT, 0, pt.aoe)
                    IncUnitAbilityLevel(pt.source, BARD_SONG[self.pid])
                    DecUnitAbilityLevel(pt.source, BARD_SONG[self.pid])
                end

                if BARD_SONG[self.pid] == SONG_WAR then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingRed.mdx", pt.source, "origin")
                elseif BARD_SONG[self.pid] == SONG_HARMONY then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingGreen.mdx", pt.source, "origin")
                elseif BARD_SONG[self.pid] == SONG_PEACE then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingYellow.mdx", pt.source, "origin")
                elseif BARD_SONG[self.pid] == SONG_FATIGUE then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingPurple.mdx", pt.source, "origin")
                end

                BlzSetSpecialEffectScale(pt.sfx, 4.5)

                pt.timer:callDelayed(1., periodic, pt)
            end
        end
    end

    ---@class INSPIRE : Spell
    INSPIRE = Spell.define("A09Y")
    do
        local thistype = INSPIRE

        function thistype:onCast()
            InspireBuff:add(self.caster, self.caster)
        end
    end

    ---@class TONEOFDEATH : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field dur number
    TONEOFDEATH = Spell.define("A02K")
    do
        local thistype = TONEOFDEATH

        thistype.values = {
            aoe = 350.,
            dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.5 + 0.5 * ablev) * GetHeroInt(Hero[pid], true) end,
            dur = 5.,
        }

        ---@type fun(pt: PlayerTimer)
        local function periodic(pt)

            pt.count = pt.count + 1
            pt.dur = pt.dur - FPS_32

            if pt.dur > 0. then
                x = GetUnitX(pt.target) + 3 * Cos(pt.angle)
                y = GetUnitY(pt.target) + 3 * Sin(pt.angle)

                --blackhole movement
                SetUnitXBounded(pt.target, x)
                SetUnitYBounded(pt.target, y)

                local ug = CreateGroup()
                local rand = GetRandomReal(bj_PI // -9., bj_PI // 9.) ---@type number 

                MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), pt.aoe, Condition(FilterEnemy))

                for target in each(ug) do
                    --enemy movement
                    if GetUnitMoveSpeed(target) > 0 then
                        local angle = Atan2(GetUnitY(pt.target) - GetUnitY(target), GetUnitX(pt.target) - GetUnitX(target))
                        local x = GetUnitX(target) + (17. + 30. / (UnitDistance(target, pt.target) + 1)) * Cos(angle + rand)
                        local y = GetUnitY(target) + (17. + 30. / (UnitDistance(target, pt.target) + 1)) * Sin(angle + rand)

                        if GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(x, y) then
                            if IsUnitType(target, UNIT_TYPE_HERO) == false then
                                SetUnitPathing(target, false)
                            end
                            SetUnitXBounded(target, x)
                            SetUnitYBounded(target, y)
                        end
                    end

                    --damage per second
                    if ModuloInteger(pt.count,32) == 0 then
                        DamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
                    end
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.angle = self.angle
            pt.target = Dummy.create(self.x + 250 * Cos(pt.angle), self.y + 250 * Sin(pt.angle), 0, 0, 6.).unit
            pt.sfx = AddSpecialEffectTarget("war3mapImported\\BlackHoleSpell.mdx", pt.target, "origin")
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dmg = self.dmg
            pt.dur = self.dur * LBOOST[self.pid]
            pt.count = 0
            SetUnitScale(pt.target, 0.5, 0.5, 0.5)

            pt.timer:callDelayed(FPS_32, periodic, pt)
        end
    end

end, Debug and Debug.getLine())
