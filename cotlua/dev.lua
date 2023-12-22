if Debug then Debug.beginFile 'Dev' end

OnInit.final("Dev", function(require)
    require 'Variables'
    require 'Users'

    SEARCH_DIALOG={} ---@type dialog[] 
    SEARCH_RESULTS=__jarray("") ---@type string[] 
    SEARCH_NEXT={} ---@type button[] 
    SEARCH_PAGE=__jarray(0) ---@type integer[] 
    BUDDHA_MODE=__jarray(false) ---@type boolean[] 
    EXTRA_DEBUG         = false ---@type boolean 
    nocd=__jarray(false) ---@type boolean[] 
    nocost=__jarray(false) ---@type boolean[] 
    SEARCHABLE=__jarray(false) ---@type boolean[] 

    COUNT_DEBUG         = false ---@type boolean 
    DEBUG_COUNT         = 0 ---@type integer 
    WEATHER_OVERRIDE         = 0 ---@type integer 

---@param pid integer
function EventSetup(pid)
    local spell         = CreateTrigger() ---@type trigger 
    local cast         = CreateTrigger() ---@type trigger 
    local finish         = CreateTrigger() ---@type trigger 
    local learn         = CreateTrigger() ---@type trigger 
    local channel         = CreateTrigger() ---@type trigger 
    local death         = CreateTrigger() ---@type trigger 
    local attacked         = CreateTrigger() ---@type trigger 
    local beforearmor         = CreateTrigger() ---@type trigger 
    local onpickup         = CreateTrigger() ---@type trigger 
    local ondrop         = CreateTrigger() ---@type trigger 
    local useitem         = CreateTrigger() ---@type trigger 
    local onsell         = CreateTrigger() ---@type trigger 
    local onpawn         = CreateTrigger() ---@type trigger 
    local u      = User.first ---@type User 
    local i         = pid - 1 ---@type integer 
    local i2         = 0 ---@type integer 
    local p        = Player(pid - 1) ---@type player 

    --make user
    if not User[p] then
        User[i] = User.create()
        User[i].player = p
        User[i].id = i + 1
        User[i].isPlaying = true
        User[i].color = GetPlayerColor(p)
        User[i].name = GetPlayerName(p)
        User[i].hex = OriginalHex[i]
        User[i].nameColored = User[i].hex .. User[i].name .. "|r"

        User.last = User[i]

        if not User.first then
            User.first = User[i]
            User[i].next = nil
            User[i].prev = nil
        else
            User[i].prev = User[User.AmountPlaying - 1]
            User[i].next = nil
        end

        TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_LEAVE)
        TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_DEFEAT)

        ForceAddPlayer(FORCE_PLAYING, p)
    end

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
    SetPlayerAbilityAvailable(Player(pid - 1), DETECT_LEAVE_ABILITY, false)
    SetPlayerAbilityAvailable(Player(pid - 1), FourCC('A0JV'), false) --elementalist setup
    SetPlayerAbilityAvailable(Player(pid - 1), FourCC('A0JX'), false)
    SetPlayerAbilityAvailable(Player(pid - 1), FourCC('A0JW'), false)
    SetPlayerAbilityAvailable(Player(pid - 1), FourCC('A0JZ'), false)
    SetPlayerAbilityAvailable(Player(pid - 1), FourCC('A0JY'), false)
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

    TriggerAddAction(spell, OnEffect)
    TriggerAddAction(cast, OnCast)
    TriggerAddAction(finish, OnFinish)
    TriggerAddCondition(learn, Filter(OnLearn))
    TriggerAddCondition(channel, Filter(OnChannel))

    --death setup
    TriggerRegisterUnitEvent(death, Hero[pid], EVENT_UNIT_DEATH)

    TriggerAddAction(death, onDeath)

    --attack setup
    TriggerRegisterUnitEvent(attacked, Hero[pid], EVENT_UNIT_ATTACKED)

    TriggerAddCondition(attacked, OnAttack)

    --damage setup
    TriggerRegisterUnitEvent(beforearmor, Hero[pid], EVENT_UNIT_DAMAGING)

    TriggerAddCondition(beforearmor, Filter(OnDamage))

    --item setup
    TriggerRegisterUnitEvent(onpickup, Hero[pid], EVENT_UNIT_PICKUP_ITEM)
    TriggerRegisterUnitEvent(ondrop, Hero[pid], EVENT_UNIT_DROP_ITEM)
    TriggerRegisterUnitEvent(useitem, Hero[pid], EVENT_UNIT_USE_ITEM)
    TriggerRegisterUnitEvent(onpawn, Hero[pid], EVENT_UNIT_PAWN_ITEM)

    TriggerAddCondition(onpickup, Condition(ItemFilter))
    TriggerAddAction(onpickup, onPickup)
    TriggerAddAction(ondrop, onDrop)
    TriggerAddAction(useitem, onUse)
    TriggerAddAction(onsell, onSell)
    TriggerAddCondition(onpawn, onPawned)
end

function PreloadItemSearch()
    local count         = 0 ---@type integer 
    local itm ---@type item 

    --searchable items
    --I000 to I0zz (3844~ items)
    for i = 0, 19018 do
        itm = CreateItem(CUSTOM_ITEM_OFFSET + i, 30000., 30000.)
        if itm ~= nil and GetItemType(itm) ~= ITEM_TYPE_POWERUP and GetItemType(itm) ~= ITEM_TYPE_CAMPAIGN then
            SEARCHABLE[i] = true
        end
        RemoveItem(itm)

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
    local i         = 1 ---@type integer 

    while i <= 30 do

        ItemData[id][i] = 0
        ItemData[id][i + BOUNDS_OFFSET * 2] = 0
        ItemData[id][i + BOUNDS_OFFSET * 3] = 0
        ItemData[id][i + BOUNDS_OFFSET * 4] = 0
        ItemData[id][i + BOUNDS_OFFSET * 5] = 0
        ItemData[id][i + BOUNDS_OFFSET * 6] = 0
        ItemData[id][i * ABILITY_OFFSET] = 0
        ItemData[id][i * ABILITY_OFFSET .. "abil"] = nil

        i = i + 1
    end
end

---@param search string
---@param source string
---@return boolean
function StringContainsString(search, source)
    local i ---@type integer 
    local sL ---@type integer 
    local sS ---@type integer 

    if StringLength(search) > StringLength(source) then
        return false
    end

    i = 0
    sL = StringLength(search)
    sS = StringLength(source)
    search = StringCase(search,false)
    source = StringCase(source,false)

    while not (i + sL > sS) do
            if search == SubString(source,i,i + sL) then
                return true
            end
        i = i + 1
    end

    return false
end

---@param pid integer
function ClearSearch(pid)
    local i         = 0 ---@type integer 

    while i <= 799 do

        SEARCH_RESULTS[pid * 800 + i] = ""

        i = i + 1
    end
end

function SearchPage()
    local b        = GetClickedButton() ---@type button 
    local p        = GetTriggerPlayer() ---@type player 
    local pid         = GetPlayerId(p) + 1 ---@type integer 
    local i         = 0 ---@type integer 

    DialogClear(SEARCH_DIALOG[pid])

    if b == SEARCH_NEXT[pid] then
        while not (i > 8 or SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid]] == "") do
            SEARCH_NEXT[pid * 800 + SEARCH_PAGE[pid]] = DialogAddButton(SEARCH_DIALOG[pid], SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid]], 0)
            SEARCH_PAGE[pid] = SEARCH_PAGE[pid] + 1
            i = i + 1
        end
        if SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid]] ~= "" then
            SEARCH_NEXT[pid] = DialogAddButton(SEARCH_DIALOG[pid], "Next page", 0)
        end

        DialogDisplay(p, SEARCH_DIALOG[pid], true)
    else --give item
        while not (b == SEARCH_NEXT[pid * 800 + SEARCH_PAGE[pid] - i] or i > 10) do
            i = i + 1
        end
        PlayerAddItemById(pid, FourCC(SubString(SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid] - i], 0, 4)))
    end
end

---@param search string
---@param pid integer
function FindItem(search, pid)
    local itemCode        = "" ---@type string 
    local i         = 0 ---@type integer 
    local id         = 0 ---@type integer 
    local name        = "" ---@type string 
    local p        = Player(pid - 1) ---@type player 
    local count         = 0 ---@type integer 

    SEARCH_PAGE[pid] = 0
    ClearSearch(pid)
    DialogClear(SEARCH_DIALOG[pid])

    while i <= 8191 do

        id = CUSTOM_ITEM_OFFSET + i
        itemCode = Id2String(id)
        name = GetObjectName(id)
        if name ~= "Default string" and name ~= "" and SEARCHABLE[i] then
            if StringContainsString(search, name) then
                SEARCH_RESULTS[pid * 800 + count] = itemCode .. " - " .. name
                count = count + 1
            end
        end
        if count > 99 then
            break
        end

        i = i + 1
    end

    i = 0
    while not (i > 8 or i > count - 1) do
        SEARCH_NEXT[pid * 800 + i] = DialogAddButton(SEARCH_DIALOG[pid], SEARCH_RESULTS[pid * 800 + i], 0)
        SEARCH_PAGE[pid] = SEARCH_PAGE[pid] + 1
        i = i + 1
    end

    if count > i then
        SEARCH_NEXT[pid] = DialogAddButton(SEARCH_DIALOG[pid], "Next page", 0)
    end

    if count > 0 then
        DialogDisplay(p, SEARCH_DIALOG[pid], true)
    end
end

function DevCommands()
    local currentPlayer        = GetTriggerPlayer() ---@type player 
    local pid         = GetPlayerId(currentPlayer) + 1 ---@type integer 
    local message        = GetEventPlayerChatString() ---@type string 
    local i         = 0 ---@type integer 
    local i2         = 0 ---@type integer 
    local r      = 0 ---@type number 
    local U      = User.first ---@type User 
    local itm ---@type item 

    if (message == "-nocd") then
        nocd[pid] = true
    elseif message == "-cd" or message == "-cdon" then
        nocd[pid] = false
    elseif message == "-vampire" then
        BlzSetUnitRealField(Hero[pid], UNIT_RF_SIGHT_RADIUS, 400.)
        while i <= 7 do
            if Player(i) ~= currentPlayer then
                SetPlayerAlliance(currentPlayer, Player(i), ALLIANCE_SHARED_VISION, false)
                SetPlayerAlliance(Player(i), currentPlayer, ALLIANCE_SHARED_VISION, false)
            end

            i = i + 1
        end
    elseif message == "-dummytest" then
        GetDummy(0, 0, 0, 0, DUMMY_RECYCLE_TIME)
        DEBUGMSG(DUMMY_COUNT)

    elseif(message == "-nocost") then
        nocost[pid] = true
    elseif message == "-cost" or message == "-coston" then
        nocost[pid] = false
    elseif (message == "-vision") then
        FogMaskEnable(false)
        FogEnable(false)
    elseif (message == "-novision") then
        FogMaskEnable(true)
        FogEnable(true)
    elseif SubString(message,0,3)== "-sp" then
        SetCurrency(pid, PLATINUM, S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message,0,3)== "-sa" and SubString(message,3,5) ~= "ve" then
        SetCurrency(pid, ARCADITE, S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message,0,3)== "-sc" then
        SetCurrency(pid, CRYSTAL, S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message,0,5)== "-lvl " then
        if GetHeroLevel(PlayerSelectedUnit[pid]) > S2I(SubString(message, 5, 8)) then
            UnitStripHeroLevel(PlayerSelectedUnit[pid], GetHeroLevel(PlayerSelectedUnit[pid]) - S2I(SubString(message, 5, 8)))
        else
            SetHeroLevel(PlayerSelectedUnit[pid], S2I(SubString(message, 5, 8)),false)
        end
    elseif SubString(message,0,5)== "-str " then
        SetHeroStr(PlayerSelectedUnit[pid], S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,5)== "-agi " then
        SetHeroAgi(PlayerSelectedUnit[pid], S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,5)== "-int " then
        SetHeroInt(PlayerSelectedUnit[pid], S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,3)== "-g " then
        AddCurrency(pid, GOLD, S2I(SubString(GetEventPlayerChatString(), 3, 10)))
    elseif SubString(message,0,3)== "-l " then
        AddCurrency(pid, LUMBER, S2I(SubString(GetEventPlayerChatString(), 3, 10)))
    elseif (message == "-day") then
        SetTimeOfDay(5.95)
    elseif (message == "-night") then
        SetTimeOfDay(17.49)
    elseif (message == "-cycle") then
        SetTimeOfDayScale(50)
    elseif SubString(message,0,4)== "-si " then
        FindItem(SubString(message, 4, StringLength(message)), pid)
    elseif SubString(message,0,4)== "-gi " then
        PlayerAddItemById(pid, FourCC(SubString(message, 4, StringLength(message))))
    elseif (message == "-pfall") or (message == "-allpf") then
        HERO_PROF[pid] = 0x3ff
    elseif (SubString(message, 0, 5) == "-hero") then
        i = S2I(SubString(message, 8, StringLength(message)))
        i2 = SAVE_UNIT_TYPE[S2I(SubString(message, 6, 8))]

        if GetPlayerSlotState(Player(i - 1)) ~= PLAYER_SLOT_STATE_PLAYING and i2 ~= 0 then
            RemoveUnit(Hero[i])
            RemoveUnit(HeroGrave[i])

            Hero[i] = CreateUnitAtLoc(Player(i - 1), i2, TownCenter, 0)
            HeroID[i] = GetUnitTypeId(Hero[i])
            CharacterSetup(i, false)
            EventSetup(i)
        end

    elseif (SubString(message, 0, 13) == "-sharecontrol") then
        SetPlayerAlliance(Player(S2I(SubString(message, 14, StringLength(message))) - 1), currentPlayer, ALLIANCE_SHARED_CONTROL, true)
    elseif (message == "-enterchaos") then
        OpenGodsPortal()
        power_crystal = CreateUnitAtLoc(pfoe, FourCC('h04S'), Location(30000, -30000), bj_UNIT_FACING)
        UnitApplyTimedLife(power_crystal, FourCC('BTLF'), 1.)
    elseif (SubString(message, 0, 8) == "-settime") then
        i = S2I(SubString(message, 9, 19))

        TimePlayed[pid] = i
    elseif (SubString(message, 0, 13) == "-punchingbags") then
        i2 = S2I(SubString(message, 14, StringLength(message)))

        while i ~= i2 do
            i = i + 1
            r = bj_PI * 2 * i / i2
            CreateUnit(pfoe, FourCC('h02D'), GetUnitX(Hero[pid]) + Cos(r) * 30 * i / i2, GetUnitY(Hero[pid]) + Sin(r) * 30 * i / i2, 270.)
        end
    elseif (SubString(message, 0, 11) == "-shopkeeper") then
        PingMinimap(GetUnitX(gg_unit_n01F_0576), GetUnitY(gg_unit_n01F_0576), 3)
    elseif (SubString(message, 0, 11) == "-setweather") then
        WEATHER_OVERRIDE = S2I(SubString(message, 12, StringLength(message)))
        UnitRemoveAbility(WeatherUnit, WeatherTable[CURRENT_WEATHER][WEATHER_ABIL])
        WeatherPeriodic()
    elseif (message== "-noborders") then
        if GetLocalPlayer() == currentPlayer then
            SetCameraField(CAMERA_FIELD_ROTATION, 90., 0)
            SetCameraBounds(WorldBounds.minX, WorldBounds.minY, WorldBounds.minX, WorldBounds.maxY, WorldBounds.maxX, WorldBounds.maxY, WorldBounds.maxX, WorldBounds.minY)
        end
    elseif (SubString(message,0,6) == "-chelp") then
        DisplayTextToPlayer(currentPlayer, 0, 0, [[
        -caoa (angle of attack) 250-330
        -cfow (field of view) 70-120
        -cfarz 5000-10000
        -croll 0-360
        -crot (rotation) 0-360
        -cdist (distance) 1000-10000
        -czoff (z offset) 0-10000
        -deletefloatingtext")
        ]])
    elseif (SubString(message,0,5) == "-caoa") then
        SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, S2R(SubString(message, 6, StringLength(message))), 0)
    elseif (SubString(message,0,5) == "-cfow") then
        SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, S2R(SubString(message, 6, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-cfarz") then
        SetCameraField(CAMERA_FIELD_FARZ, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-croll") then
        SetCameraField(CAMERA_FIELD_ROLL, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (SubString(message,0,5) == "-crot") then
        SetCameraField(CAMERA_FIELD_ROTATION, S2R(SubString(message, 6, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-cdist") then
        SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-czoff") then
        SetCameraField(CAMERA_FIELD_ZOFFSET, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (message == "-deletefloatingtext") then
        DestroyTextTag(GetLastCreatedTextTag())
        DestroyTextTag(ColoText)
        DestroyTextTag(StruggleText)
    elseif (message == "-displayhint") then
        DisplayHint()
    elseif (message == "-hackrespawn") then
        RESPAWN_DEBUG = true
    elseif (message == "-pause") then
        PauseUnit(Hero[pid], true)
    elseif (message == "-unpause") then
        PauseUnit(Hero[pid], false)
    elseif (message == "-evasion") then
        UnitAddAbility(Hero[pid], FourCC('A0JH'))
    elseif (message == "-noevasion") then
        UnitRemoveAbility(Hero[pid], FourCC('A0JH'))
    elseif (SubString(message, 0, 13) == "-setfirestorm") then
        firestormRate = S2I(SubString(message, 14, StringLength(message)))
    elseif (message == "-horde") then
        i = 0

        while i <= 39 do
            CreateUnitAtLoc(pfoe, FourCC('n07R'), GetUnitLoc(Hero[pid]), GetRandomReal(0,359))
            i = i + 1
        end
    elseif (message == "-kill") then
        UnitDamageTarget(Hero[pid], PlayerSelectedUnit[pid], BlzGetUnitMaxHP(PlayerSelectedUnit[pid]) * 2., true, false, ATTACK_TYPE_NORMAL, PURE, WEAPON_TYPE_WHOKNOWS)
    elseif (SubString(message, 0, 5) == "-ally") then
        CreateUnit(currentPlayer, FourCC(SubString(message,6,10)), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0,359))
    elseif (SubString(message, 0, 9) == "-setowner") then
        SetUnitOwner(PlayerSelectedUnit[pid], Player(S2I(SubString(message, 10, StringLength(message)))), true)
    elseif (SubString(message, 0, 6) == "-enemy") then
        CreateUnit(pfoe, FourCC(SubString(message,7,11)), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0,359))
    elseif (message == "-donation") then
        BJDebugMsg("weather rate: " .. R2S(donation))
    elseif (message == "-afktest") then
        AFKClock()
    elseif SubString(message,0,5) == "-help" then
        DisplayTextToPlayer(currentPlayer, 0, 0, "-str / -agi / -int # - Sets stat to #")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-lvl # - Sets hero level to #")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-g / -l # - Sets gold or lumber to #")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-vision / -novision - toggles map vision")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-sp # -sets platcoin to #")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-sa # -sets arclumber to #")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-sc # -sets crystals to #")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-gi - give item, spawns based on 4 character rawcode, eg. I0M8")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-si - search item id by name")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-day / -night")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-cycle - makes time really fast")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-enterchaos - starts chaos mode")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-noborders (removes camera borders so you can see outside the map)")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-setweather #[1 - " .. WEATHER_MAX .. "]")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-cd / -nocd toggles cooldowns")
        DisplayTextToPlayer(currentPlayer, 0, 0, "-pfall / -allpf gives full proficiencies")
    elseif SubString(message,0,12) == "-setprestige" then
        PrestigeTable[pid][S2I(SubString(message, 13, 15))] = S2I(SubString(message, 15, 17))
        SetPrestigeEffects(pid)
        UpdatePrestigeTooltips()
    elseif SubString(message,0,6) == "-wells" then
        i = 1
        while i <= 4 do
            PingMinimap(GetUnitX(well[i]), GetUnitY(well[i]), 1)
            i = i + 1
        end
    elseif message == "-createwell" then
        CreateWell()
    elseif SubString(message,0,8) == "-killall" then
        KillEverythingLol()
    elseif SubString(message,0,6) == "-print" then
        BJDebugMsg((StringHash(SubString(message,7, StringLength(message)))))
    elseif SubString(message,0,7) == "-printc" then
        BJDebugMsg((FourCC(SubString(message,8, StringLength(message)))))
    elseif SubString(message,0,11) == "-createhero" then
        Hero[2] = CreateUnit(Player(1), FourCC('H029'), 0, 0 ,0)
        Hero[3] = CreateUnit(Player(2), FourCC('E00G'), 0, 0 ,0)
        HeroID[2] = GetUnitTypeId(Hero[2])
        HeroID[3] = GetUnitTypeId(Hero[3])
        SetHeroLevel(Hero[2], 25, false)
        SetUnitState(Hero[2], UNIT_STATE_LIFE, GetUnitState(Hero[2], UNIT_STATE_LIFE) - 250)
    elseif SubString(message,0,5) == "-test" then
        SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_GOLD, 1000000)
        SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_LUMBER, 1000000)
        SetHeroLevel(Hero[pid], 150, false)
        PlayerAddItemById(pid, FourCC('I0M8'))
        FogMaskEnable(false)
        FogEnable(false)
        ExperienceControl(pid)
    elseif SubString(message,0,5) == "-heal" then
        SetWidgetLife(PlayerSelectedUnit[pid], BlzGetUnitMaxHP(PlayerSelectedUnit[pid]))
        SetUnitState(PlayerSelectedUnit[pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(PlayerSelectedUnit[pid]))
    elseif SubString(message,0,5) == "-yeah" then
        BJDebugMsg((StringHash(GetLocalizedString("TRIGSTR_001"))))
    elseif SubString(message,0,6) == "-invul" then
        if GetUnitAbilityLevel(PlayerSelectedUnit[pid], FourCC('Avul')) > 0 then
            UnitRemoveAbility(PlayerSelectedUnit[pid], FourCC('Avul'))
        else
            UnitAddAbility(PlayerSelectedUnit[pid], FourCC('Avul'))
        end
    elseif SubString(message,0,10) == "-dropitems" then
        while not (i > S2I(SubString(message, 11,13))) do
            Item.create(ChooseRandomItem(GetRandomInt(1, 7)), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 600.)
            i = i + 1
        end
    elseif SubString(message,0,6) == "-colo " then
        ColoPlayerCount = S2I(SubString(message, 6, StringLength(message)))
    elseif SubString(message,0 ,3) == "-hp" then
        SetWidgetLife(PlayerSelectedUnit[pid], S2I(SubString(message, 4, StringLength(message))))
        BlzSetUnitMaxHP(PlayerSelectedUnit[pid], S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message, 0, 6) == "-armor" then
        BlzSetUnitArmor(PlayerSelectedUnit[pid], S2I(SubString(message, 7, StringLength(message))))
    elseif SubString(message, 0, 5) == "-type" then
        BlzSetUnitIntegerField(PlayerSelectedUnit[pid], UNIT_IF_DEFENSE_TYPE, S2I(SubString(message, 6, StringLength(message))))
    elseif message == "-boost" then
        if BOOST_OFF then
            DisplayTextToPlayer(currentPlayer, 0, 0, "Boost enabled.")
            BOOST_OFF = false
        else
            DisplayTextToPlayer(currentPlayer, 0, 0, "Boost disabled.")
            BOOST_OFF = true
        end
    elseif SubString(message, 0, 5) == "-hurt" then
        SetWidgetLife(PlayerSelectedUnit[pid], GetWidgetLife(PlayerSelectedUnit[pid]) - BlzGetUnitMaxHP(PlayerSelectedUnit[pid]) * 0.01 * S2I(SubString(message, 6, StringLength(message))))
    elseif message == "-buddha" then
        if BUDDHA_MODE[pid] then
            DisplayTextToPlayer(currentPlayer, 0, 0, "Buddha disabled.")
            BUDDHA_MODE[pid] = false
        else
            DisplayTextToPlayer(currentPlayer, 0, 0, "Buddha enabled.")
            BUDDHA_MODE[pid] = true
        end
    elseif message == "-votekicktest" then
        votekickPlayer = pid
        ResetVote()
        VOTING_TYPE = 2

        while U do

            if GetLocalPlayer() == U.player then
                BlzFrameSetVisible(votingBG, true)
            end

            U = U.next
        end
    elseif message =="-saveall" then
        while U do

            ActionSave(U.player)

            U = U.next
        end
    elseif message == "-tp" then
        SetUnitPosition(PlayerSelectedUnit[pid], MouseX[pid], MouseY[pid])
    elseif message == "-coloxp" then
        Colosseum_XP[pid] = 1.3
    elseif message == "-debugmsg" then
        if EXTRA_DEBUG then
            EXTRA_DEBUG = false
        else
            EXTRA_DEBUG = true
        end
    elseif message == "-currentorder" then
        DEBUGMSG((GetUnitCurrentOrder(PlayerSelectedUnit[pid])))
        DEBUGMSG(OrderId2String(GetUnitCurrentOrder(PlayerSelectedUnit[pid])))
    elseif message == "-currenttarget" then
        DEBUGMSG(GetUnitName(GetUnitTarget(PlayerSelectedUnit[pid])))
    elseif message == "-dmg" then
        BlzSetUnitBaseDamage(PlayerSelectedUnit[pid], S2I(SubString(message, 5, StringLength(message))), 0)
    elseif SubString(message, 0, 12) == "-getitemdata" then
        DEBUGMSG((ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][S2I(SubString(message, 13, StringLength(message)))]))
    elseif SubString(message, 0, 9) == "-itemdata" then
        SetItemUserData(UnitItemInSlot(Hero[pid], 0), S2I(SubString(message, 10, StringLength(message))))
    elseif SubString(message, 0, 10) == "-animation" then
        SetUnitAnimationByIndex(PlayerSelectedUnit[pid], S2I(SubString(message, 11, StringLength(message))))
    elseif message == "-shadowstep" then
        ShadowStepExpire()
    elseif message == "-hasabil" and GetUnitAbilityLevel(Hero[pid], FourCC('A00D')) > 0 then
        DEBUGMSG("Yes!")
    elseif SubString(message, 0, 7) == "-rotate" then
        BlzSetUnitFacingEx(PlayerSelectedUnit[pid], S2R(SubString(message, 8, StringLength(message))))
    elseif message == "-position" then
        DEBUGMSG(R2S(GetUnitX(PlayerSelectedUnit[pid])) .. " " .. R2S(GetUnitY(PlayerSelectedUnit[pid])))
    elseif message == "-prestigehack" then
        Profile[pid].hero.prestige = 2
    elseif message == "-quickshit" then
        SetHeroLevel(PlayerSelectedUnit[pid], 400, false)
        TimePlayed[pid] = 625
        SetHeroStat(PlayerSelectedUnit[pid], MainStat(PlayerSelectedUnit[pid]), 123456)
        PlayerAddItemById(pid, FourCC('I06H'))
        PlayerAddItemById(pid, FourCC('I0G2'))
        PlayerAddItemById(pid, FourCC('I0D4'))
    elseif SubString(message, 0, 4) == "-dmg" then
        BlzSetUnitBaseDamage(PlayerSelectedUnit[pid], S2I(SubString(message, 5, StringLength(message))), 0)
    elseif SubString(message, 0, 5) == "-gocd" then
        BlzStartUnitAbilityCooldown(Hero[pid], FourCC('A07R'), 5.)
    elseif SubString(message, 0, 7) == "-skills" then
        DEBUGMSG(BlzGetAbilityStringLevelField(BlzGetUnitAbilityByIndex(Hero[pid], S2I(SubString(message, 8, StringLength(message)))), ABILITY_SLF_TOOLTIP_NORMAL, 0))
        DEBUGMSG(BlzGetAbilityStringField(BlzGetUnitAbilityByIndex(Hero[pid], S2I(SubString(message, 8, StringLength(message)))), ABILITY_SF_NAME))
        DEBUGMSG(Id2String(BlzGetAbilityId(BlzGetUnitAbilityByIndex(Hero[pid], S2I(SubString(message, 8, StringLength(message)))))))
    elseif SubString(message, 0, 7) == "-encode" then
        DEBUGMSG(Encode(S2I(SubString(message, 8, StringLength(message)))))
    elseif SubString(message, 0, 9) == "-makeitem" then
        Item.create(CreateItem(FourCC('I0OX'), 0, 0))
    elseif SubString(message, 0, 12) == "-handlecount" then
        HandleCount()
    elseif SubString(message, 0, 11) == "-countdebug" then
        if COUNT_DEBUG then
            COUNT_DEBUG = false
            DEBUGMSG("Stop counting debug!")
        else
            DEBUGMSG("Count debug!")
            COUNT_DEBUG = true
        end
    elseif SubString(message, 0, 10) == "-FourCC" then
        DEBUGMSG((FourCC(SubString(message, 11, StringLength(message)))))
    elseif SubString(message, 0, 10) == "-itemlevel" then
        Item[UnitItemInSlot(Hero[pid], 0)]:lvl(S2I(SubString(message, 11, StringLength(message))))
    elseif SubString(message, 0, 9) == "-maxlevel" then
        Item[UnitItemInSlot(Hero[pid], 0)]:lvl(ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][ITEM_UPGRADE_MAX])
    elseif SubString(message, 0, 8) == "-itemset" then
        Item[UnitItemInSlot(Hero[pid], 0)]:unequip()
        WipeItemStats(GetItemTypeId(UnitItemInSlot(Hero[pid], 0)))
        ParseItemTooltip(UnitItemInSlot(Hero[pid], 0), SubString(message, 9, StringLength(message)))
        Item[UnitItemInSlot(Hero[pid], 0)]:update()
        Item[UnitItemInSlot(Hero[pid], 0)]:equip()
    elseif SubString(message, 0, 10) == "-itemprint" then
        DEBUGMSG(BlzGetItemExtendedTooltip(UnitItemInSlot(Hero[pid], 0)))
    elseif SubString(message, 0, 12) == "-itemformula" then
        DEBUGMSG(ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][ITEM_TOOLTIP])
    elseif SubString(message, 0, 5) == "-mode" then
        DEBUGMSG(GetLocalizedString("IS_HD"))
    elseif SubString(message, 0, 6) == "-ablev" then
        DEBUGMSG((GetUnitAbilityLevel(Hero[pid], FourCC(SubString(message, 7, StringLength(message))))))
    elseif SubString(message, 0, 11) == "-shieldtest" then
        bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\HPbar.mdx", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
        TimerQueue:callDelayed(5., DestroyEffect, bj_lastCreatedEffect)
        BlzSetSpecialEffectScale(bj_lastCreatedEffect, 1.5)
        BlzSetSpecialEffectColorByPlayer(bj_lastCreatedEffect, Player(2))
        BlzSetSpecialEffectZ(bj_lastCreatedEffect, BlzGetUnitZ(Hero[pid]) + S2R(SubString(message, 12, StringLength(message))))
    elseif SubString(message, 0, 7) == "-shunpo" then
        ShowUnit(PlayerSelectedUnit[pid], false)
        ShowUnit(PlayerSelectedUnit[pid], true)
    elseif SubString(message, 0, 9) == "-pathable" then
        if IsTerrainWalkable(MouseX[pid], MouseY[pid]) then
            DEBUGMSG("yeah")
        end
    elseif SubString(message, 0, 7) == "-wander" then
        WanderingGuys()
    elseif message == "-heropos" then
        DEBUGMSG(R2S(GetUnitX(Hero[pid])))
        DEBUGMSG(R2S(GetUnitY(Hero[pid])))
    elseif message == "-afk?" then
        if panCounter[pid] < 75 or moveCounter[pid] < 1000 or selectCounter[pid] < 20 then
            DEBUGMSG("Yes")
        else
            DEBUGMSG("No")
        end
    elseif SubString(message, 0, 8) == "-setskin" then
        CosmeticTable[User[currentPlayer].name][S2I(SubString(message, 9, 11)) + DONATOR_SKIN_OFFSET] = S2I(SubString(message, 12, 14))
    elseif SubString(message, 0, 8) == "-setaura" then
        CosmeticTable[User[currentPlayer].name][S2I(SubString(message, 9, 11)) + DONATOR_AURA_OFFSET] = S2I(SubString(message, 12, 14))
    elseif SubString(message, 0, 8) == "-id2char" then
        DEBUGMSG(GetObjectName(SAVE_UNIT_TYPE[S2I(SubString(message, 9, StringLength(message)))]))
    elseif SubString(message, 0, 10) == "-givespell" then
        UnitAddAbility(PlayerSelectedUnit[pid], FourCC(SubString(message, 11, StringLength(message))))
    elseif SubString(message, 0, 12) == "-removespell" then
        UnitRemoveAbility(PlayerSelectedUnit[pid], FourCC(SubString(message, 13, StringLength(message))))
    elseif SubString(message, 0, 9) == "-addpoint" then
        STK_UpdateUnitTalentPoints(1, Hero[pid], S2I(SubString(message, 10, StringLength(message))))
    elseif message == "-mathtest" then
        DEBUGMSG((R2I(-5.5)))
        DEBUGMSG((R2I(5.5)))

        DEBUGMSG((R2I(-5.75)))
        DEBUGMSG((R2I(5.25)))
    elseif message == "-restock" then
        ShopkeeperMove()
    end
end

    local devcmd = CreateTrigger() ---@type trigger 
    local search = CreateTrigger() ---@type trigger 

    SAVE_LOAD_VERSION = POWERSOF2[30]
    MAP_NAME = "CoT Nevermore BETA"

    for i = 0, 6 do
        TriggerRegisterPlayerChatEvent(devcmd, Player(i), "-", false)
        SEARCH_DIALOG[i] = DialogCreate()
        TriggerRegisterDialogEvent(search, SEARCH_DIALOG[i])
    end

    TimerQueue:callDelayed(0., PreloadItemSearch)

    TriggerAddAction(devcmd, DevCommands)
    TriggerAddAction(search, SearchPage)
end)

if Debug then Debug.endFile() end
