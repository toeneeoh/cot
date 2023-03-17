library SaveHelperLib requires Functions

    globals
        trigger profile_sync_event = CreateTrigger()
        trigger character_sync_event = CreateTrigger()
        string savecode = ""
        boolean array newcharacter
        boolean LOAD_SAFE = true
        boolean array LEFT_CHURCH
    endglobals

    private function LoadProfile_OnLoad takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p) + 1

        set savecode = BlzGetTriggerSyncData()

        call Profiles[pid].loadProfile(savecode)

        set p = null
    endfunction

    private function LoadCharacter_OnLoad takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local integer pid = GetPlayerId(p) + 1

        set savecode = BlzGetTriggerSyncData()

        call Profiles[pid].loadCharacter(savecode)

        set p = null
    endfunction
    
    function SaveHelperInit takes nothing returns nothing
        local User u = User.first

        loop
            exitwhen u == User.NULL
            call BlzTriggerRegisterPlayerSyncEvent(profile_sync_event, u.toPlayer(), PROFILE_PREFIX, false)
            call BlzTriggerRegisterPlayerSyncEvent(character_sync_event, u.toPlayer(), CHARACTER_PREFIX, false)

            set u = u.next
        endloop

        call TriggerAddAction(profile_sync_event, function LoadProfile_OnLoad)
        call TriggerAddAction(character_sync_event, function LoadCharacter_OnLoad)
    endfunction
    
endlibrary
