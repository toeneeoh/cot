OnInit.final("DropTable", function(Require)
    Require('Items')

    ItemDrops = array2d(0)
    Rates     = __jarray(0)

    ---@class DropTable
    ---@field adjustRate function
    ---@field pickItem function
    DropTable = {}
    do
        local thistype = DropTable
        local MAX_ITEM_COUNT = 100
        local ADJUST_RATE = 0.05

        -- adjusts the drop rates of all items in a pool after a drop
        ---@type fun(id: integer, i: integer)
        local function adjustRate(id, index)
            local max = ItemDrops[id][MAX_ITEM_COUNT]

            if ItemDrops[id] == nil or max <= 1 then
                return
            end

            local adjust = 1. / max * ADJUST_RATE
            local balance = adjust / (max - 1.)

            for i = 0, max - 1 do
                if ItemDrops[id][i] == ItemDrops[id][index] then
                    ItemDrops[id][i .. "\x25"] = ItemDrops[id][i .. "\x25"] - adjust
                else
                    ItemDrops[id][i .. "\x25"] = ItemDrops[id][i .. "\x25"] + balance
                end
            end
        end

        --[[selects an item from a unit type item pool
            starts at a random index and increments by 1]]
        ---@type fun(self: DropTable, id: integer):integer
        function thistype:pickItem(id)
            local max = ItemDrops[id][MAX_ITEM_COUNT] - 1
            local i = GetRandomInt(0, max)

            while true do
                if GetRandomReal(0., 1.) < ItemDrops[id][i .. "\x25"] then
                    adjustRate(id, i)
                    break
                end

                if i >= max then
                    i = 0
                else
                    i = i + 1
                end
            end

            return ItemDrops[id][i]
        end

        ---@type fun(id: integer, max: integer)
        local function setupRates(id, max)
            ItemDrops[id][MAX_ITEM_COUNT] = (max + 1)

            for i = 0, max do
                ItemDrops[id][i .. "\x25"] = 1. / (max + 1)
            end
        end

        function RewardItem(killed)
            local uid = GetType(killed)
            local rand = math.random(0, 99)
            local x, y = GetUnitX(killed), GetUnitY(killed)
            if rand < Rates[uid] then
                CreateItem(thistype:pickItem(uid), x, y, 600.)
            end

            -- iron golem ore
            -- chaotic ore

            rand = math.random(0, 99)
            if GetUnitLevel(killed) > 45 and GetUnitLevel(killed) < 85 and rand < (0.05 * GetUnitLevel(killed)) then
                CreateItem(FourCC('I02Q'), GetUnitX(killed), GetUnitY(killed), 600.)
            elseif GetUnitLevel(killed) > 265 and GetUnitLevel(killed) < 305 and rand < (0.02 * GetUnitLevel(killed)) then
                CreateItem(FourCC('I04Z'), GetUnitX(killed), GetUnitY(killed), 600.)
            end
        end

        local id = 69 -- destructables
        ItemDrops[id][0] = FourCC('I00O')
        ItemDrops[id][1] = FourCC('I00Q')
        ItemDrops[id][2] = FourCC('I00R')
        ItemDrops[id][3] = FourCC('I01C')
        ItemDrops[id][4] = FourCC('I01F')
        ItemDrops[id][5] = FourCC('I01G')
        ItemDrops[id][6] = FourCC('I01H')
        ItemDrops[id][7] = FourCC('I01I')
        ItemDrops[id][8] = FourCC('I01K')
        ItemDrops[id][9] = FourCC('I01V')
        ItemDrops[id][10] = FourCC('I021')
        ItemDrops[id][11] = FourCC('I02R')
        ItemDrops[id][12] = FourCC('I02T')
        ItemDrops[id][13] = FourCC('I04O')
        ItemDrops[id][14] = FourCC('I01X')
        ItemDrops[id][15] = FourCC('I06F')
        ItemDrops[id][16] = FourCC('I06G')
        ItemDrops[id][17] = FourCC('I090')
        ItemDrops[id][18] = FourCC('I01Z')
        ItemDrops[id][19] = FourCC('I0FJ')

        setupRates(id, 19)

        id = FourCC('n0tb') --troll
        Rates[id] = 40
        ItemDrops[id][0] = FourCC('I01Z') --claws of lightning
        ItemDrops[id][1] = FourCC('I01F') --iron broadsword
        ItemDrops[id][2] = FourCC('I01I') --iron sword
        ItemDrops[id][3] = FourCC('I01G') --iron dagger
        ItemDrops[id][4] = FourCC('I0FJ') --chipped shield
        ItemDrops[id][5] = FourCC('I02H') --short bow
        ItemDrops[id][6] = FourCC('I04O') --wooden staff
        ItemDrops[id][7] = FourCC('I01H') --iron shield
        ItemDrops[id][8] = FourCC('I00Q') --belt of the giant
        ItemDrops[id][9] = FourCC('I00R') --boots of the ranger
        ItemDrops[id][10] = FourCC('I02R') --sigil of magic
        ItemDrops[id][11] = FourCC('I01C') --gauntlets of strength
        ItemDrops[id][12] = FourCC('I02T') --slippers of agility
        ItemDrops[id][13] = FourCC('I01S') --seven league boots
        ItemDrops[id][14] = FourCC('I01K') --leather jacket
        ItemDrops[id][15] = FourCC('I01X') --sword of revival
        ItemDrops[id][16] = FourCC('I01V') --medallion of courage
        ItemDrops[id][17] = FourCC('I021') --medallion of vitality
        ItemDrops[id][18] = FourCC('I02D') --ring of regeneration
        ItemDrops[id][21] = FourCC('I06F') --crystal ball
        ItemDrops[id][22] = FourCC('I06G') --talisman of evasion
        ItemDrops[id][23] = FourCC('I090') --sparky orb
        ItemDrops[id][24] = FourCC('I04D') --tattered cloth

        setupRates(id, 24)

        id = FourCC('n0ts') --tuskarr
        Rates[id] = 40
        ItemDrops[id][0] = FourCC('I01Z')
        ItemDrops[id][1] = FourCC('I01X')
        ItemDrops[id][2] = FourCC('I01V')
        ItemDrops[id][3] = FourCC('I021')
        ItemDrops[id][4] = FourCC('I02D')
        ItemDrops[id][7] = FourCC('I06F')
        ItemDrops[id][8] = FourCC('I06G')
        ItemDrops[id][9] = FourCC('I090')
        ItemDrops[id][10] = FourCC('I01S')
        ItemDrops[id][11] = FourCC('I04D')
        ItemDrops[id][12] = FourCC('I03A') --steel dagger
        ItemDrops[id][13] = FourCC('I03W') --steel sword
        ItemDrops[id][14] = FourCC('I00O') --arcane staff
        ItemDrops[id][15] = FourCC('I03S') --steel shield
        ItemDrops[id][16] = FourCC('I01L') --long bow
        ItemDrops[id][17] = FourCC('I03K') --steel lance
        ItemDrops[id][18] = FourCC('I08Y') --noble blade
        ItemDrops[id][19] = FourCC('I03Q') --horse boost

        setupRates(id, 19)

        id = FourCC('n0ss') --spider
        Rates[id] = 35
        ItemDrops[id][0] = FourCC('I03A')
        ItemDrops[id][1] = FourCC('I03W')
        ItemDrops[id][2] = FourCC('I00O')
        ItemDrops[id][3] = FourCC('I03K')
        ItemDrops[id][4] = FourCC('I01L')
        ItemDrops[id][5] = FourCC('I03S')
        ItemDrops[id][6] = FourCC('I08Y')
        ItemDrops[id][7] = FourCC('I03Q')
        ItemDrops[id][8] = FourCC('I0FK') --mythril sword
        ItemDrops[id][9] = FourCC('I00F') --mythril spear
        ItemDrops[id][10] = FourCC('I010') --mythril dagger
        ItemDrops[id][11] = FourCC('I00N') --blood elven staff
        ItemDrops[id][12] = FourCC('I0FM') --blood elven bow
        ItemDrops[id][13] = FourCC('I0FL') --mythril shield
        ItemDrops[id][16] = FourCC('I025') --greater mask of death

        setupRates(id, 16)

        id = FourCC('n0uw') --ursa
        Rates[id] = 30
        ItemDrops[id][0] = FourCC('I028')
        ItemDrops[id][1] = FourCC('I00D')
        ItemDrops[id][2] = FourCC('I025')
        ItemDrops[id][3] = FourCC('I02L') --great circlet
        ItemDrops[id][4] = FourCC('I06T') --sword
        ItemDrops[id][5] = FourCC('I034') --heavy
        ItemDrops[id][6] = FourCC('I0FG') --dagger
        ItemDrops[id][7] = FourCC('I06R') --bow
        ItemDrops[id][8] = FourCC('I0FT') --staff

        setupRates(id, 8)

        id = FourCC('n0dm') --dire mammoth
        Rates[id] = 30
        ItemDrops[id][0] = FourCC('I035') --plate
        ItemDrops[id][1] = FourCC('I0FO') --leather
        ItemDrops[id][2] = FourCC('I07O') --cloth
        ItemDrops[id][3] = FourCC('I0FQ') --fullplate

        setupRates(id, 3)

        id = FourCC('n01G') -- ogre tauren
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I02L')
        ItemDrops[id][1] = FourCC('I08I')
        ItemDrops[id][2] = FourCC('I0FE')
        ItemDrops[id][3] = FourCC('I07W')
        ItemDrops[id][4] = FourCC('I08B')
        ItemDrops[id][5] = FourCC('I0FD')
        ItemDrops[id][6] = FourCC('I08R')
        ItemDrops[id][7] = FourCC('I08E')
        ItemDrops[id][8] = FourCC('I08F')
        ItemDrops[id][9] = FourCC('I07Y')
        ItemDrops[id][10] = FourCC('I00B') --axe of speed

        setupRates(id, 10)

        id = FourCC('n0ud') --unbroken
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I0FS')
        ItemDrops[id][1] = FourCC('I0FR')
        ItemDrops[id][2] = FourCC('I0FY')
        ItemDrops[id][3] = FourCC('I01W')
        ItemDrops[id][4] = FourCC('I0MB')

        setupRates(id, 4)

        id = FourCC('n0hs') -- hellfire hellhound
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I00Z')
        ItemDrops[id][1] = FourCC('I00S')
        ItemDrops[id][2] = FourCC('I011')
        ItemDrops[id][3] = FourCC('I02E')
        ItemDrops[id][4] = FourCC('I023')
        ItemDrops[id][5] = FourCC('I0MA')

        setupRates(id, 5)

        id = FourCC('n024') -- centaur
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I06J')
        ItemDrops[id][1] = FourCC('I06I')
        ItemDrops[id][2] = FourCC('I06L')
        ItemDrops[id][3] = FourCC('I06K')
        ItemDrops[id][4] = FourCC('I07H')

        setupRates(id, 4)

        id = FourCC('n01M') -- magnataur forgotten one
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I01Q')
        ItemDrops[id][1] = FourCC('I01N')
        ItemDrops[id][2] = FourCC('I015')
        ItemDrops[id][3] = FourCC('I019')

        setupRates(id, 3)

        id = FourCC('n02P') -- frost dragon frost drake
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I056')
        ItemDrops[id][1] = FourCC('I04X')
        ItemDrops[id][2] = FourCC('I05Z')

        setupRates(id, 2)

        id = FourCC('n099') -- frost elder dragon
        Rates[id] = 40
        ItemDrops[id][0] = FourCC('I056')
        ItemDrops[id][1] = FourCC('I04X')
        ItemDrops[id][2] = FourCC('I05Z')

        setupRates(id, 2)

        id = FourCC('n02L') -- devourers
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I02W')
        ItemDrops[id][1] = FourCC('I00W')
        ItemDrops[id][2] = FourCC('I017')
        ItemDrops[id][3] = FourCC('I013')
        ItemDrops[id][4] = FourCC('I02I')
        ItemDrops[id][5] = FourCC('I01P')
        ItemDrops[id][6] = FourCC('I006')
        ItemDrops[id][7] = FourCC('I02V')
        ItemDrops[id][8] = FourCC('I009')

        setupRates(id, 8)

        id = FourCC('n01H') -- ancient hydra
        Rates[id] = 25
        ItemDrops[id][0] = FourCC('I07N')
        ItemDrops[id][1] = FourCC('I044')

        setupRates(id, 1)

        id = FourCC('n034') --demons
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I073')
        ItemDrops[id][1] = FourCC('I075')
        ItemDrops[id][2] = FourCC('I06Z')
        ItemDrops[id][3] = FourCC('I06W')
        ItemDrops[id][4] = FourCC('I04T')
        ItemDrops[id][5] = FourCC('I06S')
        ItemDrops[id][6] = FourCC('I06U')
        ItemDrops[id][7] = FourCC('I06O')
        ItemDrops[id][8] = FourCC('I06Q')

        setupRates(id, 8)

        id = FourCC('n03A') --horror
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I07K')
        ItemDrops[id][1] = FourCC('I05D')
        ItemDrops[id][2] = FourCC('I07E')
        ItemDrops[id][3] = FourCC('I07I')
        ItemDrops[id][4] = FourCC('I07G')
        ItemDrops[id][5] = FourCC('I07C')
        ItemDrops[id][6] = FourCC('I07A')
        ItemDrops[id][7] = FourCC('I07M')
        ItemDrops[id][8] = FourCC('I07L')
        ItemDrops[id][9] = FourCC('I07P')
        ItemDrops[id][10] = FourCC('I077')

        setupRates(id, 10)

        id = FourCC('n03F') --despair
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I05P')
        ItemDrops[id][1] = FourCC('I087')
        ItemDrops[id][2] = FourCC('I089')
        ItemDrops[id][3] = FourCC('I083')
        ItemDrops[id][4] = FourCC('I081')
        ItemDrops[id][5] = FourCC('I07X')
        ItemDrops[id][6] = FourCC('I07V')
        ItemDrops[id][7] = FourCC('I07Z')
        ItemDrops[id][8] = FourCC('I07R')
        ItemDrops[id][9] = FourCC('I07T')
        ItemDrops[id][10] = FourCC('I05O')

        setupRates(id, 10)

        id = FourCC('n08N') --abyssal
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I06C')
        ItemDrops[id][1] = FourCC('I06B')
        ItemDrops[id][2] = FourCC('I0A0')
        ItemDrops[id][3] = FourCC('I0A2')
        ItemDrops[id][4] = FourCC('I09X')
        ItemDrops[id][5] = FourCC('I0A5')
        ItemDrops[id][6] = FourCC('I09N')
        ItemDrops[id][7] = FourCC('I06D')
        ItemDrops[id][8] = FourCC('I06A')

        setupRates(id, 8)

        id = FourCC('n031') --void
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I04Y')
        ItemDrops[id][1] = FourCC('I08C')
        ItemDrops[id][2] = FourCC('I08D')
        ItemDrops[id][3] = FourCC('I08G')
        ItemDrops[id][4] = FourCC('I08H')
        ItemDrops[id][5] = FourCC('I08J')
        ItemDrops[id][6] = FourCC('I055')
        ItemDrops[id][7] = FourCC('I08M')
        ItemDrops[id][8] = FourCC('I08N')
        ItemDrops[id][9] = FourCC('I08O')
        ItemDrops[id][10] = FourCC('I08S')
        ItemDrops[id][11] = FourCC('I08U')
        ItemDrops[id][12] = FourCC('I04W')

        setupRates(id, 12)

        id = FourCC('n020') --nightmare
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I09S')
        ItemDrops[id][1] = FourCC('I0AB')
        ItemDrops[id][2] = FourCC('I09R')
        ItemDrops[id][3] = FourCC('I0A9')
        ItemDrops[id][4] = FourCC('I09V')
        ItemDrops[id][5] = FourCC('I0AC')
        ItemDrops[id][6] = FourCC('I0A7')
        ItemDrops[id][7] = FourCC('I09T')
        ItemDrops[id][8] = FourCC('I09P')
        ItemDrops[id][9] = FourCC('I04Z')

        setupRates(id, 9)

        id = FourCC('n03D') --hell
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I097')
        ItemDrops[id][1] = FourCC('I05H')
        ItemDrops[id][2] = FourCC('I098')
        ItemDrops[id][3] = FourCC('I095')
        ItemDrops[id][4] = FourCC('I08W')
        ItemDrops[id][5] = FourCC('I05G')
        ItemDrops[id][6] = FourCC('I08Z')
        ItemDrops[id][7] = FourCC('I091')
        ItemDrops[id][8] = FourCC('I093')
        ItemDrops[id][9] = FourCC('I05I')

        setupRates(id, 9)

        id = FourCC('n03J') --existence
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I09Y')
        ItemDrops[id][1] = FourCC('I09U')
        ItemDrops[id][2] = FourCC('I09W')
        ItemDrops[id][3] = FourCC('I09Q')
        ItemDrops[id][4] = FourCC('I09O')
        ItemDrops[id][5] = FourCC('I09M')
        ItemDrops[id][6] = FourCC('I09K')
        ItemDrops[id][7] = FourCC('I09I')
        ItemDrops[id][8] = FourCC('I09G')
        ItemDrops[id][9] = FourCC('I09E')

        setupRates(id, 9)

        id = FourCC('n03M') --astral
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I0AL')
        ItemDrops[id][1] = FourCC('I0AN')
        ItemDrops[id][2] = FourCC('I0AA')
        ItemDrops[id][3] = FourCC('I0A8')
        ItemDrops[id][4] = FourCC('I0A6')
        ItemDrops[id][5] = FourCC('I0A3')
        ItemDrops[id][6] = FourCC('I0A1')
        ItemDrops[id][7] = FourCC('I0A4')
        ItemDrops[id][8] = FourCC('I09Z')

        setupRates(id, 8)

        id = FourCC('n026') --plainswalker
        Rates[id] = 20
        ItemDrops[id][0] = FourCC('I0AY')
        ItemDrops[id][1] = FourCC('I0B0')
        ItemDrops[id][2] = FourCC('I0B2')
        ItemDrops[id][3] = FourCC('I0B3')
        ItemDrops[id][4] = FourCC('I0AQ')
        ItemDrops[id][5] = FourCC('I0AO')
        ItemDrops[id][6] = FourCC('I0AT')
        ItemDrops[id][7] = FourCC('I0AR')
        ItemDrops[id][8] = FourCC('I0AW')

        setupRates(id, 8)

        id = FourCC('n02U') -- nerubian
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I01E')

        setupRates(id, 0)

        id = FourCC('n0pb') -- giant polar bear
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I04A')

        setupRates(id, 0)

        id = FourCC('n03L') -- king of ogres
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I02M')

        setupRates(id, 0)

        id = FourCC('n02H') -- yeti
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I05R')

        setupRates(id, 0)

        id = FourCC('H02H') -- paladin
        Rates[id] = 80
        ItemDrops[id][0] = FourCC('I0F9')
        ItemDrops[id][1] = FourCC('I03P')
        ItemDrops[id][2] = FourCC('I0C0')
        ItemDrops[id][3] = FourCC('I0FX')

        setupRates(id, 3)

        id = FourCC('O002') -- minotaur
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I03T')
        ItemDrops[id][1] = FourCC('I0FW')
        ItemDrops[id][2] = FourCC('I07U')
        ItemDrops[id][3] = FourCC('I076')
        ItemDrops[id][4] = FourCC('I078')

        setupRates(id, 4)

        id = FourCC('H020') -- lady vashj
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I09F') -- sea wards
        ItemDrops[id][1] = FourCC('I09L') -- serpent hide boots

        setupRates(id, 1)

        id = FourCC('H01V') -- dwarven
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I079')
        ItemDrops[id][1] = FourCC('I07B')
        ItemDrops[id][2] = FourCC('I0FC')

        setupRates(id, 2)

        id = FourCC('H040') -- death knight
        Rates[id] = 80
        ItemDrops[id][0] = FourCC('I02O')
        ItemDrops[id][1] = FourCC('I029')
        ItemDrops[id][2] = FourCC('I02C')
        ItemDrops[id][3] = FourCC('I02B')

        setupRates(id, 3)

        id = FourCC('U00G') -- tri fire
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I0FA')
        ItemDrops[id][1] = FourCC('I0FU')
        ItemDrops[id][2] = FourCC('I00V')
        ItemDrops[id][3] = FourCC('I03Y')

        setupRates(id, 3)

        id = FourCC('H045') -- mystic
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I03U')
        ItemDrops[id][1] = FourCC('I0F3')
        ItemDrops[id][2] = FourCC('I07F')

        setupRates(id, 2)

        id = FourCC('O01B') -- dragoon
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I0EX')
        ItemDrops[id][1] = FourCC('I0EY')
        ItemDrops[id][2] = FourCC('I074')
        ItemDrops[id][3] = FourCC('I04N')

        setupRates(id, 3)

        id = FourCC('E00B') -- goddess of hate
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I02Z') --aura of hate

        setupRates(id, 0)

        id = FourCC('E00D') -- goddess of love
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I030') --aura of love

        setupRates(id, 0)

        id = FourCC('E00C') -- goddess of knowledge
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I031') --aura of knowledge

        setupRates(id, 0)

        id = FourCC('H04Q') -- goddess of life
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I04I') --aura of life

        setupRates(id, 0)

        id = FourCC('H00O') -- arkaden
        Rates[id] = 80
        ItemDrops[id][0] = FourCC('I02O')
        ItemDrops[id][1] = FourCC('I02C')
        ItemDrops[id][2] = FourCC('I02B')
        ItemDrops[id][3] = FourCC('I036')

        setupRates(id, 3)

        id = FourCC('N038') -- demon prince
        Rates[id] = 100
        ItemDrops[id][0] = FourCC('I04Q') --heart

        setupRates(id, 0)

        id = FourCC('N017') -- absolute horror
        Rates[id] = 85
        ItemDrops[id][0] = FourCC('I0N7')
        ItemDrops[id][1] = FourCC('I0N8')
        ItemDrops[id][2] = FourCC('I0N9')

        setupRates(id, 2)

        id = FourCC('O02B') -- slaughter
        Rates[id] = 85
        ItemDrops[id][0] = FourCC('I0AE')
        ItemDrops[id][1] = FourCC('I04F')
        ItemDrops[id][2] = FourCC('I0AF')
        ItemDrops[id][3] = FourCC('I0AD')
        ItemDrops[id][4] = FourCC('I0AG')

        setupRates(id, 4)

        id = FourCC('O02H') -- dark soul
        Rates[id] = 70
        ItemDrops[id][0] = FourCC('I05A')
        ItemDrops[id][1] = FourCC('I0AH')
        ItemDrops[id][2] = FourCC('I0AP')
        ItemDrops[id][3] = FourCC('I0AI')

        setupRates(id, 3)

        id = FourCC('O02I') -- satan
        Rates[id] = 65
        ItemDrops[id][0] = FourCC('I0BX')
        ItemDrops[id][1] = FourCC('I05J')

        setupRates(id, 1)

        id = FourCC('O02K') -- thanatos
        Rates[id] = 65
        ItemDrops[id][0] = FourCC('I04E')
        ItemDrops[id][1] = FourCC('I0MR')

        setupRates(id, 1)

        id = FourCC('H04R') -- legion
        Rates[id] = 60
        ItemDrops[id][0] = FourCC('I0B5')
        ItemDrops[id][1] = FourCC('I0B7')
        ItemDrops[id][2] = FourCC('I0B1')
        ItemDrops[id][3] = FourCC('I0AU')
        ItemDrops[id][4] = FourCC('I04L')
        ItemDrops[id][5] = FourCC('I0AJ')
        ItemDrops[id][6] = FourCC('I0AZ')
        ItemDrops[id][7] = FourCC('I0AS')
        ItemDrops[id][8] = FourCC('I0AV')
        ItemDrops[id][9] = FourCC('I0AX')

        setupRates(id, 9)

        id = FourCC('O02M') -- existence
        Rates[id] = 60
        ItemDrops[id][0] = FourCC('I018')
        ItemDrops[id][1] = FourCC('I0BY')

        setupRates(id, 1)

        id = FourCC('O03G') -- xallarath
        Rates[id] = 30
        ItemDrops[id][0] = FourCC('I0OB')
        ItemDrops[id][1] = FourCC('I0O1')
        ItemDrops[id][2] = FourCC('I0CH')

        setupRates(id, 2)

        id = FourCC('O02T') -- azazoth
        Rates[id] = 60
        ItemDrops[id][0] = FourCC('I0BS')
        ItemDrops[id][1] = FourCC('I0BV')
        ItemDrops[id][2] = FourCC('I0BK')
        ItemDrops[id][3] = FourCC('I0BI')
        ItemDrops[id][4] = FourCC('I0BB')
        ItemDrops[id][5] = FourCC('I0BC')
        ItemDrops[id][6] = FourCC('I0BE')
        ItemDrops[id][7] = FourCC('I0B9')
        ItemDrops[id][8] = FourCC('I0BG')
        ItemDrops[id][9] = FourCC('I06M')

        setupRates(id, 9)
    end
end, Debug and Debug.getLine())
