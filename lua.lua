
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                 SwiftBara Client UI                            ║
    ║              Minecraft Client Style v1.3                       ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

-- Cleanup
for _, g in pairs(game:GetService("CoreGui"):GetChildren()) do
    if g.Name:find("SwiftBara") then g:Destroy() end
end

local SwiftBara = {
    Version = "1.3.0",
    Categories = {},
    EnabledModules = {},
    Keybinds = {},
    ToggleKey = Enum.KeyCode.RightShift,
    GUIVisible = true,
    SelectingKeybind = false,  -- Trạng thái đang chọn keybind
    SelectedModule = nil,      -- Module đang được chọn để gán keybind
    KeybindSelectionMode = "SINGLE", -- "SINGLE" hoặc "ALL"
    ColorPickers = {},         -- Quản lý các color picker đang mở
    OpenDropdowns = {}         -- Quản lý các dropdown đang mở
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

-- Theme
local Theme = {
    Background = Color3.fromRGB(18, 18, 24),
    Header = Color3.fromRGB(28, 28, 38),
    Module = Color3.fromRGB(22, 22, 30),
    Card = Color3.fromRGB(25, 25, 35),
    
    Transparency = 0.4,
    
    Primary = Color3.fromRGB(255, 100, 50),
    Secondary = Color3.fromRGB(0, 200, 255),
    Accent = Color3.fromRGB(150, 100, 255),
    Success = Color3.fromRGB(100, 255, 130),
    Warning = Color3.fromRGB(255, 200, 50),
    Error = Color3.fromRGB(255, 80, 80),
    
    Enabled = Color3.fromRGB(100, 255, 130),
    Disabled = Color3.fromRGB(140, 140, 155),
    Hover = Color3.fromRGB(40, 40, 55),
    
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(130, 130, 145),
    Selecting = Color3.fromRGB(255, 200, 50), -- Màu khi đang chọn keybind
    None = Color3.fromRGB(200, 100, 100), -- Màu cho "None"
    Button = Color3.fromRGB(45, 45, 60),
}

-- Utilities
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then pcall(function() obj[k] = v end) end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, props, time)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- Helper functions
local function tableFind(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

local function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Close all open dropdowns
local function CloseAllDropdowns()
    for _, dropdown in pairs(SwiftBara.OpenDropdowns) do
        if dropdown and dropdown.Parent then
            dropdown:Destroy()
        end
    end
    SwiftBara.OpenDropdowns = {}
end

-- Close all color pickers
local function CloseAllColorPickers()
    for _, picker in pairs(SwiftBara.ColorPickers) do
        if picker and picker.Parent then
            picker:Destroy()
        end
    end
    SwiftBara.ColorPickers = {}
end

--[[
    ═══════════════════════════════════════════════════════════════
                         FIXED DRAGGABLE
    ═══════════════════════════════════════════════════════════════
]]

local function MakeDraggable(frame, handle)
    handle = handle or frame
    
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--[[
    ═══════════════════════════════════════════════════════════════
                              MAIN GUI
    ═══════════════════════════════════════════════════════════════
]]

local MainGui = Create("ScreenGui", {
    Name = "SwiftBara_Client",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = CoreGui
})

local ArrayGui = Create("ScreenGui", {
    Name = "SwiftBara_ArrayList",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = CoreGui
})

--[[
    ═══════════════════════════════════════════════════════════════
               ARRAY LIST WITH CONNECTED GRADIENT BAR
    ═══════════════════════════════════════════════════════════════
]]

local ArrayContainer = Create("Frame", {
    Name = "ArrayContainer",
    Parent = ArrayGui,
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -8, 0, 8),
    Size = UDim2.new(0, 200, 0, 500)
})

-- Connected gradient bar on the right side
local GradientBar = Create("Frame", {
    Name = "GradientBar",
    Parent = ArrayContainer,
    BackgroundColor3 = Color3.new(1, 1, 1),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 3, 0, 0)
})
Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = GradientBar})

local GradientEffect = Create("UIGradient", {
    Parent = GradientBar,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(0.5, Theme.Secondary),
        ColorSequenceKeypoint.new(1, Theme.Primary)
    }),
    Rotation = 90
})

-- Animate gradient continuously
local gradientOffset = 0
RunService.RenderStepped:Connect(function(dt)
    gradientOffset = (gradientOffset + dt * 0.5) % 1
    
    if GradientEffect and GradientEffect.Parent then
        GradientEffect.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Primary:Lerp(Theme.Secondary, math.abs(math.sin(gradientOffset * math.pi * 2)))),
            ColorSequenceKeypoint.new(0.33, Theme.Secondary:Lerp(Theme.Primary, math.abs(math.sin((gradientOffset + 0.33) * math.pi * 2)))),
            ColorSequenceKeypoint.new(0.66, Theme.Primary:Lerp(Theme.Secondary, math.abs(math.sin((gradientOffset + 0.66) * math.pi * 2)))),
            ColorSequenceKeypoint.new(1, Theme.Secondary:Lerp(Theme.Primary, math.abs(math.sin((gradientOffset + 1) * math.pi * 2))))
        })
    end
end)

-- Modules list
local ModulesList = Create("Frame", {
    Name = "ModulesList",
    Parent = ArrayContainer,
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -5, 0, 0),
    Size = UDim2.new(1, -5, 1, 0)
})

Create("UIListLayout", {
    Parent = ModulesList,
    Padding = UDim.new(0, 1),
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder
})

-- Update Array List
local function UpdateArrayList()
    -- Clear old entries
    for _, child in pairs(ModulesList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Sort by name length (longest first)
    local sorted = {}
    for name, data in pairs(SwiftBara.EnabledModules) do
        table.insert(sorted, {name = name, data = data})
    end
    table.sort(sorted, function(a, b) return #a.name > #b.name end)
    
    -- Update gradient bar height
    local totalHeight = #sorted * 21
    Tween(GradientBar, {Size = UDim2.new(0, 3, 0, math.max(totalHeight, 0))}, 0.2)
    
    -- Create entries
    for i, module in ipairs(sorted) do
        local entry = Create("Frame", {
            Name = module.name,
            Parent = ModulesList,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.3,
            Size = UDim2.new(0, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = i
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = entry})
        
        local label = Create("TextLabel", {
            Name = "Label",
            Parent = entry,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Font = Enum.Font.Code,
            Text = module.name,
            TextColor3 = Theme.Text,
            TextSize = 13
        })
        
        Create("UIPadding", {
            Parent = entry,
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8)
        })
    end
end

--[[
    ═══════════════════════════════════════════════════════════════
                           WATERMARK
    ═══════════════════════════════════════════════════════════════
]]

local Watermark = Create("Frame", {
    Name = "Watermark",
    Parent = MainGui,
    BackgroundColor3 = Theme.Background,
    BackgroundTransparency = Theme.Transparency,
    Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(0, 0, 0, 26),
    AutomaticSize = Enum.AutomaticSize.X
})
Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Watermark})
Create("UIStroke", {
    Parent = Watermark,
    Color = Theme.Primary,
    Thickness = 1,
    Transparency = 0.5
})

local WatermarkGradient = Create("UIGradient", {
    Parent = Watermark:FindFirstChildOfClass("UIStroke"),
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Primary),
        ColorSequenceKeypoint.new(1, Theme.Secondary)
    })
})

local WatermarkText = Create("TextLabel", {
    Name = "Text",
    Parent = Watermark,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    Font = Enum.Font.Code,
    Text = "",
    TextColor3 = Theme.Text,
    TextSize = 12
})

Create("UIPadding", {
    Parent = Watermark,
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 10)
})

MakeDraggable(Watermark)

-- FPS & Time
local fps = 60
local fpsCount = 0
local lastFpsUpdate = tick()

RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    if tick() - lastFpsUpdate >= 1 then
        fps = fpsCount
        fpsCount = 0
        lastFpsUpdate = tick()
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if WatermarkText and WatermarkText.Parent then
            WatermarkText.Text = "SwiftBara " .. SwiftBara.Version .. " | " .. Player.Name .. " | " .. fps .. " fps | " .. os.date("%H:%M:%S")
        end
        
        -- Animate watermark gradient
        if WatermarkGradient and WatermarkGradient.Parent then
            WatermarkGradient.Rotation = (WatermarkGradient.Rotation + 2) % 360
        end
    end
end)

--[[
    ═══════════════════════════════════════════════════════════════
                         CREATE CATEGORY
    ═══════════════════════════════════════════════════════════════
]]

function SwiftBara:CreateCategory(config)
    config = config or {}
    local name = config.Name or "Category"
    local icon = config.Icon or "⚙"
    local pos = config.Position or UDim2.new(0, 60 + (#self.Categories * 175), 0, 100)
    
    local Category = {
        Name = name,
        Modules = {},
        Expanded = true,
        modulesContainer = nil -- Thêm container để truy cập từ bên ngoài
    }
    
    -- Main frame
    local frame = Create("Frame", {
        Name = name,
        Parent = MainGui,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Theme.Transparency,
        Position = pos,
        Size = UDim2.new(0, 160, 0, 32),
        ClipsDescendants = true
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = frame})
    
    -- Gradient stroke
    local stroke = Create("UIStroke", {
        Parent = frame,
        Thickness = 1.5,
        Transparency = 0.4
    })
    local strokeGradient = Create("UIGradient", {
        Parent = stroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Primary),
            ColorSequenceKeypoint.new(1, Theme.Secondary)
        })
    })
    
    -- Animate stroke gradient
    task.spawn(function()
        while frame and frame.Parent do
            if strokeGradient and strokeGradient.Parent then
                strokeGradient.Rotation = (strokeGradient.Rotation + 2) % 360
            end
            task.wait(0.03)
        end
    end)
    
    -- Header
    local header = Create("Frame", {
        Name = "Header",
        Parent = frame,
        BackgroundColor3 = Theme.Header,
        BackgroundTransparency = 0.2,
        Size = UDim2.new(1, 0, 0, 32)
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = header})
    
    
    -- Icon
    Create("TextLabel", {
        Name = "Icon",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = icon,
        TextColor3 = Theme.Primary,
        TextSize = 14
    })
    
    -- Title
    Create("TextLabel", {
        Name = "Title",
        Parent = header,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -60, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Arrow
    local arrow = Create("TextLabel", {
        Name = "Arrow",
        Parent = header,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = "▼",
        TextColor3 = Theme.TextDim,
        TextSize = 10
    })
    
    -- Header button
    local headerBtn = Create("TextButton", {
        Name = "HeaderBtn",
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = ""
    })
    
    -- Modules container
    local modulesContainer = Create("Frame", {
        Name = "Modules",
        Parent = frame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    Create("UIListLayout", {
        Parent = modulesContainer,
        Padding = UDim.new(0, 2)
    })
    
    Create("UIPadding", {
        Parent = modulesContainer,
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4)
    })
    
    -- Lưu container vào Category
    Category.modulesContainer = modulesContainer
    
    -- Update size
    local function UpdateSize()
        local layout = modulesContainer:FindFirstChildOfClass("UIListLayout")
        if Category.Expanded then
            local h = layout.AbsoluteContentSize.Y + 10
            Tween(frame, {Size = UDim2.new(0, 160, 0, 32 + h)}, 0.2)
            Tween(arrow, {Rotation = 0}, 0.2)
        else
            Tween(frame, {Size = UDim2.new(0, 160, 0, 32)}, 0.2)
            Tween(arrow, {Rotation = -90}, 0.2)
        end
    end
    
    modulesContainer:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSize)
    
    -- Toggle expand
    headerBtn.MouseButton1Click:Connect(function()
        Category.Expanded = not Category.Expanded
        UpdateSize()
    end)
    
    -- Hover
    headerBtn.MouseEnter:Connect(function()
        Tween(header, {BackgroundTransparency = 0}, 0.1)
    end)
    headerBtn.MouseLeave:Connect(function()
        Tween(header, {BackgroundTransparency = 0.2}, 0.1)
    end)
    
    -- FIXED: Make category draggable
    MakeDraggable(frame, headerBtn)
    
    --[[
        ═══════════════════════════════════════════════════════════
                            CREATE MODULE
        ═══════════════════════════════════════════════════════════
    ]]
    
    function Category:CreateModule(config)
        config = config or {}
        local modName = config.Name or "Module"
        local modDefault = config.Default or false
        local modKey = config.Key -- Có thể là nil, Enum.KeyCode, hoặc chuỗi "None"
        local modCallback = config.Callback or function() end
        
        local Module = {
            Name = modName,
            Enabled = false,
            Key = nil, -- Mặc định là nil (None)
            Settings = {},
            Expanded = false,
            keySelectBtn = nil -- Thêm reference để truy cập từ bên ngoài
        }
        
        -- Module frame
        local modFrame = Create("Frame", {
            Name = modName,
            Parent = modulesContainer,
            BackgroundColor3 = Theme.Module,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            ClipsDescendants = true
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = modFrame})
        
        -- Button
        local modBtn = Create("TextButton", {
            Name = "Button",
            Parent = modFrame,
            BackgroundColor3 = Theme.Hover,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 26),
            Text = "",
            AutoButtonColor = false
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = modBtn})
        
        -- Indicator
        local indicator = Create("Frame", {
            Name = "Indicator",
            Parent = modBtn,
            BackgroundColor3 = Theme.Enabled,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 4, 0.5, -8),
            Size = UDim2.new(0, 3, 0, 16)
        })
        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = indicator})
        
        -- Name
        local nameLabel = Create("TextLabel", {
            Name = "Name",
            Parent = modBtn,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(1, -55, 1, 0),
            Font = Enum.Font.Gotham,
            Text = modName,
            TextColor3 = Theme.Disabled,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        -- Keybind Selector Button
        local keySelectBtn = Create("TextButton", {
            Name = "KeySelectBtn",
            Parent = modBtn,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.new(0, 35, 0, 14),
            Font = Enum.Font.Code,
            Text = "[None]",
            TextColor3 = Theme.None,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Right,
            AutoButtonColor = false
        })
        
        -- Lưu reference vào Module
        Module.keySelectBtn = keySelectBtn
        
        -- Settings container
        local settingsContainer = Create("Frame", {
            Name = "Settings",
            Parent = modFrame,
            BackgroundColor3 = Color3.fromRGB(15, 15, 22),
            BackgroundTransparency = 0.2,
            Position = UDim2.new(0, 4, 0, 28),
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false
        })
        Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = settingsContainer})
        Create("UIListLayout", {Parent = settingsContainer, Padding = UDim.new(0, 4)})
        Create("UIPadding", {
            Parent = settingsContainer,
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8)
        })
        
        -- Helper function to check if value is "None"
        local function isNoneValue(value)
            if value == nil then return true end
            if type(value) == "string" then
                return value:lower() == "none"
            end
            return false
        end
        
        -- Helper function to initialize keybind
        local function initializeKeybind()
            if modKey and not isNoneValue(modKey) then
                -- Nếu modKey là Enum.KeyCode
                if typeof(modKey) == "EnumItem" and modKey.EnumType == Enum.KeyCode then
                    Module.Key = modKey
                    keySelectBtn.Text = "[" .. modKey.Name .. "]"
                    Tween(keySelectBtn, {TextColor3 = Theme.TextDim}, 0.2)
                    SwiftBara.Keybinds[modKey] = Module
                end
            else
                -- Mặc định là None
                Module.Key = nil
                keySelectBtn.Text = "[None]"
                Tween(keySelectBtn, {TextColor3 = Theme.None}, 0.2)
            end
        end
        
        -- Khởi tạo keybind
        initializeKeybind()
        
        -- Update state
        local function UpdateState()
            if Module.Enabled then
                Tween(indicator, {BackgroundTransparency = 0}, 0.15)
                Tween(nameLabel, {TextColor3 = Theme.Enabled}, 0.15)
                Tween(modBtn, {BackgroundTransparency = 0.6}, 0.15)
                SwiftBara.EnabledModules[modName] = Module
            else
                Tween(indicator, {BackgroundTransparency = 1}, 0.15)
                Tween(nameLabel, {TextColor3 = Theme.Disabled}, 0.15)
                Tween(modBtn, {BackgroundTransparency = 1}, 0.15)
                SwiftBara.EnabledModules[modName] = nil
            end
            UpdateArrayList()
            modCallback(Module.Enabled)
        end
        
        -- Update module size
        local function UpdateModuleSize()
            if Module.Expanded and #Module.Settings > 0 then
                settingsContainer.Visible = true
                local h = settingsContainer:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y + 12
                Tween(modFrame, {Size = UDim2.new(1, 0, 0, 30 + h)}, 0.2)
            else
                Tween(modFrame, {Size = UDim2.new(1, 0, 0, 26)}, 0.2)
                task.delay(0.2, function()
                    if not Module.Expanded then settingsContainer.Visible = false end
                end)
            end
            UpdateSize()
        end
        
        settingsContainer:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateModuleSize)
        
        -- Click toggle
        modBtn.MouseButton1Click:Connect(function()
            Module.Enabled = not Module.Enabled
            UpdateState()
        end)
        
        -- Right click settings
        modBtn.MouseButton2Click:Connect(function()
            if #Module.Settings > 0 then
                Module.Expanded = not Module.Expanded
                UpdateModuleSize()
            end
        end)
        
        -- Khi nhấn vào nút keybind
        keySelectBtn.MouseButton1Click:Connect(function()
            if SwiftBara.SelectingKeybind then
                -- Đã đang chọn keybind, hủy
                SwiftBara.SelectingKeybind = false
                SwiftBara.SelectedModule = nil
                SwiftBara.KeybindSelectionMode = "SINGLE"
                SwiftBara:Notify("Cancelled keybind selection")
                
                -- Reset màu tất cả nút keybind
                for _, cat in pairs(SwiftBara.Categories) do
                    for _, mod in pairs(cat.Modules) do
                        if mod.keySelectBtn then
                            mod.keySelectBtn.Text = mod.Key and ("[" .. mod.Key.Name .. "]") or "[None]"
                            Tween(mod.keySelectBtn, {TextColor3 = mod.Key and Theme.TextDim or Theme.None}, 0.2)
                        end
                    end
                end
            else
                -- Bắt đầu chọn keybind cho module này
                SwiftBara.SelectingKeybind = true
                SwiftBara.SelectedModule = Module
                SwiftBara.KeybindSelectionMode = "SINGLE"
                SwiftBara:Notify("Press any key to bind to " .. modName .. " (ESC to cancel, Delete for None)")
                
                -- Highlight nút keybind của module này
                keySelectBtn.Text = "[...]"
                Tween(keySelectBtn, {TextColor3 = Theme.Selecting}, 0.2)
            end
        end)
        
        -- Hover effect cho nút keybind
        keySelectBtn.MouseEnter:Connect(function()
            if not SwiftBara.SelectingKeybind then
                Tween(keySelectBtn, {TextColor3 = Module.Key and Theme.Text or Theme.None}, 0.1)
            end
        end)
        
        keySelectBtn.MouseLeave:Connect(function()
            if not SwiftBara.SelectingKeybind and keySelectBtn.TextColor3 ~= Theme.Selecting then
                Tween(keySelectBtn, {TextColor3 = Module.Key and Theme.TextDim or Theme.None}, 0.1)
            end
        end)
        
        -- Hover
        modBtn.MouseEnter:Connect(function()
            if not Module.Enabled then
                Tween(modBtn, {BackgroundTransparency = 0.5}, 0.1)
            end
        end)
        modBtn.MouseLeave:Connect(function()
            if not Module.Enabled then
                Tween(modBtn, {BackgroundTransparency = 1}, 0.1)
            end
        end)
        
        if modDefault then
            Module.Enabled = true
            UpdateState()
        end
        
        --[[
            ═══════════════════════════════════════
                     MODULE SETTINGS
            ═══════════════════════════════════════
        ]]
        
        function Module:AddSlider(cfg)
            cfg = cfg or {}
            local sliderName = cfg.Name or "Slider"
            local min = cfg.Min or 0
            local max = cfg.Max or 100
            local default = cfg.Default or min
            local suffix = cfg.Suffix or ""
            local callback = cfg.Callback or function() end
            local precise = cfg.Precise or false -- Thêm tùy chọn độ chính xác
            
            local Slider = {Value = default}
            table.insert(Module.Settings, Slider)
            
            local sliderFrame = Create("Frame", {
                Name = sliderName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30)
            })
            
            Create("TextLabel", {
                Name = "Label",
                Parent = sliderFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.55, 0, 0, 12),
                Font = Enum.Font.Gotham,
                Text = sliderName,
                TextColor3 = Theme.TextDim,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local valueLabel = Create("TextLabel", {
                Name = "Value",
                Parent = sliderFrame,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0.45, 0, 0, 12),
                Font = Enum.Font.GothamBold,
                Text = tostring(default) .. suffix,
                TextColor3 = Theme.Primary,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right
            })
            
            local sliderBg = Create("Frame", {
                Name = "Bg",
                Parent = sliderFrame,
                BackgroundColor3 = Color3.fromRGB(35, 35, 48),
                Position = UDim2.new(0, 0, 0, 16),
                Size = UDim2.new(1, 0, 0, 10)
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderBg})
            
            local sliderFill = Create("Frame", {
                Name = "Fill",
                Parent = sliderBg,
                BackgroundColor3 = Theme.Primary,
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = sliderFill})
            Create("UIGradient", {
                Parent = sliderFill,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.Primary),
                    ColorSequenceKeypoint.new(1, Theme.Secondary)
                })
            })
            
            local handle = Create("Frame", {
                Name = "Handle",
                Parent = sliderBg,
                BackgroundColor3 = Theme.Text,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                ZIndex = 2
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = handle})
            Create("UIStroke", {Parent = handle, Color = Theme.Primary, Thickness = 2})
            
            local dragging = false
            
            local function update(val)
                val = math.clamp(val, min, max)
                if precise then
                    val = round(val, 2)
                else
                    val = math.floor(val)
                end
                Slider.Value = val
                valueLabel.Text = tostring(val) .. suffix
                local pct = (val - min) / (max - min)
                sliderFill.Size = UDim2.new(pct, 0, 1, 0)
                handle.Position = UDim2.new(pct, 0, 0.5, 0)
                callback(val)
            end
            
            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local pct = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    update(min + (max - min) * pct)
                end
            end)
            
            sliderBg.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local pct = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    update(min + (max - min) * pct)
                end
            end)
            
            function Slider:Set(val) update(val) end
            function Slider:Get() return Slider.Value end
            
            UpdateModuleSize()
            return Slider
        end
        
        function Module:AddToggle(cfg)
            cfg = cfg or {}
            local toggleName = cfg.Name or "Toggle"
            local default = cfg.Default or false
            local callback = cfg.Callback or function() end
            
            local Toggle = {Value = default}
            table.insert(Module.Settings, Toggle)
            
            local toggleFrame = Create("Frame", {
                Name = toggleName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20)
            })
            
            Create("TextLabel", {
                Name = "Label",
                Parent = toggleFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -38, 1, 0),
                Font = Enum.Font.Gotham,
                Text = toggleName,
                TextColor3 = Theme.TextDim,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local toggleBg = Create("Frame", {
                Name = "Bg",
                Parent = toggleFrame,
                BackgroundColor3 = Color3.fromRGB(40, 40, 55),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 30, 0, 14)
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleBg})
            
            local toggleCircle = Create("Frame", {
                Name = "Circle",
                Parent = toggleBg,
                BackgroundColor3 = Theme.TextDim,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 2, 0.5, 0),
                Size = UDim2.new(0, 10, 0, 10)
            })
            Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleCircle})
            
            local function updateToggle(val)
                Toggle.Value = val
                if val then
                    Tween(toggleBg, {BackgroundColor3 = Theme.Primary}, 0.15)
                    Tween(toggleCircle, {Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = Theme.Text}, 0.15)
                else
                    Tween(toggleBg, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}, 0.15)
                    Tween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Theme.TextDim}, 0.15)
                end
                callback(val)
            end
            
            local click = Create("TextButton", {
                Name = "Click",
                Parent = toggleFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })
            
            click.MouseButton1Click:Connect(function()
                updateToggle(not Toggle.Value)
            end)
            
            if default then updateToggle(true) end
            
            function Toggle:Set(val) updateToggle(val) end
            function Toggle:Get() return Toggle.Value end
            
            UpdateModuleSize()
            return Toggle
        end
        
        function Module:AddMode(cfg)
            cfg = cfg or {}
            local modeName = cfg.Name or "Mode"
            local options = cfg.Options or {"A", "B"}
            local default = cfg.Default or options[1]
            local callback = cfg.Callback or function() end
            
            local Mode = {Value = default, Options = options}
            table.insert(Module.Settings, Mode)
            
            local modeFrame = Create("Frame", {
                Name = modeName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20)
            })
            
            Create("TextLabel", {
                Name = "Label",
                Parent = modeFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = modeName,
                TextColor3 = Theme.TextDim,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local modeBtn = Create("TextButton", {
                Name = "Btn",
                Parent = modeFrame,
                BackgroundColor3 = Color3.fromRGB(38, 38, 52),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.55, 0, 0, 16),
                Font = Enum.Font.Gotham,
                Text = default,
                TextColor3 = Theme.Text,
                TextSize = 9,
                AutoButtonColor = false
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = modeBtn})
            
            local idx = tableFind(options, default) or 1
            
            modeBtn.MouseButton1Click:Connect(function()
                idx = idx % #options + 1
                Mode.Value = options[idx]
                modeBtn.Text = options[idx]
                callback(options[idx])
            end)
            
            modeBtn.MouseEnter:Connect(function()
                Tween(modeBtn, {BackgroundColor3 = Theme.Hover}, 0.1)
            end)
            modeBtn.MouseLeave:Connect(function()
                Tween(modeBtn, {BackgroundColor3 = Color3.fromRGB(38, 38, 52)}, 0.1)
            end)
            
            function Mode:Set(val)
                local i = tableFind(options, val)
                if i then
                    idx = i
                    Mode.Value = val
                    modeBtn.Text = val
                    callback(val)
                end
            end
            function Mode:Get() return Mode.Value end
            
            UpdateModuleSize()
            return Mode
        end
        
        --[[
            ═══════════════════════════════════════
                     DROPDOWN MENU
            ═══════════════════════════════════════
        ]]
        
        function Module:AddDropdown(cfg)
            cfg = cfg or {}
            local dropdownName = cfg.Name or "Dropdown"
            local options = cfg.Options or {"Option 1", "Option 2"}
            local default = cfg.Default or options[1]
            local multiple = cfg.Multiple or false
            local callback = cfg.Callback or function() end
            
            local Dropdown = {Value = multiple and {} or default, Options = options, Multiple = multiple}
            table.insert(Module.Settings, Dropdown)
            
            local dropdownFrame = Create("Frame", {
                Name = dropdownName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20)
            })
            
            Create("TextLabel", {
                Name = "Label",
                Parent = dropdownFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = dropdownName,
                TextColor3 = Theme.TextDim,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local dropdownBtn = Create("TextButton", {
                Name = "Btn",
                Parent = dropdownFrame,
                BackgroundColor3 = Color3.fromRGB(38, 38, 52),
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.55, 0, 0, 16),
                Font = Enum.Font.Gotham,
                Text = multiple and "Select..." or default,
                TextColor3 = Theme.Text,
                TextSize = 9,
                AutoButtonColor = false
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dropdownBtn})
            
            -- Dropdown container (sẽ được tạo khi mở)
            local dropdownContainer = nil
            
            local function updateButtonText()
                if multiple then
                    if #Dropdown.Value > 0 then
                        local text = ""
                        for i, v in ipairs(Dropdown.Value) do
                            if i <= 2 then
                                text = text .. (i > 1 and ", " or "") .. v
                            end
                        end
                        if #Dropdown.Value > 2 then
                            text = text .. " +" .. (#Dropdown.Value - 2)
                        end
                        dropdownBtn.Text = text
                    else
                        dropdownBtn.Text = "Select..."
                    end
                else
                    dropdownBtn.Text = Dropdown.Value
                end
            end
            
            local function toggleDropdown()
                if dropdownContainer and dropdownContainer.Parent then
                    -- Đóng dropdown
                    Tween(dropdownContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    task.delay(0.2, function()
                        if dropdownContainer and dropdownContainer.Parent then
                            dropdownContainer:Destroy()
                            dropdownContainer = nil
                        end
                    end)
                else
                    -- Đóng tất cả dropdown khác
                    CloseAllDropdowns()
                    
                    -- Tạo dropdown container
                    dropdownContainer = Create("Frame", {
                        Name = "DropdownContainer",
                        Parent = dropdownFrame,
                        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
                        BackgroundTransparency = 0.1,
                        Position = UDim2.new(0, 0, 1, 2),
                        Size = UDim2.new(1, 0, 0, 0),
                        ClipsDescendants = true,
                        ZIndex = 100
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dropdownContainer})
                    Create("UIStroke", {
                        Parent = dropdownContainer,
                        Color = Theme.Primary,
                        Thickness = 1,
                        Transparency = 0.3
                    })
                    
                    local listLayout = Create("UIListLayout", {
                        Parent = dropdownContainer,
                        Padding = UDim.new(0, 2)
                    })
                    
                    Create("UIPadding", {
                        Parent = dropdownContainer,
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 4),
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4)
                    })
                    
                    -- Tạo các option
                    for _, option in ipairs(options) do
                        local optionFrame = Create("Frame", {
                            Name = option,
                            Parent = dropdownContainer,
                            BackgroundColor3 = Color3.fromRGB(30, 30, 42),
                            Size = UDim2.new(1, 0, 0, 18),
                            ZIndex = 101
                        })
                        Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = optionFrame})
                        
                        local optionBtn = Create("TextButton", {
                            Name = "Btn",
                            Parent = optionFrame,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Font = Enum.Font.Gotham,
                            Text = option,
                            TextColor3 = Theme.TextDim,
                            TextSize = 9,
                            AutoButtonColor = false,
                            ZIndex = 102
                        })
                        
                        local check = Create("Frame", {
                            Name = "Check",
                            Parent = optionFrame,
                            BackgroundColor3 = Theme.Primary,
                            BackgroundTransparency = 0.8,
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -4, 0.5, 0),
                            Size = UDim2.new(0, 10, 0, 10),
                            Visible = false,
                            ZIndex = 102
                        })
                        Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = check})
                        
                        -- Kiểm tra xem option có được chọn không
                        if multiple then
                            if tableFind(Dropdown.Value, option) then
                                check.Visible = true
                                optionBtn.TextColor3 = Theme.Text
                            end
                        else
                            if Dropdown.Value == option then
                                check.Visible = true
                                optionBtn.TextColor3 = Theme.Text
                            end
                        end
                        
                        optionBtn.MouseButton1Click:Connect(function()
                            if multiple then
                                local idx = tableFind(Dropdown.Value, option)
                                if idx then
                                    table.remove(Dropdown.Value, idx)
                                    check.Visible = false
                                    optionBtn.TextColor3 = Theme.TextDim
                                else
                                    table.insert(Dropdown.Value, option)
                                    check.Visible = true
                                    optionBtn.TextColor3 = Theme.Text
                                end
                            else
                                Dropdown.Value = option
                                -- Cập nhật tất cả các option
                                for _, child in pairs(dropdownContainer:GetChildren()) do
                                    if child:IsA("Frame") and child.Name ~= "DropdownContainer" then
                                        child.Check.Visible = (child.Name == option)
                                        child.Btn.TextColor3 = (child.Name == option) and Theme.Text or Theme.TextDim
                                    end
                                end
                            end
                            
                            updateButtonText()
                            callback(Dropdown.Value)
                        end)
                        
                        optionBtn.MouseEnter:Connect(function()
                            Tween(optionFrame, {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}, 0.1)
                        end)
                        
                        optionBtn.MouseLeave:Connect(function()
                            Tween(optionFrame, {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}, 0.1)
                        end)
                    end
                    
                    -- Tính toán kích thước
                    local totalHeight = #options * 20 + 8
                    Tween(dropdownContainer, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.2)
                    
                    -- Thêm vào danh sách dropdown mở
                    table.insert(SwiftBara.OpenDropdowns, dropdownContainer)
                end
            end
            
            dropdownBtn.MouseButton1Click:Connect(function()
                toggleDropdown()
            end)
            
            dropdownBtn.MouseEnter:Connect(function()
                Tween(dropdownBtn, {BackgroundColor3 = Theme.Hover}, 0.1)
            end)
            
            dropdownBtn.MouseLeave:Connect(function()
                Tween(dropdownBtn, {BackgroundColor3 = Color3.fromRGB(38, 38, 52)}, 0.1)
            end)
            
            -- Khởi tạo text cho button
            updateButtonText()
            
            function Dropdown:Set(val)
                if multiple then
                    if type(val) == "table" then
                        Dropdown.Value = {}
                        for _, v in ipairs(val) do
                            if tableFind(options, v) then
                                table.insert(Dropdown.Value, v)
                            end
                        end
                    end
                else
                    if tableFind(options, val) then
                        Dropdown.Value = val
                    end
                end
                updateButtonText()
                callback(Dropdown.Value)
            end
            
            function Dropdown:Get() return Dropdown.Value end
            function Dropdown:Refresh(newOptions)
                Dropdown.Options = newOptions or Dropdown.Options
                if not multiple and not tableFind(Dropdown.Options, Dropdown.Value) then
                    Dropdown.Value = Dropdown.Options[1]
                end
                updateButtonText()
            end
            
            UpdateModuleSize()
            return Dropdown
        end
        
        --[[
            ═══════════════════════════════════════
                     BUTTON
            ═══════════════════════════════════════
        ]]
        
        function Module:AddButton(cfg)
            cfg = cfg or {}
            local buttonName = cfg.Name or "Button"
            local callback = cfg.Callback or function() end
            local confirm = cfg.Confirm or false -- Yêu cầu xác nhận
            
            local Button = {Callback = callback}
            table.insert(Module.Settings, Button)
            
            local buttonFrame = Create("Frame", {
                Name = buttonName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24)
            })
            
            local buttonBtn = Create("TextButton", {
                Name = "Btn",
                Parent = buttonFrame,
                BackgroundColor3 = Theme.Button,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = buttonName,
                TextColor3 = Theme.Text,
                TextSize = 10,
                AutoButtonColor = false
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = buttonBtn})
            Create("UIGradient", {
                Parent = buttonBtn,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.Primary),
                    ColorSequenceKeypoint.new(1, Theme.Secondary)
                }),
                Transparency = NumberSequence.new(0.7)
            })
            
            local confirmFrame = nil
            
            local function executeCallback()
                if confirm then
                    -- Tạo khung xác nhận
                    confirmFrame = Create("Frame", {
                        Name = "ConfirmFrame",
                        Parent = buttonFrame,
                        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
                        BackgroundTransparency = 0.1,
                        Position = UDim2.new(0, 0, 0, 24),
                        Size = UDim2.new(1, 0, 0, 0),
                        ClipsDescendants = true,
                        ZIndex = 100
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = confirmFrame})
                    Create("UIStroke", {
                        Parent = confirmFrame,
                        Color = Theme.Warning,
                        Thickness = 1
                    })
                    
                    Create("TextLabel", {
                        Name = "Text",
                        Parent = confirmFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = Enum.Font.Gotham,
                        Text = "Are you sure?",
                        TextColor3 = Theme.Warning,
                        TextSize = 9,
                        ZIndex = 101
                    })
                    
                    local confirmBtn = Create("TextButton", {
                        Name = "ConfirmBtn",
                        Parent = confirmFrame,
                        BackgroundColor3 = Theme.Error,
                        Position = UDim2.new(0, 4, 0, 22),
                        Size = UDim2.new(0.48, -2, 0, 16),
                        Font = Enum.Font.GothamBold,
                        Text = "YES",
                        TextColor3 = Theme.Text,
                        TextSize = 9,
                        AutoButtonColor = false,
                        ZIndex = 101
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = confirmBtn})
                    
                    local cancelBtn = Create("TextButton", {
                        Name = "CancelBtn",
                        Parent = confirmFrame,
                        BackgroundColor3 = Theme.Button,
                        Position = UDim2.new(0.52, 2, 0, 22),
                        Size = UDim2.new(0.48, -2, 0, 16),
                        Font = Enum.Font.Gotham,
                        Text = "NO",
                        TextColor3 = Theme.TextDim,
                        TextSize = 9,
                        AutoButtonColor = false,
                        ZIndex = 101
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = cancelBtn})
                    
                    -- Mở khung xác nhận
                    Tween(confirmFrame, {Size = UDim2.new(1, 0, 0, 42)}, 0.2)
                    
                    confirmBtn.MouseButton1Click:Connect(function()
                        callback()
                        if confirmFrame and confirmFrame.Parent then
                            Tween(confirmFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                            task.delay(0.2, function()
                                if confirmFrame and confirmFrame.Parent then
                                    confirmFrame:Destroy()
                                end
                            end)
                        end
                    end)
                    
                    cancelBtn.MouseButton1Click:Connect(function()
                        if confirmFrame and confirmFrame.Parent then
                            Tween(confirmFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                            task.delay(0.2, function()
                                if confirmFrame and confirmFrame.Parent then
                                    confirmFrame:Destroy()
                                end
                            end)
                        end
                    end)
                    
                    confirmBtn.MouseEnter:Connect(function()
                        Tween(confirmBtn, {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}, 0.1)
                    end)
                    
                    confirmBtn.MouseLeave:Connect(function()
                        Tween(confirmBtn, {BackgroundColor3 = Theme.Error}, 0.1)
                    end)
                    
                    cancelBtn.MouseEnter:Connect(function()
                        Tween(cancelBtn, {BackgroundColor3 = Theme.Hover}, 0.1)
                    end)
                    
                    cancelBtn.MouseLeave:Connect(function()
                        Tween(cancelBtn, {BackgroundColor3 = Theme.Button}, 0.1)
                    end)
                else
                    callback()
                end
            end
            
            buttonBtn.MouseButton1Click:Connect(function()
                executeCallback()
            end)
            
            buttonBtn.MouseEnter:Connect(function()
                Tween(buttonBtn, {BackgroundTransparency = 0.4}, 0.1)
            end)
            
            buttonBtn.MouseLeave:Connect(function()
                Tween(buttonBtn, {BackgroundTransparency = 0.7}, 0.1)
            end)
            
            function Button:Fire()
                executeCallback()
            end
            
            UpdateModuleSize()
            return Button
        end
        
        --[[
            ═══════════════════════════════════════
                     COLOR PICKER
            ═══════════════════════════════════════
        ]]
        
        function Module:AddColorPicker(cfg)
            cfg = cfg or {}
            local pickerName = cfg.Name or "Color"
            local default = cfg.Default or Color3.fromRGB(255, 255, 255)
            local callback = cfg.Callback or function() end
            local enableAlpha = cfg.Alpha or false
            
            local ColorPicker = {Value = default, Alpha = enableAlpha and 1 or nil}
            table.insert(Module.Settings, ColorPicker)
            
            local pickerFrame = Create("Frame", {
                Name = pickerName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20)
            })
            
            Create("TextLabel", {
                Name = "Label",
                Parent = pickerFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = pickerName,
                TextColor3 = Theme.TextDim,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local colorPreview = Create("Frame", {
                Name = "Preview",
                Parent = pickerFrame,
                BackgroundColor3 = default,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0.55, 0, 0, 16)
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = colorPreview})
            Create("UIStroke", {
                Parent = colorPreview,
                Color = Theme.TextDim,
                Thickness = 1
            })
            
            local pickerContainer = nil
            
            local function updateColor(newColor, newAlpha)
                ColorPicker.Value = newColor or ColorPicker.Value
                if enableAlpha then
                    ColorPicker.Alpha = newAlpha or ColorPicker.Alpha
                    colorPreview.BackgroundColor3 = ColorPicker.Value
                    colorPreview.BackgroundTransparency = 1 - (ColorPicker.Alpha or 1)
                else
                    colorPreview.BackgroundColor3 = ColorPicker.Value
                end
                callback(enableAlpha and {Color = ColorPicker.Value, Alpha = ColorPicker.Alpha} or ColorPicker.Value)
            end
            
            local function toggleColorPicker()
                if pickerContainer and pickerContainer.Parent then
                    -- Đóng color picker
                    Tween(pickerContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    task.delay(0.2, function()
                        if pickerContainer and pickerContainer.Parent then
                            pickerContainer:Destroy()
                            pickerContainer = nil
                            
                            -- Xóa khỏi danh sách
                            local idx = tableFind(SwiftBara.ColorPickers, pickerContainer)
                            if idx then
                                table.remove(SwiftBara.ColorPickers, idx)
                            end
                        end
                    end)
                else
                    -- Đóng tất cả color picker khác
                    CloseAllColorPickers()
                    
                    -- Tạo color picker container
                    pickerContainer = Create("Frame", {
                        Name = "ColorPickerContainer",
                        Parent = pickerFrame,
                        BackgroundColor3 = Color3.fromRGB(20, 20, 30),
                        BackgroundTransparency = 0.1,
                        Position = UDim2.new(0, 0, 1, 2),
                        Size = UDim2.new(1, 0, 0, 0),
                        ClipsDescendants = true,
                        ZIndex = 100
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = pickerContainer})
                    Create("UIStroke", {
                        Parent = pickerContainer,
                        Color = Theme.Primary,
                        Thickness = 1,
                        Transparency = 0.3
                    })
                    
                    -- Thêm vào danh sách
                    table.insert(SwiftBara.ColorPickers, pickerContainer)
                    
                    local contentSize = enableAlpha and 130 or 110
                    
                    -- Rainbow gradient cho hue
                    local hueGradient = Create("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                        })
                    })
                    
                    -- Hue slider
                    local hueFrame = Create("Frame", {
                        Name = "HueFrame",
                        Parent = pickerContainer,
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        Position = UDim2.new(0, 8, 0, 8),
                        Size = UDim2.new(1, -16, 0, 12),
                        ZIndex = 101
                    })
                    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = hueFrame})
                    hueGradient.Parent = hueFrame
                    
                    -- Chuyển màu hiện tại sang HSV
                    local h, s, v = ColorPicker.Value:ToHSV()
                    
                    local hueHandle = Create("Frame", {
                        Name = "HueHandle",
                        Parent = hueFrame,
                        BackgroundColor3 = Theme.Text,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(h, 0, 0.5, 0),
                        Size = UDim2.new(0, 16, 0, 16),
                        ZIndex = 102
                    })
                    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = hueHandle})
                    Create("UIStroke", {Parent = hueHandle, Color = Theme.Background, Thickness = 2})
                    
                    -- Saturation/Value picker
                    local svFrame = Create("Frame", {
                        Name = "SVFrame",
                        Parent = pickerContainer,
                        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                        Position = UDim2.new(0, 8, 0, 26),
                        Size = UDim2.new(1, -16, 0, 60),
                        ZIndex = 101
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = svFrame})
                    
                    local svGradient1 = Create("UIGradient", {
                        Parent = svFrame,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
                        }),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1)
                        }),
                        Rotation = 0
                    })
                    
                    local svGradient2 = Create("UIGradient", {
                        Parent = svFrame,
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
                            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                        }),
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(1, 0)
                        }),
                        Rotation = 90
                    })
                    
                    local svHandle = Create("Frame", {
                        Name = "SVHandle",
                        Parent = svFrame,
                        BackgroundColor3 = Theme.Text,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(s, 0, 1 - v, 0),
                        Size = UDim2.new(0, 14, 0, 14),
                        ZIndex = 102
                    })
                    Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = svHandle})
                    Create("UIStroke", {Parent = svHandle, Color = Theme.Background, Thickness = 2})
                    
                    -- Alpha slider (nếu bật)
                    local alphaFrame = nil
                    local alphaHandle = nil
                    
                    if enableAlpha then
                        alphaFrame = Create("Frame", {
                            Name = "AlphaFrame",
                            Parent = pickerContainer,
                            BackgroundColor3 = Color3.new(1, 1, 1),
                            Position = UDim2.new(0, 8, 0, 92),
                            Size = UDim2.new(1, -16, 0, 12),
                            ZIndex = 101
                        })
                        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = alphaFrame})
                        
                        local alphaGradient = Create("UIGradient", {
                            Parent = alphaFrame,
                            Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, ColorPicker.Value),
                                ColorSequenceKeypoint.new(1, ColorPicker.Value)
                            }),
                            Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(1, 0)
                            })
                        })
                        
                        alphaHandle = Create("Frame", {
                            Name = "AlphaHandle",
                            Parent = alphaFrame,
                            BackgroundColor3 = Theme.Text,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(ColorPicker.Alpha or 1, 0, 0.5, 0),
                            Size = UDim2.new(0, 16, 0, 16),
                            ZIndex = 102
                        })
                        Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = alphaHandle})
                        Create("UIStroke", {Parent = alphaHandle, Color = Theme.Background, Thickness = 2})
                    end
                    
                    -- Hex input
                    local hexFrame = Create("Frame", {
                        Name = "HexFrame",
                        Parent = pickerContainer,
                        BackgroundColor3 = Color3.fromRGB(30, 30, 42),
                        Position = UDim2.new(0, 8, 0, enableAlpha and 110 or 92),
                        Size = UDim2.new(1, -16, 0, 20),
                        ZIndex = 101
                    })
                    Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = hexFrame})
                    
                    local hexBox = Create("TextBox", {
                        Name = "HexBox",
                        Parent = hexFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -8, 1, 0),
                        Position = UDim2.new(0, 4, 0, 0),
                        Font = Enum.Font.Code,
                        Text = "#" .. string.format("%02X%02X%02X", 
                            math.floor(ColorPicker.Value.R * 255),
                            math.floor(ColorPicker.Value.G * 255),
                            math.floor(ColorPicker.Value.B * 255)),
                        TextColor3 = Theme.Text,
                        TextSize = 10,
                        ClearTextOnFocus = false,
                        ZIndex = 102
                    })
                    
                    -- Function to update color from HSV
                    local function updateFromHSV(newH, newS, newV)
                        local newColor = Color3.fromHSV(newH, newS, newV)
                        updateColor(newColor)
                        
                        -- Update SV frame background
                        svFrame.BackgroundColor3 = Color3.fromHSV(newH, 1, 1)
                        
                        -- Update hex
                        hexBox.Text = "#" .. string.format("%02X%02X%02X", 
                            math.floor(newColor.R * 255),
                            math.floor(newColor.G * 255),
                            math.floor(newColor.B * 255))
                    end
                    
                    -- Hue dragging
                    local hueDragging = false
                    hueFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDragging = true
                            local pct = math.clamp((input.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
                            h = pct
                            hueHandle.Position = UDim2.new(pct, 0, 0.5, 0)
                            updateFromHSV(h, s, v)
                        end
                    end)
                    
                    hueFrame.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDragging = false
                        end
                    end)
                    
                    -- SV dragging
                    local svDragging = false
                    svFrame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            svDragging = true
                            local x = math.clamp((input.Position.X - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1)
                            local y = math.clamp((input.Position.Y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1)
                            s = x
                            v = 1 - y
                            svHandle.Position = UDim2.new(x, 0, y, 0)
                            updateFromHSV(h, s, v)
                        end
                    end)
                    
                    svFrame.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            svDragging = false
                        end
                    end)
                    
                    -- Alpha dragging
                    local alphaDragging = false
                    if enableAlpha and alphaFrame then
                        alphaFrame.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                alphaDragging = true
                                local pct = math.clamp((input.Position.X - alphaFrame.AbsolutePosition.X) / alphaFrame.AbsoluteSize.X, 0, 1)
                                ColorPicker.Alpha = pct
                                alphaHandle.Position = UDim2.new(pct, 0, 0.5, 0)
                                updateColor(nil, pct)
                            end
                        end)
                        
                        alphaFrame.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                alphaDragging = false
                            end
                        end)
                    end
                    
                    -- Input changed
                    UserInputService.InputChanged:Connect(function(input)
                        if hueDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local pct = math.clamp((input.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
                            h = pct
                            hueHandle.Position = UDim2.new(pct, 0, 0.5, 0)
                            updateFromHSV(h, s, v)
                        elseif svDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local x = math.clamp((input.Position.X - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1)
                            local y = math.clamp((input.Position.Y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1)
                            s = x
                            v = 1 - y
                            svHandle.Position = UDim2.new(x, 0, y, 0)
                            updateFromHSV(h, s, v)
                        elseif alphaDragging and enableAlpha and alphaFrame and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local pct = math.clamp((input.Position.X - alphaFrame.AbsolutePosition.X) / alphaFrame.AbsoluteSize.X, 0, 1)
                            ColorPicker.Alpha = pct
                            alphaHandle.Position = UDim2.new(pct, 0, 0.5, 0)
                            updateColor(nil, pct)
                        end
                    end)
                    
                    -- Hex input
                    hexBox.FocusLost:Connect(function(enterPressed)
                        if enterPressed then
                            local hex = hexBox.Text:gsub("#", "")
                            if #hex == 6 then
                                local r = tonumber(hex:sub(1, 2), 16) or 255
                                local g = tonumber(hex:sub(3, 4), 16) or 255
                                local b = tonumber(hex:sub(5, 6), 16) or 255
                                local newColor = Color3.fromRGB(r, g, b)
                                local newH, newS, newV = newColor:ToHSV()
                                h, s, v = newH, newS, newV
                                
                                hueHandle.Position = UDim2.new(h, 0, 0.5, 0)
                                svHandle.Position = UDim2.new(s, 0, 1 - v, 0)
                                svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                                
                                updateColor(newColor)
                            end
                        end
                    end)
                    
                    -- Mở color picker
                    Tween(pickerContainer, {Size = UDim2.new(1, 0, 0, contentSize)}, 0.2)
                end
            end
            
            colorPreview.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    toggleColorPicker()
                end
            end)
            
            function ColorPicker:Set(color, alpha)
                if type(color) == "table" and color.Color then
                    updateColor(color.Color, color.Alpha)
                else
                    updateColor(color, alpha)
                end
            end
            
            function ColorPicker:Get()
                if enableAlpha then
                    return {Color = ColorPicker.Value, Alpha = ColorPicker.Alpha}
                else
                    return ColorPicker.Value
                end
            end
            
            UpdateModuleSize()
            return ColorPicker
        end
        
        --[[
            ═══════════════════════════════════════
                     TEXTBOX
            ═══════════════════════════════════════
        ]]
        
        function Module:AddTextBox(cfg)
            cfg = cfg or {}
            local textboxName = cfg.Name or "Text"
            local default = cfg.Default or ""
            local placeholder = cfg.Placeholder or "Type here..."
            local callback = cfg.Callback or function() end
            
            local TextBox = {Value = default}
            table.insert(Module.Settings, TextBox)
            
            local textboxFrame = Create("Frame", {
                Name = textboxName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30)
            })
            
            Create("TextLabel", {
                Name = "Label",
                Parent = textboxFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 12),
                Font = Enum.Font.Gotham,
                Text = textboxName,
                TextColor3 = Theme.TextDim,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local inputFrame = Create("Frame", {
                Name = "InputFrame",
                Parent = textboxFrame,
                BackgroundColor3 = Color3.fromRGB(30, 30, 42),
                Position = UDim2.new(0, 0, 0, 16),
                Size = UDim2.new(1, 0, 0, 14)
            })
            Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = inputFrame})
            
            local textBox = Create("TextBox", {
                Name = "TextBox",
                Parent = inputFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -8, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
                Font = Enum.Font.Gotham,
                Text = default,
                PlaceholderText = placeholder,
                TextColor3 = Theme.Text,
                PlaceholderColor3 = Theme.TextDim,
                TextSize = 10,
                ClearTextOnFocus = false
            })
            
            textBox.FocusLost:Connect(function(enterPressed)
                TextBox.Value = textBox.Text
                callback(textBox.Text, enterPressed)
            end)
            
            function TextBox:Set(val)
                textBox.Text = tostring(val)
                TextBox.Value = tostring(val)
                callback(tostring(val))
            end
            
            function TextBox:Get() return TextBox.Value end
            
            UpdateModuleSize()
            return TextBox
        end
        
        --[[
            ═══════════════════════════════════════
                     LABEL
            ═══════════════════════════════════════
        ]]
        
        function Module:AddLabel(cfg)
            cfg = cfg or {}
            local labelName = cfg.Name or "Label"
            local text = cfg.Text or ""
            local color = cfg.Color or Theme.TextDim
            
            local Label = {Value = text}
            table.insert(Module.Settings, Label)
            
            local labelFrame = Create("Frame", {
                Name = labelName,
                Parent = settingsContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 15)
            })
            
            local labelText = Create("TextLabel", {
                Name = "LabelText",
                Parent = labelFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = color,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            function Label:Set(newText, newColor)
                labelText.Text = newText or text
                if newColor then
                    labelText.TextColor3 = newColor
                end
                Label.Value = newText or text
            end
            
            function Label:Get() return Label.Value end
            
            UpdateModuleSize()
            return Label
        end
        
        --[[
            ═══════════════════════════════════════
                     BINDABLE SETTINGS
            ═══════════════════════════════════════
        ]]
        
        function Module:SetKey(key)
            -- Xóa keybind cũ
            if Module.Key then 
                SwiftBara.Keybinds[Module.Key] = nil 
            end
            
            -- Cập nhật keybind mới
            Module.Key = key
            
            if key and not isNoneValue(key) then
                -- Nếu có keybind mới và không phải là None
                keySelectBtn.Text = "[" .. key.Name .. "]"
                Tween(keySelectBtn, {TextColor3 = Theme.TextDim}, 0.2)
                SwiftBara.Keybinds[key] = Module
                SwiftBara:Notify("Bound " .. modName .. " to [" .. key.Name .. "]")
            else
                -- Nếu xóa keybind (None)
                Module.Key = nil
                keySelectBtn.Text = "[None]"
                Tween(keySelectBtn, {TextColor3 = Theme.None}, 0.2)
                SwiftBara:Notify("Removed keybind from " .. modName)
            end
        end
        
        function Module:Toggle()
            Module.Enabled = not Module.Enabled
            UpdateState()
        end
        
        function Module:Set(val)
            Module.Enabled = val
            UpdateState()
        end
        
        function Module:Get() return Module.Enabled end
        
        table.insert(Category.Modules, Module)
        UpdateSize()
        return Module
    end
    
    table.insert(self.Categories, Category)
    return Category
end

--[[
    ═══════════════════════════════════════════════════════════════
                         KEYBIND HANDLER
    ═══════════════════════════════════════════════════════════════
]]

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- Toggle GUI
    if input.KeyCode == SwiftBara.ToggleKey then
        SwiftBara.GUIVisible = not SwiftBara.GUIVisible
        MainGui.Enabled = SwiftBara.GUIVisible
    end
    
    -- Hotkey Ctrl+R để bắt đầu chọn keybind cho tất cả module
    if input.KeyCode == Enum.KeyCode.R then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            if not SwiftBara.SelectingKeybind then
                SwiftBara.SelectingKeybind = true
                SwiftBara.KeybindSelectionMode = "ALL"
                SwiftBara:Notify("Select a module's keybind button, then press any key (ESC to cancel, Delete for None)")
                return
            end
        end
    end
    
    -- Đóng tất cả dropdown và color picker khi click ra ngoài
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        CloseAllDropdowns()
        CloseAllColorPickers()
    end
    
    -- Nếu đang ở chế độ chọn keybind
    if SwiftBara.SelectingKeybind and SwiftBara.SelectedModule then
        if input.KeyCode == Enum.KeyCode.Escape then
            -- Hủy chọn keybind
            SwiftBara.SelectingKeybind = false
            SwiftBara.SelectedModule = nil
            SwiftBara.KeybindSelectionMode = "SINGLE"
            SwiftBara:Notify("Cancelled keybind selection")
            
            -- Reset tất cả nút keybind
            for _, cat in pairs(SwiftBara.Categories) do
                for _, mod in pairs(cat.Modules) do
                    if mod.keySelectBtn then
                        mod.keySelectBtn.Text = mod.Key and ("[" .. mod.Key.Name .. "]") or "[None]"
                        Tween(mod.keySelectBtn, {TextColor3 = mod.Key and Theme.TextDim or Theme.None}, 0.2)
                    end
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
            -- Xóa keybind (chuyển về None)
            local module = SwiftBara.SelectedModule
            if module then
                module:SetKey(nil)
            end
            
            -- Tắt chế độ chọn keybind
            SwiftBara.SelectingKeybind = false
            SwiftBara.SelectedModule = nil
            SwiftBara.KeybindSelectionMode = "SINGLE"
        else
            -- Gán keybind mới cho module đã chọn
            local module = SwiftBara.SelectedModule
            if module then
                module:SetKey(input.KeyCode)
            end
            
            -- Tắt chế độ chọn keybind
            SwiftBara.SelectingKeybind = false
            SwiftBara.SelectedModule = nil
            SwiftBara.KeybindSelectionMode = "SINGLE"
        end
        return
    end
    
    -- Kích hoạt module bằng keybind (chỉ khi không phải là phím Delete/Escape)
    if input.KeyCode ~= Enum.KeyCode.Delete and input.KeyCode ~= Enum.KeyCode.Backspace then
        local mod = SwiftBara.Keybinds[input.KeyCode]
        if mod and mod.Toggle then 
            mod:Toggle() 
        end
    end
end)

-- Hiệu ứng nhấp nháy khi đang chọn keybind
task.spawn(function()
    while task.wait(0.5) do
        if SwiftBara.SelectingKeybind then
            for _, cat in pairs(SwiftBara.Categories) do
                for _, mod in pairs(cat.Modules) do
                    if mod.keySelectBtn then
                        if mod == SwiftBara.SelectedModule then
                            mod.keySelectBtn.Text = "[...]"
                            Tween(mod.keySelectBtn, {TextColor3 = Theme.Selecting}, 0.2)
                        elseif SwiftBara.KeybindSelectionMode == "ALL" then
                            -- Nhấp nháy cho tất cả khi ở chế độ ALL
                            if mod.keySelectBtn.Text == "[...]" then
                                mod.keySelectBtn.Text = mod.Key and ("[" .. mod.Key.Name .. "]") or "[None]"
                                Tween(mod.keySelectBtn, {TextColor3 = mod.Key and Theme.TextDim or Theme.None}, 0.2)
                            else
                                mod.keySelectBtn.Text = "[...]"
                                Tween(mod.keySelectBtn, {TextColor3 = Theme.Selecting}, 0.2)
                            end
                        end
                    end
                end
            end
        end
    end
end)

--[[
    ═══════════════════════════════════════════════════════════════
                          NOTIFICATION
    ═══════════════════════════════════════════════════════════════
]]

function SwiftBara:Notify(msg, dur)
    dur = dur or 3
    
    local notif = Create("Frame", {
        Name = "Notif",
        Parent = MainGui,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = Theme.Transparency,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 50),
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = notif})
    local nStroke = Create("UIStroke", {Parent = notif, Thickness = 1, Transparency = 0.4})
    Create("UIGradient", {
        Parent = nStroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Primary),
            ColorSequenceKeypoint.new(1, Theme.Secondary)
        })
    })
    
    Create("TextLabel", {
        Name = "Text",
        Parent = notif,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.Gotham,
        Text = msg,
        TextColor3 = Theme.Text,
        TextSize = 12
    })
    
    Create("UIPadding", {
        Parent = notif,
        PaddingLeft = UDim.new(0, 14),
        PaddingRight = UDim.new(0, 14)
    })
    
    Tween(notif, {Position = UDim2.new(0.5, 0, 1, -16)}, 0.3)
    
    task.delay(dur, function()
        Tween(notif, {Position = UDim2.new(0.5, 0, 1, 50), BackgroundTransparency = 1}, 0.3)
        task.wait(0.35)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

--[[
    ═══════════════════════════════════════════════════════════════
                          CONFIG SAVING
    ═══════════════════════════════════════════════════════════════
]]

function SwiftBara:SaveConfig(name)
    local config = {
        Version = self.Version,
        Categories = {},
        Keybinds = {},
        ModuleStates = {}
    }
    
    -- Lưu trạng thái module
    for _, category in pairs(self.Categories) do
        for _, module in pairs(category.Modules) do
            config.ModuleStates[module.Name] = {
                Enabled = module.Enabled,
                Key = module.Key and module.Key.Name or nil,
                Settings = {}
            }
            
            -- Lưu settings
            for _, setting in pairs(module.Settings) do
                if setting.Value ~= nil then
                    if typeof(setting.Value) == "Color3" then
                        config.ModuleStates[module.Name].Settings[setting.Name] = {
                            Color = {setting.Value.R, setting.Value.G, setting.Value.B},
                            Alpha = setting.Alpha
                        }
                    else
                        config.ModuleStates[module.Name].Settings[setting.Name] = setting.Value
                    end
                end
            end
        end
    end
    
    -- Lưu keybinds
    for key, module in pairs(self.Keybinds) do
        config.Keybinds[key.Name] = module.Name
    end
    
    -- Tạo JSON
    local json = HttpService:JSONEncode(config)
    
    -- Lưu (ở đây có thể lưu vào DataStore hoặc file)
    self:Notify("Config '" .. name .. "' saved!", 2)
    print("[SwiftBara] Config saved:", name)
    return json
end

function SwiftBara:LoadConfig(json)
    local success, config = pcall(function()
        return HttpService:JSONDecode(json)
    end)
    
    if success and config then
        -- Tải trạng thái module
        for moduleName, moduleData in pairs(config.ModuleStates) do
            -- Tìm module
            for _, category in pairs(self.Categories) do
                for _, module in pairs(category.Modules) do
                    if module.Name == moduleName then
                        -- Tải trạng thái
                        if moduleData.Enabled ~= nil then
                            module:Set(moduleData.Enabled)
                        end
                        
                        -- Tải keybind
                        if moduleData.Key then
                            local keyCode = Enum.KeyCode[moduleData.Key]
                            if keyCode then
                                module:SetKey(keyCode)
                            end
                        end
                        
                        -- Tải settings
                        for settingName, settingValue in pairs(moduleData.Settings) do
                            -- Tìm setting trong module
                            for _, setting in pairs(module.Settings) do
                                if tostring(setting) == settingName then
                                    if setting.Set then
                                        if type(settingValue) == "table" and settingValue.Color then
                                            -- Color picker với alpha
                                            setting:Set({
                                                Color = Color3.new(unpack(settingValue.Color)),
                                                Alpha = settingValue.Alpha
                                            })
                                        else
                                            setting:Set(settingValue)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        self:Notify("Config loaded successfully!", 2)
        return true
    else
        self:Notify("Failed to load config!", 2)
        return false
    end
end

task.delay(0.3, function()
    SwiftBara:Notify("SwiftBara v" .. SwiftBara.Version .. " loaded! Press RightShift to toggle", 4)
end)

print("[SwiftBara] Client v" .. SwiftBara.Version .. " loaded!")

return SwiftBara

