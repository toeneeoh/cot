library TimedHandles uses optional TimerUtils
/**************************************************************
*
*   v1.0.5 by TriggerHappy
*   ----------------------
*
*   Use this to destroy a handle after X amount seconds.
*
*   It's useful for things like effects where you may
*   want it to be temporary, but not have to worry
*   about the cleaning memory leak. By default it supports
*   effects, lightning, weathereffect, items, ubersplats, and units.
*
*   If you want to add your own handle types copy a textmacro line
*   at the bottom and add whichever handle you want along with it's destructor.
*
*   Example: //! runtextmacro TIMEDHANDLES("handle", "DestroyHandle")
*
*   Installation
    ----------------------
*       1. Copy this script and over to your map inside a blank trigger.
*       2. If you want more efficiency copy TimerUtils over as well.
*
*   API
*   ----------------------
*       call DestroyEffectTimed(AddSpecialEffect("effect.mdx", 0, 0), 5)
*       call DestroyLightningTimed(AddLightning("CLPB", true, 0, 0, 100, 100), 5)
*
*   Credits to Vexorian for TimerUtils and his help on the script.
*
**************************************************************/

    globals
        // If you don't want a timer to be ran each instance
        // set this to true.
        private constant boolean SINGLE_TIMER = false
        // If you chose a single timer then this will be the speed
        // at which the timer will update
        private constant real    UPDATE_PERIOD = 0.05
    endglobals

    function RecycleDummy takes unit u returns nothing
        local integer i = LoadInteger(MiscHash, GetHandleId(u), 'dspl')

        call BlzSetUnitName(u, " ")
        call BlzSetUnitWeaponBooleanField(u, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
        call SetUnitOwner(u, Player(PLAYER_NEUTRAL_PASSIVE), true)
        call BlzSetUnitSkin(u, DUMMY)
        call SetUnitXBounded(u, 30000.)
        call SetUnitYBounded(u, 30000.)
        if i > 0 then
            call UnitRemoveAbility(u, i)
        endif
        call FlushChildHashtable(MiscHash, GetHandleId(u))
        call UnitAddAbility(u, 'Aloc')
        call UnitAddAbility(u, 'Avul')
        call SetUnitFlyHeight(u, GetUnitDefaultFlyHeight(u), 0)
        call SetUnitScale(u, 1, 1, 1)
        call SetUnitVertexColor(u, 255, 255, 255, 255)
        call SetUnitTimeScale(u, 1.)
        call BlzUnitClearOrders(u, false)
        call BlzUnitDisableAbility(u, 'Amov', false, false)
        call PauseUnit(u, true)
        call GroupAddUnit(DUMMY_STACK, u)
    endfunction

    // here you may add or remove handle types
    //! runtextmacro TIMEDHANDLES("effect", "DestroyEffect", "Thing")
    ///! runtextmacro TIMEDHANDLES("lightning", "DestroyLightning", "")
    ///! runtextmacro TIMEDHANDLES("weathereffect", "RemoveWeatherEffect", "")
    //! runtextmacro TIMEDHANDLES("item", "RemoveItem", "Thing")
    //! runtextmacro TIMEDHANDLES("unit", "RemoveUnit", "Thing")
    ///! runtextmacro TIMEDHANDLES("ubersplat", "DestroyUbersplat", "")
    //! runtextmacro TIMEDHANDLES("texttag", "DestroyTextTag", "")
    //! runtextmacro TIMEDHANDLES("timer", "ReleaseTimer", "")
    
    // Do not edit below this line
    
    //! textmacro TIMEDHANDLES takes HANDLE,DESTROY,WOW
        
        struct $HANDLE$Timed
        
            $HANDLE$ $HANDLE$_var
            static integer index = -1
            static thistype array instance
            static real REAL=UPDATE_PERIOD
            
            static if SINGLE_TIMER then
                static timer timer = CreateTimer()
                real duration
                real elapsed = 0
            else static if not LIBRARY.TimerUtils then
                static hashtable table = InitHashtable()
            endif

            method RemoveUnitThing takes unit u returns nothing
                local integer i
                local integer uid = GetUnitTypeId(u)

                if uid == DUMMY then //reset defaults
                    call RecycleDummy(u)
                else
                    call FlushChildHashtable(MiscHash, GetHandleId(u))
                    call RemoveUnit(u)
                endif
            endmethod

            method RemoveItemThing takes item e returns nothing
                if (GetItemUserData(e) == 0 or GetItemUserData(e) == 42) and IsItemOwned(e) == false and IsItemVisible(e) then
                    call RemoveItem(e)
                endif
            endmethod
            
            method DestroyEffectThing takes effect e returns nothing
                call BlzSetSpecialEffectScale(e, 0)
                call DestroyEffect(e)
            endmethod
            
            method destroy takes nothing returns nothing
                call $DESTROY$$WOW$(this.$HANDLE$_var)
                set this.$HANDLE$_var = null
                
                static if SINGLE_TIMER then
                    set this.elapsed = 0
                endif
                
                call this.deallocate()
            endmethod
            
            private static method remove takes nothing returns nothing
                static if SINGLE_TIMER then
                    local integer i = 0
                    local thistype this
                    loop
                        exitwhen i > thistype.index
                        set this = instance[i]
                        set this.elapsed = this.elapsed + UPDATE_PERIOD
                        if (this.elapsed >= this.duration) then
                            set instance[i] = instance[index]
                            set i = i - 1
                            set index = index - 1
                            call this.destroy()
                            if (index == -1) then
                                call PauseTimer(thistype.timer)
                            endif
                        endif
                        set i = i + 1
                    endloop
                else
                    local timer t = GetExpiredTimer()
                    static if LIBRARY.TimerUtils then
                        local $HANDLE$Timed this = GetTimerData(t)
                        call ReleaseTimer(t)
                        call this.destroy()
                    else
                        local $HANDLE$Timed this = LoadInteger(table, 0, GetHandleId(t))
                        call DestroyTimer(t)
                        set t = null
                        call this.destroy()
                    endif
                endif
            endmethod
            
            static method create takes $HANDLE$ h, real timeout returns $HANDLE$Timed
                local $HANDLE$Timed this = $HANDLE$Timed.allocate()
                
                static if SINGLE_TIMER then
                    set index = index + 1
                    set instance[index] = this
                    if (index == 0) then
                        call TimerStart(thistype.timer, UPDATE_PERIOD, true, function thistype.remove)
                    endif
                    set this.duration = timeout
                else
                    static if LIBRARY.TimerUtils then
                        call TimerStart(NewTimerEx(this), timeout, false, function $HANDLE$timed.remove)
                    else
                        local timer t = CreateTimer()
                        call SaveInteger(thistype.table, 0, GetHandleId(t), this)
                        call TimerStart(t, timeout, false, function $HANDLE$Timed.remove)
                        set t = null
                    endif
                endif  
                
                set this.$HANDLE$_var = h
                
                return this
            endmethod
            
        endstruct
        
        function $DESTROY$Timed takes $HANDLE$ h, real duration returns $HANDLE$Timed
            return $HANDLE$Timed.create(h, duration)
        endfunction

    //! endtextmacro
    
endlibrary
