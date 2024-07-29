--[[
    boss.lua

    This library defines bosses with unique handling of AI, difficulty, respawns, stat tracking, etc.
]]

OnInit.final("Boss", function(Require)
    Require('Items')
    Require('Variables')

    ---@class Boss
    ---@field revive function
    ---@field id integer
    ---@field loc location
    ---@field facing number
    ---@field difficulty integer
    ---@field unit unit
    ---@field name string
    ---@field level integer
    ---@field item integer[]
    ---@field crystal integer
    ---@field leash number
    ---@field total_damage number
    ---@field damage number[]
    ---@field difficulty_vote integer[]
    ---@field first_drop boolean
    Boss = {}
    do
        local thistype = Boss
        local mt = { __index = Boss }

        local function revive_gods()
            local ug = CreateGroup()

            GroupEnumUnitsInRect(ug, gg_rct_Gods_Arena, Filter(isplayerunitRegion))

            for target in each(ug) do
                local pid = GetPlayerId(GetOwningPlayer(target)) + 1

                if target == Hero[pid] then
                    TableRemove(GODS_GROUP, GetOwningPlayer(target))
                    MoveHeroLoc(pid, TOWN_CENTER)
                else
                    SetUnitPositionLoc(target, TOWN_CENTER)
                end
            end

            DestroyGroup(ug)

            RemoveUnit(power_crystal)

            Boss[BOSS_LIFE]:revive()

            PauseUnit(Boss[BOSS_LIFE].unit, true)
            ShowUnit(Boss[BOSS_LIFE].unit, false)

            Boss[BOSS_HATE]:revive()
            Boss[BOSS_LOVE]:revive()
            Boss[BOSS_KNOWLEDGE]:revive()

            DeadGods = 0
        end

        local function boss_respawn(uid, flag)
            if flag ~= CHAOS_MODE then
                return
            end

            local index = IsBoss(uid)

            if index then
                -- revive gods
                if uid == Boss[BOSS_LIFE].id then
                    revive_gods()
                    DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" .. Boss[index].name .. " have revived.|r")
                else
                    -- death knight / legion
                    if uid == FourCC('H040') or uid == FourCC('H04R') then
                        local ug = CreateGroup()
                        repeat
                            RemoveLocation(Boss[index].loc)
                            Boss[index].loc = GetRandomLocInRect(MAIN_MAP.rect)
                            GroupEnumUnitsInRangeOfLoc(ug, Boss[index].loc, 4000., Condition(isbase))
                        until IsTerrainWalkable(GetLocationX(Boss[index].loc), GetLocationY(Boss[index].loc)) and BlzGroupGetSize(ug) == 0 and RectContainsLoc(gg_rct_Town_Boundry, Boss[index].loc) == false and RectContainsLoc(gg_rct_Top_of_Town, Boss[index].loc) == false
                        DestroyGroup(ug)
                    elseif uid == Boss[BOSS_AZAZOTH].id then
                        AddItemToStock(god_portal, FourCC('I08T'), 1, 1)
                    end

                    Boss[index]:revive()
                    DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Orc\\Reincarnation\\ReincarnationTarget.mdl", Boss[index].loc))
                end
            end
        end

        local special_case = {
            [FourCC('E00B')] = function()
                DeadGods = DeadGods + 1

                if DeadGods == 3 then --spawn goddess of life
                    if GodsRepeatFlag == false then
                        GodsRepeatFlag = true
                        SetCinematicScene(Boss[BOSS_LIFE].id, GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), "Goddess of Life", "This is your last chance", 6, 5)
                    end

                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(Boss[BOSS_LIFE].unit), GetUnitY(Boss[BOSS_LIFE].unit)))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(Boss[BOSS_LIFE].unit), GetUnitY(Boss[BOSS_LIFE].unit)))
                    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(Boss[BOSS_LIFE].unit), GetUnitY(Boss[BOSS_LIFE].unit)))
                    ShowUnit(Boss[BOSS_LIFE].unit, true)
                    PauseUnit(Boss[BOSS_LIFE].unit, true)
                    UnitAddAbility(Boss[BOSS_LIFE].unit, FourCC('Avul'))
                    UnitAddAbility(Boss[BOSS_LIFE].unit, FourCC('A08L')) --life aura
                    TimerQueue:callDelayed(6., GoddessOfLife)
                end

                return true
            end,

            [FourCC('H04Q')] = function()
                DeadGods = 4
                DisplayTimedTextToForce(FORCE_PLAYING, 10, "You may now -flee.")
                power_crystal = CreateUnit(pfoe, FourCC('h04S'), -2026.936, -27753.830, bj_UNIT_FACING)
                EVENT_ON_DEATH:register_unit_action(power_crystal, BeginChaos)

                return false
            end,
        }

        special_case[FourCC('E00C')] = special_case[FourCC('E00B')]
        special_case[FourCC('E00D')] = special_case[FourCC('E00B')]

        local function spawn_select_difficulty(index, boss, flag)
            if flag ~= CHAOS_MODE then
                return
            end

            local x, y = GetUnitX(boss), GetUnitY(boss)
            local u = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n00B'), x, y, 0.)
            Unit[u].boss = Boss[index]

            SetUnitAnimation(u, "birth")
            TimerQueue:callDelayed(60., RemoveUnit, u)

            RemoveUnit(boss)
        end

        local function on_boss_death(killed, killer)
            local index = IsBoss(killed)
            local uid = GetType(killed)
            local x, y = GetUnitX(killed), GetUnitY(killed)

            -- item drops and material reward
            Boss[index]:reward(index, uid, x, y)

            local U = User.first
            -- print percent contribution
            while U do
                if Boss[index].damage[U.id] > 1. then
                    local percent = Boss[index].damage[U.id] / Boss[index].total_damage * 100.
                    DisplayTimedTextToForce(FORCE_PLAYING, 20., U.nameColored .. " contributed |cffffcc00" .. (percent) .. "\x25|r damage to " .. GetUnitName(killed) .. ".")
                end
                -- reset player damage
                Boss[index].damage[U.id] = 0
                U = U.next
            end

            if CHAOS_LOADING then
                return
            end

            TimerQueue:callDelayed(6., spawn_select_difficulty, index, killed, CHAOS_MODE)

            local delay = BOSS_RESPAWN_TIME

            if IsUnitIdType(uid, UNIT_TYPE_HERO) == false then
                delay = delay // 2
            end

            if special_case[uid] then
                if special_case[uid]() then
                    return
                end
            end

            delay = delay * Boss[index].respawn_modifier

            TimerQueue:callDelayed(delay, boss_respawn, uid, CHAOS_MODE)

            -- reset total damage
            Boss[index].total_damage = 0
        end

        ON_BUY_LOOKUP[FourCC('I05V')] = function(u, b, pid, itm)
            Unit[u].boss:vote(pid, 1)
        end

        ON_BUY_LOOKUP[FourCC('I05W')] = function(u, b, pid, itm)
            Unit[u].boss:vote(pid, 2)
        end

        ---@type fun(index: integer, loc: location, facing: number, id: integer, name: string, level: integer, items: integer[], crystal: integer, leash: number): unit
        function Boss.create(index, loc, facing, id, name, level, items, crystal, leash)
            local self = setmetatable({
                loc = loc,
                facing = facing,
                unit = CreateUnitAtLoc(pboss, id, loc, facing),
                difficulty = 1,
                respawn_modifier = 1,
                id = id,
                name = name,
                level = level,
                item = items,
                crystal = crystal,
                leash = leash,
                total_damage = 0,
                damage = __jarray(0),
                difficulty_vote = {},
                first_drop = true,
            }, mt)

            thistype[index] = self

            -- boss spell casting
            EVENT_ON_STRUCK_FINAL:register_unit_action(self.unit, BossAI)
            EVENT_ON_DEATH:register_unit_action(self.unit, on_boss_death)

            return self.unit
        end

        function thistype:vote(pid, difficulty_level)
            self.difficulty_vote[pid] = difficulty_level
            local U = User.first

            local vote_count = { [1] = 0, [2] = 0 }
            while U do
                local vote = self.difficulty_vote[U.id]
                vote_count[vote] = vote_count[vote] + 1

                U = U.next
            end

            if vote_count[2] > vote_count[1] then
                self.difficulty = 2
                self.respawn_modifier = 0.75
            else
                self.difficulty = 1
                self.respawn_modifier = 1
            end
        end

        ---@type fun(id: integer, chance: integer, x: number, y: number)
        local function boss_drop(id, chance, x, y)
            for _ = 1, Boss[id].difficulty do
                if math.random(0, 99) < chance then
                    local itm = CreateItem(DropTable:pickItem(id), x, y, 600.)
                    itm:lvl(IMaxBJ(0, ItemData[itm.id][ITEM_UPGRADE_MAX] - math.random(ITEM_MIN_LEVEL_VARIANCE, ITEM_MAX_LEVEL_VARIANCE)))
                end
            end
        end

        function thistype:reward(index, id, x, y)
            if self.first_drop then
                self.first_drop = false
                boss_drop(id, Rates[id] + 25, x, y)
            else
                boss_drop(id, Rates[id], x, y)
            end

            local count = Boss[index].crystal * Boss[index].difficulty ---@type integer 

            if count > 0 then
                local U = User.first

                while U do
                    if IsUnitInRangeXY(Hero[U.id], x, y, NEARBY_BOSS_RANGE) and GetHeroLevel(Hero[U.id]) >= Boss[id].level then
                        AddCurrency(U.id, CRYSTAL, count)
                        FloatingTextUnit("+" .. (count) .. (count == 1 and " Crystal" or " Crystals"), Hero[U.id], 2.1, 80, 90, 9, 70, 150, 230, 0, false)
                    end

                    U = U.next
                end
            end
        end

        function thistype:revive()
            self.unit = CreateUnitAtLoc(pboss, self.id, self.loc, self.facing)
            EVENT_ON_STRUCK_FINAL:register_unit_action(self.unit, BossAI)
            EVENT_ON_DEATH:register_unit_action(self.unit, on_boss_death)

            SetHeroLevel(self.unit, self.level, false)
            for j = 1, 6 do
                if self.item[j] ~= 0 then
                    local itm = UnitAddItemById(self.unit, self.item[j])
                    itm:lvl(ItemData[itm.id][ITEM_UPGRADE_MAX])
                end
            end
            if self.difficulty == 2 then
                SetHeroStr(self.unit, GetHeroStr(self.unit, true) * 2, true)
                BlzSetUnitBaseDamage(self.unit, BlzGetUnitBaseDamage(self.unit, 0) * 2 + 1, 0)
                SetWidgetLife(self.unit, GetWidgetLife(self.unit) + BlzGetUnitMaxHP(self.unit) * 0.5) -- heal
                Buff.dispelAll(self.unit)
                Unit[self.unit].mm = 2.
            end
            DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" .. self.name .. " has revived.|r")
        end
    end

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
        local guy = (CHAOS_MODE and Boss[BOSS_LEGION].unit) or Boss[BOSS_DEATH_KNIGHT].unit
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
        local guy = (CHAOS_MODE and Boss[BOSS_LEGION].unit) or Boss[BOSS_DEATH_KNIGHT].unit

        GroupEnumUnitsInRect(ug, MAIN_MAP.rect, Condition(ischar))
        GroupEnumUnitsInRect(g, gg_rct_NoSin, Condition(ischar))

        for i = BOSS_OFFSET, #Boss do
            GroupEnumUnitsInRangeEx(BOSS_ID, g, GetLocationX(Boss[i].loc), GetLocationY(Boss[i].loc), 2000., Condition(ischar))
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

    local illusions = {}

    ---@return boolean
    function PositionLegionIllusions()
        local u = GetSummonedUnit()

        if GetUnitTypeId(u) == FourCC('H04R') and IsUnitIllusion(u) then
            illusions[#illusions + 1] = u
            SetUnitPathing(u, false)
            UnitAddAbility(u, FourCC('Amrf'))
            RemoveItem(UnitItemInSlot(u, 0))
            RemoveItem(UnitItemInSlot(u, 1))
            RemoveItem(UnitItemInSlot(u, 2))
            RemoveItem(UnitItemInSlot(u, 3))
            RemoveItem(UnitItemInSlot(u, 5))
            RemoveItem(UnitItemInSlot(u, 5))
        end

        if #illusions >= 7 then
            local j = 0 --adjusts distance if valid spot cannot be found
            local count = 0
            local x2 = 0.
            local y2 = 0.
            local x = GetLocationX(Boss[BOSS_LEGION].loc)
            local y = GetLocationY(Boss[BOSS_LEGION].loc)
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

            SetUnitXBounded(Boss[BOSS_LEGION].unit, x2)
            SetUnitYBounded(Boss[BOSS_LEGION].unit, y2)
            SetUnitPathing(Boss[BOSS_LEGION].unit, false)
            SetUnitPathing(Boss[BOSS_LEGION].unit, true)
            BlzSetUnitFacingEx(Boss[BOSS_LEGION].unit, bj_RADTODEG * Atan2(y2 - y, x2 - x))
            IssuePointOrder(Boss[BOSS_LEGION].unit, "attack", x, y)

            for i = 1, #illusions do
                local target = illusions[i]
                x2 = x + (700 - j) * Cos(bj_DEGTORAD * (rand + i * 45))
                y2 = y + (700 - j) * Sin(bj_DEGTORAD * (rand + i * 45))

                SetUnitXBounded(target, x2)
                SetUnitYBounded(target, y2)
                BlzSetUnitFacingEx(target, bj_RADTODEG * Atan2(y2 - y, x2 - x))
                IssuePointOrder(target, "attack", x, y)
            end
        end

        return false
    end

    ---@type fun(target: unit, source: unit, amount: table, amount_after_red: number, damage_type: damagetype)
    function BossAI(target, source, amount, amount_after_red, damage_type)
        local pid = GetPlayerId(GetOwningPlayer(source)) + 1
        local index = IsBoss(target)

        -- keep track of boss damage
        Boss[index].damage[pid] = Boss[index].damage[pid] + amount_after_red
        Boss[index].total_damage = Boss[index].total_damage + amount_after_red
    end

    local t = CreateTrigger()

    TriggerRegisterPlayerUnitEvent(t, pboss, EVENT_PLAYER_UNIT_SUMMON, nil)
    TriggerAddCondition(t, Filter(PositionLegionIllusions))

end, Debug and Debug.getLine())
