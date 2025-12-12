--[[
    DebugToolUI: Roblox Remote Scanner & Tester (Mobile First)
    Profesional, modular, dan efisien untuk Roblox Android.
    - Scan semua RemoteEvent/RemoteFunction di ReplicatedStorage
    - Setiap fungsi yang di-scan dapat di-click untuk membuka panel uji (test panel)
    - Test panel memungkinkan pengiriman data (FireServer/InvokeServer) dan melihat respons
    - Tidak blocking main game, event-driven, dan mudah dipelihara
    - Praktik terbaik: camelCase, modular, komentar jelas
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local DebugTool = {}
DebugTool.log = {}
DebugTool.isLogging = false
DebugTool.connections = {}
DebugTool.ui = {}
DebugTool.remoteList = {}

-- Utility: Serialize data (untuk argumen)
function DebugTool:serializeData(data, depth)
    depth = depth or 0
    if depth > 2 then return "<Max Depth>" end
    if typeof(data) == "table" then
        local str = "{"
        for k, v in pairs(data) do
            str = str .. tostring(k) .. "=" .. self:serializeData(v, depth + 1) .. ", "
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

-- Scan semua RemoteEvent/RemoteFunction di ReplicatedStorage
function DebugTool:scanRemotes()
    self.remoteList = {}
    self:addLog("=== Scanning ReplicatedStorage... ===")
    local found = 0
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            found = found + 1
            table.insert(self.remoteList, obj)
        end
    end
    if found == 0 then
        self:addLog("Tidak ditemukan RemoteEvent/RemoteFunction.")
    else
        self:addLog("Total ditemukan: " .. found)
    end
    self:updateRemoteListUI()
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
    logFrame.Size = UDim2.new(1, -20, 0.5, -70)
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

    -- Remote List Frame
    local remoteFrame = Instance.new("ScrollingFrame")
    remoteFrame.Size = UDim2.new(1, -20, 0.5, -40)
    remoteFrame.Position = UDim2.new(0, 10, 0.5, 20)
    remoteFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    remoteFrame.BackgroundTransparency = 0.1
    remoteFrame.BorderSizePixel = 0
    remoteFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
    remoteFrame.ScrollBarThickness = 6
    remoteFrame.Parent = mainFrame

    local remoteTemplate = Instance.new("TextButton")
    remoteTemplate.Size = UDim2.new(1, 0, 0, 26)
    remoteTemplate.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    remoteTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
    remoteTemplate.Font = Enum.Font.Code
    remoteTemplate.TextSize = 15
    remoteTemplate.TextXAlignment = Enum.TextXAlignment.Left
    remoteTemplate.Visible = false
    remoteTemplate.Parent = remoteFrame

    self.ui = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        startBtn = startBtn,
        stopBtn = stopBtn,
        logFrame = logFrame,
        logTemplate = logTemplate,
        remoteFrame = remoteFrame,
        remoteTemplate = remoteTemplate
    }

    -- Event handler
    startBtn.MouseButton1Click:Connect(function()
        if not self.isLogging then
            self.isLogging = true
            self:addLog("Scan & test mode dimulai...")
            self:scanRemotes()
        else
            self:addLog("Sudah dalam mode logging.")
        end
    end)
    stopBtn.MouseButton1Click:Connect(function()
        if self.isLogging then
            self.isLogging = false
            self:addLog("Logging dihentikan.")
            self:updateRemoteListUI()
        else
            self:addLog("Tidak sedang logging.")
        end
    end)
end

-- Update tampilan log di UI
function DebugTool:updateLogUI()
    local logFrame = self.ui.logFrame
    for _, child in ipairs(logFrame:GetChildren()) do
        if child:IsA("TextLabel") and child ~= self.ui.logTemplate then
            child:Destroy()
        end
    end
    for i, msg in ipairs(self.log) do
        local label = self.ui.logTemplate:Clone()
        label.Text = msg
        label.Position = UDim2.new(0, 0, 0, (i-1)*22)
        label.Visible = true
        label.Parent = logFrame
    end
    logFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#self.log*22, logFrame.AbsoluteSize.Y))
end

-- Update daftar remote di UI
function DebugTool:updateRemoteListUI()
    local remoteFrame = self.ui.remoteFrame
    for _, child in ipairs(remoteFrame:GetChildren()) do
        if child:IsA("TextButton") and child ~= self.ui.remoteTemplate then
            child:Destroy()
        end
    end
    if not self.isLogging then return end
    for i, remote in ipairs(self.remoteList) do
        local btn = self.ui.remoteTemplate:Clone()
        btn.Text = remote.Name .. " [" .. remote.ClassName .. "]"
        btn.Position = UDim2.new(0, 0, 0, (i-1)*28)
        btn.Visible = true
        btn.Parent = remoteFrame
        btn.MouseButton1Click:Connect(function()
            self:openTestPanel(remote)
        end)
    end
    remoteFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#self.remoteList*28, remoteFrame.AbsoluteSize.Y))
end

-- Panel untuk mengetes RemoteEvent/RemoteFunction
function DebugTool:openTestPanel(remote)
    -- Hapus panel lama jika ada
    if self.ui.testPanel then
        self.ui.testPanel:Destroy()
        self.ui.testPanel = nil
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 320, 0, 180)
    panel.Position = UDim2.new(0.5, -160, 0.5, -90)
    panel.AnchorPoint = Vector2.new(0, 0)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Parent = self.ui.screenGui
    self.ui.testPanel = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 28)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Test: " .. remote.Name .. " [" .. remote.ClassName .. "]"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -38, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 47)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 18
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        panel:Destroy()
        self.ui.testPanel = nil
    end)

    local argBox = Instance.new("TextBox")
    argBox.Size = UDim2.new(1, -40, 0, 32)
    argBox.Position = UDim2.new(0, 20, 0, 50)
    argBox.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    argBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    argBox.Font = Enum.Font.Code
    argBox.TextSize = 16
    argBox.PlaceholderText = "Masukkan argumen (contoh: 123, 'hello', true)"
    argBox.Text = ""
    argBox.ClearTextOnFocus = false
    argBox.Parent = panel

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(0, 120, 0, 36)
    sendBtn.Position = UDim2.new(0, 20, 0, 100)
    sendBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
    sendBtn.Text = remote:IsA("RemoteEvent") and "FireServer" or "InvokeServer"
    sendBtn.TextColor3 = Color3.new(1,1,1)
    sendBtn.Font = Enum.Font.SourceSansBold
    sendBtn.TextSize = 18
    sendBtn.Parent = panel

    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(1, -40, 0, 36)
    resultLabel.Position = UDim2.new(0, 20, 0, 140)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = ""
    resultLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    resultLabel.Font = Enum.Font.Code
    resultLabel.TextSize = 15
    resultLabel.TextXAlignment = Enum.TextXAlignment.Left
    resultLabel.TextWrapped = true
    resultLabel.Parent = panel

    -- Fungsi parsing argumen sederhana (comma separated, mendukung string, number, boolean)
    local function parseArgs(str)
        local args = {}
        for arg in string.gmatch(str, "([^,]+)") do
            arg = arg:gsub("^%s*(.-)%s*$", "%1") -- trim
            if tonumber(arg) then
                table.insert(args, tonumber(arg))
            elseif arg == "true" then
                table.insert(args, true)
            elseif arg == "false" then
                table.insert(args, false)
            elseif arg:match("^'.*'$") or arg:match('^".*"$') then
                table.insert(args, arg:sub(2, -2))
            else
                table.insert(args, arg)
            end
        end
        return unpack(args)
    end

    sendBtn.MouseButton1Click:Connect(function()
        local args = {parseArgs(argBox.Text)}
        if remote:IsA("RemoteEvent") then
            local ok, err = pcall(function()
                remote:FireServer(unpack(args))
            end)
            if ok then
                resultLabel.Text = "FireServer dikirim."
                self:addLog("[Test] FireServer: " .. remote.Name .. " | Args: " .. self:serializeData(args))
            else
                resultLabel.Text = "Error: " .. tostring(err)
            end
        elseif remote:IsA("RemoteFunction") then
            local ok, res = pcall(function()
                return remote:InvokeServer(unpack(args))
            end)
            if ok then
                resultLabel.Text = "InvokeServer result: " .. self:serializeData(res)
                self:addLog("[Test] InvokeServer: " .. remote.Name .. " | Args: " .. self:serializeData(args) .. " | Result: " .. self:serializeData(res))
            else
                resultLabel.Text = "Error: " .. tostring(res)
            end
        end
    end)
end

-- Inisialisasi modul
function DebugTool:init()
    self:createUI()
    self:addLog("DebugToolUI siap. Tekan Start untuk scan & test RemoteEvent/RemoteFunction.")
end

DebugTool:init()

return DebugTool
