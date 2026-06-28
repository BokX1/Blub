local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WINDMILL_COST = {
	Wood = 3,
	Stone = 2,
}
local WINDMILL_DAMAGE = 1
local WINDMILL_GOLD_INTERVAL = 5
local WINDMILL_HEALTH = 3

local resources = {
	{
		name = "Wood",
		position = Vector3.new(-12, 2, 0),
		size = Vector3.new(5, 4, 5),
		color = Color3.fromRGB(122, 80, 46),
		material = Enum.Material.Wood,
	},
	{
		name = "Stone",
		position = Vector3.new(12, 2, 0),
		size = Vector3.new(5, 4, 5),
		color = Color3.fromRGB(110, 110, 110),
		material = Enum.Material.Slate,
	},
}

local windmillCounts = {}
local windmillSlots = {}

local function spawnGround()
	local existingGround = Workspace:FindFirstChild("Ground")
	if existingGround then
		existingGround:Destroy()
	end

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Color = Color3.fromRGB(80, 160, 85)
	ground.Material = Enum.Material.Grass
	ground.Position = Vector3.new(0, -0.5, 0)
	ground.Size = Vector3.new(96, 1, 96)
	ground.Parent = Workspace
end

local function addLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	for _, resource in ipairs(resources) do
		if not leaderstats:FindFirstChild(resource.name) then
			local value = Instance.new("IntValue")
			value.Name = resource.name
			value.Parent = leaderstats
		end
	end

	if not leaderstats:FindFirstChild("Gold") then
		local gold = Instance.new("IntValue")
		gold.Name = "Gold"
		gold.Parent = leaderstats
	end
end

local function awardResource(player, resourceName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild(resourceName)

	if value then
		value.Value += 1
	end
end

local function canAffordWindmill(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	return leaderstats
		and leaderstats.Wood.Value >= WINDMILL_COST.Wood
		and leaderstats.Stone.Value >= WINDMILL_COST.Stone
end

local function createPart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Color = color
	part.Material = material
	part.Position = position
	part.Size = size
	part.Parent = parent

	return part
end

local function addAttackPrompt(model, part, owner)
	local health = Instance.new("IntValue")
	health.Name = "Health"
	health.Value = WINDMILL_HEALTH
	health.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Attack"
	prompt.ObjectText = "Windmill Health: " .. health.Value
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 10
	prompt.Parent = part

	prompt.Triggered:Connect(function()
		if not model.Parent then
			return
		end

		health.Value = math.max(health.Value - WINDMILL_DAMAGE, 0)
		prompt.ObjectText = "Windmill Health: " .. health.Value

		if health.Value == 0 then
			windmillCounts[owner] = math.max((windmillCounts[owner] or 0) - 1, 0)
			model:Destroy()
		end
	end)
end

local function spawnWindmill(player)
	if not canAffordWindmill(player) then
		return
	end

	local leaderstats = player.leaderstats
	leaderstats.Wood.Value -= WINDMILL_COST.Wood
	leaderstats.Stone.Value -= WINDMILL_COST.Stone

	local folder = Workspace:FindFirstChild("Windmills")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Windmills"
		folder.Parent = Workspace
	end

	windmillCounts[player] = (windmillCounts[player] or 0) + 1
	windmillSlots[player] = (windmillSlots[player] or 0) + 1
	local slot = windmillSlots[player]
	local basePosition = Vector3.new(-24 + (slot * 8), 0, 18)
	local model = Instance.new("Model")
	model.Name = player.Name .. "Windmill"
	model.Parent = folder

	local base = createPart(model, "Base", Vector3.new(5, 1, 5), basePosition + Vector3.new(0, 0.5, 0), Color3.fromRGB(130, 95, 60), Enum.Material.WoodPlanks)
	createPart(model, "Tower", Vector3.new(2, 8, 2), basePosition + Vector3.new(0, 5, 0), Color3.fromRGB(155, 115, 70), Enum.Material.Wood)
	createPart(model, "Hub", Vector3.new(2, 2, 2), basePosition + Vector3.new(0, 9, -1.25), Color3.fromRGB(230, 220, 190), Enum.Material.Wood)
	createPart(model, "BladeVertical", Vector3.new(1, 8, 0.5), basePosition + Vector3.new(0, 9, -2), Color3.fromRGB(235, 235, 210), Enum.Material.Wood)
	createPart(model, "BladeHorizontal", Vector3.new(8, 1, 0.5), basePosition + Vector3.new(0, 9, -2), Color3.fromRGB(235, 235, 210), Enum.Material.Wood)

	-- ponytail: all windmills are attackable until teams decide ownership rules.
	addAttackPrompt(model, base, player)
end

local function spawnBuildPad()
	local existingPad = Workspace:FindFirstChild("BuildPad")
	if existingPad then
		existingPad:Destroy()
	end

	local pad = createPart(Workspace, "BuildPad", Vector3.new(10, 1, 10), Vector3.new(0, 0.1, 18), Color3.fromRGB(85, 135, 190), Enum.Material.SmoothPlastic)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Build"
	prompt.ObjectText = "Windmill (3 Wood, 2 Stone)"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.Parent = pad

	prompt.Triggered:Connect(spawnWindmill)
end

local function startGoldLoop(player)
	task.spawn(function()
		while player.Parent do
			task.wait(WINDMILL_GOLD_INTERVAL)

			local leaderstats = player:FindFirstChild("leaderstats")
			local gold = leaderstats and leaderstats:FindFirstChild("Gold")
			local windmills = windmillCounts[player] or 0

			if gold and windmills > 0 then
				gold.Value += windmills
			end
		end
	end)
end

local function spawnResourceNodes()
	local existingFolder = Workspace:FindFirstChild("ResourceNodes")
	if existingFolder then
		existingFolder:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "ResourceNodes"
	folder.Parent = Workspace

	for _, resource in ipairs(resources) do
		local node = Instance.new("Part")
		node.Name = resource.name .. "Node"
		node.Anchored = true
		node.Color = resource.color
		node.Material = resource.material
		node.Position = resource.position
		node.Size = resource.size
		node.Parent = folder

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Gather"
		prompt.ObjectText = resource.name
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 10
		prompt.Parent = node

		prompt.Triggered:Connect(function(player)
			awardResource(player, resource.name)
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	addLeaderstats(player)
	startGoldLoop(player)
end)

Players.PlayerRemoving:Connect(function(player)
	windmillCounts[player] = nil
	windmillSlots[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	addLeaderstats(player)
	startGoldLoop(player)
end

-- ponytail: static nodes are enough until a real map needs spawning rules.
spawnGround()
spawnBuildPad()
spawnResourceNodes()
