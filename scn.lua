--[[ 
    ANDROID REMOTE SPY UI v9 (ANTI-FREEZE & PERFORMANCE)
    Fix: 
    - Mengatasi "Stuck/Freeze" saat logging.
    - Menambahkan proteksi Circular Reference (Table Looping).
    - Lookup IgnoreList instan (O(1)).
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

-- IGNORE LIST (Gunakan format ["NamaRemote"] = true)
-- Ini jauh lebih cepat daripada list biasa
local IgnoreList = {
    ["CharacterSoundEvent"] = true,
    ["UpdateCharacter"] = true,
    ["ClientLog"] = true,
    ["Analytics"] = true,
    ["TouchInfo"] = true,
    ["MovementUpdate"] = true,
    ["ControlInput"] = true
}

-- UI SIZE
local expandedSize = UDim2.new(0, 450, 0, 300)
local minimizedSize = UDim2.new(0, 150, 0, 30)

-- CLEANUP UI LAMA
if CoreGui:FindFirstChild("AndroidSpyUI_v9") then CoreGui.AndroidSpyUI_v9:Destroy() end

-- 1. SERIALIZER AMAN (ANTI-CRASH)
-- Fungsi ini mencegah script macet jika membaca table yang aneh-aneh
local function SerializeTable(tbl, indent, seen)
    if not indent then indent = 0 end
    if not seen then seen = {} end -- Cache untuk mendeteksi loop
    
    if indent > 2 then return "{... (Too Deep)}" end -- Batas kedalaman
    if seen[tbl] then return "{... (Circular)}" end -- Batas looping
    
    seen[tbl] = true
    
    local formatting = string.rep("  ", indent)
    local result = "{\n"
    local count = 0
    
    for k, v in pairs(tbl) do
        count = count + 1
        if count > 20 then -- Jangan baca table jika isinya ribuan (bikin lag)
            result = result .. formatting .. "  ... (Truncated)\n"
            break 
        end
        
        local key = type(k) == "string" and '["'..k..'"]' or "["..tostring(k).."]"
        local val = "nil"
        
        if type(v) == "table" then
            val = SerializeTable(v, indent + 1, seen)
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
    -- Pcall agar jika tostring gagal, script tidak stop
    pcall(function()
        for i, v in pairs(args) do
            if type(v) == "table" then
                s = s .. SerializeTable(v) .. ", "
            elseif type(v) == "string" then
                s = s .. '"' .. v .. '", '
            else
                s = s .. tostring(v) .. ", "
            end
        end
    end)
    return s:sub(1, -3)
end

-- 2. SETUP GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AndroidSpyUI_v9"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -225, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
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
TitleLabel.Text = "🚀 Spy v9 (Performance Mode)"
TitleLabel.TextColor3 = Color3.fromRGB(52, 152, 219)
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
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ButtonContainer
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0.48, 0, 1, 0)
ClearBtn.Position = UDim2.new(0.52, 0, 0, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ClearBtn.Text = "🗑️ CLEAR"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 12
ClearBtn.Parent = ButtonContainer
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 4)

-- SCROLL LOG
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = ContentFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.Parent = ScrollFrame

-- LOGIC
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
    ToggleBtn.Text = isLogging and "⏹ STOP" or "▶ START"
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

-- 3. QUEUE SYSTEM (OPTIMIZED)
local function AddToQueue(remoteObj, method, args)
    if not isLogging then return end
    if #LogQueue > 20 then return end -- Batas buffer kecil agar tidak freeze
    
    table.insert(LogQueue, {
        name = remoteObj.Name,
        method = method,
        args = args,
        path = remoteObj:GetFullName(),
        color = (method == "FireServer" and "#f1c40f") or "#3498db"
    })
end

-- 4. RENDER LOOP (BACKGROUND THREAD)
task.spawn(function()
    while true do
        task.wait(0.2) -- Jeda lebih lama agar HP tidak panas
        
        if #LogQueue > 0 then
            -- Proses 1 per 1 agar UI Thread tidak macet
            local data = table.remove(LogQueue, 1)
            
            if data then
                local success, argsText = pcall(function() return ParseArgs(data.args) end)
                if not success then argsText = "Error Parsing Arguments" end
                
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
                
                -- Copy Code
                LogBtn.MouseButton1Click:Connect(function()
                    local code = ""
                    if data.method == "FireServer" then
                        code = string.format("local args = {%s}\ngame.%s:FireServer(unpack(args))", argsText, data.path)
                    else
                        code = string.format("local args = {%s}\ngame.%s:InvokeServer(unpack(args))", argsText, data.path)
                    end
                    setclipboard(code)
                    Label.Text = "✅ COPIED!"
                    task.wait(0.5)
                    Label.Text = string.format("<font color='%s'><b>[%s] %s</b></font>\n<font color='#bdc3c7'>%s</font>", data.color, data.method, data.name, argsText)
                end)
            end
            
             if ScrollFrame.CanvasPosition.Y >= (ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y - 100) then
                 ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
            end
        end
    end
end)

-- 5. HOOK (FAST FILTER)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) else make_writeable(mt) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local methodStr = tostring(method):lower()
    
    if isLogging and (methodStr == "fireserver" or methodStr == "invokeserver") then
        -- Cek IgnoreList SECARA INSTAN (O(1)) sebelum proses apapun
        -- Ini mencegah lag karena remote sampah
        if not IgnoreList[self.Name] then
            AddToQueue(self, tostring(method), {...})
        end
    end

    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end
