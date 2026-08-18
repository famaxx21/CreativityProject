-- ==========================================
-- TOWER MANAGER - MONITORING
-- Upload: tower_manager.lua
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")

local towerList = {}
local selectedTower = nil

-- ========== REGISTRY ==========
local towerRegistry = {}
local pendingPlacements = {}
local towerNameCounters = {}
local towerLevels = {}

-- ========== HOOK ==========
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "InvokeServer" and self.Name == "RemoteFunction" then
        -- Place hook
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
        
        -- Upgrade hook (track level)
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
        
        -- Sell hook
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
                    
                    task.spawn(function()
                        task.wait(0.2)
                        RefreshList()
                    end)
                end
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
        end
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
    
    print(string.format("[Sell] Menjual %d towers...", #myTowers))
    
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

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TowerManagerUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 380)
MainFrame.Position = UDim2.new(0, 10, 0, 50)
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
RefreshButton.Position = UDim2.new(1, -65, 0.5, -12)
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

local SellAllButton = Instance.new("TextButton")
SellAllButton.Size = UDim2.new(1, -20, 0, 30)
SellAllButton.Position = UDim2.new(0, 10, 0, 40)
SellAllButton.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
SellAllButton.BorderSizePixel = 0
SellAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SellAllButton.Text = "💰 SELL ALL TOWERS"
SellAllButton.Font = Enum.Font.GothamBold
SellAllButton.TextSize = 11
SellAllButton.Parent = MainFrame

local SellAllCorner = Instance.new("UICorner")
SellAllCorner.CornerRadius = UDim.new(0, 5)
SellAllCorner.Parent = SellAllButton

local TowerScroll = Instance.new("ScrollingFrame")
TowerScroll.Size = UDim2.new(1, 0, 1, -75)
TowerScroll.Position = UDim2.new(0, 0, 0, 75)
TowerScroll.BackgroundTransparency = 1
TowerScroll.ScrollBarThickness = 4
TowerScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 60)
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

-- ========== FUNCTIONS ==========
local function UpdatePanelInfo()
    if not selectedTower or not selectedTower.Parent then
        UpgradePanel.Visible = false
        selectedTower = nil
        return
    end
    
    local info = GetTowerInfo(selectedTower)
    
    if info then
        InfoLabel.Text = string.format(
            "🏷️ %s\n💰 Cost: $%d\n📍 %s\n⚡ Level: %s",
            info.DisplayName,
            info.Cost,
            info.Position,
            info.Level
        )
        
        UpgradePanel.Visible = true
    end
end

local function RefreshList()
    CleanupDeletedTowers()
    
    for _, child in ipairs(TowerScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local myTowers = FindAllMyTowers()
    towerList = myTowers
    
    for i, tower in ipairs(myTowers) do
        if tower.Parent then
            local info = GetTowerInfo(tower)
            
            if info then
                local costText = ""
                
                if info.Cost and info.Cost > 0 then
                    costText = string.format("$%d", info.Cost)
                end
                
                local towerButton = Instance.new("TextButton")
                towerButton.Size = UDim2.new(1, -10, 0, 50)
                towerButton.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
                towerButton.BorderSizePixel = 0
                towerButton.TextColor3 = Color3.fromRGB(220, 220, 230)
                towerButton.Text = string.format("%s\n💰 %s | 📍 %s | Lv.%s", 
                    info.DisplayName, costText, info.Position, info.Level)
                towerButton.Font = Enum.Font.GothamBold
                towerButton.TextSize = 8
                towerButton.Parent = TowerScroll
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 5)
                corner.Parent = towerButton
                
                towerButton.MouseButton1Click:Connect(function()
                    selectedTower = tower
                    UpdatePanelInfo()
                end)
            end
        end
    end
end

-- Callbacks
RefreshButton.MouseButton1Click:Connect(RefreshList)

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

-- Auto refresh
task.spawn(function()
    while true do
        task.wait(2)
        RefreshList()
        UpdatePanelInfo()
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
}

print("=================================")
print("🏗️ TOWER MANAGER LOADED")
print("Monitoring + Upgrade + Sell")
print("=================================")
