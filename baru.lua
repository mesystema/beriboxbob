-- Simple Fishing Bot UI + Safe Non-blocking Loop
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- UI (ScreenGui)
local screen = Instance.new("ScreenGui")
screen.Name = "SimpleFishBotUI"
screen.ResetOnSpawn = false
screen.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 120)
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Parent = screen

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,24)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "Fish Bot (Safe)"
title.TextColor3 = Color3.fromRGB(0,255,127)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0.45, -6, 0, 36)
startBtn.Position = UDim2.new(0,6,0,36)
startBtn.Text = "START"
startBtn.BackgroundColor3 = Color3.fromRGB(46,204,113)

local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(0.45, -6, 0, 36)
stopBtn.Position = UDim2.new(0.5, 0, 0, 36)
stopBtn.Text = "STOP"
stopBtn.BackgroundColor3 = Color3.fromRGB(231,76,60)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(1, -12, 0, 28)
closeBtn.Position = UDim2.new(0,6,0,80)
closeBtn.Text = "CLOSE"
closeBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)

-- Config
local BotConfig = {
    IsRunning = false,
    WaitThrow = 1.0,
    WaitGame = 2.5,
    WaitCool = 0.5,
    CastPower = 1.0
}

-- Helper log (simple)
local function Log(msg)
    print("[FishBot] "..msg)
end

-- Find remote helper (searches ReplicatedStorage and Character)
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

-- Resolve remotes
local Remotes = {}
Remotes.Charge = FindRemoteSmart("ChargeFish")
Remotes.Minigame = FindRemoteSmart("RequestFishingMinigameStart")
Remotes.Finish = FindRemoteSmart("CatchFishCompleted")

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

-- Main bot loop (non-blocking)
local function StartBot()
    if not (Remotes.Charge and Remotes.Minigame and Remotes.Finish) then
        Log("One or more remotes not found. Aborting.")
        return
    end

    BotConfig.IsRunning = true
    task.spawn(function()
        Log("Bot started.")
        while BotConfig.IsRunning do
            -- 1) Charge / Lempar
            Log("-> Charging / Throwing")
            local ok, res = CallRemoteSafe(Remotes.Charge, workspace.DistributedGameTime)
            if not ok then
                Log("Charge call failed: "..tostring(res))
            end

            -- pastikan tidak memblokir UI; tunggu sesuai config
            task.wait(BotConfig.WaitThrow)

            -- 2) Request minigame
            Log("-> Requesting minigame")
            local randomID = math.random(100000000, 999999999)
            local timeToSend = os.time()
            ok, res = CallRemoteSafe(Remotes.Minigame, BotConfig.CastPower, randomID, timeToSend)
            if not ok then
                Log("Minigame call failed: "..tostring(res))
            else
                Log("Minigame response: "..tostring(res))
            end

            -- 3) Wait for minigame duration (non-blocking)
            task.wait(BotConfig.WaitGame)

            -- 4) Finish / Catch
            Log("-> Finishing / Catching")
            ok, res = CallRemoteSafe(Remotes.Finish, res) -- pass ticket/response if any
            if not ok then
                Log("Finish call failed: "..tostring(res))
            else
                Log("Finish success.")
            end

            task.wait(BotConfig.WaitCool)
        end
        Log("Bot stopped.")
    end)
end

-- Stop function
local function StopBot()
    BotConfig.IsRunning = false
end

-- UI events
startBtn.MouseButton1Click:Connect(function()
    if not BotConfig.IsRunning then
        StartBot()
    end
end)
stopBtn.MouseButton1Click:Connect(function()
    StopBot()
end)
closeBtn.MouseButton1Click:Connect(function()
    screen:Destroy()
    BotConfig.IsRunning = false
end)
