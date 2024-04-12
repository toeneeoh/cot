--[[
    users.lua

    A module that creates a User interface and a linked structure such that
    player manipulation is simpler.
]]

OnInit.global("Users", function()

    FORCE_PLAYING = CreateForce() ---@type force 
    LEAVE_TRIGGER = CreateTrigger()
    OriginalHex = {} ---@type string[] 
        OriginalHex[0]  = "|cffff0303"
        OriginalHex[1]  = "|cff0042ff"
        OriginalHex[2]  = "|cff1ce6b9"
        OriginalHex[3]  = "|cff540081"
        OriginalHex[4]  = "|cfffffc01"
        OriginalHex[5]  = "|cfffe8a0e"
        OriginalHex[6]  = "|cff20c000"
        OriginalHex[7]  = "|cffe55bb0"
        OriginalHex[8]  = "|cff959697"
        OriginalHex[9]  = "|cff7ebff1"
        OriginalHex[10] = "|cff106246"
        OriginalHex[11] = "|cff4e2a04"
        OriginalHex[12] = "|cff9B0000"
        OriginalHex[13] = "|cff0000C3"
        OriginalHex[14] = "|cff00EAFF"
        OriginalHex[15] = "|cffBE00FE"
        OriginalHex[16] = "|cffEBCD87"
        OriginalHex[17] = "|cffF8A48B"
        OriginalHex[18] = "|cffBFFF80"
        OriginalHex[19] = "|cffDCB9EB"
        OriginalHex[20] = "|cff282828"
        OriginalHex[21] = "|cffEBF0FF"
        OriginalHex[22] = "|cff00781E"
        OriginalHex[23] = "|cffA46F33"

    OriginalRGB = {}
        OriginalRGB[0] =  { r = 255, g = 3,   b = 3 }
        OriginalRGB[1] =  { r = 0,   g = 66,  b = 255 }
        OriginalRGB[2] =  { r = 28,  g = 230, b = 185 }
        OriginalRGB[3] =  { r = 84,  g = 0,   b = 129 }
        OriginalRGB[4] =  { r = 255, g = 252, b = 0 }
        OriginalRGB[5] =  { r = 254, g = 138, b = 14 }
        OriginalRGB[6] =  { r = 32,  g = 192, b = 0 }
        OriginalRGB[7] =  { r = 229, g = 91,  b = 176 }
        OriginalRGB[8] =  { r = 149, g = 150, b = 151 }
        OriginalRGB[9] =  { r = 126, g = 191, b = 241 }
        OriginalRGB[10] = { r = 16,  g = 98,  b = 70 }
        OriginalRGB[11] = { r = 74,  g = 42,  b = 4 }

    ---@class User
    ---@field player player
    ---@field first User
    ---@field id integer
    ---@field next User
    ---@field prev User
    ---@field color playercolor
    ---@field colorUnits function
    ---@field name string
    ---@field nameColored string
    ---@field onLeave function
    ---@field create function
    User = setmetatable({},
        -- handle player reference (User[Player(1)])
        { __index = function(tbl, key)
            if type(key) == "userdata" then
                return rawget(tbl, GetPlayerId(key))
            end
        end})
    do
        local thistype = User
        local mt = { __index = User }
        thistype.first = nil
        thistype.AmountPlaying = 0

        function thistype:colorUnits()
            local ug = CreateGroup()

            GroupEnumUnitsOfPlayer(ug, self.player, nil)

            local u = FirstOfGroup(ug)
            while u do
                SetUnitColor(u, self.color)
                GroupRemoveUnit(ug, u)
                u = FirstOfGroup(ug)
            end

            DestroyGroup(ug)
        end

        ---@return boolean
        function thistype.onLeave()
            local p = GetTriggerPlayer()

            if BlzForceHasPlayer(FORCE_PLAYING, p) then
                local u = thistype[p]

                ForceRemovePlayer(FORCE_PLAYING, p)

                -- recycle index
                thistype.AmountPlaying = thistype.AmountPlaying - 1

                if (thistype.AmountPlaying == 1) then
                    if u.prev then
                        u.prev.next = nil
                    end
                    if u.next then
                        u.next.prev = nil
                    end
                else
                    if u.prev then
                        u.prev.next = u.next
                    end
                    if u.next then
                        u.next.prev = u.prev
                    end
                end

                u.isPlaying = false
            end

            return false
        end

        for i = 0, bj_MAX_PLAYERS - 1 do
            local p = Player(i)

            if (GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                local self = {
                    player = p,
                    id = i + 1,
                    isPlaying = true,
                    color = GetPlayerColor(p),
                    name = GetPlayerName(p),
                    hex = OriginalHex[i],
                }

                self.nameColored = self.hex .. self.name .. "|r"

                thistype[i] = self
                setmetatable(self, mt)

                thistype.last = self

                if not thistype.first then
                    thistype.first = self
                    self.next = nil
                    self.prev = nil
                else
                    self.prev = thistype[thistype.AmountPlaying - 1]
                    self.prev.next = self
                    self.next = nil
                end

                -- Increment the number of players when a new user is created
                thistype.AmountPlaying = thistype.AmountPlaying + 1

                TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_LEAVE)
                TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_DEFEAT)

                ForceAddPlayer(FORCE_PLAYING, p)
            end
        end

        TriggerAddCondition(LEAVE_TRIGGER, Filter(thistype.onLeave))
    end
end, Debug.getLine())
