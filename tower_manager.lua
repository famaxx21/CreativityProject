-- ==========================================
-- TOWER MANAGER + DATABASE INTEGRATION
-- List tower + panel upgrade + cost labeling
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")

-- Load database
loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_database.lua"))()

local towerList = {}
local selectedTower = nil

-- ========== FIND MY TOWERS ==========
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

-- ========== GET TOWER INFO ==========
local function GetTowerInfo(tower)
    if not tower or not tower.Parent then return nil end
    
    local info = {
        Name = tower.Name,
        UnitName = tower:GetAttribute("UnitName") or "Unknown",
        Level = "?",
        Damage = "?",
        Range = "?",
        Cooldown = "?",
        Cost = 0,
    }
    
    local display = tower:FindFirstChild("Display")
    if display then
        local upgrade = display:FindFirstChild("Upgrade")
        if upgrade then info.Level = tostring(upgrade.Value) end
        
        local damage = display:FindFirstChild("Damage")
        if damage then info.Damage = tostring(damage.Value) end
        
        local range = display:FindFirstChild("Range")
        if range then info.Range = tostring(range.Value) end
        
        local cooldown = display:FindFirstChild("Cooldown")
        if cooldown then info.Cooldown = tostring(cooldown.Value) end
    end
    
    -- Get cost dari database
    if getgenv().TowerDatabase then
        info.Cost = getgenv().TowerDatabase.GetCost(info.UnitName)
    end
    
    return info
end

-- ========== GET DISPLAY NAME ==========
local function GetDisplayName(tower, info, index)
    if not info then return "Unknown" end
    
    local costText = ""
    
    if info.Cost and info.Cost > 0 then
        costText = string.format(" ($%d)", info.Cost)
    end
    
    if info.UnitName and info.UnitName ~= "Unknown" and info.UnitName ~= "?" then
        return string.format("[%d] %s%s", index, info.UnitName, costText)
    end
    
    return string.format("[%d] Tower%s", index, costText)
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
        
        RefreshList()
        UpdatePanelInfo()
    end)
end

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TowerManagerUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 380)
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

local TowerScroll = Instance.new("ScrollingFrame")
TowerScroll.Size = UDim2.new(1, 0, 1, -40)
TowerScroll.Position = UDim2.new(0, 0, 0, 40)
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

-- Upgrade panel
local UpgradePanel = Instance.new("Frame")
UpgradePanel.Size = UDim2.new(0, 230, 0, 220)
UpgradePanel.Position = UDim2.new(0, 285, 0, 80)
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
UpgradeTitle.Text = "UPGRADE"
UpgradeTitle.Font = Enum.Font.GothamBlack
UpgradeTitle.TextSize = 12
UpgradeTitle.TextXAlignment = Enum.TextXAlignment.Left
UpgradeTitle.Parent = UpgradeHeader

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 60)
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

local TopButton = Instance.new("TextButton")
TopButton.Size = UDim2.new(1, -20, 0, 38)
TopButton.Position = UDim2.new(0, 10, 0, 105)
TopButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
TopButton.BorderSizePixel = 0
TopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TopButton.Text = "🟩 TOP PATH"
TopButton.Font = Enum.Font.GothamBold
TopButton.TextSize = 12
TopButton.Parent = UpgradePanel

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopButton

local BottomButton = Instance.new("TextButton")
BottomButton.Size = UDim2.new(1, -20, 0, 38)
BottomButton.Position = UDim2.new(0, 10, 0, 148)
BottomButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
BottomButton.BorderSizePixel = 0
BottomButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BottomButton.Text = "🟦 BOTTOM PATH"
BottomButton.Font = Enum.Font.GothamBold
BottomButton.TextSize = 12
BottomButton.Parent = UpgradePanel

local BottomCorner = Instance.new("UICorner")
BottomCorner.CornerRadius = UDim.new(0, 8)
BottomCorner.Parent = BottomButton

-- ========== FUNCTIONS ==========
local function UpdatePanelInfo()
    if not selectedTower or not selectedTower.Parent then
        UpgradePanel.Visible = false
        return
    end
    
    local info = GetTowerInfo(selectedTower)
    
    if info then
        local costText = ""
        
        if info.Cost and info.Cost > 0 then
            costText = string.format("\n💰 Cost: $%d", info.Cost)
        end
        
        InfoLabel.Text = string.format(
            "🏷️ %s%s\n⚡ Level: %s\n⚔️ Damage: %s\n🎯 Range: %s\n⏱️ Cooldown: %s",
            info.UnitName,
            costText,
            info.Level,
            info.Damage,
            info.Range,
            info.Cooldown
        )
        
        UpgradePanel.Visible = true
    end
end

local function RefreshList()
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
                local displayName = GetDisplayName(tower, info, i)
                
                local towerButton = Instance.new("TextButton")
                towerButton.Size = UDim2.new(1, -10, 0, 40)
                towerButton.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
                towerButton.BorderSizePixel = 0
                towerButton.TextColor3 = Color3.fromRGB(220, 220, 230)
                towerButton.Text = string.format("%s\nLv.%s", displayName, info.Level)
                towerButton.Font = Enum.Font.GothamBold
                towerButton.TextSize = 10
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

TopButton.MouseButton1Click:Connect(function()
    if selectedTower then
        UpgradeTower(selectedTower, "Top")
    end
end)

BottomButton.MouseButton1Click:Connect(function()
    if selectedTower then
        UpgradeTower(selectedTower, "Bottom")
    end
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
            startPos.X.Offset + delta.X + 285,
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
    UpgradeTop = function(tower)
        UpgradeTower(tower or selectedTower, "Top")
    end,
    UpgradeBottom = function(tower)
        UpgradeTower(tower or selectedTower, "Bottom")
    end,
}

print("=================================")
print("🏗️ TOWER MANAGER LOADED")
print("Database integrated")
print("List tampil: Nama + Cost + Level")
print("=================================")
