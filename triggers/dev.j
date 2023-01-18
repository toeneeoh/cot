library dev initializer init requires Functions, Timers, Weather, Hint, Bosses

globals
    dialog array SEARCH_DIALOG
    string array SEARCH_RESULTS
    button array SEARCH_NEXT
    integer array SEARCH_PAGE
    boolean array BUDDHA_MODE
    boolean EXTRA_DEBUG = true
endglobals

function Dec2Hex takes integer dec returns string
    local integer r = ModuloInteger(dec, BASE)
    if dec - r == 0 then
        return SubString(CHARS, r, r + 1)
    else
        return Dec2Hex((dec - r) / BASE) + SubString(CHARS, r, r + 1)
    endif
    return ""
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
        call CreateHeroItem(Hero[pid], pid, String2Id(SubString(SEARCH_RESULTS[pid * 800 + SEARCH_PAGE[pid] - i], 0, 4) ), 1 )
    endif
endfunction

function FindItem takes string search, integer pid returns nothing
    local string itemCode = ""
    local integer i = 0
    local integer tId = 0
    local string name = ""
    local player p = Player(pid - 1)
    local integer count = 0
    local integer exitcount = 0

    set SEARCH_PAGE[pid] = 0
    call ClearSearch(pid)
    call DialogClear(SEARCH_DIALOG[pid])
        
    loop
        exitwhen i > 4096 or exitcount > 5 or count > 99
        
        set itemCode = Dec2Hex(i)
        if StringLength(itemCode) == 1 then
            set itemCode = "0" + itemCode
        endif
        if StringLength(itemCode) == 2 then
            set itemCode = "0" + itemCode
        endif
        set itemCode = "I" + itemCode
        set tId = String2Id(itemCode)
        set name = GetObjectName(tId)
        if name != "Default string" and name != "" then
            if StringContainsString(search, name) and not StringContainsString("Create ", name) and not StringContainsString("Quest ", name) then
                set SEARCH_RESULTS[pid * 800 + count] = itemCode + " - " + name
                set count = count + 1
                set exitcount = 0
            endif
        else
            set exitcount = exitcount + 1
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
    
    if (message == "-nocd") then
        set nocd[pid] = true
    elseif message == "-cd" or message == "-cdon" then
        set nocd[pid] = false
    elseif message == "-vampire" then
        call BlzSetUnitRealField(Hero[pid], UNIT_RF_SIGHT_RADIUS, 400.)
        loop
            exitwhen i > 7
            if Player(i) != currentPlayer then
                call SetPlayerAlliance( currentPlayer, Player(i), ALLIANCE_SHARED_VISION, false)
                call SetPlayerAlliance( Player(i), currentPlayer, ALLIANCE_SHARED_VISION, false)
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
        call AddPlatinumCoin(pid, S2I(SubString(message, 4, StringLength(message))) - udg_Plat_Gold[pid])
    elseif SubString(message,0,3)== "-sa" and SubString(message,3,5) != "ve" then
        call AddArcaditeLumber(pid, S2I(SubString(message, 4, StringLength(message))) - udg_Arca_Wood[pid])
    elseif SubString(message,0,3)== "-sc" then
        call AddCrystals(pid, S2I(SubString(message, 4, StringLength(message))) - udg_Crystals[pid])
    elseif SubString(message,0,5)== "-lvl " then
        if GetHeroLevel(PlayerSelectedUnit[pid]) > S2I(SubString(message, 5, 8)) then
            call UnitStripHeroLevel(PlayerSelectedUnit[pid], GetHeroLevel(PlayerSelectedUnit[pid]) - S2I(SubString(message, 5, 8)))
        else
            call SetHeroLevel(PlayerSelectedUnit[pid], S2I(SubString(message, 5, 8)),false)
        endif
    elseif SubString(message,0,5)== "-str " then
        call SetHeroStr(PlayerSelectedUnit[pid],S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,5)== "-agi " then
        call SetHeroAgi(PlayerSelectedUnit[pid],S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,5)== "-int " then
        call SetHeroInt(PlayerSelectedUnit[pid],S2I(SubString(GetEventPlayerChatString(), 5, 13)),true)
    elseif SubString(message,0,3)== "-g " then
        call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_GOLD, S2I(SubString(GetEventPlayerChatString(), 3, 10)) )
    elseif SubString(message,0,3)== "-l " then
        call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_LUMBER, S2I(SubString(GetEventPlayerChatString(), 3, 10)) )
    elseif message== "-maxgl" or message== "-glmax" then
        call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_GOLD, 1000000)
        call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_LUMBER, 1000000)
    elseif (message == "-day") then
        call SetTimeOfDay( 5.95 )
    elseif (message == "-night") then
        call SetTimeOfDay( 17.49 )
    elseif (message == "-cycle") then
        call SetTimeOfDayScale(50)
    elseif (SubString(message,0, 6) =="-probe") then
        call DEBUGMSG(Dec2Hex(S2I(SubString(message, 7, StringLength(message)))))
    elseif SubString(message,0,4)== "-si " then
        call FindItem(SubString(message, 4, StringLength(message)), pid)
    elseif SubString(message,0,4)== "-gi " then
        call CreateHeroItem(Hero[pid], pid, String2Id(SubString(message, 4, StringLength(message))), 1)
    elseif SubString(message,0,6)== "-item " and StringLength(message)== 10 then
        call CreateHeroItem(Hero[pid], pid, String2Id( SubString(message,6,10) ), 1 )
    elseif (message == "-pfall") or (message == "-allpf") then
        set udg_HeroCanUsePlate[pid]=true
        set udg_HeroCanUseFullPlate[pid]=true
        set udg_HeroCanUseLeather[pid]=true
        set udg_HeroCanUseCloth[pid]=true
        set udg_HeroCanUseHeavy[pid]=true
        set udg_HeroCanUseShortSword[pid]=true
        set udg_HeroCanUseDagger[pid]=true
        set udg_HeroCanUseBow[pid]=true
        set udg_HeroCanUseStaff[pid]=true
    elseif (message == "-hero") then
        //blue
        set Hero[2] = CreateUnitAtLoc(Player(1), 'E002', TownCenter, 0)
        set HeroID[2] = GetUnitTypeId(Hero[2])
        call GroupAddUnit(HeroGroup, Hero[2])
        //teal
        set Hero[3] = CreateUnitAtLoc(Player(2), 'E00X', TownCenter, 0)
        set HeroID[3] = GetUnitTypeId(Hero[3])
        call GroupAddUnit(HeroGroup, Hero[3])
        call SetPlayerAlliance(Player(1), currentPlayer, ALLIANCE_SHARED_CONTROL, true)
        call SetPlayerAlliance(Player(2), currentPlayer, ALLIANCE_SHARED_CONTROL, true)
        set HeroGrave[2] = CreateUnit(Player(1), GRAVE, -285, -72, 270)
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
        call Trig_Weather_Actions()
    elseif (message== "-noborders") then
        call SetCameraBoundsRectForPlayerEx(currentPlayer, GetWorldBounds() )
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
        set firestormrate = S2I(SubString(message, 14, StringLength(message)))
    elseif (message == "-horde") then
        set i = 0
    
        loop
            exitwhen i > 149
            call CreateUnitAtLoc(pfoe, 'n07R', GetUnitLoc(Hero[pid]), GetRandomReal(0,359))
            set i = i + 1
        endloop
    elseif (message == "-kill") then
        call KillUnit(PlayerSelectedUnit[pid])
    elseif (SubString(message, 0, 5) == "-ally") then
        call CreateUnit(currentPlayer, String2Id( SubString(message,6,10) ), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0,359))
    elseif (SubString(message, 0, 6) == "-enemy") then
        call CreateUnit(pfoe, String2Id( SubString(message,7,11) ), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]) - 300., GetRandomReal(0,359))
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
        call SaveInteger(PrestigeRank, pid, S2I(SubString(message,13,15)), S2I(SubString(message,15,17)))
        call SetPrestigeEffects(pid)
        call UpdateTooltips()
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
        call BJDebugMsg(I2S(StringHash(SubString(message,7,StringLength(message)))))
    elseif SubString(message,0,7) == "-printc" then
        call BJDebugMsg(I2S(String2Id(SubString(message,8,StringLength(message)))))
    elseif SubString(message,0,9) == "-addpoint" then
        call AllocateStatPoints(currentPlayer, 5)
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
        call UnitAddItemById(Hero[pid], 'I0M8')
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
            call CreateItemEx(ChooseRandomItem(GetRandomInt(1, 7)), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), true)
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
            set BOOST_OFF = false
        else
            set BOOST_OFF = true
        endif
    elseif SubString(message, 0, 5) == "-hurt" then
        call SetWidgetLife(PlayerSelectedUnit[pid], GetWidgetLife(PlayerSelectedUnit[pid]) - BlzGetUnitMaxHP(PlayerSelectedUnit[pid]) * 0.01 * S2I(SubString(message, 6, StringLength(message))))
    elseif message == "-buddha" then
        if BUDDHA_MODE[pid] then
            set BUDDHA_MODE[pid] = false
        else
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
    elseif SubString(message, 0, 9) == "-itemdata" then
        call SetItemUserData(UnitItemInSlot(Hero[pid], 0), S2I(SubString(message, 10, StringLength(message))))
    elseif SubString(message, 0, 10) == "-animation" then
        call SetUnitAnimationByIndex(PlayerSelectedUnit[pid], S2I(SubString(message, 11, StringLength(message))))
    elseif message == "-shadowstep" then
        call ShadowStepExpire()
    elseif message == "-hasabil" and GetUnitAbilityLevel(Hero[pid], 'A00D') > 0 then
        call DEBUGMSG("Yes!")
    endif
endfunction

private function init takes nothing returns nothing
    local trigger devcmd = CreateTrigger()
    local trigger search = CreateTrigger()
    local integer i = 0

	loop
		exitwhen i > 6
		call TriggerRegisterPlayerChatEvent(devcmd, Player(i), "-", false)
        set SEARCH_DIALOG[i] = DialogCreate()
        call TriggerRegisterDialogEvent(search, SEARCH_DIALOG[i])
        set i = i + 1
	endloop

    call TriggerAddAction(devcmd, function DevCommands)
    call TriggerAddAction(search, function SearchPage)
    
    set devcmd = null
    set search = null
endfunction

endlibrary
