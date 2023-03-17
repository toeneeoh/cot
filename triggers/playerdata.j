library PlayerData requires TimerUtils, PlayerManager, Functions, CodeGen

    globals
        constant integer MAX_TIME_PLAYED = 1000000 //max minutes - 16666 hours
        constant integer MAX_PLAT_ARC_CRYS = 100000
        constant integer MAX_GOLD_LUMB = 10000000
        constant integer MAX_PHTL = 4000000 
        constant integer MAX_UPGRADE_LEVEL = 10
        constant integer MAX_STATS = 250000

        constant integer KEY_PROFILE = 0
        constant integer KEY_CHARACTER = 1

        dialog array LoadDialog
        button array LoadDialogButton
        integer array loadPage
        integer array loadCounter
        boolean newSlotFlag = false
        boolean array deleteMode
        integer array loadSlotCounter
        Profile array Profiles

        hashtable SaveData = InitHashtable()
    endglobals

    function CodeReload takes nothing returns boolean
        call ExecuteFunc("JHCR_Init_parse")
        return false
    endfunction
    
    struct HeroData
        integer str
        integer agi
        integer int
        integer teleport
        integer reveal
        item array items[24]
        
        integer gold
        integer lumber
        integer platinum
        integer arcadite
        integer crystal
        integer time

        integer id
        integer level
        integer hardcore
        integer prestige

        method wipeData takes nothing returns nothing
            local integer i = 0

            set .str = 0
            set .agi = 0
            set .int = 0
            set .teleport = 0
            set .reveal = 0
            set .gold = 0
            set .lumber = 0
            set .platinum = 0
            set .arcadite = 0
            set .crystal = 0
            set .time = 0
            set .id = 0
            set .level = 0
            set .hardcore = 0
            set .prestige = 0
            
            loop
                exitwhen i > 23
                call RemoveItem(.items[i])

                set i = i + 1
            endloop
        endmethod

        static method create takes nothing returns HeroData
            local HeroData hd = HeroData.allocate()

            return hd
        endmethod

        method onDestroy takes nothing returns nothing
            call wipeData()
        endmethod
    endstruct

    struct Profile
        integer pid 
        integer currentSlot
        integer profileHash
        integer pageIndex

        integer array phtl[30]
        HeroData hd

        static method create takes nothing returns thistype
            local thistype p = thistype.allocate()
            local integer i = 0

            set p.pid = 0
            set p.currentSlot = 0
            set p.profileHash = 0
            set p.pageIndex = 0
            set p.hd = HeroData.create()

            loop
                exitwhen i > 29

                set p.phtl[i] = 0

                set i = i + 1
            endloop

            return p
        endmethod

        method getSlotsUsed takes nothing returns integer
            local integer i = 0
            local integer i2 = 0

            loop
                exitwhen i > 29

                if phtl[i] > 1000000 then
                    set i2 = i2 + 1
                endif

                set i = i + 1
            endloop

            return i2
        endmethod

        method createRandomHash takes nothing returns nothing
            set .profileHash = GetRandomInt(1000, 9999)
        endmethod

        method saveProfile takes nothing returns nothing
            local integer i = 0
            local string s = ""
            local player p = Player(pid - 1)
            local integer index = 0

            call SaveInteger(SaveData, pid, index, SAVE_LOAD_VERSION)
            set index = index + 1

            loop
                exitwhen i > 29 //max slots

                if i == .currentSlot then
                    if deleteMode[pid] then
                        set .phtl[i] = 0 
                    else
                        set .phtl[i] = S2I(I2S(.hd.prestige + 1) + I2S(.hd.hardcore + 1) + I2S(.hd.id + 10) + I2S(.hd.level + 100))
                    endif
                    call DEBUGMSG(I2S(.hd.prestige) + " " + I2S(.hd.hardcore) + " " + I2S(.hd.id) + " " + I2S(.hd.level))
                endif
              
                call SaveInteger(SaveData, pid, index, phtlToValue(.phtl[i], 0))
                set index = index + 1
                call SaveInteger(SaveData, pid, index, phtlToValue(.phtl[i], 1))
                set index = index + 1
                call SaveInteger(SaveData, pid, index, phtlToValue(.phtl[i], 2))
                set index = index + 1
                call SaveInteger(SaveData, pid, index, phtlToValue(.phtl[i], 3))
                set index = index + 1

                set i = i + 1
            endloop

            call SaveInteger(SaveData, pid, index, .profileHash)
            set SAVECOUNT[pid] = index

            set s = Compile(pid)

            if GetLocalPlayer() == Player(.pid - 1) then
                call FileIO_Write(udg_MapName + "\\" + User[p].name + "\\" + "profile.pld", "\n" + s)
                call FileIO_Write(udg_MapName + "\\" + "BACKUP" + "\\" + GetObjectName(HeroID[pid]) + I2S(GetHeroLevel(Hero[pid])) + "_" + I2S(TIME) + "\\" + User[p].name + "\\" + "profile.pld", "\n" + s)
            endif

            call DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------" )
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Your data has been saved successfully. (Warcraft III\\CustomMapData\\CoT Nevermore 1.33.19)")
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Use|r -load |cffffcc00the next time you play to load your hero.")
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffFF0000YOU MUST RESTART WARCRAFT BEFORE LOADING AGAIN!|r")
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------" )

            set p = null
        endmethod

        method saveCharacter takes nothing returns nothing
            local integer i = 0
            local string s = ""
            local player p = Player(pid - 1)
            local integer index = 0
            
            //order
            /*
                hero
                    id, level, str, agi, int
                    item x24
                teleport
                reveal
                platinum
                arcadite
                crystal
                gold
                lumber
            */

            call SaveInteger(SaveData, pid, index, .profileHash)
            set index = index + 1
            call SaveInteger(SaveData, pid, index, .hd.prestige)
            set index = index + 1
            if udg_Hardcore[pid] == true then
                set .hd.hardcore = 1
            else
                set .hd.hardcore = 0
            endif
            call SaveInteger(SaveData, pid, index, .hd.hardcore)
            set index = index + 1
            set .hd.id = ConvertUnitId(HeroID[pid])
            call SaveInteger(SaveData, pid, index, .hd.id)
            set index = index + 1
            set .hd.level = GetHeroLevel(Hero[pid])
            call SaveInteger(SaveData, pid, index, .hd.level)
            set index = index + 1
            set .hd.str = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_STR, Hero[pid], false))
            set .hd.agi = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_AGI, Hero[pid], false))
            set .hd.int = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_INT, Hero[pid], false))
            call SaveInteger(SaveData, pid, index, .hd.str)
            set index = index + 1
            call SaveInteger(SaveData, pid, index, .hd.agi)
            set index = index + 1
            call SaveInteger(SaveData, pid, index, .hd.int)
            set index = index + 1
            call StoreItems(pid)
            loop
                exitwhen i > 23
                call SaveInteger(SaveData, pid, index, ItemIndexer(.hd.items[i]))
                set index = index + 1
                call BindItem(.hd.items[i], pid)
                set i = i + 1
            endloop
            set .hd.teleport = GetUnitAbilityLevel(Backpack[pid], 'A0FV')
            call SaveInteger(SaveData, pid, index, .hd.teleport)
            set index = index + 1
            set .hd.reveal = GetUnitAbilityLevel(Backpack[pid], 'A0FK')
            call SaveInteger(SaveData, pid, index, .hd.reveal)
            set index = index + 1
            set .hd.platinum = IMinBJ(udg_Plat_Gold[pid], MAX_PLAT_ARC_CRYS)
            call SaveInteger(SaveData, pid, index, .hd.platinum)
            set index = index + 1
            set .hd.arcadite = IMinBJ(udg_Arca_Wood[pid], MAX_PLAT_ARC_CRYS)
            call SaveInteger(SaveData, pid, index, .hd.arcadite)
            set index = index + 1
            set .hd.crystal = IMinBJ(udg_Crystals[pid], MAX_PLAT_ARC_CRYS)
            call SaveInteger(SaveData, pid, index, .hd.crystal)
            set index = index + 1
            set .hd.time = IMinBJ(udg_TimePlayed[pid], MAX_TIME_PLAYED)
            call SaveInteger(SaveData, pid, index, .hd.time)
            set index = index + 1
            set .hd.gold = IMinBJ(GetPlayerGold(p), MAX_GOLD_LUMB)
            call SaveInteger(SaveData, pid, index, .hd.gold)
            set index = index + 1
            set .hd.lumber = IMinBJ(GetPlayerLumber(p), MAX_GOLD_LUMB)
            call SaveInteger(SaveData, pid, index, .hd.lumber)
            set SAVECOUNT[pid] = index

            set s = Compile(pid)

            if GetLocalPlayer() == p then
                call FileIO_Write(udg_MapName + "\\" + User[p].name + "\\slot" + I2S(.currentSlot + 1) + ".pld", GetObjectName(HeroID[pid]) + " " + I2S(GetHeroLevel(Hero[pid])) + "\n" + s)
                call FileIO_Write(udg_MapName + "\\" + "BACKUP" + "\\" + GetObjectName(HeroID[pid]) + I2S(GetHeroLevel(Hero[pid])) + "_" + I2S(TIME) + "\\" + User[p].name + "\\slot" + I2S(.currentSlot + 1) + ".pld", GetObjectName(HeroID[pid]) + " " + I2S(GetHeroLevel(Hero[pid])) + "\n" + s)
            endif

            call Profiles[pid].saveProfile()

            set p = null
        endmethod

        method loadProfile takes string data returns nothing
            local integer i = 0
            local integer prestige
            local integer hardcore
            local integer id
            local integer lvl
            local player p = Player(pid - 1)
            local integer index = 0

            if not Load(data, p) then
                call DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                set p = null
                return
            endif
 
            /*
                prestige
                hardcore
                id
                lvl
                x30
                hash
            */
            call DEBUGMSG(I2S(LoadInteger(SaveData, pid, index)))
            if LoadInteger(SaveData, pid, index) != SAVE_LOAD_VERSION then
                call DisplayTimedTextToPlayer(p, 0, 0, 30., "Invalid profile data!")
                set p = null
                return
            endif

            set index = index + 1

            loop
                exitwhen i > 29
                set prestige = LoadInteger(SaveData, pid, index)
                set index = index + 1
                set hardcore = LoadInteger(SaveData, pid, index)
                set index = index + 1
                set id = LoadInteger(SaveData, pid, index)
                set index = index + 1
                set lvl = LoadInteger(SaveData, pid, index)
                set index = index + 1

                if id > 0 and lvl > 0 then
                    set phtl[i] = S2I(I2S(prestige + 1) + I2S(hardcore + 1) + I2S(id + 10) + I2S(lvl + 100))
                endif
                if prestige > 0 then
                    call AllocatePrestige(pid, prestige, id)
                endif
                call DEBUGMSG(I2S(phtl[i]))

                set i = i + 1
            endloop 

            set .profileHash = LoadInteger(SaveData, pid, index)

            call DisplayHeroSelectionDialog(pid)

            set p = null
        endmethod

        method loadCharacter takes string data returns nothing
            local integer i = 0
            local integer i2 = 0
            local integer hash = 0
            local player p = Player(pid - 1)
            local integer index = 0

            if not Load(data, p) then
                call DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                set p = null
                return
            endif

            set hash = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.prestige = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.hardcore = LoadInteger(SaveData, pid, index) 
            set index = index + 1 
            set hd.id = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.level = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.str = IMinBJ(MAX_STATS, LoadInteger(SaveData, pid, index))
            set index = index + 1 
            set hd.agi = IMinBJ(MAX_STATS, LoadInteger(SaveData, pid, index))
            set index = index + 1 
            set hd.int = IMinBJ(MAX_STATS, LoadInteger(SaveData, pid, index))
            set index = index + 1 
            loop
                exitwhen i > 23
                set i2 = LoadInteger(SaveData, pid, index)
                set index = index + 1 
                if i2 > 0 then
                    set hd.items[i] = CreateItem(udg_SaveItemType[i2], 30000, 30000)
                    call BindItem(hd.items[i], pid)
                    call SetItemVisible(hd.items[i], false)
                endif
                set i = i + 1
            endloop
            set hd.teleport = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.reveal = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.platinum = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.arcadite = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.crystal = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.time = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.gold = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hd.lumber = LoadInteger(SaveData, pid, index)

            call DEBUGMSG(I2S(hd.prestige) + " " + I2S(hd.hardcore) + " " + I2S(hd.id) + " " + I2S(hd.level)) 
            call DEBUGMSG(I2S(phtlToValue(phtl[currentSlot], 0)) + " " + I2S(phtlToValue(phtl[currentSlot], 1)) + " " + I2S(phtlToValue(phtl[currentSlot], 2)) + " " + I2S(phtlToValue(phtl[currentSlot], 3))) 
            if (hash != profileHash) or (phtlToValue(phtl[currentSlot], 0) != hd.prestige) or (phtlToValue(phtl[currentSlot], 1) != hd.hardcore) or (phtlToValue(phtl[currentSlot], 2) != hd.id) or (phtlToValue(phtl[currentSlot], 3) != hd.level) then
                call DisplayTextToPlayer(p, 0, 0, "Invalid character data!" )
                call hd.wipeData()
                call DisplayHeroSelectionDialog(pid)
                set p = null
                return
            endif

            call CharacterSetup(pid, true)

            set p = null
        endmethod
    endstruct
    
    /*example creation*/
    //local PlayerTimer pt

    //set pt = TimerList[User.ID].addTimer(pid) 

    //call TimerStart(pt.getTimer(), #, #, #, #)

    /*example data grab*/
    //local integer pid = GetTimerData(GetExpiredTimer())
    //local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    //local real dmg = pt.dmg

    /*example cleanup*/
    //call TimerList[pid].removePlayerTimer(pt)

    struct PlayerTimer
        timer PTimer

        integer pid
        integer tpid
        integer agi
        integer str
        integer int
        real x
        real y
        real dur
        real dmg
        real armor
        real aoe
        real angle
        real speed
        unit caster
        unit target
        group ug
        effect sfx

        integer tag

        thistype prev
        thistype next

        method getTimerRemaining takes nothing returns real
            return TimerGetRemaining(.PTimer)
        endmethod

        method getTimer takes nothing returns timer
            return .PTimer
        endmethod

        static method create takes integer pid returns thistype
            local thistype pt = thistype.allocate()

            set pt.PTimer = NewTimerEx(pid)
            set pt.prev = 0
            set pt.next = 0
            set pt.tag = 0

            return pt
        endmethod

        method onDestroy takes nothing returns nothing
            call DestroyGroup(ug)
            call DestroyEffect(sfx)

            set pid = 0
            set tpid = 0
            set agi = 0
            set str = 0
            set int = 0
            set x = 0.
            set y = 0.
            set dur = 0.
            set dmg = 0.
            set armor = 0.
            set aoe = 0.
            set angle = 0.
            set speed = 0.
            set tag = 0
            set caster = null
            set target = null
            set ug = null
            set sfx = null

            call ReleaseTimer(.PTimer)
        endmethod

    endstruct

    struct TimerList extends array
        PlayerTimer head
        PlayerTimer tail

        method getTimerFromHandle takes timer t returns PlayerTimer pt
            local PlayerTimer node = .head

            loop
                exitwhen node.getTimer() == t
                exitwhen node == 0

                set node = node.next
            endloop

            return node
        endmethod

        method removePlayerTimer takes PlayerTimer pt returns nothing
            if pt == .head and pt == .tail then
                set .head = 0
                set .tail = 0
            elseif pt == .head then
                set .head = .head.next
                set .head.prev = 0
            elseif pt == .tail then
                set .tail.prev.next = 0
                set .tail = .tail.prev
            else
                set pt.prev.next = pt.next
                set pt.next.prev = pt.prev
            endif

            call pt.destroy()
        endmethod

        method getTimerWithTargetTag takes unit target, integer tag returns PlayerTimer
            local PlayerTimer node = .head

            loop
                exitwhen node == 0

                if node.target == target and node.tag == tag then
                    return node
                endif

                set node = node.next
            endloop

            return 0
        endmethod

        method hasTimerWithTag takes integer tag returns boolean
            local PlayerTimer node = .head

            loop
                exitwhen node == 0

                if node.tag == tag then
                    return true
                endif

                set node = node.next
            endloop

            return false
        endmethod

        method stopAllTimersWithTag takes integer tag returns nothing
            local PlayerTimer node = .head
            local PlayerTimer tempnode = .head

            loop
                exitwhen node == 0
                set tempnode = tempnode.next

                if node.tag == tag then
                    call removePlayerTimer(node)
                endif

                set node = tempnode
            endloop
        endmethod

        method stopAllTimers takes nothing returns nothing
            local PlayerTimer node = .head

            loop
                exitwhen node == 0

                call node.destroy()

                set node = node.next
            endloop

            set .head = 0
            set .tail = 0
        endmethod

        method addTimer takes integer pid returns PlayerTimer
            local PlayerTimer pt = PlayerTimer.create(pid)

            if .head == 0 then
                set .head = pt
                set .tail = pt
            else
                set .tail.next = pt
                set pt.prev = .tail
                set .tail = .tail.next
            endif

            return pt
        endmethod
    endstruct

    function PlayerDataSetup takes nothing returns nothing
        local trigger buttonTrigger = CreateTrigger()
        local trigger keyPress = CreateTrigger()
        local User u = User.first
        local integer pid

        loop
            exitwhen u == User.NULL
            set pid = u.id

            set Profiles[pid] = Profile.create()
            set Profiles[pid].pid = pid
            set LoadDialog[pid] = DialogCreate()
            call TriggerRegisterDialogEvent(buttonTrigger, LoadDialog[pid])
            call BlzTriggerRegisterPlayerKeyEvent(keyPress, u.toPlayer(), OSKEY_ESCAPE, 0, true)

            set u = u.next
        endloop

        call TriggerAddCondition(buttonTrigger, Filter(function onLoadButtonClick))
        call TriggerAddCondition(keyPress, Filter(function CodeReload))

        set buttonTrigger = null
        set keyPress = null
    endfunction

endlibrary
