--https://github.com/user-none/lua-nums
--[[
MIT License

Copyright (c) 2016 John Schember

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]

local math = math

local M = {}
local M_mt = {}

---@class BigNum
---@field new function
---@field asbytearray function
---@field asbytestring function
---@field copy function
---@field abs function
---@field remain function
---@field len_bits function
---@field len_bytes function
---@field len_digits function
---@field set function
---@field ashex function
---@field asnumber function
---@field isbn function
BigNum = M

local DIGIT_BITS
local DIGIT_MASK
local DIGIT_MAX
local DIGIT_CMASK

do
    local x = 1
    local y = 0
    local z = 0
    while x > z do
        z = x
        x = x << 1
        y = y + 1
    end
    DIGIT_BITS = ((y - 1)//2) - 1 -- Gives us 30 bits with Lua 5.3.
    DIGIT_MASK = (1 << DIGIT_BITS) - 1
    DIGIT_MAX = DIGIT_MASK
    -- Carry needs to be 1 bit more than the digit because a carry will fill the
    -- next bit. Carry is always 1 bit more than DIGIT_BITS. We'll need to bring
    -- negative numbers back into range when dealing with subtraction.
    DIGIT_CMASK = (1 << (DIGIT_BITS + 1)) - 1
end

-- [R]RMAP is used for converting between BN and strings. The map only supports
-- base 10 and base 16. These can be expanded out to say base 64 by adding the
-- additional digits in the base to the maps.
local RMAP = {
    ["0"] = 0, ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5,
    ["6"] = 6, ["7"] = 7, ["8"] = 8, ["9"] = 9, ["A"] = 10, ["B"] = 11,
    ["C"] = 12, ["D"] = 13, ["E"] = 14, ["F"] = 15
}

local RRMAP = {
    "0", "1", "2", "3", "4", "5", "6", "7",
    "8", "9", "A", "B", "C", "D", "E", "F"
}

local function expand_num(a, num)
    while #a._digits < num do
        a._digits[#a._digits+1] = 0
    end
end

local function expand(a, b)
    -- Expand to a given number of digits.

    if type(b) == "number" then
        expand_num(a, b)
        return
    end

    -- Expand to the larger of a or b's digits.
    if #a._digits >= #b._digits then
        expand_num(b, #a._digits)
    else
        expand_num(a, #b._digits)
    end

end

local function reduce(a)
    -- Ensure the BN is never empty.
    if #a._digits == 0 then
        a._pos = true
        a._digits = { 0 }
        return
    end

    -- Check for and remove excess 0's
    for i=#a._digits,2,-1 do
        if a._digits[i] ~= 0 then
            break
        end
        table.remove(a._digits, i)
    end

    if #a._digits == 1 and a._digits[1] == 0 then
        a._pos = true
    end
end

local function reset(a)
    a._digits = { 0 }
    a._pos = true
end

local function get_input(a)
    if M.isbn(a) then
        a = a:copy()
    else
        a = M:new(a)
    end
    return a
end

local function get_inputs(a, b)
    a = get_input(a)
    b = get_input(b)
    return a, b
end

local function is_pos(a, b)
    if a._pos == b._pos then
        return true
    end
    return false
end

local function lshiftd(a, b)
    a = get_input(a)

    if b == 0 then
        return a
    end
    -- Insert 0's at the beginning of the list which is the least significant
    -- digit.
    for i=1,b do
        table.insert(a._digits, 1, 0)
    end
    reduce(a)
    return a
end

local function rshiftd(a, b)
    if b == 0 then
        return a
    elseif b >= #a._digits then
        return M:new()
    end
    -- Remove digits from the beginning.
    for _ = 1, b do
        table.remove(a._digits, 1)
    end
    reduce(a)
    return a
end

local function add_int(a, b)
    local c = M:new()
    local u = 0

    expand(a, b)

    for i=1,#a._digits do
        -- Add the digits and the carry.
        c._digits[i] = a._digits[i] + b._digits[i] + u
        -- Calculate carry buy pulling it off the top of the digit.
        u = c._digits[i] >> DIGIT_BITS
        -- Reduce the digit to the proper size by removing the carry.
        c._digits[i] = c._digits[i] & DIGIT_MASK
    end

    -- Add the final carry if we have one.
    if u ~= 0 then
        c._digits[#c._digits+1] = u
    end

    reduce(c)
    return c
end

local function sub_int(a, b)
    local c = M()
    local u = 0

    expand(a, b)

    for i=1,#a._digits do
        -- Subtract the digits and the carry.
        -- If there is a carry we've gone negative. Mask it to get a positive
        -- number with the carry bit set. All digits are unsigned values. If
        -- this was C and we were using an unsigned 32 bit integer as the digit
        -- type then it would handle wrapping internally. However, Lua doesn't
        -- have fixed size unsigned types so we need to handle wrapping.
        c._digits[i] = (a._digits[i] - b._digits[i] - u) & DIGIT_CMASK
        -- Calculate carry buy pulling it off the top of the digit.
        u = c._digits[i] >> DIGIT_BITS
        -- Reduce the digit to the proper size by removing the carry.
        c._digits[i] = c._digits[i] & DIGIT_MASK
    end

    reduce(c)
    return c
end

local function bitwise_int(a, b, op)
    local new_a, new_b = M:new(a), M:new(b)
    expand(new_a, new_b)

    local c = M:new()
    expand(c, new_a)
    for i=1,#new_a._digits do
        c._digits[i] = op(new_a._digits[i], new_b._digits[i])
    end

    reduce(c)
    return c
end

local function div_remain(a, b)
    local qpos
    local rpos

    local new_a, new_b = M:new(a), M:new(b)
    if new_a == M.ZERO then
        return M:new(), M:new()
    elseif new_b == M.ZERO then
        return nil, "divide by 0"
    elseif new_b == M:new(1) then
        return new_a, M:new()
    end

    -- The quotient's sign is based on the sign of the dividend and divisor.
    -- Standard pos and pos = pos, neg and neg = pos, pos and neg = neg.
    qpos = is_pos(new_a, new_b)
    -- Technically the remainder can't be negative. However, it is possible
    -- to provide either a positive or a negative remainder. We'll use C99
    -- rules for the remainder where it is aways the sign of the dividend.
    rpos = new_a._pos
    -- Set a and b to positive because the division algorithm only works with
    -- positive numbers.
    new_a._pos = true
    new_b._pos = true

    -- loop though every bit. len_bits gives us a total and we need to loop
    -- by bit position (index) so subtract 1. E.g. (1 << 0) is the first bit.
    --
    -- Note that when we do (1 << e) the 1 needs to be converted to a BN
    -- because 1 << 86 will most likely be larger than a native number can
    -- hold.
    local e = new_a:len_bits() - 1
    -- r is the remainder after an operation and when we drop down to the next
    -- level (long division) we will add it to the value we're pulling down.
    -- Once r is larger than the divisor it gets moved to the quotient.
    local r = M:new()
    local q = M:new()
    while e >= 0 do
        -- r is the remainder and it's also used for the drop down add.
        -- Shift it left one digit so it's the next field larger for the top.
        r = r << 1
        -- Check if there is a bit set at this position in the dividend.
        -- If so we set the first bit in r as the drop down and add part.
        if new_a & (M:new(1) << e) > 0 then
            r = r | 1
        end
        -- If r is larger than the divisor then we set r to the difference
        -- and add the difference to the quotient.
        if r >= new_b then
            r = r - new_b
            q = q | (M:new(1) << e)
        end
        e = e - 1
    end

    q._pos = qpos
    if r ~= 0 then
        r._pos = rpos
    end

    reduce(q)
    reduce(r)
    return q, r
end

local function set_string(s, n)
    local u
    local c
    local b
    local base = 10

    -- Convert the number to a string and remove any decimal portion. We're
    -- using 0 truncation so it doesn't matter what's there.
    n = tostring(n)
    n = n:gsub("%.%d*", "")
    n = n:gsub("U?L?L?$", "")

    -- Nothing left so assume 0.
    if n == "" then
        return true
    end

    -- Check if the number is negative.
    if n:sub(1, 1) == "-" then
        s._pos = false
        n = n:sub(2)
    end

    -- Convert to uppercase so we can have one check for the hex prefix. If
    -- it's a hex number change the base to 16 and remove the prefix.
    n = n:upper()
    if n:sub(1, 2) == "0X" then
        base = 16
        n = n:sub(3)
    end

    -- Go though each digit in the string from most to least significant.
    -- We're using single digit optimizations for multiplication and division
    -- because: 1. It gives us a performance boost since base will never be
    -- a BN. 2. We can't use the BN's __mul and __add functions because those
    -- call get_input(s) which in turn call :set. Infinite loops are bad.
    --
    -- The process here is set the digit, multiply by base to move it over.
    -- Add the next and repeat until we're out of digits.
    for i=1,#n do
        -- Take the current digit and get the numeric value it corresponds to.
        c = n:sub(i, i)
        b = RMAP[c]
        if b == nil then
            reset(s)
            return false
        end

        -- Multiply by base so we can move what we already have over to the
        -- make room for adding the next digit.
        u = 0
        for i=1,#s._digits do
            s._digits[i] = (s._digits[i] * base) + u
            u = s._digits[i] >> DIGIT_BITS
            s._digits[i] = s._digits[i] & DIGIT_MASK
        end
        if u ~= 0 then
            s._digits[#s._digits+1] = u
        end

        -- Add the digit.
        s._digits[1] = s._digits[1] + b
        u = s._digits[1] >> DIGIT_BITS
        s._digits[1] = s._digits[1] & DIGIT_MASK
        -- Handle the carry from the add.
        for i=2,#s._digits do
            if u == 0 then
                break
            end
            s._digits[i] = s._digits[i] + u
            u = s._digits[i] >> DIGIT_BITS
            s._digits[i] = s._digits[i] & DIGIT_MASK
        end
        if u ~= 0 then
            s._digits[#s._digits+1] = u
        end
    end

    reduce(s)
    return true
end

local function set_number(s, n)
    n = math.floor(n)

    if n >= -DIGIT_MAX and n <= DIGIT_MAX then
        if n < 0 then
            n = -n
            s._pos = false
        end

        s._digits[1] = n
        return true
    end

    set_string(s, n)
    return true
end

--- Copy the value of a into b
local function copy_bn(a, b)
    b._pos = a._pos
    b._digits = {}

    for i=1,#a._digits do
        b._digits[i] = a._digits[i]
    end
end

local function tostring_int(a, base)
    local t = ""

    if #a._digits == 1 and a._digits[1] == 0 then
        return "0"
    end

    if base ~= 10 and base ~= 16 then
        return nil, "base not supported"
    end

    local pos = a._pos
    local new_a = M:new(a)

    -- Integer division using digits. We don't want to use div_remain and BN
    -- division because that would be really slow. We can't use this method
    -- with BN's because we can only divide by amounts as large as a digit.
    -- This is fine for base because even with a 7 bit digit we an still
    -- have base be up to a 127. Really 64 is probably the largest we'd ever
    -- need in the real world.
    --
    -- This is the same div mod principal as this:
    --      local num = 1230
    --      local b = ""
    --      while num > 0 do
    --          b = tostring(num%10)..b
    --          num = num//10
    --      end
    --      print(type(b), b)
    while (#new_a._digits > 1 or new_a._digits[1] ~= 0) do
        local b = M:new()
        expand(b, new_a)
        local w = 0
        -- We are going to divide by base and each division we'll get a value
        -- with one few digit in the base. We will keep replacing a with the
        -- one digit less value and keep dividing until we've gone though all
        -- digits.
        for i=#new_a._digits,1,-1 do
            local u = 0
            -- Push the digit and the remainder from the last
            -- together.
            w = (w << DIGIT_BITS) | new_a._digits[i]
            if w >= base then
                -- If the remainder is now larger than or equal to base we need
                -- to divide the digit by the base. Then reduce the remainder
                -- down so we have the new remainder.
                u = w // base
                w = w - (u * base)
            end
            -- Save the divided digit value.
            b._digits[i] = u
        end
        -- The remainder from this run is the numeric for the base digit in
        -- the string. Pull the digit out of the map.
        t = RRMAP[w+1] .. t
        -- Update a so we can divide again to get the next digit.
        new_a = b
        reduce(new_a)
    end

    if not pos then
        t = "-" .. t
    end

    return t
end

-- Most of the metatable operations take two inputs (a and b). One will be a BN
-- but the other might not. It could be a string, number... The input's will be
-- converted into a BN if they're not. Also, copies will be used. The input is
-- never modified in place and the result will always return an new BN.
--
-- Operations with one input are going to be a BN. We don't need to verify and
-- create a BN but instead we just copy it if we need to make modifications
-- during the operation.
M_mt.__index = M
M_mt.__add =
    -- Addition is only implemented as unsigned. We'll use addition or
    -- subtraction as needed based on certain satiations. The proper sign will
    -- be set based on these condition.
    function(a, b)
        local c
        local new_a, new_b = M:new(a), M:new(b)
        local apos = new_a._pos
        local bpos = new_b._pos

        new_a._pos = true
        new_b._pos = true

        if apos == bpos then
            c = add_int(new_a, new_b)
            c._pos = apos
        elseif new_a < new_b then
            c = sub_int(new_b, new_a)
            c._pos = bpos
        else
            c = sub_int(new_a, new_b)
            c._pos = apos
        end

        return c
    end
M_mt.__sub =
    -- Subtraction is only implemented as unsigned. We'll use addition or
    -- subtraction as needed based on certain satiations. The proper sign will
    -- be set based on these condition.
    function(a, b)
        local c
        local new_a, new_b = M:new(a), M:new(b)
        local apos = new_a._pos
        local bpos = new_b._pos

        new_a._pos = true
        new_b._pos = true

        if apos ~= bpos then
            c = add_int(new_a, new_b)
            c._pos = apos
        elseif new_a >= new_b then
            c = sub_int(new_a, new_b)
            c._pos = apos
        else
            c = sub_int(new_b, new_a)
            c._pos = not apos
        end

        return c
    end
M_mt.__mul =
    -- Base line multiplication like taught in grade school. Multiply across,
    -- then drop down and multiply the next digit. Add up all the columns to
    -- get the result.
    function(a, b)
        local new_a, new_b = M:new(a), M:new(b)
        local c = M:new()
        c._pos = is_pos(new_a, new_b)

        -- Multiplication should only have a + b digits plus 1
        -- for the carry.
        expand(c, #new_a._digits + #new_b._digits + 1)

        for i = 1,#new_a._digits do
            local u = 0

            for y = 1,#new_b._digits do
                -- Digits in the given position from a and b that are
                -- multiplied. Add the carry, and add what was already in the
                -- digit. Instead of having a list for each time we add a
                -- product row we just update the final result row.
                local r = c._digits[i+y-1] + (new_a._digits[i] * new_b._digits[y]) + u
                -- Calculate the carry.
                u = r >> DIGIT_BITS
                -- Remove the carry (if there was one) from the digit.
                c._digits[i+y-1] = r & DIGIT_MASK
            end

            -- Set the carry as the next digit in the product.
            c._digits[i+#new_b._digits] = u
        end

        reduce(c)
        return c
    end
M_mt.__div =
    -- This is an integer library so division will work the same as integer
    -- division.
    function(a, b)
        return a // b
    end
M_mt.__mod =
    function(a, b)
        local new_a, new_b = M:new(a), M:new(b)
        local _, c = div_remain(new_a, new_b)
        -- Change the wrapping direction appropriately.
        if c ~= M.ZERO and c._pos ~= new_b._pos then
            c = new_b + c
        end
        return c
    end
M_mt.__pow =
    function(a, b)
        local new_a, new_b = M:new(a), M:new(b)

        -- A negative exponent will always be smaller than 0 and since we're
        -- doing integer only with truncation the result will always be 0.
        if new_b < M.ZERO then
            return M:new()
        end

        local c = M:new(1)
        local d = M:new(1)

        -- Go though each bit in b. 
        while new_b > 0 do
            -- If b is currently odd we multiply c with a. 
            if new_b & 1 == d then
                c = c * new_a
            end
            -- Shift be so we can check the next bit.
            new_b = new_b >> 1
            -- Square a.
            new_a = new_a * new_a
        end

        return c
    end
M_mt.__unm =
    function(a)
        local new_a = M:new(a)
        new_a._pos = not new_a._pos
        return new_a
    end
M_mt.__idiv =
    function(a, b)
        local new_a, new_b = M:new(a), M:new(b)
        local c, _ = div_remain(new_a, new_b)
        return c
    end
-- Bitwise functions will set the appropriate digit bitwise function and call
-- the internal bitwise function that will go though all digits. This is a
-- digit by digit operation.
--
-- For example: 1234 & 0011 will result in
-- 1 & 0
-- 2 & 0
-- 3 & 1
-- 4 & 1
--
-- Replace & with any bitwise operation.
--
-- The BNs are compared as if they were positive. Other libraries, such as
-- Tommath don't have special handling for negative numbers. Tommath ignores
-- the negative and the result uses the sign of the second number but only
-- because it simplifies the code. It does not appear to be a concious design
-- decision.
M_mt.__band =
    function(a, b)
        local function op(a, b)
            return a & b
        end
        return bitwise_int(a, b, op)
    end
M_mt.__bor =
    function(a, b)
        local function op(a, b)
            return a | b
        end
        return bitwise_int(a, b, op)
    end
M_mt.__bxor =
    function(a, b)
        local function op(a, b)
            return a ~ b
        end
        return bitwise_int(a, b, op)
    end
M_mt.__bnot =
    -- Not the unary ~ operator. Lua uses ~ in front of a value for unary and ~
    -- between values for xor. This is ~ before, the unary operator. Flips all
    -- bits in the value.
    function(a)
        a = get_input(a)
        return -(a+1)
    end
M_mt.__shl =
    -- Left shift. b is always treated as a number. This does not support
    -- shifting by a BN amount.
    function(a, b)
        local c
        local u
        local t
        local uu
        local mask
        local shift

        a, b = get_inputs(a, b)
        if not b._pos then
            return nil, "Cannot shift by negative"
        end
        t = b
        b = b:asnumber()
        if M:new(b) ~= t then
            return INT_32_LIMIT
        end

        -- Determine how many digits we could shift by and shift by that many
        -- digits.
        c = b // DIGIT_BITS 
        a = lshiftd(a, c)

        -- Determine how many bits remain that have not been shifted during the
        -- digit shift.
        c = b % DIGIT_BITS
        if c == 0 then
            return a
        end

        -- Generate a mask and how much we need to shift by.
        mask = (1 << c) - 1
        shift = DIGIT_BITS - c

        u = 0
        for i=1,#a._digits do
            -- Shift, and mask it down to the carry.
            uu = (a._digits[i] >> shift) & mask
            -- Shift and add the carry from the last operation.
            a._digits[i] = ((a._digits[i] << c) | u) & DIGIT_MASK
            -- Update our carry.
            u = uu
        end

        -- If a carry is left put it into a new digit.
        if u ~= 0 then
            a._digits[#a._digits+1] = u
        end

        reduce(a)
        return a
    end
M_mt.__shr =
    -- Right shift. b is always treated as a number. This does not support
    -- shifting by a BN amount.
    function(a, b)
        local new_a, new_b = M:new(a), M:new(b)

        if not new_b._pos then
            return nil, "Cannot shift by negative"
        end

        -- Determine how many digits we could shift by and shift by that many
        -- digits.
        local c = new_b // DIGIT_BITS
        new_a = rshiftd(new_a, c)

        -- Determine how many bits remain that have not been shifted during the
        -- digit shift.
        c = new_b % DIGIT_BITS
        if c == 0 then
            return new_a
        end

        -- Generate a mask and how much we need to shift by.
        local mask = (1 << c) - 1
        local shift = DIGIT_BITS - c

        local u = 0
        for i=#new_a._digits,1,-1 do
            -- Mask off the amount we're shifting by.
            local uu = new_a._digits[i] & mask
            -- Move the value to the right since it's a right shift and add the
            -- carry onto the most significant side. The carry was the least
            -- significant side from the previous digit and the right of that
            -- is the most significant of the next digit.
            new_a._digits[i] = (new_a._digits[i] >> c) | (u << shift)
            -- Update our carry.
            u = uu
        end

        reduce(new_a)
        return new_a
    end
M_mt.__concat =
    function(a, b)
        -- Turn the values if they're BNs into strings and let Lua handle if
        -- conversion for other types.
        if M.isbn(a) then
            a = tostring(a)
        end
        if M.isbn(b) then
            b = tostring(b)
        end
        return a..b
    end
M_mt.__len =
    -- Length is the number of bytes in the BN. There may be many more bytes
    -- than are actually used due to the digit size. For example if a digit is
    -- 128 bit and the BN has the number 2 in it then it will have a length of
    -- 16 bytes. This will be rounded up to always equal 1 byte even if there
    -- are less digits. For example, 1, 15 byte digit will return 2 bytes used.
    -- 120, 15 byte digits is exactly 8 bytes so no rounding up is necessary.
    function(a)
        local b

        b = #a._digits * DIGIT_BITS
        b = b + (8 - (b % 8))
        return b // 8
    end
M_mt.__eq =
    function(a, b)
        local new_a, new_b = M:new(a), M:new(b)
        if new_a._pos ~= new_b._pos or #new_a._digits ~= #new_b._digits then
            return false
        end

        for i=#new_a._digits,1,-1 do
            if new_a._digits[i] ~= new_b._digits[i] then
                return false
            end
        end

        return true
    end
M_mt.__lt =
    function(a, b)
        local x

        local new_a, new_b = M:new(a), M:new(b)

        -- First check if we have different signs. A
        -- negative number is always less than a positive
        -- number and vise versa.
        if not new_a._pos and new_b._pos then
            return true
        elseif new_a._pos and not new_b._pos then
            return false
        end

        -- a and b both have the same sign but might
        -- not have the same number of digits.
        if  #new_a._digits < #new_b._digits then
            if new_a._pos then
                return true
            else
                return false 
            end
        elseif #new_a._digits > #new_b._digits then
            if new_a._pos then
                return false
            else
                return true
            end
        end

        -- Same sign and same number of digits.
        -- We'll have to do a digit compare.
        if not new_a._pos then
            x = new_a
            new_a = new_b
            new_b = x
        end

        for i=#new_a._digits,1,-1 do
            if new_a._digits[i] < new_b._digits[i] then
                return true
            elseif new_a._digits[i] > new_b._digits[i] then
                return false
            end
        end

        return false
    end
M_mt.__le =
    function(a, b)
        local new_a, new_b = M:new(a), M:new(b)
        if new_a < new_b or new_a == new_b then
            return true
        end
        return false
    end
M_mt.__tostring =
    -- Default string conversion is base 10 because that's what the internal
    -- one does.
    function(a)
        return tostring_int(a, 10)
    end

function M:new(n)
    local o

    if self ~= M then
        return nil, "first argument must be self"
    end

    if n ~= nil and M.isbn(n) then
        return n:copy()
    end

    o = setmetatable({}, M_mt)
    -- The BN is made of 2 parts. The sign and a list of digits.
    o._pos = true
    o._digits = { 0 }
    if n ~= nil then
        o:set(n)
    end

    return o
end
setmetatable(M, { __call = M.new })

function M:copy()
    local n

    n = M:new()
    copy_bn(self, n)

    return n
end

function M:abs()
    local a

    a = get_input(self)
    a._pos = true
    return a
end

function M:remain(b)
    local c = M:new(b)
    local _, d = div_remain(self, c)
    return d
end

function M:len_bits()
    local b
    local c = 0

    if self == M.ZERO then
        return 1
    end

    b = #self._digits * DIGIT_BITS
    -- Only the last digit can have less than the full number
    -- of bits set.
    while c <= DIGIT_BITS-1 and (self._digits[#self._digits] & (1 << (DIGIT_BITS - c))) == 0 do
        c = c + 1
        b = b - 1
    end

    return b+1
end

function M:len_bytes()
    local bits

    bits = self:len_bits()
    if bits <= 8 then
        return 1
    end

    if bits % 8 ~= 0 then
        bits = bits + (8 - (bits % 8))
    end
    return bits // 8
end

function M:len_digits(base)
    local len

    if not base then
        base = 10
    end

    len = #tostring_int(self, base)
    if not self._pos then
        len = len - 1
    end
    return len
end

function M:set(n)
    reset(self)

    -- Nothing to set so assume 0.
    if n == nil then
        return true
    end

    -- If it's a bn we just copy it.
    if M.isbn(n) then
        copy_bn(n, self)
        return true
    end

    if type(n) == "number" then
        return set_number(self, n)
    end

    return set_string(self, n)
end

function M:ashex(width)
    local s

    s = tostring_int(self, 16)

    if M.isbn(width) then
        width = width:asnumber()
    elseif type(width) == "string" then
        width = tonumber(width)
    end

    if not self._pos then
        s = s:sub(2)
    end

    if width == nil or #s >= width then
        return (self._pos and "" or "-")..s
    end

    return (self._pos and "" or "-")..string.rep("0", width-#s)..s
end

function M:asnumber()
    local x = math.min(#self._digits, ((31+DIGIT_BITS-1)//DIGIT_BITS)-1)

    local q = self._digits[x]
    for i=x-1,1,-1 do
        q = (q << DIGIT_BITS) | self._digits[i]
    end
    if not self._pos then
        q = q * -1
    end

    if M:new(q) ~= self then
        return INT_32_LIMIT
    end
    return q
end

function M:asbytearray()
    local t = {}

    for i=self:len_bytes()-1,0,-1 do
        t[#t+1] = ((self >> (i*8)) & 0xFF):asnumber()
    end
    return t
end

function M:asbytestring()
    local b

    b = self:asbytearray()
    for i=1,#b do
        b[i] = string.char(b[i])
    end
    return table.concat(b)
end

M.ZERO = M:new()

function M.isbn(t)
    if type(t) == "table" and getmetatable(t) == M_mt then
        return true
    end
    return false
end
