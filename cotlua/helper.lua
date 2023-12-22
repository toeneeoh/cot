if Debug then Debug.beginFile "Helper" end

OnInit.global("Helper", function(require)
    require 'Variables'

    ---@class CircularArrayList
    ---@field add function
    ---@field addUp function
    ---@field calcPeakDps function
    ---@field wipe function
    ---@field count integer
    ---@field START integer
    ---@field END integer
    ---@field MAXSIZE integer
    ---@field create function
    CircularArrayList = {}
    do
        local thistype = CircularArrayList
        thistype.VALUES = __jarray(0) ---@type number[] 
        thistype.count         = 0 ---@type integer 
        thistype.START         = 0 ---@type integer 
        thistype.END         = 0 ---@type integer 
        thistype.MAXSIZE = 200 ---@type integer

        ---@param value number
        function thistype:add(value)
            self.VALUES[self.END] = value
            self.END = ModuloInteger((self.END + 1), self.MAXSIZE)

            if self.count < self.MAXSIZE then
                self.count = self.count + 1
            else
                -- Free up the last 10 slots
                self.START = ModuloInteger((self.START + 10), self.MAXSIZE)
                self.count = self.count - 10
            end
        end

        ---@param start integer
        ---@param end_ integer
        ---@return number
        function thistype:addUp(start, end_)
            local dps = 0. ---@type number 
            local j = start ---@type integer 

            while j ~= end_ do
                dps = dps + self.VALUES[j]

                j = ModuloInteger((j + 1),self.MAXSIZE)
            end

            return dps
        end

        ---@param interval integer
        ---@return number
        function thistype:calcPeakDps(interval)
            local i = self.START ---@type integer 
            local dps2 = 0. ---@type number 
            local output = 0. ---@type number 

            if self.count > interval then
                --first iteration
                local dps1 = self:addUp(i, ModuloInteger((i + 10),self.MAXSIZE))

                while i ~= self.END do
                        dps2 = dps1
                        dps1 = self:addUp(ModuloInteger((i + 1),self.MAXSIZE), ModuloInteger((i + 11), self.MAXSIZE))

                        output = math.max(output, dps1 - dps2)
                    i = ModuloInteger((i + 1),self.MAXSIZE)
                end
            end

            return output
        end

        function thistype:wipe()
            self.count = 0
            self.START = 0
            self.END = 0

            for i = 0, self.MAXSIZE - 1 do
                self.VALUES[i] = 0.
            end
        end

        ---@type fun():CircularArrayList
        function thistype.create()
            local self = {}

            setmetatable(self, { __index = CircularArrayList })

            return self
        end
    end

---@param val number
---@param min number
---@param max number
---@return number
function MathClamp(val, min, max)
    if val < min then
        return min
    elseif val > max then
        return max
    end

    return val
end

---@param b boolean
---@return integer
function B2I(b)
    if b then
        return 1
    end

    return 0
end

---@param s string
function DEBUGMSG(s)
    if LIBRARY_dev then
        if COUNT_DEBUG then
            DEBUG_COUNT = DEBUG_COUNT + 1
            DisplayTimedTextToForce(FORCE_PLAYING, 30., (DEBUG_COUNT))
        else
            DisplayTimedTextToForce(FORCE_PLAYING, 30., s)
        end
    end
end

---@param u unit
---@return integer
function GetUnitOrderValue(u)
    --heroes use the handleId
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHandleId(u)
    else
    --units use unitCode
        return GetUnitTypeId(u)
    end
end

---@type fun():boolean
function onPlayerLeave()
    local p           = GetTriggerPlayer() ---@class player
    local pid           = GetPlayerId(p) + 1 ---@type integer
    local mbitem                = nil ---@type multiboarditem 

    -- clean up
    DisplayTextToForce(FORCE_PLAYING, (User[p].nameColored .. " has left the game"))

    mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 0)
    MultiboardSetItemValue(mbitem, User[p].name)
    MultiboardSetItemValueColor(mbitem, 153, 153, 153, 255)
    mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 1)
    MultiboardSetItemValue(mbitem, "")
    MultiboardSetItemStyle(mbitem, false, false)
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 2)
    MultiboardSetItemValue(mbitem, "")
    MultiboardSetItemStyle(mbitem, false, false)
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 3)
    MultiboardSetItemValue(mbitem, "")
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 4)
    MultiboardSetItemValue(mbitem, "")
    MultiboardReleaseItem(mbitem)
    mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[pid], 5)
    MultiboardSetItemValue(mbitem, "")
    MultiboardReleaseItem(mbitem)

    PlayerCleanup(p)

    return false
end

---@return boolean
function FilterFunction()
    local u      = GetFilterUnit() ---@type unit 
    local prio      = BlzGetUnitRealField(u, UNIT_RF_PRIORITY) ---@type number 
    local found         = false ---@type boolean 
    local loopA         = 1 ---@type integer 
    local loopB         = 0 ---@type integer 

    while loopA <= unitsCount do
        if BlzGetUnitRealField(units[loopA], UNIT_RF_PRIORITY) < prio then
            unitsCount = unitsCount + 1
            loopB = unitsCount
            while loopB > loopA do
                units[loopB] = units[loopB - 1]
                loopB = loopB - 1
            end
            units[loopA] = u
            found = true
            break
        --equal prio and better colisions value
        elseif BlzGetUnitRealField(units[loopA], UNIT_RF_PRIORITY) == prio and GetUnitOrderValue(units[loopA]) > GetUnitOrderValue(u) then
            unitsCount = unitsCount + 1
            loopB = unitsCount
            while loopB > loopA do
                units[loopB] = units[loopB - 1]
                loopB = loopB - 1
            end
            units[loopA] = u
            found = true
            break
        end
        loopA = loopA + 1
    end

    -- not found add it at the end
    if not found then
        unitsCount = unitsCount + 1
        units[unitsCount] = u
    end

    return false
end

---@return integer
function GetSelectedUnitIndex()
    local i         = 0 ---@type integer 
    -- local player is in group selection?
    if BlzFrameIsVisible(containerFrame) then
        -- find the first visible yellow Background Frame
        while i <= 11 do
            if BlzFrameIsVisible(frames[i]) then
                return i
            end
            i = i + 1
        end
    end
    return -1
end

---@param index integer
---@return unit
function GetMainSelectedUnit(index)
    if index >= 0 then
        GroupEnumUnitsSelected(MAIN_SELECT_GROUP, GetLocalPlayer(), Filter(FilterFunction))
        bj_groupRandomCurrentPick = units[index + 1]
        --clear table
        while unitsCount > 0 do
            units[unitsCount] = nil
            unitsCount = unitsCount - 1
        end
        return bj_groupRandomCurrentPick
    else
        GroupEnumUnitsSelected(MAIN_SELECT_GROUP, GetLocalPlayer(), nil)
        return FirstOfGroup(MAIN_SELECT_GROUP)
    end
end

--async
---@return unit
function GetMainSelectedUnitEx()
    return GetMainSelectedUnit(GetSelectedUnitIndex())
end

do
    local    SIZE_MIN                = 0.0075          ---@type number -- Minimum size of text
    local    SIZE_BONUS              = 0.006          ---@type number -- Text size increase
    local    TIME_LIFE               = 0.9            ---@type number -- How long the text lasts
    local    TIME_FADE               = 0.7            ---@type number -- When does the text start to fade
    local    Z_OFFSET                = 100             ---@type number -- Height above unit
    local    Z_OFFSET_BON            = 75             ---@type number -- How much extra height the text gains
    local    VELOCITY                = 2.5              ---@type number -- How fast the text move in x/y plane
    local    MAX_PER_TICK            = 5 ---@type integer 
    local    TMR                     = CreateTimer() ---@type timer 
    local    count                   = 0 ---@type integer 
    local    instances               = {}

    ---@class ArcingTextTag
    ---@field create function
    ArcingTextTag = {}
    do
        local thistype = ArcingTextTag

        function thistype.update()
            local i = 1
            count = 0

            while i <= #instances do
                local self = instances[i]
                local p = Sin(bj_PI * (self.time / self.timeScale))
                self.time = self.time - FPS_32
                self.x = self.x + self.ac
                self.y = self.y + self.as
                SetTextTagPos(self.tt, self.x, self.y, Z_OFFSET + Z_OFFSET_BON * p)
                SetTextTagText(self.tt, self.text, (SIZE_MIN + SIZE_BONUS * p) * self.scale)

                if self.time <= 0 then
                    instances[i] = instances[#instances]
                    instances[#instances] = nil

                    if #instances == 0 then
                        PauseTimer(TMR)
                    end
                else
                    i = i + 1
                end
            end
        end

        ---@type fun(text: string, u: unit, duration: number, size: number, r: integer, g: integer, b: integer, alpha: integer):ArcingTextTag
        function thistype.create(text, u, duration, size, r, g, b, alpha)
            count = count + 1

            if count > MAX_PER_TICK then
                return 0
            end

            local pid = GetPlayerId(GetLocalPlayer()) + 1 ---@type integer 
            local a = GetRandomReal(0, 2 * bj_PI) ---@type number 
            local self = {} ---@class ArcingTextTag

            self.scale = size
            self.timeScale = math.max(duration, 0.001)

            self.text = text
            self.x = GetUnitX(u)
            self.y = GetUnitY(u)
            self.time = TIME_LIFE
            self.as = Sin(a) * VELOCITY
            self.ac = Cos(a) * VELOCITY

            if IsUnitVisible(u, GetLocalPlayer()) then
                if DMG_NUMBERS[pid] == 0 or (DMG_NUMBERS[pid] == 1 and not IsUnitAlly(u, GetLocalPlayer())) then
                    self.tt = CreateTextTag()
                    SetTextTagPermanent(self.tt, false)
                    SetTextTagColor(self.tt, r, g, b, 255 - alpha)
                    SetTextTagLifespan(self.tt, TIME_LIFE * duration)
                    SetTextTagFadepoint(self.tt, TIME_FADE * duration)
                    SetTextTagText(self.tt, text, SIZE_MIN * size)
                    SetTextTagPos(self.tt, self.x, self.y, Z_OFFSET)
                end
            else
                self.tt = nil
            end

            instances[#instances+1] = self

            if #instances == 1 then
                TimerStart(TMR, FPS_32, true, thistype.update)
            end

            return self
        end
    end
end

do
    ---@class shieldtimer
    ---@field shield shield
    ---@field prev shieldtimer
    ---@field next shieldtimer
    ---@field amount number
    ---@field create function
    ---@field destroy function
    shieldtimer = {}
    do
        local thistype = shieldtimer
        thistype.shield          = nil ---@class shield 
        thistype.prev             = nil ---@class shieldtimer 
        thistype.next             = nil ---@class shieldtimer 
        thistype.amount          = 0. ---@type number 

        ---@type fun(this: shieldtimer)
        local function expire(this)
            --linked list handling
            if this.prev and this.next then
                this.prev.next = this.next
                this.next.prev = this.prev
            elseif this.prev then
                this.prev.next = nil
            elseif this.next then --current is head
                this.next.prev = nil
                this.shield.timer = this.next
            end

            this.shield.max = this.shield.max - this.amount
            this.shield.hp = this.shield.hp - this.amount

            if this.shield.hp <= 0 then
                this.shield:destroy()
            else
                this.shield:refresh()
            end

            this:destroy()
        end

        ---@type fun(s: shield, amount: number, dur: number)
        function thistype.add(s, amount, dur)
            local self = s ---@class shieldtimer 

            while self.next do
                self = self.next
            end

            self.next = thistype.create(s, amount, dur)

            self.next.prev = st
        end

        function thistype:destroy()
            self = nil
        end

        ---@type fun(s: shield, amount: number, dur: number):shieldtimer
        function thistype.create(s, amount, dur)
            local self = {} ---@class shieldtimer

            self.shield = s
            self.amount = amount

            TimerQueue:callDelayed(dur, expire, self)

            return self
        end
    end

    ---@class shield
    ---@field refresh function
    ---@field sfx effect
    ---@field next shield
    ---@field prev shield
    ---@field head shield
    ---@field tail shield
    ---@field target unit
    ---@field add function
    ---@field create function
    ---@field destroy function
    ---@field color function
    ---@field c integer
    shield = {}
    do
        local thistype = shield
        thistype.sfx                = nil ---@type effect 
        thistype.target            = nil ---@type unit 
        thistype.max                = 0. ---@type number 
        thistype.hp                 = 0. ---@type number 
        thistype.c                  = 2 ---@type integer 
        thistype.timer              = 0 ---@class shieldtimer 
        thistype.next              = nil ---@class shield 
        thistype.prev              = nil ---@class shield 

        thistype.head           = nil ---@type shield 
        thistype.tail           = nil ---@type shield 
        thistype.count          = 0 ---@type integer 
        thistype.t              = nil ---@type TimerQueue 
        thistype.shieldheight = {  ---@type number[] 
            HERO_ELEMENTALIST = 200,
            HERO_MARKSMAN = 220,
            HERO_MARKSMAN_SNIPER = 220,
            HERO_ROYAL_GUARDIAN = 230,
            HERO_MASTER_ROGUE = 230,
            HERO_ASSASSIN = 230,
            HERO_DARK_SUMMONER = 230,
            HERO_THUNDERBLADE = 240,
            HERO_HIGH_PRIEST = 240,
            HERO_VAMPIRE = 240,
            HERO_OBLIVION_GUARD = 275
        }

        --shieldheight default value
        setmetatable(thistype.shieldheight, {__index = function() return 250 end})

        function thistype:color(c)
            self.c = c
            BlzSetSpecialEffectColorByPlayer(self.sfx, Player(c))
        end

        function thistype:refresh()
            BlzSetSpecialEffectTime(self.sfx, self.hp / self.max)
        end

        ---@param dmg number
        ---@param source unit
        ---@return number
        function thistype:damage(dmg, source)
            local angle      = Atan2(GetUnitY(source) - GetUnitY(target), GetUnitX(source) - GetUnitX(target)) ---@type number 
            local x      = GetUnitX(target) + 80. * Cos(angle) ---@type number 
            local y      = GetUnitY(target) + 80. * Sin(angle) ---@type number 
            local e        = AddSpecialEffect("war3mapImported\\BoneArmorCasterTC.mdx", x, y) ---@type effect 

            BlzSetSpecialEffectZ(e, BlzGetUnitZ(target) + 90.)
            BlzSetSpecialEffectColorByPlayer(e, Player(self.c))
            BlzSetSpecialEffectYaw(e, angle)
            BlzSetSpecialEffectScale(e, 0.85)
            BlzSetSpecialEffectTimeScale(e, 3.5)

            DestroyEffect(e)

            self.hp = self.hp - dmg

            if self.hp <= 0. then
                self:destroy()
                return -self.hp
            else
                self:refresh()
                return 0.00
            end
        end

        local function update()
            local curr = thistype.head ---@class shield
            local prev = nil ---@class shield 
            local u = GetMainSelectedUnitEx() ---@type unit 

            if thistype[u] then
                BlzFrameSetVisible(shieldBackdrop, true)

                if thistype[u].max >= 100000 then
                    BlzFrameSetText(shieldText, "|cff22ddff" .. R2I(thistype[u].hp))
                else
                    BlzFrameSetText(shieldText, "|cff22ddff" .. R2I(thistype[u].hp) .. " / " .. R2I(thistype[u].max))
                end
            else
                BlzFrameSetVisible(shieldBackdrop, false)
            end

            while curr do
                prev = curr
                curr = curr.next

                --move shield visual
                if UnitAlive(prev.target) then
                    BlzSetSpecialEffectX(prev.sfx, GetUnitX(prev.target))
                    BlzSetSpecialEffectY(prev.sfx, GetUnitY(prev.target))
                    BlzSetSpecialEffectZ(prev.sfx, BlzGetUnitZ(prev.target) + thistype.shieldheight[GetUnitTypeId(prev.target)])
                else
                --otherwise destroy
                    prev:destroy()
                end
            end
        end

        ---@type fun(u: unit, amount: number, dur: number):shield
        function thistype.add(u, amount, dur)
            local self = shield[u] ---@class shield

            --shield already exists
            if self then
                self.max = self.max + amount
                self.hp = self.hp + amount
                self.timer.add(self, amount, dur)

                self:refresh()
            else
            --make a new one
                self = thistype.create(u, amount)
                self.timer = shieldtimer.create(self, amount, dur)
            end

            return self
        end

        --shield fully expires
        function thistype:onDestroy()
            local pid = GetPlayerId(GetOwningPlayer(self.target)) + 1 ---@type integer 
            local curr = self.timer ---@type shieldtimer 
            local prev = nil ---@type shieldtimer 

            TimerList[pid]:stopAllTimers(GAIAARMOR.id) --gaia armor attachment
            ProtectionBuff:get(nil, self.target):dispel() --high priestess protection attack speed

            BlzSetSpecialEffectAlpha(self.sfx, 0)
            DestroyEffect(self.sfx)

            --shield timer cleanup
            while curr do
                prev = curr
                curr = curr.next

                prev:destroy()
            end

            --linked list cleanup
            self.prev.next = self.next

            if self == thistype.head then
                thistype.head = self.next
            end

            if self == thistype.tail then
                thistype.tail = self.prev
            end

            thistype.count = thistype.count - 1

            if thistype.count == 0 then
                BlzFrameSetVisible(shieldBackdrop, false)
                self.t:destroy()
            end
        end

        function thistype:destroy()
            self:onDestroy()
            self = nil
        end

        ---@type fun(u: unit, amount: number):shield
        function thistype.create(u, amount)
            local self = {} ---@class shield

            setmetatable(self, { __index = thistype })

            --instance count
            thistype.count = thistype.count + 1

            --setup
            thistype[u] = self
            self.max = amount
            self.hp = amount
            self.target = u
            self.sfx = AddSpecialEffect("war3mapImported\\HPbar.mdx", GetUnitX(u), GetUnitY(u))
            self:color(self.c)
            BlzSetSpecialEffectTime(self.sfx, 1.)
            BlzSetSpecialEffectTimeScale(self.sfx, 0.)
            BlzSetSpecialEffectScale(self.sfx, 1.6)

            --ll setup
            if thistype.t == nil then
                thistype.head = self
                thistype.t = TimerQueue.create()
                thistype.t:callPeriodically(FPS_32, nil, update)
            else
                thistype.tail.next = self
                self.prev = thistype.tail
            end

            thistype.tail = self

            return self
        end
    end
end

---@class DialogWindow
---@field getClickedIndex function
---@field pid integer
---@field data any[]
---@field MenuButton button[]
---@field MenuButtonName string[]
---@field ButtonCount integer
---@field MenuButtonCount integer
---@field Page integer
---@field display function
---@field addButton function
---@field addMenuButton function
---@field create function
---@field destroy function
DialogWindow = {}
do
    local thistype = DialogWindow
    thistype.OPTIONS_PER_PAGE         = 7 ---@type integer 
    thistype.BUTTON_MAX         = 100 ---@type integer 
    thistype.MENU_BUTTON_MAX         = 5 ---@type integer 
    thistype.DATA_MAX         = 100 ---@type integer 

    thistype.dialog        = nil ---@type dialog 
    thistype.pid         = 0 ---@type integer 
    thistype.title        = "" ---@type string 
    thistype.Button={} ---@type button[] [thistype.BUTTON_MAX]
    thistype.ButtonName=__jarray("") ---@type string[] [thistype.BUTTON_MAX]
    thistype.MenuButton={} ---@type button[] [thistype.MENU_BUTTON_MAX]
    thistype.MenuButtonName=__jarray("") ---@type string[] [thistype.MENU_BUTTON_MAX]
    thistype.ButtonCount         = 0  ---@type integer 
    thistype.MenuButtonCount         = 2  ---@type integer 
    thistype.Page         = -1 ---@type integer 
    thistype.trig         = nil ---@type trigger 

    thistype.cancellable         = true ---@type boolean 
    thistype.data = {} ---@type any[] [thistype.DATA_MAX]

    ---@return boolean
    function thistype.dialogHandler()
        local self = thistype[GetPlayerId(GetTriggerPlayer()) + 1] ---@class DialogWindow

        if self then
            --cancel
            if GetClickedButton() == self.MenuButton[0] then
                self:destroy()
            --next page
            elseif GetClickedButton() == self.MenuButton[1] then
                self:display()
            end
        end

        return false
    end

    ---@param b button
    ---@return integer
    function thistype:getClickedIndex(b)
        for index = 0, self.ButtonCount do
            if b == self.Button[index] then
                return index
            end
        end

        return -1
    end

    function thistype:display()
        local index = self.Page * self.OPTIONS_PER_PAGE + self.OPTIONS_PER_PAGE ---@type integer 
        local shown = 0 ---@type integer 

        DialogClear(self.dialog)

        --buttons
        if index > self.ButtonCount then
            index = 0
            self.Page = -1
        end

        while not (shown >= self.OPTIONS_PER_PAGE or index >= self.ButtonCount) do

            self.Button[index] = DialogAddButton(self.dialog, self.ButtonName[index], 0)

            index = index + 1
            shown = shown + 1
        end

        --menu buttons
        index = 2
        while index < self.MenuButtonCount do

            self.MenuButton[index] = DialogAddButton(self.dialog, self.MenuButtonName[index], 0)

            index = index + 1
        end

        --reserve first two menu buttons for next page / cancel
        if self.ButtonCount > self.OPTIONS_PER_PAGE then
            self.MenuButton[1] = DialogAddButton(self.dialog, "Next Page", 0)
            self.Page = self.Page + 1
        end

        if self.cancellable then
            self.MenuButton[0] = DialogAddButton(self.dialog, "Cancel", 0)
        end

        DialogSetMessage(self.dialog, self.title)
        DialogDisplay(Player(self.pid - 1), self.dialog, GetLocalPlayer() == Player(self.pid - 1))
    end

    ---@param s string
    function thistype:addButton(s)
        self.ButtonName[self.ButtonCount] = s
        self.ButtonCount = self.ButtonCount + 1
    end

    ---@param s string
    function thistype:addMenuButton(s)
        self.MenuButtonName[self.MenuButtonCount] = s
        self.MenuButtonCount = self.MenuButtonCount + 1
    end

    function thistype:destroy()
        DialogDisplay(Player(self.pid - 1), self.dialog, false)
        DialogDestroy(self.dialog)
        DestroyTrigger(self.trig)

        thistype[self.pid] = nil
    end

    ---@type fun(pid: integer, s: string, c: function):DialogWindow
    function thistype.create(pid, s, c)
        --safety
        if thistype[pid] then
            return nil
        end

        local self = {} ---@type DialogWindow
        self.dialog = DialogCreate()
        self.title = s
        self.pid = pid
        self.trig = CreateTrigger()

        setmetatable(self, { __index = thistype })

        DialogSetMessage(self.dialog, self.title)
        TriggerRegisterDialogEvent(self.trig, self.dialog)
        TriggerAddCondition(self.trig, Filter(c))
        TriggerAddCondition(self.trig, Filter(thistype.dialogHandler))

        thistype[pid] = self

        return self
    end
end

---@param u unit
---@return boolean
function IsUnitStunned(u)
    return (Stun:has(nil, u) or Freeze:has(nil, u) or KnockUp:has(nil, u) or GetUnitAbilityLevel(u, FourCC('BPSE')) > 0 or GetUnitAbilityLevel(u, FourCC('BSTN')) > 0 or isteleporting[GetPlayerId(GetOwningPlayer(u)) + 1])
end

---@param u unit
---@param id integer
---@param disable boolean
function UnitDisableAbility(u, id, disable)
    local ablev         = GetUnitAbilityLevel(u, id) ---@type integer 

    if ablev == 0 then
        return
    end

    UnitRemoveAbility(u, id)
    UnitAddAbility(u, id)
    SetUnitAbilityLevel(u, id, ablev)
    BlzUnitDisableAbility(u, id, disable, false)
    BlzUnitHideAbility(u, id, true)
end

---@param i integer
---@return string
function Id2Char(i)
    if i >= 97 then
        return SubString(abc, i - 97 + 36, i - 96 + 36)
    elseif i >= 65 then
        return SubString(abc, i - 65 + 10, i - 64 + 10)
    end
    return SubString(abc,i - 48,i - 47)
end

---@param id1 integer
---@return string
function Id2String(id1)
    local t         = id1 // 256 ---@type integer 
    local r        = Id2Char(id1 - 256 * t) ---@type string 

    id1 = t / 256
    r = Id2Char(t - 256 * id1) + r
    t = id1 // 256

    return Id2Char(t) + Id2Char(id1 - 256 * t) + r
end

function HandleCount()
    local L          = Location(0,0) ---@type location 
    BJDebugMsg((GetHandleId(L)-0x100000))
    RemoveLocation(L)
end

---@param pid integer
---@param g group
---@param r rect
---@param b boolexpr
function MakeGroupInRect(pid, g, r, b)
    callbackCount = callbackCount + 1
    passedValue[callbackCount] = pid
    GroupEnumUnitsInRect(g, r, b)
    callbackCount = callbackCount - 1
end

---@type fun(pid: integer, g: group, x: number, y: number, radius: number, b: boolexpr)
function MakeGroupInRange(pid, g, x, y, radius, b)
    callbackCount = callbackCount + 1
    passedValue[callbackCount] = pid
    GroupEnumUnitsInRange(g, x, y, radius, b)
    callbackCount = callbackCount - 1
end

---@type fun(pid: integer, g: group, x: number, y: number, radius: number, b: boolexpr)
function GroupEnumUnitsInRangeEx(pid, g, x, y, radius, b)
    local ug = CreateGroup()

    MakeGroupInRange(pid, ug, x, y, radius, b)
    BlzGroupAddGroupFast(ug, g)

    DestroyGroup(ug)
end

---@param pid integer
---@param index integer
---@param amount integer
function SetCurrency(pid, index, amount)
    Currency[pid * CURRENCY_COUNT + index] = IMaxBJ(0, amount)

    if index == GOLD then
        SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_GOLD, Currency[pid * CURRENCY_COUNT + index])
    elseif index == LUMBER then
        SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_LUMBER, Currency[pid * CURRENCY_COUNT + index])
    elseif index == PLATINUM then
        if GetLocalPlayer() == Player(pid - 1) then
            BlzFrameSetText(platText, (Currency[pid * CURRENCY_COUNT + index]))
        end
    elseif index == ARCADITE then
        if GetLocalPlayer() == Player(pid - 1) then
            BlzFrameSetText(arcText, (Currency[pid * CURRENCY_COUNT + index]))
        end
    elseif index == CRYSTAL then
        SetPlayerState(Player(pid - 1), PLAYER_STATE_RESOURCE_FOOD_USED, Currency[pid * CURRENCY_COUNT + index])
    end
end

---@param pid integer
---@param index integer
---@return integer
function GetCurrency(pid, index)
    return Currency[pid * CURRENCY_COUNT + index]
end

---@param pid integer
---@param index integer
---@param amount integer
function AddCurrency(pid, index, amount)
    SetCurrency(pid, index, GetCurrency(pid, index) + amount)
end

---@param s string
---@param s2 string
---@return boolean
function MatchString(s, s2)
    local i         = 0 ---@type integer 
    local i2         = 1 ---@type integer 
    local start         = 0 ---@type integer 
    local end_         = 0 ---@type integer 

    while not (i2 > StringLength(s2) + 1) do
        if SubString(s2, i, i2) == " " or i2 > StringLength(s2) then
            end_ = i
            if SubString(s2, start, end_) == s then
                return true
            end
            start = i2
        end

        i = i + 1
        i2 = i2 + 1
    end

    return false
end

---@param u unit
---@param show boolean
function ToggleCommandCard(u, show)
    local classification         = BlzGetUnitIntegerField(u, UNIT_IF_UNIT_CLASSIFICATION) ---@type integer 
    local ward         = GetHandleId(UNIT_CATEGORY_WARD) ---@type integer 

    if (BlzBitAnd(classification, ward) > 0 and show) or (BlzBitAnd(classification, ward) == 0 and not show) then
        BlzSetUnitIntegerField(u, UNIT_IF_UNIT_CLASSIFICATION, BlzBitXor(classification, ward))
    end
end

---@param path string
---@param is3D boolean
---@param p player
---@param u unit
function SoundHandler(path, is3D, p, u)
    local s ---@type sound 
    local ss        = "" ---@type string 

    if p ~= nil then
        if GetLocalPlayer() == p then
            ss = path
        end
        s = CreateSound(ss, false, is3D, is3D, 12700, 12700, "")
    else
        s = CreateSound(path, false, is3D, is3D, 12700, 12700, "")
    end

    if u ~= nil then
        AttachSoundToUnit(s, u)
    end

    StartSound(s)
    KillSoundWhenDone(s)
end

---@param t timer
---@return string
function RemainingTimeString(t)
    local time      = TimerGetRemaining(t) ---@type number 
    local s        = "" ---@type string 

    local minutes         = R2I(time // 60.) ---@type integer 
    local seconds         = R2I(time - minutes * 60) ---@type integer 

    if minutes > 0 then
        s = (minutes) .. " minutes"
    else
        s = (seconds) .. " seconds"
    end

    return s
end

function ItemRepickRemove()
    if Item[GetEnumItem()].owner == tempplayer then
        Item[GetEnumItem()]:destroy()
    end
end

--[[function CloseF11 takes nothing returns nothing
    if GetTriggerPlayer() == GetLocalPlayer() then
        call ForceUICancel()
    endif
endfunction]]

---@return boolean
function Trig_Enemy_Of_Hostile()
    if IsUnitEnemy(GetFilterUnit(),pfoe) == false then
        return false
    elseif UnitAlive(GetFilterUnit()) == false then
        return false
    elseif GetUnitTypeId(GetFilterUnit()) == BACKPACK then
        return false
    elseif GetUnitTypeId(GetFilterUnit()) == DUMMY then
        return false
    elseif GetUnitAbilityLevel(GetFilterUnit(), FourCC('Aloc')) > 0 then
        return false
    elseif GetPlayerId(GetOwningPlayer(GetFilterUnit())) > PLAYER_CAP then
        return false
    end
    return true
end

---@return boolean
function isvillager()
    local id         = GetUnitTypeId(GetFilterUnit()) ---@type integer 
    if id == FourCC('n02V') or id == FourCC('n03U') or id == FourCC('n09Q') or id == FourCC('n09T') or id == FourCC('n09O') or id == FourCC('n09P') or id == FourCC('n09R') or id == FourCC('n09S') or id == FourCC('nvk2') or id == FourCC('nvlw') or id == FourCC('nvlk') or id == FourCC('nvil') or id == FourCC('nvl2') or id == FourCC('H01Y') or id == FourCC('H01T') or id == FourCC('n036') or id == FourCC('n035') or id == FourCC('n037') or id == FourCC('n03S') or id == FourCC('n01I') or id == FourCC('n0A3') or id == FourCC('n0A4') or id == FourCC('n0A5') or id == FourCC('n0A6') or id == FourCC('h00G') then
        return true
    end
    return false
end

---@return boolean
function isspirit()
    local id         = GetUnitTypeId(GetFilterUnit()) ---@type integer 
    if id == FourCC('n00P') then
        return true
    end

    return false
end

---@return boolean
function ishero()
    return (IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true)
end

---@return boolean
function ischar()
    local pid         = GetPlayerId(GetOwningPlayer(GetFilterUnit())) + 1 ---@type integer 

    return (GetFilterUnit() == Hero[pid] and UnitAlive(Hero[pid]))
end

---@return boolean
function FilterNotHero()
    return (IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == false and UnitAlive(GetFilterUnit()) and GetUnitTypeId(GetFilterUnit()) ~= DUMMY)
end

---@return boolean
function isbase()
    return (IsUnitType(GetFilterUnit(), UNIT_TYPE_TOWNHALL) == true)
end

---@return boolean
function isOrc()
    local uid         = GetUnitTypeId(GetFilterUnit()) ---@type integer 

    return (UnitAlive(GetFilterUnit()) and (uid == FourCC('o01I') or uid == FourCC('o008')))
end

---@return boolean
function ishostile()
    local i         =GetPlayerId(GetOwningPlayer(GetFilterUnit())) ---@type integer 

    return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and (i ==10 or i ==11 or i ==PLAYER_NEUTRAL_AGGRESSIVE))
end

---@return boolean
function ChaosTransition()
    local i         = GetPlayerId(GetOwningPlayer(GetFilterUnit())) ---@type integer 

    return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and (i ==10 or i ==11 or i ==PLAYER_NEUTRAL_AGGRESSIVE) and RectContainsUnit(gg_rct_Colosseum, GetFilterUnit()) == false and RectContainsUnit(gg_rct_Infinite_Struggle, GetFilterUnit()) == false)
end

---@return boolean
function isplayerAlly()
    return (UnitAlive(GetFilterUnit()) and GetPlayerId(GetOwningPlayer(GetFilterUnit())) <= PLAYER_CAP and IsUnitType(GetFilterUnit(), UNIT_TYPE_HERO) == true and GetUnitTypeId(GetFilterUnit()) ~= BACKPACK)
end

---@return boolean
function iszeppelin()
    return (GetUnitTypeId(GetFilterUnit()) == FourCC('nzep') and UnitAlive(GetFilterUnit()))
end

---@return boolean
function isplayerunitRegion()
    return (UnitAlive(GetFilterUnit()) and GetPlayerId(GetOwningPlayer(GetFilterUnit())) <= PLAYER_CAP and GetUnitTypeId(GetFilterUnit()) ~= DUMMY)
end

---@return boolean
function isplayerunit()
    return (UnitAlive(GetFilterUnit()) and GetPlayerId(GetOwningPlayer(GetFilterUnit())) <= PLAYER_CAP and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY)
end

---@return boolean
function ishostileEnemy()
local i         =GetPlayerId(GetOwningPlayer(GetFilterUnit())) ---@type integer 
    return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(), FourCC('Avul')) ==0 and i <= PLAYER_CAP and GetUnitTypeId(GetFilterUnit()) ~= DUMMY)
end

---@return boolean
function isalive()
    return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY)
end

---@type fun(u: integer | unit):integer
function IsBoss(u)
    local i = 0 ---@type integer 
    local uid

    if type(u) == "number" then
        uid = u
    else
        uid = GetUnitTypeId(u)
    end

    while not (BossID[i] == uid or i > BOSS_TOTAL) do
        i = i + 1
    end

    if i > BOSS_TOTAL then
        return -1
    end

    return i
end

---@param i integer
---@return boolean
function IsEnemy(i)
    return (i == 12 or i == PLAYER_NEUTRAL_AGGRESSIVE + 1)
end

function ExplodeUnits()
    SetUnitExploded(GetEnumUnit(), true)
    KillUnit(GetEnumUnit())
end

---@param itm item
---@return boolean
function isImportantItem(itm)
    local id         = GetItemTypeId(itm) ---@type integer 

    return id == FourCC('I042') or id == FourCC('I040') or id == FourCC('I041') or id == FourCC('I0M4') or id == FourCC('I0M5') or id == FourCC('I0M6') or id == FourCC('I0M7') or itm == PathItem
end

function ClearItems()
    local itm      = GetEnumItem() ---@type item 

    if not isImportantItem(itm) then --keys + pathcheck
        Item[itm]:destroy()
    end
end

---@type fun(pt: PlayerTimer)
function AttackDelay(pt)
    BlzSetUnitWeaponBooleanField(pt.source, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
    IssueTargetOrderById(pt.source, 852173, pt.target)

    pt:destroy()
end

---@param source unit
---@param target unit
function InstantAttack(source, target)
    local pt = TimerList[0]:add() ---@class PlayerTimer 

    pt.source = source
    pt.target = target

    UnitAddAbility(source, FourCC('IATK'))
    pt.timer:callDelayed(0.05, AttackDelay, pt)
end

---@param x number
---@param y number
---@param abil integer
---@param ablev integer
---@param dur number
---@return unit
function GetDummy(x, y, abil, ablev, dur)
    if BlzGroupGetSize(DUMMY_STACK) > 0 then
        TEMP_DUMMY = BlzGroupUnitAt(DUMMY_STACK, 0)
        GroupRemoveUnit(DUMMY_STACK, TEMP_DUMMY)
        PauseUnit(TEMP_DUMMY, false)
    else
        DUMMY_LIST[DUMMY_COUNT] = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY, x, y, 0)
        TEMP_DUMMY = DUMMY_LIST[DUMMY_COUNT]
        DUMMY_COUNT = DUMMY_COUNT + 1
        UnitAddAbility(TEMP_DUMMY, FourCC('Amrf'))
        UnitRemoveAbility(TEMP_DUMMY, FourCC('Amrf'))
        UnitAddAbility(TEMP_DUMMY, FourCC('Aloc'))
        SetUnitPathing(TEMP_DUMMY, false)
        TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, TEMP_DUMMY, EVENT_UNIT_ACQUIRED_TARGET)
    end

    if UnitAddAbility(TEMP_DUMMY, abil) then
        SetUnitAbilityLevel(TEMP_DUMMY, abil, ablev)
        SaveInteger(MiscHash, GetHandleId(TEMP_DUMMY), FourCC('dspl'), abil)
    end

    if dur > 0 then
        TimerQueue:callDelayed(dur, RecycleDummy, TEMP_DUMMY)
    end

    --reset attack cooldown
    BlzSetUnitAttackCooldown(TEMP_DUMMY, 5., 0)
    UnitSetBonus(TEMP_DUMMY, BONUS_ATTACK_SPEED, 0.)

    SetUnitXBounded(TEMP_DUMMY, x)
    SetUnitYBounded(TEMP_DUMMY, y)

    return TEMP_DUMMY
end

---@param pid integer
function RemovePlayerUnits(pid)
    local ug       = CreateGroup()
    local target ---@type unit 
    local i         = 0 ---@type integer 
    local itid         = 0 ---@type integer 
    local itm ---@type item 

    GroupEnumUnitsOfPlayer(ug, Player(pid - 1), nil)

    while true do
        target = FirstOfGroup(ug)
        if target == nil then break end
        GroupRemoveUnit(ug, target)
        if IsUnitType(target, UNIT_TYPE_HERO) then
            i = 0
            while i <= 5 do
                itm = UnitItemInSlot(target, i)
                itid = GetItemTypeId(itm)
                if isImportantItem(itm) then
                    Item[itm]:destroy()
                    Item.create(CreateItem(itid, GetLocationX(TownCenter), GetLocationY(TownCenter)))
                end
                i = i + 1
            end
        end
        if GetUnitTypeId(target) ~= DUMMY then
            Buff.dispelAll(target)
            RemoveUnit(target)
        end
    end

    DestroyGroup(ug)
end

---@param hero unit
---@return integer
function HighestStat(hero)
    local str         = GetHeroStr(hero, true) ---@type integer 
    local agi         = GetHeroAgi(hero, true) ---@type integer 
    local int         = GetHeroInt(hero, true) ---@type integer 

    if str >= agi and str >= int then
        return 0
    elseif agi > str and agi >= int then
        return 1
    else
        return 2
    end
end

---@param hero unit
---@return integer
function MainStat(hero) --returns integer signifying primary attribute
    return BlzGetUnitIntegerField(hero, UNIT_IF_PRIMARY_ATTRIBUTE)
end

---@param pid integer
---@param i integer
function MainStatForm(pid, i)
    RemoveUnit(hsdummy[pid])
    if i == 1 then
        hsdummy[pid] = CreateUnit(Player(pid - 1), FourCC('E001'), 30000, 30000, 0)
    elseif i == 2 then
        hsdummy[pid] = CreateUnit(Player(pid - 1), FourCC('E004'), 30000, 30000, 0)
    elseif i == 3 then
        hsdummy[pid] = CreateUnit(Player(pid - 1), FourCC('E01A'), 30000, 30000, 0)
    end
end

---@param r rect
---@param x number
---@param y number
---@return boolean
function NearbyRect(r, x, y)
    local i         = 0 ---@type integer 
    local angle      = Atan2(GetRectCenterY(r) - y, GetRectCenterX(r) - x) ---@type number 

    while i <= 99 do
        if RectContainsCoords(r, x + Cos(angle) * i, y + Sin(angle) * i) then
            break
        end
        i = i + 1
    end

    return i <= 99
end

---@param i integer
---@param x number
---@param y number
function CustomLightingPlayerCheck(i, x, y)
    local daynightmodel        = DEFAULT_LIGHTING ---@type string 

    CustomLighting[i] = 1

    if RectContainsCoords(gg_rct_Naga_Dungeon, x, y) and not RectContainsCoords(gg_rct_Naga_Dungeon_Reward, x, y) then
        CustomLighting[i] = 2
    elseif RectContainsCoords(gg_rct_Naga_Dungeon_Boss, x, y) then
        CustomLighting[i] = 2
    elseif RectContainsCoords(gg_rct_Cave, x, y) then
        CustomLighting[i] = 3
    elseif RectContainsCoords(gg_rct_Crypt, x, y) then
        CustomLighting[i] = 4
    elseif RectContainsCoords(gg_rct_Church, x, y) then
        CustomLighting[i] = 4
    end

    if CustomLighting[i] ~= 1 then
        daynightmodel = "blacklight.mdx"
    end

    if CustomLighting[i] == 1 then
        UnitRemoveAbility(Hero[i], FourCC('A059'))
        UnitRemoveAbility(Hero[i], FourCC('A0AN'))
        UnitRemoveAbility(Hero[i], FourCC('A0B8'))
    elseif CustomLighting[i] == 2 and GetUnitAbilityLevel(Hero[i], FourCC('A0AN')) == 0 then
        UnitAddAbility(Hero[i], FourCC('A0AN'))
        UnitRemoveAbility(Hero[i], FourCC('A0B8'))
        UnitRemoveAbility(Hero[i], FourCC('A059'))
    elseif CustomLighting[i] == 3 and GetUnitAbilityLevel(Hero[i], FourCC('A0B8')) == 0 then
        UnitAddAbility(Hero[i], FourCC('A0B8'))
        UnitRemoveAbility(Hero[i], FourCC('A0AN'))
        UnitRemoveAbility(Hero[i], FourCC('A059'))
    elseif CustomLighting[i] == 4 and GetUnitAbilityLevel(Hero[i], FourCC('A059')) == 0 then
        UnitAddAbility(Hero[i], FourCC('A059'))
        UnitRemoveAbility(Hero[i], FourCC('A0AN'))
        UnitRemoveAbility(Hero[i], FourCC('A0B8'))
    end

    if GetLocalPlayer() == Player(i - 1) then
        SetDayNightModels(daynightmodel, daynightmodel)
    end
end

---@type fun(pt: PlayerTimer)
function DelayAnimationExpire(pt)
    if pt.str > 0 then
        BlzPauseUnitEx(pt.target, false)
    end

    if pt.dur > 0. then
        SetUnitTimeScale(pt.target, pt.dur)
    end

    SetUnitAnimationByIndex(pt.target, pt.agi)

    pt:destroy()
end

---@param pid integer
---@param u unit
---@param delay number
---@param index integer
---@param timescale number
---@param pause boolean
function DelayAnimation(pid, u, delay, index, timescale, pause)
    local pt             = TimerList[pid]:add() ---@class PlayerTimer 

    pt.target = u
    pt.agi = index
    pt.str = 0
    pt.dur = timescale
    pt.tag = FourCC('dani')

    if pause then
        BlzPauseUnitEx(u, true)
        pt.str = 1
    end

    pt.timer:callDelayed(delay, DelayAnimationExpire, pt)
end

---@param p player
---@param r rect
function SetCameraBoundsRectForPlayerEx(p, r)
    local minX      = GetRectMinX(r) ---@type number 
    local minY      = GetRectMinY(r) ---@type number 
    local maxX      = GetRectMaxX(r) ---@type number 
    local maxY      = GetRectMaxY(r) ---@type number 
    local pid         = GetPlayerId(p) + 1 ---@type integer 

    --lighting
    CustomLightingPlayerCheck(pid, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))

    if GetLocalPlayer() == p then
        SetCameraField(CAMERA_FIELD_ROTATION, 90., 0)
        SetCameraBounds(minX, minY, minX, maxY, maxX, maxY, maxX, minY)
    end
end

---@param pid integer
function SpawnWispSelector(pid)
    hslook[pid] = 0

    MainStatForm(pid, MainStat(HeroCircle[0].unit))

    BlzSetUnitSkin(hsdummy[pid], HeroCircle[0].skin)
    BlzSetUnitName(hsdummy[pid], GetUnitName(HeroCircle[0].unit))
    BlzSetHeroProperName(hsdummy[pid], GetHeroProperName(HeroCircle[0].unit))
    --call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_PRIMARY_ATTRIBUTE, BlzGetUnitIntegerField(HeroCircle[0].unit, UNIT_IF_PRIMARY_ATTRIBUTE))
    BlzSetUnitWeaponIntegerField(hsdummy[pid], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0, BlzGetUnitWeaponIntegerField(HeroCircle[0].unit, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0))
    BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_DEFENSE_TYPE, BlzGetUnitIntegerField(HeroCircle[0].unit, UNIT_IF_DEFENSE_TYPE))
    BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0, BlzGetUnitWeaponRealField(HeroCircle[0].unit, UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0))
    BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_RANGE, 1, BlzGetUnitWeaponRealField(HeroCircle[0].unit, UNIT_WEAPON_RF_ATTACK_RANGE, 0) - 100)
    BlzSetUnitArmor(hsdummy[pid], BlzGetUnitArmor(HeroCircle[0].unit))

    SetHeroStr(hsdummy[pid], GetHeroStr(HeroCircle[0].unit, true), true)
    SetHeroAgi(hsdummy[pid], GetHeroAgi(HeroCircle[0].unit, true), true)
    SetHeroInt(hsdummy[pid], GetHeroInt(HeroCircle[0].unit, true), true)

    BlzSetUnitBaseDamage(hsdummy[pid], BlzGetUnitBaseDamage(HeroCircle[hslook[pid]].unit, 0), 0)
    BlzSetUnitDiceNumber(hsdummy[pid], BlzGetUnitDiceNumber(HeroCircle[hslook[pid]].unit, 0), 0)
    BlzSetUnitDiceSides(hsdummy[pid], BlzGetUnitDiceSides(HeroCircle[hslook[pid]].unit, 0), 0)

    BlzSetUnitMaxHP(hsdummy[pid], BlzGetUnitMaxHP(HeroCircle[0].unit))
    BlzSetUnitMaxMana(hsdummy[pid], BlzGetUnitMaxMana(HeroCircle[0].unit))
    SetWidgetLife(hsdummy[pid], BlzGetUnitMaxHP(hsdummy[pid]))

    UnitAddAbility(hsdummy[pid], HeroCircle[0].select)
    UnitAddAbility(hsdummy[pid], HeroCircle[0].passive)

    UnitAddAbility(hsdummy[pid], FourCC('A0JI'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JQ'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JR'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JS'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JT'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JU'))
    UnitAddAbility(hsdummy[pid], FourCC('Aeth'))
    SetUnitPathing(hsdummy[pid], false)
    UnitRemoveAbility(hsdummy[pid], FourCC('Amov'))
    BlzUnitHideAbility(hsdummy[pid], FourCC('Aatk'), true)
    SetCameraBoundsRectForPlayerEx(Player(pid - 1), gg_rct_Tavern_Vision)

    if (GetLocalPlayer() == Player(pid - 1)) then
        SetCameraTargetController(HeroCircle[0].unit, 0, 0, false)
        ClearSelection()
        SelectUnit(hsdummy[pid], true)
        SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
    end

    Backpack[pid] = nil
    selectingHero[pid] = true
    SetCurrency(pid, GOLD, 75)
    SetCurrency(pid, LUMBER, 30)
end

---@type fun(u: unit)
function ResetPathing(u)
    SetUnitPathing(u, true)
end

---@type fun(u: unit, time: number)
function ResetPathingTimed(u, time)
    TimerQueue:callDelayed(time, ResetPathing, u)
end

---@param line integer
---@param contents string
---@return string
function getLine(line, contents)
    local len               = StringLength(contents) ---@type integer 
    local char              = "" ---@type string 
    local buffer            = ""  ---@type string 
    local curLine           = 0 ---@type integer 
    local i                 = 0 ---@type integer 

    while i <= len do
        char = SubString(contents, i, i + 1)
        if (char == "\n") then
            curLine = curLine + 1
            if (curLine > line) then
                return buffer
            end
            buffer = ""
        else
            buffer = buffer + char
        end
        i = i + 1
    end

    if (curLine == line) then
        return buffer
    end

    return null
end

---@param pid integer
function SetSaveSlot(pid)
    local i         = 0 ---@type integer 

    while i <= MAX_SLOTS do

        if Profile[pid].phtl[i] == 0 then
            Profile[pid].currentSlot = i
            break
        end

        i = i + 1
    end

    if i == 30 then
        Profile[pid].currentSlot = -1
    end
end

---@return boolean
function ConfirmDeleteCharacter()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@class DialogWindow 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        if GetLocalPlayer() == GetTriggerPlayer() then
            FileIO.Save(MAP_NAME .. "\\" .. User[pid - 1].name .. "\\slot" .. (Profile[pid].currentSlot + 1) .. ".pld", "")
        end
        Profile[pid]:saveProfile()

        dw:destroy()
    end

    return false
end

---@return boolean
function LoadMenu()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@class DialogWindow 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    --new character button
    if GetClickedButton() == dw.MenuButton[2] then
        SetSaveSlot(pid)

        if Profile[pid]:getSlotsUsed() >= 30 then
            DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 30.0, "You cannot save more than 30 heroes!")
            dw.Page = -1
            dw:display()
        else
            if not selectingHero[pid] then
                DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 30.0, "Select a |c006969ffhero|r using the left and right arrow keys.")
                newcharacter[pid] = true
                SpawnWispSelector(pid)
            end

            dw:destroy()
        end
    --load / delete button
    elseif GetClickedButton() == dw.MenuButton[3] then
        --stay at the same page
        if dw.Page > -1 then
            dw.Page = dw.Page - 1
        end

        if deleteMode[pid] then
            deleteMode[pid] = false
            dw.MenuButtonName[3] = "|cffff0000Delete Character"
            dw.title = "|cffffffffLOAD"
            dw:display()
        else
            deleteMode[pid] = true
            dw.MenuButtonName[3] = "|cffffffffLoad Character"
            dw.title = "|cffff0000DELETE"
            dw:display()
        end
    --character slot
    elseif index ~= -1 then
        Profile[pid].currentSlot = dw.data[index]
        dw:destroy()

        if deleteMode[pid] then
            --confirm delete character
            dw = DialogWindow.create(pid, "Are you sure?|nAny prestige bonuses from this character will be lost!", ConfirmDeleteCharacter)
            dw:addButton("|cffff0000DELETE")
            dw:display()
        else
            --load character
            DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "Loading |c006969ffhero|r from selected slot...")

            if GetLocalPlayer() == GetTriggerPlayer() then
                BlzSendSyncData(SYNC_PREFIX, getLine(1, FileIO.Load(MAP_NAME .. "\\" + User[pid - 1].name .. "\\slot" .. (Profile[pid].currentSlot + 1) .. ".pld")))
            end
        end
    end

    return false
end

---@param pid integer
function DisplayHeroSelectionDialog(pid)
    local i         = 0 ---@type integer 
    local name        = "" ---@type string 
    local hardcore         = 0 ---@type integer 
    local prestige         = 0 ---@type integer 
    local id         = 0 ---@type integer 
    local herolevel         = 0 ---@type integer 
    local dw              = DialogWindow.create(pid, "|cffffffffLOAD", LoadMenu) ---@class DialogWindow 

    deleteMode[pid] = false

    while i <= MAX_SLOTS do
        hardcore = 0
        prestige = 0
        id = 0
        herolevel = 0

        if Profile[pid].phtl[i] > 0 then --slot is not empty
            name = "|cffffcc00"
            hardcore = Profile[pid].phtl[i] & 0x1
            prestige = (Profile[pid].phtl[i] & 0x6) >> 1
            id = (Profile[pid].phtl[i] & 0x1F8) >> 3
            herolevel = (Profile[pid].phtl[i] & 0x7FE00) >> 9

            if prestige > 0 then
                name = name .. "[PRSTG] "
            end
            name = name .. GetObjectName(SAVE_UNIT_TYPE[id]) .. " [" .. (herolevel) .. "] "
            if hardcore > 0 then
                name = name .. "[HC]"
            end

            dw.data[dw.ButtonCount] = i
            dw:addButton(name)
        end

        i = i + 1
    end

    dw:addMenuButton("|cffffffffNew Character")
    dw:addMenuButton("|cffff0000Delete Character")

    dw:display()
end

---@param arena integer
function ResetArena(arena)
    local pid ---@type integer 
    local U      = User.first ---@class User 

    if arena == 0 then
        return
    end

    while U do
        pid = GetPlayerId(U.player) + 1

        if IsUnitInGroup(Hero[pid], Arena[arena]) then
            PauseUnit(Hero[pid], false)
            UnitRemoveAbility(Hero[pid], FourCC('Avul'))
            SetUnitAnimation(Hero[pid], "stand")
            SetUnitPositionLoc(Hero[pid], TownCenter)
            SetCameraBoundsRectForPlayerEx(GetOwningPlayer(Hero[pid]), gg_rct_Main_Map_Vision)
            PanCameraToTimedForPlayer(GetOwningPlayer(Hero[pid]), GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
        end

        U = U.next
    end
end

---@param pid integer
---@return integer
function GetArena(pid)
    local i         = 0 ---@type integer 

    while i <= ArenaMax do
        if IsUnitInGroup(Hero[pid], Arena[i]) then
            return i
        end
        i = i + 1
    end

    return 0
end

function ClearStruggle()
    local ug       = CreateGroup()
    local u ---@type unit 
    local U      = User.first ---@class integer 

    GroupEnumUnitsInRect(ug, gg_rct_Infinite_Struggle, Condition(FilterNotHero))
    while true do
        u = FirstOfGroup(ug)
        if u == nil then break end
        GroupRemoveUnit(ug, u)
        RemoveUnit(u)
    end

    Struggle_WaveN = 0
    GoldWon_Struggle = 0
    Struggle_WaveUCN = 0

    DestroyGroup(ug)
end

function ClearColo()
    local ug       = CreateGroup()
    local u ---@type unit 

    GoldWon_Colo = 0

    GroupEnumUnitsInRect(ug, gg_rct_Colosseum, Condition(FilterNotHero))
    while true do
        u = FirstOfGroup(ug)
        if u == nil then break end
        GroupRemoveUnit(ug, u)
        RemoveUnit(u)
    end

    EnumItemsInRect(gg_rct_Colosseum, nil, ClearItems)
    SetTextTagText(ColoText, "Colosseum", 10 * 0.023 / 10)
    DestroyGroup(ug)
end

---@param p player
---@param show boolean
function ShowHeroCircle(p, show)
    if show then
        if GetLocalPlayer() == p then
            BlzSetUnitSkin(gg_unit_H02A_0568, GetUnitTypeId(gg_unit_H02A_0568))
            BlzSetUnitSkin(gg_unit_H03N_0612, GetUnitTypeId(gg_unit_H03N_0612))
            BlzSetUnitSkin(gg_unit_H04Z_0604, GetUnitTypeId(gg_unit_H04Z_0604))
            BlzSetUnitSkin(gg_unit_H012_0605, GetUnitTypeId(gg_unit_H012_0605))
            BlzSetUnitSkin(gg_unit_U003_0081, GetUnitTypeId(gg_unit_U003_0081))
            BlzSetUnitSkin(gg_unit_H01N_0606, GetUnitTypeId(gg_unit_H01N_0606))
            BlzSetUnitSkin(gg_unit_H01S_0607, GetUnitTypeId(gg_unit_H01S_0607))
            BlzSetUnitSkin(gg_unit_H05B_0608, GetUnitTypeId(gg_unit_H05B_0608))
            BlzSetUnitSkin(gg_unit_H029_0617, GetUnitTypeId(gg_unit_H029_0617))
            BlzSetUnitSkin(gg_unit_O02S_0615, GetUnitTypeId(gg_unit_O02S_0615))
            BlzSetUnitSkin(gg_unit_H00R_0610, GetUnitTypeId(gg_unit_H00R_0610))
            BlzSetUnitSkin(gg_unit_E00G_0616, GetUnitTypeId(gg_unit_E00G_0616))
            BlzSetUnitSkin(gg_unit_E012_0613, GetUnitTypeId(gg_unit_E012_0613))
            BlzSetUnitSkin(gg_unit_E00W_0614, GetUnitTypeId(gg_unit_E00W_0614))
            BlzSetUnitSkin(gg_unit_E002_0585, GetUnitTypeId(gg_unit_E002_0585))
            BlzSetUnitSkin(gg_unit_O03J_0609, GetUnitTypeId(gg_unit_O03J_0609))
            BlzSetUnitSkin(gg_unit_E015_0586, GetUnitTypeId(gg_unit_E015_0586))
            BlzSetUnitSkin(gg_unit_E008_0587, GetUnitTypeId(gg_unit_E008_0587))
            BlzSetUnitSkin(gg_unit_E00X_0611, GetUnitTypeId(gg_unit_E00X_0611))
        end
    else
        if GetLocalPlayer() == p then
            BlzSetUnitSkin(gg_unit_H02A_0568, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H03N_0612, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H04Z_0604, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H012_0605, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_U003_0081, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H01N_0606, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H01S_0607, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H05B_0608, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H029_0617, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_O02S_0615, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_H00R_0610, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_E00G_0616, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_E012_0613, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_E00W_0614, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_E002_0585, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_O03J_0609, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_E015_0586, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_E008_0587, FourCC('eRez'))
            BlzSetUnitSkin(gg_unit_E00X_0611, FourCC('eRez'))
        end
        ShowUnit(gg_unit_n02S_0098, false)
        ShowUnit(gg_unit_n02S_0098, true)
    end
end

---@param p player
function PlayerCleanup(p) --any instance of player removal (leave, repick, permanent death, forcesave, afk removal)
    local pid         = GetPlayerId(p) + 1 ---@type integer 
    local i         = 0 ---@type integer 
    local itm ---@class Item 
    local ug       = CreateGroup()
    local target ---@type unit 

    UnitRemoveAbility(Hero[pid], FourCC('A03C')) --close actions spellbook

    while true do --clear ashen vat
        if i > 5 then break end
        itm = Item[UnitRemoveItemFromSlot(ASHEN_VAT, i)]
        if itm and itm.owner == p then
            itm:destroy()
        end
        i = i + 1
    end

    i = 0

    while true do --clear cosmetics
        if i > cosmeticTotal then break end

        if cosmeticAttach[pid * cosmeticTotal + i] ~= nil then
            TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + i])
            cosmeticAttach[pid * cosmeticTotal + i] = nil
        end

        i = i + 1
    end

    if InColo[pid] then
        ColoPlayerCount = ColoPlayerCount - 1
        InColo[pid] = false

        if ColoPlayerCount == 0 then
            ClearColo()
        end
    end

    ResetArena(GetArena(pid)) --reset pvp

    if InStruggle[pid] then
        Struggle_Pcount = Struggle_Pcount - 1
        InStruggle[pid] = false

        if Struggle_Pcount == 0 then
            ClearStruggle()
        end
    end

    Profile[pid].hero:wipeData()
    TimerList[pid]:stopAllTimers()

    mybase[pid] = nil
    GroupRemoveUnit(HeroGroup, Hero[pid])
    RemovePlayerUnits(pid)

    Hero[pid] = nil
    HERO_PROF[pid] = 0
    HeroID[pid] = 0
    Backpack[pid] = nil
    SetCurrency(pid, GOLD, 0)
    SetCurrency(pid, LUMBER, 0)
    SetCurrency(pid, PLATINUM, 0)
    SetCurrency(pid, ARCADITE, 0)
    SetCurrency(pid, CRYSTAL, 0)
    ArcaConverter[pid] = false
    ArcaConverterBought[pid] = false
    PlatConverter[pid] = false
    PlatConverterBought[pid] = false
    PhysicalTakenBase[pid] = 0
    MagicTakenBase[pid] = 0
    ItemEvasion[pid] = 0
    ItemRegen[pid] = 0
    BuffRegen[pid] = 0.
    PercentHealBonus[pid] = 0
    ItemSpellboost[pid] = 0
    ItemMovespeed[pid] = 0
    BuffMovespeed[pid] = 0
    ItemMagicRes[pid] = 1
    ItemDamageRes[pid] = 1
    TotalRegen[pid] = 0
    TotalEvasion[pid] = 0
    ItemGoldRate[pid] = 0
    TimePlayed[pid] = 0
    HeartBlood[pid] = 0
    urhome[pid] = 0
    BloodBank[pid] = 0
    BardSong[pid] = 0
    hardcoreClicked[pid] = false
    CameraLock[pid] = false
    meatgolem[pid] = nil
    destroyer[pid] = nil
    hounds[pid * 10] = nil
    hounds[pid * 10 + 1] = nil
    hounds[pid * 10 + 2] = nil
    hounds[pid * 10 + 3] = nil
    hounds[pid * 10 + 4] = nil
    hounds[pid * 10 + 5] = nil
    CustomLighting[pid] = 1 --default
    masterElement[pid] = 0
    PhantomSlashing[pid] = false
    BodyOfFireCharges[pid] = 5 --default
    limitBreak[pid] = 0
    limitBreakPoints[pid] = 0
    metamorphosis[pid] = 0.

    if GetLocalPlayer() == p then
        BlzFrameSetVisible(LimitBreakBackdrop, false)
        BlzSetAbilityIcon(PARRY.id, "ReplaceableTextures\\CommandButtons\\BTNReflex.blp")
        BlzSetAbilityIcon(SPINDASH.id, "ReplaceableTextures\\CommandButtons\\BTNComed Fall.blp")
        BlzSetAbilityIcon(INTIMIDATINGSHOUT.id, "ReplaceableTextures\\CommandButtons\\BTNBattleShout.blp")
        BlzSetAbilityIcon(WINDSCAR.id, "ReplaceableTextures\\CommandButtons\\BTNimpaledflameswordfinal.blp")
        DisplayCineFilter(false)
    end

    DestroyEffect(lightningeffect[pid])
    DestroyEffect(songeffect[pid])

    --reset unit limit
    workerCount[pid] = 0
    smallwispCount[pid] = 0
    largewispCount[pid] = 0
    warriorCount[pid] = 0
    rangerCount[pid] = 0
    SetPlayerTechResearched(p, FourCC('R013'), 1)
    SetPlayerTechResearched(p, FourCC('R014'), 1)
    SetPlayerTechResearched(p, FourCC('R015'), 1)
    SetPlayerTechResearched(p, FourCC('R016'), 1)
    SetPlayerTechResearched(p, FourCC('R017'), 1)

    sniperstance[pid] = false
    Hardcore[pid] = false
    ArenaQueue[pid] = 0

    newcharacter[pid] = true
    SetSaveSlot(pid) --repicking sets you to an empty save slot

    --[[set i = 1
    
    loop
        exitwhen i > 10
        call SaveBoolean(PlayerProf, pid, i, false)
        set i = i + 1
    endloop]]

    tempplayer = p
    EnumItemsInRect(bj_mapInitialPlayableArea, nil, ItemRepickRemove)

    if autosave[pid] then
        autosave[pid] = false
        DisplayTextToPlayer(p, 0, 0, "|cffffcc00Autosave disabled.|r")
    end

    DestroyGroup(ug)
end

---@param u1 unit
---@param u2 unit
---@return number
function UnitDistance(u1, u2)
    local dx     = GetUnitX(u2)-GetUnitX(u1) ---@type number 
    local dy     = GetUnitY(u2)-GetUnitY(u1) ---@type number 

    return SquareRoot(dx * dx + dy * dy)
end

---@param l1 location
---@param l2 location
---@return number
function Distance(l1, l2)
    local dx     = GetLocationX(l2)-GetLocationX(l1) ---@type number 
    local dy     = GetLocationY(l2)-GetLocationY(l1) ---@type number 

    return SquareRoot(dx * dx + dy * dy)
end

---@param x number
---@param y number
---@param x2 number
---@param y2 number
---@return number
function DistanceCoords(x, y, x2, y2)
    return SquareRoot(Pow(x - x2, 2) + Pow(y - y2, 2))
end

---@param u unit
function ExpireUnit(u)
    UnitApplyTimedLife(u, FourCC('BTLF'), 0.1)
end

---@param u unit
---@param abid integer
function UnitResetAbility(u, abid)
    local i         =GetUnitAbilityLevel(u, abid) ---@type integer 

    UnitRemoveAbility(u, abid)
    UnitAddAbility(u, abid)
    SetUnitAbilityLevel(u, abid,i)
end

---@param p player
---@param p2 player
---@param show boolean
function ShowHeroPanel(p, p2, show)
    if show == true then
        MultiboardDisplayBJ(false, MULTI_BOARD)
        SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_ADVANCED_CONTROL, true, p)
        SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_CONTROL, false, p)
        MultiboardDisplayBJ(true, MULTI_BOARD)
    else
        SetPlayerAllianceBJ(p2, ALLIANCE_SHARED_ADVANCED_CONTROL, false, p)
    end
end

---@param u unit
---@param itid integer
---@return item?
function GetItemFromUnit(u, itid)
    local i         = 0 ---@type integer 
    local itm ---@type item 

    while i <= 5 do
        itm = UnitItemInSlot(u, i)
        if itm ~= nil and GetItemTypeId(itm) == itid then
            return UnitItemInSlot(u, i)
        end
        i = i + 1
    end

    return nil
end

---@type fun(pid: integer, id: integer):integer
function PlayerCountItemType(pid, id)
    local j = 0 ---@type integer 

    for i = 0, MAX_INVENTORY_SLOTS - 1 do
        if Profile[pid].hero.items[i] and Profile[pid].hero.items[i].id == id then
            if Profile[pid].hero.items[i].charges > 1 then
                j = j + Profile[pid].hero.items[i].charges
            else
                j = j + 1
            end
        end
    end

    return j
end

---@type fun(pid: integer, id: integer):boolean
function PlayerHasItemType(pid, id)
    for i = 0, MAX_INVENTORY_SLOTS - 1 do
        if Profile[pid].hero.items[i] and Profile[pid].hero.items[i].id == id then
            return true
        end
    end

    return false
end

---@type fun(u: unit, itid: integer):boolean
function HasItemType(u, itid)
    local i         = 0 ---@type integer 

    while i <= 5 do
        if GetItemTypeId(UnitItemInSlot(u, i)) == itid then
            return true
        end
        i = i + 1
    end

    return false
end

---@param pid integer
---@param charge boolean
---@return Item?
function GetResurrectionItem(pid, charge)
    local i ---@type integer 
    local itm ---@class Item 

    i = 0
    while i <= 5 do
        itm = Item[UnitItemInSlot(Hero[pid], i)]
        if itm then
            if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') or ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') then
                if charge and ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') then
                    return itm
                elseif not charge and GetItemCharges(itm.obj) > 0 then
                    return itm
                end
            end
        end
        i = i + 1
    end

    if charge then
        i = 0
        while i <= 5 do
            itm = Item[UnitItemInSlot(Backpack[pid], i)]
            if itm then
                if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') or ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') then
                    if charge and ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') then
                        return itm
                    elseif not charge and GetItemCharges(itm.obj) > 0 then
                        return itm
                    end
                end
            end
            i = i + 1
        end
    end

    return nil
end

---@type fun(pt: PlayerTimer)
function MoveExpire(pt)
    pt.dur = pt.dur - 1

    if pt.dur <= 0 then
        bpmoving[pt.pid] = false
        pt:destroy()
    else
        TimerQueue:callDelayed(1., MoveExpire, pt)
    end
end

---@param groupnumber integer
---@return rect
function SelectGroupedRegion(groupnumber)
    local lowBound         = groupnumber * REGION_GAP ---@type integer 
    local highBound         = lowBound ---@type integer 

    while not (RegionCount[highBound] == nil) do
        highBound = highBound + 1
    end

    return RegionCount[GetRandomInt(lowBound, highBound - 1)]
end

--adds commas
---@param value number
---@return string
function RealToString(value)
    local s        = (R2I(value)) ---@type string 
    local len         = StringLength(s) ---@type integer 

    if len > 9 then
        s = SubString(s, 0, len - 9) .. "," .. SubString(s, len - 9, len - 6) .. "," .. SubString(s, len - 6, len - 3) .. "," .. SubString(s, len - 3, len)
    elseif len > 6 then
        s = SubString(s, 0, len - 6) .. "," .. SubString(s, len - 6, len - 3) .. "," .. SubString(s, len -3, len)
    elseif len > 3 then
        s = SubString(s, 0, len - 3) .. "," .. SubString(s, len - 3, len)
    end

    return s
end

---@param id integer
---@param pid integer
---@return number
function ItemProfMod(id, pid)
    local mod      = 1 ---@type number 
    local prof         = ItemData[id][ITEM_TYPE] ---@type integer 

    if prof > 0 and prof ~= 5 and BlzBitAnd(PROF[prof], HERO_PROF[pid]) == 0 then
        mod = 0.75
    end

    return mod
end

---@param itemType integer
---@return integer
function ItemToIndex(itemType)
    return LoadInteger(SAVE_TABLE, KEY_ITEMS, itemType)
end

---@param pid integer
---@param itm Item
function ItemInfo(pid, itm)
    local i         = 0 ---@type integer 
    local p        = Player(pid - 1) ---@type player 
    local s        = GetObjectName(itm.id) ---@type string 
    local offset         = 3 ---@type integer 
    local cost         = itm:calcStat(ITEM_COST, 0) ---@type integer 
    local maxlvl         = ItemData[itm.id][ITEM_UPGRADE_MAX] ---@type integer 

    if itm.level > 0 then
        s = s .. " [" .. LEVEL_PREFIX[itm.level] .. " +" .. (itm.level) .. "]"
    end

    if maxlvl > 0 then
        s = s .. " |cff999999(MAX +" .. (maxlvl) .. ")|r"
    end

    DisplayTimedTextToPlayer(p, 0, 0, 15., s)

    if cost > 0 then
        if (cost / 1000000) > 0 then
            DisplayTimedTextToPlayer(p, 0, 0, 15., "|cffffcc00Cost|r: " .. RealToString(cost / 1000000) .. " |cffe3e2e2Platinum|r and " .. RealToString(ModuloInteger(cost,1000000)) .. " |cffffcc00Gold|r")
        else
            DisplayTimedTextToPlayer(p, 0, 0, 15., "|cffffcc00Cost|r: " .. RealToString(cost) .. " |cffffcc00Gold|r")
        end
    end

    if ItemProfMod(itm.id, pid) < 1 then
        DisplayTimedTextToPlayer(p, 0, 0, 15., "|cffbbbbbbProficiency|r: " .. RealToString(ItemProfMod(itm.id, pid) * 100) .. "%")
    end

    i = ITEM_HEALTH
    while i <= ITEM_STAT_TOTAL do
            if ItemData[itm.id][i] ~= 0 and STAT_NAME[i] ~= nil then
                s = ""

                if i == ITEM_MAGIC_RESIST or i == ITEM_DAMAGE_RESIST or i == ITEM_EVASION or i == ITEM_CRIT_CHANCE or i == ITEM_SPELLBOOST or i == ITEM_GOLD_GAIN then
                    s = "%"
                    offset = 4
                end

                if i == ITEM_CRIT_CHANCE then
                    i = i + 1
                    DisplayTimedTextToPlayer(p, 0, 0, 15., SubString(STAT_NAME[i], offset, StringLength(STAT_NAME[i])) .. ": " .. RealToString(itm:calcStat(ITEM_CRIT_CHANCE, 0)) .. "% " .. RealToString(itm:calcStat(ITEM_CRIT_DAMAGE, 0)) .. "x")
                else
                    DisplayTimedTextToPlayer(p, 0, 0, 15., SubString(STAT_NAME[i], offset, StringLength(STAT_NAME[i])) .. ": " .. RealToString(itm:calcStat(i, 0)) + s)
                end
            end
        i = i + 1
    end

    if ItemToIndex(itm.id) > 0 then --item info cannot be cast on backpacked items
        DisplayTimedTextToPlayer(p, 0, 0, 15., "|c0000ff33Saveable|r")
    end
end

---@param flag integer
function SpawnCreeps(flag)
    local i         = 0 ---@type integer 
    local index = UnitData[flag][i]
    local myregion      = nil ---@type rect 
    local x ---@type number 
    local y ---@type number 

    while index do
        for _ = 1, UnitData[index][UNITDATA_COUNT] do
            myregion = SelectGroupedRegion(UnitData[index][UNITDATA_SPAWN])
            repeat
                x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
                y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
            until IsTerrainWalkable(x, y)
            CreateUnit(pfoe, index, x, y, GetRandomInt(0, 359))
        end

        i = i + 1
        index = UnitData[flag][i]
    end
end

---@type fun(pid: integer, id: integer):Item
function PlayerAddItemById(pid, id)
    local itm = Item.create(CreateItem(id, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]))) ---@class Item

    itm.owner = Player(pid - 1)

    UnitAddItem(Hero[pid], itm.obj)

    --stack check
    if not itm then
        return nil
    end

    if IsItemOwned(itm.obj) == false then
        UnitAddItem(Backpack[pid], itm.obj)
    end

    --stack check
    if not itm then
        return nil
    end

    if IsItemOwned(itm.obj) == false then
        for i = 12, MAX_INVENTORY_SLOTS - 1 do
            if Profile[pid].hero.items[i] == nil and itm then
                SetItemPosition(itm.obj, 30000., 30000.)
                SetItemVisible(itm.obj, false)
                Profile[pid].hero.items[i] = itm
                break
            end
        end
    end

    return itm
end

---@param id integer
---@return boolean
function IsBindItem(id)
    return (id == FourCC('I002') or id == FourCC('I000') or id == FourCC('I03L') or id == FourCC('I0N2') or id == FourCC('I0N1') or id == FourCC('I0N3') or id == FourCC('I0FN') or id == FourCC('I086') or id == FourCC('I001') or id == FourCC('I068') or id == FourCC('I05S') or id == FourCC('I04Q'))
end

---@param u unit
---@param plat integer
---@param arc integer
---@param id integer
function BuyHome(u, plat, arc, id)
    local pid         = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 

    if GetCurrency(pid, PLATINUM) < plat or GetCurrency(pid, ARCADITE) < arc then
        DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 10, "You do not have enough resources to buy this.")
    else
        PlayerAddItemById(pid, id)
        AddCurrency(pid, PLATINUM, -plat)
        AddCurrency(pid, ARCADITE, -arc)
        DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 20, "You have purchased a " + GetObjectName(id) .. ".")
        DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 10, PlatTag + (GetCurrency(pid, PLATINUM)))
        DisplayTimedTextToPlayer(GetOwningPlayer(u),0,0, 10, ArcTag + (GetCurrency(pid, ARCADITE)))
    end
end

--used before equip
---@param u unit
---@return integer
function GetEmptySlot(u)
    local i         = 0 ---@type integer 

    while i <= 5 do
        if UnitItemInSlot(u, i) == nil then
            return i
        end
        i = i + 1
    end

    return i
end

---@param itm item
---@param u unit
---@return integer
function GetItemSlot(itm, u)
    local i         = 0 ---@type integer 

    while i <= 5 do
        if UnitItemInSlot(u, i) == itm then
            return i
        end
        i = i + 1
    end

    return -1
end

---@param itm Item
---@param pid integer
---@return boolean
function IsItemBound(itm, pid)
    return (itm.owner ~= Player(pid - 1) and itm.owner ~= nil)
end

---@param itm Item
---@return boolean
function IsItemRestricted(itm)
    local limit = ItemData[itm.id][ITEM_LIMIT] ---@type integer 

    if limit == 0 then
        return false
    end

    for i = 0, 5 do
        local itm2 = UnitItemInSlot(itm.holder, i)
        local id = GetItemTypeId(itm2)

        if itm.obj == itm2 or (limit == 1 and itm.id ~= id) then
        --safe case
        elseif limit == ItemData[id][ITEM_LIMIT] then
            DisplayTextToPlayer(GetOwningPlayer(itm.holder), 0, 0, LIMIT_STRING[limit])
            return true
        end
    end

    return false
end

---@param itm Item
---@return boolean
function IsItemDud(itm)
    return GetItemTypeId(itm.obj) == FourCC('iDud')
end

---@type fun(pid: integer, id: integer):Item
function GetItemFromPlayer(pid, id)
    for i = 0, MAX_INVENTORY_SLOTS - 1 do
        if Profile[pid].hero.items[i] and Profile[pid].hero.items[i].id == id then
            return Profile[pid].hero.items[i]
        end
    end

    return nil
end

---@param index integer
function IndexWells(index)
    while index <= wellcount do
        well[index] = well[index + 1]
        wellheal[index] = wellheal[index + 1]
        index = index + 1
    end

    wellcount = wellcount - 1
end

---@param level integer
---@return integer
function RequiredXP(level)
    local base         = 150 ---@type integer 
    local i         = 2 ---@type integer 
    local levelFactor         = 100 ---@type integer 

    while i <= level do
        i = i + 1
        base = base + i * levelFactor
    end

    return base
end

---@param id integer
---@param chance integer
---@param x number
---@param y number
function BossDrop(id, chance, x, y)
    local i         = 0 ---@type integer 
    local itm ---@class Item 

    while i <= HardMode do
            if GetRandomInt(0, 99) < chance then
                itm = Item.create(CreateItem(DropTable:pickItem(id), x, y), 600.)
                itm:lvl(IMaxBJ(0, ItemData[itm.id][ITEM_UPGRADE_MAX] - GetRandomInt(8, 11)))
            end
        i = i + 1
    end
end

---@param stat integer
---@param u unit
---@param bonuses boolean
---@return integer
function GetHeroStat(stat, u, bonuses)
    if (stat == 1) then
        return GetHeroStr(u, bonuses)
    elseif (stat == 2) then
        return GetHeroInt(u, bonuses)
    elseif (stat == 3) then
        return GetHeroAgi(u, bonuses)
    end

    return 0
end

---@param p0_x number
---@param p0_y number
---@param p1_x number
---@param p1_y number
---@param p2_x number
---@param p2_y number
---@param p3_x number
---@param p3_y number
---@return location | nil
function GetLineIntersection(p0_x, p0_y, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)
    local s1_x      = p1_x - p0_x ---@type number 
    local s1_y      = p1_y - p0_y ---@type number 
    local s2_x      = p3_x - p2_x ---@type number 
    local s2_y      = p3_y - p2_y ---@type number 
    local s      = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y) ---@type number 
    local t      = (s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) // (-s2_x * s1_y + s1_x * s2_y) ---@type number 
    local i_x      = 0. ---@type number 
    local i_y      = 0. ---@type number 

    if (s >= 0.0 and s <= 1.0 and t >= 0.0 and t <= 1.0) then
        -- collision
        i_x = p0_x + (t * s1_x)
        i_y = p0_y + (t * s1_y)

        return Location(i_x, i_y)
    end

    --no collision
    return nil
end

---@param x number
---@param y number
---@param x2 number
---@param y2 number
---@param MinX number
---@param MinY number
---@param MaxX number
---@param MaxY number
---@return boolean
function LineContainsRect(x, y, x2, y2, MinX, MinY, MaxX, MaxY)
    local leftSide          = GetLineIntersection(x, y, x2, y2, MinX, MinY, MinX, MaxY) ---@type location 
    local rightSide          = GetLineIntersection(x, y, x2, y2, MaxX, MinY, MaxX, MaxY) ---@type location 
    local bottomSide          = GetLineIntersection(x, y, x2, y2, MinX, MinY, MaxX, MinY) ---@type location 
    local topSide          = GetLineIntersection(x, y, x2, y2, MinX, MaxY, MaxX, MaxY) ---@type location 
    local b         = (leftSide ~= nil or rightSide ~= nil or bottomSide ~= nil or topSide ~= nil) ---@type boolean 

    RemoveLocation(leftSide)
    RemoveLocation(rightSide)
    RemoveLocation(bottomSide)
    RemoveLocation(topSide)

    return b
end

---@param u unit
---@return boolean
function InCombat(u)
    local ug       = CreateGroup()
    local u2 ---@type unit 
    local b         = false ---@type boolean 

    GroupEnumUnitsInRange(ug, GetUnitX(u), GetUnitY(u), 900., Condition(ishostile))

    u2 = FirstOfGroup(ug)

    if GetUnitTypeId(u2) ~= 0 then
        b = true
    end

    DestroyGroup(ug)

    return b
end

---@param pid integer
function ToggleAutoAttack(pid)
    if autoAttackDisabled[pid] then
        autoAttackDisabled[pid] = false
        DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 10, "Toggled Auto Attacking on.")
        if Unit[Hero[pid]].canAttack then
            BlzSetUnitWeaponBooleanField(Hero[pid], UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
        end
    else
        autoAttackDisabled[pid] = true
        DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 10, "Toggled Auto Attacking off.")
        BlzSetUnitWeaponBooleanField(Hero[pid], UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
    end
end

function SpawnOrcs()
    local ug       = CreateGroup()

    GroupEnumUnitsOfPlayer(ug, pboss, Filter(isOrc))

    if BlzGroupGetSize(ug) > 0 and BlzGroupGetSize(ug) < 36 and not ChaosMode then
        --bottom side
        IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 12687, -15414, 45), "patrol", 668, -2146)
        IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 12866, -15589, 45), "patrol", 668, -2146)
        IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 12539, -15589, 45), "patrol", 668, -2146)
        IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 12744, -15765, 45), "patrol", 668, -2146)
        --top side
        IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 15048, -12603, 225), "patrol", 668, -2146)
        IssuePointOrder(CreateUnit(pboss, FourCC('o01I'), 15307, -12843, 225), "patrol", 668, -2146)
        IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 15299, -12355, 225), "patrol", 668, -2146)
        IssuePointOrder(CreateUnit(pboss, FourCC('o008'), 15543, -12630, 225), "patrol", 668, -2146)

        if UnitAlive(gg_unit_N01N_0050) then
            UnitAddAbility(gg_unit_N01N_0050, FourCC('Avul'))
        end
    end

    DestroyGroup(ug)
end

function SpawnForgotten()
    if UnitAlive(forgotten_spawner) and forgottenCount < 5 then
        local id         = forgottenTypes[GetRandomInt(0, 4)] ---@type integer 

        forgottenCount = forgottenCount + 1
        CreateUnit(pfoe, id, 13699 + GetRandomInt(-250, 250), -14393 + GetRandomInt(-250, 250), GetRandomInt(0, 359))
    end
end

function EnumDestroyTreesInRange()
    local d              = GetEnumDestructable() ---@type destructable 
    local did         = GetDestructableTypeId(d) ---@type integer 
    local x      = LoadReal(MiscHash, FourCC('tree'), 0) ---@type number 
    local y      = LoadReal(MiscHash, FourCC('tree'), 1) ---@type number 
    local range      = LoadReal(MiscHash, FourCC('tree'), 2) ---@type number 

    if (did == FourCC('ITtw') or did == FourCC('JTtw') or did == FourCC('FTtw') or did == FourCC('NTtw') or did == FourCC('B00B') or did == FourCC('B00H') or did == FourCC('ITtc') or did ==FourCC('NTtc') or did == FourCC('WTst') or did == FourCC('WTtw')) and DistanceCoords(x, y, GetDestructableX(d), GetDestructableY(d)) <= range then
        KillDestructable(d)
    end
end

---@param x number
---@param y number
---@param range number
function DestroyTreesInRange(x, y, range)
    local r      = Rect(x - range, y - range, x + range, y + range) ---@type rect 

    SaveReal(MiscHash, FourCC('tree'), 0, x)
    SaveReal(MiscHash, FourCC('tree'), 1, y)
    SaveReal(MiscHash, FourCC('tree'), 2, range)
    EnumDestructablesInRect(r, nil, EnumDestroyTreesInRange)
    FlushChildHashtable(MiscHash, FourCC('tree'))

    RemoveRect(r)
end

---@param owner player
---@param abil integer
---@param ablev integer
---@param x number
---@param y number
---@param order string
function DummyCast(owner, abil, ablev, x, y, order)
    local u      = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME) ---@type unit 

    SetUnitOwner(u, owner, true)
    IssueImmediateOrder(u, order)
end

---@param owner player
---@param target unit
---@param abil integer
---@param ablev integer
---@param x number
---@param y number
---@param order string
function DummyCastTarget(owner, target, abil, ablev, x, y, order)
    local u      = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME) ---@type unit 

    SetUnitOwner(u, owner, true)
    BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(GetUnitY(target) - y, GetUnitX(target) - x))
    IssueTargetOrder(u, order, target)
end

---@param owner player
---@param x2 number
---@param y2 number
---@param abil integer
---@param ablev integer
---@param x number
---@param y number
---@param order string
function DummyCastPoint(owner, x2, y2, abil, ablev, x, y, order)
    local u      = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME) ---@type unit 

    SetUnitOwner(u, owner, true)
    BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(y2 - y, x2 - x))
    IssuePointOrder(u, order, x2, y2)
end

---@param pid integer
---@param target unit
---@param duration number
function StunUnit(pid, target, duration)
    local stun = Stun:add(Hero[pid], target) ---@class Stun 

    if IsUnitType(target, UNIT_TYPE_HERO) then
        stun:duration(duration * 0.5)
    else
        stun:duration(duration)
    end
end

--highlight
---@param s string
---@param y boolean
---@return string
function HL(s, y)
    if y then
        return ("|cffffcc00" .. s .. "|r")
    else
        return s
    end
end

---@param u unit
---@param id integer
---@param index integer
---@return number
function GetAbilityField(u, id, index)
    return BlzGetAbilityRealLevelField(BlzGetUnitAbility(u, id), SPELL_FIELD[index], 0)
end

---@type fun(itm: Item)
function ItemAddSpellDelayed(itm)
    for index = ITEM_ABILITY, ITEM_ABILITY2 do
        if ItemData[itm.id][index] ~= 0 then --ability exists
            local s = ItemData[itm.id][index * ABILITY_OFFSET .. "abil"]
            local abilid = FourCC(SubString(s, 0, 4))

            BlzItemAddAbility(itm.obj, abilid)

            if abilid == FourCC('Aarm') then --armor aura
                BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_ARMOR_BONUS_HAD1, 0, itm:calcStat(index, 0))
            elseif abilid == FourCC('Abas') then --bash
                BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_CHANCE_TO_BASH, 0, itm:calcStat(index, 0))
                BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_DURATION_NORMAL, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
                BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_DURATION_HERO, 0, ItemData[itm.id][index * ABILITY_OFFSET + 1])
            elseif abilid == FourCC('A018') or abilid == FourCC('A01S') then --blink
                BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), ABILITY_RLF_MAXIMUM_RANGE, 0, itm:calcStat(index, 0))
            else --channel
                BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), SPELL_FIELD[0], 0, itm:calcStat(index, 0))

                for i = 0, SPELL_FIELD_TOTAL do
                    local count = 1
                    local value = ItemData[itm.id][index * ABILITY_OFFSET + count]

                    if value ~= 0 then
                        BlzSetAbilityRealLevelField(BlzGetItemAbility(itm.obj, abilid), SPELL_FIELD[i], 0, value)
                        count = count + 1
                    end
                end
            end

            IncUnitAbilityLevel(itm.holder, abilid)
            DecUnitAbilityLevel(itm.holder, abilid)
        end
    end
end

---@type fun(itm: Item, index: integer, value: integer, lower: integer, upper: integer):string
function ParseItemAbilityTooltip(itm, index, value, lower, upper)
    local s        = ItemData[itm.id][index * ABILITY_OFFSET .. "abil"] ---@type string 
    local id         = ItemData[itm.id][index * ABILITY_OFFSET] ---@type integer 
    local orig        = BlzGetAbilityExtendedTooltip(id, 0) ---@type string 
    local newstring        = "" ---@type string 
    local tag        = "" ---@type string 
    local i         = 5 ---@type integer 
    local i2         = 6 ---@type integer 
    local start         = 5 ---@type integer 
    local end_         = 0 ---@type integer 
    local count         = 1 ---@type integer 
    local values=__jarray(0) ---@type integer[] 

    values[0] = value

    --start at 5 index to ignore ability id
    while not (i2 > StringLength(s) + 1) do

        if SubString(s, i, i2) == " " or i2 > StringLength(s) then
            end_ = i

            values[count] = S2I(SubString(s, start, end_))

            ItemData[itm.id][index * ABILITY_OFFSET + count] = values[count]
            count = count + 1

            start = i2
        end

        i = i + 1
        i2 = i2 + 1
    end

    i = 0
    i2 = 1
    start = 0

    while not (i2 > StringLength(orig) + 1) do

        if SubString(orig, i, i2) == "$" then
            end_ = i
            tag = SubString(orig, i + 1, i2 + 1)

            newstring = newstring .. SubString(orig, start, end_)
            if upper > 0 then
                newstring = newstring .. (lower) .. "-" .. (upper)
            else
                newstring = newstring .. (values[S2I(tag) - 1])
            end

            start = i2 + 1
        end

        i = i + 1
        i2 = i2 + 1
    end

    newstring = newstring .. SubString(orig, start, StringLength(orig))

    if newstring == "" then
        return orig
    else
        return newstring
    end
end

---@param itm item
---@param s string
function ParseItemTooltip(itm, s)
    local orig        = BlzGetItemExtendedTooltip(itm) ---@type string 
    local tag        = "" ---@type string 
    local i         = 0 ---@type integer 
    local i2         = 1 ---@type integer 
    local i3         = 0 ---@type integer 
    local start=__jarray(0) ---@type integer[] 
    local end_=__jarray(0) ---@type integer[] 
    local itemid         = GetItemTypeId(itm) ---@type integer 
    local index         = 0 ---@type integer 
    local count         = 0 ---@type integer 
    local SYNTAX_COUNT         = 7 ---@type integer 

    --debug testing
    if s ~= "" then
        orig = s
    end

    --store original tooltip [id][0]
    ItemData[itemid][ITEM_TOOLTIP] = orig

    while not (i2 > StringLength(orig) + 1) do

        if SubString(orig, i, i2) == "[" then
            i3 = i2

            tag = ""
            start[0] = i2
            start[1] = 0
            start[2] = 0
            start[3] = 0
            start[4] = 0
            start[5] = 0
            start[6] = 0
            start[7] = 0
            end_[0] = i2
            end_[1] = 0
            end_[2] = 0
            end_[3] = 0
            end_[4] = 0
            end_[5] = 0
            end_[6] = 0
            end_[7] = 0
            count = 0

            while StringLength(orig) > i3 do
                i3 = i3 + 1
                end_[0] = end_[0] + 1
                tag = SubString(orig, i3, end_[0] + 1)
                if tag == "*" or tag == " " then
                    index = LoadInteger(SAVE_TABLE, KEY_ITEMS, StringHash(SubString(orig, start[0], end_[0])))
                    --stat is not fixed
                    if tag == "*" then
                        ItemData[itemid][index + BOUNDS_OFFSET * 6] = 1
                    end
                    break
                end
            end

            start[0] = end_[0] + 1

            while StringLength(orig) > i3 do
                i3 = i3 + 1
                end_[0] = end_[0] + 1
                tag = SubString(orig, i3, end_[0] + 1)
                --value range
                if tag == "|" then
                    start[1] = end_[0] + 1
                    end_[count] = i3
                    count = count + 1
                --flat per level
                elseif tag == "=" then
                    start[2] = end_[0] + 1
                    end_[count] = i3
                    count = count + 1
                --flat per rarity
                elseif tag == ">" then
                    start[3] = end_[0] + 1
                    end_[count] = i3
                    count = count + 1
                --percent effectiveness
                elseif tag == "%" then
                    start[4] = end_[0] + 1
                    end_[count] = i3
                    count = count + 1
                --unlock at
                elseif tag == "@" then
                    start[5] = end_[0] + 1
                    end_[count] = i3
                    count = count + 1
                --ability id
                elseif tag == "#" then
                    start[7] = end_[0] + 1
                    end_[count] = i3
                    count = count + 1
                elseif tag == "]" then
                    end_[count] = i3
                    count = count + 1
                    break
                end
            end

            count = 0

            for i4 = 0, SYNTAX_COUNT do
                if start[i4] > 0 then
                    if i4 == 7 then --ability
                        ItemData[itemid][index * ABILITY_OFFSET] = FourCC(SubString(orig, start[i4], start[i4] + 4))
                        ItemData[itemid][index * ABILITY_OFFSET .. "abil"] = SubString(orig, start[i4], end_[count])
                    else
                        ItemData[itemid][index + BOUNDS_OFFSET * i4] = S2I(SubString(orig, start[i4], end_[count]))
                    end
                    count = count + 1
                end
            end
        end

        i = i + 1
        i2 = i2 + 1
    end
end

--parses brackets [] = normal boost {] = low boost \] = no boost > = no color
---@type fun(spell: Spell, orig: string):string
function GetSpellTooltip(spell, orig)
    local calc = {} ---@type number[]

    for i, v in ipairs(spell.values) do
        calc[i] = type(v) == "number" and v or type(v) == "function" and v(spell.pid) or 0
    end

    if #calc > 0 then
        local pattern = "(>?)([\\{%[]+)(.-)%]"
        local count = 0
        orig = orig:gsub(pattern, function(flag, prefix, content)
            local color = flag:len() == 0
            count = count + 1

            if altModifier[spell.pid] then
                if prefix == "[" then
                    return HL(RealToString(calc[count] * (1. + BoostValue[spell.pid] - 0.2)) .. " - " .. RealToString(calc[count] * (1. + BoostValue[spell.pid] + 0.2)), color)
                elseif prefix == "{" then
                    return HL(RealToString(calc[count] * LBOOST[spell.pid]), color)
                elseif prefix == "\\" then
                    return HL(RealToString(calc[count]), color)
                end
            else
                return content
            end
        end)
    end

    return orig
end

---@param u unit
---@param id integer
---@param dur number
---@param anim integer
---@param timescale number
function SpellCast(u, id, dur, anim, timescale)
    Unit[u]:castTime(dur)

    BlzStartUnitAbilityCooldown(u, id, BlzGetUnitAbilityCooldown(u, id, GetUnitAbilityLevel(u, id) - 1))
    DelayAnimation(BOSS_ID, u, dur, 0, 1., true)
    if anim ~= -1 then
        SetUnitTimeScale(u, timescale)
        SetUnitAnimationByIndex(u, anim)
    end
end

---@param pid integer
function UpdateSpellTooltips(pid)
    local i = 0 ---@type integer 
    local abil = BlzGetUnitAbilityByIndex(Hero[pid], i) ---@type ability 

    while abil do
        local sid = BlzGetAbilityId(abil)

        if Spells[sid] and GetUnitAbilityLevel(Hero[pid], sid) > 0 then
            local mySpell = Spells[sid]:create(pid) ---@type Spell
            local tooltip = GetSpellTooltip(mySpell, SpellTooltips[sid][mySpell.ablev])

            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetAbilityExtendedTooltip(sid, tooltip, mySpell.ablev - 1)
                BlzSetAbilityActivatedExtendedTooltip(sid, tooltip, mySpell.ablev - 1)
            end

            mySpell:destroy()
        end

        i = i + 1
        abil = BlzGetUnitAbilityByIndex(Hero[pid], i)
    end

    SetPlayerAbilityAvailable(pfoe, FourCC('Agyv'), true)
    SetPlayerAbilityAvailable(pfoe, FourCC('Agyv'), false)
end

---@param pid integer
---@param loc location
function MoveHeroLoc(pid, loc)
    SetUnitPositionLoc(Hero[pid], loc)
    if IsUnitHidden(HeroGrave[pid]) == false then
        SetUnitPositionLoc(HeroGrave[pid], loc)
    end
end

function AzazothExit()
    local U      = User.first ---@class User 

    while U do

        if IsPlayerInForce(U.player, AZAZOTH_GROUP) then
            ForceRemovePlayer(AZAZOTH_GROUP, U.player)

            MoveHeroLoc(U.id, TownCenter)
            SetCameraBoundsRectForPlayerEx(U.player, gg_rct_Main_Map_Vision)
            PanCameraToTimedLocForPlayer(U.player, TownCenter, 0)
        end

        U = U.next
    end
end

---@param u unit
---@return boolean
function IsCreep(u)
    if GetOwningPlayer(u) ~= pfoe then
        return false
    elseif RectContainsUnit(gg_rct_Town_Boundry, u) then
        return false
    elseif RectContainsUnit(gg_rct_Gods_Vision, u) then
        return false
    elseif IsUnitType(u, UNIT_TYPE_MECHANICAL) == true then
        return false
    elseif IsUnitType(u, UNIT_TYPE_HERO) == true then
        return false
    end

    return true
end

---@param x number
---@param y number
---@return rect | integer
function getRect(x, y)
    local i         = 0 ---@type integer 

    while not (AREAS[i] == nil) do
        if GetRectMinX(AREAS[i]) <= x and x <= GetRectMaxX(AREAS[i]) and GetRectMinY(AREAS[i]) <= y and y <= GetRectMaxY(AREAS[i]) then
            return AREAS[i]
        end
        i = i + 1
    end

    return 0
end

---@param pid integer
function ExperienceControl(pid)
    local HeroLevel         = GetHeroLevel(Hero[pid]) ---@type integer 
    local xpRate      = 0 ---@type number 

    --1 nation, 2 home, 3 grand home, 4 grand nation, 5 lounge, 6 satan home, 7 chaotic nation

    --get multiple of 5 from hero level
    if urhome[pid] > 0 then
        xpRate = BaseExperience[R2I(HeroLevel / 5.) * 5]

        if urhome[pid] == 1 then
            xpRate = xpRate * .6
        elseif urhome[pid] == 2 then
            xpRate = xpRate * 1.0
        elseif urhome[pid] == 3 then
            xpRate = xpRate * 1.1
        elseif urhome[pid] == 4 then
            xpRate = xpRate * .9
        elseif urhome[pid] == 5 then
            xpRate = xpRate * 1.0
        elseif urhome[pid] == 6 then
            xpRate = xpRate * 1.6
        elseif urhome[pid] == 7 then
            xpRate = xpRate * 1.3
        end
    elseif HeroLevel < 15 then
        xpRate = 100
    end

    if urhome[pid] <= 4 and HeroLevel >= 180 then
        xpRate = 0
    end

    if InColo[pid] then
        xpRate = xpRate * Colosseum_XP[pid] * (0.6 + 0.4 * ColoPlayerCount)
    elseif InStruggle[pid] then
        xpRate = xpRate * .3
    end

    XP_Rate[pid] = math.max(0, xpRate * (1. + 0.04 * PrestigeTable[pid][0]) - warriorCount[pid] - rangerCount[pid])
end

---@param Owner player
function Plat_Effect(Owner)
    local i         = 0 ---@type integer 
    local x      = GetUnitX(Hero[GetConvertedPlayerId(Owner)]) ---@type number 
    local y      = GetUnitY(Hero[GetConvertedPlayerId(Owner)]) ---@type number 

    while i <= 40 do
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl" ,x + GetRandomInt(-200,200) ,y + GetRandomInt(-200,200)))
        i = i + 1
    end
end

---@type fun(pid: integer, xp: number)
function AwardXP(pid, xp)
    xp = math.floor(xp)
    SetHeroXP(Hero[pid], GetHeroXP(Hero[pid]) + xp, true)
    ExperienceControl(pid)
    FloatingTextUnit("+" .. (xp) .. " XP", Hero[pid], 2, 80, 0, 10, 204, 0, 204, 0, false)
end

---@type fun(pid: integer, goldawarded:number, displaymessage: boolean)
function AwardGold(pid, goldawarded, displaymessage)
    local p = Player(pid - 1)
    local goldWon ---@type integer 
    local platWon ---@type integer 

    goldWon = math.floor(goldawarded * GetRandomReal(0.9,1.1))
    goldWon = math.floor(goldWon * (1 + (ItemGoldRate[pid] * 0.01)))

    platWon = goldWon // 1000000
    goldWon = goldWon - platWon * 1000000

    AddCurrency(pid, PLATINUM, platWon)
    AddCurrency(pid, GOLD, goldWon)

    if displaymessage then
        if platWon > 0 then
            DisplayTimedTextToPlayer(p, 0, 0, 10, "|c00ebeb15You have gained " .. (goldWon) .. " gold and " .. (platWon) .. " platinum coins.")
            DisplayTimedTextToPlayer(p, 0, 0, 10, PlatTag .. (GetCurrency(pid, PLATINUM)))
        else
            DisplayTimedTextToPlayer(p, 0, 0, 10, "|c00ebeb15You have gained " .. (goldWon) .. " gold.")
        end
    end

    local s = string.format(goldWon)

    if goldWon >= 100000 then
        s = "+" .. (goldWon // 1000) .. "K"
    end

    if platWon > 0 then
        s = "|cffcccccc+" .. platWon .. "|r |cffffcc00" .. s .. "|r"
        FloatingTextUnit(s, killed, 1.5, 75, -100, 9., 255, 255, 255, 0, false)
    else
        FloatingTextUnit(s, killed, 1.5, 75, -100, 8.5, 255, 255, 0, 0, false)
    end
end

---@type fun(s: string, u: unit, dur: number, speed: number, z: number, size: number, r: integer, g: integer, b: integer, alpha: integer, shared: boolean)
function FloatingTextUnit(s, u, dur, speed, z, size, r, g, b, alpha, shared)
    local tt = nil

    if shared then
        tt = CreateTextTag()
    elseif GetLocalPlayer() == GetOwningPlayer(u) then
        tt = CreateTextTag()
    end

    if tt then
        SetTextTagText(tt, s, size * 0.0023)
        SetTextTagPos(tt, GetUnitX(u), GetUnitY(u), z)
        SetTextTagColor(tt, r, g, b, 255 - alpha)
        SetTextTagPermanent(tt, false)
        SetTextTagVelocity(tt, 0, speed / 1803.)
        SetTextTagLifespan(tt, dur)
        SetTextTagFadepoint(tt, dur - .4)
    end
end

---@type fun(s: string, x: number, y: number, dur: number, speed: number, z: number, size: number, r: integer, g: integer, b: integer, alpha: integer)
function DoFloatingTextCoords(s, x, y, dur, speed, z, size, r, g, b, alpha)
    local tt = CreateTextTag()

    SetTextTagText(tt, s, size * 0.0023)
    SetTextTagPos(tt, x, y, z)
    SetTextTagColor(tt, r, g, b, 255 - alpha)
    SetTextTagPermanent(tt, false)
    SetTextTagVelocity(tt, 0, speed / 1803.)
    SetTextTagLifespan(tt, dur)
    SetTextTagFadepoint(tt, dur - .4)
end

---@param id integer
---@param x number
---@param y number
function AwardCrystals(id, x, y)
    local u      = User.first ---@class User 
    local count         = CrystalRewards[id] ---@type integer 

    if count == 0 then
        return
    end

    if HardMode > 0 then
        count = count * 2
    end

    while u do

        if IsUnitInRangeXY(Hero[u.id], x, y, NEARBY_BOSS_RANGE) and GetHeroLevel(Hero[u.id]) >= BossLevel[IsBoss(id)] then
            AddCurrency(u.id, CRYSTAL, count)

            if count == 1 then
                FloatingTextUnit("+" .. (count) .. " Crystal", Hero[u.id], 2.1, 80, 90, 9, 70, 150, 230, 0, false)
            else
                FloatingTextUnit("+" .. (count) .. " Crystals", Hero[u.id], 2.1, 80, 90, 9, 70, 150, 230, 0, false)
            end
        end

        u = u.next
    end
end

---@param u unit
---@param hp number
function HP(u, hp)
    local pid = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 

    hp = hp * (1. + PercentHealBonus[pid] * 0.01)

    --undying rage heal delay
    if UndyingRageBuff:has(u, u) then
        UndyingRageBuff:get(u, u):addRegen(hp)
    else
        SetUnitState(u, UNIT_STATE_LIFE, GetUnitState(u, UNIT_STATE_LIFE) + hp)
        FloatingTextUnit(RealToString(hp), u, 2, 50, 0, 10, 125, 255, 125, 0, true)
    end
end

---@param u unit
---@param hp number
function MP(u, hp)
    --local pid = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 

    SetUnitState(u, UNIT_STATE_MANA, GetUnitState(u, UNIT_STATE_MANA) + hp)
    FloatingTextUnit(RealToString(hp), u, 2, 50, -70, 10, 0, 255, 255, 0, true)
end

---@param b boolean
function PaladinEnrage(b)
    local ug       = CreateGroup()
    local target ---@type unit 

    if b then
        GroupEnumUnitsInRange(ug, GetUnitX(gg_unit_H01T_0259), GetUnitY(gg_unit_H01T_0259), 250., Condition(isplayerunit))

        while true do
            target = FirstOfGroup(ug)
            if target == nil then break end
            GroupRemoveUnit(ug, target)
            UnitDamageTarget(gg_unit_H01T_0259, target, 20000., true, false, ATTACK_TYPE_NORMAL, PHYSICAL, WEAPON_TYPE_WHOKNOWS)
        end

        if GetUnitAbilityLevel(gg_unit_H01T_0259, FourCC('Bblo')) == 0 then
            DummyCastTarget(GetOwningPlayer(gg_unit_H01T_0259), gg_unit_H01T_0259, FourCC('A041'), 1, GetUnitX(gg_unit_H01T_0259), GetUnitY(gg_unit_H01T_0259), "bloodlust")
        end

        BlzSetHeroProperName(gg_unit_H01T_0259, "|cff990000BUZAN THE FEARLESS|r")
        UnitAddBonus(gg_unit_H01T_0259, BONUS_DAMAGE, 5000)
    else
        UnitRemoveAbility(gg_unit_H01T_0259, FourCC('Bblo'))
        BlzSetHeroProperName(gg_unit_H01T_0259, "|c00F8A48BBuzan the Fearless|r")
        UnitAddBonus(gg_unit_H01T_0259, BONUS_DAMAGE, -5000)
    end

    DestroyGroup(ug)
end

---@type fun(pt: PlayerTimer)
function PaladinAggroExpire(pt)
    pt.dur = pt.dur - 0.5

    if pt.dur <= 0 then
        SetPlayerAllianceStateBJ(Player(pt.pid - 1), Player(PLAYER_TOWN), bj_ALLIANCE_ALLIED)
        SetPlayerAllianceStateBJ(Player(PLAYER_TOWN), Player(pt.pid - 1), bj_ALLIANCE_ALLIED)

        pt:destroy()

        if not TimerList[0]:has('pala') then
            PaladinEnrage(false)
        end
    end
end

---@param pid integer
function EnableItems(pid)
    local i         = 0 ---@type integer 

    ItemsDisabled[pid] = false

    while i <= 5 do
        SetItemDroppable(UnitItemInSlot(Hero[pid], i), true)
        SetItemDroppable(UnitItemInSlot(Backpack[pid], i), true)
        i = i + 1
    end
end

---@param pid integer
function DisableItems(pid)
    local i         = 0 ---@type integer 

    ItemsDisabled[pid] = true

    while i <= 5 do
        SetItemDroppable(UnitItemInSlot(Hero[pid], i), false)
        SetItemDroppable(UnitItemInSlot(Backpack[pid], i), false)
        i = i + 1
    end
end

---@param n integer
---@param k integer
---@return integer
function BinomialCoefficient(n, k)
    local i         = 0 ---@type integer 
    local result         = 1 ---@type integer 

    if k > n then
        return 0
    end

    while not (i > k - 1) do
        result = result * (n - i) // (i + 1)

        i = i + 1
    end

    return result
end

---@class BezierCurve
---@field numPoints integer
---@field pointX number[]
---@field pointY number[]
---@field X number
---@field Y number
---@field addPoint function
---@field calcT function
---@field create function
---@field destroy function
BezierCurve = {}
do
    local thistype = BezierCurve
    thistype.numPoints         = 0 ---@type integer 
    thistype.pointX = {} ---@type number[] 
    thistype.pointY = {} ---@type number[] 

    thistype.X      = 0. ---@type number 
    thistype.Y      = 0. ---@type number 

    ---@type fun():BezierCurve
    function thistype.create()
        local self = {}

        setmetatable(self, { __index = BezierCurve })

        return self
    end

    function thistype:destroy()
        self = nil
    end

    ---@param x number
    ---@param y number
    function thistype:addPoint(x, y)
        pointX[numPoints] = x
        pointY[numPoints] = y

        numPoints = numPoints + 1
    end

    ---@param t number
    function thistype:calcT(t)
        local n         = numPoints - 1 ---@type integer 
        local resultX      = 0. ---@type number 
        local resultY      = 0. ---@type number 
        local i         = 0 ---@type integer 
        local blend      = 0. ---@type number 

        while i <= n do
            blend = BinomialCoefficient(n, i) * Pow(t, i) * Pow(1 - t, n - i)
            resultX = resultX + blend * pointX[i]
            resultY = resultY + blend * pointY[i]

            i = i + 1
        end

        X = resultX
        Y = resultY
    end
end

---@type fun(u: unit, sfx: effect)
function Undespawn(u, sfx)
    PauseUnit(u, false)
    UnitRemoveAbility(u, FourCC('Avul'))
    BlzSetSpecialEffectX(sfx, 30000)
    BlzSetSpecialEffectY(sfx, 30000)
    TimerQueue:callDelayed(0., DestroyEffect, sfx)
    ShowUnit(u, true)
    UnitData[u] = nil
end

---@type fun(pt: PlayerTimer)
function ApplyFade(pt)
    local r         = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_RED) ---@type integer 
    local g         = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_BLUE) ---@type integer 
    local b         = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_GREEN) ---@type integer 

    if GetUnitAbilityLevel(pt.target, FourCC('Bmag')) > 0 then --magnetic stance
        r = 255
        g = 25
        b = 25
    end

    pt.int = IMinBJ(255, R2I(pt.int + 7.8 // pt.dur))

    if pt.agi > 0 then
        SetUnitVertexColor(pt.target, r, g, b, 255 - pt.int)
    else
        SetUnitVertexColor(pt.target, r, g, b, pt.int)
    end

    if pt.int >= 255 or not UnitAlive(pt.target) then
        pt:destroy()
    end
end

---@param u unit
---@param dur number
---@param fade boolean
function Fade(u, dur, fade)
    local pid         = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local pt             = TimerList[pid]:add() ---@class PlayerTimer 

    pt.target = u
    if fade then
        pt.agi = 1
    else
        pt.agi = -1
    end
    pt.dur = dur
    pt.int = 0

    pt.timer:callPeriodically(FPS_32, nil, ApplyFade)
end

---@type fun(e: effect, b: boolean)
function FadeSFX(e, b)
    local count = 40 ---@type number

    if not b then
        BlzSetSpecialEffectAlpha(e, 0)
    end

    local applyfade = function()
        count = count - 1

        if b then
            BlzSetSpecialEffectAlpha(e, count * 7)
        else
            BlzSetSpecialEffectAlpha(e, 255 - count * 7)
        end
    end

    TimerQueue:callPeriodically(FPS_32, count <= 0, applyfade)
end

---@type fun(pt: PlayerTimer)
function HideSummonDelay(pt)
    ShowUnit(pt.target, false)

    pt:destroy()
end

---@type fun(pt: PlayerTimer)
function HideSummon(pt)
    SetUnitXBounded(pt.target, 30000)
    SetUnitYBounded(pt.target, 30000)

    pt.timer:callDelayed(1., HideSummonDelay, pt)
end

---@param u unit
function SummonExpire(u)
    local pid         = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local uid         = GetUnitTypeId(u) ---@type integer 
    local pt ---@class PlayerTimer 

    TimerList[pid]:stopAllTimers(u)

    if uid == SUMMON_DESTROYER then
        BorrowedLife[pid * 10] = 0
    elseif uid == SUMMON_DESTROYER then
        BorrowedLife[pid * 10 + 1] = 0
    end

    if IsUnitHidden(u) == false then --important
        if uid == SUMMON_DESTROYER or uid == SUMMON_HOUND or uid == SUMMON_GOLEM then
            UnitRemoveAbility(u, FourCC('BNpa'))
            UnitRemoveAbility(u, FourCC('BNpm'))
            pt = TimerList[pid]:add()
            pt.target = u
            pt.tag = u
            TimerQueue:callDelayed(2., DestroyEffect, AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", u, "origin"))

            pt.timer:callDelayed(2., HideSummon, pt)
        end

        if UnitAlive(u) then
            KillUnit(u)
        end
    end
end

---@type fun(pt: PlayerTimer)
function SummonDurationXPBar(pt)
    local lev         = GetHeroLevel(pt.target) ---@type integer 

    --call DEBUGMSG(RealToString(pt.dur))

    if GetUnitTypeId(pt.target) == SUMMON_GOLEM and BorrowedLife[pt.pid * 10] > 0 then
        BorrowedLife[pt.pid * 10] = BorrowedLife[pt.pid * 10] - 0.5
    elseif GetUnitTypeId(pt.target) == SUMMON_DESTROYER and BorrowedLife[pt.pid * 10 + 1] > 0 then
        BorrowedLife[pt.pid * 10 + 1] = BorrowedLife[pt.pid * 10 + 1] - 0.5
    else
        pt.dur = pt.dur - 0.5
    end

    if pt.dur <= 0 then
        SummonExpire(pt.target)
    else
        UnitStripHeroLevel(pt.target, 1)
        SetHeroXP(pt.target, R2I(RequiredXP(lev - 1) + ((lev + 1) * pt.dur * 100 / pt.armor) - 1), false)
    end
end

---@param p player
function CleanupSummons(p)
    local pid         = GetPlayerId(p) + 1 ---@type integer 
    local target ---@type unit 
    local index         = 0 ---@type integer 
    local count         = BlzGroupGetSize(SummonGroup) ---@type integer 

    repeat
        target = BlzGroupUnitAt(SummonGroup, index)
        if GetOwningPlayer(target) == p then
            SummonExpire(target)
        end
        index = index + 1
    until index >= count
end

---@param pid integer
function RecallSummons(pid)
    local target ---@type unit 
    local p        = Player(pid - 1) ---@type player 
    local x      = GetUnitX(Hero[pid]) + 200 * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pid])) ---@type number 
    local y      = GetUnitY(Hero[pid]) + 200 * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pid])) ---@type number 
    local count         = BlzGroupGetSize(SummonGroup) ---@type integer 

    for index = 0, count - 1 do
        target = BlzGroupUnitAt(SummonGroup, index)
        if GetOwningPlayer(target) == p and (GetUnitTypeId(target) == SUMMON_HOUND or GetUnitTypeId(target) == SUMMON_GOLEM or GetUnitTypeId(target) == SUMMON_DESTROYER) and IsUnitHidden(target) == false then
            SetUnitPosition(target, x, y)
            SetUnitPathing(target, false)
            SetUnitPathing(target, true)
            BlzSetUnitFacingEx(target, GetUnitFacing(Hero[pid]))
        end
    end
end

---@param u unit
function reselect(u)
    if (GetLocalPlayer() == GetOwningPlayer(u)) then
        ClearSelection()
        SelectUnit(u, true)
    end
end

---@return boolean
function FilterHound()
    if UnitAlive(GetFilterUnit()) and GetUnitTypeId(GetFilterUnit()) == SUMMON_HOUND then
        if GetOwningPlayer(GetFilterUnit()) == Player(passedValue[callbackCount] - 1) then
            return true
        end
    end

    return false
end

---@return boolean
function FilterEnemyDead()
    if GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Aloc')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == false then
            return true
        end
    end

    return false
end

---@type fun():boolean
function FilterEnemy()
    local u = GetFilterUnit()

    if UnitAlive(u) and
        IsUnitEnemy(u, Player(passedValue[callbackCount] - 1)) and
        GetUnitAbilityLevel(u, FourCC('Avul')) == 0 and
        GetUnitAbilityLevel(u, FourCC('Aloc')) == 0 and
        GetUnitTypeId(u) ~= DUMMY then
        return true
    end

    return false
end

---@return boolean
function FilterAllyHero()
    local u = GetFilterUnit()

    if UnitAlive(u) and
        IsUnitAlly(u, Player(passedValue[callbackCount] - 1)) == true and
        IsUnitType(u, UNIT_TYPE_HERO) == true and
        GetUnitAbilityLevel(u, FourCC('Avul')) == 0 and
        GetUnitAbilityLevel(u, FourCC('Aloc')) == 0 and
        GetUnitTypeId(u) ~= DUMMY then
        return true
    end

    return false
end

---@return boolean
function FilterAlly()
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Aloc')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == true then
            return true
        end
    end

    return false
end

---@return boolean
function FilterEnemyAwake()
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Aloc')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[callbackCount] - 1)) == false and UnitIsSleeping(GetFilterUnit()) == false then
            return true
        end
    end

    return false
end

---@return boolean
function FilterNotIllusion()
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Aloc')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY then
        if IsUnitIllusion(GetFilterUnit()) == false then
            return true
        end
    end

    return false
end

---@return boolean
function FilterAlive()
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Aloc')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY then
        return true
    end

    return false
end

---@param uid integer
---@param count integer
function SpawnColoUnits(uid, count)
    local i ---@type integer 
    local u ---@type unit 
    local rand         = 0 ---@type integer 

    count = count * IMinBJ(2, ColoPlayerCount)

    while count >= 1 do

        rand = GetRandomInt(1,3)
        u = CreateUnit(pboss, uid, GetRectCenterX(gg_rct_Colloseum_Player_Spawn), GetRectCenterY(gg_rct_Colloseum_Player_Spawn), 270)
        SetUnitXBounded(u, GetLocationX(colospot[rand]))
        SetUnitYBounded(u, GetLocationY(colospot[rand]))
        BlzSetUnitMaxHP(u, R2I(BlzGetUnitMaxHP(u) * (0.5 + 0.5 * ColoPlayerCount)))
        UnitAddBonus(u, BONUS_DAMAGE, R2I(BlzGetUnitBaseDamage(u, 0) * (-0.5 + 0.5 * ColoPlayerCount)))
        SetWidgetLife(u, BlzGetUnitMaxHP(u))
        SetUnitCreepGuard(u, false)
        SetUnitAcquireRange(u, 2500.)
        GroupAddUnit(ColoWaveGroup, u)
        Colosseum_Monster_Amount = Colosseum_Monster_Amount + 1

        count = count - 1
    end
end

function AdvanceColo()
    local ug       = CreateGroup()
    local looptotal ---@type integer 
    local u ---@type unit 
    local U      = User.first ---@class User 

    while U do
            if Fleeing[U.id] and InColo[U.id] then
                Fleeing[U.id] = false
                InColo[U.id] = false
                ColoPlayerCount = ColoPlayerCount - 1
                EnableItems(U.id)
                AwardGold(U.id, GoldWon_Colo, true)
                MoveHeroLoc(U.id, TownCenter)
                SetCameraBoundsRectForPlayerEx(U.player, gg_rct_Main_Map_Vision)
                PanCameraToTimedLocForPlayer(U.player, TownCenter, 0)
                DisplayTextToPlayer(U.player, 0, 0, "You escaped the Colosseum successfully.")
                Colosseum_XP[U.id] = (Colosseum_XP[U.id] - 0.05)
                ExperienceControl(U.id)
                RecallSummons(U.id)
            end
        U = U.next
    end

    if ColoPlayerCount == 0 then
        ClearColo()
    else
        Wave = Wave + 1
        if ColoCount_main[Wave] > 0 and Colosseum_Monster_Amount <= 0 then
            looptotal= ColoCount_main[Wave]
            SpawnColoUnits(ColoEnemyType_main[Wave],looptotal)
            if ColoCount_sec[Wave] > 0 then
                looptotal= ColoCount_sec[Wave]
                SpawnColoUnits(ColoEnemyType_sec[Wave],looptotal)
            end
            ColoWaveCount = ColoWaveCount + 1
            DoFloatingTextCoords("Wave " .. (ColoWaveCount), GetLocationX(ColosseumCenter), GetLocationY(ColosseumCenter), 3.20, 32.0, 0, 18.0, 255, 0, 0, 0)
        elseif ColoCount_main[Wave] <= 0 then
            U = User.first ---@class User

            GoldWon_Colo= R2I(GoldWon_Colo * 1.2)

            while U do
                if InColo[U.id] then
                    InColo[U.id] = false
                    ColoPlayerCount = ColoPlayerCount - 1
                    DisplayTimedTextToPlayer(U.player,0,0, 10, "You have successfully cleared the Colosseum and received a 20% gold bonus.")
                    EnableItems(U.id)

                    AwardGold(U.id, GoldWon_Colo, true)
                    MoveHeroLoc(U.id, TownCenter)
                    SetCameraBoundsRectForPlayerEx(U.player, gg_rct_Main_Map_Vision)
                    PanCameraToTimedLocForPlayer(U.player, TownCenter, 0)
                    RecallSummons(U.id)
                    ExperienceControl(U.id)
                end
                U = U.next
            end

            ClearColo()

            SetTextTagText(ColoText, "Colosseum", 10 * 0.023 / 10)
        end
    end

    DestroyGroup(ug)
end

---@param t number
---@param p0 number
---@param p1 number
---@param p2 number
---@param p3 number
---@return number
function CubicInterpolation(t, p0, p1, p2, p3)
    local t2      = t * t ---@type number 
    local a0      = p3 - p2 - p0 + p1 ---@type number 
    local a1      = p0 - p1 - a0 ---@type number 
    local a2      = p2 - p0 ---@type number 
    local a3      = p1 ---@type number 

    return a0 * t * t2 + a1 * t2 + a2 * t + a3
end

---@type fun(f: force, fadein: number, fadeout: number)
function BlackMask(f, fadein, fadeout)

    ---@type fun(fadedur: number, fade: boolean)
    local applyblackmask = function(fadedur, fade)
        local U = User.first ---@class User

        while U do
            if IsPlayerInForce(U.player, f) then
                if GetLocalPlayer() == U.player then
                    SetCineFilterTexture("ReplaceableTextures\\CameraMasks\\Black_mask.blp")
                    if fade then
                        SetCineFilterStartColor(0,0,0,0)
                        SetCineFilterEndColor(0,0,0,255)
                    else
                        SetCineFilterStartColor(0,0,0,255)
                        SetCineFilterEndColor(0,0,0,0)
                    end
                    SetCineFilterDuration(fadedur)
                    DisplayCineFilter(true)
                end
            end

            U = U.next
        end
    end

    applyblackmask(fadein, true)
    TimerQueue:callDelayed(fadein, applyblackmask, fadeout, false)
end

---@param f force
---@param x number
---@param y number
---@param cam rect
function MoveForce(f, x, y, cam)
    local U      = User.first ---@class User 
    local pid ---@type integer 

    while U do
        pid = GetPlayerId(U.player) + 1
        if IsPlayerInForce(U.player, f) then
            SetUnitPosition(Hero[pid], x, y)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Hero[pid], "origin"))
            SetCameraBoundsRectForPlayerEx(U.player, cam)
            PanCameraToTimedForPlayer(U.player, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
        end
        U = U.next
    end
end

---@type fun(flag: integer)
function AdvanceStruggle(flag)
    local ug       = CreateGroup()
    local u ---@type unit 
    local U      = User.first ---@class User 

    if flag == 1 then
        TimerQueue:callDelayed(3., SpawnStruggleUnits)
    end

    while U do
        if Fleeing[U.id] and InStruggle[U.id] then
            Fleeing[U.id] = false
            InStruggle[U.id] = false
            Struggle_Pcount = Struggle_Pcount - 1
            EnableItems(U.id)
            MoveHeroLoc(U.id, TownCenter)
            SetCameraBoundsRectForPlayerEx(U.player, gg_rct_Main_Map_Vision)
            PanCameraToTimedLocForPlayer(U.player, TownCenter, 0)
            ExperienceControl(U.id)
            DisplayTextToPlayer(U.player, 0, 0, "You escaped Struggle with your life.")
            AwardGold(U.id, GoldWon_Struggle, true)
            RecallSummons(U.id)
            GroupEnumUnitsInRect(ug, gg_rct_Infinite_Struggle, Condition(FilterNotHero))
            while true do
                u = FirstOfGroup(ug)
                if u == nil then break end
                GroupRemoveUnit(ug, u)
                if GetOwningPlayer(u) == U.player then
                    RemoveUnit(u)
                end
            end
        end
        U = U.next
    end

    Struggle_WaveN = Struggle_WaveN + 1
    Struggle_WaveUCN = Struggle_WaveUN[Struggle_WaveN]
    if Struggle_Pcount == 0 then
        ClearStruggle()
    else
        if Struggle_WaveU[Struggle_WaveN] <= 0 then -- Struggle Won
            GoldWon_Struggle= R2I(GoldWon_Struggle * 1.5)
            SetTextTagTextBJ(StruggleText, ("Gold won: " .. (GoldWon_Struggle)), 10.00)

            U = User.first ---@class User

            while U do
                if InStruggle[U.id] then
                    InStruggle[U.id] = false
                    Struggle_Pcount = Struggle_Pcount - 1
                    DisplayTextToPlayer(U.player, 0, 0, "50% bonus gold for victory!")
                    MoveHeroLoc(U.id, TownCenter)
                    EnableItems(U.id)
                    SetUnitPositionLoc(Backpack[U.id], TownCenter)
                    SetCameraBoundsRectForPlayerEx(U.player, gg_rct_Main_Map_Vision)
                    PanCameraToTimedLocForPlayer(U.player, TownCenter, 0)
                    if Struggle_WaveN < 40 then
                        DisplayTextToPlayer(U.player,0,0, "You received a lesser ring of struggle for completing struggle.")
                        PlayerAddItemById(U.id, FourCC('I00T'))
                    else
                        DisplayTextToPlayer(U.player,0,0, "You received a ring of struggle for completing chaotic struggle.")
                        PlayerAddItemById(U.id, FourCC('I0D0'))
                    end
                    AwardGold(U.id,GoldWon_Struggle,true)
                    ExperienceControl(U.id)
                    RecallSummons(U.id)
                    U = U.next
                end
            end

            ClearStruggle()
        else
            if Struggle_WaveN > 40 then
                DoFloatingTextCoords("Wave " .. (Struggle_WaveN - 40), GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), 3.80, 32.0, 0, 18.0, 255, 0, 0, 0)
            else
                DoFloatingTextCoords("Wave " .. (Struggle_WaveN), GetRectCenterX(gg_rct_Infinite_Struggle), GetRectCenterY(gg_rct_Infinite_Struggle), 3.80, 32.0, 0, 18.0, 255, 0, 0, 0)
            end
        end
    end

    DestroyGroup(ug)
end

---@param itid1 integer
---@param req1 integer
---@param itid2 integer
---@param req2 integer
---@param itid3 integer
---@param req3 integer
---@param itid4 integer
---@param req4 integer
---@param itid5 integer
---@param req5 integer
---@param itid6 integer
---@param req6 integer
---@param FINAL_ID integer
---@param FINAL_CHARGES integer
---@param creatingunit unit
---@param platCost number
---@param arcCost number
---@param crystals integer
---@param hidemessage boolean
---@return boolean
function Recipe(itid1, req1, itid2, req2, itid3, req3, itid4, req4, itid5, req5,itid6, req6, FINAL_ID, FINAL_CHARGES, creatingunit, platCost, arcCost, crystals, hidemessage)
    local i         = 0 ---@type integer 
    local i2         = 0 ---@type integer 
    local itemsNeeded=__jarray(0) ---@type integer[] 
    local itemsHeld=__jarray(0) ---@type integer[] 
    local itemType=__jarray(0) ---@type integer[] 
    local owner        = GetOwningPlayer(creatingunit) ---@type player 
    local pid         = GetPlayerId(owner) + 1 ---@type integer 
    local fail         = false ---@type boolean 
    local levelreq         = 0 ---@type integer 
    local cost ---@type integer 
    local success         = false ---@type boolean 
    local itm ---@type item 
    local origcount=__jarray(0) ---@type integer[]  
    local origowner         = 0 ---@type integer
    local goldcost         = R2I(ModuloReal(platCost, R2I(math.max(platCost, 1))) * 1000000) ---@type integer 
    local lumbercost         = R2I(ModuloReal(arcCost, R2I(math.max(arcCost, 1))) * 1000000) ---@type integer 

    itemType[0] = itid1
    itemType[1] = itid2
    itemType[2] = itid3
    itemType[3] = itid4
    itemType[4] = itid5
    itemType[5] = itid6
    itemsNeeded[0] = req1
    itemsNeeded[1] = req2
    itemsNeeded[2] = req3
    itemsNeeded[3] = req4
    itemsNeeded[4] = req5
    itemsNeeded[5] = req6

    while i <= 5 do
        i2 = 0
        while i2 <= 5 do
            if creatingunit == ASHEN_VAT then --vat
                itm = UnitItemInSlot(creatingunit, i2)
                if GetItemTypeId(itm) == FourCC('I04Q') then --demon golem fist heart
                    if HeartBlood[itm] < 2000 then
                        itemsHeld[i] = itemsHeld[i] - 1
                    end
                end
                if GetItemTypeId(itm) == itemType[i] then
                    origcount[itm] = origcount[itm] + 1
                    if GetItemCharges(itm) > 1 then
                        itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        itemsHeld[i] = itemsHeld[i] + 1
                    end
                end
            else
                itm = UnitItemInSlot(Hero[pid], i2)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        itemsHeld[i] = itemsHeld[i] + 1
                    end
                end
                itm = UnitItemInSlot(Backpack[pid], i2)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        itemsHeld[i] = itemsHeld[i] + 1
                    end
                end
            end

            i2 = i2 + 1
        end
        i = i + 1
    end

    i = 0

    while i <= 5 do
        if itemsHeld[i] < itemsNeeded[i] then
            fail = true
            break
        end
        i = i + 1
    end

    i = 1

    while true do --disallow multiple bound items
        if i > 6 then break end
        if origcount[i] > 0 then
            if origowner > 0 and origowner ~= i then
                origowner = -1
                fail = true
                break
            end
            origowner = i
        end
        i = i + 1
    end

    if hidemessage then --mostly for ashen vat
        if fail then
            if origowner == -1 then
                DisplayTextToForce(FORCE_PLAYING, "The Ashen Vat will not accept bound items from multiple players.")
            end
        else
            success = true
            i = 0
            while i <= 5 do
                i2 = 0
                if itemType[i] > 0 then
                    while true do
                        i2 = i2 + 1
                        if i2 > itemsNeeded[i] then break end
                        if creatingunit == ASHEN_VAT then
                            if HasItemType(creatingunit, itemType[i]) then
                                Item[GetItemFromUnit(creatingunit, itemType[i])]:useInRecipe()
                            end
                        else
                            if PlayerHasItemType(pid, itemType[i]) then
                                GetItemFromPlayer(pid, itemType[i]):useInRecipe()
                            end
                        end
                    end
                end
                i = i + 1
            end

            if FINAL_ID ~= 0 then
                local FINAL_ITEM = Item.create(CreateItem(FINAL_ID, 30000., 30000.))
                FINAL_ITEM:charge(FINAL_CHARGES)

                FINAL_ITEM.owner = Player(origowner - 1)
                UnitAddItem(creatingunit, FINAL_ITEM.obj)
            end
        end
    else
        levelreq = ItemData[FINAL_ID][ITEM_LEVEL_REQUIREMENT]

        if levelreq > GetUnitLevel(Hero[pid]) then
            DisplayTimedTextToPlayer(owner,0,0, 15., "This item requires at least level |cffFF5555" .. (levelreq) .. "|r to use.")
        elseif GetCurrency(pid, GOLD) < goldcost then
            DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough gold.")
        elseif GetCurrency(pid, LUMBER) < lumbercost then
            DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough lumber.")
        elseif GetCurrency(pid, PLATINUM) < platCost then
            DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough platinum.")
        elseif GetCurrency(pid, ARCADITE) < arcCost then
            DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough arcadite.")
        elseif GetCurrency(pid, CRYSTAL) < crystals then
            DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have enough crystals.")
        elseif fail then
            DisplayTimedTextToPlayer(owner,0,0, 30, "You do not have the required items.")
        else
            DisplayTimedTextToPlayer(owner,0,0, 30, "|cff00cc00Success!|r")
            success = true
            i = 0
            while i <= 5 do
                i2 = 0
                if itemType[i] > 0 then
                    while true do
                        i2 = i2 + 1
                        if i2 > itemsNeeded[i] then break end
                        if PlayerHasItemType(pid, itemType[i]) then
                            GetItemFromPlayer(pid, itemType[i]):useInRecipe()
                        end
                    end
                end
                i = i + 1
            end

            if FINAL_ID ~= 0 then
                local final = PlayerAddItemById(pid, FINAL_ID) ---@class Item
                final:charge(FINAL_CHARGES)

                AddCurrency(pid, GOLD, -goldcost)
                AddCurrency(pid, LUMBER, -lumbercost)
                AddCurrency(pid, PLATINUM, -R2I(platCost))
                AddCurrency(pid, ARCADITE, -R2I(arcCost))
                AddCurrency(pid, CRYSTAL, -crystals)
            end
        end
    end

    return success
end

---@param pid integer
---@param rank integer
---@param id integer
function AllocatePrestige(pid, rank, id)
    local i         = PrestigeTable[pid][id] ---@type integer 

    PrestigeTable[pid][id] = IMinBJ(2, rank + i)
    PrestigeTable[pid][0] = PrestigeTable[pid][0] + IMinBJ(2, rank + i)
end

---@param pid integer
function SetPrestigeEffects(pid)
    local name         = User[Player(pid - 1)].name
    local i         = PUBLIC_SKINS + 2 ---@type integer 
    local j         = 1 ---@type integer 
    local count         = 0 ---@type integer 
    local PT = PrestigeTable

    PercentHealBonus[pid] = 8 * (PT[pid][7] + PT[pid][10])

    --unlock backpack skins
    --dmg
    if B2I(PT[pid][3] > 0) + B2I(PT[pid][5] > 0) + B2I(PT[pid][12] > 0) > 0 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][3] > 0) + B2I(PT[pid][5] > 0) + B2I(PT[pid][12] > 0) > 1 then CosmeticTable[name][i] = 1 end
    i = i + 1
    --str
    if B2I(PT[pid][9] > 0) + B2I(PT[pid][15] > 0) + B2I(PT[pid][18] > 0) > 0 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][9] > 0) + B2I(PT[pid][15] > 0) + B2I(PT[pid][18] > 0) > 1 then CosmeticTable[name][i] = 1 end
    i = i + 1
    --agi
    if B2I(PT[pid][2] > 0) + B2I(PT[pid][8] > 0) + B2I(PT[pid][21] > 0) > 0 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][2] > 0) + B2I(PT[pid][8] > 0) + B2I(PT[pid][21] > 0) > 1 then CosmeticTable[name][i] = 1 end
    i = i + 1
    --int
    if B2I(PT[pid][4] > 0) + B2I(PT[pid][13] > 0) + B2I(PT[pid][14] > 0) > 0 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][4] > 0) + B2I(PT[pid][13] > 0) + B2I(PT[pid][14] > 0) > 1 then CosmeticTable[name][i] = 1 end
    i = i + 1
    --dmg red
    if B2I(PT[pid][11] > 0) + B2I(PT[pid][16] > 0) > 0 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][11] > 0) + B2I(PT[pid][16] > 0) > 1 then CosmeticTable[name][i] = 1 end
    i = i + 1
    --spellboost
    if B2I(PT[pid][1] > 0) + B2I(PT[pid][6] > 0) + B2I(PT[pid][17] > 0) > 0 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][1] > 0) + B2I(PT[pid][6] > 0) + B2I(PT[pid][17] > 0) > 1 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][1] > 0) + B2I(PT[pid][6] > 0) + B2I(PT[pid][17] > 0) > 2 then CosmeticTable[name][i] = 1 end
    i = i + 1
    --regen
    if B2I(PT[pid][7] > 0) + B2I(PT[pid][10] > 0) > 0 then CosmeticTable[name][i] = 1 end
    i = i + 1
    if B2I(PT[pid][7] > 0) + B2I(PT[pid][10] > 0) > 1 then CosmeticTable[name][i] = 1 end
    i = i + 1
    --prestige
    while not (j > HERO_TOTAL + 10) do

        if PrestigeTable[pid][j] > 0 then
            count = count + 1
        end

        j = j + 1
    end
    if count >= 10 then
        CosmeticTable[name][i] = 1
    end
    i = i + 1
    if count >= HERO_TOTAL then
        CosmeticTable[name][i] = 1
    end
end

function ResetVote()
    local i         = 1 ---@type integer 

    VoteYay = 0
    VoteNay = 0

    while i <= 8 do
        I_VOTED[i] = false
        i = i + 1
    end
end

function Votekick()
    local U      = User.first ---@class User 

    ResetVote()
    VOTING_TYPE = 2
    VoteYay = 1
    VoteNay = 1
    DisplayTimedTextToForce(FORCE_PLAYING, 30, "Voting to kick player " + User[votekickPlayer - 1].nameColored .. " has begun.")
    BlzFrameSetTexture(votingBG, "war3mapImported\\afkUI_3.dds", 0, true)

    while U do

        if U.id ~= votekickPlayer and U.id ~= votekickingPlayer then
            if GetLocalPlayer() == U.player then
                BlzFrameSetVisible(votingBG, true)
            end
        end

        U = U.next
    end
end

---@return boolean
function VotekickPanelClick()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw              = DialogWindow[pid] ---@class DialogWindow 
    local index         = dw:getClickedIndex(GetClickedButton()) ---@type integer 

    if index ~= -1 then
        if VOTING_TYPE == 0 then
            votekickPlayer = dw.data[index]
            votekickingPlayer = pid
            Votekick()
        end

        dw:destroy()
    end

    return false
end

---@param pid integer
function UpdateItemTooltips(pid)
    local s        = "" ---@type string 
    local s2        = "" ---@type string 
    local itm ---@class Item 

    --heart of the demon prince
    if HasItemType(Hero[pid], FourCC('I04Q')) then
        itm = Item[GetItemFromUnit(Hero[pid], FourCC('I04Q'))]

        if HeartBlood[pid] >= 2000 then
            s = "|c0000ff40"
        end

        s2 = "\n|cffff5050Chaotic Quest|r\n|c00ff0000Level Requirement: |r190\n|cff0099ffBlood Accumulated:|r (" .. s .. (IMinBJ(2000, HeartBlood[pid])) .. "/2000|r)\n\n|cff808080Deal or take damage to fill the heart with blood (Level 170+ enemies).\n|cffff0000WARNING! This item does not save!"

        itm.tooltip = s2
        itm.alt_tooltip = s2

        BlzSetItemDescription(itm.obj, itm.tooltip)
        BlzSetItemExtendedTooltip(itm.obj, itm.tooltip)
    end
end

function UpdatePrestigeTooltips()
    local s=__jarray("") ---@type string[] 
    local i ---@type integer 
    local unlocked ---@type integer 
    local u      = User.first ---@class User 
    local i2         = PUBLIC_SKINS + 2 ---@type integer 

    --prestige skins

    while u do
        i = GetPlayerId(u.player) + 1
        unlocked = 0

        while i2 <= TOTAL_SKINS do
            if CosmeticTable[u.name][i2] > 0 then
                unlocked = unlocked + 1
            end
            i2 = i2 + 1
        end

        if unlocked >= 17 then
            s[i] = "Change your backpack's appearance.\n\nUnlocked skins: |c0000ff4017/17"
        else
            s[i] = "Change your backpack's appearance.\n\nUnlocked skins: " .. (unlocked) .. "/17"
        end
        u = u.next
    end

    BlzSetAbilityExtendedTooltip(FourCC('A0KX'), s[GetPlayerId(GetLocalPlayer()) + 1], 0)
end

---@param p player
function ActivatePrestige(p)
    local i         = 0 ---@type integer 
    local counter         = 0 ---@type integer 
    local pid         = GetPlayerId(p) + 1 ---@type integer 
    local currentSlot         = Profile[pid].currentSlot ---@type integer 
    local itm={} ---@type item[] 

    if Profile[pid].hero.prestige > 0 then
        DisplayTimedTextToPlayer(p,0,0, 20.00, "You can not prestige this character again.")
    else
        Item[GetItemFromUnit(Hero[pid], FourCC('I0NN'))]:destroy()
        Profile[pid].hero.prestige = 1 + Profile[pid].hero.hardcore
        Profile[pid]:saveCharacter()

        AllocatePrestige(pid, Profile[pid].hero.prestige, Profile[pid].hero.id)

        DisplayTimedTextToForce(FORCE_PLAYING, 30.00, User[pid - 1].nameColored .. " has prestiged their hero and achieved rank |cffffcc00" .. (PrestigeTable[pid][0]) .. "|r prestige!")
        DisplayTimedTextToPlayer(p,0,0, 20.00, "|cffffcc00Hero Prestige:|r " .. (Profile[pid].hero.prestige))
        UpdatePrestigeTooltips()

        while i <= 5 do
            Item[UnitItemInSlot(Hero[pid], i)]:unequip()

            i = i + 1
        end

        SetPrestigeEffects(pid)

        i = 0
        while i <= 5 do
            Item[UnitItemInSlot(Hero[pid], i)]:equip()

            i = i + 1
        end
    end
end

---@type fun(u: unit)
function SwitchAggro(u)
    local target = GetUnitTarget(u) ---@type unit 

    IssueTargetOrder(u, "smart", target)
    Threat[u] = __jarray(0)
    Threat[u][UNIT_TARGET] = target
end

---@type fun(hero: unit, pid: integer, aoe: number, bossaggro: boolean, allythreat: integer, herothreat: integer)
function Taunt(hero, pid, aoe, bossaggro, allythreat, herothreat)
    local enemyGroup       = CreateGroup()
    local allyGroup       = CreateGroup()
    local p        = GetOwningPlayer(hero) ---@type player 

    MakeGroupInRange(pid, enemyGroup, GetUnitX(hero), GetUnitY(hero), aoe, Condition(FilterEnemy))
    MakeGroupInRange(pid, allyGroup, GetUnitX(hero), GetUnitY(hero), aoe, Condition(FilterAlly))

    local count = BlzGroupGetSize(enemyGroup)
    local count2 = BlzGroupGetSize(allyGroup)

    if count > 0 then
        for index = 0, count - 1 do
            local target = BlzGroupUnitAt(enemyGroup, index)

            local threat = Threat[target][hero]
            Threat[target][hero] = IMaxBJ(0, threat + herothreat)
            if IsBoss(target) ~= -1 then
                if bossaggro then
                    IssueTargetOrder(target, "smart", hero)
                    Threat[target][UNIT_TARGET] = hero
                end
                --threat cap reached
                if threat >= THREAT_CAP then
                    if Threat[target][UNIT_TARGET] == hero then
                        Threat[target] = __jarray(0)
                    --switch target
                    else
                        local dummy = GetDummy(GetUnitX(target), GetUnitY(target), 0, 0, 1.5)
                        BlzSetUnitSkin(dummy, FourCC('h00N'))
                        if GetLocalPlayer() == p then
                            BlzSetUnitSkin(dummy, FourCC('h01O'))
                        end
                        SetUnitScale(dummy, 2.5, 2.5, 2.5)
                        SetUnitFlyHeight(dummy, 250.00, 0.)
                        SetUnitAnimation(dummy, "birth")
                        TimerQueue:callDelayed(1.5, SwitchAggro, target)
                    end
                    Threat[target][UNIT_TARGET] = hero
                --lower everyone else's threat 
                else
                    for index2 = 0, count2 - 1 do
                        local target2 = BlzGroupUnitAt(allyGroup, index2)
                        if target2 ~= hero then
                            Threat[target][target2] = IMaxBJ(0, Threat[target][target2] - allythreat)
                        end
                    end
                end
            --so that cast aggro doesnt taunt normal enemies
            elseif allythreat > 0 then
                IssueTargetOrder(target, "smart", hero)
                Threat[target][UNIT_TARGET] = hero
            end
        end
    end

    DestroyGroup(enemyGroup)
    DestroyGroup(allyGroup)
end

---@return boolean
local function ProximityFilter()
    return (GetUnitTypeId(GetFilterUnit()) ~= DUMMY and GetUnitAbilityLevel(GetFilterUnit(), FourCC('Avul')) == 0 and GetPlayerId(GetOwningPlayer(GetFilterUnit())) < PLAYER_CAP)
end

---@type fun(source: unit, target: unit, dist: number):unit
function AcquireProximity(source, target, dist)
    local count         = 0 ---@type integer 
    local ug       = CreateGroup()
    local x      = GetUnitX(source) ---@type number 
    local y      = GetUnitY(source) ---@type number 
    local i         = 0 ---@type integer 
    local orig      = target ---@type unit 

    GroupEnumUnitsInRange(ug, x, y, dist, Filter(ProximityFilter))
    count = BlzGroupGetSize(ug)
    if count > 0 then
        for index = 0, count - 1 do
            target = BlzGroupUnitAt(ug, index)
            --dont acquire the same target
            if SquareRoot(Pow(x - GetUnitX(target), 2) + Pow(y - GetUnitY(target), 2)) < dist and Threat[source][UNIT_TARGET] ~= orig then
                dist = SquareRoot(Pow(x - GetUnitX(target), 2) + Pow(y - GetUnitY(target), 2))
                i = index
            end
        end
        target = BlzGroupUnitAt(ug, i)
        DestroyGroup(ug)
        return target
    end

    DestroyGroup(ug)
    return target
end

---@type fun(pt: PlayerTimer)
function RunDropAggro(pt)
    local ug = CreateGroup()

    MakeGroupInRange(pt.pid, ug, GetUnitX(pt.target), GetUnitY(pt.target), 800., Condition(FilterEnemy))

    local target = FirstOfGroup(ug)
    local target2
    while target do
        GroupRemoveUnit(ug, target)
        if GetUnitTarget(target) == pt.target then
            target2 = AcquireProximity(target, pt.target, 800.)
            IssueTargetOrder(target, "smart", target2)
            Threat[target][UNIT_TARGET] = target2
            --call DEBUGMSG("aggro to " + GetUnitName(target2))
        end
        target = FirstOfGroup(ug)
    end

    pt:destroy()

    DestroyGroup(ug)
end

function KillEverythingLol()
    local ug       = CreateGroup()
    local u ---@type unit 

    GroupEnumUnitsInRect(ug, bj_mapInitialPlayableArea, nil)

    while true do
        u = FirstOfGroup(ug)
        if u == nil then break end
        GroupRemoveUnit(ug, u)
        KillUnit(u)
    end

    DestroyGroup(ug)
end

---@param pid integer
---@param x number
---@param y number
---@param percenthp number
---@param percentmana number
function RevivePlayer(pid, x, y, percenthp, percentmana)
    local p        = Player(pid - 1) ---@type player 

    ReviveHero(Hero[pid], x, y, true)
    SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]) * percenthp)
    SetUnitState(Hero[pid], UNIT_STATE_MANA, GetUnitState(Hero[pid], UNIT_STATE_MAX_MANA) * percentmana)
    PanCameraToTimedForPlayer(p, x, y, 0)
    SetUnitFlyHeight(Hero[pid], 0, 0)
    reselect(Hero[pid])
    SetUnitTimeScale(Hero[pid], 1.)
    SetUnitPropWindow(Hero[pid], bj_DEGTORAD * 60.)
    SetUnitPathing(Hero[pid], true)
    RemoveLocation(FlightTarget[pid])

    if MultiShot[pid] then
        IssueImmediateOrder(Hero[pid], "immolation")
    end
end

---@type fun(pt: PlayerTimer)
function onRevive(pt)
    RevivePlayer(pt.pid, GetLocationX(TownCenter), GetLocationY(TownCenter), 1, 1)
    SetCameraBoundsRectForPlayerEx(Player(pt.pid - 1), gg_rct_Main_Map)
    PanCameraToTimedLocForPlayer(Player(pt.pid - 1), TownCenter, 0)

    DestroyTimerDialog(RTimerBox[pt.pid])

    pt:destroy()
end

---@param i integer
---@return string
function IntegerToTime(i)
    local s        = "" ---@type string 
    local hours         = i // 3600 ---@type integer 
    local minutes         = i // 60 - hours * 60 ---@type integer 
    local seconds         = i - hours * 3600 - minutes * 60 ---@type integer 

    s = tostring(hours)

    if minutes > 9 then
        s = s .. ":" .. (minutes)
    else
        s = s .. ":0" .. (minutes)
    end

    if seconds > 9 then
        s = s .. ":" .. (seconds)
    else
        s = s .. ":0" .. (seconds)
    end

    return s
end

---@param istrue boolean
---@param myreal number
---@return number
function boolset(istrue, myreal)
    if istrue then
        return 1.
    end
        return myreal
end

---@param manac number
---@return integer
function Roundmana(manac)
    if manac > 99999 then
        return 1000 * R2I(manac // 1000)
    end
    return R2I(manac)
end

---@param u unit
function BackpackLimit(u)
    BlzUnitDisableAbility(u, FourCC('A083'), true, true)
    BlzUnitDisableAbility(u, FourCC('A02A'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0IS'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0SO'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0SX'), true, true)
    BlzUnitDisableAbility(u, FourCC('A00E'), true, true)
    BlzUnitDisableAbility(u, FourCC('A00I'), true, true)
    BlzUnitDisableAbility(u, FourCC('A00O'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0CP'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0CQ'), true, true)
    BlzUnitDisableAbility(u, FourCC('AIfw'), true, true)
    BlzUnitDisableAbility(u, FourCC('AIft'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0CD'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0CC'), true, true)
    BlzUnitDisableAbility(u, FourCC('AIpv'), true, true)
    BlzUnitDisableAbility(u, FourCC('AIv2'), true, true)
    BlzUnitDisableAbility(u, FourCC('A055'), true, true)
    BlzUnitDisableAbility(u, FourCC('A01S'), true, true)
    BlzUnitDisableAbility(u, FourCC('A03D'), true, true)
    BlzUnitDisableAbility(u, FourCC('A0B5'), true, true)
    BlzUnitDisableAbility(u, FourCC('A07G'), true, true)
    UnitRemoveAbility(u, FourCC('A0CP')) --immolations and orb effects
    UnitRemoveAbility(u, FourCC('A0UP'))
    UnitRemoveAbility(u, FourCC('A00D'))
    UnitRemoveAbility(u, FourCC('A00V'))
    UnitRemoveAbility(u, FourCC('A01O'))
    UnitRemoveAbility(u, FourCC('A00Y'))
    UnitRemoveAbility(u, FourCC('AIcf'))
    UnitRemoveAbility(u, FourCC('A0CQ'))
    UnitRemoveAbility(u, FourCC('AIfw'))
    UnitRemoveAbility(u, FourCC('AIft'))
    UnitRemoveAbility(u, FourCC('A0CC'))
    UnitRemoveAbility(u, FourCC('A0CD'))
    UnitRemoveAbility(u, FourCC('A06Z'))
    UnitRemoveAbility(u, FourCC('AIlb'))
    UnitRemoveAbility(u, FourCC('AIsb'))
    UnitRemoveAbility(u, FourCC('AIdn'))
    UnitRemoveAbility(u, FourCC('A051'))
end

---@param pid integer
function UpdateManaCosts(pid)
    local maxmana = BlzGetUnitMaxMana(Hero[pid])  ---@type integer 

    if HeroID[pid] == HERO_ASSASSIN then
        SetUnitAbilityLevel(Hero[pid], BLADESPIN.id, IMinBJ(4, R2I(GetHeroLevel(Hero[pid]) / 100.) + 1))
        SetUnitAbilityLevel(Hero[pid], BLADESPINPASSIVE.id, IMinBJ(4, R2I(GetHeroLevel(Hero[pid]) / 100.) + 1))

        BlzSetUnitAbilityManaCost(Hero[pid], BLADESPIN.id, GetUnitAbilityLevel(Hero[pid], BLADESPIN.id) - 1, Roundmana(maxmana * .075))
        BlzSetUnitAbilityManaCost(Hero[pid], SHADOWSHURIKEN.id, GetUnitAbilityLevel(Hero[pid], SHADOWSHURIKEN.id) - 1, Roundmana(maxmana * .05))
        BlzSetUnitAbilityManaCost(Hero[pid], BLINKSTRIKE.id, GetUnitAbilityLevel(Hero[pid], BLINKSTRIKE.id) - 1, Roundmana(maxmana * .15))
        BlzSetUnitAbilityManaCost(Hero[pid], SMOKEBOMB.id, GetUnitAbilityLevel(Hero[pid], SMOKEBOMB.id) - 1, Roundmana(maxmana * .20))
        BlzSetUnitAbilityManaCost(Hero[pid], DAGGERSTORM.id, GetUnitAbilityLevel(Hero[pid], DAGGERSTORM.id) - 1, Roundmana(maxmana * .25))
        BlzSetUnitAbilityManaCost(Hero[pid], PHANTOMSLASH.id, GetUnitAbilityLevel(Hero[pid], PHANTOMSLASH.id) - 1, Roundmana(maxmana * (.1 - 0.025 * GetUnitAbilityLevel(Hero[pid], PHANTOMSLASH.id))))
    elseif HeroID[pid] == HERO_BARD then
        BardMelodyCost[pid] = Roundmana(GetUnitState(Hero[pid], UNIT_STATE_MANA) * .1)
        BlzSetUnitAbilityManaCost(Hero[pid], MELODYOFLIFE.id, GetUnitAbilityLevel(Hero[pid], MELODYOFLIFE.id) - 1, R2I(BardMelodyCost[pid]))
        BlzSetUnitAbilityManaCost(Hero[pid], INSPIRE.id, GetUnitAbilityLevel(Hero[pid], INSPIRE.id) - 1, Roundmana(maxmana * .02))
        BlzSetUnitAbilityManaCost(Hero[pid], TONEOFDEATH.id, GetUnitAbilityLevel(Hero[pid], TONEOFDEATH.id) - 1, Roundmana(maxmana * .2))
    elseif HeroID[pid] == HERO_DARK_SAVIOR or HeroID[pid] == HERO_DARK_SAVIOR_DEMON then
        BlzSetUnitAbilityManaCost(Hero[pid], DARKSEAL.id, GetUnitAbilityLevel(Hero[pid], DARKSEAL.id) - 1, Roundmana(maxmana * .2))
        BlzSetUnitAbilityManaCost(Hero[pid], MEDEANLIGHTNING.id, GetUnitAbilityLevel(Hero[pid], MEDEANLIGHTNING.id) - 1, Roundmana(maxmana * .1))
        BlzSetUnitAbilityManaCost(Hero[pid], FREEZINGBLAST.id, GetUnitAbilityLevel(Hero[pid], FREEZINGBLAST.id) - 1, Roundmana(maxmana * .1))
    elseif HeroID[pid] == HERO_ELEMENTALIST then
        BlzSetUnitAbilityManaCost(Hero[pid], BALLOFLIGHTNING.id, GetUnitAbilityLevel(Hero[pid], BALLOFLIGHTNING.id) - 1, Roundmana(maxmana * .05))
        BlzSetUnitAbilityManaCost(Hero[pid], FROZENORB.id, GetUnitAbilityLevel(Hero[pid], FROZENORB.id) - 1, Roundmana(maxmana * .15))
        BlzSetUnitAbilityManaCost(Hero[pid], FLAMEBREATH.id, GetUnitAbilityLevel(Hero[pid], FLAMEBREATH.id) - 1, Roundmana(maxmana * .03))
        BlzSetUnitAbilityManaCost(Hero[pid], ELEMENTALSTORM.id, GetUnitAbilityLevel(Hero[pid], ELEMENTALSTORM.id) - 1, Roundmana(maxmana * .25))
    elseif HeroID[pid] == HERO_HIGH_PRIEST then
        BlzSetUnitAbilityManaCost(Hero[pid], DIVINELIGHT.id, GetUnitAbilityLevel(Hero[pid], DIVINELIGHT.id) - 1, Roundmana(maxmana * .05))
        BlzSetUnitAbilityManaCost(Hero[pid], SANCTIFIEDGROUND.id, GetUnitAbilityLevel(Hero[pid], SANCTIFIEDGROUND.id) - 1, Roundmana(maxmana * .1))
        BlzSetUnitAbilityManaCost(Hero[pid], HOLYRAYS.id, GetUnitAbilityLevel(Hero[pid], HOLYRAYS.id) - 1, Roundmana(maxmana * .1))
        BlzSetUnitAbilityManaCost(Hero[pid], PROTECTION.id, GetUnitAbilityLevel(Hero[pid], PROTECTION.id) - 1, Roundmana(maxmana * .5))
        BlzSetUnitAbilityManaCost(Hero[pid], RESURRECTION.id, GetUnitAbilityLevel(Hero[pid], RESURRECTION.id) - 1, Roundmana(GetUnitState(Hero[pid], UNIT_STATE_MANA)))
    elseif HeroID[pid] == HERO_PHOENIX_RANGER then
        --
    elseif HeroID[pid] == HERO_THUNDERBLADE then
        BlzSetUnitAbilityManaCost(Hero[pid], OVERLOAD.id, GetUnitAbilityLevel(Hero[pid], OVERLOAD.id) - 1, Roundmana(maxmana * .02))
    end
end

end)

if Debug then Debug.endFile() end
