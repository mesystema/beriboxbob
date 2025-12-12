--[[
    DebugToolUI: Floating & Minimize-able Roblox Remote Scanner & Tester
    Profesional, mobile-first, efisien, dan tidak blocking UI utama.
    - UI dapat di-minimize/maximize (floating, draggable)
    - Tidak menghalangi gameplay utama (posisi bisa diubah, minimize)
    - Praktik terbaik: camelCase, modular, komentar jelas
    - Untuk client-side debugging RemoteEvent/RemoteFunction
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
DebugTool.localScriptList = {}
DebugTool.currentMode = "remote" -- "remote" or "localscript"

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


-- Scan semua LocalScript di PlayerGui, Backpack, PlayerScripts, dan descendants player
function DebugTool:scanLocalScripts()
    self.localScriptList = {}
    self:addLog("=== Scanning LocalScript (PlayerGui, Backpack, PlayerScripts, descendants)... ===")
    local found = 0
    local function collectScripts(parent)
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("LocalScript") then
                found = found + 1
                table.insert(self.localScriptList, obj)
            end
        end
        -- Juga cek parent itu sendiri
        if parent:IsA("LocalScript") then
            found = found + 1
            table.insert(self.localScriptList, parent)
        end
    end
    local playerGui = player:FindFirstChild("PlayerGui")
    local backpack = player:FindFirstChild("Backpack")
    local playerScripts = player:FindFirstChild("PlayerScripts")
    if playerGui then collectScripts(playerGui) end
    if backpack then collectScripts(backpack) end
    if playerScripts then collectScripts(playerScripts) end
    -- Cek descendants langsung dari player (misal: StarterGear, StarterPack, dsb)
    collectScripts(player)
    if found == 0 then
        self:addLog("Tidak ditemukan LocalScript.")
    else
        self:addLog("Total LocalScript: " .. found)
    end
    self:updateLocalScriptListUI()
end


-- UI: Buat tampilan utama (floating, draggable, minimize-able, mode switch)
function DebugTool:createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugToolUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Floating main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 340, 0, 340)
    mainFrame.Position = UDim2.new(0, 40, 0, 80)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    minimizeBtn.Position = UDim2.new(1, -38, 0, 6)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = Color3.new(1,1,1)
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.TextSize = 22
    minimizeBtn.Parent = mainFrame

    -- Restore button (hidden by default)
    local restoreBtn = Instance.new("TextButton")
    restoreBtn.Size = UDim2.new(0, 48, 0, 32)
    restoreBtn.Position = UDim2.new(0, 10, 0, 10)
    restoreBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
    restoreBtn.Text = "Show"
    restoreBtn.TextColor3 = Color3.new(1,1,1)
    restoreBtn.Font = Enum.Font.SourceSansBold
    restoreBtn.TextSize = 18
    restoreBtn.Visible = false
    restoreBtn.Parent = screenGui

    -- Mode switcher
    local modeSwitchBtn = Instance.new("TextButton")
    modeSwitchBtn.Size = UDim2.new(0, 120, 0, 32)
    modeSwitchBtn.Position = UDim2.new(0, 200, 0, 10)
    modeSwitchBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
    modeSwitchBtn.Text = "Mode: Remote"
    modeSwitchBtn.TextColor3 = Color3.new(1,1,1)
    modeSwitchBtn.Font = Enum.Font.SourceSansBold
    modeSwitchBtn.TextSize = 16
    modeSwitchBtn.Parent = mainFrame

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

    -- LocalScript List Frame
    local localScriptFrame = Instance.new("ScrollingFrame")
    localScriptFrame.Size = UDim2.new(1, -20, 0.5, -40)
    localScriptFrame.Position = UDim2.new(0, 10, 0.5, 20)
    localScriptFrame.BackgroundColor3 = Color3.fromRGB(60, 50, 50)
    localScriptFrame.BackgroundTransparency = 0.1
    localScriptFrame.BorderSizePixel = 0
    localScriptFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
    localScriptFrame.ScrollBarThickness = 6
    localScriptFrame.Visible = false
    localScriptFrame.Parent = mainFrame

    local localScriptTemplate = Instance.new("TextButton")
    localScriptTemplate.Size = UDim2.new(1, 0, 0, 26)
    localScriptTemplate.BackgroundColor3 = Color3.fromRGB(90, 70, 70)
    localScriptTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
    localScriptTemplate.Font = Enum.Font.Code
    localScriptTemplate.TextSize = 15
    localScriptTemplate.TextXAlignment = Enum.TextXAlignment.Left
    localScriptTemplate.Visible = false
    localScriptTemplate.Parent = localScriptFrame

    self.ui = {
        screenGui = screenGui,
        mainFrame = mainFrame,
        minimizeBtn = minimizeBtn,
        restoreBtn = restoreBtn,
        startBtn = startBtn,
        stopBtn = stopBtn,
        logFrame = logFrame,
        logTemplate = logTemplate,
        remoteFrame = remoteFrame,
        remoteTemplate = remoteTemplate,
        localScriptFrame = localScriptFrame,
        localScriptTemplate = localScriptTemplate,
        modeSwitchBtn = modeSwitchBtn
    }

    -- Minimize/restore logic
    minimizeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        restoreBtn.Visible = true
    end)
    restoreBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        restoreBtn.Visible = false
    end)

    -- Mode switch logic
    modeSwitchBtn.MouseButton1Click:Connect(function()
        if self.currentMode == "remote" then
            self.currentMode = "localscript"
            modeSwitchBtn.Text = "Mode: LocalScript"
            remoteFrame.Visible = false
            localScriptFrame.Visible = true
            self:addLog("Beralih ke mode LocalScript viewer.")
            if self.isLogging then
                self:scanLocalScripts()
            end
        else
            self.currentMode = "remote"
            modeSwitchBtn.Text = "Mode: Remote"
            remoteFrame.Visible = true
            localScriptFrame.Visible = false
            self:addLog("Beralih ke mode Remote scanner.")
            if self.isLogging then
                self:scanRemotes()
            end
        end
    end)

    -- Event handler
    startBtn.MouseButton1Click:Connect(function()
        if not self.isLogging then
            self.isLogging = true
            self:addLog("Scan & test mode dimulai...")
            if self.currentMode == "remote" then
                self:scanRemotes()
            else
                self:scanLocalScripts()
            end
        else
            self:addLog("Sudah dalam mode logging.")
        end
    end)
    stopBtn.MouseButton1Click:Connect(function()
        if self.isLogging then
            self.isLogging = false
            self:addLog("Logging dihentikan.")
            self:updateRemoteListUI()
            self:updateLocalScriptListUI()
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
    if not self.isLogging or self.currentMode ~= "remote" then
        remoteFrame.Visible = false
        return
    end
    remoteFrame.Visible = true
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

-- Update daftar LocalScript di UI
function DebugTool:updateLocalScriptListUI()
    local localScriptFrame = self.ui.localScriptFrame
    for _, child in ipairs(localScriptFrame:GetChildren()) do
        if child:IsA("TextButton") and child ~= self.ui.localScriptTemplate then
            child:Destroy()
        end
    end
    if not self.isLogging or self.currentMode ~= "localscript" then
        localScriptFrame.Visible = false
        return
    end
    localScriptFrame.Visible = true
    for i, scriptObj in ipairs(self.localScriptList) do
        local btn = self.ui.localScriptTemplate:Clone()
        btn.Text = scriptObj:GetFullName()
        btn.Position = UDim2.new(0, 0, 0, (i-1)*28)
        btn.Visible = true
        btn.Parent = localScriptFrame
        btn.MouseButton1Click:Connect(function()
            self:openLocalScriptPanel(scriptObj)
        end)
    end
    localScriptFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#self.localScriptList*28, localScriptFrame.AbsoluteSize.Y))
end


-- Panel untuk melihat info LocalScript (scrollable jika panjang)
function DebugTool:openLocalScriptPanel(scriptObj)
    -- Hapus panel lama jika ada
    if self.ui.testPanel then
        self.ui.testPanel:Destroy()
        self.ui.testPanel = nil
    end

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 320, 0, 180)
    panel.Position = UDim2.new(0.5, -160, 0.5, -90)
    panel.AnchorPoint = Vector2.new(0, 0)
    panel.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Parent = self.ui.screenGui
    self.ui.testPanel = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 28)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "LocalScript: " .. scriptObj.Name
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

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -40, 1, -50)
    scrollFrame.Position = UDim2.new(0, 20, 0, 45)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 120)
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = panel

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 120)
    infoLabel.Position = UDim2.new(0, 0, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Parent: " .. (scriptObj.Parent and scriptObj.Parent:GetFullName() or "-") .. "\nClass: " .. scriptObj.ClassName
    infoLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    infoLabel.Font = Enum.Font.Code
    infoLabel.TextSize = 15
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextWrapped = true
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.Parent = scrollFrame

    -- Auto adjust canvas size if infoLabel is longer
    infoLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, infoLabel.AbsoluteSize.Y)
    end)
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
    self:addLog("DebugToolUI siap. Tekan Start untuk scan & test RemoteEvent/RemoteFunction atau LocalScript.")
end

DebugTool:init()

return DebugTool
