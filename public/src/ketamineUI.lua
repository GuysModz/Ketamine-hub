--// Ketamine Hub UI Engine
--// A full-scale, weaponized UI Library for Roblox Exploits

local Ketamine = {}
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local COLORS = {
    bg_dark       = Color3.fromRGB(12, 10, 18),
    bg_panel      = Color3.fromRGB(18, 14, 28),
    bg_input      = Color3.fromRGB(28, 22, 42),
    purple_main   = Color3.fromRGB(140, 60, 220),
    purple_light  = Color3.fromRGB(180, 100, 255),
    purple_dark   = Color3.fromRGB(80, 30, 140),
    text_primary  = Color3.fromRGB(230, 220, 245),
    text_secondary= Color3.fromRGB(160, 140, 185),
    text_dim      = Color3.fromRGB(100, 85, 130),
    success       = Color3.fromRGB(80, 220, 120),
    error         = Color3.fromRGB(220, 60, 80),
}

-- Config System
local CFG = {Enabled = false, Folder = "KetamineHub", File = "Config"}
local ConfigData = {}

local function SaveConfig()
    if not CFG.Enabled then return end
    if writefile then
        if not isfolder(CFG.Folder) then makefolder(CFG.Folder) end
        writefile(CFG.Folder.."/"..CFG.File..".json", HttpService:JSONEncode(ConfigData))
    end
end

local function LoadConfig()
    if not CFG.Enabled then return end
    if isfile and isfile(CFG.Folder.."/"..CFG.File..".json") then
        local s, r = pcall(function() return HttpService:JSONDecode(readfile(CFG.Folder.."/"..CFG.File..".json")) end)
        if s and type(r) == "table" then ConfigData = r end
    end
end

local function tween(obj, props, time)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.purple_dark
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

-- Used for ZIndex layering of dropdowns
local LayerCounter = 100

function Ketamine:CreateWindow(config)
    local title = config.Name or "Ketamine Hub"
    if config.ConfigurationSaving then
        CFG.Enabled = config.ConfigurationSaving.Enabled or false
        CFG.Folder = config.ConfigurationSaving.FolderName or "KetamineHub"
        CFG.File = config.ConfigurationSaving.FileName or "Config"
        LoadConfig()
    end

    local old = CoreGui:FindFirstChild("KetamineUI")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "KetamineUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local success = pcall(function() gui.Parent = CoreGui end)
    if not success then gui.Parent = LocalPlayer.PlayerGui end

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 560, 0, 380)
    main.Position = UDim2.new(0.5, -280, 0.5, -190)
    main.BackgroundColor3 = COLORS.bg_dark
    main.BorderSizePixel = 0
    main.Parent = gui
    makeCorner(main, 8)
    makeStroke(main, COLORS.purple_main, 1.5, 0.4)

    -- Dragging logic
    local dragging, dragInput, dragStart, startPos
    main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 160, 1, 0)
    sidebar.BackgroundColor3 = COLORS.bg_panel
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    makeCorner(sidebar, 8)

    local sbClip = Instance.new("Frame")
    sbClip.Size = UDim2.new(0, 10, 1, 0)
    sbClip.Position = UDim2.new(1, -10, 0, 0)
    sbClip.BackgroundColor3 = COLORS.bg_panel
    sbClip.BorderSizePixel = 0
    sbClip.Parent = sidebar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 0, 50)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = " " .. title
    titleLbl.TextColor3 = COLORS.purple_light
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 15
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = sidebar

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, 0, 1, -60)
    tabContainer.Position = UDim2.new(0, 0, 0, 60)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 0
    tabContainer.Parent = sidebar
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = tabContainer

    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -170, 1, -20)
    contentArea.Position = UDim2.new(0, 165, 0, 10)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = main

    local WindowObj = { Tabs = {} }

    function WindowObj:CreateTab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0.9, 0, 0, 32)
        tabBtn.BackgroundColor3 = COLORS.bg_input
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = "  " .. name
        tabBtn.TextColor3 = COLORS.text_secondary
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 13
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Parent = tabContainer
        makeCorner(tabBtn, 6)

        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.ScrollBarThickness = 2
        tabContent.ScrollBarImageColor3 = COLORS.purple_main
        tabContent.Visible = false
        tabContent.Parent = contentArea

        local contentLayout = Instance.new("UIListLayout")
        contentLayout.Padding = UDim.new(0, 8)
        contentLayout.Parent = tabContent

        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 10)
        end)

        tabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(WindowObj.Tabs) do
                t.Button.BackgroundTransparency = 1
                t.Button.TextColor3 = COLORS.text_secondary
                t.Content.Visible = false
            end
            tabBtn.BackgroundTransparency = 0.5
            tabBtn.TextColor3 = COLORS.text_primary
            tabContent.Visible = true
        end)

        table.insert(WindowObj.Tabs, {Button = tabBtn, Content = tabContent})

        if #WindowObj.Tabs == 1 then
            tabBtn.BackgroundTransparency = 0.5
            tabBtn.TextColor3 = COLORS.text_primary
            tabContent.Visible = true
        end

        local TabObj = {}

        function TabObj:CreateSection(secName)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 25)
            lbl.BackgroundTransparency = 1
            lbl.Text = " " .. secName
            lbl.TextColor3 = COLORS.purple_light
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = tabContent
        end

        function TabObj:CreateLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 20)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = COLORS.text_secondary
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextWrapped = true
            lbl.Parent = tabContent
            lbl.Size = UDim2.new(1, -10, 0, lbl.TextBounds.Y + 5)
        end
        TabObj.CreateParagraph = TabObj.CreateLabel

        function TabObj:CreateButton(bConfig)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 36)
            btn.BackgroundColor3 = COLORS.bg_input
            btn.Text = bConfig.Name or "Button"
            btn.TextColor3 = COLORS.text_primary
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 13
            btn.AutoButtonColor = false
            btn.Parent = tabContent
            makeCorner(btn, 6)
            makeStroke(btn)

            btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = COLORS.purple_dark}) end)
            btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = COLORS.bg_input}) end)
            btn.MouseButton1Down:Connect(function() tween(btn, {BackgroundColor3 = COLORS.purple_main}) end)
            btn.MouseButton1Up:Connect(function() tween(btn, {BackgroundColor3 = COLORS.bg_input}) end)
            btn.MouseButton1Click:Connect(bConfig.Callback or function() end)
        end

        function TabObj:CreateToggle(tConfig)
            local flag = tConfig.Flag
            local state = tConfig.CurrentValue or false
            if flag and ConfigData[flag] ~= nil then state = ConfigData[flag] end
            
            local cb = tConfig.Callback or function() end

            local frame = Instance.new("TextButton")
            frame.Size = UDim2.new(1, -10, 0, 36)
            frame.BackgroundColor3 = COLORS.bg_input
            frame.Text = ""
            frame.AutoButtonColor = false
            frame.Parent = tabContent
            makeCorner(frame, 6)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -50, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = tConfig.Name or "Toggle"
            lbl.TextColor3 = COLORS.text_primary
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame

            local indicator = Instance.new("Frame")
            indicator.Size = UDim2.new(0, 22, 0, 22)
            indicator.Position = UDim2.new(1, -32, 0.5, -11)
            indicator.BackgroundColor3 = state and COLORS.purple_main or COLORS.bg_dark
            indicator.Parent = frame
            makeCorner(indicator, 4)
            makeStroke(indicator)

            local function fire()
                if flag then ConfigData[flag] = state SaveConfig() end
                tween(indicator, {BackgroundColor3 = state and COLORS.purple_main or COLORS.bg_dark}, 0.15)
                cb(state)
            end

            frame.MouseButton1Click:Connect(function()
                state = not state
                fire()
            end)
            
            task.spawn(fire)
            return {
                Set = function(self, val) state = val fire() end
            }
        end

        function TabObj:CreateSlider(sConfig)
            local flag = sConfig.Flag
            local min = sConfig.Min or 0
            local max = sConfig.Max or 100
            local val = sConfig.Default or min
            if flag and ConfigData[flag] ~= nil then val = ConfigData[flag] end
            
            local inc = sConfig.Increment or 1
            local cb = sConfig.Callback or function() end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 54)
            frame.BackgroundColor3 = COLORS.bg_input
            frame.Parent = tabContent
            makeCorner(frame, 6)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -20, 0, 25)
            lbl.Position = UDim2.new(0, 10, 0, 2)
            lbl.BackgroundTransparency = 1
            lbl.Text = sConfig.Name or "Slider"
            lbl.TextColor3 = COLORS.text_primary
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame

            local valLbl = Instance.new("TextLabel")
            valLbl.Size = UDim2.new(0, 50, 0, 25)
            valLbl.Position = UDim2.new(1, -60, 0, 2)
            valLbl.BackgroundTransparency = 1
            valLbl.Text = tostring(val) .. (sConfig.ValueName and (" " .. sConfig.ValueName) or "")
            valLbl.TextColor3 = COLORS.purple_light
            valLbl.Font = Enum.Font.GothamMedium
            valLbl.TextSize = 13
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.Parent = frame

            local sliderBg = Instance.new("TextButton")
            sliderBg.Size = UDim2.new(1, -20, 0, 6)
            sliderBg.Position = UDim2.new(0, 10, 0, 36)
            sliderBg.BackgroundColor3 = COLORS.bg_dark
            sliderBg.Text = ""
            sliderBg.AutoButtonColor = false
            sliderBg.Parent = frame
            makeCorner(sliderBg, 3)

            local sliderFill = Instance.new("Frame")
            sliderFill.Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0)
            sliderFill.BackgroundColor3 = COLORS.purple_main
            sliderFill.BorderSizePixel = 0
            sliderFill.Parent = sliderBg
            makeCorner(sliderFill, 3)

            local dragging = false
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                local newVal = math.floor((min + pos * (max - min)) / inc + 0.5) * inc
                newVal = math.clamp(newVal, min, max)
                
                if val ~= newVal then
                    val = newVal
                    local mappedPos = (val - min) / (max - min)
                    tween(sliderFill, {Size = UDim2.new(mappedPos, 0, 1, 0)}, 0.05)
                    valLbl.Text = tostring(val) .. (sConfig.ValueName and (" " .. sConfig.ValueName) or "")
                    if flag then ConfigData[flag] = val SaveConfig() end
                    cb(val)
                end
            end

            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
            
            task.spawn(function() cb(val) end)
            return {
                Set = function(self, newVal)
                    val = math.clamp(newVal, min, max)
                    local mappedPos = (val - min) / (max - min)
                    tween(sliderFill, {Size = UDim2.new(mappedPos, 0, 1, 0)}, 0.1)
                    valLbl.Text = tostring(val) .. (sConfig.ValueName and (" " .. sConfig.ValueName) or "")
                    if flag then ConfigData[flag] = val SaveConfig() end
                    cb(val)
                end
            }
        end

        function TabObj:CreateDropdown(dConfig)
            local flag = dConfig.Flag
            local options = dConfig.Options or {}
            local current = dConfig.CurrentOption or {}
            if type(current) == "string" then current = {current} end
            if flag and ConfigData[flag] ~= nil then current = ConfigData[flag] end
            
            local multi = dConfig.MultipleOptions or false
            local cb = dConfig.Callback or function() end

            LayerCounter = LayerCounter - 1
            local zIdx = LayerCounter

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 44)
            frame.BackgroundColor3 = COLORS.bg_input
            frame.ZIndex = zIdx
            frame.Parent = tabContent
            makeCorner(frame, 6)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -20, 0, 20)
            lbl.Position = UDim2.new(0, 10, 0, 4)
            lbl.BackgroundTransparency = 1
            lbl.Text = dConfig.Name or "Dropdown"
            lbl.TextColor3 = COLORS.text_primary
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = zIdx
            lbl.Parent = frame

            local selectedLbl = Instance.new("TextLabel")
            selectedLbl.Size = UDim2.new(1, -20, 0, 16)
            selectedLbl.Position = UDim2.new(0, 10, 0, 24)
            selectedLbl.BackgroundTransparency = 1
            selectedLbl.Text = table.concat(current, ", ")
            selectedLbl.TextColor3 = COLORS.purple_light
            selectedLbl.Font = Enum.Font.Gotham
            selectedLbl.TextSize = 12
            selectedLbl.TextXAlignment = Enum.TextXAlignment.Left
            selectedLbl.TextTruncate = Enum.TextTruncate.AtEnd
            selectedLbl.ZIndex = zIdx
            selectedLbl.Parent = frame

            local openBtn = Instance.new("TextButton")
            openBtn.Size = UDim2.new(1, 0, 1, 0)
            openBtn.BackgroundTransparency = 1
            openBtn.Text = ""
            openBtn.ZIndex = zIdx + 1
            openBtn.Parent = frame

            local dropContainer = Instance.new("ScrollingFrame")
            dropContainer.Size = UDim2.new(1, 0, 0, 0)
            dropContainer.Position = UDim2.new(0, 0, 1, 4)
            dropContainer.BackgroundColor3 = COLORS.bg_panel
            dropContainer.ScrollBarThickness = 2
            dropContainer.ScrollBarImageColor3 = COLORS.purple_main
            dropContainer.BorderSizePixel = 0
            dropContainer.Visible = false
            dropContainer.ZIndex = zIdx + 2
            dropContainer.Parent = frame
            makeCorner(dropContainer, 6)
            makeStroke(dropContainer, COLORS.purple_dark, 1)

            local dLayout = Instance.new("UIListLayout")
            dLayout.Padding = UDim.new(0, 2)
            dLayout.Parent = dropContainer

            local isOpen = false
            local function toggleDrop()
                isOpen = not isOpen
                dropContainer.Visible = true
                if isOpen then
                    local h = math.clamp(#options * 30 + 4, 0, 120)
                    tween(dropContainer, {Size = UDim2.new(1, 0, 0, h)}, 0.2)
                    tween(frame, {Size = UDim2.new(1, -10, 0, 44 + h + 8)}, 0.2)
                else
                    tween(dropContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2).Completed:Connect(function()
                        if not isOpen then dropContainer.Visible = false end
                    end)
                    tween(frame, {Size = UDim2.new(1, -10, 0, 44)}, 0.2)
                end
            end
            openBtn.MouseButton1Click:Connect(toggleDrop)

            local function renderOptions()
                for _, c in pairs(dropContainer:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, opt in ipairs(options) do
                    local isSel = table.find(current, opt)
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.BackgroundColor3 = isSel and COLORS.purple_dark or COLORS.bg_panel
                    btn.BackgroundTransparency = isSel and 0 or 1
                    btn.Text = "  " .. opt
                    btn.TextColor3 = isSel and COLORS.white or COLORS.text_secondary
                    btn.Font = Enum.Font.GothamMedium
                    btn.TextSize = 13
                    btn.TextXAlignment = Enum.TextXAlignment.Left
                    btn.ZIndex = zIdx + 3
                    btn.Parent = dropContainer

                    btn.MouseButton1Click:Connect(function()
                        if multi then
                            local idx = table.find(current, opt)
                            if idx then table.remove(current, idx) else table.insert(current, opt) end
                        else
                            current = {opt}
                            toggleDrop()
                        end
                        selectedLbl.Text = table.concat(current, ", ")
                        if flag then ConfigData[flag] = current SaveConfig() end
                        cb(multi and current or current[1])
                        renderOptions()
                    end)
                end
                dropContainer.CanvasSize = UDim2.new(0, 0, 0, #options * 30 + 4)
            end
            renderOptions()

            task.spawn(function() cb(multi and current or current[1]) end)

            return {
                Refresh = function(self, newOpts)
                    options = newOpts
                    renderOptions()
                end,
                Set = function(self, newOpts)
                    if type(newOpts) == "string" then newOpts = {newOpts} end
                    current = newOpts
                    selectedLbl.Text = table.concat(current, ", ")
                    if flag then ConfigData[flag] = current SaveConfig() end
                    cb(multi and current or current[1])
                    renderOptions()
                end
            }
        end

        function TabObj:CreateInput(iConfig)
            local flag = iConfig.Flag
            local text = iConfig.CurrentValue or ""
            if flag and ConfigData[flag] ~= nil then text = ConfigData[flag] end
            
            local cb = iConfig.Callback or function() end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 44)
            frame.BackgroundColor3 = COLORS.bg_input
            frame.Parent = tabContent
            makeCorner(frame, 6)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.5, 0, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = iConfig.Name or "Input"
            lbl.TextColor3 = COLORS.text_primary
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame

            local tb = Instance.new("TextBox")
            tb.Size = UDim2.new(0.5, -20, 0, 28)
            tb.Position = UDim2.new(0.5, 10, 0, 8)
            tb.BackgroundColor3 = COLORS.bg_dark
            tb.Text = text
            tb.PlaceholderText = iConfig.PlaceholderText or "Type here..."
            tb.TextColor3 = COLORS.purple_light
            tb.Font = Enum.Font.GothamMedium
            tb.TextSize = 13
            tb.ClearTextOnFocus = false
            tb.Parent = frame
            makeCorner(tb, 4)
            makeStroke(tb)

            tb.FocusLost:Connect(function()
                text = tb.Text
                if flag then ConfigData[flag] = text SaveConfig() end
                cb(text)
            end)
            
            task.spawn(function() cb(text) end)
        end

        function TabObj:CreateKeybind(kConfig)
            local flag = kConfig.Flag
            local key = kConfig.CurrentKeybind or "E"
            if flag and ConfigData[flag] ~= nil then key = ConfigData[flag] end
            
            local cb = kConfig.Callback or function() end

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 0, 36)
            frame.BackgroundColor3 = COLORS.bg_input
            frame.Parent = tabContent
            makeCorner(frame, 6)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -100, 1, 0)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = kConfig.Name or "Keybind"
            lbl.TextColor3 = COLORS.text_primary
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = frame

            local bindBtn = Instance.new("TextButton")
            bindBtn.Size = UDim2.new(0, 60, 0, 24)
            bindBtn.Position = UDim2.new(1, -70, 0, 6)
            bindBtn.BackgroundColor3 = COLORS.bg_dark
            bindBtn.Text = key
            bindBtn.TextColor3 = COLORS.purple_light
            bindBtn.Font = Enum.Font.GothamBold
            bindBtn.TextSize = 13
            bindBtn.Parent = frame
            makeCorner(bindBtn, 4)
            makeStroke(bindBtn)

            local waiting = false
            bindBtn.MouseButton1Click:Connect(function()
                waiting = true
                bindBtn.Text = "..."
                bindBtn.TextColor3 = COLORS.text_dim
            end)

            UserInputService.InputBegan:Connect(function(input, gp)
                if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
                    waiting = false
                    key = input.KeyCode.Name
                    bindBtn.Text = key
                    bindBtn.TextColor3 = COLORS.purple_light
                    if flag then ConfigData[flag] = key SaveConfig() end
                elseif not gp and input.KeyCode.Name == key then
                    cb()
                end
            end)
        end

        return TabObj
    end

    function WindowObj:Notify(nConfig)
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 260, 0, 70)
        notif.Position = UDim2.new(1, 20, 1, -90)
        notif.BackgroundColor3 = COLORS.bg_panel
        notif.Parent = gui
        makeCorner(notif, 6)
        makeStroke(notif, COLORS.purple_main, 1.5, 0.2)

        local tLbl = Instance.new("TextLabel")
        tLbl.Size = UDim2.new(1, -20, 0, 25)
        tLbl.Position = UDim2.new(0, 10, 0, 5)
        tLbl.BackgroundTransparency = 1
        tLbl.Text = nConfig.Title or "Notification"
        tLbl.TextColor3 = COLORS.purple_light
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 14
        tLbl.TextXAlignment = Enum.TextXAlignment.Left
        tLbl.Parent = notif

        local cLbl = Instance.new("TextLabel")
        cLbl.Size = UDim2.new(1, -20, 0, 30)
        cLbl.Position = UDim2.new(0, 10, 0, 30)
        cLbl.BackgroundTransparency = 1
        cLbl.Text = nConfig.Content or ""
        cLbl.TextColor3 = COLORS.text_secondary
        cLbl.Font = Enum.Font.GothamMedium
        cLbl.TextSize = 13
        cLbl.TextXAlignment = Enum.TextXAlignment.Left
        cLbl.TextWrapped = true
        cLbl.Parent = notif

        tween(notif, {Position = UDim2.new(1, -280, 1, -90)}, 0.4)
        task.delay(nConfig.Duration or 3, function()
            tween(notif, {Position = UDim2.new(1, 20, 1, -90)}, 0.4).Completed:Connect(function()
                notif:Destroy()
            end)
        end)
    end

    function WindowObj:Destroy()
        gui:Destroy()
    end

    return WindowObj
end

return Ketamine
