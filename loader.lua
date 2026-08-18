-- ==========================================
-- RAJA'S AUTO MACRO PLAYER - TOWER ID SYSTEM
-- Setting dari executor via getgenv().MacroSettings
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")

-- ========== SETTINGS (DARI EXECUTOR ATAU DEFAULT) ==========
local SETTINGS = getgenv().MacroSettings or {
    StratURL = "https://raw.githubusercontent.com/famaxx21/CreativityProject/refs/heads/main/DARK%20STACKED",
    AutoCommander = true,
    AutoDJ = true,
    CommanderBuffDuration = 10,
    CommanderCooldown = 30,
    DJCooldown = 30,
    PlaybackDelay = 0.3,
    AutoStart = true,
    AutoStartDelay = 3,
    DefaultY = 10.720,
    CoordTolerance = 5,
}

local towerList = {}

local function Log(msg)
    print("[Raja] " .. msg)
end

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

local function PlaceTower(unitName, x, y, z)
    local placementData = {
        Rotation = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        Position = Vector3.new(x, y, z),
    }
    
    local success = pcall(function()
        return RemoteFunction:InvokeServer("Troops", "Place", placementData, unitName)
    end)
    
    return success
end

local function PlaceAndTrack(towerId, unitName, x, z)
    local y = SETTINGS.DefaultY
    
    Log(string.format("Placing tower %d: %s at (%.2f, %.2f)", towerId, unitName, x, z))
    
    local success = PlaceTower(unitName, x, y, z)
    
    if success then
        towerList[towerId] = { X = x, Z = z, Unit = unitName }
        return true
    end
    
    return false
end

local function FindAllTowersAtXZ(x, z, tolerance)
    tolerance = tolerance or SETTINGS.CoordTolerance
    local towers = workspace:FindFirstChild("Towers")
    if not towers then return {} end
    
    local matched = {}
    
    for _, tower in ipairs(towers:GetChildren()) do
        if tower:IsA("Model") then
            for _, part in ipairs(tower:GetDescendants()) do
                if part:IsA("BasePart") then
                    local dx = part.Position.X - x
                    local dz = part.Position.Z - z
                    local distance = math.sqrt(dx * dx + dz * dz)
                    
                    if distance <= tolerance then
                        table.insert(matched, tower)
                        break
                    end
                end
            end
        end
    end
    
    return matched
end

local function UpgradeTower(towerInstance, pathType)
    if not towerInstance or not towerInstance.Parent then return false end
    
    local pathNumber = 1
    if pathType == "Bottom" then pathNumber = 2 end
    
    local realName = towerInstance:GetAttribute("UnitName") or towerInstance.Name
    
    pcall(function()
        RemoteEvent:FireServer("Streaming", "SelectTower", realName, towerInstance.Name)
    end)
    task.wait(0.08)
    
    local success = pcall(function()
        RemoteFunction:InvokeServer("Troops", "Upgrade", "Set", {
            Troop = towerInstance,
            Path = pathNumber
        })
    end)
    task.wait(0.05)
    
    pcall(function()
        RemoteEvent:FireServer("Streaming", "UnselectTower")
    end)
    
    return success
end

local function UpgradeTowerByID(towerId, pathType)
    local data = towerList[towerId]
    
    if not data then
        Log(string.format("Tower %d not in registry", towerId))
        return false
    end
    
    local towers = FindAllTowersAtXZ(data.X, data.Z)
    
    if #towers == 0 then
        Log(string.format("No tower at (%.2f, %.2f)", data.X, data.Z))
        return false
    end
    
    Log(string.format("Upgrading %d towers at (%.2f, %.2f)", #towers, data.X, data.Z))
    
    local upgraded = 0
    
    for _, tower in ipairs(towers) do
        if tower.Parent then
            local success = UpgradeTower(tower, pathType)
            if success then upgraded = upgraded + 1 end
            task.wait(0.1)
        end
    end
    
    return upgraded > 0
end

local function FireAbility(towerInstance, abilityName)
    if not towerInstance or not towerInstance.Parent then return false end
    
    local success = pcall(function()
        RemoteFunction:InvokeServer("Troops", "Abilities", "Activate", {
            Troop = towerInstance,
            Name = abilityName,
            Data = {}
        })
    end)
    
    return success
end

local function FindAllCommanders()
    local myTowers = FindAllMyTowers()
    local commanders = {}
    
    for _, tower in ipairs(myTowers) do
        local towerName = tower.Name:lower()
        local unitName = (tower:GetAttribute("UnitName") or ""):lower()
        
        if towerName:find("patriotic") or towerName:find("commander") or unitName:find("commander") then
            table.insert(commanders, tower)
        end
    end
    
    return commanders
end

local function FindDJ()
    local myTowers = FindAllMyTowers()
    
    for _, tower in ipairs(myTowers) do
        local towerName = tower.Name:lower()
        local unitName = (tower:GetAttribute("UnitName") or ""):lower()
        
        if towerName:find("dj") or towerName:find("booth") or unitName:find("dj") then
            return tower
        end
        
        local weapon = tower:FindFirstChild("Weapon")
        if weapon then
            for _, child in ipairs(weapon:GetChildren()) do
                if child.Name:lower():find("dj") or child.Name:lower():find("booth") or
                   child.Name:lower():find("beat") then
                    return tower
                end
            end
        end
    end
    
    return nil
end

local function IsTowerStunned(tower)
    if not tower or not tower.Parent then return false end
    
    local statusEffects = tower:FindFirstChild("StatusEffects")
    if statusEffects then
        for _, effect in ipairs(statusEffects:GetChildren()) do
            local effectName = effect.Name:lower()
            
            if effectName:find("stun") or effectName:find("freeze") or 
               effectName:find("shock") or effectName:find("paralyz") or
               effectName:find("frozen") or effectName:find("stunned") then
                return true
            end
        end
    end
    
    local stuns = tower:FindFirstChild("Stuns")
    if stuns and #stuns:GetChildren() > 0 then
        return true
    end
    
    return false
end

local function ParseMacroLog(logText)
    local steps = {}
    
    for line in logText:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        
        if line ~= "" and not line:match("^#") and not line:match("^//") then
            local parsed = false
            
            if not parsed then
                local pid, px, pz, pUnit, pCost = line:match('^place%((%d+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*"([^"]+)",%s*(%d+)%)$')
                
                if pid then
                    table.insert(steps, {
                        Action = "Place",
                        TowerID = tonumber(pid),
                        X = tonumber(px),
                        Z = tonumber(pz),
                        UnitName = pUnit,
                        Cost = tonumber(pCost),
                    })
                    parsed = true
                end
            end
            
            if not parsed then
                local uid, uCost = line:match('^upgrade%((%d+),%s*(%d+)%)$')
                
                if uid then
                    table.insert(steps, {
                        Action = "Upgrade",
                        TowerID = tonumber(uid),
                        Cost = tonumber(uCost),
                    })
                    parsed = true
                end
            end
            
            if not parsed then
                local dbid, dbCost = line:match('^DropTheBeat%((%d+),%s*(%d+)%)$')
                
                if dbid then
                    table.insert(steps, {
                        Action = "DropTheBeat",
                        TowerID = tonumber(dbid),
                        Cost = tonumber(dbCost),
                    })
                    parsed = true
                end
            end
            
            if not parsed then
                local sid, sTrack, sCost = line:match('^SetDjTrack%((%d+),%s*"([^"]+)",%s*(%d+)%)$')
                
                if sid then
                    table.insert(steps, {
                        Action = "SetDjTrack",
                        TowerID = tonumber(sid),
                        TrackName = sTrack,
                        Cost = tonumber(sCost),
                    })
                    parsed = true
                end
            end
            
            if not parsed then
                local cid, cCost = line:match('^CommanderAbility%((%d+),%s*(%d+)%)$')
                
                if cid then
                    table.insert(steps, {
                        Action = "CommanderAbility",
                        TowerID = tonumber(cid),
                        Cost = tonumber(cCost),
                    })
                    parsed = true
                end
            end
        end
    end
    
    return steps
end

local function ExecuteStep(step)
    if not step then return false end
    
    if step.Action == "Place" then
        return PlaceAndTrack(step.TowerID, step.UnitName, step.X, step.Z)
    elseif step.Action == "Upgrade" then
        return UpgradeTowerByID(step.TowerID, "Top")
    elseif step.Action == "DropTheBeat" then
        local dj = FindDJ()
        if dj then return FireAbility(dj, "Drop The Beat") end
        return false
    elseif step.Action == "CommanderAbility" then
        local commanders = FindAllCommanders()
        if #commanders > 0 then return FireAbility(commanders[1], "Call Of Arms") end
        return false
    end
    
    return false
end

local function PlayMacro()
    Log("Loading strat dari GitHub...")
    
    local success, logText = pcall(function()
        return game:HttpGet(SETTINGS.StratURL)
    end)
    
    if not success or not logText then
        Log("❌ Gagal load dari GitHub")
        return
    end
    
    local steps = ParseMacroLog(logText)
    Log(string.format("Parsed %d steps", #steps))
    
    if #steps == 0 then
        Log("❌ No steps")
        return
    end
    
    for i, step in ipairs(steps) do
        Log(string.format("[%d/%d] %s", i, #steps, step.Action))
        
        local success = ExecuteStep(step)
        
        if success then
            Log("  ✅")
        else
            Log("  ❌")
        end
        
        task.wait(SETTINGS.PlaybackDelay)
    end
    
    Log("✅ Playback complete")
end

local function StartAutoAbility()
    Log("Auto ability started")
    
    local dj = nil
    local nextCommanderFire = 0
    local nextDJFire = 0
    local commanderCooldowns = {}
    
    task.spawn(function()
        while true do
            local now = os.clock()
            
            if SETTINGS.AutoCommander then
                local commanders = FindAllCommanders()
                
                if #commanders > 0 then
                    for _, commander in ipairs(commanders) do
                        if not commanderCooldowns[commander] then
                            commanderCooldowns[commander] = 0
                        end
                    end
                    
                    if now >= nextCommanderFire then
                        local best = nil
                        
                        for _, commander in ipairs(commanders) do
                            if commander and commander.Parent then
                                local lastFire = commanderCooldowns[commander] or 0
                                
                                if now - lastFire >= SETTINGS.CommanderCooldown then
                                    if not IsTowerStunned(commander) then
                                        best = commander
                                        break
                                    end
                                end
                            end
                        end
                        
                        if best then
                            local success = FireAbility(best, "Call Of Arms")
                            
                            if success then
                                commanderCooldowns[best] = now
                                Log("✅ Commander buff")
                            end
                            
                            nextCommanderFire = now + SETTINGS.CommanderBuffDuration
                        else
                            nextCommanderFire = now + 0.3
                        end
                    end
                end
            end
            
            if SETTINGS.AutoDJ then
                if not dj or not dj.Parent then
                    dj = FindDJ()
                end
                
                if dj and dj.Parent then
                    if now >= nextDJFire then
                        if not IsTowerStunned(dj) then
                            local success = FireAbility(dj, "Drop The Beat")
                            
                            if success then
                                Log("✅ DJ Drop The Beat")
                            end
                            
                            nextDJFire = now + SETTINGS.DJCooldown
                        end
                    end
                end
            end
            
            task.wait(0.1)
        end
    end)
end

-- ========== UI LOGS ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RajaLogsUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

local LogsFrame = Instance.new("Frame")
LogsFrame.Size = UDim2.new(0, 300, 0, 150)
LogsFrame.Position = UDim2.new(0, 10, 0, 10)
LogsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
LogsFrame.BorderSizePixel = 0
LogsFrame.Parent = ScreenGui

local LogsCorner = Instance.new("UICorner")
LogsCorner.CornerRadius = UDim.new(0, 5)
LogsCorner.Parent = LogsFrame

local LogsHeader = Instance.new("Frame")
LogsHeader.Size = UDim2.new(1, 0, 0, 25)
LogsHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
LogsHeader.BorderSizePixel = 0
LogsHeader.Parent = LogsFrame

local LogsTitle = Instance.new("TextLabel")
LogsTitle.Size = UDim2.new(1, 0, 0, 25)
LogsTitle.BackgroundTransparency = 1
LogsTitle.TextColor3 = Color3.fromRGB(255, 180, 0)
LogsTitle.Text = "RAJA'S LOGS"
LogsTitle.Font = Enum.Font.Code
LogsTitle.TextSize = 11
LogsTitle.TextXAlignment = Enum.TextXAlignment.Left
LogsTitle.Position = UDim2.new(0, 8, 0, 0)
LogsTitle.Parent = LogsHeader

local LogsScroll = Instance.new("ScrollingFrame")
LogsScroll.Size = UDim2.new(1, 0, 1, -25)
LogsScroll.Position = UDim2.new(0, 0, 0, 25)
LogsScroll.BackgroundTransparency = 1
LogsScroll.ScrollBarThickness = 4
LogsScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 60)
LogsScroll.Parent = LogsFrame

local LogsLayout = Instance.new("UIListLayout")
LogsLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogsLayout.Padding = UDim.new(0, 2)
LogsLayout.Parent = LogsScroll

local LogsPadding = Instance.new("UIPadding")
LogsPadding.PaddingLeft = UDim.new(0, 8)
LogsPadding.PaddingRight = UDim.new(0, 8)
LogsPadding.PaddingTop = UDim.new(0, 4)
LogsPadding.Parent = LogsScroll

local oldPrint = print

print = function(...)
    local args = {...}
    local output = ""
    
    for i, arg in ipairs(args) do
        output = output .. tostring(arg)
        if i < #args then output = output .. " " end
    end
    
    oldPrint(...)
    
    task.spawn(function()
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 18)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(180, 180, 190)
        label.Text = output
        label.Font = Enum.Font.Code
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.LayoutOrder = os.clock()
        label.Parent = LogsScroll
        
        LogsScroll.CanvasPosition = Vector2.new(0, LogsScroll.AbsoluteCanvasSize.Y)
    end)
end

-- ========== AUTO START ==========
task.spawn(function()
    task.wait(SETTINGS.AutoStartDelay)
    
    Log("=================================")
    Log("RAJA'S AUTO MACRO STARTING")
    Log("=================================")
    
    StartAutoAbility()
    PlayMacro()
end)

getgenv().RajaMacro = {
    Play = PlayMacro,
    StartAbility = StartAutoAbility,
    Settings = SETTINGS,
    TowerList = towerList,
}

Log("Script loaded. Auto start in " .. SETTINGS.AutoStartDelay .. " seconds...")
