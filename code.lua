local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/cueshut/saves/main/criminality%20paste%20ui%20library'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local ESPEnabled = false
local AimbotEnabled = false
local AimbotTargetAllies = false
local FlyEnabled = false
local NoClipEnabled = false
local MaxAimbotDistance = 200 -- Limiter l'ESP à 200m
local AimbotFOV = 150
local AimbotSmoothness = 0.1

-- Visual Settings
local BoxColor = Color3.fromRGB(255, 0, 0) -- Default color for enemies (red)
local AllyColor = Color3.fromRGB(0, 255, 0) -- Default color for allies (green)
local NameColor = Color3.fromRGB(255, 255, 255) -- White for names
local DistanceColor = Color3.fromRGB(255, 255, 255) -- White for distance
local HealthColor = Color3.fromRGB(0, 255, 0) -- Health bar color (green)

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Radius = AimbotFOV
FOVCircle.Visible = true

-- UI Setup
local window = library.new('NyxWare.cc', 'NyxWare')
local tab = window.new_tab('rbxassetid://4483345998')

local sectionESP = tab.new_section('ESP')
local sectionAimbot = tab.new_section('Aimbot')

local sectorESP = sectionESP.new_sector('Visuals', 'Left')
local sectorAimbot = sectionAimbot.new_sector('Aim Settings', 'Right')

-- ESP Logic
local function CreateESP(Player)
    if Player == LocalPlayer then return end
    local Box, HealthBar, Name, DistanceLabel, Tracer = Drawing.new("Square"), Drawing.new("Line"), Drawing.new("Text"), Drawing.new("Text"), Drawing.new("Line")
    local BoxOutline = Drawing.new("Square")
    
    Box.Filled = false
    Box.Thickness = 2
    Box.Color = BoxColor
    
    BoxOutline.Filled = false
    BoxOutline.Thickness = 4
    BoxOutline.Color = Color3.fromRGB(0, 0, 0)

    Name.Size = 14
    Name.Color = NameColor
    Name.Center = true
    Name.Outline = true

    DistanceLabel.Size = 12
    DistanceLabel.Color = DistanceColor
    DistanceLabel.Center = true
    DistanceLabel.Outline = true

    HealthBar.Thickness = 2
    HealthBar.Color = HealthColor

    Tracer.Thickness = 1
    Tracer.Color = BoxColor
    
    RunService.RenderStepped:Connect(function()
        if not ESPEnabled or not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
            Box.Visible, BoxOutline.Visible, Name.Visible, DistanceLabel.Visible, HealthBar.Visible, Tracer.Visible = false, false, false, false, false, false
            return
        end

        local Root = Player.Character.HumanoidRootPart
        local Humanoid = Player.Character:FindFirstChild("Humanoid")
        local pos, visible = Camera:WorldToViewportPoint(Root.Position)

        if visible then
            local dist = math.floor((Root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
            if dist > MaxAimbotDistance then
                Box.Visible, BoxOutline.Visible, Name.Visible, DistanceLabel.Visible, HealthBar.Visible, Tracer.Visible = false, false, false, false, false, false
                return
            end

            local size = Vector2.new(100, 200)
            local posBox = Vector2.new(pos.X - 50, pos.Y - 100)
            Box.Position, Box.Size = posBox, size
            BoxOutline.Position, BoxOutline.Size = posBox, size
            Box.Visible, BoxOutline.Visible = true, true
            Box.Color = (Player.Team == LocalPlayer.Team) and AllyColor or BoxColor

            Name.Text = Player.Name
            Name.Position = Vector2.new(pos.X, pos.Y - 115)
            Name.Visible = true

            DistanceLabel.Text = tostring(dist) .. "m"
            DistanceLabel.Position = Vector2.new(pos.X, pos.Y - 130)
            DistanceLabel.Visible = true

            local hp = Humanoid.Health / Humanoid.MaxHealth
            HealthBar.From = Vector2.new(pos.X - 55, pos.Y + 100)
            HealthBar.To = Vector2.new(pos.X - 55, pos.Y + 100 - (200 * hp))
            HealthBar.Color = Color3.fromRGB(255 - (hp * 255), hp * 255, 0)
            HealthBar.Visible = true

            -- Tracer Logic
            Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            Tracer.To = Vector2.new(pos.X, pos.Y)
            Tracer.Visible = true

            -- Skeleton ESP Logic (lines from head to body parts)
            if Player.Character:FindFirstChild("Head") then
                local headPos, headVisible = Camera:WorldToViewportPoint(Player.Character.Head.Position)
                if headVisible then
                    local bodyParts = {"LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"}
                    for _, partName in ipairs(bodyParts) do
                        local part = Player.Character:FindFirstChild(partName)
                        if part then
                            local partPos, partVisible = Camera:WorldToViewportPoint(part.Position)
                            if partVisible then
                                local skeletonLine = Drawing.new("Line")
                                skeletonLine.From = Vector2.new(headPos.X, headPos.Y)
                                skeletonLine.To = Vector2.new(partPos.X, partPos.Y)
                                skeletonLine.Thickness = 1
                                skeletonLine.Color = BoxColor
                                skeletonLine.Visible = true
                            end
                        end
                    end
                end
            end
        else
            Box.Visible, BoxOutline.Visible, Name.Visible, DistanceLabel.Visible, HealthBar.Visible, Tracer.Visible = false, false, false, false, false, false
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- Aimbot Logic
local function GetClosestTarget()
    local MousePos = UserInputService:GetMouseLocation()
    local Closest, Shortest = nil, AimbotFOV
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local teamMatch = (AimbotTargetAllies and p.Team == LocalPlayer.Team) or (not AimbotTargetAllies and p.Team ~= LocalPlayer.Team)
            if teamMatch then
                local pos, visible = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - MousePos).Magnitude
                    if dist < Shortest and dist <= MaxAimbotDistance then
                        Shortest = dist
                        Closest = p.Character.Head
                    end
                end
            end
        end
    end
    return Closest
end

local function Aimbot()
    if AimbotEnabled then
        local Target = GetClosestTarget()
        if Target then
            local from = Camera.CFrame.Position
            local to = Target.Position
            local direction = (to - from).Unit
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(from, from + direction), AimbotSmoothness)
        end
    end
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    Aimbot()
end)

-- Inputs
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.H then
        FlyEnabled = not FlyEnabled
        while FlyEnabled do
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 50, 0)
            end
            task.wait(0.1)
        end
    elseif input.KeyCode == Enum.KeyCode.J then
        AimbotTargetAllies = not AimbotTargetAllies
    elseif input.KeyCode == Enum.KeyCode.A then
        NoClipEnabled = not NoClipEnabled
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = not NoClipEnabled end
        end
    elseif input.KeyCode == Enum.KeyCode.C then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Team ~= LocalPlayer.Team then
                LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
                break
            end
        end
    elseif input.KeyCode == Enum.KeyCode.X then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Team == LocalPlayer.Team then
                LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
                break
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Insert then  -- Touche Insert pour fermer l'UI
        window:Close()  -- Ferme la fenêtre de l'UI
    end
end)

-- UI Toggles
sectorESP.element('Toggle', 'Activer ESP', {default = false}, function(v)
    ESPEnabled = v.Toggle
end)

sectorAimbot.element('Toggle', 'Activer Aimbot', {default = false}, function(v)
    AimbotEnabled = v.Toggle
end)

sectorAimbot.element('Toggle', 'Viser Alliés', {default = false}, function(v)
    AimbotTargetAllies = v.Toggle
end)

sectorAimbot.element('Slider', 'FOV Aimbot', {default = {min = 50, max = 300, default = 150}}, function(v)
    AimbotFOV = v.Slider
    FOVCircle.Radius = AimbotFOV
end)

sectorAimbot.element('Slider', 'Lissage Aimbot', {default = {min = 0.01, max = 1, default = 0.1}}, function(v)
    AimbotSmoothness = v.Slider
end)

