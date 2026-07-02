-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local AimSettings = {
    Enabled = true,
    Smoothing = 0.5,
    FieldOfView = 400,
    TargetPart = "Head", 
    IsAiming = false,
    ShowFOV = false,
    TeamCheck = true,
    WallCheck = true,
    Prediction = true,
    PredictionFactor = 1,
    BulletDropPrediction = true,
    AutoDetectStats = true,
    BulletVelocity = 1000, 
    Drag = 0,             
    BulletGravity = Workspace.Gravity,
    ZoomFOV = 30,
    DefaultFOV = 70
}

local VisualSettings = {
    ESPEnabled = true,
    Highlight = true,
    Skeleton = true,
    Tracers = false,
    Names = true,
    Distance = true,
    AimMarker = true,
    ShowTargetHUD = true,
    Color = Color3.fromRGB(255, 255, 255),
    Rainbow = false,
    
    -- Visual Effects Variables
    WeaponEffect = false,
    ArmsEffect = false,
    EffectMode = "Rainbow"
}

-- Drawing Objects
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(200, 200, 200)
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 0.3
FOVCircle.Visible = AimSettings.ShowFOV
FOVCircle.Radius = AimSettings.FieldOfView

local AimMarkerLines = {Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line")}
for _, line in pairs(AimMarkerLines) do line.Thickness = 1; line.Transparency = 0.8; line.Visible = false end

local TargetHUD = {Bg = Drawing.new("Square"), Bar = Drawing.new("Square"), Text = Drawing.new("Text")}
TargetHUD.Bg.Color = Color3.fromRGB(40, 40, 40); TargetHUD.Bg.Filled = true; TargetHUD.Bg.Visible = false
TargetHUD.Bar.Color = Color3.fromRGB(255, 255, 255); TargetHUD.Bar.Filled = true; TargetHUD.Bar.Visible = false
TargetHUD.Text.Size = 16; TargetHUD.Text.Center = true; TargetHUD.Text.Outline = true; TargetHUD.Text.Visible = false

-- ESP & Highlight Management
local espObjects = {}
local jointConnections = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local function CreateESP(player)
    local esp = {
        Highlight = Instance.new("Highlight"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Skeleton = {}
    }
    
    esp.Highlight.FillTransparency = 1
    esp.Highlight.OutlineTransparency = 0
    esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    esp.Highlight.Parent = game.CoreGui
    
    esp.Name.Center = true; esp.Name.Size = 13; esp.Name.Font = 2; esp.Name.Outline = true
    esp.Tracer.Thickness = 1; esp.Tracer.Transparency = 0.4
    
    for _, jointPair in pairs(jointConnections) do
        local line = Drawing.new("Line"); line.Thickness = 1; line.Transparency = 0.5
        esp.Skeleton[jointPair[1] .. jointPair[2]] = line
    end
    espObjects[player] = esp
end

local function RemoveESP(player)
    if espObjects[player] then
        espObjects[player].Highlight:Destroy()
        espObjects[player].Name:Remove()
        espObjects[player].Tracer:Remove()
        for _, line in pairs(espObjects[player].Skeleton) do line:Remove() end
        espObjects[player] = nil
    end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, player in pairs(Players:GetPlayers()) do if player ~= LocalPlayer then CreateESP(player) end end

------------------------------------------------------------------------
-- UI Initialization (New UI Library)
------------------------------------------------------------------------
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheSancheziunblocker/Milenium/refs/heads/main/Mainui.lua", true))()

UILib.SetTitle("PIPELINE.AIM")

-- ==================== AIMBOT CATEGORY ====================
local CatAimbot = UILib.AddCategory({Name = "Aimbot", Image = 6031280882})
local GeneralTab = CatAimbot:AddTab("General")

-- Aimbot Card
local aimCard = GeneralTab:AddCard(1, "Aimbot")
aimCard:AddToggle({Label = "Enable Aimbot", Default = true,
    Callback = function(v) AimSettings.Enabled = v end})
aimCard:AddDropdown({Label = "Target Part",
    Options = {"Head", "Torso"}, Default = "Head",
    Callback = function(v) AimSettings.TargetPart = v end})
aimCard:AddToggle({Label = "Team Check", Default = true,
    Callback = function(v) AimSettings.TeamCheck = v end})
aimCard:AddToggle({Label = "Wall Check", Default = true,
    Callback = function(v) AimSettings.WallCheck = v end})
aimCard:AddSlider({Label = "Aim Smoothing", Min = 0, Max = 1, Default = 0.5, Decimals = 2,
    Callback = function(v) AimSettings.Smoothing = v end})

-- FOV Card
local fovCard = GeneralTab:AddCard(2, "FOV")
fovCard:AddToggle({Label = "Show FOV Circle", Default = false,
    Callback = function(v) AimSettings.ShowFOV = v; FOVCircle.Visible = v end})
fovCard:AddSlider({Label = "FOV Radius", Min = 50, Max = 1000, Default = 400, Decimals = 0,
    Callback = function(v) AimSettings.FieldOfView = v; FOVCircle.Radius = v end})

-- ==================== VISUALS CATEGORY ====================
local CatVisuals = UILib.AddCategory({Name = "Visuals", Image = 6031280883})
local ESPTab = CatVisuals:AddTab("ESP")

-- ESP Card
local espCard = ESPTab:AddCard(1, "ESP")
espCard:AddToggle({Label = "Enable ESP", Default = true,
    Callback = function(v) VisualSettings.ESPEnabled = v end})
espCard:AddToggle({Label = "Highlight Outline", Default = true,
    Callback = function(v) VisualSettings.Highlight = v end})
espCard:AddToggle({Label = "Skeleton ESP", Default = true,
    Callback = function(v) VisualSettings.Skeleton = v end})
espCard:AddToggle({Label = "Names", Default = true,
    Callback = function(v) VisualSettings.Names = v end})
espCard:AddToggle({Label = "Distance", Default = true,
    Callback = function(v) VisualSettings.Distance = v end})
espCard:AddToggle({Label = "Tracers", Default = false,
    Callback = function(v) VisualSettings.Tracers = v end})
espCard:AddDropdown({Label = "ESP Color Theme",
    Options = {"White", "Rainbow", "Cyber Purple", "Neon Green", "Fire Orange"}, Default = "White",
    Callback = function(v)
        VisualSettings.Rainbow = false
        if v == "White" then VisualSettings.Color = Color3.fromRGB(255, 255, 255)
        elseif v == "Rainbow" then VisualSettings.Rainbow = true
        elseif v == "Cyber Purple" then VisualSettings.Color = Color3.fromRGB(187, 0, 255)
        elseif v == "Neon Green" then VisualSettings.Color = Color3.fromRGB(0, 255, 100)
        elseif v == "Fire Orange" then VisualSettings.Color = Color3.fromRGB(255, 100, 0)
        end
    end})

-- Effects Tab
local EffectsTab = CatVisuals:AddTab("Effects")
local effectsCard = EffectsTab:AddCard(1, "Visual Effects")
effectsCard:AddToggle({Label = "Weapon Forcefield", Default = false,
    Callback = function(v) VisualSettings.WeaponEffect = v end})
effectsCard:AddToggle({Label = "Arms Forcefield", Default = false,
    Callback = function(v) VisualSettings.ArmsEffect = v end})
effectsCard:AddDropdown({Label = "Effect Mode",
    Options = {"Rainbow", "Cyber Green", "Purple", "Fire Orange"}, Default = "Rainbow",
    Callback = function(v) VisualSettings.EffectMode = v end})

------------------------------------------------------------------------
-- Aimbot Logic Function
------------------------------------------------------------------------
local function IsVisible(part)
    if not AimSettings.WallCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, raycastParams)
    return result and (result.Instance:IsDescendantOf(part.Parent) or result.Instance.Parent:IsDescendantOf(part.Parent))
end

local function GetClosestPlayer()
    local ClosestPlayer = nil
    local SmallestDistance = AimSettings.FieldOfView
    local MousePos = UserInputService:GetMouseLocation()

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            if AimSettings.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            local RootPart = Player.Character.HumanoidRootPart
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            if OnScreen then
                local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                if Distance < SmallestDistance then
                    ClosestPlayer = Player
                    SmallestDistance = Distance
                end
            end
        end
    end
    return ClosestPlayer
end

-- Forcefield Effect Management Cache
local ModifiedParts = {}

local function ApplyEffect(part, mode)
    if not part:IsA("BasePart") then return end
    
    if not ModifiedParts[part] then
        ModifiedParts[part] = {
            Material = part.Material,
            Color = part.Color,
            TextureID = (part:IsA("MeshPart") and part.TextureID) or nil
        }
        local specialMesh = part:FindFirstChildOfClass("SpecialMesh")
        if specialMesh then
            ModifiedParts[part].SpecialMesh = specialMesh
            ModifiedParts[part].SpecialMeshTexture = specialMesh.TextureId
        end
    end

    pcall(function()
        if part.Material ~= Enum.Material.ForceField then
            part.Material = Enum.Material.ForceField
        end
        
        if part:IsA("MeshPart") and part.TextureID ~= "" then
            part.TextureID = ""
        end
        local specialMesh = part:FindFirstChildOfClass("SpecialMesh")
        if specialMesh and specialMesh.TextureId ~= "" then
            specialMesh.TextureId = ""
        end

        if mode == "Rainbow" then
            part.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        elseif mode == "Cyber Green" then
            part.Color = Color3.fromRGB(0, math.floor(155 + 100 * math.sin(tick() * 3)), 0)
        elseif mode == "Purple" then
            part.Color = Color3.fromRGB(187, 0, 255)
        elseif mode == "Fire Orange" then
            part.Color = Color3.fromRGB(255, math.floor(100 + 50 * math.sin(tick() * 5)), 0)
        end
    end)
end

local function RevertPart(part)
    local data = ModifiedParts[part]
    if data then
        pcall(function()
            part.Material = data.Material
            part.Color = data.Color
            if data.TextureID and part:IsA("MeshPart") then
                part.TextureID = data.TextureID
            end
            if data.SpecialMesh then
                data.SpecialMesh.TextureId = data.SpecialMeshTexture
            end
        end)
        ModifiedParts[part] = nil
    end
end

-- Render Loop
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    -- Visual Effects Processing
    local activeEffectParts = {}
    
    if VisualSettings.WeaponEffect or VisualSettings.ArmsEffect then
        if LocalPlayer.Character then
            if VisualSettings.WeaponEffect then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    for _, v in pairs(tool:GetDescendants()) do
                        if v:IsA("BasePart") and (v.Transparency < 1 or v.LocalTransparencyModifier < 1) then
                            activeEffectParts[v] = true
                        end
                    end
                end
            end
            
            if VisualSettings.ArmsEffect then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") and (v.Transparency < 1 or v.LocalTransparencyModifier < 1) then
                        local nameLow = string.lower(v.Name)
                        if string.find(nameLow, "arm") or string.find(nameLow, "hand") then
                            activeEffectParts[v] = true
                        end
                    end
                end
            end
        end
        
        for _, v in pairs(Camera:GetDescendants()) do
            if v:IsA("BasePart") and (v.Transparency < 1 or v.LocalTransparencyModifier < 1) then
                local nameLow = string.lower(v.Name)
                local isArm = string.find(nameLow, "arm") or string.find(nameLow, "hand")
                
                if VisualSettings.ArmsEffect and isArm then
                    activeEffectParts[v] = true
                elseif VisualSettings.WeaponEffect and not isArm then
                    activeEffectParts[v] = true
                end
            end
        end
    end

    for part, _ in pairs(activeEffectParts) do
        ApplyEffect(part, VisualSettings.EffectMode)
    end

    for part, _ in pairs(ModifiedParts) do
        if typeof(part) ~= "Instance" or not part.Parent then
            ModifiedParts[part] = nil
        elseif not activeEffectParts[part] then
            RevertPart(part)
        end
    end

    -- Aimbot Processing: Using Camera CFrame manipulation for better reliability
    if AimSettings.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local Target = GetClosestPlayer()
        if Target and Target.Character then
            local PartName = (AimSettings.TargetPart == "Torso") and "UpperTorso" or "Head"
            local TargetPart = Target.Character:FindFirstChild(PartName) or Target.Character:FindFirstChild("Head")
            
            if TargetPart and IsVisible(TargetPart) then
                local TargetCFrame = CFrame.lookAt(Camera.CFrame.Position, TargetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, AimSettings.Smoothing)
            end
        end
    end
    
    if VisualSettings.Rainbow then VisualSettings.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end
    
    for player, esp in pairs(espObjects) do
        local char = player.Character
        -- Team Check Logic
        local isTeammate = (player.Team == LocalPlayer.Team)
        local isVisible = VisualSettings.ESPEnabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and not isTeammate
        
        if isVisible then
            esp.Highlight.Adornee = char
            esp.Highlight.OutlineColor = VisualSettings.Color
            esp.Highlight.Enabled = VisualSettings.Highlight
            
            local rootPart = char.HumanoidRootPart
            local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                if VisualSettings.Names or VisualSettings.Distance then
                    local dist = math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude)
                    local text = ""
                    if VisualSettings.Names then text = text .. player.Name end
                    if VisualSettings.Distance then text = text .. (VisualSettings.Names and " | " or "") .. dist .. "m" end
                    
                    esp.Name.Text = text
                    esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - 50)
                    esp.Name.Color = VisualSettings.Color; esp.Name.Visible = true
                else esp.Name.Visible = false end

                if VisualSettings.Tracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Tracer.Color = VisualSettings.Color; esp.Tracer.Visible = true
                else esp.Tracer.Visible = false end
                
                if VisualSettings.Skeleton then
                    for _, jointPair in pairs(jointConnections) do
                        local part1 = char:FindFirstChild(jointPair[1])
                        local part2 = char:FindFirstChild(jointPair[2])
                        local lineObj = esp.Skeleton[jointPair[1] .. jointPair[2]]
                        if part1 and part2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                            if vis1 and vis2 then
                                lineObj.From = Vector2.new(pos1.X, pos1.Y); lineObj.To = Vector2.new(pos2.X, pos2.Y)
                                lineObj.Color = VisualSettings.Color; lineObj.Visible = true
                            else lineObj.Visible = false end
                        else lineObj.Visible = false end
                    end
                else for _, lineObj in pairs(esp.Skeleton) do lineObj.Visible = false end end
            else esp.Name.Visible = false; esp.Tracer.Visible = false; for _, lineObj in pairs(esp.Skeleton) do lineObj.Visible = false end end
        else
            esp.Highlight.Adornee = nil
            esp.Highlight.Enabled = false
            esp.Name.Visible = false; esp.Tracer.Visible = false
            for _, lineObj in pairs(esp.Skeleton) do lineObj.Visible = false end
        end
    end
end)
