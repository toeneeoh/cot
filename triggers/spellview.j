library TasSpellView initializer init_function requires Functions optional Ascii
// TasSpellView 1.1a by Tasyen
//displays with custom UI the abilites of not controled units in the command card

// when REFORGED = false you need to tell the abilityCodes used by units to have cooldown display
// the unit does not need to have the skills they are displayed when added that way.
// call AddUnitCodeData('Ulic', "AUfn,AUfu,AUdr,AUdd")

    globals
        constant boolean REFORGED = true // have BlzGetAbilityId? otherwise false
        public boolean AutoRun = true //(true) will create Itself at 0s, (false) you need to InitSpellView()
        public string TocPath = "war3mapImported\\TasSpellView.toc"

        public real UpdateTime = 0.1
        public boolean ShowCooldown = true // can be set async, needs BlzGetAbilityId for ability by index 

        //ToolTip
        public real ToolTipSizeX = 0.26
        public real ToolTipPosX = 0.79
        public real ToolTipPosY = 0.165
        public framepointtype ToolTipPos = FRAMEPOINT_BOTTOMRIGHT

// currentSelected
        public integer DataCount = -1
        public integer DataMod = 0
        public integer array DataAbiCode
        public integer array DataMana
        public real array DataRange        
        public real array DataAoe
        public real array DataCool
        public string array DataName
        public string array DataText
        public string array DataIcon


        public framehandle ParentSimple
        public framehandle Parent
        public timer Timer

        public unit LastUnit = null
        public group SPELL_VIEW_GROUP

        public integer MOD_ABI = 1
        public integer MOD_ABI_CODE = 0

        public string array UnitCodeText
        public integer array UnitCodeType
        public integer UnitCodeCount = 0
    endglobals

    public function ParentFuncSimple takes nothing returns framehandle
        return BlzGetFrameByName("ConsoleUI", 0)
    endfunction
    public function ParentFunc takes nothing returns framehandle
        return BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0) 
    endfunction

    public function AbiFilter takes ability abi, string text, integer pid returns boolean
        local integer id = BlzGetAbilityId(abi)

        if BlzGetAbilityBooleanField(abi, ABILITY_BF_ITEM_ABILITY) then
            return false
        endif
        if BlzGetAbilityIntegerField(abi, ABILITY_IF_BUTTON_POSITION_NORMAL_X) == 0 and BlzGetAbilityIntegerField(abi, ABILITY_IF_BUTTON_POSITION_NORMAL_Y) == -11 then
            return false
        endif
        if text == "Tool tip missing!" or text == "" or text == " " then
            return false
        endif
        //backpack utilities
        if id == DETECT_LEAVE_ABILITY or id == 0 or id == 'A04M' or id == 'A00R' or id == 'A0DT' or id == 'A0KX' or id == 'A04N' or id == 'A03V' or id == 'A0L0' then
            return false
        endif
        //hero utilities
        if id == 'A0GD' or id == 'A06X' or id == 'A08Y' or id == 'A00B' or id == 'A02T' or id == 'A031' or id == 'A067' or id == 'A03C' or id == 'A00F' then
            return false
        endif
        //dummy spells
        if id == 'A06K' or id == 'A033' or id == 'A0AP' or id == 'A0A3' or id == 'A0IW' or id == 'A0IX' or id == 'A0IY' or id == 'A0IZ' then
            return false
        endif
        if id == 'A0JZ' or id == 'A0JV' or id == 'A0JY' or id == 'A0JW' or id == 'A00N' or id == 'A01A' or id == 'A09X' or id == 'A024' then
            return false
        endif
        return true
    endfunction
    
    public function AddUnitCodeData takes integer unitCode, string abiCodeString returns nothing        
        set UnitCodeCount = UnitCodeCount + 1
        set UnitCodeType[UnitCodeCount] = unitCode
        set UnitCodeText[UnitCodeCount] = abiCodeString
    endfunction
    
    public function GetUnitCodeData takes integer unitCode returns string
        local integer i = UnitCodeCount
        loop            
            exitwhen i <= 0
            if unitCode == UnitCodeType[i] then
                return UnitCodeText[i]
            endif
            set i = i - 1
        endloop
        return ""
    endfunction

static if LIBRARY_Ascii then
    public function AddSpellString takes string abiString returns nothing
        local integer startIndex = 0
        local integer skillCode
        local integer addCount = 0
        loop
        exitwhen startIndex + 3 >= StringLength(abiString)
            set skillCode = S2A(SubString(abiString, startIndex, startIndex + 4))
            set startIndex = startIndex + 5
            set DataAbiCode[addCount] = skillCode
            set addCount = addCount + 1
        endloop
        set DataCount = addCount - 1
    endfunction
endif

    public function GetUnitData takes unit u returns nothing
        local integer i = 0
        local integer addCount = 0
        local ability abi
        local string abiString
        local integer pid = GetPlayerId(GetOwningPlayer(u)) + 1
        local integer sid
        local Spell spell
        set DataCount = -1

        // have presaved Data
        set abiString = GetUnitCodeData(GetUnitTypeId(u))
        if abiString != "" then
            static if LIBRARY_Ascii then
                call AddSpellString(abiString)                
            endif
            set DataMod = MOD_ABI_CODE
        else
            set DataMod = MOD_ABI
            static if REFORGED then
                // store abiCode treat it like MOD_ABI_CODE
                set DataMod = MOD_ABI_CODE
            endif
            set i = 0
            set addCount = 0
            loop        
                set abi = BlzGetUnitAbilityByIndex(u, i)
                exitwhen abi == null
                if AbiFilter(abi, BlzGetAbilityStringLevelField(abi, ABILITY_SLF_TOOLTIP_NORMAL, 0), pid) then                    
                    static if REFORGED then
                        // store abiCode treat it like MOD_ABI_CODE
                        set DataAbiCode[addCount] = BlzGetAbilityId(abi)
                    else
                        // store the data
                        set DataIcon[addCount] = BlzGetAbilityStringLevelField(abi, ABILITY_SLF_ICON_NORMAL, 0)
                        set DataName[addCount] = BlzGetAbilityStringLevelField(abi, ABILITY_SLF_TOOLTIP_NORMAL, 0)
                        set DataText[addCount] = BlzGetAbilityStringLevelField(abi, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, 0)
                        set DataMana[addCount] = BlzGetAbilityIntegerLevelField(abi, ABILITY_ILF_MANA_COST, 0)
                        set DataCool[addCount] = BlzGetAbilityRealLevelField(abi, ABILITY_RLF_COOLDOWN, 0)
                        set DataRange[addCount] = BlzGetAbilityRealLevelField(abi, ABILITY_RLF_CAST_RANGE, 0)
                        set DataAoe[addCount] = BlzGetAbilityRealLevelField(abi, ABILITY_RLF_AREA_OF_EFFECT, 0)
                    endif
                    
                    set addCount = addCount + 1
                endif
                set i = i + 1
            endloop
            set DataCount = addCount - 1
            set abi = null
        endif
    endfunction

    public function Update takes nothing returns nothing
        local boolean foundTooltip = false
        local unit u
        local boolean hasControl
        local boolean showSpellView
        local integer i
        local integer level
        local real cdRemain
        local real cdTotal
        local integer abiCode
        local ability abi
        local Spell spell
        local integer spelldata

        call GroupEnumUnitsSelected(SPELL_VIEW_GROUP, GetLocalPlayer(), null)
        set u = FirstOfGroup(SPELL_VIEW_GROUP)
        call GroupClear(SPELL_VIEW_GROUP)

        if u != LastUnit then
            set LastUnit = u
            call GetUnitData(u)
        endif

        set hasControl = IsUnitOwnedByPlayer(u, GetLocalPlayer()) or GetPlayerAlliance(GetOwningPlayer(u), GetLocalPlayer(), ALLIANCE_SHARED_CONTROL)

        // check for visible buttons, if any is visible then do not show TasSpellView
        if not hasControl then
            set i = 0
            loop
                if BlzFrameIsVisible(BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, i)) then
                    set hasControl = true
                    exitwhen true
                endif
                exitwhen i == 11
                set i = i + 1
            endloop
        endif

        set showSpellView = not hasControl
        /*if GetHandleId(BlzGetFrameByName("SimpleReplayPanel", 0)) > 0 or GetHandleId(BlzGetFrameByName("SimpleReplayPanelV1", 0)) > 0 then
            set showSpellView = false
        endif*/
        call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewSimpleFrame", 0), showSpellView)
        call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewFrame", 0), showSpellView)
        if showSpellView then
            set i = 0
            loop                
                if i <= DataCount then 
                    call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButton", i), true)
                    if DataMod == MOD_ABI then
                        call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                        call BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewButtonBackdrop", i), DataIcon[i], 0, false)
                        call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i), false)
                    elseif DataMod == MOD_ABI_CODE then
                        set abiCode = DataAbiCode[i]
                        set level = GetUnitAbilityLevel(u, abiCode)

                        if ShowCooldown then
                            set cdRemain = BlzGetUnitAbilityCooldownRemaining(u, abiCode)
                            if cdRemain > 0 then
                                // this be inaccurate when the map has systems to change cooldowns only during the casting.
                                set cdTotal = BlzGetUnitAbilityCooldown(u, abiCode, level - 1)
                                //print(GetObjectName(data[i]),cdRemain,cdTotal, cdRemain/cdTotal)
                                call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), true)
                                call BlzFrameSetValue(BlzGetFrameByName("TasSpellViewButtonCooldown", i), 100-(cdRemain/cdTotal)*100)
                                //print(BlzFrameIsVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i)), BlzFrameGetValue(BlzGetFrameByName("TasSpellViewButtonCooldown", i)))
                            else
                                call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                            endif
                        else
                            call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                        endif
                        
                        call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i), true)
                        call BlzFrameSetText(BlzGetFrameByName("TasSpellViewButtonChargeText", i), I2S(level))
                        call BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewButtonBackdrop", i), BlzGetAbilityIcon(abiCode), 0, false)
                    endif
                else
                    call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                    call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButton", i), false)
                endif

                // hovered?
                if BlzFrameIsVisible(BlzGetFrameByName("TasSpellViewButtonToolTip", i)) then
                    set foundTooltip = true
                    if DataMod == MOD_ABI then
                        call BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewTooltipIcon", 0), DataIcon[i], 0, false)
                        call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipName", 0), "|cffffcc00" + DataName[i])
                        call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), DataText[i])
                        call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), I2S(DataMana[i]))
                        call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0), R2SW(DataCool[i],1,1))
                        call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipRangeText", 0), I2S(R2I(DataRange[i])))
                        call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), I2S(R2I(DataAoe[i])))
                    elseif DataMod == MOD_ABI_CODE then
                        set abiCode = DataAbiCode[i]
                        set level = GetUnitAbilityLevel(u, DataAbiCode[i])
                        set abi = BlzGetUnitAbility(u, abiCode)

                        set spelldata = LoadInteger(SAVE_TABLE, KEY_SPELLS, abiCode)

                        if spelldata != 0 then
                            set spell = Spell.create(spelldata)
                            call spell.setValues(GetPlayerId(GetOwningPlayer(u)) + 1)

                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), SpellTooltips[abiCode].string[spell.ablev])

                            call spell.destroy()
                        else
                            if level > 0 then
                                call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), BlzGetAbilityExtendedTooltip(abiCode, level - 1))
                            else
                                call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), BlzGetAbilityResearchExtendedTooltip(abiCode, 0))
                            endif
                        endif

                        call BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewTooltipIcon", 0), BlzGetAbilityIcon(abiCode), 0, false)
                        if level > 0 then                                
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), I2S(BlzGetUnitAbilityManaCost(u, abiCode, level - 1)))
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0), R2SW(BlzGetUnitAbilityCooldown(u, abiCode, level - 1),1,1))
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipRangeText", 0), I2S(R2I(BlzGetAbilityRealLevelField(abi, ABILITY_RLF_CAST_RANGE, level - 1))))
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), I2S(R2I(BlzGetAbilityRealLevelField(abi, ABILITY_RLF_AREA_OF_EFFECT, level - 1))))
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipName", 0), "|cffffcc00" + BlzGetAbilityTooltip(abiCode, level - 1))
                        else
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipName", 0), "|cffffcc00" + BlzGetAbilityResearchTooltip(abiCode, 0))
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), I2S(BlzGetAbilityManaCost(abiCode, 0)))
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0), R2SW(BlzGetAbilityCooldown(abiCode, 0),1,1))
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipRangeText", 0), "0")
                            call BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), "0")
                        endif
                    endif
                endif
                exitwhen i == 11
                set i = i + 1
            endloop
            call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipFrame", 0), foundTooltip)
            call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), false)
            call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), false)
            call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipManaIcon", 0), false)
            call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipAreaIcon", 0), false)
        endif
        set u = null
        set abi = null
    endfunction

    public function InitFrames takes nothing returns nothing
        local integer i
        local framehandle frame
        local framehandle tooltipFrame
        if not BlzLoadTOCFile(TocPath) then
            call BJDebugMsg("|cffff0000TasSpellView - Error Reading Toc File at: " + TocPath)
        endif
        set ParentSimple = BlzCreateFrameByType("SIMPLEFRAME", "TasSpellViewSimpleFrame", ParentFuncSimple(), "", 0)
        set Parent = BlzCreateFrameByType("FRAME", "TasSpellViewFrame", ParentFunc(), "", 0)
        set i = 0
        loop
            set frame = BlzCreateSimpleFrame("TasSpellViewButton", ParentSimple, i)
            call BlzFrameSetPoint(frame, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, i), FRAMEPOINT_CENTER, 0, 0.0)
            call BlzFrameSetLevel(frame, 6) // reforged stuff
            call BlzFrameSetLevel(BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i), 7) // reforged stuff
            set tooltipFrame = BlzCreateFrameByType("SIMPLEFRAME", "TasSpellViewButtonToolTip", frame, "", i)
            call BlzFrameSetTooltip(frame, tooltipFrame)
            call BlzFrameSetVisible(tooltipFrame, false)

            call BlzFrameSetVisible(BlzCreateFrame("TasSpellViewButtonCooldown", Parent, 0, i), false)

            // reserve HandleIds
            call BlzGetFrameByName("TasSpellViewButtonBackdrop", i)
            call BlzGetFrameByName("TasSpellViewButtonTextOverLay", i)            
            call BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i)
            call BlzGetFrameByName("TasSpellViewButtonChargeBox", i)
            call BlzGetFrameByName("TasSpellViewButtonChargeText", i)
            set i = i + 1
            exitwhen i > 11
        endloop
        if GetHandleId(BlzGetFrameByName("TasSpellViewButtonBackdrop", 1)) == 0 then
            call BJDebugMsg("|cffff0000TasSpellView - Error Create TasSpellViewButton|r")
            call BJDebugMsg("  Check Imported toc & fdf & TocPath in Map script")
            call BJDebugMsg("  Imported toc needs to have empty ending line")
            call BJDebugMsg("  fdf path in toc needs to match map imported path")
            call BJDebugMsg("  TocPath in Map script needs to match map imported path")
        endif
        
        // create one ToolTip which shows data for current hovered inside a timer.
        // also reserve handleIds to allow async usage
        call BlzCreateFrame("TasSpellViewTooltipFrame", Parent, 0, 0)
        call BlzGetFrameByName("TasSpellViewTooltipBox", 0)
        call BlzGetFrameByName("TasSpellViewTooltipIcon", 0)
        call BlzGetFrameByName("TasSpellViewTooltipName", 0)
        call BlzGetFrameByName("TasSpellViewTooltipSeperator", 0)
        call BlzGetFrameByName("TasSpellViewTooltipText", 0)
        //call BlzGetFrameByName("TasSpellViewTooltipManaText", 0)
        call BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0)
        call BlzGetFrameByName("TasSpellViewTooltipRangeText", 0)
        //call BlzGetFrameByName("TasSpellViewTooltipAreaText", 0)
        
        call BlzFrameSetSize(BlzGetFrameByName("TasSpellViewTooltipText", 0), ToolTipSizeX, 0)
        call BlzFrameSetAbsPoint(BlzGetFrameByName("TasSpellViewTooltipText", 0), ToolTipPos, ToolTipPosX, ToolTipPosY)
        call BlzFrameSetPoint(BlzGetFrameByName("TasSpellViewTooltipBox", 0), FRAMEPOINT_TOPLEFT, BlzGetFrameByName("TasSpellViewTooltipIcon", 0), FRAMEPOINT_TOPLEFT, -0.005, 0.005)
        call BlzFrameSetPoint(BlzGetFrameByName("TasSpellViewTooltipBox", 0), FRAMEPOINT_BOTTOMRIGHT, BlzGetFrameByName("TasSpellViewTooltipText", 0), FRAMEPOINT_BOTTOMRIGHT, 0.005, -0.005)
        call BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipFrame", 0), false)

        
        call BlzFrameSetVisible(ParentSimple, false)
        call BlzFrameSetVisible(Parent, false)
        if GetHandleId(BlzGetFrameByName("TasSpellViewTooltipFrame", 0)) == 0 then
            call BJDebugMsg("TasSpellView - Error - Create TasSpellViewTooltipFrame")
            call BJDebugMsg("Check Imported toc & fdf & TocPath")
        endif
    endfunction

    function InitSpellView takes nothing returns nothing
        set Timer = CreateTimer()
        set SPELL_VIEW_GROUP = CreateGroup()
        call TimerStart(Timer, UpdateTime, true, function Update)

        call InitFrames()
        
    endfunction

    private function init_function takes nothing returns nothing
        if AutoRun then
            call InitSpellView()
        endif
    endfunction
endlibrary
