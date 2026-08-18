-- ==========================================
-- RAJA'S LOADER - UI POLISHED
-- ==========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LoaderUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 240)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

-- ========== HEADER ==========
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25)),
})
HeaderGradient.Rotation = 90
HeaderGradient.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 0, 45)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 190, 0)
TitleLabel.Text = "👑 RAJA'S LOADER"
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 32, 0, 28)
MinimizeButton.Position = UDim2.new(1, -70, 0.5, -14)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Text = "—"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 14
MinimizeButton.Parent = Header

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeButton

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 32, 0, 28)
CloseButton.Position = UDim2.new(1, -34, 0.5, -14)
CloseButton.BackgroundColor3 = Color3.fromRGB(70, 25, 25)
CloseButton.BorderSizePixel = 0
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "×"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- ========== CONTENT ==========
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -45)
ContentFrame.Position = UDim2.new(0, 0, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Monitor Button
local MonitorButton = Instance.new("TextButton")
MonitorButton.Size = UDim2.new(1, -40, 0, 45)
MonitorButton.Position = UDim2.new(0, 20, 0, 15)
MonitorButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MonitorButton.BorderSizePixel = 0
MonitorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MonitorButton.Text = "🏗️  MONITOR TOWER"
MonitorButton.Font = Enum.Font.GothamBold
MonitorButton.TextSize = 13
MonitorButton.Parent = ContentFrame

local MonitorCorner = Instance.new("UICorner")
MonitorCorner.CornerRadius = UDim.new(0, 8)
MonitorCorner.Parent = MonitorButton

local MonitorGradient = Instance.new("UIGradient")
MonitorGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 50)),
})
MonitorGradient.Rotation = 90
MonitorGradient.Parent = MonitorButton

-- Stack Button
local StackButton = Instance.new("TextButton")
StackButton.Size = UDim2.new(1, -40, 0, 45)
StackButton.Position = UDim2.new(0, 20, 0, 70)
StackButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StackButton.BorderSizePixel = 0
StackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StackButton.Text = "📦  STACK + UPGRADE"
StackButton.Font = Enum.Font.GothamBold
StackButton.TextSize = 13
StackButton.Parent = ContentFrame

local StackCorner = Instance.new("UICorner")
StackCorner.CornerRadius = UDim.new(0, 8)
StackCorner.Parent = StackButton

local StackGradient = Instance.new("UIGradient")
StackGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 80, 160)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 50, 100)),
})
StackGradient.Rotation = 90
StackGradient.Parent = StackButton

-- Load Both Button
local LoadBothButton = Instance.new("TextButton")
LoadBothButton.Size = UDim2.new(1, -40, 0, 50)
LoadBothButton.Position = UDim2.new(0, 20, 0, 130)
LoadBothButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
LoadBothButton.BorderSizePixel = 0
LoadBothButton.TextColor3 = Color3.fromRGB(0, 0, 0)
LoadBothButton.Text = "🚀  LOAD BOTH"
LoadBothButton.Font = Enum.Font.GothamBlack
LoadBothButton.TextSize = 14
LoadBothButton.Parent = ContentFrame

local LoadBothCorner = Instance.new("UICorner")
LoadBothCorner.CornerRadius = UDim.new(0, 8)
LoadBothCorner.Parent = LoadBothButton

local LoadBothGradient = Instance.new("UIGradient")
LoadBothGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 180, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 120, 0)),
})
LoadBothGradient.Rotation = 90
LoadBothGradient.Parent = LoadBothButton

-- ========== FUNCTIONS ==========
local function LoadMonitor()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_database.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_manager.lua"))()
    print("[Loader] ✅ Monitor loaded")
end

local function LoadStack()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/tower_database.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/Stacked.lua"))()
    print("[Loader] ✅ Stack loaded")
end

-- Callbacks
MonitorButton.MouseButton1Click:Connect(function()
    task.spawn(LoadMonitor)
end)

StackButton.MouseButton1Click:Connect(function()
    task.spawn(LoadStack)
end)

LoadBothButton.MouseButton1Click:Connect(function()
    task.spawn(function()
        LoadMonitor()
        LoadStack()
        print("[Loader] ✅ Both loaded")
    end)
end)

-- ========== MINIMIZE ==========
local isMinimized = false
local originalSize = MainFrame.Size

MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    
    if isMinimized then
        ContentFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 320, 0, 45)
        MinimizeButton.Text = "+"
    else
        ContentFrame.Visible = true
        MainFrame.Size = originalSize
        MinimizeButton.Text = "—"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ========== DRAG ==========
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
print("👑 RAJA'S LOADER - POLISHED")
print("Gradient UI + Minimize + Close")
print("=================================")
