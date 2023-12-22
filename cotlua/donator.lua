if Debug then Debug.beginFile 'Donator' end

OnInit.final("Donator", function(require)
    require 'Users'
    require 'Variables'
    require 'MapSetup'

    donator=__jarray("") ---@type string[] 
    donatorcode=__jarray(0) ---@type integer[] 
    isdonator=__jarray(false) ---@type boolean[] 
    cosmeticName=__jarray("") ---@type string[] 
    cosmeticAttach={} ---@type effect[] 
    cosmeticTotal=nil ---@type integer 
    donatorTotal=nil ---@type integer 
    skinID=__jarray(0) ---@type integer[] 

    DONATOR_SKIN_OFFSET         = 1  ---@type integer --leave 0 for donator flag
    DONATOR_AURA_OFFSET         = 1000 ---@type integer 
    PUBLIC_SKINS         = 500 ---@type integer 

    ---@param pid integer
    ---@param slot integer
    function CosmeticSpecialEffect(pid, slot)
        if slot == 0 then --Giant + Bomb Flame
            if GetUnitAbilityLevel(Hero[pid], FourCC('A04O')) > 0 then
                SetUnitScale(Hero[pid], BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE))
                UnitRemoveAbility(Hero[pid], FourCC('A04O'))
            else
                SetUnitScale(Hero[pid], 1.5, 1.5, 1.5)
                DestroyEffect(AddSpecialEffectTarget("war3mapImported\\FlameBomb.mdx", Hero[pid], "chest"))
                UnitAddAbility(Hero[pid], FourCC('A04O'))
            end
        elseif slot == 1 then --Giant + Holy Trail
            if GetUnitAbilityLevel(Hero[pid], FourCC('A04T')) > 0 then
                SetUnitScale(Hero[pid], BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE))
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
                UnitRemoveAbility(Hero[pid], FourCC('A04T'))
            else
                SetUnitScale(Hero[pid], 1.4, 1.4, 1.4)
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\ArchAngelArcana2.mdx", Hero[pid], "overhead")
                UnitAddAbility(Hero[pid], FourCC('A04T'))
            end
        elseif slot == 2 then --Orange Pentagram
            if GetUnitAbilityLevel(Hero[pid], FourCC('A053')) > 0 then
                UnitRemoveAbility(Hero[pid], FourCC('A053'))
            else
                UnitAddAbility(Hero[pid], FourCC('A053'))
            end
        elseif slot == 3 then --Kingstride Aura
            if GetUnitAbilityLevel(Hero[pid], FourCC('A054')) > 0 then
                SetUnitScale(Hero[pid], BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE))
                UnitRemoveAbility(Hero[pid], FourCC('A054'))
            else
                SetUnitScale(Hero[pid], 1.4, 1.4, 1.4)
                UnitAddAbility(Hero[pid], FourCC('A054'))
            end
        elseif slot == 4 then --Holy Aurora
            if GetUnitAbilityLevel(Hero[pid], FourCC('A05A')) > 0 then
                UnitRemoveAbility(Hero[pid], FourCC('A05A'))
            else
                UnitAddAbility(Hero[pid], FourCC('A05A'))
            end
        elseif slot == 5 then --Spiral Aura
            if GetUnitAbilityLevel(Hero[pid], FourCC('A05L')) > 0 then
                UnitRemoveAbility(Hero[pid], FourCC('A05L'))
            else
                UnitAddAbility(Hero[pid], FourCC('A05L'))
            end
            --war3mapImported\SpiralAura.mdx
        elseif slot == 6 then --Vampiric Aura
            if GetUnitAbilityLevel(Hero[pid], FourCC('A07B')) > 0 then
                UnitRemoveAbility(Hero[pid], FourCC('A07B'))
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid])
            else
                UnitAddAbility(Hero[pid], FourCC('A07B'))
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAura.mdl", Hero[pid], "head")
                BlzSetSpecialEffectScale(cosmeticAttach[pid], 0.5)
                BlzSetSpecialEffectColor(cosmeticAttach[pid], 255, 0, 0)
            end
        elseif slot == 7 then --Blood Ritual
            if cosmeticAttach[pid * cosmeticTotal + slot] ~= nil then
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
            else
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\Blood Ritual.mdx", Hero[pid], "origin")
            end
        elseif slot == 8 then --Soul Armor Cosmic
            if cosmeticAttach[pid * cosmeticTotal + slot] ~= nil then
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
            else
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\Soul Armor Cosmic_opt.mdx", Hero[pid], "origin")
            end
        elseif slot == 9 then --Radiance Orange
            if cosmeticAttach[pid * cosmeticTotal + slot] ~= nil then
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
            else
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\Radiance_Orange.mdx", Hero[pid], "origin")
            end
        elseif slot == 10 then --Liberty Green
            if cosmeticAttach[pid * cosmeticTotal + slot] ~= nil then
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
            else
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\Liberty Green.mdx", Hero[pid], "chest")
            end
        elseif slot == 11 then --Running Flame
            if cosmeticAttach[pid * cosmeticTotal + slot] ~= nil then
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
            else
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\s_RunningFlame Aura.mdx", Hero[pid], "origin")
            end
        elseif slot == 12 then --Grudge Aura
            if cosmeticAttach[pid * cosmeticTotal + slot] ~= nil then
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
            else
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\GrudgeAura.mdx", Hero[pid], "origin")
            end
        elseif slot == 13 then --Nuke Aura
            if cosmeticAttach[pid * cosmeticTotal + slot] ~= nil then
                TimerQueue:callDelayed(0, DestroyEffect, cosmeticAttach[pid * cosmeticTotal + slot])
            else
                cosmeticAttach[pid * cosmeticTotal + slot] = AddSpecialEffectTarget("war3mapImported\\AuraNuke.mdx", Hero[pid], "origin")
            end
        end
    end

        local i         = 0 ---@type integer 
        local i2         = 0 ---@type integer 
        local i3         = 1 ---@type integer 
        local j         = 0 ---@type integer 
        local k         = 0 ---@type integer 
        local start         = 0  ---@type integer 
        local end_         = 0 ---@type integer 
        local flags        = "" ---@type string 
        local name        = "" ---@type string 

        donator[0] = "lcm#1458 11111111111111111111 11111111111111111"
        donator[1] = "Mayday#12613 01"
        donator[2] = "gnta#1220 001"
        donator[3] = "Gingusa#1768 0001 0000000000001"
        donator[4] = "Demon#24174 00001 000001"
        donator[5] = "Veridian#1582 0000001 001"
        donator[6] = "Baraghmarus#1362 000000001"
        donator[7] = "DarkSideGami#1825 0000000001 000000001"
        donator[8] = "CanFight#2771 00000000001"
        donator[9] = "DivineEvil#1601 000000000001"
        donator[10] = "Ash#14387 0000000000001"
        donator[11] = "YeOldTurnip#1512 00000000000001"
        donator[12] = "Anarak#11980 000000000000001 01"
        donator[13] = "ThayldDrekka#1293 0000000000000001 0000001"
        donator[14] = "Wyce#21518 00000000000000001 00000000001"
        donator[15] = "SilverHand#11103 000000000000000001"
        donator[16] = "Kris#2648 0000000000000000001"
        donator[17] = "Diablo89#1701 00000000000000000001 000000000001"
        donator[18] = "Luglug#1434 000000000000000000001 00000000000001"
        donator[19] = "Peacee#21451 0000000000000000000001"
        donator[20] = "DarkMatter#12814 0 00011"
        donator[21] = "xriderx#1392 0 0000000001"

        donatorTotal = 21

        while i <= donatorTotal do

            i2 = 0
            i3 = 1
            k = 0

            while not (i3 > StringLength(donator[i]) + 1) do

                if (SubString(donator[i], i2, i3) == " " or i3 > StringLength(donator[i])) then
                    end_ = i2
                    flags = SubString(donator[i], start, end_)
                    --flag as donator
                    if k == 0 then
                        name = SubString(donator[i], start, end_)

                        CosmeticTable[name][0] = 1
                    --set skin flags
                    elseif k == 1 then
                        j = DONATOR_SKIN_OFFSET

                        while not (j - DONATOR_SKIN_OFFSET > StringLength(flags)) do

                            CosmeticTable[name][j] = S2I(SubString(flags, j - DONATOR_SKIN_OFFSET, j - DONATOR_SKIN_OFFSET + 1))

                            j = j + 1
                        end
                    --set aura flags
                    elseif k == 2 then
                        j = DONATOR_AURA_OFFSET

                        while not (j - DONATOR_AURA_OFFSET > StringLength(flags)) do

                            CosmeticTable[name][j] = S2I(SubString(flags, j - DONATOR_AURA_OFFSET, j - DONATOR_AURA_OFFSET + 1))

                            j = j + 1
                        end
                    end

                    start = i3
                    k = k + 1
                end

                i2 = i2 + 1
                i3 = i3 + 1
            end

            i = i + 1
        end

        dSkinName[1] = "|cffffffffMalthael" --lcm
        skinID[1] = FourCC('H013')
        dSkinName[2] = "|cffffffffFaerie Dragon" --mayday
        skinID[2] = FourCC('H014')
        dSkinName[3] = "|cffffffffPestilant Prince" --gnta
        skinID[3] = FourCC('H015')
        dSkinName[4] = "|cffffffffReaper" --gingusa
        skinID[4] = FourCC('H021')
        dSkinName[5] = "|cffffffffEvil Eye" --demon
        skinID[5] = FourCC('H022')
        dSkinName[6] = "|cffffffffUndead Batrider" --veridian
        skinID[6] = FourCC('H024')
        dSkinName[7] = "|cffffffffSpectre" --baraghmarus
        skinID[7] = FourCC('H026')
        dSkinName[8] = "|cffffffffDemoness|r" --DarkSideGami
        skinID[8] = FourCC('H00J')
        dSkinName[9] = "|cffffffffPeasant|r" --CanFight
        skinID[9] = FourCC('H028')
        dSkinName[10] = "|cffffffffNightmare Sheep|r" --divineevil
        skinID[10] = FourCC('H02C')
        dSkinName[11] = "|cffffffffFrost Wyrm|r" --geist (ash)
        skinID[11] = FourCC('H02K')
        dSkinName[12] = "|cffffffffObsidian Destroyer|r" --yeoldturnip
        skinID[12] = FourCC('H02O')
        dSkinName[13] = "|cffffffffSpider|r" --anarak
        skinID[13] = FourCC('H02R')
        dSkinName[14] = "|cffffffffScavenger|r" --thaylddrekka
        skinID[14] = FourCC('H06X')
        dSkinName[15] = "|cffffffffSuccubus|r" --Wyce
        skinID[15] = FourCC('H03O')
        dSkinName[16] = "|cffffffffLich|r" --SilverHand
        skinID[16] = FourCC('H03P')
        dSkinName[17] = "|cffffffffPolar Bear|r" --Kris
        skinID[17] = FourCC('H03Q')
        dSkinName[18] = "|cffffffffDiablo|r" --Diablo89
        skinID[18] = FourCC('H03R')
        dSkinName[19] = "|cffffffffGnome Dragonrider|r" --Luglug
        skinID[19] = FourCC('H00A')
        dSkinName[20] = "|cffffffffExplosive Sheep|r" --Peacee
        skinID[20] = FourCC('H03S')

        --obtainable
        i = PUBLIC_SKINS
        dSkinName[i] = "|cffffffffNone"
        skinID[i] = FourCC('eRez')
        ispublic[i] = true
        i = i + 1
        dSkinName[i] = "|cffffffffWisp"
        skinID[i] = FourCC('H011')
        ispublic[i] = true
        i = i + 1
        dSkinName[i] = "|cffffffffBlack Dragon Whelp" --atk prestige 1 char
        skinID[i] = FourCC('H031')
        i = i + 1
        dSkinName[i] = "|cffffffffShadow Mephit" --atk prestige 2 char
        skinID[i] = FourCC('H03C')
        i = i + 1
        dSkinName[i] = "|cffffffffRed Dragon Whelp" --str prestige 1 char
        skinID[i] = FourCC('H03E')
        i = i + 1
        dSkinName[i] = "|cffffffffFire Mephit" --str prestige 2 char
        skinID[i] = FourCC('H03L')
        i = i + 1
        dSkinName[i] = "|cffffffffGreen Dragon Whelp" --agi prestige 1 char
        skinID[i] = FourCC('H03U')
        i = i + 1
        dSkinName[i] = "|cffffffffVenom Mephit" --agi prestige 2 char
        skinID[i] = FourCC('H03Z')
        i = i + 1
        dSkinName[i] = "|cffffffffBlue Dragon Whelp" --int prestige 1
        skinID[i] = FourCC('H041')
        i = i + 1
        dSkinName[i] = "|cffffffffIce Mephit" --int prestige 2
        skinID[i] = FourCC('H042')
        i = i + 1
        dSkinName[i] = "|cffffffffWyvern" --dmg red prestige 1
        skinID[i] = FourCC('H04E')
        i = i + 1
        dSkinName[i] = "|cffffffffNether Dragon" --dmg red prestige 2
        skinID[i] = FourCC('H04L')
        i = i + 1
        dSkinName[i] = "|cffffffffOwl" --spellboost prestige 1
        skinID[i] = FourCC('H04O')
        i = i + 1
        dSkinName[i] = "|cffffffffSpirit Owl" --spellboost prestige 2
        skinID[i] = FourCC('H04P')
        i = i + 1
        dSkinName[i] = "|cffffffffPhase Bat" --spellboost prestige 3
        skinID[i] = FourCC('H058')
        i = i + 1
        dSkinName[i] = "|cffffffffYellow Dragon Whelp" --regen prestige 1
        skinID[i] = FourCC('H05I')
        i = i + 1
        dSkinName[i] = "|cffffffffEarth Mephit" --regen prestige 2
        skinID[i] = FourCC('H05K')
        i = i + 1
        dSkinName[i] = "|cffffffffElder Shadow Dragon" --prestige 10 chars
        skinID[i] = FourCC('H066')
        i = i + 1
        dSkinName[i] = "|cffffffffSin" --prestige all chars
        skinID[i] = FourCC('H06W')

        TOTAL_SKINS = i

        cosmeticName[0] = "Giant + Blue Flame"
        cosmeticName[1] = "Giant + Holy Trail"
        cosmeticName[2] = "Orange Pentagram"
        cosmeticName[3] = "Giant + Kingstride Aura"
        cosmeticName[4] = "Holy Aurora"
        cosmeticName[5] = "Spiral Aura"
        cosmeticName[6] = "Vampiric Aura"
        cosmeticName[7] = "Blood Ritual"
        cosmeticName[8] = "Soul Armor"
        cosmeticName[9] = "Orange Radiance"
        cosmeticName[10] = "Liberty Green"
        cosmeticName[11] = "Running Flame"
        cosmeticName[12] = "Grudge Aura"
        cosmeticName[13] = "Nuke Aura"

        cosmeticTotal = 13

        local u      = User.first ---@class User 
        local mbitem                = nil ---@type multiboarditem 

        while u do
            for i = 0, funnyListTotal do
                if StringHash(u.name) == funnyList[i] and i ~= 1 then
                    CustomDefeatBJ(u.player, "Lol")
                end
            end

            if CosmeticTable[u.name][0] > 0 then
                isdonator[u.id] = true
                mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[u.id], 0)
                MultiboardSetItemValue(mbitem, u.nameColored .. "|cffffcc00*|r")
                MultiboardReleaseItem(mbitem)
            end

            u = u.next
        end

end)

if Debug then Debug.endFile() end
