library Functions uses TimerUtils, TimedHandles, TerrainPathability

globals
    string PROFILE_PREFIX = "P"
    string CHARACTER_PREFIX = "C"
    boolean tempbool = false
    integer indc = 0
    unit array DUMMY_LIST
    group DUMMY_STACK = CreateGroup()
    integer DUMMY_COUNT = 0
    real DUMMY_RECYCLE_TIME = 10.
    unit TEMP_DUMMY
    multiboard MULTI_BOARD
    integer ColoPlayerCount = 0
    boolean BOOST_OFF = false
    integer callbackCount = 0
    integer array passedValue
endglobals

struct BossItemList
    integer array items[64]
    integer size

    method addItem takes integer id returns nothing
        set items[size] = id
        set size = size + 1
    endmethod

    method pickItem takes nothing returns integer
        local integer i
        local integer id = 0
        local real dc = 1. / RMaxBJ(.size, 1)

        loop
            exitwhen id > 0
            set i = 0

            loop
                exitwhen i >= .size
                if GetRandomReal(0, 1) <= dc then
                    set id = .items[i]
                    exitwhen true
                endif
                set i = i + 1
            endloop
        endloop

        return id
    endmethod

    method onDestroy takes nothing returns nothing
        local integer i = 0

        set .size = 0
        loop
            exitwhen i > 64
            set items[i] = 0
            set i = i + 1
        endloop
    endmethod

    static method create takes nothing returns thistype
        local thistype il = thistype.allocate()

        return il
    endmethod

endstruct

function DEBUGMSG takes string s returns nothing
    static if LIBRARY_dev then
        if EXTRA_DEBUG then
            call DisplayTimedTextToForce(FORCE_PLAYING, 30., s)
        endif
    endif
endfunction

function UnitDisableAbility takes unit u, integer id, boolean disable returns nothing
    local integer ablev = GetUnitAbilityLevel(u, id)

    if ablev == 0 then
        return
    endif
    
    call UnitRemoveAbility(u, id)
    call UnitAddAbility(u, id)
    call SetUnitAbilityLevel(u, id, ablev)
    call BlzUnitDisableAbility(u, id, disable, false)
    call BlzUnitHideAbility(u, id, true)
endfunction

function Id2Char takes integer i returns string
    if i >= 97 then
        return SubString(abc,i - 97 + 36,i - 96 + 36)
    elseif i >= 65 then
        return SubString(abc,i - 65 + 10,i - 64 + 10)
    endif
    return SubString(abc,i - 48,i - 47)
endfunction

function Id2String takes integer id1 returns string
local integer t = id1 / 256
local string r = Id2Char(id1 - 256 * t)
    set id1 = t / 256
    set r = Id2Char(t - 256 * id1) + r
    set t = id1 / 256
    return Id2Char(t) + Id2Char(id1 - 256 * t) + r
endfunction

function ind takes nothing returns integer
    set indc = indc + 1
    return indc
endfunction

function indEx takes integer i returns integer
    set indc = indc + i
    return indc
endfunction

function W2U takes widget w returns unit
    call SaveFogStateHandle(MiscHash, 0, 0, ConvertFogState(GetHandleId(w)))
    return LoadUnitHandle(MiscHash, 0, 0)
endfunction

function HandleCount takes nothing returns nothing
    local location L = Location(0,0)
    call BJDebugMsg(I2S(GetHandleId(L)-0x100000))
    call RemoveLocation(L)
    set L = null
endfunction

function MakeGroupInRect takes integer pid, group g, rect r, boolexpr b returns nothing
    set callbackCount = callbackCount + 1
    set passedValue[callbackCount] = pid
    call GroupEnumUnitsInRect(g, r, b)
    set callbackCount = callbackCount - 1
endfunction

function MakeGroupInRange takes integer pid, group g, real x, real y, real radius, boolexpr b returns nothing
    set callbackCount = callbackCount + 1
    set passedValue[callbackCount] = pid
    call GroupEnumUnitsInRange(g, x, y, radius, b)
    set callbackCount = callbackCount - 1
endfunction

function GroupEnumUnitsInRangeEx takes integer pid, group g, real x, real y, real radius, boolexpr b returns nothing
    local group ug = CreateGroup()
    
    call MakeGroupInRange(pid, ug, x, y, radius, b)
    call BlzGroupAddGroupFast(ug, g)
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function Char2Id takes string c returns integer
    local integer i= 0
    local string t = ""

    loop
        set t = SubString(abc,i,i + 1)
        exitwhen t == null or t == c
        set i = i + 1
    endloop
    if i < 10 then
        return i + 48
    elseif i < 36 then
        return i + 65 - 10
    endif
    return i + 97 - 36
endfunction

function String2Id takes string s returns integer
    return ((Char2Id(SubString(s,0,1)) * 256 + Char2Id(SubString(s,1,2))) * 256 + Char2Id(SubString(s,2,3))) * 256 + Char2Id(SubString(s,3,4))
endfunction

function SetTableData takes HashTable ht, integer id, string data returns nothing
    local integer i = 0
    local integer i2 = 1
    local integer start = 0
    local integer end = 0
    local string tag = ""
    local integer value

    loop
        exitwhen i2 > StringLength(data) + 1
        if SubString(data, i, i2) == " " or i2 > StringLength(data) then
            set end = i

            set value = S2I(SubString(data, start, end))

            if value == 0 then
                set tag = SubString(data, start, end)
            else
                set ht[id][StringHash(tag)] = value
            endif

            set start = i2
        endif
    
        set i = i + 1
        set i2 = i2 + 1
    endloop
endfunction

function IndexIdsToArray takes Table tb, string s returns nothing
    local integer i = 0
    local integer i2 = 1
    local integer start = 0
    local integer end = 0
    local integer index = 0
    
    loop
        exitwhen i2 > StringLength(s) + 1
        if SubString(s, i, i2) == " " or i2 > StringLength(s) then
            set end = i
            set tb[index] = String2Id(SubString(s, start, end))
            set start = i2
            set index = index + 1
        endif
    
        set i = i + 1
        set i2 = i2 + 1
    endloop

    //call DEBUGMSG(Id2String(tb[0]))
endfunction

function MatchString takes string s, string s2 returns boolean
    local integer i = 0
    local integer i2 = 1
    local integer start = 0
    local integer end = 0
    
    loop
        exitwhen i2 > StringLength(s2) + 1
        if SubString(s2, i, i2) == " " or i2 > StringLength(s2) then
            set end = i
            if SubString(s2, start, end) == s then
                return true
            endif
            set start = i2
        endif
    
        set i = i + 1
        set i2 = i2 + 1
    endloop
    
    return false
endfunction

function ParseNewLine takes string s, integer i returns string
    local integer begin = 0
    local integer index = 0
    local integer index2 = 2
    local integer count = 0
    local string s2 = ""
    
    loop
        exitwhen count >= i or index > 999
        if SubString(s, index, index2) == "\n" then
            set count = count + 1
            set s2 = SubString(s, begin, index)
            set begin = index2
        endif
        set index = index + 1
        set index2 = index2 + 1
    endloop
    
    return s2
endfunction

function SoundHandler takes string path, player p returns nothing
    local sound s
    local string ss = ""
    
    if p != null then
        if GetLocalPlayer() == p then
            set ss = path
        endif
        set s = CreateSoundFromLabel(ss, false, false, false, 10, 10)
    else
        set s = CreateSoundFromLabel(path, false, false, false, 10, 10)
    endif

    call StartSound(s)
    call KillSoundWhenDone(s)
    
    set s = null
endfunction

function RemainingTimeString takes timer t returns string
    local real time = TimerGetRemaining(t)
    local string s = ""

    local integer minutes = R2I(time / 60.)
    local integer seconds = R2I(time - minutes * 60)
    
    if minutes > 0 then
        set s = I2S(minutes) + " minutes"
    else
        set s = I2S(seconds) + " seconds"
    endif
    
    return s
endfunction

function boolexp takes nothing returns boolean
    return true
endfunction

function ItemRepickRemove takes nothing returns nothing
    local item itm = GetEnumItem()

	if GetItemUserData(itm) == GetPlayerId(tempplayer) + 1 and itm != PathItem then
		call RemoveItem(itm)
	endif
    
    set itm = null
endfunction

function GetPlayerGold takes player whichPlayer returns integer
    return GetPlayerState( whichPlayer, PLAYER_STATE_RESOURCE_GOLD )
endfunction

function GetPlayerLumber takes player whichPlayer returns integer
    return GetPlayerState( whichPlayer, PLAYER_STATE_RESOURCE_LUMBER )
endfunction

/*function CloseF11 takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call ForceUICancel()
    endif
endfunction*/

function Trig_Enemy_Of_Hostile takes nothing returns boolean
	if IsUnitEnemy(GetFilterUnit(),pfoe) == false then
		return false
	elseif IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == true then
		return false
	elseif GetUnitTypeId(GetFilterUnit()) == BACKPACK then
		return false
	elseif GetUnitTypeId(GetFilterUnit()) == DUMMY then
		return false
	elseif GetUnitAbilityLevel(GetFilterUnit(), 'Aloc') > 0 then
		return false
    elseif GetPlayerId(GetOwningPlayer(GetFilterUnit())) > PLAYER_CAP then
		return false
	endif
	return true
endfunction

function CreateMB takes nothing returns nothing
    local integer i = 2
    local User p = User.first

    set QUEUE_BOARD = CreateMultiboard()
    set MULTI_BOARD = CreateMultiboard()
    call MultiboardSetRowCount(MULTI_BOARD, User.AmountPlaying + 1)
    call MultiboardSetColumnCount(MULTI_BOARD, 6)
    call MultiboardSetTitleText(MULTI_BOARD, "Curse of Time RPG: |c009966ffNevermore|r")
 
    call MultiboardSetItemValueBJ(MULTI_BOARD, 1, 1, "Player")
    call MultiboardSetItemColorBJ(MULTI_BOARD, 1, 1, 100, 80, 0, 0)
    call MultiboardSetItemValueBJ(MULTI_BOARD, 4, 1, "Hero")
    call MultiboardSetItemColorBJ(MULTI_BOARD, 4, 1, 100, 80, 0, 0)
    call MultiboardSetItemValueBJ(MULTI_BOARD, 5, 1, "Level")
    call MultiboardSetItemColorBJ(MULTI_BOARD, 5, 1, 100, 80, 0, 0)
    call MultiboardSetItemValueBJ(MULTI_BOARD, 6, 1, "%HP")
    call MultiboardSetItemColorBJ(MULTI_BOARD, 6, 1, 100, 80, 0, 0)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 1, 1, true, false)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 2, 1, false, false)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 3, 1, false, false)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 4, 1, true, false)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 5, 1, true, false)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 6, 1, true, false)
    call MultiboardSetItemWidthBJ(MULTI_BOARD, 1, 1, 11.00)
    call MultiboardSetItemWidthBJ(MULTI_BOARD, 2, 1, 2.00)
    call MultiboardSetItemWidthBJ(MULTI_BOARD, 3, 1, 2.00)
    call MultiboardSetItemWidthBJ(MULTI_BOARD, 4, 1, 11.00)
    call MultiboardSetItemWidthBJ(MULTI_BOARD, 5, 1, 4.00)
    call MultiboardSetItemWidthBJ(MULTI_BOARD, 6, 1, 4.00)

    loop 
        exitwhen p == User.NULL
        set udg_MultiBoardsSpot[p.id] = i

        call MultiboardSetItemValueBJ(MULTI_BOARD, 1, i, p.nameColored)
        call MultiboardSetItemStyleBJ(MULTI_BOARD, 1, i, true, false)
        call MultiboardSetItemWidthBJ(MULTI_BOARD, 1, i, 11.00)

        call MultiboardSetItemStyleBJ(MULTI_BOARD, 2, i, false, false)
        call MultiboardSetItemWidthBJ(MULTI_BOARD, 2, i, 2.00)
        
        call MultiboardSetItemStyleBJ(MULTI_BOARD, 3, i, false, false)
        call MultiboardSetItemWidthBJ(MULTI_BOARD, 3, i, 2.00)

        call MultiboardSetItemStyleBJ(MULTI_BOARD, 4, i, true, false)
        call MultiboardSetItemWidthBJ(MULTI_BOARD, 4, i, 11.00)

        call MultiboardSetItemStyleBJ(MULTI_BOARD, 5, i, true, false)
        call MultiboardSetItemWidthBJ(MULTI_BOARD, 5, i, 4.00)

        call MultiboardSetItemStyleBJ(MULTI_BOARD, 6, i, true, false)
        call MultiboardSetItemWidthBJ(MULTI_BOARD, 6, i, 4.00)

        set i = i + 1
        set p = p.next
    endloop
    
    call MultiboardDisplay(MULTI_BOARD, true)
endfunction

function VisibilityInit takes nothing returns nothing
    call FogModifierStart(CreateFogModifierRect(Player(PLAYER_NEUTRAL_PASSIVE),FOG_OF_WAR_VISIBLE,bj_mapInitialPlayableArea, false, false))
	call FogModifierStart(CreateFogModifierRect(pboss,FOG_OF_WAR_VISIBLE,gg_rct_Colosseum, false, false))
	call FogModifierStart(CreateFogModifierRect(pboss,FOG_OF_WAR_VISIBLE,gg_rct_Gods_Vision, false, false))
	call FogModifierStart(CreateFogModifierRect(pboss,FOG_OF_WAR_VISIBLE,gg_rct_InfiniteStruggleCameraBounds, false, false))
endfunction

function isvillager takes nothing returns boolean
    local integer id = GetUnitTypeId(GetFilterUnit())
	if id == 'h04A' or id == 'n02V' or id == 'n03U' or id == 'n09Q' or id == 'n09T' or id == 'n09O' or id == 'n09P' or id == 'n09R' or id == 'n09S' or id == 'nvk2' or id == 'nvlw' or id == 'nvlk' or id == 'nvil' or id == 'nvl2' or id == 'H01Y' or id == 'H01T' or id == 'n036' or id == 'n035' or id == 'n037' or id == 'n03S' or id == 'n01I' or id == 'n0A3' or id == 'n0A4' or id == 'n0A5' or id == 'n0A6' or id == 'h00G' then
        return true
	endif
	return false
endfunction

function isspirit takes nothing returns boolean
    local integer id = GetUnitTypeId(GetFilterUnit())
    if id == 'n00P' then
        return true
    endif

    return false
endfunction

function ishero takes nothing returns boolean
    return ( IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true )
endfunction

function ischar takes nothing returns boolean
    local integer pid = GetPlayerId(GetOwningPlayer(GetFilterUnit())) + 1

    return ( GetFilterUnit() == Hero[pid] and GetWidgetLife(Hero[pid]) >= 0.406 )
endfunction

function nothero takes nothing returns boolean
	return ( IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == false and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitTypeId(GetFilterUnit()) != DUMMY)
endfunction

function isbase takes nothing returns boolean
    return ( IsUnitType(GetFilterUnit(), UNIT_TYPE_TOWNHALL) == true )
endfunction

function trigenemy takes nothing returns boolean
	return IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD)==false and IsUnitEnemy(GetFilterUnit(),GetOwningPlayer(GetTriggerUnit()))
endfunction

function isOrc takes nothing returns boolean
    local integer uid = GetUnitTypeId(GetFilterUnit())

    return (GetWidgetLife(GetFilterUnit()) >= 0.406 and (uid == 'o01I' or uid == 'o008'))
endfunction

function ishostile takes nothing returns boolean
    local integer i=GetPlayerId(GetOwningPlayer(GetFilterUnit()))

	return (GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and (i==10 or i==11 or i==foe))
endfunction

function ChaosTransition takes nothing returns boolean
    local integer i = GetPlayerId(GetOwningPlayer(GetFilterUnit()))

	return (GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and (i==10 or i==11 or i==foe) and RectContainsUnit(gg_rct_Colosseum, GetFilterUnit()) == false and RectContainsUnit(gg_rct_Infinite_Struggle, GetFilterUnit()) == false)
endfunction

function isplayerAlly takes nothing returns boolean
	return GetWidgetLife(GetFilterUnit()) >= 0.406 and GetPlayerId(GetOwningPlayer(GetFilterUnit())) < 8 and IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true and GetUnitTypeId(GetFilterUnit()) != BACKPACK
endfunction

function iszeppelin takes nothing returns boolean
    return (GetUnitTypeId(GetFilterUnit()) == 'nzep' and GetWidgetLife(GetFilterUnit()) >= 0.406)
endfunction

function isplayerunit takes nothing returns boolean
    return (IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD)==false and GetPlayerId(GetOwningPlayer(GetFilterUnit())) < 8 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0)
endfunction

function ishostileEnemy takes nothing returns boolean
local integer i=GetPlayerId(GetOwningPlayer(GetFilterUnit()))
	return (IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD)==false and GetUnitAbilityLevel(GetFilterUnit(), 'Avul') ==0 and i < 9)
endfunction

function isalive takes nothing returns boolean
	return (IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD)==false and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0)
endfunction

function IsBoss takes integer uid returns boolean
    local integer i = 0

    loop
        exitwhen ChaosBossID[i] == uid or PreChaosBossID[i] == uid or i > BOSS_TOTAL
        set i = i + 1
    endloop

    return i <= BOSS_TOTAL
endfunction

function IsEnemy takes integer i returns boolean
    return (i == 12 or i == foe + 1)
endfunction

function ExplodeUnits takes nothing returns nothing
    call SetUnitExploded(GetEnumUnit(), true)
    call KillUnit(GetEnumUnit())
endfunction

function ClearItems takes nothing returns nothing
    local item itm = GetEnumItem()
    local integer itid = GetItemTypeId(itm)
    
    if itid == 'I042' or itid == 'I040' or itid == 'I041' or itid == 'I0M4' or itid == 'I0M5' or itid == 'I0M6' or itid == 'I0M7' or itm == PathItem then //keys+pathcheck
    else
        call RemoveItem(itm)
    endif
    
endfunction

function ClearWeather takes unit u returns nothing
    call BlzSetUnitAttackCooldown(u, BlzGetUnitAttackCooldown(u, 0) * weatheratkspd[udg_Weather], 0)
endfunction

function ApplyWeather takes unit u returns nothing
    call BlzSetUnitAttackCooldown(u, BlzGetUnitAttackCooldown(u, 0) / weatheratkspd[udg_Weather], 0)
endfunction

function AddArcaditeLumber takes integer pid, integer num returns nothing
    set udg_Arca_Wood[pid] = IMaxBJ(0, udg_Arca_Wood[pid] + num)
    if GetLocalPlayer() == Player(pid - 1) then
        call BlzFrameSetText(arcText, I2S(udg_Arca_Wood[pid]))
    endif
endfunction

function AddPlatinumCoin takes integer pid, integer num returns nothing
    set udg_Plat_Gold[pid] = IMaxBJ(0, udg_Plat_Gold[pid] + num)
    if GetLocalPlayer() == Player(pid - 1) then
        call BlzFrameSetText(platText, I2S(udg_Plat_Gold[pid]))
    endif
endfunction

function AddCrystals takes integer pid, integer num returns nothing
    set udg_Crystals[pid] = IMaxBJ(0, udg_Crystals[pid] + num)
    call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_FOOD_USED, udg_Crystals[pid])
endfunction

function RemovePlayerUnits takes integer pid returns nothing
    local group ug = CreateGroup()
    local unit target
    local integer i
    local integer itid
    
    call GroupEnumUnitsOfPlayer(ug, Player(pid - 1), null)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if IsUnitType(target, UNIT_TYPE_HERO) then
            set i = 0
            loop
                exitwhen i > 5
                set itid = GetItemTypeId(UnitItemInSlot(target, i))
                if itid == 'I042' or itid == 'I040' or itid == 'I041' or itid == 'I0M4' or itid == 'I0M5' or itid == 'I0M6' or itid == 'I0M7' then //keys
                    call UnitRemoveItemFromSlot(target, i)
                endif
                set i = i + 1
            endloop
        endif
        if GetUnitTypeId(target) != DUMMY and target != hsdummy[pid] then
            call RemoveUnit(target)
        endif
    endloop
    
    call DestroyGroup(ug)
    
    set ug = null
endfunction

function MainStat takes unit hero returns integer //returns integer signifying primary attribute
    return BlzGetUnitIntegerField(hero, UNIT_IF_PRIMARY_ATTRIBUTE)
endfunction

function MainStatForm takes integer pid, integer i returns nothing
    if MainStat(hsdummy[pid]) != i then //str dummy
        call RemoveUnit(hsdummy[pid])
        if i == 1 then
            set hsdummy[pid] = CreateUnit(Player(pid - 1), 'E001', 30000, 30000, 0)
        elseif i == 2 then
            set hsdummy[pid] = CreateUnit(Player(pid - 1), 'E004', 30000, 30000, 0)
        elseif i == 3 then
            set hsdummy[pid] = CreateUnit(Player(pid - 1), 'E01A', 30000, 30000, 0)
        endif
    endif
endfunction

function NearbyRect takes rect r, real x, real y returns boolean
    local integer i = 0
    local real angle = Atan2(GetRectCenterY(r) - y, GetRectCenterX(r) - x)

    loop
        exitwhen i > 99
        if RectContainsCoords(r, x + Cos(angle) * i, y + Sin(angle) * i) then
            exitwhen true
        endif
        set i = i + 1
    endloop
    
    return i <= 99
endfunction

function CustomLightingPlayerCheck takes integer i, real x, real y returns nothing
    if RectContainsCoords(gg_rct_Main_Map_Vision, x, y) and CustomLighting[i] != 1 then
        set CustomLighting[i] = 1
        if charLightId[i] != 1 then
            call UnitRemoveAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 1
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        endif
    elseif RectContainsCoords(gg_rct_Naga_Dungeon_Reward, x, y) and CustomLighting[i] != 2 then
        set CustomLighting[i] = 2
        if charLightId[i] != 1 then
            call UnitRemoveAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 1
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        endif
    elseif RectContainsCoords(gg_rct_Naga_Dungeon, x, y) and not RectContainsCoords(gg_rct_Naga_Dungeon_Reward, x, y) and CustomLighting[i] != 3 then
        set CustomLighting[i] = 3
        if charLightId[i] != 2 then
            call UnitAddAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 2
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("","")
        endif
    elseif RectContainsCoords(gg_rct_Naga_Dungeon_Boss, x, y) and CustomLighting[i] != 4 then
        set CustomLighting[i] = 4
        if charLightId[i] != 2 then
            call UnitAddAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 2
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("","")
        endif
    elseif RectContainsCoords(gg_rct_Church, x, y) and CustomLighting[i] != 5 then
        set CustomLighting[i] = 5
        if charLightId[i] != 2 then
            call UnitAddAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 2
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("","")
        endif
    elseif RectContainsCoords(gg_rct_Tavern, x, y) and CustomLighting[i] != 6 then
        set CustomLighting[i] = 6
        if charLightId[i] != 2 then
            call UnitAddAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 2
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("","")
        endif
    elseif RectContainsCoords(gg_rct_Cave, x, y) and CustomLighting[i] != 7 then
        set CustomLighting[i] = 7
        if charLightId[i] != 2 then
            call UnitAddAbility(Hero[i], 'A0B8')
            call UnitRemoveAbility(Hero[i], 'A0AN')
            set charLightId[i] = 2
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("","")
        endif
    endif
endfunction

function DelayAnimationExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    if pt.str > 0 then
        call BlzPauseUnitEx(pt.target, false)
    endif

    if pt.dur > 0 then
        call SetUnitTimeScale(pt.target, pt.dur)
    endif

    call SetUnitAnimationByIndex(pt.target, pt.agi)

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function DelayAnimation takes integer pid, unit u, real delay, integer index, real timescale, boolean pause returns nothing
    local PlayerTimer pt = TimerList[pid].addTimer(pid)

    set pt.target = u
    set pt.agi = index
    set pt.str = 0
    set pt.dur = timescale
    set pt.tag = 'dani'

    if pause then
        call BlzPauseUnitEx(u, true)
        set pt.str = 1
    endif

    call TimerStart(pt.getTimer(), delay, false, function DelayAnimationExpire)
endfunction

function SetCameraBoundsRectForPlayerEx takes player p, rect r returns nothing
    local real minX = GetRectMinX(r)
    local real minY = GetRectMinY(r)
    local real maxX = GetRectMaxX(r)
    local real maxY = GetRectMaxY(r)
    local integer pid = GetPlayerId(p) + 1

    //lighting
    call CustomLightingPlayerCheck(pid, (minX + maxX) * 0.5, (minY + maxY) * 0.5)
    
    if GetLocalPlayer() == p then
        call SetCameraField(CAMERA_FIELD_ROTATION, 90., 0)
        call SetCameraBounds(minX, minY, minX, maxY, maxX, maxY, maxX, minY)
    endif
endfunction

function SpawnWispSelector takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer) + 1

    set hslook[pid] = 0
    if hsdummy[pid] == null then
        set hsdummy[pid] = CreateUnit(whichPlayer, 'E001', 30000, 30000, 0)
    else
        call ShowUnit(hsdummy[pid], true)
    endif

    call MainStatForm(pid, MainStat(hstarget[0]))

    call BlzSetUnitSkin(hsdummy[pid], hsskinid[0])
    call BlzSetUnitName(hsdummy[pid], GetUnitName(hstarget[0]))
    call BlzSetHeroProperName(hsdummy[pid], GetHeroProperName(hstarget[0]))
    //call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_PRIMARY_ATTRIBUTE, BlzGetUnitIntegerField(hstarget[0], UNIT_IF_PRIMARY_ATTRIBUTE))
    call BlzSetUnitWeaponIntegerField(hsdummy[pid], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0, BlzGetUnitWeaponIntegerField(hstarget[0], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0))
    call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_DEFENSE_TYPE, BlzGetUnitIntegerField(hstarget[0], UNIT_IF_DEFENSE_TYPE))
    call BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0, BlzGetUnitWeaponRealField(hstarget[0], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0))
    call BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_RANGE, 0, BlzGetUnitWeaponRealField(hstarget[0], UNIT_WEAPON_RF_ATTACK_RANGE, 0))
    call BlzSetUnitArmor(hsdummy[pid], BlzGetUnitArmor(hstarget[0]))

    call SetHeroStr(hsdummy[pid], GetHeroStr(hstarget[0], true), true)
    call SetHeroAgi(hsdummy[pid], GetHeroAgi(hstarget[0], true), true)
    call SetHeroInt(hsdummy[pid], GetHeroInt(hstarget[0], true), true)

    call BlzSetUnitBaseDamage(hsdummy[pid], BlzGetUnitBaseDamage(hstarget[hslook[pid]], 0), 0)
    call BlzSetUnitDiceNumber(hsdummy[pid], BlzGetUnitDiceNumber(hstarget[hslook[pid]], 0), 0)
    call BlzSetUnitDiceSides(hsdummy[pid], BlzGetUnitDiceSides(hstarget[hslook[pid]], 0), 0)

    call BlzSetUnitMaxHP(hsdummy[pid], BlzGetUnitMaxHP(hstarget[0]))
    call BlzSetUnitMaxMana(hsdummy[pid], BlzGetUnitMaxMana(hstarget[0]))
    call SetWidgetLife(hsdummy[pid], BlzGetUnitMaxHP(hsdummy[pid]))

    call UnitAddAbility(hsdummy[pid], hsselectid[0])
    call UnitAddAbility(hsdummy[pid], hspassiveid[0])

    call UnitAddAbility(hsdummy[pid], 'A0JI')
    call UnitAddAbility(hsdummy[pid], 'A0JQ')
    call UnitAddAbility(hsdummy[pid], 'A0JR')
    call UnitAddAbility(hsdummy[pid], 'A0JS')
    call UnitAddAbility(hsdummy[pid], 'A0JT')
    call UnitAddAbility(hsdummy[pid], 'A0JU')
    call UnitAddAbility(hsdummy[pid], 'Aeth')
    call SetUnitPathing(hsdummy[pid], false)
    call UnitRemoveAbility(hsdummy[pid], 'Amov')
    call BlzUnitHideAbility(hsdummy[pid], 'Aatk', true)
    call SetCameraBoundsRectForPlayerEx(whichPlayer, gg_rct_Tavern_Vision)

    if (GetLocalPlayer() == whichPlayer) then
        call SetCameraTargetController(hstarget[0], 0, 0, false)
        call ClearSelection()
        call SelectUnit( hsdummy[pid], true )
        call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
    endif
    
    set Backpack[pid] = null
    set hselection[pid] = true
    //call SetCameraBoundsToRectForPlayerBJ(whichPlayer, gg_rct_Main_Map_Vision)
    call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_GOLD, 75)
    call SetPlayerState(whichPlayer, PLAYER_STATE_RESOURCE_LUMBER, 30)
endfunction

function OnDialogButtonClickedYes takes nothing returns boolean
    local integer pid = GetPlayerId(GetTriggerPlayer()) + 1

    call Profiles[pid].createRandomHash()

    call DialogDestroy(GetClickedDialog())
    call SpawnWispSelector(GetTriggerPlayer())
    return false
endfunction

function OnDialogButtonClickedNo takes nothing returns boolean
    call DialogDestroy(GetClickedDialog()) 
    return false
endfunction

function ResetPathing takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = LoadUnitHandle(MiscHash, 0, GetHandleId(t))

    call SetUnitPathing(u, true)
    call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
    call ReleaseTimer(t)

    set t = null
    set u = null
endfunction

function ResetPathingTimed takes unit u, real time returns nothing
    local timer t = NewTimer()

    call SaveUnitHandle(MiscHash, 0, GetHandleId(t), u)
    call TimerStart(t, time, false, function ResetPathing)

    set t = null
endfunction

function phtlToValue takes integer phtl, integer KEY returns integer
    local string s = I2S(phtl)

    if phtl < 1000000 then
        return 0
    endif

    if KEY == 0 then
        return S2I(SubString(s, 0, 1)) - 1
    elseif KEY == 1 then
        return S2I(SubString(s, 1, 2)) - 1
    elseif KEY == 2 then
        return S2I(SubString(s, 2, 4)) - 10
    elseif KEY == 3 then
        return S2I(SubString(s, 4, 7)) - 100
    endif

    return 0
endfunction

function ConvertUnitId takes integer unitId returns integer
    return LoadInteger(SAVE_TABLE, KEY_UNITS, unitId)
endfunction

function getLine takes integer line, string contents returns string
    local integer len       = StringLength(contents)
    local string char       = ""
    local string buffer     = "" 
    local integer curLine   = 0
    local integer i         = 0
    
    loop
        exitwhen i > len
        set char = SubString(contents, i, i + 1)
        if (char == "\n") then
            set curLine = curLine + 1
            if (curLine > line) then
                return buffer
            endif
            set buffer = ""
        else
            set buffer = buffer + char
        endif
        set i = i + 1
    endloop

    if (curLine == line) then
        return buffer
    endif

    return null
endfunction
        
function DisplayHeroSelectionDialog takes integer pid returns nothing
    local integer i = 0
    local integer herolevel = 0
    local string name = ""
    local integer slotsUsed = Profiles[pid].getSlotsUsed()

    call DialogClear(LoadDialog[pid])
    set deleteMode[pid] = false
    set loadPage[pid] = 0

    loop
        exitwhen i > 29 or loadPage[pid] > 5
            if Profiles[pid].phtl[i] > 1000000 then //slot is not empty
                set name = "|cffffcc00"
                set herolevel = phtlToValue(Profiles[pid].phtl[i], 3)
                if phtlToValue(Profiles[pid].phtl[i], 0) > 0 then
                    set name = name + "[PRSTG] "
                endif
                set name = name + GetObjectName(udg_SaveUnitType[phtlToValue(Profiles[pid].phtl[i], 2)]) + " [" + I2S(herolevel) + "] "
                if phtlToValue(Profiles[pid].phtl[i], 1) > 0 then
                    set name = name + "[HC]"
                endif
                set LoadDialogButton[30 * pid + i] = DialogAddButton(LoadDialog[pid], name, 0)
                set loadPage[pid] = loadPage[pid] + 1
            endif
        set i = i + 1
    endloop
    
    if slotsUsed > loadPage[pid] then
        set LoadDialogButton[pid + 500] = DialogAddButton(LoadDialog[pid], "|cffffffffNext Page", 0)
    endif
    
    if hselection[pid] then
        call DialogAddButton(LoadDialog[pid], "|cffffffffCancel", 0)
    else
        set LoadDialogButton[pid + 1000] = DialogAddButton(LoadDialog[pid], "|cffffffffNew Character", 0)
    endif
    
    if slotsUsed > 0 then
        set LoadDialogButton[pid + 1500] = DialogAddButton(LoadDialog[pid], "|cffffffffDelete Character", 0)
    endif
    
    call DialogDisplay(Player(pid - 1), LoadDialog[pid], true)
endfunction

function SetSaveSlot takes integer pid returns nothing
    local integer i = 0

    loop
        exitwhen i > 29

        if Profiles[pid].phtl[i] <= 0 then
            set Profiles[pid].currentSlot = i
            exitwhen true
        endif

        set i = i + 1
    endloop

    if i == 30 then
        set Profiles[pid].currentSlot = -1
    endif
endfunction


function onLoadButtonClick takes nothing returns nothing
    local button buttonClicked = GetClickedButton()
    local boolean buttonClickedFound = false
    local player p = GetTriggerPlayer()
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local integer j = 0
    local integer clickedSlot
    local integer herolevel
    local string name = ""
    local integer slotsUsed = Profiles[pid].getSlotsUsed()

    loop
        exitwhen j > 29 or buttonClickedFound
        
        if LoadDialogButton[pid * 30 + j] == buttonClicked then
            set clickedSlot = j
            set buttonClickedFound = true
            set Profiles[pid].currentSlot = clickedSlot
        endif
        
        set j = j + 1
    endloop
    
    call DialogClear(LoadDialog[pid])
    
    set j = 0

    if buttonClicked == LoadDialogButton[pid + 500] then
        set deleteMode[pid] = false
    
        if loadPage[pid] > slotsUsed - 1 then
            set loadPage[pid] = 0
        endif
        
        set i = loadPage[pid]

        loop
            exitwhen i > 29 or j > 5
                if Profiles[pid].phtl[i] > 1000000 then //slot is not empty 
                    set herolevel = phtlToValue(Profiles[pid].phtl[i], 3)
                    set name = "|cffffcc00"
                    if phtlToValue(Profiles[pid].phtl[i], 0) > 0 then
                        set name = name + "[PRSTG] "
                    endif
                    set name = name + GetObjectName(udg_SaveUnitType[phtlToValue(Profiles[pid].phtl[i], 2)]) + " [" + I2S(herolevel) + "] "
                    if phtlToValue(Profiles[pid].phtl[i], 1) > 0 then
                        set name = name + "[HC]"
                    endif
                    set LoadDialogButton[30 * pid + i] = DialogAddButton(LoadDialog[pid], name, 0)
                    set j = j + 1
                    set loadPage[pid] = loadPage[pid] + 1
                endif
            set i = i + 1
        endloop

        set LoadDialogButton[pid + 500] = DialogAddButton(LoadDialog[pid], "|cffffffffNext Page", 0)
        if hselection[pid] then
            call DialogAddButton(LoadDialog[pid], "|cffffffffCancel", 0)
        else
            set LoadDialogButton[pid + 1000] = DialogAddButton(LoadDialog[pid], "|cffffffffNew Character", 0)
        endif
        if slotsUsed > 0 then
            set LoadDialogButton[pid + 1500] = DialogAddButton(LoadDialog[pid], "|cffffffffDelete Character", 0)
        endif
        call DialogDisplay(p, LoadDialog[pid], true)
        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 1000] then //New character
        if Profiles[pid].getSlotsUsed() >= 30 then
            call DisplayTimedTextToPlayer(p, 0, 0, 30.0, "You cannot save more than 30 heroes!")
            call DisplayHeroSelectionDialog(pid)
        else
            call DisplayTimedTextToPlayer(p, 0, 0, 30.0, "Select a |c006969ffhero|r using arrow keys.")
            set newcharacter[pid] = true
            call SetSaveSlot(pid)
            call DEBUGMSG(I2S(Profiles[pid].currentSlot))
            call SpawnWispSelector(p)
        endif

        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 1500] then //Show delete menu
        set deleteMode[pid] = true
        set loadPage[pid] = 0
    
        loop
            exitwhen i > 29 or loadPage[pid] > 6

            if Profiles[pid].phtl[i] > 1000000 then //slot is not empty 
                set herolevel = phtlToValue(Profiles[pid].phtl[i], 3)
                set name = "|cffffcc00"
                if phtlToValue(Profiles[pid].phtl[i], 0) > 0 then
                    set name = name + "[PRSTG] "
                endif
                set name = name + GetObjectName(udg_SaveUnitType[phtlToValue(Profiles[pid].phtl[i], 2)]) + " [" + I2S(herolevel) + "] "
                if phtlToValue(Profiles[pid].phtl[i], 1) > 0 then
                    set name = name + "[HC]"
                endif
                set LoadDialogButton[30 * pid + i] = DialogAddButton(LoadDialog[pid], name, 0)
                set loadPage[pid] = loadPage[pid] + 1
            endif

            set i = i + 1
        endloop
    
        if slotsUsed > loadPage[pid] then
            set LoadDialogButton[pid + 2000] = DialogAddButton(LoadDialog[pid], "|cffffffffNext Page", 0)
        endif

        set LoadDialogButton[pid + 2500] = DialogAddButton(LoadDialog[pid], "|cffffffffBack", 0)
        call DialogDisplay(p, LoadDialog[pid], true)
        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 2000] then //Next page delete
        set deleteMode[pid] = true
    
        if loadPage[pid] > slotsUsed - 1 then
            set loadPage[pid] = 0
        endif
        
        set i = loadPage[pid]
    
        loop
            exitwhen i > 29 or j > 6

            if Profiles[pid].phtl[i] > 1000000 then //slot is not empty 
                set herolevel = phtlToValue(Profiles[pid].phtl[i], 3)
                set name = "|cffffcc00"
                if phtlToValue(Profiles[pid].phtl[i], 0) > 0 then
                    set name = name + "[PRSTG] "
                endif
                set name = name + GetObjectName(udg_SaveUnitType[phtlToValue(Profiles[pid].phtl[i], 2)]) + " [" + I2S(herolevel) + "] "
                if phtlToValue(Profiles[pid].phtl[i], 1) > 0 then
                    set name = name + "[HC]"
                endif
                set LoadDialogButton[30 * pid + i] = DialogAddButton(LoadDialog[pid], name, 0)
                set loadPage[pid] = loadPage[pid] + 1
                set j = j + 1
            endif

            set i = i + 1
        endloop

        set LoadDialogButton[pid + 2000] = DialogAddButton(LoadDialog[pid], "|cffffffffNext Page", 0)
        set LoadDialogButton[pid + 2500] = DialogAddButton(LoadDialog[pid], "|cffffffffBack", 0)
        call DialogDisplay(p, LoadDialog[pid], true)
        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 2500] then //Go back
        call DisplayHeroSelectionDialog(pid)
        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 3000] then //Confirm delete
        //delete slot
        if GetLocalPlayer() == p then
            call FileIO_Write(udg_MapName + "\\" + User.fromIndex(pid - 1).name + "\\slot" + I2S(Profiles[pid].currentSlot + 1) + ".pld", "")
        endif
        call Profiles[pid].saveProfile()
        call DisplayHeroSelectionDialog(pid)
        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 3500] then //Go back
        call DisplayHeroSelectionDialog(pid)
        set buttonClicked = null
        return
    endif
    
    if deleteMode[pid] then
        call DialogSetMessage(LoadDialog[pid], "Are you sure?/n(Any prestige bonuses from this character will be removed)")
        
        set LoadDialogButton[pid + 3000] = DialogAddButton(LoadDialog[pid], "Yes", 0)
        set LoadDialogButton[pid + 3500] = DialogAddButton(LoadDialog[pid], "No", 0)
        
        call DialogDisplay(p, LoadDialog[pid], true)
    else
        if buttonClickedFound then
            if LOAD_SAFE then
                call DisplayTextToPlayer(p, 0, 0, "Loading |c006969ffhero|r from selected slot...")
                set LOAD_SAFE = false
            else
                call DisplayTextToPlayer(p, 0, 0, "Please wait until a player is done loading!")
                call DisplayHeroSelectionDialog(pid)
                set buttonClicked = null
                set p = null
                return
            endif

            if GetLocalPlayer() == p then
                call BlzSendSyncData(CHARACTER_PREFIX, getLine(1, FileIO_Read(udg_MapName + "\\" + User[p].name + "\\slot" + I2S(clickedSlot + 1) + ".pld")))
            endif

            set LOAD_SAFE = true
        endif
    endif
    
    set buttonClicked = null
endfunction

function EnterWeather takes unit u returns nothing
    local real x=GetUnitX(u)
    local real y=GetUnitY(u)

    if RectContainsCoords(gg_rct_Main_Map,x,y) and IsUnitInGroup(u,AffectedByWeather)==false then
        call ApplyWeather(u)
        call GroupAddUnit(AffectedByWeather,u)
    elseif RectContainsCoords(gg_rct_Main_Map,x,y)==false and IsUnitInGroup(u,AffectedByWeather)then
        call ClearWeather(u)
        call GroupRemoveUnit(AffectedByWeather,u)
    endif
endfunction

function ResetArena takes integer arena returns nothing
    local integer pid
    local User U = User.first
    
    if arena == 2 or arena == 0 then
        return
    endif
    
    loop
        exitwhen U == User.NULL
        set pid = GetPlayerId(U.toPlayer()) + 1

        if IsUnitInGroup(Hero[pid], Arena[arena]) then
            call PauseUnit(Hero[pid], false)
            call UnitRemoveAbility(Hero[pid], 'Avul')
            call SetUnitAnimation(Hero[pid], "stand")
            call SetUnitPositionLoc(Hero[pid], TownCenter)
            call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(Hero[pid]), gg_rct_Main_Map_Vision)
            call PanCameraToTimedForPlayer(GetOwningPlayer(Hero[pid]), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
            call EnterWeather(Hero[pid])
        endif
        
        set U = U.next
    endloop
endfunction

function GetUnitArena takes unit u returns integer
    local integer i = 1

    if u == null then
        return 0
    endif
    
    loop
        exitwhen i > ArenaMax
        if IsUnitInGroup(u, Arena[i]) then
            return i
        endif
        set i = i + 1
    endloop
    
    return 0
endfunction

function ClearStruggle takes nothing returns nothing
    local group ug = CreateGroup()
    local unit u
    local User U = User.first

    call GroupEnumUnitsInRect(ug, gg_rct_Infinite_Struggle, Condition(function nothero))
    loop
        set u = FirstOfGroup(ug)
        exitwhen u == null
        call GroupRemoveUnit(ug, u)
        call RemoveUnit(u)
    endloop

    set udg_Struggle_WaveN = 0
    set udg_GoldWon_Struggle = 0
    set udg_Struggle_WaveUCN = 0
    call PauseTimer(strugglespawn)

    call DestroyGroup(ug)

    set ug = null
    set u = null
endfunction

function ClearColo takes nothing returns nothing
    local group ug = CreateGroup()
    local unit u

    set udg_GoldWon_Colo = 0

    call GroupEnumUnitsInRect(ug, gg_rct_Colosseum, Condition(function nothero))
    loop
        set u = FirstOfGroup(ug)
        exitwhen u == null
        call GroupRemoveUnit(ug, u)
        call RemoveUnit(u)
    endloop
    
    call EnumItemsInRect(gg_rct_Colosseum, function boolexp, function ClearItems)
    call SetTextTagText( ColoText, "Colosseum", 10 * 0.023 / 10 )
    call DestroyGroup(ug)

    set ug = null
    set u = null
endfunction

function SharedRepick takes player p returns nothing //any instance of player removal (leave, repick, permanent death, forcesave, afk removal)
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local item itm
    local group ug = CreateGroup()
    local unit target

    call UnitRemoveAbility(Hero[pid], 'A03C') //close actions spellbook
    
    loop //clear ashen vat
        exitwhen i > 5
        set itm = UnitItemInSlot(ASHEN_VAT, i)
        if GetItemUserData(itm) == pid then
            call UnitRemoveItemFromSlot(ASHEN_VAT, i)
            call RemoveItem(itm)
        endif
        set i = i + 1
    endloop

    set i = 0

    loop //clear cosmetics
        exitwhen i > cosmeticTotal

        if cosmeticAttach[pid * cosmeticTotal + i] != null then
            call DestroyEffectTimed(cosmeticAttach[pid * cosmeticTotal + i], 0)
            set cosmeticAttach[pid * cosmeticTotal + i] = null
        endif

        set i = i + 1
    endloop

    if InColo[pid] then
        set ColoPlayerCount = ColoPlayerCount - 1
        set InColo[pid] = false

        if ColoPlayerCount <= 0 then
            call ClearColo()
        endif
    endif

    call ResetArena(GetUnitArena(Hero[pid])) //reset pvp

    if InStruggle[pid] then
        set udg_Struggle_Pcount = udg_Struggle_Pcount - 1
        set InStruggle[pid] = false

        if udg_Struggle_Pcount <= 0 then
            call ClearStruggle()
        endif
    endif
    
    set mybase[pid] = null
    call GroupRemoveUnit(AzazothPlayers, Hero[pid]) //clear aza
    call GroupRemoveUnit(HeroGroup, Hero[pid])
    call RemovePlayerUnits(pid)

    call TimerList[pid].stopAllTimers()

    set Hero[pid] = null
    set HeroID[pid] = 0
	set Backpack[pid] = null
    call AddPlatinumCoin(pid, -udg_Plat_Gold[pid])
    call AddArcaditeLumber(pid, -udg_Arca_Wood[pid])
    call AddCrystals(pid, -udg_Crystals[pid])
	set udg_ArcaConverter[pid] = false
	set udg_ArcaConverterBought[pid] = false
	set udg_PlatConverter[pid] = false
	set udg_PlatConverterBought[pid] = false
	set DmgBase[pid] = 0
	set SpellTakenBase[pid] = 0
    set ItemEvasion[pid] = 0
    set ItemSpellboost[pid] = 0
    set ItemMovespeed[pid] = 0
    set ItemSpelldef[pid] = 1
    set ItemTotaldef[pid] = 1
    set TotalEvasion[pid] = 0
    set ItemGoldRate[pid] = 0
    set udg_HeroCanUsePlate[pid] = false
	set udg_HeroCanUseFullPlate[pid] = false
	set udg_HeroCanUseLeather[pid] = false
	set udg_HeroCanUseCloth[pid] = false
	set udg_HeroCanUseHeavy[pid] = false
	set udg_HeroCanUseShortSword[pid] = false
	set udg_HeroCanUseDagger[pid] = false
	set udg_HeroCanUseBow[pid] = false
	set udg_HeroCanUseStaff[pid] = false
    set udg_TimePlayed[pid] = 0
    set HeartHits[pid] = 0
    set HeartDealt[pid] = 0
    set urhome[pid] = 0
    set BloodBank[pid] = 0
    set BardSong[pid] = 0
    set ReincarnationPRCD[pid] = 0
    set ResurrectionCD[pid] = 0
    set hardcoreClicked[pid] = false
    set FlamingBowBonus[pid] = 0
    set FlamingBowCount[pid] = 0
    set CameraLock[pid] = false
    set meatgolem[pid] = null
    set destroyer[pid] = null
    set hounds[pid * 10] = null
    set hounds[pid * 10 + 1] = null
    set hounds[pid * 10 + 2] = null
    set hounds[pid * 10 + 3] = null
    set hounds[pid * 10 + 4] = null
    set hounds[pid * 10 + 5] = null

    //reset unit limit
    set workerCount[pid] = 0
    set smallwispCount[pid] = 0
    set largewispCount[pid] = 0
    set warriorCount[pid] = 0
    set rangerCount[pid] = 0
    call SetPlayerTechResearched(p, 'R013', 1)
    call SetPlayerTechResearched(p, 'R014', 1)
    call SetPlayerTechResearched(p, 'R015', 1)
    call SetPlayerTechResearched(p, 'R016', 1)
    call SetPlayerTechResearched(p, 'R017', 1)
    call SetPlayerTechResearched(p, 'R018', 1)

    set sniperstance[pid] = false
    set udg_Hardcore[pid] = false
    set ArenaQueue[pid] = 0

    call Profiles[pid].hd.wipeData()
    set newcharacter[pid] = true
    call SetSaveSlot(pid) //repicking set you to an empty save slot
    
    set i = 1
    
	loop
		exitwhen i > 10
		call SaveBoolean(PlayerProf, pid, i, false)
		set i = i + 1
	endloop
    
    set tempplayer = p
	call EnumItemsInRectBJ( bj_mapInitialPlayableArea, function ItemRepickRemove )

    if autosave[pid] then
        set autosave[pid] = false
        call DisplayTextToPlayer(p, 0, 0, "|cffffcc00Autosave disabled.|r")
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
    set itm = null
endfunction

function CreateItemEx takes integer id, real x, real y, boolean expire returns item
    local timer t
    local item itm = CreateItem(id, x, y)

    if expire then
        call RemoveItemTimed(itm, 600)
        //call DEBUGMSG("Timer Start!")
    endif

    set t = null

    return itm
endfunction

function UnitDistance takes unit u1, unit u2 returns real
    local real dx= GetUnitX(u2)-GetUnitX(u1)
    local real dy= GetUnitY(u2)-GetUnitY(u1)

	return SquareRoot(dx*dx + dy*dy)
endfunction

function Distance takes location l1, location l2 returns real
    local real dx= GetLocationX(l2)-GetLocationX(l1)
    local real dy= GetLocationY(l2)-GetLocationY(l1)
    
	return SquareRoot(dx*dx + dy*dy)
endfunction

function DistanceCoords takes real x, real y, real x2, real y2 returns real
	return SquareRoot(Pow(x - x2, 2) + Pow(y - y2, 2))
endfunction

function RefundMana takes unit u returns nothing
	//call SetUnitState(u,UNIT_STATE_MANA,GetUnitState(u,UNIT_STATE_MANA) +BlzGetAbilityManaCost(GetSpellAbilityId(),GetUnitAbilityLevel(u,GetSpellAbilityId())) )
endfunction

function ExpireUnit takes unit u returns nothing
    call UnitApplyTimedLife(u, 'BTLF', 0.1)
endfunction

function UnitResetAbility takes unit u, integer abid returns nothing
    local integer i=GetUnitAbilityLevel(u,abid)
    
    call UnitRemoveAbility(u,abid)
    call UnitAddAbility(u,abid)
    call SetUnitAbilityLevel(u,abid,i)
endfunction

function OnDefeat takes integer pid returns nothing
    local User p     = User[Player(pid - 1)]
    local integer i  = User.PlayingPlayerIndex[pid - 1]

    // clean up
    call ForceRemovePlayer(FORCE_PLAYING, p.toPlayer())
    call RemoveUnit(hsdummy[p.id])

    call DialogDestroy(dChangeSkin[p.id])
    call DialogDestroy(dCosmetics[p.id])
    call DialogDestroy(heropanel[p.id])
    
    call MultiboardSetItemValueBJ(MULTI_BOARD, 1, udg_MultiBoardsSpot[p.id], p.name)
    call MultiboardSetItemColorBJ(MULTI_BOARD, 1, udg_MultiBoardsSpot[p.id], 60, 60, 60, 0)
    call MultiboardSetItemValueBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[p.id], "" )
    call MultiboardSetItemValueBJ(MULTI_BOARD, 3, udg_MultiBoardsSpot[p.id], "" )
    call MultiboardSetItemValueBJ(MULTI_BOARD, 4, udg_MultiBoardsSpot[p.id], "" )
    call MultiboardSetItemValueBJ(MULTI_BOARD, 5, udg_MultiBoardsSpot[p.id], "" )
    call MultiboardSetItemValueBJ(MULTI_BOARD, 6, udg_MultiBoardsSpot[p.id], "" )
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[p.id], false, false)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 3, udg_MultiBoardsSpot[p.id], false, false)

    call SharedRepick(p.toPlayer())

    // recycle index
    set User.AmountPlaying = User.AmountPlaying - 1
    set User.PlayingPlayerIndex[i] = User.PlayingPlayerIndex[User.AmountPlaying]
    set User.PlayingPlayer[i] = User.PlayingPlayer[User.AmountPlaying]
    
    if (User.AmountPlaying == 1) then
        set p.prev.next = User.NULL
        set p.next.prev = User.NULL
    else
        set p.prev.next = p.next
        set p.next.prev = p.prev
    endif

    set User.last = User.PlayingPlayer[User.AmountPlaying]
    
    set p.isPlaying = false
endfunction

function GetItemFromUnit takes unit u, integer itid returns item
    local integer i = 0
    local item itm

	loop
		exitwhen i > 5
		set itm = UnitItemInSlot(u, i)
		if itm != null and GetItemTypeId(itm) == itid then
            set itm = null
            return UnitItemInSlot(u, i)
		endif
		set i = i + 1
	endloop
    
    set itm = null
	return null
endfunction

function HasItemType takes unit u, integer itid returns boolean
	local integer i = 0
    local item itm
    
    loop
        exitwhen i > 5
        set itm = UnitItemInSlot(u, i)
        if (itm != null) and (GetItemTypeId(itm) == itid) then
            set itm = null
            return true
        endif
        set i = i + 1
    endloop
    
    set itm = null
    
    return false
endfunction

function RemoveEnemyVision takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    call UnitShareVision(Hero[pid], pboss, false)
    call UnitShareVision(Hero[pid], pfoe, false)
endfunction

function EnemyVisionAggro takes unit source, widget target, real amount, boolean attack, boolean ranged, attacktype attackType, damagetype damageType, weapontype weaponType returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(source)) + 1
    local unit utarget = W2U(target)
    
    if IsEnemy(GetPlayerId(GetOwningPlayer(utarget))) and source == Hero[pid] then
        call UnitShareVision(Hero[pid], GetOwningPlayer(utarget), true)
        call TimerStart(NewTimerEx(pid), 20., false, function RemoveEnemyVision)
    endif
    
    set utarget = null
endfunction

function GetResurrectionItem takes integer pid, boolean charge returns item
    local integer i
    local integer itid
    local item itm

    set i = 0
    loop
        exitwhen i > 5
        set itm = UnitItemInSlot(Hero[pid], i)
        if itm != null then 
            set itid = GetItemTypeId(itm)
            if ItemData[itid][StringHash("res")] > 0 then
                if charge and ItemData[itid][StringHash("recharge")] > 0 then
                    set itm = null
                    return UnitItemInSlot(Hero[pid], i)
                elseif not charge and GetItemCharges(itm) > 0 then
                    set itm = null
                    return UnitItemInSlot(Hero[pid], i)
                endif
            endif
        endif
        set i = i + 1
    endloop

    if charge then
        set i = 0
        loop
            exitwhen i > 5
            set itm = UnitItemInSlot(Backpack[pid], i)
            if itm != null then 
                set itid = GetItemTypeId(itm)
                if ItemData[itid][StringHash("res")] > 0 then 
                    if charge and ItemData[itid][StringHash("recharge")] > 0 then
                        set itm = null
                        return UnitItemInSlot(Backpack[pid], i)
                    elseif not charge and GetItemCharges(itm) > 0 then
                        set itm = null
                        return UnitItemInSlot(Backpack[pid], i)
                    endif
                endif
            endif
            set i = i + 1
        endloop
    endif
    
    set itm = null
	return null
endfunction

function MoveExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 0
    
    loop
        if i > 8 then
            set t = null
            return
        endif
        exitwhen t == bpmove[i]
        set i = i + 1
    endloop
    
    set bpmoving[i] = false
    call PauseTimer(t)
    
    set t = null
endfunction

function CompleteItem takes unit u,integer pieces,integer id0,integer id1,integer id2,integer id3,integer id4,integer id5,integer resultid returns nothing
    local integer array ids
    local integer ict1=0
    local integer ict2=0

	set ids[0]=id0
	set ids[1]=id1
	set ids[2]=id2
	set ids[3]=id3
	set ids[4]=id4
	set ids[5]=id5
	loop
		exitwhen ict1>pieces
		if HasItemType(u,ids[ict1]) then
		set ict2=ict2+1
		endif
		set ict1=ict1+1
	endloop
	if ict2==pieces then
	set ict1=0
	loop
	exitwhen ict1>pieces
	call RemoveItem(GetItemFromUnit(u,ids[ict1]))
	set ict1=ict1+1
	endloop
	call UnitAddItemById(u,resultid)
	endif
endfunction

function SelectGroupedRegion takes integer groupnumber returns rect
    local integer lowBound = groupnumber * REGION_GAP
    local integer highBound = lowBound

	loop
		exitwhen RegionCount[highBound] == null
		set highBound = highBound + 1
	endloop

	return RegionCount[GetRandomInt(lowBound, highBound - 1)]
endfunction

function MainSpawn takes nothing returns nothing
    local integer i = 0
    local integer i2 = 0
    local integer typeIndex = 0
    local rect myregion = null
    local real x
    local real y
    
    loop
        set typeIndex = UnitData[0][i]
        set i2 = 0
        exitwhen UnitData[0][i] == 0
		loop
			exitwhen i2 >= UnitData[typeIndex][StringHash("count")]
			set myregion = SelectGroupedRegion(UnitData[typeIndex][StringHash("spawn")])
            set x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
            set y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
            if IsTerrainWalkable(x, y) then
                call CreateUnit(pfoe, typeIndex, x, y, GetRandomInt(0, 359))
                set myregion = null
                set i2 = i2 + 1
            endif
		endloop

		set i = i + 1
    endloop
endfunction

function ChaosSpawn takes nothing returns nothing
    local integer typeIndex = 0
    local integer i = 0
    local integer i2 = 0
    local rect myregion = null
    local real x
    local real y

    loop
        set typeIndex = UnitData[1][i]
        set i2 = 0
        exitwhen UnitData[1][i] == 0
        loop
            exitwhen i2 >= UnitData[typeIndex][StringHash("count")]
            set myregion = SelectGroupedRegion(UnitData[typeIndex][StringHash("spawn")])
            set x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
            set y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
            if IsTerrainWalkable(x, y) then
                call CreateUnit(pfoe, typeIndex, x, y, GetRandomInt(0, 359))
                set myregion = null
                set i2 = i2 + 1
            endif
        endloop

		set i = i + 1
    endloop
endfunction

function ShowHeroPanel takes player p, player p2, boolean show returns nothing
    if show == true then
        call MultiboardDisplayBJ( false, MULTI_BOARD )
        call SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_ADVANCED_CONTROL, true, p )
        call SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_CONTROL, false, p )
        call MultiboardDisplayBJ( true, MULTI_BOARD )
    else
        call SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_ADVANCED_CONTROL, false, p )
    endif
endfunction

function CreateHeroItem takes unit Hero, integer pid, integer myitem, integer itemcharges returns nothing
    local item itm = CreateItem(myitem, GetUnitX(Hero), GetUnitY(Hero))
    
    if itemcharges > 1 then
        call SetItemCharges(itm, itemcharges)
    endif

    call SetItemUserData(itm, pid)
	call UnitAddItem(Hero, itm)

	set itm = null
endfunction

function StoreItems takes integer pid returns nothing
    local integer i = 0
    local integer i2 = 0
    local HeroData myHero = Profiles[pid].hd
    local integer index = Profiles[pid].pageIndex
    local item array itms

    loop
        exitwhen i > 5
        set itms[i] = UnitItemInSlot(Hero[pid], i)
        set itms[i + 6] = UnitItemInSlot(Backpack[pid], i)
        set i = i + 1
    endloop

    loop
        exitwhen i2 > 1

        set i = 0
        set index = index + 1

        if index > 2 then
            set index = 0
        endif

        loop
            exitwhen i > 5
            set itms[i + 12 + 6 * i2] = myHero.items[i + 6 + 6 * index]
            set i = i + 1
        endloop

        set i2 = i2 + 1
    endloop

    set i = 0

    loop
        exitwhen i > 23

        set myHero.items[i] = itms[i]
        set itms[i] = null

        set i = i + 1
    endloop

    set Profiles[pid].pageIndex = 0
endfunction

function IsBindItem takes integer id returns boolean
    return (id == 'I002' or id == 'I000' or id == 'I03L' or id == 'I0N2' or id == 'I0N1' or id == 'I0N3' or id == 'I0FN' or id == 'I086' or id == 'I001' or id == 'I068' or id == 'I05S' or id == 'I04Q')
endfunction

function BuyHome takes unit u, integer plat, integer arc, integer id returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    
    if udg_Plat_Gold[pid] < plat or udg_Arca_Wood[pid] < arc then
		call DisplayTimedTextToPlayer( GetOwningPlayer(u),0,0, 10, "You do not have enough resources to buy this." )
	else
		call CreateHeroItem(u, pid, id, 1)
        call AddPlatinumCoin(pid, -plat)
        call AddArcaditeLumber(pid, -arc)
		call DisplayTimedTextToPlayer( GetOwningPlayer(u),0,0, 20, "You have purchased a "+GetObjectName(id)+"." )
		call DisplayTimedTextToPlayer( GetOwningPlayer(u),0,0, 10, PlatTag + I2S(udg_Plat_Gold[pid]) )
		call DisplayTimedTextToPlayer( GetOwningPlayer(u),0,0, 10, ArcTag + I2S(udg_Arca_Wood[pid]) )
	endif
endfunction

function GetItemSlot takes item itm, unit u returns integer
    local integer i = 0

    loop
        exitwhen i > 5
        if UnitItemInSlot(u, i) == itm then
            return i
        endif
        set i = i + 1
    endloop

    return i
endfunction

function IsItemBound takes item itm, integer pid returns boolean
    local integer origid = GetItemUserData(itm)

    if origid != pid and origid != 0 and origid != 42 then
        return true
    endif

    return false
endfunction

function IsItemSaved takes item itm returns boolean
    local integer itemid = GetItemTypeId(itm)
    local integer tableid = LoadInteger(SAVE_TABLE, KEY_ITEMS, itemid)

    if itemid == udg_SaveItemType[tableid] then
        return true
    elseif itemid == 'iDud' and ItemData[GetHandleId(itm)][0] == udg_SaveItemType[tableid] then
        return true
    endif

    return false
endfunction

function IsItemRestricted takes item itm, unit u returns boolean
    local integer itemid = GetItemTypeId(itm)
    local integer i = 0
    local integer i2 = 0
    local integer i3 = 0
    local item itm2
    local boolean exact = false

    set RESTRICTED_ERROR = 0

    loop
		exitwhen RESTRICTED_ERROR > RESTRICTED_ITEMS_MAX

        if RESTRICTED_ERROR == RESTRICTED_ITEMS_MAX then
            set exact = true
        endif

        loop
            exitwhen i > 5
            set itm2 = UnitItemInSlot(u, i)
            if itm2 != itm and itm2 != null then
                loop
                    exitwhen RestrictedItems[RESTRICTED_ERROR][i2] == 0
                    if itemid == RestrictedItems[RESTRICTED_ERROR][i2] then
                        if itemid == GetItemTypeId(itm2) then
                            return true
                        else
                            set i3 = 0
                            loop
                                exitwhen RestrictedItems[RESTRICTED_ERROR][i3] == 0
                                if exact == false and GetItemTypeId(itm2) == RestrictedItems[RESTRICTED_ERROR][i3] then
                                    return true
                                elseif exact and GetItemTypeId(itm2) == RestrictedItems[RESTRICTED_ERROR][i3] and itemid == GetItemTypeId(itm2) then
                                    return true
                                endif
                                set i3 = i3 + 1
                            endloop
                            //exitwhen true
                        endif
                    endif
                    set i2 = i2 + 1
                endloop
            endif

            set i = i + 1
            set i2 = 0
        endloop

        set i = 0
        set RESTRICTED_ERROR = RESTRICTED_ERROR + 1
	endloop

    set itm2 = null
    return false
endfunction

function IsItemDud takes item itm returns boolean
    return GetItemTypeId(itm) == 'iDud'
endfunction

function BindItem takes item itm, integer pid returns nothing
    if itm == null then
        return
    endif

    if IsItemDud(itm) then
        set ItemData[GetHandleId(itm)][1] = pid
    endif

    call SetItemUserData(itm, pid)
endfunction

function ItemToDud takes item itm, unit u returns item
    local integer id = GetItemTypeId(itm)
    local string s = BlzGetItemIconPath(itm)
    local string name = GetItemName(itm) + "\n|cffFF0000Requires level " + I2S(ItemData[id][StringHash("level")]) + " to use!|r"
    local item dud = CreateItem('iDud', 0, 0)

    //set s = SubString(s, 0, 34) + "Disabled\\DIS" + SubString(s, 35, StringLength(s))

    set ItemData[GetHandleId(dud)][0] = id
    set ItemData[GetHandleId(dud)][1] = GetItemUserData(itm)
    set ItemData[GetHandleId(dud)][2] = GetItemCharges(itm)

    call BindItem(dud, GetItemUserData(itm))

    //call BlzSetItemExtendedTooltip(dud, BlzGetItemExtendedTooltip(itm))

    call UnitRemoveItem(u, itm)
    call RemoveItem(itm)
    call UnitAddItem(u, dud)

    call BlzSetItemIconPath(dud, name)

    return dud
endfunction

function DudToItem takes item dud, unit u, real x, real y returns item
    local integer id = ItemData[GetHandleId(dud)][0]
    local integer pid = ItemData[GetHandleId(dud)][1]
    local integer charges = ItemData[GetHandleId(dud)][2]
    local integer slot = GetItemSlot(dud, u)
    local item itm = CreateItem(id, x, y)

    call ItemData.remove(GetHandleId(dud))

    call BindItem(itm, pid)
    call SetItemCharges(itm, charges)

    if u != null then
        call UnitRemoveItem(u, dud)
        call RemoveItem(dud)
        call UnitAddItem(u, itm)
        call UnitDropItemSlot(u, itm, slot)
    endif

    return itm
endfunction

function CostAdjust takes integer cost, real divisor returns integer
	set cost = R2I(cost / divisor)

	return cost
endfunction

function IndexWells takes integer index returns nothing
    loop
        exitwhen index > wellcount
        set well[index] = well[index + 1]
        set wellheal[index] = wellheal[index + 1]
        set index = index + 1
    endloop
    
    set wellcount = wellcount - 1
endfunction

function RequiredXP takes integer level returns integer
    local integer base = 150
    local integer i = 2
    local integer levelFactor = 100

    loop
        exitwhen i > level
        set i = i + 1
        set base = base + i * levelFactor
    endloop

    return base
endfunction

function HMscale takes real dmg returns integer
    if HardMode > 0 then
        return R2I(dmg * 2)
    endif

    return R2I(dmg)
endfunction

function pheal takes unit u, real hp, real mp returns nothing
local integer pid= GetPlayerId(GetOwningPlayer(u)) +1
	call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u, UNIT_STATE_LIFE) + hp * BlzGetUnitMaxHP(u) )
	call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MANA) + mp * BlzGetUnitMaxHP(u) )
endfunction

function CheckShields takes unit u returns integer
    local integer index = 0
    local integer shieldcount = 0

	loop
		exitwhen index>udg_PermanentInteger[11]
		if HasItemType(u, udg_ShieldType[index]) then
			set shieldcount = shieldcount +1
		endif
		set index = index + 1
	endloop
	if shieldcount > 1 then
		set shieldcount = 2
	endif
    
	return shieldcount
endfunction

function BOOST takes integer pid returns real
    if BOOST_OFF then
        return (1. + BoostValue[pid])
    endif
	return (1. + BoostValue[pid]) * GetRandomReal(0.8, 1.2)
endfunction

function LBOOST takes integer pid returns real
	return 1. + 0.5 * BoostValue[pid]
endfunction

function Spellhit takes unit u returns real
	return SpellTaken[GetPlayerId(GetOwningPlayer(u))+1]
endfunction

function CrystalExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 0
    local integer i2 = GetTimerData(t)
    local integer time = LoadInteger(MiscHash, i2 + 1, GetHandleId(t))
    local item itm
    
    call SaveInteger(MiscHash, i2 + 1, GetHandleId(t), time - 5)
    
    loop
        exitwhen i > i2
        set itm = LoadItemHandle(MiscHash, i, GetHandleId(t))
        if GetItemX(itm) != 0 and time - 5 <= 15 then
            call PingMinimap(GetItemX(itm), GetItemY(itm), 1)
            if time - 5 == 5 then
                call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\TomeOfRetraining\\TomeOfRetrainingCaster.mdl", GetItemX(itm), GetItemY(itm)))
            endif
        endif
        if time - 5 <= 0 then
            call RemoveItem(itm)
            call RemoveSavedHandle(MiscHash, i, GetHandleId(t))
        endif
        set i = i + 1
    endloop
    
    if time - 5 <= 0 then
        call RemoveSavedInteger(MiscHash, i2 + 1, GetHandleId(t))
        call ReleaseTimer(t)
    endif
    
    set t = null
    set itm = null
endfunction

function MakeCrystals takes integer count, integer hm, real x, real y returns nothing
    local integer i = 0
    local timer t = NewTimer()

	if hm > 0 then
		set count = count * 2
	endif

	loop
        exitwhen count <= 0
        if R2I(count / 5.) > 0 then
			call SaveItemHandle(MiscHash, i, GetHandleId(t), CreateItem('I0OG', x,y))
            set count = count - 5
            set i = i + 1
        endif

		if count > 0 then
			call SaveItemHandle(MiscHash, i, GetHandleId(t), CreateItem('I0CC', x,y))
			set count = count - 1
            set i = i + 1
		endif
	endloop
	
    call SetTimerData(t, i)
    call SaveInteger(MiscHash, i + 1, GetHandleId(t), 30)
    call TimerStart(t, 5.00, true, function CrystalExpire)
    
    set t = null
endfunction

function BossDrop takes BossItemList il, integer rolls, integer dp, real x, real y returns nothing
    local integer i = 0
    local item itm

    loop
        exitwhen i >= rolls
        if GetRandomInt(0, 99) < dp then
            set itm = CreateItemEx(il.pickItem(), x, y, true)
            call SetItemUserData(itm, 42)
        endif
        set i = i + 1
    endloop

    set itm = null
    call il.destroy()
endfunction

function GetHeroStat takes integer stat, unit u, boolean bonuses returns integer
    if (stat == 1) then
        return GetHeroStr(u, bonuses)
    elseif (stat == 2) then
        return GetHeroInt(u, bonuses)
    elseif (stat == 3) then
        return GetHeroAgi(u, bonuses)
    else
        // Unrecognized hero stat - return 0
        return 0
    endif
endfunction

function LineContainsBox takes real x, real y, real x2, real y2, real MinX, real MinY, real MaxX, real MaxY, real rate returns boolean
    local integer i = 0
    local real dist = SquareRoot(Pow(x2 - x, 2) + Pow(y2 - y, 2))
    local real angle = Atan2(y2 - y, x2 - x)
    local real X
    local real Y
    
    loop
        set i = i + R2I(dist * rate)
        set X = x + i * Cos(angle)
        set Y = y + i * Sin(angle)
        if MinX <= X and X <= MaxX and MinY <= Y and Y <= MaxY then
            return true
        endif
        exitwhen i >= dist
    endloop
    
    return false
endfunction

function Stand takes nothing returns nothing
    call SetUnitAnimation(Hero[ReleaseTimer(GetExpiredTimer())], "stand")
endfunction

function AllocateStatPoints takes player p, integer points returns nothing
    local integer pid = GetPlayerId(p) + 1

    set statpoints[pid] = statpoints[pid] + points
endfunction

function InCombat takes unit u returns boolean
    local group ug = CreateGroup()
    local unit u2
    local boolean b = false

    call GroupEnumUnitsInRange(ug, GetUnitX(u), GetUnitY(u), 900., Condition(function ishostile))
    
    set u2 = FirstOfGroup(ug)
    
    if GetUnitTypeId(u2) != 0 then
        set b = true
    endif

    call DestroyGroup(ug)
    
    set ug = null
    set u2 = null

    return b
endfunction

function SpawnOrcs takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local group ug = CreateGroup()
    
    call GroupEnumUnitsOfPlayer(ug, pboss, Filter(function isOrc))

    if IsQuestCompleted(udg_Defeat_The_Horde_Quest) == true then
        call ReleaseTimer(t)
    elseif BlzGroupGetSize(ug) > 0 and BlzGroupGetSize(ug) < 36 and not udg_Chaos_World_On then
        //bottom side
        call IssuePointOrder(CreateUnit(pboss, 'o01I', 12687, -15414, 45), "patrol", 668, -2146)
        call IssuePointOrder(CreateUnit(pboss, 'o01I', 12866, -15589, 45), "patrol", 668, -2146)
        call IssuePointOrder(CreateUnit(pboss, 'o008', 12539, -15589, 45), "patrol", 668, -2146)
        call IssuePointOrder(CreateUnit(pboss, 'o008', 12744, -15765, 45), "patrol", 668, -2146)
        //top side
        call IssuePointOrder(CreateUnit(pboss, 'o01I', 15048, -12603, 225), "patrol", 668, -2146)
        call IssuePointOrder(CreateUnit(pboss, 'o01I', 15307, -12843, 225), "patrol", 668, -2146)
        call IssuePointOrder(CreateUnit(pboss, 'o008', 15299, -12355, 225), "patrol", 668, -2146)
        call IssuePointOrder(CreateUnit(pboss, 'o008', 15543, -12630, 225), "patrol", 668, -2146)
        
        if GetWidgetLife(gg_unit_N01N_0050) >= 0.406 then
            call UnitAddAbility(gg_unit_N01N_0050, 'Avul')
        endif
    endif

    call DestroyGroup(ug)
    
    set ug = null
    set t = null
endfunction

function SpawnForgotten takes nothing returns nothing
    local integer id = forgottenTypes[GetRandomInt(0, 4)]
    
    if GetWidgetLife(forgottenSpawner) >= 0.406 and forgottenCount < 5 then
        set forgottenCount = forgottenCount + 1
        call CreateUnit(pboss, id, 13699 + GetRandomInt(-250, 250), -14393 + GetRandomInt(-250, 250), GetRandomInt(0, 359))
    endif
endfunction

//pre-assigned tree id's only, used for OG and DS tree-killing abilities
function DestroyTreesInRange_Enum takes nothing returns nothing 
local destructable Tree = GetEnumDestructable()
	if (GetDestructableTypeId(Tree)=='ITtw' or GetDestructableTypeId(Tree)=='B00B' or GetDestructableTypeId(Tree)=='ITtc' or GetDestructableTypeId(Tree)=='NTtc' or GetDestructableTypeId(Tree)=='WTst' ) and Pow(bj_cineFadeContinueRed-GetDestructableX(Tree),2)+Pow(bj_cineFadeContinueGreen-GetDestructableY(Tree),2) <= bj_enumDestructableRadius then
		call KillDestructable(Tree)
	endif
	set Tree = null
endfunction

function DestroyTreesInRange takes real X, real Y, real Range returns nothing
	call SetRect(TempRect, X-Range,Y-Range,X+Range,Y+Range)
	set bj_cineFadeContinueRed = X
	set bj_cineFadeContinueGreen = Y
	set bj_enumDestructableRadius = Range*Range
	call EnumDestructablesInRect(TempRect, null, function DestroyTreesInRange_Enum)
endfunction

function GetDummy takes real x, real y, integer abil, integer ablev, real dur returns unit
    if BlzGroupGetSize(DUMMY_STACK) > 0 then
        set TEMP_DUMMY = BlzGroupUnitAt(DUMMY_STACK, 0) 
        call GroupRemoveUnit(DUMMY_STACK, TEMP_DUMMY)
        call PauseUnit(TEMP_DUMMY, false)
    else
        set DUMMY_LIST[DUMMY_COUNT] = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY, x, y, 0)
        set TEMP_DUMMY = DUMMY_LIST[DUMMY_COUNT]
        set DUMMY_COUNT = DUMMY_COUNT + 1
        call UnitAddAbility(TEMP_DUMMY, 'Amrf')
        call UnitRemoveAbility(TEMP_DUMMY, 'Amrf')
        call UnitAddAbility(TEMP_DUMMY, 'Aloc')
        call SetUnitPathing(TEMP_DUMMY, false)
    endif

    if UnitAddAbility(TEMP_DUMMY, abil) then
        call SetUnitAbilityLevel(TEMP_DUMMY, abil, ablev)
        call SaveInteger(MiscHash, GetHandleId(TEMP_DUMMY), 'dspl', abil)
    endif

    if dur > 0 then
        call RemoveUnitTimed(TEMP_DUMMY, dur)
    endif

    call SetUnitXBounded(TEMP_DUMMY, x)
    call SetUnitYBounded(TEMP_DUMMY, y)

    return TEMP_DUMMY
endfunction

function DummyCast takes player owner, integer abil, integer ablev, real x, real y, string order returns nothing
    local unit u = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME)

    call SetUnitOwner(u, owner, true)
    call IssueImmediateOrder(u, order)

    set u = null
endfunction

function DummyCastTarget takes player owner, unit target, integer abil, integer ablev, real x, real y, string order returns nothing
    local unit u = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME)

    call SetUnitOwner(u, owner, true)
    call BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(GetUnitY(target) - y, GetUnitX(target) - x))
    call IssueTargetOrder(u, order, target)

    set u = null
endfunction

function DummyCastPoint takes player owner, real x2, real y2, integer abil, integer ablev, real x, real y, string order returns nothing
    local unit u = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME)

    call SetUnitOwner(u, owner, true)
    call BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(y2 - y, x2 - x))
    call IssuePointOrder(u, order, x2, y2)

    set u = null
endfunction

function StunUnit takes integer pid, unit target, real duration returns nothing
    local Stun stun
    set stun = Stun.add(Hero[pid], target)

    if IsUnitType(target, UNIT_TYPE_HERO) then
        set stun.duration = duration / 2.
    else
        set stun.duration = duration
    endif
endfunction

//takes real, returns as if integer, but with commas for ease of reading
function RealToString takes real stattoconvert returns string
    local string statdisplay= I2S(R2I(stattoconvert))
    local integer length= StringLength(statdisplay)
    
	if length>9 then
		set statdisplay=SubString(statdisplay, 0, length-9)+","+SubString(statdisplay, length-9, length-6)+","+SubString(statdisplay, length-6, length-3)+","+SubString(statdisplay, length-3, length)
	elseif length>6 then
		set statdisplay=SubString(statdisplay, 0, length-6)+","+SubString(statdisplay, length-6, length-3)+","+SubString(statdisplay, length-3, length-0)
	elseif length>3 then
		set statdisplay=SubString(statdisplay, 0, length-3)+","+SubString(statdisplay, length-3, length-0)
	endif
	
	return statdisplay
endfunction

function IndexShields takes integer index returns nothing
    //call SetUnitPosition(shieldunit[index], 30000, -30000)
    //call SetUnitTimeScale(shieldunit[index], -99)

    call SetUnitScale(shieldunit[index], 0., 0., 0.)
    call SetUnitTimeScale(shieldunit[index], -99)
        
    loop
        exitwhen index > shieldindexmax
        set shieldunit[index] = shieldunit[index + 1]
        set shieldtarget[index] = shieldtarget[index + 1]
        set shieldpercent[index] = shieldpercent[index + 1]
        set shieldhp[index] = shieldhp[index + 1]
        set shieldmax[index] = shieldmax[index + 1]
        set isShielded[index] = isShielded[index + 1]
        set index = index + 1
    endloop
        
    set shieldindexmax = shieldindexmax - 1
endfunction

function ShieldExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit u = LoadUnitHandle(MiscHash, 0, GetHandleId(t))
    local real amount = LoadReal(MiscHash, 1,  GetHandleId(t))
    local integer i = 0
    
    loop
        exitwhen u == shieldunit[i] or i > 500
        set i = i + 1
    endloop
    
    if i < 500 then
        set shieldhp[i] = shieldhp[i] - amount
        set shieldmax[i] = shieldmax[i] - amount
        
        if shieldmax[i] <= 0 then
            call IndexShields(i)
        endif
    endif
    
    call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
    call RemoveSavedReal(MiscHash, 1, GetHandleId(t))
    
    call ReleaseTimer(t)
    
    set u = null
    set t = null
endfunction

function kgold takes real gold returns string
    local integer g = R2I(gold)

	if gold > 10000 then
		return "+" + I2S(R2I(g* 0.001)) + "K"
	else
		return "+" + I2S(g)
	endif
endfunction

function isXpGoldGiver takes unit u returns boolean
local integer pid= GetPlayerId(GetOwningPlayer(u))
	if IsUnitType(u,UNIT_TYPE_SUMMONED) then
		return false
	elseif IsUnitIllusion(u) then
		return false
	elseif pid==10 or pid==11 or pid==foe then
		return true
	endif
	return false
endfunction

function AzazothExit takes nothing returns nothing
    local unit target
    local integer i = 0
    
    call ReleaseTimer(GetExpiredTimer())

    loop
        set target = FirstOfGroup(AzazothPlayers)
        exitwhen target == null
        set i = GetPlayerId(GetOwningPlayer(target)) + 1
        call GroupRemoveUnit(AzazothPlayers, target)
        call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(target), gg_rct_Main_Map_Vision)
        call PanCameraToTimedLocForPlayer(GetOwningPlayer(target), TownCenter, 0)
        
        if GetWidgetLife(target) >= 0.406 then
            call SetUnitPositionLoc(target, TownCenter)
        elseif IsUnitHidden(HeroGrave[i]) == false then
            call SetUnitPositionLoc(HeroGrave[i], TownCenter)
        endif
    endloop
    
    set FightingAzazoth = false
    set target = null
endfunction

function IsCreep takes unit u returns boolean
    if GetOwningPlayer(u) != pfoe then
        return false
    elseif RectContainsUnit(gg_rct_Town_Boundry, u) then
        return false
    elseif RectContainsUnit(gg_rct_Gods_Vision, u) then
        return false
    elseif IsUnitType(u, UNIT_TYPE_MECHANICAL) == true then
        return false
    elseif IsUnitType(u, UNIT_TYPE_HERO) == true then
        return false
    endif
    return true
endfunction

function Shield takes unit u, real amount, real dur returns nothing
    local timer t = NewTimer()
    local integer i = 0
    
    loop
        exitwhen u == shieldtarget[i] or i > 100
        set i = i + 1
    endloop
    
    if u != shieldtarget[i] then
        set shieldindexmax = shieldindexmax + 1
        set i = shieldindexmax
    endif

    if shieldunit[i] == null then
        set shieldunit[i] = GetDummy(GetUnitX(u), GetUnitY(u), 0, 0, 0) 
        call BlzSetUnitSkin(shieldunit[i], 'h00H')
        call SetUnitScale(shieldunit[i], 1.05, 1.05, 1.05)
        call SetUnitColor(shieldunit[i], GetPlayerColor(Player(2)))
        call SetUnitFlyHeight(shieldunit[i], 250.00, 0)
        call PauseUnit(shieldunit[i], true)
    endif
    
    set shieldtarget[i] = u

    if isShielded[i] == false then
        set shieldpercent[i] = 0
        set shieldhp[i] = amount
        set shieldmax[i] = amount
        set isShielded[i] = true
        call SetUnitAnimation(shieldunit[i], "birth")
        call SetUnitScale(shieldunit[i], 1., 1., 1.)
    else
        set shieldhp[i] = shieldhp[i] + amount
        set shieldmax[i] = shieldmax[i] + amount
    endif

    call SaveUnitHandle(MiscHash, 0, GetHandleId(t), shieldunit[i])
    call SaveReal(MiscHash, 1, GetHandleId(t), amount)
    call TimerStart(t, dur, false, function ShieldExpire)
    
    set t = null
endfunction

function getRect takes real x, real y returns rect
    local integer i = 0
    
    loop
        exitwhen AREAS[i] == null
        if GetRectMinX(AREAS[i]) <= x and x <= GetRectMaxX(AREAS[i]) and GetRectMinY(AREAS[i]) <= y and y <= GetRectMaxY(AREAS[i]) then
            return AREAS[i]
        endif
        set i = i + 1
    endloop
    
    return null
endfunction

function ExperienceControl takes integer pid returns nothing
    local integer HeroLevel = GetHeroLevel(Hero[pid])
    local real xpRate = 0
    
    //1 nation, 2 home, 3 grand home, 4 grand nation, 5 abode, 6 chaotic home, 7 chaotic nation
    
	if urhome[pid] == 0 then
		if HeroLevel < 40 then
			set xpRate = 150
		else
			set xpRate = 0
		endif
    else
        if ( HeroLevel < 20 ) then
			set xpRate=400
		elseif ( HeroLevel < 40 ) then
			set xpRate=300
		elseif ( HeroLevel < 60 ) then
			set xpRate=200
		elseif ( HeroLevel < 80 ) then
			set xpRate=160
		elseif ( HeroLevel < 100 ) then
			set xpRate=120
		elseif ( HeroLevel < 120 ) then
			set xpRate=100
		elseif ( HeroLevel < 140 ) then
			set xpRate=80
		elseif ( HeroLevel < 160 ) then
			set xpRate=60
		elseif ( HeroLevel < 180 ) then
			set xpRate=30
        elseif ( HeroLevel < 200 ) then
			set xpRate=10
        elseif ( HeroLevel > 200 ) then
			set xpRate=0
		endif
    endif

	if urhome[pid]==1 then
		set xpRate=xpRate * .6
	elseif urhome[pid]==2 then
        set xpRate=xpRate * .8
	elseif urhome[pid]==3 then
        set xpRate = xpRate * 1.1
    elseif urhome[pid]==4 then
		set xpRate = xpRate * .9
	elseif urhome[pid]>4 then
		if ( HeroLevel < 200 ) then
			set xpRate=25
		elseif ( HeroLevel < 220 ) then
			set xpRate=15
		elseif ( HeroLevel < 240 ) then
			set xpRate=10
		elseif ( HeroLevel < 260 ) then
			set xpRate=7
		elseif ( HeroLevel < 280 ) then
			set xpRate=4.5
		elseif ( HeroLevel < 300 ) then
			set xpRate=3
		elseif ( HeroLevel < 320 ) then
			set xpRate=2
		elseif ( HeroLevel < 340 ) then
			set xpRate=1.35
		elseif ( HeroLevel < 360 ) then
			set xpRate=0.7
		elseif ( HeroLevel < 380 ) then
			set xpRate=0.33
		elseif ( HeroLevel < 400 ) then
			set xpRate=0.15
		else
			set xpRate=0
		endif
		if urhome[pid] == 6 then
			set xpRate = xpRate * 1.7
		elseif urhome[pid] == 7 then
			set xpRate = xpRate * 1.4
		endif
	endif
	
	if InColo[pid] then
		set xpRate = xpRate * udg_Colloseum_XP[pid] * (0.6 + 0.4 * ColoPlayerCount)
	elseif InStruggle[pid] then
		set xpRate = xpRate * .3
	endif

	set udg_XP_Rate[pid] = RMaxBJ(0, xpRate * ( 1. + 0.04 * LoadInteger(PrestigeRank, pid, 0) ) - warriorCount[pid] - rangerCount[pid])
endfunction

function Plat_Effect takes player Owner returns nothing
local integer i=0
local real x=GetUnitX(Hero[GetConvertedPlayerId(Owner)])
local real y=GetUnitY(Hero[GetConvertedPlayerId(Owner)])
	loop
		exitwhen i>40
		call DestroyEffect( AddSpecialEffect( "Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl" ,x+GetRandomInt(-200,200) ,y+GetRandomInt(-200,200) ) )
		set i=i+1
	endloop
endfunction

//gives player gold, factors in prestige bonus, and automatically converts into Plat as needed
function AwardGold takes player p, real goldawarded, boolean displaymessage returns integer
    local integer pid = GetPlayerId(p) + 1
    local integer goldWon
    local integer platWon
    local integer intReturn

    set goldWon = R2I(goldawarded * GetRandomReal(0.9,1.1))
    set goldWon = R2I(goldWon * (1 + ((ItemGoldRate[pid] + Gld_mod[pid]) * 0.01)))
    set intReturn = goldWon

    set platWon = R2I(goldWon / 1000000.)
	set goldWon = goldWon - platWon * 1000000
	
	if udg_PlatConverter[pid] and goldWon + GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)>1000000 then
        call AddPlatinumCoin(pid, platWon + 1)
		call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD) +goldWon -1000000)
		call Plat_Effect(p)
	else
        call AddPlatinumCoin(pid, platWon)
		call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD) + goldWon)
	endif
	
	if displaymessage then
		if platWon > 0 then
			call DisplayTimedTextToPlayer( p,0,0, 10, "|c00ebeb15You have gained " +I2S(goldWon) +" gold and " +I2S(platWon) +" platinum coins." )
			call DisplayTimedTextToPlayer(p, 0, 0, 10, PlatTag + I2S(udg_Plat_Gold[pid]) )
		else
			call DisplayTimedTextToPlayer( p,0,0, 10, "|c00ebeb15You have gained " +I2S(goldWon) +" gold." )
		endif
	endif

    return intReturn
endfunction

function HasPlayerLumber takes integer pid, integer lumberCost, integer arcCost returns boolean
    local integer playerLumber = GetPlayerLumber(Player(pid - 1))

    return playerLumber >= lumberCost and udg_Arca_Wood[pid] >= arcCost
endfunction

function HasPlayerGold takes integer pid, integer goldCost, integer platCost returns boolean
    local integer playerGold = GetPlayerGold(Player(pid - 1))

    return playerGold >= goldCost and udg_Plat_Gold[pid] >= platCost 
endfunction

function ChargePlayerGold takes integer pid, integer goldCost, integer platCost returns nothing
    local integer playerGold = GetPlayerGold(Player(pid - 1))
    local integer adjustGoldCost = IMinBJ(goldCost, playerGold) //cant go negative
    local integer adjustPlatCost = IMinBJ(platCost, udg_Plat_Gold[pid])
    local integer platCharge = R2I(adjustGoldCost / 1000000.) + adjustPlatCost
    local integer goldCharge = ModuloInteger(adjustGoldCost, 1000000)

    if udg_Plat_Gold[pid] < platCharge then
        loop
            exitwhen udg_Plat_Gold[pid] >= platCharge
            set playerGold = playerGold - 1000000
            call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_GOLD, playerGold)
            set udg_Plat_Gold[pid] = udg_Plat_Gold[pid] + 1
        endloop
    endif

    if playerGold < goldCharge then //convert a plat to gold
        set goldCharge = goldCharge - 1000000
        call AddPlatinumCoin(pid, -1)
    endif

    call AddPlatinumCoin(pid, -(platCharge))
	call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_GOLD, playerGold - goldCharge)
endfunction

function ChargePlayerLumber takes integer pid, integer lumberCost, integer arcCost returns nothing
    local integer playerLumber = GetPlayerLumber(Player(pid - 1))
    local integer adjustLumberCost = IMinBJ(lumberCost, playerLumber) //cant go negative
    local integer adjustArcCost = IMinBJ(arcCost, udg_Arca_Wood[pid])
    local integer arcCharge = R2I(adjustLumberCost / 1000000.) + adjustArcCost
    local integer lumberCharge = ModuloInteger(adjustLumberCost, 1000000)

    if udg_Arca_Wood[pid] < arcCharge then
        loop
            exitwhen udg_Arca_Wood[pid] >= arcCharge
            set playerLumber = playerLumber - 1000000
            call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_LUMBER, playerLumber)
            set udg_Arca_Wood[pid] = udg_Arca_Wood[pid] + 1
        endloop
    endif

    if playerLumber < lumberCharge then //convert a plat to gold
        set lumberCharge = lumberCharge - 1000000
        call AddArcaditeLumber(pid, -1)
    endif

    call AddArcaditeLumber(pid, -(arcCharge))
	call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_LUMBER, playerLumber - lumberCharge)
endfunction

function convert255 takes real percentage returns integer
local integer result = R2I(percentage * 2.55)
	if (result < 0) then
		set result = 0
	elseif (result > 255) then
		set result = 255
	endif
	return result
endfunction

function DoFloatingTextUnit takes string s, unit u, real dur,real speed,real zOffset,real size, integer red, integer green, integer blue, integer transparency returns nothing
    set bj_lastCreatedTextTag = CreateTextTag()

	call SetTextTagText(bj_lastCreatedTextTag,s,size*0.0023)
	call SetTextTagPos(bj_lastCreatedTextTag,GetUnitX(u),GetUnitY(u),zOffset)
	call SetTextTagColor(bj_lastCreatedTextTag, red, green, blue, 255 - transparency)
	call SetTextTagPermanent(bj_lastCreatedTextTag,false)
	call SetTextTagVelocity(bj_lastCreatedTextTag,0,speed / 1803.)
	call SetTextTagLifespan(bj_lastCreatedTextTag,dur)
	call SetTextTagFadepoint(bj_lastCreatedTextTag,dur-.4)
endfunction

function DoFloatingTextCoords takes string s, real x, real y, real dur,real speed,real zOffset,real size,real red,real green,real blue,real transparency returns nothing
    set bj_lastCreatedTextTag = CreateTextTag()

	call SetTextTagText(bj_lastCreatedTextTag,s,size*0.0023)
	call SetTextTagPos(bj_lastCreatedTextTag, x, y, zOffset)
	call SetTextTagColor(bj_lastCreatedTextTag,convert255(red),convert255(green),convert255(blue),convert255(100.0-transparency))
	call SetTextTagPermanent(bj_lastCreatedTextTag,false)
	call SetTextTagVelocity(bj_lastCreatedTextTag,0,speed / 1803.)
	call SetTextTagLifespan(bj_lastCreatedTextTag,dur)
	call SetTextTagFadepoint(bj_lastCreatedTextTag,dur-.4)
endfunction

function HP takes unit u, real hp returns nothing
local integer pid= GetPlayerId(GetOwningPlayer(u)) +1
	call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u,UNIT_STATE_LIFE) + hp )
    call DoFloatingTextUnit( RealToString(hp), u,2,50,0,10,125,255,125,0)
endfunction

function MP takes unit u, real hp returns nothing
local integer pid= GetPlayerId(GetOwningPlayer(u)) +1
	call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u,UNIT_STATE_MANA) + hp )
    call DoFloatingTextUnit(RealToString(hp) , u , 1 , 60 , 0 , 10 , 0, 255, 255 , 0)
endfunction

function PaladinEnrage takes boolean b returns nothing
    local group ug = CreateGroup()
    local unit target
    
    if b then
        call GroupEnumUnitsInRange(ug, GetUnitX(gg_unit_H01T_0259), GetUnitY(gg_unit_H01T_0259), 250., Condition(function isplayerunit))
        
        loop
            set target = FirstOfGroup(ug)
            exitwhen target == null
            call GroupRemoveUnit(ug, target)
            call UnitDamageTarget(gg_unit_H01T_0259, target, 20000., true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
        endloop
        
        if GetUnitAbilityLevel(gg_unit_H01T_0259, 'Bblo') == 0 then
            call DummyCastTarget(GetOwningPlayer(gg_unit_H01T_0259), gg_unit_H01T_0259, 'A041', 1, GetUnitX(gg_unit_H01T_0259), GetUnitY(gg_unit_H01T_0259), "bloodlust")
        endif

        call BlzSetHeroProperName(gg_unit_H01T_0259, "|cff990000BUZAN THE FEARLESS|r")
        call UnitAddBonus(gg_unit_H01T_0259, BONUS_DAMAGE, 5000)
        set pallyENRAGE = true
    else
        call UnitRemoveAbility(gg_unit_H01T_0259, 'Bblo')
        call BlzSetHeroProperName(gg_unit_H01T_0259, "|c00F8A48BBuzan the Fearless|r")
        call UnitAddBonus(gg_unit_H01T_0259, BONUS_DAMAGE, -5000)
        set pallyENRAGE = false
    endif
        
    call DestroyGroup(ug)
    
    set ug = null
    set target = null
endfunction

function ApplyFade takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer amount = GetTimerData(t)
    local unit u = LoadUnitHandle(MiscHash, 0, GetHandleId(t))
    local integer direction = LoadInteger(MiscHash, 1, GetHandleId(t))
    local integer r = BlzGetUnitIntegerField(u, UNIT_IF_TINTING_COLOR_RED)
    local integer g = BlzGetUnitIntegerField(u, UNIT_IF_TINTING_COLOR_BLUE)
    local integer b = BlzGetUnitIntegerField(u, UNIT_IF_TINTING_COLOR_GREEN)

    if GetUnitAbilityLevel(u, 'A05W') > 0 then //magnetic stance
        set r = 255
        set g = 25
        set b = 25
    endif
    
    call SetTimerData(t, amount - 1)
    
    if amount <= 0 then
        call RemoveSavedInteger(MiscHash, 1, GetHandleId(t))
        call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
        call ReleaseTimer(t)
    else
        if GetWidgetLife(u) >= 0.406 then
            if direction > 0 then //1 hide, -1 show
                call SetUnitVertexColor(u, r, g, b, amount * 7)
            else
                call SetUnitVertexColor(u, r, g, b, 255 - amount * 7)
            endif
        else
            call RemoveSavedInteger(MiscHash, 1, GetHandleId(t))
            call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
            call ReleaseTimer(t)
        endif
    endif
    
    set t = null
    set u = null
endfunction

function EnableItems takes integer pid returns nothing
    local integer i = 0

    set ItemsDisabled[pid] = false

    loop
        exitwhen i > 5
        call SetItemDroppable(UnitItemInSlot(Hero[pid], i), true)
        call SetItemDroppable(UnitItemInSlot(Backpack[pid], i), true)
        set i = i + 1
    endloop
endfunction

function DisableItems takes integer pid returns nothing
    local integer i = 0

    set ItemsDisabled[pid] = true

    loop
        exitwhen i > 5
        call SetItemDroppable(UnitItemInSlot(Hero[pid], i), false)
        call SetItemDroppable(UnitItemInSlot(Backpack[pid], i), false)
        set i = i + 1
    endloop
endfunction

function Undespawn takes nothing returns nothing
    local integer id = ReleaseTimer(GetExpiredTimer())
    local unit target = GetUnitById(id)
    local effect sfx = LoadEffectHandle(MiscHash, GetHandleId(target), 'gost')

    call PauseUnit(target, false)
    call UnitRemoveAbility(target, 'Avul')
    call BlzSetSpecialEffectX(sfx, 30000)
    call BlzSetSpecialEffectY(sfx, 30000)
    call DestroyEffectTimed(sfx, 0.)
    call RemoveSavedHandle(MiscHash, GetHandleId(target), 'gost')
    call ShowUnit(target, true)

    set sfx = null
    set target = null
endfunction

function Fade takes unit u, integer times, real rate, integer direction returns nothing
    local timer t = NewTimerEx(times)
    
    call SaveUnitHandle(MiscHash, 0, GetHandleId(t), u)
    call SaveInteger(MiscHash, 1, GetHandleId(t), direction)
    call TimerStart(t, rate, true, function ApplyFade)
    
    set t = null
endfunction

function ApplyFadeSFX takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local effect e = LoadEffectHandle(MiscHash, 0, GetHandleId(t))
    local boolean b = LoadBoolean(MiscHash, 1, GetHandleId(t))
    local boolean remove = LoadBoolean(MiscHash, 2, GetHandleId(t))
    local integer amount = GetTimerData(t)

    call SetTimerData(t, amount - 1)

    if amount <= 0 then
        if remove then
            call BlzSetSpecialEffectPosition(e, 30000, 30000, 0)
            call BlzSetSpecialEffectScale(e, 0)
            call BlzSetSpecialEffectTimeScale(e, 0)
            call DestroyEffect(e)
        endif
        call RemoveSavedHandle(MiscHash, 0, GetHandleId(t))
        call RemoveSavedBoolean(MiscHash, 1, GetHandleId(t))
        call RemoveSavedBoolean(MiscHash, 2, GetHandleId(t))
        call ReleaseTimer(t)
    else
        if b then
            call BlzSetSpecialEffectAlpha(e, amount * 7)
        else
            call BlzSetSpecialEffectAlpha(e, 255 - amount * 7)
        endif
    endif

    set t = null
    set e = null
endfunction

function FadeSFX takes effect e, boolean b, boolean remove returns nothing
    local timer t = NewTimerEx(40)
    
    if not b then
        call BlzSetSpecialEffectAlpha(e, 0)
    endif
    
    call SaveEffectHandle(MiscHash, 0, GetHandleId(t), e)
    call SaveBoolean(MiscHash, 1, GetHandleId(t), b)
    call SaveBoolean(MiscHash, 2, GetHandleId(t), remove)
    call TimerStart(t, 0.03, true, function ApplyFadeSFX)
    
    set t = null
endfunction

function HideSummonPart2 takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call ShowUnit(pt.target, false)

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function HideSummon takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    call SetUnitXBounded(pt.target, 30000)
    call SetUnitYBounded(pt.target, 30000)

    call TimerStart(GetExpiredTimer(), 1., false, function HideSummonPart2)
endfunction

function SummonExpire takes unit u returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer uid = GetUnitTypeId(u)
    local PlayerTimer pt

    call TimerList[pid].stopAllTimersWithTag(GetUnitId(u))

    if uid == SUMMON_DESTROYER then
        set BorrowedLife[pid * 10] = 0
    elseif uid == SUMMON_DESTROYER then
        set BorrowedLife[pid * 10 + 1] = 0
    endif

    if IsUnitHidden(u) == false then //important
        if uid == SUMMON_DESTROYER or uid == SUMMON_HOUND or uid == SUMMON_GOLEM then
            call UnitRemoveAbility(u, 'BNpa')
            call UnitRemoveAbility(u, 'BNpm')
            set pt = TimerList[pid].addTimer(pid)
            set pt.target = u
            set pt.tag = GetUnitId(u)
            call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", u, "origin"), 2.)

            call TimerStart(pt.getTimer(), 2., false, function HideSummon)
        endif

        if GetWidgetLife(u) >= 0.406 then
            call KillUnit(u)
        endif
    endif
endfunction

function SummonDurationXPBar takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer lev = GetHeroLevel(pt.target)

    if GetUnitTypeId(pt.target) == SUMMON_GOLEM and BorrowedLife[pid * 10] > 0 then
        set BorrowedLife[pid * 10] = BorrowedLife[pid * 10] - 0.5
    elseif GetUnitTypeId(pt.target) == SUMMON_DESTROYER and BorrowedLife[pid * 10 + 1] > 0 then
        set BorrowedLife[pid * 10 + 1] = BorrowedLife[pid * 10 + 1] - 0.5
    else
        set pt.dur = pt.dur - 0.5
    endif

    if pt.dur <= 0 then
        call TimerList[pid].removePlayerTimer(pt)
        if IsUnitHidden(pt.target) == false then
            call SummonExpire(pt.target)
        endif
    else
        call UnitStripHeroLevel(pt.target, 1)
        call SetHeroXP(pt.target, R2I(RequiredXP(lev - 1) + ((lev + 1) * pt.dur * 100 / pt.armor) - 1), false)
    endif
endfunction

function CleanupSummons takes player p returns nothing
    local integer pid = GetPlayerId(p) + 1
    local unit target
    local integer index = 0
    local integer count = BlzGroupGetSize(SummonGroup)
    
    loop
        set target = BlzGroupUnitAt(SummonGroup, index)
        if GetOwningPlayer(target) == p then
            call SummonExpire(target)
        endif
        set index = index + 1
        exitwhen index >= count
    endloop
    
    set target = null
    set helicopter[pid] = null
endfunction

function RecallSummons takes integer pid returns nothing
    local unit target
    local player p = Player(pid - 1)
    local real x = GetUnitX(Hero[pid]) + 200 * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pid]))
    local real y = GetUnitY(Hero[pid]) + 200 * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pid]))
    local integer index = 0
    local integer count = BlzGroupGetSize(SummonGroup)
    
    loop
        set target = BlzGroupUnitAt(SummonGroup, index)
        if GetOwningPlayer(target) == p and (GetUnitTypeId(target) == SUMMON_HOUND or GetUnitTypeId(target) == SUMMON_GOLEM or GetUnitTypeId(target) == SUMMON_DESTROYER) and IsUnitHidden(target) == false then
            call SetUnitPosition(target, x, y)
            call BlzSetUnitFacingEx(target, GetUnitFacing(Hero[pid]))
            call EnterWeather(target)
        endif
        set index = index + 1
        exitwhen index >= count
    endloop
    
    set p = null
    set target = null
endfunction

function periodicIsSecond takes integer count, real rate, real time returns boolean
    local integer interval = R2I(1 / rate)
    
    loop
        exitwhen count < interval
        set count = count - interval
        if count < 0 then
            return false
        endif
    endloop
    
    loop
        exitwhen count < 0
        if count == 0 or count / interval == time then
            return true
        endif
        set count = count - interval
    endloop

    return false
endfunction

function reselect takes unit u returns nothing
	if (GetLocalPlayer() == GetOwningPlayer(u)) then
        call ClearSelection()
		call SelectUnit(u, true)
	endif
endfunction

function FilterEnemyDead takes nothing returns boolean
    if GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == false then
            return true
        endif
    endif

    return false
endfunction

function FilterEnemy takes nothing returns boolean
    if IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == false and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == false then
            return true
        endif
    endif

    return false
endfunction

function FilterAllyHero takes nothing returns boolean
    if IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == false and IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == true then
            return true
        endif
    endif

    return false
endfunction

function FilterRoyalGuardian takes nothing returns boolean
    if IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == false and IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == true and GetUnitTypeId(GetFilterUnit()) == HERO_ROYAL_GUARDIAN and GetOwningPlayer(GetFilterUnit()) != Player(passedValue[callbackCount] - 1) then
            return true
        endif
    endif

    return false
endfunction

function FilterAlly takes nothing returns boolean
    if IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == false and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == true then
            return true
        endif
    endif

    return false
endfunction

function FilterEnemyAwake takes nothing returns boolean
    if IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == false and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == false and UnitIsSleeping(GetFilterUnit()) == false then
            return true
        endif
    endif

    return false
endfunction

function FilterNotIllusion takes nothing returns boolean
    if IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == false and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitIllusion(GetFilterUnit()) == false then
            return true
        endif
    endif

    return false
endfunction

function FilterAlive takes nothing returns boolean
    if IsUnitType(GetFilterUnit(),UNIT_TYPE_DEAD) == false and GetWidgetLife(GetFilterUnit()) >= 0.406 and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        return true
    endif

    return false
endfunction

function SpawnColoUnits takes integer uid, integer count returns nothing
    local integer i
    local unit u
    local integer rand = 0

    set count = count * IMinBJ(2, ColoPlayerCount)
    
	loop
		exitwhen count < 1

        set rand = GetRandomInt(1,3)
		set u = CreateUnit(pboss, uid, GetRectCenterX(gg_rct_Colloseum_Player_Spawn), GetRectCenterY(gg_rct_Colloseum_Player_Spawn), 270)
        call SetUnitXBounded(u, GetLocationX(colospot[rand]))
        call SetUnitYBounded(u, GetLocationY(colospot[rand]))
        call BlzSetUnitMaxHP(u, R2I(BlzGetUnitMaxHP(u) * (0.5 + 0.5 * ColoPlayerCount)))
        call UnitAddBonus(u, BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(u, 0) * (-0.5 + 0.5 * ColoPlayerCount)))
        call SetWidgetLife(u, BlzGetUnitMaxHP(u))
        call SetUnitCreepGuard(u, false)
        call SetUnitAcquireRange(u, 2500.)
        call GroupAddUnit(ColoWaveGroup, u)
		set udg_Colosseum_Monster_Amount = udg_Colosseum_Monster_Amount + 1

		set count = count - 1
	endloop
    
    set u = null
endfunction

function AdvanceColo takes nothing returns nothing
    local group ug = CreateGroup()
    local integer looptotal
    local unit u
    local User U = User.first

    call ReleaseTimer(GetExpiredTimer())

	loop
        exitwhen U == User.NULL
            if udg_Fleeing[U.id] and InColo[U.id] then
                set udg_Fleeing[U.id] = false
                set InColo[U.id] = false
                set ColoPlayerCount = ColoPlayerCount - 1
                call EnableItems(U.id)
                call AwardGold(U.toPlayer(), udg_GoldWon_Colo, true)
                call SetCameraBoundsRectForPlayerEx(U.toPlayer(), gg_rct_Main_Map_Vision)
                call PanCameraToTimedLocForPlayer(U.toPlayer(), TownCenter, 0)
                if GetWidgetLife(Hero[U.id]) >= 0.406 then
                    call SetUnitPositionLoc(Hero[U.id], TownCenter)
                elseif IsUnitHidden(HeroGrave[U.id]) == false then
                    call SetUnitPositionLoc(HeroGrave[U.id], TownCenter)
                endif
                call DisplayTextToPlayer(U.toPlayer(), 0, 0, "You escaped the Colosseum successfully.")
                set udg_Colloseum_XP[U.id] = (udg_Colloseum_XP[U.id] - 0.05 )
                call ExperienceControl(U.id)
                call RecallSummons(U.id)
            endif
        set U = U.next
	endloop

    if ColoPlayerCount <= 0 then
        call ClearColo()
	else
        set udg_Wave = udg_Wave + 1
        if ColoCount_main[udg_Wave] > 0 and udg_Colosseum_Monster_Amount <= 0 then
            set looptotal= ColoCount_main[udg_Wave] 
            call SpawnColoUnits(ColoEnemyType_main[udg_Wave],looptotal)
            if ColoCount_sec[udg_Wave] > 0 then
                set looptotal= ColoCount_sec[udg_Wave] 
                call SpawnColoUnits(ColoEnemyType_sec[udg_Wave],looptotal)
            endif
            set ColoWaveCount = ColoWaveCount + 1
            call DoFloatingTextCoords("Wave " + I2S(ColoWaveCount), GetLocationX(ColosseumCenter), GetLocationY(ColosseumCenter), 3.20, 32.0, 0, 18.0, 100, 0, 0, 0)
        elseif ColoCount_main[udg_Wave] <= 0 then
            set U = User.first

            set udg_GoldWon_Colo= R2I( udg_GoldWon_Colo * 1.2 )

            loop
                exitwhen U == User.NULL
                if InColo[U.id] then
                    set InColo[U.id] = false
                    set ColoPlayerCount = ColoPlayerCount - 1
                    call DisplayTimedTextToPlayer(U.toPlayer(),0,0, 10, "You have successfully cleared the Colosseum and received a 20% gold bonus.")
                    call EnableItems(U.id)

                    call AwardGold(U.toPlayer(), udg_GoldWon_Colo, true)
                    call SetCameraBoundsRectForPlayerEx(U.toPlayer(), gg_rct_Main_Map_Vision)
                    call PanCameraToTimedLocForPlayer(U.toPlayer(), TownCenter, 0)
                    if GetWidgetLife(Hero[U.id]) >= 0.406 then
                        call SetUnitPositionLoc(Hero[U.id], TownCenter)
                    elseif IsUnitHidden(HeroGrave[U.id]) == false then
                        call SetUnitPositionLoc(HeroGrave[U.id], TownCenter)
                    endif
                    call RecallSummons(U.id)
                    call ExperienceControl(U.id)
                endif
                set U = U.next
            endloop

            call ClearColo()

            call SetTextTagText( ColoText, "Colosseum", 10 * 0.023 / 10 )
        endif
    endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set u = null
endfunction

function BlackMaskExpire takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer fadeout = GetTimerData(t)
    local force f = LoadForceHandle(MiscHash, GetHandleId(t), 0)
    local User U = User.first
    
    loop
        exitwhen U == User.NULL

        if IsPlayerInForce(U.toPlayer(), f) then
            if GetLocalPlayer() == U.toPlayer() then
                call SetCineFilterStartColor(0,0,0,255)
                call SetCineFilterEndColor(0,0,0,0)
                call SetCineFilterDuration(fadeout) // fades in within 2 seconds
                call DisplayCineFilter(true)
            endif
        endif
        
        set U = U.next
    endloop
    
    call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
    call ReleaseTimer(t)
    
    call DestroyForce(f)
    
    set t = null
    set f = null
endfunction

function BlackMask takes force f, integer fadein, integer fadeout returns nothing
    local User U = User.first
    local integer pid
    local force f2 = CreateForce()
    local timer t = NewTimerEx(fadeout)
    
    loop
        exitwhen U == User.NULL

        if IsPlayerInForce(U.toPlayer(), f) then
            call ForceAddPlayer(f2, U.toPlayer())
            if GetLocalPlayer() == U.toPlayer() then
                call SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\Black_mask.blp")
                call SetCineFilterStartColor(0,0,0,0)
                call SetCineFilterEndColor(0,0,0,255)
                call SetCineFilterDuration(fadein)
                call DisplayCineFilter(true)
            endif
        endif

        set U = U.next
    endloop

    call SaveForceHandle(MiscHash, GetHandleId(t), 0, f2)
    call TimerStart(t, fadein, false, function BlackMaskExpire)
    
    set f2 = null
    set t = null
endfunction

function MoveForce takes force f, real x, real y, rect cam returns nothing
    local User U = User.first
    local integer pid
    
    loop
        exitwhen U == User.NULL
        set pid = GetPlayerId(U.toPlayer()) + 1
        if IsPlayerInForce(U.toPlayer(), f) then
            call SetUnitPosition(Hero[pid], x, y)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Hero[pid], "origin"))
            call SetCameraBoundsRectForPlayerEx(U.toPlayer(), cam)
            call PanCameraToTimedForPlayer(U.toPlayer(), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
        endif
        set U = U.next
    endloop

endfunction

function AdvanceStruggle takes nothing returns nothing
    local group ug = CreateGroup()
    local unit u
    local User U = User.first
    local integer flag = GetTimerData(GetExpiredTimer())

    if flag == 1 then
        call TimerStart(strugglespawn, 3.00, true, null)
    endif
    call ReleaseTimer(GetExpiredTimer())
    
	loop
        exitwhen U == User.NULL
		if udg_Fleeing[U.id] and InStruggle[U.id] then 
            set udg_Fleeing[U.id] = false
            set InStruggle[U.id] = false
            set udg_Struggle_Pcount = udg_Struggle_Pcount - 1
            call EnableItems(U.id)
            if GetWidgetLife(Hero[U.id]) >= 0.406 then
                call SetUnitPositionLoc(Hero[U.id], TownCenter)
            elseif IsUnitHidden(HeroGrave[U.id]) == false then
                call SetUnitPositionLoc(HeroGrave[U.id], TownCenter)
            endif
			call SetCameraBoundsRectForPlayerEx(U.toPlayer(), gg_rct_Main_Map_Vision )
			call PanCameraToTimedLocForPlayer(U.toPlayer(), TownCenter, 0)
            call ExperienceControl(U.id)
			call DisplayTextToPlayer(U.toPlayer(), 0, 0, "You escaped Struggle with your life." )
			call AwardGold(U.toPlayer(), udg_GoldWon_Struggle , true)
            call RecallSummons(U.id)
            call GroupEnumUnitsInRect(ug, gg_rct_Infinite_Struggle, Condition(function nothero))
            loop
                set u = FirstOfGroup(ug)
                exitwhen u == null
                call GroupRemoveUnit(ug, u)
                if GetOwningPlayer(u) == U.toPlayer() then
                    call RemoveUnit(u)
                endif
            endloop
		endif
        set U = U.next
	endloop
    
	set udg_Struggle_WaveN = udg_Struggle_WaveN + 1
	set udg_Struggle_WaveUCN = udg_Struggle_WaveUN[udg_Struggle_WaveN]
    if udg_Struggle_Pcount <= 0 then
        call ClearStruggle()
    else
        if udg_Struggle_WaveU[udg_Struggle_WaveN] == 0 then // Struggle Won
            set udg_GoldWon_Struggle= R2I(udg_GoldWon_Struggle * 1.5)
            call SetTextTagTextBJ( StruggleText, ( "Gold won: " + I2S(udg_GoldWon_Struggle) ), 10.00 )
            loop
                set u = FirstOfGroup(ug)
                exitwhen u == null
                call GroupRemoveUnit(ug, u)
                call RemoveUnit(u)
            endloop

            set U = User.first
            
            loop
                exitwhen U == User.NULL
                if InStruggle[U.id] then
                    set InStruggle[U.id] = false
                    set udg_Struggle_Pcount = udg_Struggle_Pcount - 1
                    call DisplayTextToPlayer(U.toPlayer(), 0, 0, "50% bonus gold for victory!" )
                    if GetWidgetLife(Hero[U.id]) >= 0.406 then
                        call SetUnitPositionLoc(Hero[U.id], TownCenter)
                    elseif IsUnitHidden(HeroGrave[U.id]) == false then
                        call SetUnitPositionLoc(HeroGrave[U.id], TownCenter)
                    endif
                    call EnableItems(U.id)
                    call SetUnitPositionLoc(Backpack[U.id], TownCenter)
                    call SetCameraBoundsRectForPlayerEx(U.toPlayer(), gg_rct_Main_Map_Vision )
                    call PanCameraToTimedLocForPlayer(U.toPlayer(), TownCenter, 0 )
                    if udg_Struggle_WaveN < 40 then
                        call DisplayTextToPlayer(U.toPlayer(),0,0, "You received a lesser ring of struggle for completing struggle." )
                        call CreateHeroItem(Backpack[U.id], U.id, 'I00T', 1)
                    else
                        call DisplayTextToPlayer(U.toPlayer(),0,0, "You received a ring of struggle for completing chaotic struggle." )
                        call CreateHeroItem(Backpack[U.id], U.id, 'I0D0', 1)
                    endif
                    call AwardGold(U.toPlayer(),udg_GoldWon_Struggle,true)
                    call ExperienceControl(U.id)
                    call RecallSummons(U.id)
                    set U = U.next
                endif
            endloop
            
            set udg_Struggle_WaveN = 0
            set udg_GoldWon_Struggle = 0
            set udg_Struggle_WaveUCN = 0
            call PauseTimer(strugglespawn)
        else
            if udg_Struggle_WaveN > 40 then
                call DoFloatingTextCoords("Wave " + I2S(udg_Struggle_WaveN - 40), GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), 3.80, 32.0, 0, 18.0, 100, 0, 0, 0)
            else
                call DoFloatingTextCoords("Wave " + I2S(udg_Struggle_WaveN), GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), 3.80, 32.0, 0, 18.0, 100, 0, 0, 0)
            endif
        endif
	endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set u = null
endfunction

function IsShopKeeper takes nothing returns boolean
local unit u= GetFilterUnit()
local integer utype= GetUnitTypeId(u)
	if utype=='n01F' and GetUnitState(u,UNIT_STATE_LIFE) >0.405 then
		call PingMinimapForPlayer(GetTriggerPlayer(), GetUnitX(u), GetUnitY(u), 3)
	endif
	set u=null
	return false
endfunction

function AllocatePrestige takes integer pid, integer rank, integer id returns nothing
    local integer i = LoadInteger(PrestigeRank, pid, id)

    call SaveInteger(PrestigeRank, pid, id, IMinBJ(2, rank + i))
    call SaveInteger(PrestigeRank, pid, 0, LoadInteger(PrestigeRank, pid, 0) + IMinBJ(2, rank + i))
endfunction

function SetPrestigeEffects takes integer pid returns nothing
	set Dmg_mod[pid] = 8 * (LoadInteger(PrestigeRank,pid,3) + LoadInteger(PrestigeRank,pid,5) + LoadInteger(PrestigeRank,pid,12))
	set DR_mod[pid]  = 1.0 - (LoadInteger(PrestigeRank,pid,11) * 0.05 + LoadInteger(PrestigeRank,pid,16) * 0.05)
	set Str_mod[pid] = 6 * (LoadInteger(PrestigeRank,pid,9) + LoadInteger(PrestigeRank,pid,15) + LoadInteger(PrestigeRank,pid,18))
	set Agi_mod[pid] = 7 * (LoadInteger(PrestigeRank,pid,2) + LoadInteger(PrestigeRank,pid,8) + LoadInteger(PrestigeRank,pid,21) )
	set Int_mod[pid] = 7 * (LoadInteger(PrestigeRank,pid,10) + LoadInteger(PrestigeRank,pid,13) + LoadInteger(PrestigeRank,pid,14))
	set Spl_mod[pid] = 4 * (LoadInteger(PrestigeRank,pid,1) + LoadInteger(PrestigeRank,pid,6) + LoadInteger(PrestigeRank,pid,4) + LoadInteger(PrestigeRank,pid,17))
	set Gld_mod[pid] = 2 * (LoadInteger(PrestigeRank,pid,0))
	set Reg_mod[pid] = 8 * (LoadInteger(PrestigeRank,pid,7))
endfunction

function UpdateTooltips takes nothing returns nothing
    local string array s
    local integer i
    local integer unlocked
    local User u = User.first
    
    //prestige skins
    
    loop
        exitwhen u == User.NULL
        set i = GetPlayerId(u.toPlayer()) + 1
        set unlocked = 0
        //dmg
        if LoadInteger(PrestigeRank,i,3) +LoadInteger(PrestigeRank,i,5) +LoadInteger(PrestigeRank,i,12) > 2 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,3) +LoadInteger(PrestigeRank,i,5) +LoadInteger(PrestigeRank,i,12) > 0 then
            set unlocked = unlocked + 1
        endif
        //dmg red
        if LoadInteger(PrestigeRank,i,11) + LoadInteger(PrestigeRank,i,16) > 1 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,11) + LoadInteger(PrestigeRank,i,16) > 0 then
            set unlocked = unlocked + 1
        endif
        //str
        if LoadInteger(PrestigeRank,i,9) +LoadInteger(PrestigeRank,i,15) +LoadInteger(PrestigeRank,i,18) > 2 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,9) +LoadInteger(PrestigeRank,i,15) +LoadInteger(PrestigeRank,i,18) > 0 then
            set unlocked = unlocked + 1
        endif
        //agi
        if LoadInteger(PrestigeRank,i,2) +LoadInteger(PrestigeRank,i,8) + LoadInteger(PrestigeRank,i,21) > 1 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,2) +LoadInteger(PrestigeRank,i,8) + LoadInteger(PrestigeRank,i,21) > 0 then
            set unlocked = unlocked + 1
        endif
        //int
        if LoadInteger(PrestigeRank,i,10) +LoadInteger(PrestigeRank,i,13) +LoadInteger(PrestigeRank,i,14) > 2 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,10) +LoadInteger(PrestigeRank,i,13) +LoadInteger(PrestigeRank,i,14) > 0 then
            set unlocked = unlocked + 1
        endif
        //spellboost
        if LoadInteger(PrestigeRank,i,1) +LoadInteger(PrestigeRank,i,6) +LoadInteger(PrestigeRank,i,4) +LoadInteger(PrestigeRank,i,17) > 3 then
            set unlocked = unlocked + 3
        elseif LoadInteger(PrestigeRank,i,1) +LoadInteger(PrestigeRank,i,6) +LoadInteger(PrestigeRank,i,4) +LoadInteger(PrestigeRank,i,17) > 1 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,1) +LoadInteger(PrestigeRank,i,6) +LoadInteger(PrestigeRank,i,4) +LoadInteger(PrestigeRank,i,17) > 0 then
            set unlocked = unlocked + 1
        endif
        //regen
        if LoadInteger(PrestigeRank,i,7) > 1 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,7) > 0 then
            set unlocked = unlocked + 1
        endif
        //prestige
        if LoadInteger(PrestigeRank,i,0) > 17 then
            set unlocked = unlocked + 2
        elseif LoadInteger(PrestigeRank,i,0) > 8 then
            set unlocked = unlocked + 1
        endif
        if unlocked == 17 then
            set s[i] = "Change your backpack's appearance.\n\nUnlocked skins: |c0000ff4017/17"
        else
            set s[i] = "Change your backpack's appearance.\n\nUnlocked skins: " + I2S(unlocked) + "/17"
        endif
        set u = u.next
    endloop
    
    call BlzSetAbilityExtendedTooltip('A0KX', s[GetPlayerId(GetLocalPlayer()) + 1], 0)
    
    set u = User.first
        
    loop
        exitwhen u == User.NULL
        set i = GetPlayerId(u.toPlayer()) + 1
        
        if HeroID[i] > 0 then
            //heart of the demon prince
            if HasItemType(Hero[i], 'I04Q') then
                set s[20] = ""
                set s[21] = ""
                
                if HeartHits[i] >= 1000 then
                    set s[20] = "|c0000ff40"
                endif
                if HeartDealt[i] >= 500000 then
                    set s[21] = "|c0000ff40"
                endif
                
                set s[i] = "|c006666ffItem Type: |r|c00ff5500Chaotic Quest|r\n|c00ff0000Level Requirement: |r190\n|c00ff6600Effect:|r Deal damage (" + s[21] + RealToString(HeartDealt[i]) + "/500,000|r) or take hits (" + s[20] + RealToString(HeartHits[i]) + "/1,000|r) to fill the heart with blood. (Level 170+ enemies)\n|c00ffcc00Description: |rThe heart of the Demon Prince.\n|c00ff0000WARNING! This item does not save!|r"

                call BlzSetItemExtendedTooltip(GetItemFromUnit(Hero[i], 'I04Q'), s[i])
            endif

            //sniper stance
            if HeroID[i] == HERO_MARKSMAN then
                set s[i] = "Enable Sniper Stance - [|cffffcc00E|r]"
                set s[i + 8] = "The marksman steadies his aim, granting |cffFFCC00450 attack range|r and halved |cffffcc00Tri-Rocket|r cooldown.|nGives a |cffffcc00100%|r chance to hit for |cffFFCC004x|r additional damage.|nWhile active you have |cffffcc00100|r movespeed.|n|cff0080C02 second cooldown.|r"
                set s[i + 16] = "The Elite Marksman fires 3 rockets in a cone in front of him, dealing (|cff00D23F<A06I,Area1> x Agi|r + |cffE15F0810% Attack Damage|r) spell damage, the recoil of which sends him flying backwards a short distance. Can |cffFFCC00triple-hit|r if used at very close range to an enemy.\n|cff0080C06 second cooldown.|r"
                
                if sniperstance[i] then
                    set s[i] = "Disable Sniper Stance - [|cffffcc00E|r]"
                    set s[i + 8] = "Switches back to your normal stance, allowing you to move again at normal speed, but lose the |cffFFCC00450 attack range|r, reduced |cffffcc00Tri-Rocket|r cooldown, and |cffffcc00Critical Strike|r.\n|cff0080C02 second cooldown.|r"
                    set s[i + 16] = "The Elite Marksman fires 3 rockets in a cone in front of him, dealing (|cff00D23F<A06I,Area1> x Agi|r + |cffE15F0810% Attack Damage|r) spell damage, the recoil of which sends him flying backwards a short distance. Can |cffFFCC00triple-hit|r if used at very close range to an enemy.\n|cff0080C03 second cooldown.|r"
                endif
            endif
        endif

        set u = u.next
    endloop

    call BlzSetAbilityTooltip('A049', s[GetPlayerId(GetLocalPlayer()) + 1], 0)
    call BlzSetAbilityExtendedTooltip('A049', s[GetPlayerId(GetLocalPlayer()) + 9], 0)
    call BlzSetAbilityExtendedTooltip('A06I', s[GetPlayerId(GetLocalPlayer()) + 17], 0)
    call BlzSetAbilityExtendedTooltip('A06I', s[GetPlayerId(GetLocalPlayer()) + 17], 1)
    call BlzSetAbilityExtendedTooltip('A06I', s[GetPlayerId(GetLocalPlayer()) + 17], 2)
    call BlzSetAbilityExtendedTooltip('A06I', s[GetPlayerId(GetLocalPlayer()) + 17], 3)
    call BlzSetAbilityExtendedTooltip('A06I', s[GetPlayerId(GetLocalPlayer()) + 17], 4)
endfunction

function ActivatePrestige takes player p returns nothing
	local integer i = 0
	local integer counter = 0
	local integer pid = GetPlayerId(p) + 1
	local integer currentSlot = Profiles[pid].currentSlot
    local item array itm
    
    if Profiles[pid].hd.prestige > 0 then
        call DisplayTimedTextToPlayer(p,0,0, 20.00, "You can not prestige this character again." )
    else
        call RemoveItem(GetItemFromUnit(Hero[pid], 'I0NN'))
		set Profiles[pid].hd.prestige = 1 + Profiles[pid].hd.hardcore
		call Profiles[pid].saveCharacter()

		call AllocatePrestige(pid, Profiles[pid].hd.prestige, Profiles[pid].hd.id)

		call DisplayTimedTextToForce(FORCE_PLAYING, 30.00, User.fromIndex(pid - 1).nameColored + " has prestiged their hero and achieved rank |cffffcc00" + I2S(LoadInteger(PrestigeRank, pid, 0)) + "|r prestige!")
		call DisplayTimedTextToPlayer(p,0,0, 20.00, "|cffffcc00Hero Prestige:|r " + I2S(Profiles[pid].hd.prestige) )
		call UpdateTooltips()

		loop
			exitwhen i > 5
			set itm[i] = UnitItemInSlot(Hero[pid], i)

			if itm[i] != null then
				call UnitRemoveItem(Hero[pid], itm[i])
			endif

			set i = i + 1
		endloop

        call SetPrestigeEffects(pid)
		set i = 0

		loop
			exitwhen i > 5

			if itm[i] != null then
				call UnitAddItem(Hero[pid], itm[i])
				call UnitDropItemSlot(Hero[pid], itm[i], i)
				set itm[i] = null
			endif

			set i = i + 1
		endloop

	endif
endfunction

function Taunt takes unit hero, integer pid, boolean aggro, integer allythreat, integer herothreat returns nothing
    local group enemyGroup = CreateGroup()
    local group allyGroup = CreateGroup()
    local player p = GetOwningPlayer(hero)
    local unit target
    local unit target2
    local integer count = 0
    local integer index = 0
    local integer count2 = 0
    local integer index2 = 0

    call MakeGroupInRange(pid, enemyGroup, GetUnitX(hero), GetUnitY(hero), 800., Condition(function FilterEnemy))
    call MakeGroupInRange(pid, allyGroup, GetUnitX(hero), GetUnitY(hero), 800., Condition(function FilterAlly))

    set count = BlzGroupGetSize(enemyGroup)
    set count2 = BlzGroupGetSize(allyGroup)

    if count > 0 then
        loop
            set target = BlzGroupUnitAt(enemyGroup, index)
            call SaveInteger(ThreatHash, GetUnitId(target), GetUnitId(hero), IMinBJ(THREAT_CAP - 1, LoadInteger(ThreatHash, GetUnitId(target), GetUnitId(hero)) + herothreat))
            if aggro then
                call IssueTargetOrder(target, "smart", hero)
                call SaveInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX, GetUnitId(hero))
            endif
            loop
                set target2 = BlzGroupUnitAt(allyGroup, index2)
                if target2 != hero then
                    call SaveInteger(ThreatHash, GetUnitId(target), GetUnitId(target2), IMaxBJ(0, LoadInteger(ThreatHash, GetUnitId(target), GetUnitId(target2)) - allythreat))
                endif
                set index2 = index2 + 1
                exitwhen index2 >= count2
            endloop

            set index = index + 1
            exitwhen index >= count
        endloop
    endif

    call DestroyGroup(enemyGroup)
    call DestroyGroup(allyGroup)

    set p = null
    set enemyGroup = null
    set allyGroup = null
    set target = null
    set target2 = null
endfunction

function KillEverythingLol takes nothing returns nothing
    local group ug = CreateGroup()
    local unit u
    
    call GroupEnumUnitsInRect(ug, bj_mapInitialPlayableArea, null)
    
    loop
        set u = FirstOfGroup(ug)
        exitwhen u == null
        call GroupRemoveUnit(ug, u)
        call KillUnit(u)
    endloop
    
    call DestroyGroup(ug)
    
    set u = null
    set ug = null
endfunction

function MetamorphosisInvulnExpire takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    set HeroInvul[pid] = false

    if ismetamorphosis[pid] then
        set ismetamorphosis[pid] = false
        call GroupRemoveUnit(AffectedByWeather, Hero[pid])
        call EnterWeather(Hero[pid])
    endif
endfunction

function RevivePlayer takes integer pid, real x, real y, real percenthp, real percentmana returns nothing
    local player p = Player(pid - 1)

    call ReviveHero(Hero[pid], x, y, true)
    call SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * percenthp)
    call SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA) * percentmana)
    call PanCameraToTimedForPlayer(p, x, y, 0)
    
    if GetLocalPlayer() == p then
        call ClearSelection()
        call SelectUnit(Hero[pid], true)
    endif

    call EnterWeather(Hero[pid])

    if MultiShot[pid] then
        call IssueImmediateOrder(Hero[pid], "defend")
    endif

    call TimerStart(NewTimerEx(pid), 0.5, false, function MetamorphosisInvulnExpire)
    
    set p = null
endfunction

function onRevive takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    
    call RevivePlayer(pid, GetLocationX(TownCenter), GetLocationY(TownCenter), 1, 1)
    call SetCameraBoundsRectForPlayerEx(Player(pid - 1), gg_rct_Main_Map)
    call PanCameraToTimedLocForPlayer(Player(pid - 1), TownCenter, 0)
    
    call DestroyTimerDialog(RTimerBox[pid])

    call TimerList[pid].removePlayerTimer(pt)
endfunction

function IntegerToTime takes integer i returns string
    local string s = ""
    local integer hours = i / 3600
    local integer minutes = i / 60 - hours * 60
    local integer seconds = i - hours * 3600 - minutes * 60
    local integer length = StringLength(I2S(i))

    set s = I2S(hours)

    if minutes > 9 then
        set s = s + ":" + I2S(minutes)
    else
        set s = s + ":0" + I2S(minutes)
    endif

    if seconds > 9 then
        set s = s + ":" + I2S(seconds)
    else
        set s = s + ":0" + I2S(seconds)
    endif

    return s
endfunction

function boolset takes boolean istrue, real myreal returns real
	if istrue then
		return 1.
	endif
		return myreal
endfunction

function ItemProfMod takes integer id, integer pid returns real
    local real mod = 1

    if ItemData[id][StringHash("prof")] == 5 then
		if udg_HeroCanUseFullPlate[pid] == false and udg_HeroCanUsePlate[pid] == false then
			set mod = 0.5
		endif
	elseif LoadBoolean(PlayerProf, pid, ItemData[id][StringHash("prof")]) == false and ItemData[id][StringHash("prof")] > 0 then
		set mod = 0.5
	endif

    return mod
endfunction

function Roundmana takes real manac returns integer
	if manac>99999 then
		return 1000*R2I(manac / 1000)
	endif
	return R2I(manac)
endfunction

function UnitSpecification takes unit u returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer uid = GetUnitTypeId(u)
    local integer maxmana = BlzGetUnitMaxMana(u) 

	if uid == BACKPACK then
		call BlzUnitDisableAbility(u,'A083',true,true)
		call BlzUnitDisableAbility(u,'A02A',true,true)
		call BlzUnitDisableAbility(u,'A0IS',true,true)
		call BlzUnitDisableAbility(u,'A0SO',true,true)
		call BlzUnitDisableAbility(u,'A0SX',true,true)
		call BlzUnitDisableAbility(u,'A0RK',true,true)
		call BlzUnitDisableAbility(u,'A00I',true,true)
		call BlzUnitDisableAbility(u,'A00O',true,true)
        call BlzUnitDisableAbility(u,'A0CP',true,true)
        call BlzUnitDisableAbility(u,'A0CQ',true,true)
        call BlzUnitDisableAbility(u,'AIfw',true,true)
        call BlzUnitDisableAbility(u,'AIft',true,true)
        call BlzUnitDisableAbility(u,'A0CD',true,true)
        call BlzUnitDisableAbility(u,'A0CC',true,true)
        call BlzUnitDisableAbility(u,'AIpv',true,true)
        call BlzUnitDisableAbility(u,'AIv2',true,true)
        call BlzUnitDisableAbility(u,'A055',true,true)
        call BlzUnitDisableAbility(u,'A01S',true,true)
        call BlzUnitDisableAbility(u,'A0AC',true,true)
        call BlzUnitDisableAbility(u,'A03D',true,true)
        call BlzUnitDisableAbility(u,'A0B5',true,true)
        call BlzUnitDisableAbility(u,'A07G',true,true)
        call UnitRemoveAbility(u, 'A0CP') //immolations and orb effects
        call UnitRemoveAbility(u, 'A0UP')
        call UnitRemoveAbility(u, 'A00D')
        call UnitRemoveAbility(u, 'A00E')
        call UnitRemoveAbility(u, 'A00Q')
        call UnitRemoveAbility(u, 'A00W')
        call UnitRemoveAbility(u, 'A00X')
        call UnitRemoveAbility(u, 'A00V')
        call UnitRemoveAbility(u, 'A013')
        call UnitRemoveAbility(u, 'A01O')
        call UnitRemoveAbility(u, 'A01H')
        call UnitRemoveAbility(u, 'A019')
        call UnitRemoveAbility(u, 'A00Y')
        call UnitRemoveAbility(u, 'AIcf')
        call UnitRemoveAbility(u, 'A0CQ')
        call UnitRemoveAbility(u, 'AIfw')
        call UnitRemoveAbility(u, 'AIft')
        call UnitRemoveAbility(u, 'A0CC')
        call UnitRemoveAbility(u, 'A0CD')
        call UnitRemoveAbility(u, 'A06Z')
        call UnitRemoveAbility(u, 'AIlb')
        call UnitRemoveAbility(u, 'AIsb')
        call UnitRemoveAbility(u, 'AIdn')
        call UnitRemoveAbility(u, 'A051')
	elseif uid == HERO_ASSASSIN then
		call BlzSetUnitAbilityManaCost(u, 'A0AS', GetUnitAbilityLevel(u, 'A0AS') - 1, Roundmana(maxmana * .075 )) //blade spin
		call BlzSetUnitAbilityManaCost(u, 'A0BG', GetUnitAbilityLevel(u, 'A0BG') - 1, Roundmana(maxmana * .05 )) //shadow shuriken
		call BlzSetUnitAbilityManaCost(u, 'A00T', GetUnitAbilityLevel(u, 'A00T') - 1, Roundmana(maxmana * .15 )) //blink strike
		call BlzSetUnitAbilityManaCost(u, 'A01E', GetUnitAbilityLevel(u, 'A01E') - 1, Roundmana(maxmana * .20) ) //smoke bomb
		call BlzSetUnitAbilityManaCost(u, 'A00P', GetUnitAbilityLevel(u, 'A00P') - 1, Roundmana(maxmana * .25) ) //dagger storm
        call BlzSetUnitAbilityManaCost(u, 'A07Y', GetUnitAbilityLevel(u, 'A07Y') - 1, Roundmana(maxmana * (.1 - 0.025 * GetUnitAbilityLevel(u, 'A07Y')))) //phantom slash
	elseif uid == HERO_BARD then
        set BardMelodyCost[pid] = Roundmana(GetUnitState(u, UNIT_STATE_MANA) * .1)
		call BlzSetUnitAbilityManaCost(u, 'A02H', GetUnitAbilityLevel(u, 'A02H') - 1, R2I(BardMelodyCost[pid]))
		call BlzSetUnitAbilityManaCost(u, 'A09Y', GetUnitAbilityLevel(u, 'A09Y') - 1, Roundmana(maxmana * .02))
	elseif uid == HERO_HIGH_PRIEST then
		call BlzSetUnitAbilityManaCost(u, 'A048', GetUnitAbilityLevel(u, 'A048') - 1, Roundmana(GetUnitState(u, UNIT_STATE_MANA) *.3) )
        call BlzSetUnitAbilityManaCost(u, 'A0DU', GetUnitAbilityLevel(u, 'A0DU') - 1, Roundmana(maxmana * .02) )
    elseif uid == HERO_PHOENIX_RANGER then
        //
    elseif uid == HERO_THUNDERBLADE then
        call BlzSetUnitAbilityManaCost(u, 'A096', GetUnitAbilityLevel(u, 'A096') - 1, Roundmana(maxmana * .02) )
	endif

endfunction

function dualprof takes integer pid, integer ptype returns boolean
local integer i
local integer end
local integer counter=0
	if ptype==1 then
		set i=1
		set end=4
	elseif ptype==2 then
		set i=6
		set end=10
	elseif ptype==3 then
		set i=1
		set end=10
	endif
	loop
		exitwhen i>end
		if LoadBoolean(PlayerProf,pid, i) then
			set counter= counter+1
		endif
		set i=i+1
	endloop
	return counter>1
endfunction

function Trig_RewardDialog takes integer pid, integer rewardtable returns nothing
local integer index= 1
local integer lastint = 0

	call DialogClear( dChooseReward[pid] )
	call DialogSetMessage( dChooseReward[pid], "Choose your item." )
	set udg_SlotIndex[pid]=rewardtable
	loop
		exitwhen index > LoadInteger(RewardItems, rewardtable, 0)
		if LoadBoolean(PlayerProf,pid,index) and LoadInteger(RewardItems,rewardtable,index)!=0 and LoadInteger(RewardItems,rewardtable,index) != lastint then
            set lastint = LoadInteger(RewardItems,rewardtable,index)
			set slotitem[50+pid*10 +index] = DialogAddButton(dChooseReward[pid], GetObjectName(lastint), 48 + index)
		endif
		set index= index +1
	endloop
	call DialogDisplay(Player(pid - 1), dChooseReward[pid], true)
endfunction

endlibrary
