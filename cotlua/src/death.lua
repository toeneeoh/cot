--[[
    death.lua

    This library handles death events (i.e. EVENT_PLAYER_UNIT_DEATH or EVENT_UNIT_DEATH)
    and provides related functions and globals
]]

OnInit.final("Death", function(Require)
    Require('Users')
    Require('Variables')
    Require('Units')

    despawnGroup        = {} ---@type unit[]
    HeroReviveIndicator = {} ---@type effect[] 
    HeroTimedLife       = {} ---@type effect[] 
    RESPAWN_DEBUG       = false ---@type boolean 
    StruggleWaveGroup   = CreateGroup()
    ColoWaveGroup       = CreateGroup()
    FIRST_DROP          = 0 ---@type integer 

    QuestUnits = {
        --kroresh
        [FourCC('N01N')] = function()
            QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "|cffffcc00OPTIONAL QUEST COMPLETE|r\nThe Horde")
            QuestSetCompleted(Defeat_The_Horde_Quest, true)
            TalkToMe20 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl", gg_unit_n02Q_0382, "overhead")
        end,

        --zeknen
        [FourCC('O01A')] = function()
            DeadGods = 0
            SetCinematicScene(BossTable[BOSS_LIFE].id, GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), "Goddess of Life", "You are foolish to challenge us in our realm. Prepare yourself.", 9, 7)

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(BossTable[BOSS_HATE].unit), GetUnitY(BossTable[BOSS_HATE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(BossTable[BOSS_HATE].unit), GetUnitY(BossTable[BOSS_HATE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(BossTable[BOSS_HATE].unit), GetUnitY(BossTable[BOSS_HATE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(BossTable[BOSS_LOVE].unit), GetUnitY(BossTable[BOSS_LOVE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(BossTable[BOSS_LOVE].unit), GetUnitY(BossTable[BOSS_LOVE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(BossTable[BOSS_LOVE].unit), GetUnitY(BossTable[BOSS_LOVE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(BossTable[BOSS_KNOWLEDGE].unit), GetUnitY(BossTable[BOSS_KNOWLEDGE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(BossTable[BOSS_KNOWLEDGE].unit), GetUnitY(BossTable[BOSS_KNOWLEDGE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(BossTable[BOSS_KNOWLEDGE].unit), GetUnitY(BossTable[BOSS_KNOWLEDGE].unit)))
            ShowUnit(BossTable[BOSS_HATE].unit, true)
            ShowUnit(BossTable[BOSS_LOVE].unit, true)
            ShowUnit(BossTable[BOSS_KNOWLEDGE].unit, true)
            PauseUnit(BossTable[BOSS_HATE].unit, true)
            PauseUnit(BossTable[BOSS_LOVE].unit, true)
            PauseUnit(BossTable[BOSS_KNOWLEDGE].unit, true)
            UnitAddAbility(BossTable[BOSS_HATE].unit, FourCC('Avul'))
            UnitAddAbility(BossTable[BOSS_LOVE].unit, FourCC('Avul'))
            UnitAddAbility(BossTable[BOSS_KNOWLEDGE].unit, FourCC('Avul'))
            TimerQueue:callDelayed(7., SpawnGods)
        end,

        --evilshopkeeper
        [FourCC('n01F')] = function()
            QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "|cffffcc00OPTIONAL QUEST COMPLETED|r\nThe Evil Shopkeeper")
            QuestSetCompleted(Evil_Shopkeeper_Quest_1, true)
            --? QuestItemSetCompleted(Quest_Req[10], true)
        end,

        --forest corruption
        [FourCC('N00M')] = function()
            Item.create(CreateItem(FourCC('I03X'), GetUnitX(forest_corruption), GetUnitY(forest_corruption)), 600.) --corrupted essence
        end,

        --ice troll
        [FourCC('O00T')] = function()
            Item.create(CreateItem(FourCC('I040'), GetUnitX(ice_troll), GetUnitY(ice_troll))) --key of redemption
        end,
    }

---@type fun(uid: integer, x: number, y: number, flag: integer)
function CreepHandler(uid, x, y, flag)
    if CHAOS_MODE == flag then
        local ug = CreateGroup()

        GroupEnumUnitsInRange(ug, x, y, 800., Condition(FilterDespawn))

        if FirstOfGroup(ug) == nil then
            CreateUnit(pfoe, uid, x, y, GetRandomInt(0,359))
        else
            local creep = CreateUnit(pfoe, uid, x, y, GetRandomInt(0,359))
            BlzSetItemSkin(PATH_ITEM, BlzGetUnitSkin(creep))
            local sfx = AddSpecialEffect(BlzGetItemStringField(PATH_ITEM, ITEM_SF_MODEL_USED), x, y)
            despawnGroup[#despawnGroup + 1] = creep
            PauseUnit(creep, true)
            UnitAddAbility(creep, FourCC('Avul'))
            ShowUnit(creep, false)
            BlzSetItemSkin(PATH_ITEM, BlzGetUnitSkin(DummyUnit))
            BlzSetSpecialEffectColorByPlayer(sfx, pfoe)
            BlzSetSpecialEffectColor(sfx, 175, 175, 175)
            BlzSetSpecialEffectAlpha(sfx, 127)
            BlzSetSpecialEffectScale(sfx, BlzGetUnitRealField(creep, UNIT_RF_SCALING_VALUE))
            BlzSetSpecialEffectYaw(sfx, bj_DEGTORAD * GetUnitFacing(creep))
            Unit[creep].ghost = sfx
        end

        DestroyGroup(ug)
    end
end

---@param pid integer
function DeathHandler(pid)
    local p  = Player(pid - 1) ---@type player 
    local x  = GetUnitX(HeroGrave[pid]) ---@type number 
    local y  = GetUnitY(HeroGrave[pid]) ---@type number 
    local ug = CreateGroup()

    CleanupSummons(p)

    --dungeons
    DungeonFail(pid)

    --colosseum
    if InColo[pid] then
        ColoPlayerCount = ColoPlayerCount - 1
        InColo[pid] = false
        Fleeing[pid] = false
        AwardGold(pid, ColoGoldWon / 1.5, true)
        ExperienceControl(pid)
        if ColoPlayerCount == 0 then --clear colo
            ClearColo()
        end

    --struggle
    elseif InStruggle[pid] then
        Struggle_Pcount = Struggle_Pcount - 1
        InStruggle[pid] = false
        Fleeing[pid] = false
        ExperienceControl(pid)
        AwardGold(pid, GoldWon_Struggle * 0.1, true)
        if Struggle_Pcount == 0 then --clear struggle
            ClearStruggle()
        end
    --gods area
    elseif TableHas(GODS_GROUP, p) then
        TableRemove(GODS_GROUP, p)
    end

    DestroyGroup(ug)
end

---@type fun(pt: PlayerTimer)
function HeroGraveExpire(pt)
    local pid = pt.pid
    local p    = Player(pid - 1) ---@type player 
    local itm  = GetResurrectionItem(pid, false) ---@type Item?
    local heal = 0. ---@type number 

    BlzSetSpecialEffectScale(HeroTimedLife[pid], 0)
    DestroyEffect(HeroTimedLife[pid])

    if IsUnitHidden(HeroGrave[pid]) == false then
        if ResurrectionRevival[pid] > 0 then --high priestess resurrection
            heal = RESURRECTION.restore(ResurrectionRevival[pid])
            RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        elseif ReincarnationRevival[pid] then --phoenix ranger resurrection
            RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), 100, 100)
            BlzStartUnitAbilityCooldown(Hero[pid], REINCARNATION.id, 300.)
        elseif itm then --reincarnation item
            heal = itm:getValue(ITEM_ABILITY, 0) * 0.01

            if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv')  then --remove perishable resurrections
                itm:consumeCharge()
            end

            RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        elseif Hardcore[pid] then --hardcore death
            DisplayTextToPlayer(p, 0, 0, "You have died on Hardcore mode, you cannot revive. However, you may -repick to begin a new character in a new character save slot.")
            DeathHandler(pid)

            PlayerCleanup(pid)
        else --softcore death
            ChargeNetworth(p, 0, 0.02, 50 * GetHeroLevel(Hero[pid]), "Dying has cost you")

            DeathHandler(pid)

            EnableItems(pid)
            RevivePlayer(pid, GetLocationX(TownCenter), GetLocationY(TownCenter), 1, 1)
            SetCamera(pid, MAIN_MAP.rect)
        end

        --cleanup
        ReincarnationRevival[pid] = false
        ResurrectionRevival[pid] = 0
        UnitRemoveAbility(HeroGrave[pid], FourCC('A042'))
        UnitRemoveAbility(HeroGrave[pid], FourCC('A044'))
        UnitRemoveAbility(HeroGrave[pid], FourCC('A045'))

        SetUnitPosition(HeroGrave[pid], 30000, 30000)
        ShowUnit(HeroGrave[pid], false)
    end
end

---@type fun(pid: integer)
function SpawnGrave(pid)
    local itm      = GetResurrectionItem(pid, false)
    local scale      = 0 ---@type number 

    DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Undead\\RaiseSkeletonWarrior\\RaiseSkeleton.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid])))
    SetUnitVertexColor(HeroGrave[pid], 175, 175, 175, 255)
    if GetHeroLevel(Hero[pid]) > 1 then
        SuspendHeroXP(HeroGrave[pid], false)
        SetHeroLevelBJ(HeroGrave[pid], GetHeroLevel(Hero[pid]), false)
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

    if ReincarnationRevival[pid] then
        UnitAddAbility(HeroGrave[pid], FourCC('A044'))
    end

    if itm or ReincarnationRevival[pid] then
        HeroReviveIndicator[pid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))

        if GetLocalPlayer() == Player(pid - 1) then
            scale = 15
        end

        BlzSetSpecialEffectTimeScale(HeroReviveIndicator[pid], 0)
        BlzSetSpecialEffectScale(HeroReviveIndicator[pid], scale)
        BlzSetSpecialEffectZ(HeroReviveIndicator[pid], BlzGetLocalSpecialEffectZ(HeroReviveIndicator[pid]) - 100)
        TimerQueue:callDelayed(12.5, HideEffect, HeroReviveIndicator[pid])
    end

    HeroTimedLife[pid] = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))
    BlzSetSpecialEffectZ(HeroTimedLife[pid], BlzGetUnitZ(HeroGrave[pid]) + 200.)
    BlzSetSpecialEffectColorByPlayer(HeroTimedLife[pid], Player(pid - 1))
    BlzPlaySpecialEffectWithTimeScale(HeroTimedLife[pid], ANIM_TYPE_BIRTH, 0.099)
    BlzSetSpecialEffectScale(HeroTimedLife[pid], 1.25)

    local pt = TimerList[pid]:add()
    pt.tag = 'dead'
    pt.timer:callDelayed(12.5, HeroGraveExpire, pt)

    if sniperstance[pid] then --Reset Tri-Rocket
        sniperstance[pid] = false
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 0, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 1, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 2, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 3, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 4, 6.)
    end
end

---@type fun(killed: unit, killer: unit, awardGold: boolean)
function RewardXPGold(killed, killer, awardGold)
    local kpid = GetPlayerId(GetOwningPlayer(killer)) + 1 ---@type integer 
    local xpgroup = {}
    local lvl = GetUnitLevel(killed)

    --nearby allies
    local U = User.first

    while U do
        if IsUnitInRange(Hero[U.id], killed, 1800.00) and UnitAlive(Hero[U.id]) and U.id ~= kpid then
            if (GetHeroLevel(Hero[U.id]) >= (lvl - 20)) and (GetHeroLevel(Hero[U.id])) >= GetUnitLevel(Hero[kpid]) - LEECH_CONSTANT then
                xpgroup[#xpgroup + 1] = U.id
            end
        end
        U = U.next
    end

    --killer
    if GetHeroLevel(Hero[kpid]) >= (lvl - 20) then
        xpgroup[#xpgroup + 1] = kpid
    end

    --allocate rewards
    local maingold = 0
    local teamgold = 0
    local expbase = Experience_Table[lvl] / 700. ---@type number 

    if awardGold then
        maingold = RewardGold[lvl] * GetRandomReal(0.8, 1.2)
    end

    if #xpgroup > 0 then
        expbase = expbase * (1.2 / #xpgroup)
        teamgold = maingold * (1. / #xpgroup)
    end

    --boss bounty
    if IsUnitType(killed, UNIT_TYPE_HERO) == true then
        expbase = expbase * 15.
        maingold = expbase * 87.5
        if HARD_MODE > 0 then
            expbase = math.floor(expbase * 1.3)
            maingold = maingold * 1.3
        end
    end

    for pid = 1, #xpgroup do
        local XP = math.floor(expbase * XP_Rate[pid])

        AwardGold(pid, teamgold, false)
        AwardXP(pid, XP)
    end
end

function ReviveGods()
    local ug = CreateGroup()

    GroupEnumUnitsInRect(ug, gg_rct_Gods_Arena, Filter(isplayerunitRegion))

    for target in each(ug) do
        local pid = GetPlayerId(GetOwningPlayer(target)) + 1

        if target == Hero[pid] then
            TableRemove(GODS_GROUP, GetOwningPlayer(target))
            MoveHeroLoc(pid, TownCenter)
        else
            SetUnitPositionLoc(target, TownCenter)
        end
    end

    DestroyGroup(ug)

    RemoveUnit(power_crystal)

    BossTable[BOSS_LIFE]:revive()

    PauseUnit(BossTable[BOSS_LIFE].unit, true)
    ShowUnit(BossTable[BOSS_LIFE].unit, false)

    BossTable[BOSS_HATE]:revive()
    BossTable[BOSS_LOVE]:revive()
    BossTable[BOSS_KNOWLEDGE]:revive()

    for i = BOSS_HATE, BOSS_KNOWLEDGE do
        for j = 1, 6 do
            if BossTable[i].item[j] ~= 0 then
                UnitAddItemById(BossTable[i].unit, BossTable[i].item[j])
            end
        end
        SetHeroLevel(BossTable[i].unit, BossTable[i].level, false)
        --reapply hardmode
        if HARD_MODE > 0 then
            SetHeroStr(BossTable[i].unit, GetHeroStr(BossTable[i].unit, true) * 2, true)
            BlzSetUnitBaseDamage(BossTable[i].unit, BlzGetUnitBaseDamage(BossTable[i].unit, 0) * 2 + 1, 0)
            Unit[BossTable[i].unit].mm = 2.
        end
    end

    DeadGods = 0
end

---@type fun(pt: PlayerTimer)
function BossRespawn(pt)
    local index = IsBoss(pt.uid)

    if index ~= -1 then
        --revive gods
        if pt.uid == BossTable[BOSS_LIFE].id then
            ReviveGods()
            DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" .. BossTable[index].name .. " have revived.|r")
        else
            local ug = CreateGroup()

            --death knight / legion
            if pt.uid == FourCC('H040') or pt.uid == FourCC('H04R') then
                repeat
                    RemoveLocation(BossTable[index].loc)
                    BossTable[index].loc = GetRandomLocInRect(MAIN_MAP.rect)
                    GroupEnumUnitsInRangeOfLoc(ug, BossTable[index].loc, 4000., Condition(isbase))
                until IsTerrainWalkable(GetLocationX(BossTable[index].loc), GetLocationY(BossTable[index].loc)) and BlzGroupGetSize(ug) == 0 and RectContainsLoc(gg_rct_Town_Boundry, BossTable[index].loc) == false and RectContainsLoc(gg_rct_Top_of_Town, BossTable[index].loc) == false
            end

            DestroyGroup(ug)

            BossTable[index]:revive()
            DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Orc\\Reincarnation\\ReincarnationTarget.mdl", BossTable[index].loc))

            --dragoon evasion
            if pt.uid == BossTable[BOSS_DRAGOON].id then
                Unit[BossTable[index].unit].evasion = 50
            end

            SetHeroLevel(BossTable[index].unit, BossTable[index].level, false)
            for j = 1, 6 do
                if BossTable[index].item[j] ~= 0 then
                    local itm = UnitAddItemById(BossTable[index].unit, BossTable[index].item[j])
                    itm:lvl(ItemData[itm.id][ITEM_UPGRADE_MAX])
                end
            end
            --reapply hardmode
            if HARD_MODE > 0 then
                SetHeroStr(BossTable[index].unit, GetHeroStr(BossTable[index].unit,true) * 2, true)
                BlzSetUnitBaseDamage(BossTable[index].unit, BlzGetUnitBaseDamage(BossTable[index].unit, 0) * 2 + 1, 0)
                Unit[BossTable[index].unit].mm = 2.
            end
            DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" .. BossTable[index].name .. " has revived.|r")
        end
    end

    pt:destroy()
end

---@param uid integer
function BossHandler(uid)
    local delay = BOSS_RESPAWN_TIME

    if CHAOS_LOADING then
        return
    end

    if IsUnitIdType(uid, UNIT_TYPE_HERO) == false then
        delay = delay // 2
    end

    --azazoth
    if uid == FourCC('O02T') then
        DungeonComplete(DUNGEON_AZAZOTH)
    --naga boss
    elseif uid == FourCC('O006') then
        DungeonComplete(DUNGEON_NAGA)
    elseif uid == FourCC('E00B') or uid == FourCC('E00D') or uid == FourCC('E00C') then
        DeadGods = DeadGods + 1

        if DeadGods == 3 then --spawn goddess of life
            if GodsRepeatFlag == false then
                GodsRepeatFlag = true
                SetCinematicScene(BossTable[BOSS_LIFE].id, GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), "Goddess of Life", "This is your last chance", 6, 5)
            end

            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetUnitX(BossTable[BOSS_LIFE].unit), GetUnitY(BossTable[BOSS_LIFE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectCaster.mdl", GetUnitX(BossTable[BOSS_LIFE].unit), GetUnitY(BossTable[BOSS_LIFE].unit)))
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(BossTable[BOSS_LIFE].unit), GetUnitY(BossTable[BOSS_LIFE].unit)))
            ShowUnit(BossTable[BOSS_LIFE].unit, true)
            PauseUnit(BossTable[BOSS_LIFE].unit, true)
            UnitAddAbility(BossTable[BOSS_LIFE].unit, FourCC('Avul'))
            UnitAddAbility(BossTable[BOSS_LIFE].unit, FourCC('A08L')) --life aura
            TimerQueue:callDelayed(6., GoddessOfLife)
        end

        return
    elseif uid == BossTable[BOSS_LIFE].id then
        DeadGods = 4
        DisplayTimedTextToForce(FORCE_PLAYING, 10, "You may now -flee.")
        power_crystal = CreateUnit(pfoe, FourCC('h04S'), -2026.936, -27753.830, bj_UNIT_FACING)
    elseif BANISH_FLAG and (uid == BossTable[BOSS_DEATH_KNIGHT].id or uid == BossTable[BOSS_LEGION].id) then
        --banish death knight / legion
        return
    end

    local pt = TimerList[BOSS_ID]:add()
    pt.tag = 'boss'
    pt.uid = uid

    delay = delay * bossResMod

    if RESPAWN_DEBUG then
        delay = 5.
    end

    pt.timer:callDelayed(delay, BossRespawn, pt)
end

---@type fun(): boolean
function OnDeath()
    local killed       = GetTriggerUnit()
    local killer       = GetKillingUnit()
    local x            = GetUnitX(killed)
    local y            = GetUnitY(killed)
    local uid          = GetUnitTypeId(killed)
    local p            = GetOwningPlayer(killed)
    local p2           = GetOwningPlayer(killer)
    local pid          = GetPlayerId(p) + 1
    local kpid         = GetPlayerId(p2) + 1
    local dropflag     = true
    local spawnflag    = false
    local goldflag     = false
    local xpflag       = false
    local trainingflag = false
    local unitType     = GetType(uid)
    local index        = IsBoss(unitType)
    local U            = User.first

    if EXTRA_DEBUG then
        print(GetObjectName(uid))
    end

    --hero skills
    while U do
        --dark savior soul steal
        if IsEnemy(pid) and IsUnitInRange(Hero[U.id], killed, 1000. * LBOOST[U.id]) and UnitAlive(Hero[U.id]) and GetUnitAbilityLevel(Hero[U.id], SOULSTEAL.id) > 0 then
            HP(Hero[U.id], Hero[U.id], BlzGetUnitMaxHP(Hero[U.id]) * 0.04, SOULSTEAL.tag)
            MP(Hero[U.id], BlzGetUnitMaxMana(Hero[U.id]) * 0.04)
        end
        U = U.next
    end

    --determine flags based on area
    if IsEnemy(pid) and IsUnitEnemy(killed, p2) then
        if RectContainsCoords(gg_rct_Training_Chaos, x, y) then
            trainingflag = true
            goldflag = true
            xpflag = true
            dropflag = false
            RemoveUnit(killed)
        elseif RectContainsCoords(gg_rct_Training_Prechaos, x, y) then
            trainingflag = true
            goldflag = true
            xpflag = true
            dropflag = false
            RemoveUnit(killed)
        elseif IsUnitInGroup(killed, ColoWaveGroup) then --Colo 
            goldflag = false
            xpflag = true
            dropflag = false
            GroupRemoveUnit(ColoWaveGroup, killed)

            ColoGoldWon = ColoGoldWon + R2I(RewardGold[GetUnitLevel(killed)] / Gold_Mod[ColoPlayerCount])
            Colosseum_Monster_Amount = Colosseum_Monster_Amount - 1

            TimerQueue:callDelayed(1, RemoveUnit, killed)
            SetTextTagText(ColoText, "Gold won: " .. ((ColoGoldWon)), 10 * 0.023 / 10)
            if BlzGroupGetSize(ColoWaveGroup) == 0 then
                TimerQueue:callDelayed(3., AdvanceColo)
            end
        elseif IsUnitInGroup(killed, StruggleWaveGroup) then --struggle enemies
            goldflag = true
            xpflag = true
            dropflag = false
            GroupRemoveUnit(StruggleWaveGroup, killed)

            GoldWon_Struggle= GoldWon_Struggle + R2I(RewardGold[GetUnitLevel(killed)]*.65 *Gold_Mod[Struggle_Pcount])

            TimerQueue:callDelayed(1, RemoveUnit, killed)
            SetTextTagText(StruggleText,"Gold won: " +(GoldWon_Struggle),0.023)
            if (Struggle_WaveUCN == 0) and BlzGroupGetSize(StruggleWaveGroup) == 0 then
                TimerQueue:callDelayed(3., AdvanceStruggle, 0)
            end
        elseif TableHas(NAGA_ENEMIES, killed) then --naga dungeon
            dropflag = false
            AdvanceNagaDungeon(killed)
        elseif uid == FourCC('h04S') then --power crystal
            dropflag = false
            BeginChaos() --chaos
        else
            spawnflag = true
            goldflag = true
            xpflag = true
        end
    end

    if IsUnitIllusion(killed) then
        dropflag = false
        spawnflag = false
        goldflag = false
        xpflag = false
    end

    if xpflag then
        RewardXPGold(killed, killer, goldflag)
    end

    --========================
    -- Item Drops / Rewards
    --========================

    if dropflag and not trainingflag then
        if index >= 0 then
            --TODO dont bit flip if boss count exceeds 31
            if BlzBitAnd(FIRST_DROP, 2 ^ index) == 0 then
                FIRST_DROP = FIRST_DROP + 2 ^ index
                BossDrop(unitType, Rates[unitType] + 25, x, y)
            else
                BossDrop(unitType, Rates[unitType], x, y)
            end

            AwardCrystals(index, x, y)
        else
            local rand = GetRandomInt(0, 99)
            if rand < Rates[unitType] then
                Item.create(CreateItem(DropTable:pickItem(unitType), x, y), 600.)
            end

            --iron golem ore
            --chaotic ore

            if p == pfoe then
                rand = GetRandomInt(0, 99)

                if GetUnitLevel(killed) > 45 and GetUnitLevel(killed) < 85 and rand < (0.05 * GetUnitLevel(killed)) then
                    Item.create(CreateItem(FourCC('I02Q'), GetUnitX(killed), GetUnitY(killed)), 600.)
                elseif GetUnitLevel(killed) > 265 and GetUnitLevel(killed) < 305 and rand < (0.02 * GetUnitLevel(killed)) then
                    Item.create(CreateItem(FourCC('I04Z'), GetUnitX(killed), GetUnitY(killed)), 600.)
                end
            end
        end
    end

    --========================
    -- Quests
    --========================

    if unitType > 0 and KillQuest[unitType].status == 1 and GetHeroLevel(Hero[kpid]) <= KillQuest[unitType].max + LEECH_CONSTANT then
        KillQuest[unitType].count = KillQuest[unitType].count + 1
        FloatingTextUnit(KillQuest[unitType].name .. " " .. (KillQuest[unitType].count) .. "/" .. (KillQuest[unitType].goal), killed, 3.1 ,80, 90, 9, 125, 200, 200, 0, true)

        if KillQuest[unitType].count >= KillQuest[unitType].goal then
            KillQuest[unitType].status = 2
            KillQuest[unitType].last = uid
            DisplayTimedTextToForce(FORCE_PLAYING, 12, KillQuest[unitType].name .. " quest completed, talk to the Huntsman for your reward.")
        end
    end

    --the horde
    if IsQuestDiscovered(Defeat_The_Horde_Quest) and IsQuestCompleted(Defeat_The_Horde_Quest) == false and (uid == FourCC('o01I') or uid == FourCC('o008')) then --Defeat the Horde
        local ug = CreateGroup()
        GroupEnumUnitsOfPlayer(ug, pboss, Filter(isOrc))

        if BlzGroupGetSize(ug) == 0 and UnitAlive(kroresh) and GetUnitAbilityLevel(kroresh, FourCC('Avul')) > 0 then
            UnitRemoveAbility(kroresh, FourCC('Avul'))
            if RectContainsUnit(MAIN_MAP.rect, kroresh) == false then
                SetUnitPosition(kroresh, 14500., -15180.)
                BlzSetUnitFacingEx(kroresh, 135.)
                PingMinimap(14500., -15180., 3)
            end
            SetCinematicScene(GetUnitTypeId(kroresh), GetPlayerColor(pboss), "Kroresh Foretooth", "You dare slaughter my men? Damn you!", 5, 4)
        end

        DestroyGroup(ug)
    end

    --quest unit lookup table
    if QuestUnits[uid] then
        QuestUnits[uid]()
    end

    --========================
    --Homes
    --========================

    if killed == PlayerBase[pid] then
        if killer then
            if GetPlayerId(p2) > PLAYER_CAP then
                DisplayTimedTextToForce(FORCE_PLAYING, 45, User[pid - 1].nameColored .. "'s base was destroyed by " .. GetUnitName(killer) .. ".")
            else
                DisplayTimedTextToForce(FORCE_PLAYING, 45, User[pid - 1].nameColored .. "'s base was destroyed by " .. GetPlayerName(p2) .. ".")
            end
        else
            DisplayTimedTextToForce(FORCE_PLAYING, 45, User[pid - 1].nameColored .. "'s base has been destroyed.")
        end

        Profile[pid].hero.base = 0
        PlayerBase[pid] = nil
        if destroyBaseFlag[pid] then
            destroyBaseFlag[pid] = false
        else
            DisplayTextToPlayer(p, 0, 0, "|cffff0000You must build another base within 2 minutes or be defeated. If you are defeated you will lose your character and be unable to save. If you think you are unable to build another base for some reason, then save now.")
            local pt = TimerList[pid]:add()
            pt.tag = FourCC('bdie')
            pt.timer:callDelayed(120., BaseDeath, pt)
        end

        local ug = CreateGroup()
        GroupEnumUnitsOfPlayer(ug, p, Condition(FilterNotHero))

        for target in each(ug) do
            SetUnitExploded(target, true)
            KillUnit(target)
        end

        DestroyGroup(ug)

        --reset unit limits
        workerCount[pid] = 0
        smallwispCount[pid] = 0
        largewispCount[pid] = 0
        warriorCount[pid] = 0
        rangerCount[pid] = 0
        SetPlayerTechResearched(p, FourCC('R013'), 1)
        SetPlayerTechResearched(p, FourCC('R014'), 1)
        SetPlayerTechResearched(p, FourCC('R015'), 1)
        SetPlayerTechResearched(p, FourCC('R016'), 1)
        SetPlayerTechResearched(p, FourCC('R017'), 1)

        ExperienceControl(pid)

    --========================
    --Other
    --========================

    --unit limits
    elseif uid == FourCC('h01P') or uid == FourCC('h03Y') or uid == FourCC('h04B') or uid == FourCC('n09E') or uid == FourCC('n00Q') or uid == FourCC('n023') or uid == FourCC('n09F') or uid == FourCC('h010') or uid == FourCC('h04U') or uid == FourCC('h053') then --worker
        workerCount[pid] = workerCount[pid] - 1
        SetPlayerTechResearched(p, FourCC('R013'), 1)
    elseif uid == FourCC('e00J') or uid == FourCC('e000') or uid == FourCC('e00H') or uid == FourCC('e00K') or uid == FourCC('e006') or uid == FourCC('e00I') or uid == FourCC('e00T') or uid == FourCC('e00Y') then --small wisp
        smallwispCount[pid] = smallwispCount[pid] - 1
        SetPlayerTechResearched(p, FourCC('R014'), 1)
    elseif uid == FourCC('e00Z') or uid == FourCC('e00R') or uid == FourCC('e00Q') or uid == FourCC('e01L') or uid == FourCC('e01E') or uid == FourCC('e010') then --large wisp
        largewispCount[pid] = largewispCount[pid] - 1
        SetPlayerTechResearched(p, FourCC('R015'), 1)
    elseif uid == FourCC('h00S') or uid == FourCC('h017') or uid == FourCC('h00I') or uid == FourCC('h016') or uid == FourCC('nwlg') or uid == FourCC('h004') or uid == FourCC('h04V') or uid == FourCC('o02P') then --warrior
        warriorCount[pid] = warriorCount[pid] - 1
        SetPlayerTechResearched(p, FourCC('R016'), 1)
    elseif uid == FourCC('n00A') or uid == FourCC('n014') or uid == FourCC('n009') or uid == FourCC('n00D') or uid == FourCC('n002') or uid == FourCC('h005') or uid == FourCC('o02Q') then --ranger
        rangerCount[pid] = rangerCount[pid] - 1
        SetPlayerTechResearched(p, FourCC('R017'), 1)
    elseif uid == forgottenTypes[0] or uid == forgottenTypes[1] or uid == forgottenTypes[2] or uid == forgottenTypes[3] or uid == forgottenTypes[4] then
        forgottenCount = forgottenCount - 1

    --========================
    --Hero Death
    --========================

    elseif killed == Hero[pid] then

        --pvp death
        if GetArena(pid) then --PVP DEATH
            RevivePlayer(pid, x, y, 1, 1)
            UnitRemoveBuffs(killed, true, true)
            DisplayTextToForce(FORCE_PLAYING, User[pid - 1].nameColored .. " has been slain by " + User[kpid - 1].nameColored .. "!")
            UnitAddAbility(killed, FourCC('Avul'))
            SetUnitAnimation(killed, "death")
            PauseUnit(killed, true)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", killer, "origin"))
            ArenaDeath(killed, killer, GetArena(pid))
        else
            --grave
            UnitRemoveAbility(Hero[pid], FourCC('BEme')) --remove meta
            ShowUnit(HeroGrave[pid], true)
            SetUnitVertexColor(HeroGrave[pid], 175, 175, 175, 0)
            if IsTerrainWalkable(x, y) then
                SetUnitPosition(HeroGrave[pid], x, y)
            else
                SetUnitPosition(HeroGrave[pid], TERRAIN_X, TERRAIN_Y)
            end
            TimerQueue:callDelayed(1.5, SpawnGrave, pid)
        end

        --phoenix ranger reincarnation
        if BlzGetUnitAbilityCooldownRemaining(killed, REINCARNATION.id) <= 0 and GetUnitAbilityLevel(killed, REINCARNATION.id) > 0 then
            ReincarnationRevival[pid] = true
        end

        --high priestess self resurrection
        if BlzGetUnitAbilityCooldownRemaining(killed, RESURRECTION.id) <= 0 and GetUnitAbilityLevel(killed, RESURRECTION.id) > 0 then
            UnitAddAbility(HeroGrave[pid], FourCC('A045'))
            BlzStartUnitAbilityCooldown(killed, RESURRECTION.id, 450. - 50. * GetUnitAbilityLevel(killed, RESURRECTION.id))
            ResurrectionRevival[pid] = pid

            BlzSetSpecialEffectScale(HeroReviveIndicator[pid], 0.)
            DestroyEffect(HeroReviveIndicator[pid])
            HeroReviveIndicator[pid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))

            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetSpecialEffectScale(HeroReviveIndicator[pid], 15.)
            end

            BlzSetSpecialEffectTimeScale(HeroReviveIndicator[pid], 0.)
            BlzSetSpecialEffectZ(HeroReviveIndicator[pid], BlzGetLocalSpecialEffectZ(HeroReviveIndicator[pid]) - 100)
            TimerQueue:callDelayed(12.8, HideEffect, HeroReviveIndicator[pid])
        end

        --town paladin was killer
        if killer == townpaladin then
            local pt = TimerList[0]:get('pala', killed)

            if pt then
                pt.dur = 0.
            end
        end

    --========================
    --Enemy Respawns
    --========================

    --boss handling
    elseif index ~= -1 and p == pboss and spawnflag then
        --add up player boss damage
        local damage = 0
        U = User.first
        while U do
            damage = damage + BossDamage[#BossTable * index + U.id]
            U = U.next
        end

        U = User.first
        --print percentage contribution
        while U do
            if BossDamage[#BossTable * index + U.id] >= 1. then
                DisplayTimedTextToForce(FORCE_PLAYING, 20., U.nameColored .. " contributed |cffffcc00" .. R2S(BossDamage[#BossTable * index + U.id] * 100. / math.max(damage * 1., 1.)) .. "\x25|r damage to " .. GetUnitName(killed) .. ".")
            end
            U = U.next
        end

        TimerQueue:callDelayed(6., RemoveUnit, killed)
        BossHandler(uid)

        --reset boss damage recorded
        BossDamage = __jarray(0)

        --key quest
        if unitType == BossTable[BOSS_ARKADEN].id and not CHAOS_MODE and IsUnitHidden(god_angel) then --arkaden
            SetUnitAnimation(god_angel, "birth")
            ShowUnit(god_angel, true)
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl", GetUnitX(god_angel), GetUnitY(god_angel)))
            SetCinematicScene(GetUnitTypeId(god_angel), GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), "Angel", "Halt! Before proceeding you must bring me the 3 keys to unlock the seal and face the gods in their domain.", 8, 7)
        end
    --creep handling
    elseif UnitData[uid].spawn > 0 and spawnflag then
        TimerQueue:callDelayed(20.0, CreepHandler, uid, x, y, CHAOS_MODE)
        TimerQueue:callDelayed(30.0, RemoveUnit, killed)
    end

    return false
end

    local death = CreateTrigger()
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(death, u.player, EVENT_PLAYER_UNIT_DEATH, nil)
        u = u.next
    end

    TriggerRegisterPlayerUnitEvent(death, Player(PLAYER_TOWN), EVENT_PLAYER_UNIT_DEATH, nil)
    TriggerRegisterPlayerUnitEvent(death, pboss, EVENT_PLAYER_UNIT_DEATH, nil)

    TriggerRegisterPlayerUnitEvent(death, pfoe, EVENT_PLAYER_UNIT_DEATH, nil)
    TriggerRegisterUnitEvent(death, evilshopkeeper, EVENT_UNIT_DEATH)

    TriggerAddCondition(death, Condition(OnDeath))
end, Debug.getLine())
