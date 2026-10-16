-- =============================================================================
-- PART 1: CORE FRAMEWORK & GLOBAL VARIABLES
-- =============================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Window Focus Tracking (Fixes Cursor and Input Issues)
local isWindowFocused = true

UserInputService.WindowFocused:Connect(function()
    isWindowFocused = true
end)

UserInputService.WindowFocusReleased:Connect(function()
    isWindowFocused = false
    player.CameraMode = Enum.CameraMode.Classic
end)

-- Anti-Idle / Anti-AFK Connection
if _G.AntiAfkConnection then _G.AntiAfkConnection:Disconnect() end
_G.AntiAfkConnection = player.Idled:Connect(function(timeIdled)
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Dynamic Character Reference Management
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart", 10)
local humanoid = character:WaitForChild("Humanoid", 10)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart", 10)
    humanoid = newChar:WaitForChild("Humanoid", 10)
    camera = Workspace.CurrentCamera
end)

-- Global Configurations
_G.MasterCoinFarmActive = false
_G.MasterCombatActive = false
_G.HitboxExpanderActive = false

_G.FarmSpeed = 22
_G.UnderMapOffset = -25
_G.HoverHeight = 3
_G.PacingDelay = 0.4
_G.SheriffShootDelay = 0.8 
_G.SheriffPositionInterval = 0.8 
_G.SheriffOffsetDistance = 12

-- Custom Distance, Range, and Hitbox Configs
_G.SheriffRadius = 19
_G.MurdererRadius = 19
_G.HitboxSize = 10

_G.LuaxCollectedCache = {}
_G.BlacklistedCoins = {}
local currentActiveCoinTarget = nil

local LOBBY_POSITION = Vector3.new(13.8513422, 503.670074, -25.0013351)
local LOBBY_RADIUS = 600

if player.PlayerGui:FindFirstChild("LuaxAdvancedMM2") then
    player.PlayerGui.LuaxAdvancedMM2:Destroy()
end

-- =============================================================================
-- PART 2: GRAPHICAL USER INTERFACE BASE
-- =============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuaxAdvancedMM2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player.PlayerGui

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 420, 0, 680) 
Frame.Position = UDim2.new(0.5, -210, 0.5, -340)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 150, 255)
Stroke.Thickness = 2
Stroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Name = "TopBar"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Title.Text = "Luax Hub mm2 autofarm"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Active = true
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 380, 0, 30)
StatusLabel.Position = UDim2.new(0, 20, 0, 50)
StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
StatusLabel.Text = "Status: Idle"
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
StatusLabel.TextSize = 12
StatusLabel.Parent = Frame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

local CoinBtn = Instance.new("TextButton")
CoinBtn.Size = UDim2.new(0, 380, 0, 38)
CoinBtn.Position = UDim2.new(0, 20, 0, 90)
CoinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
CoinBtn.Text = "Universal Coin Farm: DISABLED"
CoinBtn.Font = Enum.Font.GothamBold
CoinBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CoinBtn.TextSize = 12
CoinBtn.ZIndex = 5
CoinBtn.Parent = Frame

local CoinBtnCorner = Instance.new("UICorner")
CoinBtnCorner.CornerRadius = UDim.new(0, 6)
CoinBtnCorner.Parent = CoinBtn

local CombatBtn = Instance.new("TextButton")
CombatBtn.Size = UDim2.new(0, 380, 0, 38)
CombatBtn.Position = UDim2.new(0, 20, 0, 135)
CombatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
CombatBtn.Text = "Autonomous Combat / Aim: DISABLED"
CombatBtn.Font = Enum.Font.GothamBold
CombatBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CombatBtn.TextSize = 12
CombatBtn.ZIndex = 5
CombatBtn.Parent = Frame

local CombatBtnCorner = Instance.new("UICorner")
CombatBtnCorner.CornerRadius = UDim.new(0, 6)
CombatBtnCorner.Parent = CombatBtn

-- Hitbox Expander Toggle Button
local HitboxBtn = Instance.new("TextButton")
HitboxBtn.Size = UDim2.new(0, 380, 0, 38)
HitboxBtn.Position = UDim2.new(0, 20, 0, 180)
HitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
HitboxBtn.Text = "Hitbox Expander: DISABLED"
HitboxBtn.Font = Enum.Font.GothamBold
HitboxBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
HitboxBtn.TextSize = 12
HitboxBtn.ZIndex = 5
HitboxBtn.Parent = Frame

local HitboxBtnCorner = Instance.new("UICorner")
HitboxBtnCorner.CornerRadius = UDim.new(0, 6)
HitboxBtnCorner.Parent = HitboxBtn

-- Discord Join Button
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0, 380, 0, 38)
DiscordBtn.Position = UDim2.new(0, 20, 0, 225)
DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
DiscordBtn.Text = "Join Discord Server"
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DiscordBtn.TextSize = 12
DiscordBtn.ZIndex = 5
DiscordBtn.Parent = Frame

local DiscordBtnCorner = Instance.new("UICorner")
DiscordBtnCorner.CornerRadius = UDim.new(0, 6)
DiscordBtnCorner.Parent = DiscordBtn

DiscordBtn.MouseButton1Click:Connect(function()
    local inviteLink = "https://discord.gg/xueNbfDBtZ"
    
    if setclipboard then
        setclipboard(inviteLink)
    elseif toclipboard then
        toclipboard(inviteLink)
    end
    
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        pcall(function()
            req({
                Url = inviteLink,
                Method = "GET"
            })
        end)
    end

    DiscordBtn.Text = "Copied & Opening Browser!"
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 100)
    
    task.delay(2, function()
        DiscordBtn.Text = "Join Discord Server"
        DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    end)
end)

local function updateStatus(text)
    if StatusLabel then StatusLabel.Text = "Status: " .. text end
end

-- =============================================================================
-- PART 3: UI CONTROLS & DYNAMIC SLIDERS
-- =============================================================================
local function createSlider(name, yPos, minVal, maxVal, defaultVal, callback)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 380, 0, 20)
    Label.Position = UDim2.new(0, 20, 0, yPos)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. tostring(defaultVal)
    Label.Font = Enum.Font.GothamMedium
    Label.TextColor3 = Color3.fromRGB(220, 220, 220)
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0, 380, 0, 10)
    Track.Position = UDim2.new(0, 20, 0, yPos + 22)
    Track.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Track.BorderSizePixel = 0
    Track.Active = true
    Track.ZIndex = 5
    Track.Parent = Frame

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(0, 5)
    TrackCorner.Parent = Track

    local Fill = Instance.new("Frame")
    local initRatio = (defaultVal - minVal) / (maxVal - minVal)
    Fill.Size = UDim2.new(initRatio, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 5
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 5)
    FillCorner.Parent = Fill

    local isSliding = false
    local function updateValue(input)
        local posX = math.clamp(input.Position.X - Track.AbsolutePosition.X, 0, Track.AbsoluteSize.X)
        local ratio = posX / Track.AbsoluteSize.X
        local val = math.floor(minVal + (ratio * (maxVal - minVal)))
        Fill.Size = UDim2.new(ratio, 0, 1, 0)
        Label.Text = name .. ": " .. tostring(val)
        callback(val)
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            updateValue(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end)
end

createSlider("Hitbox Size", 275, 2, 50, _G.HitboxSize, function(v) _G.HitboxSize = v end)
createSlider("Farm Speed (Studs/sec)", 325, 10, 100, _G.FarmSpeed, function(v) _G.FarmSpeed = v end)
createSlider("Under-Map Depth Offset", 375, -50, -5, _G.UnderMapOffset, function(v) _G.UnderMapOffset = v end)
createSlider("Sheriff Offsets/Radius", 425, 5, 50, _G.SheriffRadius, function(v) _G.SheriffRadius = v _G.SheriffOffsetDistance = v end)
createSlider("Murderer Avoid Radius", 475, 5, 50, _G.MurdererRadius, function(v) _G.MurdererRadius = v end)

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0, 200, 0, 25)
DelayLabel.Position = UDim2.new(0, 20, 0, 530)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Pacing Collect Delay (s):"
DelayLabel.Font = Enum.Font.GothamMedium
DelayLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
DelayLabel.TextSize = 11
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = Frame

local DelayInput = Instance.new("TextBox")
DelayInput.Size = UDim2.new(0, 160, 0, 28)
DelayInput.Position = UDim2.new(0, 240, 0, 528)
DelayInput.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
DelayInput.Text = tostring(_G.PacingDelay)
DelayInput.Font = Enum.Font.GothamBold
DelayInput.TextColor3 = Color3.fromRGB(0, 200, 255)
DelayInput.TextSize = 12
DelayInput.ZIndex = 5
DelayInput.Parent = Frame

local DelayCorner = Instance.new("UICorner")
DelayCorner.CornerRadius = UDim.new(0, 5)
DelayCorner.Parent = DelayInput

DelayInput.FocusLost:Connect(function()
    local num = tonumber(DelayInput.Text)
    if num then
        _G.PacingDelay = math.clamp(num, 0, 2)
        DelayInput.Text = tostring(_G.PacingDelay)
    else
        DelayInput.Text = tostring(_G.PacingDelay)
    end
end)

local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(1, 0, 0, 25)
Watermark.Position = UDim2.new(0, 0, 1, -25)
Watermark.BackgroundTransparency = 1
Watermark.Text = "made by hooder"
Watermark.Font = Enum.Font.GothamMedium
Watermark.TextColor3 = Color3.fromRGB(100, 100, 120)
Watermark.TextSize = 11
Watermark.Parent = Frame

local dragging = false
local dragInput, dragStart, startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

Title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- =============================================================================
-- PART 4: HITBOX EXPANDER ENGINE
-- =============================================================================
task.spawn(function()
    while true do
        pcall(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local targetPart = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("Torso")
                    if targetPart then
                        if _G.HitboxExpanderActive then
                            targetPart.Size = Vector3.new(_G.HitboxSize, _G.HitboxSize, _G.HitboxSize)
                            targetPart.Transparency = 0.6
                            targetPart.BrickColor = BrickColor.new("Really red")
                            targetPart.Material = Enum.Material.SmoothPlastic
                            targetPart.CanCollide = false
                        else
                            if targetPart.Name == "HumanoidRootPart" then
                                targetPart.Size = Vector3.new(2, 2, 1)
                            elseif targetPart.Name == "Head" then
                                targetPart.Size = Vector3.new(1, 1, 1)
                            end
                            targetPart.Transparency = 1
                            targetPart.CanCollide = false
                        end
                    end
                end
            end
        end)
        task.wait(0.2)
    end
end)

-- =============================================================================
-- PART 5: ESP ENGINE WITH SMART THREAT COLOR CODES
-- =============================================================================
local function applyHighlight(instance, color)
    if not instance or not instance.Parent then return end
    local highlight = instance:FindFirstChild("LuaxHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "LuaxHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = instance
    end
    highlight.FillTransparency = 0.35
    highlight.OutlineTransparency = 0.1
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.Enabled = true
end

local function removeHighlight(instance)
    if instance then
        local highlight = instance:FindFirstChild("LuaxHighlight")
        if highlight then highlight:Destroy() end
    end
end

local function applyBillboard(instance, text, color)
    if not instance or not instance.Parent then return end
    local head = instance:FindFirstChild("Head") or (instance:IsA("BasePart") and instance) or instance:FindFirstChildWhichIsA("BasePart")
    if not head then return end

    local gui = head:FindFirstChild("LuaxTag")
    if not gui then
        gui = Instance.new("BillboardGui")
        gui.Name = "LuaxTag"
        gui.AlwaysOnTop = true
        gui.Size = UDim2.new(0, 150, 0, 30)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextStrokeTransparency = 0.2
        label.Parent = gui
        gui.Parent = head
    end
    if gui:FindFirstChild("Label") then
        gui.Label.Text = text
        gui.Label.TextColor3 = color
    end
end

local function removeESP(instance)
    if not instance then return end
    local highlight = instance:FindFirstChild("LuaxHighlight")
    if highlight then highlight:Destroy() end
    local head = instance:FindFirstChild("Head") or (instance:IsA("BasePart") and instance) or instance:FindFirstChildWhichIsA("BasePart")
    if head and head:FindFirstChild("LuaxTag") then
        head.LuaxTag:Destroy()
    end
end

local function getPlayerRole(plr)
    if not plr or not plr.Character or not plr.Parent then return "Innocent" end
    local char = plr.Character
    local backpack = plr:FindFirstChild("Backpack")
    if char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then
        return "Murderer"
    end
    if char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function findMurdererCharacter()
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player and getPlayerRole(targetPlayer) == "Murderer" then
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                return targetPlayer.Character
            end
        end
    end
    return nil
end

local function isCoinVisualPart(obj)
    if not obj or not obj.Parent or not obj:IsDescendantOf(Workspace) then return false end
    if _G.LuaxCollectedCache[obj] or _G.BlacklistedCoins[obj] then return false end
    if obj.Parent and (_G.LuaxCollectedCache[obj.Parent] or _G.BlacklistedCoins[obj.Parent]) then return false end
    
    if obj:IsA("TouchTransmitter") then return false end
    if obj.Name == "Handle" then return false end
    
    local nameLower = obj.Name:lower()
    if nameLower:find("coinvisual") or nameLower == "coin" or nameLower == "clover" or nameLower == "candy" or nameLower == "snowball" then
        if obj:IsA("BasePart") then
            return true
        end
    end
    
    return false
end

task.spawn(function()
    while true do
        pcall(function()
            local myRoot = character and character:FindFirstChild("HumanoidRootPart")
            local murdererChar = findMurdererCharacter()
            local murdererRoot = murdererChar and murdererChar:FindFirstChild("HumanoidRootPart")
            
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= player then
                    local char = targetPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local role = getPlayerRole(targetPlayer)
                            local color = Color3.fromRGB(0, 255, 100)
                            if role == "Murderer" then color = Color3.fromRGB(255, 0, 0)
                            elseif role == "Sheriff" then color = Color3.fromRGB(0, 120, 255) end
                            local dist = myRoot and math.floor((char.HumanoidRootPart.Position - myRoot.Position).Magnitude) or 0
                            applyHighlight(char, color)
                            applyBillboard(char, string.format("[%s]\n%s (%dm)", role, targetPlayer.DisplayName, dist), color)
                        else
                            removeESP(char)
                        end
                    elseif char then
                        removeESP(char)
                    end
                end
            end

            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isCoinVisualPart(obj) then
                    local withinMurdRadius = false
                    if murdererRoot and (obj.Position - murdererRoot.Position).Magnitude <= _G.MurdererRadius then
                        withinMurdRadius = true
                    end
                    
                    if withinMurdRadius then
                        applyHighlight(obj, Color3.fromRGB(255, 0, 0))
                    elseif obj == currentActiveCoinTarget then
                        applyHighlight(obj, Color3.fromRGB(0, 255, 0))
                    else
                        applyHighlight(obj, Color3.fromRGB(255, 220, 0))
                    end
                end
            end
            
            if murdererRoot and murdererRoot.Parent then
                local circle = murdererRoot:FindFirstChild("MurdVisualRadius")
                if not circle then
                    circle = Instance.new("SelectionSphere")
                    circle.Name = "MurdVisualRadius"
                    circle.Color3 = Color3.fromRGB(255, 0, 0)
                    circle.Transparency = 0.7
                    circle.Parent = murdererRoot
                end
                circle.Adornee = murdererRoot
            end
        end)
        task.wait(0.4)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then removeESP(plr.Character) end
end)

local function hookPlayerEvents(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        removeHighlight(char)
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do hookPlayerEvents(plr) end
Players.PlayerAdded:Connect(hookPlayerEvents)

-- =============================================================================
-- PART 6: UTILITIES & SYSTEM PHYSICS CONFIGS
-- =============================================================================
local noclipConnection
local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if (_G.MasterCoinFarmActive or _G.MasterCombatActive) and character and character.Parent then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local function applyZoomOverride(isCombatMode)
    if player then
        if isCombatMode then
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 2.0
        else
            player.CameraMinZoomDistance = 0.5
            player.CameraMaxZoomDistance = 128.0
        end
    end
end

local function forceEquipWeapon(weaponName)
    if not character or not character.Parent then return nil end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local equipped = character:FindFirstChild(weaponName)
    if equipped then return equipped end
    local backpack = player:FindFirstChild("Backpack")
    local backpackItem = backpack and backpack:FindFirstChild(weaponName)
    if backpackItem then
        hum:EquipTool(backpackItem)
        return backpackItem
    end
    return nil
end

local function hasWeaponCarried(weaponName)
    if not character or not character.Parent then return false end
    if character:FindFirstChild(weaponName) then return true end
    local backpack = player:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(weaponName) then return true end
    return false
end

local function isPlayerReady()
    if not character or not character.Parent or not character:IsDescendantOf(Workspace) then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end
    local distanceToLobby = (root.Position - LOBBY_POSITION).Magnitude
    if distanceToLobby <= LOBBY_RADIUS then return false end
    return true
end

local function isCoinBagFull()
    local mainGui = player.PlayerGui:FindFirstChild("MainGUI") or player.PlayerGui:FindFirstChild("ScreenGui")
    if mainGui then
        local coinContainer = mainGui:FindFirstChild("CoinContainer", true) or mainGui:FindFirstChild("Container", true)
        if coinContainer then
            local coinText = coinContainer:FindFirstChildOfClass("TextLabel")
            if coinText and coinText.Text then
                local current, max = coinText.Text:match("(%d+)%s*/%s*(%d+)")
                if current and max then return tonumber(current) >= tonumber(max) end
            end
        end
    end
    return false
end

local function findNextCoinVisual(playerPos)
    local targetCoin = nil
    local shortestDistance = math.huge
    local murdererChar = findMurdererCharacter()
    local murdererRoot = murdererChar and murdererChar:FindFirstChild("HumanoidRootPart")

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isCoinVisualPart(obj) then
            local safeFromMurderer = true
            if murdererRoot then
                local distanceToMurd = (obj.Position - murdererRoot.Position).Magnitude
                if distanceToMurd <= _G.MurdererRadius then
                    safeFromMurderer = false
                end
            end

            if safeFromMurderer then
                local dist = (obj.Position - playerPos).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    targetCoin = obj
                end
            end
        end
    end
    return targetCoin
end

local function getNearestMapTarget()
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearestEnemy = nil
    local shortestDistance = math.huge
    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy ~= player and enemy.Parent and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local enemyHum = enemy.Character:FindFirstChildOfClass("Humanoid")
            local enemyRoot = enemy.Character.HumanoidRootPart
            if enemyHum and enemyHum.Health > 0 then
                local distToLobby = (enemyRoot.Position - LOBBY_POSITION).Magnitude
                if distToLobby > LOBBY_RADIUS then
                    local distToPlayer = (enemyRoot.Position - root.Position).Magnitude
                    if distToPlayer < shortestDistance then
                        shortestDistance = distToPlayer
                        nearestEnemy = enemy
                    end
                end
            end
        end
    end
    return nearestEnemy
end

local function isOwnedByPlayer(obj)
    local ancestor = obj
    while ancestor and ancestor ~= Workspace do
        if ancestor:IsA("Model") and Players:GetPlayerFromCharacter(ancestor) then return true end
        if ancestor:IsA("Backpack") then return true end
        ancestor = ancestor.Parent
    end
    return false
end

local function findGunDrop()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = obj.Name:lower()
        if (nameLower == "gundrop" or nameLower == "gun" or nameLower == "droppedgun") then
            if not isOwnedByPlayer(obj) then
                if obj:IsA("BasePart") then return obj
                elseif obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then return part end
                end
            end
        end
    end
    return nil
end

local function disableFirstPersonLock() 
    player.CameraMode = Enum.CameraMode.Classic 
end

local function getPredictedTargetPosition(targetPart)
    if not targetPart then return Vector3.zero end
    local pos = targetPart.Position
    local vel = targetPart.AssemblyLinearVelocity or Vector3.zero

    local leadFactor = 0.12
    local predictedX = pos.X + (vel.X * leadFactor)
    local predictedZ = pos.Z + (vel.Z * leadFactor)

    local verticalOffset = 0
    if vel.Y > 1 then
        verticalOffset = 1.25 + (vel.Y * 0.08)
    elseif vel.Y < -1 then
        verticalOffset = -0.5
    end

    return Vector3.new(predictedX, pos.Y + verticalOffset, predictedZ)
end

-- =============================================================================
-- PART 7: SMOOTH UNDER-MAP MOTION LOGIC
-- =============================================================================
local function travelSmoothUnderMap(targetPart, timeoutDuration)
    if not isPlayerReady() or not targetPart or not targetPart.Parent or not targetPart:IsDescendantOf(Workspace) then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    timeoutDuration = timeoutDuration or 2.5
    local startTime = os.clock()
    local targetPosition = targetPart.Position
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = CFrame.new(root.Position.X, targetPosition.Y + _G.UnderMapOffset, root.Position.Z)
    end)

    local targetUnderPos = Vector3.new(targetPosition.X, targetPosition.Y + _G.UnderMapOffset, targetPosition.Z)
    
    while (_G.MasterCoinFarmActive or _G.MasterCombatActive) and isPlayerReady() do
        if not targetPart or not targetPart.Parent or not targetPart:IsDescendantOf(Workspace) then return false end
        if (os.clock() - startTime) >= timeoutDuration then return false end

        local currentPos = root.Position
        local distanceVector = targetUnderPos - currentPos
        local distance = distanceVector.Magnitude

        if distance < 4 then break end 

        local moveDirection = distanceVector.Unit
        local dt = RunService.Heartbeat:Wait()
        local nextPosition = currentPos + (moveDirection * (_G.FarmSpeed * dt))
        
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(nextPosition)
        end)
    end

    if isPlayerReady() and (_G.MasterCoinFarmActive or _G.MasterCombatActive) and root and root.Parent and targetPart and targetPart.Parent and targetPart:IsDescendantOf(Workspace) then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            character:PivotTo(targetPart.CFrame)
        end)
        return true
    end
    return false
end

local function staySafelyUnderMap()
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and isPlayerReady() then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = CFrame.new(root.Position.X, _G.UnderMapOffset, root.Position.Z)
        end)
    end
end

local function instantCombatTP(targetCFrame)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not isPlayerReady() then return end
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = targetCFrame
    end)
end

local lastMapName = ""
local function checkMapReset()
    local normalMap = Workspace:FindFirstChild("Normal")
    local mapFolder = normalMap and normalMap:FindFirstChild("Map")
    if mapFolder then
        local currentMap = mapFolder:FindFirstChildOfClass("Model")
        if currentMap and currentMap.Name ~= lastMapName then
            lastMapName = currentMap.Name
            _G.LuaxCollectedCache = {} 
            _G.BlacklistedCoins = {}
            currentActiveCoinTarget = nil
        end
    end
end

-- =============================================================================
-- PART 8: MACHINE LOOP AUTOMATION & TOGGLES
-- =============================================================================
local lastSpamTpTime = 0
local isEngineRunning = false

local function executeSheriffHuntingLogic()
    local activeGun = forceEquipWeapon("Gun")
    if not activeGun then return end
    
    for _, enemy in ipairs(Players:GetPlayers()) do
        if enemy ~= player and enemy.Parent and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            if getPlayerRole(enemy) == "Murderer" then
                local enemyHum = enemy.Character:FindFirstChildOfClass("Humanoid")
                if enemyHum and enemyHum.Health > 0 then
                    local enemyRoot = enemy.Character.HumanoidRootPart
                    local enemyHead = enemy.Character:FindFirstChild("Head") or enemyRoot

                    updateStatus("Bag Full! Sheriff Engaging Murderer: " .. enemy.Name)

                    local now = os.clock()
                    if now - lastSpamTpTime >= 0.25 then
                        lastSpamTpTime = now
                        local targetCFrame = enemyRoot.CFrame * CFrame.new(0, _G.HoverHeight, _G.SheriffOffsetDistance)
                        instantCombatTP(CFrame.lookAt(targetCFrame.Position, enemyRoot.Position))
                    end

                    if isWindowFocused then
                        if camera and enemyHead and enemyHead.Parent then
                            local predictedPos = getPredictedTargetPosition(enemyHead)
                            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, predictedPos)
                        end
                        player.CameraMode = Enum.CameraMode.LockFirstPerson
                    else
                        player.CameraMode = Enum.CameraMode.Classic
                    end

                    activeGun:Activate()
                    task.wait(0.03)
                    return true
                end
            end
        end
    end
    return false
end

local function runMasterAutomationEngine()
    if isEngineRunning then return end
    isEngineRunning = true
    enableNoclip()
    
    while _G.MasterCoinFarmActive or _G.MasterCombatActive do
        task.wait()
        
        if not isPlayerReady() then 
            updateStatus("Waiting / In Lobby...")
            currentActiveCoinTarget = nil
            task.wait(0.5)
            continue 
        end
        checkMapReset()

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local playerPos = root.Position

        local droppedGun = findGunDrop()
        local activeGun = forceEquipWeapon("Gun")
        local activeKnife = forceEquipWeapon("Knife")
        local insideActiveCombat = (activeGun ~= nil or activeKnife ~= nil)
        local isSheriffRole = hasWeaponCarried("Gun")

        applyZoomOverride(insideActiveCombat)

        if _G.MasterCombatActive and insideActiveCombat then
            if activeGun then
                local murdererFound = false
                for _, enemy in ipairs(Players:GetPlayers()) do
                    if enemy ~= player and enemy.Parent and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
                        if getPlayerRole(enemy) == "Murderer" then
                            local enemyHum = enemy.Character:FindFirstChildOfClass("Humanoid")
                            if enemyHum and enemyHum.Health > 0 then
                                murdererFound = true
                                local enemyRoot = enemy.Character.HumanoidRootPart
                                local enemyHead = enemy.Character:FindFirstChild("Head") or enemyRoot

                                updateStatus("Engaging Murderer: " .. enemy.Name)

                                local now = os.clock()
                                if now - lastSpamTpTime >= 0.25 then
                                    lastSpamTpTime = now
                                    local targetCFrame = enemyRoot.CFrame * CFrame.new(0, _G.HoverHeight, _G.SheriffOffsetDistance)
                                    instantCombatTP(CFrame.lookAt(targetCFrame.Position, enemyRoot.Position))
                                end

                                if isWindowFocused then
                                    if camera and enemyHead and enemyHead.Parent then
                                        local predictedPos = getPredictedTargetPosition(enemyHead)
                                        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, predictedPos)
                                    end
                                    player.CameraMode = Enum.CameraMode.LockFirstPerson
                                else
                                    player.CameraMode = Enum.CameraMode.Classic
                                end

                                activeGun:Activate()
                                task.wait(0.03)
                                break
                            end
                        end
                    end
                end
                if not murdererFound then
                    disableFirstPersonLock()
                    updateStatus("Searching for Murderer...")
                    task.wait(0.1)
                end

            elseif activeKnife then
                local nearestEnemy = getNearestMapTarget()
                if nearestEnemy and nearestEnemy.Parent and nearestEnemy.Character then
                    local enemyHum = nearestEnemy.Character:FindFirstChildOfClass("Humanoid")
                    local enemyRoot = nearestEnemy.Character:FindFirstChild("HumanoidRootPart")
                    
                    if enemyHum and enemyHum.Health > 0 and enemyRoot and enemyRoot.Parent then
                        updateStatus("Eliminating: " .. nearestEnemy.Name)

                        local now = os.clock()
                        if now - lastSpamTpTime >= 0.25 then
                            lastSpamTpTime = now
                            instantCombatTP(enemyRoot.CFrame * CFrame.new(0, _G.HoverHeight, 2))
                        end

                        if isWindowFocused then
                            if camera and enemyRoot and enemyRoot.Parent then
                                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, enemyRoot.Position)
                            end
                        else
                            player.CameraMode = Enum.CameraMode.Classic
                        end

                        activeKnife:Activate()

                        if firetouchinterest then
                            local knifeHandle = activeKnife:FindFirstChild("Handle")
                            if knifeHandle then
                                pcall(function()
                                    firetouchinterest(knifeHandle, enemyRoot, 0)
                                    task.wait(0.01)
                                    firetouchinterest(knifeHandle, enemyRoot, 1)
                                end)
                            end
                        end
                        task.wait(0.05)
                    else
                        task.wait(0.1)
                    end
                else
                    updateStatus("Combat Active - Searching...")
                    task.wait(0.1)
                end
            end

        elseif _G.MasterCoinFarmActive then
            disableFirstPersonLock()
            local bagFull = isCoinBagFull()
            
            if bagFull and isSheriffRole then
                local targetFound = executeSheriffHuntingLogic()
                if not targetFound then
                    updateStatus("Bag Full (Sheriff)! Hunting Murderer...")
                    staySafelyUnderMap()
                    task.wait(0.2)
                end
            else
                local targetCoin = findNextCoinVisual(playerPos)

                if bagFull or not targetCoin then
                    currentActiveCoinTarget = nil
                    if droppedGun and not activeGun then
                        updateStatus("Bag Limit reached! Fetching dropped gun...")
                        travelSmoothUnderMap(droppedGun, 2.0)
                        task.wait(0.05)
                        activeGun = forceEquipWeapon("Gun")
                    else
                        if bagFull then
                            updateStatus("Bag capacity reached! Safe under map.")
                        else
                            updateStatus("No safe coins tracked nearby!")
                        end
                        staySafelyUnderMap()
                        task.wait(0.5)
                    end
                else
                    currentActiveCoinTarget = targetCoin
                    updateStatus("Collecting: " .. targetCoin.Name)
                    
                    local success = travelSmoothUnderMap(targetCoin, 2.0)
                    if success and targetCoin and targetCoin.Parent and targetCoin:IsDescendantOf(Workspace) then
                        _G.LuaxCollectedCache[targetCoin] = true
                        removeHighlight(targetCoin)
                        
                        if firetouchinterest and root and root.Parent then
                            pcall(function()
                                firetouchinterest(root, targetCoin, 0)
                                task.wait(0.02)
                                firetouchinterest(root, targetCoin, 1)
                            end)
                        end
                        
                        if _G.PacingDelay and _G.PacingDelay > 0 then
                            task.wait(_G.PacingDelay)
                        end
                    else
                        _G.BlacklistedCoins[targetCoin] = true
                        removeHighlight(targetCoin)
                    end
                end
            end
        end
    end
    
    currentActiveCoinTarget = nil
    disableFirstPersonLock()
    updateStatus("Idle")
    applyZoomOverride(false)
    disableNoclip()
    isEngineRunning = false
end

task.spawn(function()
    while true do
        task.wait(1.0)
        if (_G.MasterCoinFarmActive or _G.MasterCombatActive) and not isEngineRunning then
            task.spawn(runMasterAutomationEngine)
        end
    end
end)

CoinBtn.MouseButton1Click:Connect(function()
    _G.MasterCoinFarmActive = not _G.MasterCoinFarmActive
    if _G.MasterCoinFarmActive then
        CoinBtn.Text = "Universal Coin Farm: ENABLED"
        CoinBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 35)
        CoinBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        task.spawn(runMasterAutomationEngine)
    else
        CoinBtn.Text = "Universal Coin Farm: DISABLED"
        CoinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        CoinBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        if not _G.MasterCombatActive then
            updateStatus("Idle")
        end
    end
end)

CombatBtn.MouseButton1Click:Connect(function()
    _G.MasterCombatActive = not _G.MasterCombatActive
    if _G.MasterCombatActive then
        CombatBtn.Text = "Autonomous Combat / Aim: ENABLED"
        CombatBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 35)
        CombatBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
        task.spawn(runMasterAutomationEngine)
    else
        CombatBtn.Text = "Autonomous Combat / Aim: DISABLED"
        CombatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        CombatBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        if not _G.MasterCoinFarmActive then
            updateStatus("Idle")
        end
    end
end)

HitboxBtn.MouseButton1Click:Connect(function()
    _G.HitboxExpanderActive = not _G.HitboxExpanderActive
    if _G.HitboxExpanderActive then
        HitboxBtn.Text = "Hitbox Expander: ENABLED"
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 35)
        HitboxBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        HitboxBtn.Text = "Hitbox Expander: DISABLED"
        HitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        HitboxBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

local uiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        local targetSize = uiVisible and UDim2.new(0, 420, 0, 680) or UDim2.new(0, 420, 0, 0)
        TweenService:Create(Frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    end
end)
