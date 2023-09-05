library CustomUI requires Functions, Commands, heroselection

    globals
        boolean array afkTextVisible
        boolean array hardcoreClicked
        trigger votingSelectYes = CreateTrigger()
        trigger votingSelectNo = CreateTrigger()
        trigger hardcoreSelectYes = CreateTrigger()
        trigger hardcoreSelectNo = CreateTrigger()
        framehandle afkTextBG
        framehandle afkText
        framehandle hardcoreBG
        framehandle hardcoreButtonFrame
        framehandle hardcoreButtonFrame2
        framehandle hardcoreButtonIcon
        framehandle hardcoreButtonIcon2
        framehandle votingBG
        framehandle votingButtonFrame
        framehandle votingButtonFrame2
        framehandle votingButtonIconNo
        framehandle votingButtonIconYes
        framehandle fh
        framehandle menuButton
        framehandle chatButton
        framehandle questButton
        framehandle allyButton
        framehandle imageTest
        framehandle clockText
        framehandle platText
        framehandle arcText
        framehandle showhidemenu
        framehandle upperbuttonBar
        framehandle dummyFrame
        framehandle dummyText

        framehandle hideHealth

        framehandle shieldBackdrop
        framehandle shieldText

        framehandle array INVENTORYBACKDROP

        //for async frame changes
        framehandle containerFrame
        framehandle array frames
        group MAIN_SELECT_GROUP
        unit array units
        integer unitsCount = 0
        filterfunc filter

        framehandle LimitBreakBackdrop = null 
        framehandle LimitBreakButton1 = null 
        framehandle LimitBreakBackdrop1 = null 
        trigger TriggerLimitBreakButton1 = null 
        framehandle LimitBreakButton2 = null 
        framehandle LimitBreakBackdrop2 = null 
        trigger TriggerLimitBreakButton2 = null 
        framehandle LimitBreakButton3 = null 
        framehandle LimitBreakBackdrop3 = null 
        trigger TriggerLimitBreakButton3 = null 
        framehandle LimitBreakButton4 = null 
        framehandle LimitBreakBackdrop4 = null 
        trigger TriggerLimitBreakButton4 = null 
    endglobals

    function LimitBreakButton1Func takes nothing returns nothing 
        set limitBreak[GetPlayerId(GetTriggerPlayer()) + 1] = 1

        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetVisible(LimitBreakBackdrop, false)
            call BlzSetAbilityIcon(PARRY.id, "ReplaceableTextures\\CommandButtons\\BTNParryLimitBreak.blp")
        endif

        call BlzFrameSetEnable(LimitBreakButton1, false) 
        call BlzFrameSetEnable(LimitBreakButton1, true) 
    endfunction 
    
    function LimitBreakButton2Func takes nothing returns nothing 
        set limitBreak[GetPlayerId(GetTriggerPlayer()) + 1] = 2

        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetVisible(LimitBreakBackdrop, false)
            call BlzSetAbilityIcon(SPINDASH.id, "ReplaceableTextures\\CommandButtons\\BTNSpinDashLimitBreak.blp")
            call BlzSetAbilityIcon(SPINDASH.id2, "ReplaceableTextures\\CommandButtons\\BTNSpinDashLimitBreak.blp")
        endif

        call BlzFrameSetEnable(LimitBreakButton2, false) 
        call BlzFrameSetEnable(LimitBreakButton2, true) 
    endfunction 
    
    function LimitBreakButton3Func takes nothing returns nothing 
        set limitBreak[GetPlayerId(GetTriggerPlayer()) + 1] = 3

        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetVisible(LimitBreakBackdrop, false)
            call BlzSetAbilityIcon(INTIMIDATINGSHOUT.id, "ReplaceableTextures\\CommandButtons\\BTNIntimidatingShoutLimitBreak.blp")
        endif

        call BlzFrameSetEnable(LimitBreakButton3, false) 
        call BlzFrameSetEnable(LimitBreakButton3, true) 
    endfunction 
    
    function LimitBreakButton4Func takes nothing returns nothing 
        set limitBreak[GetPlayerId(GetTriggerPlayer()) + 1] = 4

        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetVisible(LimitBreakBackdrop, false)
            call BlzSetAbilityIcon(WINDSCAR.id, "ReplaceableTextures\\CommandButtons\\BTNWindScarLimitBreak.blp")
        endif

        call BlzFrameSetEnable(LimitBreakButton4, false) 
        call BlzFrameSetEnable(LimitBreakButton4, true) 
    endfunction 

    private function onclick takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            if BlzFrameIsVisible(menuButton) == true then
                call BlzFrameSetVisible(upperbuttonBar, false)
                call BlzFrameSetVisible(menuButton, false)
                //call BlzFrameSetVisible(allyButton, false)
                call BlzFrameSetVisible(questButton, false)
                call BlzFrameSetVisible(chatButton, false)
            else
                call BlzFrameSetVisible(upperbuttonBar, true)
                call BlzFrameSetVisible(menuButton, true)
                //call BlzFrameSetVisible(allyButton, true)
                call BlzFrameSetVisible(questButton, true)
                call BlzFrameSetVisible(chatButton, true)
            endif

            call BlzFrameSetEnable(showhidemenu, false)
            call BlzFrameSetEnable(showhidemenu, true)
            call StopCamera()
        endif
    endfunction

    function CustomUISetup takes nothing returns nothing
        local trigger t = CreateTrigger()
        local integer i = 0
        
        // Prevent multiplayer desyncs by forcing the creation of the QuestDialog frame
        call BlzFrameClick(BlzGetFrameByName("UpperButtonBarQuestsButton", 0))
        call BlzFrameClick(BlzGetFrameByName("QuestAcceptButton", 0))
        call BlzFrameSetSize(BlzGetFrameByName("QuestItemListContainer", 0), 0.01, 0.01)
        call BlzFrameSetSize(BlzGetFrameByName("QuestItemListScrollBar", 0), 0.001, 0.001)    
        call ForceUICancel()

         //inventory buttons
        //! textmacro inventoryborders takes index, x, y
            set INVENTORYBACKDROP[$index$] = BlzCreateFrameByType("BACKDROP", "PORTRAIT", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
            call BlzFrameSetAbsPoint(INVENTORYBACKDROP[$index$], FRAMEPOINT_CENTER, $x$, $y$)
            call BlzFrameSetSize(INVENTORYBACKDROP[$index$], 0.0375, 0.0375)
            call BlzFrameSetVisible(INVENTORYBACKDROP[$index$], false)
        //! endtextmacro

        //! runtextmacro inventoryborders("0", "0.5315", "0.0965")
        //! runtextmacro inventoryborders("1", "0.5715", "0.0965")
        //! runtextmacro inventoryborders("2", "0.5315", "0.058")
        //! runtextmacro inventoryborders("3", "0.5715", "0.058")
        //! runtextmacro inventoryborders("4", "0.5315", "0.0195")
        //! runtextmacro inventoryborders("5", "0.5715", "0.0195")

        //cover health text
        set hideHealth = BlzCreateFrameByType("BACKDROP", "hidehealth", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
        call BlzFrameSetAbsPoint(hideHealth, FRAMEPOINT_TOPLEFT, 0.225, 0.028)
        call BlzFrameSetAbsPoint(hideHealth, FRAMEPOINT_BOTTOMRIGHT, 0.28, 0.0185)
        call BlzFrameSetTexture(hideHealth, "black.dds", 0, true)
        call BlzFrameSetVisible(hideHealth, false)

        //shield ui
        set shieldBackdrop = BlzCreateFrameByType("BACKDROP", "shieldbackdrop", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "", 0)
        call BlzFrameSetAbsPoint(shieldBackdrop, FRAMEPOINT_TOPLEFT, 0.215570, 0.0428)
        call BlzFrameSetAbsPoint(shieldBackdrop, FRAMEPOINT_BOTTOMRIGHT, 0.290450, 0.0313600)
        call BlzFrameSetTexture(shieldBackdrop, "black.dds", 0, true)

        set shieldText = BlzCreateFrameByType("TEXT", "shieldtext", shieldBackdrop, "", 0)
        call BlzFrameSetText(shieldText, "")
        call BlzFrameSetAllPoints(shieldText, shieldBackdrop)
        call BlzFrameSetTextAlignment(shieldText, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetVisible(shieldBackdrop, false)

        set afkTextBG = BlzCreateFrameByType("BACKDROP", "afkTextBG", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
        call BlzFrameSetPoint(afkTextBG, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, - 0.41)
        call BlzFrameSetTexture(afkTextBG, "war3mapImported\\afkUI_3.dds", 0, true)
        call BlzFrameSetSize(afkTextBG, 0.13, 0.05)
        call BlzFrameSetVisible(afkTextBG, false)
            
        set afkText = BlzCreateFrameByType("TEXT", "afkText", afkTextBG, "CText_18", 0)
        call BlzFrameSetText(afkText, "")
        call BlzFrameSetTextAlignment(afkText, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetAllPoints(afkText, afkTextBG)
        call BlzFrameSetFont(afkText, "Fonts\\frizqt__.ttf", 0.034, 0)

        set dummyFrame = BlzCreateFrameByType("BACKDROP", "dummyFrame", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
        call BlzFrameSetPoint(dummyFrame, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0.30, -0.37)
        call BlzFrameSetTexture(dummyFrame, "war3mapImported\\afkUI_3.dds", 0, true)
        call BlzFrameSetSize(dummyFrame, 0.20, 0.113)
        call BlzFrameSetVisible(dummyFrame, false)
            
        set dummyText = BlzCreateFrameByType("TEXT", "dummyText", dummyFrame, "CText_18", 0)
        call BlzFrameSetTextAlignment(dummyText, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_CENTER)
        call BlzFrameSetAllPoints(dummyText, dummyFrame)
        call BlzFrameSetFont(dummyText, "Fonts\\frizqt__.ttf", 0.040, 0)
        call BlzFrameSetText(dummyText, "Last Hit: 0.00 \nTotal: 0.00 \nDPS: 0.00")
   
        //voting UI
        set votingBG = BlzCreateFrameByType("BACKDROP", "votingBG", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
        call BlzFrameSetPoint(votingBG, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, - 0.11)
        call BlzFrameSetTexture(votingBG, "war3mapImported\\hardmode.dds", 0, true)
        call BlzFrameSetSize(votingBG, 0.12, 0.12)
        call BlzFrameSetVisible(votingBG, false)
    
        set votingButtonFrame = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", votingBG, "ScoreScreenTabButtonTemplate", 0)
        set votingButtonIconYes = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", votingButtonFrame, "", 0)
        call BlzFrameSetAllPoints(votingButtonIconYes, votingButtonFrame)
        call BlzFrameSetTexture(votingButtonIconYes, "war3mapImported\\Checkframe.dds", 0, true)
        call BlzFrameSetPoint(votingButtonFrame, FRAMEPOINT_CENTER, votingBG, FRAMEPOINT_CENTER, - 0.015, 0.015)
        call BlzFrameSetSize(votingButtonFrame, 0.03, 0.03)
    
        set votingButtonFrame2 = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", votingBG, "ScoreScreenTabButtonTemplate", 0)
        set votingButtonIconNo = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", votingButtonFrame2, "", 0)
        call BlzFrameSetAllPoints(votingButtonIconNo, votingButtonFrame2)
        call BlzFrameSetTexture(votingButtonIconNo, "war3mapImported\\Xframe.dds", 0, true)
        call BlzFrameSetPoint(votingButtonFrame2, FRAMEPOINT_CENTER, votingBG, FRAMEPOINT_CENTER, 0.015, - 0.015)
        call BlzFrameSetSize(votingButtonFrame2, 0.03, 0.03)
    
        call TriggerAddCondition(votingSelectYes, Condition(function VotingMenu))
        call TriggerAddAction(votingSelectYes, function VoteYes)
        call BlzTriggerRegisterFrameEvent(votingSelectYes, votingButtonFrame, FRAMEEVENT_CONTROL_CLICK)
        
        call TriggerAddCondition(votingSelectNo, Condition(function VotingMenu))
        call TriggerAddAction(votingSelectNo, function VoteNo)
        call BlzTriggerRegisterFrameEvent(votingSelectNo, votingButtonFrame2, FRAMEEVENT_CONTROL_CLICK)

        //hardcore UI
        set hardcoreBG = BlzCreateFrameByType("BACKDROP", "hardcoreBG", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), "ButtonBackdropTemplate", 0)
        call BlzFrameSetPoint(hardcoreBG, FRAMEPOINT_CENTER, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, - 0.27)
        call BlzFrameSetTexture(hardcoreBG, "war3mapImported\\hardcoreframe.dds", 0, true)
        call BlzFrameSetSize(hardcoreBG, 0.40, 0.25)
        call BlzFrameSetVisible(hardcoreBG, false)
    
        set hardcoreButtonFrame = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", hardcoreBG, "ScoreScreenTabButtonTemplate", 0)
        set hardcoreButtonIcon = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", hardcoreButtonFrame, "", 0)
        call BlzFrameSetAllPoints(hardcoreButtonIcon, hardcoreButtonFrame)
        call BlzFrameSetTexture(hardcoreButtonIcon, "war3mapImported\\Checkframe.dds", 0, true)
        call BlzFrameSetPoint(hardcoreButtonFrame, FRAMEPOINT_CENTER, hardcoreBG, FRAMEPOINT_CENTER, - 0.030, - 0.051)
        call BlzFrameSetSize(hardcoreButtonFrame, 0.03, 0.03)
    
        set hardcoreButtonFrame2 = BlzCreateFrameByType("GLUEBUTTON", "FaceButton", hardcoreBG, "ScoreScreenTabButtonTemplate", 0)
        set hardcoreButtonIcon2 = BlzCreateFrameByType("BACKDROP", "FaceButtonIcon", hardcoreButtonFrame2, "", 0)
        call BlzFrameSetAllPoints(hardcoreButtonIcon2, hardcoreButtonFrame2)
        call BlzFrameSetTexture(hardcoreButtonIcon2, "war3mapImported\\Xframe.dds", 0, true)
        call BlzFrameSetPoint(hardcoreButtonFrame2, FRAMEPOINT_CENTER, hardcoreBG, FRAMEPOINT_CENTER, 0.030, - 0.051)
        call BlzFrameSetSize(hardcoreButtonFrame2, 0.03, 0.03)
    
        call TriggerAddCondition(hardcoreSelectYes, Condition(function HardcoreMenu))
        call TriggerAddAction(hardcoreSelectYes, function HardcoreYes)
        call BlzTriggerRegisterFrameEvent(hardcoreSelectYes, hardcoreButtonFrame, FRAMEEVENT_CONTROL_CLICK)
        
        call TriggerAddCondition(hardcoreSelectNo, Condition(function HardcoreMenu))
        call TriggerAddAction(hardcoreSelectNo, function HardcoreNo)
        call BlzTriggerRegisterFrameEvent(hardcoreSelectNo, hardcoreButtonFrame2, FRAMEEVENT_CONTROL_CLICK)
    
        // Expand TextArea
        call BlzFrameSetPoint(BlzGetFrameByName("QuestDisplay", 0), FRAMEPOINT_TOPLEFT, BlzGetFrameByName("QuestDetailsTitle", 0), FRAMEPOINT_BOTTOMLEFT, 0.003, - 0.003)
        call BlzFrameSetPoint(BlzGetFrameByName("QuestDisplay", 0), FRAMEPOINT_BOTTOMRIGHT, BlzGetFrameByName("QuestDisplayBackdrop", 0), FRAMEPOINT_BOTTOMRIGHT, - 0.003, 0.)
        
        // Relocate button
        call BlzFrameSetPoint(BlzGetFrameByName("QuestDisplayBackdrop", 0), FRAMEPOINT_BOTTOM, BlzGetFrameByName("QuestBackdrop", 0), FRAMEPOINT_BOTTOM, 0., 0.017)
        call BlzFrameClearAllPoints(BlzGetFrameByName("QuestAcceptButton", 0))
        call BlzFrameSetPoint(BlzGetFrameByName("QuestAcceptButton", 0), FRAMEPOINT_TOPRIGHT, BlzGetFrameByName("QuestBackdrop", 0), FRAMEPOINT_TOPRIGHT, - .43, - 0.016)
        call BlzFrameSetText(BlzGetFrameByName("QuestAcceptButton", 0), "×")
        call BlzFrameSetSize(BlzGetFrameByName("QuestAcceptButton", 0), 0.03, 0.03)
    
        //Hiding clock UI and creating new frame bar
        set imageTest = BlzCreateFrameByType("BACKDROP", "image", BlzGetFrameByName("ConsoleUIBackdrop", 0), "ButtonBackdropTemplate", 0)
        call BlzFrameSetTexture(imageTest, "UI\\ResourceBar.tga", 0, true)
        call BlzFrameSetPoint(imageTest, FRAMEPOINT_TOP, BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), FRAMEPOINT_TOP, 0, 0)
        call BlzFrameSetSize(imageTest, 0.44, 0.0421)
        call BlzFrameSetVisible(BlzFrameGetChild(BlzFrameGetChild(BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 5), 0), false)
        call BlzFrameSetLevel(imageTest, 1)
    
        //create clock text
        set clockText = BlzCreateFrameByType("TEXT", "clockText", imageTest, "CText_18", 0)
        call BlzFrameSetText(clockText, "0")
        call BlzFrameSetPoint(clockText, FRAMEPOINT_TOPLEFT, imageTest, FRAMEPOINT_TOPLEFT, 0.05, - 0.009)
        call BlzFrameSetFont(clockText, "Fonts\\frizqt__.ttf", 0.036, 0)
    
        //create plat text
        set platText = BlzCreateFrameByType("TEXT", "platText", imageTest, "CText_18", 0)
        call BlzFrameSetText(platText, "0")
        call BlzFrameSetPoint(platText, FRAMEPOINT_TOP, imageTest, FRAMEPOINT_TOP, - 0.0625, - 0.028)
        call BlzFrameSetFont(platText, "Fonts\\frizqt__.ttf", 0.035, 0)
    
        //create arcadite text
        set arcText = BlzCreateFrameByType("TEXT", "arcText", imageTest, "CText_18", 0)
        call BlzFrameSetText(arcText, "0")
        call BlzFrameSetTextAlignment(arcText, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetPoint(arcText, FRAMEPOINT_TOP, imageTest, FRAMEPOINT_TOP, 0.0775, - 0.028)
        call BlzFrameSetFont(arcText, "Fonts\\frizqt__.ttf", 0.035, 0)
    
        //Upkeep
        set fh = BlzGetFrameByName("ResourceBarUpkeepText", 0)
        call BlzFrameSetFont(fh, "", 0, 0)
        
        //Upkeep Hover Box
        set fh = BlzFrameGetChild(BlzGetFrameByName("ResourceBarFrame", 0), 2)
        call BlzFrameSetVisible(fh, false)
        
        //Food
        set fh = BlzGetFrameByName("ResourceBarSupplyText", 0)
        call BlzFrameSetAbsPoint(fh, FRAMEPOINT_TOPRIGHT, 0.60, 0.5950)
    
        //Gold
        set fh = BlzGetFrameByName("ResourceBarGoldText", 0)
        call BlzFrameSetAbsPoint(fh, FRAMEPOINT_TOPRIGHT, 0.389, 0.5950)
    
        //Lumber
        set fh = BlzGetFrameByName("ResourceBarLumberText", 0)
        call BlzFrameSetAbsPoint(fh, FRAMEPOINT_TOPRIGHT, 0.49, 0.5950)
    
        //Add back ally resource icons
        call BlzFrameSetTexture(BlzGetFrameByName("InfoPanelIconAllyGoldIcon", 7), "UI\\GoldReplacement.dds", 0, false)
        call BlzFrameSetTexture(BlzGetFrameByName("InfoPanelIconAllyWoodIcon", 7), "UI\\LumberReplacement.dds", 0, false)
        call BlzFrameSetTexture(BlzGetFrameByName("InfoPanelIconAllyFoodIcon", 7), "UI\\CrystalReplacement.dds", 0, false)

        set showhidemenu = BlzCreateFrame("ScriptDialogButton", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        call BlzFrameSetAbsPoint(showhidemenu, FRAMEPOINT_TOPLEFT, 0.37, 0.577)
        call BlzFrameSetAbsPoint(showhidemenu, FRAMEPOINT_BOTTOMRIGHT, 0.43, 0.557)
        call BlzFrameSetText(showhidemenu, "|cffffffffMenus|r")
        call BlzFrameSetScale(showhidemenu, 0.6)
        call BlzFrameSetFont(showhidemenu, "MasterFont", 0.028, 0)

        call BlzTriggerRegisterFrameEvent(t, showhidemenu, FRAMEEVENT_CONTROL_CLICK)
        call TriggerAddAction(t, function onclick)

        set i = 0
        loop
            exitwhen i > 6
            call BlzFrameSetScale(BlzGetFrameByName("AllianceSlot", i), 0.001)
            call BlzFrameSetScale(BlzGetFrameByName("AllyCheckBox", i), 0.001)
            set i = i + 1
        endloop

        set allyButton = BlzGetFrameByName("UpperButtonBarAlliesButton", 0)
        set menuButton = BlzGetFrameByName("UpperButtonBarMenuButton", 0)
        set chatButton = BlzGetFrameByName("UpperButtonBarChatButton", 0)
        set questButton = BlzGetFrameByName("UpperButtonBarQuestsButton", 0)
        set upperbuttonBar = BlzGetFrameByName("UpperButtonBarFrame", 0)

        call BlzFrameClearAllPoints(menuButton)
        call BlzFrameClearAllPoints(allyButton)
        call BlzFrameClearAllPoints(chatButton)
        call BlzFrameClearAllPoints(questButton)

        call BlzFrameSetAbsPoint(questButton, FRAMEPOINT_TOPLEFT, 0.36, 0.554)
        call BlzFrameSetPoint(menuButton, FRAMEPOINT_TOP, questButton, FRAMEPOINT_BOTTOM, 0.0, 0.0)
        call BlzFrameSetPoint(chatButton, FRAMEPOINT_TOP, menuButton, FRAMEPOINT_BOTTOM, 0.0, 0.0)
        call BlzFrameSetPoint(allyButton, FRAMEPOINT_TOP, chatButton, FRAMEPOINT_BOTTOM, 0.0, 0.0)

        call BlzFrameSetVisible(menuButton, false)
        call BlzFrameSetVisible(chatButton, false)
        call BlzFrameSetVisible(questButton, false)
        call BlzFrameSetVisible(allyButton, false)
 
        //limit break upgrade UI
        set LimitBreakBackdrop = BlzCreateFrame("QuestButtonDisabledBackdropTemplate", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        call BlzFrameSetAbsPoint(LimitBreakBackdrop, FRAMEPOINT_TOPLEFT, 0.61, 0.212)
        call BlzFrameSetAbsPoint(LimitBreakBackdrop, FRAMEPOINT_BOTTOMRIGHT, 0.795, 0.158)
        call BlzFrameSetVisible(LimitBreakBackdrop, false)

        set LimitBreakButton1 = BlzCreateFrameByType("GLUEBUTTON", "lb1", LimitBreakBackdrop, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetAbsPoint(LimitBreakButton1, FRAMEPOINT_TOPLEFT, 0.617400, 0.205000)
        call BlzFrameSetAbsPoint(LimitBreakButton1, FRAMEPOINT_BOTTOMRIGHT, 0.657400, 0.165000)
        set LimitBreakBackdrop1 = BlzCreateFrameByType("BACKDROP", "lbb1", LimitBreakButton1, "", 0)
        call BlzFrameSetAllPoints(LimitBreakBackdrop1, LimitBreakButton1)
        call BlzFrameSetTexture(LimitBreakBackdrop1, "ReplaceableTextures\\CommandButtons\\BTNParryLimitBreak.blp", 0, true)

        set TriggerLimitBreakButton1 = CreateTrigger() 
        call BlzTriggerRegisterFrameEvent(TriggerLimitBreakButton1, LimitBreakButton1, FRAMEEVENT_CONTROL_CLICK) 
        call TriggerAddAction(TriggerLimitBreakButton1, function LimitBreakButton1Func) 

        set LimitBreakButton2 = BlzCreateFrameByType("GLUEBUTTON", "lb2", LimitBreakBackdrop, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetAbsPoint(LimitBreakButton2, FRAMEPOINT_TOPLEFT, 0.660810, 0.205000)
        call BlzFrameSetAbsPoint(LimitBreakButton2, FRAMEPOINT_BOTTOMRIGHT, 0.700810, 0.165000)
        set LimitBreakBackdrop2 = BlzCreateFrameByType("BACKDROP", "lbb2", LimitBreakButton2, "", 0)
        call BlzFrameSetAllPoints(LimitBreakBackdrop2, LimitBreakButton2)
        call BlzFrameSetTexture(LimitBreakBackdrop2, "ReplaceableTextures\\CommandButtons\\BTNSpinDashLimitBreak.blp", 0, true)

        set TriggerLimitBreakButton2 = CreateTrigger() 
        call BlzTriggerRegisterFrameEvent(TriggerLimitBreakButton2, LimitBreakButton2, FRAMEEVENT_CONTROL_CLICK) 
        call TriggerAddAction(TriggerLimitBreakButton2, function LimitBreakButton2Func) 

        set LimitBreakButton3 = BlzCreateFrameByType("GLUEBUTTON", "lb3", LimitBreakBackdrop, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetAbsPoint(LimitBreakButton3, FRAMEPOINT_TOPLEFT, 0.704530, 0.205010)
        call BlzFrameSetAbsPoint(LimitBreakButton3, FRAMEPOINT_BOTTOMRIGHT, 0.744530, 0.165010)
        set LimitBreakBackdrop3 = BlzCreateFrameByType("BACKDROP", "lbb3", LimitBreakButton3, "", 0)
        call BlzFrameSetAllPoints(LimitBreakBackdrop3, LimitBreakButton3)
        call BlzFrameSetTexture(LimitBreakBackdrop3, "ReplaceableTextures\\CommandButtons\\BTNIntimidatingShoutLimitBreak.blp", 0, true)

        set TriggerLimitBreakButton3 = CreateTrigger() 
        call BlzTriggerRegisterFrameEvent(TriggerLimitBreakButton3, LimitBreakButton3, FRAMEEVENT_CONTROL_CLICK) 
        call TriggerAddAction(TriggerLimitBreakButton3, function LimitBreakButton3Func) 

        set LimitBreakButton4 = BlzCreateFrameByType("GLUEBUTTON", "lb4", LimitBreakBackdrop, "ScoreScreenTabButtonTemplate", 0)
        call BlzFrameSetAbsPoint(LimitBreakButton4, FRAMEPOINT_TOPLEFT, 0.747900, 0.205000)
        call BlzFrameSetAbsPoint(LimitBreakButton4, FRAMEPOINT_BOTTOMRIGHT, 0.787900, 0.165000)
        set LimitBreakBackdrop4 = BlzCreateFrameByType("BACKDROP", "lbb4", LimitBreakButton4, "", 0)
        call BlzFrameSetAllPoints(LimitBreakBackdrop4, LimitBreakButton4)
        call BlzFrameSetTexture(LimitBreakBackdrop4, "ReplaceableTextures\\CommandButtons\\BTNWindScarLimitBreak.blp", 0, true)

        set TriggerLimitBreakButton4 = CreateTrigger() 
        call BlzTriggerRegisterFrameEvent(TriggerLimitBreakButton4, LimitBreakButton4, FRAMEEVENT_CONTROL_CLICK) 
        call TriggerAddAction(TriggerLimitBreakButton4, function LimitBreakButton4Func) 

        set t = null
    endfunction

endlibrary
