local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundEndFade: RemoteEvent = ReplicatedStorage.Remotes.Gameplay.RoundEndFade
local CoinCollected: RemoteEvent = ReplicatedStorage.Remotes.Gameplay.CoinCollected
local CoinsStarted: RemoteEvent = ReplicatedStorage.Remotes.Gameplay.CoinsStarted

local coinContainer
local stop = false
local lostCoinCount = 0
local lastCoin
local tries = 0
local enabled = false
local canCollect = true
local tpCooldown = tick()

local function getRootPart()
    if not game.Players.LocalPlayer.Character then return end
    if not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    return game.Players.LocalPlayer.Character.HumanoidRootPart
end

local function tween(pos)
    local rootPart = getRootPart()

    if not rootPart then return end

    local distance = (rootPart.Position - pos).Magnitude

    local tween = TweenService:Create(rootPart, TweenInfo.new(distance / 22, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    game.Players.LocalPlayer.Character.Humanoid:ChangeState(6)
    tween:Play()
    return tween
end

local function tp(pos)
    repeat task.wait() until tick() >= tpCooldown

    local rootPart = getRootPart()

    if not rootPart then return end

    rootPart.CFrame = CFrame.new(pos)

    tpCooldown = tick() + 5

    wait(0.5)
end

local function getClosestCoin()
    local coins = coinContainer:GetChildren()
    local rootPart = getRootPart()
    local closestDistance
    local closestCoin = {}

    if not rootPart then return end

    for i,v in pairs(coins) do
        if v:FindFirstChild("CoinVisual") and v.CoinVisual.Transparency == 0 then
            local distance = (rootPart.Position -  v.Position).Magnitude

            if not closestDistance or distance < closestDistance then
                closestDistance = distance
                closestCoin = v
            end
        end
    end

    return closestCoin, closestDistance and closestDistance > 100
end

-- Coin Container checker
task.spawn(function()
    while not stop do
        if not coinContainer then
            coinContainer = workspace:FindFirstChild("CoinContainer", true)
        else
            coinContainer.Destroying:Wait()
            coinContainer = nil
        end
    
        task.wait(1)
    end
end)

-- Main loop
task.spawn(function()
    while not stop do
        if coinContainer and canCollect and enabled then
            local closestCoin, isFar = getClosestCoin()

            if lastCoin == closestCoin then
                tries += 1
            else
                tries = 0
            end

            lastCoin = closestCoin
    
            if closestCoin and closestCoin.Position then
                if tries >= 10 then
                    closestCoin.CoinVisual.Transparency = 0.01
                end
                if not isFar then
                    local t: Tween = tween(closestCoin.Position + Vector3.new(0, 3.15, 0))
                    repeat task.wait(0.1) until t.PlaybackState ~= Enum.PlaybackState.Playing or closestCoin.CoinVisual.Transparency ~= 0 or getClosestCoin() ~= closestCoin
                    if t.PlaybackState == Enum.PlaybackState.Playing then
                        lostCoinCount += 1
                    end
                    t:Cancel()
                else
                    tp(closestCoin.Position + Vector3.new(0, 3.15, 0))
                    task.wait(1)
                end
            end

            if lostCoinCount >= 5 then
                local coins = coinContainer:GetChildren()
                tp(coins[math.random(1, #coins)].Position + Vector3.new(0, 3.15, 0))
                lostCoinCount = 0
            end
        end

        task.wait(0.1)
    end
end)

-- Lost coins count reset
task.spawn(function()
    while not stop do
        lostCoinCount = 0
        task.wait(10)
    end
end)

CoinCollected.OnClientEvent:Connect(function(coinType, collected, max)
    if collected == max then
        canCollect = false
        game.Players.LocalPlayer.Character.Humanoid.Health = 0
    end
end)

RoundEndFade.OnClientEvent:Connect(function()
    canCollect = false
end)

CoinsStarted.OnClientEvent:Connect(function()
    if enabled then
        canCollect = true
    end
end)

game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function()
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/0xSteak/autofarm/refs/heads/main/main.lua"))()')
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "a"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.new(1, 0, 0)
ToggleButton.BorderColor3 = Color3.new(0, 0, 0)
ToggleButton.Size = UDim2.fromOffset(25, 25)
ToggleButton.Position = UDim2.new(0, 0, 0, 0)
ToggleButton.Text = ""
ToggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        ToggleButton.BackgroundColor3 = Color3.new(0, 1, 0)
    else
        ToggleButton.BackgroundColor3 = Color3.new(1, 0, 0)
    end
end)

shared.stop = function() stop = true end