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
    Require("Shop")

    ---@class MULTIBOARD
    ---@field lookingAt integer[]
    ---@field bodies table
    ---@field MAIN table
    ---@field QUEUE table
    ---@field BOSS table
    ---@field DAMAGE table
    ---@field rows table
    ---@field minimize function
    ---@field next function
    ---@field ROW_WIDTH number
    ---@field ROW_HEIGHT number
    ---@field ICON_SIZE number
    ---@field BUTTON_SIZE number
    ---@field available boolean[]
    ---@field display function
    ---@field update function
    ---@field addRows function
    ---@field get function
    ---@field viewing table
    MULTIBOARD = {}

    do
        local MB = MULTIBOARD
        local ROW_WIDTH = 0.3
        local ROW_HEIGHT = 0.035
        local ROW_SPACING = 0.003
        local ICON_SIZE = 0.011
        local BUTTON_SIZE = 0.015
        local INITIAL_ROW_Y_OFFSET = 0.015
        local FINAL_ROW_Y_OFFSET = 0.012

        MB.ROW_WIDTH = ROW_WIDTH
        MB.ROW_HEIGHT = ROW_HEIGHT
        MB.ICON_SIZE = ICON_SIZE
        MB.BUTTON_SIZE = BUTTON_SIZE

        -- current mb body a player is looking at
        MB.lookingAt = __jarray(1) ---@type integer[]

        -- 1 = main, 2, ready queue, 3 = threat, 4 = damage log
        MB.bodies = {} ---@type table[]

        ---@type fun(columns: integer): table
        function MB.makeBody(columns)
            local self = {
                index = #MB.bodies + 1,
                frame = BlzCreateFrame("ListBoxWar3", MB.main, 0, 0),
                available = {}, ---@type boolean[]
                rows = {},
                anchors = {},
                columnCount = columns,
            }

            BlzFrameClearAllPoints(self.frame)
            BlzFrameSetPoint(self.frame, FRAMEPOINT_TOPLEFT, MB.main, FRAMEPOINT_BOTTOMLEFT, 0, 0.01)
            BlzFrameSetVisible(self.frame, false)
            BlzFrameSetEnable(self.frame, false)

            MB.bodies[self.index] = self

            -- returns an element at row, column
            -- 1-indexed
            ---@type fun(self: self, r: integer, c: integer): table
            function self:get(r, c)
                return self.rows[r].columns[c]
            end

            -- returns an anchor at row, column (rows that are anchored at the end and climb up)
            ---@type fun(self: self, r: integer, c: integer): table
            function self:get_anchor(r, c)
                return self.anchors[r].columns[c]
            end

            -- displays body to a player
            function self:display(pid)
                self:refresh()

                local old_body = MB.bodies[MB.lookingAt[pid]]
                MB.lookingAt[pid] = self.index

                if GetLocalPlayer() == Player(pid - 1) then
                    BlzFrameSetVisible(old_body.frame, false)
                    BlzFrameSetVisible(self.frame, true)
                    BlzFrameSetTexture(MB.minimize_backdrop, "war3mapImported\\minimize.blp", 0, true)
                    BlzFrameSetText(MB.name, self.title or "")
                    if old_body.close then
                        old_body.close()
                    end
                    if self.open then
                        self.open()
                    end
                end
            end

            -- called on display to ensure body is proper dimensions and rows are aligned by height
            function self:refresh()
                local height = INITIAL_ROW_Y_OFFSET

                for i = 1, #self.rows do
                    local row = self.rows[i]
                    BlzFrameSetPoint(row.parent, FRAMEPOINT_TOPLEFT, self.frame, FRAMEPOINT_TOPLEFT, 0, -height)
                    if row.height > 0 then
                        height = height + row.height + ROW_SPACING
                    end
                end

                for i = 1, #self.anchors do
                    local anchor = self.anchors[i]
                    if anchor.height > 0 then
                        height = height + anchor.height + ROW_SPACING
                    end
                    BlzFrameSetPoint(anchor.parent, FRAMEPOINT_BOTTOMLEFT, self.frame, FRAMEPOINT_BOTTOMLEFT, 0, self.anchors[i].height + INITIAL_ROW_Y_OFFSET)
                end

                BlzFrameSetSize(self.frame, 0.3, height + FINAL_ROW_Y_OFFSET)
            end

            -- method operators for initializing different types of frames
            local mt = {
                __newindex = function(column, key, val)
                    local frame, x_offset, y_offset, width, height

                    if type(val) == "table" then
                        x_offset, y_offset, width, height = val[1], val[2], val[3], val[4]

                        -- set max height of row
                        local max_height = height - y_offset
                        column.parent.height = math.max(column.parent.height, max_height)
                        column.parent.height_backup = column.parent.height
                    end

                    if key == "text" then
                        frame = BlzCreateFrameByType("TEXT", "name", column.parent.parent, "", 0)
                        BlzFrameSetText(frame, "")
                        BlzFrameSetEnable(frame, false)
                    elseif key == "textarea" then
                        frame = BlzCreateFrame("MBTextArea", column.parent.parent, 0, 0)
                    elseif key == "icon" then
                        frame = BlzCreateFrameByType("BACKDROP", "name", column.parent.parent, "", 0)
                        BlzFrameSetEnable(frame, false)
                        BlzFrameSetTexture(frame, "trans32.blp", 0, true)
                    elseif key == "radiobutton" then -- checked by default
                        frame = BlzCreateFrame("RadioCheckedButton", column.parent.parent, 0, 0)
                    elseif key == "button" then
                        frame = BlzCreateFrameByType("GLUETEXTBUTTON", "", column.parent.parent, "ScriptDialogButton", 0)
                        BlzFrameSetScale(frame, 0.7)
                    elseif key == "checkbox" then -- unchecked by default
                        frame = BlzCreateFrame("EscMenuCheckBoxTemplate", column.parent.parent, 0, 0)
                    elseif key == "bar" then
                        frame = BlzCreateFrame("EscMenuControlBackdropTemplate", column.parent.parent, 0, 0)
                        local bar = BlzCreateFrameByType("SIMPLESTATUSBAR", "", frame, "", 0)
                        BlzFrameSetPoint(bar, FRAMEPOINT_TOPLEFT, frame, FRAMEPOINT_TOPLEFT, 0.006, -0.006)
                        BlzFrameSetPoint(bar, FRAMEPOINT_BOTTOMRIGHT, frame, FRAMEPOINT_BOTTOMRIGHT, -0.006, 0.006)
                        BlzFrameSetTexture(bar, "ui\\feedback\\xpbar\\human-bigbar-fill", 0, true)
                        rawset(column, "bar_value", bar)
                    elseif key == "gluebutton" then
                        local gb = SimpleButton.create(column.parent.parent, "", width, height, FRAMEPOINT_TOPLEFT, FRAMEPOINT_TOPLEFT, x_offset, y_offset, nil, "View item drops", FRAMEPOINT_TOPRIGHT, FRAMEPOINT_BOTTOMLEFT)
                        rawset(column, key, gb)

                        return
                    end

                    if frame then
                        BlzFrameSetSize(frame, width, height)

                        -- align frame with row parent using x-offset and y-offset
                        BlzFrameSetPoint(frame, FRAMEPOINT_TOPLEFT, column.parent.parent, FRAMEPOINT_TOPLEFT, x_offset, y_offset)

                        -- two name references
                        rawset(column, key, frame)
                        rawset(column, "frame", frame)
                    else
                        rawset(column, key, val)
                    end
                end
            }

            -- sets the visibility of a specified row index
            function self:showRow(num, show)
                local row = self.rows[num]

                BlzFrameSetVisible(row.parent, show)
                if show then
                    row.height = row.height_backup
                else
                    row.height = 0
                end
                self:refresh()
            end

            -- adds set number of rows to a body, if anchor is true the row will tail the end of the multiboard regardless of added / deleted rows
            ---@type fun(self: self, num: integer, anchor: boolean)
            function self:addRows(num, anchor)
                for _ = 1, num do
                    local row = {
                        width = ROW_WIDTH,
                        height = 0, -- default height is set when a row object is defined
                        columns = {},
                        parent = BlzCreateFrameByType("FRAME", "", self.frame, "", 0),
                    }

                    -- make parent not visible
                    BlzFrameSetTexture(row.parent, "trans32.blp", 0, true)
                    BlzFrameSetSize(row.parent, 0.001, 0.001)
                    BlzFrameSetEnable(row.parent, false)

                    if anchor then
                        self.anchors[#self.anchors + 1] = row
                        row.pos = #self.anchors
                    else
                        self.rows[#self.rows + 1] = row
                        row.pos = #self.rows
                    end

                    for i = 1, self.columnCount do
                        row.columns[i] = {
                            body = self,
                            parent = row,
                            anchor = anchor,
                        }

                        setmetatable(row.columns[i], mt)
                    end
                end
            end

            return self
        end

        -- minimizes the multiboard for a player
        function MB.minimize(pid)
            local body = MB.bodies[MB.lookingAt[pid]]

            if Player(pid - 1) == GetLocalPlayer() then
                if BlzFrameIsVisible(body.frame) then
                    BlzFrameSetVisible(body.frame, false)
                    BlzFrameSetTexture(MB.minimize_backdrop, "war3mapImported\\expand.blp", 0, true)
                    if body.close then
                        body.close()
                    end
                else
                    BlzFrameSetVisible(body.frame, true)
                    BlzFrameSetTexture(MB.minimize_backdrop, "war3mapImported\\minimize.blp", 0, true)
                    if body.open then
                        body.open()
                    end
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

        -- opens the next multiboard page for a player
        function MB.next(pid)
            local next_body = MB.lookingAt[pid]

            repeat
                next_body = (next_body + 1 > #MB.bodies and 1) or next_body + 1
            until MB.bodies[next_body].available[pid]

            MB.bodies[next_body]:display(pid)
        end

        function MB.onNext()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            if GetTriggerPlayer() == GetLocalPlayer() then
                BlzFrameSetEnable(BlzGetTriggerFrame(), false)
                BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            end

            MB.next(pid)
        end

        -- define multiboard frames
        MB.frame = BlzCreateFrameByType("FRAME", "", BlzGetFrameByName("ConsoleUIBackdrop", 0), "", 0)
        MB.main = BlzCreateFrame("ListBoxWar3", MB.frame, 0, 0)
        BlzFrameSetSize(MB.main, ROW_WIDTH, ROW_HEIGHT)
        BlzFrameSetAbsPoint(MB.main, FRAMEPOINT_TOPRIGHT, 0.925, 0.6)
        BlzFrameSetEnable(MB.main, false)

        MB.name = BlzCreateFrameByType("TEXT", "name", MB.main, "", 0)
        BlzFrameClearAllPoints(MB.name)
        BlzFrameSetPoint(MB.name, FRAMEPOINT_CENTER, MB.main, FRAMEPOINT_CENTER, 0, 0)

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

        -- create bodies
        local main = MB.makeBody(6)
        local queue = MB.makeBody(3)
        local boss = MB.makeBody(4)
        local damageLog = MB.makeBody(6)

        main:addRows(User.AmountPlaying)
        main.available = __jarray(true)
        main.title = "Curse of Time RPG: |cff9966ffNevermore|r"

        damageLog:addRows(3)
        damageLog.available = __jarray(true)
        damageLog.title = "|cffffcc00Damage Log|r"

        queue:addRows(User.AmountPlaying)
        -- keep track of player positions
        queue.player_lookup = __jarray(0)
        queue.last_row = 0

        MB.MAIN = main
        MB.QUEUE = queue
        MB.BOSS = boss
        MB.DAMAGE = damageLog

        -- initialize main multiboard player rows
        do
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
        end

        -- refresh main multiboard
        local function refresh_multiboard()
            local index = 1
            local readyIndex = 1

            for pid = 1, PLAYER_CAP do
                local u = User[pid - 1]
                local profile = Profile[pid]

                if u then
                    -- main
                    local nameText = (IS_DONATOR[pid] and u.nameColored .. "|r|cffffcc00*|r") or u.nameColored
                    local hcIcon = (Hardcore[pid] and "ReplaceableTextures\\CommandButtons\\BTNBirial.blp") or "trans32.blp"
                    local heroIcon = (profile.playing and BlzGetAbilityIcon(HeroID[pid])) or "trans32.blp"
                    local hp = (profile.playing and GetWidgetLife(Hero[pid]) / BlzGetUnitMaxHP(Hero[pid]) * 100.) or 0
                    local heroText = (profile.playing and GetObjectName(HeroID[pid])) or ""
                    local levelText = (profile.playing and "|cff999999[" .. GetHeroLevel(Hero[pid]) .. "]|r") or ""
                    local hpText = (profile.playing and HealthGradient(hp, true) .. math.ceil(hp) .. "\x25" .. "|r") or ""
                    if u.isPlaying == false then
                        name = "|cff999999" .. u.name .. "|r"
                    end

                    BlzFrameSetText(main:get(index, 1).text, nameText)
                    BlzFrameSetTexture(main:get(index, 2).icon, hcIcon, 0, true)
                    BlzFrameSetTexture(main:get(index, 3).icon, heroIcon, 0, true)
                    BlzFrameSetText(main:get(index, 4).text, heroText)
                    BlzFrameSetText(main:get(index, 5).text, levelText)
                    BlzFrameSetText(main:get(index, 6).text, hpText)

                    -- ready
                    if TableHas(QUEUE_GROUP, pid) then
                        local readyIcon = (QUEUE_READY[pid] and "ReplaceableTextures\\CommandButtons\\BTNcheck.blp") or "ReplaceableTextures\\CommandButtons\\BTNCancel.blp"

                        BlzFrameSetText(queue:get(readyIndex, 1).text, nameText)
                        BlzFrameSetTexture(queue:get(readyIndex, 2).icon, readyIcon, 0, true)

                        readyIndex = readyIndex + 1
                    end

                    index = index + 1
                end
            end
        end

        -- damage log variables / functions
        local DAMAGE_LOG_FLAGS = __jarray(0x1C0) ---@type integer[]
        local DAMAGE_LOG = CircularArrayList.create(500) ---@type CircularArrayList
        local FLAG_DEALT = 0x40
        local FLAG_TAKEN = 0x80
        local FLAG_SUMMON = 0x100

        ---@type fun(a: integer, b: integer): boolean
        local function compare_flags(entry, player)
            local compare = (entry & player)
            local damageFlag = compare & (FLAG_DEALT + FLAG_TAKEN)
            local playerFlag = compare & ~(FLAG_DEALT + FLAG_TAKEN)
            local summonFlag = ((entry & FLAG_SUMMON ~= 0) and (player & FLAG_SUMMON == 0)) and 0 or 1

            return (playerFlag ~= 0 and damageFlag ~= 0 and summonFlag ~= 0)
        end

        -- Repopulates damage log text area for a player according to DAMAGE_LOG_FLAGS[pid]
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

        -- Append a damage (or healing) instance to a damage log with appropriate flags
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
                    dw:addButton(U.nameColored .. " - " .. (((DAMAGE_LOG_FLAGS[pid] & (1 << (U.id - 1)) ~= 0) and "|cff00ff00ON|r") or "|cffff0000OFF|r"), U.id)
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

        -- build damage log
        damageLog:get(1, 1).button =      {0.03, 0, ICON_SIZE * 7, ICON_SIZE * 2.5}
        damageLog:get(1, 2).button =      {0.32, 0, ICON_SIZE * 7, ICON_SIZE * 2.5}
        damageLog:get(2, 1).textarea =    {0.015, 0.006, ROW_WIDTH - 0.03, ROW_HEIGHT * 7.}
        damageLog:get(3, 1).radiobutton = {0.035, 0.0025, BUTTON_SIZE, BUTTON_SIZE}
        damageLog:get(3, 2).text =        {0.055, 0., 0.05, ICON_SIZE}
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

        damageLog:get(3, 3).radiobutton = {0.115, 0.0025, BUTTON_SIZE, BUTTON_SIZE}
        damageLog:get(3, 4).text =        {0.135, 0., 0.05, ICON_SIZE}
        BlzFrameSetText(damageLog:get(3, 4).frame, "Received")
        RegisterButtonEvents(damageLog:get(3, 3).radiobutton, {FRAMEEVENT_CHECKBOX_CHECKED, FRAMEEVENT_CHECKBOX_UNCHECKED}, ToggleFlag, FLAG_TAKEN)

        damageLog:get(3, 5).radiobutton = {0.195, 0.0025, BUTTON_SIZE, BUTTON_SIZE}
        damageLog:get(3, 6).text =        {0.215, 0., 0.05, ICON_SIZE}
        BlzFrameSetText(damageLog:get(3, 6).frame, "Summons")
        RegisterButtonEvents(damageLog:get(3, 5).radiobutton, {FRAMEEVENT_CHECKBOX_CHECKED, FRAMEEVENT_CHECKBOX_UNCHECKED}, ToggleFlag, FLAG_SUMMON)

        -- boss mb / helper functions
        do
            boss.viewing = {}
            -- init
            boss:addRows(3 + User.AmountPlaying)
            boss:get(1, 1).bar =      {0.015, 0., ROW_WIDTH * 0.88, ROW_HEIGHT * 0.6}
            local hp = boss:get(1, 1).bar_value
            BlzFrameSetValue(hp, 100)
            BlzFrameSetVertexColor(hp, BlzConvertColor(255, 255, 0, 0))
            boss:get(2, 1).bar =      {0.015, 0., ROW_WIDTH * 0.44, ROW_HEIGHT * 0.6}
            local threat = boss:get(2, 1).bar_value
            BlzFrameSetValue(threat, 100)
            BlzFrameSetVertexColor(threat, BlzConvertColor(255, 200, 200, 0))
            -- updates everything (1 sec)
            boss.update = function(self)
                local b = boss.viewing[GetPlayerId(GetLocalPlayer()) + 1]

                if b then
                    local diff = (b.difficulty == 1 and "Normal") or "Hard"
                    self.title = b.name .. " [" .. diff .. "]"

                    BlzFrameSetText(MB.name, self.title)
                    BlzFrameSetText(self:get(2, 2).text, "|cffffcc00Target:|r " .. ((b.target and User[b.target.owner].hex .. GetUnitName(b.target.unit) .. "|r") or ""))
                    BlzFrameSetText(self:get(3, 1).text, "|cffffcc00Battle Time:|r " .. os.date("!\x25H:\x25M:\x25S", math.floor(b.time)))

                    for i = 4, #self.rows do
                        local pid = i - 3

                        if b.damage[pid] > 0 then
                            BlzFrameSetTexture(self:get(i, 1).icon, BlzGetAbilityIcon(HeroID[pid]), 0, true)
                            BlzFrameSetText(self:get(i, 2).text, User[pid - 1].nameColored)
                            BlzFrameSetText(self:get(i, 3).text, "|cffFFA500" .. math.floor(b.damage[pid]) .. "|r")
                            self:showRow(i, true)
                        else
                            self:showRow(i, false)
                        end
                    end

                    local percent = GetWidgetLife(b.unit) / BlzGetUnitMaxHP(b.unit) * 100.

                    if boss.viewing[GetPlayerId(GetLocalPlayer()) + 1] == b then
                        BlzFrameSetValue(hp, percent)
                        BlzFrameSetValue(threat, b.threat)
                    end
                end
            end
            -- updates hp and threat (0.1 sec)
            boss.threat = function(self, b)
                b.threat = b.threat - 1
                b.time = b.time + 0.1
                local percent = GetWidgetLife(b.unit) / BlzGetUnitMaxHP(b.unit) * 100.

                if boss.viewing[GetPlayerId(GetLocalPlayer()) + 1] == b then
                    BlzFrameSetValue(hp, percent)
                    BlzFrameSetValue(threat, b.threat)
                end

                if b.threat <= 0 then
                    b:switch_target(nil, 1.)
                    b.threat = 100
                end

                if UnitAlive(b.unit) and b.target then
                    TimerQueue:callDelayed(0.1, self.threat, self, b)
                else
                    b.threat = 100
                end
            end
            -- open and close functions needed due to SIMPLESTATUSBAR shenanigans
            boss.open = function()
                BlzFrameSetAlpha(hp, 255)
                BlzFrameSetAlpha(threat, 255)
            end
            boss.close = function()
                BlzFrameSetAlpha(hp, 0)
                BlzFrameSetAlpha(threat, 0)
            end
            boss.close()
            boss:get(2, 2).text =   {0.15, -0.005, ROW_WIDTH * 0.5, ROW_HEIGHT * 0.7}
            boss:get(3, 1).text = {0.02, 0.006, 0.075, 0.025}
            BlzFrameSetText(boss:get(3, 1).text, "|cffffcc00Battle Time:|r " .. os.date("!\x25H:\x25M:\x25S", 0))
            boss:get(3, 3).icon = {0.13, 0., 0.015, 0.015}
            boss:get(3, 4).text = {0.15, -0.002, 0.1, 0.015}
            BlzFrameSetText(boss:get(3, 4).text, "|cffffcc00Damage|r")
            BlzFrameSetTexture(boss:get(3, 3).icon, "ReplaceableTextures\\CommandButtons\\BTNHammer.blp", 0, true)
            -- initialize player rows, and then hide them
            for i = 4, #boss.rows do
                boss:get(i, 1).icon = {0.02, 0.004, 0.015, 0.015}
                boss:get(i, 2).text = {0.04, 0.002, 0.05, 0.0175}
                boss:get(i, 3).text = {0.15, 0.002, 0.05, 0.0175}
                boss:showRow(i, false)
            end
            -- item drop button
            boss:addRows(1, true)
            boss:get_anchor(1, 1).gluebutton =     {0.262, 0., ICON_SIZE * 2, ICON_SIZE * 2}
            local item_drops = boss:get_anchor(1, 1).gluebutton
            item_drops:icon("ReplaceableTextures\\CommandButtons\\BTNTreasureChest.blp")
            local item_drop_container = BlzCreateFrameByType("FRAME", "", item_drops.frame, "", 0)
            BlzFrameSetTexture(item_drop_container, "trans32.blp", 0, true)
            BlzFrameSetSize(item_drop_container, 0.001, 0.001)
            BlzFrameSetEnable(item_drop_container, false)
            BlzFrameSetPoint(item_drop_container, FRAMEPOINT_TOPLEFT, item_drops.frame, FRAMEPOINT_TOPLEFT, 0., 0.)
            BlzFrameSetVisible(item_drop_container, false)
            local items = {}
            for i = 1, 10 do
                items[i] = Button.create(item_drop_container, ICON_SIZE * 2 + 0.004, ICON_SIZE * 2 + 0.004, 0., -(ICON_SIZE * 2. + 0.004) * i, false)
                items[i].tooltip:point(FRAMEPOINT_TOPRIGHT)
            end
            item_drops.close = function(p, close)
                if GetLocalPlayer() == p then
                    BlzFrameSetVisible(item_drop_container, not close)
                    item_drops:enable(close)
                end
            end
            local function onClick()
                local frame = BlzGetTriggerFrame()
                local p = GetTriggerPlayer()
                local b = boss.viewing[GetPlayerId(p) + 1]
                local boss_items = {}

                for i = 1, 10 do
                    local item = ItemDrops[b.id][i - 1]

                    if item ~= 0 then
                        boss_items[i] = ShopItem.create(item, 0, true)
                    else
                        break
                    end
                end

                item_drops.close(p, not item_drops.enabled)

                if GetLocalPlayer() == p then
                    BlzFrameSetEnable(frame, false)
                    BlzFrameSetEnable(frame, true)
                    for i = 1, 10 do
                        if boss_items[i] then
                            items[i]:visible(true)
                            items[i]:icon(boss_items[i].icon)
                            items[i].tooltip:name(boss_items[i].name)
                            items[i].tooltip:icon(boss_items[i].icon)
                            items[i].tooltip:text(boss_items[i].tooltip)
                        else
                            items[i]:visible(false)
                        end
                    end
                end
            end
            item_drops:onClick(onClick)
        end

        -- display main to all
        local id = GetPlayerId(GetLocalPlayer()) + 1
        main:display(id)

        -- toggle bit flag to ensure players can see their own damage instances
        DAMAGE_LOG_FLAGS[id] = DAMAGE_LOG_FLAGS[id] | (1 << (id - 1))

        -- refresh multiboards every second for the rest of the game
        TimerQueue:callPeriodically(1., nil, refresh_multiboard)
    end
end, Debug and Debug.getLine())
