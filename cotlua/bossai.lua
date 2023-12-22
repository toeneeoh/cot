if Debug then Debug.beginFile 'BossAI' end

OnInit.final("BossAI", function(require)
    require 'Variables'

    legionillusions = CreateGroup()

---@type fun(pt: PlayerTimer)
function StompPeriodic(pt)
    pt.dur = pt.dur - 1

    if pt.dur <= 0 or UnitAlive(pt.source) == false then
        pt:destroy()
    else
        local ug = CreateGroup()

        MakeGroupInRange(BOSS_ID, ug, GetUnitX(pt.source), GetUnitY(pt.source), 300., Condition(FilterEnemy))

        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(pt.source), GetUnitY(pt.source)))

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            UnitDamageTarget(pt.source, target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            target = FirstOfGroup(ug)
        end

        pt.timer:callDelayed(1., StompPeriodic, pt)
    end

    DestroyGroup(ug)
end

--[[

Death Knight

]]

---@type fun(pt: PlayerTimer)
function ShadowStepTeleport(pt)
    SetUnitXBounded(pt.target, pt.x)
    SetUnitYBounded(pt.target, pt.y)
    SetUnitVertexColor(pt.target, BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_RED), BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_GREEN), BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_BLUE), 255)
    PauseUnit(pt.target, false)
    BlzSetUnitFacingEx(pt.target, 270.)
end

---@param target unit
---@param dur number
function BossTeleport(target, dur)
    local i         = 0 ---@type integer 
    local pt ---@type PlayerTimer 
    local guy      = nil ---@type unit 
    local msg        = "" ---@type string 
    local pid         = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 

    if ChaosMode then
        guy = Boss[BOSS_LEGION]
        msg = "Shadow Step"
        BlzStartUnitAbilityCooldown(guy, FourCC('A0AV'), 2040. - (User.AmountPlaying * 240))
    else
        guy = Boss[BOSS_DEATH_KNIGHT]
        msg = "Death March"
        BlzStartUnitAbilityCooldown(guy, FourCC('A0AU'), 2040. - (User.AmountPlaying * 240))
    end

    if UnitAlive(guy) then
        FloatingTextUnit(msg, guy, 1.75, 100, 0, 12, 154, 38, 158, 0, true)
        PauseUnit(guy, true)
        Fade(guy, dur - 0.5, true)
        pt = TimerList[BOSS_ID]:add()
        pt.x = GetUnitX(target)
        pt.y = GetUnitY(target)
        pt.tag = FourCC('tpin')
        pt.target = guy
        bj_lastCreatedUnit = GetDummy(pt.x, pt.y, 0, 0, dur)
        BlzSetUnitSkin(bj_lastCreatedUnit, GetUnitTypeId(guy))
        SetUnitVertexColor(bj_lastCreatedUnit, BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_RED), BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_GREEN), BlzGetUnitIntegerField(bj_lastCreatedUnit, UNIT_IF_TINTING_COLOR_BLUE), 0)
        Fade(bj_lastCreatedUnit, dur, false)
        BlzSetUnitFacingEx(bj_lastCreatedUnit, 270.)
        PauseUnit(bj_lastCreatedUnit, true)
        pt.timer:callDelayed(dur, ShadowStepTeleport, pt)
        if dur >= 4 then
           PlaySound("Sound\\Interface\\CreepAggroWhat1.flac")
            if ChaosMode then
                DisplayTimedTextToForce(FORCE_PLAYING, 20., "|cffffcc00Legion:|r There is no escape " + User[pid - 1].nameColored .. "..")
            else
                DisplayTimedTextToForce(FORCE_PLAYING, 20., "|cffffcc00Death Knight:|r Prepare yourself " + User[pid - 1].nameColored .. "!")
            end
        end
    end
end

---@return boolean
function ShadowStepExpire()
    local ug       = CreateGroup()
    local g       = CreateGroup()
    local guy ---@type unit 
    local i         = 0 ---@type integer 

    if ChaosMode then
        guy = Boss[BOSS_LEGION]
    else
        guy = Boss[BOSS_DEATH_KNIGHT]
    end

    GroupEnumUnitsInRect(ug, gg_rct_Main_Map, Condition(ischar))
    GroupEnumUnitsInRect(g, gg_rct_NoSin, Condition(ischar))

    while i <= BOSS_TOTAL do
        GroupEnumUnitsInRangeEx(BOSS_ID, g, GetLocationX(BossLoc[i]), GetLocationY(BossLoc[i]), 2000., Condition(ischar))
        i = i + 1
    end

    if BlzGroupGetSize(g) > 0 then
        BlzGroupRemoveGroupFast(g, ug)
    end

    GroupEnumUnitsInRange(g, GetUnitX(guy), GetUnitY(guy), 1500., Condition(ischar))

    if BlzGroupGetSize(ug) > 0 and BlzGroupGetSize(g) == 0 then --no nearby players and player available to teleport to
        guy = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))
        if guy ~= nil then
            bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\BlackSmoke.mdx", GetUnitX(guy), GetUnitY(guy))
            BlzSetSpecialEffectTimeScale(bj_lastCreatedEffect, 0.75)
            BlzSetSpecialEffectScale(bj_lastCreatedEffect, 1.)
            TimerQueue:callDelayed(3., DestroyEffect, bj_lastCreatedEffect)

            BossTeleport(guy, 4.)
        end
    end

    DestroyGroup(ug)
    DestroyGroup(g)

    return false
end

---@type fun(pt: PlayerTimer)
function DeathStrike(pt)
    local ug = CreateGroup()

    SetUnitAnimation(pt.source, "death")

    MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 180., Condition(FilterEnemy))
    DestroyEffect(AddSpecialEffect("NecroticBlast.mdx", pt.x, pt.y))

    local target = FirstOfGroup(ug)
    while target do
        GroupRemoveUnit(ug, target)
        UnitDamageTarget(Boss[BOSS_DEATH_KNIGHT], target, 15000., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
        target = FirstOfGroup(ug)
    end

    pt:destroy()
    DestroyGroup(ug)
end

--Arkaden

function FrostNova()
    if UnitAlive(Boss[BOSS_GODSLAYER]) then
        local ug       = CreateGroup()

        MakeGroupInRange(BOSS_ID, ug, GetUnitX(Boss[BOSS_GODSLAYER]), GetUnitY(Boss[BOSS_GODSLAYER]), 700., Condition(FilterEnemy))
        DestroyEffect(AddSpecialEffect("war3mapImported\\FrostNova.mdx", GetUnitX(Boss[BOSS_GODSLAYER]), GetUnitY(Boss[BOSS_GODSLAYER])))

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            Freeze:add(Boss[BOSS_GODSLAYER], target):duration(3.)
            UnitDamageTarget(Boss[BOSS_GODSLAYER], target, 15000., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    end
end

--Goddesses

---@type fun(pt: PlayerTimer)
function SunStrike(pt)
    local ug = CreateGroup()

    MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 150., Condition(FilterEnemy))

    DestroyEffect(AddSpecialEffect("war3mapImported\\OrbitalRay.mdx", pt.x, pt.y))

    local target = FirstOfGroup(ug)
    while target do
        GroupRemoveUnit(ug, target)

        UnitDamageTarget(Boss[BOSS_LIFE], target, 25000., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
        target = FirstOfGroup(ug)
    end

    pt:destroy()

    DestroyGroup(ug)
end

---@type fun(holyward: unit)
function HolyWard(holyward)
    if UnitAlive(holyward) then
        local ug = CreateGroup()
        MakeGroupInRange(BOSS_ID, ug, GetUnitX(holyward), GetUnitY(holyward), 2000., Condition(FilterAllyHero))
        KillUnit(holyward)

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)

            HP(target, 100000)
            HolyBlessing:add(target, target):duration(30.)
            TimerQueue:callDelayed(2, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", target, "origin"))
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    end
end

---@type fun(pt: PlayerTimer)
function GhostShroud(pt)
    if IsUnitType(Boss[BOSS_KNOWLEDGE], UNIT_TYPE_ETHEREAL) then
        local ug       = CreateGroup()
        MakeGroupInRange(BOSS_ID, ug, GetUnitX(Boss[BOSS_KNOWLEDGE]), GetUnitY(Boss[BOSS_KNOWLEDGE]), 500., Condition(FilterEnemy))

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)

            UnitDamageTarget(Boss[BOSS_KNOWLEDGE], target, math.max(0, GetHeroInt(Boss[BOSS_KNOWLEDGE], true) - GetHeroInt(target, true)), true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    else
        pt:destroy()
    end
end

--Absolute Horror

function ZeppelinKill()
    local ug       = CreateGroup()
    local u ---@type unit 
    local bossindex         = 0 ---@type integer 
    local zepcount         = 0 ---@type integer 

    while bossindex <= BOSS_TOTAL do
        if UnitAlive(Boss[bossindex]) and IsUnitInRangeLoc(Boss[bossindex], BossLoc[bossindex], 1500.) then
            GroupEnumUnitsInRange(ug, GetUnitX(Boss[bossindex]), GetUnitY(Boss[bossindex]), 900., Condition(iszeppelin))
            zepcount = BlzGroupGetSize(ug)
            while true do
                u = FirstOfGroup(ug)
                if u == nil then break end
                GroupRemoveUnit(ug, u)
                ExpireUnit(u)
            end
            if zepcount > 0 then
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(Boss[bossindex]), GetUnitY(Boss[bossindex])))
                SetUnitAnimation(Boss[bossindex], "attack slam")
            end
        end
        bossindex = bossindex + 1
    end

    DestroyGroup(ug)
end

---@type fun(pt: PlayerTimer)
function TrueStealth(pt)
    local ug = CreateGroup()

    MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 400., Condition(FilterEnemy))

    UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('Amrf'))
    UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('A043'))
    UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('BOwk'))
    UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('Avul'))
    SetUnitXBounded(Boss[BOSS_ABSOLUTE_HORROR], pt.x)
    SetUnitYBounded(Boss[BOSS_ABSOLUTE_HORROR], pt.y)
    SetUnitAnimation(Boss[BOSS_ABSOLUTE_HORROR], "Attack Slam")

    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y))
    local target = FirstOfGroup(ug)
    if target then
        local heal = GetWidgetLife(target)
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))
        UnitDamageTarget(Boss[BOSS_ABSOLUTE_HORROR], target, 80000. + BlzGetUnitMaxHP(target) * 0.3, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", Boss[BOSS_ABSOLUTE_HORROR], "chest"))
        heal = math.max(0, heal - GetWidgetLife(target))
        SetUnitState(Boss[BOSS_ABSOLUTE_HORROR], UNIT_STATE_LIFE, GetWidgetLife(Boss[BOSS_ABSOLUTE_HORROR]) + heal)
    end

    pt:destroy()

    DestroyGroup(ug)
end

--Orsted

function ScreamOfDespair()
    if UnitAlive(Boss[BOSS_ORSTED]) then
        local ug       = CreateGroup()

        SpellCast(target, 0, 1.8, 5, 1.2)
        MakeGroupInRange(BOSS_ID, ug, GetUnitX(Boss[BOSS_ORSTED]), GetUnitY(Boss[BOSS_ORSTED]), 500., Condition(FilterEnemy))
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", Boss[BOSS_ORSTED], "origin"))

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            Fear:add(Boss[BOSS_ORSTED], target):duration(6.)
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)
    end
end

---@type fun(pt: PlayerTimer)
function CloudOfDespair(pt)
    pt.time = pt.time + 1.

    if pt.time < pt.dur then
        local ug = CreateGroup()

        MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 300., Condition(FilterEnemy))

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            UnitDamageTarget(Boss[BOSS_ORSTED], target, BlzGetUnitMaxHP(target) * 0.05, true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
            target = FirstOfGroup(ug)
        end

        DestroyGroup(ug)

        pt.timer:callDelayed(1., CloudOfDespair, pt)
    else
        pt:destroy()
    end
end

--Slaughter Queen

function ResetSlaughterMS()
    SetUnitMoveSpeed(Boss[BOSS_SLAUGHTER_QUEEN], 300)
end

function SlaughterAvatar()
    IssueImmediateOrder(Boss[BOSS_SLAUGHTER_QUEEN], "avatar")
    SetUnitMoveSpeed(Boss[BOSS_SLAUGHTER_QUEEN], 270)
    TimerQueue:callDelayed(10., ResetSlaughterMS)
end

--Dark Soul

---@type fun(pt: PlayerTimer)
function DarkSoulAbility(pt)
    pt.dur = pt.dur - 1

    if pt.dur == 0 then
        --freeze
        if pt.agi == 3 then
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), 300., Condition(FilterEnemy))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(pt.source), GetUnitY(pt.source)))

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                Stun:add(pt.source, target):duration(5.)
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        --mortify
        elseif pt.agi == 1 then
            BossPlusSpell(pt.source, 1000000, 1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl")
        --terrify
        elseif pt.agi == 2 then
            BossXSpell(pt.source, 1000000,1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl")
        end
    end

    if not UnitAlive(pt.source) or pt.dur < 0 or pt.agi == 0 then
        pt:destroy()
    else
        pt.timer:callDelayed(0.5, DarkSoulAbility, pt)
    end
end

--Satan

---@param x number
---@param y number
function SatanFlameStrike(x, y)
    local dummy = GetDummy(GetUnitX(Boss[BOSS_SATAN]), GetUnitY(Boss[BOSS_SATAN]), FourCC('A0DN'), 1, DUMMY_RECYCLE_TIME)  ---@type unit 

    SetUnitOwner(dummy, pboss, false)
    IssuePointOrder(dummy, "flamestrike", x, y)
end

--Thanatos

---@type fun(pt: PlayerTimer)
function ThanatosAbility(pt)
    if UnitAlive(pt.source) then
        if pt.agi == 1 then
            local ug = CreateGroup()
            GroupEnumUnitsInRange(ug, pt.x, pt.y, 200., Condition(ishostileEnemy))

            SetUnitXBounded(pt.source, pt.x)
            SetUnitYBounded(pt.source, pt.y)
            SetUnitAnimation(pt.source, "attack")

            local target = FirstOfGroup(ug)
            while target do
                GroupRemoveUnit(ug, target)
                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
                UnitDamageTarget(pt.source, target, 1500000, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
                target = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        elseif pt.agi == 2 then
            BossBlastTaper(pt.source, 1000000, FourCC('A0A4'), 750)
        end
    end

    pt:destroy()
end

--Pure Existence

---@type fun(pt: PlayerTimer)
function ExistenceAbility(pt)
    pt.dur = pt.dur - 1

    if pt.dur == 3 then
        if pt.agi == 3 then
            BossInnerRing(pt.source, 1000000, 2, 400, "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl")
        elseif pt.agi == 4 then
            BossOuterRing(pt.source, 500000, 2, 400, 900, "war3mapImported\\NeutralExplosion.mdx")
        end
    elseif pt.dur == 2 then
        if pt.agi == 1 then
            BossXSpell(pt.source, 500000, 2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl")
        end
    elseif pt.dur == 1 then
        if pt.agi == 2 then
            BossBlastTaper(pt.source, 1500000, FourCC('A0AB'), 800)
        end
    elseif pt.dur == 0 then
        if pt.agi == 1 then
            BossPlusSpell(pt.source, 500000, 2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl")
        end
    end

    if pt.dur < 0 or not UnitAlive(pt.source) then
        pt:destroy()
    else
        pt.timer:callDelayed(0.5, ExistenceAbility, pt)
    end
end

--Legion

function SpawnLegionIllusions()
    local i         = 0 ---@type integer 

    if UnitAlive(Boss[BOSS_LEGION]) then
        while i < 7 do
            Item.create(UnitAddItemById(Boss[BOSS_LEGION], FourCC('I06V')))

            i = i + 1
        end
    end
end

---@return boolean
function PositionLegionIllusions()
    local u      = GetSummonedUnit() ---@type unit 
    local x      = GetLocationX(BossLoc[BOSS_LEGION]) ---@type number 
    local y      = GetLocationY(BossLoc[BOSS_LEGION]) ---@type number 
    local target      = nil ---@type unit 
    local x2 ---@type number 
    local y2 ---@type number 
    local i         = GetRandomInt(0, 359) ---@type integer 
    local i2         = 1 ---@type integer 

    if GetUnitTypeId(u) == FourCC('H04R') and IsUnitIllusion(u) then
        GroupAddUnit(legionillusions, u)
        SetUnitPathing(u, false)
        UnitAddAbility(u, FourCC('Amrf'))
        RemoveItem(UnitItemInSlot(u, 0))
        RemoveItem(UnitItemInSlot(u, 1))
        RemoveItem(UnitItemInSlot(u, 2))
        RemoveItem(UnitItemInSlot(u, 3))
        RemoveItem(UnitItemInSlot(u, 4))
        RemoveItem(UnitItemInSlot(u, 5))
    end

    if BlzGroupGetSize(legionillusions) >= 7 then
        while true do
            x2 = x + 700 * Cos(bj_DEGTORAD * i)
            y2 = y + 700 * Sin(bj_DEGTORAD * i)

            if IsTerrainWalkable(x2, y2) and RectContainsCoords(gg_rct_NoSin, x2, y2) == false then break end

            i = GetRandomInt(0, 359)
        end

        SetUnitXBounded(Boss[BOSS_LEGION], x2)
        SetUnitYBounded(Boss[BOSS_LEGION], y2)
        SetUnitPathing(Boss[BOSS_LEGION], false)
        SetUnitPathing(Boss[BOSS_LEGION], true)
        BlzSetUnitFacingEx(Boss[BOSS_LEGION], bj_RADTODEG * Atan2(y2 - y, x2 - x))
        IssuePointOrder(Boss[BOSS_LEGION], "attack", x, y)

        while true do
            target = FirstOfGroup(legionillusions)
            if target == nil then break end
            GroupRemoveUnit(legionillusions, target)

            x2 = x + 700 * Cos(bj_DEGTORAD * (i + i2 * 45))
            y2 = y + 700 * Sin(bj_DEGTORAD * (i + i2 * 45))

            SetUnitXBounded(target, x2)
            SetUnitYBounded(target, y2)
            BlzSetUnitFacingEx(target, bj_RADTODEG * Atan2(y2 - y, x2 - x))
            IssuePointOrder(target, "attack", x, y)

            i2 = i2 + 1
        end
    end

    return false
end

--Azazoth

--Xallarath

---@type fun(pt: PlayerTimer)
function FireballProjectile(pt)
    local x = GetUnitX(pt.source) ---@type number 
    local y = GetUnitY(pt.source) ---@type number 

    pt.dur = pt.dur - pt.speed

    if pt.dur > 0. then
        local ug = CreateGroup()

        MakeGroupInRange(BOSS_ID, ug, x, y, pt.aoe, Condition(FilterEnemy))

        --movement
        SetUnitXBounded(pt.source, x + pt.speed * Cos(pt.angle))
        SetUnitYBounded(pt.source, y + pt.speed * Sin(pt.angle))

        local target = FirstOfGroup(ug)

        if target then
            UnitDamageTarget(Boss[BOSS_XALLARATH], target, pt.dmg, true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)

            pt.dur = 0.
        end

        DestroyGroup(ug)

        pt2.timer:callDelayed(FPS_32, FireballProjectile, pt2)
    else
        SetUnitAnimation(pt.source, "death")
        pt:destroy()
    end
end

---@type fun(pt: PlayerTimer)
function Fireball(pt)
    if UnitAlive(pt.source) then
        local ug = CreateGroup()
        local x = GetUnitX(pt.source) ---@type number 
        local y = GetUnitY(pt.source) ---@type number 
        local size = 0 ---@type integer 

        MakeGroupInRange(BOSS_ID, ug, x, y, 4000., Condition(FilterEnemy))

        size = BlzGroupGetSize(ug)

        if size > 0 and BlzGetUnitAbilityCooldownRemaining(pt.source, FourCC('A02V')) <= 0 then
            SpellCast(pt.source, FourCC('A02V'), 0.75, 5, 1.)
            local pt2 = TimerList[BOSS_ID]:add()
            pt2.target = BlzGroupUnitAt(ug, GetRandomInt(0, size - 1))
            pt2.angle = Atan2(GetUnitY(pt2.target) - y, GetUnitX(pt2.target) - x)
            pt2.source = GetDummy(x, y, 0, 0, 21.)
            pt2.x = GetUnitX(pt2.target)
            pt2.y = GetUnitY(pt2.target)
            pt2.speed = 7.
            pt2.aoe = 90.
            pt2.dur = DistanceCoords(pt2.x, pt2.y, x, y) + 500.
            pt2.dmg = 3000000.
            BlzSetUnitSkin(pt2.source, FourCC('h02U'))
            SetUnitFlyHeight(pt2.source, 80., 0.)
            SetUnitScale(pt2.source, 1.8, 1.8, 1.8)
            UnitDisableAbility(pt2.source, FourCC('Amov'), true)
            BlzSetUnitFacingEx(pt.source, pt2.angle * bj_RADTODEG)
            BlzSetUnitFacingEx(pt2.source, pt2.angle * bj_RADTODEG)

            pt2.timer:callDelayed(FPS_32, FireballProjectile, pt2)
        end

        DestroyGroup(ug)

        pt.timer:callDelayed(1., Fireball, pt)
    else
        pt:destroy()
    end
end

---@type fun(pt: PlayerTimer)
function FocusFire(pt)
    local ug       = CreateGroup()
    local x      = GetUnitX(pt.source) ---@type number 
    local y      = GetUnitY(pt.source) ---@type number 
    local size         = 0 ---@type integer 

    if UnitAlive(pt.source) then
        if pt.target == nil then
            MakeGroupInRange(BOSS_ID, ug, x, y, 4000., Condition(FilterEnemy))

            size = BlzGroupGetSize(ug)

            if size > 0 then
                pt.target = BlzGroupUnitAt(ug, GetRandomInt(0, size - 1))
                IssueTargetOrder(pt.source, "attack", pt.target)

                if not pt.lfx then
                    pt.lfx = AddLightning("RLAS", false, x, y, GetUnitX(pt.target), GetUnitY(pt.target))
                else
                    MoveLightningEx(pt.lfx, false, x, y, BlzGetLocalUnitZ(pt.source) + GetUnitFlyHeight(pt.source) + 50., GetUnitX(pt.target), GetUnitY(pt.target), BlzGetUnitZ(pt.target) + 50.)
                end
            end
        else
            if not IsUnitVisible(pt.target, Player(PLAYER_BOSS)) or UnitDistance(pt.source, pt.target) > 4000. then
                pt.target = nil
                pt.time = 0.
                pt.agi = 0
                MoveLightningEx(pt.lfx, false, 30000., 30000., 0., 30000., 30000., 0.)
                IssueImmediateOrder(pt.source, "stop")
                UnitSetBonus(pt.source, BONUS_ATTACK_SPEED, -8.)
                BlzStartUnitAbilityCooldown(pt.source, FourCC('A02G'), 0.001)
            else
                pt.time = pt.time + FPS_32
                MoveLightningEx(pt.lfx, false, x, y, BlzGetLocalUnitZ(pt.source) + GetUnitFlyHeight(pt.source) + 50., GetUnitX(pt.target), GetUnitY(pt.target), BlzGetUnitZ(pt.target) + 50.)

                if BlzGetUnitAbilityCooldownRemaining(pt.source, FourCC('A02G')) <= 0. then
                    SpellCast(pt.source, FourCC('A02G'), 5., 0, 1.)
                end

                if pt.time >= 5 then
                    UnitDamageTarget(pt.target, pt.source, 0.001, true, false, ATTACK_TYPE_NORMAL, PHYSICAL, WEAPON_TYPE_WHOKNOWS)
                    IssueTargetOrder(pt.source, "attack", pt.target)
                    UnitSetBonus(pt.source, BONUS_ATTACK_SPEED, 8.)
                    BlzSetUnitFacingEx(pt.source, bj_RADTODEG * Atan2(GetUnitY(pt.target) - y, GetUnitX(pt.target) - x))
                end
            end
        end
    else
        DestroyLightning(pt.lfx)
        pt:destroy()
    end

    DestroyGroup(ug)
end

---@type fun(pt: PlayerTimer)
function UnstoppableForceMovement(pt)
    if UnitAlive(Boss[BOSS_XALLARATH]) then
        local ug = CreateGroup()

        GroupEnumUnitsInRange(ug, GetUnitX(Boss[BOSS_XALLARATH]), GetUnitY(Boss[BOSS_XALLARATH]), 400., Condition(isplayerunit))

        local target = FirstOfGroup(ug)
        while target do
            GroupRemoveUnit(ug, target)
            if IsUnitInGroup(target, pt.ug) == false then
                GroupAddUnit(pt.ug, target)
                UnitDamageTarget(Boss[BOSS_XALLARATH], target, 50000000., true, false, ATTACK_TYPE_NORMAL, MAGIC, WEAPON_TYPE_WHOKNOWS)
            end
            target = FirstOfGroup(ug)
        end

        pt.angle = Atan2(pt.y - GetUnitY(Boss[BOSS_XALLARATH]), pt.x - GetUnitX(Boss[BOSS_XALLARATH]))

        if IsUnitInRangeXY(Boss[BOSS_XALLARATH], pt.x, pt.y, 125.) or DistanceCoords(pt.x, pt.y, GetUnitX(Boss[BOSS_XALLARATH]), GetUnitY(Boss[BOSS_XALLARATH])) > 2500. then
            SetUnitPathing(Boss[BOSS_XALLARATH], true)
            PauseUnit(Boss[BOSS_XALLARATH], false)
            IssueImmediateOrder(Boss[BOSS_XALLARATH], "stand")
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x + 200, pt.y))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x - 200, pt.y))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y + 200))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y - 200))

            pt:destroy()
        else
            SetUnitPathing(Boss[BOSS_XALLARATH], false)
            SetUnitXBounded(Boss[BOSS_XALLARATH], GetUnitX(Boss[BOSS_XALLARATH]) + 55 * Cos(pt.angle))
            SetUnitYBounded(Boss[BOSS_XALLARATH], GetUnitY(Boss[BOSS_XALLARATH]) + 55 * Sin(pt.angle))
        end

        DestroyGroup(ug)
    else
        SetUnitPathing(Boss[BOSS_XALLARATH], true)
        PauseUnit(Boss[BOSS_XALLARATH], false)
        IssueImmediateOrder(Boss[BOSS_XALLARATH], "stand")
        pt:destroy()
    end
end

---@type fun(pt: PlayerTimer)
function UnstoppableForce(pt)
    pt.timer:callPeriodically(FPS_32, nil, UnstoppableForceMovement, pt)
end

---@type fun(pt: PlayerTimer)
function XallarathSummon(pt)
    UnitApplyTimedLife(CreateUnit(Player(pt.pid - 1), FourCC('o034'), pt.x + 400 * Cos((pt.angle + 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle + 90) * bj_DEGTORAD), pt.angle), FourCC('BTLF'), 120.)
    UnitApplyTimedLife(CreateUnit(Player(pt.pid - 1), FourCC('o034'), pt.x + 400 * Cos((pt.angle - 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle - 90) * bj_DEGTORAD), pt.angle), FourCC('BTLF'), 120.)

    pt:destroy()
end

---@param x number
---@param y number
---@param height number
function SpawnForgottenArcher(x, y, height)
    local pt             = TimerList[BOSS_ID]:add() ---@type PlayerTimer 
    pt.source = CreateUnit(pboss, FourCC('o001'), x, y, 0.)
    if UnitAddAbility(pt.source, FourCC('Amrf')) then
        UnitRemoveAbility(pt.source, FourCC('Amrf'))
    end
    SetUnitFlyHeight(pt.source, height, 0.)
    ShowUnit(pt.source, false)
    ShowUnit(pt.source, true)
    UnitApplyTimedLife(pt.source, FourCC('BTLF'), 300.)
    pt.timer:callPeriodically(FPS_32, nil, FocusFire, pt)
end

---@param x number
---@param y number
---@param height number
function SpawnForgottenMage(x, y, height)
    local pt             = TimerList[BOSS_ID]:add() ---@type PlayerTimer 
    pt.source = CreateUnit(pboss, FourCC('o000'), x, y, 0.)
    if UnitAddAbility(pt.source, FourCC('Amrf')) then
        UnitRemoveAbility(pt.source, FourCC('Amrf'))
    end
    SetUnitFlyHeight(pt.source, height, 0.)
    ShowUnit(pt.source, false)
    ShowUnit(pt.source, true)
    UnitApplyTimedLife(pt.source, FourCC('BTLF'), 300.)
    pt.timer:callDelayed(1., Fireball, pt)
end

--[[


]]

---@param source unit
---@param target unit
function BossSpellCasting(source, target)
    local pt ---@type PlayerTimer 
    local i         = 0 ---@type integer 
    local ug       = CreateGroup()
    local u      = nil ---@type unit 
    local angle      = 0. ---@type number 

    --prechaos bosses
    --hellfire magi
    if not ChaosMode then
        if target == Boss[BOSS_HELLFIRE] and UnitAlive(Boss[BOSS_HELLFIRE]) then
            --frost armor
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02M')) <= 0 then
                SpellCast(target, FourCC('A02M'), 1., 4, 1.)
                FrostArmorBuff:add(target, target):duration(10.)
            --chain lightning
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A00G')) <= 0 then
                IssueTargetOrder(target, "chainlightning", source)
            --flame strike
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01T')) <= 0 then
                IssuePointOrder(target, "flamestrike", GetUnitX(source), GetUnitY(source))
            end

        --lady vashj
        elseif target == Boss[BOSS_VASHJ] and UnitAlive(Boss[BOSS_VASHJ]) then
            --tornado storm
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A085')) <= 0 then
                SpellCast(target, FourCC('A085'), 1.5, 5, 1.)
                bj_lastCreatedUnit = CreateUnit(Player(PLAYER_BOSS), FourCC('n001'), GetUnitX(target), GetUnitY(target), 0.)
                IssuePointOrder(bj_lastCreatedUnit, "move", GetRandomReal(GetUnitX(target) - 250, GetUnitX(target) + 250), GetRandomReal(GetUnitY(target) - 250, GetUnitY(target) + 250))
                TimerQueue:callDelayed(40., RemoveUnit, bj_lastCreatedUnit)
                bj_lastCreatedUnit = CreateUnit(Player(PLAYER_BOSS), FourCC('n001'), GetUnitX(target), GetUnitY(target), 0.)
                IssuePointOrder(bj_lastCreatedUnit, "move", GetRandomReal(GetUnitX(target) - 250, GetUnitX(target) + 250), GetRandomReal(GetUnitY(target) - 250, GetUnitY(target) + 250))
                TimerQueue:callDelayed(40., RemoveUnit, bj_lastCreatedUnit)
            end

        --tauren
        elseif target == Boss[BOSS_TAUREN] and UnitAlive(Boss[BOSS_TAUREN]) then
            --shockwave
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02L')) <= 0 and UnitDistance(source, target) < 600 then
                IssuePointOrder(Boss[BOSS_TAUREN], "carrionswarm", GetUnitX(source), GetUnitY(source))
            --war stomp
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A09J')) <= 0 and UnitDistance(source, target) < 300. then
                FloatingTextUnit("War Stomp", Boss[BOSS_TAUREN], 2., 60., 0, 12, 255, 255, 255, 0, true)
                SpellCast(target, FourCC('A09J'), 1., 4, 1.)
                pt = TimerList[BOSS_ID]:add()
                pt.dmg = 4000.
                pt.source = target
                pt.dur = 8.
                pt.timer:callDelayed(1., StompPeriodic, pt)
            end

        --mystic
        elseif target == Boss[BOSS_MYSTIC] and UnitAlive(Boss[BOSS_MYSTIC]) then
            if UnitDistance(target, source) < 800. then
                --mana drain
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01Z')) <= 0 then
                    SpellCast(target, FourCC('A01Z'), 1.5, 4, 1.)
                    MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 800., Condition(FilterEnemy))
                    while true do
                        u = FirstOfGroup(ug)
                        if u == nil then break end
                        GroupRemoveUnit(ug, u)
                        --vampire mana drain exception
                        if not ManaDrainDebuff:has(target, u) and GetUnitTypeId(u) ~= HERO_VAMPIRE then
                            ManaDrainDebuff:add(target, u):duration(9999.)
                        end
                    end
                end
            end

        --dwarf
        elseif target == Boss[BOSS_DWARF] and UnitAlive(Boss[BOSS_DWARF]) then
            if UnitDistance(target, source) < 300. then
                --avatar
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0DV')) <= 0 then
                    IssueImmediateOrder(Boss[BOSS_DWARF], "avatar")
                --thunder clap
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0A2')) <= 0 then
                    FloatingTextUnit("Thunder Clap", Boss[BOSS_DWARF], 2., 60., 0, 12, 0, 255, 255, 0, true)
                    SpellCast(target, FourCC('A0A2'), 1., 4, 1.)
                    pt = TimerList[BOSS_ID]:add()
                    pt.dmg = 8000.
                    pt.source = target
                    pt.dur = 8.
                    pt.timer:callDelayed(1., StompPeriodic, pt)
                end
            end

        --death knight
        elseif target == Boss[BOSS_DEATH_KNIGHT] and UnitAlive(Boss[BOSS_DEATH_KNIGHT]) then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0AO')) <= 0 and UnitDistance(source, target) > 250. then
                BlzStartUnitAbilityCooldown(target, FourCC('A0AO'), 20.)
                BossTeleport(source, 1.5)
            --death strikes
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A088')) <= 0 then
                SpellCast(target, FourCC('A088'), 0.7, 3, 1.)
                MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 1250., Condition(FilterEnemy))
                FloatingTextUnit("Death Strikes", Boss[BOSS_DEATH_KNIGHT], 2., 60., 0, 12, 255, 255, 255, 0, true)
                while true do
                    u = FirstOfGroup(ug)
                    if u == nil then break end
                    GroupRemoveUnit(ug, u)
                    if BlzGroupGetSize(ug) < 4 then
                        pt = TimerList[BOSS_ID]:add()
                        pt.x = GetUnitX(u)
                        pt.y = GetUnitY(u)
                        pt.source = GetDummy(pt.x, pt.y, 0, 0, DUMMY_RECYCLE_TIME)
                        SetUnitScale(pt.source, 4., 4., 4.)
                        BlzSetUnitSkin(pt.source, FourCC('e01F'))
                        pt.timer:callDelayed(3., DeathStrike)
                    end
                end
            end

        --vengeful test paladin
        elseif target == Boss[BOSS_PALADIN] and UnitAlive(Boss[BOSS_PALADIN]) then
            IssueTargetOrder(target, "holybolt", target)

        --arkaden
        elseif target == Boss[BOSS_GODSLAYER] and UnitAlive(Boss[BOSS_GODSLAYER]) then
            --meta
            if GetWidgetLife(target) < BlzGetUnitMaxHP(target) * 0.5 then
                IssueImmediateOrder(target, "metamorphosis")
            end

            --frost nova
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A066')) <= 0. then
                if GetUnitTypeId(target) == FourCC('E007') then
                    SpellCast(target, FourCC('A066'), 1., 8, 1.)
                else
                    SpellCast(target, FourCC('A066'), 1., 2, 1.)
                end

                FloatingTextUnit("Frost Nova", target, 1.75, 100, 0, 12, 255, 255, 255, 0, true)

                TimerQueue:callDelayed(1., FrostNova)

            --raise skeletons
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01H')) <= 0. and GetUnitAbilityLevel(target, FourCC('A01H')) > 0 then
                SpellCast(target, FourCC('A01H'), 1.5, 8, 1.)

                i = 0

                while i ~= 5 do

                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl", GetUnitX(target) + 80. * Cos(bj_PI * i * 0.4), GetUnitY(target) + 80. * Sin(bj_PI * i * 0.4)))
                    bj_lastCreatedUnit = CreateUnit(Player(PLAYER_BOSS), FourCC('n00E'), GetUnitX(target) + 80. * Cos(bj_PI * i * 0.4), GetUnitY(target) + 80. * Sin(bj_PI * i * 0.4), GetUnitFacing(target))
                    SpellCast(bj_lastCreatedUnit, 0, 1.5, 9, 1.)
                    UnitApplyTimedLife(bj_lastCreatedUnit, FourCC('BTLF'), 30.)

                    i = i + 1
                end
            end

        --Goddesses
        elseif (target == Boss[BOSS_HATE] or target == Boss[BOSS_LOVE] or target == Boss[BOSS_KNOWLEDGE]) then
            --Love Holy Ward
            if UnitAlive(Boss[BOSS_LOVE]) and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 then
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A06T')) <= 0 then
                    SpellCast(target, FourCC('A06T'), 0.5, 9, 1.5)
                    local holyward = CreateUnit(pboss, FourCC('o009'), GetRandomReal(GetRectMinX(gg_rct_Crystal_Spawn) - 500, GetRectMaxX(gg_rct_Crystal_Spawn) + 500), GetRandomReal(GetRectMinY(gg_rct_Crystal_Spawn) - 600, GetRectMaxY(gg_rct_Crystal_Spawn) + 600), 0)

                    MakeGroupInRange(BOSS_ID, ug, GetUnitX(holyward), GetUnitY(holyward), 1250., Condition(FilterEnemy))
                    BlzSetUnitMaxHP(holyward, 10 * BlzGroupGetSize(ug))

                    Unit[holyward].attackCount = BlzGetUnitMaxHP(holyward)

                    TimerQueue:callDelayed(10., HolyWard, holyward)
                end
            end

            --knowledge
            if target == Boss[BOSS_KNOWLEDGE] and UnitAlive(target) and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 and not Unit[target].casting then
                --ghost shroud
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0A8')) <= 0 then
                    SpellCast(target, FourCC('A0A8'), 0.25, 8, 1.5)
                    DummyCastTarget(pboss, target, FourCC('A08I'), 1, GetUnitX(target), GetUnitY(target), "banish")
                    pt = TimerList[BOSS_ID]:add()
                    pt.timer:callPeriodically(1., nil, GhostShroud, pt)
                --silence
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05B')) <= 0 then
                    SpellCast(target, FourCC('A05B'), 1., 8, 1.5)

                    MakeGroupInRange(BOSS_ID, ug, GetUnitX(source), GetUnitY(source), 1000., Condition(FilterEnemy))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Silence\\SilenceAreaBirth.mdl", GetUnitX(source), GetUnitY(source)))

                    while true do
                        target = FirstOfGroup(ug)
                        if target == nil then break end
                        GroupRemoveUnit(ug, target)
                        Silence:add(Boss[BOSS_KNOWLEDGE], target):duration(10.)
                    end
                --disarm
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05W')) <= 0 then
                    SpellCast(target, FourCC('A05W'), 1., 8, 1.5)
                    Disarm:add(target, source):duration(6.)
                end
            end

        --Life
        --sun strike
        elseif (target == Boss[BOSS_LIFE]) and UnitAlive(target) and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 and BlzGetUnitAbilityCooldownRemaining(target, FourCC('A08M')) <= 0 then
            BlzStartUnitAbilityCooldown(target, FourCC('A08M'), 20.)

            GroupEnumUnitsInRange(ug, GetUnitX(target), GetUnitY(target), 1250., Condition(isplayerAlly))

            i = 1

            while true do
                u = FirstOfGroup(ug)
                if (i > 3 or u == nil) then break end
                GroupRemoveUnit(ug, u)

                bj_lastCreatedUnit = GetDummy(GetUnitX(u), GetUnitY(u), 0, 0, 3.)
                SetUnitScale(bj_lastCreatedUnit, 4., 4., 4.)
                BlzSetUnitFacingEx(bj_lastCreatedUnit, 270)
                BlzSetUnitSkin(bj_lastCreatedUnit, FourCC('e01F'))
                SetUnitVertexColor(bj_lastCreatedUnit, 200, 200, 0, 255)

                pt = TimerList[BOSS_ID]:add()
                pt.x = GetUnitX(u)
                pt.y = GetUnitY(u)
                pt.timer:callDelayed(3., SunStrike, pt)

                i = i + 1
            end
        end
    else

    --chaos bosses
        --Demon Prince
        if target == Boss[BOSS_DEMON_PRINCE] and UnitAlive(Boss[BOSS_DEMON_PRINCE]) and (GetWidgetLife(Boss[BOSS_DEMON_PRINCE]) / BlzGetUnitMaxHP(Boss[BOSS_DEMON_PRINCE])) <= 0.5 then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0AX')) <= 0 then
                BlzStartUnitAbilityCooldown(target, FourCC('A0AX'), 60.)
                DemonPrinceBloodlust:add(target, target):duration(60.)
                DummyCastTarget(Player(PLAYER_BOSS), target, FourCC('A041'), 1, GetUnitX(target), GetUnitY(target), "bloodlust")
            end

        --Absolute Horror
        elseif target == Boss[BOSS_ABSOLUTE_HORROR] and UnitAlive(Boss[BOSS_ABSOLUTE_HORROR]) and (GetWidgetLife(Boss[BOSS_ABSOLUTE_HORROR]) / BlzGetUnitMaxHP(Boss[BOSS_ABSOLUTE_HORROR])) <= 0.8 then
            i = GetRandomInt(0, 99)
            if i < 10 and BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0AC')) <= 0 then
                BlzStartUnitAbilityCooldown(target, FourCC('A0AC'), 10.)

                MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 1500., Condition(FilterEnemy))
                FloatingTextUnit("True Stealth", Boss[BOSS_ABSOLUTE_HORROR], 1.75, 100, 0, 12, 90, 30, 150, 0, true)
                UnitRemoveBuffs(Boss[BOSS_ABSOLUTE_HORROR], false, true)
                UnitAddAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('Avul'))
                UnitAddAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('A043'))
                IssueImmediateOrder(Boss[BOSS_ABSOLUTE_HORROR], "windwalk")
                u = FirstOfGroup(ug)
                if u ~= nil then
                    angle = Atan2(GetUnitY(u) - GetUnitY(Boss[BOSS_ABSOLUTE_HORROR]), GetUnitX(u) - GetUnitX(Boss[BOSS_ABSOLUTE_HORROR]))
                    UnitAddAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('Amrf'))
                    IssuePointOrder(Boss[BOSS_ABSOLUTE_HORROR], "move", GetUnitX(u) + 300 * Cos(angle), GetUnitY(u) + 300 * Sin(angle))
                    pt = TimerList[BOSS_ID]:add()
                    pt.x = GetUnitX(u) + 150 * Cos(angle)
                    pt.y = GetUnitY(u) + 150 * Sin(angle)
                    pt.timer:callDelayed(2., TrueStealth, pt)
                else
                    UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('Avul'))
                    UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('A043'))
                    UnitRemoveAbility(Boss[BOSS_ABSOLUTE_HORROR], FourCC('BOwk'))
                end
                GroupClear(ug)
            end
        --Orsted
        elseif target == Boss[BOSS_ORSTED] and UnitAlive(target) then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A03W')) <= 0. and not Unit[target].casting then
                pt = TimerList[BOSS_ID]:add()
                pt.x = GetRandomReal(GetRectMinX(gg_rct_Crypt) + 200., GetRectMaxX(gg_rct_Crypt) - 200.)
                pt.y = GetRandomReal(GetRectMinY(gg_rct_Crypt) + 200., GetRectMaxY(gg_rct_Crypt) - 200.)
                pt.sfx = AddSpecialEffect("war3mapImported\\SporeCloud025_Priority005.mdx", pt.x, pt.y)
                pt.dur = 8.

                BlzSetUnitFacingEx(target, Atan2(pt.y - GetUnitY(target), pt.x - GetUnitX(target)) * bj_RADTODEG)
                SpellCast(target, FourCC('A03W'), 1.5, 3, 1.2)

                pt.timer:callDelayed(1., CloudOfDespair, pt)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A04Q')) <= 0. and not Unit[target].casting and UnitDistance(source, target) <= 300. then
                SpellCast(target, FourCC('A04Q'), 2., 1, 1.)

                FloatingTextUnit("Scream of Despair", Boss[BOSS_ORSTED], 3, 100, 0, 13, 255, 255, 255, 0, true)

                TimerQueue:callDelayed(2, ScreamOfDespair)
            end

        --Slaughter
        elseif target == Boss[BOSS_SLAUGHTER_QUEEN] and UnitAlive(target) then
            i = GetRandomInt(1, 8)
            if HardMode > 0 then
                SetUnitAbilityLevel(Boss[BOSS_SLAUGHTER_QUEEN], FourCC('A064'), 2)
                SetUnitAbilityLevel(Boss[BOSS_SLAUGHTER_QUEEN], FourCC('A040'), 2)
            else
                SetUnitAbilityLevel(Boss[BOSS_SLAUGHTER_QUEEN], FourCC('A064'), 1)
                SetUnitAbilityLevel(Boss[BOSS_SLAUGHTER_QUEEN], FourCC('A040'), 1)
            end

            if i == 1 and BlzGetUnitAbilityCooldownRemaining(Boss[BOSS_SLAUGHTER_QUEEN], FourCC('A040')) <= 0 then
                SpellCast(target, FourCC('A040'), 0., -1, 1.)
                FloatingTextUnit("Avatar", Boss[BOSS_SLAUGHTER_QUEEN], 3, 100, 0, 13, 255, 255, 255, 0, true)
                TimerQueue:callDelayed(2., SlaughterAvatar)
            end

        --Dark Soul
        elseif target == Boss[BOSS_DARK_SOUL] and UnitAlive(target) and not Unit[target].casting then
            i = GetRandomInt(1, 2)
            pt = TimerList[BOSS_ID]:add()
            pt.source = target
            pt.dur = 4.
            pt.agi = 0
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A03M')) <= 0 then
                if i == 1 then
                    FloatingTextUnit("+ MORTIFY +", target, 3, 70, 0, 11, 255, 255, 255, 0, true)
                    pt.agi = 1
                else
                    FloatingTextUnit("x TERRIFY x", target, 3, 70, 0, 11, 255, 255, 255, 0, true)
                    pt.agi = 2
                end
                BlzStartUnitAbilityCooldown(target, FourCC('A03M'), 5.)
                BlzStartUnitAbilityCooldown(target, FourCC('A05U'), 5.)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02Q')) <= 0 then
                SpellCast(target, FourCC('A02Q'), 2., 5, 1.)
                FloatingTextUnit("||||| FREEZE |||||", target, 3, 70, 0, 11, 255, 255, 255, 0, true)
                pt.agi = 3
            end
            pt.timer:callDelayed(0.5, DarkSoulAbility, pt)

        --Satan
        elseif target == Boss[BOSS_SATAN] and UnitAlive(target) then
            if GetRandomInt(0, 99) < 10 then
                SatanFlameStrike(GetUnitX(source), GetUnitY(source))
            end

        --Legion
        elseif target == Boss[BOSS_LEGION] and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05I')) <= 0 and UnitDistance(source, target) > 250. then --shadow step
                SpellCast(target, FourCC('A05I'), 0., 1, 1.)
                BossTeleport(source, 1.5)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A08C')) <= 0 and TimerList[BOSS_ID]:has(FourCC('tpin')) == false and UnitDistance(source, target) < 800 then
                SpellCast(target, FourCC('A08C'), 0.5, 12, 1.)
                TimerQueue:callDelayed(2, DestroyEffect, AddSpecialEffect("Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", Boss[BOSS_LEGION], Boss[BOSS_LEGION]))
                RemoveLocation(BossLoc[BOSS_LEGION])
                BossLoc[BOSS_LEGION] = Location(GetUnitX(source), GetUnitY(source))
                TimerQueue:callDelayed(0.5, SpawnLegionIllusions)
            end

        --Thanatos
        elseif target == Boss[BOSS_THANATOS] and UnitAlive(target) and not Unit[target].casting then
            i = GetRandomInt(0, 99)

            if i < 10 then
                pt = TimerList[BOSS_ID]:add()
                pt.x = GetUnitX(source)
                pt.y = GetUnitY(source)
                pt.source = target

                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A023')) <= 0 and UnitDistance(source, target) > 250 then
                    BlzStartUnitAbilityCooldown(target, FourCC('A023'), 10.)
                    FloatingTextUnit("Swift Hunt", target, 1, 70, 0, 10, 255, 255, 255, 0, true)
                    pt.agi = 1
                    pt.timer:callDelayed(1.5, ThanatosAbility, pt)
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02P')) <= 0 then
                    SpellCast(target, FourCC('A02P'), 2., 12, 1.)
                    FloatingTextUnit("Death Beckons", target, 2, 70, 0, 10, 255, 255, 255, 0, true)
                    pt.agi = 2
                    pt.timer:callDelayed(2.5, ThanatosAbility, pt)
                end
            end

        --Existence
        elseif target == Boss[BOSS_EXISTENCE] and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A07F')) <= 0. then
                i = GetRandomInt(1, 4)
                if i == 1 then
                    FloatingTextUnit("Devastation", target ,2, 70, 0, 12, 255, 40, 40, 0, true)
                elseif i == 2 then
                    FloatingTextUnit("Extermination", target, 3, 70, 0, 12, 255, 255, 255, 0, true)
                elseif i == 3 and UnitDistance(source, target) <= 400 then
                    FloatingTextUnit("Implosion", target, 3, 70, 0, 12, 68, 68, 255, 0, true)
                elseif i == 4 and UnitDistance(source, target) >= 400 then
                    FloatingTextUnit("Explosion", target, 3, 70, 0, 12, 255, 100, 50, 0, true)
                else
                    i = 0
                end

                if i > 0 then
                    pt = TimerList[BOSS_ID]:add()
                    pt.source = target
                    pt.dur = 5.
                    pt.agi = i
                    SpellCast(target, FourCC('A07F'), 0., -1, 1.)
                    SpellCast(target, FourCC('A07Q'), 0., -1, 1.)
                    SpellCast(target, FourCC('A073'), 0., -1, 1.)
                    SpellCast(target, FourCC('A072'), 1.5, 4, 1.5)
                    pt.timer:callDelayed(0.5, ExistenceAbility, pt)
                end
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A07X')) <= 0. then
                SpellCast(target, FourCC('A07X'), 1.5, 4, 1.5)
                FloatingTextUnit("Protected Existence", target, 3, 70, 0, 12, 100, 255, 100, 0, true)
                ProtectedExistenceBuff:add(target, target):duration(10.)
            end

        --Xallarath
        elseif target == Boss[BOSS_XALLARATH] and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01I')) <= 0 and GetWidgetLife(target) <= BlzGetUnitMaxHP(target) * 0.5 then
                SpellCast(target, FourCC('A01I'), 0., 3, 1.)
                FloatingTextUnit("Reinforcements", Boss[BOSS_XALLARATH], 1.75, 100, 0, 12, 255, 0, 0, 0, true)
                pt = TimerList[BOSS_ID]:add()
                pt.angle = GetUnitFacing(target)
                pt.x = GetUnitX(target)
                pt.y = GetUnitY(target)
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", pt.x + 400 * Cos((pt.angle + 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle + 90) * bj_DEGTORAD)))
                DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Demon\\DarkPortal\\DarkPortalTarget.mdl", pt.x + 400 * Cos((pt.angle - 90) * bj_DEGTORAD), pt.y + 400 * Sin((pt.angle - 90) * bj_DEGTORAD)))
                pt.timer:callDelayed(2., XallarathSummon, pt)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01J')) <= 0 then
                GroupEnumUnitsInRange(ug, GetUnitX(target), GetUnitY(target), 1500., Condition(isplayerAlly))

                if BlzGroupGetSize(ug) > 0 then
                    PauseUnit(target, true)
                    SpellCast(target, FourCC('A01J'), 2.5, 1, 1.)
                    u = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))
                    FloatingTextUnit("Unstoppable Force", target, 1.75, 100, 0, 12, 255, 0, 0, 0, true)
                    bj_lastCreatedUnit = GetDummy(GetUnitX(u), GetUnitY(u), 0, 0, 4.)
                    SetUnitScale(bj_lastCreatedUnit, 10., 10., 10.)
                    BlzSetUnitFacingEx(bj_lastCreatedUnit, 270.)
                    BlzSetUnitSkin(bj_lastCreatedUnit, FourCC('e01F'))
                    SetUnitVertexColor(bj_lastCreatedUnit, 200, 200, 0, 255)
                    pt = TimerList[BOSS_ID]:add()
                    pt.x = GetUnitX(u)
                    pt.y = GetUnitY(u)
                    pt.ug = CreateGroup()
                    pt.angle = Atan2(GetUnitY(u) - GetUnitY(target), GetUnitX(u) - GetUnitX(target))
                    BlzSetUnitFacingEx(target, pt.angle * bj_RADTODEG)
                    pt.timer:callDelayed(2.5, UnstoppableForce, pt)
                end
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02B')) <= 0. and GetWidgetLife(target) <= BlzGetUnitMaxHP(target) * 0.9 then
                SpellCast(target, FourCC('A02B'), 0., 3, 1.)
                --archers
                SpawnForgottenArcher(12349., -15307., 770.)
                SpawnForgottenArcher(13500., -12300., 575.)
                SpawnForgottenArcher(14079., -11550., 575.)
                --mages
                SpawnForgottenMage(14315., -12863., 770.)
                SpawnForgottenMage(11788., -14279., 575.)
                SpawnForgottenMage(11214., -15133., 575.)
            end

        --Azazoth
        elseif target == Boss[BOSS_AZAZOTH] and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01B')) <= 0 then
                --adjust cooldown based on HP
                BlzSetUnitAbilityCooldown(target, FourCC('A01B'), 0, 15. + R2I(GetWidgetLife(target) / BlzGetUnitMaxHP(target) * 15.))
                pt = TimerList[BOSS_ID]:add()
                pt.dmg = 4000000.
                pt.dur = MathClamp(GetWidgetLife(target) // BlzGetUnitMaxHP(target), 0.35, 0.75)
                pt.angle = GetUnitFacing(Boss[BOSS_AZAZOTH])
                pt.source = target
                FloatingTextUnit("Astral Devastation", pt.source, 3, 70, 0, 12, 255, 255, 255, 0, true)
                pt.timer:callDelayed(pt.dur, AstralDevastation, pt)
                SpellCast(target, FourCC('A01B'), pt.dur * 4, 4, 1.)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A00K')) <= 0 then
                --adjust cooldown based on HP
                BlzSetUnitAbilityCooldown(target, FourCC('A00K'), 0, 25. + R2I(GetWidgetLife(target) / BlzGetUnitMaxHP(target) * 25.))
                pt = TimerList[BOSS_ID]:add()
                pt.dur = MathClamp(GetWidgetLife(target) // BlzGetUnitMaxHP(target), 0.35, 0.75)
                pt.dmg = 2000000.
                pt.source = target
                FloatingTextUnit("Astral Annihilation", pt.source, 3, 70, 0, 12, 255, 255, 255, 0, true)
                pt.timer:callDelayed(pt.dur, AstralAnnihilation, pt)
                SpellCast(target, FourCC('A00K'), pt.dur * 4, 4, 1.)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01C')) <= 0 then
                SpellCast(target, FourCC('A01C'), 1., 6, 1.)
                FloatingTextUnit("Astral Shield", Boss[BOSS_AZAZOTH], 3, 70, 0, 12, 255, 255, 255, 0, true)
                AstralShieldBuff:add(Boss[BOSS_AZAZOTH], Boss[BOSS_AZAZOTH]):duration(13.)
            end
        end
    end

    DestroyGroup(ug)
end

    local t = CreateTrigger() ---@type trigger 

    TriggerRegisterPlayerUnitEvent(t, pboss, EVENT_PLAYER_UNIT_SUMMON, nil)
    TriggerAddCondition(t, Filter(PositionLegionIllusions))

end)

if Debug then Debug.endFile() end
