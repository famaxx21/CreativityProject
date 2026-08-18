-- ==========================================
-- STACKED - REVISED FINAL
-- Auto register ke Tower Manager
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

-- ========== PLACE + REGISTER ==========
local function PlaceTowerAt(unitName, x, y, z)
    local placementData = {
        Rotation = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        Position = Vector3.new(x, y, z),
    }
    
    local success = pcall(function()
        return RemoteFunction:InvokeServer("Troops", "Place", placementData, unitName)
    end)
    
    if success then
        -- Tunggu tower muncul
        task.wait(0.3)
        
        -- Cari tower baru dan register
        if getgenv().TowerManager and getgenv().TowerManager.RegisterTower then
            local towers = workspace:FindFirstChild("Towers")
            
            if towers then
                for _, tower in ipairs(towers:GetChildren()) do
                    if tower:IsA("Model") then
                        local owner = tower:FindFirstChild("Owner")
                        local isMine = false
                        
                        if owner and owner.Value == LocalPlayer.UserId then
                            isMine = true
                        elseif not owner then
                            isMine = true
                        end
                        
                        if isMine then
                            local alreadyTracked = false
                            
                            if getgenv().TowerManager.IsTracked then
                                alreadyTracked = getgenv().TowerManager.IsTracked(tower)
                            end
                            
                            if not alreadyTracked then
                                local displayName = getgenv().TowerManager.RegisterTower(tower, unitName, x, z)
                                
                                if displayName then
                                    print(string.format("[Register] %s", displayName))
                                end
                                
                                break
                            end
                        end
                    end
                end
            end
        else
            print("[Register] ⚠️ TowerManager belum ke-load")
        end
    end
    
    return success
end

-- ========== STACK DIFFERENTIAL ==========
local function StackDifferential(unitName, x, y, z, count)
    count = count or CONFIG.StackCount
    
    print(string.format("[Stack] %d x %s", count, unitName))
    
    currentBatch = currentBatch + 1
    local batchNumber = currentBatch
    
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
    
    print(string.format("[Stack] Batch %d: %d/%d placed", batchNumber, placed, count))
    
    return placed
end

-- ========== UPGRADE ==========
local function UpgradeTowerFast(towerInstance)
    if not towerInstance or not towerInstance.Parent then return false end
    
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

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StackedUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 180)
MainFrame.Position = UDim2.new(0, 10, 0, 440)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
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
TitleLabel.Size = UDim2.new(0, 160, 0, 40)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
TitleLabel.Text = "📦 STACKED"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 13
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

-- Dropdown
local DropdownButton = Instance.new("TextButton")
DropdownButton.Size = UDim2.new(1, -24, 0, 32)
DropdownButton.Position = UDim2.new(0, 12, 0, 50)
DropdownButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
DropdownButton.BorderSizePixel = 0
DropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DropdownButton.Text = "🔽 " .. selectedUnit
DropdownButton.Font = Enum.Font.GothamBold
DropdownButton.TextSize = 12
DropdownButton.Parent = MainFrame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 5)
DropdownCorner.Parent = DropdownButton

-- Count input
local CountInput = Instance.new("TextBox")
CountInput.Size = UDim2.new(1, -24, 0, 28)
CountInput.Position = UDim2.new(0, 12, 0, 90)
CountInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
CountInput.BorderSizePixel = 0
CountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CountInput.PlaceholderText = "Count"
CountInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
CountInput.Font = Enum.Font.GothamBold
CountInput.TextSize = 12
CountInput.Text = "10"
CountInput.Parent = MainFrame

local CountCorner = Instance.new("UICorner")
CountCorner.CornerRadius = UDim.new(0, 5)
CountCorner.Parent = CountInput

-- Stack button
local StackButton = Instance.new("TextButton")
StackButton.Size = UDim2.new(1, -24, 0, 38)
StackButton.Position = UDim2.new(0, 12, 0, 128)
StackButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
StackButton.BorderSizePixel = 0
StackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StackButton.Text = "📦 STACK"
StackButton.Font = Enum.Font.GothamBold
StackButton.TextSize = 13
StackButton.Parent = MainFrame

local StackCorner = Instance.new("UICorner")
StackCorner.CornerRadius = UDim.new(0, 8)
StackCorner.Parent = StackButton

-- Side panel
local SidePanel = Instance.new("Frame")
SidePanel.Size = UDim2.new(0, 220, 0, 400)
SidePanel.Position = UDim2.new(0, 310, 0, 370)
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

StackButton.MouseButton1Click:Connect(function()
    local count = tonumber(CountInput.Text) or 10
    local x, y, z = GetPlayerPosition()
    
    task.spawn(function()
        StackDifferential(selectedUnit, x, y, z, count)
    end)
end)

-- Minimize
MinimizeButton.MouseButton1Click:Connect(function()
    local isMinimized = not DropdownButton.Visible
    
    DropdownButton.Visible = not isMinimized
    CountInput.Visible = not isMinimized
    StackButton.Visible = not isMinimized
    
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 280, 0, 40)
        MinimizeButton.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 280, 0, 180)
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
            0,
            startPos.X.Offset + delta.X + 310,
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

getgenv().Stacked = {
    Stack = StackDifferential,
    Place = PlaceTowerAt,
    Upgrade = UpgradeTowerList,
}

print("=================================")
print("📦 STACKED - REVISED")
print("Auto register ke Tower Manager")
print("=================================")
