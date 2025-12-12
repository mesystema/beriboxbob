--[[
    DebugToolUI: UI Debugging Tool untuk Roblox (Mobile First)
    - Menyediakan Start/Stop button untuk logging RemoteEvent/RemoteFunction
    - Menampilkan log aktivitas secara real-time tanpa blocking main game
    - Mengikuti praktik terbaik: modular, efisien, dan aman untuk client-side
    - Hanya untuk debugging di development environment
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Modul utama DebugTool
local DebugTool = {}
DebugTool.isLogging = false
DebugTool.log = {}
DebugTool.connections = {}

-- Serialize data untuk log
function DebugTool:serialize(data, depth)
    depth = depth or 0
    if depth > 2 then return "<Max Depth>" end
    if typeof(data) == "table" then
        local str = "{"
        for k, v in pairs(data) do
            str = str .. tostring(k) .. "=" .. self:serialize(v, depth + 1) .. ", "
        end
        return str .. "}"
    else
        return tostring(data)
    end
end

-- Tambahkan log dan update UI
function DebugTool:addLog(message)
    table.insert(self.log, 1, message)
    if #self.log > 50 then
        table.remove(self.log, #self.log)
    end
    self:updateLogUI()
end

-- Hook RemoteEvent/RemoteFunction
function DebugTool:hookRemotes()
    -- Disconnect jika sudah ada koneksi sebelumnya
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
    self.connections = {}

    local function hookRemote(remote)
        if remote:IsA("RemoteEvent") then
            -- OnClientEvent
            table.insert(self.connections, remote.OnClientEvent:Connect(function(...)
                if self.isLogging then
                    self:addLog("OnClientEvent: " .. remote.Name .. " | Data: " .. self:serialize({...}))
                end
            end))
            -- FireServer (override)
            if not remote.__debugToolHooked then
                local oldFireServer = remote.FireServer
                remote.FireServer = function(selfRemote, ...)
                    if DebugTool.isLogging then
                        DebugTool:addLog("FireServer: " .. selfRemote.Name .. " | Data: " .. DebugTool:serialize({...}))
                    end
                    return oldFireServer(selfRemote, ...)
                end
                remote.__debugToolHooked = true
            end
        elseif remote:IsA("RemoteFunction") then
            -- OnClientInvoke
            if not remote.__debugToolHooked then
                local oldOnClientInvoke = remote.OnClientInvoke
                remote.OnClientInvoke = function(...)
                    if DebugTool.isLogging then
                        DebugTool:addLog("OnClientInvoke: " .. remote.Name .. " | Data: " .. DebugTool:serialize({...}))
                    end
                    if oldOnClientInvoke then
                        return oldOnClientInvoke(...)
                    end
                end
                -- InvokeServer (override)
                local oldInvokeServer = remote.InvokeServer
                remote.InvokeServer = function(selfRemote, ...)
                    if DebugTool.isLogging then
                        DebugTool:addLog("InvokeServer: " .. selfRemote.Name .. " | Data: " .. DebugTool:serialize({...}))
                    end
                    return oldInvokeServer(selfRemote, ...)
                end
                remote.__debugToolHooked = true
            end
        end
    end

    -- Hook semua RemoteEvent/RemoteFunction di ReplicatedStorage
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            hookRemote(remote)
        end
    end

    -- Hook remote baru yang ditambahkan
    table.insert(self.connections, ReplicatedStorage.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            hookRemote(obj)
        end
    end))
end

-- UI: Buat tampilan utama
function DebugTool:createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugToolUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Frame utama
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 340, 0, 320)
    mainFrame.Position = UDim2.new(1, -350, 1, -340)
    mainFrame.AnchorPoint = Vector2.new(0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Start Button
    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0, 80, 0, 36)
    startBtn.Position = UDim2.new(0, 10, 0, 10)
    startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
    startBtn.Text = "Start"
    startBtn.TextColor3 = Color3.new(1,1,1)
    startBtn.Font = Enum.Font.SourceSansBold
    startBtn.TextSize = 20
    startBtn.Parent = mainFrame

    -- Stop Button
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 80, 0, 36)
    stopBtn.Position = UDim2.new(0, 100, 0, 10)
    stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 47)
    stopBtn.Text = "Stop"
    stopBtn.TextColor3 = Color3.new(1,1,1)
    stopBtn.Font = Enum.Font.SourceSansBold
    stopBtn.TextSize = 20
    stopBtn.Parent = mainFrame

    -- Log Label
    local logLabel = Instance.new("TextLabel")
    logLabel.Size = UDim2.new(1, -20, 0, 30)
    logLabel.Position = UDim2.new(0, 10, 0, 60)
    logLabel.BackgroundTransparency = 1
    logLabel.Text = "Log:"
    logLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    logLabel.Font = Enum.Font.SourceSansBold
    logLabel.TextSize = 18
    logLabel.TextXAlignment = Enum.TextXAlignment.Left
    logLabel.Parent = mainFrame

    -- Log ScrollingFrame
    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Size = UDim2.new(1, -20, 1, -100)
    logFrame.Position = UDim2.new(0, 10, 0, 90)
    logFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    logFrame.BackgroundTransparency = 0.2
    logFrame.BorderSizePixel = 0
    logFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
    logFrame.ScrollBarThickness = 6
    logFrame.Parent = mainFrame

    -- Template untuk log item
    local logTemplate = Instance.new("TextLabel")
    logTemplate.Size = UDim2.new(1, 0, 0, 22)
    logTemplate.BackgroundTransparency = 1
    logTemplate.TextColor3 = Color3.fromRGB(220, 220, 220)
    logTemplate.Font = Enum.Font.Code
    logTemplate.TextSize = 15
    logTemplate.TextXAlignment = Enum.TextXAlignment.Left
    logTemplate.ClipsDescendants = true
    logTemplate.Visible = false
    logTemplate.Parent = logFrame

    -- Simpan referensi UI
    self.ui = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        startBtn = startBtn,
        stopBtn = stopBtn,
        logFrame = logFrame,
        logTemplate = logTemplate
    }

    -- Event handler
    startBtn.MouseButton1Click:Connect(function()
        self:startLogging()
    end)
    stopBtn.MouseButton1Click:Connect(function()
        self:stopLogging()
    end)
end

-- Update tampilan log di UI
function DebugTool:updateLogUI()
    local logFrame = self.ui.logFrame
    -- Bersihkan log lama
    for _, child in ipairs(logFrame:GetChildren()) do
        if child:IsA("TextLabel") and child ~= self.ui.logTemplate then
            child:Destroy()
        end
    end
    -- Tambahkan log baru
    for i, msg in ipairs(self.log) do
        local label = self.ui.logTemplate:Clone()
        label.Text = msg
        label.Position = UDim2.new(0, 0, 0, (i-1)*22)
        label.Visible = true
        label.Parent = logFrame
    end
    logFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#self.log*22, logFrame.AbsoluteSize.Y))
end

-- Mulai logging
function DebugTool:startLogging()
    if not self.isLogging then
        self.isLogging = true
        self:addLog("Logging started.")
    end
end

-- Stop logging
function DebugTool:stopLogging()
    if self.isLogging then
        self.isLogging = false
        self:addLog("Logging stopped.")
    end
end

-- Inisialisasi modul
function DebugTool:init()
    self:createUI()
    self:hookRemotes()
    self:addLog("DebugToolUI ready. Tekan Start untuk mulai logging.")
end

DebugTool:init()

return DebugTool
