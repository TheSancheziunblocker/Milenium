-- =============================================================================
-- PIPELINE.AIM - Unified Game Script (Milenium UI) - OPTIMIZED ESP EDITION
-- FIXED EDITION: dead toggles implemented, floor-drop / spawn bug fixed
-- =============================================================================

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local activeNPCs = {}
local ammoCache = {}
local ammoSpreadCache = {}
local keypressCooldown = false
local ApplyAllSavedSettings
local AimIndicatorText     -- forward-declared, assigned in the UI section
local UpdateAimIndicator   -- forward-declared, assigned in the UI section

local function SendNotification(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title, Text = text, Duration = duration or 5
		})
	end)
end

-- ====================== SETTINGS CONFIGURATION ======================
local AimSettings = {
	Enabled = false, Smoothing = 0.5, FieldOfView = 90, TargetPart = "Head",
	ShowFOV = false, TeamCheck = true, WallCheck = true,
	Color = Color3.fromRGB(255, 255, 255)
}

local PlayerVisuals = {
	ESPEnabled = false, Skeleton = false, Tracers = false, Names = true,
	Distance = true, ShowClothing = true, HealthBar = true,
	Color = Color3.fromRGB(0, 255, 80),
	WhitelistColor = Color3.fromRGB(0, 180, 255),
	Rainbow = false, MaxDistance = 2000
}

local NpcVisuals = {
	ESPEnabled = false, Skeleton = false, Tracers = false, Names = true,
	Distance = true, HealthBar = true,
	Color = Color3.fromRGB(255, 60, 60),
	Rainbow = false, MaxDistance = 1500
}

local ContainerESP = {
	Enabled = false, ShowItems = true,
	Color = Color3.fromRGB(255, 215, 0),
	MaxItems = 5, MaxDistance = 500
}

local DroppedItemsESP = {
	Enabled = false, Color = Color3.fromRGB(0, 170, 255),
	ShowDistance = true, MaxDistance = 300
}

local CorpseESP = {
	Enabled = false, Color = Color3.fromRGB(200, 30, 30),
	ShowDistance = true, MaxDistance = 500
}

local EffectSettings = { WeaponEffect = false, ArmsEffect = false, EffectMode = "Rainbow" }

local WorldSettings = {
	Fullbright = false, NoFog = false, PlayerFOV = 70, ZoomFOV = 30,
	ZoomKey = Enum.KeyCode.Z, ShowWhitelistMenu = false, NoGrass = false,
	NoLeaves = false, NoClouds = false, SkyboxType = "Default",
	AmbientOverride = false, AmbientColor = Color3.fromRGB(129, 5, 255),
	RGBAmbient = false, RGBAmbientSpeed = 0.5
}

local ViewmodelSettings = {
	Enabled = false, Transparency = 0, Color = Color3.fromRGB(79, 155, 121),
	XOffset = 0, YOffset = 0, ZOffset = 0
}

-- Movement tab was removed. Only the two cross-tab features survive here:
--   InstantEquip -> Combat tab ("Instant Weapon Equip")
--   NoLandmines  -> World tab  ("Eradicate Landmines")
local MovementSettings = {
	InstantEquip = false,
	NoLandmines = false
}

local WeaponSettings = {
	NoRecoil = false, NoSpread = false, CustomHitSound = false,
	HitSoundID = "Rust", HitSoundVolume = 1
}

local UtilitySettings = {
	ModDetector = false, CheaterDetector = false, ItemFinder = false,
	ItemWhitelist = {}, ShowBossTracker = false, BossMovable = false,
	InventoryChecker = false, InvCheckerActive = false,
	InvCheckValue = false, InvCheckTarget = false
}

local Whitelist = {}
local Moderators = {}
local Cheaters = {}

local customHitSoundIDs = {
	Default = "rbxassetid://4585351098", Rust = "rbxassetid://1255040462",
	Gamesense = "rbxassetid://4817809188", Neverlose = "rbxassetid://8726881116",
	Bubble = "rbxassetid://198598793", Ding = "rbxassetid://2868331684",
	Bruh = "rbxassetid://4275842574", ["Windows XP"] = "rbxassetid://130840811",
	Discord = "rbxassetid://6501486918", TeamFortress = "rbxassetid://296102734",
	["CS 1.6"] = "rbxassetid://18362692980", Toilet = "rbxassetid://8430024127",
	FAAHH = "rbxassetid://72298953503422"
}

local skyboxPacks = {
	Default = {},
	["Orange Sunset"] = { SkyboxBk = "rbxassetid://458016711", SkyboxDn = "rbxassetid://458016826", SkyboxFt = "rbxassetid://458016532", SkyboxLf = "rbxassetid://458016655", SkyboxRt = "rbxassetid://458016782", SkyboxUp = "rbxassetid://458016792" },
	["Pink Sky"] = { SkyboxBk = "rbxassetid://271042516", SkyboxDn = "rbxassetid://271077243", SkyboxFt = "rbxassetid://271042556", SkyboxLf = "rbxassetid://271042310", SkyboxRt = "rbxassetid://271042467", SkyboxUp = "rbxassetid://271077958" },
	Night = { SkyboxBk = "rbxassetid://15470149279", SkyboxDn = "rbxassetid://15470151245", SkyboxFt = "rbxassetid://15470153860", SkyboxLf = "rbxassetid://15470155938", SkyboxRt = "rbxassetid://15470158022", SkyboxUp = "rbxassetid://15470160563" },
	["Galaxy Sky"] = { SkyboxBk = "rbxassetid://159454299", SkyboxDn = "rbxassetid://159454296", SkyboxFt = "rbxassetid://159454293", SkyboxLf = "rbxassetid://159454286", SkyboxRt = "rbxassetid://159454300", SkyboxUp = "rbxassetid://159454288" },
	["Purple Space Sky"] = { SkyboxBk = "rbxassetid://14543264135", SkyboxDn = "rbxassetid://14543358958", SkyboxFt = "rbxassetid://14543257810", SkyboxLf = "rbxassetid://14543275895", SkyboxRt = "rbxassetid://14543280890", SkyboxUp = "rbxassetid://14543371676" },
	["Spring Sky"] = { SkyboxBk = "rbxassetid://12216109205", SkyboxDn = "rbxassetid://12216109875", SkyboxFt = "rbxassetid://12216109489", SkyboxLf = "rbxassetid://12216110170", SkyboxRt = "rbxassetid://12216110471", SkyboxUp = "rbxassetid://12216108877" }
}

-- ====================== SYSTEM EFFECT RE-APPLIERS ======================
local function ApplyNoRecoil()
	local strength = WeaponSettings.NoRecoil and 0 or nil
	local ammoTypes = ReplicatedStorage:FindFirstChild("AmmoTypes")
	if ammoTypes then
		for _, ammo in ipairs(ammoTypes:GetChildren()) do
			if not ammoCache[ammo] then ammoCache[ammo] = ammo:GetAttribute("RecoilStrength") or 1 end
			ammo:SetAttribute("RecoilStrength", strength or ammoCache[ammo])
		end
	end
end

local function ApplyNoSpread()
	local ammoTypes = ReplicatedStorage:FindFirstChild("AmmoTypes")
	if ammoTypes then
		for _, ammo in ipairs(ammoTypes:GetChildren()) do
			if not ammoSpreadCache[ammo] then
				ammoSpreadCache[ammo] = {
					Accuracy = ammo:GetAttribute("AccuracyDeviation") or 0,
					Drop = ammo:GetAttribute("ProjectileDrop") or 0
				}
			end
			ammo:SetAttribute("AccuracyDeviation", WeaponSettings.NoSpread and 0 or ammoSpreadCache[ammo].Accuracy)
			ammo:SetAttribute("ProjectileDrop", WeaponSettings.NoSpread and 0 or ammoSpreadCache[ammo].Drop)
		end
	end
end

local function ApplyFoliageOverride()
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("SurfaceAppearance") and obj.Parent and obj.Parent.Name:lower():find("leaf") then
			obj.Parent.Transparency = WorldSettings.NoLeaves and 1 or 0
		end
	end
end

local function ApplyCloudsOverride()
	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then clouds.Enabled = not WorldSettings.NoClouds end
end

-- ====================== SAVE MANAGER ======================
local SaveManager = {}
SaveManager.SaveFile = "pipeline_aim_config.json"

function SaveManager:Save()
	pcall(function()
		local data = {
			AimSettings = AimSettings, PlayerVisuals = PlayerVisuals,
			NpcVisuals = NpcVisuals, ContainerESP = ContainerESP,
			DroppedItemsESP = DroppedItemsESP, CorpseESP = CorpseESP,
			EffectSettings = EffectSettings, WorldSettings = WorldSettings,
			ViewmodelSettings = ViewmodelSettings, MovementSettings = MovementSettings,
			WeaponSettings = WeaponSettings, UtilitySettings = UtilitySettings,
			Whitelist = Whitelist
		}
		local json = HttpService:JSONEncode(data)
		if writefile then writefile(self.SaveFile, json)
		else LocalPlayer:SetAttribute("PipelineAimData", json) end
	end)
end

function SaveManager:Load()
	local success = pcall(function()
		local json = nil
		if readfile and isfile and isfile(self.SaveFile) then json = readfile(self.SaveFile)
		elseif LocalPlayer:GetAttribute("PipelineAimData") then json = LocalPlayer:GetAttribute("PipelineAimData") end
		if json then
			local data = HttpService:JSONDecode(json)
			for sectionName, settings in pairs({
				AimSettings = AimSettings, PlayerVisuals = PlayerVisuals,
				NpcVisuals = NpcVisuals, ContainerESP = ContainerESP,
				DroppedItemsESP = DroppedItemsESP, CorpseESP = CorpseESP,
				EffectSettings = EffectSettings, WorldSettings = WorldSettings,
				ViewmodelSettings = ViewmodelSettings, MovementSettings = MovementSettings,
				WeaponSettings = WeaponSettings, UtilitySettings = UtilitySettings
			}) do
				if data[sectionName] then
					for k, v in pairs(data[sectionName]) do settings[k] = v end
				end
			end
			if data.Whitelist then Whitelist = data.Whitelist end
		end
	end)
	if success and ApplyAllSavedSettings then ApplyAllSavedSettings() end
end

local function Save() SaveManager:Save() end

-- ====================== DRAWING (FOV + Crosshair) ======================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = AimSettings.Color
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Visible = AimSettings.ShowFOV

-- ====================== WHITELIST SYSTEM ======================
local function IsWhitelisted(player) return Whitelist[player.Name] == true end

local function ToggleWhitelist(player)
	Whitelist[player.Name] = (not IsWhitelisted(player)) and true or nil
	Save()
	pcall(UpdateWhitelistUI)
end

-- ====================== ESP CACHES (NO HIGHLIGHTS) ======================
local espCache = {}
local containerCache = {}
local droppedCache = {}
local corpseCache = {}

local jointConnections = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},
	{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},
	{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},
	{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},
	{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}

-- ====================== OPTIMIZED ESP CREATION (with Health Bar) ======================
local function CreateESP(model)
	if espCache[model] then return end
	local esp = {
		Model = model,
		NameText = Drawing.new("Text"),
		InfoText = Drawing.new("Text"),
		Tracer = Drawing.new("Line"),
		HealthBG = Drawing.new("Square"),
		HealthFill = Drawing.new("Square"),
		HealthText = Drawing.new("Text"),
		Skeleton = {},
		-- Cached part references
		_root = nil, _humanoid = nil, _head = nil,
		_cacheTick = 0
	}
	-- Name
	esp.NameText.Center = true; esp.NameText.Size = 13; esp.NameText.Font = 2
	esp.NameText.Outline = true; esp.NameText.Visible = false
	-- Info (gear)
	esp.InfoText.Center = true; esp.InfoText.Size = 11; esp.InfoText.Font = 2
	esp.InfoText.Outline = true; esp.InfoText.Visible = false
	-- Tracer
	esp.Tracer.Thickness = 1.5; esp.Tracer.Transparency = 0.6; esp.Tracer.Visible = false
	-- Health bar background
	esp.HealthBG.Filled = true; esp.HealthBG.Thickness = 1
	esp.HealthBG.Color = Color3.fromRGB(0, 0, 0)
	esp.HealthBG.Transparency = 0.7; esp.HealthBG.Visible = false
	-- Health bar fill
	esp.HealthFill.Filled = true; esp.HealthFill.Thickness = 1
	esp.HealthFill.Transparency = 1; esp.HealthFill.Visible = false
	-- Health text
	esp.HealthText.Center = true; esp.HealthText.Size = 10; esp.HealthText.Font = 2
	esp.HealthText.Outline = true; esp.HealthText.Visible = false
	-- Skeleton
	for _, jointPair in pairs(jointConnections) do
		local line = Drawing.new("Line")
		line.Thickness = 1; line.Transparency = 0.85; line.Visible = false
		esp.Skeleton[jointPair[1] .. jointPair[2]] = line
	end
	espCache[model] = esp
end

local function CreateContainerESP(model)
	if containerCache[model] then return end
	local esp = { Model = model, NameText = Drawing.new("Text"), ItemsText = Drawing.new("Text") }
	esp.NameText.Size = 12; esp.NameText.Font = 2; esp.NameText.Outline = true
	esp.NameText.Center = true; esp.NameText.Visible = false
	esp.ItemsText.Size = 11; esp.ItemsText.Font = 2; esp.ItemsText.Outline = true
	esp.ItemsText.Center = true; esp.ItemsText.Visible = false
	containerCache[model] = esp
end

local function CreateLootESP(model, isCorpse)
	local cache = isCorpse and corpseCache or droppedCache
	if cache[model] then return end
	local esp = { Model = model, Text = Drawing.new("Text") }
	esp.Text.Size = 12; esp.Text.Font = 2; esp.Text.Outline = true
	esp.Text.Center = true; esp.Text.Visible = false
	cache[model] = esp
end

local function HideESP(esp)
	esp.NameText.Visible = false
	esp.InfoText.Visible = false
	esp.Tracer.Visible = false
	esp.HealthBG.Visible = false
	esp.HealthFill.Visible = false
	esp.HealthText.Visible = false
	for _, line in pairs(esp.Skeleton) do line.Visible = false end
end

local function RemoveESP(model)
	local esp = espCache[model]
	if esp then
		esp.NameText:Remove(); esp.InfoText:Remove(); esp.Tracer:Remove()
		esp.HealthBG:Remove(); esp.HealthFill:Remove(); esp.HealthText:Remove()
		for _, line in pairs(esp.Skeleton) do line:Remove() end
		espCache[model] = nil
	end
end

local function RemoveContainerESP(model)
	local esp = containerCache[model]
	if esp then esp.NameText:Remove(); esp.ItemsText:Remove(); containerCache[model] = nil end
end

local function RemoveLootESP(model, isCorpse)
	local cache = isCorpse and corpseCache or droppedCache
	local esp = cache[model]
	if esp then esp.Text:Remove(); cache[model] = nil end
end

-- ====================== UTILITIES ======================
local clothingTextCache = {}
local function GetPlayerGearText(player)
	-- Cache for 1s to avoid scanning every frame
	local cached = clothingTextCache[player]
	if cached and tick() - cached.time < 1 then return cached.text end
	local charModel = Workspace:FindFirstChild(player.Name)
	if not charModel then return "" end
	local lines = {}
	local hasAny = false
	for _, folderName in ipairs({"Clothing", "Holstered"}) do
		local folder = charModel:FindFirstChild(folderName)
		if folder then
			local items = {}
			for _, item in ipairs(folder:GetChildren()) do
				if item:IsA("ValueBase") then
					local val = tostring(item.Value)
					if val ~= "" and val ~= " " then table.insert(items, val); hasAny = true end
				end
			end
			if #items > 0 then table.insert(lines, folderName .. ": " .. table.concat(items, " | ")) end
		end
	end
	local result = hasAny and table.concat(lines, "\n") or ""
	clothingTextCache[player] = {text = result, time = tick()}
	return result
end

local function isNPC(model)
	if not model:IsA("Model") then return false end
	if not (model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") and model:FindFirstChild("HumanoidRootPart")) then return false end
	return Players:GetPlayerFromCharacter(model) == nil
end

local function IsVisible(part)
	if not AimSettings.WallCheck then return true end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
	params.FilterType = Enum.RaycastFilterType.Exclude
	local result = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, params)
	return result and (result.Instance:IsDescendantOf(part.Parent) or result.Instance.Parent:IsDescendantOf(part.Parent))
end

local function GetClosestTarget()
	local ClosestTarget, ClosestPart = nil, nil
	local SmallestDistance = math.huge
	local MousePos = UserInputService:GetMouseLocation()
	local verticalFov = math.rad(Camera.FieldOfView)
	local screenDist = (Camera.ViewportSize.Y / 2) / math.tan(verticalFov / 2)
	local maxRadius = screenDist * math.tan(math.rad(AimSettings.FieldOfView) / 2)
	local targets = {}
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			if AimSettings.TeamCheck and plr.Team == LocalPlayer.Team then continue end
			if IsWhitelisted(plr) then continue end
			table.insert(targets, plr.Character)
		end
	end
	for _, npc in ipairs(activeNPCs) do table.insert(targets, npc) end
	for _, char in ipairs(targets) do
		local TargetPart = char:FindFirstChild(AimSettings.TargetPart) or char:FindFirstChild("Head")
		local Humanoid = char:FindFirstChild("Humanoid")
		if TargetPart and Humanoid and Humanoid.Health > 0 then
			local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
			if OnScreen then
				local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
				if Distance < maxRadius and Distance < SmallestDistance then
					if IsVisible(TargetPart) then
						ClosestTarget = char; ClosestPart = TargetPart; SmallestDistance = Distance
					end
				end
			end
		end
	end
	return ClosestTarget, ClosestPart
end

-- ====================== DETECTORS ======================
local function CheckModerators()
	if not UtilitySettings.ModDetector then return end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local repPlayer = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(player.Name)
			if repPlayer then
				local status = repPlayer:FindFirstChild("Status")
				if status and status:FindFirstChild("GameplayVariables") then
					local premLevel = status.GameplayVariables:GetAttribute("PremiumLevel") or 0
					if premLevel >= 4 and not Moderators[player.Name] then
						Moderators[player.Name] = true
						SendNotification("Mod Detector", "Suspected moderator detected: " .. player.Name, 10)
					end
				end
			end
			for _, limb in ipairs(player.Character:GetChildren()) do
				if limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart" and limb.Transparency >= 1 then
					if not Moderators[player.Name] then
						Moderators[player.Name] = true
						SendNotification("Invis Mod Detector", "Invis Admin suspect detected: " .. player.Name, 10)
					end
				end
			end
		end
	end
end

local function CheckCheaters()
	if not UtilitySettings.CheaterDetector then return end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not Cheaters[player.Name] then
			local repPlayer = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(player.Name)
			if repPlayer then
				local status = repPlayer:FindFirstChild("Status")
				local journey = status and status:FindFirstChild("Journey")
				local stats = journey and journey:FindFirstChild("WipeStatistics")
				if stats then
					local deaths = stats:GetAttribute("Deaths") or 0
					if deaths == 0 then deaths = 1 end
					local kills = stats:GetAttribute("Kills") or 0
					local kdr = kills / deaths
					local mostWanted = ReplicatedStorage:FindFirstChild("ReportList") and (ReplicatedStorage.ReportList:FindFirstChild("MostWanted") or ReplicatedStorage.ReportList:FindFirstChild("Recent"))
					local reportData = mostWanted and mostWanted:FindFirstChild(player.Name)
					if reportData then
						local flags = reportData:GetAttribute("TotalFlags") or 0
						local age = reportData:GetAttribute("Age") or 100
						local hsr = reportData:GetAttribute("HSR") or 0
						if kills >= 15 and hsr >= 95 then
							Cheaters[player.Name] = true
							SendNotification("Cheater Detector", player.Name .. " flagged for high Headshot Rate!", 8)
						elseif flags >= 75 and age <= 50 then
							Cheaters[player.Name] = true
							SendNotification("Cheater Detector", player.Name .. " flagged for suspicious system reports!", 8)
						end
					end
					if kills >= 15 and kdr >= 5 then
						Cheaters[player.Name] = true
						SendNotification("Cheater Detector", player.Name .. " suspected for extremely high KDR (" .. math.floor(kdr*10)/10 .. ")", 8)
					end
				end
			end
		end
	end
end

local scannedPlayerItems = {}
local function CheckItemFinder()
	if not UtilitySettings.ItemFinder then return end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local repPlayer = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(player.Name)
			if repPlayer and not scannedPlayerItems[player.Name] then
				local inventory = repPlayer:FindFirstChild("Inventory")
				if inventory then
					for _, slot in ipairs(inventory:GetChildren()) do
						if slot:GetAttribute("Slot") and slot:GetAttribute("Slot"):find("Clothing") then
							local innerInv = slot:FindFirstChild("Inventory")
							if innerInv then
								for _, innerItem in ipairs(innerInv:GetChildren()) do
									if UtilitySettings.ItemWhitelist[innerItem.Name] then
										SendNotification("Item Finder", player.Name .. " has obtained: " .. innerItem.Name, 10)
										scannedPlayerItems[player.Name] = true
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- ====================== HIT SOUND INJECTOR ======================
local function HookHitSounds(sound)
	if not WeaponSettings.CustomHitSound then return end
	if sound:IsA("Sound") then
		local targetID = customHitSoundIDs[WeaponSettings.HitSoundID] or customHitSoundIDs.Default
		if sound.SoundId == "rbxassetid://4585382589" or sound.SoundId == "rbxassetid://4585351098" or
			sound.SoundId == "rbxassetid://4585382046" or sound.SoundId == "rbxassetid://4585364605" then
			sound.SoundId = targetID
			sound.Volume = WeaponSettings.HitSoundVolume
		end
	end
end

task.spawn(function()
	local mainGui = LocalPlayer.PlayerGui:WaitForChild("MainGui", 10)
	if mainGui then
		mainGui.ChildAdded:Connect(HookHitSounds)
		for _, child in ipairs(mainGui:GetChildren()) do HookHitSounds(child) end
	end
end)

LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
	if child.Name == "MainGui" then child.ChildAdded:Connect(HookHitSounds) end
end)

-- ====================== INSTANT EQUIP (FIXED: was a dead toggle) ======================
local function HandleInstantEquip(viewmodel)
	if not MovementSettings.InstantEquip then return end
	if not viewmodel then return end
	task.spawn(function()
		local hum = viewmodel:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		local charHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		local charAnimator = charHum and charHum:FindFirstChildOfClass("Animator")
		local deadline = tick() + 1.0
		while MovementSettings.InstantEquip and tick() < deadline do
			for _, src in ipairs({animator, charAnimator}) do
				if src then
					for _, track in ipairs(src:GetPlayingAnimationTracks()) do
						local aName = track.Animation and track.Animation.Name or ""
						if aName == "Equip" or aName:lower():find("equip") then
							track:AdjustSpeed(15)
							track.TimePosition = math.max(track.Length - 0.01, 0)
							return
						end
					end
				end
			end
			task.wait(0.01)
		end
	end)
end

-- ====================== LANDMINE ERADICATOR ======================
local function RunLandmineEradicator()
	if not MovementSettings.NoLandmines then return end
	local aiZones = Workspace:FindFirstChild("AiZones")
	if aiZones then
		for _, zone in ipairs(aiZones:GetChildren()) do
			if zone.Name:find("Landmine") or zone.Name:find("Claymore") then
				for _, mine in ipairs(zone:GetChildren()) do
					if mine:IsA("Model") and (mine.Name == "PMN2" or mine.Name == "MON50") then mine:Destroy() end
				end
			end
		end
	end
end

-- ====================== BOSS TRACKER HUD ======================
local BossHUD = Instance.new("ScreenGui")
BossHUD.Name = "PipelineBossHUD"; BossHUD.ResetOnSpawn = false
pcall(function() BossHUD.Parent = CoreGui end)
if not BossHUD.Parent then BossHUD.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local BossFrame = Instance.new("Frame")
BossFrame.Size = UDim2.new(0, 200, 0, 120)
BossFrame.Position = UDim2.new(0.02, 0, 0.45, 0)
BossFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
BossFrame.BorderSizePixel = 0
BossFrame.Active = true; BossFrame.Draggable = true; BossFrame.Visible = false
BossFrame.Parent = BossHUD
Instance.new("UICorner", BossFrame).CornerRadius = UDim.new(0, 5)
local BossFrameStroke = Instance.new("UIStroke", BossFrame)
BossFrameStroke.Color = Color3.fromRGB(45, 45, 45); BossFrameStroke.Thickness = 1.5

local BossTitle = Instance.new("TextLabel")
BossTitle.Size = UDim2.new(1, 0, 0, 25)
BossTitle.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
BossTitle.Text = "ACTIVE BOSS TRACKER"
BossTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
BossTitle.Font = Enum.Font.RobotoMono; BossTitle.TextSize = 12; BossTitle.BorderSizePixel = 0
BossTitle.Parent = BossFrame
Instance.new("UICorner", BossTitle).CornerRadius = UDim.new(0, 5)

local BossList = Instance.new("Frame")
BossList.Size = UDim2.new(1, 0, 1, -25)
BossList.Position = UDim2.new(0, 0, 0, 25)
BossList.BackgroundTransparency = 1; BossList.Parent = BossFrame
local UIListLayout = Instance.new("UIListLayout", BossList)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder; UIListLayout.Padding = UDim.new(0, 5)

local function CreateBossRow(bossName, zoneName)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 25); row.BackgroundTransparency = 1; row.Name = bossName; row.Parent = BossList
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0); nameLabel.Position = UDim2.new(0.05, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1; nameLabel.Text = bossName; nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.Font = Enum.Font.RobotoMono; nameLabel.TextSize = 11; nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.Parent = row
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0.4, 0, 1, 0); statusLabel.Position = UDim2.new(0.55, 0, 0, 0)
	statusLabel.BackgroundTransparency = 1; statusLabel.Text = "Not Spawned"; statusLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
	statusLabel.Font = Enum.Font.RobotoMono; statusLabel.TextSize = 11; statusLabel.TextXAlignment = Enum.TextXAlignment.Right; statusLabel.Parent = row
end

CreateBossRow("Anton", "Sawmill")
CreateBossRow("Dozer", "Factory")
CreateBossRow("Whisper", "Whisper")

local function UpdateBossTrackerLogic()
	if not UtilitySettings.ShowBossTracker then BossFrame.Visible = false; return end
	BossFrame.Visible = true; BossFrame.Active = UtilitySettings.BossMovable; BossFrame.Draggable = UtilitySettings.BossMovable
	local aiZones = Workspace:FindFirstChild("AiZones")
	local bosses = {{Name="Anton",Zone="Sawmill"},{Name="Dozer",Zone="Factory"},{Name="Whisper",Zone="Whisper"}}
	for _, bInfo in ipairs(bosses) do
		local row = BossList:FindFirstChild(bInfo.Name)
		if row then
			local statusLabel = row:GetChildren()[3]
			local zone = aiZones and aiZones:FindFirstChild(bInfo.Zone)
			local model = zone and zone:FindFirstChild(bInfo.Name)
			local hum = model and model:FindFirstChild("Humanoid")
			if model and hum and hum.Health > 0 then
				statusLabel.Text = "HP: " .. math.floor(hum.Health); statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
			else
				statusLabel.Text = "Dead/Absent"; statusLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
			end
		end
	end
end

-- ====================== INVENTORY CHECKER HUD ======================
local InvHUD = Instance.new("ScreenGui")
InvHUD.Name = "PipelineInvHUD"; InvHUD.ResetOnSpawn = false
pcall(function() InvHUD.Parent = CoreGui end)
if not InvHUD.Parent then InvHUD.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local InvFrame = Instance.new("Frame")
InvFrame.Size = UDim2.new(0, 230, 0, 180); InvFrame.Position = UDim2.new(0.8, 0, 0.45, 0)
InvFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); InvFrame.BorderSizePixel = 0
InvFrame.Active = true; InvFrame.Draggable = true; InvFrame.Visible = false; InvFrame.Parent = InvHUD
Instance.new("UICorner", InvFrame).CornerRadius = UDim.new(0, 5)
local InvFrameStroke = Instance.new("UIStroke", InvFrame)
InvFrameStroke.Color = Color3.fromRGB(0, 180, 255); InvFrameStroke.Thickness = 1.5

local InvTitle = Instance.new("TextLabel")
InvTitle.Size = UDim2.new(1, 0, 0, 25); InvTitle.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
InvTitle.Text = "TARGET INVENTORY"; InvTitle.TextColor3 = Color3.fromRGB(0, 180, 255)
InvTitle.Font = Enum.Font.RobotoMono; InvTitle.TextSize = 11; InvTitle.BorderSizePixel = 0; InvTitle.Parent = InvFrame
Instance.new("UICorner", InvTitle).CornerRadius = UDim.new(0, 5)

local InvGrid = Instance.new("ScrollingFrame")
InvGrid.Size = UDim2.new(1, -10, 1, -35); InvGrid.Position = UDim2.new(0, 5, 0, 30)
InvGrid.BackgroundTransparency = 1; InvGrid.BorderSizePixel = 0; InvGrid.ScrollBarThickness = 3; InvGrid.Parent = InvFrame
local InvGridLayout = Instance.new("UIGridLayout", InvGrid)
InvGridLayout.CellSize = UDim2.new(0, 45, 0, 45); InvGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)

local function ClearInventoryGrid()
	for _, child in ipairs(InvGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") then child:Destroy() end
	end
end

local function PopulateInventoryGrid(targetPlayer)
	ClearInventoryGrid()
	local repPlayer = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(targetPlayer.Name)
	local inventory = repPlayer and repPlayer:FindFirstChild("Inventory")
	local itemsList = ReplicatedStorage:FindFirstChild("ItemsList")
	if not inventory then return end
	local function addGridIcon(itemName, amount)
		local asset = itemsList and itemsList:FindFirstChild(itemName)
		local iconId = asset and asset:FindFirstChild("ItemProperties") and asset.ItemProperties:FindFirstChild("ItemIcon") and asset.ItemProperties.ItemIcon.Image
		local container = Instance.new("Frame")
		container.Size = UDim2.new(0, 45, 0, 45); container.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
		container.BorderSizePixel = 0; container.Parent = InvGrid
		Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(0.9, 0, 0.9, 0); img.Position = UDim2.new(0.05, 0, 0.05, 0)
		img.BackgroundTransparency = 1; img.Image = iconId or "rbxassetid://12459616555"; img.Parent = container
		if amount and amount > 1 then
			local amtLabel = Instance.new("TextLabel")
			amtLabel.Size = UDim2.new(0.5, 0, 0.4, 0); amtLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
			amtLabel.BackgroundTransparency = 1; amtLabel.Text = "x" .. amount; amtLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			amtLabel.Font = Enum.Font.RobotoMono; amtLabel.TextSize = 9; amtLabel.TextXAlignment = Enum.TextXAlignment.Right; amtLabel.Parent = container
		end
	end
	for _, slot in ipairs(inventory:GetChildren()) do
		if slot:GetAttribute("Slot") and slot:GetAttribute("Slot"):find("Clothing") then
			local innerInv = slot:FindFirstChild("Inventory")
			if innerInv then
				for _, innerItem in ipairs(innerInv:GetChildren()) do
					addGridIcon(innerItem.Name, innerItem:GetAttribute("Amount") or 1)
				end
			end
		end
	end
	InvGrid.CanvasSize = UDim2.new(0, 0, 0, InvGridLayout.AbsoluteContentSize.Y + 10)
end

local function UpdateInventoryCheckerLogic()
	if not UtilitySettings.InventoryChecker or not UtilitySettings.InvCheckerActive then InvFrame.Visible = false; return end
	local target, _ = GetClosestTarget()
	if target then
		local plr = Players:GetPlayerFromCharacter(target)
		if plr then InvFrame.Visible = true; InvTitle.Text = "INV: " .. plr.Name:upper(); PopulateInventoryGrid(plr) end
	else
		InvFrame.Visible = false
	end
end

-- ====================== WHITELIST UI ======================
local WhitelistUI = { Entries = {} }
local function CreateWhitelistUI()
	local ScreenGui = Instance.new("ScreenGui")
	local MainFrame = Instance.new("Frame")
	local UIStroke = Instance.new("UIStroke")
	local Header = Instance.new("Frame")
	local Title = Instance.new("TextLabel")
	local ListFrame = Instance.new("ScrollingFrame")
	local ListLayout = Instance.new("UIListLayout")
	ScreenGui.Name = "PipelineWhitelist"; ScreenGui.ResetOnSpawn = false
	pcall(function() ScreenGui.Parent = CoreGui end)
	if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	MainFrame.Name = "Main"; MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	MainFrame.BackgroundTransparency = 0.1; MainFrame.BorderSizePixel = 0; MainFrame.Position = UDim2.new(1, -210, 0, 15)
	MainFrame.Size = UDim2.new(0, 195, 0, 280); MainFrame.Visible = false; MainFrame.Active = true; MainFrame.Draggable = true
	UIStroke.Parent = MainFrame; UIStroke.Color = PlayerVisuals.WhitelistColor; UIStroke.Thickness = 1.5; UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Header.Name = "Header"; Header.Parent = MainFrame; Header.BackgroundColor3 = Color3.fromRGB(22, 22, 22); Header.BorderSizePixel = 0; Header.Size = UDim2.new(1, 0, 0, 24)
	Title.Name = "Title"; Title.Parent = Header; Title.BackgroundTransparency = 1; Title.Size = UDim2.new(1, -8, 1, 0)
	Title.Font = Enum.Font.RobotoMono; Title.Text = "WHITELIST MANAGER"; Title.TextColor3 = Color3.fromRGB(240, 240, 240)
	Title.TextSize = 12; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Position = UDim2.new(0, 6, 0, 0)
	ListFrame.Name = "List"; ListFrame.Parent = MainFrame; ListFrame.BackgroundTransparency = 1; ListFrame.Position = UDim2.new(0, 0, 0, 24)
	ListFrame.Size = UDim2.new(1, 0, 1, -24); ListFrame.ScrollBarThickness = 2; ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0); ListFrame.BorderSizePixel = 0
	ListLayout.Parent = ListFrame; ListLayout.SortOrder = Enum.SortOrder.LayoutOrder; ListLayout.Padding = UDim.new(0, 2)
	WhitelistUI.Gui = ScreenGui; WhitelistUI.MainFrame = MainFrame; WhitelistUI.Stroke = UIStroke; WhitelistUI.ListFrame = ListFrame; WhitelistUI.ListLayout = ListLayout
end

local function CreatePlayerEntry(player)
	local Entry = Instance.new("TextButton")
	Entry.Name = player.Name; Entry.Parent = WhitelistUI.ListFrame; Entry.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	Entry.BorderSizePixel = 0; Entry.Size = UDim2.new(1, -4, 0, 22); Entry.AutoButtonColor = false
	Entry.Font = Enum.Font.RobotoMono; Entry.TextSize = 11; Entry.TextXAlignment = Enum.TextXAlignment.Left; Entry.LayoutOrder = player.Name:lower():byte()
	local Padding = Instance.new("UIPadding"); Padding.PaddingLeft = UDim.new(0, 6); Padding.Parent = Entry
	local StatusDot = Instance.new("Frame"); StatusDot.Name = "Dot"; StatusDot.Parent = Entry
	StatusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 60); StatusDot.BorderSizePixel = 0
	StatusDot.Position = UDim2.new(1, -20, 0.5, -5); StatusDot.Size = UDim2.new(0, 10, 0, 10); StatusDot.AnchorPoint = Vector2.new(0, 0.5)
	Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
	local function UpdateVisuals()
		local wl = IsWhitelisted(player)
		Entry.Text = (wl and "[WL] " or "") .. player.Name
		Entry.TextColor3 = wl and PlayerVisuals.WhitelistColor or Color3.fromRGB(200, 200, 200)
		StatusDot.BackgroundColor3 = wl and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 60, 60)
	end
	Entry.MouseButton1Click:Connect(function() ToggleWhitelist(player); UpdateVisuals() end)
	UpdateVisuals()
	WhitelistUI.Entries[player] = Entry
end

function UpdateWhitelistUI()
	for plr, entry in pairs(WhitelistUI.Entries) do
		if not Players:FindFirstChild(plr.Name) then entry:Destroy(); WhitelistUI.Entries[plr] = nil
		else
			local wl = IsWhitelisted(plr)
			entry.Text = (wl and "[WL] " or "") .. plr.Name
			entry.TextColor3 = wl and PlayerVisuals.WhitelistColor or Color3.fromRGB(200, 200, 200)
			entry.Dot.BackgroundColor3 = wl and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 60, 60)
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and not WhitelistUI.Entries[plr] then CreatePlayerEntry(plr) end
	end
	WhitelistUI.ListFrame.CanvasSize = UDim2.new(0, 0, 0, WhitelistUI.ListLayout.AbsoluteContentSize.Y + 4)
end

CreateWhitelistUI()

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		WorldSettings.ShowWhitelistMenu = not WorldSettings.ShowWhitelistMenu; Save()
	end
end)

-- ====================== SCANNING ======================
local function ScanForLoot()
	local containersRoot = Workspace:FindFirstChild("Containers")
	if containersRoot then
		for _, obj in ipairs(containersRoot:GetDescendants()) do
			if obj:IsA("Model") and obj:FindFirstChild("Inventory") then CreateContainerESP(obj) end
		end
	end
	local droppedRoot = Workspace:FindFirstChild("DroppedItems")
	if droppedRoot then
		for _, obj in ipairs(droppedRoot:GetDescendants()) do
			if obj:IsA("Model") then
				if obj:FindFirstChildOfClass("Humanoid") then CreateLootESP(obj, true) else CreateLootESP(obj, false) end
			end
		end
	end
end

-- ====================== VIEWMODEL STYLING ======================
local function ApplyViewmodelCustomization(viewmodel)
	if not ViewmodelSettings.Enabled or not viewmodel then return end
	local hrp = viewmodel:FindFirstChild("HumanoidRootPart")
	if hrp then
		local targetOffset = Vector3.new(ViewmodelSettings.XOffset, ViewmodelSettings.YOffset, ViewmodelSettings.ZOffset)
		local leftArm = viewmodel:FindFirstChild("LeftUpperArm") or hrp:FindFirstChild("LeftUpperArm")
		local rightArm = viewmodel:FindFirstChild("RightUpperArm") or hrp:FindFirstChild("RightUpperArm")
		local motor = hrp:FindFirstChild("Motor6D")
		if leftArm and rightArm and motor then
			leftArm.C0 = leftArm.C0 + targetOffset; rightArm.C0 = rightArm.C0 + targetOffset; motor.C0 = motor.C0 + targetOffset
		end
	end
	for _, limb in ipairs(viewmodel:GetChildren()) do
		if limb.Name:find("Hand") or limb.Name:find("Arm") then
			limb.Color = ViewmodelSettings.Color; limb.Transparency = ViewmodelSettings.Transparency
		end
	end
end

Workspace.Camera.ChildAdded:Connect(function(child)
	if child.Name == "ViewModel" then
		task.wait(0.01)
		ApplyViewmodelCustomization(child)
		HandleInstantEquip(child)   -- FIX: instant equip now actually fires on weapon swap
	end
end)

-- ====================== HELPER: Health Color ======================
local function GetHealthColor(ratio)
	if ratio > 0.5 then
		return Color3.fromRGB(255 * (1 - (ratio - 0.5) * 2), 255, 0)
	else
		return Color3.fromRGB(255, 255 * (ratio * 2), 0)
	end
end

-- ====================== OPTIMIZED MAIN RENDER LOOP ======================
local WorldToViewportPoint = Camera.WorldToViewportPoint
RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()
	local camCFrame = Camera.CFrame
	local camPos = camCFrame.Position
	local viewportSize = Camera.ViewportSize
	local localTeam = LocalPlayer.Team
	local timeNow = tick()

	WhitelistUI.MainFrame.Visible = WorldSettings.ShowWhitelistMenu
	WhitelistUI.Stroke.Color = PlayerVisuals.WhitelistColor

	-- FOV Circle
	if AimSettings.ShowFOV then
		local verticalFov = math.rad(Camera.FieldOfView)
		local screenDist = (viewportSize.Y / 2) / math.tan(verticalFov / 2)
		FOVCircle.Radius = screenDist * math.tan(math.rad(AimSettings.FieldOfView) / 2)
		FOVCircle.Position = mousePos; FOVCircle.Color = AimSettings.Color
	end

	-- AIM status indicator (Milenium UI has no built-in HUD indicator, so we draw our own)
	if UpdateAimIndicator then UpdateAimIndicator() end

	-- Camera FOV
	local targetFOV = UserInputService:IsKeyDown(WorldSettings.ZoomKey) and WorldSettings.ZoomFOV or WorldSettings.PlayerFOV
	if Camera.FieldOfView ~= targetFOV then Camera.FieldOfView = targetFOV end

	-- Aimbot
	if AimSettings.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		local targetChar, targetPart = GetClosestTarget()
		if targetChar and targetPart then
			local TargetCFrame = CFrame.lookAt(camPos, targetPart.Position)
			Camera.CFrame = camCFrame:Lerp(TargetCFrame, AimSettings.Smoothing)
		end
	end

	-- Rainbow colors
	if PlayerVisuals.Rainbow then PlayerVisuals.Color = Color3.fromHSV(timeNow % 5 / 5, 1, 1) end
	if NpcVisuals.Rainbow then NpcVisuals.Color = Color3.fromHSV(timeNow % 5 / 5, 1, 1) end

	-- ========= CONTAINER ESP (Optimized) =========
	if ContainerESP.Enabled then
		for model, esp in pairs(containerCache) do
			if not model.Parent then
				RemoveContainerESP(model)
			else
				local part = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
				if part then
					local dist = (camPos - part.Position).Magnitude
					if dist <= ContainerESP.MaxDistance then
						local pos = WorldToViewportPoint(Camera, part.Position + Vector3.new(0, 3, 0))
						if pos.Z > 0 then
							if ContainerESP.ShowItems then
								local inv = model:FindFirstChild("Inventory")
								if inv then
									local items = {}
									for _, v in ipairs(inv:GetChildren()) do
										if v:IsA("ValueBase") then
											local val = tostring(v.Value)
											if val ~= "" then table.insert(items, val) end
										end
									end
									if #items > 0 then
										local count = math.min(#items, ContainerESP.MaxItems)
										local text = table.concat(items, " | ", 1, count)
										if #items > count then text = text .. " +" .. (#items - count) end
										esp.ItemsText.Text = text
										esp.ItemsText.Position = Vector2.new(pos.X, pos.Y - 14)
										esp.ItemsText.Color = ContainerESP.Color
										esp.ItemsText.Visible = true
									else esp.ItemsText.Visible = false end
								else esp.ItemsText.Visible = false end
							else esp.ItemsText.Visible = false end
						else esp.ItemsText.Visible = false end
					else esp.ItemsText.Visible = false end
				else esp.ItemsText.Visible = false end
			end
		end
	else
		for _, esp in pairs(containerCache) do esp.ItemsText.Visible = false end
	end

	-- ========= DROPPED ITEMS ESP =========
	if DroppedItemsESP.Enabled then
		for model, esp in pairs(droppedCache) do
			if not model.Parent then RemoveLootESP(model, false)
			else
				local part = model:FindFirstChildOfClass("BasePart")
				if part then
					local dist = (camPos - part.Position).Magnitude
					if dist <= DroppedItemsESP.MaxDistance then
						local pos = WorldToViewportPoint(Camera, part.Position)
						if pos.Z > 0 then
							local txt = model.Name
							if DroppedItemsESP.ShowDistance then txt = txt .. " [" .. math.floor(dist * 0.28) .. "m]" end
							esp.Text.Text = txt
							esp.Text.Position = Vector2.new(pos.X, pos.Y - 12)
							esp.Text.Color = DroppedItemsESP.Color
							esp.Text.Visible = true
						else esp.Text.Visible = false end
					else esp.Text.Visible = false end
				else esp.Text.Visible = false end
			end
		end
	else
		for _, esp in pairs(droppedCache) do esp.Text.Visible = false end
	end

	-- ========= CORPSE ESP =========
	if CorpseESP.Enabled then
		for model, esp in pairs(corpseCache) do
			if not model.Parent then RemoveLootESP(model, true)
			else
				local part = model:FindFirstChildOfClass("BasePart")
				if part then
					local dist = (camPos - part.Position).Magnitude
					if dist <= CorpseESP.MaxDistance then
						local pos = WorldToViewportPoint(Camera, part.Position)
						if pos.Z > 0 then
							local txt = "CORPSE"
							if CorpseESP.ShowDistance then txt = txt .. " [" .. math.floor(dist * 0.28) .. "m]" end
							esp.Text.Text = txt
							esp.Text.Position = Vector2.new(pos.X, pos.Y - 12)
							esp.Text.Color = CorpseESP.Color
							esp.Text.Visible = true
						else esp.Text.Visible = false end
					else esp.Text.Visible = false end
				else esp.Text.Visible = false end
			end
		end
	else
		for _, esp in pairs(corpseCache) do esp.Text.Visible = false end
	end

	-- ========= PLAYER & NPC ESP (OPTIMIZED WITH HEALTH BAR) =========
	for model, esp in pairs(espCache) do
		if not model.Parent then
			HideESP(esp)
			RemoveESP(model)
		else
			if timeNow - esp._cacheTick > 0.5 or not (esp._root and esp._root.Parent) then
				esp._root = model:FindFirstChild("HumanoidRootPart")
				esp._humanoid = model:FindFirstChildOfClass("Humanoid")
				esp._head = model:FindFirstChild("Head")
				esp._cacheTick = timeNow
			end
			local rootPart = esp._root
			local humanoid = esp._humanoid
			local headPart = esp._head
			if not (rootPart and humanoid and humanoid.Health > 0) then
				HideESP(esp)
			else
				local isNPCModel = isNPC(model)
				local plr = (not isNPCModel) and Players:GetPlayerFromCharacter(model) or nil
				local settings = isNPCModel and NpcVisuals or PlayerVisuals
				local maxDist = settings.MaxDistance or 2000
				local teamSkip = plr and AimSettings.TeamCheck and plr.Team == localTeam
				local distMag = (camPos - rootPart.Position).Magnitude
				if (not settings.ESPEnabled) or teamSkip or distMag > maxDist then
					HideESP(esp)
				else
					local rootPos = WorldToViewportPoint(Camera, rootPart.Position)
					if rootPos.Z <= 0 then
						HideESP(esp)
					else
						local color = settings.Color
						if plr and IsWhitelisted(plr) then color = PlayerVisuals.WhitelistColor end
						local headWorld = headPart and headPart.Position or (rootPart.Position + Vector3.new(0, 2, 0))
						local feetWorld = rootPart.Position - Vector3.new(0, 3, 0)
						local headScreen = WorldToViewportPoint(Camera, headWorld + Vector3.new(0, 0.6, 0))
						local feetScreen = WorldToViewportPoint(Camera, feetWorld)
						local boxTop = headScreen.Y
						local boxBot = feetScreen.Y
						if boxBot < boxTop then boxTop, boxBot = boxBot, boxTop end
						local boxHeight = boxBot - boxTop
						if boxHeight < 10 then boxHeight = 10 end
						local distance = math.floor(distMag * 0.28)
						if settings.Names or settings.Distance then
							local text = ""
							if settings.Names then text = isNPCModel and model.Name or plr.Name end
							if settings.Distance then
								text = text .. (settings.Names and " " or "") .. "[" .. distance .. "m]"
							end
							esp.NameText.Text = text
							esp.NameText.Position = Vector2.new(rootPos.X, boxTop - 16)
							esp.NameText.Color = color
							esp.NameText.Visible = true
						else esp.NameText.Visible = false end
						if settings.HealthBar then
							local maxHP = humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100
							local healthRatio = math.clamp(humanoid.Health / maxHP, 0, 1)
							local barWidth = 3
							local barX = rootPos.X - (boxHeight * 0.25) - 8
							esp.HealthBG.Size = Vector2.new(barWidth, boxHeight)
							esp.HealthBG.Position = Vector2.new(barX, boxTop)
							esp.HealthBG.Visible = true
							local fillHeight = boxHeight * healthRatio
							esp.HealthFill.Size = Vector2.new(barWidth, fillHeight)
							esp.HealthFill.Position = Vector2.new(barX, boxTop + (boxHeight - fillHeight))
							esp.HealthFill.Color = GetHealthColor(healthRatio)
							esp.HealthFill.Visible = true
							if healthRatio < 0.99 then
								esp.HealthText.Text = tostring(math.floor(humanoid.Health))
								esp.HealthText.Position = Vector2.new(barX - 4, boxTop + (boxHeight - fillHeight) - 12)
								esp.HealthText.Color = esp.HealthFill.Color
								esp.HealthText.Visible = true
							else esp.HealthText.Visible = false end
						else
							esp.HealthBG.Visible = false
							esp.HealthFill.Visible = false
							esp.HealthText.Visible = false
						end
						if (not isNPCModel) and plr and settings.ShowClothing then
							local gearText = GetPlayerGearText(plr)
							if gearText ~= "" then
								esp.InfoText.Text = gearText
								esp.InfoText.Position = Vector2.new(rootPos.X, boxBot + 4)
								esp.InfoText.Color = color
								esp.InfoText.Visible = true
							else esp.InfoText.Visible = false end
						else esp.InfoText.Visible = false end
						if settings.Tracers then
							esp.Tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
							esp.Tracer.To = Vector2.new(rootPos.X, boxBot)
							esp.Tracer.Color = color
							esp.Tracer.Visible = true
						else esp.Tracer.Visible = false end
						if settings.Skeleton then
							for _, jointPair in ipairs(jointConnections) do
								local key = jointPair[1] .. jointPair[2]
								local line = esp.Skeleton[key]
								if line then
									local p1 = model:FindFirstChild(jointPair[1])
									local p2 = model:FindFirstChild(jointPair[2])
									if p1 and p2 then
										local s1 = WorldToViewportPoint(Camera, p1.Position)
										local s2 = WorldToViewportPoint(Camera, p2.Position)
										if s1.Z > 0 and s2.Z > 0 then
											line.From = Vector2.new(s1.X, s1.Y)
											line.To = Vector2.new(s2.X, s2.Y)
											line.Color = color
											line.Visible = true
										else line.Visible = false end
									else line.Visible = false end
								end
							end
						else
							for _, line in pairs(esp.Skeleton) do line.Visible = false end
						end
					end
				end
			end
		end
	end
end)

-- Throttled UI HUD updates (every 0.5s instead of every frame)
task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(UpdateBossTrackerLogic)
		pcall(UpdateInventoryCheckerLogic)
	end
end)

-- ====================== HEARTBEAT LOOPS ======================
RunService.Heartbeat:Connect(function()
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then
		local viewmodel = Camera:FindFirstChild("ViewModel")
		if viewmodel then ApplyViewmodelCustomization(viewmodel) end
	end
end)

-- ====================== EVENT LISTENERS ======================
Players.PlayerAdded:Connect(function(plr)
	if plr ~= LocalPlayer then
		plr.CharacterAdded:Connect(function(char) CreateESP(char) end)
		if plr.Character then CreateESP(plr.Character) end
	end
	task.wait(0.5); UpdateWhitelistUI()
end)

Players.PlayerRemoving:Connect(function(plr)
	if plr.Character then RemoveESP(plr.Character) end
	Whitelist[plr.Name] = nil
	clothingTextCache[plr] = nil
	if WhitelistUI.Entries[plr] then WhitelistUI.Entries[plr]:Destroy(); WhitelistUI.Entries[plr] = nil end
	Save()
end)

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		plr.CharacterAdded:Connect(function(char) CreateESP(char) end)
		if plr.Character then CreateESP(plr.Character) end
	end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
	if isNPC(obj) then table.insert(activeNPCs, obj); CreateESP(obj) end
end

Workspace.DescendantAdded:Connect(function(desc)
	if isNPC(desc) then table.insert(activeNPCs, desc); CreateESP(desc) end
	if desc:FindFirstChild("Inventory", true) or (desc.Name == "Inventory" and desc.Parent:IsA("Model")) then
		local model = desc:FindFirstAncestorWhichIsA("Model") or desc.Parent
		if model then CreateContainerESP(model) end
	end
	if desc.Parent and desc.Parent.Name == "DroppedItems" and desc:IsA("Model") then
		if desc:FindFirstChildOfClass("Humanoid") then CreateLootESP(desc, true) else CreateLootESP(desc, false) end
	end
end)

Workspace.DescendantRemoving:Connect(function(desc)
	RemoveESP(desc); RemoveContainerESP(desc); RemoveLootESP(desc, true); RemoveLootESP(desc, false)
	for i = #activeNPCs, 1, -1 do
		if activeNPCs[i] == desc then table.remove(activeNPCs, i) end
	end
end)

ScanForLoot()

local lastScan = tick()
local lastDetectorScan = tick()
RunService.Heartbeat:Connect(function()
	local rightNow = tick()
	if rightNow - lastScan > 2.5 then ScanForLoot(); lastScan = rightNow end
	if rightNow - lastDetectorScan > 10 then
		CheckModerators(); CheckCheaters(); CheckItemFinder(); RunLandmineEradicator(); lastDetectorScan = rightNow
	end
end)

-- ====================== WORLD ENVIRONMENT CONTROL ======================
local originalLighting = {}
local function SaveLighting()
	originalLighting = {
		GlobalShadows = Lighting.GlobalShadows, Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
		FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart,
		FogColor = Lighting.FogColor, ClockTime = Lighting.ClockTime
	}
end
SaveLighting()

Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
	if WorldSettings.NoFog and Lighting.FogEnd ~= 100000 then Lighting.FogEnd = 100000 end
end)

local function UpdateWorld()
	if WorldSettings.Fullbright then
		Lighting.GlobalShadows = false; Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(178, 178, 178); Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178); Lighting.ClockTime = 14
	else
		Lighting.GlobalShadows = originalLighting.GlobalShadows; Lighting.Brightness = originalLighting.Brightness
		Lighting.Ambient = originalLighting.Ambient; Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient; Lighting.ClockTime = originalLighting.ClockTime
	end
	if WorldSettings.NoFog then Lighting.FogEnd = 100000; Lighting.FogStart = 0
	else Lighting.FogEnd = originalLighting.FogEnd; Lighting.FogStart = originalLighting.FogStart end
	pcall(function() sethiddenproperty(Workspace.Terrain, "Decoration", not WorldSettings.NoGrass) end)
	local targetPack = skyboxPacks[WorldSettings.SkyboxType]
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky and targetPack then
		if WorldSettings.SkyboxType == "Default" then
			sky.SkyboxBk = ""; sky.SkyboxDn = ""; sky.SkyboxFt = ""; sky.SkyboxLf = ""; sky.SkyboxRt = ""; sky.SkyboxUp = ""
		else
			sky.SkyboxBk = targetPack.SkyboxBk; sky.SkyboxDn = targetPack.SkyboxDn; sky.SkyboxFt = targetPack.SkyboxFt
			sky.SkyboxLf = targetPack.SkyboxLf; sky.SkyboxRt = targetPack.SkyboxRt; sky.SkyboxUp = targetPack.SkyboxUp
		end
	end
	ApplyFoliageOverride(); ApplyCloudsOverride()
end

-- ====================== CHARACTER HOOKS ======================
local function RegisterCharHooks(char)
	char.ChildAdded:Connect(function(child)
		if child.Name == "ViewModel" then
			task.wait(0.01)
			ApplyViewmodelCustomization(child)
			HandleInstantEquip(child)
		end
	end)
end
if LocalPlayer.Character then RegisterCharHooks(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(RegisterCharHooks)

-- Auto-save loop (throttled)
task.spawn(function()
	while true do task.wait(15); Save() end
end)

-- ====================== MILENIUM UI LIBRARY ======================
local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/TheSancheziunblocker/Milenium/refs/heads/main/Mainui.lua", true))()

UILib.SetTitle("PIPELINE.AIM")

-- Simple on-screen AIM status indicator (replaces the old NLIndicator HUD element)
AimIndicatorText = Drawing.new("Text")
AimIndicatorText.Size = 16
AimIndicatorText.Center = true
AimIndicatorText.Outline = true
AimIndicatorText.Font = 2
AimIndicatorText.Color = Color3.fromRGB(0, 255, 100)
AimIndicatorText.Text = "AIM"
AimIndicatorText.Visible = false

UpdateAimIndicator = function()
	if not AimSettings.Enabled then
		AimIndicatorText.Visible = false
		return
	end
	AimIndicatorText.Visible = true
	AimIndicatorText.Position = Vector2.new(Camera.ViewportSize.X / 2, 40)
end

-- ====================== CATEGORIES ======================
local CatCombat   = UILib.AddCategory({Name = "Combat",   Image = 6031280882})
local CatVisuals  = UILib.AddCategory({Name = "Visuals",  Image = 6031280883})
local CatWorld    = UILib.AddCategory({Name = "World",    Image = 6031280891})
local CatSettings = UILib.AddCategory({Name = "Settings", Image = 6031280895})

-- ============ COMBAT / AIMBOT ============
local AimbotTab = CatCombat:AddTab("Aimbot")

local aimCard = AimbotTab:AddCard(1, "Aimbot")
aimCard:AddToggle({Label = "Enable Aimbot", Default = AimSettings.Enabled,
	Callback = function(v)
		AimSettings.Enabled = v
		if UpdateAimIndicator then UpdateAimIndicator() end
		Save()
	end})
aimCard:AddToggle({Label = "Show FOV Circle", Default = AimSettings.ShowFOV,
	Callback = function(v) AimSettings.ShowFOV = v; FOVCircle.Visible = v; Save() end})
aimCard:AddToggle({Label = "Team Check", Default = AimSettings.TeamCheck,
	Callback = function(v) AimSettings.TeamCheck = v; Save() end})
aimCard:AddToggle({Label = "Wall Check", Default = AimSettings.WallCheck,
	Callback = function(v) AimSettings.WallCheck = v; Save() end})
aimCard:AddSlider({Label = "FOV Radius", Min = 10, Max = 180, Default = AimSettings.FieldOfView, Decimals = 0,
	Callback = function(v) AimSettings.FieldOfView = v; Save() end})
aimCard:AddSlider({Label = "Aim Smoothing", Min = 0, Max = 1, Default = AimSettings.Smoothing, Decimals = 2,
	Callback = function(v) AimSettings.Smoothing = v; Save() end})

local selectionCard = AimbotTab:AddCard(1, "Selection")
selectionCard:AddDropdown({Label = "Target Part", Options = {"Head", "Torso"}, Default = AimSettings.TargetPart,
	Callback = function(v) AimSettings.TargetPart = v; Save() end})

local weaponModCard = AimbotTab:AddCard(2, "Weapon Mods")
weaponModCard:AddToggle({Label = "No Recoil", Default = WeaponSettings.NoRecoil,
	Callback = function(v) WeaponSettings.NoRecoil = v; ApplyNoRecoil(); Save() end})
weaponModCard:AddToggle({Label = "No Spread & Drop", Default = WeaponSettings.NoSpread,
	Callback = function(v) WeaponSettings.NoSpread = v; ApplyNoSpread(); Save() end})
weaponModCard:AddToggle({Label = "Instant Weapon Equip", Default = MovementSettings.InstantEquip,
	Callback = function(v)
		MovementSettings.InstantEquip = v
		if v then local vm = Camera:FindFirstChild("ViewModel"); if vm then HandleInstantEquip(vm) end end
		Save()
	end})

local hitSoundCard = AimbotTab:AddCard(2, "Hit Sounds")
hitSoundCard:AddToggle({Label = "Custom Hit Sound", Default = WeaponSettings.CustomHitSound,
	Callback = function(v) WeaponSettings.CustomHitSound = v; Save() end})
hitSoundCard:AddDropdown({Label = "Hit Sound",
	Options = {"Default", "Rust", "Neverlose", "Gamesense", "Bubble", "Ding", "CS 1.6", "Windows XP", "FAAHH"},
	Default = WeaponSettings.HitSoundID,
	Callback = function(v) WeaponSettings.HitSoundID = v; Save() end})
hitSoundCard:AddSlider({Label = "Hit Sound Volume", Min = 0, Max = 2, Default = WeaponSettings.HitSoundVolume, Decimals = 2,
	Callback = function(v) WeaponSettings.HitSoundVolume = v; Save() end})

-- ============ VISUALS / ESP ============
local ESPTab = CatVisuals:AddTab("ESP")

local playerESPCard = ESPTab:AddCard(1, "Player ESP")
playerESPCard:AddToggle({Label = "Enable Player ESP", Default = PlayerVisuals.ESPEnabled,
	Callback = function(v) PlayerVisuals.ESPEnabled = v; Save() end})
playerESPCard:AddToggle({Label = "Health Bar", Default = PlayerVisuals.HealthBar,
	Callback = function(v) PlayerVisuals.HealthBar = v; Save() end})
playerESPCard:AddToggle({Label = "Skeleton ESP", Default = PlayerVisuals.Skeleton,
	Callback = function(v) PlayerVisuals.Skeleton = v; Save() end})
playerESPCard:AddToggle({Label = "Show Names", Default = PlayerVisuals.Names,
	Callback = function(v) PlayerVisuals.Names = v; Save() end})
playerESPCard:AddToggle({Label = "Show Distance", Default = PlayerVisuals.Distance,
	Callback = function(v) PlayerVisuals.Distance = v; Save() end})
playerESPCard:AddToggle({Label = "Show Gear Info", Default = PlayerVisuals.ShowClothing,
	Callback = function(v) PlayerVisuals.ShowClothing = v; Save() end})
playerESPCard:AddToggle({Label = "Show Tracers", Default = PlayerVisuals.Tracers,
	Callback = function(v) PlayerVisuals.Tracers = v; Save() end})
playerESPCard:AddToggle({Label = "Rainbow Color", Default = PlayerVisuals.Rainbow,
	Callback = function(v) PlayerVisuals.Rainbow = v; Save() end})
playerESPCard:AddColorPicker({Label = "ESP Color", Default = PlayerVisuals.Color,
	Callback = function(col) PlayerVisuals.Color = col; Save() end})
playerESPCard:AddSlider({Label = "Max Distance", Min = 100, Max = 3000, Default = PlayerVisuals.MaxDistance, Decimals = 0,
	Callback = function(v) PlayerVisuals.MaxDistance = v; Save() end})

local npcESPCard = ESPTab:AddCard(2, "NPC ESP")
npcESPCard:AddToggle({Label = "Enable NPC ESP", Default = NpcVisuals.ESPEnabled,
	Callback = function(v) NpcVisuals.ESPEnabled = v; Save() end})
npcESPCard:AddToggle({Label = "Health Bar", Default = NpcVisuals.HealthBar,
	Callback = function(v) NpcVisuals.HealthBar = v; Save() end})
npcESPCard:AddToggle({Label = "Skeleton ESP", Default = NpcVisuals.Skeleton,
	Callback = function(v) NpcVisuals.Skeleton = v; Save() end})
npcESPCard:AddToggle({Label = "Show Names", Default = NpcVisuals.Names,
	Callback = function(v) NpcVisuals.Names = v; Save() end})
npcESPCard:AddToggle({Label = "Show Distance", Default = NpcVisuals.Distance,
	Callback = function(v) NpcVisuals.Distance = v; Save() end})
npcESPCard:AddToggle({Label = "Show Tracers", Default = NpcVisuals.Tracers,
	Callback = function(v) NpcVisuals.Tracers = v; Save() end})
npcESPCard:AddToggle({Label = "Rainbow Color", Default = NpcVisuals.Rainbow,
	Callback = function(v) NpcVisuals.Rainbow = v; Save() end})
npcESPCard:AddColorPicker({Label = "ESP Color", Default = NpcVisuals.Color,
	Callback = function(col) NpcVisuals.Color = col; Save() end})
npcESPCard:AddSlider({Label = "Max Distance", Min = 100, Max = 3000, Default = NpcVisuals.MaxDistance, Decimals = 0,
	Callback = function(v) NpcVisuals.MaxDistance = v; Save() end})

-- ============ WORLD / LOOT ============
local LootTab = CatWorld:AddTab("Loot")

local containerCard = LootTab:AddCard(1, "Containers")
containerCard:AddToggle({Label = "Container ESP", Default = ContainerESP.Enabled,
	Callback = function(v) ContainerESP.Enabled = v; Save() end})
containerCard:AddToggle({Label = "Show Container Items", Default = ContainerESP.ShowItems,
	Callback = function(v) ContainerESP.ShowItems = v; Save() end})
containerCard:AddSlider({Label = "Max Items Shown", Min = 3, Max = 12, Default = ContainerESP.MaxItems, Decimals = 0,
	Callback = function(v) ContainerESP.MaxItems = v; Save() end})
containerCard:AddSlider({Label = "Max Distance", Min = 50, Max = 1000, Default = ContainerESP.MaxDistance, Decimals = 0,
	Callback = function(v) ContainerESP.MaxDistance = v; Save() end})

local droppedCard = LootTab:AddCard(2, "Dropped Items")
droppedCard:AddToggle({Label = "Dropped Items ESP", Default = DroppedItemsESP.Enabled,
	Callback = function(v) DroppedItemsESP.Enabled = v; Save() end})
droppedCard:AddToggle({Label = "Show Drop Distance", Default = DroppedItemsESP.ShowDistance,
	Callback = function(v) DroppedItemsESP.ShowDistance = v; Save() end})

local corpseCard = LootTab:AddCard(2, "Corpses")
corpseCard:AddToggle({Label = "Corpse ESP", Default = CorpseESP.Enabled,
	Callback = function(v) CorpseESP.Enabled = v; Save() end})
corpseCard:AddToggle({Label = "Show Corpse Distance", Default = CorpseESP.ShowDistance,
	Callback = function(v) CorpseESP.ShowDistance = v; Save() end})

-- ============ WORLD / ENVIRONMENT ============
local WorldTab = CatWorld:AddTab("Environment")

local envCard = WorldTab:AddCard(1, "Environment")
envCard:AddToggle({Label = "Fullbright", Default = WorldSettings.Fullbright,
	Callback = function(v) WorldSettings.Fullbright = v; UpdateWorld(); Save() end})
envCard:AddToggle({Label = "No Fog", Default = WorldSettings.NoFog,
	Callback = function(v) WorldSettings.NoFog = v; UpdateWorld(); Save() end})
envCard:AddToggle({Label = "Hide Foliage Leaves", Default = WorldSettings.NoLeaves,
	Callback = function(v) WorldSettings.NoLeaves = v; ApplyFoliageOverride(); Save() end})
envCard:AddToggle({Label = "Remove 3D Clouds", Default = WorldSettings.NoClouds,
	Callback = function(v) WorldSettings.NoClouds = v; ApplyCloudsOverride(); Save() end})
envCard:AddToggle({Label = "Remove Grass", Default = WorldSettings.NoGrass,
	Callback = function(v) WorldSettings.NoGrass = v; UpdateWorld(); Save() end})
envCard:AddToggle({Label = "Eradicate Landmines", Default = MovementSettings.NoLandmines,
	Callback = function(v) MovementSettings.NoLandmines = v; Save() end})
envCard:AddDropdown({Label = "Skybox",
	Options = {"Default", "Orange Sunset", "Pink Sky", "Night", "Galaxy Sky", "Purple Space Sky", "Spring Sky"},
	Default = WorldSettings.SkyboxType,
	Callback = function(v) WorldSettings.SkyboxType = v; UpdateWorld(); Save() end})

local cameraCard = WorldTab:AddCard(2, "Camera")
cameraCard:AddSlider({Label = "Camera FOV", Min = 30, Max = 120, Default = WorldSettings.PlayerFOV, Decimals = 0,
	Callback = function(v) WorldSettings.PlayerFOV = v; Save() end})
cameraCard:AddSlider({Label = "Zoom FOV", Min = 10, Max = 70, Default = WorldSettings.ZoomFOV, Decimals = 0,
	Callback = function(v) WorldSettings.ZoomFOV = v; Save() end})
cameraCard:AddHoldKeybind({Label = "Zoom Key", Default = WorldSettings.ZoomKey,
	Callback = function(k, down) WorldSettings.ZoomKey = k; Save() end})
cameraCard:AddToggle({Label = "Whitelist Menu (RCtrl)", Default = WorldSettings.ShowWhitelistMenu,
	Callback = function(v) WorldSettings.ShowWhitelistMenu = v; Save() end})

local viewmodelCard = WorldTab:AddCard(2, "Viewmodel")
viewmodelCard:AddToggle({Label = "Enable Viewmodel Mods", Default = ViewmodelSettings.Enabled,
	Callback = function(v) ViewmodelSettings.Enabled = v; Save() end})
viewmodelCard:AddColorPicker({Label = "Arm Color", Default = ViewmodelSettings.Color,
	Callback = function(col) ViewmodelSettings.Color = col; Save() end})
viewmodelCard:AddSlider({Label = "Arm Transparency", Min = 0, Max = 1, Default = ViewmodelSettings.Transparency, Decimals = 2,
	Callback = function(v) ViewmodelSettings.Transparency = v; Save() end})
viewmodelCard:AddSlider({Label = "Arm X Offset", Min = -5, Max = 5, Default = ViewmodelSettings.XOffset, Decimals = 2,
	Callback = function(v) ViewmodelSettings.XOffset = v; Save() end})
viewmodelCard:AddSlider({Label = "Arm Y Offset", Min = -5, Max = 5, Default = ViewmodelSettings.YOffset, Decimals = 2,
	Callback = function(v) ViewmodelSettings.YOffset = v; Save() end})
viewmodelCard:AddSlider({Label = "Arm Z Offset", Min = -5, Max = 5, Default = ViewmodelSettings.ZOffset, Decimals = 2,
	Callback = function(v) ViewmodelSettings.ZOffset = v; Save() end})

-- ============ WORLD / DETECTORS ============
local DetectorTab = CatWorld:AddTab("Detectors")

local detectorCard = DetectorTab:AddCard(1, "Detection")
detectorCard:AddToggle({Label = "Staff/Mod Detector", Default = UtilitySettings.ModDetector,
	Callback = function(v) UtilitySettings.ModDetector = v; Save() end})
detectorCard:AddToggle({Label = "Cheater Radar", Default = UtilitySettings.CheaterDetector,
	Callback = function(v) UtilitySettings.CheaterDetector = v; Save() end})
detectorCard:AddToggle({Label = "High Value Item Finder", Default = UtilitySettings.ItemFinder,
	Callback = function(v) UtilitySettings.ItemFinder = v; Save() end})

local inventoryCard = DetectorTab:AddCard(2, "Inventory")
inventoryCard:AddToggle({Label = "Enable Inv Checker", Default = UtilitySettings.InventoryChecker,
	Callback = function(v) UtilitySettings.InventoryChecker = v; Save() end})
inventoryCard:AddToggle({Label = "Inventory Viewer HUD", Default = UtilitySettings.InvCheckerActive,
	Callback = function(v) UtilitySettings.InvCheckerActive = v; Save() end})

local bossCard = DetectorTab:AddCard(2, "Boss Tracker")
bossCard:AddToggle({Label = "Show Boss Tracker", Default = UtilitySettings.ShowBossTracker,
	Callback = function(v) UtilitySettings.ShowBossTracker = v; Save() end})
bossCard:AddToggle({Label = "Movable Boss Frame", Default = UtilitySettings.BossMovable,
	Callback = function(v) UtilitySettings.BossMovable = v; Save() end})

-- ============ SETTINGS ============
local SettingsTab = CatSettings:AddTab("General")

local configCard = SettingsTab:AddCard(1, "Configuration")
local configStatus = configCard:AddStatus({Text = "Config Ready"})

configCard:AddHoldKeybind({Label = "Save Config", Default = Enum.KeyCode.F5,
	Callback = function(k, down)
		if down then
			Save()
			configStatus:SetActive(true, "Configuration Saved!")
			task.delay(2, function() configStatus:SetActive(false, "Config Ready") end)
		end
	end})
configCard:AddHoldKeybind({Label = "Load Config", Default = Enum.KeyCode.F6,
	Callback = function(k, down)
		if down then
			SaveManager:Load()
			configStatus:SetActive(true, "Configuration Loaded!")
			task.delay(2, function() configStatus:SetActive(false, "Config Ready") end)
		end
	end})

local infoCard = SettingsTab:AddCard(2, "Info")
local pingStatus = infoCard:AddStatus({Text = "Ping: 0ms"})
infoCard:AddColorPicker({Label = "Theme Accent", Default = (UILib.Theme and UILib.Theme.Accent) or Color3.fromRGB(0, 170, 255),
	Callback = function(col) end})

task.spawn(function()
	while true do
		task.wait(1)
		local ok, latency = pcall(function()
			return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		if ok then pingStatus:SetActive(true, "Ping: " .. latency .. "ms") end
	end
end)

-- ====================== APPLY SAVED SETTINGS ======================
ApplyAllSavedSettings = function()
	task.spawn(function()
		ReplicatedStorage:WaitForChild("AmmoTypes", 10)
		ApplyNoRecoil(); ApplyNoSpread(); UpdateWorld()
		local viewmodel = Camera:FindFirstChild("ViewModel")
		if viewmodel then ApplyViewmodelCustomization(viewmodel) end
	end)
end

SaveManager:Load()
task.defer(UpdateWhitelistUI)
SendNotification("PIPELINE.AIM", "Optimized ESP edition loaded — now running on Milenium UI.", 5)
