library BuffEvent /*
                        BuffEvent v1.00
                            by Flux
             
            Allows you to catch an event when any Buff applied.
     
        API:
            - BuffEvent.create(code)
                > The code will run when any Buff is applied to any unit.
                > Will not create a new object if there is a BuffEvent already
                  existing for the input code argument.
         
            - BuffEvent.remove(code)
                > Remove the BuffEvent that has the code argument.
             
            - <BuffEventObject>.destroy()
                > Remove a BuffEvent instance.
           
            - BuffEvent.buff
                > The Buff that causes the event to run.
         
        */ requires Buff /*
     
        */ optional TimerUtils /*
*/
    struct BuffEvent
     
        readonly triggercondition tc
        readonly conditionfunc cf

        readonly static Buff buff
        private static trigger trg = CreateTrigger()
     
        method destroy takes nothing returns nothing
            call TriggerRemoveCondition(thistype.trg, this.tc)
            call RemoveSavedInteger(s__Buff_hash, GetHandleId(this.cf), 0)
            set this.tc = null
            set this.cf = null
            call this.deallocate()
        endmethod
     
        static method remove takes code c returns nothing
            local integer id = GetHandleId(Condition(c))
            if HaveSavedInteger(s__Buff_hash, id, 0) then
                call thistype(LoadInteger(s__Buff_hash, id, 0)).destroy()
            debug else
                debug call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[BuffEvent]: Attempted to unregister code with non-existing BuffEvent.")
            endif
        endmethod

        static method pickAll takes nothing returns nothing
            static if LIBRARY_TimerUtils then
                set thistype.buff = GetTimerData(GetExpiredTimer())
                call ReleaseTimer(GetExpiredTimer())
            else
                local integer id = GetHandleId(GetExpiredTimer())
                set thistype.buff = LoadInteger(s__Buff_hash, id, 0)
                call RemoveSavedInteger(s__Buff_hash, id, 0)
                call DestroyTimer(GetExpiredTimer())
            endif
            call TriggerEvaluate(thistype.trg)
        endmethod
     
        static method create takes code c returns thistype
            local conditionfunc cf = Condition(c)
            local integer id = GetHandleId(cf)
            local thistype this
            if HaveSavedInteger(s__Buff_hash, id, 0) then
                set this = thistype(LoadInteger(s__Buff_hash, id, 0))
            else
                set this = thistype.allocate()
                set this.tc = TriggerAddCondition(thistype.trg, cf)
                set this.cf = cf
                call SaveInteger(s__Buff_hash, id, 0, this)
            endif
            return this
        endmethod
    endstruct

endlibrary
