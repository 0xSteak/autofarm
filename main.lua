repeat wait() until game:IsLoaded()

local runArgs = {...}

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
local enabled = runArgs[1] and true or false
local canCollect = true
local tpCooldown = tick()
local coinBag

local safePart = Instance.new("Part")
safePart.Parent = workspace
safePart.CanCollide = true
safePart.Transparency = 1
safePart.Anchored = true
safePart.Size = Vector3.new(10, 1, 10)
safePart.Position = Vector3.zero

local function getRootPart()
    if not game.Players.LocalPlayer.Character then return end
    if not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    return game.Players.LocalPlayer.Character.HumanoidRootPart
end

local function tween(pos)
    local rootPart = getRootPart()

    if not rootPart then return end

    local distance = (rootPart.Position - pos).Magnitude

    local tween = TweenService:Create(rootPart, TweenInfo.new(distance / 26, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
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

local function getMurderer()
    if workspace:FindFirstChild("Barn") then return end
    for i,v in pairs(game.Players:GetPlayers()) do
        if v.Backpack:FindFirstChild("Knife") or v.Character and v.Character:FindFirstChild("Knife") then
            return v.Character
        end
    end
end

local function checkGun()
    local character = game.Players.LocalPlayer.Character
    local gun = character and character:FindFirstChild("Gun") or game.Players.LocalPlayer.Backpack:FindFirstChild("Gun")
    return gun
end

local function shootMurderer()
    local character = game.Players.LocalPlayer.Character
    local gun = character and character:FindFirstChild("Gun") or game.Players.LocalPlayer.Backpack:FindFirstChild("Gun")
    if character and gun then
        if gun.Parent.Name == "Backpack" then
            gun.Parent = character
        end

        local murderer = getMurderer()

        if not murderer then return end

        local murdRootPart = murderer.HumanoidRootPart
        local murdLookVector = murdRootPart.CFrame.LookVector

        local oldPos = character.HumanoidRootPart.CFrame

        character.HumanoidRootPart.CFrame = CFrame.new(murdRootPart.Position - (murdLookVector * 5), murdRootPart.Position)
        
        task.wait(0.2)

        local aimPos

        if murderer.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            aimPos = murderer.RightLowerLeg.CFrame
        elseif murderer.Humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            aimPos = murderer.Head.CFrame
        else
            aimPos = murdRootPart.CFrame
        end

        task.spawn(function()
            gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, (aimPos + (murderer.Humanoid.MoveDirection * murderer.Humanoid.WalkSpeed) / 16).Position, "AH2")
        end)

        task.wait(0.2)

        character.HumanoidRootPart.CFrame = oldPos
    end
end

local function pickGun()
    local gunDrop = workspace:FindFirstChild("GunDrop", true)
    if gunDrop and gunDrop.Parent:FindFirstChild("CoinContainer") and getRootPart() then
        local oldPos = getRootPart().CFrame
        getRootPart().CFrame = CFrame.new(gunDrop.Position)
        task.wait(0.1)
        getRootPart().CFrame = oldPos
    end
end

local function murdKillAll()
    local knife = game.Players.LocalPlayer.Backpack:FindFirstChild("Knife") or game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Knife")
    if knife then
        knife.Parent = game.Players.LocalPlayer.Character
        for i,v in pairs(game.Players:GetPlayers()) do
            if v.Name ~= game.Players.LocalPlayer.Name and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = v.Character:FindFirstChild("HumanoidRootPart")
                knife.Stab:FireServer("Down")
                task.wait()
                task.spawn(function()
                    firetouchinterest(rootPart, knife.Handle, 0)
                    firetouchinterest(rootPart, knife.Handle, 1)
                end)
            end
        end
    else
        return 0
    end
end

local function getAllInfected()
    local infected = {}
    for i,v in pairs(game.Players:GetPlayers()) do
        if v.Name ~= game.Players.LocalPlayer.Name then
            if v.Backpack:FindFirstChild("Knife") or v.Character and v.Character:FindFirstChild("Knife") then
                table.insert(infected, v)
            end
        end
    end
    return infected
end

local function endRound()
    if workspace:FindFirstChild("Barn") then
        if game.Players.LocalPlayer.Backpack:FindFirstChild("Knife") or game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Knife") then
            repeat
                task.wait(1)
            until murdKillAll() == 0
        else
            repeat
                local infected = getAllInfected()
                if infected.Character and infected.Character:FindFirstChild("HumanoidRootPart") and getRootPart() then
                    local rootPart = infected.Character.HumanoidRootPart
                    getRootPart().CFrame = CFrame.new(rootPart.Position + rootPart.CFrame.LookVector * 5)
                    task.wait(5)
                end
                task.wait()
            until game.Players.LocalPlayer.Backpack:FindFirstChild("Knife") or game.Players.LocalPlayer.Character:FindFirstChild("Knife") or not workspace:FindFirstChild("Barn")
            murdKillAll()
        end
        return
    end

    if not checkGun() then
        pickGun()
        task.wait(0.5)
    end

    local gun = checkGun()

    if gun and getMurderer() then
        tp(safePart.Position + Vector3.new(0, 3, 0))
        task.wait(0.1)
        repeat shootMurderer() task.wait(3) until not getMurderer()
    else
        game.Players.LocalPlayer.Character.Humanoid.Health = 0
    end
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
        pcall(function()
            if coinContainer and canCollect and enabled then
                local closestCoin, isFar = getClosestCoin()
    
                --[[if lastCoin == closestCoin then
                    tries += 1
                else
                    tries = 0
                end]]
    
                lastCoin = closestCoin
        
                if closestCoin and closestCoin.Position then
                    local coinBag2 = coinBag
                    --[[if tries >= 10 then
                        closestCoin.CoinVisual.Transparency = 0.01
                    end]]
                    if not isFar then
                        local t: Tween = tween(closestCoin.Position + Vector3.new(0, 3.15, 0))
                        repeat task.wait(0.1) until t.PlaybackState ~= Enum.PlaybackState.Playing or closestCoin and closestCoin:FindFirstChild("CoinVisual") and closestCoin.CoinVisual.Transparency ~= 0 or getClosestCoin() ~= closestCoin
                        if t.PlaybackState == Enum.PlaybackState.Playing then
                            lostCoinCount += 1
                        else
                            task.delay(game.Players.LocalPlayer:GetNetworkPing() + 0.1, function()
                                if coinBag == coinBag2 then
                                    lostCoinCount += 1
                                end
                            end)
                        end
                        t:Cancel()
                    else
                        tp(closestCoin.Position + Vector3.new(0, 5, 0))
                    end
                end
    
                if lostCoinCount >= 5 then
                    local coins = coinContainer:GetChildren()
                    tp(coins[math.random(1, #coins)].Position + Vector3.new(0, 5, 0))
                    lostCoinCount = 0
                end
    
                if closestCoin and closestCoin:FindFirstChild("CoinVisual") then
                    closestCoin.CoinVisual.Transparency = 0.01
                end
                task.delay(1, function()
                    if closestCoin and closestCoin:FindFirstChild("CoinVisual") and closestCoin.CoinVisual.Transparency == 0.01 then
                        closestCoin.CoinVisual.Transparency = 0
                    end
                end)
            end
        end)

        task.wait(0.1)
    end
end)

-- Lost coins count reset
task.spawn(function()
    while not stop do
        lostCoinCount = 0
        task.wait(20)
    end
end)

CoinCollected.OnClientEvent:Connect(function(coinType, collected, max)
    coinBag = collected
    if collected == max then
        coinBag = 0
        canCollect = false
        if shared.noReset then tp(safePart.Position + Vector3.new(0, 3, 0)) return end
        endRound()
    end
end)

RoundEndFade.OnClientEvent:Connect(function()
    canCollect = false
end)

CoinsStarted.OnClientEvent:Connect(function()
    canCollect = true
end)

game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function()
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/0xSteak/autofarm/refs/heads/main/main.lua"))(true)')
    game:GetService("TeleportService").TeleportInitFailed:Connect(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end)
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "a"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false
local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = enabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
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

game.Players.LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)

shared.stop = function() stop = true end

task.wait(20)

if game.Players.LocalPlayer.PlayerGui:FindFirstChild("Loading") then
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/0xSteak/autofarm/refs/heads/main/main.lua"))(true)')
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

