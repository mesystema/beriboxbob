--[[
    DebugToolUI: Remote Scanner & Source Viewer Profesional
    REVISI: Peningkatan Responsivitas UI dan Skala Mobile-Friendly.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local DebugTool = {}
DebugTool.log = {}
DebugTool.isLogging = false
DebugTool.remoteList = {}
DebugTool.scriptsList = {}
DebugTool.ui = {}
DebugTool.activePanel = nil -- Melacak panel yang sedang dibuka

-- === UTILITY FUNCTIONS ===

function DebugTool:serializeData(data, depth)
    depth = depth or 0
    if depth > 2 then return "<Max Depth>" end
    if typeof(data) == "table" then
        local str = "{"
        for k, v in pairs(data) do
            local keyStr = (typeof(k) == "string" and ("'" .. k .. "'") or tostring(k))
            str = str .. keyStr .. ": " .. self:serializeData(v, depth + 1) .. ", "
        end
        return str:sub(1, -3) .. "}"
    else
        return tostring(data)
    end
end

function DebugTool:addLog(message)
    table.insert(self.log, 1, message)
    if #self.log > 50 then
        table.remove(self.log, #self.log)
    end
    self:updateLogUI()
end

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
    return args
end

-- === SCANNING LOGIC ===

function DebugTool:scanRemotes()
    self.remoteList = {}
    self:addLog("=== Scanning Remotes... ===")
    local found = 0
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            found = found + 1
            table.insert(self.remoteList, obj)
        end
    end
    self:addLog("Remote ditemukan: " .. found)
    self:updateRemoteListUI()
end

function DebugTool:scanScripts()
    self.scriptsList = {}
    local locations = {
        PlayerGui,
        player:WaitForChild("PlayerScripts"),
        ReplicatedStorage 
    }
    self:addLog("=== Scanning Client Scripts... ===")
    local found = 0
    
    local function findScripts(parent)
        for _, obj in ipairs(parent:GetChildren()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                found = found + 1
                table.insert(self.scriptsList, obj)
            end
            if obj:IsA("Folder") or obj:IsA("ScreenGui") or obj:IsA("Frame") or obj:IsA("Model") then
                findScripts(obj)
            end
        end
    end

    for _, loc in ipairs(locations) do
        findScripts(loc)
    end
    
    self:addLog("Skrip Klien ditemukan: " .. found)
    self:updateScriptsListUI()
end

-- === UI CREATION & HANDLERS ===

function DebugTool:createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DebugToolUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    -- Main frame (Skala responsif, sekitar 30% lebar layar, minimal 320px)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0.3, 0, 0, 500) -- Skala Lebar, Tinggi Tetap untuk kepadatan
    mainFrame.MinSize = Vector2.new(320, 500) -- Ukuran minimal
    mainFrame.Position = UDim2.new(0, 10, 0, 80)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Minimize/Restore, Start/Stop Buttons... (Tidak berubah)
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    minimizeBtn.Position = UDim2.new(1, -38, 0, 6)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    minimizeBtn.Text = "-"
    minimizeBtn.TextColor3 = Color3.new(1,1,1)
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.TextSize = 22
    minimizeBtn.Parent = mainFrame

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
    logFrame.Size = UDim2.new(1, -20, 0.3, -70)
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
    
    -- Tabs for Remote/Scripts
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -20, 0, 30)
    tabFrame.Position = UDim2.new(0, 10, 0.3, 70)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = mainFrame
    
    local remoteTabBtn = Instance.new("TextButton")
    remoteTabBtn.Size = UDim2.new(0.5, -5, 1, 0)
    remoteTabBtn.Position = UDim2.new(0, 0, 0, 0)
    remoteTabBtn.Text = "Remotes"
    remoteTabBtn.Font = Enum.Font.SourceSansBold
    remoteTabBtn.TextSize = 18
    remoteTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    remoteTabBtn.Parent = tabFrame

    local scriptTabBtn = Instance.new("TextButton")
    scriptTabBtn.Size = UDim2.new(0.5, -5, 1, 0)
    scriptTabBtn.Position = UDim2.new(0.5, 5, 0, 0)
    scriptTabBtn.Text = "Scripts"
    scriptTabBtn.Font = Enum.Font.SourceSansBold
    scriptTabBtn.TextSize = 18
    scriptTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    scriptTabBtn.Parent = tabFrame

    -- Container Frame for Lists
    local listContainer = Instance.new("Frame")
    listContainer.Size = UDim2.new(1, -20, 0.5, -70)
    listContainer.Position = UDim2.new(0, 10, 0.3, 100)
    listContainer.BackgroundTransparency = 1
    listContainer.Parent = mainFrame
    
    -- Remote List Frame
    local remoteFrame = Instance.new("ScrollingFrame")
    remoteFrame.Name = "RemoteList"
    remoteFrame.Size = UDim2.new(1, 0, 1, 0)
    remoteFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    remoteFrame.BackgroundTransparency = 0.1
    remoteFrame.BorderSizePixel = 0
    remoteFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
    remoteFrame.ScrollBarThickness = 6
    remoteFrame.Parent = listContainer

    -- Script List Frame
    local scriptsFrame = remoteFrame:Clone()
    scriptsFrame.Name = "ScriptsList"
    scriptsFrame.BackgroundColor3 = Color3.fromRGB(50, 60, 50)
    scriptsFrame.Visible = false
    scriptsFrame.Parent = listContainer

    local listTemplate = Instance.new("TextButton")
    listTemplate.Size = UDim2.new(1, 0, 0, 26)
    listTemplate.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    listTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
    listTemplate.Font = Enum.Font.Code
    listTemplate.TextSize = 15
    listTemplate.TextXAlignment = Enum.TextXAlignment.Left
    listTemplate.Visible = false
    listTemplate.Parent = listContainer 

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
        scriptsFrame = scriptsFrame,
        listTemplate = listTemplate,
        remoteTabBtn = remoteTabBtn,
        scriptTabBtn = scriptTabBtn,
    }

    local function switchTab(tabName)
        if tabName == "Remotes" then
            remoteFrame.Visible = true
            scriptsFrame.Visible = false
            remoteTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            scriptTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        elseif tabName == "Scripts" then
            remoteFrame.Visible = false
            scriptsFrame.Visible = true
            remoteTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            scriptTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        end
    end

    remoteTabBtn.MouseButton1Click:Connect(function() switchTab("Remotes") end)
    scriptTabBtn.MouseButton1Click:Connect(function() switchTab("Scripts") end)

    minimizeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        restoreBtn.Visible = true
        if self.activePanel then self.activePanel.Visible = false end
    end)
    restoreBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        restoreBtn.Visible = false
        if self.activePanel then self.activePanel.Visible = true end
    end)

    startBtn.MouseButton1Click:Connect(function()
        if not self.isLogging then
            self.isLogging = true
            self:addLog("Scan & test mode dimulai...")
            self:scanRemotes()
            self:scanScripts()
        else
            self:addLog("Sudah dalam mode logging.")
        end
    end)
    stopBtn.MouseButton1Click:Connect(function()
        if self.isLogging then
            self.isLogging = false
            self:addLog("Logging dihentikan.")
            self:updateRemoteListUI()
            self:updateScriptsListUI()
            if self.activePanel then self.activePanel:Destroy(); self.activePanel = nil end
        else
            self:addLog("Tidak sedang logging.")
        end
    end)
end

-- === UI UPDATES ===

function DebugTool:updateLogUI()
    local logFrame = self.ui.logFrame
    local template = self.ui.logTemplate
    for _, child in ipairs(logFrame:GetChildren()) do
        if child:IsA("TextLabel") and child ~= template then child:Destroy() end
    end
    for i, msg in ipairs(self.log) do
        local label = template:Clone()
        label.Text = msg
        label.Position = UDim2.new(0, 0, 0, (i-1)*22)
        label.Visible = true
        label.Parent = logFrame
    end
    logFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#self.log*22, logFrame.AbsoluteSize.Y))
    logFrame.CanvasPosition = Vector2.new(0, 0)
end

local function updateList(frame, list, handler)
    local template = DebugTool.ui.listTemplate
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    if not DebugTool.isLogging then return end
    for i, item in ipairs(list) do
        local btn = template:Clone()
        btn.Text = item.Name .. " [" .. item.ClassName .. "]" .. (item.Parent and (" (" .. item.Parent.Name .. ")") or "")
        btn.Position = UDim2.new(0, 0, 0, (i-1)*28)
        btn.Visible = true
        btn.Parent = frame
        btn.MouseButton1Click:Connect(function()
            handler(item)
        end)
    end
    frame.CanvasSize = UDim2.new(0, 0, 0, math.max(#list*28, frame.AbsoluteSize.Y))
end

function DebugTool:updateRemoteListUI()
    updateList(self.ui.remoteFrame, self.remoteList, function(remote) self:openTestPanel(remote) end)
end

function DebugTool:updateScriptsListUI()
    updateList(self.ui.scriptsFrame, self.scriptsList, function(scriptObj) self:viewSourceCode(scriptObj) end)
end

-- === PANEL LOGIC: REMOTE TESTER ===

function DebugTool:openTestPanel(remote)
    if self.activePanel then self.activePanel:Destroy() end
    
    local panel = Instance.new("Frame")
    -- Menggunakan ukuran tetap yang kecil
    panel.Size = UDim2.new(0, 320, 0, 200)
    panel.Position = UDim2.new(0.5, -160, 0.5, -100)
    panel.AnchorPoint = Vector2.new(0, 0)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Parent = self.ui.screenGui
    self.activePanel = panel

    -- ... [Kontrol dan Logika Pengujian Remote] ...
    
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
        self.activePanel = nil
    end)
    
    local argBox = Instance.new("TextBox")
    argBox.Size = UDim2.new(1, -40, 0, 32)
    argBox.Position = UDim2.new(0, 20, 0, 50)
    argBox.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    argBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    argBox.Font = Enum.Font.Code
    argBox.TextSize = 16
    argBox.PlaceholderText = "Argumen: 123, 'string', true"
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

    sendBtn.MouseButton1Click:Connect(function()
        local args = parseArgs(argBox.Text)
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

-- === PANEL LOGIC: SOURCE VIEWER (REVISI SKALA) ===

function DebugTool:viewSourceCode(scriptObj)
    if self.activePanel then self.activePanel:Destroy() end

    local panel = Instance.new("Frame")
    -- Menggunakan skala responsif (80% lebar dan tinggi layar)
    panel.Size = UDim2.new(0.8, 0, 0.8, 0)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Parent = self.ui.screenGui
    self.activePanel = panel
    
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
        self.activePanel = nil
    end)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 28)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Source: " .. scriptObj.Name .. " [" .. scriptObj.ClassName .. "]"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    local sourceFrame = Instance.new("ScrollingFrame")
    sourceFrame.Size = UDim2.new(1, -40, 1, -60)
    sourceFrame.Position = UDim2.new(0, 20, 0, 50)
    sourceFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    sourceFrame.BackgroundTransparency = 0.0
    sourceFrame.BorderSizePixel = 0
    sourceFrame.ScrollBarThickness = 6
    sourceFrame.Parent = panel

    local textBox = Instance.new("TextLabel") -- Menggunakan TextLabel untuk mengatasi masalah UI responsiveness di TextBox
    textBox.Size = UDim2.new(1, 0, 0, 10000) -- Ukuran vertikal besar agar bisa di-scroll
    textBox.BackgroundTransparency = 1
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 12
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.TextWrapped = false -- Penting: agar kode tidak terpotong
    textBox.Parent = sourceFrame
    
    -- MENGAMBIL KODE SUMBER
    local sourceCode = nil
    local success, err = pcall(function()
        sourceCode = scriptObj.Source 
    end)
    
    -- Pembersihan Output: Menghilangkan error skrip yang terlihat kosong
    if success and type(sourceCode) == "string" and sourceCode:len() > 0 then
        textBox.Text = sourceCode
        textBox.Size = UDim2.new(1, 0, 0, math.max(sourceFrame.AbsoluteSize.Y, sourceCode:len() * 0.12)) -- Perkiraan ukuran
        sourceFrame.CanvasSize = UDim2.new(0, 0, 0, textBox.Size.Offset.Y)
        self:addLog("[Source] Berhasil mengambil kode dari: " .. scriptObj.Name .. " (Ukuran: " .. sourceCode:len() .. " bytes)")
    else
        textBox.Text = "------------------------------------------------------\n-- KODE SUMBER KOSONG, TIDAK DITEMUKAN, ATAU DIBLOKIR --\n------------------------------------------------------\nIni mungkin terjadi jika:\n1. Skrip ini adalah skrip Server (Script) yang tidak direplikasi kodenya.\n2. ModuleScript belum dimuat oleh LocalScript.\n3. Skrip sengaja dikosongkan/dienkripsi."
        textBox.TextSize = 14
        textBox.Size = UDim2.new(1, 0, 0, 150)
        sourceFrame.CanvasSize = UDim2.new(0, 0, 0, 150)
        self:addLog("[Source] Gagal mengambil kode: " .. scriptObj.Name)
    end
end

-- === INITIALIZATION ===

function DebugTool:init()
    self:createUI()
    self:addLog("DebugToolUI siap. Tekan Start untuk scan Remote/Script Klien.")
end

DebugTool:init()

return DebugTool
