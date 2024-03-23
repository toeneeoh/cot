--[[
    codegen.lua

    Credits: Original JASS by TriggerHappy

    This module provides functions to encode a table of integers into one string of characters that may be decoded and loaded in future games.
    Used for save / load functionality in playerdata.lua
]]

if Debug then Debug.beginFile 'CodeGen' end

OnInit.global("CodeGen", function()

    SaveData = {} ---@type table

    local ALPHABET        = "!#$\x25&'()*+,-.0123456789:;=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}`" ---@type string 
    local BASE ---@type integer 
    local CHAR=__jarray("") ---@type string[] 
    local MAXVALUE         = 7 ---@type integer 
    local VALID ---@type boolean 
    local ERROR        = "" ---@type string 

    ---@return string
    function GetCodeGenError()
        return ERROR
    end

    ---@param i integer
    ---@return string
    function Encode(i)
        local b ---@type integer 
        local s        = "" ---@type string 

        if i < BASE then
            return SubString(ALPHABET, i, i + 1)
        end

        while i > 0 do
            b = i - (i // BASE) * BASE
            s = SubString(ALPHABET, b, b + 1) .. s
            i = i // BASE
        end

        return s
    end

    ---@param s string
    ---@return integer
    local function StrPos(s)
        local i         = 0 ---@type integer 
        while i < BASE do
            if s == SubString(ALPHABET, i, i + 1) then
                return i
            end
            i = i + 1
        end
        return -1
    end

    ---@param s string
    ---@return integer
    function Decode(s)
        local a         = 0 ---@type integer 

        while not (StringLength(s) == 1) do
            a = a * BASE + BASE * StrPos(SubString(s, 0, 1))
            s = SubString(s, 1, 99)
        end

        return a + StrPos(s)
    end

    ---@param in_ string
    ---@return integer
    local function StringChecksum(in_)
        local i         = 0 ---@type integer 
        local l         = StringLength(in_) ---@type integer 
        local t         = 0 ---@type integer 
        local o         = 0 ---@type integer 
        while i < l do
            t = Decode(SubString(in_, i, i + 1))
            o = o + t
            i = i + 1
        end
        return o
    end

    -- yeeahh descriptive variables
    ---@type fun(str: string, p: player): boolean
    function Load(str, p)
        local pid = GetPlayerId(p) + 1 ---@type integer 

        VALID = false

        for i = 1, 3 do
            if (Decode(SubString(str, 0, i)) == StringChecksum(SubString(str, i, 999))) then
                VALID = true
                str = SubString(str, i, 999)
                break
            end
        end

        if (not VALID) then
            ERROR = "Invalid code"
            return VALID
        end

        local l = StringLength(str)
        local c = Encode(StringChecksum(GetPlayerName(p)))
        local i = StringLength(c)

        if (c ~= SubString(str, l - i, i)) then
            VALID = false
            ERROR = "Invalid code"
            return VALID
        end

        l = l - i
        i = 0
        local data = {}

        while i < l do
            local tmp = SubString(str, i, i + 1)
            local b = true
            local f = 0
            local j = 1

            while not (f >= (MAXVALUE)) do
                if (tmp == CHAR[f]) then
                    j = f + 2
                    data[#data + 1] = Decode(SubString(str, i + 1, i + (j)))
                    b = false
                    f = MAXVALUE
                end
                f = f + 1
            end

            if (b) then
                data[#data + 1] = Decode(tmp)
            end

            i = i + j
        end

        SaveData[pid] = data
        VALID = true

        return VALID
    end

    ---@type fun(pid: integer, data: table): string
    function Compile(pid, data)
        local j   = 0 ---@type integer 
        local out = "" ---@type string 
        local x   = "" ---@type string 
        local p   = Player(pid - 1) ---@type player 

        for _, v in ipairs(data) do
            x = Encode(v)
            j = StringLength(x)

            if (j > 1) then
                out = out .. CHAR[j - 1]
            end

            out = out .. x
        end

        out = out .. Encode(StringChecksum(GetPlayerName(p)))

        out = Encode(StringChecksum(out)) .. out

        return out
    end

        local b = StringLength(ALPHABET) ---@type integer 
        local m = MAXVALUE ---@type integer 

        for i = 1, MAXVALUE - 1 do
            CHAR[i] = SubString(ALPHABET, i, i + 1)
        end

        ALPHABET = SubString(ALPHABET, 0, 1) .. SubString(ALPHABET, m + 1, b)
        BASE = b - m
end)

if Debug then Debug.endFile() end
