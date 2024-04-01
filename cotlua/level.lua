if Debug then Debug.beginFile 'Level' end

OnInit.final("Level", function(require)
    require 'Users'

function OnLevel()
    local u     = GetTriggerUnit() ---@type unit 
    local p     = GetOwningPlayer(u) ---@type player 
    local pid   = GetPlayerId(p) + 1 ---@type integer 
    local level = GetHeroLevel(u) ---@type integer 
    local uid   = GetUnitTypeId(u) ---@type integer 

    if u == Hero[pid] then
        if uid == HERO_DARK_SUMMONER then --summoning improvement level
            SetUnitAbilityLevel(u, SUMMONINGIMPROVEMENT.id, GetHeroLevel(u) // 10 + 1)
        end

        if uid == HERO_DARK_SAVIOR then --dark seal level
            SetUnitAbilityLevel(u, DARKSEAL.id, GetHeroLevel(u) // 100 + 1)
        end

        if uid == HERO_SAVIOR then --light seal level
            SetUnitAbilityLevel(u, LIGHTSEAL.id, GetHeroLevel(u) // 100 + 1)
        end

        if uid == HERO_OBLIVION_GUARD then --body of fire level
            SetUnitAbilityLevel(u, BODYOFFIRE.id, GetHeroLevel(u) // 100 + 1)
        end

        if uid == HERO_MARKSMAN or uid == HERO_MARKSMAN_SNIPER then --sniper stance level
            SetUnitAbilityLevel(u, SNIPERSTANCE.id, GetHeroLevel(u) // 50 + 1)
        end

        if uid == HERO_THUNDERBLADE then --overload level
            SetUnitAbilityLevel(u, OVERLOAD.id, GetHeroLevel(u) // 75 + 1)
        end

        if uid == HERO_ASSASSIN then --blade spin level
            SetUnitAbilityLevel(u, BLADESPIN.id, IMinBJ(4, GetHeroLevel(u) // 100 + 1))
            SetUnitAbilityLevel(u, BLADESPINPASSIVE.id, IMinBJ(4, GetHeroLevel(u) // 100 + 1))
        end

        if uid == HERO_MASTER_ROGUE then --instant death level
            SetUnitAbilityLevel(u, INSTANTDEATH.id, GetHeroLevel(u) // 50 + 1)
        end

        if not LOAD_FLAG[pid] then
            if level >= 180 and Profile[pid].hero.base <= 4 then
                SoundHandler("Sound\\Interface\\SecretFound.wav", false, p)
                DisplayTimedTextToPlayer(p, 0, 0, 60., "|cffff0000You have reached level 180 and no longer earn experience with regular homes, you must purchase a chaotic home!|r")
            elseif level <= 15 and Profile[pid].hero.base == 0 then
                SoundHandler("Sound\\Interface\\SecretFound.wav", false, p)
                DisplayTimedTextToPlayer(p, 0, 0, 60., "You will stop gaining experience after level 15 without a home, purchase one from the vendors in town and build it near a gold mine.")
            end
        end

        SuspendHeroXP(Backpack[pid], false)
        SetHeroLevel(Backpack[pid],GetHeroLevel(Hero[pid]),false)
        SuspendHeroXP(Backpack[pid], true)

        --update restricted items
        for i = 6, MAX_INVENTORY_SLOTS - 1 do
            local itm = Profile[pid].hero.items[i]

            if itm then
                if (GetHeroLevel(Hero[pid])) >= ItemData[itm.id][ITEM_LEVEL_REQUIREMENT] then
                    itm.restricted = false
                end
            end
        end

        --trigger stat change event
        if EVENT_STAT_CHANGE[u] then
            EVENT_STAT_CHANGE[u](u)
        end

        ExperienceControl(pid)
    end

    return false
end

    local level = CreateTrigger()
    local u = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(level, u.player, EVENT_PLAYER_HERO_LEVEL, nil)
        u = u.next
    end

    TriggerAddCondition(level, Condition(OnLevel))
end)

if Debug then Debug.endFile() end
