OnInit.final("HeroSelect", function(Require)
    Require('Users')
    Require('Variables')
    Require('Spells')
    Require('Frames')

    local SELECT_DUMMY   = {} ---@type unit[] 
    local SELECT_VIEWING = __jarray(0) ---@type integer[] 
    local SELECT_STAT    = __jarray(0) ---@type integer[] 
    local SELECT_SORT    = {} ---@type boolean[] 

    local unitMapping = {
        [1] = FourCC('E001'),
        [2] = FourCC('E004'),
        [3] = FourCC('E01A')
    }

    --- Create or replace the dummy unit based on the main stat index
    --- @param pid integer
    --- @param i integer
    local function MainStatForm(pid, i)
        RemoveUnit(SELECT_DUMMY[pid])
        if unitMapping[i] then
            SELECT_DUMMY[pid] = CreateUnit(Player(pid - 1), unitMapping[i], 30000, 30000, 0)
        end
    end

    ---@param pid integer
    function StartGame(pid)
        local p = Player(pid - 1)

        PauseUnit(Hero[pid], false)

        if (GetLocalPlayer() == p) then
            ClearSelection()
            SelectUnit(Hero[pid], true)
            ResetToGameCamera(0)
        end

        ExperienceControl(pid)
        CharacterSetup(pid, false)
    end

    ---@param pid integer
    local function LockCycle(pid)
        if SELECT_VIEWING[pid] > HERO_TOTAL - 1 then
            SELECT_VIEWING[pid] = 0
        elseif SELECT_VIEWING[pid] < 0 then
            SELECT_VIEWING[pid] = HERO_TOTAL - 1
        end
    end

    ---@param pid integer
    ---@param direction integer
    local function Scroll(pid, direction)
        UnitRemoveAbility(SELECT_DUMMY[pid], HeroCircle[SELECT_VIEWING[pid]].select)
        UnitRemoveAbility(SELECT_DUMMY[pid], HeroCircle[SELECT_VIEWING[pid]].passive)

        repeat
            SELECT_VIEWING[pid] = SELECT_VIEWING[pid] + direction
            LockCycle(pid)
        until not (SELECT_SORT[pid] and (MainStat(HeroCircle[SELECT_VIEWING[pid]].unit) ~= SELECT_STAT[pid]))

        local current_hero = HeroCircle[SELECT_VIEWING[pid]]

        MainStatForm(pid, MainStat(current_hero.unit))

        local selected_unit = SELECT_DUMMY[pid]

        BlzSetUnitSkin(selected_unit, current_hero.skin)
        BlzSetUnitName(selected_unit, GetUnitName(current_hero.unit))
        BlzSetHeroProperName(selected_unit, GetHeroProperName(current_hero.unit))
        BlzSetUnitWeaponIntegerField(selected_unit, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0, BlzGetUnitWeaponIntegerField(current_hero.unit, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0))
        BlzSetUnitIntegerField(selected_unit, UNIT_IF_DEFENSE_TYPE, BlzGetUnitIntegerField(current_hero.unit, UNIT_IF_DEFENSE_TYPE))
        BlzSetUnitWeaponRealField(selected_unit, UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0, BlzGetUnitWeaponRealField(current_hero.unit, UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0))
        BlzSetUnitWeaponRealField(selected_unit, UNIT_WEAPON_RF_ATTACK_RANGE, 1, BlzGetUnitWeaponRealField(current_hero.unit, UNIT_WEAPON_RF_ATTACK_RANGE, 0) - 100)
        BlzSetUnitArmor(selected_unit, BlzGetUnitArmor(current_hero.unit))

        Unit[selected_unit].str = Unit[current_hero.unit].str
        Unit[selected_unit].agi = Unit[current_hero.unit].agi
        Unit[selected_unit].int = Unit[current_hero.unit].int

        BlzSetUnitBaseDamage(selected_unit, BlzGetUnitBaseDamage(current_hero.unit, 0), 0)
        BlzSetUnitDiceNumber(selected_unit, BlzGetUnitDiceNumber(current_hero.unit, 0), 0)
        BlzSetUnitDiceSides(selected_unit, BlzGetUnitDiceSides(current_hero.unit, 0), 0)

        -- BlzSetUnitMaxHP(selected_unit, BlzGetUnitMaxHP(current_hero.unit))
        -- BlzSetUnitMaxMana(selected_unit, BlzGetUnitMaxMana(current_hero.unit))
        SetWidgetLife(selected_unit, BlzGetUnitMaxHP(selected_unit))

        UnitAddAbility(selected_unit, current_hero.select)
        UnitAddAbility(selected_unit, current_hero.passive)

        UnitAddAbility(selected_unit, FourCC('A0JI'))
        UnitAddAbility(selected_unit, FourCC('A0JQ'))
        UnitAddAbility(selected_unit, FourCC('A0JR'))
        UnitAddAbility(selected_unit, FourCC('A0JS'))
        UnitAddAbility(selected_unit, FourCC('A0JT'))
        UnitAddAbility(selected_unit, FourCC('A0JU'))
        UnitAddAbility(selected_unit, FourCC('Aeth'))
        SetUnitPathing(selected_unit, false)
        UnitRemoveAbility(selected_unit, FourCC('Amov'))
        BlzUnitHideAbility(selected_unit, FourCC('Aatk'), true)

        if (GetLocalPlayer() == Player(pid - 1)) then
            SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 500, 0)
            SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 340, 0)
            SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, 60, 0)
            SetCameraField(CAMERA_FIELD_ZOFFSET, 200, 0)
            SetCameraField(CAMERA_FIELD_ROTATION, GetUnitFacing(current_hero.unit) + 180, 0)
            SetCameraTargetController(gg_unit_h00T_0511, 0, 0, false)
            ClearSelection()
            SelectUnit(selected_unit, true)
        end
    end

    ---@param pid integer
    function StartHeroSelect(pid)
        SELECT_VIEWING[pid] = HERO_TOTAL - 1
        Scroll(pid, 1)
    end

    ---@return boolean
    function HardcoreMenu()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        if not hardcoreClicked[pid] then
            hardcoreClicked[pid] = true
            return true
        end

        return false
    end

    function HardcoreYes()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

        Profile[pid].hero.hardcore = 1

        StartGame(pid)

        if GetLocalPlayer() == GetTriggerPlayer() then
            BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            BlzFrameSetVisible(HARDCORE_BACKDROP, false)
        end
    end

    function HardcoreNo()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
        StartGame(pid)

        if GetLocalPlayer() == GetTriggerPlayer() then
            BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            BlzFrameSetVisible(HARDCORE_BACKDROP, false)
        end
    end

    ---@param pid integer
    ---@param id integer
    function Selection(pid, id)
        local p = Player(pid - 1)

        RemoveUnit(SELECT_DUMMY[pid])

        Profile[pid]:new_character(id)
        SELECTING_HERO[pid] = false

        if (GetLocalPlayer() == p) then
            ClearTextMessages()
            BlzFrameSetVisible(HARDCORE_BACKDROP, true)
        end
    end

    ---@return boolean
    local function IsSelecting()
        local pid = GetPlayerId(GetTriggerPlayer()) + 1

        if SELECTING_HERO[pid] then
            if BlzGetTriggerPlayerKey() == OSKEY_LEFT then
                Scroll(pid, -1)
            else
                Scroll(pid, 1)
            end
        end

        return false
    end

    local CYCLE_LEFT = Spell.define('A0JI')
    do
        local thistype = CYCLE_LEFT

        function thistype:onCast()
            Scroll(self.pid, -1)
        end
    end

    local CYCLE_RIGHT = Spell.define('A0JQ')
    do
        local thistype = CYCLE_RIGHT

        function thistype:onCast()
            Scroll(self.pid, 1)
        end
    end

    local SORT_AGI = Spell.define('A0JR')
    do
        local thistype = SORT_AGI

        function thistype:onCast()
            SELECT_SORT[self.pid] = true
            SELECT_STAT[self.pid] = 3
            Scroll(self.pid, 1)
        end
    end

    local SORT_STR = Spell.define('A0JS')
    do
        local thistype = SORT_STR

        function thistype:onCast()
            SELECT_SORT[self.pid] = true
            SELECT_STAT[self.pid] = 1
            Scroll(self.pid, 1)
        end
    end

    local SORT_INT = Spell.define('A0JT')
    do
        local thistype = SORT_INT

        function thistype:onCast()
            SELECT_SORT[self.pid] = true
            SELECT_STAT[self.pid] = 2
            Scroll(self.pid, 1)
        end
    end

    local STOP_SORT = Spell.define('A0JU')
    do
        local thistype = STOP_SORT

        function thistype:onCast()
            SELECT_SORT[self.pid] = false
        end
    end

    local SELECT_HERO = Spell.define('A07S', 'A07T', 'A07U', 'A07V', 'A029', 'A07W', 'A07Z', 'A080', 'A081', 'A082', 'A084', 'A086', 'A087', 'A089', 'A07J', 'A01P', 'A07L', 'A07M', 'A07N')
    do
        local thistype = SELECT_HERO

        function thistype:onCast()
            Selection(self.pid, HeroCircle[SELECT_VIEWING[self.pid]].skin)
        end
    end

    local arrow = CreateTrigger()
    local u = User.first ---@type User 

    --[[meta keys:
    none: 0
    shift: 1
    ctrl: 2
    alt: 4
    windows key: 8]]
    while u do
        BlzTriggerRegisterPlayerKeyEvent(arrow, u.player, OSKEY_LEFT, 0, true)
        BlzTriggerRegisterPlayerKeyEvent(arrow, u.player, OSKEY_RIGHT, 0, true)
        u = u.next
    end

    local hardcoreSelectYes = CreateTrigger()
    local hardcoreSelectNo = CreateTrigger()

    TriggerAddCondition(hardcoreSelectYes, Condition(HardcoreMenu))
    TriggerAddAction(hardcoreSelectYes, HardcoreYes)
    BlzTriggerRegisterFrameEvent(hardcoreSelectYes, HARDCORE_BUTTON_FRAME, FRAMEEVENT_CONTROL_CLICK)

    TriggerAddCondition(hardcoreSelectNo, Condition(HardcoreMenu))
    TriggerAddAction(hardcoreSelectNo, HardcoreNo)
    BlzTriggerRegisterFrameEvent(hardcoreSelectNo, HARDCORE_BUTTON_FRAME2, FRAMEEVENT_CONTROL_CLICK)

    TriggerAddCondition(arrow, Condition(IsSelecting))
end, Debug and Debug.getLine())
