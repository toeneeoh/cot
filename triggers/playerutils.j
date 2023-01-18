library PlayerUtils requires Functions
    /**************************************************************
    *
    *   v1.2.9 by TriggerHappy
    *
    *   This library provides a struct which caches data about players
    *   as well as provides functionality for manipulating player colors.
    *
    *   Constants
    *   ------------------
    *
    *       force FORCE_PLAYING - Player group of everyone who is playing.
    *
    *   Struct API
    *   -------------------
    *     struct User
    *
    *       static method fromIndex takes integer i returns User
    *       static method fromLocal takes nothing returns User
    *       static method fromPlaying takes integer id returns User
    *
    *       static method operator []    takes integer id returns User
    *       static method operator count takes nothing returns integer
    *
    *       method operator name         takes nothing returns string
    *       method operator name=        takes string name returns nothing
    *       method operator color        takes nothing returns playercolor
    *       method operator color=       takes playercolor c returns nothing
    *       method operator defaultColor takes nothing returns playercolor
    *       method operator hex          takes nothing returns string
    *       method operator nameColored  takes nothing returns string
    *
    *       method toPlayer takes nothing returns player
    *       method colorUnits takes playercolor c returns nothing
    *
    *       readonly string originalName
    *       readonly boolean isPlaying
    *       readonly static player Local
    *       readonly static integer LocalId
    *       readonly static integer AmountPlaying
    *       readonly static playercolor array Color
    *       readonly static player array PlayingPlayer
    *
    **************************************************************/
    
        globals
            // automatically change unit colors when changing player color
            private constant boolean AUTO_COLOR_UNITS = true
       
            // use an array for name / color lookups (instead of function calls)
            private constant boolean ARRAY_LOOKUP     = true
       
            // this only applies if ARRAY_LOOKUP is true
            private constant boolean HOOK_SAFETY      = false // disable for speed, but only use the struct to change name/color safely
       
            constant force FORCE_PLAYING = CreateForce()
       
            private string array Name
            private string array Hex
            private string array OriginalHex
            private playercolor array CurrentColor
        endglobals
    
        struct User extends array
         
            static constant integer NULL = bj_MAX_PLAYERS
           
            player handle
            integer id
            thistype next
            thistype prev
    
            string originalName
            boolean isPlaying
       
            static thistype first
            static thistype last
            static integer AmountPlaying = 0
            static playercolor array Color
    
            static thistype array PlayingPlayer
            static integer array PlayingPlayerIndex
       
            // similar to Player(#)
            static method fromIndex takes integer i returns thistype
                return thistype(i)
            endmethod
       
            static method operator [] takes player p returns thistype
                return thistype(GetPlayerId(p))
            endmethod
       
            method toPlayer takes nothing returns player
                return this.handle
            endmethod
         
            method operator name takes nothing returns string
                static if (ARRAY_LOOKUP) then
                    return Name[this]
                else
                    return GetPlayerName(this.handle)
                endif
            endmethod
       
            method operator name= takes string newName returns nothing
                call SetPlayerName(this.handle, newName)
                static if (ARRAY_LOOKUP) then
                    static if not (HOOK_SAFETY) then
                        set Name[this] = newName
                    endif
                endif
            endmethod
       
            method operator color takes nothing returns playercolor
                static if (ARRAY_LOOKUP) then
                    return CurrentColor[this]
                else
                    return GetPlayerColor(this.handle)
                endif
            endmethod
       
            method operator hex takes nothing returns string
                return OriginalHex[GetHandleId(this.color)]
            endmethod
       
            method operator color= takes playercolor c returns nothing
                call SetPlayerColor(this.handle, c)
           
                static if (ARRAY_LOOKUP) then
                    set CurrentColor[this] = c
                    static if not (HOOK_SAFETY) then
                        static if (AUTO_COLOR_UNITS) then
                            call this.colorUnits(color)
                        endif
                    endif
                endif
            endmethod
       
            method operator defaultColor takes nothing returns playercolor
                return Color[this]
            endmethod
       
            method operator nameColored takes nothing returns string
                return hex + this.name + "|r"
            endmethod
       
            method colorUnits takes playercolor c returns nothing
                local unit u
                local group ug = CreateGroup()
           
                call GroupEnumUnitsOfPlayer(ug, this.handle, null)
           
                loop
                    set u = FirstOfGroup(ug)
                    exitwhen u == null
                    call SetUnitColor(u, c)
                    call GroupRemoveUnit(ug, u)
                endloop

                call DestroyGroup(ug)
                set ug = null
            endmethod
       
            static method onLeave takes nothing returns boolean
                local thistype p  = thistype[GetTriggerPlayer()]
                local integer i   = .PlayingPlayerIndex[p.id - 1]
           
                // clean up
                call ForceRemovePlayer(FORCE_PLAYING, p.toPlayer())
                call DisplayTextToForce(FORCE_PLAYING, ( p.nameColored + " has left the game" ) )
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
                set .AmountPlaying = .AmountPlaying - 1
                set .PlayingPlayerIndex[i] = .PlayingPlayerIndex[.AmountPlaying]
                set .PlayingPlayer[i] = .PlayingPlayer[.AmountPlaying]
               
                if (.AmountPlaying == 1) then
                    set p.prev.next = User.NULL
                    set p.next.prev = User.NULL
                else
                    set p.prev.next = p.next
                    set p.next.prev = p.prev
                endif
    
                set .last = .PlayingPlayer[.AmountPlaying]
               
                set p.isPlaying = false

                return false
            endmethod
        endstruct

        function PlayerUtilsSetup takes nothing returns nothing
            local trigger t = CreateTrigger()
            local integer i = 0
            local player p

            set OriginalHex[0]  = "|cffff0303"
            set OriginalHex[1]  = "|cff0042ff"
            set OriginalHex[2]  = "|cff1ce6b9"
            set OriginalHex[3]  = "|cff540081"
            set OriginalHex[4]  = "|cfffffc01"
            set OriginalHex[5]  = "|cfffe8a0e"
            set OriginalHex[6]  = "|cff20c000"
            set OriginalHex[7]  = "|cffe55bb0"
            set OriginalHex[8]  = "|cff959697"
            set OriginalHex[9]  = "|cff7ebff1"
            set OriginalHex[10] = "|cff106246"
            set OriginalHex[11] = "|cff4e2a04"
            
            if (bj_MAX_PLAYERS > 12) then
                set OriginalHex[12] = "|cff9B0000"
                set OriginalHex[13] = "|cff0000C3"
                set OriginalHex[14] = "|cff00EAFF"
                set OriginalHex[15] = "|cffBE00FE"
                set OriginalHex[16] = "|cffEBCD87"
                set OriginalHex[17] = "|cffF8A48B"
                set OriginalHex[18] = "|cffBFFF80"
                set OriginalHex[19] = "|cffDCB9EB"
                set OriginalHex[20] = "|cff282828"
                set OriginalHex[21] = "|cffEBF0FF"
                set OriginalHex[22] = "|cff00781E"
                set OriginalHex[23] = "|cffA46F33"
            endif

            set User.first = User.NULL

            loop
                exitwhen i == bj_MAX_PLAYERS

                set p = Player(i)
            
                set User.Color[i] = GetPlayerColor(p)
                set CurrentColor[i] = User.Color[i]
                set Name[i] = GetPlayerName(p)
                
                if (GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then

                    set User.PlayingPlayer[User.AmountPlaying] = User(i)
                    set User.PlayingPlayerIndex[i] = User.AmountPlaying
                    
                    set User.last = i
                    
                    if (User.first == User.NULL) then
                        set User.first = i
                        set User(i).next = User.NULL
                        set User(i).prev = User.NULL
                    else
                        set User(i).prev = User(User.AmountPlaying - 1)
                        set User.PlayingPlayer[User.AmountPlaying - 1].next = User(i)
                        set User(i).next = User.NULL
                    endif

                    set User(i).handle = p
                    set User(i).id = i + 1
                    set User(i).isPlaying = true

                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_Tavern, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_Church, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_InfiniteStruggleCameraBounds, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_TownVision, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_Colosseum, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_Arena1, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_Arena2, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_Arena3, false, false))
                    call FogModifierStart(CreateFogModifierRect(p, FOG_OF_WAR_VISIBLE, gg_rct_Gods_Vision, false, false))
                
                    call TriggerRegisterPlayerEvent(t, p, EVENT_PLAYER_LEAVE)

                    call ForceAddPlayer(FORCE_PLAYING, p)
                    call ForceAddPlayer(hintplayers, p)
                
                    set Hex[User(i)] = OriginalHex[GetHandleId(User.Color[i])]
                
                    set User.AmountPlaying = User.AmountPlaying + 1
                endif
            
                set User(i).originalName = Name[i]
            
                set i = i + 1
            endloop
        
            call TriggerAddCondition(t, Filter(function User.onLeave))
        endfunction
    
        //===========================================================================
    
        static if (ARRAY_LOOKUP) then
            static if (HOOK_SAFETY) then
                private function SetPlayerNameHook takes player whichPlayer, string name returns nothing
                    set Name[GetPlayerId(whichPlayer)] = name
                endfunction
           
                private function SetPlayerColorHook takes player whichPlayer, playercolor color returns nothing
                    local User p = User[whichPlayer]
               
                    set Hex[p] = OriginalHex[GetHandleId(color)]
                    set CurrentColor[p] = color
               
                    static if (AUTO_COLOR_UNITS) then
                        call p.colorUnits(color)
                    endif
                endfunction
           
                hook SetPlayerName SetPlayerNameHook
                hook SetPlayerColor SetPlayerColorHook
            endif 
        endif
    
endlibrary