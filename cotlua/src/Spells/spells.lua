--[[
    spell.lua

    An all encompassing lib to handle spell related events:
        (EVENT_PLAYER_UNIT_SPELL_EFFECT,
        EVENT_PLAYER_UNIT_SPELL_CAST,
        EVENT_PLAYER_UNIT_SPELL_FINISH,
        EVENT_PLAYER_HERO_SKILL,
        EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    
    Provides a spell object factory for defining abilities by their ID
]]

OnInit.final("Spells", function(Require)
    Require("Users")

    --storage for spell definitions
    Spells = {}

    local INVALID_TARGET_MESSAGE = "|cffff0000Cannot target there!|r" ---@type string 

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
    ---@field get_tooltip function
    ---@field onCast function
    ---@field onLearn function
    Spell = {}
    do
        local thistype = Spell

        -- memoize metatables for inheritance
        local mts = {}

        ---@type fun(self: Spell, pid: integer, sid: integer?): Spell
        function thistype:create(pid, sid)
            local spell = {
                pid = pid,
                ablev = GetUnitAbilityLevel(Hero[pid], (sid or self.id))
            }

            mts[self] = mts[self] or { __index = self }

            setmetatable(spell, mts[self])

            -- precalculate function values
            if self.values then
                for k, v in pairs(self.values) do -- sync safe
                    if type(v) == "function" then
                        spell[k] = v(pid)
                    else
                        spell[k] = v
                    end
                end
            end

            return spell
        end

        local mt = { __index = function(tbl, key) local v = rawget(tbl, "values") return Spell[key] or (v and v[key]) end }

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

        --[[parses brackets
            >: no color
            ~: only shows calculated value
            [: normal boost
            {: low boost
            \: no boost
            =: tag identifier
        ]]
        ---@type fun(spell: Spell):string
        function thistype:get_tooltip()
            local orig = SpellTooltips[self.id][self.ablev]

            if self.values then
                local pattern = "(~?)(>?)([\\{\x25[])(\x25w-)=(.-)]"
                orig = orig:gsub(pattern, function(defaultflag, colorflag, prefix, tag, content)
                    local color = (colorflag ~= ">" and true) or false
                    local alt = altModifier[self.pid] or defaultflag == "~"

                    if alt then
                        local v = self[tag]
                        local calc = (type(v) == "table" and v[self.pid]) or v

                        if prefix == "[" then
                            local sb = Unit[Hero[self.pid]].spellboost
                            return HL(RealToString(calc * (1. + sb - 0.2)) .. " - " .. RealToString(calc * (1. + sb + 0.2)), color)
                        elseif prefix == "{" then
                            if calc < 10 then
                                return HL(string.format("\x25.2f", calc * LBOOST[self.pid]), color)
                            elseif calc < 1000 then
                                return HL(string.format("\x25.1f", calc * LBOOST[self.pid]), color)
                            else
                                return HL(RealToString(calc * LBOOST[self.pid]), color)
                            end
                        elseif prefix == "\\" then
                            return HL(RealToString(calc), color)
                        end
                    else
                        return content
                    end
                end)
            end

            return orig
        end

        -- Stub methods
        function thistype.onCast() end
        function thistype.onLearn(source, ablev, pid) end
        -- function thistype.onHit() end
        function thistype.onUnequip(itm) end
        function thistype.onEquip(itm, id, index) end
    end

    function SpellCast()
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
        local r       = GetRectFromCoords(x, y)
        local r2      = GetRectFromCoords(targetX, targetY)

        if Unit[caster] and targetX ~= 0 and targetY ~= 0 then
            Unit[caster].orderX = x
            Unit[caster].orderY = y
            if Unit[caster].movespeed > MOVESPEED.MAX then
                BlzSetUnitFacingEx(caster, bj_RADTODEG * Atan2(targetY - y, targetX - x))
            end
        end

        -- God Blink / Backpack Teleport
        if sid == FourCC('AImt') or sid == TELEPORT.id or sid == FourCC('A018') then
            if UnitAlive(Hero[pid]) == false then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while dead.")
            elseif sid == FourCC('A018') and CHAOS_MODE then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTimedTextToPlayer(p, 0, 0, 20.00, "With the Gods dead, these items no longer have the ability to move around the map with free will. Their powers are dead, however their innate fighting powers are left unscathed.")
            elseif r ~= MAIN_MAP.rect then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTimedTextToPlayer(p, 0, 0, 5., "Unable to teleport there.")
            elseif r ~= r2 then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTimedTextToPlayer(p, 0, 0, 5., "Unable to teleport there.")
            elseif TableHas(QUEUE_GROUP, p) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while queueing for a dungeon.")
            elseif TableHas(NAGA_GROUP, pid) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while in a dungeon.")
            end
        -- Short blink
        elseif sid == THANATOS_BOOTS.id or sid == FourCC('A03D') or sid == FourCC('A061') then
            if r ~= r2 then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport there.")
            end
        -- Teleport Home
        elseif sid == TELEPORT_HOME.id then
            if UnitAlive(Hero[pid]) == false then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while dead.")
            elseif TableHas(QUEUE_GROUP, p) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while queueing for a dungeon.")
            elseif TableHas(NAGA_GROUP, pid) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport while in a dungeon.")
            elseif TableHas(AZAZOTH_GROUP, p) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport out of here.")
            elseif r == MAIN_MAP.rect or r == gg_rct_Cave or r == gg_rct_Gods_Arena or r == gg_rct_Tavern then
            else
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Unable to teleport out of here.")
            end
        -- Resurrection
        elseif sid == RESURRECTION.id then
            if target ~= HeroGrave[tpid] then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "You must target a tombstone!")
            elseif GetUnitAbilityLevel(HeroGrave[tpid], FourCC('A045')) > 0 then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "This player is already being revived!")
            end
        elseif sid == BLOODNOVA.id then --Blood Nova
            if BLOODBANK.get(pid) < BLOODNOVA.cost(pid) then
                BlzUnitClearOrders(caster, false)
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "Not enough blood.")
            end
        -- valid cast point
        elseif sid == WHIRLPOOL.id or sid == BLOODLEAP.id or sid == SPINDASH.id or sid == METEOR.id or sid == STEEDCHARGE.id or sid == BLINKSTRIKE.id or sid == PHOENIXFLIGHT.id then
            if (not IsTerrainWalkable(targetX, targetY) or r2 ~= r) and (targetX ~= 0 and targetY ~= 0) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, INVALID_TARGET_MESSAGE)
            end
        elseif sid == ARCANESHIFT.id then
            local pt = TimerList[pid]:get(ARCANESHIFT.id, caster)

            if not IsTerrainWalkable(targetX, targetY) then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, INVALID_TARGET_MESSAGE)
            elseif pt then
                if DistanceCoords(targetX, targetY, pt.x, pt.y) > 1500. then
                    IssueImmediateOrderById(caster, ORDER_ID_STOP)
                    DisplayTextToPlayer(p, 0, 0, "|cffff0000Target point is too far away!")
                end
            end
        elseif sid == DEMONICSACRIFICE.id then
            if GetOwningPlayer(target) ~= p then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTextToPlayer(p, 0, 0, "You must target your own summons!")
            end
        elseif sid == METAMORPHOSIS.id then
            -- metamorphosis duration update
            local ablev = GetUnitAbilityLevel(Hero[pid], METAMORPHOSIS.id)
            BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], METAMORPHOSIS.id), ABILITY_RLF_DURATION_HERO, ablev - 1, METAMORPHOSIS.dur(pid) * LBOOST[pid])
        elseif sid == STEEDCHARGE.id then
            -- steed charge meta duration update
            local ablev = GetUnitAbilityLevel(Hero[pid], FourCC('A06K'))
            BlzSetAbilityRealLevelField(BlzGetUnitAbility(Hero[pid], FourCC('A06K')), ABILITY_RLF_DURATION_HERO, ablev - 1, 10. * LBOOST[pid])
        end
    end

    ---@return boolean
    function SpellChannel()
        if GetSpellAbilityId() == FourCC('IATK') then
            UnitRemoveAbility(GetTriggerUnit(), FourCC('IATK'))
        end

        return false
    end

    ---@return boolean
    function SpellLearn()
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

        -- store original tooltip
        SpellTooltips[sid][ablev] = BlzGetAbilityStringLevelField(abil, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, ablev - 1)

        -- remove bracket indicators
        UpdateSpellTooltips(pid)

        -- execute onlearn function
        if Spells[sid] then
            Spells[sid].onLearn(source, ablev, pid)
        end

        return false
    end

    function SpellFinish()
        local caster = GetTriggerUnit() ---@type unit 
        local sid    = GetSpellAbilityId() ---@type integer 
        local p      = GetOwningPlayer(caster) 
        local ablev  = GetUnitAbilityLevel(caster, sid) ---@type integer 
    end

    ---@type fun(pid: integer)
    local function instillfear_expire(pid)
        InstillFear[pid] = nil
    end

    local function instillfear_onhit(source, target)
        local pid = GetPlayerId(GetOwningPlayer(source)) + 1
        InstillFear[pid] = target
        TimerQueue:callDelayed(7., instillfear_expire, pid)
    end

    function SpellEffect()
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
        local dmg    = 0 ---@type number 
        local spell  = nil

        -- store last cast spell id
        if sid ~= ADAPTIVESTRIKE.id and sid ~= LIMITBREAK.id then
            lastCast[pid] = sid
        end

        -- use spell interface if it exists
        if Spells[sid] then
            spell = Spells[sid]:create(pid, sid)
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

        --========================
        -- Item Spells
        --========================

        elseif sid == FourCC('A083') then --Paladin Book
            local heal = 3 * GetHeroInt(caster, true) * BOOST[pid]
            if GetUnitTypeId(target) == BACKPACK then
                HP(caster, Hero[tpid], heal, GetObjectName(sid))
            else
                HP(caster, target, heal, GetObjectName(sid))
            end
        elseif sid == FourCC('A02A') then --Instill Fear
            if HasProficiency(pid, PROF_DAGGER) then
                local dummy = Dummy.create(x, y, FourCC('A0AE'), 1):cast(p, "firebolt", target)
                EVENT_DUMMY_ON_HIT:register_unit_action(dummy.unit, instillfear_onhit)
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        elseif sid == FourCC('A055') then --Darkest of Darkness
            DarkestOfDarknessBuff:add(Hero[pid], Hero[pid]):duration(20.)
        elseif sid == FourCC('A0IS') then --Abyssal Bow
            dmg = (UnitGetBonus(caster,BONUS_DAMAGE) + GetHeroAgi(caster, true)) * 4 * BOOST[pid]
            if not HasProficiency(pid, PROF_BOW) then
                dmg= dmg * 0.5
            end
            DamageTarget(caster, target, dmg, ATTACK_TYPE_NORMAL, MAGIC, thistype.tag)
        elseif sid == FourCC('A0SX') then --Azazoth Staff
            if HasProficiency(pid, PROF_STAFF) then
                local pt = TimerList[pid]:add()
                pt.source = caster
                pt.dmg = 40 * GetHeroInt(caster, true) * BOOST[pid]
                pt.angle = bj_RADTODEG * Atan2(targetY - y, targetX - x)
                pt.time = 4
                pt.tag = "Astral Devastation"

                pt.timer:callDelayed(0., AstralDevastation, pt)
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        elseif sid == FourCC('A0B5') then --Azazoth Hammer (Stomp)
            if HasProficiency(pid, PROF_HEAVY) then
                local ug = CreateGroup()
                MakeGroupInRange(pid, ug, x, y, 550.00, Condition(FilterEnemy))

                for target in each(ug) do
                    AzazothHammerStomp:add(caster, target):duration(15.)
                    DamageTarget(caster, target, 15.00 * GetHeroStr(caster, true) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, "Stomp")
                end

                DestroyGroup(ug)
            else
                DisplayTimedTextToPlayer(p, 0, 0, 15., "You do not have the proficiency to use this spell!")
            end
        elseif sid == FourCC('A00E') then --final blast
            local ug = CreateGroup()
            MakeGroupInRange(pid, ug, x, y, 600.00, Condition(FilterEnemy))

            for i = 1, 12 do
                if i < 7 then
                    x = GetUnitX(caster) + 200 * Cos(60.00 * i * bj_DEGTORAD)
                    y = GetUnitY(caster) + 200 * Sin(60.00 * i * bj_DEGTORAD)
                    DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
                end
                x = GetUnitX(caster) + 400 * Cos(60.00 * i * bj_DEGTORAD)
                y = GetUnitY(caster) + 400 * Sin(60.00 * i * bj_DEGTORAD)
                DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
                x = GetUnitX(caster) + 600 * Cos(60.00 * i * bj_DEGTORAD)
                y = GetUnitY(caster) + 600 * Sin(60.00 * i * bj_DEGTORAD)
                DestroyEffect(AddSpecialEffect("war3mapImported\\NeutralExplosion.mdx", x, y))
            end

            for target in each(ug) do
                DamageTarget(caster, target, 10.00 * (GetHeroInt(caster, true) + GetHeroAgi(caster, true) + GetHeroStr(caster, true)) * BOOST[pid], ATTACK_TYPE_NORMAL, MAGIC, "Final Blast")
            end

            DestroyGroup(ug)
        elseif UNIT_SPELLS[sid] then
            UNIT_SPELLS[sid](caster, pid, ablev, itm)

        -- Use Potion / Consumable (Backpack)
        elseif POTIONS[sid] then
            local used = false
            local pot

            for i = 0, MAX_INVENTORY_SLOTS - 1 do
                pot = Profile[pid].hero.items[i]

                if pot then
                    local abil = ItemData[pot.id][ITEM_ABILITY * ABILITY_OFFSET]

                    if POTIONS[sid][abil] then
                        POTIONS[sid][abil](pid, pot)
                        used = true
                        break
                    end
                end
            end

            if used == false then
                DisplayTextToPlayer(p, 0, 0, "You do not have a consumable of this type.")
            end

        --========================
        -- Misc
        --========================

        -- Castle of the Gods
        elseif sid == FourCC('A0A9') or sid == FourCC('A0A7') or sid == FourCC('A0A5') then
            if CHAOS_MODE then
                IssueImmediateOrderById(caster, ORDER_ID_STOP)
                DisplayTimedTextToPlayer(p, 0, 0, 10.00, "With the Gods dead, the Castle of Gods can no longer draw enough power from them in order to use its abilities.")
            end

        -- Grave Revive
        elseif sid == FourCC('A042') or sid == FourCC('A044') or sid == FourCC('A045') then
            if IsTerrainWalkable(targetX, targetY) then
                BlzSetSpecialEffectScale(HeroReviveIndicator[pid], 0)
                DestroyEffect(HeroReviveIndicator[pid])
                BlzSetSpecialEffectScale(HeroTimedLife[pid], 0)
                DestroyEffect(HeroTimedLife[pid])
                TimerList[pid]:stopAllTimers('dead')

                --item revival
                if sid == FourCC('A042') then
                    local itm2 = GetResurrectionItem(pid, false)
                    local heal = 0

                    if itm2 then
                        heal = ItemData[itm2.id][ITEM_ABILITY] * 0.01

                        --remove perishable resurrections
                        if ItemData[itm2.id][ITEM_ABILITY * ABILITY_OFFSET] == FourCC('Anrv') then
                            itm2:consumeCharge()
                        end
                    end

                    RevivePlayer(pid, targetX, targetY, heal, heal)
                --pr reincarnation
                elseif sid == FourCC('A044') then
                    RevivePlayer(pid, targetX, targetY, 100, 100)

                    BlzStartUnitAbilityCooldown(Hero[pid], REINCARNATION.id, 300.)
                --high priestess revival
                elseif sid == FourCC('A045') then
                    local heal = 40 + 20 * GetUnitAbilityLevel(Hero[ResurrectionRevival[pid]], RESURRECTION.id)
                    RevivePlayer(pid, targetX, targetY, heal, heal)
                end

                --refund HP cooldown and mana
                if sid ~= FourCC('A045') and ResurrectionRevival[pid] > 0 then
                    BlzEndUnitAbilityCooldown(Hero[ResurrectionRevival[pid]], RESURRECTION.id)
                    SetUnitState(Hero[ResurrectionRevival[pid]], UNIT_STATE_MANA, BlzGetUnitMaxMana(Hero[ResurrectionRevival[pid]]) * 0.5)
                end

                REINCARNATION.enabled[pid] = false
                ResurrectionRevival[pid] = 0
                UnitRemoveAbility(HeroGrave[pid], FourCC('A042'))
                UnitRemoveAbility(HeroGrave[pid], FourCC('A044'))
                UnitRemoveAbility(HeroGrave[pid], FourCC('A045'))
                SetUnitPosition(HeroGrave[pid], 30000, 30000)
                ShowUnit(HeroGrave[pid], false)
            else
                DisplayTextToPlayer(p, 0, 0, INVALID_TARGET_MESSAGE)
            end
        -- banish demon
        elseif sid == FourCC('A00Q') then
            itm = GetItemFromUnit(caster, FourCC('I0OU'))
            if CHAOS_MODE then
                if target == BossTable[BOSS_LEGION].unit then
                    Item[itm]:destroy()
                    if BANISH_FLAG == false then
                        BANISH_FLAG = true
                        DisplayTimedTextToForce(FORCE_PLAYING, 30., "|cffffcc00Legion:|r Fool! Did you really think splashing water on me would do anything?")
                    end
                else
                    DisplayTimedTextToPlayer(p, 0., 0., 30., "Maybe you shouldn't waste this...")
                end
            else
                if target == BossTable[BOSS_DEATH_KNIGHT].unit then
                    Item[itm]:destroy()
                    if BANISH_FLAG == false then
                        BANISH_FLAG = true
                        DisplayTimedTextToForce(FORCE_PLAYING, 30., "|cffffcc00Death Knight:|r ...???")
                    end
                else
                    DisplayTimedTextToPlayer(p, 0., 0., 30., "Maybe you shouldn't waste this...")
                end
            end
        end

        -- on cast aggro
        if spell then
            if targetX == 0. and targetY == 0. then
                Taunt(caster, pid, 800., false, 0, 200)
            else
                Taunt(caster, pid, math.min(800., DistanceCoords(x, y, targetX, targetY)), false, 0, 200)
            end
        end
    end

    local spell   = CreateTrigger()
    local cast    = CreateTrigger()
    local finish  = CreateTrigger()
    local learn   = CreateTrigger()
    local channel = CreateTrigger()
    local u       = User.first ---@type User 

    while u do
        TriggerRegisterPlayerUnitEvent(spell, u.player, EVENT_PLAYER_UNIT_SPELL_EFFECT, nil)
        TriggerRegisterPlayerUnitEvent(cast, u.player, EVENT_PLAYER_UNIT_SPELL_CAST, nil)
        TriggerRegisterPlayerUnitEvent(finish, u.player, EVENT_PLAYER_UNIT_SPELL_FINISH, nil)
        TriggerRegisterPlayerUnitEvent(learn, u.player, EVENT_PLAYER_HERO_SKILL, nil)
        TriggerRegisterPlayerUnitEvent(channel, u.player, EVENT_PLAYER_UNIT_SPELL_CHANNEL, nil)
        -- pr setup
        SetPlayerAbilityAvailable(u.player, prMulti[0], false)
        SetPlayerAbilityAvailable(u.player, prMulti[1], false)
        SetPlayerAbilityAvailable(u.player, prMulti[2], false)
        SetPlayerAbilityAvailable(u.player, prMulti[3], false)
        SetPlayerAbilityAvailable(u.player, prMulti[4], false)
        SetPlayerAbilityAvailable(u.player, FourCC('A0AP'), false)
        -- bard setup
        SetPlayerAbilityAvailable(u.player, SONG_HARMONY, false)
        SetPlayerAbilityAvailable(u.player, SONG_PEACE, false)
        SetPlayerAbilityAvailable(u.player, SONG_WAR, false)
        SetPlayerAbilityAvailable(u.player, SONG_FATIGUE, false)

        u = u.next
    end

    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_HARMONY, false)
    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_WAR, false)
    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_PEACE, false)
    SetPlayerAbilityAvailable(Player(PLAYER_NEUTRAL_PASSIVE), SONG_FATIGUE, false)

    TriggerAddAction(spell, SpellEffect)
    TriggerAddAction(cast, SpellCast)
    TriggerAddAction(finish, SpellFinish)
    TriggerAddCondition(learn, Filter(SpellLearn))
    TriggerAddCondition(channel, Filter(SpellChannel))
end, Debug and Debug.getLine())
