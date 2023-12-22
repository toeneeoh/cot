if Debug then Debug.beginFile 'Users' end

OnInit.global("Users", function()

    FORCE_PLAYING = CreateForce() ---@type force 
    LEAVE_TRIGGER = CreateTrigger() ---@type trigger
    OriginalHex = {} ---@type string[] 

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
    User = {
        first = nil,
        AmountPlaying = 0
    }

    do
        local thistype = User

        ---@type fun():User
        function thistype.create()
            local self = {}
            setmetatable(self, { __index = User })

            -- Increment the number of players when a new user is created
            thistype.AmountPlaying = User.AmountPlaying + 1

            return self
        end

        -- metatable to handle custom indices (User[1], User[Player(1)])
        local mt = {
            __index = function(tbl, key)
                if type(key) == "number" then
                    return rawget(tbl, key)
                elseif type(key) == "userdata" then
                    return rawget(tbl, GetPlayerId(key))
                end
            end
        }

        -- Set metatable for the User table
        setmetatable(thistype, mt)

        ---@type fun()
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
                local u = thistype[p] ---@class User

                ForceRemovePlayer(FORCE_PLAYING, p)

                -- recycle index
                thistype.AmountPlaying = thistype.AmountPlaying - 1

                if (thistype.AmountPlaying == 1) then
                    u.prev.next = nil
                    u.next.prev = nil
                else
                    u.prev.next = u.next
                    u.next.prev = u.prev
                end

                u.isPlaying = false
            end

            return false
        end

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

        local p ---@type player 

        for i = 0, bj_MAX_PLAYERS - 1 do
            p = Player(i)

            if (GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
                thistype[i] = thistype.create()
                thistype[i].player = p
                thistype[i].id = i + 1
                thistype[i].isPlaying = true
                thistype[i].color = GetPlayerColor(p)
                thistype[i].name = GetPlayerName(p)
                thistype[i].hex = OriginalHex[i]
                thistype[i].nameColored = thistype[i].hex .. thistype[i].name .. "|r"

                thistype.last = thistype[i]

                if not thistype.first then
                    thistype.first = thistype[i]
                    thistype[i].next = nil
                    thistype[i].prev = nil
                else
                    thistype[i].prev = thistype[thistype.AmountPlaying - 1]
                    thistype[i].next = nil
                end

                TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_LEAVE)
                TriggerRegisterPlayerEvent(LEAVE_TRIGGER, p, EVENT_PLAYER_DEFEAT)

                ForceAddPlayer(FORCE_PLAYING, p)
            end
        end

        TriggerAddCondition(LEAVE_TRIGGER, Filter(thistype.onLeave))
    end
end)

if Debug then Debug.endFile() end
