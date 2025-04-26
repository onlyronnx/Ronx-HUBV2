-- Services
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

-- Settings
local aimbotEnabled = false
local targetPart = "Head"
local fovSize = 100
local whitelist = {}
local wallcheckEnabled = true
local espEnabled = true

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = fovSize
fovCircle.Thickness = 2
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Filled = false
fovCircle.Visible = true

-- GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "RonX_HUB"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 280, 0, 320)
main.Position = UDim2.new(0.02, 0, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.Active = true
main.Draggable = true

-- Close button (top-right)
local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
end)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "🔫 RonX HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.TextSize = 18

local function newButton(text, posY)
	local btn = Instance.new("TextButton", main)
	btn.Size = UDim2.new(0.9, 0, 0, 30)
	btn.Position = UDim2.new(0.05, 0, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = text
	return btn
end

-- Aimbot toggle
local aimbotBtn = newButton("Aimbot: OFF", 45)
aimbotBtn.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimbotBtn.Text = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
end)

-- ESP toggle
local espBtn = newButton("ESP: ON", 85)
espBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	espBtn.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

-- Wallcheck toggle
local wallBtn = newButton("Wallcheck: ON", 125)
wallBtn.MouseButton1Click:Connect(function()
	wallcheckEnabled = not wallcheckEnabled
	wallBtn.Text = "Wallcheck: " .. (wallcheckEnabled and "ON" or "OFF")
end)

-- Target part switch
local partBtn = newButton("Target: Head", 165)
partBtn.MouseButton1Click:Connect(function()
	if targetPart == "Head" then
		targetPart = "HumanoidRootPart"
		partBtn.Text = "Target: Body"
	else
		targetPart = "Head"
		partBtn.Text = "Target: Head"
	end
end)

-- FOV size input
local fovBox = Instance.new("TextBox", main)
fovBox.Size = UDim2.new(0.9, 0, 0, 30)
fovBox.Position = UDim2.new(0.05, 0, 0, 205)
fovBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
fovBox.TextColor3 = Color3.fromRGB(255, 255, 255)
fovBox.Font = Enum.Font.Gotham
fovBox.PlaceholderText = "FOV Size (default 100)"
fovBox.Text = tostring(fovSize)
fovBox.TextSize = 14

fovBox.FocusLost:Connect(function()
	local newSize = tonumber(fovBox.Text)
	if newSize and newSize > 0 then
		fovSize = newSize
		fovCircle.Radius = fovSize
	end
end)

-- Whitelist add input
local whitelistBox = Instance.new("TextBox", main)
whitelistBox.Size = UDim2.new(0.9, 0, 0, 30)
whitelistBox.Position = UDim2.new(0.05, 0, 0, 245)
whitelistBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
whitelistBox.TextColor3 = Color3.fromRGB(255, 255, 255)
whitelistBox.Font = Enum.Font.Gotham
whitelistBox.PlaceholderText = "Add Whitelist Username"
whitelistBox.TextSize = 14

whitelistBox.FocusLost:Connect(function()
	local name = whitelistBox.Text
	if name ~= "" then
		table.insert(whitelist, name)
		whitelistBox.Text = "Added ✔"
		wait(1)
		whitelistBox.Text = ""
	end
end)

-- Close keybind [V]
UIS.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.V then
		gui.Enabled = not gui.Enabled
	end
end)

-- Raycast check (wallcheck)
local function isVisible(part)
	if not wallcheckEnabled then return true end
	local origin = camera.CFrame.Position
	local direction = (part.Position - origin).Unit * 500
	local result = workspace:Raycast(origin, direction, RaycastParams.new())
	if result and result.Instance and not part:IsDescendantOf(result.Instance.Parent) then
		return false
	end
	return true
end

-- Get closest enemy
local function getClosest()
	local closest = nil
	local shortest = fovSize

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= lp and p.Character and p.Character:FindFirstChild(targetPart) and not table.find(whitelist, p.Name) then
			local pos, onScreen = camera:WorldToViewportPoint(p.Character[targetPart].Position)
			if onScreen then
				local mousePos = UIS:GetMouseLocation()
				local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
				if dist < shortest and isVisible(p.Character[targetPart]) then
					shortest = dist
					closest = p
				end
			end
		end
	end
	return closest
end

-- ESP
local espTable = {}

function createESP(player)
	local box = Drawing.new("Text")
	box.Text = player.Name
	box.Size = 13
	box.Center = true
	box.Outline = true
	box.Color = Color3.fromRGB(255, 255, 255)
	box.Visible = false
	espTable[player] = box
end

function removeESP(player)
	if espTable[player] then
		espTable[player]:Remove()
		espTable[player] = nil
	end
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

for _, player in pairs(Players:GetPlayers()) do
	if player ~= lp then
		createESP(player)
	end
end

-- Main loop
RS.RenderStepped:Connect(function()
	-- Update FOV Circle position based on mouse
	fovCircle.Position = UIS:GetMouseLocation()
	fovCircle.Visible = aimbotEnabled

	if aimbotEnabled then
		local target = getClosest()
		if target and target.Character and target.Character:FindFirstChild(targetPart) then
			-- Update Aimlock directly once target is found
			camera.CFrame = CFrame.new(camera.CFrame.Position, target.Character[targetPart].Position)
		end
	end

	-- ESP update
	for player, box in pairs(espTable) do
		if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local pos, onScreen = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
			box.Text = player.Name
			box.Visible = onScreen
			box.Position = Vector2.new(pos.X, pos.Y)
		end
	end
end)

-- Add Credit Text (Blue text at the bottom)
local creditText = Instance.new("TextLabel", main)
creditText.Size = UDim2.new(1, 0, 0, 25)
creditText.Position = UDim2.new(0, 0, 1, -35)  -- Posisi di bawah
creditText.Text = "CREDIT : ONLYRONNX"
creditText.TextColor3 = Color3.fromRGB(0, 0, 255)  -- Biru
creditText.Font = Enum.Font.GothamBold
creditText.TextSize = 14
creditText.BackgroundTransparency = 1
