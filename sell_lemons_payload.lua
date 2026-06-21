--// Ketamine Hub — Sell Lemons Payload Script
--// Universal Tycoon Discovery Engine — works by scanning live hierarchy
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

--// Load Ketamine UI Library
local KetamineUI = loadstring(game:HttpGet('https://YOUR_API_DOMAIN/ketamineUI.lua'))()

local Window = KetamineUI:CreateWindow({
   Name = "💉 Ketamine Hub | Sell Lemons",
   LoadingTitle = "Ketamine Hub",
   LoadingSubtitle = "by Byte",
   Theme = "Purple",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = true,
      FolderName = "KetamineHub",
      FileName = "SellLemonsConfig"
   }
})

--// State
local Toggles = {
    AutoHarvest = false,
    AutoSell = false,
    AutoBuy = false,
    AutoRebirth = false,
    AutoCollectDrops = false,
    WalkspeedEnabled = false,
    JumppowerEnabled = false,
    AutoRemoteBuy = false
}

local Config = {
    WalkspeedValue = 16,
    JumppowerValue = 50,
    TeleportSpeed = 0.08,
    HarvestRadius = 200,
    CollectRadius = 150
}

--// Discovery cache — populated on init and refreshed periodically
local Cache = {
    myTycoon = nil,
    sellParts = {},       -- BaseParts with sell-related names or TouchInterest
    harvestables = {},    -- ClickDetectors / ProximityPrompts on trees/fruits
    buyButtons = {},      -- Tycoon purchase buttons (TouchInterest)
    sellRemotes = {},     -- RemoteEvents/RemoteFunctions for selling
    rebirthRemotes = {},  -- RemoteEvents for rebirth
    allRemotes = {},      -- Full remote list for debug
    dropParts = {},       -- Collectible drops
    lastScan = 0
}

---------------------------------------------------------------------------
-- DISCOVERY ENGINE
---------------------------------------------------------------------------

local SELL_KEYWORDS = {"sell", "cash", "register", "checkout", "exchange", "vendor", "shop"}
local HARVEST_KEYWORDS = {"lemon", "tree", "fruit", "crop", "plant", "pick", "harvest", "grow", "bush", "farm"}
local BUY_KEYWORDS = {"button", "buy", "purchase", "upgrade", "unlock"}
local REBIRTH_KEYWORDS = {"rebirth", "prestige", "evolve", "reset", "ascend", "reborn"}
local DROP_KEYWORDS = {"drop", "coin", "cash", "money", "gem", "orb", "pickup", "collect", "bill", "lemon"}
local TYCOON_KEYWORDS = {"tycoon", "plot", "base", "stand", "station"}

local function nameMatches(name, keywords)
    local lower = name:lower()
    for _, kw in ipairs(keywords) do
        if lower:find(kw, 1, true) then
            return true
        end
    end
    return false
end

--// Find player's tycoon by walking the entire workspace
local function discoverTycoon()
    -- Strategy 1: ObjectValue named "Owner" pointing to LocalPlayer
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ObjectValue") and desc.Value == LocalPlayer then
            local parentName = desc.Parent and desc.Parent.Name:lower() or ""
            -- Walk up to find the tycoon root (usually 1-3 levels up)
            local candidate = desc.Parent
            for i = 1, 4 do
                if candidate and candidate.Parent and candidate.Parent ~= Workspace then
                    candidate = candidate.Parent
                else
                    break
                end
            end
            -- Prefer the highest ancestor under Workspace that isn't Workspace itself
            if candidate and candidate ~= Workspace then
                return candidate
            end
            return desc.Parent
        end
    end

    -- Strategy 2: StringValue matching player name
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("StringValue") and desc.Value == LocalPlayer.Name then
            local parentName = desc.Name:lower()
            if parentName:find("owner") or parentName:find("player") then
                local candidate = desc.Parent
                for i = 1, 3 do
                    if candidate and candidate.Parent and candidate.Parent ~= Workspace then
                        candidate = candidate.Parent
                    else
                        break
                    end
                end
                return candidate
            end
        end
    end

    -- Strategy 3: Model/Folder named after player
    for _, child in ipairs(Workspace:GetDescendants()) do
        if (child:IsA("Model") or child:IsA("Folder")) and child.Name == LocalPlayer.Name then
            return child
        end
    end

    -- Strategy 4: Tycoon-named container with player reference
    for _, child in ipairs(Workspace:GetDescendants()) do
        if (child:IsA("Model") or child:IsA("Folder")) and nameMatches(child.Name, TYCOON_KEYWORDS) then
            for _, sub in ipairs(child:GetDescendants()) do
                if (sub:IsA("ObjectValue") and sub.Value == LocalPlayer) or
                   (sub:IsA("StringValue") and sub.Value == LocalPlayer.Name) then
                    return child
                end
            end
        end
    end

    return nil
end

--// Scan for sell pads within tycoon or workspace
local function discoverSellParts(tycoon)
    local results = {}
    local searchRoot = tycoon or Workspace

    for _, desc in ipairs(searchRoot:GetDescendants()) do
        if desc:IsA("BasePart") then
            if nameMatches(desc.Name, SELL_KEYWORDS) then
                table.insert(results, desc)
            end
            -- Also check parent name
            if desc.Parent and nameMatches(desc.Parent.Name, SELL_KEYWORDS) then
                table.insert(results, desc)
            end
        end
    end

    -- If nothing found in tycoon, expand to full workspace
    if #results == 0 and tycoon then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("BasePart") and nameMatches(desc.Name, SELL_KEYWORDS) then
                table.insert(results, desc)
            end
        end
    end

    return results
end

--// Scan for harvestable objects (ClickDetectors, ProximityPrompts on lemon/tree objects)
local function discoverHarvestables(tycoon)
    local results = {}
    local searchRoot = tycoon or Workspace

    for _, desc in ipairs(searchRoot:GetDescendants()) do
        -- ClickDetectors on harvest-named parents
        if desc:IsA("ClickDetector") then
            local parentChain = desc.Parent and desc.Parent.Name or ""
            local grandparent = desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name or ""
            if nameMatches(parentChain, HARVEST_KEYWORDS) or nameMatches(grandparent, HARVEST_KEYWORDS) then
                table.insert(results, {type = "click", detector = desc, part = desc.Parent})
            end
        end

        -- ProximityPrompts on harvest-named parents
        if desc:IsA("ProximityPrompt") then
            local parentChain = desc.Parent and desc.Parent.Name or ""
            local grandparent = desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name or ""
            if nameMatches(parentChain, HARVEST_KEYWORDS) or nameMatches(grandparent, HARVEST_KEYWORDS) then
                table.insert(results, {type = "prompt", prompt = desc, part = desc.Parent})
            end
        end
    end

    -- If nothing found by keyword, grab ALL ClickDetectors/ProximityPrompts in tycoon
    if #results == 0 and tycoon then
        for _, desc in ipairs(tycoon:GetDescendants()) do
            if desc:IsA("ClickDetector") then
                table.insert(results, {type = "click", detector = desc, part = desc.Parent})
            elseif desc:IsA("ProximityPrompt") then
                table.insert(results, {type = "prompt", prompt = desc, part = desc.Parent})
            end
        end
    end

    return results
end

--// Scan for tycoon buy buttons (parts with TouchInterest)
local function discoverBuyButtons(tycoon)
    local results = {}
    if not tycoon then return results end

    for _, desc in ipairs(tycoon:GetDescendants()) do
        -- Standard tycoon kit: buttons have a Head part with TouchInterest
        if desc:IsA("BasePart") and desc:FindFirstChild("TouchInterest") then
            if nameMatches(desc.Name, BUY_KEYWORDS) or 
               (desc.Parent and nameMatches(desc.Parent.Name, BUY_KEYWORDS)) then
                table.insert(results, desc)
            end
        end
    end

    -- Fallback: any part with TouchInterest in a "Buttons" or similar folder
    if #results == 0 then
        for _, desc in ipairs(tycoon:GetDescendants()) do
            if (desc:IsA("Folder") or desc:IsA("Model")) and nameMatches(desc.Name, BUY_KEYWORDS) then
                for _, child in ipairs(desc:GetDescendants()) do
                    if child:IsA("BasePart") and child:FindFirstChild("TouchInterest") then
                        table.insert(results, child)
                    end
                end
            end
        end
    end

    -- Nuclear fallback: every BasePart with TouchInterest that isn't a sell pad
    if #results == 0 then
        for _, desc in ipairs(tycoon:GetDescendants()) do
            if desc:IsA("BasePart") and desc:FindFirstChild("TouchInterest") then
                if not nameMatches(desc.Name, SELL_KEYWORDS) then
                    table.insert(results, desc)
                end
            end
        end
    end

    return results
end

--// Scan ReplicatedStorage for remotes
local function discoverRemotes()
    local sellRemotes = {}
    local rebirthRemotes = {}
    local allRemotes = {}

    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            table.insert(allRemotes, {name = desc.Name, path = desc:GetFullName(), class = desc.ClassName, ref = desc})

            if nameMatches(desc.Name, SELL_KEYWORDS) then
                table.insert(sellRemotes, desc)
            end
            if nameMatches(desc.Name, REBIRTH_KEYWORDS) then
                table.insert(rebirthRemotes, desc)
            end
        end
    end

    return sellRemotes, rebirthRemotes, allRemotes
end

--// Scan for collectible drops in workspace
local function discoverDrops()
    local results = {}
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return results end
    local hrpPos = character.HumanoidRootPart.Position

    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("BasePart") and nameMatches(desc.Name, DROP_KEYWORDS) then
            if (desc.Position - hrpPos).Magnitude < Config.CollectRadius then
                table.insert(results, desc)
            end
        end
        -- Also catch TouchInterest on drops
        if desc:IsA("BasePart") and desc:FindFirstChild("TouchInterest") then
            if nameMatches(desc.Name, DROP_KEYWORDS) or 
               (desc.Parent and nameMatches(desc.Parent.Name, DROP_KEYWORDS)) then
                if (desc.Position - hrpPos).Magnitude < Config.CollectRadius then
                    table.insert(results, desc)
                end
            end
        end
    end

    return results
end

--// Full scan
local function fullScan()
    Cache.myTycoon = discoverTycoon()
    Cache.sellParts = discoverSellParts(Cache.myTycoon)
    Cache.harvestables = discoverHarvestables(Cache.myTycoon)
    Cache.buyButtons = discoverBuyButtons(Cache.myTycoon)
    Cache.sellRemotes, Cache.rebirthRemotes, Cache.allRemotes = discoverRemotes()
    Cache.lastScan = tick()
end

--// Initial scan
fullScan()

--// Rescan periodically (game adds/removes objects)
task.spawn(function()
    while true do
        task.wait(10)
        fullScan()
    end
end)

---------------------------------------------------------------------------
-- INTERACTION HELPERS
---------------------------------------------------------------------------

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(part, waitTime)
    local hrp = getHRP()
    if not hrp or not part or not part.Parent then return false end
    local oldCFrame = hrp.CFrame
    hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
    task.wait(waitTime or Config.TeleportSpeed)
    return true
end

local function touchPart(targetPart)
    local hrp = getHRP()
    if not hrp or not targetPart or not targetPart.Parent then return end

    if firetouchinterest then
        firetouchinterest(hrp, targetPart, 0)
        task.wait(0.05)
        firetouchinterest(hrp, targetPart, 1)
    else
        -- Teleport fallback
        local oldCFrame = hrp.CFrame
        hrp.CFrame = targetPart.CFrame
        task.wait(0.15)
        hrp.CFrame = oldCFrame
    end
end

local function fireClickDetector(cd)
    if not cd or not cd.Parent then return end
    if fireclickdetector then
        fireclickdetector(cd)
    elseif cd:IsA("ClickDetector") then
        -- Backup: teleport near it
        local part = cd.Parent
        if part and part:IsA("BasePart") then
            teleportTo(part, 0.15)
        end
    end
end

local function fireProximityPrompt(pp)
    if not pp or not pp.Parent then return end
    if fireproximityprompt then
        fireproximityprompt(pp)
    else
        -- Manual trigger
        local oldHold = pp.HoldDuration
        local oldDist = pp.MaxActivationDistance
        pp.MaxActivationDistance = 9999
        pp.HoldDuration = 0
        local hrp = getHRP()
        if hrp and pp.Parent and pp.Parent:IsA("BasePart") then
            local oldCFrame = hrp.CFrame
            hrp.CFrame = pp.Parent.CFrame
            task.wait(0.1)
            -- Simulate interaction
            pp:InputHoldBegin()
            task.wait(0.05)
            pp:InputHoldEnd()
            task.wait(0.05)
            hrp.CFrame = oldCFrame
        end
        pp.MaxActivationDistance = oldDist
        pp.HoldDuration = oldHold
    end
end

local function fireRemote(remote, ...)
    if not remote or not remote.Parent then return end
    if remote:IsA("RemoteEvent") then
        remote:FireServer(...)
    elseif remote:IsA("RemoteFunction") then
        local args = {...}
        pcall(function() remote:InvokeServer(unpack(args)) end)
    end
end

---------------------------------------------------------------------------
-- TABS
---------------------------------------------------------------------------
local MainTab = Window:CreateTab("Auto Farm")
local TycoonTab = Window:CreateTab("Auto Tycoon")
local PlayerTab = Window:CreateTab("Player Settings")
local DebugTab = Window:CreateTab("Debug / Scan")

---------------------------------------------------------------------------
-- AUTO FARM TAB
---------------------------------------------------------------------------
MainTab:CreateSection("Lemon Gathering")

MainTab:CreateToggle({
   Name = "Auto Harvest Lemons",
   CurrentValue = false,
   Flag = "AutoHarvest",
   Callback = function(Value)
      Toggles.AutoHarvest = Value
   end
})

MainTab:CreateToggle({
   Name = "Auto Sell Lemons",
   CurrentValue = false,
   Flag = "AutoSell",
   Callback = function(Value)
      Toggles.AutoSell = Value
   end
})

MainTab:CreateToggle({
   Name = "Auto Collect Drops",
   CurrentValue = false,
   Flag = "AutoCollect",
   Callback = function(Value)
      Toggles.AutoCollectDrops = Value
   end
})

MainTab:CreateSlider({
   Name = "Collect Radius",
   Min = 50,
   Max = 500,
   Default = 150,
   Increment = 25,
   ValueName = "studs",
   Flag = "CollectRadius",
   Callback = function(Value)
      Config.CollectRadius = Value
   end
})

---------------------------------------------------------------------------
-- AUTO TYCOON TAB
---------------------------------------------------------------------------
TycoonTab:CreateSection("Automation")

TycoonTab:CreateToggle({
   Name = "Auto Buy Tycoon Buttons",
   CurrentValue = false,
   Flag = "AutoBuy",
   Callback = function(Value)
      Toggles.AutoBuy = Value
   end
})

TycoonTab:CreateToggle({
   Name = "Auto Buy via Remotes",
   CurrentValue = false,
   Flag = "AutoRemoteBuy",
   Callback = function(Value)
      Toggles.AutoRemoteBuy = Value
   end
})

TycoonTab:CreateToggle({
   Name = "Auto Rebirth / Prestige",
   CurrentValue = false,
   Flag = "AutoRebirth",
   Callback = function(Value)
      Toggles.AutoRebirth = Value
   end
})

---------------------------------------------------------------------------
-- PLAYER TAB
---------------------------------------------------------------------------
PlayerTab:CreateSection("Modifications")

PlayerTab:CreateToggle({
   Name = "WalkSpeed Customizer",
   CurrentValue = false,
   Flag = "WSEnabled",
   Callback = function(Value)
      Toggles.WalkspeedEnabled = Value
      if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
          LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
      end
   end
})

PlayerTab:CreateSlider({
   Name = "WalkSpeed Value",
   Min = 16,
   Max = 250,
   Default = 16,
   Increment = 1,
   ValueName = "Speed",
   Flag = "WSVal",
   Callback = function(Value)
      Config.WalkspeedValue = Value
   end
})

PlayerTab:CreateToggle({
   Name = "JumpPower Customizer",
   CurrentValue = false,
   Flag = "JPEnabled",
   Callback = function(Value)
      Toggles.JumppowerEnabled = Value
      if not Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
          LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
      end
   end
})

PlayerTab:CreateSlider({
   Name = "JumpPower Value",
   Min = 50,
   Max = 500,
   Default = 50,
   Increment = 5,
   ValueName = "Power",
   Flag = "JPVal",
   Callback = function(Value)
      Config.JumppowerValue = Value
   end
})

PlayerTab:CreateButton({
   Name = "Teleport to Sell Pad",
   Callback = function()
      if #Cache.sellParts > 0 then
          teleportTo(Cache.sellParts[1], 0.3)
          Window:Notify({Title = "Teleported", Content = "Moved to: " .. Cache.sellParts[1].Name, Duration = 2, Image = "check-circle"})
      else
          Window:Notify({Title = "Error", Content = "No sell pad found — run a scan first", Duration = 3, Image = "alert-circle"})
      end
   end
})

---------------------------------------------------------------------------
-- DEBUG TAB
---------------------------------------------------------------------------
DebugTab:CreateSection("Discovery Results")

DebugTab:CreateButton({
   Name = "🔄 Force Rescan",
   Callback = function()
      fullScan()
      local msg = string.format(
          "Tycoon: %s\nSell Pads: %d\nHarvestables: %d\nBuy Buttons: %d\nSell Remotes: %d\nRebirth Remotes: %d\nAll Remotes: %d",
          Cache.myTycoon and Cache.myTycoon:GetFullName() or "NOT FOUND",
          #Cache.sellParts,
          #Cache.harvestables,
          #Cache.buyButtons,
          #Cache.sellRemotes,
          #Cache.rebirthRemotes,
          #Cache.allRemotes
      )
      Window:Notify({Title = "Scan Complete", Content = msg, Duration = 8, Image = "search"})
   end
})

DebugTab:CreateButton({
   Name = "📋 Print All Remotes to Console",
   Callback = function()
      print("=== KETAMINE HUB: ALL REMOTES ===")
      for i, r in ipairs(Cache.allRemotes) do
          print(string.format("[%d] %s (%s) — %s", i, r.name, r.class, r.path))
      end
      print("=== END REMOTES ===")
      Window:Notify({Title = "Printed", Content = #Cache.allRemotes .. " remotes dumped to F9 console", Duration = 3, Image = "terminal"})
   end
})

DebugTab:CreateButton({
   Name = "📋 Print Tycoon Children",
   Callback = function()
      if not Cache.myTycoon then
          Window:Notify({Title = "Error", Content = "No tycoon found", Duration = 3, Image = "alert-circle"})
          return
      end
      print("=== TYCOON: " .. Cache.myTycoon:GetFullName() .. " ===")
      for _, child in ipairs(Cache.myTycoon:GetChildren()) do
          local childCount = #child:GetDescendants()
          print(string.format("  [%s] %s (%d descendants)", child.ClassName, child.Name, childCount))
      end
      print("=== END TYCOON ===")
      Window:Notify({Title = "Printed", Content = "Tycoon structure dumped to F9 console", Duration = 3, Image = "terminal"})
   end
})

DebugTab:CreateButton({
   Name = "📋 Print Sell Pads Found",
   Callback = function()
      print("=== SELL PADS ===")
      for i, p in ipairs(Cache.sellParts) do
          print(string.format("[%d] %s — %s", i, p.Name, p:GetFullName()))
      end
      if #Cache.sellParts == 0 then print("  (none found)") end
      print("=== END ===")
      Window:Notify({Title = "Printed", Content = #Cache.sellParts .. " sell pads dumped to F9", Duration = 3, Image = "terminal"})
   end
})

DebugTab:CreateButton({
   Name = "📋 Print Buy Buttons Found",
   Callback = function()
      print("=== BUY BUTTONS ===")
      for i, p in ipairs(Cache.buyButtons) do
          print(string.format("[%d] %s — %s (TouchInterest: %s)", i, p.Name, p:GetFullName(), tostring(p:FindFirstChild("TouchInterest") ~= nil)))
      end
      if #Cache.buyButtons == 0 then print("  (none found)") end
      print("=== END ===")
      Window:Notify({Title = "Printed", Content = #Cache.buyButtons .. " buttons dumped to F9", Duration = 3, Image = "terminal"})
   end
})

DebugTab:CreateButton({
   Name = "📋 Full Workspace Dump (Top-Level)",
   Callback = function()
      print("=== WORKSPACE TOP-LEVEL ===")
      for _, child in ipairs(Workspace:GetChildren()) do
          print(string.format("  [%s] %s", child.ClassName, child.Name))
      end
      print("=== END ===")
      Window:Notify({Title = "Printed", Content = "Workspace top-level dumped to F9", Duration = 3, Image = "terminal"})
   end
})

---------------------------------------------------------------------------
-- COROUTINE LOOPS
---------------------------------------------------------------------------

--// Loop 1: Auto Harvest
task.spawn(function()
    while true do
        task.wait(0.3)
        if Toggles.AutoHarvest then
            -- Rescan harvestables each cycle in case new ones spawned
            local harvestables = discoverHarvestables(Cache.myTycoon)
            for _, entry in ipairs(harvestables) do
                if not Toggles.AutoHarvest then break end
                pcall(function()
                    if entry.type == "click" and entry.detector and entry.detector.Parent then
                        fireClickDetector(entry.detector)
                    elseif entry.type == "prompt" and entry.prompt and entry.prompt.Parent then
                        fireProximityPrompt(entry.prompt)
                    end
                end)
                task.wait(0.05)
            end

            -- Also try firing any harvest-named remotes
            for _, remote in ipairs(Cache.allRemotes) do
                if nameMatches(remote.name, HARVEST_KEYWORDS) and remote.ref and remote.ref.Parent then
                    pcall(function() fireRemote(remote.ref) end)
                end
            end
        end
    end
end)

--// Loop 2: Auto Sell
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoSell then
            -- Method 1: Touch sell pads
            for _, sellPad in ipairs(Cache.sellParts) do
                if sellPad and sellPad.Parent then
                    pcall(function()
                        touchPart(sellPad)
                    end)
                    task.wait(0.1)
                end
            end

            -- Method 2: Fire sell remotes
            for _, remote in ipairs(Cache.sellRemotes) do
                if remote and remote.Parent then
                    pcall(function() fireRemote(remote) end)
                end
            end

            -- Method 3: Look for sell-named remotes in all remotes
            for _, r in ipairs(Cache.allRemotes) do
                if nameMatches(r.name, SELL_KEYWORDS) and r.ref and r.ref.Parent then
                    pcall(function() fireRemote(r.ref) end)
                end
            end
        end
    end
end)

--// Loop 3: Auto Buy Tycoon Buttons (via TouchInterest)
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoBuy then
            -- Rescan in case new buttons appeared after purchases
            local buttons = discoverBuyButtons(Cache.myTycoon)
            for _, button in ipairs(buttons) do
                if not Toggles.AutoBuy then break end
                if button and button.Parent then
                    pcall(function()
                        touchPart(button)
                    end)
                    task.wait(0.1)
                end
            end
        end
    end
end)

--// Loop 4: Auto Collect Drops
task.spawn(function()
    while true do
        task.wait(0.3)
        if Toggles.AutoCollectDrops then
            local hrp = getHRP()
            if hrp then
                local drops = discoverDrops()
                for _, drop in ipairs(drops) do
                    if not Toggles.AutoCollectDrops then break end
                    if drop and drop.Parent then
                        pcall(function()
                            -- Try touch first, then teleport the drop to player
                            if drop:FindFirstChild("TouchInterest") then
                                touchPart(drop)
                            else
                                drop.CFrame = hrp.CFrame
                            end
                        end)
                        task.wait(0.02)
                    end
                end
            end
        end
    end
end)

--// Loop 5: Auto Rebirth
task.spawn(function()
    while true do
        task.wait(3)
        if Toggles.AutoRebirth then
            -- Fire all discovered rebirth remotes
            for _, remote in ipairs(Cache.rebirthRemotes) do
                if remote and remote.Parent then
                    pcall(function() fireRemote(remote) end)
                end
            end

            -- Also look for rebirth buttons in tycoon
            if Cache.myTycoon then
                for _, desc in ipairs(Cache.myTycoon:GetDescendants()) do
                    if desc:IsA("BasePart") and nameMatches(desc.Name, REBIRTH_KEYWORDS) then
                        if desc:FindFirstChild("TouchInterest") then
                            pcall(function() touchPart(desc) end)
                        end
                    end
                end
            end
        end
    end
end)

--// Loop 6: Auto Remote Buy (fires buy-named remotes directly)
task.spawn(function()
    while true do
        task.wait(1)
        if Toggles.AutoRemoteBuy then
            for _, r in ipairs(Cache.allRemotes) do
                if nameMatches(r.name, BUY_KEYWORDS) and r.ref and r.ref.Parent then
                    pcall(function() fireRemote(r.ref) end)
                end
            end
        end
    end
end)

--// RunService: Player stat mods
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        if Toggles.WalkspeedEnabled then
            humanoid.WalkSpeed = Config.WalkspeedValue
        end
        if Toggles.JumppowerEnabled then
            humanoid.JumpPower = Config.JumppowerValue
        end
    end
end)

--// Anti-AFK
local ok, VirtualUser = pcall(function() return game:GetService("VirtualUser") end)
if ok and VirtualUser then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0,0))
    end)
end

--// Startup notification with scan results
local scanMsg = string.format(
    "Tycoon: %s | Sell: %d | Harvest: %d | Buttons: %d | Remotes: %d",
    Cache.myTycoon and "Found" or "NOT FOUND",
    #Cache.sellParts,
    #Cache.harvestables,
    #Cache.buyButtons,
    #Cache.allRemotes
)

Window:Notify({
   Title = "Injection Successful",
   Content = scanMsg,
   Duration = 8,
   Image = "check-circle"
})

-- If tycoon wasn't found, warn the user
if not Cache.myTycoon then
    Window:Notify({
        Title = "⚠ Tycoon Not Found",
        Content = "Make sure you've claimed a plot first. Use Debug tab to rescan after claiming.",
        Duration = 10,
        Image = "alert-triangle"
    })
end
