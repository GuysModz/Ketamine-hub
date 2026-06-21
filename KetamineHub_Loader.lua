--// Ketamine Hub Loader
--// Configure these two values:
local SCRIPT_URL = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/main.lua"  -- URL to your main script
local VALID_KEY  = "KETAMINE-XXXX-XXXX"  -- Change this to your key

------------------------------------------------------------
-- Services
------------------------------------------------------------
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local HttpService   = game:GetService("HttpService")
local player        = Players.LocalPlayer

------------------------------------------------------------
-- Color palette
------------------------------------------------------------
local COLORS = {
    bg_dark       = Color3.fromRGB(12, 10, 18),
    bg_panel      = Color3.fromRGB(18, 14, 28),
    bg_input      = Color3.fromRGB(28, 22, 42),
    purple_main   = Color3.fromRGB(140, 60, 220),
    purple_light  = Color3.fromRGB(180, 100, 255),
    purple_glow   = Color3.fromRGB(120, 40, 200),
    purple_dark   = Color3.fromRGB(80, 30, 140),
    text_primary  = Color3.fromRGB(230, 220, 245),
    text_secondary= Color3.fromRGB(160, 140, 185),
    text_dim      = Color3.fromRGB(100, 85, 130),
    success       = Color3.fromRGB(80, 220, 120),
    error         = Color3.fromRGB(220, 60, 80),
    white         = Color3.fromRGB(255, 255, 255),
    black         = Color3.fromRGB(0, 0, 0),
}

------------------------------------------------------------
-- Destroy any previous instance
------------------------------------------------------------
local existing = player.PlayerGui:FindFirstChild("KetamineHubLoader")
if existing then existing:Destroy() end

------------------------------------------------------------
-- ScreenGui
------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "KetamineHubLoader"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui

------------------------------------------------------------
-- Helper: rounded frame
------------------------------------------------------------
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.purple_main
    s.Thickness = thickness or 1.5
    s.Transparency = 0.4
    s.Parent = parent
    return s
end

local function makeGradient(parent, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

------------------------------------------------------------
-- Tween helpers
------------------------------------------------------------
local function tweenProp(obj, props, duration, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
end

------------------------------------------------------------
-- Background overlay (dim + blur feel)
------------------------------------------------------------
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = COLORS.black
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Parent = gui

tweenProp(overlay, {BackgroundTransparency = 0.4}, 0.5)

------------------------------------------------------------
-- Main container
------------------------------------------------------------
local main = Instance.new("Frame")
main.Name = "MainPanel"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.new(0, 420, 0, 340)
main.BackgroundColor3 = COLORS.bg_dark
main.BorderSizePixel = 0
main.BackgroundTransparency = 1
main.Parent = gui

makeCorner(main, 14)
makeStroke(main, COLORS.purple_main, 2)

-- Gradient on main panel
local innerPanel = Instance.new("Frame")
innerPanel.Name = "Inner"
innerPanel.Size = UDim2.new(1, 0, 1, 0)
innerPanel.BackgroundColor3 = COLORS.bg_dark
innerPanel.BorderSizePixel = 0
innerPanel.BackgroundTransparency = 1
innerPanel.Parent = main
makeCorner(innerPanel, 14)
makeGradient(innerPanel, COLORS.bg_dark, COLORS.bg_panel, 160)

-- Intro animation: scale up + fade in
main.Size = UDim2.new(0, 380, 0, 300)
tweenProp(main, {Size = UDim2.new(0, 420, 0, 340), BackgroundTransparency = 0}, 0.45, Enum.EasingStyle.Back)
tweenProp(innerPanel, {BackgroundTransparency = 0}, 0.45)

------------------------------------------------------------
-- Title bar
------------------------------------------------------------
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundColor3 = COLORS.bg_panel
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = main
makeCorner(titleBar, 14)

-- Bottom corners fix (clip lower radius)
local titleClip = Instance.new("Frame")
titleClip.Size = UDim2.new(1, 0, 0, 16)
titleClip.Position = UDim2.new(0, 0, 1, -16)
titleClip.BackgroundColor3 = COLORS.bg_panel
titleClip.BackgroundTransparency = 0.3
titleClip.BorderSizePixel = 0
titleClip.Parent = titleBar

-- Separator line
local sep = Instance.new("Frame")
sep.Size = UDim2.new(0.9, 0, 0, 1)
sep.AnchorPoint = Vector2.new(0.5, 0)
sep.Position = UDim2.new(0.5, 0, 1, 0)
sep.BackgroundColor3 = COLORS.purple_main
sep.BackgroundTransparency = 0.6
sep.BorderSizePixel = 0
sep.Parent = titleBar

-- Title text
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "💉 Ketamine Hub"
titleLabel.TextColor3 = COLORS.purple_light
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Version tag
local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(0, 60, 0, 20)
verLabel.AnchorPoint = Vector2.new(1, 0.5)
verLabel.Position = UDim2.new(1, -14, 0.5, 0)
verLabel.BackgroundColor3 = COLORS.purple_dark
verLabel.BackgroundTransparency = 0.5
verLabel.Text = "v1.0"
verLabel.TextColor3 = COLORS.purple_light
verLabel.TextSize = 12
verLabel.Font = Enum.Font.GothamMedium
verLabel.Parent = titleBar
makeCorner(verLabel, 6)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -80, 0.5, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = COLORS.text_dim
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

closeBtn.MouseEnter:Connect(function()
    tweenProp(closeBtn, {TextColor3 = COLORS.error}, 0.15)
end)
closeBtn.MouseLeave:Connect(function()
    tweenProp(closeBtn, {TextColor3 = COLORS.text_dim}, 0.15)
end)
closeBtn.MouseButton1Click:Connect(function()
    tweenProp(main, {Size = UDim2.new(0, 380, 0, 300), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tweenProp(overlay, {BackgroundTransparency = 1}, 0.3)
    task.wait(0.35)
    gui:Destroy()
end)

------------------------------------------------------------
-- Content area
------------------------------------------------------------
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -40, 1, -72)
content.Position = UDim2.new(0, 20, 0, 62)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Parent = main

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 0, 5)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Enter your key to continue"
subtitle.TextColor3 = COLORS.text_secondary
subtitle.TextSize = 14
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = content

-- Key input container
local inputFrame = Instance.new("Frame")
inputFrame.Name = "InputFrame"
inputFrame.Size = UDim2.new(1, 0, 0, 44)
inputFrame.Position = UDim2.new(0, 0, 0, 38)
inputFrame.BackgroundColor3 = COLORS.bg_input
inputFrame.BorderSizePixel = 0
inputFrame.Parent = content
makeCorner(inputFrame, 10)
local inputStroke = makeStroke(inputFrame, COLORS.purple_dark, 1.5)

-- Key text box
local keyBox = Instance.new("TextBox")
keyBox.Name = "KeyInput"
keyBox.Size = UDim2.new(1, -20, 1, 0)
keyBox.Position = UDim2.new(0, 10, 0, 0)
keyBox.BackgroundTransparency = 1
keyBox.Text = ""
keyBox.PlaceholderText = "KETAMINE-XXXX-XXXX"
keyBox.PlaceholderColor3 = COLORS.text_dim
keyBox.TextColor3 = COLORS.text_primary
keyBox.TextSize = 15
keyBox.Font = Enum.Font.GothamMedium
keyBox.TextXAlignment = Enum.TextXAlignment.Left
keyBox.ClearTextOnFocus = false
keyBox.Parent = inputFrame

keyBox.Focused:Connect(function()
    tweenProp(inputStroke, {Color = COLORS.purple_light, Transparency = 0}, 0.2)
end)
keyBox.FocusLost:Connect(function()
    tweenProp(inputStroke, {Color = COLORS.purple_dark, Transparency = 0.4}, 0.2)
end)

-- Submit button
local submitBtn = Instance.new("TextButton")
submitBtn.Name = "Submit"
submitBtn.Size = UDim2.new(1, 0, 0, 42)
submitBtn.Position = UDim2.new(0, 0, 0, 94)
submitBtn.BackgroundColor3 = COLORS.purple_main
submitBtn.BorderSizePixel = 0
submitBtn.Text = "🔑  Authenticate"
submitBtn.TextColor3 = COLORS.white
submitBtn.TextSize = 15
submitBtn.Font = Enum.Font.GothamBold
submitBtn.AutoButtonColor = false
submitBtn.Parent = content
makeCorner(submitBtn, 10)
makeGradient(submitBtn, COLORS.purple_main, COLORS.purple_dark, 90)

-- Button hover
submitBtn.MouseEnter:Connect(function()
    tweenProp(submitBtn, {BackgroundColor3 = COLORS.purple_light}, 0.15)
end)
submitBtn.MouseLeave:Connect(function()
    tweenProp(submitBtn, {BackgroundColor3 = COLORS.purple_main}, 0.15)
end)

-- Get Key button (link to your key site)
local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Name = "GetKey"
getKeyBtn.Size = UDim2.new(1, 0, 0, 34)
getKeyBtn.Position = UDim2.new(0, 0, 0, 144)
getKeyBtn.BackgroundColor3 = COLORS.bg_input
getKeyBtn.BackgroundTransparency = 0.3
getKeyBtn.BorderSizePixel = 0
getKeyBtn.Text = "🔗  Get Key"
getKeyBtn.TextColor3 = COLORS.purple_light
getKeyBtn.TextSize = 13
getKeyBtn.Font = Enum.Font.GothamMedium
getKeyBtn.AutoButtonColor = false
getKeyBtn.Parent = content
makeCorner(getKeyBtn, 8)
makeStroke(getKeyBtn, COLORS.purple_dark, 1)

getKeyBtn.MouseEnter:Connect(function()
    tweenProp(getKeyBtn, {BackgroundTransparency = 0}, 0.15)
end)
getKeyBtn.MouseLeave:Connect(function()
    tweenProp(getKeyBtn, {BackgroundTransparency = 0.3}, 0.15)
end)

getKeyBtn.MouseButton1Click:Connect(function()
    -- Replace with your key page URL
    if setclipboard then setclipboard("https://your-key-link-here.com") end
end)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 188)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = COLORS.text_dim
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = content

-- Progress bar (hidden until loading)
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.Size = UDim2.new(1, 0, 0, 4)
progressBg.Position = UDim2.new(0, 0, 0, 215)
progressBg.BackgroundColor3 = COLORS.bg_input
progressBg.BorderSizePixel = 0
progressBg.Visible = false
progressBg.Parent = content
makeCorner(progressBg, 2)

local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = COLORS.purple_light
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg
makeCorner(progressFill, 2)

-- Footer
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 16)
footer.Position = UDim2.new(0, 0, 1, -22)
footer.BackgroundTransparency = 1
footer.Text = "Ketamine Hub © 2025 — " .. player.Name
footer.TextColor3 = COLORS.text_dim
footer.TextSize = 11
footer.Font = Enum.Font.Gotham
footer.TextXAlignment = Enum.TextXAlignment.Center
footer.Parent = content

------------------------------------------------------------
-- Dragging
------------------------------------------------------------
do
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                      startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

------------------------------------------------------------
-- Key validation + script load
------------------------------------------------------------
local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or COLORS.text_dim
    statusLabel.TextTransparency = 1
    tweenProp(statusLabel, {TextTransparency = 0}, 0.2)
end

local function showProgress()
    progressBg.Visible = true
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    tweenProp(progressFill, {Size = UDim2.new(0.3, 0, 1, 0)}, 0.4)
end

local function finishProgress(success)
    local color = success and COLORS.success or COLORS.error
    progressFill.BackgroundColor3 = color
    tweenProp(progressFill, {Size = UDim2.new(1, 0, 1, 0)}, 0.3)
end

local authenticated = false

-- Helper to get safe HWID in Roblox environment
local function getHWID()
    local success, result = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return success and result or "UnknownHWID"
end

submitBtn.MouseButton1Click:Connect(function()
    if authenticated then return end

    local key = keyBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        setStatus("⚠ Enter a key first", COLORS.error)
        return
    end

    setStatus("⏳ Authenticating online...", COLORS.purple_light)
    submitBtn.Text = "⏳  Checking..."
    tweenProp(submitBtn, {BackgroundColor3 = COLORS.purple_dark}, 0.2)

    -- Make verification call to local API server
    local apiURL = string.format(
        "https://YOUR_API_DOMAIN/api/validate?key=%s&hwid=%s&user=%s",
        HttpService:UrlEncode(key),
        HttpService:UrlEncode(getHWID()),
        HttpService:UrlEncode(player.Name)
    )

    local success, response = pcall(function()
        return game:HttpGet(apiURL, true)
    end)

    if not success then
        setStatus("❌ Verification server offline", COLORS.error)
        submitBtn.Text = "🔑  Authenticate"
        tweenProp(submitBtn, {BackgroundColor3 = COLORS.purple_main}, 0.2)
        return
    end

    local data
    local parse_success, parse_err = pcall(function()
        data = HttpService:JSONDecode(response)
    end)

    if not parse_success or not data then
        setStatus("❌ Failed parsing server response", COLORS.error)
        submitBtn.Text = "🔑  Authenticate"
        tweenProp(submitBtn, {BackgroundColor3 = COLORS.purple_main}, 0.2)
        return
    end

    if data.status ~= "success" then
        setStatus("❌ " .. (data.message or "Invalid key"), COLORS.error)
        submitBtn.Text = "🔑  Authenticate"
        tweenProp(submitBtn, {BackgroundColor3 = COLORS.purple_main}, 0.2)

        -- Shake animation on input
        local orig = inputFrame.Position
        for i = 1, 4 do
            tweenProp(inputFrame, {Position = orig + UDim2.new(0, (i % 2 == 0 and -6 or 6), 0, 0)}, 0.04)
            task.wait(0.04)
        end
        tweenProp(inputFrame, {Position = orig}, 0.04)
        return
    end

    -- Key accepted
    authenticated = true
    setStatus("✅ Key verified!", COLORS.success)
    showProgress()

    task.wait(0.5)

    -- Fetch and execute script
    local scriptTarget = data.scriptUrl ~= "" and data.scriptUrl or SCRIPT_URL
    local success_fetch, result = pcall(function()
        return game:HttpGet(scriptTarget, true)
    end)

    if success_fetch and result and #result > 0 then
        finishProgress(true)
        setStatus("✅ Script loaded — injecting...", COLORS.success)
        task.wait(0.6)

        -- Fade out UI
        tweenProp(main, {BackgroundTransparency = 1, Size = UDim2.new(0, 400, 0, 320)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tweenProp(overlay, {BackgroundTransparency = 1}, 0.35)
        task.wait(0.4)
        gui:Destroy()

        -- Execute fetched script
        local exec_fn, compile_err = loadstring(result)
        if compile_err then warn(\'Payload Compile Error: \', compile_err) end
        if exec_fn then
            local s, e = pcall(exec_fn); if not s then warn(\'Payload Error: \', e) end
        end
    else
        finishProgress(false)
        setStatus("❌ Failed to fetch payload", COLORS.error)
        submitBtn.Text = "🔑  Authenticate"
        authenticated = false
        tweenProp(submitBtn, {BackgroundColor3 = COLORS.purple_main}, 0.2)
    end
end)

-- Enter key support
keyBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        submitBtn.MouseButton1Click:Fire()
    end
end)
