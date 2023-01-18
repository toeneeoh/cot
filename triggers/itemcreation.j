library ItemCreation requires Functions

function EnumUnitItems takes unit u returns integer
    local integer i = 0
    local item itm
    local integer count = 0
    
    loop
        exitwhen i > 5
        set itm = UnitItemInSlot(u, i)
        if GetItemTypeId(itm) > 0 then
            set count = count + 1
        endif
        set i = i + 1
    endloop
    
    set itm = null

    return count
endfunction

function unchargedremove takes unit u, item itm returns nothing
    if GetItemType(itm) == ITEM_TYPE_CHARGED and GetItemCharges(itm) > 1 then
        call SetItemCharges(itm, GetItemCharges(itm) - 1)
    else
        call UnitRemoveItem(u, itm)
        call SetItemPosition(itm, -25000, -25000)
    endif
endfunction

public function Item takes integer itid1, integer req1, integer itid2, integer req2, integer itid3, integer req3, integer itid4, integer req4, integer itid5, integer req5,integer itid6, integer req6, integer FINAL_ID, integer FINAL_CHARGES, unit creatingunit, real platCost, real arcCost, integer crystals, boolean hidemessage returns boolean
    local integer i = 0
    local integer i2 = 0
    local integer array itemsNeeded
    local integer array itemsHeld
    local integer array itemType
    local player owner = GetOwningPlayer(creatingunit)
    local integer pid = GetPlayerId(owner) + 1
    local boolean fail = false
    local integer levelreq = 0
    local integer cost
    local boolean success = false
    local item itm
    local integer array origcount 
    local integer origowner = 0
    local integer goldcost = R2I(ModuloReal(platCost, R2I(RMaxBJ(platCost, 1))) * 1000000)
    local integer lumbercost = R2I(ModuloReal(arcCost, R2I(RMaxBJ(arcCost, 1))) * 1000000)

    //call BJDebugMsg(I2S(itemsHeld[1]))
    
    set itemType[0] = itid1
    set itemType[1] = itid2
    set itemType[2] = itid3
    set itemType[3] = itid4
    set itemType[4] = itid5
    set itemType[5] = itid6
    set itemsNeeded[0] = req1
    set itemsNeeded[1] = req2
    set itemsNeeded[2] = req3
    set itemsNeeded[3] = req4
    set itemsNeeded[4] = req5
    set itemsNeeded[5] = req6
    
    loop
        exitwhen i > 5
        set i2 = 0
        loop
            exitwhen i2 > 5
            if creatingunit == gg_unit_h05J_0412 then //vat
                set itm = UnitItemInSlot(creatingunit, i2)
                if GetItemTypeId(itm) == 'I04Q' then //demon golem fist heart
                    if HeartDealt[GetItemUserData(itm)] < 500000 and HeartHits[GetItemUserData(itm)] < 1000 then
                        set itemsHeld[i] = itemsHeld[i] - 1
                    endif
                endif
                if GetItemTypeId(itm) == itemType[i] then
                    set origcount[GetItemUserData(itm)] = origcount[GetItemUserData(itm)] + 1
                    if GetItemCharges(itm) > 1 then
                        set itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        set itemsHeld[i] = itemsHeld[i] + 1
                    endif
                endif
            else
                set itm = UnitItemInSlot(Hero[pid], i2)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        set itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        set itemsHeld[i] = itemsHeld[i] + 1
                    endif
                endif
                set itm = UnitItemInSlot(Backpack[pid], i2)
                if GetItemTypeId(itm) == itemType[i] then
                    if GetItemCharges(itm) > 1 then
                        set itemsHeld[i] = itemsHeld[i] + GetItemCharges(itm)
                    else
                        set itemsHeld[i] = itemsHeld[i] + 1
                    endif
                endif
            endif
            
            set i2 = i2 + 1
        endloop
        set i = i + 1
    endloop

    set i = 0
    
    loop
        exitwhen i > 5
        if itemsHeld[i] < itemsNeeded[i] then
            set fail = true
            exitwhen true
        endif
        set i = i + 1
    endloop

    set i = 1

    loop //disallow multiple bound items
        exitwhen i > 6
        if origcount[i] > 0 then
            if origowner > 0 and origowner != i then
                set origowner = -1
                set fail = true
                exitwhen true
            endif
            set origowner = i
        endif
        set i = i + 1
    endloop
	
    if hidemessage then //mostly for ashen vat
        if fail then
            if origowner == -1 then
                call DisplayTextToForce(FORCE_PLAYING, "The Ashen Vat will not accept bound items from multiple players.")
            endif
        else
            set success = true
            set i = 0
            loop
                exitwhen i > 5
                set i2 = 0
                if itemType[i] > 0 then
                    loop
                        set i2 = i2 + 1
                        exitwhen i2 > itemsNeeded[i]
                        if creatingunit == gg_unit_h05J_0412 then
                            if HasItemType(creatingunit, itemType[i]) then
                                call unchargedremove(creatingunit, GetItemFromUnit(creatingunit, itemType[i]) )
                            endif
                        else
                            if HasItemType(Hero[pid], itemType[i]) then
                                call unchargedremove(Hero[pid], GetItemFromUnit(Hero[pid], itemType[i]) )
                            elseif HasItemType(Backpack[pid], itemType[i]) then
                                call unchargedremove(Backpack[pid], GetItemFromUnit(Backpack[pid], itemType[i]) )
                            endif
                        endif
                    endloop
                endif
                set i = i + 1
            endloop

            call CreateHeroItem(creatingunit, origowner, FINAL_ID, FINAL_CHARGES)
        endif
    else
        set levelreq = ItemData[FINAL_ID][StringHash("level")]

        if levelreq > GetUnitLevel(Hero[pid]) then
            call DisplayTimedTextToPlayer( owner,0,0, 15., "This item requires at least level |c00FF5555"+ I2S(levelreq) +"|r to use." )
        elseif HasPlayerGold(pid, R2I(goldcost), R2I(platCost)) == false then
            call DisplayTimedTextToPlayer( owner,0,0, 30, "You do not have enough gold." )
        elseif HasPlayerLumber(pid, R2I(lumbercost), R2I(arcCost)) == false then
            call DisplayTimedTextToPlayer( owner,0,0, 30, "You do not have enough lumber." )
        elseif udg_Crystals[pid] < crystals then
            call DisplayTimedTextToPlayer( owner,0,0, 30, "You do not have enough crystals." )
        elseif fail then
            call DisplayTimedTextToPlayer( owner,0,0, 30, "You do not have the required items." )
        else
            call DisplayTimedTextToPlayer( owner,0,0, 30, "|cff00cc00Success!|r" )
            set success = true
            set i = 0
            loop
                exitwhen i > 5
                set i2 = 0
                if itemType[i] > 0 then
                    loop
                        set i2 = i2 + 1
                        exitwhen i2 > itemsNeeded[i]
                        if HasItemType(Hero[pid], itemType[i]) then
                            call unchargedremove(Hero[pid], GetItemFromUnit(Hero[pid], itemType[i]) )
                        elseif HasItemType(Backpack[pid], itemType[i]) then
                            call unchargedremove(Backpack[pid], GetItemFromUnit(Backpack[pid], itemType[i]) )
                        endif
                    endloop
                endif
                set i = i + 1
            endloop

			if EnumUnitItems(Hero[pid]) < 6 then
                call CreateHeroItem(Hero[pid], pid, FINAL_ID, FINAL_CHARGES)
            else
                call CreateHeroItem(Backpack[pid], pid, FINAL_ID, FINAL_CHARGES)
            endif
			
			call ChargePlayerGold(pid, R2I(goldcost), R2I(platCost))
            call ChargePlayerLumber(pid, R2I(lumbercost), R2I(arcCost))
            call AddCrystals(pid, -(crystals))
        endif
    endif
    
    set owner = null
    set itm = null
    return success
endfunction

endlibrary
