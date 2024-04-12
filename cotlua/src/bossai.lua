OnInit.final("BossAI", function(Require)
    Require('Variables')

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

        for target in each(ug) do
            DamageTarget(pt.source, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, pt.tag)
        end

        DestroyGroup(ug)

        pt.timer:callDelayed(1., StompPeriodic, pt)
    end
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

---@type fun(target: unit, dur: number)
function BossTeleport(target, dur)
    local guy = (CHAOS_MODE and BossTable[BOSS_LEGION].unit) or BossTable[BOSS_DEATH_KNIGHT].unit
    local msg = (CHAOS_MODE and "Shadow Step") or "Death March"
    local pid = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 

    if CHAOS_MODE then
        BlzStartUnitAbilityCooldown(guy, FourCC('A0AV'), 2040. - (User.AmountPlaying * 240))
    else
        BlzStartUnitAbilityCooldown(guy, FourCC('A0AU'), 2040. - (User.AmountPlaying * 240))
    end

    if UnitAlive(guy) then
        FloatingTextUnit(msg, guy, 1.75, 100, 0, 12, 154, 38, 158, 0, true)
        PauseUnit(guy, true)
        Fade(guy, dur - 0.5, true)
        local pt = TimerList[BOSS_ID]:add()
        pt.x = GetUnitX(target)
        pt.y = GetUnitY(target)
        pt.tag = FourCC('tpin')
        pt.target = guy
        local dummy = Dummy.create(pt.x, pt.y, 0, 0, dur)
        BlzSetUnitSkin(dummy.unit, GetUnitTypeId(guy))
        SetUnitVertexColor(dummy.unit, BlzGetUnitIntegerField(dummy.unit, UNIT_IF_TINTING_COLOR_RED), BlzGetUnitIntegerField(dummy.unit, UNIT_IF_TINTING_COLOR_GREEN), BlzGetUnitIntegerField(dummy.unit, UNIT_IF_TINTING_COLOR_BLUE), 0)
        Fade(dummy.unit, dur, false)
        BlzSetUnitFacingEx(dummy.unit, 270.)
        PauseUnit(dummy.unit, true)
        pt.timer:callDelayed(dur, ShadowStepTeleport, pt)
        if dur >= 4 then
           PlaySound("Sound\\Interface\\CreepAggroWhat1.flac")
            if CHAOS_MODE then
                DisplayTimedTextToForce(FORCE_PLAYING, 20., "|cffffcc00Legion:|r There is no escape " .. User[pid - 1].nameColored .. "..")
            else
                DisplayTimedTextToForce(FORCE_PLAYING, 20., "|cffffcc00Death Knight:|r Prepare yourself " .. User[pid - 1].nameColored .. "!")
            end
        end
    end
end

---@return boolean
function ShadowStepExpire()
    local ug  = CreateGroup()
    local g   = CreateGroup()
    local guy = (CHAOS_MODE and BossTable[BOSS_LEGION].unit) or BossTable[BOSS_DEATH_KNIGHT].unit

    GroupEnumUnitsInRect(ug, MAIN_MAP.rect, Condition(ischar))
    GroupEnumUnitsInRect(g, gg_rct_NoSin, Condition(ischar))

    for i = BOSS_OFFSET, #BossTable do
        GroupEnumUnitsInRangeEx(BOSS_ID, g, GetLocationX(BossTable[i].loc), GetLocationY(BossTable[i].loc), 2000., Condition(ischar))
    end

    if BlzGroupGetSize(g) > 0 then
        BlzGroupRemoveGroupFast(g, ug)
    end

    GroupEnumUnitsInRange(g, GetUnitX(guy), GetUnitY(guy), 1500., Condition(ischar))

    --if there are no nearby players and there exists a valid player to teleport to on the map
    if BlzGroupGetSize(ug) > 0 and BlzGroupGetSize(g) == 0 then
        guy = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))

        if guy then
            local sfx = AddSpecialEffect("war3mapImported\\BlackSmoke.mdx", GetUnitX(guy), GetUnitY(guy))
            BlzSetSpecialEffectTimeScale(sfx, 0.75)
            BlzSetSpecialEffectScale(sfx, 1.)
            TimerQueue:callDelayed(3., DestroyEffect, sfx)

            BossTeleport(guy, 4.)
        end
    end

    DestroyGroup(ug)
    DestroyGroup(g)

    return false
end

---@type fun(pt: PlayerTimer)
function DeathStrike(pt)
    SetUnitAnimation(pt.source, "death")
    DestroyEffect(AddSpecialEffect("NecroticBlast.mdx", pt.x, pt.y))

    local ug = CreateGroup()

    MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 180., Condition(FilterEnemy))

    for target in each(ug) do
        DamageTarget(BossTable[BOSS_DEATH_KNIGHT].unit, target, 15000., ATTACK_TYPE_NORMAL, MAGIC, DEATHSTRIKE.tag)
    end

    DestroyGroup(ug)

    pt:destroy()
end

--Arkaden

function FrostNova()
    if UnitAlive(BossTable[BOSS_ARKADEN].unit) then
        local ug = CreateGroup()

        MakeGroupInRange(BOSS_ID, ug, GetUnitX(BossTable[BOSS_ARKADEN].unit), GetUnitY(BossTable[BOSS_ARKADEN].unit), 700., Condition(FilterEnemy))
        DestroyEffect(AddSpecialEffect("war3mapImported\\FrostNova.mdx", GetUnitX(BossTable[BOSS_ARKADEN].unit), GetUnitY(BossTable[BOSS_ARKADEN].unit)))

        for target in each(ug) do
            Freeze:add(BossTable[BOSS_ARKADEN].unit, target):duration(3.)
            DamageTarget(BossTable[BOSS_ARKADEN].unit, target, 15000., ATTACK_TYPE_NORMAL, MAGIC, "Frost Nova")
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

    for target in each(ug) do
        DamageTarget(BossTable[BOSS_LIFE].unit, target, 25000., ATTACK_TYPE_NORMAL, MAGIC, "Sun Strike")
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

        for target in each(ug) do
            HP(holyward, target, 100000)
            HolyBlessing:add(target, target):duration(30.)
            TimerQueue:callDelayed(2, DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", target, "origin"))
        end

        DestroyGroup(ug)
    end
end

---@type fun(pt: PlayerTimer)
function GhostShroud(pt)
    if IsUnitType(BossTable[BOSS_KNOWLEDGE].unit, UNIT_TYPE_ETHEREAL) then
        local ug = CreateGroup()
        MakeGroupInRange(BOSS_ID, ug, GetUnitX(BossTable[BOSS_KNOWLEDGE].unit), GetUnitY(BossTable[BOSS_KNOWLEDGE].unit), 500., Condition(FilterEnemy))

        for target in each(ug) do
            local dmg = math.max(0, GetHeroInt(BossTable[BOSS_KNOWLEDGE].unit, true) - GetHeroInt(target, true))

            DamageTarget(BossTable[BOSS_KNOWLEDGE].unit, target, dmg, ATTACK_TYPE_NORMAL, MAGIC, "Ghost Shroud")
        end

        DestroyGroup(ug)
    else
        pt:destroy()
    end
end

--Absolute Horror

---@type fun(pt: PlayerTimer)
function TrueStealth(pt)
    local ug = CreateGroup()

    MakeGroupInRange(BOSS_ID, ug, pt.x, pt.y, 400., Condition(FilterEnemy))

    UnitRemoveAbility(BossTable[BOSS_ABSOLUTE_HORROR].unit, FourCC('Amrf'))
    UnitRemoveAbility(BossTable[BOSS_ABSOLUTE_HORROR].unit, FourCC('A043'))
    UnitRemoveAbility(BossTable[BOSS_ABSOLUTE_HORROR].unit, FourCC('BOwk'))
    UnitRemoveAbility(BossTable[BOSS_ABSOLUTE_HORROR].unit, FourCC('Avul'))
    SetUnitXBounded(BossTable[BOSS_ABSOLUTE_HORROR].unit, pt.x)
    SetUnitYBounded(BossTable[BOSS_ABSOLUTE_HORROR].unit, pt.y)
    SetUnitAnimation(BossTable[BOSS_ABSOLUTE_HORROR].unit, "Attack Slam")

    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y))

    local count = BlzGroupGetSize(ug)

    if count > 0 then
        local target = BlzGroupUnitAt(ug, GetRandomInt(0, count - 1))
        local heal = GetWidgetLife(target)
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\Stampede\\StampedeMissileDeath.mdl", target, "origin"))
        DamageTarget(BossTable[BOSS_ABSOLUTE_HORROR].unit, target, 80000. + BlzGetUnitMaxHP(target) * 0.3, ATTACK_TYPE_NORMAL, MAGIC, "True Stealth")
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAuraTarget.mdl", BossTable[BOSS_ABSOLUTE_HORROR].unit, "chest"))
        heal = math.max(0, heal - GetWidgetLife(target))
        SetUnitState(BossTable[BOSS_ABSOLUTE_HORROR].unit, UNIT_STATE_LIFE, GetWidgetLife(BossTable[BOSS_ABSOLUTE_HORROR].unit) + heal)
    end

    pt:destroy()

    DestroyGroup(ug)
end

--Orsted

function ScreamOfDespair()
    if UnitAlive(BossTable[BOSS_ORSTED].unit) then
        local ug = CreateGroup()

        SpellCast(BossTable[BOSS_ORSTED].unit, 0, 1.8, 5, 1.2)
        MakeGroupInRange(BOSS_ID, ug, GetUnitX(BossTable[BOSS_ORSTED].unit), GetUnitY(BossTable[BOSS_ORSTED].unit), 500., Condition(FilterEnemy))
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Other\\HowlOfTerror\\HowlCaster.mdl", BossTable[BOSS_ORSTED].unit, "origin"))

        for target in each(ug) do
            Fear:add(BossTable[BOSS_ORSTED].unit, target):duration(6.)
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

        for target in each(ug) do
            DamageTarget(BossTable[BOSS_ORSTED].unit, target, BlzGetUnitMaxHP(target) * 0.05, ATTACK_TYPE_NORMAL, PURE, "Cloud of Despair")
        end

        DestroyGroup(ug)

        pt.timer:callDelayed(1., CloudOfDespair, pt)
    else
        pt:destroy()
    end
end

--Slaughter Queen

function ResetSlaughterMS()
    SetUnitMoveSpeed(BossTable[BOSS_SLAUGHTER_QUEEN].unit, 300)
end

function SlaughterAvatar()
    IssueImmediateOrder(BossTable[BOSS_SLAUGHTER_QUEEN].unit, "avatar")
    SetUnitMoveSpeed(BossTable[BOSS_SLAUGHTER_QUEEN].unit, 270)
    TimerQueue:callDelayed(10., ResetSlaughterMS)
end

--Dark Soul

---@type fun(pt: PlayerTimer)
function DarkSoulAbility(pt)
    pt.dur = pt.dur - 1

    if pt.dur == 0 then
        --freeze
        if pt.spell == 3 then
            local ug = CreateGroup()

            MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), 300., Condition(FilterEnemy))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(pt.source), GetUnitY(pt.source)))

            for target in each(ug) do
                Stun:add(pt.source, target):duration(5.)
            end

            DestroyGroup(ug)
        --mortify
        elseif pt.spell == 1 then
            BossPlusSpell(pt.source, 1000000, 1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", "Mortify")
        --terrify
        elseif pt.spell == 2 then
            BossXSpell(pt.source, 1000000,1, "Abilities\\Spells\\Undead\\AnimateDead\\AnimateDeadTarget.mdl", "Terrify")
        end
    end

    if not UnitAlive(pt.source) or pt.dur < 0 or pt.spell == 0 then
        pt:destroy()
    else
        pt.timer:callDelayed(0.5, DarkSoulAbility, pt)
    end
end

--Satan

---@type fun(x: number, y: number)
function SatanFlameStrike(x, y)
    local dummy = Dummy.create(GetUnitX(BossTable[BOSS_SATAN].unit), GetUnitY(BossTable[BOSS_SATAN].unit), FourCC('A0DN'), 1)

    SetUnitOwner(dummy.unit, pboss, false)
    IssuePointOrder(dummy.unit, "flamestrike", x, y)
end

--Thanatos

---@type fun(pt: PlayerTimer)
function ThanatosAbility(pt)
    if UnitAlive(pt.source) then
        if pt.spell == 1 then
            local ug = CreateGroup()
            GroupEnumUnitsInRange(ug, pt.x, pt.y, 200., Condition(ishostileEnemy))

            SetUnitXBounded(pt.source, pt.x)
            SetUnitYBounded(pt.source, pt.y)
            SetUnitAnimation(pt.source, "attack")

            for target in each(ug) do
                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\Coup de Grace.mdx", target, "chest"))
                DamageTarget(pt.source, target, 1500000, ATTACK_TYPE_NORMAL, MAGIC, "Swift Hunt")
            end

            DestroyGroup(ug)
        elseif pt.spell == 2 then
            BossBlastTaper(pt.source, 1000000, FourCC('A0A4'), 750, "Death Beckons")
        end
    end

    pt:destroy()
end

--Pure Existence

---@type fun(pt: PlayerTimer)
function ExistenceAbility(pt)
    pt.dur = pt.dur - 1

    if pt.dur == 3 then
        if pt.spell == 3 then
            BossInnerRing(pt.source, 1000000, 2, 400, "Abilities\\Spells\\Undead\\FrostNova\\FrostNovaTarget.mdl", "Implosion")
        elseif pt.spell == 4 then
            BossOuterRing(pt.source, 500000, 2, 400, 900, "war3mapImported\\NeutralExplosion.mdx", "Explosion")
        end
    elseif pt.dur == 2 then
        if pt.spell == 1 then
            BossXSpell(pt.source, 500000, 2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl", "Extermination")
        end
    elseif pt.dur == 1 then
        if pt.spell == 2 then
            BossBlastTaper(pt.source, 1500000, FourCC('A0AB'), 800, "Devastation")
        end
    elseif pt.dur == 0 then
        if pt.spell == 1 then
            BossPlusSpell(pt.source, 500000, 2, "Abilities\\Spells\\Undead\\ReplenishMana\\ReplenishManaCasterOverhead.mdl", "Extermination")
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
    if UnitAlive(BossTable[BOSS_LEGION].unit) then
        for _ = 0, 6 do
            UnitAddItemById(BossTable[BOSS_LEGION].unit, FourCC('I06V'))
        end
    end
end

---@return boolean
function PositionLegionIllusions()
    local u = GetSummonedUnit()

    if GetUnitTypeId(u) == FourCC('H04R') and IsUnitIllusion(u) then
        GroupAddUnit(legionillusions, u)
        SetUnitPathing(u, false)
        UnitAddAbility(u, FourCC('Amrf'))
        RemoveItem(UnitItemInSlot(u, 0))
        RemoveItem(UnitItemInSlot(u, 1))
        RemoveItem(UnitItemInSlot(u, 2))
        RemoveItem(UnitItemInSlot(u, 3))
        RemoveItem(UnitItemInSlot(u, 5))
        RemoveItem(UnitItemInSlot(u, 5))
    end

    if BlzGroupGetSize(legionillusions) >= 7 then
        local j = 0 --adjusts distance if valid spot cannot be found
        local count = 0
        local x2 = 0.
        local y2 = 0.
        local x = GetLocationX(BossTable[BOSS_LEGION].loc)
        local y = GetLocationY(BossTable[BOSS_LEGION].loc)
        local rand = GetRandomInt(0, 359)

        repeat
            x2 = x + (700 - j) * Cos(bj_DEGTORAD * rand)
            y2 = y + (700 - j) * Sin(bj_DEGTORAD * rand)

            rand = GetRandomInt(0, 359)
            count = count + 1

            if count > 150 then
                j = j + 50
            end
        until IsTerrainWalkable(x2, y2) and RectContainsCoords(gg_rct_NoSin, x2, y2) == false

        SetUnitXBounded(BossTable[BOSS_LEGION].unit, x2)
        SetUnitYBounded(BossTable[BOSS_LEGION].unit, y2)
        SetUnitPathing(BossTable[BOSS_LEGION].unit, false)
        SetUnitPathing(BossTable[BOSS_LEGION].unit, true)
        BlzSetUnitFacingEx(BossTable[BOSS_LEGION].unit, bj_RADTODEG * Atan2(y2 - y, x2 - x))
        IssuePointOrder(BossTable[BOSS_LEGION].unit, "attack", x, y)

        count = 1
        for target in each(legionillusions) do
            x2 = x + (700 - j) * Cos(bj_DEGTORAD * (rand + count * 45))
            y2 = y + (700 - j) * Sin(bj_DEGTORAD * (rand + count * 45))

            SetUnitXBounded(target, x2)
            SetUnitYBounded(target, y2)
            BlzSetUnitFacingEx(target, bj_RADTODEG * Atan2(y2 - y, x2 - x))
            IssuePointOrder(target, "attack", x, y)

            count = count + 1
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
            DamageTarget(BossTable[BOSS_XALLARATH].unit, target, pt.dmg, ATTACK_TYPE_NORMAL, MAGIC, "Fireball")

            pt.dur = 0.
        end

        DestroyGroup(ug)

        pt.timer:callDelayed(FPS_32, FireballProjectile, pt)
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
            pt2.source = Dummy.create(x, y, 0, 0, 21.).unit
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
    local ug   = CreateGroup()
    local x    = GetUnitX(pt.source) ---@type number 
    local y    = GetUnitY(pt.source) ---@type number 
    local size = 0 ---@type integer 

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
                IssueImmediateOrderById(pt.source, ORDER_ID_STOP)
                UnitSetBonus(pt.source, BONUS_ATTACK_SPEED, -8.)
                BlzStartUnitAbilityCooldown(pt.source, FourCC('A02G'), 0.001)
            else
                pt.time = pt.time + FPS_32
                MoveLightningEx(pt.lfx, false, x, y, BlzGetLocalUnitZ(pt.source) + GetUnitFlyHeight(pt.source) + 50., GetUnitX(pt.target), GetUnitY(pt.target), BlzGetUnitZ(pt.target) + 50.)

                if BlzGetUnitAbilityCooldownRemaining(pt.source, FourCC('A02G')) <= 0. then
                    SpellCast(pt.source, FourCC('A02G'), 5., 0, 1.)
                end

                if pt.time >= 5 then
                    DamageTarget(pt.target, pt.source, 0.001, ATTACK_TYPE_NORMAL, PHYSICAL, "Focus Fire")
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
    if UnitAlive(BossTable[BOSS_XALLARATH].unit) then
        local ug = CreateGroup()

        GroupEnumUnitsInRange(ug, GetUnitX(BossTable[BOSS_XALLARATH].unit), GetUnitY(BossTable[BOSS_XALLARATH].unit), 400., Condition(isplayerunit))

        for target in each(ug) do
            if IsUnitInGroup(target, pt.ug) == false then
                GroupAddUnit(pt.ug, target)
                DamageTarget(BossTable[BOSS_XALLARATH].unit, target, 50000000., ATTACK_TYPE_NORMAL, MAGIC, "Unstoppable Force")
            end
        end

        pt.angle = Atan2(pt.y - GetUnitY(BossTable[BOSS_XALLARATH].unit), pt.x - GetUnitX(BossTable[BOSS_XALLARATH].unit))

        if IsUnitInRangeXY(BossTable[BOSS_XALLARATH].unit, pt.x, pt.y, 125.) or DistanceCoords(pt.x, pt.y, GetUnitX(BossTable[BOSS_XALLARATH].unit), GetUnitY(BossTable[BOSS_XALLARATH].unit)) > 2500. then
            SetUnitPathing(BossTable[BOSS_XALLARATH].unit, true)
            PauseUnit(BossTable[BOSS_XALLARATH].unit, false)
            IssueImmediateOrder(BossTable[BOSS_XALLARATH].unit, "stand")
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x + 200, pt.y))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x - 200, pt.y))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y + 200))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", pt.x, pt.y - 200))

            pt:destroy()
        else
            SetUnitPathing(BossTable[BOSS_XALLARATH].unit, false)
            SetUnitXBounded(BossTable[BOSS_XALLARATH].unit, GetUnitX(BossTable[BOSS_XALLARATH].unit) + 55 * Cos(pt.angle))
            SetUnitYBounded(BossTable[BOSS_XALLARATH].unit, GetUnitY(BossTable[BOSS_XALLARATH].unit) + 55 * Sin(pt.angle))
        end

        DestroyGroup(ug)
    else
        SetUnitPathing(BossTable[BOSS_XALLARATH].unit, true)
        PauseUnit(BossTable[BOSS_XALLARATH].unit, false)
        IssueImmediateOrder(BossTable[BOSS_XALLARATH].unit, "stand")
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

---@type fun(x: number, y: number, height: number)
function SpawnForgottenArcher(x, y, height)
    local pt = TimerList[BOSS_ID]:add()
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

---@type fun(x: number, y: number, height: number)
function SpawnForgottenMage(x, y, height)
    local pt = TimerList[BOSS_ID]:add()
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

---@type fun(source: unit, target: unit)
function BossSpellCasting(source, target)
    local pt ---@type PlayerTimer 
    local ug = CreateGroup()

    --prechaos bosses
    --hellfire magi
    if not CHAOS_MODE then
        if target == BossTable[BOSS_HELLFIRE].unit and UnitAlive(BossTable[BOSS_HELLFIRE].unit) then
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
        elseif target == BossTable[BOSS_VASHJ].unit and UnitAlive(BossTable[BOSS_VASHJ].unit) then
            --tornado storm
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A085')) <= 0 then
                SpellCast(target, FourCC('A085'), 1.5, 5, 1.)
                local dummy = CreateUnit(Player(PLAYER_BOSS), FourCC('n001'), GetUnitX(target), GetUnitY(target), 0.)
                IssuePointOrder(dummy, "move", GetRandomReal(GetUnitX(target) - 250, GetUnitX(target) + 250), GetRandomReal(GetUnitY(target) - 250, GetUnitY(target) + 250))
                TimerQueue:callDelayed(40., RemoveUnit, dummy)
                dummy = CreateUnit(Player(PLAYER_BOSS), FourCC('n001'), GetUnitX(target), GetUnitY(target), 0.)
                IssuePointOrder(dummy, "move", GetRandomReal(GetUnitX(target) - 250, GetUnitX(target) + 250), GetRandomReal(GetUnitY(target) - 250, GetUnitY(target) + 250))
                TimerQueue:callDelayed(40., RemoveUnit, dummy)
            end

        --tauren
        elseif target == BossTable[BOSS_TAUREN].unit and UnitAlive(BossTable[BOSS_TAUREN].unit) then
            --shockwave
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02L')) <= 0 and UnitDistance(source, target) < 600 then
                IssuePointOrder(BossTable[BOSS_TAUREN].unit, "carrionswarm", GetUnitX(source), GetUnitY(source))
            --war stomp
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A09J')) <= 0 and UnitDistance(source, target) < 300. then
                SpellCast(target, FourCC('A09J'), 1., 4, 1.)
                pt = TimerList[BOSS_ID]:add()
                pt.dmg = 4000.
                pt.source = target
                pt.dur = 8.
                pt.tag = "War Stomp"
                pt.timer:callDelayed(1., StompPeriodic, pt)
                FloatingTextUnit(pt.tag, BossTable[BOSS_TAUREN].unit, 2., 60., 0, 12, 255, 255, 255, 0, true)
            end

        --mystic
        elseif target == BossTable[BOSS_MYSTIC].unit and UnitAlive(BossTable[BOSS_MYSTIC].unit) then
            if UnitDistance(target, source) < 800. then
                --mana drain
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01Z')) <= 0 then
                    SpellCast(target, FourCC('A01Z'), 1.5, 4, 1.)
                    MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 800., Condition(FilterEnemy))
                    for u in each(ug) do
                        --vampire mana drain exception
                        if not ManaDrainDebuff:has(u, u) and GetUnitTypeId(u) ~= HERO_VAMPIRE then
                            ManaDrainDebuff:add(u, u):duration(9999.)
                        end
                    end
                end
            end

        --dwarf
        elseif target == BossTable[BOSS_DWARF].unit and UnitAlive(BossTable[BOSS_DWARF].unit) then
            if UnitDistance(target, source) < 300. then
                --avatar
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0DV')) <= 0 then
                    IssueImmediateOrder(BossTable[BOSS_DWARF].unit, "avatar")
                --thunder clap
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0A2')) <= 0 then
                    SpellCast(target, FourCC('A0A2'), 1., 4, 1.)
                    pt = TimerList[BOSS_ID]:add()
                    pt.dmg = 8000.
                    pt.source = target
                    pt.dur = 8.
                    pt.tag = "Thunder Clap"
                    pt.timer:callDelayed(1., StompPeriodic, pt)
                    FloatingTextUnit(pt.tag, BossTable[BOSS_DWARF].unit, 2., 60., 0, 12, 0, 255, 255, 0, true)
                end
            end

        --death knight
        elseif target == BossTable[BOSS_DEATH_KNIGHT].unit and UnitAlive(BossTable[BOSS_DEATH_KNIGHT].unit) then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0AO')) <= 0 and UnitDistance(source, target) > 250. then
                BlzStartUnitAbilityCooldown(target, FourCC('A0AO'), 20.)
                BossTeleport(source, 1.5)
            --death strikes
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A088')) <= 0 then
                SpellCast(target, FourCC('A088'), 0.7, 3, 1.)
                MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 1250., Condition(FilterEnemy))
                FloatingTextUnit("Death Strikes", BossTable[BOSS_DEATH_KNIGHT].unit, 2., 60., 0, 12, 255, 255, 255, 0, true)
                local count = 0
                for u in each(ug) do
                    if count >= 3 then break end
                    pt = TimerList[BOSS_ID]:add()
                    pt.x = GetUnitX(u)
                    pt.y = GetUnitY(u)
                    pt.source = Dummy.create(pt.x, pt.y, 0, 0).unit
                    SetUnitScale(pt.source, 4., 4., 4.)
                    BlzSetUnitSkin(pt.source, FourCC('e01F'))
                    pt.timer:callDelayed(3., DeathStrike, pt)
                    count = count + 1
                end
            end

        --vengeful test paladin
        elseif target == BossTable[BOSS_PALADIN].unit and UnitAlive(BossTable[BOSS_PALADIN].unit) then
            IssueTargetOrder(target, "holybolt", target)

        --arkaden
        elseif GetType(target) == BossTable[BOSS_ARKADEN].id and UnitAlive(BossTable[BOSS_ARKADEN].unit) then
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

                for i = 0, 4 do
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl", GetUnitX(target) + 80. * Cos(bj_PI * i * 0.4), GetUnitY(target) + 80. * Sin(bj_PI * i * 0.4)))
                    bj_lastCreatedUnit = CreateUnit(Player(PLAYER_BOSS), FourCC('n00E'), GetUnitX(target) + 80. * Cos(bj_PI * i * 0.4), GetUnitY(target) + 80. * Sin(bj_PI * i * 0.4), GetUnitFacing(target))
                    SpellCast(bj_lastCreatedUnit, 0, 1.5, 9, 1.)
                    UnitApplyTimedLife(bj_lastCreatedUnit, FourCC('BTLF'), 30.)
                end
            end

        --Goddesses
        elseif (target == BossTable[BOSS_HATE].unit or target == BossTable[BOSS_LOVE].unit or target == BossTable[BOSS_KNOWLEDGE].unit) then
            --Love Holy Ward
            if UnitAlive(BossTable[BOSS_LOVE].unit) and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 then
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
            if target == BossTable[BOSS_KNOWLEDGE].unit and UnitAlive(target) and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 and not Unit[target].casting then
                --ghost shroud
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0A8')) <= 0 then
                    SpellCast(target, FourCC('A0A8'), 0.25, 8, 1.5)
                    Dummy.create(GetUnitX(target), GetUnitY(target), FourCC('A0A8'), 1):cast(pboss, "banish", target)
                    pt = TimerList[BOSS_ID]:add()
                    pt.timer:callPeriodically(1., nil, GhostShroud, pt)
                --silence
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05B')) <= 0 then
                    SpellCast(target, FourCC('A05B'), 1., 8, 1.5)

                    MakeGroupInRange(BOSS_ID, ug, GetUnitX(source), GetUnitY(source), 1000., Condition(FilterEnemy))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Silence\\SilenceAreaBirth.mdl", GetUnitX(source), GetUnitY(source)))

                    for target in each(ug) do
                        Silence:add(BossTable[BOSS_KNOWLEDGE].unit, target):duration(10.)
                    end
                --disarm
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05W')) <= 0 then
                    SpellCast(target, FourCC('A05W'), 1., 8, 1.5)
                    Disarm:add(target, source):duration(6.)
                end
            end

        --Life
        --sun strike
        elseif (target == BossTable[BOSS_LIFE].unit) and UnitAlive(target) and (GetWidgetLife(target) / BlzGetUnitMaxHP(target)) <= 0.9 and BlzGetUnitAbilityCooldownRemaining(target, FourCC('A08M')) <= 0 then
            BlzStartUnitAbilityCooldown(target, FourCC('A08M'), 20.)

            GroupEnumUnitsInRange(ug, GetUnitX(target), GetUnitY(target), 1250., Condition(isplayerAlly))

            local count = 0

            for u in each(ug) do
                if count >= 3 then break end
                local dummy = Dummy.create(GetUnitX(u), GetUnitY(u), 0, 0, 3.).unit
                SetUnitScale(dummy, 4., 4., 4.)
                BlzSetUnitFacingEx(dummy, 270)
                BlzSetUnitSkin(dummy, FourCC('e01F'))
                SetUnitVertexColor(dummy, 200, 200, 0, 255)

                pt = TimerList[BOSS_ID]:add()
                pt.x = GetUnitX(u)
                pt.y = GetUnitY(u)
                pt.timer:callDelayed(3., SunStrike, pt)

                count = count + 1
            end
        end
    else

    --chaos bosses
        --Demon Prince
        if target == BossTable[BOSS_DEMON_PRINCE].unit and UnitAlive(BossTable[BOSS_DEMON_PRINCE].unit) and (GetWidgetLife(BossTable[BOSS_DEMON_PRINCE].unit) / BlzGetUnitMaxHP(BossTable[BOSS_DEMON_PRINCE].unit)) <= 0.5 then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0AX')) <= 0 then
                BlzStartUnitAbilityCooldown(target, FourCC('A0AX'), 60.)
                DemonPrinceBloodlust:add(target, target):duration(60.)
                Dummy.create(GetUnitX(target), GetUnitY(target), FourCC('A041'), 1):cast(pboss, "bloodlust", target)
            end

        --Absolute Horror
        elseif target == BossTable[BOSS_ABSOLUTE_HORROR].unit and UnitAlive(BossTable[BOSS_ABSOLUTE_HORROR].unit) and (GetWidgetLife(BossTable[BOSS_ABSOLUTE_HORROR].unit) / BlzGetUnitMaxHP(BossTable[BOSS_ABSOLUTE_HORROR].unit)) <= 0.8 then
            if GetRandomInt(0, 99) < 10 and BlzGetUnitAbilityCooldownRemaining(target, FourCC('A0AC')) <= 0 then
                MakeGroupInRange(BOSS_ID, ug, GetUnitX(target), GetUnitY(target), 1500., Condition(FilterEnemy))

                local u = FirstOfGroup(ug)
                if u then
                    BlzStartUnitAbilityCooldown(target, FourCC('A0AC'), 10.)

                    FloatingTextUnit("True Stealth", BossTable[BOSS_ABSOLUTE_HORROR].unit, 1.75, 100, 0, 12, 90, 30, 150, 0, true)
                    UnitRemoveBuffs(BossTable[BOSS_ABSOLUTE_HORROR].unit, false, true)
                    UnitAddAbility(BossTable[BOSS_ABSOLUTE_HORROR].unit, FourCC('Avul'))
                    UnitAddAbility(BossTable[BOSS_ABSOLUTE_HORROR].unit, FourCC('A043'))
                    IssueImmediateOrder(BossTable[BOSS_ABSOLUTE_HORROR].unit, "windwalk")

                    local angle = Atan2(GetUnitY(u) - GetUnitY(BossTable[BOSS_ABSOLUTE_HORROR].unit), GetUnitX(u) - GetUnitX(BossTable[BOSS_ABSOLUTE_HORROR].unit))
                    UnitAddAbility(BossTable[BOSS_ABSOLUTE_HORROR].unit, FourCC('Amrf'))
                    IssuePointOrder(BossTable[BOSS_ABSOLUTE_HORROR].unit, "move", GetUnitX(u) + 300 * Cos(angle), GetUnitY(u) + 300 * Sin(angle))
                    pt = TimerList[BOSS_ID]:add()
                    pt.x = GetUnitX(u) + 150 * Cos(angle)
                    pt.y = GetUnitY(u) + 150 * Sin(angle)
                    pt.timer:callDelayed(2., TrueStealth, pt)
                end
            end
        --Orsted
        elseif target == BossTable[BOSS_ORSTED].unit and UnitAlive(target) then
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

                FloatingTextUnit("Scream of Despair", BossTable[BOSS_ORSTED].unit, 3, 100, 0, 13, 255, 255, 255, 0, true)

                TimerQueue:callDelayed(2, ScreamOfDespair)
            end

        --Slaughter
        elseif target == BossTable[BOSS_SLAUGHTER_QUEEN].unit and UnitAlive(target) then
            SetUnitAbilityLevel(BossTable[BOSS_SLAUGHTER_QUEEN].unit, FourCC('A064'), HARD_MODE + 1)
            SetUnitAbilityLevel(BossTable[BOSS_SLAUGHTER_QUEEN].unit, FourCC('A040'), HARD_MODE + 1)

            if GetRandomInt(0, 99) < 13 and BlzGetUnitAbilityCooldownRemaining(BossTable[BOSS_SLAUGHTER_QUEEN].unit, FourCC('A040')) <= 0 then
                SpellCast(target, FourCC('A040'), 0., -1, 1.)
                FloatingTextUnit("Avatar", BossTable[BOSS_SLAUGHTER_QUEEN].unit, 3, 100, 0, 13, 255, 255, 255, 0, true)
                TimerQueue:callDelayed(2., SlaughterAvatar)
            end

        --Dark Soul
        elseif target == BossTable[BOSS_DARK_SOUL].unit and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A03M')) <= 0 then
                BlzStartUnitAbilityCooldown(target, FourCC('A03M'), 5.)
                BlzStartUnitAbilityCooldown(target, FourCC('A05U'), 5.)
                pt = TimerList[BOSS_ID]:add()
                pt.source = target
                pt.dur = 4.
                if GetRandomInt(1, 2) == 1 then
                    FloatingTextUnit("+ MORTIFY +", target, 3, 70, 0, 11, 255, 255, 255, 0, true)
                    pt.spell = 1
                else
                    FloatingTextUnit("x TERRIFY x", target, 3, 70, 0, 11, 255, 255, 255, 0, true)
                    pt.spell = 2
                end

                pt.timer:callDelayed(0.5, DarkSoulAbility, pt)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02Q')) <= 0 then
                SpellCast(target, FourCC('A02Q'), 2., 5, 1.)
                pt = TimerList[BOSS_ID]:add()
                pt.source = target
                pt.dur = 4.
                FloatingTextUnit("||||| FREEZE |||||", target, 3, 70, 0, 11, 255, 255, 255, 0, true)
                pt.spell = 3
                pt.timer:callDelayed(0.5, DarkSoulAbility, pt)
            end

        --Satan
        elseif target == BossTable[BOSS_SATAN].unit and UnitAlive(target) then
            if GetRandomInt(0, 99) < 10 then
                SatanFlameStrike(GetUnitX(source), GetUnitY(source))
            end

        --Legion
        elseif target == BossTable[BOSS_LEGION].unit and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A05I')) <= 0 and UnitDistance(source, target) > 250. then --shadow step
                SpellCast(target, FourCC('A05I'), 0., 1, 1.)
                BossTeleport(source, 1.5)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A08C')) <= 0 and TimerList[BOSS_ID]:has(FourCC('tpin')) == false and UnitDistance(source, target) < 800 then
                SpellCast(target, FourCC('A08C'), 0.5, 12, 1.)
                TimerQueue:callDelayed(2, DestroyEffect, AddSpecialEffect("Abilities\\Spells\\Orc\\MirrorImage\\MirrorImageCaster.mdl", GetUnitX(BossTable[BOSS_LEGION].unit), GetUnitY(BossTable[BOSS_LEGION].unit)))
                RemoveLocation(BossTable[BOSS_LEGION].loc)
                BossTable[BOSS_LEGION].loc = Location(GetUnitX(source), GetUnitY(source))
                TimerQueue:callDelayed(0.5, SpawnLegionIllusions)
            end

        --Thanatos
        elseif target == BossTable[BOSS_THANATOS].unit and UnitAlive(target) and not Unit[target].casting then
            if GetRandomInt(0, 99) < 10 then
                if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A023')) <= 0 and UnitDistance(source, target) > 250 then
                    BlzStartUnitAbilityCooldown(target, FourCC('A023'), 10.)
                    pt = TimerList[BOSS_ID]:add()
                    pt.x = GetUnitX(source)
                    pt.y = GetUnitY(source)
                    pt.source = target
                    pt.spell = 1
                    pt.timer:callDelayed(1.5, ThanatosAbility, pt)
                    FloatingTextUnit("Swift Hunt", target, 1, 70, 0, 10, 255, 255, 255, 0, true)
                elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A02P')) <= 0 then
                    SpellCast(target, FourCC('A02P'), 2., 12, 1.)
                    pt = TimerList[BOSS_ID]:add()
                    pt.x = GetUnitX(source)
                    pt.y = GetUnitY(source)
                    pt.source = target
                    pt.spell = 2
                    pt.timer:callDelayed(2.5, ThanatosAbility, pt)
                    FloatingTextUnit("Death Beckons", target, 2, 70, 0, 10, 255, 255, 255, 0, true)
                end
            end

        --Existence
        elseif target == BossTable[BOSS_EXISTENCE].unit and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A07F')) <= 0. then
                local rand = GetRandomInt(1, 4)
                if rand == 1 then
                    FloatingTextUnit("Devastation", target , 3, 70, 0, 12, 255, 40, 40, 0, true)
                elseif rand == 2 then
                    FloatingTextUnit("Extermination", target, 3, 70, 0, 12, 255, 255, 255, 0, true)
                elseif rand == 3 and UnitDistance(source, target) <= 400 then
                    FloatingTextUnit("Implosion", target, 3, 70, 0, 12, 68, 68, 255, 0, true)
                elseif rand == 4 and UnitDistance(source, target) >= 400 then
                    FloatingTextUnit("Explosion", target, 3, 70, 0, 12, 255, 100, 50, 0, true)
                end

                pt = TimerList[BOSS_ID]:add()
                pt.source = target
                pt.dur = 5.
                pt.spell = rand
                SpellCast(target, FourCC('A07F'), 0., -1, 1.)
                SpellCast(target, FourCC('A07Q'), 0., -1, 1.)
                SpellCast(target, FourCC('A073'), 0., -1, 1.)
                SpellCast(target, FourCC('A072'), 1.5, 4, 1.5)
                pt.timer:callDelayed(0.5, ExistenceAbility, pt)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A07X')) <= 0. then
                SpellCast(target, FourCC('A07X'), 1.5, 4, 1.5)
                FloatingTextUnit("Protected Existence", target, 3, 70, 0, 12, 100, 255, 100, 0, true)
                ProtectedExistenceBuff:add(target, target):duration(10.)
            end

        --Xallarath
        elseif target == BossTable[BOSS_XALLARATH].unit and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01I')) <= 0 and GetWidgetLife(target) <= BlzGetUnitMaxHP(target) * 0.5 then
                SpellCast(target, FourCC('A01I'), 0., 3, 1.)
                FloatingTextUnit("Reinforcements", BossTable[BOSS_XALLARATH].unit, 1.75, 100, 0, 12, 255, 0, 0, 0, true)
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
                    FloatingTextUnit("Unstoppable Force", target, 1.75, 100, 0, 12, 255, 0, 0, 0, true)
                    local u = BlzGroupUnitAt(ug, GetRandomInt(0, BlzGroupGetSize(ug) - 1))
                    local dummy = Dummy.create(GetUnitX(u), GetUnitY(u), 0, 0, 4.).unit
                    SetUnitScale(dummy, 10., 10., 10.)
                    BlzSetUnitFacingEx(dummy, 270.)
                    BlzSetUnitSkin(dummy, FourCC('e01F'))
                    SetUnitVertexColor(dummy, 200, 200, 0, 255)
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
        elseif target == BossTable[BOSS_AZAZOTH].unit and UnitAlive(target) and not Unit[target].casting then
            if BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01B')) <= 0 then
                --adjust cooldown based on HP
                BlzSetUnitAbilityCooldown(target, FourCC('A01B'), 0, 15. + R2I(GetWidgetLife(target) / BlzGetUnitMaxHP(target) * 15.))
                pt = TimerList[BOSS_ID]:add()
                pt.dmg = 4000000.
                pt.dur = MathClamp(GetWidgetLife(target) // BlzGetUnitMaxHP(target), 0.35, 0.75)
                pt.angle = GetUnitFacing(BossTable[BOSS_AZAZOTH].unit)
                pt.source = target
                pt.tag = "Astral Devastation"
                FloatingTextUnit(pt.tag, pt.source, 3, 70, 0, 12, 255, 255, 255, 0, true)
                pt.timer:callDelayed(pt.dur, AstralDevastation, pt)
                SpellCast(target, FourCC('A01B'), pt.dur * 4, 4, 1.)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A00K')) <= 0 then
                --adjust cooldown based on HP
                BlzSetUnitAbilityCooldown(target, FourCC('A00K'), 0, 25. + R2I(GetWidgetLife(target) / BlzGetUnitMaxHP(target) * 25.))
                pt = TimerList[BOSS_ID]:add()
                pt.dur = MathClamp(GetWidgetLife(target) // BlzGetUnitMaxHP(target), 0.35, 0.75)
                pt.dmg = 2000000.
                pt.source = target
                pt.tag = "Astral Annihilation"
                FloatingTextUnit(pt.tag, pt.source, 3, 70, 0, 12, 255, 255, 255, 0, true)
                pt.timer:callDelayed(pt.dur, AstralAnnihilation, pt)
                SpellCast(target, FourCC('A00K'), pt.dur * 4, 4, 1.)
            elseif BlzGetUnitAbilityCooldownRemaining(target, FourCC('A01C')) <= 0 then
                SpellCast(target, FourCC('A01C'), 1., 6, 1.)
                FloatingTextUnit("Astral Shield", BossTable[BOSS_AZAZOTH].unit, 3, 70, 0, 12, 255, 255, 255, 0, true)
                AstralShieldBuff:add(BossTable[BOSS_AZAZOTH].unit, BossTable[BOSS_AZAZOTH].unit):duration(13.)
            end
        end
    end

    DestroyGroup(ug)
end

    local t = CreateTrigger()

    TriggerRegisterPlayerUnitEvent(t, pboss, EVENT_PLAYER_UNIT_SUMMON, nil)
    TriggerAddCondition(t, Filter(PositionLegionIllusions))

end, Debug.getLine())
