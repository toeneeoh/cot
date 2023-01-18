function InitTrig_Initialization takes nothing returns nothing
    call TimerStart(NewTimer(), 0.03, false, function Initialize)
endfunction
