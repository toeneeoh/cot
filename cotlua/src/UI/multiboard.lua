--[[
    multiboard.lua

    This module defines the MULTIBOARD that players interact with and provides functions to
    create and modify the UI.

    Features:
        -Player list
        -Dungeon queue
        -Boss stats / threat meter
        -Damage log
]]

OnInit.final("Multiboard", function(Require)
    Require("TimerQueue")
    Require("Dungeons")

    ---@class MULTIBOARD
    ---@field lookingAt integer[]
    ---@field bodies table
    ---@field MAIN table
    ---@field QUEUE table
    ---@field THREAT table
    ---@field DAMAGE table
    ---@field minimize function
    ---@field next function
    ---@field ROW_WIDTH number
    ---@field ROW_HEIGHT number
    ---@field ICON_SIZE number
    ---@field BUTTON_SIZE number
    MULTIBOARD = {}

    FLAG_DEALT = 0x40
    FLAG_TAKEN = 0x80
    FLAG_SUMMON = 0x100
    DAMAGE_LOG_FLAGS = __jarray(0x1C0) ---@type integer[]
    DAMAGE_LOG = CircularArrayList.create(500) ---@type CircularArrayList

    do
        local MB = MULTIBOARD
        local ROW_WIDTH = 0.3
        local ROW_HEIGHT = 0.035
        local ROW_SPACING = 0.003
        local ICON_SIZE = 0.011
        local BUTTON_SIZE = 0.015
        local INITIAL_ROW_Y_OFFSET = 0.015

        MB.ROW_WIDTH = ROW_WIDTH
        MB.ROW_HEIGHT = ROW_HEIGHT
        MB.ICON_SIZE = ICON_SIZE
        MB.BUTTON_SIZE = BUTTON_SIZE

        --current mb body a player is looking at
        MB.lookingAt = __jarray(1) ---@type integer[]

        --1 = main, 2, ready queue, 3 = threat, 4 = damage log
        MB.bodies = {} ---@type table[]

        ---@type fun(columns: integer): table
        function MB.makeBody(columns)
            local self = {
                index = #MB.bodies + 1,
                frame = BlzCreateFrame("ListBoxWar3", MB.main, 0, 0),
                available = {}, ---@type boolean[]
                rows = {},
                rowCount = 0,
                columnCount = columns,
            }

            BlzFrameClearAllPoints(self.frame)
            BlzFrameSetPoint(self.frame, FRAMEPOINT_TOPLEFT, MB.main, FRAMEPOINT_BOTTOMLEFT, 0, 0.01)
            BlzFrameSetVisible(self.frame, false)
            BlzFrameSetEnable(self.frame, false)

            MB.bodies[self.index] = self

            --returns an element at (x, y)
            ---@type fun(self: self, x: integer, y: integer): table
            function self:get(x, y)
                return self.rows[x].columns[y]
            end

            --displays body to a player
            function self:display(pid)
                self:refresh()

                local index = MB.lookingAt[pid]
                MB.lookingAt[pid] = self.index

                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(MB.bodies[index].frame, false)
                    BlzFrameSetVisible(self.frame, true)
                    BlzFrameSetTexture(MB.minimize_backdrop, "war3mapImported\\minimize.blp", 0, true)
                    BlzFrameSetText(MB.name, self.title)
                end
            end

            --called on display to ensure body is proper dimensions
            function self:refresh()
                --height based on row heights
                local height = 0

                for i = 1, self.rowCount do
                    height = height + self.rows[i].height
                end

                BlzFrameSetSize(self.frame, 0.3, height + INITIAL_ROW_Y_OFFSET)
            end

            --method operators for initializing different UI elements
            local mt = {
                __newindex = function(column, key, val)
                local frame

                --val[1] = x-offset, val[2] = y-offset, val[3] = width, val[4] = height
                if key == "text" then
                    frame = BlzCreateFrameByType("TEXT", "name", column.body.frame, "", 0)
                    BlzFrameSetText(frame, "")
                    BlzFrameSetEnable(frame, false)
                elseif key == "textarea" then
                    frame = BlzCreateFrame("MBTextArea", column.body.frame, 0, 0)
                    --BlzFrameSetEnable(frame, false)
                elseif key == "icon" then
                    frame = BlzCreateFrameByType("BACKDROP", "name", column.body.frame, "", 0)
                    BlzFrameSetEnable(frame, false)
                    BlzFrameSetTexture(frame, "trans32.blp", 0, true)
                elseif key == "radiobutton" then --checked by default
                    frame = BlzCreateFrame("RadioCheckedButton", column.body.frame, 0, 0)
                elseif key == "button" then
                    frame = BlzCreateFrameByType("GLUETEXTBUTTON", "", column.body.frame, "ScriptDialogButton", 0)
                    BlzFrameSetScale(frame, 0.7)
                elseif key == "checkbox" then --unchecked by default
                    frame = BlzCreateFrame("EscMenuCheckBoxTemplate", column.body.frame, 0, 0)
                end

                if frame ~= nil then
                    BlzFrameSetSize(frame, val[3], val[4])

                    local height = (column.parent.pos == 1 and INITIAL_ROW_Y_OFFSET) or ROW_SPACING
                    column.parent.height = math.max(column.parent.height, val[4] + val[2] + height)

                    for j = 1, column.parent.pos - 1 do
                        height = height + column.body.rows[j].height
                    end

                    --align frame with topleft of body frame using x-offset and y-offset of previous rows' height
                    BlzFrameSetPoint(frame, FRAMEPOINT_TOPLEFT, column.body.frame, FRAMEPOINT_TOPLEFT, val[1], -val[2] - height)

                    --two name references
                    rawset(column, key, frame)
                    rawset(column, "frame", frame)
                else
                    rawset(column, key, val)
                    end
                end
            }

            --adds set number of rows to a body
            ---@type fun(self: self, num: integer)
            function self:addRows(num)
                for _ = 1, num do
                    self.rowCount = self.rowCount + 1

                    local row = {
                        pos = self.rowCount,
                        width = ROW_WIDTH,
                        height = ROW_SPACING,
                        columns = {},
                    }

                    self.rows[self.rowCount] = row

                    for i = 1, self.columnCount do
                        row.columns[i] = {
                            body = self,
                            parent = row,
                        }

                        setmetatable(row.columns[i], mt)
                    end --end column loop
                end
            end

            --delete a set number of rows from the end
            ---@type fun(self: self, num: integer)
            function self:delRows(num)
                for i = self.rowCount, self.rowCount - num + 1, -1 do
                    local row = self.rows[i]

                    for col = 1, self.columnCount do
                        BlzDestroyFrame(row.columns[col].frame)
                    end

                    self.rows[i] = nil
                end

                self.rowCount = self.rowCount - num
            end

            return self
        end

        --minimizes the multiboard for a player
        function MB.minimize(pid)
            if Player(pid - 1) == GetLocalPlayer() then
                if BlzFrameIsVisible(MB.bodies[MB.lookingAt[pid]].frame) then
                    BlzFrameSetVisible(MB.bodies[MB.lookingAt[pid]].frame, false)
                    BlzFrameSetTexture(MB.minimize_backdrop, "war3mapImported\\expand.blp", 0, true)
                else
                    BlzFrameSetVisible(MB.bodies[MB.lookingAt[pid]].frame, true)
                    BlzFrameSetTexture(MB.minimize_backdrop, "war3mapImported\\minimize.blp", 0, true)
                end
            end
        end

        function MB.onMinimize()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            if GetTriggerPlayer() == GetLocalPlayer() then
                BlzFrameSetEnable(BlzGetTriggerFrame(), false)
                BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            end

            MB.minimize(pid)
        end

        --opens the next multiboard page for a player
        function MB.next(pid)
            BlzFrameSetVisible(MB.bodies[MB.lookingAt[pid]].frame, false)

            repeat
                MB.lookingAt[pid] = (MB.lookingAt[pid] + 1 > #MB.bodies and 1) or MB.lookingAt[pid] + 1
            until MB.bodies[MB.lookingAt[pid]].available[pid]

            MB.bodies[MB.lookingAt[pid]]:display(pid)
        end

        function MB.onNext()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            if GetTriggerPlayer() == GetLocalPlayer() then
                BlzFrameSetEnable(BlzGetTriggerFrame(), false)
                BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            end

            MB.next(pid)
        end

        --define multiboard frames
        MB.frame = BlzCreateFrameByType("FRAME", "", BlzGetFrameByName("ConsoleUIBackdrop", 0), "", 0)
        --MB.frame = BlzCreateFrame("QuestButtonDisabledBackdropTemplate", BlzGetFrameByName("ConsoleUIBackdrop", 0), 0, 0)
        MB.main = BlzCreateFrame("ListBoxWar3", MB.frame, 0, 0)
        BlzFrameSetSize(MB.main, ROW_WIDTH, ROW_HEIGHT)
        BlzFrameSetAbsPoint(MB.main, FRAMEPOINT_TOPRIGHT, 0.925, 0.6)
        BlzFrameSetEnable(MB.main, false)

        MB.name = BlzCreateFrameByType("TEXT", "name", MB.main, "", 0)
        BlzFrameClearAllPoints(MB.name)
        BlzFrameSetPoint(MB.name, FRAMEPOINT_CENTER, MB.main, FRAMEPOINT_CENTER, 0, 0)

        --MB.minimize_button = BlzCreateFrame("GLUEBUTTON", MB.main, 0, 0)
        MB.minimize_button = BlzCreateFrameByType("GLUEBUTTON", "name", MB.main, "ScoreScreenTabButtonTemplate", 0)
        BlzFrameClearAllPoints(MB.minimize_button)
        BlzFrameSetPoint(MB.minimize_button, FRAMEPOINT_RIGHT, MB.main, FRAMEPOINT_RIGHT, -0.04, 0)
        BlzFrameSetSize(MB.minimize_button, 0.015, 0.015)
        FrameAddSimpleTooltip(MB.minimize_button, "", "Minimize '.'", true, FRAMEPOINT_TOPRIGHT, FRAMEPOINT_BOTTOMLEFT)

        MB.minimize_backdrop = BlzCreateFrameByType("BACKDROP", "name", MB.minimize_button, "", 0)
        BlzFrameClearAllPoints(MB.minimize_backdrop)
        BlzFrameSetAllPoints(MB.minimize_backdrop, MB.minimize_button)
        BlzFrameSetTexture(MB.minimize_backdrop, "war3mapImported\\expand.blp", 0, true)

        MB.minimize_trig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(MB.minimize_trig, MB.minimize_button, FRAMEEVENT_CONTROL_CLICK)
        TriggerAddAction(MB.minimize_trig, MB.onMinimize)

        --MB.next_button = BlzCreateFrame("GLUEBUTTON", MB.main, 0, 0)
        MB.next_button = BlzCreateFrameByType("GLUEBUTTON", "name", MB.main, "ScoreScreenTabButtonTemplate", 0)
        BlzFrameClearAllPoints(MB.next_button)
        BlzFrameSetPoint(MB.next_button, FRAMEPOINT_RIGHT, MB.main, FRAMEPOINT_RIGHT, -0.0175, 0)
        BlzFrameSetSize(MB.next_button, 0.015, 0.015)
        FrameAddSimpleTooltip(MB.next_button, "", "Next page '/'", true, FRAMEPOINT_TOPRIGHT, FRAMEPOINT_BOTTOMLEFT)

        MB.next_backdrop = BlzCreateFrameByType("BACKDROP", "name", MB.next_button, "", 0)
        BlzFrameClearAllPoints(MB.next_backdrop)
        BlzFrameSetAllPoints(MB.next_backdrop, MB.next_button)
        BlzFrameSetTexture(MB.next_backdrop, "war3mapImported\\next.blp", 0, true)

        MB.next_trig = CreateTrigger()
        BlzTriggerRegisterFrameEvent(MB.next_trig, MB.next_button, FRAMEEVENT_CONTROL_CLICK)
        TriggerAddAction(MB.next_trig, MB.onNext)

        --create bodies
        local main = MB.makeBody(6)
        local queue = MB.makeBody(3)
        local threat = MB.makeBody(1)
        local damageLog = MB.makeBody(6)

        main:addRows(User.AmountPlaying)
        main.available = __jarray(true)
        main.title = "Curse of Time RPG: |cff9966ffNevermore|r"

        damageLog:addRows(3)
        damageLog.available = __jarray(true)
        damageLog.title = "|cffffcc00Damage Log|r"

        MB.MAIN = main
        MB.QUEUE = queue
        MB.THREAT = threat
        MB.DAMAGE = damageLog

        --helper functions
        local function refresh_multiboard()
            local index = 1
            local readyIndex = 1

            for pid = 1, PLAYER_CAP do
                local u = User[pid - 1]

                if u then
                    --main
                    local nameText = (IS_DONATOR[pid] and u.nameColored .. "|r|cffffcc00*|r") or u.nameColored
                    local hcIcon = (Hardcore[pid] and "ReplaceableTextures\\CommandButtons\\BTNBirial.blp") or "trans32.blp"
                    local heroIcon = (HeroID[pid] > 0 and BlzGetAbilityIcon(HeroID[pid])) or "trans32.blp"
                    local hp = (HeroID[pid] > 0 and GetWidgetLife(Hero[pid]) / BlzGetUnitMaxHP(Hero[pid]) * 100.) or 0
                    local heroText = (HeroID[pid] > 0 and GetObjectName(HeroID[pid])) or ""
                    local levelText = (HeroID[pid] > 0 and "|cff999999[" .. GetHeroLevel(Hero[pid]) .. "]|r") or ""
                    local hpText = (HeroID[pid] > 0 and HealthGradient(hp, true) .. math.ceil(hp) .. "\x25" .. "|r") or ""
                    if u.isPlaying == false then
                        name = "|cff999999" .. u.name .. "|r"
                    end

                    BlzFrameSetText(MULTIBOARD.MAIN:get(index, 1).text, nameText)
                    BlzFrameSetTexture(MULTIBOARD.MAIN:get(index, 2).icon, hcIcon, 0, true)
                    BlzFrameSetTexture(MULTIBOARD.MAIN:get(index, 3).icon, heroIcon, 0, true)
                    BlzFrameSetText(MULTIBOARD.MAIN:get(index, 4).text, heroText)
                    BlzFrameSetText(MULTIBOARD.MAIN:get(index, 5).text, levelText)
                    BlzFrameSetText(MULTIBOARD.MAIN:get(index, 6).text, hpText)

                    --ready
                    if TableHas(QUEUE_GROUP, pid) then
                        local readyIcon = (QUEUE_READY[pid] and "ReplaceableTextures\\CommandButtons\\BTNcheck.blp") or "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"

                        BlzFrameSetText(MULTIBOARD.QUEUE:get(readyIndex, 1).text, nameText)
                        BlzFrameSetTexture(MULTIBOARD.QUEUE:get(readyIndex, 2).icon, readyIcon, 0, true)

                        readyIndex = readyIndex + 1
                    end

                    index = index + 1
                end
            end
        end

        ---@type fun(a: integer, b: integer): boolean
        local function compare_flags(entry, player)
            local compare = (entry & player)
            local damageFlag = compare & (FLAG_DEALT + FLAG_TAKEN)
            local playerFlag = compare & ~(FLAG_DEALT + FLAG_TAKEN)
            local summonFlag = ((entry & FLAG_SUMMON ~= 0) and (player & FLAG_SUMMON == 0)) and 0 or 1

            return (playerFlag ~= 0 and damageFlag ~= 0 and summonFlag ~= 0)
        end

        --Repopulates damage log text area for a player according to DAMAGE_LOG_FLAGS[pid]
        ---@type fun(pid: integer)
        function LogUpdate(pid)
            local flags = DAMAGE_LOG_FLAGS[pid]
            local frame = MULTIBOARD.DAMAGE:get(2, 1).frame

            BlzFrameSetText(frame, " ")

            for entry in DAMAGE_LOG:iterator() do
                if compare_flags(entry.flags, flags) and GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameAddText(frame, entry.text)
                end
            end
        end

        --Append a damage (or healing) instance to a damage log with appropriate flags
        ---@type fun(source: unit, target: unit, text: string, heal: boolean|nil, tag: string|nil)
        function LogDamage(source, target, text, heal, tag)
            local name = tag or GetUnitName(source)
            local type = (heal and " heals ") or " hit "
            local pid = GetPlayerId(GetOwningPlayer(source)) + 1
            local tpid = GetPlayerId(GetOwningPlayer(target)) + 1
            local phex = (pid <= PLAYER_CAP and User[pid - 1].hex) or ""
            local thex = (tpid <= PLAYER_CAP and User[tpid - 1].hex) or ""
            local log = "[" .. BlzFrameGetText(CLOCK_FRAME_TEXT) .. "] " .. phex .. name .. "|r" .. type .. thex .. GetUnitName(target) .. "|r for " .. text

            --toggle summon flag
            local flags = ((TableHas(SummonGroup, target) or TableHas(SummonGroup, source)) and FLAG_SUMMON) or 0

            --toggle player and damage flags
            flags = pid <= PLAYER_CAP and ((flags | (1 << (pid - 1))) + ((heal == false and FLAG_DEALT) or 0)) or flags
            flags = tpid <= PLAYER_CAP and ((flags | (1 << (tpid - 1))) + FLAG_TAKEN) or flags

            local data = {text = log, flags = flags}

            DAMAGE_LOG:add(data)

            if compare_flags(flags, DAMAGE_LOG_FLAGS[GetPlayerId(GetLocalPlayer()) + 1]) then
                BlzFrameAddText(MULTIBOARD.DAMAGE:get(2, 1).frame, log)
            end
        end

        --initialize multiboard bodies
        local index = 1

        for pid = 1, PLAYER_CAP do
            if User[pid - 1] then
                main:get(index, 1).text = {0.02, 0, 0.09, ICON_SIZE}
                main:get(index, 2).icon = {0.11, 0, ICON_SIZE, ICON_SIZE}
                main:get(index, 3).icon = {0.13, 0, ICON_SIZE, ICON_SIZE}
                main:get(index, 4).text = {0.15, 0, 0.08, ICON_SIZE}
                main:get(index, 5).text = {0.23, 0, 0.03, ICON_SIZE}
                main:get(index, 6).text = {0.26, 0, 0.03, ICON_SIZE}

                index = index + 1
            end
        end

        ---@type fun(frame: framehandle, events: table, func: function, ...: any)
        local function RegisterButtonEvents(frame, events, func, ...)
            local trig = CreateTrigger()
            local args = table.pack(...)

            for _, event in ipairs(events) do
                BlzTriggerRegisterFrameEvent(trig, frame, event)
            end
            TriggerAddAction(trig, function()
                if GetLocalPlayer() == GetTriggerPlayer() then
                    BlzFrameSetEnable(frame, false)
                    BlzFrameSetEnable(frame, true)
                end

                func(args)
            end)
        end

        local function ViewPlayersClick()
            local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
            local dw    = DialogWindow[pid] ---@type DialogWindow 
            local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

            if index ~= -1 then
                DAMAGE_LOG_FLAGS[pid] = DAMAGE_LOG_FLAGS[pid] ~ (1 << (dw.data[index] - 1))
                LogUpdate(pid)

                dw:destroy()
            end

            return false
        end

        local function ViewPlayers()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1
            local dw = DialogWindow.create(pid, "", ViewPlayersClick) ---@type DialogWindow 
            local U  = User.first ---@type User 

            while U do
                if pid ~= U.id then
                    dw.data[dw.ButtonCount] = U.id
                    dw:addButton(U.nameColored .. " - " .. (((DAMAGE_LOG_FLAGS[pid] & (1 << (U.id - 1)) ~= 0) and "|cff00ff00ON|r") or "|cffff0000OFF|r"))
                end

                U = U.next
            end

            dw:display()
        end

        local function ToggleFlag(args)
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            DAMAGE_LOG_FLAGS[pid] = DAMAGE_LOG_FLAGS[pid] ~ args[1]
            LogUpdate(pid)
        end

        --build damage log
        damageLog:get(1, 1).button =      {0.03, 0, ICON_SIZE * 7, ICON_SIZE * 2.5}
        damageLog:get(1, 2).button =      {0.32, 0, ICON_SIZE * 7, ICON_SIZE * 2.5}
        damageLog:get(2, 1).textarea =    {0.015, -0.018, ROW_WIDTH - 0.03, ROW_HEIGHT * 7.}
        damageLog:get(3, 1).radiobutton = {0.035, 0, BUTTON_SIZE, BUTTON_SIZE}
        damageLog:get(3, 2).text =        {0.055, 0.0025, 0.05, ICON_SIZE}
        BlzFrameSetText(damageLog:get(1, 1).button, "Players")
        RegisterButtonEvents(damageLog:get(1, 1).button, {FRAMEEVENT_CONTROL_CLICK}, ViewPlayers)
        BlzFrameSetText(damageLog:get(1, 2).button, "Clear")
        RegisterButtonEvents(damageLog:get(1, 2).button, {FRAMEEVENT_CONTROL_CLICK},
        function()
            if GetLocalPlayer() == GetTriggerPlayer() then
                BlzFrameSetText(damageLog:get(2, 1).textarea, " ")
            end
        end)
        BlzFrameSetText(damageLog:get(3, 2).frame, "Dealt")
        RegisterButtonEvents(damageLog:get(3, 1).radiobutton, {FRAMEEVENT_CHECKBOX_CHECKED, FRAMEEVENT_CHECKBOX_UNCHECKED}, ToggleFlag, FLAG_DEALT)

        damageLog:get(3, 3).radiobutton = {0.115, 0, BUTTON_SIZE, BUTTON_SIZE}
        damageLog:get(3, 4).text =        {0.135, 0.0025, 0.05, ICON_SIZE}
        BlzFrameSetText(damageLog:get(3, 4).frame, "Received")
        RegisterButtonEvents(damageLog:get(3, 3).radiobutton, {FRAMEEVENT_CHECKBOX_CHECKED, FRAMEEVENT_CHECKBOX_UNCHECKED}, ToggleFlag, FLAG_TAKEN)

        damageLog:get(3, 5).radiobutton = {0.195, 0, BUTTON_SIZE, BUTTON_SIZE}
        damageLog:get(3, 6).text =        {0.215, 0.0025, 0.05, ICON_SIZE}
        BlzFrameSetText(damageLog:get(3, 6).frame, "Summons")
        RegisterButtonEvents(damageLog:get(3, 5).radiobutton, {FRAMEEVENT_CHECKBOX_CHECKED, FRAMEEVENT_CHECKBOX_UNCHECKED}, ToggleFlag, FLAG_SUMMON)

        local id = GetPlayerId(GetLocalPlayer()) + 1

        -- display main to all
        main:display(id)

        -- toggle bit flag to ensure players can see their own damage instances
        DAMAGE_LOG_FLAGS[id] = DAMAGE_LOG_FLAGS[id] | (1 << (id - 1))

        -- refresh multiboards every second for the rest of the game
        TimerQueue:callPeriodically(1., nil, refresh_multiboard)
    end
end, Debug and Debug.getLine())
