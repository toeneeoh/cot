library Items requires Functions, Commands, Dungeons, PVP, Chaos

globals
    real array SpdefBonus
    integer array MovespeedBonus
    integer array ItemMovespeed
    integer array EvasionBonus
    integer array ItemEvasion
    real array ItemSpelldef
    real array ItemTotaldef
    real array ItemSpellboost
    integer array ItemGoldRate
    boolean array donated
    constant real donationrate = 0.1
    dialog array dChooseItem
    dialog array dUpgradeItem
    dialog array dUseDiscount
    boolean array ConsumeDiscount
    button array slotitem
    button array CancelButton
    button array UpgradeButton
    timer array rezretimer
    integer array ColoCount_main
    integer array ColoEnemyType_main
    integer array ColoCount_sec
    integer array ColoEnemyType_sec
    item array UpgradingItem
    item array DiscountItem
    integer array UpgradeSlot
    integer TrainerSpawn = 0
    integer TrainerSpawnChaos = 0
    boolean hordequest = false
    dialog array PvpDialog
    button array PvpButton
    boolean array dropflag
    boolean array ItemsDisabled
endglobals

function RechargeDialog takes integer pid, integer itid, real percentage returns nothing
    local string message = GetObjectName(itid)
    local integer playerGold = GetPlayerGold(Player(pid - 1))
    local integer playerLumber = GetPlayerLumber(Player(pid - 1))
    local real goldCost = ItemData[itid][StringHash("cost")] * 100 * percentage + playerGold * percentage
    local real lumberCost = ItemData[itid][StringHash("cost")] * 100 * percentage + playerLumber * percentage
    local real platCost = udg_Plat_Gold[pid] * percentage
    local real arcCost = udg_Arca_Wood[pid] * percentage

    set goldCost = goldCost + (platCost - R2I(platCost)) * 1000000
    set lumberCost = lumberCost + (arcCost - R2I(arcCost)) * 1000000
    set platCost = R2I(platCost)
    set arcCost = R2I(arcCost)

    call DialogClear(dChooseReward[pid])

    if platCost > 0 then
        set message = message + "\nRecharge cost:\n|cffffffff" + RealToString(platCost) +"|r |cffe3e2e2Platinum|r, |cffffffff" + RealToString(goldCost) + "|r |cffffcc00Gold|r\n"
    else
        set message = message + "\nRecharge cost:\n|cffffffff" + RealToString(goldCost) + " |cffffcc00Gold|r\n"
    endif
    if arcCost > 0 then
        set message = message + "|cffffffff" + RealToString(arcCost) + "|r |cff66FF66Arcadite|r, |cffffffff" + RealToString(lumberCost) + "|r |cff472e2eLumber|r"
    else
        set message = message + "|cffffffff" + RealToString(lumberCost) + " |cff472e2eLumber|r"
    endif
    call DialogSetMessage( dChooseReward[pid], message)
    if HasPlayerGold(pid, R2I(goldCost), R2I(platCost)) and HasPlayerLumber(pid, R2I(lumberCost), R2I(arcCost)) then
        set slotitem[4000 + pid] = DialogAddButton(dChooseReward[pid], "Recharge", 'y')
    endif
    call DialogAddButton(dChooseReward[pid], "Cancel", 'c')

    call DialogDisplay(Player(pid - 1), dChooseReward[pid], true)
endfunction

function DudFloorCheck takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local item itm = LoadItemHandle(MiscHash, GetHandleId(t), 0)
    local real x = GetItemX(itm)
    local real y = GetItemY(itm)

    if (IsItemOwned(itm) == false) and (IsItemVisible(itm) == true) then
        call DudToItem(itm, null, x, y)
    endif

    call RemoveSavedHandle(MiscHash, GetHandleId(t), 0)
    call ReleaseTimer(t)

    set t = null
    set itm = null
endfunction

function KillQuestHandler takes integer pid, integer itemid, integer index returns nothing
    local integer min = KillQuest[index][StringHash("Min")]
    local integer max = KillQuest[index][StringHash("Max")]
    local integer goal = KillQuest[index][StringHash("Goal")]
    local integer playercount = 0
    local User U = User.first
    local player p = Player(pid - 1)
    local integer avg = R2I((max + min) * 0.5)
    local real x
    local real y
    local rect myregion = null

    if GetUnitLevel(Hero[pid]) < min then
        call DisplayTimedTextToPlayer(p, 0,0, 10, "You must be level |cffffcc00" + I2S(min) + "|r to begin this quest." )
    elseif GetUnitLevel(Hero[pid]) > max then
        call DisplayTimedTextToPlayer(p, 0,0, 10, "You are too high level to do this quest." )
    elseif udg_KillQuest_Status[index] == 1 then
        call DisplayTimedTextToPlayer(p, 0,0, 10, "Killed " + I2S(KillQuest[index][StringHash("Count")]) + "/" + I2S(goal) + " " + KillQuest[index].string[StringHash("Name")] )
        call PingMinimap(GetRectCenterX(KillQuest[index].rect[StringHash("Region")]), GetRectCenterY(KillQuest[index].rect[StringHash("Region")]), 3)
    elseif udg_KillQuest_Status[index] == 0 then
        set udg_KillQuest_Status[index] = 1
        call DisplayTimedTextToPlayer(p, 0, 0, 10, "|cffffcc00QUEST:|r Kill " + I2S(goal) + " " + KillQuest[index].string[StringHash("Name")] + " for a reward." )
        call PingMinimap(GetRectCenterX(KillQuest[index].rect[StringHash("Region")]), GetRectCenterY(KillQuest[index].rect[StringHash("Region")]), 5)
    elseif udg_KillQuest_Status[index] == 2 then //reward
        loop
            exitwhen U == User.NULL
            set pid = GetPlayerId(U.toPlayer()) + 1

            if HeroID[pid] > 0 and GetUnitLevel(Hero[pid]) >= min and GetUnitLevel(Hero[pid]) <= max then
                set playercount = playercount + 1
            endif

            set U = U.next
        endloop

        set U = User.first

        loop
            exitwhen U == User.NULL
            set pid = GetPlayerId(U.toPlayer()) + 1

            if GetHeroLevel(Hero[pid]) >= min and GetHeroLevel(Hero[pid]) <= max then
                call DisplayTimedTextToPlayer(U.toPlayer(), 0, 0, 10, "|c00c0c0c0" + KillQuest[index].string[StringHash("Name")] + " quest completed!|r" )
                call AwardGold(U.toPlayer(), udg_RewardGold[avg] * goal / (0.5 + playercount * 0.5), true)
                set udg_XP = R2I(udg_Experience_Table[avg] * udg_XP_Rate[pid] * goal)
                set udg_XP = IMaxBJ(100, R2I(udg_XP / 1800.0))
                call SetHeroXP(Hero[pid], GetHeroXP(Hero[pid]) + udg_XP, true)
                call ExperienceControl(pid)
                call DoFloatingTextUnit("+" + I2S(udg_XP) + " XP", Hero[pid], 2, 80, 0, 10, 204, 0, 204, 0)
            endif

            set U = U.next
        endloop
            
        //reset
        set udg_KillQuest_Status[index] = 1
        set KillQuest[index][StringHash("Count")] = 0
        set KillQuest[index][StringHash("Goal")] = IMinBJ(goal + 3, 100)

        //increase max spawns by up to 50 based on last unit killed
        if (KillQuest[index][StringHash("Goal")]) < 100 and ModuloInteger(KillQuest[index][StringHash("Goal")], 2) == 0 then
			set myregion = SelectGroupedRegion(UnitData[KillQuest[index][StringHash("Last")]][StringHash("spawn")])
            loop
                set x = GetRandomReal(GetRectMinX(myregion), GetRectMaxX(myregion))
                set y = GetRandomReal(GetRectMinY(myregion), GetRectMaxY(myregion))
                exitwhen IsTerrainWalkable(x, y)
            endloop
            call CreateUnit(pfoe, KillQuest[index][StringHash("Last")], x, y, GetRandomInt(0, 359))
            set myregion = null
        endif
    endif
    
    set p = null
endfunction

function StackItem takes item itm, unit u returns nothing
    local integer i = 0
    local integer index = 0
    local integer itemid = GetItemTypeId(itm)

    loop
        exitwhen i > 5
        if itemid == GetItemTypeId(UnitItemInSlot(u, i)) and UnitItemInSlot(u, i) != itm and GetItemCharges(UnitItemInSlot(u, i)) < 10 and GetItemCharges(itm) < 10 then
            set index = GetItemCharges(UnitItemInSlot(u, i)) + GetItemCharges(itm)
            if index < 11 then
                call SetItemCharges(UnitItemInSlot(u, i), index)
                call UnitRemoveItem(u, itm)
                call SetItemPosition(itm, -25000, -25000)
                exitwhen true
                //call RemoveItem(itm)
            else
                call SetItemCharges(UnitItemInSlot(u, i), 10)
                call SetItemCharges(itm, index - 10)
                exitwhen true
            endif
        endif
        set i = i + 1
    endloop
endfunction

function CompleteDialog takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer index= 1
    local integer pid= GetPlayerId(p)+1
    local item itm

	loop
		exitwhen index > 10
		if GetClickedButton() == slotitem[50+pid*10 +index] then
			call CreateHeroItem(Hero[pid], pid, LoadInteger(RewardItems,udg_SlotIndex[pid],index), 1)
			call DialogClear( dUpgradeItem[pid] )
		endif
		set index = index + 1
	endloop

    if GetClickedButton() == slotitem[4000 + pid] then //recharge reincarnation
        set itm = GetResurrectionItem(pid, true)
        call SetItemCharges(itm, GetItemCharges(itm) + 1)
        if udg_Hardcore[pid] then
            call ChargeNetworth(p, ItemData[GetItemTypeId(itm)][StringHash("cost")] * 3, 0.03, 0, "Recharged " + GetItemName(itm) + " for")
        else
            call ChargeNetworth(p, ItemData[GetItemTypeId(itm)][StringHash("cost")], 0.01, 0, "Recharged " + GetItemName(itm) + " for")
        endif
        call TimerStart(rezretimer[pid], 180., false,null)
    endif

    set itm = null
    set p = null
endfunction

function SpellBox takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid= GetPlayerId(p) + 1
    local integer ablev=udg_SlotIndex[91 + pid * 3]

	if ( GetClickedButton() == SpellButton[pid] ) then
		call ChargePlayerGold(pid, ModuloInteger(udg_SlotIndex[92 + pid * 3], 1000000), R2I(udg_SlotIndex[92 + pid * 3] / 1000000))
		if udg_SlotIndex[90 + pid * 3]=='I101' then
			if ablev==0 then
                //
			endif
			call SetUnitAbilityLevel(Backpack[pid], 'A0FV', ablev+1)
			call SetUnitAbilityLevel(Backpack[pid], 'A02J', ablev+1)
			call DisplayTimedTextToPlayer(p, 0, 0, 20, "You successfully upgraded to: Teleport [|cffffcc00Level " + I2S(ablev+1) + "|r]")
		elseif udg_SlotIndex[90 + pid * 3]=='I102' then
			if ablev==0 then
				call UnitAddAbility(Backpack[pid], 'A0FK')
			endif
			call SetUnitAbilityLevel(Backpack[pid], 'A0FK', ablev+1)
			call DisplayTimedTextToPlayer(p, 0, 0, 20, "You successfully upgraded to: Reveal [|cffffcc00Level " + I2S(ablev+1) + "|r]")
		endif
	endif
    set p = null
endfunction

function DisplayItemUpgrade takes player p, integer index returns nothing
    local integer levelreq = 0
    local integer pid = GetPlayerId(p) + 1
    local integer itemnumb
    local item itm
    local real dfactor
    local string ss = ""
    local integer i = 0

    set itemnumb = UpgradeSlot[pid * 12 + index]

    set levelreq = ItemData[UpItemBecomes[itemnumb]][StringHash("level")]

	call DialogClear( dUpgradeItem[pid] )

    if ConsumeDiscount[pid] then
        set dfactor = 2
    else
        set dfactor = 1
    endif
            
	set ss= "Upgrade cost: \n|cffffffff"+I2S(CostAdjust(UpItemCostPlat[itemnumb],dfactor))+"|r |cffe3e2e2Platinum|r|cffffffff, "+I2S(CostAdjust(UpItemCostArc[itemnumb],dfactor))+"|r |c0066FF66Arcadite|r"
        
	if CostAdjust(UpItemCostCrys[itemnumb],dfactor) > 0 then
		call DialogSetMessage( dUpgradeItem[pid], ss+"|cffffffff,|r \n|cffffffff"+I2S(CostAdjust(UpItemCostCrys[itemnumb],dfactor))+"|r |c006969FFCrystals|r \n|cffff0000Level Requirement:|r |cffffffff"+I2S(levelreq) )
	else
		call DialogSetMessage( dUpgradeItem[pid], ss+"\n |cffff0000Level Requirement:|r |cffffffff"+I2S(levelreq) )
	endif

	if (levelreq > GetUnitLevel(Hero[pid]) ) or (udg_Crystals[pid]< CostAdjust(UpItemCostCrys[itemnumb],dfactor)) then
	elseif (udg_Arca_Wood[pid]< CostAdjust(UpItemCostArc[itemnumb],dfactor)) or (udg_Plat_Gold[pid]< CostAdjust(UpItemCostPlat[itemnumb],dfactor)) then
	else
	    set UpgradeButton[pid] = DialogAddButton(dUpgradeItem[pid], "Upgrade", 'U')
	    set UpgradeSlot[100 + pid] = itemnumb
	endif

	call DialogAddButton(dUpgradeItem[pid], "Cancel", 'C')
	call DialogDisplay(p, dUpgradeItem[pid], true )
endfunction

function UseDiscount takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer index = 0
    local integer pid = GetPlayerId(p) + 1

    loop
        exitwhen GetClickedButton() == UpgradeButton[pid * 12 + index] or index > 200
        set index = index + 1
	endloop

    if index <= 12 then
        set ConsumeDiscount[pid] = true
        call DisplayItemUpgrade(p, index)
    else
        set ConsumeDiscount[pid] = false
        call DisplayItemUpgrade(p, index - 100)
    endif
endfunction

function UpgradeItem takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer index = 0
    local integer pid = GetPlayerId(p) + 1
    local integer itemnumb
    local item itm
    local integer i = 0

    loop
        exitwhen GetClickedButton() == slotitem[pid * 12 + index] or index > 12
        set index = index + 1
	endloop

	if index <= 12 then
        if index > 5 then
            set UpgradingItem[pid] = UnitItemInSlot(Backpack[pid], index - 6)
        else
            set UpgradingItem[pid] = UnitItemInSlot(Hero[pid], index)
        endif

        set itemnumb = UpgradeSlot[pid * 12 + index]

        if UpDiscountItem[itemnumb] > 0 then
            loop
                exitwhen i > 11
                if i > 5 then
                    set itm = UnitItemInSlot(Backpack[pid], i - 6)
                else
                    set itm = UnitItemInSlot(Hero[pid], i)
                endif
                if GetItemTypeId(itm) == UpDiscountItem[itemnumb] and itm != UpgradingItem[pid] then
                    //prompt to use discount item
                    set DiscountItem[pid] = itm
                    call DialogClear( dUseDiscount[pid] )
                    call DialogSetMessage(dUseDiscount[pid], "Consume " + GetItemName(itm) + " for a 50% discount?")
                    set UpgradeButton[pid * 12 + index] = DialogAddButton(dUseDiscount[pid], "Yes", 'Y')
                    set UpgradeButton[pid * 12 + index + 100] = DialogAddButton(dUseDiscount[pid], "No", 'N')
                    call DialogDisplay(p, dUseDiscount[pid], true)
                    set p = null
                    set itm = null
                    return
                endif
                set i = i + 1
            endloop
        endif

        call DisplayItemUpgrade(p, index)
	endif

    set p = null
    set itm = null
endfunction

function UpgradeItemConfirm takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local integer pid= GetPlayerId(p)+1
    local integer index= UpgradeSlot[100+pid]
    local real dfactor=1
    local item itm
    local integer i = 0

	if GetClickedButton() == UpgradeButton[pid] then
        if ConsumeDiscount[pid] then
            set dfactor = UpgradeCostFactor[index]
            call RemoveItem(DiscountItem[pid])
            set DiscountItem[pid] = null
            set ConsumeDiscount[pid] = false
        endif
        call AddPlatinumCoin(pid, - CostAdjust(UpItemCostPlat[index],dfactor))
        call AddArcaditeLumber(pid, - CostAdjust(UpItemCostArc[index],dfactor))
        call AddCrystals(pid, -CostAdjust(UpItemCostCrys[index],dfactor))
        call RemoveItem(UpgradingItem[pid])
        set UpgradingItem[pid] = null
		call CreateHeroItem(Hero[pid], pid, UpItemBecomes[index], 1)
		call DisplayTimedTextToPlayer(p,0,0, 20, "You successfully upgraded to: "+GetObjectName(UpItemBecomes[index]) )
        if CostAdjust(UpItemCostPlat[index],dfactor) > 0 then
            call DisplayTimedTextToPlayer(p,0,0, 5, PlatTag + I2S(udg_Plat_Gold[pid]) )
        endif
        if CostAdjust(UpItemCostArc[index],dfactor) > 0 then
            call DisplayTimedTextToPlayer(p,0,0, 5, ArcTag + I2S(udg_Arca_Wood[pid]) )
        endif
        if CostAdjust(UpItemCostCrys[index],dfactor) > 0 then
            call DisplayTimedTextToPlayer(p,0,0, 5, udg_CrystalTag +I2S(udg_Crystals[pid]) )
        endif
	endif
    
    set itm = null
    set p = null
endfunction

function ItemFilter takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local player p = GetOwningPlayer(u)
    local integer pid = GetPlayerId(p) + 1
    local item itm = GetManipulatedItem()
    local integer i = 0
    local integer slot = GetItemSlot(itm, u)
    local integer itemid = GetItemTypeId(itm)
    local integer origowner = GetItemUserData(itm)
    local integer LEVEL = ItemData[itemid][StringHash("level")]

    //bind drop
    if IsItemBound(itm, pid) and (IsItemSaved(itm) or IsBindItem(itemid)) then
        set dropflag[pid] = true
        call DisplayTimedTextToPlayer(p, 0, 0, 30, "This item is bound to " + User.fromIndex(origowner - 1).nameColored + ".")
    else
        if u == Hero[pid] then //hero
            //level drop
            if LEVEL > GetHeroLevel(u) then
                set dropflag[pid] = true
                call DisplayTimedTextToPlayer(p, 0, 0, 15., "This item requires at least level |c00FF5555" + I2S(LEVEL) + "|r to equip.")
            
            //restriction drop
            elseif IsItemRestricted(itm, u) then
                set dropflag[pid] = true
                call DisplayTimedTextToPlayer(p, 0, 0, 10, restricted_string[RESTRICTED_ERROR])
            endif

            //bind / dud pickup
            if dropflag[pid] == false then
                if IsItemDud(itm) then
                    call DudToItem(itm, u, 0, 0)
                elseif IsItemSaved(itm) or IsBindItem(itemid) then
                    call BindItem(itm, pid)
                endif
            endif

            call UnitSpecification(u)

        elseif u == Backpack[pid] then //backpack
            if IsItemDud(itm) == false and LEVEL > GetHeroLevel(Hero[pid]) + 20 then
                set dropflag[pid] = true
                call DisplayTimedTextToPlayer(p, 0, 0, 15., "This item requires at least level |c00FF5555" + I2S(LEVEL - 20) + "|r to pick up.")
            //make dud
            elseif IsItemDud(itm) == false and LEVEL > GetHeroLevel(Hero[pid]) then
                call ItemToDud(itm, u)
            endif

            call UnitSpecification(u)
        endif
    endif

    if dropflag[pid] then
        call UnitRemoveItem(u, itm)
    endif

    set u = null
    set itm = null
    return true
endfunction

function onSell takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local unit b = GetBuyingUnit()
    local item itm = GetSoldItem()
    
    if GetUnitTypeId(u) == 'h002' then //naga chest
        call RemoveUnitTimed(u, 2.5)
        call DestroyEffect(AddSpecialEffectTarget("UI\\Feedback\\GoldCredit\\GoldCredit.mdl", u, "origin"))
        call Fade(u, 40, 0.05, 1)
    endif

    if GetUnitTypeId(b) == BACKPACK then
        call BindItem(itm, GetPlayerId(GetOwningPlayer(b)) + 1)
    endif
    
    set u = null
    set b = null
    set itm = null
endfunction

function onUse takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local item itm = GetManipulatedItem()
    local player p = GetOwningPlayer(u)
    local integer itemid = GetItemTypeId(itm)
    local integer pid= GetPlayerId(p) + 1
    local timer t

    if u == Hero[pid] then //Potions (Hero)
		if itemid == 'I0BJ' then
			call HP(u, 10000)
		elseif itemid == 'I028' then
			call HP(u, 2000)
		elseif itemid == 'pghe' then
			call HP(u, 500)
		elseif itemid == 'I0BL' then
			call MP(u, 10000)
		elseif itemid == 'I00D' then
			call MP(u, 2000)
		elseif itemid == 'pgma' then
			call MP(u, 500)
		elseif itemid == 'I0MP' then
			call HP(u, 50000 + BlzGetUnitMaxHP(u) * 0.08)
			call MP(u, BlzGetUnitMaxMana(u) * 0.08)
        elseif itemid == 'I0MQ' then
			call HP(u, BlzGetUnitMaxHP(u) * 0.15)
        elseif itemid == 'vamp' then //vampiric potion
            if GetWidgetLife(Hero[pid]) >= 0.406 then
                set VampiricPotion.add(Hero[pid], Hero[pid]).duration = 10.
            endif
        endif
	endif
    
    set u = null
    set itm = null
    set p = null
    set t = null
endfunction

function onDrop takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local item itm = GetManipulatedItem()
    local player p = GetOwningPlayer(u)
    local integer itemid = GetItemTypeId(itm)
    local integer pid = GetPlayerId(p) + 1
    local integer index = 0
    local real mod = 1
    local real hp
    local real x = GetItemX(itm)
    local real y = GetItemY(itm)
    local timer t
    
    if u == Hero[pid] and dropflag[pid] == false then
        set mod = ItemProfMod(itemid, pid)
                
        set hp = GetWidgetLife(u)
        call UnitAddBonus(u, BONUS_ARMOR, -R2I(mod * ItemData[itemid][StringHash("armor")]) )
        call UnitAddBonus(u, BONUS_DAMAGE, -R2I(mod * ItemData[itemid][StringHash("damage")] * (1 + Dmg_mod[pid] * 0.01)) )
        call UnitAddBonus(u, BONUS_HERO_STR, -R2I(mod * (ItemData[itemid][StringHash("str")] + ItemData[itemid][StringHash("stats")]) * (1 + Str_mod[pid] * 0.01)) )
        call UnitAddBonus(u, BONUS_HERO_AGI, -R2I(mod * (ItemData[itemid][StringHash("agi")] + ItemData[itemid][StringHash("stats")]) * (1 + Agi_mod[pid] * 0.01)) )
        call UnitAddBonus(u, BONUS_HERO_INT, -R2I(mod * (ItemData[itemid][StringHash("int")] + ItemData[itemid][StringHash("stats")]) * (1 + Int_mod[pid] * 0.01)) )
        call BlzSetUnitMaxHP(u, BlzGetUnitMaxHP(u) - R2I(mod * ItemData[itemid][StringHash("health")]) )
        call SetWidgetLife(u, RMaxBJ(hp, 1))
        set ItemRegen[pid] = ItemRegen[pid] - ItemData[itemid][StringHash("regen")]
        set ItemSpelldef[pid] = ItemSpelldef[pid] / (1 - ItemData[itemid][StringHash("mr")] * 0.01)
        set ItemTotaldef[pid] = ItemTotaldef[pid] / (1 - ItemData[itemid][StringHash("dr")] * 0.01)
        call BlzSetUnitAttackCooldown(u, BlzGetUnitAttackCooldown(u, 0) * (1 + ItemData[itemid][StringHash("bat")] * 0.01), 0)
        set ItemEvasion[pid] = ItemEvasion[pid] - ItemData[itemid][StringHash("evasion")]
        set ItemMovespeed[pid] = ItemMovespeed[pid] - ItemData[itemid][StringHash("movespeed")]
        set ItemSpellboost[pid] = ItemSpellboost[pid] - ItemData[itemid][StringHash("spellboost")] * 0.01
        set ItemGoldRate[pid] = ItemGoldRate[pid] - ItemData[itemid][StringHash("gold")]
    elseif IsItemDud(itm) then
        set t = NewTimer()
        call SaveItemHandle(MiscHash, GetHandleId(t), 0, itm)
        call TimerStart(t, 0.01, false, function DudFloorCheck)
    endif
    
    set u = null
    set itm = null
    set p = null
    set t = null
endfunction

function onPickup takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local item itm = GetManipulatedItem()
    local item itm2
    local integer itemid = GetItemTypeId(itm)
    local player p = GetOwningPlayer(u)
    local integer pid = GetPlayerId(p) + 1
    local integer origowner = GetItemUserData(itm)
    local integer index = 0
    local integer i = 0
    local integer i2 = 0
    local integer levmin
    local integer levmax
    local real mod
    local real x
    local real y
    local group ug = CreateGroup()
    local User U = User.first

    //========================
    //Quests
    //========================

    if KillQuest.has(itemid) then //Kill Quest
        call FlashQuestDialogButton()
        call KillQuestHandler(pid, itemid, KillQuest[itemid][StringHash("Index")])
    elseif itemid == 'I0OV' then //Gossip
        set x = GetUnitX(gg_unit_n01F_0576)
        set y = GetUnitY(gg_unit_n01F_0576)

        if x > GetRectMaxX(gg_rct_Main_Map) then //in tavern
            call DisplayTextToForce(FORCE_PLAYING, "|cffffcc00Evil Shopkeeper's Brother:|r I don't know where he is.")
        else
            if x < GetRectCenterX(gg_rct_Main_Map) and y > GetRectCenterY(gg_rct_Main_Map) then
                set ShopkeeperDirection[0] = "|cffffcc00North West|r"
            elseif x > GetRectCenterX(gg_rct_Main_Map) and y > GetRectCenterY(gg_rct_Main_Map) then
                set ShopkeeperDirection[0] = "|cffffcc00North East|r"
            elseif x < GetRectCenterX(gg_rct_Main_Map) and y < GetRectCenterY(gg_rct_Main_Map) then
                set ShopkeeperDirection[0] = "|cffffcc00South West|r"
            else
                set ShopkeeperDirection[0] = "|cffffcc00South East|r"
            endif

            set ShopkeeperDirection[1] = "|cffffcc00Evil Shopkeeper's Brother:|r My brother is currently heading " + ShopkeeperDirection[0] + " to expand his business."
            set ShopkeeperDirection[2] = "|cffffcc00Evil Shopkeeper's Brother:|r I last heard that he was spotted traveling " + ShopkeeperDirection[0] + " to negotiate with some suppliers."
            set ShopkeeperDirection[3] = "|cffffcc00Evil Shopkeeper's Brother:|r My brother is rumored to have traveled " + ShopkeeperDirection[0] + " to seek new markets for his products."
            set ShopkeeperDirection[4] = "|cffffcc00Evil Shopkeeper's Brother:|r I haven't seen him for a while, but I suspect he might be up " + ShopkeeperDirection[0] + " hunting for rare items to sell."
            set ShopkeeperDirection[5] = "|cffffcc00Evil Shopkeeper's Brother:|r He is never in one place for too long. He's probably moved " + ShopkeeperDirection[0] + " by now."
            set ShopkeeperDirection[6] = "|cffffcc00Evil Shopkeeper's Brother:|r If I had to guess, I'd say he is currently located in the " + ShopkeeperDirection[0] + " part of the city."
            set ShopkeeperDirection[7] = "|cffffcc00Evil Shopkeeper's Brother:|r I'm not sure where he is, but he usually heads " + ShopkeeperDirection[0] + " when he wants to avoid trouble."
            set ShopkeeperDirection[8] = "|cffffcc00Evil Shopkeeper's Brother:|r I heard that my brother is hiding to the " + ShopkeeperDirection[0] + " of town."
            set ShopkeeperDirection[9] = "|cffffcc00Evil Shopkeeper's Brother:|r He often travels to the " + ShopkeeperDirection[0] + ", looking for new opportunities to make a profit."
            set ShopkeeperDirection[10] = "|cffffcc00Evil Shopkeeper's Brother:|r He is always on the move. He could be anywhere, but my guess is he's headed due " + ShopkeeperDirection[0] + "."

            call DisplayTextToForce(FORCE_PLAYING, ShopkeeperDirection[GetRandomInt(1, 10)])
        endif

    elseif itemid == 'I08L' then //Evil Shopkeeper
        if IsQuestDiscovered(udg_Evil_Shopkeeper_Quest_1) and IsQuestCompleted(udg_Evil_Shopkeeper_Quest_1) == false then
            loop
                exitwhen i > 5
                if GetItemTypeId(UnitItemInSlot(u, i)) == 'I045' then
                    call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_COMPLETED, "|cffffcc00OPTIONAL QUEST COMPLETED|r\nThe Evil Shopkeeper")
                    call QuestSetCompleted(udg_Evil_Shopkeeper_Quest_1, true)
                    call QuestItemSetCompleted(udg_Quest_Req[11], true)
                    exitwhen true
                endif
                set i = i + 1
            endloop
        elseif IsQuestDiscovered(udg_Evil_Shopkeeper_Quest_1) == false then
            if GetUnitLevel(Hero[pid]) >= 50 then
                call QuestSetDiscovered(udg_Evil_Shopkeeper_Quest_1, true)
                call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1OPTIONAL QUEST|r\nThe Evil Shopkeeper")
            else
                call DisplayTextToPlayer(p, 0, 0, "You must be at least level 50 to begin this quest.")
            endif
        endif
    elseif itemid == 'I00L' then //The Horde
        if GetUnitLevel(Hero[pid]) >= 100 then
            if IsQuestDiscovered(udg_Defeat_The_Horde_Quest) == false then
                call DestroyEffect(udg_TalkToMe20)
                call QuestSetDiscovered(udg_Defeat_The_Horde_Quest, true)
                call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_DISCOVERED, "|cff322ce1OPTIONAL QUEST|r\nThe Horde")
                call PingMinimap(12577, -15801, 4)
                call PingMinimap(15645, -12309, 4)
                
                //orc setup
                call SetUnitPosition(gg_unit_N01N_0050, 14665, -15352)
                call UnitAddAbility(gg_unit_N01N_0050, 'Avul')
                
                //bottom side
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 12687, -15414, 45), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 12866, -15589, 45), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 12539, -15589, 45), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 12744, -15765, 45), "patrol", 668, -2146)
                //top side
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 15048, -12603, 225), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o01I', 15307, -12843, 225), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 15299, -12355, 225), "patrol", 668, -2146)
                call IssuePointOrder(CreateUnit(pboss, 'o008', 15543, -12630, 225), "patrol", 668, -2146)
                
                call TimerStart(NewTimer(), 30., true, function SpawnOrcs)
            elseif IsQuestCompleted(udg_Defeat_The_Horde_Quest) == false then
                call DisplayTextToPlayer(p, 0, 0, "Militia: The Orcs are still alive!")
            elseif IsQuestCompleted(udg_Defeat_The_Horde_Quest) == true and not hordequest then
                call DisplayTextToPlayer(p, 0, 0, "Militia: As promised, the Key of Valor.")
                call CreateItem('I041', -800, -865)
                set hordequest = true
                call DestroyEffect(udg_TalkToMe20)
            endif
        else
            call DisplayTextToPlayer(p, 0, 0, "You must be level |cffffcc00"+I2S(100)+"|r to begin this quest.")
        endif
    else
        
    //Headhunter
        
    loop
        exitwhen i > udg_PermanentInteger[10]
        if itemid == udg_HuntedRecipe[i] then
            if HuntedLevel[i] <= GetHeroLevel(Hero[pid]) then
                if HasItemType(Hero[pid], udg_HuntedHead[i]) or HasItemType(Backpack[pid], udg_HuntedHead[i]) then
                    set itm = GetItemFromUnit(Hero[pid], udg_HuntedHead[i])
                    if itm == null then
                        set itm = GetItemFromUnit(Backpack[pid], udg_HuntedHead[i])
                        call UnitRemoveItem(Backpack[pid], itm)
                        call RemoveItem(itm)
                        call UnitAddItemById(Backpack[pid], udg_HuntedItem[i])
                    else
                        call UnitRemoveItem(Hero[pid], itm)
                        call RemoveItem(itm)
                        call UnitAddItemById(Hero[pid], udg_HuntedItem[i])
                    endif

                    set udg_XP = R2I(udg_HuntedExp[i] * udg_XP_Rate[pid] / 100.)
                    call SetHeroXP(Hero[pid], GetHeroXP(Hero[pid]) + udg_XP, true)
                    call ExperienceControl(pid)
                    call DoFloatingTextUnit("+" + I2S(udg_XP) + " XP", Hero[pid], 2, 80, 0, 10, 204, 0, 204, 0)
                else
                    call DisplayTextToPlayer(p, 0, 0, "You do not have the head.")
                endif
            else
                call DisplayTextToPlayer(p, 0, 0, "You must be level |cffffcc00"+I2S(HuntedLevel[i])+"|r to complete this quest.")
            endif
        endif
        set i= i+1
    endloop

    endif

    set i = 0
    set index = 0
    
    //========================
    //Dungeons
    //========================
    
    if itemid == 'I0JU' then //naga
        if CountPlayersInForceBJ(NAGA_GROUP) > 0 then
            call DisplayTextToPlayer(p, 0, 0, "This dungeon is already in progress!")
        else
            if QUEUE_DUNGEON == 0 then
                call StartDungeon('I0JU', -12363, -1185)
            elseif QUEUE_DUNGEON == 1 then
                call ReadyCheck()
            else
                call DisplayTextToPlayer(p, 0, 0, "Please wait while another dungeon is queueing!")
            endif
        endif
        
    elseif itemid == 'I0NM' then //naga reward
        if RectContainsCoords(gg_rct_Naga_Dungeon_Reward, GetUnitX(u), GetUnitY(u)) or RectContainsCoords(gg_rct_Naga_Dungeon_Boss, GetUnitX(u), GetUnitY(u)) then
            call NagaReward()
        endif
        
    elseif itemid == 'I0JO' and udg_Chaos_World_On == false then //portal to the gods
        if PathtoGodsisOpen and GodsParticipant[pid] == false then
            set GodsParticipant[pid] = true
        
            call SetCameraBoundsRectForPlayerEx(p, gg_rct_GodsCameraBounds)
            call PanCameraToTimedForPlayer(p, GetRectCenterX(gg_rct_GodsEntrance), GetRectCenterY(gg_rct_GodsEntrance), 0)
            call BlzSetUnitFacingEx(Hero[pid], 45)
            call SetUnitPosition(Hero[pid], GetRectCenterX(gg_rct_GodsEntrance), GetRectCenterY(gg_rct_GodsEntrance))
            call reselect(Hero[pid])
            call EnterWeather(Hero[pid])
            
            if GodsEnterFlag == false then
                set GodsEnterFlag = true
                
                call DoTransmissionBasicsXYBJ(GetUnitTypeId(gg_unit_O01A_0372), GetPlayerColor(pboss), GetUnitX(gg_unit_O01A_0372), GetUnitY(gg_unit_O01A_0372), null, "Zeknen", "Explain yourself or be struck down from this heaven!", 10 )
                call TimerStart(NewTimer(), 10, false, function ZeknenExpire)
            endif
        endif
        
    elseif itemid == 'I0NO' and udg_Chaos_World_On == false then //rescind to darkness
        if GodsEnterFlag == false and udg_Chaos_World_On == false and GetHeroLevel(Hero[pid]) >= 240 then
            set powercrystal = CreateUnitAtLoc(pfoe, 'h04S', Location(30000, -30000), bj_UNIT_FACING)
            call KillUnit(powercrystal)
        endif
        
    //========================
    //Buyables / Shops
    //========================
    
    elseif itemid == 'I07Q' and donated[pid] == false then //donation
        call ChargeNetworth(p, 0, 0.01, 100, "")
        set donated[pid] = true
        set donation = donation - donationrate
        call DisplayTextToPlayer(p, 0, 0, "|c00408080The Goddesses bestow their blessings.")
        call DisplayTextToForce(FORCE_PLAYING, "Reduced bad weather: " + I2S(R2I((1 - donation) * 100)) + "%")
    elseif itemid == 'I0M9' then //prestige
        if HasItemType(Hero[pid], 'I0NN') then
            if GetUnitLevel(Hero[pid]) == 400 then
                call ActivatePrestige(p)
            else
                call DisplayTextToPlayer(p, 0, 0, "You are not level 400!")
            endif
        else
            call DisplayTextToPlayer(p, 0, 0, "You do not have a |cffffcc00Prestige Token|r!")
        endif
    elseif itemid == 'I0TS' and HasPlayerGold(pid, 10000, 0) then //str tome
        call HeroAddStats(Hero[pid], 10, 1, false)
    elseif itemid == 'I0TA' and HasPlayerGold(pid, 10000, 0) then //agi tome
        call HeroAddStats(Hero[pid], 10, 2, false)
    elseif itemid == 'I0TI' and HasPlayerGold(pid, 10000, 0) then //int tome
        call HeroAddStats(Hero[pid], 10, 3, false)
    elseif itemid == 'I0TT' and HasPlayerGold(pid, 20000, 0) then //all stats
        call HeroAddStats(Hero[pid], 10, 4, false)
    elseif itemid == 'I0OH' and HasPlayerGold(pid, 0, 1) then //str plat tome
        call HeroAddStats(Hero[pid], 1000, 1, true)
    elseif itemid == 'I0OI' and HasPlayerGold(pid, 0, 1) then //agi plat tome
        call HeroAddStats(Hero[pid], 1000, 2, true)
    elseif itemid == 'I0OK' and HasPlayerGold(pid, 0, 1) then //int plat tome
        call HeroAddStats(Hero[pid], 1000, 3, true)
    elseif itemid == 'I0OJ' and HasPlayerGold(pid, 0, 2) then //all stats plat tome
        call HeroAddStats(Hero[pid], 1000, 4, true)
    elseif itemid == 'I0N0' then //grimoire of focus
        set i = 0
        if GetHeroStr(Hero[pid], false) - 50 > 20 then
            call SetHeroStr(Hero[pid], GetHeroStr(Hero[pid], false) - 50, true)
            set i = i + 5000
        elseif GetHeroStr(Hero[pid], false) >= 20 then
            call SetHeroStr(Hero[pid], 20, true)
        endif
        if GetHeroAgi(Hero[pid], false) - 50 > 20 then
            call SetHeroAgi(Hero[pid], GetHeroAgi(Hero[pid], false) - 50, true)
            set i = i + 5000
        elseif GetHeroAgi(Hero[pid], false) >= 20 then
            call SetHeroAgi(Hero[pid], 20, true)
        endif
        if GetHeroInt(Hero[pid], false) - 50 > 20 then
            call SetHeroInt(Hero[pid], GetHeroInt(Hero[pid], false) - 50, true)
            set i = i + 5000
        elseif GetHeroInt(Hero[pid], false) >= 20 then
            call SetHeroInt(Hero[pid], 20, true)
        endif
        if i > 0 then
            call AddPlayerGold(p, i)
            call DisplayTextToPlayer(p, 0, 0, "You have been refunded |cffffcc00" + RealToString(i) + "|r gold.")
        endif
    elseif itemid == 'I0JN' then //tome of retraining
        call RemoveItem(itm)
        call UnitAddItemById(Hero[pid], 'tret')
    elseif itemid == 'I101' or itemid == 'I102' then //upgrade teleports & reveal
        if itemid == 'I101' then
            set i = GetUnitAbilityLevel(Backpack[pid], 'A02J')
        elseif itemid == 'I102' then
            set i = GetUnitAbilityLevel(Backpack[pid], 'A0FK')
        endif
        
        set index = R2I(400 * Pow(5, i - 1))
        
        call DialogClear(dUpgradeSpell[pid])
        
        if i < 10 then //only 10 upgrades
        
            if index > 1000000 then
                call DialogSetMessage(dUpgradeSpell[pid], "Upgrade cost: \n|cffffffff" + I2S(index / 1000000) + " |cffe3e2e2Platinum|r |cffffffffand " + I2S(ModuloInteger(index, 1000000)) + " gold|r")
            else
                call DialogSetMessage(dUpgradeSpell[pid], "Upgrade cost: \n|cffffffff" + I2S(index) + " gold")
            endif
            
            if HasPlayerGold(pid, ModuloInteger(index, 1000000), R2I(index / 1000000)) then
                set SpellButton[pid] = DialogAddButton(dUpgradeSpell[pid], "Purchase", 'U')
                set udg_SlotIndex[90 + pid * 3] = itemid
                set udg_SlotIndex[91 + pid * 3] = i
                set udg_SlotIndex[92 + pid * 3] = index
            endif
            
        endif
        
        call DialogAddButton(dUpgradeSpell[pid], "Cancel", 'C')
        call DialogDisplay(p, dUpgradeSpell[pid], true)
    elseif itemid == 'I100' then //upgrade item
        call DialogClear(dChooseItem[pid])
        call DialogSetMessage(dChooseItem[pid], "Choose an item to upgrade.")
        set UpgradingItem[pid] = null
        set DiscountItem[pid] = null
        set ConsumeDiscount[pid] = false
        loop
            exitwhen index > 11
            if index > 5 then
                set itm = UnitItemInSlot(Backpack[pid], index - 6)
                set i2 = GetItemTypeId(UnitItemInSlot(Backpack[pid], index - 6))
            else
                set itm = UnitItemInSlot(Hero[pid], index)
                set i2 = GetItemTypeId(UnitItemInSlot(Hero[pid], index))
            endif
            set i = 0
            loop
                exitwhen i > udg_PermanentInteger[2]
                if i2 == UpItem[i] then
                    set slotitem[pid * 12 + index] = DialogAddButton(dChooseItem[pid], GetItemName(itm), 0)
                    set UpgradeSlot[pid * 12 + index] = i
                endif
                set i = i + 1
            endloop
            set index = index + 1
        endloop
        call DialogAddButton(dChooseItem[pid], "Cancel", 'C')
        call DialogDisplay(p, dChooseItem[pid], true)
    elseif itemid == 'I04G' then //item based conversions
		if GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)>999999  then
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)-1000000 )
			call Plat_Effect(p)
            call AddPlatinumCoin(pid, 1)
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(udg_Plat_Gold[pid]) )
		else
			call DisplayTimedTextToPlayer(p,0,0, 30, "|cffee0000You do not have a million gold to convert." )
		endif
	elseif itemid == 'I04H' then
		if GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)>999999 then 
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)-1000000 )
			call Plat_Effect(p)
            call AddArcaditeLumber(pid, 1)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(udg_Arca_Wood[pid]) )
		else
			call DisplayTimedTextToPlayer(p,0,0, 30, "|cffee0000You do not have a million lumber to convert." )
		endif
	elseif itemid == 'I054' then
		if udg_Arca_Wood[pid] >0 then 
			call Plat_Effect(p)
            call AddPlatinumCoin(pid, 1)
            call AddArcaditeLumber(pid, -1)
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)+200000 )
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(udg_Arca_Wood[pid]) )
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(udg_Plat_Gold[pid]) )
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber." )
		endif
	elseif itemid == 'I053' then
		if udg_Plat_Gold[pid] >0 then
			call Plat_Effect(p)
            call AddPlatinumCoin(pid, -1)
            call AddArcaditeLumber(pid, 1)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(udg_Arca_Wood[pid]) )
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(udg_Plat_Gold[pid]) )
		else
            call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) + 350000)
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Platinum Coins." )
		endif
	elseif itemid == 'I0PA' then
		if udg_Plat_Gold[pid] >= 4 then
			call Plat_Effect(p)
            call AddPlatinumCoin(pid, -4)
            call AddArcaditeLumber(pid, 3)
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(udg_Arca_Wood[pid]) )
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(udg_Plat_Gold[pid]) )
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; due to insufficient Platinum Coins." )
		endif
	elseif itemid == 'I051' then
		if udg_Arca_Wood[pid] >0 then
			call Plat_Effect(p)
            call AddArcaditeLumber(pid, -1)
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)+1000000 )
			call DisplayTimedTextToPlayer(p,0,0, 20, ArcTag + I2S(udg_Arca_Wood[pid]) )
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Arcadite Lumber." )
		endif
	elseif itemid == 'I052' then
		if udg_Plat_Gold[pid] >0 then
			call Plat_Effect(p)
            call AddPlatinumCoin(pid, -1)
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)+1000000 )
			call DisplayTimedTextToPlayer(p,0,0, 20, PlatTag + I2S(udg_Plat_Gold[pid]) )
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "|cff990000Unable to convert; not enough Platinum Coins." )
		endif
	elseif itemid == 'I03R' then
		if GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER) >= 25000 then
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)+25000 )
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)-25000 )
			call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 25,000 lumber to buy this." )
		endif
	elseif itemid == 'I05C' then
		if GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD) >= 32000 then
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(p,PLAYER_STATE_RESOURCE_GOLD)-32000 )
			call SetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(p,PLAYER_STATE_RESOURCE_LUMBER)+25000 )
			call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\ResourceItems\\ResourceEffectTarget.mdl", u, "origin"))
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 32,000 gold to buy this." )
		endif
    elseif itemid == 'I05S' then //prestige token
        if GetHeroLevel(Hero[pid]) < 400 then
            call DisplayTimedTextToPlayer(p,0,0, 20, "You need level 400 to buy this." )
        else
            if udg_Crystals[pid] >= 2500 then
                call AddCrystals(pid, -2500)
                call CreateHeroItem(Hero[pid], pid, 'I0NN', 0)
            else
                call DisplayTimedTextToPlayer(p,0,0, 20, "You need 2500 crystals to buy this." )
            endif
        endif
    elseif itemid == 'I0ME' then //crystal to gold / platinum
		if udg_Crystals[pid] >= 1 then
            call AddCrystals(pid, -1)
            call AddPlayerGold(p, 500000)
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 1 crystal to buy this." )
		endif
    elseif itemid == 'I0MF' then //platinum to crystal
		if HasPlayerGold(pid, 0, 3) then
			call ChargePlayerGold(pid, 0, 3)
            call AddCrystals(pid, 1)
            call DisplayTimedTextToPlayer(p,0,0, 20, udg_CrystalTag + I2S(udg_Crystals[pid]) )
		else
			call DisplayTimedTextToPlayer(p,0,0, 20, "You need at least 3 platinum to buy this." )
		endif
    elseif itemid == 'I05T' then //Satans Abode
		if GetUnitLevel(Hero[pid]) < 250 then
			call DisplayTimedTextToPlayer(p,0,0, 15, "This item requires level 250 to use." )
        else
            call BuyHome(u, 2, 1, 'I001')
		endif
	elseif itemid == 'I069' then //Demon Nation
        if GetUnitLevel(Hero[pid]) < 280 then
			call DisplayTimedTextToPlayer(p,0,0, 15, "This item requires level 280 to use." )
        else
            call BuyHome(u, 4, 2, 'I068')
		endif
    elseif itemid == 'I0JS' then //Recharge Reincarnation
        set itm = GetResurrectionItem(pid, true)
        if itm != null then
            if GetItemCharges(itm) >= 3 then
                set itm = null
            endif
        endif
        if itm == null then
            call DisplayTimedTextToPlayer(p,0,0,15, "You have no item to recharge!")
        elseif TimerGetRemaining(rezretimer[pid]) > 1 then
            call DisplayTimedTextToPlayer(p,0,0,15, I2S(R2I(TimerGetRemaining(rezretimer[pid]))) +" seconds until you can recharge your " + GetItemName(itm))
        else
            if udg_Hardcore[pid] then
                call RechargeDialog(pid, GetItemTypeId(itm), 0.03)
            else
                call RechargeDialog(pid, GetItemTypeId(itm), 0.01)
            endif
        endif
        
    //========================
    //Sets / Crafting
    //========================
    
    elseif itemid == 'I0GS' then // Godslayer Set
		call ItemCreation_Item('I02B',1,'I02C',1,'I02O',1,'item',0,'item',0,'item',0,'I0JR',1,u,.2,.1,0, false)
		if GetItemTypeId(bj_lastCreatedItem)=='I0JR' then
			call SetItemCharges(bj_lastCreatedItem,2)
		endif
	elseif itemid == 'I09H' then // Omega Pick
		call ItemCreation_Item('I02Y',1,'I02X',1,'item',0,'item',0,'item',0,'item',0,'I043',1,u,0,0,0, false)
	elseif itemid == 'I04P' then // Cheese shield
		call ItemCreation_Item('I01Y',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I038',1,u,0,0,0, false)
		if GetItemTypeId(bj_lastCreatedItem)=='I038' then
			call SetItemCharges(bj_lastCreatedItem,150)
		endif
	elseif itemid == 'I08L' then // Shopkeeper necklace
		call ItemCreation_Item('I045',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I03E',1,u,0,0,0, false)
	elseif itemid == 'I0F6' then // Dragoon Set
		call ItemCreation_Item('I0EX',1,'I04N',1,'I0EY',1,'item',0,'item',0,'item',0,'I0F4',1,u,.1,.1,0, false)
	elseif itemid == 'I0F7' then // Forgotten Mystic Set
		call ItemCreation_Item('I03U',1,'I07F',1,'I0F3',1,'item',0,'item',0,'item',0,'I0F5',1,u,.1,.1,0, false)
	elseif itemid == 'I04K' then // Aura of Gods
		call ItemCreation_Item('I030',1,'I04I',1,'I031',1,'I02Z',1,'item',0,'item',0,'I04J',1,u,.4,.2,0, false)
	elseif itemid == 'I088' then // golem fist
        call ItemCreation_Item('I02Q',6,'item',0,'item',0,'item',0,'item',0,'item',0,'I046',1,u,0.075,0,0, false)
    elseif itemid == 'I08T' then // dwarven set
		call ItemCreation_Item('I079',1,'I07B',1,'I0FC',1,'item',0,'item',0,'item',0,'I08K',1,u,.1,.1,0, false)
    //Ursine
	elseif itemid == 'I0GK' then // sword
		call ItemCreation_Item('I035',2,'I06T',3,'I034',1,'item',0,'item',0,'item',0,'I0H5',1,u,.002,0,0, false)
	elseif itemid == 'I0GL' then // heavy
		call ItemCreation_Item('I0FQ',3,'I034',2,'I035',1,'item',0,'item',0,'item',0,'I0H6',1,u,.002,0,0, false)
	elseif itemid == 'I0GM' then // dagger
		call ItemCreation_Item('I0FO',3,'I0FG',3,'item',0,'item',0,'item',0,'item',0,'I0H7',1,u,.002,0,0, false)
	elseif itemid == 'I0GN' then // bow
		call ItemCreation_Item('I0FO',3,'I06R',3,'item',0,'item',0,'item',0,'item',0,'I0H8',1,u,.002,0,0, false)
	elseif itemid == 'I0GO' then // staff
		call ItemCreation_Item('I07O',3,'I0FT',3,'item',0,'item',0,'item',0,'item',0,'I0H9',1,u,.002,0,0, false)
    //Ogre
	elseif itemid == 'I0GP' then // sword
		call ItemCreation_Item('I0FD',2,'I08B',3,'I08I',1,'item',0,'item',0,'item',0,'I0HA',1,u,.01,0,0, false)
	elseif itemid == 'I0GQ' then // heavy
		call ItemCreation_Item('I08R',3,'I08I',2,'I0FD',1,'item',0,'item',0,'item',0,'I0HB',1,u,.01,0,0, false)
	elseif itemid == 'I0GR' then // dagger
		call ItemCreation_Item('I07Y',3,'I08F',3,'item',0,'item',0,'item',0,'item',0,'I0HC',1,u,.01,0,0, false)
	elseif itemid == 'I0GT' then // bow
		call ItemCreation_Item('I07Y',3,'I08E',3,'item',0,'item',0,'item',0,'item',0,'I0HD',1,u,.01,0,0, false)
	elseif itemid == 'I0GU' then // staff
		call ItemCreation_Item('I07W',3,'I0FE',3,'item',0,'item',0,'item',0,'item',0,'I0HE',1,u,.01,0,0, false)
    //Unbroken
	elseif itemid == 'I0GV' then // sword
		call ItemCreation_Item('I01W',2,'srbd',3,'ram1',1,'item',0,'item',0,'item',0,'I0HF',1,u,.03,0,0, false)
	elseif itemid == 'I0GW' then // heavy
		call ItemCreation_Item('I0FS',3,'ram1',2,'I01W',1,'item',0,'item',0,'item',0,'I0HG',1,u,.03,0,0, false)
	elseif itemid == 'I0GX' then // dagger
		call ItemCreation_Item('I0FY',3,'horl',3,'item',0,'item',0,'item',0,'item',0,'I0HH',1,u,.03,0,0, false)
	elseif itemid == 'I0GY' then // bow
		call ItemCreation_Item('I0FY',3,'ram2',3,'item',0,'item',0,'item',0,'item',0,'I0HI',1,u,.03,0,0, false)
	elseif itemid == 'I0GZ' then // staff
		call ItemCreation_Item('I0FR',3,'ram4',3,'item',0,'item',0,'item',0,'item',0,'I0HJ',1,u,.03,0,0, false)
    //Magnataur
	elseif itemid == 'I0H0' then // sword
		call ItemCreation_Item('sor9',2,'phlt',3,'dthb',1,'item',0,'item',0,'item',0,'I0HK',1,u,.1,0,0, false)
	elseif itemid == 'I0H1' then // heavy
		call ItemCreation_Item('shcw',3,'dthb',2,'sor9',1,'item',0,'item',0,'item',0,'I0HL',1,u,.1,0,0, false)
	elseif itemid == 'I0H2' then // dagger
		call ItemCreation_Item('shrs',3,'engs',3,'item',0,'item',0,'item',0,'item',0,'I0HM',1,u,.1,0,0, false)
	elseif itemid == 'I0H3' then // bow
		call ItemCreation_Item('shrs',3,'kygh',3,'item',0,'item',0,'item',0,'item',0,'I0HN',1,u,.1,0,0, false)
	elseif itemid == 'I0H4' then // staff
		call ItemCreation_Item('sor4',3,'bzbf',3,'item',0,'item',0,'item',0,'item',0,'I0HO',1,u,.1,0,0, false)
    //Demon
    elseif itemid == 'I0CM' then //plate
        // 2x demonic plate, 3x domonic sword,  demonic long sword
		call ItemCreation_Item('I073',2,'I06S',3,'I04T',1,'item',0,'item',0,'item',0,'I0CK',1,u,0.25,0.125,0, false)
	elseif itemid == 'I0CJ' then //fullplate
        // 3x demonic fullplate, 2 x demonic long sword, 1x demonic plate
		call ItemCreation_Item('I075',3,'I04T',2,'I073',1,'item',0,'item',0,'item',0,'I0BN',1,u,0.25,0.125,0, false)
	elseif itemid == 'I0CO' then //dagger
		call ItemCreation_Item('I06U',3,'I06Z',3,'item',0,'item',0,'item',0,'item',0,'I0BO',1,u,0.25,0.125,0, false)
	elseif itemid == 'I0DI' then //bow
		call ItemCreation_Item('I06O',3,'I06Z',3,'item',0,'item',0,'item',0,'item',0,'I0CU',1,u,0.25,0.125,0, false)
	elseif itemid == 'I0CN' then //wand
		call ItemCreation_Item('I06Q',3,'I06W',3,'item',0,'item',0,'item',0,'item',0,'I0CT',1,u,0.25,0.125,0, false)
    //horror
	elseif itemid == 'I0DM' then //plate
		call ItemCreation_Item('I07E',2,'I07M',3,'I07A',2,'item',0,'item',0,'item',0,'I0CV',1,u,0.5,0.25,0, false)
	elseif itemid == 'I0CS' then //fullplate
		call ItemCreation_Item('I07I',3,'I07A',2,'I05D',1,'I07E',1,'item',0,'item',0,'I0C2',1,u,0.5,0.25,0, false)
	elseif itemid == 'I0CP' then //dagger
		call ItemCreation_Item('I07L',3,'I07G',3,'I07K',1,'item',0,'item',0,'item',0,'I0C1',1,u,0.5,0.25,0, false)
	elseif itemid == 'I0CQ' then //bow
		call ItemCreation_Item('I07P',3,'I07G',3,'I07K',1,'item',0,'item',0,'item',0,'I0CW',1,u,0.5,0.25,0, false)
	elseif itemid == 'I0CR' then //wand
		call ItemCreation_Item('I077',3,'I07C',3,'I07K',1,'item',0,'item',0,'item',0,'I0CX',1,u,0.5,0.25,0, false)
    //despair
	elseif itemid == 'I0DP' then // sword
    	call ItemCreation_Item('I087',2,'I07V',3,'I07X',1,'item',0,'item',0,'item',0,'I0CY',1,u,1.5,0.75,1, false)
	elseif itemid == 'I0DO' then // heavy
		call ItemCreation_Item('I089',3,'I07X',2,'I087',1,'item',0,'item',0,'item',0,'I0BQ',1,u,1.5,0.75,1, false)
	elseif itemid == 'I0DR' then // dagger
		call ItemCreation_Item('I07Z',3,'I083',3,'item',0,'item',0,'item',0,'item',0,'I0BP',1,u,1.5,0.75,1, false)
	elseif itemid == 'I0DQ' then // bow
		call ItemCreation_Item('I07R',3,'I083',3,'item',0,'item',0,'item',0,'item',0,'I0CZ',1,u,1.5,0.75,1, false)
	elseif itemid == 'I0DN' then // staff
		call ItemCreation_Item('I07T',3,'I081',3,'item',0,'item',0,'item',0,'item',0,'I0D3',1,u,1.5,0.75,1, false)
    //Abyssal
	elseif itemid == 'I0G3' then // sword
        call ItemCreation_Item('I09X',2,'I06A',3,'I06D',1,'item',0,'item',0,'item',0,'I0C9',1,u,3,1.5,2, false)
	elseif itemid == 'I0G4' then // heavy
        call ItemCreation_Item('I0A0',3,'I06D',2,'I09X',1,'item',0,'item',0,'item',0,'I0C8',1,u,3,1.5,2, false)
	elseif itemid == 'I0G5' then // dagger
        call ItemCreation_Item('I0A2',3,'I06B',3,'item',0,'item',0,'item',0,'item',0,'I0C7',1,u,3,1.5,2, false)
	elseif itemid == 'I0G6' then // bow
        call ItemCreation_Item('I0A2',3,'I06C',3,'item',0,'item',0,'item',0,'item',0,'I0C6',1,u,3,1.5,2, false)
	elseif itemid == 'I0G0' then // staff
        call ItemCreation_Item('I0A5',3,'I09N',3,'item',0,'item',0,'item',0,'item',0,'I0C5',1,u,3,1.5,2, false)
    //void
	elseif itemid == 'I0DV' then // sword
        call ItemCreation_Item('I08S',2,'I08C',3,'I08D',1,'I055',1,'item',0,'item',0,'I0D7',1,u,6,3,3, false)
	elseif itemid == 'I0DU' then // heavy
        call ItemCreation_Item('I08U',3,'I08D',2,'I04W',1,'I08S',1,'item',0,'item',0,'I0C4',1,u,6,3,3, false)
	elseif itemid == 'I0DS' then // dagger
        call ItemCreation_Item('I08J',3,'I08O',3,'I055',1,'item',0,'item',0,'item',0,'I0C3',1,u,6,3,3, false)
	elseif itemid == 'I0DT' then // bow
        call ItemCreation_Item('I08H',3,'I08O',3,'I055',1,'item',0,'item',0,'item',0,'I0D5',1,u,6,3,3, false)
	elseif itemid == 'I0DW' then // staff
        call ItemCreation_Item('I08G',3,'I08M',3,'I04Y',1,'item',0,'item',0,'item',0,'I0D6',1,u,6,3,3, false)
    //Nightmare
	elseif itemid == 'I0G7' then // sword
        call ItemCreation_Item('I0A7',2,'I09P',4,'I09V',1,'item',0,'item',0,'item',0,'I0CB',1,u,10,6,6, false)
	elseif itemid == 'I0G8' then // heavy
        call ItemCreation_Item('I0A9',3,'I09V',3,'I0A7',1,'item',0,'item',0,'item',0,'I0CA',1,u,10,6,6, false)
	elseif itemid == 'I0G9' then // dagger
        call ItemCreation_Item('I0AC',3,'I09R',4,'item',0,'item',0,'item',0,'item',0,'I0CD',1,u,10,6,6, false)
	elseif itemid == 'I0GA' then // bow
        call ItemCreation_Item('I0AC',3,'I09S',4,'item',0,'item',0,'item',0,'item',0,'I0CE',1,u,10,6,6, false)
	elseif itemid == 'I0GB' then // staff
        call ItemCreation_Item('I0AB',3,'I09T',4,'item',0,'item',0,'item',0,'item',0,'I0CF',1,u,10,6,6, false)
    //hell
	elseif itemid == 'I0E5' then // sword
		call ItemCreation_Item('I097',2,'I05G',3,'I05I',1,'I08W',1,'item',0,'item',0,'I0D8',1,u,15,10,10, false)
	elseif itemid == 'I0E3' then // heavy
		call ItemCreation_Item('I05H',3,'I08W',3,'I05I',0,'I097',1,'item',0,'item',0,'I0BW',1,u,15,10,10, false)
	elseif itemid == 'I0E2' then // dagger
		call ItemCreation_Item('I098',3,'I08Z',3,'I05I',1,'item',0,'item',0,'item',0,'I0BU',1,u,15,10,10, false)
	elseif itemid == 'I0E4' then // bow
		call ItemCreation_Item('I098',3,'I091',3,'I05I',1,'item',0,'item',0,'item',0,'I0DK',1,u,15,10,10, false)
	elseif itemid == 'I0E6' then // staff
		call ItemCreation_Item('I095',3,'I093',4,'I05I',0,'item',0,'item',0,'item',0,'I0DJ',1,u,15,10,10, false)
    //exist
	elseif itemid == 'I0EA' then // sword
		call ItemCreation_Item('I09U',2,'I09K',4,'I09M',1,'item',0,'item',0,'item',0,'I0DX',1,u,25,15,15, false)
	elseif itemid == 'I0E9' then // heavy
		call ItemCreation_Item('I09W',3,'I09M',3,'I09U',1,'item',0,'item',0,'item',0,'I0BT',1,u,25,15,15, false)
	elseif itemid == 'I0E8' then // dagger
		call ItemCreation_Item('I09Q',3,'I09I',4,'item',0,'item',0,'item',0,'item',0,'I0BR',1,u,25,15,15, false)
	elseif itemid == 'I0E7' then // bow
		call ItemCreation_Item('I09Q',3,'I09G',4,'item',0,'item',0,'item',0,'item',0,'I0DL',1,u,25,15,15, false)
	elseif itemid == 'I0EB' then // staff
		call ItemCreation_Item('I09O',3,'I09E',4,'item',0,'item',0,'item',0,'item',0,'I0DY',1,u,25,15,15, false)
    //astral
	elseif itemid == 'I0EF' then // sword
		call ItemCreation_Item('I0AL',2,'I0A3',4,'I0A6',1,'item',0,'item',0,'item',0,'I0E0',1,u,45,30,30, false)
	elseif itemid == 'I0EE' then // heavy
		call ItemCreation_Item('I0AN',3,'I0A6',3,'I0AL',1,'item',0,'item',0,'item',0,'I0BM',1,u,45,30,30, false)
	elseif itemid == 'I0ED' then // dagger
		call ItemCreation_Item('I0AA',3,'I0A1',4,'item',0,'item',0,'item',0,'item',0,'I0DZ',1,u,45,30,30, false)
	elseif itemid == 'I0EC' then // bow
		call ItemCreation_Item('I0AA',3,'I0A4',4,'item',0,'item',0,'item',0,'item',0,'I059',1,u,45,30,30, false)
	elseif itemid == 'I0EG' then // staff
		call ItemCreation_Item('I0A8',3,'I09Z',4,'item',0,'item',0,'item',0,'item',0,'I0E1',1,u,45,30,30, false)
    //dimensional
	elseif itemid == 'I0GF' then // sword
		call ItemCreation_Item('I0AY',2,'I0AO',4,'I0AQ',1,'item',0,'item',0,'item',0,'I0CG',1,u,80,55,55, false)
	elseif itemid == 'I0GG' then // heavy
		call ItemCreation_Item('I0B0',3,'I0AQ',3,'I0AY',1,'item',0,'item',0,'item',0,'I0FH',1,u,80,55,55, false)
	elseif itemid == 'I0GH' then // dagger
		call ItemCreation_Item('I0B2',3,'I0AT',4,'item',0,'item',0,'item',0,'item',0,'I0CI',1,u,80,55,55, false)
	elseif itemid == 'I0GI' then // bow
		call ItemCreation_Item('I0B2',3,'I0AR',4,'item',0,'item',0,'item',0,'item',0,'I0FI',1,u,80,55,55, false)
	elseif itemid == 'I0GJ' then // staff
		call ItemCreation_Item('I0B3',3,'I0AW',4,'item',0,'item',0,'item',0,'item',0,'I0FZ',1,u,80,55,55, false)
    //misc
	elseif itemid == 'I08A' then // chaotic necklace
		call ItemCreation_Item('I04Z',6,'item',0,'item',0,'item',0,'item',0,'item',0,'I050',1,u,10,0,10, false)
    //dual proficiency
    elseif itemid == 'I08P' then //dragon armor
		call ItemCreation_Item('frhg' , 1 , 'drph' , 2 , 'item' , 0 , 'item' , 0 , 'item' , 0 , 'item' , 0 , 'I09B' , 1, u , 0 , 0 , 0, false)
	elseif itemid == 'I09B' then
		if dualprof(pid , 1) then
			call Trig_RewardDialog(pid , 1)
		else
			set i=1
			loop
				exitwhen i > 4
				if LoadBoolean(PlayerProf, pid, i) then
					call CreateHeroItem(Hero[pid], pid, LoadInteger(RewardItems, 1, i), 1)
				endif
				set i=i + 1
			endloop
		endif
	elseif itemid == 'I01P' then //dragon weapon
		call ItemCreation_Item('frhg' , 1 , 'fwss' , 2 , 'item' , 0 , 'item' , 0 , 'item' , 0 , 'item' , 0 , 'I09C' , 1, u , 0 , 0 , 0, false)
	elseif itemid == 'I09C' then
		if dualprof(pid , 2) then
			call Trig_RewardDialog(pid , 2)
		else
			set i=6
			loop
				exitwhen i > 10
				if LoadBoolean(PlayerProf, pid, i) then
					call CreateHeroItem(Hero[pid], pid, LoadInteger(RewardItems, 2, i), 1)
				endif
				set i=i + 1
			endloop
		endif
	elseif itemid == 'I08Q' then //Hydra Fang
		if HasItemType(u, 'bzbe') then
            set itm = GetItemFromUnit(u, 'bzbe')
			call UnitRemoveItem(u, itm)
			call RemoveItem(itm)
			if dualprof(pid,2) then
				call Trig_RewardDialog(pid, 3)
			else
				set i=6
				loop
					exitwhen i > 10
					if LoadBoolean(PlayerProf, pid, i) then
						call CreateHeroItem(Hero[pid], pid, LoadInteger(RewardItems, 3, i), 1)
					endif
					set i=i + 1
				endloop
			endif
		else
			call DisplayTextToPlayer(p, 0, 0, "Fang must be on your hero")
		endif
	elseif itemid == 'I0JQ' then //bloody equipment
		if HasItemType(u, 'I04Q') then
            set itm = GetItemFromUnit(u, 'I04Q')
            if HeartHits[pid] >= 1000 and HeartDealt[pid] >= 500000 then
                call UnitRemoveItem(u, itm)
                call RemoveItem(itm)
                set HeartHits[pid] = 0
                set HeartDealt[pid] = 0
                call Trig_RewardDialog(pid, 7)
            elseif HeartHits[pid] >= 1000 then
                call UnitRemoveItem(u, itm)
                call RemoveItem(itm)
                set HeartHits[pid] = 0
                set HeartDealt[pid] = 0
                call Trig_RewardDialog(pid, 6)
            elseif HeartDealt[pid] >= 500000 then
                call UnitRemoveItem(u, itm)
                call RemoveItem(itm)
                set HeartHits[pid] = 0
                set HeartDealt[pid] = 0
                call Trig_RewardDialog(pid, 5)
            else
                call DisplayTextToPlayer(p, 0, 0, "You are missing blood.")
            endif
		else
			call DisplayTextToPlayer(p, 0, 0, "Requires a bloody heart to forge.")
		endif
	elseif itemid == 'I04M' then //Spider armor
		if HasItemType(u, 'I01E') then
            set itm = GetItemFromUnit(u, 'I01E')
			call UnitRemoveItem(u, itm)
			call RemoveItem(itm)
			if dualprof(pid , 1) then
				call Trig_RewardDialog(pid , 4)
			else
				set i=1
				loop
					exitwhen i > 4
					if LoadBoolean(PlayerProf, pid, i) then
						call CreateHeroItem(Hero[pid], pid, LoadInteger(RewardItems, 4, i), 1)
					endif
					set i=i + 1
				endloop
			endif
		else
			call DisplayTextToPlayer(p, 0, 0, "Spider Carapace must be on your hero")
		endif
    
    //========================
    //Item Stacking
    //========================
    
    //shop items
    elseif itemid == 'pghe' or itemid == 'I028' or itemid == 'I0BJ' or itemid == 'pgma' or itemid == 'I0BL' or itemid == 'I00D' or itemid == 'I00K' then
        call StackItem(itm, u)
    //empty flask, dragon bone, dragon heart, dragon scale, dragon potion, blood potion
    elseif itemid == 'I0MO' or itemid == 'fwss' or itemid == 'frhg' or itemid == 'drph' or itemid == 'I0MP' or itemid == 'I0MQ' then
        call StackItem(itm, u)
    //keys
    elseif itemid == 'I040' or itemid == 'I041' or itemid == 'I042' then
        if ItemCreation_Item('I0M4',1,'I041',1,'item',0,'item',0,'item',0,'item',0,'I0M7',1,u,0,0,0, true) == true then
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r" )
        elseif ItemCreation_Item('I0M5',1,'I042',1,'item',0,'item',0,'item',0,'item',0,'I0M7',1,u,0,0,0, true) == true then
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r" )
        elseif ItemCreation_Item('I0M6',1,'I040',1,'item',0,'item',0,'item',0,'item',0,'I0M7',1,u,0,0,0, true) == true then
            call QuestMessageBJ(FORCE_PLAYING, bj_QUESTMESSAGE_REQUIREMENT, "  - |cff808080Retrieve the Key of the Gods (Completed)|r" )
        elseif ItemCreation_Item('I040',1,'I041',1,'item',0,'item',0,'item',0,'item',0,'I0M5',1,u,0,0,0, true) == true then
        elseif ItemCreation_Item('I041',1,'I042',1,'item',0,'item',0,'item',0,'item',0,'I0M6',1,u,0,0,0, true) == true then
        elseif ItemCreation_Item('I042',1,'I040',1,'item',0,'item',0,'item',0,'item',0,'I0M4',1,u,0,0,0, true) == true then
        endif
        
    //=====================================
    //Colosseum / Struggle / Training / PVP
    //=====================================

    elseif itemid == 'I0EV' or itemid == 'I0EU' or itemid == 'I0ET' or itemid == 'I0ES' or itemid == 'I0ER' or itemid == 'I0EQ' or itemid == 'I0EP' or itemid == 'I0EO' then
        if ColoPlayerCount > 0 then
            call DisplayTimedTextToPlayer(p,0,0, 5.00, "Colloseum is occupied!")
        else
            call GroupEnumUnitsInRect(ug, gg_rct_Colloseum_Enter, Condition(function ischar))
            
            if (itemid == 'I0EO') or (itemid == 'I0ES') then
				if udg_Chaos_World_On then
					set udg_Wave=103
				else
					set udg_Wave=0
				endif
			elseif ( itemid == 'I0EP' ) or ( itemid == 'I0ET' ) then
				if udg_Chaos_World_On then
					set udg_Wave=128
				else
					set udg_Wave=25
				endif
			elseif ( itemid == 'I0EQ' )or( itemid == 'I0EU' ) then
				if udg_Chaos_World_On then
					set udg_Wave=153
				else
					set udg_Wave=49
				endif
			elseif ( itemid == 'I0ER' )or( itemid == 'I0EV' ) then
				if udg_Chaos_World_On then
					set udg_Wave=182
				else
					set udg_Wave=73
				endif
			endif
            
            set index = 0
            
            if ( itemid == 'I0ER' or itemid == 'I0EQ' or itemid == 'I0EP' or itemid == 'I0EO' ) then // solo
                set index = 1
            elseif ( itemid == 'I0EV' or itemid == 'I0EU' or itemid == 'I0ET' or itemid == 'I0ES' ) then // team
                if BlzGroupGetSize(ug) > 1 then
                    set index = 2
                else
                    call DisplayTextToPlayer(p,0,0, "Atleast 2 players is required to play team survival.")
                endif
            endif
            
            if (itemid == 'I0ER' or itemid == 'I0EV') and udg_Chaos_World_On then
                set i2 = 350
            endif
            
            set levmin = 500
            set levmax = 0
            
            if index == 1 then
                //start colo solo
                if isteleporting[pid] == false then
                    set ColoPlayerCount = 1
                    set udg_Colosseum_Monster_Amount = 0
                    set ColoWaveCount = 0
                    set InColo[pid] = true
                    call GroupClear(ColoWaveGroup)
                    call SetUnitPositionLoc(Hero[pid], ColosseumCenter)
                    call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(Hero[pid]), gg_rct_Colloseum_Camera_Bounds)
                    call PanCameraToTimedLocForPlayer(GetOwningPlayer(Hero[pid]), ColosseumCenter, 0)
                    call ExperienceControl(pid)
                    call EnterWeather(Hero[pid])
                    call DisableItems(pid)
                    call TimerStart(NewTimer(), 2., false, function AdvanceColo)
                endif
            elseif index == 2 then
                set i = 1
                loop
                    exitwhen i > 8
                    if IsUnitInGroup(Hero[i], ug) then
                        set levmin = IMinBJ(GetHeroLevel(Hero[i]), levmin)
                        set levmax = IMaxBJ(GetHeroLevel(Hero[i]), levmax)
                    endif
                    set i = i + 1
                endloop
                if levmin < i2 then
                    set i = 1
                    loop
                        exitwhen i > 8
                        if IsUnitInGroup(Hero[i], ug) then
                            call DisplayTextToPlayer(Player(i-1),0,0, "All players need level |cffffcc00"+I2S(i2)+"|r to enter.")
                        endif
                        set i = i + 1
                    endloop
                elseif levmax - levmin > LEECH_CONSTANT then
                    set i = 1
                    loop
                        exitwhen i > 8
                        if IsUnitInGroup(Hero[i], ug) then
                            call DisplayTextToPlayer(Player(i-1),0,0, "Maximum level difference is |cffffcc0050|r levels.")
                        endif
                        set i = i + 1
                    endloop
                else
                    //start colo team
                    set ColoPlayerCount = 0
                    set udg_Colosseum_Monster_Amount = 0
                    set ColoWaveCount = 0
                    call GroupClear(ColoWaveGroup)
                    loop
                        set u = FirstOfGroup(ug)
                        exitwhen u == null
                        set pid = GetPlayerId(GetOwningPlayer(u)) + 1
                        call GroupRemoveUnit(ug, u)
                        if u == Hero[pid] and isteleporting[pid] == false then
                            set InColo[pid] = true
                            set ColoPlayerCount = ColoPlayerCount + 1
                            set udg_Fleeing[pid] = false
                            call SetUnitPositionLoc(u, ColosseumCenter)
                            call SetCameraBoundsRectForPlayerEx(GetOwningPlayer(u), gg_rct_Colloseum_Camera_Bounds)
                            call PanCameraToTimedLocForPlayer(GetOwningPlayer(u), ColosseumCenter, 0)
                            call EnterWeather(Hero[pid])
                            call ExperienceControl(pid)
                            call DisableItems(pid)
                        endif
                    endloop
                    call TimerStart(NewTimer(), 2., false, function AdvanceColo)
                endif
            endif
        endif
        
    elseif itemid == 'I0EW' or itemid == 'I00U' then //Struggle
        call GroupEnumUnitsInRect(ug, gg_rct_Colloseum_Enter, Condition(function ischar))

        if udg_Struggle_Pcount > 0 then
            call GroupClear(ug)
            call DisplayTextToPlayer(Player(pid-1),0,0, "Struggle is occupied." )
        elseif BlzGroupGetSize(ug) > 0 then
            set levmin = 500
            set levmax = 0

            set i = 1
            loop
                exitwhen i > 8
                if IsUnitInGroup(Hero[i], ug) then
                    set levmin = IMinBJ(GetHeroLevel(Hero[i]), levmin)
                    set levmax = IMaxBJ(GetHeroLevel(Hero[i]), levmax)
                endif
                set i = i + 1
            endloop
            if levmax - levmin > 80 then
                set i = 1
                loop
                    exitwhen i > 8
                    if IsUnitInGroup(Hero[i], ug) then
                        call DisplayTextToPlayer(Player(i-1),0,0, "Maximum level difference is |cffffcc0080|r levels.")
                    endif
                    set i = i + 1
                endloop
            else
                set udg_Struggle_Pcount = 0
                set udg_GoldWon_Struggle = 0
                loop //start struggle
                    set u = FirstOfGroup(ug)
                    exitwhen u == null
                    set pid = GetPlayerId(GetOwningPlayer(u)) + 1
                    call GroupRemoveUnit(ug, u)
                    if u == Hero[pid] and isteleporting[pid] == false then
                        set InStruggle[pid] = true
                        set udg_Struggle_Pcount = udg_Struggle_Pcount + 1
                        set udg_Fleeing[pid] = false
                        call DisableItems(pid)
                        call SetUnitPositionLoc( u, StruggleCenter )
                        call CreateUnitAtLoc(GetOwningPlayer(u), 'h065', StruggleCenter, bj_UNIT_FACING )
                        call SetCameraBoundsRectForPlayerEx( GetOwningPlayer(u), gg_rct_InfiniteStruggleCameraBounds )
                        call PanCameraToTimedLocForPlayer( GetOwningPlayer(u), StruggleCenter, 0 )
                        call ExperienceControl(pid)
                        call DisplayTimedTextToPlayer(GetOwningPlayer(u), 0, 0, 15., "You have 15 seconds to build before enemies spawn.")
                    endif
                endloop
                if itemid == 'I0EW' then //regular struggle
                    set udg_Struggle_WaveN = 0
                    if levmin > 120 then
                        set udg_Struggle_WaveN = 14
                    elseif levmin > 90 then
                        set udg_Struggle_WaveN = 11
                    elseif levmin > 60 then
                        set udg_Struggle_WaveN = 8
                    elseif levmin > 30 then
                        set udg_Struggle_WaveN = 5
                    endif
                    set udg_Struggle_WaveUCN = udg_Struggle_WaveUN[udg_Struggle_WaveN]
                else //chaos struggle
                    set udg_Struggle_WaveN = 28
                    set udg_Struggle_WaveUCN = udg_Struggle_WaveUN[udg_Struggle_WaveN]
                endif
                call GroupClear(StruggleWaveGroup)
                call TimerStart(NewTimerEx(1), 12., false, function AdvanceStruggle)
            endif
        endif
        
    elseif itemid == 'I0MT' then //Enter Training
        if GetHeroLevel(Hero[pid]) < 160 then //prechaos
            set x = GetRandomReal(GetRectMinX(gg_rct_PrechaosTraining), GetRectMaxX(gg_rct_PrechaosTraining))
            set y = GetRandomReal(GetRectMinY(gg_rct_PrechaosTraining), GetRectMaxY(gg_rct_PrechaosTraining))
            call SetCameraBoundsRectForPlayerEx(p, gg_rct_PrechaosTraining)
            
            if GetLocalPlayer() == p then
                call PanCameraToTimed(GetRectCenterX(gg_rct_PrechaosTraining), GetRectCenterY(gg_rct_PrechaosTraining), 0)
                call ClearSelection()
                call SelectUnit(Hero[pid], true)
            endif
        else //chaos
            set x = GetRandomReal(GetRectMinX(gg_rct_ChaosTraining), GetRectMaxX(gg_rct_ChaosTraining))
            set y = GetRandomReal(GetRectMinY(gg_rct_ChaosTraining), GetRectMaxY(gg_rct_ChaosTraining))
            call SetCameraBoundsRectForPlayerEx(p, gg_rct_ChaosTraining)
            
            if GetLocalPlayer() == p then
                call PanCameraToTimed(GetRectCenterX(gg_rct_ChaosTraining), GetRectCenterY(gg_rct_ChaosTraining), 0)
                call ClearSelection()
                call SelectUnit(Hero[pid], true)
            endif
        endif
            
        call SetUnitPosition(Hero[pid], x, y)
    
    elseif itemid == 'I0MW' then //Exit Training
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            call GroupEnumUnitsInRect(ug, gg_rct_PrechaosTrainingSpawn, Condition(function ishostile))
            
            if FirstOfGroup(ug) == null then
                if GetLocalPlayer() == p then
                    call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
                    call PanCameraToTimed(500, -425, 0)
                    call ClearSelection()
                    call SelectUnit(Hero[pid], true)
                endif
                call SetUnitPosition(Hero[pid], 500, -425)
            else
                call DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            endif
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            call GroupEnumUnitsInRect(ug, gg_rct_ChaosTrainingSpawn, Condition(function ishostile))
            
            if FirstOfGroup(ug) == null then
                if GetLocalPlayer() == p then
                    call SetCameraBoundsRectForPlayerEx(p, gg_rct_Main_Map_Vision)
                    call PanCameraToTimed(500, -425, 0)
                    call ClearSelection()
                    call SelectUnit(Hero[pid], true)
                endif
                call SetUnitPosition(Hero[pid], 500, -425)
            else
                call DisplayTextToPlayer(p, 0, 0, "You must kill all enemies before leaving!")
            endif
        endif
        
    elseif itemid == 'I0MS' then //Training Prechaos
        call CreateUnit(pfoe, UnitData[0][TrainerSpawn], GetRandomReal(GetRectMinX(gg_rct_PrechaosTraining), GetRectMaxX(gg_rct_PrechaosTraining)), GetRandomReal(GetRectMinY(gg_rct_PrechaosTraining), GetRectMaxY(gg_rct_PrechaosTraining)), GetRandomReal(0,359))
        
    elseif itemid == 'I0MX' then //Training Chaos
        call CreateUnit(pfoe, UnitData[1][TrainerSpawnChaos], GetRandomReal(GetRectMinX(gg_rct_ChaosTraining), GetRectMaxX(gg_rct_ChaosTraining)), GetRandomReal(GetRectMinY(gg_rct_ChaosTraining), GetRectMaxY(gg_rct_ChaosTraining)), GetRandomReal(0,359))
        
    elseif itemid == 'I0MU' then //Increase Difficulty
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h001_0072, 'I0MY')
            set TrainerSpawn = TrainerSpawn + 1
            if UnitData[0][TrainerSpawn] == 0 then
                set TrainerSpawn = 0
            endif
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[0][TrainerSpawn]) + "|r")
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h000_0120, 'I0MZ')
            set TrainerSpawnChaos = TrainerSpawnChaos + 1
            if UnitData[1][TrainerSpawnChaos] == 0 then
                set TrainerSpawnChaos = 0
            endif
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[1][TrainerSpawnChaos]) + "|r")
        endif
        
    elseif itemid == 'I0MV' then //Decrease Difficulty
        if RectContainsCoords(gg_rct_PrechaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h001_0072, 'I0MY')
            set TrainerSpawn = TrainerSpawn - 1
            if TrainerSpawn < 0 then
                set TrainerSpawn = UnitData[10][0]
            endif
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[0][TrainerSpawn]) + "|r")
        elseif RectContainsCoords(gg_rct_ChaosTrainingSpawn, GetUnitX(u), GetUnitY(u)) then
            set itm = GetItemFromUnit(gg_unit_h000_0120, 'I0MZ')
            set TrainerSpawnChaos = TrainerSpawnChaos - 1
            if TrainerSpawnChaos < 0 then
                set TrainerSpawnChaos = UnitData[11][0]
            endif
            call BlzSetItemIconPath(itm, "|cffffcc00" + GetObjectName(UnitData[1][TrainerSpawnChaos]) + "|r")
        endif
    elseif itemid == 'PVPA' then //Enter PVP
        call DialogClear(PvpDialog[pid])
        call DialogSetMessage(PvpDialog[pid], "Choose an arena.")

        set PvpButton[pid * 8 + 1] = DialogAddButton(PvpDialog[pid], "Pandaren Forest [Duel]", 0)
        set PvpButton[pid * 8 + 2] = DialogAddButton(PvpDialog[pid], "Wastelands [FFA]", 1)
        set PvpButton[pid * 8 + 3] = DialogAddButton(PvpDialog[pid], "Ice Cavern [Duel]", 2)

        call DialogAddButton(PvpDialog[pid], "Cancel", 'C')
        call DialogDisplay(p, PvpDialog[pid], true)

    //========================
    //Add Bonus / Bind
    //========================
    
    elseif IsItemDud(itm) == false then
		set mod = ItemProfMod(itemid, pid)

        if u == Hero[pid] then //heroes
            //apply bonuses
            if dropflag[pid] == false then
                set x = GetWidgetLife(u)
                call UnitAddBonus(u, BONUS_ARMOR, R2I(mod * ItemData[itemid][StringHash("armor")]) )
                call UnitAddBonus(u, BONUS_DAMAGE, R2I(mod * ItemData[itemid][StringHash("damage")] * (1. + Dmg_mod[pid] * 0.01)) )
                call UnitAddBonus(u, BONUS_HERO_STR, R2I(mod * (ItemData[itemid][StringHash("str")] + ItemData[itemid][StringHash("stats")]) * (1. + Str_mod[pid] * 0.01)) )
                call UnitAddBonus(u, BONUS_HERO_AGI, R2I(mod * (ItemData[itemid][StringHash("agi")] + ItemData[itemid][StringHash("stats")]) * (1. + Agi_mod[pid] * 0.01)) )
                call UnitAddBonus(u, BONUS_HERO_INT, R2I(mod * (ItemData[itemid][StringHash("int")] + ItemData[itemid][StringHash("stats")]) * (1. + Int_mod[pid] * 0.01)) )
                call BlzSetUnitMaxHP(u, BlzGetUnitMaxHP(u) + R2I(mod * ItemData[itemid][StringHash("health")]))
                call SetWidgetLife(u, x)
                set ItemRegen[pid] = ItemRegen[pid] + ItemData[itemid][StringHash("regen")]
                set ItemSpelldef[pid] = ItemSpelldef[pid] * (1 - ItemData[itemid][StringHash("mr")] * 0.01)
                set ItemTotaldef[pid] = ItemTotaldef[pid] * (1 - ItemData[itemid][StringHash("dr")] * 0.01)
                call BlzSetUnitAttackCooldown(u, BlzGetUnitAttackCooldown(u, 0) / (1 + ItemData[itemid][StringHash("bat")] * 0.01), 0)
                set ItemEvasion[pid] = ItemEvasion[pid] + ItemData[itemid][StringHash("evasion")]
                set ItemMovespeed[pid] = ItemMovespeed[pid] + ItemData[itemid][StringHash("movespeed")]
                set ItemSpellboost[pid] = ItemSpellboost[pid] + ItemData[itemid][StringHash("spellboost")] * 0.01
                set ItemGoldRate[pid] = ItemGoldRate[pid] + ItemData[itemid][StringHash("gold")]
                    
                //profiency warning
                if GetUnitLevel(Hero[pid]) < 15 and mod < 1 then
                    call DisplayTimedTextToPlayer( p, 0, 0, 10, infostring[10])
                endif
            endif
        endif
    endif

    set dropflag[pid] = false
    
    call DestroyGroup(ug)
    
    set u = null
    set itm = null
    set itm2 = null
    set p = null
    set ug = null
endfunction

//===========================================================================
function ItemInit takes nothing returns nothing
    local trigger onpickup = CreateTrigger()
    local trigger ondrop = CreateTrigger()
    local trigger useitem = CreateTrigger()
    local trigger chooseitem = CreateTrigger()
    local trigger confirmitem = CreateTrigger()
    local trigger upgradespell = CreateTrigger()
    local trigger usediscount = CreateTrigger()
    local trigger reward = CreateTrigger()
    local trigger onsell = CreateTrigger()
    local trigger onpvp = CreateTrigger()
    local integer i = 0 
    local User u = User.first
    
    loop
        exitwhen u == User.NULL
        set i = u.id
        set rezretimer[i] = CreateTimer()
        set dChooseItem[i] = DialogCreate()
        set dUpgradeItem[i] = DialogCreate()
        set dUseDiscount[i] = DialogCreate()
        set dChooseReward[i] = DialogCreate()
        set dUpgradeSpell[i] = DialogCreate()
        set PvpDialog[i] = DialogCreate()
        call TriggerRegisterDialogEvent(chooseitem, dChooseItem[i])
        call TriggerRegisterDialogEvent(confirmitem, dUpgradeItem[i])
        call TriggerRegisterDialogEvent(usediscount, dUseDiscount[i])
        call TriggerRegisterDialogEvent(upgradespell, dUpgradeSpell[i])
        call TriggerRegisterDialogEvent(reward, dChooseReward[i])
        call TriggerRegisterDialogEvent(onpvp, PvpDialog[i])
        call TriggerRegisterPlayerUnitEvent(onpickup, u.toPlayer(), EVENT_PLAYER_UNIT_PICKUP_ITEM, function boolexp)
        call TriggerRegisterPlayerUnitEvent(ondrop, u.toPlayer(), EVENT_PLAYER_UNIT_DROP_ITEM, function boolexp)
        call TriggerRegisterPlayerUnitEvent(useitem, u.toPlayer(), EVENT_PLAYER_UNIT_USE_ITEM, function boolexp)
        set u = u.next
    endloop
    
    call TriggerRegisterUnitEvent(ondrop, ASHEN_VAT, EVENT_UNIT_DROP_ITEM)
    call TriggerRegisterPlayerUnitEvent(onsell, Player(PLAYER_NEUTRAL_PASSIVE), EVENT_PLAYER_UNIT_SELL_ITEM, function boolexp)
    
    call TriggerAddCondition(onpickup, Condition(function ItemFilter))
    call TriggerAddAction(onpickup, function onPickup)
    call TriggerAddAction(ondrop, function onDrop)
    call TriggerAddAction(useitem, function onUse)
    call TriggerAddAction(onsell, function onSell)
    
    call TriggerAddAction(chooseitem, function UpgradeItem)
    call TriggerAddAction(confirmitem, function UpgradeItemConfirm)
    call TriggerAddAction(usediscount, function UseDiscount)
    call TriggerAddAction(upgradespell, function SpellBox)
    call TriggerAddAction(reward, function CompleteDialog)
    
    call TriggerAddAction(onpvp, function EnterPVP)
    
    set onpickup = null
    set ondrop = null
    set useitem = null
    set chooseitem = null
    set confirmitem = null
    set upgradespell = null
    set usediscount = null 
    set reward = null
    set onsell = null
    set onpvp = null
endfunction

endlibrary
