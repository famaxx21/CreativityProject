-- ==========================================
-- TOWER MANAGER - BATCH HEAL + UNAPPLY + SELL FIX
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")

local towerList = {}
local selectedTower = nil
local selectedBatch = {}
local batchMode = false
local currentFilter = "All"
local collapsedGroups = {}
local currentPage = 1
local groupsPerPage = 5
local totalPages = 1

local towerRegistry = {}
local pendingPlacements = {}
local towerNameCounters = {}
local towerLevels = {}

-- ========== HEALER STATE ==========
local healerTargets = {}
local healerLinks = {}
local healerMode = false
local activeHealer = nil
local healerListCache = {}

-- ========== BATCH HEAL STATE ==========
local batchHealMode = false
local batchHealTargets = {}
local healSlotCapacity = 5

-- ========== HOOK ==========
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "InvokeServer" and self.Name == "RemoteFunction" then
        if args[1] == "Troops" and args[2] == "Place" then
            local placementData = args[3]
            local unitName = args[4]
            local position = nil
            
            if placementData and type(placementData) == "table" then
                position = placementData.Position
            end
            
            if unitName and position then
                table.insert(pendingPlacements, {
                    UnitName = unitName,
                    Position = position,
                    Time = os.clock(),
                })
            end
        end
        
        if args[1] == "Troops" and args[2] == "Upgrade" and args[3] == "Set" then
            local upgradeData = args[4]
            
            if upgradeData and type(upgradeData) == "table" then
                local upgradedTower = upgradeData.Troop
                
                if upgradedTower then
                    if not towerLevels[upgradedTower] then
                        towerLevels[upgradedTower] = 0
                    end
                    towerLevels[upgradedTower] = towerLevels[upgradedTower] + 1
                end
            end
        end
        
        if args[1] == "Troops" and args[2] == "Sell" then
            local sellData = args[3]
            
            if sellData and type(sellData) == "table" then
                local soldTower = sellData.Troop
                
                if soldTower then
                    if selectedTower == soldTower then
                        selectedTower = nil
                        task.spawn(function()
                            task.wait(0.1)
                            UpdatePanelInfo()
                        end)
                    end
                    
                    if towerRegistry[soldTower] then
                        local unitName = towerRegistry[soldTower].UnitName
                        
                        if unitName and towerNameCounters[unitName] then
                            towerNameCounters[unitName] = math.max(0, towerNameCounters[unitName] - 1)
                        end
                        
                        towerRegistry[soldTower] = nil
                    end
                    
                    towerLevels[soldTower] = nil
                    selectedBatch[soldTower] = nil
                    healerTargets[soldTower] = nil
                    batchHealTargets[soldTower] = nil
                    
                    -- Hapus sold tower dari healerLinks (sebagai healer)
                    if healerLinks[soldTower] then
                        healerLinks[soldTower] = nil
                    end
                    
                    -- Hapus sold tower dari semua target lists
                    for healer, targets in pairs(healerLinks) do
                        if targets[soldTower] then
                            targets[soldTower] = nil
                        end
                    end
                    
                    -- Reset activeHealer kalau yang di-sell adalah activeHealer
                    if activeHealer == soldTower then
                        activeHealer = nil
                        healerTargets = {}
                        UpdateHealerStatus()
                        RefreshHealerPanel()
                    end
                    
                    -- Reset CurrentHealer kalau yang di-sell
                    if getgenv().CurrentHealer == soldTower then
                        getgenv().CurrentHealer = nil
                    end
                    
                    task.spawn(function()
                        task.wait(0.2)
                        RefreshList()
                        if healerMode then
                            RefreshHealerPanel()
                        end
                    end)
                end
            end
        end
        
        -- HEALER LINK DETECTION
        if args[1] == "Troops" and args[2] == "TowerServerEvent" and args[3] == "ToggleSelectedTower" then
            local healer = args[4]
            local target = args[5]
            
            if healer and target then
                -- BLOCK SELF-TARGET
                if healer == target then
                    print("[Healer] ⛔ Self-target blocked")
                    return oldNamecall(self, ...)
                end
                
                getgenv().CurrentHealer = healer
                getgenv().CurrentHealTarget = target
                
                if not healerLinks[healer] then
                    healerLinks[healer] = {}
                end
                
                healerLinks[healer][target] = not healerLinks[healer][target]
                
                print(string.format("[Healer] Link toggled: %s -> %s (active: %s)", 
                    healer.Name, target.Name, tostring(healerLinks[healer][target])))
            end
        end
    end
    
    return oldNamecall(self, ...)
end)

-- ========== MATCH ==========
local function MatchTowerWithPlacement(tower)
    for i = #pendingPlacements, 1, -1 do
        if os.clock() - pendingPlacements[i].Time > 5 then
            table.remove(pendingPlacements, i)
        end
    end
    
    if #pendingPlacements == 0 then return nil end
    
    local towerPos = nil
    
    for _, part in ipairs(tower:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "RootPart" then
            towerPos = part.Position
            break
        end
    end
    
    if not towerPos then
        for _, part in ipairs(tower:GetDescendants()) do
            if part:IsA("BasePart") then
                towerPos = part.Position
                break
            end
        end
    end
    
    if not towerPos then return nil end
    
    for i, pending in ipairs(pendingPlacements) do
        local distance = (towerPos - pending.Position).Magnitude
        
        if distance < 10 then
            table.remove(pendingPlacements, i)
            return pending
        end
    end
    
    return nil
end

-- ========== CLEANUP ==========
local function CleanupDeletedTowers()
    local currentTowers = {}
    
    local towers = workspace:FindFirstChild("Towers")
    
    if towers then
        for _, tower in ipairs(towers:GetChildren()) do
            if tower:IsA("Model") then
                currentTowers[tower] = true
            end
        end
    end
    
    for tower, data in pairs(towerRegistry) do
        if not currentTowers[tower] then
            local unitName = data.UnitName
            
            if unitName and towerNameCounters[unitName] then
                towerNameCounters[unitName] = math.max(0, towerNameCounters[unitName] - 1)
            end
            
            towerRegistry[tower] = nil
            towerLevels[tower] = nil
            selectedBatch[tower] = nil
            healerTargets[tower] = nil
            batchHealTargets[tower] = nil
        end
    end
    
    -- Cleanup healerLinks untuk tower yang sudah hilang
    for healer, targets in pairs(healerLinks) do
        if not currentTowers[healer] then
            healerLinks[healer] = nil
        else
            for target, active in pairs(targets) do
                if not currentTowers[target] then
                    targets[target] = nil
                end
            end
        end
    end
    
    if not currentTowers[activeHealer] then
        activeHealer = nil
        healerTargets = {}
    end
    
    if selectedTower and not selectedTower.Parent then
        selectedTower = nil
        UpgradePanel.Visible = false
    end
end

-- ========== FIND ==========
local function FindAllMyTowers()
    local towers = workspace:FindFirstChild("Towers")
    if not towers then return {} end
    
    local myTowers = {}
    
    for _, tower in ipairs(towers:GetChildren()) do
        if tower:IsA("Model") then
            local owner = tower:FindFirstChild("Owner")
            
            if owner and owner.Value == LocalPlayer.UserId then
                table.insert(myTowers, tower)
            elseif not owner then
                table.insert(myTowers, tower)
            end
        end
    end
    
    return myTowers
end

local function GetTowerPosition(tower)
    for _, part in ipairs(tower:GetDescendants()) do
        if part:IsA("BasePart") and part.Name == "RootPart" then
            return part.Position
        end
    end
    
    for _, part in ipairs(tower:GetDescendants()) do
        if part:IsA("BasePart") then
            return part.Position
        end
    end
    
    return nil
end

-- ========== GET TOWER INFO ==========
local function GetTowerInfo(tower)
    if not tower or not tower.Parent then return nil end
    
    local registered = towerRegistry[tower]
    
    local info = {
        Name = tower.Name,
        UnitName = registered and registered.UnitName or "Unknown",
        DisplayName = registered and registered.DisplayName or "Unknown",
        Cost = registered and registered.Cost or 0,
        Level = tostring(towerLevels[tower] or 0),
        Position = "?",
    }
    
    if not registered then
        local match = MatchTowerWithPlacement(tower)
        
        if match then
            info.UnitName = match.UnitName
            
            if not towerNameCounters[match.UnitName] then
                towerNameCounters[match.UnitName] = 0
            end
            
            towerNameCounters[match.UnitName] = towerNameCounters[match.UnitName] + 1
            
            local count = towerNameCounters[match.UnitName]
            
            if count > 1 then
                info.DisplayName = string.format("%s #%d", match.UnitName, count)
            else
                info.DisplayName = match.UnitName
            end
            
            if getgenv().TowerDatabase then
                info.Cost = getgenv().TowerDatabase.GetCost(match.UnitName)
            end
            
            towerRegistry[tower] = {
                UnitName = match.UnitName,
                DisplayName = info.DisplayName,
                Cost = info.Cost,
            }
        end
    end
    
    local pos = GetTowerPosition(tower)
    
    if pos then
        info.Position = string.format("(%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z)
    end
    
    return info
end

-- ========== FIND HEALERS ==========
local function FindAllHealers()
    local myTowers = FindAllMyTowers()
    local healers = {}
    
    for _, tower in ipairs(myTowers) do
        if tower.Parent then
            local info = GetTowerInfo(tower)
            
            if info then
                local un = info.UnitName:lower()
                
                if un:find("medic") or un:find("healer") or un:find("doctor") or un:find("support") then
                    table.insert(healers, tower)
                end
            end
        end
    end
    
    if #healers == 0 and getgenv().CurrentHealer and getgenv().CurrentHealer.Parent then
        table.insert(healers, getgenv().CurrentHealer)
    end
    
    return healers
end

-- ========== CHECK HEAL LINK ==========
local function IsHealLinked(tower)
    for healer, targets in pairs(healerLinks) do
        if targets[tower] then
            return true
        end
    end
    
    return false
end

local function IsLinkedToHealer(healer, target)
    return healerLinks[healer] and healerLinks[healer][target] == true
end

-- ========== COUNT HEALER LINKS ==========
local function GetHealerLinkCount(healer)
    if not healerLinks[healer] then return 0 end
    
    local count = 0
    
    for target, active in pairs(healerLinks[healer]) do
        if active and target.Parent then
            count = count + 1
        end
    end
    
    return count
end

-- ========== UPGRADE ==========
local function UpgradeTower(tower, pathType)
    if not tower or not tower.Parent then return end
    
    local pathNumber = 1
    if pathType == "Bottom" then pathNumber = 2 end
    
    local realName = tower:GetAttribute("UnitName") or tower.Name
    
    task.spawn(function()
        task.wait(0.05)
        
        pcall(function()
            RemoteEvent:FireServer("Streaming", "SelectTower", realName, tower.Name)
        end)
        task.wait(0.1)
        
        pcall(function()
            RemoteFunction:InvokeServer("Troops", "Upgrade", "Set", {
                Troop = tower,
                Path = pathNumber
            })
        end)
        task.wait(0.05)
        
        pcall(function()
            RemoteEvent:FireServer("Streaming", "UnselectTower")
        end)
        
        task.wait(0.1)
        RefreshList()
        UpdatePanelInfo()
    end)
end

local function UpgradeSelectedBatch(pathType)
    local batchTowers = {}
    
    for tower, selected in pairs(selectedBatch) do
        if selected and tower.Parent then
            table.insert(batchTowers, tower)
        end
    end
    
    if #batchTowers == 0 then return end
    
    for i, tower in ipairs(batchTowers) do
        if tower.Parent then
            UpgradeTower(tower, pathType)
            task.wait(0.15)
        end
    end
end

-- ========== HEALER LINK APPLY (SINGLE HEALER) ==========
local function ApplyHealerLinks()
    if not activeHealer or not activeHealer.Parent then
        print("[Healer] ❌ Pilih healer dulu")
        return
    end
    
    local targets = {}
    
    for tower, selected in pairs(healerTargets) do
        if selected and tower.Parent and tower ~= activeHealer then
            table.insert(targets, tower)
        end
    end
    
    if #targets == 0 then
        print("[Healer] ❌ Nggak ada target di-select")
        return
    end
    
    print(string.format("[Healer] Linking %d towers ke %s...", #targets, activeHealer.Name))
    
    for _, target in ipairs(targets) do
        if target ~= activeHealer then
            pcall(function()
                RemoteFunction:InvokeServer("Troops", "TowerServerEvent", "ToggleSelectedTower", activeHealer, target)
            end)
            
            task.wait(0.15)
        end
    end
    
    print("[Healer] ✅ Selesai link")
    
    healerTargets = {}
    UpdateHealerStatus()
    RefreshList()
end

-- ========== BATCH HEAL APPLY ==========
local function ApplyBatchHeal()
    local healers = FindAllHealers()
    
    if #healers == 0 then
        print("[BatchHeal] ❌ Nggak ada healer")
        return
    end
    
    local targets = {}
    
    for tower, selected in pairs(batchHealTargets) do
        if selected and tower.Parent then
            local isHealer = false
            
            for _, h in ipairs(healers) do
                if h == tower then
                    isHealer = true
                    break
                end
            end
            
            if not isHealer then
                table.insert(targets, tower)
            end
        end
    end
    
    if #targets == 0 then
        print("[BatchHeal] ❌ Nggak ada target di-select")
        return
    end
    
    print(string.format("[BatchHeal] Distributing %d healers ke %d targets...", #healers, #targets))
    
    local healerIndex = 1
    local linkCount = 0
    
    for _, target in ipairs(targets) do
        local assigned = false
        
        for attempt = 1, #healers do
            local healer = healers[healerIndex]
            
            healerIndex = healerIndex + 1
            if healerIndex > #healers then
                healerIndex = 1
            end
            
            if healer and healer.Parent and healer ~= target then
                local currentLinks = GetHealerLinkCount(healer)
                
                -- Skip kalau sudah ter-link
                if IsLinkedToHealer(healer, target) then
                    assigned = true
                    print(string.format("[BatchHeal] Skip (already linked): %s -> %s", healer.Name, target.Name))
                    break
                end
                
                if currentLinks < healSlotCapacity then
                    pcall(function()
                        RemoteFunction:InvokeServer("Troops", "TowerServerEvent", "ToggleSelectedTower", healer, target)
                    end)
                    
                    linkCount = linkCount + 1
                    assigned = true
                    print(string.format("[BatchHeal] %s -> %s", healer.Name, target.Name))
                    
                    task.wait(0.1)
                    break
                end
            end
        end
        
        if not assigned then
            print(string.format("[BatchHeal] ⚠️ Nggak ada slot buat %s", target.Name))
        end
    end
    
    print(string.format("[BatchHeal] ✅ Selesai. %d link dibuat", linkCount))
    
    batchHealTargets = {}
    UpdateBatchHealCount()
    RefreshList()
end

-- ========== BATCH HEAL UNAPPLY ==========
local function UnapplyBatchHeal()
    local healers = FindAllHealers()
    
    if #healers == 0 then
        print("[BatchHeal] ❌ Nggak ada healer")
        return
    end
    
    local targets = {}
    
    for tower, selected in pairs(batchHealTargets) do
        if selected and tower.Parent then
            table.insert(targets, tower)
        end
    end
    
    if #targets == 0 then
        print("[BatchHeal] ❌ Nggak ada target di-select")
        return
    end
    
    print(string.format("[BatchHeal] Unlinking %d targets dari %d healers...", #targets, #healers))
    
    local unlinkCount = 0
    
    for _, healer in ipairs(healers) do
        if healer.Parent then
            for _, target in ipairs(targets) do
                if target.Parent and IsLinkedToHealer(healer, target) then
                    pcall(function()
                        RemoteFunction:InvokeServer("Troops", "TowerServerEvent", "ToggleSelectedTower", healer, target)
                    end)
                    
                    unlinkCount = unlinkCount + 1
                    print(string.format("[BatchHeal] Unlink: %s -> %s", healer.Name, target.Name))
                    
                    task.wait(0.1)
                end
            end
        end
    end
    
    print(string.format("[BatchHeal] ✅ Selesai. %d link dihapus", unlinkCount))
    
    batchHealTargets = {}
    UpdateBatchHealCount()
    RefreshList()
end

-- ========== SELL ==========
local function SellTower(tower)
    if not tower or not tower.Parent then return end
    
    task.spawn(function()
        task.wait(0.05)
        
        pcall(function()
            RemoteFunction:InvokeServer("Troops", "Sell", {
                Troop = tower
            })
        end)
        
        task.wait(0.3)
        RefreshList()
        
        if selectedTower == tower then
            selectedTower = nil
            UpgradePanel.Visible = false
        end
    end)
end

local function SellAllTowers()
    local myTowers = FindAllMyTowers()
    
    for i, tower in ipairs(myTowers) do
        if tower.Parent then
            pcall(function()
                RemoteFunction:InvokeServer("Troops", "Sell", {
                    Troop = tower
                })
            end)
            task.wait(0.1)
        end
    end
    
    task.wait(1)
    RefreshList()
    selectedTower = nil
    UpgradePanel.Visible = false
end

-- ========== MAIN UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TowerManagerUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 520)
MainFrame.Position = UDim2.new(0, 10, 0, 30)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 150, 0, 40)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
TitleLabel.Text = "🏗️ MY TOWERS"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(0, 30, 0, 25)
RefreshButton.Position = UDim2.new(1, -95, 0.5, -12)
RefreshButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
RefreshButton.BorderSizePixel = 0
RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshButton.Text = "🔄"
RefreshButton.Font = Enum.Font.GothamBold
RefreshButton.TextSize = 12
RefreshButton.Parent = Header

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 4)
RefreshCorner.Parent = RefreshButton

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 25)
MinimizeButton.Position = UDim2.new(1, -65, 0.5, -12)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Text = "—"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 14
MinimizeButton.Parent = Header

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 4)
MinimizeCorner.Parent = MinimizeButton

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 25)
CloseButton.Position = UDim2.new(1, -32, 0.5, -12)
CloseButton.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
CloseButton.BorderSizePixel = 0
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "×"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseButton

-- BATCH MODE
local BatchModeButton = Instance.new("TextButton")
BatchModeButton.Size = UDim2.new(1, -20, 0, 28)
BatchModeButton.Position = UDim2.new(0, 10, 0, 45)
BatchModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BatchModeButton.BorderSizePixel = 0
BatchModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BatchModeButton.Text = "🔘 BATCH MODE: OFF"
BatchModeButton.Font = Enum.Font.GothamBold
BatchModeButton.TextSize = 10
BatchModeButton.Parent = MainFrame

local BatchModeCorner = Instance.new("UICorner")
BatchModeCorner.CornerRadius = UDim.new(0, 5)
BatchModeCorner.Parent = BatchModeButton

-- HEALER MODE
local HealerModeButton = Instance.new("TextButton")
HealerModeButton.Size = UDim2.new(1, -20, 0, 28)
HealerModeButton.Position = UDim2.new(0, 10, 0, 78)
HealerModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
HealerModeButton.BorderSizePixel = 0
HealerModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HealerModeButton.Text = "💚 HEALER MODE: OFF"
HealerModeButton.Font = Enum.Font.GothamBold
HealerModeButton.TextSize = 10
HealerModeButton.Parent = MainFrame

local HealerModeCorner = Instance.new("UICorner")
HealerModeCorner.CornerRadius = UDim.new(0, 5)
HealerModeCorner.Parent = HealerModeButton

-- BATCH HEAL MODE
local BatchHealModeButton = Instance.new("TextButton")
BatchHealModeButton.Size = UDim2.new(1, -20, 0, 28)
BatchHealModeButton.Position = UDim2.new(0, 10, 0, 111)
BatchHealModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BatchHealModeButton.BorderSizePixel = 0
BatchHealModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BatchHealModeButton.Text = "💚🔄 BATCH HEAL: OFF"
BatchHealModeButton.Font = Enum.Font.GothamBold
BatchHealModeButton.TextSize = 10
BatchHealModeButton.Parent = MainFrame

local BatchHealModeCorner = Instance.new("UICorner")
BatchHealModeCorner.CornerRadius = UDim.new(0, 5)
BatchHealModeCorner.Parent = BatchHealModeButton

-- BATCH UPGRADE ACTIONS
local BatchActionsFrame = Instance.new("Frame")
BatchActionsFrame.Size = UDim2.new(1, -20, 0, 50)
BatchActionsFrame.Position = UDim2.new(0, 10, 0, 144)
BatchActionsFrame.BackgroundTransparency = 1
BatchActionsFrame.Visible = false
BatchActionsFrame.Parent = MainFrame

local BatchUpgradeEButton = Instance.new("TextButton")
BatchUpgradeEButton.Size = UDim2.new(0, 110, 0, 22)
BatchUpgradeEButton.Position = UDim2.new(0, 0, 0, 0)
BatchUpgradeEButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
BatchUpgradeEButton.BorderSizePixel = 0
BatchUpgradeEButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BatchUpgradeEButton.Text = "⬆️ BATCH [E]"
BatchUpgradeEButton.Font = Enum.Font.GothamBold
BatchUpgradeEButton.TextSize = 9
BatchUpgradeEButton.Parent = BatchActionsFrame

local BatchUpgradeECorner = Instance.new("UICorner")
BatchUpgradeECorner.CornerRadius = UDim.new(0, 4)
BatchUpgradeECorner.Parent = BatchUpgradeEButton

local BatchUpgradeZButton = Instance.new("TextButton")
BatchUpgradeZButton.Size = UDim2.new(0, 110, 0, 22)
BatchUpgradeZButton.Position = UDim2.new(0, 120, 0, 0)
BatchUpgradeZButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
BatchUpgradeZButton.BorderSizePixel = 0
BatchUpgradeZButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BatchUpgradeZButton.Text = "⬇️ BATCH [Z]"
BatchUpgradeZButton.Font = Enum.Font.GothamBold
BatchUpgradeZButton.TextSize = 9
BatchUpgradeZButton.Parent = BatchActionsFrame

local BatchUpgradeZCorner = Instance.new("UICorner")
BatchUpgradeZCorner.CornerRadius = UDim.new(0, 4)
BatchUpgradeZCorner.Parent = BatchUpgradeZButton

local ClearBatchButton = Instance.new("TextButton")
ClearBatchButton.Size = UDim2.new(0, 110, 0, 22)
ClearBatchButton.Position = UDim2.new(0, 0, 0, 25)
ClearBatchButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ClearBatchButton.BorderSizePixel = 0
ClearBatchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBatchButton.Text = "CLEAR"
ClearBatchButton.Font = Enum.Font.GothamBold
ClearBatchButton.TextSize = 9
ClearBatchButton.Parent = BatchActionsFrame

local ClearBatchCorner = Instance.new("UICorner")
ClearBatchCorner.CornerRadius = UDim.new(0, 4)
ClearBatchCorner.Parent = ClearBatchButton

local BatchCountLabel = Instance.new("TextLabel")
BatchCountLabel.Size = UDim2.new(0, 110, 0, 22)
BatchCountLabel.Position = UDim2.new(0, 120, 0, 25)
BatchCountLabel.BackgroundTransparency = 1
BatchCountLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
BatchCountLabel.Text = "Selected: 0"
BatchCountLabel.Font = Enum.Font.Gotham
BatchCountLabel.TextSize = 9
BatchCountLabel.TextXAlignment = Enum.TextXAlignment.Center
BatchCountLabel.Parent = BatchActionsFrame

-- BATCH HEAL ACTIONS
local BatchHealActionsFrame = Instance.new("Frame")
BatchHealActionsFrame.Size = UDim2.new(1, -20, 0, 75)
BatchHealActionsFrame.Position = UDim2.new(0, 10, 0, 144)
BatchHealActionsFrame.BackgroundTransparency = 1
BatchHealActionsFrame.Visible = false
BatchHealActionsFrame.Parent = MainFrame

local BatchHealApplyBtn = Instance.new("TextButton")
BatchHealApplyBtn.Size = UDim2.new(0, 110, 0, 22)
BatchHealApplyBtn.Position = UDim2.new(0, 0, 0, 0)
BatchHealApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
BatchHealApplyBtn.BorderSizePixel = 0
BatchHealApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BatchHealApplyBtn.Text = "💚 APPLY MEDIC"
BatchHealApplyBtn.Font = Enum.Font.GothamBold
BatchHealApplyBtn.TextSize = 9
BatchHealApplyBtn.Parent = BatchHealActionsFrame

local BatchHealApplyCorner = Instance.new("UICorner")
BatchHealApplyCorner.CornerRadius = UDim.new(0, 4)
BatchHealApplyCorner.Parent = BatchHealApplyBtn

local BatchHealUnapplyBtn = Instance.new("TextButton")
BatchHealUnapplyBtn.Size = UDim2.new(0, 110, 0, 22)
BatchHealUnapplyBtn.Position = UDim2.new(0, 120, 0, 0)
BatchHealUnapplyBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 40)
BatchHealUnapplyBtn.BorderSizePixel = 0
BatchHealUnapplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BatchHealUnapplyBtn.Text = "💔 UNAPPLY"
BatchHealUnapplyBtn.Font = Enum.Font.GothamBold
BatchHealUnapplyBtn.TextSize = 9
BatchHealUnapplyBtn.Parent = BatchHealActionsFrame

local BatchHealUnapplyCorner = Instance.new("UICorner")
BatchHealUnapplyCorner.CornerRadius = UDim.new(0, 4)
BatchHealUnapplyCorner.Parent = BatchHealUnapplyBtn

local ClearBatchHealButton = Instance.new("TextButton")
ClearBatchHealButton.Size = UDim2.new(1, 0, 0, 22)
ClearBatchHealButton.Position = UDim2.new(0, 0, 0, 25)
ClearBatchHealButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ClearBatchHealButton.BorderSizePixel = 0
ClearBatchHealButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBatchHealButton.Text = "CLEAR"
ClearBatchHealButton.Font = Enum.Font.GothamBold
ClearBatchHealButton.TextSize = 9
ClearBatchHealButton.Parent = BatchHealActionsFrame

local ClearBatchHealCorner = Instance.new("UICorner")
ClearBatchHealCorner.CornerRadius = UDim.new(0, 4)
ClearBatchHealCorner.Parent = ClearBatchHealButton

local BatchHealCountLabel = Instance.new("TextLabel")
BatchHealCountLabel.Size = UDim2.new(1, 0, 0, 22)
BatchHealCountLabel.Position = UDim2.new(0, 0, 0, 50)
BatchHealCountLabel.BackgroundTransparency = 1
BatchHealCountLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
BatchHealCountLabel.Text = "Targets: 0"
BatchHealCountLabel.Font = Enum.Font.Gotham
BatchHealCountLabel.TextSize = 9
BatchHealCountLabel.TextXAlignment = Enum.TextXAlignment.Center
BatchHealCountLabel.Parent = BatchHealActionsFrame

-- Filter
local FilterButton = Instance.new("TextButton")
FilterButton.Size = UDim2.new(1, -20, 0, 28)
FilterButton.Position = UDim2.new(0, 10, 0, 224)
FilterButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
FilterButton.BorderSizePixel = 0
FilterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterButton.Text = "Filter: All"
FilterButton.Font = Enum.Font.GothamBold
FilterButton.TextSize = 11
FilterButton.Parent = MainFrame

local FilterCorner = Instance.new("UICorner")
FilterCorner.CornerRadius = UDim.new(0, 5)
FilterCorner.Parent = FilterButton

local SellAllButton = Instance.new("TextButton")
SellAllButton.Size = UDim2.new(1, -20, 0, 25)
SellAllButton.Position = UDim2.new(0, 10, 0, 257)
SellAllButton.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
SellAllButton.BorderSizePixel = 0
SellAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SellAllButton.Text = "💰 SELL ALL"
SellAllButton.Font = Enum.Font.GothamBold
SellAllButton.TextSize = 10
SellAllButton.Parent = MainFrame

local SellAllCorner = Instance.new("UICorner")
SellAllCorner.CornerRadius = UDim.new(0, 5)
SellAllCorner.Parent = SellAllButton

local TowerScroll = Instance.new("ScrollingFrame")
TowerScroll.Size = UDim2.new(1, 0, 1, -345)
TowerScroll.Position = UDim2.new(0, 0, 0, 291)
TowerScroll.BackgroundTransparency = 1
TowerScroll.ScrollBarThickness = 4
TowerScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 60)
TowerScroll.CanvasSize = UDim2.new(0, 0, 0, 1000)
TowerScroll.Parent = MainFrame

local TowerLayout = Instance.new("UIListLayout")
TowerLayout.SortOrder = Enum.SortOrder.LayoutOrder
TowerLayout.Padding = UDim.new(0, 3)
TowerLayout.Parent = TowerScroll

local TowerPadding = Instance.new("UIPadding")
TowerPadding.PaddingLeft = UDim.new(0, 6)
TowerPadding.PaddingRight = UDim.new(0, 6)
TowerPadding.PaddingTop = UDim.new(0, 6)
TowerPadding.Parent = TowerScroll

-- Pagination
local PageFrame = Instance.new("Frame")
PageFrame.Size = UDim2.new(1, -20, 0, 30)
PageFrame.Position = UDim2.new(0, 10, 0, 485)
PageFrame.BackgroundTransparency = 1
PageFrame.Parent = MainFrame

local PrevPageButton = Instance.new("TextButton")
PrevPageButton.Size = UDim2.new(0, 60, 0, 25)
PrevPageButton.Position = UDim2.new(0, 0, 0, 2)
PrevPageButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
PrevPageButton.BorderSizePixel = 0
PrevPageButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PrevPageButton.Text = "◀ PREV"
PrevPageButton.Font = Enum.Font.GothamBold
PrevPageButton.TextSize = 9
PrevPageButton.Parent = PageFrame

local PrevPageCorner = Instance.new("UICorner")
PrevPageCorner.CornerRadius = UDim.new(0, 4)
PrevPageCorner.Parent = PrevPageButton

local PageLabel = Instance.new("TextLabel")
PageLabel.Size = UDim2.new(0, 100, 0, 25)
PageLabel.Position = UDim2.new(0, 70, 0, 2)
PageLabel.BackgroundTransparency = 1
PageLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
PageLabel.Text = "1/1"
PageLabel.Font = Enum.Font.GothamBold
PageLabel.TextSize = 10
PageLabel.TextXAlignment = Enum.TextXAlignment.Center
PageLabel.Parent = PageFrame

local NextPageButton = Instance.new("TextButton")
NextPageButton.Size = UDim2.new(0, 60, 0, 25)
NextPageButton.Position = UDim2.new(0, 180, 0, 2)
NextPageButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
NextPageButton.BorderSizePixel = 0
NextPageButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NextPageButton.Text = "NEXT ▶"
NextPageButton.Font = Enum.Font.GothamBold
NextPageButton.TextSize = 9
NextPageButton.Parent = PageFrame

local NextPageCorner = Instance.new("UICorner")
NextPageCorner.CornerRadius = UDim.new(0, 4)
NextPageCorner.Parent = NextPageButton

-- Upgrade panel
local UpgradePanel = Instance.new("Frame")
UpgradePanel.Size = UDim2.new(0, 230, 0, 280)
UpgradePanel.Position = UDim2.new(0, 300, 0, 80)
UpgradePanel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
UpgradePanel.BorderSizePixel = 0
UpgradePanel.Visible = false
UpgradePanel.Parent = ScreenGui

local UpgradeCorner = Instance.new("UICorner")
UpgradeCorner.CornerRadius = UDim.new(0, 10)
UpgradeCorner.Parent = UpgradePanel

local UpgradeHeader = Instance.new("Frame")
UpgradeHeader.Size = UDim2.new(1, 0, 0, 35)
UpgradeHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
UpgradeHeader.BorderSizePixel = 0
UpgradeHeader.Parent = UpgradePanel

local UpgradeHeaderCorner = Instance.new("UICorner")
UpgradeHeaderCorner.CornerRadius = UDim.new(0, 10)
UpgradeHeaderCorner.Parent = UpgradeHeader

local UpgradeTitle = Instance.new("TextLabel")
UpgradeTitle.Size = UDim2.new(1, -20, 0, 35)
UpgradeTitle.Position = UDim2.new(0, 10, 0, 0)
UpgradeTitle.BackgroundTransparency = 1
UpgradeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
UpgradeTitle.Text = "TOWER INFO"
UpgradeTitle.Font = Enum.Font.GothamBlack
UpgradeTitle.TextSize = 12
UpgradeTitle.TextXAlignment = Enum.TextXAlignment.Left
UpgradeTitle.Parent = UpgradeHeader

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 70)
InfoLabel.Position = UDim2.new(0, 10, 0, 40)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
InfoLabel.Text = "..."
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 10
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.TextWrapped = true
InfoLabel.Parent = UpgradePanel

local UpgradeEButton = Instance.new("TextButton")
UpgradeEButton.Size = UDim2.new(1, -20, 0, 38)
UpgradeEButton.Position = UDim2.new(0, 10, 0, 115)
UpgradeEButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
UpgradeEButton.BorderSizePixel = 0
UpgradeEButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UpgradeEButton.Text = "🟩 UPGRADE [E]"
UpgradeEButton.Font = Enum.Font.GothamBold
UpgradeEButton.TextSize = 12
UpgradeEButton.Parent = UpgradePanel

local UpgradeECorner = Instance.new("UICorner")
UpgradeECorner.CornerRadius = UDim.new(0, 8)
UpgradeECorner.Parent = UpgradeEButton

local UpgradeZButton = Instance.new("TextButton")
UpgradeZButton.Size = UDim2.new(1, -20, 0, 38)
UpgradeZButton.Position = UDim2.new(0, 10, 0, 158)
UpgradeZButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
UpgradeZButton.BorderSizePixel = 0
UpgradeZButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UpgradeZButton.Text = "🟦 UPGRADE [Z]"
UpgradeZButton.Font = Enum.Font.GothamBold
UpgradeZButton.TextSize = 12
UpgradeZButton.Parent = UpgradePanel

local UpgradeZCorner = Instance.new("UICorner")
UpgradeZCorner.CornerRadius = UDim.new(0, 8)
UpgradeZCorner.Parent = UpgradeZButton

local SellTowerButton = Instance.new("TextButton")
SellTowerButton.Size = UDim2.new(1, -20, 0, 38)
SellTowerButton.Position = UDim2.new(0, 10, 0, 201)
SellTowerButton.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
SellTowerButton.BorderSizePixel = 0
SellTowerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SellTowerButton.Text = "💰 SELL TOWER"
SellTowerButton.Font = Enum.Font.GothamBold
SellTowerButton.TextSize = 12
SellTowerButton.Parent = UpgradePanel

local SellTowerCorner = Instance.new("UICorner")
SellTowerCorner.CornerRadius = UDim.new(0, 8)
SellTowerCorner.Parent = SellTowerButton

-- ========== HEALER PANEL (SEPARATE UI) ==========
local HealerPanel = Instance.new("Frame")
HealerPanel.Name = "HealerPanel"
HealerPanel.Size = UDim2.new(0, 240, 0, 300)
HealerPanel.Position = UDim2.new(0, 300, 0, 80)
HealerPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
HealerPanel.BorderSizePixel = 0
HealerPanel.Visible = false
HealerPanel.Parent = ScreenGui

local HealerPanelCorner = Instance.new("UICorner")
HealerPanelCorner.CornerRadius = UDim.new(0, 10)
HealerPanelCorner.Parent = HealerPanel

local HealerPanelHeader = Instance.new("Frame")
HealerPanelHeader.Size = UDim2.new(1, 0, 0, 35)
HealerPanelHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
HealerPanelHeader.BorderSizePixel = 0
HealerPanelHeader.Parent = HealerPanel

local HealerPanelHeaderCorner = Instance.new("UICorner")
HealerPanelHeaderCorner.CornerRadius = UDim.new(0, 10)
HealerPanelHeaderCorner.Parent = HealerPanelHeader

local HealerPanelTitle = Instance.new("TextLabel")
HealerPanelTitle.Size = UDim2.new(1, -20, 0, 35)
HealerPanelTitle.Position = UDim2.new(0, 10, 0, 0)
HealerPanelTitle.BackgroundTransparency = 1
HealerPanelTitle.TextColor3 = Color3.fromRGB(0, 255, 150)
HealerPanelTitle.Text = "💚 PICK HEALER"
HealerPanelTitle.Font = Enum.Font.GothamBlack
HealerPanelTitle.TextSize = 12
HealerPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
HealerPanelTitle.Parent = HealerPanelHeader

local HealerPanelClose = Instance.new("TextButton")
HealerPanelClose.Size = UDim2.new(0, 30, 0, 25)
HealerPanelClose.Position = UDim2.new(1, -32, 0.5, -12)
HealerPanelClose.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
HealerPanelClose.BorderSizePixel = 0
HealerPanelClose.TextColor3 = Color3.fromRGB(255, 255, 255)
HealerPanelClose.Text = "×"
HealerPanelClose.Font = Enum.Font.GothamBold
HealerPanelClose.TextSize = 14
HealerPanelClose.Parent = HealerPanelHeader

local HealerPanelCloseCorner = Instance.new("UICorner")
HealerPanelCloseCorner.CornerRadius = UDim.new(0, 4)
HealerPanelCloseCorner.Parent = HealerPanelClose

local HealerStatusLabel = Instance.new("TextLabel")
HealerStatusLabel.Size = UDim2.new(1, -20, 0, 20)
HealerStatusLabel.Position = UDim2.new(0, 10, 0, 40)
HealerStatusLabel.BackgroundTransparency = 1
HealerStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
HealerStatusLabel.Text = "Active: None"
HealerStatusLabel.Font = Enum.Font.Gotham
HealerStatusLabel.TextSize = 10
HealerStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
HealerStatusLabel.Parent = HealerPanel

local HealerScroll = Instance.new("ScrollingFrame")
HealerScroll.Size = UDim2.new(1, -20, 0, 180)
HealerScroll.Position = UDim2.new(0, 10, 0, 62)
HealerScroll.BackgroundTransparency = 1
HealerScroll.ScrollBarThickness = 3
HealerScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 60)
HealerScroll.CanvasSize = UDim2.new(0, 0, 0, 400)
HealerScroll.Parent = HealerPanel

local HealerLayout = Instance.new("UIListLayout")
HealerLayout.SortOrder = Enum.SortOrder.LayoutOrder
HealerLayout.Padding = UDim.new(0, 4)
HealerLayout.Parent = HealerScroll

local ApplyHealerBtn = Instance.new("TextButton")
ApplyHealerBtn.Size = UDim2.new(1, -20, 0, 28)
ApplyHealerBtn.Position = UDim2.new(0, 10, 0, 252)
ApplyHealerBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
ApplyHealerBtn.BorderSizePixel = 0
ApplyHealerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyHealerBtn.Text = "💚 APPLY LINK"
ApplyHealerBtn.Font = Enum.Font.GothamBold
ApplyHealerBtn.TextSize = 10
ApplyHealerBtn.Parent = HealerPanel

local ApplyHealerCorner = Instance.new("UICorner")
ApplyHealerCorner.CornerRadius = UDim.new(0, 5)
ApplyHealerCorner.Parent = ApplyHealerBtn

-- ========== FUNCTIONS ==========
local function UpdateBatchCount()
    local count = 0
    
    for tower, selected in pairs(selectedBatch) do
        if selected and tower.Parent then
            count = count + 1
        end
    end
    
    BatchCountLabel.Text = "Selected: " .. count
end

local function UpdateBatchHealCount()
    local count = 0
    
    for tower, selected in pairs(batchHealTargets) do
        if selected and tower.Parent then
            count = count + 1
        end
    end
    
    local healerCount = #FindAllHealers()
    BatchHealCountLabel.Text = string.format("Targets: %d | Healers: %d", count, healerCount)
end

local function UpdateHealerStatus()
    if activeHealer and activeHealer.Parent then
        local info = GetTowerInfo(activeHealer)
        local targetCount = 0
        
        for tower, selected in pairs(healerTargets) do
            if selected and tower.Parent then
                targetCount = targetCount + 1
            end
        end
        
        HealerStatusLabel.Text = string.format("Active: %s | Targets: %d", 
            info and info.DisplayName or activeHealer.Name, targetCount)
    else
        HealerStatusLabel.Text = "Active: None"
    end
end

local function RefreshHealerPanel()
    for _, child in ipairs(HealerScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local healers = FindAllHealers()
    healerListCache = healers
    
    if #healers == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 30)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
        emptyLabel.Text = "No healer found"
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 10
        emptyLabel.Parent = HealerScroll
        return
    end
    
    for _, healer in ipairs(healers) do
        local info = GetTowerInfo(healer)
        local isActive = activeHealer == healer
        local linkCount = GetHealerLinkCount(healer)
        
        local healerBtn = Instance.new("TextButton")
        healerBtn.Size = UDim2.new(1, 0, 0, 35)
        healerBtn.BackgroundColor3 = isActive and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(24, 24, 34)
        healerBtn.BorderSizePixel = 0
        healerBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        healerBtn.Text = string.format("%s %s | Lv.%s | %d/%d",
            isActive and "✅" or "",
            info and info.DisplayName or healer.Name,
            info and info.Level or "?",
            linkCount,
            healSlotCapacity)
        healerBtn.Font = Enum.Font.GothamBold
        healerBtn.TextSize = 9
        healerBtn.Parent = HealerScroll
        
        local healerCorner = Instance.new("UICorner")
        healerCorner.CornerRadius = UDim.new(0, 4)
        healerCorner.Parent = healerBtn
        
        healerBtn.MouseButton1Click:Connect(function()
            activeHealer = healer
            healerTargets = {}
            getgenv().CurrentHealer = healer
            UpdateHealerStatus()
            RefreshHealerPanel()
            RefreshList()
        end)
    end
end

local function UpdatePanelInfo()
    if not selectedTower or not selectedTower.Parent then
        UpgradePanel.Visible = false
        selectedTower = nil
        return
    end
    
    local info = GetTowerInfo(selectedTower)
    
    if info then
        local healStatus = IsHealLinked(selectedTower) and "💚 HEALED" or "NO HEAL"
        
        InfoLabel.Text = string.format(
            "🏷️ %s\n💰 Cost: $%d\n📍 %s\n⚡ Level: %s\n%s",
            info.DisplayName,
            info.Cost,
            info.Position,
            info.Level,
            healStatus
        )
        
        UpgradePanel.Visible = true
    end
end

local function RefreshList()
    CleanupDeletedTowers()
    
    for _, child in ipairs(TowerScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local myTowers = FindAllMyTowers()
    towerList = myTowers
    
    local groups = {}
    local groupOrder = {}
    
    for _, tower in ipairs(myTowers) do
        if tower.Parent then
            local info = GetTowerInfo(tower)
            
            if info then
                local unitName = info.UnitName
                
                if not groups[unitName] then
                    groups[unitName] = {}
                    table.insert(groupOrder, unitName)
                end
                
                table.insert(groups[unitName], {
                    Tower = tower,
                    Info = info,
                })
            end
        end
    end
    
    local filteredGroups = {}
    
    for _, unitName in ipairs(groupOrder) do
        if currentFilter == "All" or currentFilter == unitName then
            table.insert(filteredGroups, unitName)
        end
    end
    
    totalPages = math.max(1, math.ceil(#filteredGroups / groupsPerPage))
    
    if currentPage > totalPages then
        currentPage = totalPages
    end
    
    PageLabel.Text = string.format("%d/%d", currentPage, totalPages)
    
    local startIndex = (currentPage - 1) * groupsPerPage + 1
    local endIndex = math.min(currentPage * groupsPerPage, #filteredGroups)
    
    for gi = startIndex, endIndex do
        local unitName = filteredGroups[gi]
        local groupTowers = groups[unitName]
        local isCollapsed = collapsedGroups[unitName] == true
        
        local groupHeader = Instance.new("Frame")
        groupHeader.Size = UDim2.new(1, -10, 0, 30)
        groupHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        groupHeader.BorderSizePixel = 0
        groupHeader.Parent = TowerScroll
        
        local groupCorner = Instance.new("UICorner")
        groupCorner.CornerRadius = UDim.new(0, 5)
        groupCorner.Parent = groupHeader
        
        local groupLabel = Instance.new("TextButton")
        groupLabel.Size = UDim2.new(1, 0, 1, 0)
        groupLabel.BackgroundTransparency = 1
        groupLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        groupLabel.Text = string.format("%s %s (%d)", 
            isCollapsed and "▶" or "▼", unitName, #groupTowers)
        groupLabel.Font = Enum.Font.GothamBold
        groupLabel.TextSize = 11
        groupLabel.TextXAlignment = Enum.TextXAlignment.Left
        groupLabel.Parent = groupHeader
        
        groupLabel.MouseButton1Click:Connect(function()
            collapsedGroups[unitName] = not collapsedGroups[unitName]
            RefreshList()
        end)
        
        -- SELECT ALL BUTTON - batch mode atau batch heal mode
        if batchMode or batchHealMode then
            local selectAllBtn = Instance.new("TextButton")
            selectAllBtn.Size = UDim2.new(0, 70, 0, 20)
            selectAllBtn.Position = UDim2.new(1, -80, 0.5, -10)
            selectAllBtn.BackgroundColor3 = batchHealMode and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(0, 120, 180)
            selectAllBtn.BorderSizePixel = 0
            selectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            selectAllBtn.Text = "SELECT ALL"
            selectAllBtn.Font = Enum.Font.GothamBold
            selectAllBtn.TextSize = 8
            selectAllBtn.ZIndex = 2
            selectAllBtn.Parent = groupHeader
            
            local selectAllCorner = Instance.new("UICorner")
            selectAllCorner.CornerRadius = UDim.new(0, 4)
            selectAllCorner.Parent = selectAllBtn
            
            selectAllBtn.MouseButton1Click:Connect(function()
                if batchHealMode then
                    local allSelected = true
                    
                    for _, towerData in ipairs(groupTowers) do
                        if not batchHealTargets[towerData.Tower] then
                            allSelected = false
                            break
                        end
                    end
                    
                    for _, towerData in ipairs(groupTowers) do
                        batchHealTargets[towerData.Tower] = not allSelected
                    end
                    
                    UpdateBatchHealCount()
                    RefreshList()
                elseif batchMode then
                    local allSelected = true
                    
                    for _, towerData in ipairs(groupTowers) do
                        if not selectedBatch[towerData.Tower] then
                            allSelected = false
                            break
                        end
                    end
                    
                    for _, towerData in ipairs(groupTowers) do
                        selectedBatch[towerData.Tower] = not allSelected
                    end
                    
                    UpdateBatchCount()
                    RefreshList()
                end
            end)
        end
        
        if not isCollapsed then
            for _, towerData in ipairs(groupTowers) do
                local tower = towerData.Tower
                local info = towerData.Info
                local isSelected = selectedBatch[tower] == true
                local isHealerTarget = healerTargets[tower] == true
                local isBatchHealTarget = batchHealTargets[tower] == true
                local isHealed = IsHealLinked(tower)
                
                local towerButton = Instance.new("TextButton")
                towerButton.Size = UDim2.new(1, -20, 0, 45)
                towerButton.BackgroundColor3 = isSelected and Color3.fromRGB(0, 100, 60) or 
                                               isHealerTarget and Color3.fromRGB(0, 80, 50) or
                                               isBatchHealTarget and Color3.fromRGB(0, 60, 80) or
                                               Color3.fromRGB(24, 24, 34)
                towerButton.BorderSizePixel = 0
                towerButton.TextColor3 = Color3.fromRGB(200, 200, 210)
                towerButton.Text = string.format("%s%s%s%sLv.%s | %s",
                    isHealed and "💚 " or "",
                    isSelected and "✅ " or "",
                    isHealerTarget and "🎯 " or "",
                    isBatchHealTarget and "🔵 " or "",
                    info.Level,
                    info.Position)
                towerButton.Font = Enum.Font.GothamBold
                towerButton.TextSize = 9
                towerButton.Parent = TowerScroll
                
                local towerCorner = Instance.new("UICorner")
                towerCorner.CornerRadius = UDim.new(0, 4)
                towerCorner.Parent = towerButton
                
                towerButton.MouseButton1Click:Connect(function()
                    if batchHealMode then
                        batchHealTargets[tower] = not batchHealTargets[tower]
                        UpdateBatchHealCount()
                        RefreshList()
                    elseif batchMode then
                        selectedBatch[tower] = not selectedBatch[tower]
                        UpdateBatchCount()
                        RefreshList()
                    elseif healerMode and activeHealer then
                        healerTargets[tower] = not healerTargets[tower]
                        UpdateHealerStatus()
                        RefreshList()
                    else
                        selectedTower = tower
                        UpdatePanelInfo()
                    end
                end)
            end
        end
    end
    
    UpdateBatchCount()
    UpdateBatchHealCount()
    UpdateHealerStatus()
end

-- Filter options
local filterOptions = {}

local function RefreshFilterOptions()
    filterOptions = {"All"}
    
    local myTowers = FindAllMyTowers()
    local seen = {}
    
    for _, tower in ipairs(myTowers) do
        if tower.Parent then
            local info = GetTowerInfo(tower)
            
            if info and info.UnitName ~= "Unknown" then
                if not seen[info.UnitName] then
                    seen[info.UnitName] = true
                    table.insert(filterOptions, info.UnitName)
                end
            end
        end
    end
end

FilterButton.MouseButton1Click:Connect(function()
    RefreshFilterOptions()
    
    local currentIndex = 1
    
    for i, opt in ipairs(filterOptions) do
        if opt == currentFilter then
            currentIndex = i
            break
        end
    end
    
    currentIndex = currentIndex + 1
    
    if currentIndex > #filterOptions then
        currentIndex = 1
    end
    
    currentFilter = filterOptions[currentIndex]
    FilterButton.Text = "Filter: " .. currentFilter
    currentPage = 1
    RefreshList()
end)

BatchModeButton.MouseButton1Click:Connect(function()
    batchMode = not batchMode
    healerMode = false
    batchHealMode = false
    HealerPanel.Visible = false
    
    if batchMode then
        BatchModeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        BatchModeButton.Text = "🔘 BATCH MODE: ON"
        BatchActionsFrame.Visible = true
        BatchHealActionsFrame.Visible = false
        HealerModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        HealerModeButton.Text = "💚 HEALER MODE: OFF"
        BatchHealModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        BatchHealModeButton.Text = "💚🔄 BATCH HEAL: OFF"
        UpgradePanel.Visible = false
        selectedTower = nil
    else
        BatchModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        BatchModeButton.Text = "🔘 BATCH MODE: OFF"
        BatchActionsFrame.Visible = false
        selectedBatch = {}
        UpdateBatchCount()
    end
    
    RefreshList()
end)

HealerModeButton.MouseButton1Click:Connect(function()
    healerMode = not healerMode
    batchMode = false
    batchHealMode = false
    
    if healerMode then
        HealerModeButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        HealerModeButton.Text = "💚 HEALER MODE: ON"
        HealerPanel.Visible = true
        BatchModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        BatchModeButton.Text = "🔘 BATCH MODE: OFF"
        BatchActionsFrame.Visible = false
        BatchHealModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        BatchHealModeButton.Text = "💚🔄 BATCH HEAL: OFF"
        BatchHealActionsFrame.Visible = false
        UpgradePanel.Visible = false
        selectedTower = nil
        
        RefreshHealerPanel()
    else
        HealerModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        HealerModeButton.Text = "💚 HEALER MODE: OFF"
        HealerPanel.Visible = false
        healerTargets = {}
        activeHealer = nil
        UpdateHealerStatus()
    end
    
    RefreshList()
end)

BatchHealModeButton.MouseButton1Click:Connect(function()
    batchHealMode = not batchHealMode
    batchMode = false
    healerMode = false
    HealerPanel.Visible = false
    
    if batchHealMode then
        BatchHealModeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        BatchHealModeButton.Text = "💚🔄 BATCH HEAL: ON"
        BatchHealActionsFrame.Visible = true
        BatchModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        BatchModeButton.Text = "🔘 BATCH MODE: OFF"
        BatchActionsFrame.Visible = false
        HealerModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        HealerModeButton.Text = "💚 HEALER MODE: OFF"
        UpgradePanel.Visible = false
        selectedTower = nil
    else
        BatchHealModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        BatchHealModeButton.Text = "💚🔄 BATCH HEAL: OFF"
        BatchHealActionsFrame.Visible = false
        batchHealTargets = {}
        UpdateBatchHealCount()
    end
    
    RefreshList()
end)

HealerPanelClose.MouseButton1Click:Connect(function()
    healerMode = false
    HealerPanel.Visible = false
    HealerModeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    HealerModeButton.Text = "💚 HEALER MODE: OFF"
    healerTargets = {}
    activeHealer = nil
    UpdateHealerStatus()
    RefreshList()
end)

RefreshButton.MouseButton1Click:Connect(function()
    RefreshList()
    if healerMode then
        RefreshHealerPanel()
    end
end)

BatchUpgradeEButton.MouseButton1Click:Connect(function()
    UpgradeSelectedBatch("Top")
end)

BatchUpgradeZButton.MouseButton1Click:Connect(function()
    UpgradeSelectedBatch("Bottom")
end)

ApplyHealerBtn.MouseButton1Click:Connect(function()
    ApplyHealerLinks()
end)

BatchHealApplyBtn.MouseButton1Click:Connect(function()
    ApplyBatchHeal()
end)

BatchHealUnapplyBtn.MouseButton1Click:Connect(function()
    UnapplyBatchHeal()
end)

ClearBatchButton.MouseButton1Click:Connect(function()
    selectedBatch = {}
    UpdateBatchCount()
    RefreshList()
end)

ClearBatchHealButton.MouseButton1Click:Connect(function()
    batchHealTargets = {}
    UpdateBatchHealCount()
    RefreshList()
end)

UpgradeEButton.MouseButton1Click:Connect(function()
    if selectedTower then
        UpgradeTower(selectedTower, "Top")
    end
end)

UpgradeZButton.MouseButton1Click:Connect(function()
    if selectedTower then
        UpgradeTower(selectedTower, "Bottom")
    end
end)

SellTowerButton.MouseButton1Click:Connect(function()
    if selectedTower then
        SellTower(selectedTower)
    end
end)

SellAllButton.MouseButton1Click:Connect(function()
    SellAllTowers()
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimize
local isMinimized = false
local originalSize = MainFrame.Size

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    
    BatchModeButton.Visible = not isMinimized
    HealerModeButton.Visible = not isMinimized
    BatchHealModeButton.Visible = not isMinimized
    BatchActionsFrame.Visible = batchMode and not isMinimized
    BatchHealActionsFrame.Visible = batchHealMode and not isMinimized
    FilterButton.Visible = not isMinimized
    SellAllButton.Visible = not isMinimized
    TowerScroll.Visible = not isMinimized
    PageFrame.Visible = not isMinimized
    UpgradePanel.Visible = false
    HealerPanel.Visible = healerMode and not isMinimized
    
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 280, 0, 40)
        MinimizeButton.Text = "+"
    else
        MainFrame.Size = originalSize
        MinimizeButton.Text = "—"
    end
end)

-- Pagination
PrevPageButton.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        RefreshList()
    end
end)

NextPageButton.MouseButton1Click:Connect(function()
    if currentPage < totalPages then
        currentPage = currentPage + 1
        RefreshList()
    end
end)

-- Drag main frame
local dragging = false
local dragStart = nil
local startPos = nil

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

Header.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        
        UpgradePanel.Position = UDim2.new(
            0,
            startPos.X.Offset + delta.X + 300,
            0,
            startPos.Y.Offset + delta.Y
        )
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Drag healer panel
local healerDragging = false
local healerDragStart = nil
local healerStartPos = nil

HealerPanelHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        healerDragging = true
        healerDragStart = input.Position
        healerStartPos = HealerPanel.Position
    end
end)

HealerPanelHeader.InputChanged:Connect(function(input)
    if healerDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - healerDragStart
        HealerPanel.Position = UDim2.new(
            healerStartPos.X.Scale,
            healerStartPos.X.Offset + delta.X,
            healerStartPos.Y.Scale,
            healerStartPos.Y.Offset + delta.Y
        )
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        healerDragging = false
    end
end)

-- Auto refresh
task.spawn(function()
    while true do
        task.wait(2)
        if not isMinimized then
            RefreshList()
            UpdatePanelInfo()
            
            if healerMode then
                RefreshHealerPanel()
            end
        end
    end
end)

-- Initial
RefreshList()

getgenv().TowerManager = {
    Refresh = RefreshList,
    Select = function(tower)
        selectedTower = tower
        UpdatePanelInfo()
    end,
    UpgradeE = function(tower)
        UpgradeTower(tower or selectedTower, "Top")
    end,
    UpgradeZ = function(tower)
        UpgradeTower(tower or selectedTower, "Bottom")
    end,
    Sell = SellTower,
    SellAll = SellAllTowers,
    UpgradeBatch = UpgradeSelectedBatch,
    HealerBuff = ApplyHealerLinks,
    BatchHeal = ApplyBatchHeal,
    BatchHealUnapply = UnapplyBatchHeal,
    SetActiveHealer = function(healer)
        activeHealer = healer
        UpdateHealerStatus()
        RefreshHealerPanel()
    end,
    GetHealers = FindAllHealers,
    IsTracked = function(tower)
        return towerRegistry[tower] ~= nil
    end,
    IsHealed = IsHealLinked,
    SetHealSlotCapacity = function(n)
        healSlotCapacity = n
    end,
    RegisterTower = function(tower, unitName, x, z)
        if not tower or not tower.Parent then return end
        
        if not towerNameCounters[unitName] then
            towerNameCounters[unitName] = 0
        end
        
        towerNameCounters[unitName] = towerNameCounters[unitName] + 1
        
        local count = towerNameCounters[unitName]
        local displayName = unitName
        
        if count > 1 then
            displayName = string.format("%s #%d", unitName, count)
        end
        
        local cost = 0
        
        if getgenv().TowerDatabase then
            cost = getgenv().TowerDatabase.GetCost(unitName)
        end
        
        towerRegistry[tower] = {
            UnitName = unitName,
            DisplayName = displayName,
            Cost = cost,
        }
        
        return displayName
    end,
}

print("=================================")
print("🏗️ TOWER MANAGER - BATCH HEAL + UNAPPLY")
print("💚 Healer mode: pilih 1 medic, pilih target, apply link")
print("💚🔄 Batch Heal: semua medic distribusi ke semua target")
print("💔 Unapply: hapus link dari target terpilih")
print("⛔ Self-target otomatis di-block")
print("=================================")
