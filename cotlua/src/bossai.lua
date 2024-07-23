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

    ---@type fun(target: unit, source: unit, amount: table, amount_after_red: number, damage_type: damagetype)
    function BossAI(target, source, amount, amount_after_red, damage_type)
        local pid = GetPlayerId(GetOwningPlayer(source)) + 1
        local index = IsBoss(target)

        -- keep track of boss damage
        BossTable[index].damage[pid] = BossTable[index].damage[pid] + amount_after_red
        BossTable[index].total_damage = BossTable[index].total_damage + amount_after_red
    end

    local t = CreateTrigger()

    TriggerRegisterPlayerUnitEvent(t, pboss, EVENT_PLAYER_UNIT_SUMMON, nil)
    TriggerAddCondition(t, Filter(PositionLegionIllusions))

end, Debug and Debug.getLine())
