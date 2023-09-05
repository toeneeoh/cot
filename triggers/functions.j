library Functions uses TimerUtils, TimedHandles, TerrainPathability

globals
    string SYNC_PREFIX = "S"
    integer indc = 0
    unit array DUMMY_LIST
    group DUMMY_STACK = CreateGroup()
    integer DUMMY_COUNT = 0
    real DUMMY_RECYCLE_TIME = 5.
    unit TEMP_DUMMY
    multiboard MULTI_BOARD
    integer ColoPlayerCount = 0
    boolean BOOST_OFF = false
    integer callbackCount = 0
    integer array passedValue
    real array BaseExperience
    integer array POWERSOF2
endglobals

function B2I takes boolean b returns integer
    if b then
        return 1
    endif

    return 0
endfunction

function DEBUGMSG takes string s returns nothing
    static if LIBRARY_dev then
        if COUNT_DEBUG then
            set DEBUG_COUNT = DEBUG_COUNT + 1
            call DisplayTimedTextToForce(FORCE_PLAYING, 30., I2S(DEBUG_COUNT))
        else
            call DisplayTimedTextToForce(FORCE_PLAYING, 30., s)
        endif
    endif
endfunction

function GetUnitOrderValue takes unit u returns integer
    //heroes use the handleId
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHandleId(u)
    else
    //units use unitCode
        return GetUnitTypeId(u)
    endif
endfunction

function FilterFunction takes nothing returns boolean
    local unit u = GetFilterUnit()
    local real prio = BlzGetUnitRealField(u, UNIT_RF_PRIORITY)
    local boolean found = false
    local integer loopA = 1
    local integer loopB = 0

    loop
        exitwhen loopA > unitsCount
        if BlzGetUnitRealField(units[loopA], UNIT_RF_PRIORITY) < prio then
            set unitsCount = unitsCount + 1
            set loopB = unitsCount
            loop
                exitwhen loopB <= loopA
                set units[loopB] = units[loopB - 1]
                set loopB = loopB - 1
            endloop
            set units[loopA] = u
            set found = true
            exitwhen true
        //equal prio and better colisions value
        elseif BlzGetUnitRealField(units[loopA], UNIT_RF_PRIORITY) == prio and GetUnitOrderValue(units[loopA]) > GetUnitOrderValue(u) then
            set unitsCount = unitsCount + 1
            set loopB = unitsCount
            loop
                exitwhen loopB <= loopA
                set units[loopB] = units[loopB - 1]
                set loopB = loopB - 1
            endloop
            set units[loopA] = u
            set found = true
            exitwhen true
        endif
        set loopA = loopA + 1
    endloop

    // not found add it at the end
    if not found then
        set unitsCount = unitsCount + 1
        set units[unitsCount] = u
    endif

    set u = null
    return false
endfunction

function GetSelectedUnitIndex takes nothing returns integer
    local integer i = 0
    // local player is in group selection?
    if BlzFrameIsVisible(containerFrame) then
        // find the first visible yellow Background Frame
        loop
            exitwhen i > 11
            if BlzFrameIsVisible(frames[i]) then
                return i
            endif
            set i = i + 1
        endloop
    endif
    return -1
endfunction  

function GetMainSelectedUnit takes integer index returns unit
    if index >= 0 then
        call GroupEnumUnitsSelected(MAIN_SELECT_GROUP, GetLocalPlayer(), filter)
        set bj_groupRandomCurrentPick = units[index + 1]
        //clear table
        loop
            exitwhen unitsCount <= 0
            set units[unitsCount] = null
            set unitsCount = unitsCount - 1
        endloop
        return bj_groupRandomCurrentPick
    else
        call GroupEnumUnitsSelected(MAIN_SELECT_GROUP, GetLocalPlayer(), null)
        return FirstOfGroup(MAIN_SELECT_GROUP)
    endif
endfunction

//async
function GetMainSelectedUnitEx takes nothing returns unit
    return GetMainSelectedUnit(GetSelectedUnitIndex())
endfunction

// Arcing Text Tag v1.0.0.3 by Maker
scope FloatingTextArc
    globals
        private constant    real    SIZE_MIN        = 0.0075         // Minimum size of text
        private constant    real    SIZE_BONUS      = 0.006         // Text size increase
        private constant    real    TIME_LIFE       = 0.9           // How long the text lasts
        private constant    real    TIME_FADE       = 0.7           // When does the text start to fade
        private constant    real    Z_OFFSET        = 100            // Height above unit
        private constant    real    Z_OFFSET_BON    = 75            // How much extra height the text gains
        private constant    real    VELOCITY        = 2.5             // How fast the text move in x/y plane
        private constant    real    ANGLE           = bj_PI/2       // Movement angle of the text. Does not apply if
        private constant    boolean ANGLE_RND       = true          // Is the angle random or fixed
        private constant    integer MAX_PER_TICK    = 5
        private             timer   TMR             = CreateTimer()
        private             integer count           = 0
    endglobals
    
    struct ArcingTextTag extends array        
        private texttag tt
        private real as         // angle, sin component
        private real ac         // angle, cos component
        private real t          // time
        private real x          // origin x
        private real y          // origin y
        private string s        // text
        private static integer array next
        private static integer array prev
        private static integer array rn
        private static integer ic           = 0       // Instance count   
        
        private real scale
        private real timeScale
        
        public static thistype lastCreated = 0
        
        private static method update takes nothing returns nothing
            local thistype this=next[0]
            local real p
            set count = 0
            loop
                set p = Sin(bj_PI*(.t / timeScale))
                set .t = .t - 0.03125
                set .x = .x + .ac
                set .y = .y + .as
                call SetTextTagPos(.tt, .x, .y, Z_OFFSET + Z_OFFSET_BON*p)
                call SetTextTagText(.tt, .s, (SIZE_MIN + SIZE_BONUS*p)*.scale)
                if .t <= 0 then
                    set .tt = null
                    set next[prev[this]] = next[this]
                    set prev[next[this]] = prev[this]
                    set rn[this] = rn[0]
                    set rn[0] = this
                    if next[0]==0 then
                        call PauseTimer(TMR)
                    endif
                endif
                set this = next[this]
                exitwhen this == 0
            endloop
        endmethod
        
        public static method create takes string s, unit u, real duration, real size, integer r, integer g, integer b, integer alpha returns thistype
            local integer pid = GetPlayerId(GetLocalPlayer()) + 1

            static if ANGLE_RND then
                local real a = GetRandomReal(0, 2*bj_PI)
            else
                local real a = ANGLE
            endif
            local thistype this = rn[0]
            set count = count + 1
            
            if count > MAX_PER_TICK then
                return 0
            endif

            if this == 0 then
                set ic = ic + 1
                set this = ic
            else
                set rn[0] = rn[this]
            endif
            
            set .scale = size
            set .timeScale = RMaxBJ(duration, 0.001)
            
            set next[this] = 0
            set prev[this] = prev[0]
            set next[prev[0]] = this
            set prev[0] = this
            
            set .s = s
            set .x = GetUnitX(u)
            set .y = GetUnitY(u)
            set .t = TIME_LIFE
            set .as = Sin(a)*VELOCITY
            set .ac = Cos(a)*VELOCITY
            
            if IsUnitVisible(u, GetLocalPlayer()) then
                if DMG_NUMBERS[pid] == 0 or (DMG_NUMBERS[pid] == 1 and not IsUnitAlly(u, GetLocalPlayer())) then
                    set .tt = CreateTextTag()
                    call SetTextTagPermanent(.tt, false)
                    call SetTextTagColor(.tt, r, g, b, 255 - alpha)
                    call SetTextTagLifespan(.tt, TIME_LIFE*duration)
                    call SetTextTagFadepoint(.tt, TIME_FADE*duration)
                    call SetTextTagText(.tt, s, SIZE_MIN*size)
                    call SetTextTagPos(.tt, .x, .y, Z_OFFSET)
                endif
            else
                set .tt = null
            endif
            
            if prev[this] == 0 then
                call TimerStart(TMR, 0.03125, true, function thistype.update)
            endif
            
            set .lastCreated = this
            
            return this
        endmethod
    endstruct
endscope

scope ShieldSystem
    struct shieldtimer
        private timer t         = null
        private integer shield  = 0
        private real amount     = 0.
        public integer next     = 0
        public integer prev     = 0

        private static method expire takes nothing returns nothing
            local integer i = ReleaseTimer(GetExpiredTimer())
            local thistype this = thistype(i)
            local shield s = shield(this.shield)

            //linked list handling
            if this.prev != 0 and this.next != 0 then
                set thistype(this.prev).next = this.next
                set thistype(this.next).prev = this.prev
            elseif this.prev != 0 then
                set thistype(this.prev).next = 0
            elseif this.next != 0 then //current is head
                set thistype(this.next).prev = 0
                set shield(this.shield).timer = thistype(this.next)
            endif

            set s.max = s.max - this.amount
            set s.hp = s.hp - this.amount

            call this.destroy()

            if s.hp <= 0 then
                call s.destroy()
            else
                call s.refresh()
            endif
        endmethod

        method add takes integer s, real amount, real dur returns nothing
            local shieldtimer st = this

            loop
                exitwhen st.next == 0

                set st = shieldtimer(st.next)
            endloop

            set st.next = thistype.create(s, amount, dur)

            set shieldtimer(st.next).prev = st
        endmethod

        static method create takes integer s, real amount, real dur returns thistype
            local thistype this = thistype.allocate()

            set this.t = NewTimerEx(this)
            set this.shield = s
            set this.amount = amount

            call TimerStart(this.t, dur, false, function thistype.expire)

            return this
        endmethod

        method onDestroy takes nothing returns nothing
            call ReleaseTimer(t)

            set t = null
            set shield = 0
            set amount = 0.
            set next = 0
            set prev = 0
        endmethod
    endstruct

    struct shield
        public effect sfx         = null
        private unit target       = null
        public real max           = 0.
        public real hp            = 0.
        public integer c          = 2
        public shieldtimer timer  = 0
        private integer next      = 0
        private integer prev      = 0

        private static integer head   = 0
        private static integer tail   = 0
        private static integer count  = 0
        private static timer t        = CreateTimer()
        private static integer array list
        private static Table shieldheight

        public method operator color= takes integer c returns nothing
            set .c = c
            call BlzSetSpecialEffectColorByPlayer(.sfx, Player(c))
        endmethod

        static method operator [] takes integer id returns thistype
            return thistype(list[id])
        endmethod

        public method refresh takes nothing returns nothing
            call BlzSetSpecialEffectTime(this.sfx, this.hp / this.max)
        endmethod

        public method damage takes real dmg, unit source returns nothing
            local real angle = Atan2(GetUnitY(source) - GetUnitY(.target), GetUnitX(source) - GetUnitX(.target))
            local real x = GetUnitX(.target) + 80. * Cos(angle)
            local real y = GetUnitY(.target) + 80. * Sin(angle)
            local effect e = AddSpecialEffect("war3mapImported\\BoneArmorCasterTC.mdx", x, y)

            call BlzSetSpecialEffectZ(e, BlzGetUnitZ(.target) + 90.)
            call BlzSetSpecialEffectColorByPlayer(e, Player(this.c))
            call BlzSetSpecialEffectYaw(e, angle)
            call BlzSetSpecialEffectScale(e, 0.85)
            call BlzSetSpecialEffectTimeScale(e, 3.5)

            call DestroyEffect(e)

            set this.hp = this.hp - dmg

            if this.hp <= 0 then
                call this.destroy()
            else
                call this.refresh()
            endif

            set e = null
        endmethod

        private static method update takes nothing returns nothing
            local thistype this = thistype(head)
            local thistype next
            local unit u = GetMainSelectedUnitEx()
            local integer id = GetUnitId(u)

            if thistype(list[id]) != 0 then
                call BlzFrameSetVisible(shieldBackdrop, true)

                if thistype(list[id]).max >= 100000 then
                    call BlzFrameSetText(shieldText, "|cff22ddff" + I2S(R2I(thistype(list[id]).hp)))
                else
                    call BlzFrameSetText(shieldText, "|cff22ddff" + I2S(R2I(thistype(list[id]).hp)) + " / " + I2S(R2I(thistype(list[id]).max)))
                endif
            else
                call BlzFrameSetVisible(shieldBackdrop, false)
            endif

            loop
                exitwhen this == 0
                set next = this.next

                //as long as the target is alive
                if UnitAlive(this.target) then
                    call BlzSetSpecialEffectX(this.sfx, GetUnitX(this.target))
                    call BlzSetSpecialEffectY(this.sfx, GetUnitY(this.target))
                    call BlzSetSpecialEffectZ(this.sfx, BlzGetUnitZ(this.target) + shieldHeight(GetUnitTypeId(this.target)))
                else
                //otherwise go expire
                    call this.destroy()
                endif

                set this = next
            endloop

            set u = null
        endmethod

        public static method add takes unit u, real amount, real dur returns thistype
            local integer id = GetUnitId(u)
            local thistype this = shield[id]

            //call DEBUGMSG(I2S(id))

            //shield already exists
            if this != 0 then
                set this.max = this.max + amount
                set this.hp = this.hp + amount
                call this.timer.add(this, amount, dur)

                call this.refresh()
            else
            //make a new one
                set this = thistype.create(u, amount, dur)
                set this.timer = shieldtimer.create(this, amount, dur)
            endif

            return this
        endmethod

        private static method create takes unit u, real amount, real dur returns thistype
            local integer id = GetUnitId(u)
            local thistype this = thistype.allocate()

            //instance count
            set thistype.count = thistype.count + 1
        
            //setup
            set list[id] = this
            set this.max = amount
            set this.hp = amount
            set this.target = u
            set this.sfx = AddSpecialEffect("war3mapImported\\HPbar.mdx", GetUnitX(u), GetUnitY(u))
            set this.color = c
            call BlzSetSpecialEffectTime(this.sfx, 1.)
            call BlzSetSpecialEffectTimeScale(this.sfx, 0.)
            call BlzSetSpecialEffectScale(this.sfx, 1.6)

            //ll setup
            if thistype.count == 1 then
                set thistype.head = this
                call TimerStart(thistype.t, 0.01, true, function thistype.update)
            else
                set thistype(thistype.tail).next = this
                set this.prev = thistype(thistype.tail)
            endif

            set thistype.tail = this

            return this
        endmethod

        //shield fully expires
        method onDestroy takes nothing returns nothing
            local integer pid = GetPlayerId(GetOwningPlayer(.target)) + 1
            local integer node = .timer
            local shieldtimer st

            call TimerList[pid].stopAllTimersWithTag('garm') //gaia armor attachment
            set Buff.get(null, .target, ProtectionBuff.typeid).duration = 0. //high priestess protection attack speed

            call BlzSetSpecialEffectAlpha(.sfx, 0)
            call DestroyEffect(.sfx)

            //shield timer cleanup
            loop
                exitwhen node == 0
                set st = shieldtimer(node)
                set node = st.next

                call st.destroy()
            endloop

            //linked list cleanup
            set thistype(this.prev).next = this.next

            if this == thistype.head then
                set thistype.head = this.next
            endif

            if this == thistype.tail then
                set thistype.tail = this.prev
            endif

            set thistype.count = thistype.count - 1
            set thistype.list[GetUnitId(this.target)] = 0

            if thistype.count == 0 then
                call BlzFrameSetVisible(shieldBackdrop, false)
                call PauseTimer(thistype.t)
            endif

            set .sfx = null
            set .target = null
            set .max = 0.
            set .hp = 0
            set .c = 3
            set .next = 0
            set .prev = 0
            set .timer = 0
        endmethod

        static method shieldHeight takes integer id returns integer
            if shieldheight[id] == 0 then
                return 250
            endif

            return shieldheight[id]
        endmethod

        static method onInit takes nothing returns nothing
            set shieldheight = Table.create()

            set shieldheight[HERO_ELEMENTALIST] = 200
            set shieldheight[HERO_MARKSMAN] = 220
            set shieldheight[HERO_MARKSMAN_SNIPER] = 220
            set shieldheight[HERO_ROYAL_GUARDIAN] = 230
            set shieldheight[HERO_MASTER_ROGUE] = 230
            set shieldheight[HERO_ASSASSIN] = 230
            set shieldheight[HERO_DARK_SUMMONER] = 230
            set shieldheight[HERO_THUNDERBLADE] = 240
            set shieldheight[HERO_HIGH_PRIEST] = 240
            set shieldheight[HERO_VAMPIRE] = 240
            set shieldheight[HERO_OBLIVION_GUARD] = 275
        endmethod
    endstruct
endscope

struct DialogWindow
    private static constant integer OPTIONS_PER_PAGE = 7
    private static constant integer BUTTON_MAX = 100
    private static constant integer DATA_MAX = 100
    static integer array DIALOG[PLAYER_CAP]

    dialog dialog = null
    integer pid = 0
    button array Button[thistype.BUTTON_MAX] //TODO arbitrary
    string array ButtonName[thistype.BUTTON_MAX]
    integer ButtonCount = 0 
    integer Page = 0
    button nextButton = null
    button cancelButton = null
    trigger trig = null

    public integer array data[thistype.DATA_MAX]

    static method operator [] takes integer pid returns thistype
        return thistype(DIALOG[pid - 1])
    endmethod

    static method dialogHandler takes nothing returns boolean
        local thistype this = thistype[GetPlayerId(GetTriggerPlayer()) + 1]
        local integer index = this.Page * OPTIONS_PER_PAGE + OPTIONS_PER_PAGE
        local integer i = 0

        if GetClickedButton() == null then
            return false
        endif

        if GetClickedButton() == this.nextButton then
            if index > this.ButtonCount then
                set index = 0
                set this.Page = -1
            endif

            call DialogDisplay(Player(pid - 1), this.dialog, false)
            call DialogClear(this.dialog)

            loop
                exitwhen i >= OPTIONS_PER_PAGE or i >= ButtonCount

                set Button[i] = DialogAddButton(this.dialog, ButtonName[i], 0)

                set i = i + 1
            endloop

            set this.Page = this.Page + 1

            call DialogDisplay(Player(pid - 1), this.dialog, true)
        elseif GetClickedButton() == this.cancelButton then
            call this.destroy()
        endif

        return false
    endmethod

    method getClickedIndex takes button b returns integer
        local integer index = 0

        loop
            exitwhen index >= this.ButtonCount

            if b == this.Button[index] then
                return index
            endif

            set index = index + 1
        endloop

        return -1
    endmethod

    method display takes nothing returns nothing
        if ButtonCount > OPTIONS_PER_PAGE then
            set nextButton = DialogAddButton(this.dialog, "Next Page", 0)
        endif

        set cancelButton = DialogAddButton(this.dialog, "Cancel", 0)

        call DialogDisplay(Player(pid - 1), this.dialog, true)
    endmethod

    method addButton takes string s returns nothing
        if ButtonCount < OPTIONS_PER_PAGE then
            set Button[ButtonCount] = DialogAddButton(this.dialog, s, 0)
        endif

        set ButtonName[ButtonCount] = s
        set ButtonCount = ButtonCount + 1
    endmethod

    method onDestroy takes nothing returns nothing
        local integer i = 0

        call DialogDisplay(Player(this.pid - 1), this.dialog, false)
        call DialogDestroy(this.dialog)
        call DestroyTrigger(this.trig)

        set DIALOG[this.pid - 1] = 0

        set this.dialog = null
        set this.pid = 0
        set this.ButtonCount = 0
        set this.Page = 0
        set this.trig = null
        set this.nextButton = null
        set this.cancelButton = null

        loop
            exitwhen i >= BUTTON_MAX

            set this.Button[i] = null

            set i = i + 1
        endloop

        set i = 0
        loop
            exitwhen i >= DATA_MAX

            set this.data[i] = 0

            set i = i + 1
        endloop
    endmethod

    static method create takes integer pid, string s, code c returns thistype
        local thistype this

        //safety
        if DIALOG[pid - 1] != 0 then
            return 0
        endif

        set this = thistype.allocate()
        set this.dialog = DialogCreate()
        set this.pid = pid
        set this.trig = CreateTrigger()

        call DialogSetMessage(this.dialog, s)
        call TriggerRegisterDialogEvent(this.trig, this.dialog)
        call TriggerAddCondition(this.trig, Filter(c))
        call TriggerAddCondition(this.trig, Filter(function thistype.dialogHandler))

        set DIALOG[pid - 1] = this

        return this
    endmethod
endstruct

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
        return SubString(abc, i - 97 + 36, i - 96 + 36)
    elseif i >= 65 then
        return SubString(abc, i - 65 + 10, i - 64 + 10)
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
    local integer i = 0
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

/*function SetTableData takes HashTable ht, integer id, string data returns nothing
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
endfunction*/

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

function SetCurrency takes integer pid, integer index, integer amount returns nothing
    set Currency[pid * CURRENCY_COUNT + index] = IMaxBJ(0, amount)

    if index == GOLD then
        call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_GOLD, Currency[pid * CURRENCY_COUNT + index])
    elseif index == LUMBER then
        call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_LUMBER, Currency[pid * CURRENCY_COUNT + index])
    elseif index == PLATINUM then
        if GetLocalPlayer() == Player(pid - 1) then
            call BlzFrameSetText(platText, I2S(Currency[pid * CURRENCY_COUNT + index]))
        endif
    elseif index == ARCADITE then
        if GetLocalPlayer() == Player(pid - 1) then
            call BlzFrameSetText(arcText, I2S(Currency[pid * CURRENCY_COUNT + index]))
        endif
    elseif index == CRYSTAL then
        call SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_FOOD_USED, Currency[pid * CURRENCY_COUNT + index])
    endif
endfunction

function GetCurrency takes integer pid, integer index returns integer
    return Currency[pid * CURRENCY_COUNT + index]
endfunction

function AddCurrency takes integer pid, integer index, integer amount returns nothing
    call SetCurrency(pid, index, GetCurrency(pid, index) + amount)
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

function SoundHandler takes string path, boolean is3D, player p, unit u returns nothing
    local sound s
    local string ss = ""

    if p != null then
        if GetLocalPlayer() == p then
            set ss = path
        endif
        set s = CreateSound(ss, false, is3D, is3D, 12700, 12700, "")
    else
        set s = CreateSound(path, false, is3D, is3D, 12700, 12700, "")
    endif

    if u != null then
        call AttachSoundToUnit(s, u)
    endif

    call StartSound(s)
    call KillSoundWhenDone(s)
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
    local integer iud = GetItemUserData(GetEnumItem())

	if iud != 0 and Item(iud).owner == tempplayer then
        call Item(iud).destroy()
	endif
endfunction

/*function CloseF11 takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call ForceUICancel()
    endif
endfunction*/

function Trig_Enemy_Of_Hostile takes nothing returns boolean
	if IsUnitEnemy(GetFilterUnit(),pfoe) == false then
		return false
	elseif UnitAlive(GetFilterUnit()) == false then
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
    call MultiboardSetItemValueBJ(MULTI_BOARD, 6, 1, "HP")
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
	if id == 'n02V' or id == 'n03U' or id == 'n09Q' or id == 'n09T' or id == 'n09O' or id == 'n09P' or id == 'n09R' or id == 'n09S' or id == 'nvk2' or id == 'nvlw' or id == 'nvlk' or id == 'nvil' or id == 'nvl2' or id == 'H01Y' or id == 'H01T' or id == 'n036' or id == 'n035' or id == 'n037' or id == 'n03S' or id == 'n01I' or id == 'n0A3' or id == 'n0A4' or id == 'n0A5' or id == 'n0A6' or id == 'h00G' then
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
    return (IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true)
endfunction

function ischar takes nothing returns boolean
    local integer pid = GetPlayerId(GetOwningPlayer(GetFilterUnit())) + 1

    return (GetFilterUnit() == Hero[pid] and UnitAlive(Hero[pid]))
endfunction

function nothero takes nothing returns boolean
	return (IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == false and UnitAlive(GetFilterUnit()) and GetUnitTypeId(GetFilterUnit()) != DUMMY)
endfunction

function isbase takes nothing returns boolean
    return (IsUnitType(GetFilterUnit(), UNIT_TYPE_TOWNHALL) == true)
endfunction

function isOrc takes nothing returns boolean
    local integer uid = GetUnitTypeId(GetFilterUnit())

    return (UnitAlive(GetFilterUnit()) and (uid == 'o01I' or uid == 'o008'))
endfunction

function ishostile takes nothing returns boolean
    local integer i =GetPlayerId(GetOwningPlayer(GetFilterUnit()))

	return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and (i ==10 or i ==11 or i ==PLAYER_NEUTRAL_AGGRESSIVE))
endfunction

function ChaosTransition takes nothing returns boolean
    local integer i = GetPlayerId(GetOwningPlayer(GetFilterUnit()))

	return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and (i ==10 or i ==11 or i ==PLAYER_NEUTRAL_AGGRESSIVE) and RectContainsUnit(gg_rct_Colosseum, GetFilterUnit()) == false and RectContainsUnit(gg_rct_Infinite_Struggle, GetFilterUnit()) == false)
endfunction

function isplayerAlly takes nothing returns boolean
	return (UnitAlive(GetFilterUnit()) and GetPlayerId(GetOwningPlayer(GetFilterUnit())) <= PLAYER_CAP and IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true and GetUnitTypeId(GetFilterUnit()) != BACKPACK)
endfunction

function iszeppelin takes nothing returns boolean
    return (GetUnitTypeId(GetFilterUnit()) == 'nzep' and UnitAlive(GetFilterUnit()))
endfunction

function isplayerunitRegion takes nothing returns boolean
    return (UnitAlive(GetFilterUnit()) and GetPlayerId(GetOwningPlayer(GetFilterUnit())) <= PLAYER_CAP and GetUnitTypeId(GetFilterUnit()) != DUMMY)
endfunction

function isplayerunit takes nothing returns boolean
    return (UnitAlive(GetFilterUnit()) and GetPlayerId(GetOwningPlayer(GetFilterUnit())) <= PLAYER_CAP and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY)
endfunction

function ishostileEnemy takes nothing returns boolean
local integer i =GetPlayerId(GetOwningPlayer(GetFilterUnit()))
	return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(), 'Avul') ==0 and i <= PLAYER_CAP and GetUnitTypeId(GetFilterUnit()) != DUMMY)
endfunction

function isalive takes nothing returns boolean
	return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY)
endfunction

function IsBoss takes integer uid returns integer
    local integer i = 0

    loop
        exitwhen BossID[i] == uid or i > BOSS_TOTAL
        set i = i + 1
    endloop

    if i > BOSS_TOTAL then
        return -1
    endif

    return i
endfunction

function IsEnemy takes integer i returns boolean
    return (i == 12 or i == PLAYER_NEUTRAL_AGGRESSIVE + 1)
endfunction

function ExplodeUnits takes nothing returns nothing
    call SetUnitExploded(GetEnumUnit(), true)
    call KillUnit(GetEnumUnit())
endfunction

function isImportantItem takes item itm returns boolean
    local integer id = GetItemTypeId(itm)

    return id == 'I042' or id == 'I040' or id == 'I041' or id == 'I0M4' or id == 'I0M5' or id == 'I0M6' or id == 'I0M7' or itm == PathItem
endfunction

function ClearItems takes nothing returns nothing
    local item itm = GetEnumItem()
    
    if not isImportantItem(itm) then //keys + pathcheck
        call Item[itm].destroy()
    endif

    set itm = null
endfunction

function AttackDelay takes nothing returns nothing
    local PlayerTimer pt = TimerList[0].getTimerFromHandle(GetExpiredTimer())

    call BlzSetUnitWeaponBooleanField(pt.caster, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
    call IssueTargetOrderById(pt.caster, 852173, pt.target)

    call TimerList[0].removePlayerTimer(pt)
endfunction

function InstantAttack takes unit source, unit target returns nothing
    local PlayerTimer pt = TimerList[0].addTimer(0)

    set pt.caster = source
    set pt.target = target

    call UnitAddAbility(source, 'IATK')
    call TimerStart(pt.timer, 0.05, false, function AttackDelay)
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
        call TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, TEMP_DUMMY, EVENT_UNIT_ACQUIRED_TARGET)
    endif

    if UnitAddAbility(TEMP_DUMMY, abil) then
        call SetUnitAbilityLevel(TEMP_DUMMY, abil, ablev)
        call SaveInteger(MiscHash, GetHandleId(TEMP_DUMMY), 'dspl', abil)
    endif

    if dur > 0 then
        call RemoveUnitTimed(TEMP_DUMMY, dur)
    endif

    //reset attack cooldown
    call BlzSetUnitAttackCooldown(TEMP_DUMMY, 5., 0)
    call UnitSetBonus(TEMP_DUMMY, BONUS_ATTACK_SPEED, 0.)

    call SetUnitXBounded(TEMP_DUMMY, x)
    call SetUnitYBounded(TEMP_DUMMY, y)

    return TEMP_DUMMY
endfunction

function RemovePlayerUnits takes integer pid returns nothing
    local group ug = CreateGroup()
    local unit target
    local integer i = 0
    local integer itid = 0
    local item itm
    
    call GroupEnumUnitsOfPlayer(ug, Player(pid - 1), null)
    
    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if IsUnitType(target, UNIT_TYPE_HERO) then
            set i = 0
            loop
                exitwhen i > 5
                set itm = UnitItemInSlot(target, i)
                set itid = GetItemTypeId(itm)
                if isImportantItem(itm) then
                    call Item[itm].destroy()
                    call Item.create(itid, GetLocationX(TownCenter), GetLocationY(TownCenter), 0.)
                endif
                set i = i + 1
            endloop
        endif
        if GetUnitTypeId(target) != DUMMY then
            call RemoveUnit(target)
        endif
    endloop
    
    call DestroyGroup(ug)
    
    set ug = null
    set itm = null
endfunction

function MainStat takes unit hero returns integer //returns integer signifying primary attribute
    return BlzGetUnitIntegerField(hero, UNIT_IF_PRIMARY_ATTRIBUTE)
endfunction

function MainStatForm takes integer pid, integer i returns nothing
    call RemoveUnit(hsdummy[pid])
    if i == 1 then
        set hsdummy[pid] = CreateUnit(Player(pid - 1), 'E001', 30000, 30000, 0)
    elseif i == 2 then
        set hsdummy[pid] = CreateUnit(Player(pid - 1), 'E004', 30000, 30000, 0)
    elseif i == 3 then
        set hsdummy[pid] = CreateUnit(Player(pid - 1), 'E01A', 30000, 30000, 0)
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
        if charLightId[i] != 1 and HeroID[i] > 0 then
            call UnitRemoveAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 1
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        endif
    elseif RectContainsCoords(gg_rct_Naga_Dungeon_Reward, x, y) and CustomLighting[i] != 2 then
        set CustomLighting[i] = 2
        if charLightId[i] != 1 and HeroID[i] > 0 then
            call UnitRemoveAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 1
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        endif
    elseif RectContainsCoords(gg_rct_Naga_Dungeon, x, y) and not RectContainsCoords(gg_rct_Naga_Dungeon_Reward, x, y) and CustomLighting[i] != 3 then
        set CustomLighting[i] = 3
        if charLightId[i] != 2 and HeroID[i] > 0 then
            call UnitAddAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 2
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("","")
        endif
    elseif RectContainsCoords(gg_rct_Naga_Dungeon_Boss, x, y) and CustomLighting[i] != 4 then
        set CustomLighting[i] = 4
        if charLightId[i] != 2 and HeroID[i] > 0 then
            call UnitAddAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 2
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("","")
        endif
    elseif RectContainsCoords(gg_rct_Church, x, y) and CustomLighting[i] != 5 then
        set CustomLighting[i] = 5
        if charLightId[i] != 1 and HeroID[i] > 0 then
            call UnitRemoveAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 1
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdx","Environment\\DNC\\DNCLordaeron\\DNCLordaeronTerrain\\DNCLordaeronTerrain.mdx")
        endif
    elseif RectContainsCoords(gg_rct_Tavern, x, y) and CustomLighting[i] != 6 then
        set CustomLighting[i] = 6
        if charLightId[i] != 1 and HeroID[i] > 0 then
            call UnitRemoveAbility(Hero[i], 'A0AN')
            call UnitRemoveAbility(Hero[i], 'A0B8')
            set charLightId[i] = 1
        endif
        if GetLocalPlayer() == Player(i - 1) then
            call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        endif
    elseif RectContainsCoords(gg_rct_Cave, x, y) and CustomLighting[i] != 7 then
        set CustomLighting[i] = 7
        if charLightId[i] != 2 and HeroID[i] > 0 then
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

    call TimerStart(pt.timer, delay, false, function DelayAnimationExpire)
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

    call MainStatForm(pid, MainStat(hstarget[0]))

    call BlzSetUnitSkin(hsdummy[pid], hsskinid[0])
    call BlzSetUnitName(hsdummy[pid], GetUnitName(hstarget[0]))
    call BlzSetHeroProperName(hsdummy[pid], GetHeroProperName(hstarget[0]))
    //call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_PRIMARY_ATTRIBUTE, BlzGetUnitIntegerField(hstarget[0], UNIT_IF_PRIMARY_ATTRIBUTE))
    call BlzSetUnitWeaponIntegerField(hsdummy[pid], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0, BlzGetUnitWeaponIntegerField(hstarget[0], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0))
    call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_DEFENSE_TYPE, BlzGetUnitIntegerField(hstarget[0], UNIT_IF_DEFENSE_TYPE))
    call BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0, BlzGetUnitWeaponRealField(hstarget[0], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0))
    call BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_RANGE, 1, BlzGetUnitWeaponRealField(hstarget[0], UNIT_WEAPON_RF_ATTACK_RANGE, 0) - 100)
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
        call SelectUnit(hsdummy[pid], true)
        call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
    endif
    
    set Backpack[pid] = null
    set hselection[pid] = true
    //call SetCameraBoundsToRectForPlayerBJ(whichPlayer, gg_rct_Main_Map_Vision)
    call SetCurrency(pid, GOLD, 75)
    call SetCurrency(pid, LUMBER, 30)
endfunction

function NewProfileYes takes nothing returns boolean
    local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
    
    call Profile[pid].destroy()
    call Profile[pid].create(pid)

    call DialogDestroy(GetClickedDialog())
    call SpawnWispSelector(GetTriggerPlayer())

    return false
endfunction

function NewProfileNo takes nothing returns boolean
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
    local string name = ""
    local integer slotsUsed = Profile[pid].getSlotsUsed()
    local integer hardcore = 0
    local integer prestige = 0
    local integer id = 0
    local integer herolevel = 0

    call DialogClear(LoadDialog[pid])
    set deleteMode[pid] = false
    set loadPage[pid] = 0

    loop
        exitwhen i > MAX_SLOTS or loadPage[pid] > 5
            set hardcore = 0
            set prestige = 0
            set id = 0
            set herolevel = 0

            if Profile[pid].phtl[i] > 0 then //slot is not empty
                set name = "|cffffcc00"
                set hardcore = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[0])
                set prestige = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[1] + POWERSOF2[2]) / POWERSOF2[1]
                set id = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[3] + POWERSOF2[4] + POWERSOF2[5] + POWERSOF2[6] + POWERSOF2[7] + POWERSOF2[8]) / POWERSOF2[3]
                set herolevel = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[9] + POWERSOF2[10] + POWERSOF2[11] + POWERSOF2[12] + POWERSOF2[13] + POWERSOF2[14] + POWERSOF2[15] + POWERSOF2[16] + POWERSOF2[17] + POWERSOF2[18]) / POWERSOF2[9]

                if prestige > 0 then
                    set name = name + "[PRSTG] "
                endif
                set name = name + GetObjectName(SAVE_UNIT_TYPE[id]) + " [" + I2S(herolevel) + "] "
                if hardcore > 0 then
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
        exitwhen i > MAX_SLOTS

        if Profile[pid].phtl[i] <= 0 then
            set Profile[pid].currentSlot = i
            exitwhen true
        endif

        set i = i + 1
    endloop

    if i == 30 then
        set Profile[pid].currentSlot = -1
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
    local integer hardcore = 0
    local integer prestige = 0
    local integer id = 0
    local integer herolevel = 0
    local string name = ""
    local integer slotsUsed = Profile[pid].getSlotsUsed()

    loop
        exitwhen j > MAX_SLOTS or buttonClickedFound
        
        if LoadDialogButton[pid * 30 + j] == buttonClicked then
            set clickedSlot = j
            set buttonClickedFound = true
            set Profile[pid].currentSlot = clickedSlot
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
            exitwhen i > MAX_SLOTS or j > 5
                set hardcore = 0
                set prestige = 0
                set id = 0
                set herolevel = 0

                if Profile[pid].phtl[i] > 0 then //slot is not empty 
                    set hardcore = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[0])
                    set prestige = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[1] + POWERSOF2[2]) / POWERSOF2[1]
                    set id = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[3] + POWERSOF2[4] + POWERSOF2[5] + POWERSOF2[6] + POWERSOF2[7] + POWERSOF2[8]) / POWERSOF2[3]
                    set herolevel = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[9] + POWERSOF2[10] + POWERSOF2[11] + POWERSOF2[12] + POWERSOF2[13] + POWERSOF2[14] + POWERSOF2[15] + POWERSOF2[16] + POWERSOF2[17] + POWERSOF2[18]) / POWERSOF2[9]
                    set name = "|cffffcc00"
                    if prestige > 0 then
                        set name = name + "[PRSTG] "
                    endif
                    set name = name + GetObjectName(SAVE_UNIT_TYPE[id]) + " [" + I2S(herolevel) + "] "
                    if hardcore > 0 then
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
        if Profile[pid].getSlotsUsed() >= 30 then
            call DisplayTimedTextToPlayer(p, 0, 0, 30.0, "You cannot save more than 30 heroes!")
            call DisplayHeroSelectionDialog(pid)
        else
            call DisplayTimedTextToPlayer(p, 0, 0, 30.0, "Select a |c006969ffhero|r using arrow keys.")
            set newcharacter[pid] = true
            call SetSaveSlot(pid)
            //call DEBUGMSG("Current slot: " + I2S(Profile[pid].currentSlot))
            call SpawnWispSelector(p)
        endif

        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 1500] then //Show delete menu
        set deleteMode[pid] = true
        set loadPage[pid] = 0
    
        loop
            exitwhen i > MAX_SLOTS or loadPage[pid] > 6
            set hardcore = 0
            set prestige = 0
            set id = 0
            set herolevel = 0

            if Profile[pid].phtl[i] > 0 then //slot is not empty 
                set hardcore = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[0])
                set prestige = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[1] + POWERSOF2[2]) / POWERSOF2[1]
                set id = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[3] + POWERSOF2[4] + POWERSOF2[5] + POWERSOF2[6] + POWERSOF2[7] + POWERSOF2[8]) / POWERSOF2[3]
                set herolevel = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[9] + POWERSOF2[10] + POWERSOF2[11] + POWERSOF2[12] + POWERSOF2[13] + POWERSOF2[14] + POWERSOF2[15] + POWERSOF2[16] + POWERSOF2[17] + POWERSOF2[18]) / POWERSOF2[9]
                set name = "|cffffcc00"

                if prestige > 0 then
                    set name = name + "[PRSTG] "
                endif
                set name = name + GetObjectName(SAVE_UNIT_TYPE[id]) + " [" + I2S(herolevel) + "] "
                if hardcore > 0 then
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
            exitwhen i > MAX_SLOTS or j > 6
            set hardcore = 0
            set prestige = 0
            set id = 0
            set herolevel = 0

            if Profile[pid].phtl[i] > 0 then //slot is not empty 
                set hardcore = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[0])
                set prestige = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[1] + POWERSOF2[2]) / POWERSOF2[1]
                set id = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[3] + POWERSOF2[4] + POWERSOF2[5] + POWERSOF2[6] + POWERSOF2[7] + POWERSOF2[8]) / POWERSOF2[3]
                set herolevel = BlzBitAnd(Profile[pid].phtl[i], POWERSOF2[9] + POWERSOF2[10] + POWERSOF2[11] + POWERSOF2[12] + POWERSOF2[13] + POWERSOF2[14] + POWERSOF2[15] + POWERSOF2[16] + POWERSOF2[17] + POWERSOF2[18]) / POWERSOF2[9]
                set name = "|cffffcc00"

                if prestige > 0 then
                    set name = name + "[PRSTG] "
                endif
                set name = name + GetObjectName(SAVE_UNIT_TYPE[id]) + " [" + I2S(herolevel) + "] "
                if hardcore > 0 then
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
            call FileIO_Write(MAP_NAME + "\\" + User.fromIndex(pid - 1).name + "\\slot" + I2S(Profile[pid].currentSlot + 1) + ".pld", "")
        endif
        call Profile[pid].saveProfile()
        call DisplayHeroSelectionDialog(pid)
        set buttonClicked = null
        return
    elseif buttonClicked == LoadDialogButton[pid + 3500] then //Go back
        call DisplayHeroSelectionDialog(pid)
        set buttonClicked = null
        return
    endif
    
    if deleteMode[pid] then
        call DialogSetMessage(LoadDialog[pid], "Are you sure?|nAny prestige bonuses from this character will be lost!")
        
        set LoadDialogButton[pid + 3000] = DialogAddButton(LoadDialog[pid], "Yes", 0)
        set LoadDialogButton[pid + 3500] = DialogAddButton(LoadDialog[pid], "No", 0)
        
        call DialogDisplay(p, LoadDialog[pid], true)
    else
        if buttonClickedFound then
            call DisplayTextToPlayer(p, 0, 0, "Loading |c006969ffhero|r from selected slot...")

            if GetLocalPlayer() == p then
                call BlzSendSyncData(SYNC_PREFIX, getLine(1, FileIO_Read(MAP_NAME + "\\" + User[p].name + "\\slot" + I2S(clickedSlot + 1) + ".pld")))
            endif
        endif
    endif
    
    set buttonClicked = null
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
    
    call EnumItemsInRect(gg_rct_Colosseum, null, function ClearItems)
    call SetTextTagText(ColoText, "Colosseum", 10 * 0.023 / 10)
    call DestroyGroup(ug)

    set ug = null
    set u = null
endfunction

function ShowHeroCircle takes player p, boolean show returns nothing
    if show then
        if GetLocalPlayer() == p then
            call BlzSetUnitSkin(gg_unit_H02A_0568, GetUnitTypeId(gg_unit_H02A_0568))
            call BlzSetUnitSkin(gg_unit_H03N_0612, GetUnitTypeId(gg_unit_H03N_0612))
            call BlzSetUnitSkin(gg_unit_H04Z_0604, GetUnitTypeId(gg_unit_H04Z_0604))
            call BlzSetUnitSkin(gg_unit_H012_0605, GetUnitTypeId(gg_unit_H012_0605))
            call BlzSetUnitSkin(gg_unit_U003_0081, GetUnitTypeId(gg_unit_U003_0081))
            call BlzSetUnitSkin(gg_unit_H01N_0606, GetUnitTypeId(gg_unit_H01N_0606))
            call BlzSetUnitSkin(gg_unit_H01S_0607, GetUnitTypeId(gg_unit_H01S_0607))
            call BlzSetUnitSkin(gg_unit_H05B_0608, GetUnitTypeId(gg_unit_H05B_0608))
            call BlzSetUnitSkin(gg_unit_H029_0617, GetUnitTypeId(gg_unit_H029_0617))
            call BlzSetUnitSkin(gg_unit_O02S_0615, GetUnitTypeId(gg_unit_O02S_0615))
            call BlzSetUnitSkin(gg_unit_H00R_0610, GetUnitTypeId(gg_unit_H00R_0610))
            call BlzSetUnitSkin(gg_unit_E00G_0616, GetUnitTypeId(gg_unit_E00G_0616))
            call BlzSetUnitSkin(gg_unit_E012_0613, GetUnitTypeId(gg_unit_E012_0613))
            call BlzSetUnitSkin(gg_unit_E00W_0614, GetUnitTypeId(gg_unit_E00W_0614))
            call BlzSetUnitSkin(gg_unit_E002_0585, GetUnitTypeId(gg_unit_E002_0585))
            call BlzSetUnitSkin(gg_unit_O03J_0609, GetUnitTypeId(gg_unit_O03J_0609))
            call BlzSetUnitSkin(gg_unit_E015_0586, GetUnitTypeId(gg_unit_E015_0586))
            call BlzSetUnitSkin(gg_unit_E008_0587, GetUnitTypeId(gg_unit_E008_0587))
            call BlzSetUnitSkin(gg_unit_E00X_0611, GetUnitTypeId(gg_unit_E00X_0611))
        endif
    else
        if GetLocalPlayer() == p then
            call BlzSetUnitSkin(gg_unit_H02A_0568, 'eRez')
            call BlzSetUnitSkin(gg_unit_H03N_0612, 'eRez')
            call BlzSetUnitSkin(gg_unit_H04Z_0604, 'eRez')
            call BlzSetUnitSkin(gg_unit_H012_0605, 'eRez')
            call BlzSetUnitSkin(gg_unit_U003_0081, 'eRez')
            call BlzSetUnitSkin(gg_unit_H01N_0606, 'eRez')
            call BlzSetUnitSkin(gg_unit_H01S_0607, 'eRez')
            call BlzSetUnitSkin(gg_unit_H05B_0608, 'eRez')
            call BlzSetUnitSkin(gg_unit_H029_0617, 'eRez')
            call BlzSetUnitSkin(gg_unit_O02S_0615, 'eRez')
            call BlzSetUnitSkin(gg_unit_H00R_0610, 'eRez')
            call BlzSetUnitSkin(gg_unit_E00G_0616, 'eRez')
            call BlzSetUnitSkin(gg_unit_E012_0613, 'eRez')
            call BlzSetUnitSkin(gg_unit_E00W_0614, 'eRez')
            call BlzSetUnitSkin(gg_unit_E002_0585, 'eRez')
            call BlzSetUnitSkin(gg_unit_O03J_0609, 'eRez')
            call BlzSetUnitSkin(gg_unit_E015_0586, 'eRez')
            call BlzSetUnitSkin(gg_unit_E008_0587, 'eRez')
            call BlzSetUnitSkin(gg_unit_E00X_0611, 'eRez')
        endif
        call ShowUnit(gg_unit_n02S_0098, false)
        call ShowUnit(gg_unit_n02S_0098, true)
    endif
endfunction

function PlayerCleanup takes player p returns nothing //any instance of player removal (leave, repick, permanent death, forcesave, afk removal)
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local item itm
    local group ug = CreateGroup()
    local unit target

    call UnitRemoveAbility(Hero[pid], 'A03C') //close actions spellbook
    
    loop //clear ashen vat
        exitwhen i > 5
        set itm = UnitRemoveItemFromSlot(ASHEN_VAT, i)
        call Item[itm].destroy()
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

    call Profile[pid].hero.wipeData()
    
    set mybase[pid] = null
    call GroupRemoveUnit(AzazothPlayers, Hero[pid]) //clear aza
    call GroupRemoveUnit(HeroGroup, Hero[pid])
    call RemovePlayerUnits(pid)

    call TimerList[pid].stopAllTimers()

    set Hero[pid] = null
    set HeroID[pid] = 0
	set Backpack[pid] = null
    call SetCurrency(pid, GOLD, 0)
    call SetCurrency(pid, LUMBER, 0)
    call SetCurrency(pid, PLATINUM, 0)
    call SetCurrency(pid, ARCADITE, 0)
    call SetCurrency(pid, CRYSTAL, 0)
	set udg_ArcaConverter[pid] = false
	set udg_ArcaConverterBought[pid] = false
	set udg_PlatConverter[pid] = false
	set udg_PlatConverterBought[pid] = false
	set DmgBase[pid] = 0
	set SpellTakenBase[pid] = 0
    set ItemEvasion[pid] = 0
    set ItemRegen[pid] = 0
    set ItemSpellboost[pid] = 0
    set ItemMovespeed[pid] = 0
    set ItemMagicRes[pid] = 1
    set ItemDamageRes[pid] = 1
    set TotalRegen[pid] = 0
    set TotalEvasion[pid] = 0
    set ItemGoldRate[pid] = 0
    set HERO_PROF[pid] = 0
    set udg_TimePlayed[pid] = 0
    set HeartBlood[pid] = 0
    set urhome[pid] = 0
    set BloodBank[pid] = 0
    set BardSong[pid] = 0
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
    set CustomLighting[pid] = 0
    set charLightId[pid] = 0
    set masterElement[pid] = 0
    set darkSealActive[pid] = false
    set PhantomSlashing[pid] = false
    set BodyOfFireCharges[pid] = 5 //default
    set limitBreak[pid] = 0
    if GetLocalPlayer() == p then
        call BlzFrameSetVisible(LimitBreakBackdrop, false)
        call BlzSetAbilityIcon(PARRY.id, "ReplaceableTextures\\CommandButtons\\BTNReflex.blp")
        call BlzSetAbilityIcon(SPINDASH.id, "ReplaceableTextures\\CommandButtons\\BTNComed Fall.blp")
        call BlzSetAbilityIcon(SPINDASH.id2, "ReplaceableTextures\\CommandButtons\\BTNComed Fall.blp")
        call BlzSetAbilityIcon(INTIMIDATINGSHOUT.id, "ReplaceableTextures\\CommandButtons\\BTNBattleShout.blp")
        call BlzSetAbilityIcon(WINDSCAR.id, "ReplaceableTextures\\CommandButtons\\BTNimpaledflameswordfinal.blp")
    endif
    call DestroyEffect(lightningeffect[pid])
    call DestroyEffect(songeffect[pid])

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

    set sniperstance[pid] = false
    set udg_Hardcore[pid] = false
    set ArenaQueue[pid] = 0

    set newcharacter[pid] = true
    call SetSaveSlot(pid) //repicking sets you to an empty save slot
    
    /*set i = 1
    
	loop
		exitwhen i > 10
		call SaveBoolean(PlayerProf, pid, i, false)
		set i = i + 1
	endloop*/
    
    set tempplayer = p
	call EnumItemsInRect(bj_mapInitialPlayableArea, null, function ItemRepickRemove)

    if autosave[pid] then
        set autosave[pid] = false
        call DisplayTextToPlayer(p, 0, 0, "|cffffcc00Autosave disabled.|r")
    endif

    call DestroyGroup(ug)

    set ug = null
    set target = null
    set itm = null
endfunction

function UnitDistance takes unit u1, unit u2 returns real
    local real dx= GetUnitX(u2)-GetUnitX(u1)
    local real dy= GetUnitY(u2)-GetUnitY(u1)

	return SquareRoot(dx * dx + dy * dy)
endfunction

function Distance takes location l1, location l2 returns real
    local real dx= GetLocationX(l2)-GetLocationX(l1)
    local real dy= GetLocationY(l2)-GetLocationY(l1)
    
	return SquareRoot(dx * dx + dy * dy)
endfunction

function DistanceCoords takes real x, real y, real x2, real y2 returns real
	return SquareRoot(Pow(x - x2, 2) + Pow(y - y2, 2))
endfunction

function ExpireUnit takes unit u returns nothing
    call UnitApplyTimedLife(u, 'BTLF', 0.1)
endfunction

function UnitResetAbility takes unit u, integer abid returns nothing
    local integer i =GetUnitAbilityLevel(u, abid)
    
    call UnitRemoveAbility(u, abid)
    call UnitAddAbility(u, abid)
    call SetUnitAbilityLevel(u, abid,i)
endfunction

function OnDefeat takes integer pid returns nothing
    local User p     = User[Player(pid - 1)]
    local integer i  = User.PlayingPlayerIndex[pid - 1]

    // clean up
    call ForceRemovePlayer(FORCE_PLAYING, p.toPlayer())

    call DialogDestroy(dChangeSkin[p.id])
    call DialogDestroy(dCosmetics[p.id])
    call DialogDestroy(heropanel[p.id])
    
    call MultiboardSetItemValueBJ(MULTI_BOARD, 1, udg_MultiBoardsSpot[p.id], p.name)
    call MultiboardSetItemColorBJ(MULTI_BOARD, 1, udg_MultiBoardsSpot[p.id], 60, 60, 60, 0)
    call MultiboardSetItemValueBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[p.id], "")
    call MultiboardSetItemValueBJ(MULTI_BOARD, 3, udg_MultiBoardsSpot[p.id], "")
    call MultiboardSetItemValueBJ(MULTI_BOARD, 4, udg_MultiBoardsSpot[p.id], "")
    call MultiboardSetItemValueBJ(MULTI_BOARD, 5, udg_MultiBoardsSpot[p.id], "")
    call MultiboardSetItemValueBJ(MULTI_BOARD, 6, udg_MultiBoardsSpot[p.id], "")
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 2, udg_MultiBoardsSpot[p.id], false, false)
    call MultiboardSetItemStyleBJ(MULTI_BOARD, 3, udg_MultiBoardsSpot[p.id], false, false)

    call PlayerCleanup(p.toPlayer())

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

function PlayerCountItemType takes integer pid, integer id returns integer
    local integer i = 0
    local integer j = 0

    loop
        exitwhen i == MAX_INVENTORY_SLOTS

        if Profile[pid].hero.items[i].id == id then
            if Profile[pid].hero.items[i].charges > 1 then
                set j = j + Profile[pid].hero.items[i].charges
            else
                set j = j + 1
            endif
        endif

        set i = i + 1
    endloop

    return j
endfunction

function PlayerHasItemType takes integer pid, integer id returns boolean
    local integer i = 0

    loop
        exitwhen i == MAX_INVENTORY_SLOTS

        if Profile[pid].hero.items[i].id == id then
            return true
        endif

        set i = i + 1
    endloop

    return false
endfunction

function HasItemType takes unit u, integer itid returns boolean
	local integer i = 0
    
    loop
        exitwhen i > 5
        if GetItemTypeId(UnitItemInSlot(u, i)) == itid then
            return true
        endif
        set i = i + 1
    endloop
    
    return false
endfunction

function GetResurrectionItem takes integer pid, boolean charge returns Item
    local integer i
    local Item itm

    set i = 0
    loop
        exitwhen i > 5
        set itm = Item[UnitItemInSlot(Hero[pid], i)]
        if itm != 0 then 
            if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Arrv' or ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Anrv' then
                if charge and ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Arrv' then
                    return itm
                elseif not charge and GetItemCharges(itm.obj) > 0 then
                    return itm
                endif
            endif
        endif
        set i = i + 1
    endloop

    if charge then
        set i = 0
        loop
            exitwhen i > 5
            set itm = Item[UnitItemInSlot(Backpack[pid], i)]
            if itm != 0 then 
                if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Arrv' or ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Anrv' then
                    if charge and ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == 'Arrv' then
                        return itm
                    elseif not charge and GetItemCharges(itm.obj) > 0 then
                        return itm
                    endif
                endif
            endif
            set i = i + 1
        endloop
    endif
    
	return 0
endfunction

function MoveExpire takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())

    set pt.dur = pt.dur - 1

    if pt.dur <= 0 then
        set bpmoving[pid] = false
        call TimerList[pid].removePlayerTimer(pt)
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

//adds commas
function RealToString takes real value returns string
    local string s = I2S(R2I(value))
    local integer len = StringLength(s)
    
	if len > 9 then
		set s = SubString(s, 0, len - 9) + "," + SubString(s, len - 9, len - 6) + "," + SubString(s, len - 6, len - 3) + "," + SubString(s, len - 3, len)
	elseif len > 6 then
		set s = SubString(s, 0, len - 6) + "," + SubString(s, len - 6, len - 3) + "," + SubString(s, len -3, len)
	elseif len > 3 then
		set s = SubString(s, 0, len - 3) + "," + SubString(s, len - 3, len)
	endif
	
	return s
endfunction

function ItemProfMod takes integer id, integer pid returns real
    local real mod = 1
    local integer prof = ItemData[id][ITEM_TYPE]

    if prof > 0 and prof != 5 and BlzBitAnd(PROF[prof], HERO_PROF[pid]) == 0 then
        set mod = 0.75
    endif

    return mod
endfunction

function ItemToIndex takes integer itemType returns integer
    return LoadInteger(SAVE_TABLE, KEY_ITEMS, itemType)
endfunction

function ItemInfo takes integer pid, Item itm returns nothing
    local integer i = 0
    local player p = Player(pid - 1)
    local string s = ""
    local integer offset = 3
    local integer cost = itm.calcStat(ITEM_COST, 0)

    if itm.level > 0 then
        call DisplayTimedTextToPlayer(p, 0, 0, 15., GetObjectName(itm.id) + " [" + LEVEL_PREFIX[itm.level] + "]")
    else
        call DisplayTimedTextToPlayer(p, 0, 0, 15., GetObjectName(itm.id))
    endif

    if cost > 0 then
        if (cost / 1000000) > 0 then
            call DisplayTimedTextToPlayer(p, 0, 0, 15., "|cffffcc00Cost|r: " + RealToString(cost / 1000000) + " |cffe3e2e2Platinum|r and " + RealToString(ModuloInteger(cost, 1000000)) + " |cffffcc00Gold|r")
        else
            call DisplayTimedTextToPlayer(p, 0, 0, 15., "|cffffcc00Cost|r: " + RealToString(cost) + " |cffffcc00Gold|r")
        endif
    endif

    if ItemProfMod(itm.id, pid) < 1 then
        call DisplayTimedTextToPlayer(p, 0, 0, 15., "|cffbbbbbbProficiency|r: " + RealToString(ItemProfMod(itm.id, pid) * 100) + "%")
    endif

    set i = ITEM_HEALTH
    loop
        exitwhen i > ITEM_STAT_TOTAL
            if ItemData[itm.id][i] != 0 and STAT_NAME[i] != null then
                if i == ITEM_MAGIC_RESIST or i == ITEM_DAMAGE_RESIST or i == ITEM_EVASION or i == ITEM_CRIT_CHANCE or i == ITEM_SPELLBOOST or i == ITEM_GOLD_GAIN then
                    set s = "%"
                    set offset = 4
                endif

                if i == ITEM_CRIT_CHANCE then
                    set i = i + 1
                    call DisplayTimedTextToPlayer(p, 0, 0, 15., SubString(STAT_NAME[i], offset, StringLength(STAT_NAME[i])) + ": " + RealToString(itm.calcStat(ITEM_CRIT_CHANCE, 0)) + "% " + RealToString(itm.calcStat(ITEM_CRIT_DAMAGE, 0)) + "x")
                else
                    call DisplayTimedTextToPlayer(p, 0, 0, 15., SubString(STAT_NAME[i], offset, StringLength(STAT_NAME[i])) + ": " + RealToString(itm.calcStat(i, 0)) + s)
                endif
            endif
        set i = i + 1
    endloop

    if ItemToIndex(itm.id) > 0 then //item info cannot be cast on backpacked items
        call DisplayTimedTextToPlayer(p, 0, 0, 15., "|c0000ff33Saveable|r")
    endif

    set p = null
endfunction

function SpawnCreeps takes integer flag returns nothing
    local integer i = 0
    local integer i2 = 0
    local integer typeIndex = 0
    local rect myregion = null
    local real x
    local real y
    
    loop
        set typeIndex = UnitData[flag][i]
        set i2 = 0
        exitwhen UnitData[flag][i] == 0
		loop
			exitwhen i2 >= UnitData[typeIndex][UNITDATA_COUNT]
			set myregion = SelectGroupedRegion(UnitData[typeIndex][UNITDATA_SPAWN])
            loop
                set x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
                set y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
                exitwhen IsTerrainWalkable(x, y)
            endloop
            call CreateUnit(pfoe, typeIndex, x, y, GetRandomInt(0, 359))
            set myregion = null
            set i2 = i2 + 1
		endloop

		set i = i + 1
    endloop
endfunction

function ShowHeroPanel takes player p, player p2, boolean show returns nothing
    if show == true then
        call MultiboardDisplayBJ(false, MULTI_BOARD)
        call SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_ADVANCED_CONTROL, true, p)
        call SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_CONTROL, false, p)
        call MultiboardDisplayBJ(true, MULTI_BOARD)
    else
        call SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_ADVANCED_CONTROL, false, p)
    endif
endfunction

function PlayerAddItemById takes integer pid, integer id returns Item
    local Item itm = Item.create(id, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
    local integer i = 12

    set itm.owner = Player(pid - 1)

    call UnitAddItem(Hero[pid], itm.obj)

    //stack check
    if itm == 0 then
        return 0
    endif

    if IsItemOwned(itm.obj) == false then
        call UnitAddItem(Backpack[pid], itm.obj)
    endif

    //stack check
    if itm == 0 then
        return 0
    endif

    if IsItemOwned(itm.obj) == false then
        loop
            exitwhen i == MAX_INVENTORY_SLOTS

            if Profile[pid].hero.items[i] == 0 and itm != 0 then
                call SetItemPosition(itm.obj, 30000., 30000.)
                call SetItemVisible(itm.obj, false)
                set Profile[pid].hero.items[i] = itm
                exitwhen true
            endif

            set i = i + 1
        endloop
    endif

    return itm
endfunction

function IsBindItem takes integer id returns boolean
    return (id == 'I002' or id == 'I000' or id == 'I03L' or id == 'I0N2' or id == 'I0N1' or id == 'I0N3' or id == 'I0FN' or id == 'I086' or id == 'I001' or id == 'I068' or id == 'I05S' or id == 'I04Q')
endfunction

function BuyHome takes unit u, integer plat, integer arc, integer id returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    
    if GetCurrency(pid, PLATINUM) < plat or GetCurrency(pid, ARCADITE) < arc then
		call DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 10, "You do not have enough resources to buy this.")
	else
		call PlayerAddItemById(pid, id)
        call AddCurrency(pid, PLATINUM, -plat)
        call AddCurrency(pid, ARCADITE, -arc)
		call DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 20, "You have purchased a " + GetObjectName(id) + ".")
		call DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 10, PlatTag + I2S(GetCurrency(pid, PLATINUM)))
		call DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 10, ArcTag + I2S(GetCurrency(pid, ARCADITE)))
	endif
endfunction

//used before equip
function GetEmptySlot takes unit u returns integer
    local integer i = 0

    loop
        exitwhen i > 5
        if UnitItemInSlot(u, i) == null then
            return i
        endif
        set i = i + 1
    endloop

    return i
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

    return -1
endfunction

function IsItemBound takes Item itm, integer pid returns boolean
    return (itm.owner != Player(pid - 1) and itm.owner != null)
endfunction

function IsItemRestricted takes Item itm returns boolean
    local integer i = 0
    local integer limit = ItemData[itm.id][ITEM_LIMIT]
    local Item itm2

    if limit == 0 then
        return false
    endif

    loop
		exitwhen i > 5

        set itm2 = Item[UnitItemInSlot(itm.holder, i)]

        if itm != itm2 then 
            if limit == 1 and itm.id != itm2.id then //safe 
            elseif limit == ItemData[itm2.id][ITEM_LIMIT] then
                call DisplayTextToPlayer(GetOwningPlayer(itm.holder), 0, 0, LIMIT_STRING[limit])
                return true
            endif
        endif

        set i = i + 1
	endloop

    return false
endfunction

function IsItemDud takes Item itm returns boolean
    return GetItemTypeId(itm.obj) == 'iDud'
endfunction

function GetItemFromPlayer takes integer pid, integer id returns Item
    local integer i = 0

    loop
        exitwhen i == MAX_INVENTORY_SLOTS

        if Profile[pid].hero.items[i].id == id then
            return Profile[pid].hero.items[i]
        endif

        set i = i + 1
    endloop

    return 0
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

function BossDrop takes integer id, integer chance, real x, real y returns nothing
    local integer i = 0
    local Item itm

    loop
        exitwhen i > HardMode
            if GetRandomInt(0, 99) < chance then
                set itm = Item.create(DropTable.pickItem(id), x, y, 600.)
                set itm.lvl = IMaxBJ(0, ItemData[itm.id][ITEM_UPGRADE_MAX] - GetRandomInt(8, 11))
            endif
        set i = i + 1
    endloop
endfunction

function GetHeroStat takes integer stat, unit u, boolean bonuses returns integer
    if (stat == 1) then
        return GetHeroStr(u, bonuses)
    elseif (stat == 2) then
        return GetHeroInt(u, bonuses)
    elseif (stat == 3) then
        return GetHeroAgi(u, bonuses)
    endif

    return 0
endfunction

function GetLineIntersection takes real p0_x, real p0_y, real p1_x, real p1_y, real p2_x, real p2_y, real p3_x, real p3_y returns location
    local real s1_x = p1_x - p0_x
    local real s1_y = p1_y - p0_y
    local real s2_x = p3_x - p2_x
    local real s2_y = p3_y - p2_y
    local real s = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y)
    local real t = (s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) / (-s2_x * s1_y + s1_x * s2_y)
    local real i_x = 0.
    local real i_y = 0.

    if (s >= 0.0 and s <= 1.0 and t >= 0.0 and t <= 1.0) then
        // collision
        set i_x = p0_x + (t * s1_x)
        set i_y = p0_y + (t * s1_y)

        return Location(i_x, i_y)
    endif

    //no collision
    return null
endfunction

function LineContainsRect takes real x, real y, real x2, real y2, real MinX, real MinY, real MaxX, real MaxY returns boolean
    local location leftSide = GetLineIntersection(x, y, x2, y2, MinX, MinY, MinX, MaxY)
    local location rightSide = GetLineIntersection(x, y, x2, y2, MaxX, MinY, MaxX, MaxY)
    local location bottomSide = GetLineIntersection(x, y, x2, y2, MinX, MinY, MaxX, MinY)
    local location topSide = GetLineIntersection(x, y, x2, y2, MinX, MaxY, MaxX, MaxY)
    local boolean b = (leftSide != null or rightSide != null or bottomSide != null or topSide != null)

    call RemoveLocation(leftSide)
    call RemoveLocation(rightSide)
    call RemoveLocation(bottomSide)
    call RemoveLocation(topSide)
    
    set leftSide = null
    set rightSide = null
    set bottomSide = null
    set topSide = null
    
    return b
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
    elseif BlzGroupGetSize(ug) > 0 and BlzGroupGetSize(ug) < 36 and not ChaosMode then
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
        
        if UnitAlive(gg_unit_N01N_0050) then
            call UnitAddAbility(gg_unit_N01N_0050, 'Avul')
        endif
    endif

    call DestroyGroup(ug)
    
    set ug = null
    set t = null
endfunction

function SpawnForgotten takes nothing returns nothing
    local integer id = forgottenTypes[GetRandomInt(0, 4)]
    
    if UnitAlive(forgottenSpawner) and forgottenCount < 5 then
        set forgottenCount = forgottenCount + 1
        call CreateUnit(pfoe, id, 13699 + GetRandomInt(-250, 250), -14393 + GetRandomInt(-250, 250), GetRandomInt(0, 359))
    endif
endfunction

function EnumDestroyTreesInRange takes nothing returns nothing 
    local destructable d = GetEnumDestructable()
    local integer did = GetDestructableTypeId(d)
    local real x = LoadReal(MiscHash, 'tree', 0)
    local real y = LoadReal(MiscHash, 'tree', 1)
    local real range = LoadReal(MiscHash, 'tree', 2)

	if (did == 'ITtw' or did == 'JTtw' or did == 'FTtw' or did == 'NTtw' or did == 'B00B' or did == 'B00H' or did == 'ITtc' or did =='NTtc' or did == 'WTst' or did == 'WTtw') and DistanceCoords(x, y, GetDestructableX(d), GetDestructableY(d)) <= range then
		call KillDestructable(d)
	endif

	set d = null
endfunction

function DestroyTreesInRange takes real x, real y, real range returns nothing
    local rect r = Rect(x - range, y - range, x + range, y + range)

    call SaveReal(MiscHash, 'tree', 0, x)
    call SaveReal(MiscHash, 'tree', 1, y)
    call SaveReal(MiscHash, 'tree', 2, range)
	call EnumDestructablesInRect(r, null, function EnumDestroyTreesInRange)
    call FlushChildHashtable(MiscHash, 'tree')

    call RemoveRect(r)
    set r = null
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
    local Stun stun = Stun.add(Hero[pid], target)

    if IsUnitType(target, UNIT_TYPE_HERO) then
        set stun.duration = duration * 0.5
    else
        set stun.duration = duration
    endif
endfunction

//highlight
function HL takes string s, boolean y returns string
    if y then
        return ("|cffffcc00" + s + "|r")
    else
        return s
    endif
endfunction

function GetAbilityField takes unit u, integer id, integer index returns real 
    return BlzGetAbilityRealLevelField(BlzGetUnitAbility(u, id), SPELL_FIELD[index], 0)
endfunction

function ItemAddSpellDelayed takes nothing returns nothing
    local Item itm = Item(ReleaseTimer(GetExpiredTimer()))
    local integer i = 1
    local integer count = 1
    local integer value = 0
    local integer index = ITEM_ABILITY
    local string s = ""
    local integer abilid = 0

    loop
        set s = ItemData[itm.id].string[index * ABILITY_OFFSET]
        set abilid = String2Id(SubString(s, 0, 4))

        if ItemData[itm.id][index] != 0 then //ability exists
            call BlzItemAddAbility(itm.obj, abilid)

            if abilid == 'Aarm' then //armor aura
                call BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_ARMOR_BONUS_HAD1, 0, itm.calcStat(index, 0))
            elseif abilid == 'Abas' then //bash
                call BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_CHANCE_TO_BASH, 0, itm.calcStat(index, 0))
                call BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_DURATION_NORMAL, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
                call BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_DURATION_HERO, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
            elseif abilid == 'A018' or abilid == 'A01S' then //blink
                call BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_MAXIMUM_RANGE, 0, itm.calcStat(index, 0))
            else //channel
                call BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), SPELL_FIELD[0], 0, itm.calcStat(index, 0))

                loop
                    exitwhen i > SPELL_FIELD_TOTAL
                    set value = ItemData[itm.id][index * ABILITY_OFFSET + count]

                    if value != 0 then
                        call BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), SPELL_FIELD[i], 0, value)
                    endif

                    set i = i + 1
                endloop
            endif

            call IncUnitAbilityLevel(itm.holder, abilid)
            call DecUnitAbilityLevel(itm.holder, abilid)
        endif

        set index = index + 1
        exitwhen index > ITEM_ABILITY2
    endloop
endfunction

function ParseItemAbilityTooltip takes integer itm, integer index, integer value, integer lower, integer upper returns string
    local string s = ItemData[Item(itm).id].string[index * ABILITY_OFFSET]
    local integer id = ItemData[Item(itm).id][index * ABILITY_OFFSET]
    local string orig = BlzGetAbilityExtendedTooltip(id, 0)
    local string newstring = ""
    local string tag = ""
    local integer i = 5
    local integer i2 = 6
    local integer start = 5
    local integer end = 0
    local integer count = 1
    local integer array values

    set values[0] = value

    //start at 5 index to ignore ability id
    loop
        exitwhen i2 > StringLength(s) + 1

        if SubString(s, i, i2) == " " or i2 > StringLength(s) then
            set end = i

            set values[count] = S2I(SubString(s, start, end))

            set ItemData[Item(itm).id][index * ABILITY_OFFSET + count] = values[count]
            set count = count + 1

            set start = i2
        endif

        set i = i + 1
        set i2 = i2 + 1
    endloop

    set i = 0
    set i2 = 1
    set start = 0

    loop
        exitwhen i2 > StringLength(orig) + 1

        if SubString(orig, i, i2) == "$" then
            set end = i
            set tag = SubString(orig, i + 1, i2 + 1)

            set newstring = newstring + SubString(orig, start, end)
            if upper > 0 then
                set newstring = newstring + I2S(lower) + "-" + I2S(upper)
            else
                set newstring = newstring + I2S(values[S2I(tag) - 1])
            endif

            set start = i2 + 1
        endif

        set i = i + 1
        set i2 = i2 + 1
    endloop 

    set newstring = newstring + SubString(orig, start, StringLength(orig))

    if newstring == "" then
        return orig
    else
        return newstring
    endif
endfunction

function ParseItemTooltip takes item itm, string s returns nothing
    local string orig = BlzGetItemExtendedTooltip(itm)
    local string tag = ""
    local integer i = 0
    local integer i2 = 1
    local integer i3 = 0
    local integer i4 = 0
    local integer array start
    local integer array end
    local integer itemid = GetItemTypeId(itm)
    local integer index = 0
    local integer count = 0
    local integer SYNTAX_COUNT = 7
    
    //debug testing
    if s != "" then
        set orig = s
    endif

    //store original tooltip [id][0]
    set ItemData[itemid].string[ITEM_TOOLTIP] = orig

    loop
        exitwhen i2 > StringLength(orig) + 1

        if SubString(orig, i, i2) == "[" then
            set i3 = i2

            set tag = ""
            set start[0] = i2
            set start[1] = 0
            set start[2] = 0
            set start[3] = 0
            set start[4] = 0
            set start[5] = 0
            set start[6] = 0
            set start[7] = 0
            set end[0] = i2
            set end[1] = 0
            set end[2] = 0
            set end[3] = 0
            set end[4] = 0
            set end[5] = 0
            set end[6] = 0
            set end[7] = 0
            set count = 0
            set i4 = 0

            loop
                set i3 = i3 + 1
                set end[0] = end[0] + 1
                set tag = SubString(orig, i3, end[0] + 1)
                if tag == "*" or tag == " " then
                    set index = LoadInteger(SAVE_TABLE, KEY_ITEMS, StringHash(SubString(orig, start[0], end[0])))
                    //stat is not fixed
                    if tag == "*" then
                        set ItemData[itemid][index + BOUNDS_OFFSET * 6] = 1
                    endif
                    exitwhen true
                endif
            endloop

            set start[0] = end[0] + 1

            loop
                set i3 = i3 + 1
                set end[0] = end[0] + 1
                set tag = SubString(orig, i3, end[0] + 1)
                //value range
                if tag == "|" then
                    set start[1] = end[0] + 1
                    set end[count] = i3
                    set count = count + 1
                //flat per level
                elseif tag == "=" then
                    set start[2] = end[0] + 1
                    set end[count] = i3
                    set count = count + 1
                //flat per rarity
                elseif tag == ">" then
                    set start[3] = end[0] + 1
                    set end[count] = i3
                    set count = count + 1
                //percent effectiveness
                elseif tag == "%" then
                    set start[4] = end[0] + 1
                    set end[count] = i3
                    set count = count + 1
                //unlock at
                elseif tag == "@" then
                    set start[5] = end[0] + 1
                    set end[count] = i3
                    set count = count + 1
                //ability id
                elseif tag == "#" then
                    set start[7] = end[0] + 1
                    set end[count] = i3
                    set count = count + 1
                elseif tag == "]" then
                    set end[count] = i3
                    set count = count + 1
                    exitwhen true
                endif
            endloop

            set count = 0

            loop
                exitwhen i4 > SYNTAX_COUNT

                if start[i4] > 0 then
                    if i4 == 7 then //ability
                        set ItemData[itemid][index * ABILITY_OFFSET] = String2Id(SubString(orig, start[i4], start[i4] + 4))
                        set ItemData[itemid].string[index * ABILITY_OFFSET] = SubString(orig, start[i4], end[count])
                    else
                        set ItemData[itemid][index + BOUNDS_OFFSET * i4] = S2I(SubString(orig, start[i4], end[count])) 
                    endif
                    set count = count + 1
                endif

                set i4 = i4 + 1
            endloop
        endif
    
        set i = i + 1
        set i2 = i2 + 1
    endloop
endfunction

//parses brackets [] = normal boost {] = low boost \] = no boost > = no color
function GetSpellTooltip takes Spell spell, string orig returns string
    local string newstring = ""
    local integer i = 0
    local integer i2 = 1
    local integer start = 0
    local integer end = 0
    local integer count = 0
    local boolean color = true

    loop
        exitwhen i2 > StringLength(orig) + 1
        if SubString(orig, i, i2) == "[" or SubString(orig, i, i2) == "{" or SubString(orig, i, i2) == "\\" then
            set end = i

            if SubString(orig, i - 1, i2 - 1) == ">" then
                set color = false
                set end = end - 1
            endif

            if altModifier[spell.pid] then
                if SubString(orig, i, i2) == "[" then
                    set newstring = newstring + SubString(orig, start, end) + HL(RealToString(spell.values[count] * (1. + BoostValue[spell.pid] - 0.2)) + " - " + RealToString(spell.values[count] * (1. + BoostValue[spell.pid] + 0.2)), color)
                elseif SubString(orig, i, i2) == "{" then
                    set newstring = newstring + SubString(orig, start, end) + HL(RealToString(spell.values[count] * LBOOST[spell.pid]), color)
                elseif SubString(orig, i, i2) == "\\" then
                    set newstring = newstring + SubString(orig, start, end) + HL(RealToString(spell.values[count]), color)
                endif
            else
                set newstring = newstring + SubString(orig, start, end)
            endif

            set start = i2

            set count = count + 1
        elseif SubString(orig, i, i2) == "]" then
            set color = true
            set end = i

            if not altModifier[spell.pid] then
                set newstring = newstring + SubString(orig, start, end)
            endif

            set start = i2
        endif
    
        set i = i + 1
        set i2 = i2 + 1
    endloop

    return newstring + SubString(orig, start, StringLength(orig))
endfunction

function SpellCast takes unit u, integer id, real dur, integer anim returns nothing
    call BlzStartUnitAbilityCooldown(u, id, BlzGetUnitAbilityCooldown(u, id, GetUnitAbilityLevel(u, id) - 1))

    call DelayAnimation(BOSS_ID, u, dur, 0, 1., true)
    call SetUnitAnimationByIndex(u, anim)
endfunction

function UpdateSpellTooltips takes integer pid returns nothing
    local integer i = 0
    local integer sid = 0
    local integer spell = 0
    local ability abil
    local string tooltip = ""
    local Spell mySpell

    loop
        set abil = BlzGetUnitAbilityByIndex(Hero[pid], i)
        exitwhen abil == null
        set sid = BlzGetAbilityId(abil)
        set spell = LoadInteger(SAVE_TABLE, KEY_SPELLS, sid)

        if spell != 0 then
            set mySpell = Spell.create(spell)
            call mySpell.setValues(pid)

            set tooltip = GetSpellTooltip(mySpell, SpellTooltips[sid].string[mySpell.ablev])

            if GetLocalPlayer() == Player(pid - 1) then
                call BlzSetAbilityExtendedTooltip(sid, tooltip, mySpell.ablev - 1)
                call BlzSetAbilityActivatedExtendedTooltip(sid, tooltip, mySpell.ablev - 1)
            endif

            call mySpell.destroy()
        endif

        set i = i + 1
    endloop

    call SetPlayerAbilityAvailable(pfoe, 'Agyv', true)
    call SetPlayerAbilityAvailable(pfoe, 'Agyv', false)
endfunction

function kgold takes real gold returns string
    local integer g = R2I(gold)

	if gold > 10000 then
		return "+" + I2S(R2I(g* 0.001)) + "K"
	else
		return "+" + I2S(g)
	endif
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
        
        if UnitAlive(target) then
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
    local integer count = 0
    
    //1 nation, 2 home, 3 grand home, 4 grand nation, 5 lounge, 6 satan home, 7 chaotic nation

    //get multiple of 5 from hero level
    if urhome[pid] > 0 then
        set xpRate = BaseExperience[R2I(HeroLevel / 5.) * 5]

        if urhome[pid] == 1 then
            set xpRate = xpRate * .6
        elseif urhome[pid] == 2 then
            set xpRate = xpRate * 1.0
        elseif urhome[pid] == 3 then
            set xpRate = xpRate * 1.1
        elseif urhome[pid] == 4 then
            set xpRate = xpRate * .9
        elseif urhome[pid] == 5 then
            set xpRate = xpRate * 1.0
        elseif urhome[pid] == 6 then
            set xpRate = xpRate * 1.6
        elseif urhome[pid] == 7 then
            set xpRate = xpRate * 1.3
        endif
    elseif HeroLevel < 15 then
        set xpRate = 100
    endif

    if urhome[pid] <= 4 and HeroLevel >= 180 then
        set xpRate = 0
    endif
	
	if InColo[pid] then
		set xpRate = xpRate * udg_Colloseum_XP[pid] * (0.6 + 0.4 * ColoPlayerCount)
	elseif InStruggle[pid] then
		set xpRate = xpRate * .3
	endif

	set udg_XP_Rate[pid] = RMaxBJ(0, xpRate * (1. + 0.04 * PrestigeTable[pid][0]) - warriorCount[pid] - rangerCount[pid])
endfunction

function Plat_Effect takes player Owner returns nothing
    local integer i = 0
    local real x = GetUnitX(Hero[GetConvertedPlayerId(Owner)])
    local real y = GetUnitY(Hero[GetConvertedPlayerId(Owner)])

	loop
		exitwhen i > 40
		call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl" ,x + GetRandomInt(-200,200) ,y + GetRandomInt(-200,200)))
		set i = i + 1
	endloop
endfunction

function AwardGold takes player p, real goldawarded, boolean displaymessage returns integer
    local integer pid = GetPlayerId(p) + 1
    local integer goldWon
    local integer platWon
    local integer intReturn

    set goldWon = R2I(goldawarded * GetRandomReal(0.9,1.1))
    set goldWon = R2I(goldWon * (1 + ((ItemGoldRate[pid] + Gld_mod[pid]) * 0.01)))
    set intReturn = goldWon

    set platWon = goldWon / 1000000
	set goldWon = goldWon - platWon * 1000000

    call AddCurrency(pid, PLATINUM, platWon)
    call AddCurrency(pid, GOLD, goldWon)
	
	if displaymessage then
		if platWon > 0 then
			call DisplayTimedTextToPlayer(p,0,0, 10, "|c00ebeb15You have gained " +I2S(goldWon) +" gold and " +I2S(platWon) +" platinum coins.")
			call DisplayTimedTextToPlayer(p, 0, 0, 10, PlatTag + I2S(GetCurrency(pid, PLATINUM)))
		else
			call DisplayTimedTextToPlayer(p,0,0, 10, "|c00ebeb15You have gained " +I2S(goldWon) +" gold.")
		endif
	endif

    return intReturn
endfunction

function DoFloatingTextUnit takes string s, unit u, real dur, real speed, real zOffset, real size, integer red, integer green, integer blue, integer transparency returns nothing
    set bj_lastCreatedTextTag = CreateTextTag()

	call SetTextTagText(bj_lastCreatedTextTag, s, size * 0.0023)
	call SetTextTagPos(bj_lastCreatedTextTag, GetUnitX(u), GetUnitY(u), zOffset)
	call SetTextTagColor(bj_lastCreatedTextTag, red, green, blue, 255 - transparency)
	call SetTextTagPermanent(bj_lastCreatedTextTag, false)
	call SetTextTagVelocity(bj_lastCreatedTextTag, 0, speed / 1803.)
	call SetTextTagLifespan(bj_lastCreatedTextTag, dur)
	call SetTextTagFadepoint(bj_lastCreatedTextTag, dur - .4)
endfunction

function DoFloatingTextCoords takes string s, real x, real y, real dur, real speed, real zOffset, real size, integer red, integer green, integer blue, integer transparency returns nothing
    set bj_lastCreatedTextTag = CreateTextTag()

	call SetTextTagText(bj_lastCreatedTextTag, s, size * 0.0023)
	call SetTextTagPos(bj_lastCreatedTextTag, x, y, zOffset)
	call SetTextTagColor(bj_lastCreatedTextTag, red, green, blue, 255 - transparency)
	call SetTextTagPermanent(bj_lastCreatedTextTag, false)
	call SetTextTagVelocity(bj_lastCreatedTextTag, 0, speed / 1803.)
	call SetTextTagLifespan(bj_lastCreatedTextTag, dur)
	call SetTextTagFadepoint(bj_lastCreatedTextTag, dur - .4)
endfunction

function AwardCrystals takes integer id, real x, real y returns nothing
    local User u = User.first
    local integer count = CrystalRewards[id]

    if count == 0 then
        return
    endif

	if HardMode > 0 then
		set count = count * 2
	endif

	loop
        exitwhen u == User.NULL

        if IsUnitInRangeXY(Hero[u.id], x, y, NEARBY_BOSS_RANGE) and GetHeroLevel(Hero[u.id]) >= BossLevel[IsBoss(id)] then
            call AddCurrency(u.id, CRYSTAL, count)

            if count == 1 then
                call DoFloatingTextUnit("+" + I2S(count) + " Crystal", Hero[u.id], 2.1, 80, 90, 9, 70, 150, 230, 0)
            else
                call DoFloatingTextUnit("+" + I2S(count) + " Crystals", Hero[u.id], 2.1, 80, 90, 9, 70, 150, 230, 0)
            endif
        endif

        set u = u.next
	endloop
endfunction

function HP takes unit u, real hp returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1

    //undying rage heal delay
    if TimerList[pid].get(u, null, UndyingRageBuff.typeid) != 0 then
        call UndyingRageBuff(Buff.get(u, u, UndyingRageBuff.typeid)).addRegen(hp)
    else
        call SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u, UNIT_STATE_LIFE) + hp)
        call DoFloatingTextUnit(RealToString(hp), u, 2, 50, 0, 10, 125, 255, 125, 0)
    endif
endfunction

function MP takes unit u, real hp returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1

	call SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MANA) + hp)
    call DoFloatingTextUnit(RealToString(hp), u, 2, 50, -70, 10, 0, 255, 255, 0)
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

function BinomialCoefficient takes integer n, integer k returns integer
    local integer i = 0
    local integer result = 1

    if k > n then
        return 0
    endif

    loop
        exitwhen i > k - 1
        set result = result * (n - i) / (i + 1)

        set i = i + 1
    endloop

    return result
endfunction

struct BezierCurve
    integer numPoints = 0
    real array pointX[10]
    real array pointY[10]

    real X = 0.
    real Y = 0.

    method addPoint takes real x, real y returns nothing
        set pointX[numPoints] = x
        set pointY[numPoints] = y

        set numPoints = numPoints + 1
    endmethod

    method calcT takes real t returns nothing
        local integer n = numPoints - 1
        local real resultX = 0.
        local real resultY = 0.
        local integer i = 0
        local real blend = 0.

        loop
            exitwhen i > n
            set blend = BinomialCoefficient(n, i) * Pow(t, i) * Pow(1 - t, n - i)
            set resultX = resultX + blend * pointX[i]
            set resultY = resultY + blend * pointY[i]

            set i = i + 1
        endloop

        set X = resultX
        set Y = resultY
    endmethod
endstruct

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

function ApplyFade takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer r = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_RED)
    local integer g = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_BLUE)
    local integer b = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_GREEN)

    if GetUnitAbilityLevel(pt.target, 'B02E') > 0 then //magnetic stance
        set r = 255
        set g = 25
        set b = 25
    endif

    set pt.int = IMinBJ(255, R2I(pt.int + 7.8 / pt.dur))
    
    if pt.agi > 0 then
        call SetUnitVertexColor(pt.target, r, g, b, 255 - pt.int)
    else
        call SetUnitVertexColor(pt.target, r, g, b, pt.int)
    endif

    if pt.int >= 255 or not UnitAlive(pt.target) then
        call TimerList[pid].removePlayerTimer(pt)
    endif
endfunction

function Fade takes unit u, real dur, boolean fade returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local PlayerTimer pt = TimerList[pid].addTimer(pid)

    set pt.target = u
    if fade then
        set pt.agi = 1
    else
        set pt.agi = -1
    endif
    set pt.dur = dur
    set pt.int = 0

    call TimerStart(pt.timer, 0.03, true, function ApplyFade)
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

function HideSummonDelay takes nothing returns nothing
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

    call TimerStart(GetExpiredTimer(), 1., false, function HideSummonDelay)
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

            call TimerStart(pt.timer, 2., false, function HideSummon)
        endif

        if UnitAlive(u) then
            call KillUnit(u)
        endif
    endif
endfunction

function SummonDurationXPBar takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local integer lev = GetHeroLevel(pt.target)

    //call DEBUGMSG(RealToString(pt.dur))

    if GetUnitTypeId(pt.target) == SUMMON_GOLEM and BorrowedLife[pid * 10] > 0 then
        set BorrowedLife[pid * 10] = BorrowedLife[pid * 10] - 0.5
    elseif GetUnitTypeId(pt.target) == SUMMON_DESTROYER and BorrowedLife[pid * 10 + 1] > 0 then
        set BorrowedLife[pid * 10 + 1] = BorrowedLife[pid * 10 + 1] - 0.5
    else
        set pt.dur = pt.dur - 0.5
    endif

    if pt.dur <= 0 then
        call SummonExpire(pt.target)
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
            call SetUnitPathing(target, false)
            call SetUnitPathing(target, true)
            call BlzSetUnitFacingEx(target, GetUnitFacing(Hero[pid]))
        endif
        set index = index + 1
        exitwhen index >= count
    endloop
    
    set p = null
    set target = null
endfunction

function reselect takes unit u returns nothing
	if (GetLocalPlayer() == GetOwningPlayer(u)) then
        call ClearSelection()
		call SelectUnit(u, true)
	endif
endfunction

function FilterHound takes nothing returns boolean
    if UnitAlive(GetFilterUnit()) and GetUnitTypeId(GetFilterUnit()) == SUMMON_HOUND then
        if GetOwningPlayer(GetFilterUnit()) == Player(passedValue[callbackCount] - 1) then
            return true
        endif
    endif

    return false
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
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == false then
            return true
        endif
    endif

    return false
endfunction

function FilterAllyHero takes nothing returns boolean
    if IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true and UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == true then
            return true
        endif
    endif

    return false
endfunction

function FilterAlly takes nothing returns boolean
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == true then
            return true
        endif
    endif

    return false
endfunction

function FilterEnemyAwake takes nothing returns boolean
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == false and UnitIsSleeping(GetFilterUnit()) == false then
            return true
        endif
    endif

    return false
endfunction

function FilterNotIllusion takes nothing returns boolean
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
        if IsUnitIllusion(GetFilterUnit()) == false then
            return true
        endif
    endif

    return false
endfunction

function FilterAlive takes nothing returns boolean
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),'Avul') == 0 and GetUnitAbilityLevel(GetFilterUnit(),'Aloc') == 0 and GetUnitTypeId(GetFilterUnit()) != DUMMY then
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
                if UnitAlive(Hero[U.id]) then
                    call SetUnitPositionLoc(Hero[U.id], TownCenter)
                elseif IsUnitHidden(HeroGrave[U.id]) == false then
                    call SetUnitPositionLoc(HeroGrave[U.id], TownCenter)
                endif
                call DisplayTextToPlayer(U.toPlayer(), 0, 0, "You escaped the Colosseum successfully.")
                set udg_Colloseum_XP[U.id] = (udg_Colloseum_XP[U.id] - 0.05)
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
            call DoFloatingTextCoords("Wave " + I2S(ColoWaveCount), GetLocationX(ColosseumCenter), GetLocationY(ColosseumCenter), 3.20, 32.0, 0, 18.0, 255, 0, 0, 0)
        elseif ColoCount_main[udg_Wave] <= 0 then
            set U = User.first

            set udg_GoldWon_Colo= R2I(udg_GoldWon_Colo * 1.2)

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
                    if UnitAlive(Hero[U.id]) then
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

            call SetTextTagText(ColoText, "Colosseum", 10 * 0.023 / 10)
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
            if UnitAlive(Hero[U.id]) then
                call SetUnitPositionLoc(Hero[U.id], TownCenter)
            elseif IsUnitHidden(HeroGrave[U.id]) == false then
                call SetUnitPositionLoc(HeroGrave[U.id], TownCenter)
            endif
			call SetCameraBoundsRectForPlayerEx(U.toPlayer(), gg_rct_Main_Map_Vision)
			call PanCameraToTimedLocForPlayer(U.toPlayer(), TownCenter, 0)
            call ExperienceControl(U.id)
			call DisplayTextToPlayer(U.toPlayer(), 0, 0, "You escaped Struggle with your life.")
			call AwardGold(U.toPlayer(), udg_GoldWon_Struggle, true)
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
        if udg_Struggle_WaveU[udg_Struggle_WaveN] <= 0 then // Struggle Won
            set udg_GoldWon_Struggle= R2I(udg_GoldWon_Struggle * 1.5)
            call SetTextTagTextBJ(StruggleText, ("Gold won: " + I2S(udg_GoldWon_Struggle)), 10.00)

            set U = User.first
            
            loop
                exitwhen U == User.NULL
                if InStruggle[U.id] then
                    set InStruggle[U.id] = false
                    set udg_Struggle_Pcount = udg_Struggle_Pcount - 1
                    call DisplayTextToPlayer(U.toPlayer(), 0, 0, "50% bonus gold for victory!")
                    if UnitAlive(Hero[U.id]) then
                        call SetUnitPositionLoc(Hero[U.id], TownCenter)
                    elseif IsUnitHidden(HeroGrave[U.id]) == false then
                        call SetUnitPositionLoc(HeroGrave[U.id], TownCenter)
                    endif
                    call EnableItems(U.id)
                    call SetUnitPositionLoc(Backpack[U.id], TownCenter)
                    call SetCameraBoundsRectForPlayerEx(U.toPlayer(), gg_rct_Main_Map_Vision)
                    call PanCameraToTimedLocForPlayer(U.toPlayer(), TownCenter, 0)
                    if udg_Struggle_WaveN < 40 then
                        call DisplayTextToPlayer(U.toPlayer(),0,0, "You received a lesser ring of struggle for completing struggle.")
                        call PlayerAddItemById(U.id, 'I00T')
                    else
                        call DisplayTextToPlayer(U.toPlayer(),0,0, "You received a ring of struggle for completing chaotic struggle.")
                        call PlayerAddItemById(U.id, 'I0D0')
                    endif
                    call AwardGold(U.toPlayer(),udg_GoldWon_Struggle,true)
                    call ExperienceControl(U.id)
                    call RecallSummons(U.id)
                    set U = U.next
                endif
            endloop
            
            call ClearStruggle()
        else
            if udg_Struggle_WaveN > 40 then
                call DoFloatingTextCoords("Wave " + I2S(udg_Struggle_WaveN - 40), GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), 3.80, 32.0, 0, 18.0, 255, 0, 0, 0)
            else
                call DoFloatingTextCoords("Wave " + I2S(udg_Struggle_WaveN), GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), 3.80, 32.0, 0, 18.0, 255, 0, 0, 0)
            endif
        endif
	endif
    
    call DestroyGroup(ug)
    
    set ug = null
    set u = null
endfunction

function Recipe takes integer itid1, integer req1, integer itid2, integer req2, integer itid3, integer req3, integer itid4, integer req4, integer itid5, integer req5,integer itid6, integer req6, integer FINAL_ID, integer FINAL_CHARGES, unit creatingunit, real platCost, real arcCost, integer crystals, boolean hidemessage returns boolean
    local integer i = 0
    local integer i2 = 0
    local integer array itemsNeeded
    local integer array itemsHeld
    local integer array itemType
    local player owner = GetOwningPlayer(creatingunit)
    local integer pid = GetPlayerId(owner) + 1
    local boolean fail = false
    local integer levelreq = 0
    local integer cost
    local boolean success = false
    local item itm
    local integer array origcount 
    local integer origowner = 0
    local integer goldcost = R2I(ModuloReal(platCost, R2I(RMaxBJ(platCost, 1))) * 1000000)
    local integer lumbercost = R2I(ModuloReal(arcCost, R2I(RMaxBJ(arcCost, 1))) * 1000000)
    local Item FINAL_ITEM
    
    set itemType[0] = itid1
    set itemType[1] = itid2
    set itemType[2] = itid3
    set itemType[3] = itid4
    set itemType[4] = itid5
    set itemType[5] = itid6
    set itemsNeeded[0] = req1
    set itemsNeeded[1] = req2
    set itemsNeeded[2] = req3
    set itemsNeeded[3] = req4
    set itemsNeeded[4] = req5
    set itemsNeeded[5] = req6
    
    loop
        exitwhen i > 5
        set i2 = 0
        loop
            exitwhen i2 > 5
            if creatingunit == ASHEN_VAT then //vat
                set itm = UnitItemInSlot(creatingunit, i2)
                if GetItemTypeId(itm) == 'I04Q' then //demon golem fist heart
                    if HeartBlood[GetItemUserData(itm)] < 2000 then
                        set itemsHeld[i] = itemsHeld[i] - 1
                    endif
                endif
                if GetItemTypeId(itm) == itemType[i] then
                    set origcount[GetItemUserData(itm)] = origcount[GetItemUserData(itm)] + 1
                    if GetItemCharges(itm) > 1 then
                        set itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        set itemsHeld[i] = itemsHeld[i] + 1
                    endif
                endif
            else
                set itm = UnitItemInSlot(Hero[pid], i2)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        set itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        set itemsHeld[i] = itemsHeld[i] + 1
                    endif
                endif
                set itm = UnitItemInSlot(Backpack[pid], i2)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        set itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        set itemsHeld[i] = itemsHeld[i] + 1
                    endif
                endif
            endif
            
            set i2 = i2 + 1
        endloop
        set i = i + 1
    endloop

    set i = 0
    
    loop
        exitwhen i > 5
        if itemsHeld[i] < itemsNeeded[i] then
            set fail = true
            exitwhen true
        endif
        set i = i + 1
    endloop

    set i = 1

    loop //disallow multiple bound items
        exitwhen i > 6
        if origcount[i] > 0 then
            if origowner > 0 and origowner != i then
                set origowner = -1
                set fail = true
                exitwhen true
            endif
            set origowner = i
        endif
        set i = i + 1
    endloop
	
    if hidemessage then //mostly for ashen vat
        if fail then
            if origowner == -1 then
                call DisplayTextToForce(FORCE_PLAYING, "The Ashen Vat will not accept bound items from multiple players.")
            endif
        else
            set success = true
            set i = 0
            loop
                exitwhen i > 5
                set i2 = 0
                if itemType[i] > 0 then
                    loop
                        set i2 = i2 + 1
                        exitwhen i2 > itemsNeeded[i]
                        if creatingunit == ASHEN_VAT then
                            if HasItemType(creatingunit, itemType[i]) then
                                call Item[GetItemFromUnit(creatingunit, itemType[i])].useInRecipe()
                            endif
                        else
                            if PlayerHasItemType(pid, itemType[i]) then
                                call GetItemFromPlayer(pid, itemType[i]).useInRecipe()
                            endif
                        endif
                    endloop
                endif
                set i = i + 1
            endloop

            if FINAL_ID != 0 then
                set FINAL_ITEM = Item.create(FINAL_ID, 30000., 30000., 0)
                set FINAL_ITEM.charge = FINAL_CHARGES

                set FINAL_ITEM.owner = Player(origowner - 1)
                call UnitAddItem(creatingunit, FINAL_ITEM.obj)
            endif
        endif
    else
        set levelreq = ItemData[FINAL_ID][ITEM_LEVEL_REQUIREMENT]

        if levelreq > GetUnitLevel(Hero[pid]) then
            call DisplayTimedTextToPlayer(owner,0,0, 15., "This item requires at least level |cffFF5555"+ I2S(levelreq) +"|r to use.")
        elseif GetCurrency(pid, GOLD) < goldcost then
            call DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough gold.")
        elseif GetCurrency(pid, LUMBER) < lumbercost then
            call DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough lumber.")
        elseif GetCurrency(pid, PLATINUM) < platCost then
            call DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough platinum.")
        elseif GetCurrency(pid, ARCADITE) < arcCost then
            call DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough arcadite.")
        elseif GetCurrency(pid, CRYSTAL) < crystals then
            call DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough crystals.")
        elseif fail then
            call DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have the required items.")
        else
            call DisplayTimedTextToPlayer(owner,0,0, 30, "|cff00cc00Success!|r")
            set success = true
            set i = 0
            loop
                exitwhen i > 5
                set i2 = 0
                if itemType[i] > 0 then
                    loop
                        set i2 = i2 + 1
                        exitwhen i2 > itemsNeeded[i]
                        if PlayerHasItemType(pid, itemType[i]) then
                            call GetItemFromPlayer(pid, itemType[i]).useInRecipe()
                        endif
                    endloop
                endif
                set i = i + 1
            endloop

            if FINAL_ID != 0 then
                set FINAL_ITEM = PlayerAddItemById(pid, FINAL_ID)
                set FINAL_ITEM.charge = FINAL_CHARGES
                
                call AddCurrency(pid, GOLD, -goldcost)
                call AddCurrency(pid, LUMBER, -lumbercost)
                call AddCurrency(pid, PLATINUM, -R2I(platCost))
                call AddCurrency(pid, ARCADITE, -R2I(arcCost))
                call AddCurrency(pid, CRYSTAL, -crystals)
            endif
        endif
    endif
    
    set owner = null
    set itm = null

    return success
endfunction

function AllocatePrestige takes integer pid, integer rank, integer id returns nothing
    local integer i = PrestigeTable[pid][id]

    set PrestigeTable[pid][id] = IMinBJ(2, rank + i)
    set PrestigeTable[pid][0] = PrestigeTable[pid][0] + IMinBJ(2, rank + i)
endfunction

//! textmacro PRESTIGE_BACKPACKS takes num1, num2, num3
    if B2I(PrestigeTable[pid][$num1$] > 0) + B2I(PrestigeTable[pid][$num2$] > 0) + B2I(PrestigeTable[pid][$num3$] > 0) > 0 then
        set CosmeticTable[name][i] = 1
    endif
    set i = i + 1
    if B2I(PrestigeTable[pid][$num1$] > 0) + B2I(PrestigeTable[pid][$num2$] > 0) + B2I(PrestigeTable[pid][$num3$] > 0) > 1 then
        set CosmeticTable[name][i] = 1
    endif
    set i = i + 1
//! endtextmacro

function SetPrestigeEffects takes integer pid returns nothing
    local integer name = StringHash(User[Player(pid - 1)].name)
    local integer i = PUBLIC_SKINS + 2
    local integer j = 1
    local integer count = 0

	set Dmg_mod[pid] = 8 * (PrestigeTable[pid][3] + PrestigeTable[pid][5] + PrestigeTable[pid][12])
	set DR_mod[pid]  = 1.0 - (PrestigeTable[pid][11] * 0.05 + PrestigeTable[pid][16] * 0.05)
	set Str_mod[pid] = 6 * (PrestigeTable[pid][9] + PrestigeTable[pid][15] + PrestigeTable[pid][18])
	set Agi_mod[pid] = 7 * (PrestigeTable[pid][2] + PrestigeTable[pid][8] + PrestigeTable[pid][21])
	set Int_mod[pid] = 7 * (PrestigeTable[pid][4] + PrestigeTable[pid][13] + PrestigeTable[pid][14])
	set Spl_mod[pid] = 4 * (PrestigeTable[pid][1] + PrestigeTable[pid][6] + PrestigeTable[pid][17])
	set Reg_mod[pid] = 8 * (PrestigeTable[pid][7] + PrestigeTable[pid][10])
	set Gld_mod[pid] = 2 * (PrestigeTable[pid][0])

    //unlock backpack skins
    //dmg
    //! runtextmacro PRESTIGE_BACKPACKS("3", "5", "12")
    //str
    //! runtextmacro PRESTIGE_BACKPACKS("9", "15", "18")
    //agi
    //! runtextmacro PRESTIGE_BACKPACKS("2", "8", "21")
    //int
    //! runtextmacro PRESTIGE_BACKPACKS("4", "13", "14")
    //dmg red
    //! runtextmacro PRESTIGE_BACKPACKS("11", "16", "-1")
    //spellboost
    //! runtextmacro PRESTIGE_BACKPACKS("1", "6", "17")
    if B2I(PrestigeTable[pid][1] > 0) + B2I(PrestigeTable[pid][6] > 0) + B2I(PrestigeTable[pid][17] > 0) > 2 then
        set CosmeticTable[name][i] = 1
    endif
    set i = i + 1
    //regen
    //! runtextmacro PRESTIGE_BACKPACKS("7", "10", "-1")
    //prestige
    loop
        exitwhen j > HERO_TOTAL + 10

        if PrestigeTable[pid][j] > 0 then
            set count = count + 1
        endif

        set j = j + 1
    endloop
    if count >= 10 then
        set CosmeticTable[name][i] = 1
    endif
    set i = i + 1
    if count >= HERO_TOTAL then
        set CosmeticTable[name][i] = 1
    endif
endfunction

function UpdateItemTooltips takes integer pid returns nothing
    local string s = ""
    local string s2 = ""
    local Item itm

    //heart of the demon prince
    if HasItemType(Hero[pid], 'I04Q') then
        set itm = Item[GetItemFromUnit(Hero[pid], 'I04Q')]
        
        if HeartBlood[pid] >= 2000 then
            set s = "|c0000ff40"
        endif

        set s2 = "
|cffff5050Chaotic Quest|r
|c00ff0000Level Requirement: |r190
|cff0099ffBlood Accumulated:|r (" + s + I2S(IMinBJ(2000, HeartBlood[pid])) + "/2000|r)

|cff808080Deal or take damage to fill the heart with blood (Level 170+ enemies).
|cffff0000WARNING! This item does not save!"

        set itm.tooltip = s2
        set itm.alt_tooltip = s2

        call BlzSetItemDescription(itm.obj, itm.tooltip)
        call BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
    endif
endfunction

function UpdatePrestigeTooltips takes nothing returns nothing
    local string array s
    local integer i
    local integer unlocked
    local User u = User.first
    local integer i2 = PUBLIC_SKINS + 2
    
    //prestige skins
    
    loop
        exitwhen u == User.NULL
        set i = GetPlayerId(u.toPlayer()) + 1
        set unlocked = 0

        loop
            exitwhen i2 > TOTAL_SKINS
            if CosmeticTable[StringHash(u.name)][i2] > 0 then
                set unlocked = unlocked + 1
            endif
            set i2 = i2 + 1
        endloop

        if unlocked >= 17 then
            set s[i] = "Change your backpack's appearance.\n\nUnlocked skins: |c0000ff4017/17"
        else
            set s[i] = "Change your backpack's appearance.\n\nUnlocked skins: " + I2S(unlocked) + "/17"
        endif
        set u = u.next
    endloop
    
    call BlzSetAbilityExtendedTooltip('A0KX', s[GetPlayerId(GetLocalPlayer()) + 1], 0)
endfunction

function ActivatePrestige takes player p returns nothing
	local integer i = 0
	local integer counter = 0
	local integer pid = GetPlayerId(p) + 1
	local integer currentSlot = Profile[pid].currentSlot
    local item array itm
    
    if Profile[pid].hero.prestige > 0 then
        call DisplayTimedTextToPlayer(p,0,0, 20.00, "You can not prestige this character again.")
    else
        call Item[GetItemFromUnit(Hero[pid], 'I0NN')].destroy()
		set Profile[pid].hero.prestige = 1 + Profile[pid].hero.hardcore
		call Profile[pid].saveCharacter()

		call AllocatePrestige(pid, Profile[pid].hero.prestige, Profile[pid].hero.id)

		call DisplayTimedTextToForce(FORCE_PLAYING, 30.00, User.fromIndex(pid - 1).nameColored + " has prestiged their hero and achieved rank |cffffcc00" + I2S(PrestigeTable[pid][0]) + "|r prestige!")
		call DisplayTimedTextToPlayer(p,0,0, 20.00, "|cffffcc00Hero Prestige:|r " + I2S(Profile[pid].hero.prestige))
		call UpdatePrestigeTooltips()

		loop
			exitwhen i > 5
            call Item[UnitItemInSlot(Hero[pid], i)].unequip()

			set i = i + 1
		endloop

        call SetPrestigeEffects(pid)

		set i = 0
		loop
			exitwhen i > 5
            call Item[UnitItemInSlot(Hero[pid], i)].equip()

			set i = i + 1
		endloop
	endif
endfunction

function SwitchAggro takes nothing returns nothing
    local integer id = ReleaseTimer(GetExpiredTimer())
    local unit u = GetUnitById(id)
    local unit target = GetUnitTarget(u)

    call FlushChildHashtable(ThreatHash, id)
    call IssueTargetOrder(u, "smart", target)
    call SaveInteger(ThreatHash, id, THREAT_TARGET_INDEX, GetUnitId(target))

    set u = null
    set target = null
endfunction

function Taunt takes unit hero, integer pid, real aoe, boolean bossaggro, integer allythreat, integer herothreat returns nothing
    local group enemyGroup = CreateGroup()
    local group allyGroup = CreateGroup()
    local player p = GetOwningPlayer(hero)
    local unit target
    local unit target2
    local integer count = 0
    local integer index = 0
    local integer count2 = 0
    local integer index2 = 0
    local integer i = 0

    call MakeGroupInRange(pid, enemyGroup, GetUnitX(hero), GetUnitY(hero), aoe, Condition(function FilterEnemy))
    call MakeGroupInRange(pid, allyGroup, GetUnitX(hero), GetUnitY(hero), aoe, Condition(function FilterAlly))

    set count = BlzGroupGetSize(enemyGroup)
    set count2 = BlzGroupGetSize(allyGroup)

    if count > 0 then
        loop
            set target = BlzGroupUnitAt(enemyGroup, index)
            set i = LoadInteger(ThreatHash, GetUnitId(target), GetUnitId(hero))
            call SaveInteger(ThreatHash, GetUnitId(target), GetUnitId(hero), IMaxBJ(0, i + herothreat))
            if IsBoss(GetUnitId(target)) != -1 then
                if bossaggro then
                    call IssueTargetOrder(target, "smart", hero)
                    call SaveInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX, GetUnitId(hero))
                endif
                if i >= THREAT_CAP then
                    if GetUnitById(LoadInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX)) == hero then
                        call FlushChildHashtable(ThreatHash, GetUnitId(target))
                    else //switch target
                        set bj_lastCreatedUnit = GetDummy(GetUnitX(target), GetUnitY(target), 0, 0, 1.5)
                        call BlzSetUnitSkin(bj_lastCreatedUnit, 'h00N')
                        if GetLocalPlayer() == p then
                            call BlzSetUnitSkin(bj_lastCreatedUnit, 'h01O')
                        endif
                        call SetUnitScale(bj_lastCreatedUnit, 2.5, 2.5, 2.5)
                        call SetUnitFlyHeight(bj_lastCreatedUnit, 250.00, 0.)
                        call SetUnitAnimation(bj_lastCreatedUnit, "birth")
                        call TimerStart(NewTimerEx(GetUnitId(target)), 1.5, false, function SwitchAggro)
                    endif
                    call SaveInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX, GetUnitId(hero))
                else //lower everyone else's threat 
                    loop
                        set target2 = BlzGroupUnitAt(allyGroup, index2)
                        if target2 != hero then
                            call SaveInteger(ThreatHash, GetUnitId(target), GetUnitId(target2), IMaxBJ(0, LoadInteger(ThreatHash, GetUnitId(target), GetUnitId(target2)) - allythreat))
                        endif
                        set index2 = index2 + 1
                        exitwhen index2 >= count2
                    endloop
                endif
            //so that cast aggro doesnt taunt normal enemies
            elseif allythreat > 0 then
                call IssueTargetOrder(target, "smart", hero)
                call SaveInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX, GetUnitId(hero))
            endif

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

private function ProximityFilter takes nothing returns boolean
    return (GetUnitTypeId(GetFilterUnit()) != DUMMY and GetUnitAbilityLevel(GetFilterUnit(), 'Avul') == 0 and GetPlayerId(GetOwningPlayer(GetFilterUnit())) < PLAYER_CAP)
endfunction

function AcquireProximity takes unit source, unit target, real dist returns unit
    local integer index = 0
    local integer count = 0
    local group ug = CreateGroup()
    local real x = GetUnitX(source)
    local real y = GetUnitY(source)
    local integer i = 0
    local unit orig = target

    call GroupEnumUnitsInRange(ug, x, y, dist, Filter(function ProximityFilter))
    set count = BlzGroupGetSize(ug)
    if count > 0 then
        loop
            set target = BlzGroupUnitAt(ug, index)
            //dont acquire the same target
            if SquareRoot(Pow(x - GetUnitX(target), 2) + Pow(y - GetUnitY(target), 2)) < dist and LoadInteger(ThreatHash, GetUnitId(source), THREAT_TARGET_INDEX) != GetUnitId(orig) then
                set dist = SquareRoot(Pow(x - GetUnitX(target), 2) + Pow(y - GetUnitY(target), 2)) 
                set i = index
            endif
            set index = index + 1
            exitwhen index >= count
        endloop
        set target = BlzGroupUnitAt(ug, i)
        call DestroyGroup(ug)

        set ug = null
        set orig = null
        return target
    endif

    call DestroyGroup(ug)

    set ug = null
    set orig = null
    return target
endfunction

function RunDropAggro takes nothing returns nothing
    local integer pid = GetTimerData(GetExpiredTimer())
    local PlayerTimer pt = TimerList[pid].getTimerFromHandle(GetExpiredTimer())
    local unit target
    local unit target2
    local group ug = CreateGroup()

    call MakeGroupInRange(pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 800., Condition(function FilterEnemy))

    loop
        set target = FirstOfGroup(ug)
        exitwhen target == null
        call GroupRemoveUnit(ug, target)
        if GetUnitTarget(target) == pt.target then
            set target2 = AcquireProximity(target, pt.target, 800.)
            call IssueTargetOrder(target, "smart", target2)
            call SaveInteger(ThreatHash, GetUnitId(target), THREAT_TARGET_INDEX, GetUnitId(target2))
            //call DEBUGMSG("aggro to " + GetUnitName(target2))
        endif
    endloop

    call TimerList[pid].removePlayerTimer(pt)

    call DestroyGroup(ug)

    set ug = null
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

function RevivePlayer takes integer pid, real x, real y, real percenthp, real percentmana returns nothing
    local player p = Player(pid - 1)

    call ReviveHero(Hero[pid], x, y, true)
    call SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * percenthp)
    call SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA) * percentmana)
    call PanCameraToTimedForPlayer(p, x, y, 0)
    set udg_DashDistance[pid] = 0
    call SetUnitFlyHeight(Hero[pid], 0, 0)
    call reselect(Hero[pid])
    call SetUnitTimeScale(Hero[pid], 1.)
    call SetUnitPropWindow(Hero[pid], bj_DEGTORAD * 60.)
    call SetUnitPathing(Hero[pid], true)
    call RemoveLocation(FlightTarget[pid])

    if MultiShot[pid] then
        call IssueImmediateOrder(Hero[pid], "immolation")
    endif
    
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

function Roundmana takes real manac returns integer
	if manac > 99999 then
		return 1000 * R2I(manac / 1000)
	endif
	return R2I(manac)
endfunction

function BackpackLimit takes unit u returns nothing
    call BlzUnitDisableAbility(u, 'A083', true, true)
    call BlzUnitDisableAbility(u, 'A02A', true, true)
    call BlzUnitDisableAbility(u, 'A0IS', true, true)
    call BlzUnitDisableAbility(u, 'A0SO', true, true)
    call BlzUnitDisableAbility(u, 'A0SX', true, true)
    call BlzUnitDisableAbility(u, 'A00E', true, true)
    call BlzUnitDisableAbility(u, 'A00I', true, true)
    call BlzUnitDisableAbility(u, 'A00O', true, true)
    call BlzUnitDisableAbility(u, 'A0CP', true, true)
    call BlzUnitDisableAbility(u, 'A0CQ', true, true)
    call BlzUnitDisableAbility(u, 'AIfw', true, true)
    call BlzUnitDisableAbility(u, 'AIft', true, true)
    call BlzUnitDisableAbility(u, 'A0CD', true, true)
    call BlzUnitDisableAbility(u, 'A0CC', true, true)
    call BlzUnitDisableAbility(u, 'AIpv', true, true)
    call BlzUnitDisableAbility(u, 'AIv2', true, true)
    call BlzUnitDisableAbility(u, 'A055', true, true)
    call BlzUnitDisableAbility(u, 'A01S', true, true)
    call BlzUnitDisableAbility(u, 'A03D', true, true)
    call BlzUnitDisableAbility(u, 'A0B5', true, true)
    call BlzUnitDisableAbility(u, 'A07G', true, true)
    call UnitRemoveAbility(u, 'A0CP') //immolations and orb effects
    call UnitRemoveAbility(u, 'A0UP')
    call UnitRemoveAbility(u, 'A00D')
    call UnitRemoveAbility(u, 'A00V')
    call UnitRemoveAbility(u, 'A01O')
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
endfunction

function UpdateManaCosts takes unit u returns nothing
    local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local integer uid = GetUnitTypeId(u)
    local integer maxmana = BlzGetUnitMaxMana(u) 

	if uid == BACKPACK then
	elseif uid == HERO_ASSASSIN then
		call BlzSetUnitAbilityManaCost(u, 'A0AS', GetUnitAbilityLevel(u, 'A0AS') - 1, Roundmana(maxmana * .075)) //blade spin
		call BlzSetUnitAbilityManaCost(u, 'A0BG', GetUnitAbilityLevel(u, 'A0BG') - 1, Roundmana(maxmana * .05)) //shadow shuriken
		call BlzSetUnitAbilityManaCost(u, 'A00T', GetUnitAbilityLevel(u, 'A00T') - 1, Roundmana(maxmana * .15)) //blink strike
		call BlzSetUnitAbilityManaCost(u, 'A01E', GetUnitAbilityLevel(u, 'A01E') - 1, Roundmana(maxmana * .20)) //smoke bomb
		call BlzSetUnitAbilityManaCost(u, 'A00P', GetUnitAbilityLevel(u, 'A00P') - 1, Roundmana(maxmana * .25)) //dagger storm
        call BlzSetUnitAbilityManaCost(u, 'A07Y', GetUnitAbilityLevel(u, 'A07Y') - 1, Roundmana(maxmana * (.1 - 0.025 * GetUnitAbilityLevel(u, 'A07Y')))) //phantom slash
	elseif uid == HERO_BARD then
        set BardMelodyCost[pid] = Roundmana(GetUnitState(u, UNIT_STATE_MANA) * .1)
		call BlzSetUnitAbilityManaCost(u, 'A02H', GetUnitAbilityLevel(u, 'A02H') - 1, R2I(BardMelodyCost[pid]))
		call BlzSetUnitAbilityManaCost(u, 'A09Y', GetUnitAbilityLevel(u, 'A09Y') - 1, Roundmana(maxmana * .02)) //inspire
		call BlzSetUnitAbilityManaCost(u, 'A02K', GetUnitAbilityLevel(u, 'A02K') - 1, Roundmana(maxmana * .2)) //tone of death
	elseif uid == HERO_DARK_SAVIOR or uid == HERO_DARK_SAVIOR_DEMON then
		call BlzSetUnitAbilityManaCost(u, 'A019', GetUnitAbilityLevel(u, 'A019') - 1, Roundmana(maxmana * .1))
		call BlzSetUnitAbilityManaCost(u, 'A074', GetUnitAbilityLevel(u, 'A074') - 1, Roundmana(maxmana * .1))
	elseif uid == HERO_ELEMENTALIST then
		call BlzSetUnitAbilityManaCost(u, 'A0GV', GetUnitAbilityLevel(u, 'A0GV') - 1, Roundmana(maxmana * .05))
		call BlzSetUnitAbilityManaCost(u, 'A011', GetUnitAbilityLevel(u, 'A011') - 1, Roundmana(maxmana * .15))
		call BlzSetUnitAbilityManaCost(u, 'A01U', GetUnitAbilityLevel(u, 'A01U') - 1, Roundmana(maxmana * .05))
		call BlzSetUnitAbilityManaCost(u, 'A04H', GetUnitAbilityLevel(u, 'A04H') - 1, Roundmana(maxmana * .25))
	elseif uid == HERO_HIGH_PRIEST then
		call BlzSetUnitAbilityManaCost(u, 'A0JD', GetUnitAbilityLevel(u, 'A0JD') - 1, Roundmana(maxmana * .1))
		call BlzSetUnitAbilityManaCost(u, 'A0JE', GetUnitAbilityLevel(u, 'A0JE') - 1, Roundmana(maxmana * .05))
		call BlzSetUnitAbilityManaCost(u, 'A0JG', GetUnitAbilityLevel(u, 'A0JG') - 1, Roundmana(maxmana * .1))
		call BlzSetUnitAbilityManaCost(u, 'A0J3', GetUnitAbilityLevel(u, 'A0J3') - 1, Roundmana(maxmana * .5))
		call BlzSetUnitAbilityManaCost(u, 'A048', GetUnitAbilityLevel(u, 'A048') - 1, Roundmana(GetUnitState(u, UNIT_STATE_MANA)))
    elseif uid == HERO_PHOENIX_RANGER then
        //
    elseif uid == HERO_THUNDERBLADE then
        call BlzSetUnitAbilityManaCost(u, OVERLOAD.id, GetUnitAbilityLevel(u, OVERLOAD.id) - 1, Roundmana(maxmana * .02))
	endif
endfunction

function RewardDialog takes integer pid, integer id returns nothing
    local integer i = 0
    local integer prof = 0
    local integer index = 0
    local boolean display = false

	call DialogClear(dChooseReward[pid])
	call DialogSetMessage(dChooseReward[pid], "Choose an item.")

    set udg_SlotIndex[pid] = id

	loop
        set index = ItemRewards[id][i]
        call Item.create(index, 30000., 30000., 0.01) //load item data
		exitwhen index == 0 
        set prof = ItemData[index][ITEM_TYPE]

		if BlzBitAnd(PROF[prof], HERO_PROF[pid]) != 0 then
            set display = true
            set slotitem[1000 + pid * 10 + i] = DialogAddButton(dChooseReward[pid], GetObjectName(index), 48 + i)
		endif

		set i = i + 1
	endloop

    if display then
        call DialogDisplay(Player(pid - 1), dChooseReward[pid], true)
    endif
endfunction

//initialize some globals
private struct init
    private static method onInit takes nothing returns nothing
        local integer i = 0

        //main selection setup
        set containerFrame = BlzFrameGetChild(BlzFrameGetChild(BlzFrameGetChild(BlzGetFrameByName("ConsoleUI", 0), 1), 5), 0)
        set MAIN_SELECT_GROUP = CreateGroup()
        set filter = Filter(function FilterFunction)

        // give these frames a handleId
        loop 
            exitwhen i >= BlzFrameGetChildrenCount(containerFrame) - 1
            set frames[i] = BlzFrameGetChild(BlzFrameGetChild(containerFrame, i), 0)
            set i = i + 1
        endloop
    endmethod
endstruct

endlibrary
