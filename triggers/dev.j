library dev initializer init requires Functions, Timers, Weather, Hint, Bosses

globals
    dialog array SEARCH_DIALOG
    string array SEARCH_RESULTS
    button array SEARCH_NEXT
    integer array SEARCH_PAGE
    boolean array BUDDHA_MODE
    boolean EXTRA_DEBUG = false
    boolean array nocd
	boolean array nocost
    boolean array SEARCHABLE

    boolean COUNT_DEBUG = false
    integer DEBUG_COUNT = 0
endglobals

function PreloadItemSearch takes nothing returns nothing
    local integer i = 0
    local integer count = 0
    local item itm

    call ReleaseTimer(GetExpiredTimer())

    //searchable items
    loop
        //I000 to I0zz (3844~ items)
        exitwhen i > 19018

        set itm = CreateItem(CUSTOM_ITEM_OFFSET + i, 30000., 30000.)
        if itm != null and GetItemType(itm) != ITEM_TYPE_POWERUP and GetItemType(itm) != ITEM_TYPE_CAMPAIGN then
            set SEARCHABLE[i] = true
        endif
        call RemoveItem(itm)

        set count = count + 1

        //ignore non word/digit characters
        if count == 10 then
            set i = i + 7
        elseif count == 36 then
            set i = i + 6
        elseif count == 62 then
            set i = i + 181
            set count = 0
        endif

        set i = i + 1
    endloop

    set itm = null
endfunction

function WipeItemStats takes integer id returns nothing
    local integer i = 1

    loop
        exitwhen i > 30

        set ItemData[id][i] = 0
        set ItemData[id][i + BOUNDS_OFFSET * 2] = 0
        set ItemData[id][i + BOUNDS_OFFSET * 3] = 0
        set ItemData[id][i + BOUNDS_OFFSET * 4] = 0
        set ItemData[id][i + BOUNDS_OFFSET * 5] = 0
        set ItemData[id][i + BOUNDS_OFFSET * 6] = 0
        set ItemData[id][i * ABILITY_OFFSET] = 0
        set ItemData[id].string[i * ABILITY_OFFSET] = null

        set i = i + 1
    endloop
endfunction

function StringContainsString takes string search, string source returns boolean
    local integer i
    local integer sL
    local integer sS

    if StringLength(search) > StringLength(source) then
        return false
    endif

    set i = 0
    set sL = StringLength(search)
    set sS = StringLength(source)
    set search = StringCase(search,false)
    set source = StringCase(source,false)

    loop
        exitwhen i + sL > sS
            if search == SubString(source,i,i + sL) then
                return true
            endif
        set i = i + 1
    endloop
    
    return false
endfunction

function ClearSearch takes integer pid returns nothing
    local integer i = 0

    loop
        exitwhen i > 799

        set SEARCH_RESULTS[pid * 800 + i] = ""

        set i = i + 1
    endloop
endfunction

function SearchPage takes nothing returns nothing
    local button b = GetClickedButton()
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0

    call DialogClear(SEARCH_DIALOG[pid])

    if b == SEARCH_NEXT[pid] then
        loop
            exitwhen i > 8 or SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid]] == ""
            set SEARCH_NEXT[pid * 800 + SEARCH_PAGE[pid]] = DialogAddButton(SEARCH_DIALOG[pid], SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid]], 0)
            set SEARCH_PAGE[pid] = SEARCH_PAGE[pid] + 1
            set i = i + 1
        endloop
        if SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid]] != "" then
            set SEARCH_NEXT[pid] = DialogAddButton(SEARCH_DIALOG[pid], "Next page", 0)
        endif

        call DialogDisplay(p, SEARCH_DIALOG[pid], true)
    else //give item
        loop
            exitwhen b == SEARCH_NEXT[pid * 800 + SEARCH_PAGE[pid] - i] or i > 10
            set i = i + 1
        endloop
        call PlayerAddItemById(pid, String2Id(SubString(SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid] - i], 0, 4)))
    endif
endfunction

function FindItem takes string search, integer pid returns nothing
    local string itemCode = ""
    local integer i = 0
    local integer id = 0
    local string name = ""
    local player p = Player(pid - 1)
    local integer count = 0

    set SEARCH_PAGE[pid] = 0
    call ClearSearch(pid)
    call DialogClear(SEARCH_DIALOG[pid])
        
    loop
        exitwhen i > 8191
        
        set id = CUSTOM_ITEM_OFFSET + i
        set itemCode = Id2String(id)
        set name = GetObjectName(id)
        if name != "Default string" and name != "" and SEARCHABLE[i] then
            if StringContainsString(search, name) then
                set SEARCH_RESULTS[pid * 800 + count] = itemCode + " - " + name
                set count = count + 1
            endif
        endif
        if count > 99 then
            exitwhen true
        endif

        set i = i + 1
    endloop

    set i = 0
    loop
        exitwhen i > 8 or i > count - 1
        set SEARCH_NEXT[pid * 800 + i] = DialogAddButton(SEARCH_DIALOG[pid], SEARCH_RESULTS[pid * 800 + i], 0)
        set SEARCH_PAGE[pid] = SEARCH_PAGE[pid] + 1
        set i = i + 1
    endloop

    if count > i then
        set SEARCH_NEXT[pid] = DialogAddButton(SEARCH_DIALOG[pid], "Next page", 0)
    endif

    if count > 0 then
        call DialogDisplay(p, SEARCH_DIALOG[pid], true)
    endif
    
    set p = null
endfunction

function DevCommands takes nothing returns nothing
    local player currentPlayer = GetTriggerPlayer()
    local integer pid = GetPlayerId(currentPlayer) + 1
    local string message = GetEventPlayerChatString()
    local integer i = 0
    local integer i2 = 0
    local real r = 0
    local User U = User.first
    local item itm
    
    if (message == "-nocd") then
        set nocd[pid] = true
    elseif message == "-cd" or message == "-cdon" then
        set nocd[pid] = false
    elseif message == "-vampire" then
        call BlzSetUnitRealField(Hero[pid], UNIT_RF_SIGHT_RADIUS, 400.)
        loop
            exitwhen i > 7
            if Player(i) != currentPlayer then
                call SetPlayerAlliance(currentPlayer, Player(i), ALLIANCE_SHARED_VISION, false)
                call SetPlayerAlliance(Player(i), currentPlayer, ALLIANCE_SHARED_VISION, false)
            endif

            set i = i + 1
        endloop
    elseif message == "-dummytest" then
        call GetDummy(0, 0, 0, 0, DUMMY_RECYCLE_TIME)
        call DEBUGMSG(I2S(DUMMY_COUNT))

    elseif(message == "-nocost") then
        set nocost[pid] = true
    elseif message == "-cost" or message == "-coston" then
        set nocost[pid] = false
    elseif (message == "-vision") then
        call FogMaskEnable(false)
        call FogEnable(false)
    elseif (message == "-novision") then
        call FogMaskEnable(true)
        call FogEnable(true)
    elseif SubString(message,0,3)== "-sp" then
        call SetCurrency(pid, PLATINUM, S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message,0,3)== "-sa" and SubString(message,3,5) != "ve" then
        call SetCurrency(pid, ARCADITE, S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message,0,3)== "-sc" then
        call SetCurrency(pid, CRYSTAL, S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message,0,5)== "-lvl " then
        if GetHeroLevel(PlayerSelectedUnit[pid]) > S2I(SubString(message, 5, 8)) then
            call UnitStripHeroLevel(PlayerSelectedUnit[pid], GetHeroLevel(PlayerSelectedUnit[pid]) - S2I(SubString(message, 5, 8)))
        else
            call SetHeroLevel(PlayerSelectedUnit[pid], S2I(SubString(message, 5, 8)),false)
        endif
    elseif SubString(message,0,5)== "-str " then
        call SetHeroStr(PlayerSelectedUnit[pid], S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,5)== "-agi " then
        call SetHeroAgi(PlayerSelectedUnit[pid], S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,5)== "-int " then
        call SetHeroInt(PlayerSelectedUnit[pid], S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,3)== "-g " then
        call AddCurrency(pid, GOLD, S2I(SubString(GetEventPlayerChatString(), 3, 10)))
    elseif SubString(message,0,3)== "-l " then
        call AddCurrency(pid, LUMBER, S2I(SubString(GetEventPlayerChatString(), 3, 10)))
    elseif (message == "-day") then
        call SetTimeOfDay(5.95)
    elseif (message == "-night") then
        call SetTimeOfDay(17.49)
    elseif (message == "-cycle") then
        call SetTimeOfDayScale(50)
    elseif SubString(message,0,4)== "-si " then
        call FindItem(SubString(message, 4, StringLength(message)), pid)
    elseif SubString(message,0,4)== "-gi " then
        call PlayerAddItemById(pid, String2Id(SubString(message, 4, StringLength(message))))
    elseif (message == "-pfall") or (message == "-allpf") then
        set HERO_PROF[pid] = 0x3ff
    elseif (message == "-hero") then
        //blue
        set Hero[2] = CreateUnitAtLoc(Player(1), 'E002', TownCenter, 0)
        set HeroID[2] = GetUnitTypeId(Hero[2])
        set HeroGrave[2] = CreateUnit(Player(1), GRAVE, -285, -72, 270)
        call GroupAddUnit(HeroGroup, Hero[2])
        //teal
        set Hero[3] = CreateUnitAtLoc(Player(2), 'E00X', TownCenter, 0)
        set HeroID[3] = GetUnitTypeId(Hero[3])
        call GroupAddUnit(HeroGroup, Hero[3])
    elseif (SubString(message, 0, 13) == "-sharecontrol") then
        call SetPlayerAlliance(Player(S2I(SubString(message, 14, StringLength(message)))), currentPlayer, ALLIANCE_SHARED_CONTROL, true)
    elseif (message == "-enterchaos") then
        set PathtoGodsisOpen = false
        set powercrystal = CreateUnitAtLoc(pfoe, 'h04S', Location(30000, -30000), bj_UNIT_FACING)
        call KillUnit(powercrystal)
    elseif (SubString(message, 0, 8) == "-settime") then
        set i = S2I(SubString(message, 9, 19))
    
        set udg_TimePlayed[pid] = i
    elseif (SubString(message, 0, 13) == "-punchingbags") then
        set i2 = S2I(SubString(message, 14, StringLength(message)))
    
        loop
            exitwhen i == i2
            set i = i + 1
            set r = bj_PI * 2 * i / i2
            call CreateUnit(pfoe, 'h02D', GetUnitX(Hero[pid]) + Cos(r) * 30 * i / i2, GetUnitY(Hero[pid]) + Sin(r) * 30 * i / i2, 270.)
        endloop
    elseif (SubString(message, 0, 11) == "-shopkeeper") then
        call PingMinimap(GetUnitX(gg_unit_n01F_0576), GetUnitY(gg_unit_n01F_0576), 3)
    elseif (message== "-weather") then
        call WeatherPeriodic()
    elseif (message== "-noborders") then
        call SetCameraBoundsRectForPlayerEx(currentPlayer, GetWorldBounds())
    elseif (SubString(message,0,6) == "-chelp") then
        call DisplayTextToPlayer(currentPlayer, 0, 0, "
        -caoa (angle of attack) 250-330
        -cfow (field of view) 70-120
        -cfarz 5000-10000
        -croll 0-360
        -crot (rotation) 0-360
        -cdist (distance) 1000-10000
        -czoff (z offset) 0-10000
        -deletefloatingtext")
    elseif (SubString(message,0,5) == "-caoa") then
        call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, S2R(SubString(message, 6, StringLength(message))), 0)
    elseif (SubString(message,0,5) == "-cfow") then
        call SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, S2R(SubString(message, 6, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-cfarz") then
        call SetCameraField(CAMERA_FIELD_FARZ, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-croll") then
        call SetCameraField(CAMERA_FIELD_ROLL, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (SubString(message,0,5) == "-crot") then
        call SetCameraField(CAMERA_FIELD_ROTATION, S2R(SubString(message, 6, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-cdist") then
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (SubString(message,0,6) == "-czoff") then
        call SetCameraField(CAMERA_FIELD_ZOFFSET, S2R(SubString(message, 7, StringLength(message))), 0)
    elseif (message == "-deletefloatingtext") then
        call DestroyTextTag(GetLastCreatedTextTag())
        call DestroyTextTag(ColoText)
        call DestroyTextTag(StruggleText)
    elseif (message == "-displayhint") then
        call ShowHint()
    elseif (message == "-hackrespawn") then
        set RESPAWN_DEBUG = true
    elseif (message == "-pause") then
        call PauseUnit(Hero[pid], true)
    elseif (message == "-unpause") then
        call PauseUnit(Hero[pid], false)
    elseif (message == "-evasion") then
        call UnitAddAbility(Hero[pid], 'A0JH')
    elseif (message == "-noevasion") then
        call UnitRemoveAbility(Hero[pid], 'A0JH')
    elseif (message == "-firestorm") then
        set firestormActive = true
        call TimerStart(NewTimer(), 3.00, true, function FirestormEffect)
    elseif (SubString(message, 0, 13) == "-setfirestorm") then
        set firestormRate = S2I(SubString(message, 14, StringLength(message)))
    elseif (message == "-horde") then
        set i = 0
    
        loop
            exitwhen i > 39
            call CreateUnitAtLoc(pfoe, 'n07R', GetUnitLoc(Hero[pid]), GetRandomReal(0,359))
            set i = i + 1
        endloop
    elseif (message == "-kill") then
        call UnitDamageTarget(Hero[pid], PlayerSelectedUnit[pid], BlzGetUnitMaxHP(PlayerSelectedUnit[pid]) * 2., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_DIVINE, WEAPON_TYPE_WHOKNOWS)
    elseif (SubString(message, 0, 5) == "-ally") then
        call CreateUnit(currentPlayer, String2Id(SubString(message,6,10)), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0,359))
    elseif (SubString(message, 0, 9) == "-setowner") then
        call SetUnitOwner(PlayerSelectedUnit[pid], Player(S2I(SubString(message, 10, StringLength(message)))), true)
    elseif (SubString(message, 0, 6) == "-enemy") then
        call CreateUnit(pfoe, String2Id(SubString(message,7,11)), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0,359))
    elseif (message == "-donation") then
        call BJDebugMsg("weather rate: " + R2S(donation))
    elseif (message == "-afktest") then
        call AFKClock()
    elseif SubString(message,0,5) == "-help" then
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-str / -agi / -int # - Sets stat to #")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-lvl # - Sets hero level to #")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-g / -l # - Sets gold or lumber to #")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-vision / -novision - toggles map vision")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-sp # -sets platcoin to #")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-sa # -sets arclumber to #")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-sc # -sets crystals to #")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-gi - give item, spawns based on 4 character rawcode, eg. I0M8")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-si - search item id by name")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-day / -night")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-cycle - makes time really fast")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-enterchaos - starts chaos mode")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-noborders (removes camera borders so you can see outside the map)")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-weather - changes weather")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-cd / -nocd toggles cooldowns")
        call DisplayTextToPlayer(currentPlayer, 0, 0, "-pfall / -allpf gives full proficiencies")
    elseif SubString(message,0,12) == "-setprestige" then
        set PrestigeTable[pid][S2I(SubString(message, 13, 15))] = S2I(SubString(message, 15, 17))
        call SetPrestigeEffects(pid)
        call UpdatePrestigeTooltips()
    elseif SubString(message,0,6) == "-wells" then
        set i = 1
        loop
            exitwhen i > 4
            call PingMinimap(GetUnitX(well[i]), GetUnitY(well[i]), 1)
            set i = i + 1
        endloop
    elseif message == "-createwell" then
        call CreateWell()
    elseif SubString(message,0,8) == "-killall" then
        call KillEverythingLol()
    elseif SubString(message,0,6) == "-print" then
        call BJDebugMsg(I2S(StringHash(SubString(message,7, StringLength(message)))))
    elseif SubString(message,0,7) == "-printc" then
        call BJDebugMsg(I2S(String2Id(SubString(message,8, StringLength(message)))))
    elseif SubString(message,0,11) == "-createhero" then
        set Hero[2] = CreateUnit(Player(1), 'H029', 0, 0 ,0)
        set Hero[3] = CreateUnit(Player(2), 'E00G', 0, 0 ,0)
        set HeroID[2] = GetUnitTypeId(Hero[2])
        set HeroID[3] = GetUnitTypeId(Hero[3])
        call SetHeroLevel(Hero[2], 25, false)
        call SetUnitState(Hero[2], UNIT_STATE_LIFE, GetUnitState(Hero[2], UNIT_STATE_LIFE) - 250)
    elseif SubString(message,0,5) == "-test" then
        call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_GOLD, 1000000)
        call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_LUMBER, 1000000)
        call SetHeroLevel(Hero[pid], 150, false)
        call PlayerAddItemById(pid, 'I0M8')
        call FogMaskEnable(false)
        call FogEnable(false)
        call ExperienceControl(pid)
    elseif SubString(message,0,5) == "-heal" then
        call SetWidgetLife(PlayerSelectedUnit[pid], BlzGetUnitMaxHP(PlayerSelectedUnit[pid]))
        call SetUnitState(PlayerSelectedUnit[pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(PlayerSelectedUnit[pid]))
    elseif SubString(message,0,5) == "-yeah" then
        call BJDebugMsg(I2S(StringHash(GetLocalizedString("TRIGSTR_001"))))
    elseif SubString(message,0,6) == "-invul" then
        if GetUnitAbilityLevel(PlayerSelectedUnit[pid], 'Avul') > 0 then
            call UnitRemoveAbility(PlayerSelectedUnit[pid], 'Avul')
        else
            call UnitAddAbility(PlayerSelectedUnit[pid], 'Avul')
        endif
    elseif SubString(message,0,10) == "-dropitems" then
        loop
            exitwhen i > S2I(SubString(message, 11,13))
            call Item.create(ChooseRandomItem(GetRandomInt(1, 7)), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 600.)
            set i = i + 1
        endloop
    elseif SubString(message,0,6) == "-colo " then
        set ColoPlayerCount = S2I(SubString(message, 6, StringLength(message)))
    elseif SubString(message,0 ,3) == "-hp" then
        call SetWidgetLife(PlayerSelectedUnit[pid], S2I(SubString(message, 4, StringLength(message))))
        call BlzSetUnitMaxHP(PlayerSelectedUnit[pid], S2I(SubString(message, 4, StringLength(message))))
    elseif SubString(message, 0, 6) == "-armor" then
        call BlzSetUnitArmor(PlayerSelectedUnit[pid], S2I(SubString(message, 7, StringLength(message))))
    elseif SubString(message, 0, 5) == "-type" then
        call BlzSetUnitIntegerField(PlayerSelectedUnit[pid], UNIT_IF_DEFENSE_TYPE, S2I(SubString(message, 6, StringLength(message))))
    elseif message == "-boost" then
        if BOOST_OFF then
            call DisplayTextToPlayer(currentPlayer, 0, 0, "Boost enabled.")
            set BOOST_OFF = false
        else
            call DisplayTextToPlayer(currentPlayer, 0, 0, "Boost disabled.")
            set BOOST_OFF = true
        endif
    elseif SubString(message, 0, 5) == "-hurt" then
        call SetWidgetLife(PlayerSelectedUnit[pid], GetWidgetLife(PlayerSelectedUnit[pid]) - BlzGetUnitMaxHP(PlayerSelectedUnit[pid]) * 0.01 * S2I(SubString(message, 6, StringLength(message))))
    elseif message == "-buddha" then
        if BUDDHA_MODE[pid] then
            call DisplayTextToPlayer(currentPlayer, 0, 0, "Buddha disabled.")
            set BUDDHA_MODE[pid] = false
        else
            call DisplayTextToPlayer(currentPlayer, 0, 0, "Buddha enabled.")
            set BUDDHA_MODE[pid] = true
        endif
    elseif message == "-votekicktest" then
        set votekickPlayer = pid
        call ResetVote()
        set VOTING_TYPE = 2

        loop
            exitwhen U == User.NULL

            if GetLocalPlayer() == U.toPlayer() then
                call BlzFrameSetVisible(votingBG, true)
            endif

            set U = U.next
        endloop
    elseif message =="-saveall" then
        loop
            exitwhen U == User.NULL

            call ActionSave(U.toPlayer())

            set U = U.next
        endloop
    elseif message == "-tp" then
        call SetUnitPosition(PlayerSelectedUnit[pid], MouseX[pid], MouseY[pid])
    elseif message == "-coloxp" then
        set udg_Colloseum_XP[pid] = 1.3
    elseif message == "-debugmsg" then
        if EXTRA_DEBUG then
            set EXTRA_DEBUG = false
        else
            set EXTRA_DEBUG = true
        endif
    elseif message == "-currentorder" then
        call DEBUGMSG(I2S(GetUnitCurrentOrder(PlayerSelectedUnit[pid])))
        call DEBUGMSG(OrderId2String(GetUnitCurrentOrder(PlayerSelectedUnit[pid])))
    elseif message == "-currenttarget" then
        call DEBUGMSG(GetUnitName(GetUnitTarget(PlayerSelectedUnit[pid])))
    elseif message == "-dmg" then
        call BlzSetUnitBaseDamage(PlayerSelectedUnit[pid], S2I(SubString(message, 5, StringLength(message))), 0)
    elseif SubString(message, 0, 12) == "-getitemdata" then
        call DEBUGMSG(I2S(ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][S2I(SubString(message, 13, StringLength(message)))]))
    elseif SubString(message, 0, 9) == "-itemdata" then
        call SetItemUserData(UnitItemInSlot(Hero[pid], 0), S2I(SubString(message, 10, StringLength(message))))
    elseif SubString(message, 0, 10) == "-animation" then
        call SetUnitAnimationByIndex(PlayerSelectedUnit[pid], S2I(SubString(message, 11, StringLength(message))))
    elseif message == "-shadowstep" then
        call ShadowStepExpire()
    elseif message == "-hasabil" and GetUnitAbilityLevel(Hero[pid], 'A00D') > 0 then
        call DEBUGMSG("Yes!")
    elseif SubString(message, 0, 7) == "-rotate" then
        call BlzSetUnitFacingEx(PlayerSelectedUnit[pid], S2R(SubString(message, 8, StringLength(message))))
    elseif message == "-position" then
        call DEBUGMSG(R2S(GetUnitX(PlayerSelectedUnit[pid])) + " " + R2S(GetUnitY(PlayerSelectedUnit[pid])))
    elseif message == "-prestigehack" then
        set Profile[pid].hero.prestige = 2
    elseif message == "-quickshit" then
        call SetHeroLevel(PlayerSelectedUnit[pid], 400, false)
        set udg_TimePlayed[pid] = 625
        call SetHeroStat(PlayerSelectedUnit[pid], MainStat(PlayerSelectedUnit[pid]), 123456)
        call PlayerAddItemById(pid, 'I06H')
        call PlayerAddItemById(pid, 'I0G2')
        call PlayerAddItemById(pid, 'I0D4')
    elseif SubString(message, 0, 4) == "-dmg" then
        call BlzSetUnitBaseDamage(PlayerSelectedUnit[pid], S2I(SubString(message, 5, StringLength(message))), 0)
    elseif SubString(message, 0, 5) == "-gocd" then
        call BlzStartUnitAbilityCooldown(Hero[pid], 'A07R', 5.)
    elseif SubString(message, 0, 7) == "-skills" then
        call DEBUGMSG(BlzGetAbilityStringLevelField(BlzGetUnitAbilityByIndex(Hero[pid], S2I(SubString(message, 8, StringLength(message)))), ABILITY_SLF_TOOLTIP_NORMAL, 0))
        call DEBUGMSG(BlzGetAbilityStringField(BlzGetUnitAbilityByIndex(Hero[pid], S2I(SubString(message, 8, StringLength(message)))), ABILITY_SF_NAME))
        call DEBUGMSG(Id2String(BlzGetAbilityId(BlzGetUnitAbilityByIndex(Hero[pid], S2I(SubString(message, 8, StringLength(message)))))))
    elseif SubString(message, 0, 7) == "-encode" then
        call DEBUGMSG(Encode(S2I(SubString(message, 8, StringLength(message)))))
    elseif SubString(message, 0, 9) == "-makeitem" then
        call Item.create('I0OX', 0, 0, 0.)
    elseif SubString(message, 0, 12) == "-handlecount" then
        call HandleCount()
    elseif SubString(message, 0, 11) == "-countdebug" then
        if COUNT_DEBUG then
            set COUNT_DEBUG = false
            call DEBUGMSG("Stop counting debug!")
        else
            call DEBUGMSG("Count debug!")
            set COUNT_DEBUG = true
        endif
    elseif SubString(message, 0, 10) == "-string2id" then
        call DEBUGMSG(I2S(String2Id(SubString(message, 11, StringLength(message)))))
    elseif SubString(message, 0, 10) == "-itemlevel" then
        set Item[UnitItemInSlot(Hero[pid], 0)].lvl = S2I(SubString(message, 11, StringLength(message)))
    elseif SubString(message, 0, 9) == "-maxlevel" then
        set Item[UnitItemInSlot(Hero[pid], 0)].lvl = ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))][ITEM_UPGRADE_MAX]
    elseif SubString(message, 0, 8) == "-itemset" then
        call Item[UnitItemInSlot(Hero[pid], 0)].unequip()
        call WipeItemStats(GetItemTypeId(UnitItemInSlot(Hero[pid], 0)))
        call ParseItemTooltip(UnitItemInSlot(Hero[pid], 0), SubString(message, 9, StringLength(message)))
        call Item[UnitItemInSlot(Hero[pid], 0)].update()
        call Item[UnitItemInSlot(Hero[pid], 0)].equip()
    elseif SubString(message, 0, 10) == "-itemprint" then
        call DEBUGMSG(BlzGetItemExtendedTooltip(UnitItemInSlot(Hero[pid], 0)))
    elseif SubString(message, 0, 12) == "-itemformula" then
        call DEBUGMSG(ItemData[GetItemTypeId(UnitItemInSlot(Hero[pid], 0))].string[ITEM_TOOLTIP])
    elseif SubString(message, 0, 5) == "-mode" then
        call DEBUGMSG(GetLocalizedString("IS_HD"))
    elseif SubString(message, 0, 6) == "-ablev" then
        call DEBUGMSG(I2S(GetUnitAbilityLevel(Hero[pid], String2Id(SubString(message, 7, StringLength(message))))))
    elseif SubString(message, 0, 11) == "-shieldtest" then
        set bj_lastCreatedEffect = AddSpecialEffect("war3mapImported\\HPbar.mdx", GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))
        call DestroyEffectTimed(bj_lastCreatedEffect, 5.)
        call BlzSetSpecialEffectScale(bj_lastCreatedEffect, 1.5)
        call BlzSetSpecialEffectColorByPlayer(bj_lastCreatedEffect, Player(2))
        call BlzSetSpecialEffectZ(bj_lastCreatedEffect, BlzGetUnitZ(Hero[pid]) + S2R(SubString(message, 12, StringLength(message))))
    elseif SubString(message, 0, 7) == "-shunpo" then
        call ShowUnit(PlayerSelectedUnit[pid], false)
        call ShowUnit(PlayerSelectedUnit[pid], true)
    elseif SubString(message, 0, 9) == "-pathable" then
        if IsTerrainWalkable(MouseX[pid], MouseY[pid]) then
            call DEBUGMSG("yeah")
        endif
    elseif SubString(message, 0, 7) == "-wander" then
        call WanderingGuys()
    elseif message == "-heropos" then
        call DEBUGMSG(R2S(GetUnitX(Hero[pid])))
        call DEBUGMSG(R2S(GetUnitY(Hero[pid])))
    elseif message == "-afk?" then
        if panCounter[pid] < 75 or moveCounter[pid] < 1000 or selectCounter[pid] < 20 then
            call DEBUGMSG("Yes")
        else
            call DEBUGMSG("No")
        endif
    elseif SubString(message, 0, 8) == "-setskin" then
        set CosmeticTable[StringHash(User[currentPlayer].name)][S2I(SubString(message, 9, 11)) + DONATOR_SKIN_OFFSET] = S2I(SubString(message, 12, 14))
    elseif SubString(message, 0, 8) == "-setaura" then
        set CosmeticTable[StringHash(User[currentPlayer].name)][S2I(SubString(message, 9, 11)) + DONATOR_AURA_OFFSET] = S2I(SubString(message, 12, 14))
    elseif SubString(message, 0, 8) == "-id2char" then
        call DEBUGMSG(GetObjectName(SAVE_UNIT_TYPE[S2I(SubString(message, 9, StringLength(message)))]))
    endif

    set itm = null
endfunction

private function init takes nothing returns nothing
    local trigger devcmd = CreateTrigger()
    local trigger search = CreateTrigger()
    local integer i = 0

    set SAVE_LOAD_VERSION = POWERSOF2[30]
    set MAP_NAME = "CoT Nevermore BETA"

	loop
		exitwhen i > 6
		call TriggerRegisterPlayerChatEvent(devcmd, Player(i), "-", false)
        set SEARCH_DIALOG[i] = DialogCreate()
        call TriggerRegisterDialogEvent(search, SEARCH_DIALOG[i])
        set i = i + 1
	endloop

    call TimerStart(NewTimer(), 0.00, false, function PreloadItemSearch)

    call TriggerAddAction(devcmd, function DevCommands)
    call TriggerAddAction(search, function SearchPage)
    
    set devcmd = null
    set search = null
endfunction

endlibrary
