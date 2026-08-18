-- ==========================================
-- RAJA'S LOADER - UI SELECTOR
-- Pilih modul yang mau di-load
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

local function LoadAll()
    LoadDatabase()
    LoadMonitor()
    LoadStack()
    
    print("[Loader] ✅ All modules loaded")
end

-- ========== UI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RajaLoaderUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 300)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
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

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 150, 0, 20)
StatusLabel.Position = UDim2.new(0, 15, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
StatusLabel.Text = "Pilih modul..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Header

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

-- Content
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -50)
ContentFrame.Position = UDim2.new(0, 0, 0, 50)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Database button
local DatabaseButton = Instance.new("TextButton")
DatabaseButton.Size = UDim2.new(1, -30, 0, 40)
DatabaseButton.Position = UDim2.new(0, 15, 0, 10)
DatabaseButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
DatabaseButton.BorderSizePixel = 0
DatabaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DatabaseButton.Text = "📊 DATABASE"
DatabaseButton.Font = Enum.Font.GothamBold
DatabaseButton.TextSize = 13
DatabaseButton.Parent = ContentFrame

local DatabaseCorner = Instance.new("UICorner")
DatabaseCorner.CornerRadius = UDim.new(0, 8)
DatabaseCorner.Parent = DatabaseButton

-- Monitor button
local MonitorButton = Instance.new("TextButton")
MonitorButton.Size = UDim2.new(1, -30, 0, 40)
MonitorButton.Position = UDim2.new(0, 15, 0, 60)
MonitorButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
MonitorButton.BorderSizePixel = 0
MonitorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MonitorButton.Text = "🏗️ MONITOR TOWER"
MonitorButton.Font = Enum.Font.GothamBold
MonitorButton.TextSize = 13
MonitorButton.Parent = ContentFrame

local MonitorCorner = Instance.new("UICorner")
MonitorCorner.CornerRadius = UDim.new(0, 8)
MonitorCorner.Parent = MonitorButton

-- Stack button
local StackButton = Instance.new("TextButton")
StackButton.Size = UDim2.new(1, -30, 0, 40)
StackButton.Position = UDim2.new(0, 15, 0, 110)
StackButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
StackButton.BorderSizePixel = 0
StackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StackButton.Text = "📦 STACK + UPGRADE"
StackButton.Font = Enum.Font.GothamBold
StackButton.TextSize = 13
StackButton.Parent = ContentFrame

local StackCorner = Instance.new("UICorner")
StackCorner.CornerRadius = UDim.new(0, 8)
StackCorner.Parent = StackButton

-- Load All button
local LoadAllButton = Instance.new("TextButton")
LoadAllButton.Size = UDim2.new(1, -30, 0, 45)
LoadAllButton.Position = UDim2.new(0, 15, 0, 160)
LoadAllButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
LoadAllButton.BorderSizePixel = 0
LoadAllButton.TextColor3 = Color3.fromRGB(0, 0, 0)
LoadAllButton.Text = "🚀 LOAD ALL"
LoadAllButton.Font = Enum.Font.GothamBlack
LoadAllButton.TextSize = 14
LoadAllButton.Parent = ContentFrame

local LoadAllCorner = Instance.new("UICorner")
LoadAllCorner.CornerRadius = UDim.new(0, 8)
LoadAllCorner.Parent = LoadAllButton

-- Status list
local StatusListLabel = Instance.new("TextLabel")
StatusListLabel.Size = UDim2.new(1, -30, 0, 40)
StatusListLabel.Position = UDim2.new(0, 15, 0, 215)
StatusListLabel.BackgroundTransparency = 1
StatusListLabel.TextColor3 = Color3.fromRGB(100, 100, 110)
StatusListLabel.Text = "Belum ada modul di-load"
StatusListLabel.Font = Enum.Font.Gotham
StatusListLabel.TextSize = 10
StatusListLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusListLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusListLabel.TextWrapped = true
StatusListLabel.Parent = ContentFrame

-- ========== UPDATE STATUS ==========
local function UpdateStatus()
    local statusText = ""
    
    if LOADED_MODULES.Database then
        statusText = statusText .. "✅ Database\n"
    end
    
    if LOADED_MODULES.Monitor then
        statusText = statusText .. "✅ Monitor\n"
    end
    
    if LOADED_MODULES.Stack then
        statusText = statusText .. "✅ Stack\n"
    end
    
    if statusText == "" then
        statusText = "Belum ada modul di-load"
    end
    
    StatusListLabel.Text = statusText
end

-- Callbacks
DatabaseButton.MouseButton1Click:Connect(function()
    StatusLabel.Text = "Loading database..."
    task.spawn(function()
        LoadDatabase()
        UpdateStatus()
        StatusLabel.Text = "Database loaded"
    end)
end)

MonitorButton.MouseButton1Click:Connect(function()
    StatusLabel.Text = "Loading monitor..."
    task.spawn(function()
        LoadMonitor()
        UpdateStatus()
        StatusLabel.Text = "Monitor loaded"
    end)
end)

StackButton.MouseButton1Click:Connect(function()
    StatusLabel.Text = "Loading stack..."
    task.spawn(function()
        LoadStack()
        UpdateStatus()
        StatusLabel.Text = "Stack loaded"
    end)
end)

LoadAllButton.MouseButton1Click:Connect(function()
    StatusLabel.Text = "Loading semua..."
    task.spawn(function()
        LoadAll()
        UpdateStatus()
        StatusLabel.Text = "Semua loaded"
    end)
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimize
MinimizeButton.MouseButton1Click:Connect(function()
    local isMinimized = not ContentFrame.Visible
    
    ContentFrame.Visible = not isMinimized
    
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 300, 0, 50)
        MinimizeButton.Text = "+"
    else
        MainFrame.Size = UDim2.new(0, 300, 0, 300)
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

-- ========== AUTO LOAD ALL ==========
task.spawn(function()
    task.wait(1)
    LoadAll()
    UpdateStatus()
    StatusLabel.Text = "Semua loaded otomatis"
end)

print("=================================")
print("👑 RAJA'S LOADER UI")
print("Pilih modul atau LOAD ALL")
print("=================================")
