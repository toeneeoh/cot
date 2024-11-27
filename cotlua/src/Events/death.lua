--[[
    death.lua

    This library handles death events (i.e. EVENT_PLAYER_UNIT_DEATH or EVENT_UNIT_DEATH)
    and provides related functions and globals
]]

OnInit.final("Death", function(Require)
    Require('DropTable')
    Require('Units')
    Require('Spells')
    Require('Events')

    GHOST_UNITS       = {} ---@type unit[]
    REVIVE_INDICATOR  = {} ---@type effect[] 
    REVIVE_BAR        = {} ---@type effect[] 
    StruggleWaveGroup = CreateGroup()
    ColoWaveGroup     = CreateGroup()

    -- Grave Revive
    local GRAVE_REVIVE = Spell.define('A042', 'A044', 'A045')
    do
        local thistype = GRAVE_REVIVE

        function thistype.preCast(pid, tpid, caster, target, x, y, targetX, targetY)
            if not IsTerrainWalkable(targetX, targetY) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(Player(pid - 1), 0, 0, INVALID_TARGET_MESSAGE)
            end
        end

        function thistype:onCast()
            BlzSetSpecialEffectScale(REVIVE_INDICATOR[self.pid], 0)
            DestroyEffect(REVIVE_INDICATOR[self.pid])
            BlzSetSpecialEffectScale(REVIVE_BAR[self.pid], 0)
            DestroyEffect(REVIVE_BAR[self.pid])
            TimerList[self.pid]:stopAllTimers('dead')

            -- item revival
            if self.sid == FourCC('A042') then
                local itm = GetResurrectionItem(self.pid, false)
                local heal = 0

                if itm then
                    heal = ItemData[itm.id][ITEM_ABILITY] * 0.01

                    -- remove perishable resurrections
                    if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') then
                        itm:consumeCharge()
                    else
                        itm.charges = itm.charges - 1
                    end
                end

                RevivePlayer(self.pid, self.targetX, self.targetY, heal, heal)
            -- pr reincarnation
            elseif self.sid == FourCC('A044') then
                RevivePlayer(self.pid, self.targetX, self.targetY, 1, 1)

                BlzStartUnitAbilityCooldown(Hero[self.pid], REINCARNATION.id, 300.)
            -- high priestess revival
            elseif self.sid == RESURRECTION.spell then
                local heal = 0.4 + 0.2 * GetUnitAbilityLevel(Hero[ResurrectionRevival[self.pid]], RESURRECTION.id)
                RevivePlayer(self.pid, self.targetX, self.targetY, heal, heal)
            end

            -- refund HP cooldown and mana
            if self.sid ~= RESURRECTION.spell and ResurrectionRevival[self.pid] > 0 then
                BlzEndUnitAbilityCooldown(Hero[ResurrectionRevival[self.pid]], RESURRECTION.id)
                SetUnitState(Hero[ResurrectionRevival[self.pid]], UNIT_STATE_MANA, BlzGetUnitMaxMana(Hero[ResurrectionRevival[self.pid]]) * 0.5)
            end

            REINCARNATION.enabled[self.pid] = false
            ResurrectionRevival[self.pid] = 0
            UnitRemoveAbility(self.caster, FourCC('A042'))
            UnitRemoveAbility(self.caster, FourCC('A044'))
            UnitRemoveAbility(self.caster, RESURRECTION.spell)
            SetUnitPosition(self.caster, 30000, 30000)
            ShowUnit(self.caster, false)
        end
    end

---@param pid integer
function DeathHandler(pid)
    local ug = CreateGroup()

    CleanupSummons(pid)
    EVENT_GRAVE_DEATH:trigger(Hero[pid])

    -- struggle
    if IS_IN_STRUGGLE[pid] then
        Struggle_Pcount = Struggle_Pcount - 1
        IS_IN_STRUGGLE[pid] = false
        IS_FLEEING[pid] = false
        ExperienceControl(pid)
        AwardGold(pid, GoldWon_Struggle * 0.1, true)
        if Struggle_Pcount == 0 then --clear struggle
            ClearStruggle()
        end
    -- gods area
    elseif TableHas(GODS_GROUP, pid) then
        TableRemove(GODS_GROUP, pid)
    end

    DestroyGroup(ug)
end

---@type fun(pt: PlayerTimer)
function HeroGraveExpire(pt)
    local pid = pt.pid
    local p    = Player(pid - 1)
    local itm  = GetResurrectionItem(pid, false) ---@type Item?
    local heal = 0. ---@type number 

    if IsUnitHidden(HeroGrave[pid]) == false then
        -- high priestess resurrection
        if ResurrectionRevival[pid] > 0 then
            heal = RESURRECTION.restore(ResurrectionRevival[pid])
            RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        elseif REINCARNATION.enabled[pid] then
            RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), 1, 1)
            BlzStartUnitAbilityCooldown(Hero[pid], REINCARNATION.id, 300.)
        -- reincarnation item
        elseif itm then
            heal = itm:getValue(ITEM_ABILITY, 0) * 0.01

            -- remove perishable resurrections
            if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv')  then
                itm:consumeCharge()
            else
                itm.charges = itm.charges - 1
            end

            RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        -- hardcore death
        elseif Hardcore[pid] then
            DisplayTextToPlayer(p, 0, 0, "You have died on Hardcore mode, you cannot revive. However, you may -repick to begin a new character in a new character save slot.")
            DeathHandler(pid)

            PlayerCleanup(pid)
        --softcore death
        else
            ChargeNetworth(p, 0, 0.02, 50 * GetHeroLevel(Hero[pid]), "Dying has cost you")

            DeathHandler(pid)

            DisableItems(pid, false)
            RevivePlayer(pid, GetLocationX(TOWN_CENTER), GetLocationY(TOWN_CENTER), 1, 1)
            SetCamera(pid, MAIN_MAP.rect)
        end

        --cleanup
        REINCARNATION.enabled[pid] = false
        ResurrectionRevival[pid] = 0
        UnitRemoveAbility(HeroGrave[pid], FourCC('A042'))
        UnitRemoveAbility(HeroGrave[pid], FourCC('A044'))
        UnitRemoveAbility(HeroGrave[pid], RESURRECTION.spell)

        SetUnitPosition(HeroGrave[pid], 30000, 30000)
        ShowUnit(HeroGrave[pid], false)
    end
end

---@type fun(pid: integer)
local function spawn_grave(pid)
    local itm      = GetResurrectionItem(pid, false)
    local scale      = 0 ---@type number 

    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid])))
    SetUnitVertexColor(HeroGrave[pid], 175, 175, 175, 255)
    if GetHeroLevel(Hero[pid]) > 1 then
        SuspendHeroXP(HeroGrave[pid], false)
        SetHeroLevel(HeroGrave[pid], GetHeroLevel(Hero[pid]), false)
        SuspendHeroXP(HeroGrave[pid], true)
    end
    BlzSetHeroProperName(HeroGrave[pid], GetHeroProperName(Hero[pid]))
    Fade(HeroGrave[pid], 1., false)
    if GetLocalPlayer() == Player(pid - 1) then
        ClearSelection()
        SelectUnit(HeroGrave[pid], true)
    end

    if itm then
        UnitAddAbility(HeroGrave[pid], FourCC('A042'))
    end

    if itm or REINCARNATION.enabled[pid] or ResurrectionRevival[pid] > 0 then
        REVIVE_INDICATOR[pid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))

        if GetLocalPlayer() == Player(pid - 1) then
            scale = 15
        end

        BlzSetSpecialEffectTimeScale(REVIVE_INDICATOR[pid], 0)
        BlzSetSpecialEffectScale(REVIVE_INDICATOR[pid], scale)
        BlzSetSpecialEffectZ(REVIVE_INDICATOR[pid], BlzGetLocalSpecialEffectZ(REVIVE_INDICATOR[pid]) - 100)
        TimerQueue:callDelayed(12.5, HideEffect, REVIVE_INDICATOR[pid])
    end

    REVIVE_BAR[pid] = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))
    BlzSetSpecialEffectZ(REVIVE_BAR[pid], BlzGetUnitZ(HeroGrave[pid]) + 200.)
    BlzSetSpecialEffectColorByPlayer(REVIVE_BAR[pid], Player(pid - 1))
    BlzPlaySpecialEffectWithTimeScale(REVIVE_BAR[pid], ANIM_TYPE_BIRTH, 0.099)
    BlzSetSpecialEffectScale(REVIVE_BAR[pid], 1.25)
    TimerQueue:callDelayed(12.5, HideEffect, REVIVE_BAR[pid])

    local pt = TimerList[pid]:add()
    pt.tag = 'dead'
    pt.timer:callDelayed(12.5, HeroGraveExpire, pt)
end

local function OnDeath()
    local killed       = GetTriggerUnit()
    local killer       = GetKillingUnit()
    local x            = GetUnitX(killed)
    local y            = GetUnitY(killed)
    local uid          = GetUnitTypeId(killed)
    local p            = GetOwningPlayer(killed)
    local p2           = GetOwningPlayer(killer)
    local pid          = GetPlayerId(p) + 1
    local kpid         = GetPlayerId(p2) + 1
    local unitType     = GetType(uid)
    local U            = User.first

    -- on kill trigger
    if killer then
        EVENT_ON_KILL:trigger(killer, killed)
    end

    -- on death trigger
    EVENT_ON_DEATH:trigger(killed, killer)

    -- hero skills
    while U do
        -- dark savior soul steal
        if IsEnemy(pid) and IsUnitInRange(Hero[U.id], killed, 1000. * LBOOST[U.id]) and UnitAlive(Hero[U.id]) and GetUnitAbilityLevel(Hero[U.id], SOULSTEAL.id) > 0 then
            HP(Hero[U.id], Hero[U.id], BlzGetUnitMaxHP(Hero[U.id]) * 0.04, SOULSTEAL.tag)
            MP(Hero[U.id], BlzGetUnitMaxMana(Hero[U.id]) * 0.04)
        end
        U = U.next
    end

    -- struggle shit
    if IsUnitInGroup(killed, StruggleWaveGroup) then
        GroupRemoveUnit(StruggleWaveGroup, killed)

        GoldWon_Struggle= GoldWon_Struggle + R2I(GOLD_TABLE[GetUnitLevel(killed)]*.65 *Gold_Mod[Struggle_Pcount])

        TimerQueue:callDelayed(1, RemoveUnit, killed)
        SetTextTagText(StruggleText,"Gold won: " +(GoldWon_Struggle),0.023)
        if (Struggle_WaveUCN == 0) and BlzGroupGetSize(StruggleWaveGroup) == 0 then
            TimerQueue:callDelayed(3., AdvanceStruggle, 0)
        end
    end

    -- kill quests
    if unitType > 0 and KillQuest[unitType].status == 1 and GetHeroLevel(Hero[kpid]) <= KillQuest[unitType].max + LEECH_CONSTANT then
        KillQuest[unitType].count = KillQuest[unitType].count + 1
        FloatingTextUnit(KillQuest[unitType].name .. " " .. (KillQuest[unitType].count) .. "/" .. (KillQuest[unitType].goal), killed, 3.1 ,80, 90, 9, 125, 200, 200, 0, true)

        if KillQuest[unitType].count >= KillQuest[unitType].goal then
            KillQuest[unitType].status = 2
            KillQuest[unitType].last = uid
            DisplayTimedTextToForce(FORCE_PLAYING, 12, KillQuest[unitType].name .. " quest completed, talk to the Huntsman for your reward.")
        end
    end

    -- hero death
    if killed == Hero[pid] then
        -- disable backpack teleports
        DisableBackpackTeleports(pid, true)
        -- grave
        UnitRemoveAbility(Hero[pid], FourCC('BEme')) -- remove meta
        ShowUnit(HeroGrave[pid], true)
        SetUnitVertexColor(HeroGrave[pid], 175, 175, 175, 0)
        if IsTerrainWalkable(x, y) then
            SetUnitPosition(HeroGrave[pid], x, y)
        else
            SetUnitPosition(HeroGrave[pid], TERRAIN_X, TERRAIN_Y)
        end
        TimerQueue:callDelayed(1.5, spawn_grave, pid)
    end

    return false
end

    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DEATH, OnDeath)
end, Debug and Debug.getLine())
