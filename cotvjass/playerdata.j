library PlayerData requires TimerUtils, PlayerManager, Functions, CodeGen

    globals
        constant integer MAX_TIME_PLAYED = 1000000 //max minutes - 16666 hours
        constant integer MAX_PLAT_ARC_CRYS = 100000
        constant integer MAX_GOLD_LUMB = 10000000
        constant integer MAX_PHTL = 4000000 
        constant integer MAX_UPGRADE_LEVEL = 10
        constant integer MAX_STATS = 250000
        constant integer MAX_SLOTS = 29
        constant integer MAX_INVENTORY_SLOTS = 24

        constant integer KEY_PROFILE = 0
        constant integer KEY_CHARACTER = 1

        integer array VARIATION_FLAG

        dialog array LoadDialog
        button array LoadDialogButton
        integer array loadPage
        integer array loadCounter
        boolean newSlotFlag = false
        boolean array deleteMode
        integer array loadSlotCounter

        boolean array newcharacter
        boolean array LEFT_CHURCH

        //boolean LOAD_SAFE = true

        hashtable SaveData = InitHashtable()
    endglobals

    struct HeroData
        integer pid
        integer str
        integer agi
        integer int
        integer teleport
        integer reveal
        Item array items[30] //6 extra for temp storage
        
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

        integer skin = 26 //wisp backpack

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
                exitwhen i == MAX_INVENTORY_SLOTS
                if isImportantItem(.items[i].obj) then
                    call Item.assign(CreateItemLoc(.items[i].id, TownCenter))
                endif
                call .items[i].destroy()
                set .items[i] = 0

                set i = i + 1
            endloop
        endmethod

        static method create takes integer id returns HeroData
            local HeroData hero = HeroData.allocate()

            set hero.pid = id

            return hero
        endmethod

        method onDestroy takes nothing returns nothing
            call wipeData()
        endmethod
    endstruct

    struct Profile
        integer pid 
        integer currentSlot
        integer profileHash

        integer array phtl[30]
        HeroData hero
        boolean NEW = true

        static integer array id[10]
        static trigger sync_event = CreateTrigger()
        static string array savecode[PLAYER_CAP]

        method operator skin= takes integer id returns nothing
            set hero.skin = id

            call BlzSetUnitSkin(Backpack[pid], skinID[id])
            if skinID[id] == 'H02O' then
                call AddUnitAnimationProperties(Backpack[pid], "alternate", true)
            endif
        endmethod

        static method operator [] takes integer i returns thistype
            return Profile(thistype.id[i])
        endmethod

        static method create takes integer pid returns thistype
            local thistype p = thistype.allocate()

            set thistype.id[pid] = p
            set p.currentSlot = 0
            set p.hero = HeroData.create(pid)
            set p.profileHash = GetRandomInt(500000, 510000)
            set p.pid = pid

            return p
        endmethod

        static method load takes string s, integer pid returns thistype
            local thistype profile
            local integer i = 0
            local integer id = 0
            local integer prestige = 0
            local integer index = 0
            local integer vers = 0
            local player p = Player(pid - 1)

            //fail to load
            if not Load(s, p) then
                call DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                set p = null
                return 0
            endif

            set vers = LoadInteger(SaveData, pid, index)

            //TODO implement version handling
            if vers <= SAVE_LOAD_VERSION - 2 or vers >= SAVE_LOAD_VERSION + 2 then
                call DisplayTimedTextToPlayer(p, 0, 0, 30., "Profile data corrupt or version mismatch!")
                set p = null
                return 0
            endif

            set profile = thistype.create(pid)
            set profile.NEW = false

            call DEBUGMSG("Save Load Version: " + I2S(LoadInteger(SaveData, pid, index)))

            set index = index + 1

            loop
                exitwhen i > MAX_SLOTS
                set profile.phtl[i] = LoadInteger(SaveData, pid, index)
                //
                //set hardcore = BlzBitAnd(profile.phtl[i], POWERSOF2[0])
                set prestige = BlzBitAnd(profile.phtl[i], POWERSOF2[1] + POWERSOF2[2]) / POWERSOF2[1]
                set id = BlzBitAnd(profile.phtl[i], POWERSOF2[3] + POWERSOF2[4] + POWERSOF2[5] + POWERSOF2[6] + POWERSOF2[7] + POWERSOF2[8]) / POWERSOF2[3]
                //set lvl = BlzBitAnd(profile.phtl[i], POWERSOF2[9] + POWERSOF2[10] + POWERSOF2[11] + POWERSOF2[12] + POWERSOF2[13] + POWERSOF2[14] + POWERSOF2[15] + POWERSOF2[16] + POWERSOF2[17] + POWERSOF2[18])
                //
                set index = index + 1

                if prestige > 0 then
                    call AllocatePrestige(pid, prestige, id)
                endif
                //call DEBUGMSG(I2S(profile.phtl[i]))

                set i = i + 1
            endloop 

            set profile.profileHash = LoadInteger(SaveData, pid, index)

            set p = null

            return profile
        endmethod

        static method LoadSync takes nothing returns boolean
            local integer pid = GetPlayerId(GetTriggerPlayer()) + 1

            set thistype.savecode[pid - 1] = BlzGetTriggerSyncData()

            if StringLength(thistype.savecode[pid - 1]) > 1 then
                if Profile[pid] == 0 then
                    call Profile[pid].load(thistype.savecode[pid - 1], pid)
                else
                    call Profile[pid].loadCharacter(thistype.savecode[pid - 1])
                endif
            endif

            return false
        endmethod

        method getSlotsUsed takes nothing returns integer
            local integer i = 0
            local integer i2 = 0

            loop
                exitwhen i > MAX_SLOTS

                if phtl[i] > 0 then
                    set i2 = i2 + 1
                endif

                set i = i + 1
            endloop

            return i2
        endmethod

        method saveProfile takes nothing returns nothing
            local integer i = 0
            local string s = ""
            local player p = Player(pid - 1)
            local integer index = 0

            call SaveInteger(SaveData, pid, index, SAVE_LOAD_VERSION)
            set index = index + 1

            loop
                exitwhen i > MAX_SLOTS

                if i == .currentSlot then
                    if deleteMode[pid] then
                        set .phtl[i] = 0
                    else
                        set .phtl[i] = .hero.hardcore + .hero.prestige * POWERSOF2[1] + hero.id * POWERSOF2[3] + hero.level * POWERSOF2[9]
                    endif
                    //call DEBUGMSG(I2S(.hero.prestige) + " " + I2S(.hero.hardcore) + " " + I2S(.hero.id) + " " + I2S(.hero.level))
                endif
              
                call SaveInteger(SaveData, pid, index, .phtl[i])
                set index = index + 1

                set i = i + 1
            endloop

            call SaveInteger(SaveData, pid, index, .profileHash)
            set SAVECOUNT[pid] = index

            set s = Compile(pid)

            if GetLocalPlayer() == Player(.pid - 1) then
                call FileIO_Write(MAP_NAME + "\\" + User[p].name + "\\" + "profile.pld", "\n" + s)
                call FileIO_Write(MAP_NAME + "\\" + "BACKUP" + "\\" + GetObjectName(HeroID[pid]) + I2S(GetHeroLevel(Hero[pid])) + "_" + I2S(TIME) + "\\" + User[p].name + "\\" + "profile.pld", "\n" + s)
            endif

            call DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------")
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Your data has been saved successfully. (Warcraft III\\CustomMapData\\CoT Nevermore\\" + GetPlayerName(p) + ")")
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Use|r -load |cffffcc00the next time you play to load your hero.")
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffFF0000YOU MUST RESTART WARCRAFT BEFORE LOADING AGAIN!|r")
            call DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------")

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
                        id
                        quality
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
            call SaveInteger(SaveData, pid, index, .hero.prestige)
            set index = index + 1
            if udg_Hardcore[pid] == true then
                set .hero.hardcore = 1
            else
                set .hero.hardcore = 0
            endif
            call SaveInteger(SaveData, pid, index, .hero.hardcore)
            set index = index + 1
            set .hero.id = LoadInteger(SAVE_TABLE, KEY_UNITS, HeroID[pid])
            call SaveInteger(SaveData, pid, index, .hero.id)
            set index = index + 1
            set .hero.level = GetHeroLevel(Hero[pid])
            call SaveInteger(SaveData, pid, index, .hero.level)
            set index = index + 1
            set .hero.str = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_STR, Hero[pid], false))
            set .hero.agi = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_AGI, Hero[pid], false))
            set .hero.int = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_INT, Hero[pid], false))
            call SaveInteger(SaveData, pid, index, .hero.str)
            set index = index + 1
            call SaveInteger(SaveData, pid, index, .hero.agi)
            set index = index + 1
            call SaveInteger(SaveData, pid, index, .hero.int)
            set index = index + 1
            loop
                exitwhen i == MAX_INVENTORY_SLOTS
                call SaveInteger(SaveData, pid, index, .hero.items[i].encode_id())
                set index = index + 1
                call SaveInteger(SaveData, pid, index, .hero.items[i].encode())
                set index = index + 1
                set .hero.items[i].owner = p
                set i = i + 1
            endloop
            set .hero.teleport = GetUnitAbilityLevel(Backpack[pid], 'A0FV')
            call SaveInteger(SaveData, pid, index, .hero.teleport)
            set index = index + 1
            set .hero.reveal = GetUnitAbilityLevel(Backpack[pid], 'A0FK')
            call SaveInteger(SaveData, pid, index, .hero.reveal)
            set index = index + 1
            set .hero.platinum = IMinBJ(GetCurrency(pid, PLATINUM), MAX_PLAT_ARC_CRYS)
            call SaveInteger(SaveData, pid, index, .hero.platinum)
            set index = index + 1
            set .hero.arcadite = IMinBJ(GetCurrency(pid, ARCADITE), MAX_PLAT_ARC_CRYS)
            call SaveInteger(SaveData, pid, index, .hero.arcadite)
            set index = index + 1
            set .hero.crystal = IMinBJ(GetCurrency(pid, CRYSTAL), MAX_PLAT_ARC_CRYS)
            call SaveInteger(SaveData, pid, index, .hero.crystal)
            set index = index + 1
            set .hero.time = IMinBJ(udg_TimePlayed[pid], MAX_TIME_PLAYED)
            call SaveInteger(SaveData, pid, index, .hero.time)
            set index = index + 1
            set .hero.gold = IMinBJ(GetCurrency(pid, GOLD), MAX_GOLD_LUMB)
            call SaveInteger(SaveData, pid, index, .hero.gold)
            set index = index + 1
            set .hero.lumber = IMinBJ(GetCurrency(pid, LUMBER), MAX_GOLD_LUMB)
            call SaveInteger(SaveData, pid, index, .hero.lumber)
            set index = index + 1
            call SaveInteger(SaveData, pid, index, .hero.skin)
            set SAVECOUNT[pid] = index

            set s = Compile(pid)

            if GetLocalPlayer() == p then
                call FileIO_Write(MAP_NAME + "\\" + User[p].name + "\\slot" + I2S(.currentSlot + 1) + ".pld", GetObjectName(HeroID[pid]) + " " + I2S(GetHeroLevel(Hero[pid])) + "\n" + s)
                call FileIO_Write(MAP_NAME + "\\" + "BACKUP" + "\\" + GetObjectName(HeroID[pid]) + I2S(GetHeroLevel(Hero[pid])) + "_" + I2S(TIME) + "\\" + User[p].name + "\\slot" + I2S(.currentSlot + 1) + ".pld", GetObjectName(HeroID[pid]) + " " + I2S(GetHeroLevel(Hero[pid])) + "\n" + s)
            endif

            call Profile[pid].saveProfile()

            set p = null
        endmethod

        method loadCharacter takes string data returns nothing
            local integer i = 0
            local integer i2 = 0
            local integer hash = 0
            local player p = Player(pid - 1)
            local integer index = 0
            local integer hardcore = 0
            local integer id = 0
            local integer prestige = 0
            local integer herolevel = 0

            if not Load(data, p) then
                call DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                set p = null
                return
            endif

            set hash = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.prestige = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.hardcore = LoadInteger(SaveData, pid, index) 
            set index = index + 1 
            set hero.id = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.level = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.str = IMinBJ(MAX_STATS, LoadInteger(SaveData, pid, index))
            set index = index + 1 
            set hero.agi = IMinBJ(MAX_STATS, LoadInteger(SaveData, pid, index))
            set index = index + 1 
            set hero.int = IMinBJ(MAX_STATS, LoadInteger(SaveData, pid, index))
            set index = index + 1 
            loop
                exitwhen i == MAX_INVENTORY_SLOTS
                set hero.items[i] = Item.decode_id(LoadInteger(SaveData, pid, index))
                set index = index + 1 
                if hero.items[i] != 0 then
                    set .hero.items[i].owner = p
                    call hero.items[i].decode(LoadInteger(SaveData, pid, index))
                endif
                set index = index + 1
                set i = i + 1
            endloop
            set hero.teleport = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.reveal = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.platinum = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.arcadite = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.crystal = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.time = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.gold = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.lumber = LoadInteger(SaveData, pid, index)
            set index = index + 1 
            set hero.skin = LoadInteger(SaveData, pid, index)

            set hardcore = BlzBitAnd(.phtl[.currentSlot], POWERSOF2[0])
            set prestige = BlzBitAnd(.phtl[.currentSlot], POWERSOF2[1] + POWERSOF2[2]) / POWERSOF2[1]
            set id = BlzBitAnd(.phtl[.currentSlot], POWERSOF2[3] + POWERSOF2[4] + POWERSOF2[5] + POWERSOF2[6] + POWERSOF2[7] + POWERSOF2[8]) / POWERSOF2[3]
            set herolevel = BlzBitAnd(.phtl[.currentSlot], POWERSOF2[9] + POWERSOF2[10] + POWERSOF2[11] + POWERSOF2[12] + POWERSOF2[13] + POWERSOF2[14] + POWERSOF2[15] + POWERSOF2[16] + POWERSOF2[17] + POWERSOF2[18]) / POWERSOF2[9]

            //call DEBUGMSG(I2S(hero.prestige) + " " + I2S(hero.hardcore) + " " + I2S(hero.id) + " " + I2S(hero.level)) 
            //call DEBUGMSG(I2S(prestige) + " " + I2S(hardcore) + " " + I2S(id) + " " + I2S(herolevel)) 
            
            //TODO remove herolevel mismatch?
            if (hash != profileHash) or (prestige != hero.prestige) or (hardcore != hero.hardcore) or (id != hero.id) or (herolevel != hero.level) then
                call DisplayTextToPlayer(p, 0, 0, "Invalid character data!")
                call hero.wipeData()
                call DisplayHeroSelectionDialog(pid)
                set p = null
                return
            endif

            call CharacterSetup(pid, true)

            set p = null
        endmethod

        method onDestroy takes nothing returns nothing
            local integer i = 0

            set .pid = 0
            set .currentSlot = 0
            set .profileHash = 0

            loop
                exitwhen i > MAX_SLOTS

                set .phtl[i] = 0

                set i = i + 1
            endloop

            call .hero.destroy()
        endmethod
    endstruct
    
    /*example creation*/
    //local PlayerTimer pt

    //set pt = TimerList[User.ID].addTimer(pid) 

    //call TimerStart(pt.timer, #, #, #, #)

    /*example data grab*/
    //local integer pid = GetTimerData(GetExpiredTimer())
    //local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    //local real dmg = pt.dmg

    /*example cleanup*/
    //call TimerList[pid].removePlayerTimer(pt)

    struct PlayerTimer
        timer timer = null

        integer pid = 0
        integer tpid = 0
        integer agi = 0
        integer str = 0
        integer int = 0
        integer tag = 0
        integer i = 0

        real time = 0.
        real x = 0.
        real y = 0.
        real x2 = 0.
        real y2 = 0.
        real dur = 0.
        real dmg = 0.
        real armor = 0.
        real aoe = 0.
        real angle = 0.
        real speed = 0.

        unit caster = null
        unit target = null
        group ug = null
        effect sfx = null

        Spell spell = 0

        thistype prev = 0
        thistype next = 0

        static method create takes integer pid returns thistype
            local thistype pt = thistype.allocate()

            set pt.timer = NewTimerEx(pid)
            set pt.prev = 0
            set pt.next = 0
            set pt.tag = 0

            return pt
        endmethod

        method onDestroy takes nothing returns nothing
            call DestroyGroup(ug)
            call DestroyEffect(sfx)
            call spell.destroy()

            set pid = 0
            set tpid = 0
            set agi = 0
            set str = 0
            set int = 0
            set i = 0
            set time = 0.
            set x = 0.
            set y = 0.
            set x2 = 0.
            set y2 = 0.
            set dur = 0.
            set dmg = 0.
            set armor = 0.
            set aoe = 0.
            set angle = 0.
            set speed = 0.
            set tag = 0
            set spell = 0
            set caster = null
            set target = null
            set ug = null
            set sfx = null

            call ReleaseTimer(.timer)
        endmethod
    endstruct

    struct TimerList extends array
        PlayerTimer head
        PlayerTimer tail

        method getTimerFromHandle takes timer t returns PlayerTimer pt
            local PlayerTimer node = .head

            loop
                exitwhen node.timer == t
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

        method get takes unit caster, unit target, integer tag returns PlayerTimer
            local PlayerTimer node = .head

            loop
                exitwhen node == 0

                if (node.caster == caster or caster == null) and (node.target == target or target == null) and node.tag == tag then
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
        local User u = User.first

        loop
            exitwhen u == User.NULL

            set LoadDialog[u.id] = DialogCreate()
            call TriggerRegisterDialogEvent(buttonTrigger, LoadDialog[u.id])

            set u = u.next
        endloop

        call TriggerAddCondition(buttonTrigger, Filter(function onLoadButtonClick))

        set buttonTrigger = null
    endfunction

endlibrary
