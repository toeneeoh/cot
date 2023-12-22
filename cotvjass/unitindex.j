library UnitIndex
    globals
        constant integer DETECT_LEAVE_ABILITY = 'uDex'
        unit array UI_UNIT
        integer array UI_LIST
        integer UI_INDEX = 0
        integer UI_COUNTER = 0
    endglobals

    function GetUnitId takes unit whichUnit returns integer
        return GetUnitUserData(whichUnit)
    endfunction

    function GetUnitTarget takes unit whichUnit returns unit
        return UI_UNIT[LoadInteger(ThreatHash, GetUnitId(whichUnit), THREAT_TARGET_INDEX)]
    endfunction

    function GetUnitById takes integer index returns unit
        return UI_UNIT[index]
    endfunction

    function UnitDeIndex takes unit whichUnit returns nothing
        local integer i = GetUnitId(whichUnit)

        if i > 0 then //unit is indexed
            set UI_LIST[i] = UI_INDEX
            set UI_INDEX = i

            call SetUnitUserData(whichUnit, 0)

            static if LIBRARY_dev then
                if EXTRA_DEBUG then
                    call DisplayTimedTextToForce(FORCE_PLAYING, 30., "UNREG " + GetUnitName(whichUnit))
                endif
            endif

            set UI_UNIT[i] = null
        endif
    endfunction

    private function IndexUnit takes nothing returns boolean
        local unit u = GetFilterUnit()
        local integer index = UI_INDEX
        local integer i = GetUnitId(u)

        if GetUnitTypeId(u) != DUMMY and i == 0 then
            call UnitAddAbility(u, DETECT_LEAVE_ABILITY)
            call UnitMakeAbilityPermanent(u, true, DETECT_LEAVE_ABILITY)

            if UI_INDEX != 0 then
                set UI_INDEX = UI_LIST[index]
            else
                set UI_COUNTER = UI_COUNTER + 1
                set index = UI_COUNTER
            endif

            set UI_LIST[index] = -1
            set UI_UNIT[index] = u

            call SetUnitUserData(u, index)

            call TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, u, EVENT_UNIT_ACQUIRED_TARGET)

            static if LIBRARY_dev then
                if EXTRA_DEBUG then
                    call DisplayTimedTextToForce(FORCE_PLAYING, 30., "REG " + GetUnitName(u))
                endif
            endif
        endif

        set u = null

        return false
    endfunction

    function UnitIndexingSetup takes nothing returns nothing
        local group ug = CreateGroup()

        call GroupEnumUnitsOfPlayer(ug, pboss, Filter(function IndexUnit)) //index preplaced bosses
        call TriggerRegisterEnterRegion(CreateTrigger(), WorldBounds.worldRegion, Filter(function IndexUnit))

        call DestroyGroup(ug)

        set ug = null
    endfunction
endlibrary
