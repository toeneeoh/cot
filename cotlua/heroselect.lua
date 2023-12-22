if Debug then Debug.beginFile 'HeroSelect' end

OnInit.final("HeroSelect", function(require)
    require 'Users'
    require 'Variables'

---@param pid integer
function StartGame(pid)
    local p        = Player(pid - 1) ---@type player 

    PauseUnit(Hero[pid], false)

    if (GetLocalPlayer() == p) then
        --call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        ClearSelection()
        SelectUnit(Hero[pid], true)
        ResetToGameCamera(0)
    end

    SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
    PanCameraToTimedForPlayer(p, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)

    --call MultiboardMinimizeBJ(false, MULTI_BOARD)
    ExperienceControl(pid)
    CharacterSetup(pid, false)
end

---@return boolean
function HardcoreMenu()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

    if hardcoreClicked[pid] == false then
        hardcoreClicked[pid] = true
        return true
    end

    return false
end

function HardcoreYes()
    local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
    Hardcore[pid] = true
    PlayerAddItemById(pid, FourCC('I03N'))

    StartGame(pid)

    if GetLocalPlayer() == GetTriggerPlayer() then
        BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        BlzFrameSetEnable(BlzGetTriggerFrame(), true)
        BlzFrameSetVisible(hardcoreBG, false)
    end
end

function HardcoreNo()
    local pid         = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 
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
    local pid         = GetPlayerId(currentPlayer) + 1 ---@type integer 

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
        SetCameraTargetController(HeroCircle[hslook[pid]].unit, 0, 0, false)
        ClearSelection()
        SelectUnit(hsdummy[pid], true)
    end
end

---@param pid integer
---@param id integer
function Selection(pid, id)
    local p        = Player(pid - 1) ---@type player 

    UnitRemoveAbility(hsdummy[pid], HeroCircle[hslook[pid]].select)
    UnitRemoveAbility(hsdummy[pid], HeroCircle[hslook[pid]].passive)
    RemoveUnit(hsdummy[pid])

    Hero[pid] = CreateUnit(p, id, -690., -238., 0.)
    HeroID[pid] = id
    urhome[pid] = 0
    TimePlayed[pid] = 0
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
    return selectingHero[GetPlayerId(GetTriggerPlayer()) + 1]
end

local function ScrollLeft()
    Scroll(GetTriggerPlayer(), -1)
end

local function ScrollRight()
    Scroll(GetTriggerPlayer(), 1)
end

    local leftarrow         = CreateTrigger() ---@type trigger 
    local rightarrow         = CreateTrigger() ---@type trigger 
    local u      = User.first ---@type User 

    while u do
        TriggerRegisterPlayerEvent(leftarrow, u.player, EVENT_PLAYER_ARROW_LEFT_DOWN)
        TriggerRegisterPlayerEvent(rightarrow, u.player, EVENT_PLAYER_ARROW_RIGHT_DOWN)
        u = u.next
    end

    TriggerAddCondition(leftarrow, Condition(IsSelecting))
    TriggerAddCondition(rightarrow, Condition(IsSelecting))
    TriggerAddAction(leftarrow, ScrollLeft)
    TriggerAddAction(rightarrow, ScrollRight)

end)

if Debug then Debug.endFile() end
