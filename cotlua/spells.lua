if Debug then Debug.beginFile 'Spells' end

OnInit.final("Spells", function(require)
    require "Users"

    SKINS_PER_PAGE          = 6 ---@type integer 
    SONG_WAR                = FourCC('A024') ---@type integer 
    SONG_HARMONY            = FourCC('A01A') ---@type integer 
    SONG_PEACE              = FourCC('A09X') ---@type integer 
    SONG_FATIGUE            = FourCC('A00N') ---@type integer 

    dPage                   =__jarray(0) ---@type integer[] 
    DMG_NUMBERS             =__jarray(0) ---@type integer[] 
    ResurrectionRevival     =__jarray(0) ---@type integer[] 
    undyingRageAttackBonus  =__jarray(0) ---@type integer[] 
    golemDevourStacks       =__jarray(0) ---@type integer[] 
    destroyerDevourStacks   =__jarray(0) ---@type integer[] 
    saviorBashCount         =__jarray(0) ---@type integer[] 
    BardSong                =__jarray(0) ---@type integer[] 
    BladeSpinCount          =__jarray(0) ---@type integer[] 
    IntenseFocus            =__jarray(0) ---@type integer[] 
    metaDamageBonus         =__jarray(0) ---@type integer[] 
    masterElement           =__jarray(0) ---@type integer[] 
    BodyOfFireCharges       =__jarray(0) ---@type integer[] 
    lastCast                =__jarray(0) ---@type integer[] 
    limitBreak              =__jarray(0) ---@type integer[] 
    limitBreakPoints        =__jarray(0) ---@type integer[] 
    TOTAL_SKINS             = 0 ---@type integer 

    BloodBank               =__jarray(0) ---@type number[] 
    BardMelodyCost          =__jarray(0) ---@type number[] 
    BorrowedLife            =__jarray(0) ---@type number[] 

    isteleporting           =__jarray(false) ---@type boolean[] 
    HiddenGuise             =__jarray(false) ---@type boolean[] 
    sniperstance            =__jarray(false) ---@type boolean[] 
    hero_panel_on           =__jarray(false) ---@type boolean[] 
    aoteCD                  =__jarray(false) ---@type boolean[] 
    ReincarnationRevival    =__jarray(false) ---@type boolean[] 
    heliCD                  =__jarray(false) ---@type boolean[] 
    destroyerSacrificeFlag  =__jarray(false) ---@type boolean[] 
    magneticForceFlag       =__jarray(false) ---@type boolean[] 
    PhantomSlashing         =__jarray(false) ---@type boolean[] 
    InspireActive           =__jarray(false) ---@type boolean[] 

    FlightTarget    ={} ---@type location[] 
    attargetpoint   ={} ---@type location[] 
    lightningeffect ={} ---@type effect[] 
    songeffect      ={} ---@type effect[] 
    InstillFear     ={} ---@type unit[] 

    INVALID_TARGET_MESSAGE        = "|cffff0000Cannot target there!|r" ---@type string 
    STOOLTIP=__jarray("") ---@type string[] 

    ---@class Spell
    ---@field id integer
    ---@field sid integer
    ---@field caster unit
    ---@field target unit
    ---@field pid integer
    ---@field tpid integer
    ---@field ablev integer
    ---@field x number
    ---@field y number
    ---@field targetX number
    ---@field targetY number
    ---@field angle number
    ---@field update function
    ---@field onCast function
    ---@field values table
    ---@field value number[]
    ---@field create function
    ---@field destroy function
    Spell = {}
    do
        local thistype = Spell
        thistype.id          = 0 ---@type integer
        thistype.caster      = nil ---@type unit 
        thistype.target      = nil ---@type unit 
        thistype.pid         = 0 ---@type integer 
        thistype.tpid        = 0 ---@type integer 
        thistype.ablev       = 0 ---@type integer 
        thistype.x           = 0. ---@type number 
        thistype.y           = 0. ---@type number 
        thistype.targetX     = 0. ---@type number 
        thistype.targetY     = 0. ---@type number 
        thistype.angle       = 0. ---@type number 
        thistype.values      = {} ---@type table

        function thistype:destroy()
            self = nil
        end

        ---@type fun(pid: integer):Spell
        function thistype:create(pid)
            local spell = {
                pid = pid,
                ablev = GetUnitAbilityLevel(Hero[pid], self.id)
            }

            setmetatable(spell, { __index = self })

            --assigns function values as a number (i.e self.dur) on creation
            for k, v in pairs(self) do --sync safe
                if type(v) == "function" then
                    --must be contained inside self.values table
                    for _, value in ipairs(self.values) do
                        if value == v then
                            spell[k] = v(pid)
                            break
                        end
                    end
                end
            end

            return spell
        end

        --Stub method
        function thistype:onCast() end
    end

    --savior

    ---@class LIGHTSEAL : Spell
    ---@field id integer
    ---@field dur number
    ---@field aoe number
    LIGHTSEAL = {}
    do
        local thistype = LIGHTSEAL
        thistype.id = FourCC('A07C') ---@type integer 
        thistype.dur = 12. ---@type number
        thistype.aoe = 450. ---@type number
        thistype.values = {thistype.dur, thistype.aoe}

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
            pt.target = GetDummy(pt.x, pt.y, 0, 0, pt.dur)
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
    DIVINEJUDGEMENT = {}
    do
        local thistype = DIVINEJUDGEMENT
        thistype.id = FourCC('A038') ---@type integer 
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.2 + 0.3 * ablev) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) + BlzGetUnitBaseDamage(Hero[pid], 0)) end ---@return number
        thistype.values = {thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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
                        UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end
                end
                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)

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
            pt.target = GetDummy(self.x, self.y, 0, 0, DUMMY_RECYCLE_TIME)
            pt.source = self.caster
            pt.dur = 1000.
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.ug = CreateGroup()

            BlzSetUnitSkin(pt.target, FourCC('h00X'))
            BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)
            SetUnitScale(pt.target, 1.1, 1.1, 0.8)
            SetUnitFlyHeight(pt.target, 25.00, 0.)

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class SAVIORSGUIDANCE : Spell
    ---@field shield function
    ---@field dur function
    SAVIORSGUIDANCE = {}
    do
        local thistype = SAVIORSGUIDANCE
        thistype.id = FourCC('A0KU') ---@type integer
        thistype.shield = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * (2.25 + .25 * ablev) end ---@return number
        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 9. + ablev end ---@return number
        thistype.values = {thistype.shield, thistype.dur}

        function thistype:onCast()
            local pt = TimerList[pid]:get(LIGHTSEAL.id, self.caster)

            --light seal augment
            if pt then
                MakeGroupInRange(self.pid, pt.ug, pt.x, pt.y, pt.aoe, Condition(FilterAllyHero))

                if self.caster ~= self.target and UnitAlive(self.target) then
                    GroupAddUnit(pt.ug, self.target)
                end

                GroupAddUnit(pt.ug, self.caster)

                local target = FirstOfGroup(pt.ug)
                while target do
                    GroupRemoveUnit(pt.ug, target)
                    shield.add(target, thistype.shield(self.pid) * BOOST[self.pid], thistype.dur(self.pid))
                    target = FirstOfGroup(pt.ug)
                end
            --normal cast
            else
                if self.caster ~= self.target and self.target ~= nil then
                    shield.add(self.target, thistype.shield(self.pid) * BOOST[self.pid], thistype.dur(self.pid))
                end

                shield.add(self.caster, thistype.shield(self.pid) * BOOST[self.pid], thistype.dur(self.pid))
            end


        end
    end

    ---@class HOLYBASH : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field heal function
    HOLYBASH = {}
    do
        local thistype = HOLYBASH
        thistype.id = FourCC('A0GG') ---@type integer 
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev * (GetHeroStr(Hero[pid], true) + (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * .4) end ---@return number
        thistype.aoe = 600. ---@type number
        thistype.heal = function(pid) return 25 + 0.5 * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.values = {thistype.dmg, thistype.aoe, thistype.heal}
    end

    ---@class THUNDERCLAP : Spell
    ---@field dmg function
    ---@field aoe function
    THUNDERCLAP = {}
    do
        local thistype = THUNDERCLAP
        thistype.id = FourCC("A0AT") ---@type integer 

        thistype.dmg = function(pid) return 0.25 * (ablev + 1) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true) + BlzGetUnitBaseDamage(Hero[pid], 0)) end ---@return number
        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (200. + 50 * ablev) end ---@return number
        thistype.values = {thistype.dmg, thistype.aoe}

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(LIGHTSEAL.id, self.caster)
            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            if pt then
                GroupEnumUnitsInRangeEx(self.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))
                LightSealBuff:add(self.caster, self.caster):duration(20.)
            end

            for target in each(ug) do
                SaviorThunderClap:add(self.caster, target):duration(5.)
                if pt ~= 0 and IsUnitInRangeXY(target, pt.x, pt.y, pt.aoe) then
                    if IsUnitType(target, UNIT_TYPE_HERO) == true then
                        LightSealBuff:get(self.caster, self.caster):addStack(5)
                    else
                        LightSealBuff:get(self.caster, self.caster):addStack(1)
                    end
                end
                UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
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
    RIGHTEOUSMIGHT = {}
    do
        local thistype = RIGHTEOUSMIGHT
        thistype.id = FourCC("A08R") ---@type integer 

        thistype.attack = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (.2 + .2 * ablev) end ---@return number
        thistype.armor = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return BlzGetUnitArmor(Hero[pid]) * (.4 + (.2 * ablev)) + 0.5 end ---@return number
        thistype.heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return BlzGetUnitMaxHP(Hero[pid]) * (0.10 + 0.05 * ablev) end ---@return number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev + 1) * 2. * GetHeroStr(Hero[pid],true) end ---@return number
        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev + 1) * 5. end ---@return number
        thistype.values = {thistype.attack, thistype.armor, thistype.heal, thistype.dmg, thistype.dur}

        function thistype:onCast()
            local b = RighteousMightBuff:create()
            local ug = CreateGroup()
            local angle = 0. ---@type number 

            b.dmg = self.attack
            b.armor = self.armor
            b.pid = self.pid
            b = b:check(self.caster, self.caster)
            b.duration = self.dur * LBOOST[self.pid]

            HP(self.caster, self.heal * LBOOST[self.pid])

            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\HolyAwakening.mdx", self.caster, "origin"))

            for i = 1, 24 do
                angle = 2 * bj_PI * i / 24.
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", self.x + 500 * Cos(angle), self.y + 500 * Sin(angle)))
            end

            MakeGroupInRange(self.pid, ug, self.x, self.y, 500 * LBOOST[self.pid], Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        end
    end

    --elite marksman

    ---@class SNIPERSTANCE : Spell
    ---@field crit function
    SNIPERSTANCE = {}
    do
        local thistype = SNIPERSTANCE
        thistype.id = FourCC("A049") ---@type integer 

        ---@type fun(pid: integer):number
        thistype.crit = function(pid)
            local id   = 0 ---@type integer 
            local crit = 2. + GetHeroLevel(Hero[pid]) / 50 ---@type number 

            for i = 1, 5 do
                id = GetItemTypeId(UnitItemInSlot(Hero[pid], i))

                if id ~= 0 then
                    crit = crit + (ItemData[id][ITEM_CRIT_DAMAGE]) * (ItemData[id][ITEM_CRIT_CHANCE]) * 0.02
                end
            end

            return crit
        end
        thistype.values = {thistype.crit}

        ---@type fun(pt: PlayerTimer)
        function thistype.delay(pt)
            UnitRemoveAbility(Hero[pt.pid], FourCC('Avul'))
            UnitRemoveAbility(Hero[pt.pid], FourCC('A03C'))
            UnitAddAbility(Hero[pt.pid], FourCC('A03C'))

            pt:destroy()
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            local cd = 3.
            local s = "Disable"

            if sniperstance[self.pid] then
                cd = 6.
                s = "Enable"
            end

            for i = 0, 9 do
                BlzSetUnitAbilityCooldown(self.caster, TRIROCKET.id, i, cd)
                BlzSetAbilityStringLevelField(BlzGetUnitAbility(self.caster, thistype.id), ABILITY_SLF_TOOLTIP_NORMAL, i, s .. " Sniper Stance - [|cffffcc00D|r]")
            end

            sniperstance[self.pid] = not sniperstance[self.pid]

            UnitAddAbility(self.caster, FourCC('Avul'))
            pt.timer:callDelayed(FPS_32, thistype.delay, pt)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\Defend\\DefendCaster.mdl", self.caster, "origin"))
        end
    end

    ---@class TRIROCKET : Spell
    ---@field dmg function
    ---@field cd function
    TRIROCKET = {}
    do
        local thistype = TRIROCKET
        thistype.id = FourCC("A06I") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev * GetHeroAgi(Hero[pid], true) + (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * ablev * .1) end ---@return number
        thistype.cd = function(pid) return sniperstance[pid] and 3. or 6. end
        thistype.values = {thistype.dmg, thistype.cd}

        ---@type fun(pt: PlayerTimer)
        function thistype.rocketPeriodic(pt)
            pt.dur = pt.dur - 45

            if pt.dur > 0. then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), pt.aoe, Condition(FilterEnemy))
                SetUnitXBounded(pt.target, GetUnitX(pt.target) + 45 * Cos(bj_DEGTORAD * pt.angle))
                SetUnitYBounded(pt.target, GetUnitY(pt.target) + 45 * Sin(bj_DEGTORAD * pt.angle))
                BlzSetUnitFacingEx(pt.target, pt.angle)

                if BlzGroupGetSize(ug) > 0 then
                    --boom
                    DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\GyroCopter\\GyroCopterMissile.mdl", GetUnitX(pt.target), GetUnitY(pt.target)))
                    MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 150. * LBOOST[pt.pid], Condition(FilterEnemy))

                    local target = FirstOfGroup(ug)
                    while target do
                        GroupRemoveUnit(ug, target)
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        target = FirstOfGroup(ug)
                    end

                    RecycleDummy(pt.target)
                    pt:destroy()

                    DestroyGroup(ug)
                else
                    pt.timer:callDelayed(FPS_32, thistype.rocketPeriodic, pt)
                end
            else
                RecycleDummy(pt.target)
                pt:destroy()
            end
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 50.

            if pt.dur > 0. then
                local x = GetUnitX(Hero[pt.pid]) + 50. * Cos(bj_DEGTORAD * pt.angle)
                local y = GetUnitY(Hero[pt.pid]) + 50. * Sin(bj_DEGTORAD * pt.angle)

                if IsTerrainWalkable(x, y) then
                    SetUnitXBounded(Hero[pt.pid], x)
                    SetUnitYBounded(Hero[pt.pid], y)
                    pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
                else
                    pt:destroy()
                end
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt
            SoundHandler("Units\\Human\\SteamTank\\SteamTankAttack1.flac", true, Player(self.pid - 1), self.caster)

            for i = 0, 2 do
                pt = TimerList[self.pid]:add()
                pt.target = GetDummy(self.x, self.y, 0, 0, 0)
                pt.aoe = 100. --hit range
                pt.dur = 700.
                pt.angle = (bj_RADTODEG * self.angle + (10. * i - 10.))
                pt.dmg = self.dmg * BOOST[self.pid]
                BlzSetUnitFacingEx(pt.target, pt.angle)
                BlzSetUnitSkin(pt.target, FourCC('h01C'))
                SetUnitFlyHeight(pt.target, 75., 0.)
                SetUnitScalePercent(pt.target, 100.00, 100.00, 100.00)
                pt.timer:callDelayed(FPS_32, thistype.rocketPeriodic, pt)
            end

            --movement
            pt = TimerList[self.pid]:add()
            pt.dur = 250.
            pt.angle = (bj_RADTODEG * self.angle - 180)
            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class ASSAULTHELICOPTER : Spell
    ---@field dmg function
    ---@field dur number
    ASSAULTHELICOPTER = {}
    do
        local thistype = ASSAULTHELICOPTER
        thistype.id = FourCC("A06U") ---@type integer 

        thistype.dmg = function(pid) return 0.35 * (BlzGetUnitBaseDamage(Hero[pid], 0) + GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.dur = 30. ---@type number
        thistype.values = {thistype.dmg, thistype.dur}
    end

    ---@class SINGLESHOT : Spell
    ---@field dmg function
    SINGLESHOT = {}
    do
        local thistype = SINGLESHOT
        thistype.id = FourCC("A05D") ---@type integer 
        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 5. end ---@return number
        thistype.values = {thistype.dmg}

        function thistype:onCast()
            self.x = self.x + 80. * Cos(GetUnitFacing(self.caster) * bj_DEGTORAD)
            self.y = self.y + 80. * Sin(GetUnitFacing(self.caster) * bj_DEGTORAD)
            self.angle = Atan2(MouseY[self.pid] - self.y, MouseX[self.pid] - self.x) * bj_RADTODEG
            local newangle = (180. - RAbsBJ(RAbsBJ(self.angle - GetUnitFacing(self.caster)) - 180.)) * 0.5
            self.angle = bj_DEGTORAD * (self.angle + GetRandomReal(-(newangle), newangle))

            local dummy = GetDummy(self.x + 1500. * Cos(self.angle), self.y + 1500. * Sin(self.angle), 0, 0, 1.5)
            SetUnitOwner(dummy, Player(self.pid - 1), true)
            UnitRemoveAbility(dummy, FourCC('Avul'))
            UnitRemoveAbility(dummy, FourCC('Aloc'))
            local target = GetDummy(self.x, self.y, FourCC('A05J'), 1, 1.5)
            SetUnitOwner(target, Player(self.pid - 1), false)
            BlzSetUnitFacingEx(target, bj_RADTODEG * self.angle)
            UnitDisableAbility(target, FourCC('Amov'), true)
            InstantAttack(target, dummy)
            SoundHandler("war3mapImported\\xm1014-3.wav", false, Player(self.pid - 1), nil)

            local ug = CreateGroup()

            for _ = 1, 30 do
                MakeGroupInRange(self.pid, ug, self.x, self.y, 150. * LBOOST[self.pid], Condition(FilterEnemy))

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    if SingleShotDebuff:has(self.caster, target) == false then
                        UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end
                    SingleShotDebuff:add(self.caster, target):duration(3.)
                    target = FirstOfGroup(ug)
                end

                self.x = self.x + 50 * Cos(self.angle)
                self.y = self.y + 50 * Sin(self.angle)
            end

            DestroyGroup(ug)
        end
    end

    ---@class HANDGRENADE : Spell
    ---@field dmg function
    ---@field dmg2 function
    HANDGRENADE = {}
    do
        local thistype = HANDGRENADE
        thistype.id = FourCC("A0J4") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (0.4 + 0.1 * ablev) end ---@return number
        thistype.dmg2 = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * (0.9 + 0.1 * ablev) end ---@return number
        thistype.values = {thistype.dmg, thistype.dmg2}

        ---@type fun(pt: PlayerTimer)
        function thistype.rocketPeriodic(pt)
            local target = GetDummy(GetUnitX(helicopter[pt.pid]), GetUnitY(helicopter[pt.pid]), FourCC('A04F'), 1, DUMMY_RECYCLE_TIME) ---@type unit 

            pt.dur = pt.dur - 1
            pt.timer:callDelayed(0.7, thistype.rocketPeriodic, pt)

            if pt.dur == 0 then
                SoundHandler("Units\\Human\\Gyrocopter\\GyrocopterPissed1.flac", true, nil, helicopter[pt.pid])
                SetUnitFlyHeight(target, GetUnitFlyHeight(helicopter[pt.pid]), 30000.)
                IssuePointOrder(target, "clusterrockets", pt.x, pt.y)
            elseif pt.dur < 0 then
                local ug = CreateGroup()
                --explode
                DestroyEffect(AddSpecialEffect("war3mapImported\\NewMassiveEX.mdx", pt.x, pt.y))
                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, 400. * heliboost[pt.pid], Condition(FilterEnemy))

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    StunUnit(pt.pid, target, 4.)
                    UnitDamageTarget(Hero[pt.pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt:destroy()
            end
        end

        function thistype.grenadeExplosion(pt)
            local ug = CreateGroup()
            local x = GetUnitX(pt.target) ---@type number 
            local y = GetUnitY(pt.target) ---@type number 

            MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                StunUnit(pt.pid, target, 3.)
                UnitDamageTarget(Hero[pt.pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            SetUnitAnimation(pt.target, "death")
            DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
            DestroyGroup(ug)

            pt:destroy()
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.grenadePeriodic(pt)
            local x = GetUnitX(pt.target) ---@type number 
            local y = GetUnitY(pt.target) ---@type number 

            pt.dist = pt.dist - pt.speed
            pt.timer:callDelayed(FPS_32, thistype.grenadePeriodic, pt)

            if pt.dist > 0. then
                SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))
                SetUnitFlyHeight(pt.target, math.max(50 + pt.range * (1. - pt.dist / pt.range) * pt.dist / pt.range * 1.3, 1.), 0)
            else
                SetUnitTimeScalePercent(pt.target, 0)
                pt.timer:reset()
                pt.timer:callDelayed(2., thistype.grenadeExplosion, pt)
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            if UnitAlive(helicopter[self.pid]) then
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareCaster.mdl", self.x, self.y))
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Flare\\FlareTarget.mdl", self.targetX, self.targetY))
                pt.x = self.targetX
                pt.y = self.targetY
                pt.dur = 3.
                pt.dmg = self.dmg2 * heliboost[self.pid]

                pt.timer:callDelayed(0.7, thistype.rocketPeriodic, pt)
            else
                pt.target = GetDummy(self.x, self.y, 0, 0, 5.)
                pt.angle = self.angle
                pt.dist = DistanceCoords(self.x, self.y, self.targetX, self.targetY) + 25.
                pt.range = pt.dist
                pt.speed = 24.
                pt.aoe = 300. * LBOOST[self.pid]
                pt.dmg = self.dmg * BOOST[self.pid]
                BlzSetUnitSkin(pt.target, FourCC('h03J'))
                SetUnitScale(pt.target, 1.5, 1.5, 1.5)

                pt.timer:callDelayed(FPS_32, thistype.grenadePeriodic, pt)
            end
        end
    end

    ---@class U235SHELL : Spell
    ---@field dmg function
    U235SHELL = {}
    do
        local thistype = U235SHELL
        thistype.id = FourCC("A06V") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev + 2) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) + (GetHeroAgi(Hero[pid], true) * 5.) end ---@return number
        thistype.values = {thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local x = GetUnitX(Hero[pt.pid]) + 50 * Cos(pt.angle)
            local y = GetUnitY(Hero[pt.pid]) + 50 * Sin(pt.angle)

            pt.dur = pt.dur - 50.

            if pt.dur > 0. then
                if IsTerrainWalkable(x, y) then
                    SetUnitXBounded(Hero[pt.pid], x)
                    SetUnitYBounded(Hero[pt.pid], y)
                    pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
                else
                    pt:destroy()
                end
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local target = nil ---@type unit 
            local ug = CreateGroup()
            local hit = {}

            for i = 1, 10 do
                for i2 = 1, 3 do
                    self.x = GetUnitX(self.caster) + 175 * i * Cos((self.angle + (bj_DEGTORAD * (10 * i2 - 20))))
                    self.y = GetUnitY(self.caster) + 175 * i * Sin((self.angle + (bj_DEGTORAD * (10 * i2 - 20))))

                    DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", self.x, self.y))
                    MakeGroupInRange(self.pid, ug, self.x, self.y, 150. * LBOOST[self.pid], Condition(FilterEnemy))

                    target = FirstOfGroup(ug)
                    while target do
                        GroupRemoveUnit(ug, target)
                        if not hit[target] then
                            UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                            hit[target] = target
                        end
                        target = FirstOfGroup(ug)
                    end
                end
            end

            --movement
            local pt = TimerList[self.pid]:add()
            pt.dur = 250.
            pt.angle = self.angle - bj_PI
            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)

            DestroyGroup(ug)
        end
    end

    --thunderblade

    ---@class OVERLOAD : Spell
    ---@field mult function
    OVERLOAD = {}
    do
        local thistype = OVERLOAD
        thistype.id = FourCC("A096") ---@type integer 

        thistype.mult = function(pid) return 1. + (0.5 + 0.1 * R2I(GetHeroLevel(Hero[pid]) / 75.)) end ---@return number
        thistype.values = {thistype.mult}

        function thistype:onCast()
            OverloadBuff:add(self.caster, self.caster):duration(99999.)
        end
    end

    ---@class THUNDERDASH : Spell
    ---@field range function
    ---@field dmg function
    ---@field aoe number
    THUNDERDASH = {}
    do
        local thistype = THUNDERDASH
        thistype.id = FourCC("A095") ---@type integer 

        thistype.range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (ablev + 3) * 150. end ---@return number
        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 2. end ---@return number
        thistype.aoe = 260. ---@type number
        thistype.values = {thistype.range, thistype.dmg, thistype.aoe}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local x = GetUnitX(pt.source)
            local y = GetUnitY(pt.source)

            pt.dur = pt.dur - pt.speed

            if pt.dur > 0. and IsUnitInRangeXY(pt.source, pt.x, pt.y, pt.dur + 500.) then
                --movement
                SetUnitXBounded(pt.target, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.target, y + pt.speed * Sin(pt.angle))
                SetUnitXBounded(pt.source, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.source, y + pt.speed * Sin(pt.angle))

                BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)

                if pt.dur < (GetUnitAbilityLevel(pt.source, THUNDERDASH.id) + 3) * 150 - 200 then
                    local ug = CreateGroup()
                    MakeGroupInRange(pt.pid, ug, x, y, 100.00, Condition(FilterEnemy))
                    --check for impact
                    if BlzGroupGetSize(ug) > 0 or not IsTerrainWalkable(x + pt.speed * Cos(pt.angle), y + pt.speed * Sin(pt.angle)) then
                        SetUnitXBounded(pt.source, x)
                        SetUnitYBounded(pt.source, y)
                        pt.dur = 0.
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x, y))
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x + 140, y + 140))
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x + 140, y - 140))
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x - 140, y + 140))
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", x - 140, y - 140))
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x, y))
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x + 100, y + 100))
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x + 100, y - 100))
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x - 100, y + 100))
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x - 100, y - 100))
                        MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

                        local target = FirstOfGroup(ug)
                        while target do
                            GroupRemoveUnit(ug, target)
                            UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                            target = FirstOfGroup(ug)
                        end
                    end

                    DestroyGroup(ug)
                end

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
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

            TimerList[self.pid]:stopAllTimers(OMNISLASH.id)

            pt.angle = self.angle
            pt.source = self.caster
            pt.target = GetDummy(self.x, self.y, 0, 0, DUMMY_RECYCLE_TIME)
            pt.speed = 35.
            pt.x = self.x + pt.dur * Cos(pt.angle)
            pt.y = self.y + pt.dur * Sin(pt.angle)
            pt.dur = self.range * LBOOST[self.pid]
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.aoe = self.aoe * LBOOST[self.pid]

            SetUnitVertexColor(self.caster, 255, 255, 255, 255)
            SetUnitTimeScale(self.caster, 1.)
            ShowUnit(self.caster, false)
            UnitAddAbility(self.caster, FourCC('Avul'))
            BlzSetUnitSkin(pt.target, FourCC('h00B'))
            SetUnitScale(pt.target, 1.5, 1.5, 1.5)
            SetUnitFlyHeight(pt.target, 150.00, 0.00)
            DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\FarseerMissile\\FarseerMissile.mdl", self.x, self.y))

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class MONSOON : Spell
    ---@field times function
    ---@field aoe function
    ---@field dmg function
    MONSOON = {}
    do
        local thistype = MONSOON
        thistype.id = FourCC("A0MN") ---@type integer 

        thistype.times = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 1.5 end ---@return number
        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 275 + 25. * ablev end ---@return number
        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 1.4 + 15 * GetHeroLevel(Hero[pid]) * Pow(1.3, GetHeroLevel(Hero[pid]) * 0.01) end ---@return number
        thistype.values = {thistype.times, thistype.aoe, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 1

            if pt.dur >= 0 then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, thistype.aoe(pt.pid) * LBOOST[pt.pid], Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl", GetUnitX(target), GetUnitY(target)))
                    UnitDamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end

                pt.timer:callDelayed(1., thistype.periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.x = self.targetX
            pt.y = self.targetY
            pt.dur = self.times * LBOOST[self.pid]

            local sfx = AddSpecialEffect("war3mapImported\\AnimatedEnviromentalEffectRainBv005", self.targetX, self.targetY)
            BlzSetSpecialEffectScale(sfx, 0.4)
            TimerQueue:callDelayed(pt.dur, DestroyEffect, sfx)
            pt.timer:callDelayed(1., thistype.periodic, pt)
        end
    end

    ---@class BLADESTORM : Spell
    ---@field aoe number
    ---@field dot function
    ---@field chance number
    ---@field dmg function
    BLADESTORM = {}
    do
        local thistype = BLADESTORM
        thistype.id = FourCC("A03O") ---@type integer 

        thistype.aoe = 400. ---@type number
        thistype.dot = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid],true) * ablev * 0.2 end ---@return number
        thistype.chance = 15. ---@type number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid],true) * (ablev + 2.) end ---@return number
        thistype.values = {thistype.aoe, thistype.aoe, thistype.chance, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 1

            if UnitAlive(Hero[pt.pid]) and pt.dur >= 0 then
                local ug = CreateGroup()
                local target = nil

                MakeGroupInRange(pt.pid, ug, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), thistype.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

                if GetRandomInt(0, 99) < thistype.chance * LBOOST[pt.pid] and BlzGroupGetSize(ug) > 0 then
                    target = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))
                    DummyCastTarget(GetOwningPlayer(Hero[pt.pid]), target, FourCC('A09S'), 1, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), "forkedlightning")
                    UnitDamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                end

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "origin"))
                    UnitDamageTarget(Hero[pt.pid], target, thistype.dot(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.33, thistype.periodic, pt)
            else
                AddUnitAnimationProperties(Hero[pt.pid], "spin", false)
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()
            pt.dur = 9.

            AddUnitAnimationProperties(Hero[self.pid], "spin", true)
            pt.timer:callDelayed(0.33, thistype.periodic, pt)
        end
    end

    ---@class OMNISLASH : Spell
    ---@field times function
    ---@field dmg function
    OMNISLASH = {}
    do
        local thistype = OMNISLASH
        thistype.id = FourCC("A0os") ---@type integer 

        thistype.times = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 3.5 end ---@return number
        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 1.5 end ---@return number
        thistype.values = {thistype.times, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local x = GetUnitX(Hero[pt.pid])
            local y = GetUnitY(Hero[pt.pid])

            pt.dur = pt.dur - 1

            if pt.dur >= 0 then
                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, x, y, 600., Condition(FilterEnemy))

                local target = FirstOfGroup(ug)

                if target then
                    SetUnitAnimation(Hero[pt.pid], "Attack Slam")
                    SetUnitXBounded(Hero[pt.pid], GetUnitX(target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
                    SetUnitYBounded(Hero[pt.pid], GetUnitY(target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(target) - 180.)))
                    BlzSetUnitFacingEx(Hero[pt.pid], GetUnitFacing(target))
                    UnitDamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\BlinkHero[pt.pid].mdl", Hero[pt.pid], "chest"))
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "chest"))
                else
                    pt.dur = 0.
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.4, thistype.periodic, pt)
            else
                reselect(Hero[pt.pid])
                SetUnitVertexColor(Hero[pt.pid], 255, 255, 255, 255)
                SetUnitTimeScale(Hero[pt.pid], 1.)
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dur = self.times * LBOOST[self.pid] - 1
            pt.tag = OMNISLASH.id

            SetUnitTimeScale(self.caster, 2.5)
            SetUnitVertexColorBJ(self.caster, 100, 100, 100, 50.00)
            SetUnitXBounded(self.caster, GetUnitX(self.target) + 60. * Cos(bj_DEGTORAD * (GetUnitFacing(self.target) - 180.)))
            SetUnitYBounded(self.caster, GetUnitY(self.target) + 60. * Sin(bj_DEGTORAD * (GetUnitFacing(self.target) - 180.)))
            BlzSetUnitFacingEx(self.caster, GetUnitFacing(self.target))
            UnitDamageTarget(self.caster, self.target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Blink\\Blinkcaster.mdl", self.caster, "chest"))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", self.target, "chest"))

            pt.timer:callDelayed(0.4, thistype.periodic, pt)
        end
    end

    ---@class RAILGUN : Spell
    ---@field range number
    ---@field aoe number
    ---@field dmg function
    RAILGUN = {}
    do
        local thistype = RAILGUN
        thistype.id = FourCC("A01L") ---@type integer 

        thistype.range = 3000. ---@type number
        thistype.aoe = 800. ---@type number
        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 20. end ---@return number
        thistype.values = {thistype.range, thistype.aoe, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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
                until BlzGroupGetSize(ug) > 0 or dist >= thistype.range(pt.pid)

                --laser shot
                local dummy = GetDummy(x, y, 0, 0, DUMMY_RECYCLE_TIME)
                SetUnitOwner(dummy, Player(pt.pid - 1), false)
                SetUnitFlyHeight(dummy, 135., 0.)
                UnitRemoveAbility(dummy, FourCC('Avul'))
                UnitRemoveAbility(dummy, FourCC('Aloc'))
                local target = GetDummy(GetUnitX(pt.target), GetUnitY(pt.target), FourCC('A010'), 1, DUMMY_RECYCLE_TIME)
                SetUnitFlyHeight(target, 135., 0.)
                SetUnitOwner(target, Player(pt.pid - 1), false)
                BlzSetUnitFacingEx(target, bj_RADTODEG * pt.angle)
                UnitDisableAbility(target, FourCC('Amov'), true)
                InstantAttack(target, dummy)

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

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, u)
                    UnitDamageTarget(pt.source, u, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt:destroy()
            else
                SetUnitScale(pt.target, pt.time / 3., pt.time / 3., pt.time / 3.)
                BlzSetUnitFacingEx(pt.target, GetUnitFacing(pt.target) + 10 * pt.time)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.angle = self.angle
            pt.source = self.caster
            pt.target = GetDummy(self.x + 65. * Cos(pt.angle), self.y + 65. * Sin(pt.angle), 0, 0, DUMMY_RECYCLE_TIME)
            pt.dur = 4.

            BlzSetUnitSkin(pt.target, FourCC('h072'))
            SetUnitScale(pt.target, 0., 0., 0.)
            SoundHandler("war3mapImported\\railgun.mp3", true, nil, pt.target)

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    --master rogue

    ---@class INSTANTDEATH : Spell
    ---@field mult function
    ---@field chance number
    ---@field crit function
    INSTANTDEATH = {}
    do
        local thistype = INSTANTDEATH
        thistype.id = FourCC("A0QQ") ---@type integer 

        thistype.chance = 5.
        thistype.mult = function(pid) return 12 + R2I(GetHeroLevel(Hero[pid]) / 50.) * 3. end ---@return number
        thistype.crit = function(pid, unitangle, target) ---@return number
            local chance = thistype.chance

            if GetUnitAbilityLevel(Hero[pid], BACKSTAB.id) > 0 and RAbsBJ(unitangle - GetUnitFacing(target)) < 45 then
                chance = chance * 2.
            end

            if GetRandomInt(0, 99) < chance * LBOOST[pid] then
                return thistype.mult(pid)
            end

            return 0.
        end
        thistype.values = {thistype.chance, thistype.mult}
    end

    ---@class DEATHSTRIKE : Spell
    ---@field dmg function
    ---@field dur function
    DEATHSTRIKE = {}
    do
        local thistype = DEATHSTRIKE
        thistype.id = FourCC("A0QV") ---@type integer 
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid], true) * (0.5 + 0.5 * ablev) end ---@return number
        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.6 * ablev end ---@return number
        thistype.values = {thistype.dmg, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.expire(pt)
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
            UnitDamageTarget(self.caster, self.target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            TimerQueue:callDelayed(0., IssueTargetOrder, self.caster, "smart", self.target)

            local pt = TimerList[self.pid]:add()
            pt.target = self.target
            pt.timer:callDelayed(self.dur * LBOOST[self.pid], thistype.expire, pt)
        end
    end

    ---@class HIDDENGUISE : Spell
    HIDDENGUISE = {}
    do
        local thistype = HIDDENGUISE
        thistype.id = FourCC("A0F5") ---@type integer 

        ---@type fun(pt: PlayerTimer)
        function thistype.expire(pt)
            pt.time = pt.time + FPS_32

            if pt.time >= pt.dur then
                Item.create(UnitAddItemById(pt.source, FourCC('I0OW')))
                SetUnitVertexColor(pt.source, 255, 255, 255, 255)
                ToggleCommandCard(pt.source, true)
                UnitRemoveAbility(pt.source, FourCC('Avul'))
                Unit[pt.source].attack = true

                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            pt.dur = 2.
            pt.source = self.caster
            pt.tag = thistype.id

            local sfx = AddSpecialEffect("Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", self.x, self.y)
            BlzSetSpecialEffectYaw(sfx, GetUnitFacing(self.caster) * bj_DEGTORAD)
            TimerQueue:callDelayed(2., DestroyEffect, sfx)

            HiddenGuise[self.pid] = true
            UnitRemoveAbility(self.caster, FourCC('BOwk'))
            UnitAddAbility(self.caster, FourCC('Avul'))
            ToggleCommandCard(self.caster, false)
            SetUnitVertexColor(self.caster, 50, 50, 50, 50)
            Unit[self.caster].attack = false
            pt.timer:callDelayed(FPS_32, thistype.expire, pt)
        end
    end

    ---@class NERVEGAS : Spell
    ---@field aoe function
    ---@field dmg function
    ---@field dur number
    NERVEGAS = {}
    do
        local thistype = NERVEGAS
        thistype.id = FourCC("A0F7") ---@type integer 

        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 190 + 10. * ablev end ---@return number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgi(Hero[pid], true) * 3. * ablev end ---@return number
        thistype.dur = 10. ---@type number
        thistype.values = {thistype.aoe, thistype.dmg, thistype.dur}

        function thistype:onCast()
            local dummy = GetDummy(self.x, self.y, FourCC('A01X'), 1, 0)

            local target = GetDummy(self.targetX, self.targetY, 0, 0, 0)
            UnitRemoveAbility(target, FourCC('Avul'))
            UnitRemoveAbility(target, FourCC('Aloc'))

            SetUnitOwner(dummy, Player(self.pid - 1), true)
            IssueTargetOrder(dummy, "acidbomb", target)

            AddUnitAnimationProperties(self.caster, "alternate", false)
        end
    end

    ---@class BACKSTAB : Spell
    ---@field dmg function
    BACKSTAB = {}
    do
        local thistype = BACKSTAB
        thistype.id = FourCC("A0QP") ---@type integer 
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (GetHeroAgi(Hero[pid], true) * 0.16 + (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) * .03) * ablev end ---@return number
        thistype.values = {thistype.dmg}
    end

    --TODO wahhh
    ---@class PIERCINGSTRIKE : Spell
    PIERCINGSTRIKE = {}
    do
        local thistype = PIERCINGSTRIKE
        thistype.id = FourCC("A0QU") ---@type integer 
    end

    --oblivion guard

    ---@class BODYOFFIRE : Spell
    ---@field dmg function
    ---@field cooldown function
    BODYOFFIRE = {}
    do
        local thistype = BODYOFFIRE
        thistype.id = FourCC("A07R") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * (0.25 + 0.05 * ablev) end ---@return number
        thistype.values = {thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.cooldown(pt)
            local MAX_CHARGES = 5

            BodyOfFireCharges[pt.pid] = IMinBJ(MAX_CHARGES, BodyOfFireCharges[pt.pid] + 1)
            UnitDisableAbility(pt.source, INFERNALSTRIKE.id, false)
            UnitDisableAbility(pt.source, MAGNETICSTRIKE.id, false)

            if GetLocalPlayer() == Player(pt.pid - 1) then
                BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\PASBodyOfFire" .. BodyOfFireCharges[pt.pid] .. ".blp")
            end

            if BodyOfFireCharges[pt.pid] >= MAX_CHARGES then
                BlzStartUnitAbilityCooldown(pt.source, BODYOFFIRE.id, 0.)
                pt:destroy()
            else
                BlzStartUnitAbilityCooldown(pt.source, BODYOFFIRE.id, 5.)
                TimerQueue:callDelayed(5., thistype.cooldown, pt)
            end
        end
    end

    ---@class METEOR : Spell
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    METEOR = {}
    do
        local thistype = METEOR
        thistype.id = FourCC("A07O") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * ablev * 1. end ---@return number
        thistype.aoe = 300. ---@type number
        thistype.dur = 1. ---@type number
        thistype.values = {thistype.dmg, thistype.aoe, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.expire(pt)
            local ug = CreateGroup()

            DestroyTreesInRange(pt.x, pt.y, 250)
            reselect(Hero[pt.pid])
            BlzPauseUnitEx(Hero[pt.pid], false)

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, thistype.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

            local target = FirstOfGroup(ug)

            while target do
                GroupRemoveUnit(ug, target)
                Stun:add(Hero[pt.pid], target):duration(thistype.dur * LBOOST[pt.pid])
                UnitDamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
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

            pt.timer:callDelayed(0.9, thistype.expire, pt)
        end
    end

    ---@class MAGNETICSTANCE : Spell
    MAGNETICSTANCE = {}
    do
        local thistype = MAGNETICSTANCE
        thistype.id = FourCC("A076") ---@type integer 

        function thistype:onCast()
            MagneticStanceBuff:add(self.caster, self.caster):duration(99999.)
        end
    end

    ---@class INFERNALSTRIKE : Spell
    ---@field dmg function
    ---@field aoe number
    INFERNALSTRIKE = {}
    do
        local thistype = INFERNALSTRIKE
        thistype.id = FourCC("A05S") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroStr(Hero[pid], true) * ablev * 1. end ---@return number
        thistype.aoe = 250. ---@type number
        thistype.values = {thistype.dmg, thistype.aoe}

        function thistype:onCast()
            MagneticStrikeBuff:dispel(self.caster, self.caster)
            InfernalStrikeBuff:add(self.caster, self.caster):duration(99999.)
        end
    end

    ---@class MAGNETICSTRIKE : Spell
    ---@field aoe number
    MAGNETICSTRIKE = {}
    do
        local thistype = MAGNETICSTRIKE
        thistype.id = FourCC("A047") ---@type integer 

        thistype.aoe = 250. ---@type number
        thistype.values = {thistype.aoe}

        function thistype:onCast()
            InfernalStrikeBuff:dispel(self.caster, self.caster)
            MagneticStrikeBuff:add(self.caster, self.caster):duration(99999.)
        end
    end

    ---@class GATEKEEPERSPACT : Spell
    ---@field dmg function
    ---@field aoe function
    GATEKEEPERSPACT = {}
    do
        local thistype = GATEKEEPERSPACT
        thistype.id = FourCC("A0GJ") ---@type integer 

        thistype.dmg = function(pid) return GetHeroStr(Hero[pid], true) * 15. end ---@return number
        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 550. + 50. * ablev end ---@return number
        thistype.values = {thistype.dmg, thistype.aoe}

        ---@type fun(pt: PlayerTimer)
        function thistype.expire(pt)
            local ug = CreateGroup()
            local sfx = AddSpecialEffect("war3mapImported\\AnnihilationBlast.mdx", GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]))

            BlzSetSpecialEffectColor(sfx, 25, 255, 0)
            DestroyEffect(sfx)

            SetUnitAnimationByIndex(Hero[pt.pid], 2)
            BlzPauseUnitEx(Hero[pt.pid], false)
            MakeGroupInRange(pt.pid, ug, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), thistype.aoe(pt.pid) * LBOOST[pt.pid], Condition(FilterEnemy))

            local target = FirstOfGroup(ug)

            while target do
                GroupRemoveUnit(ug, target)
                StunUnit(pt.pid, target, 5.)
                UnitDamageTarget(Hero[pt.pid], target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            pt:destroy()

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()

            BlzPauseUnitEx(self.caster, true)
            TimerQueue:callDelayed(2, DestroyEffect, AddSpecialEffect("war3mapImported\\AnnihilationTarget.mdx", self.x, self.y))
            pt.timer:callDelayed(2, thistype.expire, pt)
        end
    end

    --phoenix ranger

    ---@class REINCARNATION : Spell
    REINCARNATION = {}
    do
        local thistype = REINCARNATION
        thistype.id = FourCC("A05T") ---@type integer 
    end

    ---@class PHOENIXFLIGHT : Spell
    ---@field range function
    ---@field aoe number
    ---@field dmg function
    PHOENIXFLIGHT = {}
    do
        local thistype = PHOENIXFLIGHT
        thistype.id = FourCC("A0FT") ---@type integer 

        thistype.range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 350. + ablev * 150. end ---@return number
        thistype.aoe = 250. ---@type number
        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 1.5 end ---@return number
        thistype.values = {thistype.range, thistype.aoe, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    if IsUnitInGroup(target, pt.ug) == false then
                        GroupAddUnit(pt.ug, target)
                        DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\PhoenixMissile\\Phoenix_Missile.mdl", GetUnitX(target), GetUnitY(target)))
                        UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        if GetUnitAbilityLevel(target, FourCC('B02O')) > 0 then
                            UnitRemoveAbility(target, FourCC('B02O'))
                            SEARINGARROWS.ignite(pt.source, target)
                        end
                    end
                    target = FirstOfGroup(ug)
                end

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                UnitRemoveAbility(pt.source, FourCC('Avul'))
                ShowUnit(pt.source, true)
                reselect(pt.source)
                SetUnitPathing(pt.source, true)
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end

            DestroyGroup(ug)
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
            pt.target = GetDummy(self.x, self.y, 0, 0, DUMMY_RECYCLE_TIME)
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

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class FIERYARROWS : Spell
    FIERYARROWS = {}
    do
        local thistype = FIERYARROWS
        thistype.id = FourCC("A0IB") ---@type integer 
        thistype.chance = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2 * ablev end
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroAgility(Hero[pid], true) * ablev + BlzGetUnitBaseDamage(Hero[pid], 0) + GetUnitBonus(Hero[pid], BONUS_DAMAGE) end
        thistype.values = {thistype.chance, thistype.dmg}
    end

    ---@class SEARINGARROWS : Spell
    ---@field ignite function
    ---@field burn function
    ---@field dmg function
    ---@field dot function
    SEARINGARROWS = {}
    do
        local thistype = SEARINGARROWS
        thistype.id = FourCC("A090") ---@type integer 

        thistype.aoe = 750. ---@type number
        thistype.dmg = function(pid) return UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0) end ---@return number
        thistype.dot = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.05 + ablev * 0.05) * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) end ---@return number
        thistype.values = {thistype.aoe, thistype.dmg, thistype.dot}

        ---@type fun(pt: PlayerTimer)
        function thistype.burn(pt)
            pt.dur = pt.dur - 1

            if pt.dur >= 0 then
                UnitDamageTarget(pt.source, pt.target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                pt.timer:callDelayed(1., thistype.burn, pt)
            else
                pt:destroy()
            end
        end

        ---@type fun(source: unit, target: unit)
        function thistype.ignite(source, target)
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local pt = TimerList[pid]:add()

            TimerQueue:callDelayed(5., DestroyEffect, AddSpecialEffectTarget("war3mapImported\\FireNormal1.mdl", target, "chest"))

            pt.dmg = thistype.dot(pid) * BOOST[pid]
            pt.dur = 5.
            pt.source = source
            pt.target = target

            pt.timer:callDelayed(1., thistype.burn, pt)
        end

        function thistype:onCast()
            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)

                local dummy = GetDummy(self.x, self.y, FourCC('A069'), 1, 2.5)
                SetUnitOwner(dummy, Player(self.pid - 1), true)
                BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(self.y - GetUnitY(target), self.x - GetUnitX(target)))
                UnitDisableAbility(dummy, FourCC('Amov'), true)
                InstantAttack(dummy, target)
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        end
    end

    ---@class FLAMINGBOW : Spell
    ---@field pierce function
    ---@field bonus function
    ---@field total function
    ---@field dur number
    FLAMINGBOW = {}
    do
        local thistype = FLAMINGBOW
        thistype.id = FourCC("A0F6") ---@type integer 

        thistype.pierce = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 10. + 1. * ablev end ---@return number
        thistype.bonus = function(pid) return 0.5 * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.total = function(pid)
            local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id)
            local b = FlamingBowBuff:get(Hero[pid], Hero[pid])
            local adjust = 0
            if b then adjust = b.attack end
            return (0.8 + 0.02 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) - adjust end ---@return number
        thistype.dur = 15. ---@type number
        thistype.values = {thistype.pierce, thistype.bonus, thistype.total, thistype.dur}

        function thistype:onCast()
            FlamingBowBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    --bloodzerker

    ---@class BLOODFRENZY : Spell
    BLOODFRENZY = {}
    do
        local thistype = BLOODFRENZY
        thistype.id = FourCC("A05Y") ---@type integer 

        function thistype:onCast()
            BloodFrenzyBuff:add(self.caster, self.caster):duration(5.)
        end
    end

    ---@class BLOODLEAP : Spell
    ---@field dmg function
    ---@field aoe number
    BLOODLEAP = {}
    do
        local thistype = BLOODLEAP
        thistype.id = FourCC("A05Z") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.4 + 0.4 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.aoe = 300. ---@type number
        thistype.values = {thistype.dmg, thistype.aoe}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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

                    local target = FirstOfGroup(ug)
                    while target do
                        GroupRemoveUnit(ug, target)
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Devour\\DevourEffectArt.mdl", target, "chest"))
                        UnitDamageTarget(pt.target, target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        target = FirstOfGroup(ug)
                    end

                    DestroyGroup(ug)
                end

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
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

            UnitDamageTarget(self.caster, self.caster, 0.1 * BlzGetUnitMaxHP(self.caster), true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)

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

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class BLOODCURDLINGSCREAM : Spell
    ---@field aoe number
    ---@field dur function
    BLOODCURDLINGSCREAM = {}
    do
        local thistype = BLOODCURDLINGSCREAM
        thistype.id = FourCC("A06H") ---@type integer 

        thistype.aoe = 500. ---@type number
        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 6 end
        thistype.values = {thistype.aoe, thistype.dur}

        function thistype:onCast()
            local ug = CreateGroup()

            UnitDamageTarget(self.caster, self.caster, 0.1 * BlzGetUnitMaxHP(self.caster), true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
            MakeGroupInRange(self.pid, ug, self.x, self.y, thistype.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                BloodCurdlingScreamDebuff:add(self.caster, target):duration(self.dur * LBOOST[self.pid])
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        end
    end

    ---@class BLOODCLEAVE : Spell
    ---@field chance number
    ---@field aoe function
    ---@field dmg function
    BLOODCLEAVE = {}
    do
        local thistype = BLOODCLEAVE
        thistype.id = FourCC("A05X") ---@type integer 

        thistype.chance = 20. ---@type number
        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 195. + 5. * ablev end ---@return number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.45 + 0.05 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.values = {thistype.chance, thistype.aoe, thistype.dmg}
    end

    ---@class RAMPAGE : Spell
    RAMPAGE = {}
    do
        local thistype = RAMPAGE
        thistype.id = FourCC("A0GZ") ---@type integer 

        function thistype:onCast()
            RampageBuff:add(self.caster, self.caster):duration(99999.)
        end
    end

    ---@class UNDYINGRAGE : Spell
    ---@field regen function
    ---@field attack function
    ---@field dur number
    UNDYINGRAGE = {}
    do
        local thistype = UNDYINGRAGE
        thistype.id = FourCC("A0AD") ---@type integer 

        thistype.regen = function(pid) return GetHeroStr(Hero[pid], true) * (GetWidgetLife(Hero[pid]) / BlzGetUnitMaxHP(Hero[pid])) end
        thistype.attack = function(pid)
            local base = BlzGetUnitBaseDamage(Hero[pid], 0)
            local bonus = UnitGetBonus(Hero[pid], BONUS_DAMAGE)
            return (base + bonus - undyingRageAttackBonus[pid]) * (GetWidgetLife(Hero[pid]) / BlzGetUnitMaxHP(Hero[pid])) end
        thistype.dur = 10. ---@type number
        thistype.values = {thistype.regen, thistype.attack, thistype.dur}

        function thistype:onCast()
            UndyingRageBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    --warrior

    ---@class PARRY : Spell
    ---@field dmg function
    PARRY = {}
    do
        local thistype = PARRY
        thistype.id = FourCC("A0AI") ---@type integer 

        thistype.dmg = function(pid) return 1. * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.values = {thistype.dmg}
    end

    ---@class SPINDASH : Spell
    SPINDASH = {}
    do
        local thistype = SPINDASH
        thistype.id = FourCC("A0EE") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.7 + 0.2 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.values = {thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.recastExpire(pt)
            BlzStartUnitAbilityCooldown(pt.source, thistype.id, 3.)
            BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(pt.source, thistype.id), ABILITY_ILF_TARGET_TYPE, GetUnitAbilityLevel(pt.source, thistype.id) - 1, 2)

            pt:destroy()
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - pt.speed

            if pt.dur > 0. and IsUnitInRangeXY(pt.source, pt.x, pt.y, pt.dur + 50.) then
                local x = GetUnitX(pt.source)
                local y = GetUnitY(pt.source)
                SetUnitXBounded(pt.source, x + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.source, y + pt.speed * Sin(pt.angle))

                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, x, y, 225. * LBOOST[pt.pid], Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)

                    if not IsUnitInGroup(target, pt.ug) then
                        GroupAddUnit(pt.ug, target)
                        if limitBreak[pt.pid] & 0x2 > 0 then
                            UnitDamageTarget(pt.source, target, thistype.dmg(pt.pid) * 4. * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                            SpinDashDebuff:add(pt.source, target):duration(2.)
                        else
                            UnitDamageTarget(pt.source, target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        end
                    end
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                SetUnitPropWindow(pt.source, bj_DEGTORAD * 60.)
                SetUnitTimeScale(pt.source, 1.)
                AddUnitAnimationProperties(pt.source, "spin", false)
                SetUnitPathing(pt.source, true)
                IssueImmediateOrder(pt.source, "stop")
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

            pt = TimerList[self.pid]:get('spinRecast', self.caster)

            --recast
            if pt then
                self.targetX = pt.x
                self.targetY = pt.y
                self.angle = Atan2(pt.y - self.y, pt.x - self.x)
                SetUnitPropWindow(pt.source, bj_DEGTORAD * 60.)
                SetUnitTimeScale(pt.source, 1.)
                AddUnitAnimationProperties(pt.source, "spin", false)
                SetUnitPathing(pt.source, true)
                IssueImmediateOrder(pt.source, "stop")

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
                pt.tag = 'spinRecast'

                BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(pt.source, thistype.id), ABILITY_ILF_TARGET_TYPE, GetUnitAbilityLevel(pt.source, thistype.id) - 1, 0)

                pt.timer:callDelayed(3., thistype.recastExpire, pt)
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

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class INTIMIDATINGSHOUT : Spell
    ---@field aoe number
    ---@field dur number
    INTIMIDATINGSHOUT = {}
    do
        local thistype = INTIMIDATINGSHOUT
        thistype.id = FourCC("A00L") ---@type integer 

        thistype.aoe = 500. ---@type number
        thistype.dur = 3. ---@type number
        thistype.values = {thistype.aoe, thistype.dur}

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

            if limitBreak[self.pid] & 0x4 > 0 then
                bj_lastCreatedEffect = AddSpecialEffectTarget("war3mapImported\\BattleCryCaster.mdx", self.caster, "origin")
                BlzSetSpecialEffectColor(bj_lastCreatedEffect, 255, 255, 0)
            else
                bj_lastCreatedEffect = AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", self.caster, "origin")
            end

            DestroyEffect(bj_lastCreatedEffect)

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                IntimidatingShoutDebuff:add(self.caster, target):duration(self.dur * LBOOST[self.pid])
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        end
    end

    ---@class WINDSCAR : Spell
    ---@field dmg function
    WINDSCAR = {}
    do
        local thistype = WINDSCAR
        thistype.id = FourCC("A001") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.7 + 0.1 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.values = {thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local x = GetUnitX(pt.target) ---@type number 
            local y = GetUnitY(pt.target) ---@type number 

            pt.dur = pt.dur + 0.05

            if (pt.dur > 1. and not pt.limitbreak) or (pt.dur > 5. and pt.limitbreak) then
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            else
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)

                    if not IsUnitInGroup(target, pt.ug) then
                        GroupAddUnit(pt.ug, target)
                        TimerQueue:callDelayed(1., GroupRemoveUnit, pt.ug, target)
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end
                    target = FirstOfGroup(ug)
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

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            end
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.delay(pt)
            local angle      = 0. ---@type number 
            local pt2  

            if limitBreak[pt.pid] & 0x8 > 0 then
                for i = 0, 3 do
                    pt2 = TimerList[pt.pid]:add()
                    pt2.ug = CreateGroup()
                    pt2.aoe = 120.
                    pt2.angle = 2. * bj_PI / 3. * i
                    pt2.source = pt.source
                    pt2.target = GetDummy(GetUnitX(pt.source) + 150. * Cos(pt2.angle), GetUnitY(pt.source) + 150. * Sin(pt2.angle), 0, 0, DUMMY_RECYCLE_TIME)
                    pt2.dmg = thistype.dmg(pt.pid)
                    pt2.limitbreak = true

                    BlzSetUnitSkin(pt2.target, FourCC('h044'))
                    SetUnitScale(pt2.target, 0.6, 0.6, 0.6)
                    UnitAddAbility(pt2.target, FourCC('Amrf'))
                    SetUnitFlyHeight(pt2.target, 30.00, 0.00)
                    BlzSetUnitFacingEx(pt2.target, bj_RADTODEG * (pt2.angle + bj_PI * 0.5))
                    SetUnitVertexColor(pt2.target, 255, 255, 0, 255)

                    pt2.timer:callDelayed(FPS_32, thistype.periodic, pt2)
                end
            else
                SoundHandler("Abilities\\Spells\\Orc\\Shockwave\\Shockwave.flac", true, nil, pt.source)

                angle = pt.angle

                for i = -1, 1 do
                    pt2 = TimerList[pt.pid]:add()
                    pt2.ug = CreateGroup()
                    pt2.aoe = 150.
                    pt2.angle = angle + i / 4. * bj_PI
                    pt2.target = GetDummy(GetUnitX(pt.source) + 100. * Cos(pt2.angle), GetUnitY(pt.source) + 100. * Sin(pt2.angle), 0, 0, DUMMY_RECYCLE_TIME)
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

                    pt2.timer:callDelayed(FPS_32, thistype.periodic, pt2)
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

                pt.timer:callDelayed(0., thistype.delay, pt)
                SetUnitAnimation(self.caster, "stand")
            else
                SetUnitAnimation(self.caster, "attack slam")
                SetUnitTimeScale(self.caster, 1.5)
                pt.angle = self.angle
                pt.timer:callDelayed(0.4, thistype.delay, pt)
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
    ADAPTIVESTRIKE = {}
    do
        local thistype = ADAPTIVESTRIKE
        thistype.id = FourCC("A0AH") ---@type integer 

        thistype.spindmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (1. + 0.2 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.spinaoe = 400.
        thistype.spinheal = function(pid) return 10. * TotalRegen[pid] end

        thistype.knockaoe = 300. ---@return number
        thistype.knockdur = 1.5 ---@return number
        thistype.shoutaoe = 900. ---@return number
        thistype.shoutdur = 4. ---@return number

        thistype.tornadodmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.35 + 0.05 * ablev) * (BlzGetUnitBaseDamage(Hero[pid], 0) + UnitGetBonus(Hero[pid], BONUS_DAMAGE)) end ---@return number
        thistype.tornadodur = 3. ---@return number

        thistype.values = {thistype.spindmg, thistype.spinaoe, thistype.spinheal, thistype.knockaoe, thistype.knockdur, thistype.shoutaoe, thistype.shoutdur, thistype.tornadodmg, thistype.tornadodur}

        ---@type fun(pt: PlayerTimer)
        function thistype.tornado(pt)
            pt.time = pt.time + 0.5

            if pt.time >= pt.dur then
                IssueImmediateOrder(pt.target, "stop")
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            else
                local x = GetUnitX(pt.target)
                local y = GetUnitY(pt.target)

                IssuePointOrder(pt.target, "move", x + 75. * Cos(pt.angle), y + 75. * Sin(pt.angle))

                if ModuloReal(pt.time + 0.5, 1.) == 0. then
                    local ug = CreateGroup()
                    MakeGroupInRange(pt.pid, ug, x, y, 200., Condition(FilterEnemy))

                    local target = FirstOfGroup(ug)
                    while target do
                        GroupRemoveUnit(ug, target)
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        target = FirstOfGroup(ug)
                    end

                    DestroyGroup(ug)
                end

                pt.timer:callDelayed(0.5, thistype.tornado, pt)
            end
        end

        ---@type fun(caster: unit, x: number, y: number)
        function thistype.effect(caster, x, y)
            local pid = GetPlayerId(GetOwningPlayer(caster)) + 1
            local pt
            local ug = CreateGroup()
            local target

            if lastCast[pid] == PARRY.id then --spin heal
                SetUnitAnimation(caster, "spell")
                MakeGroupInRange(pid, ug, x, y, thistype.spinaoe * LBOOST[pid], Condition(FilterEnemy))

                target = GetDummy(x, y, 0, 0, 1.)
                BlzSetUnitSkin(target, FourCC('h074'))
                SetUnitTimeScale(target, 1.)
                SetUnitScale(target, 1.25, 1.25, 1.25)
                SetUnitAnimationByIndex(target, 0)
                SetUnitFlyHeight(target, 100., 0)
                BlzSetUnitFacingEx(target, GetUnitFacing(caster))

                target = GetDummy(x, y, 0, 0, 1.)
                BlzSetUnitSkin(target, FourCC('h074'))
                SetUnitTimeScale(target, 1.)
                SetUnitScale(target, 1.25, 1.25, 1.25)
                SetUnitAnimationByIndex(target, 0)
                SetUnitFlyHeight(target, 100., 0)
                BlzSetUnitFacingEx(target, GetUnitFacing(caster) + 180.)

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    UnitDamageTarget(caster, target, thistype.spindmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end

                HP(caster, thistype.spinheal(pid) * BOOST[pid])
            elseif lastCast[pid] == SPINDASH.id then --knock up
                SetUnitAnimationByIndex(caster, 4)
                DelayAnimation(pid, caster, 0.6, 0, 1., false)
                MakeGroupInRange(pid, ug, x, y, thistype.knockaoe * LBOOST[pid], Condition(FilterEnemy))

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    KnockUp:add(caster, target):duration(thistype.knockdur * LBOOST[pid])
                    target = FirstOfGroup(ug)
                end

                local sfx = AddSpecialEffect("war3mapImported\\DustWindFaster3.mdx", x - 110., y)
                BlzSetSpecialEffectPitch(sfx, bj_PI * 0.5)

                SoundHandler("Abilities\\Spells\\NightElf\\Cyclone\\CycloneBirth1.flac", true, nil, caster)

                DestroyEffect(sfx)
            elseif lastCast[pid] == INTIMIDATINGSHOUT.id then --ally attack damage buff
                MakeGroupInRange(pid, ug, x, y, thistype.shoutaoe * LBOOST[pid], Condition(FilterAlly))

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    IntimidatingShoutBuff:add(caster, target):duration(thistype.shoutdur * LBOOST[pid])
                    target = FirstOfGroup(ug)
                end

                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\BattleCryCaster.mdx", caster, "origin"))
            elseif lastCast[pid] == WINDSCAR.id then --5 tornadoes
                for i = 0, 4 do
                    pt = TimerList[pid]:add()
                    pt.angle = bj_PI * 0.4 * i
                    pt.target = GetDummy(x + 75. * Cos(pt.angle), y + 75 * Sin(pt.angle), 0, 0, DUMMY_RECYCLE_TIME)
                    pt.dmg = thistype.tornadodmg(pid)
                    pt.dur = thistype.tornadodur * LBOOST[pid]

                    SetUnitPathing(pt.target, false)
                    BlzSetUnitSkin(pt.target, FourCC('n001'))
                    SetUnitMoveSpeed(pt.target, 100.)
                    SetUnitScale(pt.target, 0.5, 0.5, 0.5)
                    UnitAddAbility(pt.target, FourCC('Amrf'))
                    IssuePointOrder(pt.target, "move", x + 225. * Cos(pt.angle), y + 225. * Sin(pt.angle))

                    pt.timer:callDelayed(0.5, thistype.tornado, pt)
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
    end

    ---@class LIMITBREAK : Spell
    LIMITBREAK = {}
    do
        local thistype = LIMITBREAK
        thistype.id = FourCC("A02R") ---@type integer 

        function thistype:onCast()
            if GetLocalPlayer() == Player(self.pid - 1) then
                if BlzFrameIsVisible(LimitBreakBackdrop) then
                    BlzFrameSetVisible(LimitBreakBackdrop, false)
                else
                    BlzFrameSetVisible(LimitBreakBackdrop, true)
                end
            end
        end
    end

    --hydromancer

    ---@class FROSTBLAST : Spell
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    FROSTBLAST = {}
    do
        local thistype = FROSTBLAST
        thistype.id = FourCC("A0GI") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 1. * ablev * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.aoe = 250. ---@type number
        thistype.dur = 4. ---@type number
        thistype.values = {thistype.dmg, thistype.aoe, thistype.dur}

        function thistype:onCast()
            local dummy = GetDummy(self.x, self.y, FourCC('A04B'), 1, DUMMY_RECYCLE_TIME) ---@type unit 
            SetUnitOwner(dummy, Player(self.pid - 1), true)
            IssueTargetOrder(dummy, "thunderbolt", self.target)
        end
    end

    ---@class WHIRLPOOL : Spell
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    WHIRLPOOL = {}
    do
        local thistype = WHIRLPOOL
        thistype.id = FourCC("A03X") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.25 * ablev * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.aoe = 330. ---@type number
        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2. + 2. * ablev end ---@return number
        thistype.values = {thistype.dmg, thistype.aoe, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.count = pt.count + 1
            pt.dur = pt.dur - FPS_32

            if pt.dur > 0. then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe * LBOOST[pt.pid], Condition(FilterEnemy))

                pt.dur = pt.dur - 0.0015 * IMinBJ(BlzGroupGetSize(ug), 20)

                local target = FirstOfGroup(ug)
                local angle
                while target do
                    GroupRemoveUnit(ug, target)
                    --movement effects
                    angle = Atan2(pt.y - GetUnitY(target), pt.x - GetUnitX(target))

                    if IsUnitType(target, UNIT_TYPE_HERO) == false and GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Cos(angle), GetUnitY(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Sin(angle)) then
                        SetUnitPathing(target, false)
                        SetUnitXBounded(target, GetUnitX(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Cos(angle))
                        SetUnitYBounded(target, GetUnitY(target) + (17. + 30. / (DistanceCoords(pt.x, GetUnitX(target), pt.y, GetUnitY(target)) + 1)) * Sin(angle))
                    end
                    SetUnitPathing(target, true)

                    if ModuloInteger(pt.count, 32) == 0 then
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end

                    SoakedDebuff:add(Hero[pt.pid], target):duration(5.)
                    target = FirstOfGroup(ug)
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

            if GetUnitAbilityLevel(self.caster, FourCC('B01I')) > 0 then
                UnitRemoveAbility(self.caster, FourCC('B01I'))
                pt.dur = pt.dur + 3
            end

            pt.source = GetDummy(pt.x, pt.y, 0, 0, pt.dur + 1.)
            BlzSetUnitSkin(pt.source, FourCC('h01I'))
            SetUnitTimeScale(pt.source, 1.3)
            SetUnitScale(pt.source, 0.6, 0.6, 0.6)
            SetUnitAnimation(pt.source, "birth")
            SetUnitFlyHeight(pt.source, 50., 0)
            PauseUnit(pt.source, true)
            pt.target = GetDummy(pt.x, pt.y, 0, 0, pt.dur + 1.)
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
    TIDALWAVE = {}
    do
        local thistype = TIDALWAVE
        thistype.id = FourCC("A077") ---@type integer 

        thistype.range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 500. + 100. * ablev end ---@return number
        thistype.values = {thistype.range}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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

                local target = FirstOfGroup(ug)
                local x = 0.
                local y = 0.
                while target do
                    GroupRemoveUnit(ug, target)

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
                        local debuff = TidalWaveDebuff:add(Hero[pt.pid], target)

                        if IsUnitType(target, UNIT_TYPE_HERO) == true then
                            debuff:duration(5.)
                        else
                            debuff:duration(10.)
                        end

                        if pt.infused then
                            debuff.percent = .20
                        end
                    end

                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
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
            pt.target = GetDummy(self.x, self.y, 0, 0, DUMMY_RECYCLE_TIME)
            pt.x = self.x
            pt.y = self.y
            pt.infused = false

            if GetUnitAbilityLevel(Hero[self.pid], FourCC('B01I')) > 0 then
                pt.infused = true
                UnitRemoveAbility(Hero[self.pid], FourCC('B01I'))
            end

            BlzSetUnitSkin(pt.target, FourCC('h04X'))
            SetUnitAnimation(pt.target, "birth")
            SetUnitScale(pt.target, 0.8, 0.8, 0.8)
            BlzSetUnitFacingEx(pt.target, pt.angle * bj_RADTODEG)

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class BLIZZARD : Spell
    ---@field aoe function
    ---@field dmg function
    BLIZZARD = {}
    do
        local thistype = BLIZZARD
        thistype.id = FourCC("A08E") ---@type integer 

        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 175. + 25. * ablev end ---@return number
        thistype.dmg = function(pid) return 0.25 * ablev * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.values = {thistype.aoe, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 1

            if pt.dur < 1 then
                pt:destroy()
            elseif pt.dur < 3 then
                IssueImmediateOrder(pt.source, "stop")
                pt.timer:callDelayed(1., thistype.periodic, pt)
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()  

            pt.dur = (self.ablev + 3) * LBOOST[self.pid]
            pt.source = GetDummy(self.x, self.y, FourCC('A02O'), 1, pt.dur + 3.)
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dmg = self.dmg
            pt.tag = thistype.id
            pt.infused = false

            BlzSetAbilityRealLevelField(BlzGetUnitAbility(pt.source, FourCC('A02O')), ABILITY_RLF_AREA_OF_EFFECT, 0, pt.aoe)
            IncUnitAbilityLevel(pt.source, FourCC('A02O'))
            DecUnitAbilityLevel(pt.source, FourCC('A02O'))
            SetUnitOwner(pt.source, Player(self.pid - 1), true)

            if UnitRemoveAbility(self.caster, FourCC('B01I')) then
                pt.infused = true
                UnitRemoveAbility(Hero[self.pid], FourCC('B01I'))
            end

            IssuePointOrder(pt.source, "blizzard", self.targetX, self.targetY)

            pt.timer:callDelayed(1., thistype.periodic, pt)
        end
    end

    ---@class ICEBARRAGE : Spell
    ---@field times function
    ---@field dmg function
    ICEBARRAGE = {}
    do
        local thistype = ICEBARRAGE
        thistype.id = FourCC("A098") ---@type integer 

        thistype.times = function(pid) local ablev = GetUnitAbilitylevel(Hero[pid], thistype.id) return 12. + 4. * ablev end ---@return number
        thistype.dmg = function(pid) return GetHeroInt(Hero[pid], true) * 0.5 end ---@return number
        thistype.values = {thistype.times, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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
            else
                SetUnitXBounded(pt.source, GetUnitX(pt.target))
                SetUnitYBounded(pt.source, GetUnitY(pt.target))
                SetUnitAnimation(pt.source, "death")
                if pt.infused then
                    Stun:add(Hero[pid], pt.target):duration(0.25)
                end

                if SoakedDebuff:has(nil, pt.target) then
                    UnitDamageTarget(Hero[pid], pt.target, pt.dmg * 2. * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                else
                    UnitDamageTarget(Hero[pid], pt.target, pt.dmg * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
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
                pt2.source = GetDummy(x + 100. * Cos(angle), y + 100. * Sin(angle), 0, 0, DUMMY_RECYCLE_TIME)
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
                pt2.timer:callDelayed(FPS_32, thistype.periodic, pt2)
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

            if GetUnitAbilityLevel(Hero[self.pid], FourCC('B01I')) > 0 then
                pt.infused = true
                UnitRemoveAbility(Hero[self.pid], FourCC('B01I'))
            end

            pt.timer:callDelayed(0.05, thistype.onSpawn, pt)
        end
    end

    --vampire

    ---@class BLOODBANK : Spell
    ---@field gain function
    ---@field max function
    ---@field curr function
    BLOODBANK = {}
    do
        local thistype = BLOODBANK
        thistype.id = FourCC("A07K") ---@type integer 

        thistype.gain = function(pid) return 0.75 * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.max = function(pid) return 200. * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.curr = function(pid) return BloodBank[pid] end ---@return number
        thistype.values = {thistype.gain, thistype.max, thistype.curr}
    end

    ---@class BLOODLEECH : Spell
    ---@field gain function
    ---@field dmg function
    BLOODLEECH = {}
    do
        local thistype = BLOODLEECH
        thistype.id = FourCC("A07A") ---@type integer 

        thistype.gain = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (2.75 + 0.25 * ablev) * (GetHeroAgi(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end ---@return number
        thistype.dmg = function(pid) return 10. * GetHeroAgi(Hero[pid], true) + 5. * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.values = {thistype.gain, thistype.dmg}

        function thistype:onCast()
            UnitDamageTarget(self.caster, self.target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            BloodBank[self.pid] = math.min(BloodBank[self.pid] + self.gain, BLOODBANK.max(self.pid))
        end
    end

    ---@class BLOODDOMAIN : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field gain function
    BLOODDOMAIN = {}
    do
        local thistype = BLOODDOMAIN
        thistype.id = FourCC("A09B") ---@type integer 

        thistype.aoe = 400. ---@type number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.5 + 0.5 * ablev) * GetHeroAgi(Hero[pid], true) + (1.5 + 0.5 * ablev) * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.gain = function(pid) return 1. * GetHeroAgi(Hero[pid], true) + 1. * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.values = {thistype.aoe, thistype.dmg, thistype.gain}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local ablev = GetUnitAbilityLevel(pt.source, BLOODDOMAIN.id) ---@type integer 

            pt.dur = pt.dur - 1

            if pt.dur > 0. then
                local ug = CreateGroup()
                local ug2 = CreateGroup()
                MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), pt.aoe, Condition(FilterEnemyDead))
                MakeGroupInRange(pt.pid, ug2, GetUnitX(pt.source), GetUnitY(pt.source), pt.aoe, Condition(FilterEnemy))

                pt.dmg = math.max(thistype.dmg(pt.pid) * 0.2, thistype.dmg(pt.pid) * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug2) - 1)))
                pt.armor = math.max(thistype.gain(pt.pid) * 0.2, thistype.gain(pt.pid) * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug) - 1)))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    BloodBank[pt.pid] = math.min(BloodBank[pt.pid] + pt.armor, BLOODBANK.max(pt.pid))

                    if UnitAlive(target) then
                        UnitDamageTarget(pt.source, target, pt.dmg * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end

                    local dummy = GetDummy(GetUnitX(target), GetUnitY(target), FourCC('A09D'), 1, DUMMY_RECYCLE_TIME)
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(pt.source) - GetUnitY(dummy),  GetUnitX(pt.source) - GetUnitX(dummy)))
                    InstantAttack(dummy, pt.source)
                    target = FirstOfGroup(ug)
                end

                pt.timer:callDelayed(1., thistype.periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
            DestroyGroup(ug2)
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

            MakeGroupInRange(self.pid, ug, x, y, pt.aoe, Condition(FilterEnemyDead))
            MakeGroupInRange(self.pid, ug2, x, y, pt.aoe, Condition(FilterEnemy))

            pt.dur = 5.
            pt.dmg = math.max(thistype.dmg(self.pid) * 0.2, thistype.dmg(self.pid) * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug2) - 1)))
            pt.armor = math.max(thistype.gain(self.pid) * 0.2, thistype.gain(self.pid) * (1 - (0.17 - 0.02 * ablev) * (BlzGroupGetSize(ug) - 1)))
            pt.source = self.caster

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)

                BloodBank[self.pid] = math.min(BloodBank[self.pid] + pt.armor, BLOODBANK.max(self.pid))

                if UnitAlive(target) then
                    UnitDamageTarget(self.caster, target, pt.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    if GetHeroStr(self.caster, true) > GetHeroAgi(self.caster, true) and GetUnitAbilityLevel(self.caster, BLOODLORD.id) > 0 then
                        --TODO blood domain taunt?
                    end
                end

                local dummy = GetDummy(GetUnitX(target), GetUnitY(target), FourCC('A09D'), 1, DUMMY_RECYCLE_TIME)
                BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(self.caster) - GetUnitY(dummy), GetUnitX(self.caster) - GetUnitX(dummy)))
                InstantAttack(dummy, self.caster)
                target = FirstOfGroup(ug)
            end

            pt.timer:callDelayed(1., thistype.periodic, pt)

            DestroyGroup(ug)
            DestroyGroup(ug2)
        end
    end

    ---@class BLOODMIST : Spell
    ---@field cost function
    ---@field heal function
    BLOODMIST = {}
    do
        local thistype = BLOODMIST
        thistype.id = FourCC("A093") ---@type integer 

        thistype.cost = function(pid) return 16. * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.25 + 0.25 * ablev) * GetHeroStr(Hero[pid], true) + thistype.cost(pid) * 0.15 end ---@return number
        thistype.values = {thistype.cost, thistype.heal}
    end

    ---@class BLOODNOVA : Spell
    ---@field cost number
    ---@field dmg number
    ---@field aoe number
    BLOODNOVA = {}
    do
        local thistype = BLOODNOVA
        thistype.id = FourCC("A09A") ---@type integer 

        thistype.cost = function(pid) return 40. * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.dmg = function(pid) return 3. * GetHeroAgi(Hero[pid], true) + 2. * GetHeroStr(Hero[pid], true) + thistype.cost(pid) * 0.3 end ---@return number
        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 225. + 25. * ablev end ---@return number
        thistype.values = {thistype.cost, thistype.dmg, thistype.aoe}

        function thistype:onCast()
            if BloodBank[self.pid] >= self.cost then
                BloodBank[self.pid] = BloodBank[self.pid] - self.cost
                SetUnitState(self.caster, UNIT_STATE_MANA, BloodBank[self.pid])

                local ug = CreateGroup()

                MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
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
    BLOODLORD = {}
    do
        local thistype = BLOODLORD
        thistype.id = FourCC("A097") ---@type integer 

        thistype.bonus = function(pid) return BloodBank[pid] * 0.01 end ---@return number
        thistype.dmg = function(pid) return 0.75 * GetHeroAgi(Hero[pid], true) + 1. * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 9. + ablev end ---@return number
        thistype.values = {thistype.bonus, thistype.dmg, thistype.dur}

        function thistype:onCast()
            BloodLordBuff:add(self.caster, self.caster):duration(self.dur)
        end
    end

    --high priestess

    ---@class INVIGORATION : Spell
    INVIGORATION = {}
    do
        local thistype = INVIGORATION
        thistype.id = FourCC("A0DU") ---@type integer 

        thistype.aoe = 850. ---@type number
        thistype.heal = function(pid) return 0.15 * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.mana = function(pid) return 0.02 * BlzGetUnitMaxMana(Hero[pid]) end ---@return number
        thistype.values = {thistype.aoe, thistype.heal, thistype.mana}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local heal = thistype.heal(pt.pid) ---@type number 
            local mana = thistype.mana(pt.pid) ---@type number 
            local ug = CreateGroup()
            local ftarget = nil ---@type unit 
            local percent = 100. ---@type number 

            pt.dur = pt.dur + 1

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterAllyHero))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                if percent > GetUnitLifePercent(target) then
                    percent = GetUnitLifePercent(target)
                    ftarget = target
                end
                target = FirstOfGroup(ug)
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
                    HP(ftarget, heal)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", ftarget, "origin"))
                end

                pt.timer:callDelayed(0.5, thistype.periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[pid]:add()  

            pt.x = self.x
            pt.y = self.y
            pt.aoe = self.aoe * LBOOST[self.pid]

            pt.timer:callDelayed(0.5, thistype.periodic, pt)
        end
    end

    ---@class DIVINELIGHT : Spell
    ---@field heal function
    DIVINELIGHT = {}
    do
        local thistype = DIVINELIGHT
        thistype.id = FourCC("A0JE") ---@type integer 

        thistype.heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.25 + 0.25 * ablev) * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.values = {thistype.heal}

        function thistype:onCast()
            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            --because backpack is a valid target
            if GetUnitTypeId(self.target) == BACKPACK then
                self.target = Hero[self.pid]
            end

            HP(self.target, (self.heal + BlzGetUnitMaxHP(self.target) * 0.05) * BOOST[self.pid])
            DivineLightBuff:add(self.caster, self.target):duration(3.)
        end
    end

    ---@class SANCTIFIEDGROUND : Spell
    ---@field ms number
    ---@field regen number
    ---@field aoe number
    ---@field dur function
    SANCTIFIEDGROUND = {}
    do
        local thistype = SANCTIFIEDGROUND
        thistype.id = FourCC("A0JG") ---@type integer 

        thistype.ms = 20. ---@type number
        thistype.regen = 100. ---@type number
        thistype.aoe = 400. ---@type number
        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 11. + ablev end ---@return number
        thistype.values = {thistype.ms, thistype.regen, thistype.aoe, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 1

            if pt.dur > 0. then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    SanctifiedGroundDebuff:add(Hero[pt.pid], target):duration(1.)
                    target = FirstOfGroup(ug)
                end

                if pt.dur == 2 then
                    Fade(pt.target, 1., true)
                end

                pt.timer:callDelayed(0.5, thistype.periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            local pt = TimerList[self.pid]:add()
            pt.x = self.targetX
            pt.y = self.targetY
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dur = self.dur * 2. * LBOOST[self.pid]
            pt.target = GetDummy(pt.x, pt.y, 0, 0, pt.dur * 0.5)

            UnitDisableAbility(pt.target, FourCC('Amov'), true)
            BlzSetUnitSkin(pt.target, FourCC('h04D'))
            SetUnitScale(pt.target, LBOOST[self.pid], LBOOST[self.pid], LBOOST[self.pid])
            SetUnitAnimation(pt.target, "birth")
            BlzSetUnitFacingEx(pt.target, 270.)

            pt.timer:callDelayed(0.5, thistype.periodic, pt)
        end
    end

    ---@class HOLYRAYS : Spell
    ---@field aoe number
    ---@field heal function
    ---@field dmg function
    HOLYRAYS = {}
    do
        local thistype = HOLYRAYS
        thistype.id = FourCC("A0JD") ---@type integer 

        thistype.aoe = 600. ---@type number
        thistype.heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.5 * ablev * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2. * ablev * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.values = {thistype.aoe, thistype.heal, thistype.dmg}

        function thistype:onCast()
            local ug = CreateGroup()

            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(isalive))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                if IsUnitAlly(target, Player(self.pid - 1)) then
                    local dummy = GetDummy(self.x, self.y, FourCC('A09Q'), 1, DUMMY_RECYCLE_TIME)
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(dummy), GetUnitX(target) - GetUnitX(dummy)))
                    InstantAttack(dummy, target)
                    HP(target, self.heal * BOOST[self.pid])
                else
                    local dummy = GetDummy(self.x, self.y, FourCC('A014'), 1, DUMMY_RECYCLE_TIME)
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(dummy), GetUnitX(target) - GetUnitX(dummy)))
                    InstantAttack(dummy, target)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\AncestralGuardianMissile\\AncestralGuardianMissile.mdl", target, "chest"))
                    UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                end
                target = FirstOfGroup(ug)
            end
        end
    end

    ---@class PROTECTION : Spell
    ---@field shield function
    ---@field aoe number
    PROTECTION = {}
    do
        local thistype = PROTECTION
        thistype.id = FourCC("A0J3") ---@type integer 

        thistype.shield = function(pid) return 3. * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.aoe = 650. ---@type number
        thistype.values = {thistype.shield, thistype.aoe}

        function thistype:onCast()
            local ug = CreateGroup()

            DestroyEffect(AddSpecialEffectTarget("war3mapImported\\RighteousGuard.mdx", self.caster, "chest"))
            BlzStartUnitAbilityCooldown(self.caster, RESURRECTION.id, math.max(0.01, BlzGetUnitAbilityCooldownRemaining(self.caster, RESURRECTION.id) - 2.))

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterAllyHero))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                ProtectionBuff:add(self.caster, target):duration(99999.)
                shield.add(target, self.shield * BOOST[self.pid], 20 + 10 * self.ablev):color(4)
                target = FirstOfGroup(ug)
            end
        end
    end

    ---@class RESURRECTION : Spell
    ---@field restore number
    RESURRECTION = {}
    do
        local thistype = RESURRECTION
        thistype.id = FourCC("A048") ---@type integer 

        thistype.restore = function(pid) return 40. + 20.* GetUnitAbilityLevel(Hero[pid], thistype.id) end ---@return number
        thistype.values = {thistype.restore}

        function thistype:onCast()
            local size = 0. ---@type number 

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", self.targetX, self.targetY))
            ResurrectionRevival[self.tpid] = self.pid
            UnitAddAbility(HeroGrave[self.tpid], FourCC('A045'))

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
    SOULLINK = {}
    do
        local thistype = SOULLINK
        thistype.id = FourCC("A06A") ---@type integer 

        thistype.dur = 5. ---@type number
        thistype.values = {thistype.dur}

        function thistype:onCast()
            SoulLinkBuff:add(self.caster, self.target):duration(thistype.dur * LBOOST[self.pid])
        end
    end

    ---@class LAWOFRESONANCE : Spell
    ---@field echo function
    ---@field dur number
    LAWOFRESONANCE = {}
    do
        local thistype = LAWOFRESONANCE
        thistype.id = FourCC("A0KD") ---@type integer 

        thistype.echo = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 20. + 5. * ablev end ---@return number
        thistype.dur = 5. ---@type number
        thistype.values = {thistype.echo, thistype.dur}

        function thistype:onCast()
            LawOfResonanceBuff:add(self.caster, self.target):duration(thistype.dur * LBOOST[self.pid])
        end
    end

    ---@class LAWOFVALOR : Spell
    ---@field regen function
    ---@field amp function
    ---@field dur number
    LAWOFVALOR = {}
    do
        local thistype = LAWOFVALOR
        thistype.id = FourCC("A06D") ---@type integer 

        thistype.regen = function(pid) return (0.08 + 0.02 * ablev) * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.amp = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 8. + 2. * ablev end ---@return number
        thistype.dur = 15. ---@type number
        thistype.values = {thistype.regen, thistype.amp, thistype.dur}

        function thistype:onCast()
            LawOfValorBuff:add(self.caster, self.target):duration(thistype.dur * LBOOST[self.pid])
        end
    end

    ---@class LAWOFMIGHT : Spell
    ---@field pbonus function
    ---@field fbonus function
    ---@field dur number
    LAWOFMIGHT = {}
    do
        local thistype = LAWOFMIGHT
        thistype.id = FourCC("A07D") ---@type integer 

        thistype.pbonus = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 10. + 5. * ablev end ---@return number
        thistype.fbonus = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.04 + 0.01 * ablev) * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.dur = 15. ---@type number
        thistype.values = {thistype.pbonus, thistype.fbonus, thistype.dur}

        function thistype:onCast()
            LawOfMightBuff:add(self.caster, self.target):duration(thistype.dur * LBOOST[self.pid])
        end
    end

    ---@class AURAOFJUSTICE : Spell
    ---@field pshield function
    ---@field dur number
    AURAOFJUSTICE = {}
    do
        local thistype = AURAOFJUSTICE
        thistype.id = FourCC("A06E") ---@type integer 

        thistype.pshield = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 20. + 5. * ablev end ---@return number
        thistype.dur = 5. ---@type number
        thistype.values = {thistype.pshield, thistype.dur}

        function thistype:onCast()
            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.x, self.y, 900., Condition(FilterAlly))
            DestroyEffect(AddSpecialEffect("war3mapImported\\BlessedField.mdx", self.x, self.y))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                shield.add(target, BlzGetUnitMaxHP(target) * self.pshield * 0.01 * LBOOST[self.pid], self.dur * LBOOST[pid])
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        end
    end

    ---@class DIVINERADIANCE : Spell
    ---@field heal function
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    DIVINERADIANCE = {}
    do
        local thistype = DIVINERADIANCE
        thistype.id = FourCC("A07P") ---@type integer 

        thistype.heal = function(pid) return 2. * GetHeroStr(Hero[pid], true) end ---@return number
        thistype.dmg = function(pid) return 2. * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.aoe = 750. ---@type number
        thistype.dur = 10. ---@type number
        thistype.values = {thistype.heal, thistype.dmg, thistype.aoe, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 1

            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), thistype.aoe * LBOOST[pt.pid], Condition(FilterAlive))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                if IsUnitEnemy(target, Player(pt.pid - 1)) then
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                    UnitDamageTarget(pt.source, target, thistype.dmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                elseif GetUnitTypeId(target) ~= BACKPACK and IsUnitAlly(target, Player(pt.pid - 1)) and GetUnitAbilityLevel(target, FourCC('Aloc')) == 0 then
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", GetUnitX(target), GetUnitY(target)))
                    HP(target, thistype.heal(pt.pid) * BOOST[pt.pid])
                end
                target = FirstOfGroup(ug)
            end

            if pt.dur - 1 <= 0 then
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()  

            pt.dur = self..dur * LBOOST[self.pid]
            pt.source = self.caster

            TimerQueue:callDelayed(pt.dur * 2., DestroyEffect, AddSpecialEffectTarget("war3mapImported\\HolyAurora.MDX", self.caster, "origin"))

            pt.timer:callDelayed(2., thistype.periodic, pt)
        end
    end

    --elementalist

    ---@class ELEMENTFIRE : Spell
    ---@field value integer
    ELEMENTFIRE = {}
    do
        local thistype = ELEMENTFIRE
        thistype.id = FourCC("A0J8") ---@type integer 
        thistype.value = 1 ---@type integer 

        function thistype:onCast()
            masterElement[self.pid] = thistype.value
            TimerList[self.pid]:stopAllTimers(ELEMENTLIGHTNING.id)
            UnitRemoveAbility(self.caster, FourCC('B01W'))
            UnitRemoveAbility(self.caster, FourCC('B01V'))
            UnitRemoveAbility(self.caster, FourCC('B01Z'))
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JZ'), true)
            UnitAddAbility(self.caster, FourCC('B01Y'))
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JX'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JV'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JY'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JW'), false)
            DestroyEffect(lightningeffect[self.pid])
            DestroyEffect(lightningeffect[self.pid * 8])
            lightningeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", self.caster, "right hand")
            lightningeffect[self.pid * 8] = AddSpecialEffectTarget("war3mapImported\\Fire Uber.mdx", self.caster, "left hand")
        end
    end

    ---@class ELEMENTICE : Spell
    ---@field value integer
    ELEMENTICE = {}
    do
        local thistype = ELEMENTICE
        thistype.id = FourCC("A0J6") ---@type integer 
        thistype.value = 2 ---@type integer 

        function thistype:onCast()
            masterElement[self.pid] = thistype.value
            TimerList[self.pid]:stopAllTimers(ELEMENTLIGHTNING.id)
            UnitRemoveAbility(self.caster, FourCC('B01Y'))
            UnitRemoveAbility(self.caster, FourCC('B01V'))
            UnitRemoveAbility(self.caster, FourCC('B01Z'))
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JZ'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JV'), true)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JY'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JW'), false)
            DestroyEffect(lightningeffect[self.pid])
            DestroyEffect(lightningeffect[self.pid * 8])
            lightningeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", self.caster, "right hand")
            lightningeffect[self.pid * 8] = AddSpecialEffectTarget("war3mapImported\\Water High.mdx", self.caster, "left hand")
        end
    end

    ---@class ELEMENTLIGHTNING : Spell
    ---@field value integer
    ELEMENTLIGHTNING = {}
    do
        local thistype = ELEMENTLIGHTNING
        thistype.id = FourCC("A0J9") ---@type integer 
        thistype.value = 3 ---@type integer 

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            if UnitAlive(Hero[pt.pid]) then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), 900., Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                if target then
                    local dummy = GetDummy(GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid]), FourCC('A09W'), 1, 1.)
                    SetUnitOwner(dummy, Player(pt.pid - 1), false)
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(dummy), GetUnitX(target) - GetUnitX(dummy)))
                    InstantAttack(dummy, target)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(5., thistype.periodic, pt)
            end
        end

        function thistype:onCast()
            masterElement[self.pid] = thistype.value
            UnitRemoveAbility(self.caster, FourCC('B01Y'))
            UnitRemoveAbility(self.caster, FourCC('B01W'))
            UnitRemoveAbility(self.caster, FourCC('B01V'))
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JZ'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JX'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JV'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JY'), true)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JW'), false)
            DestroyEffect(lightningeffect[self.pid])
            DestroyEffect(lightningeffect[self.pid * 8])
            lightningeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", self.caster, "right hand")
            lightningeffect[self.pid * 8] = AddSpecialEffectTarget("war3mapImported\\Storm Cast.mdx", self.caster, "left hand")

            if TimerList[self.pid]:has(thistype.id) == false then
                local pt = TimerList[self.pid]:add()
                pt.tag = thistype.id
                pt.timer:callDelayed(5., thistype.periodic, pt)
            end
        end
    end

    ---@class ELEMENTEARTH : Spell
    ---@field value integer
    ELEMENTEARTH = {}
    do
        local thistype = ELEMENTEARTH
        thistype.id = FourCC("A0JA") ---@type integer 
        thistype.value = 4 ---@type integer 

        function thistype:onCast()
            masterElement[self.pid] = thistype.value
            UnitRemoveAbility(self.caster, FourCC('B01Y'))
            UnitRemoveAbility(self.caster, FourCC('B01W'))
            UnitRemoveAbility(self.caster, FourCC('B01Z'))
            TimerList[self.pid]:stopAllTimers(ELEMENTLIGHTNING.id)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JZ'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JX'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JV'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JY'), false)
            SetPlayerAbilityAvailable(Player(self.pid - 1), FourCC('A0JW'), true)
            DestroyEffect(lightningeffect[self.pid])
            DestroyEffect(lightningeffect[self.pid * 8])
            lightningeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", self.caster, "right hand")
            lightningeffect[self.pid * 8] = AddSpecialEffectTarget("war3mapImported\\Earth High.mdx", self.caster, "left hand")
        end
    end

    ---@class BALLOFLIGHTNING : Spell
    ---@field range function
    ---@field dmg function
    BALLOFLIGHTNING = {}
    do
        local thistype = BALLOFLIGHTNING
        thistype.id = FourCC("A0GV") ---@type integer 

        thistype.range = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 650. + 200. * ablev end ---@return number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (5. + ablev) * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.values = {thistype.range, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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
                    UnitDamageTarget(Hero[pt.pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

                    pt.dur = 0.
                end

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()  

            pt.angle = self.angle
            pt.target = GetDummy(self.x + 25. * Cos(pt.angle), self.y + 25. * Sin(pt.angle), 0, 0, 5.)
            pt.aoe = 150.
            pt.dur = self.range
            pt.speed = 25. + 2. * self.ablev
            pt.dmg = self.dmg * BOOST[self.pid]

            BlzSetUnitSkin(pt.target, FourCC('h070'))
            SetUnitFlyHeight(pt.target, 50., 0)
            SetUnitScale(pt.target, 1. + .2 * self.ablev, 1. + .2 * self.ablev, 1. + .2 * self.ablev)

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
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
    FROZENORB = {}
    do
        local thistype = FROZENORB
        thistype.id = FourCC("A011") ---@type integer 
        thistype.id2 = FourCC("A01W") ---@type integer 

        thistype.iceaoe = 750.
        thistype.icedmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * ablev) end ---@return number
        thistype.orbrange = 1000.
        thistype.orbdmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * 3. * ablev end ---@return number
        thistype.orbaoe = 400.
        thistype.freeze = 3.
        thistype.values = {thistype.iceaoe, thistype.icedmg, thistype.orbrange, thistype.orbdmg, thistype.orbaoe, thistype.freeze}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local x = GetUnitX(pt.target) ---@type number 
            local y = GetUnitY(pt.target) ---@type number 

            pt.agi = pt.agi + 1
            pt.dur = pt.dur - 6.

            if pt.dur > 0. then
                --orb movement
                SetUnitXBounded(pt.target, x + 6 * Cos(pt.angle))
                SetUnitYBounded(pt.target, y + 6 * Sin(pt.angle))

                --icicle every second
                if ModuloInteger(pt.agi,32) == 0 then
                    local ug = CreateGroup()
                    local angle = 0. ---@type number 

                    MakeGroupInRange(pt.pid, ug, x, y, thistype.iceaoe(pt.pid) * LBOOST[pt.pid], Condition(FilterEnemy))

                    local target = FirstOfGroup(ug)
                    while target do
                        GroupRemoveUnit(ug, target)
                        angle = Atan2(GetUnitY(target) - y, GetUnitX(target) - x)
                        bj_lastCreatedUnit = GetDummy(x + 50. * Cos(angle), y + 50 * Sin(angle), FourCC('A09F'), 1, 3.)
                        SetUnitOwner(bj_lastCreatedUnit, Player(pt.pid - 1), false)
                        BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(pt.target), GetUnitX(target) - GetUnitX(pt.target)))
                        SetUnitScale(bj_lastCreatedUnit, 0.35, 0.35, 0.35)
                        SetUnitFlyHeight(bj_lastCreatedUnit, GetUnitFlyHeight(pt.target), 0)
                        InstantAttack(bj_lastCreatedUnit, target)
                        target = FirstOfGroup(ug)
                    end

                    DestroyGroup(ug)
                end

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                --show original cast
                UnitRemoveAbility(pt.source, FROZENORB.id2)
                BlzUnitHideAbility(pt.source, FROZENORB.id, false)

                --orb shatter
                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, x, y, thistype.orbaoe(pt.pid) * LBOOST[pt.pid], Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    Freeze:add(pt.source, target):duration(thistype.freeze(pt.pid))
                    UnitDamageTarget(pt.source, target, thistype.orbdmg(pt.pid) * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                DestroyEffect(AddSpecialEffect("war3mapImported\\FrostNova.mdx", x, y))

                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end

        end

        function thistype:onCast()
            local pt  

            if self.sid == thistype.id2 then
                pt = TimerList[self.pid]:get(thistype.id, self.caster)

                if pt then
                    pt.dur = 0.
                end
            else
                pt = TimerList[self.pid]:add()
                pt.angle = self.angle
                pt.dur = self.orbrange
                pt.tag = thistype.id
                pt.agi = 16

                pt.source = self.caster
                pt.target = GetDummy(self.x + 75 * Cos(pt.angle), self.y + 75 * Sin(pt.angle), 0, 0, 8.)
                BlzSetUnitSkin(pt.target, FourCC('h06Z'))
                SetUnitScale(pt.target, 1.3, 1.3, 1.3)
                SetUnitFlyHeight(pt.target, 70.00, 0.00)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)

                --show second cast
                BlzUnitHideAbility(self.caster, FROZENORB.id, true)
                UnitAddAbility(self.caster, FROZENORB.id2)
                SetUnitAbilityLevel(self.caster, FROZENORB.id2, self.ablev)
            end
        end
    end

    ---@class GAIAARMOR : Spell
    ---@field shield function
    GAIAARMOR = {}
    do
        local thistype = GAIAARMOR
        thistype.id = FourCC("A032") ---@type integer 

        thistype.shield = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * ablev) end ---@return number
        thistype.values = {thistype.shield}

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
    end

    ---@class FLAMEBREATH : Spell
    ---@field aoe number
    ---@field dmg function
    FLAMEBREATH = {}
    do
        local thistype = FLAMEBREATH
        thistype.id = FourCC("A01U") ---@type integer 

        thistype.aoe = 750. ---@type number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (0.5 + 0.5 * ablev) end ---@return number
        thistype.values = {thistype.aoe, thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)

                    x = GetUnitX(target)
                    y = GetUnitY(target)

                    AB = (y - By) * (Ax - Bx) - (x - Bx) * (Ay - By)
                    BC = (y - Cy) * (Bx - Cx) - (x - Cx) * (By - Cy)
                    CD = (y - Dy) * (Cx - Dx) - (x - Dx) * (Cy - Dy)
                    DA = (y - Ay) * (Dx - Ax) - (x - Ax) * (Dy - Ay)

                    if (AB >= 0 and BC >= 0 and CD >= 0 and DA >= 0) or (AB <= 0 and BC <= 0 and CD <= 0 and DA <= 0) then
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end

                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.5, thistype.periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            TimerList[self.pid]:stopAllTimers(thistype.id)

            local pt = TimerList[self.pid]:add()  
            pt.angle = self.angle
            pt.sfx = AddSpecialEffect("war3mapImported\\FlameBreath.mdx", self.x + 75 * Cos(pt.angle), self.y + 75 * Sin(pt.angle))
            pt.tag = thistype.id
            pt.aoe = self.aoe
            pt.dmg = self.dmg
            BlzSetSpecialEffectScale(pt.sfx, 1.8 * LBOOST[self.pid])
            BlzSetSpecialEffectTimeScale(pt.sfx, 1.5)
            BlzSetSpecialEffectYaw(pt.sfx, pt.angle)

            pt.timer:callDelayed(0.5, thistype.periodic, pt)
        end
    end

    ---@class ELEMENTALSTORM : Spell
    ---@field times number
    ---@field dmg function
    ---@field aoe number
    ELEMENTALSTORM = {}
    do
        local thistype = ELEMENTALSTORM
        thistype.id = FourCC("A04H") ---@type integer 

        thistype.times = 12. ---@type number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (1.5 + 0.5 * ablev) end ---@return number
        thistype.aoe = 400. ---@type number
        thistype.values = {thistype.times, thistype.dmg, thistype.aoe}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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
                    UnitDamageTarget(Hero[pt.pid], target, GetWidgetLife(target) * 0.015, true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
                    DestroyEffect(AddSpecialEffectTarget("Abilities\\Weapons\\Bolt\\BoltImpact.mdl", target, "origin"))
                elseif rand == ELEMENTEARTH.value then
                    TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffect("war3mapImported\\Earth NovaTarget.mdx", x2, y2))
                end

                --unique effects
                while target do
                    GroupRemoveUnit(ug, target)
                    if rand == ELEMENTFIRE.value then --fire
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg * 1.5, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    else
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        if rand == ELEMENTICE.value then --ice
                            Freeze:add(Hero[pt.pid], target):duration(2.)
                        elseif rand == ELEMENTEARTH.value then --earth
                            if EarthDebuff:has(nil, target) then
                                IncUnitAbilityLevel(target, FourCC('A04P'))
                            end
                            EarthDebuff:add(Hero[pt.pid], target):duration(10.)
                        end
                    end
                    target = FirstOfGroup(ug)
                end

                pt.timer:callDelayed(0.4, thistype.periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
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

            pt.timer:callDelayed(0.4, thistype.periodic, pt)
        end
    end

    --dark summoner

    ---@class SUMMONINGIMPROVEMENT : Spell
    ---@field apply function
    SUMMONINGIMPROVEMENT = {}
    do
        local thistype = SUMMONINGIMPROVEMENT
        thistype.id = FourCC("A022") ---@type integer 

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
            improvementArmorBonus[pid] = 0

            if ablev > 0 then
                SetUnitMoveSpeed(summon, GetUnitDefaultMoveSpeed(summon) + ablev * 10.)

                --armor bonus
                improvementArmorBonus[pid] = improvementArmorBonus[pid] + R2I((Pow(ablev, 1.2) + (Pow(ablev, 4.) - Pow(ablev, 3.9)) / 90.) / 2. + ablev + 6.5)

                --status bar buff
                UnitAddAbility(summon, FourCC('A06Q'))
                SetUnitAbilityLevel(summon, FourCC('A06Q'), ablev)
            end

            if uid == SUMMON_GOLEM then --golem
                if GetUnitAbilityLevel(Hero[pid], DEVOUR.id) > 0 then --golem devour ability
                    UnitAddAbility(summon, FourCC('A06C'))
                    SetUnitAbilityLevel(summon, FourCC('A06C'), GetUnitAbilityLevel(Hero[pid], DEVOUR.id))
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

            UnitSetBonus(summon, BONUS_ARMOR, improvementArmorBonus[pid])
        end

        function thistype:onCast()
            RecallSummons(self.pid)
        end
    end

    ---@class SUMMONDEMONHOUND : Spell
    ---@field hounds function
    ---@field str function
    ---@field agi function
    ---@field int function
    SUMMONDEMONHOUND = {}
    do
        local thistype = SUMMONDEMONHOUND
        thistype.id = FourCC("A0KF") ---@type integer 

        thistype.hounds = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 2 + ablev end ---@return integer
        thistype.str = function(pid) return 0.2 * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end ---@return number
        thistype.agi = function(pid) return 0.075 * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.int = function(pid) return 0.25 * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.values = {thistype.hounds, thistype.str, thistype.agi, thistype.int}

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

                if destroyerSacrificeFlag[self.pid] then
                    SetUnitVertexColor(hounds[offset + i], 90, 90, 230, 255)
                    SetUnitScale(hounds[offset + i], 1.15, 1.15, 1.15)
                    SetUnitAbilityLevel(hounds[offset + i], FourCC('A06F'), 2)
                end

                SummonGroup[#SummonGroup + 1] = hounds[offset + i]

                SetHeroXP(hounds[offset + i], R2I(RequiredXP(GetHeroLevel(Hero[self.pid]) - 1) + ((GetHeroLevel(Hero[self.pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

                pt.timer:callPeriodically(0.5, SummonDurationXPBar, pt)
            end
        end
    end

    ---@class SUMMONMEATGOLEM : Spell
    ---@field str function
    ---@field int function
    SUMMONMEATGOLEM = {}
    do
        local thistype = SUMMONMEATGOLEM
        thistype.id = FourCC("A0KH") ---@type integer 

        thistype.str = function(pid) return 0.4 * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end ---@return number
        thistype.int = function(pid) return 0.6 * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.values = {thistype.str, thistype.int}

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
                UnitRemoveAbility(meatgolem[self.pid], FourCC('A071')) --borrowed life
                UnitRemoveAbility(meatgolem[self.pid], FourCC('A0B0')) --thunder clap
                UnitRemoveAbility(meatgolem[self.pid], FourCC('A06O')) --magnetic force
                UnitRemoveAbility(meatgolem[self.pid], FourCC('A06C')) --devour
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

            golemDevourStacks[self.pid] = 0
            BorrowedLife[self.pid * 10] = 0

            BlzSetHeroProperName(meatgolem[self.pid], "Meat Golem")
            TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", meatgolem[self.pid], "origin"))
            SUMMONINGIMPROVEMENT.apply(self.pid, meatgolem[self.pid], R2I(self.str * BOOST[self.pid]), 0, R2I(self.int * BOOST[self.pid]))
            SummonGroup[#SummonGroup + 1] = meatgolem[self.pid]
            SetHeroXP(meatgolem[self.pid], R2I(RequiredXP(GetHeroLevel(Hero[self.pid]) - 1) + ((GetHeroLevel(Hero[self.pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

            pt.timer:callPeriodically(0.5, SummonDurationXPBar, pt)
        end
    end

    ---@class SUMMONDESTROYER : Spell
    ---@field periodic function
    ---@field str function
    ---@field agi function
    ---@field int function
    SUMMONDESTROYER = {}
    do
        local thistype = SUMMONDESTROYER
        thistype.id = FourCC("A0KG") ---@type integer 

        thistype.str = function(pid) return 0.0666 * (GetHeroInt(Hero[pid], true) + GetHeroStr(Hero[pid], true)) end ---@return number
        thistype.agi = function(pid) return 0.005 * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.int = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.5 * GetHeroInt(Hero[pid], true) * ablev end ---@return number
        thistype.values = {thistype.str, thistype.agi, thistype.int}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local base = 0 ---@type integer 

            if destroyerDevourStacks[pt.pid] == 5 then
                base = 400
            elseif destroyerDevourStacks[pt.pid] >= 3 then
                base = 200
            end

            SetHeroAgi(destroyer[pt.pid], IMinBJ(GetHeroAgi(destroyer[pt.pid], false) + 50, 400), true)

            if pt.x == GetUnitX(destroyer[pt.pid]) and pt.y == GetUnitY(destroyer[pt.pid]) then
                TimerQueue:callDelayed(FPS_32, thistype.periodic, pt)
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
                UnitRemoveAbility(destroyer[self.pid], FourCC('A071')) --borrowed life
                UnitRemoveAbility(destroyer[self.pid], FourCC('A04Z')) --devour
                UnitSetBonus(destroyer[self.pid], BONUS_ARMOR, 0)
                UnitSetBonus(destroyer[self.pid], BONUS_HERO_STR, 0)
                UnitSetBonus(destroyer[self.pid], BONUS_HERO_AGI, 0)
                UnitSetBonus(destroyer[self.pid], BONUS_HERO_INT, 0)
                SetHeroAgi(destroyer[self.pid], 0, true)
            end

            pt = TimerList[self.pid]:add()
            pt.x = x
            pt.y = y
            pt.dur = 180.
            pt.time = 180.
            pt.tag = destroyer[self.pid]
            pt.target = destroyer[self.pid]

            BorrowedLife[self.pid * 10 + 1] = 0
            destroyerDevourStacks[self.pid] = 0
            destroyerSacrificeFlag[self.pid] = false

            BlzSetHeroProperName(destroyer[self.pid], "Destroyer")
            TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", destroyer[self.pid], "origin"))
            SUMMONINGIMPROVEMENT.apply(self.pid, destroyer[self.pid], R2I(self.str * BOOST[self.pid]), R2I(self.agi * BOOST[self.pid]), R2I(self.int * BOOST[self.pid]))

            --revert hounds to normal
            for i = 1, #SummonGroup do
                local target = SummonGroup[i]
                if GetOwningPlayer(target) == Player(self.pid - 1) and GetUnitTypeId(target) == SUMMON_HOUND then
                    SetUnitVertexColor(target, 120, 60, 60, 255)
                    SetUnitScale(target, 0.85, 0.85, 0.85)
                    SetUnitAbilityLevel(target, FourCC('A06F'), 1)
                end
            end

            DestroyGroup(ug)

            SummonGroup[#SummonGroup + 1] = destroyer[self.pid]
            SetHeroXP(destroyer[self.pid], R2I(RequiredXP(GetHeroLevel(Hero[self.pid]) - 1) + ((GetHeroLevel(Hero[self.pid]) + 1) * pt.dur * 100 / pt.armor) - 1), false)

            pt.timer:callPeriodically(0.5, SummonDurationXPBar, pt)
        end
    end

    ---@class DEVOUR : Spell
    DEVOUR = {}
    do
        local thistype = DEVOUR
        thistype.id = FourCC("A063") ---@type integer 
    end

    ---@class DEMONICSACRIFICE : Spell
    ---@field pheal number
    ---@field dur number
    DEMONICSACRIFICE = {}
    do
        local thistype = DEMONICSACRIFICE
        thistype.id = FourCC("A0K1") ---@type integer 

        thistype.pheal = 30. ---@type number
        thistype.dur = 15. ---@type number
        thistype.values = {thistype.pheal, thistype.dur}

        function thistype:onCast()
            --demon hound
            if GetUnitTypeId(self.target) == SUMMON_HOUND then
                SummonExpire(self.target)

                for i = 1, #SummonGroup do
                    local target = SummonGroup[i]
                    if GetOwningPlayer(target) == Player(self.pid - 1) then
                        local heal = BlzGetUnitMaxHP(target) * self.pheal * 0.01 * BOOST[self.pid]
                        HP(target, heal)
                    end
                end
            --meat golem
            elseif GetUnitTypeId(self.target) == SUMMON_GOLEM then
                if golemDevourStacks[self.pid] < 4 then
                    SummonExpire(self.target)
                end

                DemonicSacrificeBuff:add(self.caster, self.caster):duration(thistype.dur * LBOOST[self.pid])

                TimerQueue:callDelayed(3., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Orc\\AncestralSpirit\\AncestralSpiritCaster.mdl", self.target, "origin"))
            --destroyer
            elseif GetUnitTypeId(self.target) == SUMMON_DESTROYER then
                SummonExpire(self.target)
                destroyerSacrificeFlag[self.pid] = true

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
    STEEDCHARGE = {}
    do
        local thistype = STEEDCHARGE
        thistype.id = FourCC("A06B") ---@type integer 

        ---@type fun(pid: integer, angle: number, x: number, y: number)
        thistype.charge = function(pid, angle, x, y)
            local speed = Movespeed[pid] * 0.045

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

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    if SteedChargeStun:has(Hero[pid], target) == false then
                        Stun:add(Hero[pid], target):duration(1.)
                        SteedChargeStun:add(Hero[pid], target):duration(2.)
                        DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", target, "origin"))
                    end
                    target = FirstOfGroup(ug)
                end

                TimerQueue:callDelayed(FPS_32, thistype.charge, pid, angle, x, y)

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

            TimerQueue:callDelayed(0.05, thistype.charge, self.pid, self.angle, self.targetX, self.targetY)
        end
    end

    ---@class SHIELDSLAM : Spell
    ---@field dmg function
    SHIELDSLAM = {}
    do
        local thistype = SHIELDSLAM
        thistype.id = FourCC("A0HT") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev * (GetHeroStr(Hero[pid], true) + 6. * BlzGetUnitArmor(Hero[pid])) end ---@return number
        thistype.values = {thistype.dmg}

        function thistype:onCast()
            local dmg = self.dmg * BOOST[self.pid] ---@type number 

            StunUnit(self.pid, self.target, 3.)
            UnitDamageTarget(self.caster, self.target, dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

            local sfx = AddSpecialEffect("war3mapImported\\DetroitSmash_Effect_CasterArt.mdx", self.x, self.y)
            BlzSetSpecialEffectYaw(sfx, bj_DEGTORAD * GetUnitFacing(self.caster))
            DestroyEffect(sfx)

            if ShieldCount[self.pid] > 0 then
                local ug = CreateGroup()
                MakeGroupInRange(self.pid, ug, GetUnitX(self.target), GetUnitY(self.target), 300 * LBOOST[self.pid], Condition(FilterEnemy))
                GroupRemoveUnit(ug, self.target)

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    UnitDamageTarget(self.caster, target, dmg * .5, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    StunUnit(self.pid, target, 1.5)
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)
            end
        end
    end

    ---@class ROYALPLATE : Spell
    ---@field armor function
    ---@field dur number
    ROYALPLATE = {}
    do
        local thistype = ROYALPLATE
        thistype.id = FourCC("A0EG") ---@type integer 

        thistype.armor = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 0.006 * Pow(ablev, 5.) + 10. * Pow(ablev, 2.) + 25. * ablev end ---@return number
        thistype.dur = 15. ---@type number
        thistype.values = {thistype.armor, thistype.dur}

        function thistype:onCast()
            RoyalPlateBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class PROVOKE : Spell
    ---@field heal function
    ---@field aoe function
    PROVOKE = {}
    do
        local thistype = PROVOKE
        thistype.id = FourCC("A04Y") ---@type integer 

        thistype.heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (BlzGetUnitMaxHP(Hero[pid]) - GetWidgetLife(Hero[pid])) * (0.2 + 0.01 * ablev) end ---@return number
        thistype.aoe = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 450. + 50. * ablev end ---@return number
        thistype.values = {thistype.heal, thistype.aoe}

        function thistype:onCast()
            local ug = CreateGroup()

            HP(self.caster, self.heal * BOOST[self.pid])
            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\Taunt\\TauntCaster.mdl", self.caster, "origin"))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                DummyCastTarget(Player(self.pid - 1), target, FourCC('A04X'), 1, GetUnitX(target), GetUnitY(target), "slow")
                target = FirstOfGroup(ug)
            end

            Taunt(self.caster, self.pid, 800., true, 2000, 2000)

            DestroyGroup(ug)
        end
    end

    ---@class FIGHTME : Spell
    ---@field dur function
    FIGHTME = {}
    do
        local thistype = FIGHTME
        thistype.id = FourCC("A09E") ---@type integer 

        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (4. + ablev) end ---@return number
        thistype.values = {thistype.dur}

        function thistype:onCast()
            FightMeCasterBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class PROTECTOR : Spell
    PROTECTOR = {}
    do
        local thistype = PROTECTOR
        thistype.id = FourCC("A0HS") ---@type integer 
    end

    --assassin

    ---@class SHADOWSHURIKEN : Spell
    ---@field dmg function
    SHADOWSHURIKEN = {}
    do
        local thistype = SHADOWSHURIKEN
        thistype.id = FourCC("A0BG") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (GetHeroAgi(Hero[pid], true) + UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0)) * (ablev + 5.) * 0.25 end ---@return number
        thistype.values = {thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            if pt.dur > 0. then
                SetUnitXBounded(pt.target, GetUnitX(pt.target) + pt.speed * Cos(pt.angle))
                SetUnitYBounded(pt.target, GetUnitY(pt.target) + pt.speed * Sin(pt.angle))

                pt.dur = pt.dur - pt.speed

                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), pt.aoe, Condition(FilterEnemy))
                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
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
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end

                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end
        end

        function thistype:onCast()
            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPINPASSIVE.id, true)
            UpdateManaCosts(self.pid)

            local pt = TimerList[self.pid]:add()
            pt.target = GetDummy(self.x, self.y, 0, 0, DUMMY_RECYCLE_TIME)
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

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class BLINKSTRIKE : Spell
    ---@field dmg function
    ---@field aoe number
    BLINKSTRIKE = {}
    do
        local thistype = BLINKSTRIKE
        thistype.id = FourCC("A00T") ---@type integer 

        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev * (0.5 * GetHeroAgi(Hero[pid], true) + 0.25 * (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + BlzGetUnitBaseDamage(Hero[pid], 0))) end ---@return number
        thistype.aoe = 200. ---@type number
        thistype.values = {thistype.dmg, thistype.aoe}

        function thistype:onCast()
            local ug = CreateGroup()

            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPINPASSIVE.id, true)
            UpdateManaCosts(self.pid)

            for i = 0, 11 do
                self.angle = 0.1666 * bj_PI * i
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", self.targetX + 190. * Cos(self.angle), self.targetY + 190. * Sin(self.angle)))
            end

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\FeralSpirit\\feralspiritdone.mdl", self.targetX, self.targetY))
            MakeGroupInRange(self.pid, ug, self.targetX, self.targetY, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))

                local debuff = MarkedForDeathDebuff:get(nil, target)

                if debuff then
                    SetUnitPathing(target, true)
                    debuff:remove()
                    BlinkStrikeBuff:add(Hero[self.pid], Hero[self.pid]):duration(6.)
                end

                UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            SetUnitXBounded(self.caster, self.targetX)
            SetUnitYBounded(self.caster, self.targetY)

            DestroyGroup(ug)
        end
    end

    ---@class SMOKEBOMB : Spell
    ---@field aoe number
    ---@field dur number
    SMOKEBOMB = {}
    do
        local thistype = SMOKEBOMB
        thistype.id = FourCC("A01E") ---@type integer 

        thistype.aoe = 300. ---@type number
        thistype.dur = 8. ---@type number
        thistype.values = {thistype.aoe, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 0.5

            if pt.dur > 0. then
                local ug = CreateGroup()
                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(isalive))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    if IsUnitAlly(target, Player(pt.pid - 1)) then
                        SmokebombBuff:add(Hero[pt.pid], target):duration(1.)
                    else
                        SmokebombDebuff:add(Hero[pt.pid], target):duration(1.)
                    end
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.5, thistype.periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPINPASSIVE.id, true)
            UpdateManaCosts(self.pid)

            local pt = TimerList[self.pid]:add()
            pt.x = self.targetX
            pt.y = self.targetY
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dur = self.dur * LBOOST[self.pid]

            pt.timer:callDelayed(0.5, thistype.periodic, pt)
            TimerQueue:callDelayed(pt.dur, DestroyEffect, AddSpecialEffect("war3mapImported\\GreySmoke.mdx", self.targetX, self.targetY))
        end
    end

    ---@class DAGGERSTORM : Spell
    ---@field dmg function
    ---@field num number
    DAGGERSTORM = {}
    do
        local thistype = DAGGERSTORM
        thistype.id = FourCC("A00P") ---@type integer 

        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 2. end ---@return number
        thistype.num = 30. ---@type number
        thistype.values = {thistype.dmg, thistype.num}

        function thistype.periodic(pt)
            local i = 1

            if pt.count > 0 then
                pt.count = pt.count - 3

                for _ = 0, 2 do
                    i = -i
                    local spawnangle = pt.angle + bj_PI + GetRandomReal(bj_PI * -0.15, bj_PI * 0.15) ---@type number
                    local x = pt.x + GetRandomReal(70., 300.) * Cos(spawnangle) ---@type number
                    local y = pt.y + GetRandomReal(70., 300.) * Sin(spawnangle) ---@type number
                    local moveangle = Atan2(pt.targetY - y, pt.targetX - x)
                    local missile = Missiles:create(x, y, 70, x + 1150. * Cos(moveangle), y + 1150. * Sin(moveangle), 0) ---@type Missiles
                    missile:model("Abilities\\Weapons\\WardenMissile\\WardenMissile.mdl")
                    missile:scale(1.1)
                    missile:speed(1400)
                    missile:arc(GetRandomReal(5, 15))
                    missile:curve(GetRandomReal(1, 10) * i)
                    missile.source = pt.source
                    missile.owner = Player(pt.pid - 1)
                    missile:vision(400)
                    missile.collision = 45
                    missile.damage = pt.dmg * BOOST[pt.pid]

                    missile.onHit = function(unit)
                        if unit ~= missile.source and IsUnitEnemy(unit, missile.owner) then
                            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", unit, "origin"))
                            UnitDamageTarget(missile.source, unit, missile.damage, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                            missile.damage = missile.damage - missile.damage * 0.05
                        end

                        return false
                    end

                    missile:launch()
                end

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            --change blade spin to active
            UnitAddAbility(self.caster, BLADESPIN.id)
            UnitDisableAbility(self.caster, BLADESPINPASSIVE.id, true)
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

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@class BLADESPINPASSIVE : Spell
    ---@field times function
    ---@field admg function
    ---@field aoe number
    ---@field pdmg function
    BLADESPINPASSIVE = {}
    do
        local thistype = BLADESPINPASSIVE
        thistype.id = FourCC("A0AQ") ---@type integer 

        thistype.times = function(pid) return math.max(8 - GetHeroLevel(Hero[pid]) // 100, 5) end ---@return number
        thistype.pdmg = function(pid) return 8. * GetHeroAgi(Hero[pid], true) end ---@return number
        thistype.aoe = 250. ---@type number
        thistype.admg = function(pid) return 4. * GetHeroAgi(Hero[pid], true) end ---@return number
        thistype.values = {thistype.times, thistype.pdmg, thistype.aoe, thistype.admg}
    end

    ---@class BLADESPIN : Spell
    ---@field spin function
    ---@field times function
    ---@field amdg function
    ---@field aoe number
    ---@field pdmg function
    BLADESPIN = {}
    do
        local thistype = BLADESPIN
        thistype.id = FourCC("A0AS") ---@type integer 

        thistype.times = function(pid) return math.max(8 - GetHeroLevel(Hero[pid]) // 100, 5) end ---@return number
        thistype.pdmg = function(pid) return 8. * GetHeroAgi(Hero[pid], true) end ---@return number
        thistype.aoe = 250. ---@type number
        thistype.admg = function(pid) return 4. * GetHeroAgi(Hero[pid], true) end ---@return number
        thistype.values = {thistype.times, thistype.pdmg, thistype.aoe, thistype.admg}

        ---@type fun(caster: unit, active: boolean)
        function thistype.spin(caster, active)
            local ug = CreateGroup()
            local pid = GetPlayerId(GetOwningPlayer(caster)) + 1
            local ablev = GetUnitAbilityLevel(caster, thistype.id)
            local target

            DelayAnimation(pid, caster, 0.5, 0, 1., true)
            SetUnitTimeScale(caster, 1.75)
            SetUnitAnimationByIndex(caster, 5)

            target = GetDummy(GetUnitX(caster), GetUnitY(caster), 0, 0, DUMMY_RECYCLE_TIME)
            BlzSetUnitSkin(target, FourCC('h00C'))
            SetUnitTimeScale(target, 0.5)
            SetUnitScale(target, 1.35, 1.35, 1.35)
            SetUnitAnimationByIndex(target, 0)
            SetUnitFlyHeight(target, 75., 0)
            BlzSetUnitFacingEx(target, GetUnitFacing(caster))

            target = GetDummy(GetUnitX(caster), GetUnitY(caster), 0, 0, DUMMY_RECYCLE_TIME)
            BlzSetUnitSkin(target, FourCC('h00C'))
            SetUnitTimeScale(target, 0.5)
            SetUnitScale(target, 1.35, 1.35, 1.35)
            SetUnitAnimationByIndex(target, 0)
            SetUnitFlyHeight(target, 75., 0)
            BlzSetUnitFacingEx(target, GetUnitFacing(caster) + 180)

            MakeGroupInRange(pid, ug, GetUnitX(caster), GetUnitY(caster), thistype.aoe * LBOOST[pid], Condition(FilterEnemy))

            target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", target, "chest"))
                if active then
                    UnitDamageTarget(caster, target, thistype.admg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                else
                    UnitDamageTarget(caster, target, thistype.pdmg(pid) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                end
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        end
    end

    ---@class PHANTOMSLASH : Spell
    ---@field dmg function
    PHANTOMSLASH = {}
    do
        local thistype = PHANTOMSLASH
        thistype.id = FourCC("A07Y") ---@type integer 

        thistype.dmg = function(pid) return GetHeroAgi(Hero[pid], true) * 1.5 end ---@return number
        thistype.values = {thistype.dmg}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local x = GetUnitX(pt.source) ---@type number 
            local y = GetUnitY(pt.source) ---@type number 

            pt.dur = pt.dur - pt.speed

            IssueImmediateOrderById(pt.source, 852178)
            if pt.dur - pt.speed <= 0 then
                IssueImmediateOrder(pt.source, "stop")
            end

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

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    if not IsUnitInGroup(target, pt.ug) then
                        GroupAddUnit(pt.ug, target)
                        MarkedForDeathDebuff:add(pt.source, target):duration(4.)
                        UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                BlzUnitDisableAbility(pt.source, thistype.id, false, false)

                PhantomSlashing[pt.pid] = false
                SetUnitTimeScale(pt.source, 1.)
                SetUnitAnimationByIndex(pt.source, 4)
                pt:destroy()
            end
        end

        function thistype:onCast()
            PhantomSlashing[self.pid] = true
            TotalEvasion[self.pid] = 100

            BlzUnitDisableAbility(self.caster, thistype.id, true, false)
            SetUnitState(self.caster, UNIT_STATE_MANA, GetUnitState(self.caster, UNIT_STATE_MANA) - BlzGetUnitMaxMana(self.caster) * (.1 - 0.025 * self.ablev))

            local pt = TimerList[self.pid]:add()
            pt.dur = math.min(750., SquareRoot(Pow(self.targetX - self.x, 2) + Pow(self.targetY - self.y, 2)))
            pt.speed = 60.
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.angle = Atan2(self.targetY - self.y, self.targetX - self.x)
            pt.source = self.caster
            pt.ug = CreateGroup()

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)

            SetUnitTimeScale(self.caster, 1.5)
            SetUnitAnimationByIndex(self.caster, 5)
            BlzSetUnitFacingEx(self.caster, pt.angle * bj_RADTODEG)

            local sfx = AddSpecialEffect("war3mapImported\\ShadowWarrior.mdl", self.x, self.y)
            BlzSetSpecialEffectColorByPlayer(sfx, Player(self.pid - 1))
            BlzSetSpecialEffectYaw(sfx, pt.angle)
            FadeSFX(sfx, true)
            TimerQueue:callDelayed(2., DestroyEffect, sfx)
            BlzPlaySpecialEffectWithTimeScale(sfx, ANIM_TYPE_ATTACK, 1.5)
        end
    end

    --arcanist

    ---@class CONTROLTIME : Spell
    ---@field dur number
    CONTROLTIME = {}
    do
        local thistype = CONTROLTIME
        thistype.id = FourCC("A04C") ---@type integer 
        thistype.dur = 10. ---@type number
        thistype.values = {thistype.dur}

        function thistype:onCast()
            ControlTimeBuff:add(self.caster, self.caster):duration(self.dur * LBOOST[self.pid])
        end
    end

    ---@class ARCANECOMETS : Spell
    ---@field dmg function
    ---@field aoe number
    ARCANECOMETS = {}
    do
        local thistype = ARCANECOMETS
        thistype.id = FourCC("A00U") ---@type integer 

        thistype.dmg = function(pid) return 2. * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.aoe = 250. ---@type number
        thistype.values = {thistype.dmg, thistype.aoe}

        ---@type fun(pt: PlayerTimer)
        function thistype.expire(pt)
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            pt:destroy()

            DestroyGroup(ug)
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.spawn(pt)
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

                    pt2.timer:callDelayed(0.6, thistype.expire, pt2)
                end

                pt.timer:callDelayed(0.2, thistype.spawn, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()  
            pt.source = self.caster
            pt.count = self.ablev + 2
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.x = self.x
            pt.y = self.y

            pt.timer:callDelayed(0.2, thistype.spawn, pt)
        end
    end

    ---@class ARCANEBOLTS : Spell
    ---@field dmg function
    ---@field aoe number
    ARCANEBOLTS = {}
    do
        local thistype = ARCANEBOLTS
        thistype.id = FourCC("A05Q") ---@type integer 

        thistype.dmg = function(pid) return 2. * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.aoe = 250. ---@type number
        thistype.values = {thistype.dmg, thistype.aoe}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 40.

            if pt.dur >= 0 then
                local x = GetUnitX(pt.target) ---@type number 
                local y = GetUnitY(pt.target) ---@type number 
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, x, y, 125., Condition(FilterEnemy))

                local target = FirstOfGroup(ug)

                --a unit was found
                if target then
                    MakeGroupInRange(pt.pid, ug, x, y, pt.aoe, Condition(FilterEnemy))

                    while target do
                        GroupRemoveUnit(ug, target)
                        UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        target = FirstOfGroup(ug)
                    end

                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", x, y))
                    pt.dur = 0.
                else
                    SetUnitXBounded(pt.target, x + 40. * Cos(pt.angle))
                    SetUnitYBounded(pt.target, y + 40. * Sin(pt.angle))
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                SetUnitAnimation(pt.target, "death")
                pt:destroy()
            end
        end

        ---@type fun(pt: PlayerTimer)
        function thistype.spawn(pt)
            local x = GetUnitX(pt.source) ---@type number 
            local y = GetUnitY(pt.source) ---@type number 

            pt.dur = pt.dur - 1

            if pt.dur >= 0 then
                local target = GetDummy(x, y, 0, 0, 3.)

                BlzSetUnitSkin(target, FourCC('h00Y'))
                BlzSetUnitFacingEx(target, bj_RADTODEG * pt.angle)
                SetUnitFlyHeight(target, 55.00, 0.00)
                SetUnitScale(target, 1.3, 1.3, 1.3)

                local pt2 = TimerList[pt.pid]:add()
                pt2.angle = pt.angle
                pt2.source = pt.source
                pt2.target = target
                pt2.dur = 1000.
                pt2.aoe = pt.aoe
                pt2.dmg = pt.dmg

                pt2.timer:callDelayed(FPS_32, thistype.periodic, pt2)
            else
                pt:destroy()
            end
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()  
            pt.dur = 1.
            pt.angle = self.angle
            pt.source = self.caster
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.timer:callDelayed(0., thistype.spawn, pt)

            pt = TimerList[self.pid]:add()
            pt.dur = self.ablev + 1
            pt.angle = self.angle
            pt.source = self.caster
            pt.dmg = self.dmg * BOOST[self.pid]
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.timer:callDelayed(0.2, thistype.spawn, pt)
        end
    end

    ---@class ARCANEBARRAGE : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field cd function
    ARCANEBARRAGE = {}
    do
        local thistype = ARCANEBARRAGE
        thistype.id = FourCC("A02N") ---@type integer 

        thistype.aoe = 750. ---@type number
        thistype.dmg = function(pid) return GetHeroInt(Hero[pid], true) * (GetUnitAbilityLevel(Hero[pid], thistype.id) + 1.) end ---@return number
        thistype.cd = function(pid) return TimerList[pid]:has(ARCANOSPHERE.id) and 8. or 25. end
        thistype.values = {thistype.aoe, thistype.dmg, thistype.cd}

        function thistype:onCast()
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

                    local dummy = GetDummy(self.targetX, self.targetY, FourCC('A008'), 1, DUMMY_RECYCLE_TIME)
                    SetUnitOwner(dummy, Player(self.pid - 1), true)
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(self.targetY - GetUnitY(target), self.targetX - GetUnitX(target)))
                    SetUnitFlyHeight(dummy, 150., 0.)
                    UnitDisableAbility(dummy, FourCC('Amov'), true)
                    InstantAttack(dummy, target)
                end
            end

            DestroyGroup(ug)
        end
    end

    ---@class ARCANOSPHERE : Spell
    ---@field dur function
    ARCANOSPHERE = {}
    do
        local thistype = ARCANOSPHERE
        thistype.id = FourCC("A079") ---@type integer 

        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 8. + 4. * ablev end ---@return number
        thistype.values = {thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

            pt.dur = pt.dur - 0.5

            if pt.dur > 0. then
                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    ArcanosphereDebuff:add(pt.source, target):duration(1.)
                    target = FirstOfGroup(ug)
                end

                pt.timer:callDelayed(0.5, thistype.periodic, pt)
            else
                SetUnitAnimation(pt.target, "death")

                UnitRemoveAbility(pt.source, ARCANECOMETS.id)
                BlzUnitHideAbility(pt.source, ARCANEBOLTS.id, false)
                BlzSetUnitAbilityCooldown(pt.source, ARCANEBARRAGE.id, GetUnitAbilityLevel(pt.source, ARCANEBARRAGE.id) - 1, 25.)
                SetUnitTurnSpeed(pt.source, GetUnitDefaultTurnSpeed(pt.source))
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

            pt.target = GetDummy(self.targetX, self.targetY, 0, 0, pt.dur + 2.)
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

            pt.timer:callDelayed(0.5, thistype.periodic, pt)

            SetUnitTurnSpeed(self.caster, 1.)
        end
    end

    ---@class STASISFIELD : Spell
    ---@field aoe number
    ---@field dur number
    STASISFIELD = {}
    do
        local thistype = STASISFIELD
        thistype.id = FourCC("A075") ---@type integer 

        thistype.aoe = 250. ---@type number
        thistype.dur = 6. ---@type number
        thistype.values = {thistype.aoe, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.dur = pt.dur - 0.25

            if pt.dur > 0. then
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(FilterEnemy))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    StasisFieldDebuff:add(pt.source, target):duration(0.5)
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)

                pt.timer:callDelayed(0.25, thistype.periodic, pt)
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

            pt.target = GetDummy(pt.x, pt.y, 0, 0, 6.)
            BlzSetUnitSkin(pt.target, FourCC('h02B'))
            SetUnitScale(pt.target, 1.05 * LBOOST[self.pid], 1.05 * LBOOST[self.pid], 1.05 * LBOOST[self.pid])
            UnitDisableAbility(pt.target, FourCC('Amov'), true)
            SetUnitFlyHeight(pt.target, 0., 0.)
            SetUnitAnimation(pt.target, "birth")

            pt.timer:callDelayed(0.25, thistype.periodic, pt)
        end
    end

    ---@class ARCANESHIFT : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field dur number
    ARCANESHIFT = {}
    do
        local thistype = ARCANESHIFT
        thistype.id = FourCC("A078") ---@type integer 

        thistype.aoe = 350. ---@type number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (5. + 3. * ablev) * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.dur = 4. ---@type number
        thistype.values = {thistype.aoe, thistype.dmg, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            if pt.time == 0 then
                BlzEndUnitAbilityCooldown(pt.source, thistype.id)
            end

            pt.time = pt.time + FPS_32

            if pt.time >= pt.dur then
                local target = FirstOfGroup(pt.ug)
                while target do
                    GroupRemoveUnit(pt.ug, target)
                    SetUnitFlyHeight(target, 0.00, 0.00)
                    if GetUnitMoveSpeed(target) > 0 then
                        SetUnitPathing(target, false)
                        SetUnitXBounded(target, pt.x)
                        SetUnitYBounded(target, pt.y)
                        ResetPathingTimed(target, 2.)
                    end
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(target), GetUnitY(target)))
                    UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(pt.ug)
                end

                BlzStartUnitAbilityCooldown(pt.source, thistype.id, pt.cd - pt.time)

                pt:destroy()
            else
                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
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

                local target = FirstOfGroup(ug)

                if target then
                    pt = TimerList[self.pid]:add()
                    pt.ug = CreateGroup()
                    pt.dmg = self.dmg * BOOST[self.pid]
                    pt.dur = self.dur * LBOOST[self.pid]
                    pt.cd = 80 --original cooldown
                    pt.source = self.caster
                    pt.tag = thistype.id
                    pt.x = self.targetX
                    pt.y = self.targetY

                    while target do
                        GroupRemoveUnit(ug, target)
                        GroupAddUnit(pt.ug, target)
                        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", GetUnitX(target), GetUnitY(target)))
                        if UnitAddAbility(target, FourCC('Amrf')) then
                            UnitRemoveAbility(target, FourCC('Amrf'))
                        end
                        Stun:add(self.caster, target):duration(pt.dur)
                        SetUnitFlyHeight(target, 500.00, 0.00)
                        target = FirstOfGroup(ug)
                    end

                    pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
                end

                DestroyGroup(ug)
            end
        end
    end

    --dark savior

    ---@class SOULSTEAL : Spell
    SOULSTEAL = {}
    do
        local thistype = SOULSTEAL
        thistype.id = FourCC("A08Z") ---@type integer 
    end

    ---@class DARKSEAL : Spell
    ---@field dur number
    DARKSEAL = {}
    do
        local thistype = DARKSEAL
        thistype.id = FourCC("A0GO") ---@type integer 

        thistype.dur = 12. ---@type number
        thistype.values = {thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, pt.x, pt.y, 450. * LBOOST[pt.pid], Condition(FilterEnemy))

            --reset base attack time
            BlzSetUnitAttackCooldown(pt.source, BlzGetUnitAttackCooldown(pt.source, 0) * (1. + pt.count * 0.01), 0)

            pt.dur = pt.dur - 0.5

            if pt.dur > 0. then
                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    GroupAddUnit(pt.ug, target)
                    DarkSealDebuff:add(pt.source, target):duration(1.)
                    target = FirstOfGroup(ug)
                end

                --count units in seal
                local count = BlzGroupGetSize(pt.ug)
                pt.count = 0.
                if count > 0 then
                    for index = 0, count - 1 do
                        target = BlzGroupUnitAt(pt.ug, index)
                        if IsUnitType(target, UNIT_TYPE_HERO) then
                            pt.count = pt.count + 10.
                        else
                            pt.count = pt.count + 1.
                        end
                    end
                end
                pt.count = math.min(5. + GetHeroLevel(pt.source) / 100 * 10, pt.count)

                --apply base attack time
                BlzSetUnitAttackCooldown(pt.source, BlzGetUnitAttackCooldown(pt.source, 0) / (1. + pt.count * 0.01), 0)

                pt.timer:callDelayed(0.5, thistype.periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()  

            pt.dur = self.dur * LBOOST[self.pid]
            pt.x = self.targetX
            pt.y = self.targetY
            pt.tag = thistype.id
            pt.source = self.caster
            pt.ug = CreateGroup()
            pt.count = 0.

            pt.target = GetDummy(pt.x, pt.y, 0, 0, pt.dur)

            BlzSetUnitSkin(pt.target, FourCC('h03X'))
            UnitDisableAbility(pt.target, FourCC('Amov'), true)
            SetUnitScale(pt.target, 6.1, 6.1, 6.1)
            BlzSetUnitFacingEx(pt.target, 270)
            SetUnitAnimation(pt.target, "birth")
            SetUnitTimeScale(pt.target, 0.8)
            DelayAnimation(self.pid, pt.target, 1., 0, 1., false)

            pt.timer:callDelayed(0.5, thistype.periodic, pt)
        end
    end

    ---@class MEDEANLIGHTNING : Spell
    ---@field targets function
    ---@field dmg function
    ---@field aoe number
    ---@field dur number
    MEDEANLIGHTNING = {}
    do
        local thistype = MEDEANLIGHTNING
        thistype.id = FourCC("A019") ---@type integer 

        thistype.targets = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return ablev + 1.5 end ---@return number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (1.5 + 0.5 * ablev) * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.aoe = 900. ---@type number
        thistype.dur = 3. ---@type number
        thistype.values = {thistype.targets, thistype.dmg, thistype.aoe, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
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
                local dummy
                for i = 0, pt.time - 1 do
                    target = BlzGroupUnitAt(ug, i)
                    if not target then break end
                    dummy = GetDummy(x, y, FourCC('A01Y'), 1, 4.)
                    SetUnitOwner(dummy, Player(pt.pid - 1), false)
                    BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(dummy), GetUnitX(target) - GetUnitX(dummy)))
                    UnitDisableAbility(dummy, FourCC('Amov'), true)
                    InstantAttack(dummy, target)
                end

                --dark seal augment
                local pt2 = TimerList[pt.pid]:get(DARKSEAL.id, pt.source)

                if pt2 then
                    BlzGroupAddGroupFast(pt2.ug, ug)
                    local count = BlzGroupGetSize(ug)

                    if count > 0 then
                        for index = 0, count - 1 do
                            target = BlzGroupUnitAt(ug, index)

                            if GetUnitAbilityLevel(target, FourCC('A06W')) > 0 then
                                local angle = 360. / count * (index + 1) * bj_DEGTORAD
                                x = pt2.x + 380 * Cos(angle)
                                y = pt2.y + 380 * Sin(angle)

                                dummy = GetDummy(x, y, FourCC('A01Y'), 1, 4.)
                                SetUnitOwner(dummy, Player(pt.pid - 1), false)
                                BlzSetUnitFacingEx(dummy, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(dummy), GetUnitX(target) - GetUnitX(dummy)))
                                UnitDisableAbility(dummy, FourCC('Amov'), true)
                                InstantAttack(dummy, target)
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

                pt.timer:callDelayed(1., thistype.periodic, pt)
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

            pt.timer:callDelayed(1., thistype.periodic, pt)
        end
    end

    ---@class FREEZINGBLAST : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field slow number
    ---@field freeze number
    FREEZINGBLAST = {}
    do
        local thistype = FREEZINGBLAST
        thistype.id = FourCC("A074") ---@type integer 

        thistype.aoe = 250. ---@type number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (ablev + 2.) end ---@return number
        thistype.slow = 3. ---@type number
        thistype.freeze = 1.5 ---@type number
        thistype.values = {thistype.aoe, thistype.dmg, thistype.slow, thistype.freeze}

        function thistype:onCast()
            local pt = TimerList[self.pid]:get(DARKSEAL.id, self.caster)  
            local ug = CreateGroup()

            MakeGroupInRange(self.pid, ug, self.targetX, self.targetY, self.aoe * LBOOST[self.pid], Condition(FilterEnemy))

            --dark seal
            if pt then
                BlzGroupAddGroupFast(pt.ug, ug)

                local sfx = AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", pt.x, pt.y)
                BlzSetSpecialEffectScale(sfx, 5)
                TimerQueue:callDelayed(3, DestroyEffect, sfx)
            end

            DestroyEffect(AddSpecialEffect("war3mapImported\\AquaSpikeVersion2.mdx", self.targetX, self.targetY))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                Freeze:add(Hero[self.pid], target):duration(self.freeze * LBOOST[self.pid])
                if IsUnitInRangeXY(target, self.targetX, self.targetY, self.aoe * LBOOST[self.pid]) == true and pt then
                    UnitDamageTarget(self.caster, target, self.dmg * 2 * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                else
                    UnitDamageTarget(self.caster, target, self.dmg * BOOST[self.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                end
                target = FirstOfGroup(ug)
            end
        end
    end

    ---@class METAMORPHOSIS : Spell
    ---@field dur function
    METAMORPHOSIS = {}
    do
        local thistype = METAMORPHOSIS
        thistype.id = FourCC("A02S") ---@type integer 

        thistype.dur = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return 5. + 5. * ablev end ---@return number
        thistype.values = {thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.expire(pt)
            metamorphosis[pt.pid] = 0.

            pt:destroy()
        end

        function thistype:onCast()
            if GetUnitTypeId(self.caster) == HERO_DARK_SAVIOR then
                local hp = GetWidgetLife(self.caster) * 0.5 ---@type number 

                SetWidgetLife(self.caster, hp)
                metamorphosis[self.pid] = math.max(0.01, hp / (BlzGetUnitMaxHP(self.caster) * 1.))

                local pt = TimerList[self.pid]:add()

                pt.timer:callDelayed(self.dur * LBOOST[self.pid], thistype.expire, pt)
            end
        end
    end

    --bard

    ---@class SONGOFFATIGUE : Spell
    SONGOFFATIGUE = {}
    do
        local thistype = SONGOFFATIGUE
        thistype.id = FourCC("A025") ---@type integer 

        function thistype:onCast()
            local p = Player(self.pid - 1) ---@type player 

            BardSong[self.pid] = SONG_FATIGUE
            SetPlayerAbilityAvailable(p, SONG_FATIGUE, true)
            SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
            SetPlayerAbilityAvailable(p, SONG_PEACE, false)
            SetPlayerAbilityAvailable(p, SONG_WAR, false)
            if songeffect[self.pid] == nil then
                songeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", self.caster, "overhead")
            end
            BlzSetSpecialEffectColorByPlayer(songeffect[self.pid], Player(3))
        end
    end

    ---@class SONGOFHARMONY : Spell
    SONGOFHARMONY = {}
    do
        local thistype = SONGOFHARMONY
        thistype.id = FourCC("A026") ---@type integer 

        function thistype:onCast()
            local p = Player(self.pid - 1) ---@type player 

            BardSong[self.pid] = SONG_HARMONY
            SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
            SetPlayerAbilityAvailable(p, SONG_HARMONY, true)
            SetPlayerAbilityAvailable(p, SONG_PEACE, false)
            SetPlayerAbilityAvailable(p, SONG_WAR, false)
            if songeffect[self.pid] == nil then
                songeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", self.caster, "overhead")
            end
            BlzSetSpecialEffectColorByPlayer(songeffect[self.pid], Player(6))
        end
    end

    ---@class SONGOFPEACE : Spell
    SONGOFPEACE = {}
    do
        local thistype = SONGOFPEACE
        thistype.id = FourCC("A027") ---@type integer 

        function thistype:onCast()
            local p = Player(self.pid - 1) ---@type player 

            BardSong[self.pid] = SONG_PEACE
            SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
            SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
            SetPlayerAbilityAvailable(p, SONG_PEACE, true)
            SetPlayerAbilityAvailable(p, SONG_WAR, false)
            if songeffect[self.pid] == nil then
                songeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", self.caster, "overhead")
            end
            BlzSetSpecialEffectColorByPlayer(songeffect[self.pid], Player(4))
        end
    end

    ---@class SONGOFWAR : Spell
    SONGOFWAR = {}
    do
        local thistype = SONGOFWAR
        thistype.id = FourCC("A02C") ---@type integer 

        function thistype:onCast()
            local p = Player(self.pid - 1) ---@type player 

            BardSong[self.pid] = SONG_WAR
            SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
            SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
            SetPlayerAbilityAvailable(p, SONG_PEACE, false)
            SetPlayerAbilityAvailable(p, SONG_WAR, true)
            if songeffect[self.pid] == nil then
                songeffect[self.pid] = AddSpecialEffectTarget("war3mapImported\\Music effect01.mdx", self.caster, "overhead")
            end
            BlzSetSpecialEffectColorByPlayer(songeffect[self.pid], Player(0))
        end
    end

    ---@class ENCORE : Spell
    ---@field aoe number
    ---@field wardur number
    ---@field heal function
    ---@field peacedur number
    ---@field fatiguedur number
    ENCORE = {}
    do
        local thistype = ENCORE
        thistype.id = FourCC("A0AZ") ---@type integer 

        thistype.aoe = 900. ---@type number
        thistype.wardur = 5. ---@type number
        thistype.heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return GetHeroInt(Hero[pid], true) * (.75 + .25 * ablev) end ---@return number
        thistype.peacedur = 5. ---@type number
        thistype.fatiguedur = 3. ---@type number
        thistype.values = {thistype.aoe, thistype.wardur, thistype.heal, thistype.peacedur, thistype.fatiguedur}

        function thistype:onCast()
            local ug = CreateGroup()
            local song = pt.song ---@type integer 
            local x2 = 0. ---@type number 
            local y2 = 0. ---@type number 
            local aoe = 0. ---@type number 
            local p = Player(self.pid - 1) ---@type player 

            MakeGroupInRange(self.pid, ug, self.x, self.y, self.aoe * LBOOST[self.pid], Condition(isalive))

            --harmony all allied units
            --war all allied heroes
            --fatigue all enemies
            --peace all heroes

            --improv
            local pt = TimerList[self.pid]:get(IMPROV.id, nil, caster)  

            if pt then
                GroupEnumUnitsInRangeEx(self.pid, ug, pt.x, pt.y, pt.aoe, Condition(isalive))
                x2 = pt.x
                y2 = pt.y
                aoe = pt.aoe
            end

            local target = FirstOfGroup(ug)
            while target do
                self.tpid = GetPlayerId(GetOwningPlayer(target)) + 1
                GroupRemoveUnit(ug, target)

                --allied units
                if IsUnitAlly(target, p) == true then
                    --song of harmony
                    if (BardSong[self.pid] == SONG_HARMONY and IsUnitInRangeXY(target, x, y, aoe)) or (song == SONG_HARMONY and IsUnitInRangeXY(target, x2, y2, aoe)) then
                        HP(target, thistype.heal(self.pid) * BOOST[self.pid])
                        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", target, "origin"))
                    end
                    --heroes
                    if target == Hero[self.tpid] then
                        --song of war
                        if (BardSong[self.pid] == SONG_WAR and IsUnitInRangeXY(target, x, y, aoe)) or (song == SONG_WAR and IsUnitInRangeXY(target, x2, y2, aoe)) then
                            SongOfWarEncoreBuff:add(caster, target):duration(thistype.wardur(self.pid) * LBOOST[self.pid])
                        end
                        --song of peace
                        if (BardSong[self.pid] == SONG_PEACE and IsUnitInRangeXY(target, x, y, aoe)) or (song == SONG_PEACE and IsUnitInRangeXY(target, x2, y2, aoe)) then
                            SongOfPeaceEncoreBuff:add(caster, target):duration(thistype.peacedur(self.pid) * LBOOST[self.pid])
                        end
                    end
                else
                --enemies
                    --song of fatigue
                    if (BardSong[self.pid] == SONG_FATIGUE and IsUnitInRangeXY(target, x, y, aoe)) or (song == SONG_FATIGUE and IsUnitInRangeXY(target, x2, y2, aoe)) then
                        StunUnit(self.pid, target, thistype.fatiguedur(self.pid) * LBOOST[self.pid])
                    end
                end
                target = FirstOfGroup(ug)
            end
        end
    end

    ---@class MELODYOFLIFE : Spell
    ---@field cost function
    ---@field heal function
    MELODYOFLIFE = {}
    do
        local thistype = MELODYOFLIFE
        thistype.id = FourCC("A02H") ---@type integer 

        thistype.cost = function(pid) return BardMelodyCost[pid] end ---@return number
        thistype.heal = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return BardMelodyCost[pid] * (.25 + .25 * ablev) end ---@return number
        thistype.values = {thistype.cost, thistype.heal}

        function thistype:onCast()
            local p = Player(self.pid - 1) ---@type player 
            local heal = self.heal * BOOST[self.pid] ---@type number 

            if GetUnitTypeId(self.target) == BACKPACK then
                HP(Hero[self.tpid], heal)
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", GetUnitX(Hero[self.tpid]), GetUnitY(Hero[self.tpid])))
            elseif IsUnitAlly(self.target, p) then
                HP(self.target, heal)
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", self.targetX, self.targetY))
            end
        end
    end

    ---@class IMPROV : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field dur number
    IMPROV = {}
    do
        local thistype = IMPROV
        thistype.id = FourCC("A06Y") ---@type integer 

        thistype.aoe = 750. ---@type number
        thistype.dmg = function(pid) local ablev = GetUnitAbilityLevel(Hero[pid], thistype.id) return (0.25 + 0.25 * ablev) * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.dur = 20. ---@type number
        thistype.values = {thistype.aoe, thistype.dmg, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)
            pt.time = pt.time + 1.

            if pt.time >= pt.dur then
                BlzSetSpecialEffectScale(pt.sfx, 1.)
                SetUnitScale(pt.source, 1., 1., 1.)
                pt:destroy()
            else
                local ug = CreateGroup()

                MakeGroupInRange(pt.pid, ug, pt.x, pt.y, pt.aoe, Condition(isalive))

                local target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    if IsUnitAlly(target, Player(pt.pid - 1)) == false then
                        if ModuloInteger(R2I(pt.time),2) == 0 then
                            UnitDamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
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
                    target = FirstOfGroup(ug)
                end

                pt.timer:callDelayed(1., thistype.periodic, pt)
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            if BardSong[self.pid] ~= 0 then
                local pt = TimerList[self.pid]:add()

                pt.x = self.targetX
                pt.y = self.targetY
                pt.song = BardSong[self.pid]
                pt.tag = thistype.id --important for aura check
                pt.aoe = self.aoe * LBOOST[self.pid]
                pt.dmg = self.dmg
                pt.dur = self.dur * LBOOST[self.pid]
                pt.target = self.caster
                pt.source = GetDummy(pt.x, pt.y, 0, 0, pt.dur)

                SetUnitScale(pt.source, 3., 3., 3.)
                SetUnitOwner(pt.source, Player(PLAYER_TOWN), true)

                --the order matters here
                UnitAddAbility(pt.source, BardSong[self.pid])
                SaveInteger(MiscHash, GetHandleId(pt.source), FourCC('dspl'), BardSong[self.pid])

                --auras for allies
                if BardSong[self.pid] ~= SONG_FATIGUE then
                    BlzSetAbilityRealLevelField(BlzGetUnitAbility(pt.source, BardSong[self.pid]), ABILITY_RLF_AREA_OF_EFFECT, 0, pt.aoe)
                    IncUnitAbilityLevel(pt.source, BardSong[self.pid])
                    DecUnitAbilityLevel(pt.source, BardSong[self.pid])
                end

                if BardSong[self.pid] == SONG_WAR then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingRed.mdx", pt.source, "origin")
                elseif BardSong[self.pid] == SONG_HARMONY then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingGreen.mdx", pt.source, "origin")
                elseif BardSong[self.pid] == SONG_PEACE then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingYellow.mdx", pt.source, "origin")
                elseif BardSong[self.pid] == SONG_FATIGUE then
                    pt.sfx = AddSpecialEffectTarget("war3mapImported\\QuestMarkingPurple.mdx", pt.source, "origin")
                end

                BlzSetSpecialEffectScale(pt.sfx, 4.5)

                pt.timer:callDelayed(1., thistype.periodic, pt)
            end
        end
    end

    ---@class INSPIRE : Spell
    INSPIRE = {}
    do
        local thistype = INSPIRE
        thistype.id = FourCC("A09Y") ---@type integer 

        function thistype:onCast()
            InspireBuff:add(self.caster, self.caster):duration(99999.)

            InspireActive[self.pid] = true
        end
    end

    ---@class TONEOFDEATH : Spell
    ---@field aoe number
    ---@field dmg function
    ---@field dur number
    TONEOFDEATH = {}
    do
        local thistype = TONEOFDEATH
        thistype.id = FourCC("A02K") ---@type integer 

        thistype.aoe = 350. ---@type number
        thistype.dmg = function(pid) return (0.5 + 0.5 * ablev) * GetHeroInt(Hero[pid], true) end ---@return number
        thistype.dur = 5. ---@type number
        thistype.values = {thistype.aoe, thistype.dmg, thistype.dur}

        ---@type fun(pt: PlayerTimer)
        function thistype.periodic(pt)

            pt.count = pt.count + 1
            pt.dur = pt.dur - FPS_32

            if pt.dur > 0. then
                x = GetUnitX(pt.target) + 3 * Cos(pt.angle)
                y = GetUnitY(pt.target) + 3 * Sin(pt.angle)

                --blackhole movement
                SetUnitXBounded(pt.target, x)
                SetUnitYBounded(pt.target, y)

                local ug = CreateGroup()
                local target
                local rand = GetRandomReal(bj_PI // -9., bj_PI // 9.) ---@type number 

                MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), pt.aoe, Condition(FilterEnemy))

                local count = BlzGroupGetSize(ug)

                if count > 0 then
                    for index = 0, count - 1 do
                        target = BlzGroupUnitAt(ug, index)
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
                            UnitDamageTarget(Hero[pt.pid], target, pt.dmg * BOOST[pt.pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                        end
                    end
                end

                pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
            else
                pt:destroy()
            end

            DestroyGroup(ug)
        end

        function thistype:onCast()
            local pt = TimerList[self.pid]:add()  

            pt.angle = self.angle
            pt.target = GetDummy(x + 250 * Cos(pt.angle), y + 250 * Sin(pt.angle), 0, 0, 6.)
            pt.sfx = AddSpecialEffectTarget("war3mapImported\\BlackHoleSpell.mdx", pt.target, "origin")
            pt.aoe = self.aoe * LBOOST[self.pid]
            pt.dmg = self.dmg
            pt.dur = self.dur * LBOOST[self.pid]
            pt.count = 0
            SetUnitScale(pt.target, 0.5, 0.5, 0.5)

            pt.timer:callDelayed(FPS_32, thistype.periodic, pt)
        end
    end

    ---@type fun(pt: PlayerTimer)
    function BorrowedLifeAutocast(pt)
        local ug = CreateGroup()

        MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 1250., Condition(FilterHound))

        local target = FirstOfGroup(ug)

        if target then
            IssueTargetOrder(pt.target, "bloodlust", target)
        end

        DestroyGroup(ug)

        pt.timer:callDelayed(1., BorrowedLifeAutocast, pt)
    end

    ---@type fun(pt: PlayerTimer)
    function DevourAutocast(pt)
        local ug = CreateGroup()

        MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 1250., Condition(FilterHound))

        local target = FirstOfGroup(ug)

        if target then
            IssueTargetOrder(pt.target, "faeriefire", target)
        end

        DestroyGroup(ug)

        pt.timer:callDelayed(1., DevourAutocast, pt)
    end

    ---@type fun(pt: PlayerTimer)
    function AzazothBladeStorm(pt)
        pt.dur = pt.dur - 0.05 --tick rate

        if pt.dur > 0. then
            --spawn effect
            local target = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0, 0, 0.75)
            BlzSetUnitSkin(target, FourCC('h00D'))
            SetUnitTimeScale(target, GetRandomReal(0.8, 1.1))
            SetUnitScale(target, 1.30, 1.30, 1.30)
            SetUnitAnimationByIndex(target, 0)
            SetUnitFlyHeight(target, GetRandomReal(50., 100.), 0)
            BlzSetUnitFacingEx(target, GetRandomReal(0, 359.))

            target = GetDummy(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0, 0, 0.75)
            BlzSetUnitSkin(target, FourCC('h00D'))
            SetUnitTimeScale(target, GetRandomReal(0.8, 1.1))
            SetUnitScale(target, 0.7, 0.7, 0.7)
            SetUnitAnimationByIndex(target, 0)
            SetUnitFlyHeight(target, GetRandomReal(50., 100.), 0)
            BlzSetUnitFacingEx(target, GetRandomReal(0, 359.))

            if pt.dur < 4.85 and ModuloReal(pt.dur, 0.25) < 0.05 then --do damage every 0.25 second
                local ug = CreateGroup()

                MakeGroupInRange(pid, ug, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 300., Condition(FilterEnemy))

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    DestroyEffect(AddSpecialEffectTarget("Objects\\Spawnmodels\\Critters\\Albatross\\CritterBloodAlbatross.mdl", target, "chest"))
                    UnitDamageTarget(Hero[pid], target, (UnitGetBonus(Hero[pid], BONUS_DAMAGE) + GetHeroStr(Hero[pid], true)) * 0.25 * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end
            end

            pt.timer:callDelayed(0.05, AzazothBladeStorm, pt)
        else
            pt:destroy()
        end

        DestroyGroup(ug)
    end

    ---@type fun(pid: integer)
    function InstillFearExpire(pid)
        InstillFear[pid] = nil
    end

    ---@type fun(pid: integer)
    function MagneticForceCD(pid)
        magneticForceFlag[pid] = false
    end

    ---@type fun(pid: integer)
    function MagneticForcePull(pid)
        if magneticForceFlag[pid] then
            local ug = CreateGroup()
            local angle ---@type number 

            MakeGroupInRange(pid, ug, GetUnitX(meatgolem[pid]), GetUnitY(meatgolem[pid]), 600. * LBOOST[pid], Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                angle = Atan2(GetUnitY(meatgolem[pid]) - GetUnitY(target), GetUnitX(meatgolem[pid]) - GetUnitX(target))
                if GetUnitMoveSpeed(target) > 0 and IsTerrainWalkable(GetUnitX(target) + (7. * Cos(angle)), GetUnitY(target) + (7. * Sin(angle))) then
                    SetUnitXBounded(target, GetUnitX(target) + (7. * Cos(angle)))
                    SetUnitYBounded(target, GetUnitY(target) + (7. * Sin(angle)))
                end
                target = FirstOfGroup(ug)
            end

            TimerQueue:callDelayed(0.05, MagneticForcePull, pid)

            DestroyGroup(ug)
        end
    end

    ---@type fun(time: integer)
    function SpiritCallPeriodic(time)
        local ug       = CreateGroup()
        local ug2       = CreateGroup()
        local target ---@type unit 
        local u ---@type unit 
        local scs ---@type SpiritCallSlow 

        time = time - 1

        GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Boss, Condition(isspirit))

        if time >= 0 then
            target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                if GetRandomInt(0, 99) < 25 then
                    GroupEnumUnitsInRect(ug2, gg_rct_Naga_Dungeon_Boss, Condition(isplayerunit))
                    u = BlzGroupUnitAt(ug2, GetRandomInt(0, BlzGroupGetSize(ug2) - 1))
                    IssuePointOrder(target, "move", GetUnitX(u), GetUnitY(u))
                end
                GroupEnumUnitsInRange(ug2, GetUnitX(target), GetUnitY(target), 300., Condition(isplayerunit))
                u = FirstOfGroup(ug2)
                while u do
                    GroupRemoveUnit(ug2, u)
                    bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), FourCC('A09R'), 1, DUMMY_RECYCLE_TIME)
                    BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(u) - GetUnitY(target), GetUnitX(u) - GetUnitX(target)))
                    InstantAttack(bj_lastCreatedUnit, u)
                    UnitDamageTarget(target, u, BlzGetUnitMaxHP(u) * 0.1, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    if UnitAlive(u) then
                        scs = SpiritCallSlow:add(u, u)
                        scs:duration(5.)
                    end
                    u = FirstOfGroup(ug2)
                end
                target = FirstOfGroup(ug)
            end
            TimerQueue:callDelayed(1., SpiritCallPeriodic, time)
        else
            target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                SetUnitVertexColor(target, 100, 255, 100, 255)
                SetUnitScale(target, 1, 1, 1)
                IssuePointOrder(target, "move", GetRandomReal(GetRectMinX(gg_rct_Naga_Dungeon_Boss_Vision), GetRectMaxX(gg_rct_Naga_Dungeon_Boss_Vision)), GetRandomReal(GetRectMinY(gg_rct_Naga_Dungeon_Boss_Vision), GetRectMaxY(gg_rct_Naga_Dungeon_Boss_Vision)))
                target = FirstOfGroup(ug)
            end
        end

        DestroyGroup(ug)
        DestroyGroup(ug2)
    end

    function SpiritCall()
        local ug       = CreateGroup()

        GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon_Boss, Condition(isspirit))

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            SetUnitVertexColor(target, 255, 25, 25, 255)
            SetUnitScale(target, 1.25, 1.25, 1.25)
            target = FirstOfGroup(ug)
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

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            UnitDamageTarget(nagaboss, target, BlzGetUnitMaxHP(target) * GetRandomReal(0.75, 1), true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    end

    function NagaCollapse()
        local dummy ---@type unit 

        for i = 0, 9 do
            dummy = GetDummy(GetRandomReal(GetRectMinX(gg_rct_Naga_Dungeon_Boss), GetRectMaxX(gg_rct_Naga_Dungeon_Boss)), GetRandomReal(GetRectMinY(gg_rct_Naga_Dungeon_Boss), GetRectMaxY(gg_rct_Naga_Dungeon_Boss)), 0, 0, 4.)
            BlzSetUnitFacingEx(dummy, 270.)
            BlzSetUnitSkin(dummy, FourCC('e01F'))
            SetUnitScale(dummy, 10., 10., 10.)
            SetUnitVertexColor(dummy, 0, 255, 255, 255)
            TimerQueue:callDelayed(3., CollapseExpire, GetUnitX(dummy), GetUnitY(dummy))
        end
    end

    function NagaWaterStrike()
        local ug       = CreateGroup()
        local dummy ---@type unit 

        if UnitAlive(nagaboss) then
            MakeGroupInRect(FOE_ID, ug, gg_rct_Naga_Dungeon_Boss, Condition(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                dummy = CreateUnit(pfoe, FourCC('h003'), GetUnitX(nagaboss), GetUnitY(nagaboss), 0)
                IssueTargetOrder(dummy, "smart", target)
                target = FirstOfGroup(ug)
            end
        else
            nagawaterstrikecd = false
        end

        DestroyGroup(ug)
    end

    ---@type fun(caster: unit, time: integer)
    function NagaMiasmaDamage(caster, time)
        time = time - 1

        if time > 0 then
            local ug = CreateGroup()

            GroupEnumUnitsInRect(ug, gg_rct_Naga_Dungeon, Condition(isplayerunit))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                if ModuloInteger(num,2) == 0 then
                    TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Units\\Undead\\PlagueCloud\\PlagueCloudtarget.mdl", target, "overhead"))
                end
                UnitDamageTarget(caster, target, 25000 + BlzGetUnitMaxHP(target) * 0.03, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
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
            NagaThorns:add(u, u):duration(6.5)
        end
    end

    ---@type fun(pid: integer)
    function ResetCD(pid)
        UnitResetCooldown(Hero[pid])
        UnitResetCooldown(Backpack[pid])
    end

    ---@type fun(pt: PlayerTimer)
    function GaiaArmorPush(pt)
        local angle      = 0. ---@type number 
        local x      = 0. ---@type number 
        local y      = 0. ---@type number 
        local ug       = CreateGroup()

        BlzGroupAddGroupFast(pt.ug, ug)

        pt.dur = pt.dur - 1

        if pt.dur > 0. then
            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                x = GetUnitX(target)
                y = GetUnitY(target)
                angle = Atan2(y - GetUnitY(Hero[pt.pid]), x - GetUnitX(Hero[pt.pid]))
                if IsTerrainWalkable(x + pt.speed * Cos(angle), y + pt.speed * Sin(angle)) then
                    SetUnitXBounded(target, x + pt.speed * Cos(angle))
                    SetUnitYBounded(target, y + pt.speed * Sin(angle))
                end
                target = FirstOfGroup(ug)
            end
        else
            pt:destroy()
        end

        DestroyGroup(ug)
    end

    ---@type fun(pid: integer)
    function GaiaArmorCD(pid)
        if HeroID[pid] == HERO_ELEMENTALIST then
            aoteCD[pid] = true
            UnitAddAbility(Hero[pid], FourCC('A033'))
            BlzUnitHideAbility(Hero[pid], FourCC('A033'), true)
        end
    end

    ---@type fun(pt: PlayerTimer)
    function AstralDevastation(pt)
        local i         = 1 ---@type integer 
        local i2         = 0 ---@type integer 
        local ug       = CreateGroup()
        local target ---@type unit 
        local playerBonus         = 0 ---@type integer 
        local x      = 0. ---@type number 
        local y      = 0. ---@type number 

        pt.time = pt.time + 1

        if pt.time < 4 then --azazoth cast
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", pt.source, "origin"))
            pt.timer:callDelayed(pt.dur, AstralDevastation, pt)
        else
            if pt.pid ~= BOSS_ID then
                playerBonus = 20
            else
                PauseUnit(pt.source, false)
            end

            while i <= 8 do
                i2 = -1
                while i2 <= 1 do
                    x = GetUnitX(pt.source) + (150 * i) * Cos(bj_DEGTORAD * (pt.angle + 40 * i2))
                    y = GetUnitY(pt.source) + (150 * i) * Sin(bj_DEGTORAD * (pt.angle + 40 * i2))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", x, y))
                    if i2 == 0 and playerBonus > 0 then
                        GroupEnumUnitsInRangeEx(pt.pid, ug, x, y, 130. + playerBonus, Condition(FilterEnemy))
                        playerBonus = playerBonus + 40
                    else
                        GroupEnumUnitsInRangeEx(pt.pid, ug, x, y, 130., Condition(FilterEnemy))
                    end
                    i2 = i2 + 1
                end
                i = i + 1
            end

            while true do
                target = FirstOfGroup(ug)
                if target == nil then break end
                GroupRemoveUnit(ug, target)
                UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end

            pt:destroy()
        end

        DestroyGroup(ug)
    end

    ---@type fun(pt: PlayerTimer)
    function AstralAnnihilation(pt)
        pt.time = pt.time + 1

        if pt.time < 4 then --azazoth cast
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", pt.source, "origin"))
        else
            local x = GetUnitX(pt.source)
            local y = GetUnitY(pt.source)

            for i = 1, 9 do
                for j = 0, 11 do
                    local angle = 2 * bj_PI * i / 12.
                    DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x + 100 * j * Cos(angle), y + 100 * j * Sin(angle)))
                end
            end

            local ug = CreateGroup()
            MakeGroupInRange(pt.pid, ug, x, y, 900., Filter(FilterEnemy))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            pt:destroy()
        end

        DestroyGroup(ug)
    end

    ---@type fun(pt: PlayerTimer)
    function MassTeleportFinish(pt)
        isteleporting[pt.pid] = false
        BlzPauseUnitEx(Backpack[pt.pid], false)

        if UnitAlive(Hero[pt.pid]) and getRect(GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid])) == getRect(pt.x, pt.y) then
            SetUnitPosition(Hero[pt.pid], pt.x, pt.y)
            SetUnitPosition(Backpack[pt.pid], pt.x, pt.y)
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTarget.mdl", GetUnitX(Hero[pt.pid]), GetUnitY(Hero[pt.pid])))
        end

        pt:destroy()
    end

    ---@type fun(pid: integer, u: unit, dur: number)
    function MassTeleport(pid, u, dur)
        local pt = TimerList[pid]:add()  

        isteleporting[pid] = true
        BlzPauseUnitEx(Backpack[pid], true)
        --call DummyCastTarget(p, u, FourCC('A01R'), ablev, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), "massteleport")
        TimerQueue:callDelayed(dur, DestroyEffect, AddSpecialEffect("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportTo.mdl", GetUnitX(u), GetUnitY(u)))
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Backpack[pid], "origin"))
        pt.x = GetUnitX(u)
        pt.y = GetUnitY(u)
        pt.timer:callDelayed(dur, MassTeleportFinish, pt)
    end

    ---@type fun(pt: PlayerTimer)
    function TeleportHomePeriodic(pt)
        pt.dur = pt.dur - 0.05

        BlzSetSpecialEffectTime(pt.sfx, math.max(0, 1. - pt.dur / pt.agi))

        if pt.dur < 0 then
            UnitRemoveAbility(Hero[pt.pid],FourCC('A050'))
            PauseUnit(Hero[pt.pid],false)
            PauseUnit(Backpack[pt.pid],false)

            if UnitAlive(Hero[pt.pid]) then
                SetUnitPositionLoc(Hero[pt.pid], TownCenter)
                SetCameraBoundsRectForPlayerEx(Player(pt.pid - 1), MAIN_MAP.rect)
                PanCameraToTimedLocForPlayer(Player(pt.pid - 1), TownCenter, 0)
            end

            BlzSetSpecialEffectTimeScale(pt.sfx, 5.)
            BlzPlaySpecialEffect(pt.sfx, ANIM_TYPE_DEATH)
            pt:destroy()
        end

        isteleporting[pt.pid] = false
    end

    ---@param p player
    ---@param dur integer
    function TeleportHome(p, dur)
        local pid         = GetPlayerId(p) + 1 ---@type integer 
        local pt             = TimerList[pid]:add()  

        isteleporting[pid] = true

        PauseUnit(Backpack[pid], true)
        PauseUnit(Hero[pid], true)
        UnitAddAbility(Hero[pid], FourCC('A050'))
        BlzUnitHideAbility(Hero[pid], FourCC('A050'), true)

        pt.dur = dur
        pt.agi = dur
        pt.sfx = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 125.0)

        BlzSetSpecialEffectZ(pt.sfx, 500.0)
        BlzSetSpecialEffectTimeScale(pt.sfx, 0.001)
        BlzSetSpecialEffectColorByPlayer(pt.sfx, Player(4))
        TimerQueue:callDelayed(dur, DestroyEffect, pt.sfx)
        pt.timer:callDelayed(0.05, TeleportHomePeriodic, pt)
    end

    ---@param boss unit
    ---@param baseDamage integer
    ---@param effectability integer
    ---@param AOE number
    function BossBlastTaper(boss, baseDamage, effectability, AOE)
        local castx      = GetUnitX(boss) ---@type number 
        local casty      = GetUnitY(boss) ---@type number 
        local dx      = 0. ---@type number 
        local dy      = 0. ---@type number 
        local g       = CreateGroup()
        local target ---@type unit 
        local angle ---@type number 
        local distance ---@type number 
        local i         =1 ---@type integer 

        while i <= 18 do
            angle= bj_PI *i /9.
            target = GetDummy(castx, casty, effectability, 1, DUMMY_RECYCLE_TIME)
            SetUnitFlyHeight(target, 150., 0)
            IssuePointOrder(target, "breathoffire", castx + 40 * Cos(angle), casty + 40 * Sin(angle))
            i = i + 1
        end
        GroupEnumUnitsInRange(g, castx, casty, AOE, Condition(ishostileEnemy))
        while true do
            target = FirstOfGroup(g)
            if target == nil then break end
            GroupRemoveUnit(g, target)
            --call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
            dx= GetUnitX(target) -castx
            dy= GetUnitY(target) -casty
            distance= SquareRoot(dx * dx +dy * dy)
            if distance<150 then
                UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,MAGIC,WEAPON_TYPE_WHOKNOWS)
            else
                UnitDamageTarget(boss,target, baseDamage /(distance/200.), true, false,ATTACK_TYPE_NORMAL,MAGIC,WEAPON_TYPE_WHOKNOWS)
            end
        end

        DestroyGroup(g)
        PauseUnit(boss,false)
    end

    ---@param boss unit
    ---@param baseDamage integer
    ---@param hgroup integer
    ---@param speffect string
    function BossPlusSpell(boss, baseDamage, hgroup, speffect)
        local castx      = GetUnitX(boss) ---@type number 
        local casty      = GetUnitY(boss) ---@type number 
        local dx ---@type number 
        local dy ---@type number 
        local i         = -8 ---@type integer 
        local g      = CreateGroup()
        local target ---@type unit 

        if UnitAlive(boss) then
            while i <= 8 do
                DestroyEffect(AddSpecialEffect(speffect, castx +80 * i, casty-75))
                DestroyEffect(AddSpecialEffect(speffect, castx +80 * i, casty + 75))
                DestroyEffect(AddSpecialEffect(speffect, castx-75, casty +80 * i))
                DestroyEffect(AddSpecialEffect(speffect, castx + 75, casty +80 * i))
                i = i + 1
            end
            GroupEnumUnitsInRange(g, castx, casty, 750, Condition(ishostileEnemy))
            while true do
                target = FirstOfGroup(g)
                if target == nil then break end
                GroupRemoveUnit(g, target)
                --call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
                dx = RAbsBJ(GetUnitX(target)- castx)
                dy = RAbsBJ(GetUnitY(target)- casty)
                if dx<150 and dy<700 then
                    UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                elseif dx<700 and dy<150 then
                    UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                end
            end
        end

        DestroyGroup(g)
    end

    ---@param boss unit
    ---@param baseDamage integer
    ---@param hgroup integer
    ---@param speffect string
    function BossXSpell(boss, baseDamage, hgroup, speffect)
        local castx      = GetUnitX(boss) ---@type number 
        local casty      = GetUnitY(boss) ---@type number 
        local dx ---@type number 
        local dy ---@type number 
        local i         = -8 ---@type integer 
        local g      = CreateGroup()
        local target ---@type unit 

        if UnitAlive(boss) then
            while i <= 8 do
                    DestroyEffect(AddSpecialEffect(speffect, castx +75 * i, casty +75 * i))
                    DestroyEffect(AddSpecialEffect(speffect, castx +75 * i, casty -75 * i))
                i = i + 1
            end
            GroupEnumUnitsInRange(g, castx, casty, 750, Condition(ishostileEnemy))
            while true do
                target = FirstOfGroup(g)
                if target == nil then break end
                GroupRemoveUnit(g, target)
                dx = RAbsBJ(GetUnitX(target)- castx)
                dy = RAbsBJ(GetUnitY(target)- casty)
                if RAbsBJ(dx -dy) <200 then
                    UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                end
            end
        end

        DestroyGroup(g)
    end

    ---@param boss unit
    ---@param baseDamage integer
    ---@param hgroup integer
    ---@param AOE number
    ---@param speffect string
    function BossInnerRing(boss, baseDamage, hgroup, AOE, speffect)
        local castx ---@type number 
        local casty ---@type number 
        local g ---@type group 
        local target ---@type unit 
        local angle ---@type number 
        local i         =0 ---@type integer 

        castx = GetUnitX(boss)
        casty = GetUnitY(boss)
        g= CreateGroup()
        while i <= 6 do
            angle= bj_PI *i /3.
            DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.4 * Cos(angle), casty +AOE*.4 * Sin(angle)))
            DestroyEffect(AddSpecialEffect(speffect, castx +AOE*.8 * Cos(angle), casty +AOE*.8 * Sin(angle)))
            i = i + 1
        end
        GroupEnumUnitsInRange(g, castx, casty, AOE, Condition(ishostileEnemy))
        while true do
            target = FirstOfGroup(g)
            if target == nil then break end
            GroupRemoveUnit(g, target)
            --call DestroyEffect(AddSpecialEffect("Abilities\\Weapons\\LordofFlameMissile\\LordofFlameMissile.mdl", GetUnitX(target), GetUnitY(target)))
            UnitDamageTarget(boss,target, baseDamage, true, false,ATTACK_TYPE_NORMAL,MAGIC,WEAPON_TYPE_WHOKNOWS)
        end

        DestroyGroup(g)
    end

    ---@param boss unit
    ---@param baseDamage integer
    ---@param hgroup integer
    ---@param innerRadius number
    ---@param outerRadius number
    ---@param speffect string
    function BossOuterRing(boss, baseDamage, hgroup, innerRadius, outerRadius, speffect)
        local castx      = GetUnitX(boss) ---@type number 
        local casty      = GetUnitY(boss) ---@type number 
        local dx      = 0. ---@type number 
        local dy      = 0. ---@type number 
        local ug       = CreateGroup()
        local target      = nil ---@type unit 
        local angle      = 0. ---@type number 
        local distance      = outerRadius - innerRadius ---@type number 
        local i         = 0 ---@type integer 

        while i <= 10 do
            angle = bj_PI * i / 5.
            DestroyEffect(AddSpecialEffect(speffect, castx + (innerRadius + distance / 6.) * Cos(angle), casty + (innerRadius + distance / 6.) * Sin(angle)))
            DestroyEffect(AddSpecialEffect(speffect, castx + (outerRadius - distance / 6.) * Cos(angle), casty + (outerRadius - distance / 6.) * Sin(angle)))
            i = i + 1
        end

        GroupEnumUnitsInRange(ug, castx, casty, outerRadius, Condition(ishostileEnemy))
        while true do
            target = FirstOfGroup(ug)
            if target == nil then break end
            GroupRemoveUnit(ug, target)
            dx = GetUnitX(target) - castx
            dy = GetUnitY(target) - casty
            distance = SquareRoot(dx * dx + dy * dy)
            if distance > innerRadius then
                UnitDamageTarget(boss, target, baseDamage, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end
        end

        DestroyGroup(ug)
    end

    ---@return boolean
    function HeroPanelClick()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid] ---@type DialogWindow 
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 
        local i     = pid * PLAYER_CAP + dw.data[index] ---@type integer 

        if index ~= -1 then
            hero_panel_on[i] = (not hero_panel_on[i])
            ShowHeroPanel(GetTriggerPlayer(), Player(dw.data[index] - 1), hero_panel_on[i])

            dw:destroy()
        end

        return false
    end

    ---@param pid integer
    function DisplayHeroPanel(pid)
        local dw = DialogWindow.create(pid, "", HeroPanelClick) ---@type DialogWindow 
        local U  = User.first ---@type User 

        while U do
            if pid ~= U.id and HeroID[U.id] ~= 0 then
                dw.data[dw.ButtonCount] = U.id
                dw:addButton(U.nameColored)
            end

            U = U.next
        end

        dw:display()
    end

    --Runs upon selecting a backpack
    ---@return boolean
    function BackpackSkinClick()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid] ---@type DialogWindow 
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        if index ~= -1 then
            if CosmeticTable[name][index] == 0 then
                DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, CosmeticTable.skins[index].error)
            else
                Profile[pid]:skin(dw.data[index])
            end

            dw:destroy()
        end

        return false
    end

    --Displays backpack selection dialog
    ---@param p player
    function BackpackSkin(p)
        local pid  = GetPlayerId(p) + 1 ---@type integer 
        local name = User[p].name
        local dw   = DialogWindow.create(pid, "Select Appearance", BackpackSkinClick) ---@type DialogWindow 

        for i, v in ipairs(CosmeticTable.skins) do
            if CosmeticTable[name][i] > 0 or v.public then
                dw.data[dw.ButtonCount] = i
                dw:addButton(v.name)
            end
        end

        dw:display()
    end

    --Runs upon selecting a cosmetic
    ---@return boolean
    function CosmeticButtonClick()
        local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        local dw    = DialogWindow[pid] ---@type DialogWindow 
        local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

        if index ~= -1 then
            CosmeticTable.cosmetics[dw.data[index]]:effect(pid)

            dw:destroy()
        end

        return false
    end

    --Displays cosmetic selection dialog
    ---@param p player
    function DisplaySpecialEffects(p)
        local pid  = GetPlayerId(p) + 1 ---@type integer 
        local name = User[p].name
        local dw   = DialogWindow.create(pid, "", CosmeticButtonClick) ---@type DialogWindow 

        for i, v in ipairs(CosmeticTable.cosmetics) do
            if CosmeticTable[name][i + DONATOR_AURA_OFFSET] > 0 then
                dw.data[dw.ButtonCount] = i
                dw:addButton(v.name)
            end
        end

        dw:display()
    end

    ---@type fun(pt: PlayerTimer)
    function NerveGas(pt)
        pt.dur = pt.dur - 1

        if pt.dur < 0 then
            pt:destroy()
        else
            local count = BlzGroupGetSize(pt.ug) ---@type integer 

            if count > 0 then
                for index = 0, count - 1 do
                    local target = BlzGroupUnitAt(pt.ug, index)
                    if UnitAlive(target) and GetUnitAbilityLevel(target, FourCC('Avul')) == 0 then
                        UnitDamageTarget(Hero[pt.pid], target, pt.dmg / pt.armor, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    end
                end
            end
            pt.timer:callDelayed(0.5, NerveGas, pt)
        end
    end

    function OnCast()
        local caster  = GetTriggerUnit() ---@type unit 
        local target  = GetSpellTargetUnit() ---@type unit 
        local sid     = GetSpellAbilityId() ---@type integer 
        local p       = GetOwningPlayer(caster) ---@type player 
        local pid     = GetPlayerId(p) + 1 ---@type integer 
        local tpid    = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 
        local x       = GetUnitX(caster) ---@type number 
        local y       = GetUnitY(caster) ---@type number 
        local targetX = GetSpellTargetX() ---@type number 
        local targetY = GetSpellTargetY() ---@type number 

        if caster == Hero[pid] then
            Moving[pid] = false
        end

        if sid == FourCC('AImt') or sid == FourCC('A02J') or sid == FourCC('A018') then --God Blink / Backpack Teleport
            if UnitAlive(Hero[pid]) == false then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while dead.")
            elseif sid == FourCC('A018') and ChaosMode then
                IssueImmediateOrder(caster, "stop")
                DisplayTimedTextToPlayer(p, 0, 0, 20.00, "With the Gods dead, these items no longer have the ability to move around the map with free will. Their powers are dead, however their innate fighting powers are left unscathed.")
            elseif getRect(x, y) ~= MAIN_MAP.rect then
                IssueImmediateOrder(caster, "stop")
                DisplayTimedTextToPlayer(p, 0, 0, 5., "Unable to teleport there.")
            elseif getRect(x, y) ~= getRect(targetX, targetY) then
                IssueImmediateOrder(caster, "stop")
                DisplayTimedTextToPlayer(p, 0, 0, 5., "Unable to teleport there.")
            elseif TableHas(QUEUE_GROUP, p) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while queueing for a dungeon.")
            elseif TableHas(NAGA_GROUP, p) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while in a dungeon.")
            end
        elseif sid == FourCC('A01S') or sid == FourCC('A03D') or sid == FourCC('A061') then --Short blink
            if getRect(x, y) ~= getRect(targetX, targetY) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport there.")
            end

        elseif sid == FourCC('A0FV') then --Teleport Home
            if UnitAlive(Hero[pid]) == false then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while dead.")
            elseif TableHas(QUEUE_GROUP, p) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while queueing for a dungeon.")
            elseif TableHas(NAGA_GROUP, p) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while in a dungeon.")
            elseif TableHas(AZAZOTH_GROUP, p) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport out of here.")
            elseif getRect(x, y) == MAIN_MAP.rect or getRect(x, y) == gg_rct_Cave or getRect(x, y) == gg_rct_Gods_Vision or getRect(x, y) == gg_rct_Tavern then
            else
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport out of here.")
            end
        elseif sid == RESURRECTION.id then --Resurrection
            if target ~= HeroGrave[tpid] then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "You must target a tombstone!")
            elseif GetUnitAbilityLevel(HeroGrave[tpid], FourCC('A045')) > 0 then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "This player is already being revived!")
            end
        elseif sid == BLOODNOVA.id then --Blood Nova
            if BloodBank[pid] < BLOODNOVA.cost(pid) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "Not enough blood.")
            end
        --valid cast point
        elseif sid == WHIRLPOOL.id or sid == BLOODLEAP.id or sid == SPINDASH.id or sid == METEOR.id or sid == STEEDCHARGE.id or sid == BLINKSTRIKE.id or sid == PHOENIXFLIGHT.id then
            if (not IsTerrainWalkable(targetX, targetY) or getRect(targetX, targetY) ~= getRect(x, y)) and (targetX ~= 0 and targetY ~= 0) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, INVALID_TARGET_MESSAGE)
            end
        elseif sid == ARCANESHIFT.id then
            local pt = TimerList[pid]:get(ARCANESHIFT.id, caster)

            if not IsTerrainWalkable(targetX, targetY) then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, INVALID_TARGET_MESSAGE)
            elseif pt then
                if DistanceCoords(targetX, targetY, pt.x, pt.y) > 1500. then
                    IssueImmediateOrder(caster, "stop")
                    DisplayTextToPlayer(p, 0, 0, "|cffff0000Target point is too far away!")
                end
            end
        elseif sid == DEMONICSACRIFICE.id then
            if GetOwningPlayer(target) ~= p then
                IssueImmediateOrder(caster, "stop")
                DisplayTextToPlayer(p, 0, 0, "You must target your own summons!")
            end
        end
    end

    ---@return boolean
    function OnChannel()
        if GetSpellAbilityId() == FourCC('IATK') then
            UnitRemoveAbility(GetTriggerUnit(), FourCC('IATK'))
        end

        return false
    end

    ---@return boolean
    function OnLearn()
        local u      = GetTriggerUnit() ---@type unit 
        local sid    = GetLearnedSkill() ---@type integer 
        local pid    = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
        local ablev  = GetUnitAbilityLevel(u, sid) ---@type integer 
        local i      = 0 ---@type integer 
        local abil   = BlzGetUnitAbilityByIndex(u, i) ---@type ability 

        --find ability
        while abil and BlzGetAbilityId(abil) ~= sid do
            i = i + 1
            abil = BlzGetUnitAbilityByIndex(u, i)
        end

        --store original tooltip
        SpellTooltips[sid][ablev] = BlzGetAbilityStringLevelField(abil, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, ablev - 1)

        --remove bracket indicators
        UpdateSpellTooltips(pid)

        if sid == GAIAARMOR.id then --Gaia Armor
            if ablev == 1 then
                UnitAddAbility(u, FourCC('A033'))
                BlzUnitHideAbility(u, FourCC('A033'), true)
                aoteCD[pid] = true
            end
        elseif sid == ADAPTIVESTRIKE.id then --adaptive strike
            if ablev == 1 then
                UnitDisableAbility(u, sid, true)
                BlzUnitHideAbility(u, sid, false)
            end
        elseif sid == LIMITBREAK.id then --limit break
            limitBreakPoints[pid] = limitBreakPoints[pid] + 1
            if GetLocalPlayer() == GetOwningPlayer(u) then
                BlzFrameSetVisible(LimitBreakBackdrop, true)
            end
        elseif sid == WINDSCAR.id then --wind scar
            if limitBreak[pid] & 0x8 > 0 then
                BlzSetAbilityIntegerLevelField(BlzGetUnitAbility(Hero[pid], WINDSCAR.id), ABILITY_ILF_TARGET_TYPE, ablev - 1, 0)
            end
        end

        return false
    end

    function OnFinish()
        local caster      = GetTriggerUnit() ---@type unit 
        local sid         = GetSpellAbilityId() ---@type integer 
        local p        = GetOwningPlayer(caster) ---@type player 
        local ablev         = GetUnitAbilityLevel(caster, sid) ---@type integer 

        if sid == FourCC('A0FV') then --Teleport Town
            if ablev > 1 then
                TeleportHome(p, 11 - ablev)
            else
                TeleportHome(p, 12)
            end
        end
    end

    function EnemySpells()
        local caster      = GetTriggerUnit() ---@type unit 
        local sid         = GetSpellAbilityId() ---@type integer 

        if sid == FourCC('A04K') then --naga dungeon thorns
            FloatingTextUnit("Thorns", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            TimerQueue:callDelayed(2., ApplyNagaThorns, caster)
            TimerQueue:callDelayed(8.5, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Orc\\SpikeBarrier\\SpikeBarrier.mdl", caster, "origin"))
        elseif sid == FourCC('A04R') then --naga dungeon swarm beetle
            FloatingTextUnit("Swarm", caster, 2, 50, 0, 13.5, 155, 255, 255, 0, true)
            local ug = CreateGroup()
            GroupEnumUnitsInRange(ug, GetUnitX(caster), GetUnitY(caster), 1250., Condition(isplayerunit))

            local target = FirstOfGroup(ug)
            local count = 0
            local rand = GetRandomInt(0, 359)
            while target do
                if GetRandomReal(0, 1.) <= 0.75 then
                    GroupRemoveUnit(ug, target)
                end
                local beetle = CreateUnit(GetOwningPlayer(caster), FourCC('u002'), GetUnitX(caster) + GetRandomInt(125, 250) * Cos(bj_DEGTORAD * (rand + i * 30)), GetUnitY(caster) + GetRandomInt(125, 250) * Sin(bj_DEGTORAD * (rand + i * 30)), 0)
                BlzSetUnitFacingEx(beetle, bj_RADTODEG * Atan2(GetUnitY(target) - GetUnitY(beetle), GetUnitX(target) - GetUnitX(beetle)))
                PauseUnit(beetle, true)
                UnitAddAbility(beetle, FourCC('Avul'))
                SetUnitAnimation(beetle, "birth")
                TimerQueue:callDelayed(GetRandomReal(0.75, 1.), SwarmBeetle, beetle, target)
                count = count + 1
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        elseif sid == FourCC('A04V') then --naga atk speed
            FloatingTextUnit("Enrage", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            TimerQueue:callDelayed(2., ApplyNagaAtkSpeed, caster)
        elseif sid == FourCC('A04W') then --naga massive aoe
            FloatingTextUnit("Miasma", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            SetUnitAnimation(caster, "channel")
            TimerQueue:callDelayed(2., NagaMiasmaDamage, caster, 41)
            for i = 0, 3 do
                local sfx = AddSpecialEffect("Abilities\\Spells\\Undead\\PlagueCloud\\PlagueCloudCaster.mdl", GetUnitX(caster) + 175 * Cos(bj_PI * i / 2 + (bj_PI / 4.)), GetUnitY(caster) + 175 * Sin(bj_PI * i / 2 + (bj_PI / 4.)))
                BlzSetSpecialEffectScale(sfx, 2.)
                TimerQueue:callDelayed(21., DestroyEffect, sfx)
            end
        elseif sid == FourCC('A05C') then --naga wisp thing?
            FloatingTextUnit("Spirit Call", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            SpiritCall()
        elseif sid == FourCC('A05K') then --naga boss rock fall
            FloatingTextUnit("Collapse", caster, 2, 50, 0, 13.5, 255, 255, 125, 0, true)
            NagaCollapse()
        end
    end

    function OnEffect()
        local caster = GetTriggerUnit() ---@type unit 
        local target = GetSpellTargetUnit() ---@type unit 
        local p      = GetOwningPlayer(caster) ---@type player 
        local itm    = GetSpellTargetItem() ---@type item?
        local sid    = GetSpellAbilityId() ---@type integer 
        local pid    = GetPlayerId(p) + 1 ---@type integer 
        local tpid   = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 
        local ablev  = GetUnitAbilityLevel(caster, sid) ---@type integer 
        local x      = GetUnitX(caster) ---@type number 
        local y      = GetUnitY(caster) ---@type number 
        local dmg    = 0 ---@type number 
        local spell  = nil

        --store last cast spell id
        if sid ~= ADAPTIVESTRIKE.id and sid ~= LIMITBREAK.id then
            lastCast[pid] = sid
        end

        --create spell interface if exists
        if Spells[sid] then
            spell = Spells[sid]:create(pid)
            spell.sid = sid
            spell.tpid = tpid
            spell.caster = caster
            spell.target = target
            spell.ablev = ablev
            spell.x = x
            spell.y = y
            spell.targetX = GetSpellTargetX()
            spell.targetY = GetSpellTargetY()
            spell.angle = Atan2(spell.targetY - y, spell.targetX - x)

            spell:onCast()

        --========================
        --Actions
        --========================

        elseif sid == FourCC('A03V') then --Move Item (Hero)
            if ItemsDisabled[pid] == false then
                UnitRemoveItem(caster, itm)
                UnitAddItem(Backpack[pid], itm)
            end
        elseif sid == FourCC('A0L0') then --Hero Info
            StatsInfo(p, pid)
        elseif sid == FourCC('A0GD') then --Item Info
            ItemInfo(pid, Item[itm])
        elseif sid == FourCC('A06X') then --Quest Progress
            DisplayQuestProgress(p)
        elseif sid == FourCC('A08Y') then --Auto-attack Toggle
            ToggleAutoAttack(pid)
        elseif sid == FourCC('A00B') then --Movement Toggle
            ForceRemovePlayer(rightclicked, p)
            if IsPlayerInForce(p, rightclickactivator) then
                DisplayTextToPlayer(p, 0, 0, "Movement Toggle disabled.")
                ForceRemovePlayer(rightclickactivator, p)
            else
                DisplayTextToPlayer(p, 0, 0, "Movement Toggle enabled.")
                ForceAddPlayer(rightclickactivator, p)
            end

        --Hero Panels
        elseif sid == FourCC('A02T') then
            DisplayHeroPanel(pid)

        --Damage Numbers
        elseif sid == FourCC('A031') then
            if DMG_NUMBERS[pid] == 0 then
                DMG_NUMBERS[pid] = 1
                DisplayTextToPlayer(p, 0, 0, "Damage Numbers for allied damage received disabled.")
            elseif DMG_NUMBERS[pid] == 1 then
                DMG_NUMBERS[pid] = 2
                DisplayTextToPlayer(p, 0, 0, "Damage Numbers for all damage disabled.")
            else
                DMG_NUMBERS[pid] = 0
                DisplayTextToPlayer(p, 0, 0, "Damage Numbers enabled.")
            end
        elseif sid == FourCC('A067') then --Deselect Backpack
            if BP_DESELECT[pid] then
                BP_DESELECT[pid] = false
                DisplayTextToPlayer(p, 0, 0, "Deselect Backpack disabled.")
            else
                BP_DESELECT[pid] = true
                DisplayTextToPlayer(p, 0, 0, "Deselect Backpack enabled.")
            end

        --========================
        --Item Spells
        --========================

        elseif sid == FourCC('A083') then --Paladin Book
            local heal = 3 * GetHeroInt(caster, true) * BOOST[pid]
            if GetUnitTypeId(target) == BACKPACK then
                HP(Hero[tpid], heal)
            else
                HP(target, heal)
            end
        elseif sid == FourCC('A02A') then --Instill Fear
            if HasProficiency(pid, PROF_DAGGER) then
                DummyCastTarget(p, target, FourCC('A0AE'), 1, x, y, "firebolt")
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        elseif sid == FourCC('A055') then --Darkest of Darkness
            DarkestOfDarknessBuff:add(Hero[pid], Hero[pid]):duration(20.)
        elseif sid == FourCC('A0IS') then --Abyssal Bow
            dmg = (UnitGetBonus(caster,BONUS_DAMAGE) + GetHeroAgi(caster, true)) * 4 * BOOST[pid]
            if not HasProficiency(pid, PROF_BOW) then
                dmg= dmg * 0.5
            end
            UnitDamageTarget(caster, target, dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
        elseif sid == FourCC('A07G') then --Azazoth Sword (Bladestorm)
            if HasProficiency(pid, PROF_SWORD) then
                local pt = TimerList[pid]:add()
                pt.dur = 5.
                pt.timer:callDelayed(0.05, AzazothBladeStorm, pt)
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        elseif sid == FourCC('A0SX') then --Azazoth Staff
            if HasProficiency(pid, PROF_STAFF) then
                local pt = TimerList[pid]:add()
                pt.source = caster
                pt.dmg = 40 * GetHeroInt(caster, true) * BOOST[pid]
                pt.angle = bj_RADTODEG * Atan2(GetSpellTargetY() - y, GetSpellTargetX() - x)
                pt.time = 4

                pt.timer:callDelayed(0., AstralDevastation, pt)
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        elseif sid == FourCC('A0B5') then --Azazoth Hammer (Stomp)
            if HasProficiency(pid, PROF_HEAVY) then
                local ug = CreateGroup()
                MakeGroupInRange(pid, ug, x, y, 550.00, Condition(FilterEnemy))

                target = FirstOfGroup(ug)
                while target do
                    GroupRemoveUnit(ug, target)
                    AzazothHammerStomp:add(caster, target):duration(15.)
                    UnitDamageTarget(caster, target, 15.00 * GetHeroStr(caster, true) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                    target = FirstOfGroup(ug)
                end

                DestroyGroup(ug)
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        elseif sid == FourCC('A00E') then --final blast
            local ug = CreateGroup()
            MakeGroupInRange(pid, ug, x, y, 600.00, Condition(FilterEnemy))

            for i = 1, 12 do
                if i < 7 then
                    x = GetUnitX(caster) + 200 * Cos(60.00 * i * bj_DEGTORAD)
                    y = GetUnitY(caster) + 200 * Sin(60.00 * i * bj_DEGTORAD)
                    DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
                end
                x = GetUnitX(caster) + 400 * Cos(60.00 * i * bj_DEGTORAD)
                y = GetUnitY(caster) + 400 * Sin(60.00 * i * bj_DEGTORAD)
                DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
                x = GetUnitX(caster) + 600 * Cos(60.00 * i * bj_DEGTORAD)
                y = GetUnitY(caster) + 600 * Sin(60.00 * i * bj_DEGTORAD)
                DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
            end

            target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                UnitDamageTarget(caster, target, 10.00 * (GetHeroInt(caster, true) + GetHeroAgi(caster, true) + GetHeroStr(caster, true)) * BOOST[pid], true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)

        --========================
        --Backpack
        --========================

        elseif sid == FourCC('A0DT') then --Move Item (Backpack)
            if ItemsDisabled[pid] == false then
                UnitRemoveItem(caster, itm)
                UnitAddItem(Hero[pid], itm)
            end
        elseif sid == FourCC('A0KX') then --Change Skin
            BackpackSkin(p)
        elseif sid == FourCC('A04N') then --Special Effects
            DisplaySpecialEffects(p)
        elseif sid == FourCC('A02J') then --Mass Teleport
            if ablev > 1 then
                MassTeleport(pid, target, ablev, 3 - ablev * .25)
            else
                MassTeleport(pid, target, ablev, 3)
            end
        elseif sid == FourCC('A00R') then --Next Backpack Page
            for i = MAX_INVENTORY_SLOTS + 5, 12 do --iterate through hidden slots back to front
                Profile[pid].hero.items[i] = Profile[pid].hero.items[i - 6]
            end

            for i = 0, 5 do
                itm = UnitItemInSlot(Backpack[pid], i)
                UnitRemoveItem(Backpack[pid], itm)
                SetItemPosition(itm, 30000., 30000.)
                SetItemVisible(itm, false)
            end

            for i = 0, 5 do
                if Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i] then
                    itm = Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i].obj
                    SetItemVisible(itm, true)
                    UnitAddItem(Backpack[pid], itm)
                    UnitDropItemSlot(Backpack[pid], itm, i)
                    SetItemDroppable(itm, (not ItemsDisabled[pid]))
                    Profile[pid].hero.items[MAX_INVENTORY_SLOTS + i] = nil
                end
            end

        elseif sid == FourCC('A09C') then --Health Potion (Backpack)
            for i = 0, 5 do
                itm = UnitItemInSlot(caster, i)
                if GetItemTypeId(itm) == FourCC('I0BJ') then
                    HP(Hero[pid], 10000)
                    break
                elseif GetItemTypeId(itm) == FourCC('I028') then
                    HP(Hero[pid], 2000)
                    break
                elseif GetItemTypeId(itm) == FourCC('I062') then
                    HP(Hero[pid], 500)
                    break
                elseif GetItemTypeId(itm) == FourCC('I0MP') then
                    HP(Hero[pid], 50000 + BlzGetUnitMaxHP(Hero[pid]) * 0.08)
                    MP(Hero[pid], BlzGetUnitMaxMana(Hero[pid]) * 0.08)
                    break
                elseif GetItemTypeId(itm) == FourCC('I0MQ') then
                    HP(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * 0.15)
                    break
                end
            end

            if itm then
                if GetItemCharges(itm) < 2 then
                    Item[itm]:destroy()
                else
                    Item[itm]:charge(Item[itm].charges - 1)
                end
            else
                DisplayTextToPlayer(p, 0, 0, "You do not have a potion to consume.")
            end
        elseif sid == FourCC('A0FS') then --Mana Potion (Backpack)
            for i = 0, 5 do
                itm = UnitItemInSlot(caster, i)
                if GetItemTypeId(itm) == FourCC('I0BL') then
                    MP(Hero[pid], 10000)
                    break
                elseif GetItemTypeId(itm) == FourCC('I00D') then
                    MP(Hero[pid], 2000)
                    break
                elseif GetItemTypeId(itm) == FourCC('I06E') then
                    MP(Hero[pid], 500)
                    break
                elseif GetItemTypeId(itm) == FourCC('I0MP') then
                    HP(Hero[pid], 50000 + BlzGetUnitMaxHP(Hero[pid]) * 0.08)
                    MP(Hero[pid], BlzGetUnitMaxMana(Hero[pid]) * 0.08)
                    break
                elseif GetItemTypeId(itm) == FourCC('I0MQ') then
                    HP(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * 0.15)
                    break
                end

                itm = nil
            end

            if itm then
                if GetItemCharges(itm) < 2 then
                    Item[itm]:destroy()
                else
                    Item[itm]:charge(Item[itm].charges - 1)
                end
            else
                DisplayTextToPlayer(p, 0, 0, "You do not have a potion to consume.")
            end
        elseif sid == FourCC('A05N') then --Unique Consumable (Backpack)
            for i = 0, 5 do
                itm = UnitItemInSlot(caster, i)
                if GetItemTypeId(itm) == FourCC('I02K') then
                    VampiricPotion:add(Hero[pid], Hero[pid]):duration(10.)
                    break
                elseif GetItemTypeId(itm) == FourCC('I027') then
                    DummyCastTarget(p, Hero[pid], FourCC('A05P'), 1, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), "invisibility")
                    break
                end

                itm = nil
            end

            if itm then
                if GetItemCharges(itm) < 2 then
                    Item[itm]:destroy()
                else
                    Item[itm]:charge(Item[itm].charges - 1)
                end
            else
                DisplayTextToPlayer(p, 0, 0, "You do not have a consumable.")
            end

        --dark summoner summon spells

        --meat golem taunt
        elseif sid == FourCC('A0KI') then --meat golem taunt
            Taunt(caster, pid, 800., true, 2000, 0)

        --meat golem thunder clap
        elseif sid == FourCC('A0B0') then
            local ug = CreateGroup()
            MakeGroupInRange(pid, ug, x, y, 300., Condition(FilterEnemy))

            target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug,target)
                MeatGolemThunderClap:add(caster, target):duration(3.)
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)

        --meat golem devour
        elseif sid == FourCC('A06C') then
            if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p and golemDevourStacks[pid] < GetUnitAbilityLevel(Hero[pid], DEVOUR.id) + 1 then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", target, "chest"))
                bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), FourCC('A00W'), 1, DUMMY_RECYCLE_TIME)
                SetUnitOwner(bj_lastCreatedUnit, p, false)
                BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(caster) - GetUnitY(target),  GetUnitX(caster) - GetUnitX(target)))
                InstantAttack(bj_lastCreatedUnit, caster)
                SummonExpire(target)
            end

        --destroyer devour
        elseif sid == FourCC('A04Z') then
            if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p and destroyerDevourStacks[pid] < GetUnitAbilityLevel(Hero[pid], DEVOUR.id) + 1 then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\DeathCoil\\DeathCoilSpecialArt.mdl", target, "chest"))
                bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), FourCC('A00W'), 1, DUMMY_RECYCLE_TIME)
                SetUnitOwner(bj_lastCreatedUnit, p, false)
                BlzSetUnitFacingEx(bj_lastCreatedUnit, bj_RADTODEG * Atan2(GetUnitY(caster) - GetUnitY(target),  GetUnitX(caster) - GetUnitX(target)))
                InstantAttack(bj_lastCreatedUnit, caster)
                SummonExpire(target)
            end

        --meat golem magnetic force
        elseif sid == FourCC('A06O') then
            magneticForceFlag[pid] = true
            TimerQueue:callDelayed(0.05, MagneticForcePull, pid)
            TimerQueue:callDelayed(10., MagneticForceCD, pid)

        --borrowed life
        elseif sid == FourCC('A071') then
            if GetUnitTypeId(target) == SUMMON_HOUND and GetOwningPlayer(target) == p then
                DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", target, "chest"))
                SummonExpire(target)

                local time = 120

                if ablev > 1 then
                    time = time / ((ablev - 1) * 2) --60, 30, 20, 15
                end

                if GetUnitTypeId(caster) == SUMMON_GOLEM then
                    BorrowedLife[pid * 10] = time
                elseif GetUnitTypeId(caster) == SUMMON_DESTROYER then
                    BorrowedLife[pid * 10 + 1] = time
                end
            end

        --========================
        --Misc
        --========================

        --Free Dobby
        elseif sid == FourCC('A09G') then
            RemoveUnit(caster)
            DisplayTextToPlayer(p, 0, 0, "The worker has gone home to live out his life in peace.")

        --Castle of the Gods
        elseif sid == FourCC('A0A9') or sid == FourCC('A0A7') or sid == FourCC('A0A6') or sid == FourCC('S001') or sid == FourCC('A0A5') then
            if ChaosMode then
                IssueImmediateOrder(caster, "stop")
                DisplayTimedTextToPlayer(p, 0, 0, 10.00, "With the Gods dead, the Castle of Gods can no longer draw enough power from them in order to use its abilities.")
            end

        --Hero Selection UI
        elseif sid == FourCC('A0JI') then
            Scroll(p, -1)

        elseif sid == FourCC('A0JQ') then
            Scroll(p, 1)

        elseif sid == FourCC('A0JR') then
            hssort[pid] = true
            hsstat[pid] = 3
            Scroll(p, 1)

        elseif sid == FourCC('A0JS') then
            hssort[pid] = true
            hsstat[pid] = 1
            Scroll(p, 1)

        elseif sid == FourCC('A0JT') then
            hssort[pid] = true
            hsstat[pid] = 2
            Scroll(p, 1)

        --sort
        elseif sid == FourCC('A0JU') then
            hssort[pid] = false

        --pick hero
        elseif sid == HeroCircle[hslook[pid]].select then
            Selection(pid, HeroCircle[hslook[pid]].skin)

        --Grave Revive
        elseif sid == FourCC('A042') or sid == FourCC('A044') or sid == FourCC('A045') then
            if IsTerrainWalkable(GetSpellTargetX(), GetSpellTargetY()) then
                BlzSetSpecialEffectScale(HeroReviveIndicator[pid], 0)
                DestroyEffect(HeroReviveIndicator[pid])
                BlzSetSpecialEffectScale(HeroTimedLife[pid], 0)
                DestroyEffect(HeroTimedLife[pid])

                --item revival
                if sid == FourCC('A042') then
                    local itm2 = GetResurrectionItem(pid, false)
                    local heal = 0

                    if itm2 then
                        heal = ItemData[itm2.id][ITEM_ABILITY] * 0.01

                        itm2:charge(itm2.charges - 1)

                        --remove perishable resurrections
                        if ItemData[itm2.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') and itm2.charges <= 0 then
                            itm2:destroy()
                        end
                    end

                    RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), heal, heal)
                --pr reincarnation
                elseif sid == FourCC('A044') then
                    RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), 100, 100)

                    BlzStartUnitAbilityCooldown(Hero[pid], REINCARNATION.id, 300.)
                --high priestess revival
                elseif sid == FourCC('A045') then
                    local heal = 40 + 20 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], RESURRECTION.id)
                    RevivePlayer(pid, GetSpellTargetX(), GetSpellTargetY(), heal, heal)
                end

                --refund HP cooldown and mana
                if sid ~= FourCC('A045') and ResurrectionRevival[pid] > 0 then
                    BlzEndUnitAbilityCooldown(Hero[ResurrectionRevival[pid]], RESURRECTION.id)
                    SetUnitState(Hero[ResurrectionRevival[pid]], UNIT_STATE_MANA, BlzGetUnitMaxMana(Hero[ResurrectionRevival[pid]]) * 0.5)
                end

                ReincarnationRevival[pid] = false
                ResurrectionRevival[pid] = 0
                UnitRemoveAbility(HeroGrave[pid], FourCC('A042'))
                UnitRemoveAbility(HeroGrave[pid], FourCC('A044'))
                UnitRemoveAbility(HeroGrave[pid], FourCC('A045'))
                SetUnitPosition(HeroGrave[pid], 30000, 30000)
                ShowUnit(HeroGrave[pid], false)
            else
                DisplayTextToPlayer(p, 0, 0, INVALID_TARGET_MESSAGE)
            end
        --banish demon
        elseif sid == FourCC('A00Q') then
            itm = GetItemFromUnit(caster, FourCC('I0OU'))
            if ChaosMode then
                if target == BossTable[BOSS_LEGION].unit then
                    Item[itm]:destroy()
                    if BANISH_FLAG == false then
                        BANISH_FLAG = true
                        DisplayTimedTextToForce(FORCE_PLAYING, 30., "|cffffcc00Legion:|r Fool! Did you really think splashing water on me would do anything?")
                    end
                else
                    DisplayTimedTextToPlayer(p, 0., 0., 30., "Maybe you shouldn't waste this...")
                end
            else
                if target == BossTable[BOSS_DEATH_KNIGHT].unit then
                    Item[itm]:destroy()
                    if BANISH_FLAG == false then
                        BANISH_FLAG = true
                        DisplayTimedTextToForce(FORCE_PLAYING, 30., "|cffffcc00Death Knight:|r ...???")
                    end
                else
                    DisplayTimedTextToPlayer(p, 0., 0., 30., "Maybe you shouldn't waste this...")
                end
            end
        end

        --on cast aggro
        if spell then
            if GetSpellTargetX() == 0. and GetSpellTargetY() == 0. then
                Taunt(caster, pid, 800., false, 0, 200)
            else
                Taunt(caster, pid, math.min(800., DistanceCoords(x, y, GetSpellTargetX(), GetSpellTargetY())), false, 0, 200)
            end
        end
    end

    local spell         = CreateTrigger() ---@type trigger 
    local onenemyspell  = CreateTrigger() ---@type trigger 
    local cast          = CreateTrigger() ---@type trigger 
    local finish        = CreateTrigger() ---@type trigger 
    local learn         = CreateTrigger() ---@type trigger 
    local channel       = CreateTrigger() ---@type trigger 
    local u             = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(spell, u.player, EVENT_PLAYER_UNIT_SPELL_EFFECT, nil)
        TriggerRegisterPlayerUnitEvent(cast, u.player, EVENT_PLAYER_UNIT_SPELL_CAST, nil)
        TriggerRegisterPlayerUnitEvent(finish, u.player, EVENT_PLAYER_UNIT_SPELL_FINISH, nil)
        TriggerRegisterPlayerUnitEvent(learn, u.player, EVENT_PLAYER_HERO_SKILL, nil)
        TriggerRegisterPlayerUnitEvent(channel, u.player, EVENT_PLAYER_UNIT_SPELL_CHANNEL, nil)
        SetPlayerAbilityAvailable(u.player, FourCC('A0JV'), false) --elementalist setup
        SetPlayerAbilityAvailable(u.player, FourCC('A0JX'), false)
        SetPlayerAbilityAvailable(u.player, FourCC('A0JW'), false)
        SetPlayerAbilityAvailable(u.player, FourCC('A0JZ'), false)
        SetPlayerAbilityAvailable(u.player, FourCC('A0JY'), false)
        SetPlayerAbilityAvailable(u.player, prMulti[0], false) --pr setup
        SetPlayerAbilityAvailable(u.player, prMulti[1], false)
        SetPlayerAbilityAvailable(u.player, prMulti[2], false)
        SetPlayerAbilityAvailable(u.player, prMulti[3], false)
        SetPlayerAbilityAvailable(u.player, prMulti[4], false)
        SetPlayerAbilityAvailable(u.player, FourCC('A0AP'), false)
        SetPlayerAbilityAvailable(u.player, SONG_HARMONY, false)  --bard setup
        SetPlayerAbilityAvailable(u.player, SONG_PEACE, false)
        SetPlayerAbilityAvailable(u.player, SONG_WAR, false)
        SetPlayerAbilityAvailable(u.player, SONG_FATIGUE, false)
        SetPlayerAbilityAvailable(u.player, DETECT_LEAVE_ABILITY, false)

        u = u.next
    end

    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_HARMONY, false)
    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_WAR, false)
    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_PEACE, false)
    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_FATIGUE, false)
    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), DETECT_LEAVE_ABILITY, false)
    TriggerRegisterPlayerUnitEvent(onenemyspell, pfoe, EVENT_PLAYER_UNIT_SPELL_EFFECT, nil)
    TriggerAddAction(onenemyspell, EnemySpells)

    TriggerAddAction(spell, OnEffect)
    TriggerAddAction(cast, OnCast)
    TriggerAddAction(finish, OnFinish)
    TriggerAddCondition(learn, Filter(OnLearn))
    TriggerAddCondition(channel, Filter(OnChannel))

    Spells = {
        [LIGHTSEAL.id] = LIGHTSEAL,
        [DIVINEJUDGEMENT.id] = DIVINEJUDGEMENT,
        [SAVIORSGUIDANCE.id] = SAVIORSGUIDANCE,
        [HOLYBASH.id] = HOLYBASH,
        [THUNDERCLAP.id] = THUNDERCLAP,
        [RIGHTEOUSMIGHT.id] = RIGHTEOUSMIGHT,

        [SNIPERSTANCE.id] = SNIPERSTANCE,
        [TRIROCKET.id] = TRIROCKET,
        [ASSAULTHELICOPTER.id] = ASSAULTHELICOPTER,
        [SINGLESHOT.id] = SINGLESHOT,
        [HANDGRENADE.id] = HANDGRENADE,
        [U235SHELL.id] = U235SHELL,

        [OVERLOAD.id] = OVERLOAD,
        [THUNDERDASH.id] = THUNDERDASH,
        [MONSOON.id] = MONSOON,
        [BLADESTORM.id] = BLADESTORM,
        [OMNISLASH.id] = OMNISLASH,
        [RAILGUN.id] = RAILGUN,

        [INSTANTDEATH.id] = INSTANTDEATH,
        [DEATHSTRIKE.id] = DEATHSTRIKE,
        [HIDDENGUISE.id] = HIDDENGUISE,
        [NERVEGAS.id] = NERVEGAS,
        [BACKSTAB.id] = BACKSTAB,
        [PIERCINGSTRIKE.id] = PIERCINGSTRIKE,

        [BODYOFFIRE.id] = BODYOFFIRE,
        [METEOR.id] = METEOR,
        [MAGNETICSTANCE.id] = MAGNETICSTANCE,
        [INFERNALSTRIKE.id] = INFERNALSTRIKE,
        [MAGNETICSTRIKE.id] = MAGNETICSTRIKE,
        [GATEKEEPERSPACT.id] = GATEKEEPERSPACT,

        [BLOODFRENZY.id] = BLOODFRENZY,
        [BLOODLEAP.id] = BLOODLEAP,
        [BLOODCURDLINGSCREAM.id] = BLOODCURDLINGSCREAM,
        [BLOODCLEAVE.id] = BLOODCLEAVE,
        [RAMPAGE.id] = RAMPAGE,
        [UNDYINGRAGE.id] = UNDYINGRAGE,

        [PARRY.id] = PARRY,
        [SPINDASH.id] = SPINDASH,
        [INTIMIDATINGSHOUT.id] = INTIMIDATINGSHOUT,
        [WINDSCAR.id] = WINDSCAR,
        [ADAPTIVESTRIKE.id] = ADAPTIVESTRIKE,
        [LIMITBREAK.id] = LIMITBREAK,

        [FROSTBLAST.id] = FROSTBLAST,
        [WHIRLPOOL.id] = WHIRLPOOL,
        [TIDALWAVE.id] = TIDALWAVE,
        [BLIZZARD.id] = BLIZZARD,
        [ICEBARRAGE.id] = ICEBARRAGE,

        [BLOODBANK.id] = BLOODBANK,
        [BLOODLEECH.id] = BLOODLEECH,
        [BLOODDOMAIN.id] = BLOODDOMAIN,
        [BLOODMIST.id] = BLOODMIST,
        [BLOODNOVA.id] = BLOODNOVA,
        [BLOODLORD.id] = BLOODLORD,

        [INVIGORATION.id] = INVIGORATION,
        [DIVINELIGHT.id] = DIVINELIGHT,
        [SANCTIFIEDGROUND.id] = SANCTIFIEDGROUND,
        [HOLYRAYS.id] = HOLYRAYS,
        [PROTECTION.id] = PROTECTION,
        [RESURRECTION.id] = RESURRECTION,

        [SOULLINK.id] = SOULLINK,
        [LAWOFRESONANCE.id] = LAWOFRESONANCE,
        [LAWOFVALOR.id] = LAWOFVALOR,
        [LAWOFMIGHT.id] = LAWOFMIGHT,
        [AURAOFJUSTICE.id] = AURAOFJUSTICE,
        [DIVINERADIANCE.id] = DIVINERADIANCE,

        [ELEMENTFIRE.id] = ELEMENTFIRE,
        [ELEMENTICE.id] = ELEMENTICE,
        [ELEMENTLIGHTNING.id] = ELEMENTLIGHTNING,
        [ELEMENTEARTH.id] = ELEMENTEARTH,
        [BALLOFLIGHTNING.id] = BALLOFLIGHTNING,
        [FROZENORB.id] = FROZENORB,
        [FROZENORB.id2] = FROZENORB,
        [GAIAARMOR.id] = GAIAARMOR,
        [FLAMEBREATH.id] = FLAMEBREATH,
        [ELEMENTALSTORM.id] = ELEMENTALSTORM,

        [SUMMONINGIMPROVEMENT.id] = SUMMONINGIMPROVEMENT,
        [SUMMONDEMONHOUND.id] = SUMMONDEMONHOUND,
        [SUMMONMEATGOLEM.id] = SUMMONMEATGOLEM,
        [SUMMONDESTROYER.id] = SUMMONDESTROYER,
        [DEMONICSACRIFICE.id] = DEMONICSACRIFICE,

        [STEEDCHARGE.id] = STEEDCHARGE,
        [SHIELDSLAM.id] = SHIELDSLAM,
        [ROYALPLATE.id] = ROYALPLATE,
        [PROVOKE.id] = PROVOKE,
        [FIGHTME.id] = FIGHTME,
        [PROTECTOR.id] = PROTECTOR,

        [BLADESPIN.id] = BLADESPIN,
        [BLADESPINPASSIVE.id] = BLADESPINPASSIVE,
        [SHADOWSHURIKEN.id] = SHADOWSHURIKEN,
        [BLINKSTRIKE.id] = BLINKSTRIKE,
        [SMOKEBOMB.id] = SMOKEBOMB,
        [DAGGERSTORM.id] = DAGGERSTORM,
        [PHANTOMSLASH.id] = PHANTOMSLASH,

        [CONTROLTIME.id] = CONTROLTIME,
        [ARCANEBOLTS.id] = ARCANEBOLTS,
        [ARCANECOMETS.id] = ARCANECOMETS,
        [ARCANEBARRAGE.id] = ARCANEBARRAGE,
        [STASISFIELD.id] = STASISFIELD,
        [ARCANESHIFT.id] = ARCANESHIFT,
        [ARCANOSPHERE.id] = ARCANOSPHERE,

        [DARKSEAL.id] = DARKSEAL,
        [MEDEANLIGHTNING.id] = MEDEANLIGHTNING,
        [FREEZINGBLAST.id] = FREEZINGBLAST,
        [METAMORPHOSIS.id] = METAMORPHOSIS,

        [PHOENIXFLIGHT.id] = PHOENIXFLIGHT,
        [FIERYARROWS.id] = FIERYARROWS,
        [SEARINGARROWS.id] = SEARINGARROWS,
        [FLAMINGBOW.id] = FLAMINGBOW,

        [SONGOFWAR.id] = SONGOFWAR,
        [SONGOFHARMONY.id] = SONGOFHARMONY,
        [SONGOFPEACE.id] = SONGOFPEACE,
        [SONGOFFATIGUE.id] = SONGOFFATIGUE,
        [ENCORE.id] = ENCORE,
        [MELODYOFLIFE.id] = MELODYOFLIFE,
        [IMPROV.id] = IMPROV,
        [INSPIRE.id] = INSPIRE,
        [TONEOFDEATH.id] = TONEOFDEATH
    }

    --Spell inheritance
    for _, v in pairs(Spells) do --sync safe
        setmetatable(v, { __index = Spell })
    end
end)

if Debug then Debug.endFile() end
