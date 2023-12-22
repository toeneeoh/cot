library heroselection requires Functions, PlayerManager

globals
    boolean array hselection
    unit array hstarget
    unit array hsdummy
    integer array hspassiveid
    integer array hsselectid
    integer array hsskinid
    integer array hslook
    integer array hsstat
    boolean array hssort
endglobals

function StartGame takes integer pid returns nothing
    local player p = Player(pid - 1)

    call PauseUnit(Hero[pid], false)

    if (GetLocalPlayer() == p) then
        //call SetDayNightModels("Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx","Environment\\DNC\\DNCAshenvale\\DNCAshenValeTerrain\\DNCAshenValeTerrain.mdx")
        call ClearSelection()
        call SelectUnit(Hero[pid], true)
        call ResetToGameCamera(0)
    endif

    call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
    call PanCameraToTimedForPlayer(p, GetUnitX(Hero[pid]), GetUnitY(Hero[pid]), 0)

    //call MultiboardMinimizeBJ(false, MULTI_BOARD)
    call ExperienceControl(pid)
    call CharacterSetup(pid, false)
endfunction

function HardcoreMenu takes nothing returns boolean
	local integer pid = GetPlayerId(GetTriggerPlayer()) + 1

    if hardcoreClicked[pid] == false then
        set hardcoreClicked[pid] = true
        return true
    endif

    return false
endfunction

function HardcoreYes takes nothing returns nothing
	local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
	set udg_Hardcore[pid]=true
	call Item.assign(UnitAddItemById(Hero[pid], 'I03N'))

	call StartGame(pid)

    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
		call BlzFrameSetVisible(hardcoreBG, false)
    endif
endfunction

function HardcoreNo takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer()) + 1
	call StartGame(pid)

    if GetLocalPlayer() == GetTriggerPlayer() then
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
		call BlzFrameSetVisible(hardcoreBG, false)
    endif
endfunction

function LockCycle takes integer pid returns nothing
    if hslook[pid] > HERO_TOTAL - 1 then
        set hslook[pid] = 0
    elseif hslook[pid] < 0 then
        set hslook[pid] = HERO_TOTAL - 1
    endif
endfunction

function Scroll takes player currentPlayer, integer direction returns nothing
    local integer pid = GetPlayerId(currentPlayer) + 1
    
    call UnitRemoveAbility(hsdummy[pid], hsselectid[hslook[pid]])
    call UnitRemoveAbility(hsdummy[pid], hspassiveid[hslook[pid]])

    set hslook[pid] = hslook[pid] + direction

    call LockCycle(pid)
    
    if hssort[pid] then
        loop
            exitwhen MainStat(hstarget[hslook[pid]]) == hsstat[pid]
            set hslook[pid] = hslook[pid] + direction
            call LockCycle(pid)
        endloop
    endif

    call MainStatForm(pid, MainStat(hstarget[hslook[pid]]))

    call BlzSetUnitSkin(hsdummy[pid], hsskinid[hslook[pid]])
    call BlzSetUnitName(hsdummy[pid], GetUnitName(hstarget[hslook[pid]]))
    call BlzSetHeroProperName(hsdummy[pid], GetHeroProperName(hstarget[hslook[pid]]))
    //call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_PRIMARY_ATTRIBUTE, BlzGetUnitIntegerField(hstarget[hslook[pid]], UNIT_IF_PRIMARY_ATTRIBUTE))
    call BlzSetUnitWeaponIntegerField(hsdummy[pid], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0, BlzGetUnitWeaponIntegerField(hstarget[hslook[pid]], UNIT_WEAPON_IF_ATTACK_ATTACK_TYPE, 0))
    call BlzSetUnitIntegerField(hsdummy[pid], UNIT_IF_DEFENSE_TYPE, BlzGetUnitIntegerField(hstarget[hslook[pid]], UNIT_IF_DEFENSE_TYPE))
    call BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0, BlzGetUnitWeaponRealField(hstarget[hslook[pid]], UNIT_WEAPON_RF_ATTACK_BASE_COOLDOWN, 0))
    call BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_RANGE, 1, BlzGetUnitWeaponRealField(hstarget[hslook[pid]], UNIT_WEAPON_RF_ATTACK_RANGE, 0) - 100)
    call BlzSetUnitArmor(hsdummy[pid], BlzGetUnitArmor(hstarget[hslook[pid]]))

    call SetHeroStr(hsdummy[pid], GetHeroStr(hstarget[hslook[pid]], true), true)
    call SetHeroAgi(hsdummy[pid], GetHeroAgi(hstarget[hslook[pid]], true), true)
    call SetHeroInt(hsdummy[pid], GetHeroInt(hstarget[hslook[pid]], true), true)

    call BlzSetUnitBaseDamage(hsdummy[pid], BlzGetUnitBaseDamage(hstarget[hslook[pid]], 0), 0)
    call BlzSetUnitDiceNumber(hsdummy[pid], BlzGetUnitDiceNumber(hstarget[hslook[pid]], 0), 0)
    call BlzSetUnitDiceSides(hsdummy[pid], BlzGetUnitDiceSides(hstarget[hslook[pid]], 0), 0)

    call BlzSetUnitMaxHP(hsdummy[pid], BlzGetUnitMaxHP(hstarget[hslook[pid]]))
    call BlzSetUnitMaxMana(hsdummy[pid], BlzGetUnitMaxMana(hstarget[hslook[pid]]))
    call SetWidgetLife(hsdummy[pid], BlzGetUnitMaxHP(hsdummy[pid]))

    call UnitAddAbility(hsdummy[pid], hsselectid[hslook[pid]])
    call UnitAddAbility(hsdummy[pid], hspassiveid[hslook[pid]])
    call UnitAddAbility(hsdummy[pid], 'A0JI')
    call UnitAddAbility(hsdummy[pid], 'A0JQ')
    call UnitAddAbility(hsdummy[pid], 'A0JR')
    call UnitAddAbility(hsdummy[pid], 'A0JS')
    call UnitAddAbility(hsdummy[pid], 'A0JT')
    call UnitAddAbility(hsdummy[pid], 'A0JU')
    call UnitAddAbility(hsdummy[pid], 'Aeth')
    call SetUnitPathing(hsdummy[pid], false)
    call UnitRemoveAbility(hsdummy[pid], 'Amov')
    call BlzUnitHideAbility(hsdummy[pid], 'Aatk', true)

    if (GetLocalPlayer() == currentPlayer) then
        call SetCameraTargetController(hstarget[hslook[pid]], 0, 0, false)
        call ClearSelection()
        call SelectUnit(hsdummy[pid], true)
    endif
endfunction

function Selection takes integer pid, integer id returns nothing
    local player p = Player(pid - 1)

    call UnitRemoveAbility(hsdummy[pid], hsselectid[hslook[pid]])
    call UnitRemoveAbility(hsdummy[pid], hspassiveid[hslook[pid]])
    call RemoveUnit(hsdummy[pid])
    
    set Hero[pid] = CreateUnit(p, id, -690., -238., 0.)
    set HeroID[pid] = id
    set urhome[pid] = 0
    set udg_TimePlayed[pid] = 0
    set PlayerSelectedUnit[pid] = Hero[pid]
    set hselection[pid] = false

    call PauseUnit(Hero[pid], true)
    
    if (GetLocalPlayer() == p) then
        call ClearTextMessages()
        call BlzFrameSetVisible(hardcoreBG, true)
    endif
endfunction

private function IsSelecting takes nothing returns boolean
    return hselection[GetPlayerId(GetTriggerPlayer()) + 1]
endfunction

private function ScrollLeft takes nothing returns nothing
    call Scroll(GetTriggerPlayer(), -1)
endfunction

private function ScrollRight takes nothing returns nothing
    call Scroll(GetTriggerPlayer(), 1)
endfunction

function HeroSelectInit takes nothing returns nothing
    local trigger leftarrow = CreateTrigger()
    local trigger rightarrow = CreateTrigger()
    local User u = User.first
    local integer i = 0
    
    loop
        exitwhen i > HERO_TOTAL - 1
        call UnitAddAbility(hstarget[i], 'Aloc')
        set i = i + 1
    endloop
    
    loop
        exitwhen u == User.NULL
        call TriggerRegisterPlayerEvent(leftarrow, u.toPlayer(), EVENT_PLAYER_ARROW_LEFT_DOWN)
        call TriggerRegisterPlayerEvent(rightarrow, u.toPlayer(), EVENT_PLAYER_ARROW_RIGHT_DOWN)
        set u = u.next
    endloop
    
    call TriggerAddCondition(leftarrow, Condition(function IsSelecting))
    call TriggerAddCondition(rightarrow, Condition(function IsSelecting))
    call TriggerAddAction(leftarrow, function ScrollLeft)
    call TriggerAddAction(rightarrow, function ScrollRight)
    
    set leftarrow = null
    set rightarrow = null
endfunction

endlibrary
