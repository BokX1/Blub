local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

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
end

local function awardResource(player, resourceName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local value = leaderstats and leaderstats:FindFirstChild(resourceName)

	if value then
		value.Value += 1
	end
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

Players.PlayerAdded:Connect(addLeaderstats)

for _, player in ipairs(Players:GetPlayers()) do
	addLeaderstats(player)
end

-- ponytail: static nodes are enough until a real map needs spawning rules.
spawnGround()
spawnResourceNodes()
