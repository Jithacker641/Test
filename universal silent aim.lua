-- Note: Hookmetamethod support required.

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Skibidiware™", 
    Text = "Hotkey: E Toggle"
})

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera
local localPlayer = game.Players.LocalPlayer
local mouse = localPlayer:GetMouse()

local originalIndex
local isSilentAimActive = false
local target = nil
local line = nil
local targetScanCooldown = 0.1
local lastScanTime = 0

local function findClosestTarget()
    local mousePos = Camera:ViewportPointToRay(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    local closestTarget = nil
    local shortestDistance = math.huge

    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") then
            local targetPlayer = game.Players:GetPlayerFromCharacter(model)
            if targetPlayer and targetPlayer.Team == localPlayer.Team then
                continue
            end

            for _, part in pairs(model:GetChildren()) do
                if part:IsA("BasePart") and (part.Name == "Head" or part.Name == "Torso") then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestTarget = part
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

local function clearTarget()
    if line then
        line.Visible = false
    end
    target = nil
end

originalIndex = hookmetamethod(game, "__index", newcclosure(function(Self, Key)
    if Self:IsA("Mouse") and rawequal(Key, "Hit") then
        if isSilentAimActive and target then
            return CFrame.new(target.Position)
        end
    end
    return originalIndex(Self, Key)
end))

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        isSilentAimActive = not isSilentAimActive
        if not isSilentAimActive then
            clearTarget()
            print("deactivated")
        else
            print("activated")
        end
    end
end)

line = Drawing.new("Line")
line.Visible = false
line.Transparency = 1
line.Thickness = 2

local function getRainbowColor()
    local hue = (tick() / 5) % 1
    return Color3.fromHSV(hue, 1, 1)
end

RunService.RenderStepped:Connect(function(deltaTime)
    if isSilentAimActive then
        if os.clock() - lastScanTime >= targetScanCooldown then
            target = findClosestTarget()
            lastScanTime = os.clock()
            print("Updated target:", target and target.Name or "None")
        end

        if target then
            local worldPosition = target.Position
            local screenPosition, onScreen = Camera:WorldToViewportPoint(worldPosition)

            if onScreen then
                line.From = UserInputService:GetMouseLocation()
                line.To = Vector2.new(screenPosition.X, screenPosition.Y)
                line.Color = getRainbowColor()
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    else
        clearTarget()
    end
end)
