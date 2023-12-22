if Debug then Debug.beginFile 'Level' end

OnInit.final("Level", function(require)
    require 'Users'

function LevelUp()
    local u      = GetTriggerUnit() ---@type unit 
    local p        = GetOwningPlayer(u) ---@type player 
    local pid         = GetPlayerId(p) + 1 ---@type integer 
    local level         = GetHeroLevel(u) ---@type integer 
    local uid         = GetUnitTypeId(u) ---@type integer 

    if u == Hero[pid] then
        if uid == HERO_DARK_SUMMONER then --summoning improvement level
            SetUnitAbilityLevel(u, SUMMONINGIMPROVEMENT.id, R2I(GetHeroLevel(u) / 10.) + 1)
        end

        if uid == HERO_DARK_SAVIOR then --dark seal level
            SetUnitAbilityLevel(u, FourCC('A0GO'), R2I(GetHeroLevel(u) / 100.) + 1)
        end

        if uid == HERO_SAVIOR then --light seal level
            SetUnitAbilityLevel(u, LIGHTSEAL.id, R2I(GetHeroLevel(u) / 100.) + 1)
        end

        if uid == HERO_OBLIVION_GUARD then --body of fire level
            SetUnitAbilityLevel(u, BODYOFFIRE.id, R2I(GetHeroLevel(u) / 100.) + 1)
        end

        if uid == HERO_MARKSMAN or uid == HERO_MARKSMAN_SNIPER then --sniper stance level
            SetUnitAbilityLevel(u, SNIPERSTANCE.id, R2I(GetHeroLevel(u) / 50.) + 1)
        end

        if uid == HERO_THUNDERBLADE then --overload level
            SetUnitAbilityLevel(u, OVERLOAD.id, R2I(GetHeroLevel(u) / 75.) + 1)
        end

        if not LOAD_FLAG[pid] then
            if level >= 180 and urhome[pid] <= 4 then
                SoundHandler("Sound\\Interface\\SecretFound.wav", false, p, nil)
                DisplayTimedTextToPlayer(p, 0, 0, 60., "|cffff0000You have reached level 180 and no longer earn experience with regular homes, you must purchase a chaotic home!")
            elseif level <= 15 and urhome[pid] == 0 then
                SoundHandler("Sound\\Interface\\SecretFound.wav", false, p, nil)
                DisplayTimedTextToPlayer(p, 0, 0, 60., "You will stop gaining experience after level 15 without a home, purchase one from the vendors in town and build it near a gold mine.")
            end
        end

        SuspendHeroXP(Backpack[pid], false)
        SetHeroLevel(Backpack[pid],GetHeroLevel(Hero[pid]),false)
        SuspendHeroXP(Backpack[pid], true)

        --handle duds
        for i = 0, 5 do
            local itm = Item[UnitItemInSlot(Backpack[pid], i)]

            if itm then
                if IsItemDud(itm) and (GetHeroLevel(Hero[pid])) >= ItemData[itm.id][ITEM_LEVEL_REQUIREMENT] then
                    itm:toItem()
                end
            end
        end

        local mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 4)
        MultiboardSetItemValue(mbitem, (GetHeroLevel(Hero[pid])))
        MultiboardReleaseItem(mbitem)

        ExperienceControl(pid)
    end
end

    local level         = CreateTrigger() ---@type trigger 
    local u      = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(level, u.player, EVENT_PLAYER_HERO_LEVEL, nil)
        u = u.next
    end

    TriggerAddAction(level, LevelUp)

end)

if Debug then Debug.endFile() end
