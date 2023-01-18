library Commands requires Functions, CodelessSaveLoad

globals
	boolean array givecd
	boolean FightingAzazoth = false
    player tempplayer
	group AzazothPlayers = CreateGroup()
    boolean townhidden = false
    dialog array GiveDialog
    button array GiveButton
    integer array Receiver
    integer array ResourceGiven
    boolean array autosave
	integer VOTING_TYPE = 0
	integer VoteYay = 0
	integer VoteNay = 0
	boolean array autoAttackDisabled
	real BossDelay = 1.
	boolean array I_VOTED
	boolean array destroyBaseFlag
	integer votekickPlayer = 0
	integer votekickingPlayer = 0
	string ArcTag = "|cff66FF66Arcadite Lumber|r: "
	string PlatTag = "|cffccccccPlatinum Coins|r: "
endglobals

function OnNewProfile takes player p returns nothing
    local dialog alertDialog = DialogCreate()
    local trigger yesButtonTrigger = CreateTrigger()
    local trigger noButtonTrigger = CreateTrigger()
	local integer pid = GetPlayerId(p) + 1
    
    if Profiles[pid].profileHash > 0 then
        call DisplayTimedTextToPlayer(p, 0, 0, 20.0, "\nYou cannot start a new profile anymore")
        return
    endif
    
    call DialogSetMessage(alertDialog, "Start a new profile?\n|cFFFF0000Any old profile will be\noverwritten once you save.|r")
    
    call TriggerRegisterDialogButtonEvent(yesButtonTrigger, DialogAddButton(alertDialog, "Yes", 0))
    call TriggerRegisterDialogButtonEvent(noButtonTrigger, DialogAddButton(alertDialog, "No", 0))
    
    call TriggerAddCondition(yesButtonTrigger, Filter(function OnDialogButtonClickedYes))
    call TriggerAddCondition(noButtonTrigger, Filter(function OnDialogButtonClickedNo))
    
    call DialogDisplay(p, alertDialog, true)
    
    set alertDialog = null
    set yesButtonTrigger = null
    set noButtonTrigger = null
endfunction

function GiveCD takes nothing returns nothing
    local integer pid = ReleaseTimer(GetExpiredTimer())
    
    set givecd[pid] = false
endfunction

function BeginAzazoth takes nothing returns nothing
	local group ug = CreateGroup()
	local User u = User.first

	call GroupEnumUnitsInRect(ug, gg_rct_Astral_God_Challenge_Circle, Condition(function ischar))

	if FightingAzazoth == false and udg_Chaos_World_On and BlzGroupGetSize(AzazothPlayers) == 0 and BlzGroupGetSize(ug) > 0 and GetWidgetLife(ChaosBoss[BOSS_AZAZOTH]) >= 0.406 then
		set FightingAzazoth = true
		call PauseUnit(ChaosBoss[BOSS_AZAZOTH],true)
		call UnitAddAbility(ChaosBoss[BOSS_AZAZOTH], 'Avul')
		loop
			exitwhen u == User.NULL
			if RectContainsUnit(gg_rct_Astral_God_Challenge_Circle, Hero[u.id]) then
				call DestroyEffectTimed(AddSpecialEffectTarget("Abilities\\Spells\\Undead\\Darksummoning\\DarkSummonTarget.mdl", Hero[u.id],"origin"), 2.)
				call GroupAddUnit(AzazothPlayers, Hero[u.id])
			endif
			set u = u.next
		endloop
		call TriggerSleepAction(2)
		set u = User.first
		loop
			exitwhen u == User.NULL
			if IsUnitInGroup(Hero[u.id],AzazothPlayers) then
				call SetCameraBoundsRectForPlayerEx(u.toPlayer(), gg_rct_GodsCameraBounds)
				call SetUnitPosition(Hero[u.id], GetRectCenterX(gg_rct_Azazoth_Spawn_AGD), GetRectCenterY(gg_rct_Azazoth_Spawn_AGD) - 1000)
				call PanCameraToTimedForPlayer(u.toPlayer(), GetUnitX(Hero[u.id]), GetUnitY(Hero[u.id]), 0)
			endif
			set u = u.next
		endloop
		call TriggerSleepAction(4)
		call PauseUnit(ChaosBoss[BOSS_AZAZOTH],false)
		call UnitRemoveAbility(ChaosBoss[BOSS_AZAZOTH], 'Avul')
	endif
	
	call DestroyGroup(ug)
	
	set ug = null
endfunction

function HeroAddStats takes unit u, real rawbonus, integer stattype, boolean isPlat returns nothing
	local player p = GetOwningPlayer(u)
	local integer pid = GetConvertedPlayerId(p)
	local integer totalStats
	local integer trueBonus 
	local string displayMessage = "You gained |cffffcc00"
	local integer hlev = GetHeroLevel(u)
	local integer levelMax= TomeCap(hlev) //carved out to use same formula in save/load system
	local integer i=1

	if hlev>25 then
		set totalStats=IMaxBJ(250, GetHeroStr(u,false) +GetHeroAgi(u,false) +GetHeroInt(u,false) )
	else
		set totalStats=IMaxBJ(50, GetHeroStr(u,false) +GetHeroAgi(u,false) +GetHeroInt(u,false) )
	endif

	set trueBonus= R2I(rawbonus * 17.2 / Pow(totalStats, 0.35))

	if totalStats > levelMax then
		call DisplayTextToPlayer(p, 0, 0, "You cannot buy any more tomes until you level up further, no gold has been charged.")
		set p=null
		return
	elseif isPlat == false then
		if stattype == 4 then
			call ChargePlayerGold(pid, 20000, 0)
		else
			call ChargePlayerGold(pid, 10000, 0)
		endif
	elseif isPlat then
		if stattype == 4 then
			call ChargePlayerGold(pid, 0, 2)
		else
			call ChargePlayerGold(pid, 0, 1)
		endif
	endif
	
	if stattype == 1 then
		call SetHeroStr(u, GetHeroStr(u,false) + trueBonus, true)
		call DisplayTextToPlayer(p, 0, 0, displayMessage + I2S(trueBonus) + "|r Strength.")
	elseif stattype == 2 then
		call SetHeroAgi(u, GetHeroAgi(u,false) + trueBonus, true)
		call DisplayTextToPlayer(p, 0, 0, displayMessage + I2S(trueBonus) + "|r Agility.")
	elseif stattype == 3 then
		call SetHeroInt(u, GetHeroInt(u,false) + trueBonus, true)
		call DisplayTextToPlayer(p, 0, 0, displayMessage + I2S(trueBonus) + "|r Intelligence.")
	elseif stattype == 4 then
		call SetHeroStr(u, GetHeroStr(u,false) + trueBonus, true)
		call SetHeroAgi(u, GetHeroAgi(u,false) + trueBonus, true)
		call SetHeroInt(u, GetHeroInt(u,false) + trueBonus, true)
		call DisplayTextToPlayer(p, 0, 0, displayMessage + I2S(trueBonus) + "|r All Stats.")
	endif

	call DestroyEffect(AddSpecialEffectTargetUnitBJ("chest", u, "Objects\\InventoryItems\\tomeRed\\tomeRed.mdl"))
	call DestroyEffect(AddSpecialEffectTargetUnitBJ("chest", u, "Abilities\\Spells\\Items\\AIam\\AIamTarget.mdl"))
	set p = null
endfunction

function GiveClick takes nothing returns nothing
    local player p = GetTriggerPlayer()
    local button b = GetClickedButton()
    local integer pid = GetPlayerId(p) + 1
    local integer i = 0
    local integer amount = 0
    
    loop
        exitwhen b == GiveButton[pid * 8 + i]
        set i = i + 1
    endloop
    
    call DialogClear(GiveDialog[pid])
    
    if i < 10 then
        set Receiver[pid] = i
        set GiveButton[pid * 8 + 100 + i] = DialogAddButton(GiveDialog[pid], "Gold", 0)
        set GiveButton[pid * 8 + 200 + i] = DialogAddButton(GiveDialog[pid], "Lumber", 0)
        set GiveButton[pid * 8 + 300 + i] = DialogAddButton(GiveDialog[pid], "Both", 0)
        call DialogAddButton(GiveDialog[pid], "Cancel", 0)
        call DialogDisplay(p, GiveDialog[pid], true)
    elseif i < 400 then
        set ResourceGiven[pid] = R2I(i / 100.)
        set GiveButton[pid * 8 + 1000 + i] = DialogAddButton(GiveDialog[pid], "250", 0)
        set GiveButton[pid * 8 + 2000 + i] = DialogAddButton(GiveDialog[pid], "500", 0)
        set GiveButton[pid * 8 + 3000 + i] = DialogAddButton(GiveDialog[pid], "1000", 0)
        set GiveButton[pid * 8 + 4000 + i] = DialogAddButton(GiveDialog[pid], "2500", 0)
        call DialogAddButton(GiveDialog[pid], "Cancel", 0)
        call DialogDisplay(p, GiveDialog[pid], true)
    else
        if i > 4000 then
            set amount = 2500
        elseif i > 3000 then
            set amount = 1000
        elseif i > 2000 then
            set amount = 500
        elseif i > 1000 then
            set amount = 250
        endif
    endif
    
    if amount > 0 then
        if ResourceGiven[pid] == 3 then // both
            if GetPlayerState(p, ConvertPlayerState(1)) > amount and GetPlayerState(p, ConvertPlayerState(2)) > amount then
                set givecd[pid] = true
                call TimerStart(NewTimerEx(pid), 25., false, function GiveCD)
            
                call SetPlayerState(p, ConvertPlayerState(1), GetPlayerState(p, ConvertPlayerState(1)) - amount)
                call SetPlayerState(p, ConvertPlayerState(2), GetPlayerState(p, ConvertPlayerState(2)) - amount)
                
                call DisplayTextToPlayer(p,0,0,"You have given " + I2S(amount) + " gold & lumber to " + User.fromIndex(Receiver[pid]).nameColored)
                call DisplayTextToPlayer(Player(Receiver[pid]), 0, 0, User.fromIndex(pid - 1).nameColored + " has given " + I2S(amount) + " gold & lumber to you.")

                call SetPlayerState(Player(Receiver[pid]), ConvertPlayerState(1), GetPlayerState(Player(Receiver[pid]), ConvertPlayerState(1)) + amount)
                call SetPlayerState(Player(Receiver[pid]), ConvertPlayerState(2), GetPlayerState(Player(Receiver[pid]), ConvertPlayerState(2)) + amount)
            else
                call DisplayTextToPlayer(p, 0, 0, "You do not have enough to send!")
            endif
        elseif ResourceGiven[pid] == 2 then // lumber
            if GetPlayerState(p, ConvertPlayerState(2)) > amount then
                set givecd[pid] = true
                call TimerStart(NewTimerEx(pid), 25., false, function GiveCD)
                call SetPlayerState(p, ConvertPlayerState(2), GetPlayerState(p, ConvertPlayerState(2)) - amount)
                
                call DisplayTextToPlayer(p,0,0,"You have given " + I2S(amount)+" lumber to " + User.fromIndex(Receiver[pid]).nameColored)
                call DisplayTextToPlayer(Player(Receiver[pid]), 0, 0, User.fromIndex(pid - 1).nameColored + " has given " + I2S(amount) + " lumber to you.")

                call SetPlayerState(Player(Receiver[pid]), ConvertPlayerState(2), GetPlayerState(Player(Receiver[pid]), ConvertPlayerState(2)) + amount)
            else
                call DisplayTextToPlayer(p, 0, 0, "You do not have enough to send!")
            endif
        elseif ResourceGiven[pid] == 1 then // gold
            if GetPlayerState(p, ConvertPlayerState(1)) > amount then
                set givecd[pid] = true
                call TimerStart(NewTimerEx(pid), 25., false, function GiveCD)
                call SetPlayerState(p, ConvertPlayerState(1), GetPlayerState(p, ConvertPlayerState(1)) - amount)
                
                call DisplayTextToPlayer(p, 0, 0, "You have given " + I2S(amount) + " gold to " + User.fromIndex(Receiver[pid]).nameColored)
                call DisplayTextToPlayer(Player(Receiver[pid]), 0, 0, User.fromIndex(pid - 1).nameColored + " has given " + I2S(amount) + " gold to you.")

                call SetPlayerState(Player(Receiver[pid]), ConvertPlayerState(1), GetPlayerState(Player(Receiver[pid]), ConvertPlayerState(1)) + amount)
            else
                call DisplayTextToPlayer(p, 0, 0, "You do not have enough to send!")
            endif
        endif
    endif
    
    set p = null
    set b = null
endfunction

function GiveSystem takes player p returns nothing
    local integer pid = GetPlayerId(p) + 1
    local User u = User.first
    
    call DialogClear(GiveDialog[pid])
    
    loop
        exitwhen u == User.NULL
            
        if pid != GetPlayerId(u.toPlayer()) + 1 and IsPlayerInForce(u.toPlayer(), FORCE_PLAYING) then
            set GiveButton[pid * 8 + GetPlayerId(u.toPlayer())] = DialogAddButton(GiveDialog[pid], GetPlayerName(Player(GetPlayerId(u.toPlayer()))), 0)
        endif

        set u = u.next
    endloop
    
    call DialogAddButton(GiveDialog[pid], "Cancel", 0)
	
    call DialogDisplay(p, GiveDialog[pid], true)
    
endfunction

function ChargeNetworth takes player p, integer flat, real percent, integer minimum, string message returns nothing
	local integer pid = GetPlayerId(p) + 1
	local integer playerGold = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
	local integer playerLumber = GetPlayerState(p, PLAYER_STATE_RESOURCE_LUMBER)
	local integer cost
	local integer platCost = R2I((playerGold / 1000000. + udg_Plat_Gold[pid]) * percent)
	local integer arcCost = R2I((playerLumber / 1000000. + udg_Arca_Wood[pid]) * percent)
		
	set cost = flat + R2I(playerGold * percent)  
	if cost < minimum then
		set cost = minimum
	endif
	set cost = ModuloInteger(cost, 1000000)

	call ChargePlayerGold(pid, cost, platCost)
	
	if message != "" then
		if platCost > 0 then
			set message = message + " " + RealToString(platCost) + " platinum, " + RealToString(cost) + " gold"
		else
			set message = message + " " + RealToString(cost) + " gold"
		endif
	endif
	
	set cost = flat + R2I(playerLumber * percent)
	if cost < minimum then
		set cost = minimum
	endif
	set cost = ModuloInteger(cost, 1000000)

	call ChargePlayerLumber(pid, cost, arcCost)
	
	if message != "" then
		if arcCost > 0 then
			set message = message + ", " + RealToString(arcCost) + " arcadite, and " + RealToString(cost) + " lumber."
		else
			set message = message + " and " + RealToString(cost) + " lumber."
		endif
		call DisplayTextToPlayer(p, 0, 0, message)
	endif
endfunction

function ShowExpRate takes player user, integer pid returns nothing
	if InColo[pid] then
        call DisplayTimedTextToPlayer( user,0,0, 30, "|c00808080Experience Rate: |r" + R2S(udg_XP_Rate[pid]) +"%" )
	else
        call DisplayTimedTextToPlayer( user,0,0, 30, "|c00808080Experience Rate: |r" + R2S(udg_XP_Rate[pid]) +"%" )
		call DisplayTimedTextToPlayer( user,0,0, 30, "|c00808080Colosseum Experience Multiplier: |r" + R2S(udg_Colloseum_XP[pid]*100.) +"%" )
	endif
endfunction

function StatsInfo takes player user, integer id returns nothing
	local integer i = id
	if i == null then
		set i = GetPlayerId(user)+1
	endif
	call DisplayTimedTextToPlayer( user,0,0, 30, "|cffFB4915Health: |r"+ RealToString(GetUnitState(Hero[i],UNIT_STATE_LIFE))+" / "+RealToString(BlzGetUnitMaxHP(Hero[i])) + " |c006584edMana: |r" + RealToString(GetUnitState(Hero[i],UNIT_STATE_MANA))+" / "+RealToString(GetUnitState(Hero[i],UNIT_STATE_MAX_MANA)) )
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c00ff0b11Strength: |r" + RealToString(GetHeroStr( Hero[i], true)) + "|c0000ff40 Agility: |r" + RealToString(GetHeroAgi( Hero[i], true)) + "|c000080ff Intelligence: |r"+ RealToString(GetHeroInt( Hero[i], true)) )
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c00800040Regeneration: |r" + RealToString(UnitGetBonus(Hero[i], BONUS_LIFE_REGEN)) + "/sec")
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c00008080Evasion: |r"+ I2S(TotalEvasion[i]) + "%" )
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c00ff8040Physical Damage Taken: |r" + I2S(R2I(DmgTaken[i] * 100 + 0.5)) +"%" )
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c008000ffSpell Damage Taken: |r" + I2S(R2I(SpellTaken[i] * 100 + 0.5)) +"%" )
	if HasShield[i]>0 and GetUnitTypeId(Hero[i])==HERO_ROYAL_GUARDIAN then
		call DisplayTimedTextToPlayer(user, 0, 0, 30, "Shield: " + I2S(HasShield[i]) )
	endif
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c0000ffffSpellboost: |r" + I2S(R2I(BoostValue[i] *100 + 0.5)) +"%" )
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c00ffcc00Gold Rate:|r +" + I2S(ItemGoldRate[i] + Gld_mod[i]) +"%" )
	call ShowExpRate(user,i)
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c00808000Time Played: |r" + I2S(R2I(udg_TimePlayed[i] / 60.)) +" hours and "+ I2S(ModuloInteger(udg_TimePlayed[i], 60)) + " minutes" )
	call DisplayTimedTextToPlayer( user,0,0, 30, "|c00808000Prestige Level: |r"+I2S(LoadInteger(PrestigeRank,i,0)) )
	set user=null
endfunction

function NormalBossHarder takes nothing returns nothing
	call SetHeroStr(GetEnumUnit(),GetHeroStr(GetEnumUnit(),true)*2,true)
	call UnitAddBonus(GetEnumUnit() , BONUS_DAMAGE , R2I( Pow(GetUnitLevel(GetEnumUnit()),1.9) ) )
endfunction

function ResetVote takes nothing returns nothing
	local integer i = 1

	set VoteYay = 0
	set VoteNay = 0

	loop
		exitwhen i > 8
		set I_VOTED[i] = false
		set i = i + 1
	endloop
endfunction

function ApplyHardmode takes nothing returns nothing
    local integer i = 0

	call BlzFrameSetVisible(votingBG, false)
    
    if CWLoading then
        return
    endif

    set HardMode = 1
	set BossDelay = RMinBJ(BossDelay, 0.75)

    call DisplayTimedTextToForce(FORCE_PLAYING, 20, "|cffffcc00The game is now in hard mode: bosses are stronger, respawn faster, and have increased drop rates.|r")
    
    if udg_Chaos_World_On then
        loop
			exitwhen i > CHAOS_BOSS_TOTAL
            if GetWidgetLife(ChaosBoss[i]) >= 0.406 and IsUnitType(ChaosBoss[i], UNIT_TYPE_DEAD) == false then
                call SetHeroStr(ChaosBoss[i], GetHeroStr(ChaosBoss[i], true) * 2, true)
				call BlzSetUnitBaseDamage(ChaosBoss[i], BlzGetUnitBaseDamage(ChaosBoss[i], 0) * 2, 0)
				call SetWidgetLife(ChaosBoss[i], GetWidgetLife(ChaosBoss[i]) + BlzGetUnitMaxHP(ChaosBoss[i]) * 0.5) //heal
            endif
			set i = i + 1
		endloop
    else
        loop
			exitwhen i > BOSS_TOTAL
            if GetWidgetLife(PreChaosBoss[i]) >= 0.406 and IsUnitType(PreChaosBoss[i], UNIT_TYPE_DEAD) == false then
                call SetHeroStr(PreChaosBoss[i], GetHeroStr(PreChaosBoss[i],true) * 2, true)
				call BlzSetUnitBaseDamage(PreChaosBoss[i], BlzGetUnitBaseDamage(PreChaosBoss[i], 0) * 2, 0)
				call SetWidgetLife(PreChaosBoss[i], GetWidgetLife(PreChaosBoss[i]) + BlzGetUnitMaxHP(PreChaosBoss[i]) * 0.5)
            endif
			set i = i + 1
		endloop
    endif
endfunction

function VotingMenu takes nothing returns boolean
	local integer pid = GetPlayerId(GetTriggerPlayer()) + 1

	if I_VOTED[pid] == false then
		set I_VOTED[pid] = true
		return true
	endif

    return false
endfunction

function CheckVote takes nothing returns nothing
	if VOTING_TYPE == 1 then
		if (VoteYay + VoteNay) >= User.AmountPlaying then
			set VOTING_TYPE = 0

			if VoteYay > VoteNay then
				call ApplyHardmode()
			else
				call DisplayTextToForce(FORCE_PLAYING, "Hardmode vote failed.")
			endif
		endif
	elseif VOTING_TYPE == 2 then
		if (VoteYay + VoteNay) >= User.AmountPlaying then
			set VOTING_TYPE = 0

			if VoteYay > VoteNay then
				call DisplayTextToForce(FORCE_PLAYING, User.fromIndex(votekickPlayer - 1).nameColored + " has been kicked from the game.")
				call CustomDefeatBJ(Player(votekickPlayer - 1), "You were vote kicked.")
				call OnDefeat(votekickPlayer)
			else
				call DisplayTextToForce(FORCE_PLAYING, "Votekick vote failed.")
			endif
		endif
	endif
endfunction

function VoteYes takes nothing returns nothing
    set VoteYay = VoteYay + 1

	call CheckVote()

	if GetLocalPlayer() == GetTriggerPlayer() then
		call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
		call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
		call BlzFrameSetVisible(votingBG, false)
	endif
endfunction

function VoteNo takes nothing returns nothing
    set VoteNay = VoteNay + 1

	call CheckVote()

	if GetLocalPlayer() == GetTriggerPlayer() then
		call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
		call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
		call BlzFrameSetVisible(votingBG, false)
	endif
endfunction

function HardmodeVoteExpire takes nothing returns nothing
	call ReleaseTimer(GetExpiredTimer())

	if VOTING_TYPE == 1 then
		call BlzFrameSetVisible(votingBG, false)
		set VOTING_TYPE = 0

		if VoteYay > VoteNay then
			call ApplyHardmode()
		endif
	endif
endfunction

function Hardmode takes nothing returns nothing
	set VOTING_TYPE = 1
	call ResetVote()
	call DisplayTimedTextToForce(FORCE_PLAYING, 30, "Voting for Hardmode has begun and will conclude in 30 seconds.")
	call BlzFrameSetVisible(votingBG, true)
	call BlzFrameSetTexture(votingBG, "war3mapImported\\hardmode.dds", 0, true)

	call TimerStart(NewTimer(), 30, false, function HardmodeVoteExpire)
endfunction

function Votekick takes nothing returns nothing
	local User U = User.first

	call ResetVote()
	set VOTING_TYPE = 2
	set VoteYay = 1
	set VoteNay = 1
	call DisplayTimedTextToForce(FORCE_PLAYING, 30, "Voting to kick player " + User.fromIndex(votekickPlayer - 1).nameColored + " has begun.")
	call BlzFrameSetTexture(votingBG, "war3mapImported\\afkUI_3.dds", 0, true)

	loop
		exitwhen U == User.NULL

		if U.id != votekickPlayer and U.id != votekickingPlayer then
			if GetLocalPlayer() == U.toPlayer() then
				call BlzFrameSetVisible(votingBG, true)
			endif
		endif

		set U = U.next
	endloop
endfunction

function FleeCommand takes player currentPlayer returns nothing
    local integer pid = GetPlayerId(currentPlayer) + 1
	local integer tpid
    local User U = User.first
    
	if InStruggle[pid] or InColo[pid] then
		set udg_Fleeing[pid]=true
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "You will escape once the current wave is complete." )
	elseif IsUnitInGroup(Hero[pid],AzazothPlayers) and GetWidgetLife(ChaosBoss[BOSS_AZAZOTH]) < 0.406 then
		call GroupRemoveUnit(AzazothPlayers,Hero[pid])
		call SetCameraBoundsRectForPlayerEx(currentPlayer, gg_rct_Main_Map_Vision)
		call PanCameraToTimedLocForPlayer(currentPlayer, TownCenter, 0)

        if GetWidgetLife(Hero[pid]) >= 0.406 then
            call SetUnitPositionLoc(Hero[pid], TownCenter)
        elseif IsUnitHidden(HeroGrave[pid]) == false then
            call SetUnitPositionLoc(HeroGrave[pid], TownCenter)
        endif
    elseif GodsParticipant[pid] and DeadGods == 4 then
		set GodsParticipant[pid] = false
		call SetCameraBoundsRectForPlayerEx(currentPlayer, gg_rct_Main_Map_Vision)
		call SetUnitPositionLoc(Hero[pid], TownCenter)
		call PanCameraToTimedLocForPlayer(currentPlayer, TownCenter, 0)
	elseif IsUnitInGroup(Hero[pid], Arena[2]) then
        call GroupRemoveUnit(Arena[2], Hero[pid])
        call SetUnitPositionLoc(Hero[pid], TownCenter)
        call SetCameraBoundsRectForPlayerEx(currentPlayer, gg_rct_Main_Map_Vision)
        call PanCameraToTimedLocForPlayer(currentPlayer, TownCenter, 0)
        set ArenaQueue[pid] = 0
        
        loop
            exitwhen U == User.NULL
			set tpid = GetPlayerId(U.toPlayer()) + 1

            call SetPlayerAllianceStateBJ(U.toPlayer(), Player(pid - 1), bj_ALLIANCE_ALLIED_VISION)
            call SetPlayerAllianceStateBJ(Player(pid - 1), U.toPlayer(), bj_ALLIANCE_ALLIED_VISION)

			if hero_panel_on[pid * 8 + (tpid - 1)] == true then
                call ShowHeroPanel(Player(pid - 1), U.toPlayer(), true)
            endif
        
            if hero_panel_on[tpid * 8 + (pid - 1)] == true then
                call ShowHeroPanel(U.toPlayer(), Player(pid - 1), true)
            endif
            set U = U.next
        endloop
	endif

	call EnterWeather(Hero[pid])
endfunction

function ShowKillCount takes player p, integer q returns nothing
	if KillQuest[q][StringHash("Count")] == KillQuest[q][StringHash("Goal")] then
		call DisplayTimedTextToPlayer(p,0,0,10, KillQuest[q].string[StringHash("Name")] + ": |cff40ff40" + I2S(KillQuest[q][StringHash("Count")]) + "/" +I2S(KillQuest[q][StringHash("Goal")]) + "|r |cffffcc00LVL " + I2S(KillQuest[q][StringHash("Min")]) + "-" + I2S(KillQuest[q][StringHash("Max")]) )
	else
		call DisplayTimedTextToPlayer(p,0,0,10, KillQuest[q].string[StringHash("Name")] + ": " + I2S(KillQuest[q][StringHash("Count")]) + "/" + I2S(KillQuest[q][StringHash("Goal")]) + " |cffffcc00LVL " + I2S(KillQuest[q][StringHash("Min")]) + "-" + I2S(KillQuest[q][StringHash("Max")]) )
	endif
endfunction

function DisplayQuestProgress takes player p returns nothing
local integer i
	if udg_Chaos_World_On then
		set i=13
		loop
			exitwhen i>22
			call ShowKillCount(p,i)
			set i=i+1
		endloop
	else
		set i=1
		loop
			exitwhen i>12
			call ShowKillCount(p,i)
			set i=i+1
		endloop
	endif
endfunction

function MainRepick takes player p returns nothing
    local integer pid = GetPlayerId(p) + 1

    if HeroID[pid] == 0 or IsUnitPaused(Hero[pid]) or GetUnitTypeId(Hero[pid]) == 0 or GetWidgetLife(Hero[pid]) < 0.406 or udg_DashDistance[pid] > 0 then
        call DisplayTextToPlayer(p, 0, 0, "You can't repick right now.")
        return
    elseif RectContainsUnit(gg_rct_Tavern, Hero[pid]) or RectContainsUnit(gg_rct_NoSin, Hero[pid]) or RectContainsUnit(gg_rct_Church, Hero[pid]) then
    else
        call DisplayTextToPlayer(p, 0, 0, "You can only repick in church, town or tavern.")
        return
    endif
    
    call TimerStart(SaveTimer[pid], 1, false, null)
    call SharedRepick(p)
	call SpawnWispSelector(p)
endfunction

function PrestigeStats takes player p, integer pid returns nothing
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "\nPrestige Level: " + I2S(LoadInteger(PrestigeRank,pid,0)) )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Physical Damage Bonus: " + I2S(Dmg_mod[pid])+"%" )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Damage Taken Multipier: " + I2S(R2I(DR_mod[pid]*100.))+"%" )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Strength Bonus: " + I2S(Str_mod[pid])+"%" )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Agility Bonus: " + I2S(Agi_mod[pid])+"%" )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Intelligence Bonus: " + I2S(Int_mod[pid])+"%" )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Spellboost Bonus: " + I2S(Spl_mod[pid])+"%" )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Health Regeneration Bonus: " + I2S(Reg_mod[pid])+"%" )
	call DisplayTimedTextToPlayer(p,0,0, 30.00, "Gold Rate Bonus: " + I2S(Gld_mod[pid])+"%" )
endfunction

function DestroyRB takes nothing returns nothing
	call ReleaseTimer(GetExpiredTimer())
	call DestroyLeaderboard(RollBoard)
	set RollChecks[30] = 0
endfunction

function myRoll takes integer pid returns nothing
	local integer i = 0
	if RollChecks[30] == 0 then
		set RollChecks[30] = 1
		set RollBoard = CreateLeaderboardBJ(FORCE_PLAYING, "Rolls")
		loop
			exitwhen i > 8
			set RollChecks[i] = 0
			set i = i + 1
		endloop
		call LeaderboardSetStyle(RollBoard, true, true, true, false)
		call LeaderboardDisplayBJ(true, RollBoard)
		call TimerStart(NewTimer(), 20., false, function DestroyRB)
	endif

	if (RollChecks[30] > 0) and (RollChecks[pid] == 0) then
		set RollChecks[pid] = 1
		call LeaderboardAddItemBJ(Player(pid - 1), RollBoard, GetPlayerName(Player(pid - 1)), GetRandomInt(i, 100))
		call LeaderboardSortItemsBJ(RollBoard, 0, false)
	endif
endfunction

function CustomCommands takes nothing returns nothing
    local string playerChatString = GetEventPlayerChatString()
    local player currentPlayer = GetTriggerPlayer()
    local integer pid = GetPlayerId(currentPlayer) + 1
    local location loc
    local integer i
    local group ug = CreateGroup()
    local unit target
	local real atkspeed
	local User U = User.first
	
	if (playerChatString == "-cc") or (playerChatString == "-commands") then
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 30, "|cffffcc00Commands are located in F9.|r")
		
	elseif (playerChatString=="-clear") or (playerChatString=="-cl") or (playerChatString=="-clr") then
		if currentPlayer == GetLocalPlayer() then
			call ClearTextMessages()
		endif

	elseif (playerChatString == "-suicide base") or (playerChatString == "-destroy base") or (playerChatString == "-db") then
		if mybase[pid] != null then
			set destroyBaseFlag[pid] = true
			call SetUnitExploded(mybase[pid], true)
			call KillUnit(mybase[pid])
		endif

	elseif (playerChatString == "-suicide") then
		call reselect(Hero[pid])
		call KillUnit(Hero[pid])

	elseif (playerChatString == "-revive") or (playerChatString == "-rv") then
		if IsUnitHidden(HeroGrave[pid]) == false or GetWidgetLife(Hero[pid]) >= 0.406 then
			call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 10, "Unable to revive because your hero isn't dead.")
		else
			call TimerList[pid].stopAllTimersWithTag('dead')
			call RevivePlayer(pid, GetLocationX(TownCenter), GetLocationY(TownCenter), 1, 1)
			call SetCameraBoundsRectForPlayerEx(currentPlayer, gg_rct_Main_Map)
			call PanCameraToTimedLocForPlayer(currentPlayer, TownCenter, 0)
			call DestroyTimerDialog(RTimerBox[pid])
    
			call ChargeNetworth(currentPlayer, 0, 0.01, 50 * GetHeroLevel(Hero[pid]), "Revived instantly for")
		endif

	elseif (SubString(playerChatString,0,5) == "-give") then
		if givecd[pid] then
			call DisplayTextToPlayer(currentPlayer, 0, 0, "You must wait 25 seconds before sending more!")
		else
			call GiveSystem(currentPlayer)
		endif

	elseif (playerChatString == "-proficiency") or (playerChatString == "-pf") then
			call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "|cffffcc00ARMOR:|r")
			if udg_HeroCanUsePlate[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Plate - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Plate - |c00FF0909X|r")
			endif
			if udg_HeroCanUseFullPlate[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Fullplate - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Fullplate - |c00FF0909X|r")
			endif
			if udg_HeroCanUseLeather[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Leather - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Leather - |c00FF0909X|r")
			endif
			if udg_HeroCanUseCloth[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Cloth - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Cloth - |c00FF0909X|r")
			endif
			call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "|cffffcc00WEAPON:|r")
			if udg_HeroCanUseHeavy[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Heavy - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Heavy - |c00FF0909X|r")
			endif
			if udg_HeroCanUseShortSword[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Short Sword - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Short Sword - |c00FF0909X|r")
			endif
			if udg_HeroCanUseDagger[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Dagger - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Dagger - |c00FF0909X|r")
			endif
			if udg_HeroCanUseBow[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Bow - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Bow - |c00FF0909X|r")
			endif
			if udg_HeroCanUseStaff[pid] then
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Staff - |c0000ff33Y|r")
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30, "Staff - |c00FF0909X|r")
			endif

	elseif (SubString(playerChatString,0,6) == "-stats") then
		call StatsInfo(currentPlayer, S2I(SubString(playerChatString,7,8)))
        
    elseif (SubString(playerChatString,0,5) == "-tome") then
        set i = GetHeroStr(Hero[pid],false) +GetHeroAgi(Hero[pid],false) +GetHeroInt(Hero[pid],false)

        call DisplayTextToPlayer(currentPlayer, 0, 0, "|cffffcc00Total Stats:|r " + I2S(i))
        call DisplayTextToPlayer(currentPlayer, 0, 0, "|cffffcc00Tome Cap:|r " + I2S(TomeCap(GetHeroLevel(Hero[pid]))))

	elseif (playerChatString == "-enter") then
		call BeginAzazoth()
        
    elseif (playerChatString == "-r") or (playerChatString == "-ready") then
        if IsPlayerInForce(currentPlayer, QUEUE_GROUP) then
            set QUEUE_READY[pid] = true
        endif
		
	elseif (SubString(playerChatString, 0, 6) == "-color") and S2I(SubString(playerChatString, 7, StringLength(playerChatString))) > 0 and S2I(SubString(playerChatString, 7, StringLength(playerChatString))) < 26 then
		set User[currentPlayer].color = ConvertPlayerColor(S2I(SubString(playerChatString, 7, StringLength(playerChatString))) - 1)
			
	elseif (playerChatString == "-roll") then
		call myRoll(pid)
	
	elseif (playerChatString == "-estats") then
		set atkspeed = 1. / BlzGetUnitAttackCooldown(PlayerSelectedUnit[pid], 0)
		if IsUnitType(PlayerSelectedUnit[pid], UNIT_TYPE_HERO) then
			set atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(PlayerSelectedUnit[pid], true), 400) * 0.01)
		endif

		call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 20, GetUnitName(PlayerSelectedUnit[pid])) 
		call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 20, "Level: " + I2S(GetUnitLevel(PlayerSelectedUnit[pid])) )
		call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 20, "Health: " + RealToString(GetWidgetLife(PlayerSelectedUnit[pid]))+ " / " + RealToString(BlzGetUnitMaxHP(PlayerSelectedUnit[pid])) )
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "|cffffcc00Attack Speed: |r" + R2S(atkspeed) + " attacks per second" )
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "|cffaa2222Regeneration: |r" + R2S(BlzGetUnitRealField(PlayerSelectedUnit[pid], UNIT_RF_HIT_POINTS_REGENERATION_RATE)) + " base health per second" )
	
	elseif (playerChatString == "-pcoins") then
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, PlatTag + I2S(udg_Plat_Gold[pid]))
		
	elseif (playerChatString == "-awood") then
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, ArcTag + I2S(udg_Arca_Wood[pid]))
		
	elseif (playerChatString == "-p") then
		if udg_Plat_Gold[pid]>0 then
			call AddPlatinumCoin(pid, -1)
			call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(currentPlayer,PLAYER_STATE_RESOURCE_GOLD)+1000000)
			call DisplayTimedTextToPlayer( currentPlayer,0,0, 10, PlatTag + I2S(udg_Plat_Gold[pid]) )
		else
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "You need 1 Platinum Coin to buy this" )
		endif
		
	elseif (playerChatString == "-a") then
		if udg_Arca_Wood[pid]>0 then
			call AddArcaditeLumber(pid, -1)
			call SetPlayerState(currentPlayer, PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(currentPlayer,PLAYER_STATE_RESOURCE_LUMBER)+1000000)
			call DisplayTimedTextToPlayer( currentPlayer,0,0, 10, ArcTag + I2S(udg_Arca_Wood[pid]) )
		else
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "You need 1 Arcadite Lumber to buy this" )
		endif
		
	elseif (playerChatString == "-bppc") then
		if udg_PlatConverterBought[pid] then
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "You already purchased this." )
		elseif udg_Plat_Gold[pid]<2 then
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "You need 2 Platinum Coins to buy this" )
		else
			call AddPlatinumCoin(pid, -2)
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "Bought Portable Platinum Coin Converter." )
			set udg_PlatConverter[pid]= true
			set udg_PlatConverterBought[pid]= true
		endif
		
	elseif (playerChatString == "-bpac") then
		if udg_ArcaConverterBought[pid] then
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "You already purchased this." )
		elseif udg_Arca_Wood[pid]<2 then
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "You need 2 Arcadite Lumber to buy this" )
		else
			call AddArcaditeLumber(pid, -2)
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "Bought Arcadite Lumber Converter." )
			set udg_ArcaConverter[pid]= true
			set udg_ArcaConverterBought[pid]= true
		endif
		
	elseif SubString(playerChatString,0,3)=="-pa" or playerChatString=="-cash" then
		set i = S2I(SubString(playerChatString, StringLength(playerChatString) - 1, StringLength(playerChatString)))
		if i > 0 then
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 30, PlatTag + I2S(udg_Plat_Gold[i]) )
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 30, ArcTag + I2S(udg_Arca_Wood[i]) )
		else
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 30, PlatTag + I2S(udg_Plat_Gold[pid]) )
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 30, ArcTag + I2S(udg_Arca_Wood[pid]) )
		endif
		
	elseif (playerChatString == "-xp") then
		call ShowExpRate(currentPlayer, pid)
		
	elseif (playerChatString == "-ms") then
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "Movespeed: "+ I2S(Movespeed[pid]) )

	elseif (playerChatString == "-as") then
		set atkspeed = 1 / BlzGetUnitAttackCooldown(Hero[pid], 0)
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "|cffffcc00Base Attack Speed: |r" + R2S(atkspeed) +" attacks per second" )

		set atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(Hero[pid], true), 400) * 0.01)
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "|cffffcc00Total Attack Speed: |r" + R2S(atkspeed) + " attacks per second.")
    elseif (playerChatString == "-speed") then
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "Movespeed: "+ I2S(Movespeed[pid]) )
		set atkspeed = 1. / BlzGetUnitAttackCooldown(Hero[pid], 0)
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "|cffffcc00Base Attack Speed: |r" + R2S(atkspeed) +" attacks per second" )

		set atkspeed = atkspeed * (1 + IMinBJ(GetHeroAgi(Hero[pid], true), 400) * 0.01)
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "|cffffcc00Total Attack Speed: |r" + R2S(atkspeed) + " attacks per second.")
    elseif (playerChatString == "-actions") then
		call UnitRemoveAbility(Hero[pid], 'A03C')
        call UnitAddAbility(Hero[pid], 'A03C')
    
	elseif (playerChatString == "-flee") then
		call FleeCommand(currentPlayer)
		
	elseif (SubString(playerChatString,0,4) == "-cam") then
		if SubString(playerChatString, StringLength(playerChatString) - 1, StringLength(playerChatString)) == "l" or SubString(playerChatString, StringLength(playerChatString) - 1, StringLength(playerChatString)) == "L" then
			set CameraLock[pid] = true
			set i=S2I(SubString(playerChatString,5, StringLength(playerChatString) - 1))
		else
			set i=S2I(SubString(playerChatString,5, StringLength(playerChatString)))
		endif
		
		if i > 3000 then
			set i = 3000
		elseif i < 100 then
			set i = 100
		endif
		
		call SetCameraFieldForPlayer(currentPlayer, CAMERA_FIELD_TARGET_DISTANCE, i, 0 )
		set udg_Zoom[pid] = i

	elseif (SubString(playerChatString,0,3) == "-aa") then
		if autoAttackDisabled[pid] then
			set autoAttackDisabled[pid] = false
			call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 10, "Toggled Auto Attacking on.")
			call BlzSetUnitWeaponBooleanField(Hero[pid], UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, true)
		else
			set autoAttackDisabled[pid] = true
			call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 10, "Toggled Auto Attacking off.")
			call BlzSetUnitWeaponBooleanField(Hero[pid], UNIT_WEAPON_BF_ATTACKS_ENABLED, 0, false)
		endif

	elseif (SubString(playerChatString,0,3) == "-zm") then
		call SetCameraFieldForPlayer(currentPlayer, CAMERA_FIELD_TARGET_DISTANCE, 2500, 0 )
		set udg_Zoom[pid] = 2500
		if SubString(playerChatString, StringLength(playerChatString) - 1, StringLength(playerChatString)) == "l" or SubString(playerChatString, StringLength(playerChatString) - 1, StringLength(playerChatString)) == "L" then
			set CameraLock[pid] = true
		endif
		
	elseif (playerChatString == "-lock") then
		if udg_Zoom[pid] == 0 then
			set udg_Zoom[pid] = 1650
		endif
		set CameraLock[pid] = true

	elseif (playerChatString == "-unlock") then
		set CameraLock[pid] = false

	elseif (SubString(playerChatString,0,6) == "-price") then
        call DisplayTimedTextToPlayer(currentPlayer,0,0,30, "Upgrade item prices have been moved to \"Item Info\" (hotkey Z + E on your hero).")

	elseif (SubString(playerChatString,0,5) == "-info") then
		call DisplayTimedTextToPlayer(currentPlayer,0,0, 30, infostring[S2I(SubString(playerChatString,6,8))] )
        
    elseif (playerChatString == "-unstuck") then
        call CinematicModeBJ(true, FORCE_PLAYING)
        call TriggerSleepAction(1.0)
        call CinematicModeBJ(false, FORCE_PLAYING)

	elseif (playerChatString=="-st") or (playerChatString=="-savetime") then
        if autosave[pid] then
            call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, "Your next autosave is in " + RemainingTimeString(SaveTimer[pid]) + ".")
        elseif udg_Hardcore[pid] then
            call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, RemainingTimeString(SaveTimer[pid]) + " until you can save again.")
        endif
        
    elseif (SubString(playerChatString, 0, 5) == "-save") then
        if GetWidgetLife(Hero[pid]) < 0.406 then
            call DisplayTextToPlayer(currentPlayer, 0, 0, "You cannot do this while dead!")
        elseif TimerGetRemaining(SaveTimer[pid]) > 1 and udg_Hardcore[pid] then
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 20, RemainingTimeString(SaveTimer[pid]) + " until you can save again." )
        elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) == false and udg_Hardcore[pid] then
            call DisplayTimedTextToPlayer(currentPlayer,0,0, 30, "|cffFF0000You're playing in hardcore mode, you may only save inside the church in town.|r")
		else
			call ActionSave(currentPlayer)
		endif
        
    elseif (SubString(playerChatString, 0, 9) == "-autosave") then
        if not autosave[pid] then
            set autosave[pid] = true
            call DisplayTextToPlayer(currentPlayer, 0, 0, "|cffffcc00Autosave is now enabled -- you will save every 30 minutes or when your next save is available as Hardcore.|r")
            call TimerStart(SaveTimer[pid], 1800, false, null)
        else
            set autosave[pid] = false
            call DisplayTextToPlayer(currentPlayer, 0, 0, "|cffffcc00Autosave disabled.|r")
        endif

	elseif (playerChatString == "-forcesave") or (playerChatString == "-saveforce") then
        if GetWidgetLife(Hero[pid]) < 0.406 then
            call DisplayTextToPlayer(currentPlayer, 0, 0, "You cannot do this while dead!")
        elseif InCombat(Hero[pid]) then
            call DisplayTextToPlayer(currentPlayer, 0, 0, "You cannot do this while in combat!")
        elseif isteleporting[pid] then
            call DisplayTextToPlayer(currentPlayer, 0, 0, "You cannot do this while teleporting!")
        elseif RectContainsCoords(gg_rct_Church, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) or RectContainsCoords(gg_rct_Tavern, GetUnitX(Hero[pid]), GetUnitY(Hero[pid])) then
            call ActionSaveForce(currentPlayer, false)
        else
            call ActionSaveForce(currentPlayer, true)
        endif
        
    elseif (playerChatString == "-cancel") then
        if forceSaving[pid] then
            set forceSaving[pid] = false
            set isteleporting[pid] = false
            call PauseUnit(Hero[pid], false)
            call PauseUnit(Backpack[pid], false)
            if (GetLocalPlayer() == currentPlayer) then
                call ClearTextMessages()
            endif
        endif
        
    elseif (SubString(playerChatString, 1, StringLength(playerChatString)) == forceString[pid]) and forceSaving[pid] then
        call SaveForceRemove(currentPlayer)

	elseif ( SubString(playerChatString, 0, 9) == "-HardMode" ) or ( SubString(playerChatString, 0, 9) == "-hardmode" ) then
		if HardMode > 0 then
			call DisplayTimedTextToPlayer(GetTriggerPlayer(), 0, 0, 5, "|cffffcc00Hard mode is already active.|r")
		else
			if VOTING_TYPE == 0 then
				call Hardmode()
			endif
		endif

	elseif ( SubString(playerChatString, 0, 9) == "-votekick" ) then
		if VOTING_TYPE == 0 and User.AmountPlaying > 2 then
			call DialogClear(votekickpanel[pid])
			
			loop
				exitwhen U == User.NULL
				
				if pid != U.id then
					set votekickpanelbutton[pid * 8 + U.id] = DialogAddButton(votekickpanel[pid], GetPlayerName(U.toPlayer()), 0)
				endif

				set U = U.next
			endloop
			
			call DialogAddButton(votekickpanel[pid], "Cancel", 0)
			call DialogDisplay(currentPlayer, votekickpanel[pid], true)
		endif

	elseif (playerChatString == "-repick") then
        if Profiles[pid].getSlotsUsed() >= 30 then
            call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 30.0, "You cannot save more than 30 heroes!")
        else
			call MainRepick(currentPlayer)
		endif

	elseif (playerChatString == "-prestige me") or (playerChatString == "-activate prestige") then
        call DisplayTimedTextToPlayer(currentPlayer, 0,0, 10, "To prestige you must acquire a |cffffcc00Prestige Token|r and redeem it at the church bishop.")

	elseif (playerChatString == "-prestige info") or (playerChatString == "-pinfo") then
		call PrestigeStats(currentPlayer,pid)
		
	elseif (playerChatString == "-pcoff") or (playerChatString == "-platinum converter off") then
		if udg_PlatConverterBought[pid] then
			set udg_PlatConverter[pid]= false
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "Platinum converter off." )
		else
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "You have not bought a Platinum Converter." )
		endif
        
    elseif (SubString(playerChatString, 0, 2) == "-n") and (SubString(playerChatString, 2, 4) == "ew") then
        call OnNewProfile(currentPlayer)

	elseif (playerChatString == "-pcon") or (playerChatString == "-platinum converter on") then
		if udg_PlatConverterBought[pid] then
			set udg_PlatConverter[pid]= true
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "Platinum converter on." )
		else
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "You have not bought a Platinum Converter." )
		endif
		
	elseif (playerChatString == "-acoff") or (playerChatString == "-arcadite converter off") then
		if udg_ArcaConverterBought[pid] then
			set udg_ArcaConverter[pid]= false
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "arcadite converter off." )
		else
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "You have not bought an Arcadite Converter." )
		endif
		
	elseif (playerChatString == "-acon") or (playerChatString == "-arcadite converter on") then
		if udg_ArcaConverterBought[pid] then
			set udg_ArcaConverter[pid]= true
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "arcadite converter on." )
		else
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "You have not bought an Arcadite Converter." )
		endif

	elseif (playerChatString == "-q") or (playerChatString == "-quests") then
		call DisplayQuestProgress(currentPlayer)

	elseif S2I(SubString(playerChatString, 1, 5)) > 999 then
		if afkTextVisible[pid] then
			if S2I(SubString(playerChatString, 1, 5)) == afkInt then
                set afkTextVisible[pid] = false
				if GetLocalPlayer() == currentPlayer then
					call BlzFrameSetVisible(afkTextBG, false)
				endif
                call SoundHandler("Sound\\Interface\\GoodJob.wav", currentPlayer)
			else
				call DisplayTimedTextToPlayer(currentPlayer, 0, 0, 10, "|cffff0000ERROR: Incorrect|r")
			endif
		endif
		
	elseif (playerChatString == "-nohints") or (playerChatString == "-hints") then
		if IsPlayerInForce(currentPlayer, hintplayers) then
			call ForceRemovePlayer(hintplayers, currentPlayer)
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "Hints turned off.")
		else
			call ForceAddPlayer(hintplayers, currentPlayer)
			call DisplayTimedTextToPlayer(currentPlayer,0,0, 10, "Hints turned on.")
		endif

	elseif (playerChatString == "-deleteallmymoney") then
        call SetPlayerGold( currentPlayer, 0)
        call SetPlayerLumber( currentPlayer, 0)
		call AddPlatinumCoin(pid, -udg_Plat_Gold[pid])
		call AddArcaditeLumber(pid, -udg_Arca_Wood[pid])
		call AddCrystals(pid, -udg_Crystals[pid])
		set udg_TimePlayed[pid] = 0
	endif

	call DestroyGroup(ug)
	
	set ug = null
	set loc = null
	set target = null
endfunction

//===========================================================================
function CommandsInit takes nothing returns nothing
    local trigger commands = CreateTrigger()
    local trigger give = CreateTrigger()
    local User u = User.first
	
	loop
		exitwhen u == User.NULL
        set GiveDialog[GetPlayerId(u.toPlayer()) + 1] = DialogCreate()
        call TriggerRegisterDialogEvent(give, GiveDialog[GetPlayerId(u.toPlayer()) + 1])
		call TriggerRegisterPlayerChatEvent(commands, u.toPlayer(), "-", false)
		set u = u.next
	endloop

	call TriggerAddAction(commands, function CustomCommands)
    call TriggerAddAction(give, function GiveClick)
    
    set commands = null
    set give = null
endfunction

endlibrary
