if Debug then Debug.beginFile 'Donator' end

OnInit.final("Donator", function(require)
    require 'Users'
    require 'Variables'
    require 'MapSetup'

    DONATOR_AURA_OFFSET = 1000 ---@type integer 

    isdonator = __jarray(false) ---@type boolean[] 
    local donator = {
        "lcm#1458 11111111111111111111111 1111111111111111111",
        "Mayday#12613 01",
        "gnta#1220 001",
        "Gingusa#1768 0001 0000000000001",
        "Demon#24174 00001 000001",
        "Veridian#1582 000001 001",
        "Baraghmarus#1362 0000001",
        "DarkSideGami#1825 00000001 000000001",
        "CanFight#2771 000000001",
        "DivineEvil#1601 0000000001",
        "Ash#14387 00000000001",
        "YeOldTurnip#1512 000000000001",
        "Anarak#11980 0000000000001 01",
        "ThayldDrekka#1293 00000000000001 0000001",
        "Wyce#21518 000000000000001 00000000001",
        "SilverHand#11103 0000000000000001",
        "Kris#2648 00000000000000001",
        "Diablo89#1701 000000000000000001 000000000001",
        "Luglug#1434 0000000000000000001 00000000000001",
        "Peacee#21451 00000000000000000001",
        "DarkMatter#12814 0 00011",
        "xriderx#1392 0 0000000001",
        "Dynasty3990#1468 000000000000000000001 000000000001",
        "Rshdan#2718 0000000000000000000001 000000000000001",
        "Prove#21949 00000000000000000000001 0000000000000001",
    }

    for i = 1, #donator do
        local name, skinFlags, auraFlags = donator[i]:match("([^#]+)#%d+ ([^ ]*) ([^ ]*)")

        --flag as donator
        CosmeticTable[name][0] = 1

        --set skin flags
        for j = 1, #skinFlags do
            CosmeticTable[name][j] = tonumber(skinFlags:sub(j, j))
        end

        --set aura flags
        for j = 1, #auraFlags do
            CosmeticTable[name][DONATOR_AURA_OFFSET + j] = tonumber(auraFlags:sub(j, j))
        end
    end

    CosmeticTable.skins = {
        { name = "Malthael", id = FourCC('H013'), public = false },
        { name = "Faerie Dragon", id = FourCC('H014'), public = false },
        { name = "Pestilant Prince", id = FourCC('H015'), public = false },
        { name = "Reaper", id = FourCC('H021'), public = false },
        { name = "Evil Eye", id = FourCC('H022'), public = false },
        { name = "Undead Batrider", id = FourCC('H024'), public = false },
        { name = "Spectre", id = FourCC('H026'), public = false },
        { name = "Demoness", id = FourCC('H00J'), public = false },
        { name = "Peasant", id = FourCC('H028'), public = false },
        { name = "Nightmare Sheep", id = FourCC('H02C'), public = false },
        { name = "Frost Wyrm", id = FourCC('H02K'), public = false },
        { name = "Obsidian Destroyer", id = FourCC('H02O'), public = false },
        { name = "Spider", id = FourCC('H02R'), public = false },
        { name = "Scavenger", id = FourCC('H06X'), public = false },
        { name = "Succubus", id = FourCC('H03O'), public = false },
        { name = "Lich", id = FourCC('H03P'), public = false },
        { name = "Polar Bear", id = FourCC('H03Q'), public = false },
        { name = "Diablo", id = FourCC('H03R'), public = false },
        { name = "Gnome Dragonrider", id = FourCC('H00A'), public = false },
        { name = "Explosive Sheep", id = FourCC('H03S'), public = false },
        { name = "Phoenix", id = FourCC('H04D'), public = false },
        { name = "Demon Taskmaster", id = FourCC('H04Y'), public = false },
        { name = "Robincoon", id = FourCC('H05C'), public = false },
        --obtainable skins
        { name = "None", id = FourCC('eRez'), public = true },
        { name = "Wisp", id = FourCC('H011'), public = true },
        { name = "Black Dragon Whelp", id = FourCC('H031'), public = true, error = "You must prestige one of these heroes to unlock this! ()" }, --atk prestige 1
        { name = "Shadow Mephit", id = FourCC('H03C'), public = true }, --atk prestige 2
        { name = "Red Dragon Whelp", id = FourCC('H03E'), public = true }, --str prestige 1
        { name = "Fire Mephit", id = FourCC('H03L'), public = true }, --str prestige 2
        { name = "Green Dragon Whelp", id = FourCC('H03U'), public = true }, --agi prestige 1
        { name = "Venom Mephit", id = FourCC('H03Z'), public = true }, --agi prestige 2
        { name = "Blue Dragon Whelp", id = FourCC('H041'), public = true }, --int prestige 1
        { name = "Ice Mephit", id = FourCC('H042'), public = true }, --int prestige 2
        { name = "Wyvern", id = FourCC('H04E'), public = true }, --dmg prestige 
        { name = "Nether Dragon", id = FourCC('H04L'), public = true }, --dmg prestige 2
        { name = "Owl", id = FourCC('H04O'), public = true }, --spellboost prestige 1
        { name = "Spirit Owl", id = FourCC('H04P'), public = true }, --spellboost prestige 2
        { name = "Phase Bat", id = FourCC('H058'), public = true }, --spellboost prestige 3
        { name = "Yellow Dragon Whelp", id = FourCC('H05I'), public = true }, --regen prestige 1
        { name = "Earth Mephit", id = FourCC('H05K'), public = true }, --regen prestige 2
        { name = "Elder Shadow Dragon", id = FourCC('H066'), public = true }, --prestige 10 chars
        { name = "Sin", id = FourCC('H06W'), public = true }, --all chars prestiged
    }

    PUBLIC_SKINS = 24
    TOTAL_SKINS = #CosmeticTable.skins

    CosmeticTable.cosmetics = {
        {
            name = "Giant + Blue Flame",
            effect = function(self, pid)
                if GetUnitAbilityLevel(Hero[pid], FourCC('A04O')) > 0 then
                    SetUnitScale(Hero[pid], BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE))
                    UnitRemoveAbility(Hero[pid], FourCC('A04O'))
                else
                    SetUnitScale(Hero[pid], 1.5, 1.5, 1.5)
                    DestroyEffect(AddSpecialEffectTarget("war3mapImported\\FlameBomb.mdx", Hero[pid], "chest"))
                    UnitAddAbility(Hero[pid], FourCC('A04O'))
                end
            end
        },
        {
            name = "Giant + Holy Trail",
            effect = function(self, pid)
                if GetUnitAbilityLevel(Hero[pid], FourCC('A04T')) > 0 then
                    SetUnitScale(Hero[pid], BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE))
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                    UnitRemoveAbility(Hero[pid], FourCC('A04T'))
                else
                    SetUnitScale(Hero[pid], 1.4, 1.4, 1.4)
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\ArchAngelArcana2.mdx", Hero[pid], "overhead")
                    UnitAddAbility(Hero[pid], FourCC('A04T'))
                end
            end
        },
        {
            name = "Orange Pentagram",
            effect = function(self, pid)
                if GetUnitAbilityLevel(Hero[pid], FourCC('A053')) > 0 then
                    UnitRemoveAbility(Hero[pid], FourCC('A053'))
                else
                    UnitAddAbility(Hero[pid], FourCC('A053'))
                end
            end
        },
        {
            name = "Giant + Kingstride Aura",
            effect = function(self, pid)
                if GetUnitAbilityLevel(Hero[pid], FourCC('A054')) > 0 then
                    SetUnitScale(Hero[pid], BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE), BlzGetUnitRealField(Hero[pid], UNIT_RF_SCALING_VALUE))
                    UnitRemoveAbility(Hero[pid], FourCC('A054'))
                else
                    SetUnitScale(Hero[pid], 1.4, 1.4, 1.4)
                    UnitAddAbility(Hero[pid], FourCC('A054'))
                end
            end
        },
        {
            name = "Holy Aurora",
            effect = function(self, pid)
                if GetUnitAbilityLevel(Hero[pid], FourCC('A05A')) > 0 then
                    UnitRemoveAbility(Hero[pid], FourCC('A05A'))
                else
                    UnitAddAbility(Hero[pid], FourCC('A05A'))
                end
            end
        },
        {
            name = "Spiral Aura",
            effect = function(self, pid)
                if GetUnitAbilityLevel(Hero[pid], FourCC('A05L')) > 0 then
                    UnitRemoveAbility(Hero[pid], FourCC('A05L'))
                else
                    UnitAddAbility(Hero[pid], FourCC('A05L'))
                end
            end
        },
        {
            name = "Vampiric Aura",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("Abilities\\Spells\\Undead\\VampiricAura\\VampiricAura.mdl", Hero[pid], "head")
                    BlzSetSpecialEffectScale(self[pid .. self.name], 0.5)
                    BlzSetSpecialEffectColor(self[pid .. self.name], 255, 0, 0)
                end
            end
        },
        {
            name = "Blood Ritual",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\Blood Ritual.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Soul Armor",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\Soul Armor Cosmic_opt.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Orange Radiance",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\Radiance_Orange.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Liberty Green",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\Liberty Green.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Running Flame",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\s_RunningFlame Aura.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Grudge Aura",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\GrudgeAura.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Nuke Aura",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\AuraNuke.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Runic Aura",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\RunicAura.mdx", Hero[pid], "origin")
                end
            end
        },
        {
            name = "Void Disc",
            effect = function(self, pid)
                if self[pid .. self.name] then
                    DestroyEffect(self[pid .. self.name])
                    self[pid .. self.name] = nil
                else
                    self[pid .. self.name] = AddSpecialEffectTarget("war3mapImported\\Void Disc.mdx", Hero[pid], "origin")
                end
            end
        },
    }

    local u = User.first

    while u do
        for i, v in ipairs(funnyList) do
            if StringHash(u.name) == v and i ~= 1 then
                CustomDefeatBJ(u.player, "Lol")
            end
        end

        if CosmeticTable[u.name][0] > 0 then
            isdonator[u.id] = true
            local mbitem = MultiboardGetItem(MULTI_BOARD, MB_SPOT[u.id], 0)
            MultiboardSetItemValue(mbitem, u.nameColored .. "|cffffcc00*|r")
            MultiboardReleaseItem(mbitem)
        end

        u = u.next
    end

end)

if Debug then Debug.endFile() end
