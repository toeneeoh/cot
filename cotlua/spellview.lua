if Debug then Debug.beginFile 'SpellView' end

OnInit.final("SpellView", function()

    -- TasSpellView 1.1a by Tasyen
    --displays with custom UI the abilites of not controled units in the command card

    -- when REFORGED = false you need to tell the abilityCodes used by units to have cooldown display
    -- the unit does not need to have the skills they are displayed when added that way.
    -- call AddUnitCodeData(FourCC('Ulic'), "AUfn,AUfu,AUdr,AUdd")

        REFORGED         = true  ---@type boolean -- have BlzGetAbilityId? otherwise false
        local AutoRun         = true  ---@type boolean --(true) will create Itself at 0s, (false) you need to InitSpellView()
        local TocPath        = "war3mapImported\\TasSpellView.toc" ---@type string 

        local UpdateTime      = 0.1 ---@type number 
        local ShowCooldown         = true  ---@type boolean -- can be set async, needs BlzGetAbilityId for ability by index 

        --ToolTip
        local ToolTipSizeX      = 0.26 ---@type number 
        local ToolTipPosX      = 0.79 ---@type number 
        local ToolTipPosY      = 0.165 ---@type number 
        local ToolTipPos                = FRAMEPOINT_BOTTOMRIGHT ---@type framepointtype 

        -- currentSelected
        local DataCount         = -1 ---@type integer 
        local DataMod         = 0 ---@type integer 
        local DataAbiCode=__jarray(0) ---@type integer[] 
        local DataMana=__jarray(0) ---@type integer[] 
        local DataRange=__jarray(0) ---@type number[]         
        local DataAoe=__jarray(0) ---@type number[] 
        local DataCool=__jarray(0) ---@type number[] 
        local DataName=__jarray("") ---@type string[] 
        local DataText=__jarray("") ---@type string[] 
        local DataIcon=__jarray("") ---@type string[] 

        local ParentSimple ---@type framehandle 
        local Parent ---@type framehandle 
        local Timer ---@type timer 

        local LastUnit      = nil ---@type unit 
        local SPELL_VIEW_GROUP ---@type group 

        local MOD_ABI         = 1 ---@type integer 
        local MOD_ABI_CODE         = 0 ---@type integer 

        local UnitCodeText=__jarray("") ---@type string[] 
        local UnitCodeType=__jarray(0) ---@type integer[] 
        local UnitCodeCount         = 0 ---@type integer 

    ---@return framehandle
    local function ParentFuncSimple()
        return BlzGetFrameByName("ConsoleUI", 0)
    end
    ---@return framehandle
    local function ParentFunc()
        return BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    end

    ---@param abi ability
    ---@param text string
    ---@param pid integer
    ---@return boolean
    local function AbiFilter(abi, text, pid)
        local id         = BlzGetAbilityId(abi) ---@type integer 

        if BlzGetAbilityBooleanField(abi, ABILITY_BF_ITEM_ABILITY) then
            return false
        end
        if BlzGetAbilityIntegerField(abi, ABILITY_IF_BUTTON_POSITION_NORMAL_X) == 0 and BlzGetAbilityIntegerField(abi, ABILITY_IF_BUTTON_POSITION_NORMAL_Y) == -11 then
            return false
        end
        if text == "Tool tip missing!" or text == "" or text == " " then
            return false
        end
        --backpack utilities
        if id == DETECT_LEAVE_ABILITY or id == 0 or id == FourCC('A04M') or id == FourCC('A00R') or id == FourCC('A0DT') or id == FourCC('A0KX') or id == FourCC('A04N') or id == FourCC('A03V') or id == FourCC('A0L0') then
            return false
        end
        --hero utilities
        if id == FourCC('A0GD') or id == FourCC('A06X') or id == FourCC('A08Y') or id == FourCC('A00B') or id == FourCC('A02T') or id == FourCC('A031') or id == FourCC('A067') or id == FourCC('A03C') or id == FourCC('A00F') then
            return false
        end
        --dummy spells
        if id == FourCC('A06K') or id == FourCC('A033') or id == FourCC('A0AP') or id == FourCC('A0A3') or id == FourCC('A0IW') or id == FourCC('A0IX') or id == FourCC('A0IY') or id == FourCC('A0IZ') then
            return false
        end
        if id == FourCC('A0JZ') or id == FourCC('A0JV') or id == FourCC('A0JY') or id == FourCC('A0JW') or id == FourCC('A00N') or id == FourCC('A01A') or id == FourCC('A09X') or id == FourCC('A024') then
            return false
        end
        return true
    end

    ---@param unitCode integer
    ---@param abiCodeString string
    local function AddUnitCodeData(unitCode, abiCodeString)
        UnitCodeCount = UnitCodeCount + 1
        UnitCodeType[UnitCodeCount] = unitCode
        UnitCodeText[UnitCodeCount] = abiCodeString
    end

    ---@param unitCode integer
    ---@return string
    local function GetUnitCodeData(unitCode)
        local i         = UnitCodeCount ---@type integer 
        while i > 0 do
            if unitCode == UnitCodeType[i] then
                return UnitCodeText[i]
            end
            i = i - 1
        end
        return ""
    end

    ---@param abiString string
    local function AddSpellString(abiString)
        local startIndex         = 0 ---@type integer 
        local skillCode ---@type integer 
        local addCount         = 0 ---@type integer 
        while not (startIndex + 3 >= StringLength(abiString)) do
            skillCode = FourCC(SubString(abiString, startIndex, startIndex + 4))
            startIndex = startIndex + 5
            DataAbiCode[addCount] = skillCode
            addCount = addCount + 1
        end
        DataCount = addCount - 1
    end

    ---@param u unit
    local function GetUnitData(u)
        local i         = 0 ---@type integer 
        local addCount         = 0 ---@type integer 
        local abi ---@type ability 
        local abiString ---@type string 
        local pid         = GetPlayerId(GetOwningPlayer(u)) + 1 ---@type integer 
        DataCount = -1

        -- have presaved Data
        abiString = GetUnitCodeData(GetUnitTypeId(u))
        if abiString ~= "" then
            AddSpellString(abiString)
            DataMod = MOD_ABI_CODE
        else
            DataMod = MOD_ABI
            if REFORGED then
                -- store abiCode treat it like MOD_ABI_CODE
                DataMod = MOD_ABI_CODE
            end
            i = 0
            addCount = 0
            abi = BlzGetUnitAbilityByIndex(u, i)
            while abi do
                if AbiFilter(abi, BlzGetAbilityStringLevelField(abi, ABILITY_SLF_TOOLTIP_NORMAL, 0), pid) then
                    if REFORGED then
                        -- store abiCode treat it like MOD_ABI_CODE
                        DataAbiCode[addCount] = BlzGetAbilityId(abi)
                    else
                        -- store the data
                        DataIcon[addCount] = BlzGetAbilityStringLevelField(abi, ABILITY_SLF_ICON_NORMAL, 0)
                        DataName[addCount] = BlzGetAbilityStringLevelField(abi, ABILITY_SLF_TOOLTIP_NORMAL, 0)
                        DataText[addCount] = BlzGetAbilityStringLevelField(abi, ABILITY_SLF_TOOLTIP_NORMAL_EXTENDED, 0)
                        DataMana[addCount] = BlzGetAbilityIntegerLevelField(abi, ABILITY_ILF_MANA_COST, 0)
                        DataCool[addCount] = BlzGetAbilityRealLevelField(abi, ABILITY_RLF_COOLDOWN, 0)
                        DataRange[addCount] = BlzGetAbilityRealLevelField(abi, ABILITY_RLF_CAST_RANGE, 0)
                        DataAoe[addCount] = BlzGetAbilityRealLevelField(abi, ABILITY_RLF_AREA_OF_EFFECT, 0)
                    end

                    addCount = addCount + 1
                end
                i = i + 1
                abi = BlzGetUnitAbilityByIndex(u, i)
            end
            DataCount = addCount - 1
        end
    end

    local function Update()
        local foundTooltip         = false ---@type boolean 
        local u ---@type unit 
        local hasControl ---@type boolean 
        local showSpellView ---@type boolean 
        local i ---@type integer 
        local spellType ---@type integer 
        local level ---@type integer 
        local cdRemain ---@type number 
        local cdTotal ---@type number 
        local abiCode ---@type integer 
        local abi ---@type ability 
        local mySpell ---@type Spell 

        GroupEnumUnitsSelected(SPELL_VIEW_GROUP, GetLocalPlayer(), nil)
        u = FirstOfGroup(SPELL_VIEW_GROUP)
        GroupClear(SPELL_VIEW_GROUP)

        if u ~= LastUnit then
            LastUnit = u
            GetUnitData(u)
        end

        hasControl = IsUnitOwnedByPlayer(u, GetLocalPlayer()) or GetPlayerAlliance(GetOwningPlayer(u), GetLocalPlayer(), ALLIANCE_SHARED_CONTROL)

        -- check for visible buttons, if any is visible then do not show TasSpellView
        if not hasControl then
            i = 0
            while true do
                if BlzFrameIsVisible(BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, i)) then
                    hasControl = true
                    break
                end
                if i == 11 then break end
                i = i + 1
            end
        end

        showSpellView = not hasControl
        --[[if GetHandleId(BlzGetFrameByName("SimpleReplayPanel", 0)) > 0 or GetHandleId(BlzGetFrameByName("SimpleReplayPanelV1", 0)) > 0 then
            set showSpellView = false
        endif]]
        BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewSimpleFrame", 0), showSpellView)
        BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewFrame", 0), showSpellView)
        if showSpellView then
            i = 0
            while true do
                if i <= DataCount then
                    BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButton", i), true)
                    if DataMod == MOD_ABI then
                        BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                        BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewButtonBackdrop", i), DataIcon[i], 0, false)
                        BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i), false)
                    elseif DataMod == MOD_ABI_CODE then
                        abiCode = DataAbiCode[i]
                        level = GetUnitAbilityLevel(u, abiCode)

                        if ShowCooldown then
                            cdRemain = BlzGetUnitAbilityCooldownRemaining(u, abiCode)
                            if cdRemain > 0 then
                                -- this be inaccurate when the map has systems to change cooldowns only during the casting.
                                cdTotal = BlzGetUnitAbilityCooldown(u, abiCode, level - 1)
                                --print(GetObjectName(data[i]),cdRemain,cdTotal, cdRemain/cdTotal)
                                BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), true)
                                BlzFrameSetValue(BlzGetFrameByName("TasSpellViewButtonCooldown", i), 100-(cdRemain/cdTotal)*100)
                                --print(BlzFrameIsVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i)), BlzFrameGetValue(BlzGetFrameByName("TasSpellViewButtonCooldown", i)))
                            else
                                BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                            end
                        else
                            BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                        end

                        BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i), true)
                        BlzFrameSetText(BlzGetFrameByName("TasSpellViewButtonChargeText", i), (level))
                        BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewButtonBackdrop", i), BlzGetAbilityIcon(abiCode), 0, false)
                    end
                else
                    BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButtonCooldown", i), false)
                    BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewButton", i), false)
                end

                -- hovered?
                if BlzFrameIsVisible(BlzGetFrameByName("TasSpellViewButtonToolTip", i)) then
                    foundTooltip = true
                    if DataMod == MOD_ABI then
                        BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewTooltipIcon", 0), DataIcon[i], 0, false)
                        BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipName", 0), "|cffffcc00" .. DataName[i])
                        BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), DataText[i])
                        BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), (DataMana[i]))
                        BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0), R2SW(DataCool[i],1,1))
                        BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipRangeText", 0), (R2I(DataRange[i])))
                        BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), (R2I(DataAoe[i])))
                    elseif DataMod == MOD_ABI_CODE then
                        abiCode = DataAbiCode[i]
                        level = GetUnitAbilityLevel(u, DataAbiCode[i])
                        abi = BlzGetUnitAbility(u, abiCode)
                        spellType = BlzGetAbilityId(abi)

                        if Spells[spellType] then
                            mySpell = Spells[spellType]:create(GetPlayerId(GetOwningPlayer(u)) + 1)

                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), GetSpellTooltip(mySpell, SpellTooltips[abiCode].string[level]))

                            mySpell:destroy()
                        else
                            if level > 0 then
                                BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), BlzGetAbilityExtendedTooltip(abiCode, level - 1))
                            else
                                BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipText", 0), BlzGetAbilityResearchExtendedTooltip(abiCode, 0))
                            end
                        end

                        BlzFrameSetTexture(BlzGetFrameByName("TasSpellViewTooltipIcon", 0), BlzGetAbilityIcon(abiCode), 0, false)
                        if level > 0 then
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), (BlzGetUnitAbilityManaCost(u, abiCode, level - 1)))
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0), R2SW(BlzGetUnitAbilityCooldown(u, abiCode, level - 1),1,1))
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipRangeText", 0), (R2I(BlzGetAbilityRealLevelField(abi, ABILITY_RLF_CAST_RANGE, level - 1))))
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), (R2I(BlzGetAbilityRealLevelField(abi, ABILITY_RLF_AREA_OF_EFFECT, level - 1))))
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipName", 0), "|cffffcc00" .. BlzGetAbilityTooltip(abiCode, level - 1))
                        else
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipName", 0), "|cffffcc00" .. BlzGetAbilityResearchTooltip(abiCode, 0))
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), (BlzGetAbilityManaCost(abiCode, 0)))
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0), R2SW(BlzGetAbilityCooldown(abiCode, 0),1,1))
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipRangeText", 0), "0")
                            BlzFrameSetText(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), "0")
                        end
                    end
                end
                if i == 11 then break end
                i = i + 1
            end
            BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipFrame", 0), foundTooltip)
            BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipManaText", 0), false)
            BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipAreaText", 0), false)
            BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipManaIcon", 0), false)
            BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipAreaIcon", 0), false)
        end
    end

    local function InitFrames()
        local i ---@type integer 
        local frame ---@type framehandle 
        local tooltipFrame ---@type framehandle 
        if not BlzLoadTOCFile(TocPath) then
            BJDebugMsg("|cffff0000TasSpellView - Error Reading Toc File at: " .. TocPath)
        end
        ParentSimple = BlzCreateFrameByType("SIMPLEFRAME", "TasSpellViewSimpleFrame", ParentFuncSimple(), "", 0)
        Parent = BlzCreateFrameByType("FRAME", "TasSpellViewFrame", ParentFunc(), "", 0)
        i = 0
        repeat
            frame = BlzCreateSimpleFrame("TasSpellViewButton", ParentSimple, i)
            BlzFrameSetPoint(frame, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, i), FRAMEPOINT_CENTER, 0, 0.0)
            BlzFrameSetLevel(frame, 6) -- reforged stuff
            BlzFrameSetLevel(BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i), 7) -- reforged stuff
            tooltipFrame = BlzCreateFrameByType("SIMPLEFRAME", "TasSpellViewButtonToolTip", frame, "", i)
            BlzFrameSetTooltip(frame, tooltipFrame)
            BlzFrameSetVisible(tooltipFrame, false)

            BlzFrameSetVisible(BlzCreateFrame("TasSpellViewButtonCooldown", Parent, 0, i), false)

            -- reserve HandleIds
            BlzGetFrameByName("TasSpellViewButtonBackdrop", i)
            BlzGetFrameByName("TasSpellViewButtonTextOverLay", i)
            BlzGetFrameByName("TasSpellViewButtonOverLayFrame", i)
            BlzGetFrameByName("TasSpellViewButtonChargeBox", i)
            BlzGetFrameByName("TasSpellViewButtonChargeText", i)
            i = i + 1
        until i > 11
        if GetHandleId(BlzGetFrameByName("TasSpellViewButtonBackdrop", 1)) == 0 then
            BJDebugMsg("|cffff0000TasSpellView - Error Create TasSpellViewButton|r")
            BJDebugMsg("  Check Imported toc & fdf & TocPath in Map script")
            BJDebugMsg("  Imported toc needs to have empty ending line")
            BJDebugMsg("  fdf path in toc needs to match map imported path")
            BJDebugMsg("  TocPath in Map script needs to match map imported path")
        end

        -- create one ToolTip which shows data for current hovered inside a timer.
        -- also reserve handleIds to allow async usage
        BlzCreateFrame("TasSpellViewTooltipFrame", Parent, 0, 0)
        BlzGetFrameByName("TasSpellViewTooltipBox", 0)
        BlzGetFrameByName("TasSpellViewTooltipIcon", 0)
        BlzGetFrameByName("TasSpellViewTooltipName", 0)
        BlzGetFrameByName("TasSpellViewTooltipSeperator", 0)
        BlzGetFrameByName("TasSpellViewTooltipText", 0)
        --call BlzGetFrameByName("TasSpellViewTooltipManaText", 0)
        BlzGetFrameByName("TasSpellViewTooltipCooldownText", 0)
        BlzGetFrameByName("TasSpellViewTooltipRangeText", 0)
        --call BlzGetFrameByName("TasSpellViewTooltipAreaText", 0)

        BlzFrameSetSize(BlzGetFrameByName("TasSpellViewTooltipText", 0), ToolTipSizeX, 0)
        BlzFrameSetAbsPoint(BlzGetFrameByName("TasSpellViewTooltipText", 0), ToolTipPos, ToolTipPosX, ToolTipPosY)
        BlzFrameSetPoint(BlzGetFrameByName("TasSpellViewTooltipBox", 0), FRAMEPOINT_TOPLEFT, BlzGetFrameByName("TasSpellViewTooltipIcon", 0), FRAMEPOINT_TOPLEFT, -0.005, 0.005)
        BlzFrameSetPoint(BlzGetFrameByName("TasSpellViewTooltipBox", 0), FRAMEPOINT_BOTTOMRIGHT, BlzGetFrameByName("TasSpellViewTooltipText", 0), FRAMEPOINT_BOTTOMRIGHT, 0.005, -0.005)
        BlzFrameSetVisible(BlzGetFrameByName("TasSpellViewTooltipFrame", 0), false)

        BlzFrameSetVisible(ParentSimple, false)
        BlzFrameSetVisible(Parent, false)
        if GetHandleId(BlzGetFrameByName("TasSpellViewTooltipFrame", 0)) == 0 then
            BJDebugMsg("TasSpellView - Error - Create TasSpellViewTooltipFrame")
            BJDebugMsg("Check Imported toc & fdf & TocPath")
        end
    end

    if AutoRun then
        Timer = CreateTimer()
        SPELL_VIEW_GROUP = CreateGroup()
        TimerStart(Timer, UpdateTime, true, Update)

        InitFrames()
    end

end)

if Debug then Debug.endFile() end
