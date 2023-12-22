if Debug then Debug.beginFile 'PlayerData' end

OnInit.global("PlayerData", function(require)
    require 'CodeGen'

    HERO_PROF=__jarray(0) ---@type integer[] 
    LOAD_FLAG=__jarray(false) ---@type boolean[] 

    MAX_TIME_PLAYED         = 1000000  ---@type integer --max minutes - 16666 hours
    MAX_PLAT_ARC_CRYS         = 100000 ---@type integer 
    MAX_GOLD_LUMB         = 10000000 ---@type integer 
    MAX_PHTL         = 4000000  ---@type integer 
    MAX_UPGRADE_LEVEL         = 10 ---@type integer 
    MAX_STATS         = 250000 ---@type integer 
    MAX_SLOTS         = 29 ---@type integer 
    MAX_INVENTORY_SLOTS         = 24 ---@type integer 

    KEY_PROFILE         = 0 ---@type integer 
    KEY_CHARACTER         = 1 ---@type integer 

    VARIATION_FLAG=__jarray(0) ---@type integer[] 

    loadPage=__jarray(0) ---@type integer[] 
    loadCounter=__jarray(0) ---@type integer[] 
    newSlotFlag         = false ---@type boolean 
    deleteMode=__jarray(false) ---@type boolean[] 
    loadSlotCounter=__jarray(0) ---@type integer[] 

    newcharacter=__jarray(false) ---@type boolean[] 
    CANNOT_LOAD=__jarray(false) ---@type boolean[] 

    --boolean LOAD_SAFE = true

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
    HeroData = {}
    do
        local thistype = HeroData

        ---@type fun(pid: integer):HeroData
        function thistype.create(pid)
            local self = {
                pid = pid,
                items = {},
                skin = 26,
                reveal = 0,
                teleport = 0
            }

            setmetatable(self, { __index = HeroData })

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
            self.skin = 26

            for i = 0, MAX_INVENTORY_SLOTS - 1 do
                if self.items[i] then
                    if isImportantItem(self.items[i].obj) then
                        Item.create(CreateItemLoc(self.items[i].id, TownCenter))
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

    ---@class Profile
    ---@field pid integer
    ---@field currentSlot integer
    ---@field profileHash integer
    ---@field phtl integer[]
    ---@field skin function
    ---@field hero HeroData
    ---@field sync_event trigger
    ---@field savecode string[]
    ---@field load function
    ---@field LoadSync function
    ---@field getSlotsUsed function
    ---@field saveProfile function
    ---@field saveCharacter function
    ---@field loadCharacter function
    ---@field create function
    Profile = {}
    do
        local thistype = Profile
        thistype.sync_event = CreateTrigger() ---@type trigger 
        thistype.savecode=__jarray("") ---@type string[] [PLAYER_CAP]

        -- metatable to handle indices (Profile[1])
        local mt = {
            __index = function(tbl, key)
                if type(key) == "number" then
                    return rawget(tbl, key)
                end
            end
        }

        -- Set metatable for the Profile table
        setmetatable(thistype, mt)

        ---@type fun(pid: integer):Profile
        function thistype.create(pid)
            local self = {
                pid = pid,
                currentSlot = 0,
                profileHash = GetRandomInt(500000, 510000),
                phtl = __jarray(0),
                hero = HeroData.create(pid),
                timers = {}
            }

            setmetatable(self, { __index = Profile })

            return self
        end

        ---@type fun(s: string, pid: integer):Profile
        function thistype.load(s, pid)
            local p = Player(pid - 1)

            --fail to load
            if not Load(s, p) then
                DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                return nil
            end

            local vers = 0
            local index = 1
            vers = SaveData[pid][index]

            --TODO implement version handling
            if vers <= SAVE_LOAD_VERSION - 2 or vers >= SAVE_LOAD_VERSION + 2 then
                DisplayTimedTextToPlayer(p, 0, 0, 30., "Profile data corrupt or version mismatch!")
                return nil
            end

            local self = thistype.create(pid)
            local id = 0
            local prestige = 0

            index = index + 1
            DEBUGMSG("Save Load Version: " .. (SaveData[pid][index]))

            for i = 0, MAX_SLOTS do
                self.phtl[i] = SaveData[pid][index]
                prestige = (self.phtl[i] & 0x6) >> 1
                id = (self.phtl[i] & 0x1F8) >> 3
                index = index + 1

                if prestige > 0 then
                    AllocatePrestige(pid, prestige, id)
                end
                --call DEBUGMSG((self.phtl[i]))
            end

            self.profileHash = SaveData[pid][index]

            return profile
        end

        ---@return boolean
        function thistype.LoadSync()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1

            thistype.savecode[pid - 1] = BlzGetTriggerSyncData()

            if StringLength(thistype.savecode[pid - 1]) > 1 then
                if not Profile[pid] then
                    Profile[pid]:load(thistype.savecode[pid - 1], pid)
                else
                    Profile[pid]:loadCharacter(thistype.savecode[pid - 1])
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

            SaveData[self.pid] = {}

            table.insert(SaveData[self.pid], SAVE_LOAD_VERSION)

            for i = 0, MAX_SLOTS do

                if i == self.currentSlot then
                    if deleteMode[self.pid] then
                        self.phtl[i] = 0
                    else
                        self.phtl[i] = self.hero.hardcore + (self.hero.prestige << 1) + (self.hero.id << 3) + (self.hero.level << 9)
                    end
                    --call DEBUGMSG((.hero.prestige) .. " " .. (.hero.hardcore) .. " " .. (.hero.id) .. " " .. (.hero.level))
                end

                table.insert(SaveData[self.pid], self.phtl[i])
            end

            table.insert(SaveData[self.pid], self.profileHash)

            local s = Compile(self.pid)

            if GetLocalPlayer() == p then
                FileIO.Save(MAP_NAME .. "\\" .. User[p].name .. "\\" .. "profile.pld", "\n" .. s)
                FileIO.Save(MAP_NAME .. "\\" .. "BACKUP" .. "\\" .. GetObjectName(HeroID[self.pid]) .. GetHeroLevel(Hero[self.pid]) .. "_" .. TIME .. "\\" .. User[p].name .. "\\" .. "profile.pld", "\n" .. s)
            end

            DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Your data has been saved successfully. (Warcraft III\\CustomMapData\\CoT Nevermore\\" .. GetPlayerName(p) .. ")")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffffcc00Use|r -load |cffffcc00the next time you play to load your hero.")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "|cffFF0000YOU MUST RESTART WARCRAFT BEFORE LOADING AGAIN!|r")
            DisplayTimedTextToPlayer(p, 0, 0, 60, "-------------------------------------------------------------------")
        end

        function thistype:saveCharacter()
            local p = Player(self.pid - 1)

            SaveData[self.pid] = {}

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

            table.insert(SaveData[self.pid], self.profileHash)
            table.insert(SaveData[self.pid], self.hero.prestige)
            if Hardcore[self.pid] == true then
                self.hero.hardcore = 1
            else
                self.hero.hardcore = 0
            end
            table.insert(SaveData[self.pid], self.hero.hardcore)
            self.hero.id = LoadInteger(SAVE_TABLE, KEY_UNITS, HeroID[self.pid])
            table.insert(SaveData[self.pid], self.hero.id)
            self.hero.level = GetHeroLevel(Hero[self.pid])
            table.insert(SaveData[self.pid], self.hero.level)
            self.hero.str = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_STR, Hero[self.pid], false))
            self.hero.agi = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_AGI, Hero[self.pid], false))
            self.hero.int = IMinBJ(MAX_STATS, GetHeroStatBJ(bj_HEROSTAT_INT, Hero[self.pid], false))
            table.insert(SaveData[self.pid], self.hero.str)
            table.insert(SaveData[self.pid], self.hero.agi)
            table.insert(SaveData[self.pid], self.hero.int)
            for i = 0, MAX_INVENTORY_SLOTS - 1 do
                table.insert(SaveData[self.pid], self.hero.items[i]:encode_id())
                table.insert(SaveData[self.pid], self.hero.items[i]:encode())
                self.hero.items[i].owner = p
            end
            self.hero.teleport = GetUnitAbilityLevel(Backpack[self.pid], FourCC('A0FV'))
            table.insert(SaveData[self.pid], self.hero.teleport)
            self.hero.reveal = GetUnitAbilityLevel(Backpack[self.pid], FourCC('A0FK'))
            table.insert(SaveData[self.pid], self.hero.reveal)
            self.hero.platinum = IMinBJ(GetCurrency(self.pid, PLATINUM), MAX_PLAT_ARC_CRYS)
            table.insert(SaveData[self.pid], self.hero.platinum)
            self.hero.arcadite = IMinBJ(GetCurrency(self.pid, ARCADITE), MAX_PLAT_ARC_CRYS)
            table.insert(SaveData[self.pid], self.hero.arcadite)
            self.hero.crystal = IMinBJ(GetCurrency(self.pid, CRYSTAL), MAX_PLAT_ARC_CRYS)
            table.insert(SaveData[self.pid], self.hero.crystal)
            self.hero.time = IMinBJ(TimePlayed[self.pid], MAX_TIME_PLAYED)
            table.insert(SaveData[self.pid], self.hero.time)
            self.hero.gold = IMinBJ(GetCurrency(self.pid, GOLD), MAX_GOLD_LUMB)
            table.insert(SaveData[self.pid], self.hero.gold)
            self.hero.lumber = IMinBJ(GetCurrency(self.pid, LUMBER), MAX_GOLD_LUMB)
            table.insert(SaveData[self.pid], self.hero.lumber)
            table.insert(SaveData[self.pid], self.hero.skin)

            Compile(self.pid)

            Profile[self.pid]:saveProfile()
        end

        ---@type fun(data: string)
        function thistype:loadCharacter(data)
            local p = Player(self.pid - 1)

            if not Load(data, p) then
                DisplayTimedTextToPlayer(p, 0, 0, 30., GetCodeGenError())
                return
            end

            local index = 1
            local hash = SaveData[self.pid][index]

            index = index + 1
            self.hero.prestige = SaveData[self.pid][index]
            index = index + 1
            self.hero.hardcore = SaveData[self.pid][index]
            index = index + 1
            self.hero.id = SaveData[self.pid][index]
            index = index + 1
            self.hero.level = SaveData[self.pid][index]
            index = index + 1
            self.hero.str = IMinBJ(MAX_STATS, SaveData[self.pid][index])
            index = index + 1
            self.hero.agi = IMinBJ(MAX_STATS, SaveData[self.pid][index])
            index = index + 1
            self.hero.int = IMinBJ(MAX_STATS, SaveData[self.pid][index])
            index = index + 1
            for i = 0, MAX_INVENTORY_SLOTS - 1 do
                self.hero.items[i] = Item.decode_id(SaveData[self.pid][index])
                index = index + 1
                if self.hero.items[i] then
                    self.hero.items[i].owner = p
                    self.hero.items[i]:decode(SaveData[self.pid][index])
                end
                index = index + 1
            end
            self.hero.teleport = SaveData[self.pid][index]
            index = index + 1
            self.hero.reveal = SaveData[self.pid][index]
            index = index + 1
            self.hero.platinum = SaveData[self.pid][index]
            index = index + 1
            self.hero.arcadite = SaveData[self.pid][index]
            index = index + 1
            self.hero.crystal = SaveData[self.pid][index]
            index = index + 1
            self.hero.time = SaveData[self.pid][index]
            index = index + 1
            self.hero.gold = SaveData[self.pid][index]
            index = index + 1
            self.hero.lumber = SaveData[self.pid][index]
            index = index + 1
            self.hero.skin = SaveData[self.pid][index]

            local hardcore = self.phtl[self.currentSlot] & 0x1
            local prestige = (self.phtl[self.currentSlot] & 0x6) >> 1
            local id = (self.phtl[self.currentSlot] & 0x1F8) >> 3
            local herolevel = (self.phtl[self.currentSlot] & 0x7FE00) >> 9

            --call DEBUGMSG((hero.prestige) .. " " .. (hero.hardcore) .. " " .. (hero.id) .. " " .. (hero.level)) 
            --call DEBUGMSG((prestige) .. " " .. (hardcore) .. " " .. (id) .. " " .. (herolevel)) 

            --TODO remove hero level mismatch?
            if (hash ~= profileHash) or (prestige ~= self.hero.prestige) or (hardcore ~= self.hero.hardcore) or (id ~= self.hero.id) or (herolevel ~= self.hero.level) then
                DisplayTextToPlayer(p, 0, 0, "Invalid character data!")
                self.hero:wipeData()
                DisplayHeroSelectionDialog(self.pid)
                return
            end

            CharacterSetup(self.pid, true)
        end

        function thistype:skin(id)
            self.hero.skin = id

            BlzSetUnitSkin(Backpack[pid], skinID[id])
            if skinID[id] == FourCC('H02O') then
                AddUnitAnimationProperties(Backpack[pid], "alternate", true)
            end
        end

        function thistype:onDestroy()
            self.hero:destroy()
        end

        function thistype:destroy()
            self:onDestroy()

            thistype[self] = nil
        end
    end

    ---@class PlayerTimer
    ---@field timer TimerQueue
    ---@field pid integer
    ---@field tpid integer
    ---@field str number
    ---@field agi number
    ---@field int number
    ---@field x number
    ---@field y number
    ---@field x2 number
    ---@field y2 number
    ---@field dmg number
    ---@field dur number
    ---@field armor number
    ---@field aoe number
    ---@field angle number
    ---@field speed number
    ---@field time number
    ---@field ug group
    ---@field sfx effect
    ---@field lfx lightning
    ---@field source unit
    ---@field target unit
    ---@field curve BezierCurve
    ---@field create function
    ---@field destroy function
    ---@field song integer
    ---@field uid integer
    PlayerTimer = {}
    do
        local thistype = PlayerTimer

        ---@type fun():PlayerTimer
        function thistype.create()
            local self = {
                timer = TimerQueue.create()
            }

            setmetatable(self, { __index = PlayerTimer })

            return self
        end

        function thistype:destroy()
            if self.ug then
                DestroyGroup(self.ug)
            end

            if self.sfx then
                DestroyEffect(self.sfx)
            end

            if self.lfx then
                DestroyLightning(self.lfx)
            end

            if self.timer then
                self.timer:destroy()
            end

            if self.curve then
                self.curve:destroy()
            end

            TimerList[self.pid]:removeTimer(self)
        end
    end

    ---@class TimerList
    ---@field pid integer
    ---@field timers PlayerTimer[]
    ---@field removeTimer function
    ---@field get function
    ---@field has function
    ---@field stopAllTimers function
    ---@field add function
    ---@field create function
    TimerList = {}
    do
        local thistype = TimerList

        -- metatable to handle indices (TimerList[1])
        local mt = {
            __index = function(tbl, key)
                if type(key) == "number" then
                    if rawget(tbl, key) then
                        return rawget(tbl, key)
                    else
                        local new = thistype.create(key)
                        rawset(tbl, key, new)
                        return new
                    end
                end
            end
        }

        -- Set metatable for the TimerList table
        setmetatable(thistype, mt)

        ---@type fun():TimerList
        function thistype.create(pid)
            local self = {
                pid = pid,
                timers = {}
            }

            setmetatable(self, { __index = TimerList })

            return self
        end

        ---@type fun(pt: PlayerTimer)
        function thistype:removeTimer(pt)
            for i = 1, #self.timers do
                if self.timers[i] == pt then
                    self.timers[i] = self.timers[#self.timers]
                    self.timers[#self.timers] = nil
                    break
                end
            end
        end

        --[[returns first timer found
        source and target may be omitted if only looking by tag]]
        ---@type fun(tag: any, source: unit?, target: unit?):PlayerTimer
        function thistype:get(tag, source, target)
            for i = 1, #self.timers do
                if self.timers[i].tag == tag and (self.timers[i].target == target or not target) and (self.timers[i].source == source or not source) then
                    return self.timers[i]
                end
            end

            return nil
        end

        --source and target may be omitted if only looking by tag
        ---@type fun(tag: any, source: unit?, target: unit?):boolean
        function thistype:has(tag, source, target)
            return self:get(tag, source, target) ~= nil
        end

        ---optional tag to only stop timers with such tag
        ---@type fun(tag: any)
        function thistype:stopAllTimers(tag)
            local i = 1
            while i <= #self.timers do
                if (not tag) or self.timers[i].tag == tag then
                    self.timers[i]:destroy()
                else
                    i = i + 1
                end
            end
        end

        --PlayerTimer constructor
        ---@type fun():PlayerTimer
        function thistype:add()
            local pt = PlayerTimer.create() ---@class PlayerTimer 

            pt.pid = self.pid
            self.timers[#self.timers + 1] = pt

            return pt
        end
    end

    ---@type fun(heroLevel: integer):integer
    function TomeCap(heroLevel)
        return R2I(Pow(heroLevel, 3) * 0.002 + 10 * heroLevel)
    end

    ---@type fun(pid: integer, load: boolean)
    function CharacterSetup(pid, load)
        local myHero          = Profile[pid].hero ---@type HeroData 
        local p        = Player(pid - 1) ---@type player 

        ItemMagicRes[pid] = 1
        ItemDamageRes[pid] = 1

        if load then
            Hero[pid] = CreateUnit(p, SAVE_UNIT_TYPE[myHero.id], GetRectCenterX(gg_rct_ChurchSpawn), GetRectCenterY(gg_rct_ChurchSpawn), 270.)
            HeroID[pid] = GetUnitTypeId(Hero[pid])
            urhome[pid] = 0
            selectingHero[pid] = false
            Hardcore[pid] = (myHero.hardcore > 0)

            SetCurrency(pid, GOLD, myHero.gold)
            SetCurrency(pid, LUMBER, myHero.lumber)
            SetCurrency(pid, PLATINUM, myHero.platinum)
            SetCurrency(pid, ARCADITE, myHero.arcadite)
            SetCurrency(pid, CRYSTAL, myHero.crystal)

            LOAD_FLAG[pid] = true
            SetHeroLevelBJ(Hero[pid], myHero.level, false)
            LOAD_FLAG[pid] = false
            TimePlayed[pid] = myHero.time
            ModifyHeroStat(bj_HEROSTAT_STR, Hero[pid], bj_MODIFYMETHOD_SET, myHero.str)
            ModifyHeroStat(bj_HEROSTAT_AGI, Hero[pid], bj_MODIFYMETHOD_SET, myHero.agi)
            ModifyHeroStat(bj_HEROSTAT_INT, Hero[pid], bj_MODIFYMETHOD_SET, myHero.int)
            DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Human\\ReviveHuman\\ReviveHuman.mdl", Hero[pid], "origin"))
            if GetLocalPlayer() == p then
                SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
            end
            SetCameraBoundsRectForPlayerEx(p, gg_rct_Church)
        else
            --new characters can save immediately
            CANNOT_LOAD[pid] = true
            --set hero values here?
        end

        GroupAddUnit(HeroGroup, Hero[pid])
        SetPrestigeEffects(pid)
        Colosseum_XP[pid] = 1.00

        --grave
        HeroGrave[pid] = CreateUnit(p, GRAVE, 30000, 30000, 270)
        SuspendHeroXP(HeroGrave[pid], true)
        ShowUnit(HeroGrave[pid], false)

        --backpack
        Backpack[pid] = CreateUnit(p, BACKPACK, 30000, 30000, 0)

        --show backpack hero panel only for player
        if GetLocalPlayer() == p then
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
        UnitAddAbility(Backpack[pid], FourCC('A02J'))
        UnitAddAbility(Backpack[pid], FourCC('A0FK'))
        UnitAddAbility(Backpack[pid], FourCC('A0FV'))
        UnitAddAbility(Backpack[pid], FourCC('A04M'))
        UnitAddAbility(Backpack[pid], FourCC('A0DT'))
        UnitAddAbility(Backpack[pid], FourCC('A05N'))

        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A03C')) --prevent actions disappearing on meta
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A03V'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A0L0'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A0GD'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A06X'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A00F'))
        UnitMakeAbilityPermanent(Hero[pid], true, FourCC('A08Y'))

        UpdatePrestigeTooltips()

        SetUnitAbilityLevel(Backpack[pid], FourCC('A0FV'), IMaxBJ(1, myHero.teleport))
        SetUnitAbilityLevel(Backpack[pid], FourCC('A02J'), IMaxBJ(1, myHero.teleport))
        SetUnitAbilityLevel(Backpack[pid], FourCC('A0FK'), IMaxBJ(1, myHero.reveal))

        --hero proficiencies / inner resistances

        if HeroID[pid] == HERO_PHOENIX_RANGER then
            HERO_PROF[pid]      = PROF_BOW + PROF_LEATHER
            PhysicalTakenBase[pid] = 2.0
            DealtDmgBase[pid]      = 1.3
            MagicTakenBase[pid]    = 1.8
        elseif HeroID[pid] == HERO_DARK_SUMMONER then
            HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid] = 1.8
            DealtDmgBase[pid]      = 1.0
            MagicTakenBase[pid]    = 1.6
        elseif HeroID[pid] == HERO_BARD then
            HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid] = 1.8
            DealtDmgBase[pid]      = 1.0
            MagicTakenBase[pid]    = 1.6
        elseif HeroID[pid] == HERO_ARCANIST then
            HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid] = 1.8
            DealtDmgBase[pid]      = 1.0
            MagicTakenBase[pid]    = 1.6
            UnitRemoveAbility(Hero[pid], ARCANECOMETS.id)
        elseif HeroID[pid] == HERO_MASTER_ROGUE then
            HERO_PROF[pid]      = PROF_DAGGER + PROF_LEATHER
            PhysicalTakenBase[pid] = 1.6
            DealtDmgBase[pid]      = 1.25
            MagicTakenBase[pid]    = 1.8
        elseif HeroID[pid] == HERO_THUNDERBLADE then
            HERO_PROF[pid]      = PROF_DAGGER + PROF_LEATHER
            PhysicalTakenBase[pid] = 1.6
            DealtDmgBase[pid]      = 1.25
            MagicTakenBase[pid]    = 1.8
        elseif HeroID[pid] == HERO_HYDROMANCER then
            HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid] = 1.8
            DealtDmgBase[pid]      = 1.0
            MagicTakenBase[pid]    = 1.6
        elseif HeroID[pid] == HERO_HIGH_PRIEST then
            HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid] = 1.8
            DealtDmgBase[pid]      = 1.0
            MagicTakenBase[pid]    = 1.6
        elseif HeroID[pid] == HERO_ELEMENTALIST then
            HERO_PROF[pid]      = PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid] = 1.8
            DealtDmgBase[pid]      = 1.0
            MagicTakenBase[pid]    = 1.6
        elseif HeroID[pid] == HERO_BLOODZERKER then
            HERO_PROF[pid]      = PROF_HEAVY + PROF_SWORD + PROF_PLATE
            PhysicalTakenBase[pid] = 1.6
            DealtDmgBase[pid]      = 1.2
            MagicTakenBase[pid]    = 1.8
        elseif HeroID[pid] == HERO_WARRIOR then
            HERO_PROF[pid]      = PROF_HEAVY + PROF_SWORD + PROF_PLATE
            PhysicalTakenBase[pid] = 1.1
            DealtDmgBase[pid]      = 1.2
            MagicTakenBase[pid]    = 1.5
        elseif HeroID[pid] == HERO_ROYAL_GUARDIAN then
            HERO_PROF[pid]      = PROF_HEAVY + PROF_SWORD + PROF_PLATE + PROF_FULLPLATE
            PhysicalTakenBase[pid] = 0.9
            DealtDmgBase[pid]      = 1.2
            MagicTakenBase[pid]    = 1.5
            BlzUnitHideAbility(Hero[pid], FourCC('A06K'), true)
        elseif HeroID[pid] == HERO_OBLIVION_GUARD then
            HERO_PROF[pid]      = PROF_HEAVY + PROF_PLATE + PROF_FULLPLATE
            PhysicalTakenBase[pid] = 1.0
            DealtDmgBase[pid]      = 1.2
            MagicTakenBase[pid]    = 1.3
            BodyOfFireCharges[pid] = 5 --default

            if GetLocalPlayer() == Player(pid - 1) then
                BlzSetAbilityIcon(BODYOFFIRE.id, "ReplaceableTextures\\CommandButtons\\PASBodyOfFire" .. (BodyOfFireCharges[pid]) .. ".blp")
            end
        elseif HeroID[pid] == HERO_VAMPIRE then
            HERO_PROF[pid]      = PROF_HEAVY + PROF_PLATE + PROF_DAGGER + PROF_LEATHER
            PhysicalTakenBase[pid]        = 1.5
            DealtDmgBase[pid]   = 1.25
            MagicTakenBase[pid] = 1.5
        elseif HeroID[pid] == HERO_ARCANE_WARRIOR then
            HERO_PROF[pid]      = PROF_HEAVY + PROF_FULLPLATE + PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid]        = 1.1
            DealtDmgBase[pid]   = 1.2
            MagicTakenBase[pid] = 1.1
        elseif HeroID[pid] == HERO_DARK_SAVIOR or HeroID[pid] == HERO_DARK_SAVIOR_DEMON then
            HERO_PROF[pid]      = PROF_SWORD + PROF_PLATE + PROF_STAFF + PROF_CLOTH
            PhysicalTakenBase[pid]        = 1.6
            DealtDmgBase[pid]   = 1.2
            MagicTakenBase[pid] = 1.0
        elseif HeroID[pid] == HERO_SAVIOR then
            HERO_PROF[pid]      = PROF_HEAVY + PROF_FULLPLATE + PROF_PLATE + PROF_SWORD
            PhysicalTakenBase[pid]        = 1.2
            DealtDmgBase[pid]   = 1.2
            MagicTakenBase[pid] = 1.3
        elseif HeroID[pid] == HERO_ASSASSIN then
            HERO_PROF[pid]      = PROF_DAGGER + PROF_LEATHER
            PhysicalTakenBase[pid]        = 1.6
            DealtDmgBase[pid]   = 1.25
            MagicTakenBase[pid] = 1.8
            UnitRemoveAbility(Hero[pid], BLADESPIN.id)
        elseif HeroID[pid] == HERO_MARKSMAN or HeroID[pid] == HERO_MARKSMAN_SNIPER then
            HERO_PROF[pid]      = PROF_BOW + PROF_LEATHER
            PhysicalTakenBase[pid]        = 2.0
            DealtDmgBase[pid]   = 1.3
            MagicTakenBase[pid] = 1.8
        end

        --load items
        if load then
            --load saved bp skin
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

        --heal to max
        SetWidgetLife(Hero[pid], BlzGetUnitMaxHP(Hero[pid]))
        SetUnitState(Hero[pid], UNIT_STATE_MANA, BlzGetUnitMaxMana(Hero[pid]))
    end

end)

if Debug then Debug.endFile() end
