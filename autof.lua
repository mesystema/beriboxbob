--[[ 
    AUTOF.LUA - Mobile Friendly Auto Fish
    Based on v9.lua logic
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIGURATION ]] --
local BotConfig = {
    IsRunning = false,
    ChargeValue = 1,
    MinigameValues = "1,1,1",
    WaitAfterCancel = 0.1,
    WaitAfterCharge = 0.2,
    WaitAfterMinigame = 0.2
}

local Remotes = {
    Cancel = nil,
    Charge = nil,
    Minigame = nil,
    Finish = nil
}

-- [[ UI SETUP ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFishUI_Mobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10000
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 380) -- Mobile friendly width
MainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
-- MainFrame.Draggable = true -- Removed in favor of custom dragging
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Title
local Title = Instance.new("TextLabel")
Title.Text = "🎣 AutoFish Mobile"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Size = UDim2.new(1, -50, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 5)
MinBtn.Parent = MainFrame
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Settings Container
local SettingsFrame = Instance.new("ScrollingFrame")
SettingsFrame.Size = UDim2.new(1, -20, 0, 160)
SettingsFrame.Position = UDim2.new(0, 10, 0, 45)
SettingsFrame.BackgroundTransparency = 1
SettingsFrame.ScrollBarThickness = 4
SettingsFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Parent = SettingsFrame
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 5)

-- Helper to create inputs
local function CreateInput(label, key)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -5, 0, 30)
    Frame.BackgroundTransparency = 1
    Frame.Parent = SettingsFrame
    
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = label
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextSize = 12
    Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    Lbl.Size = UDim2.new(0.5, 0, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Frame
    
    local Box = Instance.new("TextBox")
    Box.Text = tostring(BotConfig[key])
    Box.Font = Enum.Font.Code
    Box.TextSize = 12
    Box.TextColor3 = Color3.fromRGB(255, 255, 0)
    Box.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Box.Size = UDim2.new(0.5, 0, 1, 0)
    Box.Position = UDim2.new(0.5, 0, 0, 0)
    Box.Parent = Frame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
    
    Box.FocusLost:Connect(function()
        if type(BotConfig[key]) == "number" then
            BotConfig[key] = tonumber(Box.Text) or BotConfig[key]
        else
            BotConfig[key] = Box.Text
        end
        Box.Text = tostring(BotConfig[key])
    end)
end

CreateInput("Charge Value", "ChargeValue")
CreateInput("Minigame Values", "MinigameValues")
CreateInput("Wait Cancel", "WaitAfterCancel")
CreateInput("Wait Charge", "WaitAfterCharge")
CreateInput("Wait Minigame", "WaitAfterMinigame")

-- Log Container
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Size = UDim2.new(1, -20, 1, -260) 
LogFrame.Position = UDim2.new(0, 10, 0, 215)
LogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
LogFrame.ScrollBarThickness = 4
LogFrame.Parent = MainFrame
Instance.new("UICorner", LogFrame).CornerRadius = UDim.new(0, 6)

local LogList = Instance.new("UIListLayout")
LogList.Parent = LogFrame
LogList.SortOrder = Enum.SortOrder.LayoutOrder

local function AddLog(msg, color)
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = msg
    Lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    Lbl.Font = Enum.Font.Code
    Lbl.TextSize = 11
    Lbl.Size = UDim2.new(1, 0, 0, 0)
    Lbl.AutomaticSize = Enum.AutomaticSize.Y
    Lbl.BackgroundTransparency = 1
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.TextWrapped = true
    Lbl.Parent = LogFrame
    
    if #LogFrame:GetChildren() > 50 then
        local c = LogFrame:GetChildren()
        if c[1] and c[1] ~= LogList then c[1]:Destroy() end
    end
    LogFrame.CanvasPosition = Vector2.new(0, 9999)
end

-- Buttons
local BtnFrame = Instance.new("Frame")
BtnFrame.Size = UDim2.new(1, -20, 0, 40)
BtnFrame.Position = UDim2.new(0, 10, 1, -50)
BtnFrame.BackgroundTransparency = 1
BtnFrame.Parent = MainFrame

local StartBtn = Instance.new("TextButton")
StartBtn.Text = "START"
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 14
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
StartBtn.Size = UDim2.new(0.6, -5, 1, 0)
StartBtn.Parent = BtnFrame
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Text = "CLEAR"
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 12
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ClearBtn.Size = UDim2.new(0.4, -5, 1, 0)
ClearBtn.Position = UDim2.new(0.6, 5, 0, 0)
ClearBtn.Parent = BtnFrame
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

-- [[ LOGIC ]] --

local function ParseMinigameValues(str)
    local args = {}
    for val in string.gmatch(str, "([^,]+)") do
        val = val:match("^%s*(.-)%s*$") -- Trim whitespace
        local n = tonumber(val)
        if n then table.insert(args, n) else table.insert(args, val) end
    end
    return args
end

local function FindRemoteSmart(partialName)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
    end
    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
        end
    end
    return nil
end

local function SetupRemotes()
    Remotes.Cancel = FindRemoteSmart("Cancel")
    Remotes.Charge = FindRemoteSmart("ChargeFish")
    Remotes.Minigame = FindRemoteSmart("Minigame")
    Remotes.Finish = FindRemoteSmart("FishingComplet")
    
    if Remotes.Charge and Remotes.Minigame and Remotes.Finish then
        AddLog("✅ Remotes Found!", Color3.fromRGB(46, 204, 113))
        return true
    else
        AddLog("❌ Remotes Missing!", Color3.fromRGB(231, 76, 60))
        return false
    end
end

local function StartBot()
    task.spawn(function()
        if not SetupRemotes() then 
            BotConfig.IsRunning = false
            StartBtn.Text = "START"
            StartBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            return 
        end
        
        AddLog("Bot Started...", Color3.fromRGB(46, 204, 113))
        
        while BotConfig.IsRunning do
            -- 1. Cancel
            if Remotes.Cancel then
                pcall(function() Remotes.Cancel:FireServer() end)
            end
            task.wait(BotConfig.WaitAfterCancel)
            
            if not BotConfig.IsRunning then break end

            -- 2. Charge
            local chargeOk = false
            if Remotes.Charge then
                chargeOk = pcall(function() 
                    -- Menggunakan BotConfig.ChargeValue sesuai request
                    Remotes.Charge:InvokeServer(BotConfig.ChargeValue) 
                end)
            end
            
            if chargeOk then
                AddLog("Charge Sent ("..BotConfig.ChargeValue..")", Color3.fromRGB(200, 200, 200))
            else
                AddLog("Charge Failed", Color3.fromRGB(231, 76, 60))
            end
            task.wait(BotConfig.WaitAfterCharge)
            
            if not BotConfig.IsRunning then break end

            -- 3. Minigame
            local minigameArgs = ParseMinigameValues(BotConfig.MinigameValues)
            table.insert(minigameArgs, tick()) -- Add timestamp
            
            local minigameOk, response
            if Remotes.Minigame then
                minigameOk, response = pcall(function()
                    return Remotes.Minigame:InvokeServer(unpack(minigameArgs))
                end)
            end
            
            if minigameOk then
                AddLog("Minigame OK", Color3.fromRGB(46, 204, 113))
            else
                AddLog("Minigame Fail", Color3.fromRGB(231, 76, 60))
            end
            task.wait(BotConfig.WaitAfterMinigame)
            
            if not BotConfig.IsRunning then break end

            -- 4. Finish
            if minigameOk and response and Remotes.Finish then
                pcall(function()
                    Remotes.Finish:FireServer(response)
                end)
                AddLog("Finish Sent", Color3.fromRGB(46, 204, 113))
            end
            
            task.wait(0.1)
        end
        
        BotConfig.IsRunning = false
        StartBtn.Text = "START"
        StartBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        AddLog("Bot Stopped", Color3.fromRGB(241, 196, 15))
    end)
end

-- [[ EVENTS ]] --
StartBtn.MouseButton1Click:Connect(function()
    BotConfig.IsRunning = not BotConfig.IsRunning
    if BotConfig.IsRunning then
        StartBtn.Text = "STOP"
        StartBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        StartBot()
    else
        StartBtn.Text = "START"
        StartBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(LogFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 40), "Out", "Quad", 0.3, true)
        SettingsFrame.Visible = false
        LogFrame.Visible = false
        BtnFrame.Visible = false
        MinBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 380), "Out", "Quad", 0.3, true)
        SettingsFrame.Visible = true
        LogFrame.Visible = true
        BtnFrame.Visible = true
        MinBtn.Text = "-"
    end
end)

-- [[ DRAGGING LOGIC ]] --
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)
