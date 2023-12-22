library CodeGen initializer init

    globals
        private string ALPHABET = "!#$%&'()*+,-.0123456789:;=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}`"
        private integer BASE 
        private string array CHAR
        private integer MAXVALUE = 7
        private boolean VALID
        private string ERROR = ""
        integer array SAVECOUNT
    endglobals

    function GetCodeGenError takes nothing returns string
        return ERROR
    endfunction

    private function init takes nothing returns nothing
        local integer i = 1
        local integer b = StringLength(ALPHABET)
        local integer m = MAXVALUE

        loop
            exitwhen i >= MAXVALUE
            set CHAR[i] = SubString(ALPHABET, i, i + 1)
            set i = i + 1
        endloop

        set ALPHABET = SubString(ALPHABET, 0, 1) + SubString(ALPHABET, m + 1, b)
        set BASE = b - m
    endfunction

    function Encode takes integer i returns string
        local integer b
        local string s = ""
        
        if i < BASE then
            return SubString(ALPHABET, i, i + 1)
        endif
        
        loop
            exitwhen i <= 0
            set b = i - (i / BASE) * BASE
            set s = SubString(ALPHABET, b, b + 1) + s
            set i = i / BASE
        endloop
        
        return s
    endfunction

    function StrPos takes string s returns integer
        local integer i = 0
        loop
            exitwhen i >= BASE
            if s == SubString(ALPHABET, i, i + 1) then
                return i
            endif
            set i = i + 1
        endloop
        return -1
    endfunction

    function Decode takes string s returns integer
        local integer a = 0
        
        loop
            exitwhen StringLength(s) == 1
            set a = a * BASE + BASE * StrPos(SubString(s, 0, 1))
            set s = SubString(s, 1, 99)
        endloop
        
        return a + StrPos(s)
    endfunction

    function StringChecksum takes string in returns integer
        local integer i = 0
        local integer l = StringLength(in)
        local integer t = 0
        local integer o = 0
        loop
            exitwhen i >= l
            set t = Decode(SubString(in, i, i + 1))
            set o = o + t
            set i = i + 1
        endloop
        return o
    endfunction

    // yeeahh descriptive variables
    function Load takes string str, player p returns boolean
        local string tmp = ""
        local string c   = ""
        local integer x  = 0
        local integer i  = 1
        local integer l  = 0
        local integer j  = 1
        local integer f  = 0
        local boolean b  = true
        local integer pid = GetPlayerId(p) + 1
        
        set VALID = false
        
        loop
            exitwhen i > 3
            if (Decode(SubString(str, 0, i)) == StringChecksum(SubString(str, i, 999))) then
                set VALID = true
                set str = SubString(str, i, 999)
                set i = 4
            endif
            set i = i + 1
        endloop
        
        if (not VALID) then
            set ERROR = "Invalid code"
            return VALID
        endif
        
        set i = 0
        set l = StringLength(str)
        
        set c = Encode(StringChecksum(GetPlayerName(p)))
        set i = StringLength(c)
        if (c != SubString(str, l - i, i)) then
            set VALID = false
            set ERROR = "Invalid code"
            return VALID
        endif
        set l = l - i
        
        set i = 0
        
        loop
            exitwhen i >= l
            set tmp = SubString(str, i, i + 1)
            
            set b = true
            set f = 0
            set j = 1
            
            loop
                exitwhen f >= (MAXVALUE)
                if (tmp == CHAR[f]) then
                    set j = f + 2
                    call SaveInteger(SaveData, pid, x, Decode(SubString(str, i + 1, i + (j))))
                    set b = false
                    set f = MAXVALUE
                endif
                set f = f + 1
            endloop
            
            if (b) then
                call SaveInteger(SaveData, pid, x, Decode(tmp))
            endif
            
            set i = i + j
            set x = x + 1
        endloop
        
        set VALID = true

        return VALID
    endfunction

    function Compile takes integer pid returns string
        local integer i  = 0
        local integer j  = 0
        local string out = ""
        local string ln  = ""
        local string x   = ""
        local player p = Player(pid - 1)

        loop
            exitwhen i > SAVECOUNT[pid]
            set x = Encode(LoadInteger(SaveData, pid, i)) 
            set j = StringLength(x)

            if (j > 1) then
                set out = out + CHAR[j-1]
            endif
            
            set out = out + x
            set i = i + 1
        endloop

        call FlushChildHashtable(SaveData, pid)

        set out = out + Encode(StringChecksum(GetPlayerName(p)))
        
        set out = Encode(StringChecksum(out)) + out
        
        return out
    endfunction
endlibrary
