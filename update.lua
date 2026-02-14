--[[ 
    FISH-IT BOT v29.1 (STABLE EDITION)
    Fixed: Auto-reel issue & Remote Detection
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIG ]] --
local BotConfig = {
    IsRunning = false,
    UseTimeSpoof = false,
    WaitGame = 2.8, -- Rekomendasi 2.5 - 3.0 agar tidak terdeteksi
    WaitCool = 0.8,
    CastPower = 100,
}

local Remotes = { Charge = nil, Minigame = nil, Finish = nil }

-- [[ UI HELPER (Simplified for Stability) ]] --
-- (Bagian UI tetap sama dengan milikmu, namun pastikan fungsi StartBot menggunakan logic di bawah ini)

local function GetRod()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildWhichIsA("Tool")
end

local function SetupRemotes()
    -- Mencari remotes dengan pola nama yang sering digunakan game Fish-It
    Remotes.Charge = ReplicatedStorage:FindFirstChild("ChargeFish", true) or ReplicatedStorage:FindFirstChild("Cast", true)
    Remotes.Minigame = ReplicatedStorage:FindFirstChild("Minigame", true) or ReplicatedStorage:FindFirstChild("Catch", true)
    Remotes.Finish = ReplicatedStorage:FindFirstChild("FishingComplet", true) or ReplicatedStorage:FindFirstChild("Complete", true)
    
    return Remotes.Charge and Remotes.Minigame and Remotes.Finish
end

-- [[ LOGIC UTAMA ]] --
local function StartBot()
    task.spawn(function()
        while BotConfig.IsRunning do
            if not SetupRemotes() then 
                warn("Remotes tidak ditemukan! Pastikan kamu memegang alat pancing.")
                task.wait(2)
                continue 
            end

            -- 1. MELEMPAR
            local Rod = GetRod()
            if not Rod then
                warn("Pegang alat pancingmu!")
                task.wait(1)
                continue
            end

            -- Invoke lemparan (beberapa game butuh workspace.DistributedGameTime)
            pcall(function() 
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime) 
            end)
            
            -- 2. TUNGGU GIGITAN (Logic Deteksi)
            task.wait(1.5) -- Jeda animasi lempar
            
            local Ticket = nil
            local Attempt = 0
            
            repeat
                Attempt = Attempt + 1
                local FakeTime = BotConfig.UseTimeSpoof and (os.time() - BotConfig.WaitGame) or os.time()
                
                -- Mencoba mendapatkan 'Ticket' dari minigame
                local Success, Response = pcall(function()
                    return Remotes.Minigame:InvokeServer(BotConfig.CastPower, math.random(1000, 9999), FakeTime)
                end)

                if Success and Response then
                    Ticket = Response
                end
                task.wait(0.5)
            until Ticket or Attempt > 30 or not BotConfig.IsRunning

            -- 3. ANGKAT IKAN
            if Ticket then
                if not BotConfig.UseTimeSpoof then
                    task.wait(BotConfig.WaitGame) -- Tunggu durasi minigame normal
                else
                    task.wait(0.2) -- Instan
                end
                
                -- Kirim sinyal selesai
                pcall(function() 
                    Remotes.Finish:FireServer(Ticket) 
                end)
            end

            task.wait(BotConfig.WaitCool)
        end
    end)
end

-- Masukkan fungsi StartBot() ke dalam Button Click UI kamu.
