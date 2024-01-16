if Debug then Debug.beginFile "Helper" end

--iterator for groups with counter
---@param ug group
---@return fun(): integer?, unit?
function ieach(ug)
    local index = 0
    local length = BlzGroupGetSize(ug)

    return function()
        if index < length then
            return index, BlzGroupUnitAt(ug, index)
        end
        index = index + 1
    end
end

--iterator for groups
---@param ug group
---@return fun(): unit?
function each(ug)
    local index = 0
    local length = BlzGroupGetSize(ug)

    return function()
        if index < length then
            return BlzGroupUnitAt(ug, index)
        end
        index = index + 1
    end
end

--returns a 2d array with default value val or nil if empty
---@type fun(val: any): table
function array2d(val)
    local self = {}

    setmetatable(self, { __index = function(tbl, key)
        if rawget(tbl, key) then
            return rawget(tbl, key)
        else
            local new
            if val == nil then
                new = {}
            else
                new = __jarray(val)
            end

            rawset(tbl, key, new)
            return new
        end
    end})

    return self
end

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
    local p      = GetTriggerPlayer()
    local pid    = GetPlayerId(p) + 1
    local mbitem = nil ---@type multiboarditem 

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

    PlayerCleanup(pid)

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
    -- local player is in group selection?
    if BlzFrameIsVisible(containerFrame) then
        -- find the first visible yellow Background Frame
        for i = 0, 11 do
            if BlzFrameIsVisible(frames[i]) then
                return i
            end
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
            ---@diagnostic disable-next-line: missing-fields
            local self = {} ---@type ArcingTextTag

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
        thistype.shield = nil ---@type shield 
        thistype.prev   = nil ---@type shieldtimer 
        thistype.next   = nil ---@type shieldtimer 
        thistype.amount = 0.

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
            local self = s ---@type shieldtimer 

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
            ---@diagnostic disable-next-line: missing-fields
            local self = {} ---@type shieldtimer

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
        thistype.sfx    = nil ---@type effect 
        thistype.target = nil ---@type unit 
        thistype.max    = 0. ---@type number 
        thistype.hp     = 0. ---@type number 
        thistype.c      = 2 ---@type integer 
        thistype.timer  = 0 ---@type shieldtimer 
        thistype.next   = nil ---@type shield 
        thistype.prev   = nil ---@type shield 

        thistype.head   = nil ---@type shield 
        thistype.tail   = nil ---@type shield 
        thistype.count  = 0 ---@type integer 
        thistype.t      = nil ---@type TimerQueue 
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
            local curr = thistype.head
            local prev = nil
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
            local self = shield[u]

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
            ProtectionBuff:dispel(nil, self.target) --high priestess protection attack speed

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
            ---@diagnostic disable-next-line: missing-fields
            local self = {} ---@type shield

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
    thistype.OPTIONS_PER_PAGE = 7 ---@type integer 
    thistype.BUTTON_MAX       = 100 ---@type integer 
    thistype.MENU_BUTTON_MAX  = 5 ---@type integer 
    thistype.DATA_MAX         = 100 ---@type integer 

    thistype.dialog          = nil ---@type dialog 
    thistype.pid             = 0 ---@type integer 
    thistype.title           = "" ---@type string 
    thistype.Button          = {} ---@type button[] [thistype.BUTTON_MAX]
    thistype.ButtonName      = __jarray("") ---@type string[] [thistype.BUTTON_MAX]
    thistype.MenuButton      = {} ---@type button[] [thistype.MENU_BUTTON_MAX]
    thistype.MenuButtonName  = __jarray("") ---@type string[] [thistype.MENU_BUTTON_MAX]
    thistype.ButtonCount     = 0  ---@type integer 
    thistype.MenuButtonCount = 2  ---@type integer 
    thistype.Page            = -1 ---@type integer 
    thistype.trig            = nil ---@type trigger 

    thistype.cancellable         = true ---@type boolean 
    thistype.data = {} ---@type any[] [thistype.DATA_MAX]

    ---@return boolean
    function thistype.dialogHandler()
        local self = thistype[GetPlayerId(GetTriggerPlayer()) + 1]

        --cancel
        if self then
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

        ---@diagnostic disable-next-line: missing-fields
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

--helper functions

---@type fun(index: integer, loc: location, facing: number, id: integer, name: string, level: integer, items: integer[], crystal: integer, leash: number)
function CreateBossEntry(index, loc, facing, id, name, level, items, crystal, leash)

    BossTable[index] = {
        loc = loc,
        facing = facing,
        unit = CreateUnitAtLoc(pboss, id, loc, facing),
        id = id,
        name = name,
        level = level,
        item = items,
        crystal = crystal,
        leash = leash,
        revive = function(self) CreateUnitAtLoc(pboss, self.id, self.loc, self.facing) end
    }
end

---@type fun(pid: integer, prof: integer): boolean
function HasProficiency(pid, prof)
    if not HeroStats[HeroID[pid]] then
        return false
    end

    return BlzBitAnd(HeroStats[HeroID[pid]].prof, prof) ~= 0
end

---@param u unit
---@return boolean
function IsUnitStunned(u)
    return (Stun:has(nil, u) or Freeze:has(nil, u) or KnockUp:has(nil, u) or GetUnitAbilityLevel(u, FourCC('BPSE')) > 0 or GetUnitAbilityLevel(u, FourCC('BSTN')) > 0 or isteleporting[GetPlayerId(GetOwningPlayer(u)) + 1])
end

---@type fun(u: unit, id: integer, disable: boolean)
function UnitDisableAbility(u, id, disable)
    local ablev = GetUnitAbilityLevel(u, id) ---@type integer 

    if ablev == 0 then
        return
    end

    UnitRemoveAbility(u, id)
    UnitAddAbility(u, id)
    SetUnitAbilityLevel(u, id, ablev)
    BlzUnitDisableAbility(u, id, disable, false)
    BlzUnitHideAbility(u, id, true)
end

---@type fun(intValue: integer):string
function IntToFourCC(intValue)
    local result = ""
    for i = 1, 4 do
        local charCode = string.char((intValue >> ((4 - i) * 8)) & 0xFF)
        result = result .. charCode
    end
    return result
end

---@param position integer
---@return integer red
---@return integer green
---@return integer blue
function HealthGradient(position)
    -- Ensure the position is within the valid range [1, 100]
    position = math.min(100, math.max(1, position))

    -- Define color stops and their corresponding positions
    local colorStops = {
        {1,   {255, 0, 0}},
        {10,  {255, 0, 0}},
        {70,  {242, 255, 64}},
        {100, {8, 200, 2}}
    }

    -- Find the two color stops between which the position falls
    local startStop, endStop
    for i = 1, #colorStops - 1 do
        if position <= colorStops[i + 1][1] then
            startStop = colorStops[i]
            endStop = colorStops[i + 1]
            break
        end
    end

    -- Interpolate between the two color stops based on position
    local t = (position - startStop[1]) / (endStop[1] - startStop[1])
    local interpolatedColor = {
        math.floor(startStop[2][1] + t * (endStop[2][1] - startStop[2][1])),
        math.floor(startStop[2][2] + t * (endStop[2][2] - startStop[2][2])),
        math.floor(startStop[2][3] + t * (endStop[2][3] - startStop[2][3]))
    }

    return interpolatedColor[1], interpolatedColor[2], interpolatedColor[3]
end

--maybe one day I will no longer use groups
---@type fun(tbl:table, val: any): boolean
function TableHas(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then
            return true
        end
    end

    return false
end

---@type fun(tbl: table, val: any)
function TableRemove(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then
            tbl[i] = tbl[#tbl]
            tbl[#tbl] = nil
            break
        end
    end
end

---@type fun(tbl: table, text: string)
function DisplayTextToTable(tbl, text)
    for i = 1, #tbl do
        DisplayTextToPlayer(tbl[i], 0, 0, text)
    end
end

---@type fun(tbl: table, dur: number, text: string)
function DisplayTimedTextToTable(tbl, dur, text)
    for i = 1, #tbl do
        DisplayTimedTextToPlayer(tbl[i], 0, 0, dur, text)
    end
end

local passedValue = {}

---@type fun(pid: integer, g: group, r: rect, b: boolexpr)
function MakeGroupInRect(pid, g, r, b)
    passedValue[#passedValue + 1] = pid
    GroupEnumUnitsInRect(g, r, b)
    passedValue[#passedValue] = nil
end

---@type fun(pid: integer, g: group, x: number, y: number, radius: number, b: boolexpr)
function MakeGroupInRange(pid, g, x, y, radius, b)
    passedValue[#passedValue + 1] = pid
    GroupEnumUnitsInRange(g, x, y, radius, b)
    passedValue[#passedValue] = nil
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

---@type fun(pid: integer, index: integer):integer
function GetCurrency(pid, index)
    return Currency[pid * CURRENCY_COUNT + index]
end

---@type fun(pid: integer, index: integer, amount: integer)
function AddCurrency(pid, index, amount)
    SetCurrency(pid, index, GetCurrency(pid, index) + amount)
end

---@param u unit
---@param show boolean
function ToggleCommandCard(u, show)
    local classification = BlzGetUnitIntegerField(u, UNIT_IF_UNIT_CLASSIFICATION) ---@type integer 
    local ward = GetHandleId(UNIT_CATEGORY_WARD) ---@type integer 

    if (BlzBitAnd(classification, ward) > 0 and show) or (BlzBitAnd(classification, ward) == 0 and not show) then
        BlzSetUnitIntegerField(u, UNIT_IF_UNIT_CLASSIFICATION, BlzBitXor(classification, ward))
    end
end

---@type fun(path: string, is3D: boolean, p: player, u: unit)
function SoundHandler(path, is3D, p, u)
    local s ---@type sound 
    local ss = "" ---@type string 

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
    local time = TimerGetRemaining(t)
    local minutes = time // 60
    local seconds = ModuloInteger(R2I(time), 60)

    return (minutes > 0 and (minutes) .. " minutes") or (seconds) .. " seconds"
end

local tempplayer = nil
function ItemRepickRemove()
    if Item[GetEnumItem()].owner == tempplayer then
        Item[GetEnumItem()]:destroy()
    end
end

---@return boolean
function FilterDespawn()
    local u = GetFilterUnit()

    return IsUnitEnemy(u, pfoe) and
        UnitAlive(u) and
        GetUnitTypeId(u) ~= BACKPACK and
        GetUnitTypeId(u) ~= DUMMY and
        GetUnitAbilityLevel(u, FourCC('Aloc')) == 0 and
        GetPlayerId(GetOwningPlayer(u)) <= PLAYER_CAP
end

---@return boolean
function isvillager()
    local id = GetUnitTypeId(GetFilterUnit()) ---@type integer 
    if id == FourCC('n02V') or id == FourCC('n03U') or id == FourCC('n09Q') or id == FourCC('n09T') or id == FourCC('n09O') or id == FourCC('n09P') or id == FourCC('n09R') or id == FourCC('n09S') or id == FourCC('nvk2') or id == FourCC('nvlw') or id == FourCC('nvlk') or id == FourCC('nvil') or id == FourCC('nvl2') or id == FourCC('H01Y') or id == FourCC('H01T') or id == FourCC('n036') or id == FourCC('n035') or id == FourCC('n037') or id == FourCC('n03S') or id == FourCC('n01I') or id == FourCC('n0A3') or id == FourCC('n0A4') or id == FourCC('n0A5') or id == FourCC('n0A6') or id == FourCC('h00G') then
        return true
    end
    return false
end

---@return boolean
function isspirit()
    local id = GetUnitTypeId(GetFilterUnit()) ---@type integer 
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
    local pid = GetPlayerId(GetOwningPlayer(GetFilterUnit())) + 1 ---@type integer 

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
    local uid = GetUnitTypeId(GetFilterUnit()) ---@type integer 

    return (UnitAlive(GetFilterUnit()) and (uid == FourCC('o01I') or uid == FourCC('o008')))
end

---@return boolean
function ishostile()
    local i =GetPlayerId(GetOwningPlayer(GetFilterUnit())) ---@type integer 

    return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and (i ==10 or i ==11 or i ==PLAYER_NEUTRAL_AGGRESSIVE))
end

---@return boolean
function ChaosTransition()
    local i = GetPlayerId(GetOwningPlayer(GetFilterUnit())) ---@type integer 

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
    local u = GetFilterUnit()
    local i = GetPlayerId(GetOwningPlayer(u)) ---@type integer 

    return
    (UnitAlive(u) and
    GetUnitAbilityLevel(u, FourCC('Avul')) == 0 and
    i <= PLAYER_CAP and
    GetUnitTypeId(u) ~= DUMMY)
end

---@return boolean
function isalive()
    return (UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY)
end

---@type fun(u: integer | unit):integer
function IsBoss(u)
    local uid = (type(u) == "number" and u) or GetUnitTypeId(u)

    for i = 1, #BossTable do
        if BossTable[i].id == uid then
            return i
        end
    end

    return -1
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

local ImportantItems = {
    FourCC('I042'), FourCC('I040'), FourCC('I041'), FourCC('I0M4'), FourCC('I0M5'), FourCC('I0M6'), FourCC('I0M7') --keys
}

---@type fun(itm: item): boolean
function isImportantItem(itm)
    return ImportantItems[GetItemTypeId(itm)] ~= nil or itm == PathItem
end

function ClearItems()
    local itm = GetEnumItem() ---@type item 

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
    local pt = TimerList[0]:add()

    pt.source = source
    pt.target = target

    UnitAddAbility(source, FourCC('IATK'))
    pt.timer:callDelayed(0.05, AttackDelay, pt)
end

---@type fun(dummy: unit)
function RecycleDummy(dummy)
    if dummy then
        local abil = DUMMY_FLAG[dummy].abil

        if abil then
            UnitRemoveAbility(dummy, abil)
            DUMMY_FLAG[dummy].abil = nil
        end
        SetUnitAnimation(dummy, "stand")
        SetUnitPropWindow(dummy, bj_DEGTORAD * 180.)
        BlzSetUnitName(dummy, " ")
        BlzSetUnitWeaponBooleanField(dummy, UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
        SetUnitOwner(dummy, Player(PLAYER_NEUTRAL_PASSIVE), true)
        BlzSetUnitSkin(dummy, DUMMY)
        SetUnitXBounded(dummy, 30000.)
        SetUnitYBounded(dummy, 30000.)
        UnitAddAbility(dummy, FourCC('Aloc'))
        UnitAddAbility(dummy, FourCC('Avul'))
        SetUnitFlyHeight(dummy, GetUnitDefaultFlyHeight(dummy), 0)
        SetUnitScale(dummy, 1, 1, 1)
        SetUnitVertexColor(dummy, 255, 255, 255, 255)
        SetUnitTimeScale(dummy, 1.)
        BlzUnitClearOrders(dummy, false)
        BlzUnitDisableAbility(dummy, FourCC('Amov'), false, false)
        PauseUnit(dummy, true)
        BlzSetUnitAttackCooldown(dummy, 0.01, 0)
        UnitAddBonus(dummy, BONUS_ATTACK_SPEED, 4.)
        DUMMY_STACK[#DUMMY_STACK + 1] = dummy
    end
end

---@type fun(x: number, y: number, abil: integer, ablev: integer, dur: number):unit
function GetDummy(x, y, abil, ablev, dur)
    local dummy = DUMMY_STACK[#DUMMY_STACK]

    if not dummy then --available list is empty
        dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY, x, y, 0)
        DUMMY_LIST[#DUMMY_LIST + 1] = dummy --append to dummy list
        DUMMY_FLAG[dummy] = {}
        UnitAddAbility(dummy, FourCC('Amrf'))
        UnitRemoveAbility(dummy, FourCC('Amrf'))
        UnitAddAbility(dummy, FourCC('Aloc'))
        SetUnitPathing(dummy, false)
        TriggerRegisterUnitEvent(ACQUIRE_TRIGGER, dummy, EVENT_UNIT_ACQUIRED_TARGET)
    else --use an existing available dummy
        DUMMY_STACK[#DUMMY_STACK] = nil
        PauseUnit(dummy, false)
    end

    if UnitAddAbility(dummy, abil) then
        SetUnitAbilityLevel(dummy, abil, ablev)
        DUMMY_FLAG[dummy].abil = abil
    end

    if dur > 0 then
        TimerQueue:callDelayed(dur, RecycleDummy, dummy)
    end

    --reset attack cooldown
    BlzSetUnitAttackCooldown(dummy, 5., 0)
    UnitSetBonus(dummy, BONUS_ATTACK_SPEED, 0.)

    SetUnitXBounded(dummy, x)
    SetUnitYBounded(dummy, y)

    return dummy
end

---@param pid integer
function RemovePlayerUnits(pid)
    local ug = CreateGroup()

    GroupEnumUnitsOfPlayer(ug, Player(pid - 1), nil)

    for target in each(ug) do
        if IsUnitType(target, UNIT_TYPE_HERO) then
            for i = 0, 5 do
                local itm = UnitItemInSlot(target, i)
                local itid = GetItemTypeId(itm)
                if isImportantItem(itm) then
                    Item[itm]:destroy()
                    Item.create(CreateItem(itid, GetLocationX(TownCenter), GetLocationY(TownCenter)))
                end
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
    local str = GetHeroStr(hero, true) ---@type integer 
    local agi = GetHeroAgi(hero, true) ---@type integer 
    local int = GetHeroInt(hero, true) ---@type integer 

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
    local angle = Atan2(GetRectCenterY(r) - y, GetRectCenterX(r) - x) ---@type number 

    for i = 5, 50, 5 do
        if RectContainsCoords(r, x + i * Cos(angle), y + Sin(angle) * i) then
            return true
        end
    end

    return false
end

---@param i integer
---@param x number
---@param y number
function CustomLightingPlayerCheck(i, x, y)
    local daynightmodel = DEFAULT_LIGHTING ---@type string 

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
    if pt.pause then
        BlzPauseUnitEx(pt.target, false)
    end

    if pt.dur > 0. then
        SetUnitTimeScale(pt.target, pt.dur)
    end

    SetUnitAnimationByIndex(pt.target, pt.index)

    pt:destroy()
end

---@type fun(pid: integer, u: unit, delay: number, index: integer, timescale: number, pause: boolean)
function DelayAnimation(pid, u, delay, index, timescale, pause)
    local pt = TimerList[pid]:add() ---@type PlayerTimer

    pt.target = u
    pt.index = index
    pt.pause = false
    pt.dur = timescale

    if pause then
        BlzPauseUnitEx(u, true)
        pt.pause = true
    end

    pt.timer:callDelayed(delay, DelayAnimationExpire, pt)
end

---@param p player
---@param r rect
function SetCameraBoundsRectForPlayerEx(p, r)
    local minX = GetRectMinX(r) ---@type number 
    local minY = GetRectMinY(r) ---@type number 
    local maxX = GetRectMaxX(r) ---@type number 
    local maxY = GetRectMaxY(r) ---@type number 
    local pid  = GetPlayerId(p) + 1 ---@type integer 

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
        ClearSelection()
        SelectUnit(hsdummy[pid], true)
        SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 500, 0)
        SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 340, 0)
        SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, 60, 0)
        SetCameraField(CAMERA_FIELD_ZOFFSET, 200, 0)
        SetCameraField(CAMERA_FIELD_ROTATION, GetUnitFacing(HeroCircle[hslook[U.id]].unit) + 180, 0)
        SetCameraTargetController(gg_unit_h00T_0511, 0, 0, false)
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
    local lines = {}

    for match in contents:gmatch("[^\n]*\n") do
        lines[#lines + 1] = match
    end

    return lines[line] or ""
end

---@param pid integer
function SetSaveSlot(pid)
    for i = 0, MAX_SLOTS do
        if Profile[pid].phtl[i] == 0 then
            Profile[pid].currentSlot = i
            return
        end
    end

    Profile[pid].currentSlot = -1
end

---@return boolean
function ConfirmDeleteCharacter()
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1
    local dw    = DialogWindow[pid]
    local index = dw:getClickedIndex(GetClickedButton())

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
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    local dw    = DialogWindow[pid]
    local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

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
    local dw = DialogWindow.create(pid, "|cffffffffLOAD", LoadMenu)

    deleteMode[pid] = false

    for i = 0, MAX_SLOTS do
        local hardcore = 0
        local prestige = 0
        local id = 0
        local herolevel = 0

        if Profile[pid].phtl[i] > 0 then --slot is not empty
            local name = "|cffffcc00"
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
    end

    dw:addMenuButton("|cffffffffNew Character")
    dw:addMenuButton("|cffff0000Delete Character")

    dw:display()
end

---@param arena integer
function ResetArena(arena)
    if arena == 0 then
        return
    end

    local U = User.first

    while U do
        if IsUnitInGroup(Hero[U.id], Arena[arena]) then
            PauseUnit(Hero[U.id], false)
            UnitRemoveAbility(Hero[U.id], FourCC('Avul'))
            SetUnitAnimation(Hero[U.id], "stand")
            SetUnitPositionLoc(Hero[U.id], TownCenter)
            SetCameraBoundsRectForPlayerEx(GetOwningPlayer(Hero[U.id]), gg_rct_Main_Map_Vision)
            PanCameraToTimedForPlayer(GetOwningPlayer(Hero[U.id]), GetUnitX(Hero[U.id]), GetUnitY(Hero[U.id]), 0)
        end

        U = U.next
    end
end

---@param pid integer
---@return integer
function GetArena(pid)
    for i = 0, ArenaMax do
        if IsUnitInGroup(Hero[pid], Arena[i]) then
            return i
        end
    end

    return 0
end

function ClearStruggle()
    local ug = CreateGroup()

    GroupEnumUnitsInRect(ug, gg_rct_Infinite_Struggle, Condition(FilterNotHero))

    for target in each(ug) do
        RemoveUnit(target)
    end

    DestroyGroup(ug)

    Struggle_WaveN = 0
    GoldWon_Struggle = 0
    Struggle_WaveUCN = 0
end

function ClearColo()
    local ug = CreateGroup()

    GoldWon_Colo = 0

    GroupEnumUnitsInRect(ug, gg_rct_Colosseum, Condition(FilterNotHero))

    for target in each(ug) do
        RemoveUnit(target)
    end

    DestroyGroup(ug)

    EnumItemsInRect(gg_rct_Colosseum, nil, ClearItems)
    SetTextTagText(ColoText, "Colosseum", 10 * 0.023 / 10)
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

--use for any instance of player removal (leave, repick, permanent death, forcesave, afk removal)
---@type fun(pid: integer)
function PlayerCleanup(pid)
    local p = Player(pid - 1)

    --close actions spellbook
    UnitRemoveAbility(Hero[pid], FourCC('A03C'))

    --clear ashen vat
    for i = 0, 5 do
        local itm = Item[UnitRemoveItemFromSlot(ASHEN_VAT, i)]
        if itm and itm.owner == p then
            itm:destroy()
        end
    end

    --clear cosmetics
    for _, v in ipairs(CosmeticTable.cosmetics) do
        if v[pid .. v.name] then
            DestroyEffect(v[pid .. v.name])
            v[pid .. v.name] = nil
        end
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

    PlayerBase[pid] = nil
    GroupRemoveUnit(HeroGroup, Hero[pid])
    RemovePlayerUnits(pid)

    Hero[pid] = nil
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
    BaseID[pid] = 0
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
        BlzFrameSetVisible(dummyFrame, false)
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

    tempplayer = p
    EnumItemsInRect(bj_mapInitialPlayableArea, nil, ItemRepickRemove)

    if autosave[pid] then
        autosave[pid] = false
        DisplayTextToPlayer(p, 0, 0, "|cffffcc00Autosave disabled.|r")
    end
end

---@param u1 unit
---@param u2 unit
---@return number
function UnitDistance(u1, u2)
    local dx = GetUnitX(u2) - GetUnitX(u1) ---@type number 
    local dy = GetUnitY(u2) - GetUnitY(u1) ---@type number 

    return SquareRoot(dx * dx + dy * dy)
end

---@type fun(x: number, y: number, x2: number, y2: number):number
function DistanceCoords(x, y, x2, y2)
    return SquareRoot((x - x2) ^ 2 + (y - y2) ^ 2)
end

---@param u unit
function ExpireUnit(u)
    UnitApplyTimedLife(u, FourCC('BTLF'), 0.1)
end

---@param u unit
---@param abid integer
function UnitResetAbility(u, abid)
    local i = GetUnitAbilityLevel(u, abid) ---@type integer 

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
    local itm ---@type item 

    for i = 0, 5 do
        itm = UnitItemInSlot(u, i)
        if itm and GetItemTypeId(itm) == itid then
            return UnitItemInSlot(u, i)
        end
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
    for i = 0, 5 do
        if GetItemTypeId(UnitItemInSlot(u, i)) == itid then
            return true
        end
    end

    return false
end

---@param pid integer
---@param charge boolean
---@return Item?
function GetResurrectionItem(pid, charge)
    for i = 0, 5 do
        local itm = Item[UnitItemInSlot(Hero[pid], i)]
        if itm then
            if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') or ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') then
                if charge and ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') then
                    return itm
                elseif not charge and GetItemCharges(itm.obj) > 0 then
                    return itm
                end
            end
        end
    end

    if charge then
        for i = 0, 5 do
            local itm = Item[UnitItemInSlot(Backpack[pid], i)]
            if itm then
                if ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') or ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') then
                    if charge and ItemData[itm.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Arrv') then
                        return itm
                    elseif not charge and GetItemCharges(itm.obj) > 0 then
                        return itm
                    end
                end
            end
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
    local lowBound  = groupnumber * REGION_GAP ---@type integer 
    local highBound = lowBound ---@type integer 

    while not (RegionCount[highBound] == nil) do
        highBound = highBound + 1
    end

    return RegionCount[GetRandomInt(lowBound, highBound - 1)]
end

--formats a real to a string with commas
---@param value number
---@return string
function RealToString(value)
    local s = tostring(R2I(value)) ---@type string 
    local len = #s ---@type integer 

    local chunks = {}
    while len > 0 do
        local chunkSize = math.min(len, 3)
        chunks[#chunks + 1] = SubString(s, len - chunkSize, len)
        len = len - chunkSize
    end

    return table.concat(chunks, ",")
end

---@type fun(id: integer, pid: integer):number
function ItemProfMod(id, pid)
    local prof = ItemData[id][ITEM_TYPE] ---@type integer 

    return (prof > 0 and prof ~= 5 and not HasProficiency(pid, PROF[prof]) and 0.75) or 1
end

---@type fun(itemid: integer):integer
function ItemToIndex(itemid)
    return SAVE_TABLE.KEY_ITEMS[itemid]
end

---@param pid integer
---@param itm Item
function ItemInfo(pid, itm)
    local p      = Player(pid - 1) ---@type player 
    local s      = GetObjectName(itm.id) ---@type string 
    local cost   = itm:calcStat(ITEM_COST, 0) ---@type integer 
    local maxlvl = ItemData[itm.id][ITEM_UPGRADE_MAX] ---@type integer 

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
        DisplayTimedTextToPlayer(p, 0, 0, 15., "|cffbbbbbbProficiency|r: " .. RealToString(ItemProfMod(itm.id, pid) * 100) .. "\x25")
    end

    for i = ITEM_HEALTH, ITEM_STAT_TOTAL do
        if ItemData[itm.id][i] ~= 0 and STAT_NAME[i] ~= nil then
            local offset = 3
            s = ""

            if i == ITEM_MAGIC_RESIST or i == ITEM_DAMAGE_RESIST or i == ITEM_EVASION or i == ITEM_CRIT_CHANCE or i == ITEM_SPELLBOOST or i == ITEM_GOLD_GAIN then
                s = "\x25"
                offset = 4
            end

            if i == ITEM_CRIT_CHANCE then
                i = i + 1
                DisplayTimedTextToPlayer(p, 0, 0, 15., SubString(STAT_NAME[i], offset, StringLength(STAT_NAME[i])) .. ": " .. RealToString(itm:calcStat(ITEM_CRIT_CHANCE, 0)) .. "\x25 " .. RealToString(itm:calcStat(ITEM_CRIT_DAMAGE, 0)) .. "x")
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., SubString(STAT_NAME[i], offset, StringLength(STAT_NAME[i])) .. ": " .. RealToString(itm:calcStat(i, 0)) + s)
            end
        end
    end

    if ItemToIndex(itm.id) > 0 then --item info cannot be cast on backpacked items
        DisplayTimedTextToPlayer(p, 0, 0, 15., "|c0000ff33Saveable|r")
    end
end

---@param flag integer
function SpawnCreeps(flag)
    local i = 0 ---@type integer 
    local index = UnitData[flag][i] ---@type integer
    local myregion = nil ---@type rect 
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
    local itm = Item.create(CreateItem(id, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])))

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

    if IsItemOwned(itm.obj) == false and not itm.restricted then
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
    local pid = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 

    if GetCurrency(pid, PLATINUM) < plat or GetCurrency(pid, ARCADITE) < arc then
        DisplayTimedTextToPlayer(GetOwningPlayer(u), 0, 0, 10, "You do not have enough resources to buy this.")
    else
        PlayerAddItemById(pid, id)
        AddCurrency(pid, PLATINUM, -plat)
        AddCurrency(pid, ARCADITE, -arc)
        DisplayTimedTextToPlayer(GetOwningPlayer(u), 0, 0, 20, "You have purchased a " + GetObjectName(id) .. ".")
        DisplayTimedTextToPlayer(GetOwningPlayer(u), 0, 0, 10, PlatTag + (GetCurrency(pid, PLATINUM)))
        DisplayTimedTextToPlayer(GetOwningPlayer(u), 0, 0, 10, ArcTag + (GetCurrency(pid, ARCADITE)))
    end
end

--used before equip
---@type fun(u: unit) : integer
function GetEmptySlot(u)
    for i = 0, 5 do
        if UnitItemInSlot(u, i) == nil then
            return i
        end
    end

    return -1
end

---@type fun(itm: item, u : unit):integer
function GetItemSlot(itm, u)
    for i = 0, 5 do
        if UnitItemInSlot(u, i) == itm then
            return i
        end
    end

    return -1
end

---@type fun(itm: Item, pid: integer): boolean
function IsItemBound(itm, pid)
    return (itm.owner ~= Player(pid - 1) and itm.owner ~= nil)
end

---@param itm Item
---@return boolean
function IsItemLimited(itm)
    local limit = ItemData[itm.id][ITEM_LIMIT] ---@type integer 

    if limit == 0 then
        return false
    end

    for i = 0, 5 do
        local itm2 = UnitItemInSlot(itm.holder, i)

        if itm2 then
            local id = GetItemTypeId(itm2)

            if itm.obj == itm2 or (limit == 1 and itm.id ~= id) then
            --safe case
            elseif limit == ItemData[id][ITEM_LIMIT] then
                DisplayTextToPlayer(GetOwningPlayer(itm.holder), 0, 0, LIMIT_STRING[limit])
                return true
            end
        end
    end

    return false
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
    local base        = 150 ---@type integer 
    local levelFactor = 100 ---@type integer 

    for i = 2, level do
        base = base + i * levelFactor
    end

    return base
end

---@type fun(id: integer, chance: integer, x: number, y: number)
function BossDrop(id, chance, x, y)
    for _ = 0, HARD_MODE do
        if GetRandomInt(0, 99) < chance then
            local itm = Item.create(CreateItem(DropTable:pickItem(id), x, y), 600.)
            itm:lvl(IMaxBJ(0, ItemData[itm.id][ITEM_UPGRADE_MAX] - GetRandomInt(8, 11)))
        end
    end
end

local StatTable = {
    GetHeroStr,
    GetHeroInt,
    GetHeroAgi,
    function(a, b) return 0 end,
}

---@type fun(stat: integer, u: unit, bonuses: boolean): integer
function GetHeroStat(stat, u, bonuses)
    return StatTable[stat](u, bonuses)
end

---@type fun(p0_x: number, p0_y: number, p1_x: number, p1_y: number, p2_x: number, p2_y: number, p3_x: number, p3_y: number): location | nil
function GetLineIntersection(p0_x, p0_y, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y)
    local s1_x = p1_x - p0_x ---@type number 
    local s1_y = p1_y - p0_y ---@type number 
    local s2_x = p3_x - p2_x ---@type number 
    local s2_y = p3_y - p2_y ---@type number 
    local s    = (-s1_y * (p0_x - p2_x) + s1_x * (p0_y - p2_y)) / (-s2_x * s1_y + s1_x * s2_y) ---@type number 
    local t    = (s2_x * (p0_y - p2_y) - s2_y * (p0_x - p2_x)) // (-s2_x * s1_y + s1_x * s2_y) ---@type number 
    local i_x  = 0. ---@type number 
    local i_y  = 0. ---@type number 

    if (s >= 0.0 and s <= 1.0 and t >= 0.0 and t <= 1.0) then
        -- collision
        i_x = p0_x + (t * s1_x)
        i_y = p0_y + (t * s1_y)

        return {i_x, i_y}
    end

    --no collision
    return nil
end

---@type fun(x: number, y: number, x2: number, y2: number, minX: number, minY: number, maxX: number, maxY: number): boolean
function LineContainsRect(x, y, x2, y2, minX, minY, maxX, maxY)
    local leftSide   = GetLineIntersection(x, y, x2, y2, minX, minY, minX, maxY) ---@type table 
    local rightSide  = GetLineIntersection(x, y, x2, y2, maxX, minY, maxX, maxY) ---@type table 
    local bottomSide = GetLineIntersection(x, y, x2, y2, minX, minY, maxX, minY) ---@type table 
    local topSide    = GetLineIntersection(x, y, x2, y2, minX, maxY, maxX, maxY) ---@type table 

    return (leftSide ~= nil or rightSide ~= nil or bottomSide ~= nil or topSide ~= nil)
end

---@param u unit
---@return boolean
function InCombat(u)
    local ug = CreateGroup()

    GroupEnumUnitsInRange(ug, GetUnitX(u), GetUnitY(u), 900., Condition(ishostile))

    for target in each(ug) do
        if Threat[target].target == u then
            DestroyGroup(ug)
            return true
        end
    end


    DestroyGroup(ug)
    return false
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
    local ug = CreateGroup()

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

        if UnitAlive(kroresh) then
            UnitAddAbility(kroresh, FourCC('Avul'))
        end
    end

    DestroyGroup(ug)
end

function SpawnForgotten()
    if UnitAlive(forgotten_spawner) and forgottenCount < 5 then
        local id = forgottenTypes[GetRandomInt(0, 4)] ---@type integer 

        forgottenCount = forgottenCount + 1
        CreateUnit(pfoe, id, 13699 + GetRandomInt(-250, 250), -14393 + GetRandomInt(-250, 250), GetRandomInt(0, 359))
    end
end

local VALID_TREES = {
    ['ITtw'] = 1,
    ['JTtw'] = 1,
    ['FTtw'] = 1,
    ['NTtw'] = 1,
    ['B00B'] = 1,
    ['B00H'] = 1,
    ['ITtc'] = 1,
    ['NTtc'] = 1,
    ['WTst'] = 1,
    ['WTtw'] = 1,
    x = 0.,
    y = 0.,
    range = 0.
}

function EnumDestroyTreesInRange()
    local d   = GetEnumDestructable() ---@type destructable 
    local did = IntToFourCC(GetDestructableTypeId(d))

    if VALID_TREES[did] and DistanceCoords(VALID_TREES.x, VALID_TREES.y, GetDestructableX(d), GetDestructableY(d)) <= VALID_TREES.range then
        KillDestructable(d)
    end
end

---@type fun(x: number, y: number, range: number)
function DestroyTreesInRange(x, y, range)
    local r = Rect(x - range, y - range, x + range, y + range) ---@type rect 

    VALID_TREES.x = x
    VALID_TREES.y = y
    VALID_TREES.range = range
    EnumDestructablesInRect(r, nil, EnumDestroyTreesInRange)

    RemoveRect(r)
end

---@type fun(owner: player, abil: integer, ablev:integer, x: number, y: number, order: string)
function DummyCast(owner, abil, ablev, x, y, order)
    local u = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME) ---@type unit 

    SetUnitOwner(u, owner, true)
    IssueImmediateOrder(u, order)
end

---@type fun(owner: player, target: unit, abil: integer, ablev:integer, x: number, y: number, order: string)
function DummyCastTarget(owner, target, abil, ablev, x, y, order)
    local u = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME) ---@type unit 

    SetUnitOwner(u, owner, true)
    BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(GetUnitY(target) - y, GetUnitX(target) - x))
    IssueTargetOrder(u, order, target)
end

---@type fun(owner: player, x2: number, y2: number, abil: integer, ablev:integer, x: number, y: number, order: string)
function DummyCastPoint(owner, x2, y2, abil, ablev, x, y, order)
    local u = GetDummy(x, y, abil, ablev, DUMMY_RECYCLE_TIME) ---@type unit 

    SetUnitOwner(u, owner, true)
    BlzSetUnitFacingEx(u, bj_RADTODEG * Atan2(y2 - y, x2 - x))
    IssuePointOrder(u, order, x2, y2)
end

---@type fun(pid: integer, target: unit, duration: number)
function StunUnit(pid, target, duration)
    local stun = Stun:add(Hero[pid], target)

    if IsUnitType(target, UNIT_TYPE_HERO) then
        stun:duration(duration * 0.5)
    else
        stun:duration(duration)
    end
end

--highlights a string with |cffffcc00
---@type fun(s: string, y: boolean): string
function HL(s, y)
    return (y and ("|cffffcc00" .. s .. "|r")) or s
end

---@type fun(u: unit, id: integer, index: integer):number
function GetAbilityField(u, id, index)
    return BlzGetAbilityRealLevelField(BlzGetUnitAbility(u, id), SPELL_FIELD[index], 0)
end

---@type fun(itm: Item)
function ItemAddSpellDelayed(itm)
    for index = ITEM_ABILITY, ITEM_ABILITY2 do
        if ItemData[itm.id][index] ~= 0 then --ability exists
            local abilid = ItemData[itm.id][index * ABILITY_OFFSET]

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
    local data   = ItemData[itm.id][index * ABILITY_OFFSET .. "abil"] ---@type string 
    local id     = ItemData[itm.id][index * ABILITY_OFFSET] ---@type integer 
    local orig   = BlzGetAbilityExtendedTooltip(id, 0) ---@type string 
    local count  = 1
    local values = {} ---@type integer[] 

    values[0] = value

    --parse ability data
    for w in data:gmatch("(\x25-?\x25d+)") do
        values[count] = S2I(w)
        ItemData[itm.id][index * ABILITY_OFFSET + count] = values[count]
        count = count + 1
    end

    --parse ability tooltip and fill capture groups
    orig = orig:gsub("\x25$(\x25d+)", function(tag)
        if upper > 0 then
            return lower .. "-" .. upper
        else
            return values[S2I(tag) - 1] .. ""
        end
    end)

    return orig
end

---@type fun(itm: item, s: string)
function ParseItemTooltip(itm, s)
    local orig = s ~= "" and s or BlzGetItemExtendedTooltip(itm)
    local itemid = GetItemTypeId(itm)

    -- store original tooltip [id][0]
    ItemData[itemid][ITEM_TOOLTIP] = orig

    -- match balanced brackets
    orig = orig:gsub("(\x25b[])", function(contents)
        contents = contents:sub(2, -2)

        --get index and value
        local tag, suffix, value = contents:match("(\x25a+)([ \x25*])(\x25-?\x25d+)")
        local index = SAVE_TABLE.KEY_ITEMS[tag]

        --assign value
        ItemData[itemid][index] = S2I(value)
        --fixed toggle
        ItemData[itemid][index + BOUNDS_OFFSET * 6] = (suffix == "*") and 1 or 0

        --process affixes
        local affix = "([|=>\x25@#])([\x25w ]+)"
        local start = contents:find(affix)

        if start then
            contents = contents:sub(start)
            contents:gsub(affix, function(prefix, capture)

                --value range
                ItemData[itemid][index + BOUNDS_OFFSET] = (prefix == "|") and S2I(capture) or 0
                --flat per level
                ItemData[itemid][index + BOUNDS_OFFSET * 2] = (prefix == "=") and S2I(capture) or 0
                --flat per rarity
                ItemData[itemid][index + BOUNDS_OFFSET * 3] = (prefix == ">") and S2I(capture) or 0
                --percent effectiveness
                ItemData[itemid][index + BOUNDS_OFFSET * 4] = (prefix == "\x25") and S2I(capture) or 0
                --unlock at
                ItemData[itemid][index + BOUNDS_OFFSET * 5] = (prefix == "@") and S2I(capture) or 0
                --abilities
                ItemData[itemid][index * ABILITY_OFFSET] = (prefix == "#") and FourCC(capture:sub(1, 4)) or 0 --ID
                ItemData[itemid][index * ABILITY_OFFSET .. "abil"] = (prefix == "#") and capture:sub(6) or nil
            end)
        end
    end)
end

--parses brackets [] = normal boost {] = low boost \] = no boost > = no color
---@type fun(spell: Spell):string
function GetSpellTooltip(spell)
    local orig = SpellTooltips[spell.id][spell.ablev]
    local calc = {} ---@type number[]

    for i, v in ipairs(spell.values) do
        calc[i] = type(v) == "number" and v or type(v) == "function" and v(spell.pid) or 0
    end

    if #calc > 0 then
        local pattern = "(>?)([\\{\x25[]+)(.-)]"
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

---@type fun(u: unit, id: integer, dur: number, anim: integer, timescale: number)
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
            local tooltip = GetSpellTooltip(mySpell)

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
    local U = User.first

    while U do
        if TableHas(AZAZOTH_GROUP, U.player) then
            TableRemove(AZAZOTH_GROUP, U.player)

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
    return not (GetOwningPlayer(u) ~= pfoe or
    RectContainsUnit(gg_rct_Town_Boundry, u) or
    RectContainsUnit(gg_rct_Gods_Vision, u) or
    IsUnitType(u, UNIT_TYPE_MECHANICAL) == true or
    IsUnitType(u, UNIT_TYPE_HERO) == true)
end

---@type fun(x: number, y: number): rect?
function getRect(x, y)
    for i = 1, #AREAS do
        if GetRectMinX(AREAS[i]) <= x and x <= GetRectMaxX(AREAS[i]) and GetRectMinY(AREAS[i]) <= y and y <= GetRectMaxY(AREAS[i]) then
            return AREAS[i]
        end
    end

    return nil
end

---@param pid integer
function ExperienceControl(pid)
    local HeroLevel = GetHeroLevel(Hero[pid]) ---@type integer 
    local xpRate = 0 ---@type number 

    --get multiple of 5 from hero level
    if BaseID[pid] > 0 then
        xpRate = BaseExperience[(HeroLevel // 5) * 5] * HomeTable[BaseID[pid]].rate
    elseif HeroLevel < 15 then
        xpRate = 100
    end

    if BaseID[pid] <= 4 and HeroLevel >= 180 then
        xpRate = 0
    end

    if InColo[pid] then
        xpRate = xpRate * Colosseum_XP[pid] * (0.6 + 0.4 * ColoPlayerCount)
    elseif InStruggle[pid] then
        xpRate = xpRate * .3
    end

    XP_Rate[pid] = math.max(0, xpRate * (1. + 0.04 * PrestigeTable[pid][0]))
end

---@type fun(pid: integer)
function ConversionEffect(pid)
    local x = GetUnitX(Hero[pid])
    local y = GetUnitY(Hero[pid])

    for i = 1, 3 do
        for j = 1, i * 4 do
            local dist = i * 40
            local angle = 2. * bj_PI / (i * 4) * j
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", x + dist * Cos(angle), y + dist * Sin(angle)))
        end
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
        FloatingTextUnit(s, Hero[pid], 1.5, 75, -100, 9., 255, 255, 255, 0, false)
    else
        FloatingTextUnit(s, Hero[pid], 1.5, 75, -100, 8.5, 255, 255, 0, 0, false)
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

---@type fun(id: integer, x: number, y: number)
function AwardCrystals(id, x, y)
    local count = BossTable[id].crystal ---@type integer 

    if count == 0 then
        return
    end

    if HARD_MODE > 0 then
        count = count * 2
    end

    local u = User.first

    while u do
        if IsUnitInRangeXY(Hero[u.id], x, y, NEARBY_BOSS_RANGE) and GetHeroLevel(Hero[u.id]) >= BossTable[id].level then
            AddCurrency(u.id, CRYSTAL, count)
            FloatingTextUnit("+" .. (count) .. (count == 1 and " Crystal" or " Crystals"), Hero[u.id], 2.1, 80, 90, 9, 70, 150, 230, 0, false)
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
    local ug = CreateGroup()

    if b then
        GroupEnumUnitsInRange(ug, GetUnitX(gg_unit_H01T_0259), GetUnitY(gg_unit_H01T_0259), 250., Condition(isplayerunit))

        for target in each(ug) do
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
    ItemsDisabled[pid] = false

    for i = 0, 5 do
        SetItemDroppable(UnitItemInSlot(Hero[pid], i), true)
        SetItemDroppable(UnitItemInSlot(Backpack[pid], i), true)
    end
end

---@param pid integer
function DisableItems(pid)
    ItemsDisabled[pid] = true

    for i = 0, 5 do
        SetItemDroppable(UnitItemInSlot(Hero[pid], i), false)
        SetItemDroppable(UnitItemInSlot(Backpack[pid], i), false)
    end
end

---@type fun(n: integer, k: integer):integer
function BinomialCoefficient(n, k)
    local i = 0 ---@type integer 
    local result = 1 ---@type integer 

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

    ---@type fun():BezierCurve
    function thistype.create()
        local self = {
            numPoints = 0,
            pointX = {},
            pointY = {},
            X = 0.,
            Y = 0.
        }

        setmetatable(self, { __index = BezierCurve })

        return self
    end

    function thistype:destroy()
        self = nil
    end

    ---@param x number
    ---@param y number
    function thistype:addPoint(x, y)
        self.pointX[self.numPoints] = x
        self.pointY[self.numPoints] = y

        self.numPoints = self.numPoints + 1
    end

    ---@param t number
    function thistype:calcT(t)
        local n       = self.numPoints - 1 ---@type integer 
        local resultX = 0. ---@type number 
        local resultY = 0. ---@type number 
        local blend   = 0. ---@type number 

        for i = 0, n do
            blend = BinomialCoefficient(n, i) * t ^ i * (1 - t) ^ (n - i)
            resultX = resultX + blend * self.pointX[i]
            resultY = resultY + blend * self.pointY[i]
        end

        self.X = resultX
        self.Y = resultY
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
    local r = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_RED) ---@type integer 
    local g = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_BLUE) ---@type integer 
    local b = BlzGetUnitIntegerField(pt.target, UNIT_IF_TINTING_COLOR_GREEN) ---@type integer 

    if GetUnitAbilityLevel(pt.target, FourCC('Bmag')) > 0 then --magnetic stance
        r = 255 g = 25 b = 25
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

---@type fun(u: unit, dur: number, fade: boolean)
function Fade(u, dur, fade)
    local pid = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
    local pt  = TimerList[pid]:add()

    pt.target = u
    if fade then
        pt.agi = 1
    else
        pt.agi = -1
    end
    pt.dur = dur
    pt.int = 0

    pt.timer:callPeriodically(FPS_32, nil, ApplyFade, pt)
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
    local pid = GetPlayerId(GetOwningPlayer(u)) + 1
    local uid = GetUnitTypeId(u)

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
            local pt = TimerList[pid]:add()
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
    local lev = GetHeroLevel(pt.target) ---@type integer 

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
        SetHeroXP(pt.target, R2I(RequiredXP(lev - 1) + ((lev + 1) * pt.dur * 100 / pt.time) - 1), false)
    end
end

---@param p player
function CleanupSummons(p)
    for i = 1, #SummonGroup do
        local target = SummonGroup[i]
        if GetOwningPlayer(target) == p then
            SummonExpire(target)
        end
    end
end

---@param pid integer
function RecallSummons(pid)
    local p = Player(pid - 1) ---@type player 
    local x = GetUnitX(Hero[pid]) + 200 * Cos(bj_DEGTORAD * GetUnitFacing(Hero[pid])) ---@type number 
    local y = GetUnitY(Hero[pid]) + 200 * Sin(bj_DEGTORAD * GetUnitFacing(Hero[pid])) ---@type number 

    for i = 1, #SummonGroup do
        local target = SummonGroup[i]
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
        if GetOwningPlayer(GetFilterUnit()) == Player(passedValue[#passedValue] - 1) then
            return true
        end
    end

    return false
end

---@return boolean
function FilterEnemyDead()
    if GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Aloc')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[#passedValue] - 1)) == false then
            return true
        end
    end

    return false
end

---@type fun():boolean
function FilterEnemy()
    local u = GetFilterUnit()

    if UnitAlive(u) and
        IsUnitEnemy(u, Player(passedValue[#passedValue] - 1)) and
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
        IsUnitAlly(u, Player(passedValue[#passedValue] - 1)) == true and
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
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[#passedValue] - 1)) == true then
            return true
        end
    end

    return false
end

---@return boolean
function FilterEnemyAwake()
    if UnitAlive(GetFilterUnit()) and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Avul')) == 0 and GetUnitAbilityLevel(GetFilterUnit(),FourCC('Aloc')) == 0 and GetUnitTypeId(GetFilterUnit()) ~= DUMMY then
        if IsUnitAlly(GetFilterUnit(), Player(passedValue[#passedValue] - 1)) == false and UnitIsSleeping(GetFilterUnit()) == false then
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
    local U = User.first

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
            local looptotal = ColoCount_main[Wave]
            SpawnColoUnits(ColoEnemyType_main[Wave],looptotal)
            if ColoCount_sec[Wave] > 0 then
                looptotal= ColoCount_sec[Wave]
                SpawnColoUnits(ColoEnemyType_sec[Wave],looptotal)
            end
            ColoWaveCount = ColoWaveCount + 1
            DoFloatingTextCoords("Wave " .. (ColoWaveCount), GetLocationX(ColosseumCenter), GetLocationY(ColosseumCenter), 3.20, 32.0, 0, 18.0, 255, 0, 0, 0)
        elseif ColoCount_main[Wave] <= 0 then
            U = User.first

            GoldWon_Colo= R2I(GoldWon_Colo * 1.2)

            while U do
                if InColo[U.id] then
                    InColo[U.id] = false
                    ColoPlayerCount = ColoPlayerCount - 1
                    DisplayTimedTextToPlayer(U.player,0,0, 10, "You have successfully cleared the Colosseum and received a 20\x25 gold bonus.")
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
end

---@type fun(tbl: table, fadedur: number, fade: boolean)
local applyblackmask = function(tbl, fadedur, fade)
    for i = 1, #tbl do
        player_fog[GetPlayerId(tbl[i]) + 1] = false

        if GetLocalPlayer() == tbl[i] then
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
end

---@type fun(tbl: table, fadein: number, fadeout: number)
function BlackMask(tbl, fadein, fadeout)
    applyblackmask(tbl, fadein, true)
    TimerQueue:callDelayed(fadein, applyblackmask, tbl, fadeout, false)
end

---@type fun(tbl: table, x: number, y: number, cam: rect)
function MovePlayers(tbl, x, y, cam)
    for i = 1, #tbl do
        local pid = GetPlayerId(tbl[i]) + 1
        SetUnitPosition(Hero[pid], x, y)
        DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\MassTeleport\\MassTeleportCaster.mdl", Hero[pid], "origin"))
        SetCameraBoundsRectForPlayerEx(tbl[i], cam)
        PanCameraToTimedForPlayer(tbl[i], GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
    end
end

---@type fun(flag: integer)
function AdvanceStruggle(flag)
    local U = User.first
    local ug = CreateGroup()

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
            for target in each(ug) do
                if GetOwningPlayer(target) == U.player then
                    RemoveUnit(target)
                end
            end
        end
        U = U.next
    end

    DestroyGroup(ug)

    Struggle_WaveN = Struggle_WaveN + 1
    Struggle_WaveUCN = Struggle_WaveUN[Struggle_WaveN]
    if Struggle_Pcount == 0 then
        ClearStruggle()
    else
        if Struggle_WaveU[Struggle_WaveN] <= 0 then -- Struggle Won
            GoldWon_Struggle= R2I(GoldWon_Struggle * 1.5)
            SetTextTagTextBJ(StruggleText, ("Gold won: " .. (GoldWon_Struggle)), 10.00)

            U = User.first

            while U do
                if InStruggle[U.id] then
                    InStruggle[U.id] = false
                    Struggle_Pcount = Struggle_Pcount - 1
                    DisplayTextToPlayer(U.player, 0, 0, "50\x25 bonus gold for victory!")
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
    local itemsNeeded   =__jarray(0) ---@type integer[] 
    local itemsHeld     =__jarray(0) ---@type integer[] 
    local itemType      =__jarray(0) ---@type integer[] 
    local owner         = GetOwningPlayer(creatingunit) ---@type player 
    local pid           = GetPlayerId(owner) + 1 ---@type integer 
    local fail          = false ---@type boolean 
    local levelreq      = 0 ---@type integer 
    local success       = false ---@type boolean 
    local itm ---@type item 
    local origcount     = __jarray(0) ---@type integer[]  
    local origowner     = 0 ---@type integer
    local goldcost      = R2I(ModuloReal(platCost, R2I(math.max(platCost, 1))) * 1000000) ---@type integer 
    local lumbercost    = R2I(ModuloReal(arcCost, R2I(math.max(arcCost, 1))) * 1000000) ---@type integer 

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

    for i = 0, 5 do
        for j = 0, 5 do
            if creatingunit == ASHEN_VAT then --vat
                itm = UnitItemInSlot(creatingunit, j)
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
                itm = UnitItemInSlot(Hero[pid], j)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        itemsHeld[i] = itemsHeld[i] + 1
                    end
                end
                itm = UnitItemInSlot(Backpack[pid], j)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        itemsHeld[i] = itemsHeld[i] + 1
                    end
                end
            end
        end
    end

    for i = 0, 5 do
        if itemsHeld[i] < itemsNeeded[i] then
            fail = true
            break
        end
    end

    for i = 1, 6 do --disallow multiple bound items
        if origcount[i] > 0 then
            if origowner > 0 and origowner ~= i then
                origowner = -1
                fail = true
                break
            end
            origowner = i
        end
    end

    if hidemessage then --mostly for ashen vat
        if fail then
            if origowner == -1 then
                DisplayTextToForce(FORCE_PLAYING, "The Ashen Vat will not accept bound items from multiple players.")
            end
        else
            success = true
            for i = 0, 5 do
                if itemType[i] > 0 then
                    for _ = 1, itemsNeeded[i] do
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
            for i = 0, 5 do
                for _ = 1, itemsNeeded[i] do
                    if itemType[i] > 0 then
                        if PlayerHasItemType(pid, itemType[i]) then
                            GetItemFromPlayer(pid, itemType[i]):useInRecipe()
                        end
                    end
                end
            end

            if FINAL_ID ~= 0 then
                local final = PlayerAddItemById(pid, FINAL_ID)
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
    local i = PrestigeTable[pid][id] ---@type integer 

    PrestigeTable[pid][id] = IMinBJ(2, rank + i)
    PrestigeTable[pid][0] = PrestigeTable[pid][0] + IMinBJ(2, rank + i)
end

---@param pid integer
function SetPrestigeEffects(pid)
    local name   = User[Player(pid - 1)].name
    local i      = PUBLIC_SKINS + 2
    local j      = 1
    local count  = 0
    local PT     = PrestigeTable

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
    VoteYay = 0
    VoteNay = 0

    for i = 1, PLAYER_CAP do
        I_VOTED[i] = false
    end
end

function Votekick()
    local U = User.first

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
    local pid   = GetPlayerId(GetTriggerPlayer()) + 1
    local dw    = DialogWindow[pid]
    local index = dw:getClickedIndex(GetClickedButton())

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
    local s  = "" ---@type string 
    local s2 = "" ---@type string 

    --heart of the demon prince
    if HasItemType(Hero[pid], FourCC('I04Q')) then
        local itm = Item[GetItemFromUnit(Hero[pid], FourCC('I04Q'))]

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
    local s = __jarray("") ---@type string[] 
    local u = User.first

    while u do
        local unlocked = 0

        for j = PUBLIC_SKINS + 2, TOTAL_SKINS do
            if CosmeticTable[u.name][j] > 0 then
                unlocked = unlocked + 1
            end
        end

        if unlocked >= 17 then
            s[u.id] = "Change your backpack's appearance.\n\nUnlocked skins: |c0000ff4017/17"
        else
            s[u.id] = "Change your backpack's appearance.\n\nUnlocked skins: " .. (unlocked) .. "/17"
        end
        u = u.next
    end

    BlzSetAbilityExtendedTooltip(FourCC('A0KX'), s[GetPlayerId(GetLocalPlayer()) + 1], 0)
end

---@param p player
function ActivatePrestige(p)
    local pid = GetPlayerId(p) + 1 ---@type integer 

    if Profile[pid].hero.prestige > 0 then
        DisplayTimedTextToPlayer(p, 0, 0, 20.00, "You can not prestige this character again.")
    else
        Item[GetItemFromUnit(Hero[pid], FourCC('I0NN'))]:destroy()
        Profile[pid].hero.prestige = 1 + Profile[pid].hero.hardcore
        Profile[pid]:saveCharacter()

        AllocatePrestige(pid, Profile[pid].hero.prestige, Profile[pid].hero.id)

        DisplayTimedTextToForce(FORCE_PLAYING, 30.00, User[pid - 1].nameColored .. " has prestiged their hero and achieved rank |cffffcc00" .. (PrestigeTable[pid][0]) .. "|r prestige!")
        DisplayTimedTextToPlayer(p, 0, 0, 20.00, "|cffffcc00Hero Prestige:|r " .. (Profile[pid].hero.prestige))
        UpdatePrestigeTooltips()

        for i = 0, 5 do
            Item[UnitItemInSlot(Hero[pid], i)]:unequip()
        end

        SetPrestigeEffects(pid)

        for i = 0, 5 do
            Item[UnitItemInSlot(Hero[pid], i)]:equip()
        end
    end
end

---@type fun(enemy: unit, player: unit)
function SwitchAggro(enemy, player)
    IssueTargetOrder(enemy, "smart", player)
    Threat[enemy][player] = 0
    Threat[enemy].target = player
    Threat[enemy]["switching"] = 0
end

---@type fun(enemy: unit, player: unit)
function ChangeAggro(enemy, player)
    local dummy = GetDummy(GetUnitX(enemy), GetUnitY(enemy), 0, 0, 1.5)
    BlzSetUnitSkin(dummy, FourCC('h00N'))
    if GetLocalPlayer() == Player(pid - 1) then
        BlzSetUnitSkin(dummy, FourCC('h01O'))
    end
    SetUnitScale(dummy, 2.5, 2.5, 2.5)
    SetUnitFlyHeight(dummy, 250.00, 0.)
    SetUnitAnimation(dummy, "birth")
    TimerQueue:callDelayed(1.5, SwitchAggro, enemy, player)
    Threat[enemy]["switching"] = 1
end

---@type fun(hero: unit, pid: integer, aoe: number, bossaggro: boolean, allythreat: integer, herothreat: integer)
function Taunt(hero, pid, aoe, bossaggro, allythreat, herothreat)
    local enemyGroup = CreateGroup()
    local allyGroup  = CreateGroup()

    MakeGroupInRange(pid, enemyGroup, GetUnitX(hero), GetUnitY(hero), aoe, Condition(FilterEnemy))
    MakeGroupInRange(pid, allyGroup, GetUnitX(hero), GetUnitY(hero), aoe, Condition(FilterAlly))

    for enemy in each(enemyGroup) do
        local threat = Threat[enemy][hero]
        Threat[enemy][hero] = IMaxBJ(0, threat + herothreat)
        --boss taunting
        if IsBoss(enemy) ~= -1 then
            --instant aggro grab
            if bossaggro then
                IssueTargetOrder(enemy, "smart", hero)
                Threat[enemy].target = hero
            end
            --switch target when threat cap reached
            if threat >= THREAT_CAP and Threat[enemy].target ~= hero then
                ChangeAggro(enemy, hero)
            end
            --lower everyone else's threat 
            for ally in each(allyGroup) do
                if ally ~= hero then
                    Threat[enemy][ally] = IMaxBJ(0, Threat[enemy][ally] - allythreat)
                end
            end
        --so that cast aggro doesnt taunt normal enemies
        elseif allythreat > 0 then
            IssueTargetOrder(target, "smart", hero)
            Threat[target].target = hero
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
    local ug    = CreateGroup()
    local x     = GetUnitX(source) ---@type number 
    local y     = GetUnitY(source) ---@type number 
    local index = -1

    GroupEnumUnitsInRange(ug, x, y, dist, Filter(ProximityFilter))

    for i, prox in ieach(ug) do
        --dont acquire the same target
        if SquareRoot(Pow(x - GetUnitX(prox), 2) + Pow(y - GetUnitY(prox), 2)) < dist and Threat[source].target ~= target then
            dist = SquareRoot(Pow(x - GetUnitX(prox), 2) + Pow(y - GetUnitY(prox), 2))
            index = i
        end
    end

    if index ~= -1 then
        target = BlzGroupUnitAt(ug, index)
    end

    DestroyGroup(ug)
    return target
end

---@type fun(pt: PlayerTimer)
function RunDropAggro(pt)
    local ug = CreateGroup()

    MakeGroupInRange(pt.pid, ug, GetUnitX(pt.source), GetUnitY(pt.source), 800., Condition(FilterEnemy))

    for target in each(ug) do
        if GetUnitTarget(target) == pt.source then
            local prox = AcquireProximity(target, pt.source, 800.)
            IssueTargetOrder(target, "smart", prox)
            Threat[target].target = prox
            break
            --call DEBUGMSG("aggro to " + GetUnitName(target2))
        end
    end

    pt:destroy()

    DestroyGroup(ug)
end

---@type fun(pid: integer, x: number, y: number, percenthp: number, percentmana: number)
function RevivePlayer(pid, x, y, percenthp, percentmana)
    local p = Player(pid - 1) ---@type player 

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
    SetCameraBoundsRectForPlayerEx(Player(pt.pid - 1), MAIN_MAP.rect)
    PanCameraToTimedLocForPlayer(Player(pt.pid - 1), TownCenter, 0)

    DestroyTimerDialog(RTimerBox[pt.pid])

    pt:destroy()
end

---@type fun(i: integer):string
function IntegerToTime(i)
    local hours = math.floor(i / 3600)
    local minutes = math.floor(ModuloInteger(i, 3600) / 60)
    local seconds = ModuloInteger(i, 60)

    return string.format("\x2502d:\x2502d:\x2502d", hours, minutes, seconds)
end

---@param mana number
---@return integer
function Roundmana(mana)
    if mana > 99999 then
        return 1000 * (mana // 1000)
    end

    return R2I(mana)
end

---@param u unit
function BackpackLimit(u)
    BlzUnitDisableAbility(u, FourCC('A083'), true, true) --holy light
    BlzUnitDisableAbility(u, FourCC('A02A'), true, true) --instil fear
    BlzUnitDisableAbility(u, FourCC('A0IS'), true, true) --slaughter bow
    BlzUnitDisableAbility(u, FourCC('A00E'), true, true) --final blast
    BlzUnitDisableAbility(u, FourCC('A00I'), true, true) --health potion
    BlzUnitDisableAbility(u, FourCC('A00O'), true, true) --mana potion
    BlzUnitDisableAbility(u, FourCC('A0CQ'), true, true) --necklace vision
    BlzUnitDisableAbility(u, FourCC('AIfw'), true, true) --fire orb
    BlzUnitDisableAbility(u, FourCC('AIft'), true, true) --cold orb
    BlzUnitDisableAbility(u, FourCC('A0CD'), true, true) --da's dingo
    BlzUnitDisableAbility(u, FourCC('AIpv'), true, true) --vampiric potion
    BlzUnitDisableAbility(u, FourCC('AIv2'), true, true) --invisibility potion
    BlzUnitDisableAbility(u, FourCC('A055'), true, true) --darkest of darkness
    BlzUnitDisableAbility(u, FourCC('A01S'), true, true) --blink thanatos boots
    BlzUnitDisableAbility(u, FourCC('A03D'), true, true) --blink savior's dagger
    BlzUnitDisableAbility(u, FourCC('A0SX'), true, true) --astral freeze
    BlzUnitDisableAbility(u, FourCC('A0B5'), true, true) --azazoth hammer
    BlzUnitDisableAbility(u, FourCC('A07G'), true, true) --azazoth sword
    --orb effects
    UnitRemoveAbility(u, FourCC('A00D')) --wings
    UnitRemoveAbility(u, FourCC('A00V')) --wings rare
    UnitRemoveAbility(u, FourCC('A00Y')) --wings legendary
    UnitRemoveAbility(u, FourCC('A0CQ')) --necklace vision
    UnitRemoveAbility(u, FourCC('AIfw')) --fire orb
    UnitRemoveAbility(u, FourCC('AIft')) --cold orb
    UnitRemoveAbility(u, FourCC('A0CD')) --da's dingo
    UnitRemoveAbility(u, FourCC('AIlb')) --lightning orb
    UnitRemoveAbility(u, FourCC('AIsb')) --slow orb
    UnitRemoveAbility(u, FourCC('AIdn')) --shadow orb
end

---@param pid integer
function UpdateManaCosts(pid)
    local maxmana = BlzGetUnitMaxMana(Hero[pid])  ---@type integer 

    if HeroID[pid] == HERO_ASSASSIN then
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
