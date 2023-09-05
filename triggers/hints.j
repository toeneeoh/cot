library Hint requires Functions

    globals
        integer NUM_HINTS
        private integer hint = -1
        force hintplayers = CreateForce()
        string array hintstring
    endglobals
    
    function ShowHint takes nothing returns nothing
        local integer rand = GetRandomInt(2, NUM_HINTS)
        
        if hint < 2 then
            set hint = hint + 1
        else
            set hint = rand
        endif
        
        call DisplayTimedTextToForce(hintplayers, 15, hintstring[hint])
        if rand != hint then
            set hint = rand
        else
            set hint = hint + 1
        endif
        if hint > NUM_HINTS then
            set hint = 1
        endif
    endfunction
    
    //===========================================================================
    function HintInit takes nothing returns nothing
        local trigger hints = CreateTrigger()
    
        set hintstring[0] = "|cffc0c0c0Every 30 minutes the game will check for AFK players, so if you see a text box appear, type the number it displays after a hyphen (-####)|r"
        set hintstring[1] = "|cffc0c0c0Did you know?|r |cff9966ffCoT RPG|r |cffc0c0c0has a discord!|r |cff9ebef5https://discord.gg/peSTvTd|r"
        set hintstring[2] = "|cffc0c0c0If you find your experience rate dropping, try upgrading to a better home.|r"
        set hintstring[3] = "|cffc0c0c0Game too easy for you? Select|r |cff9966ffHardcore|r |cffc0c0c0on character creation to increase difficulty & increase benefits.|r"
        set hintstring[4] = "|cffc0c0c0Type|r |cff9966ff-info|r |cffc0c0c0or|r |cff9966ff-commands|r |cffc0c0c0to see a list of game options, especially if you are new.|r"
        set hintstring[5] = "|cffc0c0c0After an item drops it will be removed after 10 minutes, but don’t worry if you’ve already picked it up or bound it with your hero as they will not delete.|r"
        set hintstring[6] = "|cffc0c0c0Game too difficult? We recommend playing with 2+ players. If you are playing solo, consider playing online with friends or others.|r"
        set hintstring[7] = "|cffc0c0c0Enemies that respawn will appear as ghosts if you are too close, however if you walk away they will return to normal.|r"
        set hintstring[8] = "|cffc0c0c0There’s a few items in game with a significantly lower level requirement, though they are typically harder to acquire.|r"
        set hintstring[9] = "|cffc0c0c0You can type|r |cff9966ff-hints|r or |cff9966ff-nohints|r |cffc0c0c0to toggle these messages on and off.|r"
        set hintstring[10] = "|cffc0c0c0Once you enter the god's lair you cannot flee.|r"
        set hintstring[11] = "|cffc0c0c0Some artifacts remain frozen in ice, waiting to be recovered...|r"
        set hintstring[12] = "|cffc0c0c0Your colosseum experience rate will drop the more you participate, recover it by gaining experience outside of colosseum.|r"
        set hintstring[13] = "|cffc0c0c0Spellboost innately affects the damage of your spells by plus or minus 20%.|r"
        set hintstring[14] = "|cffc0c0c0Critical strike items and spells can stack their effect, the multipliers are additive.|r"
        set hintstring[15] = "|cffc0c0c0The Ashen Vat is a mysterious crafting device located in the north-west tower.|r"
        set hintstring[16] = "|cffc0c0c0The actions menu (Z on your hero) provides many useful settings such as displaying allied hero portraits on the left.|r"
        set hintstring[17] = "|cffc0c0c0Toggling off your auto attacks with -aa helps reduce the likelihood of drawing aggro, -info 8 for more information.|r"
        set hintstring[18] = "|cffc0c0c0If you meant to load another hero and you haven't left the church, you can type|r |cff9966ff-repick|r |cffc0c0c0and then|r |cff9966ff-load|r |cffc0c0c0to load another hero.|r"
        set hintstring[19] = "|cffc0c0c0Hold |cff9966ffLeft Alt|r |cffc0c0c0while viewing your abilites to see how they are affected by Spellboost.|r"
    
        set NUM_HINTS = 19
        
        call TriggerRegisterTimerEvent(hints, 240.00, true)
        call TriggerAddAction(hints, function ShowHint)
        
        set hints = null
    endfunction
    
endlibrary
    