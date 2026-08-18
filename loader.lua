-- ==========================================
-- RAJA'S LOADER - MONITOR + STACK
-- ==========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LoaderUI"
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 0, 30)
Title.Position = UDim2.new(0, 15, 0, 10)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 180, 0)
Title.Text = "RAJA'S LOADER"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Button Monitor
local MonitorButton = Instance.new("TextButton")
MonitorButton.Size = UDim2.new(1, -30, 0, 45)
MonitorButton.Position = UDim2.new(0, 15, 0, 50)
MonitorButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
MonitorButton.BorderSizePixel = 0
MonitorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MonitorButton.Text = "🏗️ LOAD MONITOR"
MonitorButton.Font = Enum.Font.SourceSansBold
MonitorButton.TextSize = 14
MonitorButton.Parent = MainFrame

local MonitorCorner = Instance.new("UICorner")
MonitorCorner.CornerRadius = UDim.new(0, 8)
MonitorCorner.Parent = MonitorButton

-- Button Stack
local StackButton = Instance.new("TextButton")
StackButton.Size = UDim2.new(1, -30, 0, 45)
StackButton.Position = UDim2.new(0, 15, 0, 105)
StackButton.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
StackButton.BorderSizePixel = 0
StackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StackButton.Text = "📦 LOAD STACK"
StackButton.Font = Enum.Font.SourceSansBold
StackButton.TextSize = 14
StackButton.Parent = MainFrame

local StackCorner = Instance.new("UICorner")
StackCorner.CornerRadius = UDim.new(0, 8)
StackCorner.Parent = StackButton

-- Button Load All
local LoadAllButton = Instance.new("TextButton")
LoadAllButton.Size = UDim2.new(1, -30, 0, 45)
LoadAllButton.Position = UDim2.new(0, 15, 0, 155)
LoadAllButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
LoadAllButton.BorderSizePixel = 0
LoadAllButton.TextColor3 = Color3.fromRGB(0, 0, 0)
LoadAllButton.Text = "🚀 LOAD BOTH"
LoadAllButton.Font = Enum.Font.SourceSansBold
LoadAllButton.TextSize = 14
LoadAllButton.Parent = MainFrame

local LoadAllCorner = Instance.new("UICorner")
LoadAllCorner.CornerRadius = UDim.new(0, 8)
LoadAllCorner.Parent = LoadAllButton

-- Callbacks
local function LoadMonitor()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_database.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_manager.lua"))()
    print("[Loader] Monitor loaded")
end

local function LoadStack()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_database.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/Stacked.lua"))()
    print("[Loader] Stack loaded")
end

MonitorButton.MouseButton1Click:Connect(function()
    task.spawn(LoadMonitor)
end)

StackButton.MouseButton1Click:Connect(function()
    task.spawn(LoadStack)
end)

LoadAllButton.MouseButton1Click:Connect(function()
    task.spawn(function()
        LoadMonitor()
        LoadStack()
        print("[Loader] Both loaded")
    end)
end)

-- Drag
local dragging = false
local dragStart = nil
local startPos = nil

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

Title.InputChanged:Connect(function(input)
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
print("LOADER UI READY")
print("MONITOR | STACK | LOAD BOTH")
print("=================================")
