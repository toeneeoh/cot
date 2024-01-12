if Debug then Debug.beginFile 'UI' end

OnInit.final("UI", function(require)
    require 'HeroSelect'

    local function LimitBreakButton(index, abil, path)
        _G["LimitBreakButtonFunc" .. index] = function()
            local pid = GetPlayerId(GetTriggerPlayer()) + 1 ---@type integer 

            if limitBreak[pid] & POWERSOF2[tonumber(index) - 1] == 0 and limitBreakPoints[pid] > 0 then
                limitBreak[pid] = limitBreak[pid] | POWERSOF2[tonumber(index) - 1]
                limitBreakPoints[pid] = limitBreakPoints[pid] - 1

                if GetLocalPlayer() == GetTriggerPlayer() then
                    if limitBreakPoints[pid] <= 0 then
                        BlzFrameSetVisible(LimitBreakBackdrop, false)
                    end
                    BlzSetAbilityIcon(_G[abil].id, "ReplaceableTextures\\CommandButtons\\BTN" .. path .. ".blp")
                end

                if _G[abil] == WINDSCAR then
                    local a = BlzGetUnitAbility(Hero[pid], _G[abil].id)
                    BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_TARGET_TYPE, 0, 0)
                    BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_TARGET_TYPE, 1, 0)
                    BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_TARGET_TYPE, 2, 0)
                    BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_TARGET_TYPE, 3, 0)
                    BlzSetAbilityIntegerLevelField(a, ABILITY_ILF_TARGET_TYPE, 4, 0)
                end
            end

            BlzFrameSetEnable(_G["LimitBreakButton" .. index], false)
            BlzFrameSetEnable(_G["LimitBreakButton" .. index], true)
        end
    end

    LimitBreakButton("1", "PARRY", "ParryLimitBreak")
    LimitBreakButton("2", "SPINDASH", "SpinDashLimitBreak")
    LimitBreakButton("3", "INTIMIDATINGSHOUT", "IntimidatingShoutLimitBreak")
    LimitBreakButton("4", "WINDSCAR", "WindScarLimitBreak")
    LimitBreakButton("5", "ADAPTIVESTRIKE", "AdaptiveStrikeLimitBreak")

    local function onclick()
        if GetTriggerPlayer() == GetLocalPlayer() then
            if BlzFrameIsVisible(menuButton) == true then
                BlzFrameSetVisible(upperbuttonBar, false)
                BlzFrameSetVisible(menuButton, false)
                --call BlzFrameSetVisible(allyButton, false)
                BlzFrameSetVisible(questButton, false)
                BlzFrameSetVisible(chatButton, false)
            else
                BlzFrameSetVisible(upperbuttonBar, true)
                BlzFrameSetVisible(menuButton, true)
                --call BlzFrameSetVisible(allyButton, true)
                BlzFrameSetVisible(questButton, true)
                BlzFrameSetVisible(chatButton, true)
            end

            BlzFrameSetEnable(showhidemenu, false)
            BlzFrameSetEnable(showhidemenu, true)
            StopCamera()
        end
    end

    local t         = CreateTrigger() ---@type trigger 
    local leftTreeAlignment      = 0.07 ---@type number 
    local middleTreeAlignment      = 0.31 ---@type number 
    local rightTreeAlignment      = 0.5 ---@type number 
    local treeSize      = 0.23 ---@type number 
    local smallTreeSize      = 0.18 ---@type number 

    -- Prevent multiplayer desyncs by forcing the creation of the QuestDialog frame
    BlzFrameClick(BlzGetFrameByName("UpperButtonBarQuestsButton", 0))
    BlzFrameClick(BlzGetFrameByName("QuestAcceptButton", 0))
    BlzFrameSetSize(BlzGetFrameByName("QuestItemListContainer", 0), 0.01, 0.01)
    BlzFrameSetSize(BlzGetFrameByName("QuestItemListScrollBar", 0), 0.001, 0.001)
    ForceUICancel()

        --inventory buttons
    local function inventoryborders(index, x, y)
        INVENTORYBACKDROP[index] = BlzCreateFrameByType("BACKDROP", "PORTRAIT", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
        BlzFrameSetAbsPoint(INVENTORYBACKDROP[index], FRAMEPOINT_CENTER, x, y)
        BlzFrameSetSize(INVENTORYBACKDROP[index], 0.0375, 0.0375)
        BlzFrameSetVisible(INVENTORYBACKDROP[index], false)
    end

    inventoryborders(0, 0.5315, 0.0965)
    inventoryborders(1, 0.5715, 0.0965)
    inventoryborders(2, 0.5315, 0.058)
    inventoryborders(3, 0.5715, 0.058)
    inventoryborders(4, 0.5315, 0.0195)
    inventoryborders(5, 0.5715, 0.0195)

    --talent tree
    TalentMainFrame = BlzCreateFrame("EscMenuBackdrop", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
    BlzFrameSetAbsPoint(TalentMainFrame, FRAMEPOINT_TOPLEFT, 0.05, 0.56)
    BlzFrameSetAbsPoint(TalentMainFrame, FRAMEPOINT_BOTTOMRIGHT, 0.75, 0.152300)
    BlzFrameSetVisible(TalentMainFrame, false)

    TreeLeft = BlzCreateFrame("ListBoxWar3", TalentMainFrame, 0, 1)
    BlzFrameSetAbsPoint(TreeLeft, FRAMEPOINT_TOPLEFT, leftTreeAlignment, 0.52)
    BlzFrameSetAbsPoint(TreeLeft, FRAMEPOINT_BOTTOMRIGHT, leftTreeAlignment + treeSize, 0.18)
    TreeMiddle = BlzCreateFrame("ListBoxWar3", TalentMainFrame, 0, 1)
    BlzFrameSetAbsPoint(TreeMiddle, FRAMEPOINT_TOPLEFT, middleTreeAlignment, 0.52)
    BlzFrameSetAbsPoint(TreeMiddle, FRAMEPOINT_BOTTOMRIGHT, middleTreeAlignment + smallTreeSize, 0.26)
    TreeRight = BlzCreateFrame("ListBoxWar3", TalentMainFrame, 0, 1)
    BlzFrameSetAbsPoint(TreeRight, FRAMEPOINT_TOPLEFT, rightTreeAlignment, 0.52)
    BlzFrameSetAbsPoint(TreeRight, FRAMEPOINT_BOTTOMRIGHT, rightTreeAlignment + treeSize, 0.18)

    ConfirmTalentsButton = BlzCreateFrame("ScriptDialogButton", TalentMainFrame, 0, 0)
    BlzFrameSetAbsPoint(ConfirmTalentsButton, FRAMEPOINT_TOPLEFT, leftTreeAlignment, 0.180410)
    BlzFrameSetAbsPoint(ConfirmTalentsButton, FRAMEPOINT_BOTTOMRIGHT, leftTreeAlignment + 0.1, 0.151000)
    BlzFrameSetText(ConfirmTalentsButton, "|cffFFFFFFConfirm|r")
    BlzFrameSetScale(ConfirmTalentsButton, 1.00)

    CancelTalentsButton = BlzCreateFrame("ScriptDialogButton", TalentMainFrame, 0, 0)
    BlzFrameSetAbsPoint(CancelTalentsButton, FRAMEPOINT_TOPLEFT, rightTreeAlignment + treeSize - 0.1, 0.180410)
    BlzFrameSetAbsPoint(CancelTalentsButton, FRAMEPOINT_BOTTOMRIGHT, rightTreeAlignment + treeSize, 0.151000)
    BlzFrameSetText(CancelTalentsButton, "|cffFFFFFDUndo|r")
    BlzFrameSetScale(CancelTalentsButton, 1.00)

    CloseTalentViewButton = BlzCreateFrame("ScriptDialogButton", TalentMainFrame, 0, 0)
    BlzFrameSetAbsPoint(CloseTalentViewButton, FRAMEPOINT_TOPLEFT, rightTreeAlignment + treeSize, 0.57)
    BlzFrameSetAbsPoint(CloseTalentViewButton, FRAMEPOINT_BOTTOMRIGHT, rightTreeAlignment + treeSize + 0.035, 0.545)
    BlzFrameSetText(CloseTalentViewButton, "|cffFCD20DX|r")
    BlzFrameSetScale(CloseTalentViewButton, 1.00)

    TitleBackgroundLeft = BlzCreateFrameByType("BACKDROP", "TitleBackgroundLeft", TreeLeft, "", 1)
    BlzFrameSetAbsPoint(TitleBackgroundLeft, FRAMEPOINT_TOPLEFT, leftTreeAlignment, 0.54)
    BlzFrameSetAbsPoint(TitleBackgroundLeft, FRAMEPOINT_BOTTOMRIGHT, leftTreeAlignment + treeSize, 0.513)
    BlzFrameSetTexture(TitleBackgroundLeft, "UI/Glues/Loading/LoadBar/Loading-BarBorder.blp", 0, true)

    TitleBackgroundMiddle = BlzCreateFrameByType("BACKDROP", "TitleBackgroundMiddle", TreeMiddle, "", 1)
    BlzFrameSetAbsPoint(TitleBackgroundMiddle, FRAMEPOINT_TOPLEFT, middleTreeAlignment, 0.54)
    BlzFrameSetAbsPoint(TitleBackgroundMiddle, FRAMEPOINT_BOTTOMRIGHT, middleTreeAlignment + smallTreeSize, 0.513)
    BlzFrameSetTexture(TitleBackgroundMiddle, "UI/Glues/Loading/LoadBar/Loading-BarBorder.blp", 0, true)

    TitleBackgroundRight = BlzCreateFrameByType("BACKDROP", "TitleBackgroundRight", TreeRight, "", 1)
    BlzFrameSetAbsPoint(TitleBackgroundRight, FRAMEPOINT_TOPLEFT, rightTreeAlignment, 0.54)
    BlzFrameSetAbsPoint(TitleBackgroundRight, FRAMEPOINT_BOTTOMRIGHT, rightTreeAlignment + treeSize, 0.513)
    BlzFrameSetTexture(TitleBackgroundRight, "UI/Glues/Loading/LoadBar/Loading-BarBorder.blp", 0, true)

    TitleLeft = BlzCreateFrameByType("TEXT", "name", TitleBackgroundLeft, "", 0)
    BlzFrameSetAbsPoint(TitleLeft, FRAMEPOINT_TOPLEFT, leftTreeAlignment, 0.53)
    BlzFrameSetAbsPoint(TitleLeft, FRAMEPOINT_BOTTOMRIGHT, leftTreeAlignment + treeSize, 0.522)
    BlzFrameSetText(TitleLeft, "Power")
    BlzFrameSetEnable(TitleLeft, false)
    BlzFrameSetScale(TitleLeft, 1.00)
    BlzFrameSetTextAlignment(TitleLeft, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)

    TitleMiddle = BlzCreateFrameByType("TEXT", "name", TitleBackgroundMiddle, "", 0)
    BlzFrameSetAbsPoint(TitleMiddle, FRAMEPOINT_TOPLEFT, middleTreeAlignment, 0.53)
    BlzFrameSetAbsPoint(TitleMiddle, FRAMEPOINT_BOTTOMRIGHT, middleTreeAlignment + smallTreeSize, 0.522)
    BlzFrameSetText(TitleMiddle, "Economy")
    BlzFrameSetEnable(TitleMiddle, false)
    BlzFrameSetScale(TitleMiddle, 1.00)
    BlzFrameSetTextAlignment(TitleMiddle, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)

    TitleRight = BlzCreateFrameByType("TEXT", "name", TitleBackgroundRight, "", 0)
    BlzFrameSetAbsPoint(TitleRight, FRAMEPOINT_TOPLEFT, rightTreeAlignment, 0.53)
    BlzFrameSetAbsPoint(TitleRight, FRAMEPOINT_BOTTOMRIGHT, rightTreeAlignment + treeSize, 0.522)
    BlzFrameSetText(TitleRight, "Utility")
    BlzFrameSetEnable(TitleRight, false)
    BlzFrameSetScale(TitleRight, 1.00)
    BlzFrameSetTextAlignment(TitleRight, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)

    --prestige status
    TreeStatus = BlzCreateFrame("ListBoxWar3", TalentMainFrame, 0, 1)
    BlzFrameSetAbsPoint(TreeStatus, FRAMEPOINT_TOPLEFT, middleTreeAlignment, 0.24)
    BlzFrameSetAbsPoint(TreeStatus, FRAMEPOINT_BOTTOMRIGHT, middleTreeAlignment + smallTreeSize, 0.18)

    StatusPoints = BlzCreateFrameByType("TEXT", "name", TreeStatus, "", 0)
    BlzFrameSetAllPoints(StatusPoints, TreeStatus)
    BlzFrameSetText(StatusPoints, "")
    BlzFrameSetEnable(StatusPoints, false)
    BlzFrameSetScale(StatusPoints, 1.00)
    BlzFrameSetTextAlignment(StatusPoints, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)

    TitleBackgroundStatus = BlzCreateFrameByType("BACKDROP", "TitleBackgroundStatus", TreeMiddle, "", 1)
    BlzFrameSetAbsPoint(TitleBackgroundStatus, FRAMEPOINT_TOPLEFT, middleTreeAlignment, 0.26)
    BlzFrameSetAbsPoint(TitleBackgroundStatus, FRAMEPOINT_BOTTOMRIGHT, middleTreeAlignment + smallTreeSize, 0.233)
    BlzFrameSetTexture(TitleBackgroundStatus, "UI/Glues/Loading/LoadBar/Loading-BarBorder.blp", 0, true)

    TitleStatus = BlzCreateFrameByType("TEXT", "name", TitleBackgroundStatus, "", 0)
    BlzFrameSetAbsPoint(TitleStatus, FRAMEPOINT_TOPLEFT, middleTreeAlignment, 0.25)
    BlzFrameSetAbsPoint(TitleStatus, FRAMEPOINT_BOTTOMRIGHT, middleTreeAlignment + smallTreeSize, 0.243)
    BlzFrameSetText(TitleStatus, "|cffffcc00Prestige Level: 0")
    BlzFrameSetEnable(TitleStatus, false)
    BlzFrameSetScale(TitleStatus, 1.00)
    BlzFrameSetTextAlignment(TitleStatus, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)

    --cover health text
    hideHealth = BlzCreateFrameByType("BACKDROP", "hidehealth", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
    BlzFrameSetAbsPoint(hideHealth, FRAMEPOINT_TOPLEFT, 0.225, 0.028)
    BlzFrameSetAbsPoint(hideHealth, FRAMEPOINT_BOTTOMRIGHT, 0.28, 0.0185)
    BlzFrameSetTexture(hideHealth, "black.dds", 0, true)
    BlzFrameSetVisible(hideHealth, false)

    --shield ui
    shieldBackdrop = BlzCreateFrameByType("BACKDROP", "shieldbackdrop", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
    BlzFrameSetAbsPoint(shieldBackdrop, FRAMEPOINT_TOPLEFT, 0.215570, 0.0428)
    BlzFrameSetAbsPoint(shieldBackdrop, FRAMEPOINT_BOTTOMRIGHT, 0.290450, 0.0313600)
    BlzFrameSetTexture(shieldBackdrop, "black.dds", 0, true)

    shieldText = BlzCreateFrameByType("TEXT", "shieldtext", shieldBackdrop, "", 0)
    BlzFrameSetText(shieldText, "")
    BlzFrameSetAllPoints(shieldText, shieldBackdrop)
    BlzFrameSetTextAlignment(shieldText, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_CENTER)
    BlzFrameSetVisible(shieldBackdrop, false)

    afkTextBG = BlzCreateFrameByType("BACKDROP", "afkTextBG", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
    BlzFrameSetPoint(afkTextBG, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, - 0.41)
    BlzFrameSetTexture(afkTextBG, "war3mapImported\\afkUI_3.dds", 0, true)
    BlzFrameSetSize(afkTextBG, 0.13, 0.05)
    BlzFrameSetVisible(afkTextBG, false)

    afkText = BlzCreateFrameByType("TEXT", "afkText", afkTextBG, "CText_18", 0)
    BlzFrameSetText(afkText, "")
    BlzFrameSetTextAlignment(afkText, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_CENTER)
    BlzFrameSetAllPoints(afkText, afkTextBG)
    BlzFrameSetFont(afkText, "Fonts\\frizqt__.ttf", 0.034, 0)

    dummyFrame = BlzCreateFrameByType("BACKDROP", "dummyFrame", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
    BlzFrameSetPoint(dummyFrame, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0.30, -0.37)
    BlzFrameSetTexture(dummyFrame, "war3mapImported\\afkUI_3.dds", 0, true)
    BlzFrameSetSize(dummyFrame, 0.25, 0.14)
    BlzFrameSetVisible(dummyFrame, false)

    dummyTextTitle = BlzCreateFrameByType("TEXT", "dummyTextTitle", dummyFrame, "CText_18", 0)
    BlzFrameSetTextAlignment(dummyTextTitle, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_LEFT)
    BlzFrameSetPoint(dummyTextTitle, FRAMEPOINT_CENTER, dummyFrame, FRAMEPOINT_CENTER, -0.04, 0)
    BlzFrameSetFont(dummyTextTitle, "Fonts\\frizqt__.ttf", 0.044, 0)
    BlzFrameSetText(dummyTextTitle, "Last Hit:\nTotal |cffE15F08Physical|r:\nTotal |cff8000ffMagic|r:\nTotal:\nDPS:\nPeak DPS:\nTime:")

    dummyTextValue = BlzCreateFrameByType("TEXT", "dummyTextValue", dummyFrame, "CText_18", 0)
    BlzFrameSetTextAlignment(dummyTextValue, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_RIGHT)
    BlzFrameSetPoint(dummyTextValue, FRAMEPOINT_CENTER, dummyFrame, FRAMEPOINT_CENTER, 0.04, 0)
    BlzFrameSetFont(dummyTextValue, "Fonts\\frizqt__.ttf", 0.034, 0)
    BlzFrameSetText(dummyTextValue, "0\n0\n0\n0\n0\n0\n0s")

    --voting UI
    votingBG = BlzCreateFrameByType("BACKDROP", "votingBG", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
    BlzFrameSetPoint(votingBG, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, - 0.11)
    BlzFrameSetTexture(votingBG, "war3mapImported\\hardmode.dds", 0, true)
    BlzFrameSetSize(votingBG, 0.12, 0.12)
    BlzFrameSetVisible(votingBG, false)

    votingButtonFrame = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", votingBG, "ScoreScreenTabButtonTemplate", 0)
    votingButtonIconYes = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", votingButtonFrame, "", 0)
    BlzFrameSetAllPoints(votingButtonIconYes, votingButtonFrame)
    BlzFrameSetTexture(votingButtonIconYes, "war3mapImported\\Checkframe.dds", 0, true)
    BlzFrameSetPoint(votingButtonFrame, FRAMEPOINT_CENTER, votingBG, FRAMEPOINT_CENTER, - 0.015, 0.015)
    BlzFrameSetSize(votingButtonFrame, 0.03, 0.03)

    votingButtonFrame2 = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", votingBG, "ScoreScreenTabButtonTemplate", 0)
    votingButtonIconNo = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", votingButtonFrame2, "", 0)
    BlzFrameSetAllPoints(votingButtonIconNo, votingButtonFrame2)
    BlzFrameSetTexture(votingButtonIconNo, "war3mapImported\\Xframe.dds", 0, true)
    BlzFrameSetPoint(votingButtonFrame2, FRAMEPOINT_CENTER, votingBG, FRAMEPOINT_CENTER, 0.015, - 0.015)
    BlzFrameSetSize(votingButtonFrame2, 0.03, 0.03)

    TriggerAddCondition(votingSelectYes, Condition(VotingMenu))
    TriggerAddAction(votingSelectYes, VoteYes)
    BlzTriggerRegisterFrameEvent(votingSelectYes, votingButtonFrame, FRAMEEVENT_CONTROL_CLICK)

    TriggerAddCondition(votingSelectNo, Condition(VotingMenu))
    TriggerAddAction(votingSelectNo, VoteNo)
    BlzTriggerRegisterFrameEvent(votingSelectNo, votingButtonFrame2, FRAMEEVENT_CONTROL_CLICK)

    --hardcore UI
    hardcoreBG = BlzCreateFrameByType("BACKDROP", "hardcoreBG", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
    BlzFrameSetPoint(hardcoreBG, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, - 0.27)
    BlzFrameSetTexture(hardcoreBG, "war3mapImported\\hardcoreframe.dds", 0, true)
    BlzFrameSetSize(hardcoreBG, 0.40, 0.25)
    BlzFrameSetVisible(hardcoreBG, false)

    hardcoreButtonFrame = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", hardcoreBG, "ScoreScreenTabButtonTemplate", 0)
    hardcoreButtonIcon = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", hardcoreButtonFrame, "", 0)
    BlzFrameSetAllPoints(hardcoreButtonIcon, hardcoreButtonFrame)
    BlzFrameSetTexture(hardcoreButtonIcon, "war3mapImported\\Checkframe.dds", 0, true)
    BlzFrameSetPoint(hardcoreButtonFrame, FRAMEPOINT_CENTER, hardcoreBG, FRAMEPOINT_CENTER, - 0.030, - 0.051)
    BlzFrameSetSize(hardcoreButtonFrame, 0.03, 0.03)

    hardcoreButtonFrame2 = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", hardcoreBG, "ScoreScreenTabButtonTemplate", 0)
    hardcoreButtonIcon2 = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", hardcoreButtonFrame2, "", 0)
    BlzFrameSetAllPoints(hardcoreButtonIcon2, hardcoreButtonFrame2)
    BlzFrameSetTexture(hardcoreButtonIcon2, "war3mapImported\\Xframe.dds", 0, true)
    BlzFrameSetPoint(hardcoreButtonFrame2, FRAMEPOINT_CENTER, hardcoreBG, FRAMEPOINT_CENTER, 0.030, - 0.051)
    BlzFrameSetSize(hardcoreButtonFrame2, 0.03, 0.03)

    TriggerAddCondition(hardcoreSelectYes, Condition(HardcoreMenu))
    TriggerAddAction(hardcoreSelectYes, HardcoreYes)
    BlzTriggerRegisterFrameEvent(hardcoreSelectYes, hardcoreButtonFrame, FRAMEEVENT_CONTROL_CLICK)

    TriggerAddCondition(hardcoreSelectNo, Condition(HardcoreMenu))
    TriggerAddAction(hardcoreSelectNo, HardcoreNo)
    BlzTriggerRegisterFrameEvent(hardcoreSelectNo, hardcoreButtonFrame2, FRAMEEVENT_CONTROL_CLICK)

    -- Expand TextArea
    BlzFrameSetPoint(BlzGetFrameByName("QuestDisplay", 0), FRAMEPOINT_TOPLEFT, BlzGetFrameByName("QuestDetailsTitle", 0), FRAMEPOINT_BOTTOMLEFT, 0.003, - 0.003)
    BlzFrameSetPoint(BlzGetFrameByName("QuestDisplay", 0), FRAMEPOINT_BOTTOMRIGHT, BlzGetFrameByName("QuestDisplayBackdrop", 0), FRAMEPOINT_BOTTOMRIGHT, - 0.003, 0.)

    -- Relocate button
    BlzFrameSetPoint(BlzGetFrameByName("QuestDisplayBackdrop", 0), FRAMEPOINT_BOTTOM, BlzGetFrameByName("QuestBackdrop", 0), FRAMEPOINT_BOTTOM, 0., 0.017)
    BlzFrameClearAllPoints(BlzGetFrameByName("QuestAcceptButton", 0))
    BlzFrameSetPoint(BlzGetFrameByName("QuestAcceptButton", 0), FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("QuestBackdrop", 0), FRAMEPOINT_TOPRIGHT, - .43, - 0.016)
    BlzFrameSetText(BlzGetFrameByName("QuestAcceptButton", 0), "×")
    BlzFrameSetSize(BlzGetFrameByName("QuestAcceptButton", 0), 0.03, 0.03)

    --Hiding clock UI and creating new frame bar
    imageTest = BlzCreateFrameByType("BACKDROP", "image", BlzGetFrameByName("ConsoleUIBackdrop", 0), "ButtonBackdropTemplate", 0)
    BlzFrameSetTexture(imageTest, "UI\\ResourceBar.tga", 0, true)
    BlzFrameSetPoint(imageTest, FRAMEPOINT_TOP, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, 0)
    BlzFrameSetSize(imageTest, 0.44, 0.0421)
    BlzFrameSetVisible(BlzFrameGetChild(BlzFrameGetChild(BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 5), 0), false)
    BlzFrameSetLevel(imageTest, 1)

    --create clock text
    clockText = BlzCreateFrameByType("TEXT", "clockText", imageTest, "CText_18", 0)
    BlzFrameSetPoint(clockText, FRAMEPOINT_TOPLEFT, imageTest, FRAMEPOINT_TOPLEFT, 0.05, - 0.009)
    BlzFrameSetFont(clockText, "Fonts\\frizqt__.ttf", 0.036, 0)

    --create plat text
    platText = BlzCreateFrameByType("TEXT", "platText", imageTest, "CText_18", 0)
    BlzFrameSetPoint(platText, FRAMEPOINT_TOP, imageTest, FRAMEPOINT_TOP, - 0.0625, - 0.028)
    BlzFrameSetFont(platText, "Fonts\\frizqt__.ttf", 0.035, 0)

    --create arcadite text
    arcText = BlzCreateFrameByType("TEXT", "arcText", imageTest, "CText_18", 0)
    BlzFrameSetTextAlignment(arcText, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_LEFT)
    BlzFrameSetPoint(arcText, FRAMEPOINT_TOP, imageTest, FRAMEPOINT_TOP, 0.0775, - 0.028)
    BlzFrameSetFont(arcText, "Fonts\\frizqt__.ttf", 0.035, 0)

    --Upkeep
    fh = BlzGetFrameByName("ResourceBarUpkeepText", 0)
    BlzFrameSetFont(fh, "", 0, 0)

    --Upkeep Hover Box
    fh = BlzFrameGetChild(BlzGetFrameByName("ResourceBarFrame", 0), 2)
    BlzFrameSetVisible(fh, false)

    --Food
    fh = BlzGetFrameByName("ResourceBarSupplyText", 0)
    BlzFrameSetAbsPoint(fh, FRAMEPOINT_TOPRIGHT, 0.60, 0.5950)

    --Gold
    fh = BlzGetFrameByName("ResourceBarGoldText", 0)
    BlzFrameSetAbsPoint(fh, FRAMEPOINT_TOPRIGHT, 0.389, 0.5950)

    --Lumber
    fh = BlzGetFrameByName("ResourceBarLumberText", 0)
    BlzFrameSetAbsPoint(fh, FRAMEPOINT_TOPRIGHT, 0.49, 0.5950)

    --Add back ally resource icons
    BlzFrameSetTexture(BlzGetFrameByName("InfoPanelIconAllyGoldIcon", 7), "UI\\GoldReplacement.dds", 0, false)
    BlzFrameSetTexture(BlzGetFrameByName("InfoPanelIconAllyWoodIcon", 7), "UI\\LumberReplacement.dds", 0, false)
    BlzFrameSetTexture(BlzGetFrameByName("InfoPanelIconAllyFoodIcon", 7), "UI\\CrystalReplacement.dds", 0, false)

    showhidemenu = BlzCreateFrame("ScriptDialogButton", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
    BlzFrameSetAbsPoint(showhidemenu, FRAMEPOINT_TOPLEFT, 0.37, 0.577)
    BlzFrameSetAbsPoint(showhidemenu, FRAMEPOINT_BOTTOMRIGHT, 0.43, 0.557)
    BlzFrameSetText(showhidemenu, "|cffffffffMenus|r")
    BlzFrameSetScale(showhidemenu, 0.6)
    BlzFrameSetFont(showhidemenu, "MasterFont", 0.028, 0)

    BlzTriggerRegisterFrameEvent(t, showhidemenu, FRAMEEVENT_CONTROL_CLICK)
    TriggerAddAction(t, onclick)

    for i = 0, 6 do
        BlzFrameSetScale(BlzGetFrameByName("AllianceSlot", i), 0.001)
        BlzFrameSetScale(BlzGetFrameByName("AllyCheckBox", i), 0.001)
    end

    allyButton = BlzGetFrameByName("UpperButtonBarAlliesButton", 0)
    menuButton = BlzGetFrameByName("UpperButtonBarMenuButton", 0)
    chatButton = BlzGetFrameByName("UpperButtonBarChatButton", 0)
    questButton = BlzGetFrameByName("UpperButtonBarQuestsButton", 0)
    upperbuttonBar = BlzGetFrameByName("UpperButtonBarFrame", 0)

    BlzFrameClearAllPoints(menuButton)
    BlzFrameClearAllPoints(allyButton)
    BlzFrameClearAllPoints(chatButton)
    BlzFrameClearAllPoints(questButton)

    BlzFrameSetAbsPoint(questButton, FRAMEPOINT_TOPLEFT, 0.36, 0.554)
    BlzFrameSetPoint(menuButton, FRAMEPOINT_TOP, questButton, FRAMEPOINT_BOTTOM, 0.0, 0.0)
    BlzFrameSetPoint(chatButton, FRAMEPOINT_TOP, menuButton, FRAMEPOINT_BOTTOM, 0.0, 0.0)
    BlzFrameSetPoint(allyButton, FRAMEPOINT_TOP, chatButton, FRAMEPOINT_BOTTOM, 0.0, 0.0)

    BlzFrameSetVisible(menuButton, false)
    BlzFrameSetVisible(chatButton, false)
    BlzFrameSetVisible(questButton, false)
    BlzFrameSetVisible(allyButton, false)

    --limit break upgrade UI
    LimitBreakBackdrop = BlzCreateFrame("QuestButtonDisabledBackdropTemplate", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
    BlzFrameSetAbsPoint(LimitBreakBackdrop, FRAMEPOINT_TOPLEFT, 0.61 - 0.0434, 0.212)
    BlzFrameSetAbsPoint(LimitBreakBackdrop, FRAMEPOINT_BOTTOMRIGHT, 0.795, 0.158)

    local function limit_break_buttons(index, x, x2, path)
        _G["LimitBreakButton" .. index] = BlzCreateFrameByType("GLUEBUTTON", "lb$index$", LimitBreakBackdrop, "ScoreScreenTabButtonTemplate", 0)
        BlzFrameSetAbsPoint(_G["LimitBreakButton" .. index], FRAMEPOINT_TOPLEFT, x, 0.205000)
        BlzFrameSetAbsPoint(_G["LimitBreakButton" .. index], FRAMEPOINT_BOTTOMRIGHT, x2, 0.165000)
        _G["LimitBreakBackdrop" .. index] = BlzCreateFrameByType("BACKDROP", "lbb" .. index, _G["LimitBreakButton" .. index], "", 0)
        BlzFrameSetAllPoints(_G["LimitBreakBackdrop" .. index], _G["LimitBreakButton" .. index])
        BlzFrameSetTexture(_G["LimitBreakBackdrop" .. index], "ReplaceableTextures\\CommandButtons\\BTN" .. path .. ".blp", 0, true)

        _G["TriggerLimitBreakButton" .. index] = CreateTrigger()
        BlzTriggerRegisterFrameEvent(_G["TriggerLimitBreakButton" .. index], _G["LimitBreakButton" .. index], FRAMEEVENT_CONTROL_CLICK)
        TriggerAddAction(_G["TriggerLimitBreakButton" .. index], _G["LimitBreakButtonFunc" .. index])
    end

    limit_break_buttons("1", 0.574000, 0.614000, "ParryLimitBreak")
    limit_break_buttons("2", 0.617400, 0.657400, "SpinDashLimitBreak")
    limit_break_buttons("3", 0.660810, 0.700810, "IntimidatingShoutLimitBreak")
    limit_break_buttons("4", 0.704530, 0.744530, "WindScarLimitBreak")
    limit_break_buttons("5", 0.747900, 0.787900, "AdaptiveStrikeLimitBreak")

    --limit break hover tooltips
    local function limit_break_tooltips(index, text)
        _G["LimitBreakToolBox" .. index] = BlzCreateFrame("ListBoxWar3", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        _G["LimitBreakToolText" .. index] = BlzCreateFrameByType("TEXT", "StandardInfoTextTemplate", _G["LimitBreakToolBox" .. index], "StandardInfoTextTemplate", 0)

        BlzFrameSetTooltip(_G["LimitBreakButton" .. index], _G["LimitBreakToolBox" .. index])

        BlzFrameSetPoint(_G["LimitBreakToolBox" .. index], FRAMEPOINT_TOPLEFT, LimitBreakBackdrop, FRAMEPOINT_CENTER, -0.095, 0.12)
        BlzFrameSetSize(_G["LimitBreakToolBox" .. index], 0.22, 0.09)

        BlzFrameClearAllPoints(_G["LimitBreakToolText" .. index])
        BlzFrameSetPoint(_G["LimitBreakToolText" .. index], FRAMEPOINT_CENTER, _G["LimitBreakToolBox" .. index], FRAMEPOINT_CENTER, 0, 0)
        BlzFrameSetSize(_G["LimitBreakToolText" .. index], 0.15, 0.06)
        BlzFrameSetText(_G["LimitBreakToolText" .. index], text)

        BlzFrameSetVisible(_G["LimitBreakToolBox" .. index], false)
    end

    limit_break_tooltips("1", "|cffffcc00Parry|r|n|nDamage is doubled and immunity window is extended to |cffffcc001|r second.")
    limit_break_tooltips("2", "|cffffcc00Spin Dash|r|n|nDamage is quadrupled and enemies struck have their attack speed slowed by |cffffcc0025\x25|r for |cffffcc002|r seconds.")
    limit_break_tooltips("3", "|cffffcc00Intimidating Shout|r|n|nAlso reduces the spell damage of enemies by |cffffcc0040\x25|r.")
    limit_break_tooltips("4", "|cffffcc00Wind Scar|r|n|nWind projectiles instead orbit around you for |cffffcc003|r seconds.")
    limit_break_tooltips("5", "|cffffcc00Adaptive Strike|r|n|nPassive cooldown reset chance increased to |cffffcc0050\x25|r.|nNow automatically casts after using a skill when available.")

    BlzFrameSetVisible(LimitBreakBackdrop, false)
end)

if Debug then Debug.endFile() end
