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
    call EnterWeather(Hero[pid])
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
	call UnitAddItemById(Hero[pid], 'I03N')

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
    call BlzSetUnitWeaponRealField(hsdummy[pid], UNIT_WEAPON_RF_ATTACK_RANGE, 0, BlzGetUnitWeaponRealField(hstarget[hslook[pid]], UNIT_WEAPON_RF_ATTACK_RANGE, 0))
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
    call ShowUnit(hsdummy[pid], false)
    
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

    set hstarget[i] = gg_unit_H02A_0568 //oblivion guard
    set hsskinid[i] = 'H02A'
    set hsselectid[i] = 'A07S'
    set hspassiveid[i] = 'A0HQ'
    set i = i + 1
    set hstarget[i] = gg_unit_H03N_0612 //bloodzerker
    set hsskinid[i] = 'H03N'
    set hsselectid[i] = 'A07T'
    set hspassiveid[i] = 'A06N'
    set i = i + 1
    set hstarget[i] = gg_unit_H04Z_0604 //royal guardian
    set hsskinid[i] = 'H04Z'
    set hsselectid[i] = 'A07U'
    set hspassiveid[i] = 'A0I5'
    set i = i + 1
    set hstarget[i] = gg_unit_H012_0605 //warrior
    set hsskinid[i] = 'H012'
    set hsselectid[i] = 'A07V'
    set hspassiveid[i] = 'A0IE'
    set i = i + 1
    set hstarget[i] = gg_unit_U003_0081 //vampire
    set hsskinid[i] = 'U003'
    set hsselectid[i] = 'A029'
    set hspassiveid[i] = 'A05E'
    set i = i + 1
    set hstarget[i] = gg_unit_H01N_0606 //savior
    set hsskinid[i] = 'H01N'
    set hsselectid[i] = 'A07W'
    set hspassiveid[i] = 'A0HW'
    set i = i + 1
    set hstarget[i] = gg_unit_H01S_0607 //dark savior
    set hsskinid[i] = 'H01S'
    set hsselectid[i] = 'A07Z'
    set hspassiveid[i] = 'A0DL'
    set i = i + 1
    set hstarget[i] = gg_unit_H05B_0608 //arcane warrior
    set hsskinid[i] = 'H05B'
    set hsselectid[i] = 'A080'
    set hspassiveid[i] = 'A0I4'
    set i = i + 1
    set hstarget[i] = gg_unit_H029_0617 //arcanist
    set hsskinid[i] = 'H029'
    set hsselectid[i] = 'A081'
    set hspassiveid[i] = 'A0EY'
    set i = i + 1
    set hstarget[i] = gg_unit_O02S_0615 //dark summoner
    set hsskinid[i] = 'O02S'
    set hsselectid[i] = 'A082'
    set hspassiveid[i] = 'A0I0'
    set i = i + 1
    set hstarget[i] = gg_unit_H00R_0610 //bard
    set hsskinid[i] = 'H00R'
    set hsselectid[i] = 'A084'
    set hspassiveid[i] = 'A0HV'
    set i = i + 1
    set hstarget[i] = gg_unit_E00G_0616 //hydromancer
    set hsskinid[i] = 'E00G'
    set hsselectid[i] = 'A086'
    set hspassiveid[i] = 'A0EC'
    set i = i + 1
    set hstarget[i] = gg_unit_E012_0613 //high priestess
    set hsskinid[i] = 'E012'
    set hsselectid[i] = 'A087'
    set hspassiveid[i] = 'A0I2'
    set i = i + 1
    set hstarget[i] = gg_unit_E00W_0614 //elementalist
    set hsskinid[i] = 'E00W'
    set hsselectid[i] = 'A089'
    set hspassiveid[i] = 'A0I3'
    set i = i + 1
    set hstarget[i] = gg_unit_E002_0585 //assassin
    set hsskinid[i] = 'E002'
    set hsselectid[i] = 'A07J'
    set hspassiveid[i] = 'A01N'
    set i = i + 1
    set hstarget[i] = gg_unit_O03J_0609 //thunder blade
    set hsskinid[i] = 'O03J'
    set hsselectid[i] = 'A01P'
    set hspassiveid[i] = 'A039'
    set i = i + 1
    set hstarget[i] = gg_unit_E015_0586 //master rogue
    set hsskinid[i] = 'E015'
    set hsselectid[i] = 'A07L'
    set hspassiveid[i] = 'A0I1'
    set i = i + 1
    set hstarget[i] = gg_unit_E008_0587 //elite marksman
    set hsskinid[i] = 'E008'
    set hsselectid[i] = 'A07M'
    set hspassiveid[i] = 'A070'
    set i = i + 1
    set hstarget[i] = gg_unit_E00X_0611 //phoenix ranger
    set hsskinid[i] = 'E00X'
    set hsselectid[i] = 'A07N'
    set hspassiveid[i] = 'A0I6'
    set i = 0
    
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
