-- ==========================================
-- RAJA'S LOADER - UI SELECTOR
-- Checklist pilih modul, klik LOAD
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local LOADED_MODULES = {}

-- ========== LOAD FUNCTIONS ==========
local function LoadDatabase()
    if LOADED_MODULES.Database then return end
    
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_database.lua"))()
    
    LOADED_MODULES.Database = true
    print("[Loader] ✅ Database loaded")
end

local function LoadMonitor()
    if LOADED_MODULES.Monitor then return end
    
    LoadDatabase()
    
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_manager.lua"))()
    
    LOADED_MODULES.Monitor = true
    print("[Loader] ✅ Monitor loaded")
end

local function LoadStack()
    if LOADED_MODULES.Stack then return end
    
    LoadDatabase()
    
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/Stacked.lua"))()
    
    LOADED_MODULES.Stack = true
    print("[Loader] ✅ Stack loaded")
end

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RajaLoaderUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 0, 30)
TitleLabel.Position = UDim2.new(0, 15, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
TitleLabel.Text = "👑 RAJA'S LOADER"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Size = UDim2.new(0, 150, 0, 20)
SubtitleLabel.Position = UDim2.new(0, 15, 0, 30)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
SubtitleLabel.Text = "Pilih modul..."
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.TextSize = 10
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 25)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
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

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 30, 0, 25)
MinimizeButton.Position = UDim2.new(1, -70, 0, 5)
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

-- Toggle states
local toggleStates = {
    Database = true,
    Monitor = true,
    Stack = false,
}

-- ========== TOGGLE CREATOR ==========
local function CreateToggle(name, description, y, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -30, 0, 55)
    ToggleFrame.Position = UDim2.new(0, 15, 0, y)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = MainFrame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 8)
    ToggleCorner.Parent = ToggleFrame
    
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -60, 0, 25)
    NameLabel.Position = UDim2.new(0, 10, 0, 5)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.Text = name
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 12
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Parent = ToggleFrame
    
    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(1, -60, 0, 20)
    DescLabel.Position = UDim2.new(0, 10, 0, 28)
    DescLabel.BackgroundTransparency = 1
    DescLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
    DescLabel.Text = description
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextSize = 9
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = ToggleFrame
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 40, 0, 20)
    ToggleButton.Position = UDim2.new(1, -50, 0.5, -10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Text = "OFF"
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 9
    ToggleButton.Parent = ToggleFrame
    
    local ToggleButtonCorner = Instance.new("UICorner")
    ToggleButtonCorner.CornerRadius = UDim.new(0, 10)
    ToggleButtonCorner.Parent = ToggleButton
    
    local isOn = false
    
    local function UpdateToggle()
        if isOn then
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
            ToggleButton.Text = "ON"
        else
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            ToggleButton.Text = "OFF"
        end
    end
    
    ToggleButton.MouseButton1Click:Connect(function()
        isOn = not isOn
        UpdateToggle()
        
        if callback then
            callback(isOn)
        end
    end)
    
    return ToggleFrame
end

-- Database toggle
CreateToggle("📊 DATABASE", "Tower cost database", 60, function(on)
    toggleStates.Database = on
end)

-- Monitor toggle
CreateToggle("🏗️ MONITOR TOWER", "Monitoring + upgrade + sell", 120, function(on)
    toggleStates.Monitor = on
end)

-- Stack toggle
CreateToggle("📦 STACK + UPGRADE", "Stack differential + batch", 180, function(on)
    toggleStates.Stack = on
end)

-- LOAD BUTTON
local LoadButton = Instance.new("TextButton")
LoadButton.Size = UDim2.new(1, -30, 0, 50)
LoadButton.Position = UDim2.new(0, 15, 0, 250)
LoadButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
LoadButton.BorderSizePixel = 0
LoadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadButton.Text = "🚀 LOAD SELECTED"
LoadButton.Font = Enum.Font.GothamBlack
LoadButton.TextSize = 14
LoadButton.Parent = MainFrame

local LoadCorner = Instance.new("UICorner")
LoadCorner.CornerRadius = UDim.new(0, 8)
LoadCorner.Parent = LoadButton

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -30, 0, 30)
StatusLabel.Position = UDim2.new(0, 15, 0, 308)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
StatusLabel.Text = "Ready"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = MainFrame

-- ========== LOAD CALLBACK ==========
LoadButton.MouseButton1Click:Connect(function()
    StatusLabel.Text = "Loading..."
    
    task.spawn(function()
        if toggleStates.Database then
            LoadDatabase()
        end
        
        if toggleStates.Monitor then
            LoadMonitor()
        end
        
        if toggleStates.Stack then
            LoadStack()
        end
        
        StatusLabel.Text = "✅ Selesai!"
        
        task.wait(2)
        StatusLabel.Text = "Ready"
    end)
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimize
MinimizeButton.MouseButton1Click:Connect(function()
    local isMinimized = not LoadButton.Visible
    
    LoadButton.Visible = not isMinimized
    StatusLabel.Visible = not isMinimized
    
    -- Hide toggles
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child:IsA("Frame") and child ~= Header then
            child.Visible = not isMinimized
        end
    end
    
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 300, 0, 50)
        MinimizeButton.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 300, 0, 350)
        MinimizeButton.Text = "—"
    end
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
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

print("=================================")
print("👑 RAJA'S LOADER UI")
print("Pilih modul → klik LOAD SELECTED")
print("=================================")
