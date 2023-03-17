function InitTrig_Initialization takes nothing returns nothing
    set ASHEN_VAT = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h05J', 30000., 30000., 270.)
    call TimerStart(NewTimer(), 0.03, false, function Initialize)
endfunction
