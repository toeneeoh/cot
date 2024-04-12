OnInit.final("HeroSelect", function(Require)
    Require('Users')
    Require('Variables')

---@param pid integer
function StartGame(pid)
    local p = Player(pid - 1) ---@type player 

    PauseUnit(Hero[pid], false)

    if (GetLocalPlayer() == p) then
        ClearSelection()
        SelectUnit(Hero[pid], true)
        ResetToGameCamera(0)
    end

    SetCamera(pid, MAIN_MAP.rect)

    ExperienceControl(pid)
    CharacterSetup(pid, false)
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
    --TODO remove Hardcore global?
    Hardcore[pid] = true
    Profile[pid].hero.hardcore = 1
    PlayerAddItemById(pid, FourCC('I03N'))

    StartGame(pid)

    if GetLocalPlayer() == GetTriggerPlayer() then
        BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        BlzFrameSetVisible(hardcoreBG, false)
    end
end

function HardcoreNo()
    local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    StartGame(pid)

    if GetLocalPlayer() == GetTriggerPlayer() then
        BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        BlzFrameSetVisible(hardcoreBG, false)
    end
end

---@param pid integer
function LockCycle(pid)
    if hslook[pid] > HERO_TOTAL - 1 then
        hslook[pid] = 0
    elseif hslook[pid] < 0 then
        hslook[pid] = HERO_TOTAL - 1
    end
end

---@param currentPlayer player
---@param direction integer
function Scroll(currentPlayer, direction)
    local pid = GetPlayerId(currentPlayer) + 1 ---@type integer 

    UnitRemoveAbility(hsdummy[pid], HeroCircle[hslook[pid]].select)
    UnitRemoveAbility(hsdummy[pid], HeroCircle[hslook[pid]].passive)

    hslook[pid] = hslook[pid] + direction

    LockCycle(pid)

    if hssort[pid] then
        while not (MainStat(HeroCircle[hslook[pid]].unit) == hsstat[pid]) do
            hslook[pid] = hslook[pid] + direction
            LockCycle(pid)
        end
    end

    MainStatForm(pid, MainStat(HeroCircle[hslook[pid]].unit))

    BlzSetUnitSkin(hsdummy[pid], HeroCircle[hslook[pid]].skin)
    BlzSetUnitName(hsdummy[pid], GetUnitName(HeroCircle[hslook[pid]].unit))
    BlzSetHeroProperName(hsdummy[pid], GetHeroProperName(HeroCircle[hslook[pid]].unit))
    --call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_PRIMARY_ATTRIBUTE, BlzGetUnitIntegerField(HeroCircle[hslook[pid]].unit, UNIT_IF_PRIMARY_ATTRIBUTE))
    BlzSetUnitWeaponIntegerField(hsdummy[pid], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0, BlzGetUnitWeaponIntegerField(HeroCircle[hslook[pid]].unit, UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0))
    BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_DEFENSE_TYPE, BlzGetUnitIntegerField(HeroCircle[hslook[pid]].unit, UNIT_IF_DEFENSE_TYPE))
    BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0, BlzGetUnitWeaponRealField(HeroCircle[hslook[pid]].unit, UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0))
    BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_RANGE, 1, BlzGetUnitWeaponRealField(HeroCircle[hslook[pid]].unit, UNIT_WEAPON_RF_ATTACK_RANGE, 0) - 100)
    BlzSetUnitArmor(hsdummy[pid], BlzGetUnitArmor(HeroCircle[hslook[pid]].unit))

    SetHeroStr(hsdummy[pid], GetHeroStr(HeroCircle[hslook[pid]].unit, true), true)
    SetHeroAgi(hsdummy[pid], GetHeroAgi(HeroCircle[hslook[pid]].unit, true), true)
    SetHeroInt(hsdummy[pid], GetHeroInt(HeroCircle[hslook[pid]].unit, true), true)

    BlzSetUnitBaseDamage(hsdummy[pid], BlzGetUnitBaseDamage(HeroCircle[hslook[pid]].unit, 0), 0)
    BlzSetUnitDiceNumber(hsdummy[pid], BlzGetUnitDiceNumber(HeroCircle[hslook[pid]].unit, 0), 0)
    BlzSetUnitDiceSides(hsdummy[pid], BlzGetUnitDiceSides(HeroCircle[hslook[pid]].unit, 0), 0)

    BlzSetUnitMaxHP(hsdummy[pid], BlzGetUnitMaxHP(HeroCircle[hslook[pid]].unit))
    BlzSetUnitMaxMana(hsdummy[pid], BlzGetUnitMaxMana(HeroCircle[hslook[pid]].unit))
    SetWidgetLife(hsdummy[pid], BlzGetUnitMaxHP(hsdummy[pid]))

    UnitAddAbility(hsdummy[pid], HeroCircle[hslook[pid]].select)
    UnitAddAbility(hsdummy[pid], HeroCircle[hslook[pid]].passive)
    UnitAddAbility(hsdummy[pid], FourCC('A0JI'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JQ'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JR'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JS'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JT'))
    UnitAddAbility(hsdummy[pid], FourCC('A0JU'))
    UnitAddAbility(hsdummy[pid], FourCC('Aeth'))
    SetUnitPathing(hsdummy[pid], false)
    UnitRemoveAbility(hsdummy[pid], FourCC('Amov'))
    BlzUnitHideAbility(hsdummy[pid], FourCC('Aatk'), true)

    if (GetLocalPlayer() == currentPlayer) then
        SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 500, 0)
        SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 340, 0)
        SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, 60, 0)
        SetCameraField(CAMERA_FIELD_ZOFFSET, 200, 0)
        SetCameraField(CAMERA_FIELD_ROTATION, GetUnitFacing(HeroCircle[hslook[pid]].unit) + 180, 0)
        SetCameraTargetController(gg_unit_h00T_0511, 0, 0, false)
        ClearSelection()
        SelectUnit(hsdummy[pid], true)
    end
end

---@param pid integer
---@param id integer
function Selection(pid, id)
    local p = Player(pid - 1) ---@type player 

    UnitRemoveAbility(hsdummy[pid], HeroCircle[hslook[pid]].select)
    UnitRemoveAbility(hsdummy[pid], HeroCircle[hslook[pid]].passive)
    RemoveUnit(hsdummy[pid])

    Hero[pid] = CreateUnit(p, id, -690., -238., 0.)
    HeroID[pid] = id
    PlayerSelectedUnit[pid] = Hero[pid]
    selectingHero[pid] = false

    PauseUnit(Hero[pid], true)

    if (GetLocalPlayer() == p) then
        ClearTextMessages()
        BlzFrameSetVisible(hardcoreBG, true)
    end
end

---@return boolean
local function IsSelecting()
    local p = GetTriggerPlayer()

    if selectingHero[GetPlayerId(p) + 1] then
        if BlzGetTriggerPlayerKey() == OSKEY_LEFT then
            Scroll(p, -1)
        else
            Scroll(p, 1)
        end
    end

    return false
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

    TriggerAddCondition(arrow, Condition(IsSelecting))
end, Debug.getLine())
