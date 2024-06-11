--[[
    codegen.lua

    Credits: Original JASS by TriggerHappy

    This module provides functions to encode a table of integers into one string of characters that may be decoded and loaded in future games.
    Used for save / load functionality in playerdata.lua
]]

OnInit.global("CodeGen", function()
    local ALPHABET        = "!#$\x25&'()*+,-.0123456789:;=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_abcdefghijklmnopqrstuvwxyz{|}`" ---@type string 
    local ERROR           = ""
    local MAX_SPACE       = 6
    local BASE            = ALPHABET:len() - MAX_SPACE - 1
    local CHAR            = ALPHABET:sub(2, MAX_SPACE + 1)
    ALPHABET              = ALPHABET:sub(1, 1) .. ALPHABET:sub(MAX_SPACE + 2)

    ---@return string
    function GetCodeGenError()
        return ERROR
    end

    ---@param i integer
    ---@return string
    function Encode(i)
        local s = ""

        if i < BASE then
            return ALPHABET:sub(i + 1, i + 1)
        end

        while i > 0 do
            local b = i - (i // BASE) * BASE
            s = ALPHABET:sub(b + 1, b + 1) .. s
            i = i // BASE
        end

        return s
    end

    ---@param s string
    ---@return integer
    local function StrPos(s)
        local pos = ALPHABET:find(s, 1, true)

        if pos then
            return pos - 1
        end

        return -1
    end

    ---@param s string
    ---@return integer
    function Decode(s)
        local a = 0 ---@type integer 

        while s:len() ~= 1 do
            a = a * BASE + BASE * StrPos(s:sub(1, 1))
            s = s:sub(2)
        end

        return a + StrPos(s)
    end

    ---@param in_ string
    ---@return integer
    local function StringChecksum(in_)
        local o = 0 ---@type integer 

        for i = 1, in_:len() do
            o = o + Decode(in_:sub(i, i))
        end

        return o
    end

    ---@type fun(str: string, p: player): boolean|table
    function Load(str, p)
        local VALID = false

        for i = 1, 3 do
            if DEV_ENABLED then
                print("Decode checksum: " .. Decode(str:sub(1, i)) .. " " .. str:sub(1, i))
                print("Checksum " .. i .. ": " .. StringChecksum(str:sub(i + 1)) .. " " .. str:sub(i + 1))
            end

            if Decode(str:sub(1, i)) == StringChecksum(str:sub(i + 1)) then
                VALID = true
                str = str:sub(i + 1)
                break
            end
        end

        local checksum = Encode(StringChecksum(GetPlayerName(p)))
        local checksum_len = checksum:len()

        if (not VALID) or checksum ~= str:sub(-checksum_len) then
            ERROR = "Invalid code"
            return false
        end

        str = str:sub(1, -checksum_len - 1)
        local data = {}
        i = 1

        while i <= #str do
            local tmp = str:sub(i, i)
            local token_length = (CHAR:find(tmp) or 0) + 1

            --ignore space indicator
            if token_length > 1 then
                i = i + 1
            end

            local token = str:sub(i, i + token_length - 1)
            data[#data + 1] = Decode(token)
            i = i + token_length
        end

        return data
    end

    ---@type fun(pid: integer, data: table): string
    function Compile(pid, data)
        local out = "" ---@type string 
        local p   = Player(pid - 1) ---@type player 

        for _, v in ipairs(data) do
            local x = Encode(v)
            local j = x:len()

            if (j > 1) then
                out = out .. CHAR:sub(j - 1, j - 1)
            end

            out = out .. x
        end

        --appends player name checksum to end of string
        out = out .. Encode(StringChecksum(GetPlayerName(p)))

        --appends total checksum to beginning of string
        local cs = StringChecksum(out)
        out = Encode(cs) .. out

        if DEV_ENABLED then
            print("Checksum: " .. cs .. " Encoded: " .. Encode(cs))
        end

        return out
    end

end, Debug.getLine())
