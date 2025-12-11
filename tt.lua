-- [[ FISH-IT BOT v30: LOG BASED FIX ]] --
-- Remote Names Updated based on your Logs:
-- 1. RF/ChargeFishingRod
-- 2. RF/RequestFishingMinigameStarted
-- 3. RE/FishingCompleted (Asumsi nama RE terakhir)

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIG ]] --
local BotConfig = {
    IsRunning = false,
    WaitGame = 2.4, -- Waktu tunggu minigame (Agar tidak ditolak server)
    WaitCool = 0.5, -- Jeda antar ikan
    CastPower = 1.0,
    WaterDepthOffset = 15
}

-- [[ UI SETUP ]] --
-- (Bagian UI saya singkat biar fokus ke logic, pakai UI lama Anda tidak apa-apa)
-- Pastikan tombol Start memanggil function StartBot()

local Remotes = { Charge = nil, Minigame = nil, Finish = nil }

-- [[ 1. SETUP REMOTES SESUAI LOG ]] --
local function SetupRemotes()
    -- Mencari Remote berdasarkan nama dari LOG Anda
    local function Find(name, type)
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == name and v:IsA(type) then return v end
        end
        return nil
    end

    Remotes.Charge = Find("ChargeFishingRod", "RemoteFunction") -- Sesuai Log
    Remotes.Minigame = Find("RequestFishingMinigameStarted", "RemoteFunction") -- Sesuai Log
    
    -- Coba cari FishingCompleted, kalau gak ada coba variasi lain
    Remotes.Finish = Find("FishingCompleted", "RemoteEvent") 
    if not Remotes.Finish then Remotes.Finish = Find("FishingComplet", "RemoteEvent") end

    if Remotes.Charge and Remotes.Minigame and Remotes.Finish then
        print("✅ REMOTE DITEMUKAN SESUAI LOG!")
        return true
    else
        warn("❌ Gagal mencari remote. Pastikan nama sesuai Log.")
        return false
    end
end

-- [[ 2. LOGIKA UTAMA ]] --
local function StartBot()
    task.spawn(function()
        if not SetupRemotes() then return end
        BotConfig.IsRunning = true
        
        while BotConfig.IsRunning do
            -- A. EQUIP TOOL (Opsional, server biasanya handle ini)
            
            -- B. LEMPAR (ChargeFishingRod)
            -- InvokeServer akan menunggu sampai server bilang "Lempar OK"
            pcall(function() 
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime) 
            end)
            
            -- HACK: Paksa pelampung turun
            task.spawn(function()
                local s = tick()
                while tick()-s < 1 do
                    for _,v in pairs(workspace:GetChildren()) do
                        if v.Name:find("Bobber") then
                            v.Velocity = Vector3.new(0,-50,0) -- Tarik ke bawah
                        end
                    end
                    task.wait()
                end
            end)

            -- C. TUNGGU GIGITAN (SPAM CHECK)
            -- Walaupun Invoke lempar sudah selesai, ikan belum tentu gigit.
            -- Kita spam RequestMinigame sampai server ngasih tiket.
            
            local Ticket = nil
            local StartWait = tick()
            
            repeat
                task.wait(0.25) -- Cek setiap 0.25 detik
                
                local randomID = math.random(100000000, 999999999) 
                
                -- Argumen disesuaikan dengan LOG: (Power, RandomID, Time)
                local Success, Response = pcall(function()
                    return Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                end)
                
                -- Kalau response bukan nil, berarti ikan SUDAH gigit
                if Success and Response ~= nil then
                    Ticket = Response -- Simpan tiketnya
                end
                
                if (tick() - StartWait) > 20 then break end -- Timeout 20 detik
            until Ticket ~= nil or not BotConfig.IsRunning
            
            if Ticket then
                -- D. PROSES MINIGAME (WAITING)
                -- Kita MENGHORMATI durasi minigame agar tidak di-kick
                if BotConfig.WaitGame > 0 then
                    task.wait(BotConfig.WaitGame)
                end
                
                -- E. SELESAI (Kirim Tiket Balik)
                pcall(function()
                    Remotes.Finish:FireServer(Ticket)
                end)
                
                -- Hapus animasi karakter biar rapi
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    for _,t in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do t:Stop() end
                end
            end
            
            task.wait(BotConfig.WaitCool)
        end
    end)
end
