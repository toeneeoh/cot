if Debug then Debug.beginFile 'Death' end

OnInit.final("Death", function(require)
    require 'Users'
    require 'Variables'

    RTimerBox           = {} ---@type timerdialog[] 
    despawnGroup        = CreateGroup()
    HeroReviveIndicator = {} ---@type effect[] 
    HeroTimedLife       = {} ---@type effect[] 
    RESPAWN_DEBUG       = false ---@type boolean 
    StruggleWaveGroup   = CreateGroup()
    ColoWaveGroup       = CreateGroup()
    FIRST_DROP          = 0 ---@type integer 

---@type fun(pt: PlayerTimer)
function RemoveCreep(pt)
    local ug = CreateGroup()
    local valid = true ---@type boolean 

    GroupEnumUnitsInRange(ug, pt.x, pt.y, 800., Condition(FilterDespawn))

    if ChaosMode and pt.agi ~= 1 then
        valid = false
    end

    if UnitData[pt.uid][UNITDATA_COUNT] > 0 and valid then
        if FirstOfGroup(ug) == nil then
            CreateUnit(pfoe, pt.uid, pt.x, pt.y, GetRandomInt(0,359))
        else
            local u2 = CreateUnit(pfoe, pt.uid, pt.x, pt.y, GetRandomInt(0,359))
            PauseUnit(u2, true)
            UnitAddAbility(u2, FourCC('Avul'))
            GroupAddUnit(despawnGroup, u2)
            ShowUnit(u2, false)
            BlzSetItemSkin(PathItem, BlzGetUnitSkin(u2))
            local sfx = AddSpecialEffect(BlzGetItemStringField(PathItem, ITEM_SF_MODEL_USED), pt.x, pt.y)
            BlzSetItemSkin(PathItem, BlzGetUnitSkin(DummyUnit))
            BlzSetSpecialEffectColorByPlayer(sfx, pfoe)
            BlzSetSpecialEffectColor(sfx, 175, 175, 175)
            BlzSetSpecialEffectAlpha(sfx, 127)
            BlzSetSpecialEffectScale(sfx, BlzGetUnitRealField(u2, UNIT_RF_SCALING_VALUE))
            BlzSetSpecialEffectYaw(sfx, bj_DEGTORAD * GetUnitFacing(u2))
            if not UnitData[u2] then
                UnitData[u2] = {}
            end
            UnitData[u2].ghost = sfx
        end
    end

    pt:destroy()
    DestroyGroup(ug)
end

---@param pid integer
function DeathHandler(pid)
    local p  = Player(pid - 1) ---@type player 
    local x  = GetUnitX(HeroGrave[pid]) ---@type number 
    local y  = GetUnitY(HeroGrave[pid]) ---@type number 
    local ug = CreateGroup()

    CleanupSummons(p)

    --clear training area if no heroes remain
    if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, x, y) then
        GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(isplayerAlly))
        for hero in each(ug) do
            if UnitAlive(hero) and hero == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
                GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(ishostile))
                for target in each(ug) do
                    RemoveUnit(target)
                end
                break
            end
        end

    --clear chaos training area if no heroes remain
    elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, x, y) then
        GroupEnumUnitsInRect(ug, gg_rct_ChaosTrainingSpawn, Condition(isplayerAlly))
        for hero in each(ug) do
            if UnitAlive(hero) and hero == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
                GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(ishostile))
                for target in each(ug) do
                    RemoveUnit(target)
                end
                break
            end
        end

    --colosseum
    elseif InColo[pid] then
        ColoPlayerCount = ColoPlayerCount - 1
        InColo[pid] = false
        Fleeing[pid] = false
        EnableItems(pid)
        AwardGold(pid, GoldWon_Colo / 1.5, true)
        SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        ExperienceControl(pid)
        if ColoPlayerCount == 0 then --clear colo
            ClearColo()
        end

    --struggle
    elseif InStruggle[pid] then
        Struggle_Pcount = Struggle_Pcount - 1
        InStruggle[pid] = false
        Fleeing[pid] = false
        EnableItems(pid)
        SetCameraBoundsRectForPlayerEx(p, MAIN_MAP.rect)
        PanCameraToTimedLocForPlayer(p, TownCenter, 0)
        ExperienceControl(pid)
        AwardGold(pid, GoldWon_Struggle * 0.1, true)
        if Struggle_Pcount == 0 then --clear struggle
            ClearStruggle()
        end

    --azazoth reset / gods area
    elseif TableHas(AZAZOTH_GROUP, p) then
        TableRemove(AZAZOTH_GROUP, p)

        if ChaosMode then
            DisplayTimedTextToForce(FORCE_PLAYING, 20.00, "|c00ff3333Azazoth: Mortal weakling, begone! Your flesh is not even worth annihilation.")

            if #AZAZOTH_GROUP == 0 then
                UnitRemoveBuffsBJ(bj_REMOVEBUFFS_ALL, BossTable[BOSS_AZAZOTH].unit)
                SetUnitLifePercentBJ(BossTable[BOSS_AZAZOTH].unit, 100)
                SetUnitManaPercentBJ(BossTable[BOSS_AZAZOTH].unit, 100)
                SetUnitPosition(BossTable[BOSS_AZAZOTH].unit, GetRectCenterX(gg_rct_Azazoth_Boss_Spawn), GetRectCenterY(gg_rct_Azazoth_Boss_Spawn))
                BlzSetUnitFacingEx(BossTable[BOSS_AZAZOTH].unit, 90.00)
            end
        end

        SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
        PanCameraToTimedLocForPlayer(p, TownCenter, 0)

    --naga dungeon
    elseif TableHas(NAGA_GROUP, p) then
        TableRemove(NAGA_GROUP, p)
        EnableItems(pid)

        if #NAGA_GROUP <= 0 then
            PauseTimer(NAGA_TIMER)
            TimerStart(NAGA_TIMER, 0.01, false, NAGA_TIMER_END)
            for target in each(NAGA_ENEMIES) do
                RemoveUnit(target)
            end
        end
    end

    DestroyGroup(ug)
end

---@type fun(pid: integer)
function HeroGraveExpire(pid)
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
            itm:charge(itm.charges - 1)
            heal = ItemData[itm.id][ITEM_ABILITY] * 0.01

            if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') and itm.charges <= 0 then --remove perishable resurrections
                itm:destroy()
            end

            RevivePlayer(pid, GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]), heal, heal)
        elseif Hardcore[pid] then --hardcore death
            DisplayTextToPlayer(p, 0, 0, "You have died on Hardcore mode, you cannot revive. However, you may -repick to begin a new character in a new character save slot.")
            DeathHandler(pid)

            PlayerCleanup(pid)
        else --softcore death
            ChargeNetworth(p, 0, 0.02, 50 * GetHeroLevel(Hero[pid]), "Dying has cost you")
            local pt = TimerList[pid]:add()
            pt.tag = FourCC('dead')
            RTimerBox[pid] = CreateTimerDialog(pt.timer)
            TimerDialogSetTitle(RTimerBox[pid], User[pid - 1].nameColored)
            TimerDialogDisplay(RTimerBox[pid], true)
            pt.timer:callDelayed(IMinBJ(IMaxBJ(GetUnitLevel(Hero[pid]) - 10, 0), 30), onRevive, pt)
            DeathHandler(pid)
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
    local itm      = GetResurrectionItem(pid, false) ---@type Item 
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
        TimerQueue:callDelayed(12.5, DestroyEffect, HeroReviveIndicator[pid])
    end

    HeroTimedLife[pid] = AddSpecialEffect("war3mapImported\\Progressbar.mdl", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))
    BlzSetSpecialEffectZ(HeroTimedLife[pid], BlzGetUnitZ(HeroGrave[pid]) + 200.)
    BlzSetSpecialEffectColorByPlayer(HeroTimedLife[pid], Player(pid - 1))
    BlzPlaySpecialEffectWithTimeScale(HeroTimedLife[pid], ANIM_TYPE_BIRTH, 0.099)
    BlzSetSpecialEffectScale(HeroTimedLife[pid], 1.25)

    TimerQueue:callDelayed(12.5, HeroGraveExpire, pid)

    if sniperstance[pid] then --Reset Tri-Rocket
        sniperstance[pid] = false
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 0, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 1, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 2, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 3, 6.)
        BlzSetUnitAbilityCooldown(Hero[pid], TRIROCKET.id, 4, 6.)
    end
end

---@type fun(killed: unit, killer: unit, awardGold: number)
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

    GroupEnumUnitsInRect(ug, gg_rct_Gods_Vision, isplayerunitRegion)

    for target in each(ug) do
        SetUnitPositionLoc(target, TownCenter)
        if target == Hero[GetPlayerId(GetOwningPlayer(target)) + 1] then
            TableRemove(AZAZOTH_GROUP, GetOwningPlayer(target))
            SetCameraBoundsRectForPlayerEx(GetOwningPlayer(target), gg_rct_Main_Map_Vision)
            PanCameraToTimedLocForPlayer(GetOwningPlayer(target), TownCenter, 0)
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
                UnitAddItem(BossTable[i].unit, Item.create(CreateItem(BossTable[i].item[j], 30000., 30000.)))
            end
        end
        SetHeroLevel(BossTable[i].unit, BossTable[i].level, false)
        if HARD_MODE > 0 then --reapply hardmode
            SetHeroStr(BossTable[i].unit, GetHeroStr(BossTable[i].unit, true) * 2, true)
            BlzSetUnitBaseDamage(BossTable[i].unit, BlzGetUnitBaseDamage(BossTable[i].unit, 0) * 2 + 1, 0)
        end
    end

    DeadGods = 0
end

---@type fun(pt: PlayerTimer)
function BossRespawn(pt)
    local index = IsBoss(pt.uid)

    if index ~= -1 then
        if pt.uid == BossTable[BOSS_LIFE].id then --revive gods
            ReviveGods()
            DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00" .. BossTable[index].name .. " have revived.|r")
        else
            local ug = CreateGroup()

            if pt.uid == FourCC('H040') or pt.uid == FourCC('H04R') then --death knight / legion
                repeat
                    RemoveLocation(BossTable[index].loc)
                    BossTable[index].loc = GetRandomLocInRect(MAIN_MAP.rect)
                    GroupEnumUnitsInRangeOfLoc(ug, BossTable[index].loc, 4000., Condition(isbase))
                until IsTerrainWalkable(GetLocationX(BossTable[index].loc), GetLocationY(BossTable[index].loc)) and BlzGroupGetSize(ug) == 0 and RectContainsLoc(gg_rct_Town_Boundry, BossTable[index].loc) == false and RectContainsLoc(gg_rct_Top_of_Town, BossTable[index].loc) == false
            end

            DestroyGroup(ug)

            BossTable[index]:revive()
            DestroyEffect(AddSpecialEffectLoc("Abilities\\Spells\\Orc\\Reincarnation\\ReincarnationTarget.mdl", BossTable[index].loc))
            for j = 1, 6 do
                if BossTable[index].item[j] ~= 0 then
                    local itm = Item.create(CreateItem(BossTable[index].item[j], 30000., 30000.))
                    UnitAddItem(BossTable[index].unit, itm.obj)
                    itm:lvl(ItemData[itm.id][ITEM_UPGRADE_MAX])
                end
            end
            SetHeroLevel(BossTable[index].unit, BossTable[index].level, false)
            if HARD_MODE > 0 then --reapply hardmode
                SetHeroStr(BossTable[index].unit, GetHeroStr(BossTable[index].unit,true) * 2, true)
                BlzSetUnitBaseDamage(BossTable[index].unit, BlzGetUnitBaseDamage(BossTable[index].unit, 0) * 2 + 1, 0)
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

    if uid == FourCC('O02T') then
        DisplayTimedTextToForce(FORCE_PLAYING, 50, "Type -flee to exit the area, or wait 60 seconds.")
        TimerQueue:callDelayed(60., AzazothExit)
    elseif uid == FourCC('E00B') or uid == FourCC('E00D') or uid == FourCC('E00C') then
        DeadGods = DeadGods + 1

        if DeadGods == 3 then --spawn goddess of life
            if GodsRepeatFlag == false then
                GodsRepeatFlag = true
                DoTransmissionBasicsXYBJ(BossTable[BOSS_LIFE].id, GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(BossTable[BOSS_LIFE].unit), GetUnitY(BossTable[BOSS_LIFE].unit), nil, "Goddess of Life", "This is your last chance.", 6)
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
    pt.agi = uid
    pt.tag = 'boss'
    pt.uid = BOSS_ID

    delay = delay * bossResMod

    if RESPAWN_DEBUG then
        delay = 5.
    end

    pt.timer:callDelayed(delay, BossRespawn, pt)
end

---@type fun(): boolean
function OnDeath()
    local u            = GetTriggerUnit()
    local u2           = GetKillingUnit()
    local x            = GetUnitX(u)
    local y            = GetUnitY(u)
    local uid          = GetUnitTypeId(u)
    local p            = GetOwningPlayer(u)
    local p2           = GetOwningPlayer(u2)
    local pid          = GetPlayerId(p) + 1
    local kpid         = GetPlayerId(p2) + 1
    local dropflag     = true
    local spawnflag    = false
    local goldflag     = false
    local xpflag       = false
    local trainingflag = false
    local unitType     = DropTable:getType(uid)
    local index        = IsBoss(unitType)
    local U            = User.first

    if EXTRA_DEBUG then
        DEBUGMSG(GetObjectName(uid))
    end

    --hero skills
    while U do
        --dark savior soul steal
        if IsEnemy(pid) and IsUnitInRange(Hero[U.id], u, 1000. * LBOOST[U.id]) and UnitAlive(Hero[U.id]) and GetUnitAbilityLevel(Hero[U.id], SOULSTEAL.id) > 0 then
            HP(Hero[U.id], BlzGetUnitMaxHP(Hero[U.id]) * 0.04)
            MP(Hero[U.id], BlzGetUnitMaxMana(Hero[U.id]) * 0.04)
        end
        U = U.next
    end

    --determine flags based on area
    if IsEnemy(pid) and IsUnitEnemy(u, p2) then
        if RectContainsCoords(gg_rct_Training_Chaos, x, y) then
            trainingflag = true
            goldflag = true
            xpflag = true
            dropflag = false
            RemoveUnit(u)
        elseif RectContainsCoords(gg_rct_Training_Prechaos, x, y) then
            trainingflag = true
            goldflag = true
            xpflag = true
            dropflag = false
            RemoveUnit(u)
        elseif IsUnitInGroup(u, ColoWaveGroup) then --Colo 
            goldflag = false
            xpflag = true
            dropflag = false
            GroupRemoveUnit(ColoWaveGroup, u)

            GoldWon_Colo = GoldWon_Colo + R2I(RewardGold[GetUnitLevel(u)] / Gold_Mod[ColoPlayerCount])
            Colosseum_Monster_Amount = Colosseum_Monster_Amount - 1

            TimerQueue:callDelayed(1, RemoveUnit, u)
            SetTextTagText(ColoText, "Gold won: " .. ((GoldWon_Colo)), 10 * 0.023 / 10)
            if BlzGroupGetSize(ColoWaveGroup) == 0 then
                TimerQueue:callDelayed(3., AdvanceColo)
            end
        elseif IsUnitInGroup(u, StruggleWaveGroup) then --struggle enemies
            goldflag = true
            xpflag = true
            dropflag = false
            GroupRemoveUnit(StruggleWaveGroup, u)

            GoldWon_Struggle= GoldWon_Struggle + R2I(RewardGold[GetUnitLevel(u)]*.65 *Gold_Mod[Struggle_Pcount])

            TimerQueue:callDelayed(1, RemoveUnit, u)
            SetTextTagText(StruggleText,"Gold won: " +(GoldWon_Struggle),0.023)
            if (Struggle_WaveUCN == 0) and BlzGroupGetSize(StruggleWaveGroup) == 0 then
                TimerQueue:callDelayed(3., AdvanceStruggle, 0)
            end
        elseif IsUnitInGroup(u, NAGA_ENEMIES) then --naga dungeon
            dropflag = false
            GroupRemoveUnit(NAGA_ENEMIES, u)

            if BlzGroupGetSize(NAGA_ENEMIES) <= 0 then
                if NAGA_FLOOR < 3 then
                    nagachest = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h002'), -23000, -3750, 270)
                    nagatp = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n00O'), -21894, -4667, 270)
                    MovePlayers(NAGA_GROUP, -24000, -4700, gg_rct_Naga_Dungeon_Reward_Vision)
                else --naga boss
                    nagachest = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('h002'), -22141, -10500, 0)
                    nagatp = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), FourCC('n00O'), -20865, -10500, 270)
                    DisplayTextToTable(NAGA_GROUP, "You have vanquished the Ancient Nagas!")
                    StartSound(bj_questCompletedSound)
                    PauseTimer(NAGA_TIMER)
                    TimerDialogDisplay(NAGA_TIMER_DISPLAY, false)
                    if not timerflag then --time restriction
                        Item.create(CreateItem(FourCC('I0NN'), x, y)) --token
                        if DungeonTable[DUNGEON_NAGA][DUNGEON_PLAYER_COUNT] > 3 and GetRandomInt(0, 99) < 50 then
                            Item.create(CreateItem(FourCC('I0NN'), x, y))
                        end
                    end
                    timerflag = false
                    for i = 0, PLAYER_CAP do
                        if TableHas(NAGA_GROUP, Player(i)) then
                            local XP = R2I(Experience_Table[500] / 700. * XP_Rate[i + 1])
                            AwardXP(i + 1, XP)
                            EnableItems(i + 1)
                        end
                    end
                end
                WaygateSetDestination(nagatp, -27637, -7440)
                WaygateActivate(nagatp, true)
            end
        elseif uid == FourCC('h04S') then --power crystal
            dropflag = false
            BeginChaos() --chaos
        else
            spawnflag = true
            goldflag = true
            xpflag = true
        end
    end

    if IsUnitIllusion(u) then
        dropflag = false
        spawnflag = false
        goldflag = false
        xpflag = false
    end

    if xpflag then
        RewardXPGold(u, u2, goldflag)
    end

    --========================
    -- Item Drops / Rewards
    --========================

    if dropflag and not trainingflag then
        --special cases
        --forest corruption
        if u == forest_corruption then
            Item.create(CreateItem(FourCC('I03X'), x, y), 600.) --corrupted essence
        end

        --ice troll
        if u == ice_troll then
            Item.create(CreateItem('I040', x, y)) --key of redemption
        end

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

                if GetUnitLevel(u) > 45 and GetUnitLevel(u) < 85 and rand < (0.05 * GetUnitLevel(u)) then
                    Item.create(CreateItem(FourCC('I02Q'), GetUnitX(u), GetUnitY(u)), 600.)
                elseif GetUnitLevel(u) > 265 and GetUnitLevel(u) < 305 and rand < (0.02 * GetUnitLevel(u)) then
                    Item.create(CreateItem(FourCC('I04Z'), GetUnitX(u), GetUnitY(u)), 600.)
                end
            end
        end
    end

    --========================
    -- Quests
    --========================

    if unitType > 0 and KillQuest[unitType][KILLQUEST_STATUS] == 1 and GetHeroLevel(Hero[kpid]) <= KillQuest[unitType][KILLQUEST_MAX] + LEECH_CONSTANT then
        KillQuest[unitType][KILLQUEST_COUNT] = KillQuest[unitType][KILLQUEST_COUNT] + 1
        FloatingTextUnit(KillQuest[unitType][KILLQUEST_NAME] .. " " .. (KillQuest[unitType][KILLQUEST_COUNT]) .. "/" .. (KillQuest[unitType][KILLQUEST_GOAL]), u, 3.1 ,80, 90, 9, 125, 200, 200, 0, true)

        if KillQuest[unitType][KILLQUEST_COUNT] >= KillQuest[unitType][KILLQUEST_GOAL] then
            KillQuest[unitType][KILLQUEST_STATUS] = 2
            KillQuest[unitType][KILLQUEST_LAST] = uid
            DisplayTimedTextToForce(FORCE_PLAYING, 12, KillQuest[unitType][KILLQUEST_NAME] .. " quest completed, talk to the Huntsman for your reward.")
        end
    end

    --the horde
    if IsQuestDiscovered(Defeat_The_Horde_Quest) and IsQuestCompleted(Defeat_The_Horde_Quest) == false and (uid == FourCC('o01I') or uid == FourCC('o008')) then --Defeat the Horde
        local ug = CreateGroup()
        GroupEnumUnitsOfPlayer(ug, pboss, Filter(isOrc))

        if BlzGroupGetSize(ug) == 0 and UnitAlive(kroresh) and GetUnitAbilityLevel(kroresh, FourCC('Avul')) > 0 then
            UnitRemoveAbility(kroresh, FourCC('Avul'))
            if RectContainsUnit(MAIN_MAP.rect, kroresh) == false then
                SetUnitPosition(kroresh, 14650, -15300)
            end
            DoTransmissionBasicsXYBJ(GetUnitTypeId(kroresh), GetPlayerColor(pboss), GetUnitX(kroresh), GetUnitY(kroresh), nil, "Kroresh Foretooth", "You dare slaughter my men? Damn you!", 5)
        end

        DestroyGroup(ug)
    end

    --kroresh
    if u == kroresh then
        QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "|cffffcc00OPTIONAL QUEST COMPLETE|r\nThe Horde")
        QuestSetCompleted(Defeat_The_Horde_Quest, true)
        TalkToMe20 = AddSpecialEffectTarget("Abilities\\Spells\\Other\\TalkToMe\\TalkToMe.mdl", gg_unit_n02Q_0382, "overhead")

    --key quest
    elseif u == BossTable[BOSS_ARKADEN].unit and not ChaosMode and IsUnitHidden(god_angel) then --arkaden
        SetUnitAnimation(god_angel, "birth")
        ShowUnit(god_angel, true)
        DoTransmissionBasicsXYBJ(GetUnitTypeId(god_angel), GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(god_angel), GetUnitY(god_angel), nil, "Angel", "Halt! Before proceeding you must bring me the 3 keys to unlock the seal and face the gods in their domain.", 7.5)

    --zeknen
    elseif u == zeknen then
        DeadGods = 0
        DoTransmissionBasicsXYBJ(BossTable[BOSS_LIFE].id, GetPlayerColor(Player(PLAYER_NEUTRAL_PASSIVE)), GetUnitX(BossTable[BOSS_LIFE].unit), GetUnitY(BossTable[BOSS_LIFE].unit), nil, "Goddess of Life", "You are foolish to challenge us in our realm. Prepare yourself.", 7.5)

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

    --evil shopkeeper
    elseif u == gg_unit_n01F_0576 then
        QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "|cffffcc00OPTIONAL QUEST COMPLETED|r\nThe Evil Shopkeeper")
        QuestSetCompleted(Evil_Shopkeeper_Quest_1, true)
        QuestItemSetCompleted(Quest_Req[10], true)
    end

    --========================
    --Homes
    --========================

    if u == PlayerBase[pid] then
        if u2 ~= nil then
            if GetPlayerId(p2) > PLAYER_CAP then
                DisplayTimedTextToForce(FORCE_PLAYING, 45, User[pid - 1].nameColored .. "'s base was destroyed by " .. GetUnitName(u2) .. ".")
            else
                DisplayTimedTextToForce(FORCE_PLAYING, 45, User[pid - 1].nameColored .. "'s base was destroyed by " .. GetPlayerName(p2) .. ".")
            end
        else
            DisplayTimedTextToForce(FORCE_PLAYING, 45, User[pid - 1].nameColored .. "'s base has been destroyed.")
        end

        BaseID[pid] = 0
        PlayerBase[pid] = nil
        if destroyBaseFlag[pid] then
            destroyBaseFlag[pid] = false
        else
            DisplayTextToPlayer(p, 0, 0, "|cffff0000You must build another base within 2 minutes or be defeated. If you are defeated you will lose your character and be unable to save. If you think you are unable to build another base for some reason, then save now.")
            local pt = TimerList[pid]:add()
            pt.tag = FourCC('bdie')

            pt.timer:callDelayed(120., BaseDeath, pt)
            DestroyTimerDialog(Timer_Window_TUD[pid])
            Timer_Window_TUD[pid] = CreateTimerDialog(pt.timer.timer)
            TimerDialogSetTitle(Timer_Window_TUD[pid], "Defeat In")
            TimerDialogDisplay(Timer_Window_TUD[pid], false)
            if p == GetLocalPlayer() then
                TimerDialogDisplay(Timer_Window_TUD[pid], true)
            end
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

    elseif u == Hero[pid] then

        --pvp death
        if GetArena(pid) > 0 then --PVP DEATH
            RevivePlayer(pid, x, y, 1, 1)
            UnitRemoveBuffs(u, true, true)
            DisplayTextToForce(FORCE_PLAYING, User[pid - 1].nameColored .. " has been slain by " + User[kpid - 1].nameColored .. "!")
            UnitAddAbility(u, FourCC('Avul'))
            SetUnitAnimation(u, "death")
            PauseUnit(u, true)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", u2, "origin"))
            ArenaDeath(u, u2, GetArena(pid))
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
        if BlzGetUnitAbilityCooldownRemaining(u, REINCARNATION.id) <= 0 and GetUnitAbilityLevel(u, REINCARNATION.id) > 0 then
            ReincarnationRevival[pid] = true
        end

        --high priestess self resurrection
        if BlzGetUnitAbilityCooldownRemaining(u, RESURRECTION.id) <= 0 and GetUnitAbilityLevel(u, RESURRECTION.id) > 0 then
            UnitAddAbility(HeroGrave[pid], FourCC('A045'))
            BlzStartUnitAbilityCooldown(u, RESURRECTION.id, 450. - 50. * GetUnitAbilityLevel(u, RESURRECTION.id))
            ResurrectionRevival[pid] = pid

            BlzSetSpecialEffectScale(HeroReviveIndicator[pid], 0.)
            DestroyEffect(HeroReviveIndicator[pid])
            HeroReviveIndicator[pid] = AddSpecialEffect("UI\\Feedback\\Target\\Target.mdx", GetUnitX(HeroGrave[pid]), GetUnitY(HeroGrave[pid]))

            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetSpecialEffectScale(HeroReviveIndicator[pid], 15.)
            end

            BlzSetSpecialEffectTimeScale(HeroReviveIndicator[pid], 0.)
            BlzSetSpecialEffectZ(HeroReviveIndicator[pid], BlzGetLocalSpecialEffectZ(HeroReviveIndicator[pid]) - 100)
            TimerQueue:callDelayed(12.8, DestroyEffect, HeroReviveIndicator[pid])
        end

        --town paladin
        if u2 == gg_unit_H01T_0259 then
            local pt = TimerList[0]:get('pala', u)

            if pt then
                pt.dur = 0.
            end
        end

    --========================
    --Enemy Respawns
    --========================

    elseif index ~= -1 and p == pboss and IsUnitIllusion(u) == false then
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
                DisplayTimedTextToForce(FORCE_PLAYING, 20., U.nameColored .. " contributed |cffffcc00" .. R2S(BossDamage[#BossTable * index + U.id] * 100. / math.max(damage * 1., 1.)) .. "\x25|r damage to " .. GetUnitName(u) .. ".")
            end
            U = U.next
        end

        TimerQueue:callDelayed(6., RemoveUnit, u)
        BossHandler(uid)

        --reset boss damage recorded
        BossDamage = __jarray(0)

    elseif IsCreep(u) and spawnflag then --Creep Respawn
        local pt = TimerList[PLAYER_NEUTRAL_AGGRESSIVE]:add()
        pt.x = x
        pt.y = y
        pt.agi = 0
        pt.uid = uid
        if ChaosMode then
            pt.agi = 1
        end
        pt.timer:callDelayed(20., RemoveCreep, pt)
        TimerQueue:callDelayed(30.0, RemoveUnit, u)
    end

    return false
end

    local death = CreateTrigger() ---@type trigger 
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(death, u.player, EVENT_PLAYER_UNIT_DEATH, nil)
        u = u.next
    end

    TriggerRegisterPlayerUnitEvent(death, Player(PLAYER_TOWN), EVENT_PLAYER_UNIT_DEATH, nil)
    TriggerRegisterPlayerUnitEvent(death, pboss, EVENT_PLAYER_UNIT_DEATH, nil)

    TriggerRegisterPlayerUnitEvent(death, pfoe, EVENT_PLAYER_UNIT_DEATH, nil)

    TriggerAddCondition(death, Condition(OnDeath))
end)

if Debug then Debug.endFile() end
