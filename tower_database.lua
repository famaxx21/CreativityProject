-- ==========================================
-- TOWER COST DATABASE
-- ==========================================

local TOWER_COST_DATABASE = {
    -- Normal Towers
    ["Scout"] = 125,
    ["Sniper"] = 450,
    ["Paintballer"] = 100,
    ["Demoman"] = 700,
    ["Boomerang"] = 550,
    ["Slime Trooper"] = 500,
    ["Soldier"] = 400,
    ["Freezer"] = 450,
    ["Assassin"] = 300,
    ["Militant"] = 600,
    ["Shotgunner"] = 1225,
    ["Hunter"] = 1625,
    ["Pyromancer"] = 900,
    ["Ace Pilot"] = 500,
    ["Medic"] = 400,
    ["Farm"] = 300,
    ["Electroshocker"] = 650,
    ["Rocketeer"] = 2000,
    ["Trapper"] = 500,
    ["Military Base"] = 400,
    ["Crook Boss"] = 800,
    ["Commander"] = 650,
    ["Warden"] = 1850,
    ["Cowboy"] = 550,
    ["DJ Booth"] = 850,
    ["Tesla"] = 2000,
    ["Saboteur"] = 775,
    ["Minigunner"] = 1850,
    ["Ranger"] = 4500,
    ["Pursuit"] = 5000,
    ["Gatling Gun"] = 5250,
    ["Turret"] = 7750,
    ["Mortar"] = 1000,
    ["Mercenary Base"] = 2750,
    ["Brawler"] = 300,
    ["Necromancer"] = 4200,
    ["Accelerator"] = 7500,
    ["Engineer"] = 600,
    ["Hacker"] = 900,
    
    -- Evolved Towers
    ["EvolvedOperator"] = 300,
    ["EvolvedKingpin"] = 3600,
    ["EvolvedJuggernaut"] = 10000,
    ["EvolvedEnforcer"] = 3000,
    
    -- Golden Towers
    ["Golden Minigunner"] = 2400,
    ["Golden Pyromancer"] = 850,
    ["Golden Crook Boss"] = 2400,
    ["Golden Scout"] = 250,
    ["Golden Soldier"] = 450,
    ["Golden Demoman"] = 875,
    ["Golden Cowboy"] = 600,
    ["Golden Snowballer"] = 67,
    
    -- Special
    ["Commando"] = 2150,
    ["Frost Blaster"] = 850,
    ["Archer"] = 600,
    ["Toxic Gunner"] = 525,
    ["Swarmer"] = 900,
    ["Firework Technician"] = 1500,
    ["Gladiator"] = 525,
    ["Slasher"] = 2400,
    ["Sledger"] = 950,
    ["Executioner"] = 750,
    ["Elf Camp"] = 300,
    ["Jester"] = 650,
    ["Cryomancer"] = 250,
    ["Hallow Punk"] = 500,
    ["Harvester"] = 2000,
    ["Snowballer"] = 300,
    ["Elementalist"] = 2000,
    ["Biologist"] = 750,
    ["Warlock"] = 4200,
    ["Spotlight Tech"] = 3225,
    ["War Machine"] = 6750,
    ["Mecha Base"] = 6000,
}

local COST_TO_TOWER = {}

for towerName, towerCost in pairs(TOWER_COST_DATABASE) do
    if not COST_TO_TOWER[towerCost] then
        COST_TO_TOWER[towerCost] = {}
    end
    
    table.insert(COST_TO_TOWER[towerCost], towerName)
end

local function GetTowerCost(towerName)
    return TOWER_COST_DATABASE[towerName] or 0
end

local function GetTowerNameByCost(cost)
    local names = COST_TO_TOWER[cost]
    
    if names and #names > 0 then
        return names[1]
    end
    
    return "Unknown"
end

local function GetTowerNamesByCost(cost)
    return COST_TO_TOWER[cost] or {}
end

getgenv().TowerDatabase = {
    Costs = TOWER_COST_DATABASE,
    Reverse = COST_TO_TOWER,
    GetCost = GetTowerCost,
    GetNameByCost = GetTowerNameByCost,
    GetNamesByCost = GetTowerNamesByCost,
}

print("=================================")
print("📊 TOWER DATABASE LOADED")
print(string.format("%d towers terdaftar", #TOWER_COST_DATABASE))
print("=================================")
