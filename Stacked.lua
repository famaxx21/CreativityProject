-- ==========================================
-- STACK + UPGRADE - BATCH SELECTOR
-- Pilih batch yang mau di-upgrade
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")

local CONFIG = {
    StackCount = 10,
    BaseSpacing = 0.3,
    MinSpacing = 0.05,
    DecayFactor = 0.8,
    PlaceDelay = 0.08,
    SelectDelay = 0.1,
    UpgradeDelay = 0.05,
    TowerDelay = 0.05,
    LevelDelay = 0.3,
    TargetLevel = 3,
    CoordinateTolerance = 10,
    WaitForTower = true,
    PlaceWaitTimeout = 5,
}

local TOWER_NAMES = {
    "Scout", "Sniper", "Paintballer", "Demoman", "Boomerang", "Slime Trooper",
    "Soldier", "Freezer", "Assassin", "Militant", "Shotgunner", "Hunter",
    "Pyromancer", "Ace Pilot", "Medic", "Farm", "Electroshocker", "Rocketeer",
    "Trapper", "Military Base", "Crook Boss", "Commander", "Warden", "Cowboy",
    "DJ Booth", "Tesla", "Saboteur", "Minigunner", "Ranger", "Pursuit",
    "Gatling Gun", "Turret", "Mortar", "Mercenary Base", "Brawler",
    "Necromancer", "Accelerator", "Engineer", "Hacker",
    "EvolvedOperator", "EvolvedKingpin", "EvolvedJuggernaut",
    "Golden Minigunner", "Golden Pyromancer", "Golden Crook Boss",
    "Golden Scout", "Golden Soldier", "Golden Demoman",
    "Commando", "Frost Blaster", "Archer", "Toxic Gunner", "Swarmer",
    "Firework Technician", "EvolvedEnforcer",
}

local selectedUnit = "EvolvedOperator"

-- ========== BATCH TRACKING ==========
local towerBatches = {}
local currentBatch = 0

local function GetPlayerPosition()
    if LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            return root.Position.X, root.Position.Y, root.Position.Z
        end
    end
    return 0, 0, 0
end

local function CountAllTowers()
    local towers = workspace:FindFirstChild("Towers")
    if not towers then return 0 end
    
    local count = 0
    
    for _, tower in ipairs(towers:GetChildren()) do
        if tower:IsA("Model") then
            count = count + 1
        end
    end
    
    return count
end

local function PlaceTowerAt(unitName, x, y, z)
    local placementData = {
        Rotation = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        Position = Vector3.new(x, y, z),
    }
    
    local success = pcall(function()
        return RemoteFunction:InvokeServer("Troops", "Place", placementData, unitName)
    end)
    
    return success
end

local function GetCurrentTowerSet()
    local towers = workspace:FindFirstChild("Towers")
    if not towers then return {} end
    
    local towerSet = {}
    
    for _, tower in ipairs(towers:GetChildren()) do
        if tower:IsA("Model") then
            towerSet[tower] = true
        end
    end
    
    return towerSet
end

local function FindNewTowers(oldSet)
    local towers = workspace:FindFirstChild("Towers")
    if not towers then return {} end
    
    local newTowers = {}
    
    for _, tower in ipairs(towers:GetChildren()) do
        if tower:IsA("Model") then
            if not oldSet[tower] then
                table.insert(newTowers, tower)
            end
        end
    end
    
    return newTowers
end

local function StackDifferentialTracked(unitName, x, y, z, count)
    count = count or CONFIG.StackCount
    
    print(string.format("[Stack] %d x %s", count, unitName))
    
    local oldSet = GetCurrentTowerSet()
    
    local placed = 0
    
    for i = 1, count do
        local angle = i * 2.399963
        local spacing = CONFIG.BaseSpacing * (CONFIG.DecayFactor ^ i)
        spacing = math.max(spacing, CONFIG.MinSpacing)
        local radius = spacing * math.sqrt(i)
        
        local offsetX = math.cos(angle) * radius
        local offsetZ = math.sin(angle) * radius
        
        local px = x + offsetX
        local pz = z + offsetZ
        
        local success = PlaceTowerAt(unitName, px, y, pz)
        
        if success then
            placed = placed + 1
        end
        
        task.wait(CONFIG.PlaceDelay)
    end
    
    task.wait(1)
    
    currentBatch = currentBatch + 1
    
    local newTowers = FindNewTowers(oldSet)
    
    for _, tower in ipairs(newTowers) do
        towerBatches[tower] = currentBatch
    end
    
    print(string.format("[Stack] Batch %d: %d towers", currentBatch, #newTowers))
    
    return newTowers
end

local function UpgradeTowerFast(towerInstance)
    if not towerInstance or not towerInstance.Parent then
        return false
    end
    
    local realName = towerInstance:GetAttribute("UnitName") or towerInstance.Name
    
    pcall(function()
        RemoteEvent:FireServer("Streaming", "SelectTower", realName, towerInstance.Name)
    end)
    task.wait(CONFIG.SelectDelay)
    
    local success = pcall(function()
        RemoteFunction:InvokeServer("Troops", "Upgrade", "Set", {
            Troop = towerInstance,
            Path = 1
        })
    end)
    task.wait(CONFIG.UpgradeDelay)
    
    pcall(function()
        RemoteEvent:FireServer("Streaming", "UnselectTower")
    end)
    
    return success
end

local function UpgradeTowerList(towerList, targetLevel)
    targetLevel = targetLevel or CONFIG.TargetLevel
    
    print(string.format("[Upgrade] %d towers to Level %d", #towerList, targetLevel))
    
    local totalUpgrades = 0
    
    for level = 1, targetLevel do
        local upgradedThisLevel = 0
        
        for i, tower in ipairs(towerList) do
            if tower.Parent then
                local success = UpgradeTowerFast(tower)
                
                if success then
                    upgradedThisLevel = upgradedThisLevel + 1
                end
                
                task.wait(CONFIG.TowerDelay)
            end
        end
        
        totalUpgrades = totalUpgrades + upgradedThisLevel
        
        print(string.format("  Level %d: %d/%d", level, upgradedThisLevel, #towerList))
        
        if upgradedThisLevel == 0 then
            break
        end
        
        task.wait(CONFIG.LevelDelay)
    end
    
    return totalUpgrades
end

-- ========== UPGRADE BATCH TERTENTU ==========
local function UpgradeBatch(batchNumber, targetLevel)
    targetLevel = targetLevel or CONFIG.TargetLevel
    
    local batchTowers = {}
    
    for tower, batch in pairs(towerBatches) do
        if batch == batchNumber then
            table.insert(batchTowers, tower)
        end
    end
    
    if #batchTowers == 0 then
        print(string.format("[Upgrade] Batch %d not found", batchNumber))
        return
    end
    
    print(string.format("[Upgrade] Batch %d: %d towers", batchNumber, #batchTowers))
    
    return UpgradeTowerList(batchTowers, targetLevel)
end

-- ========== LIST BATCHES ==========
local function ListBatches()
    print("=== BATCH LIST ===")
    
    local batches = {}
    
    for tower, batch in pairs(towerBatches) do
        if not batches[batch] then
            batches[batch] = 0
        end
        
        batches[batch] = batches[batch] + 1
    end
    
    for batch = 1, currentBatch do
        print(string.format("  Batch %d: %d towers", batch, batches[batch] or 0))
    end
end

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StackUpgradeUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 380)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 180, 0, 40)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
TitleLabel.Text = "STACK + UPGRADE"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

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
CloseButton.Position = UDim2.new(1, -30, 0.5, -12)
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

-- Dropdown tower
local DropdownButton = Instance.new("TextButton")
DropdownButton.Size = UDim2.new(1, -24, 0, 35)
DropdownButton.Position = UDim2.new(0, 12, 0, 50)
DropdownButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
DropdownButton.BorderSizePixel = 0
DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownButton.Text = "🔽 " .. selectedUnit
DropdownButton.Font = Enum.Font.GothamBold
DropdownButton.TextSize = 13
DropdownButton.Parent = MainFrame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 5)
DropdownCorner.Parent = DropdownButton

-- Count input
local CountInput = Instance.new("TextBox")
CountInput.Size = UDim2.new(1, -24, 0, 32)
CountInput.Position = UDim2.new(0, 12, 0, 95)
CountInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
CountInput.BorderSizePixel = 0
CountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CountInput.PlaceholderText = "Count"
CountInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
CountInput.Font = Enum.Font.GothamBold
CountInput.TextSize = 13
CountInput.Text = "10"
CountInput.Parent = MainFrame

local CountCorner = Instance.new("UICorner")
CountCorner.CornerRadius = UDim.new(0, 5)
CountCorner.Parent = CountInput

-- Level input
local LevelInput = Instance.new("TextBox")
LevelInput.Size = UDim2.new(1, -24, 0, 32)
LevelInput.Position = UDim2.new(0, 12, 0, 135)
LevelInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
LevelInput.BorderSizePixel = 0
LevelInput.TextColor3 = Color3.fromRGB(255, 255, 255)
LevelInput.PlaceholderText = "Level"
LevelInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
LevelInput.Font = Enum.Font.GothamBold
LevelInput.TextSize = 13
LevelInput.Text = "2"
LevelInput.Parent = MainFrame

local LevelCorner = Instance.new("UICorner")
LevelCorner.CornerRadius = UDim.new(0, 5)
LevelCorner.Parent = LevelInput

-- Batch input
local BatchInput = Instance.new("TextBox")
BatchInput.Size = UDim2.new(1, -24, 0, 32)
BatchInput.Position = UDim2.new(0, 12, 0, 175)
BatchInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
BatchInput.BorderSizePixel = 0
BatchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
BatchInput.PlaceholderText = "Batch number (kosong = terakhir)"
BatchInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
BatchInput.Font = Enum.Font.GothamBold
BatchInput.TextSize = 12
BatchInput.Text = ""
BatchInput.Parent = MainFrame

local BatchCorner = Instance.new("UICorner")
BatchCorner.CornerRadius = UDim.new(0, 5)
BatchCorner.Parent = BatchInput

-- Tombol STACK ONLY
local StackOnlyButton = Instance.new("TextButton")
StackOnlyButton.Size = UDim2.new(1, -24, 0, 35)
StackOnlyButton.Position = UDim2.new(0, 12, 0, 215)
StackOnlyButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
StackOnlyButton.BorderSizePixel = 0
StackOnlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StackOnlyButton.Text = "📦 STACK ONLY"
StackOnlyButton.Font = Enum.Font.GothamBold
StackOnlyButton.TextSize = 13
StackOnlyButton.Parent = MainFrame

local StackOnlyCorner = Instance.new("UICorner")
StackOnlyCorner.CornerRadius = UDim.new(0, 5)
StackOnlyCorner.Parent = StackOnlyButton

-- Tombol UPGRADE BATCH
local UpgradeBatchButton = Instance.new("TextButton")
UpgradeBatchButton.Size = UDim2.new(1, -24, 0, 35)
UpgradeBatchButton.Position = UDim2.new(0, 12, 0, 255)
UpgradeBatchButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
UpgradeBatchButton.BorderSizePixel = 0
UpgradeBatchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UpgradeBatchButton.Text = "⬆️ UPGRADE BATCH"
UpgradeBatchButton.Font = Enum.Font.GothamBold
UpgradeBatchButton.TextSize = 13
UpgradeBatchButton.Parent = MainFrame

local UpgradeBatchCorner = Instance.new("UICorner")
UpgradeBatchCorner.CornerRadius = UDim.new(0, 5)
UpgradeBatchCorner.Parent = UpgradeBatchButton

-- Tombol STACK + UPGRADE
local ComboButton = Instance.new("TextButton")
ComboButton.Size = UDim2.new(1, -24, 0, 35)
ComboButton.Position = UDim2.new(0, 12, 0, 295)
ComboButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
ComboButton.BorderSizePixel = 0
ComboButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ComboButton.Text = "🚀 STACK + UPGRADE"
ComboButton.Font = Enum.Font.GothamBold
ComboButton.TextSize = 13
ComboButton.Parent = MainFrame

local ComboCorner = Instance.new("UICorner")
ComboCorner.CornerRadius = UDim.new(0, 5)
ComboCorner.Parent = ComboButton

-- Tombol LIST BATCH
local ListBatchButton = Instance.new("TextButton")
ListBatchButton.Size = UDim2.new(1, -24, 0, 35)
ListBatchButton.Position = UDim2.new(0, 12, 0, 335)
ListBatchButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ListBatchButton.BorderSizePixel = 0
ListBatchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ListBatchButton.Text = "📋 LIST BATCHES"
ListBatchButton.Font = Enum.Font.GothamBold
ListBatchButton.TextSize = 12
ListBatchButton.Parent = MainFrame

local ListBatchCorner = Instance.new("UICorner")
ListBatchCorner.CornerRadius = UDim.new(0, 5)
ListBatchCorner.Parent = ListBatchButton

-- Side panel
local SidePanel = Instance.new("Frame")
SidePanel.Size = UDim2.new(0, 220, 0, 450)
SidePanel.Position = UDim2.new(0.5, 160, 0.5, -225)
SidePanel.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
SidePanel.BorderSizePixel = 0
SidePanel.Visible = false
SidePanel.Parent = ScreenGui

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 10)
SideCorner.Parent = SidePanel

local SearchInput = Instance.new("TextBox")
SearchInput.Size = UDim2.new(1, -20, 0, 35)
SearchInput.Position = UDim2.new(0, 10, 0, 8)
SearchInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SearchInput.BorderSizePixel = 0
SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchInput.PlaceholderText = "🔍 Search tower..."
SearchInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
SearchInput.Font = Enum.Font.Gotham
SearchInput.TextSize = 13
SearchInput.Parent = SidePanel

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 5)
SearchCorner.Parent = SearchInput

local SideScroll = Instance.new("ScrollingFrame")
SideScroll.Size = UDim2.new(1, 0, 1, -50)
SideScroll.Position = UDim2.new(0, 0, 0, 50)
SideScroll.BackgroundTransparency = 1
SideScroll.ScrollBarThickness = 5
SideScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
SideScroll.Parent = SidePanel

local SideLayout = Instance.new("UIListLayout")
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0, 3)
SideLayout.Parent = SideScroll

local SidePadding = Instance.new("UIPadding")
SidePadding.PaddingLeft = UDim.new(0, 6)
SidePadding.PaddingRight = UDim.new(0, 6)
SidePadding.PaddingTop = UDim.new(0, 6)
SidePadding.Parent = SideScroll

local towerButtons = {}

for _, towerName in ipairs(TOWER_NAMES) do
    local itemButton = Instance.new("TextButton")
    itemButton.Size = UDim2.new(1, -12, 0, 30)
    itemButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    itemButton.BorderSizePixel = 0
    itemButton.TextColor3 = Color3.fromRGB(220, 220, 230)
    itemButton.Text = towerName
    itemButton.Font = Enum.Font.GothamBold
    itemButton.TextSize = 12
    itemButton.Parent = SideScroll
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 4)
    itemCorner.Parent = itemButton
    
    towerButtons[towerName] = itemButton
    
    itemButton.MouseButton1Click:Connect(function()
        selectedUnit = towerName
        DropdownButton.Text = "🔽 " .. selectedUnit
        SidePanel.Visible = false
    end)
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = SearchInput.Text:lower()
    
    for towerName, button in pairs(towerButtons) do
        if searchText == "" or towerName:lower():find(searchText, 1, true) then
            button.Visible = true
        else
            button.Visible = false
        end
    end
end)

-- Callbacks
DropdownButton.MouseButton1Click:Connect(function()
    SidePanel.Visible = not SidePanel.Visible
    SearchInput.Text = ""
end)

StackOnlyButton.MouseButton1Click:Connect(function()
    local count = tonumber(CountInput.Text) or 10
    local x, y, z = GetPlayerPosition()
    
    task.spawn(function()
        StackDifferentialTracked(selectedUnit, x, y, z, count)
    end)
end)

UpgradeBatchButton.MouseButton1Click:Connect(function()
    local level = tonumber(LevelInput.Text) or 2
    local batchText = BatchInput.Text
    
    local batchNumber = tonumber(batchText)
    
    if not batchNumber then
        batchNumber = currentBatch
    end
    
    task.spawn(function()
        UpgradeBatch(batchNumber, level)
    end)
end)

ComboButton.MouseButton1Click:Connect(function()
    local count = tonumber(CountInput.Text) or 10
    local level = tonumber(LevelInput.Text) or 2
    local x, y, z = GetPlayerPosition()
    
    task.spawn(function()
        StackDifferentialTracked(selectedUnit, x, y, z, count)
        task.wait(1)
        UpgradeBatch(currentBatch, level)
    end)
end)

ListBatchButton.MouseButton1Click:Connect(function()
    ListBatches()
end)

-- Minimize/Close
local isMinimized = false
local originalSize = MainFrame.Size

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    
    if isMinimized then
        DropdownButton.Visible = false
        CountInput.Visible = false
        LevelInput.Visible = false
        BatchInput.Visible = false
        StackOnlyButton.Visible = false
        UpgradeBatchButton.Visible = false
        ComboButton.Visible = false
        ListBatchButton.Visible = false
        MainFrame.Size = UDim2.new(0, 280, 0, 40)
        MinimizeButton.Text = "+"
    else
        DropdownButton.Visible = true
        CountInput.Visible = true
        LevelInput.Visible = true
        BatchInput.Visible = true
        StackOnlyButton.Visible = true
        UpgradeBatchButton.Visible = true
        ComboButton.Visible = true
        ListBatchButton.Visible = true
        MainFrame.Size = originalSize
        MinimizeButton.Text = "—"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    SidePanel:Destroy()
    ScreenGui:Destroy()
end)

-- Drag
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
        
        SidePanel.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X + 300,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

getgenv().ComboStack = {
    Stack = function(unit, count)
        local x, y, z = GetPlayerPosition()
        return StackDifferentialTracked(unit or selectedUnit, x, y, z, count or CONFIG.StackCount)
    end,
    UpgradeBatch = UpgradeBatch,
    ListBatches = ListBatches,
    Combo = function(unit, count, level)
        local x, y, z = GetPlayerPosition()
        StackDifferentialTracked(unit or selectedUnit, x, y, z, count or CONFIG.StackCount)
        task.wait(1)
        UpgradeBatch(currentBatch, level or CONFIG.TargetLevel)
    end,
}

print("=================================")
print("STACK + UPGRADE - BATCH SELECTOR")
print("Batch input: kosong = terakhir")
print("Atau ketik nomor batch (1, 2, 3...)")
print("=================================")
