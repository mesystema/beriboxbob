--[[
    DebugToolUI: Roblox Client-Side Debugging Tool (Mobile First)
    Profesional, efisien, dan aman untuk Roblox Android.
    - UI dengan tombol Start (scan fungsi di ReplicatedStorage) & Stop
    - Menampilkan hasil scan fungsi (RemoteEvent/RemoteFunction) di ReplicatedStorage
    - Tidak blocking main game, event-driven, modular
    - Mengikuti praktik terbaik: camelCase, modular, komentar jelas
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local DebugTool = {}
DebugTool.log = {}
DebugTool.isScanning = false
DebugTool.ui = {}

-- Utility: Serialize instance info
function DebugTool:serializeInstance(instance)
    return string.format("%s [%s]", instance.Name, instance.ClassName)
end

-- Tambahkan log dan update UI
function DebugTool:addLog(message)
    table.insert(self.log, 1, message)
    if #self.log > 50 then
        table.remove(self.log, #self.log)
    end
    self:updateLogUI()
end

-- Scan semua fungsi (RemoteEvent/RemoteFunction) di ReplicatedStorage
function DebugTool:scanRemotes()
    self:addLog("=== Scanning ReplicatedStorage... ===")
    local found = 0
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            found = found + 1
            self:addLog(self:serializeInstance(obj))
        end
    end
    if found == 0 then
        self:addLog("Tidak ditemukan RemoteEvent/RemoteFunction.")
    else
        self:addLog("Total ditemukan: " .. found)
    end
end

-- UI: Buat tampilan utama
function DebugTool:createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugToolUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 340, 0, 320)
    mainFrame.Position = UDim2.new(1, -350, 1, -340)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local startBtn = Instance.new("TextButton")
    startBtn.Size = UDim2.new(0, 80, 0, 36)
    startBtn.Position = UDim2.new(0, 10, 0, 10)
    startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
    startBtn.Text = "Start"
    startBtn.TextColor3 = Color3.new(1,1,1)
    startBtn.Font = Enum.Font.SourceSansBold
    startBtn.TextSize = 20
    startBtn.Parent = mainFrame

    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 80, 0, 36)
    stopBtn.Position = UDim2.new(0, 100, 0, 10)
    stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 47)
    stopBtn.Text = "Stop"
    stopBtn.TextColor3 = Color3.new(1,1,1)
    stopBtn.Font = Enum.Font.SourceSansBold
    stopBtn.TextSize = 20
    stopBtn.Parent = mainFrame

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

    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Size = UDim2.new(1, -20, 1, -100)
    logFrame.Position = UDim2.new(0, 10, 0, 90)
    logFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    logFrame.BackgroundTransparency = 0.2
    logFrame.BorderSizePixel = 0
    logFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
    logFrame.ScrollBarThickness = 6
    logFrame.Parent = mainFrame

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
        if not self.isScanning then
            self.isScanning = true
            self:addLog("Scan dimulai...")
            self:scanRemotes()
        else
            self:addLog("Sudah dalam mode scanning.")
        end
    end)
    stopBtn.MouseButton1Click:Connect(function()
        if self.isScanning then
            self.isScanning = false
            self:addLog("Scan dihentikan.")
        else
            self:addLog("Tidak sedang scanning.")
        end
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

-- Inisialisasi modul
function DebugTool:init()
    self:createUI()
    self:addLog("DebugToolUI siap. Tekan Start untuk scan RemoteEvent/RemoteFunction.")
end

DebugTool:init()

return DebugTool
