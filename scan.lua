--[[ 
    ANDROID REMOTE SPY UI v8 (DEEP SCAN)
    Fitur:
    - Deep Table Dump: Melihat isi table argumen secara detail.
    - Copy Code: Klik teks log untuk copy script.
    - Ignore List: Membuang log sampah (Analytics, dll).
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- KONFIGURASI
local isLogging = false 
local isMinimized = false
local LogQueue = {} 
local isProcessing = false

-- DAFTAR REMOTE YANG DIABAIKAN (Biarkan kosong jika ingin melihat semua)
local IgnoreList = {
    "CharacterSoundEvent",
    "UpdateCharacter",
    "ClientLog",
    "Analytics",
    "TouchInfo"
}

-- UI VARIABLES
local expandedSize = UDim2.new(0, 450, 0, 300) -- Lebih lebar untuk baca log
local minimizedSize = UDim2.new(0, 150, 0, 30)

-- CLEANUP
if CoreGui:FindFirstChild("AndroidSpyUI_v8") then CoreGui.AndroidSpyUI_v8:Destroy() end

-- 1. UTILITIES (SERIALIZER PINTAR)
local function SerializeTable(tbl, indent)
    if not indent then indent = 0 end
    if indent > 3 then return "{...}" end -- Cegah crash jika table terlalu dalam
    
    local formatting = string.rep("  ", indent)
    local result = "{\n"
    
    for k, v in pairs(tbl) do
        local key = type(k) == "string" and '["'..k..'"]' or "["..tostring(k).."]"
        local val = "nil"
        
        if type(v) == "table" then
            val = SerializeTable(v, indent + 1)
        elseif type(v) == "string" then
            val = '"' .. v .. '"'
        elseif type(v) == "userdata" then
            val = "Instance(" .. tostring(v) .. ")"
        else
            val = tostring(v)
        end
        
        result = result .. formatting .. "  " .. key .. " = " .. val .. ",\n"
    end
    
    return result .. formatting .. "}"
end

local function ParseArgs(args)
    local s = ""
    for i, v in pairs(args) do
        if type(v) == "table" then
            s = s .. SerializeTable(v) .. ", "
        elseif type(v) == "string" then
            s = s .. '"' .. v .. '", '
        else
            s = s .. tostring(v) .. ", "
        end
    end
    return s:sub(1, -3) -- Hapus koma terakhir
end

-- 2. SETUP GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AndroidSpyUI_v8"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -225, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- HEADER
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🕵️ Deep Spy v8 (Tap to Copy)"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- BUTTONS
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, -20, 0, 30)
ButtonContainer.Position = UDim2.new(0, 10, 0, 0)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = ContentFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.48, 0, 1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "▶ START LOGGING"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.Parent = ButtonContainer
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0.48, 0, 1, 0)
ClearBtn.Position = UDim2.new(0.52, 0, 0, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ClearBtn.Text = "🗑️ CLEAR LOGS"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 11
ClearBtn.Parent = ButtonContainer
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 4)

-- SCROLLING LOG
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = ContentFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollFrame

-- UI LOGIC
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(minimizedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"
        ContentFrame.Visible = false; MainFrame.Active = false 
    else
        MainFrame:TweenSize(expandedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "_"
        task.wait(0.2); ContentFrame.Visible = true; MainFrame.Active = true
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    isLogging = not isLogging
    ToggleBtn.Text = isLogging and "⏹ STOP LOGGING" or "▶ START LOGGING"
    ToggleBtn.BackgroundColor3 = isLogging and Color3.fromRGB(241, 196, 15) or Color3.fromRGB(46, 204, 113)
end)

ClearBtn.MouseButton1Click:Connect(function()
    LogQueue = {}
    for _, v in pairs(ScrollFrame:GetChildren()) do 
        if v:IsA("TextButton") then v:Destroy() end 
    end
end)

-- DRAGGABLE
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

-- 3. QUEUE SYSTEM
local function AddToQueue(remoteObj, method, args)
    if not isLogging then return end
    if #LogQueue > 30 then return end -- Anti lag limit
    
    -- Filter Sampah
    for _, name in pairs(IgnoreList) do
        if remoteObj.Name == name then return end
    end
    
    table.insert(LogQueue, {
        name = remoteObj.Name,
        method = method,
        args = args,
        path = remoteObj:GetFullName(),
        color = (method == "FireServer" and "#f1c40f") or "#3498db"
    })
end

-- 4. RENDER LOOP (Safe UI Update)
task.spawn(function()
    while true do
        task.wait(0.15)
        if #LogQueue > 0 then
            for i = 1, 3 do
                local data = table.remove(LogQueue, 1)
                if not data then break end
                
                local argsText = ParseArgs(data.args)
                
                -- Container Button (Agar bisa diklik copy)
                local LogBtn = Instance.new("TextButton")
                LogBtn.Size = UDim2.new(1, 0, 0, 0)
                LogBtn.AutomaticSize = Enum.AutomaticSize.Y
                LogBtn.BackgroundTransparency = 0.8
                LogBtn.BackgroundColor3 = Color3.fromRGB(0,0,0)
                LogBtn.Text = ""
                LogBtn.Parent = ScrollFrame
                
                local Label = Instance.new("TextLabel")
                Label.BackgroundTransparency = 1
                Label.Font = Enum.Font.Code
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextWrapped = true
                Label.RichText = true
                Label.Text = string.format("<font color='%s'><b>[%s] %s</b></font>\n<font color='#bdc3c7'>%s</font>", data.color, data.method, data.name, argsText)
                Label.Size = UDim2.new(1, -10, 1, 0)
                Label.Position = UDim2.new(0, 5, 0, 0)
                Label.Parent = LogBtn
                
                -- Copy Logic
                LogBtn.MouseButton1Click:Connect(function()
                    local code = ""
                    if data.method == "FireServer" then
                        code = string.format("local args = {%s}\ngame.%s:FireServer(unpack(args))", argsText, data.path)
                    else
                        code = string.format("local args = {%s}\ngame.%s:InvokeServer(unpack(args))", argsText, data.path)
                    end
                    setclipboard(code)
                    Label.Text = "✅ COPIED TO CLIPBOARD!"
                    task.wait(1)
                    Label.Text = string.format("<font color='%s'><b>[%s] %s</b></font>\n<font color='#bdc3c7'>%s</font>", data.color, data.method, data.name, argsText)
                end)
            end
            
             if ScrollFrame.CanvasPosition.Y >= (ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y - 100) then
                 ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
            end
        end
    end
end)

-- 5. HOOK (OPTIMIZED & BROAD)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) else make_writeable(mt) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local methodStr = tostring(method):lower()
    
    -- Kita hapus pengecekan ClassName di awal agar lebih sensitif menangkap Framework
    if isLogging and (methodStr == "fireserver" or methodStr == "invokeserver") then
        AddToQueue(self, tostring(method), {...})
    end

    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end
