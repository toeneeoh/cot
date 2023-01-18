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
    
        set hintstring[0] = "|c00c0c0c0You can choose to stay a bum if you prefer, however your experience gain will drop. It really is better to buy a home or nation.|r"
        set hintstring[1] = "|c00c0c0c0Every 30 minutes the game will check for AFK players, so if you see a text box appear, type the number it displays after a hyphen (-####)|r"
        set hintstring[2] = "|c00c0c0c0Did you know?|r |c009966ffCoT RPG|r |c00c0c0c0has a discord!|r |c009ebef5https://discord.gg/peSTvTd|r"
        set hintstring[3] = "|c00c0c0c0If you find your experience rate dropping, try upgrading to a better home.|r"
        set hintstring[4] = "|c00c0c0c0Game too easy for you? Select|r |c009966ffHardcore|r |c00c0c0c0on character creation to increase difficulty & increase benefits.|r"
        set hintstring[5] = "|c00c0c0c0Type|r |c009966ff-info|r |c00c0c0c0or|r |c009966ff-commands|r |c00c0c0c0to see a list of game options, especially if you are new.|r"
        set hintstring[6] = "|c00c0c0c0After an item drops it will be removed after 10 minutes, but don’t worry if you’ve already picked it up or bound it with your hero as they will not delete.|r"
        set hintstring[7] = "|c00c0c0c0Game too difficult? We recommend playing with 2+ players. If you are playing solo, consider playing online with friends or others.|r"
        set hintstring[8] = "|c00c0c0c0The town fountain heals quickly, you only need to stand by it for a short time.|r"
        set hintstring[9] = "|c00c0c0c0Enemies that respawn will appear as ghosts if you are too close, however if you walk away they will return to normal.|r"
        set hintstring[10] = "|c00c0c0c0There’s a few items in game with a significantly lower level requirement, though they are typically harder to acquire.|r"
        set hintstring[11] = "|c00c0c0c0You can type|r |c009966ff-hints|r or |c009966ff-nohints|r |c00c0c0c0to toggle these messages on and off.|r"
        set hintstring[12] = "|c00c0c0c0Once you enter the god's lair you cannot flee.|r"
        set hintstring[13] = "|c00c0c0c0Some artifacts remain frozen in ice, waiting to be recovered...|r"
        set hintstring[14] = "|c00c0c0c0Your colosseum experience rate will drop the more you participate, recover it by gaining experience outside of colosseum.|r"
        set hintstring[15] = "|c00c0c0c0Spellboost innately affects the damage of your spells by plus or minus 20%.|r"
        set hintstring[16] = "|c00c0c0c0Some recipes require more than 6 items to craft, you can use your backpack to hold up to 12 items for a recipe.|r"
        set hintstring[17] = "|c00c0c0c0Critical strike items and spells can stack their effect, the multipliers are additive.|r"
        set hintstring[18] = "|c00c0c0c0The Ashen Vat is a mysterious crafting device located in the north-west tower.|r"
        set hintstring[19] = "|c00c0c0c0All full-plate boss/set items have a 25 movement speed penalty.|r"
        set hintstring[20] = "|c00c0c0c0The actions menu (Z on your hero) provides many useful settings such as displaying allied hero portraits on the left.|r"
    
        set NUM_HINTS = 20
        
        call TriggerRegisterTimerEvent(hints, 240.00, true)
        call TriggerAddAction(hints, function ShowHint)
        
        set hints = null
    endfunction
    
endlibrary
    