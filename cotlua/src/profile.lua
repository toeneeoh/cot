--[[
    profile.lua

    A module that defines the Profile interface which provides
    functions to handle player specific data.
]]

OnInit.global("Profile", function(Require)
    Require('CodeGen')
    Require('TimerQueue')

    MAX_TIME_PLAYED     = 10000000  ---@type integer -- ~10 years in minutes
    MAX_PLAT_CRYS       = 100000 ---@type integer 
    MAX_GOLD            = 10000000 ---@type integer 
    MAX_UPGRADE_LEVEL   = 10 ---@type integer 
    MAX_STATS           = 255000 ---@type integer 
    MAX_SLOTS           = 40 ---@type integer 
    MAX_INVENTORY_SLOTS = 24 ---@type integer 

    ---@class Profile
    ---@field brand_new boolean
    ---@field new_char boolean
    ---@field pid integer
    ---@field current_slot integer
    ---@field checksums integer[]
    ---@field total_time integer
    ---@field skin function
    ---@field hero HeroData
    ---@field new function
    ---@field repick function
    ---@field load function
    ---@field getSlotsUsed function
    ---@field save_profile function
    ---@field save_character function
    ---@field preload_character function
    ---@field create function
    ---@field saveCooldown function
    ---@field toggleAutoSave function
    ---@field save_timer TimerQueue
    ---@field autosave boolean
    ---@field destroy function
    ---@field get_empty_slot function
    ---@field open_dialog function
    ---@field hero_select function
    ---@field cannot_load boolean
    ---@field profile_code string
    ---@field character_code string[]
    ---@field storage HeroData[]
    ---@field generate_backup function
    ---@field new_character function
    ---@field delete_character function
    Profile = {} ---@type Profile | Profile[]
    do
        local thistype = Profile

        local getter = {
            hero = function(tbl)
                return tbl.storage[tbl.current_slot]
            end
        }

        local mt = {
            __index = function(tbl, key)
                if getter[key] then
                    return getter[key](tbl)
                end
                return rawget(thistype, key)
            end}

        ---@type fun(pid: integer): Profile
        function Profile.create(pid)
            local self = setmetatable({
                pid = pid,
                checksums = __jarray(0),
                timers = {},
                save_timer = TimerQueue.create(),
                total_time = 0,
                character_code = {},
                storage = {}, ---@type HeroData[]
                current_slot = 1,
            }, mt)

            return self
        end

        function thistype:preload_character(code, slot)
            local p = Player(self.pid - 1)

            -- compare profile slot checksum with actual code
            if StringChecksum(tostring(StringHash(code))) ~= self.checksums[slot] then
                DisplayTimedTextToPlayer(p, 0, 0, 300., "|cffff0000Hero data in slot " .. slot .. " is corrupt and will not be loaded!|r")
                return nil
            end

            local data, err = Decompile(code, p)

            -- fail to load
            if err then
                DisplayTimedTextToPlayer(p, 0, 0, 30., err)
                return nil
            end

            local hero = HeroData.create()
            self.character_code[slot] = code
            self.storage[slot] = hero

            hero:propagate(data)
        end

        ---@return boolean
        local function profile_click()
            local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
            local dw    = DialogWindow[pid] ---@type DialogWindow 
            local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

            if index ~= -1 then
                thistype[pid] = thistype.create(pid)
                thistype[pid].brand_new = true
                thistype[pid]:hero_select()

                dw:destroy()
            end

            return false
        end

        ---@param pid integer
        function thistype.new(pid)
            if thistype[pid] and thistype[pid].brand_new then
                DisplayTimedTextToPlayer(Player(pid - 1), 0, 0, 30, "You already started a new profile!")
            else
                local dw = DialogWindow.create(pid, "Start a new profile?\n|cFFFF0000Any existing profile will be\noverwritten.|r", profile_click) ---@type DialogWindow

                dw:addButton("Yes")
                dw:display()
            end
        end

        function thistype:get_empty_slot()
            for i = 1, MAX_SLOTS do
                if self.checksums[i] == 0 then
                    self.current_slot = i
                    return
                end
            end

            self.current_slot = -1
        end

        ---@type fun(pid: integer)
        function thistype:repick()
            -- return if in hero selection
            if SELECTING_HERO[self.pid] then
                return
            end

            local p = Player(self.pid - 1)

            -- allow repicking after hardcore death
            if HeroID[self.pid] ~= 0 then
                if IsUnitPaused(Hero[self.pid]) or not UnitAlive(Hero[self.pid]) then
                    DisplayTextToPlayer(p, 0, 0, "You can't repick right now.")
                    return
                elseif RectContainsUnit(gg_rct_Tavern, Hero[self.pid]) or RectContainsUnit(gg_rct_NoSin, Hero[self.pid]) or RectContainsUnit(gg_rct_Church, Hero[self.pid]) then
                    ShowHeroCircle(p, true)
                else
                    DisplayTextToPlayer(p, 0, 0, "You can only repick in church, town or tavern.")
                    return
                end
            end

            -- close stat window
            if GetLocalPlayer() == p then
                BlzFrameSetVisible(STAT_WINDOW.frame, false)
            end

            self.save_timer:reset()
            PlayerCleanup(self.pid)
            self:hero_select()
        end

        ---@type fun(self: Profile)
        local function SaveTimerExpire(self)
            local success = Save(Player(self.pid - 1))

            if not success then
                self.save_timer:callDelayed(30., SaveTimerExpire, self)
            elseif success then
                self.save_timer:callDelayed(1800., DoNothing)
            end
        end

        ---@type fun(self: Profile)
        function thistype:toggleAutoSave()
            local time = TimerGetRemaining(self.save_timer.timer)
            self.save_timer:reset()

            if self.autosave == true then
                self.save_timer:callDelayed(time, DoNothing)
                DisplayTextToPlayer(Player(self.pid - 1), 0, 0, "|cffffcc00Autosave disabled.|r")
            else
                self.save_timer:callDelayed(time, SaveTimerExpire, self)
                DisplayTextToPlayer(Player(self.pid - 1), 0, 0, "|cffffcc00Autosave is now enabled -- you will save every 30 minutes or when your next save is available as Hardcore.|r")
            end

            self.autosave = not self.autosave
        end

        ---Displays save cooldown
        ---@type fun(self: Profile)
        function thistype:saveCooldown()
            if self.autosave == true then
                DisplayTimedTextToPlayer(Player(self.pid - 1), 0, 0, 20, "Your next autosave is in " .. RemainingTimeString(self.save_timer.timer) .. ".")
            elseif Hardcore[self.pid] then
                DisplayTimedTextToPlayer(Player(self.pid - 1), 0, 0, 20, RemainingTimeString(self.save_timer.timer) .. " until you can save again.")
            end
        end

        function thistype:new_character(id)
            local hero = HeroData.create()
            self.storage[self.current_slot] = hero
            hero.id = SAVE_TABLE.KEY_UNITS[id]
        end

        function thistype:delete_character()
            local path = GetCharacterPath(self.pid, self.current_slot)
            if GetLocalPlayer() == GetTriggerPlayer() then
                FileIO.Save(path, "")
            end
            self.storage[self.current_slot] = nil
            self.character_code[self.current_slot] = nil
            self:save_profile()
        end

        local toggle_delete = {} ---@type boolean[] 

        local function load_menu()
            local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
            local dw    = DialogWindow[pid]
            local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

            -- new character button
            if GetClickedButton() == dw.MenuButton[2] then
                thistype[pid]:get_empty_slot()

                if thistype[pid]:getSlotsUsed() >= 30 then
                    DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 30.0, "You cannot save more than 30 heroes!")
                    dw.Page = -1
                    dw:display()
                else
                    if not SELECTING_HERO[pid] then
                        DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 30.0, "Select a |c006969ffhero|r using the left and right arrow keys.")
                        thistype[pid].new_char = true
                        thistype[pid]:hero_select()
                    end

                    dw:destroy()
                end
            -- load / delete button
            elseif GetClickedButton() == dw.MenuButton[3] then
                -- stay at the same page
                if dw.Page > -1 then
                    dw.Page = dw.Page - 1
                end

                if toggle_delete[pid] then
                    toggle_delete[pid] = false
                    dw.MenuButtonName[3] = "|cffff0000Delete Character"
                    dw.title = "|cffffffffLOAD"
                    dw:display()
                else
                    toggle_delete[pid] = true
                    dw.MenuButtonName[3] = "|cffffffffLoad Character"
                    dw.title = "|cffff0000DELETE"
                    dw:display()
                end
            -- character slot
            elseif index ~= -1 then
                local slot = dw.data[index]
                thistype[pid].current_slot = slot
                dw:destroy()

                if toggle_delete[pid] then
                    -- confirm delete character
                    dw = DialogWindow.create(pid, "Are you sure?|nAny prestige bonuses from this character will be lost!", ConfirmDeleteCharacter)
                    dw:addButton("|cffff0000DELETE")
                    dw:display()
                else
                    -- load character
                    DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "Loading |c006969ffhero|r from selected slot...")
                    CharacterSetup(pid, true)
                end
            end

            return false
        end

        function thistype:hero_select()
            if GetLocalPlayer() == Player(self.pid - 1) then
                EnablePreSelect(false, false)
                EnableSelect(false, false)
                SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
            end
            SetCamera(self.pid, gg_rct_Tavern)
            StartHeroSelect(self.pid)

            Backpack[self.pid] = nil
            SELECTING_HERO[self.pid] = true
            SetCurrency(self.pid, GOLD, 100)
        end

        function thistype:open_dialog()
            local dw = DialogWindow.create(self.pid, "|cffffffffLOAD", load_menu)

            toggle_delete[self.pid] = false

            for i = 1, MAX_SLOTS do
                if self.checksums[i] > 0 and self.character_code[i] then -- slot is not empty
                    local name = "|cffffcc00"
                    local storage = self.storage[i]

                    if storage.prestige > 0 then
                        name = name .. "[PRSTG] "
                    end
                    name = name .. GetObjectName(SAVE_UNIT_TYPE[storage.id]) .. " [" .. (storage.level) .. "] "
                    if storage.hardcore > 0 then
                        name = name .. "[HC]"
                    end

                    dw:addButton(name, i)
                end
            end

            dw:addMenuButton("|cffffffffNew Character")
            dw:addMenuButton("|cffff0000Delete Character")

            dw:display()
        end

        ---@type fun(code: string, pid: integer): boolean
        function thistype.load(code, pid)
            local p = Player(pid - 1)
            local data, err = Decompile(code, p)

            -- safety
            if err then
                DisplayTimedTextToPlayer(p, 0, 0, 30., err)
                return false
            end

            local index = 1
            local vers = data[index]

            -- TODO: implement version handling
            if vers <= SAVE_LOAD_VERSION - 2 or vers >= SAVE_LOAD_VERSION + 2 then
                DisplayTimedTextToPlayer(p, 0, 0, 30., "Profile data corrupt or version mismatch!")
                return false
            end

            print("Save Load Version: " .. (vers))

            local self = Profile.create(pid)

            for i = 1, MAX_SLOTS do
                index = index + 1
                self.checksums[i] = data[index]
            end

            index = index + 1
            self.total_time = data[index]
            self.profile_code = code
            thistype[pid] = self

            return true
        end

        ---@return integer
        function thistype:getSlotsUsed()
            local count = 0

            for i = 1, MAX_SLOTS do
                if self.checksums[i] > 0 then
                    count = count + 1
                end
            end

            return count
        end

        -- save all codes in backup folder with time stamp
        function thistype:generate_backup()
            local backup_folder = MAP_NAME .. "\\BACKUP\\" .. User[self.pid - 1].name .. "\\" .. os.date("\x25B_\x25d_\x25Y_\x25H_\x25M")

            if GetLocalPlayer() == Player(self.pid - 1) then
                FileIO.Save(backup_folder .. "\\profile.pld", "\n" .. self.profile_code)

                for i = 1, MAX_SLOTS do
                    if self.character_code[i] then
                        local hero_name = GetObjectName(SAVE_UNIT_TYPE[self.storage[i].id])
                        FileIO.Save(backup_folder .. "\\slot" .. i .. ".pld", hero_name .. " " .. self.storage[i].level .. "\n" .. self.character_code[i])
                    end
                end
            end
        end

        -- this should be called after saving the character
        function thistype:save_profile()
            local p = Player(self.pid - 1)
            local data = {}

            data[#data + 1] = SAVE_LOAD_VERSION

            for i = 1, MAX_SLOTS do
                if i == self.current_slot then
                    self.checksums[i] = (self.character_code[i] and StringChecksum(tostring(StringHash(self.character_code[i])))) or 0
                end

                data[#data + 1] = self.checksums[i]
            end

            data[#data + 1] = self.total_time
            self.profile_code = Compile(self.pid, data)

            if GAME_STATE == 2 then
                local path = GetProfilePath(self.pid)

                if GetLocalPlayer() == p then
                    FileIO.Save(path, "\n" .. self.profile_code)
                end

                self:generate_backup()

                DisplayTimedTextToPlayer(p, 0, 0, 120, "-------------------------------------------------------------------")
                DisplayTimedTextToPlayer(p, 0, 0, 120, "|cffffcc00Your data has been saved successfully at:|r")
                DisplayTimedTextToPlayer(p, 0, 0, 120, "(Warcraft III\\CustomMapData\\" .. MAP_NAME .. "\\" .. GetPlayerName(p) .. ")")
                DisplayTimedTextToPlayer(p, 0, 0, 120, "|cffffcc00Make sure to type|r -load |cffffcc00the next time you play.|r")
                DisplayTimedTextToPlayer(p, 0, 0, 120, "|cffffcc00A backup of your data has also been created at:|r")
                DisplayTimedTextToPlayer(p, 0, 0, 120, "(" .. MAP_NAME .. "\\BACKUP\\" .. GetPlayerName(p) .. "\\" .. os.date("\x25B_\x25d_\x25Y_\x25H_\x25M") .. ")")
                DisplayTimedTextToPlayer(p, 0, 0, 120, "-------------------------------------------------------------------")
            end
        end

        function thistype:save_character()
            local p = Player(self.pid - 1)
            local hero = self.hero

            -- update hero data
            hero.level = GetHeroLevel(Hero[self.pid])
            hero.str = math.min(MAX_STATS, Unit[Hero[self.pid]].str)
            hero.agi = math.min(MAX_STATS, Unit[Hero[self.pid]].agi)
            hero.int = math.min(MAX_STATS, Unit[Hero[self.pid]].int)
            hero.gold = math.min(GetCurrency(self.pid, GOLD), MAX_GOLD)
            hero.platinum = math.min(GetCurrency(self.pid, PLATINUM), MAX_PLAT_CRYS)
            hero.crystal = math.min(GetCurrency(self.pid, CRYSTAL), MAX_PLAT_CRYS)
            hero.teleport = GetUnitAbilityLevel(Backpack[self.pid], TELEPORT_HOME.id)
            hero.reveal = GetUnitAbilityLevel(Backpack[self.pid], FourCC('A0FK'))
            hero.time = math.min(hero.time, MAX_TIME_PLAYED)

            for i = 1, MAX_INVENTORY_SLOTS do
                local itm = hero.items[i]
                if itm then
                    itm.owner = p -- bind items after saving
                    hero.item_id[i] = itm:encode_id()
                    hero.item_stats[i] = itm:encode_stats()
                end
            end

            local s = Compile(self.pid, hero:values())

            if GAME_STATE == 2 then
                local hero_name = GetObjectName(HeroID[self.pid])
                local path = GetCharacterPath(self.pid, self.current_slot)

                if GetLocalPlayer() == p then
                    FileIO.Save(path, hero_name .. " " .. self.hero.level .. "\n" .. s)
                end
            end

            self.character_code[self.current_slot] = s
            self:save_profile()
        end

        function thistype:skin(index)
            self.hero.skin = index

            BlzSetUnitSkin(Backpack[self.pid], CosmeticTable.skins[index].id)
            if CosmeticTable.skins[index].id == FourCC('H02O') then
                AddUnitAnimationProperties(Backpack[self.pid], "alternate", true)
            end
        end
    end

    local function move_expire(unit)
        unit.busy = false
    end

    local function backpack_ai(source, _, id)
        if id ~= ORDER_ID_MOVE then
            local unit = Unit[source]
            unit.busy = true
            unit.aggro_timer = unit.aggro_timer or TimerQueue.create()
            unit.aggro_timer:reset()
            unit.aggro_timer:callDelayed(4, move_expire, unit)
        end
    end

    local function backpack_periodic(unit, pid)
        if unit then
            local x = GetUnitX(Hero[pid]) + 50 * Cos((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)
            local y = GetUnitY(Hero[pid]) + 50 * Sin((GetUnitFacing(Hero[pid]) - 45) * bj_DEGTORAD)

            if IsUnitInRange(Hero[pid], unit.unit, 1000.) == false then
                SetUnitXBounded(unit.unit, x)
                SetUnitYBounded(unit.unit, y)
                BlzUnitClearOrders(unit.unit, false)
            elseif not unit.busy or IsUnitInRange(Hero[pid], unit.unit, 800.) == false then
                if IsUnitInRange(Hero[pid], unit.unit, 50.) == false then
                    IssuePointOrderById(unit.unit, ORDER_ID_MOVE, x, y)
                end
            end

            TimerQueue:callDelayed(0.35, backpack_periodic, unit, pid)
        end
    end

    ---@class HeroData
    ---@field id integer
    ---@field hardcore integer
    ---@field prestige integer
    ---@field level integer
    ---@field str integer
    ---@field agi integer
    ---@field int integer
    ---@field gold integer
    ---@field platinum integer
    ---@field crystal integer
    ---@field time integer
    ---@field items Item[]
    ---@field item_id integer[]
    ---@field item_stats integer[]
    ---@field teleport integer
    ---@field reveal integer
    ---@field skin integer
    ---@field create function
    ---@field values function
    ---@field propagate function
    ---@field load_data function
    HeroData = {}
    do
        local thistype = HeroData
        local mt = { __index = thistype }

        local keys = {
            "id", "hardcore", "prestige", "level", "str", "agi", "int", "gold", "platinum", "crystal", "time", "item_id", "item_stats", "teleport", "reveal", "skin"
        }

        local setter = {
            id = function(pid, value)
                Hero[pid] = CreateUnit(Player(pid - 1), SAVE_UNIT_TYPE[value], 0, 0, 0.)
                HeroID[pid] = SAVE_UNIT_TYPE[value]
                PlayerSelectedUnit[pid] = Hero[pid]

                Unit[Hero[pid]].mr = HeroStats[HeroID[pid]].magic_resist
                Unit[Hero[pid]].pr = HeroStats[HeroID[pid]].phys_resist
                Unit[Hero[pid]].pm = HeroStats[HeroID[pid]].phys_damage
                Unit[Hero[pid]].cc_flat = HeroStats[HeroID[pid]].crit_chance
                Unit[Hero[pid]].cd_flat = HeroStats[HeroID[pid]].crit_damage

                -- backpack
                Backpack[pid] = CreateUnit(Player(pid - 1), BACKPACK, 0, 0, 0)

                -- show backpack hero panel only for player
                if GetLocalPlayer() == Player(pid - 1) then
                    EnablePreSelect(true, true)
                    EnableSelect(true, true)
                    ClearSelection()
                    SelectUnit(Hero[pid], true)
                    ResetToGameCamera(0)
                    PanCameraToTimed(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
                    BlzSetUnitBooleanField(Backpack[pid], UNIT_BF_HERO_HIDE_HERO_INTERFACE_ICON, false)
                end

                SetUnitOwner(Backpack[pid], Player(PLAYER_NEUTRAL_PASSIVE), false)
                SetUnitOwner(Backpack[pid], Player(pid - 1), false)
                SetUnitAnimation(Backpack[pid], "stand")
                SuspendHeroXP(Backpack[pid], true)
                UnitAddAbility(Backpack[pid], FourCC('A00R'))
                UnitAddAbility(Backpack[pid], FourCC('A09C'))
                UnitAddAbility(Backpack[pid], FourCC('A0FS'))
                UnitAddAbility(Backpack[pid], TELEPORT.id)
                UnitAddAbility(Backpack[pid], FourCC('A0FK'))
                UnitAddAbility(Backpack[pid], TELEPORT_HOME.id)
                UnitAddAbility(Backpack[pid], FourCC('A04M'))
                UnitAddAbility(Backpack[pid], FourCC('A0DT'))
                UnitAddAbility(Backpack[pid], FourCC('A05N'))

                EVENT_ON_ORDER:register_unit_action(Backpack[pid], backpack_ai)
                TimerQueue:callDelayed(0., backpack_periodic, Unit[Backpack[pid]], pid)

                -- grave
                HeroGrave[pid] = CreateUnit(Player(pid - 1), GRAVE, 30000, 30000, 270)
                SuspendHeroXP(HeroGrave[pid], true)
                ShowUnit(HeroGrave[pid], false)

                -- prevent actions disappearing on meta
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A03C'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A03V'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A0L0'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A0GD'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A06X'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00F'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A08Y'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00I'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00Y'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00B'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A02T'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A031'))
                UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A067'))
            end,
            hardcore = function(pid, value)
                Hardcore[pid] = (value > 0)
                if value > 0 then
                    PlayerAddItemById(pid, FourCC('I03N'))
                end
            end,
            level = function(pid, value)
                if value > 1 then
                    SetHeroLevel(Hero[pid], value, false)
                    SetHeroLevel(Backpack[pid], value, false)
                end
            end,
            str = function(pid, value)
                local unit = Unit[Hero[pid]]

                unit.str = value or unit.str
            end,
            agi = function(pid, value)
                local unit = Unit[Hero[pid]]

                unit.agi = value or unit.agi
            end,
            int = function(pid, value)
                local unit = Unit[Hero[pid]]

                unit.int = value or unit.int
            end,
            gold = function(pid, value)
                SetCurrency(pid, GOLD, value)
            end,
            platinum = function(pid, value)
                SetCurrency(pid, PLATINUM, value)
            end,
            crystal = function(pid, value)
                SetCurrency(pid, CRYSTAL, value)
            end,
            item_id = function(pid, value)
                local hero = Profile[pid].hero

                for j = 1, MAX_INVENTORY_SLOTS do
                    hero.items[j] = Item.decode(hero.item_id[j], hero.item_stats[j])
                end

                for i = 1, 6 do
                    if hero.items[i] then
                        UnitAddItem(Hero[pid], hero.items[i].obj)
                        UnitDropItemSlot(Hero[pid], hero.items[i].obj, i - 1)
                    end

                    if hero.items[i + 6] then
                        UnitAddItem(Backpack[pid], hero.items[i + 6].obj)
                        UnitDropItemSlot(Backpack[pid], hero.items[i + 6].obj, i - 1)
                    end
                end
            end,
            teleport = function(pid, value)
                SetUnitAbilityLevel(Backpack[pid], TELEPORT_HOME.id, value)
                SetUnitAbilityLevel(Backpack[pid], TELEPORT.id, value)
            end,
            reveal = function(pid, value)
                SetUnitAbilityLevel(Backpack[pid], FourCC('A0FK'), value)
            end,
            skin = function(pid, value)
                Profile[pid]:skin(value)
            end,
        }

        function thistype:load_data(pid)
            for i = 1, #keys do
                local key = keys[i]

                if setter[key] then
                    setter[key](pid, self[key])
                    if key == "item_id" then -- skip an index
                        i = i + 1
                    end
                end
            end
        end

        ---@return integer[]
        function thistype:values()
            local result = {}

            for i = 1, #keys do
                local key = keys[i]

                if key == "item_id" or key == "item_stats" then
                    for j = 1, MAX_INVENTORY_SLOTS do
                        result[#result + 1] = self[key][j]
                    end
                else
                    result[#result + 1] = self[key]
                end
            end

            return result
        end

        ---@param data integer[]
        function thistype:propagate(data)
            local index = 1

            for i = 1, #keys do
                local key = keys[i]

                if key == "item_id" or key == "item_stats" then
                    for j = 1, MAX_INVENTORY_SLOTS do
                        self[key][j] = data[index]
                        index = index + 1
                    end
                else
                    self[key] = data[index]
                    index = index + 1
                end
            end
        end

        ---@return HeroData
        function HeroData.create()
            -- default values, some may not be necessary
            local self = setmetatable({
                hardcore = 0,
                prestige = 0,
                level = 1,
                gold = 100,
                platinum = 0,
                crystal = 0,
                time = 0,
                items = {},
                item_id = __jarray(0),
                item_stats = __jarray(0),
                teleport = 1,
                reveal = 1,
                skin = 25, -- wisp
            }, mt)

            return self
        end
    end

    ---@type fun(level: integer):integer
    function TomeCap(level)
        return math.floor(level ^ 4 * 0.000003 + 10 * level + level ^ 3 * 0.0005)
    end

    ---@type fun(pid: integer, load: boolean)
    function CharacterSetup(pid, load)
        local hero = Profile[pid].hero
        local x, y, angle, camera = -690., -238., 0, MAIN_MAP.rect -- outside tavern

        hero:load_data(pid)

        if load then
            x, y, angle, camera = GetRectCenterX(gg_rct_ChurchSpawn), GetRectCenterY(gg_rct_ChurchSpawn), 270., gg_rct_Church
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", Hero[pid], "origin"))
        else
            -- new characters can save immediately
            Profile[pid].cannot_load = true
        end

        SetUnitPosition(Hero[pid], x, y)
        SetUnitPosition(Backpack[pid], x, y)
        BlzSetUnitFacingEx(Hero[pid], angle)
        SetCamera(pid, camera)

        SELECTING_HERO[pid] = false
        Colosseum_XP[pid] = 1.00

        -- SetPrestigeEffects(pid)
        -- UpdatePrestigeTooltips(pid)

        -- heal to max
        SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]))
        SetUnitState(Hero[pid], UNIT_STATE_MANA, (HeroID[pid] ~= HERO_VAMPIRE and BlzGetUnitMaxMana(Hero[pid])) or 0)
    end

end, Debug and Debug.getLine())
