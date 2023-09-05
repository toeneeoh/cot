library AshenVat requires Functions

globals
    private string DECON = "|c00808080Deconstruct:|r\n"
    private string RSRCH = "|cffffcc00Researching:|r\n"
    private string FUSE = "|c00008080Fuse:|r\n"
    private string ADD = " + "
    unit ASHEN_VAT
endglobals

private function HL takes string s returns string
    return "|c0080ff80" + s + "|r"
endfunction

private function DTP takes player p, real dur, string msg returns nothing
    call DisplayTimedTextToPlayer(p, 0, 0, dur, msg)
endfunction

private function PT takes integer id, integer num returns string
    local string s = GetObjectName(id)

    if num > 0 then
        return s + " x" + I2S(num)
    else
        return s
    endif
endfunction

function Trig_Ashen_Vat_Actions takes nothing returns nothing
    local unit u = GetSoldUnit()
    local unit u2 = GetBuyingUnit()
    local integer id = GetUnitTypeId(u)
    local item itm
    local integer itid
    local integer i = 0
    local boolean sfx = false
    local player p = GetOwningPlayer(u2)
    local real angle = 0.

    call RemoveUnit(u)

    if id == 'e01H' then //eject
        loop
            exitwhen i > 5
            set itm = UnitItemInSlot(ASHEN_VAT, i)
            call UnitRemoveItemFromSlot(ASHEN_VAT, i)
            set angle = i * bj_PI * 0.333
            call SetItemPosition(itm, GetUnitX(ASHEN_VAT) + 160 * Cos(angle) - 15, GetUnitY(ASHEN_VAT) + 150 * Sin(angle) + 15)
            set i = i + 1
        endloop
    elseif id == 'e01I' then //fuse
        loop
            exitwhen Recipe('I0MO',3,'I04X',1,'I056',1,'I05Z',1,'item',0,'item',0,'I0MP',3,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0MO',3,'I07K',2,'item',0,'item',0,'item',0,'item',0,'I0MQ',3,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //chaos shield
            exitwhen Recipe('I0BY',1,'I09Y',1,'I0OD',1,'I0AI',1,'I0AH',1,'I08N',1,'I01J',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //drum of war
            exitwhen Recipe('I04J',1,'I00G',1,'I00H',1,'I00I',1,'I06H',1,'item',0,'I0NJ',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //demon golem fist
            exitwhen Recipe('I04Q',1,'I046',1,'item',0,'item',0,'item',0,'item',0,'I0OF',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //absolute horror equipment
            exitwhen Recipe('I0N9',2,'I02U',1,'item',0,'item',0,'item',0,'item',0,'I0NA',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N8',2,'I033',1,'item',0,'item',0,'item',0,'item',0,'I0NB',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N7',2,'I032',1,'item',0,'item',0,'item',0,'item',0,'I0NC',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N7',2,'I02S',1,'item',0,'item',0,'item',0,'item',0,'I0ND',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N7',1,'I0N8',1,'I065',1,'item',0,'item',0,'item',0,'I0NE',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N8',2,'I0BZ',1,'item',0,'item',0,'item',0,'item',0,'I0NF',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N9',2,'I02P',1,'item',0,'item',0,'item',0,'item',0,'I0NI',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N9',2,'I048',1,'item',0,'item',0,'item',0,'item',0,'I0NG',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop
            exitwhen Recipe('I0N9',2,'I064',1,'item',0,'item',0,'item',0,'item',0,'I0NH',0,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        if sfx then
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Other\\Charm\\CharmTarget.mdl", GetUnitX(ASHEN_VAT) - 18, GetUnitY(ASHEN_VAT) - 22))
        endif
    elseif id == 'e01J' then //deconstruct
        loop //big hp pot
            exitwhen Recipe('I0BJ',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I0MO',3,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //medium hp pot
            exitwhen Recipe('I028',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I0MO',2,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //small hp pot
            exitwhen Recipe('I062',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I0MO',1,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //big mana pot
            exitwhen Recipe('I0BL',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I0MO',3,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //medium mana pot
            exitwhen Recipe('I00D',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I0MO',2,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        loop //small mana pot
            exitwhen Recipe('I06E',1,'item',0,'item',0,'item',0,'item',0,'item',0,'I0MO',1,ASHEN_VAT,0,0,0,true) == false
            set sfx = true
        endloop
        if sfx then
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Human\\Thunderclap\\ThunderClapCaster.mdl", GetUnitX(ASHEN_VAT) - 18, GetUnitY(ASHEN_VAT) - 22))
        endif
    elseif id == 'e01K' then //research
        loop
            exitwhen UnitItemInSlot(ASHEN_VAT, i) != null or i > 5
            set i = i + 1
        endloop
        set itm = UnitItemInSlot(ASHEN_VAT, i)
        set itid = GetItemTypeId(itm)
        if itm != null then
            call DTP(p, 60, RSRCH + GetObjectName(itid))
            call DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Items\\AIam\\AIamTarget.mdl", GetUnitX(ASHEN_VAT) - 18, GetUnitY(ASHEN_VAT) - 22))
        endif
        if itid == 'I0BJ' then //big hp pot
    call DTP(p, 60, DECON + PT('I0MO', 3))
    
        elseif itid == 'I028' then //medium hp pot
    call DTP(p, 60, DECON + PT('I0MO', 2))
    
        elseif itid == 'I062' then //small hp pot
    call DTP(p, 60, DECON + PT('I0MO', 0))
    
        elseif itid == 'I0BL' then //big mana pot
    call DTP(p, 60, DECON + PT('I0MO', 3))
    
        elseif itid == 'I00D' then //medium mana pot
    call DTP(p, 60, DECON + PT('I0MO', 2))
    
        elseif itid == 'I06E' then //small mana pot
    call DTP(p, 60, DECON + PT('I0MO', 0))
    
        elseif itid == 'I0MO' then //empty flask
    call DTP(p, 60, FUSE + HL(PT('I0MO', 3)) + ADD + PT('I04X', 0) + ADD + PT('I056', 0) + ADD + PT('I05Z', 0) + " = " + PT('I0MP', 3))
    call DTP(p, 60, HL(PT('I0MO', 3)) + ADD + PT('I07K', 2) + " = " + PT('I0MQ', 3))
    
        elseif itid == 'I04X' then //dragon bone
    call DTP(p, 60, FUSE + PT('I0MO', 3) + ADD + HL(PT('I04X', 0)) + ADD + PT('I056', 0) + ADD + PT('I05Z', 0) + " = " + PT('I0MP', 3))
    
        elseif itid == 'I056' then //dragon heart
    call DTP(p, 60, FUSE + PT('I0MO', 3) + ADD + PT('I04X', 0) + ADD + HL(PT('I056', 0)) + ADD + PT('I05Z', 0) + " = " + PT('I0MP', 3))
    
        elseif itid == 'I05Z' then //dragon scale
    call DTP(p, 60, FUSE + PT('I0MO', 3) + ADD + PT('I04X', 0) + ADD + PT('I056', 0) + ADD + HL(PT('I05Z', 0)) + " = " + PT('I0MP', 3))
    
        elseif itid == 'I07K' then //horror's blood
    call DTP(p, 60, FUSE + PT('I0MO', 3) + ADD + HL(PT('I07K', 2)) + " = " + PT('I0MQ', 3))
    
        elseif itid == 'I0MP' then //dragon potion
    call DTP(p, 60, FUSE + PT('I0MO', 3) + ADD + PT('I04X', 0) + ADD + PT('I056', 0) + ADD + HL(PT('I05Z', 0)) + " = " + HL(PT('I0MP', 3)))
    
        elseif itid == 'I0MQ' then //blood potion
    call DTP(p, 60, FUSE + PT('I0MO', 3) + ADD + PT('I07K', 2) + " = " + HL(PT('I0MQ', 3)))

        elseif itid == 'I0BY' then //existence soul
    call DTP(p, 60, FUSE + HL(PT('I0BY', 0)) + ADD + PT('I09Y', 0) + ADD + PT('I0OD', 0) + ADD + PT('I0AI', 0) + ADD + PT('I0AH', 0) + ADD + PT('I08N', 0) + " = " + PT('I01J', 0))

        elseif itid == 'I09Y' then //existence orb
    call DTP(p, 60, FUSE + PT('I0BY', 0) + ADD + HL(PT('I09Y', 0)) + ADD + PT('I0OD', 0) + ADD + PT('I0AI', 0) + ADD + PT('I0AH', 0) + ADD + PT('I08N', 0) + " = " + PT('I01J', 0))

        elseif itid == 'I0OD' then //satan's heart +2 
    call DTP(p, 60, FUSE + PT('I0BY', 0) + ADD + PT('I09Y', 0) + ADD + HL(PT('I0OD', 0)) + ADD + PT('I0AI', 0) + ADD + PT('I0AH', 0) + ADD + PT('I08N', 0) + " = " + PT('I01J', 0))

        elseif itid == 'I0AI' then //dark regeneration
    call DTP(p, 60, FUSE + PT('I0BY', 0) + ADD + PT('I09Y', 0) + ADD + PT('I0OD', 0) + ADD + HL(PT('I0AI', 0)) + ADD + PT('I0AH', 0) + ADD + PT('I08N', 0) + " = " + PT('I01J', 0))

        elseif itid == 'I0AH' then //dark health essence
    call DTP(p, 60, FUSE + PT('I0BY', 0) + ADD + PT('I09Y', 0) + ADD + PT('I0OD', 0) + ADD + PT('I0AI', 0) + ADD + HL(PT('I0AH', 0)) + ADD + PT('I08N', 0) + " = " + PT('I01J', 0))

        elseif itid == 'I08N' then //void shard
    call DTP(p, 60, FUSE + PT('I0BY', 0) + ADD + PT('I09Y', 0) + ADD + PT('I0OD', 0) + ADD + PT('I0AI', 0) + ADD + PT('I0AH', 0) + ADD + HL(PT('I08N', 0)) + " = " + PT('I01J', 0))

        elseif itid == 'I01J' then //chaos shield
    call DTP(p, 60, FUSE + PT('I0BY', 0) + ADD + PT('I09Y', 0) + ADD + PT('I0OD', 0) + ADD + PT('I0AI', 0) + ADD + PT('I0AH', 0) + ADD + PT('I08N', 0) + " = " + HL(PT('I01J', 0)))

        elseif itid == 'I0N8' then //absolute fang
    call DTP(p, 60, FUSE + HL(PT('I0N8', 2)) + ADD + PT('I033', 0) + " = " + PT('I0NB', 0))
    call DTP(p, 60, HL(PT('I0N8', 2)) + ADD + PT('I0BZ', 0) + " = " + PT('I0NF', 0))
    call DTP(p, 60, HL(PT('I0N8', 0)) + ADD + PT('I0N7', 0) + ADD + PT('I065', 0) + " = " + PT('I0NE', 0))
    
        elseif itid == 'I033' then //dragonfire heavy
    call DTP(p, 60, FUSE + PT('I0N8', 2) + ADD + HL(PT('I033', 0)) + " = " + PT('I0NB', 0))
    
        elseif itid == 'I0NB' then //absolute greatsword
    call DTP(p, 60, FUSE + PT('I0N8', 2) + ADD + PT('I033', 0) + " = " + HL(PT('I0NB', 0)))
    
        elseif itid == 'I0BZ' then //dragonfire sword
    call DTP(p, 60, FUSE + PT('I0N8', 2) + ADD + HL(PT('I0BZ', 0)) + " = " + PT('I0NF', 0))
    
        elseif itid == 'I0NF' then //absolute spatha
    call DTP(p, 60, FUSE + PT('I0N8', 2) + ADD + PT('I0BZ', 0) + " = " + HL(PT('I0NF', 0)))
    
        elseif itid == 'I0N7' then //absolute claws
    call DTP(p, 60, FUSE + HL(PT('I0N7', 2)) + ADD + PT('I032', 0) + " = " + PT('I0NC', 0))
    call DTP(p, 60, HL(PT('I0N7', 2)) + ADD + PT('I02S', 0) + " = " + PT('I0ND', 0))
    call DTP(p, 60, PT('I0N8', 0) + ADD + HL(PT('I0N7', 0)) + ADD + PT('I065', 0) + " = " + PT('I0NE', 0))
    
        elseif itid == 'I032' then //dragonfire bow
    call DTP(p, 60, FUSE + PT('I0N7', 2) + ADD + HL(PT('I032', 0)) + " = " + PT('I0NC', 0))
    
        elseif itid == 'I0NC' then //absolute longbow
    call DTP(p, 60, FUSE + PT('I0N7', 2) + ADD + PT('I032', 0) + " = " + HL(PT('I0NC', 0)))
    
        elseif itid == 'I02S' then //dragonfire dagger
    call DTP(p, 60, FUSE + PT('I0N7', 2) + ADD + HL(PT('I02S', 0)) + " = " + PT('I0ND', 0))
    
        elseif itid == 'I0ND' then //absolute scimitar
    call DTP(p, 60, FUSE + PT('I0N7', 2) + ADD + PT('I02S', 0) + " = " + HL(PT('I0ND', 0)))
    
        elseif itid == 'I065' then //dragonfire orb
    call DTP(p, 60, FUSE + PT('I0N8', 0) + ADD + PT('I0N7', 0) + ADD + HL(PT('I065', 0)) + " = " + PT('I0NE', 0))
    
        elseif itid == 'I0NE' then //absolute orb
    call DTP(p, 60, FUSE + PT('I0N8', 0) + ADD + PT('I0N7', 0) + ADD + PT('I065', 0) + " = " + HL(PT('I0NE', 0)))
    
        elseif itid == 'I0N9' then //absolute hide
    call DTP(p, 60, FUSE + HL(PT('I0N9', 2)) + ADD + PT('I02U', 0) + " = " + PT('I0NA', 0))
    call DTP(p, 60, HL(PT('I0N9', 2)) + ADD + PT('I02P', 0) + " = " + PT('I0NI', 0))
    call DTP(p, 60, HL(PT('I0N9', 2)) + ADD + PT('I048', 0) + " = " + PT('I0NG', 0))
    call DTP(p, 60, HL(PT('I0N9', 2)) + ADD + PT('I064', 0) + " = " + PT('I0NH', 0))
    
        elseif itid == 'I02U' then //dragonfire full plate
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + HL(PT('I02U', 0)) + " = " + PT('I0NA', 0))
    
        elseif itid == 'I02P' then //dragonfire cloth
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + HL(PT('I02P', 0)) + " = " + PT('I0NI', 0))
    
        elseif itid == 'I048' then //dragonfire plate
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + HL(PT('I048', 0)) + " = " + PT('I0NG', 0))
    
        elseif itid == 'I064' then //dragonfire leather
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + HL(PT('I064', 0)) + " = " + PT('I0NH', 0))
    
        elseif itid == 'I02U' then //absolute full plate
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + PT('I02U', 0) + " = " + HL(PT('I0NA', 0)))
    
        elseif itid == 'I02P' then //absolute cloth
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + PT('I02P', 0) + " = " + HL(PT('I0NI', 0)))
    
        elseif itid == 'I048' then //absolute plate
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + PT('I048', 0) + " = " + HL(PT('I0NG', 0)))
    
        elseif itid == 'I064' then //absolute leather
    call DTP(p, 60, FUSE + PT('I0N9', 2) + ADD + PT('I064', 0) + " = " + HL(PT('I0NH', 0)))
    
        elseif itid == 'I04J' then //aura of gods
    call DTP(p, 60, FUSE + HL(PT('I04J', 0)) + ADD + PT('I00G', 0) + ADD + PT('I00H', 0) + ADD + PT('I00I', 0) + ADD + PT('I06H', 0) + " = " + PT('I0NJ', 0))
    
        elseif itid == 'I00G' then //blood elf war drum
    call DTP(p, 60, FUSE + PT('I04J', 0) + ADD + HL(PT('I00G', 0)) + ADD + PT('I00H', 0) + ADD + PT('I00I', 0) + ADD + PT('I06H', 0) + " = " + PT('I0NJ', 0))
    
        elseif itid == 'I00H' then //blood horn
    call DTP(p, 60, FUSE + PT('I04J', 0) + ADD + PT('I00G', 0) + ADD + HL(PT('I00H', 0)) + ADD + PT('I00I', 0) + ADD + PT('I06H', 0) + " = " + PT('I0NJ', 0))
    
        elseif itid == 'I00I' then //blood shield
    call DTP(p, 60, FUSE + PT('I04J', 0) + ADD + PT('I00G', 0) + ADD + PT('I00H', 0) + ADD + HL(PT('I00I', 0)) + ADD + PT('I06H', 0) + " = " + PT('I0NJ', 0))
    
        elseif itid == 'I06H' then //warsong drum
    call DTP(p, 60, FUSE + PT('I04J', 0) + ADD + PT('I00G', 0) + ADD + PT('I00H', 0) + ADD + PT('I00I', 0) + ADD + HL(PT('I06H', 0)) + " = " + PT('I0NJ', 0))
    
        elseif itid == 'I0NJ' then //drum of war
    call DTP(p, 60, FUSE + PT('I04J', 0) + ADD + PT('I00G', 0) + ADD + PT('I00H', 0) + ADD + PT('I00I', 0) + ADD + PT('I06H', 0) + " = " + HL(PT('I0NJ', 0)))
    
        elseif itid == 'I04Q' then //heart of the demon prince
    call DTP(p, 60, FUSE + HL(PT('I04Q', 0)) + ADD + PT('I046', 0) + " = " + PT('I0OF', 0))

        elseif itid == 'I046' then //iron golem fist
    call DTP(p, 60, FUSE + PT('I04Q', 0) + ADD + HL(PT('I046', 0)) + " = " + PT('I0OF', 0))

        elseif itid == 'I0OF' then //demon golem fist
    call DTP(p, 60, FUSE + PT('I04Q', 0) + ADD + PT('I046', 0) + " = " + HL(PT('I0OF', 0)))

        else
    call DTP(p, 60, "No recipe discovered.")
        endif
    endif
    
    set u = null
    set itm = null
    set p = null
endfunction

//===========================================================================
function AshenVatInit takes nothing returns nothing
    local trigger ashen = CreateTrigger()

    call SetUnitPosition(ASHEN_VAT, 20478.027, -20244.473)
    call TriggerRegisterUnitEvent(ashen, ASHEN_VAT, EVENT_UNIT_SELL)
    call TriggerAddAction(ashen, function Trig_Ashen_Vat_Actions)

    set ashen = null
endfunction

endlibrary
