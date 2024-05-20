--[[
    dev.lua

    A module used for debugging and testing.
]]

OnInit.final("Dev", function(Require)
    Require('Variables')

    EXTRA_DEBUG    = false ---@type boolean 
    DEBUG_HERO    = false ---@type boolean 
    A_STAR_PATHING = false ---@type boolean 
    MS_OVERRIDE = false
    BUDDHA_MODE    = {} ---@type boolean[] 
    nocd           = {} ---@type boolean[] 
    nocost         = {} ---@type boolean[] 
    SEARCHABLE     = {} ---@type boolean[] 

    DEBUG_COUNT      = 0 ---@type integer 
    WEATHER_OVERRIDE = 0 ---@type integer 

    HELP_TABLE = {
        ["nocd"] = "Toggles spell and item cooldowns off",
        ["cd"] = "Toggles spell and item cooldowns on",
        ["nocost"] = "Toggles spell and item mana costs off",
        ["cost"] = "Toggles spell and item mana costs on",
        ["sight"] = "Sets your hero's sight radius to #. usage: -sight [0-1800]",
        ["dummycount"] = "Prints the number of dummies in the dummy pool",
        ["vision"] = "Reveals the whole map",
        ["novision"] = "Reenables fog of war",
        ["sp"] = "Set the amount of platinum you have to #. usage: -sp [#]",
        ["sa"] = "Set the amount of arcadite you have to #. usage: -sp [#]",
        ["sc"] = "Set the amount of crystals you have to #. usage: -sp [#]",
        ["lvl"] = "Set the selected hero's level to #. usage: -lvl [1-400]",
        ["str"] = "Set the selected hero's strength to #. usage: -str [#]",
        ["agi"] = "Set the selected hero's agility to #. usage: -agi [#]",
        ["int"] = "Set the selected hero's intelligence to #. usage: -int [#]",
        ["g"] = "Set the amount of gold you have to #. usage: -g [#]",
        ["l"] = "Set the amount of lumber you have to #. usage: -l [#]",
        ["day"] = "Set the time of day to morning.",
        ["night"] = "Set the time of day to midnight.",
        ["si"] = "Search for an item by name. usage: -si [Azazoth]",
        ["gi"] = "Give the selected unit an item by id #. usage: -gi [#]",
        ["hero"] = "Spawns an allied hero with player id # and hero type #. usage: -hero [#] [#]. Potentially buggy",
        ["enterchaos"] = "Triggers the transition into chaos",
        ["shopkeeper"] = "Pings the location of the evil shopkeeper",
        ["setweather"] = "Randomly changes the weather with no second argument or changes it to id #. usage: -setweather [#]",
        ["noborders"] = "Allows you to view the entire map",
        ["fastrespawn"] = "Toggles 5 second boss respawn time on/off",
        ["heal"] = "Fully restores the health and mana of the selected unit.",
        ["colo"] = "Sets the current number of players inside the colosseum. Potentially buggy",
        ["hp"] = "Sets the maximum health of the selected unit. usage: -hp [#]",
        ["armor"] = "Sets the armor of the selected unit. usage: -armor [#]",
        ["armortype"] = "Sets the armor type of the selected unit. usage: -armortype [0-7]",
        ["boost"] = "Toggles the spellboost +/-20% variance on/off",
        ["hurt"] = "Damages the selected unit by a percent #. usage: hurt [1-100]",
        ["buddha"] = "Prevents your hero from dying",
        ["tp"] = "Teleports the selected unit to your cursor's position.",
        ["dmg"] = "Sets the base damage of the selected unit to #. usage: -dmg [#]",

        --started skipping some
        ["setprestige"] = "Set the prestige level of a hero type # to level #. usage: -setprestige [#] [#]",

        ["shadowstep"] = "Forces legion / death knight to cast shadow step / death march.",

        ["anim"] = "Plays the animation of the selected unit by id #. usage: -anim [#] (usually 0-10, depends on number of animations)",

        ["itemlevel"] = "Sets the level of the item in your hero's first slot to #. usage: -itemlevel [#]",
        ["maxlevel"] = "Sets the level of the item in your hero's first slot to its maximum.",
        ["itemset"] = "Sets the formula of the item in your hero's first slot. usage: -itemset [tier 1][damage 5|10=2>2%150@2][spellboost*5]. see -help syntax for more item formula info.",
        ["itemformula"] = "Prints the current formula of the item in your hero's first slot.",
        ["restock"] = "Moves the evil shopkeeper to a random location and refreshes his stock.",

        ["syntax"] = [[[tier #] - tier name (0-24)|n[req #] - level requirement
[upg #] - max number of item upgrades for enhancer
[type #] - proficiency (0-all, 1-plate, 2-fullplate, 3-leather, 4-cloth, 5-shield, 6-heavy, 7-sword, 8-dagger, 9-bow, 10-staff)
[limit #] - multiple item restriction (1 - can only have one, 2+ special error messages)
[cost #] - upgrade item price
other keywords: armor, str, agi, int, regen, damage, spellboost, cd (crit damage), cc (crit chance), health, mana, dr, mr, ms, evasion, bat, gold

modifiers:
* - stat is fixed per level // for stuff like spellboost and damage resist that has linear scaling
| - value range
= - flat scaling per level
> - flat scaling per rarity
% - percent scaling per level (default is 100%) // this one is ignorable
@ - unlocks at specified level
# - ability id"]]
    }

    --lookup table
    DEV_CMDS = {
        ["nocd"] = function(p, pid, args)
            nocd[pid] = true
        end,
        ["cd"] = function(p, pid, args)
            nocd[pid] = false
        end,
        ["nocost"] = function(p, pid, args)
            nocost[pid] = true
        end,
        ["cost"] = function(p, pid, args)
            nocost[pid] = false
        end,
        ["sight"] = function(p, pid, args)
            local r = 400.

            if args[2] then
                r = S2I(args[2])
            end

            BlzSetUnitRealField(Hero[pid], UNIT_RF_SIGHT_RADIUS, r)
        end,
        ["dummycount"] = function(p, pid, args)
            print(DUMMY_COUNT)
        end,
        ["vision"] = function(p, pid, args)
            FogMaskEnable(false)
            FogEnable(false)
        end,
        ["novision"] = function(p, pid, args)
            FogMaskEnable(true)
            FogEnable(true)
        end,
        ["sp"] = function(p, pid, args)
            SetCurrency(pid, PLATINUM, S2I(args[2]))
        end,
        ["sa"] = function(p, pid, args)
            SetCurrency(pid, ARCADITE, S2I(args[2]))
        end,
        ["sc"] = function(p, pid, args)
            SetCurrency(pid, CRYSTAL, S2I(args[2]))
        end,
        ["lvl"] = function(p, pid, args)
            if GetHeroLevel(PlayerSelectedUnit[pid]) > S2I(args[2]) then
                UnitStripHeroLevel(PlayerSelectedUnit[pid], GetHeroLevel(PlayerSelectedUnit[pid]) - S2I(args[2]))
            else
                SetHeroLevel(PlayerSelectedUnit[pid], S2I(args[2]), false)
            end
        end,
        ["str"] = function(p, pid, args)
            SetHeroStr(PlayerSelectedUnit[pid], S2I(args[2]), true)
        end,
        ["agi"] = function(p, pid, args)
            SetHeroAgi(PlayerSelectedUnit[pid], S2I(args[2]), true)
        end,
        ["int"] = function(p, pid, args)
            SetHeroInt(PlayerSelectedUnit[pid], S2I(args[2]), true)
        end,
        ["g"] = function(p, pid, args)
            SetCurrency(pid, GOLD, S2I(args[2]))
        end,
        ["l"] = function(p, pid, args)
            SetCurrency(pid, LUMBER, S2I(args[2]))
        end,
        ["day"] = function(p, pid, args)
            SetTimeOfDay(5.95)
        end,
        ["night"] = function(p, pid, args)
            SetTimeOfDay(17.49)
        end,
        ["si"] = function(p, pid, args)
            local search = ""

            for i = 2, #args do
                search = search .. args[i] .. " "
            end
            search = search:gsub("\x25s+$", "")

            FindItem(search, pid)
        end,
        ["gi"] = function(p, pid, args)
            if args[2] then
                local itm = PlayerAddItemById(pid, FourCC(args[2]))
                itm:lvl(IMaxBJ(0, ItemData[itm.id][ITEM_UPGRADE_MAX] - ITEM_MAX_LEVEL_VARIANCE))
            end
        end,
        ["hero"] = function(p, pid, args)
            local id = S2I(args[2])
            local type = SAVE_UNIT_TYPE[S2I(args[3])]

            if id <= PLAYER_CAP and GetPlayerSlotState(Player(id - 1)) ~= PLAYER_SLOT_STATE_PLAYING and type and type ~= 0 then
                RemoveUnit(Hero[id])
                RemoveUnit(HeroGrave[id])

                Hero[id] = CreateUnitAtLoc(Player(id - 1), type, TownCenter, 0)
                HeroID[id] = GetUnitTypeId(Hero[id])
                Profile[id] = Profile.create(id)
                EventSetup(id)
                CharacterSetup(id, false)
            end
        end,
        ["sharecontrol"] = function(p, pid, args)
            SetPlayerAlliance(Player(S2I(args[2]) - 1), p, ALLIANCE_SHARED_CONTROL, true)
        end,
        ["enterchaos"] = function(p, pid, args)
            OpenGodsPortal()
            power_crystal = CreateUnitAtLoc(pfoe, FourCC('h04S'), Location(30000, -30000), bj_UNIT_FACING)
            UnitApplyTimedLife(power_crystal, FourCC('BTLF'), 1.)
        end,
        ["settime"] = function(p, pid, args)
            Profile[pid].hero.time = S2I(args[2])
        end,
        ["punchingbags"] = function(p, pid, args)
            local max = S2I(args[2])

            for i = 0, S2I(args[2]) do
                local r = bj_PI * 2 * i / max
                CreateUnit(pfoe, FourCC('h02D'), GetUnitX(Hero[pid]) + Cos(r) * 30 * i / max, GetUnitY(Hero[pid]) + Sin(r) * 30 * i / max, 270.)
            end
        end,
        ["shopkeeper"] = function(p, pid, args)
            PingMinimap(GetUnitX(evilshopkeeper), GetUnitY(evilshopkeeper), 3)
        end,
        ["setweather"] = function(p, pid, args)
            local w = (args[2] and S2I(args[2])) or 0

            WEATHER_OVERRIDE = w
            WeatherPeriodic()
        end,
        ["noborders"] = function(p, pid, args)
            if GetLocalPlayer() == p then
                SetCameraField(CAMERA_FIELD_ROTATION, 90., 0)
                SetCameraBounds(WorldBounds.minX, WorldBounds.minY, WorldBounds.minX, WorldBounds.maxY, WorldBounds.maxX, WorldBounds.maxY, WorldBounds.maxX, WorldBounds.minY)
            end
            SetMinimapTexture(pid, "war3mapImported\\minimap_noborders.dds")
        end,
        ["displayhint"] = function(p, pid, args)
            DisplayHint()
        end,
        ["fastrespawn"] = function(p, pid, args)
            if RESPAWN_DEBUG then
                print("5 second boss respawn disabled!")
            else
                print("5 second boss respawn enabled!")
            end

            RESPAWN_DEBUG = not RESPAWN_DEBUG
        end,
        ["pause"] = function(p, pid, args)
            PauseUnit(Hero[pid], true)
        end,
        ["unpause"] = function(p, pid, args)
            PauseUnit(Hero[pid], false)
        end,
        ["setfirestorm"] = function(p, pid, args)
            firestormRate = S2I(args[2])
        end,
        ["horde"] = function(p, pid, args)
            for _ = 0, 39 do
                CreateUnitAtLoc(pfoe, FourCC('n07R'), GetUnitLoc(Hero[pid]), GetRandomReal(0, 359))
            end
        end,
        ["kill"] = function(p, pid, args)
            DamageTarget(Hero[pid], PlayerSelectedUnit[pid], BlzGetUnitMaxHP(PlayerSelectedUnit[pid]) * 2., ATTACK_TYPE_NORMAL, PURE, "Kill")
        end,
        ["ally"] = function(p, pid, args)
            CreateUnit(p, FourCC(args[2]), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0, 359))
        end,
        ["setowner"] = function(p, pid, args)
            SetUnitOwner(PlayerSelectedUnit[pid], Player(S2I(args[2])), true)
        end,
        ["enemy"] = function(p, pid, args)
            CreateUnit(pfoe, FourCC(args[2]), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0, 359))
        end,
        ["donation"] = function(p, pid, args)
            print("weather rate: " .. R2S(donation))
        end,
        ["afktest"] = function(p, pid, args)
            AFKClock()
        end,
        ["help"] = function(p, pid, args)
            local text = ""

            if HELP_TABLE[args[2]] then
                text = HELP_TABLE[args[2]]
            else
                for key, _ in pairs(DEV_CMDS) do
                    text = text .. "-" .. key .. " "
                end
            end

            DisplayTextToPlayer(p, 0, text:len() ^ 0.05 - 0.8, text)
        end,
        ["setprestige"] = function(p, pid, args)
            PrestigeTable[pid][S2I(args[2])] = S2I(args[3])
            SetPrestigeEffects(pid)
            UpdatePrestigeTooltips()
        end,
        ["wells"] = function(p, pid, args)
            for i = 0, 4 do
                PingMinimap(GetUnitX(well[i]), GetUnitY(well[i]), 1)
            end
        end,
        ["createwell"] = function(p, pid, args)
            CreateWell()
        end,
        ["killall"] = function(p, pid, args)
            local ug = CreateGroup()

            GroupEnumUnitsInRect(ug, WorldBounds.rect, nil)

            for target in each(ug) do
                KillUnit(target)
            end

            DestroyGroup(ug)
        end,
        ["print"] = function(p, pid, args)
            print(StringHash(args[2]))
        end,
        ["printc"] = function(p, pid, args)
            print(FourCC(args[2]))
        end,
        ["test"] = function(p, pid, args)
            SetCurrency(pid, GOLD, 9999999)
            SetCurrency(pid, LUMBER, 9999999)
            SetCurrency(pid, PLATINUM, 9999)
            SetCurrency(pid, ARCADITE, 9999)
            SetCurrency(pid, CRYSTAL, 9999)
            SetHeroLevel(Hero[pid], 400, false)
            PlayerAddItemById(pid, FourCC('I0M8'))
            FogMaskEnable(false)
            FogEnable(false)
            ExperienceControl(pid)
        end,
        ["heal"] = function(p, pid, args)
            SetWidgetLife(PlayerSelectedUnit[pid], BlzGetUnitMaxHP(PlayerSelectedUnit[pid]))
            SetUnitState(PlayerSelectedUnit[pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(PlayerSelectedUnit[pid]))
        end,
        ["yeah"] = function(p, pid, args)
            print((StringHash(GetLocalizedString("TRIGSTR_001"))))
        end,
        ["invul"] = function(p, pid, args)
            if GetUnitAbilityLevel(PlayerSelectedUnit[pid], FourCC('Avul')) > 0 then
                UnitRemoveAbility(PlayerSelectedUnit[pid], FourCC('Avul'))
            else
                UnitAddAbility(PlayerSelectedUnit[pid], FourCC('Avul'))
            end
        end,
        ["colo"] = function(p, pid, args)
            ColoPlayerCount = S2I(args[2])
        end,
        ["hp"] = function(p, pid, args)
            SetWidgetLife(PlayerSelectedUnit[pid], S2I(args[2]))
            BlzSetUnitMaxHP(PlayerSelectedUnit[pid], S2I(args[2]))
        end,
        ["armor"] = function(p, pid, args)
            BlzSetUnitArmor(PlayerSelectedUnit[pid], S2I(args[2]))
        end,
        ["armortype"] = function(p, pid, args)
            BlzSetUnitIntegerField(PlayerSelectedUnit[pid], UNIT_IF_DEFENSE_TYPE, S2I(args[2]))
        end,
        ["boost"] = function(p, pid, args)
            if BOOST_OFF then
                DisplayTextToPlayer(p, 0, 0, "Boost enabled.")
                BOOST_OFF = false
            else
                DisplayTextToPlayer(p, 0, 0, "Boost disabled.")
                BOOST_OFF = true
            end
        end,
        ["hurt"] = function(p, pid, args)
            SetWidgetLife(PlayerSelectedUnit[pid], GetWidgetLife(PlayerSelectedUnit[pid]) - BlzGetUnitMaxHP(PlayerSelectedUnit[pid]) * 0.01 * S2I(args[2]))
        end,
        ["buddha"] = function(p, pid, args)
            if BUDDHA_MODE[pid] then
                DisplayTextToPlayer(p, 0, 0, "Buddha disabled.")
                BUDDHA_MODE[pid] = false
            else
                DisplayTextToPlayer(p, 0, 0, "Buddha enabled.")
                BUDDHA_MODE[pid] = true
            end
        end,
        ["votekicktest"] = function(p, pid, args)
            votekickPlayer = pid
            ResetVote()
            VOTING_TYPE = 2

            local U = User.first
            while U do
                if GetLocalPlayer() == U.player then
                    BlzFrameSetVisible(votingBG, true)
                end
                U = U.next
            end
        end,
        ["saveall"] = function(p, pid, args)
            local U = User.first
            while U do
                ActionSave(U.player)
                U = U.next
            end
        end,
        ["tp"] = function(p, pid, args)
            SetUnitPosition(PlayerSelectedUnit[pid], MouseX[pid], MouseY[pid])
        end,
        ["coloxp"] = function(p, pid, args)
            Colosseum_XP[pid] = 1.3
            DisplayTextToPlayer(p, 0, 0, "Set colosseum xp multiplier to 1.3")
        end,
        ["extradebug"] = function(p, pid, args)
            EXTRA_DEBUG = not EXTRA_DEBUG
        end,
        ["debughero"] = function(p, pid, args)
            DEBUG_HERO = not DEBUG_HERO
        end,
        ["msoverride"] = function(p, pid, args)
            MS_OVERRIDE = not MS_OVERRIDE
        end,
        ["astar"] = function(p, pid, args)
            A_STAR_PATHING = not A_STAR_PATHING
        end,
        ["currentorder"] = function(p, pid, args)
            print((GetUnitCurrentOrder(PlayerSelectedUnit[pid])))
            print(OrderId2String(GetUnitCurrentOrder(PlayerSelectedUnit[pid])))
        end,
        ["currenttarget"] = function(p, pid, args)
            local target = Unit[PlayerSelectedUnit[pid]].target

            print((target and GetUnitName(target)) or "no target")
        end,
        ["dmg"] = function(p, pid, args)
            BlzSetUnitBaseDamage(PlayerSelectedUnit[pid], S2I(args[2]), 0)
        end,
        ["getitemabilstring"] = function(p, pid, args)
            print((ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][ITEM_ABILITY * ABILITY_OFFSET .. "abil"]))
        end,
        ["getitemdata"] = function(p, pid, args)
            print((ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][S2I(args[2])]))
        end,
        ["itemdata"] = function(p, pid, args)
            SetItemUserData(UnitItemInSlot(Hero[pid], 0), S2I(args[2]))
        end,
        ["anim"] = function(p, pid, args)
            SetUnitAnimationByIndex(PlayerSelectedUnit[pid], S2I(args[2]))
        end,
        ["shadowstep"] = function(p, pid, args)
            ShadowStepExpire()
        end,
        ["rotate"] = function(p, pid, args)
            BlzSetUnitFacingEx(PlayerSelectedUnit[pid], S2R(args[2]))
        end,
        ["position"] = function(p, pid, args)
            print(R2S(GetUnitX(PlayerSelectedUnit[pid])) .. " " .. R2S(GetUnitY(PlayerSelectedUnit[pid])))
        end,
        ["prestigehack"] = function(p, pid, args)
            Profile[pid].hero.prestige = 2
        end,
        ["skills"] = function(p, pid, args)
            print(BlzGetAbilityStringLevelField(BlzGetUnitAbilityByIndex(Hero[pid], S2I(args[2])), ABILITY_SLF_TOOLTIP_NORMAL, 0))
            print(BlzGetAbilityStringField(BlzGetUnitAbilityByIndex(Hero[pid], S2I(args[2])), ABILITY_SF_NAME))
            print(IntToFourCC(BlzGetAbilityId(BlzGetUnitAbilityByIndex(Hero[pid], S2I(args[2])))))
        end,
        ["encode"] = function(p, pid, args)
            print(Encode(S2I(args[2])))
        end,
        ["makeitem"] = function(p, pid, args)
            Item.create(CreateItem(FourCC('I0OX'), 0, 0))
        end,
        ["FourCC"] = function(p, pid, args)
            print(FourCC(args[2]))
        end,
        ["itemlevel"] = function(p, pid, args)
            Item[UnitItemInSlot(Hero[pid], 0)]:lvl(S2I(args[2]))
        end,
        ["maxlevel"] = function(p, pid, args)
            Item[UnitItemInSlot(Hero[pid], 0)]:lvl(ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][ITEM_UPGRADE_MAX])
        end,
        ["itemset"] = function(p, pid, args)
            Item[UnitItemInSlot(Hero[pid], 0)]:unequip()
            WipeItemStats(GetItemTypeId(UnitItemInSlot(Hero[pid], 0)))
            local text = ""
            for i = 2, #args do
                text = text .. args[i] .. " "
            end
            ParseItemTooltip(UnitItemInSlot(Hero[pid], 0), text)
            Item[UnitItemInSlot(Hero[pid], 0)]:update()
            Item[UnitItemInSlot(Hero[pid], 0)]:equip()
        end,
        ["itemprint"] = function(p, pid, args)
            print(BlzGetItemExtendedTooltip(UnitItemInSlot(Hero[pid], 0)))
        end,
        ["itemformula"] = function(p, pid, args)
            print(ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][ITEM_TOOLTIP])
        end,
        ["mode"] = function(p, pid, args)
            print(GetLocalizedString("ASSET_MODE"))
        end,
        ["ablev"] = function(p, pid, args)
            print(GetUnitAbilityLevel(Hero[pid], FourCC(args[2])))
        end,
        ["shunpo"] = function(p, pid, args)
            ShowUnit(PlayerSelectedUnit[pid], false)
            ShowUnit(PlayerSelectedUnit[pid], true)
        end,
        ["pathable"] = function(p, pid, args)
            if IsTerrainWalkable(MouseX[pid], MouseY[pid]) then
                print("yeah")
            end
        end,
        ["heropos"] = function(p, pid, args)
            print(R2S(GetUnitX(Hero[pid])))
            print(R2S(GetUnitY(Hero[pid])))
        end,
        ["afk?"] = function(p, pid, args)
            print("Screen pan count: " .. panCounter[pid])
            print("Cursor move count: " .. moveCounter[pid])
            print("Click count: " .. clickCounter[pid])

            if panCounter[pid] < 50 or moveCounter[pid] < 5000 or clickCounter[pid] < 200 then
                print("Yes")
            else
                print("No")
            end
        end,
        ["setskin"] = function(p, pid, args)
            CosmeticTable[User[p].name][S2I(args[2])] = S2I(args[3])
        end,
        ["setaura"] = function(p, pid, args)
            CosmeticTable[User[p].name][S2I(args[2]) + DONATOR_AURA_OFFSET] = S2I(args[3])
        end,
        ["id2char"] = function(p, pid, args)
            print(GetObjectName(SAVE_UNIT_TYPE[S2I(args[2])]))
        end,
        ["addspell"] = function(p, pid, args)
            UnitAddAbility(PlayerSelectedUnit[pid], FourCC(args[2]))
        end,
        ["removespell"] = function(p, pid, args)
            UnitRemoveAbility(PlayerSelectedUnit[pid], FourCC(args[2]))
        end,
        ["restock"] = function(p, pid, args)
            ShopkeeperMove()
        end,
        ["host"] = function(p, pid, args)
            local host = DetectHost()

            if host then
                print("The host is " .. User[host].nameColored)
            end
        end,
        ["removetest"] = function(p, pid, args)
            awesome_unit = CreateUnit(Player(0), FourCC('h00F'), 0, 0, 0)
            print(type(awesome_unit))
            RemoveUnit(awesome_unit)
            print(type(awesome_unit))
        end,
        ["keys"] = function(p, pid, args)
            for index = 8,255 do
                local trigger = CreateTrigger()
                TriggerAddAction(trigger, function()
                    print("OsKey:",index, "meta",BlzGetTriggerPlayerMetaKey())
                end)
                local key = ConvertOsKeyType(index)
                for metaKey = 0,15,1 do
                    BlzTriggerRegisterPlayerKeyEvent(trigger, p, key, metaKey, true)
                    BlzTriggerRegisterPlayerKeyEvent(trigger, p, key, metaKey, false)
                end
            end
        end,
        ["handlecount"] = function(p, pid, args)
            local t = CreateTrigger()
            local i = GetHandleId(t)
            DestroyTrigger(t)
            print(i - 0x100000)
        end,
        ["gc"] = function()
            print(GC)
        end,
    }

---@param pid integer
function EventSetup(pid)
    local i  = pid - 1 ---@type integer 
    local i2 = 0 ---@type integer 
    local p  = Player(pid - 1) ---@type player 

    --make user
    if not User[p] then
        User[p] = {}
        setmetatable(User[p], { __index = User })
        User[p].player = p
        User[p].id = i + 1
        User[p].isPlaying = true
        User[p].color = GetPlayerColor(p)
        User[p].name = GetPlayerName(p)
        User[p].hex = OriginalHex[i]
        User[p].nameColored = User[p].hex .. User[p].name .. "|r"

        User.last = User[p]

        User[p].prev = User[User.AmountPlaying - 1]
        User[p].prev.next = User[p]
        User[p].next = nil

        User[User.AmountPlaying] = User[p]
        User.AmountPlaying = User.AmountPlaying + 1

        TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_LEAVE)
        TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_DEFEAT)

        ForceAddPlayer(FORCE_PLAYING, p)
    end

    local index = User.AmountPlaying
    MULTIBOARD.MAIN:addRows(1)
    MULTIBOARD.MAIN:get(index, 1).text = {0.02, 0, 0.09, MULTIBOARD.ICON_SIZE}
    MULTIBOARD.MAIN:get(index, 2).icon = {0.11, 0, MULTIBOARD.ICON_SIZE, MULTIBOARD.ICON_SIZE}
    MULTIBOARD.MAIN:get(index, 3).icon = {0.13, 0, MULTIBOARD.ICON_SIZE, MULTIBOARD.ICON_SIZE}
    MULTIBOARD.MAIN:get(index, 4).text = {0.15, 0, 0.08, MULTIBOARD.ICON_SIZE}
    MULTIBOARD.MAIN:get(index, 5).text = {0.23, 0, 0.03, MULTIBOARD.ICON_SIZE}
    MULTIBOARD.MAIN:get(index, 6).text = {0.26, 0, 0.03, MULTIBOARD.ICON_SIZE}
    MULTIBOARD.MAIN:refresh()

    --alliance setup
    SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), Player(pid - 1), bj_ALLIANCE_ALLIED)
    SetPlayerAlliance(Player(pid - 1), Player(PLAYER_NEUTRAL_PASSIVE), ALLIANCE_SHARED_SPELLS, true)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('o03K'), 1)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('e016'), 15)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('e017'), 8)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('e018'), 3)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('u01H'), 3)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('h06S'), 15)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('h06U'), 3)
    SetPlayerTechMaxAllowed(Player(pid - 1), FourCC('h06T'), 8)
    AddPlayerTechResearched(Player(pid - 1), FourCC('R013'), 1)
    AddPlayerTechResearched(Player(pid - 1), FourCC('R014'), 1)
    AddPlayerTechResearched(Player(pid - 1), FourCC('R015'), 1)
    AddPlayerTechResearched(Player(pid - 1), FourCC('R016'), 1)
    AddPlayerTechResearched(Player(pid - 1), FourCC('R017'), 1)

    i = 0
    while i ~= bj_MAX_PLAYERS do

        i2 = 0
        while i2 ~= bj_MAX_PLAYERS do
            if i ~= i2 then
                SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_VISION, true)
                SetPlayerAlliance(Player(i), Player(i2), ALLIANCE_SHARED_CONTROL, false)
            end
            i2 = i2 + 1
        end

        i = i + 1
    end

    --spell setup
    local spell   = CreateTrigger()
    local cast    = CreateTrigger()
    local finish  = CreateTrigger()
    local learn   = CreateTrigger()
    local channel = CreateTrigger()
    SetPlayerAbilityAvailable(Player(pid - 1), prMulti[0], false) --pr setup
    SetPlayerAbilityAvailable(Player(pid - 1), prMulti[1], false)
    SetPlayerAbilityAvailable(Player(pid - 1), prMulti[2], false)
    SetPlayerAbilityAvailable(Player(pid - 1), prMulti[3], false)
    SetPlayerAbilityAvailable(Player(pid - 1), prMulti[4], false)
    SetPlayerAbilityAvailable(Player(pid - 1), FourCC('A0AP'), false)
    SetPlayerAbilityAvailable(Player(pid - 1), SONG_HARMONY, false)  --bard setup
    SetPlayerAbilityAvailable(Player(pid - 1), SONG_PEACE, false)
    SetPlayerAbilityAvailable(Player(pid - 1), SONG_WAR, false)
    SetPlayerAbilityAvailable(Player(pid - 1), SONG_FATIGUE, false)

    TriggerRegisterUnitEvent(spell, Hero[pid], EVENT_UNIT_SPELL_EFFECT)
    TriggerRegisterUnitEvent(cast, Hero[pid], EVENT_UNIT_SPELL_CAST)
    TriggerRegisterUnitEvent(finish, Hero[pid], EVENT_UNIT_SPELL_CHANNEL)
    TriggerRegisterUnitEvent(learn, Hero[pid], EVENT_UNIT_SPELL_FINISH)
    TriggerRegisterUnitEvent(channel, Hero[pid], EVENT_UNIT_HERO_SKILL)

    TriggerAddAction(spell, SpellEffect)
    TriggerAddAction(cast, SpellCast)
    TriggerAddAction(finish, SpellFinish)
    TriggerAddCondition(learn, Filter(SpellLearn))
    TriggerAddCondition(channel, Filter(SpellChannel))

    --death setup
    local death = CreateTrigger()
    TriggerRegisterUnitEvent(death, Hero[pid], EVENT_UNIT_DEATH)

    TriggerAddAction(death, OnDeath)

    --attack setup
    local attacked = CreateTrigger()
    TriggerRegisterUnitEvent(attacked, Hero[pid], EVENT_UNIT_ATTACKED)

    TriggerAddCondition(attacked, Filter(OnAttack))

    --damage setup
    local beforearmor = CreateTrigger()
    TriggerRegisterUnitEvent(beforearmor, Hero[pid], EVENT_UNIT_DAMAGING)

    TriggerAddCondition(beforearmor, Filter(OnDamage))

    --item setup
    local onpickup = CreateTrigger()
    local ondrop   = CreateTrigger()
    local useitem  = CreateTrigger()
    local onsell   = CreateTrigger()
    TriggerRegisterUnitEvent(onpickup, Hero[pid], EVENT_UNIT_PICKUP_ITEM)
    TriggerRegisterUnitEvent(ondrop, Hero[pid], EVENT_UNIT_DROP_ITEM)
    TriggerRegisterUnitEvent(useitem, Hero[pid], EVENT_UNIT_USE_ITEM)
    TriggerRegisterUnitEvent(onsell, Hero[pid], EVENT_UNIT_PAWN_ITEM)

    --order setup
    local ordertarget = CreateTrigger()
    --TriggerRegisterPlayerUnitEvent(pointOrder, Player(pid - 1), EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, nil)
    --TriggerRegisterPlayerUnitEvent(ordertarget, Player(pid - 1), EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, nil)
    TriggerRegisterPlayerUnitEvent(ordertarget, Player(pid - 1), EVENT_PLAYER_UNIT_ISSUED_ORDER, nil)

    --TriggerAddAction(pointOrder, OnOrder)
    TriggerAddCondition(ordertarget, Condition(OnOrder))

    TriggerAddCondition(onpickup, Condition(PickupFilter))
    TriggerAddAction(onpickup, onPickup)
    TriggerAddAction(ondrop, onDrop)
    TriggerAddAction(useitem, onUse)
    TriggerAddCondition(onsell, Condition(onSell))
end

function PreloadItemSearch()
    local count = 0 ---@type integer 
    local itm ---@type item 

    --searchable items
    --I000 to I0zz (3844~ items)
    for i = 0, 19018 do
        if GetObjectName(CUSTOM_ITEM_OFFSET + i) ~= "Default string" then
            itm = CreateItem(CUSTOM_ITEM_OFFSET + i, 30000., 30000.)
            if GetItemType(itm) ~= ITEM_TYPE_POWERUP and GetItemType(itm) ~= ITEM_TYPE_CAMPAIGN then
                SEARCHABLE[i] = true
            end
            SetWidgetLife(itm, 1.)
            RemoveItem(itm)
        end

        count = count + 1

        --ignore non word/digit characters
        if count == 10 then
            i = i + 7
        elseif count == 36 then
            i = i + 6
        elseif count == 62 then
            i = i + 181
            count = 0
        end
    end
end

---@param id integer
function WipeItemStats(id)
    for i = 1, 30 do
        ItemData[id][i] = 0
        ItemData[id][i .. "range"] = 0
        ItemData[id][i .. "fpl"] = 0
        ItemData[id][i .. "fpr"] = 0
        ItemData[id][i .. "percent"] = 0
        ItemData[id][i .. "unlock"] = 0
        ItemData[id][i .. "fixed"] = 0
        ItemData[id][i * ABILITY_OFFSET] = 0
        ItemData[id][i * ABILITY_OFFSET .. "abil"] = nil
    end
end

function SearchPage()
    local p   = GetTriggerPlayer() ---@type player 
    local pid = GetPlayerId(p) + 1 ---@type integer 
    local dw    = DialogWindow[pid] ---@type DialogWindow 
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        local itm = PlayerAddItemById(pid, dw.data[index])
        itm:lvl(IMaxBJ(0, ItemData[itm.id][ITEM_UPGRADE_MAX] - ITEM_MAX_LEVEL_VARIANCE))

        dw:destroy()
    end

    return false
end

---@param search string
---@param pid integer
function FindItem(search, pid)
    local itemCode = "" ---@type string 
    local id       = 0 ---@type integer 
    local name     = "" ---@type string 
    local count    = 0 ---@type integer 
    local dw = DialogWindow.create(pid, "", SearchPage)

    --searchable items
    --I000 to I0zz (3844~ items)
    for i = 0, 19018 do
        id = CUSTOM_ITEM_OFFSET + i
        itemCode = IntToFourCC(id)
        name = GetObjectName(id)
        if name ~= "" and SEARCHABLE[i] then
            if string.find(name:lower(), search:lower()) then
                dw:addButton(itemCode .. " - " .. name, id)
            end
        end

        if dw.ButtonCount >= DialogWindow.BUTTON_MAX then
            break
        end

        count = count + 1

        --ignore non word/digit characters
        if count == 10 then
            i = i + 7
        elseif count == 36 then
            i = i + 6
        elseif count == 62 then
            i = i + 181
            count = 0
        end
    end

    dw:display()
end

function DevCommands()
    local p    = GetTriggerPlayer() ---@type player 
    local pid  = GetPlayerId(p) + 1 ---@type integer 
    local args = {}

    --propogate args table
    for arg in GetEventPlayerChatString():gmatch("\x25S+") do
        args[#args + 1] = arg
    end

    if DEV_CMDS[args[1]:sub(2)] then
        DEV_CMDS[args[1]:sub(2)](p, pid, args)
    end
end

    local devcmd = CreateTrigger()

    DEV_ENABLED = true
    SAVE_LOAD_VERSION = 2 ^ 30
    MAP_NAME = "CoT Nevermore BETA"

    for i = 0, PLAYER_CAP do
        TriggerRegisterPlayerChatEvent(devcmd, Player(i), "-", false)
    end

    TimerQueue:callDelayed(0., PreloadItemSearch)

    TriggerAddAction(devcmd, DevCommands)
end, Debug.getLine())
