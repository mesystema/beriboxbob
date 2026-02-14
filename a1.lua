-- LocalScript: letakkan di StarterPlayerScripts atau StarterGui (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Wait for PlayerGui reliably
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- UI
local screen = Instance.new("ScreenGui")
screen.Name = "SimpleFishBotUI"
screen.ResetOnSpawn = false
screen.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 140)
frame.Position = UDim2.new(0.5, -180, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
frame.BorderSizePixel = 0
frame.Parent = screen
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 28)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Text = "Fish Bot (Local)"
title.TextColor3 = Color3.fromRGB(0, 255, 127)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.45, -8, 0, 36)
startBtn.Position = UDim2.new(0, 6, 0, 40)
startBtn.Text = "START"
startBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
startBtn.TextColor3 = Color3.fromRGB(255,255,255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,6)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.45, -8, 0, 36)
stopBtn.Position = UDim2.new(0.5, 2, 0, 40)
stopBtn.Text = "STOP"
stopBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 14
stopBtn.Parent = frame
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0,6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -12, 0, 28)
closeBtn.Position = UDim2.new(0, 6, 0, 86)
closeBtn.Text = "CLOSE"
closeBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 14
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)

-- Log area
local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(1, -12, 0, 120)
logFrame.Position = UDim2.new(0, 6, 0, 120)
logFrame.CanvasSize = UDim2.new(0,0,0,0)
logFrame.ScrollBarThickness = 6
logFrame.BackgroundTransparency = 1
logFrame.Parent = frame

local uiList = Instance.new("UIListLayout")
uiList.Parent = logFrame
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0,2)

local function AddLog(text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = logFrame
    logFrame.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
    logFrame.CanvasPosition = Vector2.new(0, math.max(0, uiList.AbsoluteContentSize.Y - logFrame.AbsoluteSize.Y))
end

-- Config & state
local BotConfig = {
    IsRunning = false,
    WaitThrow = 1.0,
    WaitGame = 2.5,
    WaitCool = 0.5,
    CastPower = 1.0
}

-- Find remote helper
local function FindRemoteSmart(partialName)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                return v
            end
        end
    end
    return nil
end

local Remotes = {
    Charge = FindRemoteSmart("ChargeFish"),
    Minigame = FindRemoteSmart("RequestFishingMinigameStart"),
    Finish = FindRemoteSmart("CatchFishCompleted")
}

local function CallRemoteSafe(remote, ...)
    if not remote then
        return false, "remote nil"
    end
    if remote:IsA("RemoteEvent") then
        local ok, err = pcall(function() remote:FireServer(...) end)
        return ok, err
    elseif remote:IsA("RemoteFunction") then
        local ok, res = pcall(function() return remote:InvokeServer(...) end)
        return ok, res
    else
        return false, "unknown remote type"
    end
end

-- Main loop (non-blocking)
local function StartBot()
    if not (Remotes.Charge and Remotes.Minigame and Remotes.Finish) then
        AddLog("❌ Remote tidak lengkap. Periksa nama remote.", Color3.fromRGB(231,76,60))
        return
    end

    if BotConfig.IsRunning then return end
    BotConfig.IsRunning = true
    AddLog("▶ Bot started", Color3.fromRGB(46,204,113))

    task.spawn(function()
        while BotConfig.IsRunning do
            -- 1. Charge / Throw
            AddLog("-> Mengirim Charge (lempar)", Color3.fromRGB(52,152,219))
            local ok, res = CallRemoteSafe(Remotes.Charge, workspace.DistributedGameTime)
            if not ok then AddLog("Charge failed: "..tostring(res), Color3.fromRGB(231,76,60)) end

            task.wait(BotConfig.WaitThrow)

            -- 2. Request minigame
            AddLog("-> Request minigame", Color3.fromRGB(241,196,15))
            local randomID = math.random(100000000, 999999999)
            local timeToSend = os.time()
            ok, res = CallRemoteSafe(Remotes.Minigame, BotConfig.CastPower, randomID, timeToSend)
            if not ok then
                AddLog("Minigame failed: "..tostring(res), Color3.fromRGB(231,76,60))
            else
                AddLog("Minigame response: "..tostring(res), Color3.fromRGB(46,204,113))
            end

            -- 3. Wait game duration
            task.wait(BotConfig.WaitGame)

            -- 4. Finish
            AddLog("-> Fire Finish", Color3.fromRGB(52,152,219))
            ok, res = CallRemoteSafe(Remotes.Finish, res)
            if not ok then AddLog("Finish failed: "..tostring(res), Color3.fromRGB(231,76,60)) else AddLog("Finish sent", Color3.fromRGB(46,204,113)) end

            task.wait(BotConfig.WaitCool)
        end
        AddLog("⏹ Bot stopped", Color3.fromRGB(241,196,15))
    end)
end

local function StopBot()
    BotConfig.IsRunning = false
end

-- UI events
startBtn.MouseButton1Click:Connect(function()
    StartBot()
end)
stopBtn.MouseButton1Click:Connect(function()
    StopBot()
end)
closeBtn.MouseButton1Click:Connect(function()
    StopBot()
    screen:Destroy()
end)

-- initial logs
AddLog("UI siap. Pastikan ini LocalScript di StarterPlayerScripts.", Color3.fromRGB(180,180,180))
if not (Remotes.Charge and Remotes.Minigame and Remotes.Finish) then
    AddLog("Beberapa remote tidak ditemukan otomatis. Periksa nama remote di ReplicatedStorage/Character.", Color3.fromRGB(231,76,60))
else
    AddLog("Semua remote ditemukan.", Color3.fromRGB(46,204,113))
end
