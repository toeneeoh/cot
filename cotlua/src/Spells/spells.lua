--[[
    spell.lua

    A library that handles spell related events:
        (EVENT_PLAYER_UNIT_SPELL_EFFECT,
        EVENT_PLAYER_UNIT_SPELL_CAST,
        EVENT_PLAYER_UNIT_SPELL_FINISH,
        EVENT_PLAYER_HERO_SKILL,
        EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    
    Provides a spell object factory for defining abilities by their ID
]]

OnInit.final("Spells", function(Require)
    Require("Users")
    Require("UnitEvent")

    SONG_WAR     = FourCC('A024') ---@type integer 
    SONG_HARMONY = FourCC('A01A') ---@type integer 
    SONG_PEACE   = FourCC('A09X') ---@type integer 
    SONG_FATIGUE = FourCC('A00N') ---@type integer 

    --storage for spell definitions
    Spells = {}
    INVALID_TARGET_MESSAGE = "|cffff0000Cannot target there!|r" ---@type string 

    ---@class Spell
    ---@field id integer
    ---@field sid integer
    ---@field caster unit
    ---@field target unit
    ---@field pid integer
    ---@field tpid integer
    ---@field ablev integer
    ---@field x number
    ---@field y number
    ---@field targetX number
    ---@field targetY number
    ---@field angle number
    ---@field values table
    ---@field create function
    ---@field destroy function
    ---@field tag string
    ---@field define function
    ---@field getTooltip function
    ---@field preCast function
    ---@field onCast function
    ---@field onLearn function
    ---@field TOOLTIPS string[][]
    Spell = {}
    do
        local thistype = Spell
        thistype.TOOLTIPS = array2d("")

        -- memoize metatables for inheritance
        local mts = {}

        ---@type fun(self: Spell, u: unit, sid: integer?): Spell
        function thistype:create(u, sid)
            local spell = {
                pid = GetPlayerId(GetOwningPlayer(u)) + 1,
                ablev = GetUnitAbilityLevel(u, (sid or self.id))
            }

            mts[self] = mts[self] or { __index = self }

            setmetatable(spell, mts[self])

            -- precalculate function values
            if self.values then
                for k, v in pairs(self.values) do -- sync safe
                    if type(v) == "function" then
                        spell[k] = v(spell.pid)
                    else
                        spell[k] = v
                    end
                end
            end

            return spell
        end

        local mt = { __index = function(tbl, key) local v = rawget(tbl, "values") return Spell[key] or (v and v[key]) end }

        local function store_tooltip(id)
            UnitAddAbility(DUMMY_UNIT, id)
            local abil = BlzGetUnitAbility(DUMMY_UNIT, id)
            for ablev = 1, BlzGetAbilityIntegerField(abil, ABILITY_IF_LEVELS) do
                Spell.TOOLTIPS[id][ablev] = BlzGetAbilityStringLevelField(abil, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, ablev - 1)
            end
            UnitRemoveAbility(DUMMY_UNIT, id)
        end

        -- defines a new spell type by ID
        ---@param id integer
        ---@param ... any
        ---@return table
        function thistype.define(id, ...)
            local self = {}

            self.id = FourCC(id)
            self.tag = GetObjectName(self.id) -- lazy tag generation

            setmetatable(self, mt)

            Spells[self.id] = self

            -- store original tooltips
            store_tooltip(self.id)

            -- if multiple ids share a definition, store them
            if ... then
                self.shared = { self.id }
                for i = 1, select('#', ...) do
                    id = FourCC(select(i, ...))
                    Spells[id] = self
                    self.shared[#self.shared + 1] = id
                end
            end

            return self
        end

        local curr
        --[[
            >: no color
            ~: only shows calculated value
            [: normal boost
            {: low boost
            \: no boost
            =: tag identifier
        ]]
        local function parse_brackets(defaultflag, colorflag, prefix, tag, content)
            local color = (colorflag ~= ">" and true) or false
            local alt = IS_ALT_DOWN[curr.pid] or defaultflag == "~"

            if alt then
                local v = curr[tag]
                local calc = (type(v) == "table" and v[curr.pid]) or v

                if prefix == "[" then
                    local sb = Unit[Hero[curr.pid]].spellboost
                    return HL(RealToString(calc * (1. + sb - 0.2)) .. " - " .. RealToString(calc * (1. + sb + 0.2)), color)
                elseif prefix == "{" then
                    if calc < 10 then
                        return HL(string.format("\x25.2f", calc * LBOOST[curr.pid]), color)
                    elseif calc < 1000 then
                        return HL(string.format("\x25.1f", calc * LBOOST[curr.pid]), color)
                    else
                        return HL(RealToString(calc * LBOOST[curr.pid]), color)
                    end
                elseif prefix == "\\" then
                    return HL(RealToString(calc), color)
                end
            else
                return content
            end
        end

        ---@type fun(spell: Spell):string
        function thistype:getTooltip()
            local orig = Spell.TOOLTIPS[self.id][self.ablev]

            if self.values then
                local gsub = string.gsub
                local pattern = "(~?)(>?)([\\{\x25[])(\x25w-)=(.-)]"
                curr = self
                orig = gsub(orig, pattern, parse_brackets)
            end

            return orig
        end

        -- Stub methods
        function thistype.preCast(pid, tpid, caster, target, x, y, targetX, targetY) end
        function thistype.onCast() end
        function thistype.onLearn(source, ablev, pid) end
        -- function thistype.onHit() end
        function thistype.onUnequip(itm, id, index) end
        function thistype.onEquip(itm, id, index) end
        function thistype.setup(u) end
    end

    local function SpellCast()
        local caster  = GetTriggerUnit() ---@type unit 
        local target  = GetSpellTargetUnit() ---@type unit 
        local sid     = GetSpellAbilityId() ---@type integer 
        local p       = GetOwningPlayer(caster)
        local pid     = GetPlayerId(p) + 1 ---@type integer 
        local tpid    = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 
        local x       = GetUnitX(caster) ---@type number 
        local y       = GetUnitY(caster) ---@type number 
        local targetX = GetSpellTargetX() ---@type number 
        local targetY = GetSpellTargetY() ---@type number 

        if Unit[caster] and targetX ~= 0 and targetY ~= 0 then
            Unit[caster].orderX = x
            Unit[caster].orderY = y
            if Unit[caster].movespeed > MOVESPEED.MAX then
                BlzSetUnitFacingEx(caster, bj_RADTODEG * Atan2(targetY - y, targetX - x))
            end
        end

        if Spells[sid] then
            Spells[sid].preCast(pid, tpid, caster, target, x, y, targetX, targetY)
        end

        return false
    end

    ---@return boolean
    local function SpellChannel()
        if GetSpellAbilityId() == FourCC('IATK') then
            UnitRemoveAbility(GetTriggerUnit(), FourCC('IATK'))
        end

        return false
    end

    ---@return boolean
    local function SpellLearn()
        local source = GetTriggerUnit() ---@type unit 
        local sid    = GetLearnedSkill() ---@type integer 
        local pid    = GetPlayerId(GetOwningPlayer(source)) + 1 ---@type integer 
        local ablev  = GetUnitAbilityLevel(source, sid) ---@type integer 
        local i      = 0 ---@type integer 
        local abil   = BlzGetUnitAbilityByIndex(source, i) ---@type ability 

        -- find ability
        while abil and BlzGetAbilityId(abil) ~= sid do
            i = i + 1
            abil = BlzGetUnitAbilityByIndex(source, i)
        end

        -- remove bracket indicators
        UpdateSpellTooltips(pid)

        -- execute onlearn function
        if Spells[sid] then
            Spells[sid].onLearn(source, ablev, pid)
        end

        return false
    end

    local function SpellEffect()
        local caster = GetTriggerUnit() ---@type unit 
        local target = GetSpellTargetUnit() ---@type unit 
        local p      = GetOwningPlayer(caster)
        local itm    = GetSpellTargetItem() ---@type item?
        local sid    = GetSpellAbilityId() ---@type integer 
        local pid    = GetPlayerId(p) + 1 ---@type integer 
        local tpid   = GetPlayerId(GetOwningPlayer(target)) + 1 ---@type integer 
        local ablev  = GetUnitAbilityLevel(caster, sid) ---@type integer 
        local x      = GetUnitX(caster) ---@type number 
        local y      = GetUnitY(caster) ---@type number 
        local targetX = GetSpellTargetX() ---@type number 
        local targetY = GetSpellTargetY() ---@type number 
        local spell   = nil

        EVENT_ON_CAST:trigger(caster, sid, ablev)

        -- remember last cast spell id
        if sid ~= ADAPTIVESTRIKE.id and sid ~= LIMITBREAK.id then
            lastCast[pid] = sid
        end

        -- check existing spell definition
        if Spells[sid] then
            spell = Spells[sid]:create(caster, sid)
            spell.sid = sid
            spell.tpid = tpid
            spell.caster = caster
            spell.target = target
            spell.ablev = ablev
            spell.x = x
            spell.y = y
            spell.targetX = targetX
            spell.targetY = targetY
            spell.angle = Atan2(spell.targetY - y, spell.targetX - x)

            spell:onCast()

        elseif UNIT_SPELLS[sid] then
            UNIT_SPELLS[sid](caster, pid)

        -- backpack consumeable spells
        elseif POTIONS[sid] then
            local used = false

            for i = 1, MAX_INVENTORY_SLOTS do
                local pot = Profile[pid].hero.items[i]

                if pot then
                    local abil = ItemData[pot.id][ITEM_ABILITY * ABILITY_OFFSET]

                    if POTIONS[sid][abil] then
                        POTIONS[sid][abil](pid, pot)
                        used = true
                        break
                    end
                end
            end

            if not used then
                DisplayTextToPlayer(p, 0, 0, "You do not have a consumable of this type.")
            end
        end

        -- on cast aggro
        if spell then
            if Unit[caster].aggro_timer then
                Unit[caster].aggro_timer:reset()
                Unit[caster].aggro_timer:callDelayed(3., DropAggro, Unit[caster])
            end
        end

        return false
    end

    -- reused precast behavior
    DASH_PRECAST = function(pid, tpid, caster, target, x, y, targetX, targetY)
        local r = GetRectFromCoords(x, y)
        local r2 = GetRectFromCoords(targetX, targetY)

        if not IsTerrainWalkable(targetX, targetY) or r2 ~= r then
            IssueImmediateOrderById(caster, ORDER_ID_STOP)
            DisplayTextToPlayer(Player(pid - 1), 0, 0, INVALID_TARGET_MESSAGE)
        end
    end

    TERRAIN_PRECAST = function(pid, tpid, caster, target, x, y, targetX, targetY)
        if not IsTerrainWalkable(targetX, targetY) then
            IssueImmediateOrderById(caster, ORDER_ID_STOP)
            DisplayTextToPlayer(Player(pid - 1), 0, 0, INVALID_TARGET_MESSAGE)
        end
    end

    for k = 0, bj_MAX_PLAYER_SLOTS do
        local p = Player(k)

        if GetPlayerController(p) ~= MAP_CONTROL_NONE then
            -- pr setup
            SetPlayerAbilityAvailable(p, prMulti[0], false)
            SetPlayerAbilityAvailable(p, prMulti[1], false)
            SetPlayerAbilityAvailable(p, prMulti[2], false)
            SetPlayerAbilityAvailable(p, prMulti[3], false)
            SetPlayerAbilityAvailable(p, prMulti[4], false)
            SetPlayerAbilityAvailable(p, prMulti[5], false)
            SetPlayerAbilityAvailable(p, FourCC('A0AP'), false)
            -- bard setup
            SetPlayerAbilityAvailable(p, SONG_HARMONY, false)
            SetPlayerAbilityAvailable(p, SONG_PEACE, false)
            SetPlayerAbilityAvailable(p, SONG_WAR, false)
            SetPlayerAbilityAvailable(p, SONG_FATIGUE, false)
        end
    end

    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_CAST, SpellCast)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, SpellEffect)
    RegisterPlayerUnitEvent(EVENT_PLAYER_HERO_SKILL, SpellLearn)
    RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_CHANNEL, SpellChannel)
end, Debug and Debug.getLine())
