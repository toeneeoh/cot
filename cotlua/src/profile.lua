--[[
    profile.lua

    A module that defines the Profile interface which provides
    functions to handle player specific data.
]]

OnInit.global("Profile", function(Require)
    Require('CodeGen')
    Require('TimerQueue')

    LOAD_FLAG = {} ---@type boolean[] 

    MAX_TIME_PLAYED     = 1000000  ---@type integer --max minutes - 16666 hours
    MAX_PLAT_ARC_CRYS   = 100000 ---@type integer 
    MAX_GOLD_LUMB       = 10000000 ---@type integer 
    MAX_UPGRADE_LEVEL   = 10 ---@type integer 
    MAX_STATS           = 250000 ---@type integer 
    MAX_SLOTS           = 29 ---@type integer 
    MAX_INVENTORY_SLOTS = 24 ---@type integer 

    deleteMode      = {} ---@type boolean[] 

    CANNOT_LOAD     = {} ---@type boolean[] 

    ---@class Profile
    ---@field brand_new boolean
    ---@field new_char boolean
    ---@field pid integer
    ---@field currentSlot integer
    ---@field phtl integer[]
    ---@field skin function
    ---@field hero HeroData
    ---@field sync_event trigger
    ---@field savecode string[]
    ---@field new function
    ---@field repick function
    ---@field load function
    ---@field LoadSync function
    ---@field getSlotsUsed function
    ---@field saveProfile function
    ---@field saveCharacter function
    ---@field loadCharacter function
    ---@field create function
    ---@field saveCooldown function
    ---@field toggleAutoSave function
    ---@field save_timer TimerQueue
    ---@field autosave boolean
    ---@field destroy function
    ---@field get_empty_slot function
    ---@field open_dialog function
    ---@field hero_select function
    Profile = {} ---@type Profile | Profile[]
    do
        local thistype = Profile
        local mt = { __index = Profile }
        thistype.sync_event = CreateTrigger()
        thistype.savecode   =__jarray("") ---@type string[] [PLAYER_CAP]

        ---@type fun(pid: integer): Profile
        function thistype.create(pid)
            local self = {
                pid = pid,
                currentSlot = 0,
                phtl = __jarray(0),
                hero = HeroData.create(pid),
                timers = {},
                save_timer = TimerQueue.create(),
            }

            setmetatable(self, mt)

            return self
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
            for i = 0, MAX_SLOTS do
                if self.phtl[i] == 0 then
                    self.currentSlot = i
                    return
                end
            end

            self.currentSlot = -1
        end

        ---@type fun(pid: integer)
        function thistype:repick()
            --return if in hero selection
            if SELECTING_HERO[self.pid] then
                return
            end

            local p = Player(self.pid - 1)

            --allow repicking after hardcore death
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

            --close stat window
            if GetLocalPlayer() == p then
                BlzFrameSetVisible(STAT_WINDOW.frame, false)
            end

            self.save_timer:reset()
            PlayerCleanup(self.pid)
            self:hero_select()
        end

        ---@type fun(self: Profile)
        local function SaveTimerExpire(self)
            local success = ActionSave(Player(self.pid - 1))

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

        local function load_menu()
            local pid   = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
            local dw    = DialogWindow[pid]
            local index = dw:getClickedIndex(GetClickedButton()) ---@type integer 

            --new character button
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
                thistype[pid].currentSlot = dw.data[index]
                dw:destroy()

                if deleteMode[pid] then
                    --confirm delete character
                    dw = DialogWindow.create(pid, "Are you sure?|nAny prestige bonuses from this character will be lost!", ConfirmDeleteCharacter)
                    dw:addButton("|cffff0000DELETE")
                    dw:display()
                else
                    --load character
                    DisplayTextToPlayer(GetTriggerPlayer(), 0, 0, "Loading |c006969ffhero|r from selected slot...")
                    local path = GetCharacterPath(pid, thistype[pid].currentSlot)

                    if GetLocalPlayer() == GetTriggerPlayer() then
                        BlzSendSyncData(SYNC_PREFIX, GetLine(1, FileIO.Load(path)))
                    end
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
            SetCurrency(self.pid, GOLD, 75)
            SetCurrency(self.pid, LUMBER, 30)
        end

        function thistype:open_dialog()
            local dw = DialogWindow.create(self.pid, "|cffffffffLOAD", load_menu)

            deleteMode[self.pid] = false

            for i = 0, MAX_SLOTS do
                if self.phtl[i] > 0 then --slot is not empty
                    local name = "|cffffcc00"
                    local hardcore = self.phtl[i] & 0x1
                    local prestige = (self.phtl[i] & 0x6) >> 1
                    local id = (self.phtl[i] & 0x1F8) >> 3
                    local herolevel = (self.phtl[i] & 0x7FE00) >> 9

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

        ---@type fun(s: string, pid: integer): Profile | nil
        function thistype.load(s, pid)
            local p = Player(pid - 1)
            local data = Load(s, p)

            --fail to load
            if not data then
                DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                return nil
            end

            local index = 1
            local vers = data[index]

            --TODO implement version handling
            if vers <= SAVE_LOAD_VERSION - 2 or vers >= SAVE_LOAD_VERSION + 2 then
                DisplayTimedTextToPlayer(p, 0, 0, 30., "Profile data corrupt or version mismatch!")
                return nil
            end

            print("Save Load Version: " .. (vers))

            local self = thistype.create(pid)

            index = index + 1

            for i = 0, MAX_SLOTS do
                self.phtl[i] = data[index]
                local prestige = (self.phtl[i] & 0x6) >> 1
                local id = (self.phtl[i] & 0x1F8) >> 3
                index = index + 1

                if prestige > 0 then
                    AllocatePrestige(pid, prestige, id)
                end
            end

            return self
        end

        ---@return boolean
        function thistype.LoadSync()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            thistype.savecode[pid - 1] = BlzGetTriggerSyncData()

            if (thistype.savecode[pid - 1]):len() > 1 then
                if not thistype[pid] then
                    thistype[pid] = thistype.load(thistype.savecode[pid - 1], pid)
                else
                    thistype[pid]:loadCharacter(thistype.savecode[pid - 1])
                end
            end

            return false
        end

        ---@return integer
        function thistype:getSlotsUsed()
            local count = 0

            for i = 0, MAX_SLOTS do
                if self.phtl[i] > 0 then
                    count = count + 1
                end
            end

            return count
        end

        function thistype:saveProfile()
            local p = Player(self.pid - 1)
            local data = {}

            data[#data + 1] = SAVE_LOAD_VERSION

            for i = 0, MAX_SLOTS do

                if i == self.currentSlot then
                    if deleteMode[self.pid] then
                        self.phtl[i] = 0
                    else
                        self.phtl[i] = self.hero.hardcore + (self.hero.prestige << 1) + (self.hero.id << 3) + (self.hero.level << 9)
                    end
                end

                data[#data + 1] = self.phtl[i]
            end

            local s = Compile(self.pid, data)

            if GAME_STATE == 2 then
                local hero_name = GetObjectName(HeroID[self.pid])
                local path = GetProfilePath(self.pid)
                local backup_path = MAP_NAME .. "\\BACKUP\\" .. User[p].name .. "\\" .. hero_name .. self.hero.level .. "_" .. os.time() .. "\\slot" .. (self.currentSlot + 1) .. ".pld"

                if GetLocalPlayer() == p then
                    FileIO.Save(path, "\n" .. s)
                    FileIO.Save(backup_path, "\n" .. s)
                end
            end

            DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Your data has been saved successfully. (Warcraft III\\CustomMapData\\CoT Nevermore\\" .. GetPlayerName(p) .. ")")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Use|r -load |cffffcc00the next time you play to load your hero.")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffFF0000YOU MUST RESTART WARCRAFT BEFORE LOADING AGAIN!|r")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------")
        end

        function thistype:saveCharacter()
            local p = Player(self.pid - 1)

            --[[
                hash
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
                time
                gold
                lumber
                skin
            ]]

            local data = {}
            data[#data + 1] = self.hero.hardcore
            data[#data + 1] = self.hero.prestige
            self.hero.id = SAVE_TABLE.KEY_UNITS[HeroID[self.pid]]
            data[#data + 1] = self.hero.id
            self.hero.level = GetHeroLevel(Hero[self.pid])
            data[#data + 1] = self.hero.level
            self.hero.str = IMinBJ(MAX_STATS, Unit[Hero[self.pid]].str)
            self.hero.agi = IMinBJ(MAX_STATS, Unit[Hero[self.pid]].agi)
            self.hero.int = IMinBJ(MAX_STATS, Unit[Hero[self.pid]].int)
            data[#data + 1] = self.hero.str
            data[#data + 1] = self.hero.agi
            data[#data + 1] = self.hero.int
            for i = 0, MAX_INVENTORY_SLOTS - 1 do
                local id, stats = 0, 0

                if self.hero.items[i] then
                    id = self.hero.items[i]:encode_id()
                    stats = self.hero.items[i]:encode()
                    self.hero.items[i].owner = p --binds item after saving
                end

                data[#data + 1] = id
                data[#data + 1] = stats
            end
            self.hero.teleport = GetUnitAbilityLevel(Backpack[self.pid], TELEPORT_HOME.id)
            data[#data + 1] = self.hero.teleport
            self.hero.reveal = GetUnitAbilityLevel(Backpack[self.pid], FourCC('A0FK'))
            data[#data + 1] = self.hero.reveal
            self.hero.platinum = IMinBJ(GetCurrency(self.pid, PLATINUM), MAX_PLAT_ARC_CRYS)
            data[#data + 1] = self.hero.platinum
            self.hero.arcadite = IMinBJ(GetCurrency(self.pid, ARCADITE), MAX_PLAT_ARC_CRYS)
            data[#data + 1] = self.hero.arcadite
            self.hero.crystal = IMinBJ(GetCurrency(self.pid, CRYSTAL), MAX_PLAT_ARC_CRYS)
            data[#data + 1] = self.hero.crystal
            self.hero.time = IMinBJ(self.hero.time, MAX_TIME_PLAYED)
            data[#data + 1] = self.hero.time
            self.hero.gold = IMinBJ(GetCurrency(self.pid, GOLD), MAX_GOLD_LUMB)
            data[#data + 1] = self.hero.gold
            self.hero.lumber = IMinBJ(GetCurrency(self.pid, LUMBER), MAX_GOLD_LUMB)
            data[#data + 1] = self.hero.lumber
            data[#data + 1] = self.hero.skin

            local s = Compile(self.pid, data)

            if GAME_STATE == 2 then
                local hero_name = GetObjectName(HeroID[self.pid])
                local path = GetCharacterPath(self.pid, self.currentSlot)
                local backup_path = MAP_NAME .. "\\BACKUP\\" .. User[p].name .. "\\" .. hero_name .. self.hero.level .. "_" .. os.time() .. "\\slot" .. (self.currentSlot + 1) .. ".pld"

                if GetLocalPlayer() == p then
                    FileIO.Save(path, hero_name .. " " .. self.hero.level .. "\n" .. s)
                    FileIO.Save(backup_path, hero_name .. " " .. self.hero.level .. "\n" .. s)
                end
            end

            self:saveProfile()
        end

        ---@type fun(self: Profile, data: string)
        function thistype:loadCharacter(data)
            local p = Player(self.pid - 1)
            data = Load(data, p)

            if not data then
                DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                return
            end

            local index = 0
            local counter = function()
                index = index + 1
                return index
            end

            self.hero.hardcore = data[counter()]
            self.hero.prestige = data[counter()]
            self.hero.id = data[counter()]
            self.hero.level = data[counter()]
            self.hero.str = IMinBJ(MAX_STATS, data[counter()])
            self.hero.agi = IMinBJ(MAX_STATS, data[counter()])
            self.hero.int = IMinBJ(MAX_STATS, data[counter()])
            for i = 0, MAX_INVENTORY_SLOTS - 1 do
                local id = data[counter()]
                local stats = data[counter()]

                self.hero.items[i] = Item.decode(id, stats)
                if self.hero.items[i] then
                    self.hero.items[i].owner = p
                end
            end
            self.hero.teleport = data[counter()]
            self.hero.reveal = data[counter()]
            self.hero.platinum = data[counter()]
            self.hero.arcadite = data[counter()]
            self.hero.crystal = data[counter()]
            self.hero.time = data[counter()]
            self.hero.gold = data[counter()]
            self.hero.lumber = data[counter()]
            self.hero.skin = data[counter()]

            local hardcore = self.phtl[self.currentSlot] & 0x1
            local prestige = (self.phtl[self.currentSlot] & 0x6) >> 1
            local id = (self.phtl[self.currentSlot] & 0x1F8) >> 3
            local herolevel = (self.phtl[self.currentSlot] & 0x7FE00) >> 9

            if DEV_ENABLED then
                print("hardcore: " .. hardcore .. " expected: " .. self.hero.hardcore)
                print("prestige: " .. prestige .. " expected: " .. self.hero.prestige)
                print("id: " .. id .. " expected: " .. self.hero.id)
                print("herolevel: " .. herolevel .. " expected: " .. self.hero.level)
            end

            --TODO remove hero level mismatch?
            if (hardcore ~= self.hero.hardcore) or (prestige ~= self.hero.prestige) or (id ~= self.hero.id) or (herolevel ~= self.hero.level) then
                DisplayTextToPlayer(p, 0, 0, "Invalid character data!")
                self.hero:wipeData()
                self:open_dialog()
                return
            end

            CharacterSetup(self.pid, true)
        end

        function thistype:skin(index)
            self.hero.skin = index

            BlzSetUnitSkin(Backpack[self.pid], CosmeticTable.skins[index].id)
            if CosmeticTable.skins[index].id == FourCC('H02O') then
                AddUnitAnimationProperties(Backpack[self.pid], "alternate", true)
            end
        end

        function thistype:onDestroy()
            self.hero:destroy()
            self.save_timer:destroy()
        end

        function thistype:destroy()
            self:onDestroy()

            thistype[self] = nil
            self = nil
        end
    end

    ---@class HeroData
    ---@field pid integer
    ---@field str integer
    ---@field agi integer
    ---@field int integer
    ---@field teleport integer
    ---@field reveal integer
    ---@field items Item[]
    ---@field gold integer
    ---@field lumber integer
    ---@field platinum integer
    ---@field arcadite integer
    ---@field crystal integer
    ---@field time integer
    ---@field id integer
    ---@field level integer
    ---@field hardcore integer
    ---@field prestige integer
    ---@field skin integer
    ---@field wipeData function
    ---@field create function
    ---@field destroy function
    ---@field base integer
    HeroData = {}
    do
        local thistype = HeroData
        local mt = { __index = HeroData }

        thistype.SKIN_DEFAULT = 26 --wisp

        ---@type fun(pid: integer):HeroData
        function thistype.create(pid)
            local self = {
                pid = pid,
                items = {},
                skin = thistype.SKIN_DEFAULT,
                reveal = 0,
                teleport = 0,
                hardcore = 0,
                prestige = 0,
                base = 0,
                time = 0,
            }

            setmetatable(self, mt)

            return self
        end

        function thistype:wipeData()
            self.str = 0
            self.agi = 0
            self.int = 0
            self.teleport = 0
            self.reveal = 0
            self.gold = 0
            self.lumber = 0
            self.platinum = 0
            self.arcadite = 0
            self.crystal = 0
            self.time = 0
            self.id = 0
            self.level = 0
            self.hardcore = 0
            self.prestige = 0
            self.skin = thistype.SKIN_DEFAULT
            self.base = 0

            for i = 0, MAX_INVENTORY_SLOTS - 1 do
                if self.items[i] then
                    if isImportantItem(self.items[i].obj) then
                        CreateItem(self.items[i].id, GetLocationX(TOWN_CENTER), GetLocationY(TOWN_CENTER))
                    end
                    self.items[i]:destroy()
                    self.items[i] = nil
                end
            end
        end

        function thistype:onDestroy()
            self:wipeData()
        end

        function thistype:destroy()
            self:onDestroy()

            thistype[self] = nil
            self = nil
        end
    end

    ---@type fun(heroLevel: integer):integer
    function TomeCap(heroLevel)
        return R2I(heroLevel ^ 3 * 0.002 + 10 * heroLevel)
    end

    ---@type fun(pid: integer, load: boolean)
    function CharacterSetup(pid, load)
        local myHero = Profile[pid].hero ---@type HeroData 
        local p = Player(pid - 1)

        if load then
            Hero[pid] = CreateUnit(p, SAVE_UNIT_TYPE[myHero.id], GetRectCenterX(gg_rct_ChurchSpawn), GetRectCenterY(gg_rct_ChurchSpawn), 270.)
            HeroID[pid] = GetUnitTypeId(Hero[pid])
            SELECTING_HERO[pid] = false
            Hardcore[pid] = (myHero.hardcore > 0)

            SetCurrency(pid, GOLD, myHero.gold)
            SetCurrency(pid, LUMBER, myHero.lumber)
            SetCurrency(pid, PLATINUM, myHero.platinum)
            SetCurrency(pid, ARCADITE, myHero.arcadite)
            SetCurrency(pid, CRYSTAL, myHero.crystal)

            LOAD_FLAG[pid] = true
            SetHeroLevelBJ(Hero[pid], myHero.level, false)
            LOAD_FLAG[pid] = false
            ModifyHeroStat(bj_HEROSTAT_STR, Hero[pid], bj_MODIFYMETHOD_SET, myHero.str)
            ModifyHeroStat(bj_HEROSTAT_AGI, Hero[pid], bj_MODIFYMETHOD_SET, myHero.agi)
            ModifyHeroStat(bj_HEROSTAT_INT, Hero[pid], bj_MODIFYMETHOD_SET, myHero.int)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", Hero[pid], "origin"))
            if GetLocalPlayer() == p then
                SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
            end
            SetCamera(pid, gg_rct_Church)
            SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]))
            SetUnitState(Hero[pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(Hero[pid]))
        else
            -- new characters can save immediately
            CANNOT_LOAD[pid] = true
        end

        -- hero proficiencies / inner resistances
        Unit[Hero[pid]].mr = HeroStats[HeroID[pid]].magic_resist
        Unit[Hero[pid]].pr = HeroStats[HeroID[pid]].phys_resist
        Unit[Hero[pid]].pm = HeroStats[HeroID[pid]].phys_damage
        Unit[Hero[pid]].cc_flat = HeroStats[HeroID[pid]].crit_chance
        Unit[Hero[pid]].cd_flat = HeroStats[HeroID[pid]].crit_damage

        HERO_GROUP[#HERO_GROUP + 1] = Hero[pid]
        SetPrestigeEffects(pid)
        Colosseum_XP[pid] = 1.00

        -- grave
        HeroGrave[pid] = CreateUnit(p, GRAVE, 30000, 30000, 270)
        SuspendHeroXP(HeroGrave[pid], true)
        ShowUnit(HeroGrave[pid], false)

        -- backpack
        Backpack[pid] = CreateUnit(p, BACKPACK, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)

        -- show backpack hero panel only for player
        if GetLocalPlayer() == p then
            EnablePreSelect(true, true)
            EnableSelect(true, true)
            ClearSelection()
            SelectUnit(Hero[pid], true)
            ResetToGameCamera(0)
            PanCameraToTimed(GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)
            BlzSetUnitBooleanField(Backpack[pid], UNIT_BF_HERO_HIDE_HERO_INTERFACE_ICON, false)
        end

        SetUnitOwner(Backpack[pid], Player(PLAYER_NEUTRAL_PASSIVE), false)
        SetUnitOwner(Backpack[pid], p, false)
        SetUnitAnimation(Backpack[pid], "stand")
        if GetHeroLevel(Hero[pid]) > 1 then
            SetHeroLevel(Backpack[pid], GetHeroLevel(Hero[pid]), false)
        end
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

        -- prevent actions disappearing on meta
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A03C'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A03V'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A0L0'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A0GD'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A06X'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00F'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A08Y'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00I'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00B'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A02T'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A031'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A067'))

        UpdatePrestigeTooltips()

        SetUnitAbilityLevel(Backpack[pid], TELEPORT_HOME.id, IMaxBJ(1, myHero.teleport))
        SetUnitAbilityLevel(Backpack[pid], TELEPORT.id, IMaxBJ(1, myHero.teleport))
        SetUnitAbilityLevel(Backpack[pid], FourCC('A0FK'), IMaxBJ(1, myHero.reveal))

        -- load items
        if load then
            -- load saved bp skin
            if CosmeticTable[User[p].name][myHero.skin] > 0 then
                Profile[pid]:skin(myHero.skin)
            end

            for i = 0, 5 do
                if myHero.items[i] then
                    UnitAddItem(Hero[pid], myHero.items[i].obj)
                    UnitDropItemSlot(Hero[pid], myHero.items[i].obj, i)
                end

                if myHero.items[i + 6] then
                    UnitAddItem(Backpack[pid], myHero.items[i + 6].obj)
                    UnitDropItemSlot(Backpack[pid], myHero.items[i + 6].obj, i)
                end
            end
        end

        -- heal to max
        SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]))
        SetUnitState(Hero[pid], UNIT_STATE_MANA, (HeroID[pid] ~= HERO_VAMPIRE and BlzGetUnitMaxMana(Hero[pid])) or 0)
    end

end, Debug and Debug.getLine())
